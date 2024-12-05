/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cute/layout.hpp"
#include "cute/tensor.hpp"

#include "cutlass/util/device_memory.h"

// Given a type of MMA instruction, compute a memory reordering atom that places all values
// owned by each thread in contiguous memory locations. This improves smem load vectorization,
// particularly for mixed dtype GEMMs where a narrow type is loaded in the thread/value order
// of the wider type and may result in inefficient sub-bank (8-bit or 16-bit) accesses.
template<class MmaType>
auto compute_memory_reordering_atom()
{
  using namespace cute;

  // 1. Choose an MMA atom to access TV layout and MN shape
  // Note: parameters like GMMA Major, TileShape, ElementC don't affect TV layout of A, use arbitrary
  using MmaAtom = decltype(SM90::GMMA::rs_op_selector<MmaType, MmaType, float, Shape<_64,_16,_32>>());
  using MmaTraits = MMA_Traits<MmaAtom>;
  auto shape_MK = select<0,2>(typename MmaTraits::Shape_MNK{});
  auto tv_layout_mma = typename MmaTraits::ALayout{};

  // 2. Create a single warp's TV layout from that of the whole MMA
  // Note: this assumes A is partitioned between warps along M mode
  auto tile_TV_warp = make_shape(Int<32>{}, size<1>(tv_layout_mma));
  auto tv_layout_mma_warp = make_layout_like(composition(tv_layout_mma, tile_TV_warp));

  // 3. Invert warp's TV layout to get MK layout (m,k -> thr,val)
  auto shape_MK_warp = shape_div(shape_MK, size(typename MmaTraits::ThrID{}) / Int<32>{});
  auto mk_layout_mma_warp = right_inverse(tv_layout_mma_warp).with_shape(shape_MK_warp);

  // 4. Compose with a contiguous layout of values in each thread (required for smem vectorization)
  auto tv_to_offset = make_ordered_layout(shape(tv_layout_mma_warp), Step<_1,_0>{});
  auto layout_atom = composition(tv_to_offset, mk_layout_mma_warp);

  return layout_atom;
}

template<class EngineSrc, class LayoutSrc, class EngineDst, class LayoutDst>
__global__ void reorder_tensor_kernel(
  cute::Tensor<EngineSrc, LayoutSrc> src,
  cute::Tensor<EngineDst, LayoutDst> dst)
{
  auto i = blockIdx.x;
  auto k = blockIdx.y;
  for (int j = threadIdx.x; j < cute::size<1>(src); j += blockDim.x) {
    dst(i,j,k) = src(i,j,k);
  }
}

template<class EngineSrc, class LayoutSrc, class EngineDst, class LayoutDst>
void reorder_tensor(
  cute::Tensor<EngineSrc, LayoutSrc> t_src,
  cute::Tensor<EngineDst, LayoutDst> t_dst)
{
  using T = typename EngineDst::value_type;
  static_assert(cute::is_same_v<cute::remove_const_t<typename EngineSrc::value_type>, T>, "Type mismatch");
  using V = cute::uint_bit_t<cute::max(8, cute::sizeof_bits_v<T>)>;

  cute::Tensor v_src = cute::recast<V>(t_src);
  cute::Tensor v_dst = cute::recast<V>(t_dst);

  int threads = 256;
  dim3 blocks{unsigned(cute::size<0>(v_src)), unsigned(cute::size<2>(v_src)), 1u};

  reorder_tensor_kernel<<<blocks, threads>>>(v_src, v_dst);
  CUDA_CHECK(cudaDeviceSynchronize());
}

// In-place version
template<class T, class LayoutSrc, class LayoutDst>
void reorder_tensor(
  T const* src,
  LayoutSrc const& layout_src,
  T * dst,
  LayoutDst const& layout_dst)
{
  reorder_tensor(make_tensor(src, layout_src),
                 make_tensor(dst, layout_dst));
}

// In-place version
template<class T, class LayoutSrc, class LayoutDst>
void reorder_tensor(
  T * data,
  LayoutSrc const& layout_src,
  LayoutDst const& layout_dst)
{
  cutlass::DeviceAllocation<T> temp(cute::size(layout_src));
  reorder_tensor(data, layout_src, temp.get(), layout_dst);
  cutlass::device_memory::copy_device_to_device(data, temp.get(), static_cast<size_t>(cute::size(layout_src)));
}