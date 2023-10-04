/***************************************************************************************************
 * Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
  \brief Visitor tree store operations for the sm90 TMA warp-specialized (ws) epilogue
*/

#pragma once

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"
#include "sm90_visitor_tma_warpspecialized.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::fusion {

using namespace cute;
using namespace detail;

/////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Elementwise Store Operations
//
/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  int Stages,
  class EpilogueTile,
  class Element,
  FloatRoundStyle RoundStyle,
  class StrideMNL,
  class SmemLayoutAtom,
  class CopyOpR2S,
  int Alignment = 128 / sizeof_bits_v<Element>,
  bool EnableNullptr = true // Noop on nullptr params
>
struct Sm90AuxStore {
  static_assert(Alignment * sizeof_bits_v<Element> % 128 == 0, "sub-16B alignment not supported yet");

  constexpr static bool is_m_major = epilogue::collective::detail::is_m_major<StrideMNL>();
  // Find the max contiguous layout usable by TMA (if EpilogueTile is a non-compact tiler)
  using SmemShapeTma = decltype(make_shape(
      max_common_vector(make_layout(get<0>(EpilogueTile{})),make_layout(get<0>(EpilogueTile{}))),
      max_common_vector(make_layout(get<1>(EpilogueTile{})),make_layout(get<1>(EpilogueTile{})))));
  using SmemLayoutTma = decltype(tile_to_shape(
      SmemLayoutAtom{}, SmemShapeTma{},
      cute::conditional_t<is_m_major, Step<_2,_1>, Step<_1,_2>>{} ));
  using SmemLayout = decltype(tile_to_shape(
      SmemLayoutTma{},
      make_shape(size<0>(shape(EpilogueTile{})), size<1>(shape(EpilogueTile{})), Int<Stages>{}),
      cute::conditional_t<is_m_major, Step<_2,_1,_3>, Step<_1,_2,_3>>{} ));

  struct SharedStorage {
    alignas(cutlass::detail::alignment_for_swizzle(SmemLayout{}))
    array_aligned<Element, size(SmemLayout{})> smem_aux;
  };

  struct Arguments {
    Element* ptr_aux = nullptr;
    StrideMNL dAux = {};
  };

  struct Params {
    using TMA_Aux = decltype(make_tma_copy(
        SM90_TMA_STORE{},
        make_tensor(static_cast<Element*>(nullptr), repeat_like(StrideMNL{}, int32_t(0)), StrideMNL{}),
        SmemLayoutTma{}));
    TMA_Aux tma_store_aux;
    bool is_nullptr = false;
  };

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    // Optionally append 1s until problem shape is rank-4 in case its is only rank-3 (MNK)
    auto problem_shape_mnkl = append<4>(problem_shape, 1);
    auto [M, N, K, L] = problem_shape_mnkl;

    bool is_nullptr = false;
    if constexpr (EnableNullptr) {
      is_nullptr = args.ptr_aux == nullptr;
    }

    typename Params::TMA_Aux tma_store_aux;
    if (not is_nullptr) {
      Tensor tensor_aux = make_tensor(args.ptr_aux, make_layout(make_shape(M,N,L), args.dAux));
      tma_store_aux = make_tma_copy(SM90_TMA_STORE{}, tensor_aux, SmemLayoutTma{});
    }

    return {tma_store_aux, is_nullptr};
  }

  CUTLASS_HOST_DEVICE
  Sm90AuxStore() { }

  CUTLASS_HOST_DEVICE
  Sm90AuxStore(Params const& params, SharedStorage const& shared_storage)
      : params_ptr(&params),
        smem_aux(const_cast<Element*>(shared_storage.smem_aux.data())) { }

  Params const* params_ptr;
  Element* smem_aux;

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    return false;
  }

  CUTLASS_DEVICE bool
  is_C_load_needed() const {
    return false;
  }

  template <
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL
  >
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK tile_shape_mnk,
      TileCoordMNKL tile_coord_mnkl,
      EpilogueTile epi_tile,
      int thread_idx) {
    return EmptyProducerLoadCallbacks{};
  }

  template <
    class RTensor,
    class TiledR2S,
    class STensorR2S,
    class STensorS2G,
    class GTensorS2G
  >
  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(
          RTensor&& tC_rAux,
          TiledR2S tiled_r2s,
          STensorR2S&& tRS_sAux,
          STensorS2G&& bSG_sAux,
          GTensorS2G&& bSG_gAux,
          Params const* params_ptr)
      : tiled_r2s(tiled_r2s),
        tC_rAux(cute::forward<RTensor>(tC_rAux)),
        tRS_sAux(cute::forward<STensorR2S>(tRS_sAux)),
        bSG_sAux(cute::forward<STensorS2G>(bSG_sAux)),
        bSG_gAux(cute::forward<GTensorS2G>(bSG_gAux)),
        params_ptr(params_ptr) {}

    TiledR2S tiled_r2s;
    RTensor tC_rAux;                                                                   // (CPY,CPY_M,CPY_N)
    STensorR2S tRS_sAux;                                                               // (R2S,R2S_M,R2S_N,PIPE)
    STensorS2G bSG_sAux;                                                               // (S2G,S2G_M,S2G_N,PIPE)
    GTensorS2G bSG_gAux;                                                               // (S2G,S2G_M,S2G_N,EPI_M,EPI_N)
    Params const* params_ptr;

    template <typename ElementAccumulator, typename ElementInput, int FragmentSize>
    CUTLASS_DEVICE auto
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n,
          Array<ElementInput, FragmentSize> const& frg_input) {
      using ConvertInput = NumericArrayConverter<Element, ElementInput, FragmentSize, RoundStyle>;
      ConvertInput convert_input{};

      Tensor tC_rAux_frg = recast<Array<Element, FragmentSize>>(coalesce(tC_rAux));                          // (EPI_V)
      tC_rAux_frg(epi_v) = convert_input(frg_input);

      return frg_input;
    }

    CUTLASS_DEVICE void
    step_next(int epi_m, int epi_n, int store_iteration, bool issue_smem_store) {
      if constexpr (EnableNullptr) {
        if (params_ptr->is_nullptr) {
          return;
        }
      }

      using RLayoutR2S = decltype(cute::layout(TiledR2S{}.get_slice(0).retile_S(RTensor{})));
      Tensor tRS_rAux = make_tensor(tC_rAux.data(), RLayoutR2S{});                                 // (R2S,R2S_M,R2S_N)

      if (issue_smem_store) {
        int store_pipe_index = store_iteration % Stages;
        copy(tiled_r2s, tRS_rAux, tRS_sAux(_,_,_,store_pipe_index));
      }
    }

    CUTLASS_DEVICE void
    step_end(int epi_m, int epi_n, int store_iteration, bool issue_tma_store) {
      if constexpr (EnableNullptr) {
        if (params_ptr->is_nullptr) {
          return;
        }
      }

      if (issue_tma_store) {
        // Issue the TMA store
        int store_pipe_index = store_iteration % Stages;
        copy(params_ptr->tma_store_aux, bSG_sAux(_,_,_,store_pipe_index), bSG_gAux(_,_,_,epi_m,epi_n));
      }
    }
  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class TiledCopy,
    class SrcTensor
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK tile_shape_mnk,
      TileCoordMNKL tile_coord_mnkl,
      EpilogueTile epi_tile,
      TiledCopy tiled_copy,
      int thread_idx,
      SrcTensor const& tCrC) {

    auto [M, N, K, L] = problem_shape_mnkl;
    auto [m, n, k, l] = tile_coord_mnkl;
    Tensor mAux = params_ptr->tma_store_aux.get_tma_tensor(make_shape(M,N,L));                               // (M,N,L)
    Tensor gAux = local_tile(mAux, take<0,2>(tile_shape_mnk), make_coord(m,n,l));                      // (CTA_M,CTA_N)

    Tensor tC_gAux = sm90_partition_for_epilogue<ReferenceSrc>(                        // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
                      gAux, epi_tile, tiled_copy, thread_idx);
    Tensor tC_rAux = make_tensor<Element>(take<0,3>(shape(tC_gAux)));                  // (CPY,CPY_M,CPY_N)

    Tensor sAux_epi = cute::as_position_independent_swizzle_tensor(
                        make_tensor(make_smem_ptr(smem_aux), SmemLayout{}));     // (EPI_TILE_M,EPI_TILE_N,PIPE)
    Tensor gAux_epi = local_tile(gAux, epi_tile, _);                             // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)

    auto tiled_r2s = conditional_return<ReferenceSrc>(
      make_tiled_copy_S(Copy_Atom<CopyOpR2S,Element>{}, tiled_copy),
      make_tiled_copy_D(Copy_Atom<CopyOpR2S,Element>{}, tiled_copy)
    );
    auto tRS_sAux = tiled_r2s.get_slice(thread_idx).partition_D(sAux_epi);                    // (R2S,R2S_M,R2S_N,PIPE)

    ThrCopy thrblk_s2g = params_ptr->tma_store_aux.get_slice(_0{});
    Tensor bSG_sAux = thrblk_s2g.partition_S(sAux_epi);                                // (TMA,TMA_M,TMA_N,PIPE)
    Tensor bSG_gAux = thrblk_s2g.partition_D(gAux_epi);                                // (TMA,TMA_M,TMA_N,EPI_M,EPI_N)

    return ConsumerStoreCallbacks(
            cute::move(tC_rAux),
            tiled_r2s,
            cute::move(tRS_sAux),
            cute::move(bSG_sAux),
            cute::move(bSG_gAux),
            params_ptr);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Reduction Store Operations
//
/////////////////////////////////////////////////////////////////////////////////////////////////

// Scalar reduction
template <
  template <class> class RegReduceFn,
  template <class> class AtomicReduceFn,
  class ElementOutput,
  class ElementCompute,
  FloatRoundStyle RoundStyle,
  class StrideMNL = Stride<_0,_0,_0>,
  bool EnableNullptr = true // Noop on nullptr params
>
struct Sm90ScalarReduction {
  static_assert(
    (cute::is_same_v<StrideMNL, Stride<_0,_0, _0>>) || // scalar reduction, e.g. tensor max element
    (cute::is_same_v<StrideMNL, Stride<_0,_0, _1>>) || // batched scalar reduction, e.g. per-batch max element
    (cute::is_same_v<StrideMNL, Stride<_0,_0,int>>));  
  struct SharedStorage { };

  struct Arguments {
    ElementOutput* ptr_scalar = nullptr;
    ElementCompute reduction_identity = ElementCompute(0);
    StrideMNL dScalar = {};
  };

  using Params = Arguments;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    return args;
  }

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    return false;
  }

  CUTLASS_DEVICE bool
  is_C_load_needed() const {
    return false;
  }

  CUTLASS_HOST_DEVICE
  Sm90ScalarReduction() { }

  CUTLASS_HOST_DEVICE
  Sm90ScalarReduction(Params const& params, SharedStorage const& shared_storage)
      : params(params) { }

  Params const params;

  template <
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class EpilogueTile
  >
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK tile_shape_mnk,
      TileCoordMNKL tile_coord_mnkl,
      EpilogueTile epi_tile,
      int thread_idx) {
    return EmptyProducerLoadCallbacks{};
  }

  template<class CTensor, class ResidueMN>
  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(
        int l_coord,
        CTensor&& tCcScalar,
        ResidueMN residue_mn,
        Params const& params)
      : scalar(params.reduction_identity),
        l_coord(l_coord),
        tCcScalar(cute::forward<CTensor>(tCcScalar)),
        residue_mn(residue_mn),
        params(params) {}

    ElementCompute scalar;
    int l_coord;
    CTensor tCcScalar;
    ResidueMN residue_mn;
    Params params;

    template <typename ElementAccumulator, typename ElementInput, int FragmentSize>
    CUTLASS_DEVICE auto
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n,
          Array<ElementInput, FragmentSize> const& frg_input) {
      if constexpr (EnableNullptr) {
        if (params.ptr_scalar == nullptr) {
          return frg_input;
        }
      }

      using ConvertInput = NumericArrayConverter<ElementCompute, ElementInput, FragmentSize, RoundStyle>;
      using ReduceInput = RegReduceFn<ElementCompute>;
      ConvertInput convert_input{};
      ReduceInput reduce_input{};

      Array frg_I = convert_input(frg_input);

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < FragmentSize; ++i) {
        if (elem_less(tCcScalar(epi_v * FragmentSize + i), residue_mn)) {
          scalar = reduce_input(scalar, frg_I[i]);
        }
      }

      return frg_input;
    }

    CUTLASS_DEVICE void
    end() {
      if constexpr (EnableNullptr) {
        if (params.ptr_scalar == nullptr) {
          return;
        }
      }

      using ConvertI = NumericConverter<ElementOutput, ElementCompute, RoundStyle>;
      using ReduceInput = AtomicReduceFn<ElementOutput>;

      ConvertI convert_I{};
      ReduceInput reduce_input{};

      ElementOutput* ptr_scalar = params.ptr_scalar + l_coord * get<2>(params.dScalar);
      reduce_input(ptr_scalar, convert_I(scalar));
    }

  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class EpilogueTile,
    class TiledCopy,
    class SrcTensor
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK tile_shape_mnk,
      TileCoordMNKL tile_coord_mnkl,
      EpilogueTile epi_tile,
      TiledCopy tiled_copy,
      int thread_idx,
      SrcTensor const& tCrC) {

    int l_coord = static_cast<int>(get<3>(tile_coord_mnkl));

    // Compute tile residues and coordinate tensors for predication
    auto [M, N, K, L] = problem_shape_mnkl;
    auto [m, n, k, l] = tile_coord_mnkl;
    auto residue_mn = make_coord(
      M - static_cast<int>(m) * size<0>(tile_shape_mnk),
      N - static_cast<int>(n) * size<1>(tile_shape_mnk)
    );
    Tensor cScalar = make_identity_tensor(take<0,2>(tile_shape_mnk));
    Tensor tCcScalar = sm90_partition_for_epilogue<ReferenceSrc>(cScalar, epi_tile, tiled_copy, thread_idx);

    return ConsumerStoreCallbacks(l_coord, cute::move(tCcScalar), residue_mn, params);
  }

};


/////////////////////////////////////////////////////////////////////////////////////////////////

// Row vector reduction
template <
  template <class> class RegReduceFn,
  template <class> class AtomicReduceFn,
  int Stages,
  class CtaTileShapeMNK,
  class ElementOutput,
  class ElementCompute,
  FloatRoundStyle RoundStyle,
  class StrideMNL = Stride<_0,_1,_0>,
  int Alignment = 128 / sizeof_bits_v<ElementOutput>,
  bool EnableNullptr = true // Noop on nullptr params
>
struct Sm90RowReduction {
  static_assert(Stages == 0, "Smem usage not supported yet");
  static_assert(Alignment * sizeof_bits_v<ElementOutput> % 128 == 0, "sub-16B alignment not supported yet");
  static_assert(
    (cute::is_same_v<StrideMNL, Stride<_0,_1, _0>>) || // row vector reduction, e.g. per-col sum over all batches
    (cute::is_same_v<StrideMNL, Stride<_0,_1,int>>));  // batched row vector reduction, e.g. per-col sum per batch

  struct SharedStorage { };

  struct Arguments {
    ElementOutput* ptr_row = nullptr;
    ElementCompute reduction_identity = 0;
    StrideMNL dRow = {};
  };

  using Params = Arguments;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    return args;
  }

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    return false;
  }

  CUTLASS_DEVICE bool
  is_C_load_needed() const {
    return false;
  }

  CUTLASS_HOST_DEVICE
  Sm90RowReduction() { }

  CUTLASS_HOST_DEVICE
  Sm90RowReduction(Params const& params, SharedStorage const& shared_storage)
      : params(params) { }

  Params params;

  template <
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class EpilogueTile
  >
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK tile_shape_mnk,
      TileCoordMNKL tile_coord_mnkl,
      EpilogueTile epi_tile,
      int thread_idx) {
    return EmptyProducerLoadCallbacks{};
  }

  template<class RTensor, class GTensor, class CTensor, class ResidueMN>
  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(
        RTensor&& tCrRow,
        GTensor&& tCgRow,
        CTensor&& tCcRow,
        ResidueMN residue_mn,
        Params const& params)
      : tCrRow(cute::forward<RTensor>(tCrRow)),
        tCgRow(cute::forward<GTensor>(tCgRow)),
        tCcRow(cute::forward<CTensor>(tCcRow)),
        residue_mn(residue_mn),
        params(params) {}

    // gmem store after every column of subtiles, assuming M-major loop
    // needed to reduce reg pressure, otherwise each thread stores up to a full row in RF
    // since row-elements aren't evenly distributed amongst threads
    RTensor tCrRow;                                                                    // (CPY,CPY_M,CPY_N,EPI_M)
    GTensor tCgRow;                                                                    // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    CTensor tCcRow;                                                                    // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    ResidueMN residue_mn;
    Params const& params;

    template <typename ElementAccumulator, typename ElementInput, int FragmentSize>
    CUTLASS_DEVICE auto
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n,
          Array<ElementInput, FragmentSize> const& frg_input) {

      if constexpr (EnableNullptr) {
        if (params.ptr_row == nullptr) {
          return frg_input;
        }
      }

      using ConvertInput = NumericArrayConverter<ElementCompute, ElementInput, FragmentSize, RoundStyle>;
      using ReduceInput = RegReduceFn<ElementCompute>;
      ConvertInput convert_input{};
      ReduceInput reduce_input{};

      Array frg_I = convert_input(frg_input);
      Tensor tCrRow_mn = tCrRow(_,_,_,epi_m);
      Tensor tCcRow_mn = tCcRow(_,_,_,epi_m,epi_n);

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < FragmentSize; ++i) {
        if (elem_less(tCcRow_mn(i), residue_mn)) {
          ElementCompute& tCrRow_vmn = tCrRow_mn(epi_v * FragmentSize + i);
          tCrRow_vmn = reduce_input(tCrRow_vmn, frg_I[i]);
        }
      }

      return frg_input;
    }

    CUTLASS_DEVICE void
    step_end(int epi_m, int epi_n, int store_iteration, bool issue_tma_store) {
      if constexpr (EnableNullptr) {
        if (params.ptr_row == nullptr) {
          return;
        }
      }

      if (epi_m == size<3>(tCrRow)-1) { // assumes M-major subtile loop
        using ConvertI = NumericConverter<ElementOutput, ElementCompute, RoundStyle>;
        using ReduceInput = AtomicReduceFn<ElementOutput>;

        ConvertI convert_I{};
        ReduceInput reduce_input{};

        // Filter so we don't issue redunant copies over stride-0 modes
        Tensor tCrRow_flt = filter_zeros(tCrRow(_,_,_,epi_m));
        Tensor tCgRow_flt = filter_zeros(tCgRow(_,_,_,epi_m,epi_n));
        Tensor tCcRow_mn  = tCcRow(_,_,_,epi_m,epi_n);
        Tensor tCcRow_flt = make_tensor(tCcRow_mn.data(), make_layout(tCgRow_flt.shape(), tCcRow_mn.stride()));


        auto [residue_m, residue_n] = residue_mn;
        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < size(tCrRow_flt); ++i) {
          // partially OOB in M must still issue gmem reduction, so only consider residue_n
          // in case last epi tile in column is fully OOB in M and CTA tile is partially OOB in M
          if (residue_n > get<1>(tCcRow_flt(i)) && 
              // fully OOB in M does not need to issue gmem reduction, skip
              residue_m > 0) {
            reduce_input(&tCgRow_flt(i), convert_I(tCrRow_flt(i)));
          }
        }

        // Reset the registers to the reduction identity
        fill(tCrRow, params.reduction_identity);
      }
    }

  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class EpilogueTile,
    class TiledCopy,
    class SrcTensor
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK tile_shape_mnk,
      TileCoordMNKL tile_coord_mnkl,
      EpilogueTile epi_tile,
      TiledCopy tiled_copy,
      int thread_idx,
      SrcTensor const& tCrC) {

    auto [M, N, K, L] = problem_shape_mnkl;
    Tensor mRow = make_tensor(make_gmem_ptr(params.ptr_row), make_shape(M,N,L), params.dRow);
    Tensor tCgRow = sm90_partition_for_epilogue<ReferenceSrc>(                         // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
      mRow, tile_shape_mnk, tile_coord_mnkl, epi_tile, tiled_copy, thread_idx);
    Tensor tCrRow = make_tensor_like<ElementCompute>(tCgRow(_,_,_,_,_0{}));            // (CPY,CPY_M,CPY_N,EPI_M)
    fill(tCrRow, params.reduction_identity);

    // Compute tile residues and coordinate tensors for predication
    auto [m, n, k, l] = tile_coord_mnkl;
    auto residue_mn = make_coord(
      M - static_cast<int>(m) * size<0>(tile_shape_mnk),
      N - static_cast<int>(n) * size<1>(tile_shape_mnk)
    );
    Tensor cRow = make_identity_tensor(take<0,2>(tile_shape_mnk));
    Tensor tCcRow = sm90_partition_for_epilogue<ReferenceSrc>(cRow, epi_tile, tiled_copy, thread_idx);

    return ConsumerStoreCallbacks<decltype(tCrRow),decltype(tCgRow),decltype(tCcRow),decltype(residue_mn)>(
      cute::move(tCrRow), cute::move(tCgRow), cute::move(tCcRow), residue_mn, params);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// Col vector reduction
template <
  template <class> class RegReduceFn,
  template <class> class AtomicReduceFn,
  int Stages,
  class CtaTileShapeMNK,
  class ElementOutput,
  class ElementCompute,
  FloatRoundStyle RoundStyle,
  class StrideMNL = Stride<_1,_0,_0>,
  int Alignment = 128 / sizeof_bits_v<ElementOutput>,
  bool EnableNullptr = true // Noop on nullptr params
>
struct Sm90ColReduction {
  static_assert(Stages == 0, "Smem usage not supported yet");
  static_assert(Alignment * sizeof_bits_v<ElementOutput> % 128 == 0, "sub-16B alignment not supported yet");
  static_assert(
    (cute::is_same_v<StrideMNL, Stride<_1,_0, _0>>) || // col vector reduction, e.g. per-row sum over all batches
    (cute::is_same_v<StrideMNL, Stride<_1,_0,int>>));  // batched col vector reduction, e.g. per-row sum per batch

  struct SharedStorage { };

  struct Arguments {
    ElementOutput* ptr_col = nullptr;
    ElementCompute reduction_identity = 0;
    StrideMNL dCol = {};
  };

  using Params = Arguments;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    return args;
  }

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    return false;
  }

  CUTLASS_DEVICE bool
  is_C_load_needed() const {
    return false;
  }

  CUTLASS_HOST_DEVICE
  Sm90ColReduction() { }

  CUTLASS_HOST_DEVICE
  Sm90ColReduction(Params const& params, SharedStorage const& shared_storage)
      : params(params) { }

  Params params;

  template <
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class EpilogueTile
  >
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK tile_shape_mnk,
      TileCoordMNKL tile_coord_mnkl,
      EpilogueTile epi_tile,
      int thread_idx) {
    return EmptyProducerLoadCallbacks{};
  }

  template<class RTensor, class GTensor, class CTensor, class ResidueMN>
  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(
        RTensor&& tCrCol,
        GTensor&& tCgCol,
        CTensor&& tCcCol,
        ResidueMN residue_mn,
        Params const& params)
      : tCrCol(cute::forward<RTensor>(tCrCol)),
        tCgCol(cute::forward<GTensor>(tCgCol)),
        tCcCol(cute::forward<CTensor>(tCcCol)),
        residue_mn(residue_mn),
        params(params) {}

    RTensor tCrCol;                                                                    // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    GTensor tCgCol;                                                                    // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    CTensor tCcCol;                                                                    // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    ResidueMN residue_mn;
    Params const& params;

    template <typename ElementAccumulator, typename ElementInput, int FragmentSize>
    CUTLASS_DEVICE auto
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n,
          Array<ElementInput, FragmentSize> const& frg_input) {

      if constexpr (EnableNullptr) {
        if (params.ptr_col == nullptr) {
          return frg_input;
        }
      }

      using ConvertInput = NumericArrayConverter<ElementCompute, ElementInput, FragmentSize, RoundStyle>;
      using ReduceInput = RegReduceFn<ElementCompute>;
      ConvertInput convert_input{};
      ReduceInput reduce_input{};

      Array frg_I = convert_input(frg_input);
      Tensor tCrCol_mn = tCrCol(_,_,_,epi_m,epi_n);
      Tensor tCcCol_mn = tCcCol(_,_,_,epi_m,epi_n);

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < FragmentSize; ++i) {
        if (elem_less(tCcCol_mn(i), residue_mn)) {
          ElementCompute& tCrCol_vmn = tCrCol_mn(epi_v * FragmentSize + i);
          tCrCol_vmn = reduce_input(tCrCol_vmn, frg_I[i]);
        }
      }

      return frg_input;
    }

    CUTLASS_DEVICE void
    end() {
      if constexpr (EnableNullptr) {
        if (params.ptr_col == nullptr) {
          return;
        }
      }

      using ConvertI = NumericConverter<ElementOutput, ElementCompute, RoundStyle>;
      using ReduceInput = AtomicReduceFn<ElementOutput>;

      ConvertI convert_I{};
      ReduceInput reduce_input{};

      // Filter so we don't issue redunant copies over stride-0 modes
      Tensor tCrCol_flt = filter_zeros(tCrCol);
      Tensor tCgCol_flt = filter_zeros(tCgCol);
      Tensor tCcCol_flt = make_tensor(tCcCol.data(), make_layout(tCgCol_flt.shape(), tCcCol.stride()));

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size(tCrCol_flt); ++i) {
        if (elem_less(tCcCol_flt(i), residue_mn)) {
          reduce_input(&tCgCol_flt(i), convert_I(tCrCol_flt(i)));
        }
      }
    }

  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class EpilogueTile,
    class TiledCopy,
    class SrcTensor
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK tile_shape_mnk,
      TileCoordMNKL tile_coord_mnkl,
      EpilogueTile epi_tile,
      TiledCopy tiled_copy,
      int thread_idx,
      SrcTensor const& tCrC) {

    auto [M, N, K, L] = problem_shape_mnkl;
    Tensor mCol = make_tensor(make_gmem_ptr(params.ptr_col), make_shape(M,N,L), params.dCol);
    Tensor tCgCol = sm90_partition_for_epilogue<ReferenceSrc>(                         // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
      mCol, tile_shape_mnk, tile_coord_mnkl, epi_tile, tiled_copy, thread_idx);
    Tensor tCrCol = make_tensor_like<ElementCompute>(tCgCol);                          // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    fill(tCrCol, params.reduction_identity);

    // Compute tile residues and coordinate tensors for predication
    auto [m, n, k, l] = tile_coord_mnkl;
    auto residue_mn = make_coord(
      M - static_cast<int>(m) * size<0>(tile_shape_mnk),
      N - static_cast<int>(n) * size<1>(tile_shape_mnk)
    );
    Tensor cCol = make_identity_tensor(take<0,2>(tile_shape_mnk));
    Tensor tCcCol = sm90_partition_for_epilogue<ReferenceSrc>(cCol, epi_tile, tiled_copy, thread_idx);

    return ConsumerStoreCallbacks(cute::move(tCrCol), cute::move(tCgCol), cute::move(tCcCol), residue_mn, params);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// Batch matrix reduction
template <
  int Stages,
  class EpilogueTile,
  class Element,
  class StrideMNL,
  class CopyOpR2S,
  class SmemLayoutAtom,
  int Alignment = 128 / sizeof_bits_v<Element>,
  bool EnableNullptr = true // Noop on nullptr params
>
struct Sm90MatrixReduction;

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::epilogue::fusion

/////////////////////////////////////////////////////////////////////////////////////////////////
