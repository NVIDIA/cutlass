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

#include "cutlass_unit_test.h"

#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/gemm/device/ell_gemm.h"

namespace {

using Element = cutlass::half_t;
using ThreadblockShape = cutlass::gemm::GemmShape<128, 128, 32>;
using ThreadblockSwizzle =
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<8>;
using EllGemm = cutlass::gemm::device::EllGemm<
    Element, cutlass::layout::RowMajor, Element,
    cutlass::layout::ColumnMajor, Element, cutlass::layout::ColumnMajor,
    float, cutlass::arch::OpClassTensorOp, cutlass::arch::Sm80,
    ThreadblockShape, cutlass::gemm::GemmShape<64, 64, 32>,
    cutlass::gemm::GemmShape<16, 8, 16>,
    cutlass::epilogue::thread::LinearCombination<Element, 8, float, float>,
    ThreadblockSwizzle, 4, 8, 8, true>;

typename EllGemm::Arguments make_arguments(int m, int n) {
  return {{m, n, 128}, {nullptr, 128}, {nullptr, 128}, {nullptr, m},
          {nullptr, m}, nullptr, 128, 32, 0, {}, 4};
}

size_t expected_workspace(typename EllGemm::Arguments const& args) {
  ThreadblockSwizzle swizzle;
  auto tiled_shape = swizzle.get_tiled_shape(
      {args.problem_size.n(), args.problem_size.m(), args.problem_size.k()},
      {ThreadblockShape::kM, args.ell_blocksize, ThreadblockShape::kK},
      args.split_k_slices);
  tiled_shape.n() *=
      (args.ell_blocksize + ThreadblockShape::kN - 1) / ThreadblockShape::kN;
  return sizeof(int) * size_t(tiled_shape.m()) * size_t(tiled_shape.n());
}

} // namespace

TEST(SM80_Device_EllGemm, column_major_workspace_uses_transposed_problem) {
  auto tall = make_arguments(264, 136);
  auto wide = make_arguments(136, 264);

  EXPECT_EQ(EllGemm::get_workspace_size(tall), expected_workspace(tall));
  EXPECT_EQ(EllGemm::get_workspace_size(wide), expected_workspace(wide));
  EXPECT_EQ(EllGemm::get_workspace_size(tall), 72u);
  EXPECT_EQ(EllGemm::get_workspace_size(wide), 60u);
}
