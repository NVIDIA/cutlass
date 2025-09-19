/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
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
    \brief Mixed Precision BMG Grouped Gemm Example Runner
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

#include <cfloat>
using namespace cute;

///////////////////////////////////////////////////////////////////////////////////////////////////

enum GemmMode {
  ConvertOnly,
  ConvertAndScale,
  ConvertAndScaleWithZeroPoint
};

using ProblemShape = cutlass::gemm::GroupProblemShape<Shape<int,int,int>>; // <M,N,K> per group

// Command line options parsing
struct Options {

  bool help;
  bool error;

  bool a_narrower;
  int mode;
  int m, n, k, l, iterations, groups;
  int g;
  float alpha, beta;
  std::vector<typename ProblemShape::UnderlyingProblemShape> problem_sizes_host;

  Options(): help(false), error(false), m(5120), n(4096), k(4096), l(1), iterations(20),
    g(128), groups(2), mode(2), a_narrower(false), alpha(FLT_MAX), beta(FLT_MAX) {

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
    cmd.get_cmd_line_argument("l", l, 1);
    cmd.get_cmd_line_argument("g", g, 128);
    cmd.get_cmd_line_argument("groups", groups, 2);
    cmd.get_cmd_line_argument("mode", mode, 2);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("iterations", iterations, 100);
    if (cmd.check_cmd_line_flag("a_narrower")) {
      a_narrower = true;
    }
    assert(groups > 0);
    problem_sizes_host.clear();
    problem_sizes_host.reserve(groups);
    for(int i = 0; i < groups; i++) {
      problem_sizes_host.push_back({m, n, k});
    }
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "BMG Grouped GEMM Mixed Type Example\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --l=<int>                   Sets the L extent (batch count) of the GEMM\n"
      << "  --g=<int>                   The size of each group for the scales and zeros. To broadcast a vector of scales or zeros, set the group size to K.\n"
      << "  --groups=<int>              Sets the number of individual GEMM problems for Grouped GEMM\n"
      << "  --mode=<int>                The mode to run the gemm. 0 is Convert Only, 1 is Convert and Scale, 2 is Convert and Scale with Zero Point\n"
      << "  --a_narrower                If specified, make A the narrower type (B is narrower by default).\n"
      << "  --alpha=<s32>               Epilogue scalar alpha\n"
      << "  --beta=<s32>                Epilogue scalar beta\n\n"
      << "  --iterations=<int>          Iterations\n\n";

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
    uint64_t flop = static_cast<uint64_t>(2) * static_cast<uint64_t>(fmas);
    double gflop = double(flop) / double(1.0e9);
    return gflop / runtime_s;
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
            ProblemShape, CollectiveMainloop, CollectiveEpilogue, GroupScheduler>>;
  };

  template <typename Element>
  struct MMAOp;

  template <>
  struct MMAOp<cutlass::bfloat16_t> {
    using type = XE_8x16x16_F32BF16BF16F32_TT;
  };

  template <>
  struct MMAOp<cutlass::half_t> {
    using type = XE_8x16x16_F32F16F16F32_TT;
  };

  template <typename RefLayoutB>
  struct RefTiledCopyB;

  template <>
  struct RefTiledCopyB<cutlass::layout::RowMajor> {
    using type = XE_2D_U16x32x32_LD_V;
  };

  template <>
  struct RefTiledCopyB<cutlass::layout::ColumnMajor> {
    using type = XE_2D_U16x16x16_LD_T;
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

  using StrideA = typename Gemm::GemmKernel::InternalStrideA;
  using StrideB = typename Gemm::GemmKernel::InternalStrideB;
  using StrideC = typename Gemm::GemmKernel::InternalStrideC;
  using StrideD = typename Gemm::GemmKernel::InternalStrideD;

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
  using StrideScale = typename CollectiveMainloop::InternalNonVoidStrideScale;
  using StrideZero = typename CollectiveMainloop::InternalNonVoidStrideZero;

  using ElementC = typename Gemm::ElementC;
  using ElementOutput = typename CollectiveEpilogue::ElementOutput;
  using ElementCompute = typename CollectiveEpilogue::ElementCompute;
  using ElementAccumulator = typename CollectiveEpilogue::ElementAccumulator;

  //
  // Data members
  //

  // Host-side allocations
  std::vector<int64_t> offset_A;
  std::vector<int64_t> offset_B;
  std::vector<int64_t> offset_S;
  std::vector<int64_t> offset_Z;
  std::vector<int64_t> offset_C;
  std::vector<int64_t> offset_D;

  std::vector<StrideA> stride_A_host;
  std::vector<StrideB> stride_B_host;
  std::vector<StrideScale> stride_S_host;
  std::vector<StrideZero> stride_Z_host;
  std::vector<StrideC> stride_C_host;
  std::vector<StrideD> stride_D_host;

  std::vector<ElementAccumulator> alpha_host;
  std::vector<ElementAccumulator> beta_host;

  // Device-side allocations
  cutlass::DeviceAllocation<typename ProblemShape::UnderlyingProblemShape> problem_sizes;

  /// Initialization
  cutlass::DeviceAllocation<StrideA> stride_A;
  cutlass::DeviceAllocation<StrideB> stride_B;
  cutlass::DeviceAllocation<StrideScale> stride_S;
  cutlass::DeviceAllocation<StrideZero> stride_Z;
  cutlass::DeviceAllocation<StrideC> stride_C;
  cutlass::DeviceAllocation<StrideD> stride_D;

  uint64_t seed = 0;

  cutlass::DeviceAllocation<ElementA> block_A;
  cutlass::DeviceAllocation<ElementB> block_B;
  cutlass::DeviceAllocation<ElementMMA> block_A_dq; // Dequantized copy of A for validation
  cutlass::DeviceAllocation<ElementMMA> block_B_dq; // Dequantized copy of B for validation
  cutlass::DeviceAllocation<ElementScale> block_S;
  cutlass::DeviceAllocation<ElementZero> block_Z;
  cutlass::DeviceAllocation<ElementC> block_C;
  cutlass::DeviceAllocation<ElementOutput> block_D;

  cutlass::DeviceAllocation<const ElementA *> ptr_A;
  cutlass::DeviceAllocation<const ElementB *> ptr_B;
  cutlass::DeviceAllocation<const ElementMMA *> ptr_A_dq;
  cutlass::DeviceAllocation<const ElementMMA *> ptr_B_dq;
  cutlass::DeviceAllocation<const ElementScale *> ptr_S;
  cutlass::DeviceAllocation<const ElementZero *> ptr_Z;
  cutlass::DeviceAllocation<const ElementC *> ptr_C;
  cutlass::DeviceAllocation<ElementOutput *> ptr_D;
  cutlass::DeviceAllocation<ElementOutput *> ptr_ref_D;

  // Note, this is an array of pointers to alpha and beta scaling values per group
  cutlass::DeviceAllocation<ElementAccumulator*> alpha_device;
  cutlass::DeviceAllocation<ElementAccumulator*> beta_device;
  cutlass::DeviceAllocation<ElementAccumulator> block_alpha;
  cutlass::DeviceAllocation<ElementAccumulator> block_beta;

  //
  // Methods
  //

  template <typename SrcT, typename DstT>
  void quantize_tensorwise(const SrcT* d_src, DstT* d_dst, const ElementScale* scale, const ElementZero* zero, size_t size, size_t L) {
      SrcT* h_src = new SrcT[size * L];
      ElementScale* scale_h = new ElementScale[L];
      ElementZero* zero_h = new ElementZero[L];
      compat::memcpy(h_src, d_src, size * L * sizeof(SrcT));
      compat::memcpy(scale_h, scale, L * sizeof(ElementScale));
      compat::memcpy(zero_h, zero, L * sizeof(ElementZero));
      
      DstT* h_dst = new DstT[size * L];
      for(size_t j = 0; j < L; ++j) {
        for (size_t i = 0; i < size; ++i) {
            h_dst[i + j * size] = (static_cast<DstT>(h_src[i + j * size]) - zero_h[j]) * scale_h[j];
        }
      }

      compat::memcpy(d_dst, h_dst, size * sizeof(DstT));
  }

  /// Populates a Gemm::Arguments structure from the given commandline options
  auto args_from_options(const Options &options, const cutlass::KernelHardwareInfo& hw_info)
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
    using RasterOrderOptions = typename cutlass::gemm::kernel::detail::PersistentTileSchedulerXeGroup<ProblemShape>::RasterOrderOptions;

    // Per-GEMM problem shape info may only exist on the device.
    return cute::make_tuple(cutlass::gemm::GemmUniversalMode::kGrouped,
                            typename Gemm::GemmKernel::ProblemShape{options.groups, problem_sizes.get(), options.problem_sizes_host.data()},
                            fusion_args, hw_info,
                            typename Gemm::GemmKernel::TileSchedulerArguments{1, RasterOrderOptions::AlongN});

  }

  bool verify(const Options &options) {
      
    //
    // Compute reference output (default gemm kernel w/ ElementA == ElementB)
    //

    using GmemTiledCopyA = XE_2D_U16x32x32_LD_N;
    using GmemTiledCopyB = typename helpers::RefTiledCopyB<LayoutB>::type;

    using TileShape = Shape<_256, _256, _32>;

    using TiledMma =
        typename TiledMMAHelper<MMA_Atom<typename helpers::MMAOp<ElementMMA>::type>, Layout<TileShape>,
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
            typename CollectiveEpilogue::GmemTiledCopyD,
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

    cutlass::KernelHardwareInfo hw_info;

    ElementOutput const epsilon(1e-2f);
    ElementOutput const non_zero_floor(1e-4f);
    bool passed = false;

    for(int i = 0; i < options.groups; i++) {
      Shape<int, int, int, int> problem_size = append<4>(options.problem_sizes_host[i], 1);
      auto M = get<0>(problem_size);
      auto N = get<1>(problem_size);
      auto K = get<2>(problem_size);
      using RefStrideA = cutlass::gemm::TagToStrideA_t<LayoutA>;
      using RefStrideB = cutlass::gemm::TagToStrideB_t<LayoutB>;
      using RefStrideC = cutlass::gemm::TagToStrideC_t<LayoutC>;
      RefStrideA stride_a = cutlass::make_cute_packed_stride(RefStrideA{}, {M, K, 1});
      RefStrideB stride_b = cutlass::make_cute_packed_stride(RefStrideB{}, {N, K, 1});
      RefStrideC stride_c = cutlass::make_cute_packed_stride(RefStrideC{}, {M, N, 1});

      // allocate the reference memory
      cutlass::DeviceAllocation<ElementOutput> block_ref_D;
      block_ref_D.reset(i == options.groups - 1 ? block_D.size() - offset_D[i] : offset_D[i + 1] - offset_D[i]);

      typename GemmRef::Arguments arguments{
        cutlass::gemm::GemmUniversalMode::kGemm,
        problem_size,
        {block_A_dq.get() + offset_A[i], stride_a, block_B_dq.get() + offset_B[i], stride_b},
        {{alpha_host[i], beta_host[i]}, block_C.get() + offset_C[i], stride_c, block_ref_D.get(), stride_c},
        hw_info
      };

      // Run the gemm where the scaling is performed outside of the kernel.
      GemmRef gemm_ref;
      size_t workspace_size = GemmRef::get_workspace_size(arguments);
      cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);
      CUTLASS_CHECK(gemm_ref.can_implement(arguments));
      CUTLASS_CHECK(gemm_ref.initialize(arguments, workspace.get()));
      CUTLASS_CHECK(gemm_ref.run());

      compat::wait();
      // compare_reference
      passed |= cutlass::reference::device::BlockCompareRelativelyEqual(block_ref_D.get(), block_D.get() + offset_D[i], block_ref_D.size(), epsilon, non_zero_floor);
      compat::wait();
    }

    return passed;
  }

  /// Allocates device-side data
  void allocate(const Options &options) {
    int64_t total_elements_A = 0;
    int64_t total_elements_B = 0;
    int64_t total_elements_C = 0;
    int64_t total_elements_D = 0;
    int64_t total_elements_S = 0;
    int64_t total_elements_Z = 0;

    // Compute total allocation sizes across group
    for (int32_t i = 0; i < options.groups; ++i) {

      auto problem = options.problem_sizes_host.at(i);
      auto M = get<0>(problem);
      auto N = get<1>(problem);
      auto K = get<2>(problem);

      // Offset into block allocation of each matrix base pointer
      offset_A.push_back(total_elements_A);
      offset_B.push_back(total_elements_B);
      offset_S.push_back(total_elements_S);
      offset_Z.push_back(total_elements_Z);
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

      const int scale_k = options.g == 0 ? 1 : cute::ceil_div(K, options.g);
      const int dq_mn_size = options.g == 0 ? 1 : AIsNarrower ? M : N;
      total_elements_S += (dq_mn_size * scale_k);
      total_elements_Z += (dq_mn_size * scale_k);
      auto zero_elements_packed_along_k = get<0>(StrideZero{});

      stride_A_host.push_back(cutlass::make_cute_packed_stride(StrideA{}, {M, K, 1}));
      stride_B_host.push_back(cutlass::make_cute_packed_stride(StrideB{}, {N, K, 1}));
      auto stride_scale = cutlass::make_cute_packed_stride(StrideScale{}, {dq_mn_size, scale_k, 1});
      stride_S_host.push_back(stride_scale);
      stride_C_host.push_back(cutlass::make_cute_packed_stride(StrideC{}, {M, N, 1}));
      stride_D_host.push_back(cutlass::make_cute_packed_stride(StrideD{}, {M, N, 1}));
      
      auto stride_zero = [&]() {
        if constexpr (is_tuple_v<std::remove_reference_t<decltype(cute::get<1>(StrideZero{}))>>) {
          return make_stride(Int<zero_elements_packed_along_k>{},
                             make_stride(_1{}, static_cast<int64_t>(zero_elements_packed_along_k * dq_mn_size)),
                             static_cast<int64_t>(dq_mn_size * scale_k));
        } else {
          return stride_scale;
        }
      }();
      stride_Z_host.push_back(stride_zero);
    }

    block_A.reset(total_elements_A);
    block_B.reset(total_elements_B);
    block_A_dq.reset(total_elements_A);
    block_B_dq.reset(total_elements_B);
    block_S.reset(total_elements_S);
    block_Z.reset(total_elements_Z);
    block_C.reset(total_elements_C);
    block_D.reset(total_elements_D);
    block_alpha.reset(options.groups);
    block_beta.reset(options.groups);
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
  static void dequantize_B_int4(DequantizedElement* dq_buffer,
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

    compat::wait();

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
              return  static_cast<ret_type>(src_tensor(n, k, l));
            } else {
              return static_cast<ret_type>(src_tensor(n, k, l).get());
            }}();

          ret_type b = [&]() {
            if constexpr (sizeof_bits_v<ElementZero> >= 8) {
              return static_cast<ret_type>(zero_tensor(n, k / group_size, l));
            } else {
              auto zero_elements_packed_along_k = get<0>(zero_tensor.shape());
              return static_cast<ret_type>(zero_tensor((k / group_size) % zero_elements_packed_along_k, n, k / group_size / zero_elements_packed_along_k, l).get());
            }
          }();

          dst_tensor(n, k, l) = ((ElementScale)(a - b)) * scale_tensor(n, k / group_size, l);
        }
      }
    }

    cutlass::device_memory::copy_to_device(dq_buffer, (DequantizedElement*)(raw_pointer_cast(dst_tensor.data())), dst_tensor.size());
    compat::wait();
  }


  /// Initialize operands to be used in the GEMM and reference GEMM
  void initialize(Options const& options) {
    problem_sizes.reset(options.groups);
    problem_sizes.copy_from_host(options.problem_sizes_host.data());
    //
    // Assign pointers
    //

    std::vector<ElementA *> ptr_A_host(options.groups);
    std::vector<ElementB *> ptr_B_host(options.groups);
    std::vector<ElementMMA *> ptr_A_dq_host(options.groups);
    std::vector<ElementMMA *> ptr_B_dq_host(options.groups);
    std::vector<ElementScale *> ptr_S_host(options.groups);
    std::vector<ElementZero *> ptr_Z_host(options.groups);
    std::vector<ElementC *> ptr_C_host(options.groups);
    std::vector<ElementOutput *> ptr_D_host(options.groups);
    std::vector<ElementAccumulator *> ptr_alpha_host(options.groups);
    std::vector<ElementAccumulator *> ptr_beta_host(options.groups);

    // Compute offsets, alpha & beta over group on host
    for (int32_t i = 0; i < options.groups; ++i) {
      ptr_A_host.at(i) = block_A.get() + offset_A.at(i);
      ptr_B_host.at(i) = block_B.get() + offset_B.at(i);
      ptr_A_dq_host.at(i) = block_A_dq.get() + offset_A.at(i);
      ptr_B_dq_host.at(i) = block_B_dq.get() + offset_B.at(i);
      ptr_S_host.at(i) = block_S.get() + offset_S.at(i);
      ptr_Z_host.at(i) = block_Z.get() + offset_Z.at(i);
      ptr_C_host.at(i) = block_C.get() + offset_C.at(i);
      ptr_D_host.at(i) = block_D.get() + offset_D.at(i);
      // Fill host vector of alpha & beta with random values if using per-group values
      alpha_host.push_back((options.alpha == FLT_MAX) ? static_cast<ElementAccumulator>((rand() % 5) + 1) : options.alpha);
      beta_host.push_back((options.beta == FLT_MAX) ? static_cast<ElementAccumulator>(rand() % 5) : options.beta);
      // Fill host ptr vectors with offset addresses into device alpha/beta blocks
      ptr_alpha_host.at(i) = block_alpha.get() + i;
      ptr_beta_host.at(i) = block_beta.get() + i;
    }

    // Allocate device memory & copy from host
    ptr_A.reset(options.groups);
    // Per-group alpha and beta
    ptr_A.copy_from_host(ptr_A_host.data());

    ptr_A_dq.reset(options.groups);
    ptr_A_dq.copy_from_host(ptr_A_dq_host.data());

    ptr_B.reset(options.groups);
    ptr_B.copy_from_host(ptr_B_host.data());

    ptr_B_dq.reset(options.groups);
    ptr_B_dq.copy_from_host(ptr_B_dq_host.data());

    ptr_S.reset(options.groups);
    ptr_S.copy_from_host(ptr_S_host.data());

    ptr_Z.reset(options.groups);
    ptr_Z.copy_from_host(ptr_Z_host.data());

    ptr_C.reset(options.groups);
    ptr_C.copy_from_host(ptr_C_host.data());

    ptr_D.reset(options.groups);
    ptr_D.copy_from_host(ptr_D_host.data());

    stride_A.reset(options.groups);
    stride_A.copy_from_host(stride_A_host.data());

    stride_B.reset(options.groups);
    stride_B.copy_from_host(stride_B_host.data());

    stride_S.reset(options.groups);
    stride_S.copy_from_host(stride_S_host.data());

    stride_Z.reset(options.groups);
    stride_Z.copy_from_host(stride_Z_host.data());

    stride_C.reset(options.groups);
    stride_C.copy_from_host(stride_C_host.data());

    stride_D.reset(options.groups);
    stride_D.copy_from_host(stride_D_host.data());

    // Per-group alpha and beta ptrs
    alpha_device.reset(options.groups);
    alpha_device.copy_from_host(ptr_alpha_host.data());
    beta_device.reset(options.groups);
    beta_device.copy_from_host(ptr_beta_host.data());

    initialize_mixed_dtype_block(block_A, block_A_dq, seed + 2022);
    initialize_mixed_dtype_block(block_B, block_B_dq, seed + 2023);

    initialize_block(block_C, seed + 2024);

    initialize_scale(block_S, options);
    initialize_zero(block_Z, options);

    for (int32_t i = 0; i < options.groups; ++i) {
      auto problem = options.problem_sizes_host.at(i);
      auto M = get<0>(problem);
      auto N = get<1>(problem);
      auto K = get<2>(problem);
      const int scale_k = options.g == 0 ? 1 : cute::ceil_div(K, options.g);
      const int dq_mn_size = options.g == 0 ? 1 : AIsNarrower ? M : N;

      auto layout_A = make_layout(make_shape(M, K, 1), stride_A_host.at(i));
      auto layout_B = make_layout(make_shape(N, K, 1), stride_B_host.at(i));
      auto zero_elements_packed_along_k = get<0>(StrideZero{});
      auto shape_scale = cute::make_shape(dq_mn_size, scale_k, 1);
      auto stride_scale = cutlass::make_cute_packed_stride(StrideScale{}, shape_scale);
      auto shape_zero = [&]() {
        if constexpr (is_tuple_v<std::remove_reference_t<decltype(cute::get<1>(StrideZero{}))>>) {
          return cute::make_shape(dq_mn_size,
                                  cute::make_shape(zero_elements_packed_along_k, cute::max(1, scale_k / zero_elements_packed_along_k)),
                                  1);
        } else {
          return shape_scale;
        }
      }();
      auto stride_zero = [&]() {
        if constexpr (is_tuple_v<std::remove_reference_t<decltype(cute::get<1>(StrideZero{}))>>) {
          return make_stride(Int<zero_elements_packed_along_k>{},
                             make_stride(_1{}, static_cast<int64_t>(zero_elements_packed_along_k * dq_mn_size)),
                             static_cast<int64_t>(dq_mn_size * scale_k));
        } else {
          return stride_scale;
        }
      }();
      auto layout_scale = make_layout(shape_scale, stride_scale);
      auto layout_zero = make_layout(shape_zero, stride_zero);

      // Note that we are overwriting the relevant `block_X_dq` here, both were
      // filled by initialize_mixed_dtype_block above
      if (options.g != 0) {
        if constexpr (AIsNarrower) {
          dequantize(block_A_dq.get() + offset_A.at(i), block_A.get() + offset_A.at(i), layout_A,
                     block_S.get() + offset_S.at(i), block_Z.get() + offset_Z.at(i), layout_scale, layout_zero,
                     options.g);
        } else {
            if constexpr (cute::sizeof_bits_v<ElementB> < 8) {
                dequantize_B_int4(block_B_dq.get() + offset_B.at(i), block_B.get() + offset_B.at(i), layout_B,
                            block_S.get() + offset_S.at(i), block_Z.get() + offset_Z.at(i), layout_scale, layout_zero,
                            options.g);
            } else {
                dequantize(block_B_dq.get() + offset_B.at(i), block_B.get() + offset_B.at(i), layout_B,
                            block_S.get() + offset_S.at(i), block_Z.get() + offset_Z.at(i), layout_scale, layout_zero,
                            options.g);
            }
        }
      } else {
        if constexpr (AIsNarrower) {
          const size_t size_a = i == options.groups - 1 ? block_A.size() - offset_A[i] : offset_A[i + 1] - offset_A[i];
          quantize_tensorwise<ElementQuant, ElementMMA>(
              block_A.get() + offset_A.at(i),
              block_A_dq.get() + offset_A.at(i),
              block_S.get() + offset_S.at(i),
              block_Z.get() + offset_Z.at(i),
              size_a, 1
          );
        } else {
          const size_t size_b = i == options.groups - 1 ? block_B.size() - offset_B[i] : offset_B[i + 1] - offset_B[i];
          quantize_tensorwise<ElementQuant, ElementMMA>(
              block_B.get() + offset_B.at(i),
              block_B_dq.get() + offset_B.at(i),
              block_S.get() + offset_S.at(i),
              block_Z.get() + offset_Z.at(i),
              size_b, 1
          );
        }
      }
    }
  }

  cutlass::Status run(const Options& options, const cutlass::KernelHardwareInfo& hw_info) {
    allocate(options);
    initialize(options);

    auto args_tuple = args_from_options(options, hw_info);
    typename Gemm::GemmKernel::Arguments arguments {
      get<0>(args_tuple), get<1>(args_tuple),
      typename Gemm::GemmKernel::MainloopArguments{ptr_A.get(), stride_A.get(), ptr_B.get(), stride_B.get(), ptr_S.get(),
      stride_S.get(), ptr_Z.get(), stride_Z.get(), options.g},
      typename Gemm::GemmKernel::EpilogueArguments{get<2>(args_tuple), ptr_C.get(), stride_C.get(), ptr_D.get(), stride_D.get()},
      get<3>(args_tuple), get<4>(args_tuple)
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
    bool passed = verify(options);
    std::cout << "Disposition: " << (passed ? "Passed" : "Failed") << std::endl;

    if(!passed) return cutlass::Status::kErrorInternal;

    if (options.iterations > 0) {
      GPU_Clock timer;
      timer.start();
      for (int i = 0; i < options.iterations; ++i) {
        gemm_op.run();
      }
      compat::wait();

      float cute_time = timer.seconds() / options.iterations;
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
