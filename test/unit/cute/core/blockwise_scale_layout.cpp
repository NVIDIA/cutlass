/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include <gtest/gtest.h>

#include "cutlass/detail/blockwise_scale_layout.hpp"

TEST(CuTe_core, BlockwiseScaleLayoutSFBUsesOwnMajor) {
  using namespace cute;

  using KMajorSfa = cutlass::detail::Sm1xxBlockwiseScaleConfig<
      64, 128, 128, UMMA::Major::K, UMMA::Major::MN>;
  auto sfb_mn = KMajorSfa::smem_atom_layoutSFB(Shape<_128, _256, _512>{});
  EXPECT_EQ(int(stride<0, 1>(sfb_mn)), 1);
  EXPECT_EQ(int(stride<1, 1>(sfb_mn)), 2);

  using MnMajorSfa = cutlass::detail::Sm1xxBlockwiseScaleConfig<
      64, 128, 128, UMMA::Major::MN, UMMA::Major::K>;
  auto sfb_k = MnMajorSfa::smem_atom_layoutSFB(Shape<_128, _256, _512>{});
  EXPECT_EQ(int(stride<0, 1>(sfb_k)), 4);
  EXPECT_EQ(int(stride<1, 1>(sfb_k)), 1);
}
