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

#include "cutegen/cutegen_base_dynamic.hpp"
#include "cutegen/rec_var_algorithms.hpp"
#include "gtest/gtest.h"

namespace cg = cutegen;

template <class C, class A, class B>
auto sum(const A& a, const B& b)
{
    return cg::arith_tuple_sum<C>(a, b);
}

////////////////////////////////////////////////////////////////////////
// ArithTupleTest.Sum
TEST(ArithTupleTest, Sum)
{
    using tuple = cg::int_tuple;
    using coord = cg::coord;
    using dyn_t = cg::dynamic_t;
    // tuple + tuple = tuple
    {
        // Simple depth 1
        auto a = tuple(1, 2);
        auto b = tuple(3, 4);
        EXPECT_EQ(sum<tuple>(a, b), tuple(4, 6));
        // Use operator overload (result type inferred from common arg type)
        EXPECT_EQ(a + b, tuple(4, 6));
    }
    {
        // Add new nested mode at the end
        auto a = tuple(1, 2);
        auto b = tuple(0, 0, tuple(3, 4));
        EXPECT_EQ(sum<tuple>(a, b), tuple(1, 2, tuple(3, 4)));
        // Use operator overload (result type inferred from common arg type)
        EXPECT_EQ(a + b, tuple(1, 2, tuple(3, 4)));
    }
    {
        // Add new nested mode in the middle
        auto a = tuple(1, 0, 2);
        auto b = tuple(0, tuple(3, 4), 0);
        EXPECT_EQ(sum<tuple>(a, b), tuple(1, tuple(3, 4), 2));
        EXPECT_EQ(a + b, tuple(1, tuple(3, 4), 2));
    }
    {
        // Extend new mode in the middle
        auto a = tuple(1, tuple(2, 3), 4);
        auto b = tuple(0, tuple(10, 10, 5), 0);
        EXPECT_EQ(sum<tuple>(a, b), tuple(1, tuple(12, 13, 5), 4));
    }
    {
        // Adding an empty tuple (empty vector) is always OK
        auto  a = tuple(1);
        tuple b; // rec_var defaults to the empty vector
        EXPECT_EQ(sum<tuple>(a, b), a);
    }
    {
        // Simple scalar
        auto a = tuple(17);
        // Use operator overload (result type inferred from arg type)
        EXPECT_EQ(a + 11, tuple(28));
        EXPECT_EQ(13 + a, tuple(30));
    }
    // tuple + tuple = coord
    {
        // Simple depth 1
        auto a = tuple(1, 2);
        auto b = tuple(3, 4);
        EXPECT_EQ(sum<coord>(a, b), coord(4, 6));
    }
    // tuple(i32) + tuple(i64) = tuple(i64)
    {
        // Simple depth 1
        auto a = tuple(1, dyn_t{/*width=*/32});
        auto b = tuple(3, dyn_t{/*width=*/64});
        EXPECT_EQ(sum<tuple>(a, b), tuple(4, dyn_t{/*width=*/64}));
    }
    // tuple(i64) + tuple(i64) = tuple(i64)
    {
        // Simple depth 1
        auto a = tuple(1, dyn_t{/*width=*/64});
        auto b = tuple(3, dyn_t{/*width=*/64});
        EXPECT_EQ(sum<tuple>(a, b), tuple(4, dyn_t{/*width=*/64}));
    }
    // tuple(i32) + tuple(i1) = tuple(i32)
    {
        // Simple depth 1
        auto a = tuple(1, dyn_t{/*width=*/32});
        auto b = tuple(3, dyn_t{/*width=*/1});
        EXPECT_EQ(sum<tuple>(a, b), tuple(4, dyn_t{/*width=*/32}));
    }
    // tuple(i8) + tuple(i16) = tuple(i16)
    {
        // Simple depth 1
        auto a = tuple(1, dyn_t{/*width=*/8});
        auto b = tuple(3, dyn_t{/*width=*/16});
        EXPECT_EQ(sum<tuple>(a, b), tuple(4, dyn_t{/*width=*/16}));
    }
    // tuple(i1) + tuple(i1) = tuple(i1)
    {
        // Simple depth 1
        auto a = tuple(1, dyn_t{/*width=*/1});
        auto b = tuple(3, dyn_t{/*width=*/1});
        EXPECT_EQ(sum<tuple>(a, b), tuple(4, dyn_t{/*width=*/1}));
    }
}

TEST(ArithTupleTest, Subtract)
{
    using dyn_t     = cg::dynamic_t;
    using int_tuple = cg::int_tuple;
    // Test scalar subtraction with dynamic value
    {
        auto a      = cg::from_string<int_tuple>("?").value();
        auto b      = cg::from_string<int_tuple>("?").value();
        auto result = cg::arith_tuple_sub<int_tuple>(a, b);
        EXPECT_TRUE(cg::has_dynamic(result));
        EXPECT_EQ(a - b, int_tuple(dyn_t{}));
    }

    // Test tuple subtraction with dynamic values
    {
        auto a      = cg::from_string<int_tuple>("(?,?)").value();
        auto b      = cg::from_string<int_tuple>("(?,?)").value();
        auto result = cg::arith_tuple_sub<int_tuple>(a, b);
        EXPECT_TRUE(cg::has_dynamic(result[0]));
        EXPECT_TRUE(cg::has_dynamic(result[1]));
        EXPECT_EQ(a - b, int_tuple(dyn_t{}, dyn_t{}));
    }

    // Test mixed static/dynamic subtraction
    {
        auto a      = cg::from_string<int_tuple>("(8,?)").value();
        auto b      = cg::from_string<int_tuple>("(2,4)").value();
        auto result = cg::arith_tuple_sub<int_tuple>(a, b);
        EXPECT_EQ(result[0].as_int(), 6);
        EXPECT_TRUE(cg::has_dynamic(result[1]));
        EXPECT_EQ(a - b, int_tuple(6, dyn_t{}));
    }

    // Test scalar subtraction with non-dynamic values
    {
        auto a      = cg::from_string<int_tuple>("10").value();
        auto b      = cg::from_string<int_tuple>("3").value();
        auto result = cg::arith_tuple_sub<int_tuple>(a, b);
        EXPECT_FALSE(cg::has_dynamic(result));
        EXPECT_EQ(result.as_int(), 7);
        EXPECT_EQ(a - b, 7);
    }

    // Test tuple subtraction with non-dynamic values
    {
        auto a      = cg::from_string<int_tuple>("(15,20,25)").value();
        auto b      = cg::from_string<int_tuple>("(5,8,10)").value();
        auto result = cg::arith_tuple_sub<int_tuple>(a, b);
        EXPECT_FALSE(cg::has_dynamic(result[0]));
        EXPECT_FALSE(cg::has_dynamic(result[1]));
        EXPECT_FALSE(cg::has_dynamic(result[2]));
        EXPECT_EQ(result[0].as_int(), 10);
        EXPECT_EQ(result[1].as_int(), 12);
        EXPECT_EQ(result[2].as_int(), 15);
        EXPECT_EQ(a - b, int_tuple(10, 12, 15));
    }

    // Test nested tuple subtraction
    {
        auto a      = cg::from_string<int_tuple>("(1,2,(3,4))").value();
        auto b      = cg::from_string<int_tuple>("(0,1,(1,2))").value();
        auto result = cg::arith_tuple_sub<int_tuple>(a, b);
        EXPECT_EQ(result[0].as_int(), 1);
        EXPECT_EQ(result[1].as_int(), 1);
        auto nested = result[2];
        EXPECT_EQ(nested[0].as_int(), 2);
        EXPECT_EQ(nested[1].as_int(), 2);
        EXPECT_EQ(a - b, int_tuple(1, 1, int_tuple(2, 2)));
    }

    // Test different rank subtraction
    {
        auto a      = cg::from_string<int_tuple>("(1,2,3)").value();
        auto b      = cg::from_string<int_tuple>("(1,2)").value();
        auto result = cg::arith_tuple_sub<int_tuple>(a, b);
        EXPECT_EQ(result[0].as_int(), 0);
        EXPECT_EQ(result[1].as_int(), 0);
        EXPECT_EQ(result[2].as_int(), 3);
        EXPECT_EQ(a - b, int_tuple(0, 0, 3));
    }

    // Test nested tuple with dynamic values
    {
        auto a      = cg::from_string<int_tuple>("(?,(2,?))").value();
        auto b      = cg::from_string<int_tuple>("(?,(1,?))").value();
        auto result = cg::arith_tuple_sub<int_tuple>(a, b);
        EXPECT_TRUE(cg::has_dynamic(result[0]));
        auto nested = result[1];
        EXPECT_EQ(nested[0].as_int(), 1);
        EXPECT_TRUE(cg::has_dynamic(nested[1]));
        EXPECT_EQ(a - b, int_tuple(dyn_t{}, int_tuple(1, dyn_t{})));
    }
}

TEST(ArithTupleTest, Multiply)
{
    using dyn_t     = cg::dynamic_t;
    using int_tuple = cg::int_tuple;
    // Test scalar multiplication with dynamic values
    {
        auto a      = cg::from_string<int_tuple>("?").value();
        auto b      = cg::from_string<int_tuple>("?").value();
        auto result = cg::arith_tuple_mul<int_tuple>(a, b);
        EXPECT_TRUE(cg::has_dynamic(result));
        EXPECT_EQ(a * b, int_tuple{dyn_t{}});
    }

    // Test tuple multiplication with dynamic values
    {
        auto a      = cg::from_string<int_tuple>("(?,?)").value();
        auto b      = cg::from_string<int_tuple>("(?,?)").value();
        auto result = cg::arith_tuple_mul<int_tuple>(a, b);
        EXPECT_TRUE(cg::has_dynamic(result[0]));
        EXPECT_TRUE(cg::has_dynamic(result[1]));
        EXPECT_EQ(a * b, int_tuple(dyn_t{}, dyn_t{}));
    }

    // Test scalar multiplication with non-dynamic values
    {
        auto a      = cg::from_string<int_tuple>("3").value();
        auto b      = cg::from_string<int_tuple>("4").value();
        auto result = cg::arith_tuple_mul<int_tuple>(a, b);
        EXPECT_FALSE(cg::has_dynamic(result));
        EXPECT_EQ(result.as_int(), 12);
        EXPECT_EQ(a * b, 12);
    }

    // Test tuple multiplication with mixed dynamic and non-dynamic values
    {
        auto a      = cg::from_string<int_tuple>("(2,?)").value();
        auto b      = cg::from_string<int_tuple>("(?,5)").value();
        auto result = cg::arith_tuple_mul<int_tuple>(a, b);
        EXPECT_TRUE(cg::has_dynamic(result[0]));
        EXPECT_TRUE(cg::has_dynamic(result[1]));
        EXPECT_EQ(a * b, int_tuple(dyn_t{}, dyn_t{}));
    }
}

TEST(ArithTupleTest, Division)
{
    using dyn_t     = cg::dynamic_t;
    using int_tuple = cg::int_tuple;
    // Test scalar division with dynamic values
    {
        auto a      = cg::from_string<int_tuple>("?").value();
        auto b      = cg::from_string<int_tuple>("?").value();
        auto result = cg::arith_tuple_div<int_tuple>(a, b);
        EXPECT_TRUE(cg::has_dynamic(result));
        EXPECT_EQ(a / b, int_tuple{dyn_t{}});
    }

    // Test tuple division with dynamic values
    {
        auto a      = cg::from_string<int_tuple>("(?,?)").value();
        auto b      = cg::from_string<int_tuple>("(?,?)").value();
        auto result = cg::arith_tuple_div<cg::int_tuple>(a, b);
        EXPECT_TRUE(cg::has_dynamic(result[0]));
        EXPECT_TRUE(cg::has_dynamic(result[1]));
        EXPECT_EQ(a / b, int_tuple(dyn_t(), dyn_t()));
    }

    // Test scalar division with non-dynamic values
    {
        auto a      = cg::from_string<int_tuple>("12").value();
        auto b      = cg::from_string<int_tuple>("3").value();
        auto result = cg::arith_tuple_div<int_tuple>(a, b);
        EXPECT_FALSE(cg::has_dynamic(result));
        EXPECT_EQ(result.as_int(), 4);
        EXPECT_EQ(a / b, 4);
    }

    // Test tuple division with mixed dynamic and non-dynamic values
    {
        auto a      = cg::from_string<int_tuple>("(8,?)").value();
        auto b      = cg::from_string<int_tuple>("(2,5)").value();
        auto result = cg::arith_tuple_div<int_tuple>(a, b);
        EXPECT_FALSE(cg::has_dynamic(result[0]));
        EXPECT_TRUE(cg::has_dynamic(result[1]));
        EXPECT_EQ(result[0].as_int(), 4);
        EXPECT_EQ(a / b, int_tuple(4, dyn_t{}));
    }
}

TEST(ArithTupleTest, Modulo)
{
    // Test scalar modulo with dynamic values
    {
        auto a      = cg::from_string<cg::int_tuple>("?").value();
        auto b      = cg::from_string<cg::int_tuple>("?").value();
        auto result = cg::arith_tuple_mod<cg::int_tuple>(a, b);
        // Result is dynamic when either operand is dynamic.
        EXPECT_TRUE(cg::has_dynamic(result));
    }

    // Test tuple modulo with dynamic values
    {
        auto a      = cg::from_string<cg::int_tuple>("(?,?)").value();
        auto b      = cg::from_string<cg::int_tuple>("(?,?)").value();
        auto result = cg::arith_tuple_mod<cg::int_tuple>(a, b);
        // Each element remains dynamic after modulo.
        EXPECT_TRUE(cg::has_dynamic(result[0]));
        EXPECT_TRUE(cg::has_dynamic(result[1]));
    }

    // Test scalar modulo with non-dynamic values
    {
        auto a      = cg::from_string<cg::int_tuple>("14").value();
        auto b      = cg::from_string<cg::int_tuple>("3").value();
        auto result = cg::arith_tuple_mod<cg::int_tuple>(a, b);
        EXPECT_FALSE(cg::has_dynamic(result));
        EXPECT_EQ(result.as_int(), 2);
    }

    // Test tuple modulo with mixed dynamic and non-dynamic values
    {
        auto a      = cg::from_string<cg::int_tuple>("(8,15)").value();
        auto b      = cg::from_string<cg::int_tuple>("(3,?)").value();
        auto result = cg::arith_tuple_mod<cg::int_tuple>(a, b);
        EXPECT_FALSE(cg::has_dynamic(result[0]));
        EXPECT_TRUE(cg::has_dynamic(result[1]));
        EXPECT_EQ(result[0].as_int(), 2);
    }
}
