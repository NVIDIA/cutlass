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

#include "cutegen/cutegen.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"
#include "cutegen/rec_var_algorithms.hpp"

#include "gtest/gtest.h"

namespace cg = cutegen;

using cg::operator""_tup;
using cg::operator""_lay;
using cg::operator""_shp;
using cg::operator""_str;

TEST(MiscTest, Signum)
{
    using tuple = cg::int_tuple;
    // Test signum at least for the static case
    EXPECT_EQ(cg::detail::signum(tuple(2)), 1);
    EXPECT_EQ(cg::detail::signum(tuple(0)), 0);
    EXPECT_EQ(cg::detail::signum(tuple(-1)), -1);
}

TEST(LiteralTest, Literals)
{
    {
        auto lay = "(((64,128),1),1,1,(2)):(((1@0,1@1),0),0,0,(64@0))"_lay;
        EXPECT_EQ(cg::to_string(lay), "(((64,128),1),1,1,(2)):(((1@0,1@1),0),0,0,(64@0))");
    }

    {
        auto shp = "(64,128)"_shp;
        EXPECT_EQ(cg::to_string(shp), "(64,128)");
    }

    {
        auto shp = "(64,128)"_str;
        EXPECT_EQ(cg::to_string(shp), "(64,128)");
    }

    {
        auto shp = "(64,128)"_tup;
        EXPECT_EQ(cg::to_string(shp), "(64,128)");
    }
}

TEST(MiscTest, LogShiftR)
{
    using int_tuple = cg::int_tuple;
    EXPECT_EQ(cg::scalar_lshr<int_tuple>(32, 3), 4);
    EXPECT_EQ(cg::scalar_lshr<int_tuple>(32, -3), 256);
    // Verify that sign is not preserved
    EXPECT_EQ(cg::scalar_lshr<int_tuple>(INT_MIN, 1), 1073741824);
}

TEST(MiscTest, ShiftLeft)
{
    using int_tuple = cg::int_tuple;
    EXPECT_EQ(cg::scalar_shl<int_tuple>(32, 3), 256);
    EXPECT_EQ(cg::scalar_shl<int_tuple>(32, -3), 4);
}

TEST(MiscTest, SafeAbs)
{
    EXPECT_EQ(cg::safe_abs(-1), 1);
    EXPECT_EQ(cg::safe_abs(0), 0);
    EXPECT_EQ(cg::safe_abs(INT_MAX), 2147483647U);
    EXPECT_EQ(cg::safe_abs(INT_MIN), 2147483648U);
}

TEST(MiscTest, Log2Floor)
{
    EXPECT_EQ(cg::detail::log2_floor(UINT_MAX), 31);
    EXPECT_EQ(cg::detail::log2_floor(1U), 0);
    EXPECT_EQ(cg::detail::log2_floor(15U), 3);
    EXPECT_EQ(cg::detail::log2_floor(1024U), 10);
}

TEST(MiscTest, Log2Ceil)
{
    EXPECT_EQ(cg::detail::log2_ceil(UINT_MAX), 32);
    EXPECT_EQ(cg::detail::log2_ceil(0U), 0);
    EXPECT_EQ(cg::detail::log2_ceil(1U), 0);
    EXPECT_EQ(cg::detail::log2_ceil(15U), 4);
    EXPECT_EQ(cg::detail::log2_ceil(1024U), 10);
    EXPECT_EQ(cg::detail::log2_ceil(33U), 6);
}

TEST(MiscTest, Visitable)
{
    static_assert(cg::is_visitable_v<cg::int_tuple>);
    static_assert(cg::is_visitable_v<cg::shape>);
    static_assert(cg::is_visitable_v<cg::stride>);
    static_assert(cg::is_visitable_v<cg::coord>);
    static_assert(cg::is_visitable_v<cg::tile>);
    static_assert(!cg::is_visitable_v<float>);
}

TEST(MiscTest, PopCount)
{
    EXPECT_EQ(cg::detail::popcount(0U), 0);
    EXPECT_EQ(cg::detail::popcount(std::numeric_limits<uint64_t>::max()), 64);
    EXPECT_EQ(cg::detail::popcount(std::numeric_limits<uint32_t>::max()), 32);
    EXPECT_EQ(cg::detail::popcount((1U << 8) - 1), 8);
    EXPECT_EQ(cg::detail::popcount(static_cast<uint64_t>(1) << 8), 1);
}

TEST(MiscTest, Ctz)
{
    EXPECT_EQ(cg::detail::ctz(1U), 0);
    EXPECT_EQ(cg::detail::ctz(1U << 8), 8);
    EXPECT_EQ(cg::detail::ctz(11U), 0);
    EXPECT_EQ(cg::detail::ctz(static_cast<uint64_t>(1) << 45), 45);
}

TEST(MiscTest, Clz)
{
    EXPECT_EQ(cg::detail::clz(1U), 31);
    EXPECT_EQ(cg::detail::clz(static_cast<uint64_t>(1)), 63);
    EXPECT_EQ(cg::detail::clz(1U << 8), 23);
    EXPECT_EQ(cg::detail::clz(std::numeric_limits<uint32_t>::max()), 0);
    EXPECT_EQ(cg::detail::clz(std::numeric_limits<uint64_t>::max()), 0);
    EXPECT_EQ(cg::detail::clz(static_cast<uint64_t>(1) << 45), 18);
}

TEST(MiscTest, IntError)
{
    using int_tuple = cg::int_tuple;

    EXPECT_TRUE(cg::holds_error(cg::scalar_div<int_tuple>(12, 0)));
    EXPECT_TRUE(cg::holds_error(cg::scalar_mod<int_tuple>(1, 0)));

    {
        // Result cannot be represented by integer type in the return
        // type variant.
        using var_t  = std::variant<int32_t, cg::cg_error_t>;
        auto max_val = std::numeric_limits<int64_t>::max();
        auto res     = cg::scalar_div<var_t>(max_val, 1);
        EXPECT_TRUE(std::holds_alternative<cg::cg_error_t>(res));
    }
}
