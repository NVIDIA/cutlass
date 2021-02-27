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
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
  \brief Functor performing linear combination operations used by epilogues.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"
#include "cutlass/array.h"
#include "cutlass/functional.h"
#include "cutlass/numeric_conversion.h"
#include "cutlass/epilogue/thread/activation.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace epilogue {
namespace thread {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// This is a partial specialization for fused Bias and ReLU. It supports the option of packing
/// ReLU conditionals in a bit vector that may be used by backwards passes as an optimization.
///
/// This class can only be used with cutlass::epilogue::threadblock::EpilogueWithBroadcast<>.
///
/// This base class is meant to define the concept required of the
/// EpilogueWithBroadcast::OutputOp
template <
  typename ElementC_,
  typename ElementAccumulator_,
  typename ElementCompute_,
  typename ElementZ_,
  int ElementsPerAccess,
  bool StoreT = true
>
class LinearCombinationBiasRelu {
public:

  using ElementOutput = ElementC_;
  using ElementC = ElementC_;
  using ElementAccumulator = ElementAccumulator_;
  using ElementCompute = ElementCompute_;
  using ElementZ = ElementZ_;

  using ElementT = uint1b_t;

  static int const kElementsPerAccess = ElementsPerAccess;
  static int const kCount = kElementsPerAccess;

  using ElementwiseOp = ReLu<ElementCompute>;
  using BinaryOp = plus<ElementCompute>;

  using FragmentAccumulator = Array<ElementAccumulator, kElementsPerAccess>;
  using FragmentCompute = Array<ElementCompute, kElementsPerAccess>;
  using FragmentC = Array<ElementOutput, kElementsPerAccess>;
  using FragmentZ = Array<ElementZ, kElementsPerAccess>;
  using FragmentT = Array<ElementT, kElementsPerAccess>;

  /// If true, the 'Z' tensor is stored
  static bool const kStoreZ = true;

  /// If true, the 'T' tensor is stored
  static bool const kStoreT = StoreT;

  /// Host-constructable parameters structure
  struct Params {

    ElementCompute alpha;                  ///< scales accumulators
    ElementCompute beta;                   ///< scales source tensor
    ElementCompute const *alpha_ptr;       ///< pointer to accumulator scalar - if not null, loads it from memory
    ElementCompute const *beta_ptr;        ///< pointer to source scalar - if not null, loads it from memory
    ElementCompute threshold;              ///< ReLu threshold

    //
    // Methods
    //

    CUTLASS_HOST_DEVICE
    Params(): 
      alpha(ElementCompute(1)), 
      beta(ElementCompute()), 
      alpha_ptr(nullptr), 
      beta_ptr(nullptr),
      threshold(ElementCompute()) { }

    CUTLASS_HOST_DEVICE
    Params(
      ElementCompute alpha,
      ElementCompute beta,
      ElementCompute threshold = ElementCompute()
    ): 
      alpha(alpha), beta(beta), alpha_ptr(nullptr), beta_ptr(nullptr), threshold(threshold) {

    }

    CUTLASS_HOST_DEVICE
    Params(
      ElementCompute alpha
    ): alpha(alpha), beta(0), alpha_ptr(nullptr), beta_ptr(nullptr), threshold(threshold) {

    }

    CUTLASS_HOST_DEVICE
    Params(
      ElementCompute const *alpha_ptr,
      ElementCompute const *beta_ptr,
      ElementCompute threshold = ElementCompute()
    ): alpha(0), beta(0), alpha_ptr(alpha_ptr), beta_ptr(beta_ptr), threshold(threshold) {

    }

    CUTLASS_HOST_DEVICE
    Params(
      ElementCompute const *alpha_ptr
    ): alpha(0), beta(0), alpha_ptr(alpha_ptr), beta_ptr(nullptr), threshold(threshold) {

    }
  };

private:

  //
  // Data members
  //

  ElementCompute alpha_;
  ElementCompute beta_;
  ElementCompute threshold_;

public:

  //
  // Methods
  //

  /// Constructor from Params
  CUTLASS_HOST_DEVICE
  LinearCombinationBiasRelu(Params const &params) {

    alpha_ = (params.alpha_ptr ? *params.alpha_ptr : params.alpha);
    beta_ = (params.beta_ptr ? *params.beta_ptr : params.beta);
    threshold_ = params.threshold;
  }

  /// Returns true if source is needed
  CUTLASS_HOST_DEVICE
  bool is_source_needed() const {
    return beta_ != ElementCompute(0);
  }

  /// Functionally required for serial reduction in the epilogue
  CUTLASS_HOST_DEVICE
  void set_k_partition(int k_partition, int k_partition_count) {
    if (k_partition) {
      beta_ = ElementCompute(1);
    }
  }

  /// Applies the operation when is_source_needed() is true
  CUTLASS_HOST_DEVICE
  void operator()(
    FragmentZ &frag_Z, 
    FragmentT &frag_T, 
    FragmentAccumulator const &AB,
    FragmentC const &frag_C,
    FragmentCompute const &V) const {

    BinaryOp binary_op;

    FragmentCompute tmp_Accum = NumericArrayConverter<ElementCompute, ElementAccumulator, kElementsPerAccess>()(AB);
    FragmentCompute tmp_C = NumericArrayConverter<ElementCompute, ElementC, kElementsPerAccess>()(frag_C);
    FragmentCompute result_Z;
    FragmentCompute result_T;

    bool conditions[kElementsPerAccess];

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < kElementsPerAccess; ++i) {
      ElementCompute z = binary_op(alpha_ * tmp_Accum[i] + beta_ * tmp_C[i], V[i]);

      bool condition = !(z < threshold_);
      z = fmax(z, threshold_);

      result_Z[i] = z;
      conditions[i] = condition;
    }

    NumericArrayConverter<ElementZ, ElementCompute, kElementsPerAccess> convert_z;
    frag_Z = convert_z(result_Z);

    if (kStoreT) {
      PackPredicates<kElementsPerAccess> pack_predicates;
      frag_T = pack_predicates(conditions); 
    }
  }

  /// Applies the operation when is_source_needed() is false
  CUTLASS_HOST_DEVICE
  void operator()(
    FragmentZ &frag_Z, 
    FragmentT &frag_T, 
    FragmentAccumulator const &AB,
    FragmentCompute const &V) const {

    BinaryOp binary_op;

    FragmentCompute tmp_Accum = NumericArrayConverter<ElementCompute, ElementAccumulator, kElementsPerAccess>()(AB);
    FragmentCompute result_Z;
    FragmentCompute result_T;

    bool conditions[kElementsPerAccess];

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < kElementsPerAccess; ++i) {
      ElementCompute z = binary_op(alpha_ * tmp_Accum[i], V[i]);

      bool condition = !(z < threshold_);
      z = fmax(z, threshold_);

      result_Z[i] = z;
      conditions[i] = condition;
    }

    NumericArrayConverter<ElementZ, ElementCompute, kElementsPerAccess> convert_z;
    frag_Z = convert_z(result_Z);

    if (kStoreT) {
      PackPredicates<kElementsPerAccess> pack_predicates;
      frag_T = pack_predicates(conditions);
    }
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace thread
} // namespace epilogue
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
