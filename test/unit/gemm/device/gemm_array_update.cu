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

#include <vector>

#include "cutlass/gemm/device/gemm_array.h"

#include "../../common/cutlass_unit_test.h"

#include "cutlass/util/device_memory.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/reference/host/gemm.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_fill.h"

namespace {

template <typename LayoutC>
using GemmArray = cutlass::gemm::device::GemmArray<
    float, cutlass::layout::ColumnMajor,
    float, cutlass::layout::ColumnMajor,
    float, LayoutC,
    float, cutlass::arch::OpClassSimt, cutlass::arch::Sm50,
    cutlass::gemm::GemmShape<32, 64, 8>,
    cutlass::gemm::GemmShape<32, 64, 8>>;

template <typename LayoutC>
struct GemmArrayProblem {
  using Gemm = GemmArray<LayoutC>;
  using TensorAB = cutlass::HostTensor<float, cutlass::layout::ColumnMajor>;
  using TensorCD = cutlass::HostTensor<float, LayoutC>;

  cutlass::gemm::GemmCoord problem_size;
  int batch_count;
  float alpha;
  float beta;
  std::vector<TensorAB> tensor_A, tensor_B;
  std::vector<TensorCD> tensor_C, tensor_D, reference_D;
  cutlass::device_memory::allocation<float const *> ptr_A, ptr_B, ptr_C;
  cutlass::device_memory::allocation<float *> ptr_D;

  GemmArrayProblem(cutlass::gemm::GemmCoord size, int batches, float a, float b, int seed):
      problem_size(size), batch_count(batches), alpha(a), beta(b),
      tensor_A(batches), tensor_B(batches), tensor_C(batches), tensor_D(batches),
      reference_D(batches), ptr_A(batches), ptr_B(batches), ptr_C(batches), ptr_D(batches) {
    std::vector<float const *> host_A(batches), host_B(batches), host_C(batches);
    std::vector<float *> host_D(batches);
    for (int batch = 0; batch < batches; ++batch) {
      tensor_A[batch].reset(size.mk());
      tensor_B[batch].reset(size.kn());
      tensor_C[batch].reset(size.mn());
      tensor_D[batch].reset(size.mn());
      reference_D[batch].reset(size.mn(), false);

      // Small integer inputs and coefficients make the FP32 reference exact.
      cutlass::reference::host::TensorFillRandomUniform(
          tensor_A[batch].host_view(), seed + 3 * batch, 2, -2, 0);
      cutlass::reference::host::TensorFillRandomUniform(
          tensor_B[batch].host_view(), seed + 3 * batch + 1, 2, -2, 0);
      cutlass::reference::host::TensorFillRandomUniform(
          tensor_C[batch].host_view(), seed + 3 * batch + 2, 2, -2, 0);
      // A stale grid must not pass by leaving unlaunched tiles at their initial value.
      cutlass::reference::host::TensorFill(tensor_D[batch].host_view(), -10000.0f);

      tensor_A[batch].sync_device();
      tensor_B[batch].sync_device();
      tensor_C[batch].sync_device();
      tensor_D[batch].sync_device();
      host_A[batch] = tensor_A[batch].device_data();
      host_B[batch] = tensor_B[batch].device_data();
      host_C[batch] = tensor_C[batch].device_data();
      host_D[batch] = tensor_D[batch].device_data();
    }
    ptr_A.copy_from_host(host_A.data());
    ptr_B.copy_from_host(host_B.data());
    ptr_C.copy_from_host(host_C.data());
    ptr_D.copy_from_host(host_D.data());
  }

  typename Gemm::Arguments arguments() const {
    return {problem_size,
            ptr_A.get(), tensor_A[0].layout(),
            ptr_B.get(), tensor_B[0].layout(),
            ptr_C.get(), tensor_C[0].layout(),
            ptr_D.get(), tensor_D[0].layout(),
            {alpha, beta}, batch_count};
  }

  void verify() {
    cutlass::reference::host::Gemm<
        float, cutlass::layout::ColumnMajor,
        float, cutlass::layout::ColumnMajor,
        float, LayoutC, float, float> reference_gemm;
    for (int batch = 0; batch < batch_count; ++batch) {
      reference_gemm(problem_size, alpha, tensor_A[batch].host_ref(),
                     tensor_B[batch].host_ref(), beta, tensor_C[batch].host_ref(),
                     reference_D[batch].host_ref());
      tensor_D[batch].sync_host();
      EXPECT_TRUE(cutlass::reference::host::TensorEquals(
          reference_D[batch].host_view(), tensor_D[batch].host_view())) << "batch " << batch;
    }
  }
};

template <typename LayoutC>
void test_gemm_array_update() {
  // Keep both allocations alive so update() must replace all four pointer arrays.
  GemmArrayProblem<LayoutC> initial({13, 29, 9}, 1, 1.0f, 0.0f, 2026);
  GemmArrayProblem<LayoutC> updated({37, 73, 19}, 3, 2.0f, -1.0f, 2036);
  GemmArray<LayoutC> gemm;

  ASSERT_EQ(gemm.can_implement(initial.arguments()), cutlass::Status::kSuccess);
  ASSERT_EQ(gemm.initialize(initial.arguments()), cutlass::Status::kSuccess);
  ASSERT_EQ(gemm.run(), cutlass::Status::kSuccess);
  ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);
  initial.verify();

  // Grow from one tile and one batch to multiple tiles in M/N and three batches,
  // also changing K, leading dimensions, input/output pointers, alpha, and beta.
  ASSERT_EQ(gemm.can_implement(updated.arguments()), cutlass::Status::kSuccess);
  ASSERT_EQ(gemm.update(updated.arguments()), cutlass::Status::kSuccess);
  ASSERT_EQ(gemm.run(), cutlass::Status::kSuccess);
  ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);
  updated.verify();
}

} // namespace

CUTLASS_TEST_L0(SM50_Device_GemmArray, update_row_major, {
  test_gemm_array_update<cutlass::layout::RowMajor>();
})

CUTLASS_TEST_L0(SM50_Device_GemmArray, update_column_major, {
  // Column-major output forwards update() to the transposed row-major operator.
  test_gemm_array_update<cutlass::layout::ColumnMajor>();
})
