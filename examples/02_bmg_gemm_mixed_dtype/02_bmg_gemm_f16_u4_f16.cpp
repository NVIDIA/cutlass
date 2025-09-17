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
    \brief Mixed Precision BMG Gemm Example

 This example demonstrates how to dispatch a mixed precision GEMM on BMG, with optional dequantization.
 The GemmMode enum describes the 3 modes of operation:

 - ConvertOnly: Narrower type is simply converted to the wider type before MMA
 - ConvertAndScale:   Narrower type is converted to wider type, then scaled
 - ConvertAndScaleWithZeroPoint:   Narrower type is converted to wider type, then scaled and shifted by zero point
 - Limitations:
    - group must be multiple of k-block size
    - scales & zeros must be MN-major

 Note: due to a bug in the IGC compiler, it's currently necessary to build this example with the following
 environment variable set:
   export IGC_allowDecompose2DBlockFuncs=0
 To build & run this example (from your build dir):

    $ ninja 02_bmg_gemm_f16_u4_f16
    $ ./examples/sycl/02_bmg_gemm_mixed_dtype/02_bmg_gemm_f16_u4_f16

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

using MmaType = cutlass::half_t;
using QuantType = uint4_t;

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
  using StrideScale = typename CollectiveMainloop::NonVoidStrideScale;
  using StrideZero = typename CollectiveMainloop::NonVoidStrideZero;

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
  StrideZero stride_Z;

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
    using GmemTiledCopyB = XE_2D_U16x16x16_LD_T;

    // Workgroup-level tile
    using TileShape = Shape<_256, _256, _32>;

    using TiledMma =
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, Layout<TileShape>,
                                      Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA;

    constexpr int PipelineStages = 3;
    using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16<PipelineStages>;
    using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;

    using EpilogueOp = cutlass::epilogue::fusion::LinearCombination<ElementAccumulator, ElementCompute,
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
            XE_2D_U16x8x16_ST_N,
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

  template <
  class QuantizedElement,
  class DequantizedElement,
  class OperandLayout,
  class ElementScale,
  class ElementZero,
  class ScaleLayout,
  class ZeroLayout>
  static void dequantize_B(DequantizedElement* dq_buffer,
                       QuantizedElement const* q_buffer,
                       OperandLayout const operand_layout,
                       ElementScale const* scale_buffer,
                       ElementZero const* zero_buffer,
                       ScaleLayout const scale_layout,
                       ZeroLayout const zero_layout,
                       int const group_size) {
    std::vector<uint8_t> dst(size(operand_layout) * sizeof_bits_v<DequantizedElement> / 8, 0);
    cutlass::device_memory::copy_to_host(dst.data(), (uint8_t*)dq_buffer, dst.size());

    std::vector<uint8_t> src(size(operand_layout) * sizeof_bits_v<QuantizedElement> / 8, 0);
    cutlass::device_memory::copy_to_host(src.data(), (uint8_t*)q_buffer, src.size());

    std::vector<uint8_t> scale(size(scale_layout) * sizeof_bits_v<ElementScale> / 8, 0);
    cutlass::device_memory::copy_to_host(scale.data(), (uint8_t*)scale_buffer, scale.size());

    std::vector<uint8_t> zero(size(zero_layout) * sizeof_bits_v<ElementZero> / 8, 0);
    cutlass::device_memory::copy_to_host(zero.data(), (uint8_t*)zero_buffer, zero.size());

    syclcompat::wait();

    auto dst_tensor = make_tensor(make_gmem_ptr(reinterpret_cast<DequantizedElement*>(dst.data())), operand_layout);

    auto src_tensor = [&]() {
      if constexpr (sizeof_bits_v<QuantizedElement> < 8) {
        return make_tensor(cute::subbyte_iterator<const QuantizedElement>(src.data()), operand_layout);
      } else {
        return make_tensor(make_gmem_ptr(reinterpret_cast<QuantizedElement const *>(src.data())), operand_layout);
      }
    }();

    auto scale_tensor = make_tensor(make_gmem_ptr(reinterpret_cast<ElementScale const *>(scale.data())), scale_layout);

    auto zero_tensor = [&]() {
      if constexpr (sizeof_bits_v<ElementZero> < 8) {
        auto flatten_tensor = flatten(make_tensor(cute::subbyte_iterator<const ElementZero>(zero.data()), zero_layout));
        static_assert(rank(flatten_tensor.layout()) == 4);
        return make_tensor(flatten_tensor.data(), select<1, 0, 2, 3>(flatten_tensor.layout()));
      } else {
        return make_tensor(make_gmem_ptr(reinterpret_cast<ElementZero const *>(zero.data())), zero_layout);
      }
    }();

    auto N = size<0>(src_tensor);
    auto K = size<1>(src_tensor);
    auto L = size<2>(src_tensor);

    for (int l = 0; l < L; l++) {
      for (int k= 0; k < K; k++) {
        for (int n = 0; n < N; n++) {
          using ret_type = cute::conditional_t<sizeof_bits_v<ElementZero> >= 8, ElementZero, int8_t>;
          ret_type a = [&]() {
            if constexpr (sizeof_bits_v<QuantizedElement> >= 8) {
              return  (ret_type)(src_tensor(n, k, l));
            } else {
              return (ret_type)(src_tensor(n, k, l).get());
            }}();

          ret_type b = [&]() {
            if constexpr (sizeof_bits_v<ElementZero> >= 8) {
              return (ret_type)(zero_tensor(n, k / group_size, l));
            } else {
              auto zero_elements_packed_along_k = get<0>(zero_tensor.shape());
              return (ret_type)(zero_tensor((k / group_size) % zero_elements_packed_along_k, n, k / group_size / zero_elements_packed_along_k, l).get());
            }
          }();

          dst_tensor(n, k, l) = ((ElementScale)(a - b)) * scale_tensor(n, k / group_size, l);
        }
      }
    }

    cutlass::device_memory::copy_to_device(dq_buffer, (DequantizedElement*)(raw_pointer_cast(dst_tensor.data())), dst_tensor.size());
    syclcompat::wait();
  }


  /// Initialize operands to be used in the GEMM and reference GEMM
  void initialize(Options const& options) {
    auto problem_shape = ProblemShapeType{options.m, options.n, options.k, options.l};
    auto& M = cute::get<0>(problem_shape);
    auto& N = cute::get<1>(problem_shape);
    auto& K = cute::get<2>(problem_shape);
    auto& L = cute::get<3>(problem_shape);

    auto zero_elements_packed_along_k = get<0>(StrideZero{});
    const int scale_k = cute::ceil_div(options.k, options.g);
    const int dq_mn_size = AIsNarrower ? options.m : options.n;
    auto shape_A = cute::make_shape(M, K, L);
    auto shape_B = cute::make_shape(N, K, L);
    auto shape_CD = cute::make_shape(M, N, L);
    auto shape_scale = cute::make_shape(dq_mn_size, scale_k, L);
    auto shape_zero = [&]() {
      if constexpr (is_tuple_v<std::remove_reference_t<decltype(cute::get<1>(stride_Z))>>) {
        return cute::make_shape(dq_mn_size, cute::make_shape(zero_elements_packed_along_k, cute::max(1, scale_k / zero_elements_packed_along_k)), L);
      } else {
        return shape_scale;
      }
    }();

    stride_A = cutlass::make_cute_packed_stride(StrideA{}, shape_A);
    stride_B = cutlass::make_cute_packed_stride(StrideB{}, shape_B);
    stride_C = cutlass::make_cute_packed_stride(StrideC{}, shape_CD);
    stride_D = cutlass::make_cute_packed_stride(StrideD{}, shape_CD);
    stride_S = cutlass::make_cute_packed_stride(StrideScale{}, shape_scale);
    stride_Z = [&]() {
      if constexpr (is_tuple_v<std::remove_reference_t<decltype(cute::get<1>(stride_Z))>>) {
        return make_stride(Int<zero_elements_packed_along_k>{}, make_stride(_1{}, int64_t(zero_elements_packed_along_k * dq_mn_size)), int64_t(dq_mn_size * scale_k));
      } else {
        return stride_S;
      }
    }();

    block_A.reset(static_cast<std::size_t>(M) * K * L);
    block_A_dq.reset(static_cast<std::size_t>(M) * K * L);
    block_B.reset(static_cast<std::size_t>(K) * N * L);
    block_B_dq.reset(static_cast<std::size_t>(K) * N * L);
    block_C.reset(static_cast<std::size_t>(M) * N * L);
    block_D.reset(static_cast<std::size_t>(M) * N * L);
    block_ref_D.reset(static_cast<std::size_t>(M) * N * L);
    block_scale.reset(static_cast<std::size_t>(scale_k) * L * dq_mn_size);
    block_zero.reset(static_cast<std::size_t>(scale_k) * L * dq_mn_size);

    initialize_mixed_dtype_block(block_A, block_A_dq, seed + 2022);
    initialize_mixed_dtype_block(block_B, block_B_dq, seed + 2023);

    initialize_block(block_C, seed + 2024);

    initialize_scale(block_scale, options);
    initialize_zero(block_zero, options);

    auto layout_A = make_layout(shape_A, stride_A);
    auto layout_B = make_layout(shape_B, stride_B);
    auto layout_scale = make_layout(shape_scale, stride_S);
    auto layout_zero = make_layout(shape_zero, stride_Z);

    // Note that we are overwriting the relevant `block_X_dq` here, both were
    // filled by initialize_mixed_dtype_block above
    if constexpr (AIsNarrower) {
      dequantize(block_A_dq.get(), block_A.get(), layout_A,
                        block_scale.get(), block_zero.get(), layout_scale, layout_zero,
                        options.g);
    } else {
      dequantize_B(block_B_dq.get(), block_B.get(), layout_B,
                        block_scale.get(), block_zero.get(), layout_scale, layout_zero,
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
         stride_S,  block_zero.get(), stride_Z, options.g},
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

    float total_time = 0.f;

    double tflops = (2.0 * options.m * options.n * options.k * options.l) * 1e-12;

    std::cout << "Problem Size(mnk): " << options.m << 'x' << options.n << 'x' << options.k << 'x' << options.l << std::endl;

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

  // The KernelHardwareInfo struct holds the number of EUs on the GPU with a given device ID. This
  // information is used by the underlying kernel.
  cutlass::KernelHardwareInfo hw_info;

  // Change device_id to another value if you are running on a machine with multiple GPUs and wish
  // to use a GPU other than that with device ID 0.
  hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);

  // The code section below describes datatype for input, output matrices and computation between
  // elements in input matrices.
  using ElementAccumulator = float;      // <- data type of accumulator
  using ElementComputeEpilogue = float;  // <- data type of epilogue operations
  using ElementInputA = uint4_t;         // <- data type of elements in input matrix A
  using ElementInputB = half_t;          // <- data type of elements in input matrix B
  using ElementOutput = half_t;          // <- data type of elements in output matrix D

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using ElementZero = int4_t;
  using ElementScale = half_t;

  using StrideScale = cute::Stride<_1, int64_t, int64_t>;
  using StrideZero = cute::Stride<_8, cute::Stride<_1, int64_t>, int64_t>; // int4_t zero point packed 8 elements along K dimension and then along N dimension

  using GmemTiledCopyA = XE_2D_U4x32x16_LD_T;
  using GmemTiledCopyB = XE_2D_U16x16x32_LD_N;

  // Workgroup-level tile
  using TileShape = Shape<_16, _64, _64>;

  using TiledMma =
      typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, Layout<TileShape>,
                                    Layout<Shape<_1, _2, _1>, Stride<_2, _1, _0>>>::TiledMMA;

  constexpr int PipelineStages = 3;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16MixedPrecision<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;

  using EpilogueOp = cutlass::epilogue::fusion::LinearCombination<ElementAccumulator, ElementComputeEpilogue,
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
          XE_2D_U16x8x16_ST_N,
          void, void>;

  // Use the helpers to avoid template arg repetition
  using GemmAdapterBuilder = typename helpers::MixedGemmUniversalAdapterBuilder<Shape<int, int, int, int>, CollectiveEpilogue>;

  if(options.a_narrower){
    // TODO: this feature not support now
    std::cout << "Not support setting A as narrower type for int4 now." << std::endl;
  } else {
    std::cout << "Setting B as narrower type" << std::endl;
    using MixedBuilderQuant = helpers::MixedCollectiveMmaBuilder<GEMMDispatchPolicy, TileShape,
                                  cutlass::gemm::TagToStrideA_t<LayoutA>,
                                  cutlass::gemm::TagToStrideB_t<LayoutB>,
                                  TiledMma, GmemTiledCopyB, GmemTiledCopyA>;
    if(options.mode ==  GemmMode::ConvertOnly) {
      std::cout << "Running in ConvertOnly mode." << std::endl;
      using MainloopConvertOnly = MixedBuilderQuant::template CollectiveMma<ElementInputB, cute::tuple<ElementInputA>>;
      using GemmConvertOnly = GemmAdapterBuilder::template GemmUniversalAdapter<MainloopConvertOnly>;
      CUTLASS_CHECK(ExampleRunner<GemmConvertOnly>{}.run(options, hw_info));
    }else if(options.mode == GemmMode::ConvertAndScale){
      std::cout << "Running in ConvertAndScale mode." << std::endl;
      using MainloopConvertAndScale = MixedBuilderQuant::template CollectiveMma<
            ElementInputB, cute::tuple<ElementInputA, ElementScale, StrideScale>>;
      using GemmConvertAndScale = GemmAdapterBuilder::template GemmUniversalAdapter<MainloopConvertAndScale>;
      CUTLASS_CHECK(ExampleRunner<GemmConvertAndScale>{}.run(options, hw_info));
    }else{
      std::cout << "Running in ConvertAndScaleWithZeroPoint mode." << std::endl;
      using MainloopConvertAndScaleWithZeroPoint = MixedBuilderQuant::template CollectiveMma<
            ElementInputB, cute::tuple<ElementInputA, ElementScale, StrideScale, ElementZero, StrideZero>>;
      using GemmConvertAndScaleWithZeroPoint = GemmAdapterBuilder::template GemmUniversalAdapter<MainloopConvertAndScaleWithZeroPoint>;
      CUTLASS_CHECK(ExampleRunner<GemmConvertAndScaleWithZeroPoint>{}.run(options, hw_info));
    }
  }
}
