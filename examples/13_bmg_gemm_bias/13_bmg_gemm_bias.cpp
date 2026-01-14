/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2026 Intel Corporation, All rights reserved.
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
    \brief CUTLASS Intel BMG Gemm Example with Bias addition.

    This example constructs and executes a simple CUTLASS GEMM kernel on Intel BMG hardware, and
    verifies its correctness with a reference implementation
    (cutlass::reference::device::GemmComplex). The example also provides a performance measurement
    for the GEMM in TFLOPS.

    This example makes use of BMGs subgroup cooperative 2d-block copy operations and DPAS instructions.

    The shapes of the A and B matrix are defined at runtime by `options.m`, `.n` and `.k`, and the
    batch size is defined by `options.l`. The tile shape, which defines how much work is executed by
    a single work-group, is defined at compile time by:
    ```
      using TileShape = Shape<_256, _256, _32>;
    ```
    That is, each work-group processes a tile of M=256, N=256, and iterates over `options.k` in
    blocks of K=32.

    Performance of GEMM on BMG is heavily dependent on prefetching the A and B matrices. That is,
    executing Intel specific prefetch instructions for future iterations to ensure that the required
    blocks of A and B are resident in cache before they are needed.

    To build & run this example (from your build dir):

      $ ninja 13_bmg_gemm_bias
      $ ./examples/13_bmg_gemm_bias/13_bmg_gemm_bias

    Call with `--help` for information about available options
*/

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
#include "sycl_common.hpp"
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
    alpha(1.f), beta(1.f)
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
    cmd.get_cmd_line_argument("beta", beta, 1.f);
    cmd.get_cmd_line_argument("iterations", iterations, 100);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "BMG GEMM Example with Bias addition\n\n"
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
  using ElementAccumulator = typename Gemm::ElementAccumulator;

  using CollectiveEpilogue = typename Gemm::CollectiveEpilogue;
  using ElementC = typename Gemm::ElementC;
  using ElementOutput = typename CollectiveEpilogue::ElementOutput;
  using ElementD = ElementOutput;
  using ElementCompute = typename CollectiveEpilogue::ElementCompute;

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
  cutlass::DeviceAllocation<ElementC> block_C;
  cutlass::DeviceAllocation<ElementOutput> block_D;
  cutlass::DeviceAllocation<ElementOutput> block_ref_D; // Reference GEMM result for verification

  //
  // Methods
  //

  bool verify(const ProblemShapeType& problem_size, ElementCompute alpha, ElementCompute beta) {
    auto [M, N, K, L] = problem_size;

    cutlass::TensorRef ref_A(block_A.get(), LayoutA::packed({M, K}));
    cutlass::TensorRef ref_B(block_B.get(), LayoutB::packed({K, N}));
    cutlass::TensorRef ref_C(block_C.get(), LayoutC::packed({M, N}));
    cutlass::TensorRef ref_D(block_ref_D.get(), LayoutD::packed({M, N}));

    cutlass::reference::device::GemmComplex(
          {M, N, K},
          alpha,
          ref_A,
          cutlass::ComplexTransform::kNone,
          ref_B,
          cutlass::ComplexTransform::kNone,
          beta,
          ref_C,
          ref_D,
          ElementAccumulator(0),
          L,     // batch_count
          M * K, // batch_stride_A
          K * N, // batch_stride_B
          M * N, // batch_stride_C
          M * N  // batch_stride_D
        );

    // CUTLASS on SYCL uses the compatibility library compat for e.g. default in-order queue
    compat::wait();

    // Check if output from CUTLASS kernel and reference kernel are equal or not
    bool passed = cutlass::reference::device::BlockCompareEqual(
      block_ref_D.get(), block_D.get(), block_D.size());

    return passed;
  }

  /// Initialize operands to be used in the GEMM and reference GEMM
  void initialize(const ProblemShapeType& problem_size) {
    auto problem_shape_MNKL = cute::append<4>(problem_size, 1);
    auto [M, N, K, L] = problem_shape_MNKL;

    // Complete the stride by combining static layout info (StrideA) with runtime size info (M,K,L)
    stride_A = cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(M, K, L));
    stride_B = cutlass::make_cute_packed_stride(StrideB{}, cute::make_shape(N, K, L));
    stride_C = cutlass::make_cute_packed_stride(StrideC{}, cute::make_shape(M, N, L));
    stride_D = cutlass::make_cute_packed_stride(StrideD{}, cute::make_shape(M, N, L));

    block_A.reset(static_cast<std::size_t>(M) * K * L);
    block_B.reset(static_cast<std::size_t>(K) * N * L);
    block_C.reset(static_cast<std::size_t>(M) * N * L);
    block_D.reset(static_cast<std::size_t>(M) * N * L);
    block_ref_D.reset(static_cast<std::size_t>(M) * N * L);

    initialize_block(block_A, seed + 2023);
    initialize_block(block_B, seed + 2022);
    initialize_block(block_C, seed + 2021);
  }

  cutlass::Status run(const Options& options, const cutlass::KernelHardwareInfo& hw_info) {
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

    if (gemm_op.can_implement(arguments) != cutlass::Status::kSuccess){
      std::cout << "Invalid Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << 'x' << options.l << std::endl;
      std::exit(1);
    }

    CUTLASS_CHECK(gemm_op.initialize(arguments, workspace.get()));

    // Run the GEMM
    CUTLASS_CHECK(gemm_op.run());

    compat::wait();

    // Verify that the result is correct
    bool passed = verify(problem_size, options.alpha, options.beta);
    std::cout << "Disposition: " << (passed ? "Passed" : "Failed") << std::endl;

    if (passed && options.iterations > 0) {
      GPU_Clock timer;
      timer.start();
      for (int i = 0; i < options.iterations; ++i) {
        gemm_op.run();
      }
      compat::wait();

      float cute_time = timer.seconds() / options.iterations;
      double tflops = (2.0 * options.m * options.n * options.k * options.l) * 1e-12;
      std::cout << "Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << 'x' << options.l << std::endl;
      printf("Cutlass GEMM Performance:     [%4.3f]TFlop/s  (%6.4f)ms\n", tflops / cute_time, cute_time*1000);
    }

    return cutlass::Status::kSuccess;
  }

};

template<
  typename ElementInputC,
  typename LayoutC,
  typename ElementOutput
  >
bool test_bmg_gemm_bias(Options& options, cutlass::KernelHardwareInfo& hw_info)
{

  bool passed;

  // The code section below describes datatype for input, output matrices and computation between
  // elements in input matrices.
  using ElementAccumulator = float;      // <- data type of accumulator
  using ElementComputeEpilogue = float;  // <- data type of epilogue operations
  using ElementInputA = bfloat16_t;      // <- data type of elements in input matrix A
  using ElementInputB = bfloat16_t;      // <- data type of elements in input matrix B

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  // [New Copy Atom] When left unspecified (void), MainloopXeL1Staged automatically selects
  // appropriate 2D block copy operations for matrices A and B. Alternatively, you can
  // explicitly specify new copy atom operations such as XE_LOAD_2D, XE_LOAD_2D_VNNI,
  // or XE_LOAD_2D_TRANSPOSE.
  // Refer https://github.com/intel/sycl-tla/blob/main/media/docs/cpp/xe_rearchitecture.md
  using GmemTiledCopyA = void; //XE_LOAD_2D<16, 32, 32>;
  using GmemTiledCopyB = void; //XE_LOAD_2D_VNNI<16, 32, 32>;

  // Workgroup-level tile
  using TileShape = Shape<_256, _256, _32>;

  // A TiledMMA struct defines a tiling of an MMA atom over M, N and K, combining both additional
  // hardware (sub-groups for Intel BMG) and iterations by each sub-group.
  //
  // The TiledMMAHelper struct defines a specific TiledMMA for a given MMA atom. This example uses
  // the XE_DPAS_TT<8, float, cute::bfloat16_t> atom, which represents an 8x16x16 DPAS operation with
  //float32 accumulation and bfloat16 inputs, TileShape (<256, 256, 32>) and sub-group layout (8x4x1).
  // The TiledMMA constructed using TiledMMAHelper has the property that each sub-group operates on a
  // single contiguous chunk of the work-group TileShape. For this configuration, this implies that
  // each sub-group operates on a contiguous 32x64x32 chunk (4x4x2 iterations). See
  // 0t_mma_atom.md#TiledMMAs for more info. Sub-groups are arranged row-major (stride 4,1,0) for
  // performance reasons.
  using TiledMma = typename TiledMMAHelper<MMA_Atom<XE_DPAS_TT<8, float, cute::bfloat16_t>>, Layout<TileShape>, Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA;

  // For Intel BMG, PipelineStages defines how many k-blocks ahead to prefetch from A and B.
  constexpr int PipelineStages = 2;
  // For older version of copy/mma atom, use cutlass::gemm::MainloopIntelXeXMX16 as dispatch policy
  using GEMMDispatchPolicy = cutlass::gemm::MainloopXeL1Staged<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeGeneric;

  // This is the 'default' epilogue operation (Linear Combination) which performs everything in:
  // (D = alpha * (A*B) + beta * C)
  // aside from the (A*B), which is handled by the GEMM. See 05_bmg_gemm_with_epilogues for more
  // complex epilogue examples.
  using EpilogueOp = cutlass::epilogue::fusion::LinearCombination<ElementOutput, ElementComputeEpilogue,
          ElementInputC, ElementAccumulator, cutlass::FloatRoundStyle::round_to_nearest>;

  // FusionCallbacks ties the EpilogueOp to an implementation (based on the dispatch
  // policy/architecture) and defines the epilogue arguments.
  using FusionCallbacks = cutlass::epilogue::fusion::FusionCallbacks<EpilogueDispatchPolicy, EpilogueOp, TileShape,
          decltype(tile_shape(TiledMma()))>;

  // GEMM Epilogue - loads & stores C/D matrices, performs epilogue operations & load/stores any
  // auxiliary data required
  using CollectiveEpilogue = cutlass::epilogue::collective::CollectiveEpilogue<
          EpilogueDispatchPolicy,
          TileShape,
          void,                                   // Epilogue tile (void = automatic)
          ElementInputC,
          cutlass::gemm::TagToStrideC_t<LayoutC>, // Converts CUTLASS 2.x to CUTLASS 3.x representation
          ElementOutput,
          cutlass::gemm::TagToStrideC_t<LayoutD>, // Converts CUTLASS 2.x to CUTLASS 3.x representation
          FusionCallbacks,
          void,                                   // The copy atom used to load matrix C  (void = automatic)
          void>;                                  // The copy atom used to store matrix D (void = automatic)

  // GEMM Mainloop - iteration over blocks in K dimension
  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
          GEMMDispatchPolicy,
          TileShape,
          ElementInputA,
          cutlass::gemm::TagToStrideA_t<LayoutA>, // Converts CUTLASS 2.x to CUTLASS 3.x representation
          ElementInputB,
          cutlass::gemm::TagToStrideB_t<LayoutB>, // Converts CUTLASS 2.x to CUTLASS 3.x representation
          TiledMma,
          GmemTiledCopyA, void, void, cute::identity,  // A
          GmemTiledCopyB, void, void, cute::identity   // B
  >;

  // Define the whole kernel (mainloop and epilogue)
  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
          Shape<int, int, int, int>, // Defer global problem shape definition to runtime
          CollectiveMainloop,
          CollectiveEpilogue
  >;

  // The GemmUniversalAdapter wraps the defined GEMM kernel and handles the launch, and e.g.
  // persistent scratch memory if required.
  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  ExampleRunner<Gemm> runner;

  CUTLASS_CHECK(runner.run(options, hw_info));

  return passed;
}

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

  std::cout << "\n\nRunning BMG GEMM with float, RowMajor Bias and float, RowMajor Output" << std::endl << std::flush;
  test_bmg_gemm_bias<float, cutlass::layout::RowMajor, float>(options, hw_info);

  std::cout << "\n\nRunning BMG GEMM with float, ColumnMajor Bias and float, RowMajor Output" << std::endl << std::flush;
  test_bmg_gemm_bias<float, cutlass::layout::ColumnMajor, float>(options, hw_info);

  std::cout << "\n\nRunning BMG GEMM with float, RowMajor Bias and bfloat16, RowMajor Output" << std::endl << std::flush;
  test_bmg_gemm_bias<float, cutlass::layout::RowMajor, bfloat16_t>(options, hw_info);

  std::cout << "\n\nRunning BMG GEMM with float, ColumnMajor Bias and bfloat16, RowMajor Output" << std::endl << std::flush;
  test_bmg_gemm_bias<float, cutlass::layout::ColumnMajor, bfloat16_t>(options, hw_info);

  std::cout << "\n\nRunning BMG GEMM with bfloat16, RowMajor Bias and bfloat16, RowMajor Output" << std::endl << std::flush;
  test_bmg_gemm_bias<bfloat16_t, cutlass::layout::RowMajor, bfloat16_t>(options, hw_info);

  std::cout << "\n\nRunning BMG GEMM with bfloat16, ColumnMajor Bias and bfloat16, RowMajor Output" << std::endl << std::flush;
  test_bmg_gemm_bias<bfloat16_t, cutlass::layout::ColumnMajor, bfloat16_t>(options, hw_info);

  return 0;
}
