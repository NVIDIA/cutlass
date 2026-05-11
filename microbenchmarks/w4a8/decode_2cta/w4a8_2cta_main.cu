/***************************************************************************************************
 * Driver for the decode_2cta experiment.
 *
 * Owns CLI parsing + W4A8SharedInputs (input data is allocated and initialized
 * once). Calls the reference and test runners, runs the bf16 output equality
 * check on the captured host D buffers, and prints a 2-row comparison plus the
 * measured speedup.
 **************************************************************************************************/

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

#include "common/w4a8_bench_common.hpp"
#include "common/w4a8_kernel_common.cuh"
#include "common/sm90_int4_fp8_grouped_baseline.cuh"
#include "common/w4a8_grouped_setup.cuh"

#include "w4a8_2cta_runners.h"

#if !defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)
int main() {
  std::cerr << "This benchmark requires CUDA 12.3+ (modifiable TMA) and CUTLASS SM90 support.\n";
  return 0;
}
#else

namespace {

void print_result_row(SweepResult const &r) {
  std::cout << std::left << std::setw(54) << r.name;
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

struct EqResultHost {
  double max_abs_diff = 0.0;
  double max_rel_diff = 0.0;
  size_t total_elements = 0;
  size_t mismatched = 0;
  bool   passed = true;
  double atol = 0.0;
  double rtol = 0.0;
};

EqResultHost compare_host_bf16(std::vector<cutlass::bfloat16_t> const &ref,
                               std::vector<cutlass::bfloat16_t> const &test,
                               double atol, double rtol) {
  EqResultHost r;
  r.atol = atol;
  r.rtol = rtol;
  if (ref.size() != test.size()) {
    std::cerr << "Equality check: size mismatch ref=" << ref.size()
              << " test=" << test.size() << "\n";
    r.passed = false;
    return r;
  }
  r.total_elements = ref.size();
  for (size_t i = 0; i < ref.size(); ++i) {
    double a = static_cast<double>(static_cast<float>(ref[i]));
    double b = static_cast<double>(static_cast<float>(test[i]));
    double abs_diff = std::abs(a - b);
    double denom = std::max(std::abs(a), 1e-12);
    double rel_diff = abs_diff / denom;
    if (abs_diff > r.max_abs_diff) r.max_abs_diff = abs_diff;
    if (rel_diff > r.max_rel_diff) r.max_rel_diff = rel_diff;
    if (abs_diff > atol && rel_diff > rtol) {
      r.mismatched += 1;
    }
  }
  r.passed = (r.mismatched == 0);
  return r;
}

}  // namespace

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

  std::cout << "W4A8 grouped GEMM (decode 2 CTAs/SM)\n";
  std::cout << "  groups       : " << opt.groups << "\n";
  std::cout << "  per-group MNK: " << opt.m << " x " << opt.n << " x " << opt.k << "\n";
  std::cout << "  scale chunk c: " << opt.c << "\n";
  std::cout << "  warmup/iters : " << opt.warmup << " / " << opt.iterations << "\n";
  std::cout << "  total math   : " << opt.total_gemm_gflops() << " GFLOPs/iter\n";
  std::cout << "  weight bytes : " << (opt.total_b_bytes() / (1024.0 * 1024.0)) << " MiB/iter\n";
  std::cout << "  HBM3e peak   : " << H200_HBM_PEAK_GIB_S << " GiB/s\n";
  std::cout << "\n";

  W4A8SharedInputs shared;
  std::vector<typename ProblemShape::UnderlyingProblemShape> problem_host;
  shared.allocate_and_init(opt, problem_host);

  // Reference first; test second. Both runners do their own warmup + timing
  // window inside the same binary, on the same GPU, with the same warmup/iters.
  W4A8RunResult ref = run_ref(shared, opt);
  W4A8RunResult test = run_test(shared, opt);

  std::cout << "=== Results ===\n";
  std::cout << std::left << std::setw(54) << "config"
            << std::right << std::setw(11) << "time(ms)"
            << std::setw(12) << "GFLOP/s"
            << std::setw(13) << "GiB/s(B)"
            << std::setw(9)  << "%HBM"
            << "  status\n";
  print_result_row(ref.result);
  print_result_row(test.result);

  std::cout << "\n";
  if (ref.result.ok && test.result.ok) {
    EqResultHost eq = compare_host_bf16(ref.host_D, test.host_D,
                                        /*atol=*/1e-2, /*rtol=*/5e-3);
    std::cout << "Equality check (atol=" << std::scientific << std::setprecision(1) << eq.atol
              << ", rtol=" << eq.rtol << "): "
              << (eq.passed ? "PASS" : "FAIL")
              << "  max_abs_diff=" << std::scientific << std::setprecision(3) << eq.max_abs_diff
              << "  max_rel_diff=" << eq.max_rel_diff
              << "  mismatched=" << eq.mismatched << "/" << eq.total_elements
              << std::defaultfloat << "\n";

    double speedup = static_cast<double>(ref.result.avg_ms) /
                     static_cast<double>(test.result.avg_ms);
    std::cout << "Speedup vs measured baseline: "
              << std::fixed << std::setprecision(2) << speedup << "x\n";
    return eq.passed ? 0 : 3;
  } else {
    std::cerr << "One or both runs failed; skipping equality check.\n";
    return 2;
  }
}

#endif // CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED
