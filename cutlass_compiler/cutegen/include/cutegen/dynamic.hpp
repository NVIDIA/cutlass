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

#if !defined(CUTEGEN_DYNAMIC_HPP_INCLUDED_)
#define CUTEGEN_DYNAMIC_HPP_INCLUDED_

#include <array>
#include <climits>
#include <iosfwd>
#include <numeric>
#include <optional>
#include <string>
#include <type_traits>

#include "cutegen/cutegen.hpp"
#include "cutegen/cg_error.hpp"
#include "cutegen/ratio.hpp"
#include "cutegen/swizzle.hpp"

namespace cutegen
{
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// dynamic.hpp - Public API
//
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail
{
struct property_policy_c_t;
}; // namespace detail

constexpr int32_t default_dynamic_int_bitwidth()
{
    return 32;
}

struct dynamic_int_properties_t
{
    /**
     * @brief Width (in bits) of the associated dynamic integer
     */
    int32_t width = default_dynamic_int_bitwidth();
    /// Constructor
    constexpr dynamic_int_properties_t() = default;
    explicit dynamic_int_properties_t(int32_t w);
    /// Equality operators
    bool                     operator==(const dynamic_int_properties_t& rhs) const;
    bool                     operator!=(const dynamic_int_properties_t& rhs) const;
    dynamic_int_properties_t with_width(int32_t w) const;
    bool                     is_default() const;
    bool                     are_compatible(static_int_t v) const;
    static_int_t             minimum() const;
    static_int_t             maximum() const;
    /**
     * @brief Returns true if the properties describe a dynamic integer with a
     *        non-trivial value for any properties other than width.
     *
     * A constrained dynamic integer has one or more properties that distinguish
     * it from an integer value with the same width.
     */
    bool is_constrained() const;
};

/**
 * @brief Base class for dynamic types
 *
 * Handling code generation for "dynamic" values (i.e. values that are unknown
 * at code generation time) can vary between different uses of the cutegen
 * library. For example, one back end might emit MLIR code, and another might
 * generate strings that represent C/C++ code. The `dynamic_t` struct is the
 * base class for all types that are intended to represent these dynamic types.
 * Different back ends will provide a struct that inherits from the `dynamic_t`
 * struct, with the target-specific struct carrying the necessary state to
 * describe a unique dynamic value. Each back end must also provide function
 * implementations that emit the appropriate code when called by variant visit
 * functions when an operation involving a type derived from `dynamic_t` occurs.
 */
struct dynamic_t
{
public:
    using int_t             = static_int_t;
    using property_policy_t = detail::property_policy_c_t;

protected:
    dynamic_int_properties_t properties;

public:
    /// Constructor.
    constexpr dynamic_t() = default;
    explicit dynamic_t(int32_t width_);
    explicit dynamic_t(const dynamic_int_properties_t& prop);

public:
    /// Equality operator.
    bool operator==(const dynamic_t& b) const;
    /// Inequality operator.
    bool operator!=(const dynamic_t& b) const;

public:
    /// Gets the width property (in units of bits).
    int32_t get_width() const;

    const dynamic_int_properties_t& get_properties() const;

    /**
     * @brief Returns true if the dynamic integer has a non-trivial value for
     * any properties other than width.
     *
     * A constrained dynamic integer has one or more properties that distinguish
     * it from an integer value with the same width.
     */
    bool is_constrained() const;
    // Python bindings currently need to "reset" dynamic value properties due to
    // some problems with property propagation. The visitor below currently does
    // this "in-place."
    friend detail::reset_properties_to_default_visitor;
};

/// Convenience shortcut.
static constexpr dynamic_t dyn{};

/// Output stream insertion.
inline std::ostream& operator<<(std::ostream& os, const dynamic_t& u);

template <class TRet>
TRet scalar_add(const dynamic_t& lhs, const dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_add(const dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_add(TInt lhs, const dynamic_t& rhs);

template <class TRet>
TRet scalar_sub(const dynamic_t& lhs, const dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_sub(const dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_sub(TInt lhs, const dynamic_t& rhs);

template <class TRet>
TRet scalar_mul(const dynamic_t& lhs, const dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_mul(const dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_mul(TInt lhs, const dynamic_t& rhs);
template <class TRet>
TRet scalar_mul(const ratio& lhs, const dynamic_t& rhs);
template <class TRet>
TRet scalar_mul(const dynamic_t& lhs, const ratio& rhs);

template <class TRet>
TRet scalar_mod(const dynamic_t& lhs, const dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_mod(const dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_mod(TInt lhs, const dynamic_t& rhs);

template <class TRet>
TRet scalar_div(const dynamic_t& lhs, const dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_div(const dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_div(TInt lhs, const dynamic_t& rhs);

template <class TRet, bool forceUnsigned = false>
TRet scalar_ceil_div(const dynamic_t& lhs, const dynamic_t& rhs);
template <class TRet,
          bool forceUnsigned = false,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_ceil_div(const dynamic_t& lhs, TInt rhs);
template <class TRet,
          bool forceUnsigned = false,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_ceil_div(TInt lhs, const dynamic_t& rhs);

template <class TRet>
TRet scalar_min(const dynamic_t& lhs, const dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_min(const dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_min(TInt lhs, const dynamic_t& rhs);

template <class TRet>
TRet scalar_max(const dynamic_t& lhs, const dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_max(const dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_max(TInt lhs, const dynamic_t& rhs);

/**
 * @brief Logical shift right for dynamic values
 *
 * If `sh` is negative, a left shift of `abs(sh)` is performed.
 *
 * Shifting a number of bits greater than or equal to the value width results in
 * an error.
 */
template <class TRet>
TRet scalar_lshr(const dynamic_t& value, int32_t sh);

/**
 * @brief Shift left for dynamic values
 *
 * Shifting a number of bits greater than or equal to the value width results in
 * an error.
 */
template <class TRet>
TRet scalar_shl(const dynamic_t& value, int32_t sh);

/// `min` for `dynamic_t`.
dynamic_t min(const dynamic_t& lhs, const dynamic_t& rhs);
template <typename TInt, std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
dynamic_t min(const dynamic_t& lhs, TInt rhs);
template <typename TInt, std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
dynamic_t min(TInt lhs, const dynamic_t& rhs);

/// `max` for `dynamic_t`.
dynamic_t max(const dynamic_t& lhs, const dynamic_t& rhs);
template <typename TInt, std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
dynamic_t max(const dynamic_t& lhs, TInt rhs);
template <typename TInt, std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
dynamic_t max(TInt lhs, const dynamic_t& rhs);

/// `abs` for `dynamic_t`.
dynamic_t abs(const dynamic_t& x);

template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_and(const dynamic_t& lhs, T rhs);
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_and(T lhs, const dynamic_t& rhs);
template <class TRet>
TRet scalar_bitwise_and(const dynamic_t& lhs, const dynamic_t& rhs);

template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_or(const dynamic_t& lhs, T rhs);
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_or(T lhs, const dynamic_t& rhs);
template <class TRet>
TRet scalar_bitwise_or(const dynamic_t& lhs, const dynamic_t& rhs);

template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_xor(const dynamic_t& lhs, T rhs);
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_xor(T lhs, const dynamic_t& rhs);
template <class TRet>
TRet scalar_bitwise_xor(const dynamic_t& lhs, const dynamic_t& rhs);

template <class TRet>
TRet scalar_bitwise_not(const dynamic_t& d);

/// Specialization of `compare` for `dynamic_t`.
template <comp_pred pred>
struct compare<dynamic_t, pred>
{
    using result_t = std::variant<bool, dynamic_t>;

    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    result_t operator()(const dynamic_t&, TR);
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    result_t operator()(TL, const dynamic_t&);
    result_t operator()(const dynamic_t&, const dynamic_t&);
};

/**
 * @brief Conditional assignment for a `std::variant<bool, dynamic_t>` conditional result.
 *
 */
template <class TFunctorThen, class TFunctorElse>
auto cond_assign(std::variant<bool, dynamic_t> cond_result,
                 TFunctorThen&&                then_func,
                 TFunctorElse&&                else_func);

//
// Type traits
//

/**
 * @brief Checks whether the given type has `dynamic_t` as a base class.
 *
 * This structure provides a wrapper around `std::is_base_of`, using `dynamic_t` as the queried base
 * type.
 */
template <class T>
struct has_dynamic_t_base : std::integral_constant<bool, std::is_base_of<dynamic_t, T>::value>
{};

/**
 * @brief Indicates whether a type can hold a dynamic integer value
 *
 * This structure provides a wrapper around `has_dynamic_t_base`. Specializations will adapt the
 * return value accordingly.
 */
template <class T>
struct type_can_hold_dynamic_int : has_dynamic_t_base<T>
{};

/**
 * @brief Properties for the dynamic pointer type
 */
struct dynamic_ptr_properties_t
{
    using width_t = int32_t;
    using align_t = int64_t;

    dynamic_ptr_properties_t() = default;
    dynamic_ptr_properties_t(width_t w);
    dynamic_ptr_properties_t(width_t w, align_t a);
    /**
     * @brief Width of the pointee/value integer type
     */
    width_t value_width_bits = 1;
    /**
     * @brief Pointer alignment
     */
    align_t alignment_bytes = 1;

    bool operator==(const dynamic_ptr_properties_t& rhs) const;
    bool operator!=(const dynamic_ptr_properties_t& rhs) const;

    static align_t default_alignment_for_width(width_t);
};

/**
 * @brief Base class for dynamic pointer types
 *
 * This type describes a dynamic value of type "pointer to signed integer."
 * Private class members store the width of the value (pointee) integer type
 * and the alignment of the pointer.
 *
 * Note that while dynamic integer values (as described by dynamic_t) have
 * a corresponding static integer type in cutegen, there is currently no
 * static pointer type.
 *
 * The pointee type (signed integers) is currently limited to the expected
 * representational needs for cutegen, and does not include other types like
 * floating point values or aggregate structures.
 */
struct dynamic_ptr_t
{
public:
    using width_t = dynamic_ptr_properties_t::width_t;
    using align_t = dynamic_ptr_properties_t::align_t;

    /// Constructor.
    constexpr dynamic_ptr_t() = default;
    /// Constructor with width and alignment
    dynamic_ptr_t(width_t w, align_t a);
    explicit dynamic_ptr_t(width_t w);
    /// Constructor with properties
    dynamic_ptr_t(const dynamic_ptr_properties_t& prop);

    /// Equality operator.
    bool operator==(const dynamic_ptr_t& b) const;
    /// Inequality operator.
    bool operator!=(const dynamic_ptr_t& b) const;

    /// Gets the value width
    width_t get_value_bitwidth() const;

    /// Gets the alignment
    align_t get_alignment_bytes() const;

    // Allow serialization from a string to set values directly.
    friend detail::cg_from_chars<dynamic_ptr_t>;
    friend detail::reset_properties_to_default_visitor;

    const dynamic_ptr_properties_t& get_properties() const;

protected:
    dynamic_ptr_properties_t properties;
};

/// Convenience shortcut.
static constexpr dynamic_ptr_t dyn_ptr{};

/// Output stream insertion.
inline std::ostream& operator<<(std::ostream& os, const dynamic_ptr_t& u);

/**
 * @brief Checks whether the given type has `dynamic_ptr_t` as a base class.
 *
 * This structure provides a wrapper around `std::is_base_of`, using `dynamic_ptr_t` as the queried base
 * type.
 */
template <class T>
struct has_dynamic_ptr_t_base : std::integral_constant<bool, std::is_base_of<dynamic_ptr_t, T>::value>
{};

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// dynamic.hpp - Implementation and internals
//
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail
{
/// Specialization of value_to_string for dynamic_t.
template <>
struct value_to_string<dynamic_t>
{
    static std::string to_str(const dynamic_t& d)
    {
        std::string s("?");
        if(d.get_width() != default_dynamic_int_bitwidth())
        {
            s.append("{");
            s.append("i");
            s.append(std::to_string(d.get_width()));
            s.append("}");
        }
        return s;
    }
};

/// Specialization of detail::cg_from_chars<> for the dynamic_t type.
template <>
class cg_from_chars<dynamic_t> : public cg_from_chars_base<dynamic_t>
{
public:
    cg_from_chars(const char* first, const char* last, bool must_consume_all) :
        cg_from_chars_base(first, last, must_consume_all)
    {
        auto qm = parse_type<token_question_mark>();
        if(!qm.has_value())
        {
            return;
        }
        if(this->at_end())
        {
            // "bare" question mark - construct a default dynamic_t and return.
            this->set_value_with_check(dynamic_t{});
            return;
        }
        auto lbrace = parse_type<token_lbrace>();
        if(!lbrace.has_value())
        {
            // Something other than '{' was found. This may not be an error -
            // let the caller continue by - constructing a default dynamic_t.
            this->set_value_with_check(dynamic_t{});
            return;
        }
        dynamic_int_properties_t prop;
        // Parse keywords and associated values for those keywords that have
        // them.
        auto rbrace = parse_type<token_rbrace>();
        while(!rbrace.has_value())
        {
            auto kw = parse_type<token_keyword>();
            if(!kw.has_value())
            {
                // Error: Something other than a keyword was found.
                return;
            }
            if(kw.value().begins_with("i"))
            {
                if(kw.value() == "i32")
                {
                    prop.width = 32;
                }
                else if(kw.value() == "i64")
                {
                    prop.width = 64;
                }
                else if(kw.value() == "i16")
                {
                    prop.width = 16;
                }
                else if(kw.value() == "i8")
                {
                    prop.width = 8;
                }
                else if(kw.value() == "i1")
                {
                    prop.width = 1;
                }
                else
                {
                    // Error: invalid integer width
                    return;
                }
            }
            else
            {
                // Error: an unexpected keyword was found
                return;
            }
            rbrace = parse_type<token_rbrace>();
        }
        // Success: create a dynamic_t with the parsed properties
        this->set_value_with_check(dynamic_t(prop));
    }
};

template <>
struct value_encoder<dynamic_t>
{
    template <class TBuffer>
    static void encode_value(const dynamic_t& d, TBuffer& buffer)
    {
        encode(buffer, d.get_width());
    }
};

template <>
struct value_decoder<dynamic_t>
{
    template <class TIterator>
    static std::optional<dynamic_t> decode_value(TIterator& it, const TIterator& end)
    {
        const auto                   w      = decode<int32_t>(it, end);
        const std::array<int32_t, 5> widths = {32, 64, 16, 8, 1};
        if(!w.has_value() ||
           (widths.end() == std::find(widths.begin(), widths.end(), w.value())))
            return std::nullopt;
        return dynamic_t(w.value());
    }
};

/// Specialization of value_to_string for dynamic_ptr_t.
template <>
struct value_to_string<dynamic_ptr_t>
{
    static std::string to_str(const dynamic_ptr_t& d)
    {
        using align_t = dynamic_ptr_properties_t::align_t;

        std::string s("i");
        s.append(std::to_string(d.get_value_bitwidth()));
        s.append("*");
        align_t default_align = dynamic_ptr_properties_t::default_alignment_for_width(d.get_value_bitwidth());
        if(d.get_alignment_bytes() != default_align)
        {
            s.append("{align=");
            s.append(std::to_string(d.get_alignment_bytes()));
            s.append("}");
        }
        return s;
    }
};

/// Specialization of detail::cg_from_chars<> for the dynamic_ptr_t type.
template <>
class cg_from_chars<dynamic_ptr_t> : public cg_from_chars_base<dynamic_ptr_t>
{
public:
    cg_from_chars(const char* first, const char* last, bool must_consume_all) :
        cg_from_chars_base(first, last, must_consume_all)
    {
        // Expected form example: i32*{align=8}
        // parse 'i'
        auto ti = parse_type<token_i>();
        if(!ti.has_value())
        {
            return;
        }
        // parse the type width (e.g. 32  or 64)
        auto val_width = parse_type<dynamic_ptr_t::width_t>();
        if(!val_width.has_value())
        {
            return;
        }
        auto ast = parse_type<token_asterisk>();
        if(!ast.has_value())
        {
            return;
        }
        auto lbrace = parse_type<token_lbrace>();
        if(!lbrace.has_value())
        {
            // Something other than '{' was found. This may not be an error -
            // let the caller continue by constructing a default dynamic_ptr_t.
            this->set_value_with_check(dynamic_ptr_t{val_width.value()});
            return;
        }
        auto kw = parse_type<token_keyword>();
        if(!kw.has_value())
        {
            // Error: Something other than a keyword was found.
            return;
        }
        if(!(kw.value() == "align"))
        {
            // Error: a keyword other than 'align' was found
            return;
        }
        auto eq = parse_type<token_eq>();
        if(!eq.has_value())
        {
            // Error: missing '=' after 'align'
            return;
        }
        auto ptr_align = parse_type<dynamic_ptr_t::align_t>();
        if(!ptr_align.has_value())
        {
            // Error: no value for alignment
            return;
        }
        auto rbrace = parse_type<token_rbrace>();
        if(!rbrace.has_value())
        {
            // Error: no closing '}'
        }
        // Success: create a dynamic_ptr_t with the parsed width and alignment
        this->set_value_with_check(dynamic_ptr_t{val_width.value(), ptr_align.value()});
    }
};

template <>
struct value_encoder<dynamic_ptr_t>
{
    template <class TBuffer>
    static void encode_value(const dynamic_ptr_t& d, TBuffer& buffer)
    {
        encode(buffer, d.get_value_bitwidth());
        encode(buffer, d.get_alignment_bytes());
    }
};

template <>
struct value_decoder<dynamic_ptr_t>
{
    template <class TIterator>
    static std::optional<dynamic_ptr_t> decode_value(TIterator& it, const TIterator& end)
    {
        const auto w = decode<dynamic_ptr_properties_t::width_t>(it, end);
        if(!w.has_value()) return std::nullopt;
        const auto a = decode<dynamic_ptr_properties_t::align_t>(it, end);
        if(!a.has_value()) return std::nullopt;
        return dynamic_ptr_t(dynamic_ptr_properties_t{w.value(), a.value()});
    }
};

/**
 * @brief Structure to describe the execution and result of an arithmetic operation
 *
 * This struct is used to describe the desired execution parameters and result of
 * unary and binary arithmetic operations that cutegen might perform.
 *
 * In some cases, we may want to determine information about an arithmetic operation
 * without actually performing the operation - for example, to determine the
 * properties of the operation result for type inference or verification. In other
 * cases, we need the same information so that we can emit code, including any
 * potential width conversions on input operands.
 *
 * The only current "execution parameter" is the bit width of the operation being
 * performed. In a code generation scenario, if either operand has a width that does
 * not match the op_width field, it will be converted before the actual arithmetic
 * operation is generated.
 *
 * The result_prop field stores the properties of the result of the operation.
 *
 * Note that it possible (in theory at least) for the op_width to be different than
 * the width property of the result. Consider a future example in which properties
 * are extended to have min/max values.
 * A: width = 64, min = INT_MAX + 100, max = INT_MAX + 200
 * B: width = 64, min = INT_MAX, max = INT_MAX + 100
 * C = A - B
 * The range of the result will be [0, 100], which can be represented by a 32-bit
 * value (or smaller). So the implementation might perform the subtraction as a
 * 64-bit operation, and then safely truncate the result to a 32-bit value.
 */
struct arith_op_desc_t
{
    dynamic_int_properties_t result_prop;
    int32_t                  op_width;
    arith_op_desc_t(const dynamic_int_properties_t& r_prop,
                    int32_t                         op_w) :
        result_prop(r_prop),
        op_width(op_w)
    {
    }
};

struct src_operand_index_t
{
    explicit src_operand_index_t(int i) :
        index(i)
    {
    }
    int index;
};

/**
 * @brief Variant to hold the different result types for functions that
 *        "resolve" the results of arithmetic operations.
 *
 * Dynamic integer values contain properties that influence the results of
 * arithmetic operations, e.g., the integer width.
 * cutegen uses the concept of a property "policy" that uses inputs to
 * arithmetic operations to determine the properties (or values) of the output
 * operations. There is currently a single policy, based on C/C++, but other
 * policies are possible.
 * The "resolve" methods for individual arithmetic operations examines the
 * operation inputs (which are typically either dynamic values or static
 * integers), and may return one of the following values:
 * - a static integer value (when the result is known from the inputs)
 * - an error code (e.g. when dividing by zero)
 * - a source operand index that indicates the result (e.g. when adding a static
 *   constant zero to a dynamic value
 * - an arithmetic operation description that contains the properties of the
 *   result, and can also be used to emit an operation
 */
using arith_resolve_t = std::variant<static_int_t,
                                     src_operand_index_t,
                                     arith_op_desc_t,
                                     cg_error_t>;

/**
 * @brief Structure to describe an arithmetic "policy" that matches C/C++ semantics
 *
 * This structure encapsulates the determination of the arith_op_desc_t structure
 * above for various arithmetic operations. This policy was chosen to behave
 * similarly to C/C++ rules for integer promotions. (Other alternative policies
 * will be mentioned below). Note that C/C++ have provisions for both signed and
 * unsigned integers, whereas cutegen currently only deals with signed integers.
 *
 * Specifically, this policy has the following behavior:
 * - Static values will be represented as 32-bit values if the constant can be
 *   represented by a 32-bit signed integer, and will be represented as a 64-bit
 *   value otherwise. This is similar to C/C++ behavior for integer literals:
 *   https://en.cppreference.com/w/cpp/language/integer_literal.html
 * - The result of binary arithmetic operations will have a width that is 32 bits
 *   if both input operands are 32 bits wide, and the result will be 64 bits wide
 *   if either input operand is 64 bits wide. This is similar to C++ behavior:
 *   https://en.cppreference.com/w/cpp/language/implicit_conversion.html
 *
 * Note that this policy does not provide protection from integer overflow:
 * A = INT_MAX {i32}
 * B = 1 {i32}
 * Since both input operands have 32-bit width, the result will also have a width
 * of 32 bits.
 * C = A + B {i32}   signed arithmetic overflow, which is undefined in C++
 *
 * An alternative property policy (not implemented here) might take a more
 * aggressive approach to avoiding overflow: for example, the sum of a pair of
 * unconstrained i32 values can be an i64 value. With this approach, result widths
 * quickly become promoted to 64 bits. To avoid using i64 in these cases, dynamic
 * properties can be extended to have min/max values, and with user annotations of
 * integer ranges it may be possible in some cases to use reduce the width of
 * result values via interval arithmetic and/or integer range analysis.
 */
struct property_policy_c_t
{
    using int_t = static_int_t;
    //--------------------------------------------------------------------------
    // resolve_add()
    static arith_resolve_t resolve_add(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = std::max(lhs.get_width(), rhs.get_width());
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_add(const dynamic_t& lhs, TInt rhs)
    {
        auto res_width = std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    static arith_resolve_t resolve_sub(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = std::max(lhs.get_width(), rhs.get_width());
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_sub(const dynamic_t& lhs, TInt rhs)
    {
        auto res_width = std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_sub(TInt lhs, const dynamic_t& rhs)
    {
        auto res_width = std::max(rhs.get_width(), in_range<int32_t>(lhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    //--------------------------------------------------------------------------
    // resolve_mul()
    static arith_resolve_t resolve_mul(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = std::max(lhs.get_width(), rhs.get_width());
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_mul(const dynamic_t& lhs, TInt rhs)
    {
        if(0 == rhs)
        {
            return arith_resolve_t{0};
        }
        if(1 == rhs)
        {
            // Multiplying by 1 - return the lhs operand
            return src_operand_index_t(0);
        }
        auto res_width = std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    //--------------------------------------------------------------------------
    // resolve_mod()
    static arith_resolve_t resolve_mod(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = std::max(lhs.get_width(), rhs.get_width());
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_mod(const dynamic_t& lhs, TInt rhs)
    {
        if(0 == rhs)
        {
            return arith_resolve_t{cg_error_t{}};
        }
        if(1 == rhs)
        {
            // x % 1 == 0 for any integer x.
            return arith_resolve_t{0};
        }
        auto res_width = std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_mod(TInt lhs, const dynamic_t& rhs)
    {
        if(0 == lhs)
        {
            return arith_resolve_t{0};
        }
        auto res_width = std::max(rhs.get_width(), in_range<int32_t>(lhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TIntLHS,
              typename TIntRHS,
              std::enable_if_t<std::is_integral_v<TIntLHS>, bool> = true,
              std::enable_if_t<std::is_integral_v<TIntRHS>, bool> = true>
    static arith_resolve_t resolve_mod(TIntLHS lhs, TIntRHS rhs)
    {
        if(0 == rhs)
        {
            return arith_resolve_t{cg_error_t{}};
        }
        return arith_resolve_t{lhs % rhs};
    }
    //--------------------------------------------------------------------------
    // Division
    static arith_resolve_t resolve_div(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = std::max(lhs.get_width(), rhs.get_width());
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_div(const dynamic_t& lhs, TInt rhs)
    {
        if(0 == rhs)
        {
            return arith_resolve_t{cg_error_t{}};
        }
        if(1 == rhs)
        {
            // Dividing by 1 - return the lhs operand
            return src_operand_index_t(0);
        }
        auto res_width = std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_div(TInt lhs, const dynamic_t& rhs)
    {
        // CuTe C++ implements: 0 / ? -> 0, even if ? is equal to zero.
        // The layout algebra is not expected to rely on _0{}/0 = 0.
        if(0 == lhs)
        {
            return arith_resolve_t{0};
        }
        auto res_width = std::max(rhs.get_width(), in_range<int32_t>(lhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TIntLHS,
              typename TIntRHS,
              std::enable_if_t<std::is_integral_v<TIntLHS>, bool> = true,
              std::enable_if_t<std::is_integral_v<TIntRHS>, bool> = true>
    static arith_resolve_t resolve_div(TIntLHS lhs, TIntRHS rhs)
    {
        if(0 == rhs)
        {
            return arith_resolve_t{cg_error_t{}};
        }
        return arith_resolve_t{lhs / rhs};
    }
    //--------------------------------------------------------------------------
    // resolve_ceil_div()
    static arith_resolve_t resolve_ceil_div(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = std::max(lhs.get_width(), rhs.get_width());
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_ceil_div(TInt lhs, const dynamic_t& rhs)
    {
        // CuTe C++ implements: 0 / ? -> 0, even if ? is equal to zero.
        // The layout algebra is not expected to rely on _0{}/0 = 0.
        if(0 == lhs)
        {
            return arith_resolve_t{0};
        }
        auto res_width = std::max(in_range<int32_t>(lhs) ? 32 : 64, rhs.get_width());
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_ceil_div(const dynamic_t& lhs, TInt rhs)
    {
        if(rhs == 0)
        {
            return arith_resolve_t{cg_error_t{}};
        }
        if(1 == rhs)
        {
            // Return the left hand side operand when dividing by 1
            return src_operand_index_t(0);
        }
        auto res_width = std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    //--------------------------------------------------------------------------
    // resolve_min()
    static arith_resolve_t resolve_min(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = std::max(lhs.get_width(), rhs.get_width());
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_min(const dynamic_t& lhs, TInt rhs)
    {
        auto res_width = std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    //--------------------------------------------------------------------------
    // resolve_max()
    static arith_resolve_t resolve_max(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = std::max(lhs.get_width(), rhs.get_width());
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_max(const dynamic_t& lhs, TInt rhs)
    {
        auto res_width = std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    //--------------------------------------------------------------------------
    // resolve_bitwise_and()
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_bitwise_and(const dynamic_t& lhs, TInt rhs)
    {
        if(0 == rhs)
        {
            return arith_resolve_t{0};
        }
        auto res_width = std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    static arith_resolve_t resolve_bitwise_and(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = std::max(lhs.get_width(), rhs.get_width());
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    //--------------------------------------------------------------------------
    // resolve_bitwise_or()
    static arith_resolve_t resolve_bitwise_or(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = std::max(lhs.get_width(), rhs.get_width());
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_bitwise_or(const dynamic_t& lhs, TInt rhs)
    {
        if(0 == rhs)
        {
            // RHS dynamic value is zero - return the lhs operand
            return src_operand_index_t(0);
        }
        auto res_width = std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    //--------------------------------------------------------------------------
    // resolve_bitwise_xor()
    static arith_resolve_t resolve_bitwise_xor(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        return resolve_bitwise_or(lhs, rhs);
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_bitwise_xor(const dynamic_t& lhs, TInt rhs)
    {
        return resolve_bitwise_or(lhs, rhs);
    }
    //--------------------------------------------------------------------------
    // resolve_bitwise_not()
    static arith_resolve_t resolve_bitwise_not(const dynamic_t& d)
    {
        return arith_op_desc_t(dynamic_int_properties_t(d.get_width()),
                               d.get_width());
    }
    //--------------------------------------------------------------------------
    // Comparison operations
    static arith_resolve_t resolve_cmp_default(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = 1;
        return arith_op_desc_t(dynamic_int_properties_t(res_width),
                               std::max(lhs.get_width(), rhs.get_width()));
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_cmp_default(const dynamic_t& lhs, TInt rhs)
    {
        auto res_width = 1;
        return arith_op_desc_t(dynamic_int_properties_t(res_width),
                               std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64));
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_cmp_default(TInt lhs, const dynamic_t& rhs)
    {
        auto res_width = 1;
        return arith_op_desc_t(dynamic_int_properties_t(res_width),
                               std::max(rhs.get_width(), in_range<int32_t>(lhs) ? 32 : 64));
    }
    static arith_resolve_t resolve_cmp_eq(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = 1;
        return arith_op_desc_t(dynamic_int_properties_t(res_width),
                               std::max(lhs.get_width(), rhs.get_width()));
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_cmp_eq(const dynamic_t& lhs, TInt rhs)
    {
        if(!in_range_of_width(rhs, lhs.get_width()))
        {
            // The dynamic value cannot be equal to the static integer - return
            // false.
            return 0;
        }
        auto res_width = 1;
        return arith_op_desc_t(dynamic_int_properties_t(res_width),
                               std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64));
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_resolve_t resolve_cmp_eq(TInt lhs, const dynamic_t& rhs)
    {
        return resolve_cmp_eq(rhs, lhs);
    }
    //--------------------------------------------------------------------------
    // If/Else (conditional assignment)
    static arith_op_desc_t resolve_if_else(static_int_t lhs, static_int_t rhs)
    {
        int32_t lhs_width = in_range<int32_t>(lhs) ? 32 : 64;
        int32_t rhs_width = in_range<int32_t>(rhs) ? 32 : 64;
        auto    res_width = std::max(lhs_width, rhs_width);
        return arith_op_desc_t(dynamic_int_properties_t(res_width),
                               0); // operation width not used for if/else
    }
    static arith_op_desc_t resolve_if_else(const dynamic_t& lhs, const dynamic_t& rhs)
    {
        auto res_width = std::max(lhs.get_width(), rhs.get_width());
        return arith_op_desc_t(dynamic_int_properties_t(res_width),
                               0); // operation width not used for if/else
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    static arith_op_desc_t resolve_if_else(const dynamic_t& lhs, TInt rhs)
    {
        auto res_width = std::max(lhs.get_width(), in_range<int32_t>(rhs) ? 32 : 64);
        return arith_op_desc_t(dynamic_int_properties_t(res_width),
                               0); // operation width not used for if/else
    }
    //--------------------------------------------------------------------------
    // from_static (creating a value from a static integer
    static arith_op_desc_t resolve_from_static(int32_t a)
    {
        int32_t res_width = 32;
        return arith_op_desc_t(dynamic_int_properties_t(res_width),
                               0); // operation width not used for from_static
    }
    static arith_op_desc_t resolve_from_static(int64_t a)
    {
        // Represent static values with a 32-bit integer if it can be
        // represented with a 32-bit integer, and 64 bits otherwise.
        int32_t res_width = in_range<int32_t>(a) ? 32 : 64;
        return arith_op_desc_t(dynamic_int_properties_t(res_width),
                               0); // operation width not used for from_static
    }
    //--------------------------------------------------------------------------
    // resolve_shl() (left shift)
    static arith_resolve_t resolve_shl(const dynamic_t& lhs, uint32_t shift_amount)
    {
        // Shifting a number of bits greater than the value width results in an
        // error.
        if(shift_amount >= static_cast<uint32_t>(lhs.get_width()))
        {
            return cg_error_t{};
        }
        if(0 == shift_amount)
        {
            // Shifting by zero bits: return the source operand
            return src_operand_index_t(0);
        }
        int32_t res_width = lhs.get_width();
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }
    //--------------------------------------------------------------------------
    // resolve_lshr (logical shift right)
    static arith_resolve_t resolve_lshr(const dynamic_t& lhs, uint32_t shift_amount)
    {
        // Shifting a number of bits greater than the value width results in an
        // error.
        if(shift_amount >= static_cast<uint32_t>(lhs.get_width()))
        {
            return cg_error_t{};
        }
        // Shifting zero bits: return the source operand
        if(0 == shift_amount)
        {
            return src_operand_index_t(0);
        }
        int32_t res_width = lhs.get_width();
        return arith_op_desc_t(dynamic_int_properties_t(res_width), res_width);
    }

private:
    template <class T>
    static typename std::make_signed<T>::type abs_if_signed(T val)
    {
        if constexpr(std::is_signed_v<T>)
        {
            return std::abs(val);
        }
        else
        {
            return val;
        }
    }
};

} // namespace detail

inline dynamic_ptr_properties_t::dynamic_ptr_properties_t(width_t w) :
    value_width_bits(w),
    alignment_bytes(default_alignment_for_width(w))
{
}

inline dynamic_ptr_properties_t::dynamic_ptr_properties_t(width_t w, align_t a) :
    value_width_bits(w),
    alignment_bytes(a)
{
}

inline bool dynamic_ptr_properties_t::operator==(const dynamic_ptr_properties_t& rhs) const
{
    return (value_width_bits == rhs.value_width_bits) && (alignment_bytes == rhs.alignment_bytes);
}

inline bool dynamic_ptr_properties_t::operator!=(const dynamic_ptr_properties_t& rhs) const
{
    return !(*this == rhs);
}

inline dynamic_ptr_properties_t::align_t dynamic_ptr_properties_t::default_alignment_for_width(width_t w)
{
    return (w <= CHAR_BIT) ? 1 : (w / CHAR_BIT);
}

inline dynamic_int_properties_t::dynamic_int_properties_t(int32_t w) :
    width(w)
{
}

inline bool dynamic_int_properties_t::operator==(const dynamic_int_properties_t& rhs) const
{
    return (width == rhs.width);
}

inline bool dynamic_int_properties_t::operator!=(const dynamic_int_properties_t& rhs) const
{
    return !(*this == rhs);
}

inline bool dynamic_int_properties_t::is_default() const
{
    return (*this == dynamic_int_properties_t{});
}

inline dynamic_int_properties_t dynamic_int_properties_t::with_width(int32_t w) const
{
    dynamic_int_properties_t r = *this;
    r.width                    = w;
    return r;
}

inline bool dynamic_int_properties_t::are_compatible(static_int_t v) const
{
    return in_range_of_width(v, width);
}

inline static_int_t dynamic_int_properties_t::minimum() const
{
    if(64 == width)
    {
        return std::numeric_limits<int64_t>::min();
    }
    int64_t one     = 1;
    int64_t min_val = -(one << (width - 1));
    return min_val;
}

inline static_int_t dynamic_int_properties_t::maximum() const
{
    if(64 == width)
    {
        return std::numeric_limits<int64_t>::max();
    }
    int64_t one     = 1;
    int64_t max_val = (one << (width - 1)) - 1;
    return max_val;
}

inline bool dynamic_int_properties_t::is_constrained() const
{
    return false;
}

inline dynamic_t::dynamic_t(int32_t width_) :
    properties(width_)
{
}

inline dynamic_t::dynamic_t(const dynamic_int_properties_t& prop) :
    properties(prop)
{
}

inline bool dynamic_t::operator==(const dynamic_t& b) const
{
    return (properties == b.properties);
}

inline bool dynamic_t::operator!=(const dynamic_t& b) const
{
    return !(*this == b);
}

inline bool dynamic_t::is_constrained() const
{
    return properties.is_constrained();
}

inline dynamic_ptr_t::dynamic_ptr_t(width_t w, align_t a) :
    properties(w, a)
{
}

inline dynamic_ptr_t::dynamic_ptr_t(width_t w) :
    properties(w)
{
}

inline dynamic_ptr_t::dynamic_ptr_t(const dynamic_ptr_properties_t& prop) :
    properties(prop)
{
}

inline bool dynamic_ptr_t::operator==(const dynamic_ptr_t& b) const
{
    return (properties == b.properties);
}

inline bool dynamic_ptr_t::operator!=(const dynamic_ptr_t& b) const
{
    return !(*this == b);
}

inline dynamic_ptr_t::width_t dynamic_ptr_t::get_value_bitwidth() const
{
    return properties.value_width_bits;
}

inline dynamic_ptr_t::align_t dynamic_ptr_t::get_alignment_bytes() const
{
    return properties.alignment_bytes;
}

inline const dynamic_ptr_properties_t& dynamic_ptr_t::get_properties() const
{
    return properties;
}

inline int32_t dynamic_t::get_width() const
{
    return properties.width;
}

inline const dynamic_int_properties_t& dynamic_t::get_properties() const
{
    return properties;
}

template <class TRet>
TRet scalar_add(const dynamic_t& lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_add(lhs, rhs);

    // No known/expected error conditions for add operators
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_add(const dynamic_t& lhs, TInt rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_add(lhs, rhs);

    // No known/expected error conditions for add operator
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_add(TInt lhs, const dynamic_t& rhs)
{
    return scalar_add<TRet>(rhs, lhs);
}

template <class TRet>
TRet scalar_sub(const dynamic_t& lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_sub(lhs, rhs);

    // No known/expected error conditions for sub operator
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_sub(const dynamic_t& lhs, TInt rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_sub(lhs, rhs);

    // No known/expected error conditions for sub operators
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_sub(TInt lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_sub(lhs, rhs);

    // No known/expected error conditions for sub operators
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

template <class TRet>
TRet scalar_mul(const dynamic_t& lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_mul(lhs, rhs);

    // No known/expected error conditions for mul operators
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    // Return a static integer
    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert((src_op.index == 0) || (src_op.index == 1));
        return (0 == src_op.index) ? lhs : rhs;
    }

    // Return a description of the operation that will produce the result
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_mul(const dynamic_t& lhs, TInt rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_mul(lhs, rhs);

    // No known/expected error conditions for mul operator
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    // Return a static integer
    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert(src_op.index == 0);
        return lhs;
    }

    // Return a description of the operation that will produce the result
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_mul(TInt lhs, const dynamic_t& rhs)
{
    return scalar_mul<TRet>(rhs, lhs);
}
template <class TRet>
TRet scalar_mul(const ratio& lhs, const dynamic_t& rhs)
{
    auto lhs_red = lhs.reduced();
    if(std::holds_alternative<ratio::int_t>(lhs_red))
    {
        auto lhs_int = std::get<ratio::int_t>(lhs_red);
        return scalar_mul<TRet>(lhs_int, rhs);
    }
    using var_t = std::variant<static_int_t, dynamic_t, cg_error_t>;
    auto prod   = scalar_mul<var_t>(lhs.num(), rhs);
    // If the product is an integer, perform integer division directly
    if(std::holds_alternative<static_int_t>(prod))
    {
        return std::get<static_int_t>(prod) / lhs.denom();
    }
    // The ratio type is currently limited to static numerator/denominator
    // values, so we return a dynamic value here that is the result of a
    // (truncating) division.
    // Note: We can't use the return type TRet directly as scaled basis values
    // do not support the error type, and scalar_div can return an error (if,
    // for example, lhs.denom() is zero).
    auto quot = scalar_div<var_t>(std::get<dynamic_t>(prod), lhs.denom());
    if(std::holds_alternative<cg_error_t>(quot))
    {
        assert(false);
        return 0;
    }
    if(std::holds_alternative<static_int_t>(quot))
    {
        return std::get<static_int_t>(quot);
    }
    return std::get<dynamic_t>(quot);
}

template <class TRet>
TRet scalar_mul(const dynamic_t& lhs, const ratio& rhs)
{
    // multiplication is symmetric
    return scalar_mul<TRet>(rhs, lhs);
}

template <class TRet>
TRet scalar_mod(const dynamic_t& lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_mod(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_mod(const dynamic_t& lhs, TInt rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_mod(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_mod(TInt lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_mod(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

template <class TRet>
TRet scalar_div(const dynamic_t& lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_div(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert((src_op.index == 0) || (src_op.index == 1));
        return (0 == src_op.index) ? lhs : rhs;
    }

    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_div(const dynamic_t& lhs, TInt rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_div(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert(src_op.index == 0);
        return lhs;
    }

    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_div(TInt lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_div(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

template <class TRet, bool forceUnsigned>
TRet scalar_ceil_div(const dynamic_t& lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_ceil_div(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert((src_op.index == 0) || (src_op.index == 1));
        return (0 == src_op.index) ? lhs : rhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          bool forceUnsigned,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_ceil_div(const dynamic_t& lhs, TInt rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_ceil_div(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert(src_op.index == 0);
        return lhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

template <class TRet,
          bool forceUnsigned,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_ceil_div(TInt lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_ceil_div(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

//
// min
//

template <class TRet>
TRet scalar_min(const dynamic_t& lhs, const dynamic_t& rhs)
{
    using prop_policy                     = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = prop_policy::resolve_min(lhs, rhs);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    auto& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_min(const dynamic_t& lhs, TInt rhs)
{
    using prop_policy                     = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = prop_policy::resolve_min(lhs, rhs);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    auto& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_min(TInt lhs, const dynamic_t& rhs)
{
    return scalar_min<TRet>(rhs, lhs);
}

template <class TRet>
TRet scalar_max(const dynamic_t& lhs, const dynamic_t& rhs)
{
    using prop_policy                     = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = prop_policy::resolve_max(lhs, rhs);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    auto& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_max(const dynamic_t& lhs, TInt rhs)
{
    using prop_policy                     = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = prop_policy::resolve_max(lhs, rhs);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    auto& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_max(TInt lhs, const dynamic_t& rhs)
{
    return scalar_max<TRet>(rhs, lhs);
}

//
// abs
//

inline dynamic_t abs(const dynamic_t& x)
{
    return dynamic_t(x.get_width());
}

//
// bitwise
//

template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TRet scalar_bitwise_and(const dynamic_t& lhs, T rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_bitwise_and(lhs, rhs);

    // No known/expected error conditions for bitwise operators
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TRet scalar_bitwise_and(T lhs, const dynamic_t& rhs)
{
    return scalar_bitwise_and(rhs, lhs);
}
template <class TRet>
TRet scalar_bitwise_and(const dynamic_t& lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_bitwise_and(lhs, rhs);

    // No known/expected error conditions for bitwise operators
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TRet scalar_bitwise_or(const dynamic_t& lhs, T rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_bitwise_or(lhs, rhs);

    // No known/expected error conditions for bitwise operators
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert(src_op.index == 0);
        return lhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TRet scalar_bitwise_or(T lhs, const dynamic_t& rhs)
{
    // Swap operand order since the operation is symmetric
    return scalar_bitwise_or(rhs, lhs);
}
template <class TRet>
TRet scalar_bitwise_or(const dynamic_t& lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_bitwise_or(lhs, rhs);

    // No known/expected error conditions for bitwise operators
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert((src_op.index == 0) || (src_op.index == 1));
        return (0 == src_op.index) ? lhs : rhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TRet scalar_bitwise_xor(const dynamic_t& lhs, T rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_bitwise_xor(lhs, rhs);

    // No known/expected error conditions for bitwise operators
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert(src_op.index == 0);
        return lhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

template <class TRet>
TRet scalar_bitwise_xor(const dynamic_t& lhs, const dynamic_t& rhs)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_bitwise_xor(lhs, rhs);

    // No known/expected error conditions for bitwise operators
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert((src_op.index == 0) || (src_op.index == 1));
        return (0 == src_op.index) ? lhs : rhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

template <class TRet>
TRet scalar_bitwise_not(const dynamic_t& d)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_bitwise_not(d);

    // No known/expected error conditions for bitwise operators
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Bitwise not operation should not return the operand
    assert(!std::holds_alternative<detail::src_operand_index_t>(arith_resolve));

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

//
// compare
//

template <comp_pred pred>
template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool>>
std::variant<bool, dynamic_t> compare<dynamic_t, pred>::operator()(const dynamic_t& d, [[maybe_unused]] TR i)
{
    if constexpr(pred == comp_pred::eq)
    {
        using prop_policy  = dynamic_t::property_policy_t;
        auto arith_resolve = prop_policy::resolve_cmp_eq(d, i);

        // No known/expected error conditions for bitwise operators
        assert(!std::holds_alternative<cg_error_t>(arith_resolve));

        // Interpret static 0 as false and any other value (typically 1) as true
        if(std::holds_alternative<static_int_t>(arith_resolve))
            return (0 != std::get<static_int_t>(arith_resolve)) ? true : false;

        assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
        detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
        return dynamic_t(op_desc.result_prop);
    }
    // For all other predicates, we currently default to unknown properties
    return dynamic_t{/*width=*/1};
}

template <comp_pred pred>
template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool>>
std::variant<bool, dynamic_t> compare<dynamic_t, pred>::operator()([[maybe_unused]] TL i, const dynamic_t& d)
{
    if constexpr(pred == comp_pred::eq)
    {
        using prop_policy  = dynamic_t::property_policy_t;
        auto arith_resolve = prop_policy::resolve_cmp_eq(i, d);

        // No known/expected error conditions for bitwise operators
        assert(!std::holds_alternative<cg_error_t>(arith_resolve));

        // Interpret static 0 as false and any other value (typically 1) as true
        if(std::holds_alternative<static_int_t>(arith_resolve))
            return (0 != std::get<static_int_t>(arith_resolve)) ? true : false;

        assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
        detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
        return dynamic_t(op_desc.result_prop);
    }
    return dynamic_t{/*width=*/1};
}

template <comp_pred pred>
std::variant<bool, dynamic_t> compare<dynamic_t, pred>::operator()(const dynamic_t& lhs,
                                                                   const dynamic_t& rhs)
{
    if constexpr(pred == comp_pred::eq)
    {
        using prop_policy  = dynamic_t::property_policy_t;
        auto arith_resolve = prop_policy::resolve_cmp_eq(lhs, rhs);

        // No known/expected error conditions for bitwise operators
        assert(!std::holds_alternative<cg_error_t>(arith_resolve));

        // Interpret static 0 as false and any other value (typically 1) as true
        if(std::holds_alternative<static_int_t>(arith_resolve))
            return (0 != std::get<static_int_t>(arith_resolve)) ? true : false;

        assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
        detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
        return dynamic_t(op_desc.result_prop);
    }
    return dynamic_t{/*width=*/1};
}

template <class TFunctorThen, class TFunctorElse>
auto cond_assign(std::variant<bool, dynamic_t> cond_result,
                 TFunctorThen&&                then_func,
                 TFunctorElse&&                else_func)
{
    using result_t        = std::invoke_result_t<TFunctorElse>;
    using property_policy = dynamic_t::property_policy_t;
    using arith_op_desc_t = detail::arith_op_desc_t;
    using opt_arith_desc  = std::optional<arith_op_desc_t>;
    //--------------------------------------------------------------------------
    // If the conditional result can be statically evaluated, invoke the lambda
    // for the appropriate clause ('then' or 'else').
    if(std::holds_alternative<bool>(cond_result))
    {
        if(std::get<bool>(cond_result))
            return then_func();
        return else_func();
    }
    // Evaluate the then clause.
    auto then_result = then_func();
    // Evaluate the else clause.
    auto else_result = else_func();
    // Using a temporary object here instead of a lambda variable because the
    // variable may cause stack corruption with MSVC 2019.
    // details
    // - https://stackoverflow.com/questions/77437655/msvc-throws-run-time-check-failure-2-corrupted-stack-for-this-use-of-the-ov
    // - https://developercommunity.visualstudio.com/t/Runtime-stack-corruption-using-std::visi/346200
    // Resolve the type of the if operation by merging the then/else types.
    opt_arith_desc result_desc = visit(detail::overload{
                                           [](const dynamic_t& lhs, const dynamic_t& rhs) -> opt_arith_desc {
                                               arith_op_desc_t op_desc = property_policy::resolve_if_else(lhs, rhs);
                                               return opt_arith_desc{op_desc};
                                           },
                                           [](const dynamic_t& lhs, static_int_t rhs) -> opt_arith_desc {
                                               arith_op_desc_t op_desc = property_policy::resolve_if_else(lhs, rhs);
                                               return opt_arith_desc{op_desc};
                                           },
                                           [](static_int_t lhs, const dynamic_t& rhs) -> opt_arith_desc {
                                               arith_op_desc_t op_desc = property_policy::resolve_if_else(rhs, lhs);
                                               return opt_arith_desc{op_desc};
                                           },
                                           [](static_int_t lhs, static_int_t rhs) -> opt_arith_desc {
                                               arith_op_desc_t op_desc = property_policy::resolve_if_else(lhs, rhs);
                                               return opt_arith_desc{op_desc};
                                           },
                                           [](auto, auto) -> opt_arith_desc {
                                               return std::nullopt;
                                           }},
                                       then_result,
                                       else_result);

    if(!result_desc.has_value())
    {
        // One or more of the then/else blocks returned a type that was neither a
        // static nor a dynamic integer. Therefore, resolution of the if return
        // type failed.
        return result_t{cg_error_t{}};
    }
    return result_t{dynamic_t{result_desc.value().result_prop}};
}

template <class TRet>
TRet scalar_lshr(const dynamic_t& dval, int32_t shift_amount)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = (shift_amount >= 0) ?
                             prop_policy::resolve_lshr(dval, shift_amount) :
                             prop_policy::resolve_shl(dval, safe_abs(shift_amount));

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        assert(0 == std::get<detail::src_operand_index_t>(arith_resolve).index);
        return dval;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

template <class TRet>
TRet scalar_shl(const dynamic_t& dval, int32_t sh)
{
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = (sh >= 0) ?
                             prop_policy::resolve_shl(dval, sh) :
                             prop_policy::resolve_lshr(dval, safe_abs(sh));

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        assert(0 == std::get<detail::src_operand_index_t>(arith_resolve).index);
        return dval;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return dynamic_t(op_desc.result_prop);
}

//
// To/From strings
//

inline std::ostream& operator<<(std::ostream& os, const dynamic_t& u)
{
    os << to_string(u);
    return os;
}

inline std::ostream& operator<<(std::ostream& os, const dynamic_ptr_t& p)
{
    os << to_string(p);
    return os;
}

} // namespace cutegen
#endif
