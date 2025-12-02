/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
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
    \brief Tests for Xe flash attention prefill fp16
*/

#include "flash_prefill_cachedkv_testbed_3x.hpp"

namespace cutlass {

TEST(XE_Flash_Attention_Prefill_fp16_64, causal) {
  constexpr int PipelineStages = 2;
  using ShapeQK = Shape<_128, _64, _64>;
  using ShapePV = Shape<_128, _32, _64>;
  using ShapeOutPut = Shape<_128, _64, _64>;
  using SubgroupLayout = Layout<Shape<_8, _1, _1>, Stride<_1, _1, _1>>; 
  using MMAOperation = XE_8x16x16_F32F16F16F32_TT;
  using Kernel = test::flash_attention::XE_Flash_Attention_Prefill_CachedKV<half_t, float, float, ShapeQK, ShapePV,ShapeOutPut, 
                                            SubgroupLayout, MMAOperation,	true, false, false, 2>::Kernel;
  EXPECT_TRUE(test::flash_attention::TestFlashPrefillCachedKVAll<Kernel>(64));
}

TEST(XE_Flash_Attention_Prefill_fp16_64, noncausal) {
  constexpr int PipelineStages = 2;
	using ShapeQK = Shape<_128, _64, _64>;
  using ShapePV = Shape<_128, _32, _64>;
  using ShapeOutPut = Shape<_128, _64, _64>;
  using SubgroupLayout = Layout<Shape<_8, _1, _1>, Stride<_1, _1, _1>>; 
  using MMAOperation = XE_8x16x16_F32F16F16F32_TT;
  using Kernel = test::flash_attention::XE_Flash_Attention_Prefill_CachedKV<half_t, float, float, ShapeQK, ShapePV,ShapeOutPut, 
                                            SubgroupLayout, MMAOperation, false, false, false, 2>::Kernel;
  EXPECT_TRUE(test::flash_attention::TestFlashPrefillCachedKVAll<Kernel>(64));
}

TEST(XE_Flash_Attention_Prefill_fp16_64, varlen_causal) {
  constexpr int PipelineStages = 2;
  using ShapeQK = Shape<_128, _64, _64>;
  using ShapePV = Shape<_128, _32, _64>;
  using ShapeOutPut = Shape<_128, _64, _64>;
  using SubgroupLayout = Layout<Shape<_8, _1, _1>, Stride<_1, _1, _1>>; 
  using MMAOperation = XE_8x16x16_F32F16F16F32_TT;
  using Kernel = test::flash_attention::XE_Flash_Attention_Prefill_CachedKV<half_t, float, float, ShapeQK, ShapePV,ShapeOutPut, 
                                            SubgroupLayout, MMAOperation, true, false, true, 2>::Kernel;
  EXPECT_TRUE(test::flash_attention::TestFlashPrefillCachedKVAll<Kernel>(64));

}

TEST(XE_Flash_Attention_Prefill_fp16_64, varlen_noncausal) {
  constexpr int PipelineStages = 2;
  using ShapeQK = Shape<_128, _64, _64>;
  using ShapePV = Shape<_128, _32, _64>;
  using ShapeOutPut = Shape<_128, _64, _64>;
  using SubgroupLayout = Layout<Shape<_8, _1, _1>, Stride<_1, _1, _1>>; 
  using MMAOperation = XE_8x16x16_F32F16F16F32_TT;
  using Kernel = test::flash_attention::XE_Flash_Attention_Prefill_CachedKV<half_t, float, float, ShapeQK, ShapePV,ShapeOutPut, 
                                            SubgroupLayout, MMAOperation,	false, false, true, 2>::Kernel;
  EXPECT_TRUE(test::flash_attention::TestFlashPrefillCachedKVAll<Kernel>(64));
}

} // namespace cutlass
