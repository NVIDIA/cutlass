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
/*! \file
    \brief Tests for device-wide Flash Attention Decode interface
*/

#pragma once

#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "flash_attention_v2/collective/fmha_fusion.hpp"
#include "flash_attention_v2/kernel/tile_scheduler.hpp"
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
#include "cutlass/util/device_memory.h"
#include "cutlass/util/reference/device/sycl_tensor_fill.h"

#include "../gemm/device/testbed_utils.h"
#include "../common/cutlass_unit_test.h"

namespace test {
namespace flash_attention {

using namespace cute;

using MMAOperationBF16 = XE_1x16x16_F32BF16BF16F32_TT;
using MMAOperationFP16 = XE_1x16x16_F32F16F16F32_TT;

template <int KVTile, int NumSGs>
struct Shape_h64 {
  using ShapeQK = Shape<_1, Int<KVTile>, _64>;
  using ShapePV = Shape<_1, _32, Int<KVTile>>;
  using ShapeOutput = Shape<_1, _64, Int<KVTile>>;
  using SubgroupLayout = Layout<Shape<Int<NumSGs>, _1, _1>>;
};

template <int KVTile, int NumSGs>
struct Shape_h96 {
  using ShapeQK = Shape<_1, Int<KVTile>, _64>;
  using ShapePV = Shape<_1, _32, Int<KVTile>>;
  using ShapeOutput = Shape<_1, _96, Int<KVTile>>;
  using SubgroupLayout = Layout<Shape<Int<NumSGs>, _1, _1>>;
};

template <int KVTile, int NumSGs>
struct Shape_h128 {
  using ShapeQK = Shape<_1, Int<KVTile>, _64>;
  using ShapePV = Shape<_1, _32, Int<KVTile>>;
  using ShapeOutput = Shape<_1, _128, Int<KVTile>>;
  using SubgroupLayout = Layout<Shape<Int<NumSGs>, _1, _1>>;
};

template <int KVTile, int NumSGs>
struct Shape_h192 {
  using ShapeQK = Shape<_1, Int<KVTile>, _64>;
  using ShapePV = Shape<_1, _32, Int<KVTile>>;
  using ShapeOutput = Shape<_1, _192, Int<KVTile>>;
  using SubgroupLayout = Layout<Shape<Int<NumSGs>, _1, _1>>;
};

using GmemTiledCopyQU16 = cute::XE_2D_U16x1x16_LD_N;
using GmemTiledCopyKU16 = cute::XE_2D_U16x16x16_LD_T;
using GmemTiledCopyVU16 = cute::XE_2D_U16x32x32_LD_V;
using GmemTiledCopyStoreU32 = cute::XE_2D_U32x1x16_ST_N;
using GmemTiledCopyStoreU16 = cute::XE_2D_U16x1x16_ST_N;

template<typename ElementInputType, typename ElementAccumulatorType, typename ElementOutputType,  
         typename TileShapeQK, typename TileShapePV, typename TileShapeOutput, typename SubgroupLayout, 
         typename MMAOperation, bool HasCausalMask, bool isVarLen, typename TiledCopyQ, typename TiledCopyK,
         typename TiledCopyV, typename TiledCopyStore>
struct XE_Flash_Attention_Decode {
  using LayoutQ = cutlass::layout::RowMajor;
  using LayoutK = cutlass::layout::ColumnMajor;
  using LayoutV = cutlass::layout::RowMajor;
  using LayoutO = cutlass::layout::RowMajor;

  using ElementAccumulator = ElementAccumulatorType;
  using ElementComputeEpilogue = ElementAccumulatorType;
  using ElementInputQ = ElementInputType;
  using ElementInputKV = ElementInputType;
  using ElementOutput = ElementOutputType;

  using ProblemShapeRegular = cute::tuple<int, int, int, int, int, int, int, int>;
  using ProblemShapeVarlen = cute::tuple<int, int, int, cutlass::fmha::collective::VariableLength,
                                         cutlass::fmha::collective::VariableLength, cutlass::fmha::collective::VariableLength,
                                         int, int>;
  using ProblemShapeType = std::conditional_t<isVarLen, ProblemShapeVarlen, ProblemShapeRegular>;

  static constexpr int PipelineStages = 2;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;

  using GmemTiledCopyQ = TiledCopyQ;
  using GmemTiledCopyK = TiledCopyK;
  using GmemTiledCopyV = TiledCopyV;
  using GmemTiledCopyStore = TiledCopyStore;
  using CollectiveEpilogue = cutlass::flash_attention::collective::FlashDecodeEpilogue<
        EpilogueDispatchPolicy, MMAOperation, TileShapeOutput, SubgroupLayout, ElementAccumulator, ElementOutput, cutlass::gemm::TagToStrideC_t<LayoutO>,
        ElementOutput, GmemTiledCopyStore>;
  using CollectiveSoftmaxEpilogue = cutlass::flash_attention::collective::FlashDecodeSoftmaxEpilogue<
        HasCausalMask, EpilogueDispatchPolicy, ElementAccumulator>;

  // Mainloop
  using CollectiveMainloop = cutlass::flash_attention::collective::FlashDecodeMma<
        GEMMDispatchPolicy, ProblemShapeType, ElementInputQ,
        cutlass::gemm::TagToStrideA_t<LayoutQ>, ElementInputKV,
        cutlass::gemm::TagToStrideB_t<LayoutK>, ElementInputKV,
        cutlass::gemm::TagToStrideB_t<LayoutV>, MMAOperation,
        TileShapeQK, TileShapePV, SubgroupLayout,
        GmemTiledCopyQ, // Q
        GmemTiledCopyK, // K
        GmemTiledCopyV, // V,
        HasCausalMask>;

    using Kernel = cutlass::flash_attention::kernel::FMHADecode<ProblemShapeType, CollectiveMainloop,
                                                       CollectiveSoftmaxEpilogue, CollectiveEpilogue>;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

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

  cutlass::reference::device::BlockFillRandomUniform(
       block.get(), block.size(), seed, scope_max, scope_min, 0);

  syclcompat::wait();
  return true;
}

template <typename FlashDecode>
struct TestbedImpl {
  using LayoutQ = cutlass::layout::RowMajor;
  using LayoutK = cutlass::layout::ColumnMajor;
  using LayoutV = cutlass::layout::RowMajor;
  using LayoutO = cutlass::layout::RowMajor;

  using StrideQ = typename FlashDecode::StrideQ;
  using StrideK = typename FlashDecode::StrideK;
  using StrideV = typename FlashDecode::StrideV;
  using StrideO = typename FlashDecode::StrideO;

  using ElementQ = typename FlashDecode::ElementQ;
  using ElementK = typename FlashDecode::ElementK;
  using ElementV = typename FlashDecode::ElementV;
  using ElementAcc = typename FlashDecode::ElementAccumulator;

  using CollectiveMainloop = typename FlashDecode::CollectiveMainloop;
  using CollectiveEpilogue = typename FlashDecode::CollectiveEpilogue;
  using ElementOutput = typename CollectiveEpilogue::ElementOutput;
  using ElementCompute = typename CollectiveEpilogue::ElementCompute;
  using ElementAccumulator = typename CollectiveEpilogue::ElementAccumulator;

  using ProblemShapeType = typename FlashDecode::ProblemShape;
  static constexpr bool HasCausalMask = CollectiveMainloop::CausalMask;
  static constexpr bool isVarLen = CollectiveMainloop::is_var_len;

  StrideQ stride_Q;
  StrideK stride_K;
  StrideV stride_V;
  StrideK stride_K_cache;
  StrideV stride_V_cache;
  StrideO stride_O;
  uint64_t seed = 0;
  bool use_kv_cache;

  std::vector<int> cumulative_seqlen_q;
  std::vector<int> cumulative_seqlen_kv;
  std::vector<int> cumulative_seqlen_kv_cache;
  cutlass::DeviceAllocation<int> device_cumulative_seqlen_q;
  cutlass::DeviceAllocation<int> device_cumulative_seqlen_kv;
  cutlass::DeviceAllocation<int> device_cumulative_seqlen_kv_cache;
  cutlass::DeviceAllocation<ElementQ> block_Q;
  cutlass::DeviceAllocation<ElementK> block_K;
  cutlass::DeviceAllocation<ElementV> block_V;
  cutlass::DeviceAllocation<ElementK> block_K_cache;
  cutlass::DeviceAllocation<ElementV> block_V_cache;
  cutlass::DeviceAllocation<ElementOutput> block_O;
  cutlass::DeviceAllocation<ElementOutput> block_ref_O;

  //
  // Methods
  //

  /// Initializes data structures
  template <class ProblemShape>
  ProblemShapeType initialize(ProblemShape problem_shape_in) {
#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::initialize(problem_size)");
#endif
    ProblemShapeType problem_shape;
    ProblemShape problem_size;

    if (cute::get<5>(problem_shape_in) > 0) {
      use_kv_cache = true;
    } else {
      use_kv_cache = false;
    }

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
      cute::get<3>(problem_shape).cumulative_length = device_cumulative_seqlen_q.get();
      cute::get<4>(problem_shape).cumulative_length = device_cumulative_seqlen_kv.get();
      cute::get<5>(problem_shape).cumulative_length = device_cumulative_seqlen_kv_cache.get();
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
    std::normal_distribution<double> dist_kv_cache(cute::get<5>(problem_size), cute::get<5>(problem_size) / 2);

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
    cute::get<0>(problem_size_for_init) = 1;
    cute::get<3>(problem_size_for_init) = total_seqlen_q;
    cute::get<4>(problem_size_for_init) = total_seqlen_kv;
    cute::get<5>(problem_size_for_init) = total_seqlen_kv_cache;

    ProblemShapeType problem_size_for_launch;

    cute::get<3>(problem_size_for_launch) = cutlass::fmha::collective::VariableLength{max_seqlen_q};
    cute::get<4>(problem_size_for_launch) = cutlass::fmha::collective::VariableLength{max_seqlen_kv};
    cute::get<6>(problem_size_for_launch) = cute::get<6>(problem_size);
    cute::get<5>(problem_size_for_launch) = cutlass::fmha::collective::VariableLength{max_seqlen_kv_cache};
    cute::get<7>(problem_size_for_launch) = cute::get<7>(problem_size);
    cute::get<0>(problem_size_for_launch) = cute::get<0>(problem_size);
    cute::get<1>(problem_size_for_launch) = cute::get<1>(problem_size);
    cute::get<2>(problem_size_for_launch) = cute::get<2>(problem_size);


    return cute::make_tuple(problem_size_for_init, problem_size_for_launch);
  }

  /// Verifies the result
  bool verify(ProblemShapeType problem_size, float softmax_scale) {
    if constexpr (isVarLen) {
      int max_seq_len_q = static_cast<int>(cute::get<3>(problem_size));
      int max_seq_len_kv = static_cast<int>(cute::get<4>(problem_size));
      int max_seq_len_kv_cache = static_cast<int>(cute::get<5>(problem_size));
      cute::get<3>(problem_size) = cutlass::fmha::collective::VariableLength{max_seq_len_q, cumulative_seqlen_q.data()};
      cute::get<4>(problem_size) = cutlass::fmha::collective::VariableLength{max_seq_len_kv, cumulative_seqlen_kv.data()};
      cute::get<5>(problem_size) = cutlass::fmha::collective::VariableLength{max_seq_len_kv_cache, cumulative_seqlen_kv_cache.data()};
    }

    auto [batch, num_heads_q, num_heads_kv, head_size_qk, head_size_vo] = cute::select<0,1,2,6,7>(problem_size);
    int seq_len_qo, seq_len_kv, seq_len_kv_cache;

    int offset_q = 0;
    int offset_k = 0;
    int offset_v = 0;
    int offset_k_cache = 0;
    int offset_v_cache = 0;
    int offset_o = 0;

    int q_group_size = num_heads_q / num_heads_kv;
    // loop over the batch dimension to compute the output
    // to avoid the risk of running out of device memory
    for (int b = 0; b < batch; b++) {
      if constexpr (isVarLen) {
        auto logical_problem_shape = cutlass::fmha::collective::apply_variable_length(problem_size, b);
        seq_len_qo = cute::get<3>(logical_problem_shape);
        seq_len_kv = cute::get<4>(logical_problem_shape);
	      seq_len_kv_cache = cute::get<5>(logical_problem_shape);
      } else {
        seq_len_qo = cute::get<3>(problem_size);
        seq_len_kv = cute::get<4>(problem_size);
	      seq_len_kv_cache = cute::get<5>(problem_size);
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
            syclcompat::wait();

            k_ptr = block_K_concat.get();
            v_ptr = block_V_concat.get();
        }
        else {
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
        syclcompat::wait();

        // delete this memory as it is no longer needed
        block_S.reset();

        auto offset = cute::min(seq_len_qo, seq_len_kv);
        auto discard_seq_coord = seq_len_qo - offset;
        auto full_tile_offset = seq_len_kv - offset;
        int start_col = use_kv_cache ? seq_len_kv_cache : 0;

        if (HasCausalMask) {
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
            host_S[idx] = expf((host_S[idx] - max_vec[max_idx]) / sqrt(static_cast<ElementAccumulator>((head_size_qk))));
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
            if(HasCausalMask && row < discard_seq_coord) { 
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
    typename FlashDecode::Arguments arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      problem_size,
      {block_Q.get(), stride_Q,
      block_K.get(), stride_K,
      block_V.get(), stride_V,
      block_K_cache.get(), stride_K_cache,
      block_V_cache.get(), stride_V_cache},
      {softmax_scale},
      {block_O.get(), stride_O},
      hw_info};

#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: Calling FlashDecode::get_workspace_size");
#endif
    size_t workspace_size = FlashDecode::get_workspace_size(arguments);
#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: Allocating workspace of size " << workspace_size);
#endif
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: Calling FlashDecode::can_implement");
#endif
    auto can_implement = FlashDecode::can_implement(arguments);

    if (!can_implement) {
      std::cerr << "This test is not supported." << "\n";
    }

    //
    // Run Flash attention
    //

#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: Calling to_underlying_arguments");
#endif
    auto params = FlashDecode::to_underlying_arguments(arguments, workspace.get());

#if (CUTLASS_DEBUG_TRACE_LEVEL > 1)
    CUTLASS_TRACE_HOST("TestbedImpl::run: Calling run");
#endif
    auto const block = FlashDecode::get_block_shape();
    auto const grid = FlashDecode::get_grid_shape(params);

    // configure smem size and carveout
    int smem_size = FlashDecode::SharedStorageSize;

    const auto sycl_block = syclcompat::dim3(block.x, block.y, block.z);
    const auto sycl_grid = syclcompat::dim3(grid.x, grid.y, grid.z);

#if !defined(SYCL_EXT_ONEAPI_WORK_GROUP_SCRATCH_MEMORY)
    using namespace syclcompat::experimental;
    auto event = launch<cutlass::device_kernel<FlashDecode>>(
        launch_policy{sycl_grid, sycl_block, local_mem_size{static_cast<std::size_t>(smem_size)},
                      kernel_properties{sycl_exp::sub_group_size<FlashDecode::DispatchPolicy::SubgroupSize>}},
        params);
#else
    syclcompat::experimental::launch_properties launch_props {
      sycl::ext::oneapi::experimental::work_group_scratch_size(smem_size),
    };
    syclcompat::experimental::kernel_properties kernel_props{
      sycl::ext::oneapi::experimental::sub_group_size<FlashDecode::DispatchPolicy::SubgroupSize>
    };
    syclcompat::experimental::launch_policy policy{sycl_grid, sycl_block, launch_props, kernel_props};
    auto event = syclcompat::experimental::launch<cutlass::device_kernel<FlashDecode>>(policy, params);
#endif
    EventManager::getInstance().addEvent(event);

    try {
      syclcompat::wait_and_throw();
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
  typename FlashDecode
>
struct Testbed3x {
  using TestBedImpl = typename detail::TestbedImpl<FlashDecode>;
  TestBedImpl impl_;

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

template <typename FlashDecode>
bool TestFlashDecodeAll(int head_size) {
  Testbed3x<FlashDecode> testbed;

  std::vector<int> problem_size_batch{16};
  std::vector<int> problem_size_num_heads{32};
  std::vector<int> problem_size_seq_len{1024};
  std::vector<int> problem_size_seq_len_cache{0, 1024};
  std::vector<float> problem_size_softmax_scale{ 1.f / sqrt(static_cast<float>(head_size)) };
  bool passed = true;

  for (int batch : problem_size_batch) {
    for (int num_heads : problem_size_num_heads) {
      for (int seq_len : problem_size_seq_len) {
        for (int seq_len_cache : problem_size_seq_len_cache) {
          for (float softmax_scale : problem_size_softmax_scale) {
            auto num_heads_q = num_heads;
            auto num_heads_kv = num_heads;
            auto seq_len_qo = 1;
            auto seq_len_kv = seq_len;
            auto seq_len_kv_cache = seq_len_cache;
            auto head_size_qk = head_size;
            auto head_size_vo = head_size;

            auto problem_size = cute::make_tuple(
              batch, num_heads_q, num_heads_kv, seq_len_qo, seq_len_kv, seq_len_kv_cache, head_size_qk, head_size_vo);
            try {
              passed = testbed.run(problem_size, softmax_scale);
            }
            catch (std::exception const& e) {
              EXPECT_TRUE(false) << "TestFlashDecodeAll: testbed.run {"
                << "batch: " << batch << ", num_heads_q: " << num_heads_q << ", num_heads_kv: " << num_heads_kv
                << ", seq_len_qo: " << seq_len_qo << ", seq_len_kv: " << seq_len_kv << ", seq_len_kv_cache: "
                << seq_len_cache << ", head_size_vo: " << head_size_vo << ", head_size_qk: " << head_size_qk
                << ", scale: " << softmax_scale
                << "} threw an exception: " << e.what();
              throw;
            }
            catch (...) {
              EXPECT_TRUE(false) << "TestFlashDecodeAll: testbed.run {"
                << "batch: " << batch << ", num_heads_q: " << num_heads_q << ", num_heads_kv: " << num_heads_kv
                << ", seq_len_qo: " << seq_len_qo << ", seq_len_kv: " << seq_len_kv << ", seq_len_kv_cache: "
                << seq_len_cache << ", head_size_vo: " << head_size_vo << ", head_size_qk: " << head_size_qk
                << ", scale: " << softmax_scale
                << "} threw an exception (unknown)";
              throw;
            }

            EXPECT_TRUE(passed) << "TestFlashDecodeAll: testbed.run {"
              << "batch: " << batch << ", num_heads_q: " << num_heads_q << ", num_heads_kv: " << num_heads_kv
              << ", seq_len_qo: " << seq_len_qo << ", seq_len_kv: " << seq_len_kv << ", seq_len_kv_cache: "
              << seq_len_cache << ", head_size_vo: " << head_size_vo << ", head_size_qk: " << head_size_qk
              << ", scale: " << softmax_scale
              << "} failed";

            if (!passed) {
              std::cout << __FILE__ << ':' << __LINE__ << " : Flash Decode FAILED.\n";
              return false;
            }
          } // softmax_scale
        } // seq_len_cache
      } // seq_len
    } // num_heads
  }  // batch
  return passed;
}

} // namespace flash_attention
} // namespace test

/////////////////////////////////////////////////////////////////////////////////////////////////
