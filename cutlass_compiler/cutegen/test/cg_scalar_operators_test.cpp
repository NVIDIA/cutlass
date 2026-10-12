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

#include "cutegen/cg_error.hpp"
#include "cutegen/cutegen.hpp"
#include "cutegen/dynamic.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/rec_var_algorithms.hpp"
#include "cutegen/underscore.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"

#include "utils.hpp"
#include "gtest/gtest.h"

namespace cg = cutegen;

template <class TC, class TA, class TB>
auto mul(const TA& lhs, const TB& rhs)
{
    return cg::transform_leaf([](const TA& lhs, const TB& rhs) //
                              {
                                  return cg::scalar_mul<TC, TA, TB>(lhs, rhs);
                              },
                              lhs,
                              rhs);
}

////////////////////////////////////////////////////////////////////////
// ScalarOperators.Subtract
TEST(ScalarOperators, Subtract)
{
    using rv_t = cg::rec_var<cg::static_int_t, cg::dynamic_t, cg::scaled_basis, cg::cg_error_t>;
    {
        rv_t a(3);
        rv_t b(4);
        EXPECT_EQ(cutegen::scalar_sub<rv_t>(a, b), -1);
    }
    {
        rv_t a(cg::scaled_basis({0, 1}, 1), cg::scaled_basis({1, 1}, 4), cg::scaled_basis({0, 0}, 2));
        rv_t b(cg::scaled_basis({0, 1}, 1), cg::scaled_basis({1, 1}, 2), cg::scaled_basis({1, 0}, 2));
        rv_t exp(cg::scaled_basis({0, 1}, 0), cg::scaled_basis({1, 1}, 2), cg::cg_error_t{});
        EXPECT_EQ(cg::transform_leaf([](const rv_t& a, const rv_t& b) -> rv_t { return cg::scalar_sub<rv_t>(a, b); }, a, b), exp);
    }
}

////////////////////////////////////////////////////////////////////////
// ScalarOperators.Multiply
TEST(ScalarOperators, Multiply)
{
    // tuple * tuple = tuple
    {
        cg::int_tuple t0(1, 2);
        cg::int_tuple t1(4, 5);
        cg::int_tuple t2(cg::int_tuple(6, 7), 8);
        cg::int_tuple t3(cg::int_tuple(1, 0), 10);
        // (1,2) * (4,5) --> (4,10)
        EXPECT_EQ(mul<cg::int_tuple>(t0, t1), cg::int_tuple(4, 10));
        // (1,2) * ((6,7),8) --> error
        EXPECT_TRUE(cg::has_error(mul<cg::int_tuple>(t0, t2)));
        // ((6,7),8) * ((1,0),10) --> ((6,0),80)
        EXPECT_EQ(mul<cg::int_tuple>(t2, t3), cg::int_tuple(cg::int_tuple(6, 0), 80));
    }
    // shape * stride = shape
    {
        cg::shape  t0(1, 2);
        cg::stride t1(4, 5);
        // (1,2) * (4,5) --> (4,10)
        EXPECT_EQ(mul<cg::shape>(t0, t1), cg::shape(4, 10));
    }
    // coord * stride = shape
    {
        cg::coord  t0(1, 2);
        cg::stride t1(4, 5);
        // (1,2) * (4,5) --> (4,10)
        EXPECT_EQ(mul<cg::shape>(t0, t1), cg::shape(4, 10));
    }
    // coord * stride = coord
    {
        cg::coord  t0(1, 2);
        cg::stride t1(4, 5);
        // (1,2) * (4,5) --> (4,10)
        EXPECT_EQ(mul<cg::coord>(t0, t1), cg::coord(4, 10));
    }
}

////////////////////////////////////////////////////////////////////////
// ScalarOperators.Mod

TEST(ScalarOperators, BitwiseNot)
{
    using int_tuple = cg::int_tuple;
    using dyn_t     = cg::dynamic_t;

    EXPECT_EQ(cg::scalar_bitwise_not<int_tuple>(0xFFFFFFFF), 0);
    // Note that the integral overload uses the type of the operand,
    // and not the cutegen static integer type.
    EXPECT_EQ(cg::scalar_bitwise_not<int_tuple>(0xFFFFFFFFL), 0xFFFFFFFF00000000L);
    {
        auto a = cg::scalar_bitwise_not<int_tuple>(int_tuple(dyn_t{}));
        EXPECT_TRUE(cg::holds_dynamic_int(a));
    }
}

TEST(ScalarOperators, LShr)
{
    using int_tuple = cg::int_tuple;
    using dyn_t     = cg::dynamic_t;

    // Shifting by a value larger than the integral type results in an error
    EXPECT_TRUE(cg::holds_error(cg::scalar_lshr<int_tuple>(0xFFFF, 99)));
    EXPECT_TRUE(cg::holds_error(cg::scalar_lshr<int_tuple>(0xFFFF, -99)));
    EXPECT_TRUE(cg::holds_error(cg::scalar_lshr<int_tuple>(1,
                                                           std::numeric_limits<int32_t>::max())));
    EXPECT_TRUE(cg::holds_error(cg::scalar_lshr<int_tuple>(1,
                                                           std::numeric_limits<int32_t>::min())));
    // For 64-bit integers, the shift amount must be less than 64
    EXPECT_FALSE(cg::holds_error(cg::scalar_lshr<int_tuple>(0xFFFFUL, 33)));
    EXPECT_FALSE(cg::holds_error(cg::scalar_lshr<int_tuple>(0xFFFFUL, -33)));
    EXPECT_TRUE(cg::holds_error(cg::scalar_lshr<int_tuple>(0xFFFFUL, 64)));
    EXPECT_TRUE(cg::holds_error(cg::scalar_lshr<int_tuple>(0xFFFFUL, -64)));
    // Shifting an error should result in an error
    EXPECT_TRUE(cg::holds_error(cg::scalar_lshr<int_tuple>(int_tuple(cg::cg_error_t{}), 0)));
    // Shifting a vector should result in an error
    EXPECT_TRUE(cg::holds_error(cg::scalar_lshr<int_tuple>(int_tuple(cg::wrap(4)), 1)));

    // Static shift tests
    {
        auto a = cg::scalar_lshr<int_tuple>(17, 0);
        EXPECT_TRUE(cg::holds_int(a));
        EXPECT_EQ(a.as_int(), 17);
        auto b = cg::scalar_lshr<int_tuple>(8, 3);
        EXPECT_TRUE(cg::holds_int(b));
        EXPECT_EQ(b.as_int(), 1);
        auto c = cg::scalar_lshr<int_tuple>(8, -3);
        EXPECT_TRUE(cg::holds_int(c));
        EXPECT_EQ(c.as_int(), 64);
    }
    // Dynamic shift tests (divisibility)
    {
        auto a_d = cg::scalar_lshr<int_tuple>(dyn_t{}, 2);
        EXPECT_TRUE(cg::holds_dynamic_int(a_d));
        auto b_d = cg::scalar_lshr<int_tuple>(dyn_t{}, 8);
        EXPECT_TRUE(cg::holds_dynamic_int(b_d));
        auto c_d = cg::scalar_lshr<int_tuple>(dyn_t{}, -4);
        EXPECT_TRUE(cg::holds_dynamic_int(c_d));
    }
}

TEST(ScalarOperators, Shl)
{
    using int_tuple = cg::int_tuple;
    using dyn_t     = cg::dynamic_t;

    // Shifting by a value larger than the integral type results in an error
    EXPECT_TRUE(cg::holds_error(cg::scalar_shl<int_tuple>(0xFFFF, 99)));
    EXPECT_TRUE(cg::holds_error(cg::scalar_shl<int_tuple>(0xFFFF, -99)));
    EXPECT_TRUE(cg::holds_error(cg::scalar_shl<int_tuple>(1,
                                                          std::numeric_limits<int32_t>::max())));
    EXPECT_TRUE(cg::holds_error(cg::scalar_shl<int_tuple>(1,
                                                          std::numeric_limits<int32_t>::min())));
    // For 64-bit integers, the shift amount must be less than 64
    EXPECT_FALSE(cg::holds_error(cg::scalar_shl<int_tuple>(0xFFFFUL, 33)));
    EXPECT_FALSE(cg::holds_error(cg::scalar_shl<int_tuple>(0xFFFFUL, -33)));
    EXPECT_TRUE(cg::holds_error(cg::scalar_shl<int_tuple>(0xFFFFUL, 64)));
    EXPECT_TRUE(cg::holds_error(cg::scalar_shl<int_tuple>(0xFFFFUL, -64)));
    // Shifting an error should result in an error
    EXPECT_TRUE(cg::holds_error(cg::scalar_shl<int_tuple>(int_tuple(cg::cg_error_t{}), 0)));
    // Shifting a vector should result in an error
    EXPECT_TRUE(cg::holds_error(cg::scalar_shl<int_tuple>(int_tuple(cg::wrap(4)), 1)));

    // Static shift tests
    {
        auto a = cg::scalar_shl<int_tuple>(17, 0);
        EXPECT_TRUE(cg::holds_int(a));
        EXPECT_EQ(a.as_int(), 17);
        auto b = cg::scalar_shl<int_tuple>(8, 3);
        EXPECT_TRUE(cg::holds_int(b));
        EXPECT_EQ(b.as_int(), 64);
        auto c = cg::scalar_shl<int_tuple>(8, -3);
        EXPECT_TRUE(cg::holds_int(c));
        EXPECT_EQ(c.as_int(), 1);
    }
    // Dynamic shift tests (divisibility)
    {
        auto a_d = cg::scalar_shl<int_tuple>(dyn_t{}, 2);
        EXPECT_TRUE(cg::holds_dynamic_int(a_d));
        auto b_d = cg::scalar_shl<int_tuple>(dyn_t{}, 4);
        EXPECT_TRUE(cg::holds_dynamic_int(b_d));
        auto c_d = cg::scalar_shl<int_tuple>(dyn_t{}, -4);
        EXPECT_TRUE(cg::holds_dynamic_int(c_d));
    }
}

TEST(ScalarOperators, CeilDiv)
{
    using int_tuple = cg::int_tuple;
    using int_t     = cg::static_int_t;
    {
        // ceil_div() with a divisor of 0 should return an error
        // ceil_div(47, 0) --> error
        auto res = cg::scalar_ceil_div<int_tuple>(47, 0);
        EXPECT_TRUE(cg::holds_error(res));
    }
    {
        // ceil_div() with dividend = min() and divisor = -1 overflows, and
        // should return an error
        // ceil_div(INT_MIN, -1) --> error
        auto res = cg::scalar_ceil_div<int_tuple>(std::numeric_limits<int_t>::min(), -1);
        EXPECT_TRUE(cg::holds_error(res));
    }
    // ceil_div(INT_MIN, 1) == INT_MIN
    EXPECT_EQ(cg::scalar_ceil_div<int_tuple>(std::numeric_limits<int_t>::min(), 1),
              std::numeric_limits<int_t>::min());
    // ceil_div(INT_MAX, 1) == INT_MAX
    EXPECT_EQ(cg::scalar_ceil_div<int_tuple>(std::numeric_limits<int_t>::max(), 1),
              std::numeric_limits<int_t>::max());
    EXPECT_EQ(cg::scalar_ceil_div<int_tuple>(7, 2), 4);
    EXPECT_EQ(cg::scalar_ceil_div<int_tuple>(10, 2), 5);
    EXPECT_EQ(cg::scalar_ceil_div<int_tuple>(-10, 2), -5);
    EXPECT_EQ(cg::scalar_ceil_div<int_tuple>(-10, -1), 10);
    EXPECT_EQ(cg::scalar_ceil_div<int_tuple>(10, 3), 4);
    // -10 / 3 = -3 1/3, round towards +inf --> -3
    EXPECT_EQ(cg::scalar_ceil_div<int_tuple>(-10, 3), -3);
    EXPECT_EQ(cg::scalar_ceil_div<int_tuple>(10, -3), -3);
}

TEST(ScalarOperators, CondAssign)
{
    using int_tuple = cg::int_tuple;
    using dyn_t     = cg::dynamic_t;
    using cond_t    = std::variant<bool, cg::dynamic_t>;
    {
        // Test with a condition variable statically known to be true or false
        cond_t c_true  = true;
        cond_t c_false = false;
        auto   resA    = cond_assign(
            c_true,
            []() { return int_tuple(77); },
            []() { return int_tuple(0); });
        EXPECT_EQ(resA, 77);
        auto resB = cond_assign(
            c_false,
            []() { return int_tuple(77); },
            []() { return int_tuple(0); });
        EXPECT_EQ(resB, 0);
    }
    {
        // Test with a dynamic condition variable
        cond_t c{dyn_t{}};
        auto   res = cond_assign(
            c,
            []() { return int_tuple(77); },
            []() { return int_tuple(0); });
        // Result should be dynamic, as the value could be either 77 or 0.
        EXPECT_TRUE(cg::holds_dynamic_int(res));
    }
    {
        // Test with a dynamic condition variable
        cond_t c{dyn_t{}};
        auto   res = cond_assign(
            c,
            []() { return int_tuple(dyn_t{}); },
            []() { return int_tuple(64); });
        // Result should be dynamic
        EXPECT_TRUE(cg::holds_dynamic_int(res));
    }
    {
        // Test with a dynamic condition variable
        cond_t c{dyn_t{}};
        auto   res = cond_assign(
            c,
            []() { return int_tuple(dyn_t{}); },
            []() { return int_tuple(dyn_t{}); });
        // Result should be dynamic
        EXPECT_TRUE(cg::holds_dynamic_int(res));
    }
    {
        // Test with a dynamic condition variable
        cond_t c{dyn_t{}};
        auto   res = cond_assign(
            c,
            []() { return int_tuple(dyn_t{/*width=*/64}); },
            []() { return int_tuple(dyn_t{/*width=*/32}); });
        // Result should be dynamic
        EXPECT_TRUE(cg::holds_dynamic_int(res));
        // Resolving integer width should promote to the largest width
        EXPECT_EQ(cg::get_dynamic_int(res).get_width(), 64);
    }
}
