/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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
  \brief Functor performing elementwise operations used by epilogues.
*/

#pragma once

#include <sycl/sycl.hpp>
#include "cutlass/cutlass.h"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_epilogue.hpp"
#include "cutlass/epilogue/collective/detail.hpp"
#include "cutlass/detail/layout.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace flash_attention {
namespace collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <class DispatchPolicy, class MMAOperation_, class TileShapeOutput_, class SubgroupLayout_, class... Args> class FlashPrefillCachedEpilogue {
  static_assert(cutlass::detail::dependent_false<DispatchPolicy>, "Could not find an epilogue specialization.");
};

template <class MMAOperation_, class TileShapeOutput_, class SubgroupLayout_, class ElementCompute_, class ElementO_, class StrideO_, class ElementLSE_, class CopyOpO_>
class FlashPrefillCachedEpilogue<epilogue::IntelXeXMX16,  MMAOperation_, TileShapeOutput_, SubgroupLayout_, ElementCompute_, ElementO_, StrideO_, ElementLSE_, CopyOpO_> {
public:
  //
  // Type Aliases
  //
  using DispatchPolicy = epilogue::IntelXeXMX16;
  using ElementO = ElementO_;
  using StrideO = StrideO_;
  using ElementLSE = ElementLSE_;
  using CopyOpO = CopyOpO_;
  using SubgroupLayout = SubgroupLayout_;
  using TileShapeOutput = TileShapeOutput_;
  using TiledMmaOutput = typename TiledMMAHelper<MMA_Atom<MMAOperation_>, Layout<TileShapeOutput>, SubgroupLayout>::TiledMMA;
  using GmemTiledCopyO = CopyOpO;
  using ElementOutput = ElementO_;
  using ElementCompute = ElementCompute_;
  using ElementAccumulator = ElementCompute_;
  using SubgroupTileShape = decltype(cute::shape_div(TileShapeOutput{}, (SubgroupLayout{}.shape())));

  static constexpr int SubgroupSize = DispatchPolicy::SubgroupSize;

  static_assert(cute::rank(TileShapeOutput{}) == 3, "TileShapeOutput must be rank-3: [CTA_M_QO, CTA_N_VO, CTA_K_PV]");
  static_assert(cute::rank(StrideO{}) == 3, "StrideO must be rank-3: [seq_len_qo, head_size_vo, batch * num_heads]");

  using CopyThreadShape = Shape<_1, Int<SubgroupSize>>;
  
  using traits_store_O = Copy_Traits<GmemTiledCopyO, StrideO>;
  using atom_load_O = Copy_Atom<traits_store_O, ElementO>;
  using val_layout_load_O = decltype(make_layout(shape_div(typename traits_store_O::BlockShape{}, CopyThreadShape{})));
  using XE_Copy_O = decltype(make_tiled_copy(atom_load_O{}, Layout<CopyThreadShape>{}, val_layout_load_O{}));

private:
  constexpr static bool is_destination_supported = not cute::is_void_v<ElementO>;

public:
  using EmptyType = cute::tuple<>;

  struct TensorStorageImpl : cute::tuple<EmptyType, EmptyType> {};

  struct SharedStorage {
    using TensorStorage = TensorStorageImpl;

    TensorStorage tensors;
  };
  using TensorStorage = typename SharedStorage::TensorStorage;

  // Host side epilogue arguments
  struct Arguments {
    ElementO const *ptr_O;
    StrideO dO;
  };

  // Device side epilogue params
  struct Params {
    XE_Copy_O xe_store_o;
  };

  //
  // Methods
  //

  template <class ProblemShape>
  static constexpr Params to_underlying_arguments(ProblemShape const &problem_shape, Arguments const &args,
                                                  [[maybe_unused]] void *workspace) {
    auto [batch, num_heads_q, num_heads_kv, seq_len_qo, seq_len_kv, seq_len_kv_cache, head_size_qk, head_size_vo] = problem_shape;

    auto tensorO = make_tensor(make_gmem_ptr(static_cast<ElementO const*>(args.ptr_O)), 
                                                  make_layout(make_shape(seq_len_qo, head_size_vo, batch * num_heads_q), 
                                                  args.dO));
    XE_Copy_O xe_store_o{XE_Copy_O{}.with(tensorO)};
    return {
        xe_store_o,
    };
  }

  template <class ProblemShape>
  static size_t get_workspace_size(ProblemShape const &problem_shape, Arguments const &args) {
    return 0;
  }

  template <class ProblemShape>
  static cutlass::Status initialize_workspace(ProblemShape const &problem_shape, Arguments const &args, void *workspace,
                                              cudaStream_t stream, CudaHostAdapter *cuda_adapter = nullptr) {
    return Status::kSuccess;
  }

  template <class ProblemShape>
  CUTLASS_HOST_DEVICE static bool can_implement(ProblemShape const &problem_shape,
                                                [[maybe_unused]] Arguments const &args) {
    return true;
  }

  CUTLASS_HOST_DEVICE
  FlashPrefillCachedEpilogue(Params const &params_, TensorStorage const &) : params(params_) {}

  template <class ProblemShape, class SequenceLengthShape, class TileCoord, class FragOut, class FragMax, class FragSum>
  CUTLASS_DEVICE void operator()(ProblemShape problem_shape, SequenceLengthShape sequence_length_shape, TileCoord tile_coord, FragOut &out,
                                 FragMax const &max,FragSum &sum) {

    using namespace cute;

    static constexpr bool is_var_len = cutlass::fmha::collective::is_variable_length_v<tuple_element_t<2, ProblemShape>>;
  
    using FragOutLayout = typename FragOut::layout_type;

    constexpr int Vec    = shape<0>(FragOutLayout{});
    constexpr int FragsM = shape<1>(FragOutLayout{});
    constexpr int FragsN = size(select<2,3>(shape(FragOutLayout{})));

    auto g = compat::get_nd_item<1>().get_sub_group();
    auto out_reg = make_tensor(static_cast<decltype(out) &&>(out).data() , Shape<Int<Vec>, Int<FragsM>, Int<FragsN>>{});

    CUTLASS_PRAGMA_UNROLL
    for (int y = 0; y < FragsM; y++) {
      CUTLASS_PRAGMA_UNROLL
      for (int x = 0; x < Vec; x++) {
        int indx = y * Vec + x;
        auto cur_sum = reduce_over_group(g, sum(indx), sycl::plus<>());
        auto cur_scale = (cur_sum == 0.f || cur_sum != cur_sum) ? 1.0f : sycl::native::recip(cur_sum);
        CUTLASS_PRAGMA_UNROLL
        for (int z = 0; z < FragsN; z++) {
          out_reg(x, y, z) *= cur_scale;
        }
      }
    }

    // Indexing variables
    auto [batch, num_heads_q, head_size_vo] = select<0, 1, 7>(problem_shape);
    auto [seq_len_qo] = select<0>(sequence_length_shape);
    // Represent the full output tensor
    Tensor mO_mnl = cute::get_xe_tensor(make_shape(seq_len_qo, head_size_vo, (is_var_len ? batch : 1) * num_heads_q));
    
    auto [m_coord, n_coord, k_coord, l_coord] = tile_coord;
    // Tile the output tensor per WG
    Tensor g_wg_O = local_tile(mO_mnl, select<0,1>(TileShapeOutput{}), make_coord(m_coord,n_coord,l_coord));             // (BLK_M,BLK_N,m,n,l)
    static constexpr auto ATOM_N = get<2>(typename TiledMmaOutput::ThrLayoutVMNK{}.shape());
    auto m_sg = get_sub_group_id() / ATOM_N;
    auto n_sg = get_sub_group_id() % ATOM_N;
    // Tile the output tensor per SG
    Tensor gO = local_tile(g_wg_O, SubgroupTileShape{}, make_coord(m_sg,n_sg,_), Step<_1,_1, X>{});             // (BLK_M,BLK_N,m,n,l)
    auto thread_xe_store_o = params.xe_store_o.get_thread_slice(ThreadIdxX());
    Tensor tOgO = thread_xe_store_o.partition_D(gO);

    Tensor final_out_reg = make_fragment_like<ElementOutput>(out_reg);
    // iff ElementOutput == ElementAccumulator, then convert_type doesn't do the right conversion
    // so we call copy() which internally performs a static_cast op on the data.
    // for ElementOutput == bf16 | fp16, convert_type calls relevant NumericConverter specialization.    
    if constexpr (cute::is_same_v<ElementOutput, ElementCompute>) {
      copy(out_reg, final_out_reg);
    } else {
      Tensor temp = convert_type<ElementOutput>(out_reg);
      copy(temp, final_out_reg);
    }
    copy(params.xe_store_o, final_out_reg, tOgO);
  }

  // SequenceLengthShapeType = Shape<int, int, int>
  // For Fixed Sequence Length, ProblemShapeType = Shape<int, int, int, int, int, int, int, int>
  // For Variable Sequence Length, ProblemShapeType = Shape<int, int, int, VariableSeqlen, VariableSeqlen, VariableSeqlen, int, int>
  template <bool VarLen, class ProblemShapeType, class SequenceLengthShapeType>
  CUTLASS_DEVICE static constexpr Params get_updated_copies(Params const& params, ProblemShapeType const& problem_shape, 
                                                            SequenceLengthShapeType const& sequence_length_shape, int const& l_coord) {
    if constexpr (!VarLen) {
      return params;
    } else {
      auto [num_heads_q, head_size_vo] = select<1, 7>(problem_shape);
      auto [seq_len_qo] = select<0>(sequence_length_shape);

      auto qo_cumulative_length = get<3>(problem_shape).cumulative_length;
      int offset_o = num_heads_q * head_size_vo * qo_cumulative_length[l_coord];
      auto store_traits = static_cast<traits_store_O const&>(params.xe_store_o);

      ElementO* base_ptr = (ElementO*)store_traits.base_ptr;
      auto shape_o = make_shape(static_cast<int>(seq_len_qo), head_size_vo, num_heads_q);
      StrideO stride_o = cutlass::make_cute_packed_stride(StrideO{}, shape_o);

      auto tensorO = make_tensor(make_gmem_ptr(base_ptr + offset_o), make_layout(shape_o, stride_o));
      XE_Copy_O xe_store_o{XE_Copy_O{}.with(tensorO)};

      return Params{xe_store_o};
    }
  }

private:
  Params const &params;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace collective
} // namespace flash_attention
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
