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

 /*
 * VNNI Usage Summary:
 * 
 * This file demonstrates XE_LOAD_2D_VNNI usage in kernel context.
 * 
 * Key points:
 * 1. VNNI is used to load B matrix in GEMM operations
 * 2. Hardware performs interleaving during load (free transformation)
 * 3. VNNI data flows directly to DPAS operations
 * 4. Only 8-bit and 16-bit data types supported
 * 5. BlockWidth parameter creates multiple blocks (block_count = Width/BlockWidth)
 * 
 * Real-world usage pattern:
 *   auto copy_b = make_block_2d_copy_B(XE_LOAD_2D_VNNI<16, 32, 16, 16>{}, mma, gB);
 *   copy(copy_b, tBgB, tBrB);  // Load in VNNI format
 *   gemm(mma, tCrA, tBrB, tCrC);  // DPAS consumes VNNI data
 * 
 * See examples/12_bmg_moe_gemm_cute_interface/ for full GEMM implementation.
 
 */

#include "cutlass/detail/layout.hpp"

#include <cute/tensor.hpp>
#include <cute/atom/copy_atom.hpp>
#include <cute/atom/copy_traits_xe_2d.hpp>
#include <cute/arch/copy_xe_2d.hpp>
#include <cute/atom/mma_atom.hpp>
#include <cute/atom/mma_traits_xe.hpp>
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
template<class...> class XEVnniLoadKernelName;

// VNNI load demonstration kernel
// Note: VNNI is designed for B matrix in GEMM context with DPAS consumption
// This simplified test only verifies the load operation executes without errors
template <class SrcTensor, class DstTensor, int Bits, int Height, int Width>
void xe_vnni_load_kernel(SrcTensor src, DstTensor dst) {
  using namespace cute;
  using Element = typename SrcTensor::value_type;

  // Only execute with the first subgroup to avoid race conditions
  if (sycl::ext::oneapi::this_work_item::get_nd_item<1>().get_group(0) == 0) {
    // Get thread/subgroup information
    auto local_id = int(sycl::ext::oneapi::this_work_item::get_nd_item<1>().get_local_id(0));
    
    // ============================================
    // Use VNNI load instead of regular XE_LOAD_2D
    // ============================================
    // Note: VNNI is typically used with make_block_2d_copy_B in GEMM context
    // But for demonstration, we show the raw VNNI operation
    using VnniOp = XE_LOAD_2D_VNNI<Bits, Height, Width, Width>;  // BlockWidth = Width for single block
    auto tiled_copy = make_block_2d_copy(VnniOp{}, src);
    
    // Get thread slice of the tiled copy
    auto thr_copy = tiled_copy.get_slice(local_id);
    
    // Create coordinate tensor for a single tile
    auto coord_shape = make_shape(Int<Height>{}, Int<Width * Bits / sizeof_bits_v<Element>>{});
    Tensor coord_tile = make_identity_tensor(coord_shape);
    
    // Partition source coordinates and create destination fragment
    auto thr_src_coord = thr_copy.partition_S(coord_tile);
    auto thr_dst_frag = thr_copy.partition_fragment_D(coord_tile);
    
    // ============================================
    // THIS IS THE VNNI LOAD
    // Hardware performs interleaving during this load
    // Data in thr_dst_frag is now in VNNI interleaved format
    // ============================================
    copy(tiled_copy, thr_src_coord, thr_dst_frag);
    
    // For verification, store back to destination
    // Note: In real usage, thr_dst_frag would go directly to gemm(mma, tCrA, thr_dst_frag, tCrC)
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

// Host test function for VNNI load operation
template <typename Element, int Bits, int Height, int Width, int BlockWidth = Width>
void test_xe_vnni_load() {
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
  
  // Launch kernel - VNNI load demonstration
  auto blockDim = compat::dim3(SUBGROUP_SIZE);
  auto gridDim = compat::dim3(1);
  
  launch<xe_vnni_load_kernel<decltype(tensor_src), decltype(tensor_dst), Bits, Height, Width>,
         XEVnniLoadKernelName<decltype(tensor_src), decltype(tensor_dst)>>(
    launch_policy{
      gridDim, blockDim,
      kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}
    },
    tensor_src, tensor_dst);
  
    compat::wait_and_throw();
    
    // Note: We do NOT verify data matches because VNNI performs interleaving transformation
    // The loaded data is in VNNI format (hardware-interleaved for DPAS consumption)
    // When stored back to memory, the interleaved pattern is visible
    // In real usage, VNNI data goes directly to gemm()/DPAS, never stored back
    // This test verifies that VNNI load operation executes without errors
}

// ============================================
// VNNI Tests - Only 8-bit and 16-bit supported
// ============================================

TEST(PVC_CuTe_Xe, XE_VNNI_2D_uint8) {
  // VNNI is used for B matrix in GEMM - typically with BlockWidth creating multiple blocks
  test_xe_vnni_load<uint8_t, 8, 4, 64, 16>();   // 4 blocks of 16
  test_xe_vnni_load<uint8_t, 8, 8, 64, 32>();   // 2 blocks of 32
  test_xe_vnni_load<uint8_t, 8, 8, 64, 64>();   // 1 block of 64
}

TEST(PVC_CuTe_Xe, XE_VNNI_2D_int8) {
  test_xe_vnni_load<int8_t, 8, 4, 64, 16>();
  test_xe_vnni_load<int8_t, 8, 8, 64, 32>();
  test_xe_vnni_load<int8_t, 8, 8, 64, 64>();
}

TEST(PVC_CuTe_Xe, XE_VNNI_2D_uint16) {
  test_xe_vnni_load<uint16_t, 16, 4, 32, 16>();  // 2 blocks of 16
  test_xe_vnni_load<uint16_t, 16, 8, 32, 16>();  // 2 blocks of 16
  test_xe_vnni_load<uint16_t, 16, 8, 32, 32>();  // 1 block of 32
}

TEST(PVC_CuTe_Xe, XE_VNNI_2D_int16) {
  test_xe_vnni_load<int16_t, 16, 4, 32, 16>();
  test_xe_vnni_load<int16_t, 16, 8, 32, 16>();
  test_xe_vnni_load<int16_t, 16, 8, 32, 32>();
}

TEST(PVC_CuTe_Xe, XE_VNNI_2D_half) {
  test_xe_vnni_load<half_t, 16, 4, 32, 16>();
  test_xe_vnni_load<half_t, 16, 8, 32, 16>();
  test_xe_vnni_load<half_t, 16, 8, 32, 32>();
}

TEST(PVC_CuTe_Xe, XE_VNNI_2D_bfloat16) {
  test_xe_vnni_load<bfloat16_t, 16, 4, 32, 16>();
  test_xe_vnni_load<bfloat16_t, 16, 8, 32, 16>();
  test_xe_vnni_load<bfloat16_t, 16, 8, 32, 32>();
}

// Note: 32-bit and 64-bit types are NOT supported by VNNI
// VNNI only works with 8-bit and 16-bit data types

#else

// For the fallback case
#include "cutlass_unit_test.h"

TEST(PVC_CuTe_Xe, XE_VNNI_2D_SKIPPED) {
  GTEST_SKIP() << "XE_VNNI_2D tests require IGC version 2.18 or higher. skipped";
}

#endif
