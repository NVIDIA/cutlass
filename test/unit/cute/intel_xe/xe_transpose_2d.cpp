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

#include <cute/tensor.hpp>
#include <cute/atom/copy_atom.hpp>
#include <cute/atom/copy_traits_xe_2d.hpp>
#include <cute/arch/copy_xe_2d.hpp>
#include <sycl/sycl.hpp>
#include "cutlass_unit_test.h"

using namespace cute;

#if (IGC_VERSION_MAJOR > 2) || (IGC_VERSION_MAJOR == 2 && IGC_VERSION_MINOR >= 18) 

TEST(CuTe_Xe, XE_LOAD_2D_TRANSPOSE_API_Declaration) {
  // Template: XE_LOAD_2D_TRANSPOSE<Bits, Height, Width>
  // Constraints: Bits == 32 || Bits == 64, Width <= 8
  // For 64-bit: Height == 8 && Width < 4
  
  // Test 32-bit transpose operations
  using TransposeOp_32bit_2x4 = XE_LOAD_2D_TRANSPOSE<32, 2, 4>;
  using TransposeOp_32bit_4x8 = XE_LOAD_2D_TRANSPOSE<32, 4, 8>;
  using TransposeOp_32bit_8x2 = XE_LOAD_2D_TRANSPOSE<32, 8, 2>;
  
  // Test 64-bit transpose operations (limited constraints)
  using TransposeOp_64bit_8x2 = XE_LOAD_2D_TRANSPOSE<64, 8, 2>;
  using TransposeOp_64bit_8x3 = XE_LOAD_2D_TRANSPOSE<64, 8, 3>;
  
  // Test that the operations have the required static members from XE_Copy_Op_2D_Base
  static_assert(TransposeOp_32bit_2x4::AtomHeight == 2);
  static_assert(TransposeOp_32bit_2x4::AtomWidth == 4);
  static_assert(TransposeOp_32bit_2x4::CopyBits == 32);
  
  static_assert(TransposeOp_32bit_4x8::AtomHeight == 4);
  static_assert(TransposeOp_32bit_4x8::AtomWidth == 8);
  static_assert(TransposeOp_32bit_4x8::CopyBits == 32);
  
  static_assert(TransposeOp_64bit_8x2::AtomHeight == 8);
  static_assert(TransposeOp_64bit_8x2::AtomWidth == 2);
  static_assert(TransposeOp_64bit_8x2::CopyBits == 64);
  
  EXPECT_TRUE(true) << "XE_LOAD_2D_TRANSPOSE API types declared successfully";
}

TEST(CuTe_Xe, XE_LOAD_2D_TRANSPOSE_Constraints) {
  // Test that the compile-time constraints are enforced
  
  // Valid 32-bit operations
  using Valid32_1 = XE_LOAD_2D_TRANSPOSE<32, 1, 1>;
  using Valid32_2 = XE_LOAD_2D_TRANSPOSE<32, 16, 8>; // Width <= 8
  
  // Valid 64-bit operations (Height == 8 && Width < 4)
  using Valid64_1 = XE_LOAD_2D_TRANSPOSE<64, 8, 1>;
  using Valid64_2 = XE_LOAD_2D_TRANSPOSE<64, 8, 2>;
  using Valid64_3 = XE_LOAD_2D_TRANSPOSE<64, 8, 3>;
  
  static_assert(Valid32_1::CopyBits == 32);
  static_assert(Valid32_2::CopyBits == 32);
  static_assert(Valid64_1::CopyBits == 64);
  static_assert(Valid64_2::CopyBits == 64);
  static_assert(Valid64_3::CopyBits == 64);
  
  EXPECT_TRUE(true) << "XE_LOAD_2D_TRANSPOSE constraint validation successful";
}

#else

TEST(CuTe_Xe, XE_LOAD_2D_TRANSPOSE_SKIPPED) {
  GTEST_SKIP() << "XE_LOAD_2D_TRANSPOSE tests require IGC version 2.18 or higher. skipped";
}

#endif
