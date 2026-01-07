/***************************************************************************************************
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the disclaimer.
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
 * OF THIS SOFTWARE, EVEN IF ADVISED OF POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/

#include "cutlass/detail/layout.hpp"

#include <cute/tensor.hpp>
#include <cute/atom/copy_atom.hpp>
#include <cute/atom/copy_traits_xe_2d.hpp>
#include <cute/arch/copy_xe_2d.hpp>
#include <sycl/sycl.hpp>
#include <cute/util/compat.hpp>

#include "cutlass_unit_test.h"
#include "utils.hpp"

using namespace cute;
using namespace cutlass;
using namespace compat::experimental;

#define SUBGROUP_SIZE (16)

#if (IGC_VERSION_MAJOR > 2) || (IGC_VERSION_MAJOR == 2 && IGC_VERSION_MINOR >= 18)

// Kernel name for unique identification
template<class...> class XETranspose2DKernelName;

// Device kernel for XE_LOAD_2D_TRANSPOSE testing
// Note: Transpose load performs HW-level transpose during load operation
// Memory layout (Height×Width) is transposed to register layout (Width×Height)
template <class SrcTensor, class DstTensor, int Bits, int Height, int Width>
void xe_transpose_2d_kernel(SrcTensor src, DstTensor dst) {
  using namespace cute;
  using Element = typename SrcTensor::value_type;

  // Only execute with the first subgroup to avoid race conditions
  if (sycl::ext::oneapi::this_work_item::get_nd_item<1>().get_group(0) == 0) {
    // Get thread/subgroup information
    auto local_id = int(sycl::ext::oneapi::this_work_item::get_nd_item<1>().get_local_id(0));

    // Create block 2D transpose load inside kernel (device-only operation)
    using TransposeOp = XE_LOAD_2D_TRANSPOSE<Bits, Height, Width>;
    auto tiled_transpose = make_block_2d_copy(TransposeOp{}, src);

    // Get thread slice of the tiled transpose
    auto thr_transpose = tiled_transpose.get_slice(local_id);

    // Create coordinate tensor for a single tile
    // Note: coordinates are in memory space (Height×Width)
    auto coord_shape = make_shape(Int<Height>{}, Int<Width * Bits / sizeof_bits_v<Element>>{});
    Tensor coord_tile = make_identity_tensor(coord_shape);

    // Partition source coordinates for transpose load
    auto thr_src_coord = thr_transpose.partition_S(coord_tile);

    // Create destination fragment - transpose changes the layout in registers
    auto thr_dst_frag = thr_transpose.partition_fragment_D(coord_tile);

    // Perform the transpose load operation from global memory to registers
    // Data is transposed during this operation by hardware
    copy(tiled_transpose, thr_src_coord, thr_dst_frag);

    // For verification, we need to store the transposed data back
    // Note: Output will be in transposed layout (Width×Height in memory)
    // We store to the transposed destination shape
    auto dst_coord_shape = make_shape(Int<Width * Bits / sizeof_bits_v<Element>>{}, Int<Height>{});
    Tensor dst_coord_tile = make_identity_tensor(dst_coord_shape);

    using StoreOp = XE_STORE_2D<Bits, Width, Height>;  // Swapped dimensions
    auto tiled_store = make_block_2d_copy(StoreOp{}, dst);
    auto thr_store = tiled_store.get_slice(local_id);

    // Create destination coordinates for the store operation
    auto thr_dst_coord = thr_store.partition_D(dst_coord_tile);
    auto thr_src_frag = thr_store.partition_fragment_S(dst_coord_tile);

    // Copy from transpose fragment to store fragment
    copy(thr_dst_frag, thr_src_frag);

    // Perform the store operation from registers to global memory
    copy(tiled_store, thr_src_frag, thr_dst_coord);

    // Synchronize to ensure all threads complete their operations
    sycl::group_barrier(sycl::ext::oneapi::this_work_item::get_nd_item<1>().get_group());
  }
}

// Host test function template for transpose operations
template <typename Element, int Bits, int Height, int Width>
void test_xe_transpose_2d() {
  using namespace cute;

  // Source matrix dimensions (Height×Width in memory)
  constexpr int M = Height;
  constexpr int N = Width * sizeof_bits_v<Element> / Bits;

  // Destination will be transposed (Width×Height in memory)
  constexpr int M_dst = N;
  constexpr int N_dst = M;

  // Ensure proper alignment
  constexpr int elem_alignment = 16 / sizeof(Element);
  constexpr int aligned_N = ((N + elem_alignment - 1) / elem_alignment) * elem_alignment;
  constexpr int aligned_M_dst = ((M_dst + elem_alignment - 1) / elem_alignment) * elem_alignment;

  // Allocate host memory
  cutlass::host_vector<Element> host_src(M * aligned_N);
  cutlass::host_vector<Element> host_dst(M_dst * aligned_M_dst);

  // Initialize source with test pattern
  for (int i = 0; i < M; ++i) {
    for (int j = 0; j < N; ++j) {
      Element val;
      if constexpr (std::is_floating_point_v<Element> ||
                    std::is_same_v<Element, half_t> ||
                    std::is_same_v<Element, bfloat16_t>) {
        val = Element(static_cast<float>(i * N + j) / 100.0f);
      } else {
        val = static_cast<Element>((i * N + j) % 256);
      }
      host_src[i * aligned_N + j] = val;
    }
  }

  // Copy to device
  cutlass::device_vector<Element> device_src = host_src;
  cutlass::device_vector<Element> device_dst(M_dst * aligned_M_dst);

  // Create source tensor (Height×Width)
  Tensor tensor_src =
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<aligned_N>>{},
                               Stride<Int<aligned_N>, _1>{}));

  // Create destination tensor (Width×Height) - transposed shape
  Tensor tensor_dst =
        make_tensor(make_gmem_ptr(device_dst.data()),
                    make_layout(Shape<Int<M_dst>, Int<aligned_M_dst>>{},
                               Stride<Int<aligned_M_dst>, _1>{}));

  // Launch kernel
  auto blockDim = compat::dim3(SUBGROUP_SIZE);
  auto gridDim = compat::dim3(1);

  launch<xe_transpose_2d_kernel<decltype(tensor_src), decltype(tensor_dst), Bits, Height, Width>,
         XETranspose2DKernelName<decltype(tensor_src), decltype(tensor_dst)>>(
    launch_policy{
      gridDim, blockDim,
      kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}
    },
    tensor_src, tensor_dst);

  compat::wait_and_throw();
  host_dst = device_dst;

  // Verify transpose: dst[j][i] should equal src[i][j]
  for (int i = 0; i < M; ++i) {
    for (int j = 0; j < N; ++j) {
      Element src_val = host_src[i * aligned_N + j];
      Element dst_val = host_dst[j * aligned_M_dst + i];
      EXPECT_EQ(dst_val, src_val)
        << "Mismatch at src[" << i << "][" << j << "] vs dst[" << j << "][" << i << "]";
    }
  }
}

// Test 32-bit transpose operations (Width ≤ 8 constraint)
TEST(CuTe_Xe, XE_TRANSPOSE_2D_float_4x8) {
  test_xe_transpose_2d<float, 32, 4, 8>();
}

TEST(CuTe_Xe, XE_TRANSPOSE_2D_float_8x8) {
  test_xe_transpose_2d<float, 32, 8, 8>();
}

TEST(CuTe_Xe, XE_TRANSPOSE_2D_float_4x4) {
  test_xe_transpose_2d<float, 32, 4, 4>();
}

TEST(CuTe_Xe, XE_TRANSPOSE_2D_int32_4x8) {
  test_xe_transpose_2d<int32_t, 32, 4, 8>();
}

TEST(CuTe_Xe, XE_TRANSPOSE_2D_uint32_4x8) {
  test_xe_transpose_2d<uint32_t, 32, 4, 8>();
}

#else

TEST(CuTe_Xe, XE_TRANSPOSE_2D_SKIPPED) {
  GTEST_SKIP() << "XE_LOAD_2D_TRANSPOSE tests require IGC version 2.18 or higher. skipped";
}

#endif
