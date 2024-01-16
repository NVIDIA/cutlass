/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Hopper Grouped GEMM example using CUTLASS 3 APIs for NVIDIA Hopper architecture.

    This example demonstrates an implementation of Grouped GEMM using a TMA + GMMA 
    warp-specialized cooperative kernel.
    For this example all scheduling work is performed on the device.
    The new feature showcased in this example is on-the-fly modification of TMA descriptors
    to move between groups/problem_count (represented by groups).

    To run this example:

      $ ./examples/57_hopper_grouped_gemm/57_hopper_grouped_gemm --m=2048 --n=2048 --k=2048 --groups=10

      The above example command makes all 10 groups to be sized at the given m, n, k sizes. 
      Skipping any of the problem dimensions randomizes it across the different groups.

    To run this example for a set of problems using the benchmark option:

      $ ./examples/57_hopper_grouped_gemm/57_hopper_grouped_gemm --benchmark=./test_benchmark.txt

      Where the test_benchmark.txt may look as such:
        0 256x512x128
        1 256x512x512
        2 512x256x128
        3 256x256x128
        4 256x512x1024
        5 1024x512x128 and so on
*/

#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"
#include "cutlass/tensor_ref.h"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/group_array_problem_shape.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"

#include "cutlass/util/command_line.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/reference/device/gemm.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "cutlass/util/reference/device/tensor_fill.h"

#include "helper.h"

using namespace cute;
using ProblemShape = cutlass::gemm::GroupProblemShape<Shape<int,int,int>>; // <M,N,K> per group
using ElementA = cutlass::float_e4m3_t;                          // Element type for A matrix operand
using ElementB = cutlass::float_e5m2_t;                          // Element type for B matrix operand
using ElementC = float;                                          // Element type for C and D matrix operands

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM kernel configurations
/////////////////////////////////////////////////////////////////////////////////////////////////

// A matrix configuration
using         LayoutA     = cutlass::layout::RowMajor;                      // Layout type for A matrix operand
constexpr int AlignmentA  = 128 / cutlass::sizeof_bits<ElementA>::value;    // Memory access granularity/alignment of A matrix in units of elements (up to 16 bytes)

// B matrix configuration
using         LayoutB     = cutlass::layout::ColumnMajor;                   // Layout type for B matrix operand
constexpr int AlignmentB  = 128 / cutlass::sizeof_bits<ElementB>::value;    // Memory access granularity/alignment of B matrix in units of elements (up to 16 bytes)

// C/D matrix configuration
using         LayoutC     = cutlass::layout::ColumnMajor;                   // Layout type for C and D matrix operands
constexpr int AlignmentC  = 128 / cutlass::sizeof_bits<ElementC>::value;    // Memory access granularity/alignment of C matrix in units of elements (up to 16 bytes)

// Core kernel configurations
using ElementAccumulator  = float;                                          // Element type for internal accumulation
using ArchTag             = cutlass::arch::Sm90;                            // Tag indicating the minimum SM that supports the intended feature
using OperatorClass       = cutlass::arch::OpClassTensorOp;                 // Operator class tag
using TileShape           = Shape<_256,_128,_64>;                           // Threadblock-level tile size
using ClusterShape        = Shape<_1,_2,_1>;                                // Shape of the threadblocks in a cluster
using StageCountType = cutlass::gemm::collective::StageCountAuto;           // Stage count maximized based on the tile size
using KernelSchedule = cutlass::gemm::KernelGroupTmaWarpSpecializedCooperativeFP8FastAccum; // Kernel to launch
using EpilogueSchedule = cutlass::epilogue::NoSmemWarpSpecializedGroup;                     // Epilogue to launch

using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
    TileShape, ClusterShape,
    cutlass::epilogue::collective::EpilogueTileAuto,
    ElementAccumulator, ElementAccumulator,
    ElementC, LayoutC, AlignmentC,
    ElementC, LayoutC, AlignmentC,
    EpilogueSchedule
  >::CollectiveOp;

using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    ElementA, LayoutA, AlignmentA,
    ElementB, LayoutB, AlignmentB,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
    KernelSchedule
  >::CollectiveOp;

using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    ProblemShape,
    CollectiveMainloop,
    CollectiveEpilogue
>;

using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

// Reference device GEMM implementation type
using DeviceGemmReference = cutlass::reference::device::Gemm<
  ElementA,
  LayoutA,
  ElementB,
  LayoutB,
  ElementC,
  LayoutC,
  ElementAccumulator,
  ElementAccumulator>;

using StrideA = typename Gemm::GemmKernel::StrideA;
using StrideB = typename Gemm::GemmKernel::StrideB;
using StrideC = typename Gemm::GemmKernel::StrideC;
using StrideD = typename Gemm::GemmKernel::StrideD;

// Host-side allocations
std::vector<int64_t> offset_A;
std::vector<int64_t> offset_B;
std::vector<int64_t> offset_C;
std::vector<int64_t> offset_D;

std::vector<StrideA> stride_A_host;
std::vector<StrideB> stride_B_host;
std::vector<StrideC> stride_C_host;
std::vector<StrideD> stride_D_host;

// Device-side allocations
cutlass::DeviceAllocation<typename ProblemShape::UnderlyingProblemShape> problem_sizes;

cutlass::DeviceAllocation<typename Gemm::ElementA> block_A;
cutlass::DeviceAllocation<typename Gemm::ElementB> block_B;
cutlass::DeviceAllocation<typename Gemm::ElementC> block_C;
cutlass::DeviceAllocation<typename Gemm::EpilogueOutputOp::ElementOutput> block_D;
cutlass::DeviceAllocation<typename Gemm::EpilogueOutputOp::ElementOutput> block_ref_D;

cutlass::DeviceAllocation<const typename Gemm::ElementA *> ptr_A;
cutlass::DeviceAllocation<const typename Gemm::ElementB *> ptr_B;
cutlass::DeviceAllocation<const typename Gemm::ElementC *> ptr_C;
cutlass::DeviceAllocation<typename Gemm::EpilogueOutputOp::ElementOutput *> ptr_D;
cutlass::DeviceAllocation<typename Gemm::EpilogueOutputOp::ElementOutput *> ptr_ref_D;

cutlass::DeviceAllocation<StrideA> stride_A;
cutlass::DeviceAllocation<StrideB> stride_B;
cutlass::DeviceAllocation<StrideC> stride_C;
cutlass::DeviceAllocation<StrideD> stride_D;

#endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Testbed utility types
/////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

  bool help = false;

  float alpha = 1.0f;
  float beta = 0.0f;
  int iterations = 10;
  int m = 1024, n = 2048, k = 512, groups = 10;
  std::string benchmark_path;
  std::vector<typename ProblemShape::UnderlyingProblemShape> problem_sizes_host;
  int const tma_alignment_bits = 128;
  int const alignment = tma_alignment_bits / cutlass::sizeof_bits<ElementA>::value; 

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("m", m);
    cmd.get_cmd_line_argument("n", n);
    cmd.get_cmd_line_argument("k", k);
    cmd.get_cmd_line_argument("groups", groups);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("iterations", iterations);
    cmd.get_cmd_line_argument("benchmark", benchmark_path);

    // Decide how to initialize the problems
    if (!benchmark_path.empty()) {
      if (!benchmark_problems()) {
        problem_sizes_host.clear();
        return;
      }
    }
    else {
      randomize_problems(cmd);
    }
  }

  void randomize_problems(cutlass::CommandLine &cmd) {
    int cmd_line_m = -1;
    int cmd_line_n = -1;
    int cmd_line_k = -1;

    cmd.get_cmd_line_argument("m", cmd_line_m);
    cmd.get_cmd_line_argument("n", cmd_line_n);
    cmd.get_cmd_line_argument("k", cmd_line_k);

    problem_sizes_host.reserve(groups);

    for (int i = groups; i > 0; i--) {

      int m = cmd_line_m;
      int n = cmd_line_n;
      int k = cmd_line_k;

      if (m < 1) {
        m = ((rand() % 512) + 1);
      }

      if (n < 1) {
        n = ((rand() % 512) + 1);
      }

      if (k < 1) {
        k = alignment * ((rand() % 64) + 1);
      }
      problem_sizes_host.push_back({m, n, k});
    }
  }

  /// Load a benchmark
  bool benchmark_problems() {
    std::ifstream file(benchmark_path);
    if (!file.good()) {
      return false;
    }

    while (file.good()) {

      int idx = -1;
      std::string extent_str;

      file >> idx >> extent_str;

      if (idx < 0 || extent_str.empty()) {
        break;
      }

      cutlass::gemm::GemmCoord extent;
      std::vector<std::string> tokens;

      cutlass::CommandLine::tokenize(tokens, extent_str, 'x');

      for (int i = 0; i < int(tokens.size()); ++i) {
        int x = std::atoi(tokens.at(i).c_str());

        // round up
        if (x % alignment) {
          x += (alignment - (x % alignment));
        }

        extent.at(i) = x;
      }

      if (extent.product()) {
        problem_sizes_host.push_back({extent.m(), extent.n(), extent.k()});
      }
    }

    return true;
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "57_hopper_grouped_gemm\n\n"
      << "  Hopper FP8 Grouped GEMM using a Warp Specialized kernel.\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM for all groups\n"
      << "  --n=<int>                   Sets the N extent of the GEMM for all groups\n"
      << "  --k=<int>                   Sets the K extent of the GEMM for all groups\n"
      << "  --groups=<int>              Sets the number of individual GEMM problems for Grouped GEMM\n"
      << "  --alpha=<f32>               Epilogue scalar alpha\n"
      << "  --beta=<f32>                Epilogue scalar beta\n\n"
      << "  --iterations=<int>          Number of profiling iterations to perform\n\n"
      << "  --benchmark=<str>           Executes a benchmark problem size.\n";

    out
      << "\n\nExamples:\n\n"
      << "$ " << "57_hopper_grouped_gemm" << " --m=1024 --n=512 --k=1024 --groups=10 --alpha=2 --beta=0.707 \n\n";

    return out;
  }

  /// Compute performance in GFLOP/s
  double gflops(double runtime_s, std::vector<typename ProblemShape::UnderlyingProblemShape> problem_sizes_host) const
  {
    // Number of real-valued multiply-adds
    uint64_t fmas = uint64_t();

    for (auto const & problem : problem_sizes_host) {
      fmas += cute::size(problem);
    }
    // Two flops per multiply-add
    uint64_t flop = uint64_t(2) * uint64_t(fmas);
    double gflop = double(flop) / double(1.0e9);
    return gflop / runtime_s;
  }
};

/// Result structure
struct Result
{
  double avg_runtime_ms = 0.0;
  double gflops = 0.0;
  cutlass::Status status = cutlass::Status::kSuccess;
  cudaError_t error = cudaSuccess;
  bool passed = false;
};

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM setup and evaluation
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to initialize a block of device data
template <class Element>
bool initialize_block(
  cutlass::DeviceAllocation<Element>& block,
  uint64_t seed=2023) {

  Element scope_max, scope_min;
  int bits_input = cutlass::sizeof_bits<Element>::value;

  if (bits_input == 1) {
    scope_max = static_cast<Element>(2);
    scope_min = static_cast<Element>(0);
  } else if (bits_input <= 8) {
    scope_max = static_cast<Element>(2);
    scope_min = static_cast<Element>(-2);
  } else {
    scope_max = static_cast<Element>(8);
    scope_min = static_cast<Element>(-8);
  }

  cutlass::reference::device::BlockFillRandomUniform(
    block.get(), block.size(), seed, scope_max, scope_min, 0);

  return true;
}

/// Allocates device-side data
void allocate(const Options &options) {
  int64_t total_elements_A = 0;
  int64_t total_elements_B = 0;
  int64_t total_elements_C = 0;
  int64_t total_elements_D = 0;

  for (int32_t i = 0; i < options.groups; ++i) {

    auto problem = options.problem_sizes_host.at(i);
    auto M = get<0>(problem);
    auto N = get<1>(problem);
    auto K = get<2>(problem);

    offset_A.push_back(total_elements_A);
    offset_B.push_back(total_elements_B);
    offset_C.push_back(total_elements_C);
    offset_D.push_back(total_elements_D);

    int64_t elements_A = M * K;
    int64_t elements_B = K * N;
    int64_t elements_C = M * N;
    int64_t elements_D = M * N;

    total_elements_A += elements_A;
    total_elements_B += elements_B;
    total_elements_C += elements_C;
    total_elements_D += elements_D;

    stride_A_host.push_back(cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(M, K, Int<1>{})));
    stride_B_host.push_back(cutlass::make_cute_packed_stride(StrideB{}, cute::make_shape(N, K, Int<1>{})));
    stride_C_host.push_back(cutlass::make_cute_packed_stride(StrideC{}, cute::make_shape(M, N, Int<1>{})));
    stride_D_host.push_back(cutlass::make_cute_packed_stride(StrideD{}, cute::make_shape(M, N, Int<1>{})));
  }

  block_A.reset(total_elements_A);
  block_B.reset(total_elements_B);
  block_C.reset(total_elements_C);
  block_D.reset(total_elements_D);
  block_ref_D.reset(total_elements_D);
}

/// Initialize operands to be used in the GEMM and reference GEMM
void initialize(const Options &options) {
  
  uint64_t seed = 2020;

  problem_sizes.reset(options.groups);
  problem_sizes.copy_from_host(options.problem_sizes_host.data());

  //
  // Assign pointers
  //

  std::vector<ElementA *> ptr_A_host(options.groups);
  std::vector<ElementB *> ptr_B_host(options.groups);
  std::vector<ElementC *> ptr_C_host(options.groups);
  std::vector<ElementC *> ptr_D_host(options.groups);

  for (int32_t i = 0; i < options.groups; ++i) {
    ptr_A_host.at(i) = block_A.get() + offset_A.at(i);
    ptr_B_host.at(i) = block_B.get() + offset_B.at(i);
    ptr_C_host.at(i) = block_C.get() + offset_C.at(i);
    ptr_D_host.at(i) = block_D.get() + offset_D.at(i);
  }

  ptr_A.reset(options.groups);
  ptr_A.copy_from_host(ptr_A_host.data());

  ptr_B.reset(options.groups);
  ptr_B.copy_from_host(ptr_B_host.data());

  ptr_C.reset(options.groups);
  ptr_C.copy_from_host(ptr_C_host.data());

  ptr_D.reset(options.groups);
  ptr_D.copy_from_host(ptr_D_host.data());

  stride_A.reset(options.groups);
  stride_A.copy_from_host(stride_A_host.data());

  stride_B.reset(options.groups);
  stride_B.copy_from_host(stride_B_host.data());

  stride_C.reset(options.groups);
  stride_C.copy_from_host(stride_C_host.data());

  stride_D.reset(options.groups);
  stride_D.copy_from_host(stride_D_host.data());

  initialize_block(block_A, seed + 2023);
  initialize_block(block_B, seed + 2022);
  initialize_block(block_C, seed + 2021);
}

/// Populates a Gemm::Arguments structure from the given commandline options
typename Gemm::Arguments args_from_options(const Options &options)
{
  cutlass::KernelHardwareInfo hw_info;
  // Change device_id to another value if you are running on a machine with multiple GPUs and wish
  // to use a GPU other than that with device ID 0.
  hw_info.device_id = 0;
  hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);

  typename Gemm::Arguments arguments{
    cutlass::gemm::GemmUniversalMode::kGrouped,
    {options.groups, problem_sizes.get(), options.problem_sizes_host.data()},
    {ptr_A.get(), stride_A.get(), ptr_B.get(), stride_B.get()},
    {{options.alpha, options.beta}, ptr_C.get(), stride_C.get(), ptr_D.get(), stride_D.get()},
    hw_info
  };

  return arguments;
}

bool verify(const Options &options) {
  bool passed = true;
  for (int32_t i = 0; i < options.groups; ++i) {
    auto problem = options.problem_sizes_host.at(i);
    auto M = get<0>(problem);
    auto N = get<1>(problem);
    auto K = get<2>(problem);
    cutlass::TensorRef ref_A(block_A.get() + offset_A.at(i), Gemm::LayoutA::packed({M, K}));
    cutlass::TensorRef ref_B(block_B.get() + offset_B.at(i), Gemm::LayoutB::packed({K, N}));
    cutlass::TensorRef ref_C(block_C.get() + offset_C.at(i), Gemm::LayoutC::packed({M, N}));
    cutlass::TensorRef ref_D(block_ref_D.get() + offset_D.at(i), Gemm::LayoutD::packed({M, N}));

    //
    // Compute reference output
    //

    // Create instantiation for device reference gemm kernel
    DeviceGemmReference gemm_reference;

    // Launch device reference gemm kernel
    gemm_reference(
      {M, N, K},
      ElementAccumulator(options.alpha),
      ref_A,
      ref_B,
      ElementAccumulator(options.beta),
      ref_C,
      ref_D);

    // Wait for kernel to finish
    CUDA_CHECK(cudaDeviceSynchronize());

    // Check if output from CUTLASS kernel and reference kernel are equal or not
    passed &= cutlass::reference::device::BlockCompareEqual(block_ref_D.get() + offset_D.at(i), block_D.get() + offset_D.at(i), M * N);
    #if 0
    std::cout << "Group: " << i << " Status: " << passed << std::endl;
    #endif
  }
  return passed;
}

/// Execute a given example GEMM computation
template <typename Gemm>
int run(Options &options)
{
  allocate(options);
  initialize(options);

  // Instantiate CUTLASS kernel depending on templates
  Gemm gemm;

  // Create a structure of gemm kernel arguments suitable for invoking an instance of Gemm
  auto arguments = args_from_options(options);

  // Using the arguments, query for extra workspace required for matrix multiplication computation
  size_t workspace_size = Gemm::get_workspace_size(arguments);

  // Allocate workspace memory
  cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

  // Check if the problem size is supported or not
  CUTLASS_CHECK(gemm.can_implement(arguments));

  // Initialize CUTLASS kernel with arguments and workspace pointer
  CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));

  // Correctness / Warmup iteration
  CUTLASS_CHECK(gemm.run());

  // Check if output from CUTLASS kernel and reference kernel are equal or not
  Result result;
  result.passed = verify(options);

  std::cout << "  Disposition: " << (result.passed ? "Passed" : "Failed") << std::endl;

  if (!result.passed) {
    exit(-1);
  }

  // Run profiling loop
  if (options.iterations > 0)
  {
    GpuTimer timer;
    timer.start();
    for (int iter = 0; iter < options.iterations; ++iter) {
      CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));
      CUTLASS_CHECK(gemm.run());
    }
    timer.stop();

    // Compute average setup and runtime and GFLOPs.
    float elapsed_ms       = timer.elapsed_millis();
    result.avg_runtime_ms  = double(elapsed_ms) / double(options.iterations);
    result.gflops          = options.gflops(result.avg_runtime_ms / 1000.0, options.problem_sizes_host);

    std::cout << "  Problem Sizes: " << std::endl;
    for (auto const & problem : options.problem_sizes_host) {
      std::cout << "    " << problem << std::endl;
    }
    std::cout << "  Groups      : " << options.groups  << std::endl;
    std::cout << "  Alpha, Beta : " << options.alpha << ',' << options.beta << std::endl;
    std::cout << "  Avg runtime : " << result.avg_runtime_ms << " ms" << std::endl;
    std::cout << "  GFLOPS      : " << result.gflops << std::endl;
  }

  return 0;
}

#endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  // CUTLASS must be compiled with CUDA 12.3 Toolkit to run this example
  if (__CUDACC_VER_MAJOR__ < 12 || (__CUDACC_VER_MAJOR__ == 12 && __CUDACC_VER_MINOR__ < 3)) {
    std::cerr << "This example requires CUDA 12.3 or newer.\n";
    // Returning zero so this test passes on older Toolkits. Its actions are no-op.
    return 0;
  }

  cudaDeviceProp props;
  int current_device_id;
  CUDA_CHECK(cudaGetDevice(&current_device_id));
  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device_id));
  cudaError_t error = cudaGetDeviceProperties(&props, 0);
  if (props.major < 9) {
    std::cerr
      << "This example requires a GPU of NVIDIA's Hopper Architecture or "
      << "later (compute capability 90 or greater).\n";
    return 0;
  }

  //
  // Parse options
  //

  Options options;

  options.parse(argc, args);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  //
  // Evaluate CUTLASS kernels
  //

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)
  run<Gemm>(options);
#endif

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
