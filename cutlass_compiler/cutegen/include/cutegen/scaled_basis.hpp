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

#if !defined(CUTEGEN_SCALED_BASIS_HPP_INCLUDED_)
#define CUTEGEN_SCALED_BASIS_HPP_INCLUDED_

#include <assert.h>
#include <iosfwd>
#include <iterator>
#include <optional>
#include <stdint.h>
#include <string>
#include <tuple>
#include <type_traits>
#include <utility>
#include <variant>
#include <vector>

#include "cutegen/cutegen.hpp"
#include "cutegen/dynamic.hpp"

namespace cutegen
{
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// scaled_basis.hpp - Public API
//
////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @brief Class to represent a scaled basis
 *
 * The template parameter pack represents the types that the scaled value can
 * hold. By convention, the first type in the parameter pack is assumed to be
 * the static (integral) type. The most commonly used parameter packs are
 * expected to be <int> and <int, dynamic_t>, but other packs may be possible
 * in the future.
 */
template <class... TValueTypes>
struct scaled_basis_t
{
public:
    using mode_value_t    = int;
    using vector_t        = std::vector<mode_value_t>;
    using value_types_t   = std::tuple<TValueTypes...>;
    using value_variant_t = std::variant<TValueTypes...>;
    using int_t =
        typename detail::find_type_or<void, std::is_integral, value_types_t>::type;
    using dynamic_type_t =
        typename detail::variant_has_type_derived_from<value_variant_t, dynamic_t>::type_t;

    static_assert(sizeof...(TValueTypes) > 0);
    static_assert(std::is_integral<int_t>::value);

    static constexpr bool can_have_dynamic_value =
        detail::variant_has_type_derived_from<value_variant_t, dynamic_t>::value;

private:
    // modes_ holds the mode index at every depth level.
    // This is similar to how the E type is used in CUTLASS-C++,
    // see include/cute/numeric/arithmetic_tuple.hpp.
    // For example, if modes_ = {0,1}, this corresponds to ((0,1,0,...),0,...).
    vector_t        modes_;
    value_variant_t value_;

public:
    /// Constructor taking an integer mode.
    template <class T>
    scaled_basis_t(const int mode, const T value);
    /// Constructor taking a vector mode for creating a hierarchical basis element.
    template <class T>
    scaled_basis_t(vector_t modes, const T value);
    /// Equality operator.
    bool operator==(const scaled_basis_t& other) const;
    /// Inequality operator.
    bool operator!=(const scaled_basis_t& other) const;

    /// Static factory for unit basis elements (value=1) with given mode indices.
    ///   E()    == 1                                     — collapses to scalar (returns int)
    ///   E(0)   == sb(0, 1) == (1,0,0,...)                — uses (int mode, T value) ctor
    ///   E(0,0) == sb({0, 0}, 1) == ((1,0,0,...),0,0,...) — uses (vector_t modes, T value) ctor
    ///   More examples in the test/scaled_basis_test.cpp file.
    template <class... AdditionalModes>
    static scaled_basis_t E(mode_value_t mode0, AdditionalModes... modes)
    {
        return scaled_basis_t(vector_t{mode0, modes...}, 1);
    }

public:
    /**
     * @brief Checks whether a scaled basis is static.
     *
     * A scaled_basis_t is static if the held type of the value is not derived
     * from dynamic_t. Note that @a modes_ is always statically known.
     */
    bool is_static() const;
    /// Checks whether the value is an integer, i.e statically known.
    bool value_holds_int() const;
    /// Checks whether the value is dynamic.
    bool value_holds_dynamic() const;
    /// Returns a variant value that could be an instance of any value type.
    const value_variant_t& value() const;
    /// Returns a variant value that could be an instance of any value type.
    value_variant_t& value();
    /// Returns the value assuming it is a statically known integer.
    int_t static_integral_value() const;
    /// Returns the value assuming it is a dynamic value.
    auto dynamic_value() const;
    /// Gets the vector describing the mode associated with the basis element.
    const vector_t& modes() const;
    /**
     * @brief Return a copy of this instance, but with code generation state
     *        cleared, so that traced functions do not generate code.
     */
    scaled_basis_t without_codegen() const;

private:
    /// Returns the depth associated with the basis element.
    int depth() const { return modes_.size(); }
};
/// Empty-args E(): collapses to scalar 1
/// The variadic E(mode0, ...) lives in the dispatch headers because it must
/// reference the context-specific `scaled_basis` type.
inline int E() { return 1; }

/// Type trait to check whether a type is a scaled basis type.
template <class T>
struct is_scaled_basis : std::false_type
{};

/// Type trait to check whether a type is a scaled basis type.
template <class... TValueTypes>
struct is_scaled_basis<scaled_basis_t<TValueTypes...>> : std::true_type
{};

/// Output stream insertion.
template <class... TValueTypes, std::enable_if_t<sizeof...(TValueTypes) != 0, bool> = true>
std::ostream& operator<<(std::ostream& os, const scaled_basis_t<TValueTypes...>& sb);

/// Gets the mode in `t` associated with the basis element `sb`.
template <class TTuple, class... TValueTypes>
auto basis_get(const scaled_basis_t<TValueTypes...>& sb, const TTuple& t);

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// scaled_basis.hpp - Implementation and internals
//
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail
{
/// Specialization of detail::cg_from_chars<> for the scaled_basis_t type.
template <class... TValueTypes>
class cg_from_chars<scaled_basis_t<TValueTypes...>> : public cg_from_chars_base<scaled_basis_t<TValueTypes...>>
{
public:
    using sb_t            = scaled_basis_t<TValueTypes...>;
    using mode_value_t    = typename sb_t::mode_value_t;
    using value_variant_t = typename sb_t::value_variant_t;
    using int_t           = typename sb_t::int_t;
    cg_from_chars(const char* first, const char* last, bool must_consume_all) :
        cg_from_chars_base<sb_t>(first, last, must_consume_all)
    {
        auto val = this->template parse_type<value_variant_t>();
        if(!val.has_value())
        {
            // Error: could not parse scaled basis value
            return;
        }
        auto at = this->template parse_type<token_ampersand>();
        if(!at.has_value())
        {
            // Error: no @ after value. (Could be raw integer?)
            return;
        }
        using sep_vec_t = token_separated_vector<token_ampersand, mode_value_t>;
        auto modes      = this->template parse_type<sep_vec_t>();
        if(!modes.has_value())
        {
            // Error: no modes found
            return;
        }
        // CuTe-C++ prints E<0,1> (for example) as 1@1@0 (right to left). modes is a 1-to-1
        // representation of the template parameter list so we need to reverse modes when
        // constructing the scaled_basis_t.
        std::reverse(modes.value().values.begin(), modes.value().values.end());
        this->set_value_with_check(sb_t(modes.value().values, val.value()));
    }
};

/**
 * @brief Converts a scaled_basis_t to a std::string.
 *
 * From CuTe-C++:
 *
 * ```
 * E<0,0> := ((1,0,0,...),0,0,...)
 * E<0,1> := ((0,1,0,...),0,0,...)
 * E<1,0> := (0,(1,0,0,...),0,...)
 * ```
 *
 * `std::cout << E<0,1>{} << std::endl` prints `1@1@0`.
 *
 * The @a modes_ member of scaled_basis_t is in the same order as the template arguments from left
 * to right. Therefore, to be consistent, we need to build the string representation from right to
 * left.
 *
 * @see scaled_basis_t
 */
template <class TScaledBasis>
struct value_to_string<TScaledBasis,
                       std::enable_if_t<is_scaled_basis<TScaledBasis>::value>>
{
    using sb_t = TScaledBasis;
    static std::string to_str(const sb_t& sb)
    {
        std::string str = to_string(sb.value());
        str += "@";
        const auto& v = sb.modes();
        assert(!v.empty());
        for(auto it = v.crbegin(); it != v.crend(); it++)
        {
            str += to_string(*it);
            if(std::next(it) != v.crend())
                str += "@";
        }
        return str;
    }
};

// encode() implementation (scaled_basis_t type)
// Encoding: [ modes_.size() ] [ modes_[0] ] [ modes_[1] ] ... [value_]
template <class... TValueTypes>
struct value_encoder<scaled_basis_t<TValueTypes...>>
{
    using sb_t            = scaled_basis_t<TValueTypes...>;
    using vector_t        = typename sb_t::vector_t;
    using value_variant_t = typename sb_t::value_variant_t;
    template <class TBuffer>
    static void encode_value(const sb_t& sb, TBuffer& buffer)
    {
        // Use the standard vector and variant encode methods
        encode(buffer, sb.modes());
        encode(buffer, sb.value());
    }
};

// specialization of value_decoder<> for scaled_basis_t
template <class... TValueTypes>
struct value_decoder<scaled_basis_t<TValueTypes...>>
{
    using sb_t = scaled_basis_t<TValueTypes...>;
    template <class TIterator>
    static std::optional<sb_t> decode_value(TIterator& it, const TIterator& end)
    {
        const auto sz = decode<uint32_t>(it, end);
        if(!sz.has_value()) return {};
        typename sb_t::vector_t modes;
        for(unsigned i = 0; i < sz; i++)
        {
            const auto mode = decode<int>(it, end);
            if(!mode.has_value()) return {};
            modes.push_back(mode.value());
        }
        // The variant type used to represent the scale value:
        using var_t = typename sb_t::value_variant_t;
        auto sval   = decode<var_t>(it, end);
        if(!sval.has_value())
            return {};
        return sb_t(modes, sval.value());
    }
};
} // namespace detail

template <class... TValueTypes>
template <class T>
scaled_basis_t<TValueTypes...>::scaled_basis_t(const int mode, const T value) :
    modes_(1, mode), value_(value) {}

template <class... TValueTypes>
template <class T>
scaled_basis_t<TValueTypes...>::scaled_basis_t(vector_t modes, const T value) :
    modes_(std::move(modes)), value_(value)
{
    // An empty modes_ member is invalid
    assert(!modes_.empty());
}

template <class... TValueTypes>
bool scaled_basis_t<TValueTypes...>::is_static() const
{
    if constexpr(!detail::variant_has_type_derived_from<value_variant_t, dynamic_t>::value)
    {
        return true;
    }
    else
    {
        using dyn_t = typename detail::find_in_tuple<value_types_t, has_dynamic_t_base>::value;
        return !std::holds_alternative<dyn_t>(value_);
    }

    CUTEGEN_GCC_UNREACHABLE;
}

template <class... TValueTypes>
bool scaled_basis_t<TValueTypes...>::value_holds_int() const
{
    return std::holds_alternative<int_t>(value_);
}

template <class... TValueTypes>
bool scaled_basis_t<TValueTypes...>::value_holds_dynamic() const
{
    if constexpr(!detail::variant_has_type_derived_from<value_variant_t, dynamic_t>::value)
    {
        return false;
    }
    else
    {
        using dyn_t = typename detail::find_in_tuple<value_types_t, has_dynamic_t_base>::value;
        return std::holds_alternative<dyn_t>(value_);
    }

    CUTEGEN_GCC_UNREACHABLE;
}

template <class... TValueTypes>
const typename scaled_basis_t<TValueTypes...>::value_variant_t& scaled_basis_t<TValueTypes...>::value() const
{
    return value_;
}

template <class... TValueTypes>
typename scaled_basis_t<TValueTypes...>::value_variant_t& scaled_basis_t<TValueTypes...>::value()
{
    return value_;
}

template <class... TValueTypes>
typename scaled_basis_t<TValueTypes...>::int_t scaled_basis_t<TValueTypes...>::static_integral_value() const
{
    assert(is_static());
    return std::get<int_t>(value_);
}

template <class... TValueTypes>
auto scaled_basis_t<TValueTypes...>::dynamic_value() const
{
    static_assert(can_have_dynamic_value);
    using dyn_t = typename detail::find_in_tuple<value_types_t, has_dynamic_t_base>::value;
    assert(std::holds_alternative<dyn_t>(value_));
    return std::get<dyn_t>(value_);
}

template <class... TValueTypes>
const typename scaled_basis_t<TValueTypes...>::vector_t& scaled_basis_t<TValueTypes...>::modes() const
{
    return modes_;
}

template <class... TValueTypes>
inline scaled_basis_t<TValueTypes...> scaled_basis_t<TValueTypes...>::without_codegen() const
{
    using sb_t = scaled_basis_t<TValueTypes...>;
    return sb_t(modes(), visit(detail::without_codegen_leaf_visitor<value_variant_t>{}, value()));
}

template <class... TValueTypes>
bool scaled_basis_t<TValueTypes...>::operator==(const scaled_basis_t& other) const
{
    return (modes_ == other.modes()) && (value_ == other.value_);
}

template <class... TValueTypes>
bool scaled_basis_t<TValueTypes...>::operator!=(const scaled_basis_t& other) const
{
    return !((*this) == other);
}

template <class... TValueTypes, std::enable_if_t<sizeof...(TValueTypes) != 0, bool>>
std::ostream& operator<<(std::ostream& os, const scaled_basis_t<TValueTypes...>& sb)
{
    os << to_string(sb);
    return os;
}

template <class TTuple, class... TValueTypes>
auto basis_get(const scaled_basis_t<TValueTypes...>& sb, const TTuple& t)
{
    auto& modes = sb.modes();
    return t.get(modes);
}
} // namespace cutegen
#endif
