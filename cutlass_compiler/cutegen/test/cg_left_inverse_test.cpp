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

#include <numeric>
#include <stdio.h>
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
template <class Layout>
void test_left_inverse(const Layout& layout, const Layout& expected)
{
    auto inv_layout = cg::left_inverse(layout);

    EXPECT_TRUE(cg::weakly_congruent(cg::coprofile(layout), inv_layout.shape()));
    // Generalized left inverse condition
    for(int i = 0; i < cg::static_size(layout); ++i)
    {
        EXPECT_EQ(layout(inv_layout(layout(i))), layout(i));
    }
    EXPECT_EQ(inv_layout, expected) << " for layout " << layout;
    //printf(
    //    "Composition: %s\n",
    //    cg::to_string(cg::coalesce(cg::composition(inv_layout, layout))).c_str());
}
} // namespace

////////////////////////////////////////////////////////////////////////
// LeftInverseTest.Basic
TEST(LeftInverseTest, Basic)
{
    // expected inverse layouts
    { // 1:1 => 1:0
        auto test     = cg::layout(cg::shape(1), cg::stride(0));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_left_inverse(test, expected);
    }
    { // 1:1 => 1:0
        auto test     = cg::layout(cg::shape(1), cg::stride(1));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_left_inverse(test, expected);
    }
    { // 1:2 => 1:0
        auto test     = cg::layout(cg::shape(1), cg::stride(2));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_left_inverse(test, expected);
    }
    { // 1:4 => 1:0
        auto test     = cg::layout(cg::shape(1), cg::stride(4));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_left_inverse(test, expected);
    }
    { // (1,1):(0,0) => 1:0
        auto test     = cg::layout(cg::shape(1, 1), cg::stride(0, 0));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_left_inverse(test, expected);
    }
    { // (3,7):(0,0) => 1:0
        auto test     = cg::layout(cg::shape(3, 7), cg::stride(0, 0));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_left_inverse(test, expected);
    }
    { // 4:0 => 1:0
        auto test     = cg::layout(cg::shape(4), cg::stride(0));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_left_inverse(test, expected);
    }
    { // 4:1 => 4:1
        auto test     = cg::layout(cg::shape(4), cg::stride(1));
        auto expected = cg::layout(cg::shape(4), cg::stride(1));
        test_left_inverse(test, expected);
    }
    { // 4:2 => (2,4):(0,1)
        auto test     = cg::layout(cg::shape(4), cg::stride(2));
        auto expected = cg::layout(cg::shape(2, 4), cg::stride(0, 1));
        test_left_inverse(test, expected);
    }
    { // 4:4 => (4,4):(0,1)
        auto test     = cg::layout(cg::shape(4), cg::stride(4));
        auto expected = cg::layout(cg::shape(4, 4), cg::stride(0, 1));
        test_left_inverse(test, expected);
    }
    { // (8,4):(1,8) => 32:1
        auto test     = cg::layout(cg::shape(8, 4), cg::stride(1, 8));
        auto expected = cg::layout(cg::shape(32), cg::stride(1));
        test_left_inverse(test, expected);
    }
    { // (8,4):(4,1) => (4,8):(8,1)
        auto test     = cg::layout(cg::shape(8, 4), cg::stride(4, 1));
        auto expected = cg::layout(cg::shape(4, 8), cg::stride(8, 1));
        test_left_inverse(test, expected);
    }
    { // (2,4,6):(1,2,8) => 48:1
        auto test     = cg::layout(cg::shape(2, 4, 6), cg::stride(1, 2, 8));
        auto expected = cg::layout(cg::shape(48), cg::stride(1));
        test_left_inverse(test, expected);
    }
    { // (2,4,6):(4,1,8) => (4,2,6):(2,1,8)
        auto test     = cg::layout(cg::shape(2, 4, 6), cg::stride(4, 1, 8));
        auto expected = cg::layout(cg::shape(4, 2, 6), cg::stride(2, 1, 8));
        test_left_inverse(test, expected);
    }
    { // (2,4,8):(32,0,2) => (2,16,2):(0,8,1)
        auto test     = cg::layout(cg::shape(2, 4, 8), cg::stride(32, 0, 2));
        auto expected = cg::layout(cg::shape(2, 16, 2), cg::stride(0, 8, 1));
        test_left_inverse(test, expected);
    }
    { // (2,4,8):(2,0,32) => (2,16,8):(0,1,8)
        auto test     = cg::layout(cg::shape(2, 4, 8), cg::stride(2, 0, 32));
        auto expected = cg::layout(cg::shape(2, 16, 8), cg::stride(0, 1, 8));
        test_left_inverse(test, expected);
    }
    { // (2,4,4,4,2):(32,0,2,0,512) => (2,16,16,2):(0,8,1,128)
        auto test     = cg::layout(cg::shape(2, 4, 4, 4, 2), cg::stride(32, 0, 2, 0, 512));
        auto expected = cg::layout(cg::shape(2, 16, 16, 2), cg::stride(0, 8, 1, 128));
        test_left_inverse(test, expected);
    }
    { // (4,2):(1,16) => (16,2):(1,4)
        auto test     = cg::layout(cg::shape(4, 2), cg::stride(1, 16));
        auto expected = cg::layout(cg::shape(16, 2), cg::stride(1, 4));
        test_left_inverse(test, expected);
    }
    { // (4,2):(1,5) => (5,2):(1,4)
        auto test     = cg::layout(cg::shape(4, 2), cg::stride(1, 5));
        auto expected = cg::layout(cg::shape(5, 2), cg::stride(1, 4));
        test_left_inverse(test, expected);
    }
    { // (4,2):(1,10) => (10,2):(1,4)
        auto test     = cg::layout(cg::shape(4, 2), cg::stride(1, 10));
        auto expected = cg::layout(cg::shape(10, 2), cg::stride(1, 4));
        test_left_inverse(test, expected);
    }
    { // (4,2):(1,11) => (11,2):(1,4)
        auto test     = cg::layout(cg::shape(4, 2), cg::stride(1, 11));
        auto expected = cg::layout(cg::shape(11, 2), cg::stride(1, 4));
        test_left_inverse(test, expected);
    }
    { // (32,8):(65536,1) => (65536,32):(32,1)
        auto test     = cg::layout(cg::shape(32, 8), cg::stride(65536, 1));
        auto expected = cg::layout(cg::shape(65536, 32), cg::stride(32, 1));
        test_left_inverse(test, expected);
    }
    { // (32,12):(65536,1) => (65536,32):(32,1)
        auto test     = cg::layout(cg::shape(32, 12), cg::stride(65536, 1));
        auto expected = cg::layout(cg::shape(65536, 32), cg::stride(32, 1));
        test_left_inverse(test, expected);
    }
    { // (32,3,8):(65536,512,1) => (512,128,32):(96,32,1)
        auto test     = cg::layout(cg::shape(32, 3, 8), cg::stride(65536, 512, 1));
        auto expected = cg::layout(cg::shape(512, 128, 32), cg::stride(96, 32, 1));
        test_left_inverse(test, expected);
    }
    { // (32,8):(131072,2) => (2,65536,32):(0,32,1)
        auto test     = cg::layout(cg::shape(32, 8), cg::stride(131072, 2));
        auto expected = cg::layout(cg::shape(2, 65536, 32), cg::stride(0, 32, 1));
        test_left_inverse(test, expected);
    }
    { // (((((2,4),1),(2,2)),4),1,(2,2),2):(((((262144,4),0),(0,1)),8388608),0,(2,16),32)
        // =>
        // (2,2,4,16384,128):(16,128,2,256,1)
        auto test     = cg::from_string<cg::layout>("(((((2,4),1),(2,2)),4),1,(2,2),2):"
                                                    "(((((262144,4),0),(0,1)),8388608),0,(2,16),32)");
        auto expected = cg::from_string<cg::layout>("(2,2,4,16384,128):(16,128,2,256,1)");
        test_left_inverse(*test, *expected);
    }
    { // (128,160):(65536,1) => (65536,128):(128,1)
        auto test     = cg::layout(cg::shape(128, 160), cg::stride(65536, 1));
        auto expected = cg::layout(cg::shape(65536, 128), cg::stride(128, 1));
        test_left_inverse(test, expected);
    }
    { // (128,3,160):(65536,512,1) => (512,128,128):(384,128,1)
        auto layout   = cg::layout(cg::shape(128, 3, 160), cg::stride(65536, 512, 1));
        auto expected = cg::layout(cg::shape(512, 128, 128), cg::stride(384, 128, 1));
        test_left_inverse(layout, expected);
    }
    { //(128,64):(131072,2) => (2,65536,128):(0,128,1)
        auto layout   = cg::layout(cg::shape(128, 64), cg::stride(131072, 2));
        auto expected = cg::layout(cg::shape(2, 65536, 128), cg::stride(0, 128, 1));
        test_left_inverse(layout, expected);
    }
}

////////////////////////////////////////////////////////////////////////
// LeftInverseTest.Coordinate
TEST(LeftInverseTest, Coordinate)
{
    using sb_t = cg::scaled_basis_t<cg::ratio, cg::static_int_t, cg::dynamic_t>;
    // expected inverse layouts
    { // (4,5):(1@0,1@1)  =>  (4,5):(1,4)
        auto test     = cg::layout(cg::shape(4, 5), cg::stride(sb_t(0, 1), sb_t(1, 1)));
        auto expected = cg::layout(cg::shape(4, 5), cg::stride(1, 4));
        test_left_inverse(test, expected);
    }
    { // (4,5):(1@1,1@0)  =>  (5,4):(4,1)
        auto test     = cg::layout(cg::shape(4, 5), cg::stride(sb_t(1, 1), sb_t(0, 1)));
        auto expected = cg::layout(cg::shape(5, 4), cg::stride(4, 1));
        test_left_inverse(test, expected);
    }
    { // (4,5):(1@1,1@1@4)  =>  (1,4,1,1,(1,5)):(0,1,0,0,(0,4))
        auto test     = cg::layout(cg::shape(4, 5), cg::stride(sb_t(1, 1), sb_t({4, 1}, 1)));
        auto expected = cg::layout(cg::shape(1, 4, 1, 1, cg::shape(1, 5)), cg::stride(0, 1, 0, 0, cg::stride(0, 4)));
        test_left_inverse(test, expected);
    }
    { // (4,5):(2@0,2@1)  =>  ((2,4),(2,5)):((0,1),(0,4))
        auto test     = cg::layout(cg::shape(4, 5), cg::stride(sb_t(0, 2), sb_t(1, 2)));
        auto expected = cg::layout(cg::shape(cg::shape(2, 4), cg::shape(2, 5)), cg::stride(cg::stride(0, 1), cg::stride(0, 4)));
        test_left_inverse(test, expected);
    }
    // SM70 MMA 8x8x4 C TV inverse
    { // ((2,2,2),(2,2,2)):((1@0,2@1,4@0),(1@1,2@0,4@1))  =>  ((2,2,2),(2,2,2)):((1,16,4),(8,2,32))
        auto test     = cg::layout(cg::shape(cg::shape(2, 2, 2), cg::shape(2, 2, 2)),
                               cg::stride(cg::stride(sb_t(0, 1), sb_t(1, 2), sb_t(0, 4)),
                                          cg::stride(sb_t(1, 1), sb_t(0, 2), sb_t(1, 4))));
        auto expected = cg::layout(cg::shape(cg::shape(2, 2, 2), cg::shape(2, 2, 2)),
                                   cg::stride(cg::stride(1, 16, 4), cg::stride(8, 2, 32)));
        test_left_inverse(test, expected);
    }
    { // ((2,2,2),(2,2,2)):((1@0,2@1,6@0),(1@1,2@0,6@1))  =>  ((2,3,2),(2,3,2)):((1,16,4),(8,2,32))
        auto test     = cg::layout(cg::shape(cg::shape(2, 2, 2), cg::shape(2, 2, 2)),
                               cg::stride(cg::stride(sb_t(0, 1), sb_t(1, 2), sb_t(0, 6)),
                                          cg::stride(sb_t(1, 1), sb_t(0, 2), sb_t(1, 6))));
        auto expected = cg::layout(cg::shape(cg::shape(2, 3, 2), cg::shape(2, 3, 2)),
                                   cg::stride(cg::stride(1, 16, 4), cg::stride(8, 2, 32)));
        test_left_inverse(test, expected);
    }
    { // ((2,2,2),(2,2,2)):((1@0,2@1,6@0),(1@1,2@0,4@1))  =>  ((2,3,2),(2,2,2)):((1,16,4),(8,2,32))
        auto test     = cg::layout(cg::shape(cg::shape(2, 2, 2), cg::shape(2, 2, 2)),
                               cg::stride(cg::stride(sb_t(0, 1), sb_t(1, 2), sb_t(0, 6)),
                                          cg::stride(sb_t(1, 1), sb_t(0, 2), sb_t(1, 4))));
        auto expected = cg::layout(cg::shape(cg::shape(2, 3, 2), cg::shape(2, 2, 2)),
                                   cg::stride(cg::stride(1, 16, 4), cg::stride(8, 2, 32)));
        test_left_inverse(test, expected);
    }
    // SM70 MMA 8x8x4 A TV inverse
    // layout = composition(    tiler_to_layout((8,4)), Layout(((4,2),4), ((8,4),1)))
    //        = composition(Layout((8, 4), (1@0, 1@1)), Layout(((4,2),4), ((8,4),1)))
    //        = Layout(((4, 2), 4), ((1@1, 4@0), 1@0))
    { // ((4,2),4):((1@1,4@0),1@0)  =>  ((4,2),4):((8,4),1)
        auto test     = cg::layout(cg::shape(cg::shape(4, 2), 4),
                               cg::stride(cg::stride(sb_t(1, 1), sb_t(0, 4)), sb_t(0, 1)));
        auto expected = cg::layout(cg::shape(cg::shape(4, 2), 4),
                                   cg::stride(cg::stride(8, 4), 1));
        test_left_inverse(test, expected);
    }
    // SM80 MMA 16x8 TV inverse
    // layout = composition(tiler_to_layout((16,8)), Layout(((4,8),(2,2)), ((32,1),(16,8))))
    //        = composition(Layout((16, 8), (1@0, 1@1)), Layout(((4,8),(2,2)), ((32,1),(16,8))))
    { // ((4,8),(2,2)):((2@1,1@0),(1@1,8@0))  =>  ((8,2), (2,4)):((4,64), (32,1))
        auto test     = cg::layout(cg::shape(cg::shape(4, 8), cg::shape(2, 2)),
                               cg::stride(cg::stride(sb_t(1, 2), sb_t(0, 1)), cg::stride(sb_t(1, 1), sb_t(0, 8))));
        auto expected = cg::layout(cg::shape(cg::shape(8, 2), cg::shape(2, 4)),
                                   cg::stride(cg::stride(4, 64), cg::stride(32, 1)));
        test_left_inverse(test, expected);
    }
    { // (4,1,5):(1@0,0,1@1)  =>  (4,5):(1,4)
        auto test     = cg::layout(cg::shape(4, 1, 5), cg::stride(sb_t(0, 1), 0, sb_t(1, 1)));
        auto expected = cg::layout(cg::shape(4, 5), cg::stride(1, 4));
        test_left_inverse(test, expected);
    }
    // Mixed stride case (scaled basis alongside statically zero integers)
    { // (((16,4),64),1,1):(((1@1,32@1),2@0),0,0) => ((2,64),(32,4)):((0,64),(1,16))
        auto test     = cg::layout(cg::shape(cg::shape(cg::shape(16, 4), 64), 1, 1),
                               cg::stride(cg::stride(cg::stride(sb_t{1, 1}, sb_t{1, 32}), sb_t{0, 2}), 0, 0));
        auto expected = cg::layout(cg::shape(cg::shape(2, 64), cg::shape(32, 4)),
                                   cg::stride(cg::stride(0, 64), cg::stride(1, 16)));
        test_left_inverse(test, expected);
    }
    { // stride elements must not mix nonzero integers and scaled basis values.
        auto test = cg::layout(cg::shape(4, 2), cg::stride(1, sb_t{1, 2}));
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        EXPECT_ANY_THROW(auto result = cg::left_inverse(test));
#else
        EXPECT_FALSE(cg::is_valid(cg::left_inverse(test)));
#endif
    }
    // A common cotiling failure
    // atom_tv_layout = Layout(((32,       4), (16,    32)),
    //                        (( 0, 2097152), ( 1, 65536)))
    // data_layout = Layout((  128, 16),
    //                      (65536,  1))
    // # data addr -> data coord    Append 1:0 so off-the-ends get the stride-0
    // inv_data_layout = make_layout([left_inverse(data_layout), Layout(1,0)])
    // # (tid,vid) -> data_coord
    // layout_tv_data = composition(inv_data_layout, atom_tv_layout)
    // # Check validity   D o (Di o TV) == TV
    // self.assertEqual(coalesce(composition(data_layout, layout_tv_data)), coalesce(atom_tv_layout))
    {
        cg::layout              atom_tv_layout(cg::shape(cg::shape(32, 4), cg::shape(16, 32)),
                                  cg::stride(cg::stride(0, 2097152), cg::stride(1, 65536)));
        cg::layout              data_layout(cg::shape(128, 16), cg::stride(65536, 1));
        std::vector<cg::layout> vec{cg::left_inverse(data_layout), cg::layout(cg::shape(1), cg::stride(0))};
        cg::layout              inv_data_layout = cg::make_layout(vec);
        cg::layout              layout_tv_data  = cg::composition(inv_data_layout, atom_tv_layout);
        EXPECT_EQ(cg::coalesce(cg::composition(data_layout, layout_tv_data)),
                  cg::coalesce(atom_tv_layout));
    }
}
