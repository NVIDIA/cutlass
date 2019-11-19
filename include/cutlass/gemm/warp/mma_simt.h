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
    \brief Templates implementing warp-level matrix multiply-accumulate operations.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/array.h"
#include "cutlass/numeric_types.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/warp/mma.h"

#include "cutlass/gemm/thread/mma.h"

#include "cutlass/gemm/warp/mma_simt_tile_iterator.h"
#include "cutlass/gemm/warp/mma_simt_policy.h"

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
  /// Shape of the warp in units of thread (concept: MmaSimtPolicy)
  typename Policy_,
  /// Number of partitions along K dimension
  int PartitionsK = 1,
  /// Used for partial specialization
  typename Enable = bool
>
class MmaSimt {
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

  /// Indicates class of matrix operator
  using OperatorClass = arch::OpClassSimt;

  using ThreadLayoutA = typename platform::conditional< platform::is_same< layout::ColumnMajorInterleaved<4>, LayoutA >::value,
                  layout::ColumnMajor,
                  typename platform::conditional < platform::is_same< layout::RowMajorInterleaved<4>, LayoutA >::value,
                      layout::RowMajor,
                      LayoutA>::type
                 >::type;
  
  using ThreadLayoutB = typename platform::conditional< platform::is_same< layout::ColumnMajorInterleaved<4>, LayoutB >::value,
                  layout::ColumnMajor,
                  typename platform::conditional < platform::is_same< layout::RowMajorInterleaved<4>, LayoutB >::value,
                      layout::RowMajor,
                      LayoutB>::type
                 >::type;

  static constexpr bool use_dp4a = (platform::is_same< layout::ColumnMajorInterleaved<4>, LayoutA>::value || 
                                    platform::is_same< layout::RowMajorInterleaved<4>, LayoutA >::value) && 
                                    platform::is_same< ElementA, int8_t >::value && 
                                    platform::is_same< ElementB, int8_t >::value;

  using dp4a_type = typename platform::conditional< use_dp4a , int8_t, bool >::type;

  /// Thread-level matrix multiply accumulate operator
  using ThreadMma = thread::Mma<
    GemmShape<
      Shape::kM / Policy::WarpShape::kRow,
      Shape::kN / Policy::WarpShape::kColumn,
      Policy::LaneMmaShape::kK>,
    ElementA,
    ThreadLayoutA,
    ElementB,
    ThreadLayoutB,
    ElementC,
    LayoutC,
    arch::OpMultiplyAdd,
    dp4a_type
  >;

public:

  /// Iterates over the A operand in memory
  using IteratorA = MmaSimtTileIterator<
    MatrixShape<Shape::kM, Policy::LaneMmaShape::kK>,
    Operand::kA,
    ElementA,
    LayoutA,
    Policy,
    PartitionsK,
    Shape::kK
  >;

  /// Storage for A tile
  using FragmentA = typename IteratorA::Fragment;

  /// Iterates over the B operand in memory
  using IteratorB = MmaSimtTileIterator<
    MatrixShape<Policy::LaneMmaShape::kK, Shape::kN>,
    Operand::kB,
    ElementB,
    LayoutB,
    Policy,
    PartitionsK,
    Shape::kK
  >;

  /// Storage for B tile
  using FragmentB = typename IteratorB::Fragment;

  /// Iterates over the C operand in memory
  using IteratorC = MmaSimtTileIterator<
    MatrixShape<Shape::kM, Shape::kN>,
    Operand::kC,
    ElementC,
    LayoutC,
    Policy
  >;

  /// Storage for C tile
  using FragmentC = typename ThreadMma::FragmentC;

public:

  //
  // Methods
  //

  /// Ctor
  CUTLASS_DEVICE
  MmaSimt() {}

  /// Performs a warp-level matrix multiply-accumulate operation
  CUTLASS_DEVICE
  void operator()(
    FragmentC &d, 
    FragmentA const &a, 
    FragmentB const &b, 
    FragmentC const &c, int group_idx = 0) const {

    ThreadMma mma;

    mma(d, a, b, c);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace warp
} // namespace gemm
} // namespace cutlass
