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
/* \file
   \brief Execution environment
*/

#include <iostream>
#include <stdexcept>
#include <iomanip>
#include <ios>
#include <vector>

#include "cutlass/core_io.h"
#include <cuda_runtime_api.h>
#include <cuda/atomic>

#include "cutlass/profiler/cublas_helpers.h"
#include "cutlass/profiler/gemm_operation_profiler.h"
#include "cutlass/profiler/gpu_timer.h"
#include "cutlass/library/singleton.h"
#include "cutlass/library/library.h"
#include "cutlass/library/handle.h"
/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace profiler {


/////////////////////////////////////////////////////////////////////////////////////////////////

/// Ctor
GemmOperationProfiler::GemmOperationProfiler(Options const &options):
  OperationProfiler(
    options,
    library::OperationKind::kGemm,
    {
      {ArgumentTypeID::kEnumerated, {"gemm_kind"}, "Variant of GEMM (universal, gemm, planar_complex, planar_complex_array)"},
      {ArgumentTypeID::kInteger, {"m", "problem-size::m"}, "M dimension of the GEMM problem space"},
      {ArgumentTypeID::kInteger, {"n", "problem-size::n"}, "N dimension of the GEMM problem space"},
      {ArgumentTypeID::kInteger, {"k", "problem-size::k"}, "K dimension of the GEMM problem space"},
      {ArgumentTypeID::kTensor, {"A"}, "Tensor storing the A operand"},
      {ArgumentTypeID::kTensor, {"B"}, "Tensor storing the B operand"},
      {ArgumentTypeID::kTensor, {"C"}, "Tensor storing the C operand"},
      {ArgumentTypeID::kTensor, {"D"}, "Tensor storing the D output"},
      {ArgumentTypeID::kScalar, {"alpha", "epilogue::alpha"}, "Epilogue scalar alpha"},
      {ArgumentTypeID::kScalar, {"beta", "epilogue::beta"}, "Epilogue scalar beta"},
      {ArgumentTypeID::kEnumerated, {"split_k_mode", "split-k-mode"}, "Variant of split K mode(serial, parallel)"},
      {ArgumentTypeID::kInteger, {"split_k_slices", "split-k-slices"}, "Number of partitions of K dimension"},
      {ArgumentTypeID::kInteger, {"batch_count", "batch-count"}, "Number of GEMMs computed in one batch"},
      {ArgumentTypeID::kEnumerated, {"raster_order", "raster-order"}, "Raster order (heuristic, along_n, along_m)"},
      {ArgumentTypeID::kInteger, {"swizzle_size", "swizzle-size"}, "Size to swizzle"},
    },
    { library::Provider::kCUBLAS}
  ) {

  description_ = "      General matrix-matrix product. D = alpha * A*B + beta * C";
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

    << "Profile a particular problem size with split K and parallel reduction:\n"
    << "  $ cutlass_profiler --operation=Gemm --split_k_mode=parallel --split_k_slices=2 --m=1024 --n=1024 --k=128\n\n"

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

/////////////////////////////////////////////////////////////////////////////////////////////////

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

Status GemmOperationProfiler::GemmProblem::parse(
  library::GemmDescription const &operation_desc,
  ProblemSpace const &problem_space,
  ProblemSpace::Problem const &problem) {

  this->mode = library::GemmUniversalMode::kGemm;

  if (!arg_as_int(this->m, "m", problem_space, problem)) {
    // default value
    this->m = 1024;
  }

  if (!arg_as_int(this->n, "n", problem_space, problem)) {
    // default value
    this->n = 1024;
  }

  if (!arg_as_int(this->k, "k", problem_space, problem)) {
    // default value
    this->k = 1024;
  }

  if (!arg_as_SplitKModeID(this->split_k_mode, "split_k_mode", problem_space, problem)) {
    // default value
    this->split_k_mode = library::SplitKMode::kSerial;
  }

  this->mode = library::GemmUniversalMode::kGemm;
  if (this->split_k_mode == library::SplitKMode::kParallel) {
    this->mode = library::GemmUniversalMode::kGemmSplitKParallel;
  }

  if (!arg_as_int(this->split_k_slices, "split_k_slices", problem_space, problem)) {
    // default value
    this->split_k_slices = 1;
  }

  if (!arg_as_int(this->batch_count, "batch_count", problem_space, problem)) {
    // default value
    this->batch_count = 1;
  } else if (this->batch_count > 1) {
    this->mode = library::GemmUniversalMode::kBatched;
  }

  if (!arg_as_int(this->swizzle_size, "swizzle_size", problem_space, problem)) {
    // default value
    this->swizzle_size = 1;
  }

  if (!arg_as_RasterOrder(this->raster_order, "raster_order", problem_space, problem)) {
    // default value
    this->raster_order = library::RasterOrder::kHeuristic;
  }

  if (this->split_k_slices > 1 && this->batch_count > 1) {
    // At least one of these must be one
    return Status::kErrorInvalidProblem;
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

  if (!tensor_description_satisfies(operation_desc.D, "D", problem_space, problem)) {
    return Status::kErrorInvalidProblem;
  }

  if (!arg_as_scalar(
    this->alpha,
    operation_desc.element_epilogue,
    "alpha",
    problem_space,
    problem)) {

    if (!cast_from_double(this->alpha, operation_desc.element_epilogue, 1)) {
      return Status::kErrorInternal;
    }
  }

  if (!arg_as_scalar(
    this->beta,
    operation_desc.element_epilogue,
    "beta",
    problem_space,
    problem)) {

    if (!cast_from_double(this->beta, operation_desc.element_epilogue, 0)) {
      return Status::kErrorInternal;
    }
  }

  this->lda = DeviceAllocation::get_packed_layout(
    operation_desc.A.layout, {int(this->m), int(this->k)}).front();

  this->ldb = DeviceAllocation::get_packed_layout(
    operation_desc.B.layout, {int(this->k), int(this->n)}).front();

  this->ldc = DeviceAllocation::get_packed_layout(
    operation_desc.C.layout, {int(this->m), int(this->n)}).front();

  return Status::kSuccess;
}

/// Total number of bytes loaded
int64_t GemmOperationProfiler::GemmProblem::bytes(library::GemmDescription const &operation_desc) const {
  // Input bytes read and Output bytes written for the gemm problem
  int64_t bytes =
    int64_t(library::sizeof_bits(operation_desc.A.element) * m / 8) * k +
    int64_t(library::sizeof_bits(operation_desc.B.element) * n / 8) * k +
    int64_t(library::sizeof_bits(operation_desc.C.element) * m / 8) * n;

  // Set is_beta_zero true if beta is zero
  bool is_beta_zero = std::all_of(beta.begin(), beta.end(), [](uint8_t i) { return i==0; });

  // Output bytes read for the gemm problem for non-zero beta values
  if (!is_beta_zero) {
    bytes += int64_t(library::sizeof_bits(operation_desc.C.element) * m / 8) * n;
  }

  bytes *= batch_count;

  return bytes;
}

/// Total number of flops computed
int64_t GemmOperationProfiler::GemmProblem::flops(library::GemmDescription const &operation_desc) const {
  int64_t flops_ = (int64_t(m) * n * k + m * n) * 2 * batch_count;

  // complex-valued support
  switch (operation_desc.tile_description.math_instruction.math_operation) {
  case library::MathOperationID::kMultiplyAddComplex:
    flops_ *= 4;
    break;

  case library::MathOperationID::kMultiplyAddComplexFastF32:
    flops_ *= 4;
    break;

  case library::MathOperationID::kMultiplyAddGaussianComplex:
    flops_ *= 3;
    break;

  default: break;
  }

  return flops_;
}


/// Initializes a performance result
void GemmOperationProfiler::GemmProblem::initialize_result(
  PerformanceResult &result,
  library::GemmDescription const &operation_desc,
  ProblemSpace const &problem_space) {

  result.arguments.resize(problem_space.rank());

  set_argument(result, "gemm_kind", problem_space, library::to_string(operation_desc.gemm_kind));

  set_argument(result, "A", problem_space,
    std::string(library::to_string(operation_desc.A.element)) + ":" + library::to_string(operation_desc.A.layout));

  set_argument(result, "B", problem_space,
    std::string(library::to_string(operation_desc.B.element)) + ":" + library::to_string(operation_desc.B.layout));

  set_argument(result, "C", problem_space,
    std::string(library::to_string(operation_desc.C.element)) + ":" + library::to_string(operation_desc.C.layout));

  set_argument(result, "D", problem_space,
    std::string(library::to_string(operation_desc.D.element)) + ":" + library::to_string(operation_desc.D.layout));

  set_argument(result, "m", problem_space, m);
  set_argument(result, "n", problem_space, n);
  set_argument(result, "k", problem_space, k);

  set_argument(result, "split_k_mode", problem_space, library::to_string(split_k_mode));
  set_argument(result, "split_k_slices", problem_space, split_k_slices);
  set_argument(result, "batch_count", problem_space, batch_count);
  set_argument(result, "raster_order", problem_space, library::to_string(raster_order));
  set_argument(result, "swizzle_size", problem_space, swizzle_size);

  set_argument(result, "alpha", problem_space,
    library::lexical_cast(alpha, operation_desc.element_epilogue));

  set_argument(result, "beta", problem_space,
    library::lexical_cast(beta, operation_desc.element_epilogue));
}

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

  if (operation_desc.gemm_kind != library::GemmKind::kUniversal) {
    return Status::kErrorInvalidProblem;
  }

  Status status = problem_.parse(operation_desc, problem_space, problem);

  if (status != Status::kSuccess) {
    return status;
  }

  const auto device_count = options.device.devices.size();

  gemm_workspace_.clear();

  for (size_t i = 0; i < device_count; ++i) {
    cudaSetDevice(options.device.device_id(i));
    gemm_workspace_.emplace_back();
    cudaStreamCreateWithFlags(&gemm_workspace_[i].stream, cudaStreamNonBlocking);
    gemm_workspace_[i].configuration.mode = problem_.mode;
    gemm_workspace_[i].configuration.problem_size.m() = int(problem_.m);
    gemm_workspace_[i].configuration.problem_size.n() = int(problem_.n);
    gemm_workspace_[i].configuration.problem_size.k() = int(problem_.k);
    gemm_workspace_[i].configuration.lda = problem_.lda;
    gemm_workspace_[i].configuration.ldb = problem_.ldb;
    gemm_workspace_[i].configuration.ldc = problem_.ldc;
    gemm_workspace_[i].configuration.ldd = problem_.ldc;

    gemm_workspace_[i].configuration.device_count = static_cast<int>(device_count);
    gemm_workspace_[i].arguments.device_index = static_cast<int>(i);

    if (problem_.mode == library::GemmUniversalMode::kBatched) {
      gemm_workspace_[i].configuration.batch_count = problem_.batch_count;
    }
    else {
      gemm_workspace_[i].configuration.batch_count = problem_.split_k_slices;
    }

    gemm_workspace_[i].arguments.A = nullptr;
    gemm_workspace_[i].arguments.B = nullptr;
    gemm_workspace_[i].arguments.C = nullptr;
    gemm_workspace_[i].arguments.D = nullptr;
    gemm_workspace_[i].arguments.alpha = problem_.alpha.data();
    gemm_workspace_[i].arguments.beta = problem_.beta.data();
    gemm_workspace_[i].arguments.pointer_mode = library::ScalarPointerMode::kHost;
    gemm_workspace_[i].arguments.swizzle_size = problem_.swizzle_size;
    gemm_workspace_[i].arguments.raster_order = problem_.raster_order;
    initialize_result_(this->model_result_, options, operation_desc, problem_space);

    if (const auto can_implement = operation->can_implement(&gemm_workspace_[i].configuration, &gemm_workspace_[i].arguments); can_implement != Status::kSuccess) {
      return can_implement;
    }
  }

  // initialize reduction operation for parallel splitKMode
  if (problem_.split_k_mode == library::SplitKMode::kParallel) {
    if (!initialize_reduction_configuration_(operation, problem)) {
      return Status::kErrorInternal;
    }
  }

  return status;
}

/// Initializes the performance result
void GemmOperationProfiler::initialize_result_(
  PerformanceResult &result,
  Options const &options,
  library::GemmDescription const &operation_desc,
  ProblemSpace const &problem_space) {

  result.provider = library::Provider::kCUTLASS;
  result.disposition = Disposition::kNotRun;
  result.status = Status::kSuccess;
  result.operation_name = operation_desc.name;

  problem_.initialize_result(result, operation_desc, problem_space);

  OperationProfiler::initialize_result_(result, operation_desc, problem_space);

  result.bytes = problem_.bytes(operation_desc);
  result.flops = problem_.flops(operation_desc);
  result.runtime = 0;
  result.runtime_vector.resize(options.device.devices.size(), 0);

}

/// Initialize reduction problem dimensions and library::Operation
bool GemmOperationProfiler::initialize_reduction_configuration_(
  library::Operation const *operation,
  ProblemSpace::Problem const &problem) {

  library::GemmDescription const &gemm_desc =
    static_cast<library::GemmDescription const&>(operation->description());

  if (!cast_from_double(problem_.alpha_one, gemm_desc.element_epilogue, 1)) {
    return false;
  }

  if (!cast_from_double(problem_.beta_zero, gemm_desc.element_epilogue, 0)) {
    return false;
  }

  /// initialize library::ReductionConfiguration
  for (auto &gemm_workspace : gemm_workspace_) {
    gemm_workspace.reduction_configuration.problem_size      = gemm::GemmCoord(int(problem_.n), int(problem_.m), int(problem_.k)).mn();
    gemm_workspace.reduction_configuration.partitions        = int(problem_.split_k_slices);
    gemm_workspace.reduction_configuration.partition_stride  = gemm::GemmCoord(int(problem_.n), int(problem_.m), int(problem_.k)).mn().product();
    gemm_workspace.reduction_configuration.ldw               = problem_.ldc;
    gemm_workspace.reduction_configuration.lds               = problem_.ldc;
    gemm_workspace.reduction_configuration.ldd               = problem_.ldc;
  }

  // find reduction operation
  library::ReductionFunctionalKey reduction_key(
    library::Provider::kCUTLASS,
    gemm_desc.tile_description.math_instruction.element_accumulator,    // element workspace
    gemm_desc.tile_description.math_instruction.element_accumulator,    // element accumulator
    gemm_desc.D.element,                                                // element output
    gemm_desc.element_epilogue                                          // element compute
  );

  auto reduction_it = library::Singleton::get().operation_table.reduction_operations.find(reduction_key);

  if (reduction_it == library::Singleton::get().operation_table.reduction_operations.end()) {
    return false;
  }

  // initialize reduction operation required for parallel split-k operator
  reduction_op_ = reduction_it->second;

  // reduction operation found and initialized
  return true;
}

/// Initializes workspace
Status GemmOperationProfiler::initialize_workspace(
  Options const &options,
  PerformanceReport &report,
  DeviceContext &device_context,
  library::Operation const *operation,
  ProblemSpace const &problem_space,
  ProblemSpace::Problem const &problem) {

  cudaError_t result;
  result = cudaSetDevice(options.device.device_id(0));
  if (result != cudaSuccess) {
    throw std::runtime_error("cudaSetDevice() failed.");
  }

  library::Operation const* underlying_operation = operation;

  if (problem_.split_k_mode == library::SplitKMode::kParallel) {
    if (!(underlying_operation = library::find_gemm_operation_for_parallel_reduction(operation))) {
      return Status::kErrorNotSupported;
    }
  }

  library::GemmDescription const &operation_desc =
    static_cast<library::GemmDescription const &>(operation->description());

  bool is_sparse = operation_desc.tile_description.math_instruction.opcode_class == cutlass::library::OpcodeClassID::kSparseTensorOp;

  for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
    cudaSetDevice(options.device.device_id(i));

    // Compute the number of copies of the problem to avoid L2 camping.
    if (!options.profiling.workspace_count) {
      int64_t bytes = problem_.bytes(operation_desc);
      if (bytes < 3 * int64_t(options.device.properties[0].l2CacheSize)) {
        gemm_workspace_[i].problem_count =
          1 + int((3 * int64_t(options.device.properties[0].l2CacheSize)) / bytes);
      }
      else {
        gemm_workspace_[i].problem_count = 1;
      }
    }
    else {
      gemm_workspace_[i].problem_count = options.profiling.workspace_count;
    }

    bool allocate_device_tensors = options.execution_mode != ExecutionMode::kDryRun;
    if (allocate_device_tensors) {
      int seed_shift = 0;
      gemm_workspace_[i].A = device_context.allocate_and_initialize_tensor(
        options,
        "A",
        operation_desc.A.element,
        operation_desc.A.layout,
        {int(problem_.m), int(problem_.k)},
        {int(problem_.lda)},
        problem_.batch_count * gemm_workspace_[i].problem_count,
        seed_shift++,
        i // device_index
      );

      gemm_workspace_[i].B = device_context.allocate_and_initialize_tensor(
        options,
        "B",
        operation_desc.B.element,
        operation_desc.B.layout,
        {int(problem_.k), int(problem_.n)},
        {int(problem_.ldb)},
        problem_.batch_count * gemm_workspace_[i].problem_count,
        seed_shift++,
        i // device_index
      );

      gemm_workspace_[i].C = device_context.allocate_and_initialize_tensor(
        options,
        "C",
        operation_desc.C.element,
        operation_desc.C.layout,
        {int(problem_.m), int(problem_.n)},
        {int(problem_.ldc)},
        problem_.batch_count * gemm_workspace_[i].problem_count,
        seed_shift++,
        i // device_index
      );

      gemm_workspace_[i].Computed = device_context.allocate_tensor(
        options,
        "D",
        operation_desc.D.element,
        operation_desc.D.layout,
        {int(problem_.m), int(problem_.n)},
        {int(problem_.ldc)},
        problem_.batch_count * gemm_workspace_[i].problem_count,
        i // device_index
      );

      gemm_workspace_[i].Reference = device_context.allocate_tensor(
        options,
        "Reference",
        operation_desc.D.element,
        operation_desc.D.layout,
        {int(problem_.m), int(problem_.n)},
        {int(problem_.ldc)},
        problem_.batch_count * gemm_workspace_[i].problem_count,
        i // device_index
      );
    }

    if (options.execution_mode != ExecutionMode::kDryRun) {
      // NOTE: the leading non-batch strides are duplicated here for 3.0 API kernels
      gemm_workspace_[i].arguments.problem_size = {int(problem_.m), int(problem_.n), int(problem_.k)};
      gemm_workspace_[i].arguments.batch_count = problem_.batch_count;
      gemm_workspace_[i].arguments.lda = problem_.lda;
      gemm_workspace_[i].arguments.ldb = problem_.ldb;
      gemm_workspace_[i].arguments.ldc = problem_.ldc;
      gemm_workspace_[i].arguments.ldd = problem_.ldc;
      gemm_workspace_[i].arguments.batch_stride_A = gemm_workspace_[i].A->batch_stride();
      gemm_workspace_[i].arguments.batch_stride_B = gemm_workspace_[i].B->batch_stride();
      gemm_workspace_[i].arguments.batch_stride_C = gemm_workspace_[i].C->batch_stride();
      gemm_workspace_[i].arguments.batch_stride_D = gemm_workspace_[i].Computed->batch_stride();

      /* Query device SM count to pass onto the kernel as an argument, where needed */
      gemm_workspace_[i].arguments.sm_count = options.device.properties[0].multiProcessorCount;
      gemm_workspace_[i].arguments.device_index = static_cast<int>(i);
    }
  }

  //
  // Initialize the CUTLASS operation
  //
  Status status = Status::kSuccess;

  if (options.profiling.provider_enabled(library::Provider::kCUTLASS)) {

    if (options.execution_mode != ExecutionMode::kDryRun) {
      for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
        cudaSetDevice(options.device.device_id(i));
        uint64_t workspace_size = underlying_operation->get_host_workspace_size(&gemm_workspace_[i].configuration);
        gemm_workspace_[i].host_workspace.resize(workspace_size, 0);

        workspace_size = underlying_operation->get_device_workspace_size(&gemm_workspace_[i].configuration,
                                                              &gemm_workspace_[i].arguments);
        if (is_sparse) {
          // sparse gemm get_device_workspace_size() only return device workspace size per iteration
          // Needs to multiply it w/ number of iteration
          workspace_size *= gemm_workspace_[i].problem_count;
        }
        gemm_workspace_[i].device_workspace.reset(library::NumericTypeID::kU8, workspace_size);

        // Convert to structure sparse contents here.
        if (is_sparse) {
          uint8_t* profiler_workspaces[1];
          profiler_workspaces[0] = reinterpret_cast<uint8_t*>(gemm_workspace_[i].A->data());
          // Sparse operations have a different initialize interface.
          // initialize_with_profiler_workspace converts mxk tensorA to compressed mxk/sp tensorA and the tensorE
          auto modifiable_underlying_op = const_cast<library::Operation*>(underlying_operation);
          status = modifiable_underlying_op->initialize_with_profiler_workspace(
            &gemm_workspace_[i].configuration,
            gemm_workspace_[i].host_workspace.data(),
            gemm_workspace_[i].device_workspace.data(),
            profiler_workspaces,
            gemm_workspace_[i].problem_count,
            gemm_workspace_[i].stream);
        }
        else {
          status = underlying_operation->initialize(
            &gemm_workspace_[i].configuration,
            gemm_workspace_[i].host_workspace.data(),
            gemm_workspace_[i].device_workspace.data(),
            gemm_workspace_[i].stream);
        }

        if (status != Status::kSuccess) {
          return status;
        }

        if (problem_.split_k_mode == library::SplitKMode::kParallel) {
          workspace_size = reduction_op_->get_host_workspace_size(&gemm_workspace_[i].reduction_configuration);
          gemm_workspace_[i].reduction_host_workspace.resize(workspace_size, 0);

          status = reduction_op_->initialize(
            &gemm_workspace_[i].reduction_configuration,
            gemm_workspace_[i].reduction_host_workspace.data(),
            nullptr,
            gemm_workspace_[i].stream);

          if (status != Status::kSuccess) {
            return status;
          }
        }
      }
    }

    for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
      cudaSetDevice(options.device.device_id(i));
      cudaDeviceSynchronize();
    }

    //
    // If CUTLASS is enabled, generate a result for it
    //
    results_.push_back(model_result_);
    results_.back().provider = library::Provider::kCUTLASS;
    results_.back().op_kind = library::OperationKind::kGemm;
    results_.back().disposition = Disposition::kNotRun;

    for (auto provider : verification_providers_) {
      results_.back().verification_map[provider] = Disposition::kNotRun;
    }
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

  if (!options.profiling.provider_enabled(library::Provider::kCUTLASS)) {
    return true;
  }

  if (options.execution_mode == ExecutionMode::kDryRun) {
    return true;
  }

  // Initialize structure containing GEMM arguments
  for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
    gemm_workspace_[i].arguments.A = gemm_workspace_[i].A->data();
    gemm_workspace_[i].arguments.B = gemm_workspace_[i].B->data();
    gemm_workspace_[i].arguments.C = gemm_workspace_[i].C->data();
    gemm_workspace_[i].arguments.D = gemm_workspace_[i].Computed->data();
    gemm_workspace_[i].arguments.alpha = problem_.alpha.data();
    gemm_workspace_[i].arguments.beta = problem_.beta.data();
    gemm_workspace_[i].arguments.pointer_mode = library::ScalarPointerMode::kHost;
    gemm_workspace_[i].arguments.batch_stride_A = gemm_workspace_[i].A->batch_stride();
    gemm_workspace_[i].arguments.batch_stride_B = gemm_workspace_[i].B->batch_stride();
    gemm_workspace_[i].arguments.batch_stride_C = gemm_workspace_[i].C->batch_stride();
    gemm_workspace_[i].arguments.batch_stride_D = gemm_workspace_[i].Computed->batch_stride();

    if (problem_.split_k_mode == library::SplitKMode::kParallel) {
      gemm_workspace_[i].arguments.D                       = gemm_workspace_[i].device_workspace.data();
      gemm_workspace_[i].arguments.alpha                   = problem_.alpha_one.data();
      gemm_workspace_[i].arguments.beta                    = problem_.beta_zero.data();

      gemm_workspace_[i].reduction_arguments.workspace     = gemm_workspace_[i].device_workspace.data();
      gemm_workspace_[i].reduction_arguments.source        = gemm_workspace_[i].C->data();
      gemm_workspace_[i].reduction_arguments.destination   = gemm_workspace_[i].Computed->data();
      gemm_workspace_[i].reduction_arguments.alpha         = problem_.alpha.data();
      gemm_workspace_[i].reduction_arguments.beta          = problem_.beta.data();
      gemm_workspace_[i].reduction_arguments.pointer_mode  = library::ScalarPointerMode::kHost;
    }
  }

  //
  // Run the CUTLASS operation
  //

 // initialize gemm underlying operation to handle parallel reduction
  library::Operation const * underlying_operation = operation;

  if (problem_.split_k_mode == library::SplitKMode::kParallel) {
    if (!(underlying_operation = library::find_gemm_operation_for_parallel_reduction(operation))) {
      results_.back().disposition = Disposition::kFailed;
      return false;
    }
  }

  for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
    cudaSetDevice(options.device.device_id(i));

    results_.back().status = underlying_operation->run(
     &gemm_workspace_[i].arguments,
     gemm_workspace_[i].host_workspace.data(),
     gemm_workspace_[i].device_workspace.data(),
     gemm_workspace_[i].stream);

    if (results_.back().status != Status::kSuccess) {
      results_.back().disposition = Disposition::kFailed;
      return false;
    }

    // Run parallel reduction kernel for parallel split_k_mode
    if (problem_.split_k_mode == library::SplitKMode::kParallel) {
      results_.back().status = reduction_op_->run(
        &gemm_workspace_[i].reduction_arguments,
        gemm_workspace_[i].reduction_host_workspace.data(),
        nullptr,
        gemm_workspace_[i].stream);

      if (results_.back().status != Status::kSuccess) {
        results_.back().disposition = Disposition::kFailed;
        return false;
      }
    }
  }

  cudaError_t result = cudaDeviceSynchronize();
  if (result != cudaSuccess) {
    results_.back().disposition = Disposition::kFailed;
    return false;
  }

  // CUTLASS op ran the but not yet verified against any verification provider
  results_.back().disposition = Disposition::kNotVerified;

  //
  // Run verification providers
  //

  if (options.verification.enabled) {

#if CUTLASS_ENABLE_CUBLAS
    if (options.verification.provider_enabled(library::Provider::kCUBLAS)) {

      // Guard against unsupported cases
      auto const & gemm_desc = static_cast<library::GemmDescription const &>(operation->description());

      if (cublas_satisfies(gemm_desc) == Status::kSuccess) {

        // call cublas verification if supported
        for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
          cudaSetDevice(options.device.device_id(i));
          verify_with_cublas_(
           options,
           report,
           device_context,
           operation,
           problem_space,
           problem,
           gemm_workspace_[i]);
        }
        }

      else {
        // set verification map for cublas to not supported
        results_.back().verification_map[library::Provider::kCUBLAS] = Disposition::kNotSupported;
      }
    }
#endif // #if CUTLASS_ENABLE_CUBLAS

    library::GemmDescription const &gemm_desc =
      static_cast<library::GemmDescription const &>(operation->description());


    cutlass::library::NumericTypeID element_A = gemm_desc.A.element;
    cutlass::library::NumericTypeID element_B = gemm_desc.B.element;
    bool verification_status = verify_with_reference_(options, report, device_context, operation, problem_space, problem, element_A, element_B);

    // Update disposition to worst case verification outcome among all
    // verification providers which are supported
    bool is_any_verification_run_passed = false;
    for (auto &m : results_.back().verification_map) {
      if (m.second == Disposition::kFailed || m.second == Disposition::kIncorrect) {
        results_.back().disposition = m.second;
        return true;
      }
      if (!is_any_verification_run_passed && m.second == Disposition::kPassed) {
        is_any_verification_run_passed = true;
      }
    }

    if (is_any_verification_run_passed) {
      results_.back().disposition = Disposition::kPassed;
    }
  }

  // if verification.required is set, then return success iff at least one ref-check was run
  if (options.verification.required) {
    bool did_any_verification_run = false;
    for (auto provider : options.verification.providers) {
      did_any_verification_run |= (Disposition::kNotRun != results_.back().verification_map[provider]);
    }

    if (not did_any_verification_run) {
      results_.back().status = Status::kErrorNotSupported;
      return false;
    }
  }

  // Return true means continue profiling
  return true;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Verifies CUTLASS against references
bool GemmOperationProfiler::verify_with_cublas_(
  Options const &options,
  PerformanceReport &report,
  DeviceContext &device_context,
  library::Operation const *operation,
  ProblemSpace const &problem_space,
  ProblemSpace::Problem const &problem,
  GemmWorkspace &gemm_workspace_) {

#if CUTLASS_ENABLE_CUBLAS

  library::GemmDescription const &gemm_desc =
    static_cast<library::GemmDescription const &>(operation->description());

  //
  // Construct cuBLAS operators
  //

  CublasLtCreate handle;
  cublasStatus_t status = handle.get_cublaslt_create_status();

  if (status != CUBLAS_STATUS_SUCCESS) {
    results_.back().verification_map[library::Provider::kCUBLAS] = get_cutlass_disposition(status);
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
    gemm_workspace_.arguments.batch_stride_A = gemm_workspace_.A->batch_stride();
    gemm_workspace_.arguments.B = gemm_workspace_.B->data();
    gemm_workspace_.arguments.batch_stride_B = gemm_workspace_.B->batch_stride();
    gemm_workspace_.arguments.C = gemm_workspace_.Reference->data();
    gemm_workspace_.arguments.batch_stride_C = gemm_workspace_.Reference->batch_stride();
    gemm_workspace_.arguments.D = gemm_workspace_.Reference->data();
    gemm_workspace_.arguments.batch_stride_D = gemm_workspace_.Reference->batch_stride();
    gemm_workspace_.arguments.alpha = problem_.alpha.data();
    gemm_workspace_.arguments.beta = problem_.beta.data();
    gemm_workspace_.arguments.pointer_mode = library::ScalarPointerMode::kHost;

    detail::cublasLtGemmExDispatcher gemm_op(
      gemm_desc,
      gemm_workspace_.configuration,
      gemm_workspace_.arguments
    );

    gemm_op.initialize_cublaslt();

    if(!gemm_op.get_cublaslt_algo(handle, AlgorithmMode::kDefault)){
      return true;
    }

    if (gemm_op.status != Status::kSuccess) {
      results_.back().verification_map[library::Provider::kCUBLAS] = Disposition::kNotRun;
      return true;
    }

    status = gemm_op(handle);

    // Handle errors
    if (status != CUBLAS_STATUS_SUCCESS) {
      std::cerr << "cublasLt Verification run failed with status : " << cublasLtGetStatusName(status) << "\n";
      results_.back().verification_map[library::Provider::kCUBLAS] = get_cutlass_disposition(status);
      return true;
    }

    results_.back().status = Status::kSuccess;

    //
    // Verify results
    //

    results_.back().verification_map[library::Provider::kCUBLAS] = compare_tensors(
      options,
      *gemm_workspace_.Computed,
      *gemm_workspace_.Reference,
      gemm_workspace_.Computed->batch_stride()
    );

    // Save workspace if incorrect
    if (options.verification.save_workspace == SaveWorkspace::kIncorrect &&
      results_.back().verification_map[library::Provider::kCUBLAS] == Disposition::kIncorrect) {

      save_workspace(
        device_context,
        options,
        gemm_desc,
        library::Provider::kCUTLASS,
        library::Provider::kCUBLAS);
    }
  }
  catch (...) {
    results_.back().verification_map[library::Provider::kCUBLAS] = Disposition::kFailed;
  }

#endif

  // Return true means continue profiling
  return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Verifies CUTLASS against host and device references
bool GemmOperationProfiler::verify_with_reference_(
  Options const &options,
  PerformanceReport &report,
  DeviceContext &device_context,
  library::Operation const *operation,
  ProblemSpace const &problem_space,
  ProblemSpace::Problem const &problem,
  cutlass::library::NumericTypeID element_A,
  cutlass::library::NumericTypeID element_B)
{
  library::GemmDescription const &gemm_desc =
    static_cast<library::GemmDescription const &>(operation->description());

  //
  // Initialize state
  //

  for (auto provider : options.verification.providers) {

    // Skip providers that are not enabled
    if (!options.verification.provider_enabled(provider)) {
      continue;
    }

    for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
      cudaSetDevice(options.device.device_id(i));

      void *ptr_A = gemm_workspace_[i].A->data();
      void *ptr_B = gemm_workspace_[i].B->data();
      void *ptr_C = gemm_workspace_[i].C->data();
      void *ptr_D = gemm_workspace_[i].Reference->data();

      // To support the host-side reference, conditionally allocate and
      // copy tensors to host memory.
      std::vector<uint8_t> host_data_A;
      std::vector<uint8_t> host_data_B;
      std::vector<uint8_t> host_data_C;
      std::vector<uint8_t> host_data_D;

      if (provider == library::Provider::kReferenceHost) {

        host_data_A.resize(gemm_workspace_[i].A->bytes());
        ptr_A = host_data_A.data();
        gemm_workspace_[i].A->copy_to_host(ptr_A);

        host_data_B.resize(gemm_workspace_[i].B->bytes());
        ptr_B = host_data_B.data();
        gemm_workspace_[i].B->copy_to_host(ptr_B);

        host_data_C.resize(gemm_workspace_[i].C->bytes());
        ptr_C = host_data_C.data();
        gemm_workspace_[i].C->copy_to_host(ptr_C);

        host_data_D.resize(gemm_workspace_[i].Reference->bytes());
        ptr_D = host_data_D.data();
      }

      //
      // Launch
      //

      library::Handle handle;

      handle.set_provider(provider);

      Status status = handle.gemm_universal(
        problem_.mode,
        gemm_workspace_[i].configuration.problem_size.m(),
        gemm_workspace_[i].configuration.problem_size.n(),
        gemm_workspace_[i].configuration.problem_size.k(),
        gemm_desc.tile_description.math_instruction.element_accumulator,
        gemm_desc.element_epilogue,

        problem_.alpha.data(),

        element_A,
        gemm_desc.A.layout,
        gemm_desc.transform_A,
        ptr_A,
        int(gemm_workspace_[i].configuration.lda),

        element_B,
        gemm_desc.B.layout,
        gemm_desc.transform_B,
        ptr_B,
        int(gemm_workspace_[i].configuration.ldb),

        problem_.beta.data(),

        gemm_desc.C.element,
        gemm_desc.C.layout,
        ptr_C,
        int(gemm_workspace_[i].configuration.ldc),

        gemm_desc.D.element,
        gemm_desc.D.layout,
        ptr_D,
        int(gemm_workspace_[i].configuration.ldd),

        gemm_workspace_[i].configuration.batch_count,
        gemm_workspace_[i].A->batch_stride(),
        gemm_workspace_[i].B->batch_stride(),
        gemm_workspace_[i].C->batch_stride(),
        gemm_workspace_[i].Reference->batch_stride());

      if (status != Status::kSuccess) {
        results_.back().verification_map[provider] = Disposition::kNotRun;
        continue;
      }
      results_.back().status = status;

      if (provider == library::Provider::kReferenceHost) {
        gemm_workspace_[i].Reference->copy_from_host(ptr_D);
      }

      //
      // Verify results
      //

      results_.back().verification_map[provider] = compare_tensors(
        options,
        *gemm_workspace_[i].Computed,
        *gemm_workspace_[i].Reference,
        gemm_workspace_[i].Computed->batch_stride()
      );

      // Save workspace if incorrect
      if (options.verification.save_workspace == SaveWorkspace::kIncorrect &&
        results_.back().verification_map[provider] == Disposition::kIncorrect) {

        save_workspace(
          device_context,
          options,
          gemm_desc,
          library::Provider::kCUTLASS,
          provider);
        }
    }
  }

  return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace {
extern "C" {
  __global__ void delay(cuda::atomic<bool> const* release) {
    while (release->load(cuda::memory_order_acquire) != true) {
#if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 700)
      __nanosleep(100);
#endif
    }
  }
}
}

/// Measures performance results
bool GemmOperationProfiler::profile(
  Options const &options,
  PerformanceReport &report,
  DeviceContext &device_context,
  library::Operation const *operation,
  ProblemSpace const &problem_space,
  ProblemSpace::Problem const &problem) {

  if (options.profiling.provider_enabled(library::Provider::kCUTLASS)) {

    for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
      // Initialize structure containing GEMM arguments
      gemm_workspace_[i].arguments.A = gemm_workspace_[i].A->data();
      gemm_workspace_[i].arguments.B = gemm_workspace_[i].B->data();
      gemm_workspace_[i].arguments.C = gemm_workspace_[i].C->data();
      gemm_workspace_[i].arguments.D = gemm_workspace_[i].Computed->data();
      gemm_workspace_[i].arguments.alpha = problem_.alpha.data();
      gemm_workspace_[i].arguments.beta = problem_.beta.data();
      gemm_workspace_[i].arguments.pointer_mode = library::ScalarPointerMode::kHost;
      gemm_workspace_[i].arguments.batch_stride_A = gemm_workspace_[i].A->batch_stride();
      gemm_workspace_[i].arguments.batch_stride_B = gemm_workspace_[i].B->batch_stride();
      gemm_workspace_[i].arguments.batch_stride_C = gemm_workspace_[i].C->batch_stride();
      gemm_workspace_[i].arguments.batch_stride_D = gemm_workspace_[i].Computed->batch_stride();

      if (problem_.split_k_mode == library::SplitKMode::kParallel) {
        gemm_workspace_[i].arguments.D                       = gemm_workspace_[i].device_workspace.data();
        gemm_workspace_[i].arguments.alpha                   = problem_.alpha_one.data();
        gemm_workspace_[i].arguments.beta                    = problem_.beta_zero.data();

        gemm_workspace_[i].reduction_arguments.workspace     = gemm_workspace_[i].device_workspace.data();
        gemm_workspace_[i].reduction_arguments.source        = gemm_workspace_[i].C->data();
        gemm_workspace_[i].reduction_arguments.destination   = gemm_workspace_[i].Computed->data();
        gemm_workspace_[i].reduction_arguments.alpha         = problem_.alpha.data();
        gemm_workspace_[i].reduction_arguments.beta          = problem_.beta.data();
        gemm_workspace_[i].reduction_arguments.pointer_mode  = library::ScalarPointerMode::kHost;
      }
    }

    results_.back().status = profile_cutlass_(
      results_.back(),
      options,
      operation,
      nullptr,
      nullptr,
      nullptr
    );
  }
  return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Method to profile a CUTLASS Operation
Status GemmOperationProfiler::profile_cutlass_(
  PerformanceResult &result,
  Options const &options,
  library::Operation const *operation,
  void *,
  void *,
  void *) {

  cuda::atomic<bool> *release;
  cudaHostAlloc(&release, sizeof(*release), cudaHostAllocPortable);
  release->store(false, cuda::memory_order_release);

  std::vector<GpuTimer> timer;
  for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
    cudaSetDevice(options.device.device_id(i));
    timer.emplace_back();
  }
  // initialize gemm underlying operation to handle parallel reduction
  library::Operation const * underlying_operation = operation;

  if (problem_.split_k_mode == library::SplitKMode::kParallel) {
    if (!(underlying_operation = library::find_gemm_operation_for_parallel_reduction(operation))) {
      return Status::kErrorNotSupported;
    }
  }

  //
  // Optional sleep to limit power consumption and thermals
  //

  sleep(options.profiling.sleep_duration);

  //
  // Warmup loop
  //

  Status status;

  std::vector<cudaGraph_t> graphs;
  graphs.resize(gemm_workspace_.size());
  std::vector<cudaGraphExec_t> graphExecs;
  graphExecs.resize(gemm_workspace_.size());

  for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
    cudaSetDevice(options.device.device_id(i));
    cudaStreamBeginCapture(gemm_workspace_[i].stream, cudaStreamCaptureModeGlobal);
    // Halt execution until all GPUs are ready to precede.
    // It allows the CPU to trigger the GPUs all start at the same time.
    delay<<<1, 1, 0, gemm_workspace_[i].stream>>>(release);
    for (int iteration = 0; iteration < options.profiling.warmup_iterations; ++iteration) {
      int problem_idx = (iteration % gemm_workspace_[i].problem_count) * problem_.batch_count;

      gemm_workspace_[i].arguments.A = gemm_workspace_[i].A->batch_data(problem_idx);
      gemm_workspace_[i].arguments.B = gemm_workspace_[i].B->batch_data(problem_idx);
      gemm_workspace_[i].arguments.C = gemm_workspace_[i].C->batch_data(problem_idx);
      gemm_workspace_[i].arguments.D = gemm_workspace_[i].Computed->batch_data(problem_idx);

      if (problem_.split_k_mode == library::SplitKMode::kParallel) {
        gemm_workspace_[i].arguments.D                     = gemm_workspace_[i].device_workspace.data();

        gemm_workspace_[i].reduction_arguments.workspace   = gemm_workspace_[i].device_workspace.data();
        gemm_workspace_[i].reduction_arguments.source      = gemm_workspace_[i].C->batch_data(problem_idx);
        gemm_workspace_[i].reduction_arguments.destination = gemm_workspace_[i].Computed->batch_data(problem_idx);
      }

      // Execute the CUTLASS operation
      status = underlying_operation->run(
        &gemm_workspace_[i].arguments,
        gemm_workspace_[i].host_workspace.data(),
        gemm_workspace_[i].device_workspace.data(),
        gemm_workspace_[i].stream);

      if (status != Status::kSuccess) {
        return status;
      }

      // Run parallel reduction kernel for parallel split_k_mode
      if (problem_.split_k_mode == library::SplitKMode::kParallel) {
        status = reduction_op_->run(
          &gemm_workspace_[i].reduction_arguments,
          gemm_workspace_[i].reduction_host_workspace.data(),
          nullptr,
          gemm_workspace_[i].stream);

        if (status != Status::kSuccess) {
          return status;
        }
      }
    }

    //
    // Initialize GPU timer
    //

    timer[i].start(gemm_workspace_[i].stream, cudaEventRecordExternal);

    //
    // Profiling loop
    //

    int Iterations = options.profiling.iterations;

    int iteration = 0;

    for (; iteration < Iterations; ++iteration) {
      // Iterate over copies of the problem in memory
      int workspace_idx = options.profiling.warmup_iterations + iteration;
      int problem_idx = (workspace_idx % gemm_workspace_[i].problem_count) * problem_.batch_count;

      gemm_workspace_[i].arguments.A = gemm_workspace_[i].A->batch_data(problem_idx);
      gemm_workspace_[i].arguments.B = gemm_workspace_[i].B->batch_data(problem_idx);
      gemm_workspace_[i].arguments.C = gemm_workspace_[i].C->batch_data(problem_idx);
      gemm_workspace_[i].arguments.D = gemm_workspace_[i].Computed->batch_data(problem_idx);

      if (problem_.split_k_mode == library::SplitKMode::kParallel) {
        gemm_workspace_[i].arguments.D                     = gemm_workspace_[i].device_workspace.data();

        gemm_workspace_[i].reduction_arguments.workspace   = gemm_workspace_[i].device_workspace.data();
        gemm_workspace_[i].reduction_arguments.source      = gemm_workspace_[i].C->batch_data(problem_idx);
        gemm_workspace_[i].reduction_arguments.destination = gemm_workspace_[i].Computed->batch_data(problem_idx);
      }

      status = underlying_operation->run(
        &gemm_workspace_[i].arguments,
        gemm_workspace_[i].host_workspace.data(),
        gemm_workspace_[i].device_workspace.data(),
        gemm_workspace_[i].stream);

      if (status != Status::kSuccess) {
        return status;
      }

      // Run parallel reduction kernel for parallel split_k_mode
      if (problem_.split_k_mode == library::SplitKMode::kParallel) {
        status = reduction_op_->run(
          &gemm_workspace_[i].reduction_arguments,
          gemm_workspace_[i].reduction_host_workspace.data(),
          nullptr,
          gemm_workspace_[i].stream);

        if (status != Status::kSuccess) {
          return status;
        }
      }
    }
    timer[i].stop(gemm_workspace_[i].stream, cudaEventRecordExternal);
    cudaStreamEndCapture(gemm_workspace_[i].stream, &graphs[i]);
    cudaGraphInstantiate(&graphExecs[i], graphs[i], nullptr, nullptr, 0);
  }

  for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
    cudaSetDevice(options.device.device_id(i));
    cudaGraphLaunch(graphExecs[i], gemm_workspace_[i].stream);
  }

  //
  // Wait for completion
  //

  release->store(true, cuda::memory_order_release);

  for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
    cudaSetDevice(options.device.device_id(i));
    cudaStreamSynchronize(gemm_workspace_[i].stream);
  }
  //
  // Update performance result
  //


  result.runtime = 0;
  for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
    cudaSetDevice(options.device.device_id(i));
    result.runtime_vector[i] = timer[i].duration(options.profiling.iterations);
    result.runtime += result.runtime_vector[i];
  }
  result.runtime /= static_cast<double>(gemm_workspace_.size());

  cudaFreeHost(release);

  for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
    cudaSetDevice(options.device.device_id(i));
    cudaGraphExecDestroy(graphExecs[i]);
    cudaGraphDestroy(graphs[i]);
  }

  for (size_t i = 0; i < gemm_workspace_.size(); ++i) {
    cudaSetDevice(options.device.device_id(gemm_workspace_.size() - i - 1));
    timer.pop_back();
  }

  return status;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace profiler
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
