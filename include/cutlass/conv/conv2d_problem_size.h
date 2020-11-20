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
    \brief This file contains definitions and utility functions for describing convolution problem sizes.

  Conv2dProblem desciption:
    activation (NHWC), 
    filter (KRSC), 
    output (NPQK), 
    pading (pad_h, pad_w), 
    stride (stride_h, stride_w),
    dilation (dilation_h, dilation_w).
    
  Free functions to map:
    Map tensor extents (Conv2d -> ImplicitGemm)      : implicit_gemm_tensor_[a|b|c]_extent(ConvolutionOperator)
    Map tensor sizes (Conv2d -> ImplicitGemm)        : implicit_gemm_tensor_[a|b|c]_size(ConvolutionOperator)
    Map tensor problem sizes (Conv2d -> ImplicitGemm): implicit_gemm_problem_size(ConvolutionOperator)
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/tensor_coord.h"
#include "cutlass/fast_math.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/matrix_coord.h"
#include "cutlass/conv/convolution.h"

namespace cutlass {
namespace conv {

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Problem size structure
struct Conv2dProblemSize {

  // Conv2d strictly problem size parameters
  int N, H, W, C, P, Q, K, R, S;
  int pad_h, pad_w;
  int stride_h, stride_w;
  int dilation_h, dilation_w;
  Mode mode;

  // Conv2d implementation-related parameters 
  int split_k_slices;
  int groups;

  //
  // Methods
  //

public:
  CUTLASS_HOST_DEVICE
  Conv2dProblemSize(): 
    N(0), H(0), W(0), C(0), P(0), Q(0), K(0), R(0), S(0),
    pad_h(0), pad_w(0), stride_h(1), stride_w(1), dilation_h(1), dilation_w(1),
    mode(Mode::kConvolution), split_k_slices(1), groups(1) { }
 
  /// Constructor for default padding, stride, dilation, and split-K
  CUTLASS_HOST_DEVICE
  Conv2dProblemSize(
    int N,
    int H,
    int W,
    int C,
    int P,
    int Q,
    int K,
    int R,
    int S,
    Mode mode
  ): 
    N(N), H(H), W(W), C(C), P(P), Q(Q), K(K), R(R), S(S),
    pad_h(R / 2), pad_w(S / 2), stride_h(1), stride_w(1), dilation_h(1), dilation_w(1), 
    mode(mode), split_k_slices(1), groups (1) { }
  
  /// Constructor
  CUTLASS_HOST_DEVICE
  Conv2dProblemSize(
    int N,
    int H,
    int W,
    int C,
    int K,
    int R,
    int S,
    int P,
    int Q,
    int pad_h,
    int pad_w,
    int stride_h,
    int stride_w,
    int dilation_h,
    int dilation_w,
    Mode mode,
    int split_k_slices = 1,
    int groups = 1
  ): 
    N(N), H(H), W(W), C(C), K(K), R(R), S(S), P(P), Q(Q),
    pad_h(pad_h), pad_w(pad_w), stride_h(stride_h), stride_w(stride_w), 
    dilation_h(dilation_h), dilation_w(dilation_w), 
    mode(mode), split_k_slices(split_k_slices), groups (groups) { }

  /// Constructs convolution problem size from cutlass Tensor4DCoord and MatrixCoord 
  // set user-defined output size and sets P and Q (include all data members in ctor)
  CUTLASS_HOST_DEVICE
  Conv2dProblemSize(
    cutlass::Tensor4DCoord input_size,    // NHWC
    cutlass::Tensor4DCoord filter_size,   // KRSC
    cutlass::Tensor4DCoord padding,       // pad_h, _, pad_w, _
    cutlass::MatrixCoord stride,          // stride_h, stride_w
    cutlass::MatrixCoord dilation,        // dilation_h, dilation_w
    cutlass::Tensor4DCoord output_size,   // NPQK
    cutlass::conv::Mode mode = cutlass::conv::Mode::kCrossCorrelation,
    int split_k_slices = 1,
    int groups = 1
  ):
    N(input_size.n()), H(input_size.h()), W(input_size.w()), C(input_size.c()),
    K(filter_size.n()), R(filter_size.h()), S(filter_size.w()),
    pad_h(padding[0]), pad_w(padding[2]), 
    stride_h(stride.row()), stride_w(stride.column()), 
    dilation_h(dilation.row()), dilation_w(dilation.column()),
    P(output_size.h()), Q(output_size.w()),     
    mode(mode), split_k_slices(split_k_slices), groups(groups) {}

  /// Constructs convolution problem size from cutlass Tensor4DCoord and MatrixCoord 
  // computes output size and sets P and Q (skip output from ctor arguments)
  CUTLASS_HOST_DEVICE  
  Conv2dProblemSize(
    cutlass::Tensor4DCoord input_size,   // NHWC
    cutlass::Tensor4DCoord filter_size,  // KRSC
    cutlass::Tensor4DCoord padding,      // pad_h, _, pad_w, _
    cutlass::MatrixCoord stride,         // stride_h, stride_w
    cutlass::MatrixCoord dilation,       // dilation_h, dilation_w
    cutlass::conv::Mode mode = cutlass::conv::Mode::kCrossCorrelation,
    int split_k_slices = 1,
    int groups = 1
  ):
    N(input_size.n()), H(input_size.h()), W(input_size.w()), C(input_size.c()),
    K(filter_size.n()), R(filter_size.h()), S(filter_size.w()),
    pad_h(padding[0]), pad_w(padding[2]),
    stride_h(stride.row()), stride_w(stride.column()), 
    dilation_h(dilation.row()), dilation_w(dilation.column()),
    mode(mode), split_k_slices(split_k_slices), groups(groups) {
      // set output P and Q
      P = ((H + pad_h * 2 - R * dilation_h) / stride_h) + 1;
      Q = ((W + pad_w * 2 - S * dilation_w) / stride_w) + 1;
    }

  /// Constructs convolution problem size from cutlass Tensor4DCoord and MatrixCoord 
  // set user-defined output size and sets P and Q (skip padding, striding, and dilation)
  CUTLASS_HOST_DEVICE
  Conv2dProblemSize(
    cutlass::Tensor4DCoord input_size,    // NHWC
    cutlass::Tensor4DCoord filter_size,   // KRSC
    cutlass::Tensor4DCoord output_size,   // NPQK
    cutlass::conv::Mode mode = cutlass::conv::Mode::kCrossCorrelation,
    int split_k_slices = 1,
    int groups = 1
  ):
    N(input_size.n()), H(input_size.h()), W(input_size.w()), C(input_size.c()),
    K(filter_size.n()), R(filter_size.h()), S(filter_size.w()),
    P(output_size.h()), Q(output_size.w()), 
    pad_h(R / 2), pad_w(S / 2), stride_h(1), stride_w(1), 
    dilation_h(1), dilation_w(1),
    mode(mode), split_k_slices(split_k_slices), groups(groups) {}

  // Reset covolution mode in the problem
  CUTLASS_HOST_DEVICE
  Conv2dProblemSize reset_mode(cutlass::conv::Mode mode_) {
    Conv2dProblemSize tmp(*this);
    tmp.mode = mode_; 
    return tmp; 
  }

  // Reset covolution mode in the problem
  CUTLASS_HOST_DEVICE
  Conv2dProblemSize reset_split_k_slices(int split_k_slices_) {
    Conv2dProblemSize tmp(*this);
    tmp.split_k_slices = split_k_slices_; 
    return tmp; 
  }

  /// Equality operator (ignores mode and split_k_slice)
  CUTLASS_HOST_DEVICE
  bool operator==(Conv2dProblemSize const &conv) const {
    return (
      (N == conv.N) && (W == conv.H) && (W == conv.W) && (C == conv.C) &&
      (K == conv.K) && (R == conv.R) && (S == conv.S) &&
      (P == conv.P) && (Q == conv.Q) &&
      (pad_h == conv.pad_h) && (pad_w == conv.pad_w) &&
      (stride_h == conv.stride_h) && (stride_w == conv.stride_w) &&
      (dilation_h == conv.dilation_h) && (dilation_h == conv.dilation_h)
    );  
  }

  /// Inequality operator
  CUTLASS_HOST_DEVICE
  bool operator!=(Conv2dProblemSize const &rhs) const {
    return !(*this == rhs);
  }

  /// Returns activation extent as Tensor4DCoord
  CUTLASS_HOST_DEVICE
  cutlass::Tensor4DCoord activation_extent() const {

    return cutlass::Tensor4DCoord ({N, H, W, C});
  }

  /// Returns filter extent as Tensor4DCoord
  CUTLASS_HOST_DEVICE
  cutlass::Tensor4DCoord filter_extent() const {

    return cutlass::Tensor4DCoord ({K, R, S, C});
  }

  /// Returns output extent as Tensor4DCoord
  CUTLASS_HOST_DEVICE
  cutlass::Tensor4DCoord output_extent() const {

    return cutlass::Tensor4DCoord ({N, P, Q, K});
  }

  /// Returns activation size in number of elements
  CUTLASS_HOST_DEVICE
  int64_t activation_size() const {

    return (N * H * W * C);
  }

  /// Returns filter size in number of elements
  CUTLASS_HOST_DEVICE
  int64_t filter_size() const {

    return (K * R * S * C);
  }

  /// Returns output size in number of elements
  CUTLASS_HOST_DEVICE
  int64_t output_size() const {

    return (N * P * Q * K);
  }
  
  /// Returns output extent as Tensor4DCoord
  CUTLASS_HOST_DEVICE
  cutlass::Tensor4DCoord padding() const {

    return cutlass::Tensor4DCoord ({pad_h, pad_h, pad_w, pad_w});
  }

  /// Returns stride as MatrixCoord
  CUTLASS_HOST_DEVICE
  cutlass::MatrixCoord stride() const {

    return cutlass::MatrixCoord ({stride_h, stride_w});
  }

  /// Returns dilation as MatrixCoord
  CUTLASS_HOST_DEVICE
  cutlass::MatrixCoord dilation() const {

    return cutlass::MatrixCoord ({dilation_h, dilation_w});
  }
};

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                  ImplicitGemm helper functions                                 //
////////////////////////////////////////////////////////////////////////////////////////////////////

/// Determine the problem size of the implicit GEMM operation
CUTLASS_HOST_DEVICE
cutlass::gemm::GemmCoord implicit_gemm_problem_size(
  Operator conv_operator, 
  Conv2dProblemSize const &problem_size) {
  // Compute problem size
  switch (conv_operator) {
  case Operator::kFprop:
    return gemm::GemmCoord(
      problem_size.N * problem_size.P * problem_size.Q,
      problem_size.K,
      problem_size.R * problem_size.S * problem_size.C
    );
  case Operator::kDgrad:
    return gemm::GemmCoord(
      problem_size.N * problem_size.H * problem_size.W,
      problem_size.C,
      problem_size.R * problem_size.S * problem_size.K
    );
  case Operator::kWgrad:
    return gemm::GemmCoord(
      problem_size.K,
      problem_size.R * problem_size.S * problem_size.C,
      problem_size.N * problem_size.P * problem_size.Q
    );
  default:
    break;
  }
  return gemm::GemmCoord();
}

// Determine the number of gemm_k iterations for conv2d problem using implicit gemm algorithm
CUTLASS_HOST_DEVICE
int implicit_gemm_k_iterations(
  Operator conv_operator, 
  int threadblock_K, 
  Conv2dProblemSize const &problem_size) {

  int iterations = 0;
  int elements_per_split_k_slice = 0;

  switch (conv_operator) {
  case Operator::kFprop:
    elements_per_split_k_slice = (problem_size.C + problem_size.split_k_slices - 1) / problem_size.split_k_slices;
    iterations = problem_size.R * problem_size.S * ((elements_per_split_k_slice + threadblock_K - 1) / threadblock_K);
    break;

  case Operator::kDgrad:
    elements_per_split_k_slice = (problem_size.K + problem_size.split_k_slices - 1) / problem_size.split_k_slices;
    iterations = problem_size.R * problem_size.S * ((elements_per_split_k_slice + threadblock_K - 1) / threadblock_K);
    break;

  case Operator::kWgrad:
    elements_per_split_k_slice = (problem_size.N * problem_size.P * problem_size.Q + problem_size.split_k_slices - 1) / problem_size.split_k_slices;
    iterations = (elements_per_split_k_slice + threadblock_K - 1) / threadblock_K;
    break;

  default:
    break;
  }

  return iterations;
}


////////////////////////////////////////////////////////////////////////////////
//  Mapping function (ImplicitGemm A, B, C -> Conv Activation, Filter, Output)
////////////////////////////////////////////////////////////////////////////////
/// Returns ImplicitGemm tensor A extent as Tensor4DCoord
CUTLASS_HOST_DEVICE
cutlass::Tensor4DCoord implicit_gemm_tensor_a_extent(
  Operator conv_operator,
  Conv2dProblemSize const &problem_size) {
  switch (conv_operator) {
    case cutlass::conv::Operator::kFprop: return problem_size.activation_extent();
    case cutlass::conv::Operator::kDgrad: return problem_size.output_extent();
    case cutlass::conv::Operator::kWgrad: return problem_size.output_extent();
    default : break;
  }
  return cutlass::Tensor4DCoord();
}

/// Returns ImplicitGemm tensor B extent as Tensor4DCoord
CUTLASS_HOST_DEVICE
cutlass::Tensor4DCoord implicit_gemm_tensor_b_extent(
  Operator conv_operator,
  Conv2dProblemSize const &problem_size) {
  switch (conv_operator) {
    case cutlass::conv::Operator::kFprop: return problem_size.filter_extent();
    case cutlass::conv::Operator::kDgrad: return problem_size.filter_extent();
    case cutlass::conv::Operator::kWgrad: return problem_size.activation_extent();
    default : break;
  }
  return cutlass::Tensor4DCoord();
}

/// Returns ImplicitGemm tensor C extent as Tensor4DCoord
CUTLASS_HOST_DEVICE
cutlass::Tensor4DCoord implicit_gemm_tensor_c_extent(
  Operator conv_operator,
  Conv2dProblemSize const &problem_size) {
  switch (conv_operator) {
    case cutlass::conv::Operator::kFprop: return problem_size.output_extent();
    case cutlass::conv::Operator::kDgrad: return problem_size.activation_extent();
    case cutlass::conv::Operator::kWgrad: return problem_size.filter_extent();
    default : break;
  }
  return cutlass::Tensor4DCoord();
}

/// Returns ImplicitGemm tensor A size in number of elements
CUTLASS_HOST_DEVICE
int64_t implicit_gemm_tensor_a_size(
  Operator conv_operator,
  Conv2dProblemSize const &problem_size) {
  switch (conv_operator) {
    case cutlass::conv::Operator::kFprop: return problem_size.activation_size();
    case cutlass::conv::Operator::kDgrad: return problem_size.output_size();
    case cutlass::conv::Operator::kWgrad: return problem_size.output_size();
    default : break;
  }
  return 0;
}

/// Returns ImplicitGemm tensor B size in number of elements
CUTLASS_HOST_DEVICE
int64_t implicit_gemm_tensor_b_size(
  Operator conv_operator,
  Conv2dProblemSize const &problem_size) {
  switch (conv_operator) {
    case cutlass::conv::Operator::kFprop: return problem_size.filter_size();
    case cutlass::conv::Operator::kDgrad: return problem_size.filter_size();
    case cutlass::conv::Operator::kWgrad: return problem_size.activation_size();
    default : break;
  }
  return 0;
}

/// Returns ImplicitGemm tensor C size in number of elements
CUTLASS_HOST_DEVICE
int64_t implicit_gemm_tensor_c_size(
  Operator conv_operator,
  Conv2dProblemSize const &problem_size) {
  switch (conv_operator) {
    case cutlass::conv::Operator::kFprop: return problem_size.output_size();
    case cutlass::conv::Operator::kDgrad: return problem_size.activation_size();
    case cutlass::conv::Operator::kWgrad: return problem_size.filter_size();
    default : break;
  }
  return 0;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace conv
} // namespace cutlass

////////////////////////////////////////////////////////////////////////////////////////////////////
