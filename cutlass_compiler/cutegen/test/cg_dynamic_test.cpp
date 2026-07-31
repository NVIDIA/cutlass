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

#include <memory>
#include <optional>
#include <cstddef>
#include <string>
#include <variant>
#include <vector>

#include "cutegen/cutegen.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"
#include "cutegen/dynamic.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/scaled_basis.hpp"
#include "cutegen/underscore.hpp"

#include "utils.hpp"

#include "gtest/gtest.h"

namespace cutegen
{
struct cg_error_t;
} // namespace cutegen

namespace cg = cutegen;

// Dynamic type for testing, that simply holds an integer value
struct test_dynamic_t : cg::dynamic_t
{
    using value_t = int;
    constexpr test_dynamic_t() :
        value(0) {}
    test_dynamic_t(int v) :
        value(v) {}
    bool    operator==(const test_dynamic_t& b) const { return value == b.value; }
    bool    operator!=(const test_dynamic_t& b) const { return value != b.value; }
    value_t value;
};

TEST(DynamicNoBackendTest, BasicInt)
{
    auto a = test_dynamic_t(0);
    auto b = test_dynamic_t(2);
    auto c = test_dynamic_t(2);
    EXPECT_NE(a, b);
    EXPECT_EQ(b, c);
}

TEST(DynamicNoBackendTest, BasicPtr)
{
    using dyn_ptr_t = cg::dynamic_ptr_t;
    dyn_ptr_t a(32);
    EXPECT_EQ(a.get_value_bitwidth(), 32);
    EXPECT_EQ(a.get_alignment_bytes(), 4);
    dyn_ptr_t b(/*bit_width=*/16, /*byte_alignment=*/8);
    EXPECT_EQ(b.get_value_bitwidth(), 16);
    EXPECT_EQ(b.get_alignment_bytes(), 8);
}

TEST(DynamicNoBackendTest, GetDynamicValues)
{
    using dyn_t = test_dynamic_t;
    using shape = cg::rec_var<int, dyn_t, cg::cg_error_t>;
    {
        auto a   = shape(dyn_t(10), shape(1, dyn_t(11), 2), dyn_t(12), 3);
        auto v   = cg::get_leaves_with_type<dyn_t>(a);
        auto res = std::vector<dyn_t::value_t>{10, 11, 12};
        ASSERT_EQ(v.size(), res.size());
        for(size_t i = 0; i < res.size(); i++) EXPECT_EQ(v[i].value, res[i]);
    }
    {
        auto a = shape(10, shape(1, 11, 2), 12, 3);
        auto v = cg::get_leaves_with_type<dyn_t>(a);
        EXPECT_TRUE(v.empty());
    }
}

TEST(DynamicNoBackendTest, Codec)
{
    using shape = cg::rec_var<int, cg::dynamic_t, cg::cg_error_t>;
    // Verify that the encode/decode round trip returns the same as the
    // input.
    EXPECT_TRUE(test_codec(shape(3, cg::dynamic_t{}, 5)));

    using var_with_ptr = cg::rec_var<int, cg::dynamic_ptr_t, cg::cg_error_t>;
    EXPECT_TRUE(test_codec(var_with_ptr(cg::dynamic_ptr_t(32, 8),
                                        11,
                                        cg::dynamic_ptr_t(16))));
}

namespace
{
template <class T>
void test_from_string(const T& t, const char* str)
{
    auto tFS = cg::from_string<T>(std::string(str));
    EXPECT_TRUE(tFS.has_value()) << " parse failed for " << str << std::endl;
    EXPECT_EQ(tFS.value(), t);
}
} // namespace

TEST(DynamicNoBackendTest, String)
{
    using shape = cg::rec_var<int, cg::dynamic_t, cg::cg_error_t>;
    // Verify that the encode/decode round trip returns the same as the
    // input.
    shape s(3, cg::dynamic_t{}, 5);
    test_from_string(s, "(3,?,5)");
    test_from_string(s, "(3, ?,5)");

    // Test width property
    shape s3(3, shape(cg::dynamic_t{/*width=*/32}, cg::dynamic_t{/*width=*/64}), 5);
    test_from_string(s3, "(3,(?,?{i64}),5)");
    test_from_string(s3, "(3,(?{i32},?{i64}),5)");

    // Test different integer widths
    shape s4(cg::dynamic_t{/*width=*/1},
             cg::dynamic_t{/*width=*/8},
             cg::dynamic_t{/*width=*/16},
             cg::dynamic_t{/*width=*/32},
             cg::dynamic_t{/*width=*/64});
    test_from_string(s4, "(?{i1}, ?{i8}, ?{i16}, ?{i32}, ?{i64})");

    EXPECT_FALSE(cg::from_string<cg::shape>("?{i31}").has_value());
    EXPECT_FALSE(cg::from_string<cg::shape>("?{i31").has_value());
    EXPECT_FALSE(cg::from_string<cg::shape>("?{i32div1}").has_value());

    cg::dynamic_ptr_t ptr(/*width = */ 32, /*align = */ 4);
    test_from_string(ptr, "i32*{align=4}");
    test_from_string(ptr, " i32*{align=4}");
    test_from_string(ptr, "i32 *{align=4}");
    test_from_string(ptr, "i32 * {align=4}");
    test_from_string(ptr, "i32 * { align=4}");
    test_from_string(ptr, "i32 * { align  =4}");
    test_from_string(ptr, "i32 * { align= 4}");
    test_from_string(ptr, "i32 * { align= 4 } ");

    EXPECT_FALSE(cg::from_string<cg::dynamic_ptr_t>("i32").has_value());
    EXPECT_FALSE(cg::from_string<cg::dynamic_ptr_t>("*i32").has_value());
    EXPECT_FALSE(cg::from_string<cg::dynamic_ptr_t>("i1*{}").has_value());
    EXPECT_FALSE(cg::from_string<cg::dynamic_ptr_t>("i64*{align=}").has_value());
    EXPECT_FALSE(cg::from_string<cg::dynamic_ptr_t>("i64*{align=").has_value());
    EXPECT_FALSE(cg::from_string<cg::dynamic_ptr_t>("i64*{align").has_value());
    EXPECT_FALSE(cg::from_string<cg::dynamic_ptr_t>("i64*{align}").has_value());
    EXPECT_FALSE(cg::from_string<cg::dynamic_ptr_t>("i64*{align 8}").has_value());

    cg::dynamic_ptr_t ptr0(/*width = */ 64, /*align = */ 1);
    EXPECT_EQ(cg::to_string(ptr0), std::string("i64*{align=1}"));
    cg::dynamic_ptr_t ptr1(/*width = */ 16, /*align = */ 2);
    EXPECT_EQ(cg::to_string(ptr1), std::string("i16*"));
    cg::dynamic_ptr_t ptr2(/*width = */ 128, /*align = */ 16);
    EXPECT_EQ(cg::to_string(ptr2), std::string("i128*"));
}

TEST(DynamicNoBackendTest, ConstantFolding)
{
    using dyn_t = cg::dynamic_t;
    using rv_t  = cg::rec_var<cg::static_int_t, dyn_t, cg::cg_error_t>;
    {
        // Div with LHS=0 returns 0
        auto dividend = 0;
        auto divisor  = dyn_t{};
        auto q        = cg::scalar_div<rv_t>(rv_t{dividend}, rv_t{divisor});
        EXPECT_EQ(q, 0);
    }
    {
        // Mod with RHS=1 returns 0
        auto dividend = dyn_t{};
        auto divisor  = 1;
        auto r        = cg::scalar_mod<rv_t>(rv_t{dividend}, rv_t{divisor});
        EXPECT_EQ(r, 0);
    }
    {
        // Mod with RHS=-1 returns 0
        auto dividend = dyn_t{};
        auto divisor  = -1;
        auto r        = cg::scalar_mod<rv_t>(rv_t{dividend}, rv_t{divisor});
        EXPECT_EQ(r, 0);
    }
    {
        // Mod with LHS=0 returns 0
        auto dividend = 0;
        auto divisor  = dyn_t{};
        auto r        = cg::scalar_mod<rv_t>(rv_t{dividend}, rv_t{divisor});
        EXPECT_EQ(r, 0);
    }
}

TEST(DynamicNoBackendTest, Composition)
{
    // This test verifies the correct behavior of shape_min in composition
    auto a   = cg::from_string<cg::layout>(std::string("(512,?):(1,512)"));
    auto b   = cg::from_string<cg::layout>(std::string("((32,4,?)):((1@1,4@0,1@2))"));
    auto boa = cg::from_string<cg::layout>(std::string("((32,4,4),?):((1@1,4@0,1@2),4@2)"));
    ASSERT_TRUE(a.has_value());
    ASSERT_TRUE(b.has_value());
    ASSERT_TRUE(boa.has_value());
    EXPECT_EQ(cg::composition(b.value(), a.value()), boa.value());
}

TEST(DynamicNoBackendTest, CollectDynamicValues)
{
    using scaled_basis = cg::scaled_basis;
    using stride       = cg::stride;
    using shape        = cg::shape;

    const auto dy_ = cg::dynamic_t{};

    // Basics

    {
        auto empty = cg::rec_var<cg::static_int_t, cg::cg_error_t>{};
        EXPECT_EQ(cg::get_dynamics<std::vector<cg::dynamic_t>>(empty).size(), 0);
    }
    {
        auto no_dynamics = cg::from_string<cg::rec_var<cg::static_int_t, cg::cg_error_t>>("(512, (64, 16))");
        ASSERT_TRUE(no_dynamics.has_value());
        EXPECT_EQ(cg::get_dynamics<std::vector<cg::dynamic_t>>(no_dynamics.value()).size(), 0);
    }

    // Strides

    {
        auto just_statics = cg::from_string<stride>(std::string("(16, 32, (64, (16, 4)))"));
        ASSERT_TRUE(just_statics.has_value());
        EXPECT_EQ(cg::get_dynamics<std::vector<cg::dynamic_t>>(just_statics.value()).size(), 0);
    }
    {
        auto simple_dynamic = cg::from_string<stride>(std::string("(16, ?, (64, ?, (?, ?)), ?)"));
        ASSERT_TRUE(simple_dynamic.has_value());
        EXPECT_EQ(cg::get_dynamics<std::vector<cg::dynamic_t>>(simple_dynamic.value()).size(), 5);
    }
    {
        auto sb_dynamic = cg::from_string<stride>(std::string("(16, ?, (64, ?@0, (?, ?)), ?@1)"));
        ASSERT_TRUE(sb_dynamic.has_value());
        EXPECT_EQ(cg::get_dynamics<std::vector<cg::dynamic_t>>(sb_dynamic.value()).size(), 5);
    }
    {
        stride sb_dynamic(4, scaled_basis(1, cg::ratio(2, 4)), dy_);
        EXPECT_EQ(cg::get_dynamics<std::vector<cg::dynamic_t>>(sb_dynamic).size(), 1);
    }

    // Layouts

    using layout = cg::layout;

    {
        layout l_static{};
        auto   size = cg::get_dynamics<std::vector<cg::dynamic_t>>(l_static).size();
        EXPECT_EQ(size, 0);
    }
    {
        layout l_dyn_shape{{128, dy_}, {128, 1}};
        auto   size = cg::get_dynamics<std::vector<cg::dynamic_t>>(l_dyn_shape).size();
        EXPECT_EQ(size, 1);
    }
    {
        layout l_dyn_stride{{128, 128}, {128, dy_}};
        auto   size = cg::get_dynamics<std::vector<cg::dynamic_t>>(l_dyn_stride).size();
        EXPECT_EQ(size, 1);
    }
    {
        layout l_dyn_shape_stride{{dy_, 128}, {128, dy_}};
        auto   size = cg::get_dynamics<std::vector<cg::dynamic_t>>(l_dyn_shape_stride).size();
        EXPECT_EQ(size, 2);
    }
    {
        layout l_dyn_shape_stride{{dy_, dy_}, {dy_, dy_}};
        auto   size = cg::get_dynamics<std::vector<cg::dynamic_t>>(l_dyn_shape_stride).size();
        EXPECT_EQ(size, 4);
    }

    // Composed Layouts

    using comp_layout = cg::composed_layout;

    {
        comp_layout l_static{};
        auto        size = cg::get_dynamics<std::vector<cg::dynamic_t>>(l_static).size();
        EXPECT_EQ(size, 0);
    }
    {
        comp_layout l_static{layout{128, 128}, 64, layout{128, 128}};
        auto        size = cg::get_dynamics<std::vector<cg::dynamic_t>>(l_static).size();
        EXPECT_EQ(size, 0);
    }
    {
        comp_layout l_dynamic{layout{dy_, 128}, dy_, layout{128, dy_}};
        auto        size = cg::get_dynamics<std::vector<cg::dynamic_t>>(l_dynamic).size();
        EXPECT_EQ(size, 3);
    }
    {
        comp_layout l_dynamic{cg::swizzle{}, cg::cg_error_t{}, layout{128, dy_}};
        auto        size = cg::get_dynamics<std::vector<cg::dynamic_t>>(l_dynamic).size();
        EXPECT_EQ(size, 1);
    }
    {
        comp_layout l_dynamic{layout{dy_, dy_}, dy_, layout{dy_, dy_}};
        auto        size = cg::get_dynamics<std::vector<cg::dynamic_t>>(l_dynamic).size();
        EXPECT_EQ(size, 5);
    }

    // Tiles

    using tile     = cg::tile;
    const auto un_ = cg::underscore_t{};

    {
        tile t_static{layout{128, 256}};
        auto size = cg::get_dynamics<std::vector<cg::dynamic_t>>(t_static).size();
        EXPECT_EQ(size, 0);
    }
    {
        tile t_dynamic{layout{dy_, 256}};
        auto size = cg::get_dynamics<std::vector<cg::dynamic_t>>(t_dynamic).size();
        EXPECT_EQ(size, 1);
    }
    {
        tile t_dynamic{layout{cg::dynamic_t{}, cg::dynamic_t{}}};
        auto size = cg::get_dynamics<std::vector<cg::dynamic_t>>(t_dynamic).size();
        EXPECT_EQ(size, 2);
    }
    {
        tile t_underscore{un_};
        auto size = cg::get_dynamics<std::vector<cg::dynamic_t>>(t_underscore).size();
        EXPECT_EQ(size, 0);
    }
    {
        tile t_dynamic_rec{layout{shape{shape{128, dy_}, dy_}, stride{stride{dy_, 256}, 128}}};
        auto size = cg::get_dynamics<std::vector<cg::dynamic_t>>(t_dynamic_rec).size();
        EXPECT_EQ(size, 3);
    }
    {
        tile t_dynamic_rec{layout{shape{shape{dy_, dy_}, dy_}, stride{stride{dy_, dy_}, dy_}}};
        auto size = cg::get_dynamics<std::vector<cg::dynamic_t>>(t_dynamic_rec).size();
        EXPECT_EQ(size, 6);
    }
}

struct derived_dynamic_t : public cg::dynamic_t
{
    derived_dynamic_t(float f_ = 1.0f) :
        dynamic_t(),
        f(f_)
    {
    }
    float get_f() const { return f; }

private:
    float f;
};

struct derived_dynamic_traits_t
{
    using dynamic_int_t = derived_dynamic_t;
};

TEST(DynamicNoBackendTest, CastToDynamicBase)
{
    // Verify that the cg::cast_to_base_dynamic() method works for std::variant
    // instances.
    using int_derived_dyn_t = std::variant<cg::static_int_t, derived_dynamic_t>;
    using int_dyn_t         = std::variant<cg::static_int_t, cg::dynamic_t>;

    int_derived_dyn_t d0(12);
    auto              b0 = cg::cast_to_base_dynamic<int_dyn_t>(d0);
    EXPECT_TRUE(std::holds_alternative<cg::static_int_t>(b0));

    int_derived_dyn_t d1(derived_dynamic_t(-1.0f));
    auto              b1 = cg::cast_to_base_dynamic<int_dyn_t>(d1);
    EXPECT_TRUE(std::holds_alternative<cg::dynamic_t>(b1));
    EXPECT_EQ(std::get<cg::dynamic_t>(b1), cg::dynamic_t());

    // Verify that the cg::cast_to_base_dynamic() method works for recursive
    // variant instances.
    using my_shape_t = cg::cute_shape_t<derived_dynamic_traits_t>;
    my_shape_t sh(1, 2, derived_dynamic_t{2.0f}, derived_dynamic_t{-1.0f});

    auto shb = cg::cast_to_base_dynamic<cg::shape>(sh);
    EXPECT_EQ(shb, cg::shape(1, 2, cg::dynamic_t{}, cg::dynamic_t{}));
}
