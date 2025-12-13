/***************************************************************************************************
 * Copyright (c) 2023 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
  \brief Fusion callbacks specializations for the sm90 TMA warp-specialized (ws) epilogue
*/

#pragma once

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"

#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_load_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_store_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_compute_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_topk_softmax.hpp"

#include "callbacks.hpp"
#include "../collective/dispatch_policy_extra.hpp"
#include "sm120_callbacks_tma_warpspecialized_dual.hpp"
#include "operations.hpp"
#include <utility>

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::fusion {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <class NodeOp, class... ChildOps>
using Sm90EVT = Sm90TreeVisitor<NodeOp, ChildOps...>;

// D = alpha * acc
template <
  int StagesC,
  int StagesD,
  int FragmentSize,
  bool ReuseSmemC,
  bool DelayTmaStore,
  class ElementOutput,
  class ElementCompute,
  class ElementScalar,
  FloatRoundStyle RoundStyle,
  class CtaTileShapeMNK,
  class EpilogueTile
>
struct DualFusionCallbacks<
    epilogue::DualSm90TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore>,
    fusion::DualScaledAcc<ElementOutput, ElementCompute, ElementScalar, RoundStyle>,
    CtaTileShapeMNK,
    EpilogueTile
> : Sm90EVT<Sm90Compute<multiplies, ElementOutput, ElementCompute, RoundStyle>,
      Sm90ScalarBroadcast<ElementScalar, Stride<_0,_0,int64_t>>, 
      Sm90AccFetch
    > {
  using Impl = 
    Sm90EVT<Sm90Compute<multiplies, ElementOutput, ElementCompute, RoundStyle>,
      Sm90ScalarBroadcast<ElementScalar, Stride<_0,_0,int64_t>>,
      Sm90AccFetch
    >;
  using Operation = fusion::DualScaledAcc<ElementOutput, ElementCompute, ElementScalar, RoundStyle>;

  struct Arguments {
    // Give a name and flat ordering to the fusion callback args
    ElementScalar alpha = ElementScalar(1);
    ElementScalar beta = ElementScalar(0);
    ElementScalar const* alpha_ptr = nullptr;
    ElementScalar const* beta_ptr = nullptr;

    using StrideAlpha = Stride<_0,_0,int64_t>;
    StrideAlpha dAlpha = {_0{}, _0{}, 0};

    // Conversion to the args expected by the visitor implementation
    // to_underlying_arguments will implicitly call this
    operator typename Impl::Arguments() const {
      return
        {    // binary op : alpha * acc
          {{alpha}, {alpha_ptr}, {dAlpha}}, // leaf args : alpha
          {},                     // leaf args : acc
          {} // binary args : multiplies
        };   // end binary op
    }
  };

  // Ctor inheritance
  using Impl::Impl;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// D = alpha * acc + beta * C
template<
  class ElementOutput,
  class ElementCompute,
  class ElementSource = ElementOutput,
  class ElementScalar = ElementCompute,
  FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest
>
using DualSm90LinearCombination =
  Sm90EVT<Sm90Compute<homogeneous_multiply_add, ElementOutput, ElementCompute, RoundStyle>, // beta * C + (alpha * acc)
    Sm90ScalarBroadcast<ElementScalar, Stride<_0,_0,int64_t>>, // beta
    Sm90SrcFetch<ElementSource>, // C
    Sm90EVT<Sm90Compute<multiplies, ElementCompute, ElementCompute, RoundStyle>, // alpha * acc
      Sm90ScalarBroadcast<ElementScalar, Stride<_0,_0,int64_t>>, // alpha
      Sm90AccFetch // acc
    >
  >;

template <
  int StagesC,
  int StagesD,
  int FragmentSize,
  bool ReuseSmemC,
  bool DelayTmaStore,
  class ElementOutput,
  class ElementCompute,
  class ElementSource,
  class ElementScalar,
  FloatRoundStyle RoundStyle,
  class CtaTileShapeMNK,
  class EpilogueTile
>
struct DualFusionCallbacks<
    epilogue::DualSm90TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore>,
    fusion::DualLinearCombination<ElementOutput, ElementCompute, ElementSource, ElementScalar, RoundStyle>,
    CtaTileShapeMNK,
    EpilogueTile
> : DualSm90LinearCombination<typename cutlass::detail::get_unpacked_element_type<ElementOutput>::type, ElementCompute, ElementSource, ElementScalar, RoundStyle> {

  using Impl = DualSm90LinearCombination<typename cutlass::detail::get_unpacked_element_type<ElementOutput>::type, ElementCompute, ElementSource, ElementScalar, RoundStyle>;
  using Operation = fusion::DualLinearCombination<ElementOutput, ElementCompute, ElementSource, ElementScalar, RoundStyle>;

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

/////////////////////////////////////////////////////////////////////////////////////////////////

// DualOpPair specialization: allow distinct ops for accumulator0 and accumulator1
template <
  int StagesC,
  int StagesD,
  int FragmentSize,
  bool ReuseSmemC,
  bool DelayTmaStore,
  class Op0,
  class Op1,
  class CtaTileShapeMNK,
  class EpilogueTile
>
struct DualFusionCallbacks<
    epilogue::DualSm90TmaWarpSpecialized<StagesC,StagesD,FragmentSize,ReuseSmemC,DelayTmaStore>,
    DualOpPair<Op0,Op1>,
    CtaTileShapeMNK,
    EpilogueTile
> {

  using DispatchPolicy = epilogue::DualSm90TmaWarpSpecialized<StagesC,StagesD,FragmentSize,ReuseSmemC,DelayTmaStore>;
  using Operation      = DualOpPair<Op0,Op1>;

  using CB0 = DualFusionCallbacks<DispatchPolicy, Op0, CtaTileShapeMNK, EpilogueTile>;
  using CB1 = DualFusionCallbacks<DispatchPolicy, Op1, CtaTileShapeMNK, EpilogueTile>;

  struct Arguments {
    typename CB0::Arguments op0{};
    typename CB1::Arguments op1{};
  };

  struct Params {
    typename CB0::Params op0;
    typename CB1::Params op1;
  };

  struct SharedStorage {
    typename CB0::SharedStorage left;
    typename CB1::SharedStorage right;
  };

  template<class ProblemShape>
  static Params to_underlying_arguments(ProblemShape const& ps, Arguments const& a, void* ws) {
    return {
      CB0::to_underlying_arguments(ps, a.op0, ws),
      CB1::to_underlying_arguments(ps, a.op1, ws)
    };
  }

  template<class ProblemShape>
  static size_t get_workspace_size(ProblemShape const& ps, Arguments const& a) {
    return CB0::get_workspace_size(ps, a.op0) + CB1::get_workspace_size(ps, a.op1);
  }

  template<class ProblemShape>
  static cutlass::Status initialize_workspace(
      ProblemShape const& ps, Arguments const& a, void* ws, cudaStream_t stream,
      CudaHostAdapter* adapter = nullptr) {
    size_t size0 = CB0::get_workspace_size(ps, a.op0);
    void* ws1 = static_cast<uint8_t*>(ws) + size0;
    CUTLASS_CHECK(CB0::initialize_workspace(ps, a.op0, ws,  stream, adapter));
    CUTLASS_CHECK(CB1::initialize_workspace(ps, a.op1, ws1, stream, adapter));
    return cutlass::Status::kSuccess;
  }

  template<class ProblemShape>
  static bool can_implement(ProblemShape const& ps, Arguments const& a) {
    return CB0::can_implement(ps, a.op0) && CB1::can_implement(ps, a.op1);
  }

  CUTLASS_DEVICE
  DualFusionCallbacks(Params const& p, SharedStorage& st)
    : cb0_(p.op0, st.left), cb1_(p.op1, st.right) {}

  CUTLASS_DEVICE bool is_producer_load_needed() const {
    return cb0_.is_producer_load_needed() || cb1_.is_producer_load_needed();
  }

  CUTLASS_DEVICE bool is_C_load_needed() const {
    return detail_is_C_load_needed(cb0_) || detail_is_C_load_needed(cb1_);
  }
  
private:
  CB0 cb0_;
  CB1 cb1_;
  template<class T, class = void>
  struct has_is_C_load_needed : std::false_type {};

  template<class T>
  struct has_is_C_load_needed<T,
    cute::void_t<decltype(std::declval<T const&>().is_C_load_needed())>> : std::true_type {};

  template<class CbT>
  CUTLASS_DEVICE static bool detail_is_C_load_needed(CbT const& cb) {
    if constexpr (has_is_C_load_needed<CbT>::value) return cb.is_C_load_needed();
    else return false;
  }

  template<bool RefSrc, class Cb, class Args>
  CUTLASS_DEVICE static auto obtain_consumer_impl(int, Cb& cb, Args const& a)
    -> decltype(cb.template get_consumer_store_callbacks<RefSrc>(a)) {
    return cb.template get_consumer_store_callbacks<RefSrc>(a);
  }
  template<bool RefSrc, class Cb, class Args>
  CUTLASS_DEVICE static auto obtain_consumer_impl(long, Cb& cb, Args const& a)
    -> decltype(cb.get_consumer_store_callbacks(a)) {
    return cb.get_consumer_store_callbacks(a);
  }
  template<bool RefSrc, class Cb, class Args>
  CUTLASS_DEVICE static auto obtain_consumer(Cb& cb, Args const& a) {
    return obtain_consumer_impl<RefSrc>(0, cb, a);
  }

  // Wrapper structs
  template<class P0, class P1>
  struct ProducerPair {
    P0 a; P1 b;
    CUTLASS_DEVICE void begin(){ a.begin(); b.begin(); }
    CUTLASS_DEVICE void step(uint64_t* barrier,int em,int en,int stage,bool issue){
      a.step(barrier,em,en,stage,issue);
      b.step(barrier,em,en,stage,issue);
    }
    CUTLASS_DEVICE void end(){ a.end(); b.end(); }
  };

  template<class C0, class C1>
  struct ConsumerPair {
    C0 a; C1 b;

    // Trait helpers
    template<class T, class = void> struct has_begin_sync_needed : std::false_type {};
    template<class T> struct has_begin_sync_needed<T,
      cute::void_t<decltype(std::declval<T&>().begin_sync_needed())>> : std::true_type {};

    template<class T, class = void> struct has_tma_store : std::false_type {};
    template<class T> struct has_tma_store<T,
      cute::void_t<decltype(std::declval<T&>().tma_store(0,0,0,false))>> : std::true_type {};

    CUTLASS_DEVICE void begin(){ a.begin(); b.begin(); }

    CUTLASS_DEVICE bool begin_sync_needed(){
      bool r0=false,r1=false;
      if constexpr (has_begin_sync_needed<C0>::value) r0 = a.begin_sync_needed();
      if constexpr (has_begin_sync_needed<C1>::value) r1 = b.begin_sync_needed();
      return r0 || r1;
    }

    CUTLASS_DEVICE void begin_loop(int em,int en){ a.begin_loop(em,en); b.begin_loop(em,en); }

    CUTLASS_DEVICE void previsit(int em,int en,int stage,bool has_src){
      a.previsit(em,en,stage,has_src); b.previsit(em,en,stage,has_src);
    }

    template<class Frag>
    CUTLASS_DEVICE auto visit0(Frag const& f,int idx,int em,int en){
      return a.visit(f,idx,em,en);
    }
    template<class Frag>
    CUTLASS_DEVICE auto visit1(Frag const& f,int idx,int em,int en){
      return b.visit(f,idx,em,en);
    }
    template<class Frag>
    CUTLASS_DEVICE auto visit(Frag const& f,int idx,int em,int en){
      return a.visit(f,idx,em,en);
    }

    template<class SmemTensor,class SyncFn,class FragTensor>
    CUTLASS_DEVICE void reduce(SmemTensor&& t, SyncFn&& sync,int em,int en,bool last, FragTensor& fr){
      a.reduce(t,sync,em,en,last,fr);
      b.reduce(t,sync,em,en,last,fr);
    }

    CUTLASS_DEVICE void postreduce(int em,int en,int stage,bool issue){
      a.postreduce(em,en,stage,issue);
      b.postreduce(em,en,stage,issue);
    }

    CUTLASS_DEVICE void tma_store(int em,int en,int stage,bool issue){
      if constexpr (has_tma_store<C0>::value) a.tma_store(em,en,stage,issue);
      if constexpr (has_tma_store<C1>::value) b.tma_store(em,en,stage,issue);
    }

    CUTLASS_DEVICE void end_loop(int em,int en){ a.end_loop(em,en); b.end_loop(em,en); }
    CUTLASS_DEVICE void end(){ a.end(); b.end(); }
  };

public:
  template<class ProducerLoadArgs>
  CUTLASS_DEVICE auto get_producer_load_callbacks(ProducerLoadArgs const& args) {
    auto p0 = cb0_.get_producer_load_callbacks(args);
    auto p1 = cb1_.get_producer_load_callbacks(args);
    return ProducerPair<decltype(p0),decltype(p1)>{p0,p1};
  }

  template<bool RefSrc, class ConsumerStoreArgs>
  CUTLASS_DEVICE auto get_consumer_store_callbacks(ConsumerStoreArgs const& args) {
    auto c0 = obtain_consumer<RefSrc>(cb0_, args);
    auto c1 = obtain_consumer<RefSrc>(cb1_, args);
    return ConsumerPair<decltype(c0),decltype(c1)>{c0,c1};
  }

};

namespace detail {
template <class DualFusionOpOrCallbacks, class = cute::void_t<>>
struct dual_get_element_aux {
  using type = void;
};

template <class DualFusionOpOrCallbacks>
struct dual_get_element_aux<DualFusionOpOrCallbacks, cute::void_t<typename DualFusionOpOrCallbacks::ElementAux>> {
  using type = typename DualFusionOpOrCallbacks::ElementAux;
};

template <class NodeOp, class... ChildOps>
struct dual_get_element_aux<Sm90TreeVisitor<NodeOp, ChildOps...>, cute::void_t<>> {
  using type = typename dual_get_element_aux<NodeOp>::type;
};

template <class... Ts>
struct dual_get_element_aux<DualFusionCallbacks<Ts...>, cute::void_t<typename DualFusionCallbacks<Ts...>::Operation>> {
 private:
  using Operation = typename DualFusionCallbacks<Ts...>::Operation;
 public:
  using type = typename dual_get_element_aux<Operation>::type;
};

template<class Op0, class Op1>
struct dual_get_element_aux<DualOpPair<Op0,Op1>, cute::void_t<>> {
  using type = typename dual_get_element_aux<Op0>::type;
};
} // namespace cutlass:epilogue::fusion::detail

template <class Callbacks>
using dual_get_element_aux_t = typename detail::dual_get_element_aux<Callbacks>::type;

} // namespace cutlass::epilogue::fusion

/////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////////////////////////
