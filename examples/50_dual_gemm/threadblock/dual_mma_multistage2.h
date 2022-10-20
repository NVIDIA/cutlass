/***************************************************************************************************
 * Copyright (c) 2017 - 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Template for a double-buffered threadblock-scoped GEMM kernel.
*/

#pragma once

#include "cutlass/aligned_buffer.h"
#include "cutlass/arch/memory.h"
#include "cutlass/array.h"
#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/numeric_types.h"

#include "cutlass/gemm/threadblock/mma_base.h"

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
    /// Policy describing tuning details (concept: MmaPolicy)
    typename Policy_,
    /// Number of stages,
    int Stages,
    /// Use zfill or predicate for out-of-bound cp.async
    SharedMemoryClearOption SharedMemoryClear = SharedMemoryClearOption::kNone,
    /// Used for partial specialization
    typename Enable = bool>
class DualMmaMultistage2 : 
  public MmaBase<Shape_, Policy_, Stages> {
public:
  ///< Base class
  using Base = MmaBase<Shape_, Policy_, Stages>;
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

  /// Internal structure exposed for introspection.
  struct Detail {

    /// Number of cp.async instructions to load one stage of operand A
    static int const AsyncCopyIterationsPerStageA =
        IteratorA::ThreadMap::Iterations::kCount;

    /// Number of cp.async instructions to load one stage of operand B
    static int const AsyncCopyIterationsPerStageB =
        IteratorB::ThreadMap::Iterations::kCount;

    /// Number of stages
    static int const kStages = Stages;

    /// Number of cp.async instructions to load on group of operand A
    static int const kAccessesPerGroupA =
        (AsyncCopyIterationsPerStageA + Base::kWarpGemmIterations - 1) / Base::kWarpGemmIterations;

    /// Number of cp.async instructions to load on group of operand B
    static int const kAccessesPerGroupB =
        (AsyncCopyIterationsPerStageB + Base::kWarpGemmIterations - 1) / Base::kWarpGemmIterations;
  };

 private:

  using WarpLoadedFragmentA = typename Operator::FragmentA;
  using WarpLoadedFragmentB = typename Operator::FragmentB;
  using WarpTransformedFragmentA = typename Operator::TransformedFragmentA;
  using WarpTransformedFragmentB = typename Operator::TransformedFragmentB;

 private:

  //
  // Data members
  //

  /// Iterator to write threadblock-scoped tile of A operand to shared memory
  SmemIteratorA smem_iterator_A_;

  /// Iterator to write threadblock-scoped tile of B operand to shared memory
  SmemIteratorB smem_iterator_B_;

public:

  /// Construct from tensor references
  CUTLASS_DEVICE
  DualMmaMultistage2(
      ///< Shared storage needed for internal use by threadblock-scoped GEMM
      typename Base::SharedStorage &shared_storage,
      ///< ID within the threadblock
      int thread_idx,
      ///< ID of warp
      int warp_idx,
      ///< ID of each thread within a warp
      int lane_idx
    ):
      Base(shared_storage, thread_idx, warp_idx, lane_idx),
      smem_iterator_A_(shared_storage.operand_A_ref(), thread_idx),
      smem_iterator_B_(shared_storage.operand_B_ref(), thread_idx)
  {
    // Compute warp location within threadblock tile by mapping the warp_id to
    // three coordinates:
    //   _m: the warp's position within the threadblock along the M dimension
    //   _n: the warp's position within the threadblock along the N dimension
    //   _k: the warp's position within the threadblock along the K dimension

    int warp_idx_mn = warp_idx % (Base::WarpCount::kM * Base::WarpCount::kN);
    int warp_idx_k = warp_idx / (Base::WarpCount::kM * Base::WarpCount::kN);

    int warp_idx_m = warp_idx_mn % Base::WarpCount::kM;
    int warp_idx_n = warp_idx_mn / Base::WarpCount::kM;

    // Add per-warp offsets in units of warp-level tiles
    this->warp_tile_iterator_A_.add_tile_offset(
        {warp_idx_m, Base::kWarpGemmIterations * warp_idx_k});
    this->warp_tile_iterator_B_.add_tile_offset(
        {Base::kWarpGemmIterations * warp_idx_k, warp_idx_n});
  }

  CUTLASS_DEVICE
  void copy_tiles_and_advance(IteratorA &iterator_A, IteratorB &iterator_B,
                              bool advanceA,
                              int group_start_A = 0, int group_start_B = 0) {
    if (advanceA) {
      iterator_A.set_iteration_index(group_start_A *
                                    IteratorA::kAccessesPerVector);
      this->smem_iterator_A_.set_iteration_index(group_start_A);

      // Async Copy for operand A
      CUTLASS_PRAGMA_UNROLL
      for (int j = 0; j < Detail::kAccessesPerGroupA; ++j) {
        if (group_start_A + j < Detail::AsyncCopyIterationsPerStageA) {
          typename IteratorA::AccessType *dst_ptr =
              reinterpret_cast<typename IteratorA::AccessType *>(
                  this->smem_iterator_A_.get());

          int const kSrcBytes = sizeof_bits<typename IteratorA::Element>::value *
                                IteratorA::ThreadMap::kElementsPerAccess /
                                IteratorA::kAccessesPerVector / 8;

          CUTLASS_PRAGMA_UNROLL
          for (int v = 0; v < IteratorA::kAccessesPerVector; ++v) {
            auto gmem_ptr = iterator_A.get();

            if (SharedMemoryClear == SharedMemoryClearOption::kZfill) {
              cutlass::arch::cp_async_zfill<kSrcBytes, kCacheOpA>(
                  dst_ptr + v, gmem_ptr, iterator_A.valid());
            } else {
              cutlass::arch::cp_async<kSrcBytes, kCacheOpA>(
                  dst_ptr + v, gmem_ptr, iterator_A.valid());
            }

            ++iterator_A;
          }

          ++this->smem_iterator_A_;
        }
      }
    }

    iterator_B.set_iteration_index(group_start_B *
                                   IteratorB::kAccessesPerVector);
    this->smem_iterator_B_.set_iteration_index(group_start_B);

    // Async Copy for operand B
    CUTLASS_PRAGMA_UNROLL
    for (int j = 0; j < Detail::kAccessesPerGroupB; ++j) {
      if (group_start_B + j < Detail::AsyncCopyIterationsPerStageB) {
        typename IteratorB::AccessType *dst_ptr =
            reinterpret_cast<typename IteratorB::AccessType *>(
                this->smem_iterator_B_.get());

        int const kSrcBytes = sizeof_bits<typename IteratorB::Element>::value *
                              IteratorB::ThreadMap::kElementsPerAccess /
                              IteratorB::kAccessesPerVector / 8;

        CUTLASS_PRAGMA_UNROLL
        for (int v = 0; v < IteratorB::kAccessesPerVector; ++v) {
          auto gmem_ptr = iterator_B.get();

          if (SharedMemoryClear == SharedMemoryClearOption::kZfill) {
            cutlass::arch::cp_async_zfill<kSrcBytes, kCacheOpB>(
                dst_ptr + v, gmem_ptr, iterator_B.valid());
          } else {
            cutlass::arch::cp_async<kSrcBytes, kCacheOpB>(
                dst_ptr + v, gmem_ptr, iterator_B.valid());
          }

          ++iterator_B;
        }
        ++this->smem_iterator_B_;
      }
    }
  }

  /// Perform a threadblock-scoped matrix multiply-accumulate
  CUTLASS_DEVICE
  void operator()(
      ///< problem size of GEMM
      int gemm_k_iterations,
      ///< destination accumulator tile
      FragmentC &accum0,
      ///< destination accumulator tile
      FragmentC &accum1,
      ///< iterator over A operand in global memory
      IteratorA iterator_A,
      ///< iterator over B operand in global memory
      IteratorB iterator_B0,
      IteratorB iterator_B1,
      ///< initial value of accumulator
      FragmentC const &src_accum0,
      ///< initial value of accumulator
      FragmentC const &src_accum1) {

    //
    // Prologue
    //

    int smemA_write_stage_idx = 0;
    int smemA_read_stage_idx = 0;
    int smemB_write_stage_idx = 0;
    int smemB_read_stage_idx = 0;
    // Issue several complete stages
    static_assert(Base::kStages % 2 == 1);
    constexpr int kNumPrologueIters = Base::kStages / 2;
    constexpr int kNumLoadsInFlight = kNumPrologueIters * 2;
    CUTLASS_PRAGMA_UNROLL
    for (int stage = 0; stage < kNumPrologueIters;
         ++stage, --gemm_k_iterations) {
      CUTLASS_PRAGMA_UNROLL
      for (int operandB = 0; operandB < 2; ++operandB) {
        const bool isLastOperandB = (operandB == 1);
        const bool isFirstOperandB = (operandB == 0);

        auto& iterator_B = operandB == 0 ? iterator_B0 : iterator_B1;

        iterator_A.clear_mask(gemm_k_iterations == 0);
        iterator_B.clear_mask(gemm_k_iterations == 0);

        iterator_A.set_iteration_index(0);
        this->smem_iterator_A_.set_iteration_index(0);

        // Async Copy for operand A
        if (isFirstOperandB) {
          CUTLASS_PRAGMA_UNROLL
          for (int j = 0; j < Detail::AsyncCopyIterationsPerStageA; ++j) {
            typename IteratorA::AccessType *dst_ptr =
                reinterpret_cast<typename IteratorA::AccessType *>(
                    this->smem_iterator_A_.get());

            CUTLASS_PRAGMA_UNROLL
            for (int v = 0; v < IteratorA::kAccessesPerVector; ++v) {
              int const kSrcBytes =
                  sizeof_bits<typename IteratorA::Element>::value *
                  IteratorA::ThreadMap::kElementsPerAccess /
                  IteratorA::kAccessesPerVector / 8;

              int src_bytes = (iterator_A.valid() ? kSrcBytes : 0);

              cutlass::arch::cp_async_zfill<kSrcBytes, kCacheOpA>(
                  dst_ptr + v, iterator_A.get(), iterator_A.valid());

              ++iterator_A;
            }

            ++this->smem_iterator_A_;
          }
        }

        iterator_B.set_iteration_index(0);
        this->smem_iterator_B_.set_iteration_index(0);

        // Async Copy for operand B
        CUTLASS_PRAGMA_UNROLL
        for (int j = 0; j < Detail::AsyncCopyIterationsPerStageB; ++j) {
          typename IteratorB::AccessType *dst_ptr =
              reinterpret_cast<typename IteratorB::AccessType *>(
                  this->smem_iterator_B_.get());

          CUTLASS_PRAGMA_UNROLL
          for (int v = 0; v < IteratorB::kAccessesPerVector; ++v) {
            int const kSrcBytes =
                sizeof_bits<typename IteratorB::Element>::value *
                IteratorB::ThreadMap::kElementsPerAccess /
                IteratorB::kAccessesPerVector / 8;

            cutlass::arch::cp_async_zfill<kSrcBytes, kCacheOpB>(
                dst_ptr + v, iterator_B.get(), iterator_B.valid());

            ++iterator_B;
          }

          ++this->smem_iterator_B_;
        }

        // Move to the next stage
        if (isLastOperandB) {
          iterator_A.add_tile_offset({0, 1});
          this->smem_iterator_A_.add_tile_offset({0, 1});
          ++smemA_write_stage_idx;
        }

        iterator_B.add_tile_offset({1, 0});
        this->smem_iterator_B_.add_tile_offset({1, 0});
        ++smemB_write_stage_idx;

        // Defines the boundary of a stage of cp.async.
        cutlass::arch::cp_async_fence();
      }
    }

    // Perform accumulation in the 'd' output operand
    FragmentC accum[2];
    accum[0] = src_accum0;
    accum[1] = src_accum1;

    static_assert(SharedMemoryClear != SharedMemoryClearOption::kClearLastStage, "Not supported");

    // Waits until stages up to the previous (kStages-2)th stage have committed.
    cutlass::arch::cp_async_wait<kNumLoadsInFlight - 1>();
    __syncthreads();

    // Pair of fragments used to overlap shared memory loads and math
    // instructions
    WarpLoadedFragmentA warp_loaded_frag_A[2];
    WarpLoadedFragmentB warp_loaded_frag_B[2];
    WarpTransformedFragmentA never_used_fragment;
    WarpTransformedFragmentA warp_transformed_frag_A[2];
    WarpTransformedFragmentB warp_transformed_frag_B[2];

    Operator warp_mma;

    this->warp_tile_iterator_A_.set_kgroup_index(0);
    this->warp_tile_iterator_B_.set_kgroup_index(0);

    this->warp_tile_iterator_A_.load(warp_loaded_frag_A[0]);
    this->warp_tile_iterator_B_.load(warp_loaded_frag_B[0]);

    ++this->warp_tile_iterator_A_;
    ++this->warp_tile_iterator_B_;

    iterator_A.clear_mask(gemm_k_iterations == 0);
    iterator_B0.clear_mask(gemm_k_iterations == 0);
    iterator_B1.clear_mask(gemm_k_iterations == 0);

    warp_mma.transform(warp_transformed_frag_A[0], warp_transformed_frag_B[0],
                       warp_loaded_frag_A[0], warp_loaded_frag_B[0]);

    // tf32x3 kernels use staging accumulation. warp_mma uses a temporary
    // accumulator and this temporary accumulator is added to the final
    // accumulator once in every mainloop iteration.
    plus<FragmentC> plus_accum;

    FragmentC tmp_accum[2];

    if (platform::is_same<typename Operator::MathOperator,
                          arch::OpMultiplyAddFastF32>::value
      || platform::is_same<typename Operator::MathOperator,
                           arch::OpMultiplyAddComplexFastF32>::value) {

      tmp_accum[0].clear();
      tmp_accum[1].clear();
    }

    //
    // Mainloop
    //
    static_assert(Base::kWarpGemmIterations <= 2, "Keeping A in RF requires at most 2");

    CUTLASS_GEMM_LOOP
    for (; gemm_k_iterations > -kNumPrologueIters;) {
      //
      // Loop over GEMM K dimension
      //

      CUTLASS_PRAGMA_UNROLL
      for (int operand = 0; operand < 2; ++operand) {
        static_assert((Base::kStages - 1) % 2 == 0);
        const bool isLastOperandB = (operand == 1);
        const bool isFirstOperandB = (operand == 0);
        auto& iterator_B = operand == 0 ? iterator_B0 : iterator_B1;

        // Computes a warp-level GEMM on data held in shared memory
        // Each "warp_mma_k" refers to a warp-level matrix multiply-accumulate
        CUTLASS_PRAGMA_UNROLL
        for (int warp_mma_k = 0; warp_mma_k < Base::kWarpGemmIterations;
            ++warp_mma_k) {

          // Load warp-level tiles from shared memory, wrapping to k offset if
          // this is the last group as the case may be.

          if ((warp_mma_k + 1 < Base::kWarpGemmIterations && isFirstOperandB) ||
              (warp_mma_k + 1 == Base::kWarpGemmIterations && isLastOperandB)) {
            this->warp_tile_iterator_A_.set_kgroup_index((warp_mma_k + 1) % Base::kWarpGemmIterations);
            this->warp_tile_iterator_A_.load(warp_loaded_frag_A[(warp_mma_k + 1) % 2]);
            ++this->warp_tile_iterator_A_;
          }

          this->warp_tile_iterator_B_.set_kgroup_index((warp_mma_k + 1) % Base::kWarpGemmIterations);
          this->warp_tile_iterator_B_.load(warp_loaded_frag_B[(warp_mma_k + 1) % 2]);
          ++this->warp_tile_iterator_B_;

          if (warp_mma_k > 0) {
            if (isLastOperandB) {
              warp_mma.transform(warp_transformed_frag_A[warp_mma_k % 2],
                                warp_transformed_frag_B[warp_mma_k % 2],
                                warp_loaded_frag_A[warp_mma_k % 2],
                                warp_loaded_frag_B[warp_mma_k % 2]);
            } else {
              warp_mma.transform(never_used_fragment,
                                warp_transformed_frag_B[warp_mma_k % 2],
                                warp_loaded_frag_A[warp_mma_k % 2],
                                warp_loaded_frag_B[warp_mma_k % 2]);
            }
          }

          if (platform::is_same<typename Operator::MathOperator,
                                arch::OpMultiplyAddFastF32>::value
            || platform::is_same<typename Operator::MathOperator,
                                arch::OpMultiplyAddComplexFastF32>::value) {

            warp_mma(
              tmp_accum[operand],
              warp_transformed_frag_A[warp_mma_k % 2],
              warp_transformed_frag_B[warp_mma_k % 2], 
              tmp_accum[operand]
            );

            if (warp_mma_k == 0) {
              accum[operand] = plus_accum(accum[operand], tmp_accum[operand]);
              tmp_accum[operand].clear();
            }
          } else {
            warp_mma(
              accum[operand],
              warp_transformed_frag_A[warp_mma_k % 2],
              warp_transformed_frag_B[warp_mma_k % 2], 
              accum[operand]
            );
          }

          // Issue global->shared copies for the this stage
          if (warp_mma_k < Base::kWarpGemmIterations - 1) {
            int group_start_iteration_A, group_start_iteration_B;

            group_start_iteration_A = warp_mma_k * Detail::kAccessesPerGroupA;
            group_start_iteration_B = warp_mma_k * Detail::kAccessesPerGroupB;

            copy_tiles_and_advance(iterator_A, operand == 0 ? iterator_B0 : iterator_B1, isFirstOperandB, group_start_iteration_A, 
                                group_start_iteration_B);
          }

          if (warp_mma_k + 2 == Base::kWarpGemmIterations) {
            int group_start_iteration_A, group_start_iteration_B;
            group_start_iteration_A =
                (warp_mma_k + 1) * Detail::kAccessesPerGroupA;
            group_start_iteration_B =
                (warp_mma_k + 1) * Detail::kAccessesPerGroupB;

            copy_tiles_and_advance(iterator_A, operand == 0 ? iterator_B0 : iterator_B1, isFirstOperandB, group_start_iteration_A, 
                                group_start_iteration_B);

            // Inserts a memory fence between stages of cp.async instructions.
            cutlass::arch::cp_async_fence();

            // Waits until stages up to the previous (kStages-2)th stage have committed.
            arch::cp_async_wait<kNumLoadsInFlight - 1>();
            __syncthreads();

            iterator_B.add_tile_offset({1, 0});
            iterator_B.clear_mask((gemm_k_iterations - 1) == 0);
            if (isLastOperandB) {
              // Move to the next stage
              iterator_A.add_tile_offset({0, 1});
              this->smem_iterator_A_.add_tile_offset({0, 1});
              // Add negative offsets to return iterators to the 'start' of the
              // circular buffer in shared memory
              if (smemA_write_stage_idx == (Base::kStages - 1)) {
                this->smem_iterator_A_.add_tile_offset({0, -Base::kStages});
                smemA_write_stage_idx = 0;
              } else {
                ++smemA_write_stage_idx;
              }
              if (smemA_read_stage_idx == (Base::kStages - 1)) {
                this->warp_tile_iterator_A_.add_tile_offset(
                      {0, -Base::kStages * Policy::kPartitionsK *
                              Base::kWarpGemmIterations});
                smemA_read_stage_idx = 0;
              } else {
                ++smemA_read_stage_idx;
              }

              --gemm_k_iterations;
              iterator_A.clear_mask(gemm_k_iterations == 0);
            }
            
            this->smem_iterator_B_.add_tile_offset({1, 0});
            // Add negative offsets to return iterators to the 'start' of the
            // circular buffer in shared memory
            if (smemB_write_stage_idx == (Base::kStages - 1)) {
              this->smem_iterator_B_.add_tile_offset({-Base::kStages, 0});
              smemB_write_stage_idx = 0;
            } else {
              ++smemB_write_stage_idx;
            }
            if (smemB_read_stage_idx == (Base::kStages - 1)) {
              this->warp_tile_iterator_B_.add_tile_offset(
                  {-Base::kStages * Policy::kPartitionsK *
                      Base::kWarpGemmIterations,
                  0});
              smemB_read_stage_idx = 0;
            } else {
              ++smemB_read_stage_idx;
            }
          }

          // Do any conversions feeding the first stage at the end of the loop so
          // we can start right away on mma instructions
          if (warp_mma_k + 1 == Base::kWarpGemmIterations)
            warp_mma.transform(warp_transformed_frag_A[(warp_mma_k + 1) % 2],
                              warp_transformed_frag_B[(warp_mma_k + 1) % 2],
                              warp_loaded_frag_A[(warp_mma_k + 1) % 2],
                              warp_loaded_frag_B[(warp_mma_k + 1) % 2]);
        }
      }
    }

    if (platform::is_same<typename Operator::MathOperator,
                          arch::OpMultiplyAddFastF32>::value
      || platform::is_same<typename Operator::MathOperator,
                           arch::OpMultiplyAddComplexFastF32>::value) {
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < 2; ++i) {
        accum[i] = plus_accum(accum[i], tmp_accum[i]); 
      }
    }
    accum0 = accum[0];
    accum1 = accum[1];
 
    if (SharedMemoryClear == SharedMemoryClearOption::kZfill) {
      // commit and drain all pending and predicated LDGSTS pnz from the GEMM mainloop
      cutlass::arch::cp_async_fence();
      cutlass::arch::cp_async_wait<0>();
      __syncthreads();
    }

  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace threadblock
}  // namespace gemm
}  // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
