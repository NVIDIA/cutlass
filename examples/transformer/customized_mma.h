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
    \brief Template for a pipelined GEMM kernel. Does not compute batching or support split-K.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"
#include "cutlass/arch/arch.h"
#include "cutlass/arch/wmma.h"

#include "cutlass/layout/matrix.h"
#include "cutlass/transform/threadblock/predicated_tile_iterator.h"
#include "cutlass/transform/threadblock/predicated_tile_iterator_2dthreadtile.h"

#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/threadblock/default_mma_core_simt.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm70.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm75.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm80.h"

#include "customized_predicated_iterator.h"
#include "customized_mma_pipelined.h"
#include "customized_mma_multistage.h"

#include "customized_regular_scale_bias_iterator.h"
#include "customized_scale_bias_iterator.h"

////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace gemm {
namespace threadblock {

////////////////////////////////////////////////////////////////////////////////

template <
    /// Element type for A matrix operand
    typename ElementA_,
    /// Layout type for A matrix operand
    typename LayoutA_,
    /// Access granularity of A matrix in units of elements
    int kAlignmentA,
    /// Element type for B matrix operand
    typename ElementB_,
    /// Layout type for B matrix operand
    typename LayoutB_,
    /// Access granularity of B matrix in units of elements
    int kAlignmentB,
    /// Element type for internal accumulation
    typename ElementAccumulator_,
    /// Layout type for C and D matrix operands
    typename LayoutC_,
    typename ElementScaleBias_,
    typename LayoutScaleBias_,
    /// Operator class tag
    typename OperatorClass_,
    /// Tag indicating architecture to tune for
    typename ArchTag_,
    /// Threadblock-level tile size (concept: GemmShape)
    typename ThreadblockShape_,
    /// Warp-level tile size (concept: GemmShape)
    typename WarpShape_,
    /// Instruction-level tile size (concept: GemmShape)
    typename InstructionShape_,
    /// Number of stages used in the pipelined mainloop
    int Stages,
    /// Operation perfomed by GEMM
    typename Operator,
    /// Store the accumulators in row major or column major.  Row major is used
    /// when output layout is interleaved.
    bool AccumulatorsInRowMajor = false,
    /// Use zfill or predicate for out-of-bound cp.async
    SharedMemoryClearOption SharedMemoryClear = SharedMemoryClearOption::kNone
    >
struct MyMma;


////////////////////////////////////////////////////////////////////////////////

/// Specialization for row-major output (OperatorClass TensorOp)
// template <
//     /// Element type for A matrix operand
//     typename ElementA,
//     /// Layout type for A matrix operand
//     typename LayoutA,
//     /// Access granularity of A matrix in units of elements
//     int kAlignmentA,
//     /// Element type for B matrix operand
//     typename ElementB,
//     /// Layout type for B matrix operand
//     typename LayoutB,
//     /// Access granularity of B matrix in units of elements
//     int kAlignmentB,
//     typename ElementScaleBias,
//     typename LayoutScaleBias,
//     /// Element type for internal accumulation
//     typename ElementAccumulator,
//     /// Tag indicating architecture to tune for
//     typename ArchTag,
//     /// Threadblock-level tile size (concept: GemmShape)
//     typename ThreadblockShape,
//     /// Warp-level tile size (concept: GemmShape)
//     typename WarpShape,
//     /// Instruction-level tile size (concept: GemmShape)
//     typename InstructionShape,
//     /// Operation performed by GEMM
//     typename Operator
//     >
// struct MyMma<ElementA, LayoutA, kAlignmentA, ElementB, LayoutB,
//                   kAlignmentB, ElementAccumulator, layout::RowMajor, 
//                   ElementScaleBias, LayoutScaleBias,
//                   arch::OpClassTensorOp, ArchTag, ThreadblockShape, WarpShape,
//                   InstructionShape, 2, Operator, false, SharedMemoryClearOption::kNone> {
//   // Define the MmaCore components
//   using MmaCore = typename cutlass::gemm::threadblock::DefaultMmaCore<
//       ThreadblockShape, WarpShape, InstructionShape, ElementA, LayoutA,
//       ElementB, LayoutB, ElementAccumulator, layout::RowMajor,
//       arch::OpClassTensorOp, 2, Operator>;

//   // Define iterators over tiles from the A operand
//   using IteratorA =
//       cutlass::transform::threadblock::MyPredicatedTileIterator<
//           cutlass::MatrixShape<MmaCore::Shape::kM, MmaCore::Shape::kK>,
//           ElementA, LayoutA, 1, typename MmaCore::IteratorThreadMapA, kAlignmentA>;

//   // Define iterators over tiles from the B operand
//   using IteratorB =
//       cutlass::transform::threadblock::PredicatedTileIterator<
//           cutlass::MatrixShape<MmaCore::Shape::kK, MmaCore::Shape::kN>,
//           ElementB, LayoutB, 0, typename MmaCore::IteratorThreadMapB, kAlignmentB>;

//   // Define the threadblock-scoped pipelined matrix multiply
//   using ThreadblockMma = cutlass::gemm::threadblock::MyMmaPipelined<
//       typename MmaCore::Shape, IteratorA, typename MmaCore::SmemIteratorA,
//       IteratorB, typename MmaCore::SmemIteratorB, ElementAccumulator,
//       layout::RowMajor, typename MmaCore::MmaPolicy>;
// };


template <
    /// Element type for A matrix operand
    typename ElementA,
    /// Layout type for A matrix operand
    typename LayoutA,
    /// Access granularity of A matrix in units of elements
    int kAlignmentA,
    /// Element type for B matrix operand
    typename ElementB,
    /// Layout type for B matrix operand
    typename LayoutB,
    /// Access granularity of B matrix in units of elements
    int kAlignmentB,
    /// Element type for internal accumulation
    typename ElementScaleBias,
    typename LayoutScaleBias,
    typename ElementAccumulator,
    /// Layout type for C and D matrix operand
    typename LayoutC,
    /// Tag indicating architecture to tune for
    typename ArchTag,
    /// Threadblock-level tile size (concept: GemmShape)
    typename ThreadblockShape,
    /// Warp-level tile size (concept: GemmShape)
    typename WarpShape,
    /// Instruction-level tile size (concept: GemmShape)
    typename InstructionShape,
    /// Number of stages used in the multistage mainloop
    int Stages,
    /// Operation perfomed by GEMM
    typename Operator,
    /// Use zfill or predicate for out-of-bound cp.async
    SharedMemoryClearOption SharedMemoryClear
    >
struct MyMma<ElementA, LayoutA, kAlignmentA, ElementB, LayoutB,
                  kAlignmentB, ElementAccumulator, LayoutC,
                  ElementScaleBias, LayoutScaleBias,
                  arch::OpClassTensorOp, ArchTag, ThreadblockShape, WarpShape,
                  InstructionShape, Stages, Operator, false, SharedMemoryClear> {

  static_assert(platform::is_same<LayoutC, layout::RowMajor>::value
             || platform::is_same<LayoutC, layout::AffineRankN<2>>::value,
             "simt epilogue must be row major");

  static cutlass::arch::CacheOperation::Kind const CacheOpA =
      ((sizeof_bits<ElementA>::value * kAlignmentA) == 128)
          ? cutlass::arch::CacheOperation::Global
          : cutlass::arch::CacheOperation::Always;

  static cutlass::arch::CacheOperation::Kind const CacheOpB =
      ((sizeof_bits<ElementB>::value * kAlignmentB) == 128)
          ? cutlass::arch::CacheOperation::Global
          : cutlass::arch::CacheOperation::Always;

  // Define the MmaCore components
  using MmaCore = typename cutlass::gemm::threadblock::DefaultMmaCore<
      ThreadblockShape, WarpShape, InstructionShape, ElementA, LayoutA,
      ElementB, LayoutB, ElementAccumulator, LayoutC, arch::OpClassTensorOp,
      Stages, Operator, false, CacheOpA, CacheOpB>;

  // Define iterators over tiles from the A operand
  using ThreadMapA = typename MmaCore::IteratorThreadMapA;
  using AccessTypeA = cutlass::Array<ElementA, kAlignmentA>;
  using IteratorA =
      cutlass::transform::threadblock::PredicatedTileAccessIterator<
          cutlass::MatrixShape<ThreadblockShape::kM, ThreadblockShape::kK>,
          ElementA, LayoutA, 1, ThreadMapA, AccessTypeA>;

  // Define iterators over tiles from the B operand
  using ThreadMapB = typename MmaCore::IteratorThreadMapB;
  using AccessTypeB = cutlass::Array<ElementB, kAlignmentB>;
  using IteratorB =
      cutlass::transform::threadblock::PredicatedTileAccessIterator<
          cutlass::MatrixShape<ThreadblockShape::kK, ThreadblockShape::kN>,
          ElementB, LayoutB, 0, ThreadMapB, AccessTypeB>;

  // Define the threadblock-scoped multistage matrix multiply
  using ThreadblockMma = cutlass::gemm::threadblock::MyMmaMultistage<
      typename MmaCore::Shape, IteratorA, typename MmaCore::SmemIteratorA,
      MmaCore::kCacheOpA, IteratorB, typename MmaCore::SmemIteratorB,
      MmaCore::kCacheOpB, ElementAccumulator, LayoutC,
      typename MmaCore::MmaPolicy, 
      ThreadblockShape, 
      WarpShape, 
      InstructionShape, 
      MmaCore,
      ElementScaleBias,
      LayoutScaleBias,
      Stages, 
      SharedMemoryClear>;
};



} // namespace threadblock
} // namespace gemm
} // namespace cutlass 

////////////////////////////////////////////////////////////////////////////////
