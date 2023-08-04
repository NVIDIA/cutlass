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
  \brief Visitor tree compute operations for the sm90 TMA warp-specialized (ws) epilogue
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/array.h"
#include "cutlass/numeric_conversion.h"

#include "cute/tensor.hpp"

#include "cutlass/epilogue/fusion/sm90_visitor_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_load_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_store_tma_warpspecialized.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::fusion {

using namespace cute;
using namespace detail;

/////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// N-nary Elementwise Compute Operation
//
/////////////////////////////////////////////////////////////////////////////////////////////////

template<
  template <class> class ComputeFn,
  class ElementOutput,
  class ElementCompute,
  FloatRoundStyle RoundStyle,
  class = void
>
struct Sm90Compute : Sm90VisitorImpl<> {

  using Sm90VisitorImpl<>::Sm90VisitorImpl;

  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    template <typename ElementAccumulator, typename... ElementInputs, int FragmentSize>
    CUTLASS_DEVICE Array<ElementOutput, FragmentSize>
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n,
          Array<ElementInputs, FragmentSize> const&... frg_inputs) {
      return transform_apply(cute::make_tuple(frg_inputs...),
        [&] (auto&& frg_input) {
          using ElementInput = typename cute::remove_cvref_t<decltype(frg_input)>::Element;
          using ConvertInput = NumericArrayConverter<ElementCompute, ElementInput, FragmentSize, RoundStyle>;
          ConvertInput convert_input{};

          return convert_input(frg_input);
        },
        [&] (auto&&... cvt_frg_inputs) {
          using ComputeOutput = ComputeFn<Array<ElementCompute, FragmentSize>>;
          using ConvertOutput = NumericArrayConverter<ElementOutput, ElementCompute, FragmentSize, RoundStyle>;
          ComputeOutput compute_output{};
          ConvertOutput convert_output{};

          return convert_output(compute_output(cvt_frg_inputs...));
        }
      );
    }

  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class TileShapeMNK,
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
    return ConsumerStoreCallbacks();
  }

};

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Performance Optimized Specializations
//
/////////////////////////////////////////////////////////////////////////////////////////////////

// beta * C + Z
template <
  class ElementOutput,
  class ElementCompute,
  FloatRoundStyle RoundStyle,
  class ElementScalar,
  class StrideScalar,
  int ScalarCount,
  template <class> class ScalarReduceFn,
  class InputAddOp // Z
>
struct Sm90TreeVisitor<
  Sm90Compute<multiply_add, ElementOutput, ElementCompute, RoundStyle>,
  Sm90ScalarBroadcast<ElementScalar, StrideScalar, ScalarCount, ScalarReduceFn>,
  Sm90SrcFetch,
  InputAddOp
> : Sm90VisitorImpl<
      Sm90ScalarBroadcast<ElementScalar, StrideScalar, ScalarCount, ScalarReduceFn>,
      Sm90SrcFetch,
      InputAddOp,
      Sm90Compute<multiply_add, ElementOutput, ElementCompute, RoundStyle>
    >
{
  using Impl =
    Sm90VisitorImpl<
      Sm90ScalarBroadcast<ElementScalar, StrideScalar, ScalarCount, ScalarReduceFn>,
      Sm90SrcFetch,
      InputAddOp,
      Sm90Compute<multiply_add, ElementOutput, ElementCompute, RoundStyle>
    >;

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    auto const& bcast_op = get<0>(Impl::ops);
    auto const& added_op = get<2>(Impl::ops);
    return not (bcast_op.params_ptr->dScalar == Stride<_0,_0,_0>{} && not is_C_load_needed()) ||
           added_op.is_producer_load_needed();
  }

  CUTLASS_DEVICE bool
  is_C_load_needed() const {
    auto const& bcast_op = get<0>(Impl::ops);
    auto const& added_op = get<2>(Impl::ops);
    return bcast_op.scalar != 0 || added_op.is_C_load_needed();
  }

  using Impl::Sm90VisitorImpl;

  template <class CallbacksImpl>
  struct ConsumerStoreCallbacks : CallbacksImpl {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(bool is_C_load_needed, CallbacksImpl&& impl)
      : is_C_load_needed(is_C_load_needed), CallbacksImpl(cute::forward<CallbacksImpl>(impl)) { }

    bool is_C_load_needed;

    template <typename ElementAccumulator, int FragmentSize>
    CUTLASS_DEVICE Array<ElementOutput, FragmentSize>
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n) {
      Array frg_added = get<2>(CallbacksImpl::callbacks_tuple).visit(frg_acc, epi_v, epi_m, epi_n);

      using ElementZ = typename decltype(frg_added)::Element;
      using ConvertZ = NumericArrayConverter<ElementCompute, ElementZ, FragmentSize, RoundStyle>;
      using ConvertI = NumericArrayConverter<ElementOutput, ElementCompute, FragmentSize, RoundStyle>;
      ConvertZ convert_Z{};
      ConvertI convert_I{};

      Array frg_I = convert_Z(frg_added);

      if (is_C_load_needed) {
        Array frg_scalar = get<0>(CallbacksImpl::callbacks_tuple).visit(frg_acc, epi_v, epi_m, epi_n);
        Array frg_source = get<1>(CallbacksImpl::callbacks_tuple).visit(frg_acc, epi_v, epi_m, epi_n);

        using ElementX = typename decltype(frg_scalar)::Element;
        using ElementY = typename decltype(frg_source)::Element;
        using ConvertX = NumericArrayConverter<ElementCompute, ElementX, FragmentSize, RoundStyle>;
        using ConvertY = NumericArrayConverter<ElementCompute, ElementY, FragmentSize, RoundStyle>;
        using ComputeI = multiply_add<Array<ElementCompute, FragmentSize>>;
        ConvertX convert_X{};
        ConvertY convert_Y{};
        ComputeI compute_I{};

        frg_I = compute_I(convert_X(frg_scalar), convert_Y(frg_source), frg_I);
      }

      return convert_I(frg_I);
    }
  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class TileShapeMNK,
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
    return ConsumerStoreCallbacks(
      is_C_load_needed(),
      Impl::get_consumer_store_callbacks<ReferenceSrc>(
        problem_shape_mnkl,
        tile_shape_mnk,
        tile_coord_mnkl,
        epi_tile,
        tiled_copy,
        thread_idx,
        tCrC
      )
    );
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::epilogue::fusion

/////////////////////////////////////////////////////////////////////////////////////////////////
