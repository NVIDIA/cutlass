/***************************************************************************************************
 * Copyright (c) 2025 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include <bitset>
#include <cstdint>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

#include <cuda_runtime_api.h>

#include "cutlass/cutlass.h"
#include "cutlass/profiler/grouped_gemm_operation_profiler.h"
#include "cutlass/library/handle.h"
#include "cutlass/library/library.h"
/////////////////////////////////////////////////////////////////////////////////////////////////

namespace {
std::vector<std::vector<int>> parseProblemSizes(std::string const& input) {
  // input must be of the form:
  //  `[m0xn0xk0][m1xn1xk1]` where 0, 1 are the group indexes
  std::stringstream ss(input);
  std::string token;
  std::vector<std::vector<int>> result;
  while (std::getline(ss, token, ']')) {
    std::stringstream ss(token);
    std::string token;
    ss.get(); // discard '['
    std::getline(ss, token, 'x');
    auto m = std::stoi(token);
    std::getline(ss, token, 'x');
    auto n = std::stoi(token);
    std::getline(ss, token);
    auto k = std::stoi(token);
    result.push_back({m, n, k});
  }
  return result;
}
} // namespace

namespace cutlass {
namespace profiler {

GroupedGemmOperationProfiler::GroupedGemmOperationProfiler(Options const& options)
    : OperationProfiler(
        options,
        library::OperationKind::kGroupedGemm,
        {{ArgumentTypeID::kEnumerated,
          {"gemm_kind"},
          "Variant of GEMM (universal, gemm, planar_complex, planar_complex_array)"},
         {ArgumentTypeID::kInteger,
          {"m", "problem-size::m"},
          "M dimension of the GEMM problem space (for all groups)"},
         {ArgumentTypeID::kInteger,
          {"n", "problem-size::n"},
          "N dimension of the GEMM problem space (for all groups)"},
         {ArgumentTypeID::kInteger,
          {"k", "problem-size::k"},
          "K dimension of the GEMM problem space (for all groups)"},
         {ArgumentTypeID::kInteger,
          {"num_groups"},
          "If m,n,k are specified, run a grouped GEMM with this number of groups, where each GEMM "
          "uses the same m,n,k values."},
         {ArgumentTypeID::kTensor, {"A"}, "Tensor storing the A operand"},
         {ArgumentTypeID::kTensor, {"B"}, "Tensor storing the B operand"},
         {ArgumentTypeID::kTensor, {"C"}, "Tensor storing the C operand"},
         {ArgumentTypeID::kTensor, {"D"}, "Tensor storing the D output"},
         {ArgumentTypeID::kScalar,
          {"alpha", "epilogue::alpha"},
          "Epilogue scalar alpha (applied to all GEMMs in group)."},
         {ArgumentTypeID::kScalar,
          {"beta", "epilogue::beta"},
          "Epilogue scalar beta (applied to all GEMMs in group)."},
         {ArgumentTypeID::kScalar,
          {"problem-sizes"},
          "MxNxK Problem sizes for the grouped GEMM, where a group is enclosed by `[]`. E.g. "
          "--problem-sizes='[m1xn1xk1][m2xn2xk2]'"},
         {ArgumentTypeID::kScalar,
          {"problem-sizes-file"},
          "File containing grouped GEMM problem sizes, where each line represents a group whose "
          "GEMM dimensions are 'mxnxk'."}},
        {library::Provider::kReferenceDevice}) {

  description_ = "      Grouped matrix-matrix product. D[g] = alpha[g] * A[g] * B[g] + beta[g] * "
                 "C[g] for g in [0, num_groups)";
}

GroupedGemmOperationProfiler::~GroupedGemmOperationProfiler() {}

void GroupedGemmOperationProfiler::print_usage(std::ostream& out) const {
  OperationProfiler::print_usage(out);
}

void GroupedGemmOperationProfiler::print_examples(std::ostream& out) const {

  out
    << "\nExamples:\n\n"
    << "Profile a particular problem size (explicit shapes):\n"
    << "  $ cutlass_profiler --operation=GroupedGemm --problem-sizes='[1024x1024x128][16x8x8]'\n\n"

    << "Profile a particular problem size (same M, N, K for all groups):\n"
    << "  $ cutlass_profiler --operation=GroupedGemm --m=16 --n=32 --k=64 --num_groups=8'\n\n"

    << "Profile a particular problem size from a file:\n"
    << "  $ cutlass_profiler --operation=GroupedGemm --problem-sizes-file=shapes.txt\n\n"

    << "Schmoo over problem size and beta:\n"
    << "  $ cutlass_profiler --operation=GroupedGemm --problem-sizes='[8x8x8],[16x8x16][32x32x32]' "
       "--beta=0,1,2.5\n\n"

    << "Schmoo over accumulator types:\n"
    << "  $ cutlass_profiler --operation=GroupedGemm --accumulator-type=f16,f32\n\n"

    << "Run when A is f16 with column-major and B is any datatype with row-major (For column "
       "major, use column, col, or n. For row major use, row or t):\n"
    << "  $ cutlass_profiler --operation=GroupedGemm --A=f16:column --B=*:row\n\n"

    << "Using various input value distribution:\n"
    << "  $ cutlass_profiler --operation=GroupedGemm --dist=uniform,min:0,max:3\n"
    << "  $ cutlass_profiler --operation=GroupedGemm --dist=gaussian,mean:0,stddev:3\n"
    << "  $ cutlass_profiler --operation=GroupedGemm --dist=sequential,start:0,delta:1\n\n"

    << "Test your changes to gemm kernels with a quick functional test and save results in "
       "functional-test.csv:\n"
    << " $ cutlass_profiler  --operation=Gemm \\ \n"
    << "   --problem-sizes='[8x8x8][5x10x5],[16x8x16][32x32x32]' \\ \n"
    << "   --beta=0,1,2 --profiling-iterations=1 \\ \n"
    << "   --providers=cutlass --output=functional-test.csv\n\n";
}

Status GroupedGemmOperationProfiler::GroupedGemmProblem::parse(
  library::GemmDescription const& operation_desc,
  ProblemSpace const& problem_space,
  ProblemSpace::Problem const& problem) {

  this->mode = library::GemmUniversalMode::kGrouped;

  std::bitset<3> args_exist;
  std::string problem_sizes_str;
  args_exist[0] = arg_as_string(problem_sizes_str, "problem-sizes", problem_space, problem);
  int m, n, k;
  args_exist[1] = arg_as_int(m, "m", problem_space, problem) &&
                  arg_as_int(n, "n", problem_space, problem) &&
                  arg_as_int(k, "k", problem_space, problem);
  std::string problem_file;
  args_exist[2] = arg_as_string(problem_file, "problem-sizes-file", problem_space, problem);

  if (args_exist.count() == 0) {
    int num_groups = 8;
    problem_sizes.resize(num_groups);
    problem_sizes_3x.resize(num_groups);
    int m0 = 16;
    int n0 = 32;
    int k0 = 64;
    for (int i = 0; i < num_groups; i++) {
      auto m = m0 * (i + 1);
      auto n = n0 * (i + 1);
      auto k = k0 * (i + 1);
      problem_sizes[i] = {m, n, k};
      problem_sizes_3x[i] = {m, n, k};
    }
  }
  else if (args_exist.count() > 1) {
    std::cerr
      << "Exactly one of --problem-sizes, --problem-sizes-file, or --m --n --k may be specified.\n";
    return Status::kErrorInvalidProblem;
  }
  // --problem-sizes path
  else if (args_exist[0]) {
    auto problems = parseProblemSizes(problem_sizes_str);
    auto num_groups = problems.size();
    problem_sizes.resize(num_groups);
    problem_sizes_3x.resize(num_groups);
    for (size_t i = 0; i < num_groups; i++) {
      auto m = problems[i][0];
      auto n = problems[i][1];
      auto k = problems[i][2];
      problem_sizes[i] = {m, n, k};
      problem_sizes_3x[i] = {m, n, k};
    }
  }
  // m, n, k path
  else if (args_exist[1]) {
    int num_groups;
    if (!arg_as_int(num_groups, "num_groups", problem_space, problem)) {
      std::cerr << "num_groups must be specified if --m --n and --k are set.\n";
      return Status::kErrorInvalidProblem;
    }
    problem_sizes.resize(num_groups);
    problem_sizes_3x.resize(num_groups);
    for (int i = 0; i < num_groups; i++) {
      problem_sizes[i] = {m, n, k};
      problem_sizes_3x[i] = {m, n, k};
    }
  }
  // --problem-sizes-file path
  else if (args_exist[2]) {
    std::ifstream file(problem_file);
    if (!file.good()) {
      throw std::runtime_error("Failed to open file: " + problem_file);
    }

    for (std::string line; std::getline(file, line);) {
      std::istringstream iss(line);

      int m, n, k;
      char sep1, sep2;
      std::string remaining;

      if (iss >> m >> sep1 >> n >> sep2 >> k && sep1 == 'x' && sep2 == 'x' && !(iss >> remaining)) {
        problem_sizes.emplace_back(m, n, k);
        problem_sizes_3x.emplace_back(m, n, k);
      } else {
        throw std::runtime_error(
          "Invalid format in line: " + line + ". Each line in file expected to be 'mxnxk'.");
      }
    }
  }

  if (!arg_as_int(this->cluster_m, "cluster_m", problem_space, problem)) {
    // default value
    this->cluster_m = 1;
  }

  if (!arg_as_int(this->cluster_n, "cluster_n", problem_space, problem)) {
    // default value
    this->cluster_n = 1;
  }

  if (!arg_as_int(this->cluster_k, "cluster_k", problem_space, problem)) {
    // default value
    this->cluster_k = 1;
  }

  if (!arg_as_int(this->cluster_m_fallback, "cluster_m_fallback", problem_space, problem)) {
    // default value
    this->cluster_m_fallback = 0;
  }

  if (!arg_as_int(this->cluster_n_fallback, "cluster_n_fallback", problem_space, problem)) {
    // default value
    this->cluster_n_fallback = 0;
  }

  if (!arg_as_int(this->cluster_k_fallback, "cluster_k_fallback", problem_space, problem)) {
    // default value
    this->cluster_k_fallback = 0;
  }

  this->mode = library::GemmUniversalMode::kGrouped;

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

  if (!arg_as_scalar(this->beta, operation_desc.element_epilogue, "beta", problem_space, problem)) {

    if (!cast_from_double(this->beta, operation_desc.element_epilogue, 0)) {
      return Status::kErrorInternal;
    }
  }

  auto num_groups = problem_sizes.size();
  this->lda.resize(num_groups);
  this->ldb.resize(num_groups);
  this->ldc.resize(num_groups);
  for (size_t group_idx = 0; group_idx < num_groups; group_idx++) {
    this->lda[group_idx] = DeviceAllocation::get_packed_layout(
                             operation_desc.A.layout,
                             {int(this->m(group_idx)), int(this->k(group_idx))})
                             .front();

    this->ldb[group_idx] = DeviceAllocation::get_packed_layout(
                             operation_desc.B.layout,
                             {int(this->k(group_idx)), int(this->n(group_idx))})
                             .front();

    this->ldc[group_idx] = DeviceAllocation::get_packed_layout(
                             operation_desc.C.layout,
                             {int(this->m(group_idx)), int(this->n(group_idx))})
                             .front();
  }

  return Status::kSuccess;
}

/// Total number of bytes loaded
int64_t GroupedGemmOperationProfiler::GroupedGemmProblem::bytes(
  library::GemmDescription const& operation_desc) const {
  // Input bytes read and Output bytes written for the gemm problem
  int64_t bytes = 0;
  for (size_t group_idx = 0, num_groups = problem_sizes.size(); group_idx < num_groups;
       group_idx++) {

    bytes +=
      int64_t(library::sizeof_bits(operation_desc.A.element) * m(group_idx) / 8) * k(group_idx) +
      int64_t(library::sizeof_bits(operation_desc.B.element) * n(group_idx) / 8) * k(group_idx) +
      int64_t(library::sizeof_bits(operation_desc.C.element) * m(group_idx) / 8) * n(group_idx);

    // Set is_beta_zero true if beta is zero
    bool is_beta_zero = std::all_of(beta.begin(), beta.end(), [](uint8_t i) { return i == 0; });
    // Output bytes read for the gemm problem for non-zero beta values
    if (!is_beta_zero) {
      bytes +=
        int64_t(library::sizeof_bits(operation_desc.C.element) * m(group_idx) / 8) * n(group_idx);
    }
  }

  return bytes;
}

/// Total number of flops computed
int64_t GroupedGemmOperationProfiler::GroupedGemmProblem::flops(
  library::GemmDescription const& operation_desc) const {
  int64_t flops_ = 0;
  for (size_t group_idx = 0, num_groups = problem_sizes.size(); group_idx < num_groups;
       group_idx++) {
    flops_ +=
      (int64_t(m(group_idx)) * n(group_idx) * k(group_idx) + m(group_idx) * n(group_idx)) * 2;
  }

  // complex-valued support
  switch (operation_desc.tile_description.math_instruction.math_operation) {
  case library::MathOperationID::kMultiplyAddComplex:
  case library::MathOperationID::kMultiplyAddComplexFastF32:
    flops_ *= 4;
    break;
  case library::MathOperationID::kMultiplyAddGaussianComplex:
    flops_ *= 3;
    break;

  default:
    break;
  }

  return flops_;
}

/// Initializes a performance result
void GroupedGemmOperationProfiler::GroupedGemmProblem::initialize_result(
  PerformanceResult& result,
  library::GemmDescription const& operation_desc,
  ProblemSpace const& problem_space) {

  result.arguments.resize(problem_space.rank());

  set_argument(result, "gemm_kind", problem_space, library::to_string(operation_desc.gemm_kind));

  set_argument(
    result,
    "A",
    problem_space,
    std::string(library::to_string(operation_desc.A.element)) + ":" +
      library::to_string(operation_desc.A.layout));

  set_argument(
    result,
    "B",
    problem_space,
    std::string(library::to_string(operation_desc.B.element)) + ":" +
      library::to_string(operation_desc.B.layout));

  set_argument(
    result,
    "C",
    problem_space,
    std::string(library::to_string(operation_desc.C.element)) + ":" +
      library::to_string(operation_desc.C.layout));

  set_argument(
    result,
    "D",
    problem_space,
    std::string(library::to_string(operation_desc.D.element)) + ":" +
      library::to_string(operation_desc.D.layout));

  {
    std::stringstream ss;
    ss << "'";
    for (auto const& problem_size : problem_sizes) {
      ss << "[";
      auto m = problem_size[0];
      auto n = problem_size[1];
      auto k = problem_size[2];
      ss << m << "x" << n << "x" << k;
      ss << "]";
    }
    ss << "'";
    set_argument(result, "problem-sizes", problem_space, ss.str());
  }

  set_argument(result, "cluster_m", problem_space, cluster_m);
  set_argument(result, "cluster_n", problem_space, cluster_n);
  set_argument(result, "cluster_k", problem_space, cluster_k);
  set_argument(result, "cluster_m_fallback", problem_space, cluster_m_fallback);
  set_argument(result, "cluster_n_fallback", problem_space, cluster_n_fallback);
  set_argument(result, "cluster_k_fallback", problem_space, cluster_k_fallback);

  set_argument(
    result,
    "alpha",
    problem_space,
    library::lexical_cast(alpha, operation_desc.element_epilogue));

  set_argument(
    result,
    "beta",
    problem_space,
    library::lexical_cast(beta, operation_desc.element_epilogue));
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Extracts the problem dimensions
Status GroupedGemmOperationProfiler::initialize_configuration(
  Options const& options,
  PerformanceReport& report,
  DeviceContext& device_context,
  library::Operation const* operation,
  ProblemSpace const& problem_space,
  ProblemSpace::Problem const& problem) {

  library::GemmDescription const& operation_desc =
    static_cast<library::GemmDescription const&>(operation->description());

  if (operation_desc.gemm_kind != library::GemmKind::kGrouped) {
    return Status::kErrorInvalidProblem;
  }

  Status status = problem_.parse(operation_desc, problem_space, problem);
  if (status != Status::kSuccess) {
    return status;
  }

  auto num_groups = problem_.problem_sizes.size();
  gemm_workspace_.configuration.problem_count = num_groups;
  gemm_workspace_.configuration.lda = problem_.lda.data();
  gemm_workspace_.configuration.ldb = problem_.ldb.data();
  gemm_workspace_.configuration.ldc = problem_.ldc.data();

  initialize_result_(this->model_result_, options, operation_desc, problem_space);

  return status;
}

/// Initializes the performance result
void GroupedGemmOperationProfiler::initialize_result_(
  PerformanceResult& result,
  Options const& options,
  library::GemmDescription const& operation_desc,
  ProblemSpace const& problem_space) {

  result.provider = library::Provider::kCUTLASS;
  result.disposition = Disposition::kNotRun;
  result.status = Status::kSuccess;
  result.operation_name = operation_desc.name;

  problem_.initialize_result(result, operation_desc, problem_space);

  OperationProfiler::initialize_result_(result, operation_desc, problem_space);

  result.bytes = problem_.bytes(operation_desc);
  result.flops = problem_.flops(operation_desc);
  result.runtime = 0;

}

/// Initializes workspace
Status GroupedGemmOperationProfiler::initialize_workspace(
  Options const& options,
  PerformanceReport& report,
  DeviceContext& device_context,
  library::Operation const* operation,
  ProblemSpace const& problem_space,
  ProblemSpace::Problem const& problem) {

  if (options.device.devices.size() != 1) {
    throw std::runtime_error("This operation profiler only supports a single "
                             "device.");
  }

  cudaError_t result;
  result = cudaSetDevice(options.device.device_id(0));
  if (result != cudaSuccess) {
    throw std::runtime_error("cudaSetDevice() failed.");
  }

  library::Operation const* underlying_operation = operation;
  library::GemmDescription const& operation_desc =
    static_cast<library::GemmDescription const&>(operation->description());

  // Compute the number of copies of the problem to avoid L2 camping.
  if (!options.profiling.workspace_count) {
    int64_t bytes = problem_.bytes(operation_desc);
    if (bytes < 3 * int64_t(options.device.properties[0].l2CacheSize)) {
      gemm_workspace_.problem_count =
        1 + int((3 * int64_t(options.device.properties[0].l2CacheSize)) / bytes);
    }
    else {
      gemm_workspace_.problem_count = 1;
    }
  }
  else {
    gemm_workspace_.problem_count = options.profiling.workspace_count;
  }

  bool allocate_device_tensors = options.execution_mode != ExecutionMode::kDryRun;
  if (allocate_device_tensors) {
    size_t num_groups = problem_.problem_sizes.size();
    // input data
    gemm_workspace_.A_ptr_array_host.resize(num_groups);
    gemm_workspace_.B_ptr_array_host.resize(num_groups);
    gemm_workspace_.C_ptr_array_host.resize(num_groups);
    gemm_workspace_.D_ptr_array_host.resize(num_groups);
    static_assert(sizeof(void*) == 8); // allocating blocks for pointers, so verify pointer size
    // ldx
    gemm_workspace_.lda_array_device =
      device_context
        .allocate_block(options, "lda_array", library::NumericTypeID::kS64, num_groups, 0);
    gemm_workspace_.ldb_array_device =
      device_context
        .allocate_block(options, "ldb_array", library::NumericTypeID::kS64, num_groups, 0);
    gemm_workspace_.ldc_array_device =
      device_context
        .allocate_block(options, "ldc_array", library::NumericTypeID::kS64, num_groups, 0);
    gemm_workspace_.lda_array_device->copy_from_host(problem_.lda.data());
    gemm_workspace_.ldb_array_device->copy_from_host(problem_.ldb.data());
    gemm_workspace_.ldc_array_device->copy_from_host(problem_.ldc.data());
    // problem sizes
    gemm_workspace_.problem_sizes_array_device = device_context.allocate_block(
      options,
      "problem_sizes_array",
      library::NumericTypeID::kU8,
      num_groups * sizeof(gemm::GemmCoord),
      0);
    gemm_workspace_.problem_sizes_array_device->copy_from_host(problem_.problem_sizes.data());

    gemm_workspace_.problem_sizes_3x_array_device = device_context.allocate_block(
      options,
      "problem_sizes_array_3x",
      library::NumericTypeID::kU8,
      num_groups * sizeof(cute::Shape<int, int, int>),
      0);
    gemm_workspace_.problem_sizes_3x_array_device->copy_from_host(problem_.problem_sizes_3x.data());

    // reference
    gemm_workspace_.reference_ptr_array_host.resize(num_groups);

    int seed_shift = 0;
    for (size_t group_idx = 0; group_idx < num_groups; group_idx++) {
      auto group_str = std::to_string(group_idx);
      gemm_workspace_.A_ptr_array_host[group_idx] = device_context.allocate_and_initialize_tensor(
        options,
        "A_" + group_str,
        operation_desc.A.element,
        operation_desc.A.layout,
        {int(problem_.m(group_idx)), int(problem_.k(group_idx))},
        {int(problem_.lda[group_idx])},
        gemm_workspace_.problem_count,
        seed_shift++,
        0);
      gemm_workspace_.B_ptr_array_host[group_idx] = device_context.allocate_and_initialize_tensor(
        options,
        "B_" + group_str,
        operation_desc.B.element,
        operation_desc.B.layout,
        {int(problem_.k(group_idx)), int(problem_.n(group_idx))},
        {int(problem_.ldb[group_idx])},
        gemm_workspace_.problem_count,
        seed_shift++,
        0);
      gemm_workspace_.C_ptr_array_host[group_idx] = device_context.allocate_and_initialize_tensor(
        options,
        "C_" + group_str,
        operation_desc.C.element,
        operation_desc.C.layout,
        {int(problem_.m(group_idx)), int(problem_.n(group_idx))},
        {int(problem_.ldc[group_idx])},
        gemm_workspace_.problem_count,
        seed_shift++,
        0);
      gemm_workspace_.D_ptr_array_host[group_idx] = device_context.allocate_tensor(
        options,
        "D_" + group_str,
        operation_desc.D.element,
        operation_desc.D.layout,
        {int(problem_.m(group_idx)), int(problem_.n(group_idx))},
        {int(problem_.ldc[group_idx])},
        gemm_workspace_.problem_count,
        0);

      gemm_workspace_.reference_ptr_array_host[group_idx] = device_context.allocate_tensor(
        options,
        "Reference_" + group_str,
        operation_desc.D.element,
        operation_desc.D.layout,
        {int(problem_.m(group_idx)), int(problem_.n(group_idx))},
        {int(problem_.ldc[group_idx])},
        gemm_workspace_.problem_count,
        0);
    }

    // takes the allocated tensors and initializes an array of pointers per problem in the workspace
    auto create_dev_ptr_array_all_workspace = [&](
                                                std::vector<DeviceAllocation*>& dev_ptr_arrays,
                                                std::vector<DeviceAllocation*> const& input,
                                                std::string const& id) {
      auto num_workspaces = gemm_workspace_.problem_count;
      dev_ptr_arrays.resize(num_workspaces);
      // note "problem_count" here refers to input/output count for L2 cycling
      for (int i = 0; i < gemm_workspace_.problem_count; i++) {
        std::string name = id + "_ptr_array_workspace" + std::to_string(i);
        dev_ptr_arrays[i] =
          device_context.allocate_block(options, name, library::NumericTypeID::kU64, num_groups, 0);
        std::vector<void*> group_ptrs(num_groups);
        for (size_t group_idx = 0; group_idx < num_groups; group_idx++) {
          group_ptrs[group_idx] = input[group_idx]->batch_data(i);
        }
        dev_ptr_arrays[i]->copy_from_host(group_ptrs.data());
      }
    };
    create_dev_ptr_array_all_workspace(
      gemm_workspace_.A_ptr_array_device,
      gemm_workspace_.A_ptr_array_host,
      "A");
    create_dev_ptr_array_all_workspace(
      gemm_workspace_.B_ptr_array_device,
      gemm_workspace_.B_ptr_array_host,
      "B");
    create_dev_ptr_array_all_workspace(
      gemm_workspace_.C_ptr_array_device,
      gemm_workspace_.C_ptr_array_host,
      "C");
    create_dev_ptr_array_all_workspace(
      gemm_workspace_.D_ptr_array_device,
      gemm_workspace_.D_ptr_array_host,
      "D");
  }
  init_arguments(options);

  //
  // Initialize the CUTLASS operation
  //
  Status status = Status::kSuccess;
  if (options.profiling.provider_enabled(library::Provider::kCUTLASS)) {
    if (options.execution_mode != ExecutionMode::kDryRun) {
      uint64_t workspace_size =
        underlying_operation->get_host_workspace_size(&gemm_workspace_.configuration);
      gemm_workspace_.host_workspace.resize(workspace_size, 0);

      workspace_size = underlying_operation->get_device_workspace_size(
        &gemm_workspace_.configuration,
        &gemm_workspace_.arguments);
      gemm_workspace_.device_workspace.reset(library::NumericTypeID::kU8, workspace_size);

      status = underlying_operation->initialize(
        &gemm_workspace_.configuration,
        gemm_workspace_.host_workspace.data(),
        gemm_workspace_.device_workspace.data());
      if (status != Status::kSuccess) {
        return status;
      }

      status = underlying_operation->can_implement(
        &gemm_workspace_.configuration,
        &gemm_workspace_.arguments);
      if (status != Status::kSuccess) {
        return status;
      }
    }

    //
    // If CUTLASS is enabled, generate a result for it
    //
    results_.push_back(model_result_);
    results_.back().provider = library::Provider::kCUTLASS;
    results_.back().op_kind = library::OperationKind::kGroupedGemm;
    results_.back().disposition = Disposition::kNotRun;

    for (auto provider : verification_providers_) {
      results_.back().verification_map[provider] = Disposition::kNotRun;
    }
  }
  return status;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Verifies CUTLASS against references
bool GroupedGemmOperationProfiler::verify_cutlass(
  Options const& options,
  PerformanceReport& report,
  DeviceContext& device_context,
  library::Operation const* operation,
  ProblemSpace const& problem_space,
  ProblemSpace::Problem const& problem) {

  if (!options.profiling.provider_enabled(library::Provider::kCUTLASS)) {
    return true;
  }

  if (options.execution_mode == ExecutionMode::kDryRun) {
    return true;
  }

  init_arguments(options);

  library::Operation const* underlying_operation = operation;
  results_.back().status = underlying_operation->run(
    &gemm_workspace_.arguments,
    gemm_workspace_.host_workspace.data(),
    gemm_workspace_.device_workspace.data());

  if (results_.back().status != Status::kSuccess) {
    results_.back().disposition = Disposition::kFailed;
    throw "failed";
    return false;
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
      // set verification map for cublas to not supported
      results_.back().verification_map[library::Provider::kCUBLAS] = Disposition::kNotSupported;
    }
#endif // #if CUTLASS_ENABLE_CUBLAS

    library::GemmDescription const& gemm_desc =
      static_cast<library::GemmDescription const&>(operation->description());

    bool verification_status = verify_with_reference_(
      options,
      report,
      device_context,
      operation,
      problem_space,
      problem,
      gemm_desc.A.element,
      gemm_desc.B.element);

    // Update disposition to worst case verification outcome among all
    // verification providers which are supported
    bool is_any_verification_run_passed = false;
    for (auto& m : results_.back().verification_map) {
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
      did_any_verification_run |=
        (Disposition::kNotRun != results_.back().verification_map[provider]);
    }

    if (not did_any_verification_run) {
      results_.back().status = Status::kErrorNotSupported;
      return false;
    }
  }

  // Return true means continue profiling
  return true;
}

/// Verifies CUTLASS against host and device references
bool GroupedGemmOperationProfiler::verify_with_reference_(
  Options const& options,
  PerformanceReport& report,
  DeviceContext& device_context,
  library::Operation const* operation,
  ProblemSpace const& problem_space,
  ProblemSpace::Problem const& problem,
  cutlass::library::NumericTypeID element_A,
  cutlass::library::NumericTypeID element_B) {
  library::GemmDescription const& gemm_desc =
    static_cast<library::GemmDescription const&>(operation->description());

  for (auto provider : options.verification.providers) {

    // Skip providers that are not enabled
    if (!options.verification.provider_enabled(provider)) {
      continue;
    }

    auto status = Status::kSuccess;
    auto disposition = Disposition::kFailed;
    for (size_t group_idx = 0, num_groups = problem_.problem_sizes.size(); group_idx < num_groups;
         group_idx++) {
      void* ptr_A = gemm_workspace_.A_ptr_array_host[group_idx]->data();
      void* ptr_B = gemm_workspace_.B_ptr_array_host[group_idx]->data();
      void* ptr_C = gemm_workspace_.C_ptr_array_host[group_idx]->data();
      void* ptr_D = gemm_workspace_.reference_ptr_array_host[group_idx]->data();

      // To support the host-side reference, conditionally allocate and
      // copy tensors to host memory.
      std::vector<uint8_t> host_data_A;
      std::vector<uint8_t> host_data_B;
      std::vector<uint8_t> host_data_C;
      std::vector<uint8_t> host_data_D;

      if (provider == library::Provider::kReferenceHost) {
        host_data_A.resize(gemm_workspace_.A_ptr_array_host[group_idx]->bytes());
        ptr_A = host_data_A.data();
        gemm_workspace_.A_ptr_array_host[group_idx]->copy_to_host(
          ptr_A); // this is copying all the data for L2 busting as well

        host_data_B.resize(gemm_workspace_.B_ptr_array_host[group_idx]->bytes());
        ptr_B = host_data_B.data();
        gemm_workspace_.B_ptr_array_host[group_idx]->copy_to_host(ptr_B);

        host_data_C.resize(gemm_workspace_.C_ptr_array_host[group_idx]->bytes());
        ptr_C = host_data_C.data();
        gemm_workspace_.C_ptr_array_host[group_idx]->copy_to_host(ptr_C);

        host_data_D.resize(gemm_workspace_.reference_ptr_array_host[group_idx]->bytes());
        ptr_D = host_data_D.data();
      }

      library::Handle handle;
      handle.set_provider(provider);

      status = handle.gemm_universal(
        library::GemmUniversalMode::kGemm,
        problem_.m(group_idx),
        problem_.n(group_idx),
        problem_.k(group_idx),
        problem_.cluster_m,
        problem_.cluster_n,
        problem_.cluster_k,
        problem_.cluster_m_fallback,
        problem_.cluster_n_fallback,
        problem_.cluster_k_fallback,
        gemm_desc.tile_description.math_instruction.element_accumulator,
        gemm_desc.element_epilogue,
        problem_.alpha.data(),
        element_A,
        gemm_desc.A.layout,
        gemm_desc.transform_A,
        ptr_A,
        int(problem_.lda[group_idx]),
        element_B,
        gemm_desc.B.layout,
        gemm_desc.transform_B,
        ptr_B,
        int(problem_.ldb[group_idx]),
        problem_.beta.data(),
        gemm_desc.C.element,
        gemm_desc.C.layout,
        ptr_C,
        int(problem_.ldc[group_idx]),
        gemm_desc.D.element,
        gemm_desc.D.layout,
        ptr_D,
        int(problem_.ldc[group_idx]),
        1,
        gemm_workspace_.A_ptr_array_host[group_idx]->batch_stride(),
        gemm_workspace_.B_ptr_array_host[group_idx]->batch_stride(),
        gemm_workspace_.C_ptr_array_host[group_idx]->batch_stride(),
        gemm_workspace_.reference_ptr_array_host[group_idx]->batch_stride());

      if (status != Status::kSuccess)
        break;

      if (provider == library::Provider::kReferenceHost) {
        gemm_workspace_.reference_ptr_array_host[group_idx]->copy_from_host(ptr_D);
      }

      disposition = compare_tensors(
        options,
        *gemm_workspace_.D_ptr_array_host[group_idx],
        *gemm_workspace_.reference_ptr_array_host[group_idx],
        gemm_workspace_.D_ptr_array_host[group_idx]->batch_stride());
      if (disposition != Disposition::kPassed)
        break;
    }
    if (status != Status::kSuccess) {
      results_.back().verification_map[provider] = Disposition::kNotRun;
      continue;
    }
    results_.back().status = status;
    results_.back().verification_map[provider] = disposition;

    // Save workspace if incorrect
    if (
      options.verification.save_workspace == SaveWorkspace::kIncorrect &&
      results_.back().verification_map[provider] == Disposition::kIncorrect) {

      save_workspace(device_context, options, gemm_desc, library::Provider::kCUTLASS, provider);
    }
  }

  return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Measures performance results
bool GroupedGemmOperationProfiler::profile(
  Options const& options,
  PerformanceReport& report,
  DeviceContext& device_context,
  library::Operation const* operation,
  ProblemSpace const& problem_space,
  ProblemSpace::Problem const& problem) {

  if (options.profiling.provider_enabled(library::Provider::kCUTLASS)) {
    results_.back().status = profile_cutlass_(
      results_.back(),
      options,
      operation,
      &gemm_workspace_.arguments,
      gemm_workspace_.host_workspace.data(),
      gemm_workspace_.device_workspace.data());
  }
  return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Method to profile a CUTLASS Operation
Status GroupedGemmOperationProfiler::profile_cutlass_(
  PerformanceResult& result,
  Options const& options,
  library::Operation const* operation,
  void* arguments,
  void* host_workspace,
  void* device_workspace) {

  // initialize gemm underlying operation to handle parallel reduction
  library::Operation const* underlying_operation = operation;

  auto func = [&](cudaStream_t stream, int iteration) {
    // Iterate over copies of the problem in memory
    int workspace_idx = options.profiling.warmup_iterations + iteration;
    int problem_idx = (workspace_idx % gemm_workspace_.problem_count);

    gemm_workspace_.arguments.ptr_A = gemm_workspace_.A_ptr_array_device[problem_idx]->data();
    gemm_workspace_.arguments.ptr_B = gemm_workspace_.B_ptr_array_device[problem_idx]->data();
    gemm_workspace_.arguments.ptr_C = gemm_workspace_.C_ptr_array_device[problem_idx]->data();
    gemm_workspace_.arguments.ptr_D = gemm_workspace_.D_ptr_array_device[problem_idx]->data();

    return underlying_operation->run(arguments, host_workspace, device_workspace);
  };
  return profile_kernel_(result, options, func);
}

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace profiler
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
