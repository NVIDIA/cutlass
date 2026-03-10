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

#define gpuErrChk(ans) { gpuAssert2((ans), __FILE__, __LINE__); }
inline void gpuAssert2(cudaError_t code, const char *file, int line, bool abort=true) {
  if (code != cudaSuccess) {
    fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
    if (abort) exit(code);
  }
}

namespace TGV {
namespace gqa {

using namespace cute;

float constexpr Log2_E = static_cast<float>(M_LOG2E);

// K has shape (kvL, dH, kvH, BS)
// Q has shape ((qHLocal, qL), dH, kvH, BS)
// V has shape (dH, kvL, kvH, BS)
// O has shape (dH, (qHLocal, qL), kvH, BS)

// flash decode triton code
/*
# bmm1
q = tl.load(q_ptrs) # [BLOCK_qL, BLOCK_dH]
k = tl.load(k_ptrs) # [BLOCK_kvL, BLOCK_dH]
qk = tl.dot(q, k.T) * sm_scale # [BLOCK_qL, BLOCK_kvL]

# softmax(qk), all the variable names are from FA paper
m_ij = tl.max(qk, axis=1) # [BLOCK_qL,]
p = tl.exp(qk - m_ij[:, None]) # [BLOCK_qL, BLOCK_kvL]
# l_ij = exp(qk_n0+1 - m_ij) + ... + exp(qk_n1 - m_ij)
l_ij = tl.sum(p, axis=1) # [BLOCK_qL,]

# store m_ij and l_ij
tl.store(mij_ptrs, m_ij)
tl.store(lij_ptrs, l_ij)

# bmm2
v = tl.load(v_ptrs) # [BLOCK_kvL, BLOCK_dH]
acc = tl.dot(p.to(q.dtype), v) # [BLOCK_qL, BLOCK_dH]
tl.store(acc_ptrs, acc)
*/

// Store value to remote shared memory in the cluster
CUTE_DEVICE void
store_shared_remote_f32(float value, uint32_t dsmem_addr, uint32_t remote_barrier_addr) {
  asm volatile("st.async.shared::cluster.mbarrier::complete_tx::bytes.f32 [%0], %1, [%2];"
               : : "r"(dsmem_addr), "f"(value), "r"(remote_barrier_addr));
}

// given a smem tensor, return the dsmem tensor for the given rank, the tensor addr is in smem addr space (not generic addr space)
template <class Tensor>
CUTE_DEVICE auto 
get_dsmem_tensor(Tensor tensor, int rank) {
  using T = typename decltype(tensor)::value_type;
  // tensor.data().get() is the smem addr in the generic addr space, in the generic addr space a region is reserved for smem
  // doing ld/st to this region of the generic addr space will be converted into ld.shared/st.shared to the smem addr space by the compiler
  // the mapa (and many inline ptx) instruction's input and output addr are in the smem/dsmem addr space, so we need to explicitly convert from generic to shared addr space
  uint32_t smem_addr = __cvta_generic_to_shared(tensor.data().get()); // smem addr space
  // mapa to get the dsmem addr of this tensor in another CTA
  uint32_t dsmem_addr = set_block_rank(smem_addr, rank); // smem addr space
  return make_tensor(make_smem_ptr((T*)dsmem_addr), tensor.layout());
}

// Helper methods to create layouts
// K always has the shape (kvL, dH, kvH, BS)
// kvH has to be the last dim because we do mma partitioning to the first two dims (M, K) in gemm terminology
// we only index into kvH after cta level partitioning
// it can has arbitrary stride as long as dH (K in gemm terminology) is contiguous
auto make_layout_K(
  int kvH, int kvL, int dH, int BS,
  int stride_kvH, int stride_kvL, int stride_dH, int stride_BS
) {
  assert(stride_dH == 1);
  return make_layout(make_shape(kvL, dH, kvH, BS), make_stride(stride_kvL, Int<1>{}, stride_kvH, stride_BS));
}

// Q always has the shape ((qHLocal, qL), dH, kvH, BS), qH = kvH * qHLocal
// kvH has to be the last dim because we do mma partitioning to the first two dims (N, K) in gemm terminology
// we only index into kvH after cta level partitioning
// it can has arbitrary stride as long as dH (K in gemm terminology) is contiguous
auto make_layout_Q(
  int kvH, int qHLocal, int qL, int dH, int BS,
  int stride_kvH, int stride_qHLocal, int stride_qL, int stride_dH, int stride_BS
) {
  assert(stride_dH == 1);
  return make_layout(make_shape(make_shape(qHLocal, qL), dH, kvH, BS), make_stride(make_stride(stride_qHLocal, stride_qL), Int<1>{}, stride_kvH, stride_BS));
}

// V always has the shape (dH, kvL, kvH, BS)
// kvH has to be the last dim because we do mma partitioning to the first two dims (M, K) in gemm terminology
// we only index into kvH after cta level partitioning
// it can has arbitrary stride as long as dH (M in gemm terminology) is contiguous
auto make_layout_V(
  int kvH, int kvL, int dH, int BS,
  int stride_kvH, int stride_kvL, int stride_dH, int stride_BS
) {
  assert(stride_dH == 1);
  return make_layout(make_shape(dH, kvL, kvH, BS), make_stride(stride_dH, stride_kvL, stride_kvH, stride_BS));
}

// O always has the shape (dH, (qHLocal, qL), kvH, BS), qH = kvH * qHLocal
// kvH has to be the last dim because we do mma partitioning to the first two dims (M, N) in gemm terminology
// we only index into kvH after cta level partitioning
// it can has arbitrary stride as long as dH (M in gemm terminology) is contiguous
auto make_layout_O(
  int kvH, int qHLocal, int qL, int dH, int BS,
  int stride_kvH, int stride_qHLocal, int stride_qL, int stride_dH, int stride_BS
) {
  assert(stride_dH == 1);
  return make_layout(make_shape(dH, make_shape(qHLocal, qL), kvH, BS), make_stride(stride_dH, make_stride(stride_qHLocal, stride_qL), stride_kvH, stride_BS));
}

// sinks always has the shape ((qHLocal, qL), kvH)
// the real shape is (qHLocal * kvH), but we give qL stride 0 to make CTA indexing cleaner
// so different qL maps to the same sink value
auto make_layout_sinks(
  int qHLocal, int qL, int kvH
) {
  return make_layout(make_shape(make_shape(qHLocal, qL), kvH), make_stride(make_stride(Int<1>{}, Int<0>{}), qHLocal));
}

// simplified from cutlass/include/cutlass/gemm/kernel/static_tile_scheduler.hpp
// allow for easy extention to other types of tile scheduler
struct WorkTileInfo {
  int BS_idx = 0;
  int kvH_idx = 0;
  // each cta process kv block range [kvL_idx_start, kvL_idx_end)
  int kvL_idx_start = 0;
  int kvL_idx_end = 0;
  int dH_idx = 0; // for bmm2 tiling
  int qHLocal_idx = 0;
  int qL_idx = 0;
  bool is_valid_tile = false;

  CUTLASS_HOST_DEVICE bool
  is_valid() const {
    return is_valid_tile;
  }

  CUTLASS_HOST_DEVICE
  static WorkTileInfo
  invalid_work_tile() {
    return {-1, -1, -1, -1, -1, -1, -1, false};
  }
};

// The shared memory buffers for Q, K, V matrices.
template <
  class TypeQKV,         // Tensor Q/K/V data type
  class TypeAcc,         // Tensor Acc data type
  class KSmemLayout,     // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
  class QSmemLayout,     // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
  class VSmemLayout,     // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
  class SSmemLayout,     // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1) aka C matrix (M, N, 1) for bmm1
  class PSmemLayout,     // ((CTA_qHLocal, CTA_qL), CTA_kvL, 1) aka B matrix (N, K, 1) for bmm2
  class WRSmemLayout,    // (NumEpilogWarps, (CTA_qHLocal, CTA_qL)), WR stands for warp reduce
  class MSMailboxSmemLayout,// (MaxSplits, CTA_qHLocal * CTA_qL / NumReductionCTA), MS stands max and sum
  class Acc1SmemLayout,  // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1)
  class Acc2MailboxSmemLayout, // (CTA_dH, CTA_qHLocal * CTA_qL / NumReductionCTA, MaxSplits)
  class SinksSmemLayout, // (CTA_qHLocal * CTA_qL / NumReductionCTA)
  int BMM1_DMA_Stage,
  int BMM2_DMA_Stage>
struct SharedStorage {
  // for bmm1
  alignas(128) cute::ArrayEngine<TypeQKV, cute::cosize_v<KSmemLayout>> K; // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
  alignas(128) cute::ArrayEngine<TypeQKV, cute::cosize_v<QSmemLayout>> Q; // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
  // for bmm2
  alignas(128) cute::ArrayEngine<TypeQKV, cute::cosize_v<VSmemLayout>> V; // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
  alignas(128) cute::ArrayEngine<TypeQKV, cute::cosize_v<PSmemLayout>> P; // ((CTA_qHLocal, CTA_qL), CTA_kvL, 1)
  // for softmax to get CTA wide max and sum
  alignas(128) cute::ArrayEngine<TypeAcc, cute::cosize_v<WRSmemLayout>> FmaxPartial; // (NumEpilogWarps, (CTA_qHLocal, CTA_qL))
  // for softmax to get cluster wide max and sum
  alignas(128) cute::ArrayEngine<TypeAcc, cute::cosize_v<MSMailboxSmemLayout>> FmaxMailbox;    // (MaxSplits, CTA_qHLocal * CTA_qL / NumReductionCTA)
  alignas(128) cute::ArrayEngine<TypeAcc, cute::cosize_v<MSMailboxSmemLayout>> FsumMailbox;    // (MaxSplits, CTA_qHLocal * CTA_qL / NumReductionCTA)
  // staging bufferfor making acc1 rmem layout easier for softmax reduction
  alignas(128) cute::ArrayEngine<TypeAcc, cute::cosize_v<Acc1SmemLayout>> Acc1; // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1)
  // for final flash decode reduction
  alignas(128) cute::ArrayEngine<TypeAcc, cute::cosize_v<Acc2MailboxSmemLayout>> Acc2Mailbox; // (CTA_dH, CTA_qHLocal * CTA_qL / NumReductionCTA, MaxSplits)
  // for attention sinks
  alignas(128) cute::ArrayEngine<TypeAcc, cute::cosize_v<SinksSmemLayout>> Sink; // (CTA_qHLocal * CTA_qL / NumReductionCTA)

  // BMM1 iterate over dH (i.e. K dimension)
  alignas(16) cute::uint64_t tma_bmm1_full_barrier[BMM1_DMA_Stage];      // Barrier between TMA/softmax and BMM1, TMA/softmax tells BMM1 the tile is ready/full, BMM1 can start consuming it
  alignas(16) cute::uint64_t tma_bmm1_empty_barrier[BMM1_DMA_Stage];     // Barrier between BMM1 and TMA, BMM1 tells TMA the tile is empty, TMA can start loading the next tile

  // BMM2 iterate over kvL (i.e. K dimension)
  alignas(16) cute::uint64_t tmasoftmax_bmm2_full_barrier[BMM2_DMA_Stage];  // Barrier between TMA/softmax and BMM2, TMA/softmax tells BMM2 the tile is ready/full, BMM2 can start consuming it
  alignas(16) cute::uint64_t tma_bmm2_empty_barrier[BMM2_DMA_Stage];        // Barrier between BMM2 and TMA, BMM2 tells TMA the tile is empty, TMA can start loading the next tile

  alignas(16) cute::uint64_t bmm1_softmax_full_barrier;      // Barrier between BMM1 and softmax, BMM1 tells softmax the tile is ready/full, softmax can start consuming it
  alignas(16) cute::uint64_t bmm2_epilog_full_barrier;       // Barrier between BMM2 and epilog, BMM2 tells epilog the tile is ready/full, epilog can start consuming it

  // for cluster reduction
  alignas(16) cute::uint64_t maxsum_mailbox_full_barrier;  // barrier indicating the st.async of fmax and fsum are done
  alignas(16) cute::uint64_t acc2_mailbox_full_barrier;  // barrier indicating the st.async of acc2 are done

  alignas(16) cute::uint32_t bmm1_tmem_base_ptr; // Base pointer for TMEM allocation, BMM1 MMA will allocate TMEM here
  alignas(16) cute::uint32_t bmm2_tmem_base_ptr; // Base pointer for TMEM allocation, BMM2 MMA will allocate TMEM here

  // for cp.async to write to
  int seq_len;

  CUTE_DEVICE constexpr auto tensor_sK() { return make_tensor(make_smem_ptr(K.begin()), KSmemLayout{}); }
  CUTE_DEVICE constexpr auto tensor_sQ() { return make_tensor(make_smem_ptr(Q.begin()), QSmemLayout{}); }
  CUTE_DEVICE constexpr auto tensor_sV() { return make_tensor(make_smem_ptr(V.begin()), VSmemLayout{}); }
  // it's the same tensor P, just different views (layouts)
  CUTE_DEVICE constexpr auto tensor_sS() { return make_tensor(make_smem_ptr(P.begin()), SSmemLayout{}); }
  CUTE_DEVICE constexpr auto tensor_sP() { return make_tensor(make_smem_ptr(P.begin()), PSmemLayout{}); }
  CUTE_DEVICE constexpr auto tensor_sFmaxPartial() { return make_tensor(make_smem_ptr(FmaxPartial.begin()), WRSmemLayout{}); }
  CUTE_DEVICE constexpr auto tensor_sAcc1() { return make_tensor(make_smem_ptr(Acc1.begin()), Acc1SmemLayout{}); }

  // mailbox
  CUTE_DEVICE constexpr auto tensor_sFmaxMailbox() { return make_tensor(make_smem_ptr(FmaxMailbox.begin()), MSMailboxSmemLayout{}); }
  CUTE_DEVICE constexpr auto tensor_sFsumMailbox() { return make_tensor(make_smem_ptr(FsumMailbox.begin()), MSMailboxSmemLayout{}); }
  CUTE_DEVICE constexpr auto tensor_sAcc2Mailbox() { return make_tensor(make_smem_ptr(Acc2Mailbox.begin()), Acc2MailboxSmemLayout{}); }
  CUTE_DEVICE constexpr auto tensor_sSink() { return make_tensor(make_smem_ptr(Sink.begin()), SinksSmemLayout{}); }
};

// generic TMA copy device function that works on any tensor for 1 stage
template <
  class GTensor,
  class STensor,
  class TmaAtom,
  char Name,
  bool DummyIter, // if true, don't issue any real tma load, only set barrier tx count to 0, keep the full/empty barrier pipeline running
  bool Print,
  int DMA_Stage>
CUTLASS_DEVICE void 
TMA_copy(
  GTensor gTensor, // ((TMA, NumTma_K), Tiles_K)
  STensor sTensor, // ((TMA, NumTma_K), DMA_Stage or 1)
  int k_tile,
  int k_tile_base, // base index of the kblock that this CTA is going to work on
  int& tma_mma_empty_barrier_phase_bit,
  int tma_transaction_bytes,
  TmaAtom const* tma_atom,
  cute::uint64_t* tma_mma_full_barrier,
  cute::uint64_t* tma_mma_empty_barrier
) {

  // a single kblock
  // wait_barrier's input argument is the old phase bit
  // it waits for the smem slot to be empty to start loading the next tile
  wait_barrier(tma_mma_empty_barrier[k_tile % DMA_Stage], tma_mma_empty_barrier_phase_bit);

  if constexpr (Print) {
    if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
      printf("[DMA_%c] barrier empty, kblock %d\n", Name, k_tile);
    }
  }

  if (elect_one_sync()) {
    if constexpr (DummyIter) {
      // set 0 transaction bytes for dummy iteration
      set_barrier_transaction_bytes(tma_mma_full_barrier[k_tile % DMA_Stage], 0);
    } 
    else {
      // set the barrier transaction bytes to the number of bytes to load the tile, has to be done by a single thread
      set_barrier_transaction_bytes(tma_mma_full_barrier[k_tile % DMA_Stage], tma_transaction_bytes);
      // load Q tile into smem ((CTA_qHLocal, CTA_qL), CTA_dH)
      copy(tma_atom->with(tma_mma_full_barrier[k_tile % DMA_Stage]), gTensor(_, k_tile_base + k_tile), sTensor(_,k_tile % DMA_Stage));
    }
  }

  if ((k_tile % DMA_Stage) == (DMA_Stage - 1)) {
    tma_mma_empty_barrier_phase_bit ^= 1;
  }
}

// generic MMA device function that works on any tensor for 1 stage
template <
  class ATensor,
  class BTensor,
  class CTensor,
  class TiledMMA,
  char Name,
  bool Print>
CUTLASS_DEVICE void 
MMA_gemm(
  ATensor tCrA, // ((Mma_M, Mma_K), NumMma_M, NumMma_K, DMA_Stage)
  BTensor tCrB, // ((Mma_N, Mma_K), NumMma_N, NumMma_K, DMA_Stage)
  CTensor tCtAcc, // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
  TiledMMA tiled_mma,
  int& stage_idx,
  int& tma_mma_full_barrier_phase_bit,
  UMMA::ScaleOut initial_accumulate,
  cute::uint64_t* tma_mma_full_barrier,
  cute::uint64_t* tma_mma_empty_barrier,
  cute::uint64_t& mma_epilog_full_barrier
) {
  int constexpr DMA_Stage = size<3>(tCrA);

  // setting it to 0 will clear the TMEM accumulator, setting it to one will reuse existing accumulator
  tiled_mma.accumulate_ = initial_accumulate;

  // a single kblock
  // wait for tma_mma_full_barrier to be full
  wait_barrier(tma_mma_full_barrier[stage_idx], tma_mma_full_barrier_phase_bit);

  if constexpr (Print) {
    if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
      printf("[MMA_%c] barrier full, kblock stage %d\n", Name, stage_idx);
    }
  }

  for (int k_block = 0; k_block < size<2>(tCrA); ++k_block) {
    // execute a Mma_M x Mma_N x Mma_K GEMM
    // for K * Q and V * P, both the B matrix has a single stage, so we can just use stage_idx = 0 for B
    cute::gemm(tiled_mma, tCrA(_,_,k_block, stage_idx), tCrB(_,_,k_block, 0), tCtAcc);
    // after the first mma instruction, we need to start accumulating the result
    // i.e. basically do C += A * B
    tiled_mma.accumulate_ = UMMA::ScaleOut::One;
  }
  // notify the DMA warp that the all the MMA issued prior to this tcgen05.commit is done, the smem slot is now empty and can be reused
  cutlass::arch::umma_arrive(&tma_mma_empty_barrier[stage_idx]);

  stage_idx++;
  // for every DMA_Stage number of iterations, we flip the phase bit such that we reuse the full barrier for another round of mma
  if (stage_idx == DMA_Stage) {
    tma_mma_full_barrier_phase_bit ^= 1;
    stage_idx = 0;
  }

  // notify the epilog warp that MMA is done, the tmem slot is now full and can be consumed
  cutlass::arch::umma_arrive(&mma_epilog_full_barrier);
}

enum class ReduceOp {
  Sum,
  Max,
  Min
};

// Helper for dependent static_assert in templates
template<auto> inline constexpr bool dependent_false = false;

// https://docs.nvidia.com/cuda/cuda-math-api/cuda_math_api/group__CUDA__MATH__SINGLE.html
template <ReduceOp Op>
CUTLASS_DEVICE float 
reduce_op(float a, float b) {
  if constexpr (Op == ReduceOp::Sum) {
    return a + b;
  } 
  else if constexpr (Op == ReduceOp::Max) {
    return fmaxf(a, b);
  } 
  else if constexpr (Op == ReduceOp::Min) {
    return fminf(a, b);
  } 
  else {
    // gcc 11.2 evaluate static_assert first before instantiating the template
    // so we make the condition template dependent to ensure it is evaluated after if-else branch condition is evaluated
    // gcc 13.2 fixes this issue
    static_assert(dependent_false<Op>, "Invalid reduce op");
    return 0;
  }
}

// generic warp reduce function that works on a single reg value
// according to semantics section of the ptx doc https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-shfl-sync
// shfl.sync waits for all participating threads to reach this point, and then execute the shuffle instruction
// so we don't need to explicitly sync warp beforehand
// only supports full warp now, i.e. all 32 threads are active
template <ReduceOp Op>
CUTLASS_DEVICE float 
warp_reduce(float val) {
  // if it's doing float max or min, using the faster redux.sync instead of warp shuffle
  if constexpr (Op == ReduceOp::Max) {
    float result;
    asm volatile("redux.sync.max.NaN.f32 %0, %1, 0xffffffff;\n" : "=f"(result) : "f"(val));
    return result;
  } 
  else if constexpr (Op == ReduceOp::Min) {
    float result;
    asm volatile("redux.sync.min.NaN.f32 %0, %1, 0xffffffff;\n" : "=f"(result) : "f"(val));
    return result;
  } 
  else {
    float acc = val;
    for (int i = 16; i >= 1; i /= 2) {
      float new_val = __shfl_xor_sync(0xffffffff, acc, i, 32);
      acc = reduce_op<Op>(acc, new_val);
    }
    return acc;
  }
}

// generic cta reduce function that works on a vector of reg values
// this is better than calling the same pattern on each reg value repeatedly because we coalesce the bar.sync before inter warp reduction into a single bar.sync
// the compiler can generate better pipelined code this way
// 1. do a warp reduce (redux.sync or warp shuffle)
// 2. first thread in each warp writes the warp reduce result to smem
// 3. sync across all participating warps/threads using named barrier to ensure smem write visibility
// 4. first thread in each warp reads all the warp reduce result from smem and do a reduction (separately for each warp)
// 5. first thread broadcast the cta reduce result to all threads in the warp
// this should work well when NumWarps is small, if it's big one should use another warp shuffle to do step 3 reduction
template <
  ReduceOp Op, int NumWarps,
  class RmemTensor,
  class OTensor,
  class SmemTensor>
CUTLASS_DEVICE void 
cta_reduce(
  RmemTensor val,  // the value tensor to be reduced, we reduce each element across all participating threads
  OTensor& out,    // the output tensor, same shape as val, each threads hold the entire reduction result for each element
  int warp_idx,    // relative warp id that participate in the reduction, from 0 to NumWarps-1
  SmemTensor smem, // a tensor of shape (NumWarps, size(val)) to store the partial warp reduce result
  cutlass::arch::NamedBarrier& warp_reduce_barrier
) {

  int lane_id = cutlass::canonical_lane_idx();
  for (int i = 0; i < size(val); i++) {
    // step 1: do a warp reduce
    float warp_reduce_result = warp_reduce<Op>(val(i));
    // step 2: first thread in each warp writes the warp reduce result to smem
    if (lane_id == 0) {
      smem(warp_idx, i) = warp_reduce_result;
    }
  }
  // step 3: sync across all participating warps/threads using named barrier
  // according to the ptx page, bar.sync has an implicit fence.cta to ensure smem write visibility
  warp_reduce_barrier.arrive_and_wait();

  // tried smem atomics and it's slower
  for (int i = 0; i < size(val); i++) {
    // step 4: first thread in each warp reads all the warp reduce result from smem and do a reduction (separately for each warp)
    float acc = smem(0, i);
    if (lane_id == 0) {
      for (int j = 1; j < NumWarps; j++) {
        acc = reduce_op<Op>(acc, smem(j, i));
      }
    }
    // step 5: first thread broadcast the cta reduce result to all threads in the warp
    acc = __shfl_sync(0xffffffff, acc, 0, 32);
    out(i) = acc;
  }
}

// this function acts on the transposed tensor of the above cta_reduce function
// what it effectively does is reducing values between all elements in val tensor and across consecutive NumThreads in the warp
template <
  ReduceOp Op,
  int NumThreads, // num consecutive threads to reduce
  class RmemTensor>
CUTLASS_DEVICE float 
cta_reduce_transposed(
  RmemTensor val  // per thread value tensor
) {
  // 1. reduce all elements in val tensor (thread local reduction)
  float acc = val(0);
  for (int i = 1; i < size(val); i++) {
    acc = reduce_op<Op>(acc, val(i));
  }
  // 2. cross NumThreads thread reduce
  for (int i = (NumThreads / 2); i >= 1; i /= 2) {
    float new_val = __shfl_xor_sync(0xffffffff, acc, i, 32);
    acc = reduce_op<Op>(acc, new_val);
  }
  return acc;
}

// copied from SM100::TMEM::LOAD::copy_unpack cutlass/include/cute/atom/copy_traits_sm100.hpp
// what it does is given a tmem address, load the data into rmem tensor with the given tcgen05.ld copy op
template <
  class CopyOp,
  class TD, class DLayout>
CUTLASS_DEVICE void 
tmem_load(
  uint32_t tmem_addr,
  Tensor<TD,DLayout>& dst
) {
  static_assert(is_rmem<TD>::value, "Expected RMEM dst.");

  using RegTypeDst = typename remove_extent<typename CopyOp::DRegisters>::type;
  Tensor rD = recast<RegTypeDst>(dst);

  constexpr int RegNumDst = extent<typename CopyOp::DRegisters>::value;
  CUTE_STATIC_ASSERT_V(size(rD) == Int<RegNumDst>{},
  "The tcgen05.ld CopyOp's size does not match the destination tensor size.");

  detail::explode(CopyOp::copy,
                  &tmem_addr, seq<0>{},
                  rD, make_seq<RegNumDst>{});
}

// copied from SM100::TMEM::STORE::copy_unpack cutlass/include/cute/atom/copy_traits_sm100.hpp
// what it does is given a tmem address, store the data in rmem tensor to the tmem address with the given tcgen05.st copy op
template <
  class CopyOp,
  class TS, class SLayout>
CUTLASS_DEVICE void 
tmem_store(
  Tensor<TS,SLayout>& src,
  uint32_t tmem_addr
) {
  static_assert(is_rmem<TS>::value, "Expected RMEM src.");

  using RegTypeSrc = typename remove_extent<typename CopyOp::SRegisters>::type;
  Tensor rS = recast<RegTypeSrc>(src);

  constexpr int RegNumSrc = extent<typename CopyOp::SRegisters>::value;
  CUTE_STATIC_ASSERT_V(size(rS) == Int<RegNumSrc>{},
      "The tcgen05.st CopyOp's size does not match the source tensor size.");

  detail::explode(CopyOp::copy,
                  rS, make_seq<RegNumSrc>{},
                  &tmem_addr, seq<0>{});
}

// issue cp.async
CUTLASS_DEVICE void 
cp_async(
  int* gmem_addr,
  int* smem_addr
) {
  uint32_t smem_int_ptr = cute::cast_smem_ptr_to_uint(smem_addr);
  asm volatile("cp.async.ca.shared.global.L2::128B [%0], [%1], %2;\n"
      :: "r"(smem_int_ptr),
          "l"(gmem_addr),
          "n"(sizeof(int)));
}

// mapping between thread id (T) -> dH (row index of Acc2)
template <int CTA_dH>
CUTLASS_DEVICE auto 
make_bmm2_tmem_load_t_dH_layout() {
  if constexpr (CTA_dH == 64) {
    return make_layout(make_shape(Int<16>{}, Int<2>{}, Int<4>{}), make_stride(Int<1>{}, Int<0>{}, Int<16>{}));
  } 
  else if constexpr (CTA_dH == 128) {
    return make_layout(Int<128>{});
  } 
  else {
    static_assert(dependent_false<CTA_dH>, "CTA_dH must be 64 or 128");
    return make_layout(Int<128>{});
  }
}

// TMA load Q, guarded by griddepcontrol.wait
template <
  class SharedStorage,
  class WorkTileInfo,
  class QTensor,
  class TmaAtomQ,
  class TiledBMM1,
  int CTA_qHLocal, int CTA_qL, int CTA_dH>
CUTLASS_DEVICE void 
DMA_Q_warp(
  SharedStorage& shared_storage,
  WorkTileInfo work_tile_info,
  QTensor mQ,
  // when passing tma descriptor as function argument, it has to be pass by pointer/reference, if pass by value, it will live on local memory (i.e. the stack)
  // and the tma unit cannot access the local memory, (even if it can, the local memory is strided by thread id, the content for each thread is strided)
  TmaAtomQ const* tma_atom_Q,
  TiledBMM1 tiled_bmm1) {

  if (!work_tile_info.is_valid()) {
    return;
  }

  // tCsQ means the mma partitioned smem tensor sQ
  Tensor tCsQ = shared_storage.tensor_sQ();   // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
  // now let's tile the gmem tensor first into the tile this CTA needs (i.e. CTA-level tiling), which is ((CTA_qHLocal, CTA_qL), CTA_dH, Num_CTA_dH)
  // mQ has shape ((qHLocal, qL), dH, kvH, BS), after local_tile (without indexing), it becomes ((CTA_qHLocal, CTA_qL), CTA_dH, (Num_CTA_qHLocal, Num_CTA_qL), Num_CTA_dH, kvH, BS)
  // there is only one tile on the dH dimension
  Tensor gQ = local_tile(mQ, make_shape(make_shape(Int<CTA_qHLocal>{}, Int<CTA_qL>{}), Int<CTA_dH>{}), 
                          make_coord(make_coord(work_tile_info.qHLocal_idx, work_tile_info.qL_idx), _, work_tile_info.kvH_idx, work_tile_info.BS_idx));  // ((CTA_qHLocal, CTA_qL), CTA_dH, Num_CTA_dH)

  // now we want to partition (give the same tensor a new view) the gmem tensor into the mma shape, to match the smem layout
  ThrMMA cta_bmm1 = tiled_bmm1.get_slice(0);   // 1 sm mma only has 1 thread in tiled_bmm1
  // tCgQ means the mma partitioned gmem tensor gQ
  Tensor tCgQ = cta_bmm1.partition_B(gQ);     // ((Mma_N, Mma_K), NumMma_N, NumMma_K, Tiles_K)

  // now we want to partition (give the same tensor a new view) the gmem tensor into the tma shape in preparation for tma copy
  auto [tBgQ, tBsQ] = tma_partition(*tma_atom_Q,
                                  Int<0>{}, // cta_coord: 1x1 cluster
                                  Layout<_1>{}, // cta_layout: CTA coord -> logical multicast id, no multicast, just identity layout
                                  group_modes<0,3>(tCsQ), group_modes<0,3>(tCgQ));
  // tBgQ: ((TMA, NumTma_N, NumTma_K), Tiles_K) get coalesced to ((TMA, NumTma_K), Tiles_K) since NumTma_N = 1
  // tBsQ: ((TMA, NumTma_N, NumTma_K), 1) get coalesced to ((TMA, NumTma_K), 1) since NumTma_N = 1
  // the shape of the TMA box is (CTA_qHLocal*CTA_qL, CTA_dH)

  /*if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    printf("cta_bmm1:\t"); print(cta_bmm1); print("\n");
    printf("tCsQ:\t"); print(tCsQ); print("\n");  // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
    printf("gQ:\t"); print(gQ); print("\n");      // ((CTA_qHLocal, CTA_qL), CTA_dH, Num_CTA_dH)
    printf("tCgQ:\t"); print(tCgQ); print("\n");  // ((Mma_N, Mma_K), NumMma_N, NumMma_K, Tiles_K)
    printf("tBgQ:\t"); print(tBgQ); print("\n");  // ((TMA, NumTma_K), Tiles_K)
    printf("tBsQ:\t"); print(tBsQ); print("\n");  // ((TMA, NumTma_K), 1)
  }*/

  // only do griddepcontrol.wait on Q loading, Q is dependent on previous kernel
  cutlass::arch::wait_on_dependent_grids();

  int tma_transaction_bytes = sizeof(make_tensor_like(tBsQ(_,0)));
  int k_tile_count = work_tile_info.kvL_idx_end - work_tile_info.kvL_idx_start;

  Tensor tCsK = shared_storage.tensor_sK();   // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
  int constexpr DMA_Stage = size<3>(tCsK);

  /*if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    printf("tBgQ:\t"); print(tBgQ); print("\n");  // ((TMA, NumTma_K), Tiles_K)
    printf("tBsQ:\t"); print(tBsQ); print("\n");  // ((TMA, NumTma_K), 1)
    printf("TmaBytes: %d\n", tma_transaction_bytes);
    printf("k_tile_count: %d\n", k_tile_count);
    printf("DMA_Stage: %d\n", DMA_Stage);
  }*/

  // initial phase bit for tma_mma_empty_barrier is 0, and it denotes smem slot is empty
  // we wait on the "old" phase bit of 1, when it is "flipped" to 0 (the initial phase bit), the smem slot is empty
  // so tma_mma_empty_barrier_phase_bit denotes the phase bit before the flip we are waiting on
  // example for DMA_Stage = 2, i.e. 2 smem slots, 2 empty barriers a and b
  // kblock 0: old phase bit of barrier a is 1, wait for barrier a's phase bit to change to 0 (the initial phase bit), 0 denotes slot a is empty, 1 denotes slot a is used by mma
  // kblock 1: old phase bit of barrier b is 1, wait for barrier b's phase bit to change to 0 (the initial phase bit), 0 denotes slot b is empty, 1 denotes slot b is used by mma
  // kblock 2: old phase bit of barrier a is 0, wait for barrier a's phase bit to change to 1 (flipped once), 1 denotes slot a is empty, 0 denotes slot a is used by mma
  // kblock 3: old phase bit of barrier b is 0, wait for barrier b's phase bit to change to 1 (flipped once), 1 denotes slot b is empty, 0 denotes slot b is used by mma
  // kblock 4: old phase bit of barrier a is 1, wait for barrier a's phase bit to change to 0 (flipped twice), 0 denotes slot a is empty, 1 denotes slot a is used by mma
  // kblock 5: old phase bit of barrier b is 1, wait for barrier b's phase bit to change to 0 (flipped twice), 0 denotes slot b is empty, 1 denotes slot b is used by mma
  // ...
  int tma_mma_empty_barrier_phase_bit = 1;

  // Q0, _, _, ...
  int k_tile = 0;
  // fetch Q0, there is only 1 Q tile
  TMA_copy<decltype(tBgQ), decltype(tBsQ), TmaAtomQ, 'Q', false, false, DMA_Stage>(tBgQ, tBsQ, k_tile, 0, tma_mma_empty_barrier_phase_bit, tma_transaction_bytes, tma_atom_Q, shared_storage.tma_bmm1_full_barrier, shared_storage.tma_bmm1_empty_barrier);
  k_tile++;

  // so the rest of the K tiles all share the same Q tile, so we just do dummy iterations
  for (; k_tile < k_tile_count; k_tile++) {
    TMA_copy<decltype(tBgQ), decltype(tBsQ), TmaAtomQ, 'Q', true, false, DMA_Stage>(tBgQ, tBsQ, k_tile, 0, tma_mma_empty_barrier_phase_bit, tma_transaction_bytes, tma_atom_Q, shared_storage.tma_bmm1_full_barrier, shared_storage.tma_bmm1_empty_barrier);
  }

  /*wait_barrier(shared_storage.tma_bmm1_full_barrier[0], 0);
  if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    printf("tCsQ:\t"); print_tensor(tCsQ(_,0,_,0)); print("\n");
  }*/
}

// TMA load K and then V, not guarded by griddepcontrol.wait
template <
  class SharedStorage,
  class WorkTileInfo,
  class KTensor,
  class VTensor,
  class TmaAtomK,
  class TmaAtomV,
  class TiledBMM1,
  class TiledBMM2,
  int CTA_kvL, int CTA_dH>
CUTLASS_DEVICE void 
DMA_KV_warp(
  SharedStorage& shared_storage,
  WorkTileInfo work_tile_info,
  KTensor mK,
  VTensor mV,
  // when passing tma descriptor as function argument, it has to be pass by pointer/reference, if pass by value, it will live on local memory (i.e. the stack)
  // and the tma unit cannot access the local memory, (even if it can, the local memory is strided by thread id, the content for each thread is strided)
  TmaAtomK const* tma_atom_K,
  TmaAtomV const* tma_atom_V,
  TiledBMM1 tiled_bmm1,
  TiledBMM2 tiled_bmm2) {

  if (!work_tile_info.is_valid()) {
    return;
  }

  // setup code for K tensor
  // tCsK means the mma partitioned smem tensor sK
  Tensor tCsK = shared_storage.tensor_sK();   // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
  // now let's tile the gmem tensor first into the tile this CTA needs (i.e. CTA-level tiling), which is (CTA_kvL, CTA_dH, Num_CTA_kvL)
  // mK has shape (kvL, dH, kvH, BS), after local_tile (without indexing), it becomes (CTA_kvL, CTA_dH, Num_CTA_kvL, Num_CTA_dH, kvH, BS)
  // and this CTA works on gK(_,_,kvL_idx_start:kvL_idx_end)
  Tensor gK = local_tile(mK, make_shape(Int<CTA_kvL>{}, Int<CTA_dH>{}), 
                          make_coord(_, 0, work_tile_info.kvH_idx, work_tile_info.BS_idx));  // (CTA_kvL, CTA_dH, Num_CTA_kvL)

  // now we want to partition (give the same tensor a new view) the gmem tensor into the mma shape, to match the smem layout
  ThrMMA cta_bmm1 = tiled_bmm1.get_slice(0);   // 1 sm mma only has 1 thread in tiled_bmm1
  // tCgK means the mma partitioned gmem tensor gK
  Tensor tCgK = cta_bmm1.partition_A(gK);      // ((Mma_M, Mma_K), NumMma_M, NumMma_K, Tiles_M)

  // now we want to partition (give the same tensor a new view) the gmem tensor into the tma shape in preparation for tma copy
  auto [tAgK, tAsK] = tma_partition(*tma_atom_K,
                                  Int<0>{}, // cta_coord: 1x1 cluster
                                  Layout<_1>{}, // cta_layout: CTA coord -> logical multicast id, no multicast, just identity layout
                                  group_modes<0,3>(tCsK), group_modes<0,3>(tCgK));
  // tAgK: ((TMA, NumTma_M, NumTma_K), Tiles_M) get coalesced to ((TMA, NumTma_K), Tiles_M) since NumTma_M = 1
  // tAsK: ((TMA, NumTma_M, NumTma_K), BMM1_DMA_Stage) get coalesced to ((TMA, NumTma_K), BMM1_DMA_Stage) since NumTma_M = 1
  // the shape of the TMA box is (CTA_kvL, CTA_dH)

  /*if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    printf("cta_bmm1:\t"); print(cta_bmm1); print("\n");
    printf("tCsK:\t"); print(tCsK); print("\n");  // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
    printf("gK:\t"); print(gK); print("\n");      // (CTA_kvL, CTA_dH, Num_CTA_kvL)
    printf("tCgK:\t"); print(tCgK); print("\n");  // ((Mma_M, Mma_K), NumMma_M, NumMma_K, Tiles_M)
    printf("tAgK:\t"); print(tAgK); print("\n");  // ((TMA, NumTma_K), Tiles_M)
    printf("tAsK:\t"); print(tAsK); print("\n");  // ((TMA, NumTma_K), BMM1_DMA_Stage)
  }*/

  // setup code for V tensor
  // tCsV means the mma partitioned smem tensor sV
  Tensor tCsV = shared_storage.tensor_sV();   // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
  // now let's tile the gmem tensor first into the tile this CTA needs (i.e. CTA-level tiling), which is (CTA_dH, CTA_kvL)
  // mV has shape (dH, kvL, kvH, BS), after local_tile (without indexing), it becomes (CTA_dH, CTA_kvL, Num_CTA_dH, Num_CTA_kvL, kvH, BS)
  // and this CTA works on gV(_,_,kvL_idx_start:kvL_idx_end)
  Tensor gV = local_tile(mV, make_shape(Int<CTA_dH>{}, Int<CTA_kvL>{}), 
                          make_coord(work_tile_info.dH_idx, _, work_tile_info.kvH_idx, work_tile_info.BS_idx));  // (CTA_dH, CTA_kvL, Num_CTA_kvL)

  // now we want to partition (give the same tensor a new view) the gmem tensor into the mma shape, to match the smem layout
  ThrMMA cta_bmm2 = tiled_bmm2.get_slice(0);   // 1 sm mma only has 1 thread in tiled_bmm2
  // tCgV means the mma partitioned gmem tensor gV
  Tensor tCgV = cta_bmm2.partition_A(gV);      // ((Mma_M, Mma_K), NumMma_M, NumMma_K, Tiles_K)

  // now we want to partition (give the same tensor a new view) the gmem tensor into the tma shape in preparation for tma copy
  auto [tAgV, tAsV] = tma_partition(*tma_atom_V,
                                  Int<0>{}, // cta_coord: 1x1 cluster
                                  Layout<_1>{}, // cta_layout: CTA coord -> logical multicast id, no multicast, just identity layout
                                  group_modes<0,3>(tCsV), group_modes<0,3>(tCgV));
  // tAgV: ((TMA, NumTma_M, NumTma_K), Tiles_K) get coalesced to ((TMA, NumTma_K), Tiles_K) since NumTma_M = 1
  // tAsV: ((TMA, NumTma_M, NumTma_K), BMM2_DMA_Stage) get coalesced to ((TMA, NumTma_K), BMM2_DMA_Stage) since NumTma_M = 1
  // the shape of the TMA box is (CTA_dH, CTA_kvL)

  /*if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    printf("cta_bmm2:\t"); print(cta_bmm2); print("\n");
    printf("tCsV:\t"); print(tCsV); print("\n");  // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
    printf("gV:\t"); print(gV); print("\n");      // (CTA_dH, CTA_kvL, Num_CTA_kvL)
    printf("tCgV:\t"); print(tCgV); print("\n");  // ((Mma_M, Mma_K), NumMma_M, NumMma_K, Tiles_K)
    printf("tAgV:\t"); print(tAgV); print("\n");  // ((TMA, NumTma_K), Tiles_K)
    printf("tAsV:\t"); print(tAsV); print("\n");  // ((TMA, NumTma_K), BMM2_DMA_Stage)
  }*/

  int tma_K_transaction_bytes = sizeof(make_tensor_like(tAsK(_,0)));
  int tma_V_transaction_bytes = sizeof(make_tensor_like(tAsV(_,0)));
  int k_tile_count = work_tile_info.kvL_idx_end - work_tile_info.kvL_idx_start;
  int constexpr BMM1_DMA_Stage = size<3>(tCsK);
  int constexpr BMM2_DMA_Stage = size<3>(tCsV);

  /*if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    printf("TmaKBytes: %d\n", tma_K_transaction_bytes);
    printf("TmaVBytes: %d\n", tma_V_transaction_bytes);
    printf("k_tile_count: %d\n", k_tile_count);
    printf("BMM1_DMA_Stage: %d\n", BMM1_DMA_Stage);
    printf("BMM2_DMA_Stage: %d\n", BMM2_DMA_Stage);
  }*/

  // details of how the phase bit works is in DMA_Q_warp
  int tma_bmm1_empty_barrier_phase_bit = 1;
  int tma_bmm2_empty_barrier_phase_bit = 1;

  int bmm1_k_tile = 0;
  int bmm2_k_tile = 0;

  bool constexpr Print = false;
  // iterate over kblock
  // SOL order is K0, (K1, V0), (K2, V1), (K3, V2), ...

  // sw pipeline prolog
  TMA_copy<decltype(tAgK), decltype(tAsK), TmaAtomK, 'K', false, Print, BMM1_DMA_Stage>(tAgK, tAsK, bmm1_k_tile, work_tile_info.kvL_idx_start, tma_bmm1_empty_barrier_phase_bit, tma_K_transaction_bytes, tma_atom_K, shared_storage.tma_bmm1_full_barrier, shared_storage.tma_bmm1_empty_barrier);
  bmm1_k_tile++;

  for (; bmm1_k_tile < k_tile_count; bmm1_k_tile++, bmm2_k_tile++) {

    TMA_copy<decltype(tAgK), decltype(tAsK), TmaAtomK, 'K', false, Print, BMM1_DMA_Stage>(tAgK, tAsK, bmm1_k_tile, work_tile_info.kvL_idx_start, tma_bmm1_empty_barrier_phase_bit, tma_K_transaction_bytes, tma_atom_K, shared_storage.tma_bmm1_full_barrier, shared_storage.tma_bmm1_empty_barrier);

    TMA_copy<decltype(tAgV), decltype(tAsV), TmaAtomV, 'V', false, Print, BMM2_DMA_Stage>(tAgV, tAsV, bmm2_k_tile, work_tile_info.kvL_idx_start, tma_bmm2_empty_barrier_phase_bit, tma_V_transaction_bytes, tma_atom_V, shared_storage.tmasoftmax_bmm2_full_barrier, shared_storage.tma_bmm2_empty_barrier);
  }

  // sw pipeline epilog
  TMA_copy<decltype(tAgV), decltype(tAsV), TmaAtomV, 'V', false, Print, BMM2_DMA_Stage>(tAgV, tAsV, bmm2_k_tile, work_tile_info.kvL_idx_start, tma_bmm2_empty_barrier_phase_bit, tma_V_transaction_bytes, tma_atom_V, shared_storage.tmasoftmax_bmm2_full_barrier, shared_storage.tma_bmm2_empty_barrier);

  cutlass::arch::launch_dependent_grids();
}

// MMA warp that includes BMM1 and BMM2
template <
  class SharedStorage,
  class WorkTileInfo,
  class OTensor,
  class TiledBMM1,
  class TiledBMM2,
  int CTA_qHLocal, int CTA_qL, int CTA_kvL, int CTA_dH>
CUTLASS_DEVICE void 
MMA_warp(
  SharedStorage& shared_storage,
  WorkTileInfo work_tile_info,
  OTensor mO,
  TiledBMM1 tiled_bmm1,
  TiledBMM2 tiled_bmm2,
  cutlass::arch::NamedBarrier& tmem_allocation_barrier
) {
  if (!work_tile_info.is_valid()) {
    // we don't allocate tmem for invalid tiles but we still need to relinquish the allocation lock
    using TmemAllocator = cute::TMEM::Allocator1Sm;
    TmemAllocator tmem_allocator{};
    tmem_allocator.release_allocation_lock();
    return;
  }

  // compute BMM1, S = K x Q
  // smem tensor prepared by DMA_K and DMA_Q
  Tensor tCsK = shared_storage.tensor_sK();   // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
  Tensor tCsQ = shared_storage.tensor_sQ();   // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
  Tensor sS = shared_storage.tensor_sS();     // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1)

  // BMM1 Fragment Allocation
  ThrMMA cta_bmm1 = tiled_bmm1.get_slice(0);        // 1 sm mma only has 1 thread in tiled_mma
  Tensor tCrK = cta_bmm1.make_fragment_A(tCsK);     // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
  Tensor tCrQ = cta_bmm1.make_fragment_B(tCsQ);     // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
  // then partition it to mma shape
  Tensor tCsS = cta_bmm1.partition_C(sS(_,_,0));    // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
  Tensor tCtAcc1 = cta_bmm1.make_fragment_C(tCsS);  // ((Mma_M, Mma_N), NumMma_M, NumMma_N)

  // compute BMM2, O = V x P
  // smem tensor prepared by DMA_V and softmax
  Tensor tCsV = shared_storage.tensor_sV();         // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
  Tensor sP = shared_storage.tensor_sP();           // ((CTA_qHLocal, CTA_qL), CTA_kvL, 1)
  // cluster level tiling for mO, gO is what will be produced by the entire cluster
  Tensor gO = local_tile(mO, make_shape(Int<CTA_dH>{}, make_shape(Int<CTA_qHLocal>{}, Int<CTA_qL>{})), 
                      make_coord(work_tile_info.dH_idx, make_coord(work_tile_info.qHLocal_idx, work_tile_info.qL_idx), work_tile_info.kvH_idx, work_tile_info.BS_idx));  // (CTA_dH, (CTA_qHLocal, CTA_qL))

  // BMM2 Fragment Allocation
  ThrMMA cta_bmm2 = tiled_bmm2.get_slice(0);        // 1 sm mma only has 1 thread in tiled_mma
  Tensor tCrV = cta_bmm2.make_fragment_A(tCsV);     // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
  Tensor tCsP = cta_bmm2.partition_B(sP);           // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
  Tensor tCrP = cta_bmm2.make_fragment_B(tCsP);     // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
  // then partition it to mma shape
  Tensor tCgO = cta_bmm2.partition_C(gO);           // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
  Tensor tCtAcc2 = cta_bmm2.make_fragment_C(tCgO);  // ((Mma_M, Mma_N), NumMma_M, NumMma_N)

  // TMEM Allocation
  // tmem has 128 lane, 512 column, 1 word/column, each word is 4B, 256KB in total
  using TmemAllocator = cute::TMEM::Allocator1Sm;
  TmemAllocator tmem_allocator{};

  int constexpr Acc1_col = CTA_qHLocal * CTA_qL; // num tmem column for tCtAcc1
  int constexpr Acc1_col_max = cute::max(Acc1_col, TmemAllocator::ColumnsPerAllocationSlice); // min allocation granularity is 32 columns
  static_assert((Acc1_col_max & (Acc1_col_max - 1)) == 0, "Acc1 column size is not a power of 2");

  int constexpr Acc2_col = CTA_qHLocal * CTA_qL; // num tmem column for tCtAcc2
  int constexpr Acc2_col_max = cute::max(Acc2_col, TmemAllocator::ColumnsPerAllocationSlice); // min allocation granularity is 32 columns
  static_assert((Acc2_col_max & (Acc2_col_max - 1)) == 0, "Acc2 column size is not a power of 2");

  // allow half of tmem to be used for overlapping with next kernel
  static_assert((Acc1_col_max + Acc2_col_max) < TmemAllocator::Sm100TmemCapacityColumns / 2, "Accumulator is too large to fit in half of tmem");

  // do two separate allocations for bmm1 and bmm2 accumulators, we waste some capacity and cycles
  // if needed, in the future we can merge the two allocations into one and do some offsetting
  tmem_allocator.allocate(Acc1_col_max, &shared_storage.bmm1_tmem_base_ptr);
  tmem_allocator.allocate(Acc2_col_max, &shared_storage.bmm2_tmem_base_ptr);
  // notify epilog warp that tmem allocation is complete
  tmem_allocation_barrier.arrive();

  // relinquish early so that prefetch cta can be launched
  tmem_allocator.release_allocation_lock();

  // update the tmem base ptr of the accumulator tensor
  tCtAcc1.data() = shared_storage.bmm1_tmem_base_ptr;
  tCtAcc2.data() = shared_storage.bmm2_tmem_base_ptr;

  /*if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    printf("tCsK:\t"); print(tCsK); print("\n");         // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
    printf("tCsQ:\t"); print(tCsQ); print("\n");         // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
    printf("sS:\t"); print(sS); print("\n");             // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1)
    printf("tCsS:\t"); print(tCsS); print("\n");         // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
    printf("Acc1_col_max:\t%d\n", Acc1_col_max);
    printf("tCtAcc1:\t"); print(tCtAcc1); print("\n");   // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
    printf("tCrK:\t"); print(tCrK); print("\n");         // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
    printf("tCrQ:\t"); print(tCrQ); print("\n");         // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)

    printf("tCsV:\t"); print(tCsV); print("\n");         // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
    printf("sP:\t"); print(sP); print("\n");             // ((CTA_qHLocal, CTA_qL), CTA_kvL, 1)
    printf("tCsP:\t"); print(tCsP); print("\n");         // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
    printf("tCrV:\t"); print(tCrV); print("\n");         // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
    printf("tCrP:\t"); print(tCrP); print("\n");         // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
    printf("gO:\t"); print(gO); print("\n");             // (CTA_dH, (CTA_qHLocal, CTA_qL))
    printf("tCgO:\t"); print(tCgO); print("\n");         // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
    printf("Acc2_col_max:\t%d\n", Acc2_col_max);
    printf("tCtAcc2:\t"); print(tCtAcc2); print("\n");   // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
  }*/

  bool constexpr Print = false;
  int k_tile_count = work_tile_info.kvL_idx_end - work_tile_info.kvL_idx_start;
  // iterate over kblock
  // SOL order is: K0Q0, (K1Q0, V0P0), (K2Q0, V1P1), (K3Q0, V2P2), ...

  // details of how the phase bit works is in DMA_Q_warp
  int tma_bmm1_full_barrier_phase_bit = 0;
  int tma_bmm2_full_barrier_phase_bit = 0;

  int bmm1_stage_idx = 0;
  int bmm2_stage_idx = 0;

  int k_tile = 0;

  // prolog bmm1
  // bmm1 always overwrites the accumulator, so we set it to UMMA::ScaleOut::Zero
  MMA_gemm<decltype(tCrK), decltype(tCrQ), decltype(tCtAcc1), TiledBMM1, '1', Print>(tCrK, tCrQ, tCtAcc1, tiled_bmm1, bmm1_stage_idx, tma_bmm1_full_barrier_phase_bit, UMMA::ScaleOut::Zero, shared_storage.tma_bmm1_full_barrier, shared_storage.tma_bmm1_empty_barrier, shared_storage.bmm1_softmax_full_barrier);

  for (; k_tile < (k_tile_count - 1); k_tile++) {
    // bmm1 of next iter
    MMA_gemm<decltype(tCrK), decltype(tCrQ), decltype(tCtAcc1), TiledBMM1, '1', Print>(tCrK, tCrQ, tCtAcc1, tiled_bmm1, bmm1_stage_idx, tma_bmm1_full_barrier_phase_bit, UMMA::ScaleOut::Zero, shared_storage.tma_bmm1_full_barrier, shared_storage.tma_bmm1_empty_barrier, shared_storage.bmm1_softmax_full_barrier);

    // bmm2 of current iter
    // for bmm2, only clear the accumulator for the first iter, for subsequent iters, we accumulate the VP result on top of corrected Acc2
    UMMA::ScaleOut bmm2_accumulate = (k_tile == 0) ? UMMA::ScaleOut::Zero : UMMA::ScaleOut::One;
    MMA_gemm<decltype(tCrV), decltype(tCrP), decltype(tCtAcc2), TiledBMM2, '2', Print>(tCrV, tCrP, tCtAcc2, tiled_bmm2, bmm2_stage_idx, tma_bmm2_full_barrier_phase_bit, bmm2_accumulate, shared_storage.tmasoftmax_bmm2_full_barrier, shared_storage.tma_bmm2_empty_barrier, shared_storage.bmm2_epilog_full_barrier);
  }

  // epilog bmm2
  UMMA::ScaleOut bmm2_accumulate = (k_tile == 0) ? UMMA::ScaleOut::Zero : UMMA::ScaleOut::One;
  MMA_gemm<decltype(tCrV), decltype(tCrP), decltype(tCtAcc2), TiledBMM2, '2', Print>(tCrV, tCrP, tCtAcc2, tiled_bmm2, bmm2_stage_idx, tma_bmm2_full_barrier_phase_bit, bmm2_accumulate, shared_storage.tmasoftmax_bmm2_full_barrier, shared_storage.tma_bmm2_empty_barrier, shared_storage.bmm2_epilog_full_barrier);

  // wait for tmem deallocation signal from epilog warp
  tmem_allocation_barrier.arrive_and_wait();

  // deallocate TMEM
  tmem_allocator.free(shared_storage.bmm1_tmem_base_ptr, Acc1_col_max);
  tmem_allocator.free(shared_storage.bmm2_tmem_base_ptr, Acc2_col_max);
}

// first do softmax on S, then do flash decode reduction
template <
  class SharedStorage,
  class WorkTileInfo,
  class KTensor,
  class OTensor,
  class SinkTensor,
  class TiledBMM1,
  class TiledBMM2,
  int CTA_qHLocal, int CTA_qL, int CTA_kvL, int CTA_dH,
  int NumReductionCTA,
  bool NoSink>
CUTLASS_DEVICE void 
EPILOG_warp(
  SharedStorage& shared_storage,
  WorkTileInfo work_tile_info,
  KTensor mK,
  OTensor mO,
  SinkTensor mSink,
  int seq_len,
  TiledBMM1 tiled_bmm1,
  TiledBMM2 tiled_bmm2,
  float softmax_scale_log2,
  int sliding_window_size,
  cutlass::arch::NamedBarrier& tmem_allocation_barrier,
  cutlass::arch::NamedBarrier& epilog_barrier,
  int NumSplits,
  int tid,      // tid local to epilog warp
  int warp_idx, // warp id local to epilog warp group
  int rank
) {
  // bmm1
  Tensor sS = shared_storage.tensor_sS();           // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1)
  // BMM1 Fragment Allocation
  ThrMMA cta_bmm1 = tiled_bmm1.get_slice(0);        // 1 sm mma only has 1 thread in tiled_bmm1
  // then partition it to mma shape
  // we only use 1 S buffer, it gives sufficient overlap between MMA and softmax
  Tensor tCsS = cta_bmm1.partition_C(sS(_,_,0));    // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
  // create the tmem tensor view
  Tensor tCtAcc1 = cta_bmm1.make_fragment_C(tCsS);  // ((Mma_M, Mma_N), NumMma_M, NumMma_N)

  // bmm2
  // cluster level tiling for mO, gO is what will be produced by the entire cluster
  Tensor gO = local_tile(mO, make_shape(Int<CTA_dH>{}, make_shape(Int<CTA_qHLocal>{}, Int<CTA_qL>{})), 
                      make_coord(work_tile_info.dH_idx, make_coord(work_tile_info.qHLocal_idx, work_tile_info.qL_idx), work_tile_info.kvH_idx, work_tile_info.BS_idx));  // (CTA_dH, (CTA_qHLocal, CTA_qL))
  // BMM2 Fragment Allocation
  ThrMMA cta_bmm2 = tiled_bmm2.get_slice(0);        // 1 sm mma only has 1 thread in tiled_bmm2
  // then partition it to mma shape
  Tensor tCgO = cta_bmm2.partition_C(gO);           // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
  // create the tmem tensor view
  Tensor tCtAcc2 = cta_bmm2.make_fragment_C(tCgO);  // ((Mma_M, Mma_N), NumMma_M, NumMma_N)

  // wait for tmem allocation in mma warp to complete, only do the wait for valid tiles
  if (work_tile_info.is_valid()) {
    tmem_allocation_barrier.arrive_and_wait();
  }

  // update tmem base ptr of the accumulator tensor
  tCtAcc1.data() = shared_storage.bmm1_tmem_base_ptr;
  tCtAcc2.data() = shared_storage.bmm2_tmem_base_ptr;

  // BMM1 tcgen05.ld
  using TypeAcc = typename decltype(tCtAcc1)::value_type;
  constexpr int acc1_col_bits = size<1>(sS) * sizeof_bits_v<TypeAcc>;
  // use tcgen05.ld.32dp32bit simplifies softmax implementation, every thread just hold a row of the accumulator tensor
  // softmax is applied to each column, so we do both the sum and max across all 128 threads using warp shuffle
  auto bmm1_tmem_load = TMEM::op_repeater<SM100_TMEM_LOAD_32dp32b1x, acc1_col_bits>();
  TiledCopy tiled_t2r_copy_bmm1 = make_tmem_copy(bmm1_tmem_load, tCtAcc1);
  // epilog tid is from 128 to 255, need to offset by -128 when getting the per thread slice
  ThrCopy   thr_t2r_copy_bmm1   = tiled_t2r_copy_bmm1.get_slice(tid);

  // tD means the partitioning pattern of tcgen05.ld
  // now we get the per thread slice of the Acc1 for tcgen05.ld src and dst
  Tensor tDtAcc1 = thr_t2r_copy_bmm1.partition_S(tCtAcc1);  // (CpyS, NumCpy_M, NumCpy_N), per subpartition view of the Acc1/S tensor
  Tensor tDsS    = thr_t2r_copy_bmm1.partition_D(tCsS);     // (CpyD, NumCpy_M, NumCpy_N), per thread slice of the Acc1/S tensor in smem, i.e. a row of the Acc1 tensor
  // allocate per thread rmem space for the Acc1, the shape is the same as the post partition shape of the output tensor
  Tensor tDrS = make_tensor<TypeAcc>(shape(tDsS));          // (CpyD, NumCpy_M, NumCpy_N), per thread slice of the Acc1/S tensor in rmem, i.e. a row of the Acc1 tensor

  // restructure Acc1 in rmem for faster fsum reduction
  // because tcgen05.ld.32dp32bit put each row of the Acc1 tensor into 1 thread, for softmax we need cross thread reduction (reduce each column) for fsum/fmax, fmax is fine because we can use redux.sync
  // so we restructure Acc1 in rmem such that each thread holds a partial column of the Acc1 tensor, so we do thread local reduction as much as possible, then do warp/cta/cluster reduction
  Tensor sAcc1 = shared_storage.tensor_sAcc1();     // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1)
  Tensor tCsAcc1 = cta_bmm1.partition_C(sAcc1(_,_,0));      // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
  Tensor tDsAcc1 = thr_t2r_copy_bmm1.partition_D(tCsAcc1);  // (CpyD, NumCpy_M, NumCpy_N), per thread slice of the output tensor
  // zipped_divide partition it into (CTA_qHLocal * CTA_qL, (CTA_kvL / CTA_qHLocal / CTA_qL, (CTA_qHLocal, CTA_qL)))
  // then the per thread indexing gets the shape to (CTA_qHLocal * CTA_qL)
  // tFsum means the thread partitioning pattern for calculating fsum, i.e. each thread holds a partial column of the Acc1 tensor
  Tensor tFsumsAcc1 = zipped_divide(sAcc1(_,_,0), Int<CTA_qHLocal * CTA_qL>{})(_, tid); // (CTA_qHLocal * CTA_qL)
  Tensor tFsumrAcc1 = make_tensor<TypeAcc>(shape(tFsumsAcc1)); // (CTA_qHLocal * CTA_qL)
  // so what we do is tmem(tDtAcc1)->rmem(tDrS)->smem(tDsAcc1/tFsumsAcc1)->rmem(tFsumrAcc1)
  static_assert(CTA_kvL % (CTA_qHLocal * CTA_qL) == 0, "CTA_kvL must be divisible by CTA_qHLocal * CTA_qL"); // such that each column is held by integer number of threads
  static_assert((CTA_kvL / (CTA_qHLocal * CTA_qL)) <= 32, "CTA_kvL / (CTA_qHLocal * CTA_qL) must be less than or equal to 32"); // such that fsum reduction won't cross warp boundary

  // predicate tensor for predicating S/P based on kvL
  Tensor coordK = make_identity_tensor(shape(mK));    // (kvL, dH, kvH, BS) -> (kvL, dH, kvH, BS)
  Tensor cK = local_tile(coordK, make_shape(Int<CTA_kvL>{}, Int<CTA_dH>{}), 
                          make_coord(_, work_tile_info.dH_idx, work_tile_info.kvH_idx, work_tile_info.BS_idx));  // (CTA_kvL, CTA_dH, Num_CTA_kvL) -> (kvL, dH, kvH, BS)
  Tensor cur_kvL = cK(tid, 0, _); // (Num_CTA_kvL) -> (kvL, dH, kvH, BS)

  // BMM2 tcgen05.ld
  // now we get the per thread slice of the Acc2 for tcgen05.ld src and dst
  constexpr int acc2_col_bits = size<1>(gO) * sizeof_bits_v<TypeAcc>;
  // use tcgen05.ld.32dp32bit simplifies correction implementation, every thread just hold a row of the accumulator tensor
  // but cute will be unhappy since we use MMA_M=64 mma but load tmem with 32dp32bit, so we need to bypass cute copy completely by directly using ptx
  auto bmm2_tmem_load = TMEM::op_repeater<SM100_TMEM_LOAD_32dp32b1x, acc2_col_bits>();
  // similarly, use tcgen05.st.32dp32bit to store the corrected Acc2 back to tmem
  auto bmm2_tmem_store = TMEM::op_repeater<SM100_TMEM_STORE_32dp32b1x, acc2_col_bits>();
  // allocate per thread rmem space for the reshaped Acc2 tensor, it just hold a row of the Acc2 tensor
  // tAcc2 means it's the partitioning pattern where each thread holds a row of the Acc2 tensor
  // for dH=64, after tcgen05.ld, thread 0-15, 32-47, 64-79, 96-111 will hold the data of Acc2(0:16,:), Acc2(32:48,:), Acc2(64:80,:), Acc2(96:112,:)
  // for dH=128, after tcgen05.ld, thread 0-31, 32-63, 64-95, 96-127 will hold the data of Acc2(0:32,:), Acc2(32:64,:), Acc2(64:96,:), Acc2(96:128,:)
  Tensor tAcc2rAcc2 = make_tensor<TypeAcc>(shape<1>(gO)); // (CTA_qHLocal, CTA_qL), per thread slice of the Acc2 tensor in rmem
  uint32_t acc2_tmem_addr = raw_pointer_cast(tCtAcc2.data());
  // mapping between thread id (T) -> dH (row index of Acc2), different for dH=64 and dH=128
  Layout bmm2_tmem_load_t_dH_layout = make_bmm2_tmem_load_t_dH_layout<CTA_dH>();

  // now we define the warp reduce partial results tensor for fmax
  Tensor sFmaxPartial = shared_storage.tensor_sFmaxPartial(); // (NumEpilogWarps, (CTA_qHLocal, CTA_qL))
  // each element in tDrS (CTA_qHLocal, CTA_qL) is from a different column (q token) of Acc1 tensor, softmax takes column sum/max and scale each element
  // each column would need a separate fmax, so the meta data max tensor has the same shape as tDrS, and the max value is the same for the same column for all threads
  // this is the CTA wide fmax tensor for all kv tiles
  Tensor tDrFmax = make_tensor<TypeAcc>(shape(tDsS)); // (CpyD, NumCpy_M, NumCpy_N) or (CTA_qHLocal * CTA_qL), per thread slice of the meta data max tensor

  // we do things a bit differently for fsum, each warp holds its portion of the fsum tensor, there are CTA_qHLocal * CTA_qL fsum in total for this cta
  // and we evenly distribute the q tokens between all epilog warps, so each warp computes CTA_qHLocal * CTA_qL / NumEpilogWarps q tokens
  int constexpr NumEpilogWarps = size<0>(sFmaxPartial);
  static_assert(CTA_dH <= (NumEpilogWarps * 32), "have enough threads to hold bmm2 tcgen05.ld output");
  int constexpr NumQPerWarp = CTA_qHLocal * CTA_qL / NumEpilogWarps;
  // alpha = exp2f(m_i_old - m_i)
  Tensor rAlpha  = make_tensor<TypeAcc>(shape(tDrS)); // (CpyD, NumCpy_M, NumCpy_N) or (CTA_qHLocal * CTA_qL), per thread slice
  // this is the thread wide fsum tensor for all kv tiles
  Tensor l_i = make_tensor<TypeAcc>(shape(tDrS)); // (CpyD, NumCpy_M, NumCpy_N) or (CTA_qHLocal * CTA_qL), per thread slice
  // this is the CTA wide fsum tensor for all kv tiles
  Tensor tDrFsum = make_tensor<TypeAcc>(Int<NumQPerWarp>{}); // (NumQPerWarp), per thread slice of the meta data sum tensor
  // then we need a layout to represent the mapping between (warp id (T), V) -> q_idx
  // T0V0 -> q_idx 0
  // T0V1 -> q_idx 1
  // T1V0 -> q_idx 2
  // T1V1 -> q_idx 3
  // ...
  Layout cta_reduce_tv_q_layout = make_layout(make_shape(Int<NumEpilogWarps>{}, Int<NumQPerWarp>{}), make_stride(Int<NumQPerWarp>{}, Int<1>{}));

  // now we do the data type conversion of S/P from fp32 to bf16/fp8
  using TypeQKV = typename decltype(sS)::value_type;
  // allocate per thread rmem space for the converted S/P tensor, the shape is the same as the post partition shape of the output tensor
  // the only difference with tDrAcc is here per element is TypeQKV instead of TypeAcc
  Tensor tDrS_converted = make_tensor<TypeQKV>(shape(tDsS));     // (CpyD, NumCpy_M, NumCpy_N), per thread slice of the Acc1/S tensor in rmem, i.e. a row of the Acc1 tensor
  // create a converter, convert 1 value at a time, from TypeAcc to TypeQKV
  cutlass::NumericConverter<TypeQKV, TypeAcc> converter_s;

  // setup for fmax and fsum cluster reduction
  // each reduction participating cta handles CTA_qHLocal * CTA_qL / NumReductionCTA number of q tokens, there are NumReductionCTA participating in cluster reduction
  // so we want to have a layout/mapping (reduction cta id (T), local q_idx (V)) -> q_idx
  // assume we have 8 q_idx, and 2 reduction ctas, then we have the following mapping:
  // (reduction cta 0, local q_idx 0) -> q_idx 0
  // (reduction cta 0, local q_idx 1) -> q_idx 1
  // (reduction cta 0, local q_idx 2) -> q_idx 2
  // (reduction cta 0, local q_idx 3) -> q_idx 3
  // (reduction cta 1, local q_idx 0) -> q_idx 4
  // (reduction cta 1, local q_idx 1) -> q_idx 5
  // (reduction cta 1, local q_idx 2) -> q_idx 6
  // (reduction cta 1, local q_idx 3) -> q_idx 7
  // we create the tv layout for cluster reduction (reduction cta id (T), local q_idx (V)) -> q_idx
  Layout cluster_reduce_tv_q_layout = make_layout(make_shape(Int<NumReductionCTA>{}, Int<CTA_qHLocal * CTA_qL / NumReductionCTA>{}), 
                                              make_stride(Int<CTA_qHLocal * CTA_qL / NumReductionCTA>{}, Int<1>{}));

  // for fmax/fsum cluster reduction, ultimately we want to have a layout of (warp_id (T), V) -> (reduction cta id (T'), V') for scattering cta scope fmax/fsum values to reduction ctas
  // so we do this by (warp_id (T), V) -> q_idx -> (reduction cta id (T'), V')
  // we obtain q_idx -> (reduction cta id (T'), V') by taking the right inverse of cluster_reduce_tv_q_layout
  //
  // regarding whether we choose right-inverse or left-inverse:
  // You can think of right-inverse as a truncated version of left-inverse -- truncated to the compact range of a layout.
  // if there's a "hole" in the codomain/range, then the right_inverse stops there. E.g.
  //   (4,5):(1,5)           # There's a "hole" at idx=4
  //   right_inverse = 4:1           
  //   left_inverse  = (5,5):(1,4)
  // since here cluster_reduce_tv_q_layout is bijective, there is no hole, so right-inverse and left-inverse are the same
  Layout cluster_reduce_q_tv_layout = right_inverse(cluster_reduce_tv_q_layout);
  // (warp_id (T), V) -> (reduction cta id (T'), V') is obtained through composition
  Layout cluster_reduce_tv_tv_layout = composition(cluster_reduce_q_tv_layout, cta_reduce_tv_q_layout);

  // setup for fmax cluster reduction
  // thread 0 in each epilog warp will send its local portion of fmax (CTA_qHLocal * CTA_qL / NumEpilogWarps q tokens) to corresponding reduction ctas, 
  // i.e. the entire epilog warp group will send all fmax to all reduction ctas
  // for instance we have 8 q tokens and 4 epilog warps, and 8 reduction ctas, fmax tensor is in rmem:
  // warp 0: send fmax(0) (q_idx 0) to reduction cta 0
  // warp 0: send fmax(1) (q_idx 1) to reduction cta 1
  // warp 1: send fmax(0) (q_idx 2) to reduction cta 2
  // warp 1: send fmax(1) (q_idx 3) to reduction cta 3
  // warp 2: send fmax(0) (q_idx 4) to reduction cta 4
  // warp 2: send fmax(1) (q_idx 5) to reduction cta 5
  // warp 3: send fmax(0) (q_idx 6) to reduction cta 6
  // warp 3: send fmax(1) (q_idx 7) to reduction cta 7
  Tensor sFmaxMailbox = shared_storage.tensor_sFmaxMailbox();   // (MaxSplits, CTA_qHLocal * CTA_qL / NumReductionCTA)
  int constexpr MaxSplits = size<0>(sFmaxMailbox);
  // tSRC means cluster reduction src partitioning pattern, i.e. each CTA holds a particular row of the mailbox tensor of all reduction ctas
  Tensor tSRCsFmaxMailbox = sFmaxMailbox(rank,_);               // (CTA_qHLocal * CTA_qL / NumReductionCTA)
  // destination dsmem tensor for each q token
  decltype(tSRCsFmaxMailbox) tSRCdsFmaxMailbox[NumQPerWarp]; // send different q tokens to different reduction cta

  // setup for fsum cluster reduction
  Tensor sFsumMailbox = shared_storage.tensor_sFsumMailbox();   // (MaxSplits, CTA_qHLocal * CTA_qL / NumReductionCTA)
  // tSRC means cluster reduction src partitioning pattern, i.e. each CTA holds a particular row of the mailbox tensor of all reduction ctas
  Tensor tSRCsFsumMailbox = sFsumMailbox(rank,_);               // (CTA_qHLocal * CTA_qL / NumReductionCTA)
  // destination dsmem tensor for each q token
  decltype(tSRCsFsumMailbox) tSRCdsFsumMailbox[NumQPerWarp]; // send different q tokens to different reduction cta

  uint32_t dsmem_maxsum_mailbox_full_barrier_addr[NumQPerWarp]; // dsmem addr for mailbox barrier

  // do mapa and get the dsmem addr of each q token
  CUTE_UNROLL
  for(int i = 0; i < NumQPerWarp; i++) {
    auto cluster_tv = cluster_reduce_tv_tv_layout(warp_idx, i); // it's the 1d coordinate of (reduction cta id (T'), V')
    // idx2crd convertes 1d coordinate to natural coordinate, i.e. (reduction cta id (T'), V')
    int dst_cta_id = get<0>(idx2crd(cluster_tv, shape(cluster_reduce_tv_q_layout)));
    tSRCdsFmaxMailbox[i] = get_dsmem_tensor(tSRCsFmaxMailbox, dst_cta_id);
    tSRCdsFsumMailbox[i] = get_dsmem_tensor(tSRCsFsumMailbox, dst_cta_id);
    uint32_t smem_maxsum_mailbox_full_barrier_addr = __cvta_generic_to_shared(&shared_storage.maxsum_mailbox_full_barrier);
    dsmem_maxsum_mailbox_full_barrier_addr[i] = set_block_rank(smem_maxsum_mailbox_full_barrier_addr, dst_cta_id);
  }

  // setup for Acc2 cluster reduction
  int row_id = bmm2_tmem_load_t_dH_layout(tid);
  Tensor sAcc2Mailbox = shared_storage.tensor_sAcc2Mailbox(); // (CTA_dH, CTA_qHLocal * CTA_qL / NumReductionCTA, MaxSplits)
  // per thread slice of the Acc2 mailbox tensor, tSRC means cluster reduction src partitioning pattern
  // each thread sends each row of the Acc2 tensor to many dst CTAs
  Tensor tSRCsAcc2Mailbox = sAcc2Mailbox(row_id,_,rank);      // (CTA_qHLocal * CTA_qL / NumReductionCTA)
  decltype(tSRCsAcc2Mailbox) tSRCdsAcc2Mailbox[NumReductionCTA]; // send different q tokens to different reduction cta
  uint32_t dsmem_acc2_mailbox_full_barrier_addr[NumReductionCTA]; // dsmem addr for mailbox barrier
  // do mapa and get the dsmem addr of q token
  CUTE_UNROLL
  for(int i = 0; i < NumReductionCTA; i++) {
    tSRCdsAcc2Mailbox[i] = get_dsmem_tensor(tSRCsAcc2Mailbox, i);
    uint32_t smem_acc2_mailbox_full_barrier_addr = __cvta_generic_to_shared(&shared_storage.acc2_mailbox_full_barrier);
    dsmem_acc2_mailbox_full_barrier_addr[i] = set_block_rank(smem_acc2_mailbox_full_barrier_addr, i);
  }

  Tensor tCsK = shared_storage.tensor_sK();   // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
  Tensor tCsV = shared_storage.tensor_sV();   // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
  int constexpr BMM1_DMA_Stage = size<3>(tCsK);
  int constexpr BMM2_DMA_Stage = size<3>(tCsV);
  int NumKVTiles = work_tile_info.kvL_idx_end - work_tile_info.kvL_idx_start;

  // setup for cluster reduction
  // because each CTA is going to produce (CTA_dH, CTA_qHLocal * CTA_qL / NumReductionCTA), i.e. each CTA handles CTA_qHLocal * CTA_qL / NumReductionCTA q tokens
  // we further partition gO into per CTA level
  static_assert(CTA_qHLocal * CTA_qL % NumReductionCTA == 0, "CTA_qHLocal * CTA_qL must be divisible by NumReductionCTA");
  Tensor tCTAgO = local_tile(gO, make_shape(Int<CTA_dH>{}, Int<CTA_qHLocal * CTA_qL / NumReductionCTA>{}), make_coord(0, rank));  // (CTA_dH, CTA_qHLocal * CTA_qL / NumReductionCTA)

  // now we do the data type conversion of Acc2 from fp32 to bf16/fp8
  using TypeO = typename decltype(mO)::value_type;
  // create a converter, convert 1 value at a time, from TypeAcc to TypeO
  cutlass::NumericConverter<TypeO, TypeAcc> converter_o;

  // setup for fmax/fsum cluster reduction
  int maxsum_st_async_transaction_bytes = NumSplits * CTA_qHLocal * CTA_qL / NumReductionCTA * sizeof(TypeAcc) * 2;

  // participating CTA set the barrier transaction bytes
  if ((rank < NumReductionCTA) && (tid == 0)) {
    set_barrier_transaction_bytes(shared_storage.maxsum_mailbox_full_barrier, maxsum_st_async_transaction_bytes);
  }

  // allocate cluster wide fmax and fsum tensor
  Tensor rFmaxCluster = make_tensor<TypeAcc>(size<1>(sFmaxMailbox)); // (CTA_qHLocal * CTA_qL / NumReductionCTA)
  // beta = exp2f(m_ij - m_i)
  Tensor rBeta    = make_tensor<TypeAcc>(make_shape(size<1>(sFmaxMailbox), size<0>(sFmaxMailbox))); // (CTA_qHLocal * CTA_qL / NumReductionCTA, MaxSplits)
  Tensor rFsumCluster = make_tensor<TypeAcc>(size<1>(sFsumMailbox)); // (CTA_qHLocal * CTA_qL / NumReductionCTA)

  // setup for Acc2 cluster reduction
  int acc2_st_async_transaction_bytes = CTA_dH * CTA_qHLocal * CTA_qL / NumReductionCTA * NumSplits * sizeof(TypeAcc);

  if ((rank < NumReductionCTA) && (tid == 0)) {
    set_barrier_transaction_bytes(shared_storage.acc2_mailbox_full_barrier, acc2_st_async_transaction_bytes);
  }

  // final per thread (one row of the output tensor) cluster reduction result
  Tensor tAcc2rO = make_tensor<TypeAcc>(size<1>(sFmaxMailbox));         // (CTA_qHLocal * CTA_qL / NumReductionCTA)
  Tensor tAcc2rO_converted = make_tensor<TypeO>(size<1>(sFmaxMailbox)); // (CTA_qHLocal * CTA_qL / NumReductionCTA)

  // attention sink needed by this cluster is 1 kv head
  Tensor gSink = local_tile(mSink, make_shape(make_shape(Int<CTA_qHLocal>{}, Int<CTA_qL>{}), Int<1>{}), 
                          make_coord(make_coord(work_tile_info.qHLocal_idx, work_tile_info.qL_idx), work_tile_info.kvH_idx));  // (CTA_qHLocal, CTA_qL)
  Tensor sSink = shared_storage.tensor_sSink(); // (CTA_qHLocal * CTA_qL / NumReductionCTA)
  // get the sink tensor needed for this cta, i.e. the sink value needed by each reduction cta
  // we achieve this by doing a composition of the gSink tensor and the cluster_reduce_tv_q_layout (aka the tv layout for cluster reduction)
  // composing with a tv layout is equivalent to reorganizing the tensor layout into shape (T, V)
  // after the composition, the tensor shape is (NumReductionCTA, CTA_qHLocal * CTA_qL / NumReductionCTA)
  // then we index into the rank-th row to get the sink value needed by this cta
  Tensor tClustergSink = composition(gSink, cluster_reduce_tv_q_layout)(rank, _); // (CTA_qHLocal * CTA_qL / NumReductionCTA)
  static_assert(size(sSink) < NumEpilogWarps * 32, "one epilog thread loads at most 1 sink value");

  /*if ((tid == 0) && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    printf("sS:\t"); print(sS); print("\n");             // (CTA_dH, (CTA_qHLocal, CTA_qL), 1)
    printf("tCsS:\t"); print(tCsS); print("\n");         // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
    printf("tCtAcc1:\t"); print(tCtAcc1); print("\n");   // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
    printf("sAcc1:\t"); print(sAcc1); print("\n");       // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1)
    printf("tCsAcc1:\t"); print(tCsAcc1); print("\n");   // ((Mma_M, Mma_N), NumMma_M, NumMma_N)

    printf("tiled_t2r_copy_bmm1:\t"); print(tiled_t2r_copy_bmm1); print("\n");
    printf("thr_t2r_copy_bmm1:\t"); print(thr_t2r_copy_bmm1); print("\n");
    printf("tDtAcc1:\t"); print(tDtAcc1); print("\n");   // (CpyS, NumCpy_M, NumCpy_N)
    printf("tDsS:\t"); print(tDsS); print("\n");         // (CpyD, NumCpy_M, NumCpy_N)
    printf("tDrS:\t"); print(tDrS); print("\n");         // (CpyD, NumCpy_M, NumCpy_N)

    printf("sFmaxPartial:\t"); print(sFmaxPartial); print("\n");
    printf("tDrFmax:\t"); print(tDrFmax); print("\n");
    printf("tDrFsum:\t"); print(tDrFsum); print("\n");
    printf("cta_reduce_tv_q_layout: "); print_layout(cta_reduce_tv_q_layout); print("\n");

    printf("tDrS_converted:\t"); print(tDrS_converted); print("\n"); // (CpyD, NumCpy_M, NumCpy_N)

    printf("tDsAcc1:\t"); print(tDsAcc1); print("\n");   // (CpyD, NumCpy_M, NumCpy_N)
    printf("tFsumsAcc1:\t"); print(tFsumsAcc1); print("\n"); // ((CTA_qHLocal, CTA_qL), (CTA_kvL / CTA_qHLocal / CTA_qL, (CTA_qHLocal, CTA_qL)))
    printf("tFsumrAcc1:\t"); print(tFsumrAcc1); print("\n"); // (CTA_qHLocal * CTA_qL)

    printf("coordK: "); print(coordK); print("\n");     // (kvL, dH, kvH, BS)
    printf("cK: "); print(cK); print("\n");             // (CTA_kvL, CTA_dH, Num_CTA_kvL) -> (kvL, dH, kvH, BS)
    printf("cur_kvL: "); print(cur_kvL); print("\n");   // (Num_CTA_kvL) -> (kvL, dH, kvH, BS)
    printf("seq_len: %d\n", seq_len);

    printf("TypeAcc: %lluB\n", sizeof(TypeAcc));

    printf("gO:\t"); print(gO); print("\n");       // (CTA_dH, (CTA_qHLocal, CTA_qL))
    printf("tCgO:\t"); print(tCgO); print("\n");   // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
    printf("tCtAcc2:\t"); print(tCtAcc2); print("\n");   // ((Mma_M, Mma_N), NumMma_M, NumMma_N)
    printf("tAcc2rAcc2:\t"); print(tAcc2rAcc2); print("\n");   // (CTA_qHLocal, CTA_qL)

    printf("cluster_reduce_tv_q_layout: "); print_layout(cluster_reduce_tv_q_layout); print("\n");
    printf("cluster_reduce_q_tv_layout: "); print_layout(cluster_reduce_q_tv_layout); print("\n");
    printf("cluster_reduce_tv_tv_layout: "); print_layout(cluster_reduce_tv_tv_layout); print("\n");

    printf("sFmaxMailbox: "); print(sFmaxMailbox); print("\n");           // (MaxSplits, CTA_qHLocal * CTA_qL / NumReductionCTA)
    printf("tSRCsFmaxMailbox: "); print(tSRCsFmaxMailbox); print("\n");   // (CTA_qHLocal * CTA_qL / NumReductionCTA)
    printf("tSRCdsFmaxMailbox[1]: "); print(tSRCdsFmaxMailbox[1]); print("\n");   // (CTA_qHLocal * CTA_qL / NumReductionCTA)
    printf("sFsumMailbox: "); print(sFsumMailbox); print("\n");           // (MaxSplits, CTA_qHLocal * CTA_qL / NumReductionCTA)
    printf("tSRCsFsumMailbox: "); print(tSRCsFsumMailbox); print("\n");   // (CTA_qHLocal * CTA_qL / NumReductionCTA)
    printf("tSRCdsFsumMailbox[1]: "); print(tSRCdsFsumMailbox[1]); print("\n");   // (CTA_qHLocal * CTA_qL / NumReductionCTA)
    printf("dsmem_maxsum_mailbox_full_barrier_addr[1]: %x\n", dsmem_maxsum_mailbox_full_barrier_addr[1]);

    printf("sAcc2Mailbox: "); print(sAcc2Mailbox); print("\n");           // (CTA_dH, CTA_qHLocal * CTA_qL / NumReductionCTA, MaxSplits)
    printf("tSRCsAcc2Mailbox: "); print(tSRCsAcc2Mailbox); print("\n");   // (CTA_qHLocal * CTA_qL / NumReductionCTA)
    printf("tSRCdsAcc2Mailbox[2]: "); print(tSRCdsAcc2Mailbox[2]); print("\n");   // (CTA_qHLocal * CTA_qL / NumReductionCTA)
    printf("dsmem_acc2_mailbox_full_barrier_addr[2]: %x\n", dsmem_acc2_mailbox_full_barrier_addr[2]);

    printf("tCTAgO:\t"); print(tCTAgO); print("\n");     // (CTA_dH, CTA_qHLocal * CTA_qL / NumReductionCTA)

    printf("NumSplits: %d\n", NumSplits);
    printf("maxsum_st_async_transaction_bytes: %d\n", maxsum_st_async_transaction_bytes);

    printf("rFmaxCluster: "); print(rFmaxCluster); print("\n");                   // (CTA_qHLocal * CTA_qL / NumReductionCTA)
    printf("rBeta: "); print(rBeta); print("\n");                         // (CTA_qHLocal * CTA_qL / NumReductionCTA, MaxSplits)
    printf("rFsumCluster: "); print(rFsumCluster); print("\n");                   // (CTA_qHLocal * CTA_qL / NumReductionCTA)

    printf("acc2_st_async_transaction_bytes: %d\n", acc2_st_async_transaction_bytes);

    printf("tAcc2rO: "); print(tAcc2rO); print("\n");                     // (CTA_qHLocal * CTA_qL / NumReductionCTA)
    printf("tAcc2rO_converted: "); print(tAcc2rO_converted); print("\n"); // (CTA_qHLocal * CTA_qL / NumReductionCTA)

    printf("gSink: "); print(gSink); print("\n");                         // (CTA_qHLocal, CTA_qL)
    printf("sSink: "); print(sSink); print("\n");                         // (CTA_qHLocal * CTA_qL / NumReductionCTA)
    printf("tClustergSink: "); print(tClustergSink); print("\n");         // (CTA_qHLocal * CTA_qL / NumReductionCTA)

    // test inf properties
    // -inf - 2 = -inf
    // exp2f(-inf) = 0
    // refer to cuda math api for full behavior ragarding inf https://docs.nvidia.com/cuda/cuda-math-api/cuda_math_api/group__CUDA__MATH__SINGLE.html#group__cuda__math__single_1ga3e2984de99de67ca680c9bb4f4427f81
    printf("-inf: %f\n", -cutlass::platform::numeric_limits<TypeAcc>::infinity());
    printf("-inf-2: %f\n", -cutlass::platform::numeric_limits<TypeAcc>::infinity() - 2.0f);
    printf("exp2f(-inf-2): %f\n", exp2f(-cutlass::platform::numeric_limits<TypeAcc>::infinity() - 2.0f));
  }*/

  static_assert(MaxSplits <= 32, "we can use 1 warp to initialize mailbox");
  // initialize mailbox tensor for fmax and fsum, when NumSplits < MaxSplits, we need to init those value to -inf and 0
  // because we do reduction on the full tensor (of size MaxSplits) not just the valid splits
  // there is no need to init sAcc2 because it will be scaled with beta which will be 0 for invalid splits
  if (tid < MaxSplits) {
    fill(sFmaxMailbox(tid, _), -cutlass::platform::numeric_limits<TypeAcc>::infinity());
    clear(sFsumMailbox(tid, _));
  }

  // ensure initialized smem is visible to the entire cluster
  cutlass::arch::fence_view_async_shared();
  epilog_barrier.arrive_and_wait();

  // issue cp.async for sink tensor
  if constexpr (!NoSink) {
    if (rank < NumReductionCTA) {
      // each thread loads one sink value
      if (tid < size(sSink)) {
        cp_async((int*)(&tClustergSink(tid)), (int*)(&sSink(tid)));
      }
    }
  }

  // only do softmax on valid kv tiles
  if (work_tile_info.is_valid()) {
    // init rmem tensor to make first iteration correct
    fill(tDrFmax, -cutlass::platform::numeric_limits<TypeAcc>::infinity());
    clear(l_i);
    // prolog do arrive on tma_bmm1_full_barrier because first BMM1 doesn't need to wait for preceeding tcgen05.ld Acc1
    if (elect_one_sync()) {
      arrive_barrier(shared_storage.tma_bmm1_full_barrier[0]);
    }

    // initial phase bit for bmm1_softmax_full_barrier is 0
    // it is flipped to 1 when the BMM1 warp is done, and now we can start the softmax
    int bmm1_softmax_full_barrier_phase_bit = 0;

    // initial phase bit for bmm2_epilog_full_barrier is 0
    // it is flipped to 1 when the BMM2 warp is done, and now we can start the epilog
    int bmm2_epilog_full_barrier_phase_bit = 0;

    // If sliding window feature is enabled, we need to adjust the seq_len_start.
    int seq_len_start = (sliding_window_size == 0) ? 0 : cute::max(0, seq_len - sliding_window_size);

    // loop over each kv tile
    for (int kv_tile = 0; kv_tile < NumKVTiles; kv_tile++) {

      // wait for the BMM1 warp to finish
      wait_barrier(shared_storage.bmm1_softmax_full_barrier, bmm1_softmax_full_barrier_phase_bit);
      bmm1_softmax_full_barrier_phase_bit ^= 1; // flip the phase bit in preparation for next BMM1

      //if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
      //  printf("[Softmax] tile %d fmax start\n", kv_tile);
      //}

      // softmax on S
      // load tmem -> rmem
      copy(tiled_t2r_copy_bmm1, tDtAcc1, tDrS);
      // there isn't a register dependency on tDrS to honor here to signal tcgen05.ld is done, so we need explicit tcgen05.wait::ld to make sure tcgen05.ld is done
      // tcgen05.wait::ld has an implicit __syncwarp, so we don't need a bar.sync across all epilog warp group
      cutlass::arch::fence_view_async_tmem_load();
      // only 1 thread per warp signals bmm1 of next iter to start, so in aggregate it's 4 arrives, i.e. each warp sync independently with bmm1, no need for all warp group to be in sync
      // tcgen05.ld of Acc1 is done, the BMM1 of next iter can start to overwrite tmem
      if (elect_one_sync()) {
        arrive_barrier(shared_storage.tma_bmm1_full_barrier[(kv_tile + 1) % BMM1_DMA_Stage]);
      }

      // fill the row with -inf if the data is not valid (i.e. over the kv seq len), such that after softmax they will be 0
      // the data per thread is a row of the S/Acc1 tensor of shape (CTA_kvL, (CTA_qHLocal, CTA_qL))
      // if the data is not valid, we fill it with -inf (mask off) such that it will be nop in fmax and fsum reduction
      auto kv_seq_len = get<0>(cur_kvL(work_tile_info.kvL_idx_start + kv_tile));
      bool row_valid = (kv_seq_len < seq_len) &&  (kv_seq_len >= seq_len_start); // only kvL within [seq_len_start, seq_len) is valid
      if (!row_valid) {
        fill(tDrS, -cutlass::platform::numeric_limits<TypeAcc>::infinity());
      }
      // scale it by softmax_scale_log2, s = s * softmax_scale_log2 = s * softmax_scale * log2(e)
      // here we leverage the fact that expf(s) = exp2f(s * log2(e)), and doing the exp2f path generates less instructions than expf (and presumably slightly less accurate)
      // so we fuse the log2(e) with the softmax scale, hence all later expf (e.g. alpha/beta) should be replaced by exp2f
      // with cuda graph, softmax_scale_log2 is already precalculated on the cpu and hardened as kernel parameter/constant, there is no overhead of this fusion
      CUTE_UNROLL
      for (int i = 0; i < tDrS.size(); i++) {
        tDrS[i] *= softmax_scale_log2;
      }

      // calculate fmax across all threads for tile (CTA_kvL, (CTA_qHLocal, CTA_qL))
      // m_ij = fmax(s)
      Tensor m_ij = make_tensor<TypeAcc>(shape(tDrFmax)); // (CTA_qHLocal * CTA_qL), per thread slice of the meta data max tensor for the current kv tile
      cta_reduce<ReduceOp::Max, NumEpilogWarps>(tDrS, m_ij, warp_idx, sFmaxPartial, epilog_barrier);

      // m_i_old = m_i
      Tensor m_i_old = make_tensor<TypeAcc>(shape(tDrFmax));
      copy(tDrFmax, m_i_old);

      // m_i = max(m_i_old, m_ij)
      CUTE_UNROLL
      for (int i = 0; i < tDrFmax.size(); i++) {
        tDrFmax[i] = reduce_op<ReduceOp::Max>(tDrFmax(i), m_ij(i));
      }

      // alpha = exp2f(m_i_old - m_i)
      CUTE_UNROLL
      for (int i = 0; i < tDrFmax.size(); i++) {
        rAlpha[i] = exp2f(m_i_old[i] - tDrFmax[i]);
      }

      // p = exp2f(s - m_i)
      CUTE_UNROLL
      for (int i = 0; i < tDrS.size(); i++) {
        tDrS[i] = exp2f(tDrS[i] - tDrFmax[i]);
      }

      // l_i = alpha * l_i + p
      CUTE_UNROLL
      for (int i = 0; i < tDrS.size(); i++) {
        l_i[i] = rAlpha[i] * l_i[i] + tDrS[i];
      }

      // convert S/P from fp32 to bf16
      CUTE_UNROLL
      for (int i = 0; i < tDrS.size(); i++) {
        tDrS_converted[i] = converter_s(tDrS[i]);
      }

      // wait for the BMM2 warp to finish, such that we can write a new S tensor to smem for the next iteration of BMM2
      if (kv_tile > 0) { // we can safely overwrite S in the first iter since there is no preceeding BMM2 that consumes S
        wait_barrier(shared_storage.bmm2_epilog_full_barrier, bmm2_epilog_full_barrier_phase_bit);
        bmm2_epilog_full_barrier_phase_bit ^= 1; // flip the phase bit in preparation for next BMM2
      }

      //if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
      //  printf("[Softmax] tile %d S store start\n", kv_tile);
      //}

      // store bf16 S to smem
      copy(tDrS_converted, tDsS);
      // fence.proxy.async.shared::cta ensures the smem write from generic proxy (i.e. cuda core) is visible to all async proxy (e.g. tma, tcgen05.mma)
      // we want the S write to smem to be visible by tcgen05.mma in the mma warp
      // so the fence+synchronization pattern is the following:
      // 1. every thread in the epilog warp issues a fence.proxy.async.shared::cta such that the smem write by this thread is visible to async proxy
      // 2. use named barrier to sync all threads in the epilog warp, so when all threads reach this point, every thread has executed the fence.proxy.async.shared::cta
      //    at this point the smem write is visible to tcgen05.mma unit
      // 3. we use mbarrier to notify mma warp that the S tensor is ready and visible to tcgen05.mma unit and bmm2 is ready to start (if V load is also done)
      // 
      // fence.proxy.async.shared::cta
      cutlass::arch::fence_view_async_shared();
      // only need to sync within the warp, baceuse later each warp independently signals bmm2 to start, no need for all warp group to be in sync
      __syncwarp();

      // do the correction here, skip for first iter
      // because we already checked BMM2 is done before the S store, so we can tcgen05.ld Acc2
      // also first iter value of alpha=0, if there is perf issue, we don't need the if
      if (kv_tile > 0) {
        // bmm2 load tmem -> rmem
        // only the first 16 threads in each warp contains the Acc2 tensor data, each thread holds a row of the Acc2 tensor
        // the rest 16 threads hold bogus data
        tmem_load<decltype(bmm2_tmem_load)>(acc2_tmem_addr, tAcc2rAcc2);
        // acc2 = alpha * acc2
        CUTE_UNROLL
        for (int i = 0; i < tAcc2rAcc2.size(); i++) {
          tAcc2rAcc2[i] *= rAlpha[i];
        }
        // now use tcgen05.st to store corrected Acc2 back to tmem
        tmem_store<decltype(bmm2_tmem_store)>(tAcc2rAcc2, acc2_tmem_addr);
        // we need a tcgen05.wait::st to make sure tcgen05.st result is visible to async proxy (i.e. tcgen05.mma)
        // tcgen05.wait::st has an implicit __syncwarp, so we don't need a bar.sync across all epilog warp group
        cutlass::arch::fence_view_async_tmem_store();
      }

      // the warp is in sync, just do arrive per warp to signal bmm2 to start
      // only 1 thread per warp signals bmm2 to start, so in aggregate it's 4 arrives
      if (elect_one_sync()) {
        arrive_barrier(shared_storage.tmasoftmax_bmm2_full_barrier[kv_tile % BMM2_DMA_Stage]);
      }
    }

    // overlapped with the last BMM2
    // do transpose of l_i in rmem for faster fsum reduction
    copy(l_i, tDsAcc1);
    // make the smem write visible to all threads in the epilog warp
    epilog_barrier.arrive_and_wait();
    // now each thread holds a partial column of the Acc1 tensor
    copy(tFsumsAcc1, tFsumrAcc1);

    // l_ij = sum(p)
    int constexpr Interval = CTA_kvL / CTA_qHLocal / CTA_qL;
    // do fsum reduction among Interval number of threads
    tDrFsum(0) = cta_reduce_transposed<ReduceOp::Sum, Interval>(tFsumrAcc1);
    // get the rest of the fsum values (different q tokens) to thread 0
    // now thread 0, Interval, 2 * Interval, ... have the fsum values for each q token
    CUTE_UNROLL
    for (int i = 1; i < tDrFsum.size(); i++) {
      tDrFsum(i) = __shfl_sync(0xffffffff, tDrFsum(0), i * Interval, 32);
    }

    // up until here, the content of tDrFmax and tDrFsum is:
    // tDrFmax: warp 0-3: [fmax(q0), fmax(q1), fmax(q2), fmax(q3), fmax(q4), fmax(q5), fmax(q6), fmax(q7)]
    // tDrFsum: warp 0 [fsum(q0), fsum(q1)]
    //          warp 1 [fsum(q2), fsum(q3)]
    //          warp 2 [fsum(q4), fsum(q5)]
    //          warp 3 [fsum(q6), fsum(q7)]
    // st.async expects the layout of tDrFsum, so we rearrange tDrFmax to the same layout as tDrFsum
    static_assert(NumEpilogWarps == 4, "NumEpilogWarps must be 4");
    if (tid == 32) {
      int constexpr WarpId = 1;
      CUTE_UNROLL
      for (int i = 0; i < NumQPerWarp; i++) {
        tDrFmax(i) = tDrFmax(WarpId * NumQPerWarp + i);
      }
    } 
    else if (tid == 64) {
      int constexpr WarpId = 2;
      CUTE_UNROLL
      for (int i = 0; i < NumQPerWarp; i++) {
        tDrFmax(i) = tDrFmax(WarpId * NumQPerWarp + i);
      }
    } 
    else if (tid == 96) {
      int constexpr WarpId = 3;
      CUTE_UNROLL
      for (int i = 0; i < NumQPerWarp; i++) {
        tDrFmax(i) = tDrFmax(WarpId * NumQPerWarp + i);
      }
    }

    // we can start sending cta level fmax and fsum to remote using st.async, 
    // tid 0 in each epilog warp will send its local portion of fmax and fsum to corresponding reduction cta
    // when we have 8 q tokens in total and 4 epilog warps, each thread sends 2 q tokens to corresponding reduction cta
    if ((tid % 32) == 0) {
      CUTE_UNROLL
      for (int i = 0; i < NumQPerWarp; i++) {
        auto cluster_tv = cluster_reduce_tv_tv_layout(warp_idx, i); // it's the 1d coordinate of (reduction cta id (T'), V')
        // idx2crd convertes 1d coordinate to natural coordinate, i.e. (reduction cta id (T'), V')
        int local_q_idx = get<1>(idx2crd(cluster_tv, shape(cluster_reduce_tv_q_layout)));
        store_shared_remote_f32(tDrFmax(i), (uint32_t)&tSRCdsFmaxMailbox[i](local_q_idx), dsmem_maxsum_mailbox_full_barrier_addr[i]);
        store_shared_remote_f32(tDrFsum(i), (uint32_t)&tSRCdsFsumMailbox[i](local_q_idx), dsmem_maxsum_mailbox_full_barrier_addr[i]);
      }
    }

    // wait for the BMM2 warp to finish
    wait_barrier(shared_storage.bmm2_epilog_full_barrier, bmm2_epilog_full_barrier_phase_bit);

    //if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    //  printf("[Epilog] barrier full\n");
    //}

    // bmm2 load tmem -> rmem
    // for dH=64, only the first 16 threads in each warp contains the Acc2 tensor data, each thread holds a row of the Acc2 tensor
    // the rest 16 threads hold bogus data
    // for dH=128, all 32 threads hold valid data
    tmem_load<decltype(bmm2_tmem_load)>(acc2_tmem_addr, tAcc2rAcc2);
    int lane_id = cutlass::canonical_lane_idx();
    if (lane_id < (CTA_dH / NumEpilogWarps)) {
      // do the st.async of acc2 to remote, rmem -> dsmem
      CUTE_UNROLL
      for (int i = 0; i < tAcc2rAcc2.size(); i++) {
        // use the exact same partition layout as fmax and fsum cluster reduction
        // i.e. each reduction cta handles CTA_qHLocal * CTA_qL / NumReductionCTA number of q tokens
        // here we do q_idx -> (reduction cta id (T'), V'), similarly, we use idx2crd to convert 1d coordinate to natural coordinate
        int dst_cta_id = get<0>(idx2crd(cluster_reduce_q_tv_layout(i), shape(cluster_reduce_tv_q_layout)));
        int local_q_idx = get<1>(idx2crd(cluster_reduce_q_tv_layout(i), shape(cluster_reduce_tv_q_layout)));
        store_shared_remote_f32(tAcc2rAcc2(i), (uint32_t)&tSRCdsAcc2Mailbox[dst_cta_id](local_q_idx), dsmem_acc2_mailbox_full_barrier_addr[dst_cta_id]);
      }
    }

    // signal the mma warp tcgen05.ld of bmm2 is done, can start deallocate all tmem
    tmem_allocation_barrier.arrive();
  }

  // only NumReductionCTA number of reduction ctas will do the reduction
  if (rank < NumReductionCTA) {
    // handle oob when NumSplits < MaxSplits
    // doing computation on MaxSplits is faster than doing NumSplits with if statement
    clear(rBeta);

    if constexpr (!NoSink) {
      // wait for cp.async of sink tensor to finish
      if (tid < size(sSink)) {
        cp_async_fence();
        cp_async_wait<0>();
      }
      // make the sink tensor visible to all threads in the epilog warp
      epilog_barrier.arrive_and_wait();
    }

    // the reduction cta wait for st.async of fmax and fsum to finish
    int maxsum_mailbox_full_barrier_phase_bit = 0;
    wait_barrier(shared_storage.maxsum_mailbox_full_barrier, maxsum_mailbox_full_barrier_phase_bit);

    //if (elect_one_sync() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    //  printf("[Reduction] barrier full\n");
    //}

    // every thread redundantly calculates cluster wide fmax for (CTA_qHLocal * CTA_qL / NumReductionCTA) q tokens
    CUTE_UNROLL
    for (int i = 0; i < rFmaxCluster.size(); i++) {
      // cache the mailbox tensor in rmem to hide ld.shared latency, if we demand load ld.shared, its latency will hurt pipelining/unrolling amount
      // so we manually pipeline the ld.shared first and do all the operation on rmem, 
      // this is similar to sw pipelining but we do it manually because compiler is not smart enough to figure it out
      // instruction sequencing is important because we are an in-order issue machine, meaning stall of current instruction issue will block all subsequent instruction issue
      // many times compiler is not smart enough to do it, so you need to write the code in the right order to help it
      Tensor rFmaxMailbox = make_tensor<TypeAcc>(Int<MaxSplits>{});
      copy(sFmaxMailbox(_,i), rFmaxMailbox);

      Tensor rFsumMailbox = make_tensor<TypeAcc>(Int<MaxSplits>{});
      copy(sFsumMailbox(_,i), rFsumMailbox);

      rFmaxCluster(i) = rFmaxMailbox(0);

      CUTE_UNROLL
      for (int j = 1; j < MaxSplits; j++) {
        rFmaxCluster(i) = reduce_op<ReduceOp::Max>(rFmaxCluster(i), rFmaxMailbox(j));
      }

      // after fmax is done, we can do beta and fsum calculation
      // 2 optimizations we are doing:
      //   1. if we put NumSplits in the trip count, this makes it into a dynamic loop, and the index j into rBeta becomes a dynamic index
      //      but rBeta is in RF which doesn't support dynamic indexing, so the compiler will put it onto the stack (local memory) instead and generate ld.local/st.local instructions
      //      we want to keep rBeta in RF to avoid the local memory access, so we put MaxSplits in the trip count 
      //   2. we don't use predication of if statement to avoid the access when j >= NumSplits, instead we set the remainder sum/max value to 0 and inf and loop over MaxSplits
      //      when we use predicate, compiler will generate branch instruction which prevents the loop from doing more software pipelining, i.e. overlapping independent instructions
      //      from different iterations
      TypeAcc acc = 0.0f;
      CUTE_UNROLL
      for (int j = 0; j < MaxSplits; j++) {
        rBeta(i, j) = exp2f(rFmaxMailbox(j) - rFmaxCluster(i));
        acc += rBeta(i, j) * rFsumMailbox(j);
      }
      rFsumCluster(i) = acc;
      if constexpr (!NoSink) {
        rFsumCluster(i) += exp2f(sSink(i) * Log2_E - rFmaxCluster(i));
      }
    }

    if (tid < CTA_dH) {
      // initial phase bit for acc2_mailbox_full_barrier is 0
      // it is flipped to 1 when the acc2 st.async are done, and now we can start the reduction
      int acc2_mailbox_full_barrier_phase_bit = 0;
      // wait for the acc2 st.async to finish
      wait_barrier(shared_storage.acc2_mailbox_full_barrier, acc2_mailbox_full_barrier_phase_bit);

      // now we can do the reduction, reduce across Acc2 of all splits
      CUTE_UNROLL
      for (int i = 0; i < tAcc2rO.size(); i++) {
        TypeAcc acc = 0.0f;
        CUTE_UNROLL
        for (int j = 0; j < MaxSplits; j++) {
          acc += rBeta(i, j) * sAcc2Mailbox(tid, i, j);
        }
        // o = o / l_i
        tAcc2rO(i) = acc / rFsumCluster(i);
      }

      // convert from fp32 to bf16
      CUTE_UNROLL
      for (int i = 0; i < tAcc2rO.size(); i++) {
        tAcc2rO_converted(i) = converter_o(tAcc2rO(i));
      }

      // rmem -> gmem
      copy(tAcc2rO_converted, tCTAgO(tid, _));
    }
  }

  // debug
  /*epilog_barrier.arrive_and_wait();
  if ((tid == 0) && (blockIdx.x == 15) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    int example_row = 0;

    //print("sAcc1:\t"); print(sAcc1); print("\n"); // s = q * k * softmax_scale_log2
    print("tDrFmax:\t"); print_tensor(tDrFmax); print("\n"); // m_ij = fmax(s)
    print("tDrS:\t"); print_tensor(tDrS); print("\n"); // p = exp2f(s - m_ij)
    print("tDrFsum:\t"); print_tensor(tDrFsum); print("\n"); // l_ij = sum(p)
    print("tDrS_converted:\t"); print_tensor(tDrS_converted); print("\n");
    print("sS:\t"); print_tensor(sS(example_row,_,0)); print("\n");

    Tensor sP = shared_storage.tensor_sP(); // ((CTA_qHLocal, CTA_qL), CTA_kvL, BMM2_DMA_Stage)
    print("sP:\t"); print_tensor(sP(_,example_row,0)); print("\n");

    print("tAcc2rAcc2:\t"); print_tensor(tAcc2rAcc2); print("\n");

    print("sFmaxMailbox: "); print_tensor(sFmaxMailbox); print("\n");
    print("sFsumMailbox: "); print_tensor(sFsumMailbox); print("\n");
    print("rFmaxCluster: "); print_tensor(rFmaxCluster); print("\n");
    print("rBeta: "); print_tensor(rBeta); print("\n");
    print("rFsumCluster: "); print_tensor(rFsumCluster); print("\n");

    print("sAcc2Mailbox: "); print_tensor(sAcc2Mailbox(example_row,_,_)); print("\n");
    print("tAcc2rO: "); print_tensor(tAcc2rO); print("\n");
    print("tAcc2rO_converted: "); print_tensor(tAcc2rO_converted); print("\n");
    print("gO: "); print_tensor(gO(example_row,_)); print("\n");
  }*/
}

// K has shape (kvL, dH, kvH, BS)
// Q has shape ((qHLocal, qL), dH, kvH, BS)
// V has shape (dH, kvL, kvH, BS)
// O has shape (dH, (qHLocal, qL), kvH, BS)
// sinks has shape ((qHLocal, qL), kvH)
// seq_len has shape (BS)
template <
  class SharedStorage,
  class KTensor, class QTensor, class VTensor, class OTensor, class SinkTensor,
  class TmaAtomK, class TmaAtomQ, class TmaAtomV,
  class TiledBMM1, class TiledBMM2,
  class TypeAcc,
  int CTA_qHLocal, int CTA_qL, int CTA_kvL, int CTA_dH,
  int BMM1_DMA_Stage, int BMM2_DMA_Stage,
  int MaxSplits, int NumReductionCTA,
  bool NoSink>
__maxnreg__(128)
__global__ void 
gqa_device(
  KTensor mK,
  QTensor mQ,
  VTensor mV,
  OTensor mO,
  SinkTensor mSink,
  int* seq_lens,
  CUTE_GRID_CONSTANT TmaAtomK const tma_atom_K,
  CUTE_GRID_CONSTANT TmaAtomQ const tma_atom_Q,
  CUTE_GRID_CONSTANT TmaAtomV const tma_atom_V,
  TiledBMM1 tiled_bmm1,
  TiledBMM2 tiled_bmm2,
  float softmax_scale_log2,
  int sliding_window_size,
  int pdl_count
) {
  //if (threadIdx.x == 0) {
  //    printf("[%d, %d, %d] gqa_device\n", blockIdx.x, blockIdx.y, blockIdx.z);
  //}

  // Allocate SMEM
  extern __shared__ char shared_memory[];
  SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(shared_memory);

  // WorkTileInfo, for non persistent static scheduler, cta id is the work tile info
  // since loading the seq_lens is on the critical path of the prolog, we want to start it as soon as possible
  int kvH = shape<2>(mK);
  int BS_idx = blockIdx.x / kvH;
  // only thread 0 issues cp.async to load the seq_len
  if (threadIdx.x == 0) {
    cp_async(&seq_lens[BS_idx], &shared_storage.seq_len);
  }

  //if (threadIdx.x == 0) {
  //  printf("[%d, %d, %d] work_tile_info: %d, %d, %d, %d, %d\n", blockIdx.x, blockIdx.y, blockIdx.z, work_tile_info.BS_idx, work_tile_info.kvH_idx, work_tile_info.kvL_idx_start, work_tile_info.kvL_idx_end, work_tile_info.dH_idx, work_tile_info.qHLocal_idx, work_tile_info.qL_idx);
  //}

  int warp_idx = cutlass::canonical_warp_idx_sync();

  // barrier initialization, warp 0 does initialization
  if (warp_idx == 0) {
    // transaction barrier because tma arrive on it, 6 thread arrive: one for DMA_Q warp, one for DMA_KV (K fetch) warp, and 4 for softmax warp (tcgen05.ld Acc1 is done)
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
    // 1 thread (epilog) arrive to signal maxsum
    cutlass::arch::detail::initialize_barrier_array_aligned<cutlass::arch::ClusterTransactionBarrier, 1>(&shared_storage.maxsum_mailbox_full_barrier, /* arrival count */ 1);
    // 1 thread (epilog) arrive to signal acc2
    cutlass::arch::detail::initialize_barrier_array_aligned<cutlass::arch::ClusterTransactionBarrier, 1>(&shared_storage.acc2_mailbox_full_barrier, /* arrival count */ 1);
  }
  // Sync tmem allocation status between MMA and softmax/epilogue warps within CTA
  // 32 threads (mma) + 128 threads (epilog) to sync
  // also used for tmem deallocation between epilog warps and mma warps within CTA
  cutlass::arch::NamedBarrier tmem_allocation_barrier(32 + 128, cutlass::arch::ReservedNamedBarriers::TmemAllocBarrier);
  // syncing all threads (128) within 4 epilog warps
  cutlass::arch::NamedBarrier epilog_barrier(128, cutlass::arch::ReservedNamedBarriers::EpilogueBarrier);

  /*if (thread0() && (blockIdx.x == 0) && (blockIdx.y == 0) && (blockIdx.z == 0)) {
    Tensor tCsK = shared_storage.tensor_sK();         // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
    Tensor tCsQ = shared_storage.tensor_sQ();         // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
    Tensor tCsV = shared_storage.tensor_sV();         // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
    Tensor sS = shared_storage.tensor_sS();           // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1)
    Tensor sP = shared_storage.tensor_sP();           // ((CTA_qHLocal, CTA_qL), CTA_kvL, 1)

    printf("tCsK:\t"); print(tCsK); print("\n");
    printf("tCsQ:\t"); print(tCsQ); print("\n");
    printf("tCsV:\t"); print(tCsV); print("\n");
    printf("sS:\t"); print(sS); print("\n");
    printf("sP:\t"); print(sP); print("\n");
  }*/

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
  // so if we have (2, 4) shape (qHLocal, qL) cta, we do the following mapping from linear cta id to 2d id
  // 0 -> (0, 0)
  // 1 -> (1, 0)
  // 2 -> (0, 1)
  // 3 -> (1, 1)
  // 4 -> (0, 2)
  // 5 -> (1, 2)
  // 6 -> (0, 3)
  // 7 -> (1, 3)
  int qHLocal = shape<0>(shape<0>(mQ));
  int num_qHLocal = cutlass::ceil_div(qHLocal, CTA_qHLocal);
  // bid.z is the split id for kvL split, try to evenly distribute the kvL blocks to every CTA
  int rank = blockIdx.z;
  int seq_len = shared_storage.seq_len;
  // Sliding window optimization: when enabled, we only process tokens in range
  // [seq_len - sliding_window_size, seq_len). To simplify tile distribution,
  // we align the skip boundary to CTA_kvL tiles.
  //
  // Example with seq_len=100, sliding_window_size=30, CTA_kvL=16:
  //   - Tokens we care about: [70, 100)
  //   - Skip offset aligned to tiles: floor(70 / 16) * 16 = 64
  //   - Workload range: [64, 100), length = 36
  //   - Tiles to process: ceil(36 / 16) = 3 tiles
  int workload_seq_len = seq_len;
  int seq_len_skip_offset = 0;  // Number of sequence positions to skip (tile-aligned)
  if (sliding_window_size > 0 && sliding_window_size < seq_len) {
    int unaligned_skip = seq_len - sliding_window_size;
    seq_len_skip_offset = (unaligned_skip / CTA_kvL) * CTA_kvL;  // Align to tile boundary
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
    DMA_Q_warp<SharedStorage, WorkTileInfo, decltype(mQ), TmaAtomQ, TiledBMM1, CTA_qHLocal, CTA_qL, CTA_dH>(shared_storage, work_tile_info, mQ, &tma_atom_Q, tiled_bmm1);
  } 
  else if (warp_idx == 1) {
    DMA_KV_warp<SharedStorage, WorkTileInfo, decltype(mK), decltype(mV), TmaAtomK, TmaAtomV, TiledBMM1, TiledBMM2, CTA_kvL, CTA_dH>(shared_storage, work_tile_info, mK, mV, &tma_atom_K, &tma_atom_V, tiled_bmm1, tiled_bmm2);
  } 
  else if (warp_idx == 2) {
    MMA_warp<SharedStorage, WorkTileInfo, decltype(mO), TiledBMM1, TiledBMM2, CTA_qHLocal, CTA_qL, CTA_kvL, CTA_dH>(shared_storage, work_tile_info, mO, tiled_bmm1, tiled_bmm2, tmem_allocation_barrier);
  } 
  else if (warp_idx >= 4) {
    // epilog tid is from 128 to 255, need to offset by -128 when getting the per thread slice
    int tid = threadIdx.x - 128;
    // warp_idx - 4 because epilog warp group starts from warp 4
    EPILOG_warp<SharedStorage, WorkTileInfo, decltype(mK), decltype(mO), decltype(mSink), TiledBMM1, TiledBMM2, CTA_qHLocal, CTA_qL, CTA_kvL, CTA_dH, NumReductionCTA, NoSink>(shared_storage, work_tile_info, mK, mO, mSink, seq_len, tiled_bmm1, tiled_bmm2, softmax_scale_log2, sliding_window_size, tmem_allocation_barrier, epilog_barrier, NumSplits, tid, warp_idx - 4, rank);
  }

  __syncthreads();
}

// K has shape (kvL, dH, kvH, BS)
// Q has shape ((qHLocal, qL), dH, kvH, BS)
// V has shape (dH, kvL, kvH, BS)
// O has shape (dH, (qHLocal, qL), kvH, BS)
// kvL is max_seq_len, seq_lens[BS] is the actual seq len for each batch
// sinks has shape (qHLocal * kvH), i.e. one sink per q head, when device_ptr_sinks is nullptr, it's disabled
// sliding_window_size is the size of the sliding window, when it's 0, it's disabled
template<
  class TypeQKV, class TypeO, class TypeAcc,
  int CTA_qHLocal, int CTA_qL, int CTA_kvL, int CTA_dH,
  int BMM1_DMA_Stage, int BMM2_DMA_Stage,
  int MaxSplits, int NumReductionCTA>
void gqa_host(
  TypeQKV* device_ptr_K,
  TypeQKV* device_ptr_Q,
  TypeQKV* device_ptr_V,
  TypeO* device_ptr_O,
  int* seq_lens,
  TypeAcc* device_ptr_sinks,
  int kvH, int qHLocal, int qL, int kvL, int dH, int BS,
  int stride_K_kvH, int stride_K_kvL, int stride_K_dH, int stride_K_BS,
  int stride_Q_kvH, int stride_Q_qHLocal, int stride_Q_qL, int stride_Q_dH, int stride_Q_BS,
  int stride_V_kvH, int stride_V_kvL, int stride_V_dH, int stride_V_BS,
  int stride_O_kvH, int stride_O_qHLocal, int stride_O_qL, int stride_O_dH, int stride_O_BS,
  float softmax_scale,
  int sliding_window_size,
  bool pdl, int pdl_count = -1,
  cudaStream_t stream = 0
) {
  Layout layout_K = make_layout_K(kvH, kvL, dH, BS, stride_K_kvH, stride_K_kvL, stride_K_dH, stride_K_BS);
  Layout layout_Q = make_layout_Q(kvH, qHLocal, qL, dH, BS, stride_Q_kvH, stride_Q_qHLocal, stride_Q_qL, stride_Q_dH, stride_Q_BS);
  Layout layout_V = make_layout_V(kvH, kvL, dH, BS, stride_V_kvH, stride_V_kvL, stride_V_dH, stride_V_BS);
  Layout layout_O = make_layout_O(kvH, qHLocal, qL, dH, BS, stride_O_kvH, stride_O_qHLocal, stride_O_qL, stride_O_dH, stride_O_BS);
  Layout layout_sinks = make_layout_sinks(qHLocal, qL, kvH);

  // how we handle oob:
  //   oob for K, Q, V are handled by TMA
  //   oob for O is explicitly handled by predicate in the epilog since it uses simple st.global epilog
  // we partition kvL with tile size of CTA_kvL, and we evenly distribute the kvL blocks to MaxSplits number of cta in the cluster
  assert(NumReductionCTA <= MaxSplits);
  static_assert(((CTA_qHLocal * CTA_qL) % NumReductionCTA) == 0, "each reduction cta must have even number of q tokens");

  //printf("Running for problem shape (kvH x qHLocal x qL x kvL x dH x BS): %d x %d x %d x %d x %d x %d\n", kvH, qHLocal, qL, kvL, dH, BS);
  //printf("with tile size CTA_qHLocal: %d, CTA_qL: %d, CTA_kvL: %d, CTA_dH: %d\n", CTA_qHLocal, CTA_qL, CTA_kvL, CTA_dH);
  //printf("layout_K: "); print(layout_K); printf("\n");
  //printf("layout_Q: "); print(layout_Q); printf("\n");
  //printf("layout_V: "); print(layout_V); printf("\n");
  //printf("layout_O: "); print(layout_O); printf("\n");

  // create the cute tensor
  Tensor mK = make_tensor(make_gmem_ptr(device_ptr_K), layout_K); // (kvL, dH, kvH, BS)
  Tensor mQ = make_tensor(make_gmem_ptr(device_ptr_Q), layout_Q); // ((qHLocal, qL), dH, kvH, BS)
  Tensor mV = make_tensor(make_gmem_ptr(device_ptr_V), layout_V); // (dH, kvL, kvH, BS)
  Tensor mO = make_tensor(make_gmem_ptr(device_ptr_O), layout_O); // (dH, (qHLocal, qL), kvH, BS)
  Tensor mSink = make_tensor(make_gmem_ptr(device_ptr_sinks), layout_sinks); // ((qHLocal, qL), kvH)

  //printf("mK: "); print(mK); printf("\n");
  //printf("mQ: "); print(mQ); printf("\n");
  //printf("mV: "); print(mV); printf("\n");
  //printf("mO: "); print(mO); printf("\n");
  //printf("mSink: "); print(mSink); printf("\n");

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

  // We can also print and inspect the tiled_mma
  //print(tiled_bmm1);
  //print(tiled_bmm2);

  // Pre-partitioned smem Tile Shape to post-partitioned smem tile shape ((Mma_M, Mma_K), NumMma_M, NumMma_K, DMA_Stage)
  // bmm1 has BMM1_DMA_Stage stage
  // tile K shape is (CTA_kvL, CTA_dH, BMM1_DMA_Stage) and is the A operand
  // tile Q shape is ((CTA_qHLocal, CTA_qL), CTA_dH, 1) and is the B operand, because all K tiles share the same Q tiles, we only have 1 stage of Q tiles
  // tile S shape is (CTA_kvL, (CTA_qHLocal, CTA_qL), 1) and is the C operand
  auto shape_K = make_shape(Int<CTA_kvL>{}, Int<CTA_dH>{}, Int<BMM1_DMA_Stage>{});
  auto shape_Q = make_shape(make_shape(Int<CTA_qHLocal>{}, Int<CTA_qL>{}), Int<CTA_dH>{}, Int<1>{});
  auto shape_S = make_shape(Int<CTA_kvL>{}, make_shape(Int<CTA_qHLocal>{}, Int<CTA_qL>{}), Int<1>{});
  auto mma_shape_K = partition_shape_A(tiled_bmm1, shape_K);
  auto mma_shape_Q = partition_shape_B(tiled_bmm1, shape_Q);

  // bmm2 has 1 stage because we explicitly only has 1 kvL tile
  // tile V shape is (CTA_dH, CTA_kvL, BMM2_DMA_Stage) and is the A operand
  // tile P shape is ((CTA_qHLocal, CTA_qL), CTA_kvL, 1) and is the B operand, since 1 P tile is enough to overlap MMA with softmax
  auto shape_V = make_shape(Int<CTA_dH>{}, Int<CTA_kvL>{}, Int<BMM2_DMA_Stage>{});
  auto shape_P = select<1, 0, 2>(shape_S); // just a permutation of shape_S
  auto mma_shape_V = partition_shape_A(tiled_bmm2, shape_V);

  // Print and inspect shapes for this example. note that this is only the shape of the smem tile, not the actual smem layout
  //print("shape_K: "); print(shape_K); print("\n");
  //print("shape_Q: "); print(shape_Q); print("\n");
  //print("shape_S: "); print(shape_S); print("\n");
  //print("shape_V: "); print(shape_V); print("\n");
  //print("shape_P: "); print(shape_P); print("\n");
  //print("mma_shape_K: "); print(mma_shape_K); print("\n");
  //print("mma_shape_Q: "); print(mma_shape_Q); print("\n");
  //print("mma_shape_V: "); print(mma_shape_V); print("\n");

  // choose the swizzle atom for K, Q, S, V and P
  // for bmm1, both K and Q are dH (K in gemm terminology) major
  // and S is M major, none of the swizzle layout gives bank conflict free store to smem for S, 
  // swizzle 64B/128B should give at most 2-way bank conflict which is good enough since the output tile is small
  auto SmemLayoutAtomK = cutlass::gemm::collective::detail::sm100_smem_selector<
                              cute::UMMA::Major::K,                     // gmem layout of K
                              TypeQKV,                                  // data type of K
                              decltype(shape<0>(shape_K)), decltype(shape<1>(shape_K))>();  // tile size of K
  auto SmemLayoutAtomQ = cutlass::gemm::collective::detail::sm100_smem_selector<
                              cute::UMMA::Major::K,                     // gmem layout of Q
                              TypeQKV,                                  // data type of Q
                              decltype(shape<0>(shape_Q)), decltype(shape<1>(shape_Q))>();  // tile size of Q
  // we use TypeQKV because we don't actually want to store the bf32 output to smem, we do the softmax and quantize it to bf16 and then store it as P
  // hence the smem layout atom should reflect the bf16 precision
  // for bmm1 tcgen05.ld, each register is holding a row of S (CTA_kvL is mapped to the thread dimension), if we do st.shared from rmem to smem, to avoid bank conflict, we need to put T0V0, T1V0, T2V0, ... T31V0 contiguously in smem
  // then the smem layout of S is M (CTA_kvL) major, so we choose MN major swizzle atom
  auto SmemLayoutAtomS = UMMA::Layout_MN_SW128_Atom<TypeQKV>{};

  // for bmm2, V is dH (M in gemm terminology) major, P is CTA_kvL (K in gemm terminology) major
  auto SmemLayoutAtomV = cutlass::gemm::collective::detail::sm100_smem_selector<
                              cute::UMMA::Major::MN,                    // gmem layout of V
                              TypeQKV,                                  // data type of V
                              decltype(shape<0>(shape_V)), decltype(shape<1>(shape_V))>();  // tile size of V
  // swizzle atom for P should be the transpose of the swizzle atom for S, because they literally represent the same tensor just with different dimension order (aka a pytorch transpose)
  auto SmemLayoutAtomP = UMMA::Layout_K_SW128_Atom<TypeQKV>{};

  // Print and inspect SmemLayoutAtomK, SmemLayoutAtomQ, SmemLayoutAtomS, SmemLayoutAtomV, and SmemLayoutAtomP for this example.
  //print("SmemLayoutAtomK: "); print(SmemLayoutAtomK); print("\n");
  //print("SmemLayoutAtomQ: "); print(SmemLayoutAtomQ); print("\n");
  //print("SmemLayoutAtomS: "); print(SmemLayoutAtomS); print("\n");
  //print("SmemLayoutAtomV: "); print(SmemLayoutAtomV); print("\n");
  //print("SmemLayoutAtomP: "); print(SmemLayoutAtomP); print("\n");

  // finally construct the smem layout for tile K, Q, V, S, and P
  auto sK_layout = UMMA::tile_to_mma_shape(SmemLayoutAtomK, mma_shape_K); // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM1_DMA_Stage)
  auto sQ_layout = UMMA::tile_to_mma_shape(SmemLayoutAtomQ, mma_shape_Q); // ((Mma_N, Mma_K), NumMma_N, NumMma_K, 1)
  auto sV_layout = UMMA::tile_to_mma_shape(SmemLayoutAtomV, mma_shape_V); // ((Mma_M, Mma_K), NumMma_M, NumMma_K, BMM2_DMA_Stage)
  // S and P use tile_to_shape as we do the mma partition in the kernel later
  // here we use Step to enforce same swizzle atom stacking order for S and P, 
  // with Step<_1, _2, _3>, basically we say the swizzle atom is first stacked along the first dimension (CTA_kvL), then the second dimension ((CTA_qHLocal, CTA_qL)), then the third dimension (1)
  auto sS_layout = tile_to_shape(SmemLayoutAtomS, shape_S, Step<_1, _2, _3>{}); // (CTA_kvL, (CTA_qHLocal, CTA_qL), 1)
  // with Step<_2, _1, _3>, basically we say the swizzle atom is first stacked along the second dimension (CTA_kvL), then the first dimension ((CTA_qHLocal, CTA_qL)), then the third dimension (1)
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

  // Print and inspect sK_layout, sQ_layout, sV_layout, and sP_layout for this example.
  //print("sK_layout: "); print(sK_layout); print("\n");
  //print("sQ_layout: "); print(sQ_layout); print("\n");
  //print("sV_layout: "); print(sV_layout); print("\n");
  //print("sS_layout: "); print(sS_layout); print("\n");
  //print("sP_layout: "); print(sP_layout); print("\n");
  //print("sAcc1_layout: "); print(sAcc1_layout); print("\n");
  //print("sWarpReduce_layout: "); print(sWarpReduce_layout); print("\n");
  //print("sMSMailbox_Layout: "); print(sMSMailbox_Layout); print("\n");
  //print("sAcc2Mailbox_layout: "); print(sAcc2Mailbox_layout); print("\n");

  // Now we can find the SMEM allocation size
  using SMEMStorage = SharedStorage<TypeQKV, TypeAcc, decltype(sK_layout), decltype(sQ_layout), decltype(sV_layout), decltype(sS_layout), decltype(sP_layout), decltype(sWarpReduce_layout), decltype(sMSMailbox_Layout), decltype(sAcc1_layout), decltype(sAcc2Mailbox_layout), decltype(sSinks_layout), BMM1_DMA_Stage, BMM2_DMA_Stage>;

  static_assert(BMM1_DMA_Stage >= BMM2_DMA_Stage, "otherwise you are wasting BMM2 stage because BMM1 TMA issue will block BMM2 TMA due to insufficient BMM1 stages");

  // create TMA descriptors for K, Q, V, and P matrices
  Copy_Atom tma_atom_K = make_tma_atom(
    SM90_TMA_LOAD{},                              // TMA Load Op, sm100 reuses sm90 tma atom
    mK,                                           // Source GMEM tensor
    take<0, 3>(sK_layout),                        // Destination SMEM layout for 1 DMA_Stage, ((Mma_M, Mma_K), NumMma_M, NumMma_K)
    make_shape(get<0>(shape_K), get<1>(shape_K))  // TMA box shape, it's cosize must match the cosize of the destination smem layout
  );
  // this is an arithmetic tuple, denoting the coordinate of the top-left corner of the TMA box
  Tensor mK_tma = tma_atom_K.get_tma_tensor(shape(mK));   // (kvL, dH, kvH, BS)
  //print("tma_atom_K:\t"); print(tma_atom_K); print("\n");
  //print("mK_tma:\t"); print(mK_tma); print("\n");

  Copy_Atom tma_atom_Q = make_tma_atom(
    SM90_TMA_LOAD{},                              // TMA Load Op, sm100 reuses sm90 tma atom
    mQ,                                           // Source GMEM tensor
    // sQ_layout(_,_,_,Int<0>{}) doesn't work
    // basically under some corner cases, composedlayout indexing is incorrectly implemented, so we use the take method which is also correct
    take<0, 3>(sQ_layout),                        // Destination SMEM layout for 1 DMA_Stage, ((Mma_N, Mma_K), NumMma_N, NumMma_K)
    make_shape(get<0>(shape_Q), get<1>(shape_Q))  // TMA box shape, it's cosize must match the cosize of the destination smem layout
  );
  // this is an arithmetic tuple, denoting the coordinate of the top-left corner of the TMA box
  Tensor mQ_tma = tma_atom_Q.get_tma_tensor(shape(mQ));   // ((qHLocal, qL), dH, kvH, BS)
  //print("tma_atom_Q:\t"); print(tma_atom_Q); print("\n");
  //print("mQ_tma:\t"); print(mQ_tma); print("\n");

  Copy_Atom tma_atom_V = make_tma_atom(
    SM90_TMA_LOAD{},                              // TMA Load Op, sm100 reuses sm90 tma atom
    mV,                                           // Source GMEM tensor
    take<0, 3>(sV_layout),                        // Destination SMEM layout for 1 DMA_Stage, ((Mma_M, Mma_K), NumMma_M, NumMma_K)
    make_shape(get<0>(shape_V), get<1>(shape_V))  // TMA box shape, it's cosize must match the cosize of the destination smem layout
  );
  // this is an arithmetic tuple, denoting the coordinate of the top-left corner of the TMA box
  Tensor mV_tma = tma_atom_V.get_tma_tensor(shape(mV));   // (dH, kvL, kvH, BS)
  //print("tma_atom_V:\t"); print(tma_atom_V); print("\n");
  //print("mV_tma:\t"); print(mV_tma); print("\n");

  int smemBytes = sizeof(SMEMStorage);

  // print smemBytes
  //printf("smemBytes: %d\n", smemBytes);

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
      &gqa_device<SMEMStorage, decltype(mK_tma), decltype(mQ_tma), decltype(mV_tma), decltype(mO), decltype(mSink),
                  decltype(tma_atom_K), decltype(tma_atom_Q), decltype(tma_atom_V),
                  decltype(tiled_bmm1), decltype(tiled_bmm2),
                  TypeAcc,
                  CTA_qHLocal, CTA_qL, CTA_kvL, CTA_dH,
                  BMM1_DMA_Stage, BMM2_DMA_Stage,
                  MaxSplits, NumReductionCTA,
                  false>;
    gpuErrChk(cudaFuncSetAttribute(*kernel_instance, cudaFuncAttributeMaxDynamicSharedMemorySize, smemBytes));
    // portable max cluster size is 8, but sm100a supports 16, need explicit opt in
    gpuErrChk(cudaFuncSetAttribute(*kernel_instance, cudaFuncAttributeNonPortableClusterSizeAllowed, 1));
    gpuErrChk(cudaLaunchKernelEx(&config, kernel_instance, mK_tma, mQ_tma, mV_tma, mO, mSink,
                                seq_lens,
                                tma_atom_K, tma_atom_Q, tma_atom_V,
                                tiled_bmm1, tiled_bmm2,
                                softmax_scale * Log2_E, sliding_window_size, pdl_count));
  } 
  else {
    auto *kernel_instance =
      &gqa_device<SMEMStorage, decltype(mK_tma), decltype(mQ_tma), decltype(mV_tma), decltype(mO), decltype(mSink),
                  decltype(tma_atom_K), decltype(tma_atom_Q), decltype(tma_atom_V),
                  decltype(tiled_bmm1), decltype(tiled_bmm2),
                  TypeAcc,
                  CTA_qHLocal, CTA_qL, CTA_kvL, CTA_dH,
                  BMM1_DMA_Stage, BMM2_DMA_Stage,
                  MaxSplits, NumReductionCTA,
                  true>;
    gpuErrChk(cudaFuncSetAttribute(*kernel_instance, cudaFuncAttributeMaxDynamicSharedMemorySize, smemBytes));
    // portable max cluster size is 8, but sm100a supports 16, need explicit opt in
    gpuErrChk(cudaFuncSetAttribute(*kernel_instance, cudaFuncAttributeNonPortableClusterSizeAllowed, 1));
    gpuErrChk(cudaLaunchKernelEx(&config, kernel_instance, mK_tma, mQ_tma, mV_tma, mO, mSink,
                                seq_lens,
                                tma_atom_K, tma_atom_Q, tma_atom_V,
                                tiled_bmm1, tiled_bmm2,
                                softmax_scale * Log2_E, sliding_window_size, pdl_count));
  }
}

} // namespace gqa
} // namespace TGV
