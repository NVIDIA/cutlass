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

#include <cute/arch/copy_xe.hpp>

namespace cute
{
template <class CopyOp, class GTensor>
struct XE_2D_LD_Unpack
{
  GTensor tensor;

  using Copy_Traits = Copy_Traits<CopyOp, GTensor>;
  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr void
  copy_unpack(Copy_Traits const &traits,
              Tensor<ViewEngine<ArithmeticTupleIterator<TS>>, SLayout> const &src,
              Tensor<TD, DLayout> &dst)
  {
      static_assert(is_rmem<TD>::value);
      int H = size<0>(traits.tensor);
      int W = size<1>(traits.tensor) * sizeof(typename Copy_Traits::CopyInternalType);
      auto [y, x, z] = src.data().coord_;
      CopyOp::copy(traits.tensor.data() + z, W, H, W, intel::coord_t{x, y}, &*dst.data());
  }

  template <class GCoord, class GShape, class GStride>
  CUTE_HOST_DEVICE constexpr auto
  get_pvc_tensor(GCoord const& coord, GShape const& shape, GStride const& stride_mul) const 
  {
    return make_tensor(make_inttuple_iter(coord), 
                        make_layout(make_shape(_1{}, get<0>(shape), get<1>(shape), get<2>(shape)), 
                                    make_stride(_1{}, E<0>{} * get<0>(stride_mul), E<1>{} * get<1>(stride_mul), E<2>{} * get<2>(stride(tensor)))));
  }
};

template <class GTensor>
struct Copy_Traits<XE_2D_U16x8x16x1x1_LD_N, GTensor>
     : XE_2D_LD_Unpack<XE_2D_U16x8x16x1x1_LD_N, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout =
    Layout<Shape<_16, Shape<_8, _16>>, Stride<_16, Stride<_256, _1>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;

};

template <class GTensor>
struct Copy_Traits<XE_2D_U32x8x16x1x1_LD_N, GTensor>
     : XE_2D_LD_Unpack<XE_2D_U32x8x16x1x1_LD_N, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout =
    Layout<Shape<_16, Shape<_8, _32>>, Stride<_32, Stride<_512, _1>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = uint;
};

template <class GTensor>
struct Copy_Traits<XE_2D_U16x8x16x4x2_LD_N, GTensor>
     : XE_2D_LD_Unpack<XE_2D_U16x8x16x4x2_LD_N, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout =
      Layout<Shape<_16, Shape<Shape<_8, _4>, Shape<_16, _2>>>,
             Stride<_16, Stride<Stride<_512, _4096>, Stride<_1, _256>>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class GTensor>
struct Copy_Traits<XE_2D_U16x8x16x2x2_LD_N, GTensor>
     : XE_2D_LD_Unpack<XE_2D_U16x8x16x2x2_LD_N, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout =
      Layout<Shape<_16, Shape<Shape<_8, _2>, Shape<_16, _2>>>,
             Stride<_16, Stride<Stride<_512, _4096>, Stride<_1, _256>>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class GTensor>
struct Copy_Traits<XE_2D_U16x8x16x1x2_LD_N, GTensor>
     : XE_2D_LD_Unpack<XE_2D_U16x8x16x1x2_LD_N, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_16, Shape<_8, Shape<_16, _2>>>,
                           Stride<_16, Stride<_512, Stride<_1, _256>>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class GTensor>
struct Copy_Traits<XE_2D_U16x8x16x4x1_LD_N, GTensor>
     : XE_2D_LD_Unpack<XE_2D_U16x8x16x4x1_LD_N, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout =
      Layout<Shape<_16, Shape<_32, _16>>, Stride<_16, Stride<_256, _1>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class GTensor>
struct Copy_Traits<XE_2D_U32x8x16x2x1_LD_N, GTensor>
     : XE_2D_LD_Unpack<XE_2D_U32x8x16x2x1_LD_N, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout =
      Layout<Shape<_16, Shape<_16, _32>>, Stride<_32, Stride<_512, _1>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  // 32 bits register file
  using CopyInternalType = uint;
};

template <class GTensor>
struct Copy_Traits<XE_2D_U16x16x16x2x1_LD_N, GTensor>
     : XE_2D_LD_Unpack<XE_2D_U16x16x16x2x1_LD_N, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout =
      Layout<Shape<_16, Shape<_16, _32>>, Stride<_32, Stride<_512, _1>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  // 32 bits register file
  using CopyInternalType = uint;
};

template <class GTensor>
struct Copy_Traits<XE_2D_U16x16x16x2x2_V, GTensor>
     : XE_2D_LD_Unpack<XE_2D_U16x16x16x2x2_V, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout =
      Layout< Shape<_16,  Shape< Shape<   _8,    _2>,  Shape<_16,   _2,   _2>>>,
             Stride<_16, Stride<Stride<_1024, _8192>, Stride< _1, _512, _256>>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class GTensor>
struct Copy_Traits<XE_2D_U16x16x16x1x2_V, GTensor>
     : XE_2D_LD_Unpack<XE_2D_U16x16x16x1x2_V, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout =
      Layout< Shape<_16,  Shape<   _8,  Shape<_16,   _2,   _2>>>,
             Stride<_16, Stride<_1024, Stride< _1, _512, _256>>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class GTensor>
struct Copy_Traits<XE_2D_U16x16x16x2x1_V, GTensor>
     : XE_2D_LD_Unpack<XE_2D_U16x16x16x2x1_V, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout =
      Layout< Shape<_16,  Shape<Shape<_8, _2>, Shape<_16, _2>>>,
             Stride<_16, Stride<Stride<_512, _4096>, Stride<_1, _256>>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class GTensor>
struct Copy_Traits<XE_2D_U16x16x16x1x1_V, GTensor>
     : XE_2D_LD_Unpack<XE_2D_U16x16x16x1x1_V, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout =
      Layout< Shape<_16,  Shape<_8,    Shape<_16, _2>>>,
             Stride<_16, Stride<_512, Stride<_1, _256>>>>;
  // Reference map from (thr,val) to bit
  using RefLayout = DstLayout;
  using CopyInternalType = ushort;
};

template <class CopyOp, class GTensor>
struct XE_2D_ST_Unpack
{
  GTensor tensor;
  using Copy_Traits = Copy_Traits<CopyOp, GTensor>;
  template <class TS, class SLayout,
            class TD, class DLayout>
  CUTE_HOST_DEVICE friend constexpr void
  copy_unpack(Copy_Traits const &traits,
              Tensor<TS, SLayout> const &src,
              Tensor<ViewEngine<ArithmeticTupleIterator<TD>>, DLayout> &dst)
  {
      static_assert(is_rmem<TS>::value);
      int H = size<0>(traits.tensor);
      int W = size<1>(traits.tensor) * sizeof(typename Copy_Traits::CopyInternalType);
      auto [y, x, z] = dst.data().coord_;
      CopyOp::copy(traits.tensor.data() + z, W, H, W, intel::coord_t{x, y}, &*src.data());
  }

  template <class GCoord, class GShape, class GStride>
  CUTE_HOST_DEVICE constexpr auto
  get_pvc_tensor(GCoord const& coord, GShape const& shape, GStride const& stride_mul) const 
  {
    return make_tensor(make_inttuple_iter(coord), 
                        make_layout(make_shape(_1{}, get<0>(shape), get<1>(shape), get<2>(shape)), 
                                    make_stride(_1{}, E<0>{} * get<0>(stride_mul), E<1>{} * get<1>(stride_mul), E<2>{} * get<2>(stride(tensor)))));
  }
};

template <class GTensor>
struct Copy_Traits<XE_2D_U32x8x16x1x1_ST_N, GTensor>
     : XE_2D_ST_Unpack<XE_2D_U32x8x16x1x1_ST_N, GTensor>
{
  // Logical thread id to thread idx
  using ThrID = Layout<_16>;
  // Map from (src-thr,src-val) to bit
  using SrcLayout =
    Layout<Shape<_16, Shape<_8, _32>>, Stride<_32, Stride<_512, _1>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_16, _64>, Stride<_0, _1>>;
  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;
  using CopyInternalType = uint;
};

template <class Copy, class GEngine, class GLayout>
auto make_xe_2d_copy(Tensor<GEngine, GLayout> gtensor)
{
    using GTensor = Tensor<GEngine, GLayout>;
    using Traits = Copy_Traits<Copy, GTensor>;
    Traits traits{gtensor};
    return Copy_Atom<Traits, typename GEngine::value_type>{traits};
}
} // end namespace cute
