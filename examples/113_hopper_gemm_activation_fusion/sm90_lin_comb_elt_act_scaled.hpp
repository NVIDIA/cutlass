/***************************************************************************************************
 * Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
  \brief Visitor tree node for gated activation function
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/workspace.h"

#include "cute/tensor.hpp"

#include "cutlass/epilogue/fusion/sm90_callbacks_tma_warpspecialized.hpp"       // Sm90EVT
#include "cutlass/epilogue/fusion/sm90_visitor_load_tma_warpspecialized.hpp"    // Sm90ScalarBroadcastPtrArray
#include "cutlass/epilogue/fusion/sm90_visitor_store_tma_warpspecialized.hpp"   // Sm90AuxArrayStore
#include "cutlass/epilogue/fusion/sm90_visitor_compute_tma_warpspecialized.hpp" // Sm90Compute

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::fusion {

template<
  bool PtrArray,
  class Element,
  class Stride>
using Sm90ScalarBroadcastSelector = cute::conditional_t<PtrArray,
  Sm90ScalarBroadcastPtrArray<Element, Stride>,
  Sm90ScalarBroadcast<Element, Stride>
>;

// D = activation(alpha * acc + beta * C)
template<
  bool DoScale,
  template <class> class ActivationFn_,
  class ElementOutput,
  class ElementCompute,
  class ElementSource = ElementOutput,
  class ElementScalar = ElementCompute,
  class ElementIntermediate = ElementOutput,
  FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest
>
struct AccCastLinCombEltActScale
    : LinearCombination<ElementOutput, ElementCompute, ElementSource, ElementScalar, RoundStyle> {
  using ActivationFn = ActivationFn_<ElementCompute>;
  static constexpr bool IsEltActSupported = true;
};

// D = activation(alpha * acc + beta * C))
template<
  bool PtrArray,
  template <class> class ActivationFn,
  class ElementOutput,
  class ElementCompute,
  class ElementSource = ElementOutput,
  class ElementScalar = ElementCompute,
  class ElementIntermediate = ElementOutput,
  FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest
>
using Sm90AccCastLinCombEltAct =
  Sm90EVT<Sm90Compute<ActivationFn, ElementCompute, ElementCompute, RoundStyle>, // activation(beta * C + (alpha * acc))
          // This is same as Sm90LinearCombination except performs a roundrip cast to ElementIntermediate
          // after accumulator scaling but before adding source (bias)
          Sm90EVT<Sm90Compute<homogeneous_multiply_add, ElementCompute, ElementCompute, RoundStyle>, // beta * C + (alpha * acc)
                  Sm90ScalarBroadcastSelector<PtrArray, ElementScalar, Stride<_0,_0,int64_t>>, // beta
                  Sm90SrcFetch<ElementSource>, // C
                  Sm90EVT<Sm90Compute<multiplies, ElementIntermediate, ElementCompute, RoundStyle>, // alpha * acc
                          Sm90ScalarBroadcastSelector<PtrArray, ElementScalar, Stride<_0,_0,int64_t>>, // alpha
                          Sm90AccFetch // acc
                  >
          >
  >;

// D = scale * activation(alpha * acc + beta * C)
template<
  bool PtrArray,
  bool DoScale,
  template <class> class ActivationFn,
  class ElementOutput,
  class ElementCompute,
  class ElementSource = ElementOutput,
  class ElementScalar = ElementCompute,
  class ElementIntermediate = ElementOutput,
  FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest
>
using Sm90AccCastLinCombEltActScale =
  cute::conditional_t<DoScale,
    Sm90EVT<Sm90Compute<multiplies, ElementCompute, ElementCompute, RoundStyle>,
            Sm90ScalarBroadcastSelector<PtrArray, ElementScalar, Stride<_0,_0,int64_t>>,
            Sm90AccCastLinCombEltAct<PtrArray, ActivationFn, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle>
    >,
    Sm90AccCastLinCombEltAct<PtrArray, ActivationFn, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle>
  >;

template <
  int StagesC,
  int StagesD,
  int FragmentSize,
  bool ReuseSmemC,
  bool DelayTmaStore,
  bool DoScale,
  template <class> class ActivationFn,
  class ElementOutput,
  class ElementCompute,
  class ElementSource,
  class ElementScalar,
  class ElementIntermediate,
  FloatRoundStyle RoundStyle,
  class CtaTileShapeMNK,
  class EpilogueTile
>
struct FusionCallbacks<
    epilogue::Sm90TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore>,
    fusion::AccCastLinCombEltActScale<DoScale, ActivationFn, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle>,
    CtaTileShapeMNK,
    EpilogueTile
> : Sm90AccCastLinCombEltActScale<false, DoScale, ActivationFn, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle> {

  using Impl = Sm90AccCastLinCombEltActScale<false, DoScale, ActivationFn, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle>;
  using Operation = fusion::AccCastLinCombEltActScale<DoScale, ActivationFn, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle>;

  struct Arguments {

    using StrideAlpha = Stride<_0,_0,int64_t>;
    ElementScalar        alpha = ElementScalar(1);
    ElementScalar const* alpha_ptr{};
    StrideAlpha          dAlpha{};

    using StrideBeta  = Stride<_0,_0,int64_t>;
    ElementScalar        beta = ElementScalar(0);
    ElementScalar const* beta_ptr{};
    StrideBeta           dBeta{};

    using StrideScale = Stride<_0,_0,int64_t>;
    ElementScalar        scale = ElementScalar(1);
    ElementScalar const* scale_ptr{};
    StrideScale          dScale{};

    using ActivationArguments = typename Sm90Compute<ActivationFn, ElementCompute, ElementCompute, RoundStyle>::Arguments;
    ActivationArguments activation = ActivationArguments();

    operator typename Impl::Arguments() const {

      using SubImpl = Sm90AccCastLinCombEltAct<false, ActivationFn, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle>;
      typename SubImpl::Arguments actlincomb_args
      {                                       // unary op: activation(beta * C + (alpha * acc))
        {                                       // ternary op : beta * C + (alpha * acc)
          {{beta}, {beta_ptr}, {dBeta}},          // leaf args : beta
          {},                                     // leaf args : C
          {                                       // binary op : alpha * acc
            {{alpha}, {alpha_ptr}, {dAlpha}},       // leaf args : alpha
            {},                                     // leaf args : acc
            {}                                      // binary args : multiplies
          },
          {}                                      // ternary args : multiply_add
        },
        activation                              // unary args: activation
      };

      return [&]() {
        if constexpr (DoScale) {
          return typename Impl::Arguments
          {                                   // binary op : scale * (actlincomb)
            {{scale}, {scale_ptr}, {dScale}},   // leaf args : scale
            actlincomb_args,                    // leaf_args : actlincomb
            {}                                  // leaf args : multiplies
          };
        }
        else {
          return actlincomb_args;
        }
      }();
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

template <
  int StagesC,
  int StagesD,
  int FragmentSize,
  bool ReuseSmemC,
  bool DelayTmaStore,
  int NumEpilogueWarpGroups,
  bool DoScale,
  template <class> class ActivationFn,
  class ElementOutput,
  class ElementCompute,
  class ElementSource,
  class ElementScalar,
  class ElementIntermediate,
  FloatRoundStyle RoundStyle,
  class CtaTileShapeMNK,
  class EpilogueTile
>
struct FusionCallbacks<
    epilogue::Sm90PtrArrayTmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore, NumEpilogueWarpGroups>,
    fusion::AccCastLinCombEltActScale<DoScale, ActivationFn, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle>,
    CtaTileShapeMNK,
    EpilogueTile
> : Sm90AccCastLinCombEltActScale<true, DoScale, ActivationFn, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle> {

  using Impl = Sm90AccCastLinCombEltActScale<true, DoScale, ActivationFn, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle>;
  using Operation = fusion::AccCastLinCombEltActScale<DoScale, ActivationFn, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle>;

  struct Arguments {

    using StrideAlpha = Stride<_0,_0,int64_t>;
    ElementScalar               alpha = ElementScalar(1);
    ElementScalar const*        alpha_ptr{};
    ElementScalar const* const* alpha_ptr_array{};
    StrideAlpha                 dAlpha{};

    using StrideBeta = Stride<_0,_0,int64_t>;
    ElementScalar               beta = ElementScalar(0);
    ElementScalar const*        beta_ptr{};
    ElementScalar const* const* beta_ptr_array{};
    StrideBeta                  dBeta{};

    using StrideScale = Stride<_0,_0,int64_t>;
    ElementScalar               scale = ElementScalar(1);
    ElementScalar const*        scale_ptr{};
    ElementScalar const* const* scale_ptr_array{};
    StrideScale                 dScale{};

    using ActivationArguments = typename Sm90Compute<ActivationFn, ElementCompute, ElementCompute, RoundStyle>::Arguments;
    ActivationArguments activation = ActivationArguments();

    operator typename Impl::Arguments() const {

      using SubImpl = Sm90AccCastLinCombEltAct<true, ActivationFn, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle>;
      typename SubImpl::Arguments actlincomb_args
      {                                                          // unary op: activation(beta * C + (alpha * acc))
        {                                                          // ternary op : beta * C + (alpha * acc)
          {{beta}, {beta_ptr}, {beta_ptr_array}, {dBeta}},           // leaf args : beta
          {},                                                        // leaf args : C
          {                                                          // binary op : alpha * acc
            {{alpha}, {alpha_ptr}, {alpha_ptr_array}, {dAlpha}},       // leaf args : alpha
            {},                                                        // leaf args : acc
            {}                                                         // binary args : multiplies
          },
          {}                                                         // ternary args : multiply_add
        },
        activation                                                 // unary args: activation
      };

      return [&]() {
        if constexpr (DoScale) {
          return typename Impl::Arguments
          {                                                      // binary op : scale * (actlincomb)
            {{scale}, {scale_ptr}, {scale_ptr_array}, {dScale}},   // leaf args : scale
            actlincomb_args,                                       // leaf args : actlincomb
            {}                                                     // leaf args : multiplies
          };
        }
        else {
          return actlincomb_args;
        }
      }();
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

} // namespace cutlass::epilogue::fusion 
