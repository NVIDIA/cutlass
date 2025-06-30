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
#include "flash_attention_v2/collective/fmha_fusion.hpp"
#include "flash_attention_v2/kernel/tile_scheduler_cachedKV.hpp"
#include "cutlass/util/packed_stride.hpp"
#include "flash_attention_v2/kernel/xe_flash_attn_prefill_cachedKV.hpp"
#include "flash_attention_v2/collective/xe_flash_attn_prefill_epilogue_cachedKV.hpp"
#include "flash_attention_v2/collective/xe_flash_attn_prefill_softmax_epilogue.hpp"
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
  bool use_paged_kv = false;
  std::string scheduler;

  int batch, num_heads_q, num_heads_kv, seq_len_qo, seq_len_kv, seq_len_kv_cache, page_size, head_size_qk, head_size_vo, iterations;
  float softmax_scale;

  Options()
      : help(false), error(false), is_causal(false), varlen(false), use_paged_kv(false), batch(32), num_heads_q(16), num_heads_kv(16), seq_len_qo(512), head_size_qk(128),
        seq_len_kv(512), seq_len_kv_cache(512), page_size(128), head_size_vo(128), iterations(100), softmax_scale(1.f), scheduler("Individual") {}

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
    cmd.get_cmd_line_argument("num_heads_q", num_heads_q, 16);
    cmd.get_cmd_line_argument("num_heads_kv", num_heads_kv, num_heads_q);
    cmd.get_cmd_line_argument("seq_len_qo", seq_len_qo, 512);
    cmd.get_cmd_line_argument("seq_len_kv", seq_len_kv, seq_len_qo);
    cmd.get_cmd_line_argument("seq_len_kv_cache", seq_len_kv_cache, 512);
    cmd.get_cmd_line_argument("head_size_vo", head_size_vo, HEAD_DIM);
    cmd.get_cmd_line_argument("head_size_qk", head_size_qk, head_size_vo);
    cmd.get_cmd_line_argument("iterations", iterations, 100);

    if (cmd.check_cmd_line_flag("use_paged_kv")) {
        use_paged_kv = true;
        cmd.get_cmd_line_argument("page_size", page_size, 128);

        if (page_size % 128 != 0) {
            std::cerr << "Invalid: page_size must be a multiple of 128" << std::endl;
            return;
        }
        if (seq_len_kv_cache % page_size != 0) {
            std::cerr << "Invalid: seq_len_kv_cache must be divisible by page_size" << std::endl;
            return;
        }
    }

    softmax_scale = 1 / sqrt(static_cast<float>(head_size_qk));
  }

  /// Prints the usage statement.
  std::ostream &print_usage(std::ostream &out) const {

    out << "BMG Flash Attention v2 Example\n\n"
        << "Options:\n\n"
        << "  --help                      If specified, displays this usage statement\n\n"
        << "  --is_causal                 Apply Causal Mask to the output of first Matmul\n"
        << "  --varlen                    Enable variable sequence length\n"
        << "  --scheduler=\"Value\"       Choose between Individual or Persistent Scheduler\n"
        << "  --batch=<int>               Sets the Batch Size of the Multi-Head Self Attention module\n"
        << "  --num_heads_q=<int>         Sets the Number of Attention Heads for Key-Value pair the Multi-Head Self Attention module\n"
        << "  --num_heads_kv=<int>        Sets the Number of Attention Heads for Query input in the Multi-Head Self Attention module\n"
        << "  --seq_len_qo=<int>          Sets the Sequence length of the Query input in Multi-Head Self Attention module\n"
        << "  --seq_len_kv=<int>          Sets the Sequence length of the Key-Value pair in Multi-Head Self Attention module\n"
        << "  --seq_len_kv_cache=<int>    Sets the Sequence length of the cached Key-Value pair in Multi-Head Self Attention module\n"
        << "  --use_paged_kv              Use paged (non-contiguous) KV cache. Default is contiguous KV Cache\n"
        << "  --page_size=<int>           Block size for paged KV cache. Default is 128\n"
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

template <class FMHAPrefillCachedKernel, bool isVarLen> struct ExampleRunner {

  using StrideQ = typename FMHAPrefillCachedKernel::StrideQ;
  using StrideK = typename FMHAPrefillCachedKernel::StrideK;
  using StrideV = typename FMHAPrefillCachedKernel::StrideV;
  using StrideO = typename FMHAPrefillCachedKernel::StrideO;

  using ElementQ = typename FMHAPrefillCachedKernel::ElementQ;
  using ElementK = typename FMHAPrefillCachedKernel::ElementK;
  using ElementV = typename FMHAPrefillCachedKernel::ElementV;
  using ElementAcc = typename FMHAPrefillCachedKernel::ElementAccumulator;

  using CollectiveEpilogue = typename FMHAPrefillCachedKernel::CollectiveEpilogue;
  using ElementOutput = typename CollectiveEpilogue::ElementOutput;
  using ElementCompute = typename CollectiveEpilogue::ElementCompute;
  using ElementAccumulator = typename CollectiveEpilogue::ElementAccumulator;

  using ProblemShapeType = typename FMHAPrefillCachedKernel::ProblemShape;

  //
  // Data members
  //

  /// Initialization
  StrideQ stride_Q;
  StrideK stride_K;
  StrideV stride_V;
  StrideK stride_K_cache;
  StrideV stride_V_cache;
  StrideO stride_O;
  uint64_t seed = 0;

  cutlass::DeviceAllocation<ElementQ> block_Q;
  cutlass::DeviceAllocation<ElementK> block_K;
  cutlass::DeviceAllocation<ElementV> block_V;
  cutlass::DeviceAllocation<ElementK> block_K_cache;
  cutlass::DeviceAllocation<ElementV> block_V_cache;
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

  bool verify(ProblemShapeType problem_size, bool is_causal, bool use_kv_cache) {
    
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
    int q_group_size = num_heads_q/num_heads_kv;
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

        if (use_kv_cache) {
          cutlass::DeviceAllocation<ElementK> block_K_concat(head_size_qk * seq_len_kv_total);
          cutlass::DeviceAllocation<ElementV> block_V_concat(seq_len_kv_total * head_size_vo);

          // Concatenate K_cache and K
          syclcompat::memcpy<ElementK>(
              block_K_concat.get(),
              block_K_cache.get() + offset_k_cache,
              seq_len_kv_cache * head_size_qk
          );
          syclcompat::memcpy<ElementK>(
              block_K_concat.get() + seq_len_kv_cache * head_size_qk,
              block_K.get() + offset_k,
              seq_len_kv * head_size_qk
          );

          // Concatenate V_cache and V
          syclcompat::memcpy<ElementV>(
              block_V_concat.get(),
              block_V_cache.get() + offset_v_cache,
              seq_len_kv_cache * head_size_vo
          );
          syclcompat::memcpy<ElementV>(
              block_V_concat.get() + seq_len_kv_cache * head_size_vo,
              block_V.get() + offset_v,
              seq_len_kv * head_size_vo
          );

          k_ptr = block_K_concat.get();
          v_ptr = block_V_concat.get();
        } else {
          k_ptr = block_K.get() + offset_k;
          v_ptr = block_V.get() + offset_v;
        }

        cutlass::TensorRef ref_Q(block_Q.get() + offset_q, LayoutQ::packed({seq_len_qo, head_size_qk}));
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

        // delete this memory as it is no longer needed
        block_S.reset();
        auto offset = cute::min(seq_len_qo, seq_len_kv);
        auto discard_seq_coord = seq_len_qo - offset;
        auto full_tile_offset = seq_len_kv - offset;
        int start_col = use_kv_cache ? seq_len_kv_cache : 0;
        if (is_causal) {
          // apply mask to S
          for (int row = 0; row < seq_len_qo; row++) {
            for (int col = start_col; col < seq_len_kv_total; col++) {
              if (col - full_tile_offset > row + start_col - discard_seq_coord)
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
            if(is_causal && row < discard_seq_coord) {
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

        // delete this memory as it is no longer needed
        block_acc.reset();
        std::vector<ElementOutput> vec_out(vec_acc.size());
        for(int i = 0; i < vec_out.size(); i++) {
          vec_out[i] = static_cast<ElementOutput>(vec_acc[i]);
        }
        syclcompat::memcpy<ElementOutput>(block_ref_O.get() + offset_o, vec_out.data(), vec_out.size());

        offset_q += seq_len_qo * head_size_qk;
        if(kv_group_update % q_group_size==0) {
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
    int seq_len_kv_cache = get<5>(problem_size);

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
      int seqlen_q = cutlass::round_up(generate_positive_int(dist_q, rng), AlignmentQ);
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
    get<6>(problem_size_for_launch) = get<6>(problem_size);
    get<7>(problem_size_for_launch) = get<7>(problem_size);
    get<0>(problem_size_for_launch) = get<0>(problem_size);
    get<1>(problem_size_for_launch) = get<1>(problem_size);
    get<2>(problem_size_for_launch) = get<2>(problem_size);


    return cute::make_tuple(problem_size_for_init, problem_size_for_launch);
  }

  /// Initialize operands to be used in the GEMM and reference GEMM
  ProblemShapeType initialize(const Options &options) {
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

    block_Q.reset(batch * num_heads_q * seq_len_qo * head_size_qk);
    block_K.reset(batch * num_heads_kv * seq_len_kv * head_size_qk);
    block_V.reset(batch * num_heads_kv * seq_len_kv * head_size_vo);
    block_K_cache.reset(batch * num_heads_kv * seq_len_kv_cache * head_size_qk);
    block_V_cache.reset(batch * num_heads_kv * seq_len_kv_cache * head_size_vo);
    block_O.reset(batch * num_heads_q * seq_len_qo * head_size_vo);
    block_ref_O.reset(batch * num_heads_q * seq_len_qo * head_size_vo);

    if (options.use_paged_kv) {
      paged_kv_cache.page_size = options.page_size;
      std::vector<int> num_pages_per_seq{0};
      int num_pages = 0;
      for(int b = 0; b < cute::get<0>(problem_shape); b++) {
        int seq_len_cache = isVarLen ? cumulative_seqlen_kv_cache[b + 1] - cumulative_seqlen_kv_cache[b] : seq_len_kv_cache;
        int pages_per_seq = ceil_div(seq_len_cache, paged_kv_cache.page_size);
        num_pages_per_seq.push_back(num_pages_per_seq.back() + pages_per_seq);
        num_pages += pages_per_seq;
      }
      paged_kv_cache.page_table.reset(num_pages);

      // initialize block table with random mapping for non-contiguous layout
      std::vector<int> page_mapping(num_pages);
      for (int b = 0; b < cute::get<0>(problem_shape); ++b) {
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
    }

    initialize_block(block_Q, seed + 2023);
    initialize_block(block_K, seed + 2022);
    initialize_block(block_V, seed + 2021);
    initialize_block(block_K_cache, seed + 2024);
    initialize_block(block_V_cache, seed + 2025);

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

  // Note that the GemmUniversalAdapter currently doesn't support flash attention, which is why this
  // secondary `run` function is required to launch the kernel.
  static void run(typename FMHAPrefillCachedKernel::Params params) {
    dim3 const block = FMHAPrefillCachedKernel::get_block_shape();
    dim3 const grid = FMHAPrefillCachedKernel::get_grid_shape(params);

    // configure smem size and carveout
    int smem_size = FMHAPrefillCachedKernel::SharedStorageSize;

    const auto sycl_block = syclcompat::dim3(block.x, block.y, block.z);
    const auto sycl_grid = syclcompat::dim3(grid.x, grid.y, grid.z);

// Launch parameters depend on whether SYCL compiler supports work-group scratch memory extension
#if !defined(SYCL_EXT_ONEAPI_WORK_GROUP_SCRATCH_MEMORY)
    using namespace syclcompat::experimental;
    auto event = launch<cutlass::device_kernel<FMHAPrefillCachedKernel>>(
        launch_policy{sycl_grid, sycl_block, local_mem_size{static_cast<std::size_t>(smem_size)},
                      kernel_properties{sycl_exp::sub_group_size<FMHAPrefillCachedKernel::DispatchPolicy::SubgroupSize>}},
        params);
#else
    syclcompat::experimental::launch_properties launch_props {
      sycl::ext::oneapi::experimental::work_group_scratch_size(smem_size),
    };
    syclcompat::experimental::kernel_properties kernel_props{
      sycl::ext::oneapi::experimental::sub_group_size<FMHAPrefillCachedKernel::DispatchPolicy::SubgroupSize>
    };
    syclcompat::experimental::launch_policy policy{sycl_grid, sycl_block, launch_props, kernel_props};
    auto event = syclcompat::experimental::launch<cutlass::device_kernel<FMHAPrefillCachedKernel>>(policy, params);
#endif

    EventManager::getInstance().addEvent(event);
  }

  cutlass::Status run(const Options &options, const cutlass::KernelHardwareInfo &hw_info) {

    ProblemShapeType problem_size = initialize(options);

    typename FMHAPrefillCachedKernel::Arguments arguments{
        cutlass::gemm::GemmUniversalMode::kGemm,
        problem_size,
        {block_Q.get(), stride_Q,
        block_K.get(), stride_K,
        block_V.get(), stride_V,
        block_K_cache.get(), stride_K_cache,
        block_V_cache.get(), stride_V_cache,
        options.use_paged_kv ? paged_kv_cache.page_table.get() : nullptr,
        options.use_paged_kv ? paged_kv_cache.page_size : 0,
        options.use_paged_kv ? paged_kv_cache.num_pages_per_seq.get() : nullptr},
        {options.softmax_scale},
        {block_O.get(), stride_O},
        hw_info};

    // Define device-global scratch memory
    size_t workspace_size = FMHAPrefillCachedKernel::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

    if (!FMHAPrefillCachedKernel::can_implement(arguments)) {
      std::cout << "Invalid Problem Size: " << options.batch << 'x' << options.num_heads_q << 'x' <<
        options.seq_len_qo << 'x' << options.seq_len_kv << 'x' << options.head_size_qk << 'x'  << options.head_size_vo 
        << (options.is_causal ? "xCausal" : "xNonCausal") << std::endl;
      return cutlass::Status::kErrorInvalidProblem;
    }

    // Initialize the workspace
    CUTLASS_CHECK(FMHAPrefillCachedKernel::initialize_workspace(arguments, workspace.get()));

    // Convert host-side arguments to device-side arguments to be passed to the kernel
    auto params = FMHAPrefillCachedKernel::to_underlying_arguments(arguments, workspace.get());

    // Run the Flash Attention implementation.
    run(params);

    syclcompat::wait();

    // Verify that the result is correct
    bool use_kv_cache = options.seq_len_kv_cache > 0;
    bool passed = verify(problem_size, options.is_causal, use_kv_cache);
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
 
      auto offset = cute::min(options.seq_len_qo, options.seq_len_kv);
      auto discard_seq_coord = options.seq_len_qo - offset;
      auto full_tile_offset = options.seq_len_kv - offset;
      // offset + 1 is going to be ceil_div
      auto effective_seq_len_kv = options.seq_len_kv_cache + (options.is_causal ? full_tile_offset + ((offset + 1) / 2.0): options.seq_len_kv);
      auto effective_seq_len_qo = options.is_causal ? options.seq_len_qo - discard_seq_coord : options.seq_len_qo;
      double cute_time = timer.seconds() / options.iterations;
      double flops_qk = 2.0 * options.batch * options.num_heads_q * effective_seq_len_qo * effective_seq_len_kv * options.head_size_qk;
      double flops_pv = 2.0 *  options.batch * options.num_heads_q * effective_seq_len_qo * options.head_size_vo * effective_seq_len_kv;
      double tflops = ((flops_qk + flops_pv) * 1e-12) / cute_time;
      double gbps_qk =  options.batch * (sizeof(ElementQ) * options.num_heads_q * effective_seq_len_qo * options.head_size_qk + 
                                         sizeof(ElementK) * options.num_heads_kv * effective_seq_len_kv * options.head_size_qk);
      double gbps_pv = sizeof(ElementV) * options.batch * options.num_heads_kv * effective_seq_len_kv * options.head_size_vo +
                       sizeof(ElementOutput) * options.batch * options.num_heads_q * effective_seq_len_qo * options.head_size_vo;
      double gbps = ((gbps_qk + gbps_pv)  * 1e-9) / (cute_time);
      std::cout << "Batch: " << options.batch << "\tNumHeads_q: " << options.num_heads_q << "\tNumHeads_kv: " << options.num_heads_kv << "\tSeq Length QO: " << options.seq_len_qo
          << "\tSeq Length KV: " << options.seq_len_kv << "\tSeq Length KV Cache: " << options.seq_len_kv_cache 
          << "\tHead Size QK: " << options.head_size_qk << "\tHead Size VO: " << options.head_size_vo
          << "\tCausal Mask: " << (options.is_causal ? "true" : "false") << "\tVariable Sequence Length: " << (options.varlen ? "true" : "false")
          << "\t Scheduler: " << options.scheduler << "\t Paged KV cache: " << (options.use_paged_kv ? "true" : "false");
      printf("\nPerformance:   %4.3f  GB/s,    %4.3f  TFlop/s,   %6.4f  ms\n\n", gbps, tflops, cute_time * 1000);
    }

    return cutlass::Status::kSuccess;
  }
};

// the default value used for the case BF16
template <bool Causal, 
          typename TileShapeQK, 
          typename TileShapePV, 
          typename TileShapeOutput, 
          typename SubgroupLayout, 
          int PipelineStages,
          typename ElementInputQ = bfloat16_t, 
          typename ElementInputKV = bfloat16_t, 
          typename MMAOperation = XE_8x16x16_F32BF16BF16F32_TT,
          typename GmemTiledCopyQ = XE_2D_U16x8x32_LD_N,
          typename GmemTiledCopyK = XE_2D_U16x16x16_LD_T, // _T designates a transposed block load operation
          typename GmemTiledCopyV = XE_2D_U16x16x32_LD_V,
          typename ElementAccumulator = float,
          typename ElementComputeEpilogue = float,
          typename ElementOutput = float,
          typename GmemTiledCopyStore = XE_2D_U32x8x16_ST_N> struct FMHAConfig {

  template <bool isVarLen, bool PagedKV, class Scheduler>
  static int run(const Options &options) {
    //
    // Run examples
    //

    // The KernelHardwareInfo struct holds the number of EUs on the GPU with a given device ID. This
    // information is used by the underlying kernel.
    cutlass::KernelHardwareInfo hw_info;

    using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16<PipelineStages>;
    using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;
    using CollectiveEpilogue = cutlass::flash_attention::collective::FlashPrefillCachedEpilogue<
        EpilogueDispatchPolicy, MMAOperation, TileShapeOutput, SubgroupLayout, ElementComputeEpilogue, ElementOutput, cutlass::gemm::TagToStrideC_t<LayoutO>, ElementOutput,
        GmemTiledCopyStore>;
    using CollectiveSoftmaxEpilogue = cutlass::flash_attention::collective::FlashPrefillSoftmaxEpilogue<Causal, EpilogueDispatchPolicy, ElementAccumulator>;

    using ProblemShapeRegular = cute::tuple<int, int, int, int, int, int, int, int>;
    using namespace cutlass::fmha::collective;
    using ProblemShapeVarlen = cute::tuple<int, int, int, VariableLength, VariableLength, VariableLength, int, int>;
    using ProblemShapeType = std::conditional_t<isVarLen, ProblemShapeVarlen, ProblemShapeRegular>;

    // Mainloop
    using CollectiveMainloop = cutlass::flash_attention::collective::FlashPrefillCachedMma<
        GEMMDispatchPolicy, ProblemShapeType, ElementInputQ, cutlass::gemm::TagToStrideA_t<LayoutQ>, ElementInputKV,
        cutlass::gemm::TagToStrideB_t<LayoutK>, ElementInputKV, cutlass::gemm::TagToStrideB_t<LayoutV>, MMAOperation, TileShapeQK, TileShapePV, SubgroupLayout,
        GmemTiledCopyQ, // Q
        GmemTiledCopyK, // K
        GmemTiledCopyV, // V,
        Causal,
        PagedKV>;

    using FMHAPrefillCachedKernel = cutlass::flash_attention::kernel::FMHAPrefillCached<ProblemShapeType, CollectiveMainloop,
                                                                     CollectiveSoftmaxEpilogue, CollectiveEpilogue, Scheduler>;

    ExampleRunner<FMHAPrefillCachedKernel, isVarLen> runner;

    CUTLASS_CHECK(runner.run(options, hw_info));
    return 0;    
  }

  static int run(const Options &options) {
    if (options.use_paged_kv && !options.varlen) {
      return run<false, true, cutlass::flash_attention::IndividualScheduler>(options);
    } else if(!options.use_paged_kv && options.varlen) {
      return run<true, false, cutlass::flash_attention::IndividualScheduler>(options);
    } else if(!options.use_paged_kv && !options.varlen) {
      return run<false, false, cutlass::flash_attention::IndividualScheduler>(options);
    } else {
      return run<true, true, cutlass::flash_attention::IndividualScheduler>(options);
    }
  }
};
