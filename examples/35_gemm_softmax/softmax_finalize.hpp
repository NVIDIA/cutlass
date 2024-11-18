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

/*
    //
    // Methods
    //
    Arguments() { }

    Arguments(
      cutlass::gemm::GemmCoord  problem_size,
      ElementNorm*              block_Norm,
      ElementSum*               block_Sum
    ):
      problem_size(problem_size),
      block_Norm(block_Norm),
      block_Sum(block_Sum),
      problem_sizes(nullptr),
      offset_Norm_Device(nullptr),
      offset_Sum_Device(nullptr),
      batch_stride_Max(0),
      batch_stride_Sum(0)
    {

    }*/
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

    /*int tid = ThreadIdxX();
    //int bid = BlockIdxX();
    int bdim = BlockDimX();

    int warps_in_block = bdim / NumThreadsPerWarp;
    
    int wlid = tid % warps_in_block; // local id of thread in warp
    int gid = tid;// + bid * GridDimX();
    int bsize = GridDimX();
    int m_batch_id = BlockIdxY();
    int batch_id = m_batch_id / params.args.IOSize[1];
    int m = m_batch_id % params.args.IOSize[1];*/

    int m = ThreadIdxX() + BlockDimX() * BlockIdxX();
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

    if(m==0 && batch_id==0){
      print("PartialTensorShape: "); print(PartialTensorShape); print("\n");
    }

    ElementPartial max_val = std::numeric_limits<ElementPartial>::min();
    for(int partial_n = 0; partial_n < params.args.partialSize[1]; partial_n += 1){
        ElementPartial partial_max = mPartialMax(m, partial_n, batch_id);
        /*if(m==0 && batch_id==0){
          print("partial_max: "); print(partial_max); print("\n");
        }*/
        max_val = max_val > partial_max ? max_val : partial_max;
    }
    //max_val = reduce_max(max_val);

    //mOut(0,0,0) = max_val; return;
    
    ElementPartial sum_val = 0;
    for(int partial_n = 0; partial_n < params.args.partialSize[1]; partial_n += 1){
        ElementPartial partial_max = mPartialMax(m, partial_n, batch_id);
        ElementPartial partial_sum = mPartialSum(m, partial_n, batch_id);
        sum_val = sum_val + partial_sum * cutlass::fast_exp(partial_max - max_val);
    }
    //sum_val = reduce_sum(sum_val);

    if(m==0 && batch_id==0){
      print("max_val: "); print(max_val); print("\n");
      print("sum_val: "); print(sum_val); print("\n");
    }

    ElementPartial norm = 1 / sum_val;

    for(int n = 0; n < params.args.IOSize[1]; n += 1){
      mOut(m, n, batch_id) = cutlass::fast_exp(mIn(m, n, batch_id) - max_val) * norm;
    }
  }
    /*
    // defining three vars for a general reduction module
    cutlass::gemm::GemmCoord problem_size = isGroupedProblem ? params.args.problem_sizes[bid] : params.args.problem_size;
    int m_dim_in_loop = isGroupedProblem ? problem_size.m() : tid + bdim;
    int access_offset = isGroupedProblem ? 0 : bid * bdim;

    if (!isGroupedProblem && access_offset + tid >= problem_size.m()) return;

    ElementNorm *curr_ptr_Max = isGroupedProblem ? \
              params.args.block_Norm + params.args.offset_Norm_Device[bid] : \
              params.args.block_Norm + block_batch * params.args.batch_stride_Max;
    ElementSum *curr_ptr_Sum = isGroupedProblem ? \
              params.args.block_Sum + params.args.offset_Sum_Device[bid] : \
              params.args.block_Sum + block_batch * params.args.batch_stride_Sum;

    int threadblock_num = (problem_size.n() + ThreadblockShape::kN - 1) / ThreadblockShape::kN;

    ConvertSum   convert_sum;
    ConvertNorm  convert_norm;

    ConvertSumOutput   convert_sum_output;
    ConvertNormOutput  convert_norm_output;

    uint32_t float_max_bits = 0xff7fffff;
    float min_float = reinterpret_cast<float const &>(float_max_bits);

    CUTLASS_PRAGMA_UNROLL
    for (int idx_m = tid; idx_m < m_dim_in_loop; idx_m += bdim) {
      ElementNorm *access_n = curr_ptr_Max + idx_m + access_offset;
      ElementSum *access_s = curr_ptr_Sum + idx_m + access_offset;
      ElementNorm *access_n_bak = access_n;
      ElementSum *access_s_bak = access_s;
      ElementSoftmaxCompute max_val = ElementSoftmaxCompute(min_float);
      ElementSoftmaxCompute sum_val = ElementSoftmaxCompute(0);
      ElementNorm fetch_n;
      ElementSum fetch_s;

      CUTLASS_PRAGMA_UNROLL
      for (int idx_n = 0; idx_n < threadblock_num; idx_n++) {
        cutlass::arch::global_load<ElementNorm, sizeof(ElementNorm)>(fetch_n, access_n, true);
        max_val = cutlass::fast_max(max_val, convert_norm(fetch_n));
        access_n += problem_size.m();
      }

      access_n = access_n_bak;

      CUTLASS_PRAGMA_UNROLL
      for (int idx_n = 0; idx_n < threadblock_num; idx_n++) {
        cutlass::arch::global_load<ElementNorm, sizeof(ElementNorm)>(fetch_n, access_n, true);
        cutlass::arch::global_load<ElementSum, sizeof(ElementSum)>(fetch_s, access_s, true);
        sum_val += convert_sum(fetch_s) * cutlass::fast_exp(convert_norm(fetch_n) - max_val);
        access_n += problem_size.m();
        access_s += problem_size.m();
      }

      ElementSoftmaxCompute inv_sum = cutlass::constants::one<ElementSoftmaxCompute>() / sum_val;

      access_n = access_n_bak;
      access_s = access_s_bak;

      access_n[0] = convert_norm_output(max_val);
      access_s[0] = convert_sum_output(inv_sum);
    }

  }*/
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace kernel
} // namespace reduction
} // namespace cutlass
