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
   \brief Execution environment
*/

#include <iostream>
#include <stdexcept>
#include <iomanip>
#include <ios>

#include "cublas_helpers.h"
#include "gemm_operation_profiler.h"
#include "gpu_timer.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace profiler {


/////////////////////////////////////////////////////////////////////////////////////////////////

/// Ctor
GemmOperationProfiler::GemmOperationProfiler(): 
  OperationProfiler(library::OperationKind::kGemm,{
  	{ArgumentTypeID::kEnumerated, {"Gemm_kind"}, "Variant of GEMM (e.g. gemm, planar complex, batched, ...)"},
	  {ArgumentTypeID::kInteger, {"m", "problem-size::m"}, "M dimension of the GEMM problem space"},
  	{ArgumentTypeID::kInteger, {"n", "problem-size::n"}, "N dimension of the GEMM problem space"},
	  {ArgumentTypeID::kInteger, {"k", "problem-size::k"}, "K dimension of the GEMM problem space"},
  	{ArgumentTypeID::kTensor, {"A"}, "Tensor storing the A operand"},
	  {ArgumentTypeID::kTensor, {"B"}, "Tensor storing the B operand"},
  	{ArgumentTypeID::kTensor, {"C"}, "Tensor storing the C operand"},
	  {ArgumentTypeID::kScalar, {"alpha", "epilogue::alpha"}, "Epilogue scalar alpha"},
  	{ArgumentTypeID::kScalar, {"beta", "epilogue::beta"}, "Epilogue scalar beta"},
	  {ArgumentTypeID::kInteger, {"split_k_slices"}, "Number of partitions of K dimension"},
  	{ArgumentTypeID::kInteger, {"batch_count"}, "Number of GEMMs computed in one batch"},
  }) {

  description_ = "General matrix-matrix product. D = alpha * A*B + beta * C";
}

/// Destructor
GemmOperationProfiler::~GemmOperationProfiler() {

}

/// Prints usage statement for the math function
void GemmOperationProfiler::print_usage(std::ostream &out) const {
  out << "GEMM" << "\n\n";

  OperationProfiler::print_usage(out);
}

/// Prints examples
void GemmOperationProfiler::print_examples(std::ostream &out) const {

  out << "\nExamples:\n\n"
    << "Profile a particular problem size:\n"
    << "  $ cutlass_profiler --operation=Gemm --m=1024 --n=1024 --k=128\n\n"

    << "Schmoo over problem size and beta:\n"
    << "  $ cutlass_profiler --operation=Gemm --m=1024:4096:256 --n=1024:4096:256 --k=128:8192:128 --beta=0,1,2.5\n\n"

    << "Schmoo over accumulator types:\n"
    << "  $ cutlass_profiler --operation=Gemm --accumulator-type=f16,f32\n\n"

    << "Run when A is f16 with column-major and B is any datatype with row-major (For column major, use column, col, or n. For row major use, row or t):\n"
    << "  $ cutlass_profiler --operation=Gemm --A=f16:column --B=*:row\n\n"

    << "Using various input value distribution:\n"
    << "  $ cutlass_profiler --operation=Gemm --dist=uniform,min:0,max:3\n"
    << "  $ cutlass_profiler --operation=Gemm --dist=gaussian,mean:0,stddev:3\n"
    << "  $ cutlass_profiler --operation=Gemm --dist=sequential,start:0,delta:1\n\n"

    << "Run a kernel with cta tile size of 256x128x32 and save workspace if results are incorrect (note that --cta-tile::k=32 is default cta-tile size):\n"
    << " $ cutlass_profiler --operation=Gemm --cta_m=256 --cta_n=128  --cta_k=32 --save-workspace=incorrect\n\n"
    
    << "Test your changes to gemm kernels with a quick functional test and save results in functional-test.csv:\n"
    << " $ cutlass_profiler  --operation=Gemm \\ \n"
    << "   --m=8,56,120,136,256,264,512,520,1024,1032,4096,8192,16384 \\ \n"
    << "   --n=8,56,120,136,256,264,512,520,1024,1032,4096,8192,16384 \\ \n"
    << "   --k=8,16,32,64,128,256,288,384,504,512,520 \\ \n"
    << "   --beta=0,1,2 --profiling-iterations=1 \\ \n"
    << "   --providers=cutlass --output=functional-test.csv\n\n";
}

#if 0
// used this for debugging
static std::string byte_string(std::vector<uint8_t> const &bytes) {
  std::stringstream ss;

  ss << "0x";

  for (size_t idx = bytes.size(); idx > 0; --idx) {
    ss << std::hex << std::setw(2) << std::setfill('0') << uint32_t(bytes.at(idx - 1));
  }

  return ss.str();
}
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Extracts the problem dimensions
Status GemmOperationProfiler::initialize_configuration(
  Options const &options,  
  PerformanceReport &report,
  DeviceContext &device_context,
  library::Operation const *operation,
  ProblemSpace const &problem_space,
  ProblemSpace::Problem const &problem) {

  library::GemmDescription const &operation_desc = 
    static_cast<library::GemmDescription const &>(operation->description());

  if (operation_desc.gemm_kind != library::GemmKind::kGemm) {
    return Status::kErrorInvalidProblem;
  }


  if (!arg_as_int(problem_.m, "m", problem_space, problem)) {
    // default value
    problem_.m = 1024;
  }

  if (!arg_as_int(problem_.n, "n", problem_space, problem)) {
    // default value
    problem_.n = 1024;
  }
  
  if (!arg_as_int(problem_.k, "k", problem_space, problem)) {
    // default value
    problem_.k = 1024;
  }
  
  if (!arg_as_int(problem_.split_k_slices, "split_k_slices", problem_space, problem)) {
    // default value
    problem_.split_k_slices = 1;
  }
  
  if (!arg_as_int(problem_.batch_count, "batch_count", problem_space, problem)) {
    // default value
    problem_.batch_count = 1;
  }

  if (!tensor_description_satisfies(operation_desc.A, "A", problem_space, problem)) {
    return Status::kErrorInvalidProblem;
  }

  if (!tensor_description_satisfies(operation_desc.B, "B", problem_space, problem)) {
    return Status::kErrorInvalidProblem;
  }

  if (!tensor_description_satisfies(operation_desc.C, "C", problem_space, problem)) {
    return Status::kErrorInvalidProblem;
  }

  if (!arg_as_scalar(
    problem_.alpha, 
    operation_desc.element_epilogue, 
    "alpha", 
    problem_space, 
    problem)) {

    if (!cast_from_double(problem_.alpha, operation_desc.element_epilogue, 1)) {
      return Status::kErrorInternal;
    }
  }
  
  if (!arg_as_scalar(
    problem_.beta, 
    operation_desc.element_epilogue, 
    "beta", 
    problem_space, 
    problem)) {
    
    if (!cast_from_double(problem_.beta, operation_desc.element_epilogue, 0)) {
      return Status::kErrorInternal;
    }
  }

  problem_.lda = DeviceAllocation::get_packed_layout(
    operation_desc.A.layout, {int(problem_.m), int(problem_.k)}).front();

  problem_.ldb = DeviceAllocation::get_packed_layout(
    operation_desc.B.layout, {int(problem_.k), int(problem_.n)}).front();

  problem_.ldc = DeviceAllocation::get_packed_layout(
    operation_desc.C.layout, {int(problem_.m), int(problem_.n)}).front();

  gemm_workspace_.configuration.problem_size.m() = int(problem_.m);
  gemm_workspace_.configuration.problem_size.n() = int(problem_.n);
  gemm_workspace_.configuration.problem_size.k() = int(problem_.k);
  gemm_workspace_.configuration.lda = problem_.lda;
  gemm_workspace_.configuration.ldb = problem_.ldb;
  gemm_workspace_.configuration.ldc = problem_.ldc;
  gemm_workspace_.configuration.ldd = problem_.ldc;
  gemm_workspace_.configuration.split_k_slices = int(problem_.split_k_slices);

  gemm_workspace_.arguments.A = nullptr;
  gemm_workspace_.arguments.B = nullptr;
  gemm_workspace_.arguments.C = nullptr;
  gemm_workspace_.arguments.D = nullptr;
  gemm_workspace_.arguments.alpha = problem_.alpha.data();
  gemm_workspace_.arguments.beta = problem_.beta.data();
  gemm_workspace_.arguments.pointer_mode = library::ScalarPointerMode::kHost;

  initialize_result_(this->model_result_, options, operation_desc, problem_space);
  
  return operation->can_implement(&gemm_workspace_.configuration, &gemm_workspace_.arguments);
}

/// Initializes the performance result
void GemmOperationProfiler::initialize_result_(
  PerformanceResult &result,
  Options const &options,  
  library::GemmDescription const &operation_desc,
  ProblemSpace const &problem_space) {

  result.provider = Provider::kCUTLASS;
  result.disposition = Disposition::kNotRun;
  result.status = Status::kSuccess;
  result.operation_name = operation_desc.name;

  result.arguments.resize(problem_space.rank());

  set_argument_(result, "A", problem_space,
    std::string(library::to_string(operation_desc.A.element)) + ":" + library::to_string(operation_desc.A.layout));

  set_argument_(result, "B", problem_space,
    std::string(library::to_string(operation_desc.B.element)) + ":" + library::to_string(operation_desc.B.layout));

  set_argument_(result, "C", problem_space,
    std::string(library::to_string(operation_desc.C.element)) + ":" + library::to_string(operation_desc.C.layout));

  set_argument_(result, "m", problem_space, problem_.m);
  set_argument_(result, "n", problem_space, problem_.n);
  set_argument_(result, "k", problem_space, problem_.k);

  set_argument_(result, "split_k_slices", problem_space, problem_.split_k_slices);
  set_argument_(result, "batch_count", problem_space, problem_.batch_count);

  set_argument_(result, "alpha", problem_space,
    library::lexical_cast(problem_.alpha, operation_desc.element_epilogue));

  set_argument_(result, "beta", problem_space,
    library::lexical_cast(problem_.beta, operation_desc.element_epilogue));

  OperationProfiler::initialize_result_(result, operation_desc, problem_space);

  result.bytes = 
    int64_t(library::sizeof_bits(operation_desc.A.element) * problem_.m / 8) * problem_.k + 
    int64_t(library::sizeof_bits(operation_desc.B.element) * problem_.n / 8) * problem_.k +
    int64_t(library::sizeof_bits(operation_desc.C.element) * problem_.m / 8) * problem_.n * 2;

  result.flops = 2 * (problem_.m * problem_.n * problem_.k + problem_.m * problem_.n);

  result.runtime = 0;

}

/// Initializes workspace
Status GemmOperationProfiler::initialize_workspace(
  Options const &options,  
  PerformanceReport &report,
  DeviceContext &device_context,
  library::Operation const *operation,
  ProblemSpace const &problem_space,
  ProblemSpace::Problem const &problem) {

  library::GemmDescription const &operation_desc = 
    static_cast<library::GemmDescription const &>(operation->description());

  if (options.execution_mode != ExecutionMode::kDryRun) {

    gemm_workspace_.A = device_context.allocate_tensor(
      options,
      "A",
      operation_desc.A.element,
      operation_desc.A.layout,
      {int(problem_.m), int(problem_.k)},
      {int(problem_.lda)}
    );

    gemm_workspace_.B = device_context.allocate_tensor(
      options,
      "B",
      operation_desc.B.element,
      operation_desc.B.layout,
      {int(problem_.k), int(problem_.n)},
      {int(problem_.ldb)}
    );

    gemm_workspace_.C = device_context.allocate_tensor(
      options,
      "C",
      operation_desc.C.element,
      operation_desc.C.layout,
      {int(problem_.m), int(problem_.n)},
      {int(problem_.ldc)}
    );

    gemm_workspace_.Computed = device_context.allocate_tensor(
      "D",
      operation_desc.C.element,
      operation_desc.C.layout,
      {int(problem_.m), int(problem_.n)},
      {int(problem_.ldc)}
    );

    gemm_workspace_.Reference = device_context.allocate_tensor(
      "Reference",
      operation_desc.C.element,
      operation_desc.C.layout,
      {int(problem_.m), int(problem_.n)},
      {int(problem_.ldc)}
    );

    gemm_workspace_.Reference->copy_from_device(gemm_workspace_.C->data());
  }


  //
  // Initialize the CUTLASS operation
  //
  Status status = Status::kSuccess;

  if (options.profiling.provider_enabled(Provider::kCUTLASS)) {

    if (options.execution_mode != ExecutionMode::kDryRun) {

      uint64_t workspace_size = operation->get_host_workspace_size(&gemm_workspace_.configuration);
      gemm_workspace_.host_workspace.resize(workspace_size, 0);

      workspace_size = operation->get_device_workspace_size(&gemm_workspace_.configuration);
      gemm_workspace_.device_workspace.reset(library::NumericTypeID::kU8, workspace_size);

      status = operation->initialize(
        &gemm_workspace_.configuration,
        gemm_workspace_.host_workspace.data(),
        gemm_workspace_.device_workspace.data());
    }

    //
    // If CUTLASS is enabled, generate a result for it
    //
    results_.push_back(model_result_);
    results_.back().provider = Provider::kCUTLASS;
    results_.back().disposition = Disposition::kNotRun;
  }

  return status;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Verifies CUTLASS against references
bool GemmOperationProfiler::verify_cutlass(
  Options const &options,  
  PerformanceReport &report,
  DeviceContext &device_context,
  library::Operation const *operation,
  ProblemSpace const &problem_space,
  ProblemSpace::Problem const &problem) {

  if (!options.profiling.provider_enabled(Provider::kCUTLASS)) {
    return true;
  }

  if (options.execution_mode == ExecutionMode::kDryRun) {
    return true;
  }

  // Initialize structure containing GEMM arguments
  gemm_workspace_.arguments.A = gemm_workspace_.A->data();
  gemm_workspace_.arguments.B = gemm_workspace_.B->data();
  gemm_workspace_.arguments.C = gemm_workspace_.C->data();
  gemm_workspace_.arguments.D = gemm_workspace_.Computed->data();
  gemm_workspace_.arguments.alpha = problem_.alpha.data();
  gemm_workspace_.arguments.beta = problem_.beta.data();
  gemm_workspace_.arguments.pointer_mode = library::ScalarPointerMode::kHost;

  //
  // Run the CUTLASS operation
  //

  results_.back().status = operation->run(
    &gemm_workspace_.arguments, 
    gemm_workspace_.host_workspace.data(),
    gemm_workspace_.device_workspace.data());

  if (results_.back().status != Status::kSuccess) {
    results_.back().disposition = Disposition::kFailed;
    return false;
  }

  cudaError_t result = cudaDeviceSynchronize();
  if (result != cudaSuccess) {
    results_.back().disposition = Disposition::kFailed;
    return false;
  }

  results_.back().disposition = Disposition::kNotVerified;

  if (options.verification.enabled) {

#if CUTLASS_ENABLE_CUBLAS
    if (options.verification.provider_enabled(Provider::kCUBLAS)) {

      // Guard against unsupported cases
      auto const & gemm_desc = static_cast<library::GemmDescription const &>(operation->description());

      if (cublas_satisfies(gemm_desc) != Status::kSuccess) {
        return true;
      }

      return verify_with_cublas_(
        options,
        report,
        device_context,
        operation,
        problem_space,
        problem);
    }
#endif // #if CUTLASS_ENABLE_CUBLAS
    
  }

  return true;
}


/////////////////////////////////////////////////////////////////////////////////////////////////

#if CUTLASS_ENABLE_CUBLAS

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

/// Selects one or more cuBLAS algorithms.
static void select_cublas_algorithms(
  std::vector<cublasGemmAlgo_t> &algorithms,
  Options const &options, 
  library::GemmDescription const &op_desc) {

  library::OpcodeClassID const & opcode_class = 
    op_desc.tile_description.math_instruction.opcode_class;

  switch (options.library.algorithm_mode) {
    case AlgorithmMode::kMatching:
    {
      algorithms.push_back(get_cublas_gemm_algo(
        op_desc.tile_description.threadblock_shape.m(), 
        op_desc.tile_description.threadblock_shape.n(), 
        op_desc.tile_description.threadblock_shape.k(), 
        opcode_class));
      break;
    }

    case AlgorithmMode::kBest:
    {
      // Choose first enumerated mode. If none are enumerated, choose based on opcode class
      // and evaluate all of them.

      if (options.library.algorithms.empty()) {
        // Enumerate all algorithms
        if (opcode_class == library::OpcodeClassID::kSimt) {
          
          for (int algo = CUBLAS_GEMM_DEFAULT; 
            algo <= CUBLAS_GEMM_ALGO23; 
            ++algo) {

            algorithms.push_back(cublasGemmAlgo_t(algo));
          }
        }
        else {
          
          for (int algo = CUBLAS_GEMM_DEFAULT_TENSOR_OP; 
            algo <= CUBLAS_GEMM_ALGO15_TENSOR_OP; 
            ++algo) {

            algorithms.push_back(cublasGemmAlgo_t(algo));
          }
        }
      }
      else {
        // Use the listed algorithms
        algorithms.reserve(options.library.algorithms.size());

        for (int algo : options.library.algorithms) {
          algorithms.push_back(reinterpret_cast<cublasGemmAlgo_t const &>(algo));
        }
      }

      break;
    }

    case AlgorithmMode::kDefault:
    {

      // Use the library's default algorithm
      algorithms.push_back((opcode_class == library::OpcodeClassID::kSimt ? 
        CUBLAS_GEMM_DEFAULT : CUBLAS_GEMM_DEFAULT_TENSOR_OP)); 

      break;
    }
    default:
    {
      break;
    }
  }
}

/// Dispatcher to cublasGemmEx() 
struct cublasGemmExDispatcher {

  //
  // Data members
  //
  library::GemmConfiguration configuration;
  library::GemmArguments arguments;

  cublasOperation_t trans_A;
  cublasOperation_t trans_B;
  cudaDataType_t data_type_A;
  cudaDataType_t data_type_B;
  cudaDataType_t data_type_C;
  cudaDataType_t compute_type;
  cublasGemmAlgo_t algo;
  Status status;
  
  //
  // Methods
  //

  cublasGemmExDispatcher( 
    library::GemmDescription const &op_desc,
    library::GemmConfiguration configuration_,
    library::GemmArguments arguments_,
    cublasGemmAlgo_t algorithm = CUBLAS_GEMM_DFALT
  ):
    configuration(configuration_), arguments(arguments_), algo(algorithm), status(Status::kSuccess) {

    trans_A = get_cublas_transpose_operation(op_desc.A.layout);
    trans_B = get_cublas_transpose_operation(op_desc.B.layout);

    bool good = true;
    good = (good && get_cublas_datatype(data_type_A, op_desc.A.element));
    good = (good && get_cublas_datatype(data_type_B, op_desc.B.element));
    good = (good && get_cublas_datatype(data_type_C, op_desc.C.element));

    good = (good && get_cublas_datatype(
      compute_type, 
      op_desc.tile_description.math_instruction.element_accumulator));

    if (!good) {
      status = Status::kErrorNotSupported;
    }
  }

  /// Executes GEMM using these arguments
  cublasStatus_t operator()(cublasHandle_t handle) {

    return cublasGemmEx(
      handle,
      trans_A,
      trans_B,
      configuration.problem_size.m(),
      configuration.problem_size.n(),
      configuration.problem_size.k(),
      arguments.alpha,
      arguments.A,
      data_type_A,
      int(configuration.lda),
      arguments.B,
      data_type_B,
      int(configuration.ldb),
      arguments.beta,
      arguments.D,
      data_type_C,
      int(configuration.ldc),
      compute_type,
      algo
    );
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace detail

#endif // CUTLASS_ENABLE_CUBLAS

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Verifies CUTLASS against references
bool GemmOperationProfiler::verify_with_cublas_(
  Options const &options,  
  PerformanceReport &report,
  DeviceContext &device_context,
  library::Operation const *operation,
  ProblemSpace const &problem_space,
  ProblemSpace::Problem const &problem) {


#if CUTLASS_ENABLE_CUBLAS

  library::GemmDescription const &gemm_desc = 
    static_cast<library::GemmDescription const &>(operation->description());

  CublasCreate handle;
  cublasStatus_t status = handle.get_cublas_create_status();

  if (status != CUBLAS_STATUS_SUCCESS) {

    results_.back().status = get_cutlass_status(status);
    results_.back().disposition = Disposition::kFailed;
    
    return true;
  }

  std::vector<cublasGemmAlgo_t> algorithms;

  detail::select_cublas_algorithms(
    algorithms, 
    options, 
    gemm_desc);

  if (algorithms.empty()) {
    // no algorithm selected
    return true;
  }

  //
  // Initialize state
  //

  try {

    //
    // Construct dispatcher to cublasGemmEx()
    //

    // Initialize structure containing GEMM arguments
    gemm_workspace_.arguments.A = gemm_workspace_.A->data();
    gemm_workspace_.arguments.B = gemm_workspace_.B->data();
    gemm_workspace_.arguments.C = gemm_workspace_.Reference->data();
    gemm_workspace_.arguments.D = gemm_workspace_.Reference->data();
    gemm_workspace_.arguments.alpha = problem_.alpha.data();
    gemm_workspace_.arguments.beta = problem_.beta.data();
    gemm_workspace_.arguments.pointer_mode = library::ScalarPointerMode::kHost;

    detail::cublasGemmExDispatcher gemm_op( 
      gemm_desc, 
      gemm_workspace_.configuration,
      gemm_workspace_.arguments,
      algorithms.front()
    );

    if (gemm_op.status != Status::kSuccess) {
      results_.back().disposition = Disposition::kNotVerified;
      return true;
    }

    results_.back().status = Status::kSuccess;

    status = gemm_op(handle);

    // Handle errors
    if (status != CUBLAS_STATUS_SUCCESS) {
      results_.back().status = get_cutlass_status(status);
      results_.back().disposition = Disposition::kNotVerified;
      return true;
    }

    //
    // Verify results
    //

    results_.back().disposition = compare_tensors(
      options,
      *gemm_workspace_.Computed,
      *gemm_workspace_.Reference
    );

    // Save workspace if incorrect
    if (options.verification.save_workspace == SaveWorkspace::kIncorrect && 
      results_.back().disposition == Disposition::kIncorrect) {

      save_workspace(
        device_context,
        options,
        gemm_desc,
        Provider::kCUTLASS,
        Provider::kCUBLAS);
    }
  }
  catch (...) {
    results_.back().disposition = Disposition::kFailed;
    results_.back().status = Status::kErrorNotSupported;
  }

#endif

  // Return true means continue profiling
  return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Measures performance results
bool GemmOperationProfiler::profile(
  Options const &options,  
  PerformanceReport &report,
  DeviceContext &device_context,
  library::Operation const *operation,
  ProblemSpace const &problem_space,
  ProblemSpace::Problem const &problem) {

  if (options.profiling.provider_enabled(Provider::kCUTLASS)) {

    // Initialize structure containing GEMM arguments
    gemm_workspace_.arguments.A = gemm_workspace_.A->data();
    gemm_workspace_.arguments.B = gemm_workspace_.B->data();
    gemm_workspace_.arguments.C = gemm_workspace_.C->data();
    gemm_workspace_.arguments.D = gemm_workspace_.Computed->data();
    gemm_workspace_.arguments.alpha = problem_.alpha.data();
    gemm_workspace_.arguments.beta = problem_.beta.data();
    gemm_workspace_.arguments.pointer_mode = library::ScalarPointerMode::kHost;

    results_.back().status = profile_cutlass_(
      results_.back().runtime,
      options,
      operation,
      &gemm_workspace_.arguments,
      gemm_workspace_.host_workspace.data(),
      gemm_workspace_.device_workspace.data()
    );
  }
  return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace profiler
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
