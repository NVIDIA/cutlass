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
#include "cute/arch/mma_sm90.hpp"

#include "cutlass/util/device_memory.h"

// Given a type of MMA instruction, compute a memory reordering atom that places all values
// owned by each thread in contiguous memory locations. This improves smem load vectorization,
// particularly for mixed dtype GEMMs where a narrow type is loaded in the thread/value order
// of the wider type and may result in inefficient sub-bank (8-bit or 16-bit) accesses.
// In addition, we can reorder the values across several MMA instructions to get even wider
// vectorization (AtomLayout parameter) and permute the values within each instruction to get
// more optimal conversion instruction sequences (ValLayout parameter).
template<class ElementMma, 
         class AtomLayout = cute::Layout<cute::_1>,
         class ValLayout  = cute::Layout<cute::_1>>
constexpr auto compute_memory_reordering_atom(AtomLayout atom_layout = {}, ValLayout val_layout = {})
{
  using namespace cute;

  static_assert(is_static_v<ValLayout>, "ValLayout must be static");
  static_assert(is_static_v<AtomLayout>, "AtomLayout must be static");

  // 1. Choose an MMA atom to access TV layout and MN shape
  // Note: parameters like GMMA Major, TileShape, ElementC don't affect TV layout of A, use arbitrary
  using MmaAtom = decltype(SM90::GMMA::rs_op_selector<ElementMma, ElementMma, float, Shape<_64,_16,_32>>());
  using MmaTraits = MMA_Traits<MmaAtom>;
  auto mk_shape_mma = select<0,2>(typename MmaTraits::Shape_MNK{});
  auto tv_layout_mma = typename MmaTraits::ALayout{};
  static_assert(size<1>(tv_layout_mma) % size(val_layout) == 0, "Value layout must evenly divide the MMA value layout");

  // 2. Create a single warp's TV layout from that of the whole MMA and invert to get (m,k -> thr,val)
  // Note: this assumes A is partitioned between warps along M mode
  auto tv_tiler_warp = make_shape(Int<32>{}, size<1>(tv_layout_mma));
  auto mk_shape_warp = shape_div(mk_shape_mma, size(typename MmaTraits::ThrID{}) / Int<32>{});
  auto tv_layout_mma_warp = make_layout_like(composition(tv_layout_mma, tv_tiler_warp));
  auto mk_layout_mma_warp = right_inverse(tv_layout_mma_warp).with_shape(mk_shape_warp);

  // 3. Repeat the warp layout NumAtoms times along K mode to get wider vectorization
  auto mk_layout_mma_trgt = blocked_product(mk_layout_mma_warp, atom_layout);

  // 4. Compose with a contiguous layout of values in each thread (required for smem vectorization)
  auto val_to_offset = logical_product(val_layout, size<1>(tv_layout_mma) / size(val_layout) * size(atom_layout));
  auto thr_to_offset = make_layout(size<0>(tv_layout_mma_warp));
  auto tv_to_offset = select<1,0>(logical_product(val_to_offset, thr_to_offset));
  auto layout_atom = composition(tv_to_offset, mk_layout_mma_trgt);

  return layout_atom;
}

template<class TileShape, class EngineSrc, class LayoutSrc, class EngineDst, class LayoutDst, class TiledCopy>
__global__ void reorder_tensor_kernel(
  cute::Tensor<EngineSrc, LayoutSrc> S,
  cute::Tensor<EngineDst, LayoutDst> D,
  TiledCopy tiled_copy)
{
  using namespace cute;

  using T = typename EngineDst::value_type;

  Tensor gS = local_tile(S, TileShape{}, make_coord(blockIdx.x, _, blockIdx.z));
  Tensor gD = local_tile(D, TileShape{}, make_coord(blockIdx.x, _, blockIdx.z));

  auto thread_copy = tiled_copy.get_slice(threadIdx.x);
  Tensor tS = thread_copy.partition_S(gS);
  Tensor tD = thread_copy.partition_D(gD);

  copy(tiled_copy, tS, tD);
}

template<class EngineSrc, class LayoutSrc, class EngineDst, class LayoutDst>
void reorder_tensor(
  cute::Tensor<EngineSrc, LayoutSrc> S,
  cute::Tensor<EngineDst, LayoutDst> D)
{
  using namespace cute;

  using T = typename EngineDst::value_type;
  static_assert(is_same_v<remove_const_t<typename EngineSrc::value_type>, T>, "Type mismatch");

  // Construct a value layout that assigns at least 8 bits of contiguous elements in destination tensor to a thread
  // This avoids a race condition when writing out subbyte types (e.g. int4b_t).
  auto has_major_mode = [](auto s) {
    return any_of(s, [](auto a){ return is_constant<1, decltype(a)>{}; });
  };
  static_assert(has_major_mode(stride<0>(LayoutDst{})) ^ has_major_mode(stride<1>(LayoutDst{})), 
                "Could not find stride-1 mode in destination layout");
  constexpr int N = shape_div(Int<8>{}, sizeof_bits<T>{});
  auto val_layout = conditional_return<has_major_mode(stride<0>(LayoutDst{}))>(
    make_layout(make_shape(Int<N>{}, Int<1>{}), GenColMajor{}),
    make_layout(make_shape(Int<1>{}, Int<N>{}), GenRowMajor{}));

  // Make a tiled copy with a simple row-major thread order and above layout
  int constexpr NumThreads = 128;
  auto const thr_layout = make_layout(make_shape(Int<1>{}, Int<NumThreads>{}));
  auto tiled_copy = make_tiled_copy(Copy_Atom<DefaultCopy, T>{}, thr_layout, val_layout);

  // Assign a group of 16 rows to a threadblock; this matches the shuffle atom size for Hopper
  using TileShape = Shape<_16>;
  auto tiled_D = group_modes<3,rank_v<LayoutDst>>(tiled_divide(D, TileShape{}));
  dim3 blocks{unsigned(size<1>(tiled_D)), 1u, unsigned(size<3>(tiled_D))};

  reorder_tensor_kernel<TileShape><<<blocks, NumThreads>>>(S, D, tiled_copy);
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
  using namespace cute;
  reorder_tensor(make_tensor(make_gmem_ptr<T>(src), layout_src),
                 make_tensor(make_gmem_ptr<T>(dst), layout_dst));
}

// In-place version
template<class T, class LayoutSrc, class LayoutDst>
void reorder_tensor(
  T * data,
  LayoutSrc const& layout_src,
  LayoutDst const& layout_dst)
{
  using namespace cute;
  cutlass::DeviceAllocation<T> temp(size(layout_src));
  reorder_tensor(data, layout_src, temp.get(), layout_dst);
  cutlass::device_memory::copy_device_to_device(data, temp.get(), static_cast<size_t>(size(layout_src)));
}