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
/* \file
   \brief Defines operations for all GEMM operation kinds in CUTLASS Library.
*/

#pragma once
#include "cutlass/cutlass.h"

#include "cutlass/gemm/device/gemm.h"
#include "cutlass/gemm/device/gemm_sparse.h"
#include "cutlass/gemm/device/gemm_complex.h"
#include "cutlass/gemm/device/gemm_batched.h"
#include "cutlass/gemm/device/gemm_array.h"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/default_gemm_universal.h"
#include "cutlass/gemm/kernel/default_gemm_planar_complex_universal.h"

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
    description_.provider = Provider::kCUTLASS;
    description_.kind = OperationKind::kGemm;
    description_.gemm_kind = GemmKind::kGemm;

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

    description_.tile_description.math_instruction.math_operation =
      MathOperationMap<typename Operator::Operator>::kId;

    description_.tile_description.minimum_compute_capability = 
      ArchMap<typename Operator::ArchTag, typename Operator::OperatorClass>::kMin;

    description_.tile_description.maximum_compute_capability = 
      ArchMap<typename Operator::ArchTag, typename Operator::OperatorClass>::kMax;
    
    description_.A = make_TensorDescription<ElementA, LayoutA>(Operator::kAlignmentA);
    description_.B = make_TensorDescription<ElementB, LayoutB>(Operator::kAlignmentB);
    description_.C = make_TensorDescription<ElementC, LayoutC>(Operator::kAlignmentC);
    description_.element_epilogue = NumericTypeMap<ElementCompute>::kId;

    description_.split_k_mode = SplitKMode::kNone;
    description_.transform_A = ComplexTransformMap<Operator::kTransformA>::kId;
    description_.transform_B = ComplexTransformMap<Operator::kTransformB>::kId;
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

  void print_operator_args(OperatorArguments &operator_args) const {
#if 0
    std::cout << "GemmOperation::OperatorArguments" << std::endl;
    std::cout << "    problem_size: " << operator_args.problem_size.m() << ", "<< operator_args.problem_size.n() << "," <<  operator_args.problem_size.k() << std::endl;
    std::cout << "    alpha:      " << operator_args.epilogue.alpha << std::endl;
    std::cout << "    alpha_ptr:  " << operator_args.epilogue.alpha_ptr << std::endl;
    std::cout << "    beta:       " << operator_args.epilogue.beta << std::endl;
    std::cout << "    beta_ptr:   " << operator_args.epilogue.beta_ptr << std::endl;
    std::cout << "  ref_A.data(): " << operator_args.ref_A.data() << std::endl;
    std::cout << "  ref_A.stride: " << operator_args.ref_A.stride(0) << std::endl;
    std::cout << "  ref_B.data(): " << operator_args.ref_B.data() << std::endl;
    std::cout << "  ref_B.stride: " << operator_args.ref_B.stride(0) << std::endl;
    std::cout << "  ref_C.data(): " << operator_args.ref_C.data() << std::endl;
    std::cout << "  ref_C.stride: " << operator_args.ref_C.stride(0) << std::endl;
#endif
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Operator_>
class GemmSparseOperation : public GemmOperationBase<Operator_> {
public:

  using Operator = Operator_;
  using ElementA = typename Operator::ElementA;
  using LayoutA = typename Operator::LayoutA;
  using ElementB = typename Operator::ElementB;
  using LayoutB = typename Operator::LayoutB;
  using ElementC = typename Operator::ElementC;
  using LayoutC = typename Operator::LayoutC;
  using ElementE = typename Operator::ElementE;
  using LayoutE = typename Operator::LayoutE;
  using ElementAccumulator = typename Operator::ElementAccumulator;
  using ElementCompute = typename Operator::EpilogueOutputOp::ElementCompute;

  using OperatorArguments = typename Operator::Arguments;

public:

  /// Constructor
  GemmSparseOperation(char const *name = "unknown_gemm"): GemmOperationBase<Operator_>(name) {

    this->description_.kind = OperationKind::kSparseGemm;
    this->description_.gemm_kind = GemmKind::kSparse;
    this->description_.E = make_TensorDescription<ElementE, LayoutE>(Operator::kAlignmentE);
  }

protected:

  /// Constructs the arguments structure given the configuration and arguments
  static Status construct_arguments_(
    OperatorArguments &operator_args,
    SparseGemmConfiguration const *configuration) {

    operator_args.problem_size = configuration->problem_size;
    operator_args.ref_A = {nullptr, int(configuration->lda)};
    operator_args.ref_B = {nullptr, int(configuration->ldb)};
    operator_args.ref_C = {nullptr, int(configuration->ldc)};
    operator_args.ref_D = {nullptr, int(configuration->ldd)};
    operator_args.ref_E = {nullptr, int(configuration->lde)};

    return Status::kSuccess;
  }

  /// Constructs the arguments structure given the configuration and arguments
  static Status update_arguments_(
    OperatorArguments &operator_args,
    SparseGemmArguments const *arguments) {

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
    operator_args.ref_E.reset(static_cast<ElementE const *>(arguments->E));

    return Status::kSuccess;
  }

public:

  /// Returns success if the operation can proceed
  virtual Status can_implement(
    void const *configuration_ptr, 
    void const *arguments_ptr) const {

    SparseGemmConfiguration const *configuration = 
      static_cast<SparseGemmConfiguration const *>(configuration_ptr);

    SparseGemmArguments const *arguments = 
      static_cast<SparseGemmArguments const *>(arguments_ptr);

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
      static_cast<SparseGemmConfiguration const *>(configuration_ptr));

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
      static_cast<SparseGemmConfiguration const *>(configuration_ptr));

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
      static_cast<SparseGemmArguments const *>(arguments_ptr));

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

  void print_operator_args(OperatorArguments &operator_args) const {
#if 0
    std::cout << "GemmOperation::OperatorArguments" << std::endl;
    std::cout << "    problem_size: " << operator_args.problem_size.m() << ", "<< operator_args.problem_size.n() << "," <<  operator_args.problem_size.k() << std::endl;
    std::cout << "    alpha:      " << operator_args.epilogue.alpha << std::endl;
    std::cout << "    alpha_ptr:  " << operator_args.epilogue.alpha_ptr << std::endl;
    std::cout << "    beta:       " << operator_args.epilogue.beta << std::endl;
    std::cout << "    beta_ptr:   " << operator_args.epilogue.beta_ptr << std::endl;
    std::cout << "  ref_A.data(): " << operator_args.ref_A.data() << std::endl;
    std::cout << "  ref_A.stride: " << operator_args.ref_A.stride(0) << std::endl;
    std::cout << "  ref_B.data(): " << operator_args.ref_B.data() << std::endl;
    std::cout << "  ref_B.stride: " << operator_args.ref_B.stride(0) << std::endl;
    std::cout << "  ref_C.data(): " << operator_args.ref_C.data() << std::endl;
    std::cout << "  ref_C.stride: " << operator_args.ref_C.stride(0) << std::endl;
#endif
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Operator_>
class GemmUniversalOperation : public GemmOperationBase<Operator_> {
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
  GemmUniversalOperation(char const *name = "unknown_gemm"): 
    GemmOperationBase<Operator_>(name) {

    this->description_.gemm_kind = GemmKind::kUniversal;
  }

protected:

  /// Constructs the arguments structure given the configuration and arguments
  static Status construct_arguments_(
    OperatorArguments &operator_args,
    GemmUniversalConfiguration const *configuration) {

    operator_args.mode = configuration->mode;

    operator_args.problem_size = configuration->problem_size;
    operator_args.batch_count = configuration->batch_count;

    operator_args.lda = int(configuration->lda);
    operator_args.ldb = int(configuration->ldb);
    operator_args.ldc = int(configuration->ldc);
    operator_args.ldd = int(configuration->ldd);
    
    return Status::kSuccess;
  }

  /// Constructs the arguments structure given the configuration and arguments
  static Status update_arguments_(
    OperatorArguments &operator_args,
    GemmUniversalArguments const *arguments) {
    
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

    // update arguments
    operator_args.ptr_A = arguments->A;
    operator_args.ptr_B = arguments->B;
    operator_args.ptr_C = arguments->C;
    operator_args.ptr_D = arguments->D;

    operator_args.batch_stride_A = arguments->batch_stride_A;
    operator_args.batch_stride_B = arguments->batch_stride_B;
    operator_args.batch_stride_C = arguments->batch_stride_C;
    operator_args.batch_stride_D = arguments->batch_stride_D;
    
    return Status::kSuccess;
  }

public:

  /// Returns success if the operation can proceed
  virtual Status can_implement(
    void const *configuration_ptr, 
    void const *arguments_ptr) const {
    
    GemmUniversalConfiguration const *configuration = 
      static_cast<GemmUniversalConfiguration const *>(configuration_ptr);

    GemmUniversalArguments const *arguments = 
      static_cast<GemmUniversalArguments const *>(arguments_ptr);

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
      static_cast<GemmUniversalConfiguration const *>(configuration_ptr));

    if (status != Status::kSuccess) {
      return 0;
    }

    uint64_t size = Operator::get_workspace_size(args);

    return size;
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
      static_cast<GemmUniversalConfiguration const *>(configuration_ptr));

    if (status != Status::kSuccess) {
      return status;
    }

    Operator *op = new (host_workspace) Operator;

    status = op->initialize(args, device_workspace, stream);
    
    return status;
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
      static_cast<GemmUniversalArguments const *>(arguments_ptr));

    if (status != Status::kSuccess) {
      return status;
    }
    
    Operator *op = static_cast<Operator *>(host_workspace);
    
    status = op->update(args, device_workspace);

    if (status != Status::kSuccess) {
      return status;
    }
    
    status = op->run(stream);
    
    return status;
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Operator_>
class GemmPlanarComplexOperation : public GemmOperationBase<Operator_> {
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
  GemmPlanarComplexOperation(char const *name = "unknown_gemm"): GemmOperationBase<Operator_>(name) {

    this->description_.gemm_kind = GemmKind::kPlanarComplex;
  }

protected:

  /// Constructs the arguments structure given the configuration and arguments
  static Status construct_arguments_(
    OperatorArguments &operator_args,
    GemmPlanarComplexConfiguration const *configuration) {

    operator_args.mode = cutlass::gemm::GemmUniversalMode::kBatched;
    operator_args.problem_size = configuration->problem_size;
    operator_args.batch_count = configuration->batch_count;

    operator_args.lda_real = int(configuration->lda_real);
    operator_args.lda_imag = int(configuration->lda_imag);
    operator_args.ldb_real = int(configuration->ldb_real);
    operator_args.ldb_imag = int(configuration->ldb_imag);
    operator_args.ldc_real = int(configuration->ldc_real);
    operator_args.ldc_imag = int(configuration->ldc_imag);
    operator_args.ldd_real = int(configuration->ldd_real);
    operator_args.ldd_imag = int(configuration->ldd_imag);

    return Status::kSuccess;
  }

  /// Constructs the arguments structure given the configuration and arguments
  static Status update_arguments_(
    OperatorArguments &operator_args,
    GemmPlanarComplexArguments const *arguments) {
    
    if (arguments->pointer_mode == ScalarPointerMode::kHost) {
      typename Operator::EpilogueOutputOp::Params params(
        *static_cast<cutlass::complex<ElementCompute> const *>(arguments->alpha),
        *static_cast<cutlass::complex<ElementCompute> const *>(arguments->beta)
      );
      operator_args.epilogue = params;
    }
    else if (arguments->pointer_mode == ScalarPointerMode::kDevice){
      typename Operator::EpilogueOutputOp::Params params(
        static_cast<cutlass::complex<ElementCompute> const *>(arguments->alpha),
        static_cast<cutlass::complex<ElementCompute> const *>(arguments->beta)
      );
      operator_args.epilogue = params; 
    }
    else {
      return Status::kErrorInvalidProblem;
    }

    // update arguments
    operator_args.ptr_A_real = arguments->A_real;
    operator_args.ptr_A_imag = arguments->A_imag;
    operator_args.ptr_B_real = arguments->B_real;
    operator_args.ptr_B_imag = arguments->B_imag;
    operator_args.ptr_C_real = arguments->C_real;
    operator_args.ptr_C_imag = arguments->C_imag;
    operator_args.ptr_D_real = arguments->D_real;
    operator_args.ptr_D_imag = arguments->D_imag;

    operator_args.batch_stride_A = arguments->batch_stride_A_real;
    operator_args.batch_stride_A_imag = arguments->batch_stride_A_imag;
    operator_args.batch_stride_B = arguments->batch_stride_B_real;
    operator_args.batch_stride_B_imag = arguments->batch_stride_B_imag;
    operator_args.batch_stride_C = arguments->batch_stride_C_real;
    operator_args.batch_stride_C_imag = arguments->batch_stride_C_imag;
    operator_args.batch_stride_D = arguments->batch_stride_D_real;
    operator_args.batch_stride_D_imag = arguments->batch_stride_D_imag;
    
    return Status::kSuccess;
  }

public:

  /// Returns success if the operation can proceed
  virtual Status can_implement(
    void const *configuration_ptr, 
    void const *arguments_ptr) const {
    
    GemmPlanarComplexConfiguration const *configuration = 
      static_cast<GemmPlanarComplexConfiguration const *>(configuration_ptr);

    GemmPlanarComplexArguments const *arguments = 
      static_cast<GemmPlanarComplexArguments const *>(arguments_ptr);

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
      static_cast<GemmPlanarComplexConfiguration const *>(configuration_ptr));

    if (status != Status::kSuccess) {
      return 0;
    }

    uint64_t size = Operator::get_workspace_size(args);

    return size;
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
      static_cast<GemmPlanarComplexConfiguration const *>(configuration_ptr));

    if (status != Status::kSuccess) {
      return status;
    }

    Operator *op = new (host_workspace) Operator;

    status = op->initialize(args, device_workspace, stream);
    
    return status;
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
      static_cast<GemmPlanarComplexArguments const *>(arguments_ptr));

    if (status != Status::kSuccess) {
      return status;
    }
    
    Operator *op = static_cast<Operator *>(host_workspace);
    
    status = op->update(args, device_workspace);

    if (status != Status::kSuccess) {
      return status;
    }
    
    status = op->run(stream);
    
    return status;
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Operator_>
class GemmPlanarComplexArrayOperation : public GemmOperationBase<Operator_> {
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
  GemmPlanarComplexArrayOperation(char const *name = "unknown_gemm"): GemmOperationBase<Operator_>(name) {

    this->description_.gemm_kind = GemmKind::kPlanarComplexArray;
  }

protected:

  /// Constructs the arguments structure given the configuration and arguments
  static Status construct_arguments_(
    OperatorArguments &operator_args,
    GemmPlanarComplexArrayConfiguration const *configuration) {

    operator_args.mode = cutlass::gemm::GemmUniversalMode::kArray;
    operator_args.problem_size = configuration->problem_size;
    operator_args.batch_count = configuration->batch_count;

    operator_args.lda_real = int(configuration->lda_real);
    operator_args.lda_imag = int(configuration->lda_imag);
    operator_args.ldb_real = int(configuration->ldb_real);
    operator_args.ldb_imag = int(configuration->ldb_imag);
    operator_args.ldc_real = int(configuration->ldc_real);
    operator_args.ldc_imag = int(configuration->ldc_imag);
    operator_args.ldd_real = int(configuration->ldd_real);
    operator_args.ldd_imag = int(configuration->ldd_imag);

    return Status::kSuccess;
  }

  /// Constructs the arguments structure given the configuration and arguments
  static Status update_arguments_(
    OperatorArguments &operator_args,
    GemmPlanarComplexArrayArguments const *arguments) {
    
    if (arguments->pointer_mode == ScalarPointerMode::kHost) {
      typename Operator::EpilogueOutputOp::Params params(
        *static_cast<cutlass::complex<ElementCompute> const *>(arguments->alpha),
        *static_cast<cutlass::complex<ElementCompute> const *>(arguments->beta)
      );
      operator_args.epilogue = params;
    }
    else if (arguments->pointer_mode == ScalarPointerMode::kDevice){
      typename Operator::EpilogueOutputOp::Params params(
        static_cast<cutlass::complex<ElementCompute> const *>(arguments->alpha),
        static_cast<cutlass::complex<ElementCompute> const *>(arguments->beta)
      );
      operator_args.epilogue = params; 
    }
    else {
      return Status::kErrorInvalidProblem;
    }

    // update arguments
    operator_args.ptr_A_real = arguments->A_real;
    operator_args.ptr_A_imag = arguments->A_imag;
    operator_args.ptr_B_real = arguments->B_real;
    operator_args.ptr_B_imag = arguments->B_imag;
    operator_args.ptr_C_real = arguments->C_real;
    operator_args.ptr_C_imag = arguments->C_imag;
    operator_args.ptr_D_real = arguments->D_real;
    operator_args.ptr_D_imag = arguments->D_imag;

    operator_args.ptr_M = arguments->M;
    operator_args.ptr_N = arguments->N;
    operator_args.ptr_K = arguments->K;
    
    return Status::kSuccess;
  }

public:

  /// Returns success if the operation can proceed
  virtual Status can_implement(
    void const *configuration_ptr, 
    void const *arguments_ptr) const {
    
    GemmPlanarComplexArrayConfiguration const *configuration = 
      static_cast<GemmPlanarComplexArrayConfiguration const *>(configuration_ptr);

    GemmPlanarComplexArrayArguments const *arguments = 
      static_cast<GemmPlanarComplexArrayArguments const *>(arguments_ptr);

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
      static_cast<GemmPlanarComplexArrayConfiguration const *>(configuration_ptr));

    if (status != Status::kSuccess) {
      return 0;
    }

    uint64_t size = Operator::get_workspace_size(args);

    return size;
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
      static_cast<GemmPlanarComplexArrayConfiguration const *>(configuration_ptr));

    if (status != Status::kSuccess) {
      return status;
    }

    Operator *op = new (host_workspace) Operator;

    status = op->initialize(args, device_workspace, stream);
    
    return status;
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
      static_cast<GemmPlanarComplexArrayArguments const *>(arguments_ptr));

    if (status != Status::kSuccess) {
      return status;
    }
    
    Operator *op = static_cast<Operator *>(host_workspace);
    
    status = op->update(args, device_workspace);

    if (status != Status::kSuccess) {
      return status;
    }
    
    status = op->run(stream);
    
    return status;
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace library
} // namespace cutlass

///////////////////////////////////////////////////////////////////////////////////////////////////
