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

#if !defined(CUTEGEN_CHARCONV_HPP_DEFINED_)
#define CUTEGEN_CHARCONV_HPP_DEFINED_

// This file intends to provide string parsing support to cutegen when the
// C++ standard library used for compilation does not support it.
//
// Specifically, the cutegen string parsing functions use structures and
// functions provided in the C++17 <charconv> header. Support for this
// header was added to GCC v8.1:
//
// https://gcc.gnu.org/onlinedocs/libstdc++/manual/status.html#status.iso.2017
//
// Note that cutegen currently only uses the std::from_chars() function
// for parsing integers. (Floating point support was not added to GCC until
// v11.1, but cutegen does not use any floating point functionality from
// <charconv>.)
//
// C++ defines a feature test macro, __cpp_lib_to_chars, which can be used
// to determine compiler support. However, this macro seems to also refer
// to floating support. In order to use the standard library functionality
// for integers when it exists, we instead are using the __has_include
// preprocessor feature to check for <charconv>.
//
// https://gcc.gnu.org/bugzilla/show_bug.cgi?id=100146
#if __has_include(<charconv>)

#include <charconv>

namespace cutegen
{
namespace detail
{

// Use the C++ standard library definition of the from_chars_result structure.
using std::from_chars_result;
// Use the C++ standard library definition of the from_chars() function.
using std::from_chars;

} // namespace detail
} // namespace cutegen
#else

#include <algorithm>
#include <cinttypes>
#include <system_error>

#if defined(_WIN32)
#include <intsafe.h>
#endif

namespace cutegen
{
namespace detail
{

struct from_chars_result
{
    const char* ptr;
    std::errc   ec;
};

#if defined(_WIN32)
inline bool mul_overflow(uint64_t a, uint64_t b, uint64_t* presult)
{
    return FAILED(UlongLongMult(a, b, presult));
}
inline bool add_overflow(uint64_t a, uint64_t b, uint64_t* presult)
{
    return FAILED(UlongLongAdd(a, b, presult));
}
#else  // defined(_WIN32)
inline bool mul_overflow(uint64_t a, uint64_t b, uint64_t* presult)
{
    return __builtin_mul_overflow(a, b, presult);
}
inline bool add_overflow(uint64_t a, uint64_t b, uint64_t* presult)
{
    return __builtin_add_overflow(a, b, presult);
}
#endif // defined(_WIN32)

template <typename T,
          std::enable_if_t<std::is_integral<T>::value, bool> = true>
from_chars_result from_chars(const char* first,
                             const char* last,
                             T&          value)
// Note: The internal implementation of from_chars does not currently support
// specifying the base of the string. cutegen currently only uses base 10 for
// integer parsing. A complete implementation of from_chars() would need to
// uncomment the line below and provide an implementation for other bases.
//                             int         base = 10)
{
    from_chars_result fcr{first, std::errc::invalid_argument};
    //--------------------------------------------------------------------------
    // Check for an empty/invalid first/last range
    if(!first || (last <= first))
    {
        return fcr;
    }
    //--------------------------------------------------------------------------
    // from_chars():
    // - does not ignore leading whitespace
    // - does not accept a '+' at the beginning of an integer
    // - only accepts a leading '-' for signed values
    if(isspace(*first) ||
       (!std::is_signed_v<T> && (*first == '-')) ||
       (*first == '+'))
    {
        return fcr;
    }
    //--------------------------------------------------------------------------
    // Check for a negative sign for signed types.
    bool bNeg = false;
    auto cur  = first;
    if(std::is_signed_v<T> && (*first == '-'))
    {
        bNeg = true;
        if(!std::isdigit(static_cast<int>(*(++cur))))
        {
            return fcr;
        }
    }
    //--------------------------------------------------------------------------
    // Return if the first character (after a possible '-') is not a digit.
    if(!std::isdigit(static_cast<int>(*cur)))
    {
        return fcr;
    }
    //--------------------------------------------------------------------------
    // Parse the integer value as a non-negative value (i.e. ignoring the
    // negative sign if there was one).
    uint64_t val       = 0;
    bool     bOverflow = false;
    while((cur < last) && std::isdigit(static_cast<int>(*cur)))
    {
        // Check for overflow, but continue to consume characters (as
        // from_chars() does...).
        bOverflow |= mul_overflow(val, static_cast<uint64_t>(10), &val);
        bOverflow |= add_overflow(val, static_cast<uint64_t>((*cur) - '0'), &val);
        ++cur;
    }
    fcr.ptr = cur;
    //--------------------------------------------------------------------------
    // If overflow of the accumulator type occurred, return with out_of_range.
    if(bOverflow)
    {
        fcr.ec = std::errc::result_out_of_range;
        return fcr;
    }
    //--------------------------------------------------------------------------
    // Check the parsed uint64_t value against limits of the destination type.
    if(std::is_signed_v<T> && bNeg)
    {
        // Check if the negated value can be represented.
        if(val > std::llabs(std::numeric_limits<T>::min()))
        {
            fcr.ec = std::errc::result_out_of_range;
            return fcr;
        }
        else
        {
            // Success!
            value  = -val;
            fcr.ec = std::errc{};
            return fcr;
        }
    }
    else
    {
        if(val <= std::numeric_limits<T>::max())
        {
            // Success!
            value  = static_cast<T>(val);
            fcr.ec = std::errc{};
            return fcr;
        }
        else
        {
            // Out of range (positive value)
            fcr.ec = std::errc::result_out_of_range;
            return fcr;
        }
    }
}

} // namespace detail
} // namespace cutegen
#endif

#endif // !defined(CUTEGEN_CHARCONV_HPP_DEFINED_)
