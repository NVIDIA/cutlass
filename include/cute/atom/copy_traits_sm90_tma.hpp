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

#include <cute/arch/copy_sm90_desc.hpp>
#include <cute/arch/copy_sm90_tma.hpp>

#include <cute/tensor.hpp>

#include <cute/atom/copy_traits.hpp>
#include <cute/atom/copy_atom.hpp>

namespace cute
{

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// TMA_LOAD ///////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

struct SM90_TMA_LOAD_OP : SM90_TMA_LOAD {};

// The executable SM90_TMA_LOAD with tma_desc and tma_mbar
template <class NumBits>
struct Copy_Traits<SM90_TMA_LOAD_OP, NumBits>
{
  using ThrID   = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBits>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBits>>;

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
#if 0
    print("THR (%d,%d,%d) BLK (%d,%d,%d)\n",
          threadIdx.x, threadIdx.y, threadIdx.z,
          blockIdx.x, blockIdx.y, blockIdx.z);
    print("  TMA Coord "); print(src_coord); print("\n");
    print("  TMA Shape "); print(make_tuple(uint64_t(tma_desc_.size0_),
                                            uint64_t(tma_desc_.size1_),
                                            uint64_t(tma_desc_.size2_),
                                            uint64_t(tma_desc_.size3_))); print("\n");
#endif

    SM90_TMA_LOAD::copy(&tma_desc_,
                      tma_load_mbar_,
                      dst_ptr,
                      get<Is>(src_coord)...);
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
    //static_assert(is_gmem<TS>::value, "Expected gmem src for SM90_TMA_LOAD");  // TMA spoofed src tensor
    static_assert(is_smem<TD>::value, "Expected smem dst for SM90_TMA_LOAD");

    traits.copy_unpack_(dst.data().get(), src.data().coord_, tuple_seq<decltype(src.data().coord_)>{});
  }
};

// The non-executable SM90_TMA_LOAD with tma_desc and no tma_mbar
// Use .with(tma_mbar) to construct an executable version
template <class NumBits, class GmemStrides>
struct Copy_Traits<SM90_TMA_LOAD, NumBits, GmemStrides>
{
  using ThrID   = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBits>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBits>>;

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
  Copy_Traits<SM90_TMA_LOAD_OP, NumBits>
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
    constexpr int tma_rank = decltype(cute::min(rank(flatten(g_stride_)), Int<5>{}))::value;
    return make_tensor(ArithmeticTupleIterator(as_arithmetic_tuple(repeat<tma_rank>(Int<0>{}))),
                       g_shape,
                       g_stride_);
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

template <class NumBits>
struct Copy_Traits<SM90_TMA_LOAD_MULTICAST_OP, NumBits>
{
  using ThrID   = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBits>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBits>>;

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
#if 0
    print("THR (%d,%d,%d) BLK (%d,%d,%d)\n",
          threadIdx.x, threadIdx.y, threadIdx.z,
          blockIdx.x, blockIdx.y, blockIdx.z);
    print("  TMA Coord "); print(src_coord); print("\n");
    print("  TMA Shape "); print(make_tuple(uint64_t(tma_desc_.size0_),
                                            uint64_t(tma_desc_.size1_),
                                            uint64_t(tma_desc_.size2_),
                                            uint64_t(tma_desc_.size3_))); print("\n");
#endif

    SM90_TMA_LOAD_MULTICAST::copy(&tma_desc_,
                                tma_load_mbar_,
                                multicast_mask_,
                                dst_ptr,
                                get<Is>(src_coord)...);
  }

  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr
  void
  copy_unpack(Copy_Traits        const& traits,
              Tensor<TS,SLayout> const& src,
              Tensor<TD,DLayout>      & dst)
  {
    //static_assert(is_gmem<TS>::value, "Expected gmem src for SM90_TMA_LOAD");  // TMA spoofed src tensor
    static_assert(is_smem<TD>::value, "Expected smem dst for SM90_TMA_LOAD_MULTICAST");

    traits.copy_unpack_(dst.data().get(), src.data().coord_, tuple_seq<decltype(src.data().coord_)>{});
  }
};

template <class NumBits, class GmemStrides>
struct Copy_Traits<SM90_TMA_LOAD_MULTICAST, NumBits, GmemStrides>
{
  using ThrID   = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBits>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBits>>;

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
  Copy_Traits<SM90_TMA_LOAD_MULTICAST_OP, NumBits>
  with(uint64_t& tma_load_mbar, uint16_t const& multicast_mask) const {
    return {tma_desc_, tma_load_mbar, multicast_mask};
  }

  // Generate the TMA coord tensor
  template <class GShape>
  CUTE_HOST_DEVICE constexpr
  auto
  get_tma_tensor(GShape const& g_shape) const {
    static_assert(is_congruent<decltype(g_shape), decltype(g_stride_)>::value);
    constexpr int tma_rank = decltype(cute::min(rank(flatten(g_stride_)), Int<5>{}))::value;
    return make_tensor(ArithmeticTupleIterator(as_arithmetic_tuple(repeat<tma_rank>(Int<0>{}))),
                       g_shape,
                       g_stride_);
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
template <class NumBits, class GmemStrides>
struct Copy_Traits<SM90_TMA_STORE, NumBits, GmemStrides>
{
  using ThrID   = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBits>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBits>>;

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
    constexpr int tma_rank = decltype(cute::min(rank(flatten(g_stride_)), Int<5>{}))::value;
    return make_tensor(ArithmeticTupleIterator(as_arithmetic_tuple(repeat<tma_rank>(Int<0>{}))),
                       g_shape,
                       g_stride_);
  }

  template <class Coord, int... Is>
  CUTE_HOST_DEVICE constexpr
  void
  copy_unpack_(void const* const src_ptr,
               Coord const& dst_coord, seq<Is...>) const
  {
#if 0
    print("THR (%d,%d,%d) BLK (%d,%d,%d)\n",
          threadIdx.x, threadIdx.y, threadIdx.z,
          blockIdx.x, blockIdx.y, blockIdx.z);
    print("  TMA Coord "); print(dst_coord); print("\n");
    print("  TMA Shape "); print(make_tuple(uint64_t(tma_desc_.size0_),
                                            uint64_t(tma_desc_.size1_),
                                            uint64_t(tma_desc_.size2_),
                                            uint64_t(tma_desc_.size3_))); print("\n");
#endif

    SM90_TMA_STORE::copy(&tma_desc_,
                      src_ptr,
                      get<Is>(dst_coord)...);
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

    traits.copy_unpack_(src.data().get(), dst.data().coord_, tuple_seq<decltype(dst.data().coord_)>{});
  }
};

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// BULK COPY //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

template <class NumBits, class... OpArgs>
struct Copy_Traits<SM90_BULK_COPY_G2S, NumBits, OpArgs...>
{
  static_assert(int32_t(NumBits::value / 8) % 16 == 0,
                "Bulk Copy requires copy vector size align to 16B.");

  using ThrID = Layout<_1>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBits>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBits>>;
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
                             dst.data().get(), int32_t(NumBits::value / 8));
  }

  // Record the memory barrier for the instruction
  CUTE_HOST_DEVICE constexpr
  Copy_Traits<SM90_BULK_COPY_G2S, NumBits, uint64_t*>
  with(uint64_t& bulk_mbar) const {
    return {{&bulk_mbar}};
  }
};

template <class NumBits>
struct Copy_Traits<SM90_BULK_COPY_S2G, NumBits>
{
  static_assert(int32_t(NumBits::value / 8) % 16 == 0,
                "Bulk Copy requires copy vector size align to 16B.");

  using ThrID = Layout<_1>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,NumBits>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,NumBits>>;
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
    SM90_BULK_COPY_S2G::copy(src.data().get(), dst.data().get(), int32_t(NumBits::value / 8));
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

namespace detail
{

template <int B, int M, int S, class Offset, class SLayout>
auto
get_swizzle_portion(ComposedLayout<Swizzle<B,M,S>,Offset,SLayout>)
{
  return Swizzle<B,M,S>{};
}

template <class Shape, class Stride>
auto
get_swizzle_portion(Layout<Shape,Stride>)
{
  return Swizzle<0,4,3>{};
}

template <int B, int M, int S, class Offset, class SLayout>
auto
get_nonswizzle_portion(ComposedLayout<Swizzle<B,M,S>,Offset,SLayout> const& slayout)
{
  return slayout.layout_fn();
}

template <class Shape, class Stride>
auto
get_nonswizzle_portion(Layout<Shape,Stride> const& slayout)
{
  return slayout;
}

template <int B, int M, int S>
TMA::SmemSwizzleBits
get_tma_swizzle_bits(Swizzle<B,M,S>)
{
  if constexpr (M == 4) {
    switch (B) {
      default:  static_assert(0 <= B && B <= 3, "Expected B = 0,1,2, or 3 when M == 4. Unsupported layout swizzle.");
      case 3:   return TMA::SmemSwizzleBits::B128;
      case 2:   return TMA::SmemSwizzleBits::B64;
      case 1:   return TMA::SmemSwizzleBits::B32;
      case 0:   return TMA::SmemSwizzleBits::DISABLE;
    }
  } else
  {
    static_assert(M < 0, "Unsupported layout swizzle.");
  }
}

template <class Layout>
TMA::SmemSwizzleBits
get_tma_swizzle_bits(Layout const& layout)
{
  return get_tma_swizzle_bits(get_swizzle_portion(layout));
}

#if !defined(__CUDACC_RTC__)
// Use a smem2gmode map to read through the GMEM tensor
// and construct a TMA Descriptor for the resulting instruction
template <class GEngine, class GLayout,
          class SShape, class SStride,
          int B, int M, int S>
CUTE_HOST
auto
make_tma_copy_desc(Tensor<GEngine,GLayout> const& gtensor,    // The original GMEM Tensor
                   Layout<SShape,SStride>  const& smem_inv,   // smem_idx to flat gmode
                   Swizzle<B,M,S>          const& swizzle)    // Swizzle fn on smem_idx
{
  using T = typename GEngine::value_type;

  auto flat_glayout = flatten(gtensor.layout());
  CUTE_STATIC_ASSERT_V(rank(flat_glayout) == rank(smem_inv));
  constexpr int rank_smem_inv = decltype(rank(smem_inv))::value;

  auto tma_multimode = rank(flat_glayout) > Int<5>{};
  constexpr uint32_t tma_dim = cute::min(rank(flat_glayout), 5);;

  //
  // TMA gmem desc info
  //

  void* gmem_address = (void*) gtensor.data();

  cute::array<uint64_t, 5> gmem_prob_shape  = {1,1,1,1,1};
  cute::array<uint64_t, 5> gmem_prob_stride = {0,0,0,0,0};
  for_each(make_seq<rank_smem_inv>{}, [&](auto i) {
    auto e = stride<i>(smem_inv);   // For g++-7.5, let it deduce e rather than fuse with below
    constexpr int j = decltype(e.mode())::value;
    constexpr int tma_i = i < 5 ? i : 4;

    // Problem stride
    uint64_t stride_j = stride<j>(flat_glayout) * sizeof(T);
    uint64_t old_stride = gmem_prob_stride[tma_i];
    gmem_prob_stride[tma_i] = gcd(gmem_prob_stride[tma_i], stride_j);

    // Problem shape
    uint64_t shape_j = shape<j>(flat_glayout);
    if (gmem_prob_stride[tma_i] != 0) {
      // We're "resetting" this TMA mode and using it as a "multimode"
      // Recurrence: g_shape = (s_i - 1) * (d_i / gcd_j d_j) + 1
      gmem_prob_shape[tma_i] = (gmem_prob_shape[tma_i]-1) * (old_stride / gmem_prob_stride[tma_i])
                             +                (shape_j-1) * (stride_j   / gmem_prob_stride[tma_i])
                             + 1;
    } else {
      gmem_prob_shape[tma_i] = shape_j;
    }
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

  assert((gmem_prob_stride[0]) == sizeof(T));                // First stride is implicitly 1
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
  for_each(make_seq<rank_smem_inv>{}, [&](auto i) {
    uint32_t shape_i = shape<i>(smem_inv);
    constexpr int tma_i = i < 5 ? i : 4;
    if (tma_multimode && tma_i == 4) {
      // We're "reusing" this TMA mode and using it as a "multimode"
      smem_box_shape[tma_i] = 1;
    } else {
      smem_box_shape[tma_i] = shape_i;
    }
  });

  assert(smem_box_shape[0] >= (uint64_t(1)));                // Size must be min 1
  assert(smem_box_shape[0] <= (uint64_t(1) << 8));           // Size must be max 2^8
  assert(smem_box_shape[0] >= (uint64_t(1)));                // Size must be min 1
  assert(smem_box_shape[0] <= (uint64_t(1) << 8));           // Size must be max 2^8
  assert(smem_box_shape[0] >= (uint64_t(1)));                // Size must be min 1
  assert(smem_box_shape[0] <= (uint64_t(1) << 8));           // Size must be max 2^8
  assert(smem_box_shape[0] >= (uint64_t(1)));                // Size must be min 1
  assert(smem_box_shape[0] <= (uint64_t(1) << 8));           // Size must be max 2^8

  assert(smem_box_stride[0] >= (uint32_t(1)));               // Stride must be min 1
  assert(smem_box_stride[0] <= (uint32_t(8)));               // Stride must be max 2^3
  assert(smem_box_stride[1] >= (uint32_t(1)));               // Stride must be min 1
  assert(smem_box_stride[1] <= (uint32_t(8)));               // Stride must be max 2^3
  assert(smem_box_stride[2] >= (uint32_t(1)));               // Stride must be min 1
  assert(smem_box_stride[2] <= (uint32_t(8)));               // Stride must be max 2^3
  assert(smem_box_stride[3] >= (uint32_t(1)));               // Stride must be min 1
  assert(smem_box_stride[3] <= (uint32_t(8)));               // Stride must be max 2^3
  assert(smem_box_stride[4] >= (uint32_t(1)));               // Stride must be min 1
  assert(smem_box_stride[4] <= (uint32_t(8)));               // Stride must be max 2^3

  //
  // Construct the descriptor
  //

  TmaDescriptor tma_desc = {0};

  //
  // TMA general info
  //

#if (__CUDACC_VER_MAJOR__ >= 12)

  CUtensorMapDataType     tma_format      = TMA::to_CUtensorMapDataType<T>();
  CUtensorMapInterleave   tma_interleave  = CU_TENSOR_MAP_INTERLEAVE_NONE;
  CUtensorMapL2promotion  tma_l2Promotion = CU_TENSOR_MAP_L2_PROMOTION_NONE;
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

#endif // (__CUDACC_VER_MAJOR__ >= 12)
  // Finally, get the inverse permutation of the E<i> bases for the mocked gmem stride
  auto gmem_stride_bases_flat = transform(make_seq<rank_smem_inv>{}, [&](auto i) {
    auto k = find(stride(smem_inv), E<i>{});
    // For gcc 7.5 -- avoid 'if constexpr'
    int32_t tma_coord_stride = int32_t(stride<i>(flat_glayout) * sizeof(T) / (gmem_prob_stride[4] != 0 ? gmem_prob_stride[4] : 16));
    return conditional_return(tma_multimode && (k >= Int<4>{}),
                              E<4>{} * tma_coord_stride,        // The 4th TMA mode is the multimode, use int32_t coord stride
                              E<k>{});
  });

  // Give that the profile of gtensor and fold it
  // NOTE: This is the only reason we want the original gtensor shape rather than the more intuitive flattened shape
  auto gmem_stride_bases = stride(composition(make_layout(repeat_like(shape(flat_glayout), Int<2>{}), gmem_stride_bases_flat),
                                              make_layout(repeat_like(shape(gtensor),      Int<2>{}))));

  return make_tuple(tma_desc, gmem_stride_bases);
}

template <class CopyOp,
          class GEngine, class GLayout,
          class SLayout,
          class TShape, class TStride,
          class VShape, class VStride>
CUTE_HOST
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

  auto flat_glayout = flatten(gtensor.layout());

  // Invert the smem to get the largest contiguous vector in the smem layout
  auto inv_smem_layout = right_inverse(get_nonswizzle_portion(slayout));
  // trunc_smem_idx -> trunc_smem_coord

  // Map from smem idx to a gmem mode
  auto sidx_to_gmode = coalesce(composition(cta_v_map, inv_smem_layout));

  // Truncate any incompatibilities
  auto smem_rank = find_if(stride(sidx_to_gmode), [](auto e) {
    auto v = basis_value(e);
    return not is_constant<1,decltype(v)>{};
  });
  static_assert(smem_rank > 0, "Could not find a common smem-gmem vectorization for TMA. Do they have a common majorness?");
  // TMA uses a maximum of 5 modes
  // If the gtensor has more than 5 modes, we need to reserve the last TMA-mode as a "multimode"
  constexpr int smem_tma_rank = cute::min(int(smem_rank), (rank(flat_glayout) > Int<5>{} ? 4 : 5));

  // Keep only the static-1 basis modes into gmem
  auto sidx_to_gmode_trunc = take<0,smem_tma_rank>(sidx_to_gmode);

  // Split according to the portion each multicast CTA will be responsible for
  auto sidx_to_gmode_vt = logical_divide(sidx_to_gmode_trunc, shape_div(size(sidx_to_gmode_trunc), cosize(cta_t_map)));

#if 0
  print("g_layout      : "); print(gtensor.layout()); print("\n");
  print("s_layout      : "); print(slayout); print("\n");
  print("cta_t_map     : "); print(cta_t_map); print("\n");
  print("cta_v_map     : "); print(cta_v_map); print("\n");
  print("inv_smem      : "); print(inv_smem_layout); print("\n");
  print("sidx_to_gmode : "); print(sidx_to_gmode); print("\n");

  print("sidx_to_gmode_trunc : "); print(sidx_to_gmode_trunc); print("\n");
  print("sidx_to_gmode_vt    : "); print(sidx_to_gmode_vt); print("\n");
#endif

  //
  // TMA gtensor manipulation
  //

  // Generate a TupleBasis for the gtensor
  auto flat_gbasis  = make_basis_like(shape(flat_glayout));

  // Fold the flat_gbasis into the glayout
  auto glayout_basis = make_layout(shape(gtensor),
                                   stride(composition(make_layout(repeat_like(shape(flat_glayout), Int<2>{}), flat_gbasis),
                                                      make_layout(repeat_like(shape(gtensor),      Int<2>{})))));

  // Tile the modes of gtensor with the truncated cta_v_map o inv_smem_layout_trunc
  auto tma_layout_v_trunc = flatten(composition(glayout_basis, layout<0>(sidx_to_gmode_vt)));

  // Append any missing basis on the end as size-1 modes b/c they got truncated
  // NOTE This is essentially ArithmeticTuple complement...
  auto missing_basis = fold(stride(tma_layout_v_trunc), flat_gbasis, [](auto init, auto e) {
    auto k = find(init, e);
    return remove<k>(init);
  });

  // The appended map from truncated smem codomain to gmem mode: trunc_smem_idx -> gmem_mode
  auto tma_layout_v = make_layout(flatten(cute::make_tuple(tma_layout_v_trunc.shape(),  repeat<rank(missing_basis)>(Int<1>{}))),
                                  flatten(cute::make_tuple(tma_layout_v_trunc.stride(), missing_basis)));

#if 0
  print("flat_gbasis  : "); print(flat_gbasis); print("\n");
  print("missing_b    : "); print(missing_basis); print("\n");
  print("tma_layout_v : "); print(tma_layout_v); print("\n");
#endif

  //
  // Construct the TMA Desc and GMEM mode ordering
  //

  auto [tma_desc, gmem_stride_bases] = detail::make_tma_copy_desc(gtensor, tma_layout_v, get_swizzle_portion(slayout));

  //
  // Construct the Copy_Traits
  //

  using T = typename GEngine::value_type;
  constexpr int num_bits = decltype(size<0>(sidx_to_gmode_vt))::value * sizeof(T) * 8;
  using Traits = Copy_Traits<CopyOp, Int<num_bits>, decltype(gmem_stride_bases)>;

#if 0
  print("num_bits      :  "); print(num_bits); print("\n");
  print("g_stride_bases:  "); print(gmem_stride_bases); print("\n");
#endif

  Traits tma_traits{tma_desc, gmem_stride_bases};

  //
  // Construct the TiledCopy
  //

  auto cta_tiler = product_each(shape(cta_v_map));

  // (CTA V, CTA T) -> smem_coord
  auto layout_vt = composition(inv_smem_layout, make_layout(shape(sidx_to_gmode_vt)));
  // Scale that up to cover all of the smem_coords
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
#endif // !defined(__CUDACC_RTC__)

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
#if !defined(__CUDACC_RTC__)
template <class CopyOp,
          class GEngine, class GLayout,
          class SLayout,
          class CTA_Tile,
          class Cluster_Size>
CUTE_HOST
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
CUTE_HOST
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
CUTE_HOST
auto
make_tma_copy(CopyOp                  const& copy_op,
              Tensor<GEngine,GLayout> const& gtensor,
              SLayout                 const& slayout,
              Cluster_Size            const& cluster_size)
{
  return make_tma_copy(copy_op, gtensor, slayout, product_each(shape(slayout)), cluster_size);
}
#endif // !defined(__CUDACC_RTC__)

} // end namespace cute
