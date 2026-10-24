/***************************************************************************************************
 * Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 **************************************************************************************************/

///////////////////////////////////////////////////////////////////////////////////////////////////
//
//  CuTe Tutorial for SM100 Programming -- Warp-specialized block-scaled MXFP8 (2SM + Multicast TMA)
//
// Compared to 04_mma_tma_2sm_sm100_mxfp8.cu this variant introduces warp specialization:
//   - Warp 0      : TMA warp           -- issues 2SM multicast TMA loads of A/B and cooperative
//                                         copy of SFA/SFB into a multi-stage ring buffer in SMEM.
//   - Warp 1      : MMA warp           -- runs the UTCCP (SFs) and UMMA (A*B) on each stage.
//   - Warps 2..3  : Epilogue warps     -- after the whole K-loop completes, perform
//                                         TMEM -> RMEM -> SMEM -> GMEM (TMA STORE).
//
// Multi-stage TMA->UMMA pipeline (NumStages=2) is implemented with raw mbarriers:
//   - tma_full_bar[NumStages]  : producer=TMA warp (via TMA transaction bytes), consumer=MMA warp.
//   - mma_empty_bar[NumStages] : producer=MMA warp (umma_arrive_multicast_2x1SM), consumer=TMA warp.
//   - acc_bar                  : producer=MMA warp (one-shot after the last k-tile),
//                                consumer=epilogue warps.
//
// Epilogue is intentionally simple and single-pathed (no double-buffering):
//   acc(TMEM) -> register fragment -> sD (SMEM) -> cute::copy(SM90_TMA_STORE, sD, gD).
// D == alpha * (A*B blockscaled). C / beta are omitted for clarity.
//
///////////////////////////////////////////////////////////////////////////////////////////////////

#include <iostream>
#include <cstdio>

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cutlass/half.h>
#include <cutlass/float8.h>
#include <cutlass/util/print_error.hpp>
#include <cutlass/arch/barrier.h>
#include <cutlass/cluster_launch.hpp>
#include <cutlass/detail/sm100_blockscaled_layout.hpp>
#include <cutlass/detail/sm100_tmem_helper.hpp>

#include <cute/tensor.hpp>
#include <cute/arch/cluster_sm90.hpp>
#include <cute/numeric/integral_constant.hpp>
#include <cute/algorithm/cooperative_copy.hpp>
#include <cute/arch/tmem_allocator_sm100.hpp>
#include <cute/atom/copy_traits_sm100.hpp>

#include "example_utils.hpp"

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

// Number of stages in the A/B/SFA/SFB mainloop ring buffer.
static constexpr int NumStages = 4;

// Warp-role partitioning within a 128-thread CTA.
static constexpr int TmaWarpIdx  = 0;
static constexpr int MmaWarpIdx  = 1;
static constexpr int EpiWarpIdx0 = 2; // warps 2 and 3 form the epilogue warp group (64 threads).

// Shared storage uses a flat NumStages * cosize allocation per mainloop buffer
// (A/B/SFA/SFB); per-stage tensors are constructed in device code by pointer
// offset. This avoids building a staged CuTe layout for the scale factors
// (whose base layout is not always trivially extensible with an outer stage mode).
template <class TypeA, class TypeB, class TypeSF, class TypeD,
          class ASmemLayout, class BSmemLayout,
          class SFASmemLayout, class SFBSmemLayout, class DSmemLayout>
struct SharedStorage
{
  static constexpr int ACosize   = cute::cosize_v<ASmemLayout>;
  static constexpr int BCosize   = cute::cosize_v<BSmemLayout>;
  static constexpr int SFACosize = cute::cosize_v<SFASmemLayout>;
  static constexpr int SFBCosize = cute::cosize_v<SFBSmemLayout>;

  alignas(128) cute::ArrayEngine<TypeA,  ACosize   * NumStages> A;
  alignas(128) cute::ArrayEngine<TypeB,  BCosize   * NumStages> B;
  alignas(128) cute::ArrayEngine<TypeSF, SFACosize * NumStages> SFA;
  alignas(128) cute::ArrayEngine<TypeSF, SFBCosize * NumStages> SFB;

  // Single-buffered epilogue SMEM (no double-buffer on purpose).
  alignas(128) cute::ArrayEngine<TypeD,  cute::cosize_v<DSmemLayout>> D;

  // Per-stage mainloop barriers.
  alignas(16) cute::uint64_t tma_full_bar [NumStages];
  alignas(16) cute::uint64_t mma_empty_bar[NumStages];

  // One-shot accumulator handoff barrier (MMA -> epilogue).
  alignas(16) cute::uint64_t acc_bar;

  alignas(16) cute::uint32_t tmem_base_ptr;

  CUTE_DEVICE constexpr auto tensor_sA  (int s) { return make_tensor(make_smem_ptr(A.begin()   + s * ACosize),   ASmemLayout{});   }
  CUTE_DEVICE constexpr auto tensor_sB  (int s) { return make_tensor(make_smem_ptr(B.begin()   + s * BCosize),   BSmemLayout{});   }
  CUTE_DEVICE constexpr auto tensor_sSFA(int s) { return make_tensor(make_smem_ptr(SFA.begin() + s * SFACosize), SFASmemLayout{}); }
  CUTE_DEVICE constexpr auto tensor_sSFB(int s) { return make_tensor(make_smem_ptr(SFB.begin() + s * SFBCosize), SFBSmemLayout{}); }
  CUTE_DEVICE constexpr auto tensor_sD  ()      { return make_tensor(make_smem_ptr(D.begin()),                   DSmemLayout{});   }
};

template <class SharedStorage,
          class ATensor, class BTensor, class DTensor,
          class SFATensor, class SFBTensor,
          class MmaTiler_MNK, class EpiTiler_MN, class TiledMMA, class ClusterShape_MNK,
          class TmaAtomA, class TmaAtomB, class TmaAtomD,
          class Alpha>
__global__ static
void
gemm_device(ATensor   mA, BTensor   mB, DTensor   mD,
            SFATensor mSFA, SFBTensor mSFB,
            MmaTiler_MNK mma_tiler, EpiTiler_MN epi_tiler_mn,
            TiledMMA tiled_mma, ClusterShape_MNK cluster_shape,
            CUTE_GRID_CONSTANT TmaAtomA const tma_atom_A,
            CUTE_GRID_CONSTANT TmaAtomB const tma_atom_B,
            CUTE_GRID_CONSTANT TmaAtomD const tma_atom_D,
            Alpha alpha)
{
  // ---- Cluster / CTA coordinates -------------------------------------------
  Layout cluster_layout_vmnk = tiled_divide(make_layout(cluster_shape),
                                            make_tile(typename TiledMMA::AtomThrID{}));

  auto mma_coord_vmnk = make_coord(blockIdx.x % size<0>(cluster_layout_vmnk),
                                   blockIdx.x / size<0>(cluster_layout_vmnk),
                                   blockIdx.y,
                                   _);
  auto mma_coord = select<1,2,3>(mma_coord_vmnk);

  Tensor gA = local_tile(mA, mma_tiler, mma_coord, Step<_1, X,_1>{});
  Tensor gB = local_tile(mB, mma_tiler, mma_coord, Step< X,_1,_1>{});
  Tensor gD = local_tile(mD, mma_tiler, mma_coord, Step<_1,_1, X>{});

  // SFA is split along M for 2SM (per-CTA half-M). SFB is replicated per peer CTA.
  auto mma_v = get<0>(mma_coord_vmnk);
  constexpr auto v_size = size<0>(decltype(cluster_layout_vmnk){});
  auto mma_tiler_sfa = make_shape(get<0>(mma_tiler) / Int<v_size>{},
                                  get<1>(mma_tiler),
                                  get<2>(mma_tiler));
  auto mma_coord_sfa = make_coord(get<1>(mma_coord_vmnk) * Int<v_size>{} + mma_v,
                                  get<2>(mma_coord_vmnk),
                                  _);
  Tensor gSFA = local_tile(mSFA, mma_tiler_sfa, mma_coord_sfa, Step<_1, X,_1>{});
  Tensor gSFB = local_tile(mSFB, mma_tiler,     mma_coord,     Step< X,_1,_1>{});

  // ---- SMEM tensors --------------------------------------------------------
  extern __shared__ char shared_memory[];
  SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(shared_memory);

  // Per-stage tensors are obtained via shared_storage.tensor_sA(stage), etc.

  // ---- MMA partitioning (accumulator in TMEM) ------------------------------
  ThrMMA cta_mma = tiled_mma.get_slice(mma_v);
  Tensor tCgA = cta_mma.partition_A(gA);
  Tensor tCgB = cta_mma.partition_B(gB);
  Tensor tCgD = cta_mma.partition_C(gD);

  Tensor tCtAcc = cta_mma.make_fragment_C(tCgD);

  uint32_t elect_one_thr  = cute::elect_one_sync();
  int warp_idx = int(threadIdx.x / 32);
  bool is_warp0 = (warp_idx == 0);
  bool is_tma_warp = (warp_idx == TmaWarpIdx);
  bool is_mma_warp = (warp_idx == MmaWarpIdx);

  // ---- TMEM allocation (warp 0 elects) -------------------------------------
  using TmemAllocator = cute::TMEM::Allocator2Sm;
  TmemAllocator tmem_allocator{};
  if (is_warp0) {
    tmem_allocator.allocate(TmemAllocator::Sm100TmemCapacityColumns, &shared_storage.tmem_base_ptr);
  }
  __syncthreads();
  uint32_t tmem_base_addr = shared_storage.tmem_base_ptr;
  tCtAcc.data() = tmem_base_addr;

  // SFA/SFB TMEM fragments (per-stage shape from a stage-0 probe of sSFA/sSFB).
  auto sSFA_probe = shared_storage.tensor_sSFA(0);
  auto sSFB_probe = shared_storage.tensor_sSFB(0);
  Tensor tCtSFA_probe = make_tensor<typename TiledMMA::FrgTypeSFA>(shape(sSFA_probe));
  Tensor tCtSFB_probe = make_tensor<typename TiledMMA::FrgTypeSFB>(shape(sSFB_probe));
  tCtSFA_probe.data() = tCtAcc.data().get() + cutlass::detail::find_tmem_tensor_col_offset(tCtAcc);
  tCtSFB_probe.data() = tCtSFA_probe.data().get() + cutlass::detail::find_tmem_tensor_col_offset(tCtSFA_probe);
  uint32_t tmem_sfa_addr = tCtSFA_probe.data().get();
  uint32_t tmem_sfb_addr = tCtSFB_probe.data().get();

  // ---- Cluster coord / multicast masks -------------------------------------
  auto cta_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(int(cute::block_rank_in_cluster()));
  auto elect_one_cta = get<0>(cta_in_cluster_coord_vmnk) == Int<0>{};

  uint16_t tma_mcast_mask_a = create_tma_multicast_mask<2>(cluster_layout_vmnk, cta_in_cluster_coord_vmnk);
  uint16_t tma_mcast_mask_b = create_tma_multicast_mask<1>(cluster_layout_vmnk, cta_in_cluster_coord_vmnk);
  uint16_t mma_mcast_mask_c = create_tma_multicast_mask<0,1>(cluster_layout_vmnk, cta_in_cluster_coord_vmnk) |
                              create_tma_multicast_mask<0,2>(cluster_layout_vmnk, cta_in_cluster_coord_vmnk);

  // Per-iteration TMA transaction byte count (constant across stages).
  // 2SM multicast: the leader CTA's mbarrier accumulates transactions for
  // both CTAs in the pair, which is the leading size<0>() factor. Query the
  // partitioned slice size from stage-0 SMEM tensors via tma_partition.
  auto sA0 = shared_storage.tensor_sA(0);
  auto sB0 = shared_storage.tensor_sB(0);
  auto tAsA0 = get<1>(tma_partition(tma_atom_A,
      get<2>(cta_in_cluster_coord_vmnk),
      make_layout(size<2>(cluster_layout_vmnk)),
      group_modes<0,3>(sA0), group_modes<0,3>(tCgA)));
  auto tBsB0 = get<1>(tma_partition(tma_atom_B,
      get<1>(cta_in_cluster_coord_vmnk),
      make_layout(size<1>(cluster_layout_vmnk)),
      group_modes<0,3>(sB0), group_modes<0,3>(tCgB)));
  int tma_transaction_bytes = int(size<0>(cluster_layout_vmnk)) *
      ( int(sizeof(make_tensor_like(tAsA0)))
      + int(sizeof(make_tensor_like(tBsB0))) );

  // ---- Barrier initialization (warp 0 thread 0 only) -----------------------
  int num_mcast_participants = size<1>(cluster_layout_vmnk) + size<2>(cluster_layout_vmnk) - 1;
  if (is_warp0 && elect_one_thr) {
    CUTLASS_PRAGMA_UNROLL
    for (int s = 0; s < NumStages; ++s) {
      // TMA arrives once per stage (leader CTA's single TMA thread).
      cute::initialize_barrier(shared_storage.tma_full_bar [s], /* arrive count */ 1);
      // MMA releases: each of the multicast participant CTAs signals empty via
      // umma_arrive_multicast_2x1SM (leader-CTA's UMMA scribbles onto all peers).
      cute::initialize_barrier(shared_storage.mma_empty_bar[s], num_mcast_participants);
    }
    // Accumulator handoff, signaled once at end of mainloop.
    cute::initialize_barrier(shared_storage.acc_bar, num_mcast_participants);
  }
  cute::cluster_sync();

  int num_k_tiles = int(size<3>(tCgA));

  ///////////////////////////////////////////////////////////////////////////
  // Step 2 : Mainloop -- warp-specialized producer/consumer
  ///////////////////////////////////////////////////////////////////////////

  if (is_tma_warp) {
    // ---- TMA warp -----------------------------------------------------------
    // Producer side of the (tma_full_bar, mma_empty_bar) pipeline.
    // producer_phase starts at 0 and flips each time it reuses a given stage.
    int producer_phase = 0;

    // Precompute TMA partitions once per stage (loop-invariant across k_tile):
    //   - tAgA / tBgB depend only on the cluster tile view and multicast
    //     coord, which are stage-independent -> a single copy suffices.
    //   - tAsA / tBsB only change base SMEM pointer across stages -> keep one
    //     per stage, indexed by `stage` in the loop.
    auto [tAgA, tAsA_s0] = tma_partition(tma_atom_A,
        get<2>(cta_in_cluster_coord_vmnk),
        make_layout(size<2>(cluster_layout_vmnk)),
        group_modes<0,3>(shared_storage.tensor_sA(0)), group_modes<0,3>(tCgA));
    auto [tBgB, tBsB_s0] = tma_partition(tma_atom_B,
        get<1>(cta_in_cluster_coord_vmnk),
        make_layout(size<1>(cluster_layout_vmnk)),
        group_modes<0,3>(shared_storage.tensor_sB(0)), group_modes<0,3>(tCgB));

    cute::array<decltype(tAsA_s0), NumStages> tAsA_all{};
    cute::array<decltype(tBsB_s0), NumStages> tBsB_all{};
    tAsA_all[0] = tAsA_s0;
    tBsB_all[0] = tBsB_s0;
    CUTLASS_PRAGMA_UNROLL
    for (int s = 1; s < NumStages; ++s) {
      tAsA_all[s] = get<1>(tma_partition(tma_atom_A,
          get<2>(cta_in_cluster_coord_vmnk),
          make_layout(size<2>(cluster_layout_vmnk)),
          group_modes<0,3>(shared_storage.tensor_sA(s)), group_modes<0,3>(tCgA)));
      tBsB_all[s] = get<1>(tma_partition(tma_atom_B,
          get<1>(cta_in_cluster_coord_vmnk),
          make_layout(size<1>(cluster_layout_vmnk)),
          group_modes<0,3>(shared_storage.tensor_sB(s)), group_modes<0,3>(tCgB)));
    }

    for (int k_tile = 0; k_tile < num_k_tiles; ++k_tile) {
      int stage = k_tile % NumStages;

      // Wait for MMA warp to release this stage's slot (skip on first use).
      if (k_tile >= NumStages) {
        cute::wait_barrier(shared_storage.mma_empty_bar[stage], producer_phase);
        if (stage == NumStages - 1) producer_phase ^= 1;
      }

      // Single thread issues the 2SM multicast TMA loads for this stage.
      if (elect_one_thr) {
        if (elect_one_cta) {
          cute::set_barrier_transaction_bytes(shared_storage.tma_full_bar[stage], tma_transaction_bytes);
        }
        copy(tma_atom_A.with(shared_storage.tma_full_bar[stage], tma_mcast_mask_a), tAgA(_,k_tile), tAsA_all[stage]);
        copy(tma_atom_B.with(shared_storage.tma_full_bar[stage], tma_mcast_mask_b), tBgB(_,k_tile), tBsB_all[stage]);
      }
    }
  }
  else if (is_mma_warp) {
    // ---- MMA warp -----------------------------------------------------------
    // Consumer of tma_full_bar, producer of mma_empty_bar (via 2x1SM arrive).
    tiled_mma.accumulate_ = UMMA::ScaleOut::Zero;
    int consumer_phase = 0;
    // MMA warp is also a "consumer" of mma_empty_bar: it must wait before
    // overwriting a stage's SF SMEM while the previous iteration's UTCCP may
    // still be reading it on the leader CTA. This mirrors the TMA warp's
    // phase-bit tracking of the same barrier.
    int reuse_phase = 0;

    for (int k_tile = 0; k_tile < num_k_tiles; ++k_tile) {
      int stage = k_tile % NumStages;

      // Wait for the previous use of this stage's SF SMEM to complete (skip
      // the first NumStages iterations since nothing has used those slots yet).
      if (k_tile >= NumStages) {
        cute::wait_barrier(shared_storage.mma_empty_bar[stage], reuse_phase);
        if (stage == NumStages - 1) reuse_phase ^= 1;
      }

      // Cooperative copy of scale factors GMEM -> SMEM using MMA warp's 32
      // threads. All CTAs (leader + peer) load SFs into their own SMEM: the
      // 2SM UTCCP issued by the leader accesses both CTAs' SMEM to fill TMEM.
      int lane = int(threadIdx.x) & 31;
      Tensor sSFA_stage = shared_storage.tensor_sSFA(stage);
      Tensor sSFB_stage = shared_storage.tensor_sSFB(stage);
      cooperative_copy<32>(lane, gSFA(_,_,k_tile), sSFA_stage);
      cooperative_copy<32>(lane, gSFB(_,_,k_tile), sSFB_stage);
      cutlass::arch::fence_view_async_shared();

      // Only the leader CTA tracks the TMA completion barrier (2SM TMA
      // transaction bytes only land on the leader's mbarrier) and issues
      // UTCCP + UMMA. Peer CTA's MMA warp simply owns the cooperative_copy
      // above and then proceeds to the next iteration.
      if (elect_one_cta) {
        cute::wait_barrier(shared_storage.tma_full_bar[stage], consumer_phase);
        if (stage == NumStages - 1) consumer_phase ^= 1;

        // Per-stage SMEM views.
        auto sSFA_s = shared_storage.tensor_sSFA(stage);
        auto sSFB_s = shared_storage.tensor_sSFB(stage);

        // Per-stage UTCCP partitioning (the atom is cheap; no host precompute needed).
        Tensor tCtSFA = make_tensor<typename TiledMMA::FrgTypeSFA>(shape(sSFA_s));
        Tensor tCtSFB = make_tensor<typename TiledMMA::FrgTypeSFB>(shape(sSFB_s));
        tCtSFA.data() = tmem_sfa_addr;
        tCtSFB.data() = tmem_sfb_addr;

        auto sSFA_compact = make_tensor(sSFA_s.data(), filter_zeros(sSFA_s.layout()));
        auto sSFB_compact = make_tensor(sSFB_s.data(), filter_zeros(sSFB_s.layout()));
        auto tSFA_compact = make_tensor(tCtSFA.data(), filter_zeros(tCtSFA.layout()));
        auto tSFB_compact = make_tensor(tCtSFB.data(), filter_zeros(tCtSFB.layout()));

        using UtccpOp = SM100_UTCCP_4x32dp128bit_2cta;
        auto tiled_copy_s2t_SFA = make_utccp_copy(UtccpOp{}, tSFA_compact);
        auto tiled_copy_s2t_SFB = make_utccp_copy(UtccpOp{}, tSFB_compact);
        auto thr_s2t_SFA = tiled_copy_s2t_SFA.get_slice(0);
        auto thr_s2t_SFB = tiled_copy_s2t_SFB.get_slice(0);

        auto sfa_src_ = thr_s2t_SFA.partition_S(sSFA_compact);
        auto sfa_src  = get_utccp_smem_desc_tensor<UtccpOp>(sfa_src_);
        auto sfa_dst  = thr_s2t_SFA.partition_D(tSFA_compact);
        auto sfb_src_ = thr_s2t_SFB.partition_S(sSFB_compact);
        auto sfb_src  = get_utccp_smem_desc_tensor<UtccpOp>(sfb_src_);
        auto sfb_dst  = thr_s2t_SFB.partition_D(tSFB_compact);

        copy(tiled_copy_s2t_SFA, sfa_src, sfa_dst);
        copy(tiled_copy_s2t_SFB, sfb_src, sfb_dst);

        // Build per-stage A/B descriptor fragments and issue UMMA.
        Tensor sA_s = shared_storage.tensor_sA(stage);
        Tensor sB_s = shared_storage.tensor_sB(stage);
        Tensor tCrA = cta_mma.make_fragment_A(sA_s);
        Tensor tCrB = cta_mma.make_fragment_B(sB_s);

        CUTE_UNROLL
        for (int k_block = 0; k_block < size<2>(tCrA); ++k_block) {
          gemm(tiled_mma.with(tiled_mma.accumulate_,
                              tCtSFA(_,_,k_block),
                              tCtSFB(_,_,k_block)),
               tCrA(_,_,k_block),
               tCrB(_,_,k_block),
               tCtAcc);
          tiled_mma.accumulate_ = UMMA::ScaleOut::One;
        }

        // Signal this stage's empty barrier to all multicast participants.
        cutlass::arch::umma_arrive_multicast_2x1SM(&shared_storage.mma_empty_bar[stage], mma_mcast_mask_c);
      }
    }

    // After the whole K-loop, signal the accumulator barrier once. All
    // multicast participants (including peer CTAs) will see this and their
    // epilogue warps can proceed.
    if (elect_one_cta) {
      cutlass::arch::umma_arrive_multicast_2x1SM(&shared_storage.acc_bar, mma_mcast_mask_c);
    }
  }

  // ---- Epilogue (all 128 threads participate) -----------------------------
  // TMEM -> RMEM with SM100_TMEM_LOAD_32dp32b1x requires a full 32x4=128
  // thread layout; the warp-specialization above is only for the mainloop.
  // All warps converge here and together drain the accumulator.
  cute::wait_barrier(shared_storage.acc_bar, 0);
  auto epi_tiler_v = make_tile(epi_tiler_mn);
  Tensor tAcc_epi = zipped_divide(tCtAcc, epi_tiler_v);  // (EpiTile, NumTiles)
  Tensor gD_epi   = zipped_divide(tCgD,   epi_tiler_v);  // (EpiTile, NumTiles)
  Tensor sD_epi   = shared_storage.tensor_sD();          // (EpiTile)

  // TMA STORE partitioning (SMEM -> GMEM).
  auto [tSG_gD, tSG_sD] = tma_partition(tma_atom_D, sD_epi, gD_epi);

  // TMEM -> RMEM tiled copy (staged per epilogue subtile).
  TiledCopy t2r_copy = make_tmem_copy(SM100_TMEM_LOAD_32dp32b1x{}, tAcc_epi(_, _0{}));
  ThrCopy   thr_t2r  = t2r_copy.get_slice(int(threadIdx.x));
  Tensor tTR_tAcc = thr_t2r.partition_S(tAcc_epi);  // (T2R, NumT2R, NumTiles)
  Tensor tTR_sD   = thr_t2r.partition_D(sD_epi);    // (T2R, NumT2R)
  Tensor tTR_rD   = make_fragment_like(tTR_sD);

  int num_epi_tiles = int(size<2>(tTR_tAcc));
  CUTE_NO_UNROLL
  for (int epi = 0; epi < num_epi_tiles; ++epi) {
    // TMEM -> RMEM for this subtile.
    copy(t2r_copy, tTR_tAcc(_,_,epi), tTR_rD);

    // Apply alpha (C/beta intentionally omitted for simplicity).
    CUTE_UNROLL
    for (int i = 0; i < size(tTR_rD); ++i) {
      tTR_rD(i) = float(alpha) * tTR_rD(i);
    }

    // RMEM -> SMEM, then TMA STORE SMEM -> GMEM.
    copy_aligned(tTR_rD, tTR_sD);
    tma_store_fence();
    __syncthreads();
    if (threadIdx.x == 0) {
      copy(tma_atom_D, tSG_sD, tSG_gD(_, epi));
      tma_store_arrive();
      tma_store_wait<0>();
    }
    __syncthreads();
  }

  __syncthreads();

  // Release TMEM (warp 0 only).
  if (is_warp0) {
    tmem_allocator.release_allocation_lock();
    tmem_allocator.free(shared_storage.tmem_base_ptr, TmemAllocator::Sm100TmemCapacityColumns);
  }
}

template <class TypeA, class LayoutA,
          class TypeB, class LayoutB,
          class TypeD, class LayoutD,
          class TypeSF, class LayoutSFA, class LayoutSFB,
          class Alpha>
void gemm_host_mxfp8_f32_ws_tnt(TypeA  const* device_ptr_A,   LayoutA   layout_A,
                                TypeB  const* device_ptr_B,   LayoutB   layout_B,
                                TypeD       * device_ptr_D,   LayoutD   layout_D,
                                TypeSF const* device_ptr_SFA, LayoutSFA layout_SFA,
                                TypeSF const* device_ptr_SFB, LayoutSFB layout_SFB,
                                Alpha const alpha)
{
  Tensor mA   = make_tensor(make_gmem_ptr(device_ptr_A),   layout_A);
  Tensor mB   = make_tensor(make_gmem_ptr(device_ptr_B),   layout_B);
  Tensor mD   = make_tensor(make_gmem_ptr(device_ptr_D),   layout_D);
  Tensor mSFA = make_tensor(make_gmem_ptr(device_ptr_SFA), layout_SFA);
  Tensor mSFB = make_tensor(make_gmem_ptr(device_ptr_SFB), layout_SFB);

  auto Gemm_M = shape<0>(layout_A);
  auto Gemm_N = shape<0>(layout_B);
  auto Gemm_K = shape<1>(layout_A);
  std::cout << "Running for problem shape (MxNxK): " << Gemm_M << "x" << Gemm_N << "x" << Gemm_K << std::endl;

  // 2SM block-scaled UMMA: (M=256, N=256, K=32) MXFP8 x MXFP8 -> F32
  TiledMMA tiled_mma = make_tiled_mma(
      SM100_MMA_MXF8F6F4_2x1SM_SS<TypeA, TypeB, TypeD, TypeSF,
                                  256, 256,
                                  UMMA::Major::K, UMMA::Major::K>{});
  print(tiled_mma);

  auto bM = tile_size<0>(tiled_mma);
  auto bN = tile_size<1>(tiled_mma);
  auto bK = tile_size<2>(tiled_mma) * Int<4>{};
  auto mma_tiler = make_shape(bM, bN, bK);

  if (not evenly_divides(shape(mma_tiler), tile_shape(tiled_mma))) {
    std::cerr << "The MMA Shape should evenly divide the MMA Tiler." << std::endl; return;
  }
  if (not evenly_divides(make_shape(Gemm_M, Gemm_N, Gemm_K), mma_tiler)) {
    std::cerr << "MmaTiler_MNK must evenly divide ProblemShape_MNK." << std::endl; return;
  }

  // ---- Single-stage SMEM layouts for A/B (device multiplies by NumStages) --
  auto mma_shape_A = partition_shape_A(tiled_mma, make_shape(size<0>(mma_tiler), size<2>(mma_tiler)));
  auto mma_shape_B = partition_shape_B(tiled_mma, make_shape(size<1>(mma_tiler), size<2>(mma_tiler)));

  auto sA_layout = UMMA::tile_to_mma_shape(UMMA::Layout_K_SW128_Atom<TypeA>{}, mma_shape_A);
  auto sB_layout = UMMA::tile_to_mma_shape(UMMA::Layout_K_SW128_Atom<TypeB>{}, mma_shape_B);

  using SfConfig = cutlass::detail::Sm1xxBlockScaledConfig<32>;
  auto sSFA_layout = SfConfig::deduce_smem_layoutSFA(tiled_mma, mma_tiler);
  auto sSFB_layout = SfConfig::deduce_smem_layoutSFB(tiled_mma, mma_tiler);

  print("sA_layout:\t");   print(sA_layout);   print("\n");
  print("sB_layout:\t");   print(sB_layout);   print("\n");
  print("sSFA_layout:\t"); print(sSFA_layout); print("\n");
  print("sSFB_layout:\t"); print(sSFB_layout); print("\n");

  // ---- Epilogue SMEM layout (single buffer) --------------------------------
  auto mma_shape_C = partition_shape_C(tiled_mma, make_shape(size<0>(mma_tiler), size<1>(mma_tiler)));
  auto epi_tiler = make_tile(size<0,0>(mma_shape_C), size<0,1>(mma_shape_C) / Int<4>{});

  auto sD_layout_mn = tile_to_shape(UMMA::Layout_K_SW128_Atom<TypeD>{},
                                    make_shape(size<0>(epi_tiler), size<1>(epi_tiler)));
  auto sD_layout = group<0,2>(sD_layout_mn);
  print("sD_layout:\t"); print(sD_layout); print("\n");

  using SMEMStorage = SharedStorage<TypeA, TypeB, TypeSF, TypeD,
                                    decltype(sA_layout), decltype(sB_layout),
                                    decltype(sSFA_layout), decltype(sSFB_layout),
                                    decltype(sD_layout)>;

  auto cluster_shape = make_shape(Int<4>{}, Int<4>{}, Int<1>{});
  Layout cluster_layout_vmnk = tiled_divide(make_layout(cluster_shape),
                                            make_tile(typename decltype(tiled_mma)::AtomThrID{}));

  if ((Gemm_M % (bM * size<1>(cluster_layout_vmnk))) != 0 ||
      (Gemm_N % (bN * size<2>(cluster_layout_vmnk))) != 0) {
    std::cerr << "Cluster footprint (ClusterM*bM x ClusterN*bN) = ("
              << int(bM * size<1>(cluster_layout_vmnk)) << " x "
              << int(bN * size<2>(cluster_layout_vmnk))
              << ") must evenly divide ProblemShape_MN ("
              << int(Gemm_M) << " x " << int(Gemm_N) << ")." << std::endl;
    return;
  }

  // TMA atoms use the single-stage A/B layout (the device has NumStages copies).
  Copy_Atom tma_atom_A = make_tma_atom_A_sm100(
      SM100_TMA_2SM_LOAD_MULTICAST{},
      mA, sA_layout, mma_tiler, tiled_mma, cluster_layout_vmnk);
  Tensor mA_tma = tma_atom_A.get_tma_tensor(shape(mA));

  Copy_Atom tma_atom_B = make_tma_atom_B_sm100(
      SM100_TMA_2SM_LOAD_MULTICAST{},
      mB, sB_layout, mma_tiler, tiled_mma, cluster_layout_vmnk);
  Tensor mB_tma = tma_atom_B.get_tma_tensor(shape(mB));

  Copy_Atom tma_atom_D = make_tma_atom(
      SM90_TMA_STORE{}, mD, sD_layout, epi_tiler);
  Tensor mD_tma = tma_atom_D.get_tma_tensor(shape(mD));

  print("tma_atom_A:\t"); print(tma_atom_A); print("\n");
  print("tma_atom_B:\t"); print(tma_atom_B); print("\n");
  print("tma_atom_D:\t"); print(tma_atom_D); print("\n");

  dim3 dimBlock(128);
  dim3 dimCluster(size<0>(cluster_shape), size<1>(cluster_shape), size<2>(cluster_shape));
  dim3 dimGrid(size(ceil_div(Gemm_M, bM * size<1>(cluster_layout_vmnk))) * dimCluster.x,
               size(ceil_div(Gemm_N, bN * size<2>(cluster_layout_vmnk))) * dimCluster.y);
  int  smemBytes = sizeof(SMEMStorage);

  auto* kernel_ptr = &gemm_device<SMEMStorage,
                                  decltype(mA_tma), decltype(mB_tma), decltype(mD_tma),
                                  decltype(mSFA), decltype(mSFB),
                                  decltype(mma_tiler), decltype(epi_tiler),
                                  decltype(tiled_mma), decltype(cluster_shape),
                                  decltype(tma_atom_A), decltype(tma_atom_B), decltype(tma_atom_D),
                                  Alpha>;

  CUTE_CHECK_ERROR(cudaFuncSetAttribute(kernel_ptr,
                                        cudaFuncAttributeMaxDynamicSharedMemorySize,
                                        smemBytes));

  printf("Grid: (%d,%d,%d)  Cluster: (%d,%d,%d)  SMEM: %d bytes\n",
         dimGrid.x, dimGrid.y, dimGrid.z,
         dimCluster.x, dimCluster.y, dimCluster.z, smemBytes);

  cutlass::ClusterLaunchParams params = {dimGrid, dimBlock, dimCluster, smemBytes};
  cutlass::Status status = cutlass::launch_kernel_on_cluster(params, (void const*) kernel_ptr,
                                                             mA_tma, mB_tma, mD,
                                                             mSFA, mSFB,
                                                             mma_tiler, epi_tiler,
                                                             tiled_mma, cluster_shape,
                                                             tma_atom_A, tma_atom_B, tma_atom_D,
                                                             alpha);
  CUTE_CHECK_LAST();
  if (status != cutlass::Status::kSuccess) {
    std::cerr << "Error: Failed at kernel Launch" << std::endl;
  }
}

#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

// Block-scaled reference GEMM: D(m,n) = alpha * sum_k( A(m,k)*B(n,k)*SFA(m,k)*SFB(n,k) )
template <class AccType,
          class TensorA, class TensorB, class TensorD,
          class TensorSFA, class TensorSFB, class Alpha>
void reference_gemm_blockscaled(TensorA const& A, TensorB const& B, TensorD& D,
                                TensorSFA const& SFA, TensorSFB const& SFB, Alpha alpha)
{
  using namespace cute;
  for (int m = 0; m < size<0>(D); ++m) {
    for (int n = 0; n < size<1>(D); ++n) {
      AccType acc = AccType(0.f);
      for (int k = 0; k < size<1>(A); ++k) {
        float a  = float(A(m,k));
        float b  = float(B(n,k));
        float sa = float(SFA(m,k));
        float sb = float(SFB(n,k));
        acc += AccType(a * sa * b * sb);
      }
      D(m,n) = AccType(alpha) * acc;
    }
  }
}

int main(int argc, char** argv)
{
  cudaDeviceProp props;
  int current_device_id;
  cudaGetDevice(&current_device_id);
  cudaGetDeviceProperties(&props, current_device_id);
  cudaError_t err = cudaGetDeviceProperties(&props, 0);
  if (err != cudaSuccess) {
    std::cerr << "cudaGetDeviceProperties() returned an error: " << cudaGetErrorString(err) << std::endl;
    return -1;
  }
  if ((props.major != 10) || (props.major == 10 && props.minor > 1)) {
    std::cerr << "This example requires Blackwell compute capability 100a. Found "
              << props.major << "." << props.minor << std::endl;
    return -1;
  }

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

  int Gemm_M = 1024; if (argc >= 2) sscanf(argv[1], "%d", &Gemm_M);
  int Gemm_N = 1024; if (argc >= 3) sscanf(argv[2], "%d", &Gemm_N);
  int Gemm_K = 512;  if (argc >= 4) sscanf(argv[3], "%d", &Gemm_K);

  using TypeA  = cutlass::float_e4m3_t;
  using TypeB  = cutlass::float_e4m3_t;
  using TypeSF = cutlass::float_ue8m0_t;
  using TypeD  = float;
  using TypeAccumulator = float;
  auto type_str_a = "e4m3";
  auto type_str_b = "e4m3";
  auto type_str_d = "float";

  Layout layout_A = make_layout(make_shape (Gemm_M, Gemm_K), make_stride(Gemm_K, Int<1>{}));
  Layout layout_B = make_layout(make_shape (Gemm_N, Gemm_K), make_stride(Gemm_K, Int<1>{}));
  Layout layout_D = make_layout(make_shape (Gemm_M, Gemm_N), make_stride(Gemm_N, Int<1>{}));

  using SfConfig = cutlass::detail::Sm1xxBlockScaledConfig<32>;
  auto layout_SFA = SfConfig::tile_atom_to_shape_SFA(make_shape(Gemm_M, Gemm_N, Gemm_K));
  auto layout_SFB = SfConfig::tile_atom_to_shape_SFB(make_shape(Gemm_M, Gemm_N, Gemm_K));
  print("layout_SFA:\t"); print(layout_SFA); print("\n");
  print("layout_SFB:\t"); print(layout_SFB); print("\n");

  thrust::host_vector<TypeA>  host_A (Gemm_M * Gemm_K);
  thrust::host_vector<TypeB>  host_B (Gemm_N * Gemm_K);
  thrust::host_vector<TypeSF> host_SFA(cute::cosize(layout_SFA));
  thrust::host_vector<TypeSF> host_SFB(cute::cosize(layout_SFB));

  Tensor host_tensor_A   = make_tensor(host_A.data(),   layout_A);
  Tensor host_tensor_B   = make_tensor(host_B.data(),   layout_B);
  Tensor host_tensor_SFA = make_tensor(host_SFA.data(), layout_SFA);
  Tensor host_tensor_SFB = make_tensor(host_SFB.data(), layout_SFB);

  initialize_tensor(host_tensor_A);
  initialize_tensor(host_tensor_B);

  srand(0xC0FFEE);
  auto random_ue8m0 = []() {
    int exp = 122 + (rand() % 11);
    return TypeSF::bitcast(uint8_t(exp));
  };
  for (size_t i = 0; i < host_SFA.size(); ++i) host_SFA[i] = random_ue8m0();
  for (size_t i = 0; i < host_SFB.size(); ++i) host_SFB[i] = random_ue8m0();

  thrust::device_vector<TypeA>  device_A   = host_A;
  thrust::device_vector<TypeB>  device_B   = host_B;
  thrust::device_vector<TypeSF> device_SFA = host_SFA;
  thrust::device_vector<TypeSF> device_SFB = host_SFB;
  thrust::device_vector<TypeD>  device_D(Gemm_M * Gemm_N);

  float alpha = 1.0f;
  gemm_host_mxfp8_f32_ws_tnt(device_A.data().get(),   layout_A,
                             device_B.data().get(),   layout_B,
                             device_D.data().get(),   layout_D,
                             device_SFA.data().get(), layout_SFA,
                             device_SFB.data().get(), layout_SFB,
                             alpha);

  thrust::host_vector<TypeD> host_D = device_D;
  Tensor host_tensor_D = make_tensor(host_D.data(), layout_D);

  thrust::host_vector<TypeD> host_reference_D(Gemm_M * Gemm_N);
  auto host_reference_tensor_D = make_tensor(host_reference_D.data(), layout_D);
  reference_gemm_blockscaled<TypeAccumulator>(host_tensor_A, host_tensor_B,
                                              host_reference_tensor_D,
                                              host_tensor_SFA, host_tensor_SFB, alpha);

  auto relative_error = print_matrix_multiply_mollified_relative_error(
      type_str_a, host_tensor_A,
      type_str_b, host_tensor_B,
      type_str_d, host_tensor_D, host_reference_tensor_D);
  bool success = relative_error <= 1e-2;
  std::cout << "Execution is " << ((success) ? "successful." : "failed.") << std::endl;
#else
  std::cout << "CUTLASS_ARCH_MMA_SM100_SUPPORTED must be enabled, but it is not. Test is waived.\n";
#endif
  return 0;
}
