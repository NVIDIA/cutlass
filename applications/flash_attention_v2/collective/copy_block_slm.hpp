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

namespace cute {

/* Flat copies */
template <class SrcEngine, class SrcLayout,
          class DstEngine, class DstLayout>
CUTE_HOST_DEVICE
void
copy_block_r2s(Tensor<SrcEngine, SrcLayout> const& src,
               Tensor<DstEngine, DstLayout>      & dst)
{
  static_assert(is_rmem_v<SrcEngine> && is_smem_v<DstEngine>, "Expected rmem->smem copy");

  auto atom_r2s = Copy_Atom<XE_1D_STSM<float>, float>{};    // TODO: larger block messages

  auto atom_shape = make_shape(_1{}, size(src));
  auto src_v = src.compose(make_layout(atom_shape));
  auto dst_v = dst.compose(make_layout(atom_shape, Stride<_0, _16>{}));

  copy(atom_r2s, src_v, dst_v);
}

template <class SrcEngine, class SrcLayout,
          class DstEngine, class DstLayout>
CUTE_HOST_DEVICE
void
copy_block_s2r(Tensor<SrcEngine, SrcLayout> const& src,
               Tensor<DstEngine, DstLayout>      & dst)
{
  static_assert(is_smem_v<SrcEngine> && is_rmem_v<DstEngine>, "Expected smem->rmem copy");

  auto atom_s2r = Copy_Atom<XE_1D_LDSM<float>, float>{};

  auto atom_shape = make_shape(_1{}, size(dst));
  auto src_v = src.compose(make_layout(atom_shape, Stride<_0, _16>{}));
  auto dst_v = dst.compose(make_layout(atom_shape));

  copy(atom_s2r, src_v, dst_v);
}

/* Coordinate-aware copies */
template <class SrcEngine, class SrcLayout, class SrcCoordLayout,
          class DstEngine, class DstLayout, class DstCoordLayout>
CUTE_HOST_DEVICE
void
copy_block_r2s(SubgroupTensor<SrcEngine, SrcLayout, SrcCoordLayout> const& src,
               Tensor<DstEngine, DstLayout>                              & dst,
               DstCoordLayout                                       const& dst_c)
{
  using _SG = intel::_SGSize;

  static_assert(is_rmem_v<SrcEngine> && is_smem_v<DstEngine>, "Expected rmem->smem copy");
  static_assert(sizeof_bits_v<typename SrcEngine::value_type> == 32, "Only 32-bit data supported");

  auto atom_r2s = Copy_Atom<XE_1D_STSM<float>, float>{};    // TODO: larger block messages

  auto atom_shape = make_shape(_1{}, size(SrcLayout{}));

  auto src_c_wi0 = composition(project_strides(SrcCoordLayout{}), make_layout(atom_shape, Stride<_0, _SG>{}));
  auto rlayout = composition(right_inverse(project_strides(dst_c)), src_c_wi0);

  auto src_v = src.compose(make_layout(atom_shape));
  auto dst_v = dst.compose(rlayout);

  copy(atom_r2s, src_v, dst_v);
}

template <class SrcEngine, class SrcLayout, class SrcCoordLayout,
          class DstEngine, class DstLayout, class DstCoordLayout>
CUTE_HOST_DEVICE
void
copy_block_s2r(Tensor<SrcEngine, SrcLayout>                         const& src,
               SrcCoordLayout                                       const& src_c,
               SubgroupTensor<DstEngine, DstLayout, DstCoordLayout>      & dst)
{
  using _SG = intel::_SGSize;

  static_assert(is_smem_v<SrcEngine> && is_rmem_v<DstEngine>, "Expected smem->rmem copy");
  static_assert(sizeof_bits_v<typename SrcEngine::value_type> == 32, "Only 32-bit data supported");

  auto atom_s2r = Copy_Atom<XE_1D_LDSM<float>, float>{};

  auto atom_shape = make_shape(_1{}, size(DstLayout{}));

  auto dst_c_wi0 = composition(project_strides(DstCoordLayout{}), make_layout(atom_shape, Stride<_0, _SG>{}));
  auto rlayout = composition(right_inverse(project_strides(src_c)), dst_c_wi0);

  auto src_v = src.compose(rlayout);
  auto dst_v = dst.compose(make_layout(atom_shape));

  copy(atom_s2r, src_v, dst_v);
}

/* Variants accepting rvalue dst */
template <class SrcEngine, class SrcLayout,
          class DstEngine, class DstLayout>
CUTE_HOST_DEVICE
void
copy_block_r2s(Tensor<SrcEngine, SrcLayout> const& src,
               Tensor<DstEngine, DstLayout>     && dst)
{
  return copy_block_r2s(src, dst);
}

template <class SrcEngine, class SrcLayout,
          class DstEngine, class DstLayout>
CUTE_HOST_DEVICE
void
copy_block_s2r(Tensor<SrcEngine, SrcLayout> const& src,
               Tensor<DstEngine, DstLayout>     && dst)
{
  return copy_block_s2r(src, dst);
}

template <class SrcEngine, class SrcLayout, class SrcCoordLayout,
          class DstEngine, class DstLayout, class DstCoordLayout>
CUTE_HOST_DEVICE
void
copy_block_r2s(SubgroupTensor<SrcEngine, SrcLayout, SrcCoordLayout> const& src,
               Tensor<DstEngine, DstLayout>                             && dst,
               DstCoordLayout                                       const& dst_c)
{
  return copy_block_r2s(src, dst, dst_c);
}

template <class SrcEngine, class SrcLayout, class SrcCoordLayout,
          class DstEngine, class DstLayout, class DstCoordLayout>
CUTE_HOST_DEVICE
void
copy_block_s2r(Tensor<SrcEngine, SrcLayout>                         const& src,
               SrcCoordLayout                                       const& src_c,
               SubgroupTensor<DstEngine, DstLayout, DstCoordLayout>     && dst)
{
  return copy_block_s2r(src, dst);
}

} /* namespace cute */