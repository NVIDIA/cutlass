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

#if !defined(CUTEGEN_SWIZZLE_HPP_INCLUDED_)
#define CUTEGEN_SWIZZLE_HPP_INCLUDED_

#include <algorithm>
#include <assert.h>
#include <iosfwd>
#include <optional>
#include <string>
#include <type_traits>

#include "cutegen/cutegen.hpp"

namespace cutegen
{
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// swizzle.hpp - Public API
//
////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @brief Swizzle class.
 *
 * A swizzle operation modifies the integer "value" of a pointer or address.
 * in most current uses, the address is a shared memory address, which is
 * limited to a 32-bit value in current hardware. Therefore, we can think of
 * the swizzle operation as a function that modifies a 32-bit unsigned integer.
 *
 * The swizzle operation creates a new 32-bit value given an input 32-bit value.
 * N_MASK bits are chosen from within the input value, shifted right or left,
 * and then combined with N_MASK bits of the input value via a bitwise XOR
 * operation. The example below shows the case for N_MASK=4, NUM_SHIFT=11,
 * NUM_BASE=4.
 *
 *   INPUT:
 *   31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
 *  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
 *    x  w  v  u  t  s  r  q  p  o  n  m  l Y3 Y2 Y1 Y0  k  j  i  h  g  f  e Z3 Z2 Z1 Z0  d  c  b  a
 *                                           ^        ^                       ^        ^
 *                            Extract y bits |        |                       |        |
 *                            by bitwise and |        |      num_shift        |        |
 *                            with mask      |        |<----------------------|------->|   num_base
 *                                           |________|      (>0 here)        |________|  <-------->
 *                                               |                                |
 *                                               ----------------------------------
 *                                               shift Yi bits, xor w/input    ___|____
 *                                                                            |        | Ai = Yi ^ Zi
 *   OUTPUT:                                                                  v        v
 *   31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
 *  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
 *    x  w  v  u  t  s  r  q  p  o  n  m  l Y3 Y2 Y1 Y0  k  j  i  h  g  f  e A3 A2 A1 A1  d  c  b  a
 *
 * When num_shift is positive, Y values are shifted to the right. When num_shift
 *  negative, Y values are shifted to the left.
 *
 * Note that only N_MASK bits are modified.
 * - When num_shift > 0, N_MASK bits are modified starting at the bit with index num_base.
 * - When num_shift < 0, N_MASK bits are modified starting at the bit with index (num_base + num_shift).
 *
 * The swizzle operation is characterized by by 3 integer values:
 *
 * - @p num_bits: the number of bits (i.e. width) of the bit mask (N_MASK above)
 * - @p num_base: the number of least significant bits that will remain constant
 * - @p num_shift: the number of bits to shift, which can be positive or negative
 *
 * Applying a swizzle to an integer performs the following operations:
 *
 * 1. perform a bitwise-and operation on the input with an internal mask Y (calculated as detailed
 *    below)
 * 2. shift the result of step 1 to the right num_shift places (for num_shift >= 0) or to the left
 *    num_shift places (for num_shift < 0)
 * 3. perform a bitwise-xor operation between the input and the result of step 2
 *
 * The bitmask `Y` referenced above is calculated as follows. Consider a 3-bit wide mask (`num_bits
 * = 3`) `0b111`.
 *
 * 1. With `num_base = 4`, `num_shift = 10`
 *    ```
 *    Y = (mask << (num_base + num_shift))
 *    0bxxxxxxxxxxxxxxxYYYxxxxxxxxxxxxxx
 *                                 | 4 |
 *                       |   10    |
 *    ```
 *    When shifted 10 bits to the right, the mask becomes
 *    ```
 *    0bxxxxxxxxxxxxxxxxxxxxxxxxxZZZxxxx
 *    ```
 *    The shifted mask is sometimes referred to in CuTe as `Z`. The result of `apply(x)` would be `x
 *    ^ ((x & Y) >> 10)`.
 * 2. With `num_base = 4`, `num_shift = -11`
 *    ```
 *    Y = mask << num_base
 *    0bxxxxxxxxxxxxxxxxxxxxxxxxxYYYxxxx
 *                                 | 4 |
 *    ```
 *    When shifted 11 bits to the left, the mask becomes
 *    ```
 *    0bxxxxxxxxxxxxxxZZZxxxxxxxxxxxxxxx
 *                      |       15     |
 *    ```
 *    The result of `apply(x)` would be `x ^ ((x & Y) << 11)`.
 */
class swizzle
{
public:
    static constexpr int32_t bitwidth = 32;
    /**
     * @brief Default constructor returning an identity swizzle.
     *
     * CuTe C++ uses (0,4,3) for the default/identity swizzle.
     */
    swizzle();
    /**
     * @brief Constructor.
     *
     * Construct a swizzle using explicit values for the number of bits (bbits), the number of
     * constant least significant bits (mbase), and the (signed) number of bits to shift
     */
    swizzle(uint32_t bbits, uint32_t mbase, int32_t sshift);
    /**
     * @brief Constructor.
     *
     * Construct a swizzle using explicit Y- and Z-masks. These masks should have the same number of
     * set bits in each mask
     */
    swizzle(uint32_t ymask, uint32_t zmask);

    /**
     * @brief Validate the given swizzle configuration.
     *
     * Returns true if the values can be used to create a valid swizzle instance
     */
    static bool is_valid(uint32_t num_bits, uint32_t num_base, int32_t num_shift);

    /**
     * @brief Construct a swizzle object, returning nullopt if the arguments are invalid
     *
     */
    static std::optional<swizzle> get(uint32_t num_bits, uint32_t num_base, int32_t num_shift);

    /// Equality operator.
    bool operator==(const swizzle& other) const;
    /// Inequality operator.
    bool operator!=(const swizzle& other) const;
    /// operator() applying the swizzle function to the argument.
    template <class T>
    T operator()(const T& offset) const;

    /// Returns the number of bits to swizzle.
    uint32_t num_bits() const;
    /// Returns the number of bits of the base.
    uint32_t num_base() const;
    /// Returns the number of bits to shift before applying XOR (a positive shift is a right shift).
    int32_t num_shift() const;
    /// Returns the Y-mask.
    uint32_t y_mask() const;
    /// Returns the Z-mask.
    uint32_t z_mask() const;
    /// Returns the swizzle code which is OR(Y-mask, Z-mask).
    uint32_t swizzle_code() const;
    /// Returns whether the swizzle function is identity.
    [[nodiscard]] bool is_identity() const;
    /// Returns whether the swizzle function is the canonical identity (0,4,3).
    [[nodiscard]] bool is_canonical_identity() const;
    /// Returns a tuple of values that can be used for hashing
    std::tuple<uint32_t, uint32_t, int32_t> get_hash_tuple() const;

private:
    static constexpr uint32_t canon_num_bits  = 0;
    static constexpr uint32_t canon_num_base  = 4;
    static constexpr int32_t  canon_num_shift = 3;

    uint32_t num_bits_;
    uint32_t num_base_;
    int32_t  num_shift_;
};

/**
 * @brief Output stream insertion.
 *
 * Format: `S<num_bits,num_base,num_shift>`.
 */
inline std::ostream& operator<<(std::ostream& os, const swizzle& sw);

/**
 * @brief Make granularity of swizzle smaller by multiplying a swizzle base by N.
 *
 * @param N         multiplier, must be power of 2
 * @param sw        Input swizzle
 * @return auto     Output swizzle
 */
inline swizzle downcast(static_int_t N, const swizzle& sw);

/**
 * @brief Make granularity of swizzle larger by dividing a swizzle base by N.
 *
 * @param N         divisor, must be a power of 2 and less than swizzle base
 * @param sw        Input swizzle
 * @return auto     Output swizzle
 */
inline swizzle upcast(static_int_t N, const swizzle& sw);

inline static bool is_valid(const swizzle& sw);

inline int max_alignment(const swizzle& sw);

template <class TRange>
bool check_get_indices(const swizzle& s, const TRange& r);

template <class TRange, std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
swizzle get(const swizzle& rv, const TRange& range);

template <class TRange, std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
swizzle select(const swizzle& rv, const TRange& range);

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// swizzle.hpp - Implementation and internals
//
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail
{
// Default implementation of the swizzle applicator. The type of the offset
// argument must support:
// - scalar_bitwise_and() with an integer value
// - scalar_lshr() (logical shift right, with signed shift)
// - scalar_bitwise_xor()
// Specialization can be used to modify behavior for other types.
template <class T, class TEnable = void>
struct swizzle_applicator
{
    static T apply(const swizzle& sw, const T& offset)
    {
        return scalar_bitwise_xor<T>(offset,
                                     scalar_lshr<T>(scalar_bitwise_and<T>(offset, sw.y_mask()),
                                                    sw.num_shift()));
    };
};

/// Specialization of value_to_string for swizzle.
template <>
struct value_to_string<swizzle>
{
    static std::string to_str(const swizzle& sw)
    {
        std::string ret{"S<"};
        ret += to_string(sw.num_bits()) + ",";
        ret += to_string(sw.num_base()) + ",";
        ret += to_string(sw.num_shift()) + ">";
        return ret;
    }
};

/// Specialization of detail::cg_from_chars for swizzle
template <>
class cg_from_chars<swizzle> : public cg_from_chars_base<swizzle>
{
public:
    cg_from_chars(const char* first, const char* last, bool must_consume_all) :
        cg_from_chars_base(first, last, must_consume_all)
    {
        auto S = parse_type<char_token<'S'>>();
        if(!S.has_value())
        {
            return;
        }
        auto lt = parse_type<token_lt>();
        if(!lt.has_value())
        {
            return;
        }
        auto nBits = parse_type<uint32_t>();
        if(!nBits.has_value())
        {
            return;
        }
        auto comma0 = parse_type<token_comma>();
        if(!comma0.has_value())
        {
            return;
        }
        auto nBase = parse_type<uint32_t>();
        if(!nBase.has_value())
        {
            return;
        }
        auto comma1 = parse_type<token_comma>();
        if(!comma1.has_value())
        {
            return;
        }
        auto nShift = parse_type<int32_t>();
        if(!nShift.has_value())
        {
            return;
        }
        auto gt = parse_type<token_gt>();
        if(!gt.has_value())
        {
            return;
        }
        skip_whitespace();
        // Fail without creating an instance if parsed values are invalid.
        if(!swizzle::is_valid(nBits.value(),
                              nBase.value(),
                              nShift.value()))
        {
            return;
        }
        set_value_with_check(swizzle(nBits.value(), nBase.value(), nShift.value()));
    }
};

/// Specialization of value_encoder for swizzle
template <>
struct value_encoder<swizzle>
{
    template <class TBuffer>
    static void encode_value(const swizzle& sw, TBuffer& buffer)
    {
        encode(buffer, sw.num_bits());
        encode(buffer, sw.num_base());
        encode(buffer, sw.num_shift());
    }
};

/// Specialization of value_decoder for swizzle
template <>
struct value_decoder<swizzle>
{
    template <class TIterator>
    static std::optional<swizzle> decode_value(TIterator& it, const TIterator& end)
    {
        auto opt_num_bits = decode<uint32_t>(it, end);
        if(!opt_num_bits.has_value()) return {};
        auto opt_num_base = decode<uint32_t>(it, end);
        if(!opt_num_base.has_value()) return {};
        auto opt_num_shift = decode<int32_t>(it, end);
        if(!opt_num_shift.has_value()) return {};
        // Validate num_bits/num_base/num_shift values
        if(!swizzle::is_valid(opt_num_bits.value(),
                              opt_num_base.value(),
                              opt_num_shift.value()))
        {
            return {};
        }
        return swizzle(opt_num_bits.value(), opt_num_base.value(), opt_num_shift.value());
    }
};
} // namespace detail

inline swizzle::swizzle() :
    swizzle(canon_num_bits, canon_num_base, canon_num_shift) {}

inline swizzle::swizzle(uint32_t bbits, uint32_t mbase, int32_t sshift) :
    num_bits_(bbits),
    num_base_(mbase),
    num_shift_(sshift)
{
    assert(is_valid(num_bits_, num_base_, num_shift_) &&
           "swizzle parameters are invalid");
}

inline swizzle::swizzle(uint32_t ymask, uint32_t zmask)
{
    const int32_t  BZ   = detail::popcount(zmask);
    const int32_t  TZ_Y = (0 == ymask) ? 0 : detail::ctz(ymask);
    const int32_t  TZ_Z = (0 == zmask) ? 0 : detail::ctz(zmask);
    const uint32_t M    = std::min(TZ_Y, TZ_Z) % 32;
    const int32_t  S    = TZ_Y - TZ_Z;
#ifndef NDEBUG
    const int32_t BY = detail::popcount(ymask);
    assert((BY == BZ) && "Y and Z popcount values differ");
#endif
    num_bits_  = BZ;
    num_base_  = M;
    num_shift_ = S;
    assert(is_valid(num_bits_, num_base_, num_shift_) &&
           "swizzle constructed from invalid masks");
}

inline std::optional<swizzle> swizzle::get(uint32_t num_bits,
                                           uint32_t num_base,
                                           int32_t  num_shift)
{
    if(!is_valid(num_bits, num_base, num_shift))
    {
        return std::nullopt;
    }
    return swizzle(num_bits, num_base, num_shift);
}

inline bool swizzle::is_valid(uint32_t num_bits, uint32_t num_base, int32_t num_shift)
{
    // The shift amount must be greater than or equal to the number of mask bits.
    // The sum of the base, shift, and mask bit widths must be less than or
    // equal to the swizzle bitwidth.
    return (((std::abs(num_shift) + num_bits + num_base) <= swizzle::bitwidth) &&
            (static_cast<uint32_t>(std::abs(num_shift)) >= num_bits));
}

inline bool swizzle::operator==(const swizzle& other) const
{
    return (num_bits() == other.num_bits()) &&
           (num_base() == other.num_base()) &&
           (num_shift() == other.num_shift());
}

inline bool swizzle::operator!=(const swizzle& other) const
{
    return !(*this == other);
}

template <class T>
inline T swizzle::operator()(const T& offset) const
{
    return detail::swizzle_applicator<T>::apply(*this, offset);
}

inline uint32_t swizzle::num_bits() const { return num_bits_; }

inline uint32_t swizzle::num_base() const { return num_base_; }

inline int32_t swizzle::num_shift() const { return num_shift_; }

inline uint32_t swizzle::y_mask() const
{
    uint32_t mask = (1 << num_bits_) - 1;
    return mask << (num_base_ + std::max(0, num_shift_));
}

inline uint32_t swizzle::z_mask() const
{
    uint32_t mask = (1 << num_bits_) - 1;
    return mask << (num_base_ - std::min(0, num_shift_));
}

inline uint32_t swizzle::swizzle_code() const
{
    return (y_mask() | z_mask());
}

[[nodiscard]] inline bool swizzle::is_identity() const
{
    return num_bits_ == 0;
}

[[nodiscard]] inline bool swizzle::is_canonical_identity() const
{
    return (num_bits_ == canon_num_bits) &&
           (num_base_ == canon_num_base) &&
           (num_shift_ == canon_num_shift);
}

inline std::tuple<uint32_t, uint32_t, int32_t> swizzle::get_hash_tuple() const
{
    return std::make_tuple(num_bits_, num_base_, num_shift_);
}

inline static bool is_valid(const swizzle& sw)
{
    return swizzle::is_valid(sw.num_bits(), sw.num_base(), sw.num_shift());
}

inline int max_alignment(const swizzle& sw)
{
    return 1 << sw.num_base();
}

inline swizzle downcast(static_int_t N, const swizzle& sw)
{
    assert(is_pow_2(N) && "cannot recast swizzle by value that isn't a power of 2");
    using uint_t = std::make_unsigned_t<static_int_t>;
    return swizzle(sw.num_bits(),
                   sw.num_base() + detail::ctz(static_cast<uint_t>(N)),
                   sw.num_shift());
}

inline swizzle upcast(static_int_t N, const swizzle& sw)
{
    assert(is_pow_2(N) && "cannot recast swizzle by value that isn't a power of 2");
    using uint_t        = std::make_unsigned_t<static_int_t>;
    unsigned int log2_N = detail::ctz(static_cast<uint_t>(N));
    assert(log2_N <= sw.num_base() && "cannot upcast by a value larger than swizzle base");
    return swizzle(sw.num_bits(), sw.num_base() - log2_N, sw.num_shift());
}

template <class TRange>
bool check_get_indices(const swizzle& s, const TRange& r)
{
    return false;
}

template <class TRange,
          std::enable_if_t<!std::is_integral_v<TRange>, bool>>
swizzle get(const swizzle& rv, const TRange& range)
{
    // This should never happen and is an artifact due to SwizzleType implementing
    // ValueTypeInterface
    assert(false && "Calling get on a swizzle doesn't make sense!");
    return {};
}

template <class TRange,
          std::enable_if_t<!std::is_integral_v<TRange>, bool>>
swizzle select(const swizzle& rv, const TRange& range)
{
    // This should never happen and is an artifact due to SwizzleType implementing
    // ValueTypeInterface
    assert(false && "Calling select on a swizzle doesn't make sense!");
    return {};
}

inline std::ostream& operator<<(std::ostream& os, const swizzle& sw)
{
    os << to_string(sw);
    return os;
}
} // namespace cutegen
#endif
