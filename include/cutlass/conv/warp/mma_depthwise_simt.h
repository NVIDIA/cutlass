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

#include "cutlass/gemm/warp/mma_simt.h"
#include "cutlass/conv/warp/mma_depthwise_simt_tile_iterator.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace conv {
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
    /// Complex transformation on operand A
    ComplexTransform TransformA = ComplexTransform::kNone,
    /// Complex transformation on operand B
    ComplexTransform TransformB = ComplexTransform::kNone,
    /// Used for partial specialization
    typename Enable = bool>
class MmaDepthwiseSimt
    : public cutlass::gemm::warp::
          MmaSimt<Shape_, ElementA_, LayoutA_, ElementB_, LayoutB_, ElementC_, LayoutC_, Policy_> {
  using Base = cutlass::gemm::warp::
      MmaSimt<Shape_, ElementA_, LayoutA_, ElementB_, LayoutB_, ElementC_, LayoutC_, Policy_>;
      
public:
  /// Shape of warp-level matrix operation (concept: GemmShape)
  using Shape = Shape_;  // < 64, 16 , 8>

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

  /// Hard-coded for now
  using ArchTag = arch::Sm50;

  /// Complex transform on A operand
  static ComplexTransform const kTransformA = TransformA;

  /// Complex transform on B operand
  static ComplexTransform const kTransformB = TransformB;

public:

  /// Iterates over the B operand in memory
  using IteratorB = cutlass::conv::warp::DepthwiseMmaSimtTileIterator<
    MatrixShape<Policy::LaneMmaShape::kK, Shape::kN>,
    cutlass::gemm::Operand::kB,
    ElementB,
    LayoutB,
    Policy,
    PartitionsK,
    Shape::kK
  >;

  /// Storage for B tile
  using FragmentB = typename IteratorB::Fragment;

  /// Storage for transformed A tile
  using TransformedFragmentB = FragmentB;

public:

  //
  // Methods
  //

  /// Ctor
  CUTLASS_DEVICE
  MmaDepthwiseSimt():Base() {}
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace warp
} // namespace gemm
} // namespace cutlass
