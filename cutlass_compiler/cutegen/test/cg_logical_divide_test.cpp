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
#include "cutegen/underscore.hpp"

#include "gtest/gtest.h"

namespace cg = cutegen;

namespace
{
template <class LayoutA, class LayoutB, class LayoutResult>
void test_logical_divide(const LayoutA&      layoutA,
                         const LayoutB&      layoutB,
                         const LayoutResult& layoutExpected)
{
    auto layoutR = logical_divide(layoutA, layoutB);

    EXPECT_EQ(layoutR, layoutExpected) << " for logical_divide("
                                       << layoutA << ", " << layoutB
                                       << ")";

    // Check the rank (Tile,Grid)
    EXPECT_EQ(cg::rank(layoutR), 2);

    // Check that the Tile-mode is just composition
    EXPECT_TRUE(cg::compatible(layoutB.shape(), layoutR.shape()[0]));
    for(int i = 0; i < cg::static_size(layoutB); ++i)
    {
        //std::cout << "layoutB(" << i << ") = " << layoutB(i) << std::endl;
        //std::cout << "layoutA(" << layoutB(i) << ") = " << layoutA(layoutB(i)) << std::endl;
        EXPECT_EQ(layoutR(cg::int_tuple(i, 0)), layoutA(layoutB(i)));
    }

    // Check the Grid-mode
    // Every element of A appears in R as well
    for(int i = 0; i < cg::static_size(layoutA); ++i)
    {
        auto a      = layoutA(i);
        bool a_in_r = false;
        for(int j = 0; j < cg::static_size(layoutR); ++j)
        {
            if(a == layoutR(j))
            {
                a_in_r = true;
                break;
            }
        }
        EXPECT_TRUE(a_in_r);
    }
}
} // namespace

////////////////////////////////////////////////////////////////////////////////
// LogicalDivideTest.Basic
TEST(LogicalDivideTest, Basic)
{
    { // 1:0 / 1:0  =>  (1, 1):(0, 0)
        auto layout   = cg::layout(cg::shape(1), cg::stride(0));
        auto tile     = cg::layout(cg::shape(1), cg::stride(0));
        auto expected = cg::layout(cg::shape(1, 1), cg::stride(0, 0));

        test_logical_divide(layout, tile, expected);
    }
    { // 1:0 / 1:1  =>  (1, 1):(0, 0)
        auto layout   = cg::layout(cg::shape(1), cg::stride(0));
        auto tile     = cg::layout(cg::shape(1), cg::stride(1));
        auto expected = cg::layout(cg::shape(1, 1), cg::stride(0, 0));

        test_logical_divide(layout, tile, expected);
    }
    { // 1:1 / 1:0  =>  (1, 1):(0, 1)
        auto layout   = cg::layout(cg::shape(1), cg::stride(1));
        auto tile     = cg::layout(cg::shape(1), cg::stride(0));
        auto expected = cg::layout(cg::shape(1, 1), cg::stride(0, 1));

        test_logical_divide(layout, tile, expected);
    }
    { // 1:1 / 1:1  =>  (1, 1):(1, 1)
        auto layout   = cg::layout(cg::shape(1), cg::stride(1));
        auto tile     = cg::layout(cg::shape(1), cg::stride(1));
        auto expected = cg::layout(cg::shape(1, 1), cg::stride(1, 1));
        test_logical_divide(layout, tile, expected);
    }
    { // 6:1 / 2:1  =>  (2, 3):(1, 2)
        auto layout   = cg::layout(cg::shape(6), cg::stride(1));
        auto tile     = cg::layout(cg::shape(2), cg::stride(1));
        auto expected = cg::layout(cg::shape(2, 3), cg::stride(1, 2));

        test_logical_divide(layout, tile, expected);
    }
    { // 6:1 / 2:3  =>  (2, 3):(3, 1)
        auto layout   = cg::layout(cg::shape(6), cg::stride(1));
        auto tile     = cg::layout(cg::shape(2), cg::stride(3));
        auto expected = cg::layout(cg::shape(2, 3), cg::stride(3, 1));

        test_logical_divide(layout, tile, expected);
    }
    { // 6:1 / (2, 3):(3, 1)  =>  ((2, 3), 1):((3, 1), 6)
        auto layout   = cg::layout(cg::shape(6), cg::stride(1));
        auto tile     = cg::layout(cg::shape(2, 3), cg::stride(3, 1));
        auto expected = cg::layout(cg::shape(cg::shape(2, 3), 1),
                                   cg::stride(cg::stride(3, 1), 6));

        test_logical_divide(layout, tile, expected);
    }
    { // 6:2 / 2:1  =>  (2, 3):(2, 4)
        auto layout   = cg::layout(cg::shape(6), cg::stride(2));
        auto tile     = cg::layout(cg::shape(2), cg::stride(1));
        auto expected = cg::layout(cg::shape(2, 3), cg::stride(2, 4));

        test_logical_divide(layout, tile, expected);
    }
    { // 6:2 / 2:3  =>  (2, 3):(6, 2)
        auto layout   = cg::layout(cg::shape(6), cg::stride(2));
        auto tile     = cg::layout(cg::shape(2), cg::stride(3));
        auto expected = cg::layout(cg::shape(2, 3), cg::stride(6, 2));

        test_logical_divide(layout, tile, expected);
    }
    { // 6:2 / (2, 3):(3, 1)  =>  ((2, 3), 1):((6, 2), 12)
        auto layout   = cg::layout(cg::shape(6), cg::stride(2));
        auto tile     = cg::layout(cg::shape(2, 3), cg::stride(3, 1));
        auto expected = cg::layout(cg::shape(cg::shape(2, 3), 1),
                                   cg::stride(cg::stride(6, 2), 12));
        test_logical_divide(layout, tile, expected);
    }
    { // (6, 6):(1, 12) / (6, 3):(3, 1)  =>  (((2, 3), 3), 2):(((3, 12), 1), 36)
        auto layout   = cg::layout(cg::shape(6, 6), cg::stride(1, 12));
        auto tile     = cg::layout(cg::shape(6, 3), cg::stride(3, 1));
        auto expected = cg::layout(cg::shape(cg::shape(cg::shape(2, 3), 3), 2),
                                   cg::stride(cg::stride(cg::stride(3, 12), 1), 36));

        test_logical_divide(layout, tile, expected);
    }
    { // (6, 6):(12, 1) / (6, 3):(3, 1)  =>  (((2, 3), 3), 2):(((36, 1), 12), 3)
        auto layout   = cg::layout(cg::shape(6, 6), cg::stride(12, 1));
        auto tile     = cg::layout(cg::shape(6, 3), cg::stride(3, 1));
        auto expected = cg::layout(cg::shape(cg::shape(cg::shape(2, 3), 3), 2),
                                   cg::stride(cg::stride(cg::stride(36, 1), 12), 3));

        test_logical_divide(layout, tile, expected);
    }
    { // 32:1 / 2:8  =>  (2, (8, 2)):(8, (1, 16))
        auto layout   = cg::layout(cg::shape(32), cg::stride(1));
        auto tile     = cg::layout(cg::shape(2), cg::stride(8));
        auto expected = cg::layout(cg::shape(2, cg::shape(8, 2)), cg::stride(8, cg::stride(1, 16)));

        test_logical_divide(layout, tile, expected);
    }
    { // (4, 1):(1, 1) / 2:1  =>  (2, 2):(1, 2)
        auto layout   = cg::layout(cg::shape(4, 1), cg::stride(1, 1));
        auto tile     = cg::layout(cg::shape(2), cg::stride(1));
        auto expected = cg::layout(cg::shape(2, 2), cg::stride(1, 2));

        test_logical_divide(layout, tile, expected);
    }
    { // (4, 1):(1, 1) / 2:2  =>  (2, 2):(2, 1)
        auto layout   = cg::layout(cg::shape(4, 1), cg::stride(1, 1));
        auto tile     = cg::layout(cg::shape(2), cg::stride(2));
        auto expected = cg::layout(cg::shape(2, 2), cg::stride(2, 1));

        test_logical_divide(layout, tile, expected);
    }
    { // (8, 8):(1, 8) / 32:2  =>  (32, 2):(2, 1)
        auto layout   = cg::layout(cg::shape(8, 8), cg::stride(1, 8));
        auto tile     = cg::layout(cg::shape(32), cg::stride(2));
        auto expected = cg::layout(cg::shape(32, 2), cg::stride(2, 1));

        test_logical_divide(layout, tile, expected);
    }
    { // (8, 8):(8, 1) / 32:2  =>  ((4, 8), 2):((16, 1), 8)
        auto layout   = cg::layout(cg::shape(8, 8), cg::stride(8, 1));
        auto tile     = cg::layout(cg::shape(32), cg::stride(2));
        auto expected = cg::layout(cg::shape(cg::shape(4, 8), 2), cg::stride(cg::stride(16, 1), 8));

        test_logical_divide(layout, tile, expected);
    }
}

////////////////////////////////////////////////////////////////////////////////
// LogicalDivideTest.ZippedAndTiled
TEST(LogicalDivideTest, ZippedAndTiled)
{
    using shape           = cg::shape;
    using stride          = cg::stride;
    using layout          = cg::layout;
    using tile            = cg::tile;
    using composed_layout = cg::composed_layout;
    {
        // Tests that just printed the result from the old implementation of
        // zipped_divide and tiled_divide. Make sure that the new implementation
        // does match.
        auto shape_A = layout(shape(16, 16));
        auto shape_B = layout(shape(16, 16));
        auto shape_C = layout(shape(16, 16));
        auto shapes  = cg::make_layout(std::vector<layout>{shape_A, shape_B, shape_C});

        auto TV_A = layout(shape(shape(4, 8), 4),
                           stride(stride(64, 1), 16));
        auto TV_B = layout(shape(shape(4, 8), shape(2, 2)),
                           stride(stride(64, 1), stride(32, 16)));
        auto TV_C = layout(shape(shape(4, 8), 2),
                           stride(stride(32, 1), 16));
        auto TV   = tile(TV_A, TV_B, TV_C);

        EXPECT_EQ(to_string(zipped_divide(shapes, TV)),
                  "((((4,8),4),((4,8),(2,2)),((4,8),2)),(2,2,(2,2))):((((64,1),16),((64,1),(32,16)),((32,1),16)),(8,8,(8,128)))");
        EXPECT_EQ(to_string(tiled_divide(shapes, TV)),
                  "((((4,8),4),((4,8),(2,2)),((4,8),2)),2,2,(2,2)):((((64,1),16),((64,1),(32,16)),((32,1),16)),8,8,(8,128))");
    }

    {
        // Example taken from a real CuTe gemm example.
        // The LHS is ((2,(128,16)), (2,4,2))
        // The RHS is <_,<2,1>> (using <> for tiles until we complete with strides)
        auto a = layout(shape(shape(2, shape(128, 16)), shape(2, 4, 2)));
        auto b = tile(cg::_, tile(2, 1));
        // auto c_bymode = cg::layout(cg::shape(
        //     cg::shape(2, cg::shape(128, 16)),
        //     cg::shape(cg::shape(2, 1), cg::shape(1, 4), 2)));
        auto c_zipped = layout(shape(shape(2, shape(2, 1)),
                                     shape(shape(128, 16),
                                           shape(1, 4, 2))));
        auto c_tiled  = layout(shape(shape(2, shape(2, 1)),
                                    shape(128, 16),
                                    shape(1, 4, 2)));
        // The layout / tile logical divide's implementation has been removed
        // There is no direct use case yet
        // EXPECT_EQ(logical_divide(a, b).shape(), c_bymode.shape());
        EXPECT_EQ(zipped_divide(a, b).shape(), c_zipped.shape());
        EXPECT_EQ(tiled_divide(a, b).shape(), c_tiled.shape());
    }

    {
        auto a = layout(shape(8, 32), stride(1, 8));
        auto b = tile(layout(shape(4), stride(1)),
                      layout(shape(16), stride(2)));
        auto c = layout(shape(shape(4, 16), shape(2, 2)),
                        stride(stride(1, 16), stride(4, 8)));
        EXPECT_EQ(zipped_divide(a, b), c);
    }

    {
        // depth-0 tile which is layout
        auto a = layout(shape(8, 32), stride(1, 8));
        auto b = tile(layout(shape(4), stride(1)));

        EXPECT_EQ("4:1", cg::to_string(b));
        auto ref = layout(shape(4, 64), stride(1, 4));
        EXPECT_EQ(ref, zipped_divide(a, b));
    }

    {
        auto a = layout(shape(8, 32), stride(1, 8));
        auto b = shape(4, 2);
        EXPECT_EQ("((4,2),(2,16)):((1,8),(4,16))", cg::to_string(zipped_divide(a, b)));
    }

    {
        composed_layout a = cg::from_string<composed_layout>("S<2,1,2> o 0 o (8,32):(1,8)").value();
        auto            b = shape(4, 2);
        EXPECT_EQ("S<2,1,2> o 0 o ((4,2),(2,16)):((1,8),(4,16))", cg::to_string(zipped_divide(a, b)));
    }
    {
        layout a_row = cg::from_string<layout>("(?,?):(?,1)").value();
        tile   t     = cg::from_string<tile>("[?:1;?:1]").value();
        EXPECT_EQ("((?,?),(?,?)):((?,1),(?,?))",
                  cg::to_string(zipped_divide(a_row, t)));
    }
    {
        layout a_col = cg::from_string<layout>("(?,?):(1,?)").value();
        tile   t     = cg::from_string<tile>("[?:1;?:1]").value();
        EXPECT_EQ("((?,?),(?,?)):((1,?),(?,?))", cg::to_string(zipped_divide(a_col, t)));
    }
    {
        layout a = cg::from_string<layout>("((32,4,?),(32,4,?)):((16,4,?),(0,1,512))").value();
        tile   t = cg::from_string<tile>("[128:1;32:1]").value();
        EXPECT_EQ("(((32,4),32),(?,(4,?))):(((16,4),0),(?,(1,512)))",
                  cg::to_string(zipped_divide(a, t)));
    }
    {
        layout a(shape(shape(8, 8), shape(8, 8), 1),
                 stride(stride(512, 64), stride(1, 8), 4096));
        tile   b(layout(shape(128)), layout(shape(128)));
        layout expected_result = cg::from_string<layout>("(((8,16),128),(1,1,1)):(((512,64),1),(1024,128,4096))").value();
        EXPECT_EQ(zipped_divide(a, b), expected_result);
    }
    {
        layout a(shape(shape(8, 8), shape(8, 8), 1),
                 stride(stride(512, 64), stride(1, 8), 4096));
        shape  b(cg::wrap(128), cg::wrap(128));
        layout expected_result = cg::from_string<layout>("(((128),(128)),((1,8),(1,8),1)):(((512),(1)),((65536,64),(128,8),4096))").value();
        EXPECT_EQ(zipped_divide(a, b), expected_result);
    }
}

////////////////////////////////////////////////////////////////////////////////
// LogicalDivideTest.ScaledBasis
//
// Both target and tiler carry scaled-basis strides (different dimension
// assignments per mode). Exercises the pycute-style complement+extend path
// inside the divide call.
TEST(LogicalDivideTest, ScaledBasis)
{
    using sb_t = cg::scaled_basis;
    // target = (64,(64,2)):(1@1,(1@0,64@1))
    cg::layout target(cg::shape(64, cg::shape(64, 2)),
                      cg::stride(sb_t{1, 1}, cg::stride(sb_t{0, 1}, sb_t{1, 64})));
    // tiler  = (64,(16,2)):(1@0,(1@1,64@1))
    cg::layout tiler(cg::shape(64, cg::shape(16, 2)),
                     cg::stride(sb_t{0, 1}, cg::stride(sb_t{1, 1}, sb_t{1, 64})));
    cg::layout expected =
        cg::from_string<cg::layout>(
            "((64,(16,2)),(1,4)):((1@1,(1@0,64@1)),(64@1,16@0))")
            .value();
    EXPECT_EQ(cg::zipped_divide(target, tiler), expected);
}

TEST(LogicalDivideTest, ScaledBasisLowerRankTiler)
{
    using sb_t = cg::scaled_basis;
    // The tiler uses only basis 0; lay.shape has rank 2. The pycute extend
    // step adds a full-extent leftover in basis 1 for the dimension the
    // tiler doesn't cover.
    cg::layout lay(cg::shape(128, 64), cg::stride(sb_t{1, 1}, sb_t{0, 1}));
    cg::layout tiler(cg::shape(2), cg::stride(sb_t{0, 64}));
    cg::layout expected =
        cg::from_string<cg::layout>("(2,(64,64)):(64@1,(1@1,1@0))").value();
    EXPECT_EQ(cg::zipped_divide(lay, tiler), expected);
}

// Identity-layout tiler (b.stride() == make_basis_like(b.shape())) over a target
// layout with dynamic shape.  Semantically equivalent to dividing by
// shape_to_tile(b.shape()); the layout/layout dispatch must route to the
// per-mode tile path to avoid static_size() on the dynamic cosize inside
// complement()'s scaled-basis branch.
TEST(LogicalDivideTest, ScaledBasisIdentityTilerDynamicTarget)
{
    using dyn_t = cg::dynamic_t;
    using sb_t  = cg::scaled_basis;

    // target = (?,?):(?,1)
    cg::layout target(cg::shape(dyn_t{8}, dyn_t{}),
                      cg::stride(dyn_t{}, 1));
    // tiler  = (128,128):(1@0,1@1)  — i.e. make_identity_layout(shape(128,128))
    cg::layout tiler(cg::shape(128, 128),
                     cg::stride(sb_t{0, 1}, sb_t{1, 1}));

    auto result = cg::zipped_divide(target, tiler);

    // The result should be a valid rank-2 layout with the tiler's shape in
    // mode 0; we don't pin down the rest mode here because its dynamic
    // divisibility encoding is incidental.
    EXPECT_EQ(cg::rank(result), 2);
    EXPECT_EQ(cg::get(result, 0).shape(), cg::shape(128, 128));
}

// Static-shape companion to the above: dividing a static layout by an
// identity-layout tiler should match dividing by the corresponding shape/tile.
TEST(LogicalDivideTest, ScaledBasisIdentityTilerStaticEquivalence)
{
    using sb_t = cg::scaled_basis;

    cg::layout target(cg::shape(256, 384), cg::stride(1, 256));
    cg::layout identity_tiler(cg::shape(128, 128),
                              cg::stride(sb_t{0, 1}, sb_t{1, 1}));
    cg::shape  shape_tiler(128, 128);

    EXPECT_EQ(cg::zipped_divide(target, identity_tiler),
              cg::zipped_divide(target, shape_tiler));
}

////////////////////////////////////////////////////////////////////////////////
// LogicalDivideTest.CeilDiv
TEST(LogicalDivideTest, CeilDiv)
{
    {
        cg::layout target(cg::shape(16, 16));
        cg::layout tiler(cg::shape(4, 8), cg::stride(1, 8));
        EXPECT_EQ(ceil_div(target.shape(), tiler), get(zipped_divide(target, tiler), 1).shape());
    }

    {
        cg::layout target(cg::shape(16, 16));
        cg::tile   tiler(cg::layout(cg::shape(4)), cg::layout(cg::shape(8)));
        EXPECT_EQ(ceil_div(target.shape(), tiler), get(zipped_divide(target, tiler), 1).shape());
    }

    {
        cg::layout target(cg::shape(16, 16));
        cg::tile   tiler(4, 8);
        EXPECT_EQ(ceil_div(target.shape(), tiler), get(zipped_divide(target, tiler), 1).shape());
    }

    {
        auto shape_A = cg::layout(cg::shape(16, 16));
        auto shape_B = cg::layout(cg::shape(16, 16));
        auto shape_C = cg::layout(cg::shape(16, 16));
        auto target  = cg::make_layout(std::vector<cg::layout>{shape_A, shape_B, shape_C});

        auto       TV_A = cg::layout(cg::shape(cg::shape(4, 8), 4),
                               cg::stride(cg ::stride(64, 1), 16));
        cg::layout TV_B(cg::shape(cg::shape(4, 8), cg::shape(2, 2)),
                        cg::stride(cg::stride(64, 1), cg::stride(32, 16)));
        cg::layout TV_C(cg::shape(cg::shape(4, 8), 2),
                        cg::stride(cg::stride(32, 1), 16));
        cg::tile   tiler(TV_A, TV_B, TV_C);

        EXPECT_EQ(ceil_div(target.shape(), tiler), get(zipped_divide(target, tiler), 1).shape());
    }
}

////////////////////////////////////////////////////////////////////////////////
// LogicalDivideTest.Coord
TEST(LogicalDivideTest, Coord)
{
    using sb_t = cg::scaled_basis;
    { // (8, 8):(9, 1) / 4:1@0  =>  (4, (2, 8)):(9, (36, 1))
        auto layout   = cg::layout(cg::shape(8, 8), cg::stride(9, 1));
        auto tile     = cg::layout(cg::shape(4), cg::stride(cg::E(0)));
        auto expected = cg::layout(cg::shape(4, cg::shape(2, 8)), cg::stride(9, cg::stride(36, 1)));

        test_logical_divide(layout, tile, expected);
    }
    { // (8, 8):(9, 1) / 4:1@1  =>  (4, (8, 2)):(1, (9, 4))
        auto layout   = cg::layout(cg::shape(8, 8), cg::stride(9, 1));
        auto tile     = cg::layout(cg::shape(4), cg::stride(cg::E(1)));
        auto expected = cg::layout(cg::shape(4, cg::shape(8, 2)), cg::stride(1, cg::stride(9, 4)));

        test_logical_divide(layout, tile, expected);
    }
    { // (8, 8):(9, 1) / 4:2@0  =>  (4, (2, 8)):(18, (9, 1))
        auto layout   = cg::layout(cg::shape(8, 8), cg::stride(9, 1));
        auto tile     = cg::layout(cg::shape(4), cg::stride(sb_t{/*mode=*/0, /*value=*/2}));
        auto expected = cg::layout(cg::shape(4, cg::shape(2, 8)), cg::stride(18, cg::stride(9, 1)));

        test_logical_divide(layout, tile, expected);
    }
    { // (8, 8):(9, 1) / 4:2@1  =>  (4, (8, 2)):(2, (9, 1))
        auto layout   = cg::layout(cg::shape(8, 8), cg::stride(9, 1));
        auto tile     = cg::layout(cg::shape(4), cg::stride(sb_t{/*mode=*/1, /*value=*/2}));
        auto expected = cg::layout(cg::shape(4, cg::shape(8, 2)), cg::stride(2, cg::stride(9, 1)));

        test_logical_divide(layout, tile, expected);
    }
    { // (8, 8):(9, 1) / (4, 4):(1@1, 2@0)  =>  ((4, 4), (2, 2)):((1, 18), (9, 4))
        auto layout   = cg::layout(cg::shape(8, 8), cg::stride(9, 1));
        auto tile     = cg::layout(cg::shape(4, 4), cg::stride(sb_t{/*mode=*/1, /*value=*/1}, sb_t{/*mode=*/0, /*value=*/2}));
        auto expected = cg::layout(cg::shape(cg::shape(4, 4), cg::shape(2, 2)), cg::stride(cg::stride(1, 18), cg::stride(9, 4)));

        test_logical_divide(layout, tile, expected);
    }
    { // (8, 8):(9, 1) / (5, 7):(3@1, 2@0)  =>  ((5, 7), (2, 3)):((3, 18), (9, 1))
        auto layout   = cg::layout(cg::shape(8, 8), cg::stride(9, 1));
        auto tile     = cg::layout(cg::shape(5, 7), cg::stride(sb_t{/*mode=*/1, /*value=*/3}, sb_t{/*mode=*/0, /*value=*/2}));
        auto expected = cg::layout(cg::shape(cg::shape(5, 7), cg::shape(2, 3)), cg::stride(cg::stride(3, 18), cg::stride(9, 1)));

        test_logical_divide(layout, tile, expected);
    }
}
