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

#include <ostream>
#include <string>
#include <variant>
#include <vector>

#include "cutegen/cutegen.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/rec_var.hpp"

#include "gtest/gtest.h"

namespace cg = cutegen;

template <class Layout>
void test_coalesce(const Layout& l, const Layout& lExpected)
{
    auto lCoalesce = cg::coalesce(l);
    ASSERT_EQ(lCoalesce, lExpected) << " with input " << l << std::endl;
    ASSERT_TRUE(cg::depth(lCoalesce.shape()) <= 1);
    ASSERT_EQ(cg::static_size(l), cg::static_size(lCoalesce));
    // We avoid comparing offsets for coordinate (scaled basis) layouts
    // for now, as zero comparisons are not implemented yet. (For
    // example, we want (0,(0,10)) and (0,(0,10),(0,0,0,0)) to compare
    // equal, but cutegen doesn't support that yet.
    if(cg::holds_int(cg::coprofile(l)))
    {
        // Verify that each offset is identical
        for(int i = 0; i < cg::static_size(l); ++i)
        {
            EXPECT_EQ(lCoalesce(cg::coord(i)), l(cg::coord(i)));
        }
    }
    // No coalesce if profile == shape if doesn't have shape-1 mode
    if(!any_leaf_is(l.shape(), [&](const auto& v) { return v == 1; }))
    {
        EXPECT_EQ(l, cg::coalesce(l, l.shape()));
        Layout lWrap{cg::wrap_if_leaf(l.shape()), cg::wrap_if_leaf(l.stride())};
        EXPECT_EQ(lWrap, cg::coalesce(l, cg::int_tuple()));
    }
}

template <class Layout, class TRecVar>
void test_coalesce(const Layout& l, const TRecVar& t, const Layout& lExpected)
{
    auto lCoalesce = cg::coalesce(l, t);
    EXPECT_EQ(lCoalesce, lExpected) << " with input " << l << ", profile " << t << std::endl;

    EXPECT_GE(cg::depth(lCoalesce.shape()), cg::depth(t));
    EXPECT_EQ(cg::size(l), cg::size(lCoalesce));
    // Verify that each offset is identical
    for(int i = 0; i < cg::static_size(l); ++i)
    {
        EXPECT_EQ(lCoalesce(cg::coord(i)), l(cg::coord(i)));
    }
}

TEST(CoalesceTest, Basic)
{
    { // 1:0 => 1:0
        auto ly = cg::layout(cg::shape(1), cg::stride(0));
        test_coalesce(ly,
                      cg::layout(cg::shape(1), cg::stride(0)));
    }
    { // 1:1 => 1:1
        auto ly = cg::layout(cg::shape(1), cg::stride(1));
        test_coalesce(ly,
                      cg::layout(cg::shape(1), cg::stride(1)));
    }
    { // (1, 1):(5, 7)  =>  1:7
        auto ly = cg::layout(cg::shape(1, 1), cg::stride(5, 7));
        test_coalesce(ly,
                      cg::layout(cg::shape(1), cg::stride(7)));
    }
    { // (2,4):(1,2) => 8:1
        auto ly = cg::layout(cg::shape(2, 4), cg::stride(1, 2));
        test_coalesce(ly,
                      cg::layout(cg::shape(8), cg::stride(1)));
    }
    { // (2,4):(4,1) => (2,4):(4,1)
        auto ly = cg::layout(cg::shape(2, 4), cg::stride(4, 1));
        test_coalesce(ly,
                      cg::layout(cg::shape(2, 4), cg::stride(4, 1)));
    }
    { // (2,4,6):(1,2,8) => 48:1
        auto ly = cg::layout(cg::shape(2, 4, 6), cg::stride(1, 2, 8));
        test_coalesce(ly,
                      cg::layout(cg::shape(48), cg::stride(1)));
    }
    { // (2,4,6):(24,6,1) => (2,4,6):(24,6,1)
        auto ly = cg::layout(cg::shape(2, 4, 6), cg::stride(24, 6, 1));
        test_coalesce(ly,
                      cg::layout(cg::shape(2, 4, 6), cg::stride(24, 6, 1)));
    }
    { // (2,(4,6)):(1,(2,8)) => 48:1
        auto ly = cg::layout(cg::shape(2, cg::shape(4, 6)), cg::stride(1, cg::stride(2, 8)));
        test_coalesce(ly,
                      cg::layout(cg::shape(48), cg::stride(1)));
    }
    { // (2,4,6):(1,6,2) => (2,4,6):(1,6,2)
        auto ly = cg::layout(cg::shape(2, 4, 6), cg::stride(1, 6, 2));
        test_coalesce(ly,
                      cg::layout(cg::shape(2, 4, 6), cg::stride(1, 6, 2)));
    }

    { // (2,1,6):(1,7,2) => 12:1
        auto ly = cg::layout(cg::shape(2, 1, 6), cg::stride(1, 7, 2));
        test_coalesce(ly,
                      cg::layout(cg::shape(12), cg::stride(1)));
    }
    { // (2,1,6):(4,7,8) => 12:4
        auto ly = cg::layout(cg::shape(2, 1, 6), cg::stride(4, 7, 8));
        test_coalesce(ly,
                      cg::layout(cg::shape(12), cg::stride(4)));
    }
    { // (2,1,6,1):(4,7,8,0) => 12:4
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(4, 7, 8, 0));
        test_coalesce(ly,
                      cg::layout(cg::shape(12), cg::stride(4)));
    }
    { // (2,1,6,1):(4,7,8,57) =>  12:4
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(4, 7, 8, 57));
        test_coalesce(ly,
                      cg::layout(cg::shape(12), cg::stride(4)));
    }
    { // (2,1,6,1):(1,7,8,0) =>  (2,6):(1,8)
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(1, 7, 8, 0));
        test_coalesce(ly,
                      cg::layout(cg::shape(2, 6), cg::stride(1, 8)));
    }
    { // (2,1,6,1):(1,7,8,57) =>  (2,6):(1,8)
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(1, 7, 8, 57));
        test_coalesce(ly,
                      cg::layout(cg::shape(2, 6), cg::stride(1, 8)));
    }
    { // (2,1,6,1):(1,7,8,48) =>  (2,6):(1,8)
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(1, 7, 8, 48));
        test_coalesce(ly,
                      cg::layout(cg::shape(2, 6), cg::stride(1, 8)));
    }
    { // (2,1,3):(2,4,4) =>  6:2
        auto ly = cg::layout(cg::shape(2, 1, 3), cg::stride(2, 4, 4));
        test_coalesce(ly,
                      cg::layout(cg::shape(6), cg::stride(2)));
    }
    { // ((2,2),(2,2)):((1,4),(8,32)) => (2,4,2):(1,4,32))
        auto ly = cg::layout(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                             cg::stride(cg::stride(1, 4), cg::stride(8, 32)));
        test_coalesce(ly,
                      cg::layout(cg::shape(2, 4, 2), cg::stride(1, 4, 32)));
    }
    { // (2,1,3):(3,0.1) => (2,3):(3,1)
        auto ly = cg::layout(cg::shape(2, 1, 3), cg::stride(3, 0, 1));
        test_coalesce(ly,
                      cg::layout(cg::shape(2, 3), cg::stride(3, 1)));
    }
    // Rank-0 layout
    auto layoutL = cg::layout();
    test_coalesce(layoutL, layoutL);
}

TEST(CoalesceTest, Coord)
{
    using sb_t = cg::scaled_basis;
    { // 1:1@0  =>  1:1@0
        auto ly = cg::layout(cg::shape(1), cg::stride(cg::E(0)));
        test_coalesce(ly,
                      cg::layout(cg::shape(1), cg::stride(cg::E(0))));
    }
    { // 1:1@1  =>  1:1@1
        auto ly = cg::layout(cg::shape(1), cg::stride(cg::E(1)));
        test_coalesce(ly,
                      cg::layout(cg::shape(1), cg::stride(cg::E(1))));
    }
    { // (1, 1):(1@0, 1@1)  =>  1:1@1
        auto ly = cg::layout(cg::shape(1, 1), cg::stride(cg::E(0), cg::E(1)));
        test_coalesce(ly,
                      cg::layout(cg::shape(1), cg::stride(cg::E(1))));
    }
    { // (2, 4):(1@0, 1@1)  =>  (2, 4):(1@0, 1@1)
        auto ly = cg::layout(cg::shape(2, 4), cg::stride(cg::E(0), cg::E(1)));
        test_coalesce(ly,
                      cg::layout(cg::shape(2, 4), cg::stride(cg::E(0), cg::E(1))));
    }
    { // (2, 4):(1@1, 2@1)  =>  8:1@1
        auto ly = cg::layout(cg::shape(2, 4), cg::stride(cg::E(1), sb_t{/*mode=*/1, /*value=*/2}));
        test_coalesce(ly,
                      cg::layout(cg::shape(8), cg::stride(cg::E(1))));
    }
    { // (2, 1, 6, 1):(1@1@1, 1@3@2, 2@1@1, 1@3@2)  =>  12:1@1@1
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(sb_t({1, 1}, 1), sb_t({2, 3}, 1), sb_t({1, 1}, 2), sb_t({2, 3}, 1)));
        test_coalesce(ly,
                      cg::layout(cg::shape(12), cg::stride(cg::E(1, 1))));
    }
    { // (2, 1, 6, 1):(1@1@1, 1@3@2, 2@0@1, 1@3@2)  =>  (2, 6):(1@1@1, 2@0@1)
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(sb_t({1, 1}, 1), sb_t({2, 3}, 1), sb_t({1, 0}, 2), sb_t({2, 3}, 1)));
        test_coalesce(ly,
                      cg::layout(cg::shape(2, 6), cg::stride(cg::E(1, 1), sb_t{{1, 0}, 2})));
    }
    { // (2, 1, 6, 1):(1@0@1, 1@3@2, 2@0@1, 12@0@1)  =>  12:1@0@1
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(sb_t({1, 0}, 1), sb_t({2, 3}, 1), sb_t({1, 0}, 2), sb_t({1, 0}, 12)));
        test_coalesce(ly,
                      cg::layout(cg::shape(12), cg::stride(cg::E(1, 0))));
    }
    { // ((2, 2), (2, 2)):((1@0, 1@1), (2@1, 2@0))  =>  (2, 4, 2):(1@0, 1@1, 2@0)
        auto ly = cg::layout(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                             cg::stride(cg::stride(cg::E(0), cg::E(1)), cg::stride(sb_t{1, 2}, sb_t{0, 2})));
        test_coalesce(ly,
                      cg::layout(cg::shape(2, 4, 2), cg::stride(cg::E(0), cg::E(1), sb_t{0, 2})));
    }
}

TEST(CoalesceTest, WithProfile)
{
    {
        auto layout = cg::layout(cg::shape(1), cg::stride(0));
        // 1:0 => 1:0 (with profile 1)
        test_coalesce(layout,
                      cg::int_tuple(1),
                      cg::layout(cg::shape(1), cg::stride(0)));

        // 1:0 => (1):(0) with profile (1)
        test_coalesce(layout,
                      cg::int_tuple(cg::wrap(1)),
                      cg::layout(cg::shape(cg::wrap(1)),
                                 cg::stride(cg::wrap(0))));
    }
    {
        auto layout = cg::layout(cg::shape(1), cg::stride(1));
        // 1:1 => 1:1 with profile 1
        test_coalesce(layout,
                      cg::int_tuple(1),
                      cg::layout(cg::shape(1), cg::stride(1)));
        // 1:1 => (1):(1) with profile ()
        test_coalesce(layout,
                      cg::int_tuple(),
                      cg::layout(cg::shape(cg::wrap(1)), cg::stride(cg::wrap(1))));
        // 1:1 => (1):(1) with profile (1)
        test_coalesce(layout,
                      cg::int_tuple(cg::wrap(1)),
                      cg::layout(cg::shape(cg::wrap(1)), cg::stride(cg::wrap(1))));
    }
    {
        auto layout = cg::layout(cg::shape(2, 4), cg::stride(1, 2));
        // (2,4):(1,2) => 8:1 with profile 1
        test_coalesce(layout,
                      cg::int_tuple(1),
                      cg::layout(cg::shape(8), cg::stride(1)));

        // (2,4):(1,2) => (2,4):(1,2) with profile (1)
        test_coalesce(layout,
                      cg::int_tuple(cg::wrap(1)),
                      cg::layout(cg::shape(2, 4), cg::stride(1, 2)));
    }
    {
        auto layout = cg::layout(cg::shape(2, 1, 6), cg::stride(1, 6, 2));
        // (2,1,6):(1,6,2) => (2,1,6):(1,6,2) with profile (1,2)
        test_coalesce(layout,
                      cg::int_tuple(1, 2),
                      cg::layout(cg::shape(2, 1, 6), cg::stride(1, 6, 2)));
    }
    {
        auto layout = cg::layout(cg::shape(2, 4), cg::stride(4, 1));
        // (2,4):(4,1) => (2,4):(4,1) with profile 1
        test_coalesce(layout,
                      cg::int_tuple(1),
                      cg::layout(cg::shape(2, 4), cg::stride(4, 1)));
    }
    {
        auto layout = cg::layout(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                                 cg::stride(cg::stride(1, 4), cg::stride(8, 32)));
        // ((2,2),(2,2)):((1,4),(8.32)) => (2,4,2):(1,4,32) with profile 1
        test_coalesce(layout,
                      cg::int_tuple(1),
                      cg::layout(cg::shape(2, 4, 2), cg::stride(1, 4, 32)));

        // ((2,2),(2,2)):((1,4),(8,32)) => ((2,2),(2,2)):((1,4),(8,32)) with profile (1)
        test_coalesce(layout,
                      cg::int_tuple(cg::wrap(1)),
                      cg::layout(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                                 cg::stride(cg::stride(1, 4), cg::stride(8, 32))));

        // ((2,2),(2,2)):((1,4),(8,32)) => ((2,2),(2,2)):((1,4),(8,32)) with profile (1,2)
        test_coalesce(layout,
                      cg::int_tuple(1, 2),
                      cg::layout(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                                 cg::stride(cg::stride(1, 4), cg::stride(8, 32))));
    }
    {
        auto layout = cg::layout(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                                 cg::stride(cg::stride(1, 2), cg::stride(16, 32)));

        // ((2,2),(2,2)):((1,2),(16,32)) => (4,4):(1,16) with profile 1
        test_coalesce(layout,
                      cg::int_tuple(1),
                      cg::layout(cg::shape(4, 4), cg::stride(1, 16)));

        // ((2,2),(2,2)):((1,2),(16,32)) => (4,(2,2)):(1,(16,32)) with profile (1)
        test_coalesce(layout,
                      cg::int_tuple(cg::wrap(1)),
                      cg::layout(cg::shape(cg::shape(4), cg::shape(2, 2)),
                                 cg::stride(cg::stride(1), cg::stride(16, 32))));

        // ((2,2),(2,2)):((1,2),(16,32)) => (4,4):(1,16) with profile (1,2)
        test_coalesce(layout,
                      cg::int_tuple(1, 2),
                      cg::layout(cg::shape(4, 4), cg::stride(1, 16)));
    }
}

TEST(CoalesceTest, Dynamic)
{
    using dyn_t  = cg::dynamic_t;
    using shape  = cg::shape;
    using stride = cg::stride;
    using layout = cg::layout;
    {
        // CuTe C++                       cutegen
        // (_2,_1,_6)  =>  _12            (2,1,6)  => 12
        // (_4,7,_8)       _4             (4,?,8)     4
        layout ly   = layout(shape(2, 1, 6), stride(4, dyn_t{}, 8));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(12), stride(4))) << " for input " << ly;
    }
    {
        // CuTe C++                         cutegen
        // (2,_4,_6)  =>  (2,_4,_6)           (?,4,6)  => (?,4,6)
        // (_1,2,8)       (_1,2,8)            (1,?,?)     (1,?,?)
        layout ly   = layout(shape(dyn_t{}, 4, 6), stride(1, dyn_t{}, dyn_t{}));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(dyn_t{}, 4, 6), stride(1, dyn_t{}, dyn_t{})))
            << " for input " << ly;
    }
    {
        // CuTe C++                         cutegen
        // (_2,4,_6)  =>  (_2,4,_6)            (2,?,6)  => (2,?,6)
        // (_1,_2,8)      (_1,2,8)             (1,2,?)     (1,2,?)
        layout ly   = layout(shape(2, dyn_t{}, 6), stride(1, 2, dyn_t{}));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(2, dyn_t{}, 6), stride(1, 2, dyn_t{})))
            << " for input " << ly;
    }
    {
        // CuTe C++                         cutegen
        // (_2,_4,6)   =>  (_8,6)            (2,4,?)  => (8,?)
        // (_1,_2,_8)      (_1,_8)           (1,2,8)     (1,8)
        layout ly   = layout(shape(2, 4, dyn_t{}), stride(1, 2, 8));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(8, dyn_t{}), stride(1, 8)))
            << " for input " << ly;
    }
    {
        // CuTe C++                         cutegen
        // (_2,_4)   => (_2,_4)            (2,4)  => (2,4)
        // (_4,_1)      (_4,_1)            (4,1)     (4,1)
        layout ly   = layout(shape(2, 4), stride(4, 1));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(2, 4), stride(4, 1)))
            << " for input " << ly;
    }
    {
        // CuTe C++                         cutegen
        // (_2,_4,_6)    => (_2,_4,_6)      (2,4,6)  =>  (2,4,6)
        // (_24,_6,_1)      (_24,_6,_1)     (24,6,1)     (24,6,1)
        layout ly   = layout(shape(2, 4, 6), stride(24, 6, 1));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(2, 4, 6), stride(24, 6, 1)))
            << " for input " << ly;
    }
    {
        // CuTe C++                         cutegen
        // (2,_4,_6)    => (2,_4,_6)       (?,4,6)  =>  (?,4,6)
        // (_24,_6,_1)     (_24,_6,_1)     (24,6,1)     (24,6,1)
        layout ly   = layout(shape(dyn_t{}, 4, 6), stride(24, 6, 1));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(dyn_t{}, 4, 6), stride(24, 6, 1)))
            << " for input " << ly;
    }
    {
        // CuTe C++                         cutegen
        // (_2,4,_6)   => (_2,4,_6)      (2,?,6)  =>  (2,?,6)
        // (24,_6,_1)     (24,_6,_1)     (?,6,1)      (?,6,1)
        layout ly   = layout(shape(2, dyn_t{}, 6), stride(dyn_t{}, 6, 1));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(2, dyn_t{}, 6), stride(dyn_t{}, 6, 1)))
            << " for input " << ly;
    }
    {
        // CuTe C++                         cutegen
        // (_2,_4,6)  => (_2,_4,6)     (2,4,?)  =>  (2,4,?)
        // (24,6,_1)     (24,6,_1)     (?,?,1)      (?,?,1)
        layout ly   = layout(shape(2, 4, dyn_t{}), stride(dyn_t{}, dyn_t{}, 1));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(2, 4, dyn_t{}), stride(dyn_t{}, dyn_t{}, 1)))
            << " for input " << ly;
    }
    {
        // CuTe C++                         cutegen
        // (_2,_1,_3)  => (_2,_3)     (2,1,3)  =>  (2,3)
        // (_3,_0,_1)     (_3,_1)     (3,0,1)      (3,1)
        layout ly   = layout(shape(2, 1, 3), stride(3, 0, 1));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(2, 3), stride(3, 1)))
            << " for input " << ly;
    }
    {
        // CuTe C++                         cutegen
        // (_2,1,_3)  => (_2,1,_3)     (2,?,3)  =>  (2,?,3)
        // (3,_3,_1)     (3,_3,_1)     (?,3,1)      (?,3,1)
        layout ly   = layout(shape(2, dyn_t{}, 3), stride(dyn_t{}, 3, 1));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(2, dyn_t{}, 3), stride(dyn_t{}, 3, 1)))
            << " for input " << ly;
    }
    {
        // CuTe C++                         cutegen
        // (_2,1,_3)  => (_2,1,_3)     (2,?,3)  =>  (2,?,3)
        // (_2,4,_4)     (_2,4,_4)     (2,?,4)      (2,?,4)
        layout ly   = layout(shape(2, dyn_t{}, 3), stride(2, dyn_t{}, 4));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(2, dyn_t{}, 3), stride(2, dyn_t{}, 4)))
            << " for input " << ly;
    }
    {
        // CuTe C++                         cutegen
        // (_2,1,_3)  => (_2,1,_3)      (2,?,3)  =>  (2,?,3)
        // (_2,_0,_4)    (_2,_0,_4)     (2,0,4)      (2,0,4)
        layout ly   = layout(shape(2, dyn_t{}, 3), stride(2, dyn_t{}, 4));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(2, dyn_t{}, 3), stride(2, dyn_t{}, 4)))
            << " for input " << ly;
    }
    {
        // CuTe C++                              cutegen
        // ((_2,_2),(_2,_2))  => (_2,_4,_2)      ((2,2),(2,2))  =>  (2,4,2)
        // ((_1,_4),(_8,_32))    (_1,_4,_32)     ((1,4),(8,32))     (1,4,32)
        layout ly   = layout(shape(shape(2, 2), shape(2, 2)), stride(stride(1, 4), stride(8, 32)));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(2, 4, 2), stride(1, 4, 32)))
            << " for input " << ly;
    }
    {
        // (?,?):(?,?) --> (?,?):(?,?)
        layout ly   = layout(shape(dyn_t{}, dyn_t{}), stride(dyn_t{}, dyn_t{}));
        auto   ly_c = coalesce(ly);
        EXPECT_EQ(ly_c, layout(shape(dyn_t{}, dyn_t{}), stride(dyn_t{}, dyn_t{})))
            << " for input " << ly;
    }
}

TEST(CoalesceTest, ScaledBasis)
{
    {
        auto opt_l   = cg::from_string<cg::layout>("((16,4),128):((1@0,16@0),1@1)");
        auto opt_res = cg::from_string<cg::layout>("(    64,128):(       1@0,1@1)");
        ASSERT_TRUE(opt_l.has_value());
        ASSERT_TRUE(opt_res.has_value());
        EXPECT_EQ(cg::coalesce(opt_l.value()), opt_res.value());
    }
}

TEST(CoalesceTest, CoalesceUpWith)
{
    // coalesce_up_with walks the layout from left to right, opposite from coalesce
    {
        // This test verifies that coalesce_up_with correctly avoids coalescing when the resulting
        // shape mode would have an extent greater than the second argument
        auto opt_l   = cg::from_string<cg::layout>("(2,4,32,4):(1,2,8,256)");
        auto opt_res = cg::from_string<cg::layout>("(256,4):(1,256)");
        ASSERT_TRUE(opt_l.has_value());
        ASSERT_TRUE(opt_res.has_value());
        EXPECT_EQ(cg::coalesce_up_with(opt_l.value(), 256), opt_res.value());
    }
    {
        // This test verifies that coalesce_up_with does coalesce when the resulting shape mode has
        // extent lower than or equal to the second argument and the stride contains scaled basis
        // elements
        auto opt_l   = cg::from_string<cg::layout>("((16,4),128):((1@0,16@0),1@1)");
        auto opt_res = cg::from_string<cg::layout>("(    64,128):(       1@0,1@1)");
        ASSERT_TRUE(opt_l.has_value());
        ASSERT_TRUE(opt_res.has_value());
        EXPECT_EQ(cg::coalesce_up_with(opt_l.value(), 256), opt_res.value());
    }
    {
        // This test verifies that coalesce_up_with correctly avoids coalescing when the resulting
        // shape mode would have an extent greater than the second argument for TMA layouts
        auto opt_l = cg::from_string<cg::layout>("((16,20),128):((1@0,16@0), 1@1)");
        ASSERT_TRUE(opt_l.has_value());
        // Won't coalesce because 16x20 > 256
        EXPECT_EQ(cg::coalesce_up_with(opt_l.value(), 256), cg::flatten(opt_l.value()));
    }
}

TEST(CoalesceTest, Shape)
{
    using shape = cg::shape;
    using dyn_t = cg::dynamic_t;
    {
        // (64,32,?) => (2048,?)
        shape s0(64, 32, dyn_t{});
        shape s0_c = cg::coalesce(s0);
        EXPECT_EQ(s0_c, shape(2048, dyn_t{}));
    }
    {
        // (64,?,?,?,2,4) => (64,?,8)
        shape s1(64, dyn_t{}, dyn_t{}, dyn_t{}, 2, 4);
        shape s1_c = cg::coalesce(s1);
        EXPECT_EQ(s1_c, shape(64, dyn_t{}, 8));
    }
    {
        // (64,32,2) => 4096
        shape s2(64, 32, 2);
        shape s2_c = cg::coalesce(s2);
        EXPECT_EQ(s2_c, shape(4096));
    }
    {
        // (64,32,(2,?)) => (4096,?)
        shape s3(64, 32, shape(2, dyn_t{}));
        shape s3_c = cg::coalesce(s3);
        EXPECT_EQ(s3_c, shape(4096, dyn_t{}));
    }
}
