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

// ==========  size_of_inst  ==========
template <class T, class dtype, class = void>
static constexpr auto size_of_inst = sizeof(dtype);

template <class T, class dtype>
static constexpr auto size_of_inst<T, dtype, cute::void_t<typename T::inst_dtype>> = sizeof(typename T::inst_dtype);


// ==========  value_layout_t  ==========
template <class T, class = void>
struct value_layout_t {
  using type = decltype(make_layout(make_shape(get<0>(typename T::BlockShape{}),
                                                            get<1>(typename T::BlockShape{})
                                                                / Int<detail::subgroup_size>{})));
};

template <class T>
struct value_layout_t<T, cute::void_t<typename T::ValueShape>> {
  using type = decltype(make_layout(make_shape(get<0>(typename T::ValueShape{}),
                                                            get<1>(typename T::ValueShape{})
                                                                / Int<detail::subgroup_size>{})));
};


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


} // end namespace detail


template <uint32_t dim, class Tensor_t>
static constexpr auto append_pvc_tensor(Tensor_t const &t0, uint32_t shape, uint32_t stride) {
  return make_tensor(make_inttuple_iter(t0.data()), append(t0.layout(), make_layout(shape, E<dim>{} * stride)));
}

template <class CopyOp, class StrideIndicator = cute::Stride<int64_t, cute::Int<1>, int64_t>>
struct XE_2D_LD_Unpack {

  using BlockShape = typename CopyOp::BlockShape;
  using Value_Layout = typename detail::value_layout_t<CopyOp>::type;
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


  template <class TS, class SLayout, class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr void
  copy_unpack(Traits_LD_t const &traits, Tensor<TS, SLayout> const &src,
              Tensor<TD, DLayout> &dst) {
    using dtype = typename Tensor<TD, DLayout>::value_type;
    constexpr int dtype_bits = sizeof_bits_v<dtype>;

    static_assert(is_rmem<TD>::value);
    // TODO(Codeplay): rnable this check once the coordinate refactoring is complete
    //static_assert(size(SLayout{}) * dtype_bits == size<1>(typename Traits_LD_t::SrcLayout{}),
      //            "Src tensor size does not match copy atom size");
    static_assert(size(DLayout{}) * dtype_bits == size<1>(typename Traits_LD_t::DstLayout{}),
                  "Dst tensor size does not match copy atom size");

    dtype *base_addr = (dtype *)traits.base_ptr;
  
    auto [m, n, l] = src.data().coord_;
    int x = is_need_reversed ? m : n;
    int y = is_need_reversed ? n : m;
    constexpr auto inst_size = detail::size_of_inst<CopyOp, dtype>;

    CopyOp::copy(base_addr + l * traits.stride_l,
                 traits.width * sizeof(dtype), traits.height,
                 traits.pitch * sizeof(dtype),
                 intel::coord_t{(int)(x * sizeof(dtype) / inst_size), y},
                 &*dst.data());
  }

  template <class... CA_Args, class TS, class SLayout>
  CUTE_HOST_DEVICE friend constexpr void
  prefetch(Copy_Atom<Traits_LD_t, CA_Args...> const &atom,
           Tensor<TS, SLayout> const &src) {
    static_assert(detail::has_prefetch<CopyOp>);

    using dtype = typename Copy_Atom<Traits_LD_t, CA_Args...>::ValType;

    dtype *base_addr = (dtype *)atom.base_ptr;

    auto [m, n, l] = src.data().coord_;

    CopyOp::PREFETCH::copy((void *)(base_addr + l * atom.stride_l),
                           atom.width * sizeof(dtype), atom.height,
                           atom.pitch * sizeof(dtype),
                           intel::coord_t{(int)n, (int)m});
  }

  template <class Coord, class GShape>
  CUTE_HOST_DEVICE constexpr auto get_pvc_tensor(Coord const &coord,
                                                 GShape const &shape) const {

    auto R = rank(GShape{});
    static_assert(R == 3, "mismatch rank");

    using basis_t =  make_seq<rank(BlockShape{})>;

    using shape_mn = std::conditional_t<is_convention_MN, BlockShape, decltype(reverse(BlockShape{}))>;

    auto new_shape = cute::tuple_cat(make_shape(_1{}), take<R - 2, R>(shape));
    auto new_stride = cute::tuple_cat(make_stride(_1{}), transform(basis_t{}, shape_mn{},
                                                                  [&](auto i, auto s){
                                                                      return E<i>{} * s;
                                                                  }));
    return make_tensor(make_inttuple_iter(coord),
                        make_layout(new_shape, new_stride));
  }

  template <class GCoord, class GShape, class GStride, class Basis = decltype(make_seq<rank(GStride{})>{})>
  CUTE_HOST_DEVICE constexpr auto get_pvc_tensor(GCoord const &coord,
                                                 GShape const &shape,
                                                 GStride const &stride, 
                                                 Basis const & basis = {}) const {

    auto R = rank(GShape{});
    static_assert(R == 3 || R == 4, "mismatch rank");
    auto t_shape = cute::tuple_cat(make_shape(_1{}), take<1, R>(shape));
    auto t_stride =  cute::tuple_cat(make_stride(_1{}), transform(basis, stride, [&](auto i, auto s){
        return E<i>{} * s;
    }));
    return make_tensor(make_inttuple_iter(coord),
                       make_layout(t_shape, t_stride));
  }

  // Generate the PVC coord tensor
  template <class GShape>
  CUTE_HOST_DEVICE constexpr
  auto
  get_pvc_tensor(GShape const& g_shape) const {
    static_assert(rank(GShape{}) == 3, "get_pvc_tensor only supports rank-3 tensors");
    return make_counting_tensor(make_layout(g_shape, make_stride(E<0>(), E<1>(), E<2>())));
  }

  template <class TLShape>
  CUTE_HOST_DEVICE constexpr auto make_fragment_layout(TLShape&& fragment_top_level_shape) const {
    auto [mma_atom_size, total_mma_atom_iters_M, total_mma_atom_iters_N] = fragment_top_level_shape;
    auto copy_size_M = size<0>(BlockShape{}); //TODO(Codeplay): We could use ValLayoutDst once it is consistent
    auto copy_size_N = size<1>(BlockShape{}) / size(typename Traits_LD_t::ThrID{});
    assert(copy_size_M >= mma_atom_size);
    auto mma_atom_iters_in_copy_M = copy_size_M / mma_atom_size;
    auto mma_atom_iters_in_copy_N = copy_size_N;
    auto copy_iters_M = total_mma_atom_iters_M / mma_atom_iters_in_copy_M;
    auto copy_iters_N = total_mma_atom_iters_N / mma_atom_iters_in_copy_N;
    auto order = std::conditional_t<is_convention_MN, Step<_0, Step<_1,_3>, Step<_2,_4>>, Step<_0, Step<_2,_4>, Step<_1,_3>>>{};
    return make_ordered_layout(make_shape(mma_atom_size, 
                                          make_shape(mma_atom_iters_in_copy_M, copy_iters_M), 
                                          make_shape(mma_atom_iters_in_copy_N, copy_iters_N)), order);
  };

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
  using Value_Layout = decltype(make_layout(make_shape(get<0>(BlockShape{}),
                                                       get<1>(BlockShape{})
                                                          / Int<detail::subgroup_size>{})));

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
                  "Src tensor size does not match copy atom size");
    // TODO(Codeplay): rnable this check once the coordinate refactoring is complete
    //static_assert(size(DLayout{}) * dtype_bits == size<1>(typename Traits_ST_t::DstLayout{}),
    //              "Dst tensor size does not match copy atom size");

    dtype *base_addr = (dtype *)traits.base_ptr;
    
    auto [m, n, l] = dst.data().coord_;

    CopyOp::copy(base_addr + l * traits.stride_l,
                 traits.width * sizeof(dtype), traits.height,
                 traits.pitch * sizeof(dtype),
                 intel::coord_t{(int)n, (int)m}, &*src.data());
  }

  template <class Coord, class GShape>
  CUTE_HOST_DEVICE constexpr auto get_pvc_tensor(Coord const &coord,
                                                 GShape const &shape) const {

    auto R = rank(GShape{});
    static_assert(R == 3, "mismatch rank");

    using basis_t =  make_seq<rank(BlockShape{})>;

    auto new_shape = cute::tuple_cat(make_shape(_1{}), take<R - 2, R>(shape));
    auto new_stride = cute::tuple_cat(make_stride(_1{}), transform(basis_t{}, BlockShape{},
                                                                  [&](auto i, auto s){
                                                                      return E<i>{} * s;
                                                                  }));
    return make_tensor(make_inttuple_iter(coord),
                        make_layout(new_shape, new_stride));
  }

  template <class GCoord, class GShape, class GStride, class Basis = decltype(make_seq<rank(GStride{})>{})>
  CUTE_HOST_DEVICE constexpr auto get_pvc_tensor(GCoord const &coord,
                                                 GShape const &shape,
                                                 GStride const &stride, 
                                                 Basis const & basis = {}) const {

    auto R = rank(GShape{});
    static_assert(R == 3 || R == 4, "mismatch rank");
    auto t_shape = cute::tuple_cat(make_shape(_1{}), take<1, R>(shape));
    auto t_stride =  cute::tuple_cat(make_stride(_1{}), transform(basis, stride, [&](auto i, auto s){
        return E<i>{} * s;
    }));
    return make_tensor(make_inttuple_iter(coord),
                       make_layout(t_shape, t_stride));
  }

  // Generate the PVC coord tensor
  template <class GShape>
  CUTE_HOST_DEVICE constexpr
  auto
  get_pvc_tensor(GShape const& g_shape) const {
    static_assert(rank(GShape{}) == 3, "get_pvc_tensor only supports rank-3 tensors");
    return make_counting_tensor(make_layout(g_shape, make_stride(E<0>(), E<1>(), E<2>())));
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

// clang-format off

template <class... args_t>
struct Copy_Traits<XE_2D_U8x1x32_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x1x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x2x32_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x2x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x4x32_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x4x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x8x32_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x8x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x16x32_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x16x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x32x32_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x32x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x1x64_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x1x64_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x1x64_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U8x2x64_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x2x64_LD_N, args_t...>(args...) {}
};


template <class... args_t>
struct Copy_Traits<XE_2D_U8x2x64_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U8x4x64_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U8x4x64_LD_N, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_8>,
                           Stride< _0,_1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _4>>,
                           Stride<_16,Stride< _1,_256,_512>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x4x64_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x4x64_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U8x8x64_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x8x64_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x8x64_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U8x16x64_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x16x64_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x16x64_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U8x32x64_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U8x32x64_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x32x64_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U16x1x16_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U16x1x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x2x16_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U16x2x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x4x16_LD_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U16x4x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x8x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x8x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x8x16_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U16x16x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x16x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x16x16_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U16x32x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x32x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x32x16_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U16x1x32_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x1x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x1x32_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U16x2x32_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x2x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x2x32_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U16x4x32_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x4x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x4x32_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U16x8x32_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x8x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x8x32_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U16x16x32_LD_N, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x16x32_LD_N, args_t...> {
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x16x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x16x32_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U16x32x32_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x32x32_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x32x32_LD_N::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_TF32x1x8_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x1x8_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_TF32x2x8_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x2x8_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_TF32x4x8_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x4x8_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_TF32x8x8_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x8x8_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_TF32x16x8_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x16x8_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_TF32x32x8_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x32x8_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_TF32x1x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x1x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_TF32x2x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x2x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_TF32x4x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x4x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_TF32x8x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x8x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_TF32x16x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x16x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_TF32x32x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_TF32x32x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x1x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x1x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x2x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x2x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x4x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x4x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x8x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x8x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x16x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x16x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x32x16_LD_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x32x16_LD_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x32x16_LD_V, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U8x32x16_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x32x16_LD_V::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U8x32x32_LD_V, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U8x32x32_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x32x64_LD_V, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U8x32x64_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x16x16_LD_V, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x16x16_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x32x16_LD_V, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x32x16_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x32x32_LD_V, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x32x32_LD_V, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_1024>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _2,  _16>>,
                           Stride<_16,Stride< _1,_512,_256,_1024>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x32x32_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x16x32_LD_V, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x16x32_LD_V, args_t...> {
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_512>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape <_16,Shape <_16,  _2,  _2,   _8>>,
                           Stride<_16,Stride< _1,_512,_256,_1024>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgTs>
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U16x16x32_LD_V, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x16x8_LD_T, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_LD_Unpack<XE_2D_U16x16x8_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x16x16_LD_T, args_t...>
    : XE_2D_LD_Unpack<XE_2D_U16x16x16_LD_T, args_t...> {
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape <_16,_256>,
                           Stride< _0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape < _16,Shape <_16,_16>>,
                           Stride<_256,Stride< _1,_16>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;

  template <class... ArgT>
  Copy_Traits(ArgT... args)
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
struct Copy_Traits<XE_2D_U32x16x2_LD_T, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x16x2_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x16x4_LD_T, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x16x4_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x16x8_LD_T, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U32x16x8_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x16x8_LD_T::PREFETCH, args_t...>
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
struct Copy_Traits<XE_2D_U64x8x1_LD_T, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U64x8x1_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U64x8x2_LD_T, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U64x8x2_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U64x8x4_LD_T, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_LD_Unpack<XE_2D_U64x8x4_LD_T, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x2x32_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U8x2x32_ST_N, args_t...> {
  using BlockShape = Shape<_2,_32>;
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
  Copy_Traits(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U8x2x32_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x1x16_ST_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_ST_Unpack<XE_2D_U8x1x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x2x16_ST_N, args_t...>
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
  Copy_Traits(ArgTs... args)
      : XE_2D_ST_Unpack<XE_2D_U8x2x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x4x16_ST_N, args_t...>
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
struct Copy_Traits<XE_2D_U8x8x16_ST_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U8x8x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U8x8x32_ST_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U8x8x32_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x1x16_ST_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U16x1x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x2x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U16x2x16_ST_N, args_t...> {
  using BlockShape = Shape<_2, _16>;
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
  Copy_Traits(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U16x2x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x4x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U16x4x16_ST_N, args_t...> {
  using BlockShape = Shape<_4, _16>;
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
  Copy_Traits(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U16x4x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U16x8x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U16x8x16_ST_N, args_t...> {
  using BlockShape = Shape<_8, _16>;
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
  Copy_Traits(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U16x8x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x1x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U32x1x16_ST_N, args_t...> {
  using BlockShape = Shape<_1, _16>;
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
  Copy_Traits(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U32x1x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x2x16_ST_N, args_t...>
    : XE_2D_ST_Unpack<XE_2D_U32x2x16_ST_N, args_t...> {
  using BlockShape = Shape<_2, _16>;
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
  Copy_Traits(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U32x2x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x4x16_ST_N, args_t...>
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
  Copy_Traits(ArgT... args)
      : XE_2D_ST_Unpack<XE_2D_U32x4x16_ST_N, args_t...>(args...) {}
};

template <class... args_t>
struct Copy_Traits<XE_2D_U32x8x16_ST_N, args_t...>
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
  Copy_Traits(ArgTs... args)
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

namespace detail
{
  //TODO:: THIS SHOULD GET DEPRECATED
  template<class PrefetchTileSize, class dtype>
  auto prefetch_selector(void* ptr = nullptr, int32_t width = 0, int32_t height = 0, int32_t pitch = 0) {
    if constexpr (get<0>(PrefetchTileSize{}) == 1) {
      using prefetch_trait = Copy_Traits<XE_2D_U8x1x64_LD_N>;
      using prefetch_atom = Copy_Atom<prefetch_trait, dtype>;
      return make_tiled_copy(prefetch_atom{}.with(static_cast<dtype const*>(ptr), width, height, pitch),
                                           Layout<Shape<_1, _16>>{},
                                           Layout<Shape<_2, _2>>{});
    }
    else if constexpr (get<0>(PrefetchTileSize{}) == 2) {
      using prefetch_trait = Copy_Traits<XE_2D_U8x2x64_LD_N>;
      using prefetch_atom = Copy_Atom<prefetch_trait, dtype>;
      return make_tiled_copy(prefetch_atom{}.with(static_cast<dtype const*>(ptr), width, height, pitch),
                                           Layout<Shape<_1, _16>>{},
                                           Layout<Shape<_2, _2, _2>>{});
    }
    else if constexpr (get<0>(PrefetchTileSize{}) == 4) {
      using prefetch_trait = Copy_Traits<XE_2D_U8x4x64_LD_N>;
      using prefetch_atom = Copy_Atom<prefetch_trait, dtype>;
      return make_tiled_copy(prefetch_atom{}.with(static_cast<dtype const*>(ptr), width, height, pitch),
                                           Layout<Shape<_1, _16>>{},
                                           Layout<Shape<_2, _2, _4>>{});
    }
    else if constexpr (get<0>(PrefetchTileSize{}) == 8) {
      using prefetch_trait = Copy_Traits<XE_2D_U8x8x64_LD_N>;
      using prefetch_atom = Copy_Atom<prefetch_trait, dtype>;
      return make_tiled_copy(prefetch_atom{}.with(static_cast<dtype const*>(ptr), width, height, pitch),
                                           Layout<Shape<_1, _16>>{},
                                           Layout<Shape<_2, _2, _8>>{});
    }
    else if constexpr (get<0>(PrefetchTileSize{}) == 16) {
      using prefetch_trait = Copy_Traits<XE_2D_U8x16x64_LD_N>;
      using prefetch_atom = Copy_Atom<prefetch_trait, dtype>;
      return make_tiled_copy(prefetch_atom{}.with(static_cast<dtype const*>(ptr), width, height, pitch),
                                           Layout<Shape<_1, _16>>{},
                                           Layout<Shape<_2, _2, _16>>{});
    }
    else if constexpr (get<0>(PrefetchTileSize{}) == 32) {
      using prefetch_trait = Copy_Traits<XE_2D_U8x32x64_LD_N>;
      using prefetch_atom = Copy_Atom<prefetch_trait, dtype>;
      return make_tiled_copy(prefetch_atom{}.with(static_cast<dtype const*>(ptr), width, height, pitch),
                                           Layout<Shape<_1, _16>>{},
                                           Layout<Shape<_2, _2, _32>>{});
    }
    else{
      static_assert(dependent_false<PrefetchTileSize> && "Invalid PrefetchTileSize[0]");
    }
  }
 
template<typename PrefetchShape, class Stride, class dtype, int subgroupsize, class Tensor >
  CUTE_HOST_DEVICE  auto make_prefetch(Tensor const& tensor) {
      using prefetch_trait = Copy_Traits<PrefetchShape, Stride>;
      using prefetch_atom = Copy_Atom<prefetch_trait, dtype>;

      return make_tiled_copy(prefetch_atom{}.with(tensor),
                                      Layout<Shape<_1, Int<subgroupsize>>>{},
                                      make_layout(make_shape(get<0>(typename prefetch_trait::BlockShape{}),
                                                             get<1>(typename prefetch_trait::BlockShape{}) / Int<subgroupsize>{})));
    }
// Define macros to map types to their corresponding sizes
#define TYPE_BITS_float(row) XE_2D_U32##x##row##x##16_LD_N
#define TYPE_BITS_bfloat16_t(row) XE_2D_U16##x##row##x##32_LD_N
#define TYPE_BITS_int8_t(row) XE_2D_U8##x##row##x##64_LD_N
#define TYPE_BITS_tfloat32_t(row) XE_2D_TF32##x##row##x##16_LD_N

#define SELECT_BITS(type, row) TYPE_BITS_##type(row)
// Template to dynamically construct and return the type
template <typename T, int row>
struct XePrefetchConstructor {
       static_assert( "Invalid PrefetchTileSize and type"); 
};

#define BUILD_XE_NAME(row)\
template <>\
struct XePrefetchConstructor<float, row> {\
  using type_t = TYPE_BITS_float(row);\
};\
template <>\
struct XePrefetchConstructor<bfloat16_t, row> {\
  using type_t = TYPE_BITS_bfloat16_t(row);\
};\
template <>\
struct XePrefetchConstructor<half_t, row> {\
  using type_t = TYPE_BITS_bfloat16_t(row);\
};\
template <>\
struct XePrefetchConstructor<int8_t, row> {\
  using type_t = TYPE_BITS_int8_t(row);\
};\
template <>\
struct XePrefetchConstructor<tfloat32_t, row> {\
using type_t = TYPE_BITS_tfloat32_t(row);\
};\


BUILD_XE_NAME(1)
BUILD_XE_NAME(2)
BUILD_XE_NAME(4)
BUILD_XE_NAME(8)
BUILD_XE_NAME(16)
BUILD_XE_NAME(32)

#undef TYPE_BITS_float
#undef TYPE_BITS_bfloat16_t
#undef TYPE_BITS_int8_t
#undef BUILD_XE_NAME

   template<class PrefetchTileSize, class dtype, class Stride, int SubgroupSize, class Tensor>
   CUTE_HOST_DEVICE auto prefetch_selector(Tensor const& tensor) {
    if constexpr (get<0>(PrefetchTileSize{}) == 1)
      return make_prefetch<typename XePrefetchConstructor<dtype, 1>::type_t, Stride, dtype, SubgroupSize>(tensor);
    else if constexpr (get<0>(PrefetchTileSize{}) == 2)
      return make_prefetch<typename XePrefetchConstructor<dtype, 2>::type_t, Stride, dtype, SubgroupSize>(tensor);
    else if constexpr (get<0>(PrefetchTileSize{}) == 4)
      return make_prefetch<typename XePrefetchConstructor<dtype, 4>::type_t, Stride, dtype, SubgroupSize>(tensor);
    else if constexpr (get<0>(PrefetchTileSize{}) == 8)
      return make_prefetch<typename XePrefetchConstructor<dtype, 8>::type_t, Stride, dtype, SubgroupSize>(tensor);
    else if constexpr (get<0>(PrefetchTileSize{}) == 16)
      return make_prefetch<typename XePrefetchConstructor<dtype, 16>::type_t, Stride, dtype, SubgroupSize>(tensor);
    else if constexpr (get<0>(PrefetchTileSize{}) == 32)
      return make_prefetch<typename XePrefetchConstructor<dtype, 32>::type_t, Stride, dtype, SubgroupSize>(tensor); 
    else
      static_assert(dependent_false<PrefetchTileSize> && "Invalid PrefetchTileSize[0]");
  }
} // end namespace detail

template <class TiledCopy, class ThrIdx>
class Xe2DThrCopy : ThrCopy<TiledCopy, ThrIdx> {

public:

  CUTE_HOST_DEVICE
  Xe2DThrCopy(ThrIdx const& thr_idx) : ThrCopy<TiledCopy, ThrIdx> (thr_idx) {}

  template <class DTensor>
  CUTE_HOST_DEVICE
  auto
  retile_D(DTensor&& dtensor) {
    if constexpr (!TiledCopy::is_convention_MN) {
      return retile_D_nkl(dtensor);
    } else {
      return retile_D_mkl(dtensor);
    }
  }

  template <class MMA, class MMATensor>
  CUTE_HOST_DEVICE
  auto
  retile_MMA(MMA const&, MMATensor&& mma_tensor) {
    if constexpr (TiledCopy::is_convention_MN) {
      static constexpr auto m = decltype(size<1>(mma_tensor.shape()))::value;
      static constexpr auto k = decltype(size<2>(mma_tensor.shape()))::value;
      static constexpr auto m_step = size<0>(typename TiledCopy::BlockShape{})
                                        / size<0>(typename MMA::Shape_MNK{});
      static constexpr auto k_step = size<1>(typename TiledCopy::BlockShape{})
                                        / size<2>(typename MMA::Shape_MNK{});

      auto retiled_tensor = make_tensor(mma_tensor.data(),
                                        make_shape(size<0>(mma_tensor.shape()),
                                                   Int<m_step>{},
                                                   Int<k_step>{},
                                                   Int<m / m_step>{},
                                                   Int<k / k_step>{}));
      return make_tensor(mma_tensor.data(),group<2, 4>(group<1, 3>(select<0, 1, 3, 2, 4>(retiled_tensor.layout()))));
    } else {
      static constexpr auto k = decltype(size<2>(mma_tensor.shape()))::value;
      static constexpr auto k_step = size<0>(typename TiledCopy::BlockShape{})
                                      / size<2>(typename MMA::Shape_MNK{});

      auto retiled_tensor = make_tensor(mma_tensor.data(),
                                        make_shape(size<0>(mma_tensor.shape()),
                                                   Int<k_step>{},
                                                   size<1>(mma_tensor.shape()),
                                                   Int<k / k_step>{}));
      return make_tensor(mma_tensor.data(),group<2, 4>(select<0, 2, 1, 3>(retiled_tensor.layout())));
    }
  }

private:

  template <class DTensor>
  CUTE_HOST_DEVICE static
  auto
  retile_D_mkl(DTensor&& dtensor) {
    auto tmp = ThrCopy<TiledCopy, ThrIdx>::retile_D(dtensor);
    return make_tensor(static_cast<decltype(tmp) &&>(tmp).data(),
                           tmp.shape());
  }

  template <class DTensor>
  CUTE_HOST_DEVICE static
  auto
  retile_D_nkl(DTensor&& dtensor) {
    auto b_tensor = make_tensor(dtensor.data(),
                               make_shape(size<0>(dtensor.shape()),
                                         size<2>(dtensor.shape()),
                                         size<1>(dtensor.shape())));
    auto tmp = ThrCopy<TiledCopy, ThrIdx>::retile_D(b_tensor);
    return make_tensor(static_cast<decltype(tmp) &&>(tmp).data(),
                       make_shape(size<0>(tmp.shape()),
                                  size<2>(tmp.shape()),
                                  size<1>(tmp.shape())));
  }
};

template <class Copy_Atom,
          class LayoutCopy_TV,  // (tid,vid) -> coord   [Need not be 2D...]
          class ShapeTiler_MN>  // coord space
struct Xe2DTiledCopy : TiledCopy<Copy_Atom, LayoutCopy_TV, ShapeTiler_MN>{

  template <class ThrIdx,
            __CUTE_REQUIRES(is_integral<ThrIdx>::value)>
  CUTE_HOST_DEVICE
  auto
  get_slice(ThrIdx const& thr_idx) const
  {
    return Xe2DThrCopy<Xe2DTiledCopy, ThrIdx>(thr_idx);
  }
};

template <class... Args,
          class ThrLayout,
          class ValLayout = typename Copy_Atom<Args...>::Value_Layout>
CUTE_HOST_DEVICE
auto
make_xe_2d_copy(Copy_Atom<Args...> const& copy_atom,
                ThrLayout          const& thr_layout = {},     // (m,n) -> thr_idx
                ValLayout          const& val_layout = {})     // (m,n) -> val_idx
{
  // Take the raked_products to compute the Layout_MN
  // (M,N) -> (thr_idx, val_idx)
  auto layout_mn = raked_product(thr_layout, val_layout);
  // (thr_idx, val_idx) -> (M,N)
  auto layout_tv = right_inverse(layout_mn).with_shape(make_shape(size(thr_layout), size(val_layout)));
  // Tiler for extracting relevant elements
  // (M,N) -> tensor coord
  auto tiler = product_each(shape(layout_mn));

#if 0
  print("thr_layout: "); print(thr_layout); print("\n");
  print("val_layout: "); print(val_layout); print("\n");
  print("layout_mn : "); print(layout_mn);  print("\n");
  print("layout_tv : "); print(layout_tv);  print("\n");
  print("tiler     : "); print(tiler);      print("\n");
#endif

  return Xe2DTiledCopy<Copy_Atom<Args...>, decltype(layout_tv), decltype(tiler)>{copy_atom};
}

// The number of threads involved in a Xe2DTiledCopy
template <class... Args>
CUTE_HOST_DEVICE constexpr
auto
size(Xe2DTiledCopy<Args...> const&)
{
  return typename Xe2DTiledCopy<Args...>::TiledNumThr{};
}

template <class CopyAtom, class TV, class Tiler,
          class SrcEngine, class SrcLayout,
          class DstEngine, class DstLayout>
CUTE_HOST_DEVICE
void
copy(Xe2DTiledCopy<CopyAtom, TV, Tiler> const& tiled_copy,
     Tensor<SrcEngine, SrcLayout>   const& src,
     Tensor<DstEngine, DstLayout>        & dst)
{
  return copy(static_cast<CopyAtom const&>(tiled_copy), src, dst);
}

} // end namespace cute
