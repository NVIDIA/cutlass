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
    \brief Tests for Xe flash attention prefill
*/

#include "flash_prefill_testbed_3x.hpp"

namespace cutlass {

using MMAOperation = test::flash_attention::MMAOP;
using Shape_h = test::flash_attention::SHAPE_H;

TEST(TEST_NAME, causal) {
  using Kernel = test::flash_attention::XE_Flash_Attention_Prefill<INPUT_TYPE, float, OUT_TYPE, typename Shape_h::ShapeQK, typename Shape_h::ShapePV,
                                            typename Shape_h::ShapeOutput, typename Shape_h::SubgroupLayout, MMAOperation, true, false, 2>::Kernel;
  EXPECT_TRUE(test::flash_attention::TestFlashPrefillAll<Kernel>(HEAD_DIM));
}

TEST(TEST_NAME, noncausal) {
  using Kernel = test::flash_attention::XE_Flash_Attention_Prefill<INPUT_TYPE, float, OUT_TYPE, typename Shape_h::ShapeQK, typename Shape_h::ShapePV,
                                            typename Shape_h::ShapeOutput, typename Shape_h::SubgroupLayout, MMAOperation, false, false, 2>::Kernel;
  EXPECT_TRUE(test::flash_attention::TestFlashPrefillAll<Kernel>(HEAD_DIM));
}

TEST(GTEST_CONCAT_TOKEN_(DISABLED_, TEST_NAME), varlen_causal) {
  using Kernel = test::flash_attention::XE_Flash_Attention_Prefill<INPUT_TYPE, float, OUT_TYPE, typename Shape_h::ShapeQK, typename Shape_h::ShapePV,
                                            typename Shape_h::ShapeOutput, typename Shape_h::SubgroupLayout, MMAOperation, true, true, 2>::Kernel;
  EXPECT_TRUE(test::flash_attention::TestFlashPrefillAll<Kernel>(HEAD_DIM));
}

TEST(TEST_NAME, varlen_noncausal) {
  using Kernel = test::flash_attention::XE_Flash_Attention_Prefill<INPUT_TYPE, float, OUT_TYPE, typename Shape_h::ShapeQK, typename Shape_h::ShapePV,
                                            typename Shape_h::ShapeOutput, typename Shape_h::SubgroupLayout, MMAOperation, false, true, 2>::Kernel;
  EXPECT_TRUE(test::flash_attention::TestFlashPrefillAll<Kernel>(HEAD_DIM));
}

TEST(TEST_NAME, Llama3_70B) {
  using Kernel = test::flash_attention::XE_Flash_Attention_Prefill<INPUT_TYPE, float, OUT_TYPE, typename Shape_h::ShapeQK, typename Shape_h::ShapePV,
                                            typename Shape_h::ShapeOutput, typename Shape_h::SubgroupLayout, MMAOperation, true, false, 2>::Kernel; // Causal for autoregressive
  EXPECT_TRUE(test::flash_attention::TestFlashPrefillAll<Kernel>(HEAD_DIM, "llama3_70b"));
}

} // namespace cutlass
