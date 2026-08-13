/***************************************************************************************************
 * Copyright (c) 2017 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Bounds of the TMA descriptor construction on the host.
*/

#include "cutlass_unit_test.h"

#include <cstdlib>

#include <cute/tensor.hpp>
#include <cute/atom/copy_traits_sm90_tma.hpp>

using namespace cute;

namespace {

// Builds a multicast TMA atom whose cluster is larger than the TMA box.
// The box is 8 by 4, and the product of its modes is 32.
void build_atom_with_cluster_above_box()
{
  auto gmem_layout = make_layout(make_shape(256, 256), GenRowMajor{});
  auto smem_layout = make_layout(make_shape(_8{}, _4{}), GenRowMajor{});
  Tensor gtensor = make_tensor(make_gmem_ptr<float>(nullptr), gmem_layout);
  auto atom = make_tma_atom(SM90_TMA_LOAD_MULTICAST{}, gtensor, smem_layout,
                            product_each(shape(smem_layout)), Int<64>{});
  (void) atom;
}

} // namespace

// The box truncation loop counts down through the TMA box modes. A cluster
// larger than the product of those modes leaves the loop index below mode 0.
// An unsigned index then wraps and reads smem_box_shape far outside the array.
// The child process must complete the call and exit with the code 0.
TEST(CuTe_Tma_Descriptor, Multicast_Cluster_Above_Box)
{
  GTEST_FLAG_SET(death_test_style, "threadsafe");
  EXPECT_EXIT({ build_atom_with_cluster_above_box(); std::exit(0); },
              ::testing::ExitedWithCode(0), "");
}
