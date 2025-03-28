/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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

#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/collective/xe_array_epilogue.hpp"
#include "cutlass/epilogue/fusion/xe_callbacks.hpp"
#include "cutlass/gemm/group_array_problem_shape.hpp"
#include "cutlass/gemm/device/gemm_universal.h"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/collective/collective_mma.hpp"
#include "cutlass/util/GPU_Clock.hpp"

#include <cute/tensor.hpp>
#include <random>

#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "common.hpp"
#include "helper.h"

#include <cfloat>

using namespace cute;
using ProblemShape = cutlass::gemm::GroupProblemShape<Shape<int,int,int>>; // <M,N,K> per group

using ElementAccumulator = float;                   // <- data type of accumulator
using ElementComputeEpilogue = float;  // <- data type of epilogue operations
using ElementA = bfloat16_t;                        // <- data type of elements in input matrix A
using ElementB = bfloat16_t;                        // <- data type of elements in input matrix B
using ElementOutput = float;                        // <- data type of elements in output matrix D

///////////////////////////////////////////////////////////////////////////////////////////////////

#define CUTLASS_SYCL_PROFILING_ENABLED

// Command line options parsing
struct Options {

  bool error = false;
  bool help = false;

  float alpha, beta;
  int iterations;
  int m, n, k, groups;
  std::vector<typename ProblemShape::UnderlyingProblemShape> problem_sizes_host;

  Options() : error(false), help(false), alpha(FLT_MAX), beta(FLT_MAX), iterations(100),
              m(5120), n(4096), k(4096), groups(2) {
    problem_sizes_host.reserve(groups);
    for(int i = 0; i < groups; i++) {
      problem_sizes_host.push_back({m, n, k});
    }
  }

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("m", m, 5120);
    cmd.get_cmd_line_argument("n", n, 4096);
    cmd.get_cmd_line_argument("k", k, 4096);
    cmd.get_cmd_line_argument("groups", groups, 2);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta",  beta,  0.f);
    cmd.get_cmd_line_argument("iterations", iterations, 100);

    assert(groups > 0);
    problem_sizes_host.clear();
    problem_sizes_host.reserve(groups);
    for(int i = 0; i < groups; i++) {
      problem_sizes_host.push_back({m, n, k});
    }
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "PVC Grouped GEMM\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM for all groups\n"
      << "  --n=<int>                   Sets the N extent of the GEMM for all groups\n"
      << "  --k=<int>                   Sets the K extent of the GEMM for all groups\n"
      << "  --groups=<int>              Sets the number of individual GEMM problems for Grouped GEMM\n"
      << "  --alpha=<f32>               Epilogue scalar alpha\n"
      << "  --beta=<f32>                Epilogue scalar beta\n\n"
      << "  --iterations=<int>          Number of profiling iterations to perform\n\n";

    out
      << "\n\nExamples:\n\n"
      << "$ " << "pvc_grouped_gemm" << " --m=5120 --n=4096 --k=4096 --groups=5 --alpha=2.5 --beta=0.5 \n\n";

    return out;
  }

  /// Compute performance in GFLOP/s
  double gflops(double runtime_s, std::vector<typename ProblemShape::UnderlyingProblemShape> problem_sizes_host) const
  {
    // Number of real-valued multiply-adds
    uint64_t fmas = uint64_t();

    for (auto const & problem : problem_sizes_host) {
      fmas += static_cast<uint64_t>(get<0>(problem)) *
              static_cast<uint64_t>(get<1>(problem)) *
              static_cast<uint64_t>(get<2>(problem));
    }
    // Two flops per multiply-add
    uint64_t flop = uint64_t(2) * uint64_t(fmas);
    double gflop = double(flop) / double(1.0e9);
    return gflop / runtime_s;
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template <
  class Gemm
>
struct ExampleRunner {

  using ElementA = typename Gemm::ElementA;
  using ElementB = typename Gemm::ElementB;
  using ElementC = typename Gemm::ElementC;

  using LayoutA = typename Gemm::LayoutA;
  using LayoutB = typename Gemm::LayoutB;
  using LayoutC = typename Gemm::LayoutC;
  using LayoutD = typename Gemm::LayoutD;

  using CollectiveEpilogue = typename Gemm::CollectiveEpilogue;
  using ElementOutput = typename CollectiveEpilogue::ElementOutput;
  using ElementAccumulator = ElementOutput;

  using StrideA = typename Gemm::GemmKernel::InternalStrideA;
  using StrideB = typename Gemm::GemmKernel::InternalStrideB;
  using StrideC = typename Gemm::GemmKernel::InternalStrideC;
  using StrideD = typename Gemm::GemmKernel::InternalStrideD;

  // Host-side allocations
  std::vector<int64_t> offset_A;
  std::vector<int64_t> offset_B;
  std::vector<int64_t> offset_C;
  std::vector<int64_t> offset_D;

  std::vector<StrideA> stride_A_host;
  std::vector<StrideB> stride_B_host;
  std::vector<StrideC> stride_C_host;
  std::vector<StrideD> stride_D_host;

  std::vector<ElementAccumulator> alpha_host;
  std::vector<ElementAccumulator> beta_host;

  // Device-side allocations
  cutlass::DeviceAllocation<typename ProblemShape::UnderlyingProblemShape> problem_sizes;

  cutlass::DeviceAllocation<ElementA> block_A;
  cutlass::DeviceAllocation<ElementB> block_B;
  cutlass::DeviceAllocation<ElementC> block_C;
  cutlass::DeviceAllocation<ElementOutput> block_D;
  cutlass::DeviceAllocation<ElementOutput> block_ref_D;

  cutlass::DeviceAllocation<const ElementA *> ptr_A;
  cutlass::DeviceAllocation<const ElementB *> ptr_B;
  cutlass::DeviceAllocation<const ElementC *> ptr_C;
  cutlass::DeviceAllocation<ElementOutput *> ptr_D;
  cutlass::DeviceAllocation<ElementOutput *> ptr_ref_D;

  cutlass::DeviceAllocation<StrideA> stride_A;
  cutlass::DeviceAllocation<StrideB> stride_B;
  cutlass::DeviceAllocation<StrideC> stride_C;
  cutlass::DeviceAllocation<StrideD> stride_D;

  // Note, this is an array of pointers to alpha and beta scaling values per group
  cutlass::DeviceAllocation<ElementAccumulator*> alpha_device;
  cutlass::DeviceAllocation<ElementAccumulator*> beta_device;
  cutlass::DeviceAllocation<ElementAccumulator> block_alpha;
  cutlass::DeviceAllocation<ElementAccumulator> block_beta;

  uint64_t seed = 0;

  //
  // Methods
  //

  bool verify(const Options &options) {
    bool passed = true;
    for (int32_t i = 0; i < options.groups; ++i) {
      auto problem = options.problem_sizes_host.at(i);
      auto M = get<0>(problem);
      auto N = get<1>(problem);
      auto K = get<2>(problem);
      cutlass::TensorRef ref_A(block_A.get() + offset_A.at(i), LayoutA::packed({M, K}));
      cutlass::TensorRef ref_B(block_B.get() + offset_B.at(i), LayoutB::packed({K, N}));
      cutlass::TensorRef ref_C(block_C.get() + offset_C.at(i), LayoutC::packed({M, N}));
      cutlass::TensorRef ref_D(block_ref_D.get() + offset_D.at(i), LayoutD::packed({M, N}));

      //
      // Compute reference output
      //
      cutlass::reference::device::GemmComplex(
            {M, N, K},
            alpha_host.at(i),
            ref_A,
            cutlass::ComplexTransform::kNone,
            ref_B,
            cutlass::ComplexTransform::kNone,
            beta_host.at(i),
            ref_C,
            ref_D,
            ElementAccumulator(0),
            1,     // batch_count
            M * K, // batch_stride_A
            K * N, // batch_stride_B
            M * N, // batch_stride_C
            M * N  // batch_stride_D
          );

      // Wait for kernel to finish
      syclcompat::wait();

      // Check if output from CUTLASS kernel and reference kernel are equal or not
      passed &= cutlass::reference::device::BlockCompareEqual(block_ref_D.get() + offset_D.at(i), block_D.get() + offset_D.at(i), M * N);
      if(!passed)
        break;
    }
    return passed;
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

    stride_A_host.push_back(cutlass::make_cute_packed_stride(StrideA{}, {M, K, 1}));
    stride_B_host.push_back(cutlass::make_cute_packed_stride(StrideB{}, {N, K, 1}));
    stride_C_host.push_back(cutlass::make_cute_packed_stride(StrideC{}, {M, N, 1}));
    stride_D_host.push_back(cutlass::make_cute_packed_stride(StrideD{}, {M, N, 1}));

  }

  block_A.reset(total_elements_A);
  block_B.reset(total_elements_B);
  block_C.reset(total_elements_C);
  block_D.reset(total_elements_D);
  block_ref_D.reset(total_elements_D);
  block_alpha.reset(options.groups);
  block_beta.reset(options.groups);
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
  std::vector<ElementAccumulator *> ptr_alpha_host(options.groups);
  std::vector<ElementAccumulator *> ptr_beta_host(options.groups);

  for (int32_t i = 0; i < options.groups; ++i) {
    ptr_A_host.at(i) = block_A.get() + offset_A.at(i);
    ptr_B_host.at(i) = block_B.get() + offset_B.at(i);
    ptr_C_host.at(i) = block_C.get() + offset_C.at(i);
    ptr_D_host.at(i) = block_D.get() + offset_D.at(i);
    alpha_host.push_back((options.alpha == FLT_MAX) ? static_cast<ElementAccumulator>((rand() % 5) + 1) : options.alpha);
    beta_host.push_back((options.beta == FLT_MAX) ? static_cast<ElementAccumulator>(rand() % 5) : options.beta);
    ptr_alpha_host.at(i) = block_alpha.get() + i;
    ptr_beta_host.at(i) = block_beta.get() + i;
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

  alpha_device.reset(options.groups);
  alpha_device.copy_from_host(ptr_alpha_host.data());
  beta_device.reset(options.groups);
  beta_device.copy_from_host(ptr_beta_host.data());

  initialize_block(block_A, seed + 2023);
  initialize_block(block_B, seed + 2022);
  initialize_block(block_C, seed + 2021);
  block_alpha.copy_from_host(alpha_host.data());
  block_beta.copy_from_host(beta_host.data());
}

  /// Populates a Gemm::Arguments structure from the given commandline options
  typename Gemm::Arguments args_from_options(const Options &options, const cutlass::KernelHardwareInfo& hw_info, bool host_problem_shapes_available = true)
  {
    typename Gemm::Arguments arguments;
    decltype(arguments.epilogue.thread) fusion_args;

    if (options.alpha != FLT_MAX && options.beta != FLT_MAX) {
      // If both alpha/beta are provided (via cmd line args) and are scalar, i.e., same alpha/beta applies to all batches.
      fusion_args.alpha = options.alpha;
      fusion_args.beta = options.beta;
      fusion_args.alpha_ptr = nullptr;
      fusion_args.beta_ptr = nullptr;
      fusion_args.alpha_ptr_array = nullptr;
      fusion_args.beta_ptr_array = nullptr;
      // Single alpha and beta for all groups
      fusion_args.dAlpha = {cute::_0{}, cute::_0{}, 0};
      fusion_args.dBeta = {cute::_0{}, cute::_0{}, 0};
    }
    else {
      // If pointers to alpha/beta are provided, i.e., alpha/beta can differ between batches/groups.
      fusion_args.alpha = 0;
      fusion_args.beta = 0;
      fusion_args.alpha_ptr = nullptr;
      fusion_args.beta_ptr = nullptr;
      fusion_args.alpha_ptr_array = alpha_device.get();
      fusion_args.beta_ptr_array = beta_device.get();
      // One alpha and beta per each group
      fusion_args.dAlpha = {cute::_0{}, cute::_0{}, 1};
      fusion_args.dBeta = {cute::_0{}, cute::_0{}, 1};
    }
    using RasterOrderOptions = typename cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90Group<ProblemShape>::RasterOrderOptions;

    if (host_problem_shapes_available) {
      arguments = typename Gemm::Arguments {
        cutlass::gemm::GemmUniversalMode::kGrouped,
        {options.groups, problem_sizes.get(), options.problem_sizes_host.data()},
        {ptr_A.get(), stride_A.get(), ptr_B.get(), stride_B.get()},
        {fusion_args, ptr_C.get(), stride_C.get(), ptr_D.get(), stride_D.get()},
        hw_info,
        {1, RasterOrderOptions::AlongN}
      };
    }
    else {
      arguments = typename Gemm::Arguments {
        cutlass::gemm::GemmUniversalMode::kGrouped,
        {options.groups, problem_sizes.get(), nullptr},
        {ptr_A.get(), stride_A.get(), ptr_B.get(), stride_B.get()},
        {fusion_args, ptr_C.get(), stride_C.get(), ptr_D.get(), stride_D.get()},
        hw_info,
        {1, RasterOrderOptions::AlongN}
      };
    }

    return arguments;
  }

  cutlass::Status run(const Options& options, const cutlass::KernelHardwareInfo& hw_info, bool host_problem_shapes_available = true) {
    allocate(options);
    initialize(options);

    Gemm gemm_op;

    auto arguments = args_from_options(options, hw_info, host_problem_shapes_available);

    size_t workspace_size = Gemm::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

    CUTLASS_CHECK(gemm_op.can_implement(arguments));

    CUTLASS_CHECK(gemm_op.initialize(arguments, workspace.get()));

    // Run the GEMM
    CUTLASS_CHECK(gemm_op.run());

    syclcompat::wait();

    // Verify that the result is correct
    bool passed = verify(options);
    std::cout << "Disposition: " << (passed ? "Passed" : "Failed") << std::endl;

    if(!passed) return cutlass::Status::kErrorInternal;

    if (options.iterations > 0) {
      GPU_Clock timer;
      timer.start();
      for (int iter = 0; iter < options.iterations; ++iter) {
        CUTLASS_CHECK(gemm_op.run());
      }
      syclcompat::wait();

      float cute_time = timer.seconds() * 1000;
      double cute_average_time = double(cute_time) / double(options.iterations);
      double gflops = options.gflops(cute_average_time / 1000.0, options.problem_sizes_host);

      std::cout << "  Problem Sizes, Alpha, Beta " << std::endl;
      for (int32_t i = 0; i < options.groups; ++i) {
        std::cout << "    " << options.problem_sizes_host.at(i);
        std::cout << ", " << alpha_host.at(i) << ", " << beta_host.at(i) << std::endl;
      }
      std::cout << "  Groups      : " << options.groups  << std::endl;
      std::cout << "  Avg runtime : " << cute_average_time << " ms" << std::endl;
      std::cout << "  GFLOPS      : " << gflops << std::endl;
    }

    return cutlass::Status::kSuccess;
  }

};

int main(int argc, const char** argv)
{
  //
  // Parse options
  //

  Options options;

  options.parse(argc, argv);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  if (options.error) {
    std::cerr << "Aborting execution." << std::endl;
    return -1;
  }

  //
  // Run examples
  //

  // The KernelHardwareInfo struct holds the number of EUs on the GPU with a given device ID. This
  // information is used by the underlying kernel.
  cutlass::KernelHardwareInfo hw_info;

  // Change device_id to another value if you are running on a machine with multiple GPUs and wish
  // to use a GPU other than that with device ID 0.
  hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using GmemTiledCopyA = XE_2D_U16x32x32_LD_N;
  using GmemTiledCopyB = XE_2D_U16x32x32_LD_V;

  // Workgroup-level tile
  using TileShape = Shape<_256, _256, _32>;

  using TiledMma =
      TiledMMA<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
               Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>,
               Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                    Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, _32>>;

  constexpr int PipelineStages = 2;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelPVCGroup<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelPVCGroupEpilogue;

  using EpilogueOp = cutlass::epilogue::fusion::LinearCombination<ElementOutput, ElementComputeEpilogue,
          ElementAccumulator, ElementAccumulator, cutlass::FloatRoundStyle::round_to_nearest>;

  using FusionCallBacks = cutlass::epilogue::fusion::FusionCallbacks<EpilogueDispatchPolicy, EpilogueOp, TileShape,
          decltype(tile_shape(TiledMma()))>;
  using CollectiveEpilogue = cutlass::epilogue::collective::CollectiveEpilogue<
          EpilogueDispatchPolicy,
          TileShape,
          ElementAccumulator,
          cutlass::gemm::TagToStrideC_t<LayoutC*>,
          ElementOutput,
          cutlass::gemm::TagToStrideC_t<LayoutD*>,
          FusionCallBacks,
          XE_2D_U32x8x16_LD_N,
          void, void,
          XE_2D_U32x8x16_ST_N,
          void, void>;

// Mainloop
  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
          GEMMDispatchPolicy,
          TileShape,
          ElementA,
          cutlass::gemm::TagToStrideA_t<LayoutA*>,
          ElementB,
          cutlass::gemm::TagToStrideB_t<LayoutB*>,
          TiledMma,
          GmemTiledCopyA, void, void, cute::identity,  // A
          GmemTiledCopyB, void, void, cute::identity   // B
  >;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
  ProblemShape,
  CollectiveMainloop,
  CollectiveEpilogue,
  cutlass::gemm::GroupScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  ExampleRunner<Gemm> runner;

  CUTLASS_CHECK(runner.run(options, hw_info));

  return 0;
}
