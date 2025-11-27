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



/*! \file
    \brief Ragged Contiguous Blockscaled Grouped GEMM example using CUTLASS 3 APIs for the NVIDIA Blackwell SM100 architecture.

    This example demonstrates an implementation of Ragged Contiguous Grouped GEMM using a TMA + Blackwell SM100 TensorOp-based warp-specialized kernel for narrow precisions (FP4) with Scale Factors (In and Out).
    For this example all scheduling work is performed on the device.

    To run this example:

      $ ./examples/92_blackwell_moe_gemm/92_blackwell_moe_gemm_blockscaled_rcgrouped --m=128 --k=128 --groups=10

      The above example command makes all 10 groups to be sized at the given m, n, k sizes. 
      Note that m and k remain consistent across groups and only n is randomized if it's not provided through the args.
      Alpha and beta values are randomized across the different groups.

    To run this example for a set of problems using the benchmark option:

      $ ./examples/92_blackwell_grouped_gemm/92_blackwell_moe_gemm_blockscaled_rcgrouped --benchmark=./test_benchmark.txt

      Where the test_benchmark.txt may look as such:
        0 256x512x256
        1 256x128x256
        2 256x256x256 and so on
      Note that one must keep m and k consistent across groups in the benchmark file.

*/

#include <iostream>
#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>
#include <float.h>

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
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/reference/host/gett.hpp"
#include "cutlass/util/reference/host/tensor_norm.h"
#include "cutlass/util/reference/host/tensor_compare.h"

#include "helper.h"
using namespace cute;

using ProblemShape = cutlass::gemm::MoEProblemShape<Shape<int,int,int>>; // <M,N,K> per group
using ElementInput = cutlass::float_e4m3_t;                                // Element type for Input matrix operands
using ElementSF    = cutlass::float_ue8m0_t;                               // Element type for SF matrix operands
using ElementC     = cutlass::bfloat16_t;                                      // Element type for C matrix operands

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM kernel configurations
/////////////////////////////////////////////////////////////////////////////////////////////////
// A matrix configuration
using ElementA = cutlass::mx_float8_t<ElementInput>;                        // Element type for A matrix operand
using LayoutA  = cutlass::layout::RowMajor;                                 // Layout type for A matrix operand
constexpr int AlignmentA  = 16;                                             // Alignment of A matrix in units of elements (up to 16 bytes)

// B matrix configuration
using ElementB = cutlass::mx_float8_t<ElementInput>;                        // Element type for A matrix operand
using LayoutB = cutlass::layout::ColumnMajor;                               // Layout type for B matrix operand
constexpr int AlignmentB  = 16;                                             // Alignment of A matrix in units of elements (up to 16 bytes)

// C/D matrix configuration
using ElementD = ElementC;                                                  // Element type for D matrix operands
using         LayoutC     = cutlass::layout::RowMajor;                      // Layout type for C and D matrix operands
constexpr int AlignmentC  = 128 / cutlass::sizeof_bits<ElementC>::value;    // Alignment of C matrix in units of elements (up to 16 bytes)
constexpr int AlignmentD  = 128 / cutlass::sizeof_bits<ElementD>::value;    // Alignment of D matrix in units of elements (up to 16 bytes)
using ElementAccumulator  = float;                                          // Element type for internal accumulation

using ElementSFD  = cutlass::float_ue4m3_t;                                 // Element type for SF Output operands
constexpr int OutputSFVectorSize = 16;
using FusionOperation = cutlass::epilogue::fusion::LinCombEltActBlockScaleFactor<
    cutlass::epilogue::thread::SiLu,
    OutputSFVectorSize,
    ElementD,
    ElementAccumulator,
    ElementSFD,
    LayoutC,
    ElementC>;

// Core kernel configurations
using ArchTag             = cutlass::arch::Sm100;                           // Tag indicating the minimum SM that supports the intended feature
using OperatorClass = cutlass::arch::OpClassBlockScaledTensorOp;            // Operator class tag
using StageCountType = cutlass::gemm::collective::StageCountAuto;           // Stage count maximized based on the tile size

// Runtime Cluster Shape
using ClusterShape = Shape<int32_t,int32_t,_1>;

// Different configs for 1SM and 2SM MMA kernel
struct MMA1SMConfig {
  using MmaTileShape     = Shape<_128,_256,_128>;
  using KernelSchedule   = cutlass::gemm::KernelPtrArrayTmaWarpSpecialized1SmMxf8f6f4Sm100;   // Kernel to launch
  using EpilogueSchedule = cutlass::epilogue::PtrArrayTmaWarpSpecialized1Sm;              // Epilogue to launch
};

struct MMA2SMConfig {
  using MmaTileShape     = Shape<_256,_256,_128>;
  using KernelSchedule   = cutlass::gemm::KernelPtrArrayTmaWarpSpecialized2SmMxf8f6f4Sm100;   // Kernel to launch
  using EpilogueSchedule = cutlass::epilogue::PtrArrayTmaWarpSpecialized2Sm;              // Epilogue to launch
};

using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    typename MMA1SMConfig::MmaTileShape, ClusterShape,
    Shape<_128,_64>,
    ElementAccumulator, ElementAccumulator,
    ElementC, LayoutC *, AlignmentC, // Set ElementC as void here to run kernel as void-C case
    ElementD, LayoutC *, AlignmentD,
    typename MMA1SMConfig::EpilogueSchedule
    // , FusionOperation  // Enable for SF Output
>::CollectiveOp;
using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
  ArchTag, OperatorClass,
  ElementA, LayoutA, AlignmentA,
  ElementB, LayoutB *, AlignmentB,
  ElementAccumulator,
    typename MMA1SMConfig::MmaTileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
    typename MMA1SMConfig::KernelSchedule
>::CollectiveOp;
using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    ProblemShape,
    CollectiveMainloop,
    CollectiveEpilogue
>;
using Gemm1SM = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
using Gemm = Gemm1SM;

using CollectiveEpilogue2SM = typename cutlass::epilogue::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    typename MMA2SMConfig::MmaTileShape, ClusterShape,
    Shape<_128,_64>,
    ElementAccumulator, ElementAccumulator,
    ElementC, LayoutC *, AlignmentC, // Set ElementC as void here to run kernel as void-C case
    ElementD, LayoutC *, AlignmentD,
    typename MMA2SMConfig::EpilogueSchedule
    // , FusionOperation  // Enable for SF Output
>::CollectiveOp;
using CollectiveMainloop2SM = typename cutlass::gemm::collective::CollectiveBuilder<
  ArchTag, OperatorClass,
  ElementA, LayoutA, AlignmentA,
  ElementB, LayoutB *, AlignmentB,
  ElementAccumulator,
    typename MMA2SMConfig::MmaTileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue2SM::SharedStorage))>,
    typename MMA2SMConfig::KernelSchedule
>::CollectiveOp;
using GemmKernel2SM = cutlass::gemm::kernel::GemmUniversal<
    ProblemShape,
    CollectiveMainloop2SM,
    CollectiveEpilogue2SM
>;
using Gemm2SM = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel2SM>;

using StrideA = cutlass::detail::TagToStrideA_t<LayoutA>;
using StrideB = typename Gemm::GemmKernel::InternalStrideB;
using StrideC = typename Gemm::GemmKernel::InternalStrideC;
using StrideD = typename Gemm::GemmKernel::InternalStrideD;

using LayoutSFA = typename Gemm::GemmKernel::CollectiveMainloop::InternalLayoutSFA;
using LayoutSFB = typename Gemm::GemmKernel::CollectiveMainloop::InternalLayoutSFB;
using Sm1xxBlkScaledConfig =  typename Gemm::GemmKernel::CollectiveMainloop::Sm1xxBlkScaledConfig;
using Sm1xxBlockScaledOutputConfig= cutlass::detail::Sm1xxBlockScaledOutputConfig<
                                        OutputSFVectorSize,
                                        cute::is_same_v<typename FusionOperation::GmemLayoutTagScalefactor,
                                            cutlass::layout::RowMajor> ? cute::UMMA::Major::K : cute::UMMA::Major::MN
                                     >;
using OutputSFAtom = typename Sm1xxBlockScaledOutputConfig::SfAtom;
using LayoutSFD = typename Sm1xxBlockScaledOutputConfig::LayoutSF;

// Host-side allocations
std::vector<ElementAccumulator> alpha_host;
std::vector<ElementAccumulator> beta_host;

using HostTensorA = cutlass::HostTensor<typename Gemm::ElementA, cutlass::layout::PackedVectorLayout>;
using HostTensorB = cutlass::HostTensor<typename Gemm::ElementB, cutlass::layout::PackedVectorLayout>;
using HostTensorSF = cutlass::HostTensor<typename Gemm::GemmKernel::ElementSF, cutlass::layout::PackedVectorLayout>;
using HostTensorC = cutlass::HostTensor<typename Gemm::ElementC, cutlass::layout::PackedVectorLayout>;
using HostTensorD = cutlass::HostTensor<typename Gemm::EpilogueOutputOp::ElementOutput, cutlass::layout::PackedVectorLayout>;

HostTensorA block_A;
HostTensorSF block_SFA;
std::vector<HostTensorB> block_B;
std::vector<HostTensorSF> block_SFB;
std::vector<HostTensorC> block_C;
std::vector<HostTensorD> block_D;
std::vector<HostTensorSF> block_SFD;
std::vector<HostTensorD> block_ref_D;

// Device-side allocations
cutlass::DeviceAllocation<int32_t> tokens_per_expert;

cutlass::DeviceAllocation<const typename Gemm::ElementA *> ptr_A;
cutlass::DeviceAllocation<const typename Gemm::ElementB *> ptr_B;
cutlass::DeviceAllocation<const typename Gemm::GemmKernel::ElementSF *> ptr_SFA;
cutlass::DeviceAllocation<const typename Gemm::GemmKernel::ElementSF *> ptr_SFB;
cutlass::DeviceAllocation<const typename Gemm::ElementC *> ptr_C;
cutlass::DeviceAllocation<typename Gemm::EpilogueOutputOp::ElementOutput *> ptr_D;
cutlass::DeviceAllocation<typename Gemm::GemmKernel::ElementSF *> ptr_SFD;
cutlass::DeviceAllocation<typename Gemm::EpilogueOutputOp::ElementOutput *> ptr_ref_D;

StrideA stride_A;
LayoutSFA layout_SFA;

// Note, this is an array of pointers to alpha and beta scaling values per group
cutlass::DeviceAllocation<ElementAccumulator*> alpha_device;
cutlass::DeviceAllocation<ElementAccumulator*> beta_device;
cutlass::DeviceAllocation<ElementAccumulator> block_alpha;
cutlass::DeviceAllocation<ElementAccumulator> block_beta;
// A matrix wide constant value to scale the output matrix
// Avoids generating small FP4 values.
// NormConst is a single device-side constant value, its not per-batch or per-group
cutlass::DeviceAllocation<ElementAccumulator> norm_constant_device;

#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

template <typename T>
auto make_iterator(T* ptr) {
  return cute::recast_ptr<T>(ptr);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Testbed utility types
/////////////////////////////////////////////////////////////////////////////////////////////////

using RasterOrderOptions = cutlass::gemm::kernel::detail::RasterOrderOptions;
// Command line options parsing
struct Options {

  bool help = false;
  bool verification = true;
  bool use_pdl = false;

  float alpha = FLT_MAX;
  float beta  = FLT_MAX;
  float norm_constant = 1.0;
  int warmup = 1000;
  int iterations = 1000;
  int m = 1024, n = 2048, k = 512, groups = 10;
  dim3 cluster_shape = dim3(2,1,1);
  dim3 cluster_shape_fallback = dim3(2,1,1);
  RasterOrderOptions raster_order = RasterOrderOptions::AlongN;
  int max_sm_count = INT_MAX;
  std::string benchmark_path;
  std::vector<int32_t> tokens_per_expert_host;
  std::vector<typename ProblemShape::UnderlyingProblemShape> problem_sizes_host;
  int const tma_alignment_bits = 128;
  int const alignment = tma_alignment_bits / cutlass::sizeof_bits<ElementInput>::value;

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }
    if (cmd.check_cmd_line_flag("no_verif")) {
      verification = false;
    }
    if (cmd.check_cmd_line_flag("use_pdl")) {
      use_pdl = true;
    }

    cmd.get_cmd_line_argument("m", m);
    cmd.get_cmd_line_argument("n", n);
    cmd.get_cmd_line_argument("k", k);
    cmd.get_cmd_line_argument("groups", groups);
    cmd.get_cmd_line_argument("alpha", alpha, FLT_MAX);
    cmd.get_cmd_line_argument("beta",  beta,  FLT_MAX);
    cmd.get_cmd_line_argument("norm_constant",  norm_constant,  float(1.0));
    cmd.get_cmd_line_argument("warmup", warmup);
    cmd.get_cmd_line_argument("iterations", iterations);
    cmd.get_cmd_line_argument("benchmark", benchmark_path);
    cmd.get_cmd_line_argument("cluster_m", cluster_shape.x);
    cmd.get_cmd_line_argument("cluster_n", cluster_shape.y);
    cmd.get_cmd_line_argument("cluster_fallback_m", cluster_shape_fallback.x);
    cmd.get_cmd_line_argument("cluster_fallback_n", cluster_shape_fallback.y);
    cmd.get_cmd_line_argument("max_sm_count", max_sm_count, INT_MAX);

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

    char raster_char;
    cmd.get_cmd_line_argument("raster", raster_char);

    if (raster_char == 'N' || raster_char == 'n') {
      raster_order = RasterOrderOptions::AlongN;
    }
    else if (raster_char == 'M' || raster_char == 'm') {
      raster_order = RasterOrderOptions::AlongM;
    }
  }

  void randomize_problems(cutlass::CommandLine &cmd) {
    int cmd_line_m = -1, cmd_line_n = -1, cmd_line_k = -1;
    cmd.get_cmd_line_argument("m", cmd_line_m);
    cmd.get_cmd_line_argument("n", cmd_line_n);
    cmd.get_cmd_line_argument("k", cmd_line_k);

    problem_sizes_host.reserve(groups);

    m = cmd_line_m;
    k = cmd_line_k;
    if (m < 1) {
      m = alignment * ((rand() % 64) + 1);
    }
    if (k < 1) {
      k = alignment * ((rand() % 64) + 1);
    }

    for (int i = groups; i > 0; i--) {
      int n = cmd_line_n;
      if (n < 0) {
        n = alignment * ((rand() % 64) + 1);
      }
      problem_sizes_host.push_back({m, n, k});
      tokens_per_expert_host.push_back(n);
    }
    groups = static_cast<int>(problem_sizes_host.size());
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
        extent.at(i) = std::atoi(tokens.at(i).c_str());
      }
      problem_sizes_host.push_back({extent.m(), extent.n(), extent.k()});
      tokens_per_expert_host.push_back(extent.n());
    }

    groups = static_cast<int>(problem_sizes_host.size());
    m = get<0>(problem_sizes_host.at(0));
    k = get<2>(problem_sizes_host.at(0));

    return true;
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "92_blackwell_moe_gemm_blockscaled_rcgrouped\n\n"
      << "  Blackwell Block Scaled Narrow Precision Ragged Contiguous Grouped GEMM using a Warp Specialized kernel.\n\n"
      << "Options:\n\n"
      << "  --help                                                       If specified, displays this usage statement\n\n"
      << "  --m=<int>                                                    Sets the M extent of the GEMM for all groups\n"
      << "  --n=<int>                                                    Sets the N extent of the GEMM for all groups\n"
      << "  --k=<int>                                                    Sets the K extent of the GEMM for all groups\n"
      << "  --groups=<int>                                               Sets the number of individual GEMM problems for Grouped GEMM\n"
      << "  --alpha=<f32>                                                Epilogue scalar alpha\n"
      << "  --beta=<f32>                                                 Epilogue scalar beta\n"
      << "  --norm_constant=<f32>                                        Epilogue scalar normalization constant for the output matrix\n\n"
      << "  --cluster_m=<int>          and --cluster_n=<int>             Sets the X,Y dims of the preferred cluster shape\n"
      << "  --cluster_fallback_m=<int> and --cluster_fallback_n=<int>    Sets the X,Y dims of the fallback cluster shape\n\n"
      << "  --raster=<char>                                              CTA Rasterization direction (N for along N, M for along M)\n\n"
      << "  --iterations=<int>                                           Number of profiling iterations to perform\n\n"
      << "  --benchmark=<str>                                            Executes a benchmark problem size\n"
      << "  --max_sm_count=<int>                                         Run kernels using only these number of SMs\n"
      << "  --no_verif                                                   Do not run (host-side) verification kernels\n"
      << "  --use_pdl                                                    Launch kernel with PDL (Programmatic Dependent Launch) enabled\n";

    out
      << "\n\nExamples:\n\n"
      << "$ " << "92_blackwell_moe_gemm_blockscaled_rcgrouped" << " --m=1024 --n=512 --k=1024 --groups=10 --alpha=2 --beta=0.707 \n\n";

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

/// Result structure
struct Result
{
  double avg_runtime_ms = 0.0;
  double gflops = 0.0;
  cutlass::Status status = cutlass::Status::kSuccess;
  cudaError_t error = cudaSuccess;
  bool passed = false;
};

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM setup and evaluation
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to initialize a block of device data
template <typename Element, typename Layout>
bool initialize_block(
  cutlass::TensorView<Element, Layout> view,
  uint64_t seed) {

  double scope_max, scope_min;
  constexpr int bits_input = cutlass::sizeof_bits<Element>::value;

  if constexpr (bits_input == 1) {
    scope_max = 2;
    scope_min = 0;
  }
  else if constexpr (bits_input <= 6) {
    scope_max = 2;
    scope_min = -2;
  }
  else if constexpr (bits_input <= 8) {
    if constexpr (cute::is_same_v<Element, cutlass::float_ue8m0_t>) {
      scope_max = 4;
      scope_min = 1;
    }
    else {
      scope_max = 1;
      scope_min = -1;
    }
  }
  else{
    scope_max = 4;
    scope_min = -4;
  }

  cutlass::reference::host::TensorFillRandomUniform(
    view, seed, scope_max, scope_min, 0);

  return true;
}

/// Allocates device-side data
void allocate(const Options &options) {
  for (int32_t i = 0; i < options.groups; ++i) {
    auto problem = options.problem_sizes_host.at(i);
    auto M = get<0>(problem);
    auto N = get<1>(problem);
    auto K = get<2>(problem);

    auto stride_B = cutlass::make_cute_packed_stride(StrideB{}, {N, K, 1});
    auto stride_C = cutlass::make_cute_packed_stride(StrideC{}, {M, N, 1});
    auto stride_D = cutlass::make_cute_packed_stride(StrideD{}, {M, N, 1});

    auto layout_B = make_layout(make_shape(N, K, 1), stride_B);
    auto layout_C = make_layout(make_shape(M, N, 1), stride_C);
    auto layout_D = make_layout(make_shape(M, N, 1), stride_D);
    auto layout_SFB = Sm1xxBlkScaledConfig::tile_atom_to_shape_SFB(cute::make_shape(M, N, K, 1));
    auto layout_SFD = Sm1xxBlockScaledOutputConfig::tile_atom_to_shape_SFD(cute::make_shape(M, N, K, 1));

    block_B.push_back(HostTensorB(cutlass::make_Coord(size(layout_B))));
    block_SFB.push_back(HostTensorSF(cutlass::make_Coord(size(filter_zeros(layout_SFB)))));
    block_C.push_back(HostTensorC(cutlass::make_Coord(size(layout_C))));
    block_D.push_back(HostTensorD(cutlass::make_Coord(size(layout_D))));
    block_SFD.push_back(HostTensorSF(cutlass::make_Coord(size(filter_zeros(layout_SFD)))));
    block_ref_D.push_back(HostTensorD(cutlass::make_Coord(size(layout_D))));
  }
  block_alpha.reset(options.groups);
  block_beta.reset(options.groups);
}

/// Initialize operands to be used in the GEMM and reference GEMM
void initialize(const Options &options) {
  uint64_t seed = 2020;

  // Setting up tokens_per_expert array
  tokens_per_expert.reset(options.tokens_per_expert_host.size());
  tokens_per_expert.copy_from_host(options.tokens_per_expert_host.data());

  //
  // Assign pointers
  //

  std::vector<typename Gemm::ElementB *> ptr_B_host(options.groups);
  std::vector<typename Gemm::GemmKernel::ElementSF *> ptr_SFB_host(options.groups);
  std::vector<typename Gemm::ElementC *> ptr_C_host(options.groups);
  std::vector<typename Gemm::EpilogueOutputOp::ElementOutput *> ptr_D_host(options.groups);
  std::vector<typename Gemm::GemmKernel::ElementSF *> ptr_SFD_host(options.groups);
  std::vector<ElementAccumulator *> ptr_alpha_host(options.groups);
  std::vector<ElementAccumulator *> ptr_beta_host(options.groups);

  layout_SFA = Sm1xxBlkScaledConfig::tile_atom_to_shape_SFA(cute::make_shape(options.m, options.n, options.k, options.groups));

  stride_A = cutlass::make_cute_packed_stride(StrideA{}, {options.m, options.k, options.groups});
  auto layout_A = make_layout(make_shape(options.m, options.k, options.groups), stride_A);
  block_A.reset(cutlass::make_Coord(size(layout_A)));

  block_SFA.reset(cutlass::make_Coord(size(filter_zeros(layout_SFA))));
  initialize_block(block_A.host_view(), seed + 2022);
  initialize_block(block_SFA.host_view(), seed + 2024);

  block_A.sync_device();
  block_SFA.sync_device();

  for (int32_t i = 0; i < options.groups; ++i) {

    initialize_block(block_B.at(i).host_view(), seed + 2022);
    initialize_block(block_C.at(i).host_view(), seed + 2023);
    initialize_block(block_SFB.at(i).host_view(), seed + 2025);

    block_B.at(i).sync_device();
    block_C.at(i).sync_device();
    block_SFB.at(i).sync_device();

    ptr_B_host.at(i) = block_B.at(i).device_data();
    ptr_SFB_host.at(i) = block_SFB.at(i).device_data();
    ptr_C_host.at(i) = block_C.at(i).device_data();
    ptr_D_host.at(i) = block_D.at(i).device_data();
    ptr_SFD_host.at(i) = block_SFD.at(i).device_data();

    alpha_host.push_back((options.alpha == FLT_MAX) ? static_cast<ElementAccumulator>((rand() % 5) + 1) : options.alpha);
    beta_host.push_back((options.beta == FLT_MAX) ? static_cast<ElementAccumulator>(rand() % 5) : options.beta);
    ptr_alpha_host.at(i) = block_alpha.get() + i;
    ptr_beta_host.at(i) = block_beta.get() + i;
  }

  ptr_B.reset(options.groups);
  ptr_B.copy_from_host(ptr_B_host.data());

  ptr_SFB.reset(options.groups);
  ptr_SFB.copy_from_host(ptr_SFB_host.data());

  ptr_C.reset(options.groups);
  ptr_C.copy_from_host(ptr_C_host.data());

  ptr_D.reset(options.groups);
  ptr_D.copy_from_host(ptr_D_host.data());

  ptr_SFD.reset(options.groups);
  ptr_SFD.copy_from_host(ptr_SFD_host.data());

  alpha_device.reset(options.groups);
  alpha_device.copy_from_host(ptr_alpha_host.data());
  beta_device.reset(options.groups);
  beta_device.copy_from_host(ptr_beta_host.data());

  block_alpha.copy_from_host(alpha_host.data());
  block_beta.copy_from_host(beta_host.data());

  norm_constant_device.reset(1);
  norm_constant_device.copy_from_host(&options.norm_constant);
}

/// Populates a Gemm::Arguments structure from the given commandline options
template <typename Gemm>
typename Gemm::Arguments args_from_options(Options &options) {
  cutlass::KernelHardwareInfo hw_info;
  // Change device_id to another value if you are running on a machine with multiple GPUs and wish
  // to use a GPU other than that with device ID 0.
  hw_info.device_id = 0;
  hw_info.sm_count = min(cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id), options.max_sm_count);

  if (!is_static_v<ClusterShape>) {
    if (size<0>(typename Gemm::GemmKernel::CollectiveMainloop::AtomThrShapeMNK{}) == 2 &&
        (options.cluster_shape.x < 2 || options.cluster_shape_fallback.x < 2)) {
      std::cout << "Error: MMA2SMConfig kernel config needs cluster_dim.x >= 2" << std::endl;
      exit(-1);
    }
    hw_info.cluster_shape = options.cluster_shape;
    hw_info.cluster_shape_fallback = options.cluster_shape_fallback;
  }

  typename Gemm::Arguments arguments;
  decltype(arguments.epilogue.thread) fusion_args;
  fusion_args.alpha_ptr = nullptr;
  fusion_args.beta_ptr = nullptr;

  // If alpha/beta are provided (via cmd line args) and are scalar, i.e., same alpha/beta applies to all batches.
  // If pointers to alpha/beta are provided, i.e., alpha/beta can differ between batches/groups.
  if (options.alpha != FLT_MAX){
    // Single alpha for all groups
    fusion_args.alpha = options.alpha;
    fusion_args.alpha_ptr_array = nullptr;
    fusion_args.dAlpha = {_0{}, _0{}, 0};
  }
  else {
    fusion_args.alpha = 0;
    fusion_args.alpha_ptr_array = alpha_device.get();
    // Only one alpha per each group
    fusion_args.dAlpha = {_0{}, _0{}, 1};
  }
  if (options.beta != FLT_MAX) {
    // Single beta for all groups
    fusion_args.beta = options.beta;
    fusion_args.beta_ptr_array = nullptr;
    fusion_args.dBeta = {_0{}, _0{}, 0};
  }
  else {
    fusion_args.beta = 0;
    fusion_args.beta_ptr_array = beta_device.get();
    // Only one beta per each group
    fusion_args.dBeta = {_0{}, _0{}, 1};
  }

  typename Gemm::GemmKernel::TileSchedulerArguments scheduler;
  scheduler.raster_order = options.raster_order;

  arguments = typename Gemm::Arguments {
    cutlass::gemm::GemmUniversalMode::kGrouped,
    {options.m, options.n, options.k, options.groups, tokens_per_expert.get()},
    {block_A.device_data(), ptr_B.get(), 
     block_SFA.device_data(), ptr_SFB.get()},
    {fusion_args, ptr_C.get(), nullptr, ptr_D.get(), nullptr},
    hw_info, scheduler
  };

  return arguments;
}

bool verify(const Options &options) {
  using namespace cute;
  bool passed = true;
  for (int32_t i = 0; i < options.groups; ++i) {
    auto problem = options.problem_sizes_host.at(i);
    auto M = get<0>(problem);
    auto N = get<1>(problem);
    auto K = get<2>(problem);

    auto stride_A = cutlass::make_cute_packed_stride(StrideA{}, {M, K, 1});
    auto stride_B = cutlass::make_cute_packed_stride(StrideB{}, {N, K, 1});
    auto stride_C = cutlass::make_cute_packed_stride(StrideC{}, {M, N, 1});
    auto stride_D = cutlass::make_cute_packed_stride(StrideD{}, {M, N, 1});
    auto layout_A = make_layout(make_shape(M, K, 1), stride_A);
    auto layout_B = make_layout(make_shape(N, K, 1), stride_B);
    auto layout_C = make_layout(make_shape(M, N, 1), stride_C);
    auto layout_D = make_layout(make_shape(M, N, 1), stride_D);
    auto layout_SFA = Sm1xxBlkScaledConfig::tile_atom_to_shape_SFA(cute::make_shape(M, N, K, 1));
    auto layout_SFB = Sm1xxBlkScaledConfig::tile_atom_to_shape_SFB(cute::make_shape(M, N, K, 1));
    auto layout_SFD = Sm1xxBlockScaledOutputConfig::tile_atom_to_shape_SFD(cute::make_shape(M, N, K, 1));

    // Create the arguments for host reference implementation
    Tensor tensor_A = make_tensor(make_iterator(block_A.host_data()) + size_t(1) * i * size(layout_A), layout_A);
    Tensor tensor_SFA = make_tensor(block_SFA.host_data() + size_t(1) * i * size(filter_zeros(layout_SFA)), layout_SFA);
    Tensor tensor_B = make_tensor(make_iterator(block_B.at(i).host_data()), layout_B);
    Tensor tensor_SFB = make_tensor(block_SFB.at(i).host_data(), layout_SFB);
    cutlass::reference::host::GettBlockScalingMainloopParams<ElementAccumulator,
        decltype(tensor_A),
        decltype(tensor_SFA),
        decltype(tensor_B),
        decltype(tensor_SFB)
      >
    mainloop_params{tensor_A, tensor_SFA, tensor_B, tensor_SFB};

    auto tensor_C = cute::make_tensor(make_iterator(block_C.at(i).host_data()), layout_C);
    auto tensor_ref_D = cute::make_tensor(make_iterator(block_ref_D.at(i).host_data()), layout_D);

    cutlass::reference::host::GettEpilogueParams<
        float, float,
        ElementAccumulator, ElementAccumulator,
        decltype(tensor_C), decltype(tensor_ref_D)
      > epilogue_params{};

    epilogue_params.C = tensor_C;
    epilogue_params.D = tensor_ref_D;
    epilogue_params.alpha = alpha_host.at(i);
    epilogue_params.beta = beta_host.at(i);

    cutlass::reference::host::Gemm3x(mainloop_params, epilogue_params);

    block_D.at(i).sync_host();
    // Check if output from CUTLASS kernel and reference kernel are equal or not
    passed &= cutlass::reference::host::TensorEquals(block_ref_D.at(i).host_view(), block_D.at(i).host_view());

  }
  return passed;
}

/// Execute a given example GEMM computation
template <typename Gemm>
int run(Options &options)
{
  std::cout << "  Problem Sizes, Alpha, Beta " << std::endl;
  for (int32_t i = 0; i < options.groups; ++i) {
    std::cout << "    " << options.problem_sizes_host.at(i);
    std::cout << ", " << alpha_host.at(i) << ", " << beta_host.at(i) << std::endl;
  }
  std::cout << "  Groups      : " << options.groups  << std::endl;

  // Instantiate CUTLASS kernel depending on templates
  Gemm gemm;

  // Create a structure of gemm kernel arguments suitable for invoking an instance of Gemm
  auto arguments = args_from_options<Gemm>(options);

  // Using the arguments, query for extra workspace required for matrix multiplication computation
  size_t workspace_size = Gemm::get_workspace_size(arguments);

  // Allocate workspace memory
  cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

  // Check if the problem size is supported or not
  CUTLASS_CHECK(gemm.can_implement(arguments));

  // Initialize CUTLASS kernel with arguments and workspace pointer
  CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));

  // Correctness / Warmup iteration
  CUTLASS_CHECK(gemm.run(/* stream = */ nullptr, /* cuda_adapter = */ nullptr, /* launch_with_pdl = */ options.use_pdl));

  cudaDeviceSynchronize();

  // Check if output from CUTLASS kernel and reference kernel are equal or not
  Result result;
  if (options.verification) {
    std::cout << "  Host-side verification is now running - may be very slow for large cases." << std::endl;
    result.passed = verify(options);
    std::cout << "  Disposition: " << (result.passed ? "Passed" : "Failed") << std::endl;
    if (!result.passed) {
      exit(-1);
    }
  }
  else {
    std::cout << "  Verification is turned off for this run." << std::endl;
  }

  // Run profiling loop
  if (options.iterations > 0) {
    for (int iter = 0; iter < options.warmup; ++iter) {
      CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));
      CUTLASS_CHECK(gemm.run(/* stream = */ nullptr, /* cuda_adapter = */ nullptr, /* launch_with_pdl = */ options.use_pdl));
    }
    GpuTimer timer;
    timer.start();
    for (int iter = 0; iter < options.iterations; ++iter) {
      CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));
      CUTLASS_CHECK(gemm.run(/* stream = */ nullptr, /* cuda_adapter = */ nullptr, /* launch_with_pdl = */ options.use_pdl));
    }
    timer.stop();

    // Compute average setup and runtime and GFLOPs.
    float elapsed_ms       = timer.elapsed_millis();
    result.avg_runtime_ms  = double(elapsed_ms) / double(options.iterations);
    result.gflops          = options.gflops(result.avg_runtime_ms / 1000.0, options.problem_sizes_host);

    std::cout << "  Avg runtime : " << result.avg_runtime_ms << " ms" << std::endl;
    std::cout << "  TFLOPS      : " << result.gflops / 1000.0 << std::endl;
  }

  return 0;
}

#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  // CUTLASS must be compiled with CUDA 12.8 Toolkit to run this example
  if (__CUDACC_VER_MAJOR__ < 12 ||
       ((__CUDACC_VER_MAJOR__ == 12 && __CUDACC_VER_MINOR__ < 8)
       )
     ) {
    std::cerr << "This example requires CUDA 12.8 or newer.\n";
    // Returning zero so this test passes on older Toolkits. Its actions are no-op.
    return 0;
  }

  cudaDeviceProp props;
  int current_device_id;
  CUDA_CHECK(cudaGetDevice(&current_device_id));
  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device_id));
  cudaError_t error = cudaGetDeviceProperties(&props, 0);
  if (props.major != 10 || (props.minor != 0 && props.minor != 1 && props.minor != 3
       )
     ) {
    std::cerr << "This example requires a GPU with compute capability 100a|f, 101a|f, or 103a|f)." << std::endl;
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

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
  allocate(options);
  initialize(options);

  //
  // Evaluate CUTLASS kernels
  //

  std::cout << "Running kernel with 1SM MMA config:" << std::endl;
  run<Gemm1SM>(options);
  std::cout << "Running kernel with 2SM MMA config:" << std::endl;
  run<Gemm2SM>(options);
#endif

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
