/***************************************************************************************************
 * W4A8 grouped GEMM tile/schedule sweep for the decode regime (small M, many experts).
 *
 * For every (TileShape, ClusterShape, KernelSchedule) candidate we instantiate the same
 * Int4Fp8GemmGivenSchedule<...> from sm90_int4_fp8_grouped.cuh, run it through
 * profile_variant(), and print a single ranked table.
 **************************************************************************************************/

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <iostream>
#include <iomanip>
#include <string>
#include <utility>
#include <vector>

#include "common/w4a8_bench_common.hpp"

#include "cutlass/cutlass.h"
#include "cute/tensor.hpp"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/group_array_problem_shape.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"

#include "cutlass/util/device_memory.h"

#include "helper.h"

#include "w4a8_grouped_setup.cuh"

#if !defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)
int main() {
  std::cerr << "This benchmark requires CUDA 12.3+ (modifiable TMA) and CUTLASS SM90 support.\n";
  return 0;
}
#else

template <class Config, class Schedule>
static SweepResult run_one(const std::string &name, W4A8BenchOptions const &opt) {
  using Gemm = typename Int4Fp8GemmGivenSchedule<Config, Schedule>::GemmScaleOnly;
  SweepResult r;
  r.name = name;

  BaselineGroupedContext<Gemm> ctx;
  std::vector<typename ProblemShape::UnderlyingProblemShape> problem_host;
  ctx.allocate_and_init(opt, problem_host);

  Gemm gemm;
  auto arguments = ctx.make_arguments(opt);
  size_t workspace_size = Gemm::get_workspace_size(arguments);
  cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

  auto status_ci = gemm.can_implement(arguments);
  if (status_ci != cutlass::Status::kSuccess) {
    r.ok = false;
    r.status = std::string("SKIP can_implement: ") + cutlass::cutlassGetStatusString(status_ci);
    return r;
  }
  auto status_init = gemm.initialize(arguments, workspace.get());
  if (status_init != cutlass::Status::kSuccess) {
    r.ok = false;
    r.status = std::string("SKIP initialize: ") + cutlass::cutlassGetStatusString(status_init);
    return r;
  }

  // Warm-up launch outside the timer to surface any runtime error.
  auto status_run = gemm.run();
  if (status_run != cutlass::Status::kSuccess) {
    r.ok = false;
    r.status = std::string("SKIP run: ") + cutlass::cutlassGetStatusString(status_run);
    return r;
  }
  W4A8_CUDA_SYNC();

  r = profile_variant(name, opt, [&]() { CUTLASS_CHECK(gemm.run()); });
  return r;
}

// ============================================================================
// Candidate tile/cluster/schedule configurations.
// ============================================================================

namespace sched {
  using Coop = cutlass::gemm::KernelPtrArrayTmaWarpSpecializedCooperative;
  using Ping = cutlass::gemm::KernelPtrArrayTmaWarpSpecializedPingpong;
}

namespace cfg {
  template <int TM, int TN>
  using Tile = cute::Shape<cute::Int<TM>, cute::Int<TN>, cute::Int<TileShapeK>>;

  using C0_Tile = Tile<128, 128>;
  using C1_Tile = Tile<128, 16>;
  using C2_Tile = Tile<128, 16>;
  using C3_Tile = Tile<128, 32>;
  using C4_Tile = Tile< 64, 16>;
  using C5_Tile = Tile< 64, 32>;
  using C6_Tile = Tile< 64, 64>;
  using C7_Tile = Tile<128, 16>;

  using Cluster_1_1_1 = cute::Shape<cute::_1, cute::_1, cute::_1>;
  using Cluster_2_1_1 = cute::Shape<cute::_2, cute::_1, cute::_1>;
  using Cluster_1_2_1 = cute::Shape<cute::_1, cute::_2, cute::_1>;

  using C0 = GemmConfig<C0_Tile, Cluster_1_1_1>;
  using C1 = GemmConfig<C1_Tile, Cluster_1_1_1>;
  using C2 = GemmConfig<C2_Tile, Cluster_2_1_1>;
  using C3 = GemmConfig<C3_Tile, Cluster_1_1_1>;
  using C4 = GemmConfig<C4_Tile, Cluster_1_1_1>;
  using C5 = GemmConfig<C5_Tile, Cluster_1_1_1>;
  using C6 = GemmConfig<C6_Tile, Cluster_1_1_1>;
  using C7 = GemmConfig<C7_Tile, Cluster_1_2_1>;
}

struct Variant {
  const char *id;
  const char *name;
  SweepResult (*run)(W4A8BenchOptions const &);
};

template <class Config, class Schedule>
static SweepResult run_named(W4A8BenchOptions const &opt, const char *name) {
  return run_one<Config, Schedule>(std::string(name), opt);
}

#define VARIANT(ID, NAME, CFG, SCH)                                                                \
  Variant {                                                                                        \
    ID, NAME, [](W4A8BenchOptions const &o) { return run_named<CFG, SCH>(o, NAME); }               \
  }

static const Variant kVariants[] = {
    VARIANT("C0", "C0 coop 128x128x128 cluster1x1x1", cfg::C0, sched::Coop),
    VARIANT("C1", "C1 coop 128x 16x128 cluster1x1x1", cfg::C1, sched::Coop),
    VARIANT("C2", "C2 coop 128x 16x128 cluster2x1x1", cfg::C2, sched::Coop),
    VARIANT("C3", "C3 coop 128x 32x128 cluster1x1x1", cfg::C3, sched::Coop),
    VARIANT("C4", "C4 ping  64x 16x128 cluster1x1x1", cfg::C4, sched::Ping),
    VARIANT("C5", "C5 ping  64x 32x128 cluster1x1x1", cfg::C5, sched::Ping),
    VARIANT("C6", "C6 ping  64x 64x128 cluster1x1x1", cfg::C6, sched::Ping),
    VARIANT("C7", "C7 coop 128x 16x128 cluster1x2x1", cfg::C7, sched::Coop),
};

int main(int argc, char const **argv) {
  if (!cuda_toolkit_at_least_12_3()) {
    std::cerr << "CUDA 12.3+ required.\n";
    return 0;
  }
  if (!device_is_hopper_sm90()) {
    std::cerr << "Hopper (SM90) GPU required.\n";
    return 1;
  }

  W4A8BenchOptions opt;
  opt.parse(argc, argv);

  std::cout << "W4A8 grouped GEMM sweep\n";
  std::cout << "  groups       : " << opt.groups << "\n";
  std::cout << "  per-group MNK: " << opt.m << " x " << opt.n << " x " << opt.k << "\n";
  std::cout << "  scale chunk c: " << opt.c << "\n";
  std::cout << "  warmup/iters : " << opt.warmup << " / " << opt.iterations << "\n";
  std::cout << "  total math   : " << opt.total_gemm_gflops() << " GFLOPs/iter\n";
  std::cout << "  weight bytes : " << (opt.total_b_bytes() / (1024.0 * 1024.0)) << " MiB/iter\n";
  std::cout << "  HBM3e peak   : " << H200_HBM_PEAK_GIB_S << " GiB/s\n";
  if (!opt.only.empty()) {
    std::cout << "  filter --only: " << opt.only << "\n";
  }
  std::cout << "\n";

  std::vector<SweepResult> results;
  for (auto const &v : kVariants) {
    if (!opt.only.empty() && opt.only != v.id) continue;
    results.push_back(v.run(opt));
  }

  if (results.empty()) {
    std::cerr << "No variants matched --only='" << opt.only << "'.\n";
    return 2;
  }

  // Print as-run order.
  std::cout << "\n=== Sweep results (as-run order) ===\n";
  std::cout << std::left << std::setw(38) << "config"
            << std::right << std::setw(11) << "time(ms)"
            << std::setw(12) << "GFLOP/s"
            << std::setw(13) << "GiB/s(B)"
            << std::setw(9)  << "%HBM"
            << "  status\n";
  for (auto const &r : results) {
    std::cout << std::left << std::setw(38) << r.name;
    if (r.ok) {
      std::cout << std::right << std::fixed << std::setprecision(3) << std::setw(11) << r.avg_ms
                << std::setprecision(1) << std::setw(12) << r.gflops
                << std::setprecision(1) << std::setw(13) << r.bw_gib_s
                << std::setprecision(1) << std::setw(9) << r.bw_pct_peak;
    } else {
      std::cout << std::right << std::setw(11) << "-"
                << std::setw(12) << "-"
                << std::setw(13) << "-"
                << std::setw(9)  << "-";
    }
    std::cout << "  " << r.status << "\n";
  }

  // Sort OK rows fastest first; failed rows pushed to the end.
  std::vector<SweepResult> sorted = results;
  std::sort(sorted.begin(), sorted.end(), [](SweepResult const &a, SweepResult const &b) {
    if (a.ok != b.ok) return a.ok && !b.ok;
    if (!a.ok) return false;
    return a.avg_ms < b.avg_ms;
  });

  std::cout << "\n=== Ranked (best -> worst by avg ms) ===\n";
  std::cout << std::left << std::setw(38) << "config"
            << std::right << std::setw(11) << "time(ms)"
            << std::setw(12) << "GFLOP/s"
            << std::setw(13) << "GiB/s(B)"
            << std::setw(9)  << "%HBM"
            << "  status\n";
  for (auto const &r : sorted) {
    std::cout << std::left << std::setw(38) << r.name;
    if (r.ok) {
      std::cout << std::right << std::fixed << std::setprecision(3) << std::setw(11) << r.avg_ms
                << std::setprecision(1) << std::setw(12) << r.gflops
                << std::setprecision(1) << std::setw(13) << r.bw_gib_s
                << std::setprecision(1) << std::setw(9) << r.bw_pct_peak;
    } else {
      std::cout << std::right << std::setw(11) << "-"
                << std::setw(12) << "-"
                << std::setw(13) << "-"
                << std::setw(9)  << "-";
    }
    std::cout << "  " << r.status << "\n";
  }

  // Highlight winner and speedup vs baseline (C0).
  SweepResult const *baseline = nullptr;
  SweepResult const *winner = nullptr;
  for (auto const &r : results) {
    if (r.name.rfind("C0 ", 0) == 0 && r.ok) baseline = &r;
  }
  for (auto const &r : sorted) {
    if (r.ok) { winner = &r; break; }
  }
  if (winner && baseline && winner != baseline) {
    double speedup = baseline->avg_ms / winner->avg_ms;
    std::cout << "\nBest config: " << winner->name
              << "  (" << std::setprecision(2) << speedup << "x speedup vs C0 baseline)\n";
  } else if (winner) {
    std::cout << "\nBest config: " << winner->name << "\n";
  }
  return 0;
}

#endif
