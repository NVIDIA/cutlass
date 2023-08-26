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
#include <cutlass/trace.h>
#include <cute/swizzle.hpp>

TEST(CuTe_core, ConstantArithmetic) {
  using namespace cute;

  constexpr cute::integral_constant<uint32_t, 0> uzero{};

  // This extra test exists historically as part of the diagnosis
  // of a possible Clang 14 bug.  However, it's a nice test for
  // cute::integral_constant's arithmetic operators, so it's saved here.
  // It also demonstrates how to work with cute::integral_constant
  // and lambda captures.  Microsoft Visual Studio ("MSVC") tends to
  // disagree with other compilers about the meaning of decltype
  // for variables captured by reference.  MSVC and GCC 8.3.0
  // also tend to disagree with other compilers (and other GCC versions)
  // about whether expressions involving such variables
  // are constant expressions.
  //
  // A typical CuTe idiom is to do lambda captures by reference [&].
  // This test changes them to capture by value, except for
  // the innermost lambda's capture of S1, which is by reference.
  // The point is to show that MSVC and GCC 8 have issues with this
  // that other compilers do not.  For example,
  //
  // 1. MSVC needs remove_cvref_t around decltype(S1)
  //    in order to access decltype(S1)::value, and
  // 2. MSVC and GCC 8.3.0 both report a build error with S1()
  //    (that is, calling operator() on S1, which returns the
  //    same thing as S1.value).
  //
  // The reason for (2) is that neither compiler thinks
  // that S1() is a constant expression.
  //
  // This leaves S1.value as the most concise portable expression
  // for the "value" member of a cute::integral_constant.
  for_each(make_integer_sequence<uint32_t, 8>{}, [uzero](auto S0) {
    for_each(make_integer_sequence<uint32_t, 8>{}, [uzero,S0](auto F0) {
      for_each(make_integer_sequence<uint32_t, 8>{}, [uzero,S0,F0](auto S1) {
        for_each(make_integer_sequence<uint32_t, 8>{}, [uzero,S0,F0,&S1](auto F1) {
          static_assert((decltype(S0)::value & decltype(F0)::value) == decltype(S0 & F0)::value);

          // Using S1.value means you don't have to use remove_cvref_t
          // with a captured-by-reference variable.
          static_assert((cute::remove_cvref_t<decltype(S1)>::value & decltype(F1)::value) == decltype(S1 & F1)::value);
          static_assert((S1.value & decltype(F1)::value) == decltype(S1 & F1)::value);
          // S1() _should_ work, but does not with Visual Studio 2022,
          // which emits C2131 ("expression did not evaluate to a constant").
          // It also does not with GCC 8.3.0, which emits an error with messages
          // "non-constant condition for static assertion" and
          // "'this' is not a constant expression."
          //
          //static_assert((S1() & decltype(F1)::value) == decltype(S1 & F1)::value);
          static_assert(decltype((S0 & F0) != uzero)::value == ((decltype(S0)::value & decltype(F0)::value) != 0));

          static_assert(decltype((S1 & F1) != uzero)::value == ((cute::remove_cvref_t<decltype(S1)>::value & decltype(F1)::value) != 0));
          static_assert(decltype((S1 & F1) != uzero)::value == ((S1.value & decltype(F1)::value) != 0));

          constexpr bool left  = decltype((S0 & F0) != uzero || (S1 & F1) != uzero)::value;
          constexpr bool right =
            ((decltype(S0)::value & decltype(F0)::value) != 0) ||
            ((cute::remove_cvref_t<decltype(S1)>::value & decltype(F1)::value) != 0);
          constexpr bool right2 =
            ((decltype(S0)::value & decltype(F0)::value) != 0) ||
            ((S1.value & decltype(F1)::value) != 0);
          static_assert(right == right2);
          static_assert(left == right);
          constexpr bool left2 = decltype((S0 & F0) != uzero)::value || decltype((S1 & F1) != uzero)::value;
          static_assert(left == left2);
        });
      });
    });
  });
}
