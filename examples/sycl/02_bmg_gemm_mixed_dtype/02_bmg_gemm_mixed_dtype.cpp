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
/*! \file
    \brief CUTLASS Intel BMG Gemm with mixed input types

  This example demonstrates how to dispatch a mixed precision GEMM (int8 and bfloat16) on BMG, with
  optional dequantization. The GemmMode enum describes the 3 modes of operation:

  - ConvertOnly:                   Narrower type is simply converted to the wider type before MMA
  - ConvertAndScale:               Narrower type is converted to wider type, then scaled
  - ConvertAndScaleWithZeroPoint:  Narrower type is converted to wider type, scaled and offset

  - Requirements:
      - dequantization group size (options.g) must be multiple of k-block size
      - scales & zeros must be MN-major

  The MMA operation itself takes bfloat16 input for both A and B, and so the narrower type is first
  upcasted (inside the mainloop) prior to being passed into the MMA atom.

  Verification for this example is performed against a standard reference GEMM in the wider type.
  The narrow-type input data are upcasted (or dequantized) externally before executing the
  reference GEMM.

  Note: due to a bug in the IGC compiler, it's currently necessary to build this example with the
  following environment variable set (CMake handles this for AOT compilation; for JIT, please set
  this in your environment):

    export IGC_allowDecompose2DBlockFuncs=0

  To build & run this example (from your build dir):

    $ ninja 02_bmg_gemm_mixed_dtype
    $ ./examples/sycl/02_bmg_gemm_mixed_dtype/02_bmg_gemm_mixed_dtype

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
#include "cutlass/util/mixed_dtype_utils.hpp"

using namespace cute;

///////////////////////////////////////////////////////////////////////////////////////////////////

enum GemmMode {
  ConvertOnly,
  ConvertAndScale,
  ConvertAndScaleWithZeroPoint
};

using MmaType = bfloat16_t;
using QuantType = cutlass::int8_t;

// Command line options parsing
struct Options {

  bool help;
  bool error;

  bool a_narrower;
  int mode;
  int m, n, k, l, iterations;
  int g;
  float alpha, beta;

  Options():
    help(false),
    error(false),
    m(5120), n(4096), k(4096), l(1), iterations(20),
    g(128), mode(2), a_narrower(false),
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
    cmd.get_cmd_line_argument("g", g, 128);
    cmd.get_cmd_line_argument("mode", mode, 2);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("iterations", iterations, 100);
    if (cmd.check_cmd_line_flag("a_narrower")) {
      a_narrower = true;
    }
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "BMG GEMM Mixed Type Example\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --l=<int>                   Sets the L extent (batch count) of the GEMM\n"
      << "  --g=<int>                   The size of each group for the scales and zeros. To broadcast a vector of scales or zeros, set the group size to K.\n"
      << "  --mode=<int>                The mode to run the gemm. 0 is Convert Only, 1 is Convert and Scale, 2 is Convert and Scale with Zero Point\n"
      << "  --a_narrower                If specified, make A the narrower type (B is narrower by default).\n"
      << "  --alpha=<s32>               Epilogue scalar alpha\n"
      << "  --beta=<s32>                Epilogue scalar beta\n\n"
      << "  --iterations=<int>          Iterations\n\n";

    return out;
  }
};

// Factory structs to factor out boilerplate code
namespace helpers{
using namespace cutlass::gemm;
template <typename DispatchPolicy, typename TileShape, typename LayoutA,
          typename LayoutB, typename TiledMMA, typename GmemTiledCopyA,
          typename GmemTiledCopyB>
struct MixedCollectiveMmaBuilder {

  template <typename ElementA, typename ElementB>
  using CollectiveMma = collective::CollectiveMma<
      DispatchPolicy, TileShape, ElementA, LayoutA, ElementB, LayoutB, TiledMMA,
      GmemTiledCopyA, void, void, cute::identity, GmemTiledCopyB, void, void,
      cute::identity>;
};

template <typename ProblemShape, typename CollectiveEpilogue>
struct MixedGemmUniversalAdapterBuilder {
  template <typename CollectiveMainloop>
  using GemmUniversalAdapter =
      device::GemmUniversalAdapter<kernel::GemmUniversal<
          ProblemShape, CollectiveMainloop, CollectiveEpilogue>>;
};
}
///////////////////////////////////////////////////////////////////////////////////////////////////

template <
  class Gemm
>
struct ExampleRunner {

  using CollectiveMainloop = typename Gemm::CollectiveMainloop;
  using CollectiveEpilogue = typename Gemm::CollectiveEpilogue;

  static constexpr bool AIsNarrower = CollectiveMainloop::IsATransformed;

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
  using ElementMMA = std::conditional_t<AIsNarrower, ElementB, ElementA>;
  using ElementQuant = std::conditional_t<AIsNarrower, ElementA, ElementB>;

  using ElementScale = typename CollectiveMainloop::NonVoidElementScale;
  using ElementZero = typename CollectiveMainloop::NonVoidElementZero;
  // Scale and Zero share a stride since the layout and shapes must be the same.
  using StrideScale = typename CollectiveMainloop::StrideScale;
  using StrideZero = StrideScale; 

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
  StrideScale stride_S;

  uint64_t seed = 0;

  cutlass::DeviceAllocation<ElementA> block_A;
  cutlass::DeviceAllocation<ElementB> block_B;
  cutlass::DeviceAllocation<ElementMMA> block_A_dq; // Dequantized copy of A for validation
  cutlass::DeviceAllocation<ElementMMA> block_B_dq; // Dequantized copy of B for validation
  cutlass::DeviceAllocation<ElementScale> block_scale;
  cutlass::DeviceAllocation<ElementZero> block_zero;
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

    using GmemTiledCopyA = XE_2D_U16x32x32_LD_N;
    using GmemTiledCopyB = XE_2D_U16x32x32_LD_V;

    // Workgroup-level tile
    using TileShape = Shape<_256, _256, _32>;

    using TiledMma =
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<TileShape>,
                                      Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA;

    constexpr int PipelineStages = 3;
    using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16<PipelineStages>;
    using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;

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
            ElementMMA,
            cutlass::gemm::TagToStrideA_t<LayoutA>,
            ElementMMA,
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
      {block_A_dq.get(), stride_A, block_B_dq.get(), stride_B},
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

  template <class Element>
  bool initialize_scale(
    cutlass::DeviceAllocation<Element>& block, 
    Options const& options) {

    if (options.mode == GemmMode::ConvertOnly) {
      // No scales, so just initialize with 1 so we can use the same kernel to dequantize the data.
      std::vector<Element> stage(block.size(), Element(1.0f));
      block.copy_from_host(stage.data());
    } 
    else {
      float elt_max_f = float(cutlass::platform::numeric_limits<ElementQuant>::max());
      const float max_dequant_val = 4.f;
      const float min_dequant_val = 0.5f;

      float scope_max(max_dequant_val / elt_max_f);
      float scope_min(min_dequant_val / elt_max_f);

      cutlass::reference::device::BlockFillRandomUniform(
        block.get(), block.size(), seed, Element(scope_max), Element(scope_min));
    }
    return true;
  }

  template <class Element>
  bool initialize_zero(
    cutlass::DeviceAllocation<Element>& block,
    Options const& options) {
    
    if (options.mode == GemmMode::ConvertAndScaleWithZeroPoint) {
      cutlass::reference::device::BlockFillRandomUniform(
        block.get(), block.size(), seed, Element(2.0f), Element(-2.0f));
    } else {
      // No bias, so just initialize with 0 so we can use the same kernel to dequantize the data.
      std::vector<Element> stage(block.size(), Element(0.0f));
      block.copy_from_host(stage.data());
    }
    return true;
  }

  /// Initialize operands to be used in the GEMM and reference GEMM
  void initialize(Options const& options) {
    auto [M, N, K, L] = ProblemShapeType{options.m, options.n, options.k, options.l};

    const int scale_k = cute::ceil_div(options.k, options.g);
    const int dq_mn_size = AIsNarrower ? options.m : options.n;
    auto shape_A = cute::make_shape(M, K, L);
    auto shape_B = cute::make_shape(N, K, L);
    auto shape_CD = cute::make_shape(M, N, L);
    auto shape_scale_zero = cute::make_shape(dq_mn_size, scale_k, L);

    stride_A = cutlass::make_cute_packed_stride(StrideA{}, shape_A);
    stride_B = cutlass::make_cute_packed_stride(StrideB{}, shape_B);
    stride_C = cutlass::make_cute_packed_stride(StrideC{}, shape_CD);
    stride_D = cutlass::make_cute_packed_stride(StrideD{}, shape_CD);
    stride_S = cutlass::make_cute_packed_stride(StrideScale{}, shape_scale_zero);

    block_A.reset(static_cast<std::size_t>(M) * K * L);
    block_A_dq.reset(static_cast<std::size_t>(M) * K * L);
    block_B.reset(static_cast<std::size_t>(K) * N * L);
    block_B_dq.reset(static_cast<std::size_t>(K) * N * L);
    block_C.reset(static_cast<std::size_t>(M) * N * L);
    block_D.reset(static_cast<std::size_t>(M) * N * L);
    block_ref_D.reset(static_cast<std::size_t>(M) * N * L);
    block_scale.reset(static_cast<std::size_t>(scale_k) * L * dq_mn_size);
    block_zero.reset(static_cast<std::size_t>(scale_k) * L * dq_mn_size);

    initialize_mixed_dtype_block(block_A, block_A_dq, seed + 2023);
    initialize_mixed_dtype_block(block_B, block_B_dq, seed + 2022);
    initialize_block(block_C, seed + 2021);

    initialize_scale(block_scale, options);
    initialize_zero(block_zero, options);

    auto layout_A = make_layout(shape_A, stride_A);
    auto layout_B = make_layout(shape_B, stride_B);
    auto layout_scale_zero = make_layout(shape_scale_zero, stride_S);

    // Note that we are overwriting the relevant `block_X_dq` here, both were
    // filled by initialize_mixed_dtype_block above
    if constexpr (AIsNarrower) {
      dequantize(block_A_dq.get(), block_A.get(), layout_A,
                        block_scale.get(), block_zero.get(), layout_scale_zero,
                        options.g);
    } else {
      dequantize(block_B_dq.get(), block_B.get(), layout_B,
                        block_scale.get(), block_zero.get(), layout_scale_zero,
                        options.g);
    }
  }

  cutlass::Status run(const Options& options, const cutlass::KernelHardwareInfo& hw_info) {
    ProblemShapeType problem_size = ProblemShapeType{options.m, options.n, options.k, options.l};

    initialize(options);

    typename Gemm::GemmKernel::Arguments arguments{
        cutlass::gemm::GemmUniversalMode::kGemm,
        problem_size,
        {block_A.get(), stride_A, block_B.get(), stride_B, block_scale.get(),
         stride_S, options.g, block_zero.get()},
        {{options.alpha, options.beta},
         block_C.get(),
         stride_C,
         block_D.get(),
         stride_D},
        hw_info};

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

    syclcompat::wait();

    // Verify that the result is correct
    bool passed = verify(options);
    std::cout << "Disposition: " << (passed ? "Passed" : "Failed") << std::endl;

    if(!passed) return cutlass::Status::kErrorInternal;

    if (options.iterations > 0) {
      GPU_Clock timer;
      timer.start();
      for (int i = 0; i < options.iterations; ++i) {
        gemm_op.run();
      }
      syclcompat::wait();

      float cute_time = timer.seconds() / options.iterations;
      double tflops = (2.0 * options.m * options.n * options.k * options.l) * 1e-12;
      std::cout << "Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << 'x' << options.l << std::endl;
      printf("Cutlass GEMM Performance:     [%4.3f]TFlop/s  (%6.4f)ms\n", tflops / cute_time, cute_time*1000);
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

  bool passed;

  // The code section below describes datatype for input, output matrices and computation between
  // elements in input matrices.
  using ElementAccumulator = float;      // <- data type of accumulator
  using ElementComputeEpilogue = float;  // <- data type of epilogue operations
  using ElementInputA = QuantType;       // <- data type of elements in input matrix A
  using ElementInputB = MmaType;         // <- data type of elements in input matrix B
  using ElementOutput = float;           // <- data type of elements in output matrix D

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using ElementZero = MmaType;
  using ElementScale = MmaType;

  // Note: XE_2D_U18x32x32_LD_N is incompatible with our bf16 MMA atoms
  using GmemTiledCopyA = XE_2D_U8x32x32_LD_V;  // U8  (1-byte) block copy for A (narrower type)
  using GmemTiledCopyB = XE_2D_U16x32x32_LD_V; // U16 (2-byte) block copy for B (wider type)
  static_assert(sizeof(ElementInputA) == 1, "ElementA width must match GmemTiledCopyA U8");

  // Workgroup-level tile
  using TileShape = Shape<_256, _256, _32>;

  // Although this is a mixed type example, the actual MMA accepts bf16 input for both A and B:
  using TiledMma =                    // M=8,N=16,K=16, D=f32,A=bf16,B=bf16,C=f32
      typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<TileShape>,
                                    Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA;

  constexpr int PipelineStages = 3; // prefetch 3 iters of data for A and B
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16MixedPrecision<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;

  // Default (Linear Combination) epilogue
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

  // Use the helpers to avoid template arg repetition
  using GemmAdapterBuilder = helpers::MixedGemmUniversalAdapterBuilder<Shape<int, int, int, int>, CollectiveEpilogue>;

  using MixedBuilderQuantA =
      helpers::MixedCollectiveMmaBuilder<GEMMDispatchPolicy, TileShape,
                                cutlass::gemm::TagToStrideA_t<LayoutA>,
                                cutlass::gemm::TagToStrideB_t<LayoutB>,
                                TiledMma, GmemTiledCopyA, GmemTiledCopyB>;

  using MixedBuilderQuantB =
      helpers::MixedCollectiveMmaBuilder<GEMMDispatchPolicy, TileShape,
                                cutlass::gemm::TagToStrideA_t<LayoutA>,
                                cutlass::gemm::TagToStrideB_t<LayoutB>,
                                TiledMma, GmemTiledCopyB, GmemTiledCopyA>;

  // A-narrow Mainloop & GemmUniversalAdapter
  using MainloopAConvertOnly =
      MixedBuilderQuantA::CollectiveMma<cute::tuple<ElementInputA>,
                                        ElementInputB>;
  using GemmAConvertOnly =
      GemmAdapterBuilder::GemmUniversalAdapter<MainloopAConvertOnly>;

  using MainloopAConvertAndScale = MixedBuilderQuantA::CollectiveMma<
      cute::tuple<ElementInputA, ElementScale>, ElementInputB>;
  using GemmAConvertAndScale =
      GemmAdapterBuilder::GemmUniversalAdapter<MainloopAConvertAndScale>;

  using MainloopAConvertAndScaleWithZeroPoint =
      MixedBuilderQuantA::CollectiveMma<
          cute::tuple<ElementInputA, ElementScale, ElementZero>, ElementInputB>;
  using GemmAConvertAndScaleWithZeroPoint =
      GemmAdapterBuilder::GemmUniversalAdapter<
          MainloopAConvertAndScaleWithZeroPoint>;

  // B-narrow Mainloop & GemmUniversalAdapter
  using MainloopBConvertOnly =
      MixedBuilderQuantB::CollectiveMma<ElementInputB,
                                        cute::tuple<ElementInputA>>;
  using GemmBConvertOnly =
      GemmAdapterBuilder::GemmUniversalAdapter<MainloopBConvertOnly>;

  using MainloopBConvertAndScale = MixedBuilderQuantB::CollectiveMma<
      ElementInputB, cute::tuple<ElementInputA, ElementScale>>;
  using GemmBConvertAndScale =
      GemmAdapterBuilder::GemmUniversalAdapter<MainloopBConvertAndScale>;

  using MainloopBConvertAndScaleWithZeroPoint =
      MixedBuilderQuantB::CollectiveMma<
          ElementInputB, cute::tuple<ElementInputA, ElementScale, ElementZero>>;
  using GemmBConvertAndScaleWithZeroPoint =
      GemmAdapterBuilder::GemmUniversalAdapter<
          MainloopBConvertAndScaleWithZeroPoint>;

  if(options.a_narrower){
    std::cout << "Setting A as narrower type" << std::endl;
    if(options.mode ==  GemmMode::ConvertOnly) {
      std::cout << "Running in ConvertOnly mode." << std::endl;
      CUTLASS_CHECK(ExampleRunner<GemmAConvertOnly>{}.run(options, hw_info));
    }else if(options.mode == GemmMode::ConvertAndScale){
      std::cout << "Running in ConvertAndScale mode." << std::endl;
      CUTLASS_CHECK(ExampleRunner<GemmAConvertAndScale>{}.run(options, hw_info));
    }else{
      std::cout << "Running in ConvertAndScaleWithZeroPoint mode." << std::endl;
      CUTLASS_CHECK(ExampleRunner<GemmAConvertAndScaleWithZeroPoint>{}.run(options, hw_info));
    }
  }else{
    std::cout << "Setting B as narrower type" << std::endl;
    if(options.mode ==  GemmMode::ConvertOnly) {
      std::cout << "Running in ConvertOnly mode." << std::endl;
      CUTLASS_CHECK(ExampleRunner<GemmBConvertOnly>{}.run(options, hw_info));
    }else if(options.mode == GemmMode::ConvertAndScale){
      std::cout << "Running in ConvertAndScale mode." << std::endl;
      CUTLASS_CHECK(ExampleRunner<GemmBConvertAndScale>{}.run(options, hw_info));
    }else{
      std::cout << "Running in ConvertAndScaleWithZeroPoint mode." << std::endl;
      CUTLASS_CHECK(ExampleRunner<GemmBConvertAndScaleWithZeroPoint>{}.run(options, hw_info));
    }
  }

  return 0;
}
