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
#pragma once

#include <cute/atom/copy_atom.hpp>
#include <cute/atom/copy_traits.hpp>

#include <cute/algorithm/prefetch.hpp>
#include <cute/arch/copy_xe.hpp>

namespace cute {

namespace detail {

static constexpr auto subgroup_size = 16;

// ==========  size_of_inst_bits  ==========
template <class T, class dtype, class = void>
static constexpr auto size_of_inst_bits = sizeof_bits_v<dtype>;

template <class T, class dtype>
static constexpr auto size_of_inst_bits<T, dtype, cute::void_t<typename T::inst_dtype>> = sizeof_bits_v<typename T::inst_dtype>;


// ==========  is_transpose_load  ==========
template <class, class = void>
static constexpr bool is_transpose_load = false;

template <class T>
static constexpr bool is_transpose_load<T, cute::void_t<std::bool_constant<T::is_transpose>>> = T::is_transpose;


// ==========  is_stride_leftmost  ==========
template <class T, class = void>
static constexpr bool is_stride_leftmost = std::is_same_v<_1, decltype(get<0>(T{}))>;

template <class T>
static constexpr bool is_stride_leftmost<T, cute::void_t<decltype(T{}.stride())>> = std::is_same_v<_1, decltype(get<0>(T{}.stride()))>;

// Swap the Src or Dst Layout of a Copy_Traits if the logical/memory layouts differ 
template <bool is_convention_MN, typename LayoutIn, typename BlockShape>
auto get_logical_layout(LayoutIn &&, BlockShape &&) {
  static_assert(cute::rank(BlockShape{}) == 2, "Expected 2D BlockShape for XE_2D copy op.");
  static_assert(cute::rank(LayoutIn{}) == 2, "Expected 2D LayoutIn for XE_2D copy op.");
  if constexpr (is_convention_MN) {
    return LayoutIn{};
  } else {
    // (16, (32, 2))
    //        ^-- the size of an element in bits
    static_assert(size(LayoutIn{}) % size(BlockShape{}) == 0);
    constexpr int ElemBitSize = size(LayoutIn{}) / size(BlockShape{});
    // Construct a generic row-major layout of the relevant size
    using RowMajorLayout =
        decltype(make_ordered_layout(Shape<Int<ElemBitSize>, BlockShape>{}, Step<_0, Step<_2, _1>>{}));
    // Compose with LayoutIn to produce the transposed Copy_Traits layout
    return right_inverse(RowMajorLayout{}).compose(LayoutIn{});
  }
}
} // end namespace detail

template<class TileShape, int Num_SGs, int SubgroupSize = detail::subgroup_size, class Tensor>
CUTE_HOST_DEVICE auto prefetch_selector(Tensor const& tensor) {
  constexpr size_t cacheline_bytes = 64;
  using dtype = typename Tensor::value_type;
  constexpr size_t dtype_size_bits = sizeof_bits_v<dtype>;
  constexpr bool is_need_reversed = detail::is_stride_leftmost<decltype(tensor.stride())>;
  using CopyThreadShape = std::conditional_t<is_need_reversed,
                                             Shape<Int<SubgroupSize>, _1>,
                                             Shape<_1, Int<SubgroupSize>>>;

  constexpr int tile_contig_size = is_need_reversed ? size<0>(TileShape{}) : size<1>(TileShape{});
  constexpr int tile_non_contig_size = is_need_reversed ? size<1>(TileShape{}) : size<0>(TileShape{});

  // block here is what is prefetched in one atom execution
  // min(32,32)-> 32 (256, 32) -> 32
  static constexpr auto block_contig_size = cute::min(tile_contig_size, cacheline_bytes / sizeof(dtype));
  // A: 1 -> trans or B 256/32 = 8
  static constexpr auto nums_blocks_contig = ceil_div(tile_contig_size, block_contig_size);
  
  // layout of sub groups
  // A shape<32,1> / trans or B shape<4,8>
  constexpr int sgs_contig = cute::gcd(Num_SGs, nums_blocks_contig);
  constexpr int sgs_non_contig = Num_SGs / sgs_contig;

  constexpr auto block_non_contig_size = tile_non_contig_size / sgs_non_contig;

  using PrefetchTilingLayout = std::conditional_t<is_need_reversed,
           Layout<Shape<Shape<Int<SubgroupSize >, Int<sgs_contig>>, Int<sgs_non_contig>>,
                  Stride<Stride<_1, Int<SubgroupSize >>,            Int<SubgroupSize  * sgs_contig>>>,
    Layout<Shape<Int<sgs_non_contig>, Shape<Int<SubgroupSize >, Int<sgs_contig>>>,
           Stride<Int<SubgroupSize * sgs_contig>,  Stride<_1, Int<SubgroupSize>>>>
  >;

  #define RETURN_STATEMENT(NON_CONTIG, DTYPE_SIZE, CONTIG) \
    using PrefetchTraits = Copy_Traits<XE_2D_U##DTYPE_SIZE##x##NON_CONTIG##x##CONTIG##_LD_N, decltype(tensor.stride())>; \
    using PrefetchAtom = Copy_Atom<PrefetchTraits, dtype>; \
    using Scalar = Int<cute::max(1, DTYPE_SIZE / dtype_size_bits)>; \
    using ScalarLayout = std::conditional_t<is_need_reversed, Layout<Shape<Scalar, _1>>, Layout<Shape<_1, Scalar>>>; \
    using ScalarPrefetchShape =  decltype(product_each(raked_product(ScalarLayout{}, \
                                                        Layout<typename PrefetchTraits::BlockShape>{}).shape())); \
    using PrefetchValLayout = decltype(make_layout(shape_div(ScalarPrefetchShape{}, CopyThreadShape{}))); \
    return make_tiled_copy(PrefetchAtom{}.with(tensor), \
                           PrefetchTilingLayout{}, \
                           PrefetchValLayout{});

  #define CHOOSE_PREFETCH_FOR_TYPE(NON_CONTIG) \
    if constexpr (dtype_size_bits == 4){ \
      RETURN_STATEMENT(NON_CONTIG, 8, 32); \
    } else if constexpr (dtype_size_bits == 8){ \
      RETURN_STATEMENT(NON_CONTIG, 8, 64); \
    } else if constexpr (dtype_size_bits == 16){ \
      RETURN_STATEMENT(NON_CONTIG, 16, 32); \
    } else if constexpr (dtype_size_bits == 32){ \
      RETURN_STATEMENT(NON_CONTIG, 32, 16); \
    } else { \
      static_assert(dependent_false<dtype> && "Invalid TileShape and dtype"); \
    }

  if constexpr (block_non_contig_size == 1){
    CHOOSE_PREFETCH_FOR_TYPE(1)
  } else if constexpr (block_non_contig_size == 2) {
    CHOOSE_PREFETCH_FOR_TYPE(2)
  } else if constexpr (block_non_contig_size == 4) {
    CHOOSE_PREFETCH_FOR_TYPE(4)
  } else if constexpr (block_non_contig_size == 8) {
    CHOOSE_PREFETCH_FOR_TYPE(8)
  } else if constexpr (block_non_contig_size == 16) {
    CHOOSE_PREFETCH_FOR_TYPE(16)
  } else if constexpr (block_non_contig_size == 32) {
    CHOOSE_PREFETCH_FOR_TYPE(32)
  } else {
    static_assert(dependent_false<TileShape> && "Invalid TileShape[0]");
  }
  #undef CHOOSE_PREFETCH_FOR_TYPE
  #undef RETURN_STATEMENT
}


template <class CopyOp, class StrideIndicator = cute::Stride<int64_t, cute::Int<1>, int64_t>>
struct XE_2D_LD_Unpack {

  using BlockShape = typename CopyOp::BlockShape;
  using Traits_LD_t = Copy_Traits<CopyOp, StrideIndicator>;

  static constexpr auto stride_rank = rank(StrideIndicator{});
  static_assert(stride_rank == 2 || stride_rank == 3);

  // Assume LD_T/LD_N will indicate ColumnMajor and RowMajor
  static constexpr bool is_column_major = detail::is_transpose_load<CopyOp>;

  // We need reverse some parameters becasue intel xe 2d copy intrinsic always assume the matrix is (M, N):(N, 1) convention
  static constexpr bool is_need_reversed = detail::is_stride_leftmost<StrideIndicator>;

  // For a logic matrix M-rows and N-columns, user can pass it with the convention (M, N):(N, 1), also can pass it with convention (N, M):(1, N).
  // It mean (M, N):(N, 1) convention if 'is_convention_MN' is true, (N, M):(1, N) convention otherwise.
  static constexpr bool is_convention_MN = !(is_need_reversed ^ is_column_major);

  // 2d copy parameters
  const void *base_ptr;
  uint32_t width;
  uint32_t height;
  uint32_t pitch;
  uint32_t stride_l = 0;



  XE_2D_LD_Unpack(const void *ptr, uint32_t y,
                 uint32_t x, uint32_t p = 0) : base_ptr(ptr) {
    if constexpr (is_need_reversed) {
      width = y;
      height = x;
    }
    else {
      width = x;
      height = y;
    }

    pitch = (p == 0 ? width : p);
  }

  template <class... TensorArgs>
  XE_2D_LD_Unpack(Tensor<TensorArgs...> const &tensor) {
    base_ptr = tensor.data().get();

    if constexpr (is_need_reversed)
    {
      width = size<0>(tensor.shape());
      height = size<1>(tensor.shape());
      pitch = size<1>(tensor.stride());
    }
    else
    {
      width = size<1>(tensor.shape());
      height = size<0>(tensor.shape());
      pitch = size<0>(tensor.stride());
    }

    if constexpr (stride_rank == 3) {
      stride_l = size<2>(tensor.stride());
    }
  }

  XE_2D_LD_Unpack(Traits_LD_t const &traits) : base_ptr(traits.base_ptr),
                  width(traits.width), height(traits.height), pitch(traits.pitch),
                  stride_l(traits.stride_l) {}

  XE_2D_LD_Unpack() {}

  template<class TileShape, int Num_SGs, class Tensor>
  CUTE_HOST_DEVICE auto prefetch_selector(Tensor const& tensor) const {
    constexpr int subgroup_size  = size(typename Traits_LD_t::ThrID{});
    return cute::prefetch_selector<TileShape, Num_SGs, subgroup_size>(tensor);
  }

  template <class TS, class SLayout, class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr void
  copy_unpack(Traits_LD_t const &traits, Tensor<TS, SLayout> const &src,
              Tensor<TD, DLayout> &dst) {
    using dtype = typename Tensor<TD, DLayout>::value_type;
    constexpr int dtype_bits = sizeof_bits_v<dtype>;

    static_assert(is_rmem<TD>::value);
    static_assert(size(SLayout{}) * dtype_bits == size<1>(typename Traits_LD_t::SrcLayout{}),
                  "Src tensor size does not match copy atom size.");
    static_assert(size(DLayout{}) * dtype_bits == size<1>(typename Traits_LD_t::DstLayout{}),
                  "Dst tensor size does not match copy atom size.");

    dtype *base_addr = (dtype *)traits.base_ptr;
  
    auto [m, n, l] = src.data().coord_;
    int x = is_need_reversed ? m : n;
    int y = is_need_reversed ? n : m;

    constexpr auto inst_size_bits = detail::size_of_inst_bits<CopyOp, dtype>;

    CopyOp::copy(base_addr + l * traits.stride_l,
                 (traits.width * sizeof_bits_v<dtype>) / sizeof_bits_v<int8_t>, traits.height,
                 (traits.pitch * sizeof_bits_v<dtype>) / sizeof_bits_v<int8_t>,
                 intel::coord_t{(int)(x * sizeof_bits_v<dtype> / inst_size_bits), y},
                 raw_pointer_cast(&((&*dst.data())[0])));
  }

  template <class... CA_Args, class TS, class SLayout>
  CUTE_HOST_DEVICE friend constexpr void
  prefetch(Copy_Atom<Traits_LD_t, CA_Args...> const &atom,
           Tensor<TS, SLayout> const &src) {
    using dtype = typename Copy_Atom<Traits_LD_t, CA_Args...>::ValType;

    static_assert(detail::has_prefetch<CopyOp>);
    static_assert(size(SLayout{}) * sizeof_bits_v<dtype> == size<1>(typename Traits_LD_t::SrcLayout{}),
                  "Src tensor size does not match copy atom for prefetch size");

    dtype *base_addr = (dtype *)atom.base_ptr;

    auto [m, n, l] = src.data().coord_;

    int x = is_need_reversed ? m : n;
    int y = is_need_reversed ? n : m;

    constexpr auto inst_size_bits = detail::size_of_inst_bits<CopyOp, dtype>;

    CopyOp::PREFETCH::copy(base_addr + l * atom.stride_l,
                           (atom.width * sizeof_bits_v<dtype>) / sizeof_bits_v<int8_t>, atom.height,
                           (atom.pitch * sizeof_bits_v<dtype>) / sizeof_bits_v<int8_t>,
                           intel::coord_t{(int)(x * sizeof_bits_v<dtype> / inst_size_bits), y});
  }

  template <class... TensorArgs>
  static constexpr auto with(Tensor<TensorArgs...> const &tensor) {
      return Traits_LD_t{tensor};
  }

  template<class T0, class T1, class... Ts>
  static constexpr auto with(T0 && arg0, T1 && arg1, Ts&&... args) {
      return Traits_LD_t{arg0, arg1, args...};
  }
};

template <class CopyOp, class StrideIndicator = cute::Stride<int64_t, cute::Int<1>, int64_t>> struct XE_2D_ST_Unpack {
  using Traits_ST_t = Copy_Traits<CopyOp, StrideIndicator>;
  using BlockShape = typename CopyOp::BlockShape;

  static constexpr auto stride_rank = rank(StrideIndicator{});
  static_assert(stride_rank == 2 || stride_rank == 3);

  static constexpr bool is_convention_MN = true;

  const void *base_ptr;
  uint32_t width;
  uint32_t height;
  uint32_t pitch;
  uint32_t stride_l = 0;

  XE_2D_ST_Unpack(const void *ptr, uint32_t y,
                 uint32_t x, uint32_t p = 0) : base_ptr(ptr) {
      width = x;
      height = y;
      pitch = (p == 0 ? width : p);
  }

  template <class... TensorArgs>
  XE_2D_ST_Unpack(Tensor<TensorArgs...> const &tensor) {
    base_ptr = tensor.data().get();
    width = size<1>(tensor.shape());
    height = size<0>(tensor.shape());
    pitch = size<0>(tensor.stride());

    if constexpr (stride_rank == 3) {
      stride_l = size<2>(tensor.stride());
    }
  }

  XE_2D_ST_Unpack(Traits_ST_t const &traits)  : base_ptr(traits.base_ptr),
                  width(traits.width), height(traits.height), pitch(traits.pitch),
                  stride_l(traits.stride_l) {}

  XE_2D_ST_Unpack() {}


  template <class TS, class SLayout, class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr void
  copy_unpack(Traits_ST_t const &traits, Tensor<TS, SLayout> const &src,
              Tensor<TD, DLayout> &dst) {

    using dtype = typename Tensor<TS, SLayout>::value_type;
    constexpr int dtype_bits = sizeof_bits_v<dtype>;

    static_assert(is_rmem<TS>::value);
    static_assert(size(SLayout{}) * dtype_bits == size<1>(typename Traits_ST_t::SrcLayout{}),
                  "Src tensor size does not match copy atom size.");
    static_assert(size(DLayout{}) * dtype_bits == size<1>(typename Traits_ST_t::DstLayout{}),
                  "Dst tensor size does not match copy atom size.");

    dtype *base_addr = (dtype *)traits.base_ptr;
    
    auto [m, n, l] = dst.data().coord_;

    CopyOp::copy(base_addr + l * traits.stride_l,
                 traits.width * sizeof(dtype), traits.height,
                 traits.pitch * sizeof(dtype),
                 intel::coord_t{(int)n, (int)m}, &*src.data());
  }

  template <class... TensorArgs>
  static constexpr auto with(Tensor<TensorArgs...> const &tensor) {
    return Traits_ST_t{tensor};
  }

  template<class T0, class T1, class... Ts>
  static constexpr auto with(T0 && arg0, T1 && arg1, Ts&&... args) {
      return Traits_ST_t{arg0, arg1, args...};
  }

};

template <class TiledCopy, class TLShape>
CUTE_HOST_DEVICE constexpr auto make_fragment_layout(TiledCopy &tiled_copy,
                                                     TLShape &&fragment_top_level_shape) {
  auto [mma_atom_shape, total_mma_atom_iters_M, total_mma_atom_iters_N] = fragment_top_level_shape;
  auto mma_atom_shape_2d = prepend<2>(mma_atom_shape, _1{});

  Int mma_atom_size_M =
      Int<!TiledCopy::is_convention_MN ? size<0>(mma_atom_shape_2d) : size<1>(mma_atom_shape_2d)>{};
  Int mma_atom_size_N =
      Int<!TiledCopy::is_convention_MN ? size<1>(mma_atom_shape_2d) : size<0>(mma_atom_shape_2d)>{};

  using ThreadLayout_ = Shape<_1, Int<size(typename TiledCopy::Traits_LD_t::ThrID{})>>;
  using ThreadLayout = std::conditional_t<TiledCopy::is_convention_MN,
                                          ThreadLayout_,
                                          decltype(cute::reverse(ThreadLayout_{}))>;
  auto thread_copy_shape = shape_div(typename TiledCopy::BlockShape{}, ThreadLayout{});
  Int copy_size_M = size<0>(thread_copy_shape);
  Int copy_size_N = size<1>(thread_copy_shape);

  static_assert(copy_size_M >= mma_atom_size_M, "MMA atom larger than copy atom is not currently supported.");
  static_assert(copy_size_N >= mma_atom_size_N, "MMA atom larger than copy atom is not currently supported.");
  Int mma_atom_iters_in_copy_M = copy_size_M / mma_atom_size_M;
  Int mma_atom_iters_in_copy_N = copy_size_N / mma_atom_size_N;
  Int copy_iters_M = total_mma_atom_iters_M / mma_atom_iters_in_copy_M;
  Int copy_iters_N = total_mma_atom_iters_N / mma_atom_iters_in_copy_N;
  auto order = std::conditional_t<TiledCopy::is_convention_MN,
                                  Step<Step<_0, _1>, Step<_2, _4>, Step<_3, _5>>,
                                  Step<Step<_0, _1>, Step<_3, _5>, Step<_2, _4>>>{};

  return make_ordered_layout(make_shape(mma_atom_shape_2d,
                                        make_shape(mma_atom_iters_in_copy_M, copy_iters_M),
                                        make_shape(mma_atom_iters_in_copy_N, copy_iters_N)),
                             order);
};

// clang-format off

template <typename CopyOp, typename... Args>
struct Copy_Traits_{
  static_assert(cute::dependent_false<CopyOp>, "Copy_Traits_ not defined for this CopyOp");
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x1x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x1x32_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,_16>,
                           Stride<_16, _1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x1x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x2x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x2x32_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,  _2, _2>>,
                           Stride< _0,Stride< _1,_128,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,  _2, _2>>,
                           Stride<_16,Stride< _1,_128,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x2x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x4x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x4x32_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,  _2, _4>>,
                           Stride< _0,Stride< _1,_128,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,  _2, _4>>,
                           Stride<_16,Stride< _1,_128,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x4x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x8x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x8x32_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,  _2, _8>>,
                           Stride< _0,Stride< _1,_128,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,  _2, _8>>,
                           Stride<_16,Stride< _1,_128,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x8x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x16x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x16x32_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,  _2, _16>>,
                           Stride< _0,Stride< _1,_128,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,  _2, _16>>,
                           Stride<_16,Stride< _1,_128,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x16x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x32x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x32x32_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,  _2, _32>>,
                           Stride< _0,Stride< _1,_128,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,  _2, _32>>,
                           Stride<_16,Stride< _1,_128,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x32x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U4x32x64_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U4x32x64_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape < _4, _4, _32>>,
                           Stride<_0,Stride< _1, _4, _16>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape < _4, _4, _32>>,
                           Stride<_16,Stride< _1, _4, _16>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U4x32x64_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U4x16x64_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U4x16x64_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_4, _4, _16>>,
                           Stride<_0,Stride <_1, _4, _16>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_4, _4, _16>>,
                           Stride<_16,Stride<_1, _4, _16>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U4x16x64_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U4x16x16_LD_T, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U4x16x16_LD_T, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_4, _16>>,
                           Stride<_0,Stride< _1,_64>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_4, _16>>,
                           Stride<_16,Stride< _1,_64>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U4x16x16_LD_T, args_t...>(args...) {}
};
template <class... args_t>
struct Copy_Traits_<XE_2D_U4x32x16_LD_T, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U4x32x16_LD_T, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_4, _32>>,
                          Stride<_0,Stride< _1,_64>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_4, _32>>,
                           Stride<_16,Stride< _1,_64>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U4x32x16_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x1x64_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x1x64_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x1x64_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x1x64_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x1x64_LD_N::PREFETCH, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,_2,  _2>>,
                           Stride<_16,Stride<_1,_8,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,_2,  _2>>,
                           Stride<_16,Stride<_1,_8,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x2x64_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x2x64_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _2>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x2x64_LD_N, args_t...>(args...) {}
};


template <class... args_t>
struct Copy_Traits_<XE_2D_U8x2x64_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x2x64_LD_N::PREFETCH, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,_2,  _2,  _2>>,
                           Stride<_16,Stride<_1,_8,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,_2,  _2,  _2>>,
                           Stride<_16,Stride<_1,_8,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x4x64_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x4x64_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (dst-thr,dst-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2,  _4>>,
                           Stride<_0,Stride< _1,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _4>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x4x64_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x4x64_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x4x64_LD_N::PREFETCH, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,_2,  _2,  _4>>,
                           Stride<_16,Stride<_1,_8,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,_2,  _2,  _4>>,
                           Stride<_16,Stride<_1,_8,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x8x64_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x8x64_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _8>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x8x64_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x8x64_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x8x64_LD_N::PREFETCH, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,_2,  _2,  _8>>,
                           Stride<_16,Stride<_1,_8,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,_2,  _2,  _8>>,
                           Stride<_16,Stride<_1,_8,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};


template <class... args_t>
struct Copy_Traits_<XE_2D_U8x16x64_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x16x64_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2, _16>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x16x64_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x16x64_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x16x64_LD_N::PREFETCH, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2, _16>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2, _16>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x32x64_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x32x64_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2, _32>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x32x64_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x32x64_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x32x64_LD_N::PREFETCH, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2, _32>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2, _32>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x1x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x1x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_16>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,_16>,
                           Stride<_16, _1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U16x1x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x2x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x2x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_16>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U16x2x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x4x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x4x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _4>>,
                           Stride< _0,Stride< _1,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _4>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U16x4x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x8x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x8x16_LD_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _8>>,
                           Stride< _0,Stride< _1,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _8>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x8x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x8x16_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x8x16_LD_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _8>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _8>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x16x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x16x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16, _16>>,
                           Stride< _0, Stride< _1,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16, _16>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x16x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x16x16_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x16x16_LD_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16, _16>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16, _16>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x32x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x32x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_512>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16, _32>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x32x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x32x16_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x32x16_LD_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16, _32>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16, _32>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x1x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x1x32_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2>>,
                           Stride< _0,Stride< _1,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x1x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x1x32_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x1x32_LD_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x2x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x2x32_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2,  _2>>,
                           Stride< _0,Stride< _1,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _2>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x2x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x2x32_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x2x32_LD_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2,  _2>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _2>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x4x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x4x32_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2,  _4>>,
                           Stride< _0,Stride< _1,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _4>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x4x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x4x32_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x4x32_LD_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2,  _4>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _4>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x8x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x8x32_LD_N, args_t...> {
  using ThrID = Layout<_16>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2,  _8>>,
                           Stride< _0,Stride< _1,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _8>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x8x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x8x32_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x8x32_LD_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32,  _8>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32,  _8>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x16x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x16x32_LD_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;


  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2, _16>>,
                           Stride< _0,Stride< _1,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2, _16>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x16x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x16x32_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x16x32_LD_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32, _16>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32, _16>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x32x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x32x32_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16, Shape<_16,  _2, _32>>,
                           Stride<_0, Stride< _1,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16, Shape <_16,   _2, _32>>,
                           Stride<_16, Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x32x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x32x32_LD_N::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x32x32_LD_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32, _32>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32, _32>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_TF32x1x8_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_TF32x1x8_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape < _8,_2>,_32>,
                           Stride<Stride<_32,_0>, _1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x1x8_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_TF32x2x8_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_TF32x2x8_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape < _8,  _2>,_32>,
                           Stride<Stride<_32,_256>, _1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x2x8_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_TF32x4x8_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_TF32x4x8_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape < _8,  _2>,Shape <_32,  _2>>,
                           Stride<Stride<_32,_256>,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x4x8_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_TF32x8x8_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_TF32x8x8_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape < _8,  _2>,Shape <_32,  _4>>,
                           Stride<Stride<_32,_256>,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x8x8_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_TF32x16x8_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_TF32x16x8_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape < _8,  _2>,Shape <_32,   _8>>,
                           Stride<Stride<_32,_256>,Stride< _1, _512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x16x8_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_TF32x32x8_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_TF32x32x8_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape < _8,  _2>,Shape <_32, _16>>,
                           Stride<Stride<_32,_256>,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x32x8_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_TF32x1x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_TF32x1x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape < _8,_2>,Shape <_32,  _2>>,
                           Stride<Stride<_32,_0>,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x1x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_TF32x2x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_TF32x2x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape < _8,  _2>,Shape <_32,  _2>>,
                           Stride<Stride<_32,_512>,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x2x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_TF32x4x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_TF32x4x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape < _8,  _2>,Shape <_32,  _2,   _2>>,
                           Stride<Stride<_32,_512>,Stride< _1,_256,_1024>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x4x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_TF32x8x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_TF32x8x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape < _8,  _2>,Shape <_32,  _2,   _4>>,
                           Stride<Stride<_32,_512>,Stride< _1,_256,_1024>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x8x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_TF32x16x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_TF32x16x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _32>>,
                           Stride<_0,Stride< _512, _1>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x16x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_TF32x32x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_TF32x32x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16, Shape <_16, _2, _32>>,
                           Stride< _0, Stride<_512, Int<512 * 16>, _1>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x32x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x1x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U32x1x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,_32>,
                           Stride<_32, _1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x1x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x2x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U32x2x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32,  _2>>,
                           Stride< _0,Stride< _1,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32,  _2>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x2x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x4x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U32x4x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32,  _4>>,
                           Stride< _0, Stride< _1,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32,  _4>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x4x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x8x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U32x8x16_LD_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32,  _8>>,
                           Stride< _0, Stride< _1,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32,  _8>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x8x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x16x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U32x16x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32, _16>>,
                           Stride< _0,Stride< _1,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32, _16>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x16x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x32x16_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U32x32x16_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32, _32>>,
                           Stride< _0,Stride< _1,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32, _32>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x32x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x32x16_LD_V, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x32x16_LD_V, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,  _4,  _8>>,
                           Stride< _8,Stride<_1,_128,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U8x32x16_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x32x16_LD_V::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x32x16_LD_V, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8, _32>>,
                           Stride< _8,Stride<_1,_128>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8, _32>>,
                           Stride< _8,Stride<_1,_128>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x32x32_LD_V, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x32x32_LD_V, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_512>,
                           Stride< _0,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,  _4,  _2,  _8>>,
                           Stride< _8,Stride<_1,_256,_128,_1024>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U8x32x32_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x32x64_LD_V, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x32x64_LD_V, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,  _4,  _4,   _8>>,
                           Stride< _8,Stride<_1,_512,_128,_2048>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U8x32x64_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x16x16_LD_V, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x16x16_LD_V, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2,  _8>>,
                           Stride< _0,Stride< _1,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _8>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x16x16_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x32x16_LD_V, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x32x16_LD_V, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2, _16>>,
                           Stride< _0,Stride< _1,_256,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2, _16>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x32x16_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x32x32_LD_V, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x32x32_LD_V, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2,  _2,  _16>>,
                           Stride<_0,Stride< _1,_512,_256,_1024>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _2,  _16>>,
                           Stride<_16,Stride< _1,_512,_256,_1024>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x32x32_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x16x32_LD_V, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x16x32_LD_V, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2,  _2,   _8>>,
                           Stride<_0,Stride< _1,_512,_256,_1024>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _2,   _8>>,
                           Stride<_16,Stride< _1,_512,_256,_1024>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x16x32_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x16x8_LD_T, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x16x8_LD_T, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_16>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape < _16,Shape <_16, _8>>,
                           Stride<_128,Stride< _1,_16>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U16x16x8_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x16x16_LD_T, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x16x16_LD_T, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  // TODO(joe): Not convinced that changing from <_16, _256> should be required here
  // but get_logical_layout assumes get<1,0>(layout.shape) is the type size
  using SrcLayout = Layout<Shape < _16,Shape <_16,_16>>,
                           Stride<_0,Stride< _1,_16>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape < _16,Shape <_16,_16>>,
                           Stride<_256,Stride< _1,_16>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U16x16x16_LD_T, args_t...>(args...) {}
};

// template<class... args_t>
// struct Copy_Traits<XE_2D_U32x16x1_LD_T, args_t...>
//     : XE_2D_LD_Unpack<XE_2D_U32x16x1_LD_T, args_t...> {
//   // Logical thread id to thread idx
//   using ThrID = Layout<_16>;
//   // Map from (src-thr,src-val) to bit
//   using SrcLayout = Layout<Shape <_16,_32>,
//                            Stride< _0, _1>>;
//   // Map from (dst-thr,dst-val) to bit
//   using DstLayout = Layout<Shape <_16,_32>,
//                            Stride<_32, _1>>;
//   // Reference map from (thr,val) to bit
//   using RefLayout = DstLayout;
// };

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x16x2_LD_T, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U32x16x2_LD_T, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32, _2>>,
                           Stride< _0,Stride< _1,_32>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32, _2>>,
                           Stride<_64,Stride< _1,_32>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x16x2_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x16x4_LD_T, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U32x16x4_LD_T, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32, _4>>,
                           Stride< _0,Stride< _1,_32>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32, _4>>,
                           Stride<_64,Stride< _1,_32>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x16x4_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x16x8_LD_T, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U32x16x8_LD_T, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32, _8>>,
                           Stride< _0,Stride< _1,_32>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape < _16,Shape <_32, _8>>,
                           Stride<_128,Stride< _1,_32>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x16x8_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x16x8_LD_T::PREFETCH, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U32x16x8_LD_T, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <Shape < _8,_2>,Shape <_32, _16>>,
                           Stride<Stride<_32,_0>,Stride< _1,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape < _8,_2>,Shape <_32, _16>>,
                           Stride<Stride<_32,_0>,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U64x8x1_LD_T, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U64x8x1_LD_T, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_64>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape < _8,_2>,_64>,
                           Stride<Stride<_64,_0>, _1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U64x8x1_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U64x8x2_LD_T, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U64x8x2_LD_T, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_64>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape <  _8,_2>,Shape <_64, _2>>,
                           Stride<Stride<_128,_0>,Stride< _1,_64>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U64x8x2_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U64x8x4_LD_T, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U64x8x4_LD_T, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_64>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <Shape <  _8,_2>,Shape <_64, _4>>,
                           Stride<Stride<_256,_0>,Stride< _1,_64>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U64x8x4_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x2x32_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U8x2x32_ST_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,  _2, _2>>,
                           Stride<_16,Stride< _1,_128,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_8,  _2, _2>>,
                           Stride< _0,Stride< _1,_128,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U8x2x32_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x1x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U8x1x16_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_8>,
                           Stride< _8,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_ST_Unpack<XE_2D_U8x1x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x2x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U8x2x16_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,  _2>>,
                           Stride< _8,Stride<_1,_128>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_ST_Unpack<XE_2D_U8x2x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x4x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U8x4x16_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,  _4>>,
                           Stride< _8,Stride<_1,_128>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x8x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U8x8x16_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_8,  _8>>,
                           Stride< _8,Stride<_1,_128>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;
  using CopyInternalType = uint8_t;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U8x8x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U8x8x32_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U8x8x32_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout =
      Layout<Shape<_16, Shape<_8, _16>>, Stride<_0, Stride<_0, _1>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;
  using CopyInternalType = uint8_t;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U8x8x32_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x1x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U16x1x16_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_16>,
                           Stride<_16, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,_16>,
                           Stride< _0, _1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U16x1x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x2x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U16x2x16_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _2>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2>>,
                           Stride< _0,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U16x2x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x4x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U16x4x16_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _4>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _4>>,
                           Stride< _0,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U16x4x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U16x8x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U16x8x16_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_16,  _8>>,
                           Stride<_16,Stride< _1,_256>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _8>>,
                           Stride< _0,Stride< _1,_256>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U16x8x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x1x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U32x1x16_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_32>,
                           Stride<_32, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,_32>,
                           Stride< _0, _1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U32x1x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x2x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U32x2x16_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32,  _2>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32,  _2>>,
                           Stride< _0,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U32x2x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x4x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U32x4x16_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32,  _4>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32,  _4>>,
                           Stride< _0,Stride< _1,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  template <class... ArgT>
  Copy_Traits_(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U32x4x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits_<XE_2D_U32x8x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U32x8x16_ST_N, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,Shape <_32,  _8>>,
                           Stride<_32,Stride< _1,_512>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_32,  _8>>,
                           Stride< _0,Stride< _1,_512>>>; // 0 here makes all threads in a warp get the same base address
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;

  template <class... ArgTs>
  Copy_Traits_(ArgTs... args)
      : XE_2D_ST_Unpack<XE_2D_U32x8x16_ST_N, args_t...>(args...) {}
};

template<class S, class D>
struct Copy_Traits<XE_ATOMIC<S, D>> {
  // Logical thread id to thread idx (one-thread)
  using ThrID = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,Int<sizeof_bits<S>::value>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,Int<sizeof_bits<D>::value>>>;

  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;
};

template<class S, class D>
struct Copy_Traits<XE_1D_LDSM<S, D>> {
    // Logical thread id to thread idx
    using ThrID = Layout<_16>;
    // Map from (src-thr,src-val) to bit
    using SrcLayout = Layout<Shape<_16, Int<sizeof_bits<S>::value>>, Stride<_0, _1>>;
    // Map from (dst-thr,dst-val) to bit
    using DstLayout = Layout<Shape<_16, Shape<Int<sizeof_bits<D>::value / sizeof_bits<S>::value>, Int<sizeof_bits<S>::value>>>,
                             Stride<Int<sizeof_bits<S>::value>, Stride<Int<sizeof_bits<S>::value * 16>, _1>>>;
    // Reference map from (thr,val) to bit
    using RefLayout = DstLayout;
};

template<class S, class D>
struct Copy_Traits<XE_1D_LOAD_GLOBAL<S, D>> {
    // Logical thread id to thread idx
    using ThrID = Layout<_16>;
    // Map from (src-thr,src-val) to bit
    using SrcLayout = Layout<Shape<_16, Int<sizeof_bits<S>::value>>, Stride<_0, _1>>;
    // Map from (dst-thr,dst-val) to bit
    using DstLayout = Layout<Shape <_16, Shape<Int<sizeof_bits<D>::value / sizeof_bits<S>::value>, Int<sizeof_bits<S>::value>>>,
                             Stride<Int<sizeof_bits<S>::value>, Stride<Int<sizeof_bits<S>::value * 16>, _1>>>;
    // Reference map from (thr,val) to bit
    using RefLayout = DstLayout;
};

template<class S, class D>
struct Copy_Traits<PREFETCH<S, D>> {
    // Logical thread id to thread idx
    using ThrID = Layout<_16>;
    // Map from (src-thr,src-val) to bit
    using SrcLayout = Layout<Shape<_16, Int<sizeof_bits<S>::value>>, Stride<_0, _1>>;
    // Map from (dst-thr,dst-val) to bit
    using DstLayout = Layout<Shape <                       _16,Int<sizeof_bits<D>::value>>,
                             Stride<Int<sizeof_bits<D>::value>,                        _1>>;
    // Reference map from (thr,val) to bit
    using RefLayout = DstLayout;

    template <class... CopyArgs>
    CUTE_HOST_DEVICE
    Copy_Traits(Copy_Traits<CopyArgs...> const& traits) {}
};

template<class S, class D>
struct Copy_Traits<XE_1D_STSM<S, D>> {
    // Logical thread id to thread idx
    using ThrID = Layout<_16>;
    // Map from (src-thr,src-val) to bit
    using SrcLayout = Layout<Shape<_16, Shape<Int<sizeof_bits<S>::value / sizeof_bits<D>::value>, Int<sizeof_bits<D>::value>>>,
                             Stride<Int<sizeof_bits<D>::value>, Stride<Int<sizeof_bits<D>::value * 16>, _1>>>;
    // Map from (dst-thr,dst-val) to bit
    using DstLayout = Layout<Shape<_16, Int<sizeof_bits<D>::value>>, Stride<_0, _1>>;
    // Reference map from (thr,val) to bit
    using RefLayout = SrcLayout;
};

template<class S, class D>
struct Copy_Traits<XE_1D_STORE_GLOBAL<S, D>> {
    // Logical thread id to thread idx
    using ThrID = Layout<_16>;
    // Map from (src-thr,src-val) to bit
    using SrcLayout = Layout<Shape<_16, Shape<Int<sizeof_bits<S>::value / sizeof_bits<D>::value>, Int<sizeof_bits<D>::value>>>,
                             Stride<Int<sizeof_bits<D>::value>, Stride<Int<sizeof_bits<D>::value * 16>, _1>>>;
    // Map from (dst-thr,dst-val) to bit
    using DstLayout = Layout<Shape<_16, Int<sizeof_bits<D>::value>>, Stride<_0, _1>>;
    // Reference map from (thr,val) to bit
    using RefLayout = SrcLayout;
};

// This is the Copy_Traits for Xe 2D Block copies, which inherits from `Copy_Traits_` and handles
// transposing the traits depending on the layout of the tensor in memory (MN vs. K-major).
// Since we can't SFINAE this (Copy_Traits has no Enable = void template param), we are
// obliged to define the actual Copy_Traits for each instruction individually
// TODO(codeplay): Revisit this after SPIR-V copy builtins added
// TODO(codeplay): Is it safe that we default to row-major when constructing Copy_Traits,
// or should we insist that the developer provide the stride?
#define COPY_TRAIT_LD_DEF(COPY_OP) \
template <class... args_t> \
struct Copy_Traits<COPY_OP, args_t...> : Copy_Traits_<COPY_OP, args_t...>{ \
  using CopyOp = COPY_OP; \
  using Base = Copy_Traits_<CopyOp, args_t...>; \
  using XE_2D_LD_Unpack<CopyOp, args_t...>::is_convention_MN; \
  using typename Base::ThrID; \
  using BlockShape = std::conditional_t<is_convention_MN, typename Base::BlockShape, decltype(cute::reverse(typename Base::BlockShape{}))>; \
  using SrcLayout = decltype(detail::get_logical_layout<is_convention_MN>(typename Base::SrcLayout{}, typename Base::BlockShape{})); \
  using DstLayout = decltype(detail::get_logical_layout<is_convention_MN>(typename Base::DstLayout{}, typename Base::BlockShape{})); \
  using RefLayout = DstLayout; \
  template <class... ArgTs> \
  Copy_Traits(ArgTs... args) \
      : Copy_Traits_<CopyOp, args_t...>(args...) {} \
};

#define COPY_TRAIT_ST_DEF(COPY_OP) \
template <class... args_t> \
struct Copy_Traits<COPY_OP, args_t...> : Copy_Traits_<COPY_OP, args_t...>{ \
  using CopyOp = COPY_OP; \
  using Base = Copy_Traits_<CopyOp, args_t...>; \
  using XE_2D_ST_Unpack<CopyOp, args_t...>::is_convention_MN; \
  using typename Base::ThrID; \
  using BlockShape = std::conditional_t<is_convention_MN, typename Base::BlockShape, decltype(cute::reverse(typename Base::BlockShape{}))>; \
  using SrcLayout = decltype(detail::get_logical_layout<is_convention_MN>(typename Base::SrcLayout{}, typename Base::BlockShape{})); \
  using DstLayout = decltype(detail::get_logical_layout<is_convention_MN>(typename Base::DstLayout{}, typename Base::BlockShape{})); \
  using RefLayout = SrcLayout; \
  template <class... ArgTs> \
  Copy_Traits(ArgTs... args) \
      : Copy_Traits_<CopyOp, args_t...>(args...) {} \
};

COPY_TRAIT_LD_DEF(XE_2D_U8x1x32_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U8x2x32_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U8x4x32_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U8x8x32_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U8x1x64_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U8x2x64_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U8x4x64_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U8x8x64_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U64x8x1_LD_T)
COPY_TRAIT_LD_DEF(XE_2D_U64x8x2_LD_T)
COPY_TRAIT_LD_DEF(XE_2D_U64x8x4_LD_T)
COPY_TRAIT_LD_DEF(XE_2D_U8x16x32_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U8x32x32_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U8x16x64_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U8x32x64_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U16x1x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U16x2x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U16x4x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U16x8x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U16x1x32_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U16x2x32_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U16x4x32_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U16x8x32_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U16x16x32_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_TF32x1x8_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_TF32x2x8_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_TF32x4x8_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_TF32x8x8_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U32x1x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U32x2x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U32x4x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U32x8x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U8x32x16_LD_V)
COPY_TRAIT_LD_DEF(XE_2D_U8x32x32_LD_V)
COPY_TRAIT_LD_DEF(XE_2D_U8x32x64_LD_V)
COPY_TRAIT_LD_DEF(XE_2D_U16x16x8_LD_T)
COPY_TRAIT_LD_DEF(XE_2D_U32x16x2_LD_T)
COPY_TRAIT_LD_DEF(XE_2D_U32x16x4_LD_T)
COPY_TRAIT_LD_DEF(XE_2D_U32x16x8_LD_T)
COPY_TRAIT_LD_DEF(XE_2D_U16x16x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U16x32x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U16x32x32_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_TF32x16x8_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_TF32x32x8_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_TF32x1x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_TF32x2x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_TF32x4x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_TF32x8x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U32x16x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U32x32x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U16x16x16_LD_V)
COPY_TRAIT_LD_DEF(XE_2D_U16x32x16_LD_V)
COPY_TRAIT_LD_DEF(XE_2D_U16x32x32_LD_V)
COPY_TRAIT_LD_DEF(XE_2D_U16x16x32_LD_V)
COPY_TRAIT_LD_DEF(XE_2D_U16x16x16_LD_T)
COPY_TRAIT_LD_DEF(XE_2D_TF32x16x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_TF32x32x16_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U4x32x64_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U4x16x64_LD_N)
COPY_TRAIT_LD_DEF(XE_2D_U4x32x16_LD_T)
COPY_TRAIT_LD_DEF(XE_2D_U4x16x16_LD_T)
COPY_TRAIT_LD_DEF(XE_2D_U8x1x64_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U8x2x64_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U8x4x64_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U8x8x64_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U8x16x64_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U8x32x64_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U16x8x16_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U16x1x32_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U16x2x32_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U16x4x32_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U16x8x32_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U8x32x16_LD_V::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U32x16x8_LD_T::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U16x16x16_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U16x32x16_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U16x16x32_LD_N::PREFETCH)
COPY_TRAIT_LD_DEF(XE_2D_U16x32x32_LD_N::PREFETCH)

COPY_TRAIT_ST_DEF(XE_2D_U8x2x32_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U8x1x16_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U8x2x16_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U8x4x16_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U8x8x16_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U8x8x32_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U16x1x16_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U16x2x16_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U16x4x16_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U16x8x16_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U32x1x16_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U32x2x16_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U32x4x16_ST_N)
COPY_TRAIT_ST_DEF(XE_2D_U32x8x16_ST_N)

// Generate the PVC coordinate tensor
template <class GShape>
CUTE_HOST_DEVICE constexpr
auto
get_pvc_tensor(GShape const& g_shape) {
  return make_counting_tensor(make_identity_layout(g_shape));
}

} // end namespace cute
