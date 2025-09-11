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
\brief CUTLASS Intel BMG Gemm FP8 with optinal quantization.
   The GemmMode enum describes the 3 modes of operation:

  - ConvertOnly:                   Narrower type is simply converted to the wider type before MMA
  - ConvertAndScale:               Narrower type is converted to wider type, then scaled

  - Requirements:
      - dequantization group size (options.g) must be multiple of k-block size
      - scales & zeros must be MN-major

    To build & run this example (from your build dir):

      $ ninja 08_bmg_gemm_f8_scaling
      $ ./examples/sycl/08_bmg_gemm_f8/08_bmg_gemm_f8_scaling

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

enum GemmMode {
  ConvertOnly,
  ConvertAndScale
};

///////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

  bool help;
  bool error;

  int mode;
  int m, n, k, l, iterations;
  int g;
  float alpha, beta;

  Options():
    help(false),
    error(false),
    m(5120), n(4096), k(4096), l(1), iterations(20),
    g(128), mode(0),
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
    cmd.get_cmd_line_argument("mode", mode, 1);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("iterations", iterations, 100);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "BMG GEMM Example\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --l=<int>                   Sets the L extent (batch count) of the GEMM\n"
      << "  --g=<int>                   The size of each group for the scales and zeros. To broadcast a vector of scales or zeros, set the group size to K.\n"
      << "  --mode=<int>                The mode to run the gemm. 0 is Convert Only, 1 is Convert and Scale\n"
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

  using CollectiveMainloop = typename Gemm::CollectiveMainloop;
  using CollectiveEpilogue = typename Gemm::CollectiveEpilogue;

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
  using ElementMMA = typename CollectiveMainloop::ElementMMA;
  using ElementQuant = ElementA;

  using ElementScaleA = typename CollectiveMainloop::NonVoidElementScaleA;
  using ElementScaleB = typename CollectiveMainloop::NonVoidElementScaleB;

  using ElementZeroA = typename CollectiveMainloop::NonVoidElementZeroA;
  using ElementZeroB = typename CollectiveMainloop::NonVoidElementZeroB;

  using StrideScaleA = typename CollectiveMainloop::NonVoidStrideScaleA;
  using StrideScaleB = typename CollectiveMainloop::NonVoidStrideScaleB;

  using StrideZeroA = typename CollectiveMainloop::NonVoidStrideZeroA;
  using StrideZeroB = typename CollectiveMainloop::NonVoidStrideZeroB;

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
  StrideScaleA stride_SA;
  StrideScaleB stride_SB;
  StrideZeroA stride_ZA;
  StrideZeroB stride_ZB;

  uint64_t seed = 0;

  cutlass::DeviceAllocation<ElementA> block_A;
  cutlass::DeviceAllocation<ElementB> block_B;
  cutlass::DeviceAllocation<ElementMMA> block_A_dq; // Dequantized copy of A for validation
  cutlass::DeviceAllocation<ElementMMA> block_B_dq; // Dequantized copy of B for validation
  cutlass::DeviceAllocation<ElementC> block_C;
  cutlass::DeviceAllocation<ElementScaleA> block_scaleA;
  cutlass::DeviceAllocation<ElementScaleB> block_scaleB;
  cutlass::DeviceAllocation<ElementZeroA> block_zeroA;
  cutlass::DeviceAllocation<ElementZeroB> block_zeroB;
  cutlass::DeviceAllocation<ElementOutput> block_D;
  cutlass::DeviceAllocation<ElementOutput> block_ref_D;

  //
  // Methods
  //
  template <typename SrcT, typename DstT>
  void convert_fp8_to_fp16(const SrcT* d_src, DstT* d_dst, size_t size) {
    syclcompat::get_default_queue().parallel_for(size, [=](auto indx) {
      d_dst[indx] = static_cast<DstT>(d_src[indx]);
    }).wait();
  }

  bool verify(const Options &options) {
    using GmemTiledCopyA = XE_2D_U16x32x32_LD_N;
    using GmemTiledCopyB = XE_2D_U16x16x16_LD_V;

    // Workgroup-level tile
    using TileShape = Shape<_256, _256, _32>;

    using TiledMma =
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, Layout<TileShape>,
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
      const float elt_max_f = float(cutlass::platform::numeric_limits<ElementQuant>::max());
      // Need to fix max_dequant_val and min_dequant_val?
      const float max_dequant_val = elt_max_f * 0.25f;
      const float min_dequant_val = 0.5f;
      const float scale_max = max_dequant_val / elt_max_f;
      const float scale_min = min_dequant_val / elt_max_f;
      cutlass::reference::device::BlockFillRandomUniform(
         block.get(), block.size(), seed, Element(scale_max), Element(scale_min));
    }
    return true;
  }

  template <class Element>
  bool initialize_zero(
    cutlass::DeviceAllocation<Element>& block,
    Options const& options) {

    // No bias, so just initialize with 0 so we can use the same kernel to dequantize the data.
    std::vector<Element> stage(block.size(), Element(0.0f));
    block.copy_from_host(stage.data());

    return true;
  }

  /// Initialize operands to be used in the GEMM and reference GEMM
  void initialize(Options const& options) {
    auto [M, N, K, L] = ProblemShapeType{options.m, options.n, options.k, options.l};

    const int scale_k = cute::ceil_div(options.k, options.g);
    auto shape_A = cute::make_shape(M, K, L);
    auto shape_B = cute::make_shape(N, K, L);
    auto shape_CD = cute::make_shape(M, N, L);
    auto shape_scale_zeroA = cute::make_shape(options.m, scale_k, L);
    auto shape_scale_zeroB = cute::make_shape(options.n, scale_k, L);

    stride_A = cutlass::make_cute_packed_stride(StrideA{}, shape_A);
    stride_B = cutlass::make_cute_packed_stride(StrideB{}, shape_B);
    stride_C = cutlass::make_cute_packed_stride(StrideC{}, shape_CD);
    stride_D = cutlass::make_cute_packed_stride(StrideD{}, shape_CD);
    stride_SA = cutlass::make_cute_packed_stride(StrideScaleA{}, shape_scale_zeroA);
    stride_SB = cutlass::make_cute_packed_stride(StrideScaleB{}, shape_scale_zeroB);
    stride_ZA = cutlass::make_cute_packed_stride(StrideZeroA{}, shape_scale_zeroA);
    stride_ZB = cutlass::make_cute_packed_stride(StrideZeroB{}, shape_scale_zeroB);

    block_A.reset(static_cast<std::size_t>(M) * K * L);
    block_A_dq.reset(static_cast<std::size_t>(M) * K * L);
    block_B.reset(static_cast<std::size_t>(K) * N * L);
    block_B_dq.reset(static_cast<std::size_t>(K) * N * L);
    block_C.reset(static_cast<std::size_t>(M) * N * L);
    block_D.reset(static_cast<std::size_t>(M) * N * L);
    block_ref_D.reset(static_cast<std::size_t>(M) * N * L);
    block_scaleA.reset(static_cast<std::size_t>(scale_k) * L * M);
    block_scaleB.reset(static_cast<std::size_t>(scale_k) * L * N);
    block_zeroA.reset(static_cast<std::size_t>(scale_k) * L * M);
    block_zeroB.reset(static_cast<std::size_t>(scale_k) * L * N);

    initialize_block(block_A, seed + 2023);
    initialize_block(block_B, seed + 2022);
    initialize_block(block_C, seed + 2021);

    convert_fp8_to_fp16<ElementA, half_t>(
        block_A.get(),
        block_A_dq.get(),
        block_A.size()
    );
    convert_fp8_to_fp16<ElementB, half_t>(
        block_B.get(),
        block_B_dq.get(),
        block_B.size()
    );

    initialize_scale(block_scaleA, options);
    initialize_zero(block_zeroA, options);
    initialize_scale(block_scaleB, options);
    initialize_zero(block_zeroB, options);

    auto layout_A = make_layout(shape_A, stride_A);
    auto layout_B = make_layout(shape_B, stride_B);
    auto layout_scale_zeroA = make_layout(shape_scale_zeroA, stride_SA);
    auto layout_scale_zeroB = make_layout(shape_scale_zeroB, stride_SB);

    // Note that we are overwriting the relevant `block_X_dq` here, both were
    // filled by initialize_mixed_dtype_block above
    cutlass::dequantize(block_A_dq.get(), block_A.get(), layout_A,
                        block_scaleA.get(), block_zeroA.get(), layout_scale_zeroA, layout_scale_zeroA,
                        options.g);
    cutlass::dequantize(block_B_dq.get(), block_B.get(), layout_B,
                        block_scaleB.get(), block_zeroB.get(), layout_scale_zeroB, layout_scale_zeroB,
                        options.g);
  }
  
  cutlass::Status run(const Options& options, const cutlass::KernelHardwareInfo& hw_info) {
    ProblemShapeType problem_size = ProblemShapeType{options.m, options.n, options.k, options.l};

    initialize(options);

    typename Gemm::GemmKernel::Arguments arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      problem_size,
      {block_A.get(), stride_A, block_B.get(), stride_B,
      block_scaleA.get(), stride_SA, block_scaleB.get(), stride_SB,
      nullptr, stride_SA, nullptr, stride_SB,
      options.g},
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
      if constexpr (std::is_same_v<ElementA, float_e4m3_t>) {
        std::cout << "Datatype: float_e4m3_t"<< std::endl;
      } else if constexpr (std::is_same_v<ElementA, float_e5m2_t>) {
        std::cout << "Datatype: float_e5m2_t"<< std::endl;
      }
      printf("Cutlass GEMM Performance:     [%4.3f]TFlop/s  (%6.4f)ms\n", tflops / cute_time, cute_time*1000);
    }

    return cutlass::Status::kSuccess;
  }

};

template<typename ElementType>
int launcher(Options& options)
{
  //
  // Run examples
  //

  cutlass::KernelHardwareInfo hw_info;

  hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);

  bool passed;

  using MmaType = half_t;
  using QuantType = ElementType;

  using ElementAccumulator = float;
  using ElementComputeEpilogue = float;
  using ElementInputA = QuantType;
  using ElementInputB = QuantType;
  using ElementOutput = float;

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using ElementScale = MmaType;

  using StrideScale = cute::Stride<_1, int64_t, int64_t>;

  using GmemTiledCopyA = XE_2D_U8x32x32_LD_N;
  using GmemTiledCopyB = XE_2D_U8x32x32_LD_V;

  using TileShape = Shape<_256, _256, _32>;

  // TODO: Consider smaller tile size to reduce register pressure
  using TiledMma =
      typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, Layout<TileShape>,
      Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA;

  constexpr int PipelineStages = 2;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16FP8Scaling<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;

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

  using ConvertOnlyCollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
          GEMMDispatchPolicy,
          TileShape,
          cute::tuple<ElementInputA>,
          cutlass::gemm::TagToStrideA_t<LayoutA>,
          cute::tuple<ElementInputB>,
          cutlass::gemm::TagToStrideB_t<LayoutB>,
          TiledMma,
          GmemTiledCopyA, void, void, cute::identity,
          GmemTiledCopyB, void, void, cute::identity
  >;

  using ConvertAndScaleCollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
          GEMMDispatchPolicy,
          TileShape,
          cute::tuple<ElementInputA, ElementScale, StrideScale>,
          cutlass::gemm::TagToStrideA_t<LayoutA>,
          cute::tuple<ElementInputB, ElementScale, StrideScale>,
          cutlass::gemm::TagToStrideB_t<LayoutB>,
          TiledMma,
          GmemTiledCopyA, void, void, cute::identity,
          GmemTiledCopyB, void, void, cute::identity
  >;

  if(options.mode ==  GemmMode::ConvertOnly) {
    std::cout << "Running in ConvertOnly mode." << std::endl;
    using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int, int, int, int>,
      ConvertOnlyCollectiveMainloop,
      CollectiveEpilogue
    >;
    using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
    CUTLASS_CHECK(ExampleRunner<Gemm>{}.run(options, hw_info));
  } else if(options.mode == GemmMode::ConvertAndScale){
    std::cout << "Running in ConvertAndScale mode." << std::endl;
    using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int, int, int, int>,
      ConvertAndScaleCollectiveMainloop,
      CollectiveEpilogue
    >;
    using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
    CUTLASS_CHECK(ExampleRunner<Gemm>{}.run(options, hw_info));
  }
  return 0;
}

int main(int argc, const char** argv) {
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
  launcher<cutlass::float_e5m2_t>(options);
  launcher<cutlass::float_e4m3_t>(options);
  return 0;
}
