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
#include <cutlass/detail/sm107_blockscaled_layout.hpp>
#include "cutlass/util/reference/host/gett.hpp"
#include "cutlass/detail/sm100_tmem_helper.hpp"

// CuTe includes
#include <cute/tensor.hpp>                      // CuTe tensor implementation
#include <cute/arch/cluster_sm90.hpp>           // CuTe functions for querying the details of cluster launched
#include <cute/arch/cluster_sm100.hpp>
#include <cute/numeric/integral_constant.hpp>   // Compile time in constants such as _1, _256 etc.
#include <cute/algorithm/cooperative_copy.hpp>

using namespace cute;

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

template <class CopyOp, class... TraitsArgs, class... AtomArgs>
CUTE_HOST_DEVICE auto constexpr
is_tma_2cta(cute::Copy_Atom<cute::Copy_Traits<CopyOp, TraitsArgs...>, AtomArgs...> const&)
{
  return cute::bool_constant<cute::is_same<CopyOp, cute::SM100_TMA_2SM_LOAD          >::value ||
                             cute::is_same<CopyOp, cute::SM100_TMA_2SM_LOAD_MULTICAST>::value>{};
}

// The shared memory buffers for A and B matrices; and barriers for tracking MMA/TMA completion.
template <class TypeA,            // Tensor A data type
          class TypeB,            // Tensor B data type
          class TypeSFA,          // Tensor SFA data type
          class TypeSFB,          // Tensor SFB data type
          class ASmemLayout,      // (MmaM/2,MmaK), MmaTile_M/MmaM, MmaTile_K/MmaK
          class BSmemLayout,      // (MmaN/2,MmaK), MmaTile_N/MmaN, MmaTile_K/MmaK
          class SFASmemLayout,
          class SFBSmemLayout>
struct SharedStorage
{
  alignas(128) cute::ArrayEngine<TypeA, cute::cosize_v<ASmemLayout>> A;
  alignas(128) cute::ArrayEngine<TypeB, cute::cosize_v<BSmemLayout>> B;
  alignas(128) cute::ArrayEngine<TypeSFA, cute::cosize_v<SFASmemLayout>> SFA;
  alignas(128) cute::ArrayEngine<TypeSFB, cute::cosize_v<SFBSmemLayout>> SFB;

  alignas(16) cute::uint64_t mma_barrier;  // Barrier to track MMA computation on SMEM
  alignas(16) cute::uint64_t tma_barrier;  // Barrier to track TMA data transfers to SMEM

  CUTE_DEVICE constexpr auto tensor_sA() {
    return make_tensor(make_smem_ptr(A.begin()), ASmemLayout{});
  }
  CUTE_DEVICE constexpr auto tensor_sB() {
    return make_tensor(make_smem_ptr(B.begin()), BSmemLayout{});
  }
  CUTE_DEVICE constexpr auto tensor_sSFA() {
    return make_tensor(make_smem_ptr(SFA.begin()), SFASmemLayout{});
  }
  CUTE_DEVICE constexpr auto tensor_sSFB() {
    return make_tensor(make_smem_ptr(SFB.begin()), SFBSmemLayout{});
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
template <class ProblemShape_MNK,
          class ClusterShape_MNK,
          class TypeA, class ALayout, class ASmemLayout, class TmaAtomA,
          class TypeSFA, class SFALayout, class SFASmemLayout, class TmaAtomSFA,
          class TypeB, class BLayout, class BSmemLayout, class TmaAtomB,
          class TypeSFB, class SFBLayout, class SFBSmemLayout, class TmaAtomSFB,
          class TypeC, class CLayout,
          class TypeD, class DLayout,
          class TiledMMA,
          class SFBTiledMMA,
          class MmaTiler_MNK,
          class Alpha, class Beta,
          bool Verbose = false>
__global__ static
void
gemm_device(ProblemShape_MNK problem_shape_mnk,
            ClusterShape_MNK cluster_shape_mnk,
            TypeA const* ptr_A, ALayout layout_A, CUTE_GRID_CONSTANT TmaAtomA const tma_atom_A,
            TypeSFA const* ptr_SFA, SFALayout layout_SFA, CUTE_GRID_CONSTANT TmaAtomSFA const tma_atom_SFA,
            TypeB const* ptr_B, BLayout layout_B, CUTE_GRID_CONSTANT TmaAtomB const tma_atom_B,
            TypeSFB const* ptr_SFB, SFBLayout layout_SFB, CUTE_GRID_CONSTANT TmaAtomSFB const tma_atom_SFB,
            TypeC const* ptr_C, CLayout layout_C,
            TypeD      * ptr_D, DLayout layout_D,
            TiledMMA tiled_mma,
            SFBTiledMMA sfb_tiled_mma,
            MmaTiler_MNK mma_tiler,
            Alpha alpha, Beta beta)
{
  using namespace cute;

  // b-reuse is enabled if the M-mode of a MMA tile contains two MMA
  // instrcutions.
  constexpr bool is_breuse = (size<0>(MmaTiler_MNK{}) ==
                              2 * size<0>(typename TiledMMA::AtomShape_MNK{}));

  // Allocate SMEM
  extern __shared__ char shared_memory[];
  using SharedStorage = SharedStorage<TypeA, TypeB, TypeSFA, TypeSFB,
                                      ASmemLayout, BSmemLayout, SFASmemLayout, SFBSmemLayout>;
  SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(shared_memory);

  // Represent the full tensors in global memory
  Tensor mA = tma_atom_A.get_tma_tensor(shape(layout_A));       // (Gemm_M,Gemm_K)
  Tensor mSFA =
    tma_atom_SFA.get_tma_tensor(shape(layout_SFA));
  Tensor mB = tma_atom_B.get_tma_tensor(shape(layout_B));       // (Gemm_N,Gemm_K)
  Tensor mSFB =
    tma_atom_SFB.get_tma_tensor(shape(layout_SFB));

  Tensor mC = make_tensor(make_gmem_ptr(ptr_C), layout_C);      // (Gemm_M,Gemm_N)
  Tensor mD = make_tensor(make_gmem_ptr(ptr_D), layout_D);      // (Gemm_M,Gemm_N)

  Layout cta_layout_mnk = make_layout(cluster_shape_mnk);
  Layout cta_layout_vmnk = tiled_divide(cta_layout_mnk, make_tile(typename TiledMMA::AtomThrID{}));    // (Mma_Ctas, ClusterShape_M/Mma_Ctas, ClusterShape_N, ClusterShape_K)
  auto cta_in_cluster_coord_vmnk = cta_layout_vmnk.get_flat_coord(int(cute::block_rank_in_cluster()));
  // SFB uses the 1-CTA scale-factor MMA instruction whose AtomThrID has size 1,
  // so its vmnk layout differs from the main 2-CTA tiled_mma.
  Layout sfb_cta_layout_vmnk = tiled_divide(cta_layout_mnk, make_tile(typename SFBTiledMMA::AtomThrID{}));
  auto sfb_cta_in_cluster_coord_vmnk = sfb_cta_layout_vmnk.get_flat_coord(int(cute::block_rank_in_cluster()));

  // Get the appropriate blocks for this MMA
  // mma coord != cta_coord_in_grid for this example
  auto mma_coord_vmnk = make_coord(
      blockIdx.x % size<0>(cta_layout_vmnk),
      blockIdx.x / size<0>(cta_layout_vmnk),
      blockIdx.y, _);
  auto mma_coord_mnk = take<1,4>(mma_coord_vmnk);

  auto sfb_mma_coord_vmnk = make_coord(
      blockIdx.x % size<0>(sfb_cta_layout_vmnk),
      blockIdx.x / size<0>(sfb_cta_layout_vmnk),
      blockIdx.y, _);
  auto sfb_mma_coord_mnk = take<1,4>(sfb_mma_coord_vmnk);

  if constexpr (Verbose) {
    if(thread0()) {
      print("mma_tiler:\t"); print(mma_tiler); print("\n");
      print("cta_layout_mnk:\t"); print(cta_layout_mnk); print("\n");
      print("cta_layout_vmnk:\t"); print(cta_layout_vmnk); print("\n");
      print("cta_in_cluster_coord_vmnk:\t"); print(cta_in_cluster_coord_vmnk); print("\n");
      print("mma_coord_vmnk:\t"); print(mma_coord_vmnk); print("\n");
      print("mma_coord_mnk:\t"); print(mma_coord_mnk); print("\n");
      print("sfb_mma_coord_vmnk:\t"); print(sfb_mma_coord_vmnk); print("\n");
      print("sfb_mma_coord_mnk:\t"); print(sfb_mma_coord_mnk); print("\n");
    } __syncthreads();
  }

  Tensor gA = local_tile(mA, mma_tiler, mma_coord_mnk, Step<_1, X,_1>{});  // (MmaTile_M,MmaTile_K,Gemm_K/MmaTile_K)
  Tensor gSFA =
    local_tile(mSFA, mma_tiler, mma_coord_mnk, Step<_1, X,_1>{});
  Tensor gB = local_tile(mB, mma_tiler, mma_coord_mnk, Step< X,_1,_1>{});  // (MmaTile_N,MmaTile_K,Gemm_K/MmaTile_K)
  Tensor gSFB =
    local_tile(mSFB, mma_tiler, sfb_mma_coord_mnk, Step< X,_1,_1>{});
  Tensor gC = local_tile(mC, mma_tiler, mma_coord_mnk, Step<_1,_1, X>{});  // (MmaTile_M,MmaTile_N)
  Tensor gD = local_tile(mD, mma_tiler, mma_coord_mnk, Step<_1,_1, X>{});  // (MmaTile_M,MmaTile_N)

  if constexpr (Verbose) {
    if (thread0()) {
      print("mA:\t"); print(mA); print("\n");
      print("mSFA:\t"); print(mSFA); print("\n");
      print("mB:\t"); print(mB); print("\n");
      print("mSFB:\t"); print(mSFB); print("\n");
      print("mC:\t"); print(mC); print("\n");
      print("mD:\t"); print(mD); print("\n");

      print("gA:\t"); print(gA); print("\n");
      print("gSFA:\t"); print(gSFA); print("\n");
      print("gB:\t"); print(gB); print("\n");
      print("gSFB:\t"); print(gSFB); print("\n");
      print("gC:\t"); print(gC); print("\n");
      print("gD:\t"); print(gD); print("\n");
    } __syncthreads();
  }

  //
  // MMA: Define C accumulators and A/B partitioning
  //

  ThrMMA cta_mma = tiled_mma.get_slice(get<0>(mma_coord_vmnk));        // Use Peer CTA coordinate
  ThrMMA sfb_cta_mma = sfb_tiled_mma.get_slice(get<0>(sfb_mma_coord_vmnk));

  // tXgY -> Y tensor from (g)mem partitioned according to MMA's X tensor block
  Tensor tCgA = cta_mma.partition_A(gA);                               // ((Mma_M/2, Mma_K),(MmaTile_M/Mma_M),(MmaTile_K/Mma_K),Gemm_K/MmaTile_K)
  Tensor tCgSFA = cta_mma.partition_A(gSFA);
  Tensor tCgB = cta_mma.partition_B(gB);                               // ((Mma_N/2, Mma_K),(MmaTile_N/Mma_N),(MmaTile_K/Mma_K),Gemm_K/MmaTile_K)
  Tensor tCgSFB = sfb_cta_mma.partition_B(gSFB);
  Tensor tCgC = cta_mma.partition_C(gC);                               // ((Mma_M/2, Mma_N),(MmaTile_M/Mma_M),(MmaTile_N/Mma_N))
  Tensor tCgD = cta_mma.partition_C(gD);                               // ((Mma_M/2, Mma_N),(MmaTile_M/Mma_M),(MmaTile_N/Mma_N))

  if constexpr (Verbose) {
    if (thread0()) {
      print("tCgA:\t"); print(tCgA); print("\n");
      print("tCgSFA:\t"); print(tCgSFA); print("\n");
      print("tCgB:\t"); print(tCgB); print("\n");
      print("tCgSFB:\t"); print(tCgSFB); print("\n");
      print("tCgC:\t"); print(tCgC); print("\n");
      print("tCgD:\t"); print(tCgD); print("\n");
    }__syncthreads();
  }
  // The SMEM tensors
  // Represent the SMEM buffers for A and B
  Tensor tCsA = shared_storage.tensor_sA();       // (MmaA, NumMma_M, NumMma_K, NumTile_K)
  Tensor tCsSFA = shared_storage.tensor_sSFA();
  Tensor tCsB = shared_storage.tensor_sB();       // (MmaB, NumMma_M, NumMma_K, NumTile_K)
  Tensor tCsSFB = shared_storage.tensor_sSFB();

  // MMA Fragment Allocation
  Tensor tCrA = cta_mma.make_fragment_A(tCsA);   // (Mma_M/2,Mma_K),(MmaTile_M/Mma_M),(MmaTile_K/Mma_K)
  Tensor tCrB = cta_mma.make_fragment_B(tCsB);   // (Mma_N/2,Mma_K),(MmaTile_N/Mma_M),(MmaTile_K/Mma_K)
  // TMEM Allocation
  Tensor tCtSFA = make_tensor<typename TiledMMA::FrgTypeSFA>(shape(SFASmemLayout{}));
  Tensor tCtSFB = make_tensor<typename SFBTiledMMA::FrgTypeSFB>(shape(SFBSmemLayout{}));
  Tensor tCtAcc = cta_mma.make_fragment_C(tCgC); // (Mma_M/2,Mma_N),(MmaTile_M/Mma_M),(MmaTile_N/Mma_N)

  tCtSFA.data() = tCtAcc.data().get() + cutlass::detail::find_tmem_tensor_col_offset(tCtAcc);
  tCtSFB.data() = tCtSFA.data().get() + cutlass::detail::find_tmem_tensor_col_offset(tCtSFA);

  if constexpr (Verbose) {
    if (thread0()) {
      print("tCsA:\t"); print(tCsA); print("\n");
      print("tCsSFA:\t"); print(tCsSFA); print("\n");
      print("tCsB:\t"); print(tCsB); print("\n");
      print("tCsSFB:\t"); print(tCsSFB); print("\n");
      print("tCrA:\t"); print(tCrA); print("\n");
      print("tCrB:\t"); print(tCrB); print("\n");
      print("tCtAcc:\t"); print(tCtAcc); print("\n");
      print("tCtSFA:\t"); print(tCtSFA); print("\n");
      print("tCtSFB:\t"); print(tCtSFB); print("\n");

      auto num_acc_cols = cutlass::detail::find_tmem_tensor_col_offset(tCtAcc);
      auto num_sfa_cols = cutlass::detail::find_tmem_tensor_col_offset(tCtSFA);
      auto num_sfb_cols = cutlass::detail::find_tmem_tensor_col_offset(tCtSFB);
      printf("Number of TMEM cols, Acc: %d, SFA: %d, SFB: %d\n",
             num_acc_cols, num_sfa_cols, num_sfb_cols);
    } __syncthreads();
  }

  //
  // TMA Setup
  //
  // Project the cta_layout for tma_a along the n-modes
  auto [tAgA, tAsA] = tma_partition(tma_atom_A,
                                    get<2>(cta_in_cluster_coord_vmnk), make_layout(size<2>(cta_layout_vmnk)),
                                    group_modes<0,3>(tCsA), group_modes<0,3>(tCgA));

  auto [tAgSFA, tAsSFA] = tma_partition(
      tma_atom_SFA, get<2>(cta_in_cluster_coord_vmnk),
      make_layout(size<2>(cta_layout_vmnk)),
      group_modes<0, 3>(tCsSFA), group_modes<0, 3>(tCgSFA));

  // Project the cta_layout for tma_b along the m-modes
  auto [tBgB, tBsB] = tma_partition(tma_atom_B,
                                    get<1>(cta_in_cluster_coord_vmnk), make_layout(size<1>(cta_layout_vmnk)),
                                    group_modes<0,3>(tCsB), group_modes<0,3>(tCgB));

  auto [tBgSFB, tBsSFB] = tma_partition(
      tma_atom_SFB, get<1>(sfb_cta_in_cluster_coord_vmnk),
      make_layout(size<1>(sfb_cta_layout_vmnk)),
      group_modes<0, 3>(tCsSFB), group_modes<0, 3>(tCgSFB));

  if constexpr (Verbose) {
    if (thread0()) {
      print("tAgA:\t"); print(tAgA); print("\n");
      print("tAsA:\t"); print(tAsA); print("\n");
      print("tAgSFA:\t"); print(tAgSFA); print("\n");
      print("tAsSFA:\t"); print(tAsSFA); print("\n");
      print("tBgB:\t"); print(tBgB); print("\n");
      print("tBsB:\t"); print(tBsB); print("\n");
      print("tBgSFB:\t"); print(tBgSFB); print("\n");
      print("tBsSFB:\t"); print(tBsSFB); print("\n");
    } __syncthreads();
  }

  int32_t tma_transaction_bytes = 0;
  // The leader CTA's transaction barrier will wait for all A and B transactions for both peer CTAs.
  tma_transaction_bytes += size<0>(cta_layout_vmnk) * sizeof(cute::ArrayEngine<TypeA, size_v<decltype(filter_zeros(tAsA))>>);
  tma_transaction_bytes += size<0>(cta_layout_vmnk) * sizeof(cute::ArrayEngine<TypeB, size_v<decltype(filter_zeros(tBsB))>>);
  tma_transaction_bytes += size<0>(cta_layout_vmnk) * sizeof(cute::ArrayEngine<TypeSFA, size_v<decltype(filter_zeros(tAsSFA))>>);
  tma_transaction_bytes += size<0>(cta_layout_vmnk) * sizeof(cute::ArrayEngine<TypeSFB, size_v<decltype(filter_zeros(tBsSFB))>>);

  if constexpr (Verbose) {
    if (thread0()) {
      printf("TmaBytes: %d\n", tma_transaction_bytes);
    }
  }

  uint16_t tma_mcast_mask_a   = create_tma_multicast_mask<2>(cta_layout_vmnk, cta_in_cluster_coord_vmnk);
  uint16_t tma_mcast_mask_b   = create_tma_multicast_mask<1>(cta_layout_vmnk, cta_in_cluster_coord_vmnk);
  uint16_t tma_mcast_mask_sfa = create_tma_multicast_mask<2>(cta_layout_vmnk, cta_in_cluster_coord_vmnk);
  uint16_t tma_mcast_mask_sfb = create_tma_multicast_mask<1>(sfb_cta_layout_vmnk, sfb_cta_in_cluster_coord_vmnk);

  constexpr bool is_all_tma2cta =
      is_tma_2cta(tma_atom_A) && is_tma_2cta(tma_atom_B) &&
      is_tma_2cta(tma_atom_SFA) && is_tma_2cta(tma_atom_SFB);
  constexpr bool is_all_tma1cta =
      !is_tma_2cta(tma_atom_A) && !is_tma_2cta(tma_atom_B) &&
      !is_tma_2cta(tma_atom_SFA) && !is_tma_2cta(tma_atom_SFB);
  static_assert(is_all_tma2cta ^ is_all_tma1cta, "All TMA operations should be either 2 CTA or 1CTA.");

  // mma_instr_mask: the bitmask of CTAs in the cluster that share this MMA instruction.
  uint32_t mma_instr_mask = create_tma_multicast_mask<0,1>(cta_layout_vmnk, cta_in_cluster_coord_vmnk)
                          | create_tma_multicast_mask<0,2>(cta_layout_vmnk, cta_in_cluster_coord_vmnk);

  if constexpr (Verbose) {
    if (thread0()) {
      printf("tma_mcast_mask_a: %x\n", tma_mcast_mask_a);
      printf("tma_mcast_mask_b: %x\n", tma_mcast_mask_b);
      printf("tma_mcast_mask_sfa: %x\n", tma_mcast_mask_sfa);
      printf("tma_mcast_mask_sfb: %x\n", tma_mcast_mask_sfb);
      printf("mma_instr_mask: %x\n", mma_instr_mask);
    }
  }

  //
  // UTCCP Setup
  //
  auto append_mn_bcast_mode = [](auto smem_layout) {
    // This is a manual workaround (needed for UTCCP with VS=16,
    // but harmless for VS=32), where we manually encode the TMEM 
    // broadcast info into the SMEM layouts.
    return make_layout(
      make_layout(make_layout(get<0,0>(smem_layout), make_layout(_4{}, _0{})),
                  get<0,1>(smem_layout)),
      get<1>(smem_layout),
      get<2>(smem_layout));
  };

  auto tCsSFA_compact =
      make_tensor(tCsSFA.data(), filter_zeros(tCsSFA.layout()));
  auto tCsSFA_compact_bcast_mn =
      make_tensor(tCsSFA_compact.data(),
                  append_mn_bcast_mode(tCsSFA_compact.layout()));
  auto tCtSFA_compact =
      make_tensor(tCtSFA.data(), filter_zeros(tCtSFA.layout()));

  using AtomThrID = typename TiledMMA::AtomThrID;
  using UtccpOp = cute::conditional_t<
      (decltype(cute::size(AtomThrID{}) == Int<2>{})::value),
      SM100_UTCCP_4x32dp128bit_2cta, SM100_UTCCP_4x32dp128bit_1cta>;
  auto tiled_copy_s2t_SFA = make_utccp_copy(UtccpOp{}, tCtSFA_compact);
  auto thr_copy_s2t_SFA = tiled_copy_s2t_SFA.get_slice(0);

  auto thr_tCsSFA_compact_s2t_ = thr_copy_s2t_SFA.partition_S(tCsSFA_compact_bcast_mn);
  auto thr_tCsSFA_compact_s2t = get_utccp_smem_desc_tensor<UtccpOp>(thr_tCsSFA_compact_s2t_);
  auto thr_tCtSFA_compact_s2t = thr_copy_s2t_SFA.partition_D(tCtSFA_compact);

  auto tCsSFB_compact = make_tensor(tCsSFB.data(), filter_zeros(tCsSFB.layout()));
  auto tCsSFB_compact_bcast_mn =
      make_tensor(tCsSFB_compact.data(),
                  append_mn_bcast_mode(tCsSFB_compact.layout()));

  auto tCtSFB_compact = make_tensor(tCtSFB.data(), filter_zeros(tCtSFB.layout()));

  auto tiled_copy_s2t_SFB = make_utccp_copy(UtccpOp{}, tCtSFB_compact);
  auto thr_copy_s2t_SFB = tiled_copy_s2t_SFB.get_slice(0);
  auto thr_tCsSFB_compact_s2t_ = thr_copy_s2t_SFB.partition_S(tCsSFB_compact_bcast_mn);
  auto thr_tCsSFB_compact_s2t = get_utccp_smem_desc_tensor<UtccpOp>(thr_tCsSFB_compact_s2t_);
  auto thr_tCtSFB_compact_s2t = thr_copy_s2t_SFB.partition_D(tCtSFB_compact);

  if constexpr (Verbose) {
    if (thread0()) {
      print("tCsSFA_compact: "); print(tCsSFA_compact.layout()); print("\n");
      print("tCsSFA_compact_bcast_mn: "); print(tCsSFA_compact_bcast_mn.layout()); print("\n");
      print("tCtSFA_compact: "); print(tCtSFA_compact.layout()); print("\n");
      print("tCsSFB_compact: "); print(tCsSFB_compact.layout()); print("\n");
      print("tCsSFB_compact_bcast_mn: "); print(tCsSFB_compact_bcast_mn.layout()); print("\n");
      print("tCtSFB_compact: "); print(tCtSFB_compact.layout()); print("\n");
    }
  }

  uint32_t elect_one_thr  = cute::elect_one_sync();
  uint32_t elect_one_warp = (threadIdx.x / 32 == 0);
  uint32_t elect_one_cta = get<0>(cta_in_cluster_coord_vmnk) == 0;

  // Calculate the number of CTAs that participates in multicast operation with this CTA (for both A and B matrices)
  int32_t num_mcast_participants = size<1>(cta_layout_vmnk) + size<2>(cta_layout_vmnk) - 1;
  // Barriers in SMEM should be initialized by a single thread.

  if constexpr (Verbose) {
    if(thread0()){
      printf("Number of multicast participants: %d\n", num_mcast_participants);
    }
  }
  if (elect_one_warp && elect_one_thr) {
    // Initialize MMA barrier
    cute::initialize_barrier(shared_storage.mma_barrier, num_mcast_participants);

    // Initialize the TMA barrier
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
    // Step 2a: Load A, B, SFA, and SFB tiles
    if (elect_one_warp && elect_one_thr) { // TMA loads are executed by one thread
      if (elect_one_cta) { // Only the leader CTA will need to wait for TMA transactions
        cute::set_barrier_transaction_bytes(shared_storage.tma_barrier, tma_transaction_bytes); // Set the expected transaction bytes for the TMA loads
      }
      copy(tma_atom_A.with(shared_storage.tma_barrier,tma_mcast_mask_a), tAgA(_,k_tile), tAsA); // Load MmaTile_M x MmaTile_K A tile
      copy(tma_atom_B.with(shared_storage.tma_barrier,tma_mcast_mask_b), tBgB(_,k_tile), tBsB); // Load MmaTile_N x MmaTile_K B tile
      copy(tma_atom_SFA.with(shared_storage.tma_barrier, tma_mcast_mask_sfa),
           tAgSFA(_,k_tile),
           tAsSFA);
      copy(tma_atom_SFB.with(shared_storage.tma_barrier, tma_mcast_mask_sfb),
           tBgSFB(_,k_tile),
           tBsSFB);
    }

    // step 2b: copy SFA and SFB tiles from SMEM to TMEM
    if (elect_one_cta) {
      // everyone sync
      cute::wait_barrier(shared_storage.tma_barrier, tma_barrier_phase_bit);
      tma_barrier_phase_bit ^= 1;

      // Issue UTCCP for entire k-tile
      copy(tiled_copy_s2t_SFA, thr_tCsSFA_compact_s2t, thr_tCtSFA_compact_s2t);
      copy(tiled_copy_s2t_SFB, thr_tCsSFB_compact_s2t, thr_tCtSFB_compact_s2t);
    }

    cutlass::arch::fence_view_async_tmem_store();
    __syncthreads();

    cute::cluster_sync();

    // Step 2c: Execute the MMAs for this tile
    if (elect_one_cta) {
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
                 make_zip_tensor(tCrA(_,0,k_block), tCtSFA(_,0,k_block)),
                 make_zip_tensor(tCrB(_,0,k_block), tCtSFB(_,0,k_block)),
                 tCtAcc(_,0,0));
            gemm(tiled_mma.with(C<UMMA::BMatrixBufferReuse::Reuse>{}),
                 make_zip_tensor(tCrA(_,1,k_block), tCtSFA(_,1,k_block)),
                 make_zip_tensor(tCrB(_,0,k_block), tCtSFB(_,0,k_block)),
                 tCtAcc(_,1,0));
          } else {
            gemm(tiled_mma,
                 make_zip_tensor(tCrA(_,_,k_block), tCtSFA(_,_,k_block)),
                 make_zip_tensor(tCrB(_,_,k_block), tCtSFB(_,_,k_block)),
                 tCtAcc);
          }
          tiled_mma.accumulate_ = UMMA::ScaleOut::One;
        }

        // Ensure MMAs are completed, only then we can reuse the A and B buffers.
        // All participating CTAs should be encoded in the mask.
        // Since only the leader CTA executes MMA, it should also send arrivals for its peer CTA.
        if constexpr (is_all_tma2cta) {
          cutlass::arch::umma_arrive_multicast_2x1SM(&shared_storage.mma_barrier, mma_instr_mask);
        } else {
          cutlass::arch::umma_arrive_multicast(&shared_storage.mma_barrier, mma_instr_mask);
        }
      }
    }
    // Wait MMAs to complete to avoid overwriting the A and B buffers on all threads.
    cute::wait_barrier(shared_storage.mma_barrier, consumer_mma_barrier_phase_bit);
    consumer_mma_barrier_phase_bit ^= 1; // flip the phase
  }

  cute::cluster_sync();

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


  if constexpr (Verbose) {
    if (thread0()) {
      print("tDtAcc: "); print(tDtAcc.layout()); print("\n");
      print("tDgC: "); print(tDgC.layout()); print("\n");
      print("tDgD: "); print(tDgD.layout()); print("\n");
    }
  }

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
          int32_t SFVecSize_,
          class TypeA = cutlass::float_e2m1_t,
          class TypeSFA = cutlass::float_ue8m0_t,
          class TypeB = cutlass::float_e2m1_t,
          class TypeSFB = cutlass::float_ue8m0_t,
          bool Verbose = false>
bool test_blockscaled_gemm(ProblemShape_MNK problem_shape_mnk)
{
  static_assert(get<1>(MmaShape_MNK{}) == 128 || get<1>(MmaShape_MNK{}) == 256,
                "For simplicity, this example only supports MMA-N=128 or 256");
  static_assert(cute::is_same_v<TypeSFA, TypeSFB>,
                "TypeSFA and TypeSFB must be identical");
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
    return false;
  }

  print("MmaShape_MNK:\t"); print(MmaShape_MNK{}); print("\n");
  print("MmaTiler_MNK:\t"); print(MmaTiler_MNK{}); print("\n");
  printf("A=K-major  B=K-major\n");

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

  // A tensor (Gemm_M,Gemm_K): K-major -> row-major (stride Gemm_K,1)
  auto layout_A = make_layout(make_shape(Gemm_M, Gemm_K), make_stride(Gemm_K, Int<1>{}));
  thrust::host_vector<TypeA> host_A(size(filter_zeros(layout_A)));
  auto host_tensor_A = make_tensor(iterator_t<TypeA>{host_A.data()}, layout_A);

  initialize_tensor(host_tensor_A, make_tuple(0, 2));
  thrust::device_vector<TypeA> device_A = host_A;
  auto device_tensor_A = make_tensor(device_A.data().get(), layout_A);

  // B tensor (Gemm_N,Gemm_K): K-major -> row-major (stride Gemm_K,1)
  auto layout_B = make_layout(make_shape(Gemm_N, Gemm_K), make_stride(Gemm_K, Int<1>{}));
  thrust::host_vector<TypeB> host_B(size(filter_zeros(layout_B)));
  auto host_tensor_B = make_tensor(iterator_t<TypeB>{host_B.data()}, layout_B);

  initialize_tensor(host_tensor_B, make_tuple(0, 2));
  thrust::device_vector<TypeB> device_B = host_B;
  auto device_tensor_B = make_tensor(device_B.data().get(), layout_B);

  // Set layouts for SFA/SFB
  using Sm107BlkScaledConfig = cutlass::detail::Sm107BlockScaledConfig<SFVecSize_>;
  auto layout_SFA = tile_to_shape(typename Sm107BlkScaledConfig::SfAtom{},
                                 make_shape(Gemm_M, Gemm_K), Step<_2, _1>{});
  auto layout_SFB = tile_to_shape(typename Sm107BlkScaledConfig::SfAtom{},
                                 make_shape(Gemm_N, Gemm_K), Step<_2, _1>{});
  // Allocate SFA and SFB
  thrust::host_vector<TypeSFA> host_sfa(size(filter_zeros(layout_SFA)));
  thrust::host_vector<TypeSFB> host_sfb(size(filter_zeros(layout_SFB)));

  auto host_tensor_SFA = make_tensor(host_sfa.data(), layout_SFA);
  auto host_tensor_SFB = make_tensor(host_sfb.data(), layout_SFB);

  initialize_tensor(host_tensor_SFA, make_tuple(0, 5));
  initialize_tensor(host_tensor_SFB, make_tuple(0, 5));

  thrust::device_vector<TypeSFA> device_SFA = host_sfa;
  thrust::device_vector<TypeSFB> device_SFB = host_sfb;

  // C tensor (Gemm_M,Gemm_N)
  auto layout_C = make_layout(make_shape(Gemm_M, Gemm_N),
                                make_stride(Gemm_N, Int<1>{}));
  thrust::host_vector<TypeC>   host_C(Gemm_M * Gemm_N);
  Tensor host_tensor_C = make_tensor(host_C.data(), layout_C);

  initialize_tensor(host_tensor_C, 0);
  thrust::device_vector<TypeC> device_C = host_C;
  if constexpr (Verbose) {
    print("host_tensor_A:\t"); print(host_tensor_A); print("\n");
    print("host_tensor_B:\t"); print(host_tensor_B); print("\n");
    print("host_tensor_SFA:\t"); print(host_tensor_SFA); print("\n");
    print("host_tensor_SFB:\t"); print(host_tensor_SFB); print("\n");
    print("host_tensor_C:\t"); print(host_tensor_C); print("\n");
  }

  // D tensor MxN (Gemm_M,Gemm_N)
  auto layout_D = make_layout(make_shape (Gemm_M,   Gemm_N),
                                make_stride(Gemm_N, Int<1>{}));   // :(Gemm_N,_1)
  // Note that we don't need a host_tensor for D yet.
  thrust::device_vector<TypeD> device_D(Gemm_M * Gemm_N);

  if constexpr (Verbose) {
    print("layout_A: "); print(layout_A); print("\n");
    print("layout_SFA: "); print(layout_SFA); print("\n");
    print("layout_B: "); print(layout_B); print("\n");
    print("layout_SFB: "); print(layout_SFB); print("\n");
    print("layout_C: "); print(layout_C); print("\n");
    print("layout_D: "); print(layout_D); print("\n");
  }

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
              MMA_Traits<SM107_MMA_MXF4NVF4_2x1SM_SS<
                          TypeA, TypeB, TypeC, TypeSFA, MmaM, MmaN, SFVecSize_,
                          UMMA::Major::K, UMMA::Major::K,
                          UMMA::ScaleIn::One, UMMA::ScaleIn::One>>{},
              Layout<Shape<_1, _1, _1>>{},
              permutation_mnk);
      } else {
        return make_tiled_mma(
              MMA_Traits<SM107_MMA_MXF4NVF4_2x1SM_SS<
                          TypeA, TypeB, TypeC, TypeSFA, MmaM, MmaN, SFVecSize_,
                          UMMA::Major::K, UMMA::Major::K,
                          UMMA::ScaleIn::One, UMMA::ScaleIn::One>>{});
      }
    } else {
      return make_tiled_mma(
            MMA_Traits<SM107_MMA_MXF4NVF4_SS<
                        TypeA, TypeB, TypeC, TypeSFA, MmaM, MmaN, SFVecSize_,
                        UMMA::Major::K, UMMA::Major::K,
                        UMMA::ScaleIn::One, UMMA::ScaleIn::One>>{});
    }
  }();
  static_assert(size<2>(typename decltype(tiled_mma)::AtomShape_MNK{}) ==
                    size<2>(MmaShape_MNK{}),
                "tiled_mma atom K-mode does not match MmaK");

  using SFBTiledMMA = typename decltype(tiled_mma)::MMA_ScaleFactor;
  auto sfb_tiled_mma = cute::make_tiled_mma(SFBTiledMMA{});

  auto mma_tiler = MmaTiler_MNK{};

  if constexpr (Verbose) {
    print("tiled_mma:\t"); print(tiled_mma); print("\n");
    print("mma_tiler:\t"); print(mma_tiler); print("\n");
    print("sfb_tiled_mma:\t"); print(sfb_tiled_mma); print("\n");
  }

  auto mma_shape_A = partition_shape_A(tiled_mma, make_shape(size<0>(MmaTiler_MNK{}),
                                                             size<2>(MmaTiler_MNK{})));

  auto mma_shape_B = partition_shape_B(tiled_mma, make_shape(size<1>(MmaTiler_MNK{}),
                                                             size<2>(MmaTiler_MNK{})));

  // Print and inspect mma_shape_A, and mma_shape_B for this example.
  if constexpr (Verbose) {
    print("mma_shape_A:\t"); print(mma_shape_A); print("\n");
    print("mma_shape_B:\t"); print(mma_shape_B); print("\n");
  }

  // The Rubin FP4 MMA only supports K-major operands, so the SMEM layouts are
  // always built from the K-major swizzle atom.
  auto sA_layout = UMMA::tile_to_mma_shape(UMMA::Layout_K_SW128_Atom<TypeA>{}, mma_shape_A);
  auto sB_layout = UMMA::tile_to_mma_shape(UMMA::Layout_K_SW128_Atom<TypeB>{}, mma_shape_B);

  auto sSFA_layout = Sm107BlkScaledConfig::deduce_smem_layoutSFA(tiled_mma, mma_tiler);
  auto sSFB_layout = Sm107BlkScaledConfig::deduce_smem_layoutSFB(tiled_mma, mma_tiler);
  using SFASmemLayout = decltype(sSFA_layout);
  using SFBSmemLayout = decltype(sSFB_layout);

  if constexpr (Verbose) {
    print("Shared memory layouts:\n");
    print("sA_layout:\t"); print(sA_layout); print("\n");
    print("sB_layout:\t"); print(sB_layout); print("\n");
    print("sSFA_layout:\t"); print(sSFA_layout); print("\n");
    print("sSFB_layout:\t"); print(sSFB_layout); print("\n");
  }

  // Now we can find the SMEM allocation size
  using ASmemLayout = decltype(sA_layout);
  using BSmemLayout = decltype(sB_layout);

  constexpr int32_t smemBytes = sizeof(SharedStorage<TypeA,
                                                     TypeB,
                                                     TypeSFA,
                                                     TypeSFB,
                                                     ASmemLayout,
                                                     BSmemLayout,
                                                     SFASmemLayout,
                                                     SFBSmemLayout>);

  // TMA descriptor needs to be created on host
  using ClusterShape = Shape<Int<ClusterM>, Int<ClusterN>, Int<1>>;
  auto cluster_layout_mnk = make_layout(ClusterShape{});
  Layout cluster_layout_vmnk =
    tiled_divide(cluster_layout_mnk,
                make_tile(typename decltype(tiled_mma)::AtomThrID{}));

  auto cluster_sfb_layout_vmnk =
    tiled_divide(cluster_layout_mnk,
                 make_tile(typename decltype(sfb_tiled_mma)::AtomThrID{}));

  auto tma_load_op = []() {
    if constexpr (Is2Cta == false) {
      return SM90_TMA_LOAD_MULTICAST{};
    } else {
      return SM100_TMA_2SM_LOAD_MULTICAST{};
    }
  };

  auto tma_op_a = tma_load_op();
  auto tma_op_b = tma_load_op();
  auto tma_op_sfa = tma_load_op();
  auto tma_op_sfb = tma_load_op();

  auto device_tensorSFA = make_tensor(device_SFA.data().get(), layout_SFA);
  auto device_tensorSFB = make_tensor(device_SFB.data().get(), layout_SFB);

  cute::Copy_Atom tma_atom_A = cute::make_tma_atom_A_sm100(
        tma_op_a, device_tensor_A, sA_layout, MmaTiler_MNK{}, tiled_mma, cluster_layout_vmnk);

  Copy_Atom tma_atom_SFA = make_tma_atom_A_sm100<uint16_t>(
      tma_op_sfa, device_tensorSFA, sSFA_layout, MmaTiler_MNK{}, tiled_mma, cluster_layout_vmnk);

  cute::Copy_Atom tma_atom_B = cute::make_tma_atom_B_sm100(
        tma_op_b, device_tensor_B, sB_layout, MmaTiler_MNK{}, tiled_mma, cluster_layout_vmnk);

  Copy_Atom tma_atom_SFB = make_tma_atom_B_sm100<uint16_t>(
      tma_op_sfb, device_tensorSFB, sSFB_layout, mma_tiler, sfb_tiled_mma, cluster_sfb_layout_vmnk);

  if constexpr (Verbose) {
    print("tma_atom_A:\t"); print(tma_atom_A); print("\n");
    print("tma_atom_B:\t"); print(tma_atom_B); print("\n");
    print("tma_atom_SFA:\t"); print(tma_atom_SFA); print("\n");
    print("tma_atom_SFB:\t"); print(tma_atom_SFB); print("\n");
  }

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
                      ProblemShape_MNK,
                      ClusterShape,
                      TypeA, decltype(layout_A), ASmemLayout, decltype(tma_atom_A),
                      TypeSFA, decltype(layout_SFA), SFASmemLayout, decltype(tma_atom_SFA),
                      TypeB, decltype(layout_B), BSmemLayout, decltype(tma_atom_B),
                      TypeSFB, decltype(layout_SFB), SFBSmemLayout, decltype(tma_atom_SFB),
                      TypeC, decltype(layout_C),
                      TypeD, decltype(layout_D),
                      decltype(tiled_mma),
                      decltype(sfb_tiled_mma),
                      MmaTiler_MNK,
                      TypeAlpha, TypeBeta,
                      Verbose
                    >;

  if constexpr (Verbose) {
    printf("Grid launched: %d, %d, %d\n", dimGrid.x, dimGrid.y, dimGrid.z);
    printf("Cluster launched: %d, %d, %d\n", dimCluster.x, dimCluster.y, dimCluster.z);
    printf("Smem bytes: %d\n", smemBytes);
  }
  // Set kernel attributes (set SMEM)
  auto status_ = cudaFuncSetAttribute(
      *kernel_ptr, cudaFuncAttributeMaxDynamicSharedMemorySize, smemBytes);
  if (status_ != cudaSuccess) {
    std::cerr << "Error: Failed to set Shared Memory size." << std::endl;
    return false;
  }

  TypeAlpha alpha = 1.0f;
  TypeBeta beta = 0.0f;

  // Launch kernel with TMA parameters and cluster shape
  cudaStream_t stream = 0;
  cutlass::ClusterLaunchParams params = {dimGrid, dimBlock, dimCluster, smemBytes, stream};
  cutlass::Status status = cutlass::launch_kernel_on_cluster(params, (void const*) kernel_ptr,
      problem_shape_mnk,
      shape(cluster_layout_mnk),
      device_A.data().get(), layout_A, tma_atom_A,
      device_SFA.data().get(), layout_SFA, tma_atom_SFA,
      device_B.data().get(), layout_B, tma_atom_B,
      device_SFB.data().get(), layout_SFB, tma_atom_SFB,
      device_C.data().get(), layout_C,
      device_D.data().get(), layout_D,
      tiled_mma,
      sfb_tiled_mma,
      MmaTiler_MNK{},
      alpha, beta);

  CUTE_CHECK_LAST();

  if (status != cutlass::Status::kSuccess) {
    std::cerr << "Error: Failed at kernel Launch" << std::endl;
    return false;
  }
  if constexpr (Verbose) {
    std::cout << "Kernel launched and finished successfully\n";
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

  // Gett expects rank-3 (M, K, L) and (M, N, L) tensors. Our GEMM is non-batched
  // (L=1), so we extend each rank-2 layout with a zero-stride batch dimension.
  auto to_rank3 = [](auto tensor) {
    return make_tensor(tensor.data(),
      make_layout(append(shape(tensor.layout()),  _1{}),
                  append(stride(tensor.layout()), _0{})));
  };
  auto t_A   = to_rank3(host_tensor_A);
  auto t_B   = to_rank3(host_tensor_B);
  auto t_C   = to_rank3(host_tensor_C);
  auto t_SFA = to_rank3(host_tensor_SFA);
  auto t_SFB = to_rank3(host_tensor_SFB);

  // Reference output tensor (device does not yet produce SFD, use null placeholder).
  thrust::host_vector<TypeD> host_reference_D(Gemm_M * Gemm_N, TypeD(0));
  auto host_reference_tensor_D = make_tensor(host_reference_D.data(), layout_D);
  auto t_D = to_rank3(host_reference_tensor_D);

  auto t_SFD = make_tensor(static_cast<TypeSFA *>(nullptr),
                           make_layout(make_shape(_1{}, _1{}, _1{}))); // Not used.

  cutlass::reference::host::GettBlockScalingMainloopParams<
      TypeAccumulator, decltype(t_A), decltype(t_SFA), decltype(t_B), decltype(t_SFB)>
      mainloop_params{t_A, t_SFA, t_B, t_SFB};

  cutlass::reference::host::GettBlockScalingEpilogueParams<
      TypeAlpha, TypeAccumulator, TypeC, decltype(t_C), decltype(t_D), decltype(t_SFD)>
      epilogue_params{alpha, beta, t_C, t_D, t_SFD};
  cutlass::reference::host::Gemm3x(mainloop_params, epilogue_params);

  ////////////////////////////////////////////////////////////
  //
  // Compare results
  //
  ////////////////////////////////////////////////////////////
  Tensor D_computed_cute = make_tensor(host_D.data(), layout_D);
  Tensor D_expected_cute = make_tensor(host_reference_D.data(), layout_D);
  auto relative_error = print_matrix_multiply_mollified_relative_error(
      type_str_a, host_tensor_A, type_str_b, host_tensor_B, type_str_d,
      D_computed_cute, D_expected_cute);
  bool success = relative_error <= 0.0;
  std::cout << "Execution is " << ((success) ? "successful." : "failed.")
            << std::endl;

  // Print first 10 mismatches with (row, col), reference, and computed values.
  // Also compute the fraction of incorrect results.
  if (!success) {
    int mismatch_count = 0;
    int total_incorrect = 0;
    int total_elements = Gemm_M * Gemm_N;
    std::cout << "First up to 10 mismatches (row, col): ref vs got" << std::endl;
    for (int m = 0; m < Gemm_M; ++m) {
      for (int n = 0; n < Gemm_N; ++n) {
        TypeD got = D_computed_cute(m, n);
        TypeD ref = D_expected_cute(m, n);
        if (got != ref) {
          if (mismatch_count < 10) {
            std::cout << "  (" << m << ", " << n << "): ref=" << ref
                      << " got=" << got << std::endl;
            ++mismatch_count;
          }
          ++total_incorrect;
        }
      }
    }
    std::cout << "Incorrect: " << total_incorrect << " / " << total_elements
              << " = " << (100.0 * total_incorrect / total_elements) << "%" << std::endl;
  }
  return success;
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

  int32_t Gemm_N = 512;
  if (argc >= 3)
    sscanf(argv[2], "%d", &Gemm_N);

  int32_t Gemm_K = 512;
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

  // if true, debug information will be printed (for host and device) to stdout
  constexpr bool verbose = false;

  constexpr int32_t clusterM = 2;
  constexpr int32_t clusterN = 2;

  bool all_passed = true;

  cute::for_each(cute::make_tuple(cute::Int<16>{}, cute::Int<32>{}),
                 [&](auto sfvec_ic) {
  constexpr int32_t SFVecSize = decltype(sfvec_ic)::value;

  // MMA instruction: 128x128x128
  // MMA tiler:       128x128x256
  // 1CTA without b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_128, _128, _128>,
                          Shape<_128, _128, _256>,
                          false, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          verbose>(problem_shape);

  // MMA instruction: 128x256x128
  // MMA tiler:       128x256x256
  // 1CTA without b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_128, _256, _128>,
                          Shape<_128, _256, _256>,
                          false, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          verbose>(problem_shape);

  // MMA instruction: 128x128x128
  // MMA tiler:       256x128x256
  // 1CTA with b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_128, _128, _128>,
                          Shape<_256, _128, _256>,
                          false, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          verbose>(problem_shape);

  // MMA instruction: 128x256x128
  // MMA tiler:       256x256x256
  // 1CTA with b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_128, _256, _128>,
                          Shape<_256, _256, _256>,
                          false, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          verbose>(problem_shape);

  // MMA instruction: 256x128x128
  // MMA tiler:       256x128x256
  // 2CTA without b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_256, _128, _128>,
                          Shape<_256, _128, _256>,
                          true, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          verbose>(problem_shape);

  // MMA instruction: 256x128x128
  // MMA tiler:       512x128x256
  // 2CTA with b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_256, _128, _128>,
                          Shape<_512, _128, _256>,
                          true, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          verbose>(problem_shape);

  // MMA instruction: 256x256x128
  // MMA tiler:       256x256x256
  // 2CTA without b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_256, _256, _128>,
                          Shape<_256, _256, _256>,
                          true, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          verbose>(problem_shape);

  // MMA instruction: 256x256x128
  // MMA tiler:       512x256x256
  // 2CTA with b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_256, _256, _128>,
                          Shape<_512, _256, _256>,
                          true, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          cutlass::float_e2m1_t, cutlass::float_ue8m0_t,
                          verbose>(problem_shape);
  });

  {
  constexpr int32_t SFVecSize = 32;

  // MMA instruction: 128x128x128
  // MMA tiler:       128x128x256
  // 1CTA without b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_128, _128, _128>,
                          Shape<_128, _128, _256>,
                          false, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          verbose>(problem_shape);

  // MMA instruction: 128x256x128
  // MMA tiler:       128x256x256
  // 1CTA without b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_128, _256, _128>,
                          Shape<_128, _256, _256>,
                          false, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          verbose>(problem_shape);

  // MMA instruction: 128x128x128
  // MMA tiler:       256x128x256
  // 1CTA with b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_128, _128, _128>,
                          Shape<_256, _128, _256>,
                          false, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          verbose>(problem_shape);

  // MMA instruction: 128x256x128
  // MMA tiler:       256x256x256
  // 1CTA with b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_128, _256, _128>,
                          Shape<_256, _256, _256>,
                          false, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          verbose>(problem_shape);

  // MMA instruction: 256x128x128
  // MMA tiler:       256x128x256
  // 2CTA without b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_256, _128, _128>,
                          Shape<_256, _128, _256>,
                          true, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          verbose>(problem_shape);

  // MMA instruction: 256x128x128
  // MMA tiler:       512x128x256
  // 2CTA with b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_256, _128, _128>,
                          Shape<_512, _128, _256>,
                          true, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          verbose>(problem_shape);

  // MMA instruction: 256x256x128
  // MMA tiler:       256x256x256
  // 2CTA without b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_256, _256, _128>,
                          Shape<_256, _256, _256>,
                          true, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          verbose>(problem_shape);

  // MMA instruction: 256x256x128
  // MMA tiler:       512x256x256
  // 2CTA with b-reuse
  all_passed &=
    test_blockscaled_gemm<Shape<_256, _256, _128>,
                          Shape<_512, _256, _256>,
                          true, clusterM, clusterN,
                          decltype(problem_shape),
                          SFVecSize,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          cutlass::float_e2m1_t, cutlass::float_ue5m3_t,
                          verbose>(problem_shape);
  }

  std::cout << "Overall: " << (all_passed ? "PASSED" : "FAILED") << std::endl;
  return all_passed ? 0 : 1;

#else
  std::cout << "CUTLASS_ARCH_MMA_SM107_SUPPORTED must be enabled, but it is "
               "not. This example requires SM107 (Rubin) architecture."
            << std::endl;
  return 1;
#endif
}
