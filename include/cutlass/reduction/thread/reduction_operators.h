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
  \brief Kernel performing a reduction over densely packed tensors in global memory
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/tensor_ref.h"
#include "cutlass/numeric_types.h"
#include "cutlass/array.h"
#include "cutlass/functional.h"
#include "cutlass/numeric_conversion.h"

namespace cutlass {
namespace reduction {
namespace thread {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Mixed-precision reduction
template <
  typename ElementAccumulator_,
  typename Element_,
  int Count = 1
>
struct ReduceAdd {

  //
  // Type definitions
  //

  using ElementAccumulator = ElementAccumulator_;
  using Element = Element_;
  static int const kCount = Count;

  using FragmentAccumulator = cutlass::Array<ElementAccumulator, kCount>;
  using FragmentElement = cutlass::Array<Element, kCount>;

  struct Params { };

  //
  // Data members
  //

  /// Parameters object
  Params params;

  //
  // Methods
  //

  /// Constructor
  CUTLASS_HOST_DEVICE
  ReduceAdd(Params params_ = Params()): params(params_) { }

  /// Operator
  CUTLASS_HOST_DEVICE
  FragmentAccumulator operator()(
    FragmentAccumulator accumulator, 
    FragmentElement element) const {

    plus<FragmentAccumulator> op;

    NumericArrayConverter<
      ElementAccumulator, 
      Element, 
      kCount, 
      PreferredRoundingMode<ElementAccumulator, Element>::kRound> converter;

    return op(accumulator, converter(element));
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace thread
} // namespace reduction
} // namespace cutlass
