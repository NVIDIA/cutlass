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

#include "gtest/gtest.h"

namespace cg = cutegen;

namespace
{
cg::layout test_composition(const cg::layout& layoutA, const cg::layout& layoutB)
{
    auto layoutR = composition(layoutA, layoutB);
    if(!cg::is_valid(layoutR))
    {
        EXPECT_TRUE(false) << "composition(" << layoutA << ", " << layoutB << ") is invalid";
        return layoutR;
    }
    // printf("%s o %s => %s\n",
    //        cg::to_string(layoutA).c_str(),
    //        cg::to_string(layoutB).c_str(),
    //        cg::to_string(layoutR).c_str());
    // Only test layout mapping for static test cases, since we aren't able to
    // generate/lower arithmetic operations in this unit test.
    if(cg::is_static(layoutR))
    {
        // Test that layout B is compatible with layout R. Checking
        // compatibility is only possible here for static layouts, as the
        // product() function is used to for mode comparisons.
        EXPECT_TRUE(compatible(layoutB, layoutR));
        // Test that R(c) = A(B(c)) for all coordinates c in layoutB
        // It is on purpose that we test A(B(i)) when B(i) goes out of the domain of A to verify
        // consistent OOB behavior
        for(int i = 0; i < cg::static_size(layoutR); ++i)
        {
            EXPECT_EQ(layoutR(i), layoutA(layoutB(i))) << "R(" << i << ") != A(B("
                                                       << i << ")) with R = " << layoutR
                                                       << ", A = " << layoutA
                                                       << ", B = " << layoutB;
        }
    }
    return layoutR;
}
} // namespace

////////////////////////////////////////////////////////////////////////
// CompositionTest.Basic
TEST(CompositionTest, Basic)
{
    using layout = cg::layout;
    using shape  = cg::shape;
    using stride = cg::stride;
    using dyn_t  = cg::dynamic_t;
    {
        auto a = layout(shape(1), stride(0));
        auto b = layout(shape(1), stride(0));

        auto r = test_composition(a, b);
        // 1:0 o 1:0  =>  1:0
        EXPECT_EQ(r, layout(shape(1), stride(0)));
    }
    {
        auto a = layout(shape(1), stride(0));
        auto b = layout(shape(1), stride(1));

        auto r = test_composition(a, b);
        // 1:0 o 1:1  =>  1:0
        EXPECT_EQ(r, layout(shape(1), stride(0)));
    }
    {
        auto a = layout(shape(1), stride(1));
        auto b = layout(shape(1), stride(0));

        auto r = test_composition(a, b);
        // 1:1 o 1:0  =>  1:0
        EXPECT_EQ(r, layout(shape(1), stride(0)));
    }
    {
        auto a = layout(shape(1), stride(1));
        auto b = layout(shape(1), stride(1));

        auto r = test_composition(a, b);
        // 1:1 o 1:1  =>  1:1
        EXPECT_EQ(r, layout(shape(1), stride(1)));
    }
    {
        auto a = layout(shape(cg::wrap(4)));
        auto b = layout(shape(cg::wrap(4)));

        auto r = test_composition(a, b);
        // (4):(1) o (4):(1)  =>  (4):(1)
        EXPECT_EQ(r, layout(shape(cg::wrap(4)), stride(cg::wrap(1))));
    }
    {
        auto a = layout(shape(cg::wrap(4)), stride(cg::wrap(2)));
        auto b = layout(shape(cg::wrap(4)));

        auto r = test_composition(a, b);
        // (4):(2) o (4):(1)  =>  (4):(2)
        EXPECT_EQ(r, layout(shape(cg::wrap(4)), stride(cg::wrap(2))));
    }
    {
        auto a = layout(shape(cg::wrap(4)), stride(cg::wrap(0)));
        auto b = layout(shape(cg::wrap(4)));

        auto r = test_composition(a, b);
        // (4):(0) o (4):(1)  =>  (4):(0)
        EXPECT_EQ(r, layout(shape(cg::wrap(4)), stride(cg::wrap(0))));
    }
    {
        auto a = layout(shape(cg::wrap(4)));
        auto b = layout(shape(cg::wrap(4)), stride(cg::wrap(0)));

        auto r = test_composition(a, b);
        // (4):(1) o (4):(0)  =>  (1):(0)
        EXPECT_EQ(r, layout(shape(cg::wrap(4)), stride(cg::wrap(0))));
    }
    {
        auto a = layout(shape(cg::wrap(4)));
        auto b = layout(shape(cg::wrap(1)), stride(cg::wrap(0)));

        auto r = test_composition(a, b);
        // (4):(1) o (1):(0)  =>  (1):(0)
        EXPECT_EQ(r, layout(shape(cg::wrap(1)), stride(cg::wrap(0))));
    }
    {
        auto a = layout(shape(cg::wrap(4)));
        auto b = layout(shape(cg::wrap(2)));

        auto r = test_composition(a, b);
        // (4):(1) o (2):(1)  =>  (2):(1)
        EXPECT_EQ(r, layout(shape(cg::wrap(2)), stride(cg::wrap(1))));
    }
    {
        auto a = layout(shape(cg::wrap(4)), stride(cg::wrap(2)));
        auto b = layout(shape(cg::wrap(2)));

        auto r = test_composition(a, b);
        // (4):(2) o (2):(1)  =>  (2):(2)
        EXPECT_EQ(r, layout(shape(cg::wrap(2)), stride(cg::wrap(2))));
    }
    {
        auto a = layout(shape(cg::wrap(4)));
        auto b = layout(shape(cg::wrap(2)), stride(cg::wrap(2)));

        auto r = test_composition(a, b);
        // (4):(1) o (2):(2)  =>  (2):(2)
        EXPECT_EQ(r, layout(shape(cg::wrap(2)), stride(cg::wrap(2))));
    }
    {
        auto a = layout(shape(cg::wrap(4)), stride(cg::wrap(2)));
        auto b = layout(shape(cg::wrap(2)), stride(cg::wrap(2)));

        auto r = test_composition(a, b);
        // (4):(2) o (2):(2)  =>  (2):(4)
        EXPECT_EQ(r, layout(shape(cg::wrap(2)), stride(cg::wrap(4))));
    }
    {
        auto a = layout(shape(4, 3));
        auto b = layout(shape(cg::wrap(12)));

        auto r = test_composition(a, b);
        // (4,3):(1,4) o (12):(1)  =>  (12):(1)
        EXPECT_EQ(r, layout(shape(cg::wrap(12)), stride(cg::wrap(1))));
    }
    {
        auto a = layout(shape(cg::wrap(12)));
        auto b = layout(shape(4, 3));

        auto r = test_composition(a, b);
        // (12):(1) o (4,3):(1,4)  =>  (4,3):(1,4)
        EXPECT_EQ(r, layout(shape(4, 3), stride(1, 4)));
    }
    {
        auto a = layout(shape(cg::wrap(12)), stride(cg::wrap(2)));
        auto b = layout(shape(4, 3));

        auto r = test_composition(a, b);
        // (12):(2) o (4,3):(1,4)  =>  (4,3):(2,8)
        EXPECT_EQ(r, layout(shape(4, 3), stride(2, 8)));
    }
    {
        auto a = layout(shape(cg::wrap(12)));
        auto b = layout(shape(4, 3), stride(3, 1));

        auto r = test_composition(a, b);
        // (12):(1) o (4,3):(3,1)  =>  (4,3):(3,1)
        EXPECT_EQ(r, layout(shape(4, 3), stride(3, 1)));
    }
    {
        auto a = layout(shape(cg::wrap(12)), stride(cg::wrap(2)));
        auto b = layout(shape(4, 3), stride(3, 1));

        auto r = test_composition(a, b);
        // (12):(2) o (4,3):(3,1)  =>  (4,3):(6,2)
        EXPECT_EQ(r, layout(shape(4, 3), stride(6, 2)));
    }
    {
        auto a = layout(shape(12));
        auto b = layout(shape(2, 3), stride(2, 4));

        auto r = test_composition(a, b);
        // (12):(1) o (2,3):(2,4)  =>  (2,3):(2,4)
        EXPECT_EQ(r, layout(shape(2, 3), stride(2, 4)));
    }
    {
        auto a = layout(shape(4, 3));
        auto b = layout(shape(4, 3));

        auto r = test_composition(a, b);
        // (4,3):(1,4) o (4,3):(1,4)  =>  (4,3):(1,4)
        EXPECT_EQ(r, layout(shape(4, 3), stride(1, 4)));
    }
    {
        auto a = layout(shape(4, 3));
        auto b = layout(shape(cg::wrap(6)));

        auto r = test_composition(a, b);
        // (4,3):(1,4) o (6):(1)  =>  (6):(1)
        EXPECT_EQ(r, layout(shape(cg::wrap(6)), stride(cg::wrap(1))));
    }
    {
        auto a = layout(shape(4, 3));
        auto b = layout(shape(cg::wrap(6)), stride(cg::wrap(2)));

        auto r = test_composition(a, b);
        // (4,3):(1,4) o (6):(2)  =>  (6):(2)
        EXPECT_EQ(r, layout(shape(cg::wrap(6)), stride(cg::wrap(2))));
    }
    {
        auto a = layout(shape(4, 3));
        auto b = layout(shape(6, 2), stride(2, 1));

        auto r = test_composition(a, b);
        // (4,3):(1,4) o (6,2):(2,1)  =>  (6,2):(2,1)
        EXPECT_EQ(r, layout(shape(6, 2), stride(2, 1)));
    }
    {
        auto a = layout(shape(4, 3));
        auto b = layout(shape(4, 3), stride(3, 1));

        auto r = test_composition(a, b);
        // (4,3):(1,4) o (4,3):(3,1)  =>  (4,3):(3,1)
        EXPECT_EQ(r, layout(shape(4, 3), stride(3, 1)));
    }
    {
        auto a = layout(shape(4, 3), stride(3, 1));
        auto b = layout(shape(4, 3));

        auto r = test_composition(a, b);
        // (4,3):(3,1) o (4,3):(1,4)  =>  (4,3):(3,1)
        EXPECT_EQ(r, layout(shape(4, 3), stride(3, 1)));
    }
    {
        auto a = layout(shape(4, 3), stride(3, 1));
        auto b = layout(shape(cg::wrap(12)));

        auto r = test_composition(a, b);
        // (4,3):(3,1) o (12):(1)  =>  ((4,3)):((3,1))
        EXPECT_EQ(r, layout(cg::wrap(shape(4, 3)), cg::wrap(stride(3, 1))));
    }
    {
        auto a = layout(shape(4, 3), stride(3, 1));
        auto b = layout(shape(cg::wrap(6)), stride(cg::wrap(2)));

        auto r = test_composition(a, b);
        // (4,3):(3,1) o (6):(2)  =>  ((2,3)):((6,1))
        EXPECT_EQ(r, layout(cg::wrap(shape(2, 3)), cg::wrap(stride(6, 1))));
    }
    {
        auto a = layout(shape(4, 3), stride(3, 1));
        auto b = layout(shape(6, 2), stride(2, 1));

        auto r = test_composition(a, b);
        // (4,3):(3,1) o (6,2):(2,1)  =>  ((2,3),2):((6,1),3)
        EXPECT_EQ(r, layout(shape(shape(2, 3), 2), stride(stride(6, 1), 3)));
    }
    {
        auto a = layout(shape(8, 8));
        auto b = layout(shape(shape(2, 2, 2), shape(2, 2, 2)),
                        stride(stride(1, 16, 4), stride(8, 2, 32)));
        auto r = test_composition(a, b);
        // (8,8):(1,8) o ((2,2,2),(2,2,2)):((1,16,4),(8,2,32))  =>  ((2,2,2),(2,2,2)):((1,16,4),(8,2,32))
        EXPECT_EQ(r, layout(shape(shape(2, 2, 2), shape(2, 2, 2)), stride(stride(1, 16, 4), stride(8, 2, 32))));
    }
    {
        auto a = layout(shape(8, 8), stride(8, 1));
        auto b = layout(shape(shape(2, 2, 2), shape(2, 2, 2)),
                        stride(stride(1, 16, 4), stride(8, 2, 32)));
        auto r = test_composition(a, b);
        // (8,8):(8,1) o ((2,2,2),(2,2,2)):((1,16,4),(8,2,32))  =>  ((2,2,2),(2,2,2)):((8,2,32),(1,16,4))
        EXPECT_EQ(r, layout(shape(shape(2, 2, 2), shape(2, 2, 2)), stride(stride(8, 2, 32), stride(1, 16, 4))));
    }
    {
        auto a = layout(shape(shape(2, 2, 2), shape(2, 2, 2)),
                        stride(stride(1, 16, 4), stride(8, 2, 32)));
        auto b = layout(shape(8), stride(4));
        auto r = test_composition(a, b);
    }
    {
        auto a = layout(shape(shape(4, 2)), stride(stride(1, 16)));
        auto b = layout(shape(4, 2), stride(2, 1));
        auto r = test_composition(a, b);
        // ((4,2)):((1,16)) o (4,2):(2,1)  =>  ((2,2),2):((2,16),1)
        EXPECT_EQ(r, layout(shape(shape(2, 2), 2), stride(stride(2, 16), 1)));
    }
    {
        auto a = layout(shape(2, 2), stride(2, 1));
        auto b = layout(shape(2, 2), stride(2, 1));
        auto r = test_composition(a, b);
        // (2,2):(2,1) o (2,2):(2,1)  =>  (2,2):(1,2)
        EXPECT_EQ(r, layout(shape(2, 2), stride(1, 2)));
    }
    {
        auto a = layout(shape(4, 8, 2));
        auto b = layout(shape(2, 2, 2), stride(2, 8, 1));
        auto r = test_composition(a, b);
        // (4,8,2):(1,4,32) o (2,2,2):(2,8,1)  =>  (2,2,2):(2,8,1)
        EXPECT_EQ(r, layout(shape(2, 2, 2), stride(2, 8, 1)));
    }
    {
        auto a = layout(shape(4, 8, 2), stride(2, 8, 1));
        auto b = layout(shape(2, 2, 2), stride(1, 8, 2));
        auto r = test_composition(a, b);
        // (4,8,2):(2,8,1) o (2,2,2):(1,8,2)  =>  (2,2,2):(2,16,4)
        EXPECT_EQ(r, layout(shape(2, 2, 2), stride(2, 16, 4)));
    }
    {
        auto a = layout(shape(4, 8, 2), stride(2, 8, 1));
        auto b = layout(shape(4, 2, 2), stride(2, 8, 1));
        auto r = test_composition(a, b);
        // (4,8,2):(2,8,1) o (4,2,2):(2,8,1)  =>  (4,2,2):(4,16,2)
        EXPECT_EQ(r, layout(shape(4, 2, 2), stride(4, 16, 2)));
    }
    // -------------------------------
    // Dynamic shapes/strides
    // -------------------------------
    {
        auto a = layout(shape(dyn_t{}), stride(dyn_t{}));
        auto b = layout(shape(4), stride(1));
        auto r = test_composition(a, b);
        // ?:? o 4:1  =>  4:?
        EXPECT_EQ(r, layout(shape(4), stride(dyn_t{})));
    }
    {
        auto a = layout(shape(dyn_t{}), stride(dyn_t{}));
        auto b = layout(shape(4), stride(dyn_t{}));
        auto r = test_composition(a, b);
        // ?:?: o 4:?  =>  4:?
        EXPECT_EQ(r, layout(shape(4), stride(dyn_t{})));
    }
    {
        auto a = layout(shape(dyn_t{}), stride(1));
        auto b = layout(shape(4), stride(dyn_t{}));
        auto r = test_composition(a, b);
        // ?:1 o 4:?  =>  4:?
        EXPECT_EQ(r, layout(shape(4), stride(dyn_t{})));
    }
    {
        auto a = layout(shape(dyn_t{}), stride(1));
        auto b = layout(shape(4), stride(1));
        auto r = test_composition(a, b);
        // ?:1 o 4:1  =>  4:1
        EXPECT_EQ(r, layout(shape(4), stride(1)));
    }
    {
        auto a = layout(shape(dyn_t{}, dyn_t{}), stride(dyn_t{}, dyn_t{}));
        auto b = layout(shape(cg::wrap(4)), stride(cg::wrap(1)));
        auto r = test_composition(a, b);
        // (?,?):(?,?) o (4):(1)  =>  ((?,?)):((?,?))
        EXPECT_EQ(r, layout(cg::wrap(shape(dyn_t{}, dyn_t{})), cg::wrap(stride(dyn_t{}, dyn_t{}))));
    }
    {
        auto a = layout(shape(dyn_t{}), stride(dyn_t{}));
        auto b = layout(shape(dyn_t{}), stride(dyn_t{}));
        auto r = test_composition(a, b);
        // ?:? o ?:?  =>  ?:?
        EXPECT_EQ(r, layout(shape(dyn_t{}), stride(dyn_t{})));
    }
    // -------------------------------
    // RHS ScaledBasis stride + dynamic shape (github.com/NVIDIA/cutlass/issues/3470)
    // -------------------------------
    {
        // scaled_basis(mode, value)
        auto a = layout(shape(4, 4), stride(4, 1));
        auto b = layout(shape(dyn_t{}, 4), stride(cg::scaled_basis(1, 1), cg::scaled_basis(0, 1)));
        auto r = test_composition(a, b);
        // (4,4):(4,1) o (?,4):(1@1,1@0)  =>  (?,4):(1,4)
        EXPECT_EQ(r, layout(shape(dyn_t{}, 4), stride(1, 4)));
    }
    {
        // Exact repro from the issue: (4096,8192):(1,4096) o (32,?,8,128):(E(0),8*E(1),E(1),32*E(0))
        auto a = layout(shape(4096, 8192), stride(1, 4096));
        auto b = layout(shape(32, dyn_t{}, 8, 128),
                        stride(cg::scaled_basis(0, 1),
                                cg::scaled_basis(1, 8),
                                cg::scaled_basis(1, 1),
                                cg::scaled_basis(0, 32)));
        auto r = test_composition(a, b);
        EXPECT_TRUE(cg::is_valid(r));
    }
    // -------------------------------
    // cosize(b) > size(a) and divisibility
    // -------------------------------
    {
        auto a = layout(shape(cg::wrap(1)), stride(cg::wrap(0)));
        auto b = layout(shape(cg::wrap(4)));
        auto r = test_composition(a, b);
        // (1):(0) o (4):(1)  =>  (4):(0)
        EXPECT_EQ(r, layout(shape(cg::wrap(4)), stride(cg::wrap(0))));
    }
    {
        auto a = layout(shape(cg::wrap(1)), stride(cg::wrap(1)));
        auto b = layout(shape(cg::wrap(4)));
        auto r = test_composition(a, b);
        // (1):(1) o (4):(1)  =>  (4):(1)
        EXPECT_EQ(r, layout(shape(cg::wrap(4)), stride(cg::wrap(1))));
    }
    {
        auto a = layout(shape(cg::wrap(4)));
        auto b = layout(shape(cg::wrap(4)), stride(cg::wrap(2)));
        auto r = test_composition(a, b);
        // (4):(1) o (4):(2)  =>  (4):(2)
        EXPECT_EQ(r, layout(shape(cg::wrap(4)), stride(cg::wrap(2))));
    }
    // Last mode gets extended
    {
        auto a = layout(shape(4, 3), stride(3, 1));
        auto b = layout(shape(cg::wrap(24)));
        auto r = test_composition(a, b);
        // (4,3):(3,1) o (24):(1)  =>  ((4,6)):((3,1))
        EXPECT_EQ(r, layout(cg::wrap(shape(4, 6)), cg::wrap(stride(3, 1))));
    }
    // Last mode extension even without last mode divisibility
    {
        auto a = layout(shape(4, 3), stride(3, 1));
        auto b = layout(shape(cg::wrap(8)));
        auto r = test_composition(a, b);
        // (4,3):(3,1) o (8):(1)  =>  ((4,2)):((3,1))
        EXPECT_EQ(r, layout(cg::wrap(shape(4, 2)), cg::wrap(stride(3, 1))));
    }
    // Capping a layout with 1:0 extends in stride-0
    {
        auto a = layout(shape(4, 3, 1), stride(3, 1, 0));
        auto b = layout(shape(cg::wrap(24)));
        auto r = test_composition(a, b);
        // (4,3,1):(3,1,0) o (24):(1)  =>  ((4,3,2)):((3,1,0))
        EXPECT_EQ(r, layout(cg::wrap(shape(4, 3, 2)), cg::wrap(stride(3, 1, 0))));
    }
    {
        auto a = layout(shape(4, 3, 1), stride(3, 1, 0));
        auto b = layout(shape(cg::wrap(4)));
        auto r = test_composition(a, b);
        // (4,3,1):(3,1,0) o (4):(1)  =>  (4):(3)
        EXPECT_EQ(r, layout(shape(cg::wrap(4)), stride(cg::wrap(3))));
    }
    // Pre-coalesced LHS
    {
        auto a = layout(shape(4, 6, 8), stride(1, 4, 7));
        auto b = layout(shape(6), stride(1));
        auto r = test_composition(a, b);
        // (4,6,8):(1,4,7) o 6:1  =>  6:1
        EXPECT_EQ(r, layout(shape(6), stride(1)));
    }
    // Mid-layout truncation
    {
        auto a = layout(shape(4, 6, 8, 10), stride(2, 3, 5, 7));
        auto b = layout(shape(6), stride(12));
        auto r = test_composition(a, b);
        // (4,6,8,10):(2,3,5,7) o 6:12  =>  (2,3):(9,5)
        EXPECT_EQ(r, layout(shape(2, 3), stride(9, 5)));
    }
    {
        auto a = layout(shape(8, 8), stride(8, 1));
        auto b = layout(shape(2), stride(3));
        auto r = test_composition(a, b);
        // (8,8):(8,1) o 2:3  =>  2:24
        EXPECT_EQ(r, layout(shape(2), stride(24)));
    }
    {
        auto a = layout(shape(8, 8), stride(8, 1));
        auto b = layout(shape(3), stride(3));
        auto r = test_composition(a, b);
        // (8,8):(8,1) o 3:3  =>  3:24
        EXPECT_EQ(r, layout(shape(3), stride(24)));
    }
    {
        auto a = layout(shape(3), stride(1));
        auto b = layout(shape(4), stride(1));
        auto r = test_composition(a, b);
        // 3:1 o 4:1  =>  4:1
        EXPECT_EQ(r, layout(shape(4), stride(1)));
    }
    // Added for coalesced composition
    {
        auto a = layout(shape(4, 3));
        auto b = layout(shape(6));
        auto r = test_composition(a, b);
    }
    // Added for coalesced composition
    {
        auto a = layout(shape(4, 3));
        auto b = layout(shape(4, 3), stride(3, 1));
        auto r = test_composition(a, b);
    }
    // Added for composition with basis stride elements in B
    {
        auto a = cg::from_string<layout>("(4,4):(4,1)").value();
        auto b = cg::from_string<layout>("(4,4):(1@1,1@0)").value();
        auto r = test_composition(a, b);
        // (4,4):(4,1) o (4,4):(1@1,1@0)  =>  (4,4):(1,4)
        EXPECT_EQ(r, layout(shape(4, 4), stride(1, 4)));
    }
    // Added for composition with basis stride elements in B
    {
        auto a = cg::from_string<layout>("(4,(2,3)):(6,(3,1))").value();
        auto b = cg::from_string<layout>("(2,4):(1@1@1,1@0)").value();
        auto r = test_composition(a, b);
        // (4,(2,3)):(6,(3,1)) o (2,4):(1@1@1,1@0)  =>  (2,4):(1,6)
        EXPECT_EQ(r, layout(shape(2, 4), stride(1, 6)));
    }
    {
        auto a = layout(shape(5, 4), stride(1, 10));
        auto b = layout(shape(3));
        auto r = test_composition(a, b);
        // (5,4):(1,10) o 3:1  => 3:1
        EXPECT_EQ(r, layout(shape(3), stride(1)));
    }
    {
        auto a = layout(shape(64), stride(4096));
        auto b = layout(shape(1), stride(1));
        auto r = test_composition(a, b);
        // 64:4096 o 1:1  =>  1:4096
        EXPECT_EQ(r, layout(shape(1), stride(4096)));
    }
}

////////////////////////////////////////////////////////////////////////
// CompositionTest.Swizzle
TEST(CompositionTest, Swizzle) //
{
    // Composition with a composed layout on the right is not supported
#if 0
    {
        auto a = cg::layout(cg::shape(8, 8), cg::stride(8, 1));
        auto b = cg::composition(cg::swizzle(2, 0,-3),
                                 cg::layout(cg::shape(8, 8), cg::stride(8, 1)));
        auto r = test_composition(a, b);
    }

    {
        auto a = cg::composition(cg::swizzle(2, 0, 3),
                                 cg::layout(cg::shape(8, 8), cg::stride(8, 1)));
        auto b = cg::composition(cg::swizzle(2, 0,-3),
                                 cg::layout(cg::shape(8, 8), cg::stride(8, 1)));
        auto r = test_composition(a, b);
    }
#endif
}

////////////////////////////////////////////////////////////////////////
// CompositionTest.TestBuildFailureMode
TEST(CompositionTest, TestBuildFailureMode)
{
#if 0
  {
    auto a = cg::layout {};
    auto b = cg::layout {};
    auto c = cg::composition(a,b); // Should succeed
  }
#endif
#if 0
  {
    auto a = cg::layout {};
    auto b = cg::stride {};
    // Should fail with the compiler not finding candidate functions if enable_if and SFINAE are
    // working correctly (a "no matching function for call to 'composition..." error)
    auto c = cg::composition(a,b);
  }
#endif
}

////////////////////////////////////////////////////////////////////////
// CompositionTest.Invalid
TEST(CompositionTest, Invalid)
{
    {
        // The rank of the co-profile of rhs must be <= the rank of lhs
        auto lhs = *cg::from_string<cg::layout>("3:1");
        auto rhs = *cg::from_string<cg::layout>("2:1@1");
        EXPECT_EQ(cg::composition(lhs, rhs), cg::layout(cg::cg_error_t{}));
    }
}
