/***************************************************************************************************
 * Copyright (c) 2017-2021, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Templates implementing warp-level per channel scale+bias+relu before
   matrix multiply-accumulate operations targeting Tensor Cores.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/array.h"
#include "cutlass/platform/platform.h"

#include "cutlass/numeric_conversion.h"
#include "cutlass/numeric_types.h"
#include "cutlass/matrix_shape.h"

#include "cutlass/arch/memory_sm75.h"
#include "cutlass/arch/mma_sm75.h" 
#include "cutlass/arch/mma_sm80.h"

#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/warp/mma.h"

#include "cutlass/gemm/warp/mma_tensor_op_policy.h"

#include "cutlass/gemm/warp/mma_tensor_op_tile_iterator.h"
#include "cutlass/gemm/warp/mma_tensor_op_tile_iterator_sm80.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace gemm {
namespace warp {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename FragmentActivations, typename FragmentScaleBias,
          typename FragmentMean>
struct GemmScaleBiasTransform {

  using T_A = typename FragmentActivations::Element;
  using T_BIAS = typename FragmentScaleBias::Element;
  using T_HALF2 = __half2;

  static int const NumActivations = FragmentActivations::kElements;
  static int const NumScaleBias = FragmentScaleBias::kElements;
  static int const MmaElements = 2;
  // One element has one scale and one bias
  static int const MmaScaleBiasPair = 2;
  // 16816 has 2 columns
  static int const MmaCols = 2;

  using MmaOperand = Array<T_A, MmaElements>;
  using ScaleBiasOperand = Array<T_BIAS, MmaElements * MmaScaleBiasPair>;

  CUTLASS_DEVICE
  void transform(MmaOperand &activations, ScaleBiasOperand const &scale_bias, float mean_val, float variance_val, int const &i) {

#if (defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 800))
    uint32_t *ptr_activations = reinterpret_cast<uint32_t *>(&activations);
    uint32_t const *ptr_scale_bias = reinterpret_cast<uint32_t const *>(&scale_bias);

    float2 gamma_val, beta_val, local_out_fp2;
    local_out_fp2 = __half22float2( ((half2 *)ptr_activations)[0] );
    gamma_val = __half22float2( ((half2 *)ptr_scale_bias)[0] );
    beta_val = __half22float2( ((half2 *)ptr_scale_bias)[1] );
    local_out_fp2.x = fmaf((local_out_fp2.x - mean_val), (gamma_val.x * variance_val), beta_val.x);
    local_out_fp2.y = fmaf((local_out_fp2.y - mean_val), (gamma_val.y * variance_val), beta_val.y);

    // if (local_out_fp2.x > 0.1) printf("tid = %d, idx = %d, data = {%5.2f, %5.2f}, gamma = {%5.2f, %5.2f}, beta = {%5.2f, %5.2f}, res = {%5.2f, %5.2f}.\n", threadIdx.x, i, local_out_fp2.x, local_out_fp2.y, 
    // gamma_val.x, gamma_val.y, beta_val.x, beta_val.y, fmaf(local_out_fp2.x, gamma_val.x, beta_val.x), fmaf(local_out_fp2.y, gamma_val.y, beta_val.y));

    asm volatile(
        "{\n\t"
        " cvt.rn.f16x2.f32 %0, %2, %1;"
        "}\n"
        : "=r"(ptr_activations[0])
        : "f"(local_out_fp2.x), "f"(local_out_fp2.y));

    // Apply per channel scale+bias+relu if the data is not a special NaN
    // (0x7eff).  If it is a special NaN (0x7eff), hard code the output to 0.

    // We assumes the pair of FP16 are either both inbound or both out-of-bound.
    // It requires C to be an even number.

    // activations: fp16, scale_bias: fp32.
    // t0, t1 = cvt.fp32.fp16x2(activations[0])
    // two fmas on scale_bias[0], scale_bias[1], scale_bias[2], and scale_bias[3]
    // cvt back to fp16x2 and save to result.

    // asm volatile(
    //     "{\n\t"
    //     // " .reg .pred %%p;\n\t"
    //     // " setp.eq.u32 %%p, %0, %7;\n\t"
    //     " .reg .b32 a1; .reg .b32 a2;"
    //     " .reg .b32 t2; .reg .b32 t1; .reg .b32 r1;"
    //     " cvt.f32.f16 a1, %1; cvt.f32.f16 a2, %2;"
    //     " fma.rn.f32 t1, a1, %3, %5; fma.rn.f32 t2, a2, %4, %6;"
    //     " cvt.rz.f16x2.f32 r1, t1, t2;"
    //     " mov.b32 %0, r1;"
    //     // " selp.u32 %0, 0, r1, %%p;\n\t"
    //     "}\n"
    //     : "=r"(ptr_activations[0])
    //     : "h"(ptr_activations_f16[0]),
    //       "h"(ptr_activations_f16[1]),
    //       "r"(ptr_scale_bias[0]),
    //       "r"(ptr_scale_bias[1]),
    //       "r"(ptr_scale_bias[2]),
    //       "r"(ptr_scale_bias[3]));

    // asm volatile(
    //     "{\n\t"
    //     " .reg .pred %%p;\n\t"
    //     " .reg .b32 t1;\n\t"
    //     " setp.eq.u32 %%p, %2, %4;\n\t"
    //     " fma.rn.f16x2 t1, %1, %2, %3;\n"
    //     " selp.u32 %0, 0, t1, %%p;\n\t"
    //     "}\n"
    //     : "=r"(ptr_activations[0])
    //     : "r"(ptr_scale_bias[0]), "r"(ptr_activations[0]),
    //       "r"(ptr_scale_bias[1]), "n"(0x7eff7eff));


    // asm volatile(
    //     "{\n\t"
    //     " fma.rn.f16x2 %0, %1, %2, %3;\n"
    //     "}\n"
    //     : "=r"(ptr_activations[0])
    //     : "r"(ptr_scale_bias[0]), "r"(ptr_activations[0]),
    //       "r"(ptr_scale_bias[1]));

#else
    // TODO: write emulation code
    assert(0);
#endif
  }

  CUTLASS_DEVICE
  void operator()(FragmentActivations &activations,
                  FragmentScaleBias const &scale_bias,
                  FragmentMean const &mean,
                  FragmentMean const &variance) {
    MmaOperand *ptr_activations = reinterpret_cast<MmaOperand *>(&activations);
    ScaleBiasOperand const *ptr_scale_bias =
        reinterpret_cast<ScaleBiasOperand const *>(&scale_bias);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < (NumActivations / MmaElements); ++i) {
      int idx = (i / 4) * 2 + (i % 2);
      transform(ptr_activations[i], ptr_scale_bias[(i / MmaScaleBiasPair) % MmaCols], mean[idx], variance[idx], i);
    }
  }
};

} // namespace warp
} // namespace conv 
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
