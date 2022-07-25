/***************************************************************************************************
 * Copyright (c) 2017-2021, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Template for a double-buffered threadblock-scoped Back-to-back fused GEMM kernel.
*/

#pragma once

#include "cutlass/aligned_buffer.h"
#include "cutlass/array.h"
#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/warp/mma_tensor_op_fragment_iterator.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/numeric_conversion.h"
#include "cutlass/numeric_types.h"
#include "cutlass/util/debug.h"
#include "cutlass/util/device_dump.h"
#include "mma_2d_base.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace contrib {
namespace gemm {
namespace threadblock {

////////////////////////////////////////////////////////////////////////////////////////////////

/// Structure to compute the matrix product targeting CUDA cores and SIMT math instructions.
template <
    /// Size of the Gemm problem - concept: gemm::GemmShape<>
    typename Shape0_,
    /// Iterates over tiles of A operand in global memory
    //  (concept: ReadableTileIterator | ForwardTileIterator | MaskedTileIterator)
    typename IteratorA0_,
    /// Iterates over tiles of A operand in shared memory
    /// (concept: WriteableTileIterator | RandomAccessTileIterator)
    typename SmemIteratorA0_,
    /// Iterates over tiles of B operand in global memory
    //  (concept: ReadableTileIterator | ForwardTileIterator | MaskedTileIterator)
    typename IteratorB0_,
    /// Iterates over tiles of B operand in shared memory
    /// (concept: WriteableTileIterator | RandomAccessTileIterator)
    typename SmemIteratorB0_,
    /// Size of the Gemm problem - concept: gemm::GemmShape<>
    typename Shape1_,
    /// Iterates over the intermediate accumulator tile
    //  (concept::MmaTensorOpFragmentIterator)
    typename FragmentIteratorA1_,
    /// Iterates over tiles of B operand in global memory
    //  (concept: ReadableTileIterator | ForwardTileIterator | MaskedTileIterator)
    typename IteratorB1_,
    /// Iterates over tiles of B operand in shared memory
    /// (concept: WriteableTileIterator | RandomAccessTileIterator)
    typename SmemIteratorB1_,
    /// Data type of accumulator matrix
    typename ElementC_,
    /// Data type of accumulator matrix
    typename LayoutC_,
    /// Output operator for 1st Gemm(concept: epilogue::thread::LinearCombinationClamp, etc...)
    typename OutputOp_,
    /// Output operator for 1st Gemm(concept: epilogue::thread::LinearCombinationClamp, etc...)
    typename Epilogue_,
    /// Policy describing tuning details (concept: MmaPipelinedPolicy)
    typename Policy0_,
    /// Policy describing tuning details (concept: MmaPipelinedPolicy)
    typename Policy1_,
    /// Prologue of A0
    typename PrologueDefA0_,
    /// Prologue of B0
    typename PrologueDefB0_,
    /// Prologue of B1
    typename PrologueDefB1_,
    /// Transformation applied to A0 operand
    typename TransformA0_ = NumericArrayConverter<typename SmemIteratorA0_::Element,
                                                  typename IteratorA0_::Element,
                                                  IteratorA0_::Fragment::kElements>,
    ///
    /// Transformation applied to B0 operand
    typename TransformB0_ = NumericArrayConverter<typename SmemIteratorB0_::Element,
                                                  typename IteratorB0_::Element,
                                                  IteratorB0_::Fragment::kElements>,
    ///
    /// Transformation applied to B1 operand
    typename TransformB1_ = NumericArrayConverter<typename SmemIteratorB1_::Element,
                                                  typename IteratorB1_::Element,
                                                  IteratorB1_::Fragment::kElements>,
    /// Used for partial specialization
    typename Enable = bool>
class Mma2DPipelined : public Mma2DBase<Shape0_, Shape1_, Policy0_, Policy1_, 2> {
 public:
  ///< Base class
  using Base = Mma2DBase<Shape0_, Shape1_, Policy0_, Policy1_, 2>;

  using Shape0 = Shape0_;          ///< Size of the Gemm problem - concept: gemm::GemmShape<>
  using IteratorA0 = IteratorA0_;  ///< Iterates over tiles of A operand in global memory
  using IteratorB0 = IteratorB0_;  ///< Iterates over tiles of B operand in global memory
  using Policy0 = Policy0_;        ///< Policy describing tuning details

  using SmemIteratorA0 = SmemIteratorA0_;
  using SmemIteratorB0 = SmemIteratorB0_;

  using Shape1 = Shape1_;  ///< Size of the Gemm problem - concept: gemm::GemmShape<>
  using FragmentIteratorA1 = FragmentIteratorA1_;  ///< Iterates over intermediate accumulator tile
  using IteratorB1 = IteratorB1_;  ///< Iterates over tiles of B operand in global memory
  using Policy1 = Policy1_;        ///< Policy describing tuning details

  using SmemIteratorB1 = SmemIteratorB1_;

  using ElementC = ElementC_;  ///< Data type of accumulator matrix
  using LayoutC = LayoutC_;    ///< Layout of accumulator matrix

  using OutputOp = OutputOp_;  ///< Epilogue after 1st Gemm
  using Epilogue = Epilogue_;

  using IteratorC0 = typename Epilogue::OutputTileIterator;

  using PrologueDefA0 = PrologueDefA0_;
  using PrologueOpA0 = typename PrologueDefA0::Operator;

  using PrologueDefB0 = PrologueDefB0_;
  using PrologueOpB0 = typename PrologueDefB0::Operator;

  using PrologueDefB1 = PrologueDefB1_;
  using PrologueOpB1 = typename PrologueDefB1::Operator;

  using TransformA0 = TransformA0_;
  using TransformB0 = TransformB0_;
  using TransformB1 = TransformB1_;

  //
  // Dependent types
  //

  /// Fragment of operand A loaded from global memory
  using FragmentA0 = typename IteratorA0::Fragment;

  /// Fragment of operand B loaded from global memory
  using FragmentB0 = typename IteratorB0::Fragment;

  /// Fragment of accumulator tile
  using FragmentC0 = typename Policy0::Operator::FragmentC;

  /// Warp-level Mma
  using Operator0 = typename Policy0::Operator;

  /// Fragment of operand B loaded from global memory
  using FragmentB1 = typename IteratorB1::Fragment;

  /// Fragment of accumulator tile
  using FragmentC1 = typename Policy1::Operator::FragmentC;

  /// Warp-level Mma
  using Operator1 = typename Policy1::Operator;

  /// Obtain the arch tag from the warp-level operator
  using ArchTag = typename Policy0::Operator::ArchTag;

  /// Complex transform on A0 operand
  static ComplexTransform const kTransformA0 = Operator0::kTransformA;

  /// Complex transform on B0 operand
  static ComplexTransform const kTransformB0 = Operator0::kTransformB;

  /// Complex transform on B1 operand
  static ComplexTransform const kTransformB1 = Operator1::kTransformB;

  // staticaly assert kStages for MmaPipelined is two (Double-buffered pipeline)
  static_assert((Base::kStages == 2), "MmaPipelined requires kStages set to value 2");

 private:
  using WarpFragmentA0 = typename Operator0::FragmentA;
  using WarpFragmentB0 = typename Operator0::FragmentB;
  /// Warp Fragment of operand A1 loaded from accmulator tile
  using WarpFragmentA1 = typename FragmentIteratorA1::Fragment;
  using WarpFragmentB1 = typename Operator1::FragmentB;

 protected:
  /// Iterator to write threadblock-scoped tile of A operand to shared memory
  SmemIteratorA0 smem_iterator_A_;

  /// Iterator to write threadblock-scoped tile of B0 operand to shared memory
  SmemIteratorB0 smem_iterator_B0_;

  /// Iterator to write threadblock-scoped tile of B1 operand to shared memory
  SmemIteratorB1 smem_iterator_B1_;

 public:
  /// Construct from tensor references
  CUTLASS_DEVICE
  Mma2DPipelined(
      typename Base::Mma2DSharedStorage&
          shared_storage,  ///< Shared storage needed for internal use by threadblock-scoped GEMM
      int thread_idx,      ///< ID within the threadblock
      int warp_idx,        ///< ID of warp
      int lane_idx         ///< ID of each thread within a warp
      )
      : Base(shared_storage, thread_idx, warp_idx, lane_idx),
        smem_iterator_A_(shared_storage.shared_storage0.operand_A_ref(), thread_idx),
        smem_iterator_B0_(shared_storage.shared_storage0.operand_B_ref(), thread_idx),
        smem_iterator_B1_(shared_storage.shared_storage1.operand_B_ref(), thread_idx) {
    // Compute warp location within threadblock tile by mapping the warp_id to three coordinates:
    //   _m: the warp's position within the threadblock along the M dimension
    //   _n: the warp's position within the threadblock along the N dimension
    //   _k: the warp's position within the threadblock along the K dimension

    // These should stay the same across different GEMM layers
    int warp_idx_mn = warp_idx % (Base::WarpCount0::kM * Base::WarpCount0::kN);
    int warp_idx_k = warp_idx / (Base::WarpCount0::kM * Base::WarpCount0::kN);

    int warp_idx_m = warp_idx_mn % Base::WarpCount0::kM;
    int warp_idx_n = warp_idx_mn / Base::WarpCount0::kM;

    // These may change across different GEMM layers
    int tile_offset_k_0 = Base::kWarpGemmIterations0 * warp_idx_k;
    int tile_offset_k_1 = Base::kWarpGemmIterations1 * warp_idx_k;

    // Add per-warp offsets in units of warp-level tiles
    this->warp_tile_iterator_A0_.add_tile_offset({warp_idx_m, tile_offset_k_0});
    this->warp_tile_iterator_B0_.add_tile_offset({tile_offset_k_0, warp_idx_n});
    this->warp_tile_iterator_B1_.add_tile_offset({tile_offset_k_1, warp_idx_n});
  }

  /// Perform a threadblock-scoped matrix multiply-accumulate
  CUTLASS_DEVICE
  void gemm0(int gemm_k_iterations_0,
             IteratorA0 iterator_A0,
             IteratorB0 iterator_B0,
             IteratorC0 iterator_C0,
             PrologueOpA0 prologue_op_A0,
             PrologueOpA0 prologue_op_B0,
             OutputOp output_op,
             FragmentC0& accum0,
             TransformA0 transform_A0 = TransformA0(),
             TransformB0 transform_B0 = TransformB0()) {
    //
    // Prologue
    //
    using WarpLoadIteratorA0 = typename Base::Operator0::IteratorA;
    using WarpLoadIteratorB0 = typename Base::Operator0::IteratorB;

    FragmentA0 tb_frag_A0;
    FragmentB0 tb_frag_B0;

    tb_frag_A0.clear();
    tb_frag_B0.clear();

    // The last kblock is loaded in the prolog
    iterator_A0.load(tb_frag_A0);
    iterator_B0.load(tb_frag_B0);

    ++iterator_A0;
    ++iterator_B0;

    this->smem_iterator_A_.store(transform_A0(tb_frag_A0));
    this->smem_iterator_B0_.store(transform_B0(tb_frag_B0));

    ++this->smem_iterator_A_;
    ++this->smem_iterator_B0_;

    typename PrologueOpA0::Detail<WarpLoadIteratorA0>::Fragment prologue_frag_A0;
    typename PrologueOpB0::Detail<WarpLoadIteratorB0>::Fragment prologue_frag_B0;
    prologue_op_A0.template load<WarpLoadIteratorA0>(prologue_frag_A0);
    prologue_op_B0.template load<WarpLoadIteratorB0>(prologue_frag_B0);

    __syncthreads();

    // Pair of fragments used to overlap shared memory loads and math instructions
    WarpFragmentA0 warp_frag_A0[2];
    WarpFragmentB0 warp_frag_B0[2];

    this->warp_tile_iterator_A0_.set_kgroup_index(0);
    this->warp_tile_iterator_B0_.set_kgroup_index(0);

    prologue_op_A0.template set_kgroup_index<WarpLoadIteratorA0>(0);
    prologue_op_B0.template set_kgroup_index<WarpLoadIteratorB0>(0);

    this->warp_tile_iterator_A0_.load(warp_frag_A0[0]);
    this->warp_tile_iterator_B0_.load(warp_frag_B0[0]);

    ++this->warp_tile_iterator_A0_;
    ++this->warp_tile_iterator_B0_;

    Operator0 warp_mma0;

    int smem_write_stage_idx = 1;

    // Avoid reading out of bounds
    if (gemm_k_iterations_0 <= 1) {
      iterator_A0.clear_mask();
      iterator_B0.clear_mask();
    }

    // Issue loads during the first warp-level matrix multiply-add *AFTER* issuing
    // shared memory loads (which have the tighest latency requirement).
    iterator_A0.load(tb_frag_A0);

    //
    // Mainloop
    //

    // Note: The main loop does not support Base::WarpGemmIterations == 2.
    CUTLASS_GEMM_LOOP
    for (; gemm_k_iterations_0 > 0; --gemm_k_iterations_0) {
      //
      // Loop over GEMM K dimension
      //

      CUTLASS_PRAGMA_UNROLL
      for (int warp_mma_k = 0; warp_mma_k < Base::kWarpGemmIterations0; ++warp_mma_k) {
        // Load warp-level tiles from shared memory, wrapping to k offset if this is the last group
        // as the case may be.

        prologue_op_A0.template set_kgroup_index<WarpLoadIteratorA0>(warp_mma_k);
        prologue_op_B0.template set_kgroup_index<WarpLoadIteratorB0>(warp_mma_k);

        if (warp_mma_k == Base::kWarpGemmIterations0 - 1) {
          // Write fragments to shared memory
          this->smem_iterator_A_.store(tb_frag_A0);

          this->smem_iterator_B0_.store(tb_frag_B0);

          __syncthreads();

          // Issue loads during the first warp-level matrix multiply-add *AFTER* issuing
          // shared memory loads (which have the tighest latency requirement).
          iterator_A0.load(tb_frag_A0);

          ++this->smem_iterator_B0_;
          ++this->smem_iterator_A_;

          // Add negative offsets to return iterators to the 'start' of the circular buffer in
          // shared memory
          if (smem_write_stage_idx == 1) {
            this->smem_iterator_A_.add_tile_offset({0, -Base::kStages});
            this->smem_iterator_B0_.add_tile_offset({-Base::kStages, 0});
          } else {
            this->warp_tile_iterator_A0_.add_tile_offset(
                {0, -Base::kStages * Policy0::kPartitionsK * Base::kWarpGemmIterations0});
            this->warp_tile_iterator_B0_.add_tile_offset(
                {-Base::kStages * Policy0::kPartitionsK * Base::kWarpGemmIterations0, 0});
          }

          smem_write_stage_idx ^= 1;
        }

        this->warp_tile_iterator_A0_.set_kgroup_index((warp_mma_k + 1) %
                                                      Base::kWarpGemmIterations0);
        this->warp_tile_iterator_B0_.set_kgroup_index((warp_mma_k + 1) %
                                                      Base::kWarpGemmIterations0);

        this->warp_tile_iterator_A0_.load(warp_frag_A0[(warp_mma_k + 1) % 2]);
        this->warp_tile_iterator_B0_.load(warp_frag_B0[(warp_mma_k + 1) % 2]);

        ++this->warp_tile_iterator_A0_;
        ++this->warp_tile_iterator_B0_;

        if (warp_mma_k == 0) {
          iterator_B0.load(tb_frag_B0);

          ++iterator_A0;
          ++iterator_B0;

          // Avoid reading out of bounds if this was the last loop iteration
          if (gemm_k_iterations_0 <= 2) {
            iterator_A0.clear_mask();
            iterator_B0.clear_mask();
          }
        }

        warp_frag_A0[warp_mma_k % 2] = prologue_op_A0.template operator()<WarpLoadIteratorA0>(
            warp_frag_A0[warp_mma_k % 2], prologue_frag_A0);
        warp_frag_B0[warp_mma_k % 2] = prologue_op_B0.template operator()<WarpLoadIteratorB0>(
            warp_frag_B0[warp_mma_k % 2], prologue_frag_B0);
        warp_mma0(accum0, warp_frag_A0[warp_mma_k % 2], warp_frag_B0[warp_mma_k % 2], accum0);
      }
      prologue_op_A0.template operator++<WarpLoadIteratorA0>();
      prologue_op_B0.template operator++<WarpLoadIteratorB0>();
      prologue_op_A0.template load<WarpLoadIteratorA0>(prologue_frag_A0);
      prologue_op_B0.template load<WarpLoadIteratorB0>(prologue_frag_B0);
    }

    // epilogue
    Epilogue epilogue;
    epilogue(output_op, accum0, accum0, iterator_C0);
  }

  /// Perform a threadblock-scoped matrix multiply-accumulate
  CUTLASS_DEVICE
  void gemm1(int gemm_k_iterations_1,
             const FragmentC0& accum0,
             FragmentIteratorA1 warp_tile_iterator_A1,
             IteratorB1 iterator_B1,
             PrologueOpB1 prologue_op_B1,
             FragmentC1& accum1,
             TransformB1 transform_B1 = TransformB1()) {
    // Prologue
    //
    using WarpLoadIteratorB1 = typename Base::Operator1::IteratorB;

    // FragmentIteratorA1 warp_tile_iterator_A1(accum0);
    FragmentB1 tb_frag_B1;
    tb_frag_B1.clear();

    // The last kblock is loaded in the prolog
    iterator_B1.load(tb_frag_B1);

    ++iterator_B1;

    this->smem_iterator_B1_.store(transform_B1(tb_frag_B1));

    ++this->smem_iterator_B1_;

    typename PrologueOpB1::Detail<WarpLoadIteratorB1>::Fragment prologue_frag_B1;
    prologue_op_B1.template load<WarpLoadIteratorB1>(prologue_frag_B1);
    __syncthreads();

    // Pair of fragments used to overlap shared memory loads and math instructions
    WarpFragmentA1 warp_frag_A1[2];
    WarpFragmentB1 warp_frag_B1[2];

    // warp_tile_iterator_A1_.set_kgroup_index(0);
    this->warp_tile_iterator_B1_.set_kgroup_index(0);
    prologue_op_B1.template set_kgroup_index<WarpLoadIteratorB1>(0);

    warp_tile_iterator_A1.load(warp_frag_A1[0]);
    this->warp_tile_iterator_B1_.load(warp_frag_B1[0]);

    ++warp_tile_iterator_A1;
    ++this->warp_tile_iterator_B1_;

    Operator1 warp_mma1;

    int smem_write_stage_idx = 1;

    int max_gemm_k_iterations_1 = (Shape0::kN + Shape1::kK - 1) / Shape1::kK;

    // Avoid reading out of bounds
    if (max_gemm_k_iterations_1 <= 1) {
      iterator_B1.clear_mask();
    }

    int exit_threshold = max_gemm_k_iterations_1 - gemm_k_iterations_1;

    //
    // Mainloop
    //

    // Note: The main loop does not support Base::WarpGemmIterations == 2.
    CUTLASS_PRAGMA_UNROLL
    for (; max_gemm_k_iterations_1 > 0; --max_gemm_k_iterations_1) {
      //
      // Loop over GEMM K dimension
      //
      if (max_gemm_k_iterations_1 <= exit_threshold) {
        break;
      }

      CUTLASS_PRAGMA_UNROLL
      for (int warp_mma_k = 0; warp_mma_k < Base::kWarpGemmIterations1; ++warp_mma_k) {
        // Load warp-level tiles from shared memory, wrapping to k offset if this is the last group
        // as the case may be.

        prologue_op_B1.template set_kgroup_index<WarpLoadIteratorB1>(warp_mma_k);

        if (warp_mma_k == Base::kWarpGemmIterations1 - 1) {
          // Write fragments to shared memory

          this->smem_iterator_B1_.store(tb_frag_B1);

          __syncthreads();
          ++this->smem_iterator_B1_;

          // Add negative offsets to return iterators to the 'start' of the circular buffer in
          // shared memory
          if (smem_write_stage_idx == 1) {
            this->smem_iterator_B1_.add_tile_offset({-Base::kStages, 0});
          } else {
            this->warp_tile_iterator_B1_.add_tile_offset(
                {-Base::kStages * Policy1::kPartitionsK * Base::kWarpGemmIterations1, 0});
          }

          smem_write_stage_idx ^= 1;
        }

        this->warp_tile_iterator_B1_.set_kgroup_index((warp_mma_k + 1) %
                                                      Base::kWarpGemmIterations1);

        warp_tile_iterator_A1.load(warp_frag_A1[(warp_mma_k + 1) % 2]);
        this->warp_tile_iterator_B1_.load(warp_frag_B1[(warp_mma_k + 1) % 2]);

        ++warp_tile_iterator_A1;
        ++this->warp_tile_iterator_B1_;

        if (warp_mma_k == 0) {
          iterator_B1.load(tb_frag_B1);
          ++iterator_B1;

          // Avoid reading out of bounds if this was the last loop iteration
          if (gemm_k_iterations_1 <= 2) {
            iterator_B1.clear_mask();
          }
        }

        warp_frag_B1[warp_mma_k % 2] = prologue_op_B1.template operator()<WarpLoadIteratorB1>(
            warp_frag_B1[warp_mma_k % 2], prologue_frag_B1);
        warp_mma1(accum1, warp_frag_A1[warp_mma_k % 2], warp_frag_B1[warp_mma_k % 2], accum1);
      }
      prologue_op_B1.template operator++<WarpLoadIteratorB1>();
      prologue_op_B1.template load<WarpLoadIteratorB1>(prologue_frag_B1);
    }
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace threadblock
}  // namespace gemm
}  // namespace contrib
}  // namespace cutlass
