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
#include "cutlass/epilogue/fusion/xe_callbacks.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "flash_attention_v2/kernel/xe_flash_attn_gemm.hpp"
#include "flash_attention_v2/collective/xe_flash_attn_epilogue.hpp"
#include "flash_attention_v2/collective/xe_flash_attn_softmax_epilogue.hpp"
#include "cutlass/util/GPU_Clock.hpp"
#include "cutlass/util/sycl_event_manager.hpp"

#include <cute/tensor.hpp>
#include <random>

#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "../examples/sycl/pvc/common.hpp"

#include "../benchmarks/benchmark_runner.hpp"

using namespace cute;

namespace cutlass::benchmark {

// Command line options parsing
struct FMHAOptions {

  bool error;

  int batch, num_heads, seq_len, head_size, iterations;
  float softmax_scale;
  std::string bm_name;

  FMHAOptions()
      : error(false), batch(32), num_heads(16), seq_len(512), head_size(128),
        iterations(100), softmax_scale(1.f), bm_name("Flash Attention v2") {}

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    cmd.get_cmd_line_argument("batch", batch, 32);
    cmd.get_cmd_line_argument("num_heads", num_heads, 16);
    cmd.get_cmd_line_argument("seq_len", seq_len, 512);
    cmd.get_cmd_line_argument("head_size", head_size, 128);
    cmd.get_cmd_line_argument("iterations", iterations, 100);
    cmd.get_cmd_line_argument("bm_name", bm_name, std::string("Flash Attention v2"));

    softmax_scale = 1 / std::sqrt(static_cast<float>(head_size));
  }

  std::string benchmark_name() const {
    std::stringstream full_name;
    full_name << bm_name << "/";
    std::string const test_name_suffix = std::to_string(batch) + "x" +
                                   std::to_string(num_heads) + "x" +
                                   std::to_string(seq_len) + "x" +
                                   std::to_string(head_size);
    full_name << test_name_suffix;

    return full_name.str();
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template <class FMHAConfiguration> struct BenchmarkRunnerFMHA {

  using GemmKernel = typename FMHAConfiguration::GemmKernel;
  
  using LayoutQ = typename FMHAConfiguration::LayoutQ;
  using LayoutK = typename FMHAConfiguration::LayoutK;
  using LayoutV = typename FMHAConfiguration::LayoutV;
  using LayoutO = typename FMHAConfiguration::LayoutO;

  using StrideQ = typename GemmKernel::StrideQ;
  using StrideK = typename GemmKernel::StrideK;
  using StrideV = typename GemmKernel::StrideV;
  using StrideO = typename GemmKernel::StrideO;

  using ElementQ = typename GemmKernel::ElementQ;
  using ElementK = typename GemmKernel::ElementK;
  using ElementV = typename GemmKernel::ElementV;
  using ElementAcc = typename GemmKernel::ElementAccumulator;

  using CollectiveEpilogue = typename GemmKernel::CollectiveEpilogue;
  using ElementOutput = typename CollectiveEpilogue::ElementOutput;
  using ElementCompute = typename CollectiveEpilogue::ElementCompute;
  using ElementAccumulator = typename CollectiveEpilogue::ElementAccumulator;

  using ProblemShapeType = typename GemmKernel::ProblemShape;
  static constexpr bool Causal = FMHAConfiguration::Causal;

  int32_t count;

  //
  // Data members
  //

  /// Initialization
  StrideQ stride_Q;
  StrideK stride_K;
  StrideV stride_V;
  StrideO stride_O;
  uint64_t seed = 0;

  std::vector<cutlass::DeviceAllocation<ElementQ>> block_Q;
  std::vector<cutlass::DeviceAllocation<ElementK>> block_K;
  std::vector<cutlass::DeviceAllocation<ElementV>> block_V;
  cutlass::DeviceAllocation<ElementOutput> block_O;
  cutlass::DeviceAllocation<ElementOutput> block_ref_O;

  //
  // Methods
  //

  bool verify(const ProblemShapeType &problem_size) {
    auto [batch, num_heads, seq_len, head_size] = problem_size;

    int batch_size = batch * num_heads;

    // loop over the batch dimension to compute the output
    // to avoid the risk of running out of device memory
    for (int b = 0, offset = 0; b < batch_size; b++, offset += seq_len * head_size) {

      cutlass::DeviceAllocation<ElementOutput> block_S;
      block_S.reset(seq_len * seq_len);

      cutlass::TensorRef ref_Q(block_Q[0].get() + offset, LayoutQ::packed({seq_len, head_size}));
      cutlass::TensorRef ref_K(block_K[0].get() + offset, LayoutK::packed({head_size, seq_len}));
      cutlass::TensorRef ref_V(block_V[0].get() + offset, LayoutV::packed({seq_len, head_size}));
      cutlass::TensorRef ref_S(block_S.get(), LayoutQ::packed({seq_len, seq_len}));
      cutlass::TensorRef ref_O(block_ref_O.get() + offset, LayoutO::packed({seq_len, head_size}));

      cutlass::reference::device::GemmComplex({seq_len, seq_len, head_size}, 1.f, ref_Q,
                                              cutlass::ComplexTransform::kNone, ref_K, cutlass::ComplexTransform::kNone,
                                              0.f, ref_S, ref_S, ElementAccumulator(0),
                                              1,                   // batch_count
                                              seq_len * head_size, // batch_stride_Q
                                              seq_len * head_size, // batch_stride_K
                                              seq_len * seq_len,   // batch_stride_S
                                              seq_len * seq_len    // batch_stride_S
      );

      syclcompat::wait();

      std::vector<ElementOutput> host_S(seq_len * seq_len);
      syclcompat::memcpy<ElementOutput>(host_S.data(), block_S.get(), host_S.size());
      syclcompat::wait();

      // delete this memory as it is no longer needed
      block_S.reset();

      if (Causal) {
        // apply mask to S
        for (int row = 0; row < seq_len; row++) {
          for (int col = 0; col < seq_len; col++) {
            if (col > row)
              host_S[col + row * seq_len] = -INFINITY;
          }
        }
      }

      // compute max element per row of S
      std::vector<ElementOutput> max_vec(seq_len, -INFINITY);
      for (int row = 0; row < seq_len; row++) {
        int idx = row * seq_len;
        int max_idx = row;
        max_vec[max_idx] = host_S[idx++];
        for (int col = 1; col < seq_len; col++, idx++) {
          if (max_vec[max_idx] < host_S[idx])
            max_vec[max_idx] = host_S[idx];
        }
      }

      // compute exp of S
      for (int row = 0; row < seq_len; row++) {
        int idx = row * seq_len;
        int max_idx = row;
        for (int col = 0; col < seq_len; col++, idx++) {
          host_S[idx] = expf((host_S[idx] - max_vec[max_idx]) / std::sqrt(static_cast<ElementOutput>((head_size))));
        }
      }

      // compute sum per row of S
      std::vector<ElementOutput> sum_vec(seq_len, ElementOutput{0});
      for (int row = 0; row < seq_len; row++) {
        int idx = row * seq_len;
        int sum_idx = row;
        for (int col = 0; col < seq_len; col++, idx++) {
          sum_vec[sum_idx] += host_S[idx];
        }

        // scale each row with the sum to compute softmax
        idx = row * seq_len;
        sum_idx = row;
        for (int col = 0; col < seq_len; col++, idx++) {
          host_S[idx] /= sum_vec[sum_idx];
        }
      }

      std::vector<ElementV> host_P(host_S.size());
      for (int p = 0; p < host_P.size(); p++)
        host_P[p] = static_cast<ElementV>(host_S[p]);

      cutlass::DeviceAllocation<ElementV> block_P;
      block_P.reset(host_P.size());

      syclcompat::memcpy<ElementV>(block_P.get(), host_P.data(), host_P.size());
      syclcompat::wait();

      cutlass::TensorRef ref_P(block_P.get(), LayoutQ::packed({seq_len, seq_len}));

      cutlass::reference::device::GemmComplex({seq_len, head_size, seq_len}, 1.f, ref_P,
                                              cutlass::ComplexTransform::kNone, ref_V, cutlass::ComplexTransform::kNone,
                                              0.f, ref_O, ref_O, ElementAccumulator(0),
                                              1,                   // batch_count
                                              seq_len * seq_len,   // batch_stride_P
                                              seq_len * head_size, // batch_stride_V
                                              seq_len * head_size, // batch_stride_O
                                              seq_len * head_size  // batch_stride_O
      );

      syclcompat::wait();
      // delete this memory as it is no longer needed
      block_P.reset();
    }

    syclcompat::wait();

    // Check if output from CUTLASS kernel and reference kernel are equal or not
    bool passed = cutlass::reference::device::BlockCompareRelativelyEqual(block_ref_O.get(), block_O.get(),
                                                                          block_O.size(), 0.5f, 0.5f);

    return passed;
  }

  /// Initialize operands to be used in the GEMM and reference GEMM
  void initialize(const ProblemShapeType &problem_size) {
    // auto problem_shape = cute::append<4>(problem_size, 1);
    auto [batch, num_heads, seq_len, head_size] = problem_size;

    stride_Q = cutlass::make_cute_packed_stride(StrideQ{}, cute::make_shape(seq_len, head_size, batch * num_heads));
    stride_K = cutlass::make_cute_packed_stride(StrideK{}, cute::make_shape(seq_len, head_size, batch * num_heads));
    stride_V = cutlass::make_cute_packed_stride(StrideV{}, cute::make_shape(head_size, seq_len, batch * num_heads));
    stride_O = cutlass::make_cute_packed_stride(StrideO{}, cute::make_shape(seq_len, head_size, batch * num_heads));

    auto mem_size = batch * num_heads * seq_len * head_size;

    std::size_t mem_occupied_QKV = (mem_size * sizeof(ElementQ)) + (mem_size * sizeof(ElementK)) + 
                                   (mem_size * sizeof(ElementV));

    count = std::ceil(static_cast<float>(cutlass::get_llc_size()) / static_cast<float>(mem_occupied_QKV)) + 1;

    for(int i = 0; i < count; i++) {
      block_Q.emplace_back();
      block_K.emplace_back();
      block_V.emplace_back();      
    }

    
    for(int i = 0; i < count; i++) {
      block_Q[i].reset(mem_size);
      block_K[i].reset(mem_size);
      block_V[i].reset(mem_size);

      initialize_block(block_Q[i], seed + i);
      initialize_block(block_K[i], seed + i);
      initialize_block(block_V[i], seed + i);
    }

    block_O.reset(mem_size);
    block_ref_O.reset(mem_size);
  }

  static void run(typename GemmKernel::Params params) {
    dim3 const block = GemmKernel::get_block_shape();
    dim3 const grid = GemmKernel::get_grid_shape(params);

    // configure smem size and carveout
    int smem_size = GemmKernel::SharedStorageSize;

    const auto sycl_block = syclcompat::dim3(block.x, block.y, block.z);
    const auto sycl_grid = syclcompat::dim3(grid.x, grid.y, grid.z);

    using namespace syclcompat::experimental;
    auto event = launch<cutlass::device_kernel<GemmKernel>>(
        launch_policy{sycl_grid, sycl_block, local_mem_size{static_cast<std::size_t>(smem_size)},
                      kernel_properties{sycl_exp::sub_group_size<GemmKernel::DispatchPolicy::SubgroupSize>}},
        params);

    EventManager::getInstance().addEvent(event);
  }

  void run(::benchmark::State& state, const FMHAOptions &options, const cutlass::KernelHardwareInfo &hw_info) {
    ProblemShapeType problem_size =
        ProblemShapeType{options.batch, options.num_heads, options.seq_len, options.head_size};

    initialize(problem_size);

    typename GemmKernel::Arguments arguments{
        cutlass::gemm::GemmUniversalMode::kGemm,
        problem_size,
        {block_Q[0].get(), stride_Q, block_K[0].get(), stride_K, block_V[0].get(), stride_V},
        {options.softmax_scale},
        {block_O.get(), stride_O},
        hw_info};

    // GemmKernel gemm_op;

    size_t workspace_size = GemmKernel::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

    GemmKernel::can_implement(arguments);

    // Initialize the workspace
    auto status = GemmKernel::initialize_workspace(arguments, workspace.get());
    if (status != cutlass::Status::kSuccess) {
      return;
    }

    typename GemmKernel::Params params = GemmKernel::to_underlying_arguments(arguments, workspace.get());

    // Run the GEMM
    run(params);

    syclcompat::wait();

    // Verify that the result is correct
    bool passed = verify(problem_size);
    if(not passed) {
      state.SkipWithError("Disposition Failed.");
    }

    state.counters["batch"] = options.batch;
    state.counters["num_heads"] = options.num_heads;
    state.counters["seq_len"] = options.seq_len;
    state.counters["head_size"] = options.head_size;
    state.counters["scale"] = options.softmax_scale;
    state.counters["causal"] = Causal;

    std::stringstream extra_label;
    extra_label << "layoutQ=RowMajor ";
    extra_label << "layoutK=ColumnMajor ";
    extra_label << "layoutV=RowMajor ";

    state.SetLabel(extra_label.str());

    double flops_qk = 2.0 * options.batch * options.num_heads * options.seq_len * options.seq_len * options.head_size;
    double flops_pv = 2.0 * options.batch * options.num_heads * options.seq_len * options.head_size * options.seq_len;
    double gflops = (flops_qk + flops_pv) * 1e-9;

    double mega_bytes_transferred = options.batch * options.num_heads *
                  (options.seq_len * options.head_size + options.seq_len * options.head_size) * 2 * 2 * (1e-6);

    initialize_counters(state);
    int32_t counter = 1;
    for(auto _ : state) {
      state.PauseTiming();
      int input_num = std::max(int(0), counter % count);

      typename GemmKernel::Arguments arguments{
          cutlass::gemm::GemmUniversalMode::kGemm,
          problem_size,
          {block_Q[input_num].get(), stride_Q, block_K[input_num].get(), stride_K, block_V[input_num].get(), stride_V},
          {options.softmax_scale},
          {block_O.get(), stride_O},
          hw_info};

      size_t workspace_size = GemmKernel::get_workspace_size(arguments);
      cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

      GemmKernel::can_implement(arguments);

      // Initialize the workspace
      auto status = GemmKernel::initialize_workspace(arguments, workspace.get());
      if (status != cutlass::Status::kSuccess) {
        return;
      }

      typename GemmKernel::Params params = GemmKernel::to_underlying_arguments(arguments, workspace.get());

      state.ResumeTiming();

      GPU_Clock timer;
      timer.start();
      run(params);
      auto ms_elapsed = timer.milliseconds();
      update_counters(state, ms_elapsed);
      state.SetIterationTime(ms_elapsed / 1000);
      counter++;
    }
    finalize_counters(state, gflops, mega_bytes_transferred);
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

}

#define CUTLASS_FMHA_BENCHMARK(F) cutlass::benchmark::BenchmarkRegistry<cutlass::benchmark::FMHAOptions>::Register(#F, &F##_func)

#define CUTLASS_CREATE_FMHA_BENCHMARK(F)                          \
  static void F##_func(                                           \
      ::benchmark::State& state,                                  \
      cutlass::benchmark::FMHAOptions const& options,                 \
      cutlass::KernelHardwareInfo const& hw_info) {               \
    auto bench = cutlass::benchmark::BenchmarkRunnerFMHA<F>();    \
    bench.run(state, options, hw_info);                           \
  }
