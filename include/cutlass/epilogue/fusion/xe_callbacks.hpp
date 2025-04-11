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
  \brief Fusion callbacks specializations for the Intel PVC epilogue
*/

#pragma once

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"

#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/fusion/callbacks.hpp"
#include "cutlass/epilogue/fusion/sm90_callbacks_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/xe_visitor.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_load_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_store_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_compute_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/xe_visitor_softmax.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::fusion {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  class ElementOutput_,
  class ElementCompute_,
  class ElementSource_,
  class ElementScalar_,
  FloatRoundStyle RoundStyle_,
  class CtaTileShapeMNK_,
  class EpilogueTile_
>
struct FusionCallbacks<
    epilogue::IntelPVCEpilogue,
    fusion::LinearCombination<ElementOutput_, ElementCompute_, ElementSource_, ElementScalar_, RoundStyle_>,
    CtaTileShapeMNK_,
    EpilogueTile_
> : Sm90LinearCombination<typename cutlass::detail::get_unpacked_element_type<ElementOutput_>::type, ElementCompute_, ElementSource_, ElementScalar_, RoundStyle_> {

  using Impl = Sm90LinearCombination<typename cutlass::detail::get_unpacked_element_type<ElementOutput_>::type, ElementCompute_, ElementSource_, ElementScalar_, RoundStyle_>;
  using ElementOutput = ElementOutput_;
  using ElementCompute = ElementCompute_;
  using ElementSource = ElementSource_;
  using ElementScalar = ElementScalar_;
  using Operation = fusion::LinearCombination<ElementOutput, ElementCompute, ElementSource_, ElementScalar, RoundStyle_>;

  struct Arguments {
    ElementScalar alpha = ElementScalar(1);
    ElementScalar beta = ElementScalar(0);
    ElementScalar const* alpha_ptr = nullptr;
    ElementScalar const* beta_ptr = nullptr;

    using StrideAlpha = Stride<_0,_0,int64_t>;
    using StrideBeta  = Stride<_0,_0,int64_t>;
    StrideAlpha dAlpha = {_0{}, _0{}, 0};
    StrideBeta  dBeta  = {_0{}, _0{}, 0};

    operator typename Impl::Arguments() const {
      return
        {    // ternary op : beta * C + (alpha * acc)
          {{beta}, {beta_ptr}, {dBeta}}, // leaf args : beta
          {},                   // leaf args : C
          {                     // binary op : alpha * acc
            {{alpha}, {alpha_ptr}, {dAlpha}}, // leaf args : alpha
            {},                     // leaf args : acc
            {}                  // binary args : multiplies
          },                    // end binary op
          {} // ternary args : multiply_add
        };   // end ternary op
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};


template <
  template <class> class ActivationFn_,
  class ElementOutput_,
  class ElementCompute_,
  class ElementSource_,
  class ElementScalar_,
  FloatRoundStyle RoundStyle_,
  class CtaTileShapeMNK_,
  class EpilogueTile_
>
struct FusionCallbacks<
    epilogue::IntelPVCEpilogue,
    fusion::LinCombEltAct<ActivationFn_, ElementOutput_, ElementCompute_, ElementSource_, ElementScalar_, RoundStyle_>,
    CtaTileShapeMNK_,
    EpilogueTile_
> : Sm90LinCombEltAct<ActivationFn_, ElementOutput_, ElementCompute_, ElementSource_, ElementScalar_, RoundStyle_> {

  using Impl = Sm90LinCombEltAct<ActivationFn_, typename cutlass::detail::get_unpacked_element_type<ElementOutput_>::type, ElementCompute_, ElementSource_, ElementScalar_, RoundStyle_>;
  using ElementOutput = ElementOutput_;
  using ElementCompute = ElementCompute_;
  using ElementSource = ElementSource_;
  using ElementScalar = ElementScalar_;
  using Operation = fusion::LinCombEltAct<ActivationFn_, ElementOutput_, ElementCompute_, ElementSource_, ElementScalar_, RoundStyle_>;

  struct Arguments {
    ElementScalar_ alpha = ElementScalar_(1);
    ElementScalar_ beta = ElementScalar_(0);
    ElementScalar_ const* alpha_ptr = nullptr;
    ElementScalar_ const* beta_ptr = nullptr;

    using StrideAlpha = Stride<_0,_0,int64_t>;
    using StrideBeta  = Stride<_0,_0,int64_t>;
    StrideAlpha dAlpha = {_0{}, _0{}, 0};
    StrideBeta  dBeta  = {_0{}, _0{}, 0};

    using ActivationArguments = typename Sm90Compute<ActivationFn_, ElementOutput_, ElementCompute_, RoundStyle_>::Arguments;
    ActivationArguments activation = ActivationArguments();

    operator typename Impl::Arguments() const {
      return
              {    // unary op: activation(beta * C + (alpha * acc))
                        {    // ternary op : beta * C + (alpha * acc)
                          {{beta}, {beta_ptr}, {dBeta}}, // leaf args : beta
                          {},                   // leaf args : C
                          {                     // binary op : alpha * acc
                                        {{alpha}, {alpha_ptr}, {dAlpha}}, // leaf args : alpha
                                        {},                     // leaf args : acc
                                        {}                  // binary args : multiplies
                          },                    // end binary op
                          {} // ternary args : multiply_add
                        },   // end ternary op
                        activation // unary args: activation
                };   // end unary op
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

// D = softmax(alpha * acc + beta * C)
template<
  // int FragmentSize,
  class CtaTileShapeMNK,
  class EpilogueTile,
  class ElementOutput,
  class ElementCompute,
  class CopyOpR2G,
  class ElementSource = ElementOutput,
  class ElementScalar = ElementCompute,
  FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest
>
using XeLinCombSoftmaxRow =
  Sm90EVT<XeSoftmaxRowReduction<CtaTileShapeMNK, EpilogueTile, ElementOutput, ElementCompute, CopyOpR2G, RoundStyle>, // softmax(beta * C + (alpha * acc))
    Sm90LinearCombination<ElementCompute, ElementCompute, ElementSource, ElementScalar, RoundStyle> // beta * C + (alpha * acc)
  >;

template <
  // int FragmentSize,
  class ElementOutput_,
  class ElementCompute_,
  class ElementSource_,
  class ElementScalar_,
  class CopyOpR2G_,
  FloatRoundStyle RoundStyle,
  class CtaTileShapeMNK,
  class EpilogueTile
>
struct FusionCallbacks<
    epilogue::IntelPVCEpilogue,
    fusion::LinCombSoftmaxRow<ElementOutput_, ElementCompute_, CopyOpR2G_, ElementSource_, ElementScalar_, RoundStyle>,
    CtaTileShapeMNK,
    EpilogueTile
> : XeLinCombSoftmaxRow<CtaTileShapeMNK, EpilogueTile, ElementOutput_, ElementCompute_, CopyOpR2G_, ElementSource_, ElementScalar_, RoundStyle> {

  using ElementOutput = ElementOutput_;
  using ElementCompute = ElementCompute_;
  using ElementSource = ElementSource_;
  using ElementScalar = ElementScalar_;
  using Impl = XeLinCombSoftmaxRow<CtaTileShapeMNK, EpilogueTile, typename cutlass::detail::get_unpacked_element_type<ElementOutput>::type, ElementCompute, CopyOpR2G_, ElementSource, ElementScalar, RoundStyle>;
  using Operation = fusion::LinCombSoftmaxRow<ElementOutput_, ElementCompute, CopyOpR2G_, ElementSource, ElementScalar, RoundStyle>;

  struct Arguments {
    ElementScalar alpha = ElementScalar(1);
    ElementScalar beta = ElementScalar(0);
    ElementScalar const* alpha_ptr = nullptr;
    ElementScalar const* beta_ptr = nullptr;
    ElementOutput* output_ptr = nullptr;

    operator typename Impl::Arguments() const {
      return
        {    // unary op: activation(beta * C + (alpha * acc))
          {    // ternary op : beta * C + (alpha * acc)
            {{beta}, {beta_ptr}}, // leaf args : beta
            {},                   // leaf args : C
            {                     // binary op : alpha * acc
              {{alpha}, {alpha_ptr}}, // leaf args : alpha
              {},                     // leaf args : acc
              {}                  // binary args : multiplies
            },                    // end binary op
            {} // ternary args : multiply_add
          },   // end ternary op
          {output_ptr} // unary args: activation
        };   // end unary op
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

template<
  class StrideAux,
  class CopyOpG2R,
  template <class> class ActivationFn,
  class ElementOutput,
  class ElementCompute,
  class ElementAux = ElementOutput,
  class ElementSource = ElementOutput,
  class ElementScalar = ElementCompute,
  FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest
>
using XeLinCombDeEltAct =
  Sm90EVT<Sm90Compute<ActivationFn, ElementOutput, ElementCompute, RoundStyle>, // activation(beta * C + (alpha * acc), aux)
    Sm90LinearCombination<ElementCompute, ElementCompute, ElementSource, ElementScalar, RoundStyle>, // beta * C + (alpha * acc)
    XeAuxLoad<ElementAux, StrideAux, CopyOpG2R> // aux
  >;

// Z = Aux
// dY = alpha * acc + beta * C
// D = activation(dY, Z)
//
template <
  class GmemLayoutTagAux,
  template <class> class ActivationFn,
  class ElementOutput_,
  class ElementCompute_,
  class ElementAux,
  class ElementSource,
  class ElementScalar,
  int AlignmentAux,
  FloatRoundStyle RoundStyle,
  class CtaTileShapeMNK,
  class EpilogueTile,
  class CopyOpG2R
>
struct FusionCallbacks<
    epilogue::IntelPVCEpilogue,
    fusion::LinCombDeEltAct<
      GmemLayoutTagAux, ActivationFn, ElementOutput_, ElementCompute_,
      ElementAux, ElementSource, ElementScalar, AlignmentAux, RoundStyle
    >,
    CtaTileShapeMNK,
    EpilogueTile,
    CopyOpG2R
> : XeLinCombDeEltAct<
      cutlass::gemm::TagToStrideC_t<GmemLayoutTagAux>, CopyOpG2R, ActivationFn, ElementOutput_,
      ElementCompute_, ElementAux, ElementSource, ElementScalar, RoundStyle
    > {

  using ElementOutput = ElementOutput_;
  using ElementCompute = ElementCompute_;

  using Impl =
    XeLinCombDeEltAct<
      cutlass::gemm::TagToStrideC_t<GmemLayoutTagAux>, CopyOpG2R, ActivationFn, ElementOutput,
      ElementCompute, ElementAux, ElementSource, ElementScalar, RoundStyle
    >;
  using Operation =
    fusion::LinCombDeEltAct<
      GmemLayoutTagAux, ActivationFn, ElementOutput, ElementCompute,
      ElementAux, ElementSource, ElementScalar, AlignmentAux, RoundStyle
    >;

  struct Arguments {
    ElementScalar alpha = ElementScalar(1);
    ElementScalar beta = ElementScalar(0);
    ElementScalar const* alpha_ptr = nullptr;
    ElementScalar const* beta_ptr = nullptr;

    using StrideAlpha = Stride<_0,_0,int64_t>;
    using StrideBeta  = Stride<_0,_0,int64_t>;
    StrideAlpha dAlpha = {_0{}, _0{}, 0};
    StrideBeta  dBeta  = {_0{}, _0{}, 0};

    using ActivationArguments = typename Sm90Compute<ActivationFn, ElementOutput, ElementCompute, RoundStyle>::Arguments;
    ActivationArguments activation = ActivationArguments();

    using StrideAux = cutlass::gemm::TagToStrideC_t<GmemLayoutTagAux>;
    ElementAux const* aux_ptr = nullptr;
    StrideAux dAux = {};

    operator typename Impl::Arguments() const {
      return
        {    // binary op : activation(beta * C + (alpha * acc), aux)
          {                  // ternary op : beta * C + (alpha * acc)
            {{beta}, {beta_ptr}, {dBeta}}, // leaf args : beta
            {},                   // leaf args : C
            {                     // binary op : alpha * acc
              {{alpha}, {alpha_ptr}, {dAlpha}}, // leaf args : alpha
              {},                     // leaf args : acc
              {}                  // binary args : multiplies
            },                    // end binary op
            {}               // ternary args : multiply_add
          },                 // end ternary op
          {aux_ptr, ElementAux(0), dAux}, // leaf args : aux
          activation // binary args : activation
        };   // end binary op
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// D = alpha * acc + beta * C + per-row bias
template <
  class ElementOutput_,
  class ElementCompute_,
  class ElementBias_,
  class ElementSource_,
  class ElementScalar_,
  int AlignmentBias_,
  FloatRoundStyle RoundStyle_,
  class CtaTileShapeMNK_,
  class EpilogueTile_
>
struct FusionCallbacks<
    epilogue::IntelPVCEpilogue,
    fusion::LinCombPerRowBias<ElementOutput_, ElementCompute_, ElementBias_, ElementSource_, ElementScalar_, AlignmentBias_, RoundStyle_>,
    CtaTileShapeMNK_,
    EpilogueTile_
> : Sm90LinCombPerRowBias<CtaTileShapeMNK_, ElementOutput_, ElementCompute_, ElementBias_, ElementSource_, ElementScalar_, AlignmentBias_, RoundStyle_> {

  using Impl = Sm90LinCombPerRowBias<
      CtaTileShapeMNK_,
      typename cutlass::detail::get_unpacked_element_type<ElementOutput_>::type,
      ElementCompute_, ElementBias_, ElementSource_, ElementScalar_,
      AlignmentBias_, RoundStyle_>;
  using ElementOutput = ElementOutput_;
  using ElementCompute = ElementCompute_;
  using ElementBias = ElementBias_;
  using ElementSource = ElementSource_;
  using ElementScalar = ElementScalar_;
  static constexpr int AlignmentBias = AlignmentBias_;
  using Operation = fusion::LinCombPerRowBias<ElementOutput_, ElementCompute_, ElementBias_, ElementSource_, ElementScalar_, AlignmentBias_, RoundStyle_>;

  struct Arguments {
    ElementScalar_ alpha = ElementScalar_(1);
    ElementScalar_ beta = ElementScalar_(0);
    ElementScalar_ const* alpha_ptr = nullptr;
    ElementScalar_ const* beta_ptr = nullptr;

    using StrideAlpha = Stride<_0,_0,int64_t>;
    using StrideBeta  = Stride<_0,_0,int64_t>;
    StrideAlpha dAlpha = {_0{}, _0{}, 0};
    StrideBeta  dBeta  = {_0{}, _0{}, 0};

    using StrideBias = Stride<_1, _0, int64_t>;
    ElementBias const* bias_ptr = nullptr;
    StrideBias dBias = {};

    operator typename Impl::Arguments() const {
      return
        {     // ternary op : beta * C + (alpha * acc + bias)
          {{beta}, {beta_ptr}, {dBeta}}, // leaf args : beta
          {},                   // leaf args : C
          {                     // ternary op : alpha * acc + bias
            {{alpha}, {alpha_ptr}, {dAlpha}}, // leaf args : alpha
            {},                     // leaf args : acc
            {bias_ptr, ElementBias(0), dBias}, // leaf args : bias
            {}                  // ternary args : multiply_add
          },                    // end ternary op
          {} // ternary args : multiply_add
        };   // end ternary op
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

// D = alpha * acc + beta * C + per-column bias
template<
  int StagesC,
  class CtaTileShapeMNK,
  class EpilogueTile,
  class ElementOutput,
  class ElementCompute,
  class ElementBias = ElementOutput,
  class ElementSource = ElementOutput,
  class ElementScalar = ElementCompute,
  int AlignmentBias = 128 / sizeof_bits_v<ElementBias>,
  FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest
>
using XeLinCombPerColBias =
  Sm90EVT<Sm90Compute<homogeneous_multiply_add, ElementOutput, ElementCompute, RoundStyle>, // beta * C + (alpha * acc + bias)
    Sm90ScalarBroadcast<ElementScalar, Stride<_0,_0,int64_t>>, // beta
    Sm90SrcFetch<ElementSource>, // C
    Sm90EVT<Sm90Compute<homogeneous_multiply_add, ElementCompute, ElementCompute, RoundStyle>, // alpha * acc + bias
      Sm90ScalarBroadcast<ElementScalar, Stride<_0,_0,int64_t>>, // alpha
      Sm90AccFetch, // acc
      XeRowBroadcast<0, CtaTileShapeMNK, ElementBias, ElementCompute, Stride<_0,_1,int64_t>, AlignmentBias> // bias
    >
  >;

template <
  class ElementOutput_,
  class ElementCompute_,
  class ElementBias_,
  class ElementSource_,
  class ElementScalar_,
  int AlignmentBias_,
  FloatRoundStyle RoundStyle_,
  class CtaTileShapeMNK_,
  class EpilogueTile_
>
struct FusionCallbacks<
    epilogue::IntelPVCEpilogue,
    fusion::LinCombPerColBias<ElementOutput_, ElementCompute_, ElementBias_, ElementSource_, ElementScalar_, AlignmentBias_, RoundStyle_>,
    CtaTileShapeMNK_,
    EpilogueTile_
> : XeLinCombPerColBias<_1{} /* Stages */, CtaTileShapeMNK_, EpilogueTile_, ElementOutput_, ElementCompute_, ElementBias_, ElementSource_, ElementScalar_, AlignmentBias_, RoundStyle_> {

  using Impl = XeLinCombPerColBias<
      _1{},
      CtaTileShapeMNK_,
      EpilogueTile_, 
      typename cutlass::detail::get_unpacked_element_type<ElementOutput_>::type,
      ElementCompute_, ElementBias_, ElementSource_, ElementScalar_,
      AlignmentBias_, RoundStyle_>;
  using ElementOutput = ElementOutput_;
  using ElementCompute = ElementCompute_;
  using ElementBias = ElementBias_;
  using ElementSource = ElementSource_;
  using ElementScalar = ElementScalar_;
  static constexpr int AlignmentBias = AlignmentBias_;
  using Operation = fusion::LinCombPerColBias<ElementOutput_, ElementCompute_, ElementBias_, ElementSource_, ElementScalar_, AlignmentBias_, RoundStyle_>;

  struct Arguments {
    ElementScalar_ alpha = ElementScalar_(1);
    ElementScalar_ beta = ElementScalar_(0);
    ElementScalar_ const* alpha_ptr = nullptr;
    ElementScalar_ const* beta_ptr = nullptr;

    using StrideAlpha = Stride<_0,_0,int64_t>;
    using StrideBeta  = Stride<_0,_0,int64_t>;
    StrideAlpha dAlpha = {_0{}, _0{}, 0};
    StrideBeta  dBeta  = {_0{}, _0{}, 0};

    using StrideBias = Stride<_0, _1, int64_t>;
    ElementBias const* bias_ptr = nullptr;
    StrideBias dBias = {};

    operator typename Impl::Arguments() const {
      return
        {     // ternary op : beta * C + (alpha * acc + bias)
          {{beta}, {beta_ptr}, {dBeta}}, // leaf args : beta
          {},                   // leaf args : C
          {                     // ternary op : alpha * acc + bias
            {{alpha}, {alpha_ptr}, {dAlpha}}, // leaf args : alpha
            {},                     // leaf args : acc
            {bias_ptr, ElementBias(0), dBias}, // leaf args : bias
            {}                  // ternary args : multiply_add
          },                    // end ternary op
          {} // ternary args : multiply_add
        };   // end ternary op
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

template <
  int TopK,
  class ElementOutput_,
  class ElementCompute_,
  class ElementSource_,
  class ElementScalar_,
  FloatRoundStyle RoundStyle,
  class CtaTileShapeMNK,
  class EpilogueTile
>
struct FusionCallbacks<
  epilogue::IntelPVCEpilogue,
  fusion::LinCombTopKSoftmaxCol<TopK, ElementOutput_, ElementCompute_, ElementSource_, ElementScalar_, RoundStyle>,
  CtaTileShapeMNK,
  EpilogueTile
> : Sm90LinCombTopKSoftmaxCol<TopK, 8 /*FragmentSize*/, CtaTileShapeMNK, EpilogueTile, ElementOutput_, ElementCompute_, ElementSource_, ElementScalar_, RoundStyle> {

  static constexpr int FragmentSize = 8;
  using ElementOutput = ElementOutput_;
  using ElementCompute = ElementCompute_;
  using ElementSource = ElementSource_;
  using ElementScalar = ElementScalar_;
  using Impl = Sm90LinCombTopKSoftmaxCol<TopK, FragmentSize, CtaTileShapeMNK, EpilogueTile, 
                                        typename cutlass::detail::get_unpacked_element_type<ElementOutput>::type, 
                                        ElementCompute, ElementSource, ElementScalar, RoundStyle>;
  using Operation = fusion::LinCombTopKSoftmaxCol<TopK, ElementOutput, ElementCompute, ElementSource, ElementScalar, RoundStyle>;

  struct Arguments {
    ElementScalar alpha = ElementScalar(1);
    ElementScalar beta = ElementScalar(0);
    ElementScalar const* alpha_ptr = nullptr;
    ElementScalar const* beta_ptr = nullptr;

    operator typename Impl::Arguments() const {
      return
        {    // unary op: activation(beta * C + (alpha * acc))
          {    // ternary op : beta * C + (alpha * acc)
            {{beta}, {beta_ptr}}, // leaf args : beta
            {},                   // leaf args : C
            {                     // binary op : alpha * acc
              {{alpha}, {alpha_ptr}}, // leaf args : alpha
              {},                     // leaf args : acc
              {}                  // binary args : multiplies
            },                    // end binary op
            {} // ternary args : multiply_add
          },   // end ternary op
          {} // unary args: activation
        };   // end unary op
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// D = activation(alpha * acc + beta * C + per-row bias)

template <
 // int FragmentSize,
  //bool ReuseSmemC,
 // bool DelayTmaStore,
  template <class> class ActivationFn_,
  class ElementOutput_,
  class ElementCompute_,
  class ElementBias_,
  class ElementSource_,
  class ElementScalar_,
  int AlignmentBias_,
  FloatRoundStyle RoundStyle_,
  class CtaTileShapeMNK_,
  class EpilogueTile_
>
struct FusionCallbacks<
     epilogue::IntelPVCEpilogue,
    fusion::LinCombPerRowBiasEltAct<
      ActivationFn_, ElementOutput_, ElementCompute_, ElementBias_, ElementSource_, ElementScalar_, AlignmentBias_, RoundStyle_
    >,
    CtaTileShapeMNK_,
    EpilogueTile_
> : Sm90LinCombPerRowBiasEltAct<
      CtaTileShapeMNK_, ActivationFn_, ElementOutput_, ElementCompute_, ElementBias_, ElementSource_, ElementScalar_, AlignmentBias_, RoundStyle_
    > {

  using ElementOutput = ElementOutput_;
  using ElementCompute = ElementCompute_;
  using ElementBias = ElementBias_;
  using ElementSource = ElementSource_;
  using ElementScalar = ElementScalar_;
  static constexpr int AlignmentBias = AlignmentBias_;
  using Impl =
    Sm90LinCombPerRowBiasEltAct<
      CtaTileShapeMNK_, ActivationFn_, ElementOutput, ElementCompute, ElementBias, ElementSource, ElementScalar, AlignmentBias, RoundStyle_
    >;
  using Operation =
    fusion::LinCombPerRowBiasEltAct<
      ActivationFn_, ElementOutput, ElementCompute, ElementBias, ElementSource, ElementScalar, AlignmentBias, RoundStyle_
    >;

  struct Arguments {
    ElementScalar alpha = ElementScalar(1);
    ElementScalar beta = ElementScalar(0);
    ElementScalar const* alpha_ptr = nullptr;
    ElementScalar const* beta_ptr = nullptr;

    using StrideAlpha = Stride<_0,_0,int64_t>;
    using StrideBeta  = Stride<_0,_0,int64_t>;
    StrideAlpha dAlpha = {_0{}, _0{}, 0};
    StrideBeta  dBeta  = {_0{}, _0{}, 0};

    using StrideBias = Stride<_1,_0,int64_t>;
    ElementBias const* bias_ptr = nullptr;
    StrideBias dBias = {};

    using ActivationArguments = typename Sm90Compute<ActivationFn_, ElementOutput, ElementCompute, RoundStyle_>::Arguments;
    ActivationArguments activation = ActivationArguments();

    operator typename Impl::Arguments() const {
      return
        {    // unary op : activation(beta * C + (alpha * acc + bias))
          {    // ternary op : beta * C + (alpha * acc + bias)
            {{beta}, {beta_ptr}, {dBeta}}, // leaf args : beta
            {},                   // leaf args : C
            {                     // ternary op : alpha * acc + bias
              {{alpha}, {alpha_ptr}, {dAlpha}}, // leaf args : alpha
              {},                     // leaf args : acc
              {bias_ptr, ElementBias(0), dBias}, // leaf args : bias
              {}                  // ternary args : multiply_add
            },                    // end ternary op
            {} // ternary args : multiply_add
          },   // end ternary op
          activation // unary args : activation
        };   // end unary op
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

/////////////////////////////////////////////////////////////////////////////////////////////
// D = alpha * acc + beta * C, where beta and alpha can be vectors for each batch
template <
  class ElementOutput_,
  class ElementCompute_,
  class ElementSource_,
  class ElementScalar_,
  FloatRoundStyle RoundStyle_,
  class CtaTileShapeMNK_,
  class EpilogueTile_
>
struct FusionCallbacks<
    epilogue::IntelPVCGroupEpilogue,
    fusion::LinearCombination<ElementOutput_, ElementCompute_, ElementSource_, ElementScalar_, RoundStyle_>,
    CtaTileShapeMNK_,
    EpilogueTile_
> : Sm90LinearCombinationPtrArray<typename cutlass::detail::get_unpacked_element_type<ElementOutput_>::type, ElementCompute_, ElementSource_, ElementScalar_, RoundStyle_> {

  using Impl = Sm90LinearCombinationPtrArray<typename cutlass::detail::get_unpacked_element_type<ElementOutput_>::type, ElementCompute_, ElementSource_, ElementScalar_, RoundStyle_>;
  using ElementOutput = ElementOutput_;
  using ElementCompute = ElementCompute_;
  using ElementSource = ElementSource_;
  using ElementScalar = ElementScalar_;
  using Operation = fusion::LinearCombination<ElementOutput, ElementCompute, ElementSource, ElementScalar, RoundStyle_>;

  struct Arguments {
    ElementScalar alpha = ElementScalar(1);
    ElementScalar beta = ElementScalar(0);
    ElementScalar const* alpha_ptr = nullptr;
    ElementScalar const* beta_ptr = nullptr;
    ElementScalar const* const* alpha_ptr_array = nullptr;
    ElementScalar const* const* beta_ptr_array = nullptr;

    using StrideAlpha = Stride<_0,_0,int64_t>;
    using StrideBeta  = Stride<_0,_0,int64_t>;
    StrideAlpha dAlpha = {_0{}, _0{}, 0};
    StrideBeta  dBeta  = {_0{}, _0{}, 0};

    operator typename Impl::Arguments() const {
      return
        {    // ternary op : beta * C + (alpha * acc)
          {{beta}, {beta_ptr}, {beta_ptr_array}, {dBeta}}, // leaf args : beta
          {},                   // leaf args : C
          {                     // binary op : alpha * acc
            {{alpha}, {alpha_ptr}, {alpha_ptr_array}, {dAlpha}}, // leaf args : alpha
            {},                     // leaf args : acc
            {}                  // binary args : multiplies
          },                    // end binary op
          {} // ternary args : multiply_add
        };   // end ternary op
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::epilogue::fusion

/////////////////////////////////////////////////////////////////////////////////////////////////
