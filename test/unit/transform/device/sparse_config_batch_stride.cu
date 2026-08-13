/***************************************************************************************************
 * Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "../../common/cutlass_unit_test.h"

#include "cute/atom/mma_traits_sm90_gmma.hpp"                      // cute::GMMA::Major
#include "cutlass/gemm/collective/builders/sm90_sparse_config.inl" // Sm90GemmSparseConfig
#include "cutlass/gemm/collective/builders/sm1xx_sparse_config.inl"// Sm1xxGemmSparseConfig
#include "cutlass/layout/matrix.h"                                 // RowMajor
#include "cutlass/numeric_types.h"                                 // float_e4m3_t

///////////////////////////////////////////////////////////////////////////////////////////////////

namespace {

// The batch stride is the product of two aligned extents. Both are int, thus the product
// overflows for a large problem and the cast to int64_t widens a value that already wrapped.
template <class Config>
void check_batch_stride(int M, int K, int64_t expect_a, int64_t expect_e) {
  auto layout_a = Config::fill_layoutA(cute::make_shape(M, 128, K, 2));
  auto layout_e = Config::fill_layoutE(cute::make_shape(M, 128, K, 2));
  EXPECT_EQ(int64_t(cute::stride<2>(layout_a)), expect_a) << "M " << M << " K " << K;
  EXPECT_EQ(int64_t(cute::stride<2>(layout_e)), expect_e) << "M " << M << " K " << K;
}

} // namespace

TEST(Sparse_Config, sm90_batch_stride_wider_than_32_bits) {
  using ElementAMma = cute::sparse_elem<2, cutlass::float_e4m3_t>;
  using ElementEMma = cute::sparse_elem<8, uint8_t>;
  using Config = cutlass::Sm90GemmSparseConfig<ElementAMma, cute::GMMA::Major::K,
                                               ElementEMma, cute::Int<64>>;

  check_batch_stride<Config>(49152, 65536, 3221225472LL, 3221225472LL);
  check_batch_stride<Config>(65536, 65536, 4294967296LL, 4294967296LL);
}

TEST(Sparse_Config, sm1xx_batch_stride_wider_than_32_bits) {
  using ElementAMma = cute::sparse_elem<2, cutlass::float_e4m3_t>;
  using ElementEMma = cute::sparse_elem<8, uint8_t>;
  using Config = cutlass::Sm1xxGemmSparseConfig<ElementAMma, cutlass::layout::RowMajor,
                                                ElementEMma>;

  check_batch_stride<Config>(49152, 65536, 3221225472LL, 3221225472LL);
  check_batch_stride<Config>(65536, 65536, 4294967296LL, 4294967296LL);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
