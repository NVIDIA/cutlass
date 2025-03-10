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

#include "cutlass/detail/layout.hpp"

#include <cute/tensor.hpp>
#include <sycl/sycl.hpp>
#include <syclcompat.hpp>

#include "cutlass_unit_test.h"

using namespace cute;
using namespace cutlass;
using namespace syclcompat::experimental;

#define SUBGROUP_SIZE (16)

template <class TensorS, class TensorD>
void copy_kernel_vectorized(TensorS tile_S, TensorD tile_D) {
  using namespace cute;

  using Element = typename TensorS::value_type;

  // Shared memory buffers
  auto smem = syclcompat::local_mem<Element[size(tile_S)]>();
  Tensor sTensor = make_tensor(make_smem_ptr(smem), tile_S.layout());

  // Define `AccessType` which controls the size of the actual memory access.
  // using AccessType = cutlass::AlignedArray<Element, size(VecLayout{})>;

  // A copy atom corresponds to one hardware memory access.
  using traits_load = Copy_Traits<XE_1D_LOAD_GLOBAL<
      typename uint_bit<sizeof_bits_v<Element>>::type, cutlass::uint128_t>>;
  using Atom_load = Copy_Atom<traits_load, Element>;
  using traits_store = Copy_Traits<XE_1D_STORE_GLOBAL<
      cutlass::uint128_t, typename uint_bit<sizeof_bits_v<Element>>::type>>;
  using Atom_store = Copy_Atom<traits_store, Element>;

  using traits_ldsm =
      Copy_Traits<XE_1D_LDSM<typename uint_bit<sizeof_bits_v<Element>>::type,
                             cutlass::uint128_t>>;
  using Atom_ldsm = Copy_Atom<traits_ldsm, Element>;
  using traits_stsm =
      Copy_Traits<XE_1D_STSM<cutlass::uint128_t,
                             typename uint_bit<sizeof_bits_v<Element>>::type>>;
  using Atom_stsm = Copy_Atom<traits_stsm, Element>;

  // Construct tiled copy, a tiling of copy atoms.
  //
  // Note, this assumes the vector and thread layouts are aligned with contigous
  // data in GMEM. Alternative thread layouts are possible but may result in
  // uncoalesced reads. Alternative vector layouts are also possible, though
  // incompatible layouts will result in compile time errors.

  auto VecLayout = make_layout(
      make_shape(_1{}, Int<sizeof(cutlass::uint128_t) / sizeof(Element)>{}),
      Stride<Int<sizeof(cutlass::uint128_t) / sizeof(Element)>, _1>{});
  auto ThreadLayout = make_layout(make_shape(_1{}, _16{}));
  auto tiled_copy_load = make_tiled_copy(Atom_load{},  // access size
                                         ThreadLayout, // thread layout
                                         VecLayout); // vector layout (e.g. 4x1)
  auto tiled_copy_store =
      make_tiled_copy(Atom_store{}, // access size
                      ThreadLayout, // thread layout
                      VecLayout);   // vector layout (e.g. 4x1)

  auto tiled_ldsm = make_tiled_copy(Atom_ldsm{},  // access size
                                    ThreadLayout, // thread layout
                                    VecLayout);   // vector layout (e.g. 4x1)
  auto tiled_stsm = make_tiled_copy(Atom_stsm{},  // access size
                                    ThreadLayout, // thread layout
                                    VecLayout);   // vector layout (e.g. 4x1)

  // Construct a Tensor corresponding to each thread's slice.
  auto thr_copy_load = tiled_copy_load.get_thread_slice(ThreadIdxX());
  auto thr_copy_store = tiled_copy_store.get_thread_slice(ThreadIdxX());

  auto thr_copy_ldsm = tiled_ldsm.get_thread_slice(ThreadIdxX());
  auto thr_copy_stsm = tiled_stsm.get_thread_slice(ThreadIdxX());

  Tensor thr_tile_load_S =
      thr_copy_load.partition_S(tile_S); // (CopyOp, CopyM, CopyN)
  Tensor thr_tile_store_D =
      thr_copy_store.partition_D(tile_D); // (CopyOp, CopyM, CopyN)

  Tensor thr_tile_ldsm_S =
      thr_copy_ldsm.partition_S(sTensor); // (CopyOp, CopyM, CopyN)
  Tensor thr_tile_stsm_D =
      thr_copy_stsm.partition_D(sTensor); // (CopyOp, CopyM, CopyN)

  // Construct a register-backed Tensor with the same shape as each thread's
  // partition Use make_fragment because the first mode is the instruction-local
  // mode
  Tensor fragment = make_fragment_like(
      thr_copy_load.partition_D(tile_S)); // (CopyOp, CopyM, CopyN)

#if 0
  if (thread(0, 0)) {
    print("loading to registers from src ========================\n");
    print("tile_S:");
    print(tile_S.layout());
    print("\n");

    print("thr_tile_load_S: ");
    print(thr_tile_load_S.layout());
    print("\n");
    print(thr_tile_load_S.data());
    print("\n");

    print("thr_tile_store_D: ");
    print(thr_tile_store_D.layout());
    print("\n");

    print("fragment: ");
    print(fragment.layout());
    print("\n");
  }
#endif

  // Copy from GMEM to RMEM and from RMEM to GMEM
  prefetch(tiled_copy_load, thr_tile_load_S);
  copy(tiled_copy_load, thr_tile_load_S, fragment);
  copy(tiled_stsm, fragment, thr_tile_stsm_D);
  clear(fragment);
  copy(tiled_ldsm, thr_tile_ldsm_S, fragment);
  copy(tiled_copy_store, fragment, thr_tile_store_D);
}

TEST(PVC_1d_copy, copy_double) {
  {
    constexpr int M = 1;
    constexpr int N = 128;
    using Element = double;
    //
    // Allocate and initialize
    //
    cutlass::host_vector<Element> host_src(M * N);
    cutlass::host_vector<Element> host_output(M * N);

    for (size_t i = 0; i < host_src.size(); ++i) {
      host_src[i] = static_cast<Element>(i);
    }

    cutlass::device_vector<Element> device_src = host_src;
    cutlass::device_vector<Element> device_output(M * N);

    Tensor S =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));
    Tensor D =
        make_tensor(make_gmem_ptr(device_output.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));

    static constexpr auto subgroup_size = 16;
    auto blockDim = syclcompat::dim3(subgroup_size);

    launch<copy_kernel_vectorized<decltype(S), decltype(D)>>(
        launch_policy{
            syclcompat::dim3(1), blockDim,
            kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
        S, D);

    syclcompat::wait_and_throw();
    host_output = device_output;
    for (int i = 0; i < M * N; ++i) {
      // printf("%d  %d\n", int(h_in[i]), int(h_out[i]));
      EXPECT_EQ(host_output[i], host_src[i]);
    }
  }

  {
    constexpr int M = 1;
    constexpr int N = 128;
    using Element = float;
    //
    // Allocate and initialize
    //
    cutlass::host_vector<Element> host_src(M * N);
    cutlass::host_vector<Element> host_output(M * N);

    for (size_t i = 0; i < host_src.size(); ++i) {
      host_src[i] = static_cast<Element>(i);
    }

    cutlass::device_vector<Element> device_src = host_src;
    cutlass::device_vector<Element> device_output(M * N);

    Tensor S =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));
    Tensor D =
        make_tensor(make_gmem_ptr(device_output.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));

    static constexpr auto subgroup_size = 16;
    auto blockDim = syclcompat::dim3(subgroup_size);
    //
    // Launch the kernel
    //
    launch<copy_kernel_vectorized<decltype(S), decltype(D)>>(
        launch_policy{
            syclcompat::dim3(1), blockDim,
            kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
        S, D);

    syclcompat::wait_and_throw();
    host_output = device_output;
    for (int i = 0; i < M * N; ++i) {
      EXPECT_EQ(host_output[i], host_src[i]);
    }
  }

  {
    constexpr int M = 1;
    constexpr int N = 128;
    using Element = uint16_t;
    //
    // Allocate and initialize
    //
    cutlass::host_vector<Element> host_src(M * N);
    cutlass::host_vector<Element> host_output(M * N);

    for (size_t i = 0; i < host_src.size(); ++i) {
      host_src[i] = static_cast<Element>(i);
    }

    cutlass::device_vector<Element> device_src = host_src;
    cutlass::device_vector<Element> device_output(M * N);

    Tensor S =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));
    Tensor D =
        make_tensor(make_gmem_ptr(device_output.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));

    static constexpr auto subgroup_size = 16;
    auto blockDim = syclcompat::dim3(subgroup_size);
    //
    // Launch the kernel
    //
    launch<copy_kernel_vectorized<decltype(S), decltype(D)>>(
        launch_policy{
            syclcompat::dim3(1), blockDim,
            kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
        S, D);

    syclcompat::wait_and_throw();
    host_output = device_output;
    for (int i = 0; i < M * N; ++i) {
      EXPECT_EQ(host_output[i], host_src[i]);
    }
  }
}
