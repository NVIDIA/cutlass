/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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


#pragma once

#if !defined(__CUDACC_RTC__)
#include <cuda.h>
#include <cassert>
#endif

#include <cute/tensor.hpp>
#include <cute/tensor_zip.hpp>
#include <cute/atom/copy_traits_sm90_tma.hpp>   // SM90_TMA_LOAD{,_MULTICAST}, TMA_LOAD_Unpack, detail::make_tma_copy_atom
#include <cute/atom/copy_traits_sm100_tma.hpp>  // SM100_* ops, make_tma_atom_{A,B}_sm100 (reroute target)
#include <cute/arch/copy_sm107_tma.hpp>         // SM107_TMA_LOAD<T>, etc.
#include <cute/arch/cluster_sm90.hpp>           // elect_one_sync
#include <cute/atom/copy_traits.hpp>
#include <cute/container/array.hpp>

namespace cute
{

// SM107 reuses the SM90 TMA descriptor construction and make_tma_copy machinery verbatim.
// The only change in SM107 is the mbarrier report mechanism (bulk copy and bulk tensor copy only).
// Report mechanism qualifier must be chosen based on element bit width, which we set in
// make_tma_atom_{A,B}_sm107, and only when triggered with reporting enabled (ReportValid == 1).
// The transition from the SM90 load op to SM107 with report qualifier is done during executable
// load construction ("with").

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// TMA_LOAD ///////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

template <class T>
struct SM107_TMA_LOAD_OP : SM107_TMA_LOAD<T> {};

// The non-executable SM107_TMA_LOAD with tma_desc and no tma_mbar
// Use .with(tma_mbar) to construct an executable version
template <class T, class NumBitsPerTMA, class AuxParams_>
struct Copy_Traits<SM107_TMA_LOAD<T>, NumBitsPerTMA, AuxParams_>
{
  using ThrID     = Layout<_1>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM107_TMA_LOAD arguments
  TmaDescriptor tma_desc_;
  using AuxParams = AuxParams_;
  AuxParams aux_params_;

  // Return TmaDescriptor/TensorMap
  CUTE_HOST_DEVICE constexpr
  TmaDescriptor const*
  get_tma_descriptor() const {
    return &tma_desc_;
  }

  // Construct an executable SM107_TMA_LOAD with tma_mbar
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM107_TMA_LOAD_OP<T>, NumBitsPerTMA>
  with(
    uint64_t& tma_mbar,
    [[maybe_unused]] uint16_t const& multicast_mask = 0,
    TMA::CacheHintSm90 const& cache_hint = TMA::CacheHintSm90::EVICT_NORMAL) const {
    // We accept multicast_mask here to keep the API for both atoms consistent
    return {&tma_desc_, &tma_mbar, static_cast<uint64_t>(cache_hint)};
  }

  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM107_TMA_LOAD_OP<T>, NumBitsPerTMA>
  with(
    TmaDescriptor const* new_tma_desc,
    uint64_t& tma_mbar,
    [[maybe_unused]] uint16_t const& multicast_mask = 0,
    TMA::CacheHintSm90 const& cache_hint = TMA::CacheHintSm90::EVICT_NORMAL) const {
    // We accept multicast_mask here to keep the API for both atoms consistent
    return {new_tma_desc, &tma_mbar, static_cast<uint64_t>(cache_hint)};
  }

  // Generate the TMA coord tensor
  template <class GShape>
  CUTE_HOST_DEVICE constexpr
  auto
  get_tma_tensor(GShape const& g_shape) const {
    static_assert(is_congruent<decltype(g_shape), decltype(aux_params_.g_stride_)>::value);
    return make_coord_tensor(make_layout(g_shape, aux_params_.g_stride_));
  }

  // Don't try to execute a copy with SM107_TMA_LOAD before calling .with()
  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr void
  copy_unpack(Copy_Traits        const& traits,
              Tensor<TS,SLayout> const& src,
              Tensor<TD,DLayout>      & dst) = delete;

  // Construct with updated TMA descriptor only (no barrier change)
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM107_TMA_LOAD<T>, NumBitsPerTMA, AuxParams_>
  with(TmaDescriptor const* new_tma_desc) const {
    return {*new_tma_desc, aux_params_};
  }
};

// The executable SM107_TMA_LOAD with tma_desc and tma_mbar
template <class T, class NumBitsPerTMA>
struct Copy_Traits<SM107_TMA_LOAD_OP<T>, NumBitsPerTMA>
  : TMA_LOAD_Unpack<SM107_TMA_LOAD_OP<T>, NumBitsPerTMA>
{
  using ThrID     = Layout<_1>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM107_TMA_LOAD arguments
  tuple<
  TmaDescriptor const*,
  uint64_t*, // smem mbarrier
  uint64_t   // cache hint
  > const opargs_;

  CUTE_HOST_DEVICE
  Copy_Traits(TmaDescriptor const* desc, uint64_t* mbar, uint64_t cache)
    : opargs_(desc, mbar, cache) {}

  // Return TmaDescriptor/TensorMap
  CUTE_HOST_DEVICE constexpr
  TmaDescriptor const*
  get_tma_descriptor() const {
    return get<0>(opargs_);
  }
};

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// TMA_LOAD_MULTICAST /////////////////////////////
//////////////////////////////////////////////////////////////////////////////

template <class T>
struct SM107_TMA_LOAD_MULTICAST_OP : SM107_TMA_LOAD_MULTICAST<T> {};

// The non-executable SM107_TMA_LOAD_MULTICAST with tma_desc and no tma_mbar
// Use .with(tma_mbar, multicast_mask) to construct an executable version
template <class T, class NumBitsPerTMA, class AuxParams_>
struct Copy_Traits<SM107_TMA_LOAD_MULTICAST<T>, NumBitsPerTMA, AuxParams_>
{
  using ThrID     = Layout<_1>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM107_TMA_LOAD_MULTICAST arguments
  TmaDescriptor tma_desc_;
  using AuxParams = AuxParams_;
  AuxParams aux_params_;

  // Return TmaDescriptor/TensorMap
  CUTE_HOST_DEVICE constexpr
  TmaDescriptor const*
  get_tma_descriptor() const {
    return &tma_desc_;
  }

  // Construct an executable SM107_TMA_LOAD_MULTICAST with tma_mbar
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM107_TMA_LOAD_MULTICAST_OP<T>, NumBitsPerTMA>
  with(
    uint64_t& tma_load_mbar,
    uint16_t const& multicast_mask,
    TMA::CacheHintSm90 const& cache_hint = TMA::CacheHintSm90::EVICT_NORMAL) const {
    return {&tma_desc_, &tma_load_mbar, multicast_mask, static_cast<uint64_t>(cache_hint)};
  }

  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM107_TMA_LOAD_MULTICAST_OP<T>, NumBitsPerTMA>
  with(
    TmaDescriptor const* new_tma_desc,
    uint64_t& tma_load_mbar,
    uint16_t const& multicast_mask,
    TMA::CacheHintSm90 const& cache_hint = TMA::CacheHintSm90::EVICT_NORMAL) const {
    return {new_tma_desc, &tma_load_mbar, multicast_mask, static_cast<uint64_t>(cache_hint)};
  }

  // Generate the TMA coord tensor
  template <class GShape>
  CUTE_HOST_DEVICE constexpr
  auto
  get_tma_tensor(GShape const& g_shape) const {
    static_assert(is_congruent<decltype(g_shape), decltype(aux_params_.g_stride_)>::value);
    return make_coord_tensor(make_layout(g_shape, aux_params_.g_stride_));
  }

  // Don't try to execute a copy with SM107_TMA_LOAD_MULTICAST before calling .with()
  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr void
  copy_unpack(Copy_Traits        const& traits,
              Tensor<TS,SLayout> const& src,
              Tensor<TD,DLayout>      & dst) = delete;
};

// The executable SM107_TMA_LOAD_MULTICAST with tma_desc and tma_mbar and multicast_mask
template <class T, class NumBitsPerTMA>
struct Copy_Traits<SM107_TMA_LOAD_MULTICAST_OP<T>, NumBitsPerTMA>
  : TMA_LOAD_Unpack<SM107_TMA_LOAD_MULTICAST_OP<T>, NumBitsPerTMA>
{
  using ThrID     = Layout<_1>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM107_TMA_LOAD_MULTICAST arguments
  tuple<
  TmaDescriptor const*,
  uint64_t*, // smem mbarrier
  uint16_t,  // multicast mask
  uint64_t   // cache hint
  > const opargs_;

  CUTE_HOST_DEVICE
  Copy_Traits(TmaDescriptor const* desc, uint64_t* mbar, uint16_t mask, uint64_t hint)
    : opargs_(desc, mbar, mask, hint) {}

  // Return TmaDescriptor/TensorMap
  CUTE_HOST_DEVICE constexpr
  TmaDescriptor const*
  get_tma_descriptor() const {
    return get<0>(opargs_);
  }
};

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// TMA_2SM_LOAD ///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

template <class T>
struct SM107_TMA_2SM_LOAD_OP : SM107_TMA_2SM_LOAD<T> {};

// The non-executable SM107_TMA_2SM_LOAD with tma_desc and no tma_mbar
// Use .with(tma_mbar) to construct an executable version
template <class T, class NumBitsPerTMA, class AuxParams_>
struct Copy_Traits<SM107_TMA_2SM_LOAD<T>, NumBitsPerTMA, AuxParams_>
{
  using ThrID     = Layout<_2>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_2,NumBitsPerTMA>, Stride<NumBitsPerTMA,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_2,NumBitsPerTMA>, Stride<NumBitsPerTMA,_1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM107_TMA_2SM_LOAD arguments
  TmaDescriptor tma_desc_;
  using AuxParams = AuxParams_;
  AuxParams aux_params_;

  // Return TmaDescriptor/TensorMap
  CUTE_HOST_DEVICE constexpr
  TmaDescriptor const*
  get_tma_descriptor() const {
    return &tma_desc_;
  }

  // Construct an executable SM107_TMA_2SM_LOAD with tma_mbar
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM107_TMA_2SM_LOAD_OP<T>, NumBitsPerTMA>
  with(
    uint64_t& tma_mbar,
    [[maybe_unused]] uint16_t const& multicast_mask = 0,
    TMA::CacheHintSm100 const& cache_hint = TMA::CacheHintSm100::EVICT_NORMAL) const {
    // We accept multicast_mask here to keep the API for both atoms consistent
    return {&tma_desc_, &tma_mbar, static_cast<uint64_t>(cache_hint)};
  }

  // Construct an executable SM107_TMA_2SM_LOAD with tma_mbar (temp. overloaded for grouped gemm/ptr array gemm)
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM107_TMA_2SM_LOAD_OP<T>, NumBitsPerTMA>
  with(
    TmaDescriptor const* new_tma_desc,
    uint64_t& tma_mbar,
    [[maybe_unused]] uint16_t const& multicast_mask = 0,
    TMA::CacheHintSm100 const& cache_hint = TMA::CacheHintSm100::EVICT_NORMAL) const {
    // We accept multicast_mask here to keep the API for both atoms consistent
    return {new_tma_desc, &tma_mbar, static_cast<uint64_t>(cache_hint)};
  }

  // Generate the TMA coord tensor
  template <class GShape>
  CUTE_HOST_DEVICE constexpr
  auto
  get_tma_tensor(GShape const& g_shape) const {
    static_assert(is_congruent<decltype(g_shape), decltype(aux_params_.g_stride_)>::value);
    return make_coord_tensor(make_layout(g_shape, aux_params_.g_stride_));
  }

  // Don't try to execute a copy with SM107_TMA_2SM_LOAD before calling .with()
  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr void
  copy_unpack(Copy_Traits        const& traits,
              Tensor<TS,SLayout> const& src,
              Tensor<TD,DLayout>      & dst) = delete;

  // Construct with updated TMA descriptor only (no barrier change)
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM107_TMA_2SM_LOAD<T>, NumBitsPerTMA, AuxParams_>
  with(TmaDescriptor const* new_tma_desc) const {
    return {*new_tma_desc, aux_params_};
  }
};

// The executable SM107_TMA_2SM_LOAD with tma_desc and tma_mbar
template <class T, class NumBitsPerTMA>
struct Copy_Traits<SM107_TMA_2SM_LOAD_OP<T>, NumBitsPerTMA>
  : TMA_LOAD_Unpack<SM107_TMA_2SM_LOAD_OP<T>, NumBitsPerTMA>
{
  using ThrID     = Layout<_2>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_2,NumBitsPerTMA>, Stride<NumBitsPerTMA,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_2,NumBitsPerTMA>, Stride<NumBitsPerTMA,_1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM107_TMA_2SM_LOAD arguments
  tuple<
  TmaDescriptor const*,
  uint64_t*, // smem mbarrier
  uint64_t   // cache hint
  > const opargs_;

  CUTE_HOST_DEVICE
  Copy_Traits(TmaDescriptor const* desc, uint64_t* mbar, uint64_t cache)
    : opargs_(desc, mbar, cache) {}

  // Return TmaDescriptor/TensorMap
  CUTE_HOST_DEVICE constexpr
  TmaDescriptor const*
  get_tma_descriptor() const {
    return get<0>(opargs_);
  }
};

//////////////////////////////////////////////////////////////////////////////
///////////////////////// TMA_2SM_LOAD_MULTICAST /////////////////////////////
//////////////////////////////////////////////////////////////////////////////

template <class T>
struct SM107_TMA_2SM_LOAD_MULTICAST_OP : SM107_TMA_2SM_LOAD_MULTICAST<T> {};

// The non-executable SM107_TMA_2SM_LOAD_MULTICAST with tma_desc and no tma_mbar
// Use .with(tma_mbar, multicast_mask) to construct an executable version
template <class T, class NumBitsPerTMA, class AuxParams_>
struct Copy_Traits<SM107_TMA_2SM_LOAD_MULTICAST<T>, NumBitsPerTMA, AuxParams_>
{
  using ThrID     = Layout<_2>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_2,NumBitsPerTMA>, Stride<NumBitsPerTMA,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_2,NumBitsPerTMA>, Stride<NumBitsPerTMA,_1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM107_TMA_2SM_LOAD_MULTICAST arguments
  TmaDescriptor tma_desc_;
  using AuxParams = AuxParams_;
  AuxParams aux_params_;

  // Return TmaDescriptor/TensorMap
  CUTE_HOST_DEVICE constexpr
  TmaDescriptor const*
  get_tma_descriptor() const {
    return &tma_desc_;
  }

  // Construct an executable SM107_TMA_2SM_LOAD_MULTICAST with tma_mbar
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM107_TMA_2SM_LOAD_MULTICAST_OP<T>, NumBitsPerTMA>
  with(
    uint64_t& tma_load_mbar,
    uint16_t const& multicast_mask,
    TMA::CacheHintSm100 const& cache_hint = TMA::CacheHintSm100::EVICT_NORMAL) const {
    return {&tma_desc_, &tma_load_mbar, multicast_mask, static_cast<uint64_t>(cache_hint)};
  }

  // Construct an executable SM107_TMA_2SM_LOAD_MULTICAST_OP with tma_mbar (temp. overloaded for grouped gemm/ptr array gemm)
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM107_TMA_2SM_LOAD_MULTICAST_OP<T>, NumBitsPerTMA>
  with(
    TmaDescriptor const* new_tma_desc,
    uint64_t& tma_load_mbar,
    uint16_t const& multicast_mask,
    TMA::CacheHintSm100 const& cache_hint = TMA::CacheHintSm100::EVICT_NORMAL) const {
    return {new_tma_desc, &tma_load_mbar, multicast_mask, static_cast<uint64_t>(cache_hint)};
  }

  // Generate the TMA coord tensor
  template <class GShape>
  CUTE_HOST_DEVICE constexpr
  auto
  get_tma_tensor(GShape const& g_shape) const {
    static_assert(is_congruent<decltype(g_shape), decltype(aux_params_.g_stride_)>::value);
    return make_coord_tensor(make_layout(g_shape, aux_params_.g_stride_));
  }

  // Don't try to execute a copy with SM107_TMA_2SM_LOAD_MULTICAST before calling .with()
  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr void
  copy_unpack(Copy_Traits        const& traits,
              Tensor<TS,SLayout> const& src,
              Tensor<TD,DLayout>      & dst) = delete;
};

// The executable SM107_TMA_2SM_LOAD_MULTICAST with tma_desc and tma_mbar and multicast_mask
template <class T, class NumBitsPerTMA>
struct Copy_Traits<SM107_TMA_2SM_LOAD_MULTICAST_OP<T>, NumBitsPerTMA>
  : TMA_LOAD_Unpack<SM107_TMA_2SM_LOAD_MULTICAST_OP<T>, NumBitsPerTMA>
{
  using ThrID     = Layout<_2>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_2,NumBitsPerTMA>, Stride<NumBitsPerTMA,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_2,NumBitsPerTMA>, Stride<NumBitsPerTMA,_1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM107_TMA_2SM_LOAD_MULTICAST arguments
  tuple<
  TmaDescriptor const*,
  uint64_t*, // smem mbarrier
  uint16_t,  // multicast mask
  uint64_t   // cache hint
  > const opargs_;

  CUTE_HOST_DEVICE
  Copy_Traits(TmaDescriptor const* desc, uint64_t* mbar, uint16_t mask, uint64_t hint)
    : opargs_(desc, mbar, mask, hint) {}

  // Return TmaDescriptor/TensorMap
  CUTE_HOST_DEVICE constexpr
  TmaDescriptor const*
  get_tma_descriptor() const {
    return get<0>(opargs_);
  }
};

////////////////////////////////////
// Make TMA
///////////////////////////////////

#if !defined(__CUDACC_RTC__)
/** Duplicates of make_tma_atom_{A,B}_sm100 that create TMA load executables with validity reporting
 */

namespace detail {

template <class CopyOp>
constexpr bool copy_op_supports_validity_reporting =
       is_same_v<CopyOp, SM90_TMA_LOAD>
    || is_same_v<CopyOp, SM90_TMA_LOAD_MULTICAST>
    || is_same_v<CopyOp, SM100_TMA_2SM_LOAD>
    || is_same_v<CopyOp, SM100_TMA_2SM_LOAD_MULTICAST>;

template <class CopyOp, class T>
struct copy_op_to_copy_op_with_validity_reporting {
  static_assert(dependent_false<CopyOp>, "No SM107 counterpart for this TMA CopyOp.");
};

template <class T>
struct copy_op_to_copy_op_with_validity_reporting<SM90_TMA_LOAD, T> {
  using type = SM107_TMA_LOAD<T>;
};

template <class T>
struct copy_op_to_copy_op_with_validity_reporting<SM90_TMA_LOAD_MULTICAST, T> {
  using type = SM107_TMA_LOAD_MULTICAST<T>;
};

template <class T>
struct copy_op_to_copy_op_with_validity_reporting<SM100_TMA_2SM_LOAD, T> {
  using type = SM107_TMA_2SM_LOAD<T>;
};

template <class T>
struct copy_op_to_copy_op_with_validity_reporting<SM100_TMA_2SM_LOAD_MULTICAST, T> {
  using type = SM107_TMA_2SM_LOAD_MULTICAST<T>;
};

template <class CopyOp, class T>
using copy_op_to_copy_op_with_validity_reporting_t = typename copy_op_to_copy_op_with_validity_reporting<CopyOp, T>::type;

} // end namespace detail


////////////////////////////////////
// Experimental Make TMA Atom
///////////////////////////////////

template <bool ReportValid = false,
          class TmaInternalType = void,
          class CopyOp,
          class GEngine, class GLayout,
          class SLayout,
          class MMA_Tiler,
          class... Args,
          class ClusterShapeVMNK,
          __CUTE_REQUIRES(detail::copy_op_supports_validity_reporting<CopyOp>)>
CUTE_HOST
auto
make_tma_atom_A_sm107(CopyOp                  const& copy_op,
                      Tensor<GEngine,GLayout> const& gtensor,        // (M, K, ...)
                      SLayout                 const& slayout,        // (MMA, MMA_M, MMA_K, ...)
                      MMA_Tiler               const& mma_tiler,      // (TILE_M, TILE_N, TILE_K, ...)
                      TiledMMA<Args...>       const& mma,
                      ClusterShapeVMNK        const& cluster_shape)  // (CTA_V, CTA_M, CTA_N, CTA_K)
{
  // Keep only MK modes from MNK
  auto mma_tiler_mk = remove<1>(mma_tiler);

  // cluster tile coord -> gtensor coord
  auto g_tile = make_identity_layout(shape(gtensor)).compose(mma_tiler_mk);         // (TILE_M, TILE_K, ...)

  // cta val idx -> gmem mode
  auto cta_v_tile = layout<1>(mma.thrfrg_A(g_tile))(_, repeat<rank(g_tile)>(_));    // (MMA, MMA_M, MMA_K, ...)

  // The size of the multicasting
  auto num_multicast = [&](){
    if constexpr (is_same_v<CopyOp, SM90_TMA_LOAD_MULTICAST>
                  || is_same_v<CopyOp, SM100_TMA_2SM_LOAD_MULTICAST>
                 ) {
      return size<2>(cluster_shape);                   // VMNK: Use only the N-CTAs in the Multicast
    } else
    if constexpr (is_same_v<CopyOp, SM90_TMA_LOAD>
                  || is_same_v<CopyOp, SM100_TMA_2SM_LOAD>
                  ) {
      return Int<1>{};                                 // VMNK: Use no CTAs in Non-Multicast
    } else {
      static_assert(dependent_false<CopyOp>, "Unsupported TMA");
    }
  }();

  // Prefer TmaInternalType if specified. Fallback to GEngine::value_type
  using TmaType = conditional_t<is_same<void, TmaInternalType>::value, typename GEngine::value_type, TmaInternalType>;

  // Select the validity-reporting element type for the SM107 op tag (void disables reporting).
  using ValidT = conditional_t<ReportValid, TmaType, void>;
  using CopyOp_Sm107 = detail::copy_op_to_copy_op_with_validity_reporting_t<CopyOp, ValidT>;

  return detail::make_tma_copy_atom<TmaType>(CopyOp_Sm107{}, gtensor, slayout, num_multicast, cta_v_tile);
}

template <bool ReportValid = false,
          class TmaInternalType = void,
          class CopyOp,
          class GEngine, class GLayout,
          class SLayout,
          class MMA_Tiler,
          class... Args,
          class ClusterShapeVMNK,
          __CUTE_REQUIRES(detail::copy_op_supports_validity_reporting<CopyOp>)>
CUTE_HOST
auto
make_tma_atom_B_sm107(CopyOp                  const& copy_op,
                      Tensor<GEngine,GLayout> const& gtensor,        // (N, K, ...)
                      SLayout                 const& slayout,        // (MMA, MMA_N, MMA_K, ...)
                      MMA_Tiler               const& mma_tiler,      // (TILE_M, TILE_N, TILE_K, ...)
                      TiledMMA<Args...>       const& mma,
                      ClusterShapeVMNK        const& cluster_shape)  // (CTA_V, CTA_M, CTA_N, CTA_K)
{
  // Keep only NK modes from MNK
  auto mma_tiler_nk = remove<0>(mma_tiler);
  // cluster tile coord -> gtensor coord
  auto g_tile = make_identity_layout(shape(gtensor)).compose(mma_tiler_nk);         // (TILE_N, TILE_K, ...)
  // cta val idx -> gmem mode
  auto cta_v_tile = layout<1>(mma.thrfrg_B(g_tile))(_, repeat<rank(g_tile)>(_));    // (MMA, MMA_N, MMA_K, ...)

  // The size of the multicasting
  auto num_multicast = [&](){
    if constexpr (is_same_v<CopyOp, SM90_TMA_LOAD_MULTICAST>
                  || is_same_v<CopyOp, SM100_TMA_2SM_LOAD_MULTICAST>
                 ) {
      return size<1>(cluster_shape);                   // VMNK: Use only the M-CTAs in the Multicast
    } else
    if constexpr (is_same_v<CopyOp, SM90_TMA_LOAD>
                  || is_same_v<CopyOp, SM100_TMA_2SM_LOAD>
                  ) {
      return Int<1>{};                                 // VMNK: Use no CTAs in Non-Multicast
    } else {
      static_assert(dependent_false<CopyOp>, "Unsupported TMA");
    }
  }();

  // Prefer TmaInternalType if specified. Fallback to GEngine::value_type
  using TmaType = conditional_t<is_same<void, TmaInternalType>::value, typename GEngine::value_type, TmaInternalType>;

  // Select the validity-reporting element type for the SM107 op tag (void disables reporting).
  using ValidT = conditional_t<ReportValid, TmaType, void>;
  using CopyOp_Sm107 = detail::copy_op_to_copy_op_with_validity_reporting_t<CopyOp, ValidT>;

  return detail::make_tma_copy_atom<TmaType>(CopyOp_Sm107{}, gtensor, slayout, num_multicast, cta_v_tile);
}

// Mbarrier reporting disabled / inapplicable
template <bool ReportValid = false,
          class TmaInternalType = void,
          class CopyOp,
          class GEngine, class GLayout,
          class SLayout,
          class MMA_Tiler,
          class... Args,
          class ClusterShapeVMNK,
          __CUTE_REQUIRES(not detail::copy_op_supports_validity_reporting<CopyOp>)>
CUTE_HOST
auto
make_tma_atom_A_sm107(CopyOp                  const& copy_op,
                      Tensor<GEngine,GLayout> const& gtensor,
                      SLayout                 const& slayout,
                      MMA_Tiler               const& mma_tiler,
                      TiledMMA<Args...>       const& mma,
                      ClusterShapeVMNK        const& cluster_shape)
{
  static_assert(not ReportValid, "SM107 mbarrier validity reporting is not supported for this CopyOp / Copy_Traits.");
  return make_tma_atom_A_sm100<TmaInternalType>(copy_op, gtensor, slayout, mma_tiler, mma, cluster_shape);
}

template <bool ReportValid = false,
          class TmaInternalType = void,
          class CopyOp,
          class GEngine, class GLayout,
          class SLayout,
          class MMA_Tiler,
          class... Args,
          class ClusterShapeVMNK,
          __CUTE_REQUIRES(not detail::copy_op_supports_validity_reporting<CopyOp>)>
CUTE_HOST
auto
make_tma_atom_B_sm107(CopyOp                  const& copy_op,
                      Tensor<GEngine,GLayout> const& gtensor,
                      SLayout                 const& slayout,
                      MMA_Tiler               const& mma_tiler,
                      TiledMMA<Args...>       const& mma,
                      ClusterShapeVMNK        const& cluster_shape)
{
  static_assert(not ReportValid, "SM107 mbarrier validity reporting is not supported for this CopyOp / Copy_Traits.");
  return make_tma_atom_B_sm100<TmaInternalType>(copy_op, gtensor, slayout, mma_tiler, mma, cluster_shape);
}

#endif // !defined(__CUDACC_RTC__)


} // end namespace cute
