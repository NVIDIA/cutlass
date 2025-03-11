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

namespace cutlass {
    std::size_t get_llc_size() {
      #if defined(CUTLASS_ENABLE_SYCL)
        return syclcompat::get_default_queue().get_device().get_info<sycl::info::device::global_mem_cache_size>();   
      #else
        cudaDeviceProp prop_struct;
        auto result = cudaGetDeviceProperties(&prop_struct, 0);
        if (result != cudaSuccess) {
          throw std::runtime_error(cudaGetErrorString(result));
        }
        return static_cast<std::size_t>(prop_struct.l2CacheSize);
      #endif
    }
}

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
struct GEMMOptions {

  bool error;

  int m, n, k, l;
  float alpha, beta;
  std::string bm_name;

  GEMMOptions():
          error(false),
          m(5120), n(4096), k(4096), l(1),
          alpha(1.f), beta(0.f),
          bm_name("GEMM")
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
    cmd.get_cmd_line_argument("bm_name", bm_name, std::string("GEMM"));
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

  int32_t count;

  //
  // Data members
  //

  /// Initialization
  StrideA stride_A;
  StrideB stride_B;
  StrideC stride_C;
  StrideD stride_D;

  uint64_t seed;

  std::vector<DeviceAllocation<ElementA>> block_A;
  std::vector<DeviceAllocation<ElementB>> block_B;
  std::vector<DeviceAllocation<ElementC>> block_C;
  DeviceAllocation<ElementOutput> block_D;
  DeviceAllocation<ElementOutput> block_ref_D;

  BenchmarkRunnerGemm() : seed(0) {};

  //
  // Methods
  //

  bool verify(const ProblemShapeType& problem_size, ElementCompute alpha, ElementCompute beta) {
    auto [M, N, K, L] = problem_size;

    TensorRef ref_A(block_A[0].get(), LayoutA::packed({M, K}));
    TensorRef ref_B(block_B[0].get(), LayoutB::packed({K, N}));
    TensorRef ref_C(block_C[0].get(), LayoutC::packed({M, N}));
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

    std::size_t mem_occupied_ABC = (M * K * L * sizeof(ElementA)) + (K * N * L * sizeof(ElementB)) + 
                                   (M * N * L * sizeof(ElementC));
    count = std::ceil(static_cast<float>(cutlass::get_llc_size()) / static_cast<float>(mem_occupied_ABC)) + 1;

    for(int i=0; i < count; i++) {
      block_A.emplace_back();
      block_B.emplace_back();
      block_C.emplace_back();
    }

    for (int i=0; i < count; i++) {
      block_A[i].reset(M * K * L);
      block_B[i].reset(K * N * L);
      block_C[i].reset(M * N * L);
      initialize_block(block_A[i], seed + i);
      initialize_block(block_B[i], seed + i);
      initialize_block(block_C[i], seed + i);
    }

    block_D.reset(M * N * L);
    block_ref_D.reset(M * N * L);

  }

  void run(::benchmark::State& state, const GEMMOptions& options, const KernelHardwareInfo& hw_info) {
    ProblemShapeType problem_size = ProblemShapeType{options.m, options.n, options.k, options.l};

    initialize(problem_size);

    typename Gemm::GemmKernel::Arguments arguments = GemmConfiguration::defaultArguments();
    arguments.mode = gemm::GemmUniversalMode::kGemm;
    arguments.problem_shape = problem_size;
    arguments.mainloop = {block_A[0].get(), stride_A, block_B[0].get(), stride_B};
    arguments.epilogue = {{options.alpha, options.beta}, block_C[0].get(), stride_C, block_D.get(), stride_D};
    arguments.hw_info = hw_info;

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
      state.SkipWithError("Disposition Failed.");
    }

    state.counters["m"] = options.m;
    state.counters["n"] = options.n;
    state.counters["k"] = options.k;
    state.counters["l"] = options.l;
    state.counters["alpha"] = options.alpha;
    state.counters["beta"] = options.beta;

    std::stringstream extra_label;
    if constexpr (cute::size<0>(StrideA{}) == 1) {
      extra_label << "layoutA=ColumnMajor ";
    } else if constexpr (cute::size<1>(StrideA{}) == 1) {
      extra_label << "layoutA=RowMajor ";
    }
    if constexpr (cute::size<0>(StrideB{}) == 1) {
      extra_label << "layoutB=RowMajor ";
    } else if constexpr (cute::size<1>(StrideB{}) == 1) {
      extra_label << "layoutB=ColumnMajor ";
    }
    if constexpr (cute::size<0>(StrideC{}) == 1) {
      extra_label << "layoutC=ColumnMajor ";
    } else if constexpr (cute::size<1>(StrideC{}) == 1) {
      extra_label << "layoutC=RowMajor ";
    }
    state.SetLabel(extra_label.str());

    auto gflop = 2.0 * options.m * options.n * options.k * options.l * 1e-9;
    auto mega_bytes_transferred = static_cast<double>(
        options.m * options.k * sizeof(ElementA) +
        options.k * options.n * sizeof(ElementB) +
        (options.beta != 0 ? 2 : 1) * options.m * options.n * sizeof(ElementC)
      ) * 1e-6 * options.l;

    initialize_counters(state);
    int32_t counter = 1;
    for(auto _ : state) {
      state.PauseTiming();
      int input_num = std::max(int(0), counter % count);
      typename Gemm::GemmKernel::Arguments arguments{
        gemm::GemmUniversalMode::kGemm,
        problem_size,
        {block_A[input_num].get(), stride_A, block_B[input_num].get(), stride_B},
        {{options.alpha, options.beta}, block_C[input_num].get(), stride_C, block_D.get(), stride_D},
        hw_info
      };
      gemm_op.initialize(arguments, workspace.get());
      state.ResumeTiming();

      GPU_Clock timer;
      timer.start();
      gemm_op.run();
      auto ms_elapsed = timer.milliseconds();
      update_counters(state, ms_elapsed);
      state.SetIterationTime(ms_elapsed / 1000);
      counter++;
    }
    finalize_counters(state, gflop, mega_bytes_transferred);
  }

private:
  static void initialize_counters(::benchmark::State& state) {
    state.counters["avg_runtime_ms"] = 0;
    state.counters["best_runtime_ms"] = std::numeric_limits<double>::max();
  }

  static void update_counters(::benchmark::State& state, double ms_elapsed) {
    state.PauseTiming();
    state.counters["total_runtime_ms"] += ms_elapsed;
    state.counters["best_runtime_ms"] = std::min<double>(state.counters["best_runtime_ms"], ms_elapsed);
    state.ResumeTiming();
  }

  static void finalize_counters(::benchmark::State& state,  double gflop, double mega_bytes_transferred) {
    state.counters["avg_runtime_ms"] =
      state.counters["total_runtime_ms"] / static_cast<double>(state.iterations());
    state.counters["avg_tflops"] = gflop / state.counters["avg_runtime_ms"];
    state.counters["avg_throughput"] = mega_bytes_transferred / state.counters["avg_runtime_ms"];
    state.counters["best_tflop"] = gflop / state.counters["best_runtime_ms"];
    state.counters["best_bandwidth"] = mega_bytes_transferred / state.counters["best_runtime_ms"];
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template<typename Options>
class BenchmarkRegistry {
  using BM_Lambda = std::function<void(::benchmark::State& state, Options const&, KernelHardwareInfo const &)>;
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

#define CUTLASS_BENCHMARK(F) cutlass::benchmark::BenchmarkRegistry<cutlass::benchmark::GEMMOptions>::Register(#F, &F##_func)

#define CUTLASS_CREATE_GEMM_BENCHMARK(F)                          \
  static void F##_func(                                           \
      ::benchmark::State& state,                                  \
      cutlass::benchmark::GEMMOptions const& options,                 \
      cutlass::KernelHardwareInfo const& hw_info) {               \
    auto bench = cutlass::benchmark::BenchmarkRunnerGemm<F>();    \
    bench.run(state, options, hw_info);                           \
  }
