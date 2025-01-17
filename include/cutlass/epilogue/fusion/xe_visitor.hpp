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

using namespace cutlass;
using namespace cutlass::epilogue::fusion;

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Elementwise Load Operations
//
/////////////////////////////////////////////////////////////////////////////////////////////////

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
    assert(!find(args.dAux, 0) && "auxillary matrix should have no strides with values 0");
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

    using TiledMma = decltype(args.tiled_mma);
    using MmaAtomShape = typename TiledMma::AtomShape_MNK;

    auto SG_M = get<0>(args.tile_shape_mnk);
    auto SG_N = get<1>(args.tile_shape_mnk);

    static constexpr int FragsM = SG_M / get<0>(MmaAtomShape()); // A frags per sub_group
    static constexpr int FragsN = SG_N / get<1>(MmaAtomShape()); // B frags per sub_group

    auto [M, N, K, L] = args.problem_shape_mnkl;
    auto [m_coord, n_coord, k_coord, l_coord] = args.tile_coord_mnkl;
    auto m_offset = m_coord * SG_M;
    auto n_offset = n_coord * SG_N;
    Tensor rw_coord = args.tiled_copy.get_pvc_tensor(
            make_coord(m_offset, n_offset, l_coord),
            make_shape(_, Int<FragsM>{}, Int<FragsN>{}));

    return ConsumerStoreCallbacks(
        rw_coord, xe_copy_aux, cute::move(trAux), params_ptr
    );
  }
};

