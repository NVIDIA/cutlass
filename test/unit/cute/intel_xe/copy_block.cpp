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

template <class TensorS, class TensorD, class TiledLoad, class TiledStore,
          class CopyOp = void>
void copy_kernel_vectorized(TensorS S, TensorD D, TiledLoad load,
                            TiledStore store) {
  const int m_coord = 0;
  const int n_coord = 0;
  const int l_coord = BlockIdxZ();

  // ==========  load   ==========
  auto thr_copy_load = load.get_thread_slice(ThreadIdxX());
  auto coord_tensor_load = cute::get_pvc_tensor(append(S.shape(),_1{}));
  auto thr_tile_load_coord = thr_copy_load.partition_S(coord_tensor_load)(_,_,_,0);
  auto fragment = make_tensor<typename TensorS::value_type>(thr_tile_load_coord.shape());
  if constexpr (cute::detail::has_prefetch<CopyOp>)
    prefetch(load, thr_tile_load_coord);
  copy(load, thr_tile_load_coord, fragment);

  // ==========  store   ==========
  auto thr_copy_store = store.get_thread_slice(ThreadIdxX());
  auto coord_tensor_store = cute::get_pvc_tensor(append(D.shape(),_1{}));
  auto thr_tile_store_coord = thr_copy_store.partition_D(coord_tensor_store)(_,_,_,0);
  Tensor frag_view =
      make_tensor(static_cast<decltype(fragment) &&>(fragment).data(),
                  thr_tile_store_coord.shape());
  copy(store, frag_view, thr_tile_store_coord);

#if 0
  if (thread(0)) {
    print("fragment: ");
    print(fragment.layout());
    print("\n");

    print("frag_view: ");
    print(frag_view.layout());
    print("\n");

    print("thr_tile_load_coord: ");
    print(thr_tile_load_coord.layout());
    print("\n");

    print("thr_tile_store_coord: ");
    print(thr_tile_store_coord.layout());
    print("\n");
  }
#endif
}
template <class dtype, class load, class store, uint32_t M, uint32_t N,
          bool trans = false>
struct copy_op;

template <class dtype, class load, class store, uint32_t M, uint32_t N>
struct copy_op<dtype, load, store, M, N, false> {
  void operator()() {
    //
    // Allocate and initialize
    //
    cutlass::host_vector<dtype> host_src(M * N);
    cutlass::host_vector<dtype> host_output(M * N);

    for (size_t i = 0; i < host_src.size(); ++i) {
      host_src[i] = static_cast<dtype>(i);
    }

    cutlass::device_vector<dtype> device_src = host_src;
    cutlass::device_vector<dtype> device_output = host_output;

    Tensor S =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));
    Tensor D =
        make_tensor(make_gmem_ptr(device_output.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));

    auto tiled_load = make_tiled_copy(
        Copy_Atom<Copy_Traits<load, decltype(S)>, dtype>{}.with(device_src.data(), M, N),
        Layout<Shape<_1, Int<SUBGROUP_SIZE>>>{},
        make_layout(shape_div(typename Copy_Traits<load, decltype(S)>::BlockShape{}, Shape<_1, _16>{})));

    auto tiled_store = make_tiled_copy(
        Copy_Atom<Copy_Traits<store, decltype(D)>, dtype>{}.with(device_output.data(), M, N),
        Layout<Shape<_1, Int<SUBGROUP_SIZE>>>{},
        make_layout(shape_div(typename Copy_Traits<store, decltype(S)>::BlockShape{}, Shape<_1, _16>{})));

    auto blockDim = syclcompat::dim3(size(tiled_load));
    //
    // Launch the kernel
    //
    launch<
        copy_kernel_vectorized<decltype(S), decltype(D), decltype(tiled_load),
                               decltype(tiled_store), load>>(
        launch_policy{
            syclcompat::dim3(1), blockDim,
            kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
        S, D, tiled_load, tiled_store);

    syclcompat::wait_and_throw();
    host_output = device_output;
    for (int i = 0; i < M * N; ++i) {
      EXPECT_EQ(host_output[i], host_src[i]);
    }
  }
};

template <class load, uint32_t M, uint32_t N>
struct copy_op<char, load, XE_2D_U8x2x32_ST_N, M, N, false> {
  void operator()() {
    //
    // Allocate and initialize
    //
    using dtype = char;
    cutlass::host_vector<dtype> host_src(M * N);
    cutlass::host_vector<dtype> host_output(M * N);

    for (size_t i = 0; i < host_src.size(); ++i) {
      host_src[i] = static_cast<dtype>(i);
    }

    cutlass::device_vector<dtype> device_src = host_src;
    cutlass::device_vector<dtype> device_output = host_output;

    Tensor S =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));
    Tensor D =
        make_tensor(make_gmem_ptr(device_output.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));

    auto tiled_load = make_tiled_copy(
        Copy_Atom<Copy_Traits<load, decltype(S)>, dtype>{}.with(S), Layout<Shape<_1, _16>>{},
        make_layout(shape_div(typename Copy_Traits<load, decltype(S)>::BlockShape{}, Shape<_1, _16>{})));

    auto tiled_store = make_tiled_copy(
        Copy_Atom<Copy_Traits<XE_2D_U8x2x32_ST_N, decltype(D)>, dtype>{}.with(D), Layout<Shape<_1, _16>>{},
        make_layout(shape_div(typename Copy_Traits<XE_2D_U8x2x32_ST_N, decltype(S)>::BlockShape{}, Shape<_1, _16>{})));

    auto blockDim = syclcompat::dim3(size(tiled_load));
    //
    // Launch the kernel
    //
    launch<
        copy_kernel_vectorized<decltype(S), decltype(D), decltype(tiled_load),
                               decltype(tiled_store), load>>(
        launch_policy{
            syclcompat::dim3(1), blockDim,
            kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
        S, D, tiled_load, tiled_store);

    syclcompat::wait_and_throw();
    host_output = device_output;
    for (int i = 0; i < M * N; ++i) {
      EXPECT_EQ(host_output[i], host_src[i]);
    }
  }
};

template <class load, uint32_t M, uint32_t N>
struct copy_op<uint16_t, load, XE_2D_U16x2x16_ST_N, M, N, false> {
  void operator()() {
    //
    // Allocate and initialize
    //
    using dtype = uint16_t;
    cutlass::host_vector<dtype> host_src(M * N);
    cutlass::host_vector<dtype> host_output(M * N);

    for (size_t i = 0; i < host_src.size(); ++i) {
      host_src[i] = static_cast<dtype>(i);
    }

    cutlass::device_vector<dtype> device_src = host_src;
    cutlass::device_vector<dtype> device_output = host_output;

    Tensor S =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));
    Tensor D = make_tensor(
        make_gmem_ptr(device_output.data()),
        make_layout(Shape<Int<M * 2>, Int<N / 2>>{}, Stride<Int<N / 2>, _1>{}));

    auto tiled_load = make_tiled_copy(
        Copy_Atom<Copy_Traits<load, decltype(S)>, dtype>{}.with(device_src.data(), M, N),
        Layout<Shape<_1, Int<SUBGROUP_SIZE>>>{},
        make_layout(shape_div(typename Copy_Traits<load, decltype(S)>::BlockShape{}, Shape<_1, _16>{})));
    auto tiled_store = make_tiled_copy(
        Copy_Atom<Copy_Traits<XE_2D_U16x2x16_ST_N, decltype(D)>, uint16_t>{}.with(
            device_output.data(), M * 2, N / 2), Layout<Shape<_1, _16>>{},
        make_layout(shape_div(typename Copy_Traits<XE_2D_U16x2x16_ST_N, decltype(S)>::BlockShape{}, Shape<_1, _16>{})));
    auto blockDim = syclcompat::dim3(size(tiled_load));
    //
    // Launch the kernel
    //
    launch<
        copy_kernel_vectorized<decltype(S), decltype(D), decltype(tiled_load),
                               decltype(tiled_store), load>>(
        launch_policy{
            syclcompat::dim3(1), blockDim,
            kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
        S, D, tiled_load, tiled_store);

    syclcompat::wait_and_throw();
    host_output = device_output;
    for (int i = 0; i < M * 2; ++i) {
      for (int j = 0; j < N / 2; ++j) {
        EXPECT_EQ(host_output[i * N / 2 + j],
                  host_src[(i % M) * N + j + (i / M) * N / 2]);
      }
    }
  }
};

template <class load, class store, int32_t M, int32_t N>
struct copy_op<uint32_t, load, store, M, N, true> {
  void operator()() {
    //
    // Allocate and initialize
    //
    using dtype = uint32_t;
    cutlass::host_vector<dtype> host_src(M * N);
    cutlass::host_vector<dtype> host_output(M * N);

    for (size_t i = 0; i < host_src.size(); ++i) {
      host_src[i] = static_cast<dtype>(i);
    }

    cutlass::device_vector<dtype> device_src = host_src;
    cutlass::device_vector<dtype> device_output = host_output;

    Tensor S =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<N>>{}, Stride<Int<N>, _1>{}));
    Tensor D =
        make_tensor(make_gmem_ptr(device_output.data()),
                    make_layout(Shape<Int<N>, Int<M>>{}, Stride<Int<M>, _1>{}));

    auto tiled_load = make_tiled_copy(
        Copy_Atom<Copy_Traits<load, decltype(S)>, dtype>{}.with(device_src.data(), M, N),
        Layout<Shape<Int<SUBGROUP_SIZE>, _1>>{},
        make_layout(shape_div(typename Copy_Traits<load, decltype(S)>::BlockShape{}, Shape<_1, _16>{})));
    auto tiled_store = make_tiled_copy(
        Copy_Atom<Copy_Traits<store, decltype(D)>, dtype>{}.with(device_output.data(), N, M),
        Layout<Shape<_1, Int<SUBGROUP_SIZE>>>{},
        make_layout(shape_div(typename Copy_Traits<store, decltype(S)>::BlockShape{}, Shape<_1, _16>{})));
    auto blockDim = syclcompat::dim3(size(tiled_load));
    //
    // Launch the kernel
    //
    launch<
        copy_kernel_vectorized<decltype(S), decltype(D), decltype(tiled_load),
                               decltype(tiled_store), load>>(
        launch_policy{
            syclcompat::dim3(1), blockDim,
            kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
        S, D, tiled_load, tiled_store);

    syclcompat::wait_and_throw();
    host_output = device_output;
    for (int i = 0; i < N; ++i) {
      for (int j = 0; j < M; ++j) {
        EXPECT_EQ(host_output[i * M + j], host_src[j * N + i]);
      }
    }
  }
};

TEST(PVC_CuTe_Xe, block_2d_16bits_n) {
  copy_op<uint16_t, XE_2D_U16x1x16_LD_N, XE_2D_U16x1x16_ST_N, 1, 16>{}();
  copy_op<uint16_t, XE_2D_U16x4x16_LD_N, XE_2D_U16x4x16_ST_N, 4, 16>{}();
  copy_op<uint16_t, XE_2D_U16x8x16_LD_N, XE_2D_U16x8x16_ST_N, 8, 16>{}();
  copy_op<uint16_t, XE_2D_U16x16x16_LD_N, XE_2D_U16x8x16_ST_N, 16, 16>{}();
  copy_op<uint16_t, XE_2D_U16x16x16_LD_N, XE_2D_U16x8x16_ST_N, 32, 16>{}();
}

TEST(PVC_CuTe_Xe, block_2d_32bits_n) {
  copy_op<uint32_t, XE_2D_U32x1x16_LD_N, XE_2D_U32x1x16_ST_N, 1, 16>{}();
  copy_op<uint32_t, XE_2D_U32x2x16_LD_N, XE_2D_U32x2x16_ST_N, 2, 16>{}();
  copy_op<uint32_t, XE_2D_U32x4x16_LD_N, XE_2D_U32x4x16_ST_N, 4, 16>{}();
  copy_op<uint32_t, XE_2D_U32x8x16_LD_N, XE_2D_U32x8x16_ST_N, 8, 16>{}();
  copy_op<uint32_t, XE_2D_U32x16x16_LD_N, XE_2D_U32x8x16_ST_N, 16, 16>{}();
  copy_op<uint32_t, XE_2D_U32x32x16_LD_N, XE_2D_U32x8x16_ST_N, 32, 16>{}();
}

TEST(PVC_CuTe_Xe, block_2d_8bits_n) {
  copy_op<char, XE_2D_U8x2x32_LD_N, XE_2D_U8x2x32_ST_N, 2, 32>{}();
  copy_op<char, XE_2D_U8x4x32_LD_N, XE_2D_U8x2x32_ST_N, 4, 32>{}();
  copy_op<char, XE_2D_U8x8x32_LD_N, XE_2D_U8x2x32_ST_N, 8, 32>{}();
  copy_op<char, XE_2D_U8x16x32_LD_N, XE_2D_U8x2x32_ST_N, 16, 32>{}();
  copy_op<char, XE_2D_U8x32x32_LD_N, XE_2D_U8x2x32_ST_N, 32, 32>{}();
}

TEST(PVC_CuTE_Xe, block_2d_16bits_n_v2) {
  copy_op<uint16_t, XE_2D_U16x1x32_LD_N, XE_2D_U16x2x16_ST_N, 1, 32>{}();
  copy_op<uint16_t, XE_2D_U16x2x32_LD_N, XE_2D_U16x2x16_ST_N, 2, 32>{}();
  copy_op<uint16_t, XE_2D_U16x4x32_LD_N, XE_2D_U16x2x16_ST_N, 4, 32>{}();
  copy_op<uint16_t, XE_2D_U16x8x32_LD_N, XE_2D_U16x2x16_ST_N, 8, 32>{}();
  copy_op<uint16_t, XE_2D_U16x16x32_LD_N, XE_2D_U16x2x16_ST_N, 16, 32>{}();
  copy_op<uint16_t, XE_2D_U16x32x32_LD_N, XE_2D_U16x2x16_ST_N, 32, 32>{}();
}

TEST(PVC_CuTe_Xe, block_2d_16bits_vnni) {
  copy_op<uint16_t, XE_2D_U16x16x16_LD_V, XE_2D_U16x8x16_ST_N, 16, 16>{}();
  copy_op<uint16_t, XE_2D_U16x32x16_LD_V, XE_2D_U16x8x16_ST_N, 32, 16>{}();
}

TEST(PVC_CuTe_Xe, block_2d_32bits_transpose) {
  copy_op<uint32_t, XE_2D_U32x16x2_LD_T, XE_2D_U32x2x16_ST_N, 16, 2, true>{}();
  copy_op<uint32_t, XE_2D_U32x16x4_LD_T, XE_2D_U32x4x16_ST_N, 16, 4, true>{}();
  copy_op<uint32_t, XE_2D_U32x16x8_LD_T, XE_2D_U32x8x16_ST_N, 16, 8, true>{}();
}
