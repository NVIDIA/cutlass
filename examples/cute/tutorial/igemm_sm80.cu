/***************************************************************************************************
 * INT8 Tensor Core GEMM using CuTe on SM80+
 *
 * C(M,N) = A(M,K) * B(N,K)^T  with A, B K-major (row-major), C M-major (col-major)
 * Accumulator: int32, Output: int32
 *
 * Features:
 *   - SM80 m16n8k16 / m16n8k32 INT8 MMA atoms
 *   - Swizzled shared memory (Swizzle<2,4,3>) for zero bank conflicts
 *   - 3-stage cp.async pipeline with interleaved A/B loads
 *   - CTA swizzle for L2 locality
 *   - Predicated loads (ZFILL) for arbitrary M, N, K
 *   - Configurable tile sizes (BM, BN) and MMA K-size (k16/k32)
 *
 **************************************************************************************************/

#include <cstdlib>
#include <cstdio>
#include <cstdint>
#include <cassert>
#include <iostream>

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cute/tensor.hpp>

#include "cutlass/util/print_error.hpp"
#include "cutlass/util/GPU_Clock.hpp"
#include "cutlass/util/helper_cuda.hpp"

using namespace cute;

// ─── Shared memory storage ────────────────────────────────────────────────
template <class ElementA, class ElementB,
          class SmemLayoutA, class SmemLayoutB>
struct SharedStorage {
  ArrayEngine<ElementA, cosize_v<SmemLayoutA>> A;
  ArrayEngine<ElementB, cosize_v<SmemLayoutB>> B;
};

// ─── Predicate helper ─────────────────────────────────────────────────────
// Build a (CPY_M, CPY_K) bool tensor from a partitioned coordinate tensor
template <class CoordTensor>
__device__ auto make_pred_2d(CoordTensor const& coords, int row_max, int k_lim) {
  auto pred = make_tensor<bool>(make_shape(size<1>(coords), size<2>(coords)));
  CUTE_UNROLL
  for (int i = 0; i < size<0>(pred); ++i) {
    CUTE_UNROLL
    for (int j = 0; j < size<1>(pred); ++j) {
      pred(i,j) = get<0>(coords(Int<0>{},i,j)) < row_max &&
                  get<1>(coords(Int<0>{},i,j)) < k_lim;
    }
  }
  return pred;
}

// ─── GEMM kernel ──────────────────────────────────────────────────────────
template <int SwizzleLog,
          class ProblemShape, class CtaTiler,
          class TA, class AStride, class ASmemLayout, class TiledCopyA, class S2RAtomA,
          class TB, class BStride, class BSmemLayout, class TiledCopyB, class S2RAtomB,
          class TC, class CStride, class CSmemLayout, class TiledMma,
          class Alpha, class Beta>
__global__ static
__launch_bounds__(decltype(size(TiledMma{}))::value)
void gemm_device(ProblemShape shape_MNK, CtaTiler cta_tiler,
                 TA const* A, AStride dA, ASmemLayout sA_layout, TiledCopyA copy_a, S2RAtomA s2r_atom_a,
                 TB const* B, BStride dB, BSmemLayout sB_layout, TiledCopyB copy_b, S2RAtomB s2r_atom_b,
                 TC      * C, CStride dC, CSmemLayout          , TiledMma mma,
                 Alpha alpha, Beta beta)
{
  CUTE_STATIC_ASSERT_V(rank(shape_MNK) == Int<3>{});
  CUTE_STATIC_ASSERT_V(rank(cta_tiler) == Int<3>{});

  // Full tensors
  Tensor mA = make_tensor(make_gmem_ptr(A), select<0,2>(shape_MNK), dA);  // (M,K)
  Tensor mB = make_tensor(make_gmem_ptr(B), select<1,2>(shape_MNK), dB);  // (N,K)
  Tensor mC = make_tensor(make_gmem_ptr(C), select<0,1>(shape_MNK), dC);  // (M,N)

  // CTA swizzle: remap blockIdx for L2 locality
  int tile_m = blockIdx.x, tile_n = blockIdx.y;
  if constexpr (SwizzleLog > 0) {
    constexpr int SW = 1 << SwizzleLog;
    int tiles_m = gridDim.x;
    int tiles_n = gridDim.y;
    if (tiles_n >= SW) {
      int bid = blockIdx.x + blockIdx.y * tiles_m;
      int panel_sz = tiles_m * SW;
      int panel_id = bid / panel_sz;
      int within   = bid % panel_sz;
      tile_m = within / SW;
      tile_n = panel_id * SW + within % SW;
      if (tile_n >= tiles_n) return;
    }
  }
  auto cta_coord = make_coord(tile_m, tile_n, _);
  Tensor gA = local_tile(mA, cta_tiler, cta_coord, Step<_1, X,_1>{});  // (BLK_M,BLK_K,k)
  Tensor gB = local_tile(mB, cta_tiler, cta_coord, Step< X,_1,_1>{});  // (BLK_N,BLK_K,k)
  Tensor gC = local_tile(mC, cta_tiler, cta_coord, Step<_1,_1, X>{});  // (BLK_M,BLK_N)

  // Coordinate tensors for bounds-checking
  Tensor cA = make_identity_tensor(make_shape(size<0>(cta_tiler), size<2>(cta_tiler)));
  Tensor cB = make_identity_tensor(make_shape(size<1>(cta_tiler), size<2>(cta_tiler)));
  Tensor cC = make_identity_tensor(make_shape(size<0>(cta_tiler), size<1>(cta_tiler)));

  int m_max = get<0>(shape_MNK) - tile_m * int(size<0>(cta_tiler));
  int n_max = get<1>(shape_MNK) - tile_n * int(size<1>(cta_tiler));
  int k_max = get<2>(shape_MNK);
  int bk    = int(size<2>(cta_tiler));

  // Shared memory buffers
  extern __shared__ char shared_memory[];
  using SmemStorage = SharedStorage<TA, TB, ASmemLayout, BSmemLayout>;
  SmemStorage& smem = *reinterpret_cast<SmemStorage*>(shared_memory);
  Tensor sA = make_tensor(make_smem_ptr(smem.A.begin()), sA_layout);  // (BLK_M,BLK_K,PIPE)
  Tensor sB = make_tensor(make_smem_ptr(smem.B.begin()), sB_layout);  // (BLK_N,BLK_K,PIPE)

  //
  // Partition the copying of A and B tiles across the threads
  //

  ThrCopy thr_copy_a = copy_a.get_slice(threadIdx.x);
  Tensor tAgA = thr_copy_a.partition_S(gA);                           // (CPY,CPY_M,CPY_K,k)
  Tensor tAsA = thr_copy_a.partition_D(sA);                           // (CPY,CPY_M,CPY_K,PIPE)
  Tensor tAcA = thr_copy_a.partition_S(cA);                           // (CPY,CPY_M,CPY_K)

  ThrCopy thr_copy_b = copy_b.get_slice(threadIdx.x);
  Tensor tBgB = thr_copy_b.partition_S(gB);                           // (CPY,CPY_N,CPY_K,k)
  Tensor tBsB = thr_copy_b.partition_D(sB);                           // (CPY,CPY_N,CPY_K,PIPE)
  Tensor tBcB = thr_copy_b.partition_S(cB);                           // (CPY,CPY_N,CPY_K)

  //
  // Define A/B partitioning and C accumulators
  //

  ThrMMA thr_mma = mma.get_slice(threadIdx.x);
  Tensor tCgC = thr_mma.partition_C(gC);                              // (MMA,MMA_M,MMA_N)
  Tensor tCrA = thr_mma.partition_fragment_A(sA(_,_,0));              // (MMA,MMA_M,MMA_K)
  Tensor tCrB = thr_mma.partition_fragment_B(sB(_,_,0));              // (MMA,MMA_N,MMA_K)
  Tensor tCrC = thr_mma.make_fragment_C(tCgC);                        // (MMA,MMA_M,MMA_N)
  clear(tCrC);
  Tensor tCcC = thr_mma.partition_C(cC);                              // epilogue coords

  //
  // Copy Atom retiling
  //

  TiledCopy s2r_copy_a = make_tiled_copy_A(s2r_atom_a, mma);
  ThrCopy   s2r_thr_copy_a = s2r_copy_a.get_slice(threadIdx.x);
  Tensor tXsA = s2r_thr_copy_a.partition_S(sA);                       // (CPY,MMA_M,MMA_K,PIPE)
  Tensor tXrA = s2r_thr_copy_a.retile_D(tCrA);                        // (CPY,MMA_M,MMA_K)

  TiledCopy s2r_copy_b = make_tiled_copy_B(s2r_atom_b, mma);
  ThrCopy   s2r_thr_copy_b = s2r_copy_b.get_slice(threadIdx.x);
  Tensor tXsB = s2r_thr_copy_b.partition_S(sB);                       // (CPY,MMA_N,MMA_K,PIPE)
  Tensor tXrB = s2r_thr_copy_b.retile_D(tCrB);                        // (CPY,MMA_N,MMA_K)

  //
  // PREFETCH
  //

  auto K_PIPE_MAX = size<3>(tAsA);
  int k_tile_count = size<3>(tAgA);
  int k_tile_next = 0;

  // Interior CTA: all M/N/K elements in-bounds -> skip predication
  bool is_interior = (m_max >= int(size<0>(cta_tiler))) &&
                     (n_max >= int(size<1>(cta_tiler))) &&
                     (k_max % bk == 0);

  // Start async loads for all pipes but the last
  CUTE_UNROLL
  for (int k_pipe = 0; k_pipe < K_PIPE_MAX-1; ++k_pipe) {
    if (is_interior) {
      copy(copy_a, tAgA(_,_,_,k_tile_next), tAsA(_,_,_,k_pipe));
      copy(copy_b, tBgB(_,_,_,k_tile_next), tBsB(_,_,_,k_pipe));
    } else {
      int k_lim = k_max - k_tile_next * bk;
      copy_if(copy_a, make_pred_2d(tAcA, m_max, k_lim), tAgA(_,_,_,k_tile_next), tAsA(_,_,_,k_pipe));
      copy_if(copy_b, make_pred_2d(tBcB, n_max, k_lim), tBgB(_,_,_,k_tile_next), tBsB(_,_,_,k_pipe));
    }
    cp_async_fence();
    --k_tile_count;
    if (k_tile_count > 0) { ++k_tile_next; }
  }

  //
  // PIPELINED MAIN LOOP
  //   gmem(k_tile_next) -> smem(smem_pipe_write)
  //   smem(smem_pipe_read) -> rmem(k_block_next)
  //   compute on rmem(k_block)
  //

  auto K_BLOCK_MAX = size<2>(tCrA);
  int smem_pipe_read  = 0;
  int smem_pipe_write = K_PIPE_MAX-1;

  Tensor tXsA_p = tXsA(_,_,_,smem_pipe_read);
  Tensor tXsB_p = tXsB(_,_,_,smem_pipe_read);

  // PREFETCH register pipeline
  if (K_BLOCK_MAX > 1) {
    cp_async_wait<K_PIPE_MAX-2>();
    __syncthreads();
    copy(s2r_atom_a, tXsA_p(_,_,Int<0>{}), tXrA(_,_,Int<0>{}));
    copy(s2r_atom_b, tXsB_p(_,_,Int<0>{}), tXrB(_,_,Int<0>{}));
  }

  CUTE_NO_UNROLL
  while (k_tile_count > -(K_PIPE_MAX-1))
  {
    CUTE_UNROLL
    for (int k_block = 0; k_block < K_BLOCK_MAX; ++k_block)
    {
      if (k_block == K_BLOCK_MAX - 1)
      {
        tXsA_p = tXsA(_,_,_,smem_pipe_read);
        tXsB_p = tXsB(_,_,_,smem_pipe_read);
        cp_async_wait<K_PIPE_MAX-2>();
        __syncthreads();
      }

      // Load A, B shmem->regs for k_block+1
      auto k_block_next = (k_block + Int<1>{}) % K_BLOCK_MAX;
      copy(s2r_atom_a, tXsA_p(_,_,k_block_next), tXrA(_,_,k_block_next));
      copy(s2r_atom_b, tXsB_p(_,_,k_block_next), tXrB(_,_,k_block_next));

      // Interleaved copy: A before gemm, B after gemm
      if (k_block == 0)
      {
        if (is_interior) {
          copy(copy_a, tAgA(_,_,_,k_tile_next), tAsA(_,_,_,smem_pipe_write));
        } else {
          int k_lim = k_max - k_tile_next * bk;
          copy_if(copy_a, make_pred_2d(tAcA, m_max, k_lim), tAgA(_,_,_,k_tile_next), tAsA(_,_,_,smem_pipe_write));
        }
      }

      // Thread-level register gemm for k_block
      gemm(mma, tCrA(_,_,k_block), tCrB(_,_,k_block), tCrC);

      if (k_block == 0)
      {
        if (is_interior) {
          copy(copy_b, tBgB(_,_,_,k_tile_next), tBsB(_,_,_,smem_pipe_write));
        } else {
          int k_lim = k_max - k_tile_next * bk;
          copy_if(copy_b, make_pred_2d(tBcB, n_max, k_lim), tBgB(_,_,_,k_tile_next), tBsB(_,_,_,smem_pipe_write));
        }
        cp_async_fence();
        --k_tile_count;
        if (k_tile_count > 0) { ++k_tile_next; }
        smem_pipe_write = smem_pipe_read;
        smem_pipe_read = (smem_pipe_read == K_PIPE_MAX-1) ? 0 : smem_pipe_read+1;
      }
    }
  }

  //
  // Epilogue
  //

  if (is_interior) {
    axpby(alpha, tCrC, beta, tCgC);
  } else {
    CUTE_UNROLL
    for (int i = 0; i < size(tCrC); ++i) {
      if (get<0>(tCcC(i)) < m_max && get<1>(tCcC(i)) < n_max) {
        tCgC(i) = alpha * tCrC(i) + beta * tCgC(i);
      }
    }
  }
}

// ─── Launch wrapper ───────────────────────────────────────────────────────
// BM:  compile-time M tile size (must be >= 16, multiple of 16)
// BN:  compile-time N tile size (must be >= 64, multiple of 64)
// K32: use m16n8k32 MMA atom (true) vs m16n8k16 (false)
template<int BM = 128, int BN = 128, bool K32 = false>
void gemm_i8(int m, int n, int k,
             int32_t alpha,
             int8_t const* A, int ldA,
             int8_t const* B, int ldB,
             int32_t beta,
             int32_t* C, int ldC,
             cudaStream_t stream = 0)
{
  using namespace cute;

  static_assert(BM >= 16 && BM % 16 == 0, "BM must be >= 16 and multiple of 16");
  static_assert(BN >= 64 && BN % 64 == 0, "BN must be >= 64 and multiple of 64");

  auto M = int(m);
  auto N = int(n);
  auto K = int(k);
  auto prob_shape = make_shape(M, N, K);                            // (M, N, K)

  // Define TN strides (mixed)
  auto dA = make_stride(ldA, Int<1>{});                             // (dM, dK) K-major
  auto dB = make_stride(ldB, Int<1>{});                             // (dN, dK) K-major
  auto dC = make_stride(Int<1>{}, ldC);                             // (dM, dN) M-major

  // CTA tile
  auto bM = Int<BM>{};
  auto bN = Int<BN>{};
  auto bK = Int< 64>{};
  auto cta_tiler = make_shape(bM, bN, bK);                         // (BLK_M, BLK_N, BLK_K)
  auto bP = Int<3>{};                                               // Pipeline stages

  // Swizzled smem: Swizzle<2,4,3>, 8-row atom x 64 cols
  auto smem_atom = composition(Swizzle<2, 4, 3>{},
                               Layout<Shape <_8, _64>,
                                      Stride<_64, _1>>{});
  auto sA = tile_to_shape(smem_atom, make_shape(bM, bK, bP));
  auto sB = tile_to_shape(smem_atom, make_shape(bN, bK, bP));
  auto sC = make_layout(make_shape(bM, bN));

  // Warp layout: always 8 warps (256 threads) for better occupancy
  constexpr int WM = BM >= 32 ? 2 : 1;
  constexpr int WN = 8 / WM;
  constexpr int NUM_THREADS = WM * WN * 32;

  // A copy: adapt thread layout and vectorization to BM and thread count
  constexpr int thr_rows_A  = BM < 64 ? BM : 64;
  constexpr int thr_kcols_A = NUM_THREADS / thr_rows_A;
  constexpr int vals_A      = 64 / thr_kcols_A;

  using CpType_A = conditional_t<vals_A >= 16, uint128_t,
                   conditional_t<vals_A >= 8,  uint64_t, uint32_t>>;

  TiledCopy copyA = make_tiled_copy(
      Copy_Atom<SM80_CP_ASYNC_CACHEALWAYS_ZFILL<CpType_A>, int8_t>{},
      Layout<Shape <Int<thr_rows_A>, Int<thr_kcols_A>>,
             Stride<Int<thr_kcols_A>, _1>>{},                      // Thr layout
      Layout<Shape<_1, Int<vals_A>>>{});                            // Val layout

  // B copy: BNx64, 128-bit cp.async
  constexpr int thr_rows_B = NUM_THREADS / 4;
  TiledCopy copyB = make_tiled_copy(
      Copy_Atom<SM80_CP_ASYNC_CACHEALWAYS_ZFILL<uint128_t>, int8_t>{},
      Layout<Shape<Int<thr_rows_B>, _4>, Stride<_4, _1>>{},        // Thr layout
      Layout<Shape<_1, _16>>{});                                    // Val layout

  // MMA atom: k16 vs k32
  using MmaAtom  = conditional_t<K32, SM80_16x8x32_S32S8S8S32_TN_SATURATE,
                                      SM80_16x8x16_S32S8S8S32_TN_SATURATE>;
  using S2RCopyA = conditional_t<K32, SM75_U32x4_LDSM_N, SM75_U32x2_LDSM_N>;
  using S2RCopyB = conditional_t<K32, SM75_U32x2_LDSM_N, SM75_U32x1_LDSM_N>;

  TiledMMA mmaC = make_tiled_mma(MmaAtom{},
                                 Layout<Shape<Int<WM>, Int<WN>, _1>>{});

  Copy_Atom<S2RCopyA, int8_t> s2r_atom_A;
  Copy_Atom<S2RCopyB, int8_t> s2r_atom_B;

  int smem_size = int(sizeof(SharedStorage<int8_t, int8_t, decltype(sA), decltype(sB)>));
  dim3 dimBlock(size(mmaC));
  dim3 dimGrid(size(ceil_div(M, bM)),
               size(ceil_div(N, bN)));

  constexpr int kSwizzle = 3;  // 2^3=8 N-tiles per L2 panel
  auto kernel_fptr = gemm_device<kSwizzle,
    decltype(prob_shape), decltype(cta_tiler),
    int8_t,  decltype(dA), decltype(sA), decltype(copyA), decltype(s2r_atom_A),
    int8_t,  decltype(dB), decltype(sB), decltype(copyB), decltype(s2r_atom_B),
    int32_t, decltype(dC), decltype(sC), decltype(mmaC),
    decltype(alpha), decltype(beta)>;

  cudaFuncSetAttribute(kernel_fptr,
    cudaFuncAttributeMaxDynamicSharedMemorySize, smem_size);
  cudaFuncSetAttribute(kernel_fptr,
    cudaFuncAttributePreferredSharedMemoryCarveout, 100);

  kernel_fptr<<<dimGrid, dimBlock, smem_size, stream>>>
    (prob_shape, cta_tiler,
     A, dA, sA, copyA, s2r_atom_A,
     B, dB, sB, copyB, s2r_atom_B,
     C, dC, sC, mmaC,
     alpha, beta);
}

// ─── CPU reference ────────────────────────────────────────────────────────
// C(M,N) = A(M,K) * B(N,K)^T, A K-major, B K-major, C N-major (row-major)
void cpu_i8gemm(int m, int n, int k,
                int8_t const* A, int8_t const* B, int32_t* C)
{
  for (int i = 0; i < m; ++i) {
    for (int j = 0; j < n; ++j) {
      int32_t acc = 0;
      for (int p = 0; p < k; ++p) {
        acc += int32_t(A[i * k + p]) * int32_t(B[j * k + p]);
      }
      C[i * n + j] = acc;
    }
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────
int main(int argc, char** argv)
{
  cudaDeviceProp props;
  cudaError_t error = cudaGetDeviceProperties(&props, 0);
  if (error != cudaSuccess) {
    std::cerr << "cudaGetDeviceProperties() returned an error: "
              << cudaGetErrorString(error) << std::endl;
    return -1;
  }

  if (props.major < 8) {
    std::cout << "This example requires an Ampere GPU or newer (CC >= 80)" << std::endl;
    return 0;
  }

  std::cout << "Using device 0: " << props.name
            << " (SM" << props.major * 10 + props.minor
            << ", " << props.multiProcessorCount << " SMs)" << std::endl;

  int m = 4096;
  if (argc >= 2) sscanf(argv[1], "%d", &m);
  int n = 4096;
  if (argc >= 3) sscanf(argv[2], "%d", &n);
  int k = 4096;
  if (argc >= 4) sscanf(argv[3], "%d", &k);

  std::cout << "M = " << m << std::endl;
  std::cout << "N = " << n << std::endl;
  std::cout << "K = " << k << std::endl;

  int ldA = k, ldB = k, ldC = n;

  thrust::host_vector<int8_t> h_A(m * k), h_B(n * k);
  thrust::host_vector<int32_t> h_C(m * n, 0);

  srand(42);
  for (int i = 0; i < m * k; ++i) h_A[i] = (int8_t)((rand() % 7) - 3);
  for (int i = 0; i < n * k; ++i) h_B[i] = (int8_t)((rand() % 7) - 3);

  thrust::device_vector<int8_t>  d_A = h_A, d_B = h_B;
  thrust::device_vector<int32_t> d_C(m * n, 0);

  //
  // Correctness verification on a small problem
  //

  {
    int vm = 100, vn = 256, vk = 192;  // non-aligned sizes
    std::cout << "\nVerification: M=" << vm << " N=" << vn << " K=" << vk << std::endl;

    thrust::host_vector<int8_t> vA(vm * vk), vB(vn * vk);
    srand(123);
    for (int i = 0; i < vm * vk; ++i) vA[i] = (int8_t)((rand() % 7) - 3);
    for (int i = 0; i < vn * vk; ++i) vB[i] = (int8_t)((rand() % 7) - 3);

    // CPU reference
    thrust::host_vector<int32_t> h_ref(vm * vn, 0);
    cpu_i8gemm(vm, vn, vk, vA.data(), vB.data(), h_ref.data());

    // GPU kernel (swap A<->B and m<->n for N-major C output)
    thrust::device_vector<int8_t>  d_vA = vA, d_vB = vB;
    thrust::device_vector<int32_t> d_vC(vm * vn, 0);
    gemm_i8<128, 128, false>(vn, vm, vk, 1,
                              d_vB.data().get(), vk,
                              d_vA.data().get(), vk,
                              0, d_vC.data().get(), vn);
    CUTE_CHECK_LAST();
    cudaDeviceSynchronize();

    thrust::host_vector<int32_t> h_gpu = d_vC;
    int errs = 0;
    for (int i = 0; i < vm * vn; ++i) {
      if (h_gpu[i] != h_ref[i]) {
        if (errs < 5)
          std::cerr << "  MISMATCH [" << i << "]: gpu=" << h_gpu[i]
                    << " cpu=" << h_ref[i] << std::endl;
        ++errs;
      }
    }
    std::cout << "Verification: " << (errs == 0 ? "PASS" : "FAIL")
              << " (" << errs << " errors)" << std::endl;
    if (errs > 0) return 1;
  }

  //
  // Timing
  //

  double gops = 2.0 * m * n * k * 1e-9;

  const int timing_iterations = 100;
  GPU_Clock timer;

  // Warmup
  gemm_i8<128, 128, false>(n, m, k, 1,
                            d_B.data().get(), ldB,
                            d_A.data().get(), ldA,
                            0, d_C.data().get(), ldC);
  CUTE_CHECK_LAST();
  cudaDeviceSynchronize();

  // k16 timing
  timer.start();
  for (int i = 0; i < timing_iterations; ++i) {
    gemm_i8<128, 128, false>(n, m, k, 1,
                              d_B.data().get(), ldB,
                              d_A.data().get(), ldA,
                              0, d_C.data().get(), ldC);
  }
  double k16_time = timer.seconds() / timing_iterations;
  CUTE_CHECK_LAST();

  // k32 timing
  gemm_i8<128, 128, true>(n, m, k, 1,
                           d_B.data().get(), ldB,
                           d_A.data().get(), ldA,
                           0, d_C.data().get(), ldC);
  cudaDeviceSynchronize();
  timer.start();
  for (int i = 0; i < timing_iterations; ++i) {
    gemm_i8<128, 128, true>(n, m, k, 1,
                             d_B.data().get(), ldB,
                             d_A.data().get(), ldA,
                             0, d_C.data().get(), ldC);
  }
  double k32_time = timer.seconds() / timing_iterations;
  CUTE_CHECK_LAST();

  printf("\nINT8_GEMM_k16: [%6.1f]GOp/s  (%6.4f)ms\n", gops / k16_time, k16_time * 1000);
  printf("INT8_GEMM_k32: [%6.1f]GOp/s  (%6.4f)ms\n",   gops / k32_time, k32_time * 1000);

  return 0;
}
