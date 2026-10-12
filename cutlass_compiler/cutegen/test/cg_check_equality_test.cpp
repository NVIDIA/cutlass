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

#include "gtest/gtest.h"

namespace cg = cutegen;

TEST(CheckEquality, Basic)
{
    using dyn_t       = cg::dynamic_t;
    using container_t = std::vector<cg::detail::eq_comp_t>;
    using dyn_index_t = cg::detail::dynamic_index_t;
    using eq_comp_t   = cg::detail::eq_comp_t;

    // Test value below using numeric_limits<int64_t>::max() assumes 64-bit
    // static constants.
    static_assert(std::is_same<cg::static_int_t, int64_t>::value);

    cg::scaled_basis sb1({2, 3, 4}, 64);
    cg::scaled_basis sb2({2, 3, 4}, 32);
    cg::scaled_basis sb3({2, 3, 4}, dyn_t{});
    cg::scaled_basis sb4({0, 3, 4}, 64);
    cg::scaled_basis sb5({2, 3, 4}, cg::ratio(256, 4));
    cg::scaled_basis sb6({2, 3, 4}, cg::ratio(17, 4));

    cg::shape     s0(2, 3, 4);
    cg::shape     s1(2, 3, 4);
    cg::shape     s2(2, 3, 5);
    cg::shape     s3(2, 3, cg::shape(4, 5, 6), 7);
    cg::shape     s4(2, dyn_t{}, cg::shape(dyn_t{}, dyn_t{}, dyn_t{}), 7);
    cg::shape     s5(dyn_t{}, 3, cg::shape(4, 5, 6), dyn_t{});
    cg::shape     s6(dyn_t{}, dyn_t{}, dyn_t{});
    cg::shape     s7(dyn_t{}, dyn_t{}, dyn_t{});
    cg::int_tuple t0(2, 3, 4);
    cg::int_tuple t1(2, 3, std::numeric_limits<int64_t>::max());
    cg::int_tuple t2(dyn_t{}, dyn_t{}, dyn_t{/*width=*/32});
    cg::int_tuple t3(10, 20, 30);
    cg::int_tuple t4(dyn_t{}, dyn_t{}, dyn_t{});
    cg::coord     c0(2, cg::_, 4);
    cg::stride    d0(2, 3, 4);
    cg::stride    d1(2, sb1, 4);
    cg::stride    d2(dyn_t{}, sb2, 4);
    cg::stride    d3(dyn_t{}, sb3, 4);
    cg::stride    d4(dyn_t{}, sb4, 4);
    cg::stride    d5(dyn_t{}, sb5, 4);
    cg::stride    d6(dyn_t{}, sb6, 4);

    // (2, 3, 4) == (2, 3, 4)
    auto cmp0 = cg::detail::check_equality<container_t>(s0, s1);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp0));
    EXPECT_TRUE(std::get<bool>(cmp0));

    // (2, 3, 4) != (2, 3, 5)
    auto cmp1 = cg::detail::check_equality<container_t>(s0, s2);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp1));
    EXPECT_FALSE(std::get<bool>(cmp1));

    // (2, 3, 4) != (2, 3, (4, 5, 6), 7)
    auto cmp2 = cg::detail::check_equality<container_t>(s0, s3);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp2));
    EXPECT_FALSE(std::get<bool>(cmp2));

    // (2, 3, 4) != (2, ?, (?, ?, ?), 7)
    auto cmp3 = cg::detail::check_equality<container_t>(s0, s4);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp3));
    EXPECT_FALSE(std::get<bool>(cmp3));

    // (2, 3, (4, 5, 6), 7) might equal (2, ?, (?, ?, ?), 7)
    auto cmp_4 = cg::detail::check_equality<container_t>(s3, s4);
    EXPECT_TRUE(std::holds_alternative<container_t>(cmp_4));
    EXPECT_EQ(std::get<container_t>(cmp_4).size(), 4);
    eq_comp_t chk4[] = {{3, dyn_index_t{0}},
                        {4, dyn_index_t{1}},
                        {5, dyn_index_t{2}},
                        {6, dyn_index_t{3}}};
    EXPECT_EQ(std::get<container_t>(cmp_4)[0], chk4[0]);
    EXPECT_EQ(std::get<container_t>(cmp_4)[1], chk4[1]);
    EXPECT_EQ(std::get<container_t>(cmp_4)[2], chk4[2]);
    EXPECT_EQ(std::get<container_t>(cmp_4)[3], chk4[3]);

    // (2, ?, (?, ?, ?), 7) might equal (?, 3, (4, 5, 6), ?)
    auto cmp5 = cutegen::detail::check_equality<container_t>(s4, s5);
    EXPECT_TRUE(std::holds_alternative<container_t>(cmp5));
    EXPECT_EQ(std::get<container_t>(cmp5).size(), 6);
    eq_comp_t chk5[] = {{2, dyn_index_t{0}},
                        {dyn_index_t{0}, 3},
                        {dyn_index_t{1}, 4},
                        {dyn_index_t{2}, 5},
                        {dyn_index_t{3}, 6},
                        {7, dyn_index_t{1}}};
    EXPECT_EQ(std::get<container_t>(cmp5)[0], chk5[0]);
    EXPECT_EQ(std::get<container_t>(cmp5)[1], chk5[1]);
    EXPECT_EQ(std::get<container_t>(cmp5)[2], chk5[2]);
    EXPECT_EQ(std::get<container_t>(cmp5)[3], chk5[3]);
    EXPECT_EQ(std::get<container_t>(cmp5)[4], chk5[4]);
    EXPECT_EQ(std::get<container_t>(cmp5)[5], chk5[5]);

    // (?, ?, ?) might equal (?, ?, ?)
    auto cmp6 = cutegen::detail::check_equality<container_t>(s6, s7);
    EXPECT_TRUE(std::holds_alternative<container_t>(cmp6));
    EXPECT_EQ(std::get<container_t>(cmp6).size(), 3);
    eq_comp_t chk6[] = {{dyn_index_t{0}, dyn_index_t{0}},
                        {dyn_index_t{1}, dyn_index_t{1}},
                        {dyn_index_t{2}, dyn_index_t{2}}};
    EXPECT_EQ(std::get<container_t>(cmp6)[0], chk6[0]);
    EXPECT_EQ(std::get<container_t>(cmp6)[1], chk6[1]);
    EXPECT_EQ(std::get<container_t>(cmp6)[2], chk6[2]);

    // We can even perform elementwise comparison of different types (if we want
    // to).
    // shape(2, 3, 4) == int_tuple(2, 3, 4)
    auto cmp7 = cg::detail::check_equality<container_t>(s0, t0);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp7));
    EXPECT_TRUE(std::get<bool>(cmp7));

    // shape(2, 3, 4) != coord(2, _, 4)
    auto cmp8 = cg::detail::check_equality<container_t>(s0, c0);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp8));
    EXPECT_FALSE(std::get<bool>(cmp8));

    // shape(2, 3, 4) == stride(2, 3, 4)
    auto cmp9 = cg::detail::check_equality<container_t>(s0, d0);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp9));
    EXPECT_TRUE(std::get<bool>(cmp9));

    // stride(2, 3, 4) != stride(2, 64@4@3@2, 4)
    auto cmp10 = cg::detail::check_equality<container_t>(d0, d1);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp10));
    EXPECT_FALSE(std::get<bool>(cmp10));

    // stride(2, 64@4@3@2, 4) == stride(2, 64@4@3@2, 4)
    auto cmp11 = cg::detail::check_equality<container_t>(d1, d1);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp11));
    EXPECT_TRUE(std::get<bool>(cmp11));

    // stride(2, 64@4@3@2, 4) != stride(?, 32@4@3@2, 4) (basis value different)
    auto cmp12 = cg::detail::check_equality<container_t>(d1, d2);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp12));
    EXPECT_FALSE(std::get<bool>(cmp12));

    // stride(?, 32@4@3@2, 4) might equal stride(?, ?@4@3@2, 4)
    auto cmp13 = cg::detail::check_equality<container_t>(d2, d3);
    EXPECT_TRUE(std::holds_alternative<container_t>(cmp13));
    EXPECT_EQ(std::get<container_t>(cmp13).size(), 2);
    eq_comp_t chk13[] = {{dyn_index_t{0}, dyn_index_t{0}},
                         {32, dyn_index_t{1}}};
    EXPECT_EQ(std::get<container_t>(cmp13)[0], chk13[0]);
    EXPECT_EQ(std::get<container_t>(cmp13)[1], chk13[1]);

    // stride(2, 64@4@3@2, 4) != stride(2, 64@4@3@0, 4)  (last mode differs)
    auto cmp14 = cg::detail::check_equality<container_t>(d1, d4);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp14));
    EXPECT_FALSE(std::get<bool>(cmp14));

    // stride(2, 64@4@3@2, 4) might equal stride(?, 256/4@4@3@2, 4) (ratio reduces to 64)
    auto cmp15 = cg::detail::check_equality<container_t>(d1, d5);
    EXPECT_TRUE(std::holds_alternative<container_t>(cmp15));
    EXPECT_EQ(std::get<container_t>(cmp15).size(), 1);
    eq_comp_t chk15[] = {{2, dyn_index_t{0}}};
    EXPECT_EQ(std::get<container_t>(cmp15)[0], chk15[0]);

    // stride(2, 64@4@3@2, 4) != stride(?, 17/4@4@3@2, 4) (ratio is non-integral)
    auto cmp16 = cg::detail::check_equality<container_t>(d1, d6);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp16));
    EXPECT_FALSE(std::get<bool>(cmp16));

    // stride(?, ?@4@3@2, 4) might equal stride(?, 256/4@4@3@2, 4) (ratio reduces to 64)
    auto cmp17 = cg::detail::check_equality<container_t>(d3, d5);
    EXPECT_TRUE(std::holds_alternative<container_t>(cmp17));
    EXPECT_EQ(std::get<container_t>(cmp17).size(), 2);
    eq_comp_t chk17[] = {{dyn_index_t{0}, dyn_index_t{0}},
                         {dyn_index_t{1}, 64}};
    EXPECT_EQ(std::get<container_t>(cmp17)[0], chk17[0]);
    EXPECT_EQ(std::get<container_t>(cmp17)[1], chk17[1]);

    // (2,3,<too_big_for_i32>) != (?,?,?{i32})
    auto cmp18 = cg::detail::check_equality<container_t>(t1, t2);
    EXPECT_TRUE(std::holds_alternative<bool>(cmp18));
    EXPECT_FALSE(std::get<bool>(cmp18));

    // (10,20,30) != (?,?,?)
    auto cmp19 = cg::detail::check_equality<container_t>(t3, t4);
    EXPECT_TRUE(std::holds_alternative<container_t>(cmp19));
}
