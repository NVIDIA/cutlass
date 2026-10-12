/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

//
//

#include <iostream>
#include <cstdio>

// Use Thrust to handle host/device allocations
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

// Cutlass includes
#include <cutlass/util/print_error.hpp>
#include <cutlass/arch/barrier.h>
#include <cutlass/cluster_launch.hpp>
#include <cutlass/util/reference/host/gemm.h>

// CuTe includes
#include <cute/tensor.hpp>                      // CuTe tensor implementation
#include <cute/arch/cluster_sm90.hpp>           // CuTe functions for querying the details of cluster launched
#include <cute/arch/cluster_sm100.hpp>
#include <cute/numeric/integral_constant.hpp>   // Compile time in constants such as _1, _256 etc.
#include <cute/algorithm/cooperative_copy.hpp>

using namespace cute;
// #define CUTE_EXAMPLE_PRINT_LAYOUTS

template <class T>
using iterator_t =
    typename conditional < sizeof_bits_v<T><8, subbyte_iterator<T>, T *>::type;

template <class T>
CUTE_HOST_DEVICE constexpr auto typestr() {
  if constexpr (is_same_v<T, cutlass::float_e4m3_t>) { return "float_e4m3"; } else
  if constexpr (is_same_v<T, cutlass::float_e5m2_t>) { return "float_e5m2"; } else
  if constexpr (is_same_v<T, cutlass::float_e2m3_t>) { return "float_e2m3"; } else
  if constexpr (is_same_v<T, cutlass::float_e3m2_t>) { return "float_e3m2"; } else
  if constexpr (is_same_v<T, cutlass::float_e2m1_t>) { return "float_e2m1"; } else
  { static_assert(sizeof(T) == 0, "Unknown type for typestr"); }
}

template <class CopyOp, class... Args>
CUTE_HOST_DEVICE auto constexpr
is_tma_2cta(cute::Copy_Traits<CopyOp, Args...> const&)
{
  return cute::bool_constant<cute::is_same<CopyOp, cute::SM100_TMA_2SM_LOAD          >::value ||
                             cute::is_same<CopyOp, cute::SM100_TMA_2SM_LOAD_MULTICAST>::value>{};
}

// The shared memory buffers for A and B matrices; and barriers for tracking MMA/TMA completion.
template <class TypeA,           // Tensor A data type
          class TypeB,           // Tensor B data type
          class ASmemLayout,     // (MmaM/2,MmaK), MmaTile_M/MmaM, MmaTile_K/MmaK
          class BSmemLayout>     // (MmaN/2,MmaK), MmaTile_N/MmaN, MmaTile_K/MmaK
struct SharedStorage
{
  alignas(128) cute::ArrayEngine<TypeA, cute::cosize_v<ASmemLayout>> A;
  alignas(128) cute::ArrayEngine<TypeB, cute::cosize_v<BSmemLayout>> B;

  alignas(16) cute::uint64_t mma_barrier;  // Barrier to track MMA computation on SMEM
  alignas(16) cute::uint64_t tma_barrier;  // Barrier to track TMA data transfers to SMEM

  CUTE_DEVICE constexpr auto tensor_sA() {
    return make_tensor(make_smem_ptr(A.begin()), ASmemLayout{});
  }
  CUTE_DEVICE constexpr auto tensor_sB() {
    return make_tensor(make_smem_ptr(B.begin()), BSmemLayout{});
  }
};

template <class Tensor>
void initialize_tensor(Tensor tensor, cute::tuple<int, int> value_range = {0, 2}) {
  using DataType = typename Tensor::element_type;
  auto [min, max] = value_range;
  for (int32_t i = 0; i < cute::size(tensor); i++) {
    tensor(i) = DataType(int((max-min)*(rand() / double(RAND_MAX)) + min));
  }
}

template <class Tensor>
void initialize_tensor(Tensor tensor, int32_t value) {
  using DataType = typename Tensor::element_type;
  for (int32_t i = 0; i < cute::size(tensor); i++) {
    tensor(i) = DataType(value);
  }
}

// The device kernel
template <class ProblemShape_MNK, class MmaTiler_MNK,
          class ClusterShape_MNK,
          class TypeA, class ALayout, class ASmemLayout, class TmaAtomA,
          class TypeB, class BLayout, class BSmemLayout, class TmaAtomB,
          class TypeC, class CLayout,
          class TypeD, class DLayout,
          class TiledMMA,
          class Alpha, class Beta>
__global__ static
void
gemm_device(ProblemShape_MNK problem_shape_mnk, MmaTiler_MNK mma_tiler,
            ClusterShape_MNK cluster_shape_mnk,
            TypeA const* ptr_A, ALayout layout_A, CUTE_GRID_CONSTANT TmaAtomA const tma_atom_A,
            TypeB const* ptr_B, BLayout layout_B, CUTE_GRID_CONSTANT TmaAtomB const tma_atom_B,
            TypeC const* ptr_C, CLayout layout_C,
            TypeD      * ptr_D, DLayout layout_D,
            TiledMMA tiled_mma,
            Alpha alpha, Beta beta)
{
  using namespace cute;

  constexpr bool is_breuse = (size<0>(MmaTiler_MNK{}) == 2 * size<0>(typename TiledMMA::AtomShape_MNK{}));

  // Allocate SMEM
  extern __shared__ char shared_memory[];
  using SharedStorage = SharedStorage<TypeA, TypeB, ASmemLayout, BSmemLayout>;
  SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(shared_memory);

  // Represent the full tensors in global memory
  Tensor mA = tma_atom_A.get_tma_tensor(shape(layout_A));       // (Gemm_M,Gemm_K)
  Tensor mB = tma_atom_B.get_tma_tensor(shape(layout_B));       // (Gemm_N,Gemm_K)
  Tensor mC = make_tensor(make_gmem_ptr(ptr_C), layout_C);      // (Gemm_M,Gemm_N)
  Tensor mD = make_tensor(make_gmem_ptr(ptr_D), layout_D);      // (Gemm_M,Gemm_N)

  Layout cta_layout_mnk = make_layout(cluster_shape_mnk);
  Layout cta_layout_vmnk = tiled_divide(cta_layout_mnk, make_tile(typename TiledMMA::AtomThrID{}));    // (Mma_Ctas, ClusterShape_M/Mma_Ctas, ClusterShape_N, ClusterShape_K)
  auto cta_in_cluster_coord_vmnk = cta_layout_vmnk.get_flat_coord(int(cute::block_rank_in_cluster()));

  // Get the appropriate blocks for this MMA
  // mma coord != cta_coord_in_grid for this example
  auto mma_coord_vmnk = make_coord(
      blockIdx.x % size<0>(cta_layout_vmnk),
      blockIdx.x / size<0>(cta_layout_vmnk),
      blockIdx.y, _);
  auto mma_coord_mnk = take<1,4>(mma_coord_vmnk);

#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  if(thread0()) {
    print("mma_tiler:\t"); print(mma_tiler); print("\n");
    print("cta_layout_mnk:\t"); print(cta_layout_mnk); print("\n");
    print("cta_layout_vmnk:\t"); print(cta_layout_vmnk); print("\n");
    print("cta_in_cluster_coord_vmnk:\t"); print(cta_in_cluster_coord_vmnk); print("\n");
    print("mma_coord_vmnk:\t"); print(mma_coord_vmnk); print("\n");
    print("mma_coord_mnk:\t"); print(mma_coord_mnk); print("\n");
  } __syncthreads();
#endif

  Tensor gA = local_tile(mA, mma_tiler, mma_coord_mnk, Step<_1, X,_1>{});  // (MmaTile_M,MmaTile_K,Gemm_K/MmaTile_K)
  Tensor gB = local_tile(mB, mma_tiler, mma_coord_mnk, Step< X,_1,_1>{});  // (MmaTile_N,MmaTile_K,Gemm_K/MmaTile_K)
  Tensor gC = local_tile(mC, mma_tiler, mma_coord_mnk, Step<_1,_1, X>{});  // (MmaTile_M,MmaTile_N)
  Tensor gD = local_tile(mD, mma_tiler, mma_coord_mnk, Step<_1,_1, X>{});  // (MmaTile_M,MmaTile_N)

#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  if (thread0()) {
    print("mA:\t"); print(mA); print("\n");
    print("mB:\t"); print(mB); print("\n");
    print("mC:\t"); print(mC); print("\n");
    print("mD:\t"); print(mD); print("\n");

    print("gA:\t"); print(gA); print("\n");
    print("gB:\t"); print(gB); print("\n");
    print("gC:\t"); print(gC); print("\n");
    print("gD:\t"); print(gD); print("\n");
  } __syncthreads();
#endif

  //
  // MMA: Define C accumulators and A/B partitioning
  //

  ThrMMA cta_mma = tiled_mma.get_slice(get<0>(mma_coord_vmnk));        // Use Peer CTA coordinate
  // tXgY -> Y tensor from (g)mem partitioned according to MMA's X tensor block
  Tensor tCgA = cta_mma.partition_A(gA);                               // ((Mma_M/2, Mma_K),(MmaTile_M/Mma_M),(MmaTile_K/Mma_K),Gemm_K/MmaTile_K)
  Tensor tCgB = cta_mma.partition_B(gB);                               // ((Mma_N/2, Mma_K),(MmaTile_N/Mma_N),(MmaTile_K/Mma_K),Gemm_K/MmaTile_K)
  Tensor tCgC = cta_mma.partition_C(gC);                               // ((Mma_M/2, Mma_N),(MmaTile_M/Mma_M),(MmaTile_N/Mma_N))
  Tensor tCgD = cta_mma.partition_C(gD);                               // ((Mma_M/2, Mma_N),(MmaTile_M/Mma_M),(MmaTile_N/Mma_N))

#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  if (thread0()) {
    print("tCgA:\t"); print(tCgA); print("\n"); // tCgA:   ArithTuple(_0,0) o ((_128,_16),_1,_4,4):((_1@1,_1@0),_0,_16@0,_64@0)
    print("tCgB:\t"); print(tCgB); print("\n"); // tCgB:   ArithTuple(_0,0) o ((_128,_16),_1,_4,4):((_1@1,_1@0),_0,_16@0,_64@0)
    print("tCgC:\t"); print(tCgC); print("\n"); // tCgC:   gmem_ptr[32b](GMEM_ADDR_C + offset_for_mma_tile + offset_for_mma) o ((_128,_256),_1,_1):((256,_1),_0,_0)
    print("tCgD:\t"); print(tCgD); print("\n"); // tCgD:   gmem_ptr[32b](GMEM_ADDR_D + offset_for_mma_tile + offset_for_mma) o ((_128,_256),_1,_1):((256,_1),_0,_0)
  }__syncthreads();
#endif
  // The SMEM tensors
  // Represent the SMEM buffers for A and B
  Tensor tCsA = shared_storage.tensor_sA();       // (MmaA, NumMma_M, NumMma_K, NumTile_K)
  Tensor tCsB = shared_storage.tensor_sB();       // (MmaB, NumMma_M, NumMma_K, NumTile_K)

  // MMA Fragment Allocation
  Tensor tCrA = cta_mma.make_fragment_A(tCsA);   // (Mma_M/2,Mma_K),(MmaTile_M/Mma_M),(MmaTile_K/Mma_K)
  Tensor tCrB = cta_mma.make_fragment_B(tCsB);   // (Mma_N/2,Mma_K),(MmaTile_N/Mma_M),(MmaTile_K/Mma_K)
  // TMEM Allocation
  Tensor tCtAcc = cta_mma.make_fragment_C(tCgC); // (Mma_M/2,Mma_N),(MmaTile_M/Mma_M),(MmaTile_N/Mma_N)

#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  if (thread0()) {
    print("tCsA:\t"); print(tCsA); print("\n");   // tCsA:   Sw<3,4,3>_smem_ptr[16b](SMEM_ADDR_A) o ((_128,_16),_1,_4):((_64,_1),_0,_16)
    print("tCsB:\t"); print(tCsB); print("\n");   // tCsB:   Sw<3,4,3>_smem_ptr[16b](SMEM_ADDR_B) o ((_128,_16),_1,_4):((_64,_1),_0,_16)
    print("tCrA:\t"); print(tCrA); print("\n");   // tCrA:   UMMA::DescriptorIterator o (_1,_1,_4):(_0,_0,_2)
    print("tCrB:\t"); print(tCrB); print("\n");   // tCrB:   UMMA::DescriptorIterator o (_1,_1,_4):(_0,_0,_2)
    print("tCtAcc:\t"); print(tCtAcc); print("\n"); // tCtAcc: tmem_[32b](TMEM_ADDR) o ((_128,_256),_1,_1):((_65536,_1),_0,_0)
  } __syncthreads();
#endif

  //
  // TMA Setup
  //
  // Project the cta_layout for tma_a along the n-modes
  auto [tAgA, tAsA] = tma_partition(tma_atom_A,
                                    get<2>(cta_in_cluster_coord_vmnk), make_layout(size<2>(cta_layout_vmnk)),
                                    group_modes<0,3>(tCsA), group_modes<0,3>(tCgA));

  // Project the cta_layout for tma_b along the m-modes
  auto [tBgB, tBsB] = tma_partition(tma_atom_B,
                                    get<1>(cta_in_cluster_coord_vmnk), make_layout(size<1>(cta_layout_vmnk)),
                                    group_modes<0,3>(tCsB), group_modes<0,3>(tCgB));

#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  if (thread0()) {
    print("tAgA:\t"); print(tAgA); print("\n"); // tAgA:   ArithTuple(0,0) o (((_64,_128),_1),4):(((_1@0,_1@1),_0),_64@0)
    print("tAsA:\t"); print(tAsA); print("\n"); // tAsA:   Sw<3,4,3>_smem_ptr[16b](SMEM_ADDR_A) o ((_8192,_1)):((_1,_0))
    print("tBgB:\t"); print(tBgB); print("\n"); // tBgB:   ArithTuple(0,0) o (((_64,_128),_1),4):(((_1@0,_1@1),_0),_64@0)
    print("tBsB:\t"); print(tBsB); print("\n"); // tBsB:   Sw<3,4,3>_smem_ptr[16b](SMEM_ADDR_B) o ((_8192,_1)):((_1,_0))
  } __syncthreads();
#endif

  int32_t tma_transaction_bytes = 0;
  // The leader CTA's transaction barrier will wait for all A and B transactions for both peer CTAs.
  tma_transaction_bytes += size<0>(cta_layout_vmnk) * sizeof(cute::ArrayEngine<TypeA, size_v<decltype(filter_zeros(tAsA))>>);
  tma_transaction_bytes += size<0>(cta_layout_vmnk) * sizeof(cute::ArrayEngine<TypeB, size_v<decltype(filter_zeros(tBsB))>>);

#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  if (thread0()) {
    printf("TmaBytes: %d\n", tma_transaction_bytes);
  }
#endif

  // We need to calculate the mask for CTAs in cluster that are participating
  // in multicast with this CTA.
  uint16_t tma_mcast_mask_a = 0;
  uint16_t tma_mcast_mask_a_pair = 0; // Mma is executed on the leader CTA. The leader also needs to handle the syncronization for the peer CTA.
  int32_t pair_index = (get<0>(cta_in_cluster_coord_vmnk) == 0 ? 1 : 0);
  {
    uint16_t mask = 0;
    CUTE_UNROLL
    for (int32_t n = 0; n < size<2>(cta_layout_vmnk); ++n) {
      mask |= uint16_t(1) << cta_layout_vmnk(0,0,n,0);
    }
    // Shift by the instruction's elected block rank (dynamic)
    int32_t cta_rank = cta_layout_vmnk(get<0>(cta_in_cluster_coord_vmnk), get<1>(cta_in_cluster_coord_vmnk), 0, get<3>(cta_in_cluster_coord_vmnk));
    int32_t cta_rank_pair = cta_layout_vmnk(pair_index, get<1>(cta_in_cluster_coord_vmnk), 0, get<3>(cta_in_cluster_coord_vmnk));

    tma_mcast_mask_a = mask << cta_rank;
    tma_mcast_mask_a_pair = mask << cta_rank_pair;
  }

  uint16_t tma_mcast_mask_b = 0;
  uint16_t tma_mcast_mask_b_pair = 0; // Mma is executed on the leader CTA. The leader also needs to handle the syncronization for the peer CTA.
  {
    // Get the instruction code
    uint16_t mask = 0;
    CUTE_UNROLL
    for (int32_t m = 0; m < size<1>(cta_layout_vmnk); ++m) {
      mask |= uint16_t(1) << cta_layout_vmnk(0,m,0,0);
    }
    // Shift by the instruction's elected block rank (dynamic)
    int32_t cta_rank = cta_layout_vmnk(get<0>(cta_in_cluster_coord_vmnk), 0, get<2>(cta_in_cluster_coord_vmnk), get<3>(cta_in_cluster_coord_vmnk));
    int32_t cta_rank_pair = cta_layout_vmnk(pair_index, 0, get<2>(cta_in_cluster_coord_vmnk), get<3>(cta_in_cluster_coord_vmnk));
    tma_mcast_mask_b = mask << cta_rank;
    tma_mcast_mask_b_pair = mask << cta_rank_pair;
  }

  uint16_t mma_mask = tma_mcast_mask_a | tma_mcast_mask_b | tma_mcast_mask_a_pair | tma_mcast_mask_b_pair;

#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  if (thread0()) {
    printf("tma_a_mask: %x\n",tma_mcast_mask_a);
    printf("tma_b_mask: %x\n",tma_mcast_mask_b);
    printf("mma_mask: %x\n",mma_mask);
  }
#endif

  uint32_t elect_one_thr  = cute::elect_one_sync();
  uint32_t elect_one_warp = (threadIdx.x / 32 == 0);
  uint32_t elect_one_cta = get<0>(cta_in_cluster_coord_vmnk) == 0;

  // Calculate the number of CTAs that participates in multicast operation with this CTA (for both A and B matrices)
  int32_t num_mcast_participants = size<1>(cta_layout_vmnk) + size<2>(cta_layout_vmnk) - 1;
  // Barriers in SMEM should be initialized by a single thread.

#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  if(thread0()){
    printf("Number of multicast participants: %d\n", num_mcast_participants);
  }
#endif
  if (elect_one_warp && elect_one_thr) {
    // Initialize MMA barrier
    cute::initialize_barrier(shared_storage.mma_barrier, /* num_ctas */ num_mcast_participants); // All CTAs that participates in multicast operation with this CTA should synchronize for buffer empty.
                                                                                                     // Note that since the MMA will be executed by only half of the CTAs, the arrival on the m-mode of cluster are halved.
    cute::initialize_barrier(shared_storage.tma_barrier, /* num_threads */ 1);
  }
  int32_t consumer_mma_barrier_phase_bit = 0;  // Each barrier has associated phase_bit.

  int32_t tma_barrier_phase_bit = 0;   // Each barrier has associated phase_bit.

  // Make sure all threads in the CTA across all CTAs in the cluster observe the barrier initialization
  cute::cluster_sync();

  // Set accumlate option to zero so that the first MMA instruction will clear the TMEM accumulator.
  tiled_mma.accumulate_ = UMMA::ScaleOut::Zero;

  // Step 2: The Mainloop

  // Execute a MmaTile_M x MmaTile_N x GEMM_K GEMM
  for (int32_t k_tile = 0; k_tile < size<3>(tCgA); ++k_tile) {

    // Step 2a: Load A and B tiles
    if (elect_one_warp && elect_one_thr) { // TMA loads are executed by one thread
      if (elect_one_cta) { // Only the leader CTA will need to wait for TMA transactions
        cute::set_barrier_transaction_bytes(shared_storage.tma_barrier, tma_transaction_bytes); // Set the expected transaction bytes for the TMA loads
      }
      copy(tma_atom_A.with(shared_storage.tma_barrier,tma_mcast_mask_a), tAgA(_,k_tile), tAsA); // Load MmaTile_M x MmaTile_K A tile
      copy(tma_atom_B.with(shared_storage.tma_barrier,tma_mcast_mask_b), tBgB(_,k_tile), tBsB); // Load MmaTile_N x MmaTile_K B tile
    }
    // Step 2b: Execute the MMAs for this tile
    if (elect_one_cta) {

      cute::wait_barrier(shared_storage.tma_barrier, tma_barrier_phase_bit);
      tma_barrier_phase_bit ^= 1;

      if (elect_one_warp) {
        // Execute a MmaTile_M x MmaTile_N x MmaTile_K GEMM
        for (int32_t k_block = 0; k_block < size<2>(tCrA); ++k_block) {
          if constexpr (is_breuse) {
            // tCrA: (Mma_M/2,Mma_K),(MmaTile_M/Mma_M),(MmaTile_K/Mma_K)
            static_assert(size<1>(tCrA) == 2,
                          "The b-reuse feature expects size<1>(tCrA) == 2.");
            // tCrB: (Mma_N/2,Mma_K),(MmaTile_N/Mma_M),(MmaTile_K/Mma_K)
            static_assert(size<1>(tCrB) == 1,
                          "The b-reuse feature expects size<1>(tCrB) == 1.");
            // tCtAcc: (Mma_M/2,Mma_N),(MmaTile_M/Mma_M),(MmaTile_N/Mma_N)
            static_assert(size<1>(tCtAcc) == 2,
                          "The b-reuse feature expects size<1>(tCtAcc) == 2.");
            gemm(tiled_mma.with(C<UMMA::BMatrixBufferReuse::Keep>{}),
                 tCrA(_,0,k_block),
                 tCrB(_,0,k_block),
                 tCtAcc(_,0,0));
            gemm(tiled_mma.with(C<UMMA::BMatrixBufferReuse::Reuse>{}),
                 tCrA(_,1,k_block),
                 tCrB(_,0,k_block),
                 tCtAcc(_,1,0));
          } else {
            gemm(tiled_mma, tCrA(_,_,k_block), tCrB(_,_,k_block), tCtAcc);
          }
          tiled_mma.accumulate_ = UMMA::ScaleOut::One;
        }

        // Ensure MMAs are completed, only then we can reuse the A and B buffers.
        // All participating CTAs should be encoded in the mask.
        // Since only the leader CTA executes MMA, it should also send arrivals for its peer CTA.
        constexpr bool is_all_tma_2cta = is_tma_2cta(tma_atom_A) && is_tma_2cta(tma_atom_B);
        if constexpr (is_all_tma_2cta) {
          cutlass::arch::umma_arrive_multicast_2x1SM(&shared_storage.mma_barrier, mma_mask);
        } else {
          cutlass::arch::umma_arrive_multicast(&shared_storage.mma_barrier, mma_mask);
        }
      }
    }
    // Wait MMAs to complete to avoid overwriting the A and B buffers on all threads.
    cute::wait_barrier(shared_storage.mma_barrier, consumer_mma_barrier_phase_bit);
    consumer_mma_barrier_phase_bit ^= 1; // flip the phase
  }

  // Now, MmaTile_M x MmaTile_N result for the 2 CTA MMA is ready.
  // Now, both peer CTAs can go ahead and read their TMEM accumulator.
  __syncthreads(); // Not really needed.

  // Step 3: Execute epilogue.

  using TMEM_LOAD = SM100_TMEM_LOAD_32dp32b1x;

  // Create the tiled copy operation for the accumulator (TMEM -> Registers)
  auto tiled_t2r_copy = make_tmem_copy(TMEM_LOAD{}, tCtAcc);
  auto thr_tiled_t2r_copy = tiled_t2r_copy.get_slice(threadIdx.x);
  Tensor tDtAcc = thr_tiled_t2r_copy.partition_S(tCtAcc);               // ((TMEM_LOAD,#TMEM_LOAD),MMA_M,MMA_N)
  Tensor tDgC = thr_tiled_t2r_copy.partition_D(tCgC);                   // ((TMEM_LOAD,#TMEM_LOAD),MMA_M,MMA_N)
  Tensor tDgD = thr_tiled_t2r_copy.partition_D(tCgD);                   // ((TMEM_LOAD,#TMEM_LOAD),MMA_M,MMA_N)

  Tensor tDrAcc = make_tensor<TypeC>(shape(tDgC));                      // ((TMEM_LOAD,#TMEM_LOAD),MMA_M,MMA_N)
  Tensor tDrC = make_tensor<TypeC>(shape(tDgC));

  // Load TMEM
  copy(tiled_t2r_copy, tDtAcc, tDrAcc);
  // Load C tensor
  copy(tDgC, tDrC);
  // AXPBY rmem -> rmem, D = alpha * (A*B) + beta * C
  axpby(alpha, tDrAcc, beta, tDrC);
  // Copy the result to D tensor
  copy(tDrC, tDgD);
}


// Host-side GEMM Configuration and Launch
template <class MmaShape_MNK, class MmaTiler_MNK,
          bool Is2Cta, int32_t ClusterM, int32_t ClusterN,
          class ProblemShape_MNK,
          class TypeA = cutlass::float_e4m3_t,
          class TypeB = cutlass::float_e4m3_t,
          UMMA::Major AMajor = UMMA::Major::K,
          UMMA::Major BMajor = UMMA::Major::K>
void test_gemm(ProblemShape_MNK problem_shape_mnk)
{
  // Get M, N, K dimensions of the GEMM we are running
  auto Gemm_M = get<0>(problem_shape_mnk);
  auto Gemm_N = get<1>(problem_shape_mnk);
  auto Gemm_K = get<2>(problem_shape_mnk);
  std::cout << "Running for problem shape (MxNxK): " << Gemm_M << "x" << Gemm_N
            << "x" << Gemm_K << std::endl;
  if (!evenly_divides(take<0, 2>(problem_shape_mnk),
                      take<0, 2>(MmaTiler_MNK{}))) {
    std::cerr << "OOB accesses are not supported. MmaTiler_MNK should evenly "
                 "divide GEMM_MNK."
              << std::endl;
    return;
  }

  print("MmaShape_MNK:\t"); print(MmaShape_MNK{}); print("\n");
  print("MmaTiler_MNK:\t"); print(MmaTiler_MNK{}); print("\n");
  printf("A=%s  B=%s\n",
         AMajor == UMMA::Major::K ? "K-major" : "M-major",
         BMajor == UMMA::Major::K ? "K-major" : "N-major");

  // Define the data types. A and B types are same for MMA instruction.
  auto type_str_a = typestr<TypeA>();
  auto type_str_b = typestr<TypeB>();
  using TypeC = float;
  [[maybe_unused]] auto type_str_c = "float";
  using TypeD = float;
  auto type_str_d = "float";
  using TypeAccumulator = float;
  using TypeAlpha = float;
  using TypeBeta = float;

  // A tensor (Gemm_M,Gemm_K): K-major -> row-major (stride Gemm_K,1); MN-major -> col-major (stride 1,Gemm_M)
  auto layout_A = [&]() {
    if constexpr (AMajor == UMMA::Major::K) {
      return make_layout(make_shape(Gemm_M, Gemm_K), make_stride(Gemm_K, Int<1>{}));
    } else {
      return make_layout(make_shape(Gemm_M, Gemm_K), make_stride(Int<1>{}, Gemm_M));
    }
  }();
  thrust::host_vector<TypeA> host_A(size(filter_zeros(layout_A)));
  auto host_tensor_A = make_tensor(iterator_t<TypeA>{host_A.data()}, layout_A);

  initialize_tensor(host_tensor_A, make_tuple(0, 2));
  thrust::device_vector<TypeA> device_A = host_A;
  auto device_tensor_A = make_tensor(device_A.data().get(), layout_A);
#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  print("host_tensor_A:\t"); print(host_tensor_A); print("\n");
#endif

  // B tensor (Gemm_N,Gemm_K): K-major -> row-major (stride Gemm_K,1); MN-major -> col-major (stride 1,Gemm_N)
  auto layout_B = [&]() {
    if constexpr (BMajor == UMMA::Major::K) {
      return make_layout(make_shape(Gemm_N, Gemm_K), make_stride(Gemm_K, Int<1>{}));
    } else {
      return make_layout(make_shape(Gemm_N, Gemm_K), make_stride(Int<1>{}, Gemm_N));
    }
  }();
  thrust::host_vector<TypeB> host_B(size(filter_zeros(layout_B)));
  auto host_tensor_B = make_tensor(iterator_t<TypeB>{host_B.data()}, layout_B);

  initialize_tensor(host_tensor_B, make_tuple(0, 2));
  thrust::device_vector<TypeB> device_B = host_B;
  auto device_tensor_B = make_tensor(device_B.data().get(), layout_B);
#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  print("host_tensor_B:\t"); print(host_tensor_B); print("\n");
#endif
  // C tensor (Gemm_M,Gemm_N)
  auto layout_C = make_layout(make_shape(Gemm_M, Gemm_N),
                                make_stride(Gemm_N, Int<1>{}));   
  thrust::host_vector<TypeC>   host_C(Gemm_M * Gemm_N);
  Tensor host_tensor_C = make_tensor(host_C.data(), layout_C);

  initialize_tensor(host_tensor_C, 0);
  thrust::device_vector<TypeC> device_C = host_C;
#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  print("host_tensor_C:\t"); print(host_tensor_C); print("\n");
#endif

  // D tensor MxN (Gemm_M,Gemm_N)
  auto layout_D = make_layout(make_shape (Gemm_M,   Gemm_N),
                                make_stride(Gemm_N, Int<1>{}));   // :(Gemm_N,_1)
  // Note that we don't need a host_tensor for D yet.
  thrust::device_vector<TypeD> device_D(Gemm_M * Gemm_N);

  ////////////////////////////////////////////////////////////
  //
  // Initialize the GEMM kernel parameters
  //
  ////////////////////////////////////////////////////////////

  cute::TiledMMA tiled_mma = [&]() {
    constexpr int MmaM = cute::size<0>(MmaShape_MNK{});
    constexpr int MmaN = cute::size<1>(MmaShape_MNK{});
    constexpr int MmaK = cute::size<2>(MmaShape_MNK{});
    constexpr bool is_breuse = (size<0>(MmaTiler_MNK{}) == 2 * MmaM);
    if constexpr (Is2Cta) {
      if constexpr (is_breuse) {
        // For the case of b-reuse and .2CTA instructions, we permute the M mode
        // such that each CTA within a pair contains a consecutive portion of the A tensor
        auto permutation_mnk = make_tile(
          Layout<Shape<_128, _2, _2>, Stride<_1, _256, _128>>{},
          cute::Int<MmaN>{},
          cute::Int<MmaK>{});
        return make_tiled_mma(
              MMA_Traits<SM107_MMA_F8F6F4_2x1SM_SS<
                          TypeA, TypeB, TypeC, MmaM, MmaN, AMajor,
                          BMajor, UMMA::ScaleIn::One, UMMA::ScaleIn::One>>{},
              Layout<Shape<_1, _1, _1>>{},
              permutation_mnk);
      } else {
        return make_tiled_mma(
              MMA_Traits<SM107_MMA_F8F6F4_2x1SM_SS<
                          TypeA, TypeB, TypeC, MmaM, MmaN, AMajor,
                          BMajor, UMMA::ScaleIn::One, UMMA::ScaleIn::One>>{});
      }
    } else {
      return make_tiled_mma(
            MMA_Traits<SM107_MMA_F8F6F4_SS<
                        TypeA, TypeB, TypeC, MmaM, MmaN, AMajor,
                        BMajor, UMMA::ScaleIn::One, UMMA::ScaleIn::One>>{});
    }
  }();
  static_assert(size<2>(typename decltype(tiled_mma)::AtomShape_MNK{}) ==
                    size<2>(MmaShape_MNK{}),
                "tiled_mma atom K-mode does not match MmaK");

  // We can also print and inspect the tiled_mma
#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  print("tiled_mma:\t"); print(tiled_mma); print("\n");
#endif

  auto mma_shape_A = partition_shape_A(tiled_mma, make_shape(size<0>(MmaTiler_MNK{}),
                                                             size<2>(MmaTiler_MNK{})));

  auto mma_shape_B = partition_shape_B(tiled_mma, make_shape(size<1>(MmaTiler_MNK{}),
                                                             size<2>(MmaTiler_MNK{})));

  // Print and inspect mma_shape_A, and mma_shape_B for this example.
#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  print("mma_shape_A:\t"); print(mma_shape_A); print("\n"); // mma_shape_A:    ((_128,_16),_1,_4)
  print("mma_shape_B:\t"); print(mma_shape_B); print("\n"); // mma_shape_B:    ((_128,_16),_1,_4)
#endif

  auto sA_layout = [&]() {
    if constexpr (AMajor == UMMA::Major::K) {
      return UMMA::tile_to_mma_shape(UMMA::Layout_K_SW128_Atom<TypeA>{}, mma_shape_A);
    } else {
      return UMMA::tile_to_mma_shape(UMMA::Layout_MN_SW128_Atom<TypeA>{}, mma_shape_A);
    }
  }();
  auto sB_layout = [&]() {
    if constexpr (BMajor == UMMA::Major::K) {
      return UMMA::tile_to_mma_shape(UMMA::Layout_K_SW128_Atom<TypeB>{}, mma_shape_B);
    } else {
      return UMMA::tile_to_mma_shape(UMMA::Layout_MN_SW128_Atom<TypeB>{}, mma_shape_B);
    }
  }();
  // Print and inspect sA_layout and sB_layout for this example.
#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  print("sA_layout:\t"); print(sA_layout); print("\n");
  print("sB_layout:\t"); print(sB_layout); print("\n");
#endif
  // Now we can find the SMEM allocation size
  using ASmemLayout = decltype(sA_layout);
  using BSmemLayout = decltype(sB_layout);
  constexpr int32_t smemBytes = sizeof(SharedStorage<TypeA, TypeB, ASmemLayout, BSmemLayout>);

  // TMA descriptor needs to be created on host
  using ClusterShape = Shape<Int<ClusterM>, Int<ClusterN>, Int<1>>;
  auto cluster_layout_mnk = make_layout(ClusterShape{});
  Layout cluster_layout_vmnk =
    tiled_divide(cluster_layout_mnk,
                make_tile(typename decltype(tiled_mma)::AtomThrID{}));

  auto tma_load_op = []() {
    if constexpr (Is2Cta == false) {
      return SM90_TMA_LOAD_MULTICAST{};
    } else {
      return SM100_TMA_2SM_LOAD_MULTICAST{};
    }
  };

  auto tma_op_a = tma_load_op();
  auto tma_op_b = tma_load_op();

  // This is the correct SM100 interface for creating TMA loads.
  cute::Copy_Atom tma_atom_A = cute::make_tma_atom_A_sm100(
        tma_op_a, device_tensor_A, sA_layout, MmaTiler_MNK{}, tiled_mma, cluster_layout_vmnk);
#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  print("tma_atom_A:\t"); print(tma_atom_A); print("\n");
#endif

  // This is the correct SM100 interface
  cute::Copy_Atom tma_atom_B = cute::make_tma_atom_B_sm100(
        tma_op_b, device_tensor_B, sB_layout, MmaTiler_MNK{}, tiled_mma, cluster_layout_vmnk);
#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  print("tma_atom_B:\t"); print(tma_atom_B); print("\n");
#endif

  ////////////////////////////////////////////////////////////
  //
  // Launch GEMM kernel
  //
  ////////////////////////////////////////////////////////////

  dim3 dimBlock(128);
  dim3 dimCluster(size<0>(cluster_layout_mnk),
                  size<1>(cluster_layout_mnk),
                  size<2>(cluster_layout_mnk));

  // We need to roundup the grid dimensions to make the grid launched a multiple
  // of ClusterShape_MNK
  dim3 dimGrid(
      cute::round_up(cute::ceil_div(Gemm_M, cute::get<0>(MmaTiler_MNK{}) /
                                                size<0>(cluster_layout_vmnk)),
                     dimCluster.x),
      cute::round_up(cute::ceil_div(Gemm_N, cute::get<1>(MmaTiler_MNK{})),
                     dimCluster.y));

  auto* kernel_ptr = &gemm_device <
                      ProblemShape_MNK, MmaTiler_MNK,
                      ClusterShape,
                      TypeA, decltype(layout_A), ASmemLayout, decltype(tma_atom_A),
                      TypeB, decltype(layout_B), BSmemLayout, decltype(tma_atom_B),
                      TypeC, decltype(layout_C),
                      TypeD, decltype(layout_D),
                      decltype(tiled_mma),
                      TypeAlpha, TypeBeta
                    >;

#if defined(CUTE_EXAMPLE_PRINT_LAYOUTS)
  printf("Grid launched: %d, %d, %d\n", dimGrid.x, dimGrid.y, dimGrid.z);
  printf("Cluster launched: %d, %d, %d\n", dimCluster.x, dimCluster.y, dimCluster.z);
  printf("Smem bytes: %d\n", smemBytes);
#endif
  // Set kernel attributes (set SMEM)
  auto status_ = cudaFuncSetAttribute(
      *kernel_ptr, cudaFuncAttributeMaxDynamicSharedMemorySize, smemBytes);
  if (status_ != cudaSuccess) {
    std::cerr << "Error: Failed to set Shared Memory size." << std::endl;
    return;
  }

  TypeAlpha alpha = 1;
  TypeBeta beta = 1;

  // Launch kernel with TMA parameters and cluster shape
  cudaStream_t stream = 0;
  cutlass::ClusterLaunchParams params = {dimGrid, dimBlock, dimCluster, smemBytes, stream};
  cutlass::Status status = cutlass::launch_kernel_on_cluster(params, (void const*) kernel_ptr,
      problem_shape_mnk, MmaTiler_MNK{},
      shape(cluster_layout_mnk),
      device_A.data().get(), layout_A, tma_atom_A,
      device_B.data().get(), layout_B, tma_atom_B,
      device_C.data().get(), layout_C,
      device_D.data().get(), layout_D,
      tiled_mma,
      alpha, beta);

  CUTE_CHECK_LAST();

  if (status != cutlass::Status::kSuccess) {
    std::cerr << "Error: Failed at kernel Launch" << std::endl;
    return;
  }

  // Host allocation for D tensor and transfer D tensor from device to host
  thrust::host_vector<TypeD> host_D = device_D;
  // Create a non-owning CuTe tensor for D tensor
  Tensor host_tensor_D = make_tensor(host_D.data(), layout_D);

  ////////////////////////////////////////////////////////////
  //
  // Execute reference GEMM kernel
  //
  ////////////////////////////////////////////////////////////

  thrust::host_vector<TypeD> host_reference_D(Gemm_M*Gemm_N);
  auto host_reference_tensor_D = make_tensor(host_reference_D.data(), layout_D);
  // AMajor=K  -> A (M,K) row-major    -> RowMajor(K)    for MxK reference
  // AMajor=MN -> A (M,K) col-major    -> ColumnMajor(M) for MxK reference
  // BMajor=K  -> B (N,K) K-contiguous -> ColumnMajor(K) for KxN reference
  // BMajor=MN -> B (N,K) N-contiguous -> RowMajor(N)    for KxN reference
  auto ref_A = [&]() {
    if constexpr (AMajor == UMMA::Major::K) {
      return cutlass::make_TensorRef(host_A.data(), cutlass::layout::RowMajor(Gemm_K));
    } else {
      return cutlass::make_TensorRef(host_A.data(), cutlass::layout::ColumnMajor(Gemm_M));
    }
  }();
  auto ref_B = [&]() {
    if constexpr (BMajor == UMMA::Major::K) {
      return cutlass::make_TensorRef(host_B.data(), cutlass::layout::ColumnMajor(Gemm_K));
    } else {
      return cutlass::make_TensorRef(host_B.data(), cutlass::layout::RowMajor(Gemm_N));
    }
  }();
  cutlass::reference::host::compute_gemm(
      cutlass::gemm::GemmCoord(Gemm_M, Gemm_N, Gemm_K),
      alpha, ref_A, ref_B, beta,
      cutlass::make_TensorRef(host_reference_D.data(), cutlass::layout::RowMajor(Gemm_N)),
      TypeAccumulator(0));

  ////////////////////////////////////////////////////////////
  //
  // Compare results
  //
  ////////////////////////////////////////////////////////////

  auto relative_error = print_matrix_multiply_mollified_relative_error(
      type_str_a, host_tensor_A, type_str_b, host_tensor_B, type_str_d,
      host_tensor_D, host_reference_tensor_D);
  bool success = relative_error <= 0.0;
  std::cout << "Execution is " << ((success) ? "successful." : "failed.")
            << std::endl;
}

int32_t main(int32_t argc, char **argv) {
  // Query the device properties and make sure we are running on Rubin SM107
  // GPUs
  cudaDeviceProp props;
  int32_t current_device_id;
  cudaGetDevice(&current_device_id);
  cudaError_t error = cudaGetDeviceProperties(&props, current_device_id);
  if (!(props.major == 10 && props.minor == 7)) {
    std::cerr << "This example requires NVIDIA's Rubin Architecture GPU with "
                 "compute capability 107a.\n";
    return 0;
  }
#if defined(CUTLASS_ARCH_MMA_SM107_SUPPORTED)
  int32_t Gemm_M = 512;
  if (argc >= 2)
    sscanf(argv[1], "%d", &Gemm_M);

  int32_t Gemm_N = 1024;
  if (argc >= 3)
    sscanf(argv[2], "%d", &Gemm_N);

  int32_t Gemm_K = 256;
  if (argc >= 4)
    sscanf(argv[3], "%d", &Gemm_K);

  ////////////////////////////////////////////////////////////
  //
  // Create A, B, C, and D tensors
  //
  ////////////////////////////////////////////////////////////

  auto problem_shape = cute::make_shape(Gemm_M, Gemm_N, Gemm_K);

  // Setup input and output tensors, and the kernel parameters; 
  // and execute the kernel on device

  constexpr int32_t clusterM = 2;
  constexpr int32_t clusterN = 2;

  // MMA instruction: 128x128x64
  // MMA tiler:       128x128x128
  // without b-reuse
  test_gemm<Shape<_128, _128, _64>,
            Shape<_128, _128, _128>,
            false, clusterM, clusterN,
            decltype(problem_shape),
            cutlass::float_e4m3_t, cutlass::float_e4m3_t,
            UMMA::Major::K,  UMMA::Major::K
            >(problem_shape);

  // MMA instruction: 128x128x64
  // MMA tiler:       256x128x128
  // with b-reuse
  test_gemm<Shape<_128, _128, _64>,
            Shape<_256, _128, _128>,
            false, clusterM, clusterN,
            decltype(problem_shape),
            cutlass::float_e4m3_t, cutlass::float_e4m3_t,
            UMMA::Major::K,  UMMA::Major::MN
            >(problem_shape);

  // MMA instruction: 256x256x64
  // MMA tiler:       256x256x128
  // without b-reuse
  test_gemm<Shape<_256, _256, _64>,
            Shape<_256, _256, _128>,
            true, clusterM, clusterN,
            decltype(problem_shape),
            cutlass::float_e4m3_t, cutlass::float_e4m3_t,
            UMMA::Major::MN, UMMA::Major::K
            >(problem_shape);

  // MMA instruction: 256x256x64
  // MMA tiler:       512x256x128
  // with b-reuse
  test_gemm<Shape<_256, _256, _64>,
            Shape<_512, _256, _128>,
            true, clusterM, clusterN,
            decltype(problem_shape),
            cutlass::float_e4m3_t, cutlass::float_e4m3_t,
            UMMA::Major::MN, UMMA::Major::MN
            >(problem_shape);

#else
  std::cout << "CUTLASS_ARCH_MMA_SM107_SUPPORTED must be enabled, but it is "
               "not. This example requires SM107 (Rubin) architecture."
            << std::endl;
#endif
}
