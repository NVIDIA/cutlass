/***************************************************************************************************
 * Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
#include <cstdlib>
#include <cstdio>
#include <cassert>

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cute/tensor.hpp>
#include <cute/atom/copy_traits_sm90_im2col.hpp>

#include "cutlass/cluster_launch.hpp"
#include "cutlass/arch/barrier.h"
#include "cutlass/pipeline/sm90_pipeline.hpp"

#include "cutlass/util/print_error.hpp"
#include "cutlass/util/GPU_Clock.hpp"
#include "cutlass/util/helper_cuda.hpp"
#include "cutlass/arch/mma_sm90.h"
#include "cutlass/device_kernel.h"

using namespace cute;

template <class ElementA,
          class ElementB,
          class SmemLayoutA,    // (M,K,P)
          class SmemLayoutB>    // (N,K,P)
struct SharedStorage
{
    alignas(128) cute::ArrayEngine<ElementA, cosize_v<SmemLayoutA>> A;
    alignas(128) cute::ArrayEngine<ElementB, cosize_v<SmemLayoutB>> B;

    uint64_t tma_barrier[size<2>(SmemLayoutA{})];
    uint64_t mma_barrier[size<2>(SmemLayoutA{})];
};

template <class ProblemShape, class CtaTiler,
          class TA, class SmemLayoutA, class TmaA,
          class TB, class SmemLayoutB, class TmaB,
          class TC, class CStride, class TiledMma,
          class Alpha, class Beta>
struct KernelParams
{
    ProblemShape shape_MNK;
    CtaTiler cta_tiler;
    TA const* A;
    TmaA tma_a;
    TB const* B;
    TmaB tma_b;
    TC* C;
    CStride dC;
    TiledMma mma;
    Alpha alpha;
    Beta beta;
};

template <class ProblemShape, class CtaTiler,
          class TA, class SmemLayoutA, class TmaA,
          class TB, class SmemLayoutB, class TmaB,
          class TC, class CStride, class TiledMma,
          class Alpha, class Beta>
__global__ static
__launch_bounds__(decltype(size(TiledMma{}))::value)
void
gemm_device(KernelParams<ProblemShape, CtaTiler,
            TA, SmemLayoutA, TmaA, TB, SmemLayoutB, TmaB,
            TC, CStride, TiledMma, Alpha, Beta> const* params_ptr)
{
    auto const& params     = *params_ptr;
    auto const& shape_MNK  = params.shape_MNK;
    auto const& cta_tiler  = params.cta_tiler;
    auto const& tma_a      = params.tma_a;
    auto const& tma_b      = params.tma_b;
    auto        C          = params.C;
    auto const& dC         = params.dC;
    auto        mma        = params.mma;
    auto const& alpha      = params.alpha;
    auto const& beta       = params.beta;
    // Preconditions
    CUTE_STATIC_ASSERT_V(rank(shape_MNK) == Int<3>{});                   // (M, N, K)
    CUTE_STATIC_ASSERT_V(rank(cta_tiler) == Int<3>{});                   // (BLK_M, BLK_N, BLK_K)

    static_assert(is_static<SmemLayoutA>::value);
    static_assert(is_static<SmemLayoutB>::value);

    CUTE_STATIC_ASSERT_V(size<0>(SmemLayoutA{}) == size<0>(cta_tiler));  // BLK_M
    CUTE_STATIC_ASSERT_V(size<0>(SmemLayoutB{}) == size<1>(cta_tiler));  // BLK_N
    CUTE_STATIC_ASSERT_V(size<1>(SmemLayoutA{}) == size(get<2>(cta_tiler)));  // BLK_K (hierarchical)
    CUTE_STATIC_ASSERT_V(size<1>(SmemLayoutB{}) == size(get<2>(cta_tiler)));  // BLK_K (hierarchical)

    CUTE_STATIC_ASSERT_V(congruent(select<0,1>(shape_MNK), dC));         // dC strides for shape MN

    //
    // Full and Tiled Tensors
    //

    // Represent the full tensors
    auto [M, N, K] = shape_MNK;
    Tensor mA = tma_a.get_tma_tensor(make_shape(M,K));                   // (M,K) TMA Tensor
    Tensor mB = tma_b.get_tma_tensor(make_shape(N,K));                   // (N,K) TMA Tensor
    Tensor mC = make_tensor(make_gmem_ptr(C), make_shape(M,N), dC);      // (M,N)

    // Get the appropriate blocks for this thread block
    // Im2col TMA tensor (A) has a ComposedLayout that can't be indexed with concrete blockIdx
    // directly in local_tile. Defer all coordinates, then select the block tile separately.
    auto cta_coord = make_coord(blockIdx.x, blockIdx.y, _);              // (m,n,k)
    Tensor gA_mk = local_tile(mA, cta_tiler, make_coord(_,_,_), Step<_1, X,_1>{});  // (BLK_M,BLK_K,m,k)
    Tensor gA    = gA_mk(_,_,blockIdx.x,_);                             // (BLK_M,BLK_K,k)
    Tensor gB_nk = local_tile(mB, cta_tiler, make_coord(_,_,_), Step< X,_1,_1>{});  // (BLK_N,BLK_K,n,k)
    Tensor gB    = gB_nk(_,_,blockIdx.y,_);                             // (BLK_N,BLK_K,k)
    Tensor gC = local_tile(mC, cta_tiler, cta_coord, Step<_1,_1, X>{});  // (BLK_M,BLK_N)

    // Shared memory tensors
    extern __shared__ char shared_memory[];
    using SharedStorage = SharedStorage<TA, TB, SmemLayoutA, SmemLayoutB>;
    SharedStorage& smem = *reinterpret_cast<SharedStorage*>(shared_memory);
    Tensor sA = make_tensor(make_smem_ptr(smem.A.begin()), SmemLayoutA{}); // (BLK_M,BLK_K,PIPE)
    Tensor sB = make_tensor(make_smem_ptr(smem.B.begin()), SmemLayoutB{}); // (BLK_N,BLK_K,PIPE)

    //
    // Partition the copying of A and B tiles
    //
    // TUTORIAL:
    //   For im2col TMA, we use get_slice/partition_S/partition_D instead of tma_partition/group_modes.
    //   get_slice(0) selects this CTA's slice (no multicasting with cluster dim = 1).
    //   partition_S partitions the source (gmem) tensor according to the TMA atom.
    //   partition_D partitions the destination (smem) tensor according to the TMA atom.
    //

    // Both TMAs are TiledCopy objects — use get_slice/partition_S/partition_D
    auto block_tma_a = tma_a.get_slice(0);
    Tensor tAgA = block_tma_a.partition_S(gA);                              // (TMA,TMA_M,TMA_K,k)
    Tensor tAsA = block_tma_a.partition_D(sA);                              // (TMA,TMA_M,TMA_K,PIPE)

    auto block_tma_b = tma_b.get_slice(0);
    Tensor tBgB = block_tma_b.partition_S(gB);                              // (TMA,TMA_N,TMA_K,k)
    Tensor tBsB = block_tma_b.partition_D(sB);                              // (TMA,TMA_N,TMA_K,PIPE)

    constexpr int tma_transaction_bytes = (size<0>(SmemLayoutA{}) * size<1>(SmemLayoutA{}) * sizeof(TA))
                                        + (size<0>(SmemLayoutB{}) * size<1>(SmemLayoutB{}) * sizeof(TB));

    //
    // PREFETCH
    //

    auto K_PIPE_MAX = size<3>(tAsA);  // PIPE dimension (4D: TMA,TMA_M,TMA_K,PIPE)

    // Total count of tiles
    int k_tile_count = size<3>(tAgA);  // k dimension (4D: TMA,TMA_M,TMA_K,k)
    // Current tile index in gmem to read from
    int k_tile = 0;

    // Initialize Barriers
    int warp_idx = cutlass::canonical_warp_idx_sync();
    int lane_predicate = cute::elect_one_sync();
    uint64_t* producer_mbar = smem.tma_barrier;
    uint64_t* consumer_mbar = smem.mma_barrier;

    using ProducerBarType = cutlass::arch::ClusterTransactionBarrier;  // TMA
    using ConsumerBarType = cutlass::arch::ClusterBarrier;             // MMA
    CUTE_UNROLL
    for (int pipe = 0; pipe < K_PIPE_MAX; ++pipe) {
    if ((warp_idx == 0) && lane_predicate) {
        ProducerBarType::init(&producer_mbar[pipe],   1);
        ConsumerBarType::init(&consumer_mbar[pipe], 128);
    }
    }
    // Ensure barrier init is complete on all CTAs
    cluster_sync();

    // Start async loads for all pipes
    CUTE_UNROLL
    for (int pipe = 0; pipe < K_PIPE_MAX; ++pipe)
    {
    if ((warp_idx == 0) && lane_predicate)
    {
        // Set expected Tx Bytes after each reset / init
        ProducerBarType::arrive_and_expect_tx(&producer_mbar[pipe], tma_transaction_bytes);
        copy(tma_a.with(producer_mbar[pipe]), tAgA(_,_,_,k_tile), tAsA(_,_,_,pipe));
        copy(tma_b.with(producer_mbar[pipe]), tBgB(_,_,_,k_tile), tBsB(_,_,_,pipe));
    }
    --k_tile_count;
    ++k_tile;
    }

    //
    // Define A/B partitioning and C accumulators
    //
    // TUTORIAL:
    //   The tCrA and tCrB are actually Tensors of MMA Descriptors constructed as views of SMEM.
    //   The MMA Descriptor generation is automatic via inspection and validation of the SMEM Layouts.
    //   Because the MMA reads directly from SMEM and the fragments are descriptors rather than registers,
    //     there is no need for copy(tCsA, tCrA) in the mainloop.
    //

    ThrMMA thr_mma = mma.get_thread_slice(threadIdx.x);
    Tensor tCsA = thr_mma.partition_A(sA);                               // (MMA,MMA_M,MMA_K,PIPE)
    Tensor tCsB = thr_mma.partition_B(sB);                               // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tCgC = thr_mma.partition_C(gC);                               // (MMA,MMA_M,MMA_N)

    // Allocate accumulators and clear them
    Tensor tCrC = thr_mma.make_fragment_C(tCgC);                         // (MMA,MMA_M,MMA_N)
    clear(tCrC);

    // Allocate "fragments"
    Tensor tCrA = thr_mma.make_fragment_A(tCsA);                         // (MMA,MMA_M,MMA_K,PIPE)
    Tensor tCrB = thr_mma.make_fragment_B(tCsB);                         // (MMA,MMA_N,MMA_K,PIPE)

    //
    // PIPELINED MAIN LOOP
    //
    // TUTORIAL:
    //   Rather than interleaving the stages and instructions like in SM70 and SM80,
    //     the SM90 mainloops rely on explicit producer-consumer synchronization
    //     on the purely async instructions TMA and MMA.
    //   More advanced pipeline and warp-specialization strategies are available in CUTLASS mainloops.
    //

    // A PipelineState is a circular pipe index [.index()] and a pipe phase [.phase()]
    //   that flips each cycle through K_PIPE_MAX.
    auto write_state = cutlass::PipelineState<K_PIPE_MAX>();             // TMA writes
    auto read_state  = cutlass::PipelineState<K_PIPE_MAX>();             // MMA  reads

    CUTE_NO_UNROLL
    while (k_tile_count > -K_PIPE_MAX)
    {
    // Wait for Producer to complete
    int read_pipe = read_state.index();
    ProducerBarType::wait(&producer_mbar[read_pipe], read_state.phase());

    // MMAs to cover 1 K_TILE
    warpgroup_arrive();
    gemm(mma, tCrA(_,_,_,read_pipe), tCrB(_,_,_,read_pipe), tCrC);     // (V,M) x (V,N) => (V,M,N)
    warpgroup_commit_batch();

    // Wait for all MMAs in a K_TILE to complete
    warpgroup_wait<0>();

    // Notify that consumption is done
    ConsumerBarType::arrive(&consumer_mbar[read_pipe]);
    ++read_state;

    // Only issue new TMA copies if there are more tiles to fetch
    if ((warp_idx == 0) && lane_predicate && (k_tile_count > 0))
    {
        int pipe = write_state.index();
        // Wait for Consumer to complete consumption
        ConsumerBarType::wait(&consumer_mbar[pipe], write_state.phase());
        // Set expected Tx Bytes after each reset / init
        ProducerBarType::arrive_and_expect_tx(&producer_mbar[pipe], tma_transaction_bytes);
        copy(tma_a.with(producer_mbar[pipe]), tAgA(_,_,_,k_tile), tAsA(_,_,_,pipe));
        copy(tma_b.with(producer_mbar[pipe]), tBgB(_,_,_,k_tile), tBsB(_,_,_,pipe));
        ++write_state;
    }
    --k_tile_count;
    ++k_tile;
    }

    //
    // Epilogue (unpredicated)
    //

    axpby(alpha, tCrC, beta, tCgC);
}

template <class TA, class TW, class TO>
void 
conv2d_fprop(int n, int h, int w, int c, int k, int r, int s, int p, int q, 
             TA const* A, 
             TW const* W,
             TO *O, cudaStream_t stream = 0)
{
    // Implicit conversion convolution to GEMM
    // from O(n,p,q,k) = A(n,h,w,c) * W(k,r,s,c)
    // to O(M,N) = A(M,K) * W(N,K) where M = n*p*q, K = (c,s,r), N=k
    //
    // TUTORIAL:
    //   For im2col TMA, K must be a hierarchical tuple (C,S,R) — not a flat product c*s*r.
    //   The TMA im2col coordinate tensor has ComposedLayout with shape (M, (C,S,R)).
    //   The CTA tiler's K dimension must be Shape<bK> (rank-1 tuple) so that logical_divide
    //   tiles only the C (channel) dimension, leaving S and R as outer k-loop modes.
    //   This matches how the CUTLASS conv collective handles fprop im2col.

    // Define shapes (dynamic)
    auto M = int(n*p*q);
    auto K = make_shape(c, s, r);
    auto N = int(k);
    auto prob_shape = make_shape(M, N, K);

    // Define strides (mixed)
    // Activation tensor must be rank-2 hierarchical ((W,H,N), C) for make_im2col_tma_copy.
    // product_each on rank-2 shape gives (W*H*N, C), which aligns with the rank-2 cta_tiler (bM, bK).
    auto dA = make_stride(make_stride(c, c*w, c*w*h), Int<1>{});
    auto dW = make_stride(r*s*c, make_stride(Int<1>{}, c, c*s));
    auto dO = make_stride(N, Int<1>{});

    // Define CTA tile sizes (static)
    auto bM = Int<128>{};
    auto bN = Int<128>{};
    auto bK = Int<64>{};
    auto cta_tiler = make_shape(bM, bN, make_shape(bK));
    auto bP = Int<3>{}; // Pipeline

    // Define the smem layouts (static)
    auto sA = tile_to_shape(GMMA::Layout_MN_SW128_Atom<TA>{}, make_shape(bM,bK,bP));
    auto sW = tile_to_shape(GMMA::Layout_MN_SW128_Atom<TW>{}, make_shape(bN,bK,bP));

    // Define the MMA
    TiledMMA tiled_mma = make_tiled_mma(SM90_64x64x16_F16F16F16_SS<GMMA::Major::MN,GMMA::Major::MN>{});

    // Define the TMAs
    // Create Global memory tensors for TMA inspection
    Tensor mA = make_tensor(make_gmem_ptr(A),
                            make_shape(make_shape(w,h,n), c),
                            dA);
    Tensor mW = make_tensor(make_gmem_ptr(W),
                            make_shape(k, make_shape(c,s,r)),
                            dW);

    // Compute convolution corners (for fprop, stride=1, no padding, dilation=1)
    // lower_corner = -lower_padding (reversed to W,H order)
    auto lower_corner_whd = make_tuple(0, 0);       // no padding
    // upper_corner = upper_padding - (filter_size - 1) * dilation
    auto upper_corner_whd = make_tuple(-(s-1), -(r-1));     // no padding, dilation=1
    // padding
    auto lower_padding_whd = make_tuple(0, 0);
    auto upper_padding_whd = make_tuple(0, 0);
    // traversal stride (convolution stride)
    auto stride_whd = make_tuple(1, 1);
    // filter offsets: lower_srt = (0, 0) for fprop
    auto lower_srt = make_tuple(0, 0);
    // dilation
    auto dilation_srt = make_tuple(1, 1); // dilation=1

    // Create TMA TiledCopy objects (not Copy_Atom — we need get_slice/partition_S/partition_D)
    auto tmaA = make_im2col_tma_copy(SM90_TMA_LOAD_IM2COL{},
                                     mA,
                                     sA(_,_,0),
                                     product_each(shape(sA(_,_,0))),
                                     Int<1>{},
                                     lower_corner_whd,
                                     upper_corner_whd,
                                     lower_padding_whd,
                                     upper_padding_whd,
                                     stride_whd,
                                     lower_srt,
                                     dilation_srt);
    auto tmaW = make_tma_copy(SM90_TMA_LOAD{}, mW, sW(_,_,0), make_shape(bN, make_shape(bK)), Int<1>{});

    //
    // Setup and Launch
    //

    // Launch parameter setup
    int smem_size = int(sizeof(SharedStorage<TA, TW, decltype(sA), decltype(sW)>));
    dim3 dimBlock(size(tiled_mma));
    dim3 dimCluster(1, 1, 1);
    dim3 dimGrid(round_up(size(ceil_div(M, bM)), dimCluster.x),
                 round_up(size(ceil_div(N, bN)), dimCluster.y));
    cutlass::ClusterLaunchParams params = {dimGrid, dimBlock, dimCluster, smem_size};


    using TI = cute::half_t;
    TI alpha = TI(1.0f);
    TI beta  = TI(0.0f);

    using KParams = KernelParams<decltype(prob_shape), decltype(cta_tiler),
                                 TA, decltype(sA), decltype(tmaA),
                                 TW, decltype(sW), decltype(tmaW),
                                 TO, decltype(dO), decltype(tiled_mma),
                                 decltype(alpha), decltype(beta)>;
    KParams h_kernel_args{prob_shape, cta_tiler, A, tmaA, W, tmaW, O, dO, tiled_mma, alpha, beta};

    KParams* d_kernel_args = nullptr;
    CUTE_CHECK_ERROR(cudaMalloc(&d_kernel_args, sizeof(KParams)));
    CUTE_CHECK_ERROR(cudaMemcpy(d_kernel_args, &h_kernel_args, sizeof(KParams), cudaMemcpyHostToDevice));

    void const* kernel_ptr = reinterpret_cast<void const*>(
                                &gemm_device<decltype(prob_shape), decltype(cta_tiler),
                                             TA, decltype(sA), decltype(tmaA),
                                             TW, decltype(sW), decltype(tmaW),
                                             TO, decltype(dO), decltype(tiled_mma),
                                             decltype(alpha), decltype(beta)>);
    CUTE_CHECK_ERROR(cudaFuncSetAttribute(
        kernel_ptr,
        cudaFuncAttributeMaxDynamicSharedMemorySize,
        smem_size));

    // Kernel Launch
    cutlass::Status status = cutlass::launch_kernel_on_cluster(params, kernel_ptr,
                                                               d_kernel_args);
    CUTE_CHECK_LAST();

    if (status != cutlass::Status::kSuccess) {
        std::cerr << "Error: Failed at kernel launch" << std::endl;
    }

    CUTE_CHECK_ERROR(cudaFree(d_kernel_args));
}

int main(int argc, char** argv)
{
    cudaDeviceProp props;
    int current_device_id;
    cudaGetDevice(&current_device_id);
    cudaGetDeviceProperties(&props, current_device_id);
    cudaError_t error = cudaGetDeviceProperties(&props, 0);
    if (error != cudaSuccess) {
        std::cerr << "cudaGetDeviceProperties() returned an error: " << cudaGetErrorString(error) << std::endl;
        return -1;
    }

    if (props.major < 9) {
        std::cout << "This example requires NVIDIA's Hopper Architecture GPU with compute capability 90a\n" << std::endl;
        return 0;
    }

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

    int N = 1;
    if (argc >= 2)
        sscanf(argv[1], "%d", &N);

    int H = 56;
    if (argc >= 3)
        sscanf(argv[2], "%d", &H);

    int W = 56;
    if (argc >= 4)
        sscanf(argv[3], "%d", &W);

    int C = 64;
    if (argc >= 5)
        sscanf(argv[4], "%d", &C);

    int K = 128;
    if (argc >= 6)
        sscanf(argv[5], "%d", &K);

    int R = 3;
    if (argc >= 7)
        sscanf(argv[6], "%d", &R);

    int S = 3;
    if (argc >= 8)
        sscanf(argv[7], "%d", &S); 

    int P = H - R + 1, Q = W - S +1;
    using TA = cute::half_t;
    using TW = cute::half_t;
    using TO = cute::half_t;

    thrust::host_vector<TA> h_A(N*H*W*C);
    thrust::host_vector<TW> h_W(K*R*S*C);
    thrust::host_vector<TO> h_O(N*P*Q*K);

    // Initialize the tensors
    for (int j = 0; j < N*H*W*C; ++j) h_A[j] = TA(j);
    for (int j = 0; j < K*R*S*C; ++j) h_W[j] = TW(1);
    for (int j = 0; j < N*P*Q*K; ++j) h_O[j] = TO(0);

    thrust::device_vector<TA> d_A = h_A;
    thrust::device_vector<TW> d_W = h_W;
    thrust::device_vector<TO> d_O = h_O;

    double gflops = (2.0*N*P*Q*K*C*R*S) * 1e-9;

    const int timing_iterations = 100;
    GPU_Clock timer;

    // Run once
    d_O = h_O;
    conv2d_fprop(N, H, W, C, K, R, S, P, Q, 
                d_A.data().get(),
                d_W.data().get(),
                d_O.data().get());
    CUTE_CHECK_LAST();
    thrust::host_vector<TO> cute_result = d_O;

    // Timing iterations
    timer.start();
    for (int i = 0; i < timing_iterations; ++i) {
        conv2d_fprop(N, H, W, C, K, R, S, P, Q, 
                d_A.data().get(),
                d_W.data().get(),
                d_O.data().get());
    }
    double cute_time = timer.seconds() / timing_iterations;
    CUTE_CHECK_LAST();
    printf("CUTE_GEMM:     [%6.1f]GFlop/s  (%6.4f)ms\n", gflops / cute_time, cute_time*1000);

#else
    std::cout << "CUTLASS_ARCH_MMA_SM90_SUPPORTED must be enabled, but it is not. Test is waived \n" << std::endl;
#endif
    return 0;
}