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

#include "gemm_configuration_sycl.hpp"

using Scheduler = cutlass::gemm::device::Scheduler;

using MMAAtom = MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>;

template <
  typename TileShape,
  typename Tiler,
  typename GmemTiledCopyA,
  typename GmemTiledCopyB>
using Gemm_Bench_BF16FP32_RRR = cutlass::gemm::device::GemmConfiguration<
    cutlass::arch::IntelXe,
    cutlass::bfloat16_t, cutlass::layout::RowMajor,
    cutlass::bfloat16_t, cutlass::layout::RowMajor,
    float, cutlass::layout::RowMajor,
    float,
    TileShape, Scheduler::Gemm, Tiler,
    GmemTiledCopyA, GmemTiledCopyB>;


using Tile_1 = TiledMMA<MMAAtom, Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>, Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, _32>>;
using PvcGemmBF16BF16FP32_RRR_1 = Gemm_Bench_BF16FP32_RRR<Shape<_256, _256, _32>, Tile_1, XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V>;

using Tile_2 = TiledMMA<MMAAtom, Layout<Shape<_4,_8,_1>, Stride<_8,_1,_0>>, Tile<Layout<Shape<_8, _4, _4>, Stride<_1, _32, _8>>, Layout<Shape<_16, _8, _4>, Stride<_1, _64, _16>>, _32>>;
using PvcGemmBF16BF16FP32_RRR_2 = Gemm_Bench_BF16FP32_RRR<Shape<_128, _512, _32>, Tile_2, XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V>;

using Tile_3 = TiledMMA<MMAAtom, Layout<Shape<_8,_4,_1>, Stride<_4,_1,_0>>, Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>, Layout<Shape<_16, _4, _2>, Stride<_1, _32, _16>>, _32>>;
using PvcGemmBF16BF16FP32_RRR_3 = Gemm_Bench_BF16FP32_RRR<Shape<_256, _128, _32>, Tile_3, XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V>;

using Tile_4 = TiledMMA<MMAAtom, Layout<Shape<_4,_8,_1>, Stride<_8,_1,_0>>, Tile<Layout<Shape<_8, _4, _4>, Stride<_1, _32, _8>>, Layout<Shape<_16, _8, _1>, Stride<_1, _16, _0>>, _16>>;
using PvcGemmBF16BF16FP32_RRR_4 = Gemm_Bench_BF16FP32_RRR<Shape<_128, _256, _16>, Tile_4, XE_2D_U16x32x16_LD_N, XE_2D_U16x16x16_LD_V>;

using Tile_5 = TiledMMA<MMAAtom, Layout<Shape<_1,_4,_1>, Stride<_0,_1,_0>>, Tile<Layout<Shape<_8, _1, _1>, Stride<_1, _0, _0>>, Layout<Shape<_16, _4, _2>, Stride<_1, _32, _16>>, _32>>;
using PvcGemmBF16BF16FP32_RRR_5 = Gemm_Bench_BF16FP32_RRR<Shape<_8, _128, _32>, Tile_5, XE_2D_U16x8x32_LD_N, XE_2D_U16x32x32_LD_V>;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_1);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_2);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_3);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_4);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RRR_5);

using PvcGemmCollectiveBF16BF16FP32_RRR_256x256x32 = cutlass::gemm::device::GemmConfiguration<
    cutlass::arch::IntelXe,
    cutlass::bfloat16_t, cutlass::layout::RowMajor,
    cutlass::bfloat16_t, cutlass::layout::RowMajor,
    float, cutlass::layout::RowMajor,
    float,
    Shape<_256,_256,_32>, Scheduler::Gemm>;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmCollectiveBF16BF16FP32_RRR_256x256x32);

template <
  typename TileShape,
  typename Tiler,
  typename GmemTiledCopyA,
  typename GmemTiledCopyB>
using Gemm_Bench_BF16FP32_RCR = cutlass::gemm::device::GemmConfiguration<
    cutlass::arch::IntelXe,
    cutlass::bfloat16_t, cutlass::layout::RowMajor,
    cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
    float, cutlass::layout::RowMajor,
    float,
    TileShape, Scheduler::Gemm, Tiler,
    GmemTiledCopyA, GmemTiledCopyB>;

using Tile_6 = TiledMMAHelper<MMAAtom, Layout<Shape<_8, _128, _32>>, Layout<Shape<_1, _4, _1>, Stride<_0, _1, _0>>>::TiledMMA;
using PvcGemmBF16BF16FP32_RCR_5 = Gemm_Bench_BF16FP32_RCR<Shape<_8, _128, _32>, Tile_6, XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T>;

using PvcGemmBF16BF16FP32_RCR_6 = Gemm_Bench_BF16FP32_RCR<Shape<_256, _256, _32>, Tile_1, XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T>;

using Tile_7 = TiledMMAHelper<MMAAtom, Layout<Shape<_8, _128, _32>>, Layout<Shape<_1, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA;
using PvcGemmBF16BF16FP32_RCR_7 = Gemm_Bench_BF16FP32_RCR<Shape<_8, _128, _32>, Tile_7, XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T>;


using Tile_8 = TiledMMAHelper<MMAAtom, Layout<Shape<_8, _64, _32>>, Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA;
using PvcGemmBF16BF16FP32_RCR_9 = Gemm_Bench_BF16FP32_RCR<Shape<_8, _64, _32>, Tile_8, XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T>;

using Tile_9 = TiledMMAHelper<MMAAtom, Layout<Shape<_16, _64, _32>>, Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA;
using PvcGemmBF16BF16FP32_RCR_16 = Gemm_Bench_BF16FP32_RCR<Shape<_16, _64, _32>, Tile_9, XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T>;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_5);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_6);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_7);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_9);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_16);

template <
  typename TileShape,
  typename Tiler,
  typename GmemTiledCopyA,
  typename GmemTiledCopyB,
  typename Epilogue>
using SplitK_Bench_BF16FP32_RCR_Epilogue = cutlass::gemm::device::GemmConfiguration<
    cutlass::arch::IntelXe,
    cutlass::bfloat16_t, cutlass::layout::RowMajor,
    cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
    float, cutlass::layout::RowMajor,
    float,
    TileShape, Scheduler::GemmSplitK, Tiler,
    GmemTiledCopyA, GmemTiledCopyB, Epilogue>;

using Tile_10 = TiledMMAHelper<MMAAtom, Layout<Shape<_8, _64, _32>>, Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA;
using SiLuF32 = cutlass::epilogue::fusion::LinCombEltAct<
  cutlass::epilogue::thread::SiLu,
  float, float, float, float,
  cutlass::FloatRoundStyle::round_to_nearest>;
using PvcGemmBF16BF16FP32_RCR_8_silu = SplitK_Bench_BF16FP32_RCR_Epilogue<
  Shape<_8, _64, _32>,
  Tile_10,
  XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
  SiLuF32>;

using Tile_11 = TiledMMAHelper<MMAAtom, Layout<Shape<_8, _64, _32>>, Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA;
using PvcGemmBF16BF16FP32_RCR_7_mul = SplitK_Bench_BF16FP32_RCR_Epilogue<
  Shape<_8, _64, _32>,
  Tile_11,
  XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
  cutlass::epilogue::fusion::LinCombDeEltAct<
    cutlass::layout::RowMajor, std::multiplies, float, float>>;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_8_silu);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_7_mul);

using PvcGemmCollectiveBF16BF16FP32_RCR_silu_8x64x32 = cutlass::gemm::device::GemmConfiguration<
    cutlass::arch::IntelXe,
    cutlass::bfloat16_t, cutlass::layout::RowMajor,
    cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
    float, cutlass::layout::RowMajor,
    float,
    Shape<_8,_64,_32>, Scheduler::GemmSplitK,
    void, void, void,
    SiLuF32>;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmCollectiveBF16BF16FP32_RCR_silu_8x64x32);

using PvcGemmBF16BF16FP32_CRR_7 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelXe,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float,
        Shape<_256, _256, _32>, Scheduler::Gemm, Tile_1,
        XE_2D_U16x16x16_LD_T, XE_2D_U16x32x32_LD_V
        >;

using PvcGemmBF16BF16FP32_CCR_8 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelXe,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float,
        Shape<_256, _256, _32>, Scheduler::Gemm, Tile_1,
        XE_2D_U16x16x16_LD_T, XE_2D_U16x16x16_LD_T>;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_CRR_7);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_CCR_8);


// TODO(codeplay): Re-enable these once there is general support for epilogues
// using PvcGemmBF16BF16FP32_RCR_Linear = cutlass::gemm::device::GemmConfiguration<
//         cutlass::arch::IntelXe,
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
//         cutlass::arch::IntelXe,
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
// CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_Linear);
// CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_RCR_Linear_MoE);
//
using PvcGemmFP16FP16FP32_RCR_5 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelXe,
        cutlass::half_t, cutlass::layout::RowMajor,
        cutlass::half_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _32>, Scheduler::Gemm,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, Layout<Shape<_8, _128, _32>>,
        Layout<Shape<_1, _4, _1>, Stride<_0, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T
        >;

using PvcGemmFP16FP16FP32_RCR_7 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelXe,
        cutlass::half_t, cutlass::layout::RowMajor,
        cutlass::half_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _128, _32>, Scheduler::Gemm,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, Layout<Shape<_8, _128, _32>>,
                                      Layout<Shape<_1, _8, _1>, Stride<_8, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T
        >;

using PvcGemmFP16FP16FP32_RCR_9 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelXe,
        cutlass::half_t, cutlass::layout::RowMajor,
        cutlass::half_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _64, _32>, Scheduler::Gemm,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, Layout<Shape<_8, _64, _32>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T
        >;

using PvcGemmFP16FP16FP32_RCR_16 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelXe,
        cutlass::half_t, cutlass::layout::RowMajor,
        cutlass::half_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_16, _64, _32>, Scheduler::Gemm,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, Layout<Shape<_16, _64, _32>>,
                                      Layout<Shape<_2, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T
        >;

using PvcGemmFP16FP16FP32_RCR_7_mul = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelXe,
        cutlass::half_t, cutlass::layout::RowMajor,
        cutlass::half_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _64, _32>, Scheduler::GemmSplitK,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, Layout<Shape<_8, _64, _32>>,
                                        Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        cutlass::epilogue::fusion::LinCombDeEltAct<
        cutlass::layout::RowMajor, std::multiplies, float, float>
        >;

using PvcGemmFP16FP16FP32_RCR_8_silu = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelXe,
        cutlass::half_t, cutlass::layout::RowMajor,
        cutlass::half_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _64, _32>, Scheduler::GemmSplitK,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, Layout<Shape<_8, _64, _32>>,
                                      Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T,
        cutlass::epilogue::fusion::LinCombEltAct<
            cutlass::epilogue::thread::SiLu,
            float, float, float, float,
            cutlass::FloatRoundStyle::round_to_nearest>>;

using PvcGemmFP16FP16FP32_SplitK_RCR_5 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelXe,
        cutlass::half_t, cutlass::layout::RowMajor,
        cutlass::half_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float, Shape<_8, _64, _32>,  Scheduler::GemmSplitK,
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, Layout<Shape<_8, _64, _32>>,
                                        Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T
        >;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmFP16FP16FP32_RCR_5);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmFP16FP16FP32_RCR_7);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmFP16FP16FP32_RCR_9);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmFP16FP16FP32_RCR_16);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmFP16FP16FP32_RCR_7_mul);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmFP16FP16FP32_RCR_8_silu);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmFP16FP16FP32_SplitK_RCR_5);

using PvcGemmBF16BF16FP32_SplitK_RRR_1 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelXe,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        float, cutlass::layout::RowMajor,
        float,
        Shape<_256, _256, _32>, Scheduler::GemmSplitK, Tile_1,
        XE_2D_U16x32x32_LD_N, XE_2D_U16x32x32_LD_V>;

using Tile_12 = TiledMMAHelper<MMAAtom, Layout<Shape<_8, _64, _32>>, Layout<Shape<_1, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA;
using PvcGemmBF16BF16FP32_SplitK_RCR_5 = cutlass::gemm::device::GemmConfiguration<
        cutlass::arch::IntelXe,
        cutlass::bfloat16_t, cutlass::layout::RowMajor,
        cutlass::bfloat16_t, cutlass::layout::ColumnMajor,
        float, cutlass::layout::RowMajor,
        float,
        Shape<_8, _64, _32>, Scheduler::GemmSplitK, Tile_12,
        XE_2D_U16x8x32_LD_N, XE_2D_U16x16x16_LD_T>;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RRR_1);
CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_5);

// TODO: benchmark is named streamK but uses splitk scheduler
using PvcGemmBF16BF16FP32_StreamK_RRR_1 = PvcGemmBF16BF16FP32_SplitK_RRR_1;

CUTLASS_CREATE_GEMM_BENCHMARK(PvcGemmBF16BF16FP32_StreamK_RRR_1);

static void register_gemm_benchmarks() {
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_1);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_2);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_3);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_4);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RRR_5);
  CUTLASS_BENCHMARK(PvcGemmCollectiveBF16BF16FP32_RRR_256x256x32);

  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_5);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_6);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_7);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_9);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_16);

  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_8_silu);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_7_mul);
  CUTLASS_BENCHMARK(PvcGemmCollectiveBF16BF16FP32_RCR_silu_8x64x32);

  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_CRR_7);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_CCR_8);

  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RRR_1);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_SplitK_RCR_5);
  CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_StreamK_RRR_1);

  CUTLASS_BENCHMARK(PvcGemmFP16FP16FP32_RCR_5);
  CUTLASS_BENCHMARK(PvcGemmFP16FP16FP32_RCR_7);
  CUTLASS_BENCHMARK(PvcGemmFP16FP16FP32_RCR_9);
  CUTLASS_BENCHMARK(PvcGemmFP16FP16FP32_RCR_16);
  CUTLASS_BENCHMARK(PvcGemmFP16FP16FP32_RCR_7_mul);
  CUTLASS_BENCHMARK(PvcGemmFP16FP16FP32_RCR_8_silu);
  CUTLASS_BENCHMARK(PvcGemmFP16FP16FP32_SplitK_RCR_5);

  // CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_Linear);
  // CUTLASS_BENCHMARK(PvcGemmBF16BF16FP32_RCR_Linear_MoE);
}
