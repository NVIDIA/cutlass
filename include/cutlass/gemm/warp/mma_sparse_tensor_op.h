/***************************************************************************************************
 * Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
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
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Templates implementing warp-level matrix multiply-accumulate
   operations targeting sparse Tensor Cores.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/array.h"
#include "cutlass/platform/platform.h"

#include "cutlass/numeric_conversion.h"
#include "cutlass/numeric_types.h"
#include "cutlass/matrix_shape.h"

#include "cutlass/arch/memory_sm75.h"
#include "cutlass/arch/mma_sm75.h" 
#include "cutlass/arch/mma_sm80.h"

#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/warp/mma.h"

#include "cutlass/gemm/warp/mma_tensor_op_policy.h"
#include "cutlass/gemm/warp/mma_tensor_op.h"

#include "cutlass/gemm/warp/mma_tensor_op_tile_iterator.h"
#include "cutlass/gemm/warp/mma_tensor_op_tile_iterator_sm80.h"
#include "cutlass/gemm/warp/mma_tensor_op_tile_iterator_sparse.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace gemm {
namespace warp {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Structure to compute the matrix product targeting CUDA cores and SIMT math instructions.
template <
  /// Size of the Gemm problem - concept: gemm::GemmShape<>
  typename Shape_,
  /// Data type of A elements
  typename ElementA_,
  /// Layout of A matrix (concept: MatrixLayout)
  typename LayoutA_,
  /// Data type of B elements
  typename ElementB_,
  /// Layout of B matrix (concept: MatrixLayout)
  typename LayoutB_,
  /// Element type of C matrix
  typename ElementC_,
  /// Layout of C matrix (concept: MatrixLayout)
  typename LayoutC_,
  /// Policy describing warp-level MmaTensorOp (concept: MmaTensorOp policy)
  typename Policy_,
  /// Number of partitions along K dimension
  int PartitionsK_ = 1,
  /// Store the accumulators in row major or column major.  Row major is used
  /// when output layout is interleaved.
  bool AccumulatorsInRowMajor = false,
  /// Used for partial specialization
  typename Enable = bool
>
class SparseMmaTensorOp {
public:
  /// Shape of warp-level matrix operation (concept: GemmShape)
  using Shape = Shape_;

  /// Data type of multiplicand A
  using ElementA = ElementA_;

  /// Layout of multiplicand A
  using LayoutA = LayoutA_;

  /// Data type of multiplicand B
  using ElementB = ElementB_;

  /// Layout of multiplicand B
  using LayoutB = LayoutB_;

  /// Data type of accumulator matrix C
  using ElementC = ElementC_;

  /// Layout of accumulator matrix C
  using LayoutC = LayoutC_;

  /// Shape of the warp in units of thread (concept: MmaLanePolicySimt)
  using Policy = Policy_;

  /// Architecture tag from underlying instruction
  using ArchTag = typename Policy::Operator::ArchTag;

  /// Indicates class of matrix operator
  using OperatorClass = arch::OpClassTensorOp;

  /// Complex transform on A operand
  static ComplexTransform const kTransformA = ComplexTransform::kNone;

  /// Complex transform on B operand
  static ComplexTransform const kTransformB = ComplexTransform::kNone;

  /// Number of threads participating in warp-level matrix product
  static int const kThreadCount = 32;

  /// Number of partitions along K dimension
  static int const kPartitionsK = PartitionsK_;

  /// Sparsity in Operand A
  static int const kSparse = Policy::Operator::kSparse;

  /// Meta data size in bits 
  static int const kMetaSizeInBits = Policy::Operator::kMetaSizeInBits;

  /// Max ID2
  static int const kMaxID2 = Policy::Operator::kMaxID2;

  /// Data type of meta E that is moved at the same time
  using ElementE =
      typename cutlass::platform::conditional<kMaxID2 == 1, uint32_t,
                                              uint16_t>::type;

  /// Number of ElementA that is associated with one ElementE
  static int const kElementsPerElementE =
      128 / cutlass::sizeof_bits<ElementA>::value;

  /// Meta data is essentially interleaved but mapped to ColumnMajor internally
  static int const kInterleaved = 2;

  /// Layout of meta E 
  using LayoutE = cutlass::layout::ColumnMajor;

 public:

  /// Iterates over the A operand in memory
 using IteratorA = MmaTensorOpMultiplicandTileIterator<
     MatrixShape<Shape::kM, Shape::kK / kSparse>, Operand::kA, ElementA,
     LayoutA,
     MatrixShape<Policy::Operator::Shape::kM,
                 Policy::Operator::Shape::kK / kSparse>,
     Policy::OpDelta::kRow, kThreadCount, kPartitionsK>;

 /// Storage for A tile
 using FragmentA = typename IteratorA::Fragment;

 /// Storage for transformed A tile
 using TransformedFragmentA =
     Array<typename Policy::Operator::ElementA, FragmentA::kElements>;

 /// Iterates over the B operand in memory
 using IteratorB = MmaTensorOpMultiplicandTileIterator<
     MatrixShape<Shape::kK, Shape::kN>, Operand::kB, ElementB, LayoutB,
     MatrixShape<Policy::Operator::Shape::kK, Policy::Operator::Shape::kN>,
     Policy::OpDelta::kRow, kThreadCount, kPartitionsK>;

 /// Storage for B tile
 using FragmentB = typename IteratorB::Fragment;

 /// Storage for transformed B tile
 using TransformedFragmentB =
     Array<typename Policy::Operator::ElementB, FragmentB::kElements>;

 /// Iterates over the C operand in memory
 using IteratorC = MmaTensorOpAccumulatorTileIterator<
     MatrixShape<Shape::kM, Shape::kN>, ElementC, LayoutC,
     typename Policy::Operator::Shape, typename Policy::OpDelta>;

 /// Storage for C tile
 using FragmentC = typename IteratorC::Fragment;

 /// Iterates over the E operand in memory
 using IteratorE = SparseMmaTensorOpMetaTileIterator<
     MatrixShape<Shape::kM * kInterleaved,
                 Shape::kK / kSparse / kElementsPerElementE / kInterleaved>,
     ElementE, LayoutE,
     MatrixShape<Policy::Operator::Shape::kM,
                 Policy::Operator::Shape::kK / kSparse / kElementsPerElementE /
                     kInterleaved>,
     Policy::OpDelta::kRow, kThreadCount, kPartitionsK>;

 /// Storage for E tile
 using FragmentE = typename IteratorE::Fragment;

private:

  static_assert(
    !(Shape::kM % Policy::Operator::Shape::kM) && 
    !(Shape::kN % Policy::Operator::Shape::kN),
    "Shape of warp-level Mma must be divisible by operator shape.");

  /// Number of mma operations performed
  using MmaIterations = MatrixShape<
    Shape::kM / Policy::Operator::Shape::kM,
    Shape::kN / Policy::Operator::Shape::kN
  >;

public:

  /// Underlying matrix multiply operator (concept: arch::Mma)
  typename Policy::Operator mma;

public:

  //
  // Methods
  //

  /// Ctor
  CUTLASS_DEVICE
  SparseMmaTensorOp() {}

  /// Performs a warp-level matrix multiply-accumulate operation
  CUTLASS_DEVICE
  void operator()(
    FragmentC &D, 
    TransformedFragmentA const &A, 
    TransformedFragmentB const &B, 
    FragmentC const &C,
    FragmentE const &E
  ) const {

    using MmaOperandA = typename Policy::Operator::FragmentA;
    using MmaOperandB = typename Policy::Operator::FragmentB;
    using MmaOperandC = typename Policy::Operator::FragmentC;
    using MmaOperandE = typename Policy::Operator::FragmentE;

    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 800)

    D = C;

    MmaOperandA const *ptr_A = reinterpret_cast<MmaOperandA const *>(&A);
    MmaOperandB const *ptr_B = reinterpret_cast<MmaOperandB const *>(&B);
    MmaOperandC *ptr_D = reinterpret_cast<MmaOperandC *>(&D);
    MmaOperandE const *ptr_E = reinterpret_cast<MmaOperandE const *>(&E);

      CUTLASS_PRAGMA_UNROLL
      for (int m = 0; m < MmaIterations::kRow; ++m) {

        int id2 = m % kMaxID2;

        CUTLASS_PRAGMA_UNROLL
        for (int n = 0; n < MmaIterations::kColumn; ++n) {

          int n_serpentine = ((m % 2) ? (MmaIterations::kColumn - 1 - n) : n);

          if (AccumulatorsInRowMajor) {  // matrix B is reordered
            mma(
              ptr_D[n_serpentine + m * MmaIterations::kColumn],
              ptr_A[m],
              ptr_B[n_serpentine],
              ptr_D[n_serpentine + m * MmaIterations::kColumn],
              ptr_E[(m / kMaxID2)],
              id2);
          } else {
            mma(ptr_D[m + n_serpentine * MmaIterations::kRow],
                ptr_A[m],
                ptr_B[n_serpentine],
                ptr_D[m + n_serpentine * MmaIterations::kRow],
                ptr_E[(m / kMaxID2)],
                id2);
          }
        }
      }
    #else
      assert(0);
    #endif
  }

  /// Transform the mma operands to the required types
  CUTLASS_DEVICE
  void transform(TransformedFragmentA &dst_A, TransformedFragmentB &dst_B,
                 FragmentA const &A, FragmentB const &B) const {

    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 800)
    //
    // Define conversions from source type to instruction type
    //
    FloatRoundStyle const kRoundA =
        PreferredRoundingMode<typename Policy::Operator::ElementA,
                              ElementA>::kRound;
    FloatRoundStyle const kRoundB =
        PreferredRoundingMode<typename Policy::Operator::ElementB,
                              ElementB>::kRound;
    detail::ConvertAndPack<typename Policy::Operator::ElementA, ElementA,
                           FragmentA::kElements / 2, kRoundA>
        convert_A;
    NumericArrayConverter<typename Policy::Operator::ElementB, ElementB,
                          FragmentB::kElements, kRoundB>
        convert_B;
    Array<ElementA, FragmentA::kElements / 2> const *ptr_A =
        reinterpret_cast<Array<ElementA, FragmentA::kElements / 2> const *>(&A);
    Array<typename Policy::Operator::ElementA, FragmentA::kElements / 2> *
        ptr_dst_A = reinterpret_cast<Array<typename Policy::Operator::ElementA,
                                           FragmentA::kElements / 2> *>(&dst_A);

    dst_B = convert_B(B);

    ptr_dst_A[0] = convert_A(ptr_A[0]);
    ptr_dst_A[1] = convert_A(ptr_A[1]);
    #else
      assert(0);
    #endif
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace warp
} // namespace gemm
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
