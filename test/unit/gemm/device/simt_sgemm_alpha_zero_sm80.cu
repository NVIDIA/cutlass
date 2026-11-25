/***************************************************************************************************
 * Copyright (c) 2017 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
/*! \file
    \brief Regression tests for a zero-alpha SIMT GEMM epilogue.
*/

#include <limits>

#include "../../common/cutlass_unit_test.h"

#include "cutlass/cutlass.h"
#include "cutlass/gemm/device/gemm.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/reference/host/tensor_fill.h"

#if defined(CUTLASS_ARCH_MMA_SM80_SUPPORTED)

TEST(SM80_Device_Gemm_f32_simt, alpha_zero_does_not_propagate_nan) {
  using Element = float;
  using Layout = cutlass::layout::RowMajor;
  using Gemm = cutlass::gemm::device::Gemm<
    Element,
    Layout,
    Element,
    Layout,
    Element,
    Layout,
    Element,
    cutlass::arch::OpClassSimt,
    cutlass::arch::Sm80>;

  cutlass::gemm::GemmCoord const problem_size(8, 8, 8);
  Element const quiet_nan = std::numeric_limits<Element>::quiet_NaN();

  cutlass::HostTensor<Element, Layout> tensor_A(problem_size.mk());
  cutlass::HostTensor<Element, Layout> tensor_B(problem_size.kn());
  cutlass::HostTensor<Element, Layout> tensor_C(problem_size.mn());
  cutlass::HostTensor<Element, Layout> tensor_D(problem_size.mn());

  cutlass::reference::host::TensorFill(tensor_A.host_view(), quiet_nan);
  cutlass::reference::host::TensorFill(tensor_B.host_view(), quiet_nan);
  tensor_A.sync_device();
  tensor_B.sync_device();

  for (Element beta : {Element(1), Element(0)}) {
    Element const source_value = beta == Element(0) ? quiet_nan : Element(3);
    cutlass::reference::host::TensorFill(tensor_C.host_view(), source_value);
    tensor_C.sync_device();

    typename Gemm::Arguments arguments{
      problem_size,
      tensor_A.device_ref(),
      tensor_B.device_ref(),
      tensor_C.device_ref(),
      tensor_D.device_ref(),
      {Element(0), beta}};

    Gemm gemm_op;
    ASSERT_EQ(gemm_op.can_implement(arguments), cutlass::Status::kSuccess);
    ASSERT_EQ(gemm_op(arguments), cutlass::Status::kSuccess);
    ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);

    tensor_D.sync_host();
    Element const expected = beta == Element(0) ? Element(0) : source_value;

    for (size_t i = 0; i < tensor_D.capacity(); ++i) {
      EXPECT_EQ(tensor_D.host_data()[i], expected) << "beta = " << beta << ", index = " << i;
    }
  }
}

#endif  // CUTLASS_ARCH_MMA_SM80_SUPPORTED
