/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "77_blackwell_fmha/collective/fmha_fusion.hpp"
#include "flash_attention_v2/kernel/tile_scheduler.hpp"
#include "cutlass/util/packed_stride.hpp"
#include "flash_attention_v2/kernel/xe_flash_attn_gemm.hpp"
#include "flash_attention_v2/collective/xe_flash_attn_epilogue.hpp"
#include "flash_attention_v2/collective/xe_flash_attn_softmax_epilogue.hpp"
#include "cutlass/util/GPU_Clock.hpp"
#include "cutlass/util/sycl_event_manager.hpp"

#include <cute/tensor.hpp>
#include <random>

#include "helper.h"
#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "sycl_common.hpp"

using namespace cute;

// Command line options parsing
struct Options {

  bool help;
  bool error;
  bool is_causal;
  bool varlen = false;
  std::string scheduler;

  int batch, num_heads, seq_len_qo, seq_len_kv, head_size_qk, head_size_vo, iterations;
  float softmax_scale;

  Options()
      : help(false), error(false), is_causal(false), varlen(false), batch(32), num_heads(16), seq_len_qo(512), head_size_qk(128),
        seq_len_kv(512), head_size_vo(128), iterations(100), softmax_scale(1.f), scheduler("Individual") {}

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    if (cmd.check_cmd_line_flag("is_causal")) {
      is_causal = true;
    }

    if (cmd.check_cmd_line_flag("varlen")) {
      varlen = true;
    }

    cmd.get_cmd_line_argument("scheduler", scheduler, std::string("Individual"));

    cmd.get_cmd_line_argument("batch", batch, 32);
    cmd.get_cmd_line_argument("num_heads", num_heads, 16);
    cmd.get_cmd_line_argument("seq_len_qo", seq_len_qo, 512);
    cmd.get_cmd_line_argument("seq_len_kv", seq_len_kv, seq_len_qo);
    cmd.get_cmd_line_argument("head_size_vo", head_size_vo, 128);
    cmd.get_cmd_line_argument("head_size_qk", head_size_qk, head_size_vo);
    cmd.get_cmd_line_argument("iterations", iterations, 100);

    softmax_scale = 1 / sqrt(static_cast<float>(head_size_qk));
  }

  /// Prints the usage statement.
  std::ostream &print_usage(std::ostream &out) const {

    out << "PVC Flash Attention v2 Example\n\n"
        << "Options:\n\n"
        << "  --help                      If specified, displays this usage statement\n\n"
        << "  --is_causal                 Apply Causal Mask to the output of first Matmul\n"
        << "  --varlen                    Enable variable sequence length\n"
        << "  --scheduler                 Choose between Individual or Persistent Scheduler\n"
        << "  --batch=<int>               Sets the Batch Size of the Multi-Head Self Attention module\n"
        << "  --num_heads=<int>           Sets the Number of Attention Heads of the Multi-Head Self Attention module\n"
        << "  --seq_len_qo=<int>          Sets the Sequence length of the Query input in Multi-Head Self Attention module\n"
        << "  --seq_len_kv=<int>          Sets the Sequence length of the Key-Value pair in Multi-Head Self Attention module\n"
        << "  --head_size_qk=<int>        Sets the Attention Head dimension of the 1st Matrix Multiplication in Multi-Head Self Attention module\n"
        << "  --head_size_vo=<int>        Sets the Attention Head dimension of the 2nd Matrix Multiplication in Multi-Head Self Attention module\n"
        << "  --iterations=<int>          Iterations\n\n";

    return out;
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

// Flash Attention takes 3 input matrices: (K)eys, (Q)ueries and (V)alues.
using LayoutQ = cutlass::layout::RowMajor;
using LayoutK = cutlass::layout::ColumnMajor;
using LayoutV = cutlass::layout::RowMajor;
using LayoutO = cutlass::layout::RowMajor;

template <class GemmKernel, bool isVarLen> struct ExampleRunner {

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

  //
  // Data members
  //

  /// Initialization
  StrideQ stride_Q;
  StrideK stride_K;
  StrideV stride_V;
  StrideO stride_O;
  uint64_t seed = 0;

  cutlass::DeviceAllocation<ElementQ> block_Q;
  cutlass::DeviceAllocation<ElementK> block_K;
  cutlass::DeviceAllocation<ElementV> block_V;
  cutlass::DeviceAllocation<ElementOutput> block_O;
  cutlass::DeviceAllocation<ElementOutput> block_ref_O;

  std::vector<int> cumulative_seqlen_q;
  std::vector<int> cumulative_seqlen_kv;
  cutlass::DeviceAllocation<int> device_cumulative_seqlen_q;
  cutlass::DeviceAllocation<int> device_cumulative_seqlen_kv;

  //
  // Methods
  //

  bool verify(ProblemShapeType problem_size, bool is_causal) {
    
    if constexpr (isVarLen) {
      int max_seq_len_q = static_cast<int>(get<2>(problem_size));
      int max_seq_len_kv = static_cast<int>(get<3>(problem_size));
      get<2>(problem_size) = cutlass::fmha::collective::VariableLength{max_seq_len_q, cumulative_seqlen_q.data()};
      get<3>(problem_size) = cutlass::fmha::collective::VariableLength{max_seq_len_kv, cumulative_seqlen_kv.data()};
    }

    auto [batch, num_heads, head_size_qk, head_size_vo] = cute::select<0,1,4,5>(problem_size);
    int seq_len_qo, seq_len_kv;

    int offset_q = 0;
    int offset_k = 0;
    int offset_v = 0;
    int offset_o = 0;
    // loop over the batch dimension to compute the output
    // to avoid the risk of running out of device memory
    for (int b = 0; b < batch; b++) {
      if constexpr (isVarLen) {
        auto logical_problem_shape = cutlass::fmha::collective::apply_variable_length(problem_size, b);
        seq_len_qo = get<2>(logical_problem_shape);
        seq_len_kv = get<3>(logical_problem_shape);
      } else {
        seq_len_qo = get<2>(problem_size);
        seq_len_kv = get<3>(problem_size);
      }

      for (int h = 0; h < num_heads; h++) {
        cutlass::DeviceAllocation<ElementOutput> block_S;
        block_S.reset(seq_len_qo * seq_len_kv);

        cutlass::TensorRef ref_Q(block_Q.get() + offset_q, LayoutQ::packed({seq_len_qo, head_size_qk}));
        cutlass::TensorRef ref_K(block_K.get() + offset_k, LayoutK::packed({head_size_qk, seq_len_kv}));
        cutlass::TensorRef ref_V(block_V.get() + offset_v, LayoutV::packed({seq_len_kv, head_size_vo}));
        cutlass::TensorRef ref_S(block_S.get(), LayoutQ::packed({seq_len_qo, seq_len_kv}));
        cutlass::TensorRef ref_O(block_ref_O.get() + offset_o, LayoutO::packed({seq_len_qo, head_size_vo}));

        cutlass::reference::device::GemmComplex({seq_len_qo, seq_len_kv, head_size_qk}, 1.f, ref_Q,
                                                cutlass::ComplexTransform::kNone, ref_K, cutlass::ComplexTransform::kNone,
                                                0.f, ref_S, ref_S, ElementAccumulator(0),
                                                1,                   // batch_count
                                                seq_len_qo * head_size_qk, // batch_stride_Q
                                                seq_len_kv * head_size_qk, // batch_stride_K
                                                seq_len_qo * seq_len_kv,   // batch_stride_S
                                                seq_len_qo * seq_len_kv    // batch_stride_S
        );

        syclcompat::wait();

        std::vector<ElementOutput> host_S(block_S.size());
        syclcompat::memcpy<ElementOutput>(host_S.data(), block_S.get(), host_S.size());
        syclcompat::wait();

        // delete this memory as it is no longer needed
        block_S.reset();

        // Apply upper-diagonal masking if required
        if (is_causal) {
          // apply mask to S
          for (int row = 0; row < seq_len_qo; row++) {
            for (int col = 0; col < seq_len_kv; col++) {
              if (col > row)
                host_S[col + row * seq_len_kv] = -INFINITY;
            }
          }
        }

        // compute max element per row of S
        std::vector<ElementOutput> max_vec(seq_len_qo, -INFINITY);
        for (int row = 0; row < seq_len_qo; row++) {
          int idx = row * seq_len_kv;
          int max_idx = row;
          max_vec[max_idx] = host_S[idx++];
          for (int col = 1; col < seq_len_kv; col++, idx++) {
            if (max_vec[max_idx] < host_S[idx])
              max_vec[max_idx] = host_S[idx];
          }
        }

        // compute exp of S
        for (int row = 0; row < seq_len_qo; row++) {
          int idx = row * seq_len_kv;
          int max_idx = row;
          for (int col = 0; col < seq_len_kv; col++, idx++) {
            host_S[idx] = expf((host_S[idx] - max_vec[max_idx]) / sqrt(static_cast<ElementOutput>((head_size_qk))));
          }
        }

        // compute sum per row of S
        std::vector<ElementOutput> sum_vec(seq_len_qo, ElementOutput{0});
        for (int row = 0; row < seq_len_qo; row++) {
          int idx = row * seq_len_kv;
          int sum_idx = row;
          for (int col = 0; col < seq_len_kv; col++, idx++) {
            sum_vec[sum_idx] += host_S[idx];
          }

          // scale each row with the sum to compute softmax
          idx = row * seq_len_kv;
          sum_idx = row;
          for (int col = 0; col < seq_len_kv; col++, idx++) {
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

        cutlass::TensorRef ref_P(block_P.get(), LayoutQ::packed({seq_len_qo, seq_len_kv}));

        cutlass::reference::device::GemmComplex({seq_len_qo, head_size_vo, seq_len_kv}, 1.f, ref_P,
                                                cutlass::ComplexTransform::kNone, ref_V, cutlass::ComplexTransform::kNone,
                                                0.f, ref_O, ref_O, ElementAccumulator(0),
                                                1,                   // batch_count
                                                seq_len_qo * seq_len_kv,   // batch_stride_P
                                                seq_len_kv * head_size_vo, // batch_stride_V
                                                seq_len_qo * head_size_vo, // batch_stride_O
                                                seq_len_qo * head_size_vo  // batch_stride_O
        );

        syclcompat::wait();
        // delete this memory as it is no longer needed
        block_P.reset();

        offset_q += seq_len_qo * head_size_qk;
        offset_k += seq_len_kv * head_size_qk;
        offset_v += seq_len_kv * head_size_vo;
        offset_o += seq_len_qo * head_size_vo;
      }
    }

    syclcompat::wait();

    // Check if output from CUTLASS kernel and reference kernel are equal or not
    bool passed = cutlass::reference::device::BlockCompareRelativelyEqual(block_ref_O.get(), block_O.get(),
                                                                          block_O.size(), 0.5f, 0.5f);

    return passed;
  }

  template<class ProblemShape>
  auto initialize_varlen(const ProblemShape& problem_size, const bool VarlenSame = true) {
    int num_batches = get<0>(problem_size);

    // generate Q as --b times
    //    gaussian (--Q, --Q / 2) sampled positive
    //    track cumulative 
    std::mt19937 rng(0x202305151552ull);
    std::normal_distribution<double> dist_q(get<2>(problem_size), get<2>(problem_size) / 2);
    std::normal_distribution<double> dist_kv(get<3>(problem_size), get<3>(problem_size) / 2);

    auto generate_positive_int = [](auto& dist, auto& gen) {
      int result = 0;
      do {
        result = static_cast<int>(dist(gen));
      } while (result <= 0);
      return result;
    };

    cumulative_seqlen_q = {0};
    cumulative_seqlen_kv = {0};

    int total_seqlen_q = 0;
    int total_seqlen_kv = 0;
    int max_seqlen_q = 0;
    int max_seqlen_kv = 0;

    for (int i = 0; i < num_batches; i++) {
      int seqlen_q = VarlenSame ? get<2>(problem_size) : generate_positive_int(dist_q, rng);
      int seqlen_kv = VarlenSame ? get<3>(problem_size) : generate_positive_int(dist_kv, rng);

      total_seqlen_q += seqlen_q;
      total_seqlen_kv += seqlen_kv;

      max_seqlen_q = std::max(max_seqlen_q, seqlen_q);
      max_seqlen_kv = std::max(max_seqlen_kv, seqlen_kv);

      cumulative_seqlen_q.push_back(cumulative_seqlen_q.back() + seqlen_q);
      cumulative_seqlen_kv.push_back(cumulative_seqlen_kv.back() + seqlen_kv);
    }

    ProblemShape problem_size_for_init = problem_size;
    get<0>(problem_size_for_init) = 1;
    get<2>(problem_size_for_init) = total_seqlen_q;
    get<3>(problem_size_for_init) = total_seqlen_kv;

    ProblemShapeType problem_size_for_launch;

    get<2>(problem_size_for_launch) = cutlass::fmha::collective::VariableLength{max_seqlen_q};
    get<3>(problem_size_for_launch) = cutlass::fmha::collective::VariableLength{max_seqlen_kv};
    get<4>(problem_size_for_launch) = get<4>(problem_size);
    get<5>(problem_size_for_launch) = get<5>(problem_size);
    get<0>(problem_size_for_launch) = get<0>(problem_size);
    get<1>(problem_size_for_launch) = get<1>(problem_size);

    return cute::make_tuple(problem_size_for_init, problem_size_for_launch);
  }

  /// Initialize operands to be used in the GEMM and reference GEMM
  ProblemShapeType initialize(const Options &options) {
    auto problem_shape_in =
        cute::make_tuple(options.batch, options.num_heads, options.seq_len_qo, options.seq_len_kv, options.head_size_qk, options.head_size_vo);

    ProblemShapeType problem_shape;
    decltype(problem_shape_in) problem_size;

    if constexpr (isVarLen) {
      auto [problem_shape_init, problem_shape_launch] = initialize_varlen(problem_shape_in);
      problem_shape = problem_shape_launch;
      problem_size = problem_shape_init;
    }
    else {
      problem_size = problem_shape_in;
      problem_shape = problem_shape_in;
    }

    auto [batch, num_heads, seq_len_qo, seq_len_kv, head_size_qk, head_size_vo] = problem_size;

    stride_Q = cutlass::make_cute_packed_stride(StrideQ{}, cute::make_shape(seq_len_qo, head_size_qk, batch * num_heads));
    stride_K = cutlass::make_cute_packed_stride(StrideK{}, cute::make_shape(seq_len_kv, head_size_qk, batch * num_heads));
    stride_V = cutlass::make_cute_packed_stride(StrideV{}, cute::make_shape(head_size_vo, seq_len_kv, batch * num_heads));
    stride_O = cutlass::make_cute_packed_stride(StrideO{}, cute::make_shape(seq_len_qo, head_size_vo, batch * num_heads));

    block_Q.reset(batch * num_heads * seq_len_qo * head_size_qk);
    block_K.reset(batch * num_heads * seq_len_kv * head_size_qk);
    block_V.reset(batch * num_heads * seq_len_kv * head_size_vo);
    block_O.reset(batch * num_heads * seq_len_qo * head_size_vo);
    block_ref_O.reset(batch * num_heads * seq_len_qo * head_size_vo);

    initialize_block(block_Q, seed + 2023);
    initialize_block(block_K, seed + 2022);
    initialize_block(block_V, seed + 2021);

    if (!cumulative_seqlen_q.empty()) {
      device_cumulative_seqlen_q.reset(cumulative_seqlen_q.size());
      device_cumulative_seqlen_q.copy_from_host(
        cumulative_seqlen_q.data(), cumulative_seqlen_q.size());
    }
    if (!cumulative_seqlen_kv.empty()) {
      device_cumulative_seqlen_kv.reset(cumulative_seqlen_kv.size());
      device_cumulative_seqlen_kv.copy_from_host(
        cumulative_seqlen_kv.data(), cumulative_seqlen_kv.size());
    }

    if constexpr (isVarLen) {
      get<2>(problem_shape).cumulative_length = device_cumulative_seqlen_q.get();
      get<3>(problem_shape).cumulative_length = device_cumulative_seqlen_kv.get();
    }

    return problem_shape;
  }

  // Note that the GemmUniversalAdapter currently doesn't support flash attention, which is why this
  // secondary `run` function is required to launch the kernel.
  static void run(typename GemmKernel::Params params) {
    dim3 const block = GemmKernel::get_block_shape();
    dim3 const grid = GemmKernel::get_grid_shape(params);

    // configure smem size and carveout
    int smem_size = GemmKernel::SharedStorageSize;

    const auto sycl_block = syclcompat::dim3(block.x, block.y, block.z);
    const auto sycl_grid = syclcompat::dim3(grid.x, grid.y, grid.z);

// Launch parameters depend on whether SYCL compiler supports work-group scratch memory extension
#if !defined(SYCL_EXT_ONEAPI_WORK_GROUP_SCRATCH_MEMORY)
    using namespace syclcompat::experimental;
    auto event = launch<cutlass::device_kernel<GemmKernel>>(
        launch_policy{sycl_grid, sycl_block, local_mem_size{static_cast<std::size_t>(smem_size)},
                      kernel_properties{sycl_exp::sub_group_size<GemmKernel::DispatchPolicy::SubgroupSize>}},
        params);
#else
    syclcompat::experimental::launch_properties launch_props {
      sycl::ext::oneapi::experimental::work_group_scratch_size(smem_size),
    };
    syclcompat::experimental::kernel_properties kernel_props{
      sycl::ext::oneapi::experimental::sub_group_size<GemmKernel::DispatchPolicy::SubgroupSize>
    };
    syclcompat::experimental::launch_policy policy{sycl_grid, sycl_block, launch_props, kernel_props};
    auto event = syclcompat::experimental::launch<cutlass::device_kernel<GemmKernel>>(policy, params);
#endif

    EventManager::getInstance().addEvent(event);
  }

  cutlass::Status run(const Options &options, const cutlass::KernelHardwareInfo &hw_info) {

    ProblemShapeType problem_size = initialize(options);

    typename GemmKernel::Arguments arguments{
        cutlass::gemm::GemmUniversalMode::kGemm,
        problem_size,
        {block_Q.get(), stride_Q, block_K.get(), stride_K, block_V.get(), stride_V},
        {options.softmax_scale},
        {block_O.get(), stride_O},
        hw_info};

    // GemmKernel gemm_op;

    // Define device-global scratch memory
    size_t workspace_size = GemmKernel::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

    if (!GemmKernel::can_implement(arguments)) {
      std::cout << "Invalid Problem Size: " << options.batch << 'x' << options.num_heads << 'x' <<
        options.seq_len_qo << 'x' << options.seq_len_kv << 'x' << options.head_size_qk << 'x'  << options.head_size_vo 
        << (options.is_causal ? "xCausal" : "xNonCausal") << std::endl;
      return cutlass::Status::kErrorInvalidProblem;
    }

    // Initialize the workspace
    CUTLASS_CHECK(GemmKernel::initialize_workspace(arguments, workspace.get()));

    // Convert host-side arguments to device-side arguments to be passed to the kernel
    auto params = GemmKernel::to_underlying_arguments(arguments, workspace.get());

    // Run the GEMM
    run(params);

    syclcompat::wait();

    // Verify that the result is correct
    bool passed = verify(problem_size, options.is_causal);
    std::cout << "Disposition: " << (passed ? "Passed" : "Failed") << std::endl;

    if (!passed) {
      return cutlass::Status::kErrorInternal;
    }

    if (options.iterations > 0) {
      GPU_Clock timer;
      timer.start();
      for (int i = 0; i < options.iterations; ++i) {
        run(params);
      }
      syclcompat::wait();

      double cute_time = timer.seconds() / options.iterations;
      double flops_qk = 2.0 * options.batch * options.num_heads * options.seq_len_qo * options.seq_len_kv * options.head_size_qk;
      double flops_pv = 2.0 * options.batch * options.num_heads * options.seq_len_qo * options.head_size_vo * options.seq_len_kv;
      double tflops = ((flops_qk + flops_pv) * 1e-12) / cute_time;
      double gbps_qk = 2.0 * options.batch * options.num_heads * (options.seq_len_qo * options.head_size_qk + options.seq_len_kv * options.head_size_qk);
      double gbps_pv = 2.0 * options.batch * options.num_heads * (options.seq_len_kv * options.seq_len_qo + options.seq_len_qo * options.head_size_vo);
      double gbps = ((gbps_qk + gbps_pv)  * 1e-9) / (cute_time);
      std::cout << "Batch: " << options.batch << "\tNumHeads: " << options.num_heads << "\tSeq Length QO: " << options.seq_len_qo
                << "\tSeq Length KV: " << options.seq_len_kv << "\tHead Size QK: " << options.head_size_qk << "\tHead Size VO: " << options.head_size_vo
                << "\tCausal Mask: " << (options.is_causal ? "true" : "false") << "\tVariable Sequence Length: " << (options.varlen ? "true" : "false")
                << "\t Scheduler: " << options.scheduler;
      printf("\nPerformance:   %4.3f  GB/s,    %4.3f  TFlop/s,   %6.4f  ms\n\n", gbps, tflops, cute_time * 1000);
    }

    return cutlass::Status::kSuccess;
  }
};

template <bool Causal, typename TileShape, typename TiledMma> struct FMHAConfig {

  template <bool isVarLen, class Scheduler>
  static int run(const Options &options) {
    //
    // Run examples
    //

    // The KernelHardwareInfo struct holds the number of EUs on the GPU with a given device ID. This
    // information is used by the underlying kernel.
    cutlass::KernelHardwareInfo hw_info;

    // The code section below describes datatype for input, output matrices and computation between
    // elements in input matrices.
    using ElementAccumulator = float;     // <- data type of accumulator
    using ElementComputeEpilogue = float; // <- data type of epilogue operations
    using ElementInputQ = bfloat16_t;     // <- data type of elements in input matrix A
    using ElementInputKV = bfloat16_t;    // <- data type of elements in input matrix B
    using ElementOutput = float;          // <- data type of elements in output matrix D
        
    constexpr int PipelineStages = 2;
    using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelPVC<PipelineStages>;
    using EpilogueDispatchPolicy = cutlass::epilogue::IntelPVCEpilogue;

    using GmemTiledCopyQ = XE_2D_U16x16x32_LD_N;
    using GmemTiledCopyK = XE_2D_U16x16x16_LD_T; // _T designates a transposed block load operation
    using GmemTiledCopyV = XE_2D_U16x32x32_LD_V;
    using GmemTiledCopyStore = XE_2D_U32x8x16_ST_N;
    using CollectiveEpilogue = cutlass::flash_attention::collective::CollectiveEpilogueAttention<
        EpilogueDispatchPolicy, TileShape, ElementAccumulator, cutlass::gemm::TagToStrideC_t<LayoutO>, ElementOutput,
        GmemTiledCopyStore>;
    using CollectiveSoftmaxEpilogue = cutlass::flash_attention::collective::CollectiveSoftmaxEpilogue<Causal, EpilogueDispatchPolicy, ElementAccumulator>;

    using ProblemShapeRegular = cute::tuple<int, int, int, int, int, int>;
    using namespace cutlass::fmha::collective;
    using ProblemShapeVarlen = cute::tuple<int, int, VariableLength, VariableLength, int, int>;
    using ProblemShapeType = std::conditional_t<isVarLen, ProblemShapeVarlen, ProblemShapeRegular>;

    // Mainloop
    using CollectiveMainloop = cutlass::flash_attention::collective::CollectiveMmaAttention<
        GEMMDispatchPolicy, ProblemShapeType, TileShape, ElementInputQ, cutlass::gemm::TagToStrideA_t<LayoutQ>, ElementInputKV,
        cutlass::gemm::TagToStrideB_t<LayoutK>, ElementInputKV, cutlass::gemm::TagToStrideB_t<LayoutV>, TiledMma,
        GmemTiledCopyQ, // Q
        GmemTiledCopyK, // K
        GmemTiledCopyV, // V,
        Causal>;

    using GemmKernel = cutlass::flash_attention::kernel::GemmUniversalAttention<ProblemShapeType, CollectiveMainloop,
                                                                     CollectiveSoftmaxEpilogue, CollectiveEpilogue, Scheduler>;

    ExampleRunner<GemmKernel, isVarLen> runner;

    CUTLASS_CHECK(runner.run(options, hw_info));
    return 0;    
  }

  static int run(const Options &options) {
    if(options.varlen) {
      if(options.scheduler.compare(std::string("Persistent")) == 0) {
        return run<true, cutlass::flash_attention::PersistentScheduler>(options);
      } else {
        return run<true, cutlass::flash_attention::IndividualScheduler>(options);
      }
    } else {
      if(options.scheduler.compare(std::string("Persistent")) == 0) {
        return run<false, cutlass::flash_attention::PersistentScheduler>(options);
      } else {
        return run<false, cutlass::flash_attention::IndividualScheduler>(options);
      }
    }
  }
};
