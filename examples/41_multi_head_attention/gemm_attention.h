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
 * 3. Neither the name of the copyright holdvr nor the names of its
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
    \brief Defines the FusedMultiHeadAttention Class

    The class contains the following:
    1) GEMM0 with epilogue fusion,
    2) GEMM1 with mainloop fusion, and 
    3) A lightweight full softmax reduction kernel.

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
#include "cutlass/epilogue/threadblock/epilogue_visitor_with_softmax.h"
#include "cutlass/epilogue/thread/scale_type.h"
#include "cutlass/gemm/kernel/default_gemm_grouped_softmax_mainloop_fusion.h"
#include "cutlass/reduction/kernel/reduce_softmax_final.h"
#include "gemm_grouped_with_softmax_visitor.h"

namespace cutlass {

template <
  typename ElementQ_,
  typename LayoutQ_,
  typename ElementK_,
  typename LayoutK_,
  typename ElementP_,
  typename LayoutP_,
  typename ElementCompute_,
  typename OperatorClass_,
  typename ArchTag_,
  typename ThreadblockShape0_,
  typename ThreadblockShape1_,
  typename WarpShape0_,
  typename WarpShape1_,
  typename InstructionShape_,
  int kStages0_,
  int kStages1_,
  bool UseMasking_ = false,
  cutlass::gemm::kernel::GroupScheduleMode GroupScheduleMode0_ = cutlass::gemm::kernel::GroupScheduleMode::kHostPrecompute,
  cutlass::gemm::kernel::GroupScheduleMode GroupScheduleMode1_ = cutlass::gemm::kernel::GroupScheduleMode::kHostPrecompute,
  int Alignment = 128 / cutlass::sizeof_bits<ElementQ_>::value,
  typename ElementSoftmax_ = ElementP_
>
class FusedMultiHeadAttention {
public:

  using ElementQ = ElementQ_;
  using ElementK = ElementK_;
  using ElementP = ElementP_;
  using ElementV = ElementK;
  using ElementOutput = ElementP;
  using ElementAccumulator = ElementCompute_;

  using LayoutQ = LayoutQ_;
  using LayoutK = LayoutK_;
  using LayoutP = LayoutP_;
  using LayoutV = LayoutK;
  using LayoutO = LayoutP;

  using ElementNorm = cutlass::half_t;
  using ElementSum = cutlass::half_t;
  using ElementSoftmaxCompute = float;
  using LayoutNorm = cutlass::layout::RowMajor;

  using ThreadblockSwizzle = cutlass::gemm::threadblock::GemmBatchedIdentityThreadblockSwizzle;

  using OperatorClass = OperatorClass_;
  using ArchTag = ArchTag_;

  using ThreadblockShape0 = ThreadblockShape0_;
  using WarpShape0 = WarpShape0_;

  using ThreadblockShape1 = ThreadblockShape1_;
  using WarpShape1 = WarpShape1_;
  
  static int const Stages0 = kStages0_;
  static int const Stages1 = kStages1_;

  using InstructionShape = InstructionShape_;

  using EpilogueOutputOp0 = cutlass::epilogue::thread::LinearCombination<
        ElementOutput, 128 / cutlass::sizeof_bits<ElementOutput>::value,
        ElementAccumulator, ElementAccumulator, cutlass::epilogue::thread::ScaleType::OnlyAlphaScaling>;

  using EpilogueOutputOp1 = cutlass::epilogue::thread::LinearCombination<
        ElementOutput, 128 / cutlass::sizeof_bits<ElementOutput>::value,
        ElementAccumulator, ElementAccumulator, cutlass::epilogue::thread::ScaleType::Nothing>;

  using Operator = typename cutlass::gemm::device::DefaultGemmConfiguration<
        OperatorClass, ArchTag, ElementQ, ElementK, ElementP,
        ElementAccumulator>::Operator;
  static bool const kInternalTranspose = cutlass::platform::is_same<LayoutP, cutlass::layout::ColumnMajor>::value;

  static bool const kUseMasking = UseMasking_;

  static cutlass::gemm::kernel::GroupScheduleMode const kGroupScheduleMode0 = GroupScheduleMode0_;
  static cutlass::gemm::kernel::GroupScheduleMode const kGroupScheduleMode1 = GroupScheduleMode1_;

  using MapArguments = cutlass::gemm::kernel::detail::MapArguments<
    ElementQ,
    LayoutQ,
    cutlass::ComplexTransform::kNone,
    8,
    ElementK,
    LayoutK,
    cutlass::ComplexTransform::kNone,
    8,
    LayoutP,
    kInternalTranspose
  >;

  using DefaultGemmKernel = typename cutlass::gemm::kernel::DefaultGemm<
    typename MapArguments::ElementA,
    typename MapArguments::LayoutA,
    MapArguments::kAlignmentA,
    typename MapArguments::ElementB,
    typename MapArguments::LayoutB,
    MapArguments::kAlignmentB,
    ElementP,
    typename MapArguments::LayoutC,
    ElementAccumulator,
    OperatorClass,
    ArchTag,
    ThreadblockShape0,
    WarpShape0,
    InstructionShape,
    EpilogueOutputOp0,
    ThreadblockSwizzle,
    Stages0,
    true,
    Operator,
    cutlass::gemm::SharedMemoryClearOption::kNone
  >::GemmKernel;

  using EpilogueVisitor = typename cutlass::epilogue::threadblock::EpilogueVisitorSoftmax<
    ThreadblockShape0,
    DefaultGemmKernel::kThreadCount,
    typename DefaultGemmKernel::Epilogue::OutputTileIterator,
    typename EpilogueOutputOp0::ElementCompute,
    ElementNorm,
    ElementSum,
    ElementSoftmaxCompute,
    EpilogueOutputOp0,
    kUseMasking
  >;

  using Epilogue = typename cutlass::epilogue::threadblock::EpilogueWithVisitorFromExistingEpilogue<
    EpilogueVisitor,
    typename DefaultGemmKernel::Epilogue
  >::Epilogue;

  using GemmKernel0 = cutlass::gemm::kernel::GemmGroupedWithEpilogueVistor<
    typename DefaultGemmKernel::Mma,
    Epilogue,
    ThreadblockSwizzle,
    kGroupScheduleMode0,
    kInternalTranspose,
    kUseMasking
  >;

  using GemmGrouped0 = cutlass::gemm::device::GemmGrouped<GemmKernel0>;

  using ApplyFinalReductionDevice = cutlass::reduction::kernel::ApplySoftmaxFinalReduction<
    ElementNorm,
    ElementSum,
    typename GemmGrouped0::GemmKernel::EpilogueVisitor::ElementSoftmaxCompute,
    typename GemmGrouped0::GemmKernel::EpilogueVisitor::ThreadblockShape,
    true
  >;

  using GemmKernel1 = typename cutlass::gemm::kernel::DefaultGemmGroupedSoftmaxMainloopFusion<
    ElementP, 
    LayoutP,
    cutlass::ComplexTransform::kNone,
    128 / cutlass::sizeof_bits<ElementQ>::value,
    ElementV,
    LayoutV,
    cutlass::ComplexTransform::kNone,
    128 / cutlass::sizeof_bits<ElementK>::value,
    ElementNorm,
    LayoutNorm,
    ElementOutput,
    LayoutO,
    ElementAccumulator,
    OperatorClass, 
    ArchTag,
    ThreadblockShape1,
    WarpShape1,
    InstructionShape,
    EpilogueOutputOp1,
    ThreadblockSwizzle, 
    Stages1,
    kGroupScheduleMode1
  >::GemmKernel;

  using GemmGrouped1 = cutlass::gemm::device::GemmGrouped<GemmKernel1>;

public:

  /// Arguments class
  struct Arguments {
    cutlass::gemm::GemmCoord *problem_sizes0;
    cutlass::gemm::GemmCoord *problem_sizes0_real;
    cutlass::gemm::GemmCoord *problem_sizes1;
    int problem_count;
    int threadblock_count;

    ElementQ ** ptr_Q;
    ElementK ** ptr_K;
    ElementP ** ptr_P;
    ElementP ** ptr_V;
    ElementP ** ptr_O;

    ElementNorm **ptr_Max;
    ElementSum **ptr_Sum;

    ElementP *block_P;
    ElementNorm *block_Norm;
    ElementSum *block_Sum;
    int64_t *offset_P;
    int64_t *offset_Norm_Device;
    int64_t *offset_Sum_Device;

    typename LayoutQ::Stride::LongIndex *ldq;
    typename LayoutK::Stride::LongIndex *ldk;
    typename LayoutP::Stride::LongIndex *ldp;
    typename LayoutP::Stride::LongIndex *ldv;
    typename LayoutP::Stride::LongIndex *ldo;

    cutlass::gemm::GemmCoord *problem_sizes0_host;
    cutlass::gemm::GemmCoord *problem_sizes1_host;

    ElementAccumulator alpha0;
    ElementAccumulator alpha1;
    ElementAccumulator beta;

    int head_number;
    int batch_size;
    int seq_length;

    typename ApplyFinalReductionDevice::Arguments reduction;

    //
    // Methods
    //
    Arguments(): 
      problem_count(0), 
      threadblock_count(0), 
      ptr_Q(nullptr),
      ptr_K(nullptr),
      ptr_P(nullptr),
      ptr_V(nullptr),
      ptr_O(nullptr),
      ptr_Max(nullptr),
      ptr_Sum(nullptr),
      block_P(nullptr),
      block_Norm(nullptr),
      block_Sum(nullptr),
      offset_P(nullptr),
      offset_Norm_Device(nullptr),
      offset_Sum_Device(nullptr),
      ldq(nullptr),
      ldk(nullptr),
      ldp(nullptr),
      ldv(nullptr),
      ldo(nullptr),
      head_number(0),
      batch_size(0),
      seq_length(0)
    {

    }

    Arguments(
      cutlass::gemm::GemmCoord *problem_sizes0,
      cutlass::gemm::GemmCoord *problem_sizes1,
      int problem_count,
      int threadblock_count,
      ElementQ ** ptr_Q,
      ElementK ** ptr_K,
      ElementP ** ptr_P,
      ElementP ** ptr_V,
      ElementP ** ptr_O,
      ElementNorm **ptr_Max,
      ElementSum **ptr_Sum,
      ElementP *block_P,
      ElementNorm *block_Norm,
      ElementSum *block_Sum,
      int64_t *offset_P,
      int64_t *offset_Norm_Device,
      int64_t *offset_Sum_Device,
      typename LayoutQ::Stride::LongIndex *ldq,
      typename LayoutK::Stride::LongIndex *ldk,
      typename LayoutP::Stride::LongIndex *ldp,
      typename LayoutP::Stride::LongIndex *ldv,
      typename LayoutP::Stride::LongIndex *ldo,
      ElementAccumulator alpha0,
      ElementAccumulator alpha1,
      ElementAccumulator beta,
      int head_number,
      int batch_size,
      int seq_length,
      cutlass::gemm::GemmCoord *problem_sizes0_host = nullptr,
      cutlass::gemm::GemmCoord *problem_sizes1_host = nullptr,
      cutlass::gemm::GemmCoord *problem_sizes0_real = nullptr
    ):
      problem_sizes0(problem_sizes0),
      problem_sizes1(problem_sizes1),
      problem_count(problem_count),
      threadblock_count(threadblock_count),
      ptr_Q(ptr_Q),
      ptr_K(ptr_K),
      ptr_P(ptr_P),
      ptr_V(ptr_V),
      ptr_O(ptr_O),
      ptr_Max(ptr_Max),
      ptr_Sum(ptr_Sum),
      block_P(block_P),
      block_Norm(block_Norm),
      block_Sum(block_Sum),
      offset_P(offset_P),
      offset_Norm_Device(offset_Norm_Device),
      offset_Sum_Device(offset_Sum_Device),
      ldq(ldq),
      ldk(ldk),
      ldp(ldp),
      ldv(ldv),
      ldo(ldo),
      alpha0(alpha0),
      alpha1(alpha1),
      beta(beta),
      head_number(head_number),
      batch_size(batch_size),
      seq_length(seq_length),
      problem_sizes0_host(problem_sizes0_host),
      problem_sizes1_host(problem_sizes1_host),
      problem_sizes0_real(problem_sizes0_real),
      reduction(
        problem_sizes0,
        block_Norm,
        block_Sum,
        offset_Norm_Device,
        offset_Sum_Device
      )
    {
        
    }


  };

  struct Params {
    cutlass::gemm::GemmCoord *problem_sizes0;
    cutlass::gemm::GemmCoord *problem_sizes0_real;
    cutlass::gemm::GemmCoord *problem_sizes1;
    int problem_count;
    int threadblock_count;

    ElementQ ** ptr_Q;
    ElementK ** ptr_K;
    ElementP ** ptr_P;
    ElementP ** ptr_V;
    ElementP ** ptr_O;

    ElementNorm **ptr_Max;
    ElementSum **ptr_Sum;

    ElementP *block_P;
    ElementNorm *block_Norm;
    ElementSum *block_Sum;
    int64_t *offset_P;
    int64_t *offset_Norm_Device;
    int64_t *offset_Sum_Device;

    typename LayoutQ::Stride::LongIndex *ldq;
    typename LayoutK::Stride::LongIndex *ldk;
    typename LayoutP::Stride::LongIndex *ldp;
    typename LayoutP::Stride::LongIndex *ldv;
    typename LayoutP::Stride::LongIndex *ldo;

    cutlass::gemm::GemmCoord *problem_sizes0_host;
    cutlass::gemm::GemmCoord *problem_sizes1_host;

    ElementAccumulator alpha0;
    ElementAccumulator alpha1;
    ElementAccumulator beta;

    int head_number;
    int batch_size;
    int seq_length;

    typename ApplyFinalReductionDevice::Params reduction;

    Params(): 
      problem_count(0), 
      threadblock_count(0), 
      ptr_Q(nullptr),
      ptr_K(nullptr),
      ptr_P(nullptr),
      ptr_V(nullptr),
      ptr_O(nullptr),
      ptr_Max(nullptr),
      ptr_Sum(nullptr),
      block_P(nullptr),
      block_Norm(nullptr),
      block_Sum(nullptr),
      offset_P(nullptr),
      offset_Norm_Device(nullptr),
      offset_Sum_Device(nullptr),
      ldq(nullptr),
      ldk(nullptr),
      ldp(nullptr),
      ldv(nullptr),
      ldo(nullptr),
      problem_sizes0(nullptr),
      problem_sizes1(nullptr),
      problem_sizes0_real(nullptr),
      head_number(0),
      batch_size(0),
      seq_length(0)
    {

    }

    Params(Arguments const &args, void *workspace = nullptr):
      problem_sizes0(args.problem_sizes0),
      problem_sizes1(args.problem_sizes1),
      problem_count(args.problem_count),
      threadblock_count(args.threadblock_count),
      ptr_Q(args.ptr_Q),
      ptr_K(args.ptr_K),
      ptr_P(args.ptr_P),
      ptr_V(args.ptr_V),
      ptr_O(args.ptr_O),
      ptr_Max(args.ptr_Max),
      ptr_Sum(args.ptr_Sum),
      block_P(args.block_P),
      block_Norm(args.block_Norm),
      block_Sum(args.block_Sum),
      offset_P(args.offset_P),
      offset_Norm_Device(args.offset_Norm_Device),
      offset_Sum_Device(args.offset_Sum_Device),
      ldq(args.ldq),
      ldk(args.ldk),
      ldp(args.ldp),
      ldv(args.ldv),
      ldo(args.ldo),
      problem_sizes0_host(args.problem_sizes0_host),
      problem_sizes1_host(args.problem_sizes1_host),
      problem_sizes0_real(args.problem_sizes0_real),
      alpha0(args.alpha0),
      alpha1(args.alpha1),
      beta(args.beta),
      head_number(args.head_number),
      batch_size(args.batch_size),
      seq_length(args.seq_length),
      reduction(args.reduction)
    {

    }
  };


private:

  Params params_;
  GemmGrouped0 gemm_grouped0;
  GemmGrouped1 gemm_grouped1;


public:

  /// Ctor
  FusedMultiHeadAttention() {

  }

  /// Initialize
  Status initialize(Arguments const &args, 
                    void *workspace0 = nullptr,
                    void *workspace1 = nullptr) {

    params_ = Params(args);

    typename GemmGrouped0::Arguments args_gemm0(
      params_.problem_sizes0,
      params_.problem_count,
      params_.threadblock_count,
      params_.ptr_Q,
      params_.ptr_K,
      params_.ptr_P,
      params_.ptr_P,
      params_.ptr_Max,
      params_.ptr_Sum,
      params_.ldq,
      params_.ldk,
      params_.ldp,
      params_.ldp,
      typename GemmGrouped0::GemmKernel::EpilogueVisitor::Arguments(
        {
          params_.alpha0,
          params_.beta
        }
      ),
      params_.problem_sizes0_host,
      params_.problem_sizes0_real
    );


    Status result0 = gemm_grouped0.initialize(args_gemm0, workspace0);

    typename EpilogueOutputOp1::Params epilogue_op1(params_.alpha1, params_.beta);

    typename GemmGrouped1::Arguments args_gemm1(
      params_.problem_sizes1,
      params_.problem_count,
      params_.threadblock_count,
      epilogue_op1,
      params_.ptr_P,
      params_.ptr_V,
      params_.ptr_O,
      params_.ptr_O,
      (void**)params_.ptr_Max,
      (void**)params_.ptr_Sum,
      params_.ldp,
      params_.ldv,
      params_.ldo,
      params_.ldo,
      params_.problem_sizes1_host
    );

    Status result1 = gemm_grouped1.initialize(args_gemm1, workspace1);

    if ((result0 == cutlass::Status::kSuccess) && (result1 == cutlass::Status::kSuccess) ) {
      return cutlass::Status::kSuccess;
    }else{
      if (result0 != cutlass::Status::kSuccess) {
        return result0;
      }else{
        return result1;
      }
    }
  }

  /// Run
  Status run(cudaStream_t stream = nullptr) {

    Status result = gemm_grouped0.run();
    cudaError_t error_info;

    if (result != cutlass::Status::kSuccess) {
      return cutlass::Status::kErrorInternal;
    }

    int thread_per_block = 1024;

    dim3 final_reduction_grid(params_.head_number * params_.batch_size);
    dim3 final_reduction_block(thread_per_block);

    cutlass::Kernel<ApplyFinalReductionDevice><<<
        final_reduction_grid, final_reduction_block, sizeof(typename ApplyFinalReductionDevice::SharedStorage), stream
      >>>(params_.reduction);

    error_info = cudaGetLastError();

    if (error_info != cudaSuccess) {
      return cutlass::Status::kErrorInternal;
    }

    result = gemm_grouped1.run();

    if (result != cutlass::Status::kSuccess) {
      return cutlass::Status::kErrorInternal;
    }

    return cutlass::Status::kSuccess;
  }

  /// Function call operator
  Status operator()(cudaStream_t stream = nullptr) {
    return run(stream);
  }
};

}
