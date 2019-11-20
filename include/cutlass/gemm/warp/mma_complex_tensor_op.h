/***************************************************************************************************
 * Copyright (c) 2017-2019, NVIDIA CORPORATION.  All rights reserved.
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
    \brief Templates implementing warp-level matrix multiply-accumulate operations targeting
      Tensor Cores.
*/

#pragma once

#include "cutlass/cutlass.h"

#include "cutlass/array.h"
#include "cutlass/complex.h"
#include "cutlass/numeric_types.h"
#include "cutlass/matrix_shape.h"

#include "cutlass/arch/memory_sm75.h"
#include "cutlass/arch/mma_sm75.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/warp/mma.h"

#include "cutlass/gemm/warp/mma_tensor_op_policy.h"
#include "cutlass/gemm/warp/mma_tensor_op.h"

#include "cutlass/gemm/warp/mma_tensor_op_tile_iterator.h"
/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace gemm {
namespace warp {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  /// Size of the Gemm problem - concept: gemm::GemmShape<>
  typename Shape_,
  /// Data type of A elements
  typename RealElementA,
  /// Layout of A matrix (concept: MatrixLayout)
  typename LayoutA_,
  /// Data type of B elements
  typename RealElementB,
  /// Layout of B matrix (concept: MatrixLayout)
  typename LayoutB_,
  /// Element type of C matrix
  typename RealElementC,
  /// Layout of C matrix (concept: MatrixLayout)
  typename LayoutC_,
  /// Policy describing warp-level MmaTensorOp (concept: MmaTensorOp policy)
  typename Policy_,
  /// Complex transform on A operand
  ComplexTransform TransformA = ComplexTransform::kNone,
  /// Complex transform on B operand
  ComplexTransform TransformB = ComplexTransform::kNone,
  /// Used for partial specialization
  typename Enable = bool
>
class MmaComplexTensorOp;

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Partial specialization for complex*complex+complex => complex using real-valued TensorOps
template <
  /// Size of the Gemm problem - concept: gemm::GemmShape<>
  typename Shape_,
  /// Data type of A elements
  typename RealElementA,
  /// Layout of A matrix (concept: MatrixLayout)
  typename LayoutA_,
  /// Data type of B elements
  typename RealElementB,
  /// Layout of B matrix (concept: MatrixLayout)
  typename LayoutB_,
  /// Element type of C matrix
  typename RealElementC,
  /// Layout of C matrix (concept: MatrixLayout)
  typename LayoutC_,
  /// Policy describing warp-level MmaTensorOp (concept: MmaTensorOp policy)
  typename Policy_,
  /// Complex transform on A operand
  ComplexTransform TransformA,
  /// Complex transform on B operand
  ComplexTransform TransformB,
  /// Used for partial specialization
  typename Enable
>
class MmaComplexTensorOp<
  Shape_, 
  complex<RealElementA>, 
  LayoutA_, 
  complex<RealElementB>,
  LayoutB_,
  complex<RealElementC>,
  LayoutC_,
  Policy_,
  TransformA,
  TransformB,
  Enable>  {
public:
  /// Shape of warp-level matrix operation (concept: GemmShape)
  using Shape = Shape_;

  /// Data type of multiplicand A
  using ElementA = complex<RealElementA>;

  /// Layout of multiplicand A
  using LayoutA = LayoutA_;

  /// Data type of multiplicand B
  using ElementB = complex<RealElementB>;

  /// Layout of multiplicand B
  using LayoutB = LayoutB_;

  /// Data type of accumulator matrix C
  using ElementC = complex<RealElementC>;

  /// Layout of accumulator matrix C
  using LayoutC = LayoutC_;

  /// Shape of the warp in units of thread (concept: MmaLanePolicySimt)
  using Policy = Policy_;

  /// Complex transform on A operand
  static ComplexTransform const kTransformA = TransformA;

  /// Complex transform on B operand
  static ComplexTransform const kTransformB = TransformB;

  /// Indicates class of matrix operator
  using OperatorClass = arch::OpClassTensorOp;

  /// Number of threads participating in warp-level matrix product
  static int const kThreadCount = 32;

public:

  /// Iterates over the A operand in memory
  using IteratorA = MmaTensorOpMultiplicandTileIterator<
    MatrixShape<Shape::kM, Shape::kK>,
    Operand::kA,
    ElementA,
    LayoutA,
    MatrixShape<Policy::Operator::Shape::kM, Policy::Operator::Shape::kK>,
    Policy::OpDelta::kRow,
    32,
    1
  >;

  /// Storage for A tile
  using FragmentA = typename IteratorA::Fragment;

  /// Iterates over the B operand in memory
  using IteratorB = MmaTensorOpMultiplicandTileIterator<
    MatrixShape<Shape::kK, Shape::kN>,
    Operand::kB,
    ElementB,
    LayoutB,
    MatrixShape<Policy::Operator::Shape::kK, Policy::Operator::Shape::kN>,
    Policy::OpDelta::kColumn,
    32,
    1
  >;

  /// Storage for B tile
  using FragmentB = typename IteratorB::Fragment;


  static_assert(
    !(Shape::kM % Policy::Operator::Shape::kM) && 
    !(Shape::kN % Policy::Operator::Shape::kN),
    "Shape of warp-level Mma must be divisible by operator shape.");

  /// Number of mma operations performed
  using MmaIterations = MatrixShape<
    Shape::kM / Policy::Operator::Shape::kM,
    Shape::kN / Policy::Operator::Shape::kN
  >;

  /// Iterates over the C operand in memory
  using IteratorC = MmaTensorOpAccumulatorTileIterator<
     MatrixShape<Shape::kM, Shape::kN>, 
     ElementC, 
     LayoutC,
     typename Policy::Operator::Shape, 
     typename Policy::OpDelta>;

  /// Storage for C tile, the accumulator. Note, regardless of multiplicand type, this
  /// storage arrangement is to be considered 'planar complex' in the sense that all real-valued
  /// parts are stored consecutively followed by all imaginary parts. This matches the structure
  /// of Tensor Cores which are always real-valued matrix multiplies.
  using FragmentC = typename IteratorC::Fragment;

  static_assert(
    FragmentC::kElements == 2 * MmaIterations::kCount * Policy::Operator::FragmentC::kElements,
    "Unexpected planar complex fragment length.");

private:

  //
  // Data members
  //

  /// Underlying real-valued matrix multiply operator (concept: arch::Mma)
  typename Policy::Operator mma;

public:

  //
  // Methods
  //

  /// Ctor
  CUTLASS_DEVICE
  MmaComplexTensorOp() {}

  /// Performs a warp-level matrix multiply-accumulate operation
  CUTLASS_DEVICE
  void operator()(
    FragmentC &D, 
    FragmentA const &A, 
    FragmentB const &B, 
    FragmentC const &C) const {

    // Alias types for underlying real-valued matrix multiply operator
    using MmaOperandA = typename Policy::Operator::FragmentA;
    using MmaOperandB = typename Policy::Operator::FragmentB;
    using MmaOperandC = typename Policy::Operator::FragmentC;

    static_assert(MmaOperandA::kElements == 1, 
      "This implementation only supports math instructions in which exactly one element is needed for the A operand."
      "We can geneneralize later.");

    static_assert(MmaOperandB::kElements == 1, 
      "This implementation only supports math instructions in which exactly one element is needed for the A operand."
      "We can geneneralize later.");

    D = C;

    CUTLASS_PRAGMA_UNROLL
    for (int m = 0; m < MmaIterations::kRow; ++m) {

      // mma(accum.real(), a.real(), b.real(), accum.real());
      CUTLASS_PRAGMA_UNROLL
      for (int n = 0; n < MmaIterations::kColumn; ++n) {

        // Pack operands together. This may result in actual MOVs 
        MmaOperandA operand_A;
        MmaOperandB operand_B;

        operand_A[0] = A[m].real();
        operand_B[0] = B[n].real();

        // Real-valued accumulator part
        MmaOperandC *accum = reinterpret_cast<MmaOperandC *>(&D) + 
          (m + n * MmaIterations::kRow);

          mma(*accum, operand_A, operand_B, *accum);
      }

      // mma(accum.imag(), a.real(), b.imag(), accum.imag()); 
      CUTLASS_PRAGMA_UNROLL
      for (int n = MmaIterations::kColumn - 1; n >= 0; --n) {

        // Pack operands together. This may result in actual MOVs 
        MmaOperandA operand_A;
        MmaOperandB operand_B;

        operand_A[0] = A[m].real();
        operand_B[0] = (kTransformB == ComplexTransform::kConjugate ? -B[n].imag() : B[n].imag());

        // Complex-valued accumulator part
        MmaOperandC *accum = reinterpret_cast<MmaOperandC *>(&D) + 
          (m + n * MmaIterations::kRow) + MmaIterations::kCount;

        mma(*accum, operand_A, operand_B, *accum);
      }

      // mma(accum.real(), -a.imag(), b.imag(), accum.real())
      CUTLASS_PRAGMA_UNROLL
      for (int n = 0; n < MmaIterations::kColumn; ++n) {

        // Pack operands together. This may result in actual MOVs 
        MmaOperandA operand_A;
        MmaOperandB operand_B;

        // A imaginary part is intentionally negated
        operand_A[0] = (kTransformA == ComplexTransform::kConjugate ? A[m].imag() : -A[m].imag());
        operand_B[0] = (kTransformB == ComplexTransform::kConjugate ? -B[n].imag() : B[n].imag());

        // Complex-valued accumulator part
        MmaOperandC *accum = reinterpret_cast<MmaOperandC *>(&D) + 
          (m + n * MmaIterations::kRow);

        mma(*accum, operand_A, operand_B, *accum);
      }

      // mma(accum.imag(), a.imag(), b.real(), accum.imag())
      CUTLASS_PRAGMA_UNROLL
      for (int n = MmaIterations::kColumn - 1; n >= 0; --n) {

        // Pack operands together. This may result in actual MOVs 
        MmaOperandA operand_A;
        MmaOperandB operand_B;

        operand_A[0] = (kTransformA == ComplexTransform::kConjugate ? -A[m].imag() : A[m].imag());
        operand_B[0] = B[n].real();

        // Real-valued accumulator part
        MmaOperandC *accum = reinterpret_cast<MmaOperandC *>(&D) + 
          (m + n * MmaIterations::kRow) + MmaIterations::kCount;

        mma(*accum, operand_A, operand_B, *accum);
      }
    }
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// TODO - partial specializations of real*complex and complex*real

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace warp
} // namespace gemm
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
