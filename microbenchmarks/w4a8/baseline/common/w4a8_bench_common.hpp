#pragma once

#include <cuda_runtime.h>
#include <cstdlib>
#include <iostream>
#include <numeric>
#include <vector>

#include "cutlass/util/command_line.h"

inline void w4a8_cuda_check(cudaError_t e, int line) {
  if (e != cudaSuccess) {
    std::cerr << "CUDA error: " << cudaGetErrorString(e) << " at line " << line << std::endl;
    std::exit(EXIT_FAILURE);
  }
}
#define W4A8_CUDA_SYNC() w4a8_cuda_check(cudaDeviceSynchronize(), __LINE__)

/// Shared CLI and timing for all W4A8 grouped microbenchmarks.
struct W4A8BenchOptions {
  int groups = 128;
  int m = 1;
  int n = 1536;
  int k = 4096;
  int c = 128;
  float alpha = 1.f;
  float beta = 0.f;
  int warmup = 20;
  int iterations = 200;

  void parse(int argc, char const **argv) {
    cutlass::CommandLine cmd(argc, argv);
    cmd.get_cmd_line_argument("groups", groups);
    cmd.get_cmd_line_argument("m", m);
    cmd.get_cmd_line_argument("n", n);
    cmd.get_cmd_line_argument("k", k);
    cmd.get_cmd_line_argument("c", c);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("warmup", warmup);
    cmd.get_cmd_line_argument("iterations", iterations);
  }

  /// Total GEMM FLOPs across the grouped batch in GFLOP units (2*M*N*K per group).
  double total_gemm_gflops() const {
    uint64_t fmas = static_cast<uint64_t>(groups) * static_cast<uint64_t>(m)
                  * static_cast<uint64_t>(n) * static_cast<uint64_t>(k);
    return (2.0 * static_cast<double>(fmas)) / 1e9;
  }

  /// Total INT4 weight bytes read across the grouped batch (groups * K * N * 4 bits).
  double total_b_bytes() const {
    return 0.5 * static_cast<double>(groups) * static_cast<double>(k) * static_cast<double>(n);
  }
};

inline bool environment_supports_modifiable_tma_w4a8() {
#if defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)
  return true;
#else
  return false;
#endif
}

inline bool cuda_toolkit_at_least_12_3() {
  return !(__CUDACC_VER_MAJOR__ < 12 || (__CUDACC_VER_MAJOR__ == 12 && __CUDACC_VER_MINOR__ < 3));
}

inline bool device_is_hopper_sm90(int device = 0) {
  cudaDeviceProp props{};
  if (cudaGetDeviceProperties(&props, device) != cudaSuccess) {
    return false;
  }
  return props.major == 9 && props.minor == 0;
}

/// Result row from a single timed sweep variant.
struct SweepResult {
  std::string name;
  bool ok = false;
  std::string status;
  float avg_ms = 0.f;
  double gflops = 0.0;
  double bw_gib_s = 0.0;
  double bw_pct_peak = 0.0;
};

/// Reference HBM3e peak BW for H200, GiB/s (4.8 TB/s = 4800 GB/s ~ 4470 GiB/s).
inline constexpr double H200_HBM_PEAK_GIB_S = 4470.0;

/// Time a callable with CUDA events, computing avg_ms and derived throughput metrics.
template <class Fn>
SweepResult profile_variant(const std::string &name, W4A8BenchOptions const &opt, Fn &&fn) {
  SweepResult r;
  r.name = name;
  if (opt.iterations <= 0) {
    r.status = "skip: iterations<=0";
    return r;
  }
  cudaEvent_t start{}, stop{};
  cudaEventCreate(&start);
  cudaEventCreate(&stop);
  std::vector<float> times;
  times.reserve(opt.iterations);

  for (int it = 0; it < opt.warmup + opt.iterations; ++it) {
    cudaEventRecord(start);
    fn();
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float ms = 0.f;
    cudaEventElapsedTime(&ms, start, stop);
    if (it >= opt.warmup) {
      times.push_back(ms);
    }
  }
  cudaEventDestroy(start);
  cudaEventDestroy(stop);

  r.avg_ms = std::accumulate(times.begin(), times.end(), 0.f) /
             static_cast<float>(times.size() > 0 ? times.size() : 1);
  double t_s = static_cast<double>(r.avg_ms) / 1000.0;
  r.gflops = opt.total_gemm_gflops() / t_s;
  r.bw_gib_s = (opt.total_b_bytes() / (1024.0 * 1024.0 * 1024.0)) / t_s;
  r.bw_pct_peak = 100.0 * r.bw_gib_s / H200_HBM_PEAK_GIB_S;
  r.ok = true;
  r.status = "OK";
  return r;
}
