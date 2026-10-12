/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#pragma once

#include <cassert>
#include <cstdint>
#include <iostream>
#include <cstdio>
#include <cmath>

// Cutlass includes
#include <cutlass/cutlass.h>
#include <cutlass/numeric_types.h>
#include <cutlass/arch/barrier.h>
#include <cutlass/gemm/collective/builders/sm100_common.inl> // mma/smem selector, umma::major
#include <cutlass/numeric_conversion.h>
#include <cutlass/arch/grid_dependency_control.h>

// CuTe includes
#include <cute/tensor.hpp>                      // CuTe tensor implementation
#include <cute/arch/tmem_allocator_sm100.hpp>   // TMEM allocator for SM100
#include <cute/arch/copy_sm90_desc.hpp>
#include <cute/arch/copy_sm90_tma.hpp>

#include "common.cuh"
#include "tgv_gqa.cuh"  // reuse layout helpers, WorkTileInfo, TMA_copy, MMA_gemm, reductions, DMA_Q/MMA/EPILOG warps

// Grouped Query Attention (paged KV cache) with dual BMM + online softmax. 7 warps: 1 DMA_Q, 1 DMA_KV, 1 MMA,
// 4 EPILOG. Warp 3 is unused.
// Warp 0 (DMA_Q):       Loads Q via TMA, single-stage. Reused from gqa namespace (gqa::DMA_Q_warp).
// Warp 1 (DMA_KV):      Loads K then V via TMA, one cp.async.bulk per page. Issues its own cp.async of per-CTA-tile
//                       page indices into a smem staging buffer (lane-distributed, thread-local cp_async fence/wait).
//                       Defined locally in gqa_paged namespace.
// Warp 2 (MMA):         Performs BMM1 (K@Q) and BMM2 (V@P). Reused from gqa namespace (gqa::MMA_warp).
// Warps 4-7 (EPILOG):   Softmax partial max/sum warp reduction, cluster wide max/sum reduction, final flash-decode
//                       output with attention sink support. Reused from gqa namespace (gqa::EPILOG_warp).
// WorkTileInfo: Reused from gqa namespace. Attention-specific fields: BS_idx, kvH_idx, kvL_idx_start/end, dH_idx, qHLocal_idx, qL_idx.
// SharedStorage: Defined locally. Inherits from gqa::SharedStorage and adds the paged-only pieces: PageIdx smem
//   buffer (double-buffered because K and V are offset by 1 tile -- around pi-stage boundaries they read different
//   slots) and paged views (tensor_sK_paged / tensor_sV_paged / tensor_sPageIdx) over the inherited K/V smem buffers.

namespace TGV {
namespace gqa_paged {

using namespace cute;

// Symbols reused identically from TGV::gqa -- see tgv_gqa.cuh for definitions.
// Log2_E and WorkTileInfo are pulled in here; everything else is referenced explicitly via gqa:: at call sites.
using TGV::gqa::Log2_E;
using TGV::gqa::WorkTileInfo;

// The (bs_idx, per_batch_page_idx) -> physical page id mapping lives in a gmem page_table tensor of shape
// (kvL/Page_Size, BS), seeded by the host harness and fetched at runtime by DMA_KV_warp. To install a
// new placement policy, populate the page_table differently host-side; the kernel does not assume any structure.
// The shared memory buffers for Q, K, V matrices.
template <
  class TypeQKV,         // Tensor Q/K/V data type
  class TypeAcc,         // Tensor Acc data type
  class KSmemLayout,     // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
  class KPagedSmemLayout,// (Page_Size, CTA_dH, NumPagePerCTATile, BMM1_DMA_Stage), same memory as KSmemLayout
  class QSmemLayout,     // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
  class VSmemLayout,     // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
  class VPagedSmemLayout,// (CTA_dH, Page_Size, NumPagePerCTATile, BMM2_DMA_Stage), same memory as VSmemLayout
  class SSmemLayout,     // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1) aka C matrix (M, N, 1) for bmm1
  class PSmemLayout,     // ((CTA_qHLocal, CTA_qL), CTA_kvL, 1) aka B matrix (N, K, 1) for bmm2
  class WRSmemLayout,    // (NumEpilogWarps, (CTA_qHLocal, CTA_qL)), WR stands for warp reduce
  class MSMailboxSmemLayout,// (MaxSplits, CTA_qHLocal * CTA_qL / NumReductionCTA), MS stands max and sum
  class Acc1SmemLayout,  // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1)
  class Acc2MailboxSmemLayout, // (CTA_dH, CTA_qHLocal * CTA_qL / NumReductionCTA, MaxSplits)
  class SinksSmemLayout, // (CTA_qHLocal * CTA_qL / NumReductionCTA)
  class PageIdxSmemLayout, // ((NumPagePerCTATile, Tiles_Per_Pi_Stage), Page_Idx_Stage), int32 page indices staged by DMA_KV warp
  int BMM1_DMA_Stage,
  int BMM2_DMA_Stage,
  int Page_Idx_Stage>
// Paged kernel adds two pieces on top of the plain gqa SharedStorage:
//   - PageIdx smem buffer (DMA_KV staging, int32 page indices). Double-buffered: K and V are 1 tile apart, so
//     around a pi-stage boundary they read different slots. DMA_KV writes the next slot via lane-distributed
//     cp.async at K_t_in_stage==1 (when V has crossed into the current pi-stage and the next slot is free).
//   - paged views of the inherited K/V smem buffers (same memory, different layout)
struct SharedStorage : TGV::gqa::SharedStorage<
    TypeQKV, TypeAcc,
    KSmemLayout, QSmemLayout, VSmemLayout, SSmemLayout, PSmemLayout,
    WRSmemLayout, MSMailboxSmemLayout, Acc1SmemLayout,
    Acc2MailboxSmemLayout, SinksSmemLayout,
    BMM1_DMA_Stage, BMM2_DMA_Stage> {
  // DMA_KV staging buffer for int32 page indices, layout ((NumPagePerCTATile, Tiles_Per_Pi_Stage), Page_Idx_Stage)
  alignas(128) cute::ArrayEngine<int, cute::cosize_v<PageIdxSmemLayout>> PageIdx;

  // alternative paged view of the same K smem buffer used by TMA: (Page_Size, CTA_dH, NumPagePerCTATile, BMM1_DMA_Stage)
  CUTE_DEVICE constexpr auto tensor_sK_paged() { return make_tensor(make_smem_ptr(this->K.begin()), KPagedSmemLayout{}); }
  // alternative paged view of the same V smem buffer used by TMA: (CTA_dH, Page_Size, NumPagePerCTATile, BMM2_DMA_Stage)
  CUTE_DEVICE constexpr auto tensor_sV_paged() { return make_tensor(make_smem_ptr(this->V.begin()), VPagedSmemLayout{}); }
  CUTE_DEVICE constexpr auto tensor_sPageIdx() { return make_tensor(make_smem_ptr(PageIdx.begin()), PageIdxSmemLayout{}); }
};

// paged TMA copy: like gqa::TMA_copy, but issues NumPagePerCTATile back-to-back copies that share one full barrier.
// empty/full barrier semantics still operate at CTA-tile granularity -- one slot covers the whole (CTA_kvL, CTA_dH) tile,
// transaction bytes counts all pages, and a single set_barrier_transaction_bytes arrives once per stage.
//
// Page indices are read from smem -- DMA_KV stages them from the gmem page_table via lane-distributed
// cp.async and a thread-local cp_async_fence/wait. The caller passes a smem pointer to the
// NumPagePerCTATile page indices owned by this tile; this function performs an ld.shared per page and uses the
// resulting global page id as the gmem coordinate for the TMA copy.
template <
  class GTensor,
  class STensor,
  class TmaAtom,
  char Name,
  bool Print,
  int DMA_Stage,
  int NumPagePerCTATile>
CUTLASS_DEVICE void
TMA_copy_paged(
  GTensor gTensor, // ((TMA, NumTma_K), Num_Page_Global)
  STensor sTensor, // ((TMA, NumTma_K), NumPagePerCTATile, DMA_Stage)
  int k_tile,
  int const* page_idx_smem, // pointer to NumPagePerCTATile contiguous int page indices in smem (this tile's slice)
  int& tma_mma_empty_barrier_phase_bit,
  int tma_transaction_bytes, // total bytes for one CTA tile (NumPagePerCTATile pages)
  TmaAtom const* tma_atom,
  cute::uint64_t* tma_mma_full_barrier,
  cute::uint64_t* tma_mma_empty_barrier
) {
  // wait for the smem slot to be empty before issuing pages for the next CTA tile
  wait_barrier(tma_mma_empty_barrier[k_tile % DMA_Stage], tma_mma_empty_barrier_phase_bit);

  if constexpr (Print) {
    if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
      printf("[DMA_%c] barrier empty, kblock %d (paged, %d pages)\n", Name, k_tile, NumPagePerCTATile);
    }
  }

  if (elect_one_sync()) {
    // single set_barrier_transaction_bytes accounts for all pages; later cute::copy calls don't add arrivals.
    set_barrier_transaction_bytes(tma_mma_full_barrier[k_tile % DMA_Stage], tma_transaction_bytes);
    CUTE_UNROLL
    for (int p = 0; p < NumPagePerCTATile; p++) {
      // per-page lookup: load global page id from smem and feed it as the gmem coordinate for one TMA copy.
      int global_page = page_idx_smem[p];
      copy(tma_atom->with(tma_mma_full_barrier[k_tile % DMA_Stage]),
           gTensor(_, global_page),
           sTensor(_, p, k_tile % DMA_Stage));
    }
  }

  if ((k_tile % DMA_Stage) == (DMA_Stage - 1)) {
    tma_mma_empty_barrier_phase_bit ^= 1;
  }
}

// Lane-distributed cp.async of one pi-stage's worth (Num_Page_Idx_Per_Stage ints) of page indices from gmem
// page table to a smem slot. Each lane loads ceil(Num_Page_Idx_Per_Stage/32) ints; the LSU coalesces them.
// Caller pre-slices the BS mode of the page table (it is CTA-constant) and is responsible for
// cp_async_fence/wait + __syncwarp ordering after this returns.
template <
  int Tiles_Per_Pi_Stage, int Num_Page_Idx_Per_Stage, int Page_Idx_Stage,
  class GPageTableTensor, class SPageIdxTensor>
CUTLASS_DEVICE void
issue_pi_stage_cp_async(
  GPageTableTensor gPageTable, // ((NumPagePerCTATile, kvL/CTA_kvL),), int gmem -- BS already sliced
  SPageIdxTensor sPageIdx,     // ((NumPagePerCTATile, Tiles_Per_Pi_Stage), Page_Idx_Stage), int smem
  int kvL_idx_start, int pi_stage_idx) {
  int tile_start = kvL_idx_start + pi_stage_idx * Tiles_Per_Pi_Stage;
  int slot = pi_stage_idx % Page_Idx_Stage;
  // Shift gPageTable's data pointer to the first page of this pi-stage; flat-index `i` walks consecutive
  // (page-within-CTA-tile, CTA-tile) pairs in column-major order across Num_Page_Idx_Per_Stage ints.
  auto gp = domain_offset(make_coord(make_coord(0, tile_start)), gPageTable);
  // Use threadIdx.x-derived lane (cheap: threadIdx.x is already live in a register from earlier in the kernel).
  int lane = cutlass::canonical_lane_idx();
  CUTE_UNROLL
  for (int i = lane; i < Num_Page_Idx_Per_Stage; i += 32) {
    cp_async(&gp(i), &sPageIdx(i, slot));
  }
}

// Paged DMA_KV warp: TMA-loads K then V, one cp.async.bulk per page. Page indices are staged into smem by this
// same warp via lane-distributed cp.async (no separate Read_Page_Idx warp, no transaction-barrier handshake).
// See the in-body comment ahead of the prolog for the page-idx fetch pipeline. Tiles_Per_Pi_Stage >= 2 is
// required so the K_t_in_stage==1 issue hook exists.
template <
  class SharedStorage,
  class WorkTileInfo,
  class KTensor,
  class VTensor,
  class PageTableTensor,
  class TmaAtomK,
  class TmaAtomV,
  int CTA_kvL, int CTA_dH, int Page_Size,
  int Page_Idx_Stage, int Num_Page_Idx_Per_Stage>
CUTLASS_DEVICE void
DMA_KV_warp(
  SharedStorage& shared_storage,
  WorkTileInfo work_tile_info,
  KTensor mK,
  VTensor mV,
  PageTableTensor mPageTable,  // (kvL/Page_Size, BS), int gmem; underlying allocation tail-padded by Num_Page_Idx_Per_Stage ints. Mode-0 is partitioned by NumPagePerCTATile to access per-CTA-tile slices.
  // when passing tma descriptor as function argument, it has to be pass by pointer/reference, if pass by value, it will live on local memory (i.e. the stack)
  // and the tma unit cannot access the local memory, (even if it can, the local memory is strided by thread id, the content for each thread is strided)
  TmaAtomK const* tma_atom_K,
  TmaAtomV const* tma_atom_V) {

  if (!work_tile_info.is_valid()) {
    return;
  }

  // CTA_kvL % Page_Size == 0, Num_Page_Idx_Per_Stage % NumPagePerCTATile == 0, Page_Idx_Stage == 2,
  // and Tiles_Per_Pi_Stage >= 2 are all checked in gqa_paged_host.
  constexpr int NumPagePerCTATile = CTA_kvL / Page_Size;
  constexpr int Tiles_Per_Pi_Stage = Num_Page_Idx_Per_Stage / NumPagePerCTATile;

  // setup code for K tensor
  // paged smem view of K, NOT mma partitioned, used purely for TMA: (Page_Size, CTA_dH, NumPagePerCTATile, BMM1_DMA_Stage)
  // the same smem buffer is also accessible via tensor_sK() in MMA-partitioned form for the MMA warp.
  Tensor sK_paged = shared_storage.tensor_sK_paged();   // (Page_Size, CTA_dH, NumPagePerCTATile, BMM1_DMA_Stage)
  // mK has shape (Page_Size, dH, Num_Page_Global, kvH); BS is folded into Num_Page_Global so there is no BS mode.
  // local_tile with a static (Page_Size, CTA_dH) tile_shape materializes the leading two modes statically (TMA
  // partition requires static mode-0 sizes); dH==CTA_dH and Page_Size already matches so the divisions collapse.
  // The page selection is done at TMA-issue time via the smem page_idx slice (staged by DMA_KV's own cp.async),
  // not by indexing on a BS mode here.
  Tensor gK = local_tile(mK, make_shape(Int<Page_Size>{}, Int<CTA_dH>{}),
                          make_coord(0, 0, _, work_tile_info.kvH_idx));  // (Page_Size, CTA_dH, Num_Page_Global)

  // group modes [0,2) on both sK_paged and gK so the TMA box (Page_Size, CTA_dH) is mode 0; outer modes are
  // (NumPagePerCTATile, BMM1_DMA_Stage) for smem and Num_Page_Global for gmem.
  auto [tAgK, tAsK] = tma_partition(*tma_atom_K,
                                  Int<0>{}, // cta_coord: 1x1 cluster
                                  Layout<_1>{}, // cta_layout: CTA coord -> logical multicast id, no multicast, just identity layout
                                  group_modes<0, 2>(sK_paged), group_modes<0, 2>(gK));
  // tAsK: ((TMA, NumTma_K), NumPagePerCTATile, BMM1_DMA_Stage) -- 3 modes
  // tAgK: ((TMA, NumTma_K), Num_Page_Global) -- 2 modes
  // the shape of the TMA box is (Page_Size, CTA_dH)

  /*if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    printf("[PAGED-K] sK_paged:\t"); print(sK_paged); printf("\n");  // (Page_Size, CTA_dH, NumPagePerCTATile, BMM1_DMA_Stage)
    printf("[PAGED-K] gK:\t"); print(gK); printf("\n");              // (Page_Size, CTA_dH, Num_Page_Global)
    printf("[PAGED-K] tAgK:\t"); print(tAgK); printf("\n");          // ((TMA, NumTma_K), Num_Page_Global)
    printf("[PAGED-K] tAsK:\t"); print(tAsK); printf("\n");          // ((TMA, NumTma_K), NumPagePerCTATile, BMM1_DMA_Stage)
  }*/

  // setup code for V tensor
  // paged smem view of V, NOT mma partitioned, used purely for TMA: (CTA_dH, Page_Size, NumPagePerCTATile, BMM2_DMA_Stage)
  // the same smem buffer is also accessible via tensor_sV() in MMA-partitioned form for the MMA warp.
  Tensor sV_paged = shared_storage.tensor_sV_paged();   // (CTA_dH, Page_Size, NumPagePerCTATile, BMM2_DMA_Stage)
  // mV has shape (dH, Page_Size, Num_Page_Global, kvH); BS is folded into Num_Page_Global so there is no BS mode.
  Tensor gV = local_tile(mV, make_shape(Int<CTA_dH>{}, Int<Page_Size>{}),
                          make_coord(0, 0, _, work_tile_info.kvH_idx));  // (CTA_dH, Page_Size, Num_Page_Global)

  // group modes [0,2) on both sV_paged and gV so the TMA box (CTA_dH, Page_Size) is mode 0; outer modes are
  // (NumPagePerCTATile, BMM2_DMA_Stage) for smem and Num_Page_Global for gmem.
  auto [tAgV, tAsV] = tma_partition(*tma_atom_V,
                                  Int<0>{}, // cta_coord: 1x1 cluster
                                  Layout<_1>{}, // cta_layout: CTA coord -> logical multicast id, no multicast, just identity layout
                                  group_modes<0, 2>(sV_paged), group_modes<0, 2>(gV));
  // tAsV: ((TMA, NumTma_K), NumPagePerCTATile, BMM2_DMA_Stage) -- 3 modes
  // tAgV: ((TMA, NumTma_K), Num_Page_Global) -- 2 modes
  // the shape of the TMA box is (CTA_dH, Page_Size)

  /*if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    printf("[PAGED-V] sV_paged:\t"); print(sV_paged); printf("\n");  // (CTA_dH, Page_Size, NumPagePerCTATile, BMM2_DMA_Stage)
    printf("[PAGED-V] gV:\t"); print(gV); printf("\n");              // (CTA_dH, Page_Size, Num_Page_Global)
    printf("[PAGED-V] tAgV:\t"); print(tAgV); printf("\n");          // ((TMA, NumTma_K), Num_Page_Global)
    printf("[PAGED-V] tAsV:\t"); print(tAsV); printf("\n");          // ((TMA, NumTma_K), NumPagePerCTATile, BMM2_DMA_Stage)
  }*/

  // total K/V bytes per stage slot = all NumPagePerCTATile pages combined (they share one full barrier).
  // Slice tAsK/tAsV at one stage to get all pages in that stage; size_in_bytes is implicit via sizeof(tensor_like).
  int tma_K_transaction_bytes = sizeof(make_tensor_like(tAsK(_, _, 0)));
  int tma_V_transaction_bytes = sizeof(make_tensor_like(tAsV(_, _, 0)));
  int k_tile_count = work_tile_info.kvL_idx_end - work_tile_info.kvL_idx_start;
  // BMM1_DMA_Stage = mode 3 of rank-4 sK_paged (Page_Size, CTA_dH, NumPage, Stage)
  // BMM2_DMA_Stage = mode 3 of rank-4 sV_paged (CTA_dH, Page_Size, NumPage, Stage)
  int constexpr BMM1_DMA_Stage = size<3>(sK_paged);
  int constexpr BMM2_DMA_Stage = size<3>(sV_paged);

  /*if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    printf("[PAGED-K] tma_K_transaction_bytes (per CTA tile)=%d\n", tma_K_transaction_bytes);
    printf("[PAGED-V] tma_V_transaction_bytes=%d, k_tile_count=%d, BMM1_DMA_Stage=%d, BMM2_DMA_Stage=%d\n", tma_V_transaction_bytes, k_tile_count, BMM1_DMA_Stage, BMM2_DMA_Stage);
  }*/

  // details of how the phase bit works is in DMA_Q_warp (in tgv_gqa.cuh)
  int tma_bmm1_empty_barrier_phase_bit = 1;
  int tma_bmm2_empty_barrier_phase_bit = 1;

  int bmm1_k_tile = 0;
  int bmm2_k_tile = 0;

  bool constexpr Print = false;

  // sPageIdx layout: ((NumPagePerCTATile, Tiles_Per_Pi_Stage), Page_Idx_Stage). For tile t (CTA-tile idx):
  //   t_in_stage = t % Tiles_Per_Pi_Stage; pi_slot = (t / Tiles_Per_Pi_Stage) % Page_Idx_Stage;
  //   page_idx_smem_ptr = &sPageIdx(make_coord(0, t_in_stage), pi_slot).
  Tensor sPageIdx = shared_storage.tensor_sPageIdx();

  // gPageTable view: per-CTA slice of the page table, then split mode 0 by NumPagePerCTATile so the
  // (page-within-CTA-tile, CTA-tile-idx) split is explicit. BS is sliced upfront -- it's CTA-constant.
  // Tail-padded host allocation lets us read up to Tiles_Per_Pi_Stage tiles past kvL_idx_end without OOB.
  Tensor gPageTable = logical_divide(mPageTable(_, work_tile_info.BS_idx), Shape<Int<NumPagePerCTATile>>{}); // ((NumPagePerCTATile, kvL/CTA_kvL),)

  // SOL order: K0, (K1, V0), (K2, V1), ...
  //
  // Page-idx fetch pipeline. The page-idx smem buffer is double-buffered (Page_Idx_Stage=2 slots) because
  // K leads V by 1 tile -- around a pi-stage boundary K reads slot S%2 (stage S) while V is finishing the
  // last tile of slot (S-1)%2 (stage S-1), so the two slots must coexist. Synchronization is thread-local
  // cp_async_fence/cp_async_wait<0> + __syncwarp -- no cross-warp barrier.
  //   * Prolog: issue stage 0 -> slot 0, fence, wait, syncwarp, then K0 TMA.
  //   * Main loop K_t_in_stage == 0: drain the previously-issued cp.async (stage K_pi_stage's data). At this
  //     point at most one cp.async group is outstanding so wait<0> is correct.
  //   * Main loop K_t_in_stage == 1: pre-issue stage K_pi_stage+1 -> slot (K_pi_stage+1)%2 if it has tiles
  //     in this CTA's range. V crossed into pi-stage K_pi_stage at the previous iteration, so slot
  //     (K_pi_stage+1)%2 = (K_pi_stage-1)%2 is no longer being ld.shared'd and is safe to overwrite. The
  //     consumer's wait at the next pi-stage boundary (Tiles_Per_Pi_Stage-1 tiles later) hides the RTT.

  // Prolog: stage 0 must be in slot 0 before K0 reads it.
  {
    issue_pi_stage_cp_async<Tiles_Per_Pi_Stage, Num_Page_Idx_Per_Stage, Page_Idx_Stage>(
        gPageTable, sPageIdx, work_tile_info.kvL_idx_start, /*pi_stage_idx=*/0);
    cp_async_fence();
    cp_async_wait<0>();
    __syncwarp();

    // K0 prolog (no V yet).
    TMA_copy_paged<decltype(tAgK), decltype(tAsK), TmaAtomK, 'K', Print, BMM1_DMA_Stage, NumPagePerCTATile>(tAgK, tAsK, bmm1_k_tile, &sPageIdx(make_coord(0, 0), 0), tma_bmm1_empty_barrier_phase_bit, tma_K_transaction_bytes, tma_atom_K, shared_storage.tma_bmm1_full_barrier, shared_storage.tma_bmm1_empty_barrier);
    bmm1_k_tile++;
  }

  for (; bmm1_k_tile < k_tile_count; bmm1_k_tile++, bmm2_k_tile++) {
    int K_t_in_stage = bmm1_k_tile % Tiles_Per_Pi_Stage;
    int K_pi_stage = bmm1_k_tile / Tiles_Per_Pi_Stage;
    int K_pi_slot = K_pi_stage % Page_Idx_Stage;

    // Drain stage K_pi_stage's cp.async before K reads its slot.
    if (K_t_in_stage == 0) {
      cp_async_wait<0>();
      __syncwarp();
    }

    // Pre-issue stage K_pi_stage+1 if there are still tiles in this CTA's range to consume from it.
    if (K_t_in_stage == 1) {
      int next_pi_stage = K_pi_stage + 1;
      int next_tile_start = work_tile_info.kvL_idx_start + next_pi_stage * Tiles_Per_Pi_Stage;
      if (next_tile_start < work_tile_info.kvL_idx_end) {
        issue_pi_stage_cp_async<Tiles_Per_Pi_Stage, Num_Page_Idx_Per_Stage, Page_Idx_Stage>(
            gPageTable, sPageIdx, work_tile_info.kvL_idx_start, next_pi_stage);
        cp_async_fence();
      }
    }

    TMA_copy_paged<decltype(tAgK), decltype(tAsK), TmaAtomK, 'K', Print, BMM1_DMA_Stage, NumPagePerCTATile>(tAgK, tAsK, bmm1_k_tile, &sPageIdx(make_coord(0, K_t_in_stage), K_pi_slot), tma_bmm1_empty_barrier_phase_bit, tma_K_transaction_bytes, tma_atom_K, shared_storage.tma_bmm1_full_barrier, shared_storage.tma_bmm1_empty_barrier);

    int V_t_in_stage = bmm2_k_tile % Tiles_Per_Pi_Stage;
    int V_pi_slot    = (bmm2_k_tile / Tiles_Per_Pi_Stage) % Page_Idx_Stage;
    TMA_copy_paged<decltype(tAgV), decltype(tAsV), TmaAtomV, 'V', Print, BMM2_DMA_Stage, NumPagePerCTATile>(tAgV, tAsV, bmm2_k_tile, &sPageIdx(make_coord(0, V_t_in_stage), V_pi_slot), tma_bmm2_empty_barrier_phase_bit, tma_V_transaction_bytes, tma_atom_V, shared_storage.tmasoftmax_bmm2_full_barrier, shared_storage.tma_bmm2_empty_barrier);
  }

  // V epilog (last V). Its slot is already populated by an earlier cp.async.
  {
    int V_t_in_stage = bmm2_k_tile % Tiles_Per_Pi_Stage;
    int V_pi_slot    = (bmm2_k_tile / Tiles_Per_Pi_Stage) % Page_Idx_Stage;
    TMA_copy_paged<decltype(tAgV), decltype(tAsV), TmaAtomV, 'V', Print, BMM2_DMA_Stage, NumPagePerCTATile>(tAgV, tAsV, bmm2_k_tile, &sPageIdx(make_coord(0, V_t_in_stage), V_pi_slot), tma_bmm2_empty_barrier_phase_bit, tma_V_transaction_bytes, tma_atom_V, shared_storage.tmasoftmax_bmm2_full_barrier, shared_storage.tma_bmm2_empty_barrier);
  }

  cutlass::arch::launch_dependent_grids();
}

// mK has shape (Page_Size, dH, num_pages, kvH)
// mQ has shape ((qHLocal, qL), dH, kvH, BS)
// mV has shape (dH, Page_Size, num_pages, kvH)
// mO has shape (dH, (qHLocal, qL), kvH, BS)
// mSink has shape ((qHLocal, qL), kvH)
// mSeqLens has shape (BS)
// mPageTable has shape (kvL/Page_Size, BS), entry [p, bs] = physical page id of batch bs's per-batch page p
// (BS is folded into num_pages on the K/V side; mPageTable supplies the (bs, kvL) -> page mapping.)
template <
  class SharedStorage,
  class KTensor, class QTensor, class VTensor, class OTensor, class SinkTensor,
  class SeqLensTensor, class PageTableTensor,
  class TmaAtomK, class TmaAtomQ, class TmaAtomV,
  class TiledBMM1, class TiledBMM2,
  class TypeAcc,
  int CTA_qHLocal, int CTA_qL, int CTA_kvL, int CTA_dH,
  int Page_Size,
  int BMM1_DMA_Stage, int BMM2_DMA_Stage,
  int Page_Idx_Stage, int Num_Page_Idx_Per_Stage,
  int MaxSplits, int NumReductionCTA,
  bool NoSink>
__maxnreg__(128)
__global__ void
gqa_paged_device(
  KTensor mK,
  QTensor mQ,
  VTensor mV,
  OTensor mO,
  SinkTensor mSink,
  SeqLensTensor mSeqLens,
  PageTableTensor mPageTable,  // (kvL/Page_Size, BS); underlying allocation tail-padded by Num_Page_Idx_Per_Stage ints
  CUTE_GRID_CONSTANT TmaAtomK const tma_atom_K,
  CUTE_GRID_CONSTANT TmaAtomQ const tma_atom_Q,
  CUTE_GRID_CONSTANT TmaAtomV const tma_atom_V,
  TiledBMM1 tiled_bmm1,
  TiledBMM2 tiled_bmm2,
  float softmax_scale_log2,
  int sliding_window_size,
  int pdl_count
) {
  // Allocate SMEM
  extern __shared__ char shared_memory[];
  SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(shared_memory);

  // WorkTileInfo, for non persistent static scheduler, cta id is the work tile info
  // since loading the seq_lens is on the critical path of the prolog, we want to start it as soon as possible
  // mK shape: (Page_Size, CTA_dH, Num_Page_Global, kvH) -- BS is folded into Num_Page_Global; kvH is mode 3.
  int kvH = shape<3>(mK);
  int BS_idx = blockIdx.x / kvH;
  // only thread 0 issues cp.async to load the seq_len -- keep this as the first thing on the critical path.
  if (threadIdx.x == 0) {
    cp_async(&mSeqLens(BS_idx), &shared_storage.seq_len);
  }

  int warp_idx = cutlass::canonical_warp_idx_sync();

  // barrier initialization, warp 0 does initialization
  if (warp_idx == 0) {
    // transaction barrier because tma arrive on it, 6 thread arrive: one for DMA_Q warp, one for DMA_KV (K fetch) warp, and 4 for softmax warp (tcgen05.ld Acc1 is done).
    // For paged K, DMA_KV still arrives ONCE per stage (via set_barrier_transaction_bytes once with total bytes for all pages).
    cutlass::arch::detail::initialize_barrier_array_aligned<cutlass::arch::ClusterTransactionBarrier, BMM1_DMA_Stage>(shared_storage.tma_bmm1_full_barrier, /* arrival count */ 6);
    // 1 thread (BMM1) arrive to signal DMA_Q and DMA_KV (K fetch) warp
    cutlass::arch::detail::initialize_barrier_array_aligned<cutlass::arch::ClusterBarrier, BMM1_DMA_Stage>(shared_storage.tma_bmm1_empty_barrier, /* arrival count */ 1);
    // transaction barrier because tma arrive on it, 5 thread arrive: one for DMA_KV (V fetch) warp and 4 for softmax warp (S/P store)
    cutlass::arch::detail::initialize_barrier_array_aligned<cutlass::arch::ClusterTransactionBarrier, BMM2_DMA_Stage>(shared_storage.tmasoftmax_bmm2_full_barrier, /* arrival count */ 5);
    // 1 thread (BMM2) arrive to signal DMA_KV (V fetch) and softmax warp (P store)
    cutlass::arch::detail::initialize_barrier_array_aligned<cutlass::arch::ClusterBarrier, BMM2_DMA_Stage>(shared_storage.tma_bmm2_empty_barrier, /* arrival count */ 1);
    // 1 thread (BMM1) arrive to signal softmax
    cutlass::arch::detail::initialize_barrier_array_aligned<cutlass::arch::ClusterBarrier, 1>(&shared_storage.bmm1_softmax_full_barrier, /* arrival count */ 1);
    // 1 thread (BMM2) arrive to signal epilog
    cutlass::arch::detail::initialize_barrier_array_aligned<cutlass::arch::ClusterBarrier, 1>(&shared_storage.bmm2_epilog_full_barrier, /* arrival count */ 1);
    // 32 (mma) + 128 (epilog) to signal tmem allocation/deallocation result
    cutlass::arch::detail::initialize_barrier_array_aligned<cutlass::arch::ClusterBarrier, 1>(&shared_storage.tmem_allocation_result_barrier, /* arrival count */ 32 + 128);
    // 1 thread (epilog) arrive to signal maxsum
    cutlass::arch::detail::initialize_barrier_array_aligned<cutlass::arch::ClusterTransactionBarrier, 1>(&shared_storage.maxsum_mailbox_full_barrier, /* arrival count */ 1);
    // 1 thread (epilog) arrive to signal acc2
    cutlass::arch::detail::initialize_barrier_array_aligned<cutlass::arch::ClusterTransactionBarrier, 1>(&shared_storage.acc2_mailbox_full_barrier, /* arrival count */ 1);
    // No page-idx full/empty barriers: DMA_KV fetches its own page indices via cp.async with thread-local
    // cp_async_fence/wait, so the cross-warp transaction-barrier handshake is gone.
  }
  // syncing all threads (128) within 4 epilog warps
  cutlass::arch::NamedBarrier epilog_barrier(128, cutlass::arch::ReservedNamedBarriers::EpilogueBarrier);

  // barrier initialization needs to be visible to all warps
  // defer it as late as possible to allow some thread divergence in prolog
  cutlass::arch::fence_barrier_init();
#if 0
  // this will have a membar.gpu to ensure dsmem write visibility within the entire cluster, because there isn't a membar.cluster
  // membar.gpu is 0.2us
  cluster_sync();
#else
  // the alternative is to use proper fences
  // at the ptx level, fence.mbarrier_init.release.cluster act as a release fence (in cluster scope) for mbarrier init op
  cutlass::arch::fence_barrier_init();
  // thread 0 waits for its previously issued cp.async to complete
  // here we overlap the cp.async with the barrier initialization as much as possible
  if (threadIdx.x == 0) {
    cp_async_fence();
    cp_async_wait<0>();
  }

  // the cluster sync serves two purposes:
  // 1. it waits for all threads in the cluster to see the barrier initialization
  // 2. it waits for all threads in the cta to see the cp.async result in smem
  cluster_arrive_relaxed();
  cluster_wait();
#endif

  // bid.y includes rasterization of qHLocal and qL
  int qHLocal = shape<0>(shape<0>(mQ));
  int num_qHLocal = cutlass::ceil_div(qHLocal, CTA_qHLocal);
  // bid.z is the split id for kvL split, try to evenly distribute the kvL blocks to every CTA
  int rank = blockIdx.z;
  int seq_len = shared_storage.seq_len;
  // Sliding window optimization: when enabled, we only process tokens in range
  // [seq_len - sliding_window_size, seq_len). To simplify tile distribution,
  // we align the skip boundary to CTA_kvL tiles.
  int workload_seq_len = seq_len;
  int seq_len_skip_offset = 0;
  if (sliding_window_size > 0 && sliding_window_size < seq_len) {
    int unaligned_skip = seq_len - sliding_window_size;
    seq_len_skip_offset = (unaligned_skip / CTA_kvL) * CTA_kvL;
    workload_seq_len = seq_len - seq_len_skip_offset;
  }
  int NumKVTiles = cutlass::ceil_div(workload_seq_len, CTA_kvL);
  int NumSplits = cute::min(MaxSplits, NumKVTiles);
  int kvL_tile_count_per_cta = NumKVTiles / MaxSplits;
  int kvL_tile_count_remainder = NumKVTiles % MaxSplits;
  int kvL_tile_count = kvL_tile_count_per_cta + (rank < kvL_tile_count_remainder ? 1 : 0);
  int kvL_tile_count_skip_offset = seq_len_skip_offset / CTA_kvL;
  int kvL_tile_count_start = rank * kvL_tile_count_per_cta + (rank < kvL_tile_count_remainder ? rank : kvL_tile_count_remainder) + kvL_tile_count_skip_offset;
  int kvL_tile_count_end = kvL_tile_count_start + kvL_tile_count;
  WorkTileInfo work_tile_info {
    .BS_idx = (int32_t)BS_idx,
    .kvH_idx = (int32_t)(blockIdx.x % kvH),
    .kvL_idx_start = (int32_t)kvL_tile_count_start,
    .kvL_idx_end = (int32_t)kvL_tile_count_end,
    .dH_idx = 0, // no dH tiling for bmm2
    .qHLocal_idx = (int32_t)(blockIdx.y % num_qHLocal),
    .qL_idx = (int32_t)(blockIdx.y / num_qHLocal),
    .is_valid_tile = (kvL_tile_count > 0)
  };

  if (warp_idx == 0) {
    gqa::DMA_Q_warp<SharedStorage, WorkTileInfo, decltype(mQ), TmaAtomQ, TiledBMM1, CTA_qHLocal, CTA_qL, CTA_dH>(shared_storage, work_tile_info, mQ, &tma_atom_Q, tiled_bmm1);
  }
  else if (warp_idx == 1) {
    DMA_KV_warp<SharedStorage, WorkTileInfo, decltype(mK), decltype(mV), decltype(mPageTable), TmaAtomK, TmaAtomV, CTA_kvL, CTA_dH, Page_Size, Page_Idx_Stage, Num_Page_Idx_Per_Stage>(shared_storage, work_tile_info, mK, mV, mPageTable, &tma_atom_K, &tma_atom_V);
  }
  else if (warp_idx == 2) {
    gqa::MMA_warp<SharedStorage, WorkTileInfo, decltype(mO), TiledBMM1, TiledBMM2, CTA_qHLocal, CTA_qL, CTA_kvL, CTA_dH>(shared_storage, work_tile_info, mO, tiled_bmm1, tiled_bmm2);
  }
  // warp_idx == 3 is unused (the previous Read_Page_Idx warp was folded into DMA_KV).
  else if (warp_idx >= 4) {
    // epilog tid is from 128 to 255, need to offset by -128 when getting the per thread slice
    int tid = threadIdx.x - 128;
    // EPILOG_warp only uses mK for shape(mK) (to build a kvL coord predicate). mK on the paged kernel has shape
    // (Page_Size, CTA_dH, Num_Page_Global, kvH) with BS folded into Num_Page_Global, so we build a coord-only
    // identity tensor with the original (kvL, dH, kvH, BS) shape. BS comes straight from mO (rank 4, mode 3).
    // kvL is recovered from mPageTable shape (kvL/Page_Size, BS); Page_Size is a compile-time constant so this
    // is a constant multiply (no integer divide), unlike deriving from shape<2>(mK)/BS which costs ~3%.
    int dH = shape<1>(mK);
    int BS = shape<3>(mO);
    int kvL = static_cast<int>(shape<0>(mPageTable)) * Page_Size;
    auto mK_coord = make_identity_tensor(make_shape(kvL, dH, kvH, BS));
    // warp_idx - 4 because epilog warp group starts from warp 4
    gqa::EPILOG_warp<SharedStorage, WorkTileInfo, decltype(mK_coord), decltype(mO), decltype(mSink), TiledBMM1, TiledBMM2, CTA_qHLocal, CTA_qL, CTA_kvL, CTA_dH, NumReductionCTA, NoSink>(shared_storage, work_tile_info, mK_coord, mO, mSink, seq_len, tiled_bmm1, tiled_bmm2, softmax_scale_log2, sliding_window_size, epilog_barrier, NumSplits, tid, warp_idx - 4, rank);
  }

  __syncthreads();
}

// KV has shape (num_pages_total, 2, Page_Size, kvH, dH); KV(_,0,...) is K, KV(_,1,...) is V; BS is folded into num_pages_total
// Q has shape ((qHLocal, qL), dH, kvH, BS)
// O has shape (dH, (qHLocal, qL), kvH, BS)
// sinks has shape (qHLocal * kvH), i.e. one sink per q head, when device_ptr_sinks is nullptr, it's disabled
// seq_lens has shape (BS); kvL is max_seq_len, seq_lens[bs] is the actual seq len for batch bs
// page_table has shape (kvL/Page_Size, BS)
// sliding_window_size is the size of the sliding window, when it's 0, it's disabled
template<
  class TypeQKV, class TypeO, class TypeAcc,
  int CTA_qHLocal, int CTA_qL, int CTA_kvL, int CTA_dH,
  int Page_Size,
  int BMM1_DMA_Stage, int BMM2_DMA_Stage,
  int Page_Idx_Stage, int Num_Page_Idx_Per_Stage,
  int MaxSplits, int NumReductionCTA>
void gqa_paged_host(
  TypeQKV* device_ptr_KV,
  TypeQKV* device_ptr_Q,
  TypeO* device_ptr_O,
  TypeAcc* device_ptr_sinks,
  int* seq_lens,
  int* device_ptr_page_table,        // (kvL/Page_Size, BS); underlying allocation must be tail-padded by Num_Page_Idx_Per_Stage ints
  int kvH, int qHLocal, int qL, int kvL, int dH, int BS,
  int stride_KV_pages, int stride_KV_KV, int stride_KV_ps, int stride_KV_kvH, int stride_KV_dH,
  int stride_Q_kvH, int stride_Q_qHLocal, int stride_Q_qL, int stride_Q_dH, int stride_Q_BS,
  int stride_O_kvH, int stride_O_qHLocal, int stride_O_qL, int stride_O_dH, int stride_O_BS,
  int stride_PT_p, int stride_PT_BS,
  float softmax_scale,
  int sliding_window_size,
  bool pdl, int pdl_count = -1,
  cudaStream_t stream = 0
) {
  assert(kvL % Page_Size == 0);
  int num_pages_total = BS * (kvL / Page_Size);

  // Reconstruct the combined KV gmem tensor exactly as the harness laid it out: shape
  // (num_pages_total, 2, Page_Size, kvH, dH) with the 5 strides supplied by the caller.
  auto layout_KV = make_layout(
      make_shape(num_pages_total, Int<2>{}, Int<Page_Size>{}, kvH, dH),
      make_stride(stride_KV_pages, stride_KV_KV, stride_KV_ps, stride_KV_kvH, stride_KV_dH));
  Tensor mKV = make_tensor(make_gmem_ptr(device_ptr_KV), layout_KV); // (num_pages_total, 2, Page_Size, kvH, dH)

  // Slice on the K/V mode (=1). Each slice has shape (num_pages_total, Page_Size, kvH, dH); the kernel expects the
  // modes in MMA order, so we permute via select<...>: K wants (Page_Size, dH, num_pages_total, kvH) -> indices
  // (1,3,0,2); V wants (dH, Page_Size, num_pages_total, kvH) -> indices (3,1,0,2).
  Tensor mKV_K = mKV(_, 0, _, _, _);
  Tensor mKV_V = mKV(_, 1, _, _, _);
  Tensor mK = make_tensor(mKV_K.data(), select<1, 3, 0, 2>(mKV_K.layout())); // (Page_Size, dH, num_pages_total, kvH)
  Tensor mV = make_tensor(mKV_V.data(), select<3, 1, 0, 2>(mKV_V.layout())); // (dH, Page_Size, num_pages_total, kvH)

  Layout layout_Q = gqa::make_layout_Q(kvH, qHLocal, qL, dH, BS, stride_Q_kvH, stride_Q_qHLocal, stride_Q_qL, stride_Q_dH, stride_Q_BS);
  Layout layout_O = gqa::make_layout_O(kvH, qHLocal, qL, dH, BS, stride_O_kvH, stride_O_qHLocal, stride_O_qL, stride_O_dH, stride_O_BS);
  Layout layout_sinks = gqa::make_layout_sinks(qHLocal, qL, kvH);

  // Page table tensor as the harness owns it: rank-2 shape (kvL/Page_Size, BS), strides supplied by the caller.
  // DMA_KV warp on the device side partitions mode-0 via logical_divide(_, Shape<NumPagePerCTATile>) into
  // ((NumPagePerCTATile, MaxNumKVTiles), BS) -- the (page-within-CTA-tile, CTA-tile-idx, batch) view it actually
  // indexes. Keeping the gmem-side layout flat per batch lets the harness pass any contiguous or page-strided table.
  // (DMA_KV uses 4-byte cp.async, so no cp.async.bulk-style 16B alignment requirements on bytes/base/stride.)
  auto layout_PageTable = make_layout(
      make_shape(kvL / Page_Size, BS),
      make_stride(stride_PT_p, stride_PT_BS));
  Tensor mPageTable = make_tensor(make_gmem_ptr(device_ptr_page_table), layout_PageTable); // (kvL/Page_Size, BS)

  // how we handle oob:
  //   oob for K, Q, V are handled by TMA
  //   oob for O is explicitly handled by predicate in the epilog since it uses simple st.global epilog
  // we partition kvL with tile size of CTA_kvL, and we evenly distribute the kvL blocks to MaxSplits number of cta in the cluster
  assert(NumReductionCTA <= MaxSplits);
  static_assert(((CTA_qHLocal * CTA_qL) % NumReductionCTA) == 0, "each reduction cta must have even number of q tokens");

  // mK and mV are constructed above by slicing+permuting the combined mKV tensor.
  Tensor mQ = make_tensor(make_gmem_ptr(device_ptr_Q), layout_Q); // ((qHLocal, qL), dH, kvH, BS)
  Tensor mO = make_tensor(make_gmem_ptr(device_ptr_O), layout_O); // (dH, (qHLocal, qL), kvH, BS)
  Tensor mSink = make_tensor(make_gmem_ptr(device_ptr_sinks), layout_sinks); // ((qHLocal, qL), kvH)
  Tensor mSeqLens = make_tensor(make_gmem_ptr(seq_lens), make_layout(make_shape(BS))); // (BS)

  static_assert(CTA_kvL == 128, "BMM1's MMA_M needs to be 128 for tcgen05.ld->softmax");
  static_assert(((CTA_qHLocal * CTA_qL) % 8) == 0, "BMM1's MMA_N needs to be divisible by 8 for tcgen05.mma");
  assert(dH == CTA_dH); // bmm1 only has 1 kblock (i.e. 1 Q tile), bmm2 deal with all dH for now, in the foreseable future this is the hardest constraint to lift
  static_assert((CTA_dH == 128) || (CTA_dH == 64), "BMM2's MMA_M needs to be at either 128 or 64 for tcgen05.ld->correction");
  // we swap AB so bmm1 is K (CTA_kvL, CTA_dH) x Q (CTA_dH, CTA_qHLocal * CTA_qL)
  // both Q and K are dH (K in gemm terminology) major
  // M = CTA_kvL, N = CTA_qHLocal * CTA_qL, K = CTA_dH
  TiledMMA tiled_bmm1 = cutlass::gemm::collective::detail::sm100_make_1sm_trivial_tiled_mma<
                          TypeQKV, TypeQKV, TypeAcc,                                        // Mma's A, B, and Accumulator types
                          Shape<Int<CTA_kvL>, Int<CTA_qHLocal * CTA_qL>, Int<CTA_dH>>,      // TileShape_MNK
                          Shape<_1, _1, _1>,                                                // ClusterShape_MNK
                          cute::UMMA::Major::K, cute::UMMA::Major::K>();

  // we swap AB for bmm2 as well, V (dH, CTA_kvL) x P (CTA_kvL, CTA_qHLocal * CTA_qL)
  // V is dH (M in gemm terminology) major, P is CTA_kvL (K in gemm terminology) major in smem after each thread writes P from rmem to smem
  // M = CTA_dH, N = CTA_qHLocal * CTA_qL, K = CTA_kvL
  TiledMMA tiled_bmm2 = cutlass::gemm::collective::detail::sm100_make_1sm_trivial_tiled_mma<
                          TypeQKV, TypeQKV, TypeAcc,                                        // Mma's A, B, and Accumulator types
                          Shape<Int<CTA_dH>, Int<CTA_qHLocal * CTA_qL>, Int<CTA_kvL>>,      // TileShape_MNK
                          Shape<_1, _1, _1>,                                                // ClusterShape_MNK
                          cute::UMMA::Major::MN, cute::UMMA::Major::K>();

  // Pre-partitioned smem Tile Shape to post-partitioned smem tile shape ((Mma_M, Mma_K), NumMma_M, NumMma_K, DMA_Stage)
  auto shape_K = make_shape(Int<CTA_kvL>{}, Int<CTA_dH>{}, Int<BMM1_DMA_Stage>{});
  auto shape_Q = make_shape(make_shape(Int<CTA_qHLocal>{}, Int<CTA_qL>{}), Int<CTA_dH>{}, Int<1>{});
  auto shape_S = make_shape(Int<CTA_kvL>{}, make_shape(Int<CTA_qHLocal>{}, Int<CTA_qL>{}), Int<1>{});
  auto mma_shape_K = partition_shape_A(tiled_bmm1, shape_K);
  auto mma_shape_Q = partition_shape_B(tiled_bmm1, shape_Q);

  auto shape_V = make_shape(Int<CTA_dH>{}, Int<CTA_kvL>{}, Int<BMM2_DMA_Stage>{});
  auto shape_P = select<1, 0, 2>(shape_S); // just a permutation of shape_S
  auto mma_shape_V = partition_shape_A(tiled_bmm2, shape_V);

  // choose the swizzle atom for K, Q, S, V and P
  auto SmemLayoutAtomK = cutlass::gemm::collective::detail::sm100_smem_selector<
                            cute::UMMA::Major::K,                     // gmem layout of K
                            TypeQKV,                                  // data type of K
                            decltype(shape<0>(shape_K)), decltype(shape<1>(shape_K))>();  // tile size of K
  auto SmemLayoutAtomQ = cutlass::gemm::collective::detail::sm100_smem_selector<
                            cute::UMMA::Major::K,                     // gmem layout of Q
                            TypeQKV,                                  // data type of Q
                            decltype(shape<0>(shape_Q)), decltype(shape<1>(shape_Q))>();  // tile size of Q
  // for bmm1 tcgen05.ld, each register is holding a row of S (CTA_kvL is mapped to the thread dimension), if we do
  // st.shared from rmem to smem, to avoid bank conflict, we need to put T0V0, T1V0, T2V0, ... T31V0 contiguously in smem.
  // then the smem layout of S is M (CTA_kvL) major, so we choose MN major swizzle atom
  auto SmemLayoutAtomS = UMMA::Layout_MN_SW128_Atom<TypeQKV>{};

  auto SmemLayoutAtomV = cutlass::gemm::collective::detail::sm100_smem_selector<
                            cute::UMMA::Major::MN,                    // gmem layout of V
                            TypeQKV,                                  // data type of V
                            decltype(shape<0>(shape_V)), decltype(shape<1>(shape_V))>();  // tile size of V
  // swizzle atom for P should be the transpose of the swizzle atom for S, because they literally represent the same tensor just with different dimension order (aka a pytorch transpose)
  auto SmemLayoutAtomP = UMMA::Layout_K_SW128_Atom<TypeQKV>{};

  // finally construct the smem layout for tile K, Q, V, S, and P
  auto sK_layout = UMMA::tile_to_mma_shape(SmemLayoutAtomK, mma_shape_K); // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
  // paged K smem layout: same memory as sK_layout, viewed as (Page_Size, CTA_dH, NumPagePerCTATile, BMM1_DMA_Stage).
  // tile_to_shape uses Step<_1, _3, _2, _4> to stack SmemLayoutAtomK the same way as sK_layout,
  // i.e. first along CTA_kvL/(Page_Size, NumPagePerCTATile), then along CTA_dH, finally along BMM1_DMA_Stage
  static_assert(CTA_kvL % Page_Size == 0, "Page_Size must divide CTA_kvL");
  constexpr int NumPagePerCTATile = CTA_kvL / Page_Size;
  auto sK_paged_layout = tile_to_shape(SmemLayoutAtomK,
                                       make_shape(Int<Page_Size>{}, Int<CTA_dH>{}, Int<NumPagePerCTATile>{}, Int<BMM1_DMA_Stage>{}),
                                       Step<_1, _3, _2, _4>{});

  auto sQ_layout = UMMA::tile_to_mma_shape(SmemLayoutAtomQ, mma_shape_Q); // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
  auto sV_layout = UMMA::tile_to_mma_shape(SmemLayoutAtomV, mma_shape_V); // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
  // paged V smem layout: same memory as sV_layout, viewed as (CTA_dH, Page_Size, NumPagePerCTATile, BMM2_DMA_Stage).
  // V is MN-major: atom is (atom_M=CTA_dH, atom_K) -> stacking inside the atom covers all of CTA_dH; multiple atoms tile
  // along K (kvL). Splitting kvL into Page_Size + NumPage just renames the K-iter modes; default LayoutLeft step works
  // because mode order (M -> K_inner -> K_outer -> Stage) matches the natural sV_layout stride sequence.
  auto sV_paged_layout = tile_to_shape(SmemLayoutAtomV,
                                       make_shape(Int<CTA_dH>{}, Int<Page_Size>{}, Int<NumPagePerCTATile>{}, Int<BMM2_DMA_Stage>{}));

  // The paged and MMA-partitioned views of K/V must alias the same smem buffer -> cosize must match.
  static_assert(cute::cosize_v<decltype(sK_paged_layout)> == cute::cosize_v<decltype(sK_layout)>,
                "sK_paged_layout and sK_layout must alias the same smem buffer (cosize must match)");
  static_assert(cute::cosize_v<decltype(sV_paged_layout)> == cute::cosize_v<decltype(sV_layout)>,
                "sV_paged_layout and sV_layout must alias the same smem buffer (cosize must match)");
  // S and P use tile_to_shape as we do the mma partition in the kernel later
  auto sS_layout = tile_to_shape(SmemLayoutAtomS, shape_S, Step<_1, _2, _3>{}); // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1)
  auto sP_layout = tile_to_shape(SmemLayoutAtomP, shape_P, Step<_2, _1, _3>{}); // ((CTA_qHLocal, CTA_qL), CTA_kvL, 1)
  auto sAcc1_layout = make_layout(shape_S); // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1)
  // for storing fmax and fsum warp reduce partial results
  int constexpr NumEpilogWarps = 4;
  // NumEpilogWarps contiguous because we often ld.shared all NumEpilogWarps from 1/32 threads, this has best vectorization
  auto sWarpReduce_layout = make_layout(make_shape(Int<NumEpilogWarps>{}, make_shape(Int<CTA_qHLocal>{}, Int<CTA_qL>{}))); // (NumEpilogWarps, (CTA_qHLocal, CTA_qL))
  // MaxSplits contiguous because we often ld.shared all MaxSplits from 1/32 threads, this has best vectorization
  auto sMSMailbox_Layout = make_layout(make_shape(Int<MaxSplits>{}, Int<CTA_qHLocal * CTA_qL / NumReductionCTA>{})); // (MaxSplits, CTA_qHLocal * CTA_qL / NumReductionCTA)
  // default layout is CTA_dH contiguous to maximize st.async/ld.shared bw
  auto sAcc2Mailbox_layout = make_layout(make_shape(Int<CTA_dH>{}, Int<CTA_qHLocal * CTA_qL / NumReductionCTA>{}, Int<MaxSplits>{})); // (CTA_dH, CTA_qHLocal * CTA_qL / NumReductionCTA, MaxSplits)
  auto sSinks_layout = make_layout(Int<CTA_qHLocal * CTA_qL / NumReductionCTA>{}); // (CTA_qHLocal * CTA_qL / NumReductionCTA)
  // DMA_KV's page-idx staging buffer. Page_Idx_Stage and Num_Page_Idx_Per_Stage are configured by the host
  // harness (template params). Single static_assert block lives here so warp functions don't repeat them.
  static_assert(Num_Page_Idx_Per_Stage % NumPagePerCTATile == 0,
                "Num_Page_Idx_Per_Stage must be a multiple of CTA_kvL/Page_Size so a DMA stage's pages live in one pi stage");
  // Page_Idx_Stage must be exactly 2: K leads V by 1 tile, so around a pi-stage boundary K reads slot S%2
  // (stage S) while V finishes the last tile of slot (S-1)%2 (stage S-1). =1 would alias these slots; >2
  // wastes smem because at most 2 pi-stage groups are live at once (the one being consumed + the pre-issued).
  static_assert(Page_Idx_Stage == 2, "Page_Idx_Stage must be 2 for the K-leads-V-by-1 page-idx pipeline");
  constexpr int Tiles_Per_Pi_Stage_Host = Num_Page_Idx_Per_Stage / NumPagePerCTATile;
  // DMA_KV's folded page-idx pipeline issues stage S's cp.async at K_t_in_stage==1 of stage S-1, so each
  // pi-stage must hold at least 2 CTA tiles. Choose Num_Page_Idx_Per_Stage >= 2 * NumPagePerCTATile.
  static_assert(Tiles_Per_Pi_Stage_Host >= 2,
                "Tiles_Per_Pi_Stage (= Num_Page_Idx_Per_Stage / NumPagePerCTATile) must be >= 2 for the folded page-idx pipeline");
  // Hierarchical layout ((NumPagePerCTATile, Tiles_Per_Pi_Stage), Page_Idx_Stage), default LayoutLeft so
  // mode 0 is fully contiguous (NumPagePerCTATile innermost). Letting cute carry the (p, t) split keeps the
  // producer's inner write as sPageIdx(make_coord(p, t), stage_idx) without manual i/N + i%N arithmetic, and
  // gives the consumer a contiguous NumPagePerCTATile-int slice via &sPageIdx(make_coord(0, t), stage_idx).
  auto sPageIdx_layout = make_layout(make_shape(make_shape(Int<NumPagePerCTATile>{}, Int<Tiles_Per_Pi_Stage_Host>{}), Int<Page_Idx_Stage>{}));

  // Now we can find the SMEM allocation size
  using SMEMStorage = SharedStorage<TypeQKV, TypeAcc,
                                    decltype(sK_layout), decltype(sK_paged_layout),
                                    decltype(sQ_layout),
                                    decltype(sV_layout), decltype(sV_paged_layout),
                                    decltype(sS_layout), decltype(sP_layout),
                                    decltype(sWarpReduce_layout), decltype(sMSMailbox_Layout), decltype(sAcc1_layout),
                                    decltype(sAcc2Mailbox_layout), decltype(sSinks_layout),
                                    decltype(sPageIdx_layout),
                                    BMM1_DMA_Stage, BMM2_DMA_Stage, Page_Idx_Stage>;

  static_assert(BMM1_DMA_Stage >= BMM2_DMA_Stage, "otherwise you are wasting BMM2 stage because BMM1 TMA issue will block BMM2 TMA due to insufficient BMM1 stages");

  // create TMA descriptors for K, Q, V matrices
  // K TMA box is (Page_Size, CTA_dH) -- one page per TMA copy. The per-page SMEM destination layout points into the
  // same memory as a single page slot inside sK_layout/sK_paged_layout.
  Copy_Atom tma_atom_K = make_tma_atom(
      SM90_TMA_LOAD{},                              // TMA Load Op, sm100 reuses sm90 tma atom
      mK,                                           // Source GMEM tensor
      take<0, 2>(sK_paged_layout),                  // Destination SMEM layout for 1 page = 1 TMA box, (Page_Size, CTA_dH)
      make_shape(Int<Page_Size>{}, Int<CTA_dH>{})   // TMA box shape
  );
  Tensor mK_tma = tma_atom_K.get_tma_tensor(shape(mK));   // (Page_Size, dH, num_pages_total, kvH)

  Copy_Atom tma_atom_Q = make_tma_atom(
      SM90_TMA_LOAD{},                              // TMA Load Op, sm100 reuses sm90 tma atom
      mQ,                                           // Source GMEM tensor
      // sQ_layout(_,_,_,Int<0>{}) doesn't work under some corner cases (composedlayout indexing), so we use
      // the take method which is also correct.
      take<0, 3>(sQ_layout),                        // Destination SMEM layout for 1 DMA_Stage, ((Mma_N, Mma_K), NumMma_N, NumMma_K)
      make_shape(get<0>(shape_Q), get<1>(shape_Q))  // TMA box shape
  );
  Tensor mQ_tma = tma_atom_Q.get_tma_tensor(shape(mQ));   // ((qHLocal, qL), dH, kvH, BS)

  // V TMA box is (CTA_dH, Page_Size) -- one page per TMA copy. Per-page SMEM destination layout points into the
  // same memory as a single page slot inside sV_layout/sV_paged_layout.
  Copy_Atom tma_atom_V = make_tma_atom(
      SM90_TMA_LOAD{},                              // TMA Load Op, sm100 reuses sm90 tma atom
      mV,                                           // Source GMEM tensor
      take<0, 2>(sV_paged_layout),                  // Destination SMEM layout for 1 page = 1 TMA box, (CTA_dH, Page_Size)
      make_shape(Int<CTA_dH>{}, Int<Page_Size>{})   // TMA box shape
  );
  Tensor mV_tma = tma_atom_V.get_tma_tensor(shape(mV));   // (dH, Page_Size, num_pages_total, kvH)

  int smemBytes = sizeof(SMEMStorage);

  // invoke the kernel
  cudaLaunchConfig_t config;
  cudaLaunchAttribute attrs[2];
  // bid.x: kvH * BS, bid.y: qHLocal * qL, bid.z: kvL
  uint32_t Cluster_Size = cute::max(MaxSplits, NumReductionCTA);
  config.gridDim = dim3{
      (uint32_t)kvH * BS,
      (uint32_t)cutlass::ceil_div(qHLocal, CTA_qHLocal) * cutlass::ceil_div(qL, CTA_qL),
      Cluster_Size};
  config.blockDim = 256; // 8 warps
  config.dynamicSmemBytes = smemBytes;
  config.stream = stream;
  attrs[0].id = cudaLaunchAttributeClusterDimension;
  attrs[0].val.clusterDim = {1, 1, Cluster_Size};
  attrs[1].id = cudaLaunchAttributeProgrammaticStreamSerialization;
  attrs[1].val.programmaticStreamSerializationAllowed = 1;
  config.attrs = attrs;
  config.numAttrs = pdl ? 2 : 1;

  if (device_ptr_sinks != nullptr) {
    auto *kernel_instance =
        &gqa_paged_device<SMEMStorage,
                          decltype(mK_tma), decltype(mQ_tma), decltype(mV_tma), decltype(mO), decltype(mSink),
                          decltype(mSeqLens), decltype(mPageTable),
                          decltype(tma_atom_K), decltype(tma_atom_Q), decltype(tma_atom_V),
                          decltype(tiled_bmm1), decltype(tiled_bmm2),
                          TypeAcc,
                          CTA_qHLocal, CTA_qL, CTA_kvL, CTA_dH,
                          Page_Size,
                          BMM1_DMA_Stage, BMM2_DMA_Stage,
                          Page_Idx_Stage, Num_Page_Idx_Per_Stage,
                          MaxSplits, NumReductionCTA,
                          false>;
    gpuErrChk(cudaFuncSetAttribute(*kernel_instance, cudaFuncAttributeMaxDynamicSharedMemorySize, smemBytes));
    // portable max cluster size is 8, but sm100a supports 16, need explicit opt in
    gpuErrChk(cudaFuncSetAttribute(*kernel_instance, cudaFuncAttributeNonPortableClusterSizeAllowed, 1));
    gpuErrChk(cudaLaunchKernelEx(&config, kernel_instance, mK_tma, mQ_tma, mV_tma, mO, mSink,
                                mSeqLens, mPageTable,
                                tma_atom_K, tma_atom_Q, tma_atom_V,
                                tiled_bmm1, tiled_bmm2,
                                softmax_scale * Log2_E, sliding_window_size, pdl_count));
  }
  else {
    auto *kernel_instance =
        &gqa_paged_device<SMEMStorage,
                          decltype(mK_tma), decltype(mQ_tma), decltype(mV_tma), decltype(mO), decltype(mSink),
                          decltype(mSeqLens), decltype(mPageTable),
                          decltype(tma_atom_K), decltype(tma_atom_Q), decltype(tma_atom_V),
                          decltype(tiled_bmm1), decltype(tiled_bmm2),
                          TypeAcc,
                          CTA_qHLocal, CTA_qL, CTA_kvL, CTA_dH,
                          Page_Size,
                          BMM1_DMA_Stage, BMM2_DMA_Stage,
                          Page_Idx_Stage, Num_Page_Idx_Per_Stage,
                          MaxSplits, NumReductionCTA,
                          true>;
    gpuErrChk(cudaFuncSetAttribute(*kernel_instance, cudaFuncAttributeMaxDynamicSharedMemorySize, smemBytes));
    // portable max cluster size is 8, but sm100a supports 16, need explicit opt in
    gpuErrChk(cudaFuncSetAttribute(*kernel_instance, cudaFuncAttributeNonPortableClusterSizeAllowed, 1));
    gpuErrChk(cudaLaunchKernelEx(&config, kernel_instance, mK_tma, mQ_tma, mV_tma, mO, mSink,
                                mSeqLens, mPageTable,
                                tma_atom_K, tma_atom_Q, tma_atom_V,
                                tiled_bmm1, tiled_bmm2,
                                softmax_scale * Log2_E, sliding_window_size, pdl_count));
  }
}

} // namespace gqa_paged
} // namespace TGV
