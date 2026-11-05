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

#include <optional>
#include <string>
#include <tuple>
#include <utility>
#include <variant>
#include <vector>

#include "cutegen/composed_layout.hpp"
#include "cutegen/cutegen.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/swizzle.hpp"
#include "cutegen/underscore.hpp"

#include "utils.hpp"

#include "gtest/gtest.h"

namespace cg = cutegen;

TEST(ComposedLayoutTest, ToFromString)
{
    using sb = cg::scaled_basis;
    {
        cg::layout          a(cg::shape(4, 5));
        cg::layout          b(cg::shape(2, 3));
        cg::composed_layout aob(a, 2, b);
        std::string         string_aob = "(4,5):(1,4) o 2 o (2,3):(1,2)";
        EXPECT_EQ(to_string(aob), string_aob);
        auto opt_aob = cg::from_string<cg::composed_layout>(string_aob);
        EXPECT_TRUE(opt_aob.has_value());
        EXPECT_EQ(aob, opt_aob.value());
    }
    {
        cg::swizzle         a(3, 5, 4);
        cg::layout          b(cg::shape(2, 3));
        cg::composed_layout aob(a, 2, b);
        std::string         string_aob = "S<3,5,4> o 2 o (2,3):(1,2)";
        EXPECT_EQ(to_string(aob), string_aob);
        auto opt_aob = cg::from_string<cg::composed_layout>(string_aob);
        EXPECT_TRUE(opt_aob.has_value());
        EXPECT_EQ(aob, opt_aob.value());
    }
    {
        cg::layout          a(cg::shape(4, 5));
        cg::layout          b(cg::shape(2, 3), cg::stride(sb(0, 1), sb(1, 1)));
        cg::composed_layout aob(a, cg::int_tuple(0, 0), b);
        std::string         string_aob = "(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)";
        EXPECT_EQ(cg::to_string(aob), string_aob);
        auto opt_aob = cg::from_string<cg::composed_layout>(string_aob);
        EXPECT_TRUE(opt_aob.has_value());
        EXPECT_EQ(aob, opt_aob.value());
    }
}

TEST(ComposedLayoutTest, Codec)
{
    {
        auto l1 = cg::from_string<cg::composed_layout>(
                      std::string("S<3,5,4> o 2 o (2,3):(1,2)"))
                      .value();
        auto l2 = cg::from_string<cg::composed_layout>(
                      std::string("(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)"))
                      .value();
        test_codec(l1);
        test_codec(l2);
    }
}

TEST(ComposedLayoutTest, HasError)
{
    {
        auto l = cg::from_string<cg::composed_layout>(
            std::string("(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)"));
        ASSERT_TRUE(l.has_value());
        EXPECT_FALSE(cg::has_error(l.value()));
    }
    {
        auto l = cg::from_string<cg::composed_layout>(
            std::string("(4,5):(1,4) o (0,0) o (2,3):(x,1@1)"));
        ASSERT_TRUE(l.has_value());
        EXPECT_TRUE(cg::has_error(l.value()));
    }
    {
        auto l = cg::from_string<cg::composed_layout>(
            std::string("(4,5):(1,4) o (0,x) o (2,3):(1@0,1@1)"));
        ASSERT_TRUE(l.has_value());
        EXPECT_TRUE(cg::has_error(l.value()));
    }
    {
        auto l = cg::from_string<cg::composed_layout>(
            std::string("(4,x):(1,4) o (0,0) o (2,3):(1@0,1@1)"));
        ASSERT_TRUE(l.has_value());
        EXPECT_TRUE(cg::has_error(l.value()));
    }
}

TEST(ComposedLayoutTest, SliceStaticSwizzledLayouts)
{
    {
        // master_layout = S<3,4,4> o 0 o (64,128):(1,64)
        // Y mask = 1792, Z mask = 112
        // master_layout( (_,16) ) = (64):(1) (decay)
        cg::swizzle         sw(3, 4, 4);
        cg::composed_layout master_layout(sw, cg::int_tuple(0), cg::layout(cg::shape(64, 128), cg::stride(1, 64)));
        auto [sliced_layout, offset] = cg::slice_and_offset(cg::coord(cg::_, 16), master_layout);
        EXPECT_TRUE(sliced_layout.is_normal_layout());
        cg::layout sliced_layout_affine = sliced_layout.layout_b();
        for(cg::layout::int_t i = 0; i < cg::static_size(sliced_layout_affine); i++)
        {
            EXPECT_EQ(sliced_layout(i), sliced_layout_affine(i).as_int());
            EXPECT_EQ(master_layout(cg::coord(i, 16)), offset.as_int() + sliced_layout_affine(i).as_int());
        }
    }
    {
        // master_layout = S<3,4,4> o 0 o (64,128):(1,64)
        // Y mask = 1792, Z mask = 112
        // master_layout( (32,_) ) = S<3,4,4> o 32 o (128):(64) (no decay)
        cg::swizzle         sw(3, 4, 4);
        cg::composed_layout master_layout(sw, cg::int_tuple(0), cg::layout(cg::shape(64, 128), cg::stride(1, 64)));
        auto [sliced_layout, offset] = cg::slice_and_offset(cg::coord(32, cg::_), master_layout);
        EXPECT_FALSE(sliced_layout.is_normal_layout());
        for(cg::layout::int_t i = 0; i < cg::static_size(sliced_layout); i++)
            EXPECT_EQ(master_layout(cg::coord(32, i)), offset.as_int() + sliced_layout(i).as_int());
    }
    {
        // Slicing l with ((_,3),_) decays into (2,4):(1,-2) + offset
        // Slicing l with ((0_),(_,0)) doesn't decay
        cg::composed_layout l = cg::from_string<cg::composed_layout>(
                                    std::string("S<2,1,2> o 0 o ((2,4),(2,2)):((1,8),(2,4))"))
                                    .value();
        {
            auto [sl, o] = cg::slice_and_offset(cg::coord(cg::coord(cg::_, 3), cg::_), l);
            EXPECT_TRUE(sl.is_normal_layout());
            EXPECT_EQ(o, 30);
            EXPECT_EQ(cg::coalesce(sl.layout_b()), cg::layout(cg::shape(2, 4), cg::stride(1, -2)));
        }
        {
            auto c       = cg::coord(cg::coord(0, cg::_), cg::coord(cg::_, 0));
            auto [sl, o] = cg::slice_and_offset(c, l);
            EXPECT_FALSE(sl.is_normal_layout());
            EXPECT_EQ(sl.a(), l.a());
            EXPECT_EQ(sl.offset(), 0);
            EXPECT_EQ(sl.layout_b(), cg::slice(c, l.layout_b()));
        }
    }
    {
        // NVIDIA/cutlass#3454: swizzle-projection composition fails for (10,2):(2,1)
        // and must soft-error instead of asserting in static_size.
        cg::swizzle         sw(3, 4, 3);
        cg::composed_layout bad(sw, cg::int_tuple(0),
                                cg::layout(cg::shape(10, 2), cg::stride(2, 1)));
        auto [sliced_bad, offset_bad] =
            cg::slice_and_offset(cg::coord(cg::_, 0), bad);
        EXPECT_FALSE(cg::is_valid(sliced_bad));
        (void)offset_bad;

        cg::composed_layout ok(sw, cg::int_tuple(0),
                               cg::layout(cg::shape(8, 2), cg::stride(2, 1)));
        auto [sliced_ok, offset_ok] = cg::slice_and_offset(cg::coord(cg::_, 0), ok);
        EXPECT_TRUE(cg::is_valid(sliced_ok));
        EXPECT_TRUE(sliced_ok.is_normal_layout());
        EXPECT_EQ(cg::to_string(sliced_ok.layout_b()), std::string("(8):(2)"));
        EXPECT_EQ(offset_ok.as_int(), 0);
    }
}

TEST(ComposedLayoutTest, SliceAffineLayouts)
{
    { // dereference
        auto lay = *cg::from_string<cg::composed_layout>(
            std::string("(3,?):(1,?) o 0 o (2,3):(3,1)"));
        auto [slice, offset] = cg::slice_and_offset(cg::coord(0, 2), lay);
        EXPECT_EQ(lay.layout_a(), slice.layout_a());
        EXPECT_EQ(2, slice.offset().as_int());
        // Flow: Calculate expected offset for coord (0,2)
        // Step 1: layout_b((0,2)) = 0*3 + 2*1 = 2
        // Step 2: calculated_offset = off + layout_b(coord) = 0 + 2 = 2
        // Step 3: layout_a(calculated_offset) = layout_a(2) = 2*1 = 2
        EXPECT_EQ(2, offset.as_int());
    }

    { // slice
        auto crd = cg::coord(1, cg::_);
        auto lay = *cg::from_string<cg::composed_layout>(
            std::string("(3,?):(1,?) o 0 o (2,3):(3,1)"));
        auto [slice, offset] = cg::slice_and_offset(crd, lay);
        EXPECT_EQ(lay.layout_a(), slice.layout_a());
        EXPECT_EQ(3, slice.offset().as_int());
        EXPECT_EQ(cg::slice(crd, lay.layout_b()), slice.layout_b());
        EXPECT_EQ(0, offset.as_int());
    }
}

TEST(ComposedLayoutTest, CountDynamicScalars)
{
    {
        auto lay = cg::from_string<cg::composed_layout>(
            std::string("S<3,5,4> o ? o (2,?):(1,?)"));
        EXPECT_EQ(3, cg::scalar_count(lay.value(), /*dynamicOnly=*/true));
        EXPECT_EQ(8, cg::scalar_count(lay.value()));
    }

    {
        auto lay = cg::from_string<cg::composed_layout>(
            std::string("(3,?):(1,?) o ? o ((2,?),(2,2)):((?,8),(2,4))"));
        EXPECT_EQ(5, cg::scalar_count(lay.value(), /*dynamicOnly=*/true));
        EXPECT_EQ(13, cg::scalar_count(lay.value()));
    }
}

TEST(ComposedLayoutTest, DomainOffset)
{
    {
        auto layout = cg::from_string<cg::composed_layout>(
                          std::string(" ((8,16,1,1),(64,1,1,1)):((1@0@1,1@1@1,1@2@1,1@2),(1@0,1@0@3,1@1@3,1@2@3)) o (0,(0,0,0,0)) o (((32,128),1),(1,4),(1,1,(1,1,1,1))):(((1@0@1,1@0),0),(0,32@0@1),(0,0,(128@0@1,1@1@1,1@2@1,1@3@1)))"))
                          .value();
        auto coord                = cg::coord(cg::coord(4096, 0), 0, 0);
        auto [new_layout, offset] = cg::domain_offset(coord, layout);
        EXPECT_EQ(new_layout.offset(), cg::int_tuple(128, cg::int_tuple(0, 0, 0, 0)));
        EXPECT_EQ(new_layout.layout_a(), layout.layout_a());
        EXPECT_EQ(new_layout.layout_b(), layout.layout_b());
        EXPECT_EQ(offset, cg::int_tuple(0));
    }
}

TEST(ComposedLayoutTest, Get)
{
    {
        // S<3,5,4> o 2 o (2,3):(1,2)
        cg::swizzle           a(3, 5, 4);
        cg::layout            b(cg::shape(2, 3));
        cg::composed_layout   aob(a, 2, b);
        std::array<size_t, 1> idx0 = {0};
        EXPECT_EQ(cg::get(aob, idx0),
                  cg::composed_layout(a, 2, cg::layout(cg::shape(2), cg::stride(1))));
    }
}

TEST(ComposedLayoutTest, MakeLayoutLike)
{
    {
        // S<3,5,4> o 2 o (2,3):(3,1)
        cg::swizzle         a(3, 5, 4);
        cg::layout          b(cg::shape(2, 3), cg::stride(3, 1));
        cg::composed_layout aob(a, 2, b);
        EXPECT_EQ(cg::make_layout_like(aob),
                  cg::layout(cg::shape(2, 3), cg::stride(3, 1)));
    }
}

TEST(ComposedLayoutTest, Select)
{
    {
        // S<3,5,4> o 2 o (2,3):(1,2)
        cg::swizzle           a(3, 5, 4);
        cg::layout            b(cg::shape(2, 3));
        cg::composed_layout   aob(a, 2, b);
        std::array<size_t, 1> idx0 = {0};
        std::vector<size_t>   idx1;
        EXPECT_EQ(cg::get(cg::select(aob, idx0), 0),
                  cg::composed_layout(a, 2, cg::layout(cg::shape(2), cg::stride(1))));
        EXPECT_EQ(cg::get(cg::select(aob, 0), 0),
                  cg::composed_layout(a, 2, cg::layout(cg::shape(2), cg::stride(1))));
        EXPECT_EQ(cg::select(aob, 0, 1), aob);
        EXPECT_EQ(cg::rank(cg::select(aob, idx1)), 0);
    }
}

TEST(ComposedLayoutTest, Upcast)
{
    {
        auto lay = cg::from_string<cg::composed_layout>(std::string("8:1 o 6 o (2,4):(1,2)")).value();
        EXPECT_EQ("4:1 o 3 o (1,4):(1,1)", to_string(upcast(2, lay)));
    }
}

////////////////////////////////////////////////////////////////////////
// LayoutTest.CoSize
TEST(ComposedLayoutTest, CoSize)
{
    // Test for 'cosize(layout) == cosize(layout.outer)'
    {
        cg::swizzle         inner(3, 5, 4);
        cg::layout          outer(cg::shape(10, cg::shape(10, 10), 10),
                         cg::stride(10, cg::stride(1, 200), 2000));
        cg::composed_layout lay(inner, 2, outer);
        EXPECT_EQ(cg::cosize(lay), cg::cosize(outer));
    }
    // Test for 'cosize(layout) == error when layout is affine'
    {
        cg::layout          inner(cg::shape(16));
        cg::layout          outer(cg::shape(10, cg::shape(10, 10), 10),
                         cg::stride(10, cg::stride(1, 200), 2000));
        cg::composed_layout lay(inner, 2, outer);
        EXPECT_TRUE(cg::has_error(cg::cosize(lay)));
    }

    // No need to repeat for other patterns as cosize of composed layout is cosize of outer
}

TEST(ComposedLayoutTest, Downcast)
{
    {
        auto lay = cg::from_string<cg::composed_layout>(std::string("8:1 o 6 o (2,4):(1,2)")).value();
        EXPECT_EQ("16:1 o 12 o (4,4):(1,4)", to_string(downcast(2, lay)));
    }
    {
        auto lay = cg::from_string<cg::composed_layout>(std::string("S<3,4,3> o 6 o (2,4):(1,2)")).value();
        EXPECT_EQ("S<3,5,3> o 12 o (4,4):(1,4)", to_string(downcast(2, lay)));
    }
}
