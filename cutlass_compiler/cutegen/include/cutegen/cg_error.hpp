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

/**
 * @file
 */

#if !defined(CUTEGEN_CG_ERROR_HPP_INCLUDED_)
#define CUTEGEN_CG_ERROR_HPP_INCLUDED_

#include <iosfwd>
#include <optional>
#include <string>
#include <system_error>

#include "cutegen/cutegen.hpp"
#include "cutegen/charconv.hpp"

namespace cutegen
{
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// cg_error.hpp - Public API
//
////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @brief Struct for signaling a user error.
 *
 * An instance of `cg_error_t` is returned in case of a user error. This type is added as a valid
 * element type to the recursive variant types we define for implementing CuTe. Any recursive
 * variant that has a cg_error_t element is considered invalid. The struct name is prefix with `cg_`
 * such that it doesn't collide with `error_t` defined by the GNU compiler suite (for example).
 */
struct cg_error_t
{
public:
    /// Equality operator.
    bool operator==(const cg_error_t& /*b*/) const;
    /// Inequality operator.
    bool operator!=(const cg_error_t& /*b*/) const;
    // Uncomment to find location of error creation in a debugger backtrace.
    //cg_error_t() { assert(false); }
};

/// Output stream insertion.
inline std::ostream& operator<<(std::ostream& os, const cg_error_t& e);

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// cg_error.hpp - Implementation and internals
//
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail
{
/// Specialization of value_to_string for cg_error_t.
template <>
struct value_to_string<cg_error_t>
{
    static std::string to_str(const cg_error_t& t)
    {
        return std::string("x");
    }
};

/// Specialization of detail::cg_from_chars<> for cg_error_t.
template <>
class cg_from_chars<cg_error_t>
{
public:
    using optional_t = std::optional<cg_error_t>;
    cg_from_chars(const char* first, const char* last, bool must_consume_all)
    {
        auto curr = detail::find_non_whitespace(first, last);
        if(curr && (*curr == 'x'))
        {
            auto next = detail::find_non_whitespace(curr + 1, last);
            // Error if we need to consume all AND the next non-whitespace
            // character is not the end.
            result_ = from_chars_result{next,
                                        (must_consume_all && (next != last)) ?
                                            std::errc::invalid_argument :
                                            std::errc{}};
            if(result_.ec == std::errc{})
                // Success - assign to the optional value
                value_ = cg_error_t{};
        }
        else
        {
            result_ = from_chars_result{first, std::errc::invalid_argument};
        }
    }
    const optional_t&        parse_value() { return value_; }
    const from_chars_result& parse_result() { return result_; }

private:
    from_chars_result result_;
    optional_t        value_;
};
} // namespace detail

inline bool cg_error_t::operator==(const cg_error_t&) const { return true; }

inline bool cg_error_t::operator!=(const cg_error_t&) const { return false; }

inline std::ostream& operator<<(std::ostream& os, const cg_error_t& e)
{
    os << to_string(e);
    return os;
}

// encode/decode:
// cg_error_t uses the specialization of value_encoder and value_decoder for empty types
} // namespace cutegen
#endif
