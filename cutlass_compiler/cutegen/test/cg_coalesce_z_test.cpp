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

void test_coalesce_z(const cg::layout& layout,
                     const cg::layout& layoutExpected)
{
    auto coalesce_layout = cg::coalesce_z(layout);

    // Verify that coalesce_z() result has depth 1
    EXPECT_LE(cg::depth(coalesce_layout), 1);
    if(cg::is_static(layout))
    {
        // Verify that the size of the result is the same as the size of the input
        EXPECT_EQ(cg::static_size(coalesce_layout), cg::static_size(layout));

        // Avoid comparing offsets for coordinate layouts for now, as zero
        // comparisons are not implemented yet.
        if(cg::holds_int(cg::coprofile(layout)))
        {
            // Verify that the result layout mapping matches that of the input.
            // We arbitrarily select a domain 42 times as large as the input
            // domain to verify that coalesce_z() does not change the mapping
            // for integers outside the domain.
            for(int i = 0; i < 42 * cg::static_size(layout); ++i)
            {
                EXPECT_EQ(coalesce_layout(i), layout(i));
            }
        }
    }
    // Verify that the coalesce_z() result matches the result given (which is
    // usually obtained from CuTe C++).
    EXPECT_EQ(coalesce_layout, layoutExpected);
}

TEST(CoalesceZTest, Basic)
{
    using dyn_t = cg::dynamic_t;
    {
        // 1:0 ==> 1:0
        auto ly = cg::layout(cg::shape(1), cg::stride(0));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(1), cg::stride(0)));
    }
    {
        // 1:1 ==> 1:1
        auto ly = cg::layout(cg::shape(1), cg::stride(1));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(1), cg::stride(1)));
    }
    {
        // (1,1):(5,7) ==> 1:7
        auto ly = cg::layout(cg::shape(1, 1), cg::stride(5, 7));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(1), cg::stride(7)));
    }
    {
        // (2,4):(1,2) ==> 8:1
        auto ly = cg::layout(cg::shape(2, 4), cg::stride(1, 2));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(8), cg::stride(1)));
    }
    {
        // (2,4):(4,1) ==> (2,4):(4,1)
        auto ly = cg::layout(cg::shape(2, 4), cg::stride(4, 1));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, 4), cg::stride(4, 1)));
    }
    {
        // (2,4,6):(1,2,8) ==> 48:1
        auto ly = cg::layout(cg::shape(2, 4, 6), cg::stride(1, 2, 8));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(48), cg::stride(1)));
    }
    {
        // (2,4,6):(24,6,1) ==> (2,4,6):(24,6,1)
        auto ly = cg::layout(cg::shape(2, 4, 6), cg::stride(24, 6, 1));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, 4, 6), cg::stride(24, 6, 1)));
    }
    {
        // (2,(4,6)):(1,(2,8)) ==> 48:1
        auto ly = cg::layout(cg::shape(2, cg::shape(4, 6)), cg::stride(1, cg::stride(2, 8)));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(48), cg::stride(1)));
    }
    {
        // (2,4,6):(1,6,2) ==> (2,4,6):(1,6,2)
        auto ly = cg::layout(cg::shape(2, 4, 6), cg::stride(1, 6, 2));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, 4, 6), cg::stride(1, 6, 2)));
    }
    {
        // (2,1,6):(1,7,2) ==> 12:1
        auto ly = cg::layout(cg::shape(2, 1, 6), cg::stride(1, 7, 2));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(12), cg::stride(1)));
    }
    {
        // (2,1,6):(4,7,8) ==> 12:4
        auto ly = cg::layout(cg::shape(2, 1, 6), cg::stride(4, 7, 8));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(12), cg::stride(4)));
    }
    {
        // (2,1,6,1):(4,7,8,0) ==> (12,1):(4,0)
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(4, 7, 8, 0));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(12, 1), cg::stride(4, 0)));
    }
    {
        // (2,1,6,1):(4,7,8,57) ==> (12,1):(4,57)
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(4, 7, 8, 57));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(12, 1), cg::stride(4, 57)));
    }
    {
        // (2,1,6,1):(1,7,8,0) ==> (2,6,1):(1,8,0)
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(1, 7, 8, 0));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, 6, 1), cg::stride(1, 8, 0)));
    }
    {
        // (2,1,6,1):(1,7,8,57) ==> (2,6,1):(1,8,57)
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(1, 7, 8, 57));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, 6, 1), cg::stride(1, 8, 57)));
    }
    {
        // (2,1,6,1):(1,7,8,48) ==> (2,6):(1,8)
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(1, 7, 8, 48));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, 6), cg::stride(1, 8)));
    }
    {
        // (2,1,3):(2,4,4) ==> 6:2
        auto ly = cg::layout(cg::shape(2, 1, 3), cg::stride(2, 4, 4));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(6), cg::stride(2)));
    }
    {
        // ((2,2),(2,2)):((1,4),(8,32)) ==> (2,4,2):(1,4,32)
        auto ly = cg::layout(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                             cg::stride(cg::stride(1, 4), cg::stride(8, 32)));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, 4, 2), cg::stride(1, 4, 32)));
    }
    // Tests that are not currently part of PyCuTe
    {
        // (2,1,6):(1,6,2) ==> 12:1
        auto ly = cg::layout(cg::shape(2, 1, 6), cg::stride(1, 6, 2));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(12), cg::stride(1)));
    }
    {
        // (2,1,6,1):(1,6,2,0) ==> (12,1):(1,0)
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(1, 6, 2, 0));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(12, 1), cg::stride(1, 0)));
    }
    {
        // (2,1,6):(1,?,2) ==> 12:1
        auto ly = cg::layout(cg::shape(2, 1, 6), cg::stride(1, dyn_t{}, 2));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(12), cg::stride(1)));
    }
    {
        // (2,1,6):(4,?,8) ==> 12:4
        auto ly = cg::layout(cg::shape(2, 1, 6), cg::stride(4, dyn_t{}, 8));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(12), cg::stride(4)));
    }
    {
        // (?,4,6):(1,?,?) ==> (?,4,6):(1,?,?)
        auto ly = cg::layout(cg::shape(dyn_t{}, 4, 6), cg::stride(1, dyn_t{}, dyn_t{}));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(dyn_t{}, 4, 6), cg::stride(1, dyn_t{}, dyn_t{})));
    }
    {
        // (2,?,6):(1,2,?) ==> (2,?,6):(1,2,?)
        auto ly = cg::layout(cg::shape(2, dyn_t{}, 6), cg::stride(1, 2, dyn_t{}));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, dyn_t{}, 6), cg::stride(1, 2, dyn_t{})));
    }
    {
        // (2,4,?):(1,2,8) ==> (8,?):(1,8)
        auto ly = cg::layout(cg::shape(2, 4, dyn_t{}), cg::stride(1, 2, 8));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(8, dyn_t{}), cg::stride(1, 8)));
    }
    {
        // (?,4,6):(24,6,1) ==> (?,4,6):(24,6,1)
        auto ly = cg::layout(cg::shape(dyn_t{}, 4, 6), cg::stride(24, 6, 1));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(dyn_t{}, 4, 6), cg::stride(24, 6, 1)));
    }
    {
        // (2,?,6):(?,6,1) ==> (2,?,6):(?,6,1)
        auto ly = cg::layout(cg::shape(2, dyn_t{}, 6), cg::stride(dyn_t{}, 6, 1));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, dyn_t{}, 6), cg::stride(dyn_t{}, 6, 1)));
    }
    {
        // (2,4,?):(?,?,1) ==> (2,4,?):(?,?,1)
        auto ly = cg::layout(cg::shape(2, 4, dyn_t{}), cg::stride(dyn_t{}, dyn_t{}, 1));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, 4, dyn_t{}), cg::stride(dyn_t{}, dyn_t{}, 1)));
    }
    {
        // (2,1,3):(3,0,1) ==> (2,3):(3,1)
        auto ly = cg::layout(cg::shape(2, 1, 3), cg::stride(3, 0, 1));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, 3), cg::stride(3, 1)));
    }
    {
        // (2,?,3):(?,3,1) ==> (2,?,3):(?,3,1)
        auto ly = cg::layout(cg::shape(2, dyn_t{}, 3), cg::stride(dyn_t{}, 3, 1));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, dyn_t{}, 3), cg::stride(dyn_t{}, 3, 1)));
    }
    {
        // (2,?,3):(2,?,4) ==> (2,?,3):(2,?,4)
        auto ly = cg::layout(cg::shape(2, dyn_t{}, 3), cg::stride(2, dyn_t{}, 4));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, dyn_t{}, 3), cg::stride(2, dyn_t{}, 4)));
    }
    {
        // (2,?,3):(2,0,4) ==> (2,?,3):(2,0,4)
        auto ly = cg::layout(cg::shape(2, dyn_t{}, 3), cg::stride(2, 0, 4));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, dyn_t{}, 3), cg::stride(2, 0, 4)));
    }
}

TEST(CoalesceZTest, Coord)
{
    using sb_t = cg::scaled_basis;
    { // 1:1@0  =>  1:1@0
        auto ly = cg::layout(cg::shape(1), cg::E(0));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(1), cg::stride(cg::E(0))));
    }
    { // 1:1@1  =>  1:1@1
        auto ly = cg::layout(cg::shape(1), cg::stride(cg::E(1)));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(1), cg::stride(cg::E(1))));
    }
    { // (1, 1):(1@0, 1@1)  =>  1:1@1
        auto ly = cg::layout(cg::shape(1, 1), cg::stride(cg::E(0), cg::E(1)));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(1), cg::stride(cg::E(1))));
    }
    { // (2, 4):(1@0, 1@1)  =>  (2, 4):(1@0, 1@1)
        auto ly = cg::layout(cg::shape(2, 4), cg::stride(cg::E(0), cg::E(1)));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, 4), cg::stride(cg::E(0), cg::E(1))));
    }
    { // (2, 4):(1@1, 2@1)  =>  8:1@1
        auto ly = cg::layout(cg::shape(2, 4), cg::stride(cg::E(1), sb_t{/*mode=*/1, /*value=*/2}));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(8), cg::stride(cg::E(1))));
    }
    { // (2, 1, 6, 1):(1@1@1, 1@3@2, 2@1@1, 1@3@2)  =>  (12, 1):(1@1@1, 1@3@2)
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(sb_t({1, 1}, 1), sb_t({2, 3}, 1), sb_t({1, 1}, 2), sb_t({2, 3}, 1)));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(12, 1), cg::stride(cg::E(1, 1), sb_t{{2, 3}, 1})));
    }
    { // (2, 1, 6, 1):(1@1@1, 1@3@2, 2@0@1, 1@3@2)  =>  (2, 6, 1):(1@1@1, 2@0@1, 1@3@2)
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(sb_t({1, 1}, 1), sb_t({2, 3}, 1), sb_t({1, 0}, 2), sb_t({2, 3}, 1)));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, 6, 1), cg::stride(cg::E(1, 1), sb_t{{1, 0}, 2}, sb_t{{2, 3}, 1})));
    }
    { // (2, 1, 6, 1):(1@0@1, 1@3@2, 2@0@1, 12@0@1)  =>  12:1@0@1
        auto ly = cg::layout(cg::shape(2, 1, 6, 1), cg::stride(sb_t({1, 0}, 1), sb_t({2, 3}, 1), sb_t({1, 0}, 2), sb_t({1, 0}, 12)));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(12), cg::stride(cg::E(1, 0))));
    }
    { // ((2, 2), (2, 2)):((1@0, 1@1), (2@1, 2@0))  =>  (2, 4, 2):(1@0, 1@1, 2@0)
        auto ly = cg::layout(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                             cg::stride(cg::stride(cg::E(0), cg::E(1)), cg::stride(sb_t{1, 2}, sb_t{0, 2})));
        test_coalesce_z(ly,
                        cg::layout(cg::shape(2, 4, 2), cg::stride(cg::E(0), cg::E(1), sb_t{0, 2})));
    }
}
