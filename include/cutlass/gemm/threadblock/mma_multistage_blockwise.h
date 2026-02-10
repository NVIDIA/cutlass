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

/*! \file
    \brief Template for a double-buffered threadblock-scoped GEMM kernel that performs blockwise 
    scaling dequantization in the MMA for input matrices A and B.
*/

#pragma once

#include "cutlass/aligned_buffer.h"
#include "cutlass/arch/memory.h"
#include "cutlass/array.h"
#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/threadblock/mma_base.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/numeric_types.h"
#include "cutlass/gemm/threadblock/mma_multistage.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace gemm {
namespace threadblock {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Structure to compute the matrix product targeting CUDA cores and SIMT math
/// instructions.
template <
    /// Size of the Gemm problem - concept: gemm::GemmShape<>
    typename Shape_,
    /// Iterates over tiles of A operand in global memory
    //  (concept: ReadableTileIterator | ForwardTileIterator |
    //  MaskedTileIterator)
    typename IteratorA_,
    /// Iterates over tiles of A operand in shared memory
    /// (concept: WriteableTileIterator | RandomAccessTileIterator)
    typename SmemIteratorA_,
    /// Cache operation for operand A
    cutlass::arch::CacheOperation::Kind CacheOpA,
    /// Iterates over tiles of B operand in global memory
    //  (concept: ReadableTileIterator | ForwardTileIterator |
    //  MaskedTileIterator)
    typename IteratorB_,
    /// Iterates over tiles of B operand in shared memory
    /// (concept: WriteableTileIterator | RandomAccessTileIterator)
    typename SmemIteratorB_,
    /// Cache operation for operand B
    cutlass::arch::CacheOperation::Kind CacheOpB,
    /// Data type of accumulator matrix
    typename ElementC_,
    /// Data type of accumulator matrix
    typename LayoutC_,
    /// Element Type for for the scalesl
    typename ElementScale_,
    /// Layout for the scales.
    typename LayoutScale_,
    /// Policy describing tuning details (concept: MmaPolicy)
    typename Policy_,
    /// Number of stages,
    int Stages,
    /// Use zfill or predicate for out-of-bound cp.async
    SharedMemoryClearOption SharedMemoryClear = SharedMemoryClearOption::kNone,
    /// Used for partial specialization
    typename Enable = bool>
class MmaMultistageBlockwise : public MmaMultistage<Shape_, IteratorA_, SmemIteratorA_, CacheOpA,
                                IteratorB_, SmemIteratorB_, CacheOpB,
                                ElementC_, LayoutC_, Policy_, Stages,
                                SharedMemoryClear, Enable> {
public:
  ///< Base class
  using Base = MmaMultistage<Shape_, IteratorA_, SmemIteratorA_, CacheOpA,
                            IteratorB_, SmemIteratorB_, CacheOpB,
                            ElementC_, LayoutC_, Policy_, Stages,
                            SharedMemoryClear, Enable>;
  ///< Size of the Gemm problem - concept: gemm::GemmShape<>
  using Shape = Shape_;
  ///< Iterates over tiles of A operand in global memory
  using IteratorA = IteratorA_;
  ///< Iterates over tiles of B operand in global memory
  using IteratorB = IteratorB_;
  ///< Data type of accumulator matrix
  using ElementC = ElementC_;
  ///< Layout of accumulator matrix
  using LayoutC = LayoutC_;
  /// Data type of scales
  using ElementScale = ElementScale_;
  /// Layout Type of Scales.
  using LayoutScale = LayoutScale_;
  ///< Policy describing tuning details
  using Policy = Policy_;

  using SmemIteratorA = SmemIteratorA_;
  using SmemIteratorB = SmemIteratorB_;

  static cutlass::arch::CacheOperation::Kind const kCacheOpA = CacheOpA;
  static cutlass::arch::CacheOperation::Kind const kCacheOpB = CacheOpB;

  //
  // Dependent types
  //

  /// Fragment of accumulator tile
  using FragmentC = typename Policy::Operator::FragmentC;

  /// Warp-level Mma
  using Operator = typename Policy::Operator;

  /// Minimum architecture is Sm80 to support cp.async
  using ArchTag = arch::Sm80;

  /// Complex transform on A operand
  static ComplexTransform const kTransformA = Operator::kTransformA;

  /// Complex transform on B operand
  static ComplexTransform const kTransformB = Operator::kTransformB;

  // Reference to the canonical MmaMultistage specialization with identical
  // template arguments.  This enables us to reuse its helper structures
  // (Detail and PipeState) without redefining them here.
  using BaseMma = MmaMultistage<Shape_, IteratorA_, SmemIteratorA_, CacheOpA,
                                IteratorB_, SmemIteratorB_, CacheOpB,
                                ElementC_, LayoutC_, Policy_, Stages,
                                SharedMemoryClear, Enable>;

  /// Internal structure exposed for introspection (aliased from BaseMma).
  using Detail = typename BaseMma::Detail;

  // Bring selected base-class helpers into scope so that calls like
  // advance_smem_read_stage() resolve correctly in a dependent-name
  // context where two-phase lookup would otherwise ignore the base
  // class.
  using Base::advance_smem_read_stage;
  using Base::advance_smem_write_stage;
  using Base::copy_tiles_and_advance;
  using Base::prologue;
  using Base::gmem_wait;
  using Base::wind_down;

private:
  // Pipeline state structure reused from the canonical multistage kernel.
  using PipeState = typename BaseMma::PublicPipeState;

private:
  //
  // Data members
  //

  /// Warp-level MMA operator
  Operator warp_mma_;

public:
  /// Construct from tensor references
  CUTLASS_DEVICE
  MmaMultistageBlockwise(
      ///< Shared storage needed for internal use by threadblock-scoped GEMM
      typename Base::SharedStorage &shared_storage,
      ///< ID within the threadblock
      int thread_idx,
      ///< ID of warp
      int warp_idx,
      ///< ID of each thread within a warp
      int lane_idx)
      : Base(shared_storage, thread_idx, warp_idx, lane_idx)
  {
    // All per-warp iterator adjustments are handled by the base-class
    // constructor, so no additional work is required here.
  }

  /// Perform a threadblock mainloop iteration of matrix multiply-accumulate
  CUTLASS_DEVICE
  void mac_loop_iter(
      PipeState &pipe_state, ///< [in|out] loop-carried pipeline state
      FragmentC &accum,      ///< [in|out] destination accumulator tile
      IteratorA &iterator_A, ///< [in|out] iterator over A operand in global memory
      IteratorB &iterator_B, ///< [in|out] iterator over B operand in global memory
      int &gemm_k_iterations,
      cutlass::TensorRef<ElementScale, LayoutScale> scale_A, // blockwise scale tensor for A
      cutlass::TensorRef<ElementScale, LayoutScale> scale_B,     // blockwise scale tensor for B
      int k_iter_idx,  ///< current K-block index processed by this iteration
      int block_m_idx, ///< threadblock index along M dimension (row)
      int block_n_idx) ///< threadblock index along N dimension (col)
  {
    // Unroll the warp-level MMA tiles of a threadblock's mainloop iteration
    CUTLASS_PRAGMA_UNROLL
    for (int warp_mma_k = 0; warp_mma_k < Base::kWarpGemmIterations;
         ++warp_mma_k) {

      //  Load the next warp-tile's A fragment from shared memory
      this->warp_tile_iterator_A_.set_kgroup_index((warp_mma_k + 1) % Base::kWarpGemmIterations);
      this->warp_tile_iterator_A_.load(pipe_state.warp_loaded_frag_A_[(warp_mma_k + 1) % 2]);
      ++this->warp_tile_iterator_A_;

      // Load the next warp-tile's B fragment from shared memory
      this->warp_tile_iterator_B_.set_kgroup_index((warp_mma_k + 1) % Base::kWarpGemmIterations);
      this->warp_tile_iterator_B_.load(pipe_state.warp_loaded_frag_B_[(warp_mma_k + 1) % 2]);
      ++this->warp_tile_iterator_B_;

      // Except for the first warp-tile, all warp-tiles convert their incoming shared memory fragments as necessary
      if (warp_mma_k > 0) {
        warp_mma_.transform(pipe_state.warp_transformed_frag_A_[warp_mma_k % 2],
            pipe_state.warp_transformed_frag_B_[warp_mma_k % 2],
            pipe_state.warp_loaded_frag_A_[warp_mma_k % 2],
            pipe_state.warp_loaded_frag_B_[warp_mma_k % 2]);
      }

      // Compute scale factor for the current (M-tile, N-tile, K-tile) triple.
      // The K-tile index used for scaling must not exceed the allocated range
      // of the scale tensors.  This situation can arise in the prologue /
      // epilogue iterations of the multistage pipeline when the software
      // pipeline executes Stages-1 extra iterations with gemm_k_iterations < 0.

      int ldA = int(scale_A.layout().stride(0));
      int k_block_idx = k_iter_idx;
      if (k_block_idx >= ldA) {
        k_block_idx = ldA - 1;
      }

      float scale_factor = scale_A.at({block_m_idx, k_block_idx}) *
                           scale_B.at({block_n_idx, k_block_idx});

      // Perform MMA into a temporary fragment (unscaled)
      FragmentC delta;
      FragmentC zero_frag;
      zero_frag.clear();

      warp_mma_(delta, pipe_state.warp_transformed_frag_A_[warp_mma_k % 2],
                pipe_state.warp_transformed_frag_B_[warp_mma_k % 2], zero_frag);

      // Apply dequantization scaling
      CUTLASS_PRAGMA_UNROLL
      for (int el = 0; el < FragmentC::kElements; ++el) {
        delta[el] *= scale_factor;
      }

      // Accumulate the scaled contribution
      plus<FragmentC> plus_accum;

      if (Detail::kStagedAccumulation) {
        pipe_state.tmp_accum_ = plus_accum(pipe_state.tmp_accum_, delta);

        if (warp_mma_k == 0) {
          accum = plus_accum(accum, pipe_state.tmp_accum_);
          pipe_state.tmp_accum_.clear();
        }
      } else {
        accum = plus_accum(accum, delta);
      }

      // Except for the last warp-tile, all warp-tiles issue their share of
      // global->shared fragment copies
      if (warp_mma_k < Base::kWarpGemmIterations - 1) {
        int group_start_iteration_A, group_start_iteration_B;
        group_start_iteration_A = warp_mma_k * Detail::kAccessesPerGroupA;
        group_start_iteration_B = warp_mma_k * Detail::kAccessesPerGroupB;

        copy_tiles_and_advance(iterator_A, iterator_B, group_start_iteration_A,
                               group_start_iteration_B);
      }

      // The second-to-last warp-tile also:
      //   - performs the last warp-tile's share of global->shared fragment
      //   copies
      //   - moves to the next global fetch stage
      if (warp_mma_k + 2 == Base::kWarpGemmIterations) {
        // Performs the last warp-tile's share of global->shared fragment copies
        int group_start_iteration_A =
            (warp_mma_k + 1) * Detail::kAccessesPerGroupA;
        int group_start_iteration_B =
            (warp_mma_k + 1) * Detail::kAccessesPerGroupB;

        copy_tiles_and_advance(iterator_A, iterator_B, group_start_iteration_A,
                               group_start_iteration_B);

        // Inserts a memory fence between stages of cp.async instructions.
        cutlass::arch::cp_async_fence();

        // Wait until we have at least one completed global fetch stage
        gmem_wait();

        // Move to the next global fetch stage
        advance_smem_write_stage(iterator_A, iterator_B);
        advance_smem_read_stage();

        // Disable global fetching when done with global fetch iterations
        --gemm_k_iterations;
        iterator_A.clear_mask(gemm_k_iterations == 0);
        iterator_B.clear_mask(gemm_k_iterations == 0);
      }

      // The last warp-tile also converts the shared memory fragments used by
      // the first warp-tile of the next iteration, if necessary (so we can
      // immediately start issuing MMA instructions at the top of the loop )
      if (warp_mma_k + 1 == Base::kWarpGemmIterations) {
        warp_mma_.transform(
            pipe_state.warp_transformed_frag_A_[(warp_mma_k + 1) % 2],
            pipe_state.warp_transformed_frag_B_[(warp_mma_k + 1) % 2],
            pipe_state.warp_loaded_frag_A_[(warp_mma_k + 1) % 2],
            pipe_state.warp_loaded_frag_B_[(warp_mma_k + 1) % 2]);
      }
    }
  }

  /// Perform the specified number of threadblock mainloop iterations of matrix
  /// multiply-accumulate.  Assumes prologue has been initiated.
  CUTLASS_DEVICE
  void gemm_iters(
      int gemm_k_iterations, ///< number of threadblock mainloop iterations
      FragmentC &accum,      ///< [in|out] accumulator tile
      IteratorA &iterator_A, ///< [in|out] iterator over A operand in global memory
      IteratorB &iterator_B,
      cutlass::TensorRef<ElementScale, LayoutScale> scale_A, // blockwise scale tensor for A
      cutlass::TensorRef<ElementScale, LayoutScale> scale_B, // blockwise scale tensor for B
      int block_m_idx,
      int block_n_idx) ///< [in|out] iterator over B operand in global memory
  {
    PipeState pipe_state;

    // Disable global fetching if done with global fetch iterations
    iterator_A.clear_mask(gemm_k_iterations == 0);
    iterator_B.clear_mask(gemm_k_iterations == 0);

    // Load first warp-tile's A fragment from shared memory
    this->warp_tile_iterator_A_.set_kgroup_index(0);
    this->warp_tile_iterator_A_.load(pipe_state.warp_loaded_frag_A_[0]);
    ++this->warp_tile_iterator_A_;

    // Load first warp-tile's B fragment from shared memory
    this->warp_tile_iterator_B_.set_kgroup_index(0);
    this->warp_tile_iterator_B_.load(pipe_state.warp_loaded_frag_B_[0]);
    ++this->warp_tile_iterator_B_;

    // Transform, if necessary, the first warp-tile's shared memory fragments
    warp_mma_.transform(pipe_state.warp_transformed_frag_A_[0],
                        pipe_state.warp_transformed_frag_B_[0],
                        pipe_state.warp_loaded_frag_A_[0],
                        pipe_state.warp_loaded_frag_B_[0]);

    if (Detail::kStagedAccumulation) {
      pipe_state.tmp_accum_.clear();
    }

    // Mainloop
    int k_iter_idx = 0;

    CUTLASS_GEMM_LOOP
    for (; gemm_k_iterations > (-Base::kStages + 1); ++k_iter_idx) {
      mac_loop_iter(pipe_state, accum, iterator_A, iterator_B,
                    gemm_k_iterations, scale_A, scale_B, k_iter_idx,
                    block_m_idx, block_n_idx);
    }

    if (Detail::kStagedAccumulation) {
      plus<FragmentC> plus_accum;
      accum = plus_accum(accum, pipe_state.tmp_accum_);
    }

    // Commit and drain all pending and predicated cp.async pnz from the GEMM
    // mainloop
    cutlass::arch::cp_async_fence();
    cutlass::arch::cp_async_wait<0>();
    __syncthreads();
  }

  /// Perform a threadblock-scoped matrix multiply-accumulate
  CUTLASS_DEVICE
  void operator()(
      ///< problem size of GEMM
      int gemm_k_iterations,
      ///< destination accumulator tile
      FragmentC &accum,
      ///< iterator over A operand in global memory
      IteratorA iterator_A,
      ///< iterator over B operand in global memory
      IteratorB iterator_B,
      ///< initial value of accumulator
      FragmentC const &src_accum,
      cutlass::TensorRef<ElementScale, LayoutScale> scaleA,
      cutlass::TensorRef<ElementScale, LayoutScale> scaleB) {
    // Each scale element corresponds to a 128x128 tile along (M, K) for A and
    // (N, K) for B. Grid dimension  X enumerates threadblock tiles along M and
    // grid dimension Y along N when GemmIdentityThreadblockSwizzle is used with
    // the default N = 1 (tile = 1). Therefore,
    //   blockIdx.x -> tile index along the M dimension
    //   blockIdx.y -> tile index along the N dimension.

    constexpr int kScaleBlock = 128;
    // Row-wise block index for A (and output C/D) – one per 128 rows.
    int block_m_idx = (blockIdx.x * Shape::kM) / kScaleBlock;

    // Column-wise block index for B – one per 128 columns.  Note that each
    // threadblock processes Shape::kN columns, which may be < 128 (64 in this
    // kernel).  We therefore map two consecutive threadblock tiles onto the
    // same 128-wide scale block when Shape::kN < kScaleBlock.
    int block_n_idx = (blockIdx.y * Shape::kN) / kScaleBlock;

    // Prologue (start fetching iterations of global fragments into shared
    // memory)
    prologue(iterator_A, iterator_B, gemm_k_iterations);

    // Wait until we have at least one completed global fetch stage
    gmem_wait();

    // Initialize destination accumulators with source accumulators
    accum = src_accum;

    // Perform the MAC-iterations with blockwise dequantization
    gemm_iters(gemm_k_iterations, accum, iterator_A, iterator_B, scaleA, scaleB,
               block_m_idx, block_n_idx);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace threadblock
} // namespace gemm
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
