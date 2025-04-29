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

template <class DispatchPolicy, class... Args> class FlashDecodeEpilogue {
  static_assert(cutlass::detail::dependent_false<DispatchPolicy>, "Could not find an epilogue specialization.");
};

template <class CtaTileMNK_, class ElementO_, class StrideO_, class ElementLSE_, class CopyOpO_>
class FlashDecodeEpilogue<epilogue::IntelPVCEpilogue, CtaTileMNK_, ElementO_, StrideO_, ElementLSE_, CopyOpO_> {
public:
  //
  // Type Aliases
  //
  using DispatchPolicy = epilogue::IntelPVCEpilogue;
  using CtaTileMNK = CtaTileMNK_;
  using ElementO = ElementO_;
  using ElementAccumulator = ElementO_;
  using StrideO = StrideO_;
  using ElementLSE = ElementLSE_;
  using CopyOpO = CopyOpO_;

  using GmemTiledCopyO = CopyOpO;
  using ElementOutput = ElementO_;
  using ElementCompute = ElementO_;

  static constexpr int SubgroupSize = DispatchPolicy::SubgroupSize;

  static_assert(cute::rank(CtaTileMNK{}) == 4, "CtaTileMNK must be rank-4: [CTA_M_Q, CTA_N_V, CTA_N_QK, CTA_K_QK]");
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
  FlashDecodeEpilogue(Params const &params_, TensorStorage const &) : params(params_) {}

  template <class ProblemShape, class TileShape, class TileCoord, class STensorOut, class FragSum, class STensorSum, class TiledMma>
  CUTLASS_DEVICE void operator()(ProblemShape problem_shape, TileShape tile_shape, TileCoord tile_coord, STensorOut &shmem_tensor_out,
                                 FragSum &sum, STensorSum& shmem_tensor_sum, TiledMma tiled_mma) {

    using namespace cute;

    using MmaAtomShape = typename TiledMma::AtomShape_MNK;
    using TempShape = decltype(cute::shape_div(take<1, 3>(tile_shape), take<2, 4>(typename TiledMma::ThrLayoutVMNK{}.shape())));
    using SubgroupTileShape = decltype(make_shape(get<0>(tile_shape), get<0>(TempShape{}), get<1>(TempShape{})));
    using FragsShape = decltype(cute::shape_div(take<0, 2>(SubgroupTileShape{}), take<0, 2>(MmaAtomShape())));
    static constexpr bool is_var_len = cutlass::fmha::collective::is_variable_length_v<tuple_element_t<2, ProblemShape>>;
  
    static constexpr int FragsM = get<0>(FragsShape{}); // A frags per sub_group
    static constexpr int FragsN = get<1>(FragsShape{}); // B frags per sub_group
    static constexpr int Vec = (get<0>(MmaAtomShape()) * get<1>(MmaAtomShape())) / SubgroupSize;
    static constexpr int ATOM_M = get<1>(typename TiledMma::ThrLayoutVMNK{}.shape());
    static constexpr int ATOM_N = get<2>(typename TiledMma::ThrLayoutVMNK{}.shape());

    auto sg = syclcompat::get_nd_item<1>().get_sub_group();
    auto group = syclcompat::get_nd_item<1>().get_group();
    const int sg_local_id = sg.get_local_id()[0];
    const int sg_group_id = sg.get_group_id()[0];

    // reduce sum across the whole workgroup through SLM
    // rest of the epilogue stays the same as prefill

    CUTLASS_PRAGMA_UNROLL
    for (int y = 0; y < FragsM; y++) {
      CUTLASS_PRAGMA_UNROLL
      for (int x = 0; x < Vec; x++) {
        int indx = y * Vec + x;
        auto cur_sum = reduce_over_group(sg, sum(indx), sycl::plus<>());

        if(sg_local_id == 0) {
          shmem_tensor_sum(indx + sg_group_id * FragsM * Vec) = cur_sum;
        }
      }
    }

    sycl::group_barrier(group);

    Tensor out_reg = make_tensor<ElementOutput>(make_shape(Int<Vec>{}, Int<FragsM>{}, Int<FragsN>{}));

    // only ATOM_N subgroups are needed to do reduction across the whole workgroup
    // using SLM, and write the final output to Global Memory.

    if(sg_group_id < ATOM_N) {
      CUTLASS_PRAGMA_UNROLL
      for (int y = 0; y < FragsM; y++) {
        CUTLASS_PRAGMA_UNROLL
        for (int x = 0; x < Vec; x++) {
          int indx = y * Vec + x;
          ElementCompute cur_sum = ElementCompute{0};
          CUTLASS_PRAGMA_UNROLL
          for(int i = 0; i < ATOM_M * ATOM_N; i ++) {
            if (i % ATOM_N == sg_group_id) {
              cur_sum += shmem_tensor_sum(i * Vec * FragsM + indx);
            }
          }

          auto cur_scale = (cur_sum == 0.f || cur_sum != cur_sum) ? 1.f : sycl::native::recip(cur_sum);

          CUTLASS_PRAGMA_UNROLL
          for (int z = 0; z < FragsN; z++) {
            auto base_indx = indx + (z * Vec * FragsM);
            const int slm_curr_idx = sg_local_id + base_indx * SubgroupSize;

            ElementOutput out_val_curr = ElementOutput{0};
            CUTLASS_PRAGMA_UNROLL
            for(int i = 0; i < ATOM_M * ATOM_N; i++) {
              if (i % ATOM_N == sg_group_id) {
               auto out_val_prev = shmem_tensor_out(slm_curr_idx + i * out_reg.size() * SubgroupSize);
               out_val_curr += out_val_prev;
              }
            }

            out_reg(x, y, z) = out_val_curr * cur_scale;
          }
        }
      }

      // Indexing variables
      auto [batch, num_heads_q, seq_len_qo, head_size_vo] = select<0, 1, 3, 7>(problem_shape);
      // Represent the full output tensor
      Tensor mO_mnl = cute::get_pvc_tensor(make_shape(seq_len_qo, head_size_vo, (is_var_len ? batch : 1) * num_heads_q));
      
      auto [m_coord, n_coord, k_coord, l_coord] = tile_coord;
      // Tile the output tensor per WG
      Tensor g_wg_O = local_tile(mO_mnl, select<0,1>(tile_shape), make_coord(m_coord,n_coord,l_coord));             // (BLK_M,BLK_N,m,n,l)
      const int m_sg = 0;
      const int n_sg = sg_group_id;
      // Tile the output tensor per SG
      Tensor gO = local_tile(g_wg_O, SubgroupTileShape{}, make_coord(m_sg, n_sg, _), Step<_1,_1, X>{});             // (BLK_M,BLK_N,m,n,l)

      auto thread_xe_store_o = params.xe_store_o.get_thread_slice(ThreadIdxX());
      Tensor tOgO = thread_xe_store_o.partition_D(gO);

      copy(params.xe_store_o, out_reg, tOgO);
    }
  }

  template <bool VarLen, class ProblemShapeType>
  CUTLASS_DEVICE static constexpr Params get_updated_copies(Params const& params, ProblemShapeType const& problem_shape, int const& l_coord) {
    if constexpr (!VarLen) {
      return params;
    } else {
      auto [batch, num_heads_q, seq_len_qo, head_size_vo] = select<0, 1, 3, 7>(problem_shape);

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
