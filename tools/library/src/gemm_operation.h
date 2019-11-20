/***************************************************************************************************
 * Copyright (c) 2017-2019, NVIDIA CORPORATION.  All rights reserved.
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
/* \file
   \brief Defines operations for all GEMM operation kinds in CUTLASS Library.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/gemm/device/gemm.h"
#include "cutlass/gemm/device/gemm_batched.h"

#include "cutlass/library/library.h"
#include "library_internal.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace library {

///////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Operator_>
class GemmOperationBase : public Operation {
public:
  using Operator = Operator_;
  using ElementA = typename Operator::ElementA;
  using LayoutA = typename Operator::LayoutA;
  using ElementB = typename Operator::ElementB;
  using LayoutB = typename Operator::LayoutB;
  using ElementC = typename Operator::ElementC;
  using LayoutC = typename Operator::LayoutC;
  using ElementAccumulator = typename Operator::ElementAccumulator;
  using ElementCompute = typename Operator::EpilogueOutputOp::ElementCompute;

  using OperatorArguments = typename Operator::Arguments;

protected:

  /// 
  GemmDescription description_;

public:

  /// Constructor
  GemmOperationBase(char const *name = "unknown_gemm") {

    description_.name = name;
    description_.kind = OperationKind::kGemm;
  
    description_.tile_description.threadblock_shape = make_Coord(
      Operator::ThreadblockShape::kM,
      Operator::ThreadblockShape::kN,
      Operator::ThreadblockShape::kK);

    description_.tile_description.threadblock_stages = Operator::kStages;

    description_.tile_description.warp_count = make_Coord(
      Operator::GemmKernel::WarpCount::kM,
      Operator::GemmKernel::WarpCount::kN,
      Operator::GemmKernel::WarpCount::kK);
    
    description_.tile_description.math_instruction.instruction_shape = make_Coord(
      Operator::InstructionShape::kM,
      Operator::InstructionShape::kN,
      Operator::InstructionShape::kK);

    description_.tile_description.math_instruction.element_accumulator = 
      NumericTypeMap<ElementAccumulator>::kId;

    description_.tile_description.math_instruction.opcode_class = 
      OpcodeClassMap<typename Operator::OperatorClass>::kId;

    description_.tile_description.minimum_compute_capability = 
      ArchMap<typename Operator::ArchTag>::kMin;

    description_.tile_description.maximum_compute_capability = 
      ArchMap<typename Operator::ArchTag>::kMax;

    description_.gemm_kind = GemmKind::kGemm;
    
    description_.A = make_TensorDescription<ElementA, LayoutA>(Operator::kAlignmentA);
    description_.B = make_TensorDescription<ElementB, LayoutB>(Operator::kAlignmentB);
    description_.C = make_TensorDescription<ElementC, LayoutC>(Operator::kAlignmentC);
    description_.element_epilogue = NumericTypeMap<ElementCompute>::kId;

    description_.split_k_mode = Operator::kSplitKSerial ? SplitKMode::kSerial : SplitKMode::kNone;
    description_.transform_A = ComplexTransform::kNone;
    description_.transform_B = ComplexTransform::kNone;
  }
  
  /// Returns the description of the GEMM operation
  virtual OperationDescription const & description() const {
    return description_;
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Operator_>
class GemmOperation : public GemmOperationBase<Operator_> {
public:

  using Operator = Operator_;
  using ElementA = typename Operator::ElementA;
  using LayoutA = typename Operator::LayoutA;
  using ElementB = typename Operator::ElementB;
  using LayoutB = typename Operator::LayoutB;
  using ElementC = typename Operator::ElementC;
  using LayoutC = typename Operator::LayoutC;
  using ElementAccumulator = typename Operator::ElementAccumulator;
  using ElementCompute = typename Operator::EpilogueOutputOp::ElementCompute;

  using OperatorArguments = typename Operator::Arguments;

public:

  /// Constructor
  GemmOperation(char const *name = "unknown_gemm"): GemmOperationBase<Operator_>(name) {

    this->description_.gemm_kind = GemmKind::kGemm;
  }

protected:

  /// Constructs the arguments structure given the configuration and arguments
  static Status construct_arguments_(
    OperatorArguments &operator_args,
    GemmConfiguration const *configuration) {

    operator_args.problem_size = configuration->problem_size;
    operator_args.ref_A = {nullptr, int(configuration->lda)};
    operator_args.ref_B = {nullptr, int(configuration->ldb)};
    operator_args.ref_C = {nullptr, int(configuration->ldc)};
    operator_args.ref_D = {nullptr, int(configuration->ldd)};
    operator_args.split_k_slices = configuration->split_k_slices;

    return Status::kSuccess;
  }

  /// Constructs the arguments structure given the configuration and arguments
  static Status update_arguments_(
    OperatorArguments &operator_args,
    GemmArguments const *arguments) {

    if (arguments->pointer_mode == ScalarPointerMode::kHost) {
      typename Operator::EpilogueOutputOp::Params params(
        *static_cast<ElementCompute const *>(arguments->alpha),
        *static_cast<ElementCompute const *>(arguments->beta)
      );
      operator_args.epilogue = params;
    }
    else if (arguments->pointer_mode == ScalarPointerMode::kDevice){
      typename Operator::EpilogueOutputOp::Params params(
        static_cast<ElementCompute const *>(arguments->alpha),
        static_cast<ElementCompute const *>(arguments->beta)
      );
      operator_args.epilogue = params; 
    }
    else {
      return Status::kErrorInvalidProblem;
    }

    operator_args.ref_A.reset(static_cast<ElementA const *>(arguments->A));
    operator_args.ref_B.reset(static_cast<ElementB const *>(arguments->B));
    operator_args.ref_C.reset(static_cast<ElementC const *>(arguments->C));
    operator_args.ref_D.reset(static_cast<ElementC *>(arguments->D));

    return Status::kSuccess;
  }

public:

  /// Returns success if the operation can proceed
  virtual Status can_implement(
    void const *configuration_ptr, 
    void const *arguments_ptr) const {

    GemmConfiguration const *configuration = 
      static_cast<GemmConfiguration const *>(configuration_ptr);

    GemmArguments const *arguments = 
      static_cast<GemmArguments const *>(arguments_ptr);

    OperatorArguments args;

    Status status = construct_arguments_(args, configuration);

    if (status != Status::kSuccess) {
      return status;
    }

    status = update_arguments_(args, arguments);

    if (status != Status::kSuccess) {
      return status;
    }

    return Operator::can_implement(args);
  }
  
  /// Gets the host-side workspace
  virtual uint64_t get_host_workspace_size(
    void const *configuration) const {

    return sizeof(Operator);
  }
  
  /// Gets the device-side workspace
  virtual uint64_t get_device_workspace_size(
    void const *configuration_ptr) const {

    OperatorArguments args;

    Status status = construct_arguments_(
      args, 
      static_cast<GemmConfiguration const *>(configuration_ptr));

    if (status != Status::kSuccess) {
      return 0;
    }

    return Operator::get_workspace_size(args);
  }
  
  /// Initializes the workspace
  virtual Status initialize(
    void const *configuration_ptr, 
    void *host_workspace, 
    void *device_workspace, 
    cudaStream_t stream = nullptr) const {

    OperatorArguments args;

    Status status = construct_arguments_(
      args, 
      static_cast<GemmConfiguration const *>(configuration_ptr));

    if (status != Status::kSuccess) {
      return status;
    }

    Operator *op = new (host_workspace) Operator;

    return op->initialize(args, device_workspace, stream);
  }

  /// Runs the kernel
  virtual Status run(
    void const *arguments_ptr,
    void *host_workspace, 
    void *device_workspace = nullptr, 
    cudaStream_t stream = nullptr) const {

    OperatorArguments args;

    Status status = update_arguments_(
      args, 
      static_cast<GemmArguments const *>(arguments_ptr));

    if (status != Status::kSuccess) {
      return status;
    }

    Operator *op = static_cast<Operator *>(host_workspace);

    status = op->update(args, device_workspace);

    if (status != Status::kSuccess) {
      return status;
    }

    return op->run(stream);
  }
};


///////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Operator_>
class GemmBatchedOperation : public GemmOperationBase<Operator_> {
public:

  using Operator = Operator_;
  using ElementA = typename Operator::ElementA;
  using LayoutA = typename Operator::LayoutA;
  using ElementB = typename Operator::ElementB;
  using LayoutB = typename Operator::LayoutB;
  using ElementC = typename Operator::ElementC;
  using LayoutC = typename Operator::LayoutC;
  using ElementAccumulator = typename Operator::ElementAccumulator;
  using ElementCompute = typename Operator::EpilogueOutputOp::ElementCompute;

  using OperatorArguments = typename Operator::Arguments;

protected:

  /// 
  GemmDescription description_;

public:

  /// Constructor
  GemmBatchedOperation(char const *name = "unknown_gemm"): GemmOperationBase<Operator_>(name) {

    description_.gemm_kind = GemmKind::kBatched;
  }

protected:

  /// Constructs the arguments structure given the configuration and arguments
  static Status construct_arguments_(
    OperatorArguments &operator_args,
    GemmBatchedConfiguration const *configuration) {

    operator_args.problem_size = configuration->problem_size;
    operator_args.ref_A = {nullptr, int(configuration->lda)};
    operator_args.stride_A = configuration->batch_stride_A;
    operator_args.ref_B = {nullptr, int(configuration->ldb)};
    operator_args.stride_B = configuration->batch_stride_B;
    operator_args.ref_C = {nullptr, int(configuration->ldc)};
    operator_args.stride_C = configuration->batch_stride_C;
    operator_args.ref_D = {nullptr, int(configuration->ldd)};
    operator_args.stride_D = configuration->batch_stride_D;

    operator_args.batch_count = configuration->batch_count;

    return Status::kSuccess;
  }

  /// Constructs the arguments structure given the configuration and arguments
  static Status update_arguments_(
    OperatorArguments &operator_args,
    GemmBatchedArguments const *arguments) {

    if (arguments->pointer_mode == ScalarPointerMode::kHost) {
      typename Operator::EpilogueOutputOp::Params params(
        *static_cast<ElementCompute const *>(arguments->alpha),
        *static_cast<ElementCompute const *>(arguments->beta)
      );
      operator_args.epilogue = params;
    }
    else if (arguments->pointer_mode == ScalarPointerMode::kDevice){
      typename Operator::EpilogueOutputOp::Params params(
        static_cast<ElementCompute const *>(arguments->alpha),
        static_cast<ElementCompute const *>(arguments->beta)
      );
      operator_args.epilogue = params; 
    }
    else {
      return Status::kErrorInvalidProblem;
    }

    operator_args.ref_A.reset(static_cast<ElementA const *>(arguments->A));
    operator_args.ref_B.reset(static_cast<ElementB const *>(arguments->B));
    operator_args.ref_C.reset(static_cast<ElementC const *>(arguments->C));
    operator_args.ref_D.reset(static_cast<ElementC *>(arguments->D));

    return Status::kSuccess;
  }

public:

  /// Returns the description of the GEMM operation
  virtual OperationDescription const & description() const {
    return description_;
  }

  /// Returns success if the operation can proceed
  virtual Status can_implement(
    void const *configuration_ptr, 
    void const *arguments_ptr) const {

    GemmBatchedConfiguration const *configuration = 
      static_cast<GemmBatchedConfiguration const *>(configuration_ptr);

    GemmBatchedArguments const *arguments = 
      static_cast<GemmBatchedArguments const *>(arguments_ptr);

    OperatorArguments args;

    Status status = construct_arguments_(args, configuration);

    if (status != Status::kSuccess) {
      return status;
    }

    status = update_arguments_(args, arguments);

    if (status != Status::kSuccess) {
      return status;
    }

    return Operator::can_implement(args);
  }
  
  /// Gets the host-side workspace
  virtual uint64_t get_host_workspace_size(
    void const *configuration) const {

    return sizeof(Operator);
  }
  
  /// Gets the device-side workspace
  virtual uint64_t get_device_workspace_size(
    void const *configuration_ptr) const {

    OperatorArguments args;

    Status status = construct_arguments_(
      args, 
      static_cast<GemmBatchedConfiguration const *>(configuration_ptr));

    if (status != Status::kSuccess) {
      return 0;
    }

    return Operator::get_workspace_size(args);
  }
  
  /// Initializes the workspace
  virtual Status initialize(
    void const *configuration_ptr, 
    void *host_workspace, 
    void *device_workspace, 
    cudaStream_t stream = nullptr) const {

    OperatorArguments args;

    Status status = construct_arguments_(
      args, 
      static_cast<GemmBatchedConfiguration const *>(configuration_ptr));

    if (status != Status::kSuccess) {
      return status;
    }

    Operator *op = new (host_workspace) Operator;

    return op->initialize(args, device_workspace, stream);
  }

  /// Runs the kernel
  virtual Status run(
    void const *arguments_ptr,
    void *host_workspace, 
    void *device_workspace = nullptr, 
    cudaStream_t stream = nullptr) const {

    OperatorArguments args;

    Status status = update_arguments_(
      args, 
      static_cast<GemmBatchedArguments const *>(arguments_ptr));

    if (status != Status::kSuccess) {
      return status;
    }

    Operator *op = static_cast<Operator *>(host_workspace);

    status = op->update(args, device_workspace);

    if (status != Status::kSuccess) {
      return status;
    }

    return op->run(stream);
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace library
} // namespace cutlass

///////////////////////////////////////////////////////////////////////////////////////////////////
