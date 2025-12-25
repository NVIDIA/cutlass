/***************************************************************************************************
* Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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

#pragma once

#include "gemm_configuration_cuda.hpp"

using AmpereGemmBF16BF16FP32_CCC = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::Sm80,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor, 8,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor, 8,
        float, cutlass::layout::ColumnMajor,
        float>;

using AmpereGemmBF16BF16FP32_CCC_kAlignmentA4 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::Sm80,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor, 4,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor, 8,
        float, cutlass::layout::ColumnMajor,
        float>;

using AmpereGemmBF16BF16FP32_CCC_kAlignmentA1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::Sm80,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor, 1,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor, 8,
        float, cutlass::layout::ColumnMajor,
        float>;

using AmpereGemmBF16BF16FP32_CCC_kAlignment1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::Sm80,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor, 1,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor, 1,
        float, cutlass::layout::ColumnMajor,
        float>;

using AmpereGemmFP16FP16FP32_CCC = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::Sm80,
        cutlass::half_t, cutlass::layout::ColumnMajor, 8,
        cutlass::half_t, cutlass::layout::ColumnMajor, 8,
        float, cutlass::layout::ColumnMajor,
        float>;

using AmpereGemmFP16FP16FP32_CCC_kAlignmentA4 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::Sm80,
        cutlass::half_t, cutlass::layout::ColumnMajor, 4,
        cutlass::half_t, cutlass::layout::ColumnMajor, 8,
        float, cutlass::layout::ColumnMajor,
        float>;

using AmpereGemmFP16FP16FP32_CCC_kAlignmentA1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::Sm80,
        cutlass::half_t, cutlass::layout::ColumnMajor, 1,
        cutlass::half_t, cutlass::layout::ColumnMajor, 8,
        float, cutlass::layout::ColumnMajor,
        float>;

using AmpereGemmFP16FP16FP32_CCC_kAlignment1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::Sm80,
        cutlass::half_t, cutlass::layout::ColumnMajor, 1,
        cutlass::half_t, cutlass::layout::ColumnMajor, 1,
        float, cutlass::layout::ColumnMajor,
        float>;

using AmpereGemmTF32TF32FP32_CCC = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::Sm80,
        float, cutlass::layout::ColumnMajor, 4,
        float, cutlass::layout::ColumnMajor, 4,
        float, cutlass::layout::ColumnMajor,
        float>;

using AmpereGemmTF32TF32FP32_CCC_kAlignmentA1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::Sm80,
        float, cutlass::layout::ColumnMajor, 1,
        float, cutlass::layout::ColumnMajor, 4,
        float, cutlass::layout::ColumnMajor,
        float>;

using AmpereGemmTF32TF32FP32_CCC_kAlignment1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::Sm80,
        float, cutlass::layout::ColumnMajor, 1,
        float, cutlass::layout::ColumnMajor, 1,
        float, cutlass::layout::ColumnMajor,
        float>;

CUTLASS_CREATE_GEMM_BENCHMARK(AmpereGemmBF16BF16FP32_CCC);
CUTLASS_CREATE_GEMM_BENCHMARK(AmpereGemmBF16BF16FP32_CCC_kAlignment1);
CUTLASS_CREATE_GEMM_BENCHMARK(AmpereGemmBF16BF16FP32_CCC_kAlignmentA1);
CUTLASS_CREATE_GEMM_BENCHMARK(AmpereGemmBF16BF16FP32_CCC_kAlignmentA4);

CUTLASS_CREATE_GEMM_BENCHMARK(AmpereGemmFP16FP16FP32_CCC);
CUTLASS_CREATE_GEMM_BENCHMARK(AmpereGemmFP16FP16FP32_CCC_kAlignment1);
CUTLASS_CREATE_GEMM_BENCHMARK(AmpereGemmFP16FP16FP32_CCC_kAlignmentA1);
CUTLASS_CREATE_GEMM_BENCHMARK(AmpereGemmFP16FP16FP32_CCC_kAlignmentA4);

CUTLASS_CREATE_GEMM_BENCHMARK(AmpereGemmTF32TF32FP32_CCC);
CUTLASS_CREATE_GEMM_BENCHMARK(AmpereGemmTF32TF32FP32_CCC_kAlignment1);
CUTLASS_CREATE_GEMM_BENCHMARK(AmpereGemmTF32TF32FP32_CCC_kAlignmentA1);

static void register_gemm_benchmarks() {
  CUTLASS_BENCHMARK(AmpereGemmBF16BF16FP32_CCC);
  CUTLASS_BENCHMARK(AmpereGemmBF16BF16FP32_CCC_kAlignment1);
  CUTLASS_BENCHMARK(AmpereGemmBF16BF16FP32_CCC_kAlignmentA1);
  CUTLASS_BENCHMARK(AmpereGemmBF16BF16FP32_CCC_kAlignmentA4);

  CUTLASS_BENCHMARK(AmpereGemmFP16FP16FP32_CCC);
  CUTLASS_BENCHMARK(AmpereGemmFP16FP16FP32_CCC_kAlignment1);
  CUTLASS_BENCHMARK(AmpereGemmFP16FP16FP32_CCC_kAlignmentA1);
  CUTLASS_BENCHMARK(AmpereGemmFP16FP16FP32_CCC_kAlignmentA4);

  CUTLASS_BENCHMARK(AmpereGemmTF32TF32FP32_CCC);
  CUTLASS_BENCHMARK(AmpereGemmTF32TF32FP32_CCC_kAlignment1);
  CUTLASS_BENCHMARK(AmpereGemmTF32TF32FP32_CCC_kAlignmentA1);
}
