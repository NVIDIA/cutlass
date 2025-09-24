/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
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
    \brief Tests for device-wide Flash Attention Prefill interface
*/

#pragma once

#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "flash_attention_v2/collective/fmha_fusion.hpp"
#include "flash_attention_v2/kernel/tile_scheduler.hpp"
#include "cutlass/util/packed_stride.hpp"
#include "flash_attention_v2/kernel/xe_flash_attn_prefill.hpp"
#include "flash_attention_v2/collective/xe_flash_attn_prefill_epilogue.hpp"
#include "flash_attention_v2/collective/xe_flash_attn_prefill_softmax_epilogue.hpp"
#include "cutlass/util/GPU_Clock.hpp"
#include "cutlass/util/sycl_event_manager.hpp"
#include "cutlass/util/initialize_block.hpp"

#include <cute/tensor.hpp>
#include <random>

#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/reference/device/sycl_tensor_fill.h"

#include "../gemm/device/testbed_utils.h"
#include "../common/cutlass_unit_test.h"

namespace test {
namespace flash_attention {

using namespace cute;

using MMAOperationBF16 = cute::XE_8x16x16_F32BF16BF16F32_TT;
using MMAOperationFP16 = cute::XE_8x16x16_F32F16F16F32_TT;

struct Shape_h64 {
  using ShapeQK = Shape<_128, _64, _64>;
  using ShapePV = Shape<_128, _32, _64>;
  using ShapeOutput = Shape<_128, _64, _64>;
  using SubgroupLayout = Layout<Shape<_8, _1, _1>, Stride<_1, _1, _1>>;
};

struct Shape_h96 {
  using ShapeQK = Shape<_128, _64, _32>;
  using ShapePV = Shape<_128, _32, _64>;
  using ShapeOutput = Shape<_128, _96, _64>;
  using SubgroupLayout = Layout<Shape<_8, _1, _1>, Stride<_1, _1, _1>>; 
};

struct Shape_h128 {
  using ShapeQK = Shape<_128, _64, _64>;
  using ShapePV = Shape<_128, _32, _64>;
  using ShapeOutput = Shape<_128, _128, _64>;
  using SubgroupLayout = Layout<Shape<_16, _1, _1>, Stride<_1, _1, _1>>;
};

struct Shape_h192 {
  using ShapeQK = Shape<_256, _64, _64>;
  using ShapePV = Shape<_256, _32, _64>;
  using ShapeOutput = Shape<_256, _192, _64>;
  using SubgroupLayout = Layout<Shape<_32, _1, _1>, Stride<_1, _1, _1>>; 
};

/////////////////////////////////////////////////////////////////////
  template <int input_bits, int output_bits> struct TiledCopyConfig;

  template <> struct TiledCopyConfig<8, 32> {
    using GmemTiledCopyQ = cute::XE_2D_U8x8x32_LD_N;
    using GmemTiledCopyK = cute::XE_2D_U8x16x16_LD_T;
    using GmemTiledCopyV = cute::XE_2D_U8x32x32_LD_V;
    using GmemTiledCopyO = cute::XE_2D_U32x8x16_ST_N;
  };

  template <> struct TiledCopyConfig<8, 8> {
    using GmemTiledCopyQ = cute::XE_2D_U8x8x32_LD_N;
    using GmemTiledCopyK = cute::XE_2D_U8x16x16_LD_T;
    using GmemTiledCopyV = cute::XE_2D_U8x32x32_LD_V;
    using GmemTiledCopyO = cute::XE_2D_U8x8x16_ST_N;
  };

  template <> struct TiledCopyConfig<16, 32> {
    using GmemTiledCopyQ = cute::XE_2D_U16x8x32_LD_N;
    using GmemTiledCopyK = cute::XE_2D_U16x16x16_LD_T;
    using GmemTiledCopyV = cute::XE_2D_U16x16x32_LD_V;
    using GmemTiledCopyO = cute::XE_2D_U32x8x16_ST_N;
  };

  template <> struct TiledCopyConfig<16, 16> {
    using GmemTiledCopyQ = cute::XE_2D_U16x8x32_LD_N;
    using GmemTiledCopyK = cute::XE_2D_U16x16x16_LD_T;
    using GmemTiledCopyV = cute::XE_2D_U16x16x32_LD_V;
    using GmemTiledCopyO = cute::XE_2D_U16x8x16_ST_N;
  };
  
  template <class, class> class convert_fp8_to_fp16_name;

  template <typename SrcT, typename DstT>
  void convert_fp8_to_fp16(const SrcT* d_src, DstT* d_dst, size_t size) {
    compat::get_default_queue().parallel_for<convert_fp8_to_fp16_name<SrcT, DstT>>(size, [=](auto indx) {
      d_dst[indx] = static_cast<DstT>(d_src[indx]);
    }).wait();
  }


/////////////////////////////////////////////////////////////////////

template<typename ElementInputType, typename ElementAccumulatorType, typename ElementOutputType,  
        typename TileShapeQK, typename TileShapePV, typename TileShapeOutput, typename SubgroupLayout, 
        typename MMAOperation, bool HasCausalMask, bool isVarLen, int PipelineStages>
struct XE_Flash_Attention_Prefill {
  using LayoutQ = cutlass::layout::RowMajor;
  using LayoutK = cutlass::layout::ColumnMajor;
  using LayoutV = cutlass::layout::RowMajor;
  using LayoutO = cutlass::layout::RowMajor;

  using ElementAccumulator = ElementAccumulatorType;
  using ElementComputeEpilogue = ElementAccumulatorType;
  using ElementInputQ = ElementInputType;
  using ElementInputKV = ElementInputType;
  using ElementOutput = ElementOutputType;

  using ProblemShapeRegular = cute::tuple<int, int, int, int, int, int, int>;
  using ProblemShapeVarlen = cute::tuple<int, int, int, cutlass::fmha::collective::VariableLength,
                                         cutlass::fmha::collective::VariableLength, int, int>;
  using ProblemShapeType = std::conditional_t<isVarLen, ProblemShapeVarlen, ProblemShapeRegular>;

  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;

  using GmemTiledCopyQ = typename TiledCopyConfig<cute::sizeof_bits_v<ElementInputQ>, cute::sizeof_bits_v<ElementOutput>>::GmemTiledCopyQ;
  using GmemTiledCopyK = typename TiledCopyConfig<cute::sizeof_bits_v<ElementInputKV>, cute::sizeof_bits_v<ElementOutput>>::GmemTiledCopyK;
  using GmemTiledCopyV = typename TiledCopyConfig<cute::sizeof_bits_v<ElementInputKV>, cute::sizeof_bits_v<ElementOutput>>::GmemTiledCopyV;
  using GmemTiledCopyStore = typename TiledCopyConfig<cute::sizeof_bits_v<ElementInputQ>, cute::sizeof_bits_v<ElementOutput>>::GmemTiledCopyO;
  using CollectiveEpilogue = cutlass::flash_attention::collective::FlashPrefillEpilogue<
        EpilogueDispatchPolicy, MMAOperation, TileShapeOutput, SubgroupLayout, ElementAccumulator, ElementOutput, cutlass::gemm::TagToStrideC_t<LayoutO>, ElementOutput,
        GmemTiledCopyStore>;
  using CollectiveSoftmaxEpilogue = cutlass::flash_attention::collective::FlashPrefillSoftmaxEpilogue<
        HasCausalMask, EpilogueDispatchPolicy, ElementAccumulator>;

  // Mainloop
  using CollectiveMainloop = cutlass::flash_attention::collective::FlashPrefillMma<
        GEMMDispatchPolicy, ProblemShapeType, ElementInputQ,
        cutlass::gemm::TagToStrideA_t<LayoutQ>, ElementInputKV,
        cutlass::gemm::TagToStrideB_t<LayoutK>, ElementInputKV,
        cutlass::gemm::TagToStrideB_t<LayoutV>,
        MMAOperation, TileShapeQK, TileShapePV, SubgroupLayout,
        GmemTiledCopyQ, // Q
        GmemTiledCopyK, // K
        GmemTiledCopyV, // V,
        HasCausalMask>;

  using Kernel = cutlass::flash_attention::kernel::FMHAPrefill<ProblemShapeType, CollectiveMainloop,
                                                      CollectiveSoftmaxEpilogue, CollectiveEpilogue>;
};
/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

template <typename FlashAttention>
struct TestbedImpl {
  using LayoutQ = cutlass::layout::RowMajor;
  using LayoutK = cutlass::layout::ColumnMajor;
  using LayoutV = cutlass::layout::RowMajor;
  using LayoutO = cutlass::layout::RowMajor;

  using StrideQ = typename FlashAttention::StrideQ;
  using StrideK = typename FlashAttention::StrideK;
  using StrideV = typename FlashAttention::StrideV;
  using StrideO = typename FlashAttention::StrideO;

  using ElementQ = typename FlashAttention::ElementQ;
  using ElementK = typename FlashAttention::ElementK;
  using ElementV = typename FlashAttention::ElementV;
  using ElementAcc = typename FlashAttention::ElementAccumulator;

  using CollectiveMainloop = typename FlashAttention::CollectiveMainloop;
  using CollectiveEpilogue = typename FlashAttention::CollectiveEpilogue;
  using ElementOutput = typename CollectiveEpilogue::ElementOutput;
  using ElementCompute = typename CollectiveEpilogue::ElementCompute;
  using ElementAccumulator = typename CollectiveEpilogue::ElementAccumulator;

  using ProblemShapeType = typename FlashAttention::ProblemShape;
  static constexpr bool HasCausalMask = CollectiveMainloop::CausalMask;
  static constexpr bool isVarLen = CollectiveMainloop::is_var_len;

  StrideQ stride_Q;
  StrideK stride_K;
  StrideV stride_V;
  StrideO stride_O;
  uint64_t seed = 0;

  std::vector<int> cumulative_seqlen_q;
  std::vector<int> cumulative_seqlen_kv;
  cutlass::DeviceAllocation<int> device_cumulative_seqlen_q;
  cutlass::DeviceAllocation<int> device_cumulative_seqlen_kv;
  cutlass::DeviceAllocation<ElementQ> block_Q;
  cutlass::DeviceAllocation<ElementK> block_K;
  cutlass::DeviceAllocation<ElementV> block_V;
  cutlass::DeviceAllocation<ElementOutput> block_O;
  cutlass::DeviceAllocation<ElementOutput> block_ref_O;

  //
  // Methods
  //
  template <typename T>
  static constexpr bool is_fp8_v = cute::is_any_of_v<T, cute::float_e5m2_t, cute::float_e4m3_t>;

  template <typename Tin> inline auto in_memory(cutlass::DeviceAllocation<Tin>& in) {
    using outType = cute::conditional_t<is_fp8_v<Tin>, half_t, Tin>;
    if constexpr(is_fp8_v<Tin>) {
      cutlass::DeviceAllocation<outType> out(in.size());
      convert_fp8_to_fp16<Tin, outType>(in.get(), out.get(), in.size());
      return out;
    } else { 
      return in;
    };
  }

  /// Initializes data structures
  template <class ProblemShape>
  ProblemShapeType initialize(ProblemShape problem_shape_in) {
#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::initialize(problem_size)");
#endif
    ProblemShapeType problem_shape;
    ProblemShape problem_size;

    if constexpr (isVarLen) {
      auto [problem_shape_init, problem_shape_launch] = initialize_varlen(problem_shape_in);
      problem_shape = problem_shape_launch;
      problem_size = problem_shape_init;
    }
    else {
      problem_size = problem_shape_in;
      problem_shape = problem_shape_in;
    }

    auto [batch, num_heads_q, num_heads_kv, seq_len_qo, seq_len_kv, head_size_qk, head_size_vo] = problem_size;

    stride_Q = cutlass::make_cute_packed_stride(StrideQ{}, cute::make_shape(seq_len_qo, head_size_qk, batch * num_heads_q));
    stride_K = cutlass::make_cute_packed_stride(StrideK{}, cute::make_shape(seq_len_kv, head_size_qk, batch * num_heads_kv));
    stride_V = cutlass::make_cute_packed_stride(StrideV{}, cute::make_shape(head_size_vo, seq_len_kv, batch * num_heads_kv));
    stride_O = cutlass::make_cute_packed_stride(StrideO{}, cute::make_shape(seq_len_qo, head_size_vo, batch * num_heads_q));

    block_Q.reset(batch * num_heads_q * seq_len_qo * head_size_qk);
    block_K.reset(batch * num_heads_kv * seq_len_kv * head_size_qk);
    block_V.reset(batch * num_heads_kv * seq_len_kv * head_size_vo);
    block_O.reset(batch * num_heads_q * seq_len_qo * head_size_vo);
    block_ref_O.reset(batch * num_heads_q * seq_len_qo * head_size_vo);

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
      cute::get<3>(problem_shape).cumulative_length = device_cumulative_seqlen_q.get();
      cute::get<4>(problem_shape).cumulative_length = device_cumulative_seqlen_kv.get();
    }

    return problem_shape;
  }

  template<class ProblemShape>
  auto initialize_varlen(const ProblemShape& problem_size, const bool VarlenSame = true) {
    int num_batches = cute::get<0>(problem_size);

    // generate Q as --b times
    //    gaussian (--Q, --Q / 2) sampled positive
    //    track cumulative
    std::mt19937 rng(0x202305151552ull);
    std::normal_distribution<double> dist_q(cute::get<3>(problem_size), cute::get<3>(problem_size) / 2);
    std::normal_distribution<double> dist_kv(cute::get<4>(problem_size), cute::get<4>(problem_size) / 2);

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

    int total_seqlen_q = 0;
    int total_seqlen_kv = 0;
    int max_seqlen_q = 0;
    int max_seqlen_kv = 0;

    for (int i = 0; i < num_batches; i++) {
      int seqlen_q = cutlass::round_up(generate_positive_int(dist_q, rng), AlignmentQ);
      int seqlen_kv = cutlass::round_up(generate_positive_int(dist_kv, rng), AlignmentKV);

      total_seqlen_q += seqlen_q;
      total_seqlen_kv += seqlen_kv;

      max_seqlen_q = std::max(max_seqlen_q, seqlen_q);
      max_seqlen_kv = std::max(max_seqlen_kv, seqlen_kv);

      cumulative_seqlen_q.push_back(cumulative_seqlen_q.back() + seqlen_q);
      cumulative_seqlen_kv.push_back(cumulative_seqlen_kv.back() + seqlen_kv);
    }

    ProblemShape problem_size_for_init = problem_size;
    cute::get<0>(problem_size_for_init) = 1;
    cute::get<3>(problem_size_for_init) = total_seqlen_q;
    cute::get<4>(problem_size_for_init) = total_seqlen_kv;

    ProblemShapeType problem_size_for_launch;

    cute::get<3>(problem_size_for_launch) = cutlass::fmha::collective::VariableLength{max_seqlen_q};
    cute::get<4>(problem_size_for_launch) = cutlass::fmha::collective::VariableLength{max_seqlen_kv};
    cute::get<5>(problem_size_for_launch) = cute::get<5>(problem_size);
    cute::get<6>(problem_size_for_launch) = cute::get<6>(problem_size);
    cute::get<0>(problem_size_for_launch) = cute::get<0>(problem_size);
    cute::get<1>(problem_size_for_launch) = cute::get<1>(problem_size);
    cute::get<2>(problem_size_for_launch) = cute::get<2>(problem_size);


    return cute::make_tuple(problem_size_for_init, problem_size_for_launch);
  }

  /// Verifies the result
  bool verify(ProblemShapeType problem_size, float softmax_scale)
  {
    if constexpr (isVarLen) {
      int max_seq_len_q = static_cast<int>(cute::get<3>(problem_size));
      int max_seq_len_kv = static_cast<int>(cute::get<4>(problem_size));
      cute::get<3>(problem_size) = cutlass::fmha::collective::VariableLength{max_seq_len_q, cumulative_seqlen_q.data()};
      cute::get<4>(problem_size) = cutlass::fmha::collective::VariableLength{max_seq_len_kv, cumulative_seqlen_kv.data()};
    }

    auto [batch, num_heads_q, num_heads_kv, head_size_qk, head_size_vo] = cute::select<0,1,2,5,6>(problem_size);
    int seq_len_qo, seq_len_kv;

    auto block_Q_ = in_memory(block_Q);
    auto block_K_ = in_memory(block_K);
    auto block_V_ = in_memory(block_V);
    using ElementV_ = cute::conditional_t<is_fp8_v<ElementV>, half_t, ElementV>;

    int offset_q = 0;
    int offset_k = 0;
    int offset_v = 0;
    int offset_o = 0;
    // loop over the batch dimension to compute the output
    // to avoid the risk of running out of device memory
    int q_group_size = num_heads_q/num_heads_kv;
    for (int b = 0; b < batch; b++) {
      if constexpr (isVarLen) {
        auto logical_problem_shape = cutlass::fmha::collective::apply_variable_length(problem_size, b);
        seq_len_qo = cute::get<3>(logical_problem_shape);
        seq_len_kv = cute::get<4>(logical_problem_shape);
      } else {
        seq_len_qo = cute::get<3>(problem_size);
        seq_len_kv = cute::get<4>(problem_size);
      }
      int kv_group_update=1;
      for (int h = 0; h < num_heads_q; h++) {
        cutlass::DeviceAllocation<ElementAccumulator> block_S;
        block_S.reset(seq_len_qo * seq_len_kv);

        cutlass::TensorRef ref_Q(block_Q_.get() + offset_q, LayoutQ::packed({seq_len_qo, head_size_qk}));
        cutlass::TensorRef ref_K(block_K_.get() + offset_k, LayoutK::packed({head_size_qk, seq_len_kv}));
        cutlass::TensorRef ref_V(block_V_.get() + offset_v, LayoutV::packed({seq_len_kv, head_size_vo}));
        cutlass::TensorRef ref_S(block_S.get(), LayoutQ::packed({seq_len_qo, seq_len_kv}));

        cutlass::reference::device::GemmComplex({seq_len_qo, seq_len_kv, head_size_qk}, ElementAccumulator{1}, ref_Q,
                                                cutlass::ComplexTransform::kNone, ref_K, cutlass::ComplexTransform::kNone,
                                                ElementAccumulator{0}, ref_S, ref_S, ElementAccumulator{0},
                                                1,                   // batch_count
                                                seq_len_qo * head_size_qk, // batch_stride_Q
                                                seq_len_kv * head_size_qk, // batch_stride_K
                                                seq_len_qo * seq_len_kv,   // batch_stride_S
                                                seq_len_qo * seq_len_kv    // batch_stride_S
        );

        compat::wait();

        std::vector<ElementAccumulator> host_S(block_S.size());
        compat::memcpy<ElementAccumulator>(host_S.data(), block_S.get(), host_S.size());

        // delete this memory as it is no longer needed
        block_S.reset();
        auto offset = cute::min(seq_len_qo, seq_len_kv);
        auto discard_seq_coord = seq_len_qo - offset;
        auto full_tile_offset = seq_len_kv - offset;
        if (HasCausalMask) {
          // apply mask to S
          for (int row = 0; row < seq_len_qo; row++) {
            for (int col = 0; col < seq_len_kv; col++) {
              if ((col - full_tile_offset) > (row - discard_seq_coord))
                host_S[col + row * seq_len_kv] = ElementAccumulator{-INFINITY};
            }
          }
        }

        // compute max element per row of S
        std::vector<ElementAccumulator> max_vec(seq_len_qo, -INFINITY);
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
            host_S[idx] = expf((host_S[idx] - max_vec[max_idx]) / sqrt(static_cast<ElementAccumulator>((head_size_qk))));
          }
        }

        // compute sum per row of S
        std::vector<ElementAccumulator> sum_vec(seq_len_qo, ElementAccumulator{0});
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
            if(HasCausalMask && row < discard_seq_coord) {
              host_S[idx] = 0;
            } else {
              host_S[idx] /= sum_vec[sum_idx];
            }
          }
        }

        std::vector<ElementV_> host_P(host_S.size());
        for (int p = 0; p < host_P.size(); p++)
          host_P[p] = static_cast<ElementV_>(host_S[p]);

        cutlass::DeviceAllocation<ElementV_> block_P;
        block_P.reset(host_P.size());

        compat::memcpy<ElementV_>(block_P.get(), host_P.data(), host_P.size());

        cutlass::TensorRef ref_P(block_P.get(), LayoutQ::packed({seq_len_qo, seq_len_kv}));

        cutlass::DeviceAllocation<ElementAccumulator> block_acc;
        block_acc.reset(seq_len_qo * head_size_vo);
        cutlass::TensorRef ref_acc(block_acc.get(), LayoutO::packed({seq_len_qo, head_size_vo}));

        cutlass::reference::device::GemmComplex({seq_len_qo, head_size_vo, seq_len_kv}, ElementAccumulator{1}, ref_P,
                                                cutlass::ComplexTransform::kNone, ref_V, cutlass::ComplexTransform::kNone,
                                                ElementAccumulator{0}, ref_acc, ref_acc, ElementAccumulator{0},
                                                1,                   // batch_count
                                                seq_len_qo * seq_len_kv,   // batch_stride_P
                                                seq_len_kv * head_size_vo, // batch_stride_V
                                                seq_len_qo * head_size_vo, // batch_stride_O
                                                seq_len_qo * head_size_vo  // batch_stride_O
        );

        compat::wait();
        // delete this memory as it is no longer needed
        block_P.reset();

        std::vector<ElementAccumulator> vec_acc(block_acc.size());
        compat::memcpy<ElementAccumulator>(vec_acc.data(), block_acc.get(), vec_acc.size());

        // delete this memory as it is no longer needed
        block_acc.reset();
        std::vector<ElementOutput> vec_out(vec_acc.size());
        for(int i = 0; i < vec_out.size(); i++) {
          vec_out[i] = static_cast<ElementOutput>(vec_acc[i]);
        }
        compat::memcpy<ElementOutput>(block_ref_O.get() + offset_o, vec_out.data(), vec_out.size());

        offset_q += seq_len_qo * head_size_qk;
        if(kv_group_update % q_group_size==0) {
          offset_k += seq_len_kv * head_size_qk;
          offset_v += seq_len_kv * head_size_vo;
        }
        kv_group_update++;
        offset_o += seq_len_qo * head_size_vo;
      }
    }

    compat::wait();

    // Check if output from CUTLASS kernel and reference kernel are equal or not
    bool passed = cutlass::reference::device::BlockCompareRelativelyEqual(block_ref_O.get(), block_O.get(),
                                                                          block_O.size(), ElementOutput{0.5}, ElementOutput{0.5});
    return passed;
  }

  bool sufficient() {
    return true;
  }

  /// Executes one test
  template<class ProblemShape>
  bool run(ProblemShape problem_size_init, float softmax_scale)
  {
#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run"); 
#endif

    // Fail test if insufficient device
    if (!sufficient()) {
      CUTLASS_TRACE_HOST("TestbedImpl::run: Test failed due to insufficient device");
      std::cout << "Test failed due to insufficient device." << std::endl;
      return false;
    }
#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    else {
      CUTLASS_TRACE_HOST("TestbedImpl::run: sufficient() returned true");
    }
#endif

    ProblemShapeType problem_size = this->initialize(problem_size_init);

#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: this->initialize() returned true");
#endif

    //
    // Initialize the Flash attention operator
    //
    cutlass::KernelHardwareInfo hw_info;
    typename FlashAttention::Arguments arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      problem_size,
      {block_Q.get(), stride_Q, block_K.get(), stride_K, block_V.get(), stride_V},
      {softmax_scale},
      {block_O.get(), stride_O},
      hw_info};

#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: Calling FlashAttention::get_workspace_size");
#endif
    size_t workspace_size = FlashAttention::get_workspace_size(arguments);
#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: Allocating workspace of size " << workspace_size);
#endif
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: Calling FlashAttention::can_implement");
#endif
    auto can_implement = FlashAttention::can_implement(arguments);

    if (!can_implement) {
      std::cerr << "This test is not supported." << "\n";
    }

    //
    // Run Flash attention
    //

#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: Calling to_underlying_arguments");
#endif
    auto params = FlashAttention::to_underlying_arguments(arguments, workspace.get());

#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: Calling run");
#endif
    auto const block = FlashAttention::get_block_shape();
    auto const grid = FlashAttention::get_grid_shape(params);

    // configure smem size and carveout
    int smem_size = FlashAttention::SharedStorageSize;

    const auto sycl_block = compat::dim3(block.x, block.y, block.z);
    const auto sycl_grid = compat::dim3(grid.x, grid.y, grid.z);

#if !defined(SYCL_EXT_ONEAPI_WORK_GROUP_SCRATCH_MEMORY)
    using namespace compat::experimental;
    auto event = launch<cutlass::device_kernel<FlashAttention>>(
        launch_policy{sycl_grid, sycl_block, local_mem_size{static_cast<std::size_t>(smem_size)},
                      kernel_properties{sycl_exp::sub_group_size<FlashAttention::DispatchPolicy::SubgroupSize>}},
        params);
#else
    compat::experimental::launch_properties launch_props {
      sycl::ext::oneapi::experimental::work_group_scratch_size(smem_size),
    };
    compat::experimental::kernel_properties kernel_props{
      sycl::ext::oneapi::experimental::sub_group_size<FlashAttention::DispatchPolicy::SubgroupSize>
    };
    compat::experimental::launch_policy policy{sycl_grid, sycl_block, launch_props, kernel_props};
    auto event = compat::experimental::launch<cutlass::device_kernel<FlashAttention>, FlashAttention>(policy, params);
#endif
    EventManager::getInstance().addEvent(event);

    try {
      compat::wait_and_throw();
    } catch (std::exception const &e) {
      ADD_FAILURE() << "Error at Kernel Sync.";
      return false;
    }

    //
    // Verify
    //
#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: Calling this->verify");
#endif
    bool passed = this->verify(problem_size, softmax_scale);
    if (!passed) {
      CUTLASS_TRACE_HOST("TestbedImpl::run: this->verify FAILED");
      std::cout << "Error : Failed \n";
    }
#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    else {
      CUTLASS_TRACE_HOST("TestbedImpl::run: this->verify passed");
    }
#endif

#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: Reached end");
#endif
    return passed;
  }
};

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  typename FlashAttention
>
struct Testbed3x {
  // using TestBedImp = typename detail::TestbedImpl<FlashAttention>;
  // TestBedImp impl_;
  detail::TestbedImpl<FlashAttention> impl_;

  //
  // Methods
  //
  Testbed3x() : impl_() {}

  /// Executes one test
  template <class ProblemShape>
  bool run(
   ProblemShape problem_size,
   float softmax_scale
    )
  {
    return impl_.run(problem_size, softmax_scale);
  }
};

template <typename FlashAttention>
bool TestFlashPrefillAll(int head_size, std::string config="default") {
  Testbed3x<FlashAttention> testbed;

  std::vector<int> problem_size_batch;
  std::vector<int> problem_size_num_heads;
  std::vector<int> problem_size_seq_len;

  if(config == "llama3_70b"){
    problem_size_batch = {1, 2};
    problem_size_num_heads = {128};
    problem_size_seq_len = {512, 1024};
  }
  else{
    problem_size_batch = {8};
    problem_size_num_heads = {8};
    problem_size_seq_len = {512};
  }
  std::vector<float> problem_size_softmax_scale{ 1.f / sqrt(static_cast<float>(head_size)) };
  bool passed = true;

  for (int batch : problem_size_batch) {
    for (int num_heads : problem_size_num_heads) {
      for (int seq_len : problem_size_seq_len) {
        for (float softmax_scale : problem_size_softmax_scale) {
          auto num_heads_q = num_heads;
          auto num_heads_kv = num_heads;
          auto seq_len_qo = seq_len;
          auto seq_len_kv = seq_len;
          auto head_size_qk = head_size;
          auto head_size_vo = head_size;

          auto problem_size = cute::make_tuple(
            batch, num_heads_q, num_heads_kv, seq_len_qo, seq_len_kv, head_size_qk, head_size_vo);
          try {
            passed = testbed.run(problem_size, softmax_scale);
          }
          catch (std::exception const& e) {
            EXPECT_TRUE(false) << "TestAll: testbed.run {"
              << "batch: " << batch << ", num_heads_q: " << num_heads_q << ", num_heads_kv: " << num_heads_kv
              << ", seq_len_qo: " << seq_len_qo << ", seq_len_kv: " << seq_len_kv
              << ", head_size_vo: " << head_size_vo << ", head_size_qk: " << head_size_qk
              << ", scale: " << softmax_scale
              << "} threw an exception: " << e.what();
            throw;
          }
          catch (...) {
            EXPECT_TRUE(false) << "TestAll: testbed.run {"
              << "batch: " << batch << ", num_heads_q: " << num_heads_q << ", num_heads_kv: " << num_heads_kv
              << ", seq_len_qo: " << seq_len_qo << ", seq_len_kv: " << seq_len_kv
              << ", head_size_vo: " << head_size_vo << ", head_size_qk: " << head_size_qk
              << ", scale: " << softmax_scale
              << "} threw an exception (unknown)";
            throw;
          }

          EXPECT_TRUE(passed) << "TestAll: testbed.run {"
            << "batch: " << batch << ", num_heads_q: " << num_heads_q << ", num_heads_kv: " << num_heads_kv
            << ", seq_len_qo: " << seq_len_qo << ", seq_len_kv: " << seq_len_kv
            << ", head_size_vo: " << head_size_vo << ", head_size_qk: " << head_size_qk
            << ", scale: " << softmax_scale
            << "} failed";

          if (!passed) {
            std::cout << __FILE__ << ':' << __LINE__ << " : Flash attention FAILED.\n";
            return false;
          }
        } // softmax_scale
      } // seq_len
    } // num_heads
  }  // batch
  return passed;
}

} // namespace flash_attention
} // namespace test

/////////////////////////////////////////////////////////////////////////////////////////////////
