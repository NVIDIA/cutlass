/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
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
#include "cutlass/epilogue/collective/xe_epilogue.hpp"
#include "cutlass/epilogue/fusion/xe_callbacks.hpp"
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

using namespace cute;

///////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

  bool help;
  bool error;

  int m, n, k, l, iterations;
  float alpha, beta;

  Options():
    help(false),
    error(false),
    m(5120), n(4096), k(4096), l(1), iterations(20),
    alpha(1.f), beta(0.f)
  { }

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
    cmd.get_cmd_line_argument("l", l, 1);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("iterations", iterations, 100);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "PVC GEMM Mixed Type Example\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --l=<int>                   Sets the L extent (batch count) of the GEMM\n"
      << "  --alpha=<s32>               Epilogue scalar alpha\n"
      << "  --beta=<s32>                Epilogue scalar beta\n\n"
      << "  --iterations=<int>          Iterations\n\n";

    return out;
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template <
  class Gemm
>
struct ExampleRunner {

  using StrideA = typename Gemm::GemmKernel::StrideA;
  using StrideB = typename Gemm::GemmKernel::StrideB;
  using StrideC = typename Gemm::GemmKernel::StrideC;
  using StrideD = typename Gemm::GemmKernel::StrideD;

  using LayoutA = typename Gemm::LayoutA;
  using LayoutB = typename Gemm::LayoutB;
  using LayoutC = typename Gemm::LayoutC;
  using LayoutD = typename Gemm::LayoutD;

  using ElementA = typename Gemm::ElementA;
  using ElementB = typename Gemm::ElementB;
  using ElementAcc = typename Gemm::ElementAccumulator;

  using CollectiveEpilogue = typename Gemm::CollectiveEpilogue;
  using ElementC = typename Gemm::ElementC;
  using ElementOutput = typename CollectiveEpilogue::ElementOutput;
  using ElementCompute = typename CollectiveEpilogue::ElementCompute;
  using ElementAccumulator = typename CollectiveEpilogue::ElementAccumulator;

  using ProblemShapeType = typename Gemm::GemmKernel::ProblemShape;

  //
  // Data members
  //

  /// Initialization
  StrideA stride_A;
  StrideB stride_B;
  StrideC stride_C;
  StrideD stride_D;
  uint64_t seed = 0;

  cutlass::DeviceAllocation<ElementA> block_A;
  cutlass::DeviceAllocation<ElementB> block_B;
  cutlass::DeviceAllocation<ElementB> block_A_dq; // Dequantized copy of A for validation
  cutlass::DeviceAllocation<ElementC> block_C;
  cutlass::DeviceAllocation<ElementOutput> block_D;
  cutlass::DeviceAllocation<ElementOutput> block_ref_D;

  //
  // Methods
  //

  bool verify(const Options &options) {
      
    //
    // Compute reference output (default gemm kernel w/ ElementA == ElementB)
    //
    using ElementRefA = ElementB;          // <- data type of ElementA in reference implementation

    using GmemTiledCopyA = XE_2D_U16x32x32_LD_N;
    using GmemTiledCopyB = XE_2D_U16x32x32_LD_V;

    // Workgroup-level tile
    using TileShape = Shape<_256, _256, _32>;

    using TiledMma = TiledMMA<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
            Layout<Shape<_8,_4,_1>>,
            Tile<_64,_64,_32>>; // Subgroup level-tile

    constexpr int PipelineStages = 3;
    using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelPVC<PipelineStages>;
    using EpilogueDispatchPolicy = cutlass::epilogue::IntelPVCEpilogue;

    using EpilogueOp = cutlass::epilogue::fusion::LinearCombination<ElementOutput, ElementCompute,
            ElementAccumulator, ElementAccumulator, cutlass::FloatRoundStyle::round_to_nearest>;

    using FusionCallBacks = cutlass::epilogue::fusion::FusionCallbacks<EpilogueDispatchPolicy, EpilogueOp, TileShape,
            decltype(tile_shape(TiledMma()))>;

    using CollectiveEpilogueRef = cutlass::epilogue::collective::CollectiveEpilogue<
            EpilogueDispatchPolicy,
            TileShape,
            ElementAccumulator,
            cutlass::gemm::TagToStrideC_t<LayoutC>,
            ElementOutput,
            cutlass::gemm::TagToStrideC_t<LayoutD>,
            FusionCallBacks,
            XE_2D_U32x8x16_LD_N,
            void, void,
            XE_2D_U32x8x16_ST_N,
            void, void>;

    // Mainloop
    using CollectiveMainloopRef = cutlass::gemm::collective::CollectiveMma<
            GEMMDispatchPolicy,
            TileShape,
            ElementRefA,
            cutlass::gemm::TagToStrideA_t<LayoutA>,
            ElementB,
            cutlass::gemm::TagToStrideB_t<LayoutB>,
            TiledMma,
            GmemTiledCopyA, void, void, cute::identity,  // A
            GmemTiledCopyB, void, void, cute::identity   // B
    >;

    using GemmKernelRef = cutlass::gemm::kernel::GemmUniversal<
    Shape<int, int, int, int>,
    CollectiveMainloopRef,
    CollectiveEpilogueRef
    >;

    using GemmRef = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelRef>;

    typename GemmRef::Arguments arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      {options.m, options.n, options.k, options.l},
      {block_A_dq.get(), stride_A, block_B.get(), stride_B},
      {{options.alpha, options.beta}, block_C.get(), stride_C, block_ref_D.get(), stride_D}
    };

    // Run the gemm where the scaling is performed outside of the kernel.
    GemmRef gemm_ref;
    size_t workspace_size = GemmRef::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);
    CUTLASS_CHECK(gemm_ref.can_implement(arguments));
    CUTLASS_CHECK(gemm_ref.initialize(arguments, workspace.get()));
    CUTLASS_CHECK(gemm_ref.run());

    // compare_reference
    ElementOutput const epsilon(1e-2f);
    ElementOutput const non_zero_floor(1e-4f);
    bool passed = cutlass::reference::device::BlockCompareRelativelyEqual(block_ref_D.get(), block_D.get(), block_D.size(), epsilon, non_zero_floor);
    return passed;
  }

  template <typename T1, typename T2> 
  void initialize_block_A(cutlass::DeviceAllocation<T1> block_device, cutlass::DeviceAllocation<T2> block_device_dq,  uint64_t seed) {
    std::mt19937 rng(std::random_device{}());
    std::uniform_real_distribution<> dist(0.0f, 1.0f);
    rng.seed(seed);

    auto block_host = std::vector<T1>(block_device.size());
    auto block_host_dq = std::vector<T2>(block_device.size());
    for (int i = 0; i < block_host.size(); ++i) {
      block_host[i] = static_cast<T1>(dist(rng));
      block_host_dq[i] = static_cast<T2>(block_host[i]);
    }

    block_device.copy_from_host(block_host.data());
    block_device_dq.copy_from_host(block_host_dq.data());
  }

  /// Initialize operands to be used in the GEMM and reference GEMM
  void initialize(const ProblemShapeType& problem_size) {
    auto problem_shape_MNKL = cute::append<4>(problem_size, 1);
    auto [M, N, K, L] = problem_shape_MNKL;

    stride_A = cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(M, K, L));
    stride_B = cutlass::make_cute_packed_stride(StrideB{}, cute::make_shape(N, K, L));
    stride_C = cutlass::make_cute_packed_stride(StrideC{}, cute::make_shape(M, N, L));
    stride_D = cutlass::make_cute_packed_stride(StrideD{}, cute::make_shape(M, N, L));

    block_A.reset(M * K * L);
    block_A_dq.reset(M * K * L);
    block_B.reset(K * N * L);
    block_C.reset(M * N * L);
    block_D.reset(M * N * L);
    block_ref_D.reset(M * N * L);

    initialize_block_A(block_A, block_A_dq, seed+2023);
    initialize_block(block_B, seed + 2022);
    initialize_block(block_C, seed + 2021);
  }

  void run(const Options& options, const cutlass::KernelHardwareInfo& hw_info) {
    ProblemShapeType problem_size = ProblemShapeType{options.m, options.n, options.k, options.l};

    initialize(problem_size);

    typename Gemm::GemmKernel::Arguments arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      problem_size,
      {block_A.get(), stride_A, block_B.get(), stride_B},
      {{options.alpha, options.beta}, block_C.get(), stride_C, block_D.get(), stride_D},
      hw_info
    };

    Gemm gemm_op;

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

    if (passed && options.iterations > 0) {
      GPU_Clock timer;
      timer.start();
      for (int i = 0; i < options.iterations; ++i) {
        CUTLASS_CHECK(gemm_op.run());
      }
      syclcompat::wait();

      float cute_time = timer.seconds() / options.iterations;
      double tflops = (2.0 * options.m * options.n * options.k * options.l) * 1e-12;
      std::cout << "Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << 'x' << options.l << std::endl;
      printf("Cutlass GEMM Performance:     [%4.3f]TFlop/s  (%6.4f)ms\n", tflops / cute_time, cute_time*1000);
    }

    return;
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

  bool passed;

  // The code section below describes datatype for input, output matrices and computation between
  // elements in input matrices.
  using ElementAccumulator = float;                   // <- data type of accumulator
  using ElementComputeEpilogue = float;  // <- data type of epilogue operations
  using ElementInputA = cutlass::float_e4m3_t;         // <- data type of elements in input matrix A
  using ElementInputB = bfloat16_t;                        // <- data type of elements in input matrix B
  using ElementOutput = float;                        // <- data type of elements in output matrix D

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using GmemTiledCopyA = XE_2D_U8x32x32_LD_N;
  using GmemTiledCopyB = XE_2D_U16x32x32_LD_V;
  static_assert(sizeof(ElementInputA) == 1, "ElementA width must match GmemTiledCopyA U8");

  // Workgroup-level tile
  using TileShape = Shape<_256, _256, _32>;

  using TiledMma = TiledMMA<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
          Layout<Shape<_8,_4,_1>>,
          Tile<_64,_64,_32>>; // Subgroup level-tile

  constexpr int PipelineStages = 3;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelPVCMixedPrecision<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelPVCEpilogue;

  using EpilogueOp = cutlass::epilogue::fusion::LinearCombination<ElementOutput, ElementComputeEpilogue,
          ElementAccumulator, ElementAccumulator, cutlass::FloatRoundStyle::round_to_nearest>;

  using FusionCallBacks = cutlass::epilogue::fusion::FusionCallbacks<EpilogueDispatchPolicy, EpilogueOp, TileShape,
          decltype(tile_shape(TiledMma()))>;
  using CollectiveEpilogue = cutlass::epilogue::collective::CollectiveEpilogue<
          EpilogueDispatchPolicy,
          TileShape,
          ElementAccumulator,
          cutlass::gemm::TagToStrideC_t<LayoutC>,
          ElementOutput,
          cutlass::gemm::TagToStrideC_t<LayoutD>,
          FusionCallBacks,
          XE_2D_U32x8x16_LD_N,
          void, void,
          XE_2D_U32x8x16_ST_N,
          void, void>;

  // Mainloop
  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
          GEMMDispatchPolicy,
          TileShape,
          ElementInputA,
          cutlass::gemm::TagToStrideA_t<LayoutA>,
          ElementInputB,
          cutlass::gemm::TagToStrideB_t<LayoutB>,
          TiledMma,
          GmemTiledCopyA, void, void, cute::identity,  // A
          GmemTiledCopyB, void, void, cute::identity   // B
  >;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
  Shape<int, int, int, int>,
  CollectiveMainloop,
  CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  ExampleRunner<Gemm> runner;

  runner.run(options, hw_info);

  return 0;
}
