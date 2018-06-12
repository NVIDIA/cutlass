/***************************************************************************************************
 * Copyright (c) 2017-2018, NVIDIA CORPORATION.  All rights reserved.
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
    \brief Implements the BLAS linear scaling function alpha*AB + beta*C
*/
#pragma once

#include <cutlass/fragment_multiply_add.h>

namespace cutlass {
namespace gemm {

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Functor to compute linear combination of fragments
template <typename Scalar_, typename FragmentMultiplyAdd_ = FragmentMultiplyAdd<Scalar_> >
struct LinearScaling {
  // The scalar.
  typedef Scalar_ Scalar;
  // The adapater.
  typedef FragmentMultiplyAdd_ FragmentMultiplyAdd;

  /// The parameters.
  struct Params {
    /// The alpha/beta scaling params.
    Scalar alpha, beta;

    /// Initialize the parameters.
    template <typename GemmDesc_>
    CUTLASS_HOST_DEVICE int initialize(GemmDesc_ const& desc) {
      alpha = desc.alpha;
      beta = desc.beta;
      return 0;
    }
  };

  /// Ctor.
  CUTLASS_DEVICE LinearScaling(Params const& params) : alpha(params.alpha), beta(params.beta) {}

  /// Evaluate the functor.
  template <typename FragmentA_, typename FragmentB_>
  CUTLASS_DEVICE void evaluate(FragmentA_ const& accum, FragmentB_& output) {
    FragmentMultiplyAdd mad;
    mad.multiply(alpha, accum, output);
  }

  /// Evaluate the functor.
  template <typename FragmentA_, typename FragmentB_>
  CUTLASS_DEVICE void evaluate(FragmentA_ const& accum, FragmentB_ const& old, FragmentB_& output) {
    FragmentMultiplyAdd mad;
    FragmentB_ tmp;
    mad.multiply(beta, old, tmp);
    mad.multiply_add(alpha, accum, tmp, output);
  }

  /// The alpha/beta scaling factors.
  Scalar alpha, beta;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace gemm
}  // namespace cutlass
