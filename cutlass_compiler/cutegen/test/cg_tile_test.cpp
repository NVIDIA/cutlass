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

#include <iosfwd>
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

namespace cg = cutegen;

TEST(TileTest, RecVarTypes)
{
    // Tiles do not have an integer type
    static_assert(std::is_same_v<void, cg::tile::int_t>);
    static_assert(std::is_same_v<cg::tile::elem_types_t, std::tuple<cg::layout, cg::underscore_t>>);
}

TEST(TileTest, HoldsLeaf)
{
    {
        cg::tile t(cg::_);
        EXPECT_TRUE(cg::holds_leaf(t));
    }
    {
        cg::tile t(cg::layout(3));
        EXPECT_TRUE(cg::holds_leaf(t));
    }
    {
        cg::tile t(cg::layout(3), cg::layout(4));
        EXPECT_FALSE(cg::holds_leaf(t));
    }
}

TEST(TileTest, FromString)
{
    {
        // Empty tile
        auto a = cg::from_string<cg::tile>(std::string("[]"));
        EXPECT_TRUE(a.has_value());
        EXPECT_EQ(a, cg::tile{});
    }
    {
        // A tile with two layouts specified as integers
        auto a = cg::from_string<cg::tile>(std::string("[5;2]"));
        EXPECT_TRUE(a.has_value());
        auto b = cg::tile(cg::layout(5), cg::layout(2));
        EXPECT_EQ(a, b);
    }
    {
        // A tile with a single layout without specifying the stride
        auto a = cg::from_string<cg::tile>(std::string("[(2,(3,4))]"));
        EXPECT_TRUE(a.has_value());
        // Workaround to force a vector of variants of size 1
        auto b = cg::tile{};
        b.append(cg::layout(cg::shape(2, cg::shape(3, 4))));
        EXPECT_EQ(a, b);
    }
    {
        // A tile with a single layout with dummy strides
        auto a = cg::from_string<cg::tile>(std::string("[(2,(3,4)):(1,(3,2))]"));
        EXPECT_TRUE(a.has_value());
        // Workaround to force a vector of variants of size 1
        auto b = cg::tile{};
        b.append(cg::layout(cg::shape(2, cg::shape(3, 4)),
                            cg::stride(1, cg::stride(3, 2))));
        EXPECT_EQ(a, b);
    }
    {
        // A tile with 2 layouts
        auto a = cg::from_string<cg::tile>(std::string("[(2,(3,4));5:2]"));
        EXPECT_TRUE(a.has_value());
        EXPECT_EQ(a,
                  cg::tile(cg::layout(cg::shape(2, cg::shape(3, 4))),
                           cg::layout(cg::shape(5), cg::stride(2))));
    }
    {
        // A complex example with dummy strides
        std::string s = "[(2,(3,4));[_;((10,11),12):((8,2),5)];5:4@2]";
        auto        a = cg::from_string<cg::tile>(s);
        EXPECT_TRUE(a.has_value());
        EXPECT_EQ(
            a,
            cg::tile(cg::layout(cg::shape(2, cg::shape(3, 4))),
                     cg::tile(
                         cg::_,
                         cg::layout(cg::shape(cg::shape(10, 11), 12),
                                    cg::stride(cg::stride(8, 2), 5))),
                     cg::layout(cg::shape(5), cg::scaled_basis(2, 4))));
        auto b = cg::make_tile<cg::tile>(s);
        EXPECT_EQ(a, b);
    }

    {
        auto a = cg::from_string<cg::tile>(std::string("(5,2):(1,5)"));
        auto b = cg::tile(cg::layout(cg::shape(5, 2)));
        EXPECT_TRUE(a.has_value());
        EXPECT_EQ(b, a);
    }

    {
        // Verify that the is_tile trait is generic enough
        using rv_t = cg::rec_var<cg::layout, cg::underscore_t, cg::cg_error_t>; // != cg::tile
        auto t     = cg::from_string<rv_t>("[(2,2):(1,2);_]");
        ASSERT_TRUE(t.has_value());
        rv_t t_ref(cg::layout(cg::shape(2, 2)), cg::_);
        EXPECT_EQ(t.value(), t_ref);
    }
}

TEST(TileTest, ToString)
{
    // Verify steps:
    // 1. a -> tile
    // 2_0. b_str -> a.to_string()
    // 2_1. c_str -> (ss << a).str()
    // 3_0. b -> from_string(b_str)
    // 3_1. c -> from_string(c_str)
    // 4_0. EXPECT_EQ(a,b)
    // 4_1. EXPECT_EQ(a,c)
    {
        // Empty tile
        std::stringstream ss;
        auto              a = cg::tile{};
        auto              b = cg::from_string<cg::tile>(cg::to_string(a));
        ss << a;
        auto c = cg::from_string<cg::tile>(ss.str());
        EXPECT_EQ(a, b);
        EXPECT_EQ(a, c);
    }
    {
        // A tile with two layouts specified as integers
        std::stringstream ss;
        auto              a = cg::tile(cg::layout(5), cg::layout(2));
        auto              b = cg::from_string<cg::tile>(cg::to_string(a));
        ss << a;
        auto c = cg::from_string<cg::tile>(ss.str());
        EXPECT_EQ(a, b);
        EXPECT_EQ(a, c);
    }
    {
        // A tile with a single layout without specifying the stride
        std::stringstream ss;
        auto              a = cg::tile{};
        a.append(cg::layout(cg::shape(2, cg::shape(3, 4))));
        auto b = cg::from_string<cg::tile>(cg::to_string(a));
        ss << a;
        auto c = cg::from_string<cg::tile>(ss.str());
        EXPECT_EQ(a, b);
        EXPECT_EQ(a, c);
    }
    {
        // A tile with a single layout with dummy strides
        // Workaround to force a vector of variants of size 1
        std::stringstream ss;
        auto              a = cg::tile{};
        a.append(cg::layout(cg::shape(2, cg::shape(3, 4)),
                            cg::stride(1, cg::stride(3, 2))));
        auto b = cg::from_string<cg::tile>(cg::to_string(a));
        ss << a;
        auto c = cg::from_string<cg::tile>(ss.str());
        EXPECT_EQ(a, b);
        EXPECT_EQ(a, c);
    }
    {
        // A tile with 2 layouts
        std::stringstream ss;
        // clang-format off
        auto              a = cg::tile(cg::layout(cg::shape(2, cg::shape(3, 4))),
                                       cg::layout(cg::shape(5), cg::stride(2)));
        auto              b = cg::from_string<cg::tile>(cg::to_string(a));
        // clang-format on
        ss << a;
        auto c = cg::from_string<cg::tile>(ss.str());
        EXPECT_EQ(a, b);
        EXPECT_EQ(a, c);
    }
    {
        // A complex example with dummy strides
        std::stringstream ss;
        // clang-format off
        auto a = cg::tile(cg::layout(cg::shape(2, cg::shape(3, 4))),
                     cg::tile(
                         cg::_,
                         cg::layout(cg::shape(cg::shape(10, 11), 12),
                                    cg::stride(cg::stride(8, 2), 5))),
                     cg::layout(cg::shape(5), cg::scaled_basis(2, 4)));
        // clang-format on
        auto b = cg::from_string<cg::tile>(cg::to_string(a));
        ss << a;
        auto c = cg::from_string<cg::tile>(ss.str());
        EXPECT_EQ(a, b);
        EXPECT_EQ(a, c);
    }
}

TEST(TileTest, ShapeToTile)
{
    // First implementation omitted to wrap shape elements in a layout. This
    // resulted in a build error for cutlass-opt since exceptions are disabled
    // and transform returns cg_error_t{} for invalid cases which cannot be
    // directly held by a tile
    {
        auto s = cg::shape(cg::shape(2, 3, 4), 5);
        EXPECT_EQ(cg::shape_to_tile(s), cg::tile(cg::tile(2, 3, 4), 5));
    }
    {
        cg::shape s{};
        EXPECT_EQ(cg::shape_to_tile(s), cg::tile{});
    }
}

TEST(TileTest, TileToShape)
{
    {
        auto t = cg::tile(cg::tile(2, 3, 4), 5);
        EXPECT_EQ(cg::extract_shape_from_tile(t),
                  cg::shape(cg::shape(2, 3, 4), 5));
    }
    {
        EXPECT_EQ(cg::extract_shape_from_tile(cg::tile()), cg::shape());
    }
}

////////////////////////////////////////////////////////////////////////
// TileTest.HasDynamicType
TEST(TileTest, HasDynamicType)
{
    static_assert(cg::type_can_hold_dynamic_int<cg::layout>::value);
    static_assert(cg::rec_var_has_dynamic_type<cg::tile>::value);
}

TEST(TileTest, IsStatic)
{
    auto a = cg::tile(cg::layout(cg::shape(2, cg::shape(3, 4))),
                      cg::layout(cg::shape(5), cg::stride(2)));
    auto b = cg::tile(cg::layout(cg::shape(2, cg::shape(cg::dynamic_t{}, 4))),
                      cg::layout(cg::shape(5), cg::stride(2)));
    EXPECT_TRUE(cg::is_static(a));
    EXPECT_FALSE(cg::is_static(b));
}

TEST(TileTest, CountDynamicScalars)
{
    {
        auto t = cg::from_string<cg::tile>(std::string("[(1):(?);(?):(4)]"));
        ASSERT_TRUE(t.has_value());
        EXPECT_EQ(cg::scalar_count(t.value(), /*dynamicOnly=*/true), 2);
    }
    {
        auto t = cg::from_string<cg::tile>(std::string("[(1,2):(?,?)]"));
        ASSERT_TRUE(t.has_value());
        EXPECT_EQ(cg::scalar_count(t.value(), /*dynamicOnly=*/true), 2);
    }
    {
        auto t = cg::from_string<cg::tile>(std::string("[(1,?):(?@0,?)]"));
        ASSERT_TRUE(t.has_value());
        EXPECT_EQ(cg::scalar_count(t.value(), /*dynamicOnly=*/true), 3);
    }
}
