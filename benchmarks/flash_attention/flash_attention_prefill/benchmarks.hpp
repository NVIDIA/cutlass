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


struct Shape_h64 {
  static constexpr int PipelineStages = 2;
  using ShapeQK = Shape<_128, _64, _64>;
  using ShapePV = Shape<_128, _32, _64>;
  using ShapeOutPut = Shape<_128, _64, _64>;
  using SubgroupLayout = Layout<Shape<_8, _1, _1>, Stride<_1, _1, _1>>;
};

struct Shape_h96 {
  static constexpr int PipelineStages = 2;
  using ShapeQK = Shape<_128, _64, _32>;
  using ShapePV = Shape<_128, _32, _64>;
  using ShapeOutPut = Shape<_128, _96, _64>;
  using SubgroupLayout = Layout<Shape<_8, _1, _1>, Stride<_1, _1, _1>>; 
};

struct Shape_h128 {
  static constexpr int PipelineStages = 2;
  using ShapeQK = Shape<_128, _64, _64>;
  using ShapePV = Shape<_128, _32, _64>;
  using ShapeOutPut = Shape<_128, _128, _64>;
  using SubgroupLayout = Layout<Shape<_16, _1, _1>, Stride<_1, _1, _1>>; 
};

struct Shape_h192 {
  static constexpr int PipelineStages = 2;
  using ShapeQK = Shape<_256, _64, _64>;
  using ShapePV = Shape<_256, _32, _64>;
  using ShapeOutPut = Shape<_256, _192, _64>;
  using SubgroupLayout = Layout<Shape<_32, _1, _1>, Stride<_1, _1, _1>>; 
};

template<class QKVType, bool Causal, bool VarLen, class TileShapeConfig>
struct FMHAPrefillConfigGen {
 // Todo(codeplay) this type should be passed as parameter as well since come shape may get better performace
 // with different copy
  using GmemTiledCopyQ = XE_2D_U16x8x32_LD_N;
  using GmemTiledCopyK = XE_2D_U16x16x16_LD_T; // _T designates a transposed block load operation
  using GmemTiledCopyV = XE_2D_U16x16x32_LD_V;
  using GmemTiledCopyO = XE_2D_U32x8x16_ST_N;
  using type = cutlass::flash_attention::FMHAPrefillConfig<
     // todo(codeplay) : accumulator type and output type should be pass as template parameter
      QKVType, float, float,  
      GmemTiledCopyQ ,
      GmemTiledCopyK,
      GmemTiledCopyV ,
      GmemTiledCopyO,
      typename TileShapeConfig::ShapeQK,
      typename TileShapeConfig::ShapePV,
      typename TileShapeConfig::ShapeOutPut,
      typename TileShapeConfig::SubgroupLayout,
      Causal, VarLen, TileShapeConfig::PipelineStages>;
};

using PvcFMHAPrefillBF16BF16FP32_RCR_h64_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t,  true, false, Shape_h64>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h96_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, true, false, Shape_h96>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h128_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, true, false, Shape_h128>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h192_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, true, false, Shape_h192>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h64_Causal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t,  true, true, Shape_h64>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h96_Causal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, true, true, Shape_h96>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h128_Causal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, true, true, Shape_h128>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h192_Causal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, true, true, Shape_h192>::type;

using PvcFMHAPrefillBF16BF16FP32_RCR_h64_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t,  false, false, Shape_h64>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h96_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, false, false, Shape_h96>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h128_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, false, false, Shape_h128>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h192_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, false, false, Shape_h192>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h64_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t,  false, true, Shape_h64>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h96_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t,  false, true, Shape_h96>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h128_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, false, true, Shape_h128>::type;
using PvcFMHAPrefillBF16BF16FP32_RCR_h192_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::bfloat16_t, false, true, Shape_h192>::type;

using PvcFMHAPrefillFP16FP16FP32_RCR_h64_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t,  true, false, Shape_h64>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h96_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t, true, false, Shape_h96>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h128_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t, true, false, Shape_h128>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h192_Causal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t, true, false, Shape_h192>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h64_Causal_VarLen = FMHAPrefillConfigGen<cutlass::half_t,  true, true, Shape_h64>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h96_Causal_VarLen = FMHAPrefillConfigGen<cutlass::half_t,  true, true, Shape_h96>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h128_Causal_VarLen = FMHAPrefillConfigGen<cutlass::half_t, true, true, Shape_h128>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h192_Causal_VarLen = FMHAPrefillConfigGen<cutlass::half_t, true, true, Shape_h192>::type;

using PvcFMHAPrefillFP16FP16FP32_RCR_h64_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t,  false, false, Shape_h64>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h96_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t,  false, false, Shape_h96>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h128_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t, false, false, Shape_h128>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h192_NonCausal_FixedLen = FMHAPrefillConfigGen<cutlass::half_t, false, false, Shape_h192>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h64_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::half_t,  false, true, Shape_h64>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h96_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::half_t,  false, true, Shape_h96>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h128_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::half_t, false, true, Shape_h128>::type;
using PvcFMHAPrefillFP16FP16FP32_RCR_h192_NonCausal_VarLen = FMHAPrefillConfigGen<cutlass::half_t, false, true, Shape_h192>::type;


CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_NonCausal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h96_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h96_NonCausal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_NonCausal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_NonCausal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_NonCausal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h96_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h96_NonCausal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_NonCausal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_Causal_FixedLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_NonCausal_FixedLen);

CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_NonCausal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h96_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h96_NonCausal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_NonCausal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_NonCausal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_NonCausal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h96_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h96_NonCausal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_NonCausal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_Causal_VarLen);
CUTLASS_CREATE_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_NonCausal_VarLen);

static void register_flash_attention_prefill_benchmarks() {
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_NonCausal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h96_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h96_NonCausal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_NonCausal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_NonCausal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_NonCausal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h96_NonCausal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h96_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_NonCausal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_Causal_FixedLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_NonCausal_FixedLen);

  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h64_NonCausal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h96_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h96_NonCausal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h128_NonCausal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillBF16BF16FP32_RCR_h192_NonCausal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h64_NonCausal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h96_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h96_NonCausal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h128_NonCausal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_Causal_VarLen);
  CUTLASS_FMHA_PREFILL_BENCHMARK(PvcFMHAPrefillFP16FP16FP32_RCR_h192_NonCausal_VarLen);
}
