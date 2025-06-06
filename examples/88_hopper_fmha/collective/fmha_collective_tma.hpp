/***************************************************************************************************
 * Copyright (c) 2024 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass/cutlass.h"
#include "cutlass/gemm/collective/collective_builder.hpp"

#include "../collective/fmha_common.hpp"
#include "../collective/fmha_collective_load.hpp"
#include "../collective/fmha_collective_softmax.hpp"
#include "../kernel/fmha_options.hpp"

namespace cutlass::fmha::collective {

using namespace cute;
using cutlass::fmha::kernel::Tag;
using cutlass::fmha::kernel::find_option_t;

template<
  typename Element_,
  typename ElementAccumulator_,
  typename TileShape_, // BlockQO, BlockKV, BlockHead
  class Fusion,
  class... Options
>
struct FmhaMainloopTma {

  using Element = Element_;
  using ElementAccumulator = ElementAccumulator_;
  using TileShape = TileShape_;

  // Options
  using kClusterM = find_option_t<Tag::kClusterM, Int<1>, Options...>;
  static constexpr int StageCount = find_option_t<Tag::kStagesKV, Int<4>, Options...>::value;
  static constexpr int StageCountQ = find_option_t<Tag::kStagesQ, Int<1>, Options...>::value;

  using StagesQ = cutlass::gemm::collective::StageCount<StageCountQ>;
  using Stages = cutlass::gemm::collective::StageCount<StageCount>;
  using ClusterShape = Shape<kClusterM, _1, _1>;

  // 16B alignment lets us use TMA
  static constexpr int Alignment = 16 / sizeof(Element);

  using TileShapeQK = TileShape;
  using TileShapePV = decltype(select<0,2,1>(TileShapeQK{}));

  using LayoutQKV = cute::tuple<int, _1, cute::tuple<int, int>>;
  using LayoutQ = LayoutQKV;
  using LayoutK = LayoutQKV;
  using LayoutV = LayoutQKV;

  using CollectiveMmaQK = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      Element, LayoutQ, Alignment,
      Element, LayoutK, Alignment,
      ElementAccumulator,
      TileShapeQK, ClusterShape, Stages,
      cutlass::gemm::KernelTmaWarpSpecialized>::CollectiveOp;

  using CollectiveMmaPV = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      // the stride for A does not matter since we do not load from smem at all
      Element, LayoutK, Alignment,
      Element, decltype(select<1,0,2>(LayoutV{})), Alignment,
      ElementAccumulator,
      TileShapePV, ClusterShape, Stages,
      cutlass::gemm::KernelTmaWarpSpecialized>::CollectiveOp;

  using TiledMmaQK = typename CollectiveMmaQK::TiledMma;
  using TiledMmaPV = decltype(convert_to_gmma_rs(typename CollectiveMmaPV::TiledMma{}));

  using SmemLayoutQ = decltype(unstageSmemLayout(typename CollectiveMmaQK::SmemLayoutA{}, Int<StagesQ::value>{}));
  using SmemLayoutK = typename CollectiveMmaQK::SmemLayoutB;
  using SmemLayoutV = typename CollectiveMmaPV::SmemLayoutB;

  using MainloopPipeline = cutlass::PipelineTmaAsync<Stages::value>;
  using MainloopPipelineQ = cutlass::PipelineTmaAsync<StagesQ::value>;

  using PipelineState  = typename cutlass::PipelineState<MainloopPipeline::Stages>;
  using PipelineStateQ  = typename cutlass::PipelineState<MainloopPipelineQ::Stages>;

  using TileShapeOut = TileShapePV;
  using TiledMmaOut = TiledMmaPV;
  using ElementOut = ElementAccumulator;

  struct SharedStorage {
    cute::array_aligned<Element, cute::cosize_v<SmemLayoutQ>> smem_q;
    union {
      cute::array_aligned<Element, cute::cosize_v<SmemLayoutK>> smem_k;
      cute::array_aligned<Element, cute::cosize_v<SmemLayoutV>> smem_v;
    };
  };

  struct Arguments {
    const Element* ptr_Q;
    LayoutQ dQ;
    const Element* ptr_K;
    LayoutK dK;
    const Element* ptr_V;
    LayoutV dV;
  };

  using TMA_Q = typename CollectiveMmaQK::Params::TMA_A;
  using TMA_K = typename CollectiveMmaQK::Params::TMA_B;
  using TMA_V = typename CollectiveMmaPV::Params::TMA_B;

  struct Params {
    TMA_Q tma_load_q;
    TMA_K tma_load_k;
    TMA_V tma_load_v;

    float scale_softmax;
    float scale_softmax_log2;
    float rp_dropout;
  };

  using LoadQ = cutlass::fmha::collective::CollectiveLoadTma<
    cutlass::fmha::collective::LoadKind::kQ,
    MainloopPipelineQ,
    Element,
    SmemLayoutQ,
    TMA_Q
  >;

  using LoadK = cutlass::fmha::collective::CollectiveLoadTma<
    cutlass::fmha::collective::LoadKind::kK,
    MainloopPipeline,
    Element,
    SmemLayoutK,
    TMA_K
  >;

  using LoadV = cutlass::fmha::collective::CollectiveLoadTma<
    cutlass::fmha::collective::LoadKind::kV,
    MainloopPipeline,
    Element,
    SmemLayoutV,
    TMA_V
  >;

  static_assert(size(typename CollectiveMmaQK::TiledMma{}) == size(typename CollectiveMmaPV::TiledMma{}));

  static const int MaxThreadsPerBlock = size(typename CollectiveMmaQK::TiledMma{});

  template<class ProblemShape>
  static bool can_implement(ProblemShape const& problem_size, Arguments const& args) {
    return true
      && (get<4>(problem_size) <= get<2>(TileShape{}))
      && ((get<4>(problem_size) % Alignment) == 0)
      && ((get<2>(problem_size) % Alignment) == 0)
    ;
  }

  template<class ProblemShape>
  static Params to_underlying_arguments(ProblemShape const& problem_size, Arguments const& args, void* workspace) {

    auto problem_shape_qk = make_shape(get<2>(problem_size), get<3>(problem_size), get<4>(problem_size), make_shape(get<0>(problem_size), get<1>(problem_size)));
    auto params_qk = CollectiveMmaQK::to_underlying_arguments(problem_shape_qk,
        typename CollectiveMmaQK::Arguments {
            args.ptr_Q, args.dQ,
            args.ptr_K, args.dK,
        }, /*workspace=*/ nullptr);

    auto problem_shape_pv = select<0,2,1,3>(problem_shape_qk);
    auto params_pv = CollectiveMmaPV::to_underlying_arguments(problem_shape_pv,
        typename CollectiveMmaPV::Arguments {
            args.ptr_K, args.dK,  // never used, dummy
            args.ptr_V, select<1,0,2>(args.dV),
        }, /*workspace=*/ nullptr);

    return Params{
        params_qk.tma_load_a,
        params_qk.tma_load_b,
        params_pv.tma_load_b,
        1.0f / (float) std::sqrt(get<4>(problem_size)),
        (float) (std::log2(std::exp(1.0)) / std::sqrt(get<4>(problem_size))),
        1.0f
    };
  }

  CUTLASS_DEVICE
  static void prefetch_tma_descriptors(Params const& params) {
    cute::prefetch_tma_descriptor(params.tma_load_q.get_tma_descriptor());
    cute::prefetch_tma_descriptor(params.tma_load_k.get_tma_descriptor());
    cute::prefetch_tma_descriptor(params.tma_load_v.get_tma_descriptor());
  }

  template<class BlkCoord, class ProblemShape>
  CUTLASS_DEVICE auto
  compute(
      int block_rank_in_cluster,
      BlkCoord const& blk_coord, Params const& params, ProblemShape const& problem_size,
      MainloopPipeline& pipeline, PipelineState& smem_pipe_read, PipelineState& smem_pipe_write,
      MainloopPipelineQ& pipeline_q, PipelineStateQ& smem_pipe_read_q, PipelineStateQ& smem_pipe_write_q,
      SharedStorage& storage)
  {
    int warp_idx   = cutlass::canonical_warp_idx_sync();
    int thread_idx = threadIdx.x;
      
    PipelineState smem_pipe_release = smem_pipe_read;
    [[maybe_unused]] PipelineStateQ smem_pipe_release_q = smem_pipe_read_q;


    int fusion_tile_count = Fusion{}.get_trip_count(blk_coord, TileShape{}, problem_size);

    LoadQ load_q{params.tma_load_q, pipeline_q, storage.smem_q};
    auto load_state_q = load_q.init_state(_0{}, problem_size, TileShapeQK{}, blk_coord, 1);

    LoadK load_k{params.tma_load_k, pipeline, storage.smem_k};
    auto load_state_k = load_k.init_state(block_rank_in_cluster, problem_size, TileShapeQK{}, blk_coord, fusion_tile_count);

    LoadV load_v{params.tma_load_v, pipeline, storage.smem_v};
    auto load_state_v = load_v.init_state(block_rank_in_cluster, problem_size, TileShapePV{}, blk_coord, fusion_tile_count);

    // Set predicate for the lowest lane_id in the warp
    int lane_predicate = cute::elect_one_sync();

    // Issue TmaLoads (Prologue fetches)
    if (warp_idx == 0) {
      auto q_tile_iter = cute::make_coord_iterator(1);
      int q_tile_count = 1;
      load_q.step(q_tile_iter, load_state_q, smem_pipe_write_q, lane_predicate, q_tile_count);
    }

    // Loop over K elems
    auto k_tile_iter = cute::make_coord_iterator(fusion_tile_count);

    int k_tile_count_tma = 2 * fusion_tile_count;

    uint16_t mcast_mask_b = 0;

    if (warp_idx == 0 && lane_predicate == 1) {
      if constexpr (cute::is_same_v<typename CollectiveMmaQK::GmemTiledCopyB, SM90_TMA_LOAD_MULTICAST>) {
        auto block_layout = Layout<ClusterShape>{}; // (m,n) -> block_id
        for (int m = 0; m < size<0>(block_layout); ++m) {
          mcast_mask_b |= (uint16_t(1) << block_layout(m,_0{},Int<0>{}));
        }
      }

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < StageCount; i++) {
        if (i % 2 == 0) {
          load_k.template step<false>(k_tile_iter, load_state_k, smem_pipe_write, lane_predicate, k_tile_count_tma, mcast_mask_b);
        } else {
          load_v.template step<true>(k_tile_iter, load_state_k, smem_pipe_write, lane_predicate, k_tile_count_tma, mcast_mask_b);
        }
      }
    }

    TiledMmaQK tiled_mma_qk;
    auto thr_mma_qk = tiled_mma_qk.get_thread_slice(thread_idx);
    
    // Mainloop setup QK
    Tensor sQ = make_tensor(make_smem_ptr(storage.smem_q.data()), SmemLayoutQ{});
    Tensor sK = make_tensor(make_smem_ptr(storage.smem_k.data()), SmemLayoutK{});

    Tensor tSsQ = thr_mma_qk.partition_A(sQ);                                   // (MMA,MMA_M,MMA_K,PIPE)
    Tensor tSsK = thr_mma_qk.partition_B(sK);                                   // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tSrQ = thr_mma_qk.make_fragment_A(tSsQ);                            // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tSrK = thr_mma_qk.make_fragment_B(tSsK);                            // (MMA,MMA_M,MMA_N,PIPE)
    
    // Prepare: MMA PV
    TiledMmaPV tiled_mma_pv;
    auto thr_mma_pv = tiled_mma_pv.get_thread_slice(thread_idx);
    
    // Mainloop setup PV
    Tensor sV = make_tensor(make_smem_ptr(storage.smem_v.data()), SmemLayoutV{});

    Tensor tOsV = thr_mma_pv.partition_B(sV);                                   // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tOrV = thr_mma_pv.make_fragment_B(tOsV);                            // (MMA,MMA_M,MMA_N,PIPE)
  
    int k_tile_count = Fusion{}.get_unmasked_trip_count(blk_coord, TileShape{}, problem_size);

    pipeline_q.consumer_wait(smem_pipe_read_q);
 
    // mapping into QK accumulator
    Tensor cP = make_identity_tensor(take<0,2>(TileShapeQK{}));
    Tensor tPcP = thr_mma_qk.partition_C(cP);
    int m_block = get<0>(blk_coord);
    tPcP.data() = tPcP.data() + E<0>{} * m_block * get<0>(TileShapeQK{});
  
    // Allocate PV acc
    Tensor acc_pv = partition_fragment_C(tiled_mma_pv, take<0, 2>(TileShapePV{}));

    cutlass::fmha::collective::CollectiveSoftmax<ElementAccumulator, Fusion, decltype(params)> softmax{params};
    auto softmax_state = softmax.init(acc_pv, tiled_mma_pv);

    if (true)
    {
        --k_tile_count;
        // Allocate QK acc
        Tensor acc_qk = partition_fragment_C(tiled_mma_qk, take<0, 2>(TileShapeQK{}));
  
        pipeline.consumer_wait(smem_pipe_read);

        // MMA QK
        warpgroup_fence_operand(acc_qk);
        warpgroup_arrive();
  
        gemm_zero_acc(tiled_mma_qk, tSrQ(_,_,_,_0{}), tSrK(_,_,_,smem_pipe_read.index()), acc_qk);
        warpgroup_commit_batch();

        ++smem_pipe_read;
  
        // Wait for the pipeline MMAs to drain
        warpgroup_wait<0>();
        warpgroup_fence_operand(acc_qk);

        softmax.step(acc_qk, tiled_mma_qk, tPcP, softmax_state, problem_size);
  
        Tensor acc_qk_fixed = make_fragment_like<Element>(convert_c_layout_to_a_layout(acc_qk.layout(), shape<1>(typename decltype(tiled_mma_pv)::LayoutA_TV{})));
  
        Tensor acc_qk_input = make_tensor(acc_qk_fixed.data(), acc_qk.layout());
        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < size(acc_qk); i++) {
            acc_qk_input(i) = static_cast<Element>(acc_qk(i));
        }
  
        pipeline.consumer_wait(smem_pipe_read);

        // MMA PV
        warpgroup_fence_operand(acc_pv);
        warpgroup_fence_operand(acc_qk_fixed);
       warpgroup_arrive();
  
        gemm_zero_acc(tiled_mma_pv, acc_qk_fixed, tOrV(_,_,_,smem_pipe_read.index()), acc_pv);
        warpgroup_commit_batch();
  
        //
        // Advance the pipe
        //

        // Advance consumer pipeline
        ++smem_pipe_read;

        pipeline.consumer_release(smem_pipe_release);
        ++smem_pipe_release;

        tPcP.data() = tPcP.data() + E<1>{} * get<1>(TileShapeQK{});
    }
  
    CUTLASS_PRAGMA_NO_UNROLL
    for ( ; k_tile_count > 0; --k_tile_count)
    {
        // Allocate QK acc
        Tensor acc_qk = partition_fragment_C(tiled_mma_qk, take<0, 2>(TileShapeQK{}));
  
        pipeline.consumer_wait(smem_pipe_read);

        // MMA QK
        warpgroup_fence_operand(acc_qk);
        warpgroup_arrive();

        gemm_zero_acc(tiled_mma_qk, tSrQ(_,_,_,_0{}), tSrK(_,_,_,smem_pipe_read.index()), acc_qk);
        warpgroup_commit_batch();

        ++smem_pipe_read;

        if (warp_idx == 0) {
          load_k.template step<false>(k_tile_iter, load_state_k, smem_pipe_write, lane_predicate, k_tile_count_tma, mcast_mask_b);
        }
  
        // Wait for the pipeline MMAs to drain
        warpgroup_wait<0>();
        warpgroup_fence_operand(acc_qk);
        warpgroup_fence_operand(acc_pv);

        softmax.template step_interleave_begin<false>(acc_qk, tiled_mma_qk, tPcP, softmax_state, acc_pv, tiled_mma_pv, problem_size);

        pipeline.consumer_release(smem_pipe_release);

        ++smem_pipe_release;

        pipeline.consumer_wait(smem_pipe_read);

        // MMA PV  
        auto layout_qk_input = convert_c_layout_to_a_layout(acc_qk.layout(), shape<1>(typename decltype(tiled_mma_pv)::LayoutA_TV{}));
  
        Tensor acc_qk_input = make_tensor(acc_qk.data(), layout_qk_input);
  
        static_assert(decltype(size<1>(layout_qk_input) == _1{})::value);
        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < size<2>(tOrV); i++) {
          Tensor acc_qk_element = make_fragment_like<Element>(layout_qk_input(_, _0{}, _0{}));
          Tensor acc_qk_element_mk = tensor_op_mk_v(tiled_mma_pv, acc_qk_element);
          Tensor acc_qk_input_mk = tensor_op_mk_v(tiled_mma_pv, acc_qk_input(_, _0{}, i));
          softmax.step_interleave_step(acc_qk_input_mk, softmax_state);
          CUTLASS_PRAGMA_UNROLL
          for (int j = 0; j < size(acc_qk_element_mk); j++) {
            acc_qk_element_mk(j) = static_cast<Element>(acc_qk_input_mk(j));
          }
          warpgroup_arrive();
          CUTLASS_PRAGMA_UNROLL
          for (int j = 0; j < size<1>(tOrV); j++) {
            cute::gemm(tiled_mma_pv, acc_qk_element, tOrV(_,j,i,smem_pipe_read.index()), acc_pv(_,_0{},j));
          }
        }
        warpgroup_commit_batch();
  
        // Wait for the pipeline MMAs to drain
        pipeline.consumer_release(smem_pipe_release);
        ++smem_pipe_release;

        ++smem_pipe_read;

        if (warp_idx == 0) {
          load_v.template step<true>(k_tile_iter, load_state_v, smem_pipe_write, lane_predicate, k_tile_count_tma, mcast_mask_b);
        }

        tPcP.data() = tPcP.data() + E<1>{} * get<1>(TileShapeQK{});
    }

    k_tile_count += Fusion{}.get_masked_trip_count(blk_coord, TileShape{}, problem_size);

    CUTLASS_PRAGMA_NO_UNROLL
    for ( ; k_tile_count > 0; --k_tile_count)
    {
        // Allocate QK acc
        Tensor acc_qk = partition_fragment_C(tiled_mma_qk, take<0, 2>(TileShapeQK{}));
  
        pipeline.consumer_wait(smem_pipe_read);

        // MMA QK
        warpgroup_fence_operand(acc_qk);
        warpgroup_arrive();

        gemm_zero_acc(tiled_mma_qk, tSrQ(_,_,_,_0{}), tSrK(_,_,_,smem_pipe_read.index()), acc_qk);
        warpgroup_commit_batch();

        ++smem_pipe_read;

        if (warp_idx == 0) {
          load_k.template step<false>(k_tile_iter, load_state_k, smem_pipe_write, lane_predicate, k_tile_count_tma, mcast_mask_b);
        }
  
        // Wait for the pipeline MMAs to drain
        warpgroup_wait<0>();
        warpgroup_fence_operand(acc_qk);
        warpgroup_fence_operand(acc_pv);

        softmax.step_interleave_begin(acc_qk, tiled_mma_qk, tPcP, softmax_state, acc_pv, tiled_mma_pv, problem_size);

        pipeline.consumer_release(smem_pipe_release);

        ++smem_pipe_release;

        pipeline.consumer_wait(smem_pipe_read);

        // MMA PV  
        auto layout_qk_input = convert_c_layout_to_a_layout(acc_qk.layout(), shape<1>(typename decltype(tiled_mma_pv)::LayoutA_TV{}));
  
        Tensor acc_qk_input = make_tensor(acc_qk.data(), layout_qk_input);
  
        static_assert(decltype(size<1>(layout_qk_input) == _1{})::value);
        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < size<2>(tOrV); i++) {
          Tensor acc_qk_element = make_fragment_like<Element>(layout_qk_input(_, _0{}, _0{}));
          Tensor acc_qk_element_mk = tensor_op_mk_v(tiled_mma_pv, acc_qk_element);
          Tensor acc_qk_input_mk = tensor_op_mk_v(tiled_mma_pv, acc_qk_input(_, _0{}, i));
          softmax.step_interleave_step(acc_qk_input_mk, softmax_state);
          CUTLASS_PRAGMA_UNROLL
          for (int j = 0; j < size(acc_qk_element_mk); j++) {
            acc_qk_element_mk(j) = static_cast<Element>(acc_qk_input_mk(j));
          }
          warpgroup_arrive();
          CUTLASS_PRAGMA_UNROLL
          for (int j = 0; j < size<1>(tOrV); j++) {
            cute::gemm(tiled_mma_pv, acc_qk_element, tOrV(_,j,i,smem_pipe_read.index()), acc_pv(_,_0{},j));
          }
        }
        warpgroup_commit_batch();
  
        // Wait for the pipeline MMAs to drain
        pipeline.consumer_release(smem_pipe_release);
        ++smem_pipe_release;

        ++smem_pipe_read;

        if (warp_idx == 0) {
          load_v.template step<true>(k_tile_iter, load_state_v, smem_pipe_write, lane_predicate, k_tile_count_tma, mcast_mask_b);
        }

        tPcP.data() = tPcP.data() + E<1>{} * get<1>(TileShapeQK{});
    }

    // Wait for the pipeline MMAs to drain
    warpgroup_wait<0>();
    warpgroup_fence_operand(acc_pv);

    Tensor lse = softmax.tail(softmax_state, acc_pv, tiled_mma_pv);

    return make_tuple(acc_pv, lse);
  }
};

}  // namespace cutlass::fmha::collective

