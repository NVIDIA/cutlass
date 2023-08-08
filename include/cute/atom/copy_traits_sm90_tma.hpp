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
#pragma once

#if !defined(__CUDACC_RTC__)
#include <cuda.h>
#endif

#include <cute/atom/copy_traits_sm90_tma_swizzle.hpp>
#include <cute/atom/copy_traits.hpp>
#include <cute/atom/copy_atom.hpp>

namespace cute
{

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// TMA_LOAD ///////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

struct SM90_TMA_LOAD_OP : SM90_TMA_LOAD {};

// The executable SM90_TMA_LOAD with tma_desc and tma_mbar
template <class NumBitsPerTMA>
struct Copy_Traits<SM90_TMA_LOAD_OP, NumBitsPerTMA>
{
  using ThrID   = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBitsPerTMA>>;

  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM90_TMA_LOAD arguments
  TmaDescriptor const& tma_desc_;
  uint64_t& tma_load_mbar_;

  template <class Coord, int... Is>
  CUTE_HOST_DEVICE constexpr
  void
  copy_unpack_(void const* const dst_ptr,
               Coord const& src_coord, seq<Is...>) const
  {
    SM90_TMA_LOAD::copy(&tma_desc_, tma_load_mbar_,
                        dst_ptr, get<Is>(src_coord)...);
  }

  // This is the copy_unpack dispatch for this Copy_Traits
  // Src needs to be a gmem tensor with TmaCoordIterator .data()
  // Dst needs to be a smem tensor
  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr
  void
  copy_unpack(Copy_Traits        const& traits,
              Tensor<TS,SLayout> const& src,
              Tensor<TD,DLayout>      & dst)
  {
    static_assert(is_smem<TD>::value, "Expected smem dst for SM90_TMA_LOAD");

    traits.copy_unpack_(raw_pointer_cast(dst.data()), src.data().coord_, tuple_seq<decltype(src.data().coord_)>{});
  }
};

// The non-executable SM90_TMA_LOAD with tma_desc and no tma_mbar
// Use .with(tma_mbar) to construct an executable version
template <class NumBitsPerTMA, class GmemStrides>
struct Copy_Traits<SM90_TMA_LOAD, NumBitsPerTMA, GmemStrides>
{
  using ThrID   = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBitsPerTMA>>;

  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM90_TMA_LOAD arguments
  TmaDescriptor tma_desc_;
  GmemStrides g_stride_;

  // Return TmaDescriptor/TensorMap
  CUTE_HOST_DEVICE constexpr
  TmaDescriptor const*
  get_tma_descriptor() const {
    return &tma_desc_;
  }

  // Construct an executable SM90_TMA_LOAD with tma_mbar
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM90_TMA_LOAD_OP, NumBitsPerTMA>
  with(uint64_t& tma_mbar, uint16_t const& multicast_mask = 0) const {
    // We accept multicast_mask here to keep the API for both atoms consistent
    // assert(multicast_mask == 0);
    (void) multicast_mask;
    return {tma_desc_, tma_mbar};
  }

  // Generate the TMA coord tensor
  template <class GShape>
  CUTE_HOST_DEVICE constexpr
  auto
  get_tma_tensor(GShape const& g_shape) const {
    static_assert(is_congruent<decltype(g_shape), decltype(g_stride_)>::value);
    return make_counting_tensor(make_layout(g_shape, g_stride_));
  }

  // Don't try to execute a copy with SM90_TMA_LOAD before calling .with()
  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr void
  copy_unpack(Copy_Traits        const& traits,
              Tensor<TS,SLayout> const& src,
              Tensor<TD,DLayout>      & dst) = delete;
};

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// TMA_LOAD_MULTICAST /////////////////////////////
//////////////////////////////////////////////////////////////////////////////

struct SM90_TMA_LOAD_MULTICAST_OP : SM90_TMA_LOAD_MULTICAST {};

template <class NumBitsPerTMA>
struct Copy_Traits<SM90_TMA_LOAD_MULTICAST_OP, NumBitsPerTMA>
{
  using ThrID   = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBitsPerTMA>>;

  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM90_TMA_LOAD_MULTICAST arguments
  TmaDescriptor const& tma_desc_;
  uint64_t& tma_load_mbar_;
  uint16_t const& multicast_mask_;

  template <class Coord, int... Is>
  CUTE_HOST_DEVICE constexpr
  void
  copy_unpack_(void const* const dst_ptr,
               Coord const& src_coord, seq<Is...>) const
  {
    SM90_TMA_LOAD_MULTICAST::copy(&tma_desc_, tma_load_mbar_, multicast_mask_,
                                  dst_ptr, get<Is>(src_coord)...);
  }

  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr
  void
  copy_unpack(Copy_Traits        const& traits,
              Tensor<TS,SLayout> const& src,
              Tensor<TD,DLayout>      & dst)
  {
    static_assert(is_smem<TD>::value, "Expected smem dst for SM90_TMA_LOAD_MULTICAST");

    traits.copy_unpack_(raw_pointer_cast(dst.data()), src.data().coord_, tuple_seq<decltype(src.data().coord_)>{});
  }
};

template <class NumBitsPerTMA, class GmemStrides>
struct Copy_Traits<SM90_TMA_LOAD_MULTICAST, NumBitsPerTMA, GmemStrides>
{
  using ThrID   = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBitsPerTMA>>;

  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM90_TMA_LOAD_MULTICAST arguments
  TmaDescriptor tma_desc_;
  GmemStrides g_stride_;

  // Return TmaDescriptor/TensorMap
  CUTE_HOST_DEVICE constexpr
  TmaDescriptor const*
  get_tma_descriptor() const {
    return &tma_desc_;
  }

  // Construct an executable SM90_TMA_LOAD_MULTICAST with tma_mbar
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM90_TMA_LOAD_MULTICAST_OP, NumBitsPerTMA>
  with(uint64_t& tma_load_mbar, uint16_t const& multicast_mask) const {
    return {tma_desc_, tma_load_mbar, multicast_mask};
  }

  // Generate the TMA coord tensor
  template <class GShape>
  CUTE_HOST_DEVICE constexpr
  auto
  get_tma_tensor(GShape const& g_shape) const {
    static_assert(is_congruent<decltype(g_shape), decltype(g_stride_)>::value);
    return make_counting_tensor(make_layout(g_shape, g_stride_));
  }

  // Don't try to execute a copy with SM90_TMA_LOAD_MULTICAST before calling .with()
  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr void
  copy_unpack(Copy_Traits        const& traits,
              Tensor<TS,SLayout> const& src,
              Tensor<TD,DLayout>      & dst) = delete;
};

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// TMA_STORE //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

// The executable SM90_TMA_STORE with tma_desc
template <class NumBitsPerTMA, class GmemStrides>
struct Copy_Traits<SM90_TMA_STORE, NumBitsPerTMA, GmemStrides>
{
  using ThrID   = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBitsPerTMA>>;

  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM90_TMA_STORE arguments
  TmaDescriptor tma_desc_;
  GmemStrides g_stride_;

  // Return TmaDescriptor/TensorMap
  CUTE_HOST_DEVICE constexpr
  TmaDescriptor const*
  get_tma_descriptor() const {
    return &tma_desc_;
  }

  // Generate the TMA coord tensor
  template <class GShape>
  CUTE_HOST_DEVICE constexpr
  auto
  get_tma_tensor(GShape const& g_shape) const {
    static_assert(is_congruent<decltype(g_shape), decltype(g_stride_)>::value);
    return make_counting_tensor(make_layout(g_shape, g_stride_));
  }

  template <class Coord, int... Is>
  CUTE_HOST_DEVICE constexpr
  void
  copy_unpack_(void const* const src_ptr,
               Coord const& dst_coord, seq<Is...>) const
  {
    SM90_TMA_STORE::copy(&tma_desc_,
                         src_ptr, get<Is>(dst_coord)...);
  }

  // This is the copy_unpack dispatch for this Copy_Traits
  // Src needs to be a smem tensor
  // Dst needs to be a gmem tensor with TmaCoordIterator .data()
  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr
  void
  copy_unpack(Copy_Traits        const& traits,
              Tensor<TS,SLayout> const& src,
              Tensor<TD,DLayout>      & dst)
  {
    static_assert(is_smem<TS>::value, "Expected smem src for SM90_TMA_STORE");
    //static_assert(is_gmem<TD>::value, "Expected gmem dst for SM90_TMA_STORE");  // TMA spoofed src tensor

    traits.copy_unpack_(raw_pointer_cast(src.data()), dst.data().coord_, tuple_seq<decltype(dst.data().coord_)>{});
  }
};

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// BULK COPY //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

template <class NumBitsPerTMA, class... OpArgs>
struct Copy_Traits<SM90_BULK_COPY_G2S, NumBitsPerTMA, OpArgs...>
{
  static_assert(int32_t(NumBitsPerTMA::value / 8) % 16 == 0,
                "Bulk Copy requires copy vector size align to 16B.");

  using ThrID = Layout<_1>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM90_BULK_COPY_G2S arguments
  // 0: uint64_t* bulk_load_memory_barrier
  cute::tuple<OpArgs...> bulk_load_mbar_;

  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr
  void
  copy_unpack(Copy_Traits        const& traits,
              Tensor<TS,SLayout> const& src,
              Tensor<TD,DLayout>      & dst)
  {
    static_assert(is_same<cute::tuple<OpArgs...>, cute::tuple<uint64_t*>>::value,
                  "Extra arguments not set. Set .with() before use.");
    static_assert(is_gmem<TS>::value, "Expected gmem src for SM90_BULK_COPY_G2S");
    static_assert(is_smem<TD>::value, "Expected smem dst for SM90_BULK_COPY_G2S");
    SM90_BULK_COPY_G2S::copy(src.data().get(), *get<0>(traits.bulk_load_mbar_),
                             dst.data().get(), int32_t(NumBitsPerTMA::value / 8));
  }

  // Record the memory barrier for the instruction
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM90_BULK_COPY_G2S, NumBitsPerTMA, uint64_t*>
  with(uint64_t& bulk_mbar) const {
    return {{&bulk_mbar}};
  }
};

template <class NumBitsPerTMA>
struct Copy_Traits<SM90_BULK_COPY_S2G, NumBitsPerTMA>
{
  static_assert(int32_t(NumBitsPerTMA::value / 8) % 16 == 0,
                "Bulk Copy requires copy vector size align to 16B.");

  using ThrID = Layout<_1>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBitsPerTMA>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr
  void
  copy_unpack(Copy_Traits        const& traits,
              Tensor<TS,SLayout> const& src,
              Tensor<TD,DLayout>      & dst)
  {
    static_assert(is_smem<TS>::value, "Expected smem src for SM90_BULK_COPY_S2G");
    static_assert(is_gmem<TD>::value, "Expected gmem dst for SM90_BULK_COPY_S2G");
    SM90_BULK_COPY_S2G::copy(src.data().get(), dst.data().get(), int32_t(NumBitsPerTMA::value / 8));
  }
};

//
// Placeholder for the bulk copy algorithm's default, auto-vectorizing behavior
//

template <class... OpArgs>
struct Copy_Traits<SM90_BULK_COPY_AUTO, OpArgs...>
{
  // Logical thread id to thread idx (one-thread)
  using ThrID = Layout<_1>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,_1>, Stride<_0,_0>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,_1>, Stride<_0,_0>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  // SM90_UBULK_COPY arguments
  // 0: uint64_t* bulk_load_memory_barrier [if this is a BULK_LOAD_G2S]
  cute::tuple<OpArgs...> opargs_;

  // Record the memory barrier for the instruction
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM90_BULK_COPY_AUTO, uint64_t*>
  with(uint64_t& bulk_mbar) const {
    return {{&bulk_mbar}};
  }
};

//
// MAKE_TMA_COPY and related
//

namespace detail {

// Use a smem2gmode map to read through the GMEM tensor
// and construct a TMA Descriptor for the resulting instruction
template <class GEngine, class GLayout,
          class SShape, class SStride,
          int B, int M, int S>
CUTE_HOST_RTC
auto
make_tma_copy_desc(Tensor<GEngine,GLayout> const& gtensor,    // The original GMEM Tensor
                   Layout<SShape,SStride>  const& smem_inv_h, // smem_idx to hier gmode
                   Swizzle<B,M,S>          const& swizzle)    // Swizzle fn on smem_idx
{
  using T = typename GEngine::value_type;

  // This is the gmem "vector" that corresponds to the smem vector in memory  (smem_box_shape):(gmem_prob_stride)
  Tensor tma_gstride = recast<T>(gtensor.compose(smem_inv_h));

  // If the sizes of smem_inv_h and tma_gstride don't match, then a non-trivial recast was performed.
  // In that case, require that the recasted modes all have size-1 so TMA can identity them and skip them.
  for_each(zip(flatten(shape(smem_inv_h)), flatten(shape(tma_gstride))), [] (auto s_and_g) {
    auto [s,g] = s_and_g;
    CUTE_STATIC_ASSERT_V(s == g or g == Int<1>{},
                         "A non-trivial recast was performed, but TMA cannot identify which modes to leave out.");
  });

  // Perform the tiling to the gmem vector again, but with indirections to the gtensor modes
  auto gbasis = make_identity_layout(shape(gtensor));
  auto tma_gbasis_tile_tmp = gbasis.compose(smem_inv_h);
  // Instead of the recast (gbasis doesn't have type info), replace the shape with the already-recasted shape and coalesce out any size-1 modes
  auto tma_gbasis_tile = coalesce(make_layout(shape(tma_gstride), stride(tma_gbasis_tile_tmp)));

  // Recast the original tensor for shape inspections
  auto glayout_T = recast<T>(gtensor).layout();

  // Find missing bases that don't belong to a size-1 mode of the recast input
  // NOTE This is essentially ArithmeticTuple complement...
  // NOTE   in persuit of implementing an ArithmeticTuple logical_divide for smem_inv_h
  auto tma_gbasis_full = fold(zip(flatten(shape(glayout_T)), flatten(stride(gbasis))), tma_gbasis_tile, 
                              [](auto tma_g, auto s_and_d) {
    auto [s,d] = s_and_d;
    auto k = find(stride(tma_g), d);  // Find the basis in tma_gstride
    if constexpr (decltype(k != rank(tma_g) || is_constant<1, decltype(s)>{})::value) {
      // If d was found or s is static-1, then don't append
      return tma_g;
    } else {
      // Else, append the missing basis
      return append(tma_g, make_layout(Int<1>{}, d));
    }
  });

  // Group the trailing modes to make this max rank-5
  auto tma_gbasis = group<cute::min(rank(tma_gbasis_full),4),-1>(tma_gbasis_full);

#if 0
  print("gtensor      : "); print(gtensor); print("\n");
  print("smem_inv_h   : "); print(smem_inv_h); print("\n");
  print("tma_gstride  : "); print(tma_gstride); print("\n");
  print("gbasis       : "); print(gbasis); print("\n");
  print("tma_gb_tile  : "); print(tma_gbasis_tile  ); print("\n");
  print("tma_gbasis   : "); print(tma_gbasis); print("\n");
#endif

  constexpr int tma_dim = decltype(rank(tma_gbasis))::value;

  //
  // TMA gmem desc info
  //

  void* gmem_address = (void*) raw_pointer_cast(gtensor.data());

  cute::array<uint64_t, 5> gmem_prob_shape  = {1,1,1,1,1};
  cute::array<uint64_t, 5> gmem_prob_stride = {0,0,0,0,0};
  // Use the indirections in tma_gbasis in the values of flat_glayout to construct the gmem shapes/strides
  for_each(make_seq<tma_dim>{}, [&](auto i) {
    for_each(stride<i>(tma_gbasis), [&](auto ej) {
      // Problem stride
      uint64_t stride_j = basis_get(ej, stride(glayout_T)) * sizeof(T);
      uint64_t old_stride = gmem_prob_stride[i];
      gmem_prob_stride[i] = gcd(gmem_prob_stride[i], stride_j);

      // Problem shape
      uint64_t shape_j = basis_get(ej, shape(glayout_T));
      if (gmem_prob_stride[i] != 0) {
        // Recurrence: g_shape = (s_i - 1) * (d_i / gcd_j d_j) + 1
        gmem_prob_shape[i] = (gmem_prob_shape[i]-1) * (old_stride / gmem_prob_stride[i])
                           +            (shape_j-1) * (stride_j   / gmem_prob_stride[i])
                           + 1;
      } else {
        gmem_prob_shape[i] = shape_j;
      }
    });
  });

  assert((reinterpret_cast<uint64_t>(gmem_address) & 0b1111) == 0);  // Address must be 16B-aligned

  assert(gmem_prob_shape[0] >= (uint64_t(1)));               // Size must be min 1
  assert(gmem_prob_shape[0] <= (uint64_t(1) << 32));         // Size must be max 2^32
  assert(gmem_prob_shape[1] >= (uint64_t(1)));               // Size must be min 1
  assert(gmem_prob_shape[1] <= (uint64_t(1) << 32));         // Size must be max 2^32
  assert(gmem_prob_shape[2] >= (uint64_t(1)));               // Size must be min 1
  assert(gmem_prob_shape[2] <= (uint64_t(1) << 32));         // Size must be max 2^32
  assert(gmem_prob_shape[3] >= (uint64_t(1)));               // Size must be min 1
  assert(gmem_prob_shape[3] <= (uint64_t(1) << 32));         // Size must be max 2^32
  assert(gmem_prob_shape[4] >= (uint64_t(1)));               // Size must be min 1
  assert(gmem_prob_shape[4] <= (uint64_t(1) << 32));         // Size must be max 2^32

  // TMA descriptor does not store the zeroth stride and assumes it is sizeof(T) == one element.
  assert(gmem_prob_stride[0] == sizeof(T) && "Majorness of smem doesn't match majorness of gmem");

  assert((gmem_prob_stride[1]) < (uint64_t(1) << 40));       // Stride must be max 2^40
  assert((gmem_prob_stride[1] & 0b1111) == 0);               // Stride must be multiple of 16B (128b)
  assert((gmem_prob_stride[2]) < (uint64_t(1) << 40));       // Stride must be max 2^40
  assert((gmem_prob_stride[2] & 0b1111) == 0);               // Stride must be multiple of 16B (128b)
  assert((gmem_prob_stride[3]) < (uint64_t(1) << 40));       // Stride must be max 2^40
  assert((gmem_prob_stride[3] & 0b1111) == 0);               // Stride must be multiple of 16B (128b)
  assert((gmem_prob_stride[4]) < (uint64_t(1) << 40));       // Stride must be max 2^40
  assert((gmem_prob_stride[4] & 0b1111) == 0);               // Stride must be multiple of 16B (128b)

  //
  // TMA smem desc info
  //

  cute::array<uint32_t, 5> smem_box_shape  = {1,1,1,1,1};
  cute::array<uint32_t, 5> smem_box_stride = {1,1,1,1,1};
  // The smem box is simply given by the sizes of the modes in tma_gbasis
  for_each(make_seq<tma_dim>{}, [&](auto i) {
    smem_box_shape[i] *= size<i>(tma_gbasis);
  });

  assert(smem_box_shape[0] >= (uint64_t(1)));                // Size must be min 1
  assert(smem_box_shape[0] <= (uint64_t(1) << 8));           // Size must be max 2^8 = 256
  assert(smem_box_shape[0] >= (uint64_t(1)));                // Size must be min 1
  assert(smem_box_shape[0] <= (uint64_t(1) << 8));           // Size must be max 2^8 = 256
  assert(smem_box_shape[0] >= (uint64_t(1)));                // Size must be min 1
  assert(smem_box_shape[0] <= (uint64_t(1) << 8));           // Size must be max 2^8 = 256
  assert(smem_box_shape[0] >= (uint64_t(1)));                // Size must be min 1
  assert(smem_box_shape[0] <= (uint64_t(1) << 8));           // Size must be max 2^8 = 256

  assert(smem_box_stride[0] >= (uint32_t(1)));               // Stride must be min 1
  assert(smem_box_stride[0] <= (uint32_t(8)));               // Stride must be max 2^3 = 8
  assert(smem_box_stride[1] >= (uint32_t(1)));               // Stride must be min 1
  assert(smem_box_stride[1] <= (uint32_t(8)));               // Stride must be max 2^3 = 8
  assert(smem_box_stride[2] >= (uint32_t(1)));               // Stride must be min 1
  assert(smem_box_stride[2] <= (uint32_t(8)));               // Stride must be max 2^3 = 8
  assert(smem_box_stride[3] >= (uint32_t(1)));               // Stride must be min 1
  assert(smem_box_stride[3] <= (uint32_t(8)));               // Stride must be max 2^3 = 8
  assert(smem_box_stride[4] >= (uint32_t(1)));               // Stride must be min 1
  assert(smem_box_stride[4] <= (uint32_t(8)));               // Stride must be max 2^3 = 8

  //
  // Construct the descriptor
  //

  TmaDescriptor tma_desc = {0};

  //
  // TMA general info
  //

#if (__CUDACC_VER_MAJOR__ >= 12) && !defined(__CUDACC_RTC__)

  CUtensorMapDataType     tma_format      = TMA::to_CUtensorMapDataType<T>();
  CUtensorMapInterleave   tma_interleave  = CU_TENSOR_MAP_INTERLEAVE_NONE;
  CUtensorMapL2promotion  tma_l2Promotion = CU_TENSOR_MAP_L2_PROMOTION_L2_128B;
  CUtensorMapFloatOOBfill tma_oobFill     = CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE;

  // TMA smem swizzle type
  CUtensorMapSwizzle smem_swizzle = TMA::to_CUtensorMapSwizzle(get_tma_swizzle_bits(swizzle));
  CUresult result = cuTensorMapEncodeTiled(
      &tma_desc,
      tma_format,
      tma_dim,
      gmem_address,
      gmem_prob_shape.data(),
      gmem_prob_stride.data() + 1,  // gmem_prob_stride[0] implicitly 1
      smem_box_shape.data(),
      smem_box_stride.data(),
      tma_interleave,
      smem_swizzle,
      tma_l2Promotion,
      tma_oobFill);

  if (result != CUDA_SUCCESS) {
    std::cerr << "TMA Desc Addr:   " << &tma_desc
              << "\nformat         " << tma_format
              << "\ndim            " << tma_dim
              << "\ngmem_address   " << gmem_address
              << "\nglobalDim      " << gmem_prob_shape
              << "\nglobalStrides  " << gmem_prob_stride
              << "\nboxDim         " << smem_box_shape
              << "\nelementStrides " << smem_box_stride
              << "\ninterleave     " << tma_interleave
              << "\nswizzle        " << smem_swizzle
              << "\nl2Promotion    " << tma_l2Promotion
              << "\noobFill        " << tma_oobFill << std::endl;
    std::cerr << "Error: Failed to initialize the TMA descriptor " << result << std::endl;
    assert(false);
  }

#endif // (__CUDACC_VER_MAJOR__ >= 12) && !defined(__CUDACC_RTC__)
  // Finally, get the inverse permutation of the E<i> bases for the mocked gmem stride
  // NOTE This is essentially ArithmeticTuple inverse...
  auto gmem_stride_bases = transform_leaf(stride(gbasis), [&](auto ei) {
    auto si = basis_get(ei,  shape(glayout_T));
    auto di = basis_get(ei, stride(glayout_T));
    auto tma_gbasis_stride = stride(tma_gbasis);
    // Find j such that E<i> is in stride<j>(tma_gbasis)
    [[maybe_unused]] auto j = find_if(tma_gbasis_stride, [&](auto tma_stride_j) { return any_of(tma_stride_j, [&](auto dj) { return dj == ei; }); });
    // Return the TMA basis this gmode contributes to
    if constexpr (is_constant<1, decltype(si)>::value || decltype(j == rank(tma_gbasis_stride))::value) {
      return Int<0>{};     // Return arithmetic identity -- no contribution to the TMA
    } else 
    if constexpr (decltype(rank<j>(tma_gbasis_stride) == Int<1>{})::value) {
      return E<j>{};       // We know that the scale factor is Int<1>{}
    } else {
      return E<j>{} * int32_t(di * sizeof(T) / cute::max(gmem_prob_stride[j], 16));
    }
  });

#if 0
  print("gmem_stride_bases : "); print(gmem_stride_bases); print("\n");
#endif

  return cute::make_tuple(tma_desc, gmem_stride_bases);
}

// The "logical TMA tid" is a map from the CTA rank to its logical id
// within the instruction.  It works like a mask or ordering on the
// CTAs.  For non-multicast TMA, all CTAs should map to 0.  For
// multicast TMA of size 4, CTAs will be mapped to {0,1,2,3}.
template <class CopyOp,
          class GEngine, class GLayout,
          class SLayout,
          class TShape, class TStride,
          class VShape, class VStride>
CUTE_HOST_RTC
auto
make_tma_copy_tiled(CopyOp,
                    Tensor<GEngine,GLayout> const& gtensor,     // Full GMEM Tensor
                    SLayout                 const& slayout,     // CTA Tile of SMEM
                    Layout<TShape,TStride>  const& cta_t_map,   // T: CTA thr idx -> logical TMA tid
                    Layout<VShape,VStride>  const& cta_v_map)   // V: CTA val idx -> gmem coord
{
  //
  // TMA parameter checking
  //

  CUTE_STATIC_ASSERT_V(product_each(shape(slayout)) == product_each(shape(cta_v_map)),
    "TMA requires CTA_Tile and SLayout top-level shape equivalence.");
  CUTE_STATIC_ASSERT_V(size(slayout) % cosize(cta_t_map) == Int<0>{},
    "Number of active CTAs in TMA must divide domain size of slayout.");

  //
  // TMA slayout manipulation
  //

  // Invert the smem to get the largest contiguous vector in the smem layout
  auto inv_smem_layout = right_inverse(get_nonswizzle_portion(slayout));
  // trunc_smem_idx -> trunc_smem_coord

  // Map from smem idx to a gmem mode
  auto sidx_to_gmode = coalesce(composition(cta_v_map, inv_smem_layout));

#if 0
  print("g_layout         : "); print(gtensor.layout()); print("\n");
  print("s_layout         : "); print(slayout); print("\n");
  print("cta_t_map        : "); print(cta_t_map); print("\n");
  print("cta_v_map        : "); print(cta_v_map); print("\n");
  print("inv_smem         : "); print(inv_smem_layout); print("\n");
  print("sidx_to_gmode    : "); print(sidx_to_gmode); print("\n");
#endif

  //
  // TMA gtensor manipulation
  //

  // Generate a TupleBasis for the gtensor
  auto glayout_basis = make_identity_layout(shape(gtensor));

  // Tile the modes of gtensor with the truncated cta_v_map o inv_smem_layout_trunc
  auto tma_layout_full = flatten(composition(glayout_basis, sidx_to_gmode));

  // Truncate any incompatibilities -- no starting in the middle of gmodes
  auto smem_rank = find_if(stride(tma_layout_full), [](auto e) {
    [[maybe_unused]] auto v = basis_value(e);
    return not is_constant<1,decltype(v)>{};
  });
  static_assert(smem_rank > 0, "Could not find a common tile-gmem vectorization. Does the Tile select out major GMEM modes?");
  // TMA uses a maximum of 5 modes
  // If the gtensor has more than 5 modes, we need to reserve the last TMA-mode as a "multimode"
  constexpr int smem_tma_rank = cute::min(int(smem_rank), (rank(tma_layout_full) > Int<5>{} ? 4 : 5));

  // Keep only the static-1 basis modes into gmem
  auto tma_layout_trunc = take<0,smem_tma_rank>(tma_layout_full);

  // Split according to the portion each multicast CTA will be responsible for
  auto tma_layout_vt = logical_divide(tma_layout_trunc, shape_div(size(tma_layout_trunc), cosize(cta_t_map)));

#if 0
  print("glayout_basis   : "); print(glayout_basis); print("\n");
  print("tma_layout_full : "); print(tma_layout_full); print("\n");

  print("tma_layout_trunc: "); print(tma_layout_trunc); print("\n");
  print("tma_layout_vt   : "); print(tma_layout_vt); print("\n");
#endif

  //
  // Construct the TMA Desc and GMEM mode ordering
  //

  auto [tma_desc, gmem_stride_bases] = detail::make_tma_copy_desc(gtensor, layout<0>(tma_layout_vt), get_swizzle_portion(slayout));

  //
  // Construct the Copy_Traits
  //

  using T = typename GEngine::value_type;
  constexpr int num_bits_per_tma = decltype(size<0>(tma_layout_vt))::value * sizeof(T) * 8;
  using Traits = Copy_Traits<CopyOp, cute::C<num_bits_per_tma>, decltype(gmem_stride_bases)>;

#if 0
  print("num_bits      :  "); print(NumBitsPerTMA{}); print("\n");
  print("g_stride_bases:  "); print(gmem_stride_bases); print("\n");
#endif

  Traits tma_traits{tma_desc, gmem_stride_bases};

  //
  // Construct the TiledCopy
  //

  auto cta_tiler = product_each(shape(cta_v_map));

  // (CTA V, CTA T) -> smem_coord
  auto layout_vt = composition(inv_smem_layout, make_layout(shape(tma_layout_vt)));
  // Scale that up to cover all of the smem_coords
  //
  // The smem vector might not cover all of the tile,
  // so multiply it up to cover the entire tile.
  // "T" here (the parallel index) is a CTA index.
  auto layout_VT = tile_to_shape(layout_vt, make_shape(size(cta_v_map)/size<1>(layout_vt), size<1>(layout_vt)));
  // Flip it and change the domain of the T from logical thr to thr_idx
  auto layout_TV = make_layout(composition(layout<1>(layout_VT), cta_t_map), layout<0>(layout_VT));

#if 0
  print("cta_tiler : "); print(cta_tiler); print("\n");
  print("layout_VT : "); print(layout_VT); print("\n");
  print("layout_TV : "); print(layout_TV); print("\n");
#endif

  using T = typename GEngine::value_type;
  return TiledCopy<Copy_Atom<Traits,T>, decltype(layout_TV), decltype(cta_tiler)>{tma_traits};
}

} // end namespace detail

/** Make a CuTe CTA-collective TiledCopy for a TMA operation.
 *
 * @param CopyOp The target copy operation: SM90_TMA_LOAD, SM90_TMA_LOAD_MULTICAST, SM90_TMA_STORE
 * @param gtensor The GMEM Tensor to be involved in the TMA.
 * @param slayout The SMEM Layout to be involved in the TMA.
 * @param cta_tile The CTA-local tile that each CTA will be tiling GMEM with.
 *                 This is often the blk_shape that is used to tile the GMEM for CTAs:
 *                   local_tile(gtensor, blk_shape, blk_coord) -> CTA-local tile of gtensor
 * @param cluster_size When using SM90_TMA_LOAD_MULTICAST, this can be a (static) power-of-2 <= 16
 *                   defining the multicast size (used to further partition the SMEM)
 *                 Else, static-1
 *
 * This code attempts to maximize the TMA box size. It does this by tracing
 * the SMEM "vector" -- the inverse of the smem layout -- to find the largest
 * contiguous array of smem that can be written to/from global memory given
 * the constraints that the TMA instruction imposes.
 *
 * This is accomplished by assigning "basis" strides to the GMEM to track which
 * modes of SMEM map to which modes of GMEM, then reorder the modes of GMEM according
 * to the SMEM vector, and then using those GMEM/SMEM modes to fill in the desc.
 *
 * Examples:
     using T = float;
     T* gptr = nullptr;

    {
    // Simple 2D
    Tensor gtensor = make_tensor(gptr, make_shape(1024, 256), GenRowMajor{}); // K-Major GMEM
    auto slayout   = make_layout(make_shape(_64{}, _32{}), GenRowMajor{});    // K-Major SMEM
    auto tma = make_tma_copy(SM90_TMA_LOAD{}, gtensor, slayout);
    }

    {
    // GMMA 2D
    Tensor gtensor = make_tensor(gptr, make_shape(1024, 256));                                 // MN-Major GMEM
    auto slayout   = tile_to_shape(GMMA::Layout_MN_SW128_Atom<T>{}, make_shape(_128{},_64{})); // MN-Major Swizzled+Tiled 128x64 SMEM
    auto tma = make_tma_copy(SM90_TMA_LOAD{}, gtensor, slayout);
    }

    {
    // 3D
    Tensor gtensor = make_tensor(gptr, make_shape(1024, 32, 512), make_stride(64, Int<1>{}, 65536)); // GMEM
    auto slayout   = make_layout(make_shape(_16{}, _8{}, _2{}), make_stride(_16{}, _1{}, _8{}));     // SMEM w/ same major-mode
    auto tma = make_tma_copy(SM90_TMA_LOAD{}, gtensor, slayout);
    }

    {
    // cuTENSOR 4D
    auto layout = make_shape(make_shape(32,40),make_shape(make_shape(8,8),656)); // GMEM
    auto cta_tile    = make_shape(_128{},make_shape(_32{},_2{}));                // GMEM Tiling:
                                                                                 //   Take 128-elem from m: m0 must divide 128,
                                                                                 //                         m-last may be predicated
                                                                                 //   Take 32-elem from k0, 2-elem from k1
    auto slayout = make_layout(cta_tile);                                        // Col-Major SMEM
    auto tma = make_tma_copy(SM90_TMA_LOAD{}, gtensor, slayout, cta_tile, Int<1>{});
    }
 *
 * Check the TMA box size and desc:
    print("TMA Box size:  "); print(typename decltype(tma)::Tiler_MN{}); print("\n");
    print("TMA desc     : "); print(tma.tma_desc_); print("\n");
 *
 * Usage:
     Tensor mA = tma_a.get_tma_tensor(make_shape(M,N));        // (M,N) TMA coord tensor
     Tensor gA = local_tile(mA, cta_tile, cta_coord);          // (BLK_M,BLK_N) TMA coord tensor for this CTA
     Tensor sA = make_tensor(make_smem_ptr<T>(sptr), slayout); // (BLK_M,BLK_N) SMEM tensor

     auto cta_tma = tma.get_slice(cta_idx_in_cluster);         // Slice for multicast partitioning
     Tensor tAgA = cta_tma.partition_S(gA);                    // Partition for src
     Tensor tAsA = cta_tma.partition_D(sA);                    // Partition for dst

     copy(tma.with(barrier, mcast_mask), tAgA, tAsA);          // copy with supporting TMA params
 */
template <class CopyOp,
          class GEngine, class GLayout,
          class SLayout,
          class CTA_Tile,
          class Cluster_Size>
CUTE_HOST_RTC
auto
make_tma_copy(CopyOp                  const& copy_op,
              Tensor<GEngine,GLayout> const& gtensor,
              SLayout                 const& slayout,
              CTA_Tile                const& cta_tile,
              Cluster_Size            const& cluster_size)
{

  return detail::make_tma_copy_tiled(copy_op,
                                     gtensor,
                                     slayout,
                                     make_layout(cluster_size),
                                     make_identity_layout(cta_tile));
}

// Explicit defaulting
template <class CopyOp,
          class GEngine, class GLayout,
          class SLayout>
CUTE_HOST_RTC
auto
make_tma_copy(CopyOp                  const& copy_op,
              Tensor<GEngine,GLayout> const& gtensor,
              SLayout                 const& slayout)
{
  return make_tma_copy(copy_op, gtensor, slayout, product_each(shape(slayout)), Int<1>{});
}

template <class CopyOp,
          class GEngine, class GLayout,
          class SLayout,
          class Cluster_Size>
CUTE_HOST_RTC
auto
make_tma_copy(CopyOp                  const& copy_op,
              Tensor<GEngine,GLayout> const& gtensor,
              SLayout                 const& slayout,
              Cluster_Size            const& cluster_size)
{
  return make_tma_copy(copy_op, gtensor, slayout, product_each(shape(slayout)), cluster_size);
}

} // end namespace cute
