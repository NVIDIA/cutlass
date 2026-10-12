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

#if !defined(CUTEGEN_RATIO_HPP_INCLUDED_)
#define CUTEGEN_RATIO_HPP_INCLUDED_

#include <iosfwd>
#include <numeric>
#include <optional>
#include <string>
#include <type_traits>

#include "cutegen/cutegen.hpp"
#include "cutegen/cg_int.hpp"

namespace cutegen
{
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// ratio.hpp - Public API
//
////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @brief Ratio class.
 *
 * A class to represent the ratio of two signed integers, represented by the
 * numerator and the denominator.
 *
 * Note that equality compares the numerator and the denominator directly,
 * as is done by CuTe C++. This means that 2 / 4 and 1 / 2 are NOT EQUAL.
 * The reduced() function returns a variant that holds either:
 * - an integer value (if gcd(num, denom) == denom)
 * - a reduced/simplified ratio (e.g. ratio(2,4).reduced() == ratio(1,2))
 */
class ratio
{
public:
    using int_t     = static_int_t;
    using reduced_t = std::variant<static_int_t, ratio>;

private:
    int_t num_;
    int_t denom_;

public:
    /// Constructor.
    ratio(int_t n, int_t d);
    /// Equality operator.
    bool operator==(const ratio&) const;
    /// Inequality operator.
    bool operator!=(const ratio&) const;

public:
    /// Gets the numerator.
    int_t num() const;
    /// Gets the denominator.
    int_t denom() const;
    /// Gets the reduced from of the ratio, possibly simplifying it to an integer.
    reduced_t reduced() const;
    /// Whether the ratio can be simplified to an integer.
    bool is_integral() const;

private:
    /// Returns `1` if `x > 0`, `-1` if `x < 0`, and `0` otherwise.
    static int_t signum(int_t x);
};

/// Output stream insertion.
inline std::ostream& operator<<(std::ostream& os, const ratio& r);

template <class TRet>
TRet scalar_add(const ratio& lhs, const ratio& rhs);
template <class TRet,
          class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_add(TInt lhs, const ratio& rhs);
template <class TRet,
          class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_add(const ratio& lhs, TInt rhs);

template <class TRet>
TRet scalar_sub(const ratio& lhs, const ratio& rhs);
template <class TRet,
          class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_sub(TInt lhs, const ratio& rhs);
template <class TRet,
          class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_sub(const ratio& lhs, TInt rhs);

template <class TRet>
TRet scalar_mul(const ratio& lhs, const ratio& rhs);
template <class TRet,
          class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_mul(TInt lhs, const ratio& rhs);
template <class TRet,
          class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_mul(const ratio& lhs, TInt rhs);

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// ratio.hpp - Implementation and internals
//
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail
{
/// Specialization of value_to_string for ratio.
template <>
struct value_to_string<ratio>
{
    static std::string to_str(const ratio& r)
    {
        std::string ret(to_string(r.num()));
        ret += "/";
        ret += to_string(r.denom());
        return ret;
    }
};

/// Specialization of detail::cg_from_chars for ratio
template <>
class cg_from_chars<ratio> : public cg_from_chars_base<ratio>
{
public:
    cg_from_chars(const char* first, const char* last, bool must_consume_all) :
        cg_from_chars_base(first, last, must_consume_all)
    {
        auto num = parse_type<ratio::int_t>();
        if(!num.has_value())
        {
            return;
        }
        auto slash = parse_type<token_fwd_slash>();
        if(!slash.has_value())
        {
            return;
        }
        auto denom = parse_type<ratio::int_t>();
        if(!denom.has_value() || (0 == denom.value()))
        {
            return;
        }
        skip_whitespace();
        set_value_with_check(ratio(num.value(), denom.value()));
    }
};

/// Specialization of value_encoder for ratio
template <>
struct value_encoder<ratio>
{
    template <class TBuffer>
    static void encode_value(const ratio& r, TBuffer& buffer)
    {
        encode(buffer, r.num());
        encode(buffer, r.denom());
    }
};

/// Specialization of value_decoder for ratio
template <>
struct value_decoder<ratio>
{
    template <class TIterator>
    static std::optional<ratio> decode_value(TIterator& it, const TIterator& end)
    {
        auto opt_num = decode<ratio::int_t>(it, end);
        if(!opt_num.has_value()) return std::nullopt;
        auto opt_denom = decode<ratio::int_t>(it, end);
        if(!opt_denom.has_value() || (0 == opt_denom.value())) return std::nullopt;
        return ratio(opt_num.value(), opt_denom.value());
    }
};
} // namespace detail

inline ratio::ratio(int_t n, int_t d) :
    num_(n), denom_(d) {}

inline ratio::int_t ratio::num() const { return num_; }

inline ratio::int_t ratio::denom() const { return denom_; }

inline ratio::reduced_t ratio::reduced() const
{
    // Reducing a ratio forces 0/X, X/0, and 0/0 to integer 0 with the
    // current implementation.
    int_t g = std::gcd(std::abs(num_), std::abs(denom_));
    if(0 == g)
    {
        // This should only occur if both are zero. We will arbitrarily
        // force an integer 0 = 0/0 here.
        return reduced_t(0);
    }
    int_t num   = signum(num_) * signum(denom_) * std::abs(num_) / g;
    int_t denom = std::abs(denom_) / g;
    if((0 == num) || (1 == denom))
    {
        return reduced_t(num);
    }
    else
    {
        assert(0 != denom);
        return reduced_t(ratio(num, denom));
    }
}

inline bool ratio::is_integral() const
{
    return std::holds_alternative<int_t>(reduced());
}

inline ratio::int_t ratio::signum(int_t x)
{
    return ((0 < x) - (x < 0));
}

inline bool ratio::operator==(const ratio& other) const
{
    return (num() == other.num()) && (denom() == other.denom());
}

inline bool ratio::operator!=(const ratio& other) const
{
    return !(*this == other);
}

template <class TRet>
TRet scalar_add(const ratio& lhs, const ratio& rhs)
{
    auto m   = std::lcm(lhs.denom(), rhs.denom());
    auto num = (lhs.num() * (m / lhs.denom())) + (rhs.num() * (m / rhs.denom()));
    if(0 == num)
    {
        return 0;
    }
    auto r = ratio(num, m).reduced();
    if(std::holds_alternative<static_int_t>(r))
    {
        return std::get<static_int_t>(r);
    }
    return std::get<ratio>(r);
}

template <class TRet,
          class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_add(TInt lhs, const ratio& rhs)
{
    if(0 == rhs.num())
    {
        return lhs;
    }
    auto r = ratio(rhs.num() + (lhs * rhs.denom()), rhs.denom()).reduced();
    if(std::holds_alternative<static_int_t>(r))
    {
        return std::get<static_int_t>(r);
    }
    return std::get<ratio>(r);
}
template <class TRet,
          class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_add(const ratio& lhs, TInt rhs)
{
    // addition is symmetric - swap order and use above function
    return scalar_add<TRet>(rhs, lhs);
}

template <class TRet>
TRet scalar_sub(const ratio& lhs, const ratio& rhs)
{
    auto m   = std::lcm(lhs.denom(), rhs.denom());
    auto num = (lhs.num() * (m / lhs.denom())) - (rhs.num() * (m / rhs.denom()));
    if(0 == num)
    {
        return 0;
    }
    auto r = ratio(num, m).reduced();
    if(std::holds_alternative<static_int_t>(r))
    {
        return std::get<static_int_t>(r);
    }
    return std::get<ratio>(r);
}
template <class TRet,
          class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_sub(TInt lhs, const ratio& rhs)
{
    if(0 == rhs.num())
    {
        return lhs;
    }
    auto r = ratio((lhs * rhs.denom()) - rhs.num(), rhs.denom()).reduced();
    if(std::holds_alternative<static_int_t>(r))
    {
        return std::get<static_int_t>(r);
    }
    return std::get<ratio>(r);
}

template <class TRet,
          class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_sub(const ratio& lhs, TInt rhs)
{
    if(0 == lhs.num())
    {
        return -rhs;
    }
    auto r = ratio(lhs.num() - (rhs * lhs.denom()), lhs.denom()).reduced();
    if(std::holds_alternative<static_int_t>(r))
    {
        return std::get<static_int_t>(r);
    }
    return std::get<ratio>(r);
}

template <class TRet>
TRet scalar_mul(const ratio& lhs, const ratio& rhs)
{
    if((0 == lhs.num()) || (0 == rhs.num()))
    {
        return 0;
    }
    auto r = ratio(lhs.num() * rhs.num(), lhs.denom() * rhs.denom()).reduced();
    if(std::holds_alternative<static_int_t>(r))
    {
        return std::get<static_int_t>(r);
    }
    return std::get<ratio>(r);
}
template <class TRet,
          class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_mul(const ratio& lhs, TInt rhs)
{
    if((0 == lhs.num()) || (0 == rhs))
    {
        return 0;
    }
    auto r = ratio(lhs.num() * rhs, lhs.denom()).reduced();
    if(std::holds_alternative<static_int_t>(r))
    {
        return std::get<static_int_t>(r);
    }
    return std::get<ratio>(r);
}
template <class TRet,
          class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_mul(TInt lhs, const ratio& rhs)
{
    return scalar_mul<TRet>(rhs, lhs);
}

inline std::ostream& operator<<(std::ostream& os, const ratio& r)
{
    os << detail::value_to_string<ratio>::to_str(r);
    return os;
}
} // namespace cutegen
#endif
