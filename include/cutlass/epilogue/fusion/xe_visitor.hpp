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

/*! \file
  \brief Visitor tree operations for the PVC epilogue
*/

#pragma once

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Elementwise Load Operations
//
/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::fusion {

template <
  class Element,
  class StrideMNL,
  class CopyOpG2R,
  bool EnableNullptr = true
>
struct XeAuxLoad {
  using SharedStorage = Element;

  struct Arguments {
    Element const* ptr_aux = nullptr;
    Element null_default = Element(0);
    StrideMNL dAux = {};
  };

  using Trait_Aux = Copy_Traits<CopyOpG2R>;
  using SubgroupSize = Int<size((typename Trait_Aux::ThrID){})>;
  using XE_Copy_Aux = decltype(make_tiled_copy(Copy_Atom<Trait_Aux, Element>{}
                      .with(static_cast<Element const*>(nullptr), int32_t(0), int32_t(0), int32_t(0)),
                         Layout<Shape<_1, SubgroupSize>>{},
                         make_layout(make_shape(get<0>(typename Trait_Aux::BlockShape{}),
                         get<1>(typename Trait_Aux::BlockShape{}) / SubgroupSize{}))));
  struct Params {
    XE_Copy_Aux xe_load_aux;
    Element null_default = Element(0);
    bool use_default = false;
  };

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    // Optionally append 1s until problem shape is rank-4 in case its is only rank-3 (MNK)
    auto problem_shape_mnkl = append<4>(problem_shape, 1);
    auto [M, N, K, L] = problem_shape_mnkl;
    // TODO(codeplay): This assumes a packed 2D (+ a batch dim) aux matrix
    static_assert(rank(decltype(args.dAux){}) == 3);
    auto N_AUX = get<0>(args.dAux); // dAux is a stride and N_AUX is a size
    auto M_AUX = size(M);
    XE_Copy_Aux xe_load_aux = make_tiled_copy(Copy_Atom<Trait_Aux, Element>{}.with(
                                  args.ptr_aux, M_AUX, N_AUX),
                                  Layout<Shape<_1, SubgroupSize>>{},
                                  make_layout(make_shape(get<0>(typename Trait_Aux::BlockShape{}),
                                                         get<1>(typename Trait_Aux::BlockShape{}) / SubgroupSize{})));

    bool use_default = false;
    if constexpr (EnableNullptr) {
      use_default = args.ptr_aux == nullptr;
    }

    return Params{xe_load_aux, args.null_default, use_default};
  }

  template <class ProblemShape>
  static bool
  can_implement(ProblemShape const& problem_shape, Arguments const& args) {
    return !find(args.dAux, 0); // auxillary matrix should have no strides with values 0
  }

  template <class ProblemShape>
  static size_t
  get_workspace_size(ProblemShape const& problem_shape, Arguments const& args) {
    return 0;
  }

  template <class ProblemShape>
  static cutlass::Status
  initialize_workspace(ProblemShape const& problem_shape, Arguments const& args, void* workspace, cudaStream_t stream,
    CudaHostAdapter* cuda_adapter = nullptr) {
    return cutlass::Status::kSuccess;
  }

  CUTLASS_HOST_DEVICE
  XeAuxLoad() { }

  CUTLASS_HOST_DEVICE
  XeAuxLoad(Params const& params, SharedStorage const&) : params_ptr(&params) { }

  Params const* params_ptr;

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    return false;
  }

  CUTLASS_DEVICE bool
  is_C_load_needed() const {
    return false;
  }

  CUTLASS_DEVICE bool
  is_zero() const {
    return (params_ptr->use_default && params_ptr->null_default == Element(0));
  }

  template <class... Args>
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(ProducerLoadArgs<Args...> const&) {
    return EmptyProducerLoadCallbacks{};
  }

  template <class CTensor, class RTensor>
  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CTensor rw_coord;                                                                           // (EPI_V, EPI_M, EPI_N)
    XE_Copy_Aux xe_copy_aux;
    RTensor tC_rAux;                                                                                // (CPY,CPY_M,CPY_N)
    Params const* params_ptr;

    CUTLASS_DEVICE
    ConsumerStoreCallbacks(CTensor rw_coord, XE_Copy_Aux xe_copy_aux, RTensor&& tC_rAux, Params const* params_ptr)
      : rw_coord(cute::forward<CTensor>(rw_coord)), xe_copy_aux(xe_copy_aux), tC_rAux(cute::forward<RTensor>(tC_rAux)), params_ptr(params_ptr) { }


    CUTLASS_DEVICE void
    previsit(int epi_m, int epi_n, int load_iteration, bool is_producer_load_needed) {
       if constexpr (EnableNullptr) {
         if (params_ptr->use_default) {
           fill(tC_rAux, params_ptr->null_default);
           return;
         }
       }

       copy(xe_copy_aux, rw_coord(_, epi_m, epi_n), tC_rAux);
    }

    // here is where we return values from the aux tile being processed
    template <typename ElementAccumulator, int FragmentSize>
    CUTLASS_DEVICE Array<Element, FragmentSize>
    visit(Array<ElementAccumulator, FragmentSize> const&, int epi_v, int, int) {
       Tensor tC_rAux_frg = recast<Array<Element, FragmentSize>>(coalesce(tC_rAux));                          // (EPI_V)
       return tC_rAux_frg(epi_v);

    }
  };

  template <
    bool ReferenceSrc,
    class... Args
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(ConsumerStoreArgs<Args...> const& args) {
    auto xe_copy_aux = params_ptr->xe_load_aux;
    Tensor trAux = make_tensor_like<Element>(args.tCrC);

    auto [M, N, K, L] = args.problem_shape_mnkl;
    auto [m_coord, n_coord, k_coord, l_coord] = args.tile_coord_mnkl;

    Tensor mAux_mnl = cute::get_pvc_tensor(make_shape(M,N,L));
    // Tiling is done differently than in epilogue as we get in coordinates of subgroup in kernel
    Tensor gAux = local_tile(mAux_mnl, select<0,1>(args.tile_shape_mnk), make_coord(m_coord,n_coord,l_coord));
    Tensor tCgAux = args.tiled_copy.get_thread_slice(args.thread_idx).partition_D(gAux);

    return ConsumerStoreCallbacks(
        tCgAux, xe_copy_aux, cute::move(trAux), params_ptr
    );
  }
};

template<
  int Stages,
  class CtaTileShapeMNK,
  class ElementInput_,
  class ElementCompute = cute::remove_pointer_t<ElementInput_>,
  class StrideMNL_ = Stride<_0,_1,_0>,
  int Alignment = 128 / sizeof_bits_v<cute::remove_pointer_t<ElementInput_>>,
  bool EnableNullptr = true // Fallback scalar broadcast for nullptr params
>
struct XeRowBroadcast {
  using StrideMNL = StrideMNL_;
  // Get base element input type.
  using ElementInput = cute::remove_pointer_t<ElementInput_>;
  // Check if input is an array of pointers.
  static constexpr bool IsArrayOfPointers = is_same_v<ElementInput*, ElementInput_>;
  using PtrRowType = cute::conditional_t<IsArrayOfPointers, ElementInput const* const*, ElementInput const*>;

  static_assert(Stages == 0, "Row broadcast doesn't support smem pipelining");

  static constexpr bool IsDynamicBroadcast = is_same_v<remove_cvref_t<decltype(get<1>(StrideMNL{}))>, bool>; // row vector or scalar broadcast
  static_assert(is_static_v<decltype(take<0,2>(StrideMNL{}))> || IsDynamicBroadcast, "XeRowBroadcast requires static MN stride for non-dynamic broadcast case."); // batch stride can be dynamic or static
  static_assert(take<0,2>(StrideMNL{}) == Stride<_0,_1>{} || IsDynamicBroadcast, "XeRowBroadcast requires MN stride=(0,1) for non-dynamic broadcast case.");

  struct SharedStorage { };

  struct Arguments {
    PtrRowType ptr_row = nullptr;
    ElementInput null_default = ElementInput(0);
    StrideMNL dRow = {};
  };

  struct Params {
    PtrRowType ptr_row = nullptr;
    ElementCompute null_default = ElementCompute(0);
    StrideMNL dRow = {};
  };

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    return {args.ptr_row, ElementCompute(args.null_default), args.dRow};
  }

  template <class ProblemShape>
  static bool
  can_implement(ProblemShape const& problem_shape, Arguments const& args) {
    return true;
  }

  template <class ProblemShape>
  static size_t
  get_workspace_size(ProblemShape const& problem_shape, Arguments const& args) {
    return 0;
  }

  template <class ProblemShape>
  static cutlass::Status
  initialize_workspace(ProblemShape const& problem_shape, Arguments const& args, void* workspace, cudaStream_t stream,
    CudaHostAdapter* cuda_adapter = nullptr) {
    return cutlass::Status::kSuccess;
  }

  CUTLASS_HOST_DEVICE
  XeRowBroadcast() { }

  CUTLASS_HOST_DEVICE
  XeRowBroadcast(Params const& params, SharedStorage const& shared_storage)
      : params(params), is_zero_(false) {
    auto const& [stride_M, stride_N, stride_L] = params.dRow;
    // Nullptr default
    if (EnableNullptr && params.ptr_row == nullptr) {
      is_zero_ = params.null_default == ElementCompute(0);
    }
    // Dynamic non-batched scalar broadcast
    else if (IsDynamicBroadcast && stride_N == bool(0) && stride_L == repeat_like(stride_L, 0)) {
       if constexpr (!IsArrayOfPointers) {
         is_zero_ = params.ptr_row[0] == ElementInput(0);
       }
    }
  }

  Params params;
  bool is_zero_ = false;
  ElementInput *smem = nullptr;

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    return false;
  }

  CUTLASS_DEVICE bool
  is_C_load_needed() const {
    return false;
  }

  CUTLASS_DEVICE bool
  is_zero() const {
    return is_zero_;
  }

  template <class... Args>
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(ProducerLoadArgs<Args...> const& args) {
    return EmptyProducerLoadCallbacks{};
  }

  template<class GTensor, class RTensor, class CTensor, class ThrResidue>
  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(GTensor tCgRow_, RTensor tCrRow_, CTensor tCcRow_, ThrResidue residue_tCcRow_, Params const& params_)
      : tCgRow(tCgRow_),
        tCrRow(tCrRow_),
        tCcRow(tCcRow_),
        residue_tCcRow(residue_tCcRow_),
        params(params_) {
      if (EnableNullptr && params.ptr_row == nullptr) {
        fill(tCrRow, params.null_default);
      }
    }

    GTensor tCgRow;                                                                    // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    RTensor tCrRow;                                                                    // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    CTensor tCcRow;                                                                    // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    ThrResidue residue_tCcRow;
    Params const& params;

    CUTLASS_DEVICE void
    begin() {
      if (EnableNullptr && params.ptr_row == nullptr) {
        return;
      }

      // Filter so we don't issue redundant copies over stride-0 modes
      // (only works if 0-strides are in same location, which is by construction)
      Tensor tCgRow_flt = filter_zeros(tCgRow);
      Tensor tCrRow_flt = make_tensor_like<ElementInput>(filter_zeros(tCrRow));
      Tensor tCcRow_flt = filter_zeros(tCcRow, tCgRow.stride());

      constexpr auto MCL = decltype(max_common_layout(tCgRow_flt, tCrRow_flt)){};
      constexpr int V = cute::min(Alignment, size(MCL));
      if constexpr (V > 1) {
        using VecType = uint_bit_t<V * sizeof_bits_v<ElementInput>>;
        Tensor tCgRow_vec = recast<VecType>(coalesce(tCgRow_flt));
        Tensor tCrRow_vec = recast<VecType>(coalesce(tCrRow_flt));
        Tensor tCcRow_vec = tensor<1>(zipped_divide(tCcRow_flt, MCL.compose(Int<V>{})));
        auto pred_fn = [&](auto const &...coords) CUTLASS_LAMBDA_FUNC_INLINE {
          return elem_less(tCcRow_vec(coords...), residue_tCcRow);
        };
        copy_if(pred_fn, tCgRow_vec, tCrRow_vec);
      } else {
        auto pred_fn = [&](auto const &...coords) CUTLASS_LAMBDA_FUNC_INLINE {
          return elem_less(tCcRow_flt(coords...), residue_tCcRow);
        };
        copy_if(pred_fn, tCgRow_flt, tCrRow_flt);
      }

      constexpr int FrgSize = size(tCrRow_flt);
      using FrgInput = Array<ElementInput, FrgSize>;
      using FrgCompute = Array<ElementCompute, FrgSize>;
      using ConvertInput = NumericArrayConverter<ElementCompute, ElementInput, FrgSize>;

      Tensor tCrRow_input_frg = recast<FrgInput>(coalesce(tCrRow_flt));
      Tensor tCrRow_compute_frg = recast<FrgCompute>(filter(tCrRow));
      ConvertInput convert_input{};
      tCrRow_compute_frg(_0{}) = convert_input(tCrRow_input_frg(_0{}));
    }

    template <typename ElementAccumulator, int FragmentSize>
    CUTLASS_DEVICE Array<ElementCompute, FragmentSize>
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n) {
      Array<ElementCompute, FragmentSize> frg_row;
      Tensor tCrRow_mn = tCrRow(_,_,_,epi_m,epi_n);

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < FragmentSize; ++i) {
        frg_row[i] = tCrRow_mn(epi_v * FragmentSize + i);
      }

      return frg_row;
    }
  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class... Args
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(ConsumerStoreArgs<Args...> const& args) {
    auto [M, N, K, L] = args.problem_shape_mnkl;
    auto [m, n, k, l] = args.tile_coord_mnkl;

    auto layout_N = [&] () CUTLASS_LAMBDA_FUNC_INLINE {
      auto shape_N = get<1>(args.problem_shape_mnkl);
      if constexpr (IsDynamicBroadcast) {
        auto stride_N = repeat_like(shape_N, int(0));
        if (get<1>(params.dRow) == bool(1)) {
          stride_N = transform_leaf(compact_major<LayoutLeft>(shape_N),
            [] (auto const& stride) { return static_cast<int>(stride); }
          );
        }
        return make_layout(shape_N, stride_N);
      }
      else {
        return make_layout(shape_N);
      }
    }();

    auto layout_M = make_layout(M, repeat_like(M, _0{}));
    auto layout_L = make_layout(L, get<2>(params.dRow));
    ElementInput const* ptr_row;
    if constexpr(IsArrayOfPointers) {
      ptr_row = params.ptr_row[l];
    } else {
      ptr_row = params.ptr_row;
    }
  // TODO(Codeplay): id_in_sg instead of thread_idx here because incorrect tiled copy definition
    int id_in_sg = syclcompat::get_nd_item<1>().get_sub_group().get_local_id();
    Tensor mRow = make_tensor(make_gmem_ptr(ptr_row), make_layout(layout_M,layout_N,layout_L));
    Tensor tCgRow = sm90_partition_for_epilogue<ReferenceSrc>(                         // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
      mRow, args.tile_shape_mnk, args.tile_coord_mnkl, args.epi_tile, args.tiled_copy, id_in_sg);

    Tensor mRow_static = make_tensor(make_gmem_ptr(ptr_row), make_layout(layout_M, make_layout(N),layout_L));
    Tensor tCgRow_static = sm90_partition_for_epilogue<ReferenceSrc>(                  // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
      mRow_static, args.tile_shape_mnk, args.tile_coord_mnkl, args.epi_tile, args.tiled_copy, id_in_sg);
    Tensor tCrRow = make_tensor_like<ElementCompute>(tCgRow_static);                   // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    
    return ConsumerStoreCallbacks(tCgRow, tCrRow, args.tCcD, args.residue_tCcD, params);
  }
};
} // namespace cutlass::epilogue::fusion
