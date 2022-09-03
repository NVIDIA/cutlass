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
    \brief Defines basic properties needed by CTA-level GEMMs assuming expectations about data
      layout of the global memory fragments, data types, and internal tile sizes.

      Partial specializations for threadblock::Mma operations targeting depthwise related simt instructions.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/array.h"

#include "cutlass/numeric_types.h"
#include "cutlass/matrix_shape.h"

#include "cutlass/gemm/warp/mma.h"
#include "cutlass/gemm/threadblock/mma_pipelined.h"
#include "cutlass/gemm/threadblock/mma_singlestage.h"

#include "cutlass/gemm/threadblock/mma_base.h"
#include "cutlass/conv/warp/mma_depthwise_simt.h"

#include "cutlass/arch/cache_operation.h" 

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace conv {
namespace threadblock {

template <
    /// Shape of threadblock-scoped matrix multiply operator
    typename Shape,
    /// Shape of warp-level matrix multiply operator
    typename WarpShape,
    /// Shape of one matrix production operation (concept: GemmShape)
    typename InstructionShape,
    /// Element data type of A operand
    typename ElementA,
    /// Layout of operand A
    typename LayoutA,
    /// Element data type of B operand
    typename ElementB,
    /// Layout of operand B
    typename LayoutB,
    /// Data type of accumulator
    typename ElementC,
    /// Layout of accumulator
    typename LayoutC,
    /// Indicates type of math operator (arch::OpClassSimt or arch::OpClassTensorOp)
    typename OperatorClass,
    /// Size of a warp-scoped per thread access
    int kLaneAccessSizeA_ = 0,
    /// Size of a warp-scoped per thread access 
    int kLaneAccessSizeB_ = 0,
    /// Number of stages
    int Stages = 2,
    /// Operation performed by MMA
    typename Operator = typename platform::conditional<
        (platform::is_same<OperatorClass,
                           cutlass::arch::OpClassTensorOp>::value) &&
            (platform::is_same<ElementA, int8_t>::value ||
             platform::is_same<ElementA, int4b_t>::value ||
             platform::is_same<ElementA, uint8_t>::value ||
             platform::is_same<ElementA, uint4b_t>::value),
        cutlass::arch::OpMultiplyAddSaturate,
        cutlass::arch::OpMultiplyAdd>::type,
    /// Store the accumulators in row major or column major.  Row major is used
    /// when output layout is interleaved.
    bool AccumulatorsInRowMajor = false,
    /// Cache operation of operand A
    cutlass::arch::CacheOperation::Kind CacheOpA =
        cutlass::arch::CacheOperation::Global,
    /// Cache operation of operand B
    cutlass::arch::CacheOperation::Kind CacheOpB =
        cutlass::arch::CacheOperation::Global,
    /// per-element transformation for elements of A
    ComplexTransform TransformA = ComplexTransform::kNone,
    /// per-element transformation for elements of B
    ComplexTransform TransformB = ComplexTransform::kNone,
    bool IsComplex = false // (is_complex<ElementA>::value || is_complex<ElementB>::value)
>
struct DepthwiseMmaCoreWithLaneAccessSize;

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// Shape of threadblock-scoped matrix multiply operator
    typename Shape,
    /// Shape of warp-level matrix multiply operator
    typename WarpShape,
    /// Shape of one matrix production operation (concept: GemmShape)
    typename InstructionShape,
    /// Element data type of A operand
    typename ElementA,
    /// Layout of operand A
    typename LayoutA,
    /// Element data type of B operand
    typename ElementB,
    /// Layout of operand B
    typename LayoutB,
    /// Data type of accumulator
    typename ElementC,
    /// Layout of accumulator
    typename LayoutC,
    /// Indicates type of math operator (arch::OpClassSimt or arch::OpClassTensorOp)
    typename OperatorClass,
    /// Number of stages
    int Stages,
    /// Operation performed by MMA
    typename Operator,
    /// Store the accumulators in row major or column major.  Row major is used
    /// when output layout is interleaved.
    bool AccumulatorsInRowMajor,
    /// Cache operation of operand A
    cutlass::arch::CacheOperation::Kind CacheOpA,
    /// Cache operation of operand B
    cutlass::arch::CacheOperation::Kind CacheOpB,
    /// per-element transformation for elements of A
    ComplexTransform TransformA,
    /// per-element transformation for elements of B
    ComplexTransform TransformB,
    bool IsComplex
>
struct DepthwiseMmaCoreWithLaneAccessSize<
    Shape, WarpShape, InstructionShape,
    ElementA, LayoutA, ElementB, LayoutB, ElementC, LayoutC,
    OperatorClass, -1, -1, Stages, Operator, AccumulatorsInRowMajor,
    CacheOpA, CacheOpB, TransformA, TransformB, IsComplex
> : cutlass::gemm::threadblock::DefaultMmaCore<
    Shape, WarpShape, InstructionShape,
    ElementA, LayoutA, ElementB, LayoutB, ElementC, LayoutC,
    OperatorClass, Stages, Operator, AccumulatorsInRowMajor,
    CacheOpA, CacheOpB, TransformA, TransformB, IsComplex
> {};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Partial specialization:
///
///   A: row-major
///   B: column-major
///   Operator: simt class
///
/// This uses the default warp-level operator given tile sizes
template <
    /// Shape of threadblock-scoped matrix multiply operator (concept:
    /// GemmShape)
    typename Shape_,
    /// Shape of warp-level matrix multiply operator (concept: GemmShape)
    typename WarpShape_,
    /// Data type of A operand
    typename ElementA_,
    /// Data type of B operand
    typename ElementB_,
    /// Data type of accumulator
    typename ElementC_,
    /// Layout of accumulator
    typename LayoutC_,
    /// Size of a warp-scoped per thread access (a value of -1 indicates the default)
    int kLaneAccessSizeA_,
    /// Size of a warp-scoped per thread access (a value of -1 indicates the default)
    int kLaneAccessSizeB_,
    /// Operation performed by GEMM
    typename Operator_>
struct DepthwiseMmaCoreWithLaneAccessSize<Shape_,
                                        WarpShape_,
                                        cutlass::gemm::GemmShape<1, 1, 1>,
                                        ElementA_,
                                        layout::RowMajor,
                                        ElementB_,
                                        layout::ColumnMajor,
                                        ElementC_,
                                        LayoutC_,
                                        arch::OpClassSimt,
                                        kLaneAccessSizeA_,
                                        kLaneAccessSizeB_,
                                        2,
                                        Operator_> : public cutlass::gemm::threadblock::DefaultMmaCore<Shape_,
                                                                           WarpShape_,
                                                                           cutlass::gemm::GemmShape<1, 1, 1>,
                                                                           ElementA_,
                                                                           layout::RowMajor,
                                                                           ElementB_,
                                                                           layout::ColumnMajor,
                                                                           ElementC_,
                                                                           LayoutC_,
                                                                           arch::OpClassSimt,
                                                                           2,
                                                                           Operator_> {
  using Base = cutlass::gemm::threadblock::DefaultMmaCore<Shape_,
                              WarpShape_,
                              cutlass::gemm::GemmShape<1, 1, 1>,
                              ElementA_,
                              layout::RowMajor,
                              ElementB_,
                              layout::ColumnMajor,
                              ElementC_,
                              LayoutC_,
                              arch::OpClassSimt,
                              2,
                              Operator_>;

  using Shape = Shape_;
  using WarpShape = WarpShape_;
  using InstructionShape = cutlass::gemm::GemmShape<1, 1, 1>;
  using ElementA = ElementA_;
  using LayoutA = layout::RowMajor;
  using ElementB = ElementB_;
  using LayoutB = layout::ColumnMajor;
  using ElementC = ElementC_;
  using LayoutC = LayoutC_;
  using OperatorClass = arch::OpClassSimt;

  static int const kLaneAccessSizeA = kLaneAccessSizeA_;
  static int const kLaneAccessSizeB = kLaneAccessSizeB_;

  // Divisility requirements
  static_assert( kLaneAccessSizeA > 0 && kLaneAccessSizeB > 0,
    "Size of a warp-scoped per thread access should be larger then ZERO" );

  /// Default Operator
  using Operator = Operator_;

  /// Number of warps present
  using WarpCount = typename Base::WarpCount;

  // Divisility requirements
  static_assert(
    !(Shape::kM % WarpShape::kM) &&
    !(Shape::kN % WarpShape::kN),
    "Threadblock-scoped GEMM should be divisible by warp-scoped GEMM size."
  );

  /// Number of threads per warp
  static int const kWarpSize = cutlass::gemm::warp::WarpSize<arch::OpClassSimt>::value;

  static int const kElementsPerAccess = 1;

  //
  // Shared memory layouts
  //

  using SmemLayoutA = layout::ColumnMajor;
  using SmemLayoutB = layout::RowMajor;

  //
  // Iterators to write to shared memory are same as base class
  //

  //
  // Warp-level matrix multiply operator
  //

  // Define the warp-level op
  static const int WarpNumThreadsM = cutlass::gemm::threadblock::detail::simt_get_warp_threads_m<WarpShape>(); 
  static const int WarpNumThreadsN = kWarpSize / WarpNumThreadsM;
  static const int ThreadTileM = WarpShape::kM / WarpNumThreadsM;
  static const int ThreadTileN = WarpShape::kN / WarpNumThreadsN;
  static_assert(!(WarpShape::kM % WarpNumThreadsM) && !(WarpShape::kN % WarpNumThreadsN),
      "WarpShape must be divisible by ThreadTile shape.");
  static const int LaneLayout = ThreadTileM > 4 && ThreadTileN > 4 ? 2 : 1;
  static const int numElementsA = kLaneAccessSizeA / sizeof_bits<ElementA>::value;
  static const int numElementsB = kLaneAccessSizeB / sizeof_bits<ElementB>::value;
  static const int LaneM = cutlass::const_min(numElementsA, ThreadTileM);
  static const int LaneN = cutlass::const_min(numElementsB, ThreadTileN);

  static int const kPaddingM = cutlass::gemm::threadblock::detail::simt_transpose_padding(kWarpSize, Shape::kK, sizeof_bits<ElementA>::value);
  static int const kPaddingN = cutlass::gemm::threadblock::detail::simt_transpose_padding(kWarpSize, Shape::kK, sizeof_bits<ElementB>::value);

  static_assert(!(kPaddingM % LaneM) && !(kPaddingN % LaneN),
                "Padding must be divisible by Lane");

  // these should have max of thread tile also
  using LaneMmaShape = cutlass::gemm::GemmShape<
      LaneM,
      LaneN,
      1>;
  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
      cutlass::MatrixShape<WarpNumThreadsM, WarpNumThreadsN>,   // WarpShape
      cutlass::layout::RowMajorInterleaved<LaneLayout>,         // LaneLayout
      LaneMmaShape
  >;

  using MmaWarpSimt = cutlass::conv::warp::MmaDepthwiseSimt<
      WarpShape,      /// Size of the Gemm problem - concept: gemm::GemmShape<>
      ElementA,       /// Data type of A elements
      SmemLayoutA,    /// Layout of A matrix (concept: MatrixLayout)
      ElementB,       /// Data type of B elements
      SmemLayoutB,    /// Layout of B matrix (concept: MatrixLayout)
      ElementC,       /// Element type of C matrix
      LayoutC,        /// Layout of C matrix (concept: MatrixLayout)
      Policy          /// Policy describing warp-level MmaSimtOp (concept: MmaSimtOp policy)
  >;

  /// Policy used to define MmaPipelined 
  using MmaPolicy = cutlass::gemm::threadblock::MmaPolicy<
    MmaWarpSimt,
    MatrixShape<kPaddingM, 0>,    // skew for A matrix to avoid SMEM bank conflicts
    MatrixShape<0, kPaddingN>,    // skew for B matrix to avoid SMEM bank conflicts
    WarpCount::kK
  >;
};

} // namespace threadblock
} // namespace conv
} // namespace cutlass
