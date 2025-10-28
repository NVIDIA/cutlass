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
 **************************************************************************************************/

#include <cute/tensor.hpp>
#include <cute/atom/copy_atom.hpp>
#include <cute/atom/copy_traits_xe_2d.hpp>
#include <cute/arch/copy_xe_2d.hpp>
#include <sycl/sycl.hpp>
#include "cutlass_unit_test.h"

using namespace cute;

#if (IGC_VERSION_MAJOR > 2) || (IGC_VERSION_MAJOR == 2 && IGC_VERSION_MINOR >= 18) 

TEST(PVC_CuTe_Xe, XE_LOAD_2D_VNNI_API_Declaration) {
  // Template: XE_LOAD_2D_VNNI<Bits, Height, Width, BlockWidth = Width>
  
  // Test that the VNNI operation types can be declared
  using VNNIOp_8bit_2x32 = XE_LOAD_2D_VNNI<8, 2, 32>;
  using VNNIOp_8bit_4x32 = XE_LOAD_2D_VNNI<8, 4, 32>;
  using VNNIOp_16bit_2x16 = XE_LOAD_2D_VNNI<16, 2, 16>;
  using VNNIOp_16bit_4x16 = XE_LOAD_2D_VNNI<16, 4, 16>;
  
  // Test that the operations have the required static members from XE_Copy_Op_2D_Base
  static_assert(VNNIOp_8bit_2x32::AtomHeight == 2);
  static_assert(VNNIOp_8bit_2x32::AtomWidth == 32);
  static_assert(VNNIOp_8bit_2x32::CopyBits == 8);
  
  static_assert(VNNIOp_16bit_2x16::AtomHeight == 2);
  static_assert(VNNIOp_16bit_2x16::AtomWidth == 16);
  static_assert(VNNIOp_16bit_2x16::CopyBits == 16);
  
  EXPECT_TRUE(true) << "XE_LOAD_2D_VNNI API types declared successfully";
}

#else

TEST(PVC_CuTe_Xe, XE_LOAD_2D_VNNI_SKIPPED) {
  GTEST_SKIP() << "XE_LOAD_2D_VNNI tests require IGC version 2.18 or higher. skipped";
}

#endif