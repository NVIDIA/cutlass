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
#include <cstdint>
#include <numeric>
#include <optional>
#include <stddef.h>
#include <string>
#include <type_traits>
#include <utility>
#include <variant>
#include <vector>

#include "cutegen/cg_error.hpp"
#include "cutegen/cutegen.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"
#include "cutegen/dynamic.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/rec_var_algorithms.hpp"
#include "cutegen/swizzle.hpp"
#include "cutegen/underscore.hpp"
#include "cutegen/literals.hpp"

#include "gtest/gtest.h"

#include "utils.hpp"

namespace cg = cutegen;
using cg::operator""_lay;

////////////////////////////////////////////////////////////////////////
// LayoutTest.Basic
TEST(LayoutTest, Basic)
{
    // 8 rows, 4 columns
    cg::layout l0(cg::shape(8, 4), cg::gen_col_major());
    EXPECT_EQ(l0, cg::layout(cg::shape(8, 4), cg::stride(1, 8)));
    EXPECT_EQ(2, cg::rank(l0));

    // Instantiate with an integer, defaults to column-major strides
    cg::layout l1(5);
    EXPECT_EQ(l1, cg::layout(cg::shape(5), cg::stride(1)));

    // Create a layout by combining modes from two or more layouts
    cg::layout l2(cg::shape(2, 4, 6), cg::stride(1, 2, 8));
    cg::layout l3(cg::shape(8, 10), cg::stride(48, 384));
    cg::layout l4(l2, l3);
    // l4 = ((2,4,6),(8,10)):((1,2,8),(48,384))
    EXPECT_EQ(l4, cg::layout(cg::shape(cg::shape(2, 4, 6), cg::shape(8, 10)), //
                             cg::stride(cg::stride(1, 2, 8), cg::stride(48, 384))));

    // get sub-layout
    cg::layout l5 = cg::get(l4, 0);
    cg::layout l6 = cg::get(l4, 1);
    EXPECT_EQ(l5, l2);
    EXPECT_EQ(l6, l3);
    std::array<size_t, 2> idx0 = {0, 2};
    EXPECT_EQ(cg::get(l4, idx0), cg::layout(cg::shape(6), cg::stride(8)));
    EXPECT_EQ(cg::get(l4, 0, 2), cg::layout(cg::shape(6), cg::stride(8)));
    std::array<size_t, 1> idx1 = {1};
    EXPECT_EQ(cg::get(l4, idx1), cg::layout(cg::shape(8, 10), cg::stride(48, 384)));
    std::vector<size_t> idx2; // empty
    cg::layout          l7 = cg::get(l4, idx2);
    EXPECT_EQ(l7, l4);

    //select sub-layout
    //l4 = ((2,4,6),(8,10)):((1,2,8),(48,384))
    std::array<size_t, 2> idx3 = {0, 1};
    EXPECT_EQ(cg::select(l4, idx3), l4);
    EXPECT_EQ(cg::rank(cg::select(l4, idx2)), 0); // idx2 is an empty array
    EXPECT_EQ(cg::select(l4, 0, 1), l4);
    EXPECT_EQ(cg::get(cg::select(l4, 0), 0), cg::layout(cg::shape(2, 4, 6), cg::stride(1, 2, 8)));
    EXPECT_EQ(cg::get(cg::select(l4, idx1), 0), cg::layout(cg::shape(8, 10), cg::stride(48, 384)));
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.TypeCanHoldDynamic
TEST(LayoutTest, TypeCanHoldDynamic)
{
    static_assert(cg::type_can_hold_dynamic_int<cg::layout>::value);
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.HasError
TEST(LayoutTest, HasError)
{
    {
        auto l = cg::from_string<cg::layout>(std::string("(2,3):(1,2)"));
        ASSERT_TRUE(l.has_value());
        EXPECT_FALSE(cg::has_error(l.value()));
    }
    {
        auto l = cg::from_string<cg::layout>(std::string("(2,3):(x,2)"));
        ASSERT_TRUE(l.has_value());
        EXPECT_TRUE(cg::has_error(l.value()));
    }
    {
        auto l = cg::from_string<cg::layout>(std::string("(x,3):(1,2)"));
        ASSERT_TRUE(l.has_value());
        EXPECT_TRUE(cg::has_error(l.value()));
    }
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.IsValid
TEST(LayoutTest, IsValid)
{
    {
        auto l = cg::layout(cg::shape(cg::cg_error_t{}), cg::stride(1));
        EXPECT_FALSE(cg::is_valid(l));
    }
    {
        auto l = cg::layout(cg::shape(2), cg::stride(cg::cg_error_t{}));
        EXPECT_FALSE(cg::is_valid(l));
    }
    {
        auto l = cg::layout(cg::shape(cg::shape(2, cg::cg_error_t{}), 3),
                            cg::stride(cg::stride(1, 2), 3));
        EXPECT_FALSE(cg::is_valid(l));
    }
    {
        auto l = cg::layout(cg::shape(2), cg::stride(2));
        EXPECT_TRUE(cg::is_valid(l));
    }
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.Validate
TEST(LayoutTest, Validate)
{
    // shape and stride must be congruent so constructing ((2,3),4):(1,2,6)
    // should result in an invalid layout with an error
    auto l = cg::layout(cg::shape(cg::shape(2, 3), 4),
                        cg::stride(1, 2, 6));
    EXPECT_FALSE(cg::is_valid(l));
    EXPECT_TRUE(cg::has_error(l));
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.CompactStrideGeneration
TEST(LayoutTest, CompactStrideGeneration)
{
    {
        auto s   = cg::from_string<cg::shape>("(2,(3,4),5)").value();
        auto o   = cg::from_string<cg::shape>("1").value();
        auto res = cg::from_string<cg::stride>("(1,(2,6),24)").value();
        EXPECT_EQ(cg::compact_order<cg::stride>(s, o), res);
    }
    {
        auto s   = cg::from_string<cg::shape>("5").value();
        auto o   = cg::from_string<cg::shape>("1").value();
        auto res = cg::from_string<cg::stride>("1").value();
        EXPECT_EQ(cg::compact_order<cg::stride>(s, o), res);
    }
    {
        auto s   = cg::from_string<cg::shape>("(2,(3,4),5)").value();
        auto o   = cg::from_string<cg::shape>("(1,(3,2),4)").value();
        auto res = cg::from_string<cg::stride>("(1,(8,2),24)").value();
        EXPECT_EQ(cg::compact_order<cg::stride>(s, o), res);
    }
    {
        auto s   = cg::from_string<cg::shape>("(2,(3,4),5)").value();
        auto o   = cg::from_string<cg::shape>("(1,5,4)").value();
        auto res = cg::from_string<cg::stride>("(1,(10,30),2)").value();
        EXPECT_EQ(cg::compact_order<cg::stride>(s, o), res);
    }
    {
        auto s   = cg::from_string<cg::shape>("(2,(3,(4,5)),6)").value();
        auto o   = cg::from_string<cg::shape>("(1,(3,2),4)").value();
        auto res = cg::from_string<cg::stride>("(1,(40,(2,8)),120)").value();
        EXPECT_EQ(cg::compact_order<cg::stride>(s, o), res);
    }
    {
        auto s   = cg::from_string<cg::shape>("(2,(3,4),5)").value();
        auto o   = cg::from_string<cg::shape>("(?,(3,?),4)").value();
        auto res = cg::from_string<cg::stride>("(15,(1,30),3)").value();
        EXPECT_EQ(cg::compact_order<cg::stride>(s, o), res);
    }
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.Idx2Crd
TEST(LayoutTest, Idx2Crd)
{
    // 8 rows, 4 columns
    cg::layout l0(cg::shape(8, 4), cg::gen_col_major());

    // Test calling idx2crd with a bare integer
    auto crd = cg::idx2crd(21, l0.shape(), l0.stride());
    EXPECT_EQ(crd, cg::coord(5, 2));
    // Test calling idx2crd with a tuple
    auto crd2 = cg::idx2crd(cg::int_tuple(21), l0.shape(), l0.stride());
    EXPECT_EQ(crd, cg::coord(5, 2));

    // Test calling idx2crd with a tuple and a shape
    auto crd3 = cg::idx2crd(cg::int_tuple(21), l0.shape());
    EXPECT_EQ(crd3, cg::coord(5, 2));

    // Test calling idx2crd with a bare integer and a shape
    auto crd4 = cg::idx2crd(21, l0.shape());
    EXPECT_EQ(crd4, cg::coord(5, 2));

    cg::layout l1(cg::shape(8, cg::dynamic_t{}), cg::gen_col_major());
    auto       crd5 = cg::idx2crd(21, l1.shape());
    EXPECT_EQ(crd5, cg::coord(5, 2));

    // mixed dynamic shape
    cg::layout l2(cg::shape(cg::dynamic_t{}, cg::shape(8, cg::dynamic_t{})),
                  cg::gen_col_major());
    auto       crd6 = cg::idx2crd(cg::int_tuple(4, 5), l2.shape());
    EXPECT_EQ(crd6, cg::coord(4, cg::coord(5, 0)));

    cg::layout l3(cg::shape(cg::dynamic_t{}, cg::shape(cg::dynamic_t{}, 8)),
                  cg::gen_col_major());
    auto       crd7 = cg::idx2crd(cg::int_tuple(4, 5), l3.shape());
    EXPECT_EQ(crd7, cg::coord(4, cg::coord(cg::dynamic_t{}, cg::dynamic_t{})));

    // Test with higher rank and dynamic entries in result coordinate
    cg::layout l4(cg::shape(cg::dynamic_t{}, cg::dynamic_t{}),
                  cg::gen_col_major());
    auto       crd8 = cg::idx2crd(21, l4.shape());
    EXPECT_EQ(crd8, cg::coord(cg::dynamic_t{}, cg::dynamic_t{}));
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.LayoutEval
TEST(LayoutTest, LayoutEval)
{
    // clang-format off
    cg::layout hier_layout(cg::shape(8, cg::shape(2, 2)),
                           cg::stride(2, cg::stride(1, 16)));
    EXPECT_EQ(18, cg::layout_eval(cg::coord(17),
                              hier_layout.shape(),
                              hier_layout.stride()));
    EXPECT_EQ(18, cg::layout_eval(cg::coord(1, 2),
                              hier_layout.shape(),
                              hier_layout.stride()));
    EXPECT_EQ(18, cg::layout_eval(cg::coord(1, cg::coord(0, 1)),
                              hier_layout.shape(),
                              hier_layout.stride()));

    cg::layout morton3(cg::shape(cg::shape(2, cg::shape(2, 2)),
                                 cg::shape(2, cg::shape(2, 2))),
                       cg::stride(cg::stride(1, cg::stride(4, 16)),
                                  cg::stride(2, cg::stride(8, 32))));
    EXPECT_EQ(49, cg::layout_eval(cg::coord(37),
                              morton3.shape(),
                              morton3.stride()));
    EXPECT_EQ(49, cg::layout_eval(cg::coord(5, 4),
                              morton3.shape(),
                              morton3.stride()));
    EXPECT_EQ(49, cg::layout_eval(cg::coord(cg::coord(1, 2), cg::coord(0, 2)),
                              morton3.shape(),
                              morton3.stride()));
    EXPECT_EQ(49, cg::layout_eval(cg::coord(cg::coord(1, cg::coord(0, 1)),
                                        cg::coord(0, cg::coord(0, 1))),
                              morton3.shape(),
                              morton3.stride()));

    // underscore "behaves" like 0 for the use cases below
    // It actually behaves like {}
    using cg::_;

    EXPECT_EQ(cg::layout_eval(cg::coord(cg::coord(0, 3)), morton3),
              cg::layout_eval(cg::coord(cg::coord(_, 3)), morton3));

    EXPECT_EQ(cg::layout_eval(cg::coord(cg::coord(1, 0)), morton3),
              cg::layout_eval(cg::coord(cg::coord(1, _)), morton3));

    EXPECT_EQ(cg::layout_eval(cg::coord(cg::coord(1, cg::coord(1, 0)), 0), morton3),
              cg::layout_eval(cg::coord(cg::coord(1, cg::coord(1, 0)), _), morton3));

    EXPECT_EQ(cg::layout_eval(cg::coord(cg::coord(1, cg::coord(1, 1)), cg::coord(0, 0)), morton3),
              cg::layout_eval(cg::coord(cg::coord(1, cg::coord(1, 1)), cg::coord(0, _)), morton3));

    EXPECT_EQ(cg::layout_eval(cg::coord(cg::coord(0, cg::coord(1, 1)), cg::coord(1, 0)), morton3),
              cg::layout_eval(cg::coord(cg::coord(_, cg::coord(1, 1)), cg::coord(1, _)), morton3));

    EXPECT_EQ(cg::layout_eval(cg::coord(cg::coord(0, cg::coord(0, 1)), cg::coord(0, 0)), morton3),
              cg::layout_eval(cg::coord(cg::coord(_, cg::coord(_, 1)), cg::coord(_, _)), morton3));
    // clang-format on

    {
        // Out-of-bound accesses
        // l = (4,3):(3,1) of size 12
        // 12 -> (0,3) (natural coordinate) -> 3
        // (5,5) -> dot with the stride -> 20
        cg::layout l(cg::shape(4, 3), cg::stride(3, 1));
        auto       idx0 = cg::layout_eval(cg::coord(12), l);
        auto       idx1 = cg::layout_eval(cg::coord(5, 5), l);
        EXPECT_EQ(idx0, 3);
        EXPECT_EQ(idx1, 20);
    }
    {
        // l1 = (4,3,2):(3,1,0)
        // Verify behavior of idx2crd and layout_eval when there is a mode like 2:0 (stride = static-0
        // and shape != static-1)
        cg::layout l(cg::shape(4, 3, 2), cg::stride(3, 1, 0));
        auto       idx0 = cg::layout_eval(cg::coord(11), l);
        auto       idx1 = cg::layout_eval(cg::coord(12), l);
        EXPECT_EQ(idx0, 11);
        EXPECT_EQ(idx1, 0);
    }
}

TEST(LayoutTest, AdvancedLayoutEval)
{
    auto l  = cg::layout(cg::shape(cg::shape(2, 3), 4, 5),
                        cg::stride(cg::stride(60, 20), 1, 4));
    auto hc = cg::idx2crd(117, l.shape(), l.stride());
    EXPECT_EQ(l(hc), 117);
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.Size
TEST(LayoutTest, Size)
{
    auto l = cg::layout(cg::shape(2, cg::shape(3, 4), cg::shape(5, 6, cg::shape(7)), 8));
    EXPECT_EQ(cg::static_size(l), 40320);
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.CoSize
TEST(LayoutTest, CoSize)
{
    // Test for 'cosize(layout)'
    {
        auto l = cg::layout(cg::shape(10, cg::shape(10, 10), 10),
                            cg::stride(10, cg::stride(1, 200), 2000));
        EXPECT_EQ(cg::cosize(l), 9 * (1 + 10 + 200 + 2000) + 1);
    }
    // Test for 'static_cosize(layout)'
    {
        auto l = cg::layout(cg::shape(10, cg::shape(10, 10), 10),
                            cg::stride(10, cg::stride(1, 200), 2000));
        EXPECT_EQ(cg::static_cosize(l), 9 * (1 + 10 + 200 + 2000) + 1);
    }
    // Test with a layout that has negative strides
    {
        auto l = cg::layout(cg::shape(10, cg::shape(10, 10), 10),
                            cg::stride(-10, cg::stride(1, 200), 2000));
        EXPECT_EQ(cg::static_cosize(l), 9 * (1 + 10 + 200 + 2000) + 1);
    }
    // Test for 'cosize(layout, iterable)' where iterable is a vector
    {
        auto l = cg::layout(cg::shape(10, cg::shape(10, 10), 10),
                            cg::stride(10, cg::stride(1, 200), 2000));
        EXPECT_EQ(cg::cosize(l, std::vector<int>{1, 1}), 9 * 200 + 1);
    }
    // Test for 'static_cosize(layout, iterable)' where iterable is a vector
    {
        auto l = cg::layout(cg::shape(10, cg::shape(10, 10), 10),
                            cg::stride(10, cg::stride(1, 200), 2000));
        EXPECT_EQ(cg::static_cosize(l, std::vector<int>{1, 1}), 9 * 200 + 1);
    }
    // Test for 'cosize(layout, iterable)' where iterable is an array
    {
        auto l = cg::layout(cg::shape(10, cg::shape(10, 10), 10),
                            cg::stride(10, cg::stride(1, 200), 2000));
        EXPECT_EQ(cg::cosize(l, std::array<int, 1>{1}), 9 * (1 + 200) + 1);
    }
    // Test for 'static_cosize(layout, iterable)' where iterable is an array
    {
        auto l = cg::layout(cg::shape(10, cg::shape(10, 10), 10),
                            cg::stride(10, cg::stride(1, 200), 2000));
        EXPECT_EQ(cg::static_cosize(l, std::array<int, 1>{1}), 9 * (1 + 200) + 1);
    }
}

TEST(LayoutTest, Append)
{
    // Append to larger rank
    {
        cg::layout a(cg::shape(10, cg::shape(10, 10), 10),
                     cg::stride(10, cg::stride(1, 200), 2000));
        cg::layout b(cg::shape(5), cg::stride(1));

        auto c = cg::append_to_rank_N(5, a, b);

        EXPECT_EQ(c, "(10,(10,10),10,5,5):(10,(1,200),2000,1,1)"_lay);
    }

    // Append to same rank
    {
        cg::layout a(cg::shape(10, cg::shape(10, 10), 10),
                     cg::stride(10, cg::stride(1, 200), 2000));
        cg::layout b(cg::shape(5), cg::stride(1));

        auto c = cg::append_to_rank_N(3, a, b);

        EXPECT_EQ(c, "(10,(10,10),10):(10,(1,200),2000)"_lay);
    }

    // Append to smaller rank
    {
        cg::layout a(cg::shape(10, cg::shape(10, 10), 10),
                     cg::stride(10, cg::stride(1, 200), 2000));
        cg::layout b(cg::shape(5), cg::stride(1));

        auto c = cg::append_to_rank_N(2, a, b);

        EXPECT_EQ(c, "(10,(10,10),10):(10,(1,200),2000)"_lay);
    }
}

TEST(LayoutTest, Prepend)
{
    // Prepend to larger rank
    {
        cg::layout a(cg::shape(10, cg::shape(10, 10), 10),
                     cg::stride(10, cg::stride(1, 200), 2000));
        cg::layout b(cg::shape(5), cg::stride(1));

        auto c = cg::prepend_to_rank_N(5, a, b);

        EXPECT_EQ(c, "(5,5,10,(10,10),10):(1,1,10,(1,200),2000)"_lay);
    }

    // Prepend to same rank
    {
        cg::layout a(cg::shape(10, cg::shape(10, 10), 10),
                     cg::stride(10, cg::stride(1, 200), 2000));
        cg::layout b(cg::shape(5), cg::stride(1));

        auto c = cg::prepend_to_rank_N(3, a, b);

        EXPECT_EQ(c, "(10,(10,10),10):(10,(1,200),2000)"_lay);
    }

    // Prepend to smaller rank
    {
        cg::layout a(cg::shape(10, cg::shape(10, 10), 10),
                     cg::stride(10, cg::stride(1, 200), 2000));
        cg::layout b(cg::shape(5), cg::stride(1));

        auto c = cg::prepend_to_rank_N(2, a, b);

        EXPECT_EQ(c, "(10,(10,10),10):(10,(1,200),2000)"_lay);
    }
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.FromString
TEST(LayoutTest, FromString)
{
    // Test from_string with integer shape and stride
    {
        auto optLayout = cg::from_string<cg::layout>(std::string("8:2"));
        EXPECT_TRUE(optLayout.has_value());
        EXPECT_EQ(cg::layout(cg::shape(8), cg::stride(2)), optLayout.value());
    }
    // Test from_string() with explicit shape and stride
    {
        auto optLayout = cg::from_string<cg::layout>(std::string("(8, 4):(1, 8)"));
        EXPECT_TRUE(optLayout.has_value());
        EXPECT_EQ(cg::layout(cg::shape(8, 4), cg::stride(1, 8)), optLayout.value());
    }
    // Test from_string() with explicit shape only (no stride --> col_major)
    {
        auto optLayout = cg::from_string<cg::layout>(std::string("(8, 4)"));
        EXPECT_TRUE(optLayout.has_value());
        EXPECT_EQ(cg::layout(cg::shape(8, 4), cg::stride(1, 8)), optLayout.value());
    }
    // Test from_string() with an invalid strings
    {
        EXPECT_FALSE(cg::from_string<cg::layout>(std::string(":(8,4)")).has_value());
        EXPECT_FALSE(cg::from_string<cg::layout>(std::string("(8,4)::(1,8)")).has_value());
        EXPECT_FALSE(cg::from_string<cg::layout>(std::string("(8,4):(1,8):")).has_value());
        // no offset:
        EXPECT_FALSE(cg::from_string<cg::layout>(std::string("S<0,0,0> o (8,4):(1,8):")).has_value());
    }
    // Test from_string() with scaled basis elements
    {
        std::string lstr("(((64,128),1),1,1,(2)):(((1@0,1@1),0),0,0,(64@0))");
        auto        optLayout = cg::from_string<cg::layout>(lstr);
        EXPECT_TRUE(optLayout.has_value());
        EXPECT_EQ(cg::to_string(optLayout.value()), lstr);
    }
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.Codec
TEST(LayoutTest, Codec)
{
    // Verify that the encode/decode round trip returns the same as the
    // input.
    EXPECT_TRUE(test_codec(cg::layout(cg::shape(2, 4, 6), cg::stride(1, 2, 8))));
    EXPECT_TRUE(test_codec(cg::layout(cg::shape(cg::shape(2, 4, 6), cg::shape(8, 10)),
                                      cg::stride(cg::stride(1, 2, 8), cg::stride(48, 384)))));
    // Verify failure on invalid buffers
    {
        std::vector<char> buffer;
        cg::encode(buffer, cg::layout(cg::shape(2, 4, 6), cg::stride(1, 2, 8)));
        buffer.resize(buffer.size() - 16);
        auto dec = cg::decode<cg::layout>(buffer);
        EXPECT_FALSE(dec.has_value());
    }
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.slice_and_offset
TEST(LayoutTest, SliceAndOffset)
{
    {
        auto l0       = cg::layout(cg::shape(2, 4, 6), cg::stride(1, 2, 8));
        auto c0       = cg::coord(0, 1, 2);
        auto [s0, o0] = cg::slice_and_offset(c0, l0);

        EXPECT_EQ(cg::slice(c0, l0.shape()), s0.shape());
        EXPECT_EQ(cg::slice(c0, l0.stride()), s0.stride());
        EXPECT_EQ(cg::layout_eval(c0, l0.shape(), l0.stride()), o0);
    }

    {
        auto l0       = cg::layout(cg::shape(3, 4), cg::stride(1, 3));
        auto c0       = cg::coord(0, 1);
        auto [s0, o0] = cg::slice_and_offset(c0, l0);

        EXPECT_EQ(cg::slice(c0, l0.shape()), s0.shape());
        EXPECT_EQ(cg::slice(c0, l0.stride()), s0.stride());
        EXPECT_EQ(cg::layout_eval(c0, l0.shape(), l0.stride()), o0);
    }

    {
        // clang-format off
        auto l0       = cg::layout(cg::shape(2, 3, cg::shape(4, 5)),
                                   cg::stride(1, 2, cg::stride(6, 24)));
        // clang-format on
        auto c0       = cg::coord(0, 1, cg::coord(2, 3));
        auto [s0, o0] = cg::slice_and_offset(c0, l0);

        EXPECT_EQ(cg::slice(c0, l0.shape()), s0.shape());
        EXPECT_EQ(cg::slice(c0, l0.stride()), s0.stride());
        EXPECT_EQ(cg::layout_eval(c0, l0.shape(), l0.stride()), o0);
    }

    {
        auto l0       = cg::layout(cg::shape(5), cg::stride(1));
        auto c0       = cg::coord(3);
        auto [s0, o0] = cg::slice_and_offset(c0, l0);

        EXPECT_EQ(cg::slice(c0, l0.shape()), s0.shape());
        EXPECT_EQ(cg::slice(c0, l0.stride()), s0.stride());
        EXPECT_EQ(cg::layout_eval(c0, l0.shape(), l0.stride()), o0);
    }
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.slice_and_offset
TEST(LayoutTest, DomainOffset)
{
    {
        auto l0       = cg::layout(cg::shape(2, 4, 6), cg::stride(1, 2, 8));
        auto c0       = cg::coord(0, 1, 2);
        auto [l, off] = cg::domain_offset(c0, l0);

        EXPECT_EQ(l0, l);
        EXPECT_EQ(l0(c0), off);
    }

    {
        auto l0       = cg::layout(cg::shape(2, cg::shape(4, 6)), cg::stride(1, cg::stride(2, 8)));
        auto c0       = cg::coord(0, 1, 2);
        auto [l, off] = cg::domain_offset(c0, l0);

        EXPECT_EQ(l0, l);
        EXPECT_EQ(l0(c0), off);
    }
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.FindLayoutInRecVar
TEST(LayoutTest, FindLayoutInRecVar)
{
    static_assert(cg::is_layout<cg::layout>::value);
    static_assert(!cg::is_layout<cg::int_tuple>::value);

    // rv_t defined here is expected to be similar/identical to a
    // recursive variant that represents a CuTe tile.
    using rv_t          = cg::rec_var<int, cg::layout, cg::dynamic_t, cg::underscore_t>;
    const size_t lIndex = cg::find_layout_in_rec_var<rv_t>::index;
    EXPECT_EQ(lIndex, 1);
    static_assert(std::is_same_v<std::tuple_element_t<lIndex, rv_t::elem_types_t>,
                                 cg::layout>);
    static_assert(std::is_same_v<cg::find_layout_in_rec_var<rv_t>::value,
                                 cg::layout>);
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.Upcast
TEST(LayoutTest, Upcast)
{
    auto l0 = cg::from_string<cg::layout>(std::string("8:2"));
    EXPECT_TRUE(l0.has_value());
    EXPECT_EQ(cg::layout(cg::shape(4), cg::stride(1)), cg::upcast(4, l0.value()));

    auto l1 = cg::from_string<cg::layout>(std::string("8:4"));
    EXPECT_TRUE(l1.has_value());
    EXPECT_EQ(cg::layout(cg::shape(8), cg::stride(2)), cg::upcast(2, l1.value()));

    auto l2        = cg::from_string<cg::layout>(std::string("((5, 6), 8):((8, 4), 1)"));
    auto l2_upcast = cg::from_string<cg::layout>(std::string("((5, 6), 4):((4, 2), 1)"));
    EXPECT_TRUE(l2.has_value());
    EXPECT_TRUE(l2_upcast.has_value());
    EXPECT_EQ(l2_upcast.value(), cg::upcast(2, l2.value()));

    auto l3        = cg::from_string<cg::layout>(std::string("((5, 6), 8):((8, 0), 1)"));
    auto l3_upcast = cg::from_string<cg::layout>(std::string("((5, 6), 4):((4, 0), 1)"));
    EXPECT_TRUE(l3.has_value());
    EXPECT_TRUE(l3_upcast.has_value());
    EXPECT_EQ(l3_upcast.value(), cg::upcast(2, l3.value()));

    // (?,32):(?,1) --4--> (?,8):(?,1)
    auto l4_dyn        = cg::layout(cg::shape(cg::dynamic_t{}, 32), cg::stride(cg::dynamic_t{}, 1));
    auto l4_dyn_upcast = cg::layout(cg::shape(cg::dynamic_t{}, 8), cg::stride(cg::dynamic_t{}, 1));
    EXPECT_EQ(l4_dyn_upcast, cg::upcast(4, l4_dyn));

    // Negative and zero values for the cast factor are not allowed.
    EXPECT_FALSE(cg::is_valid(cg::upcast(-1, l4_dyn)));
    EXPECT_FALSE(cg::is_valid(cg::upcast(0, l4_dyn)));
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.Downcast
TEST(LayoutTest, Downcast)
{
    auto l0 = cg::from_string<cg::layout>(std::string("8:1")).value();
    EXPECT_EQ(cg::layout(cg::shape(16), cg::stride(1)), cg::downcast(2, l0));

    // auto l1 = cg::from_string<cg::layout>(std::string("8:2")).value();
    // EXPECT_EQ(cg::layout(cg::shape(8), cg::stride(2)), cg::downcast(2, l1));

    auto l2          = cg::from_string<cg::layout>(std::string("((5, 6),  8):(( 8, 4), 1)")).value();
    auto l2_downcast = cg::from_string<cg::layout>(std::string("((5, 6), 16):((16, 8), 1)")).value();
    EXPECT_EQ(l2_downcast, cg::downcast(2, l2));

    // (?,32):(?,1) --2--> (?,64):(?,1)
    auto l3_dyn          = cg::layout(cg::shape(cg::dynamic_t{}, 32), cg::stride(cg::dynamic_t{}, 1));
    auto l3_dyn_downcast = cg::layout(cg::shape(cg::dynamic_t{}, 64), cg::stride(cg::dynamic_t{}, 1));
    EXPECT_EQ(l3_dyn_downcast, cg::downcast(2, l3_dyn));

    // Negative and zero values for the cast factor are not allowed.
    EXPECT_FALSE(cg::is_valid(cg::downcast(-1, l3_dyn)));
    EXPECT_FALSE(cg::is_valid(cg::downcast(0, l3_dyn)));
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.Recast
#ifndef int24_t
struct alignas(1) int24_t
{
    int8_t data[3];
};
#endif
TEST(LayoutTest, Recast)
{
    auto l0           = cg::from_string<cg::layout>(std::string("(32,16,8):(1,256,32)")).value();
    auto l_f16_to_f32 = cg::recast<int16_t, int32_t>(l0);
    EXPECT_EQ(cg::layout(cg::shape(16, 16, 8), cg::stride(1, 128, 16)), l_f16_to_f32);
    auto l_f16_to_f8 = cg::recast<int16_t, int8_t>(l0);
    EXPECT_EQ(cg::layout(cg::shape(64, 16, 8), cg::stride(1, 512, 64)), l_f16_to_f8);
    auto l_i24_to_i64 = cg::recast<int24_t, int64_t>(l0);
    EXPECT_EQ(cg::layout(cg::shape(12, 16, 8), cg::stride(1, 96, 12)), l_i24_to_i64);
    auto l_i24_to_i64_2 = cg::recast(/*new_type_bits = */ sizeof(int64_t) * 8,
                                     /*old_type_bits = */ sizeof(int24_t) * 8,
                                     l0);
    EXPECT_EQ(cg::layout(cg::shape(12, 16, 8), cg::stride(1, 96, 12)), l_i24_to_i64_2);
}

TEST(LayoutTest, CountDynamicScalars)
{
    {
        auto lay = cg::from_string<cg::layout>(std::string("(1,3,(2,?)):(?,1,(?,1))"));
        EXPECT_EQ(cg::scalar_count(lay.value(), /*dynamicOnly=*/true), 3);
        EXPECT_EQ(cg::scalar_count(lay.value()), 8);
    }
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.ExclusiveScan
// On "old" compilers with C++ standard libraries that don't support
// std::exclusive_scan(), we implement our own.
TEST(LayoutTest, ExclusiveScan)
{
    std::array<int, 10> a = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    std::vector<int>    b(10, 0);
    cg::detail::exclusive_scan(a.begin(), a.end(), b.begin(), 5, std::plus<>{});
    EXPECT_EQ(b[0], 5);  // 5
    EXPECT_EQ(b[1], 6);  // 5 + 1
    EXPECT_EQ(b[2], 8);  // 6 + 2
    EXPECT_EQ(b[3], 11); // 8 + 3
    EXPECT_EQ(b[4], 15); // 11 + 4
    EXPECT_EQ(b[5], 20); // 15 + 5
    EXPECT_EQ(b[6], 26); // 20 + 6
    EXPECT_EQ(b[7], 33); // 26 + 7
    EXPECT_EQ(b[8], 41); // 33 + 8
    EXPECT_EQ(b[9], 50); // 41 + 9
}

TEST(LayoutTest, MaxAlignment)
{
    {
        auto lay = *cg::from_string<cg::layout>("(1,8):(1,1)");
        EXPECT_EQ(8, cg::max_alignment(lay));
    }

    {
        // verify nested gcd
        auto lay = *cg::from_string<cg::layout>("(4,2,(8,2)):(512,1,(8,8192))");
        EXPECT_EQ(2, cg::max_alignment(lay));
    }

    {
        auto lay = *cg::from_string<cg::layout>("((1,(2))):((1,(0)))");
        EXPECT_EQ(1, cg::max_alignment(lay));
    }

    {
        auto lay = *cg::from_string<cg::layout>("(8,16):(1,4)");
        EXPECT_EQ(4, cg::max_alignment(lay));
    }

    {
        auto lay = *cg::from_string<cg::composed_layout>(std::string("(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)"));
        EXPECT_EQ(1, cg::max_alignment(lay));
    }

    {
        auto lay = *cg::from_string<cg::composed_layout>(std::string("S<3,4,4> o 0 o (32,1):(1,32)"));
        EXPECT_EQ(16, cg::max_alignment(lay));
    }
}

TEST(LayoutTest, MakeLayoutLike)
{
    {
        cg::layout lay(cg::shape(2, 2, 2, 2), cg::stride(0, 2, 4, 1));
        cg::layout target(cg::shape(2, 2, 2, 2), cg::stride(0, 2, 4, 1));
        EXPECT_EQ(target, cg::make_layout_like(lay));
    }

    {
        cg::layout lay(cg::shape(2, 3, 4, 5), cg::stride(0, 42, 1, 0));
        cg::layout target(cg::shape(2, 3, 4, 5), cg::stride(0, 4, 1, 0));
        EXPECT_EQ(target, cg::make_layout_like(lay));
    }

    {
        cg::layout lay(cg::shape(2, 3, 4, 5), cg::stride(0, cg::dynamic_t{}, 1, 0));
        cg::layout target(cg::shape(2, 3, 4, 5), cg::stride(0, 4, 1, 0));
        EXPECT_EQ(target, cg::make_layout_like(lay));
    }

    {
        cg::layout lay(cg::shape(cg::shape(2, 3), 4, 5), cg::stride(cg::stride(0, cg::dynamic_t{}), 1, 0));
        cg::layout target(cg::shape(cg::shape(2, 3), 4, 5), cg::stride(cg::stride(0, 4), 1, 0));
        EXPECT_EQ(target, cg::make_layout_like(lay));
    }

    {
        cg::layout lay(cg::shape(cg::shape(4, cg::shape(2, 3)), 5), cg::stride(cg::stride(1, cg::stride(0, cg::dynamic_t{})), 0));
        cg::layout target(cg::shape(cg::shape(4, cg::shape(2, 3)), 5), cg::stride(cg::stride(1, cg::stride(0, 4)), 0));
        EXPECT_EQ(target, cg::make_layout_like(lay));
    }
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.IncrementCoord
TEST(LayoutTest, IncrementCoord)
{
    // Test static shape and coord
    {
        cg::shape s(3, 3, 3);
        cg::coord c0(0, 0, 0);
        cg::coord c1 = cg::increment_coord(c0, s);
        EXPECT_EQ(c1, cg::coord(1, 0, 0));

        cg::coord c2(2, 1, 1);
        cg::coord c3 = cg::increment_coord(c2, s);
        EXPECT_EQ(c3, cg::coord(0, 2, 1));

        cg::coord c4(2, 2, 1);
        cg::coord c5 = cg::increment_coord(c4, s);
        EXPECT_EQ(c5, cg::coord(0, 0, 2));

        // Test OOB behaviour - incrementing past the end
        cg::coord c6(2, 2, 2);
        cg::coord c7 = cg::increment_coord(c6, s);
        EXPECT_EQ(c7, cg::coord(0, 0, 3));
        cg::coord c8 = cg::increment_coord(c7, s);
        EXPECT_EQ(c8, cg::coord(1, 0, 3));

        // Test rank 1 shape
        cg::shape s1(3);
        cg::coord c9(1);
        cg::coord c10 = cg::increment_coord(c9, s1);
        EXPECT_EQ(c10, cg::coord(2));
    }

    // Test dynamic shape and coord
    {
        cg::shape s(cg::dynamic_t{}, 4, 8);
        cg::coord c(cg::dynamic_t{}, cg::dynamic_t{}, cg::dynamic_t{});
        cg::coord c1 = cg::increment_coord(c, s);
        EXPECT_EQ(c1, cg::coord(cg::dynamic_t{}, cg::dynamic_t{}, cg::dynamic_t{}));
    }

    // Test static coord, dynamic shape
    {
        cg::shape s(cg::dynamic_t{}, 4, 8);
        cg::coord c(0, 0, 0);
        cg::coord c1 = cg::increment_coord(c, s);
        EXPECT_EQ(c1, cg::coord(cg::dynamic_t{}, cg::dynamic_t{}, cg::dynamic_t{}));
    }

    // Test handling of size-1 shape modes
    {
        cg::shape s(cg::dynamic_t{}, 1, 8);
        cg::coord c(0, 0, 0);
        cg::coord c1 = cg::increment_coord(c, s);
        EXPECT_EQ(c1, cg::coord(cg::dynamic_t{}, 0, cg::dynamic_t{}));
        cg::coord c2 = cg::increment_coord(c1, s);
        EXPECT_EQ(c2, cg::coord(cg::dynamic_t{}, 0, cg::dynamic_t{}));
    }

    // Test hierarchical shapes and coords
    {
        cg::shape s0(cg::shape(3, 3), cg::shape(3, 3));
        cg::coord c0(cg::coord(0, 0), cg::coord(1, 0));
        cg::coord c1 = cg::increment_coord(c0, s0);
        EXPECT_EQ(c1, cg::coord(cg::coord(1, 0), cg::coord(1, 0)));

        cg::coord c2(cg::coord(2, 2), cg::coord(2, 0));
        cg::coord c3 = cg::increment_coord(c2, s0);
        EXPECT_EQ(c3, cg::coord(cg::coord(0, 0), cg::coord(0, 1)));

        cg::shape s1(cg::shape(3), cg::shape(3), cg::shape(2, 2));
        cg::coord c4(cg::coord(2), cg::coord(1), cg::coord(0, 0));
        cg::coord c5 = cg::increment_coord(c4, s1);
        EXPECT_EQ(c5, cg::coord(cg::coord(0), cg::coord(2), cg::coord(0, 0)));

        cg::shape s2(cg::wrap(3));
        cg::coord c6(cg::wrap(0));
        cg::coord c7 = cg::increment_coord(c6, s2);
        cg::coord c8 = cg::increment_coord(c7, s2);
        EXPECT_EQ(c7, cg::coord(cg::wrap(1)));
        EXPECT_EQ(c8, cg::coord(cg::wrap(2)));

        // Test OOB behaviour
        cg::shape s3(cg::shape(2, 2), cg::shape(2, 2));
        cg::coord c9(cg::coord(1, 1), cg::coord(1, 1));
        cg::coord c10 = cg::increment_coord(c9, s3);
        EXPECT_EQ(c10, cg::coord(cg::coord(0, 0), cg::coord(0, 2)));

        cg::shape s4(cg::shape(2, 2), cg::shape(2));
        cg::coord c11(cg::coord(1, 1), cg::coord(1));
        cg::coord c12 = cg::increment_coord(c11, s4);
        EXPECT_EQ(c12, cg::coord(cg::coord(0, 0), cg::coord(2)));
    }
}

TEST(LayoutTest, CoProfile)
{
    using sb_t = cg::scaled_basis;
    {
        // ((64,2),16):((65536,48),1)
        cg::layout lay(cg::shape(cg::shape(64, 2), 16), cg::stride(cg::stride(65536, 48), 1));
        EXPECT_EQ(cg::coprofile(lay), cg::int_tuple(0));
    }
    {
        // ((64,2),16):((1@1,48@0),1@0)
        cg::layout lay(cg::shape(cg::shape(64, 2), 16),
                       cg::stride(cg::stride(sb_t(1, 1), sb_t(0, 48)), sb_t(0, 1)));
        EXPECT_EQ(cg::coprofile(lay), cg::int_tuple(0, 0));
    }
    {
        // (65536,128,256):(1@0,1@1,1@3@2)
        cg::layout lay(cg::shape(65536, 128, 16),
                       cg::stride(sb_t(0, 1), sb_t(1, 1), sb_t(std::vector({2, 3}), 1)));
        EXPECT_EQ(cg::coprofile(lay), cg::int_tuple(0, 0, cg::int_tuple(0, 0, 0, 0)));
    }
    {
        // ():()
        cg::layout lay{cg::shape{}, cg::stride{}};
        EXPECT_EQ(cg::coprofile(lay), cg::int_tuple(0));
    }
}

TEST(LayoutTest, TilerToLayout)
{
    using sb_t = cg::scaled_basis;
    {
        // tiler_to_layout() with layout argument
        auto ly = cg::tiler_to_layout(cg::layout(cg::shape(7, 2), cg::stride(3, 1)));
        EXPECT_EQ(ly, cg::layout(cg::shape(7, 2), cg::stride(3, 1)));
    }
    {
        // tiler_to_layout() with layout argument and non-unit stride
        auto ly = cg::tiler_to_layout(cg::layout(cg::shape(7, 2), cg::stride(3, 1)),
                                      cg::stride(3));
        EXPECT_EQ(ly, cg::layout(cg::shape(7, 2), cg::stride(9, 3)));
    }
    {
        // tiler_to_layout() with integral shape argument
        auto ly = cg::tiler_to_layout(cg::shape(8));
        EXPECT_EQ(ly, cg::layout(cg::shape(8), cg::stride(1)));
    }
    {
        // tiler_to_layout() with integral shape argument and non-unit stride
        auto ly = cg::tiler_to_layout(cg::shape(8), cg::stride(5));
        EXPECT_EQ(ly, cg::layout(cg::shape(8), cg::stride(5)));
    }
    {
        // tiler_to_layout() with rank 2 shape argument
        // (4, 5) --> (4, 5):(1@0, 1@1)
        auto ly = cg::tiler_to_layout(cg::shape(4, 5));
        EXPECT_EQ(ly, cg::layout(cg::shape(4, 5), cg::stride(sb_t{0, 1}, sb_t{1, 1})));
    }
    {
        // tiler_to_layout() with hierarchical shape argument
        // (4, 5, (6, 7)) --> (4, 5, (6, 7)):(1@0, 1@1, (1@0@2, 1@1@2))
        auto ly = cg::tiler_to_layout(cg::shape(4, 5, cg::shape(6, 7)));
        // clang-format off
        EXPECT_EQ(ly, cg::layout(cg::shape(4, 5, cg::shape(6, 7)),
                                 cg::stride(sb_t{0, 1}, sb_t{1, 1}, cg::stride(sb_t{{2, 0}, 1}, sb_t{{2, 1}, 1}))));
        // clang-format on
    }
    {
        // tiler_to_layout() with tile holding a single layout
        auto ly = cg::tiler_to_layout(cg::tile(cg::layout(cg::shape(7, 2), cg::stride(3, 1))));
        EXPECT_EQ(ly, cg::layout(cg::shape(7, 2), cg::stride(3, 1)));
    }
}
