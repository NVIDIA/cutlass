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

#include "cutlass/detail/layout.hpp"

#include <cute/tensor.hpp>
#include <sycl/sycl.hpp>
#include <syclcompat.hpp>

#include "cutlass_unit_test.h"

using namespace cute;
using namespace cute::detail;

using namespace cutlass;
using namespace cutlass::layout;
using namespace cutlass::detail;

using namespace syclcompat::experimental;

#define SUBGROUP_SIZE (16)

#define CUTLASS_ENABLE_DEBUG_PRINTS (0)
#define LOG_GROUP (0)
#undef LOG_THREAD
#define LOG_THREAD (0)

template <class atype, class btype, class ctype>
void verify(uint32_t m, uint32_t n, uint32_t k, atype *A, btype *B, ctype *C,
            bool row_a = true, bool row_b = true) {
  int cnt = 0;
  bool is_normal = true;

  for (int i = 0; i < m; i++) {
    for (int j = 0; j < n; j++) {
      ctype expect = ctype(0);
      for (int z = 0; z < k; z++) {
        auto a = row_a ? A[i * k + z] : A[i + z * m];
        auto b = row_b ? B[z * n + j] : B[z + j * k];
        expect += a * b;
      }

      ctype val = C[i * n + j];

      if constexpr(std::is_floating_point_v<ctype>) {
        if (isnormal(val) && isnormal(expect)) {
          auto error = std::abs((expect - val) / val);
          if (error > 0.01f) {
            cnt++;
          }
        } else {
          // TODO(codeplay): Assert that at least some values are non-zero.
          if(!(expect == 0 && val == 0)) is_normal = false;
        }
      } else {
        if (val != expect) {
          cnt++;
        }
      }
    }
  }

  EXPECT_EQ(cnt, 0);
  EXPECT_EQ(is_normal, true);
}

template <typename T> static void fill_matrix(cutlass::host_vector<T> &M) {
  std::random_device dev;
  std::mt19937 rng(dev());

  T start, end;

  if constexpr (std::is_same_v<T, tfloat32_t> || std::is_same_v<T, half_t>
                 || std::is_same_v<T, bfloat16_t> || std::is_same_v<T, float>) {
    start = (T)0.0;
    end = (T)1.0;
  } else if constexpr (std::is_same_v<T, int8_t>) {
    start = (T)(-5);
    end = (T)5;
  } else if constexpr (std::is_same_v<T, uint8_t>) {
    start = (T)0;
    end = (T)5;
  } else {
    CUTE_STATIC_ASSERT(false, "you must set coreect start/end value to initialize data");
  }

  std::uniform_real_distribution<float> dist((T)start, (T)end);
  for (int i = 0; i < M.size(); i++)
    M[i] = static_cast<T>(dist(rng));
}

template <class kernel> void run(uint32_t m, uint32_t n, uint32_t k) {

  using TA = typename kernel::TA;
  using TB = typename kernel::TB;
  using TC = typename kernel::TC;

  cutlass::host_vector<TA> h_A(m * k);
  cutlass::host_vector<TB> h_B(n * k);
  cutlass::host_vector<TC> h_C(m * n);

  fill_matrix(h_A);
  fill_matrix(h_B);

  cutlass::device_vector<TA> d_A = h_A;
  cutlass::device_vector<TB> d_B = h_B;
  cutlass::device_vector<TC> d_C = h_C;

  auto dimBlock = syclcompat::dim3(
      ceil_div(kernel::wg_tile_m, kernel::sg_tile_m),
      SUBGROUP_SIZE * ceil_div(kernel::wg_tile_n, kernel::sg_tile_n));
  auto dimGrid = syclcompat::dim3(size(ceil_div(m, kernel::wg_tile_m)),
                                  size(ceil_div(n, kernel::wg_tile_n)));

  launch<kernel::func>(
      launch_policy{dimGrid, dimBlock,
                    kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
      d_A.data(), d_B.data(), d_C.data(), m, n, k);

  syclcompat::wait();

  h_C = d_C;
  verify(m, n, k, h_A.data(), h_B.data(), h_C.data(), kernel::is_a_row_major,
         kernel::is_b_row_major);
}
