/***************************************************************************************************
* Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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

#include "benchmark_runner.hpp"
#include "fmha_prefill_configuration.hpp"

//bfloat16 benchmarks
using TiledMmaBF16_h64 = typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, 
                                                Layout<Shape<_128, _64, _64>>,
                                                Layout<Shape<_8, _1, _1>, Stride<_1, _1, _1>>>::TiledMMA;

using TiledMmaBF16_h128 = typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, 
                                                Layout<Shape<_128, _128, _64>>,
                                                Layout<Shape<_8, _2, _1>, Stride<_2, _1, _1>>>::TiledMMA;

using TiledMmaBF16_h192 = typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, 
                                                Layout<Shape<_256, _64, _64>>,
                                                Layout<Shape<_16, _1, _1>, Stride<_1, _1, _1>>>::TiledMMA;


//half benchmarks
using TiledMmaFP16_h64 = typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, 
                                                Layout<Shape<_128, _64, _64>>,
                                                Layout<Shape<_8, _1, _1>, Stride<_1, _1, _1>>>::TiledMMA;

using TiledMmaFP16_h128 = typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, 
                                                Layout<Shape<_128, _128, _64>>,
                                                Layout<Shape<_8, _2, _1>, Stride<_2, _1, _1>>>::TiledMMA;

using TiledMmaFP16_h192 = typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>, 
                                                Layout<Shape<_256, _64, _64>>,
                                                Layout<Shape<_16, _1, _1>, Stride<_1, _1, _1>>>::TiledMMA;

using Shape_h64 = Shape<_128, _64, _64, _64>;
using Shape_h128 = Shape<_128, _128, _64, _64>;
using Shape_h192 = Shape<_256, _64, _64, _64>;

template<class QKVType, bool Causal, bool VarLen, class TileShape, class TiledMma>
struct FMHAPrefillConfigGen {
using type = cutlass::flash_attention::FMHAPrefillConfig<
      QKVType, QKVType, QKVType, 
      cutlass::layout::RowMajor, 
      cutlass::layout::ColumnMajor, 
      cutlass::layout::RowMajor,
      cutlass::layout::RowMajor,
      Causal, VarLen, TileShape,
      TiledMma>;
};

using PvcFMHAPrefillBF16BF16FP32_RCR_h64_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t,  true, false, Shape_h64, TiledMmaBF16_h64>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h128_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, true, false, Shape_h128, TiledMmaBF16_h128>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h192_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, true, false, Shape_h192, TiledMmaBF16_h192>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h64_Causal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t,  true, true, Shape_h64, TiledMmaBF16_h64>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h128_Causal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, true, true, Shape_h128, TiledMmaBF16_h128>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h192_Causal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, true, true, Shape_h192, TiledMmaBF16_h192>::type;

using PvcFMHAPrefillBF16BF16FP32_RCR_h64_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t,  false, false, Shape_h64, TiledMmaBF16_h64>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h128_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, false, false, Shape_h128, TiledMmaBF16_h128>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h192_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, false, false, Shape_h192, TiledMmaBF16_h192>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h64_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t,  false, true, Shape_h64, TiledMmaBF16_h64>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h128_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, false, true, Shape_h128, TiledMmaBF16_h128>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h192_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, false, true, Shape_h192, TiledMmaBF16_h192>::type;

using PvcFMHAPrefillFP16FP16FP32_RCR_h64_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t,  true, false, Shape_h64, TiledMmaFP16_h64>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h128_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t, true, false, Shape_h128, TiledMmaFP16_h128>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h192_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t, true, false, Shape_h192, TiledMmaFP16_h192>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h64_Causal_VarLen = FMHAPrefillConfigGen<cutlass::half_t,  true, true, Shape_h64, TiledMmaFP16_h64>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h128_Causal_VarLen = FMHAPrefillConfigGen<cutlass::half_t, true, true, Shape_h128, TiledMmaFP16_h128>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h192_Causal_VarLen = FMHAPrefillConfigGen<cutlass::half_t, true, true, Shape_h192, TiledMmaFP16_h192>::type;

using PvcFMHAPrefillFP16FP16FP32_RCR_h64_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t,  false, false, Shape_h64, TiledMmaFP16_h64>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h128_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t, false, false, Shape_h128, TiledMmaFP16_h128>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h192_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t, false, false, Shape_h192, TiledMmaFP16_h192>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h64_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::half_t,  false, true, Shape_h64, TiledMmaFP16_h64>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h128_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::half_t, false, true, Shape_h128, TiledMmaFP16_h128>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h192_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::half_t, false, true, Shape_h192, TiledMmaFP16_h192>::type;


CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_NonCausal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_NonCausal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_NonCausal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_NonCausal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_NonCausal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_NonCausal_FixedLen);

CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_NonCausal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_NonCausal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_NonCausal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_NonCausal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_NonCausal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_NonCausal_VarLen);

static void register_flash_attention_prefill_benchmarks() {
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_NonCausal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_NonCausal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_NonCausal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_NonCausal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_NonCausal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_NonCausal_FixedLen);

  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_NonCausal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_NonCausal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_NonCausal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_NonCausal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_NonCausal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_NonCausal_VarLen);
}
