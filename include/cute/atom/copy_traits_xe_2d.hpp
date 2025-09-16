/***************************************************************************************************
* Copyright (C) 2025 Intel Corporation, All rights reserved.
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

#include <cute/atom/copy_atom.hpp>
#include <cute/atom/copy_traits.hpp>

#include <cute/algorithm/prefetch.hpp>
#include <cute/arch/copy_xe_2d.hpp>

// 2D block payload intrinsics
SYCL_EXTERNAL extern "C" int* __builtin_IB_subgroup_createBlock2DAddressPayload(long base, int width_minus_one, int height_minus_one, int pitch_minus_one,
                                                                                int blockX, int blockY, int blockWidth, int blockHeight, int numBlocks);
SYCL_EXTERNAL extern "C" int* __builtin_IB_subgroup_copyBlock2DAddressPayload(int* AP);

SYCL_EXTERNAL extern "C" void __builtin_IB_subgroup_addBlock2DAddressPayloadBlockX(int* addrPayload, int blockX);
SYCL_EXTERNAL extern "C" void __builtin_IB_subgroup_addBlock2DAddressPayloadBlockY(int* addrPayload, int blockY);
SYCL_EXTERNAL extern "C" void __builtin_IB_subgroup_setBlock2DAddressPayloadBlockX(int* addrPayload, int blockX);
SYCL_EXTERNAL extern "C" void __builtin_IB_subgroup_setBlock2DAddressPayloadBlockY(int* addrPayload, int blockY);
SYCL_EXTERNAL extern "C" void __builtin_IB_subgroup_setBlock2DAddressPayloadBase(int* addrPayload, long base);
SYCL_EXTERNAL extern "C" void __builtin_IB_subgroup_setBlock2DAddressPayloadWidth(int* addrPayload, int width_minus_one);
SYCL_EXTERNAL extern "C" void __builtin_IB_subgroup_setBlock2DAddressPayloadHeigth(int* addrPayload, int height_minus_one);
SYCL_EXTERNAL extern "C" void __builtin_IB_subgroup_setBlock2DAddressPayloadPitch(int* addrPayload, int pitch_minus_one);


namespace cute {

// Utility to check if a layout belongs to a coordinate tensor.
template <typename Layout>
static constexpr bool is_counting_layout_v = is_arithmetic_tuple_like<decltype(Layout{}(0))>::value;




// Base traits class for block 2D messages.
//
// XMode and YMode are mode indices into the tensor, identifying which modes map to the block 2D dimensions.
//   X: consecutive dimension
//   Y: strided dimension internal to the copy atom
// While individual atoms perform 2D copies, additional dimensions are supported by tiling.
//
// If the value type of the tensor has a different size from the underlying copy atoms,
//   it must be specified via the ValType template argument. Due to the SIMD-like layout of data
//   in registers, the generic CuTe code for handling type size changes (via Copy_Atom) does not
//   work properly in most cases.
template <class Op, class XMode, class YMode, typename ValType, typename TiledStrides = Stride<_1>>
struct Xe2DTraitsBase
{
  using Traits = Copy_Traits<Op, XMode, YMode, ValType, TiledStrides>;
  using ThrID = Layout<intel::_SGSize>;

  static constexpr int ValBits = is_void_v<ValType> ? Op::CopyBits
                                                    : int(sizeof_bits_v<ValType>);
  static_assert(Op::CopyBits % ValBits == 0, "Type is incompatible with this copy atom");

  // Payload for 2D block message:
  //   - base pointer
  //   - matrix width/height/pitch in global memory
  //   - x/y offsets (overwritten during each copy operation)
  //   - block width/height/count
  // Note the payload is mutable to allow x/y offsets to be dynamically updated for each use.
  mutable int *payload;

  // Copy of base pointer, to allow payload updates for >2D tensors.
  uint64_t base_ptr;

  // Copies of width/height/pitch, for constructing related traits (e.g. load->prefetch)
  uint32_t width, height, pitch;

  // Strides not handled by block 2D operations (>2D tensors).
  TiledStrides tiled_strides;

  static constexpr bool nontrivial_tiled_strides = !is_static_v<TiledStrides>
      || !is_constant_v<0, decltype(cute::max(TiledStrides{}))>;

  // Uninitialized atom, available on host or device.
  CUTE_HOST_DEVICE
  Xe2DTraitsBase() {}

  // Initialized atom, device-only.
  template <typename SEngine, typename SLayout>
  CUTE_DEVICE
  Xe2DTraitsBase(Tensor<SEngine, SLayout> const& src)
      : base_ptr((uint64_t) &*src.data()),
        tiled_strides(replace<XMode::value>(replace<YMode::value>(src.stride(), _0{}), _0{}))
  {
    constexpr auto SBits = sizeof_bits_v<typename SEngine::value_type>;
    width = (shape<XMode::value>(src) * SBits) >> 3;
    height = shape<YMode::value>(src);
    pitch = (stride<YMode::value>(src) * SBits) >> 3;
#ifdef CUTE_ENABLE_XE_BLOCK_2D_ASSERT
    assert((base_ptr % 64 == 0) && "CuTe runtime error: misaligned block 2D base pointer");
    assert((width % 4 == 0) && "CuTe runtime error: misaligned block 2D tensor width");
    assert((pitch % 4 == 0) && "CuTe runtime error: misaligned block 2D tensor pitch");
    assert((width <= 0xFFFFFF) && "CuTe runtime error: block 2D tensor width exceeds 2^24");
    assert((height <= 0xFFFFFF) && "CuTe runtime error: block 2D tensor height exceeds 2^24");
    assert((pitch <= 0xFFFFFF) && "CuTe runtime error: block 2D tensor pitch exceeds 2^24");
#endif
    init_payload();
  }

  template <class Op2, typename ValType2>
  CUTE_DEVICE explicit
  Xe2DTraitsBase(Xe2DTraitsBase<Op2, XMode, YMode, ValType2, TiledStrides> const& other)
    : base_ptr(other.base_ptr), width(other.width), height(other.height), pitch(other.pitch),
      tiled_strides(other.tiled_strides)
  {
    init_payload();
  }

  // Initialize a previously-uninitialized atom.
  template <typename... Args>
  CUTE_DEVICE static auto
  with(Args&&... args) {
    return Traits(std::forward<Args>(args)...);
  }

  CUTE_DEVICE
  void init_payload() {
#ifdef __SYCL_DEVICE_ONLY__
    payload = __builtin_IB_subgroup_createBlock2DAddressPayload(
      base_ptr,
      width - 1,
      height - 1,
      pitch - 1,
      0,  /* x offset, configured per-copy */
      0,  /* y offset, configured per-copy */
      Op::AtomWidth / Op::BlockCount,
      Op::AtomHeight,
      Op::BlockCount
    );
#endif
  }

  template <int Bits, typename Coord>
  CUTE_DEVICE
  void update_payload(const Coord &coord) const
  {
#ifdef __SYCL_DEVICE_ONLY__
    // Update x/y offsets in payload
    int32_t x = get<XMode::value>(coord) * Bits / Op::CopyBits;
    int32_t y = get<YMode::value>(coord);
    __builtin_IB_subgroup_setBlock2DAddressPayloadBlockX(payload, x);
    __builtin_IB_subgroup_setBlock2DAddressPayloadBlockY(payload, y);

#ifdef CUTE_ENABLE_XE_BLOCK_2D_ASSERT
    assert((x % 4 == 0) && "CuTe runtime error: misaligned block 2D x offset");
#endif

    // Perform stride calculation and update base pointer for > 2D tensors
    if constexpr (nontrivial_tiled_strides) {
      auto offset = inner_product(coord, tiled_strides);
      auto byte_offset = (offset * Bits) >> 3;
      __builtin_IB_subgroup_setBlock2DAddressPayloadBase(payload, base_ptr + byte_offset);

#ifdef CUTE_ENABLE_XE_BLOCK_2D_ASSERT
      assert((byte_offset % 64 == 0) && "CuTe runtime error: misaligned block 2D base pointer");
#endif
    }
#endif /* __SYCL_DEVICE_ONLY__ */
  }

  static constexpr auto get_x_mode() { return XMode{}; }
  static constexpr auto get_y_mode() { return YMode{}; }
};

template <class Op, class XMode, class YMode, typename ValType, typename TiledStrides = Stride<_1>>
struct Xe2DLoadTraitsBase : Xe2DTraitsBase<Op, XMode, YMode, ValType, TiledStrides>
{
  using Super = Xe2DTraitsBase<Op, XMode, YMode, ValType, TiledStrides>;
  using Traits = typename Super::Traits;
  using ThrID = typename Super::ThrID;

  using Super::Super;

  // Execution.
  template <class SEngine, class SLayout,
            class DEngine, class DLayout>
  CUTE_DEVICE friend constexpr void
  copy_unpack(Traits const&                   traits,
              Tensor<SEngine, SLayout> const& src,
              Tensor<DEngine, DLayout> &      dst) {
    using SType = typename SEngine::value_type;
    using DType = typename DEngine::value_type;
    using SrcLayout = typename Traits::SrcLayout;
    using DstLayout = typename Traits::DstLayout;
    constexpr auto DBits = sizeof_bits_v<DType>;

    static_assert(is_counting_layout_v<SLayout>, "Source tensor must be a coordinate tensor.");
    static_assert(is_rmem_v<DEngine>, "Destination tensor must be in registers.");
    static_assert(size(SLayout{}) * DBits == size<1>(SrcLayout{}),
                  "Source tensor size does not match copy atom size.");
    static_assert(size(DLayout{}) * DBits == size<1>(DstLayout{}),
                  "Destination tensor size does not match copy atom size.");

    traits.template update_payload<DBits>(src.data().coord_);
    Op::copy(traits.payload, recast_ptr<int_byte_t<bits_to_bytes(Super::ValBits)>>(&*dst.data()));
  }
};


// Split a subgroup-level layout into a TV-layout.
template <typename InLayout, int CopyBits, int ValBits, int Threads>
struct XeInterleavedLayoutHelper {
  // Underlying SIMD vector type's element width:
  static constexpr int VecTypeBits = cute::max(ValBits, 8);

  // Expand from CopyBits to VecTypeBits in x dimension:
  using Expanded = decltype(logical_product(Layout<Shape<Int<CopyBits/VecTypeBits>>>{}, InLayout{}));  // V' -> (x', y)

  // Split elements between work-items, interleaving:
  using TVLayout = decltype(composition(Expanded{}, make_layout(make_shape(Int<Threads>{}, Int<size(Expanded{})/Threads>{}))));

  // Expand from elements to bits:
  using PreResult = decltype(blocked_product(Layout<Shape<_1, Int<VecTypeBits>>>{}, TVLayout{}));

  // Simplify for nicer-looking layouts:
  using Result = decltype(coalesce(PreResult{}, Step<_1, _1>{}));

  // Examples:

  // U16 32x16 nontranspose -> U4/U8
  //  In:  (_32, _16):(_1, _32)                                           V -> (x,y)
  // Exp:  (_2, _32, _16):(_1, _2, _64)                                Vbit -> (xbit,y)
  //   Compose with (_16, _64):(_1, _16)
  //  TV:  (_16, _64):(_1, _16)
  // Res:  (_16, (_8, _64)):(_8, (_1, _128))

  // U32 8x16 transpose -> U16 (16x16)  LD_T
  //  In:  (_16, _8):(_8, _1)                                             V -> (x,y)
  // Exp:  (_2, _16, _8):(_1, _16, _2)                                  V16 -> (x16,y)
  //    Compose with (_16, _16):(_1, _16)
  //  TV:  ((_2, _8), (_2, _8)):((_1, _16), (_128, _2))               (T,V) -> (x16,y)
  // Res:  ((_2, _8), (_16, _2, _8)):((_16, _256), (_1, _2048, _32))  (T,V) -> (xbit,y)
};

template <typename Layout, int CopyBits, int ValBits, int Threads = intel::sg_size>
using XeInterleavedLayout = typename XeInterleavedLayoutHelper<Layout, CopyBits, ValBits, Threads>::Result;

// Block 2D load traits.
template <class XMode, class YMode, typename ValType, typename TiledStrides,
          int CopyBits, int Height, int Width, int BlockWidth>
struct Copy_Traits<XE_LOAD_2D<CopyBits, Height, Width, BlockWidth>, XMode, YMode, ValType, TiledStrides>
    : Xe2DLoadTraitsBase<XE_LOAD_2D<CopyBits, Height, Width, BlockWidth>, XMode, YMode, ValType, TiledStrides>
{
  using Super = Xe2DLoadTraitsBase<XE_LOAD_2D<CopyBits, Height, Width, BlockWidth>, XMode, YMode, ValType, TiledStrides>;
  using Super::Super;

  // (dst-thr, dst-val) -> (x, y)
  using DstLayout = XeInterleavedLayout<Layout<Shape<Int<BlockWidth>, Int<Height>, Int<Width/BlockWidth>>,
                                               Stride<_1, Int<Width>, Int<BlockWidth>>>,
                                        CopyBits,
                                        sizeof_bits_v<ValType>>;

  using RefLayout = DstLayout;
  using SrcLayout = decltype(replace<0>(RefLayout{}, Layout<Shape<intel::_SGSize>, Stride<_0>>{}));
};

// Block 2D VNNI load traits.
template <class XMode, class YMode, typename ValType, typename TiledStrides,
          int CopyBits, int Height, int Width, int BlockWidth>
struct Copy_Traits<XE_LOAD_2D_VNNI<CopyBits, Height, Width, BlockWidth>, XMode, YMode, ValType, TiledStrides>
    : Xe2DLoadTraitsBase<XE_LOAD_2D_VNNI<CopyBits, Height, Width, BlockWidth>, XMode, YMode, ValType, TiledStrides>
{
  using Super = Xe2DLoadTraitsBase<XE_LOAD_2D_VNNI<CopyBits, Height, Width, BlockWidth>, XMode, YMode, ValType, TiledStrides>;
  using Super::Super;

  static constexpr int BV = 32 / CopyBits;

  // (dst-thr, dst-val) -> (x, y)
  using DstLayout = XeInterleavedLayout<Layout<Shape<Int<BV>, Int<BlockWidth>, Int<Height/BV>, Int<Width/BlockWidth>>,
                                               Stride<Int<Width>, _1, Int<Width*BV>, Int<BlockWidth>>>,
                                        CopyBits,
                                        sizeof_bits_v<ValType>>;

  using RefLayout = DstLayout;
  using SrcLayout = decltype(replace<0>(RefLayout{}, Layout<Shape<intel::_SGSize>, Stride<_0>>{}));
};

// Block 2D transposed load traits.
template <class XMode, class YMode, typename ValType, typename TiledStrides,
          int CopyBits, int Height, int Width>
struct Copy_Traits<XE_LOAD_2D_TRANSPOSE<CopyBits, Height, Width>, XMode, YMode, ValType, TiledStrides>
    : Xe2DLoadTraitsBase<XE_LOAD_2D_TRANSPOSE<CopyBits, Height, Width>, XMode, YMode, ValType, TiledStrides>
{
  using Super = Xe2DLoadTraitsBase<XE_LOAD_2D_TRANSPOSE<CopyBits, Height, Width>, XMode, YMode, ValType, TiledStrides>;
  using Super::Super;

  // (dst-thr, dst-val) -> (x, y)
  using DstLayout = XeInterleavedLayout<Layout<Shape<Int<Height>, Int<Width>>,
                                               Stride<Int<Width>, _1>>,
                                        CopyBits,
                                        sizeof_bits_v<ValType>>;

  using RefLayout = DstLayout;
  using SrcLayout = decltype(replace<0>(RefLayout{}, Layout<Shape<intel::_SGSize>, Stride<_0>>{}));
};

// Block 2D store traits.
template <class XMode, class YMode, typename ValType, typename TiledStrides,
          int CopyBits, int Height, int Width>
struct Copy_Traits<XE_STORE_2D<CopyBits, Height, Width>, XMode, YMode, ValType, TiledStrides>
    : Xe2DTraitsBase<XE_STORE_2D<CopyBits, Height, Width>, XMode, YMode, ValType, TiledStrides>
{
  // (src-thr, src-val) -> (x, y)
  using SrcLayout = XeInterleavedLayout<Layout<Shape<Int<Width>, Int<Height>>>,
                                        CopyBits,
                                        sizeof_bits_v<ValType>>;

  using RefLayout = SrcLayout;
  using DstLayout = decltype(replace<0>(RefLayout{}, Layout<Shape<intel::_SGSize>, Stride<_0>>{}));

  using Op = XE_STORE_2D<CopyBits, Height, Width>;
  using Super = Xe2DTraitsBase<Op, XMode, YMode, ValType, TiledStrides>;
  using Traits = typename Super::Traits;  // a.k.a. this class
  using ThrID = typename Super::ThrID;

  using Super::Super;

  // Execution.
  template <class SEngine, class SLayout,
            class DEngine, class DLayout>
  CUTE_DEVICE friend constexpr void
  copy_unpack(Traits const&                   traits,
              Tensor<SEngine, SLayout> const& src,
              Tensor<DEngine, DLayout> &      dst) {
    using SType = typename SEngine::value_type;
    using DType = typename DEngine::value_type;
    using SrcLayout = typename Traits::SrcLayout;
    using DstLayout = typename Traits::DstLayout;
    constexpr auto SBits = sizeof_bits_v<SType>;

    static_assert(is_counting_layout_v<DLayout>, "Destination tensor must be a coordinate tensor.");
    static_assert(is_rmem_v<SEngine>, "Source tensor must be in registers.");
    static_assert(size(SLayout{}) * SBits == size<1>(SrcLayout{}),
                  "Source tensor size does not match copy atom size.");
    static_assert(size(DLayout{}) * SBits == size<1>(DstLayout{}),
                  "Destination tensor size does not match copy atom size.");

    traits.template update_payload<SBits>(dst.data().coord_);
    Op::copy(traits.payload, recast_ptr<int_byte_t<bits_to_bytes(Super::ValBits)>>(&*src.data()));
  }
};

// Block 2D prefetch traits.
//
// Note prefetch does not use/need block width; it is present for template arg compatibility
//  between loads and their prefetches.
template <class XMode, class YMode, typename ValType, typename TiledStrides,
          int CopyBits, int Height, int Width, int BlockWidth>
struct Copy_Traits<XE_PREFETCH_2D<CopyBits, Height, Width, BlockWidth>, XMode, YMode, ValType, TiledStrides>
    : Xe2DTraitsBase<XE_PREFETCH_2D<CopyBits, Height, Width, BlockWidth>, XMode, YMode, ValType, TiledStrides>
{
  // (dst-thr, dst-val) -> (x, y)
  using DstLayout = XeInterleavedLayout<Layout<Shape<Int<Width>, Int<Height>>>,
                                        CopyBits,
                                        sizeof_bits_v<ValType>>;

  using RefLayout = DstLayout;
  using SrcLayout = decltype(replace<0>(RefLayout{}, Layout<Shape<intel::_SGSize>, Stride<_0>>{}));

  using Op = XE_PREFETCH_2D<CopyBits, Height, Width, BlockWidth>;
  using Super = Xe2DTraitsBase<Op, XMode, YMode, ValType, TiledStrides>;
  using Traits = typename Super::Traits;  // a.k.a. this class
  using ThrID = typename Super::ThrID;

  using Super::Super;

  // Execution.
  template <class SEngine, class SLayout,
            class DEngine, class DLayout>
  CUTE_DEVICE friend constexpr void
  copy_unpack(Traits const&                   traits,
              Tensor<SEngine, SLayout> const& src,
              Tensor<DEngine, DLayout> &      dst) {
    using SType = typename SEngine::value_type;
    using SrcLayout = typename Traits::SrcLayout;

    static_assert(is_counting_layout_v<SLayout>, "Source tensor must be a coordinate tensor.");
    static_assert(size(SLayout{}) * Super::ValBits == size<1>(SrcLayout{}),
                  "Source tensor size does not match copy atom size.");

    traits.template update_payload<Super::ValBits>(src.data().coord_);
    Op::copy(traits.payload);
  }
};

// Helpers for creating a tiling of block 2D copy atoms for a given global memory tensor.
//
// The x/y modes are deduced according to the rules:
//   x: innermost constant-stride-1 mode
//   y: innermost dynamic-stride mode, or innermost non-1 stride if there are no dynamic strides.
template <class CopyOp,
          class Engine, class Layout>
CUTE_HOST_DEVICE
auto
make_block_2d_copy(const CopyOp& op, const Tensor<Engine, Layout>& gmem) {
  return make_block_2d_copy<typename Engine::value_type>(op, gmem.stride()).with(gmem);
}

template <class OptionalValType = void, class CopyOp, class... Strides>
CUTE_HOST_DEVICE
auto
make_block_2d_copy(const CopyOp& op, const Stride<Strides...>&)
{
  // Configure traits for this atom, identifying x and y modes.
  using ValType = std::conditional_t<std::is_void_v<OptionalValType>,
                                     int_bit_t<CopyOp::CopyBits>,
                                     OptionalValType>;

  Stride<Strides...> strides{};
  return make_block_2d_copy<ValType>(op, strides, find_x_mode(strides), find_y_mode(strides));
}

template <class ValType, class CopyOp, class... Strides, class XMode, class YMode>
CUTE_HOST_DEVICE
auto
make_block_2d_copy(const CopyOp& op, const Stride<Strides...>&, const XMode&, const YMode&)
{
  static constexpr auto ValBits = sizeof_bits_v<ValType>;

  Stride<Strides...> strides{};
  XMode x_mode{};
  YMode y_mode{};

  using TiledStrides = decltype(replace<x_mode()>(replace<y_mode()>(strides, _0{}), _0{}));

  using Traits = Copy_Traits<CopyOp, XMode, YMode, ValType, TiledStrides>;
  using Atom = Copy_Atom<Traits, ValType>;

  // Create tiler for the TiledCopy.
  constexpr auto tile_1 = tuple_repeat<rank(strides)>(_1{});
  constexpr auto Width = CopyOp::AtomWidth * CopyOp::CopyBits / ValBits;
  constexpr auto Height = CopyOp::AtomHeight;
  using ShapeTiler_MN = decltype(replace<x_mode()>(replace<y_mode()>(tile_1, Int<Height>{}), Int<Width>{}));

  // Create proper TV-layout for the TiledCopy, using the copy atom's reference layout.
  //
  // ValLayoutRef for all block 2D atoms is (T,V)->(X,Y).
  // If the x/y ordering in ValLayoutRef matches the order of XMode/YMode in the given strides, then
  //    the TiledCopy's TV-layout is just ValLayoutRef. Otherwise, we need to transpose x/y in the RefLayout.
  constexpr bool transpose_tv = (y_mode < x_mode);
  using MaybeTranspose = Layout<Shape<Int<Width>, Int<Height>>,
                                Stride<Int<transpose_tv ? Height : 1>,
                                       Int<transpose_tv ? 1 : Width>>>;
  using LayoutCopy_TV = decltype(composition(MaybeTranspose{}, typename Atom::ValLayoutRef{}));

  return TiledCopy<Atom, LayoutCopy_TV, ShapeTiler_MN>{};
}

// Low-level routine for creating a block 2D TiledCopy for multiple subgroups.
// In addition to the usual parameters, it takes:
//   - atom_shape = "subgroup shape" (# of copy blocks in each dimension)
//   - sv_layout = "subgroup-value layout" (ordering for subgroups in the tiling)
template <class ValType,
          class CopyOp, class... Strides,
          class XMode, class YMode,
          class SGShape, class SVLayout>
CUTE_HOST_DEVICE
auto
make_block_2d_copy(const CopyOp& op,
                   const Stride<Strides...>& strides,
                   const XMode& x_mode, const YMode& y_mode,
                   const SGShape& atom_shape,             // (SG_M, SG_N, ...)
                   const SVLayout& sv_layout)             // (SG #, SG value) -> (SG_M, SG_N, ...)
{
  // Create TiledCopy for a single subgroup.
  using SGCopy = decltype(make_block_2d_copy<ValType>(op, strides, x_mode, y_mode));
  using Atom          = typename SGCopy::Atom;
  using ShapeTiler_MN = typename SGCopy::Tiler_MN;
  using LayoutCopy_TV = typename SGCopy::TiledLayout_TV;

  // Expand the shape.
  auto x_shape = elem_scale(ShapeTiler_MN{}, atom_shape);

  // Expand the single-SG TV layout to the full shape, then tile.
  auto x_tv_layout1 = composition(make_layout(ShapeTiler_MN{}, make_layout(x_shape).stride()), LayoutCopy_TV{});
  auto x_tv_layout = blocked_product(x_tv_layout1, sv_layout);

  return TiledCopy<Atom, decltype(x_tv_layout), decltype(x_shape)>{};
}


template <class... Strides>
CUTE_HOST_DEVICE
constexpr auto
find_x_mode(const Stride<Strides...> &) {
  Stride<Strides...> strides{};
  return find_if(strides, [](auto const &x) { return C<is_constant_v<1, decltype(x)>>{}; });
}

template <class... Strides>
CUTE_HOST_DEVICE
constexpr auto
find_y_mode(const Stride<Strides...>&) {
  Stride<Strides...> strides{};
  constexpr auto YModeDyn = find_if(strides, [](auto const &x) { return C<std::is_integral_v<decltype(x)>>{}; });
  if constexpr (YModeDyn < rank(strides))
    return YModeDyn;
  else
    return find_if(strides, [](auto const &x) { return C<!is_constant_v<1, decltype(x)>>{}; });
}

// Copy selection and creation.

template <int I, int min_scale, class T>
struct find_first_basis_mode_pred { using type = C<false>; };

template <int I, int min_scale, int S>
struct find_first_basis_mode_pred<I, min_scale, ScaledBasis<C<S>, I>> {
    using type = C<(S >= min_scale)>;
};

template <int N, int min_size, class InLayout>
CUTE_HOST_DEVICE
constexpr auto
find_first_basis_mode(InLayout const&) {
  return find_if(InLayout{}.stride(), [](auto const &x) {
    using XType = remove_cvref_t<decltype(x)>;
    return typename find_first_basis_mode_pred<N, min_size, XType>::type{};
  });
}

// Find the first block size (stride) in dimension N of size at least min_size.
// FIXME: should look through all matching strides and pick the smallest.
template <int N, int min_size = 2, class InLayout>
CUTE_HOST_DEVICE
constexpr auto
get_block_size(InLayout const&) {
  InLayout layout{};
  constexpr auto block_mode = find_first_basis_mode<N, min_size>(layout);
  if constexpr (block_mode < rank(layout))
    return basis_value(stride<block_mode>(layout));
  else
    return get<N>(atuple_coshape(layout));
}

// Remove subbyte packing modes from a layout, if present.
template <int Bits, class InLayout>
CUTE_HOST_DEVICE
constexpr auto
strip_subbyte(InLayout const& layout)
{
  using namespace cute::intel;
  if constexpr (Bits >= 8)
    return layout;
  else {
    static_assert(is_static_v<InLayout>, "Layout must be static");
    constexpr auto values = size(InLayout{}) / sg_size;
    constexpr auto per_byte = 8 / Bits;
    static_assert(values % per_byte == 0, "Partially-occupied bytes in layout");
    return coalesce(composition(layout, Layout<Shape<C<per_byte>, _SGSize, C<values/per_byte>>,
                                               Stride<_SGSize,         _1, C<sg_size*per_byte>>>{}));
  }
}

// Remove VNNI and subbyte packing modes from a layout, if present.
// Returns a std::pair<Layout, bool> = (layout_out, has_vnni)
template <int Bits, class InLayout>
CUTE_HOST_DEVICE
constexpr auto
strip_vnni_subbyte(InLayout const&)
{
  constexpr auto layout = strip_subbyte<Bits>(InLayout{});
  constexpr int R = rank(layout);
  constexpr bool vnni = (R >= 2)
                     && (Bits < 32)
                     && is_constant_v<32 / Bits, decltype(size<0>(layout))>;

  if constexpr (vnni) {
    // Coalesce VNNI mode with next mode in that dimension, if any,
    //   or else move it to the end of the layout.
    constexpr auto vmode = get<0>(layout);
    constexpr auto vdim = stride<0>(layout).mode();
    constexpr auto slayout = take<1,R>(layout);
    constexpr auto next_vmode = find_first_basis_mode<vdim, 0>(slayout);
    if constexpr (next_vmode < R - 1)
      return std::make_pair(replace<next_vmode>(slayout, coalesce(make_layout(vmode, get<next_vmode>(slayout)))), true);
    else
      return std::make_pair(append(layout,vmode), true);
  } else
    return std::make_pair(layout, false);
}

enum class Block2DTransform {N, T, V};

template <int MemBits, int RegBits, bool Store = false,
          class DesiredCoordLayout, class GlobalStride>
CUTE_HOST_DEVICE
constexpr Block2DTransform
block_2d_transform_selector(DesiredCoordLayout const& layout,
                            GlobalStride       const& gstride)
{
  // Stores are always non-transpose.
  if constexpr (Store)
      return Block2DTransform::N;

  // Check if copy's consumer wants VNNI layout.
  constexpr auto result = strip_vnni_subbyte<RegBits>(DesiredCoordLayout{});
  constexpr auto slayout = get<0>(result);
  constexpr bool vnni = get<1>(result);
  constexpr bool transpose = !is_constant_v<1, decltype(basis_get(stride<0>(slayout), gstride))>;

  // If VNNI needed, use VNNI load for 8/16-bit types in memory, otherwise regular.
  if constexpr (vnni && !transpose)
      return (MemBits == 8 || MemBits == 16) ? Block2DTransform::V : Block2DTransform::N;

  // Otherwise, use transpose load if significant transposition required.
  if constexpr (transpose && decltype(size<0>(slayout))::value * MemBits >= 16)
      return Block2DTransform::T;
  else
      return Block2DTransform::N;
}

// Heuristically select a block 2D copy operation.
//      MemType: type of data in memory
//      RegType: type of data in registers, as associated with CoordLayout
//        Store: true for stores, false for loads (default)
//  CoordLayout: desired subgroup coordinate layout in registers
//                 (Note: a reorder may be required to achieve data in this layout)
// GlobalStride: strides of data in memory
template <typename MemType, typename RegType, bool Store = false,
          typename CoordLayout, typename GlobalStride>
CUTE_HOST_DEVICE
constexpr auto
block_2d_selector(CoordLayout const&, GlobalStride const&)
{
  static_assert(is_static_v<CoordLayout>, "Coordinate layout must be static");

  auto layout = coalesce(CoordLayout{});
  GlobalStride gstride{};

  // Determine size of copy.
  constexpr int MemBits = sizeof_bits_v<MemType>;
  constexpr int RegBits = sizeof_bits_v<RegType>;

  // Determine which kind of block 2D message to use (regular/VNNI/transpose)
  constexpr auto kind = block_2d_transform_selector<MemBits, RegBits, Store>(layout, gstride);

  // Strip off VNNI mode if present.
  constexpr auto slayout = get<0>(strip_vnni_subbyte<RegBits>(layout));

  constexpr auto x_mode = find_x_mode(gstride);
  constexpr auto y_mode = find_y_mode(gstride);

  constexpr int min_large_block = cute::min(256 / RegBits, 16);
  constexpr bool resize = (MemBits != RegBits);

  auto shape = atuple_coshape(layout);

  if constexpr (kind != Block2DTransform::T) {
    constexpr int CopyBits = cute::max(8, cute::min(64, MemBits));

    // Determine block width.
    // Get innermost stride in x dimension that is >= 1/2 GRF
    //   Block width = highest power of 2 divisor (up to 64b)
    //   Width = highest power of 2 divisor of full tile's width, up to 64b and 4x block width
    constexpr int max_w = 64 * 8 / MemBits;
    constexpr int x_stride = get_block_size<x_mode(), min_large_block>(slayout);
    constexpr int block_width = cute::gcd(max_w, x_stride);
    constexpr int load_width = cute::gcd(cute::min(max_w, 4 * block_width),
                                          get<x_mode()>(shape));
    constexpr int width = Store ? block_width : load_width;
    constexpr int block_cwidth = block_width * MemBits / CopyBits;
    constexpr int cwidth = width * MemBits / CopyBits;

    // Determine block height.
    // Get innermost stride in H dimension, besides VNNI stride if VNNI.
    // However, if data resizing will occur, choose full tile height, up to block height limit.
    //   (Rationale: we are already moving data, so layouts don't need to match)
    constexpr int y_stride = get_block_size<y_mode()>(slayout);
    constexpr int max_h = Store ? 8 : 32;
    constexpr int height = cute::gcd(resize ? get<y_mode()>(shape) : y_stride, max_h);

    if constexpr (Store)
      return XE_STORE_2D    <CopyBits, height, cwidth>{};
    else if constexpr (kind == Block2DTransform::V)
      return XE_LOAD_2D_VNNI<CopyBits, height, cwidth, block_cwidth>{};
    else
      return XE_LOAD_2D     <CopyBits, height, cwidth, block_cwidth>{};
  } else {
    // Similar process for transposing copies, but with width/height reversed.
    constexpr int CopyBits = cute::max(32, cute::min(64, MemBits));

    constexpr int y_stride = get_block_size<y_mode(), min_large_block>(slayout);
    constexpr int height = cute::gcd(32, y_stride);

    constexpr int max_w = 32 * 8 / MemBits;
    constexpr int x_stride = get_block_size<x_mode()>(slayout);
    constexpr int width = cute::gcd(resize ? get<x_mode()>(shape) : x_stride, max_w);
    constexpr int cwidth = width * MemBits / CopyBits;

    return XE_LOAD_2D_TRANSPOSE<CopyBits, height, cwidth>{};
  }
}

// Helper for make_block_2d_copy_* routines
template <class ValType, class TiledMMA, class CopyOp, class... Strides,
          class XMode, class YMode, class MMAShape, class SVLayout>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_X(CopyOp             const& op,          // Copy operation
                     TiledMMA           const& mma,         // TiledMMA instance
                     Stride<Strides...> const& gstride,     // Global memory strides
                     XMode              const& x_mode,      // x, y modes
                     YMode              const& y_mode,
                     MMAShape           const& mma_shape,   // Coordinate space
                     SVLayout           const& sv_layout)   // (SG,V) -> coord
{
  // Divide coordinate codomain into copy tiles.
  constexpr int Width = CopyOp::AtomWidth * CopyOp::CopyBits / sizeof_bits_v<ValType>;
  constexpr int Height = CopyOp::AtomHeight;
  auto op_tile = Int<Width>{}  * E<XMode::value>{}
               + Int<Height>{} * E<YMode::value>{};
  auto atom_shape = shape_div(mma_shape, op_tile);

  auto divide_by_op_tile = zip(make_layout(op_tile, make_stride(_0{}, _0{})),
                               make_layout(atom_shape));                        // (M,K) -> (M tile, K tile)

  auto sv_layout_t0 = composition(divide_by_op_tile, sv_layout);                // (SG,V) -> (M tile, K tile)

  // Filter out value modes that are internal to copy tiles.
  auto sv_layout_t = make_layout(get<0>(sv_layout_t0),
                                 filter(get<1>(sv_layout_t0)));                // (SG,V') -> (M tile, K tile)

  // Tile copy operation.
  return make_block_2d_copy<ValType>(op, gstride, x_mode, y_mode, atom_shape, sv_layout_t);
}

// MMA-focused TiledCopy creation functions.
template <class TiledMMA, class GEngine, class GLayout>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_A(TiledMMA                 const& mma,   // TiledMMA instance
                     Tensor<GEngine, GLayout> const& gmem)  // Global tensor
{
  using ValType = typename GEngine::value_type;
  return make_block_2d_copy_A<ValType>(mma, gmem.stride()).with(gmem);
}

template <class TiledMMA, class CopyOp, class GEngine, class GLayout>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_A(CopyOp                   const& op,    // Copy operation
                     TiledMMA                 const& mma,   // TiledMMA instance
                     Tensor<GEngine, GLayout> const& gmem)  // Global tensor
{
  using ValType = typename GEngine::value_type;
  return make_block_2d_copy_A<ValType>(op, mma, gmem.stride()).with(gmem);
}

template <class ValType, class TiledMMA, class... Strides>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_A(TiledMMA           const& mma,         // TiledMMA instance
                     Stride<Strides...> const& gstride)     // Global memory strides
{
  using MMAType = typename TiledMMA::ValTypeA;
  auto cA = make_identity_tensor(select<0,2>(mma.tile_mnk()));
  auto op = block_2d_selector<ValType, MMAType>(mma.get_slice(0).atom_partition_A(cA).layout(), gstride);
  return make_block_2d_copy_A<ValType>(op, mma, gstride);
}

template <class ValType, class TiledMMA, class CopyOp, class... Strides>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_A(CopyOp             const& op,          // Copy operation
                     TiledMMA           const& mma,         // TiledMMA instance
                     Stride<Strides...> const& gstride)     // Global memory strides
{
  return make_block_2d_copy_A<ValType>(op, mma, gstride, find_x_mode(gstride), find_y_mode(gstride));
}

template <class ValType, class TiledMMA, class CopyOp, class... Strides, class XMode, class YMode>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_A(CopyOp             const& op,          // Copy operation
                     TiledMMA           const& mma,         // TiledMMA instance
                     Stride<Strides...> const& gstride,     // Global memory strides
                     XMode              const& x_mode,      // x, y modes
                     YMode              const& y_mode)
{
  // Retrieve MMA atom's (subgroup, value) -> (M,K) layout
  auto tile_mk = select<0,2>(mma.tile_mnk());

  auto thr_vmnk = mma.get_thr_layout_vmnk();                                        // (ThrV,ThrM,ThrN,ThrK) -> thr
  auto shape_vmnk = shape(thr_vmnk);                                                // (ThrV,ThrM,ThrN,ThrK)
  auto drop_n = make_layout(shape_vmnk,
      make_stride(_1{}, get<0>(shape_vmnk), _0{},
                  get<0>(shape_vmnk) * get<1>(shape_vmnk)));                        // (ThrV,ThrM,ThrN,ThrK) -> (ThrV,ThrM,ThrK)

  auto thr_to_vmk = composition(drop_n, right_inverse(thr_vmnk));                   // thr -> (ThrV,ThrM,ThrK)
  auto sg_to_vmk = composition(thr_to_vmk,
      make_layout(product(take<1,4>(shape_vmnk)), get<0>(shape_vmnk)));             // SG -> (0,ThrM,ThrK)

  auto svA = composition(mma.thrfrg_A(make_layout(tile_mk)),
                         make_tile(sg_to_vmk, _));                                  // (SG,V) -> (M,K)

  // Derive copy tile layout and create TiledCopy
  return make_block_2d_copy_X<ValType>(op, mma, gstride, x_mode, y_mode, tile_mk, svA);
}

template <class TiledMMA, class GEngine, class GLayout>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_B(TiledMMA                 const& mma,   // TiledMMA instance
                     Tensor<GEngine, GLayout> const& gmem)  // Global tensor
{
  using ValType = typename GEngine::value_type;
  return make_block_2d_copy_B<ValType>(mma, gmem.stride()).with(gmem);
}

template <class TiledMMA, class CopyOp, class GEngine, class GLayout>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_B(CopyOp                   const& op,    // Copy operation
                     TiledMMA                 const& mma,   // TiledMMA instance
                     Tensor<GEngine, GLayout> const& gmem)  // Global tensor
{
  using ValType = typename GEngine::value_type;
  return make_block_2d_copy_B<ValType>(op, mma, gmem.stride()).with(gmem);
}

template <class ValType, class TiledMMA, class... Strides>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_B(TiledMMA           const& mma,         // TiledMMA instance
                     Stride<Strides...> const& gstride)     // Global memory strides
{
  using MMAType = typename TiledMMA::ValTypeB;
  auto cB = make_identity_tensor(select<1,2>(mma.tile_mnk()));
  auto op = block_2d_selector<ValType, MMAType>(mma.get_slice(0).atom_partition_B(cB).layout(), gstride);
  return make_block_2d_copy_B<ValType>(op, mma, gstride);
}

template <class ValType, class TiledMMA, class CopyOp, class... Strides>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_B(CopyOp             const& op,          // Copy operation
                     TiledMMA           const& mma,         // TiledMMA instance
                     Stride<Strides...> const& gstride)     // Global memory strides
{
  return make_block_2d_copy_B<ValType>(op, mma, gstride, find_x_mode(gstride), find_y_mode(gstride));
}

template <class ValType, class TiledMMA, class CopyOp, class... Strides, class XMode, class YMode>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_B(CopyOp             const& op,          // Copy operation
                     TiledMMA           const& mma,         // TiledMMA instance
                     Stride<Strides...> const& gstride,     // Global memory strides
                     XMode              const& x_mode,      // x, y modes
                     YMode              const& y_mode)
{
  // Retrieve MMA atom's (subgroup, value) -> (N,K) layout
  auto tile_nk = select<1,2>(mma.tile_mnk());

  auto thr_vmnk = mma.get_thr_layout_vmnk();                                        // (ThrV,ThrM,ThrN,ThrK) -> thr
  auto shape_vmnk = shape(thr_vmnk);                                                // (ThrV,ThrM,ThrN,ThrK)
  auto drop_m = make_layout(shape_vmnk,
      make_stride(_1{}, _0{}, get<0>(shape_vmnk), _0{},
                  get<0>(shape_vmnk) * get<2>(shape_vmnk)));                        // (ThrV,ThrM,ThrN,ThrK) -> (ThrV,ThrN,ThrK)

  auto thr_to_vnk = composition(drop_m, right_inverse(thr_vmnk));                   // thr -> (ThrV,ThrN,ThrK)
  auto sg_to_vnk = composition(thr_to_vnk,
      make_layout(product(take<1,4>(shape_vmnk)), get<0>(shape_vmnk)));             // SG -> (0,ThrN,ThrK)

  auto svB = composition(mma.thrfrg_B(make_layout(tile_nk)),
                         make_tile(sg_to_vnk, _));                                  // (SG,V) -> (N,K)

  // Derive copy tile layout and create TiledCopy
  return make_block_2d_copy_X<ValType>(op, mma, gstride, x_mode, y_mode, tile_nk, svB);
}

template <class TiledMMA, class GEngine, class GLayout>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_C(TiledMMA                 const& mma,   // TiledMMA instance
                     Tensor<GEngine, GLayout> const& gmem)  // Global tensor
{
  using ValType = typename GEngine::value_type;
  return make_block_2d_copy_C<ValType>(mma, gmem.stride()).with(gmem);
}

template <class TiledMMA, class CopyOp, class GEngine, class GLayout>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_C(CopyOp                   const& op,    // Copy operation
                     TiledMMA                 const& mma,   // TiledMMA instance
                     Tensor<GEngine, GLayout> const& gmem)  // Global tensor
{
  using ValType = typename GEngine::value_type;
  return make_block_2d_copy_C<ValType>(op, mma, gmem.stride()).with(gmem);
}

template <class ValType, class TiledMMA, class... Strides>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_C(TiledMMA           const& mma,         // TiledMMA instance
                     Stride<Strides...> const& gstride)     // Global memory strides
{
  using MMAType = typename TiledMMA::ValTypeA;
  auto cC = make_identity_tensor(select<0,1>(mma.tile_mnk()));
  auto op = block_2d_selector<ValType, MMAType, true>(
    mma.get_slice(0).atom_partition_C(cC).layout(), gstride
  );
  return make_block_2d_copy_C<ValType>(op, mma, gstride);
}

template <class ValType, class TiledMMA, class CopyOp, class... Strides>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_C(CopyOp             const& op,          // Copy operation
                     TiledMMA           const& mma,         // TiledMMA instance
                     Stride<Strides...> const& gstride)     // Global memory strides
{
  return make_block_2d_copy_C<ValType>(op, mma, gstride, find_x_mode(gstride), find_y_mode(gstride));
}

template <class ValType, class TiledMMA, class CopyOp, class... Strides, class XMode, class YMode>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_C(CopyOp             const& op,          // Copy operation
                     TiledMMA           const& mma,         // TiledMMA instance
                     Stride<Strides...> const& gstride,     // Global memory strides
                     XMode              const& x_mode,      // x, y modes
                     YMode              const& y_mode)
{
  // Retrieve MMA atom's (subgroup, value) -> (M,N) layout
  auto tile_mn = select<0,1>(mma.tile_mnk());

  auto thr_vmnk = mma.get_thr_layout_vmnk();                                        // (ThrV,ThrM,ThrN,ThrK) -> thr
  auto shape_vmnk = shape(thr_vmnk);                                                // (ThrV,ThrM,ThrN,ThrK)
  auto drop_k = replace<3>(make_layout(shape_vmnk),
                           make_layout(get<3>(shape_vmnk), _0{}));                  // (ThrV,ThrM,ThrN,ThrK) -> (ThrV,ThrM,ThrN)

  auto thr_to_vmn = composition(drop_k, right_inverse(thr_vmnk));                   // thr -> (ThrV,ThrM,ThrN)
  auto sg_to_vmn = composition(thr_to_vmn,
      make_layout(product(take<1,4>(shape_vmnk)), get<0>(shape_vmnk)));             // SG -> (0,ThrM,ThrN)

  auto svC = composition(mma.thrfrg_C(make_layout(tile_mn)),
                         make_tile(sg_to_vmn, _));                                  // (SG,V) -> (M,N)

  // Derive copy tile layout and create TiledCopy
  return make_block_2d_copy_X<ValType>(op, mma, gstride, x_mode, y_mode, tile_mn, svC);
}

// Prefetch selection and creation.
namespace detail {
  template <class Op, class XMode, class YMode, typename ValType, typename TiledStrides>
  CUTE_HOST_DEVICE decltype(auto)
  as_block_2d_traits(Xe2DTraitsBase<Op, XMode, YMode, ValType, TiledStrides> const &o) {
    return o;
  }
};

template <class Copy_Atom, class LayoutCopy_TV, class ShapeTiler_MN>
CUTE_HOST_DEVICE
auto
make_block_2d_prefetch(TiledCopy<Copy_Atom, LayoutCopy_TV, ShapeTiler_MN> const& tiled_copy)
{
  using TCopy = TiledCopy<Copy_Atom, LayoutCopy_TV, ShapeTiler_MN>;

  constexpr auto sg_count = typename TCopy::TiledNumThr{} / typename TCopy::AtomNumThr{};
  auto &traits = detail::as_block_2d_traits(tiled_copy);

  return make_block_2d_prefetch<typename Copy_Atom::ValType, sg_count()>(
    ShapeTiler_MN{}, traits.tiled_strides, traits.get_x_mode(), traits.get_y_mode()
  ).with(traits);
}

template <int SGCount, class Shape, class Engine, class Layout>
CUTE_HOST_DEVICE
auto
make_block_2d_prefetch(const Shape& shape, Tensor<Engine, Layout> const& gmem)
{
  using ValType = typename Engine::value_type;
  return make_block_2d_prefetch<ValType, SGCount>(shape, gmem.stride()).with(gmem);
}

template <typename ValType, int SGCount, class Shape, class... Strides>
CUTE_HOST_DEVICE
auto
make_block_2d_prefetch(const Shape& shape, Stride<Strides...> const& stride)
{
  return make_block_2d_prefetch<ValType, SGCount>(shape, stride, find_x_mode(stride), find_y_mode(stride));
}

template <typename ValType, int SGCount, class Shape, class... Strides, class XMode, class YMode>
CUTE_HOST_DEVICE
auto
make_block_2d_prefetch(const Shape&, Stride<Strides...> const& stride, const XMode& x_mode, const YMode& y_mode)
{
  constexpr auto shape_x = get<XMode::value>(Shape{});
  constexpr auto shape_y = get<YMode::value>(Shape{});

  // Try to retrieve whole cache lines (contiguous dimension = x)
  constexpr auto width = cute::min(shape_x, 512 / sizeof_bits_v<ValType>);

  // Do a preliminary tiling to choose appropriate height.
  constexpr int n_sg_x = cute::gcd(SGCount, ceil_div(shape_x, width));
  constexpr int n_sg_y = SGCount / n_sg_x;

  constexpr auto max_height = 32;
  constexpr auto height = cute::min(max_height, ceil_div(shape_y, n_sg_y));

  // Select op.
  using CopyType = int_byte_t<sizeof(ValType)>;
  using CopyOp = XE_PREFETCH_2D<sizeof_bits_v<CopyType>,
                                height,
                                ceil_div(width * sizeof_bits_v<ValType>, sizeof_bits_v<CopyType>)>;

  return make_block_2d_prefetch<ValType, SGCount>(CopyOp{}, Shape{}, stride, x_mode, y_mode);
}

// Low-level prefetch creation utility.
template <typename ValType, int SGCount,
          class PrefetchOp, class Shape, class... Strides, class XMode, class YMode>
CUTE_HOST_DEVICE
auto
make_block_2d_prefetch(PrefetchOp         const& op,
                       Shape              const& shape,
                       Stride<Strides...> const& stride,
                       XMode              const& x_mode,
                       YMode              const& y_mode)
{
  constexpr auto all_1s = tuple_repeat<rank(Shape{})>(_1{});
  constexpr auto width = PrefetchOp::AtomWidth * PrefetchOp::CopyBits / sizeof_bits_v<ValType>;
  constexpr auto height = PrefetchOp::AtomHeight;

  auto op_tile = replace<XMode::value>(replace<YMode::value>(all_1s, Int<height>{}), Int<width>{});

  // Reduce shape to grid of atoms.
  auto atom_shape = shape_div(shape, op_tile);

  // Replicate op tile across subgroups, traversing the innermost dimension first.
  // Ensure the resulting collective tile goes evenly into the given shape (may not be a power of 2)
  constexpr int n_sg_x = cute::gcd(SGCount, get<XMode::value>(atom_shape));
  constexpr int n_sg_y = SGCount / n_sg_x;

  auto collective_op_tile = replace<XMode::value>(replace<YMode::value>(all_1s,
                                                                        Int<n_sg_y>{}),
                                                  Int<n_sg_x>{});

  // Tile atom grid across collective op tile.
  auto sv_layout = zipped_divide(make_layout(collective_op_tile), atom_shape);

  // Create the TiledCopy object.
  return make_block_2d_copy<ValType>(op, stride, x_mode, y_mode, atom_shape, sv_layout);
}



//
// Display utilities
//
template <class Op, class XMode, class YMode, typename ValType, typename TiledStrides>
CUTE_HOST_DEVICE
void
print_block_2d_traits(Xe2DTraitsBase<Op, XMode, YMode, ValType, TiledStrides> const& traits)
{
  print("  Width:        "); print(Op::AtomWidth);                 print("\n");
  print("  Height:       "); print(Op::AtomHeight);                print("\n");
  print("  CopyType:     "); print(Op::CopyBits);                  print("b\n");
  print("  ValueType:    "); print(sizeof_bits_v<ValType>);        print("b\n");
  print("  XMode:        "); print(XMode{});                       print("\n");
  print("  YMode:        "); print(YMode{});                       print("\n");
  print("  TiledStrides: "); print(traits.tiled_strides);          print("\n");
}

template <typename ValType, class Traits, typename AtomValType>
CUTE_HOST_DEVICE
void
print_block_2d_atom(Copy_Atom<Traits, AtomValType> const& atom)
{
  using Atom = remove_cvref_t<decltype(atom)>;
  print("  ThrID:        "); print(typename Atom::ThrID{});        print("\n");
  print("  ValLayoutSrc: "); print(typename Atom::ValLayoutSrc{}); print("\n");
  print("  ValLayoutDst: "); print(typename Atom::ValLayoutDst{}); print("\n");
  print("  ValLayoutRef: "); print(typename Atom::ValLayoutRef{}); print("\n");
  if constexpr (sizeof_bits_v<ValType> != sizeof_bits_v<AtomValType>) {
    print("  AtomValType:  "); print(sizeof_bits_v<AtomValType>);    print("b\n");
  }
}

template <class XMode, class YMode, typename ValType, typename TiledStrides, typename AtomValType,
          int CopyBits, int Height, int Width, int BlockWidth>
CUTE_HOST_DEVICE
void
print(Copy_Atom<Copy_Traits<XE_LOAD_2D<CopyBits, Height, Width, BlockWidth>,
                XMode, YMode, ValType, TiledStrides>, AtomValType> const& atom)
{
  print("Copy_Atom (XE_LOAD_2D)\n");
  print("  BlockWidth:   "); print(BlockWidth);                    print("\n");
  print_block_2d_traits(atom);
  print("\n");
  print_block_2d_atom<ValType>(atom);
}

template <class XMode, class YMode, typename ValType, typename TiledStrides, typename AtomValType,
          int CopyBits, int Height, int Width, int BlockWidth>
CUTE_HOST_DEVICE
void
print(Copy_Atom<Copy_Traits<XE_LOAD_2D_VNNI<CopyBits, Height, Width, BlockWidth>,
                XMode, YMode, ValType, TiledStrides>, AtomValType> const& atom)
{
  print("Copy_Atom (XE_LOAD_2D_VNNI)\n");
  print("  BlockWidth:   "); print(BlockWidth);                    print("\n");
  print_block_2d_traits(atom);
  print("\n");
  print_block_2d_atom<ValType>(atom);
}

template <class XMode, class YMode, typename ValType, typename TiledStrides, typename AtomValType,
          int CopyBits, int Height, int Width>
CUTE_HOST_DEVICE
void
print(Copy_Atom<Copy_Traits<XE_LOAD_2D_TRANSPOSE<CopyBits, Height, Width>,
                XMode, YMode, ValType, TiledStrides>, AtomValType> const& atom)
{
  print("Copy_Atom (XE_LOAD_2D_TRANSPOSE)\n");
  print_block_2d_traits(atom);
  print("\n");
  print_block_2d_atom<ValType>(atom);
}

template <class XMode, class YMode, typename ValType, typename TiledStrides, typename AtomValType,
          int CopyBits, int Height, int Width>
CUTE_HOST_DEVICE
void
print(Copy_Atom<Copy_Traits<XE_STORE_2D<CopyBits, Height, Width>,
                XMode, YMode, ValType, TiledStrides>, AtomValType> const& atom)
{
  print("Copy_Atom (XE_STORE_2D)\n");
  print_block_2d_traits(atom);
  print("\n");
  print_block_2d_atom<ValType>(atom);
}

template <class XMode, class YMode, typename ValType, typename TiledStrides, typename AtomValType,
          int CopyBits, int Height, int Width>
CUTE_HOST_DEVICE
void
print(Copy_Atom<Copy_Traits<XE_PREFETCH_2D<CopyBits, Height, Width>,
                XMode, YMode, ValType, TiledStrides>, AtomValType> const& atom)
{
  print("Copy_Atom (XE_PREFETCH_2D)\n");
  print_block_2d_traits(atom);
  print("\n");
  print_block_2d_atom<ValType>(atom);
}

} // end namespace cute
