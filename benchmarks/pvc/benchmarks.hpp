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
#include "flash_attention_v2/benchmarks.hpp"

using Scheduler = cutlass::gemm::device::Scheduler;

using MMAAtom = MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>;
using PvcGemmBF16BF16FP32_RRR_1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_2 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_128, _512, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_4,_8,_1>, Stride<_8,_1,_0>>, 
                 Tile<Layout<Shape<_8, _4, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _8, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_3 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
                float, Shape<_256, _128, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _2>, Stride<_1, _32, _16>>, 
                      _32>>,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_4 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_128, _256, _16>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_4,_8,_1>, Stride<_8,_1,_0>>, 
                 Tile<Layout<Shape<_8, _4, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _8, _1>, Stride<_1, _16, _0>>, 
                      _16>>,
        XE_2D_U16x32x16_LD_N, XE_2D_U16x16x16_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_5 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_1,_4,_1>, Stride<_0,_1,_0>>, 
                 Tile<Layout<Shape<_8, _1, _1>, Stride<_1, _0, _0>>,
                      Layout<Shape<_16, _4, _2>, Stride<_1, _32, _16>>, 
                      _32>>,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x32x32_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_6 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_6 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_7 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_8, _128, _32>>,
                                      Layout<Shape<_1, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_V,
        Scheduler::Gemm>;


using PvcGemmBF16BF16FP32_RRR_8 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _32>>,
                                      Layout<Shape<_2, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_9 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_8, _64, _32>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_10 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _256, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _256, _32>>,
                                      Layout<Shape<_2,_16, _1>, Stride<_16, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x32x16_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_11 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _32>>,
                                      Layout<Shape<_4, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RRR_12 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _512, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _512, _32>>,
                                      Layout<Shape<_1, _32, _1>, Stride<_32, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x16x16_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_5 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _32>,
        typename TiledMMAHelper<MMAAtom, Layout<Shape<_8, _128, _32>>,
        Layout<Shape<_1, _4, _1>, Stride<_0, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_6 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_7 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_8, _128, _32>>,
                                      Layout<Shape<_1, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;


using PvcGemmBF16BF16FP32_RCR_8 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _32>>,
                                      Layout<Shape<_2, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;
        
using PvcGemmBF16BF16FP32_RCR_9 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_8, _64, _32>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;
        
using PvcGemmBF16BF16FP32_RCR_10 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _256, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _256, _32>>,
                                      Layout<Shape<_2,_16, _1>, Stride<_16, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;
        
using PvcGemmBF16BF16FP32_RCR_11 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _32, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _32, _32>>,
                                      Layout<Shape<_4, _2, _1>, Stride<_2, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;
        
using PvcGemmBF16BF16FP32_RCR_12 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _32, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _32, _32>>,
                                      Layout<Shape<_8, _2, _1>, Stride<_2, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_13 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _64, _32>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_14 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _64, _32>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_15 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_16, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_16, _64, _32>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_16 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_16, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_16, _64, _32>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_17 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _16>,
        typename TiledMMAHelper<MMAAtom, Layout<Shape<_8, _128, _16>>,
        Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_18 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _16>,
        typename TiledMMAHelper<MMAAtom, Layout<Shape<_256, _256, _16>>,
        Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_19 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_8, _128, _16>>,
                                      Layout<Shape<_1, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;


using PvcGemmBF16BF16FP32_RCR_20 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _16>>,
                                      Layout<Shape<_2, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;
        
using PvcGemmBF16BF16FP32_RCR_21 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_8, _64, _16>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;
        
using PvcGemmBF16BF16FP32_RCR_22 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _256, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _256, _16>>,
                                      Layout<Shape<_2,_16, _1>, Stride<_16, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;
        
using PvcGemmBF16BF16FP32_RCR_23 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _32, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _32, _16>>,
                                      Layout<Shape<_4, _2, _1>, Stride<_2, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;
        
using PvcGemmBF16BF16FP32_RCR_24 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _32, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _32, _16>>,
                                      Layout<Shape<_8, _2, _1>, Stride<_2, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_25 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _64, _32>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_26 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _64, _16>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_27 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_16, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_16, _64, _16>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_28 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_16, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_16, _64, _16>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_29 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _64, _32>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_30 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _64, _32>>,
                                      Layout<Shape<_4, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_31 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _64, _32>>,
                                      Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_32 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_128, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_128, _64, _32>>,
                                      Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_33 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _64, _16>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_34 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _64, _16>>,
                                      Layout<Shape<_4, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_35 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _64, _16>>,
                                      Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_RCR_36 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_128, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_128, _64, _16>>,
                                      Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;


using PvcGemmBF16BF16FP32_RCR_37 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _64, _32>>,
                                      Layout<Shape<_4, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

// TODO(codeplay): Re-enable these once there is general support for epilogues
// using PvcGemmBF16BF16FP32_RCR_Linear = cutlass::gemm::device::GemmConfiguration<
//         cutlass::arch::IntelPVC,
//         cutlass::bfloat16_t, cutlass::layout::RowMajor,
//         cutlass::bfloat16_t, cute::Stride<int64_t, _1, _0>, // Stride for batch is _0 (re-use the same B matrix)
//         float, cutlass::layout::RowMajor,
//         float, Shape<_256, _256, _32>,
//         TiledMMA<MMAAtom, 
//                  Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
//                  Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
//                       Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
//                       _32>>,
//         XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
//         Scheduler::Gemm,
//         cutlass::epilogue::fusion::LinCombPerColBias<
//             float, float, float, float,
//             float, 128 / sizeof_bits_v<float>,
//             cutlass::FloatRoundStyle::round_to_nearest>
// >;

// TODO(codeplay): Does this batch GEMM config correspond to 'MoE group gemm with 256 experts'?
// using PvcGemmBF16BF16FP32_RCR_Linear_MoE = cutlass::gemm::device::GemmConfiguration<
//         cutlass::arch::IntelPVC,
//         cutlass::bfloat16_t, cute::Stride<int64_t, _1, _0>, // Stride for batch is _0 (re-use the same A matrix)
//         cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
//         float, cutlass::layout::RowMajor,
//         float, Shape<_256, _256, _32>,
//         TiledMMA<MMAAtom, 
//                  Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
//                  Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
//                       Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
//                       _32>>,
//         XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
//         Scheduler::Gemm,
//         cutlass::epilogue::fusion::LinCombPerColBias<
//             float, float, float, float,
//             float, 128 / sizeof_bits_v<float>,
//             cutlass::FloatRoundStyle::round_to_nearest>
// >;
//
using PvcGemmBF16BF16FP32_RCR_6_silu = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm,
        cutlass::epilogue::fusion::LinCombEltAct<
            cutlass::epilogue::thread::SiLu,
            float, float, float, float,
            cutlass::FloatRoundStyle::round_to_nearest>>;

using PvcGemmBF16BF16FP32_RCR_6_mul = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm,
        cutlass::epilogue::fusion::LinCombDeEltAct<
            cutlass::layout::RowMajor, std::multiplies, float, float>>;

using PvcGemmBF16BF16FP32_CRR_7 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x16x16_LD_T, XE_2D_U16x32x32_LD_V,
        Scheduler::Gemm>;

using PvcGemmBF16BF16FP32_CCR_8 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x16x16_LD_T, XE_2D_U16x16x16_LD_T,
        Scheduler::Gemm>;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_1);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_2);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_3);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_4);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_5);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_6);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_7);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_8);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_9);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_10);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_11);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_12);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_5);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_6);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_7);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_8);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_9);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_10);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_11);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_12);
// CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_Linear);
// CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_Linear_MoE);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_6_silu);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_6_mul);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_13);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_14);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_15);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_16);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_17);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_18);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_19);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_20);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_21);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_22);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_23);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_24);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_25);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_26);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_27);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_28);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_29);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_30);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_31);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_32);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_33);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_34);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_35);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_36);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_37);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_CRR_7);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_CCR_8);

using PvcGemmBF16BF16FP32_StreamK_RCR_1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_StreamK_RCR_2 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _32>,
        typename TiledMMAHelper<MMAAtom, Layout<Shape<_8, _128, _32>>,
        Layout<Shape<_1, _4, _1>, Stride<_0, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_StreamK_RRR_1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V,
        Scheduler::GemmSplitK>;
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_StreamK_RRR_1);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_StreamK_RCR_1);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_StreamK_RCR_2);


using PvcGemmBF16BF16FP32_SplitK_RCR_1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_2 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _32>,
        typename TiledMMAHelper<MMAAtom, Layout<Shape<_8, _128, _32>>,
        Layout<Shape<_1, _4, _1>, Stride<_0, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_3 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _32>>,
                                      Layout<Shape<_2, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_4 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_16, _128, _32>,
        typename TiledMMAHelper<MMAAtom, Layout<Shape<_16, _128, _32>>,
        Layout<Shape<_1, _8, _1>, Stride<_0, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;


using PvcGemmBF16BF16FP32_SplitK_RCR_5 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_8, _64, _32>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_6 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _32>>,
                                      Layout<Shape<_1, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_7 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _32>>,
                                      Layout<Shape<_4, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_8 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _16>>,
                                      Layout<Shape<_4, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_9 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _16>>,
                                      Layout<Shape<_2, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_10 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _16>>,
                                      Layout<Shape<_1, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_11 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_8, _128, _32>>,
                                      Layout<Shape<_1, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_12 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _128, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _128, _32>>,
                                      Layout<Shape<_2, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_13 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _64, _32>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_14 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _64, _32>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_15 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_16, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_16, _64, _32>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_16 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_16, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_16, _64, _32>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_17 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _16>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _16>>,
        XE_2D_U16x32x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_18 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _16>,
        typename TiledMMAHelper<MMAAtom, Layout<Shape<_8, _128, _16>>,
        Layout<Shape<_1, _4, _1>, Stride<_0, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_19 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _16>>,
                                      Layout<Shape<_2, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_20 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_16, _128, _16>,
        typename TiledMMAHelper<MMAAtom, Layout<Shape<_16, _128, _16>>,
        Layout<Shape<_1, _8, _1>, Stride<_0, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;


using PvcGemmBF16BF16FP32_SplitK_RCR_21 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_8, _64, _16>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_22 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _16>>,
                                      Layout<Shape<_1, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_23 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _128, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _128, _16>>,
                                      Layout<Shape<_4, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;


using PvcGemmBF16BF16FP32_SplitK_RCR_24 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_8, _128, _16>>,
                                      Layout<Shape<_1, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_25 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _128, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _128, _16>>,
                                      Layout<Shape<_2, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_26 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _64, _16>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_27 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _64, _16>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_28 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_16, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_16, _64, _16>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_29 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_16, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_16, _64, _16>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_30 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _64, _32>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_31 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _64, _32>>,
                                      Layout<Shape<_4, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_32 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _64, _32>>,
                                      Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;
 
using PvcGemmBF16BF16FP32_SplitK_RCR_33 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _64, _16>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x32x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_34 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _64, _16>>,
                                      Layout<Shape<_4, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_35 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _64, _16>>,
                                      Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;
        
using PvcGemmBF16BF16FP32_SplitK_RCR_36 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_128, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_128, _64, _32>>,
                                      Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_37 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_128, _64, _16>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_128, _64, _16>>,
                                      Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x16_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_38 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _64, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _64, _32>>,
                                      Layout<Shape<_4, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_39 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_32, _32, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_32, _32, _32>>,
                                      Layout<Shape<_4, _2, _1>, Stride<_2, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_40 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _32, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _32, _32>>,
                                      Layout<Shape<_4, _2, _1>, Stride<_2, _1, _0>>>::TiledMMA,
        XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_41 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_64, _32, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_64, _32, _32>>,
                                      Layout<Shape<_8, _2, _1>, Stride<_2, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RCR_42 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_128, _32, _32>,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_128, _32, _32>>,
                                      Layout<Shape<_16, _2, _1>, Stride<_2, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        Scheduler::GemmSplitK>;

using PvcGemmBF16BF16FP32_SplitK_RRR_1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelPVC,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_256, _256, _32>,
        TiledMMA<MMAAtom, 
                 Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, 
                 Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                      Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, 
                      _32>>,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V,
        Scheduler::GemmSplitK>;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RRR_1);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_1);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_2);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_3);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_4);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_5);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_6);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_7);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_8);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_9);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_10);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_11);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_12);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_13);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_14);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_15);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_16);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_17);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_18);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_19);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_20);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_21);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_22);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_23);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_24);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_25);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_26);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_27);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_28);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_29);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_30);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_31);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_32);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_33);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_34);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_35);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_36);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_37);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_38);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_39);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_40);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_41);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_42);
static void register_benchmarks() {
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_1);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_2);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_3);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_4);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_5);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_6);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_7);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_8);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_9);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_10);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_11);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_12);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_5);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_6);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_7);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_8);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_9);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_10);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_11);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_12);
  // CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_Linear);
  // CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_Linear_MoE);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_6_silu);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_6_mul);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_13);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_14);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_15);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_16);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_17);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_18);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_19);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_20);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_21);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_22);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_23);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_24);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_25);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_26);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_27);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_28);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_29);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_30);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_31);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_32);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_33);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_34);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_35);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_36);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_37);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_CRR_7);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_CCR_8);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_StreamK_RRR_1);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_StreamK_RCR_1);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_StreamK_RCR_2);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RRR_1);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_1);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_2);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_3);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_4);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_5);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_6);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_7);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_8);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_9);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_10);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_11);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_12);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_13);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_14);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_15);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_16);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_17);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_18);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_19);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_20);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_21);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_22);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_23);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_24);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_25);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_26);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_27);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_28);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_29);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_30);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_31);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_32);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_33);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_34);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_35);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_36);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_37);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_38);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_39);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_40);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_41);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_42);
  CUTLASS_FMHA_BENCHMARK(PvcFMHABF16BF16FP32_RCR_h64_Causal_FixedLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHABF16BF16FP32_RCR_h64_NonCausal_FixedLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHABF16BF16FP32_RCR_h128_Causal_FixedLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHABF16BF16FP32_RCR_h128_NonCausal_FixedLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHABF16BF16FP32_RCR_h192_Causal_FixedLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHABF16BF16FP32_RCR_h192_NonCausal_FixedLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHAFP16FP16FP32_RCR_h64_Causal_FixedLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHAFP16FP16FP32_RCR_h64_NonCausal_FixedLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHAFP16FP16FP32_RCR_h128_Causal_FixedLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHAFP16FP16FP32_RCR_h128_NonCausal_FixedLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHAFP16FP16FP32_RCR_h192_Causal_FixedLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHAFP16FP16FP32_RCR_h192_NonCausal_FixedLen);

  CUTLASS_FMHA_BENCHMARK(PvcFMHABF16BF16FP32_RCR_h64_Causal_VarLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHABF16BF16FP32_RCR_h64_NonCausal_VarLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHABF16BF16FP32_RCR_h128_Causal_VarLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHABF16BF16FP32_RCR_h128_NonCausal_VarLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHABF16BF16FP32_RCR_h192_Causal_VarLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHABF16BF16FP32_RCR_h192_NonCausal_VarLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHAFP16FP16FP32_RCR_h64_Causal_VarLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHAFP16FP16FP32_RCR_h64_NonCausal_VarLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHAFP16FP16FP32_RCR_h128_Causal_VarLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHAFP16FP16FP32_RCR_h128_NonCausal_VarLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHAFP16FP16FP32_RCR_h192_Causal_VarLen);
  CUTLASS_FMHA_BENCHMARK(PvcFMHAFP16FP16FP32_RCR_h192_NonCausal_VarLen);

}
