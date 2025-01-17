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

#include "../benchmark_runner.hpp"
#include "gemm_configuration.hpp"

using Scheduler = cutlass::gemm::device::Scheduler;

using MMAAtom = MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>;
using PvcGemmBF16BF16FP32_RRR_1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, Layout<Shape<_8,_4,_1>>>,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_2 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_128, _512, _32>,
        TiledMMA<MMAAtom, Layout<Shape<_4,_8,_1>>>,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_3 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
                float, Shape<_256, _128, _32>,
        TiledMMA<MMAAtom, Layout<Shape<_8,_4,_1>>>,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_4 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_128, _256, _16>,
        TiledMMA<MMAAtom, Layout<Shape<_4,_8,_1>>>,
        XE_2D_U16x32x16_LD_N, XE_2D_U16x16x32_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_5 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _32>,
        TiledMMA<MMAAtom, Layout<Shape<_1,_4,_1>>>,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x32x32_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_6 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, Layout<Shape<_8,_4,_1>>>,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_CRR_7 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, Layout<Shape<_8,_4,_1>>>,
        XE_2D_U16x16x16_LD_T, XE_2D_U16x32x32_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_CCR_8 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, Layout<Shape<_8,_4,_1>>>,
        XE_2D_U16x16x16_LD_T, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_1);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_2);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_3);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_4);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_5);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_6);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_CRR_7);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_CCR_8);

using PvcGemmBF16BF16FP32_StreamK_RRR_1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, Layout<Shape<_8,_4,_1>>>,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V,
        Scheduler::GemmStreamK>;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_StreamK_RRR_1);

using PvcGemmBF16BF16FP32_SplitK_RRR_1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, Layout<Shape<_8,_4,_1>>>,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V,
        Scheduler::GemmSplitK>;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RRR_1);

static void register_benchmarks() {
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_1);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_2);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_3);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_4);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_5);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_6);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_CRR_7);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_CCR_8);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_StreamK_RRR_1);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RRR_1);
}
