/***************************************************************************************************
 * Copyright (c) 2017 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
  \brief Kernel performing a final calculation of softmax
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"
#include "cutlass/array.h"
#include "cutlass/functional.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/numeric_conversion.h"
#include "cutlass/arch/memory.h"
#include "cutlass/arch/memory_sm75.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace reduction {
namespace kernel {

template <
  typename ElementInput_,
  typename StrideInput_,
  typename ElementPartial_,
  typename StridePartial_,
  typename ElementOutput_,
  typename StrideOutput_
>
class SoftmaxFinalize {
public:

  using ElementInput = ElementInput_;
  using StrideInput = StrideInput_;
  using ElementPartial = ElementPartial_;
  using StridePartial = StridePartial_;
  using ElementOutput = ElementOutput_;
  using StrideOutput = StrideOutput_;

  //
  // Arguments
  //

  struct Arguments {
    //TODO(Tadej): duplicated part of sizes
    cutlass::MatrixCoord      IOSize;    ///< Extent of input and output matrices
    cutlass::MatrixCoord partialSize;    ///< Extent of partial max and sum matrices
    int                  batch_count;    ///< Batch count
    StrideInput               dInput;
    StridePartial           dPartial;
    StrideOutput             dOutput;
    ElementInput*             ptr_in;
    ElementPartial*  ptr_partial_max;
    ElementPartial*  ptr_partial_sum;
    ElementOutput*           ptr_out;
  };

  struct SharedStorage {
    cute::array_aligned<ElementPartial, 32 * 32 * 2> s_mem;
  };

  static constexpr int SharedStorageSize = sizeof(SharedStorage);

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
  SoftmaxFinalize() { }

  CUTLASS_DEVICE
  void operator()(Params const &params, char* shared_storage) {

    apply(params, shared_storage);
  }

private:

  template <class Op>
  CUTLASS_DEVICE static ElementPartial reduceSg(ElementPartial val, Op op) {
    auto sg = syclcompat::get_nd_item<1>().get_sub_group();
    CUTLASS_PRAGMA_UNROLL
    for(uint laneMask = 8; laneMask >= 1; laneMask /= 2) {
      val = op(val, syclcompat::permute_sub_group_by_xor(sg, val, laneMask, 16));
    }
    return val;
  }

  CUTLASS_DEVICE static ElementPartial reduce_max(ElementPartial val) {
      return reduceSg(val, [](ElementPartial const & x, ElementPartial const & y) { return x > y ? x : y; });
  }

  CUTLASS_DEVICE static ElementPartial reduce_sum(ElementPartial val) {
      return reduceSg(val, [](ElementPartial const & x, ElementPartial const & y) { return x + y; });
  }

  /// Full reduction
  CUTLASS_DEVICE
  void apply(Params const &params, char* shared_storage) {
    using ConvertInput = cutlass::NumericConverter<ElementInput, ElementPartial>;
    using ConvertNormOutput = cutlass::NumericConverter<ElementPartial, ElementOutput>;

    int x = ThreadIdxX();
    int m = x + BlockDimX() * BlockIdxX();
    int y = ThreadIdxY();
    int y_size = BlockDimY();
    int batch_id = BlockIdxY();

    if(m>=params.args.IOSize[0]){
      return;
    }

    
    // Represent the full tensors
    auto IOTensorShape = make_shape(params.args.IOSize[0], params.args.IOSize[1], params.args.batch_count);
    auto PartialTensorShape = make_shape(params.args.partialSize[0], params.args.partialSize[1], params.args.batch_count);
    Tensor mPartialMax = make_tensor(make_gmem_ptr(params.args.ptr_partial_max), PartialTensorShape, params.args.dPartial);                 // (m,n,l)
    Tensor mPartialSum = make_tensor(make_gmem_ptr(params.args.ptr_partial_sum), PartialTensorShape, params.args.dPartial);                 // (m,n,l)
    Tensor mOut = make_tensor(make_gmem_ptr(params.args.ptr_out), IOTensorShape, params.args.dOutput);                 // (m,n,l)
    Tensor mIn = make_tensor(make_gmem_ptr(params.args.ptr_in), IOTensorShape, params.args.dInput);                   // (m,n,l)

    //Represent the shared tensor
    Tensor sPartial = make_tensor(make_smem_ptr(reinterpret_cast<ElementPartial*>(shared_storage)), make_layout(make_shape(32, 32, 2)));

    ElementPartial max_val = std::numeric_limits<ElementPartial>::min();
    for(int partial_n = y; partial_n < params.args.partialSize[1]; partial_n += y_size){
        ElementPartial partial_max = mPartialMax(m, partial_n, batch_id);
        max_val = max_val > partial_max ? max_val : partial_max;
    }
    sPartial(x,y,0) = max_val;
    syncthreads();
    //TODO(Tadej): improve reduction
    for(int y2 = 0; y2 < y_size; y2++){
        ElementPartial partial_max = sPartial(x,y2,0);
        max_val = max_val > partial_max ? max_val : partial_max;
    }
    
    ElementPartial sum_val = 0;
    for(int partial_n = y; partial_n < params.args.partialSize[1]; partial_n += y_size){
        ElementPartial partial_max = mPartialMax(m, partial_n, batch_id);
        ElementPartial partial_sum = mPartialSum(m, partial_n, batch_id);
        sum_val = sum_val + partial_sum * cutlass::fast_exp(partial_max - max_val);
    }
    syncthreads();
    sPartial(x,y,1) = sum_val;
    syncthreads();
    sum_val = 0;
    //TODO(Tadej): improve reduction
    for(int y2 = 0; y2 < y_size; y2++){
        ElementPartial partial_max = sPartial(x,y2,0);
        ElementPartial partial_sum = sPartial(x,y2,1);
        sum_val = sum_val + partial_sum;
    }

    ElementPartial norm = 1 / sum_val;

    for(int n = y * 2; n < params.args.IOSize[1]; n += y_size * 2){
      auto inVal = mIn(m, n, batch_id);
      auto inVal2 = mIn(m, n+1, batch_id);
      mOut(m, n, batch_id) = cutlass::fast_exp(inVal - max_val) * norm;
      mOut(m, n+1, batch_id) = cutlass::fast_exp(inVal2 - max_val) * norm;
    }
    if(params.args.IOSize[1]%2==1){
      int n = params.args.IOSize[1] - 1;
      auto inVal = mIn(m, n, batch_id);
      mOut(m, n, batch_id) = cutlass::fast_exp(inVal - max_val) * norm;
    }
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace kernel
} // namespace reduction
} // namespace cutlass
