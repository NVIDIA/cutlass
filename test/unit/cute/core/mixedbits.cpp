/***************************************************************************************************
 * Copyright (c) 2017 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass_unit_test.h"

// C<uint32_t(something)>::value_type is not uint32_t for GCC 7.5.0.
// This test is thus disabled for GCC < 8.
#if defined(__GNUC__) && (__GNUC__ < 8)

#include <cutlass/trace.h>
#include <cute/swizzle.hpp>

namespace { // (anonymous)

  // This function exists to work around a Clang 14 issue, in which
  // the compiler tries to instantiate code that lives inside the
  // "else" branch of an "if constexpr," even when the "else" branch
  // is false.  That triggers a spurious static_assert in MixedBits.
  // The work-around is to make the body of the "else" branch a
  // function, rather than leaving it in line.
  //
  // Some compilers strangely deduce the first two terms of
  // make_integer_sequence<uint32_t, 8> as C<false> and C<true>, and
  // the remaining terms as C<2>, C<3>, etc.  Making this function take
  // cute::integral_constant<uint32_t, S0_value>, etc. doesn't work
  // with those compilers.
  template<class S0_type, S0_type S0_value,
    class F0_type, F0_type F0_value,
    class S1_type, S1_type S1_value,
    class F1_type, F1_type F1_value>
  void clang14_workaround(cute::integral_constant<S0_type, S0_value>,
    cute::integral_constant<F0_type, F0_value>,
    cute::integral_constant<S1_type, S1_value>,
    cute::integral_constant<F1_type, F1_value>)
  {
    constexpr cute::C<static_cast<uint32_t>(S0_value)> S0{};
    constexpr cute::C<static_cast<uint32_t>(F0_value)> F0{};
    constexpr cute::C<static_cast<uint32_t>(S1_value)> S1{};
    constexpr cute::C<static_cast<uint32_t>(F1_value)> F1{};

    for (uint32_t d0 = 0; d0 < 8; ++d0) {
      if ((d0 & F0) != d0) { continue; }    // Skip repeats
      for (uint32_t d1 = 0; d1 < 8; ++d1) {
        if ((d1 & F1) != d1) { continue; }  // Skip repeats
        auto m0 = make_mixed_bits(S0, d0, F0);
        auto m1 = make_mixed_bits(S1, d1, F1);
        //print(m0); print(" & "); print(m1); print(" = "); print(m0 & m1); print("\n");
        EXPECT_EQ(uint32_t(m0 & m1), uint32_t(m0) & uint32_t(m1));
        //print(m0); print(" | "); print(m1); print(" = "); print(m0 | m1); print("\n");
        EXPECT_EQ(uint32_t(m0 | m1), uint32_t(m0) | uint32_t(m1));
        //print(m0); print(" ^ "); print(m1); print(" = "); print(m0 ^ m1); print("\n");
        EXPECT_EQ(uint32_t(m0 ^ m1), uint32_t(m0) ^ uint32_t(m1));
      }
    }
  }
} // namespace (anonymous)

TEST(CuTe_core, MixedBits) {
  using namespace cute;

  auto uzero = cute::integral_constant<uint32_t, 0>{};

  for_each(make_integer_sequence<uint32_t, 8>{}, [&](auto S0) {
    for_each(make_integer_sequence<uint32_t, 8>{}, [&](auto F0) {
      for_each(make_integer_sequence<uint32_t, 8>{}, [&](auto S1) {
        for_each(make_integer_sequence<uint32_t, 8>{}, [&](auto F1) {
          if constexpr (decltype(S0 == uzero || S1 == uzero)::value) {
            return;
          } else if constexpr (decltype((S0 & F0) != uzero || (S1 & F1) != uzero)::value) {
            return;
          } else {
            clang14_workaround(S0, F0, S1, F1);
          }
        });
      });
    });
  });
}

TEST(CuTe_core, MakeIntegerSequence) {
  cute::for_each(cute::make_integer_sequence<uint32_t, 8>{}, [](auto c) {
    using c_type = decltype(c);
    constexpr auto c_value = c_type::value;
    using expected_type = cute::integral_constant<uint32_t, c_value>;
    static_assert(cute::is_same_v<c_type, expected_type>);
  });
}

#endif // defined(__GNUC__) && (__GNUC__ < 8)
