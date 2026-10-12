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

// This file provides tests for the cutegen::detail::from_chars() function. On
// platforms that support the std::from_chars() function, that function is used.
// On other platforms, cutegen provides an implementation that mirrors the C++
// standard library version.
// For more recent compilers that support the std::from_chars() function, the
// tests below will run using the C++ standard library implementation. In
// general, we assume that the C++ standard library has its own tests! However,
// in this case, the tests in this file are important in that they:
// - verify behavior of the cutegen implementation directly on platforms that DO
//   NOT support std::from_chars()
// - verify assumptions made by the cutegen implementation on platforms that DO
//   support std::from_chars().

#include <iostream>
#include <optional>
#include <string>

#include "cutegen/charconv.hpp"

#include "gtest/gtest.h"

namespace cg  = cutegen;
namespace det = cg::detail;

// Utility function for checking the results of a call to detail::from_chars()
// for integral types. Returns true if the check is successful:
// - the pointer in the from_chars_result matches the expected pointer
// - the status code in the from_chars_result matches the expected status
// - if parse status indicates success, the optional value provided matches
//   the value that was parsed. (If the parse was expected to fail, the value
//   is not checked for equality.)
template <typename T>
bool check_from_chars(const char*                   s,
                      const std::optional<T>&       value_check,
                      const det::from_chars_result& res_check)
{
    T    value;
    auto res = det::from_chars(s, s + strlen(s), value);
    // The pointer and error code should ALWAYS match what the test call provided.
    if((res.ec != res_check.ec) || (res.ptr != res_check.ptr))
    {
        std::cout << "check_from_chars() failure: "
                  << "error_code = " << static_cast<long>(res.ec)
                  << " (expected " << static_cast<long>(res_check.ec)
                  << "), pointer offset = " << (res.ptr - s)
                  << " (expected " << (res_check.ptr - s) << ")" << std::endl;
        return false;
    }
    // If the error code indicates a successful parse, ALSO compare
    // the parsed value to the expected value.
    if(res.ec == std::errc{})
    {
        if(!value_check.has_value())
        {
            std::cout << "check_from_chars() failure: "
                      << "Parse was successful, but no value provided" << std::endl;
            return false;
        }
        if(value_check.value() != value)
        {
            std::cout << "check_from_char() failure: Parse value was " << value
                      << ", but check value was " << value_check.value() << std::endl;
            return false;
        }
        return true;
    }
    // The parse was unsuccessful (as expected), so the test is successful.
    return true;
}

det::from_chars_result make_result(const char* ptr, std::errc ec = {})
{
    return det::from_chars_result{ptr, ec};
}
////////////////////////////////////////////////////////////////////////
// CharconvTest.Basic
TEST(CharconvTest, Basic)
{
    {
        // Parse success. The from_chars() function should advance the
        // pointer to the A after the valid digits.
        const char* s0 = "12345ABCDEFG";
        EXPECT_TRUE(check_from_chars(s0,
                                     std::optional<int16_t>(12345),
                                     make_result(s0 + 5)));
        EXPECT_TRUE(check_from_chars(s0,
                                     std::optional<int32_t>(12345),
                                     make_result(s0 + 5)));
        EXPECT_TRUE(check_from_chars(s0,
                                     std::optional<int64_t>(12345),
                                     make_result(s0 + 5)));
        EXPECT_TRUE(check_from_chars(s0,
                                     std::optional<uint16_t>(12345),
                                     make_result(s0 + 5)));
        EXPECT_TRUE(check_from_chars(s0,
                                     std::optional<uint32_t>(12345),
                                     make_result(s0 + 5)));
        EXPECT_TRUE(check_from_chars(s0,
                                     std::optional<uint64_t>(12345),
                                     make_result(s0 + 5)));
    }
    {
        // Parse failure with leading whitespace
        const char* s1 = " 1";
        EXPECT_TRUE(check_from_chars(s1,
                                     std::optional<int32_t>{},
                                     make_result(s1, std::errc::invalid_argument)));
    }
    {
        // Parse failure with only a negative sign
        const char* s2 = "-";
        EXPECT_TRUE(check_from_chars(s2,
                                     std::optional<int32_t>{},
                                     make_result(s2, std::errc::invalid_argument)));
    }
    {
        // Parse success up to first whitespace
        const char* s3 = "97  8";
        EXPECT_TRUE(check_from_chars(s3,
                                     std::optional<uint32_t>(97),
                                     make_result(s3 + 2)));
    }
    {
        // Parse failure for empty string
        const char* s4 = "";
        EXPECT_TRUE(check_from_chars(s4,
                                     std::optional<int32_t>{},
                                     make_result(s4, std::errc::invalid_argument)));
    }
    {
        // Parse failure for invalid characters
        const char* s5 = "QWERTY";
        EXPECT_TRUE(check_from_chars(s5,
                                     std::optional<int32_t>{},
                                     make_result(s5, std::errc::invalid_argument)));
    }
    {
        // Parse success up to comma
        const char* s6 = "8, (8)";
        EXPECT_TRUE(check_from_chars(s6,
                                     std::optional<uint32_t>(8),
                                     make_result(s6 + 1)));
    }
    {
        // Parsing negative values. When successful, the from_chars() function
        // should advance the pointer to the A after the valid digits.
        const char* s7 = "-789ABCDEFG";
        EXPECT_TRUE(check_from_chars(s7,
                                     std::optional<int16_t>(-789),
                                     make_result(s7 + 4)));
        EXPECT_TRUE(check_from_chars(s7,
                                     std::optional<int32_t>(-789),
                                     make_result(s7 + 4)));
        EXPECT_TRUE(check_from_chars(s7,
                                     std::optional<int64_t>(-789),
                                     make_result(s7 + 4)));
        // Parsing should fail for signed types
        EXPECT_TRUE(check_from_chars(s7,
                                     std::optional<uint16_t>{},
                                     make_result(s7, std::errc::invalid_argument)));
        EXPECT_TRUE(check_from_chars(s7,
                                     std::optional<uint32_t>{},
                                     make_result(s7, std::errc::invalid_argument)));
        EXPECT_TRUE(check_from_chars(s7,
                                     std::optional<uint64_t>{},
                                     make_result(s7, std::errc::invalid_argument)));
    }
    {
        // Parse success for negative zero with signed types (as gcc stdlibc++ does)
        const char* s8 = "-0";
        EXPECT_TRUE(check_from_chars(s8,
                                     std::optional<int32_t>(0),
                                     make_result(s8 + 2)));
        // Parse failure for negative zero with unsigned types (as gcc stdlibc++ does)
        EXPECT_TRUE(check_from_chars(s8,
                                     std::optional<uint32_t>{},
                                     make_result(s8, std::errc::invalid_argument)));
    }
    {
        // libstdc++ accepts leading zeros
        const char* s9 = "012";
        EXPECT_TRUE(check_from_chars(s9,
                                     std::optional<int32_t>(12),
                                     make_result(s9 + 3)));
    }
    {
        // Parse failure expected with a space after a leading negative sign
        const char* s10 = "- 45";
        EXPECT_TRUE(check_from_chars(s10,
                                     std::optional<int32_t>{},
                                     make_result(s10, std::errc::invalid_argument)));
    }
    {
        // Verify a result_out_of range code when trying to parse an integer
        // greater than INT_MAX
        std::string s11 = std::to_string(static_cast<int64_t>(std::numeric_limits<int>::max()) + 1);
        EXPECT_TRUE(check_from_chars(s11.c_str(),
                                     std::optional<int32_t>{},
                                     make_result(s11.c_str() + 10, std::errc::result_out_of_range)));
    }
    {
        std::string s12 = std::to_string(std::numeric_limits<int64_t>::max());
        s12.append("000000000000000000000000");
        EXPECT_TRUE(check_from_chars(s12.c_str(),
                                     std::optional<int8_t>{},
                                     make_result(s12.c_str() + s12.length(), std::errc::result_out_of_range)));
    }
    {
        // Parse failure expected with a leading plus (as specified for
        // from_chars() behavior).
        const char* s13 = "+34";
        EXPECT_TRUE(check_from_chars(s13,
                                     std::optional<int32_t>{},
                                     make_result(s13, std::errc::invalid_argument)));
    }
}
