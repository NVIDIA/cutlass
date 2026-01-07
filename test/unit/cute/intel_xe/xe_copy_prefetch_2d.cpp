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
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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

#if (IGC_VERSION_MAJOR > 2) || (IGC_VERSION_MAJOR == 2 && IGC_VERSION_MINOR >= 18) 

// Kernel name for unique identification - includes Bits to ensure uniqueness
template<class SrcTensor, int Bits, int Height, int Width> 
class XEPrefetch2DKernelName;

// Device kernel for XE_PREFETCH_2D testing  
template <class SrcTensor, int Bits, int Height, int Width>
void xe_prefetch_2d_kernel(SrcTensor src) {
  using namespace cute;
  using namespace sycl::ext::oneapi::this_work_item;
  using Element = typename SrcTensor::value_type;

  // Only execute with the first subgroup to avoid race conditions
  if (get_nd_item<1>().get_group(0) == 0) {
    // Get thread/subgroup information
    auto local_id = int(get_nd_item<1>().get_local_id(0));
    
    // Create block 2D prefetch inside kernel (device-only operation)
    using PrefetchOp = XE_PREFETCH_2D<Bits, Height, Width>;
    auto tiled_prefetch = make_block_2d_copy(PrefetchOp{}, src);
    
    // Get thread slice of the tiled prefetch
    auto thr_prefetch = tiled_prefetch.get_slice(local_id);
    
    // Create coordinate tensor for a single tile
    auto coord_shape = make_shape(Int<Height>{}, Int<Width * Bits / sizeof_bits_v<Element>>{});
    Tensor coord_tile = make_identity_tensor(coord_shape);
    
    // Partition source coordinates for prefetch
    auto thr_src_coord = thr_prefetch.partition_S(coord_tile);
    
    // Create dummy destination fragment (prefetch ignores destination)
    auto thr_dst_frag = thr_prefetch.partition_fragment_D(coord_tile);
    
    // Perform the prefetch operation
    copy(tiled_prefetch, thr_src_coord, thr_dst_frag);
    
    // Synchronize to ensure all threads complete their operations
    sycl::group_barrier(get_nd_item<1>().get_group());
  }
}

// Host test function template for XE_PREFETCH_2D
template <typename Element, int Bits, int Height, int Width>
void test_xe_prefetch_2d() {
  using namespace cute;
  
  // Matrix dimensions - must be compatible with block 2D constraints
  constexpr int M = Height;
  constexpr int N = (Width * sizeof_bits_v<Element>) / Bits;
  
  // Ensure proper alignment (required for block 2D operations)
  constexpr int elem_alignment = 16 / sizeof(Element);  
  constexpr int aligned_N = ((N + elem_alignment - 1) / elem_alignment) * elem_alignment;
  
  // Allocate and initialize host data
  cutlass::host_vector<Element> host_src(M * aligned_N);
  
  // Initialize source with test pattern
  for (size_t i = 0; i < host_src.size(); ++i) {
    host_src[i] = static_cast<Element>(static_cast<float>(i % 256));
  }

  // Copy to device
  cutlass::device_vector<Element> device_src = host_src;
  
  // Create tensors with proper layout
  Tensor tensor_src = 
        make_tensor(make_gmem_ptr(device_src.data()),
                    make_layout(Shape<Int<M>, Int<aligned_N>>{}, Stride<Int<aligned_N>, _1>{}));
  
  // Launch kernel - prefetch happens on device
  auto blockDim = compat::dim3(intel::sg_size);
  auto gridDim = compat::dim3(1);
  
  launch<xe_prefetch_2d_kernel<decltype(tensor_src), Bits, Height, Width>,
         XEPrefetch2DKernelName<decltype(tensor_src), Bits, Height, Width>>(
    launch_policy{
      gridDim, blockDim,
      kernel_properties{sycl_exp::sub_group_size<intel::sg_size>}
    },
    tensor_src);
  
  compat::wait_and_throw();
  
  // Note: XE_PREFETCH_2D just prefetches to cache, no verification needed
  EXPECT_TRUE(true) << "XE_PREFETCH_2D operation completed successfully";
}

TEST(CuTe_Xe, XE_PREFETCH_2D_uint8) {
  test_xe_prefetch_2d<uint8_t, 8, 2, 64>();
  test_xe_prefetch_2d<uint8_t, 8, 4, 64>();
}

TEST(CuTe_Xe, XE_PREFETCH_2D_int16) {
  test_xe_prefetch_2d<int16_t, 16, 2, 32>();
  test_xe_prefetch_2d<int16_t, 16, 4, 32>();
}

TEST(CuTe_Xe, XE_PREFETCH_2D_float) {
  test_xe_prefetch_2d<float, 32, 2, 16>();
  test_xe_prefetch_2d<float, 32, 4, 16>();
}


// Test 4: 8-bit Minimal Configuration
TEST(CuTe_Xe, XE_PREFETCH_2D_8bit_Minimal) {
  test_xe_prefetch_2d<uint8_t, 8, 1, 32>();
}

// Test 5: 8-bit Small Height
TEST(CuTe_Xe, XE_PREFETCH_2D_8bit_SmallHeight) {
  test_xe_prefetch_2d<uint8_t, 8, 2, 64>();
}

// Test 6: 8-bit Medium Configuration
TEST(CuTe_Xe, XE_PREFETCH_2D_8bit_Medium) {
  test_xe_prefetch_2d<uint8_t, 8, 4, 64>();
}

// Test 7: 8-bit Large Height
TEST(CuTe_Xe, XE_PREFETCH_2D_8bit_LargeHeight) {
  test_xe_prefetch_2d<uint8_t, 8, 8, 64>();
}

// Test 8: 8-bit Wide Configuration (respecting 512-bit width limit)
TEST(CuTe_Xe, XE_PREFETCH_2D_8bit_Wide) {
  test_xe_prefetch_2d<int8_t, 8, 4, 64>();  // 8*64=512 bits (max)
}

// Test 9: 16-bit Minimal Configuration
TEST(CuTe_Xe, XE_PREFETCH_2D_16bit_Minimal) {
  test_xe_prefetch_2d<int16_t, 16, 1, 16>();
}

// Test 10: 16-bit Small Configuration
TEST(CuTe_Xe, XE_PREFETCH_2D_16bit_Small) {
  test_xe_prefetch_2d<int16_t, 16, 2, 32>();
}

// Test 11: 16-bit Medium Configuration
TEST(CuTe_Xe, XE_PREFETCH_2D_16bit_Medium) {
  test_xe_prefetch_2d<uint16_t, 16, 4, 32>();
}

// Test 12: 16-bit Large Height
TEST(CuTe_Xe, XE_PREFETCH_2D_16bit_LargeHeight) {
  test_xe_prefetch_2d<int16_t, 16, 8, 32>();
}

// Test 13: 16-bit Wide Configuration (respecting 512-bit width limit)
TEST(CuTe_Xe, XE_PREFETCH_2D_16bit_Wide) {
  test_xe_prefetch_2d<bfloat16_t, 16, 4, 32>();  // 16*32=512 bits (max)
}

// Test 14: 32-bit Minimal Configuration
TEST(CuTe_Xe, XE_PREFETCH_2D_32bit_Minimal) {
  test_xe_prefetch_2d<float, 32, 1, 16>();  // 32*16=512 bits (max)
}

// Test 15: 32-bit Small Configuration
TEST(CuTe_Xe, XE_PREFETCH_2D_32bit_Small) {
  test_xe_prefetch_2d<float, 32, 2, 16>();
}

// Test 16: 32-bit Medium Configuration
TEST(CuTe_Xe, XE_PREFETCH_2D_32bit_Medium) {
  test_xe_prefetch_2d<int32_t, 32, 4, 16>();
}

// Test 17: 32-bit Large Height
TEST(CuTe_Xe, XE_PREFETCH_2D_32bit_LargeHeight) {
  test_xe_prefetch_2d<float, 32, 8, 16>();
}

// Test 18: 32-bit Wide Configuration (respecting 512-bit width limit)
TEST(CuTe_Xe, XE_PREFETCH_2D_32bit_Wide) {
  test_xe_prefetch_2d<float, 32, 4, 16>();  // 32*16=512 bits (max)
}

// Test 19: 64-bit Small Configuration
TEST(CuTe_Xe, XE_PREFETCH_2D_64bit_Small) {
  test_xe_prefetch_2d<double, 64, 2, 8>();  // 64*8=512 bits (max)
}

// Test 20: 64-bit Medium Configuration
TEST(CuTe_Xe, XE_PREFETCH_2D_64bit_Medium) {
  test_xe_prefetch_2d<double, 64, 4, 8>();  // 64*8=512 bits (max)
}

// Test 21: 64-bit Large Height  
TEST(CuTe_Xe, XE_PREFETCH_2D_64bit_LargeHeight) {
  test_xe_prefetch_2d<int64_t, 64, 8, 8>();  // 64*8=512 bits (max)
}

// Test 22: Mixed Data Types - Power of Two Heights
TEST(CuTe_Xe, XE_PREFETCH_2D_PowerOfTwo_Heights) {
  // 8-bit with power-of-two heights
  test_xe_prefetch_2d<uint8_t, 8, 16, 64>();
  test_xe_prefetch_2d<uint8_t, 8, 32, 32>();
  
  // 16-bit with power-of-two heights
  test_xe_prefetch_2d<int16_t, 16, 16, 32>();
  
  // 32-bit with power-of-two heights
  test_xe_prefetch_2d<float, 32, 16, 16>();
}

// Test 23: Various Width Configurations
TEST(CuTe_Xe, XE_PREFETCH_2D_VariousWidths) {
  // 8-bit with various widths
  test_xe_prefetch_2d<uint8_t, 8, 4, 16>();
  test_xe_prefetch_2d<uint8_t, 8, 4, 32>();
  
  // 16-bit with various widths
  test_xe_prefetch_2d<int16_t, 16, 4, 8>();
  test_xe_prefetch_2d<int16_t, 16, 4, 16>();
  
  // 32-bit with various widths
  test_xe_prefetch_2d<float, 32, 4, 4>();
  test_xe_prefetch_2d<float, 32, 4, 8>();
}

// Test 24: Square Tiles
TEST(CuTe_Xe, XE_PREFETCH_2D_SquareTiles) {
  // 8-bit square (in memory view)
  test_xe_prefetch_2d<uint8_t, 8, 8, 8>();
  
  // 16-bit square
  test_xe_prefetch_2d<int16_t, 16, 4, 4>();
  
  // 32-bit square
  test_xe_prefetch_2d<float, 32, 4, 4>();
}

// Test 25: Tall Tiles (Height > Width)
TEST(CuTe_Xe, XE_PREFETCH_2D_TallTiles) {
  test_xe_prefetch_2d<uint8_t, 8, 16, 8>();
  test_xe_prefetch_2d<int16_t, 16, 8, 4>();
  test_xe_prefetch_2d<float, 32, 8, 4>();
}

// Test 26: Cache Line Optimization
TEST(CuTe_Xe, XE_PREFETCH_2D_CacheOptimized) {
  // Configurations aligned to cache lines (64 bytes)
  test_xe_prefetch_2d<uint8_t, 8, 4, 64>();   // 64 bytes per row
  test_xe_prefetch_2d<int16_t, 16, 4, 32>();  // 64 bytes per row
  test_xe_prefetch_2d<float, 32, 4, 16>();    // 64 bytes per row
  test_xe_prefetch_2d<double, 64, 4, 8>();    // 64 bytes per row
}

#else

// For the fallback case
#include "cutlass_unit_test.h"

TEST(CuTe_Xe, XE_PREFETCH_2D_SKIPPED) {
  GTEST_SKIP() << "XE_PREFETCH_2D tests require IGC version 2.18 or higher. skipped";
}

#endif
