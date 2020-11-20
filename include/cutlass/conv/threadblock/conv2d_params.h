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
/*! 
  \file 
  \brief Extracts the host-params objects into non-template code.
*/

#pragma once

#define TRACE_CONV_PARAMS_INITIALIZERS_ENABLED 0

#include "cutlass/cutlass.h"
#include "cutlass/fast_math.h"
#include "cutlass/layout/tensor.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/layout/pitch_linear.h"
#include "cutlass/conv/convolution.h"
#include "cutlass/conv/conv2d_problem_size.h"

#if TRACE_CONV_PARAMS_INITIALIZERS_ENABLED
#include <fstream>
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace conv {
namespace threadblock {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Params structure used for all Conv2d analytic tile iterators
template< typename Layout_ = layout::TensorNHWC >
struct Conv2dAnalyticParams {

  using Layout = Layout_;

  Layout layout;

  //
  // Methods
  //

  CUTLASS_HOST_DEVICE
  Conv2dAnalyticParams() { }

  CUTLASS_HOST_DEVICE
  Conv2dAnalyticParams(
    Conv2dProblemSize const &problem_size,
    Layout const &layout
  ): layout(layout) {

  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

#if TRACE_CONV_PARAMS_INITIALIZERS_ENABLED

CUTLASS_HOST_DEVICE
void TraceIteratorParams(
  char const *conv_operator, 
  char const *operand,
  int element_size_bits,
  MatrixCoord threadblock_shape,
  int thread_count,
  int access_size,
  layout::PitchLinearCoord threadmap_iterations,
  layout::PitchLinearCoord threadmap_delta
) {
 
#if !defined(__CUDA_ARCH__)

  char const *fname = "conv_iterator_params.csv";

  std::ifstream test(fname);
  bool file_exists = test.is_open();

  if (file_exists) {
    test.close();
  }
 
  std::ofstream trace("conv_iterator_params.csv", std::ofstream::app);

  if (!file_exists) {
    trace 
      << "Operator,Operand,ElementSize,CtaRows,CtaColumns,ThreadCount,AccessSize,"
      << "IterationsContiguous,IterationsStrided,DeltaContiguous,DeltaStrided\n";
  }

  trace << conv_operator << "," << operand << "," << element_size_bits << "," 
    << threadblock_shape.row() << "," << threadblock_shape.column()
    << "," << thread_count << "," << access_size 
    << "," << threadmap_iterations.contiguous() << "," << threadmap_iterations.strided()
    << "," << threadmap_delta.contiguous() << "," << threadmap_delta.strided() << "\n";
#endif
}

#define TRACE_CONV_INITIALIZERS(conv_op, operand, element_size, cta_shape, thread_count, access_size, iterations, delta) \
  TraceIteratorParams(conv_op, operand, element_size, cta_shape, thread_count, access_size, iterations, delta);

#else

#define TRACE_CONV_INITIALIZERS(conv_op, operand, element_size, cta_shape, thread_count, access_size, iterations, delta) {}

#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Parameters structure used for Conv2dFpropActivationTileIteratorOptimized
template< typename Layout_ = layout::TensorNHWC >
struct Conv2dFpropActivationIteratorOptimizedParams;

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Parameters structure used for Conv2dFpropActivationTileIteratorOptimized
template<>
struct Conv2dFpropActivationIteratorOptimizedParams<layout::TensorNHWC> {
  
  using Layout = layout::TensorNHWC;

  Layout layout;

  int64_t inc_next[3];    // {next S, next R, next C}
  int filter_c_delta;     // number of logical elements to add to filter_c_
  int PQ;                 // product of P*Q

  FastDivmod pq_divmod;
  FastDivmod q_divmod;

  //
  // Methods
  //

  CUTLASS_HOST_DEVICE
  Conv2dFpropActivationIteratorOptimizedParams() { }

  CUTLASS_HOST_DEVICE
  Conv2dFpropActivationIteratorOptimizedParams(
    Conv2dProblemSize const &problem_size,
    Layout const &layout,                             ///< layout object
    int element_size_bits,                            ///< size of each element in bits
    MatrixCoord threadblock_shape,
    int thread_count,
    int access_size,
    layout::PitchLinearCoord threadmap_iterations,
    layout::PitchLinearCoord threadmap_delta
  ): 
    layout(layout), PQ(problem_size.P * problem_size.Q), pq_divmod(PQ), q_divmod(problem_size.Q) {

    TRACE_CONV_INITIALIZERS("conv2d_fprop", "activation", 
      element_size_bits, threadblock_shape, thread_count, access_size, threadmap_iterations, threadmap_delta);

    int conv_sign = (problem_size.mode == Mode::kConvolution ? -1 : 1);

    // next S
    inc_next[0] = conv_sign * (int64_t(layout.stride()[0]) * problem_size.dilation_w) * element_size_bits / 8;

    // next R
    inc_next[1] = conv_sign * (
        int64_t(layout.stride()[1]) * problem_size.dilation_h
        - (problem_size.S - 1) * layout.stride()[0] * problem_size.dilation_w
      ) * element_size_bits / 8;

    // next C
    inc_next[2] = (
        threadblock_shape.column() * problem_size.split_k_slices
        - conv_sign * int64_t(problem_size.R - 1) * layout.stride()[1] * problem_size.dilation_h
        - conv_sign * int64_t(problem_size.S - 1) * layout.stride()[0] * problem_size.dilation_w
      ) * element_size_bits / 8;

    // logical offset added to internal channel counter - units are elements, not bytes
    filter_c_delta = threadblock_shape.column() * problem_size.split_k_slices;
  }
};

/// Parameters structure used for Conv2dFpropActivationTileIteratorOptimized
template <int Interleaved_>
struct Conv2dFpropActivationIteratorOptimizedParams<layout::TensorNCxHWx<Interleaved_>> {
  static int const kInterleaved = Interleaved_;
 
  using Layout = layout::TensorNCxHWx<kInterleaved>;

  Layout layout;

  int64_t inc_next[3];    // {next S, next R, next C}
  int filter_c_delta;     // number of logical elements to add to filter_c_
  int PQ;                 // product of P*Q

  FastDivmod pq_divmod;
  FastDivmod q_divmod;

  //
  // Methods
  //

  CUTLASS_HOST_DEVICE
  Conv2dFpropActivationIteratorOptimizedParams() { }

  CUTLASS_HOST_DEVICE
  Conv2dFpropActivationIteratorOptimizedParams(
    Conv2dProblemSize const &problem_size,
    Layout const &layout,                             ///< layout object
    int element_size_bits,                            ///< size of each element in bits
    MatrixCoord threadblock_shape,
    int thread_count,
    int access_size,
    layout::PitchLinearCoord threadmap_iterations,
    layout::PitchLinearCoord threadmap_delta
  ): 
    layout(layout), PQ(problem_size.P * problem_size.Q), pq_divmod(PQ), q_divmod(problem_size.Q) {

    TRACE_CONV_INITIALIZERS("conv2d_fprop", "activation", 
      element_size_bits, threadblock_shape, thread_count, access_size, threadmap_iterations, threadmap_delta);

    int conv_sign = (problem_size.mode == Mode::kConvolution ? -1 : 1);

    // next S
    inc_next[0] = conv_sign * (kInterleaved * problem_size.dilation_w) * element_size_bits / 8;

    // next R
    inc_next[1] = conv_sign * (
        int64_t(layout.stride()[0]) * problem_size.dilation_h
        - (problem_size.S - 1) * kInterleaved * problem_size.dilation_w
      ) * element_size_bits / 8;

    // next C
    inc_next[2] = (
        threadblock_shape.column() * problem_size.split_k_slices / kInterleaved * int64_t(layout.stride()[1])
        - conv_sign * int64_t(problem_size.R - 1) * layout.stride()[0] * problem_size.dilation_h
        - conv_sign * int64_t(problem_size.S - 1) * kInterleaved * problem_size.dilation_w
      ) * element_size_bits / 8;

    // logical offset added to internal channel counter - units are elements, not bytes
    filter_c_delta = threadblock_shape.column() * problem_size.split_k_slices;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

template< typename Layout_ = layout::TensorNHWC >
struct Conv2dFpropFilterIteratorOptimizedParams;

/////////////////////////////////////////////////////////////////////////////////////////////////

template<>
struct Conv2dFpropFilterIteratorOptimizedParams<layout::TensorNHWC>
{

  using Layout = layout::TensorNHWC;

  Layout layout;
  int RS;
  int filter_c_delta;

  int64_t inc_next_k;         // offset in units of bytes to next K position
  int64_t inc_next_rs;        // offset in units of bytes to next RS position
  int64_t inc_next_c;         // offset in units of bytes to next C position

  //
  // Methods
  //
  CUTLASS_HOST_DEVICE
  Conv2dFpropFilterIteratorOptimizedParams() { }

  CUTLASS_HOST_DEVICE
  Conv2dFpropFilterIteratorOptimizedParams(
    Conv2dProblemSize const &problem_size,
    Layout const &layout,
    int element_size_bits,                        ///< size of each element in bits
    MatrixCoord threadblock_shape,
    int thread_count,
    int access_size,
    layout::PitchLinearCoord threadmap_iterations,
    layout::PitchLinearCoord threadmap_delta
  ): 
    layout(layout) {
    
    TRACE_CONV_INITIALIZERS("conv2d_fprop", "filter", 
      element_size_bits, threadblock_shape, thread_count, access_size, threadmap_iterations, threadmap_delta);

    RS = problem_size.R * problem_size.S;

    inc_next_k = (int64_t(layout.stride()[2]) * threadmap_delta.strided() * element_size_bits) / 8;

    inc_next_rs =
      ( int64_t(layout.stride()[0])
        - int64_t(layout.stride()[2]) * (threadmap_iterations.strided() - 1) * threadmap_delta.strided()
      ) * element_size_bits / 8;

    inc_next_c =
      (
        threadblock_shape.row() * problem_size.split_k_slices
        - int64_t(RS - 1) * layout.stride()[0]
        - int64_t(threadmap_iterations.strided() - 1) * threadmap_delta.strided() * layout.stride()[2]
      ) * element_size_bits / 8;

    filter_c_delta = threadblock_shape.row() * problem_size.split_k_slices;
  }
};

template<int Interleaved_>
struct Conv2dFpropFilterIteratorOptimizedParams<layout::TensorCxRSKx<Interleaved_>>
{
  static int const kInterleaved = Interleaved_;
  using Layout = layout::TensorCxRSKx<kInterleaved>;

  Layout layout;
  int RS;
  int filter_c_delta;

  int64_t inc_next_k;         // offset in units of bytes to next K position
  int64_t inc_next_rs;        // offset in units of bytes to next RS position
  int64_t inc_next_c;         // offset in units of bytes to next C position

  //
  // Methods
  //
  CUTLASS_HOST_DEVICE
  Conv2dFpropFilterIteratorOptimizedParams() { }

  CUTLASS_HOST_DEVICE
  Conv2dFpropFilterIteratorOptimizedParams(
    Conv2dProblemSize const &problem_size,
    Layout const &layout,
    int element_size_bits,                        ///< size of each element in bits
    MatrixCoord threadblock_shape,
    int thread_count,
    int access_size,
    layout::PitchLinearCoord threadmap_iterations,
    layout::PitchLinearCoord threadmap_delta
  ): 
    layout(layout) {
    
    TRACE_CONV_INITIALIZERS("conv2d_fprop", "filter", 
      element_size_bits, threadblock_shape, thread_count, access_size, threadmap_iterations, threadmap_delta);

    RS = problem_size.R * problem_size.S;

    inc_next_k = (kInterleaved * threadmap_delta.strided() * element_size_bits) / 8;

    inc_next_rs =
      (  int64_t(layout.stride()[0])
        - kInterleaved * (threadmap_iterations.strided() - 1) * threadmap_delta.strided()
      ) * element_size_bits / 8;

    inc_next_c =
      (
        threadblock_shape.row() * problem_size.split_k_slices / kInterleaved * int64_t(layout.stride()[2])
        - int64_t(RS - 1) * layout.stride()[0]
        - int64_t(threadmap_iterations.strided() - 1) * threadmap_delta.strided() * kInterleaved 
      ) * element_size_bits / 8;

    filter_c_delta = threadblock_shape.row() * problem_size.split_k_slices;
  }
};

/// Parameters object for Conv2d DGRAD OutputGradient (dy) iterator
struct Conv2dDgradOutputGradientIteratorOptimizedParams {

  using Layout = layout::TensorNHWC;

  Layout layout;

  int64_t inc_next[3];    // {next S, next R, next K}

  int filter_k_delta;     // number of logical elements to add to filter_k_

  int HW;                   // product of H*W

  FastDivmod hw_divmod;
  FastDivmod w_divmod;

  //
  // Methods
  //

  CUTLASS_HOST_DEVICE
  Conv2dDgradOutputGradientIteratorOptimizedParams() { }

  CUTLASS_HOST_DEVICE
  Conv2dDgradOutputGradientIteratorOptimizedParams(
    Conv2dProblemSize const &problem_size,
    Layout const &layout,
    int element_size_bits,                        ///< size of each element in bits
    MatrixCoord threadblock_shape,
    int thread_count,
    int access_size,
    layout::PitchLinearCoord threadmap_iterations,
    layout::PitchLinearCoord threadmap_delta
  ): 
    layout(layout), HW(problem_size.H *problem_size.W), hw_divmod(HW), w_divmod(problem_size.W) {
    
    TRACE_CONV_INITIALIZERS("conv2d_dgrad", "output_gradient", 
      element_size_bits, threadblock_shape, thread_count, access_size, threadmap_iterations, threadmap_delta);

    int conv_sign = (problem_size.mode == Mode::kConvolution ? 1 : -1);

    // next S
    inc_next[0] = conv_sign * (layout.stride()[0] * problem_size.dilation_w) * element_size_bits / 8;

    // next R
    inc_next[1] = conv_sign * (
        layout.stride()[1] * problem_size.dilation_h
        - (problem_size.S - 1) * layout.stride()[0] * problem_size.dilation_w
      ) * element_size_bits / 8;

    // next K
    inc_next[2] = (
        threadblock_shape.column() * problem_size.split_k_slices
        - conv_sign * (problem_size.R - 1) * layout.stride()[1] * problem_size.dilation_h
        - conv_sign * (problem_size.S - 1) * layout.stride()[0] * problem_size.dilation_w
      ) * element_size_bits / 8;

    // logical offset added to internal channel counter - units are elements, not bytes
    filter_k_delta = threadblock_shape.column() * problem_size.split_k_slices;
  }
};

/// Parameters object for Conv2d DGRAD Filter (w) iterator
struct Conv2dDgradFilterIteratorOptimizedParams {

  using Layout = layout::TensorNHWC;

  Layout layout;
  int RS;
  int filter_k_delta;

  int64_t inc_next_strided;   // offset in units of bytes to next K coordinate within tile
  int64_t inc_next_rs;        // offset in units of bytes to next RS position
  int64_t inc_next_k;         // offset in units of bytes to next K position in subsequent tile

  //
  // Methods
  //
  CUTLASS_HOST_DEVICE
  Conv2dDgradFilterIteratorOptimizedParams() { }

  CUTLASS_HOST_DEVICE
  Conv2dDgradFilterIteratorOptimizedParams(
    Conv2dProblemSize const &problem_size,
    Layout const &layout,    
    int element_size_bits,                        ///< size of each element in bits
    MatrixCoord threadblock_shape,
    int thread_count,
    int access_size, 
    layout::PitchLinearCoord threadmap_iterations,
    layout::PitchLinearCoord threadmap_delta
  ): 
    layout(layout), RS(problem_size.R * problem_size.S) {

    TRACE_CONV_INITIALIZERS("conv2d_dgrad", "filter", 
      element_size_bits, threadblock_shape, thread_count, access_size, threadmap_iterations, threadmap_delta);

    inc_next_strided = (layout.stride()[2] * threadmap_delta.strided() * element_size_bits) / 8;

    inc_next_rs =
      ( layout.stride()[0]
        - (threadmap_iterations.strided() - 1) * threadmap_delta.strided() * layout.stride()[2]
      ) * element_size_bits / 8;

    inc_next_k =
      (
        threadblock_shape.row() * problem_size.split_k_slices * layout.stride()[2]
        - (problem_size.R * problem_size.S - 1) * layout.stride()[0]
        - (threadmap_iterations.strided() - 1) * threadmap_delta.strided() * layout.stride()[2]
      ) * element_size_bits / 8;

    filter_k_delta = threadblock_shape.row() * problem_size.split_k_slices;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Parameters object for Conv2d WGRAD Output Gradient (dy) iterator
struct Conv2dWgradOutputGradientIteratorOptimizedParams {

  using Layout = layout::TensorNHWC;

  Layout layout;

  int NPQ;                      // precomputd product of N*P*Q for clearing predicates

  FastDivmod pq_divmod;
  FastDivmod q_divmod;

  int64_t offset_next_strided;    // offset in units of bytes to next npq coordinate within tile
  int64_t offset_next_contiguous; // offset in units of bytes to next k coordinate within tile
  int64_t inc_next_npq;           // offset in units of bytes to next npq position in subsequent tile

  //
  // Methods
  //

  CUTLASS_HOST_DEVICE
  Conv2dWgradOutputGradientIteratorOptimizedParams() { }

  CUTLASS_HOST_DEVICE
  Conv2dWgradOutputGradientIteratorOptimizedParams(
    Conv2dProblemSize const &problem_size,
    Layout const &layout,    
    int element_size_bits,                        ///< size of each element in bits
    MatrixCoord threadblock_shape,
    int thread_count,
    int access_size,
    layout::PitchLinearCoord threadmap_iterations,
    layout::PitchLinearCoord threadmap_delta
  ):
    layout(layout),
    NPQ(problem_size.N * problem_size.P * problem_size.Q),
    pq_divmod(problem_size.P * problem_size.Q),
    q_divmod(problem_size.Q) {
    
    TRACE_CONV_INITIALIZERS("conv2d_wgrad", "output_gradient", 
      element_size_bits, threadblock_shape, thread_count, access_size, threadmap_iterations, threadmap_delta);

    // Incremental offsets in unites of bytes (number of elements) * sizeof_bits<Element>::value / 8
    offset_next_strided = (threadmap_delta.strided() * layout.stride()[0])
                        * element_size_bits / 8;

    offset_next_contiguous = (threadmap_delta.contiguous())
                            * element_size_bits / 8;

    inc_next_npq = (threadblock_shape.column() * problem_size.split_k_slices * layout.stride()[0])
                      * element_size_bits / 8;
  }
};

struct Conv2dWgradActivationIteratorOptimizedParams {

  using Layout = layout::TensorNHWC;

  Layout layout;

  FastDivmod sc_divmod;
  FastDivmod pq_divmod;
  FastDivmod q_divmod;
  FastDivmod c_divmod;

  //
  // Methods
  //
  CUTLASS_HOST_DEVICE
  Conv2dWgradActivationIteratorOptimizedParams() { }

  CUTLASS_HOST_DEVICE
  Conv2dWgradActivationIteratorOptimizedParams(
    Conv2dProblemSize const &problem_size,
    Layout const &layout
  ):
    layout(layout),
    sc_divmod(problem_size.S * problem_size.C),
    pq_divmod(problem_size.P * problem_size.Q),
    q_divmod(problem_size.Q),
    c_divmod(problem_size.C) {

  }

  CUTLASS_HOST_DEVICE
  Conv2dWgradActivationIteratorOptimizedParams(
    Conv2dProblemSize const &problem_size,
    Layout const &layout,
    int element_size_bits,                        ///< size of each element in bits
    MatrixCoord threadblock_shape,
    int thread_count,
    int access_size,
    layout::PitchLinearCoord threadmap_iterations,
    layout::PitchLinearCoord threadmap_delta
  ):
    Conv2dWgradActivationIteratorOptimizedParams(
      problem_size,
      layout
    ) { 
    
      TRACE_CONV_INITIALIZERS("conv2d_wgrad", "activation", 
        element_size_bits, threadblock_shape, thread_count, access_size, threadmap_iterations, threadmap_delta);
    }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace threadblock
} // namespace conv
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////

