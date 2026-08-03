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

#include <algorithm>
#include <iostream>
#include <optional>
#include <string>
#include <vector>

#include "cutegen/cg_error.hpp"
#include "cutegen/cutegen.hpp"
#include "cutegen/ratio.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"

#include "gtest/gtest.h"

#include "utils.hpp"

namespace cg = cutegen;

TEST(RatioTest, Equality)
{
    cg::ratio rA(4, 8);
    cg::ratio rB(1, 2);
    cg::ratio rC(1, 2);
    EXPECT_NE(rA, rB);
    EXPECT_EQ(rB, rC);

    cg::ratio rD(99, -11);
    cg::ratio rE(-99, 11);
    EXPECT_NE(rD, rE);
}

TEST(RatioTest, IsIntegral)
{
    cg::ratio rA(4, 8);
    cg::ratio rB(1, 2);
    cg::ratio rC(16, 4);
    EXPECT_FALSE(rA.is_integral());
    EXPECT_FALSE(rB.is_integral());
    EXPECT_TRUE(rC.is_integral());

    cg::ratio rD(99, -11);
    cg::ratio rE(-99, 11);
    EXPECT_TRUE(rD.is_integral());
    EXPECT_TRUE(rE.is_integral());
}

TEST(RatioTest, Reduced)
{
    cg::ratio rA(4, 8);
    cg::ratio rB(1, 2);
    cg::ratio rC(99, 11);
    EXPECT_TRUE(std::holds_alternative<cg::ratio>(rA.reduced()));
    EXPECT_TRUE(std::holds_alternative<cg::ratio>(rB.reduced()));
    EXPECT_TRUE(std::holds_alternative<cg::ratio::int_t>(rC.reduced()));
    EXPECT_EQ(rA.reduced(), rB.reduced());

    cg::ratio rD(99, -11);
    cg::ratio rE(-99, 11);
    EXPECT_TRUE(std::holds_alternative<cg::ratio::int_t>(rD.reduced()));
    EXPECT_TRUE(std::holds_alternative<cg::ratio::int_t>(rE.reduced()));
    EXPECT_EQ(std::get<cg::ratio::int_t>(rD.reduced()), -9);
    EXPECT_EQ(std::get<cg::ratio::int_t>(rE.reduced()), -9);

    // The current implementation is derived from the CuTe C++ implementation
    // and returns 0 for:
    // 1 / 0
    // 0 / 0
    cg::ratio rF(1, 0);
    EXPECT_TRUE(std::holds_alternative<cg::ratio::int_t>(rF.reduced()));
    EXPECT_EQ(std::get<cg::ratio::int_t>(rF.reduced()), 0);
    cg::ratio rG(0, 0);
    EXPECT_TRUE(std::holds_alternative<cg::ratio::int_t>(rG.reduced()));
    EXPECT_EQ(std::get<cg::ratio::int_t>(rG.reduced()), 0);
    cg::ratio rH(0, 4);
    EXPECT_TRUE(std::holds_alternative<cg::ratio::int_t>(rH.reduced()));
    EXPECT_EQ(std::get<cg::ratio::int_t>(rH.reduced()), 0);
}

TEST(RatioTest, FromString)
{
    // Test ratio parsing
    {
        auto optRatioA = cg::from_string<cg::ratio>(std::string("1/2"));
        EXPECT_TRUE(optRatioA.has_value());
        EXPECT_EQ(cg::ratio(1, 2), optRatioA.value());
        auto optRatioB = cg::from_string<cg::ratio>(std::string(" 2 / -3 "));
        EXPECT_TRUE(optRatioB.has_value());
        EXPECT_EQ(cg::ratio(2, -3), optRatioB.value());
        // Disallow zero denominator
        auto optRatioC = cg::from_string<cg::ratio>(std::string("4/0"));
        EXPECT_FALSE(optRatioC.has_value());
    }
    // Test invalid ratio strings
    {
        auto optRatioC = cg::from_string<cg::ratio>(std::string("2"));
        EXPECT_FALSE(optRatioC.has_value());
        auto optRatioD = cg::from_string<cg::ratio>(std::string(" 5 /"));
        EXPECT_FALSE(optRatioD.has_value());
        auto optRatioE = cg::from_string<cg::ratio>(std::string(" / 5"));
        EXPECT_FALSE(optRatioE.has_value());
    }
}

TEST(RatioTest, Codec)
{
    EXPECT_TRUE(test_codec(cg::ratio(1, 2)));
    EXPECT_TRUE(test_codec(cg::ratio(2, -3)));
    // Verify failure on invalid buffers
    {
        std::vector<char> buffer;
        cg::encode(buffer, cg::ratio(1, 2));
        buffer.resize(buffer.size() - 1);
        auto dec = cg::decode<cg::ratio>(buffer);
        EXPECT_FALSE(dec.has_value());
    }
    // Verify failure on zero denominator decode. (We can't use the ratio class
    // directly since it asserts in debug mode with a zero denominator.
    // Therefore, we assume the nominal encoding of numerator followined by
    // denominator.
    {
        std::vector<char> buffer;
        cg::encode(buffer, static_cast<cg::ratio::int_t>(5));
        cg::encode(buffer, static_cast<cg::ratio::int_t>(0));
        auto dec = cg::decode<cg::ratio>(buffer);
        EXPECT_FALSE(dec.has_value());
    }
}

TEST(RatioTest, Arithmetic)
{
    using var_t = std::variant<cg::static_int_t, cg::ratio, cg::cg_error_t>;
    using ratio = cg::ratio;

    // 1/2 * 8/4 = 8/8= 1
    EXPECT_EQ(var_t(1), cg::scalar_mul<var_t>(ratio(1, 2), ratio(8, 4)));
    // 1/2 * 8 = 8/2 = 4
    EXPECT_EQ(var_t(4), cg::scalar_mul<var_t>(ratio(1, 2), 8));
    // 11 * 2/6 = 22/6 = 11/3
    EXPECT_EQ(var_t(ratio(11, 3)), cg::scalar_mul<var_t>(11, ratio(2, 6)));
    // 1/4 * 0 = 0
    EXPECT_EQ(var_t(0), cg::scalar_mul<var_t>(ratio(1, 4), 0));
    // 3/3 * 0 = 0
    EXPECT_EQ(var_t(0), cg::scalar_mul<var_t>(ratio(3, 3), 0));
    // 5/5 * 17 = 17
    EXPECT_EQ(var_t(17), cg::scalar_mul<var_t>(ratio(5, 5), 17));
    // 1/4 * 1 = 1/4
    EXPECT_EQ(var_t(ratio(1, 4)), cg::scalar_mul<var_t>(ratio(1, 4), 1));
    // -11 * 2/6 = -22/6 = -11/3
    EXPECT_EQ(var_t(ratio(-11, 3)), cg::scalar_mul<var_t>(-11, ratio(2, 6)));

    // 1/2 + 1/4 = 3/4
    EXPECT_EQ(var_t(ratio(3, 4)), cg::scalar_add<var_t>(ratio(1, 2), ratio(1, 4)));
    // 3/2 + 4 = 11/2
    EXPECT_EQ(var_t(ratio(11, 2)), cg::scalar_add<var_t>(ratio(3, 2), 4));
    // 7 + 1/3 = 22/3
    EXPECT_EQ(var_t(ratio(22, 3)), cg::scalar_add<var_t>(7, ratio(1, 3)));
    // 1/2 + 1/2 = 1
    EXPECT_EQ(var_t(1), cg::scalar_add<var_t>(ratio(1, 2), ratio(1, 2)));
    // 3/2 + 7/2 = 10/2 = 5
    EXPECT_EQ(var_t(5), cg::scalar_add<var_t>(ratio(3, 2), ratio(7, 2)));
    // 24 + 0/2 = 24
    EXPECT_EQ(var_t(24), cg::scalar_add<var_t>(24, ratio(0, 2)));
    // 3/2 + (-7/2) = -4/2 = -2
    EXPECT_EQ(var_t(-2), cg::scalar_add<var_t>(ratio(3, 2), ratio(-7, 2)));
    // 0/2 + 13 = 14
    EXPECT_EQ(var_t(14), cg::scalar_add<var_t>(ratio(0, 2), 14));
    // 1/2 + 0 = 1/2
    EXPECT_EQ(var_t(ratio(1, 2)), cg::scalar_add<var_t>(ratio(1, 2), 0));

    // 3/4 - 1/2 = 1/4
    EXPECT_EQ(var_t(ratio(1, 4)), cg::scalar_sub<var_t>(ratio(3, 4), ratio(1, 2)));
    // 22/2 - 4 = 14/2
    EXPECT_EQ(var_t(7), cg::scalar_sub<var_t>(ratio(22, 2), 4));
    // 1 - 1/11 = 10/11
    EXPECT_EQ(var_t(ratio(10, 11)), cg::scalar_sub<var_t>(1, ratio(1, 11)));
    // 3/2 - 7/2 = -4/2 = -2
    EXPECT_EQ(var_t(-2), cg::scalar_sub<var_t>(ratio(3, 2), ratio(7, 2)));
    // 0/2 - 5 = -5
    EXPECT_EQ(var_t(-5), cg::scalar_sub<var_t>(ratio(0, 2), 5));
}
