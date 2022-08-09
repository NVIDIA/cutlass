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

/**

*/

#pragma once

/////////////////////////////////////////////////////////////////////////////////////////////////

#include <cmath>
#include <iostream>
#include <vector>
#include <limits>

#include "cutlass/cutlass.h"
#include "cutlass/arch/memory.h"
#include "cutlass/arch/memory_sm75.h"

#include "cutlass/gemm/kernel/default_gemm.h"
#include "cutlass/gemm/kernel/default_gemm_complex.h"
#include "cutlass/gemm/device/default_gemm_configuration.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

#include "epilogue_with_visitor.h"
#include "gemm_with_epilogue_visitor.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace kernel {

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Kernel computes partial reduction
//
//
// 2. Sum[m, n'] = sum_n(exp(D[m, n] - N[m, 0]))
//
template <
  typename ElementD_,
  typename ElementNorm_,
  typename ElementSum_,
  typename ElementSoft_,
  typename ElementSoftmaxCompute_,
  int Alignment,
  typename Shape_ = MatrixShape<4, 16>
>
class ApplySoftmax {
public:

  using ElementD = ElementD_;
  using ElementNorm = ElementNorm_;
  using ElementSum = ElementSum_;
  using ElementSoft = ElementSoft_;
  using ElementSoftmaxCompute = ElementSoftmaxCompute_;

  static int const kAlignment = Alignment;
  using Shape = Shape_;

  using Layout = cutlass::layout::RowMajor;

  using TensorRefD = TensorRef<ElementD, Layout>;
  using TensorRefN = TensorRef<ElementNorm, Layout>;
  using TensorRefSum = TensorRef<ElementSum, Layout>;
  using TensorRefSoft = TensorRef<ElementSoft, Layout>;

  using FragmentSoftmax = Array<ElementSoftmaxCompute, kAlignment>;

  //
  // Arguments
  //

  struct Arguments {

    MatrixCoord     extent;             ///< Extent of D and Softmax matrices
    int             batch_count;        ///< Batch count
    TensorRefD      ref_D;              ///< D matrix computed by GEMM+Max (input)
    TensorRefN      ref_N;              ///< Norm tensor (input)
    TensorRefSum    ref_S;              ///< Sum  tensor (input)
    TensorRefSoft   ref_Soft;           ///< Softmax tensor (output)
    int64_t         batch_stride_D;     ///< Batch stride for D tensor
    int64_t         batch_stride_N;     ///< Batch stride for N tensor
    int64_t         batch_stride_S;     ///< Batch stride for S tensor
    int64_t         batch_stride_Soft;  ///< Batch stride for softmax tensor

    //
    // Methods
    //
    Arguments():
      batch_count(1),
      batch_stride_D(0),
      batch_stride_N(0),
      batch_stride_S(0),
      batch_stride_Soft(0)
    { }

    Arguments(
      MatrixCoord     extent_,             ///< Extent of D and Softmax matrices
      int             batch_count_,        ///< Batch count
      TensorRefD      ref_D_,              ///< D matrix computed by GEMM+PartialReduce
      TensorRefN      ref_N_,              ///< Output parameter for N
      TensorRefSum    ref_S_,              ///< Output parameter for N
      TensorRefSoft   ref_Soft_,           ///< Softmax
      int64_t         batch_stride_D_ = 0,
      int64_t         batch_stride_N_ = 0,
      int64_t         batch_stride_S_ = 0,
      int64_t         batch_stride_Soft_ = 0
    ):
      extent(extent_),
      batch_count(batch_count_),
      ref_D(ref_D_),
      ref_N(ref_N_),
      ref_S(ref_S_),
      ref_Soft(ref_Soft_),
      batch_stride_D(batch_stride_D_),
      batch_stride_N(batch_stride_N_),
      batch_stride_S(batch_stride_S_),
      batch_stride_Soft(batch_stride_Soft_)
    {

    }
  };

  //
  // Params struct
  //

  struct Params {
    Arguments args;

    //
    // Methods
    //
    Params() { }

    Params(Arguments const &args_): args(args_) { }
  };

  //
  // SharedStorage
  //

  struct SharedStorage {

  };

private:

public:

  CUTLASS_DEVICE
  ApplySoftmax() { }

  CUTLASS_DEVICE
  void operator()(Params const &params, SharedStorage &shared_storage) {
    apply(params, shared_storage);
  }

private:


  /// Compute Softmax
  CUTLASS_DEVICE
  void apply(Params const &params, SharedStorage &shared_storage) {

    using AccessTypeD = AlignedArray<ElementD, kAlignment>;

    int block_batch = blockIdx.z;
    int block_m = blockIdx.x * Shape::kRow;
    int block_n = 0;

    int thread_m = threadIdx.y;
    int thread_n = threadIdx.x * kAlignment;

    int idx_m = block_m + thread_m;
    int idx_n = block_n + thread_n;

    // Kill off thread if it is outside the row boundary
    if (params.args.extent.row() <= idx_m) {
      return;
    }

    //
    // Setup pointers to load D again
    //

    using AccessTypeD = AlignedArray<ElementD, kAlignment>;
    using AccessTypeSoft = AlignedArray<ElementSoft, kAlignment>;
    using FragmentSoft = Array<ElementSoft, kAlignment>;
    using ConvertSoftCompute = cutlass::NumericArrayConverter<ElementSoftmaxCompute, ElementD, kAlignment>;
    using ConvertSoftOutput = cutlass::NumericArrayConverter<ElementSoft, ElementSoftmaxCompute, kAlignment>;

    using Mul = cutlass::multiplies<FragmentSoftmax>;
    using Minus = cutlass::minus<FragmentSoftmax>;
    using Exp   = cutlass::fast_exp_op<FragmentSoftmax>;

    ConvertSoftCompute   convert_soft_compute;
    ConvertSoftOutput  convert_soft_output;

    Minus     minus;
    Mul       mul;
    Exp       exponential;

    using ConvertSum = cutlass::NumericConverter<ElementSoftmaxCompute, ElementSum>;
    using ConvertNorm = cutlass::NumericConverter<ElementSoftmaxCompute, ElementNorm>;

    ConvertSum   convert_sum;
    ConvertNorm  convert_norm;

    AccessTypeD *access_d = reinterpret_cast<AccessTypeD *>(
      params.args.ref_D.data() +
      params.args.batch_stride_D * block_batch +
      params.args.ref_D.layout()({idx_m, idx_n}));

    AccessTypeSoft *access_soft = reinterpret_cast<AccessTypeSoft *>(
      params.args.ref_Soft.data() +
      params.args.batch_stride_Soft * block_batch +
      params.args.ref_Soft.layout()({idx_m, idx_n}));

    ElementSum inv_sum = (params.args.ref_S.data())[block_m];
    ElementNorm norm = (params.args.ref_N.data())[block_m];

    //
    // Loop
    //
    CUTLASS_PRAGMA_UNROLL
    for (
      int idx = 0;
      idx < params.args.extent.column();
      idx += Shape::kColumn * kAlignment) {

      if (idx_n < params.args.extent.column()) {

        AccessTypeD fetch;
        arch::global_load<AccessTypeD, sizeof(AccessTypeD)>(fetch, access_d, true);

        FragmentSoftmax result = mul(exponential(minus(convert_soft_compute(fetch), convert_norm(norm))),  convert_sum(inv_sum));
        FragmentSoft soft  = convert_soft_output(result);

        arch::global_store<FragmentSoft, sizeof(FragmentSoft)>(soft, access_soft, true);
      }

      access_d += Shape::kColumn;
      access_soft += Shape::kColumn;
      idx_n += Shape::kColumn * kAlignment;
    }
  }
};

template <
  typename ElementNorm_,
  typename ElementSum_,
  typename ElementSoftmaxCompute_,
  typename ThreadblockShape_
>
class ApplyFinalReduction {
public:

  using ElementNorm = ElementNorm_;
  using ElementSum = ElementSum_;
  using ElementSoftmaxCompute = ElementSoftmaxCompute_;
  using ThreadblockShape = ThreadblockShape_;

  using Layout = cutlass::layout::RowMajor;

  using TensorRefN = TensorRef<ElementNorm, Layout>;
  using TensorRefSum = TensorRef<ElementSum, Layout>;  

  //
  // Arguments
  //

  struct Arguments {

    MatrixCoord     extent;             ///< Extent of D and Softmax matrices
    int             batch_count;        ///< Batch count
    TensorRefN      ref_N;              ///< Norm tensor (input / output)
    TensorRefSum    ref_Sum;            ///< Sum tensor (input / output)
    int64_t         batch_stride_N;     ///< Batch stride for N tensor
    int64_t         batch_stride_Sum;   ///< Batch stride for softmax tensor

    //
    // Methods
    //
    Arguments():
      batch_count(1),
      batch_stride_N(0),
      batch_stride_Sum(0)
    { }

    Arguments(
      MatrixCoord     extent_,             ///< Extent of D and Softmax matrices
      int             batch_count_,        ///< Batch count
      TensorRefN      ref_N_,              ///< Output parameter for N
      TensorRefSum    ref_Sum_ ,           ///< Sum
      int64_t         batch_stride_N_ = 0,
      int64_t         batch_stride_Sum_ = 0
    ):
      extent(extent_),
      batch_count(batch_count_),
      ref_N(ref_N_),
      ref_Sum(ref_Sum_),
      batch_stride_N(batch_stride_N_),
      batch_stride_Sum(batch_stride_Sum_)
    {

    }
  };

  struct SharedStorage {


  };

  //
  // Params struct
  //

  struct Params {
    Arguments args;

    //
    // Methods
    //
    Params() { }

    Params(Arguments const &args_): args(args_) { }
  };

private:

public:

  CUTLASS_DEVICE
  ApplyFinalReduction() { }

  CUTLASS_DEVICE
  void operator()(Params const &params, SharedStorage &shared_storage) {

    apply(params, shared_storage);
  }

private:

  /// Partial reduction
  CUTLASS_DEVICE
  void apply(Params const &params, SharedStorage &shared_storage) {

    int threadblock_num = (params.args.extent.column() + ThreadblockShape::kN - 1) / ThreadblockShape::kN;

    int block_batch = blockIdx.z;

    int block_n = blockIdx.x * blockDim.x;

    int thread_n = threadIdx.x;

    int idx_n = block_n + thread_n;

    if (idx_n >= params.args.extent.row()) {
      return;
    }


    using ConvertSumOutput = cutlass::NumericConverter<ElementSum, ElementSoftmaxCompute>;
    using ConvertNormOutput = cutlass::NumericConverter<ElementNorm, ElementSoftmaxCompute>;

    using ConvertSum = cutlass::NumericConverter<ElementSoftmaxCompute, ElementSum>;
    using ConvertNorm = cutlass::NumericConverter<ElementSoftmaxCompute, ElementNorm>;

    ConvertSum   convert_sum;
    ConvertNorm  convert_norm;

    ConvertSumOutput   convert_sum_output;
    ConvertNormOutput  convert_norm_output;

    ElementNorm *access_n = params.args.ref_N.data() + params.args.batch_stride_N * block_batch + idx_n;
    ElementSum *access_s = params.args.ref_Sum.data() + params.args.batch_stride_Sum * block_batch + idx_n;

    ElementNorm *access_n_bak = access_n;
    ElementSum *access_s_bak = access_s;

    uint32_t float_max_bits = 0xff7fffff;
    float min_float = reinterpret_cast<float const &>(float_max_bits);

    ElementSoftmaxCompute max_val = ElementSoftmaxCompute(min_float);
    ElementSoftmaxCompute sum_val = ElementSoftmaxCompute(0);
    ElementNorm fetch_n;
    ElementSum fetch_s;

    CUTLASS_PRAGMA_UNROLL
    for (int idx_m = 0; idx_m < threadblock_num; idx_m++) {
      arch::global_load<ElementNorm, sizeof(ElementNorm)>(fetch_n, access_n, true);
      max_val = fast_max(max_val, convert_norm(fetch_n));
      access_n += params.args.extent.row();
    }
    
    access_n = access_n_bak;

    CUTLASS_PRAGMA_UNROLL
    for (int idx_m = 0; idx_m < threadblock_num; idx_m++) {
      arch::global_load<ElementNorm, sizeof(ElementNorm)>(fetch_n, access_n, true);
      arch::global_load<ElementSum, sizeof(ElementSum)>(fetch_s, access_s, true);
      sum_val += convert_sum(fetch_s) * fast_exp(convert_norm(fetch_n) - max_val);
      access_n += params.args.extent.row();
      access_s += params.args.extent.row();
    }

    ElementSoftmaxCompute inv_sum = cutlass::constants::one<ElementSoftmaxCompute>() / sum_val;

    access_n = access_n_bak;
    access_s = access_s_bak;

    access_n[0] = convert_norm_output(max_val);
    access_s[0] = convert_sum_output(inv_sum);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

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
class EpilogueVisitorBiasMax {
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

  /// Argument structure
  struct Arguments {

    typename ElementwiseFunctor::Params   elementwise;
    TensorRefD                            ref_C;
    TensorRefD                            ref_D;
    ElementNorm                           *ptr_Max;
    ElementSum                            *ptr_Sum;
    int64_t                               batch_stride_C;
    int64_t                               batch_stride_D;
    int64_t                               batch_stride_Max;
    int64_t                               batch_stride_Sum;

    //
    // Methods
    //
    Arguments():
      ptr_Max(nullptr),
      ptr_Sum(nullptr),
      batch_stride_C(0),
      batch_stride_D(0),
      batch_stride_Max(0),
      batch_stride_Sum(0)
    {

    }

    Arguments(
      typename ElementwiseFunctor::Params   elementwise_,
      TensorRefD                            ref_C_,
      TensorRefD                            ref_D_,
      ElementNorm                           *ptr_Max_,
      ElementSum                            *ptr_Sum_,
      int64_t                               batch_stride_C_,
      int64_t                               batch_stride_D_,
      int64_t                               batch_stride_Max_,
      int64_t                               batch_stride_Sum_
    ):
      elementwise(elementwise_),
      ref_C(ref_C_),
      ref_D(ref_D_),
      ptr_Max(ptr_Max_),
      ptr_Sum(ptr_Sum_),
      batch_stride_C(batch_stride_C_),
      batch_stride_D(batch_stride_D_),
      batch_stride_Max(batch_stride_Max_),
      batch_stride_Sum(batch_stride_Sum_)
    {

    }
  };

  struct Params {

    typename ElementwiseFunctor::Params   elementwise;
    typename OutputTileIterator::Params   params_C;
    typename OutputTileIterator::Params   params_D;
    typename OutputTileIterator::Element *ptr_C;
    typename OutputTileIterator::Element *ptr_D;
    ElementNorm                           *ptr_Max;
    ElementSum                            *ptr_Sum;
    int64_t                               batch_stride_C;
    int64_t                               batch_stride_D;
    int64_t                               batch_stride_Max;
    int64_t                               batch_stride_Sum;

    //
    // Methods
    //
    CUTLASS_HOST_DEVICE
    Params():
      ptr_D(nullptr),
      ptr_Max(nullptr),
      ptr_Sum(nullptr)
    {

    }

    CUTLASS_HOST_DEVICE
    Params(Arguments const &args):
      elementwise(args.elementwise),
      params_C(args.ref_C.layout()),
      params_D(args.ref_D.layout()),
      ptr_C(args.ref_C.data()),
      ptr_D(args.ref_D.data()),
      ptr_Max(args.ptr_Max),
      ptr_Sum(args.ptr_Sum),
      batch_stride_C(args.batch_stride_C),
      batch_stride_D(args.batch_stride_D),
      batch_stride_Max(args.batch_stride_Max),
      batch_stride_Sum(args.batch_stride_Sum)
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

  ElementSoftmaxCompute                 accum_max_;
  int                                   threadblock_row_;

public:

  CUTLASS_DEVICE
  EpilogueVisitorBiasMax(
    Params const &params,                                         ///< Parameters routed to the epilogue
    SharedStorage &shared_storage,                                ///< Shared storage needed by the functors here
    MatrixCoord const &problem_size,                              ///< Problem size of the output
    int thread_idx,                                               ///< Thread index within the threadblock
    int warp_idx,                                                 ///< Warp index within the threadblock
    int lane_idx,                                                 ///< Lane index within the warp
    MatrixCoord const &threadblock_offset = MatrixCoord(0, 0)
  ):
    params_(params),
    shared_storage_(shared_storage),
    extent_(problem_size),
    elementwise_(params.elementwise),
    iterator_C_(params.params_C, params.ptr_C, problem_size, thread_idx, threadblock_offset),
    iterator_D_(params.params_D, params.ptr_D, problem_size, thread_idx, threadblock_offset),
    threadblock_row_(threadblock_offset.row())
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
    iterator_C_.add_pointer_offset(batch_idx * params_.batch_stride_C);
    iterator_D_.add_pointer_offset(batch_idx * params_.batch_stride_D);
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

    int thread_in_row = OutputTileIterator::ThreadMap::Detail::RowArrangement::Detail::kShapeWidth;
    int half_thread_in_row = (thread_in_row >> 1);

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

    SoftmaxFragment sum_frag = exponential(minus(result, accum_max_));

    ElementSoftmaxCompute reduction_sum = sum_accumulator_(sum_frag);

    CUTLASS_PRAGMA_UNROLL
    for (int i = half_thread_in_row; i > 0; i >>= 1) {
      ElementSoftmaxCompute tmp = __shfl_xor_sync(0xFFFFFFFF, reduction_sum, i);
      reduction_sum += tmp;
    }

    bool is_write_thread = (thread_offset.row() < extent_.row() && (threadIdx.x % thread_in_row) == 0);
    ElementNorm *curr_ptr_max = params_.ptr_Max + thread_offset.row() + blockIdx.y * extent_.row();
    ElementSum *curr_ptr_sum = params_.ptr_Sum + thread_offset.row() + blockIdx.y * extent_.row();
    
    arch::global_store<ElementNorm, sizeof(ElementNorm)>(
              convert_norm_output(accum_max_),
              (void *)curr_ptr_max,
              is_write_thread);

    arch::global_store<ElementSum, sizeof(ElementSum)>(
              convert_sum_output(reduction_sum),
              (void *)curr_ptr_sum,
              is_write_thread);

     clear_accum_max_();

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
  void clear_accum_max_() {

    uint32_t float_max_bits = 0xff7fffff;   // -FLT_MAX
    float min_float = reinterpret_cast<float const &>(float_max_bits);
    accum_max_ = ElementSoftmaxCompute(min_float);
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

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace kernel

/////////////////////////////////////////////////////////////////////////////////////////////////

///
template <
  typename ElementA_,
  typename LayoutA_,
  typename ElementB_,
  typename LayoutB_,
  typename ElementC_,
  typename ElementCompute_,
  typename EpilogueFunctorOp_,
  typename ElementNorm_ = float,
  typename ElementSum_ = float,
  int Alignment = 128 / cutlass::sizeof_bits<ElementA_>::value,
  typename ElementSoftmax_ = ElementC_
>
class GemmSoftmax {
public:

  ///////////////////////////////////////////////////////////////////////////////////////////////

  //
  // Type definitions
  //

  using ElementA = ElementA_;
  using ElementB = ElementB_;
  using ElementC = ElementC_;
  using ElementCompute = ElementCompute_;
  using ElementSum = ElementSum_;
  using ElementSoft = ElementSoftmax_;
  using ElementSoftmaxCompute = float;

  using LayoutA = LayoutA_;
  using LayoutB = LayoutB_;

  static int const kAlignment = Alignment;

  using EpilogueFunctorOp = EpilogueFunctorOp_;
  using ElementNorm = ElementNorm_;

  // These are mandatory layouts.
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutN = cutlass::layout::RowMajor;
  using LayoutS = cutlass::layout::RowMajor;
  using LayoutSoft = cutlass::layout::RowMajor;

  using TensorRefA = TensorRef<ElementA, LayoutA>;
  using TensorRefB = TensorRef<ElementB, LayoutB>;
  using TensorRefC = TensorRef<ElementC, LayoutC>;
  using TensorRefN = TensorRef<ElementNorm, LayoutN>;
  using TensorRefSum = TensorRef<ElementSum, LayoutS>;
  using TensorRefSoft = TensorRef<ElementSoft, LayoutSoft>;

  using ThreadblockShape = cutlass::gemm::GemmShape<128, 128, 32>;
  using WarpShape        = cutlass::gemm::GemmShape<64, 64, 32>;
  using InstructionShape = cutlass::gemm::GemmShape<16, 8, 16>;

  using OperatorClass       = cutlass::arch::OpClassTensorOp;
  using ArchTag             = cutlass::arch::Sm80;
  static int const kStages  = 3;

  using ThreadblockSwizzle = cutlass::gemm::threadblock::GemmBatchedIdentityThreadblockSwizzle;

  ///////////////////////////////////////////////////////////////////////////////////////////////

  // basic GEMM kernel
  using DefaultGemmKernel = typename cutlass::gemm::kernel::DefaultGemm<
    ElementA,
    LayoutA,
    kAlignment,
    ElementB,
    LayoutB,
    kAlignment,
    ElementC,
    LayoutC,
    ElementCompute,
    OperatorClass,
    ArchTag,
    ThreadblockShape,
    WarpShape,
    InstructionShape,
    EpilogueFunctorOp,
    ThreadblockSwizzle,
    kStages,
    true,
    typename cutlass::gemm::device::DefaultGemmConfiguration<
        OperatorClass, ArchTag, ElementA, ElementB, ElementC, ElementCompute>::Operator,
    cutlass::gemm::SharedMemoryClearOption::kNone
  >::GemmKernel;

  ///////////////////////////////////////////////////////////////////////////////////////////////

  // Epilogue visitor
  using EpilogueVisitor = kernel::EpilogueVisitorBiasMax<
    ThreadblockShape,
    DefaultGemmKernel::kThreadCount,
    typename DefaultGemmKernel::Epilogue::OutputTileIterator,
    ElementCompute,
    ElementNorm,
    ElementSum,
    ElementSoftmaxCompute,
    EpilogueFunctorOp
  >;

  /// Epilogue
  using Epilogue = typename cutlass::epilogue::threadblock::EpilogueWithVisitorFromExistingEpilogue<
    EpilogueVisitor,
    typename DefaultGemmKernel::Epilogue
  >::Epilogue;

  // GEMM
  using GemmKernel = gemm::kernel::GemmWithEpilogueVisitor<
    typename DefaultGemmKernel::Mma,
    Epilogue,
    ThreadblockSwizzle
  >;

  // Softmax kernel
  using SoftmaxApplyKernel = kernel::ApplySoftmax<
    ElementC,
    ElementNorm,
    ElementSum,
    ElementSoft,
    ElementSoftmaxCompute,
    kAlignment,
    MatrixShape<
      1, 1024
    >
  >;

  using ApplyFinalReductionKernel = kernel::ApplyFinalReduction<
    ElementNorm,
    ElementSum,
    ElementSoftmaxCompute,
    ThreadblockShape
  >;

public:

  /// Arguments class
  struct Arguments {

    typename GemmKernel::Arguments         gemm;
    typename SoftmaxApplyKernel::Arguments softmax;
    typename ApplyFinalReductionKernel::Arguments reduction;
    cutlass::gemm::GemmCoord extend;
    //
    // Methods
    //
    Arguments() { }

    Arguments(
      cutlass::gemm::GemmCoord problem_size,
      int32_t    batch_count_,
      TensorRefA ref_A_,
      TensorRefB ref_B_,
      TensorRefC ref_C_,
      TensorRefC ref_D_,
      typename EpilogueFunctorOp::Params linear_scaling,
      TensorRefN ref_N_,
      TensorRefSum ref_S_,
      TensorRefSoft ref_Softmax_,
      int64_t batch_stride_A_ = 0,
      int64_t batch_stride_B_ = 0,
      int64_t batch_stride_C_ = 0,
      int64_t batch_stride_D_ = 0,
      int64_t batch_stride_Max_ = 0,
      int64_t batch_stride_Sum_ = 0,
      int64_t batch_stride_Softmax_ = 0
    ):
      gemm(
        cutlass::gemm::GemmUniversalMode::kBatched,
        problem_size,
        batch_count_,
        ref_A_,
        ref_B_,
        batch_stride_A_,
        batch_stride_B_,
        typename EpilogueVisitor::Arguments(
          linear_scaling,
          ref_C_,
          ref_D_,
          ref_N_.data(),
          ref_S_.data(),
          batch_stride_C_,
          batch_stride_D_,
          batch_stride_Max_,
          batch_stride_Sum_
        )
      ),
      reduction(
        MatrixCoord(problem_size.m(), problem_size.n()),
        batch_count_,
        ref_N_,
        ref_S_,
        batch_stride_Max_,
        batch_stride_Sum_
      ), 
      softmax(
        MatrixCoord(problem_size.m(), problem_size.n()),
        batch_count_,
        ref_D_,
        ref_N_,
        ref_S_,
        ref_Softmax_,
        batch_stride_D_,
        batch_stride_Max_,
        batch_stride_Sum_,
        batch_stride_Softmax_
      ),
      extend(problem_size)
    {

    }
  };

  struct Params {

    typename GemmKernel::Params         gemm;
    typename SoftmaxApplyKernel::Params softmax;
    typename ApplyFinalReductionKernel::Params reduction;
    MatrixCoord extend;
    //
    // Methods
    //
    Params() { }

    Params(Arguments const &args):
      gemm(args.gemm),
      reduction(args.reduction),
      softmax(args.softmax),
      extend(MatrixCoord(args.extend.m(), args.extend.n()))
    {

    }
  };

public:

  // Gemm


  //
  // Methods
  //

private:

  Params params_;

public:

  /// Ctor
  GemmSoftmax() {

  }

  /// Initialize
  Status initialize(Arguments const &args) {

    params_ = Params(args);

    return cutlass::Status::kSuccess;
  }

  /// Run
  Status run(cudaStream_t stream) {

    //
    // Launch the GEMM + max kernel
    //

    dim3 gemm_grid = ThreadblockSwizzle().get_grid_shape(params_.gemm.grid_tiled_shape);
    dim3 gemm_block(GemmKernel::kThreadCount, 1, 1);

    int gemm_smem_size = int(sizeof(typename GemmKernel::SharedStorage));

    cutlass::Kernel<GemmKernel><<<gemm_grid, gemm_block, gemm_smem_size, stream>>>(params_.gemm);

    cudaError_t result = cudaGetLastError();

    if (result != cudaSuccess) {
      return cutlass::Status::kErrorInternal;
    }


    //
    // Launch the ApplyFinalReductionKernel
    //

    int threadblock_num_in_column = (params_.extend.column() + ThreadblockShape::kN - 1) / ThreadblockShape::kN;

    if (threadblock_num_in_column > 1) {
      int thread_per_block = 128;
      int block_per_row = (params_.extend.row() + thread_per_block - 1) / thread_per_block;
      if (block_per_row < 4) {
        thread_per_block = 32;
        block_per_row = (params_.extend.row() + thread_per_block - 1) / thread_per_block;
      }

      dim3 final_reduction_grid(block_per_row);
      dim3 final_reduction_block(thread_per_block);

      Kernel<ApplyFinalReductionKernel><<<
        final_reduction_grid, final_reduction_block, sizeof(typename ApplyFinalReductionKernel::SharedStorage), stream
      >>>(params_.reduction);

      result = cudaGetLastError();

      if (result != cudaSuccess) {
        return cutlass::Status::kErrorInternal;
      }
    }

    //
    // Launch the SoftmaxApplyKernel
    //

    dim3 apply_block(SoftmaxApplyKernel::Shape::kColumn, SoftmaxApplyKernel::Shape::kRow);

    int cta_rows = SoftmaxApplyKernel::Shape::kRow;
    int cta_columns = SoftmaxApplyKernel::Shape::kColumn * SoftmaxApplyKernel::kAlignment;

    dim3 apply_grid(
      (params_.softmax.args.extent.row() + cta_rows - 1) / cta_rows,
      (params_.softmax.args.extent.column() + cta_columns - 1) / cta_columns,
      params_.softmax.args.batch_count);

    Kernel<SoftmaxApplyKernel><<<
      apply_grid, apply_block, sizeof(typename SoftmaxApplyKernel::SharedStorage), stream
    >>>(params_.softmax);

    result = cudaGetLastError();

    if (result != cudaSuccess) {
      return cutlass::Status::kErrorInternal;
    }

    return cutlass::Status::kSuccess;
  }

  /// Function call operator
  Status operator()(cudaStream_t stream = nullptr) {
    return run(stream);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
