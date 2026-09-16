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
#include <optional>
#include <string>
#include <variant>
#include <vector>

#include "cutegen/cg_error.hpp"
#include "cutegen/cutegen.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"
#include "cutegen/dynamic.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/rec_var_algorithms.hpp"
#include "cutegen/scaled_basis.hpp"
#include "cutegen/underscore.hpp"

#include "gtest/gtest.h"

#include "utils.hpp"

namespace cg = cutegen;

TEST(ScaledBasisTest, Basic)
{
    // Test equality when one has an int, the other has a vector of size 1
    auto a = cg::scaled_basis(cg::scaled_basis::vector_t(1, 1), 2);
    auto b = cg::scaled_basis(1, 2);
    EXPECT_EQ(a, b);
    // Test equality between scaled bases with vector modes
    auto c = cg::scaled_basis({2, 2}, 1);
    auto d = cg::scaled_basis({2, 2}, 1);
    EXPECT_EQ(c, d);
}

TEST(ScaledBasisTest, EFactory)
{
    // E is a shortcut unit (value=1) basis element factory function.
    using sb = cg::scaled_basis;

    // E() == 1 — pycute parity, collapses to plain integer.
    EXPECT_EQ(cg::E(), 1);

    // E(0) == sb(0, 1) == (1,0,0,...)
    // E(1) == sb(1, 1) == (0,1,0,...)
    EXPECT_EQ(cg::E(0), sb(0, 1));
    EXPECT_EQ(cg::E(1), sb(1, 1));

    // E(m0, m1, ...) for hierarchical basis elements.
    // E(0,0) == sb({0, 0}, 1) == ((1,0,0,...),0,0,...)
    // E(0,1) == sb({0, 1}, 1) == ((0,1,0,...),0,0,...)
    // E(1,0) == sb({1, 0}, 1) == (0,(1,0,0,...),0,...)
    // E(1,1) == sb({1, 1}, 1) == (0,(0,1,0,...),0,...)
    EXPECT_EQ(cg::E(0, 0), sb({0, 0}, 1));
    EXPECT_EQ(cg::E(0, 1), sb({0, 1}, 1));
    EXPECT_EQ(cg::E(1, 0), sb({1, 0}, 1));
    EXPECT_EQ(cg::E(1, 1), sb({1, 1}, 1));

    // Inspect modes/value directly for the single- and multi-mode paths.
    // (Both paths now go through the vector ctor — no size-1 special case.)
    {
        auto e = cg::E(2);
        EXPECT_EQ(e.modes(), sb::vector_t{2});
        EXPECT_TRUE(e.value_holds_int());
        EXPECT_EQ(e.static_integral_value(), 1);
    }
    {
        auto e = cg::E(1, 0, 2);
        EXPECT_EQ(e.modes(), (sb::vector_t{1, 0, 2}));
        EXPECT_TRUE(e.value_holds_int());
        EXPECT_EQ(e.static_integral_value(), 1);
    }
}

TEST(ScaledBasisTest, HoldsScaledBasis)
{
    using sb = cg::scaled_basis;
    auto a   = cg::stride(1, 2, 3);
    EXPECT_FALSE(cg::holds_scaled_basis(a));
    EXPECT_FALSE(cg::has_scaled_basis(a));
    auto b = cg::stride(sb(0, 1));
    EXPECT_TRUE(cg::holds_scaled_basis(b));
    EXPECT_TRUE(cg::has_scaled_basis(b));
    auto c = cg::stride(1, cg::stride(sb(0, 1)));
    EXPECT_FALSE(cg::holds_scaled_basis(c));
    EXPECT_TRUE(cg::has_scaled_basis(c));
    auto d = cg::shape{};
    EXPECT_FALSE(cg::holds_scaled_basis(d));
    EXPECT_FALSE(cg::has_scaled_basis(d));
}

////////////////////////////////////////////////////////////////////////
// ScaledBasisTest.TypeCanHoldDynamic
TEST(ScaledBasisTest, TypeCanHoldDynamic)
{
    using test_sb     = cg::scaled_basis_t<int>;
    using test_sb_dyn = cg::scaled_basis_t<int, cg::dynamic_t>;
    static_assert(cg::type_can_hold_dynamic_int<test_sb_dyn>::value);
    static_assert(!cg::type_can_hold_dynamic_int<test_sb>::value);
}

TEST(ScaledBasisTest, ToString)
{
    auto a = cg::stride(cg::scaled_basis(cg::scaled_basis::vector_t(1, 1), 1));
    EXPECT_EQ(cg::to_string(a), "1@1");
    auto b = cg::stride(cg::scaled_basis(2, 1));
    EXPECT_EQ(cg::to_string(b), "1@2");
    auto c = cg::stride(cg::scaled_basis(cg::scaled_basis::vector_t(1, 2), 2));
    EXPECT_EQ(cg::to_string(c), "2@2");
    auto d = cg::stride(cg::scaled_basis({2, 2}, 1));
    EXPECT_EQ(cg::to_string(d), "1@2@2");
    auto e = cg::stride(cg::scaled_basis({2, 3, 4, 5, 6, 7}, 64));
    EXPECT_EQ(cg::to_string(e), "64@7@6@5@4@3@2");
    auto f = cg::stride(cg::scaled_basis({2, 3, 4, 5, 6, 7}, cg::ratio(1, 4)));
    EXPECT_EQ(cg::to_string(f), "1/4@7@6@5@4@3@2");
}

TEST(ScaledBasisTest, FromString)
{
    auto a = cg::from_string<cg::stride>(std::string("1@1"));
    EXPECT_EQ(a, cg::stride(cg::scaled_basis(1, 1)));
    auto b = cg::from_string<cg::stride>(std::string("1@2"));
    EXPECT_EQ(b, cg::stride(cg::scaled_basis(2, 1)));
    auto c = cg::from_string<cg::stride>(std::string("2@2"));
    EXPECT_EQ(c, cg::stride(cg::scaled_basis(cg::scaled_basis::vector_t(1, 2), 2)));
    auto d       = cg::from_string<cg::stride>(std::string("1@2@2"));
    auto d_check = cg::stride(cg::scaled_basis({2, 2}, 1));
    EXPECT_EQ(d, d_check);
    auto e       = cg::from_string<cg::scaled_basis>(std::string("64@7@6@5@4@3@2"));
    auto e_check = cg::scaled_basis({2, 3, 4, 5, 6, 7}, 64);
    EXPECT_EQ(e, e_check);
    // Verify that an invalid mode sets will fail to parse
    auto f = cg::from_string<cg::scaled_basis>(std::string("64@7@6@"));
    EXPECT_FALSE(f.has_value());
    auto g = cg::from_string<cg::scaled_basis>(std::string("64-7@6"));
    EXPECT_FALSE(g.has_value());
    {
        using sb = cg::scaled_basis;

        auto dyn      = cg::dynamic_t{};
        auto ly       = cg::from_string<cg::layout>(std::string("((?,?),?,?,?,?):((?@1,?@0),?@2,?@0,?@1,?@2)"));
        auto ly_check = cg::layout(cg::shape(cg::shape(dyn, dyn),
                                             dyn,
                                             dyn,
                                             dyn,
                                             dyn),
                                   cg::stride(cg::stride(sb{1, dyn}, sb{0, dyn}),
                                              sb{2, dyn},
                                              sb{0, dyn},
                                              sb{1, dyn},
                                              sb{2, dyn}));
        EXPECT_EQ(ly, ly_check);
    }
    auto h       = cg::from_string<cg::scaled_basis>(std::string("2/4@7@6@5@4@3@2"));
    auto h_check = cg::scaled_basis({2, 3, 4, 5, 6, 7}, cg::ratio(2, 4));
    EXPECT_EQ(h, h_check);
}

TEST(ScaledBasisTest, SparseScaledBasis)
{
    {
        auto stride = cg::from_string<cg::stride>(std::string("(2@1,1@1)")).value();
        auto shape  = cg::shape(3, 5);
        auto layout = cg::layout(shape, stride);

        auto tuple = cg::layout_eval(cg::coord(1, 1), layout);
        EXPECT_EQ(cg::int_tuple(0, 3), tuple);
    }

    {
        auto layout = cg::from_string<cg::layout>(std::string("(4,1,3):(0,0,64@0)")).value();
        auto tuple  = cg::layout_eval(5, layout);
        EXPECT_EQ(cg::int_tuple(std::vector<cg::int_tuple>{64}), tuple);
    }

    {
        auto layout = cg::from_string<cg::layout>(std::string("(((2),1),1,1,2):(((0),0),0,0,64@0)")).value();
        auto tuple  = cg::layout_eval(10, layout);
        EXPECT_EQ(cg::int_tuple(std::vector<cg::int_tuple>{320}), tuple);
    }
}

TEST(ScaledBasisTest, EncodeDecode)
{
    auto a = cg::layout(cg::shape(2), cg::scaled_basis(2, 1));
    auto b = cg::layout(cg::shape(2), cg::scaled_basis({1, 2, 3}, 4));
    auto c = cg::layout(cg::shape(2), cg::scaled_basis({1, 2, 3}, cg::ratio(4, 12)));
    EXPECT_TRUE(test_codec(a));
    EXPECT_TRUE(test_codec(b));
    EXPECT_TRUE(test_codec(c));
    // Verify failure on invalid buffers
    {
        std::vector<char> buffer;
        cg::encode(buffer, a);
        buffer.resize(buffer.size() - 16);
        auto dec = cg::decode<cg::layout>(buffer);
        EXPECT_FALSE(dec.has_value());
    }
}

TEST(ScaledBasisTest, MakeBasisLike)
{
    using sb = cg::scaled_basis;
    {
        auto shape  = cg::shape(4);
        auto stride = cg::make_basis_like<cg::stride>(shape);
        EXPECT_EQ(stride, cg::stride(1));
    }
    {
        auto shape  = cg::shape(2, 2, 2);
        auto stride = cg::make_basis_like<cg::stride>(shape);
        EXPECT_EQ(stride, cg::stride(sb(0, 1), sb(1, 1), sb(2, 1)));
    }
    {
        auto shape  = cg::shape(2, cg::shape(3, 4), 5);
        auto stride = cg::make_basis_like<cg::stride>(shape);
        EXPECT_EQ(stride,
                  cg::stride(
                      sb(0, 1),
                      cg::stride(sb({1, 0}, 1), sb({1, 1}, 1)),
                      sb(2, 1)));
        auto layout = cg::make_identity_layout(shape);
        EXPECT_EQ(layout.shape(), shape);
        EXPECT_EQ(layout.stride(), stride);
    }
    {
        // pycute behavior:
        // >>> make_basis_like(Layout(8,1))
        // 1
        auto s = cg::make_basis_like<cg::stride>(cg::layout(cg::shape(8)));
        EXPECT_EQ(s, 1);
    }
    {
        // pycute behavior:
        // >>> make_basis_like((Layout(4,2), Layout(5,3)))
        // (1@0, 1@1)
        auto s = cg::make_basis_like<cg::stride>(cg::tile(cg::layout(cg::shape(4), cg::stride(2)),
                                                          cg::layout(cg::shape(5), cg::stride(3))));
        EXPECT_EQ(s, cg::stride(sb(0, 1), sb(1, 1)));
    }
}

template <class A, class B>
auto sum(const A& a, const B& b)
{
    return cg::arith_tuple_sum<cg::int_tuple>(a, b);
}

TEST(ScaledBasisTest, Addition)
{
    // scaled_basis_t  + scaled_basis_t
    {
        // 2@0 + 6@2 -> (2,0,6)
        auto a = cg::scaled_basis(0, 2);
        auto b = cg::scaled_basis(2, 6);
        EXPECT_EQ(sum(a, b), cg::int_tuple(2, 0, 6));
    }
    {
        // 2@1 + 6@1 -> (0,8)
        auto a = cg::scaled_basis(1, 2);
        auto b = cg::scaled_basis(1, 6);
        EXPECT_EQ(sum(a, b), cg::int_tuple(0, 8));
    }
    {
        // 2@2@1 + 6@1 -> (0,6,(0,2))
        auto a = cg::scaled_basis({2, 1}, 2);
        auto b = cg::scaled_basis(1, 6);
        EXPECT_EQ(sum(a, b), cg::int_tuple(0, 6, cg::int_tuple(0, 2)));
    }
    {
        // 2@2@1 + 3@2@1 -> (0,0,(0,5))
        auto a = cg::scaled_basis({2, 1}, 2);
        auto b = cg::scaled_basis({2, 1}, 3);
        EXPECT_EQ(sum(a, b), cg::int_tuple(0, 0, cg::int_tuple(0, 5)));
    }
    // tuple + scaled_basis
    {
        // (0,0,(0,3)) + 3@0@1 -> ((0,3),0,(0,3))
        auto a   = cg::int_tuple(0, 0, cg::int_tuple(0, 3));
        auto b   = cg::scaled_basis({0, 1}, 3);
        auto res = cg::int_tuple(cg::int_tuple(0, 3), 0, cg::int_tuple(0, 3));
        EXPECT_EQ(sum(a, b), res);
        auto c = b;
        auto d = a;
        EXPECT_EQ(sum(c, d), res);
    }
    {
        // 2@2@1 + 6@2 must fail
        auto a = cg::scaled_basis({2, 1}, 2);
        auto b = cg::scaled_basis(2, 6);
        EXPECT_FALSE(cg::is_valid(sum(a, b)));
    }
    {
        using test_tuple = cg::rec_var<cg::static_int_t, cg::dynamic_t, cg::cg_error_t>;
        test_tuple tA(1, 2);
        test_tuple tB(3, 4);
        auto       tC = cg::arith_tuple_sum<test_tuple>(tA, tB);
        EXPECT_EQ(tC, test_tuple(4, 6));
    }
}

TEST(ScaledBasisTest, LayoutCoShape)
{
    using sb = cg::scaled_basis;
    auto l   = cg::layout(cg::shape(10, cg::shape(10, 10), 10),
                        cg::stride(sb(1, 1), cg::stride(sb(0, 1), sb(0, 10)), sb(2, 1)));
    // (9,(9,9),9) maps to (99,9,9)
    EXPECT_EQ(cg::static_cosize(l), 100 * 10 * 10);
}

TEST(ScaledBasisTest, LayoutComposition)
{
    {
        // Scaled basis elements present in the RHS
        auto a = cg::layout(cg::shape(4, 3, 5), cg::stride(3, 1, 12));

        auto b = cg::layout(cg::shape(2), cg::scaled_basis(1, 1));
        auto c = cg::layout(cg::shape(2), cg::scaled_basis(2, 1));
        auto d = cg::layout(cg::shape(2), cg::scaled_basis(2, 2));

        // Grab mode 1 of a, stride of 1*1
        auto aob = cg::layout(cg::shape(2), cg::stride(1));
        // Grab mode 2 of a, stride of 12*1
        auto aoc = cg::layout(cg::shape(2), cg::stride(12));
        // Grab mode 2 of a, stride of 12*2
        auto aod = cg::layout(cg::shape(2), cg::stride(24));

        EXPECT_EQ(composition(a, b), aob);
        EXPECT_EQ(composition(a, c), aoc);
        EXPECT_EQ(composition(a, d), aod);

        auto e = cg::layout(
            cg::shape(4, cg::shape(2, 3)),
            cg::stride(2, cg::stride(1, 8)));

        auto f = cg::layout(cg::shape(2), cg::scaled_basis({1, 1}, 2));
        auto g = cg::layout(cg::shape(2), cg::scaled_basis(1, 2));

        // Grab mode 1:1 of a which is 3:8, compose with 2:2
        auto eof = cg::layout(cg::shape(2), cg::stride(16));
        // Grab mode 1 of a which is (2,3):(1,8), compose with 2:2
        // Result obtained with pyCuTe is 2:8
        auto eog = cg::layout(cg::shape(2), cg::stride(8));
        EXPECT_EQ(composition(e, f), eof);
        EXPECT_EQ(composition(e, g), eog);
    }
    {
        // Scaled basis elements present in the LHS
        // Starts with a layout (512,64,2):(1@1,1@0,64@0) (layout taken from a CuTe-C++ example)
        // Compose with 16:1
        // This extracts the (logically) first 16 elements resulting in 16:1@1
        auto a = cg::layout(cg::shape(512, 64, 2),
                            cg::stride(cg::scaled_basis(1, 1),
                                       cg::scaled_basis(0, 1),
                                       cg::scaled_basis(0, 64)));
        auto b = cg::layout(cg::shape(16), cg::stride(1));
        EXPECT_EQ(composition(a, b),
                  cg::layout(cg::shape(16), cg::stride(cg::scaled_basis(1, 1))));
    }
}

TEST(ScaledBasisTest, LayoutAndCoordinateStatic)
{
    using sb = cg::scaled_basis;

    {
        // A coordinate congruent to the layout
        // (10,20,30):(1@0,1@1,20@1) at (1,2,3) = (1,62)
        auto l = cg::layout(
            cg::shape(10, 20, 30),
            cg::stride(sb(0, 1), sb(1, 1), sb(1, 20)));
        auto c = cg::coord(1, 2, 3);
        EXPECT_EQ(cg::layout_eval(c, l.shape(), l.stride()), cg::int_tuple(1, 62));
    }
    {
        // A coordinate not congruent to the layout
        // ((64,128),2):((1@0,1@1),64@1) at (65,1)
        auto l = cg::layout(
            cg::shape(cg::shape(64, 128), 2),
            cg::stride(cg::stride(sb(0, 1), sb(1, 1)), sb(1, 64)));
        auto c = cg::coord(65, 1);
        EXPECT_EQ(cg::layout_eval(c, l.shape(), l.stride()), cg::int_tuple(1, 65));
    }
    {
        // Same but further nested
        // ((64,128),2):((1@0@0,1@1),64@1) at (65,1)
        auto l = cg::layout(
            cg::shape(cg::shape(64, 128), 2),
            cg::stride(cg::stride(sb(0, 1), sb(1, 1)), sb(1, 64)));
        auto c = cg::coord(65, 1);
        EXPECT_EQ(cg::layout_eval(c, l.shape(), l.stride()), cg::int_tuple(cg::int_tuple(1), 65));
    }
    {
        // Slice and offset
        auto l = cg::layout(
            cg::shape(cg::shape(64, 128), 2),
            cg::stride(cg::stride(sb(0, 1), sb(1, 1)), sb(1, 64)));
        auto c1         = cg::coord(cg::coord(cg::_, cg::_), 1);
        auto c2         = cg::coord(cg::_, 1);
        auto [l1, off1] = cg::slice_and_offset(c1, l);
        auto [l2, off2] = cg::slice_and_offset(c2, l);
        EXPECT_EQ(l1, cg::layout(cg::shape(64, 128), cg::stride(sb(0, 1), sb(1, 1))));
        EXPECT_EQ(off1, cg::int_tuple(0, 64));
        // Note that l1 and l2 are not equal
        EXPECT_NE(l1, l2);
        EXPECT_EQ(off1, off2);
    }

    {
        // Strides mixing 0 and scaled basis elements for shape modes of extent 1
        cg::layout mA(cg::shape(cg::shape(64, 128), 1, 1, 2),
                      cg::stride(cg::stride(sb(1, 1), sb(0, 1)), 0, 0, sb(0, 64)));
        auto [l0, off0] = cg::slice_and_offset(cg::coord(0), mA);
        EXPECT_EQ(off0, cg::int_tuple(0, 0));
        auto [l1, off1] = cg::slice_and_offset(cg::coord(0, 0, 0, 1), mA);
        EXPECT_EQ(off1, cg::int_tuple(64, 0));
    }
    {
        // A test that caught incorrect tuple arithmetics
        auto l = cg::layout(cg::shape(cg::shape(128, 16), 1, 4),
                            cg::stride(cg::stride(64, 1), 0, 16));
        auto c = cg::layout_eval(cg::coord(cg::_, 0, 0), l);
        EXPECT_EQ(c, cg::int_tuple(0));
    }
    {
        // A test that caught incorrect handling of underscores when the
        // coordinate's profile is not natural
        auto l = cg::layout(
            cg::shape(cg::shape(cg::shape(128, 64), 1), 1),
            cg::stride(cg::stride(cg::stride(sb(0, 1), sb(1, 1)), sb(0, 1)), sb(0, 64)));
        auto c = cg::coord(cg::coord(cg::_, 0), 0);
        EXPECT_EQ(cg::int_tuple(0, 0), cg::layout_eval(c, l));
    }
}

TEST(ScaledBasisTest, LayoutAndCoordinateDynamic)
{
    using layout = cg::layout;
    using shape  = cg::shape;
    using stride = cg::stride;
    using coord  = cg::coord;
    using tuple  = cg::int_tuple;
    using sb     = cg::scaled_basis;
    using dyn_t  = cg::dynamic_t;

    {
        // A non-static coordinate
        auto l = layout(
            shape(10, 20, 30),
            stride(sb(0, 1), sb(1, 1), sb(1, 20)));
        auto c            = coord(dyn_t{}, 2, 3);
        auto tuple_offset = cg::layout_eval(c, l);
        EXPECT_FALSE(cg::is_static(tuple_offset));
        EXPECT_TRUE(cg::holds_vector(tuple_offset));
        EXPECT_FALSE(cg::is_static(tuple_offset[0]));
        EXPECT_TRUE(cg::is_static(tuple_offset[1]));
    }
    {
        // A non-static non-natural coordinate
        // This exercises dynamic conditionals in idx2crd_impl
        auto l = layout(
            shape(shape(10, 10), 20, 30),
            stride(stride(sb(0, 1), sb(0, 10)), sb(1, 1), sb(2, 1)));
        auto c            = coord(dyn_t{}, 2, 3);
        auto tuple_offset = cg::layout_eval(c, l);
        EXPECT_EQ(tuple_offset, tuple(dyn_t{}, 2, 3));
    }
    {
        // partition_A|B example in dynamic gemm kernel: slice_and_offset(static_coord, dynamic_layout)
        // coord:((0,(0,0)),(_,(_,_,_,_,_)))
        auto coord_test = coord(coord(0, coord(0, 0)), coord(cg::_, coord(cg::_, cg::_, cg::_, cg::_, cg::_)));
        auto shape_test = shape(shape(1, shape(1, 1)), shape(shape(128, 16), shape(1, 4, cg::dyn, cg::dyn, cg::dyn)));
        // layout:((1,(1,1)),((128,16),(1,4,?,?,?))):((0,(0,0)),((1@1,1@0),(0,16@0,128@1,64@0,1@2)))
        auto stride_test = stride(stride(0, stride(0, 0)), stride(stride(sb(1, 1), sb(0, 1)), stride(0, sb(0, 16), sb(1, 128), sb(0, 64), sb(2, 1))));
        auto lay_test    = layout(shape_test, stride_test);
        auto [s, o]      = cg::slice_and_offset(coord_test, lay_test);

        // ((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)
        auto ref_sliced_shape  = shape(shape(128, 16), 1, 4, cg::dyn, cg::dyn, cg::dyn);
        auto ref_sliced_stride = stride(stride(sb(1, 1), sb(0, 1)), 0, sb(0, 16), sb(1, 128), sb(0, 64), sb(2, 1));
        auto ref_sliced_lay    = layout(ref_sliced_shape, ref_sliced_stride);
        EXPECT_EQ(s, ref_sliced_lay);
        // (0, 0, 0)
        auto ref_offset = tuple(0, 0, 0);
        EXPECT_EQ(o, ref_offset);
    }
    {
        // partition_A|B example in dynamic gemm kernel: slice_and_offset(dynamic_coord, dynamic_layout)
        // coord:((0,(?,0)),(_,(_,?,_,_,?)))
        auto coord_test = coord(coord(0, coord(cg::dyn, 0)), coord(cg::_, coord(cg::_, cg::dyn, cg::_, cg::_, cg::dyn)));
        auto shape_test = shape(shape(1, shape(1, 1)), shape(shape(128, 16), shape(1, 4, cg::dyn, cg::dyn, cg::dyn)));
        // layout:((1,(1,1)),((128,16),(1,4,?,?,?))):((0,(0,0)),((1@1,1@0),(0,16@0,128@1,64@0,1@2)))
        auto stride_test = stride(stride(0, stride(0, 0)), stride(stride(sb(1, 1), sb(0, 1)), stride(0, sb(0, 16), sb(1, 128), sb(0, 64), sb(2, 1))));
        auto lay_test    = layout(shape_test, stride_test);
        auto [s, o]      = cg::slice_and_offset(coord_test, lay_test);

        // ((128,16),1,?,?):((1@1,1@0),0,128@1,64@0)
        auto ref_sliced_shape  = shape(shape(128, 16), 1, cg::dyn, cg::dyn);
        auto ref_sliced_stride = stride(stride(sb(1, 1), sb(0, 1)), 0, sb(1, 128), sb(0, 64));
        auto ref_sliced_lay    = layout(ref_sliced_shape, ref_sliced_stride);
        EXPECT_EQ(s, ref_sliced_lay);
        // (?, 0, ?)
        auto ref_offset = tuple(cg::dynamic_t{}, 0, cg::dyn);
        EXPECT_EQ(o, ref_offset);
    }
    {
        // partition_S example in dynamic gemm kernel: layout_eval(static_coord, dynamic_layout)
        auto shape_test  = shape(shape(128, 16), 1, 4, cg::dyn, cg::dyn, cg::dyn);
        auto stride_test = stride(stride(sb(1, 1), sb(0, 1)), 0, sb(0, 16), sb(1, 128), sb(0, 64), sb(2, 1));
        // ((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)
        auto lay_test = layout(shape_test, stride_test);
        auto idx      = cg::layout_eval(coord(0), lay_test);

        // (0, 0, 0)
        auto ref_idx = tuple(0, 0, 0);
        EXPECT_EQ(idx, ref_idx);
    }
    {
        // partition_S example in dynamic gemm kernel: layout_eval(dynamic_coord, dynamic_layout)
        auto shape_test  = shape(shape(128, 16), 1, 4, cg::dyn, cg::dyn, cg::dyn);
        auto stride_test = stride(stride(sb(1, 1), sb(0, 1)), 0, sb(0, 16), sb(1, 128), sb(0, 64), sb(2, 1));
        // ((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)
        auto lay_test = layout(shape_test, stride_test);
        auto idx      = cg::layout_eval(coord(cg::dyn), lay_test);

        // (?, ?, ?)
        auto ref_idx = tuple(cg::dyn, cg::dyn, cg::dyn);
        EXPECT_EQ(idx, ref_idx);
    }
}

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

TEST(ScaledBasisTest, IntegerRatio)
{
    using shape        = cg::shape;
    using stride       = cg::stride;
    using scaled_basis = cg::scaled_basis;
    using ratio        = cg::ratio;

    shape  sh(4, 5);
    stride d(6, scaled_basis(1, 1));
    EXPECT_TRUE(cg::is_static(d));
    EXPECT_EQ(mul<shape>(sh, d), shape(24, shape(0, 5)));

    // Multiplication of scaled basis with a ratio: 5 * 1/5 = 1
    // (scalar multiplication does ratio reduction automatically)
    stride dr(6, scaled_basis(1, ratio(1, 5)));
    EXPECT_EQ(mul<shape>(sh, dr), shape(24, shape(0, 1)));

    // Multiplication of scaled basis with a ratio: 5 * 1/4 = 5/4
    // Since the ratio can't currently be represented by a shape, we expect an
    // error in the output.
    stride derr(6, scaled_basis(1, ratio(1, 4)));
    EXPECT_TRUE(cg::has_error(mul<shape>(sh, derr)));

    // The integer ratio implementation forces the following ratios to
    // zero when reducing during multiplication:
    // X / 0 = 0
    // 0 / 0 = 0
    // 0 / X = 0
    stride dz0(6, scaled_basis(1, ratio(1, 0)));
    EXPECT_EQ(mul<shape>(sh, dz0), shape(24, shape(0, 0)));
    stride dz1(7, scaled_basis(1, ratio(0, 0)));
    EXPECT_EQ(mul<shape>(sh, dz1), shape(28, shape(0, 0)));
    stride dz2(8, scaled_basis(1, ratio(0, 1)));
    EXPECT_EQ(mul<shape>(sh, dz2), shape(32, shape(0, 0)));
}
