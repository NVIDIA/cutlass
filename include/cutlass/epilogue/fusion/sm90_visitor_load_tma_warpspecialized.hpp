/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
  \brief Visitor tree load operations for the sm90 TMA warp-specialized (ws) epilogue
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/arch/barrier.h"

#include "cute/tensor.hpp"
#include "sm90_visitor_tma_warpspecialized.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::fusion {

using namespace cute;
using namespace detail;

/////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Elementwise Fetch Operations
//
/////////////////////////////////////////////////////////////////////////////////////////////////

// returns accumulator
struct Sm90AccFetch : Sm90VisitorImpl<> {

  using Sm90VisitorImpl<>::Sm90VisitorImpl;

  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    template <typename ElementAccumulator, int FragmentSize>
    CUTLASS_DEVICE Array<ElementAccumulator, FragmentSize>
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n) {
      return frg_acc;
    }
  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class... Args
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(ConsumerStoreArgs<Args...> const& args) {
    return ConsumerStoreCallbacks{};
  }
};

// Split tree visitor fetches intermediate results from temporary accumulators
using Sm90SplitTreeFetch = Sm90AccFetch;

/////////////////////////////////////////////////////////////////////////////////////////////////

// returns C
template <class Element>
struct Sm90SrcFetch : Sm90VisitorImpl<> {

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    return is_C_load_needed();
  }

  CUTLASS_DEVICE bool
  is_C_load_needed() const {
    return not is_void_v<Element>;
  }

  CUTLASS_DEVICE bool
  is_zero() const {
    return is_void_v<Element>;
  }

  using Sm90VisitorImpl<>::Sm90VisitorImpl;

  template<class SrcTensor>
  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(SrcTensor const& tCrC)
      : tCrC(tCrC) {}

    SrcTensor const& tCrC;                                                                         // (CPY,CPY_M,CPY_N)

    template <typename ElementAccumulator, int FragmentSize>
    CUTLASS_DEVICE Array<typename SrcTensor::value_type, FragmentSize>
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n) {
      return recast<Array<typename SrcTensor::value_type, FragmentSize>>(tCrC)(epi_v);
    }

  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class... Args
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(ConsumerStoreArgs<Args...> const& args) {
    // register type may differ from logical type so we can't assert matching types here
    return ConsumerStoreCallbacks(args.tCrC);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Elementwise Load Operations
//
/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  int Stages,
  class EpilogueTile,
  class Element,
  class StrideMNL,
  class SmemLayoutAtom,
  class CopyOpS2R,
  int Alignment = 128 / sizeof_bits_v<Element>,
  bool EnableNullptr = true // Fallback scalar broadcast for nullptr params
>
struct Sm90AuxLoad {
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
  using CopyOpG2S =
      SM90_TMA_LOAD
    ;

  struct SharedStorage {
    alignas(cutlass::detail::alignment_for_swizzle(SmemLayout{}))
    array_aligned<Element, size(SmemLayout{})> smem_aux;
  };

  struct Arguments {
    Element const* ptr_aux = nullptr;
    Element null_default = Element(0);
    StrideMNL dAux = {};
  };

  struct Params {
    using TMA_Aux = decltype(make_tma_copy(
        CopyOpG2S{},
        make_tensor(make_gmem_ptr(static_cast<Element const*>(nullptr)), repeat_like(StrideMNL{}, int32_t(0)), append<3>(StrideMNL{}, _0{})),
        take<0,2>(SmemLayoutTma{})));
    TMA_Aux tma_load_aux;
    Element null_default = Element(0);
    bool use_default = false;
  };

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    // Optionally append 1s until problem shape is rank-4 in case its is only rank-3 (MNK)
    auto problem_shape_mnkl = append<4>(problem_shape, 1);
    auto [M, N, K, L] = problem_shape_mnkl;
    auto M_AUX =
        size(M)
      ;
    Tensor tensor_aux = make_tensor(make_gmem_ptr(args.ptr_aux), make_layout(make_shape(M_AUX,N,L), append<3>(args.dAux, _0{})));
    typename Params::TMA_Aux tma_load_aux = make_tma_copy(CopyOpG2S{}, tensor_aux, take<0,2>(SmemLayoutTma{}));

    bool use_default = false;
    if constexpr (EnableNullptr) {
      use_default = args.ptr_aux == nullptr;
    }

    return Params{tma_load_aux, args.null_default, use_default};
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
  Sm90AuxLoad() { }

  CUTLASS_HOST_DEVICE
  Sm90AuxLoad(Params const& params, SharedStorage const& shared_storage)
      : params_ptr(&params),
        smem_aux(const_cast<Element*>(shared_storage.smem_aux.data())) { }

  Params const* params_ptr;
  Element* smem_aux;

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    return true;
  }

  CUTLASS_DEVICE bool
  is_C_load_needed() const {
    return false;
  }

  CUTLASS_DEVICE bool
  is_zero() const {
    return (params_ptr->use_default && params_ptr->null_default == Element(0));
  }

  template <class GTensor, class STensor>
  struct ProducerLoadCallbacks : EmptyProducerLoadCallbacks {
    CUTLASS_DEVICE
    ProducerLoadCallbacks(GTensor&& bGS_gAux, STensor&& bGS_sAux, Params const* params_ptr)
      : bGS_gAux(cute::forward<GTensor>(bGS_gAux)),
        bGS_sAux(cute::forward<STensor>(bGS_sAux)),
        params_ptr(params_ptr) {}

    GTensor bGS_gAux;                                                                  // (TMA,TMA_M,TMA_N,EPI_M,EPI_N)
    STensor bGS_sAux;                                                                  // (TMA,TMA_M,TMA_N,PIPE)
    Params const* params_ptr;

    CUTLASS_DEVICE void
    step(uint64_t* full_mbarrier_ptr, int epi_m, int epi_n, int load_iteration, bool issue_tma_load) {
      if constexpr (EnableNullptr) {
        if (params_ptr->use_default) {
          return;
        }
      }

      if (issue_tma_load) {
        // Increment the expected transaction bytes of the current stage's mbarrier by the subtile's byte-size
        constexpr uint32_t copy_bytes = size(take<0,2>(SmemLayout{})) * sizeof_bits_v<Element> / 8;
        cutlass::arch::ClusterTransactionBarrier::expect_transaction(full_mbarrier_ptr, copy_bytes);
        // Issue the TMA load
        constexpr uint16_t mcast_mask = 0;
        int load_pipe_index = load_iteration % Stages;
        copy(params_ptr->tma_load_aux.with(*full_mbarrier_ptr, mcast_mask),
          bGS_gAux(_,_,_,epi_m,epi_n), bGS_sAux(_,_,_,load_pipe_index));
      }
    }
  };

  template <class... Args>
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(ProducerLoadArgs<Args...> const& args) {

    auto [M, N, K, L] = args.problem_shape_mnkl;
    auto [m, n, k, l] = args.tile_coord_mnkl;
    auto coord_shape =
        make_coord(m, n, l)
      ;
    Tensor mAux_mn = params_ptr->tma_load_aux.get_tma_tensor(make_shape(M,N,L));                             // (M,N,L)
    Tensor mAux = coalesce(mAux_mn, take<0,2>(args.tile_shape_mnk));
    Tensor gAux = local_tile(mAux, take<0,2>(args.tile_shape_mnk), coord_shape);                       // (CTA_M,CTA_N)

    Tensor gAux_epi = flat_divide(gAux, args.epi_tile);                          // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)
    Tensor sAux_epi = make_tensor(make_smem_ptr(smem_aux), SmemLayout{});        // (EPI_TILE_M,EPI_TILE_N,PIPE)

    ThrCopy thrblk_g2s = params_ptr->tma_load_aux.get_slice(_0{});
    Tensor bGS_gAux = thrblk_g2s.partition_S(gAux_epi);                                // (TMA,TMA_M,TMA_N,EPI_M,EPI_N)
    Tensor bGS_sAux = thrblk_g2s.partition_D(sAux_epi);                                // (TMA,TMA_M,TMA_N,PIPE)

    return ProducerLoadCallbacks<decltype(bGS_gAux), decltype(bGS_sAux)>(
      cute::move(bGS_gAux), cute::move(bGS_sAux), params_ptr);
  }

  template <class RTensor, class TiledS2R, class STensorS2R>
  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(RTensor&& tC_rAux, TiledS2R tiled_s2r, STensorS2R&& tSR_sAux, Params const* params_ptr)
      : tC_rAux(cute::forward<RTensor>(tC_rAux)),
        tiled_s2r(tiled_s2r),
        tSR_sAux(cute::forward<STensorS2R>(tSR_sAux)),
        params_ptr(params_ptr) { }

    TiledS2R tiled_s2r;
    RTensor tC_rAux;                                                                          // (CPY,CPY_M,CPY_N)
    STensorS2R tSR_sAux;                                                                      // (S2R,S2R_M,S2R_N,PIPE)
    Params const* params_ptr;

    CUTLASS_DEVICE void
    previsit(int epi_m, int epi_n, int load_iteration, bool is_producer_load_needed) {
      if constexpr (EnableNullptr) {
        if (params_ptr->use_default) {
          fill(tC_rAux, params_ptr->null_default);
          return;
        }
      }

      using RLayoutS2R = decltype(cute::layout(TiledS2R{}.get_slice(0).retile_S(RTensor{})));
      Tensor tSR_rAux = make_tensor(tC_rAux.data(), RLayoutS2R{});                                 // (S2R,S2R_M,S2R_N)

      int load_pipe_index = load_iteration % Stages;
      copy(tiled_s2r, tSR_sAux(_,_,_,load_pipe_index), tSR_rAux);
    }

    template <typename ElementAccumulator, int FragmentSize>
    CUTLASS_DEVICE Array<Element, FragmentSize>
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n) {
      Tensor tC_rAux_frg = recast<Array<Element, FragmentSize>>(coalesce(tC_rAux));                          // (EPI_V)

      return tC_rAux_frg(epi_v);
    }
  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class... Args
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(ConsumerStoreArgs<Args...> const& args) {

    auto [M, N, K, L] = args.problem_shape_mnkl;

    Tensor mAux_mn = params_ptr->tma_load_aux.get_tma_tensor(make_shape(M,N,L));                             // (M,N,L)
    Tensor mAux = coalesce(mAux_mn, take<0,2>(args.tile_shape_mnk));
    Tensor tC_gAux = sm90_partition_for_epilogue<ReferenceSrc                          // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
      >(mAux, args.tile_shape_mnk, args.tile_coord_mnkl, args.epi_tile, args.tiled_copy, args.thread_idx);
    Tensor tC_rAux = make_tensor<Element>(take<0,3>(shape(tC_gAux)));                  // (CPY,CPY_M,CPY_N)

    auto tiled_s2r = conditional_return<ReferenceSrc>(
      make_tiled_copy_S(Copy_Atom<CopyOpS2R,Element>{}, args.tiled_copy),
      make_tiled_copy_D(Copy_Atom<CopyOpS2R,Element>{}, args.tiled_copy)
    );
    Tensor sAux_epi = cute::as_position_independent_swizzle_tensor(
                        make_tensor(make_smem_ptr(smem_aux), SmemLayout{}));            // (EPI_TILE_M,EPI_TILE_N,PIPE)
    auto tSR_sAux = tiled_s2r.get_slice(args.thread_idx).partition_S(sAux_epi);               // (S2R,S2R_M,S2R_N,PIPE)

    return ConsumerStoreCallbacks<decltype(tC_rAux), decltype(tiled_s2r), decltype(tSR_sAux)>(
        cute::move(tC_rAux), tiled_s2r, cute::move(tSR_sAux), params_ptr);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Broadcast Load Operations
//
/////////////////////////////////////////////////////////////////////////////////////////////////

// Scalar broadcast
// Supports reduction over multiple broadcasts to support fusions such as fp8 scaling factors
template<
  class Element,
  class StrideMNL = Stride<_0,_0,_0>,
  int BroadcastCount = 1,
  template <class> class ReductionFn = multiplies
>
struct Sm90ScalarBroadcast {
  static_assert(is_static_v<decltype(take<0,2>(StrideMNL{}))>); // batch stride can be dynamic or static
  static_assert(take<0,2>(StrideMNL{}) == Stride<_0,_0>{});

  struct SharedStorage { };

  struct Arguments {
    Element scalars[BroadcastCount] = {};
    Element const* scalar_ptrs[BroadcastCount] = {};
    StrideMNL dScalar = {};
  };

  using Params = Arguments;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    return args;
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
    CudaHostAdapter *cuda_adapter = nullptr) {
    return cutlass::Status::kSuccess;
  }

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    return false;
  }

  CUTLASS_DEVICE bool
  is_C_load_needed() const {
    return false;
  }

  // This must be called after update_scalar is called
  CUTLASS_DEVICE bool
  is_zero() const {
    return scalar == Element(0);
  }

  CUTLASS_HOST_DEVICE
  Sm90ScalarBroadcast() { }

  CUTLASS_HOST_DEVICE
  Sm90ScalarBroadcast(Params const& params, SharedStorage const& shared_storage)
      : params_ptr(&params) {
    // Get the scalar for non-batched broadcast
    if (get<2>(params_ptr->dScalar) == 0) {
      update_scalar();
    }
  }

  Element scalar;
  Params const* params_ptr;

  template <class... Args>
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(ProducerLoadArgs<Args...> const& args) {
    // Get the scalar for batched broadcast
    if (get<2>(params_ptr->dScalar) != 0) {
      auto [m_coord, n_coord, k_coord, l_coord] = args.tile_coord_mnkl;
      update_scalar(l_coord);
    }

    return EmptyProducerLoadCallbacks{};
  }

  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(Element scalar)
      : scalar(scalar) {}

    Element scalar;

    template <typename ElementAccumulator, int FragmentSize>
    CUTLASS_DEVICE Array<Element, FragmentSize>
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n) {
      Array<Element, FragmentSize> frg_scalar;
      frg_scalar.fill(scalar);

      return frg_scalar;
    }

  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class... Args
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(ConsumerStoreArgs<Args...> const& args) {

    // Get the scalar for batched broadcast
    if (get<2>(params_ptr->dScalar) != 0) {
      auto [m_coord, n_coord, k_coord, l_coord] = args.tile_coord_mnkl;
      update_scalar(l_coord);
    }

    return ConsumerStoreCallbacks(scalar);
  }

private:
  CUTLASS_DEVICE void
  update_scalar(int l_coord = 0) {
    int l_offset = l_coord * size<2>(params_ptr->dScalar);

    if (params_ptr->scalar_ptrs[0] != nullptr) {
      scalar = params_ptr->scalar_ptrs[0][l_offset];
    } else {
      // batch stride is ignored for nullptr fallback
      scalar = params_ptr->scalars[0];
    }

    // Do reduction over multiple broadcasts if necessary
    ReductionFn<Element> reduction_fn;
    CUTLASS_PRAGMA_UNROLL
    for (int i = 1; i < BroadcastCount; ++i) {
      if (params_ptr->scalar_ptrs[i] != nullptr) {
        scalar = reduction_fn(scalar, params_ptr->scalar_ptrs[i][l_offset]);
      } else {
        // batch stride is ignored for nullptr fallback
        scalar = reduction_fn(scalar, params_ptr->scalars[i]);
      }
    }
  }

  template<class... Xs>
  CUTLASS_DEVICE void
  update_scalar(cute::tuple<Xs...>) {
    // Only support multiple L-modes with fully-broadcast scalar
    static_assert(cute::is_same_v<StrideMNL, Stride<_0,_0, _0>>);
    scalar = params_ptr->scalars[0];
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

template <int StagesC, class CtaTileShapeMNK, class EpilogueTile>
[[deprecated("row broadcast only uses 0 stages")]] constexpr int
compute_row_broadcast_stages() {
  return ceil_div(StagesC, size<1>(zipped_divide(make_layout(take<0,2>(CtaTileShapeMNK{})), EpilogueTile{}))) + 1;
}

}

// Row vector broadcast
template<
  int Stages,
  class CtaTileShapeMNK,
  class Element,
  class StrideMNL = Stride<_0,_1,_0>,
  int Alignment = 128 / sizeof_bits_v<Element>,
  bool EnableNullptr = true // Fallback scalar broadcast for nullptr params
>
struct Sm90RowBroadcast {
  static_assert(Stages == 0, "Row broadcast doesn't support smem usage");
  static_assert(is_static_v<decltype(take<0,2>(StrideMNL{}))>); // batch stride can be dynamic or static
  static_assert(take<0,2>(StrideMNL{}) == Stride<_0,_1>{});

  struct SharedStorage { 
    array_aligned<Element, size<1>(CtaTileShapeMNK{})> smem;
  };

  struct Arguments {
    Element const* ptr_row = nullptr;
    Element null_default = Element(0);
    StrideMNL dRow = {};
  };

  using Params = Arguments;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    return args;
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
  Sm90RowBroadcast() { }

  CUTLASS_HOST_DEVICE
  Sm90RowBroadcast(Params const& params, SharedStorage const& shared_storage)
      : params(params)
      , smem(const_cast<Element*>(shared_storage.smem.data())) { }

  Params params;
  Element *smem = nullptr;

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
    return (params.ptr_row == nullptr && params.null_default == Element(0));
  }

  template <class... Args>
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(ProducerLoadArgs<Args...> const& args) {
    return EmptyProducerLoadCallbacks{};
  }

  template <class GS_GTensor, class GS_STensor, class GS_CTensor, class Tiled_G2S, class SR_STensor, class SR_RTensor, class CTensor, class ThrResidue, class ThrNum>
  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(
        GS_GTensor tGS_gRow_, GS_STensor tGS_sRow_, 
        GS_CTensor tGS_cRow_, Tiled_G2S tiled_g2s_, 
        SR_STensor tSR_sRow_, SR_RTensor tSR_rRow_,
        CTensor tCcRow_, ThrResidue residue_tCcRow_, ThrNum thr_num_, Params const& params_)
      : tGS_gRow(tGS_gRow_)
      , tGS_sRow(tGS_sRow_)
      , tGS_cRow(tGS_cRow_)
      , tiled_G2S(tiled_g2s_)
      , tSR_sRow(tSR_sRow_)
      , tSR_rRow(tSR_rRow_)
      , tCcRow(tCcRow_)
      , residue_tCcRow(residue_tCcRow_)
      , params(params_)
      , is_nullptr(EnableNullptr && params_.ptr_row == nullptr) {}

    GS_GTensor tGS_gRow;                                                         // (CPY,CPY_M,CPY_N)
    GS_STensor tGS_sRow;                                                         // (CPY,CPY_M,CPY_N)
    GS_CTensor tGS_cRow;                                                         // (CPY,CPY_M,CPY_N)
    Tiled_G2S tiled_G2S;

    SR_STensor tSR_sRow;                                                         // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    SR_RTensor tSR_rRow;                                                         // (CPY,CPY_M,CPY_N,EPI_M,EPI_N) 
  
    CTensor tCcRow;                                                              // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    ThrResidue residue_tCcRow;                                                   // (m, n)
    ThrNum thr_num;
    Params const& params;
    bool is_nullptr;

    CUTLASS_DEVICE void
    begin() {
      if constexpr (EnableNullptr) {
        if (params.ptr_row == nullptr) {
          fill(tSR_rRow, params.null_default);
          return;
        }
      }

      auto synchronize = [&] () { cutlass::arch::NamedBarrier::sync(thr_num, cutlass::arch::ReservedNamedBarriers::EpilogueBarrier); };
      Tensor tGS_gRow_flt = filter_zeros(tGS_gRow);
      Tensor tGS_sRow_flt = filter_zeros(tGS_sRow);
      Tensor tGS_cRow_flt = make_tensor(tGS_cRow.data(), make_layout(tGS_gRow_flt.shape(), tGS_cRow.stride()));

      for (int i = 0; i < size(tGS_gRow_flt); ++i) {
        if (get<1>(tGS_cRow_flt(i)) >= size<1>(CtaTileShapeMNK{})) {
          continue; // OOB of SMEM, 
        }
        if (elem_less(tGS_cRow_flt(i), make_coord(get<0>(residue_tCcRow), get<1>(residue_tCcRow)))) {
          tGS_sRow_flt(i) = tGS_gRow_flt(i);
        }
        else {
          tGS_sRow_flt(i) = Element(0); // Set to Zero when OOB so LDS could be issue without any preds.
        }
      }
      synchronize();
    }

    CUTLASS_DEVICE void
    begin_loop(int epi_m, int epi_n) {
      if (epi_m == 0) { // Assumes M-major subtile loop
        if (is_nullptr) return; // Do not issue LDS when bias is nullptr
        Tensor tSR_sRow_flt = filter_zeros(tSR_sRow(_,_,_,epi_m,epi_n));
        Tensor tSR_rRow_flt = filter_zeros(tSR_rRow);
        copy(tSR_sRow_flt, tSR_rRow_flt);
      }
    }

    template <typename ElementAccumulator, int FragmentSize>
    CUTLASS_DEVICE Array<Element, FragmentSize>
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n) {
      Array<Element, FragmentSize> frg_row;

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < FragmentSize; ++i) {
        frg_row[i] = tSR_rRow(epi_v * FragmentSize + i);
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
    using ThreadCount = decltype(size(args.tiled_copy));

    Tensor mRow = make_tensor(make_gmem_ptr(params.ptr_row), make_shape(M,N,L), params.dRow);
    Tensor gRow = local_tile(mRow(_,_,l), take<0,2>(args.tile_shape_mnk), make_coord(m, n));          // (CTA_M, CTA_N)
    Tensor sRow = make_tensor(make_smem_ptr(smem), 
        make_shape(size<0>(CtaTileShapeMNK{}), size<1>(CtaTileShapeMNK{})), make_shape(_0{}, _1{}));  // (CTA_M, CTA_N)
    //// G2S: Gmem to Smem
    auto tiled_g2s = make_tiled_copy(Copy_Atom<DefaultCopy, Element>{},
                                     Layout< Shape<_1, ThreadCount>, 
                                            Stride<_0,          _1>>{}, 
                                     Layout<_1>{});   
    auto thr_g2s = tiled_g2s.get_slice(args.thread_idx);
    Tensor tGS_gRow = thr_g2s.partition_S(gRow);
    Tensor tGS_sRow = thr_g2s.partition_D(sRow);

    //// G2S: Coord 
    auto cRow = make_identity_tensor(make_shape(size<0>(CtaTileShapeMNK{}), size<1>(CtaTileShapeMNK{})));
    Tensor tGS_cRow = thr_g2s.partition_S(cRow);

    //// S2R: Smem to Reg
    Tensor tSR_sRow = sm90_partition_for_epilogue<ReferenceSrc>(sRow, args.epi_tile, args.tiled_copy, args.thread_idx);
    Tensor tSR_rRow = make_tensor_like(take<0,3>(tSR_sRow));                                           // (CPY,CPY_M,CPY_N)

    return ConsumerStoreCallbacks<decltype(tGS_gRow), decltype(tGS_sRow), decltype(tGS_cRow), decltype(tiled_g2s), decltype(tSR_sRow), decltype(tSR_rRow), decltype(args.tCcD), decltype(args.residue_cD), ThreadCount>(
      tGS_gRow, 
      tGS_sRow, 
      tGS_cRow, tiled_g2s, 
      tSR_sRow, 
      tSR_rRow, 
      args.tCcD, 
      args.residue_cD,
      ThreadCount{}, 
      params);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// Column vector broadcast
template<
  int Stages,
  class CtaTileShapeMNK,
  class Element,
  class StrideMNL = Stride<_1,_0,_0>,
  int Alignment = 128 / sizeof_bits_v<Element>,
  bool EnableNullptr = true // Fallback scalar broadcast for nullptr params
>
struct Sm90ColBroadcast {
  static_assert(Stages == 0, "Column broadcast doesn't support smem usage");
  static_assert(is_static_v<decltype(take<0,2>(StrideMNL{}))>); // batch stride can be dynamic or static
  static_assert(take<0,2>(StrideMNL{}) == Stride<_1,_0>{});

  // Accumulator distributes col elements evenly amongst threads so we can just directly load from gmem
  struct SharedStorage { };

  struct Arguments {
    Element const* ptr_col = nullptr;
    Element null_default = Element(0);
    StrideMNL dCol = {};
  };

  using Params = Arguments;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    return args;
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
    return (params.ptr_col == nullptr && params.null_default == Element(0));
  }

  CUTLASS_HOST_DEVICE
  Sm90ColBroadcast() { }

  CUTLASS_HOST_DEVICE
  Sm90ColBroadcast(Params const& params, SharedStorage const& shared_storage)
      : params(params) { }

  Params params;

  template <class... Args>
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(ProducerLoadArgs<Args...> const& args) {
    return EmptyProducerLoadCallbacks{};
  }

  template<class GTensor, class RTensor, class CTensor, class ThrResidue>
  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(GTensor&& tCgCol, RTensor&& tCrCol, CTensor tCcCol, ThrResidue residue_tCcCol, Params const& params)
      : tCgCol(cute::forward<GTensor>(tCgCol)),
        tCrCol(cute::forward<RTensor>(tCrCol)),
        tCcCol(tCcCol),
        residue_tCcCol(residue_tCcCol),
        params(params) {}

    GTensor tCgCol;                                                                    // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    RTensor tCrCol;                                                                    // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    CTensor tCcCol;                                                                    // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
    ThrResidue residue_tCcCol;
    Params const& params;

    CUTLASS_DEVICE void
    begin() {
      if constexpr (EnableNullptr) {
        if (params.ptr_col == nullptr) {
          fill(tCrCol, params.null_default);
          return;
        }
      }

      // Filter so we don't issue redundant copies over stride-0 modes
      // (only works if 0-strides are in same location, which is by construction)
      Tensor tCgCol_flt = filter_zeros(tCgCol);
      Tensor tCrCol_flt = filter_zeros(tCrCol);
      Tensor tCcCol_flt = make_tensor(tCcCol.data(), make_layout(tCrCol_flt.shape(), tCcCol.stride()));

      constexpr auto MCL = decltype(max_common_layout(tCgCol_flt, tCrCol_flt)){};
      constexpr int V = cute::min(Alignment, size(MCL));
      if constexpr (V > 1) {
        using VecType = uint_bit_t<V * sizeof_bits_v<Element>>;
        Tensor tCgCol_vec = recast<VecType>(coalesce(tCgCol_flt));
        Tensor tCrCol_vec = recast<VecType>(coalesce(tCrCol_flt));
        Tensor tCcCol_vec = tensor<1>(zipped_divide(tCcCol_flt, MCL.compose(Int<V>{})));
        auto pred_fn = [&] (auto const&... coords) { return elem_less(tCcCol_vec(coords...), residue_tCcCol); };
        copy_if(pred_fn, tCgCol_vec, tCrCol_vec);
      }
      else {
        auto pred_fn = [&] (auto const&... coords) { return elem_less(tCcCol_flt(coords...), residue_tCcCol); };
        copy_if(pred_fn, tCgCol_flt, tCrCol_flt);
      }
    }

    template <typename ElementAccumulator, int FragmentSize>
    CUTLASS_DEVICE Array<Element, FragmentSize>
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n) {
      Array<Element, FragmentSize> frg_col;
      Tensor tCrCol_mn = tCrCol(_,_,_,epi_m,epi_n);

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < FragmentSize; ++i) {
        frg_col[i] = tCrCol_mn(epi_v * FragmentSize + i);
      }

      return frg_col;
    }

  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class... Args
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(ConsumerStoreArgs<Args...> const& args) {

    auto [M, N, K, L] = args.problem_shape_mnkl;
    Tensor mCol = make_tensor(make_gmem_ptr(params.ptr_col), make_shape(M,N,L), params.dCol);
    Tensor tCgCol = sm90_partition_for_epilogue<ReferenceSrc>(                         // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)
      mCol, args.tile_shape_mnk, args.tile_coord_mnkl, args.epi_tile, args.tiled_copy, args.thread_idx);
    Tensor tCrCol = make_tensor_like(tCgCol);                                          // (CPY,CPY_M,CPY_N,EPI_M,EPI_N)

    return ConsumerStoreCallbacks<decltype(tCgCol), decltype(tCrCol), decltype(args.tCcD), decltype(args.residue_tCcD)>(
      cute::move(tCgCol), cute::move(tCrCol), args.tCcD, args.residue_tCcD, params);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// Batch matrix broadcast
// Only need to redefine this if we can multicast across cluster L
template <
  int Stages,
  class EpilogueTile,
  class Element,
  class StrideMNL,
  class SmemLayoutAtom,
  class CopyOpS2R,
  int Alignment = 128 / sizeof_bits_v<Element>,
  bool EnableNullptr = true // Fallback scalar broadcast for nullptr params
>
using Sm90MatrixBroadcast
  = Sm90AuxLoad<Stages, EpilogueTile, Element, StrideMNL, SmemLayoutAtom, CopyOpS2R, EnableNullptr>;

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::epilogue::fusion

/////////////////////////////////////////////////////////////////////////////////////////////////
