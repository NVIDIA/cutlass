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
  \brief Epilogue visitor for threadblock scoped GEMMs that process softmax computations in epilogue.

  The epilogue finds max values in each row of the row-major output matrix and stores them.
  The max values are also used for a further round of threadblock scoped reduction operation, where
  the partial reduction results are stored in a pre-allocated array and used for further full reduction.

*/

#pragma once

/////////////////////////////////////////////////////////////////////////////////////////////////

#include "cutlass/cutlass.h"
#include "cutlass/arch/memory.h"
#include "cutlass/arch/memory_sm75.h"
#include "cutlass/numeric_conversion.h"
#include "cutlass/fast_math.h"

namespace cutlass {
namespace epilogue {
namespace threadblock {

template <
  typename ThreadblockShape_,
  int ThreadCount,
  typename OutputTileIterator_,
  typename ElementAccumulator_,
  typename ElementNorm_,
  typename ElementSum_,
  typename ElementSoftmaxCompute_,
  typename ElementwiseFunctor_
>
class EpilogueVisitorSoftmax {
public:

  using ThreadblockShape   = ThreadblockShape_;
  static int const kThreadCount = ThreadCount;

  using OutputTileIterator = OutputTileIterator_;
  using ElementwiseFunctor = ElementwiseFunctor_;

  static int const kIterations = OutputTileIterator::kIterations;
  static int const kElementsPerAccess = OutputTileIterator::kElementsPerAccess;

  using ElementOutput = typename OutputTileIterator::Element;
  using LayoutOutput = cutlass::layout::RowMajor;
  using ElementAccumulator = ElementAccumulator_;

  using ElementNorm = ElementNorm_;
  using ElementSum = ElementSum_;
  using ElementSoftmaxCompute = ElementSoftmaxCompute_;

  using AccumulatorFragment = Array<ElementAccumulator, kElementsPerAccess>;
  using SoftmaxFragment = Array<ElementSoftmaxCompute, kElementsPerAccess>;
  using OutputVector = Array<ElementOutput, kElementsPerAccess>;
  using TensorRefD = TensorRef<ElementOutput, LayoutOutput>;

  static int const kThreadsPerRow = OutputTileIterator::ThreadMap::Detail::kAccessWidth;
  static bool const hasMultiStepsInRow = (OutputTileIterator::ThreadMap::Iterations::kColumn > 1);

  /// Argument structure
  struct Arguments {

    typename ElementwiseFunctor::Params   elementwise;

    //
    // Methods
    //
    Arguments()
    {

    }

    Arguments(
      typename ElementwiseFunctor::Params   elementwise_
    ):
      elementwise(elementwise_)
    {

    }
  };

  struct Params {

    typename ElementwiseFunctor::Params   elementwise;

    //
    // Methods
    //
    CUTLASS_HOST_DEVICE
    Params()
    {

    }

    CUTLASS_HOST_DEVICE
    Params(Arguments const &args):
      elementwise(args.elementwise)
    {

    }
  };

  /// Shared storage
  struct SharedStorage {

  };

private:

  Params const &                        params_;
  SharedStorage &                       shared_storage_;
  MatrixCoord                           extent_;
  ElementwiseFunctor                    elementwise_;

  OutputTileIterator                    iterator_C_;
  OutputTileIterator                    iterator_D_;
  typename OutputTileIterator::Fragment fragment_C_;
  typename OutputTileIterator::Fragment fragment_D_;

  ElementAccumulator                    alpha_;
  ElementAccumulator                    beta_;

  ElementNorm                           *ptr_Max_;
  ElementSum                            *ptr_Sum_;

  int                                   column_offset_;

  ElementSoftmaxCompute                 accum_max_;
  ElementSoftmaxCompute                 accum_sum_ = ElementSoftmaxCompute(0);

public:

  CUTLASS_DEVICE
  EpilogueVisitorSoftmax(
    Params const &params,
    SharedStorage &shared_storage,
    cutlass::MatrixCoord const &problem_size,
    int thread_idx,
    int warp_idx,
    int lane_idx,
    typename OutputTileIterator::Params params_C,
    typename OutputTileIterator::Params params_D,
    typename OutputTileIterator::Element *ptr_C,
    typename OutputTileIterator::Element *ptr_D,
    ElementNorm *ptr_Max = nullptr,
    ElementSum *ptr_Sum = nullptr,
    cutlass::MatrixCoord const &threadblock_offset = cutlass::MatrixCoord(0, 0),
    int column_offset = 0
  ):
    params_(params),
    shared_storage_(shared_storage),
    extent_(problem_size),
    elementwise_(params.elementwise),
    iterator_C_(params_C, ptr_C, problem_size, thread_idx, threadblock_offset),
    iterator_D_(params_D, ptr_D, problem_size, thread_idx, threadblock_offset),
    ptr_Max_(ptr_Max),
    ptr_Sum_(ptr_Sum),
    column_offset_(column_offset)
  {
    alpha_ = (params.elementwise.alpha_ptr ? *params.elementwise.alpha_ptr : params.elementwise.alpha);
    beta_ =  (params.elementwise.beta_ptr ? *params.elementwise.beta_ptr : params.elementwise.beta);

    if (beta_ == ElementAccumulator()) {
      iterator_C_.clear_mask();
    }
  }

  /// Helper to indicate split-K behavior
  CUTLASS_DEVICE
  void set_k_partition(
    int split_k_index,                                            ///< Index of this threadblock within split-K partitioned scheme
    int split_k_slices) {                                         ///< Total number of split-K slices

  }

  /// Called to set the batch index
  CUTLASS_DEVICE
  void set_batch_index(int batch_idx) {

  }

  /// Called at the start of the epilogue just before iterating over accumulator slices
  CUTLASS_DEVICE
  void begin_epilogue() {

  }

  /// Called at the start of one step before starting accumulator exchange
  CUTLASS_DEVICE
  void begin_step(int step_idx) {
    fragment_D_.clear();
    fragment_C_.clear();

    if (elementwise_.kScale != cutlass::epilogue::thread::ScaleType::OnlyAlphaScaling) {
      iterator_C_.load(fragment_C_);
      ++iterator_C_;
    }
    
  }

  /// Called at the start of a row
  CUTLASS_DEVICE
  void begin_row(int row_idx) {

  }

  /// Called after accumulators have been exchanged for each accumulator vector
  CUTLASS_DEVICE
  void visit(
    int row_idx,
    int column_idx,
    int frag_idx,
    AccumulatorFragment const &accum) {

    using Mul = cutlass::multiplies<SoftmaxFragment>;
    using Minus = cutlass::minus<SoftmaxFragment>;
    using Exp   = cutlass::fast_exp_op<SoftmaxFragment>;

    Minus     minus;
    Exp       exponential;

    SoftmaxFragment result;

    using ConvertSumOutput = cutlass::NumericConverter<ElementSoftmaxCompute, ElementSum>;
    using ConvertNormOutput = cutlass::NumericConverter<ElementSoftmaxCompute, ElementNorm>;

    ConvertSumOutput   convert_sum_output;
    ConvertNormOutput  convert_norm_output;

    NumericArrayConverter<ElementSoftmaxCompute, ElementOutput, kElementsPerAccess> source_converter;
    OutputVector &source_vector = reinterpret_cast<OutputVector *>(&fragment_C_)[frag_idx];

    if (elementwise_.kScale == cutlass::epilogue::thread::ScaleType::OnlyAlphaScaling) {
      result = source_converter(elementwise_(accum));
    }else{
      result = source_converter(elementwise_(accum, source_vector));
    }

    MatrixCoord thread_offset =
      iterator_D_.thread_start() +
      OutputTileIterator::ThreadMap::iteration_offset(frag_idx);

    int half_thread_in_row = (kThreadsPerRow >> 1);

    bool column_guard = (thread_offset.column() < extent_.column());

    // Compute the maximum within one row
    if (!column_idx) {
      // This is the first fragment in a new row
      if (column_guard) {
        accum_max_ = maximum_accumulator_(result);
      }
    }
    else {
      // This is an additional fragment in the same row
      if (column_guard) {
        accum_max_ = maximum_accumulator_(result, accum_max_);
      }
    }

    CUTLASS_PRAGMA_UNROLL
    for (int i = half_thread_in_row; i > 0; i >>= 1) {
      ElementSoftmaxCompute tmp = __shfl_xor_sync(0xFFFFFFFF, accum_max_, i);
      accum_max_ = fast_max(accum_max_, tmp);
    }

    if (hasMultiStepsInRow) {
      accum_sum_ = (column_guard) ? \
        sum_accumulator_(exponential(minus(result, accum_max_)), accum_sum_) : ElementSoftmaxCompute(0);
    }else{
      accum_sum_ = sum_accumulator_(exponential(minus(result, accum_max_)), accum_sum_);
    }


    CUTLASS_PRAGMA_UNROLL
    for (int i = half_thread_in_row; i > 0; i >>= 1) {
      ElementSoftmaxCompute tmp = __shfl_xor_sync(0xFFFFFFFF, accum_sum_, i);
      accum_sum_ += tmp;
    }

    bool row_guard = thread_offset.row() < extent_.row();
    bool is_write_thread = (row_guard && ((threadIdx.x % kThreadsPerRow) == 0));
    ElementNorm *curr_ptr_max = ptr_Max_ + thread_offset.row() + column_offset_;
    ElementSum *curr_ptr_sum = ptr_Sum_ + thread_offset.row() + column_offset_;

    arch::global_store<ElementNorm, sizeof(ElementNorm)>(
              convert_norm_output(accum_max_),
              (void *)curr_ptr_max,
              is_write_thread);

    arch::global_store<ElementSum, sizeof(ElementSum)>(
              convert_sum_output(accum_sum_),
              (void *)curr_ptr_sum,
              is_write_thread);

    // Clear accumulators for max and sum when finishing a whole row
    if (column_idx == OutputTileIterator::ThreadMap::Iterations::kColumn - 1) {
      clear_accum_();
    }

    // Convert to the output
    NumericArrayConverter<ElementOutput, ElementSoftmaxCompute, kElementsPerAccess> output_converter;
    OutputVector &output = reinterpret_cast<OutputVector *>(&fragment_D_)[frag_idx];
    output = output_converter(result);
  }

  /// Called at the start of a row
  CUTLASS_DEVICE
  void end_row(int row_idx) {

  }

  /// Called after all accumulator elements have been visited
  CUTLASS_DEVICE
  void end_step(int step_idx) {

    iterator_D_.store(fragment_D_);
    ++iterator_D_;
  }

  /// Called after all steps have been completed
  CUTLASS_DEVICE
  void end_epilogue() {

  }

private:

  CUTLASS_DEVICE
  void clear_accum_() {

    uint32_t float_max_bits = 0xff7fffff;   // -FLT_MAX
    float min_float = reinterpret_cast<float const &>(float_max_bits);
    accum_max_ = ElementSoftmaxCompute(min_float);
    accum_sum_ = ElementSoftmaxCompute(0);
  }

  CUTLASS_DEVICE
  ElementSoftmaxCompute sum_accumulator_(SoftmaxFragment const &accum) {
    ElementSoftmaxCompute sum_ = ElementSoftmaxCompute(0);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < SoftmaxFragment::kElements; ++i) {
      sum_ += ElementSoftmaxCompute(accum[i]);
    }

    return sum_;
  }

  CUTLASS_DEVICE
  ElementSoftmaxCompute sum_accumulator_(SoftmaxFragment const &accum, ElementSoftmaxCompute sum_) {
    // ElementSoftmaxCompute sum_ = ElementSoftmaxCompute(0);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < SoftmaxFragment::kElements; ++i) {
      sum_ += ElementSoftmaxCompute(accum[i]);
    }

    return sum_;
  }

  CUTLASS_DEVICE
  ElementSoftmaxCompute maximum_accumulator_(SoftmaxFragment const &accum) {
    ElementSoftmaxCompute max_ = accum[0];

    CUTLASS_PRAGMA_UNROLL
    for (int i = 1; i < SoftmaxFragment::kElements; ++i) {
      max_ = fast_max(max_, ElementSoftmaxCompute(accum[i]));
    }

    return max_;
  }

  CUTLASS_DEVICE
  ElementSoftmaxCompute maximum_accumulator_(SoftmaxFragment const &accum, ElementSoftmaxCompute max_) {

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < SoftmaxFragment::kElements; ++i) {
      max_ = fast_max(max_, ElementSoftmaxCompute(accum[i]));
    }

    return max_;
  }
};

} // namespace threadblock
} // namespace epilogue
} // namespace cutlass