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
  Tensor sB = make_tensor(make_smem_ptr(shared_storage.smem.data()), smem_layout);  // (CTA_TILE_M,CTA_TILE_N,...)

  // TMA requires special handling of strides to deal with coord codomain mapping
  // Represent the full tensors -- get these from TMA
  Tensor mA = make_tensor(make_gmem_ptr(g_in), gmem_layout);
  Tensor mB = tma.get_tma_tensor(shape(gmem_layout));

  constexpr int R = rank_v<CTA_Tiler>;
  Tensor gA = local_tile(mA, cta_tiler, repeat<R>(_));               // (CTA_TILE_M,CTA_TILE_N,...REST_M,REST_N,...)
  Tensor gB = local_tile(mB, cta_tiler, repeat<R>(_));               // (CTA_TILE_M,CTA_TILE_N,...REST_M,REST_N,...)

  //
  // Prepare the TMA_STORE
  //

  auto cta_tma = tma.get_slice(Int<0>{});                            // CTA slice

  Tensor tBsB_x = cta_tma.partition_S(sB);                           // (TMA,TMA_M,TMA_N)
  Tensor tBgB_x = cta_tma.partition_D(gB);                           // (TMA,TMA_M,TMA_N,REST_M,REST_N)

#if 0
  if (thread0()) {
    print(tma);
    print("TILE  :  "); print(cta_tiler); print("\n");
    print("  mB  :  "); print(  mB.data());   print(" o "); print(  mB.layout());   print("\n");
    print("  gB  :  "); print(  gB.data());   print(" o "); print(  gB.layout());   print("\n");
    print("tBgB_x:  "); print(tBgB_x.data()); print(" o "); print(tBgB_x.layout()); print("\n");
    print("  sB  :  "); print(  sB.data());   print(" o "); print(  sB.layout());   print("\n");
    print("tBsB_x:  "); print(tBsB_x.data()); print(" o "); print(tBsB_x.layout()); print("\n");
  }
#endif

  //
  // Perform the TMA_STORE
  //

  // INPUT: Group the CTA_TILE_X modes and REST_X modes for input
  Tensor tAgA = group_modes<0,R>(group_modes<R,rank(gA)>(gA));       // (CTA_TILE, REST)

  // OUTPUT: Group the REST_X modes and the TMA_X modes to easily iterate through the tiles
  Tensor tBgB = group_modes<1,rank(tBgB_x)>(tBgB_x);                 // (TMA,REST)
  Tensor tBsB = group_modes<1,rank(tBsB_x)>(tBsB_x);                 // (TMA,REST)
  static_assert(size<1>(tBsB) == 1);

#if 0
  if (thread0()) {
    print("tAgA  :  "); print(tAgA.data()); print(" o "); print(tAgA.layout()); print("\n");
    print("tBsB  :  "); print(tBsB.data()); print(" o "); print(tBsB.layout()); print("\n");
    print("tBgB  :  "); print(tBgB.data()); print(" o "); print(tBgB.layout()); print("\n");
  }
#endif

  // Loop over the TMA stages, using smem as our buffer
  for (int stage = 0; stage < size<1>(tBgB); ++stage)
  {
    //
    // Read in trivially gmem -> smem
    //

    for (int i = threadIdx.x; i < size(sB); i += blockDim.x) {
      sB(i) = tAgA(i,stage);
    }

    __syncthreads();

    //
    // Perform the TMA_STORE
    //

    if (threadIdx.x == 0) {
      copy(tma, tBsB(_,0), tBgB(_,stage));
    }

    tma_store_wait<0>();
    __syncthreads();
  }
}

template <class T, class GMEM_Layout, class SMEM_Layout, class CTA_Tile>
void
test_tma_store(GMEM_Layout const& gmem_layout,
               SMEM_Layout const& smem_layout,
               CTA_Tile    const& cta_tile)
{
  thrust::host_vector<T> h_in(cosize(gmem_layout));
  for (int i = 0; i < h_in.size(); ++i) { h_in[i] = T(i % 13); }
  thrust::device_vector<T> d_in = h_in;
  thrust::device_vector<T> d_out(h_in.size(), T(-1));

  Tensor gA = make_tensor(d_out.data().get(), gmem_layout);
  auto tma = make_tma_copy(SM90_TMA_STORE{}, gA, smem_layout, cta_tile, Int<1>{});
  //print(tma);

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
test_tma_store(GMEM_Layout const& gmem_layout,
               SMEM_Layout const& smem_layout)
{
  return test_tma_store<T>(gmem_layout, smem_layout, product_each(shape(smem_layout)));
}

TEST(SM90_CuTe_Hopper, Tma_Load_1D)
{
  Layout smem_layout = Layout<_256, _1>{};
  {
  Layout gmem_layout = smem_layout;
  test_tma_store<int8_t>(gmem_layout, smem_layout);
  test_tma_store<half_t>(gmem_layout, smem_layout);
  test_tma_store< float>(gmem_layout, smem_layout);
  test_tma_store<double>(gmem_layout, smem_layout);
  }

  {
  Layout gmem_layout = make_layout(128, GenColMajor{});
  test_tma_store<int8_t>(gmem_layout, smem_layout);
  test_tma_store<half_t>(gmem_layout, smem_layout);
  test_tma_store< float>(gmem_layout, smem_layout);
  test_tma_store<double>(gmem_layout, smem_layout);
  }
}

TEST(SM90_CuTe_Hopper, Tma_Store_32x32_Col)
{
  Layout smem_layout = Layout<Shape<_32,_32>, Stride<_1,_32>>{};
  {
  Layout gmem_layout = smem_layout;
  test_tma_store<int8_t>(gmem_layout, smem_layout);
  test_tma_store<half_t>(gmem_layout, smem_layout);
  test_tma_store< float>(gmem_layout, smem_layout);
  test_tma_store<double>(gmem_layout, smem_layout);
  }

  {
  Layout gmem_layout = make_layout(make_shape(32,32), GenColMajor{});
  test_tma_store<int8_t>(gmem_layout, smem_layout);
  test_tma_store<half_t>(gmem_layout, smem_layout);
  test_tma_store< float>(gmem_layout, smem_layout);
  test_tma_store<double>(gmem_layout, smem_layout);
  }

  {
  Layout gmem_layout = make_layout(make_shape(32,32), make_stride(Int<1>{}, 1024));
  test_tma_store<int8_t>(gmem_layout, smem_layout);
  test_tma_store<half_t>(gmem_layout, smem_layout);
  test_tma_store< float>(gmem_layout, smem_layout);
  test_tma_store<double>(gmem_layout, smem_layout);
  }
}

TEST(SM90_CuTe_Hopper, Tma_Store_32x32_Row)
{
  Layout smem_layout = Layout<Shape<_32,_32>, Stride<_32,_1>>{};
  {
  Layout gmem_layout = smem_layout;
  test_tma_store<int8_t>(gmem_layout, smem_layout);
  test_tma_store<half_t>(gmem_layout, smem_layout);
  test_tma_store< float>(gmem_layout, smem_layout);
  test_tma_store<double>(gmem_layout, smem_layout);
  }

  {
  Layout gmem_layout = make_layout(make_shape(32,32), GenRowMajor{});
  test_tma_store<int8_t>(gmem_layout, smem_layout);
  test_tma_store<half_t>(gmem_layout, smem_layout);
  test_tma_store< float>(gmem_layout, smem_layout);
  test_tma_store<double>(gmem_layout, smem_layout);
  }

  {
  Layout gmem_layout = make_layout(make_shape(32,32), make_stride(1024, Int<1>{}));
  test_tma_store<int8_t>(gmem_layout, smem_layout);
  test_tma_store<half_t>(gmem_layout, smem_layout);
  test_tma_store< float>(gmem_layout, smem_layout);
  test_tma_store<double>(gmem_layout, smem_layout);
  }
}

template <class T, template <typename> typename SWIZZLE_ATOM>
void
test_tma_store_swizzle_atom_mn()
{
  auto   smem_layout = SWIZZLE_ATOM<T>{};
  Layout gmem_layout = make_layout(shape(smem_layout), GenColMajor{});
  return test_tma_store<T>(gmem_layout, smem_layout, product_each(shape(smem_layout)));
}

template <class T, template <typename> typename SWIZZLE_ATOM>
void
test_tma_store_swizzle_atom_k()
{
  auto   smem_layout = SWIZZLE_ATOM<T>{};
  Layout gmem_layout = make_layout(shape(smem_layout), GenRowMajor{});
  return test_tma_store<T>(gmem_layout, smem_layout, product_each(shape(smem_layout)));
}

TEST(SM90_CuTe_Hopper, Tma_Store_Swizzle_Atoms)
{
  test_tma_store_swizzle_atom_mn<int8_t, GMMA::Layout_MN_SW128_Atom>();
  test_tma_store_swizzle_atom_mn<half_t, GMMA::Layout_MN_SW128_Atom>();
  test_tma_store_swizzle_atom_mn< float, GMMA::Layout_MN_SW128_Atom>();
  test_tma_store_swizzle_atom_mn<double, GMMA::Layout_MN_SW128_Atom>();

  test_tma_store_swizzle_atom_mn<int8_t, GMMA::Layout_MN_SW64_Atom>();
  test_tma_store_swizzle_atom_mn<half_t, GMMA::Layout_MN_SW64_Atom>();
  test_tma_store_swizzle_atom_mn< float, GMMA::Layout_MN_SW64_Atom>();
  test_tma_store_swizzle_atom_mn<double, GMMA::Layout_MN_SW64_Atom>();

  test_tma_store_swizzle_atom_mn<int8_t, GMMA::Layout_MN_SW32_Atom>();
  test_tma_store_swizzle_atom_mn<half_t, GMMA::Layout_MN_SW32_Atom>();
  test_tma_store_swizzle_atom_mn< float, GMMA::Layout_MN_SW32_Atom>();
  test_tma_store_swizzle_atom_mn<double, GMMA::Layout_MN_SW32_Atom>();

  test_tma_store_swizzle_atom_mn<int8_t, GMMA::Layout_MN_INTER_Atom>();
  test_tma_store_swizzle_atom_mn<half_t, GMMA::Layout_MN_INTER_Atom>();
  test_tma_store_swizzle_atom_mn< float, GMMA::Layout_MN_INTER_Atom>();
  test_tma_store_swizzle_atom_mn<double, GMMA::Layout_MN_INTER_Atom>();

  test_tma_store_swizzle_atom_k<int8_t, GMMA::Layout_K_SW128_Atom>();
  test_tma_store_swizzle_atom_k<half_t, GMMA::Layout_K_SW128_Atom>();
  test_tma_store_swizzle_atom_k< float, GMMA::Layout_K_SW128_Atom>();
  test_tma_store_swizzle_atom_k<double, GMMA::Layout_K_SW128_Atom>();

  test_tma_store_swizzle_atom_k<int8_t, GMMA::Layout_K_SW64_Atom>();
  test_tma_store_swizzle_atom_k<half_t, GMMA::Layout_K_SW64_Atom>();
  test_tma_store_swizzle_atom_k< float, GMMA::Layout_K_SW64_Atom>();
  test_tma_store_swizzle_atom_k<double, GMMA::Layout_K_SW64_Atom>();

  test_tma_store_swizzle_atom_k<int8_t, GMMA::Layout_K_SW32_Atom>();
  test_tma_store_swizzle_atom_k<half_t, GMMA::Layout_K_SW32_Atom>();
  test_tma_store_swizzle_atom_k< float, GMMA::Layout_K_SW32_Atom>();
  test_tma_store_swizzle_atom_k<double, GMMA::Layout_K_SW32_Atom>();

  test_tma_store_swizzle_atom_k<int8_t, GMMA::Layout_K_INTER_Atom>();
  test_tma_store_swizzle_atom_k<half_t, GMMA::Layout_K_INTER_Atom>();
  test_tma_store_swizzle_atom_k< float, GMMA::Layout_K_INTER_Atom>();
  test_tma_store_swizzle_atom_k<double, GMMA::Layout_K_INTER_Atom>();
}

template <class T, template <typename> typename SWIZZLE_ATOM>
void
test_tma_store_swizzle_tile_mn()
{
  auto   smem_layout = tile_to_shape(SWIZZLE_ATOM<T>{}, Shape<_128,_128>{});
  Layout gmem_layout = make_layout(make_shape(int(size<0>(smem_layout)), int(size<1>(smem_layout))), GenColMajor{});
  return test_tma_store<T>(gmem_layout, smem_layout, product_each(shape(smem_layout)));
}

template <class T, template <typename> typename SWIZZLE_ATOM>
void
test_tma_store_swizzle_tile_k()
{
  auto   smem_layout = tile_to_shape(SWIZZLE_ATOM<T>{}, Shape<_128,_128>{});
  Layout gmem_layout = make_layout(make_shape(int(size<0>(smem_layout)), int(size<1>(smem_layout))), GenRowMajor{});
  return test_tma_store<T>(gmem_layout, smem_layout, product_each(shape(smem_layout)));
}

TEST(SM90_CuTe_Hopper, Tma_Store_Swizzle_Tiles)
{
  // Other T-types use too much smem
  test_tma_store_swizzle_tile_mn<int8_t, GMMA::Layout_MN_SW128_Atom>();
  test_tma_store_swizzle_tile_mn<half_t, GMMA::Layout_MN_SW128_Atom>();
  test_tma_store_swizzle_tile_mn<int8_t, GMMA::Layout_MN_SW64_Atom>();
  test_tma_store_swizzle_tile_mn<half_t, GMMA::Layout_MN_SW64_Atom>();
  test_tma_store_swizzle_tile_mn<int8_t, GMMA::Layout_MN_SW32_Atom>();
  test_tma_store_swizzle_tile_mn<half_t, GMMA::Layout_MN_SW32_Atom>();
  test_tma_store_swizzle_tile_mn<int8_t, GMMA::Layout_MN_INTER_Atom>();
  test_tma_store_swizzle_tile_mn<half_t, GMMA::Layout_MN_INTER_Atom>();
  test_tma_store_swizzle_tile_k<int8_t, GMMA::Layout_K_SW128_Atom>();
  test_tma_store_swizzle_tile_k<half_t, GMMA::Layout_K_SW128_Atom>();
  test_tma_store_swizzle_tile_k<int8_t, GMMA::Layout_K_SW64_Atom>();
  test_tma_store_swizzle_tile_k<half_t, GMMA::Layout_K_SW64_Atom>();
  test_tma_store_swizzle_tile_k<int8_t, GMMA::Layout_K_SW32_Atom>();
  test_tma_store_swizzle_tile_k<half_t, GMMA::Layout_K_SW32_Atom>();
  test_tma_store_swizzle_tile_k<int8_t, GMMA::Layout_K_INTER_Atom>();
  test_tma_store_swizzle_tile_k<half_t, GMMA::Layout_K_INTER_Atom>();
}


// Tensor by-mode
TEST(SM90_CuTe_Hopper, Tma_Store_Tensor)
{
  // 3-mode TMA
  {
  Layout gmem_layout = make_layout(make_shape(128, 64, 5));
  auto cta_tile      = Shape<_64, _32>{};                    // GMEM Tiling:
                                                             //   Take 64-elem from m
                                                             //   Take 32-elem from k
  auto smem_layout = make_layout(Shape<_64,_32>{});
  test_tma_store<half_t>(gmem_layout, smem_layout, cta_tile);
  }

  // 4-mode TMA
  {
  Layout gmem_layout = make_layout(make_shape(make_shape(80,40),make_shape(32,12)));
  auto cta_tile      = Shape<Shape<_16,_8>,Shape<_32,_2>>{}; // GMEM Tiling:
                                                             //   Take 16-elem from m0, 8-elem from m1,
                                                             //   Take 32-elem from k0, 2-elem from k1
  auto smem_layout = make_layout(Shape<_128,_64>{});
  test_tma_store<half_t>(gmem_layout, smem_layout, cta_tile);
  }

  // 5-mode TMA
  {
  Layout gmem_layout = make_layout(make_shape(make_shape(32,32,32),make_shape(32,12)));
  auto cta_tile      = Shape<Shape<_16,_4,_2>,Shape<_16,_2>>{}; // GMEM Tiling:
                                                             //   Take 4-elem from m0, 4-elem from m1, 5-elem from m2
                                                             //   Take 32-elem from k0, 2-elem from k1
  auto smem_layout = make_layout(Shape<_128,_32>{});
  test_tma_store<half_t>(gmem_layout, smem_layout, cta_tile);
  }
}

// Tensor Multimode -- TMA with more than 5 modes in GMEM (packs residual modes into last TMA mode)
TEST(SM90_CuTe_Hopper, Tma_Store_Tensor_Multimode)
{
  {
  Layout gmem_layout = make_layout(make_shape(make_shape(32,3,2,2),make_shape(32,4,2)));
  auto cta_tile      = Shape<Shape<_32>, Shape<_32,_2>>{};    // GMEM Tiling:
                                                              //  Take 32-elem from m0
                                                              //  Take 32-elem from k0, 2-elem from k1
  auto smem_layout = make_layout(Shape<_32,_64>{});
  test_tma_store<half_t>(gmem_layout, smem_layout, cta_tile);
  }

  {
  Layout gmem_layout = make_layout(make_shape(make_shape(64,3,2,2),make_shape(32,4,2)));
  auto cta_tile      = Shape<Shape<_32,_3>, Shape<_32,_2>>{}; // GMEM Tiling:
                                                              //  Take 32-elem from m0, 3-elem from m1
                                                              //  Take 32-elem from k0, 2-elem from k1
  auto smem_layout = make_layout(Shape<_96,_64>{});
  test_tma_store<half_t>(gmem_layout, smem_layout, cta_tile);
  }

  {
  Layout gmem_layout = make_layout(make_shape(make_shape(64,3,2,3,2),make_shape(32,4,2,2)));
  auto cta_tile      = Shape<Shape<_32>, Shape<_16,_2>>{};    // GMEM Tiling:
                                                              //  Take 32-elem from m0
                                                              //  Take 16-elem from k0, 2-elem from k1
  auto smem_layout = make_layout(Shape<_32,_32>{});
  test_tma_store<half_t>(gmem_layout, smem_layout, cta_tile);
  }
}

#endif
