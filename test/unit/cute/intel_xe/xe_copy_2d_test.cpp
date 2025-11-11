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
template<class...> class XECopy2DKernelName;

// Device kernel for XE_LOAD_2D testing  
template <class SrcTensor, class DstTensor, int Bits, int Height, int Width>
void xe_copy_2d_kernel(SrcTensor src, DstTensor dst) {
  using namespace cute;
  using Element = typename SrcTensor::value_type;

  // Only execute with the first subgroup to avoid race conditions
  if (sycl::ext::oneapi::this_work_item::get_nd_item<1>().get_group(0) == 0) {
    // Get thread/subgroup information
    auto local_id = int(sycl::ext::oneapi::this_work_item::get_nd_item<1>().get_local_id(0));
    
    // Create block 2D copy inside kernel (device-only operation)
    using CopyOp = XE_LOAD_2D<Bits, Height, Width>;
    auto tiled_copy = make_block_2d_copy(CopyOp{}, src);
    
    // Get thread slice of the tiled copy
    auto thr_copy = tiled_copy.get_slice(local_id);
    
    // Create coordinate tensor for a single tile
    auto coord_shape = make_shape(Int<Height>{}, Int<Width * Bits / sizeof_bits_v<Element>>{});
    Tensor coord_tile = make_identity_tensor(coord_shape);
    
    // Partition source coordinates and create destination fragment
    auto thr_src_coord = thr_copy.partition_S(coord_tile);
    auto thr_dst_frag = thr_copy.partition_fragment_D(coord_tile);
    
    // Perform the copy operation from global memory to registers
    copy(tiled_copy, thr_src_coord, thr_dst_frag);
    
    // For verification, create a 2D store operation to write registers back to destination
    using StoreOp = XE_STORE_2D<Bits, Height, Width>;
    auto tiled_store = make_block_2d_copy(StoreOp{}, dst);
    auto thr_store = tiled_store.get_slice(local_id);
    
    // Create destination coordinates for the store operation
    auto thr_dst_coord = thr_store.partition_D(coord_tile);
    auto thr_src_frag = thr_store.partition_fragment_S(coord_tile);
    
    // Copy the loaded data from registers to the fragment for storing
    copy(thr_dst_frag, thr_src_frag);
    
    // Perform the store operation from registers to global memory
    copy(tiled_store, thr_src_frag, thr_dst_coord);
    
    // Synchronize to ensure all threads complete their operations
    sycl::group_barrier(sycl::ext::oneapi::this_work_item::get_nd_item<1>().get_group());
  }
}

// Host test function template
template <typename Element, int Bits, int Height, int Width, int BlockWidth = Width>
void test_xe_copy_2d() {
  using namespace cute;
  
  // Matrix dimensions - must be compatible with block 2D constraints
  constexpr int M = Height;
  constexpr int N = Width * sizeof_bits_v<Element> / Bits;
  
  // Ensure proper alignment (required for block 2D operations)
  constexpr int elem_alignment = 16 / sizeof(Element);  
  constexpr int aligned_N = ((N + elem_alignment - 1) / elem_alignment) * elem_alignment;
  
  // Allocate and initialize host data
  cutlass::host_vector<Element> host_src(M * aligned_N);
  cutlass::host_vector<Element> host_dst(M * aligned_N);

  
  // Initialize source with test pattern
  for (size_t i = 0; i < host_src.size(); ++i) {
    // Use a safe conversion that works for all numeric types
    if constexpr (std::is_floating_point_v<Element>     || 
                  std::is_same_v<Element, half_t>       || 
                  std::is_same_v<Element, bfloat16_t>   ||
                  std::is_same_v<Element, tfloat32_t>) {
      
      // For floating-point types, convert through float
      float val = static_cast<float>(i % 256) / 255.0f;  // Normalize to [0,1]
      host_src[i] = Element(val);
    } else {
      // For integer types (including uint64_t) and char, direct conversion is safe
      host_src[i] = static_cast<Element>(i % 256);
    }
  }

  // Copy to device
  cutlass::device_vector<Element> device_src = host_src;
  cutlass::device_vector<Element> device_dst(M * aligned_N);
  
  // Create tensors with proper layout
  Tensor tensor_src = 
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<aligned_N>>{}, Stride<Int<aligned_N>, _1>{}));
  
  Tensor tensor_dst = 
        make_tensor(make_gmem_ptr(device_dst.data()),
                    make_layout(Shape<Int<M>, Int<aligned_N>>{}, Stride<Int<aligned_N>, _1>{}));
  
  // Launch kernel - copy creation happens on device
  auto blockDim = compat::dim3(SUBGROUP_SIZE);
  auto gridDim = compat::dim3(1);
  
  launch<xe_copy_2d_kernel<decltype(tensor_src), decltype(tensor_dst), Bits, Height, Width>,
         XECopy2DKernelName<decltype(tensor_src), decltype(tensor_dst)>>(
    launch_policy{
      gridDim, blockDim,
      kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}
    },
    tensor_src, tensor_dst);
  
    compat::wait_and_throw();
    host_dst = device_dst;
    for (int i = 0; i < M * N; ++i) {
        // printf("%d  %d\n", int(h_in[i]), int(h_out[i]));
        EXPECT_EQ(host_dst[i], host_src[i]);
    }
}

TEST(PVC_CuTe_Xe, XE_COPY_2D_uint8) {
  test_xe_copy_2d<uint8_t, 8, 2, 64>();
  test_xe_copy_2d<uint8_t, 8, 3, 64>();
  test_xe_copy_2d<uint8_t, 8, 4, 64>();
  test_xe_copy_2d<uint8_t, 8, 5, 64>();
  test_xe_copy_2d<uint8_t, 8, 6, 64>();
  test_xe_copy_2d<uint8_t, 8, 7, 64>();
  test_xe_copy_2d<uint8_t, 8, 8, 64>();
}

TEST(PVC_CuTe_Xe, XE_COPY_2D_int8) {
  test_xe_copy_2d<int8_t, 8, 2, 64>();
  test_xe_copy_2d<int8_t, 8, 3, 64>();
  test_xe_copy_2d<int8_t, 8, 4, 64>();
  test_xe_copy_2d<int8_t, 8, 5, 64>();
  test_xe_copy_2d<int8_t, 8, 6, 64>();
  test_xe_copy_2d<int8_t, 8, 7, 64>();
  test_xe_copy_2d<int8_t, 8, 8, 64>();
}

TEST(PVC_CuTe_Xe, XE_COPY_2D_uint16) {
  test_xe_copy_2d<uint16_t, 16, 2, 32>();
  test_xe_copy_2d<uint16_t, 16, 3, 32>();
  test_xe_copy_2d<uint16_t, 16, 4, 32>();
  test_xe_copy_2d<uint16_t, 16, 5, 32>();
  test_xe_copy_2d<uint16_t, 16, 6, 32>();
  test_xe_copy_2d<uint16_t, 16, 7, 32>();
  test_xe_copy_2d<uint16_t, 16, 8, 32>();
}

TEST(PVC_CuTe_Xe, XE_COPY_2D_int16) {
  test_xe_copy_2d<int16_t, 16, 2, 32>();
  test_xe_copy_2d<int16_t, 16, 3, 32>();
  test_xe_copy_2d<int16_t, 16, 4, 32>();
  test_xe_copy_2d<int16_t, 16, 5, 32>();
  test_xe_copy_2d<int16_t, 16, 6, 32>();
  test_xe_copy_2d<int16_t, 16, 7, 32>();
  test_xe_copy_2d<int16_t, 16, 8, 32>();
}

TEST(PVC_CuTe_Xe, XE_COPY_2D_half) {
  test_xe_copy_2d<half_t, 16, 2, 32>();
  test_xe_copy_2d<half_t, 16, 3, 32>();
  test_xe_copy_2d<half_t, 16, 4, 32>();
  test_xe_copy_2d<half_t, 16, 5, 32>();
  test_xe_copy_2d<half_t, 16, 6, 32>();
  test_xe_copy_2d<half_t, 16, 7, 32>();
  test_xe_copy_2d<half_t, 16, 8, 32>();
}

TEST(PVC_CuTe_Xe, XE_COPY_2D_bfloat16) {
  test_xe_copy_2d<bfloat16_t, 16, 2, 32>();
  test_xe_copy_2d<bfloat16_t, 16, 3, 32>();
  test_xe_copy_2d<bfloat16_t, 16, 4, 32>();
  test_xe_copy_2d<bfloat16_t, 16, 5, 32>();
  test_xe_copy_2d<bfloat16_t, 16, 6, 32>();
  test_xe_copy_2d<bfloat16_t, 16, 7, 32>();
  test_xe_copy_2d<bfloat16_t, 16, 8, 32>();
}

TEST(PVC_CuTe_Xe, XE_COPY_2D_uint32) {
  test_xe_copy_2d<uint32_t, 32, 2, 16>();
  test_xe_copy_2d<uint32_t, 32, 3, 16>();
  test_xe_copy_2d<uint32_t, 32, 4, 16>();
  test_xe_copy_2d<uint32_t, 32, 5, 16>();
  test_xe_copy_2d<uint32_t, 32, 6, 16>();
  test_xe_copy_2d<uint32_t, 32, 7, 16>();
  test_xe_copy_2d<uint32_t, 32, 8, 16>();
}

TEST(PVC_CuTe_Xe, XE_COPY_2D_int32) {
  test_xe_copy_2d<int32_t, 32, 2, 16>();
  test_xe_copy_2d<int32_t, 32, 3, 16>();
  test_xe_copy_2d<int32_t, 32, 4, 16>();
  test_xe_copy_2d<int32_t, 32, 5, 16>();
  test_xe_copy_2d<int32_t, 32, 6, 16>();
  test_xe_copy_2d<int32_t, 32, 7, 16>();
  test_xe_copy_2d<int32_t, 32, 8, 16>();
}

TEST(PVC_CuTe_Xe, XE_COPY_2D_float) {
  test_xe_copy_2d<float, 32, 2, 16>();
  test_xe_copy_2d<float, 32, 3, 16>();
  test_xe_copy_2d<float, 32, 4, 16>();
  test_xe_copy_2d<float, 32, 5, 16>();
  test_xe_copy_2d<float, 32, 6, 16>();
  test_xe_copy_2d<float, 32, 7, 16>();
  test_xe_copy_2d<float, 32, 8, 16>();
}

TEST(PVC_CuTe_Xe, XE_COPY_2D_tfloat32) {
  test_xe_copy_2d<tfloat32_t, 32, 2, 16>();
  test_xe_copy_2d<tfloat32_t, 32, 3, 16>();
  test_xe_copy_2d<tfloat32_t, 32, 4, 16>();
  test_xe_copy_2d<tfloat32_t, 32, 5, 16>();
  test_xe_copy_2d<tfloat32_t, 32, 6, 16>();
  test_xe_copy_2d<tfloat32_t, 32, 7, 16>();
  test_xe_copy_2d<tfloat32_t, 32, 8, 16>();
}

TEST(PVC_CuTe_Xe, XE_COPY_2D_char) {
  test_xe_copy_2d<char, 8, 2, 64>();
  test_xe_copy_2d<char, 8, 3, 64>();
  test_xe_copy_2d<char, 8, 4, 64>();
  test_xe_copy_2d<char, 8, 5, 64>();
  test_xe_copy_2d<char, 8, 6, 64>();
  test_xe_copy_2d<char, 8, 7, 64>();
  test_xe_copy_2d<char, 8, 8, 64>();
}

#else

// For the fallback case
#include "cutlass_unit_test.h"

TEST(PVC_CuTe_Xe, XE_COPY_2D_SKIPPED) {
  GTEST_SKIP() << "XE_COPY_2D tests require IGC version 2.18 or higher. skipped";
}

#endif
