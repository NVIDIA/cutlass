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

#include <algorithm>
#include <limits>
#include <optional>
#include <stddef.h>
#include <stdexcept>
#include <stdint.h>
#include <string>
#include <type_traits>
#include <utility>
#include <variant>
#include <vector>

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

////////////////////////////////////////////////////////////////////////
// TupleTest.FilterTypesInTuples
TEST(TupleTest, FilterTypesInTuples)
{
    {
        using t0 = std::tuple<>;
        using t1 = typename cg::detail::filter_types_in_tuple<std::is_integral, t0>::type;
        static_assert(std::is_same_v<t0, t1>);
    }
    {
        using t0   = std::tuple<int32_t, int64_t, float, cg::cg_error_t>;
        using tInt = std::tuple<int32_t, int64_t>;
        using t1   = typename cg::detail::filter_types_in_tuple<std::is_integral, t0>::type;
        static_assert(std::is_same_v<tInt, t1>);
    }
    {
        using t0   = std::tuple<int, cg::dynamic_t, cg::underscore_t, cg::cg_error_t>;
        using tDyn = std::tuple<cg::dynamic_t>;
        using t1   = typename cg::detail::filter_types_in_tuple<cg::has_dynamic_t_base, t0>::type;
        static_assert(std::is_same_v<tDyn, t1>);
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Basic
TEST(TupleTest, Basic)
{
    {
        auto t = cg::coord(1, 2, 3);
        auto v = cg::get_vector_elem(t, 1);
        EXPECT_EQ(cg::coord(1, 2, 3), t);
        EXPECT_EQ(2, v.as_int());
    }

    {
        auto t = cg::int_tuple(10, 5);
        auto v = cg::get_vector(t);
        EXPECT_EQ(10, v[0]);
        EXPECT_EQ(5, v[1]);
        EXPECT_EQ(cg::int_tuple(10, 5), t);
    }

    {
        auto t = cg::int_tuple(10);
        auto v = cg::get_int(t);
        EXPECT_EQ(10, v);
        EXPECT_EQ(cg::int_tuple(10), t);
    }

    static_assert(std::is_same_v<cg::rec_var<cg::shape::int_t, cg::dynamic_t, cg::cg_error_t>,
                                 cg::detail::rec_var_from_tuple<cg::shape::elem_types_t>::type>);
    {
        // Local alias to protect against modifications of aliases in cutegen_base_dynamic.hpp
        using shape         = cg::rec_var<int, cg::cg_error_t>;
        const size_t iIndex = cg::detail::find_in_tuple<shape::elem_types_t,
                                                        std::is_integral>::index;
        // Compilation failure expected here: a layout is not a valid
        // type for a shape
        //const size_t lIndex = cg::find_in_tuple<shape::elem_types_t,
        //                                         cg::is_layout>::index;
        const bool bInt = std::is_same_v<std::tuple_element_t<iIndex, shape::elem_types_t>,
                                         int>;
        EXPECT_EQ(iIndex, 0);
        EXPECT_TRUE(bInt);
    }
    // Empty/Non-Empty
    {
        // Local alias to protect against modifications of aliases in cutegen_base_dynamic.hpp
        using tuple = cg::rec_var<int, cg::cg_error_t>;
        tuple tEmpty;
        tuple tNonEmpty(36);
        EXPECT_TRUE(cg::is_empty(tEmpty));
        EXPECT_FALSE(cg::is_empty(tNonEmpty));

        static_assert(cg::is_rec_var_and_can_hold_type<tuple, int>::value,
                      "incorrect variant type check (tuple[int])");
        static_assert(!cg::is_rec_var_and_can_hold_type<tuple, short>::value,
                      "incorrect variant type check (tuple[short])");
        static_assert(cg::is_rec_var_and_convertible_from_type<tuple, short>::value,
                      "incorrect variant type conversion check (tuple[short])");
        static_assert(!cg::is_rec_var_and_can_hold_type<tuple, cg::underscore_t>::value,
                      "incorrect variant type check (tuple[underscore_t])");
        static_assert(cg::is_rec_var_and_can_hold_type<decltype(tEmpty), int>::value,
                      "incorrect variant type check (tuple[int])");
    }
    // Initialization
    {
        // Initialize from integer
        // tFromInt = 36
        cg::int_tuple tFromInt(36);
        EXPECT_EQ("36", cg::to_string(tFromInt));
        EXPECT_TRUE(cg::holds_int(tFromInt));
        EXPECT_TRUE(cg::holds_leaf(tFromInt));
        EXPECT_FALSE(cg::holds_vector(tFromInt));
        // Initialize from vector
        // t_36 = (36)
        cg::int_tuple t_36(std::vector<cg::int_tuple>(1, 36));
        EXPECT_EQ("(36)", cg::to_string(t_36));
        EXPECT_FALSE(cg::holds_int(t_36));
        EXPECT_FALSE(cg::holds_leaf(t_36));
        EXPECT_TRUE(cg::holds_vector(t_36));
        // Nested initialization
        // t4 = (3,7,(4,5,(1,2,(3,4))),9)
        cg::int_tuple t4(3, 7, cg::int_tuple(4, 5, cg::int_tuple(1, 2, cg::int_tuple(3, 4))), 9);
        EXPECT_EQ(cg::to_string(t4), "(3,7,(4,5,(1,2,(3,4))),9)");
        // "Dynamic" initialization
        // t4b = (3,7,(4,5,(1,2,(3,4))),9)
        cg::int_tuple t4b(3);
        t4b.append(7);
        cg::int_tuple t4_inner(1, 2);
        t4_inner.append(cg::int_tuple(3, 4));
        cg::int_tuple t4_outer(4);
        t4_outer.append(5);
        t4_outer.append(t4_inner);
        t4b.append(t4_outer);
        t4b.append(9);
        // Comparison operator
        EXPECT_EQ(t4, t4b);
        EXPECT_NE(t_36, t4);
        EXPECT_EQ(cg::to_string(t4), cg::to_string(t4b));
        // Rank
        EXPECT_EQ(cg::rank(tFromInt), 1);
        EXPECT_EQ(cg::rank(t4), 4);
        // Depth
        EXPECT_EQ(cg::depth(tFromInt), 0); // leaf values have depth 0
        EXPECT_EQ(cg::depth(t_36), 1);
        // t4 = (3,7,                 ,9)    1
        //           (4,5,           )       2
        //                (1,2,     )        3
        //                     (3,4)         4
        EXPECT_EQ(cg::depth(t4), 4);
    }
    // [] operator
    {
        cg::int_tuple tA(0, 1, 2, 3, 4, 5, 6);
        for(size_t i = 0; i < rank(tA); ++i)
        {
            EXPECT_EQ(cg::get_int(tA[i]), i);
        }
        EXPECT_THROW(tA[rank(tA)], std::out_of_range);
        cg::int_tuple tB(13);
        EXPECT_EQ(cg::get_int(tB[0]), 13);
        EXPECT_THROW(tB[1], std::out_of_range);
    }
    // back()
    {
        cg::int_tuple tD(0, 1, 2, 3, 4);
        EXPECT_EQ(tD[rank(tD) - 1], tD.back());
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Transform
TEST(TupleTest, Transform)
{
    // Transform
    {
        auto scalar_mult_fn = [](const cg::int_tuple& lhs, const cg::int_tuple& rhs) //
        {
            return cg::scalar_mul<cg::int_tuple, cg::int_tuple, cg::int_tuple>(lhs, rhs);
        };
        auto scalar_abs_fn = [](const cg::int_tuple& t) //
        {
            return cg::scalar_abs<cg::int_tuple>(t);
        };
        cg::int_tuple t3(3);
        cg::int_tuple t7(7);
        cg::int_tuple t21 = cg::transform_leaf(scalar_mult_fn, t3, t7);
        EXPECT_EQ(cg::get_int(t21), 21);
        cg::int_tuple tNeg(-13);
        EXPECT_EQ(cg::transform_leaf(scalar_abs_fn, tNeg),
                  cg::int_tuple(13));
        {
            cg::int_tuple tA(4, cg::int_tuple(5, 6));
            cg::int_tuple tB(2, cg::int_tuple(3, 4));
            cg::int_tuple tC = cg::transform_leaf(scalar_mult_fn,
                                                  tA,
                                                  tB);
            EXPECT_EQ(tC, cg::int_tuple(8, cg::int_tuple(15, 24)));
        }
        {
            cg::int_tuple tD(-13, cg::int_tuple(-14, -15));
            EXPECT_EQ(cg::transform_leaf(scalar_abs_fn, tD),
                      cg::int_tuple(13, cg::int_tuple(14, 15)));
            EXPECT_EQ(cg::transform_leaf([](const auto& x) { return scalar_abs(x); }, tD),
                      cg::int_tuple(13, cg::int_tuple(14, 15)));
        }
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.ProductSum
TEST(TupleTest, ProductSum)
{
    // Product & Sum
    {
        // t15_7 = (15,7)
        cg::int_tuple t15_7(std::vector<cg::int_tuple>({cg::int_tuple(15), cg::int_tuple(7)}));
        EXPECT_EQ(cg::product(t15_7), 105);
        EXPECT_EQ(cg::sum(t15_7), 22);
        cg::int_tuple t4(3, 7, cg::int_tuple(4, 5, cg::int_tuple(1, 2, cg::int_tuple(3, 4))), 9);
        // clang-format off
        EXPECT_EQ(cg::product(t4), 3 * 7 * 4 * 5 * 1 * 2 * 3 * 4 * 9);
        EXPECT_EQ(cg::sum(t4),     3 + 7 + 4 + 5 + 1 + 2 + 3 + 4 + 9);
        // clang-format on
    }
    // Inner Product
    {
        cg::int_tuple t3(std::vector<cg::int_tuple>({cg::int_tuple(15), cg::int_tuple(7)}));
        cg::int_tuple t3a(16);
        t3a.append(8);
        // (15 * 15) + (7 * 7)
        EXPECT_EQ(cg::inner_product<cg::int_tuple>(t3, t3), (15 * 15) + (7 * 7));
        // (15 * 16) + (7 * 8)
        EXPECT_EQ(cg::inner_product<cg::int_tuple>(t3, t3a), (15 * 16) + (7 * 8));
        cg::int_tuple t8_4(8, 4);
        EXPECT_EQ(cg::inner_product<cg::int_tuple>(t8_4, t8_4), (8 * 8) + (4 * 4));
        cg::int_tuple t8_4_2(8, 4, 2);
        EXPECT_EQ(cg::inner_product<cg::int_tuple>(t8_4_2, t8_4_2), (8 * 8) + (4 * 4) + (2 * 2));
        cg::int_tuple t1_2_8_2(cg::int_tuple(1, 2), 8, 2);
        EXPECT_EQ(cg::inner_product<cg::int_tuple>(t1_2_8_2, t1_2_8_2), (1 * 1) + (2 * 2) + (8 * 8) + (2 * 2));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Abs
TEST(TupleTest, Abs)
{
    {
        cg::stride stride12_3 = cg::from_string<cg::stride>("(1,2,-3)").value();
        cg::stride stride123  = cg::from_string<cg::stride>("(1,2,3)").value();
        EXPECT_EQ(cg::abs(stride12_3), stride123);
    }
    {
        cg::stride stride12_3 = cg::from_string<cg::stride>("((1),(2,-3))").value();
        cg::stride stride123  = cg::from_string<cg::stride>("((1),(2,3))").value();
        EXPECT_EQ(cg::abs(stride12_3), stride123);
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Wrap
TEST(TupleTest, Wrap)
{
    cg::int_tuple t1(3);
    cg::int_tuple t2(std::vector<cg::int_tuple>{{3}});
    cg::int_tuple t3(3, 5);
    EXPECT_EQ(t2, cg::wrap_if_leaf(t1));
    EXPECT_EQ(t2, cg::wrap_if_leaf(t2));
    EXPECT_EQ(t3, cg::wrap_if_leaf(t3));

    cg::int_tuple w(cg::wrap(4));
    EXPECT_EQ(w, cg::from_string<cg::int_tuple>("(4)"));
    EXPECT_EQ(cg::depth(w), 1);

    cg::int_tuple w2(cg::wrap(cg::int_tuple(5)));
    EXPECT_EQ(w2, cg::from_string<cg::int_tuple>("(5)"));
    EXPECT_EQ(cg::depth(w2), 1);

    cg::int_tuple w3(cg::wrap(cg::wrap(6)));
    EXPECT_EQ(w3, cg::from_string<cg::int_tuple>("((6))"));
    EXPECT_EQ(cg::depth(w3), 2);

    cg::int_tuple w4(cg::wrap(cg::wrap(cg::wrap(7))));
    EXPECT_EQ(w4, cg::from_string<cg::int_tuple>("(((7)))"));
    EXPECT_EQ(cg::depth(w4), 3);

    std::vector<cg::int_tuple> v;
    v.push_back(cg::int_tuple{1});
    v.push_back(cg::int_tuple{2});
    v.push_back(cg::int_tuple{3});
    // v = (1,2,3)
    cg::int_tuple w5(cg::wrap(cg::wrap(v)));
    // w5 = (((1,2,3)))
    EXPECT_EQ(w5, cg::from_string<cg::int_tuple>("(((1,2,3)))"));
    EXPECT_EQ(cg::depth(w5), 3);
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Max
TEST(TupleTest, Max)
{
    cg::int_tuple t3(std::vector<cg::int_tuple>({cg::int_tuple(15), cg::int_tuple(7)}));
    cg::int_tuple t4(3, 7, cg::int_tuple(4, 5, cg::int_tuple(1, 2, cg::int_tuple(3, 4))), 9);
    EXPECT_EQ(cg::max(t3), 15);
    EXPECT_EQ(cg::max(t4), 9);
}

////////////////////////////////////////////////////////////////////////
// TupleTest.ColMajor
TEST(TupleTest, ColMajor)
{
    cg::shape t8_4(8, 4);
    cg::shape t8_4_2(8, 4, 2);
    cg::shape t1_2_8_2(cg::shape(1, 2), 8, 2);
    cg::shape t2_3_8_2(cg::shape(2, 3), 8, 2);
    {
        auto cm = cg::compact_col_major<cg::shape, cg::stride>(t8_4);
        EXPECT_EQ(cm, cg::stride(1, 8));
    }
    {
        auto cm = cg::compact_col_major<cg::shape, cg::stride>(t8_4_2);
        EXPECT_EQ(cm, cg::stride(1, 8, 32));
    }
    {
        auto cm = cg::compact_col_major<cg::shape, cg::stride>(t1_2_8_2);
        EXPECT_EQ(cm, cg::stride(cg::stride(0, 1), 2, 16));
    }
    {
        auto cm = cg::compact_col_major<cg::shape, cg::stride>(t2_3_8_2);
        EXPECT_EQ(cm, cg::stride(cg::stride(1, 2), 6, 48));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.RowMajor
TEST(TupleTest, RowMajor)
{
    {
        cg::shape t8_4(8, 4);
        auto      rm = cg::compact_row_major<cg::shape, cg::stride>(t8_4);
        EXPECT_EQ(rm, cg::stride(4, 1));
    }
    {
        cg::shape t8_4_2(8, 4, 2);
        auto      rm = cg::compact_row_major<cg::shape, cg::stride>(t8_4_2);
        EXPECT_EQ(rm, cg::stride(8, 2, 1));
    }
    {
        cg::shape t1_2_8_2(cg::shape(1, 2), 8, 2);
        auto      rm = cg::compact_row_major<cg::shape, cg::stride>(t1_2_8_2);
        EXPECT_EQ(rm, cg::stride(cg::stride(32, 16), 2, 1));
    }
    {
        cg::shape t2_3_8_2(cg::shape(2, 3), 8, 2);
        auto      rm = cg::compact_row_major<cg::shape, cg::stride>(t2_3_8_2);
        EXPECT_EQ(rm, cg::stride(cg::stride(48, 16), 2, 1));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Congruence
TEST(TupleTest, Congruence)
{
    // Congruence
    // t1 = (0)
    cg::int_tuple t1;
    t1.append(0);
    // t2 = 0
    cg::int_tuple t2(0);
    // t2a = 7
    cg::int_tuple t2a(7);
    // t3 = (15,7)
    cg::int_tuple t3(std::vector<cg::int_tuple>({cg::int_tuple(15), cg::int_tuple(7)}));
    // t3a = (16,8)
    cg::int_tuple t3a(16);
    t3a.append(8);
    // t4  = (3,7,(4,5,(1,2,(3,4))),9)
    cg::int_tuple t4(3, 7, cg::int_tuple(4, 5, cg::int_tuple(1, 2, cg::int_tuple(3, 4))), 9);
    // t4a = (3,7,(4,5,(1,2,(3,4))),9)
    cg::int_tuple t4a(3, 7, cg::int_tuple(4, 5, cg::int_tuple(1, 2, cg::int_tuple(3, 4))), 9);
    // t4b = (3,7,(4,5,(1,2,(3,4))),9)
    cg::int_tuple t4b(3);
    t4b.append(7);
    cg::int_tuple t4_inner(1, 2);
    t4_inner.append(cg::int_tuple(3, 4));
    cg::int_tuple t4_outer(4);
    t4_outer.append(5, t4_inner);
    t4b.append(t4_outer, 9);
    EXPECT_TRUE(cg::is_congruent(t1, t1));
    EXPECT_FALSE(cg::is_congruent(t1, t2));
    EXPECT_TRUE(cg::is_congruent(t2, t2a));
    EXPECT_FALSE(cg::is_congruent(t2, t3));
    EXPECT_TRUE(cg::is_congruent(t3, t3a));
    EXPECT_TRUE(cg::is_congruent(t4, t4a));
    EXPECT_TRUE(cg::is_congruent(t4, t4b));
    EXPECT_TRUE(cg::is_congruent(t4a, t4b));
    EXPECT_FALSE(cg::is_congruent(t3, t4));
    EXPECT_TRUE(cg::is_congruent(t4, t4));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.WeakCongruence
TEST(TupleTest, WeakCongruence)
{
    cg::int_tuple a0(1); // 1
    cg::int_tuple b0(2); // 2
    EXPECT_TRUE(cg::weakly_congruent(a0, a0));
    EXPECT_TRUE(cg::weakly_congruent(b0, b0));
    EXPECT_TRUE(cg::weakly_congruent(a0, b0));

    cg::int_tuple a1;
    cg::int_tuple b1;
    a1.append(3); // (3)
    b1.append(4); // (4)
    EXPECT_TRUE(weakly_congruent(a0, a1));
    EXPECT_TRUE(weakly_congruent(b0, b1));
    EXPECT_TRUE(weakly_congruent(a0, b1));
    EXPECT_TRUE(weakly_congruent(b0, a1));
    EXPECT_FALSE(weakly_congruent(a1, a0));
    EXPECT_FALSE(weakly_congruent(b1, b0));
    EXPECT_FALSE(weakly_congruent(a1, b0));
    EXPECT_FALSE(weakly_congruent(b1, a0));
    EXPECT_TRUE(weakly_congruent(a1, a1));
    EXPECT_TRUE(weakly_congruent(b1, b1));
    EXPECT_TRUE(weakly_congruent(a1, b1));

    // (5,6)
    cg::int_tuple a2(5, 6);
    EXPECT_TRUE(weakly_congruent(a0, a2));
    EXPECT_FALSE(weakly_congruent(a1, a2));
    EXPECT_TRUE(weakly_congruent(a2, a2));

    // (7,(8,9))
    auto a3 = cg::int_tuple(7);
    a3.append(cg::int_tuple(8, 9));
    EXPECT_TRUE(weakly_congruent(a0, a3));
    EXPECT_FALSE(weakly_congruent(a1, a3));
    EXPECT_TRUE(weakly_congruent(a2, a3));

    auto b2 = a2;
    EXPECT_TRUE(weakly_congruent(b0, b2));
    EXPECT_FALSE(weakly_congruent(b1, b2));
    EXPECT_TRUE(weakly_congruent(a2, b2));

    auto b3 = a3;
    EXPECT_FALSE(weakly_congruent(a3, b1));
    EXPECT_FALSE(weakly_congruent(a3, a2));
    EXPECT_TRUE(weakly_congruent(a3, b3));

    // ((10,11),(12,13))
    cg::int_tuple b4;
    b4.append(cg::int_tuple(10, 11));
    b4.append(cg::int_tuple(12, 13));
    EXPECT_TRUE(weakly_congruent(a0, b4));
    EXPECT_FALSE(weakly_congruent(a1, b4));
    EXPECT_TRUE(weakly_congruent(a2, b4));
    EXPECT_TRUE(weakly_congruent(a3, b4));

    // (3, 4) and 5
    cg::int_tuple a(3, 4);
    cg::int_tuple b(5);
    EXPECT_FALSE(weakly_congruent(a, b));
    EXPECT_TRUE(weakly_congruent(b, a));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Group
TEST(TupleTest, Group)
{
    // Congruence
    // t2 = 3
    cg::int_tuple t2(3);
    // t3 = (15,7)
    cg::int_tuple t3(15, 7);
    // t4  = (3,7,(4,5,(1,2,(3,4))),9)
    cg::int_tuple t4(3, 7, cg::int_tuple(4, 5, cg::int_tuple(1, 2, cg::int_tuple(3, 4))), 9);
    EXPECT_EQ(cg::from_string<cg::int_tuple>(std::string("(3)")), cg::group(0, 1, t2));
    EXPECT_EQ(cg::from_string<cg::int_tuple>(std::string("((15),7)")), cg::group(0, 1, t3));
    EXPECT_EQ(cg::from_string<cg::int_tuple>(std::string("((15),7)")), cg::group(0, -1, t3));
    EXPECT_EQ(cg::from_string<cg::int_tuple>(std::string("(15,(7))")), cg::group(-1, 2, t3));
    EXPECT_EQ(cg::from_string<cg::int_tuple>(std::string("(3,(7),(4,5,(1,2,(3,4))),9)")), cg::group(1, 2, t4));
    EXPECT_EQ(cg::from_string<cg::int_tuple>(std::string("(3,(7,(4,5,(1,2,(3,4)))),9)")), cg::group(1, 3, t4));
    EXPECT_EQ(cg::int_tuple(cg::cg_error_t{}), cg::group(0, 10, t4));
    EXPECT_EQ(cg::int_tuple(cg::cg_error_t{}), cg::group(-10, 3, t4));
    EXPECT_EQ(cg::int_tuple(cg::cg_error_t{}), cg::group(3, 1, t4));
    EXPECT_EQ(cg::int_tuple(cg::cg_error_t{}), cg::group(1, 1, t4));
    EXPECT_EQ(cg::int_tuple(cg::cg_error_t{}), cg::group(-1, -3, t4));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Take
TEST(TupleTest, Take)
{
    {
        // B >= E returns ()
        auto t   = cg::from_string<cg::int_tuple>(std::string("(2,3,4,5)"));
        auto res = cg::from_string<cg::int_tuple>(std::string("()"));
        ASSERT_TRUE(t.has_value() && res.has_value());
        EXPECT_EQ(cg::take(4, 5, t.value()), res.value());
    }
    {
        // E < 0 gets readjusted to E = rank(t)
        auto t   = cg::from_string<cg::int_tuple>(std::string("(2,3,4,5)"));
        auto res = cg::from_string<cg::int_tuple>(std::string("(4,5)"));
        ASSERT_TRUE(t.has_value() && res.has_value());
        EXPECT_EQ(cg::take(2, -1, t.value()), res.value());
    }
    {
        // Take elements in the middle
        auto t   = cg::from_string<cg::int_tuple>(std::string("(2,3,4,5)"));
        auto res = cg::from_string<cg::int_tuple>(std::string("(3,4)"));
        ASSERT_TRUE(t.has_value() && res.has_value());
        EXPECT_EQ(cg::take(1, 3, t.value()), res.value());
    }
    {
        // A leaf gets wrapped
        auto t   = cg::from_string<cg::int_tuple>(std::string("1"));
        auto res = cg::from_string<cg::int_tuple>(std::string("(1)"));
        ASSERT_TRUE(t.has_value() && res.has_value());
        EXPECT_EQ(cg::take(0, 1, t.value()), res.value());
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Compatibility
TEST(TupleTest, Compatibility)
{
    cg::int_tuple t(36);
    cg::int_tuple t_36(std::vector<cg::int_tuple>(1, 36));
    cg::int_tuple t_1_36(1, 36);
    cg::int_tuple t_2_18(2, 18);
    cg::int_tuple t_3_12(3, 12);
    cg::int_tuple t_4_9(4, 9);
    cg::int_tuple t_6_6(6, 6);
    cg::int_tuple t_9_4(9, 4);
    cg::int_tuple t_12_3(12, 3);
    cg::int_tuple t_18_2(18, 2);
    cg::int_tuple t_36_1(36, 1);
    cg::int_tuple t__1_6__6(cg::int_tuple(1, 6), 6);
    cg::int_tuple t__2_3__6(cg::int_tuple(2, 3), 6);
    cg::int_tuple t__3_2__6(cg::int_tuple(3, 2), 6);
    EXPECT_TRUE(cg::compatible(t, t_36));
    EXPECT_TRUE(cg::compatible(t, t_1_36));
    EXPECT_TRUE(cg::compatible(t, t_2_18));
    EXPECT_TRUE(cg::compatible(t, t_3_12));
    EXPECT_TRUE(cg::compatible(t, t_4_9));
    EXPECT_TRUE(cg::compatible(t, t_6_6));
    EXPECT_TRUE(cg::compatible(t, t_9_4));
    EXPECT_TRUE(cg::compatible(t, t_12_3));
    EXPECT_TRUE(cg::compatible(t, t_18_2));
    EXPECT_TRUE(cg::compatible(t, t_36_1));
    EXPECT_TRUE(cg::compatible(t, t__1_6__6));
    EXPECT_TRUE(cg::compatible(t, t__2_3__6));
    EXPECT_TRUE(cg::compatible(t, t__3_2__6));
    EXPECT_FALSE(cg::compatible(t_36_1, t__1_6__6));
    EXPECT_TRUE(cg::compatible(t_6_6, t__1_6__6));
    EXPECT_TRUE(cg::compatible(t_6_6, t__2_3__6));
    EXPECT_TRUE(cg::compatible(t_6_6, t__3_2__6));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Compatibility
TEST(TupleTest, Cat)
{
    // t0 = ((3,2),6,5,(8,9,10))
    cg::int_tuple t0(cg::int_tuple(3, 2), 6, cg::int_tuple(5, cg::int_tuple(8, 9, 10)));
    // t1 = 8
    cg::int_tuple t1(8);
    EXPECT_EQ(cg::cat_tuple(t1), t1);
    EXPECT_EQ(cg::cat_tuple(t1, t1), cg::int_tuple(8, 8));
    // t2 = ((3,2),6,5,(8,9,10),8)
    auto t2 = cg::cat_tuple(t0, t1);
    EXPECT_EQ(cg::to_string(t2), "((3,2),6,(5,(8,9,10)),8)");
    // t3 = (7, 6)
    cg::int_tuple t3(7, 6);
    // t4 = (5, 4)
    cg::int_tuple t4(5, 4);
    EXPECT_EQ(cg::cat_tuple(t3, t4), cg::int_tuple(7, 6, 5, 4));
    EXPECT_EQ(cg::cat_tuple(t1, t3, t4), cg::int_tuple(8, 7, 6, 5, 4));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.ElemLess
TEST(TupleTest, ElemLess)
{
    cg::int_tuple a(1, 2, 3);
    cg::int_tuple b(2, 3, 4, 5);
    cg::int_tuple c(2, 3);
    cg::int_tuple d(0, 1);
    cg::int_tuple e(3, 4, 5, 6);
    EXPECT_TRUE(cg::elem_less(a, b));
    EXPECT_FALSE(cg::elem_less(b, a));
    EXPECT_FALSE(cg::elem_less(a, c));
    EXPECT_FALSE(cg::elem_less(a, d));
    EXPECT_TRUE(cg::elem_less(d, c));
    EXPECT_TRUE(cg::elem_less(d, a));
    EXPECT_TRUE(cg::elem_less(b, e));
    EXPECT_TRUE(cg::elem_less(cg::int_tuple(11), cg::int_tuple(12)));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.ColexLess
TEST(TupleTest, ColexLess)
{
    {
        cg::int_tuple a(1, 2, 3, 5);
        cg::int_tuple b(2, 3, 4, 5);
        cg::int_tuple c(2, 3);
        cg::int_tuple d(0, 1);
        cg::int_tuple e(3, 4, 5, 6);
        cg::int_tuple f(1, 2, 3, 4);
        cg::int_tuple g(2);
        EXPECT_TRUE(cg::colex_less(a, b));
        EXPECT_FALSE(cg::colex_less(b, a));
        EXPECT_TRUE(cg::colex_less(d, c));
        EXPECT_TRUE(cg::colex_less(b, e));
        EXPECT_TRUE(cg::colex_less(cg::int_tuple(11), cg::int_tuple(12)));
        EXPECT_FALSE(cg::colex_less(a, f));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.LexLess
TEST(TupleTest, LexLess)
{
    cg::int_tuple a(1, 2, 3);
    cg::int_tuple b(2, 3, 4, 5);
    cg::int_tuple c(2, 3);
    cg::int_tuple d(0, 1);
    cg::int_tuple e(3, 4, 5, 6);
    EXPECT_TRUE(cg::lex_less(a, b));
    EXPECT_FALSE(cg::lex_less(b, a));
    EXPECT_TRUE(cg::lex_less(a, c));
    EXPECT_TRUE(cg::lex_less(d, c));
    EXPECT_TRUE(cg::lex_less(d, a));
    EXPECT_TRUE(cg::lex_less(b, e));
    EXPECT_TRUE(cg::lex_less(cg::int_tuple(11), cg::int_tuple(12)));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.HoldsUnderscore
TEST(TupleTest, HoldsUnderscore)
{
    using cg::_;
    // {holds|has}_underscore
    auto a = cg::coord(_, 2);
    EXPECT_TRUE(cg::has_underscore(a));
    EXPECT_FALSE(cg::holds_underscore(a));
    auto b = cg::coord(_);
    EXPECT_TRUE(cg::has_underscore(b));
    EXPECT_TRUE(cg::holds_underscore(b));
    auto c = cg::coord(1, cg::coord(_, 2), 3);
    EXPECT_TRUE(cg::has_underscore(c));
    auto d = cg::coord(1, cg::coord(1, 2), 3);
    EXPECT_FALSE(cg::has_underscore(d));
    auto e = cg::shape{};
    EXPECT_FALSE(cg::holds_underscore(e));
    EXPECT_FALSE(cg::has_underscore(e));
    // is_underscore_only
    EXPECT_FALSE(cg::is_underscore_only(a));
    EXPECT_FALSE(cg::is_underscore_only(e));
    cg::coord f(cg::_, cg::coord(cg::_, cg::_));
    EXPECT_TRUE(cg::is_underscore_only(f));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Slicing
TEST(TupleTest, Slicing)
{
    using cg::_;
    // a = (2,3,4,(5,6))
    auto a = cg::coord(2, 3, 4, cg::coord(5, 6));

    static_assert(cg::is_rec_var_and_can_hold_type<cg::coord, cg::underscore_t>::value,
                  "incorrect variant type check: coord[underscore_t]");

    // a(1) = ()
    EXPECT_EQ(cg::to_string(cg::slice(cg::coord(1), a)), "()");
    // a(_) = ((2,3,4,(5,6)))
    EXPECT_EQ(cg::to_string(cg::slice(cg::coord(_), a)), "(2,3,4,(5,6))");
    // a(_,1,_,_) = (2,4,(5,6))
    EXPECT_EQ(cg::to_string(cg::slice(cg::coord(_, 1, _, _), a)), "(2,4,(5,6))");
    // a(_,1,_,(_,_)) = (2,4,5,6)
    EXPECT_EQ(cg::to_string(cg::slice(cg::coord(_, 1, _, cg::coord(_, _)), a)), "(2,4,5,6)");
    // a(_,1,_,(_,2)) = (2,4,5)
    EXPECT_EQ(cg::to_string(cg::slice(cg::coord(_, 1, _, cg::coord(_, 2)), a)), "(2,4,5)");
    // a(_,1,_,(1,2)) = (2,4)
    EXPECT_EQ(cg::to_string(cg::slice(cg::coord(_, 1, _, cg::coord(1, 2)), a)), "(2,4)");
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Dicing
TEST(TupleTest, Dicing)
{
    using cg::_;
    // a = (2,3,4,(5,6))
    auto a = cg::coord(2, 3, 4, cg::coord(5, 6));
    // a(1) = (2,3,4,(5,6))
    EXPECT_EQ(cg::to_string(cg::dice(cg::coord(1), a)), "(2,3,4,(5,6))");
    // a(_) = ()
    EXPECT_EQ(cg::to_string(cg::dice(cg::coord(_), a)), "()");
    // a(_,1,_,_) = (3)
    EXPECT_EQ(cg::to_string(cg::dice(cg::coord(_, 1, _, _), a)), "(3)");
    // a(_,1,_,(_,_)) = (3)
    EXPECT_EQ(cg::to_string(cg::dice(cg::coord(_, 1, _, cg::coord(_, _)), a)), "(3)");
    // a(_,1,_,(_,2)) = (3,6)
    EXPECT_EQ(cg::to_string(cg::dice(cg::coord(_, 1, _, cg::coord(_, 2)), a)), "(3,6)");
    // a(_,1,_,(1,2)) = (3,5,6)
    EXPECT_EQ(cg::to_string(cg::dice(cg::coord(_, 1, _, cg::coord(1, 2)), a)), "(3,5,6)");

    // b = (((4,8),(2,1)),((2,2,2),(4,2)))
    auto b = cg::coord(cg::coord(cg::coord(4, 8), cg::coord(2, 1)), cg::coord(cg::coord(2, 2, 2), cg::coord(4, 2)));
    // b(1,(1,0),(_,(_,_))) = ((4,8),2,1)
    EXPECT_EQ(cg::to_string(cg::dice(cg::coord(cg::coord(1, cg::coord(1, 0)), cg::coord(_, cg::coord(_, _))), b)), "((4,8),2,1)");
}

////////////////////////////////////////////////////////////////////////
// TupleTest.FilterZeros
TEST(TupleTest, FilterZeros)
{
    cg::int_tuple a(1, 0, 1);
    cg::int_tuple b(3, 3, 3);
    cg::int_tuple c = filter_zeros(a, b);
    EXPECT_EQ(c, cg::int_tuple(3, 1, 3));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Flatten
TEST(TupleTest, Flatten)
{
    using int_tuple = cg::int_tuple;
    // Flatten
    {
        // clang-format off
        // tA = (3, 4, (5, (6, 7, (8, 9))), 10)
        int_tuple tA(3, 4, int_tuple(5,
                                     int_tuple(6, 7, int_tuple(8,9))),
                     10);
        // clang-format on
        EXPECT_EQ(flatten(tA), int_tuple(3, 4, 5, 6, 7, 8, 9, 10));
        // tB = 3
        int_tuple tB(3);
        EXPECT_EQ(flatten(tB), int_tuple(3));
        // tC = ((9, 8), (7, 6, 5))
        int_tuple tC(int_tuple(9, 8), int_tuple(7, 6, 5));
        EXPECT_EQ(flatten(tC), int_tuple(9, 8, 7, 6, 5));
    }
    // Flatten Into
    {
        int_tuple tfDst(0, 1, 2);
        // tfSrc = (3, 4, (5, (6, 7, (8, 9))), 10)
        int_tuple tfSrc(3, 4, int_tuple(5, int_tuple(6, 7, cg::int_tuple(8, 9))), 10);
        cg::flatten_into(tfSrc, tfDst);
        EXPECT_EQ(tfDst, int_tuple(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
    }
    // Flatten Into
    {
        int_tuple tfDst(0, 1, 2);
        // tfSrc = ()
        int_tuple tfSrc;
        cg::flatten_into(tfSrc, tfDst);
        EXPECT_EQ(tfDst, int_tuple(0, 1, 2));
    }
    // Flatten Into
    {
        // Test with a non-vector destination
        int_tuple tfDst(0);
        // tfSrc = 4
        int_tuple tfSrc(4);
        cg::flatten_into(tfSrc, tfDst);
        EXPECT_EQ(tfDst, int_tuple(0, 4));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Prepend
TEST(TupleTest, Prepend)
{
    // Prepend
    {
        // tB = 3
        cg::int_tuple tB(3);
        EXPECT_EQ(cg::prepend(cg::int_tuple(2), tB), cg::int_tuple(2, 3));
        cg::int_tuple tC(cg::int_tuple(6, 7), 8);
        EXPECT_EQ(cg::prepend(cg::int_tuple(5), tC),
                  cg::int_tuple(5, cg::int_tuple(6, 7), 8));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Resize
TEST(TupleTest, Resize)
{
    using cg::_;
    // Resize
    // Tuple with different size.
    {
        // Resize to larger
        cg::int_tuple tA(3);
        EXPECT_EQ(cg::append_to_rank_N(5, tA, 0), cg::int_tuple(3, 0, 0, 0, 0));
        // Resize to same
        cg::int_tuple tB(3, 4, 5, 6, 7);
        EXPECT_EQ(cg::append_to_rank_N(5, tB, 0), cg::int_tuple(3, 4, 5, 6, 7));
        // Resize to smaller
        cg::int_tuple tC(3, 4, 5, 6, 7);
        EXPECT_EQ(cg::append_to_rank_N(4, tC, 0), cg::int_tuple(3, 4, 5, 6, 7));
    }
    // Coord with different size.
    {
        // Resize to larger
        cg::coord tA(3);
        EXPECT_EQ(cg::append_to_rank_N(5, tA, cg::_), cg::coord(3, _, _, _, _));
        // Resize to larger
        cg::coord tB(3, _, 5, 6);
        EXPECT_EQ(cg::append_to_rank_N(5, tB, -1), cg::coord(3, _, 5, 6, -1));
        // Resize from empty
        cg::coord tC;
        EXPECT_EQ(cg::append_to_rank_N(4, tC, 1), cg::coord(1, 1, 1, 1));
    }
    // Stride with sb.
    {
        using sb = cg::scaled_basis;
        cg::stride tA(3, 1, sb(5, 4), sb(0, 1));
        EXPECT_EQ(cg::append_to_rank_N(5, tA, sb(2, 3)), cg::stride(3, 1, sb(5, 4), sb(0, 1), sb(2, 3)));
    }

    // Resize
    // Tuple with different size.
    {
        // Resize to larger
        cg::int_tuple tA(3);
        EXPECT_EQ(cg::prepend_to_rank_N(5, tA, 0), cg::int_tuple(0, 0, 0, 0, 3));

        // Resize to same
        cg::int_tuple tB(3, 4, 5, 6, 7);
        EXPECT_EQ(cg::prepend_to_rank_N(5, tB, 0), cg::int_tuple(3, 4, 5, 6, 7));
        // Resize to smaller
        cg::int_tuple tC(3, 4, 5, 6, 7);
        EXPECT_EQ(cg::prepend_to_rank_N(4, tC, 0), cg::int_tuple(3, 4, 5, 6, 7));

        // Prepend tuple
        cg::int_tuple tD(3);
        EXPECT_EQ(cg::prepend_to_rank_N(3, tA, cg::int_tuple(2, 3)), cg::int_tuple(cg::int_tuple(2, 3), cg::int_tuple(2, 3), 3));
    }
    // Coord with different size.
    {
        // Resize to larger
        cg::coord tA(3);
        EXPECT_EQ(cg::prepend_to_rank_N(5, tA, cg::_), cg::coord(_, _, _, _, 3));
        // Resize to larger
        cg::coord tB(3, _, 5, 6);
        EXPECT_EQ(cg::prepend_to_rank_N(5, tB, -1), cg::coord(-1, 3, _, 5, 6));
        // Resize from empty
        cg::coord tC;
        EXPECT_EQ(cg::prepend_to_rank_N(4, tC, 1), cg::coord(1, 1, 1, 1));
    }
    // Stride with sb.
    {
        using sb = cg::scaled_basis;
        cg::stride tA(3, 1, sb(5, 4), sb(0, 1));
        EXPECT_EQ(cg::prepend_to_rank_N(5, tA, sb(2, 3)), cg::stride(sb(2, 3), 3, 1, sb(5, 4), sb(0, 1)));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.ReplaceFront
TEST(TupleTest, ReplaceFront)
{
    // ReplaceFront
    {
        // 2 --> 3
        cg::int_tuple tB(3);
        EXPECT_EQ(cg::replace_front(cg::int_tuple(2), tB), cg::int_tuple(3));
        // ((6,7),8) --> (7,8)
        cg::int_tuple tC(cg::int_tuple(6, 7), 8);
        EXPECT_EQ(cg::replace_front(tC, cg::int_tuple(7)),
                  cg::int_tuple(7, 8));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Iterator
TEST(TupleTest, Iterator)
{
    {
        // Tuple with vector of integers
        cg::int_tuple tA(0, 1, 2, 3, 4, 5);
        auto          it = tA.begin();
        EXPECT_EQ(cg::get_int(*it), 0);
        ++it;
        EXPECT_EQ(cg::get_int(*it), 1);
        it++;
        EXPECT_EQ(cg::get_int(*it), 2);
        ++it;
        EXPECT_EQ(cg::get_int(*it), 3);
        it++;
        EXPECT_EQ(cg::get_int(*it), 4);
        it++;
        EXPECT_EQ(cg::get_int(*it), 5);
        EXPECT_EQ(++it, tA.end());
    }
    {
        // Tuple with integer value
        cg::int_tuple tB(6);
        auto          it = tB.cbegin();
        EXPECT_EQ(cg::get_int(*it), 6);
        EXPECT_EQ(it, --tB.cend());
        EXPECT_EQ(++it, tB.cend());
    }
    {
        // Empty tuple
        cg::int_tuple tC;
        EXPECT_EQ(tC.begin(), tC.end());
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Zip
TEST(TupleTest, Zip)
{
    {
        // When mode 0 is a leaf, the entire thing is wrapped once
        auto t   = *cg::from_string<cg::int_tuple>("(1,(2,3))");
        auto res = *cg::from_string<cg::int_tuple>("((1,(2,3)))");
        EXPECT_EQ(cg::zip(t), res);
    }
    {
        cg::int_tuple tA(cg::int_tuple(1, 3, 5, 7), cg::int_tuple(2, 4, 6, 8));
        cg::int_tuple tB = zip(tA);
        EXPECT_EQ(tB,
                  cg::int_tuple(cg::int_tuple(1, 2),
                                cg::int_tuple(3, 4),
                                cg::int_tuple(5, 6),
                                cg::int_tuple(7, 8)));
    }
    {
        cg::int_tuple tC = zip(cg::int_tuple(1, 4, 7),
                               cg::int_tuple(2, 5, 8),
                               cg::int_tuple(3, 6, 9));
        EXPECT_EQ(tC,
                  cg::int_tuple(cg::int_tuple(1, 2, 3),
                                cg::int_tuple(4, 5, 6),
                                cg::int_tuple(7, 8, 9)));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Reverse
TEST(TupleTest, Reverse)
{
    {
        cg::int_tuple tA(cg::int_tuple(1, 3), 4);
        cg::int_tuple tB = reverse(tA);
        EXPECT_EQ(tB, cg::int_tuple(4, cg::int_tuple(1, 3)));
    }
    {
        cg::int_tuple tA(5);
        cg::int_tuple tB = reverse(tA);
        EXPECT_EQ(tB, cg::int_tuple(5));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.CeilDiv
TEST(TupleTest, CeilDiv)
{
    {
        cg::int_tuple tA(1, 11, 21, 31);
        cg::int_tuple tB(10, 10, 10, 10);
        cg::int_tuple tC = cg::ceil_div(tA, tB);
        EXPECT_EQ(tC, cg::int_tuple(1, 2, 3, 4));
    }
    {
        cg::int_tuple tE(5);
        cg::int_tuple tF(3);
        cg::int_tuple tG = cg::ceil_div(tE, tF);
        EXPECT_EQ(tG, cg::int_tuple(2));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.ScalarScale
TEST(TupleTest, ScalarScale)
{
    EXPECT_EQ(cg::scalar_scale(cg::int_tuple(1, 2), cg::int_tuple(12, 12)),
              cg::int_tuple(12, 24));
    EXPECT_EQ(cg::scalar_scale(cg::int_tuple(2), cg::int_tuple(12, 12)),
              cg::int_tuple(288));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.ShapeDiv
TEST(TupleTest, ShapeDiv)
{
    EXPECT_EQ(cg::shape_div(cg::int_tuple(1), cg::int_tuple(8)),
              cg::int_tuple(1));

    EXPECT_EQ(cg::shape_div(cg::int_tuple(8), cg::int_tuple(4)),
              cg::int_tuple(2));

    // shape_div((3, 4), 6) = (1, 2)
    EXPECT_EQ(cg::shape_div(cg::int_tuple(3, 4), cg::int_tuple(6)),
              cg::int_tuple(1, 2));
    // shape_div((3, 4), 12) = (1, 1)
    EXPECT_EQ(cg::shape_div(cg::int_tuple(3, 4), cg::int_tuple(12)),
              cg::int_tuple(1, 1));
    // shape_div((3, 4), 36) = (1, 1)
    EXPECT_EQ(cg::shape_div(cg::int_tuple(3, 4), cg::int_tuple(36)),
              cg::int_tuple(1, 1));
    // shape_div(((3, 4), 6), 36) = ((1, 1), 2)
    EXPECT_EQ(cg::shape_div(cg::int_tuple(cg::int_tuple(3, 4), 6), cg::int_tuple(36)),
              cg::int_tuple(cg::int_tuple(1, 1), 2));
    // shape_div((6, (3, 4)), 36) = (1, 2)
    EXPECT_EQ(cg::shape_div(cg::int_tuple(6, cg::int_tuple(3, 4)), cg::int_tuple(36)),
              cg::int_tuple(1, cg::int_tuple(1, 2)));
    // shape_div((64, 64), (16, 16)) = (4, 4)
    EXPECT_EQ(cg::shape_div(cg::int_tuple(64, 64), cg::int_tuple(16, 16)),
              cg::int_tuple(4, 4));
    // shape_div((64, 64), (8, 32)) = (8, 2)
    EXPECT_EQ(cg::shape_div(cg::int_tuple(64, 64), cg::int_tuple(8, 32)),
              cg::int_tuple(8, 2));
    // shape_div((_64,_64), (_128,_128)) = (1, 1)
    EXPECT_EQ(cg::shape_div(cg::int_tuple(64, 64), cg::int_tuple(128, 128)),
              cg::int_tuple(1, 1));
    // shape_div((_64,_64), 16) = (4, 64)
    EXPECT_EQ(cg::shape_div(cg::int_tuple(64, 64), cg::int_tuple(16)),
              cg::int_tuple(4, 64));
    // shape_div((_64,_64), 128) = (1, 32)
    EXPECT_EQ(cg::shape_div(cg::int_tuple(64, 64), cg::int_tuple(128)),
              cg::int_tuple(1, 32));
    // shape_div((_64,_64), 4096) = (1, 1)
    EXPECT_EQ(cg::shape_div(cg::int_tuple(64, 64), cg::int_tuple(4096)),
              cg::int_tuple(1, 1));
    // shape_div((_64,_64), 8192) = (1, 1)
    EXPECT_EQ(cg::shape_div(cg::int_tuple(64, 64), cg::int_tuple(8192)),
              cg::int_tuple(1, 1));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.FromString
TEST(TupleTest, FromString)
{
    EXPECT_EQ(cg::int_tuple(8, 4), cg::from_string<cg::int_tuple>(std::string("(8, 4)")));
    EXPECT_EQ(cg::int_tuple(7), cg::from_string<cg::int_tuple>(std::string("7")));
    EXPECT_EQ(cg::int_tuple(), cg::from_string<cg::int_tuple>(std::string("()")));
    // Calling cg::int_tuple(cg::int_tuple(7)) just invokes the copy constructor.
    // We can explicitly use a vector to nest a tuple...
    EXPECT_EQ(cg::int_tuple(std::vector<cg::int_tuple>(1, 7)),
              cg::from_string<cg::int_tuple>(std::string("(7)")));
    EXPECT_EQ(cg::int_tuple(cg::int_tuple(1, 2), 3),
              cg::from_string<cg::int_tuple>(std::string("((1, 2),        3)")));
    EXPECT_EQ(cg::int_tuple(cg::int_tuple(1, 2), cg::int_tuple(3, 4, 5)),
              cg::from_string<cg::int_tuple>(std::string("((1, 2), (3, 4, 5)) ")));
    EXPECT_EQ(cg::int_tuple(cg::int_tuple(1, 2), cg::int_tuple(3, cg::int_tuple(4, 5))),
              cg::from_string<cg::int_tuple>(std::string("((1, 2), (3, (4, 5)))")));
    EXPECT_EQ(cg::int_tuple(cg::int_tuple(1, 2), cg::int_tuple(3, cg::int_tuple(4, 5), 6)),
              cg::from_string<cg::int_tuple>(std::string("((1, 2), (3, (4, 5), 6))  ")));
    EXPECT_EQ(cg::int_tuple(cg::int_tuple(1, 2), cg::int_tuple(3, cg::int_tuple(4, 5), 6, cg::int_tuple(7, 8))),
              cg::from_string<cg::int_tuple>(std::string("((1, 2), (3, (4, 5), 6, (7, 8)))")));
    EXPECT_EQ(cg::int_tuple(cg::int_tuple(1, 2), cg::int_tuple(3, cg::int_tuple(4, 5), 6, cg::int_tuple(7, cg::int_tuple(8, 9)))),
              cg::from_string<cg::int_tuple>(std::string("((1, 2), (3, (4, 5  ), 6, (7, (8, 9)) )  )")));
    EXPECT_EQ(cg::int_tuple(cg::int_tuple(1001, 1002), cg::int_tuple(1003, cg::int_tuple(1004, 1005), 1006, cg::int_tuple(1007, cg::int_tuple(1008, cg::int_tuple(1009, 1010))))),
              cg::from_string<cg::int_tuple>(std::string("((1001, 1002), (1003, (1004, 1005), 1006, (1007, (1008, (1009, 1010)))))")));

    // Coordinate from string (with and without underscore)
    EXPECT_EQ(cg::coord(8, 4), cg::from_string<cg::coord>(std::string("(8, 4)")));
    EXPECT_EQ(cg::coord(cg::_), cg::from_string<cg::coord>(std::string("_")));
    EXPECT_EQ(cg::coord(cg::_), cg::from_string<cg::coord>(std::string("  _   ")));
    EXPECT_EQ(cg::coord(std::vector<cg::coord>(1, cg::_)),
              cg::from_string<cg::coord>(std::string("(_)")));
    EXPECT_EQ(cg::coord(8, cg::_, 4), cg::from_string<cg::coord>(std::string("(8, _, 4)")));
    // Invalid strings
    EXPECT_FALSE(cg::from_string<cg::int_tuple>(std::string("(")));
    EXPECT_FALSE(cg::from_string<cg::int_tuple>(std::string("(3")));
    EXPECT_FALSE(cg::from_string<cg::int_tuple>(std::string("(4, 8))")));
    EXPECT_FALSE(cg::from_string<cg::int_tuple>(std::string("(4), 8))")));
    EXPECT_FALSE(cg::from_string<cg::int_tuple>(std::string("(4)8")));
    EXPECT_FALSE(cg::from_string<cg::int_tuple>(std::string("(4, )8")));
    EXPECT_FALSE(cg::from_string<cg::int_tuple>(std::string("(4, ,8)")));
    EXPECT_FALSE(cg::from_string<cg::int_tuple>(std::string("(4, b)")));
    EXPECT_FALSE(cg::from_string<cg::int_tuple>(std::string("(4x, b)")));
    EXPECT_FALSE(cg::from_string<cg::int_tuple>(std::string("(4, (,), 8))")));
    EXPECT_FALSE(cg::from_string<cg::coord>(std::string("(8,_4)")));
    {
        using tuple = cg::rec_var<int>;
        EXPECT_FALSE(cg::from_string<tuple>(std::to_string(static_cast<int64_t>(std::numeric_limits<int>::max()) + 1)));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Codec
TEST(TupleTest, Codec)
{
    // Verify that the encode/decode round trip returns the same as the
    // input.
    EXPECT_TRUE(test_codec(cg::shape(3, 4, 5)));
    EXPECT_TRUE(test_codec(cg::coord(3, 4, cg::coord(5, 6, cg::coord(7, 8), cg::_), 10)));
    EXPECT_TRUE(test_codec(cg::int_tuple(cg::int_tuple(1, 2), cg::int_tuple(3, cg::int_tuple(4, 5), 6, cg::int_tuple(7, cg::int_tuple(8, 9))))));
    // Verify failure on invalid buffers
    {
        std::vector<char> buffer;
        cg::encode(buffer, cg::shape(3, 4, 5));
        buffer.resize(buffer.size() - 8);
        auto dec = cg::decode<cg::shape>(buffer);
        EXPECT_FALSE(dec.has_value());
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.LeafPos
TEST(TupleTest, LeafPos)
{
    cg::int_tuple tEmpty;
    cg::int_tuple tNonEmpty(36);
    EXPECT_EQ(0, cg::leaf_count(tEmpty));
    EXPECT_EQ(1, cg::leaf_count(tNonEmpty));

    cg::int_tuple tFromInt(36);
    EXPECT_TRUE(cg::holds_leaf(cg::leaf_at_fpos(tFromInt, 0)));
    EXPECT_EQ(cg::leaf_at_fpos(tFromInt, 0).as_int(), 36);

    cg::int_tuple t4(3, 7, cg::int_tuple(4, 5, cg::int_tuple(1, 2, cg::int_tuple(3, 4))), 9);
    EXPECT_EQ(cg::leaf_at_fpos(t4, 0).as_int(), 3);
    EXPECT_EQ(cg::leaf_at_fpos(t4, 1).as_int(), 7);
    EXPECT_EQ(cg::leaf_at_fpos(t4, 2).as_int(), 4);
    EXPECT_EQ(cg::leaf_at_fpos(t4, 3).as_int(), 5);
    EXPECT_EQ(cg::leaf_at_fpos(t4, 4).as_int(), 1);
    EXPECT_EQ(cg::leaf_at_fpos(t4, 5).as_int(), 2);
    EXPECT_EQ(cg::leaf_at_fpos(t4, 6).as_int(), 3);
    EXPECT_EQ(cg::leaf_at_fpos(t4, 7).as_int(), 4);
    EXPECT_EQ(cg::leaf_at_fpos(t4, 8).as_int(), 9);
    EXPECT_EQ(9, cg::leaf_count(t4));

    // Assign an element value using a scalar flattened position
    cg::leaf_at_fpos(t4, 8) = 77;
    EXPECT_EQ(cg::to_string(t4), "(3,7,(4,5,(1,2,(3,4))),77)");

    cg::int_tuple tA(0, 1, 2, 3, 4, 5, 6);
    EXPECT_EQ(7, cg::leaf_count(tA));

    cg::coord crd(cg::_, 2);
    EXPECT_TRUE(cg::has_underscore(crd));
    EXPECT_EQ(2, cg::leaf_count(crd));
    EXPECT_EQ(1,
              cg::leaf_count_if(crd,
                                [](auto& e) //
                                {
                                    return std::holds_alternative<cg::underscore_t>(e);
                                }));
    EXPECT_EQ(0,
              cg::leaf_count_if(crd,
                                [](auto& e) //
                                {
                                    return std::holds_alternative<cg::coord::vector_t>(e);
                                }));
}

// TupleTest.RepeatLike
TEST(TupleTest, RepeatLike)
{
    auto a = cg::int_tuple(cg::int_tuple(1, 2), 3, cg::int_tuple(4, cg::int_tuple(5, 6)));
    auto b = cg::repeat_like<cg::int_tuple>(a, cg::int_tuple::int_t(10));
    // With a different return type
    auto c = cg::repeat_like<cg::stride>(a, cg::int_tuple::int_t(10));
    EXPECT_EQ(b,
              cg::int_tuple(cg::int_tuple(10, 10), 10, cg::int_tuple(10, cg::int_tuple(10, 10))));
    EXPECT_EQ(c,
              cg::stride(cg::stride(10, 10), 10, cg::stride(10, cg::stride(10, 10))));
}

// TupleTest.Dynamic
TEST(TupleTest, Dynamic)
{
    using test_rv_t = cg::rec_var<int>;
    // Verify that the template does not detect a variant type derived
    // from dynamic_t:
    static_assert(!cg::rec_var_has_dynamic_type<test_rv_t>::value);
    // Verify that we can call holds_dynamic_int(), even for a type that does not
    // have the ability to hold a dynamic type.
    // (holds_dynamic_int() for recursive variants without a dynamic type should
    // trivially return false.
    test_rv_t a;
    EXPECT_FALSE(cg::holds_dynamic_int(a));
    // Verify that the template detects the variant type derived from dynamic_t.
    using test_rv_dyn_t = cg::rec_var<cg::static_int_t, cg::dynamic_t>;
    static_assert(cg::rec_var_has_dynamic_type<test_rv_dyn_t>::value);

    using test_tuple = cg::rec_var<cg::static_int_t, cg::dynamic_t, cg::cg_error_t>;
    using test_shape = cg::rec_var<cg::static_int_t, cg::dynamic_t, cg::cg_error_t>;
    using test_coord = cg::rec_var<cg::static_int_t, cg::dynamic_t, cg::underscore_t>;

    test_shape s_static(3, 4, 5);
    EXPECT_TRUE(is_static(s_static));
    EXPECT_FALSE(has_dynamic(s_static));

    test_shape s_dynamic(3, test_shape(4, 5, cg::dyn), 7);
    EXPECT_FALSE(is_static(s_dynamic));
    EXPECT_TRUE(has_dynamic(s_dynamic));
    EXPECT_EQ("(3,(4,5,?),7)", cg::to_string(s_dynamic));

    EXPECT_EQ(cg::depth(test_tuple(cg::dyn)), 0);

    // Dynamic strings
    EXPECT_EQ(test_coord(8, cg::dyn), cg::from_string<test_coord>(std::string("(8,?)")));
    EXPECT_EQ(test_coord(cg::dyn), cg::from_string<test_coord>(std::string("?")));
    EXPECT_EQ(test_coord(std::vector<test_coord>(1, cg::dyn)),
              cg::from_string<test_coord>(std::string("(?)")));
    EXPECT_EQ(test_coord(8, cg::dyn, 4), cg::from_string<test_coord>(std::string("(8, ?, 4)")));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.IsIntegralOnly
TEST(TupleTest, IsIntegralOnly)
{
    cg::int_tuple t0{1, 2, 4};
    EXPECT_TRUE(cg::is_static(t0));
    EXPECT_TRUE(cg::is_integral_only(t0));

    cg::int_tuple t1(cg::cg_error_t{}, 1);
    EXPECT_TRUE(cg::is_static(t1));
    EXPECT_FALSE(cg::is_integral_only(t1));
    EXPECT_TRUE(cg::has_error(t1));

    cg::coord t3{1, 2, cg::_};
    EXPECT_TRUE(cg::is_static(t3));
    EXPECT_FALSE(cg::is_integral_only(t3));

    cg::stride t4{cg::scaled_basis{1, 1}};
    EXPECT_TRUE(cg::is_static(t4));
    EXPECT_FALSE(cg::is_integral_only(t4));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.ScalarOps
TEST(TupleTest, ScalarOps)
{
    {
        using int_tuple = cg::int_tuple;
        // clang-format off
        int_tuple a(0b10101);
        int_tuple b( 0b1011);
        // clang-format on
        int_tuple c0 = cg::scalar_bitwise_and<int_tuple>(a, b);
        int_tuple c1 = cg::scalar_bitwise_or<int_tuple>(a, b);
        int_tuple c2 = cg::scalar_bitwise_xor<int_tuple>(a, b);
        EXPECT_EQ(c0, a.as_int() & b.as_int());
        EXPECT_EQ(c1, a.as_int() | b.as_int());
        EXPECT_EQ(c2, a.as_int() ^ b.as_int());
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.CastRecVar
TEST(TupleTest, CastRecVar)
{
    {
        using tuple_t  = cg::int_tuple;
        using shape_t  = cg::shape;
        using stride_t = cg::stride;
        using coord_t  = cg::coord;
        using sb_t     = cg::scaled_basis;
        tuple_t t0(1, tuple_t(2, 3, tuple_t(4, 5, 6)), 7);
        coord_t c0(1, cg::_, coord_t(2, 3));
        // shape_t  s0(t0); // (Note: shape and tuple are actually the same type.)
        stride_t d0(3, 1, sb_t(5, 4), sb_t(0, 1));
        //std::cout << "t0    = " << t0 << std::endl;
        //std::cout << "c0    = " << c0 << std::endl;
        //std::cout << "s0    = " << s0 << std::endl;
        //std::cout << "d0    = " << d0 << std::endl;
        auto s0_t0 = cg::rec_var_cast<shape_t>(t0);  // shape from tuple
        auto d0_t0 = cg::rec_var_cast<stride_t>(t0); // stride from tuple
        auto s0_c0 = cg::rec_var_cast<shape_t>(c0);  // shape from coord
        auto c0_d0 = cg::rec_var_cast<coord_t>(d0);  // coord from stride
        //std::cout << "s0_t0 = " << s0_t0 << std::endl;
        //std::cout << "d0_t0 = " << d0_t0 << std::endl;
        //std::cout << "s0_c0 = " << s0_c0 << std::endl;
        //std::cout << "c0_d0 = " << c0_d0 << std::endl;
        // EXPECT_EQ(t0, s0);
        // EXPECT_EQ(s0_t0, t0); // Types are identical - use operator==()
        EXPECT_EQ(d0_t0,
                  stride_t(1, stride_t(2, 3, stride_t(4, 5, 6)), 7));
        // Replace underscore with cg_error_t
        EXPECT_EQ(s0_c0,
                  shape_t(1, cg::cg_error_t{}, shape_t(2, 3)));
        // Replace scaled basis with cg_error_t
        EXPECT_EQ(c0_d0,
                  coord_t(3, 1, cg::cg_error_t{}, cg::cg_error_t{}));
    }
}

using visit_tuple = cg::rec_var<int>;

struct visitor_test
{
    void operator()(int i) { sum += i; }
    void operator()(const visit_tuple::vector_t& v)
    {
        for(auto& e : v)
        {
            cg::visit(*this, e);
        }
    }
    int sum = 0;
};

////////////////////////////////////////////////////////////////////////
// TupleTest.VisitVariant
TEST(TupleTest, VisitVariant)
{
    visit_tuple  v(1, 2, visit_tuple(3, 4, 5));
    visitor_test vtest;
    cg::visit(vtest, v);
    EXPECT_EQ(1 + 2 + 3 + 4 + 5, vtest.sum);
}

////////////////////////////////////////////////////////////////////////
// TupleTest.HoldsLeaf
TEST(TupleTest, HoldsLeaf)
{
    using layout = cg::layout;
    using shape  = layout::shape_t;
    using stride = layout::stride_t;
    using tuple  = cg::int_tuple;
    using coord  = cg::coord;
    using tile   = cg::tile;

    EXPECT_TRUE(cg::holds_leaf(tuple(4)));
    EXPECT_FALSE(cg::holds_leaf(cg::from_string<shape>("(5)").value()));
    EXPECT_FALSE(cg::holds_leaf(shape()));
    EXPECT_FALSE(cg::holds_leaf(tuple(1, 2, tuple(3, 4, tuple(5, 6)))));
    EXPECT_TRUE(cg::holds_leaf(coord(cg::underscore_t{})));
    EXPECT_TRUE(cg::holds_leaf(tile(cg::underscore_t{})));
    EXPECT_TRUE(cg::holds_leaf(tile(layout(shape(2, 2), stride(1, 2)))));
    EXPECT_FALSE(cg::holds_leaf(tile(layout(shape(2, 2), stride(1, 2)),
                                     layout(shape(2, 2), stride(1, 2)))));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.HoldsAnyAlternative
TEST(TupleTest, HoldsAnyAlternative)
{
    using layout = cg::layout;
    using shape  = layout::shape_t;
    using tuple  = cg::int_tuple;
    using int_t  = tuple::int_t;
    using err_t  = cg::cg_error_t;
    using dyn_t  = cg::dynamic_t;

    EXPECT_TRUE(cg::detail::holds_any_alternative<int_t>(tuple(4)));
    EXPECT_FALSE(cg::detail::holds_any_alternative<err_t>(tuple(4)));
    EXPECT_TRUE(cg::detail::holds_any_alternative<std::vector<shape>>(cg::from_string<shape>("(5)").value()));
    EXPECT_FALSE(cg::detail::holds_any_alternative<int_t>(tuple(dyn_t{})));
    bool b0 = cg::detail::holds_any_alternative<int_t, dyn_t>(tuple(dyn_t{}));
    EXPECT_TRUE(b0);
    bool b1 = cg::detail::holds_any_alternative<int_t, err_t>(tuple(dyn_t{}));
    EXPECT_FALSE(b1);

    using double_string_t = std::variant<double, std::string>;
    std::variant<double, std::string> v(1.0);
    EXPECT_TRUE(cg::detail::holds_any_alternative<double>(v));
    EXPECT_FALSE(cg::holds_leaf(shape()));
    tuple t0(1, 2, tuple(3, 4, tuple(5, 6)));
    EXPECT_TRUE(cg::has_only_leaves_of_type<int_t>(t0));
    tuple t1(1, 2, tuple(dyn_t{}, 4, tuple(5, 6)));
    EXPECT_FALSE(cg::has_only_leaves_of_type<int_t>(t1));
    bool b2 = cg::has_only_leaves_of_type<int_t, dyn_t>(t1);
    EXPECT_TRUE(b2);

    std::vector<double_string_t> vec;
    vec.push_back(1.0);
    vec.push_back(2.0);
    vec.push_back(3.0);
    bool bH = cg::holds_type<double>(vec[0]);
    EXPECT_TRUE(bH);
    bH = cg::holds_type<double, std::string>(vec[0]);
    EXPECT_TRUE(bH);
    EXPECT_TRUE(cg::all_hold_types<double>(vec));
    vec.push_back("Hello World!");
    EXPECT_FALSE(cg::all_hold_types<double>(vec));

    using int_double_string_t = std::variant<int, double, std::string>;
    std::vector<int_double_string_t> ids_vec;
    ids_vec.push_back(std::string("A"));
    ids_vec.push_back(2.0);
    ids_vec.push_back(std::string("B"));
    ids_vec.push_back(4.0);
    bool b = cg::all_hold_types<std::string, double>(ids_vec);
    EXPECT_TRUE(b);
    ids_vec.push_back(1);
    b = cg::all_hold_types<std::string, double>(ids_vec);
    EXPECT_FALSE(b);
}

////////////////////////////////////////////////////////////////////////
// TupleTest.HasLeafWithType
TEST(TupleTest, HasLeafWithType)
{
    using tuple = cg::int_tuple;
    using int_t = tuple::int_t;
    using err_t = cg::cg_error_t;
    using dyn_t = cg::dynamic_t;

    // Single-element leaf: holds int_t → true for int_t, false for dyn_t
    EXPECT_TRUE(cg::has_leaf_with_type<int_t>(tuple(4)));
    EXPECT_FALSE(cg::has_leaf_with_type<dyn_t>(tuple(4)));

    // Single-element leaf: holds dyn_t → true for dyn_t, false for int_t
    EXPECT_TRUE(cg::has_leaf_with_type<dyn_t>(tuple(dyn_t{})));
    EXPECT_FALSE(cg::has_leaf_with_type<int_t>(tuple(dyn_t{})));

    // Nested tuple with all int_t leaves
    tuple t0(1, 2, tuple(3, 4, tuple(5, 6)));
    EXPECT_TRUE(cg::has_leaf_with_type<int_t>(t0));
    EXPECT_FALSE(cg::has_leaf_with_type<dyn_t>(t0));
    EXPECT_FALSE(cg::has_leaf_with_type<err_t>(t0));

    // Nested tuple with one dyn_t leaf among int_t leaves
    tuple t1(1, 2, tuple(dyn_t{}, 4, tuple(5, 6)));
    EXPECT_TRUE(cg::has_leaf_with_type<dyn_t>(t1));
    EXPECT_TRUE(cg::has_leaf_with_type<int_t>(t1));
    EXPECT_FALSE(cg::has_leaf_with_type<err_t>(t1));

    // Multiple type args: true if any leaf holds any of them
    bool b0 = cg::has_leaf_with_type<int_t, dyn_t>(t1);
    EXPECT_TRUE(b0);
    bool b1 = cg::has_leaf_with_type<err_t, dyn_t>(t1);
    EXPECT_TRUE(b1);
    bool b2 = cg::has_leaf_with_type<err_t>(t1);
    EXPECT_FALSE(b2);
}

////////////////////////////////////////////////////////////////////////
// TupleTest.TupleLike
TEST(TupleTest, TupleLike)
{
    // Test shape type
    {
        using shape_t = cg::cute_shape_t<cg::dynamic_t>;
        EXPECT_TRUE(cg::is_tuple_like_v<shape_t>);
    }

    // Test stride type
    {
        using stride_t = cg::cute_stride_t<cg::dynamic_t>;
        EXPECT_TRUE(cg::is_tuple_like_v<stride_t>);
    }

    // Test coord type
    {
        using coord_t = cg::cute_coord_t<cg::dynamic_t>;
        EXPECT_TRUE(cg::is_tuple_like_v<coord_t>);
    }

    // Test int_tuple type
    {
        using int_tuple_t = cg::cute_int_tuple_t<cg::dynamic_t>;
        EXPECT_TRUE(cg::is_tuple_like_v<int_tuple_t>);
    }

    // Test non-tuple types
    {
        // Layout type is not tuple-like
        using layout_t = cg::layout_t<cg::dynamic_t>;
        EXPECT_FALSE(cg::is_tuple_like_v<layout_t>);

        // Dynamic type is not tuple-like
        EXPECT_FALSE(cg::is_tuple_like_v<cg::dynamic_t>);

        // Error type is not tuple-like
        EXPECT_FALSE(cg::is_tuple_like_v<cg::cg_error_t>);

        // Underscore type is not tuple-like
        EXPECT_FALSE(cg::is_tuple_like_v<cg::underscore_t>);
    }

    // Test with const/reference variations
    {
        using shape_t = cg::cute_shape_t<cg::dynamic_t>;
        EXPECT_TRUE(cg::is_tuple_like_v<const shape_t>);
        EXPECT_TRUE(cg::is_tuple_like_v<shape_t&>);
        EXPECT_TRUE(cg::is_tuple_like_v<const shape_t&>);
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Insert
TEST(TupleTest, Insert)
{
    {
        cg::int_tuple t(cg::int_tuple(3, 2), 6, cg::int_tuple(5, 3));

        auto t1  = t;
        auto it1 = t1.insert(t1.begin(), 5);
        EXPECT_EQ(cg::int_tuple(5, cg::int_tuple(3, 2), 6, cg::int_tuple(5, 3)), t1);
        EXPECT_EQ(*it1, 5);
        EXPECT_EQ(it1, t1.begin());

        auto t2  = t;
        auto it2 = t2.insert(t2.begin() + 1, 5);
        EXPECT_EQ(cg::int_tuple(cg::int_tuple(3, 2), 5, 6, cg::int_tuple(5, 3)), t2);
        EXPECT_EQ(*it2, 5);
        EXPECT_EQ(it2, t2.begin() + 1);

        auto t3  = t;
        auto it3 = t3.insert(t3.begin() + 1, cg::int_tuple(8, 5));
        EXPECT_EQ(cg::int_tuple(cg::int_tuple(3, 2), cg::int_tuple(8, 5), 6, cg::int_tuple(5, 3)), t3);
        EXPECT_EQ(*it3, cg::int_tuple(8, 5));
        EXPECT_EQ(it3, t3.begin() + 1);

        auto t4  = cg::int_tuple(3);
        auto it4 = t4.insert(t4.begin(), 5);
        EXPECT_EQ(cg::int_tuple(5, 3), t4);
        EXPECT_EQ(*it4, 5);
        EXPECT_EQ(it4, t4.begin());
    }
    {
        cg::int_tuple t(cg::int_tuple(3, 2), 6, cg::int_tuple(5, 3));

        auto t1 = cg::insert(0, t, 5);
        EXPECT_EQ(cg::int_tuple(5, cg::int_tuple(3, 2), 6, cg::int_tuple(5, 3)), t1);

        auto t2 = cg::insert(1, t, 5);
        EXPECT_EQ(cg::int_tuple(cg::int_tuple(3, 2), 5, 6, cg::int_tuple(5, 3)), t2);

        auto t3 = cg::insert(1, t, cg::int_tuple(8, 5));
        EXPECT_EQ(cg::int_tuple(cg::int_tuple(3, 2), cg::int_tuple(8, 5), 6, cg::int_tuple(5, 3)), t3);

        auto t4 = cg::insert(cg::rank(t) + 2, t, 5);
        EXPECT_EQ(cg::int_tuple(cg::cg_error_t{}), t4);

        auto t5 = cg::insert(-1, t, 5);
        EXPECT_EQ(cg::int_tuple(cg::cg_error_t{}), t5);

        auto t6 = cg::insert(0, cg::int_tuple(3), 5);
        EXPECT_EQ(cg::int_tuple(cg::cg_error_t{}), t6);
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Select
TEST(TupleTest, Select)
{
    cg::int_tuple tA(0, 1, 2, 3, 4, 5, 6);
    for(size_t i = 0; i < rank(tA); ++i)
    {
        EXPECT_EQ(cg::select(tA, i).get(0).as_int(), static_cast<cg::int_tuple::int_t>(i));
    }

    // Use std::array for the indices
    std::array<size_t, 2> idx0 = {0, 2};
    cg::int_tuple         tB(0, 1, cg::int_tuple(2, 3, 4, cg::int_tuple(5, 6)));
    EXPECT_EQ(cg::select(tB, 0), cg::int_tuple(std::vector<cg::int_tuple>{0}));
    EXPECT_EQ(cg::select(tB, 1), cg::int_tuple(std::vector<cg::int_tuple>{1}));
    EXPECT_EQ(cg::select(tB, 2).get(0), cg::int_tuple(2, 3, 4, cg::int_tuple(5, 6)));
    EXPECT_EQ(cg::select(tB, 2, 0), cg::int_tuple(cg::int_tuple(2, 3, 4, cg::int_tuple(5, 6)), 0));
    EXPECT_EQ(cg::select(tB, 1, 1), cg::int_tuple(1, 1));
    EXPECT_EQ(cg::select(tB, 2, 2), cg::int_tuple(cg::int_tuple(2, 3, 4, cg::int_tuple(5, 6)), cg::int_tuple(2, 3, 4, cg::int_tuple(5, 6))));
    EXPECT_EQ(cg::select(tB, 0, 1, 2), cg::int_tuple(0, 1, cg::int_tuple(2, 3, 4, cg::int_tuple(5, 6))));
    EXPECT_EQ(cg::select(tB, idx0), cg::int_tuple(0, cg::int_tuple(2, 3, 4, cg::int_tuple(5, 6))));
    EXPECT_EQ(cg::select(tB, 0, 2), cg::int_tuple(0, cg::int_tuple(2, 3, 4, cg::int_tuple(5, 6))));
    // Use std::vector for the indices
    std::vector<int> idx2;
    EXPECT_EQ(cg::rank(cg::select(tB, idx2)), 0);
    // Use a bare array for the indices.
    unsigned int idx3[3] = {2, 1, 0};
    EXPECT_EQ(cg::select(tB, idx3), cg::int_tuple(cg::int_tuple(2, 3, 4, cg::int_tuple(5, 6)), 1, 0));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Unwrap
TEST(TupleTest, Unwrap)
{
    EXPECT_EQ(cg::unwrap(cg::from_string<cg::shape>(std::string("1")).value()), cg::from_string<cg::shape>(std::string("1")).value());
    EXPECT_EQ(cg::unwrap(cg::from_string<cg::shape>(std::string("(1)")).value()), cg::from_string<cg::shape>(std::string("1")).value());
    EXPECT_EQ(cg::unwrap(cg::from_string<cg::shape>(std::string("((1,2))")).value()), cg::from_string<cg::shape>(std::string("(1,2)")).value());
    EXPECT_EQ(cg::unwrap(cg::from_string<cg::shape>(std::string("((1,2),1)")).value()), cg::from_string<cg::shape>(std::string("((1,2),1)")).value());
    EXPECT_EQ(cg::unwrap(cg::from_string<cg::shape>(std::string("(1,(1,2))")).value()), cg::from_string<cg::shape>(std::string("(1,(1,2))")).value());
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Get
TEST(TupleTest, Get)
{
    cg::int_tuple tA(0, 1, 2, 3, 4, 5, 6);
    for(size_t i = 0; i < rank(tA); ++i)
    {
        EXPECT_EQ(tA.get(i).as_int(), static_cast<cg::int_tuple::int_t>(i));
    }
    cg::int_tuple tB(0, 1, cg::int_tuple(2, 3, 4, cg::int_tuple(5, 6)));
    EXPECT_EQ(tB.get(0), cg::int_tuple(0));
    EXPECT_EQ(tB.get(1), cg::int_tuple(1));
    EXPECT_EQ(tB.get(2), cg::int_tuple(2, 3, 4, cg::int_tuple(5, 6)));
    EXPECT_EQ(tB.get(2, 0), cg::int_tuple(2));
    EXPECT_EQ(tB.get(2, 1), cg::int_tuple(3));
    EXPECT_EQ(tB.get(2, 2), cg::int_tuple(4));
    EXPECT_EQ(tB.get(2, 3), cg::int_tuple(5, 6));
    EXPECT_EQ(tB.get(2, 3, 0), cg::int_tuple(5));
    EXPECT_EQ(tB.get(2, 3, 1), cg::int_tuple(6));

    // Use std::array for the indices
    std::array<size_t, 3> idx0 = {2, 3, 0};
    EXPECT_EQ(tB.get(idx0), cg::int_tuple(5));
    // Use std::vector for the indices
    std::vector<int> idx1;
    idx1.push_back(2);
    idx1.push_back(3);
    EXPECT_EQ(tB.get(idx1), cg::int_tuple(5, 6));
    // Verify that an empty range returns the variant itself
    std::vector<int> idx2;
    EXPECT_EQ(tB.get(idx2), cg::int_tuple(0, 1, cg::int_tuple(2, 3, 4, cg::int_tuple(5, 6))));
    // Use a bare array for the indices.
    unsigned int idx3[3] = {2, 3, 1};
    EXPECT_EQ(tB.get(idx3), cg::int_tuple(6));

    // Verify the function to check whether a set of indices is valid
    EXPECT_TRUE(cg::check_get_indices(tB, idx0));
    EXPECT_TRUE(cg::check_get_indices(tB, idx1));
    EXPECT_TRUE(cg::check_get_indices(tB, idx2));
    EXPECT_FALSE(cg::check_get_indices(tA, idx0));
    EXPECT_TRUE(cg::check_get_indices(tA, idx2));

    EXPECT_TRUE(cg::check_get_indices(cg::int_tuple(8), std::array<size_t, 1>{0}));
    EXPECT_TRUE(cg::check_get_indices(cg::int_tuple(cg::int_tuple(5, 6), 7), std::array<size_t, 1>{1}));
    EXPECT_TRUE(cg::check_get_indices(cg::int_tuple(cg::int_tuple(5, 6), 7), std::array<size_t, 2>{1, 0}));
    EXPECT_FALSE(cg::check_get_indices(cg::int_tuple(cg::int_tuple(5, 6), 7), std::array<size_t, 2>{1, 1}));
    EXPECT_TRUE(cg::check_get_indices(cg::int_tuple(cg::int_tuple(5, 6), 7), std::array<size_t, 3>{1, 0, 0}));
    EXPECT_FALSE(cg::check_get_indices(cg::int_tuple(cg::int_tuple(5, 6), 7), std::array<size_t, 3>{1, 0, 1}));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.InRange
TEST(TupleTest, InRange)
{
    EXPECT_TRUE(cg::in_range<int32_t>(std::numeric_limits<int32_t>::max()));
    EXPECT_TRUE(cg::in_range<int32_t>(std::numeric_limits<int32_t>::min()));
    EXPECT_TRUE(cg::in_range<int32_t>(0));
    EXPECT_TRUE(cg::in_range<int64_t>(std::numeric_limits<int64_t>::max()));
    EXPECT_TRUE(cg::in_range<int64_t>(std::numeric_limits<int64_t>::min()));
    EXPECT_TRUE(cg::in_range<int64_t>(0));
    EXPECT_FALSE(cg::in_range<int32_t>(std::numeric_limits<int64_t>::max()));
    EXPECT_FALSE(cg::in_range<int32_t>(std::numeric_limits<int64_t>::min()));
    EXPECT_FALSE(cg::in_range<int16_t>(std::numeric_limits<int16_t>::max() + 1));
    EXPECT_FALSE(cg::in_range<int16_t>(std::numeric_limits<int16_t>::min() - 1));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Gcd
TEST(TupleTest, Gcd)
{
    EXPECT_EQ(4, cg::gcd(*cg::from_string<cg::int_tuple>("4")));
    EXPECT_EQ(4, cg::gcd(*cg::from_string<cg::int_tuple>("(4)")));
    EXPECT_EQ(1, cg::gcd(*cg::from_string<cg::int_tuple>("(?)")));
    EXPECT_EQ(2, cg::gcd(*cg::from_string<cg::int_tuple>("(4,(2,6))")));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.ScalarRange
TEST(TupleTest, ScalarRange)
{
    {
        cg::int_range_t r0 = cg::get_scalar_range(cg::int_tuple(-4, 1, 377));
        EXPECT_EQ(cg::int_range_t(-4, 377), r0);
    }
    {
        cg::int_tuple   t1(3, cg::int_tuple(99, 47, cg::int_tuple(100)), 0);
        cg::int_range_t r1 = cg::get_scalar_range(t1);
        EXPECT_EQ(cg::int_range_t(0, 100), r1);
    }
    {
        cg::int_tuple   t2(std::numeric_limits<int32_t>::min(),
                         std::numeric_limits<int32_t>::max());
        cg::int_range_t r2 = cg::get_scalar_range(t2);
        EXPECT_EQ(cg::int_range_t(std::numeric_limits<int32_t>::min(),
                                  std::numeric_limits<int32_t>::max()),
                  r2);
        EXPECT_TRUE(cg::in_range<int32_t>(r2));
        EXPECT_TRUE(cg::in_range<int64_t>(r2));
    }
    {
        cg::int_tuple   t3(std::numeric_limits<int64_t>::min(),
                         std::numeric_limits<int64_t>::max());
        cg::int_range_t r3 = cg::get_scalar_range(t3);
        EXPECT_EQ(cg::int_range_t(std::numeric_limits<int64_t>::min(),
                                  std::numeric_limits<int64_t>::max()),
                  r3);
        EXPECT_FALSE(cg::in_range<int32_t>(r3));
        EXPECT_TRUE(cg::in_range<int64_t>(r3));
    }
}

////////////////////////////////////////////////////////////////////////
// ArrayConstructorTest.Basic
TEST(ArrayConstructorTest, Basic)
{
    using int_t = cg::shape::int_t;
    {
        cg::shape baseline(1, 2, 3, 4);

        std::array<int_t, 4> a = {1, 2, 3, 4};
        cg::shape            sa(a);
        EXPECT_EQ(sa, baseline);

        std::array<cg::shape, 4> c = {1, 2, 3, 4};
        cg::shape                sc(c);
        EXPECT_EQ(sc, baseline);
    }
    {
        cg::shape exp_result;
        exp_result.append(4);
        std::array<int_t, 1> a = {4};
        cg::shape            wrapped_s(a);
        EXPECT_EQ(wrapped_s, exp_result);
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Product
TEST(TupleTest, Product)
{
    {
        // When t is a leaf, it's wrapped
        auto t   = *cg::from_string<cg::int_tuple>("2");
        auto res = *cg::from_string<cg::int_tuple>("(2)");
        EXPECT_EQ(cg::product_each(t), res);
    }
    {
        auto t   = *cg::from_string<cg::int_tuple>("(1,(2,3),(4,5),6)");
        auto res = *cg::from_string<cg::int_tuple>("(1,6,20,6)");
        EXPECT_EQ(cg::product_each(t), res);
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.
TEST(TupleTest, Erase)
{
    {
        // Remove a non-leaf element (the first one)
        // ((3,2),6,(5,3)) --> (6,(5,3))
        cg::int_tuple t(cg::int_tuple(3, 2), 6, cg::int_tuple(5, 3));

        auto it1 = t.erase(t.begin());
        // Verify that the first element was erased
        EXPECT_EQ(cg::int_tuple(6, cg::int_tuple(5, 3)), t);
        // Verify that the returned iterator points to the element AFTER the
        // removed element.
        EXPECT_EQ(*it1, 6);
        // Verify that the returned iterator points to the beginning of the
        // int_tuple (in this case).
        EXPECT_EQ(it1, t.begin());
    }
    {
        // Remove a non-leaf element (the last one)
        // ((3,2),6,(5,3)) --> ((3,2),6)
        cg::int_tuple t(cg::int_tuple(3, 2), 6, cg::int_tuple(5, 3));
        auto          it1 = t.erase(t.begin() + 2);
        // Verify that the last element was erased
        EXPECT_EQ(cg::int_tuple(cg::int_tuple(3, 2), 6), t);
        // Verify that the returned iterator points to the end of the int_tuple
        // (in this case).
        EXPECT_EQ(it1, t.end());
    }
    {
        // Remove the first element, with the result having a single value
        // (4,23) --> (23)
        cg::int_tuple t(4, 23);

        auto it1 = t.erase(t.begin());
        // Verify that erasing an element from a recursive variant that holds 2
        // values results in a recursive variant that holds an vector with a
        // single element.
        EXPECT_TRUE(cg::holds_vector(t));
        // Verify that the first element was erased
        EXPECT_EQ(cg::int_tuple(cg::wrap(23)), t);
        // Verify that the returned iterator points to the element AFTER the
        // removed element.
        EXPECT_EQ(*it1, 23);
        // Verify that the returned iterator points to the beginning of the
        // int_tuple (in this case).
        EXPECT_EQ(it1, t.begin());
    }
    {
        // Remove the last element, with the result having a single value
        // (4,23) --> (4)
        cg::int_tuple t(4, 23);

        auto it1 = t.erase(t.begin() + 1);
        // Verify that erasing an element from a recursive variant that holds 2
        // values results in a recursive variant that holds an vector.
        EXPECT_TRUE(cg::holds_vector(t));
        // Verify that the last element was erased
        EXPECT_EQ(cg::int_tuple(cg::wrap(4)), t);
        // Verify that the returned iterator points to the end of the
        // int_tuple (in this case).
        EXPECT_EQ(it1, t.end());
    }
    {
        // Remove the first two elements
        // ((3,2),6,(5,3)) --> ((5,3))
        cg::int_tuple t(cg::int_tuple(3, 2), 6, cg::int_tuple(5, 3));

        auto it1 = t.erase(t.begin(), t.begin() + 2);
        // Verify that the first 2 elements were erased
        EXPECT_EQ(cg::int_tuple(cg::wrap(cg::int_tuple(5, 3))), t);
        // Verify that the returned iterator points to the element AFTER the
        // removed element.
        EXPECT_EQ(*it1, cg::int_tuple(5, 3));
        // Verify that the returned iterator points to the beginning of the
        // int_tuple (in this case).
        EXPECT_EQ(it1, t.begin());
    }
    {
        // Remove no elements
        // ((3,2),6,(5,3)) --> ((3,2),6,(5,3))
        cg::int_tuple t(cg::int_tuple(3, 2), 6, cg::int_tuple(5, 3));

        auto it1 = t.erase(t.end(), t.end());
        // Verify that no elements were erased
        EXPECT_EQ(cg::int_tuple(cg::int_tuple(3, 2), 6, cg::int_tuple(5, 3)), t);
        // Verify that the returned iterator points to the end of the
        // int_tuple (in this case).
        EXPECT_EQ(it1, t.end());
    }
    {
        // Remove no elements
        // ((3,2),6,(5,3)) --> ((3,2),6,(5,3))
        cg::int_tuple t(cg::int_tuple(3, 2), 6, cg::int_tuple(5, 3));

        auto it1 = t.erase(t.begin(), t.begin());
        // Verify that no elements were erased
        EXPECT_EQ(cg::int_tuple(cg::int_tuple(3, 2), 6, cg::int_tuple(5, 3)), t);
        // Verify that the returned iterator points to the beginning of the
        // int_tuple (in this case).
        EXPECT_EQ(it1, t.begin());
    }
    {
        // Remove the only element
        // 4 --> ()
        cg::int_tuple t(4);

        auto it1 = t.erase(t.begin());
        // Verify that the result is an empty tuple
        EXPECT_EQ(cg::int_tuple(), t);
        // Verify that the returned iterator points to the beginning of the
        // int_tuple (in this case).
        EXPECT_EQ(it1, t.begin());
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.PopBack
TEST(TupleTest, PopBack)
{
    {
        // Remove a non-leaf element from the back.
        // ((3,2),6,(5,3)) --> ((3,2),6)
        cg::int_tuple t(cg::int_tuple(3, 2), 6, cg::int_tuple(5, 3));

        t.pop_back();
        EXPECT_EQ(cg::int_tuple(cg::int_tuple(3, 2), 6), t);
    }
    {
        // Preserve the vector representation when popping a two-element tuple.
        // (4,23) --> (4)
        cg::int_tuple t(4, 23);

        t.pop_back();
        EXPECT_TRUE(cg::holds_vector(t));
        EXPECT_EQ(cg::int_tuple(cg::wrap(4)), t);
    }
    {
        // Remove the only element from a leaf.
        // 4 --> ()
        cg::int_tuple t(4);

        t.pop_back();
        EXPECT_TRUE(cg::holds_vector(t));
        EXPECT_EQ(cg::int_tuple(), t);
    }
    {
        // Remove the only element from an explicitly wrapped tuple.
        // (4) --> ()
        cg::int_tuple t(cg::wrap(4));

        t.pop_back();
        EXPECT_TRUE(cg::holds_vector(t));
        EXPECT_EQ(cg::int_tuple(), t);
    }
    {
        // Pop removes only the top-level back element.
        // ((1,2),(3,(4,5))) --> ((1,2))
        cg::int_tuple t = *cg::from_string<cg::int_tuple>("((1, 2), (3, (4, 5)))");

        t.pop_back();
        EXPECT_EQ(*cg::from_string<cg::int_tuple>("((1, 2))"), t);
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.
TEST(TupleTest, GetLeaves)
{
    using int_t = cg::int_tuple::int_t;
    using dyn_t = cg::dynamic_t;
    {
        // ((3,2),6,(?,3))
        cg::int_tuple t(cg::int_tuple(3, 2), 6, cg::int_tuple(dyn_t{}, 3));
        auto          leaves = cg::get_leaves(t);
        EXPECT_EQ(leaves.size(), 5);
        EXPECT_TRUE(std::holds_alternative<int_t>(leaves[0]));
        EXPECT_TRUE(std::holds_alternative<int_t>(leaves[1]));
        EXPECT_TRUE(std::holds_alternative<int_t>(leaves[2]));
        EXPECT_TRUE(std::holds_alternative<dyn_t>(leaves[3]));
        EXPECT_TRUE(std::holds_alternative<int_t>(leaves[4]));
        EXPECT_EQ(std::get<int_t>(leaves[0]), 3);
        EXPECT_EQ(std::get<int_t>(leaves[1]), 2);
        EXPECT_EQ(std::get<int_t>(leaves[2]), 6);
        EXPECT_EQ(std::get<int_t>(leaves[4]), 3);
    }
    {
        // ((3,2),?,(?,5))
        cg::int_tuple t(cg::int_tuple(3, 2), dyn_t{}, cg::int_tuple(dyn_t{}, 5));
        // Note: return type is std::vector<int_t> because there is only one type.
        auto int_leaves = cg::get_leaves_with_type<int_t>(t);
        EXPECT_EQ(int_leaves.size(), 3);
        EXPECT_EQ(int_leaves[0], 3);
        EXPECT_EQ(int_leaves[1], 2);
        EXPECT_EQ(int_leaves[2], 5);
        auto dyn_leaves = cg::get_leaves_with_type<dyn_t>(t);
        EXPECT_EQ(dyn_leaves.size(), 2);
        // Note: return vector element type is std::variant<int_t, dyn_t>
        auto int_or_dyn_leaves = cg::get_leaves_with_type<int_t, dyn_t>(t);
        EXPECT_EQ(int_or_dyn_leaves.size(), 5);
        EXPECT_TRUE(std::holds_alternative<int_t>(int_or_dyn_leaves[0]));
        EXPECT_EQ(std::get<int_t>(int_or_dyn_leaves[0]), 3);
        EXPECT_TRUE(std::holds_alternative<int_t>(int_or_dyn_leaves[1]));
        EXPECT_EQ(std::get<int_t>(int_or_dyn_leaves[1]), 2);
        EXPECT_TRUE(std::holds_alternative<dyn_t>(int_or_dyn_leaves[2]));
        EXPECT_EQ(std::get<dyn_t>(int_or_dyn_leaves[2]), dyn_t{});
        EXPECT_TRUE(std::holds_alternative<dyn_t>(int_or_dyn_leaves[3]));
        EXPECT_EQ(std::get<dyn_t>(int_or_dyn_leaves[3]), dyn_t{});
        EXPECT_TRUE(std::holds_alternative<int_t>(int_or_dyn_leaves[4]));
        EXPECT_EQ(std::get<int_t>(int_or_dyn_leaves[4]), 5);
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.
TEST(TupleTest, PrefixProduct)
{
    using int_tuple = cg::int_tuple;
    // Tests taken from pycute test_htuple.py
    EXPECT_EQ(cg::prefix_product(int_tuple(2)), 1);
    EXPECT_EQ(cg::prefix_product(int_tuple(3, 2)), int_tuple(1, 3));
    EXPECT_EQ(cg::prefix_product(int_tuple(3, 2, 4)), int_tuple(1, 3, 6));
    EXPECT_EQ(cg::prefix_product(int_tuple(int_tuple(2, 3), 4)),
              int_tuple(int_tuple(1, 2), 6));
    EXPECT_EQ(cg::prefix_product(cg::from_string<int_tuple>("((2,3),(2,1,2),(5,2,1))").value()),
              cg::from_string<int_tuple>("((1,2),(6,12,12),(24,120,240))").value());
    // Initial value is specified - we expect the result to be the same
    // value.
    EXPECT_EQ(cg::prefix_product(int_tuple(4, int_tuple(5, 6), 7),
                                 int_tuple(1, int_tuple(4, 20), 120)),
              int_tuple(1, int_tuple(4, 20), 120));
    // Test functionality for the case where an init value is specified,
    // and the profiles don't match.
    // PyCuTe output:
    // >>> prefix_product((4,(5, 6),7), (1,4,500))
    // (1, (4, 20), 500)
    EXPECT_EQ(cg::prefix_product(int_tuple(4, int_tuple(5, 6), 7),
                                 int_tuple(1, 4, 500)),
              int_tuple(1, int_tuple(4, 20), 500));
}

////////////////////////////////////////////////////////////////////////
// TupleTest.AllLeaves
TEST(TupleTest, AllLeaves)
{
    using int_t     = cg::int_tuple::int_t;
    using int_tuple = cg::int_tuple;
    using dyn_t     = cg::dynamic_t;

    auto is_positive_int = [](const auto& v) { return (cg::holds_int(v) && (v.as_int() > 0)); };
    auto is_nonzero_int  = [](const auto& v) { return (cg::holds_int(v) && (v.as_int() != 0)); };
    auto is_one          = [](const auto& v) { return (cg::holds_int(v) && (v.as_int() == 1)); };
    auto always_true     = [](const auto&) { return true; };
    auto always_false    = [](const auto&) { return false; };

    // Single leaf: true when predicate holds
    EXPECT_TRUE(cg::all_leaves(int_tuple(4), is_positive_int));
    EXPECT_FALSE(cg::all_leaves(int_tuple(0), is_positive_int));

    // Flat tuple: all leaves positive
    EXPECT_TRUE(cg::all_leaves(int_tuple(1, 2, 3), is_positive_int));

    // Flat tuple: one non-positive leaf
    EXPECT_FALSE(cg::all_leaves(int_tuple(1, 0, 3), is_positive_int));

    // Flat tuple: all leaves non-zero
    EXPECT_TRUE(cg::all_leaves(int_tuple(2, 3, 5), is_nonzero_int));

    // Nested tuple: all leaves positive
    // ((3,2),6,(4,5))
    EXPECT_TRUE(cg::all_leaves(int_tuple(int_tuple(3, 2), 6, int_tuple(4, 5)), is_positive_int));

    // Nested tuple: one leaf is zero -> not all positive
    // ((3,2),0,(4,5))
    EXPECT_FALSE(cg::all_leaves(int_tuple(int_tuple(3, 2), 0, int_tuple(4, 5)), is_positive_int));

    // Deeply nested tuple: all leaves positive
    // (((2,3),4),5)
    EXPECT_TRUE(cg::all_leaves(int_tuple(int_tuple(int_tuple(2, 3), 4), 5), is_positive_int));

    // Deeply nested tuple: one leaf is non-positive
    // (((2,0),4),5)
    EXPECT_FALSE(cg::all_leaves(int_tuple(int_tuple(int_tuple(2, 0), 4), 5), is_positive_int));

    // All leaves equal 1
    EXPECT_TRUE(cg::all_leaves(int_tuple(1, 1, 1), is_one));
    EXPECT_FALSE(cg::all_leaves(int_tuple(1, 2, 1), is_one));

    // Trivially true / false predicates
    EXPECT_TRUE(cg::all_leaves(int_tuple(1, 2, 3), always_true));
    EXPECT_FALSE(cg::all_leaves(int_tuple(1, 2, 3), always_false));

    // Empty vector: all_leaves should return true (vacuously)
    {
        int_tuple empty;
        EXPECT_TRUE(cg::all_leaves(empty, always_false));
    }

    // Mixed int and dynamic leaves: predicate checks that all leaves hold a static int
    {
        // (3, ?, 5) — contains a dynamic leaf, so not all leaves are static ints
        cg::int_tuple t(3, dyn_t{}, 5);
        auto          is_int_leaf = [](const auto& v) {
            return std::holds_alternative<int_t>(v);
        };
        EXPECT_FALSE(cg::all_leaves(t, is_int_leaf));

        // (3, 5, 7) — all leaves are static ints
        cg::int_tuple t2(3, 5, 7);
        EXPECT_TRUE(cg::all_leaves(t2, is_int_leaf));
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.MaxRank
TEST(TupleTest, MaxRank)
{
    {
        cg::int_tuple a3(1, 2, 3);
        cg::int_tuple b1(0);
        cg::int_tuple c4(17, 18, 19, 20);
        EXPECT_EQ(cg::max_rank(a3, b1, c4), 4);
    }
    {
        EXPECT_EQ(cg::max_rank(), 0);
    }
    {
        cg::int_tuple a0;
        EXPECT_EQ(cg::max_rank(a0), 0);
    }
}

////////////////////////////////////////////////////////////////////////
// TupleTest.Swap
TEST(TupleTest, Swap)
{
    {
        cg::int_tuple a(7);
        cg::int_tuple b(11);
        a.swap(b);
        EXPECT_EQ(a, 11);
        EXPECT_EQ(b, 7);
    }
    {
        cg::int_tuple a(1, 2, 3);
        cg::int_tuple b(0);
        a.swap(b);
        EXPECT_EQ(a, 0);
        EXPECT_EQ(b, cg::int_tuple(1, 2, 3));
    }
    {
        cg::int_tuple a(1, 2);
        cg::int_tuple b(3, 4, 5);
        a.swap(b);
        EXPECT_EQ(a, cg::int_tuple(3, 4, 5));
        EXPECT_EQ(b, cg::int_tuple(1, 2));
    }
    {
        cg::int_tuple a;
        cg::int_tuple b(42);
        a.swap(b);
        EXPECT_EQ(a, 42);
        EXPECT_EQ(b, cg::int_tuple());
    }
    {
        cg::int_tuple a = *cg::from_string<cg::int_tuple>("((1, 2), 3)");
        cg::int_tuple b = *cg::from_string<cg::int_tuple>("(4, (5, 6))");
        a.swap(b);
        EXPECT_EQ(a, cg::from_string<cg::int_tuple>("(4, (5, 6))"));
        EXPECT_EQ(b, cg::from_string<cg::int_tuple>("((1, 2), 3)"));
    }
    {
        cg::int_tuple a(1, 2, 3);
        a.swap(a);
        EXPECT_EQ(a, cg::int_tuple(1, 2, 3));
    }
}
