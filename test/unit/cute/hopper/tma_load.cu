/***************************************************************************************************
 * Copyright (c) 2017 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass_unit_test.h"

#include <iostream>

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cute/tensor.hpp>

using namespace cute;

template <class ElementType, class SmemLayout>
struct SharedStorage
{
  cute::array_aligned<ElementType, cute::cosize_v<SmemLayout>> smem;
  cute::uint64_t tma_load_mbar[1];
};

#if CUDA_12_0_SM90_FEATURES_SUPPORTED
template <class T, class TiledCopy, class CTA_Tiler, class GmemLayout, class SmemLayout>
__global__ void
tma_test_device_cute(T const* g_in, T* g_out,
                     CUTE_GRID_CONSTANT TiledCopy const tma, CTA_Tiler cta_tiler,
                     GmemLayout gmem_layout, SmemLayout smem_layout)
{
  CUTE_STATIC_ASSERT_V(product_each(shape(cta_tiler)) == product_each(shape(smem_layout)));

  // Use Shared Storage structure to allocate and distribute aligned SMEM addresses
  extern __shared__ char shared_memory[];
  using SharedStorage = SharedStorage<T, SmemLayout>;
  SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(shared_memory);
  // Construct SMEM tensor
  Tensor sA = make_tensor(make_smem_ptr(shared_storage.smem.data()), smem_layout);  // (CTA_TILE_M,CTA_TILE_N,...)
  // Shared memory barriers use 64bits in SMEM for synchronization
  uint64_t* tma_load_mbar = shared_storage.tma_load_mbar;

  // TMA requires special handling of strides to deal with coord codomain mapping
  // Represent the full tensors -- get these from TMA
  Tensor mA = tma.get_tma_tensor(shape(gmem_layout));
  Tensor mB = make_tensor(make_gmem_ptr(g_out), gmem_layout);

  constexpr int R = rank_v<CTA_Tiler>;
  Tensor gA = local_tile(mA, cta_tiler, repeat<R>(_));               // (CTA_TILE_M,CTA_TILE_N,...REST_M,REST_N,...)
  Tensor gB = local_tile(mB, cta_tiler, repeat<R>(_));               // (CTA_TILE_M,CTA_TILE_N,...REST_M,REST_N,...)

  //
  // Prepare the TMA_LOAD
  //

  auto cta_tma = tma.get_slice(Int<0>{});                            // CTA slice

  Tensor tAgA_x = cta_tma.partition_S(gA);                           // (TMA,TMA_M,TMA_N,REST_M,REST_N)
  Tensor tAsA_x = cta_tma.partition_D(sA);                           // (TMA,TMA_M,TMA_N)

#if 0
  if (thread0()) {
    print(tma);
    print("TILE  :  "); print(cta_tiler); print("\n");
    print("  mA  :  "); print(  mA.data());   print(" o "); print(  mA.layout());   print("\n");
    print("  gA  :  "); print(  gA.data());   print(" o "); print(  gA.layout());   print("\n");
    print("tAgA_x:  "); print(tAgA_x.data()); print(" o "); print(tAgA_x.layout()); print("\n");
    print("  sA  :  "); print(  sA.data());   print(" o "); print(  sA.layout());   print("\n");
    print("tAsA_x:  "); print(tAsA_x.data()); print(" o "); print(tAsA_x.layout()); print("\n");
  }
#endif

  //
  // Perform the TMA_LOAD
  //

  // INPUT: Group the REST_X modes and the TMA_X modes to easily iterate through the tiles
  Tensor tAgA = group_modes<1,rank(tAgA_x)>(tAgA_x);                 // (TMA,REST)
  Tensor tAsA = group_modes<1,rank(tAsA_x)>(tAsA_x);                 // (TMA,REST)
  static_assert(size<1>(tAsA) == 1);

  // OUTPUT: Group the CTA_TILE_X modes and REST_X modes for output
  Tensor tBgB = group_modes<0,R>(group_modes<R,rank(gB)>(gB));       // (CTA_TILE, REST)

#if 0
  if (thread0()) {
    print("tAgA  :  "); print(tAgA.data()); print(" o "); print(tAgA.layout()); print("\n");
    print("tAsA  :  "); print(tAsA.data()); print(" o "); print(tAsA.layout()); print("\n");
    print("tBgB  :  "); print(tBgB.data()); print(" o "); print(tBgB.layout()); print("\n");
  }
#endif

  // Loop over the TMA stages, using smem as our buffer
  for (int stage = 0; stage < size<1>(tAgA); ++stage)
  {
    // Set the bytes transferred in this TMA transaction (may involve multiple issues)
    constexpr int kTmaTransactionBytes = size(sA) * sizeof(T);

    if (threadIdx.x == 0)
    {
      /// Initialize shared memory barrier
      tma_load_mbar[0] = 0;
      cute::initialize_barrier(tma_load_mbar[0], 1 /*numThreads*/);
      cute::set_barrier_transaction_bytes(tma_load_mbar[0], kTmaTransactionBytes);

      copy(tma.with(tma_load_mbar[0]), tAgA(_,stage), tAsA(_,0));
    }
    __syncthreads();

    /// Wait on the shared memory barrier until the phase bit flips from kPhaseBit value
    constexpr int kPhaseBit = 0;
    cute::wait_barrier(tma_load_mbar[0], kPhaseBit);

    //
    // Write out trivially smem -> gmem
    //

    for (int i = threadIdx.x; i < size(sA); i += blockDim.x) {
      tBgB(i,stage) = sA(i);
    }
    __syncthreads();
  }
}

template <class T, class GMEM_Layout, class SMEM_Layout, class CTA_Tile>
void
test_tma_load(GMEM_Layout const& gmem_layout,
              SMEM_Layout const& smem_layout,
              CTA_Tile    const& cta_tile)
{
  thrust::host_vector<T> h_in(cosize(gmem_layout));
  for (int i = 0; i < h_in.size(); ++i) { h_in[i] = T(i); }
  thrust::device_vector<T> d_in = h_in;
  thrust::device_vector<T> d_out(h_in.size(), T(-1));

  Tensor gA = make_tensor(d_in.data().get(), gmem_layout);
  auto tma = make_tma_copy(SM90_TMA_LOAD{}, gA, smem_layout, cta_tile, Int<1>{});
  //print("TMA Box   size:  "); print(typename decltype(tma)::Tiler_MN{}); print("\n");
  //print("TMA Instr size:  "); print(decltype(tma)::NumValSrc); print("\n");

  int smem_size = int(sizeof(SharedStorage<T, decltype(smem_layout)>));
  tma_test_device_cute<<<1, 128, smem_size>>>(
    thrust::raw_pointer_cast(d_in.data()),
    thrust::raw_pointer_cast(d_out.data()),
    tma, cta_tile,
    gmem_layout,
    smem_layout);

  thrust::host_vector<T> h_out = d_out;
  Tensor hA_in  = make_tensor(h_in.data(),  gmem_layout);
  Tensor hA_out = make_tensor(h_out.data(), gmem_layout);
  for (int i = 0; i < size(gmem_layout); ++i) {
    EXPECT_EQ(hA_in(i), hA_out(i));
  }
}

template <class T, class GMEM_Layout, class SMEM_Layout>
void
test_tma_load(GMEM_Layout const& gmem_layout,
              SMEM_Layout const& smem_layout)
{
  return test_tma_load<T>(gmem_layout, smem_layout, product_each(shape(smem_layout)));
}

TEST(SM90_CuTe_Hopper, Tma_Load_32x32_Col)
{
  Layout smem_layout = Layout<Shape<_32,_32>, Stride<_1,_32>>{};
  {
  Layout gmem_layout = smem_layout;
  test_tma_load<int8_t>(gmem_layout, smem_layout);
  test_tma_load<half_t>(gmem_layout, smem_layout);
  test_tma_load< float>(gmem_layout, smem_layout);
  test_tma_load<double>(gmem_layout, smem_layout);
  }

  {
  Layout gmem_layout = make_layout(make_shape(32,32), GenColMajor{});
  test_tma_load<int8_t>(gmem_layout, smem_layout);
  test_tma_load<half_t>(gmem_layout, smem_layout);
  test_tma_load< float>(gmem_layout, smem_layout);
  test_tma_load<double>(gmem_layout, smem_layout);
  }

  {
  Layout gmem_layout = make_layout(make_shape(32,32), make_stride(Int<1>{}, 1024));
  test_tma_load<int8_t>(gmem_layout, smem_layout);
  test_tma_load<half_t>(gmem_layout, smem_layout);
  test_tma_load< float>(gmem_layout, smem_layout);
  test_tma_load<double>(gmem_layout, smem_layout);
  }
}

TEST(SM90_CuTe_Hopper, Tma_Load_32x32_Row)
{
  Layout smem_layout = Layout<Shape<_32,_32>, Stride<_32,_1>>{};
  {
  Layout gmem_layout = smem_layout;
  test_tma_load<int8_t>(gmem_layout, smem_layout);
  test_tma_load<half_t>(gmem_layout, smem_layout);
  test_tma_load< float>(gmem_layout, smem_layout);
  test_tma_load<double>(gmem_layout, smem_layout);
  }

  {
  Layout gmem_layout = make_layout(make_shape(32,32), GenRowMajor{});
  test_tma_load<int8_t>(gmem_layout, smem_layout);
  test_tma_load<half_t>(gmem_layout, smem_layout);
  test_tma_load< float>(gmem_layout, smem_layout);
  test_tma_load<double>(gmem_layout, smem_layout);
  }

  {
  Layout gmem_layout = make_layout(make_shape(32,32), make_stride(1024, Int<1>{}));
  test_tma_load<int8_t>(gmem_layout, smem_layout);
  test_tma_load<half_t>(gmem_layout, smem_layout);
  test_tma_load< float>(gmem_layout, smem_layout);
  test_tma_load<double>(gmem_layout, smem_layout);
  }
}

template <class T, template <typename> typename SWIZZLE_ATOM>
void
test_tma_load_swizzle_atom_mn()
{
  auto   smem_layout = SWIZZLE_ATOM<T>{};
  Layout gmem_layout = make_layout(shape(smem_layout), GenColMajor{});
  return test_tma_load<T>(gmem_layout, smem_layout, product_each(shape(smem_layout)));
}

template <class T, template <typename> typename SWIZZLE_ATOM>
void
test_tma_load_swizzle_atom_k()
{
  auto   smem_layout = SWIZZLE_ATOM<T>{};
  Layout gmem_layout = make_layout(shape(smem_layout), GenRowMajor{});
  return test_tma_load<T>(gmem_layout, smem_layout, product_each(shape(smem_layout)));
}

TEST(SM90_CuTe_Hopper, Tma_Load_Swizzle_Atoms)
{
  test_tma_load_swizzle_atom_mn<int8_t, GMMA::Layout_MN_SW128_Atom>();
  test_tma_load_swizzle_atom_mn<half_t, GMMA::Layout_MN_SW128_Atom>();
  test_tma_load_swizzle_atom_mn< float, GMMA::Layout_MN_SW128_Atom>();
  test_tma_load_swizzle_atom_mn<double, GMMA::Layout_MN_SW128_Atom>();

  test_tma_load_swizzle_atom_mn<int8_t, GMMA::Layout_MN_SW64_Atom>();
  test_tma_load_swizzle_atom_mn<half_t, GMMA::Layout_MN_SW64_Atom>();
  test_tma_load_swizzle_atom_mn< float, GMMA::Layout_MN_SW64_Atom>();
  test_tma_load_swizzle_atom_mn<double, GMMA::Layout_MN_SW64_Atom>();

  test_tma_load_swizzle_atom_mn<int8_t, GMMA::Layout_MN_SW32_Atom>();
  test_tma_load_swizzle_atom_mn<half_t, GMMA::Layout_MN_SW32_Atom>();
  test_tma_load_swizzle_atom_mn< float, GMMA::Layout_MN_SW32_Atom>();
  test_tma_load_swizzle_atom_mn<double, GMMA::Layout_MN_SW32_Atom>();

  test_tma_load_swizzle_atom_mn<int8_t, GMMA::Layout_MN_INTER_Atom>();
  test_tma_load_swizzle_atom_mn<half_t, GMMA::Layout_MN_INTER_Atom>();
  test_tma_load_swizzle_atom_mn< float, GMMA::Layout_MN_INTER_Atom>();
  test_tma_load_swizzle_atom_mn<double, GMMA::Layout_MN_INTER_Atom>();

  test_tma_load_swizzle_atom_k<int8_t, GMMA::Layout_K_SW128_Atom>();
  test_tma_load_swizzle_atom_k<half_t, GMMA::Layout_K_SW128_Atom>();
  test_tma_load_swizzle_atom_k< float, GMMA::Layout_K_SW128_Atom>();
  test_tma_load_swizzle_atom_k<double, GMMA::Layout_K_SW128_Atom>();

  test_tma_load_swizzle_atom_k<int8_t, GMMA::Layout_K_SW64_Atom>();
  test_tma_load_swizzle_atom_k<half_t, GMMA::Layout_K_SW64_Atom>();
  test_tma_load_swizzle_atom_k< float, GMMA::Layout_K_SW64_Atom>();
  test_tma_load_swizzle_atom_k<double, GMMA::Layout_K_SW64_Atom>();

  test_tma_load_swizzle_atom_k<int8_t, GMMA::Layout_K_SW32_Atom>();
  test_tma_load_swizzle_atom_k<half_t, GMMA::Layout_K_SW32_Atom>();
  test_tma_load_swizzle_atom_k< float, GMMA::Layout_K_SW32_Atom>();
  test_tma_load_swizzle_atom_k<double, GMMA::Layout_K_SW32_Atom>();

  test_tma_load_swizzle_atom_k<int8_t, GMMA::Layout_K_INTER_Atom>();
  test_tma_load_swizzle_atom_k<half_t, GMMA::Layout_K_INTER_Atom>();
  test_tma_load_swizzle_atom_k< float, GMMA::Layout_K_INTER_Atom>();
  test_tma_load_swizzle_atom_k<double, GMMA::Layout_K_INTER_Atom>();
}

template <class T, template <typename> typename SWIZZLE_ATOM>
void
test_tma_load_swizzle_tile_mn()
{
  auto   smem_layout = tile_to_shape(SWIZZLE_ATOM<T>{}, Shape<_128,_128>{});
  Layout gmem_layout = make_layout(make_shape(int(size<0>(smem_layout)), int(size<1>(smem_layout))), GenColMajor{});
  return test_tma_load<T>(gmem_layout, smem_layout, product_each(shape(smem_layout)));
}

template <class T, template <typename> typename SWIZZLE_ATOM>
void
test_tma_load_swizzle_tile_k()
{
  auto   smem_layout = tile_to_shape(SWIZZLE_ATOM<T>{}, Shape<_128,_128>{});
  Layout gmem_layout = make_layout(make_shape(int(size<0>(smem_layout)), int(size<1>(smem_layout))), GenRowMajor{});
  return test_tma_load<T>(gmem_layout, smem_layout, product_each(shape(smem_layout)));
}

TEST(SM90_CuTe_Hopper, Tma_Load_Swizzle_Tiles)
{
  // Other T-types use too much smem
  test_tma_load_swizzle_tile_mn<int8_t, GMMA::Layout_MN_SW128_Atom>();
  test_tma_load_swizzle_tile_mn<half_t, GMMA::Layout_MN_SW128_Atom>();
  test_tma_load_swizzle_tile_mn<int8_t, GMMA::Layout_MN_SW64_Atom>();
  test_tma_load_swizzle_tile_mn<half_t, GMMA::Layout_MN_SW64_Atom>();
  test_tma_load_swizzle_tile_mn<int8_t, GMMA::Layout_MN_SW32_Atom>();
  test_tma_load_swizzle_tile_mn<half_t, GMMA::Layout_MN_SW32_Atom>();
  test_tma_load_swizzle_tile_mn<int8_t, GMMA::Layout_MN_INTER_Atom>();
  test_tma_load_swizzle_tile_mn<half_t, GMMA::Layout_MN_INTER_Atom>();
  test_tma_load_swizzle_tile_k<int8_t, GMMA::Layout_K_SW128_Atom>();
  test_tma_load_swizzle_tile_k<half_t, GMMA::Layout_K_SW128_Atom>();
  test_tma_load_swizzle_tile_k<int8_t, GMMA::Layout_K_SW64_Atom>();
  test_tma_load_swizzle_tile_k<half_t, GMMA::Layout_K_SW64_Atom>();
  test_tma_load_swizzle_tile_k<int8_t, GMMA::Layout_K_SW32_Atom>();
  test_tma_load_swizzle_tile_k<half_t, GMMA::Layout_K_SW32_Atom>();
  test_tma_load_swizzle_tile_k<int8_t, GMMA::Layout_K_INTER_Atom>();
  test_tma_load_swizzle_tile_k<half_t, GMMA::Layout_K_INTER_Atom>();
}


TEST(SM90_CuTe_Hopper, Tma_Load_Metamode)
{
  {
  auto smem_layout = Layout<Shape<_32,_32>, Stride<_1,_32>>{};
    {
    Layout gmem_layout = make_layout(make_shape(make_shape(8,4), 32), GenColMajor{});
    test_tma_load<half_t>(gmem_layout, smem_layout);
    }
    {
    Layout gmem_layout = make_layout(make_shape(make_shape(8,32), 32), GenColMajor{});
    test_tma_load<half_t>(gmem_layout, smem_layout);
    }
    {
    Layout gmem_layout = make_layout(make_shape(make_shape(64,32), 32), GenColMajor{});
    test_tma_load<half_t>(gmem_layout, smem_layout);
    }
  }

  {
  auto smem_layout = Layout<Shape<_32,_32>, Stride<_32,_1>>{};
    {
    Layout gmem_layout = make_layout(make_shape(make_shape(8,4), 32), GenRowMajor{});
    test_tma_load<half_t>(gmem_layout, smem_layout);
    }
    {
    Layout gmem_layout = make_layout(make_shape(make_shape(8,32), 32), GenRowMajor{});
    test_tma_load<half_t>(gmem_layout, smem_layout);
    }
    {
    Layout gmem_layout = make_layout(make_shape(make_shape(64,32), 32), GenRowMajor{});
    test_tma_load<half_t>(gmem_layout, smem_layout);
    }
  }
}

TEST(SM90_CuTe_Hopper, Tma_Load_Tensor)
{
  // Tensor by-mode
  {
  Layout gmem_layout = make_layout(make_shape(make_shape(80,40),make_shape(32,12)));
  auto cta_tile      = Shape<Shape<_16,_8>,Shape<_32,_2>>{}; // GMEM Tiling:
                                                             //   Take 16-elem from m0, 8-elem from m1,
                                                             //   Take 32-elem from k0, 2-elem from k1
  auto smem_layout = make_layout(Shape<_128,_64>{});
  test_tma_load<half_t>(gmem_layout, smem_layout, cta_tile);
  }

  // Tensor Metamode -- Tiler selects flat elements from a multimode
  {
  Layout gmem_layout = make_layout(make_shape(make_shape(32,40),make_shape(make_shape(8,8),12)));
  auto cta_tile      = Shape<_128, Shape<_32,_2>>{};         // GMEM Tiling:
                                                             //   Take 128-elem from m: m0 must divide 128,
                                                             //                         m-last may be predicated
                                                             //   Take 32-elem from k0, 2-elem from k1
  auto smem_layout = make_layout(Shape<_128,_64>{});
  test_tma_load<half_t>(gmem_layout, smem_layout, cta_tile);
  }

  // Tensor Multimode -- TMA with more than 5 modes in GMEM (packs residual modes into last TMA mode)
  {
  Layout gmem_layout = make_layout(make_shape(make_shape(32,3,2,2),make_shape(32,4,2)));
  auto cta_tile      = Shape<Shape<_32>, Shape<_32,_2>>{};    // GMEM Tiling:
                                                              //  Take 32-elem from m0
                                                              //  Take 32-elem from k0, 2-elem from k1
  auto smem_layout = make_layout(Shape<_32,_64>{});
  test_tma_load<half_t>(gmem_layout, smem_layout, cta_tile);
  }

}

#endif
