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

#include <stdio.h>
#include <string>
#include <variant>
#include <vector>

#include "cutegen/cutegen.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/rec_var_algorithms.hpp"

#include "gtest/gtest.h"

namespace cg = cutegen;

namespace
{
template <class LayoutA, class LayoutB, class LayoutResult>
void test_logical_product(const LayoutA&      layoutA,
                          const LayoutB&      layoutB,
                          const LayoutResult& expected)
{
    auto layoutR = logical_product(layoutA, layoutB);

    EXPECT_EQ(cg::rank(layoutR), 2);
    EXPECT_TRUE(cg::compatible(layoutB.shape(), layoutR.shape()[1]));
    EXPECT_EQ(layoutR, expected);
}
} // namespace

////////////////////////////////////////////////////////////////////////
// LogicalProductTest.Basic
TEST(LogicalProductTest, Basic)
{
    { // 1:0 x 1:0  =>  (1, 1):(0, 0)
        auto vec      = cg::layout(cg::shape(1), cg::stride(0));
        auto tile     = cg::layout(cg::shape(1), cg::stride(0));
        auto expected = cg::layout(cg::shape(1, 1), cg::stride(0, 0));

        test_logical_product(vec, tile, expected);
    }
    { // 1:1 x 1:0  =>  (1, 1):(1, 0)
        auto vec      = cg::layout(cg::shape(1), cg::stride(1));
        auto tile     = cg::layout(cg::shape(1), cg::stride(0));
        auto expected = cg::layout(cg::shape(1, 1), cg::stride(1, 0));

        test_logical_product(vec, tile, expected);
    }
    { // 1:0 x 1:1  =>  (1, 1):(0, 1)
        auto vec      = cg::layout(cg::shape(1), cg::stride(0));
        auto tile     = cg::layout(cg::shape(1), cg::stride(1));
        auto expected = cg::layout(cg::shape(1, 1), cg::stride(0, 1));

        test_logical_product(vec, tile, expected);
    }
    { // 1:1 x 1:1  =>  (1, 1):(1, 1)
        auto vec      = cg::layout(cg::shape(1), cg::stride(1));
        auto tile     = cg::layout(cg::shape(1), cg::stride(1));
        auto expected = cg::layout(cg::shape(1, 1), cg::stride(1, 1));

        test_logical_product(vec, tile, expected);
    }
    { // 3:1 x 4:1  =>  (3, 4):(1, 3)
        auto vec      = cg::layout(cg::shape(3), cg::stride(1));
        auto tile     = cg::layout(cg::shape(4), cg::stride(1));
        auto expected = cg::layout(cg::shape(3, 4), cg::stride(1, 3));

        test_logical_product(vec, tile, expected);
    }
    { // 3:1 x 4:0  =>  (3, 4):(1, 0)
        auto vec      = cg::layout(cg::shape(3), cg::stride(1));
        auto tile     = cg::layout(cg::shape(4), cg::stride(0));
        auto expected = cg::layout(cg::shape(3, 4), cg::stride(1, 0));

        test_logical_product(vec, tile, expected);
    }
    { // 3:1 x (2, 4):(1, 2)  =>  (3, (2, 4)):(1, (3, 6))
        auto vec      = cg::layout(cg::shape(3), cg::stride(1));
        auto tile     = cg::layout(cg::shape(2, 4), cg::stride(1, 2));
        auto expected = cg::layout(cg::shape(3, cg::shape(2, 4)),
                                   cg::stride(1, cg::stride(3, 6)));

        test_logical_product(vec, tile, expected);
    }

    { // (2, 4):(1, 2) x 3:1  =>  ((2, 4), 3):((1, 2), 8)
        auto vec      = cg::layout(cg::shape(2, 4), cg::stride(1, 2));
        auto tile     = cg::layout(cg::shape(3), cg::stride(1));
        auto expected = cg::layout(cg::shape(cg::shape(2, 4), 3),
                                   cg::stride(cg::stride(1, 2), 8));

        test_logical_product(vec, tile, expected);
    }
    { // (8, (2, 2)):(1, (8, 16)) x 4:2  =>  ((8, (2, 2)), 4):((1, (8, 16)), 64)
        auto vec      = cg::layout(cg::shape(8, cg::shape(2, 2)),
                              cg::stride(1, cg::stride(8, 16)));
        auto tile     = cg::layout(cg::shape(4), cg::stride(2));
        auto expected = cg::layout(cg::shape(cg::shape(8, cg::shape(2, 2)), 4),
                                   cg::stride(cg::stride(1, cg::stride(8, 16)), 64));

        test_logical_product(vec, tile, expected);
    }

    { // (2, 2):(1, 2) x (3, 3):(3, 1)  =>  ((2, 2), (3, 3)):((1, 2), (12, 4))
        auto vec      = cg::layout(cg::shape(2, 2), cg::stride(1, 2));
        auto tile     = cg::layout(cg::shape(3, 3), cg::stride(3, 1));
        auto expected = cg::layout(cg::shape(cg::shape(2, 2), cg::shape(3, 3)),
                                   cg::stride(cg::stride(1, 2), cg::stride(12, 4)));

        test_logical_product(vec, tile, expected);
    }

    { // 3:32 x 32:1  =>  (3, 32):(32, 1)
        auto vec      = cg::layout(cg::shape(3), cg::stride(32));
        auto tile     = cg::layout(cg::shape(32), cg::stride(1));
        auto expected = cg::layout(cg::shape(3, 32), cg::stride(32, 1));

        test_logical_product(vec, tile, expected);
    }

    { // 3:2 x 4:1  =>  (3, (2, 2)):(2, (1, 6))
        auto vec      = cg::layout(cg::shape(3), cg::stride(2));
        auto tile     = cg::layout(cg::shape(4), cg::stride(1));
        auto expected = cg::layout(cg::shape(3, cg::shape(2, 2)),
                                   cg::stride(2, cg::stride(1, 6)));

        test_logical_product(vec, tile, expected);
    }
    { // 3:32 x 128:1  =>  (3, (32, 4)):(32, (1, 96))
        auto vec      = cg::layout(cg::shape(3), cg::stride(32));
        auto tile     = cg::layout(cg::shape(128), cg::stride(1));
        auto expected = cg::layout(cg::shape(3, cg::shape(32, 4)),
                                   cg::stride(32, cg::stride(1, 96)));

        test_logical_product(vec, tile, expected);
    }
    { // 3:32 x (8, 8):(1, 8)  =>  (3, (8, (4, 2))):(32, (1, (8, 96)))
        auto vec      = cg::layout(cg::shape(3), cg::stride(32));
        auto tile     = cg::layout(cg::shape(8, 8), cg::stride(1, 8));
        auto expected = cg::layout(cg::shape(3, cg::shape(8, cg::shape(4, 2))),
                                   cg::stride(32, cg::stride(1, cg::stride(8, 96))));

        test_logical_product(vec, tile, expected);
    }
    { // 3:32 x (8, 8):(8, 1)  =>  (3, ((4, 2), 8)):(32, ((8, 96), 1))
        auto vec      = cg::layout(cg::shape(3), cg::stride(32));
        auto tile     = cg::layout(cg::shape(8, 8), cg::stride(8, 1));
        auto expected = cg::layout(cg::shape(3, cg::shape(cg::shape(4, 2), 8)),
                                   cg::stride(32, cg::stride(cg::stride(8, 96), 1)));

        test_logical_product(vec, tile, expected);
    }
    { // (4, 2):(1, 16) x (4, 4):(1, 4)  =>  ((4, 2), (4, 4)):((1, 16), (4, 32))
        auto vec      = cg::layout(cg::shape(4, 2), cg::stride(1, 16));
        auto tile     = cg::layout(cg::shape(4, 4), cg::stride(1, 4));
        auto expected = cg::layout(cg::shape(cg::shape(4, 2), cg::shape(4, 4)),
                                   cg::stride(cg::stride(1, 16), cg::stride(4, 32)));

        test_logical_product(vec, tile, expected);
    }
    { // (4, 2):(1, 16) x (4, 2):(2, 1)  =>  ((4, 2), ((2, 2), 2)):((1, 16), ((8, 32), 4))
        auto vec      = cg::layout(cg::shape(4, 2), cg::stride(1, 16));
        auto tile     = cg::layout(cg::shape(4, 2), cg::stride(2, 1));
        auto expected = cg::layout(cg::shape(cg::shape(4, 2), cg::shape(cg::shape(2, 2), 2)),
                                   cg::stride(cg::stride(1, 16), cg::stride(cg::stride(8, 32), 4)));

        test_logical_product(vec, tile, expected);
    }
    { // ((2, 2), (2, 2)):((1, 4), (8, 32)) x (2, 2):(1, 2)  =>  (((2, 2), (2, 2)), (2, 2)):(((1, 4), (8, 32)), (2, 16))
        auto vec      = cg::layout(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                              cg::stride(cg::stride(1, 4), cg::stride(8, 32)));
        auto tile     = cg::layout(cg::shape(2, 2), cg::stride(1, 2));
        auto expected = cg::layout(cg::shape(cg::shape(cg::shape(2, 2), cg::shape(2, 2)), cg::shape(2, 2)),
                                   cg::stride(cg::stride(cg::stride(1, 4), cg::stride(8, 32)), cg::stride(2, 16)));

        test_logical_product(vec, tile, expected);
    }
    { // ((2, 2), (2, 2)):((1, 4), (8, 32)) x (2, 2):(2, 1)  =>  (((2, 2), (2, 2)), (2, 2)):(((1, 4), (8, 32)), (16, 2))
        auto vec      = cg::layout(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                              cg::stride(cg::stride(1, 4), cg::stride(8, 32)));
        auto tile     = cg::layout(cg::shape(2, 2), cg::stride(2, 1));
        auto expected = cg::layout(cg::shape(cg::shape(cg::shape(2, 2), cg::shape(2, 2)), cg::shape(2, 2)),
                                   cg::stride(cg::stride(cg::stride(1, 4), cg::stride(8, 32)), cg::stride(16, 2)));

        test_logical_product(vec, tile, expected);
    }
    { // (4, 6):(1, 6) x 3:1  =>  ((4, 6), 3):((1, 6), 36)
        auto vec      = cg::layout(cg::shape(4, 6), cg::stride(1, 6));
        auto tile     = cg::layout(cg::shape(3), cg::stride(1));
        auto expected = cg::layout(cg::shape(cg::shape(4, 6), 3), cg::stride(cg::stride(1, 6), 36));

        test_logical_product(vec, tile, expected);
    }
    // Tests not in PyCuTe
    { // 3:0 x 4:1  =>  (3, 4):(0, 1)
        auto vec      = cg::layout(cg::shape(3), cg::stride(0));
        auto tile     = cg::layout(cg::shape(4), cg::stride(1));
        auto expected = cg::layout(cg::shape(3, 4), cg::stride(0, 1));

        test_logical_product(vec, tile, expected);
    }
    { // 3:0 x 4:0  =>  (3, 4):(0, 0)
        auto vec      = cg::layout(cg::shape(3), cg::stride(0));
        auto tile     = cg::layout(cg::shape(4), cg::stride(0));
        auto expected = cg::layout(cg::shape(3, 4), cg::stride(0, 0));

        test_logical_product(vec, tile, expected);
    }
}

TEST(LogicalProductTest, Zipped)
{
    {
        auto block = *cg::from_string<cg::layout>("(3,4):(1,3)");
        auto tiler = *cg::from_string<cg::layout>("(4,5):(5,1)");
        auto zp    = *cg::from_string<cg::layout>("((3,4),(4,5)):((1,3),(60,12))");
        auto tp    = *cg::from_string<cg::layout>("((3,4),4,5):((1,3),60,12)");
        auto fp    = *cg::from_string<cg::layout>("(3,4,4,5):(1,3,60,12)");
        EXPECT_EQ(cg::zipped_product(block, tiler), zp);
        EXPECT_EQ(cg::tiled_product(block, tiler), tp);
        EXPECT_EQ(cg::flat_product(block, tiler), fp);
    }
    {
        auto block = *cg::from_string<cg::composed_layout>("S<0,4,3> o 0 o (3,4):(1,3)");
        auto tiler = *cg::from_string<cg::layout>("(4,5):(5,1)");
        auto zp    = *cg::from_string<cg::composed_layout>("S<0,4,3> o 0 o ((3,4),(4,5)):((1,3),(60,12))");
        auto tp    = *cg::from_string<cg::composed_layout>("S<0,4,3> o 0 o ((3,4),4,5):((1,3),60,12)");
        auto fp    = *cg::from_string<cg::composed_layout>("S<0,4,3> o 0 o (3,4,4,5):(1,3,60,12)");
        EXPECT_EQ(cg::zipped_product(block, tiler), zp);
        EXPECT_EQ(cg::tiled_product(block, tiler), tp);
        EXPECT_EQ(cg::flat_product(block, tiler), fp);
    }
}

//////////////////////////////////////////////////////////////////////////////
// LogicalProductTest.Advanced
TEST(LogicalProductTest, Advanced)
{
    {
        // Checked against CuTe-C++
        auto a = *cg::from_string<cg::layout>("(3,4):(4,1)");
        auto b = *cg::from_string<cg::layout>("(2,5):(1,2)");
        auto c = *cg::from_string<cg::layout>("((3,2),(4,5)):((4,12),(1,24))");
        EXPECT_EQ(cg::blocked_product(a, b), c);
    }

    {
        auto a = cg::layout(cg::shape(3, 4), cg::stride(4, 1));
        auto b = cg::layout(cg::shape(2, 5), cg::stride(1, 2));
        auto c = cg::layout(
            cg::shape(cg::shape(2, 3), cg::shape(5, 4)),
            cg::stride(cg::stride(12, 4), cg::stride(24, 1)));
        EXPECT_EQ(cg::raked_product(a, b), c);
    }
    {
        // Example found in tiled copy creation
        // raked_product( 128:1, (4,4):(1,4) ) = ((4,128),4):((128,1),512)
        // Verifies that padding works correctly
        cg::layout thr_layout(cg::shape(128));
        cg::layout val_layout(cg::shape(4, 4));
        cg::layout layout_mn = cg::raked_product(thr_layout, val_layout);
        EXPECT_EQ(layout_mn,
                  cg::layout(cg::shape(cg::shape(4, 128), 4), cg::stride(cg::stride(128, 1), 512)));
    }
}

TEST(LogicalProductTest, ComposedLayout)
{
    // Create composed layout
    auto composed = cg::composed_layout(
        cg::layout(cg::shape(2, 3), cg::stride(3, 1)),
        2,
        cg::layout(cg::shape(3, 4), cg::stride(4, 1)));

    // Create second layout
    auto b = cg::layout(cg::shape(2, 5), cg::stride(1, 2));

    // Create expected layout
    auto expected = cg::layout(
        cg::shape(cg::shape(3, 4), cg::shape(2, 5)),
        cg::stride(cg::stride(4, 1), cg::stride(12, 24)));

    auto result = cg::logical_product(composed, b);
    EXPECT_EQ(result.layout_a(), composed.layout_a());
    EXPECT_EQ(result.offset(), composed.offset());
    // Perform blocked product and check result
    EXPECT_EQ(result.layout_b(), expected);
}

TEST(BlockedProductTest, ComposedLayout)
{
    auto composed = *cg::from_string<cg::composed_layout>("(2,3):(3,1) o 2 o (3,4):(4,1)");
    auto b        = *cg::from_string<cg::layout>("(2,5):(1,2)");
    auto expected = *cg::from_string<cg::layout>("((3,2),(4,5)):((4,12),(1,24))");

    auto result = cg::blocked_product(composed, b);
    EXPECT_EQ(result.layout_a(), composed.layout_a());
    EXPECT_EQ(result.offset(), composed.offset());
    EXPECT_EQ(result.layout_b(), expected);
}

TEST(RakedProductTest, ComposedLayout)
{
    // Create composed layout
    auto composed = cg::composed_layout(
        cg::layout(cg::shape(2, 3), cg::stride(3, 1)),
        2,
        cg::layout(cg::shape(3, 4), cg::stride(4, 1)));

    // Create second layout
    auto b = cg::layout(cg::shape(2, 5), cg::stride(1, 2));

    // Create expected layout
    auto expected = cg::layout(
        cg::shape(cg::shape(2, 3), cg::shape(5, 4)),
        cg::stride(cg::stride(12, 4), cg::stride(24, 1)));

    auto result = cg::raked_product(composed, b);
    EXPECT_EQ(result.layout_a(), composed.layout_a());
    EXPECT_EQ(result.offset(), composed.offset());
    // Perform blocked product and check result
    EXPECT_EQ(result.layout_b(), expected);
}
