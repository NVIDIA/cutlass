/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Hopper GEMM with activation fusion example
*/

#include <cstdlib>
#include <iostream>
#include <numeric>
#include <vector>

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/epilogue/fusion/operations.hpp"
#include "cutlass/epilogue/thread/activation.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/kernel/tile_scheduler_params.h"

#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "cutlass/util/reference/device/tensor_fill.h"

#include "helper.h"
#include "options.hpp"
#include "utils.hpp"
#include "sm90_lin_comb_elt_act_scaled.hpp"
#include "activation_kernel.cuh"

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM kernel configurations
/////////////////////////////////////////////////////////////////////////////////////////////////

#if 0
template<class T>
using ActivationFn = cutlass::epilogue::thread::ReLu<T>;
#elif 1
template<class T>
using ActivationFn = cutlass::epilogue::thread::SiLu<T>;
#else
template<class T>
using ActivationFn = cutlass::epilogue::thread::Identity<T>;
#endif

bool constexpr IsFp8         = true;  // whether to run with fp8 or fp16 input/output
bool constexpr Quantize      = true;  // whether to quantize output with a per-tensor scale factor
bool constexpr ExactMode     = false; // whether to reproduce unfused dual gemm+activation exactly
bool constexpr BiasBroadcast = true;  // whether bias is broadcast along columns in each group
bool constexpr Pingpong      = true;  // whether to use pingpong schedule

// A matrix configuration
using         ElementA    = conditional_t<IsFp8, cutlass::float_e4m3_t, cutlass::half_t>; // Element type for A matrix operand
using         LayoutA     = cutlass::layout::RowMajor;                                    // Layout type for A matrix operand
constexpr int AlignmentA  = 128 / cutlass::sizeof_bits<ElementA>::value;                  // Memory access granularity/alignment of A matrix in units of elements (up to 16 bytes)

// B matrix configuration
using         ElementB    = conditional_t<IsFp8, cutlass::float_e5m2_t, cutlass::half_t>; // Element type for B matrix operand
using         LayoutB     = cutlass::layout::ColumnMajor;                                 // Layout type for B matrix operand
constexpr int AlignmentB  = 128 / cutlass::sizeof_bits<ElementB>::value;                  // Memory access granularity/alignment of B matrix in units of elements (up to 16 bytes)

// C/D matrix configuration
using         ElementC    = cutlass::half_t;                                              // Element type for C and D matrix operands
using         LayoutC     = cutlass::layout::ColumnMajor;                                 // Layout type for C and D matrix operands
constexpr int AlignmentC  = 128 / cutlass::sizeof_bits<ElementC>::value;                  // Memory access granularity/alignment of C matrix in units of elements (up to 16 bytes)

using         ElementD    = conditional_t<IsFp8, cutlass::float_e4m3_t, cutlass::half_t>; // Element type for C and D matrix operands
using         LayoutD     = cutlass::layout::ColumnMajor;                                 // Layout type for C and D matrix operands
constexpr int AlignmentD  = 128 / cutlass::sizeof_bits<ElementD>::value;                  // Memory access granularity/alignment of C matrix in units of elements (up to 16 bytes)

// Core kernel configurations
using ElementAccumulator  = float;                                           // Element type for internal accumulation
using ElementCompute      = float;                                           // Element type for internal accumulation
using ElementScalar       = float;                                           // Element type for internal accumulation
using ElementIntermediate = cutlass::half_t;                                 // Element type of intermediate result between GEMM and bias+activation
using ArchTag             = cutlass::arch::Sm90;                             // Tag indicating the minimum SM that supports the intended feature
using OperatorClass       = cutlass::arch::OpClassTensorOp;                  // Operator class tag
using EpiTileShape        = cutlass::epilogue::collective::EpilogueTileAuto; // Epilogue sub-tile shape
using ClusterShape        = Shape<_1,_2,_1>;                                 // Shape of the threadblocks in a cluster
using TileShapeK          = Int<128 * 8 / sizeof_bits<ElementA>::value>;

using KernelScheduleCooperative = conditional_t<cutlass::gemm::collective::detail::is_input_fp8<ElementA, ElementB>(),
                                                cutlass::gemm::KernelTmaWarpSpecializedCooperativeFP8FastAccum,
                                                cutlass::gemm::KernelTmaWarpSpecializedCooperative>;

using KernelSchedulePingpong    = conditional_t<cutlass::gemm::collective::detail::is_input_fp8<ElementA, ElementB>(),
                                                cutlass::gemm::KernelTmaWarpSpecializedPingpongFP8FastAccum,
                                                cutlass::gemm::KernelTmaWarpSpecializedPingpong>;

using KernelSchedule   = conditional_t<Pingpong, KernelSchedulePingpong, KernelScheduleCooperative>;
using EpilogueSchedule = conditional_t<Pingpong, cutlass::epilogue::TmaWarpSpecialized, cutlass::epilogue::TmaWarpSpecializedCooperative>;
using TileShape        = conditional_t<Pingpong, Shape<_128,_128,TileShapeK>, Shape<_128,_256,TileShapeK>>;

using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
    TileShape, ClusterShape,
    EpiTileShape,
    ElementAccumulator, ElementCompute,
    ElementC, LayoutC, AlignmentC,
    ElementD, LayoutD, AlignmentD,
    EpilogueSchedule,
    cutlass::epilogue::fusion::AccCastLinCombEltActScale<
      Quantize,
      ActivationFn,
      ElementD,
      ElementCompute,
      ElementC,
      ElementScalar,
      conditional_t<ExactMode, ElementIntermediate, ElementCompute>
    >
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
    Shape<int,int,int,int>, // Indicates ProblemShape
    CollectiveMainloop,
    CollectiveEpilogue
>;

using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

// Reference device GEMM implementation type
using CollectiveEpilogueRef = typename cutlass::epilogue::collective::CollectiveBuilder<
    cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
    TileShape, ClusterShape,
    EpiTileShape,
    ElementAccumulator, ElementCompute,
    void,     LayoutC, AlignmentC,
    ElementIntermediate, LayoutD, AlignmentD,
    EpilogueSchedule,
    cutlass::epilogue::fusion::ScaledAcc<ElementIntermediate, ElementCompute, ElementScalar>
  >::CollectiveOp;

using CollectiveMainloopRef = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    ElementA, LayoutA, AlignmentA,
    ElementB, LayoutB, AlignmentB,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
    KernelSchedule
  >::CollectiveOp;

using GemmKernelRef = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>, // Indicates ProblemShape
    CollectiveMainloopRef,
    CollectiveEpilogueRef
>;

using GemmRef = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelRef>;

using StrideA = typename GemmKernel::StrideA;
using StrideB = typename GemmKernel::StrideB;
using StrideC = typename GemmKernel::StrideC;
using StrideD = typename GemmKernel::StrideD;

//
// Data members
//

/// Initialization
StrideA stride_A;
StrideB stride_B;
StrideC stride_C;
StrideD stride_D;
uint64_t seed;

cutlass::DeviceAllocation<ElementA> block_A;
cutlass::DeviceAllocation<ElementB> block_B;
cutlass::DeviceAllocation<ElementC> block_C;
cutlass::DeviceAllocation<ElementD> block_D;
cutlass::DeviceAllocation<ElementD> block_D_ref;
cutlass::DeviceAllocation<ElementIntermediate> block_D_ref_gemm;
cutlass::DeviceAllocation<int64_t> offset_col_D;
cutlass::DeviceAllocation<ElementScalar> block_scale;

#endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Testbed utility types
/////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options : GemmOptionsBase<cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90Params::RasterOrderOptions> {

  using Base = GemmOptionsBase<cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90Params::RasterOrderOptions>;

  float alpha = 1.f, beta = 0.f;
  int m = 10240, n = 2048, k = 8192, l = 10;

  // Parses the command line
  void parse(cutlass::CommandLine const& cmd) {
    Base::parse(cmd);
    cmd.get_cmd_line_argument("alpha", alpha);
    cmd.get_cmd_line_argument("beta", beta);
    cmd.get_cmd_line_argument("m", m);
    cmd.get_cmd_line_argument("n", n);
    cmd.get_cmd_line_argument("k", k);
    cmd.get_cmd_line_argument("l", l);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << program_path << "\n"
           "\n"
           "  Hopper GEMM with fused activation function.\n"
           "\n"
           "Options:\n"
           "\n"
           "  --help                      If specified, displays this usage statement\n\n"
           "  --m=<int>                   Sets the M extent of the GEMM\n"
           "  --n=<int>                   Sets the N extent of the GEMM\n"
           "  --k=<int>                   Sets the K extent of the GEMM\n"
           "  --l=<int>                   Sets the L extent of the GEMM\n"
           "  --alpha=<f32>               Epilogue scalar alpha\n"
           "  --beta=<f32>                Epilogue scalar beta\n"
           "  --raster=<char>             CTA Rasterization direction (N for along N, M for along M, and H for heuristic)\n"
           "  --swizzle=<int>             CTA Rasterization swizzle\n"
           "  --warmup=<int>              Number of warmup iterations to perform.\n"
           "  --iterations=<int>          Number of profiling iterations to perform.\n"
           "  --verbose                   Verbose mode (output detailed verification result)\n"
           "  --verify=<bool>             Verification (correctness check) on/off\n"
           "  --sms                       Number of SMs to run the GEMMs on\n"
           "  --device                    Device index\n"
           "\n"
           "Examples:\n"
           "\n"
        << program_path << " --m=1024 --n=512 --k=1024 --l=10 --alpha=2 --beta=0.707\n";

    return out;
  }

  /// Compute total number of floating point operations
  double total_flops() const {
    // Two flops per multiply-add
    return uint64_t(2) * m * n * k * l;
  }
};

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM setup and evaluation
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Initialize operands to be used in the GEMM and reference GEMM
void initialize(const Options &options) {

  auto [M, N, K, L] = make_tuple(options.m, options.n, options.k, options.l);
  auto NC = BiasBroadcast ? 1 : N;

  stride_A = cutlass::make_cute_packed_stride(StrideA{}, {M, K, L});
  stride_B = cutlass::make_cute_packed_stride(StrideB{}, {N, K, L});
  stride_C = cutlass::make_cute_packed_stride(StrideC{}, {M, NC, L});
  stride_D = cutlass::make_cute_packed_stride(StrideD{}, {M, N, L});

  block_A.reset(M * K * L);
  block_B.reset(N * K * L);
  block_C.reset(M * NC * L);
  block_D.reset(M * N * L);
  block_D_ref.reset(M * N * L);
  block_D_ref_gemm.reset(M * N * L);
  block_scale.reset(1);

  if constexpr (BiasBroadcast) {
    get<1>(stride_C) = 0;
  }

  std::vector<int64_t> offset_col_D_host(options.l + 1);
  std::iota(offset_col_D_host.begin(), offset_col_D_host.end(), 0ll);
  std::transform(offset_col_D_host.begin(), offset_col_D_host.end(), offset_col_D_host.begin(), [&](auto i) { return i * options.n; });
  offset_col_D.reset(options.l + 1);
  offset_col_D.copy_from_host(offset_col_D_host.data());

  cutlass::reference::device::BlockFillRandom(block_A.get(), block_A.size(), 2024, options.dist_a);
  cutlass::reference::device::BlockFillRandom(block_B.get(), block_B.size(), 2025, options.dist_b);
  cutlass::reference::device::BlockFillRandom(block_C.get(), block_C.size(), 2026, options.dist_c);
  cutlass::reference::device::BlockFillRandomUniform(block_scale.get(), block_scale.size(), 2027, 0.5, 1.0);
}

template <typename GemmT>
auto args_from_options_common(const Options &options)
{
  cutlass::KernelHardwareInfo hw_info;
  hw_info.device_id = 0;
  hw_info.sm_count = options.sm_count > 0 
                   ? options.sm_count 
                   : cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);

  typename GemmT::Arguments arguments;
  decltype(arguments.epilogue.thread) fusion_args{};

  fusion_args.alpha = options.alpha;

  return make_tuple(fusion_args, hw_info);
}

template <typename GemmT>
typename GemmT::Arguments
args_from_options(const Options &options);

template <>
typename Gemm::Arguments
args_from_options<Gemm>(Options const& options)
{
  auto [fusion_args, hw_info] = args_from_options_common<Gemm>(options);
  fusion_args.beta = options.beta;
  fusion_args.scale_ptr = Quantize ? block_scale.get() : nullptr;

  typename Gemm::Arguments arguments{
    cutlass::gemm::GemmUniversalMode::kGemm,
    {options.m, options.n, options.k, options.l},
    {block_A.get(), stride_A, block_B.get(), stride_B},
    {fusion_args, block_C.get(), stride_C, block_D.get(), stride_D},
    hw_info,
    {options.swizzle, options.raster}
  };

  return arguments;
}

template <>
typename GemmRef::Arguments
args_from_options<GemmRef>(Options const& options)
{
  auto [fusion_args, hw_info] = args_from_options_common<GemmRef>(options);

  typename GemmRef::Arguments arguments{
    cutlass::gemm::GemmUniversalMode::kGemm,
    {options.m, options.n, options.k, options.l},
    {block_A.get(), stride_A, block_B.get(), stride_B},
    {fusion_args, nullptr, stride_C, block_D_ref_gemm.get(), stride_D},
    hw_info,
    {options.swizzle, options.raster}
  };

  return arguments;
}

bool verify(const Options &options) {
  // Check if output from CUTLASS kernel and reference kernel are equal or not
  bool passed = false;
  if constexpr (ExactMode) {
    passed = cutlass::reference::device::BlockCompareEqual(block_D_ref.get(), block_D.get(), block_D.size());
  }
  else {
    passed = cutlass::reference::device::BlockCompareRelativelyEqual(block_D_ref.get(), block_D.get(), block_D.size(), ElementD(options.tolerance), ElementD(options.nonzero_floor));
  }

  if (!passed && options.verbose) {
    print("D reference: "); print_device_tensor(make_tensor(block_D_ref.get(), make_shape(options.m, options.n, options.l), stride_D));
    print("D  computed: "); print_device_tensor(make_tensor(block_D.get(), make_shape(options.m, options.n, options.l), stride_D));
  }

  return passed;
}

/// Execute a given example GEMM computation
bool run(Options& options)
{
  if (options.beta != 1.f && options.beta != 0.f) {
    throw std::runtime_error("Specifying beta != 0/1 is not supported by verification kernel");
  }

  initialize(options);

  std::cout << "Problem Size: " << shape_string(make_tuple(options.m, options.n, options.k, options.l)) << std::endl;
  std::cout << "Data types: " << problem_desc_string<ElementA, ElementB, ElementAccumulator, ElementC, ElementD>() << std::endl;
  std::cout << "Activation function: " << activation_func_string<ActivationFn>() << std::endl;
  std::cout << "Kernel schedule: " << kernel_schedule_string<KernelSchedule>() << std::endl;
  std::cout << "GEMM tile shape: " << shape_string(TileShape{}) << std::endl;
  std::cout << "Epi tile shape: " << epilogue_tile_string(EpiTileShape{}) << std::endl;
  std::cout << "Cluster shape: " << shape_string(ClusterShape{}) << std::endl;
  std::cout << "Rasterization: " << options.raster_string() << " with a maximum CTA swizzle of " << options.swizzle << std::endl;
  std::cout << "Options: Quantize = " << Quantize << ", Exact = " << ExactMode << ", BiasBroadcast = " << BiasBroadcast << std::endl;

  Runner<Gemm> gemm(args_from_options<Gemm>(options));
  Runner<GemmRef> gemm_ref(args_from_options<GemmRef>(options));

  auto run_fused = [&](){ gemm.run(); };
  auto run_ref_gemm = [&](){ gemm_ref.run(); };
  auto run_activation = [&](){ 
    do_activation<ActivationFn>(
      block_D_ref.get(),
      block_D_ref_gemm.get(),
      Quantize ? block_scale.get() : static_cast<ElementScalar const*>(nullptr),
      options.beta != 0.f ? block_C.get() : static_cast<ElementC const*>(nullptr),
      BiasBroadcast,
      offset_col_D.get(),
      options.l,
      options.m,
      options.n * options.l,
      false);
  };
  auto run_unfused = [&](){ run_ref_gemm(); run_activation(); };

  run_fused();
  CUDA_CHECK(cudaDeviceSynchronize());

  // Correctness check
  bool passed = true;
  if (options.verify) {
    run_unfused();
    CUDA_CHECK(cudaDeviceSynchronize());

    passed = verify(options);
    std::cout << "Disposition: " << (passed ? "Passed" : "Failed") << std::endl;
  }

  // Run profiling loop
  if (options.iterations > 0)
  {
    auto benchmark = [&](auto name, auto func)
    {
      BenchmarkResult result = run_benchmark(func, options.warmup, options.iterations);
      double avg_tflops = double(options.total_flops()) / result.avg_runtime_ms / 1e9; // FLOP/ms -> TFLOP/s
      printf(options.csv ? "%s,%.3f,%.0f\n" : "%20s  %20.3f  %20.0f\n",
             name, result.avg_runtime_ms, avg_tflops);
    };
    printf(options.csv ? "%s,%s,%s\n" : "%20s  %20s  %20s\n",
           "Kernel", "Runtime (ms)", "Throughput (Tflop/s)");
    benchmark("Fused", run_fused);
    benchmark("Unfused", run_unfused);
    benchmark("GEMM only", run_ref_gemm);
  }

  return passed;
}

#endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  // CUTLASS must be compiled with CUDA 12.0 Toolkit to run this example
  // and must have compute capability at least 90.
  if (__CUDACC_VER_MAJOR__ < 12) {
    std::cerr << "This example requires CUDA 12 or newer.\n";
    // Returning zero so this test passes on older Toolkits. Its actions are no-op.
    return 0;
  }

  try {
    Options options;
    cutlass::CommandLine cmd(argc, args);
    options.parse(cmd);

    if (options.help) {
      options.print_usage(std::cout) << std::endl;
      return EXIT_SUCCESS;
    }

    if (options.device >= 0) {
      CUDA_CHECK(cudaSetDevice(options.device));
    }
    else {
      CUDA_CHECK(cudaGetDevice(&options.device));
    }

    cudaDeviceProp props;
    CUDA_CHECK(cudaGetDeviceProperties(&props, options.device));
    if (props.major != 9 || props.minor != 0) {
      std::cerr << "This example requires a GPU of NVIDIA's Hopper Architecture (compute capability 90).\n";
      return EXIT_SUCCESS;
    }

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)
    if (!run(options)) {
      return EXIT_FAILURE;
    }
#endif
  }
  catch (std::exception const& e) {
    std::cerr << e.what() << std::endl;
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
