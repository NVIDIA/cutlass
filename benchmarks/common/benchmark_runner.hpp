/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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

#pragma once

#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/gemm/device/gemm_universal.h"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/collective/collective_mma.hpp"
#include "cutlass/util/GPU_Clock.hpp"

#include "cutlass/util/host_tensor.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cute/tensor.hpp"

#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#if defined(CUTLASS_ENABLE_SYCL)
#include "cutlass/util/reference/device/sycl_tensor_fill.h"
#else
#include "cutlass/util/reference/device/tensor_fill.h"
#endif

#include <benchmark/benchmark.h>

using namespace cute;

namespace cutlass::benchmark {

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to initialize a block of device data
template <class Element>
bool initialize_block(
        cutlass::DeviceAllocation<Element>& block,
        uint64_t seed=2023) {

  Element scope_max, scope_min;
  int bits_input = cutlass::sizeof_bits<Element>::value;

  if (bits_input == 1) {
    scope_max = Element(2);
    scope_min = Element(0);
  } else if (bits_input <= 8) {
    scope_max = Element(2);
    scope_min = Element(-2);
  } else {
    scope_max = Element(8);
    scope_min = Element(-8);
  }

  reference::device::BlockFillRandomUniform(
       block.get(), block.size(), seed, scope_max, scope_min, 0);
  return true;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

  bool error;

  int m, n, k, l;
  float alpha, beta;
  std::string bm_name;

  Options():
          error(false),
          m(5120), n(4096), k(4096), l(1),
          alpha(1.f), beta(0.f),
          bm_name("unknown")
  { }

  // Parses the command line
  void parse(int argc, char const **args) {
    CommandLine cmd(argc, args);

    cmd.get_cmd_line_argument("m", m, 5120);
    cmd.get_cmd_line_argument("n", n, 4096);
    cmd.get_cmd_line_argument("k", k, 4096);
    cmd.get_cmd_line_argument("l", l, 1);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("bm_name", bm_name, std::string("unknown"));
  }

  std::string benchmark_name() const {
    std::stringstream full_name;
    full_name << bm_name << "/";
    std::string const test_name_suffix = std::to_string(m) + "x" +
                                   std::to_string(n) + "x" +
                                   std::to_string(k) + "x" +
                                   std::to_string(l);
    full_name << test_name_suffix;

    return full_name.str();
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template <class GemmConfiguration>
struct BenchmarkRunnerGemm {

  using Gemm = typename GemmConfiguration::Gemm;

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

  using CollectiveEpilogue = typename Gemm::CollectiveEpilogue;
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

  uint64_t seed;

  DeviceAllocation<ElementA> block_A;
  DeviceAllocation<ElementB> block_B;
  DeviceAllocation<ElementC> block_C;
  DeviceAllocation<ElementOutput> block_D;
  DeviceAllocation<ElementOutput> block_ref_D;

  BenchmarkRunnerGemm() : seed(0) {};

  //
  // Methods
  //

  bool verify(const ProblemShapeType& problem_size, ElementCompute alpha, ElementCompute beta) {
    auto [M, N, K, L] = problem_size;

    TensorRef ref_A(block_A.get(), LayoutA::packed({M, K}));
    TensorRef ref_B(block_B.get(), LayoutB::packed({K, N}));
    TensorRef ref_C(block_C.get(), LayoutC::packed({M, N}));
    TensorRef ref_D(block_ref_D.get(), LayoutD::packed({M, N}));

    reference::device::GemmComplex(
            {M, N, K},
            alpha,
            ref_A,
            ComplexTransform::kNone,
            ref_B,
            ComplexTransform::kNone,
            beta,
            ref_C,
            ref_D,
            ElementAccumulator(0),
            L,     // batch_count
            M * K, // batch_stride_A
            K * N, // batch_stride_B
            M * N, // batch_stride_C
            M * N  // batch_stride_D
    );

#if defined(CUTLASS_ENABLE_SYCL)
    syclcompat::wait();
#else
    cudaDeviceSynchronize();
#endif

    // Check if output from CUTLASS kernel and reference kernel are equal or not
    bool passed = reference::device::BlockCompareEqual(
      block_ref_D.get(), block_D.get(), block_D.size());

    return passed;
  }

  /// Initialize operands to be used in the GEMM and reference GEMM
  void initialize(const ProblemShapeType& problem_size) {
    auto problem_shape_MNKL = cute::append<4>(problem_size, 1);
    auto [M, N, K, L] = problem_shape_MNKL;

    stride_A = cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(M, K, L));
    stride_B = cutlass::make_cute_packed_stride(StrideB{}, cute::make_shape(N, K, L));
    stride_C = cutlass::make_cute_packed_stride(StrideC{}, cute::make_shape(M, N, L));
    stride_D = cutlass::make_cute_packed_stride(StrideD{}, cute::make_shape(M, N, L));

    block_A.reset(M * K * L);
    block_B.reset(K * N * L);
    block_C.reset(M * N * L);
    block_D.reset(M * N * L);
    block_ref_D.reset(M * N * L);

    initialize_block(block_A, seed + 2023);
    initialize_block(block_B, seed + 2022);
    initialize_block(block_C, seed + 2021);
  }

  void run(::benchmark::State& state, const Options& options, const KernelHardwareInfo& hw_info) {
    ProblemShapeType problem_size = ProblemShapeType{options.m, options.n, options.k, options.l};

    initialize(problem_size);

    typename Gemm::GemmKernel::Arguments arguments{
       gemm::GemmUniversalMode::kGemm,
      problem_size,
      {block_A.get(), stride_A, block_B.get(), stride_B},
      {{options.alpha, options.beta}, block_C.get(), stride_C, block_D.get(), stride_D},
      hw_info
    };

    Gemm gemm_op;

    size_t workspace_size = Gemm::get_workspace_size(arguments);
    device_memory::allocation<uint8_t> workspace(workspace_size);

    gemm_op.can_implement(arguments);

    gemm_op.initialize(arguments, workspace.get());

    // Run the GEMM
    gemm_op.run();

#if defined(CUTLASS_ENABLE_SYCL)
    syclcompat::wait();
#else
    cudaDeviceSynchronize();
#endif

    // Verify that the result is correct
    bool passed = verify(problem_size, options.alpha, options.beta);
    if(not passed) {
      throw std::runtime_error("Disposition Failed.");
    }

    auto tflop = ((2.0 * options.m * options.n * options.k * options.l) * 1e-12);
    auto giga_bytes_transferred = (((options.m * options.k) * sizeof(ElementA) +
                                     (options.k * options.n) * sizeof(ElementB) +
                                 (options.beta != 0 ? 2 : 1) * (options.m * options.n) * sizeof(ElementC)) * 1e-9) *
                                 options.l;
    initialize_counters(state);
    for(auto _ : state) {
      GPU_Clock timer;
      timer.start();
      gemm_op.run();
      auto ms_elapsed = timer.milliseconds();
      update_counters(state, ms_elapsed, tflop, giga_bytes_transferred);
      state.SetIterationTime(ms_elapsed / 1000);
    }
    finalize_counters(state, tflop, giga_bytes_transferred);
  }

private:
  static void initialize_counters(::benchmark::State& state) {
    state.counters["avg_runtime_ms"] = 0;
    state.counters["avg_tflops"] = 0;
    state.counters["avg_throughput"] = 0;
    state.counters["best_runtime_ms"] = std::numeric_limits<double>::max();
  }

  static void update_counters(::benchmark::State& state, double ms_elapsed, double tflop, double giga_bytes_transferred) {
    state.PauseTiming();
    state.counters["avg_runtime_ms"] += ms_elapsed;
    state.counters["avg_tflops"] += tflop / (ms_elapsed * 1000);
    state.counters["avg_throughput"] += giga_bytes_transferred / (ms_elapsed / 1000);
    state.counters["best_runtime_ms"] = std::min<double>(state.counters["best_runtime_ms"], ms_elapsed);
    state.ResumeTiming();
  }

  static void finalize_counters(::benchmark::State& state,  double tflop, double giga_bytes_transferred) {
    state.counters["avg_runtime_ms"] /= state.iterations();
    state.counters["avg_tflops"] /= state.iterations();
    state.counters["avg_throughput"] /= state.iterations();
    state.counters["best_tflop"] = tflop / (state.counters["best_runtime_ms"] / 1000);
    state.counters["best_bandwidth"] = giga_bytes_transferred / (state.counters["best_runtime_ms"] / 1000);
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

class BenchmarkRegistry {
  using BM_Lambda = std::function<void(::benchmark::State& state, Options const&, KernelHardwareInfo const &)>;;
  std::map<const std::string, BM_Lambda> benchmarks;

  static BenchmarkRegistry& get_instance() {
    static BenchmarkRegistry runner;
    return runner;
  }

  BenchmarkRegistry() = default;
public:
  BenchmarkRegistry(BenchmarkRegistry const&) = delete;
  void operator=(BenchmarkRegistry const&) = delete;

  static auto const& get_benchmark(std::string const& name) {
    auto& benchs = get_instance().benchmarks;
    auto it = benchs.find(name);
    if (it == benchs.end()) {
      throw std::runtime_error("Benchmark not found");
    }
    return it->second;
  }

  static void Register(std::string const& key, BM_Lambda const func) {
    auto& benchs = get_instance().benchmarks;
    if (benchs.find(key) == benchs.end()) {
      benchs.insert(std::make_pair(key, func));
    } else {
      std::cerr << "Benchmark " << key << " duplicated." << std::endl;
    }
  }
};

}

#define CUTLASS_BENCHMARK(F) cutlass::benchmark::BenchmarkRegistry::Register(#F, &F##_func)

#define CUTLASS_CREATE_GEMM_BENCHMARK(F)                          \
  static void F##_func(                                           \
      ::benchmark::State& state,                                  \
      cutlass::benchmark::Options const& options,                 \
      cutlass::KernelHardwareInfo const& hw_info) {               \
    auto bench = cutlass::benchmark::BenchmarkRunnerGemm<F>();    \
    bench.run(state, options, hw_info);                           \
  }
