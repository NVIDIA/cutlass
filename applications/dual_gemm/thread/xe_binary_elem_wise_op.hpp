/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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

#include "cutlass/cutlass.h"
#include "cutlass/functional.h"
#include "cutlass/epilogue/thread/activation.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace epilogue {
namespace thread {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Applies a linear combination operator to an array of elements.
///
/// Computes linear scaling: D = elem-wise-binary-p(unary-op(accume1), unary-op(accume2))
///
template <
  typename ElementOutput_,  ///< Data type used to load and store tensors
  template <class> class UnaryOpLeft, // unary operation for the left hand side acumulator
  template <class> class UnaryOpRight, // unary operation for the right hand side acumulator
  template <class> class BinaryOp,
  typename ElementAccumulator_ = ElementOutput_,       ///< Accumulator data type
  typename ElementCompute_ = ElementOutput_          ///< Data type used to compute linear combination
  >
class FusedElementWiseOpDualGemm {
public:
 
  CUTLASS_HOST_DEVICE
  ElementOutput_ operator()(
      ElementAccumulator_ const &lhs, 
      ElementAccumulator_ const &rhs) const {
        UnaryOpLeft<ElementCompute_> element_wise_unary_op_lhs;
        UnaryOpRight<ElementCompute_> element_wise_unaryop_rhs;
        BinaryOp<ElementCompute_> element_wise_binary;
 
 return  element_wise_binary(element_wise_unary_op_lhs(lhs), element_wise_unaryop_rhs(rhs));
}

  template <int kCount>
  CUTLASS_HOST_DEVICE cutlass::Array<ElementOutput_, kCount> operator() (
    cutlass::Array<ElementAccumulator_, kCount> const &lhs, 
    cutlass::Array<ElementAccumulator_, kCount> const &rhs) const {
      UnaryOpLeft<cutlass::Array<ElementAccumulator_, kCount> > element_wise_unary_op_lhs;
      UnaryOpRight<cutlass::Array<ElementAccumulator_, kCount> > element_wise_unaryop_rhs;
      BinaryOp<cutlass::Array<ElementAccumulator_, kCount> > element_wise_binary;
    return  element_wise_binary(element_wise_unary_op_lhs(lhs), element_wise_unaryop_rhs(rhs));
  }
};
}
}
}
