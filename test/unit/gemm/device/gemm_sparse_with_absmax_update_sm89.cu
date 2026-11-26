/***************************************************************************************************
 * Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "../../common/cutlass_unit_test.h"
#include "testbed_sparse_absmax_update.h"

#if defined(CUTLASS_ARCH_SPARSE_MMA_F32_SM89_SUPPORTED)
namespace {
using namespace test::gemm::device::sparse_absmax_update;

void test_update(char const* name) {
  int device = 0;
  ASSERT_EQ(cudaGetDevice(&device), cudaSuccess);
  cudaDeviceProp properties{};
  ASSERT_EQ(cudaGetDeviceProperties(&properties, device), cudaSuccess);
  if (properties.major != 8 || properties.minor != 9) {
    GTEST_SKIP() << "Requires Ada SM89";
  }
  if (sizeof(Gemm::GemmKernel::SharedStorage) > properties.sharedMemPerBlockOptin) {
    GTEST_SKIP() << "Insufficient per-block shared memory";
  }
  try {
    Inputs inputs;
    for (auto const& test : kCases) {
      if (std::string(name) == test.name) {
        EXPECT_TRUE(run_case(inputs, test));
        return;
      }
    }
    FAIL() << "Unknown update case: " << name;
  } catch (std::exception const& error) {
    FAIL() << error.what();
  }
}
}  // namespace

CUTLASS_TEST_L0(SM89_Device_SparseGemmWithAbsmax, unchanged_control, {
  test_update("unchanged_control");
})

CUTLASS_TEST_L0(SM89_Device_SparseGemmWithAbsmax, aux_pointer, {
  test_update("aux_pointer");
})

CUTLASS_TEST_L0(SM89_Device_SparseGemmWithAbsmax, bias_pointer, {
  test_update("bias_pointer");
})

CUTLASS_TEST_L0(SM89_Device_SparseGemmWithAbsmax, bias_stride, {
  test_update("bias_stride");
})

CUTLASS_TEST_L0(SM89_Device_SparseGemmWithAbsmax, combined, {
  test_update("combined");
})

CUTLASS_TEST_L0(SM89_Device_SparseGemmWithAbsmax, enable_aux, {
  test_update("enable_aux");
})

CUTLASS_TEST_L0(SM89_Device_SparseGemmWithAbsmax, disable_aux, {
  test_update("disable_aux");
})

CUTLASS_TEST_L0(SM89_Device_SparseGemmWithAbsmax, enable_bias, {
  test_update("enable_bias");
})

CUTLASS_TEST_L0(SM89_Device_SparseGemmWithAbsmax, disable_bias, {
  test_update("disable_bias");
})

#endif
