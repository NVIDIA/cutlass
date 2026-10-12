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

#if !defined(CG_INT_HPP_INCLUDED_)
#define CG_INT_HPP_INCLUDED_

#include <climits>

#include "cutegen/cutegen.hpp"
#include "cutegen/cg_error.hpp"

#if defined(_WIN32)
#include <intrin.h>
#endif

namespace cutegen
{

/// Typedef for the default static integer type.
using static_int_t = int64_t;

/// Returns the bitwidth of the default static integer type.
constexpr unsigned int static_int_bitwidth();

/// Casts the given value to the static_int_t type. Slightly shorter than the
/// equivalent static_cast<static_int_t>(value), and asserts that the value
/// is in_range() in assert-enabled builds.
template <class T, std::enable_if_t<std::is_integral_v<T>, bool> = true>
static_int_t static_int_cast(T value);

//
// Integer utilities
//

/// Type alias to represent the minimum and maximum values that an integer can
/// hold. Both values are inclusive: the integer in question can be equal to
/// the first (minimum) value or the second (maximum) value. In other words,
/// the range is given by [first, second]. Note that this is different than
/// half open intervals like [first, second) commonly used by iterators.
using int_range_t = std::pair<static_int_t, static_int_t>;

/**
 * @brief Returns true if type R can represent values in range r
 */
template <class R>
constexpr bool in_range(int_range_t r) noexcept;

/**
 * @brief Returns true if the value `t` can be represented by type `R`
 *
 * (Backport of C++-20's `in_range`.)
 */
template <class R, class T>
constexpr bool in_range(T t) noexcept;

/**
 * @brief Returns true if the `value` is in the range of a signed integer
 *        value of the given `width`.
 *
 * Returns false if the width is less than 1 or greater than 64.
 */
bool in_range_of_width(int64_t value, int32_t width) noexcept;

/**
 * @brief Computes the ceiling of the division of `a` by `b`
 *
 * The return type should be capable of holding an integer result
 * or an instance of cg_error_t, in case of error.
 *
 * An instance of cg_error_t is returned if:
 * - the divisor is 0
 * - overflow occurs (e.g. ceil_div(INT_MIN, -1))
 */
template <class TReturn,
          class TA,
          class TB,
          std::enable_if_t<std::is_integral_v<TA>, bool> = true,
          std::enable_if_t<std::is_integral_v<TB>, bool> = true>
TReturn scalar_ceil_div(TA a, TB b);

/**
 * @brief Computes the ceiling of the division of `a` by `b`
 *
 * Note that this function does not guard against overflow or division by zero.
 */
template <class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
T ceil_div(const T& a, const T& b);

/**
 * @brief Computes the logical right shift of `value` by `sh` bits.
 *
 * This function performs logical right shift (i.e. without sign preservation
 * for negative values). If `sh` is negative, the value is shifted to the left
 * by `abs(sh)` bits.
 * We choose to implement logical shift because the primary use of shift
 * operations in cutegen is for swizzling, which operates on unsigned values.
 */
template <class TReturn,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TReturn scalar_lshr(T value, int32_t sh);

/**
 * @brief Computes the left shift of `value` by `sh` bits.
 *
 * If `sh` is negative, a logical right shift of `abs(sh)` bits is performed.
 */
template <class TReturn,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TReturn scalar_shl(T value, int32_t sh);

/**
 * @brief Returns the unsigned absolute value of the (possibly signed) argument.
 *
 * Since the returned type is an unsigned value, this function avoids overflow
 * if `val` == std::numeric_limits<T>::min().
 */
template <class T>
std::make_unsigned_t<T> safe_abs(T val);

/**
 * @brief Returns true if the given value is a positive power of 2.
 *
 * Note: this function returns false if `val` is zero.
 */
template <class T>
bool is_pow_2(T val);

//
// Bitwise ops
//   The purpose of these structs is to extend for example std::bit_and to our custom dynamic types.
//

/**
 * @brief Perform a bitwise and operation on the input arguments.
 *
 * The return type `TRet` must be capable of representing the result of a
 * bitwise and operation of the input. Examples are an integer type or a variant
 * type that can hold an integer.
 */
template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool> = true,
          std::enable_if_t<std::is_integral_v<TRHS>, bool> = true>
TRet scalar_bitwise_and(TLHS lhs, TRHS rhs);

/**
 * @brief Perform a bitwise or operation on the input arguments.
 *
 * The return type `TRet` must be capable of representing the result of a
 * bitwise or operation of the input. Examples are an integer type or a variant
 * type that can hold an integer.
 */
template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool> = true,
          std::enable_if_t<std::is_integral_v<TRHS>, bool> = true>
TRet scalar_bitwise_or(TLHS lhs, TRHS rhs);

/**
 * @brief Perform a bitwise xor operation on the input arguments.
 *
 * The return type `TRet` must be capable of representing the result of a
 * bitwise xor operation of the input. Examples are an integer type or a variant
 * type that can hold an integer.
 */
template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool> = true,
          std::enable_if_t<std::is_integral_v<TRHS>, bool> = true>
TRet scalar_bitwise_xor(TLHS lhs, TRHS rhs);

/**
 * @brief Perform a bitwise not operation on the input argument.
 *
 * The return type `TRet` must be capable of representing the result of a
 * bitwise not operation of the input. Examples are an integer type or a variant
 * type that can hold an integer.
 */
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_not(T value);

/**
 * @brief Divides lhs by rhs, returning `cg_error_t` if rhs is zero.
 *
 * The return type `TRet` must be constructible with either:
 * - an integer result of the division
 * - an instance of `cg_error_t`
 */
template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool> = true,
          std::enable_if_t<std::is_integral_v<TRHS>, bool> = true>
TRet scalar_div(TLHS lhs, TRHS rhs);

/**
 * @brief Returns lhs % rhs, or `cg_error_t` if rhs is zero.
 *
 * The return type `TRet` must be constructible with either:
 * - an integer result of the modulo operation
 * - an instance of `cg_error_t`
 */
template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool> = true,
          std::enable_if_t<std::is_integral_v<TRHS>, bool> = true>
TRet scalar_mod(TLHS lhs, TRHS rhs);

/**
 * @brief Returns the minimum of two integer values.
 *
 * The return type `TRet` must be constructible with the integer result of the
 * min() function.
 */
template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool> = true,
          std::enable_if_t<std::is_integral_v<TRHS>, bool> = true>
TRet scalar_min(TLHS lhs, TRHS rhs);

/**
 * @brief Returns the maximum of two integer values.
 *
 * The return type `TRet` must be constructible with the integer result of the
 * max() function.
 */
template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool> = true,
          std::enable_if_t<std::is_integral_v<TRHS>, bool> = true>
TRet scalar_max(TLHS lhs, TRHS rhs);

/// Enum for binary comparison operator kinds.
enum class comp_pred
{
    eq,
    ne,
    lt,
    gt,
};

/// Struct to be specialized for binary comparisons.
template <class T, comp_pred predicate, class TEnable = void>
struct compare;

/// Specialization for integers and `=`.
template <class T>
struct compare<T, comp_pred::eq, std::enable_if_t<std::is_integral_v<T>>>
{
    bool operator()(T a, T b);
};

/// Specialization for integers and `!=`.
template <class T>
struct compare<T, comp_pred::ne, std::enable_if_t<std::is_integral_v<T>>>
{
    bool operator()(T a, T b);
};

/// Specialization for integers and `<`.
template <class T>
struct compare<T, comp_pred::lt, std::enable_if_t<std::is_integral_v<T>>>
{
    bool operator()(T a, T b);
};

/// Specialization for integers and `>`.
template <class T>
struct compare<T, comp_pred::gt, std::enable_if_t<std::is_integral_v<T>>>
{
    bool operator()(T a, T b);
};

/// Conditional assignement for a boolean predicate result (static case).
template <class TFunctorThen, class TFunctorElse>
auto cond_assign(bool cond, TFunctorThen&& then_func, TFunctorElse&& else_func);

namespace detail
{

/**
 * @brief Returns the number of 1 bits in the value `x`.
 *
 * Note: can be replaced with std::popcount() in C++ 20.
 */
inline int popcount(uint32_t x)
{
#if defined(_WIN32)
#if defined(_M_ARM64)
    return _CountOneBits(x);
#else
    // defined on x86, x86_64
    return __popcnt(x);
#endif
#else
    return __builtin_popcount(x);
#endif
}

/**
 * @brief Returns the number of 1 bits in the value `x`.
 *
 * Note: can be replaced with std::popcount() in C++ 20.
 */
inline int popcount(uint64_t x)
{
#if defined(_WIN32)
#if defined(_M_ARM64)
    return _CountOneBits64(x);
#elif defined(_M_X64)
    return __popcnt64(x);
#else
    // The __popcnt64() intrinsic does not exist on 32-bit x86 platforms.
    return __popcnt(static_cast<uint32_t>(x)) + __popcnt(static_cast<uint32_t>(x >> 32));
#endif
#else
    return __builtin_popcountll(x);
#endif
}

/**
 * @brief Returns the number of trailing zeros in the value `x`.
 *
 * Note: The return value of __builtin_ctz() is undefined when `x == 0`,
 *       but the result seems to be defined for the `_tzcnt_u32()` intrinsic.
 *
 * Note: can be replaced with std::count_rzero() in C++ 20.
 */
// Count trailing zeros
inline int ctz(uint32_t x)
{
    assert(x != 0); // Can remove this with count_rzero()
#if defined(_WIN32)
#if defined(_M_ARM64)
    return _CountTrailingZeros(x);
#else
    // defined on x86, x86_64
    return _tzcnt_u32(x);
#endif
#else
    return __builtin_ctz(x);
#endif
}

/**
 * @brief Returns the number of trailing zeros in the value `x`.
 *
 * Note: The return value of __builtin_ctz() is undefined when `x == 0`,
 *       but the result seems to be defined for the `_tzcnt_u64()` intrinsic.
 *
 * Note: can be replaced with std::count_rzero() in C++ 20.
 */
inline int ctz(uint64_t x)
{
    assert(x != 0); // Can remove this with count_rzero()
#if defined(_WIN32)
#if defined(_M_ARM64)
    return _CountTrailingZeros64(x);
#elif defined(_M_X64)
    return _tzcnt_u64(x);
#else
    // The _tzcnt_u64() intrinsic does not exist on 32-bit x86 platforms.
    unsigned int lo_ctz = _tzcnt_u32(static_cast<uint32_t>(x));
    return (lo_ctz != 32) ? lo_ctz : (32 + _tzcnt_u32(static_cast<uint32_t>(x >> 32)));
#endif
#else
    return __builtin_ctzll(x);
#endif
}

/**
 * @brief Returns the number of leading zeros in the value `x`.
 *
 * Note: The return value of __builtin_clz() is undefined when `x == 0`,
 *       but the result seems to be defined for the `_lzcnt_u32()` intrinsic.
 *
 * Note: can be replaced with std::count_lzero() in C++ 20.
 */
inline int clz(uint32_t x)
{
    assert(x != 0); // Can remove this with count_lzero()
#if defined(_WIN32)
#if defined(_M_ARM64)
    return _CountLeadingZeros(x);
#else
    return _lzcnt_u32(x);
#endif
#else
    return __builtin_clz(x);
#endif
}

/**
 * @brief Returns the number of leading zeros in the value `x`.
 *
 * Note: The return value of __builtin_clzll() is undefined when `x == 0`,
 *       but the result seems to be defined for the `_lzcnt_u64()` intrinsic.
 *
 * Note: can be replaced with std::count_lzero() in C++ 20.
 */
inline int clz(uint64_t x)
{
    assert(x != 0); // Can remove this with count_lzero()
#if defined(_WIN32)
#if defined(_M_ARM64)
    return _CountLeadingZeros64(x);
#elif defined(_M_X64)
    return _lzcnt_u64(x);
#else
    // The _lzcnt_u64() intrinsic does not exist on 32-bit x86 platforms.
    unsigned int hi_clz = _lzcnt_u32(static_cast<uint32_t>(x >> 32));
    return (hi_clz != 32) ? hi_clz : (32 + _lzcnt_u32(static_cast<uint32_t>(x)));
#endif
#else
    return __builtin_clzll(x);
#endif
}

/**
 * @brief Returns the index of the most significant bit.
 *
 * Note: The result is undefined for `x == 0`, as the implementation of this
 *       function uses `clz()`, and that function is undefined for an argument
 *       of zero.
 */
template <typename T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
int log2_floor(T x)
{
    using uint_t = std::make_unsigned_t<T>;
    assert(x != 0);
    return (sizeof(T) * CHAR_BIT) - 1 - clz(static_cast<uint_t>(x));
}

/**
 * @brief Computes ceil(log2(x)) using integer arithmetic.
 *
 * This function returns l such that
 * - l >= 0
 * - 2^{l-1} < x <= 2^l
 */
template <typename T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
int log2_ceil(T x)
{
    using uint_t = std::make_unsigned_t<T>;
    assert(x >= 0);
    // Output of clz() is undefined for x == 0. For x = 0 or x = 1, we return
    // 1 from log2_ceil(), as 2^0 = 1.
    if(x <= 1)
    {
        return 0;
    }
    // See: Hacker's Delight, p. 106
    return (sizeof(T) * CHAR_BIT) - clz(static_cast<uint_t>(x - 1));
}

/**
 * @brief Compare integral values for equality
 */
template <class T,
          class U,
          std::enable_if_t<std::is_integral_v<T>, bool> = true,
          std::enable_if_t<std::is_integral_v<U>, bool> = true>
constexpr bool cmp_equal(T t, U u) noexcept
{
    if constexpr(std::is_signed_v<T> == std::is_signed_v<U>)
    {
        return t == u;
    }
    else if constexpr(std::is_signed_v<T>)
    {
        return t >= 0 && std::make_unsigned_t<T>(t) == u;
    }
    else
    {
        return u >= 0 && std::make_unsigned_t<U>(u) == t;
    }
}

/**
 * @brief Returns true if integral values are not equal
 */
template <class T, class U>
constexpr bool cmp_not_equal(T t, U u) noexcept
{
    return !cmp_equal(t, u);
}

/**
 * @brief Returns true if `t` is less than `u`
 */
template <class T, class U>
constexpr bool cmp_less(T t, U u) noexcept
{
    if constexpr(std::is_signed_v<T> == std::is_signed_v<U>)
    {
        return t < u;
    }
    else if constexpr(std::is_signed_v<T>)
    {
        return t < 0 || std::make_unsigned_t<T>(t) < u;
    }
    else
    {
        return u >= 0 && t < std::make_unsigned_t<U>(u);
    }
}

/**
 * @brief Returns true if `t` is greater than `u`
 */
template <class T, class U>
constexpr bool cmp_greater(T t, U u) noexcept
{
    return cmp_less(u, t);
}

/**
 * @brief Returns true if `t` is less than or equal to `u`
 */
template <class T, class U>
constexpr bool cmp_less_equal(T t, U u) noexcept
{
    return !cmp_less(u, t);
}

/**
 * @brief Returns true if `t` is greater than or equal to `u`
 */
template <class T, class U>
constexpr bool cmp_greater_equal(T t, U u) noexcept
{
    return !cmp_less(t, u);
}

// Specialization of the detail::from_chars class for integral types
template <typename T>
class cg_from_chars<T, std::enable_if_t<std::is_integral_v<T>>> : public cg_from_chars_base<T>
{
public:
    using optional_t = std::optional<T>;
    cg_from_chars(const char* first, const char* last, bool must_consume_all) :
        cg_from_chars_base<T>(first, last, must_consume_all)
    {
        T t;
        // Advance past initial whitespace, as the C++ standard library
        // implementation for integer types does not.
        this->skip_whitespace();
        auto res = from_chars(this->get_ptr(), last, t);
        if(res.ec == std::errc{})
        {
            // Advance the pointer
            this->set_ptr(res.ptr);
            this->skip_whitespace();
            this->set_value_with_check(t);
        }
    }
};

} // namespace detail

constexpr unsigned int static_int_bitwidth()
{
    return std::numeric_limits<static_int_t>::digits + 1;
}

template <class T, std::enable_if_t<std::is_integral_v<T>, bool>>
static_int_t static_int_cast(T value)
{
    assert(in_range<static_int_t>(value));
    return static_cast<static_int_t>(value);
}

template <class R>
constexpr bool in_range(int_range_t r) noexcept
{
    return detail::cmp_greater_equal(r.first, std::numeric_limits<R>::min()) &&
           detail::cmp_less_equal(r.second, std::numeric_limits<R>::max());
}

template <class R,
          class T>
constexpr bool in_range(T t) noexcept
{
    return detail::cmp_greater_equal(t, std::numeric_limits<R>::min()) &&
           detail::cmp_less_equal(t, std::numeric_limits<R>::max());
}

inline bool in_range_of_width(int64_t value, int32_t width) noexcept
{
    if((width < 1) || (width > 64))
        return false;
    if(width == 64)
        return true; // argument is 64 bits wide...
    int64_t one     = 1;
    int64_t max_val = (one << (width - 1)) - 1;
    int64_t min_val = -(one << (width - 1));
    return (value <= max_val) && (value >= min_val);
}

template <class TReturn,
          class TA,
          class TB,
          std::enable_if_t<std::is_integral_v<TA>, bool>,
          std::enable_if_t<std::is_integral_v<TB>, bool>>
TReturn scalar_ceil_div(TA a, TB b)
{
    using int_t = std::common_type_t<TA, TB>;
    if(0 == b)
    {
        // Return error when divisor is 0
        return cg_error_t{};
    }
    if constexpr(std::is_signed_v<int_t>)
    {
        // INT_MIN / (-1) --> overflow, as the result cannot be represented by
        // a signed value.
        if((-1 == static_cast<int_t>(b)) && (a == std::numeric_limits<int_t>::min()))
        {
            return cg_error_t{};
        }
    }
    // Instead of the more common formulation:
    // ceil_div(a, b) = (a + b - 1) / b
    // We use the form adopted by MLIR's CeilDivSIOp lowering, which allows us
    // to avoid checking for overflow in the result of a + b.
    int_t q = a / b;
    if((q * b != a) && ((a < 0) == (b < 0)))
    {
        // If q * b != a and (a,b) have the same sign, increment the quotient
        return q + 1;
    }
    return q;
}

template <class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
T ceil_div(const T& a, const T& b)
{
    return (a + b - 1) / b;
}

template <class TReturn,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TReturn scalar_lshr(T value, int32_t sh)
{
    // Follow the behavior of LLVM here: shifting a number of bits greater than
    // or equal to the number of bits in the value is an error.
    if(safe_abs(sh) >= (sizeof(T) * CHAR_BIT))
        return cg_error_t{};

    if(sh >= 0)
    {
        // Avoid sign preservation for negative values
        using uint_t = std::make_unsigned_t<T>;
        return static_cast<static_int_t>(static_cast<uint_t>(value) >> sh);
    }
    else
    {
        return static_cast<static_int_t>(value << (-sh));
    }
}

template <class TReturn,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TReturn scalar_shl(T value, int32_t sh)
{
    // Follow the behavior of LLVM here: shifting a number of bits greater than
    // or equal to the number of bits in the value is an error.
    if(safe_abs(sh) >= (sizeof(T) * CHAR_BIT))
        return cg_error_t{};

    if(sh >= 0)
    {
        return static_cast<static_int_t>(value << sh);
    }
    else
    {
        // A left shift by a negative values is treated as a logical right
        // shift. Avoid sign preservation for negative values.
        using uint_t = std::make_unsigned_t<T>;
        return static_cast<static_int_t>(static_cast<uint_t>(value) >> (-sh));
    }
}

template <class T>
std::make_unsigned_t<T> safe_abs(T val)
{
    if constexpr(std::is_unsigned_v<T>)
    {
        return val;
    }
    else
    {
        using unsigned_t = std::make_unsigned_t<T>;
        // If the input value is equal to the minimum signed value, the absolute
        // value (which is positive) cannot be represented with the signed type,
        // and behavior is undefined.
        //
        // The C++ standard indicates that the conversion from signed to
        // unsigned will have a result congruent to the source modulo 2^n, which
        // yields the correct result when the input is the signed minimum.
        if(std::numeric_limits<T>::min() == val)
            return static_cast<unsigned_t>(val);
        return static_cast<unsigned_t>(std::abs(val));
    }
}

template <class T>
bool is_pow_2(T val)
{
    if(val <= 0)
    {
        return false;
    }
    return (0 == (val & (val - 1)));
}

template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool>,
          std::enable_if_t<std::is_integral_v<TRHS>, bool>>
TRet scalar_bitwise_and(TLHS lhs, TRHS rhs)
{
    return TRet{std::bit_and{}(lhs, rhs)};
}

template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool>,
          std::enable_if_t<std::is_integral_v<TRHS>, bool>>
TRet scalar_bitwise_or(TLHS lhs, TRHS rhs)
{
    return TRet{std::bit_or{}(lhs, rhs)};
}

template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool>,
          std::enable_if_t<std::is_integral_v<TRHS>, bool>>
TRet scalar_bitwise_xor(TLHS lhs, TRHS rhs)
{
    return TRet{std::bit_xor{}(lhs, rhs)};
}

template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TRet scalar_bitwise_not(T value)
{
    return TRet{std::bit_not{}(value)};
}

template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool>,
          std::enable_if_t<std::is_integral_v<TRHS>, bool>>
TRet scalar_div(TLHS lhs, TRHS rhs)
{
    if(rhs == 0)
        return cg_error_t{};

    auto quotient = lhs / rhs;

    // Find the integer type in the return type
    using int_t = typename detail::find_type_or<void, std::is_integral, TRet>::type;

    // Validate that the quotient can be represented
    if(!in_range<int_t>(quotient))
        return cg_error_t{};

    return static_cast<int_t>(quotient);
}

template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool>,
          std::enable_if_t<std::is_integral_v<TRHS>, bool>>
TRet scalar_mod(TLHS lhs, TRHS rhs)
{
    if(rhs == 0)
        return cg_error_t{};

    auto res = lhs % rhs;
    // Find the integer type in the return type
    using int_t = typename detail::find_type_or<void, std::is_integral, TRet>::type;

    // Validate that the quotient can be represented
    if(!in_range<int_t>(res))
        return cg_error_t{};

    return static_cast<int_t>(res);
}

template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool>,
          std::enable_if_t<std::is_integral_v<TRHS>, bool>>
TRet scalar_min(TLHS lhs, TRHS rhs)
{
    using min_t  = std::common_type_t<TLHS, TRHS>;
    auto min_val = std::min(static_cast<min_t>(lhs), static_cast<min_t>(rhs));
    using int_t  = typename detail::find_type_or<void, std::is_integral, TRet>::type;
    if(!in_range<int_t>(min_val))
        return cg_error_t{};

    return min_val;
}

template <class TRet,
          class TLHS,
          class TRHS,
          std::enable_if_t<std::is_integral_v<TLHS>, bool>,
          std::enable_if_t<std::is_integral_v<TRHS>, bool>>
TRet scalar_max(TLHS lhs, TRHS rhs)
{
    using max_t  = std::common_type_t<TLHS, TRHS>;
    auto max_val = std::max(static_cast<max_t>(lhs), static_cast<max_t>(rhs));
    using int_t  = typename detail::find_type_or<void, std::is_integral, TRet>::type;
    if(!in_range<int_t>(max_val))
        return cg_error_t{};

    return max_val;
}

template <class T>
bool compare<T, comp_pred::eq, std::enable_if_t<std::is_integral_v<T>>>::operator()(T a, T b)
{
    return a == b;
};

template <class T>
bool compare<T, comp_pred::ne, std::enable_if_t<std::is_integral_v<T>>>::operator()(T a, T b)
{
    return a != b;
};

template <class T>
bool compare<T, comp_pred::lt, std::enable_if_t<std::is_integral_v<T>>>::operator()(T a, T b)
{
    return a < b;
};

template <class T>
bool compare<T, comp_pred::gt, std::enable_if_t<std::is_integral_v<T>>>::operator()(T a, T b)
{
    return a > b;
};

template <class TFunctorThen, class TFunctorElse>
auto cond_assign(bool cond, TFunctorThen&& then_func, TFunctorElse&& else_func)
{
    if(cond) return then_func();
    return else_func();
}

} // namespace cutegen

#endif // !defined(CG_INT_HPP_INCLUDED_)
