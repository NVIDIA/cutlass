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
    \brief Hopper Grouped GEMM with fused Bias + Gated-SwiGLU epilogue.

    This example extends 57_hopper_grouped_gemm.cu to demonstrate a fully-fused
    epilogue that:
      1) Loads a per-group BF16 row bias [2*I] into smem via cp.async
         (Sm90RowBroadcast, EVT child leaf).
      2) Adds the bias to the FP32 GEMM accumulator (Sm90Compute<plus>).
      3) Stores the bias-added pre-activation [M_i, 2*I] to gmem
         (the "aux D" output, useful for backward pass).
      4) Computes Gated-SwiGLU on (gate, up) pairs and TMA-stores the
         half-width result [M_i, I] to a separate output buffer
         (Sm90GatedSwiGLUStoreTma, EVT root with HasAuxTmaStore=true).

    The kernel signature: per group i,
        gate_up_i = A_i [M_i, K] @ B_i [K, 2*I] + bias_i [2*I]   (bf16, "aux D")
        swiglu_i  = SwiGLU(gate_up_i)                            (bf16, [M_i, I])

      The SwiGLU activation is the OpenAI "openai-style" approximation used by
      GPT-OSS / mxfp4 swiglu: with alpha = 1.702 and limit = 7.0,
        g_clip = min(gate, limit)
        u_clip = clamp(up, -limit, limit)
        s      = 0.5 * (1 + tanh(alpha * 0.5 * g_clip))
        out    = g_clip * s * u_clip + g_clip * s

    To run this example:

      $ ./examples/57_hopper_grouped_gemm/57_hopper_bias_swiglu_grouped_gemm \
            --m=1024 --n=4096 --k=2048 --groups=8

      Here --n is the GEMM-N dimension which equals 2*I (gate + up
      concatenated); the SwiGLU output has half that width per row.

    Both the Cooperative and Pingpong PtrArray TMA warp-specialized schedules
    are exercised.
*/

#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"
#include "cutlass/tensor_ref.h"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_tma_warpspecialized.hpp"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/group_array_problem_shape.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"

#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/device/gemm.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "cutlass/util/reference/device/tensor_fill.h"

#include "helper.h"

// Custom EVT visitors (copies of PR_todo headers, kept inside this example so
// the binary is self-contained relative to the cutlass include tree).
#include "sm90_gated_swiglu_store_tma.hpp"

using namespace cute;

using ProblemShape = cutlass::gemm::GroupProblemShape<Shape<int,int,int>>; // <M, N=2I, K>

using ElementA       = cutlass::bfloat16_t;
using ElementB       = cutlass::bfloat16_t;
using ElementOutput  = cutlass::bfloat16_t;   // aux_D and SwiGLU output
using ElementBias    = cutlass::bfloat16_t;
using ElementAccum   = float;

#if defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

static_assert(std::is_same_v<ElementOutput, cutlass::bfloat16_t>,
    "Sm90GatedSwiGLUStoreTma uses tanh.approx.bf16x2 and requires bf16 output");

/////////////////////////////////////////////////////////////////////////////////////////////////
// Layouts / alignments
/////////////////////////////////////////////////////////////////////////////////////////////////

using LayoutA      = cutlass::layout::RowMajor;
using LayoutB      = cutlass::layout::ColumnMajor;
using LayoutOutput = cutlass::layout::RowMajor;

constexpr int AlignmentA      = 128 / cutlass::sizeof_bits<ElementA>::value;       // 8 bf16
constexpr int AlignmentB      = 128 / cutlass::sizeof_bits<ElementB>::value;       // 8 bf16
constexpr int AlignmentOutput = 128 / cutlass::sizeof_bits<ElementOutput>::value;  // 8 bf16
constexpr int AlignmentBias   = AlignmentOutput;

using ArchTag      = cutlass::arch::Sm90;
using OperatorClass = cutlass::arch::OpClassTensorOp;

/////////////////////////////////////////////////////////////////////////////////////////////////
// Schedule configurations
/////////////////////////////////////////////////////////////////////////////////////////////////

struct CooperativeConfig {
  using KernelSchedule   = cutlass::gemm::KernelPtrArrayTmaWarpSpecializedCooperative;
  using EpilogueSchedule = cutlass::epilogue::PtrArrayTmaWarpSpecializedCooperative;
  using TileShape    = Shape<_128, _256, _64>;
  using ClusterShape = Shape<_2,   _1,   _1>;
  static constexpr int EpiThreadCount = 256;
};

struct PingpongConfig {
  using KernelSchedule   = cutlass::gemm::KernelPtrArrayTmaWarpSpecializedPingpong;
  using EpilogueSchedule = cutlass::epilogue::PtrArrayTmaWarpSpecializedPingpong;
  using TileShape    = Shape<_128, _128, _64>;
  using ClusterShape = Shape<_2,   _1,   _1>;
  static constexpr int EpiThreadCount = 128;
};

/////////////////////////////////////////////////////////////////////////////////////////////////
// GEMM instantiation per schedule
//
// EVT tree: SwiGLUStore( Plus( AccFetch, RowBroadcastVec ) )
//   leaf  Sm90AccFetch                -> FP32 accumulator
//   leaf  Sm90RowBroadcast<...>    -> per-group bf16 bias [2I], cp.async loaded
//   inner Sm90Compute<plus, bf16, fp32> -> elementwise (acc + bias)
//   root  Sm90GatedSwiGLUStoreTma     -> aux_D store + TMA SwiGLU half-width store
//
// We build a 'reference' epilogue first to pull EpiTile / SmemLayoutAtomD /
// CopyOpR2S / StagesD out of the builder (the SwiGLU root visitor needs them
// to size its own smem and pipeline correctly), then assemble the real fusion.
/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename ScheduleConfig>
struct GemmGivenSchedule {
  using TileShape         = typename ScheduleConfig::TileShape;
  using ClusterShape      = typename ScheduleConfig::ClusterShape;
  using KernelSchedule    = typename ScheduleConfig::KernelSchedule;
  using EpilogueSchedule  = typename ScheduleConfig::EpilogueSchedule;
  static constexpr int EpiThreadCount = ScheduleConfig::EpiThreadCount;

  static constexpr auto RoundStyle = cutlass::FloatRoundStyle::round_to_nearest;

  // ----- Phase 1: reference epilogue (stock Sm90RowBroadcast) -----
  using AccFetchRef  = cutlass::epilogue::fusion::Sm90AccFetch;
  using BiasBcastRef = cutlass::epilogue::fusion::Sm90RowBroadcast<
      0, TileShape, ElementBias*, ElementAccum,
      Stride<_0, _1, _0>, AlignmentBias>;
  using PlusRef      = cutlass::epilogue::fusion::Sm90Compute<
      cutlass::plus, ElementOutput, ElementAccum, RoundStyle>;
  using FusionRef    = cutlass::epilogue::fusion::Sm90EVT<PlusRef, AccFetchRef, BiasBcastRef>;

  using RefEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      ArchTag, OperatorClass,
      TileShape, ClusterShape,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccum, ElementAccum,
      void, void, 0,                                    // no source C matrix
      ElementOutput, LayoutOutput*, AlignmentOutput,
      EpilogueSchedule,
      FusionRef>::CollectiveOp;

  using EpiTile         = typename RefEpilogue::EpilogueTile;
  using SmemLayoutAtomD = typename RefEpilogue::SmemLayoutAtomD;
  using CopyOpR2S       = typename RefEpilogue::CopyOpR2S;
  static constexpr int StagesD = RefEpilogue::DispatchPolicy::StagesD;

  // ----- Phase 2: real EVT tree -----
  using AccFetch  = cutlass::epilogue::fusion::Sm90AccFetch;
  using BiasBcast = cutlass::epilogue::fusion::Sm90RowBroadcast<
      /*Stages=*/0,                                     // visitor uses no smem stage
      TileShape,
      ElementBias*,                                     // PtrArray (per-group bias)
      ElementAccum,
      Stride<_0, _1, _0>,
      AlignmentBias>;
  using PlusOp    = cutlass::epilogue::fusion::Sm90Compute<
      cutlass::plus, ElementOutput, ElementAccum, RoundStyle>;
  using AccPlusBiasEVT = cutlass::epilogue::fusion::Sm90EVT<PlusOp, AccFetch, BiasBcast>;

  using SwiGLUStore = cutlass::epilogue::fusion::Sm90GatedSwiGLUStoreTma<
      StagesD,
      EpiTile,
      ElementOutput,
      ElementAccum,
      RoundStyle,
      SmemLayoutAtomD,
      CopyOpR2S,
      AlignmentOutput,
      /*EnableNullptr=*/true,
      EpiThreadCount>;

  using SwiGLUFusion = cutlass::epilogue::fusion::Sm90EVT<SwiGLUStore, AccPlusBiasEVT>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      ArchTag, OperatorClass,
      TileShape, ClusterShape,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccum, ElementAccum,
      void, void, 0,                                    // no source C matrix
      ElementOutput, LayoutOutput*, AlignmentOutput,    // aux D output
      EpilogueSchedule,
      SwiGLUFusion>::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      ArchTag, OperatorClass,
      ElementA, LayoutA*, AlignmentA,
      ElementB, LayoutB*, AlignmentB,
      ElementAccum,
      TileShape, ClusterShape,
      cutlass::gemm::collective::StageCountAutoCarveout<
          static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      KernelSchedule>::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      ProblemShape, CollectiveMainloop, CollectiveEpilogue>;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
};

using Gemm         = GemmGivenSchedule<CooperativeConfig>::Gemm;
using GemmPingpong = GemmGivenSchedule<PingpongConfig>::Gemm;

// Reference device GEMM (FP32 accum -> bf16 output, no bias / no activation).
using DeviceGemmReference = cutlass::reference::device::Gemm<
    ElementA, LayoutA,
    ElementB, LayoutB,
    ElementOutput, LayoutOutput,
    ElementAccum, ElementAccum>;

using StrideA = typename Gemm::GemmKernel::InternalStrideA;
using StrideB = typename Gemm::GemmKernel::InternalStrideB;
using StrideD = typename Gemm::GemmKernel::InternalStrideD;

// Cooperative and Pingpong share the same A/B/D stride types because they're
// derived from the layouts (RowMajor / ColMajor / RowMajor), not the kernel
// schedule. Pin this with a static_assert so a future schedule divergence
// fails at compile time rather than silently mismapping device strides.
static_assert(std::is_same_v<StrideA, typename GemmPingpong::GemmKernel::InternalStrideA>,
    "Cooperative / Pingpong StrideA mismatch");
static_assert(std::is_same_v<StrideB, typename GemmPingpong::GemmKernel::InternalStrideB>,
    "Cooperative / Pingpong StrideB mismatch");
static_assert(std::is_same_v<StrideD, typename GemmPingpong::GemmKernel::InternalStrideD>,
    "Cooperative / Pingpong StrideD mismatch");

/////////////////////////////////////////////////////////////////////////////////////////////////
// Reference kernels for bias + SwiGLU on device (used only by verify())
/////////////////////////////////////////////////////////////////////////////////////////////////

static __global__ void add_row_bias_row_major_kernel(
    cutlass::bfloat16_t* D, cutlass::bfloat16_t const* bias, int M, int N) {
  int64_t idx = blockIdx.x * static_cast<int64_t>(blockDim.x) + threadIdx.x;
  int64_t total = static_cast<int64_t>(M) * N;
  if (idx >= total) return;
  int n = static_cast<int>(idx % N);                  // row-major: contiguous in N
  float v = static_cast<float>(D[idx]) + static_cast<float>(bias[n]);
  D[idx] = cutlass::bfloat16_t(v);
}

static __global__ void swiglu_reference_kernel(
    cutlass::bfloat16_t const* D_pre,
    cutlass::bfloat16_t*       out,
    int M, int Nhalf,
    float alpha, float limit) {
  int64_t idx = blockIdx.x * static_cast<int64_t>(blockDim.x) + threadIdx.x;
  int64_t total = static_cast<int64_t>(M) * Nhalf;
  if (idx >= total) return;
  int m = static_cast<int>(idx / Nhalf);
  int n = static_cast<int>(idx % Nhalf);
  int64_t base = static_cast<int64_t>(m) * (2 * Nhalf);
  float g = static_cast<float>(D_pre[base + 2 * n + 0]);
  float u = static_cast<float>(D_pre[base + 2 * n + 1]);
  g = fminf(g, limit);
  u = fmaxf(fminf(u, limit), -limit);
  float s  = 0.5f * (1.f + tanhf(alpha * 0.5f * g));
  float gs = g * s;
  float r  = gs * u + gs;
  out[idx] = cutlass::bfloat16_t(r);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// Host-side allocations
/////////////////////////////////////////////////////////////////////////////////////////////////

std::vector<int64_t> offset_A;     // start element of each group in block_A     (size M_i*K)
std::vector<int64_t> offset_B;     // size K * N    (N = 2I)
std::vector<int64_t> offset_aux;   // size M_i * N  (aux D & ref pre-activation)
std::vector<int64_t> offset_swi;   // size M_i * I

std::vector<StrideA> stride_A_host;
std::vector<StrideB> stride_B_host;
std::vector<StrideD> stride_D_host;

// Device-side allocations
cutlass::DeviceAllocation<typename ProblemShape::UnderlyingProblemShape> problem_sizes;

cutlass::DeviceAllocation<ElementA>      block_A;
cutlass::DeviceAllocation<ElementB>      block_B;
cutlass::DeviceAllocation<ElementBias>   block_bias;       // groups * N
cutlass::DeviceAllocation<ElementOutput> block_aux_D;      // sum(M_i) * N
cutlass::DeviceAllocation<ElementOutput> block_swiglu;     // sum(M_i) * I
cutlass::DeviceAllocation<ElementOutput> block_ref_pre;    // sum(M_i) * N (pre-activation reference)
cutlass::DeviceAllocation<ElementOutput> block_ref_swiglu; // sum(M_i) * I

cutlass::DeviceAllocation<const ElementA*>      ptr_A;
cutlass::DeviceAllocation<const ElementB*>      ptr_B;
cutlass::DeviceAllocation<ElementOutput*>       ptr_aux_D;    // visitor side: ptr_D
cutlass::DeviceAllocation<ElementBias*>         ptr_bias;     // bias is bf16** (non-const)
cutlass::DeviceAllocation<ElementOutput*>       ptr_swiglu;

cutlass::DeviceAllocation<StrideA> stride_A;
cutlass::DeviceAllocation<StrideB> stride_B;
cutlass::DeviceAllocation<StrideD> stride_D;       // also reused for aux_D (same layout)

#endif // defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
// Command-line options
/////////////////////////////////////////////////////////////////////////////////////////////////

struct Options {
  bool help = false;
  int iterations = 10;

  // M can be randomized per group; N (= 2*I) and K are constant across groups
  // because the SwiGLU visitor stores a single N_out / stride_swiglu in Params
  // (Sm90GatedSwiGLUStoreTma::Arguments fields N_out / stride_swiglu apply to
  // every group via aux_tensormaps_replace).
  int m = 1024, n = 4096, k = 2048, groups = 8;
  std::string benchmark_path;
  std::vector<typename ProblemShape::UnderlyingProblemShape> problem_sizes_host;

  float swiglu_alpha = 1.702f;
  float swiglu_limit = 7.0f;

  int const tma_alignment_bits = 128;
  int const alignment = tma_alignment_bits / cutlass::sizeof_bits<ElementA>::value;

  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);
    if (cmd.check_cmd_line_flag("help")) { help = true; return; }

    cmd.get_cmd_line_argument("m", m);
    cmd.get_cmd_line_argument("n", n);
    cmd.get_cmd_line_argument("k", k);
    cmd.get_cmd_line_argument("groups", groups);
    cmd.get_cmd_line_argument("iterations", iterations);
    cmd.get_cmd_line_argument("benchmark", benchmark_path);
    cmd.get_cmd_line_argument("swiglu_alpha", swiglu_alpha);
    cmd.get_cmd_line_argument("swiglu_limit", swiglu_limit);

    if (!benchmark_path.empty()) {
      if (!benchmark_problems()) { problem_sizes_host.clear(); return; }
    } else {
      randomize_problems(cmd);
    }
  }

  void randomize_problems(cutlass::CommandLine &cmd) {
    int cmd_line_m = -1;
    cmd.get_cmd_line_argument("m", cmd_line_m);
    problem_sizes_host.reserve(groups);

    // N and K are shared across groups (see field comment above).
    // M can vary; if --m is omitted, randomize per group.
    std::srand(2024);                              // deterministic problem shapes across runs
    for (int i = 0; i < groups; ++i) {
      int m_i = cmd_line_m;
      if (m_i < 0) {
        m_i = alignment * ((std::rand() % 64) + 1);
      }
      problem_sizes_host.push_back({m_i, n, k});
    }
  }

  bool benchmark_problems() {
    std::ifstream file(benchmark_path);
    if (!file.good()) return false;

    // Force every problem to share the same N and K (taken from the FIRST
    // entry); only M varies.
    int n_first = -1;
    int k_first = -1;
    while (file.good()) {
      int idx = -1;
      std::string extent_str;
      file >> idx >> extent_str;
      if (idx < 0 || extent_str.empty()) break;

      cutlass::gemm::GemmCoord extent;
      std::vector<std::string> tokens;
      cutlass::CommandLine::tokenize(tokens, extent_str, 'x');
      for (int i = 0; i < int(tokens.size()); ++i) {
        extent.at(i) = std::atoi(tokens.at(i).c_str());
      }
      if (n_first < 0) { n_first = extent.n(); k_first = extent.k(); n = n_first; k = k_first; }
      problem_sizes_host.push_back({extent.m(), n_first, k_first});
    }
    groups = static_cast<int>(problem_sizes_host.size());
    return true;
  }

  bool valid() const {
    if (groups <= 0)      return false;
    if (n % 16 != 0)      return false;   // bias / aux D / TMA all require multiples of 16
    if ((n / 2) % 8 != 0) return false;   // SwiGLU half-width must be 8-aligned
    if (k <= 0 || k % 8 != 0) return false;
    for (auto const& p : problem_sizes_host) {
      if (get<0>(p) <= 0 || get<1>(p) <= 0 || get<2>(p) <= 0) return false;
      if (get<1>(p) != n || get<2>(p) != k) return false;   // N, K must be shared
    }
    return true;
  }

  std::ostream & print_usage(std::ostream &out) const {
    out << "57_hopper_bias_swiglu_grouped_gemm\n\n"
        << "  Hopper BF16 Grouped GEMM with fused per-group bias + Gated-SwiGLU\n"
        << "  epilogue. The GEMM produces [M_i, 2*I] = bias-added pre-activations\n"
        << "  (stored to aux_D), and the SwiGLU output [M_i, I] is TMA-stored to a\n"
        << "  separate buffer.\n\n"
        << "Options:\n\n"
        << "  --help                      Display this usage statement\n"
        << "  --m=<int>                   Per-group M (random if omitted)\n"
        << "  --n=<int>                   GEMM N = 2*I (shared across groups)\n"
        << "  --k=<int>                   Shared K\n"
        << "  --groups=<int>              Number of groups (problems)\n"
        << "  --iterations=<int>          Profiling iterations (0 to skip)\n"
        << "  --swiglu_alpha=<f32>        SwiGLU alpha (default 1.702)\n"
        << "  --swiglu_limit=<f32>        SwiGLU clamp limit (default 7.0)\n"
        << "  --benchmark=<str>           Benchmark file (idx MxNxK per line)\n\n"
        << "Examples:\n\n"
        << "$ 57_hopper_bias_swiglu_grouped_gemm --m=1024 --n=4096 --k=2048 --groups=8\n";
    return out;
  }

  // GEMM-only flops: counts 2*M*N*K per group; bias-add and SwiGLU are timed
  // by GpuTimer but intentionally not counted here.
  double gflops(double runtime_s) const {
    uint64_t fmas = 0;
    for (auto const& p : problem_sizes_host) {
      fmas += uint64_t(get<0>(p)) * uint64_t(get<1>(p)) * uint64_t(get<2>(p));
    }
    return double(2 * fmas) / 1.0e9 / runtime_s;
  }
};

struct Result {
  double avg_runtime_ms = 0.0;
  double gflops = 0.0;
  cutlass::Status status = cutlass::Status::kSuccess;
  cudaError_t error = cudaSuccess;
  bool passed = false;
};

#if defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
// Init / allocate
/////////////////////////////////////////////////////////////////////////////////////////////////

template <class Element>
bool initialize_block(cutlass::DeviceAllocation<Element>& block, uint64_t seed) {
  Element scope_max, scope_min;
  int bits_input = cutlass::sizeof_bits<Element>::value;
  if (bits_input == 1)       { scope_max = Element(2);  scope_min = Element(0);  }
  else if (bits_input <= 8)  { scope_max = Element(2);  scope_min = Element(-2); }
  else                       { scope_max = Element(4);  scope_min = Element(-4); }
  cutlass::reference::device::BlockFillRandomUniform(
      block.get(), block.size(), seed, scope_max, scope_min, 0);
  return true;
}

void allocate(const Options &options) {
  offset_A.clear();   offset_B.clear();
  offset_aux.clear(); offset_swi.clear();
  stride_A_host.clear(); stride_B_host.clear(); stride_D_host.clear();

  int64_t total_A = 0, total_B = 0, total_aux = 0, total_swi = 0;

  for (int i = 0; i < options.groups; ++i) {
    auto const& p = options.problem_sizes_host.at(i);
    int M = get<0>(p);
    int N = get<1>(p);            // = 2*I
    int K = get<2>(p);
    int Ihalf = N / 2;

    offset_A.push_back(total_A);
    offset_B.push_back(total_B);
    offset_aux.push_back(total_aux);
    offset_swi.push_back(total_swi);

    total_A   += int64_t(M) * K;
    total_B   += int64_t(K) * N;
    total_aux += int64_t(M) * N;
    total_swi += int64_t(M) * Ihalf;

    stride_A_host.push_back(cutlass::make_cute_packed_stride(StrideA{}, {M, K, 1}));
    stride_B_host.push_back(cutlass::make_cute_packed_stride(StrideB{}, {N, K, 1}));
    stride_D_host.push_back(cutlass::make_cute_packed_stride(StrideD{}, {M, N, 1}));
  }

  block_A.reset(total_A);
  block_B.reset(total_B);
  block_aux_D.reset(total_aux);
  block_ref_pre.reset(total_aux);
  block_swiglu.reset(total_swi);
  block_ref_swiglu.reset(total_swi);
  block_bias.reset(int64_t(options.groups) * options.n);
}

void initialize(const Options &options) {
  uint64_t seed = 2024;

  problem_sizes.reset(options.groups);
  problem_sizes.copy_from_host(options.problem_sizes_host.data());

  std::vector<ElementA*>       host_ptr_A(options.groups);
  std::vector<ElementB*>       host_ptr_B(options.groups);
  std::vector<ElementOutput*>  host_ptr_aux_D(options.groups);
  std::vector<ElementBias*>    host_ptr_bias(options.groups);
  std::vector<ElementOutput*>  host_ptr_swiglu(options.groups);

  for (int i = 0; i < options.groups; ++i) {
    host_ptr_A.at(i)      = block_A.get()      + offset_A.at(i);
    host_ptr_B.at(i)      = block_B.get()      + offset_B.at(i);
    host_ptr_aux_D.at(i)  = block_aux_D.get()  + offset_aux.at(i);
    host_ptr_swiglu.at(i) = block_swiglu.get() + offset_swi.at(i);
    host_ptr_bias.at(i)   = block_bias.get()   + int64_t(i) * options.n;
  }

  ptr_A.reset(options.groups);       ptr_A.copy_from_host(host_ptr_A.data());
  ptr_B.reset(options.groups);       ptr_B.copy_from_host(host_ptr_B.data());
  ptr_aux_D.reset(options.groups);   ptr_aux_D.copy_from_host(host_ptr_aux_D.data());
  ptr_bias.reset(options.groups);    ptr_bias.copy_from_host(host_ptr_bias.data());
  ptr_swiglu.reset(options.groups);  ptr_swiglu.copy_from_host(host_ptr_swiglu.data());

  stride_A.reset(options.groups);    stride_A.copy_from_host(stride_A_host.data());
  stride_B.reset(options.groups);    stride_B.copy_from_host(stride_B_host.data());
  stride_D.reset(options.groups);    stride_D.copy_from_host(stride_D_host.data());

  initialize_block(block_A,    seed + 1);
  initialize_block(block_B,    seed + 2);
  initialize_block(block_bias, seed + 3);

  // Sentinel-fill output buffers so a kernel that fails to write some
  // positions is caught by verify() rather than silently passing on
  // residual cudaMalloc memory.
  CUDA_CHECK(cudaMemset(block_aux_D.get(), 0xFF,
      block_aux_D.size() * sizeof(ElementOutput)));
  CUDA_CHECK(cudaMemset(block_swiglu.get(), 0xFF,
      block_swiglu.size() * sizeof(ElementOutput)));
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// Arguments construction
/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename GemmT>
typename GemmT::Arguments args_from_options(const Options &options,
                                            bool host_problem_shapes_available = true) {
  int device_id = 0;
  cutlass::KernelHardwareInfo kernel_hw_info =
      cutlass::KernelHardwareInfo::make_kernel_hardware_info<typename GemmT::GemmKernel>(device_id);

  // GEMM N is shared across groups (Options::valid enforces this); SwiGLU
  // halves it to produce the output dimension I.
  int32_t const N_out = options.n / 2;
  int32_t const swiglu_stride = N_out;        // row-major, contiguous over half-N

  typename GemmT::Arguments arguments {
      cutlass::gemm::GemmUniversalMode::kGrouped,
      {options.groups, problem_sizes.get(),
       host_problem_shapes_available ? options.problem_sizes_host.data() : nullptr},
      {ptr_A.get(), stride_A.get(), ptr_B.get(), stride_B.get()},
      {/*epilogue.thread (below)*/ {},
       /*ptr_C =*/ nullptr,                       // no source matrix
       /*stride_C =*/ nullptr,
       /*ptr_D =*/ ptr_aux_D.get(),               // bias-added pre-activation [M_i, 2I]
       /*stride_D =*/ stride_D.get()},
      kernel_hw_info
  };

  // EVT args, leaves-then-root:
  //   child(AccPlusBiasEVT) = { AccFetch{}, RowBroadcastVec{ptr_row, null_default, dRow}, Compute{} }
  //   root (SwiGLUStore)    = { ptr_swiglu, N_out, stride_swiglu, alpha, limit }
  arguments.epilogue.thread = {
      {  // child EVT (AccPlusBiasEVT)
          {},                                                                       // Sm90AccFetch
          {                                                                          // Sm90RowBroadcast
              reinterpret_cast<ElementBias const* const*>(ptr_bias.get()),
              ElementBias(0),
              {}                                                                     // default Stride<_0,_1,_0>
          },
          {}                                                                         // Sm90Compute<plus>
      },
      {  // root SwiGLUStore
          ptr_swiglu.get(),
          N_out,
          swiglu_stride,
          options.swiglu_alpha,
          options.swiglu_limit
      }
  };

  return arguments;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// Reference computation and verification
/////////////////////////////////////////////////////////////////////////////////////////////////

bool verify(const Options &options) {
  bool passed = true;

  for (int i = 0; i < options.groups; ++i) {
    auto const& p = options.problem_sizes_host.at(i);
    int M = get<0>(p);
    int N = get<1>(p);
    int K = get<2>(p);
    int Ihalf = N / 2;

    // 1) Pure GEMM (no bias / no activation) into block_ref_pre.
    cutlass::TensorRef ref_A(block_A.get() + offset_A.at(i), LayoutA::packed({M, K}));
    cutlass::TensorRef ref_B(block_B.get() + offset_B.at(i), LayoutB::packed({K, N}));
    cutlass::TensorRef ref_C(block_ref_pre.get() + offset_aux.at(i), LayoutOutput::packed({M, N}));
    cutlass::TensorRef ref_D(block_ref_pre.get() + offset_aux.at(i), LayoutOutput::packed({M, N}));

    DeviceGemmReference gemm_ref;
    gemm_ref(
        {M, N, K},
        ElementAccum(1.0f),
        ref_A, ref_B,
        ElementAccum(0.0f),
        ref_C, ref_D);
    CUDA_CHECK(cudaDeviceSynchronize());

    // 2) Add row bias into block_ref_pre (row-major: bias is broadcast across M).
    {
      int64_t total = int64_t(M) * N;
      int threads = 256;
      int blocks = static_cast<int>((total + threads - 1) / threads);
      add_row_bias_row_major_kernel<<<blocks, threads>>>(
          block_ref_pre.get() + offset_aux.at(i),
          block_bias.get()    + int64_t(i) * options.n,
          M, N);
      CUDA_CHECK(cudaDeviceSynchronize());
    }

    // 3) Apply SwiGLU into block_ref_swiglu.
    {
      int64_t total = int64_t(M) * Ihalf;
      int threads = 256;
      int blocks = static_cast<int>((total + threads - 1) / threads);
      swiglu_reference_kernel<<<blocks, threads>>>(
          block_ref_pre.get()    + offset_aux.at(i),
          block_ref_swiglu.get() + offset_swi.at(i),
          M, Ihalf,
          options.swiglu_alpha, options.swiglu_limit);
      CUDA_CHECK(cudaDeviceSynchronize());
    }

    // 4) Compare. bf16 + tanh.approx easily diverges past strict-eq.
    // Use a nonzero_floor near the GEMM dynamic range so that bf16
    // quantization noise around "should be zero" outputs (~0.15 absolute)
    // is absorbed without masking real algorithmic bugs in large-magnitude
    // regions.
    bool aux_ok = cutlass::reference::device::BlockCompareRelativelyEqual(
        block_aux_D.get()  + offset_aux.at(i),
        block_ref_pre.get() + offset_aux.at(i),
        int64_t(M) * N,
        ElementOutput(5e-2f),
        ElementOutput(4.0f));

    bool swi_ok = cutlass::reference::device::BlockCompareRelativelyEqual(
        block_swiglu.get()     + offset_swi.at(i),
        block_ref_swiglu.get() + offset_swi.at(i),
        int64_t(M) * Ihalf,
        ElementOutput(6e-2f),
        ElementOutput(4.0f));

    if (!aux_ok || !swi_ok) {
      std::cerr << "  Group " << i << " failed (aux=" << aux_ok
                << ", swiglu=" << swi_ok << ")\n";
    }
    passed = passed && aux_ok && swi_ok;
  }
  return passed;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// Driver
/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename GemmT>
int run(Options &options, bool host_problem_shapes_available = true) {
  allocate(options);
  initialize(options);

  std::cout << "  Problem sizes (M, 2I, K):\n";
  for (int i = 0; i < options.groups; ++i) {
    std::cout << "    " << options.problem_sizes_host.at(i) << "\n";
  }
  std::cout << "  Groups        : " << options.groups << "\n"
            << "  SwiGLU alpha  : " << options.swiglu_alpha << "\n"
            << "  SwiGLU limit  : " << options.swiglu_limit << "\n";

  GemmT gemm;
  auto arguments = args_from_options<GemmT>(options, host_problem_shapes_available);

  size_t workspace_size = GemmT::get_workspace_size(arguments);
  cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

  CUTLASS_CHECK(gemm.can_implement(arguments));
  CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));
  CUTLASS_CHECK(gemm.run());

  Result result;
  result.passed = verify(options);

  std::cout << "  Disposition   : " << (result.passed ? "Passed" : "Failed") << std::endl;
  if (!result.passed) { std::exit(-1); }

  if (options.iterations > 0) {
    GpuTimer timer;
    timer.start();
    for (int i = 0; i < options.iterations; ++i) {
      CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));
      CUTLASS_CHECK(gemm.run());
    }
    timer.stop();

    float elapsed_ms     = timer.elapsed_millis();
    result.avg_runtime_ms = double(elapsed_ms) / double(options.iterations);
    result.gflops         = options.gflops(result.avg_runtime_ms / 1000.0);

    std::cout << "  Avg runtime   : " << result.avg_runtime_ms << " ms" << std::endl;
    std::cout << "  TFLOPS (GEMM) : " << result.gflops / 1000.0 << std::endl;
  }
  return 0;
}

#endif // defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {
  if (__CUDACC_VER_MAJOR__ < 12 || (__CUDACC_VER_MAJOR__ == 12 && __CUDACC_VER_MINOR__ < 3)) {
    std::cerr << "This example requires CUDA 12.3 or newer.\n";
    return 0;
  }

  cudaDeviceProp props;
  int current_device_id;
  CUDA_CHECK(cudaGetDevice(&current_device_id));
  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device_id));
  if (props.major != 9 || props.minor != 0) {
    std::cerr << "This example requires SM90 (Hopper).\n";
    return 0;
  }

  Options options;
  options.parse(argc, args);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }
  if (!options.valid()) {
    std::cerr << "Invalid options: n must be a multiple of 16, n/2 a multiple of 8, k a multiple of 8.\n";
    return -1;
  }

#if defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)
  std::cout << "\n*** Cooperative schedule (bias + SwiGLU) ***\n";
  run<Gemm>(options);

  std::cout << "\n*** Cooperative schedule (host problem shapes unavailable) ***\n";
  run<Gemm>(options, /*host_problem_shapes_available=*/false);

  std::cout << "\n*** Pingpong schedule (bias + SwiGLU) ***\n";
  run<GemmPingpong>(options);

  std::cout << "\n*** Pingpong schedule (host problem shapes unavailable) ***\n";
  run<GemmPingpong>(options, /*host_problem_shapes_available=*/false);
#endif
  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
