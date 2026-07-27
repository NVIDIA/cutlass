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
#include "cutlass/epilogue/fusion/sm90_visitor_load_tma_warpspecialized.hpp"    // Sm90ScalarBroadcast(PtrArray)
#include "cutlass/epilogue/fusion/sm90_visitor_store_tma_warpspecialized.hpp"   // Sm90Aux(Array)Store
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

template<
  bool PtrArray,
  bool Quantize,
  template <class> class ActivationFn,
  int Stages,
  int NumEpilogueWarpGroups,
  class EpilogueTile,
  class StrideMNL,
  class SmemLayoutAtom,
  class CopyOpR2S,
  class ElementOutput,
  class ElementCompute,
  class ElementScalar = ElementCompute,
  FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest>
struct Sm90GatedActivation
{
  // Transparently handle PtrArray/GroupGemm case by using a dummy shape on host
  template<class ProblemShape>
  CUTLASS_HOST_DEVICE
  static constexpr auto
  get_problem_shape(ProblemShape const& problem_shape) {
    if constexpr (PtrArray) {
      return typename ProblemShape::UnderlyingProblemShape{};
    }
    else {
      return problem_shape;
    }
  }

  // Convert input problem shape [(M,2),N,K,L] to output problem shape [M,N,K,L]
  template<class Shape>
  CUTLASS_HOST_DEVICE
  static constexpr auto
  to_output_shape(Shape const& shape) {
    using namespace cute;
    static_assert(CUTE_STATIC_V(rank<0>(shape)) == 3, "Input shape/coord must have a rank-3 M-mode");
    auto M = remove<1>(get<0>(shape));
    return replace<0>(shape, M);
  }

  using EpilogueTileOut = decltype(to_output_shape(EpilogueTile{}));

  // Define sub-EVTs below that will be invoked manually
  // Cannot compose them using normal EVT structure due to gated activation logic:
  // 1. Compute EVT (activation) is only visited on "bottom" half of the values
  // 2. Store EVT is visited after multiplying gating and activation values, 
  //    which needs access to the whole epilogue tile, i.e. in reduce()

  using ComputeOp = Sm90Compute<ActivationFn, ElementCompute, ElementCompute, RoundStyle>;
  using ComputeEVT = Sm90EVT<ComputeOp, Sm90AccFetch>; // leaf input slot

  using StoreOp = cute::conditional_t<PtrArray,
    Sm90AuxArrayStore<Stages, NumEpilogueWarpGroups, EpilogueTileOut, ElementOutput, RoundStyle, StrideMNL, SmemLayoutAtom, CopyOpR2S>,
    Sm90AuxStore<Stages, EpilogueTileOut, ElementOutput, RoundStyle, StrideMNL, SmemLayoutAtom, CopyOpR2S>
  >;
  using ScaleOp = Sm90EVT<Sm90Compute<multiplies, ElementCompute, ElementCompute, RoundStyle>,         // scale op
                          Sm90ScalarBroadcastSelector<PtrArray, ElementScalar, Stride<_0,_0,int64_t>>, // scale factor broadcast
                          Sm90AccFetch>;                                                               // leaf input slot
  using StoreEVT = Sm90EVT<StoreOp, cute::conditional_t<Quantize, ScaleOp, Sm90AccFetch>>;

  // Delegate most operations to generic Sm90Visitor even though we don't inherit from it
  using Impl = Sm90EVT<StoreEVT, ComputeEVT>;

  using SharedStorage = typename Impl::SharedStorage;
  using Arguments = typename Impl::Arguments;
  using Params = typename Impl::Params;
  template <bool IsLoad>
  using TensorMaps = typename Impl::template TensorMaps<IsLoad>;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    return Impl::to_underlying_arguments(to_output_shape(get_problem_shape(problem_shape)), args, workspace);
  }

  template <class ProblemShape>
  static bool
  can_implement(ProblemShape const& problem_shape, Arguments const& args) {
    // unlike other host APIs, can_implement gets passed underlying problem shape for Grouped Gemm cases
    return Impl::can_implement(to_output_shape(problem_shape), args);
  }

  template <class ProblemShape>
  static size_t
  get_workspace_size(ProblemShape const& problem_shape, Arguments const& args) {
    return Impl::get_workspace_size(to_output_shape(get_problem_shape(problem_shape)), args);
  }

  template <class ProblemShape>
  static cutlass::Status
  initialize_workspace(ProblemShape const& problem_shape, Arguments const& args, void* workspace, cudaStream_t stream,
    CudaHostAdapter* cuda_adapter = nullptr) {
    return Impl::initialize_workspace(to_output_shape(get_problem_shape(problem_shape)), args, workspace, stream);
  }

  CUTLASS_HOST_DEVICE
  Sm90GatedActivation() : impl() { }

  CUTLASS_HOST_DEVICE
  Sm90GatedActivation(Params const& params, SharedStorage const& shared_storage)
    : impl(params, shared_storage) { }

  Impl impl;

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    return impl.is_producer_load_needed();
  }

  CUTLASS_DEVICE bool
  is_C_load_needed() const {
    return impl.is_C_load_needed();
  }

  template <class... Args>
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(ProducerLoadArgs<Args...> const& args) {
    return impl.get_producer_load_callbacks(args);
  }

  template <
    class CallbacksImpl,
    class CrdTensor
  >
  struct ConsumerStoreCallbacks : CallbacksImpl {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(
        CallbacksImpl impl,
        CrdTensor tRS_cD)
    : CallbacksImpl(impl), 
      tRS_cD(tRS_cD) {}

    using CallbacksImpl::callbacks_tuple;
    CrdTensor tRS_cD;

    template <typename ElementAccumulator, typename ElementInput, int FragmentSize>
    CUTLASS_DEVICE auto
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc, int epi_v, int epi_m, int epi_n,
          Array<ElementInput, FragmentSize> const& frg_input) {
      using namespace cute;

      static_assert(FragmentSize % 4 == 0, "Fragment size is too small");
      using FrgOutput = Array<ElementInput, FragmentSize / 2>;

      // This splitting relies on details of WGMMA accumulator register layout
      Tensor input = flat_divide(make_tensor(frg_input.data(), Int<FragmentSize>{}), Layout<Shape<_2,_2>>{});
      Tensor input_val = make_tensor_like(input(_,0,_));
      Tensor input_act = make_tensor_like(input(_,1,_));
      copy(input(_,0,_), input_val);
      copy(input(_,1,_), input_act);

      FrgOutput const& frg_input_val = recast<FrgOutput>(input_val)(0);
      FrgOutput const& frg_input_act = recast<FrgOutput>(input_act)(0);

      // store(gemm0 * act(gemm1))
      FrgOutput frg_output_act = get<0>(callbacks_tuple).visit(frg_input_act, epi_v, epi_m, epi_n);
      FrgOutput frg_output = frg_input_val * frg_output_act;
      get<1>(callbacks_tuple).visit(frg_output, epi_v, epi_m, epi_n);

      return frg_input;
    }
  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class... Args
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(ConsumerStoreArgs<Args...> const& args) {

    using namespace cute;

    // Transform TV layout of the tiled copy by removing every other group of 8 rows.
    // Note: assumes by-mode tilers that are bijective here - not necessarily the case in general!

    auto tiler_mn = typename decltype(args.tiled_copy)::Tiler_MN{};
    auto layout_tv = typename decltype(args.tiled_copy)::TiledLayout_TV{};
    auto [tiler_m, tiler_n] = tiler_mn;
    int constexpr TileM = CUTE_STATIC_V(size(tiler_m));
    int constexpr TileN = CUTE_STATIC_V(size(tiler_n));
    auto row_selector = Layout<Shape<_8,Int<TileM/16>>, Stride<_1,_16>>{}; // select every other group of 8 rows
    auto col_selector = Layout<Int<TileN>>{};                              // select all columns

    auto tiler_mn_out =
      make_tile(
        right_inverse(
          make_layout_like(
            composition(
              right_inverse(tiler_m),
              row_selector
            )
          )
        ),
        tiler_n
      );

    auto layout_tv_out =
      right_inverse(                                                         // t,v/2 -> copy m/2,n
        composition(                                                         // copy m/2,n -> t,v/2
          make_layout_like(                                                  // real m/2,n -> t,v/2
            composition(                                                     // real m/2,n -> t,v/2
              composition(                                                   // real m,n -> t,v
                right_inverse(layout_tv).with_shape(shape(tiler_mn)),        // copy m,n -> t,v
                make_tile(right_inverse(tiler_m), right_inverse(tiler_n))    // real m,n -> copy m,n
              ),
              make_tile(row_selector, col_selector)                          // real m,n -> real m/2,n
            )
          ),
          tiler_mn_out
        )
      ).with_shape(make_shape(size<0>(layout_tv), size<1>(layout_tv)/_2{})); // t,v/2 -> copy m/2,n

    auto tiled_copy = TiledCopy<Copy_Atom<DefaultCopy,ElementCompute>, decltype(layout_tv_out), decltype(tiler_mn_out)>{};
    
    auto args_impl = ConsumerStoreArgs{
      to_output_shape(args.problem_shape_mnkl),
      to_output_shape(args.tile_shape_mnk),
      to_output_shape(args.tile_coord_mnkl),
      args.tiled_mma,
      EpilogueTileOut{},
      tiled_copy,
      args.cD,
      args.residue_cD,
      args.tCcD,
      args.residue_tCcD,
      args.tCrC,
      args.thread_idx
    };

    auto cst_impl = impl.get_consumer_store_callbacks<ReferenceSrc>(args_impl);

    return ConsumerStoreCallbacks<decltype(cst_impl), decltype(args.tCcD)>(
      cst_impl, 
      args.tCcD);
  }

  template <bool IsLoad, class CallbacksImpl>
  struct TensorMapCallbacks : CallbacksImpl {

    CUTLASS_DEVICE
    TensorMapCallbacks(CallbacksImpl&& impl) : CallbacksImpl(cute::move(impl)) {}
    
    template <class ProblemShape_MNKL>
    CUTLASS_DEVICE
    void
    perform_update(
        TensorMaps<IsLoad> tensormaps,
        ProblemShape_MNKL problem_shape_mnkl,
        int32_t next_batch,
        int32_t warp_group_idx)
    {
      CallbacksImpl::perform_update(tensormaps, to_output_shape(problem_shape_mnkl), next_batch, warp_group_idx);
    }
  };

  template <bool IsLoad>
  CUTLASS_DEVICE constexpr auto
  get_tensormap_callbacks() {
    auto tmap_callbacks = impl.template get_tensormap_callbacks<IsLoad>();
    return TensorMapCallbacks<IsLoad,decltype(tmap_callbacks)>(cute::move(tmap_callbacks));
  }
};

template<
  bool Quantize, // whether to quantize output with a per-tensor scale factor
  template <class> class ActivationFn,
  class GmemLayoutTagOutput,
  class ElementOutput,
  class ElementCompute,
  class ElementSource = ElementOutput,
  class ElementScalar = ElementCompute,
  class ElementIntermediate = ElementOutput,
  int Alignment = 128 / cute::sizeof_bits_v<ElementOutput>,
  FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest
>
struct LinCombGatedActFunc
    : LinearCombination<ElementOutput, ElementCompute, ElementSource, ElementScalar, RoundStyle> {
  using ElementAux = ElementOutput;
  using GmemLayoutTagAux = GmemLayoutTagOutput;
  static constexpr int AlignmentAux = Alignment;
  static constexpr bool IsAuxOutSupported = true;
};

template<
  bool PtrArray,
  bool Quantize,
  template <class> class ActivationFn,
  int Stages,
  int NumEpilogueWarpGroups,
  class EpilogueTile,
  class StrideMNL,
  class SmemLayoutAtom,
  class CopyOpR2S,
  class ElementOutput,
  class ElementCompute,
  class ElementSource = ElementOutput,
  class ElementScalar = ElementCompute,
  class ElementIntermediate = ElementOutput,
  FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest
>
using Sm90LinCombGatedActFunc =
  Sm90EVT<Sm90GatedActivation<PtrArray, Quantize, ActivationFn, Stages, NumEpilogueWarpGroups, EpilogueTile, StrideMNL,
                              SmemLayoutAtom, CopyOpR2S, ElementOutput, ElementCompute, ElementScalar, RoundStyle>,  // store(x(0) * f(x(1) * scale))
          // This is same as Sm90LinearCombinationPtrArray except it performs a roundrip cast to ElementIntermediate 
          // after accumulator scaling but before adding source (bias), which emulates precision of unfused path
          Sm90EVT<Sm90Compute<homogeneous_multiply_add, ElementCompute, ElementCompute, RoundStyle>, // beta * C + (alpha * acc)
                  Sm90ScalarBroadcastSelector<PtrArray, ElementScalar, Stride<_0,_0,int64_t>>, // beta
                  Sm90SrcFetch<ElementSource>, // C
                  Sm90EVT<Sm90Compute<multiplies, ElementIntermediate, ElementCompute, RoundStyle>, // alpha * acc
                          Sm90ScalarBroadcastSelector<PtrArray, ElementScalar, Stride<_0,_0,int64_t>>, // alpha
                          Sm90AccFetch // acc
                  >
          >
  >;

  template <
  // DispatchPolicy args
  int StagesC,
  int StagesD,
  int FragmentSize,
  bool ReuseSmemC,
  bool DelayTmaStore,
  // Fusion op args
  // Gated act + quantization args
  bool Quantize,
  template <class> class ActivationFn,
  // Store args
  class GmemLayoutTagOutput,
  // Element types
  class ElementOutput,
  class ElementCompute,
  class ElementSource,
  class ElementScalar,
  class ElementIntermediate,
  int Alignment,
  FloatRoundStyle RoundStyle,
  // Tile shape args
  class CtaTileShapeMNK,
  class EpilogueTile,
  // Aux store args
  class SmemLayoutAtom,
  class CopyOpR2S
>
struct FusionCallbacks<
    epilogue::Sm90TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore>,
    fusion::LinCombGatedActFunc<Quantize, ActivationFn, GmemLayoutTagOutput, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, Alignment, RoundStyle>,
    CtaTileShapeMNK,
    EpilogueTile,
    SmemLayoutAtom,
    CopyOpR2S
> : Sm90LinCombGatedActFunc<false, Quantize, ActivationFn, StagesD, 2, EpilogueTile, cutlass::gemm::TagToStrideC_t<GmemLayoutTagOutput>,
                            SmemLayoutAtom, CopyOpR2S, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle> {

  using Impl = Sm90LinCombGatedActFunc<false, Quantize, ActivationFn, StagesD, 2, EpilogueTile, cutlass::gemm::TagToStrideC_t<GmemLayoutTagOutput>,
                                       SmemLayoutAtom, CopyOpR2S, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle>;
  using Operation = fusion::LinCombGatedActFunc<Quantize, ActivationFn, GmemLayoutTagOutput, ElementOutput, ElementCompute,
                                                ElementSource, ElementScalar, ElementIntermediate, Alignment, RoundStyle>;

  struct Arguments {
    using StrideAlpha = Stride<_0,_0,int64_t>;
    ElementScalar               alpha = ElementScalar(1);
    ElementScalar const*        alpha_ptr{};
    StrideAlpha                 dAlpha{};

    using StrideBeta = Stride<_0,_0,int64_t>;
    ElementScalar               beta = ElementScalar(0);
    ElementScalar const*        beta_ptr{};
    StrideBeta                  dBeta{};

    using StrideScale = Stride<_0,_0,int64_t>;
    ElementScalar               scale = ElementScalar(1);
    ElementScalar const*        scale_ptr{};
    StrideScale                 dScale{};

    using StrideOutput = cutlass::gemm::TagToStrideC_t<GmemLayoutTagOutput>;
    ElementOutput* ptr_D{};
    StrideOutput dD{};

    int sm_count{};

    operator typename Impl::Arguments() const {

      using StoreArgs = decltype(typename Impl::Arguments{}.op_1.op_1);

      StoreArgs store_args = [&]{
        if constexpr (Quantize) {
          return StoreArgs
          {                                                        // custom node : conversion + store 
            {                                                        // binary op : conversion + scale
              {{scale}, {scale_ptr}, {dScale}},                        // leaf args : scalar broadcast (scale)
              {},                                                      // leaf args : acc fetch (input)
              {}                                                       // binary args : multiplies
            },
            {ptr_D, dD},                                             // unary op : aux store
          };
        }
        else {
          return StoreArgs
          {                                                        // unary op : aux store
            {},                                                      // leaf args : acc fetch (input)
            {ptr_D, dD}                                              // unary args : aux store
          };
        }
      }();

      return
        {                                                          // unary op: store(scale(gated_act(beta * C + (alpha * acc))))
          {                                                          // ternary op : beta * C + (alpha * acc)
            {{beta}, {beta_ptr}, {dBeta}},                             // leaf args : beta
            {},                                                        // leaf args : C
            {                                                          // binary op : alpha * acc
              {{alpha}, {alpha_ptr}, {dAlpha}},                          // leaf args : alpha
              {},                                                        // leaf args : acc
              {}                                                         // binary args : multiplies
            },
            {}                                                         // ternary args : multiply_add
          },
          {                                                        // custom node : gated_act+scale+store custom node
            {                                                        // unary op : act_func(input)
              {},                                                      // leaf args : input
              {}                                                       // unary args : act_func
            },
            store_args
          }
        };
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

template <
  // DispatchPolicy args
  int StagesC,
  int StagesD,
  int FragmentSize,
  bool ReuseSmemC,
  bool DelayTmaStore,
  int NumEpilogueWarpGroups,
  // Fusion op args
  // Gated act + quantization args
  bool Quantize,
  template <class> class ActivationFn,
  // Store args
  class GmemLayoutTagOutput,
  // Element types
  class ElementOutput,
  class ElementCompute,
  class ElementSource,
  class ElementScalar,
  class ElementIntermediate,
  int Alignment,
  FloatRoundStyle RoundStyle,
  // Tile shape args
  class CtaTileShapeMNK,
  class EpilogueTile,
  // Aux store args
  class SmemLayoutAtom,
  class CopyOpR2S
>
struct FusionCallbacks<
    epilogue::Sm90PtrArrayTmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore, NumEpilogueWarpGroups>,
    fusion::LinCombGatedActFunc<Quantize, ActivationFn, GmemLayoutTagOutput, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, Alignment, RoundStyle>,
    CtaTileShapeMNK,
    EpilogueTile,
    SmemLayoutAtom,
    CopyOpR2S
> : Sm90LinCombGatedActFunc<true, Quantize, ActivationFn, StagesD, NumEpilogueWarpGroups, EpilogueTile, cutlass::gemm::TagToStrideC_t<GmemLayoutTagOutput>,
                            SmemLayoutAtom, CopyOpR2S, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle> {

  using Impl = Sm90LinCombGatedActFunc<true, Quantize, ActivationFn, StagesD, NumEpilogueWarpGroups, EpilogueTile, cutlass::gemm::TagToStrideC_t<GmemLayoutTagOutput>,
                                       SmemLayoutAtom, CopyOpR2S, ElementOutput, ElementCompute, ElementSource, ElementScalar, ElementIntermediate, RoundStyle>;
  using Operation = fusion::LinCombGatedActFunc<Quantize, ActivationFn, GmemLayoutTagOutput, ElementOutput, ElementCompute,
                                                ElementSource, ElementScalar, ElementIntermediate, Alignment, RoundStyle>;

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

    using StrideOutput = cutlass::gemm::TagToStrideC_t<GmemLayoutTagOutput>;
    ElementOutput** ptr_D{};
    StrideOutput dD{};

    int sm_count{};

    operator typename Impl::Arguments() const {

      using StoreArgs = decltype(typename Impl::Arguments{}.op_1.op_1);

      StoreArgs store_args = [&]{
        if constexpr (Quantize) {
          return StoreArgs
          {                                                        // custom node : conversion + store 
            {                                                        // binary op : conversion + scale
              {{scale}, {scale_ptr}, {scale_ptr_array}, {dScale}},     // leaf args : scalar broadcast (scale)
              {},                                                      // leaf args : acc fetch (input)
              {}                                                       // binary args : multiplies
            },
            {ptr_D, dD, sm_count},                                   // unary op : aux store
          };
        }
        else {
          return StoreArgs
          {                                                        // unary op : aux store
            {},                                                      // leaf args : acc fetch (input)
            {ptr_D, dD, sm_count}                                    // unary args : aux store
          };
        }
      }();

      return
        {                                                          // unary op: store(scale(gated_act(beta * C + (alpha * acc))))
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
          {                                                        // custom node : gated_act+scale+store custom node
            {                                                        // unary op : act_func(input)
              {},                                                      // leaf args : input
              {}                                                       // unary args : act_func
            },
            store_args
          }
        };
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

} // namespace cutlass::epilogue::fusion 
