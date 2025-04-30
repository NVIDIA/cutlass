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

#include "cutlass/cutlass.h"
#include "cutlass/gemm/dispatch_policy.hpp"

#include "cute/algorithm/functional.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/algorithm/gemm.hpp"
#include "cutlass/util/packed_stride.hpp"

#include "fmha_fusion.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::flash_attention::collective {
using namespace cute;

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename To_type, typename Engine, typename Layout>
CUTLASS_DEVICE auto convert_type(Tensor<Engine, Layout> const &tensor) {
  using From_type = typename Engine::value_type;
  constexpr int numel = decltype(size(tensor))::value;
  cutlass::NumericArrayConverter<To_type, From_type, numel> convert_op;
  auto frag = convert_op(*reinterpret_cast<const cutlass::Array<From_type, numel> *>(tensor.data()));
  return make_tensor(make_rmem_ptr<To_type>(&frag), tensor.layout());
}

////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////

template <class DispatchPolicy, class ProblemShapeType_, class TileShape_, class ElementQ_, class StrideQ_, class ElementK_, class StrideK_,
          class ElementV_, class StrideV_, class TiledMma_, class GmemTiledCopyQ_, class GmemTiledCopyK_,
          class GmemTiledCopyV_, bool CausalMask_>
struct CollectiveMmaAttention {
  static_assert(cutlass::detail::dependent_false<ElementQ_>, "Could not find a mainloop specialization.");
};

/////////////////////////////////////////////////////////////////////////////////////////////////

template <int Stages, class ProblemShapeType_, class TileShape_, class ElementQ_, class StrideQ_, class ElementK_, class StrideK_,
          class ElementV_, class StrideV_, class TiledMma_, class GmemTiledCopyQ_, class GmemTiledCopyK_,
          class GmemTiledCopyV_, bool CausalMask_>
struct CollectiveMmaAttention<gemm::MainloopIntelXeXMX16<Stages>, ProblemShapeType_, TileShape_, ElementQ_, StrideQ_, ElementK_, StrideK_, ElementV_,
                              StrideV_, TiledMma_, GmemTiledCopyQ_, GmemTiledCopyK_, GmemTiledCopyV_, CausalMask_> {
  //
  // Type Aliases
  //
  using DispatchPolicy = gemm::MainloopIntelXeXMX16<Stages>;
  using TileShape = TileShape_;
  using WorkgroupTileShape = TileShape; // <BLK_M_Q, BLK_N_V, BLK_N_QK, BLK_K_QK>
  using ProblemShapeType = ProblemShapeType_;
  using ElementQ = ElementQ_;
  using StrideQ = StrideQ_;
  using ElementK = ElementK_;
  using StrideK = StrideK_;
  using ElementV = ElementV_;
  using StrideV = StrideV_;
  using TiledMma = TiledMma_;
  using TiledMmaQVO = TiledMma;
  using ElementAccumulator = typename TiledMma::ValTypeC;
  using GmemTiledCopyQ = GmemTiledCopyQ_;
  using GmemTiledCopyK = GmemTiledCopyK_;
  using GmemTiledCopyV = GmemTiledCopyV_;
  using ArchTag = typename DispatchPolicy::ArchTag;

  static constexpr bool CausalMask = CausalMask_;
  static constexpr int SubgroupSize = DispatchPolicy::SubgroupSize;

  using MmaAtomShape = typename TiledMma::AtomShape_MNK;

  using TileShapeQK = decltype(select<0, 2, 3>(WorkgroupTileShape{})); // <BLK_M_Q, BLK_N_QK, BLK_K_QK>
  using TileShapePV = decltype(select<0, 1, 2>(WorkgroupTileShape{})); // <BLK_M_PV, BLK_N_V, BLK_N_QK>

  static constexpr auto PV_BLK_N = get<1>(TileShapePV{});
  static constexpr auto PV_BLK_K = get<2>(TileShapePV{});

  static constexpr auto PV_ATOM_M = get<1>(typename TiledMmaQVO::ThrLayoutVMNK{}.shape());
  static constexpr auto PV_ATOM_N = get<2>(typename TiledMmaQVO::ThrLayoutVMNK{}.shape());
  static constexpr auto PV_ATOM_K = get<3>(typename TiledMmaQVO::ThrLayoutVMNK{}.shape());

  using SubgroupTileShapePV = decltype(cute::shape_div(TileShapePV{}, take<1, 4>(typename TiledMmaQVO::ThrLayoutVMNK{}.shape())));

  static constexpr auto QK_BLK_M = get<0>(TileShapeQK{});
  static constexpr auto QK_BLK_N = get<1>(TileShapeQK{});
  static constexpr auto QK_BLK_K = get<2>(TileShapeQK{});

  using K_Atom_Shape = decltype(Shape<Int<PV_ATOM_M>, _1, _1>{});

  // This TiledMma is only required to serve the specific tiling requirements for matrix K.
  // This is due to the consumption of matrix K by all subgroups within a workgroup.
  using TiledMmaK = typename TiledMMAHelper<typename TiledMmaQVO::Atom, 
                                            Layout<TileShapeQK>,
                                            Layout<K_Atom_Shape, Stride<_1, _1, _1>>>::TiledMMA;

  static constexpr auto QK_ATOM_M = get<1>(typename TiledMmaK::ThrLayoutVMNK{}.shape()); // 8
  static constexpr auto QK_ATOM_N = get<2>(typename TiledMmaK::ThrLayoutVMNK{}.shape()); // 1
  static constexpr auto QK_ATOM_K = get<3>(typename TiledMmaK::ThrLayoutVMNK{}.shape()); // 1

  using SubgroupTileShapeQK = decltype(cute::shape_div(TileShapeQK{}, take<1, 4>(typename TiledMmaK::ThrLayoutVMNK{}.shape())));

  static constexpr auto QK_SG_M = get<0>(SubgroupTileShapeQK{});
  static constexpr auto QK_SG_N = get<1>(SubgroupTileShapeQK{});
  static constexpr auto QK_SG_K = get<2>(SubgroupTileShapeQK{});

  static constexpr bool is_var_len = cutlass::fmha::collective::is_variable_length_v<tuple_element_t<3, ProblemShapeType>>;

  using SubgroupTileShapeO = decltype(cute::shape_div(TileShapePV{}, take<1, 4>(typename TiledMmaQVO::ThrLayoutVMNK{}.shape())));
  using FragsShape = decltype(cute::shape_div(take<0, 2>(SubgroupTileShapeO{}), take<0, 2>(MmaAtomShape())));

  static constexpr uint32_t MaxThreadsPerBlock = size(TiledMmaQVO{});
  using CopyThreadShape = Shape<_1, Int<SubgroupSize>>;
  
  using traits_load_Q = Copy_Traits<GmemTiledCopyQ, StrideQ>;
  using atom_load_Q = Copy_Atom<traits_load_Q, ElementQ>;
  using val_layout_load_Q = decltype(make_layout(shape_div(typename traits_load_Q::BlockShape{}, CopyThreadShape{})));
  using XE_Copy_Q = decltype(make_tiled_copy(atom_load_Q{}, Layout<CopyThreadShape>{}, val_layout_load_Q{}));

  using traits_load_K = Copy_Traits<GmemTiledCopyK, StrideK>;
  using atom_load_K = Copy_Atom<traits_load_K, ElementK>;
  using val_layout_load_K = decltype(make_layout(shape_div(typename traits_load_K::BlockShape{}, CopyThreadShape{})));
  using XE_Copy_K = decltype(make_tiled_copy(atom_load_K{}, Layout<CopyThreadShape>{}, val_layout_load_K{}));

  using traits_load_V = Copy_Traits<GmemTiledCopyV, StrideV>;
  using atom_load_V = Copy_Atom<traits_load_V, ElementV>;
  using val_layout_load_V = decltype(make_layout(shape_div(typename traits_load_V::BlockShape{}, CopyThreadShape{})));
  using XE_Copy_V = decltype(make_tiled_copy(atom_load_V{}, Layout<CopyThreadShape>{}, val_layout_load_V{}));

  // Host side kernel arguments
  struct Arguments {
    ElementQ const *ptr_Q;
    StrideQ dQ;
    ElementK const *ptr_K;
    StrideK dK;
    ElementV const *ptr_V;
    StrideV dV;
  };

  struct Params {
    XE_Copy_Q gmem_tiled_copy_q;
    XE_Copy_K gmem_tiled_copy_k;
    XE_Copy_V gmem_tiled_copy_v;
  };

  //
  // Methods
  //

  CollectiveMmaAttention() = default;

  static constexpr Params to_underlying_arguments(ProblemShapeType const &problem_shape, Arguments const &args,
                                                  void *workspace) {
    (void)workspace;

    auto [batch, num_heads_q, num_heads_kv, seq_len_qo, seq_len_kv, head_size_qk, head_size_vo] = problem_shape;

    auto tensorQ = make_tensor(make_gmem_ptr(args.ptr_Q), make_layout(make_shape(seq_len_qo, head_size_qk, batch * num_heads_q), args.dQ));
    auto tensorK = make_tensor(make_gmem_ptr(args.ptr_K), make_layout(make_shape(seq_len_kv, head_size_qk, batch * num_heads_kv), args.dK));
    auto tensorV = make_tensor(make_gmem_ptr(args.ptr_V), make_layout(make_shape(head_size_vo, seq_len_kv, batch * num_heads_kv), args.dV));
    XE_Copy_Q copyQ{XE_Copy_Q{}.with(tensorQ)};
    XE_Copy_K copyK{XE_Copy_K{}.with(tensorK)};
    XE_Copy_V copyV{XE_Copy_V{}.with(tensorV)};
  
    return Params{copyQ, copyK, copyV};
  }

  template <class FragQccum, class TensorQ, class TensorK, class FragSrc>
  CUTLASS_DEVICE void mmaQK(FragQccum &accum, TensorQ gQ, TensorK gK, FragSrc const &frag_src,
                            int const &k_tile_count, Params const &params) {

    int thread_idx = static_cast<int>(ThreadIdxX());
    auto thr_copy_Q = params.gmem_tiled_copy_q.get_slice(thread_idx);
    auto thr_copy_K = params.gmem_tiled_copy_k.get_slice(thread_idx);
    // Instantiate the MMA object
    TiledMmaK tiled_mma_k;
    TiledMmaQVO tiled_mma_q;
    // To make all threads in a warp have the same global tensors pass in the index of thread 0 in each warp
    auto sg = syclcompat::get_nd_item<1>().get_sub_group();
    auto first_thread_in_sg_idx = sg.get_group_id()[0] * DispatchPolicy::SubgroupSize;
    auto thread_mma_k = tiled_mma_k.get_slice(first_thread_in_sg_idx);
    auto thread_mma_q = tiled_mma_q.get_slice(first_thread_in_sg_idx);

    // Partition
    Tensor tCgQ = thread_mma_q.partition_A(gQ);
    Tensor tCgK = thread_mma_k.partition_B(gK);

    // Create fragments
    // TODO(Codeplay): fix this, this is probably not general
    Tensor tCrQ = make_tensor<ElementQ>(make_fragment_layout(params.gmem_tiled_copy_q, take<0,3>(tCgQ.shape())));
    Tensor tCrK = make_tensor<ElementK>(make_fragment_layout(params.gmem_tiled_copy_k, take<0,3>(tCgK.shape())));
    
    // Retile registers for copies
    Tensor tQrQ = thr_copy_Q.retile_D(tCrQ);
    Tensor tKrK = thr_copy_K.retile_D(tCrK);

    // Retile global tile for copies
    Tensor tQgQ = thr_copy_Q.retile_S(tCgQ);
    Tensor tKgK = thr_copy_K.retile_S(tCgK);

#if CUTLASS_ENABLE_DEBUG_PRINTS
#define PRINT(x) print(#x ": "); print(x); print("\n");
  if (cute::thread(LOG_THREAD, LOG_GROUP)) {
    print("======================= Q: \n");
    PRINT(gQ);
    PRINT(tCrQ);
    PRINT(tCgQ);
    PRINT(tQrQ);
    PRINT(tQgQ);

    print("=====================  K :\n");
    PRINT(gK);
    PRINT(tCrK);
    PRINT(tCgK);
    PRINT(tKrK);
    PRINT(tKgK);

    print("=====================  Config: \n");
    PRINT(MaxThreadsPerBlock);
    PRINT(SubgroupTileShapeQK{});
  }
  #undef PRINT
#endif

    //
    // Mainloop
    //

    for (int k_tile = 0; k_tile < k_tile_count; ++k_tile) {
      copy(params.gmem_tiled_copy_q, tQgQ(_,_,_,k_tile), tQrQ);
      copy(params.gmem_tiled_copy_k, tKgK(_,_,_,k_tile), tKrK);
      cute::gemm(tiled_mma_q, accum, tCrQ, tCrK, frag_src);
    }
  }

  template <class FragQccum, class FragS, class TensorV, class FragSrc>
  CUTLASS_DEVICE void mmaPV(FragQccum &accum, FragS const &tSr, TensorV gV,
                            FragSrc const &frag_src, Params const &params) {

    int thread_idx = static_cast<int>(ThreadIdxX());
    // Instantiate the MMA object
    TiledMmaQVO tiled_mma;
    auto sg = syclcompat::get_nd_item<1>().get_sub_group();
    auto first_thread_in_sg_idx = sg.get_group_id()[0] * DispatchPolicy::SubgroupSize;
    auto thread_mma = tiled_mma.get_slice(first_thread_in_sg_idx);  
    Tensor tCgV = thread_mma.partition_B(gV);
    Tensor tCrV = make_tensor<ElementV>(make_fragment_layout(params.gmem_tiled_copy_v, tCgV.shape()));

    // Partition the copying of A and B tiles across the threads
    auto gmem_thr_copy_V = params.gmem_tiled_copy_v.get_slice(thread_idx);
    Tensor tVrV = gmem_thr_copy_V.retile_D(tCrV);
    Tensor tVgV = gmem_thr_copy_V.retile_S(tCgV);

#if CUTLASS_ENABLE_DEBUG_PRINTS
#define PRINT(x) print(#x ": "); print(x); print("\n");
  if (cute::thread(LOG_THREAD, LOG_GROUP)) {
    print("=====================  V :\n");
    PRINT(gV);
    PRINT(tCrV);
    PRINT(tCgV);
    PRINT(tVrV);
    PRINT(tVgV);

    print("=====================  Config: \n");
    PRINT(MaxThreadsPerBlock);
    PRINT(SubgroupTileShapePV{});
  }
  #undef PRINT
#endif

    // 7) Convert S to P (FP32 -> BF16)
    Tensor tPr = convert_type<typename TiledMmaQVO::ValTypeA>(tSr);

    //
    // Mainloop
    //
    copy(params.gmem_tiled_copy_v, tVgV, tVrV);
    cute::gemm(tiled_mma, accum, tPr, tCrV, frag_src);
  }

  template <class ProblemShape>
  CUTLASS_DEVICE static constexpr Params get_updated_copies(Params const& params, ProblemShape const& problem_shape, int const& l_coord) {
    if constexpr (!is_var_len) {
      return params;
    } else {
      auto [batch, num_heads_q, num_heads_kv, seq_len_qo, seq_len_kv, head_size_qk, head_size_vo] = problem_shape;

      auto qo_cumulative_length = get<3>(problem_shape).cumulative_length;
      auto kv_cumulative_length = get<4>(problem_shape).cumulative_length;

      int offset_q = num_heads_q * head_size_qk * qo_cumulative_length[l_coord];
      int offset_k = num_heads_kv * head_size_qk * kv_cumulative_length[l_coord];
      int offset_v = num_heads_kv * head_size_vo * kv_cumulative_length[l_coord];

      auto q_traits = static_cast<traits_load_Q const&>(params.gmem_tiled_copy_q);
      ElementQ* q_ptr = (ElementQ*)q_traits.base_ptr;

      auto k_traits = static_cast<traits_load_K const&>(params.gmem_tiled_copy_k);
      ElementK* k_ptr = (ElementK*)k_traits.base_ptr;

      auto v_traits = static_cast<traits_load_V const&>(params.gmem_tiled_copy_v);
      ElementV* v_ptr = (ElementV*)v_traits.base_ptr;

      auto shape_q = make_shape(static_cast<int>(seq_len_qo), head_size_qk, num_heads_q);
      StrideQ stride_q = cutlass::make_cute_packed_stride(StrideQ{}, shape_q);

      auto shape_k = make_shape(static_cast<int>(seq_len_kv), head_size_qk, num_heads_kv);
      StrideK stride_k = cutlass::make_cute_packed_stride(StrideK{}, shape_k);

      auto shape_v = make_shape(head_size_vo, static_cast<int>(seq_len_kv), num_heads_kv);
      StrideV stride_v = cutlass::make_cute_packed_stride(StrideV{}, shape_v);

      auto tensorQ = make_tensor(make_gmem_ptr(q_ptr + offset_q), make_layout(shape_q, stride_q));
      auto tensorK = make_tensor(make_gmem_ptr(k_ptr + offset_k), make_layout(shape_k, stride_k));
      auto tensorV = make_tensor(make_gmem_ptr(v_ptr + offset_v), make_layout(shape_v, stride_v));

      XE_Copy_Q copyQ{XE_Copy_Q{}.with(tensorQ)};
      XE_Copy_K copyK{XE_Copy_K{}.with(tensorK)};
      XE_Copy_V copyV{XE_Copy_V{}.with(tensorV)};

      return Params{copyQ, copyK, copyV};
    }
  }
};

} // namespace cutlass::flash_attention::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
