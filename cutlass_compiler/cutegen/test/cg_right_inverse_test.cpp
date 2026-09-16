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
void test_right_inverse(const Layout& layout, const Layout& exp)
{
    auto inv_layout = cg::right_inverse(layout);

    EXPECT_TRUE(cg::weakly_congruent(cg::coprofile(layout), inv_layout.shape()))
        << ", coprofile = " << cg::coprofile(layout) << ", shape = " << inv_layout.shape();

    //printf("%s => %s\n", cg::to_string(layout).c_str(), cg::to_string(inv_layout).c_str());
    // printf("Composition: %s\n",
    //        cg::to_string(coalesce(composition(layout, inv_layout))).c_str());

    // Generalized right inverse condition
    for(int i = 0; i < cg::static_size(inv_layout); ++i)
    {
        EXPECT_EQ(inv_layout(layout(inv_layout(i))), inv_layout(i)) << " for i = " << i;
    }

    EXPECT_EQ(inv_layout, exp) << " for layout " << layout;

    // Canonical right inverse post-condition is satisfied with codomain Z
    if(cg::holds_type<cg::static_int_t, cg::dynamic_t>(cg::coprofile(layout)))
    {
        for(int i = 0; i < cg::static_size(inv_layout); ++i)
        {
            EXPECT_EQ(layout(inv_layout(i)), i) << " for i = " << i;
        }
    }
}
} // namespace

////////////////////////////////////////////////////////////////////////
// RightInverseTest.Basic
TEST(RightInverseTest, Basic)
{
    { // 1:0  =>  1:0
        auto test     = cg::layout(cg::shape(1), cg::stride(0));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
    { // 1:1  =>  1:0
        auto test     = cg::layout(cg::shape(1), cg::stride(1));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
    { // 1:2  =>  1:0
        auto test     = cg::layout(cg::shape(1), cg::stride(2));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
    { // 1:4  =>  1:0
        auto test     = cg::layout(cg::shape(1), cg::stride(4));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
    { // 4:4  =>  1:0
        auto test     = cg::layout(cg::shape(4), cg::stride(4));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
    { // (1, 1):(0, 0)  =>  1:0
        auto test     = cg::layout(cg::shape(1, 1), cg::stride(0, 0));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
    { // (3, 7):(0, 0)  =>  1:0
        auto test     = cg::layout(cg::shape(3, 7), cg::stride(0, 0));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
    { // 1:1  =>  1:0
        auto test     = cg::layout(cg::shape(1), cg::stride(1));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
    { // 4:0  =>  1:0
        auto test     = cg::layout(cg::shape(4), cg::stride(0));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
    { // 4:1  =>  4:1
        auto test     = cg::layout(cg::shape(4), cg::stride(1));
        auto expected = cg::layout(cg::shape(4), cg::stride(1));
        test_right_inverse(test, expected);
    }
    { // 4:2  =>  1:0
        auto test     = cg::layout(cg::shape(4), cg::stride(2));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
    { // (2, 4):(0, 2)  =>  1:0
        auto test     = cg::layout(cg::shape(2, 4), cg::stride(0, 2));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
    { // (8, 4):(1, 8)  =>  32:1
        auto test     = cg::layout(cg::shape(8, 4), cg::stride(1, 8));
        auto expected = cg::layout(cg::shape(32), cg::stride(1));
        test_right_inverse(test, expected);
    }
    { // (8, 4):(4, 1)  =>  (4, 8):(8, 1)
        auto test     = cg::layout(cg::shape(8, 4), cg::stride(4, 1));
        auto expected = cg::layout(cg::shape(4, 8), cg::stride(8, 1));
        test_right_inverse(test, expected);
    }
    { // (2, 4, 6):(1, 2, 8)  =>  48:1
        auto test     = cg::layout(cg::shape(2, 4, 6), cg::stride(1, 2, 8));
        auto expected = cg::layout(cg::shape(48), cg::stride(1));
        test_right_inverse(test, expected);
    }
    { // (2, 4, 6):(4, 1, 8)  =>  (4, 2, 6):(2, 1, 8)
        auto test     = cg::layout(cg::shape(2, 4, 6), cg::stride(4, 1, 8));
        auto expected = cg::layout(cg::shape(4, 2, 6), cg::stride(2, 1, 8));
        test_right_inverse(test, expected);
    }
    { // (2,4,4,6):(4,1,0,8)  =>  (4,2,6):(2,1,32)
        auto test     = cg::layout(cg::shape(2, 4, 4, 6), cg::stride(4, 1, 0, 8));
        auto expected = cg::layout(cg::shape(4, 2, 6), cg::stride(2, 1, 32));
        test_right_inverse(test, expected);
    }
    { // (4, 2):(1, 16)  =>  4:1
        auto test     = cg::layout(cg::shape(4, 2), cg::stride(1, 16));
        auto expected = cg::layout(cg::shape(4), cg::stride(1));
        test_right_inverse(test, expected);
    }
    { // (4, 2):(1, 5)  =>  4:1
        auto test     = cg::layout(cg::shape(4, 2), cg::stride(1, 5));
        auto expected = cg::layout(cg::shape(4), cg::stride(1));
        test_right_inverse(test, expected);
    }
    { // Dynamic stride
        auto test     = cg::layout(cg::shape(2, 4, 6), cg::stride(4, 1, cg::dynamic_t{}));
        auto expected = cg::layout(cg::shape(4, 2), cg::stride(2, 1));
        test_right_inverse(test, expected);
    }
    { // (32,128):(0,1) => 128:32
        // Cases with layout modes of shape extent > 1 and 0 stride extent
        auto test     = cg::layout(cg::shape(32, 128), cg::stride(0, 1));
        auto expected = cg::layout(cg::shape(128), cg::stride(32));
        test_right_inverse(test, expected);
    }
    { // ():() => 1:0
        auto test     = cg::layout(cg::shape(), cg::stride());
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
    { // 1:? => 1:0
        auto test     = cg::layout(cg::shape(1), cg::stride(cg::dynamic_t{}));
        auto expected = cg::layout(cg::shape(1), cg::stride(0));
        test_right_inverse(test, expected);
    }
}

////////////////////////////////////////////////////////////////////////
// RightInverseTest.Coordinate
TEST(RightInverseTest, Coordinate)
{
    using sb_t = cg::scaled_basis_t<cg::ratio, cg::static_int_t, cg::dynamic_t>;
    { // (4, 5):(1@0, 1@1)  =>  (4, 5):(1, 4)
        auto test     = cg::layout(cg::shape(4, 5), cg::stride(sb_t(0, 1), sb_t(1, 1)));
        auto expected = cg::layout(cg::shape(4, 5), cg::stride(1, 4));
        test_right_inverse(test, expected);
    }
    { // (4, 5):(1@1, 1@0)  =>  (5, 4):(4, 1)
        auto test     = cg::layout(cg::shape(4, 5), cg::stride(sb_t(1, 1), sb_t(0, 1)));
        auto expected = cg::layout(cg::shape(5, 4), cg::stride(4, 1));
        test_right_inverse(test, expected);
    }
    { // (4, 5):(1@1, 1@1@4)  =>  (1, 4, 1, 1, (1, 5)):(0, 1, 0, 0, (0, 4))
        auto test     = cg::layout(cg::shape(4, 5), cg::stride(sb_t(1, 1), sb_t({4, 1}, 1)));
        auto expected = cg::layout(cg::shape(1, 4, 1, 1, cg::shape(1, 5)),
                                   cg::stride(0, 1, 0, 0, cg::stride(0, 4)));
        test_right_inverse(test, expected);
    }
    { // (4, 5):(2@0, 2@1)  =>  (1, 1):(0, 0)
        auto test     = cg::layout(cg::shape(4, 5), cg::stride(sb_t(0, 2), sb_t(1, 2)));
        auto expected = cg::layout(cg::shape(1, 1), cg::stride(0, 0));
        test_right_inverse(test, expected);
    }
    // SM70 MMA 8x8x4 C TV inverse
    { // ((2, 2, 2), (2, 2, 2)):((1@0, 2@1, 4@0), (1@1, 2@0, 4@1))  =>  ((2, 2, 2), (2, 2, 2)):((1, 16, 4), (8, 2, 32))
        auto test     = cg::layout(cg::shape(cg::shape(2, 2, 2), cg::shape(2, 2, 2)),
                               cg::stride(cg::stride(sb_t(0, 1), sb_t(1, 2), sb_t(0, 4)),
                                          cg::stride(sb_t(1, 1), sb_t(0, 2), sb_t(1, 4))));
        auto expected = cg::layout(cg::shape(cg::shape(2, 2, 2), cg::shape(2, 2, 2)),
                                   cg::stride(cg::stride(1, 16, 4), cg::stride(8, 2, 32)));
        test_right_inverse(test, expected);
    }
    { // ((2, 2, 2), (2, 2, 2)):((1@0, 2@1, 5@0), (1@1, 2@0, 5@1))  =>  ((2, 2), (2, 2)):((1, 16), (8, 2))
        auto test     = cg::layout(cg::shape(cg::shape(2, 2, 2), cg::shape(2, 2, 2)),
                               cg::stride(cg::stride(sb_t(0, 1), sb_t(1, 2), sb_t(0, 5)),
                                          cg::stride(sb_t(1, 1), sb_t(0, 2), sb_t(1, 5))));
        auto expected = cg::layout(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                                   cg::stride(cg::stride(1, 16), cg::stride(8, 2)));
        test_right_inverse(test, expected);
    }
    { // ((2, 2, 2), (2, 2, 2)):((1@0, 2@1, 5@0), (1@1, 2@0, 4@1))  =>  ((2, 2), (2, 2, 2)):((1, 16), (8, 2, 32))
        auto test     = cg::layout(cg::shape(cg::shape(2, 2, 2), cg::shape(2, 2, 2)),
                               cg::stride(cg::stride(sb_t(0, 1), sb_t(1, 2), sb_t(0, 5)),
                                          cg::stride(sb_t(1, 1), sb_t(0, 2), sb_t(1, 4))));
        auto expected = cg::layout(cg::shape(cg::shape(2, 2), cg::shape(2, 2, 2)),
                                   cg::stride(cg::stride(1, 16), cg::stride(8, 2, 32)));
        test_right_inverse(test, expected);
    }
    // SM70 MMA 8x8x4 A TV inverse
    // layout = composition(tiler_to_layout((8,4)), Layout(((4,2),4), ((8,4),1)))
    //        = composition(Layout((8,4),(1@0,1@1)), Layout(((4,2),4), ((8,4),1)))
    //        = Layout(((4, 2), 4), ((1@1, 4@0), 1@0))
    { // ((4, 2), 4):((1@1, 4@0), 1@0)  =>  ((4, 2), 4):((8, 4), 1)
        auto test     = cg::layout(cg::shape(cg::shape(4, 2), 4),
                               cg::stride(cg::stride(sb_t(1, 1), sb_t(0, 4)), sb_t(0, 1)));
        auto expected = cg::layout(cg::shape(cg::shape(4, 2), 4),
                                   cg::stride(cg::stride(8, 4), 1));
        test_right_inverse(test, expected);
    }
    // SM80 MMA 16x8 TV inverse
    // layout = composition(tiler_to_layout((16,8)), Layout(((4,8),(2,2)), ((32,1),(16,8))))
    //        = composition(Layout((16,8), (1@0,1@1)), Layout(((4,8),(2,2)), ((32,1),(16,8))))
    //        = Layout(((4, 8), (2, 2)), ((2@1, 1@0), (1@1, 8@0)))
    { // ((4, 8), (2, 2)):((2@1, 1@0), (1@1, 8@0))  =>  ((8, 2), (2, 4)):((4, 64), (32, 1))
        auto test     = cg::layout(cg::shape(cg::shape(4, 8), cg::shape(2, 2)),
                               cg::stride(cg::stride(sb_t(1, 2), sb_t(0, 1)), cg::stride(sb_t(1, 1), sb_t(0, 8))));
        auto expected = cg::layout(cg::shape(cg::shape(8, 2), cg::shape(2, 4)),
                                   cg::stride(cg::stride(4, 64), cg::stride(32, 1)));
        test_right_inverse(test, expected);
    }
    { // (4, 1, 5):(1@0, 0, 1@1)  =>  (4, 5):(1, 4)
        auto test     = cg::layout(cg::shape(4, 1, 5), cg::stride(sb_t(0, 1), 0, sb_t(1, 1)));
        auto expected = cg::layout(cg::shape(4, 5), cg::stride(1, 4));
        test_right_inverse(test, expected);
    }
    // Mixed stride case (scaled basis alongside statically zero integers).
    // This is not a meaningful right inverse test, but is instead the same
    // input layout as a left inverse test, but is useful in checking
    // invariants of the right inverse implementation.
    { // (((16,4),64),1,1):(((1@1,32@1),2@0),0,0) => ((2,64),(32,4)):((0,64),(1,16))
        auto test     = cg::layout(cg::shape(cg::shape(cg::shape(16, 4), 64), 1, 1),
                               cg::stride(cg::stride(cg::stride(sb_t{1, 1}, sb_t{1, 32}), sb_t{0, 2}), 0, 0));
        auto expected = cg::layout(cg::shape(1, 16), cg::stride(0, 1));
        test_right_inverse(test, expected);
    }
}
