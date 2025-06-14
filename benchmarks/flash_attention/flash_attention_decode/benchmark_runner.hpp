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
#include "cutlass/epilogue/fusion/xe_callbacks.hpp"
#include "flash_attention_v2/kernel/tile_scheduler.hpp"
#include "flash_attention_v2/collective/fmha_fusion.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/util/packed_stride.hpp"
#include "flash_attention_v2/kernel/xe_flash_attn_decode.hpp"
#include "flash_attention_v2/collective/xe_flash_attn_decode_epilogue.hpp"
#include "flash_attention_v2/collective/xe_flash_attn_decode_softmax_epilogue.hpp"
#include "cutlass/util/GPU_Clock.hpp"
#include "cutlass/util/sycl_event_manager.hpp"

#include <cute/tensor.hpp>
#include <random>

#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "../examples/common/sycl_common.hpp"
#include "../../common.hpp"

using namespace cute;

namespace cutlass::benchmark {

// Command line options parsing
struct FMHADecodeOptions {

  bool error;

  int batch, num_heads_q, num_heads_kv, seq_len_qo, seq_len_kv, seq_len_kv_cache, head_size_qk,
      head_size_vo, iterations, page_size;
  float softmax_scale;
  std::string bm_name;

  FMHADecodeOptions()
      : error(false), batch(32), num_heads_q(16), num_heads_kv(16), seq_len_qo(1), head_size_qk(128),
        seq_len_kv(512), seq_len_kv_cache(0), page_size(128), head_size_vo(128), iterations(100), softmax_scale(1.f), bm_name("Flash Attention v2 Decode") {}

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    cmd.get_cmd_line_argument("batch", batch, 32);
    cmd.get_cmd_line_argument("num_heads_q", num_heads_q, 16);
    cmd.get_cmd_line_argument("num_heads_kv", num_heads_kv, num_heads_q);
    cmd.get_cmd_line_argument("seq_len_qo", seq_len_qo, 1);
    cmd.get_cmd_line_argument("seq_len_kv", seq_len_kv, seq_len_qo);
    cmd.get_cmd_line_argument("seq_len_kv_cache", seq_len_kv_cache, 0);
    cmd.get_cmd_line_argument("page_size", page_size, 128);
    cmd.get_cmd_line_argument("head_size_vo", head_size_vo, 128);
    cmd.get_cmd_line_argument("head_size_qk", head_size_qk, head_size_vo);
    cmd.get_cmd_line_argument("iterations", iterations, 100);
    cmd.get_cmd_line_argument("bm_name", bm_name, std::string("Flash Attention v2"));

    softmax_scale = 1 / std::sqrt(static_cast<float>(head_size_qk));

    if (seq_len_kv_cache % page_size != 0) {
      std::cerr << "Invalid: seq_len_kv_cache must be divisible by page_size" << std::endl;
      return;
    }
  }

  std::string benchmark_name() const {
    std::stringstream full_name;
    full_name << bm_name << "/";
    std::string const test_name_suffix = std::to_string(batch) + "x" +
                                   std::to_string(num_heads_q) + "x" +
                                   std::to_string(num_heads_kv) + "x" +
                                   std::to_string(seq_len_qo) + "x" +
                                   std::to_string(head_size_qk) + "x" +
                                   std::to_string(seq_len_kv) + "x" +
                                   std::to_string(seq_len_kv_cache) + "x" +
                                   std::to_string(head_size_vo);
    full_name << test_name_suffix;

    return full_name.str();
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template <class FMHADecodeConfiguration> struct BenchmarkRunnerFMHADecode {

  using FMHADecodeKernel = typename FMHADecodeConfiguration::FMHADecodeKernel;
  
  using LayoutQ = typename FMHADecodeConfiguration::LayoutQ;
  using LayoutK = typename FMHADecodeConfiguration::LayoutK;
  using LayoutV = typename FMHADecodeConfiguration::LayoutV;
  using LayoutO = typename FMHADecodeConfiguration::LayoutO;

  using StrideQ = typename FMHADecodeKernel::StrideQ;
  using StrideK = typename FMHADecodeKernel::StrideK;
  using StrideV = typename FMHADecodeKernel::StrideV;
  using StrideO = typename FMHADecodeKernel::StrideO;

  using ElementQ = typename FMHADecodeKernel::ElementQ;
  using ElementK = typename FMHADecodeKernel::ElementK;
  using ElementV = typename FMHADecodeKernel::ElementV;
  using ElementAcc = typename FMHADecodeKernel::ElementAccumulator;

  using CollectiveEpilogue = typename FMHADecodeKernel::CollectiveEpilogue;
  using ElementOutput = typename CollectiveEpilogue::ElementOutput;
  using ElementCompute = typename CollectiveEpilogue::ElementCompute;
  using ElementAccumulator = typename CollectiveEpilogue::ElementAccumulator;

  using ProblemShapeType = typename FMHADecodeKernel::ProblemShape;
  static constexpr bool Causal = FMHADecodeConfiguration::Causal;
  static constexpr bool isVarLen = FMHADecodeConfiguration::VarLen;
  static constexpr bool PagedKV = FMHADecodeConfiguration::PagedKV;

  int32_t count;

  //
  // Data members
  //

  /// Initialization
  StrideQ stride_Q;
  StrideK stride_K;
  StrideV stride_V;
  StrideO stride_O;
  StrideK stride_K_cache;
  StrideV stride_V_cache;

  uint64_t seed = 0;

  std::vector<cutlass::DeviceAllocation<ElementQ>> block_Q;
  std::vector<cutlass::DeviceAllocation<ElementK>> block_K;
  std::vector<cutlass::DeviceAllocation<ElementV>> block_V;
  std::vector<cutlass::DeviceAllocation<ElementK>> block_K_cache;
  std::vector<cutlass::DeviceAllocation<ElementV>> block_V_cache;
  cutlass::DeviceAllocation<ElementOutput> block_O;
  cutlass::DeviceAllocation<ElementOutput> block_ref_O;

  std::vector<int> cumulative_seqlen_q;
  std::vector<int> cumulative_seqlen_kv;
  std::vector<int> cumulative_seqlen_kv_cache;
  cutlass::DeviceAllocation<int> device_cumulative_seqlen_q;
  cutlass::DeviceAllocation<int> device_cumulative_seqlen_kv;
  cutlass::DeviceAllocation<int> device_cumulative_seqlen_kv_cache;

  struct PagedKVParams {
      cutlass::DeviceAllocation<int> page_table;
      int page_size = 0;
      cutlass::DeviceAllocation<int> num_pages_per_seq;
  };
  PagedKVParams paged_kv_cache;

  //
  // Methods
  //

  bool verify(ProblemShapeType problem_size) {
    
    if constexpr (isVarLen) {
      int max_seq_len_q = static_cast<int>(get<3>(problem_size));
      int max_seq_len_kv = static_cast<int>(get<4>(problem_size));
      int max_seq_len_kv_cache = static_cast<int>(get<5>(problem_size));
      get<3>(problem_size) = cutlass::fmha::collective::VariableLength{max_seq_len_q, cumulative_seqlen_q.data()};
      get<4>(problem_size) = cutlass::fmha::collective::VariableLength{max_seq_len_kv, cumulative_seqlen_kv.data()};
      get<5>(problem_size) = cutlass::fmha::collective::VariableLength{max_seq_len_kv_cache, cumulative_seqlen_kv_cache.data()};
    }

    auto [batch, num_heads_q, num_heads_kv, head_size_qk, head_size_vo] = cute::select<0,1,2,6,7>(problem_size);
    int seq_len_qo, seq_len_kv, seq_len_kv_cache;

    int offset_q = 0;
    int offset_k = 0;
    int offset_v = 0;
    int offset_k_cache = 0;
    int offset_v_cache = 0;
    int offset_o = 0;
    // loop over the batch dimension to compute the output
    // to avoid the risk of running out of device memory
    int q_group_size = num_heads_q / num_heads_kv;
    for (int b = 0; b < batch; b++) {
      if constexpr (isVarLen) {
        auto logical_problem_shape = cutlass::fmha::collective::apply_variable_length(problem_size, b);
        seq_len_qo = get<3>(logical_problem_shape);
        seq_len_kv = get<4>(logical_problem_shape);
        seq_len_kv_cache = get<5>(logical_problem_shape);
      } else {
        seq_len_qo = get<3>(problem_size);
        seq_len_kv = get<4>(problem_size);
        seq_len_kv_cache = get<5>(problem_size);
      }

      int seq_len_kv_total = seq_len_kv_cache + seq_len_kv;
      int kv_group_update = 1;
      for (int h = 0; h < num_heads_q; h++) {
        cutlass::DeviceAllocation<ElementAccumulator> block_S;
        block_S.reset(seq_len_qo * seq_len_kv_total);

        ElementK* k_ptr;
        ElementV* v_ptr;

        if (seq_len_kv_cache > 0) {
            cutlass::DeviceAllocation<ElementK> block_K_concat(head_size_qk * seq_len_kv_total);
            cutlass::DeviceAllocation<ElementV> block_V_concat(seq_len_kv_total * head_size_vo);

            // Concatenate K_cache and K
            syclcompat::memcpy<ElementK>(
                block_K_concat.get(),
                block_K_cache[0].get() + offset_k_cache,
                seq_len_kv_cache * head_size_qk
            );
            syclcompat::memcpy<ElementK>(
                block_K_concat.get() + seq_len_kv_cache * head_size_qk,
                block_K[0].get() + offset_k,
                seq_len_kv * head_size_qk
            );

            // Concatenate V_cache and V
            syclcompat::memcpy<ElementV>(
                block_V_concat.get(),
                block_V_cache[0].get() + offset_v_cache,
                seq_len_kv_cache * head_size_vo
            );
            syclcompat::memcpy<ElementV>(
                block_V_concat.get() + seq_len_kv_cache * head_size_vo,
                block_V[0].get() + offset_v,
                seq_len_kv * head_size_vo
            );
            syclcompat::wait();

            k_ptr = block_K_concat.get();
            v_ptr = block_V_concat.get();
        }
        else {
            k_ptr = block_K[0].get() + offset_k;
            v_ptr = block_V[0].get() + offset_v;
        }

        cutlass::TensorRef ref_Q(block_Q[0].get() + offset_q, LayoutQ::packed({seq_len_qo, head_size_qk}));
        cutlass::TensorRef ref_K(k_ptr, LayoutK::packed({head_size_qk, seq_len_kv_total}));
        cutlass::TensorRef ref_V(v_ptr, LayoutV::packed({seq_len_kv_total, head_size_vo}));
        cutlass::TensorRef ref_S(block_S.get(), LayoutQ::packed({seq_len_qo, seq_len_kv_total}));

        cutlass::reference::device::GemmComplex({seq_len_qo, seq_len_kv_total, head_size_qk}, ElementAccumulator{1}, ref_Q,
                                                cutlass::ComplexTransform::kNone, ref_K, cutlass::ComplexTransform::kNone,
                                                ElementAccumulator{0}, ref_S, ref_S, ElementAccumulator{0},
                                                1,                   // batch_count
                                                seq_len_qo * head_size_qk, // batch_stride_Q
                                                seq_len_kv_total * head_size_qk, // batch_stride_K
                                                seq_len_qo * seq_len_kv_total,   // batch_stride_S
                                                seq_len_qo * seq_len_kv_total    // batch_stride_S
        );

        syclcompat::wait();

        std::vector<ElementAccumulator> host_S(block_S.size());
        syclcompat::memcpy<ElementAccumulator>(host_S.data(), block_S.get(), host_S.size());
        syclcompat::wait();

        // delete this memory as it is no longer needed
        block_S.reset();

        auto offset = cute::min(seq_len_qo, seq_len_kv);
        auto discard_seq_coord = seq_len_qo - offset;
        auto full_tile_offset = seq_len_kv - offset;
        if (Causal) {
          // apply mask to S
          for (int row = 0; row < seq_len_qo; row++) {
            for (int col = seq_len_kv_cache; col < seq_len_kv_total; col++) {
              if ((col - full_tile_offset) > (row + seq_len_kv_cache - discard_seq_coord))
                host_S[col + row * seq_len_kv_total] = ElementAccumulator{-INFINITY};
            }
          }
        }

        // compute max element per row of S
        std::vector<ElementAccumulator> max_vec(seq_len_qo, ElementAccumulator{-INFINITY});
        for (int row = 0; row < seq_len_qo; row++) {
          int idx = row * seq_len_kv_total;
          int max_idx = row;
          max_vec[max_idx] = host_S[idx++];
          for (int col = 1; col < seq_len_kv_total; col++, idx++) {
            if (max_vec[max_idx] < host_S[idx])
              max_vec[max_idx] = host_S[idx];
          }
        }

        // compute exp of S
        for (int row = 0; row < seq_len_qo; row++) {
          int idx = row * seq_len_kv_total;
          int max_idx = row;
          for (int col = 0; col < seq_len_kv_total; col++, idx++) {
            host_S[idx] = expf((host_S[idx] - max_vec[max_idx]) / std::sqrt(static_cast<ElementAccumulator>((head_size_qk))));
          }
        }

        // compute sum per row of S
        std::vector<ElementAccumulator> sum_vec(seq_len_qo, ElementAccumulator{0});
        for (int row = 0; row < seq_len_qo; row++) {
          int idx = row * seq_len_kv_total;
          int sum_idx = row;
          for (int col = 0; col < seq_len_kv_total; col++, idx++) {
            sum_vec[sum_idx] += host_S[idx];
          }

          // scale each row with the sum to compute softmax
          idx = row * seq_len_kv_total;
          sum_idx = row;
          for (int col = 0; col < seq_len_kv_total; col++, idx++) {
            if(Causal && row < discard_seq_coord) { 
              host_S[idx] = 0;
            } else {
              host_S[idx] /= sum_vec[sum_idx];
            }
          }
        }

        std::vector<ElementV> host_P(host_S.size());
        for (int p = 0; p < host_P.size(); p++)
          host_P[p] = static_cast<ElementV>(host_S[p]);

        cutlass::DeviceAllocation<ElementV> block_P;
        block_P.reset(host_P.size());

        syclcompat::memcpy<ElementV>(block_P.get(), host_P.data(), host_P.size());
        syclcompat::wait();

        cutlass::TensorRef ref_P(block_P.get(), LayoutQ::packed({seq_len_qo, seq_len_kv_total}));

        cutlass::DeviceAllocation<ElementAccumulator> block_acc;
        block_acc.reset(seq_len_qo * head_size_vo);
        cutlass::TensorRef ref_acc(block_acc.get(), LayoutO::packed({seq_len_qo, head_size_vo}));

        cutlass::reference::device::GemmComplex({seq_len_qo, head_size_vo, seq_len_kv_total}, ElementAccumulator{1}, ref_P,
                                                cutlass::ComplexTransform::kNone, ref_V, cutlass::ComplexTransform::kNone,
                                                ElementAccumulator{0}, ref_acc, ref_acc, ElementAccumulator{0},
                                                1,                   // batch_count
                                                seq_len_qo * seq_len_kv_total,   // batch_stride_P
                                                seq_len_kv_total * head_size_vo, // batch_stride_V
                                                seq_len_qo * head_size_vo, // batch_stride_O
                                                seq_len_qo * head_size_vo  // batch_stride_O
        );

        syclcompat::wait();
        // delete this memory as it is no longer needed
        block_P.reset();

        std::vector<ElementAccumulator> vec_acc(block_acc.size());
        syclcompat::memcpy<ElementAccumulator>(vec_acc.data(), block_acc.get(), vec_acc.size());
        syclcompat::wait();

        // delete this memory as it is no longer needed
        block_acc.reset();
        std::vector<ElementOutput> vec_out(vec_acc.size());
        for(int i = 0; i < vec_out.size(); i++) {
          vec_out[i] = static_cast<ElementOutput>(vec_acc[i]);
        }
        syclcompat::memcpy<ElementOutput>(block_ref_O.get() + offset_o, vec_out.data(), vec_out.size());
        syclcompat::wait();

        offset_q += seq_len_qo * head_size_qk;
        if(kv_group_update % q_group_size == 0) {
          offset_k += seq_len_kv * head_size_qk;
          offset_v += seq_len_kv * head_size_vo;
          offset_k_cache += seq_len_kv_cache * head_size_qk;
          offset_v_cache += seq_len_kv_cache * head_size_vo;
        }
        kv_group_update++;
        offset_o += seq_len_qo * head_size_vo;
      }
    }

    syclcompat::wait();

    // Check if output from CUTLASS kernel and reference kernel are equal or not
    bool passed = cutlass::reference::device::BlockCompareRelativelyEqual(block_ref_O.get(), block_O.get(),
                                                                          block_O.size(), ElementOutput{0.5}, ElementOutput{0.5});

    return passed;
  }

  template<class ProblemShape>
  auto initialize_varlen(const ProblemShape& problem_size) {
    int num_batches = get<0>(problem_size);

    // generate Q as --b times
    //    gaussian (--Q, --Q / 2) sampled positive
    //    track cumulative 
    std::mt19937 rng(0x202305151552ull);
    std::normal_distribution<double> dist_q(get<3>(problem_size), get<3>(problem_size) / 2);
    std::normal_distribution<double> dist_kv(get<4>(problem_size), get<4>(problem_size) / 2);
    std::normal_distribution<double> dist_kv_cache(get<5>(problem_size), get<5>(problem_size) / 2);

    // Use Cacheline Size to calculate alignment
    constexpr int cacheline_bytes = 64;
    constexpr int AlignmentQ = cacheline_bytes / sizeof(ElementQ);    // Alignment of Q matrix in units of elements
    constexpr int AlignmentKV = cacheline_bytes / sizeof(ElementK);   // Alignment of Kand V matrix in units of elements

    auto generate_positive_int = [](auto& dist, auto& gen) {
      int result = 0;
      do {
        result = static_cast<int>(dist(gen));
      } while (result <= 0);
      return result;
    };

    cumulative_seqlen_q = {0};
    cumulative_seqlen_kv = {0};
    cumulative_seqlen_kv_cache = {0};

    int total_seqlen_q = 0;
    int total_seqlen_kv = 0;
    int total_seqlen_kv_cache = 0;
    int max_seqlen_q = 0;
    int max_seqlen_kv = 0;
    int max_seqlen_kv_cache = 0;

    for (int i = 0; i < num_batches; i++) {
      //seqlen_q is usually set to 1 for decode.
      int seqlen_q = cute::get<3>(problem_size) == 1 ? 1 : std::min(cute::get<3>(problem_size), cutlass::round_up(generate_positive_int(dist_q, rng), AlignmentQ));
      int seqlen_kv = cutlass::round_up(generate_positive_int(dist_kv, rng), AlignmentKV);
      int seqlen_kv_cache = cute::get<5>(problem_size) == 0 ? 0 : cutlass::round_up(generate_positive_int(dist_kv_cache, rng), AlignmentKV);

      total_seqlen_q += seqlen_q;
      total_seqlen_kv += seqlen_kv;
      total_seqlen_kv_cache += seqlen_kv_cache;

      max_seqlen_q = std::max(max_seqlen_q, seqlen_q);
      max_seqlen_kv = std::max(max_seqlen_kv, seqlen_kv);
      max_seqlen_kv_cache = std::max(max_seqlen_kv_cache, seqlen_kv_cache);

      cumulative_seqlen_q.push_back(cumulative_seqlen_q.back() + seqlen_q);
      cumulative_seqlen_kv.push_back(cumulative_seqlen_kv.back() + seqlen_kv);
      cumulative_seqlen_kv_cache.push_back(cumulative_seqlen_kv_cache.back() + seqlen_kv_cache);
    }

    ProblemShape problem_size_for_init = problem_size;
    get<0>(problem_size_for_init) = 1;
    get<3>(problem_size_for_init) = total_seqlen_q;
    get<4>(problem_size_for_init) = total_seqlen_kv;
    get<5>(problem_size_for_init) = total_seqlen_kv_cache;

    ProblemShapeType problem_size_for_launch;

    get<3>(problem_size_for_launch) = cutlass::fmha::collective::VariableLength{max_seqlen_q};
    get<4>(problem_size_for_launch) = cutlass::fmha::collective::VariableLength{max_seqlen_kv};
    get<5>(problem_size_for_launch) = cutlass::fmha::collective::VariableLength{max_seqlen_kv_cache};
    get<0>(problem_size_for_launch) = get<0>(problem_size);
    get<1>(problem_size_for_launch) = get<1>(problem_size);
    get<2>(problem_size_for_launch) = get<2>(problem_size);
    get<6>(problem_size_for_launch) = get<6>(problem_size);
    get<7>(problem_size_for_launch) = get<7>(problem_size);

    return cute::make_tuple(problem_size_for_init, problem_size_for_launch);
  }

  /// Initialize operands to be used in the Flash Attention
  ProblemShapeType initialize(const FMHADecodeOptions &options) {
    auto problem_shape_in =
        cute::make_tuple(options.batch, options.num_heads_q, options.num_heads_kv, options.seq_len_qo, options.seq_len_kv, options.seq_len_kv_cache, options.head_size_qk, options.head_size_vo);

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

    auto [batch, num_heads_q, num_heads_kv, seq_len_qo, seq_len_kv, seq_len_kv_cache, head_size_qk, head_size_vo] = problem_size;

    stride_Q = cutlass::make_cute_packed_stride(StrideQ{}, cute::make_shape(seq_len_qo, head_size_qk, batch * num_heads_q));
    stride_K = cutlass::make_cute_packed_stride(StrideK{}, cute::make_shape(seq_len_kv, head_size_qk, batch * num_heads_kv));
    stride_V = cutlass::make_cute_packed_stride(StrideV{}, cute::make_shape(head_size_vo, seq_len_kv, batch * num_heads_kv));
    stride_K_cache = cutlass::make_cute_packed_stride(StrideK{}, cute::make_shape(seq_len_kv_cache, head_size_qk, batch * num_heads_kv));
    stride_V_cache = cutlass::make_cute_packed_stride(StrideV{}, cute::make_shape(head_size_vo, seq_len_kv_cache, batch * num_heads_kv));
    stride_O = cutlass::make_cute_packed_stride(StrideO{}, cute::make_shape(seq_len_qo, head_size_vo, batch * num_heads_q));

    std::size_t mem_size_q = static_cast<std::size_t>(batch) * num_heads_q * seq_len_qo * head_size_qk;
    std::size_t mem_size_k = static_cast<std::size_t>(batch) * num_heads_kv * seq_len_kv * head_size_qk;
    std::size_t mem_size_v = static_cast<std::size_t>(batch) * num_heads_kv * seq_len_kv * head_size_vo;
    std::size_t mem_size_k_cache = static_cast<std::size_t>(batch) * num_heads_kv * seq_len_kv_cache * head_size_qk;
    std::size_t mem_size_v_cache = static_cast<std::size_t>(batch) * num_heads_kv * seq_len_kv_cache * head_size_vo;
    std::size_t mem_size_o = static_cast<std::size_t>(batch) * num_heads_q * seq_len_qo * head_size_vo;

    std::size_t mem_occupied_QKV = (mem_size_q * sizeof(ElementQ)) + ((mem_size_k + mem_size_k_cache) * sizeof(ElementK)) + 
                                   ((mem_size_v + mem_size_v_cache) * sizeof(ElementV));

    count = std::ceil(static_cast<float>(cutlass::get_llc_size()) / static_cast<float>(mem_occupied_QKV)) + 1;

    if (PagedKV) {
      paged_kv_cache.page_size = options.page_size;
      std::vector<int> num_pages_per_seq{0};
      int num_pages = 0;
      for(int b = 0; b < get<0>(problem_shape); b++) {
        int seq_len_cache = isVarLen ? cumulative_seqlen_kv_cache[b + 1] - cumulative_seqlen_kv_cache[b] : seq_len_kv_cache;
        int pages_per_seq = ceil_div(seq_len_cache, paged_kv_cache.page_size);
        num_pages_per_seq.push_back(num_pages_per_seq.back() + pages_per_seq);
        num_pages += pages_per_seq;
      }
      paged_kv_cache.page_table.reset(num_pages);

      // initialize block table with random mapping for non-contiguous layout
      std::vector<int> page_mapping(num_pages);
      for (int b = 0; b < get<0>(problem_shape); ++b) {
        std::vector<int> physical_pages(num_pages_per_seq[b + 1] - num_pages_per_seq[b]);
        std::iota(physical_pages.begin(), physical_pages.end(), 0);
        // shuffle physical pages
        std::shuffle(physical_pages.begin(), physical_pages.end(), std::mt19937{ std::random_device{}() });
        for (int blk = 0; blk < physical_pages.size(); ++blk) {
          int logical_idx = num_pages_per_seq[b] + blk;
          page_mapping[logical_idx] = physical_pages[blk];
        }
      }
      syclcompat::memcpy(paged_kv_cache.page_table.get(), page_mapping.data(), page_mapping.size() * sizeof(int));

      paged_kv_cache.num_pages_per_seq.reset(num_pages_per_seq.size());
      syclcompat::memcpy(paged_kv_cache.num_pages_per_seq.get(), num_pages_per_seq.data(), num_pages_per_seq.size() * sizeof(int));
      syclcompat::wait();
    }

    for(int i = 0; i < count; i++) {
      block_Q.emplace_back();
      block_K.emplace_back();
      block_V.emplace_back();
      block_K_cache.emplace_back();
      block_V_cache.emplace_back();
    }

    
    for(int i = 0; i < count; i++) {
      block_Q[i].reset(mem_size_q);
      block_K[i].reset(mem_size_k);
      block_V[i].reset(mem_size_v);
      block_K_cache[i].reset(mem_size_k_cache);
      block_V_cache[i].reset(mem_size_v_cache);

      initialize_block(block_Q[i], seed + i);
      initialize_block(block_K[i], seed + i + 100);
      initialize_block(block_V[i], seed + i + 101);
      initialize_block(block_K_cache[i], seed + i + 102);
      initialize_block(block_V_cache[i], seed + i + 103);
    }

    block_O.reset(mem_size_o);
    block_ref_O.reset(mem_size_o);

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

    if (!cumulative_seqlen_kv_cache.empty()) {
      device_cumulative_seqlen_kv_cache.reset(cumulative_seqlen_kv_cache.size());
      device_cumulative_seqlen_kv_cache.copy_from_host(
        cumulative_seqlen_kv_cache.data(), cumulative_seqlen_kv_cache.size());
    }

    if constexpr (isVarLen) {
      get<3>(problem_shape).cumulative_length = device_cumulative_seqlen_q.get();
      get<4>(problem_shape).cumulative_length = device_cumulative_seqlen_kv.get();
      get<5>(problem_shape).cumulative_length = device_cumulative_seqlen_kv_cache.get();
    }

    return problem_shape;
  }

  static void run(typename FMHADecodeKernel::Params params) {
    dim3 const block = FMHADecodeKernel::get_block_shape();
    dim3 const grid = FMHADecodeKernel::get_grid_shape(params);

    // configure smem size and carveout
    int smem_size = FMHADecodeKernel::SharedStorageSize;

    const auto sycl_block = syclcompat::dim3(block.x, block.y, block.z);
    const auto sycl_grid = syclcompat::dim3(grid.x, grid.y, grid.z);

#if !defined(SYCL_EXT_ONEAPI_WORK_GROUP_SCRATCH_MEMORY)
    using namespace syclcompat::experimental;
    auto event = launch<cutlass::device_kernel<FMHADecodeKernel>>(
        launch_policy{sycl_grid, sycl_block, local_mem_size{static_cast<std::size_t>(smem_size)},
                      kernel_properties{sycl_exp::sub_group_size<FMHADecodeKernel::DispatchPolicy::SubgroupSize>}},
        params);
#else
    syclcompat::experimental::launch_properties launch_props{
      sycl::ext::oneapi::experimental::work_group_scratch_size(smem_size)
    };
    syclcompat::experimental::kernel_properties kernel_props{
      sycl::ext::oneapi::experimental::sub_group_size<FMHADecodeKernel::DispatchPolicy::SubgroupSize>
    };
    syclcompat::experimental::launch_policy policy{sycl_grid, sycl_block, launch_props, kernel_props};
    auto event = syclcompat::experimental::launch<cutlass::device_kernel<FMHADecodeKernel>>(policy, params);
#endif

    EventManager::getInstance().addEvent(event);
  }

  void run(::benchmark::State& state, const FMHADecodeOptions &options, const cutlass::KernelHardwareInfo &hw_info) {

    ProblemShapeType problem_size = initialize(options);

    typename FMHADecodeKernel::Arguments arguments{
        cutlass::gemm::GemmUniversalMode::kGemm,
        problem_size,
        {block_Q[0].get(), stride_Q,
        block_K[0].get(), stride_K,
        block_V[0].get(), stride_V,
        block_K_cache[0].get(), stride_K_cache,
        block_V_cache[0].get(), stride_V_cache,
        PagedKV ? paged_kv_cache.page_table.get() : nullptr,
        PagedKV ? paged_kv_cache.page_size : 0,
        PagedKV ? paged_kv_cache.num_pages_per_seq.get() : nullptr},
        {options.softmax_scale},
        {block_O.get(), stride_O},
        hw_info};

    size_t workspace_size = FMHADecodeKernel::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

    FMHADecodeKernel::can_implement(arguments);

    // Initialize the workspace
    auto status = FMHADecodeKernel::initialize_workspace(arguments, workspace.get());
    if (status != cutlass::Status::kSuccess) {
      return;
    }

    typename FMHADecodeKernel::Params params = FMHADecodeKernel::to_underlying_arguments(arguments, workspace.get());

    // Run the GEMM
    run(params);

    syclcompat::wait();

    // Verify that the result is correct
    bool passed = verify(problem_size);
    if(not passed) {
      state.SkipWithError("Disposition Failed.");
    }

    state.counters["batch"] = options.batch;
    state.counters["num_heads_q"] = options.num_heads_q;
    state.counters["num_heads_kv"] = options.num_heads_kv;
    state.counters["seq_len_qo"] = options.seq_len_qo;
    state.counters["seq_len_kv"] = options.seq_len_kv;
    state.counters["seq_len_kv_cache"] = options.seq_len_kv_cache;
    state.counters["head_size_kv"] = options.head_size_qk;
    state.counters["head_size_vo"] = options.head_size_vo;
    state.counters["page_size"] = options.page_size;
    state.counters["scale"] = options.softmax_scale;
    state.counters["causal"] = Causal;
    state.counters["varlen"] = isVarLen;
    state.counters["paged_kv"] = PagedKV;

    std::stringstream extra_label;
    extra_label << "layoutQ=RowMajor ";
    extra_label << "layoutK=ColumnMajor ";
    extra_label << "layoutV=RowMajor ";

    state.SetLabel(extra_label.str());
    // when seq_len_qo is not equal to seq_len_kv we use bottom up approach for the masking. 
    // Following changes will adjust the effective_seq_len_kv when masking applied for such cases.
    auto offset = cute::min(options.seq_len_qo, options.seq_len_kv);
    auto discard_seq_coord = options.seq_len_qo - offset;
    auto full_tile_offset = options.seq_len_kv - offset;
    auto effective_seq_len_kv = Causal ? full_tile_offset + ((offset + 1) / 2.0): options.seq_len_kv;
    auto effective_seq_len_qo = Causal ? options.seq_len_qo - discard_seq_coord  : options.seq_len_qo;
   
    double flops_qk = 2.0 * options.batch * options.num_heads_q * effective_seq_len_qo * effective_seq_len_kv * options.head_size_qk;
    double flops_pv = 2.0 * options.batch * options.num_heads_q * effective_seq_len_qo * options.head_size_vo * effective_seq_len_kv;
    double gflops = (flops_qk + flops_pv) * 1e-9;
    double gbps_qk =  options.batch * (sizeof(ElementQ) * options.num_heads_q * effective_seq_len_qo * options.head_size_qk + 
                      sizeof(ElementK) * options.num_heads_kv * effective_seq_len_kv * options.head_size_qk);    
    double gbps_pv = sizeof(ElementV) * options.batch * options.num_heads_kv * effective_seq_len_kv * options.head_size_vo +
                     sizeof(ElementOutput) * options.batch * options.num_heads_q * effective_seq_len_qo * options.head_size_vo;
    double mega_bytes_transferred = (gbps_qk + gbps_pv) * (1e-6);

    initialize_counters(state);
    int32_t counter = 1;
    for(auto _ : state) {
      state.PauseTiming();
      int input_num = std::max(int(0), counter % count);

      typename FMHADecodeKernel::Arguments arguments{
        cutlass::gemm::GemmUniversalMode::kGemm,
        problem_size,
        {block_Q[input_num].get(), stride_Q,
        block_K[input_num].get(), stride_K,
        block_V[input_num].get(), stride_V,
        block_K_cache[input_num].get(), stride_K_cache,
        block_V_cache[input_num].get(), stride_V_cache,
        PagedKV ? paged_kv_cache.page_table.get() : nullptr,
        PagedKV ? paged_kv_cache.page_size : 0,
        PagedKV ? paged_kv_cache.num_pages_per_seq.get() : nullptr},
        {options.softmax_scale},
        {block_O.get(), stride_O},
        hw_info};

      size_t workspace_size = FMHADecodeKernel::get_workspace_size(arguments);
      cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

      FMHADecodeKernel::can_implement(arguments);

      // Initialize the workspace
      auto status = FMHADecodeKernel::initialize_workspace(arguments, workspace.get());
      if (status != cutlass::Status::kSuccess) {
        return;
      }

      typename FMHADecodeKernel::Params params = FMHADecodeKernel::to_underlying_arguments(arguments, workspace.get());

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

#define CUTLASS_FMHA_DECODE_BENCHMARK(F) cutlass::benchmark::BenchmarkRegistry<cutlass::benchmark::FMHADecodeOptions>::Register(#F, &F##_func)

#define CUTLASS_CREATE_FMHA_DECODE_BENCHMARK(F)                          \
  static void F##_func(                                           \
      ::benchmark::State& state,                                  \
      cutlass::benchmark::FMHADecodeOptions const& options,                 \
      cutlass::KernelHardwareInfo const& hw_info) {               \
    auto bench = cutlass::benchmark::BenchmarkRunnerFMHADecode<F>();    \
    bench.run(state, options, hw_info);                           \
  }
