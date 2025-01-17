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

template <class TensorS, class TensorD, class TiledLoad, class TiledStore>
void copy_kernel_global(TensorS S, TensorD D, TiledLoad load,
                        TiledStore store) {

  auto thr_copy_load = load.get_thread_slice(ThreadIdxX());
  Tensor thr_tile_load_S = thr_copy_load.partition_S(S);
  Tensor thr_tile_load_D = thr_copy_load.partition_D(S);

  // Construct a register-backed Tensor with the same shape as each thread's
  // partition Use make_fragment because the first mode is the instruction-local
  // mode
  Tensor fragment =
      make_fragment_like(thr_tile_load_D); // (CopyOp, CopyM, CopyN)

  copy(load, thr_tile_load_S, fragment);

  auto thr_copy_store = store.get_thread_slice(ThreadIdxX());

  Tensor thr_tile_store_D =
      thr_copy_store.partition_D(D); // (CopyOp, CopyM, CopyN)

  Tensor frag_view =
      make_tensor(static_cast<decltype(fragment) &&>(fragment).data(),
                  thr_copy_store.partition_S(D).shape());

#if 0
  if (thread(0)) {
    print("thr_tile_load_S: ");
    print(thr_tile_load_S.layout());
    print("\n");

    print("thr_tile_load_D: ");
    print(thr_tile_load_D.layout());
    print("\n");

    print("fragment: ");
    print(fragment.layout());
    print("\n");

    print("thr_tile_store_D: ");
    print(thr_tile_store_D.layout());
    print("\n");

    print("frag_view: ");
    print(frag_view.layout());
    print("\n\n");
  }
#endif

  copy(store, frag_view, thr_tile_store_D);
}

TEST(PVC_2d_copy, load_store_global) {
  {
    constexpr int M = 8;
    constexpr int N = 16;
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
    cutlass::device_vector<Element> device_output = host_output;

    Tensor S =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));
    Tensor D =
        make_tensor(make_gmem_ptr(device_output.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));

    auto tiled_copy =
        make_tiled_copy(Copy_Atom<UniversalCopy<Element>, Element>{},
                        Layout<Shape<_1, _16>, Stride<_16, _1>>{},
                        Layout<Shape<_8, _1>, Stride<_1, _8>>{});
    static constexpr auto subgroup_size = 16;
    auto blockDim = syclcompat::dim3(size(tiled_copy));
    //
    // Launch the kernel
    //
    launch<copy_kernel_global<decltype(S), decltype(D), decltype(tiled_copy),
                              decltype(tiled_copy)>>(
        launch_policy{
            syclcompat::dim3(1), blockDim,
            kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
        S, D, tiled_copy, tiled_copy);

    syclcompat::wait_and_throw();
    host_output = device_output;
    for (int i = 0; i < M * N; ++i) {
      EXPECT_EQ(host_output[i], host_src[i]);
    }
  }
}

TEST(PVC_2d_copy, load_store_global_V) {
  {
    constexpr int M = 16;
    constexpr int N = 16;
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
    cutlass::device_vector<Element> device_output = host_output;

    Tensor S =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));
    Tensor D =
        make_tensor(make_gmem_ptr(device_output.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));

    auto tiled_copy =
        make_tiled_copy(Copy_Atom<UniversalCopy<Element>, Element>{},
                        Layout<Shape<_1, _16>, Stride<_16, _1>>{},
                        Layout<Shape<_8, _2>, Stride<_1, _8>>{});
    static constexpr auto subgroup_size = 16;
    auto blockDim = syclcompat::dim3(size(tiled_copy));
    //
    // Launch the kernel
    //
    launch<copy_kernel_global<decltype(S), decltype(D), decltype(tiled_copy),
                              decltype(tiled_copy)>>(
        launch_policy{
            syclcompat::dim3(1), blockDim,
            kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
        S, D, tiled_copy, tiled_copy);

    syclcompat::wait_and_throw();
    host_output = device_output;
    for (int i = 0; i < M * N; ++i) {
      EXPECT_EQ(host_output[i], host_src[i]);
    }
  }
}

template <class TensorS, class TensorD, class TiledCopy>
void copy_kernel_local(TensorS S, TensorD D, TiledCopy Op) {

  // Shared memory buffers
  using Element = typename TensorS::value_type;
  ;
  auto smem = syclcompat::local_mem<Element[size(S)]>();
  Tensor sTensor = make_tensor(make_smem_ptr(smem), S.layout());

  auto thr_copy = Op.get_thread_slice(ThreadIdxX());
  Tensor thr_global_S = thr_copy.partition_S(S);
  Tensor thr_global_D = thr_copy.partition_D(D);
  Tensor thr_local_S = thr_copy.partition_S(sTensor);
  Tensor thr_local_D = thr_copy.partition_D(sTensor);

  // Construct a register-backed Tensor with the same shape as each thread's
  // partition Use make_fragment because the first mode is the instruction-local
  // mode
  Tensor fragment = make_fragment_like(thr_global_D); // (CopyOp, CopyM, CopyN)

  copy(Op, thr_global_S, fragment);
  copy(Op, fragment, thr_local_D);
  clear(fragment);
  copy(Op, thr_local_S, fragment);
  copy(Op, fragment, thr_global_D);
}

TEST(PVC_2d_copy, load_store_local) {
  {
    constexpr int M = 8;
    constexpr int N = 16;
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
    cutlass::device_vector<Element> device_output = host_output;

    Tensor S =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));
    Tensor D =
        make_tensor(make_gmem_ptr(device_output.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));

    auto tiled_copy =
        make_tiled_copy(Copy_Atom<UniversalCopy<Element>, Element>{},
                        Layout<Shape<_1, _16>, Stride<_16, _1>>{},
                        Layout<Shape<_8, _1>, Stride<_1, _8>>{});
    static constexpr auto subgroup_size = 16;
    auto blockDim = syclcompat::dim3(size(tiled_copy));
    //
    // Launch the kernel
    //
    launch<copy_kernel_local<decltype(S), decltype(D), decltype(tiled_copy)>>(
        launch_policy{
            syclcompat::dim3(1), blockDim,
            kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
        S, D, tiled_copy);

    syclcompat::wait_and_throw();
    host_output = device_output;
    for (int i = 0; i < M * N; ++i) {
      EXPECT_EQ(host_output[i], host_src[i]);
    }
  }
}

template <class TensorS, class TensorD, class TiledLoad, class TiledStore>
void copy_kernel_atomic(TensorS S, TensorD D, TiledLoad load,
                        TiledStore store) {

  auto thr_copy_load = load.get_thread_slice(ThreadIdxX());
  Tensor thr_tile_load_S = thr_copy_load.partition_S(S);
  Tensor thr_tile_load_D = thr_copy_load.partition_D(S);

  // Construct a register-backed Tensor with the same shape as each thread's
  // partition Use make_fragment because the first mode is the instruction-local
  // mode
  Tensor fragment =
      make_fragment_like(thr_tile_load_D); // (CopyOp, CopyM, CopyN)

  copy(load, thr_tile_load_S, fragment);

  auto thr_copy_store = store.get_thread_slice(ThreadIdxX());

  Tensor thr_tile_store_D =
      thr_copy_store.partition_D(D); // (CopyOp, CopyM, CopyN)

#if 0
  if (thread(0)) {
    print("thr_tile_load_S: ");
    print(thr_tile_load_S.layout());
    print("\n");

    print("thr_tile_load_D: ");
    print(thr_tile_load_D.layout());
    print("\n");

    print("fragment: ");
    print(fragment.layout());
    print("\n");

    print("thr_tile_store_D: ");
    print(thr_tile_store_D.layout());
    print("\n");
  }
#endif

  copy(store, fragment, thr_tile_store_D);
  copy(store, fragment, thr_tile_store_D);
}

TEST(PVC_2d_copy, load_store_stomic_float) {
  {
    constexpr int M = 8;
    constexpr int N = 16;
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
    cutlass::device_vector<Element> device_output = host_output;

    Tensor S =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));
    Tensor D =
        make_tensor(make_gmem_ptr(device_output.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));

    auto tiled_load =
        make_tiled_copy(Copy_Atom<UniversalCopy<Element>, Element>{},
                        Layout<Shape<_1, _16>, Stride<_16, _1>>{},
                        Layout<Shape<_8, _1>, Stride<_1, _8>>{});
    auto tiled_atom = make_tiled_copy(Copy_Atom<XE_ATOMIC<Element>, Element>{},
                                      Layout<Shape<_1, _16>, Stride<_16, _1>>{},
                                      Layout<Shape<_8, _1>, Stride<_1, _8>>{});
    static constexpr auto subgroup_size = 16;
    auto blockDim = syclcompat::dim3(size(tiled_load));
    //
    // Launch the kernel
    //
    launch<copy_kernel_atomic<decltype(S), decltype(D), decltype(tiled_load),
                              decltype(tiled_atom)>>(
        launch_policy{
            syclcompat::dim3(1), blockDim,
            kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
        S, D, tiled_load, tiled_atom);

    syclcompat::wait_and_throw();
    host_output = device_output;
    for (int i = 0; i < M * N; ++i) {
      EXPECT_EQ(host_output[i], 2 * host_src[i]);
    }
  }
}

TEST(PVC_2d_copy, load_store_stomic_int) {
  {
    constexpr int M = 8;
    constexpr int N = 16;
    using Element = int;
    //
    // Allocate and initialize
    //
    cutlass::host_vector<Element> host_src(M * N);
    cutlass::host_vector<Element> host_output(M * N);

    for (size_t i = 0; i < host_src.size(); ++i) {
      host_src[i] = static_cast<Element>(i);
    }

    cutlass::device_vector<Element> device_src = host_src;
    cutlass::device_vector<Element> device_output = host_output;

    Tensor S =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));
    Tensor D =
        make_tensor(make_gmem_ptr(device_output.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));

    auto tiled_load =
        make_tiled_copy(Copy_Atom<UniversalCopy<Element>, Element>{},
                        Layout<Shape<_1, _16>, Stride<_16, _1>>{},
                        Layout<Shape<_8, _1>, Stride<_1, _8>>{});
    auto tiled_atom = make_tiled_copy(Copy_Atom<XE_ATOMIC<Element>, Element>{},
                                      Layout<Shape<_1, _16>, Stride<_16, _1>>{},
                                      Layout<Shape<_8, _1>, Stride<_1, _8>>{});
    static constexpr auto subgroup_size = 16;
    auto blockDim = syclcompat::dim3(size(tiled_load));
    //
    // Launch the kernel
    //
    launch<copy_kernel_atomic<decltype(S), decltype(D), decltype(tiled_load),
                              decltype(tiled_atom)>>(
        launch_policy{
            syclcompat::dim3(1), blockDim,
            kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
        S, D, tiled_load, tiled_atom);

    syclcompat::wait_and_throw();
    host_output = device_output;
    for (int i = 0; i < M * N; ++i) {
      EXPECT_EQ(host_output[i], 2 * host_src[i]);
    }
  }
}
