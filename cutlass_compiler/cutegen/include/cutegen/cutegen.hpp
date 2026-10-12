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

#if !defined(CUTEGEN_HPP_INCLUDED_)
#define CUTEGEN_HPP_INCLUDED_

#include <algorithm>
#include <cassert>
#include <cstdint>
#include <cstring>
#include <iterator>
#include <limits>
#include <optional>
#include <cstddef>
#include <string>
#include <system_error>
#include <tuple>
#include <type_traits>
#include <utility>
#include <variant>
#include <vector>

#include "cutegen/charconv.hpp"

// Taken from CuTe-C++
// Some versions of GCC < 11 have trouble deducing that a
// function with "auto" return type and all of its returns in an "if
// constexpr ... else" statement must actually return.  Thus, GCC
// emits spurious "missing return statement" build warnings.
// Developers can suppress these warnings by using the
// CUTEGEN_GCC_UNREACHABLE macro, which must be followed by a semicolon.
// It's harmless to use the macro for other GCC versions or other
// compilers, but it has no effect.
#if !defined(CUTEGEN_GCC_UNREACHABLE)
#if defined(__clang__) || defined(__GNUC__)
#define CUTEGEN_GCC_UNREACHABLE __builtin_unreachable()
#else
#define CUTEGEN_GCC_UNREACHABLE
#endif
#endif

/// cutegen namespace.
namespace cutegen
{
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// cutegen.hpp - Public API
//
////////////////////////////////////////////////////////////////////////////////////////////////////

/// Backports C++-20's `remove_cvref_t`.
template <class T>
using remove_cvref_t = std::remove_cv_t<std::remove_reference_t<T>>;

/// Struct to compute the size of `T` in bits.
template <class T>
struct sizeof_bits
{
    static constexpr size_t value = sizeof(T) * 8;
};

/// Specialization of `sizeof_bits` for `const T`.
template <class T>
struct sizeof_bits<const T> : sizeof_bits<T>
{};

/// Specialization of `sizeof_bits` for `void`.
template <>
struct sizeof_bits<void>
{
    static constexpr size_t value = 0;
};

/// Specialization of `sizeof_bits` for `bool`.
template <>
struct sizeof_bits<bool>
{
    static constexpr size_t value = 1;
};

/// Helper variable template for `sizeof_bits`.
template <class T>
static constexpr size_t sizeof_bits_v = sizeof_bits<T>::value;

//
// To/from string
//

/// Generates a string representation of `t`.
template <class T>
[[nodiscard]] std::string to_string(const T& t);

/// Attempts to parse the given string into an instance of `T`.
template <class T, class TString>
std::optional<T> from_string(const TString& str);

/// Attempts to parse the given string into an instance of `T`.
template <class T>
std::optional<T> from_string(const char* str);

//
// Encode / decode
//

/// Encodes the value `t` into the provided buffer.
template <class T, class TBuffer>
void encode(TBuffer& buf, const T& t);

/**
 * @brief Attempts to decode the buffer @p buf into an instance of `T`.
 *
 * `buf` must support a `begin()` and `end()` method returning an iterator.
 */
template <class T, class TBuffer>
std::optional<T> decode(const TBuffer& buf);

/// Overload of `decode` for a buffer provided via a `begin` and `end` iterators.
template <class T, class TIterator>
std::optional<T> decode(TIterator& it, const TIterator& end);

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// cutegen.hpp - Implementation and internals
//
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail
{

/// Struct resolving the widest type among a list of types.
template <class T, class... Ts>
struct find_widest_integral_type
{
private:
    using other_type = typename find_widest_integral_type<Ts...>::type;

public:
    using type = typename std::conditional<sizeof(T) >= sizeof(other_type), T, other_type>::type;
};

/// Base case specialization of find_widest_integral_type.
template <class T>
struct find_widest_integral_type<T>
{
    using type = T;
};

/// Checks at runtime whether it is safe to cast `x` from `TFrom` to `TTo`.
template <class TFrom, class TTo>
bool is_integral_cast_safe(const TFrom x)
{
    return (static_cast<TFrom>(static_cast<TTo>(x)) == x);
}

template <size_t, bool...>
struct find_in_tuple_index
{};
template <size_t I, bool... Bs>
struct find_in_tuple_index<I, false, Bs...> : public find_in_tuple_index<I + 1, Bs...>
{};
template <size_t I, bool... Bs>
struct find_in_tuple_index<I, true, Bs...> : public std::integral_constant<std::size_t, I>
{};

// Find the first type in a tuple that satisfies the given predicate.
template <class Tuple, template <class> class TPredicate>
struct find_in_tuple;

template <class... TupleTypes, template <class> class TPredicate>
struct find_in_tuple<std::tuple<TupleTypes...>, TPredicate>
{
    static constexpr const size_t index = detail::find_in_tuple_index<0,
                                                                      TPredicate<TupleTypes>::value...>::value;
    using value                         = std::tuple_element_t<index, std::tuple<TupleTypes...>>;
};

/// Template function to find a type within another type that satisfies a given
/// predicate, with a default type if one is not found.
template <class TDefault,
          template <class>
          class TPredicate,
          class T,
          class TEnable = void>
struct find_type_or;

/// Specialization for the empty tuple type.
template <class TDefault,
          template <class>
          class TPredicate>
struct find_type_or<TDefault, TPredicate, std::tuple<>>
{
    using type = TDefault;
};

/// Specialization for tuple types.
template <class TDefault,
          template <class>
          class TPredicate,
          class TType,
          class... TTupleTypes>
struct find_type_or<TDefault, TPredicate, std::tuple<TType, TTupleTypes...>>
{
    using type = typename std::conditional<TPredicate<TType>::value,
                                           TType,
                                           typename find_type_or<TDefault,
                                                                 TPredicate,
                                                                 std::tuple<TTupleTypes...>>::type>::type;
};

/// Specialization for std::variant.
template <class TDefault,
          template <class>
          class TPredicate,
          class TType,
          class... TVariantTypes>
struct find_type_or<TDefault, TPredicate, std::variant<TType, TVariantTypes...>>
{
    using type = typename std::conditional<TPredicate<TType>::value,
                                           TType,
                                           typename find_type_or<TDefault,
                                                                 TPredicate,
                                                                 std::tuple<TVariantTypes...>>::type>::type;
};

/// Struct that filters out types in a tuple that do not satisfy a predicate TPred.
template <template <class...> class TPred, class TTuple>
struct filter_types_in_tuple;

template <template <class...> class TPred>
struct filter_types_in_tuple<TPred, std::tuple<>>
{
    using type = std::tuple<>;
};

template <template <class...> class TPred, class TType, class... TTypes>
struct filter_types_in_tuple<TPred, std::tuple<TType, TTypes...>>
{
    using recursive_type = typename filter_types_in_tuple<TPred, std::tuple<TTypes...>>::type;
    // std::declval used so that this works when TType has no default constructor
    using type = typename std::conditional<
        TPred<TType>::value,
        decltype(std::tuple_cat(std::declval<std::tuple<TType>>(), std::declval<recursive_type>())),
        recursive_type>::type;
};

/**
 * @brief Struct that removes types in TTupleB from TTupleA.
 *
 * @pre The set of types in TTupleA is a superset of the set of types in TTupleB
 */
template <class TTupleA, class TTupleB>
struct tuple_types_diff;

template <class TTupleB>
struct tuple_types_diff<std::tuple<>, TTupleB>
{
    using type = std::tuple<>;
};

template <class TTupleB, class TType, class... TTypes>
struct tuple_types_diff<std::tuple<TType, TTypes...>, TTupleB>
{
    using recursive_type = typename tuple_types_diff<std::tuple<TTypes...>, TTupleB>::type;

    template <class T>
    struct is_type : std::is_same<TType, T>
    {};
    using type_or_void = typename find_type_or<void, is_type, TTupleB>::type;

    using type = typename std::conditional<
        std::is_same_v<type_or_void, void>,
        decltype(std::tuple_cat(std::declval<std::tuple<TType>>(), std::declval<recursive_type>())),
        recursive_type>::type;
};

// Generic declaration to be specialized
template <class TTuple, class TType>
struct tuple_has_type;

/// Type trait to check whether a tuple has a type `TType`.
template <class... TTupleTypes, class TType>
struct tuple_has_type<std::tuple<TTupleTypes...>, TType>
{
    using tuple_t               = std::tuple<TTupleTypes...>;
    static constexpr bool value = (std::is_same<TType, TTupleTypes>::value || ...);
};

// Generic declaration to be specialized
template <class TTuple, class TType>
struct tuple_is_convertible_from_type;

/// Type trait to check whether a tuple has a type `TType`.
template <class... TTupleTypes, class TType>
struct tuple_is_convertible_from_type<std::tuple<TTupleTypes...>, TType>
{
    using tuple_t               = std::tuple<TTupleTypes...>;
    static constexpr bool value = (std::is_convertible<TType, TTupleTypes>::value || ...);
};

// Generic declaration to be specialized
template <class T, template <class> class TPredicate>
struct tuple_has_type_pred;

/// Type trait to check whether a tuple of types has a type that satisfies a predicate.
template <class... TTupleTypes, template <class> class TPredicate>
struct tuple_has_type_pred<std::tuple<TTupleTypes...>, TPredicate>
{
    using tuple_t               = std::tuple<TTupleTypes...>;
    static constexpr bool value = (TPredicate<TTupleTypes>::value || ...);
};

/// Type trait to check whether a type is a std::variant type.
template <class T>
struct is_variant : std::false_type
{};

/// Type trait to check whether a type is a std::variant type.
template <class... TVarElemTypes>
struct is_variant<std::variant<TVarElemTypes...>> : std::true_type
{};

template <class Type, class... VTypes>
constexpr bool variant_can_hold_type(const std::variant<VTypes...>& v)
{
    return (std::is_same_v<Type, VTypes> || ...);
}

// Generic declaration to be specialized
template <class T, class TBase>
struct variant_has_type_derived_from;

/// Type trait to check whether a variant can hold a type derived from `TBase`.
template <class TBase>
struct variant_has_type_derived_from<std::variant<>, TBase>
{
    static constexpr bool value = false;
    using type_t                = void;
};

template <class TBase, class TThisElemType, class... TRemainingElemTypes>
struct variant_has_type_derived_from<std::variant<TThisElemType, TRemainingElemTypes...>, TBase>
{
    static constexpr bool value = std::is_base_of<
                                      TBase,
                                      TThisElemType>::value ||
                                  variant_has_type_derived_from<
                                      std::variant<TRemainingElemTypes...>,
                                      TBase>::value;
    using type_t = std::conditional_t<
        std::is_base_of<TBase, TThisElemType>::value,
        TThisElemType,
        typename variant_has_type_derived_from<std::variant<TRemainingElemTypes...>, TBase>::type_t>;
};

// To be specialized
template <class TValue, class TEnable = void>
struct value_encoder;

/**
 * @brief Struct to provide type-specific decoding from a binary buffer representation.
 *
 * To be specialized.
 *
 * Types held by cutegen::rec_var and std::variant must have support for serialization into a binary
 * stream if they are to be used with the cutegen encode() and decode() functions. These types
 * provide support via specializations of the value_decoder structure.
 *
 * Specializations of the value_decoder struct should provide a static decode_value() method that
 * takes a pair of iterators (start and end). The iterator type is usually a template type that
 * supports random access to a byte type, with std::vector<char>::iterator being a canonical
 * example.
 *
 * The return value is std::optional<TValue>. If the decode was successful, the returned
 * std::optional instance will hold the parse value. If the decode was not successful, the returned
 * std::optional will not hold a value. The start iterator will be incremented for non-empty types
 * that consume bytes from the input.
 */
template <class TValue, class TEnable = void>
struct value_decoder;

/// Specialization of value_encoder() for empty types (no data is inserted).
template <class TEmpty>
struct value_encoder<TEmpty, std::enable_if_t<std::is_empty<TEmpty>::value>>
{
    template <class TBuffer>
    static void encode_value(const TEmpty& /*val*/, TBuffer& /*buffer*/)
    {
        // No data encoded for empty types
    }
};

/// Specialization of value_encoder for integral types.
template <class TValue>
struct value_encoder<TValue, std::enable_if_t<std::is_integral_v<TValue>>>
{
    template <class TBuffer>
    static void encode_value(const TValue& val, TBuffer& buffer)
    {
        buffer.insert(buffer.end(),
                      reinterpret_cast<const char*>(&val),
                      reinterpret_cast<const char*>(&val) + sizeof(val));
    }
};

/// Specialization of value_encoder for vector types.
template <class TElem>
struct value_encoder<std::vector<TElem>>
{
    using vector_t = std::vector<TElem>;
    using value_t  = typename vector_t::value_type;
    template <class TBuffer>
    static void encode_value(const std::vector<TElem>& v, TBuffer& buffer)
    {
        // Add the vector size to the buffer. Truncate to 32 bits to save space.
        assert(v.size() <= std::numeric_limits<uint32_t>::max());
        auto sz = static_cast<uint32_t>(v.size());
        value_encoder<uint32_t>::encode_value(sz, buffer);
        for(auto& e : v)
        {
            // Recursively encode each vector element
            value_encoder<value_t>::encode_value(e, buffer);
        }
    }
};

/// Specialization of value_encoder for variant types.
template <class... TVarElemTypes>
struct value_encoder<std::variant<TVarElemTypes...>>
{
    template <class TBuffer>
    static void encode_value(const std::variant<TVarElemTypes...>& v, TBuffer& buffer)
    {
        // Variant index is size_t, but truncate to 32 bits to use less space.
        value_encoder<uint32_t>::encode_value(static_cast<uint32_t>(v.index()), buffer);
        // The visit() function will invoke the lambda with the specific variant
        // type held by the variant.
        std::visit([&](auto&& vt) //
                   {
                       using var_type_t = typename std::remove_const_t<std::remove_reference_t<decltype(vt)>>;
                       value_encoder<var_type_t>::encode_value(std::forward<decltype(vt)>(vt),
                                                               buffer);
                   },
                   v);
    }
};

/// Specialization of value_encoder for std::optional.
// Encode std::optional as:
// 4 bytes: 1 (present) or 0 (not present)
// if present, encode contained type
template <class TOptionalType>
struct value_encoder<std::optional<TOptionalType>>
{
    template <class TBuffer>
    static void encode_value(const std::optional<TOptionalType>& opt, TBuffer& buffer)
    {
        value_encoder<uint32_t>::encode_value(opt.has_value() ? 1 : 0, buffer);
        if(opt.has_value())
        {
            value_encoder<TOptionalType>::encode_value(opt.value(), buffer);
        }
    }
};

/// Specialization of value_decoder for integral types.
template <class TValue>
struct value_decoder<TValue, std::enable_if_t<std::is_integral_v<TValue>>>
{
    template <class TIterator>
    static std::optional<TValue> decode_value(TIterator& it, const TIterator& end)
    {
        if(std::distance(it, end) < static_cast<int>(sizeof(TValue)))
        {
            return {};
        }
        else
        {
            TValue v;
            std::memcpy(&v, &(*it), sizeof(TValue));
            it += sizeof(TValue);
            return {v};
        }
    }
};

/// Specialization of value_decoder for empty types.
template <class TEmpty>
struct value_decoder<TEmpty, std::enable_if_t<std::is_empty_v<TEmpty>>>
{
    template <class TIterator>
    static std::optional<TEmpty> decode_value(TIterator& /*it*/, const TIterator& /*end*/)
    {
        return TEmpty{};
    }
};

/// Specialization of value_decoder for std::optional types
template <class TValueType>
struct value_decoder<std::optional<TValueType>>
{
    template <class TIterator>
    static std::optional<std::optional<TValueType>> decode_value(TIterator&       it,
                                                                 const TIterator& end)
    {
        // Decode the boolean indicating whether or not the optional has a value
        auto has_val = value_decoder<uint32_t>::decode_value(it, end);
        if(!has_val.has_value())
        {
            // Return an optional holding an optional without a value...
            return std::nullopt;
        }
        // If the encode "has_value" flag is 1, we need to read the value next
        if(has_val.value() != 0)
        {
            auto opt_val = value_decoder<TValueType>::decode_value(it, end);
            if(!opt_val.has_value())
            {
                // Decoded a flag indicating there should be a value, but
                // decoding the value failed. Return an optional that does
                // not hold a value to signal failure.
                return std::nullopt;
            }
            else
            {
                return std::optional(opt_val);
            }
        }
        else
        {
            return std::optional<TValueType>{};
        }
    }
};

// The value_decoder specialization for variants is implemented using a switch
// statement with an arbitrary upper bound on the number of variant types. This
// function is called with the constexpr switch case value as an integer
// template parameter, and uses `if constexpr` to avoid attempting to invoke the
// decoder for a variant alternative index that is greater than the maximum
// index defined for variant type.
template <class TVariant, uint32_t Index, class TIterator>
std::optional<TVariant> decode_variant_from_index(TIterator& it, const TIterator& itEnd)
{
    if constexpr(Index < std::variant_size_v<TVariant>)
    {
        using var_type_t = typename std::variant_alternative_t<Index, TVariant>;
        return decode<var_type_t>(it, itEnd);
    }
    else
    {
        return std::nullopt;
    }

    CUTEGEN_GCC_UNREACHABLE;
}

/**
 * @brief Decode a std::variant by decoding the index and dispatching to the type decoder.
 *
 * Generate a variant instance from the binary storage representation created by the encode()
 * function. See comments for the encode() function for details on the (simple) format.
 *
 * The implementation requires functionality similar to that of the std::variant visit() function,
 * but instead of dispatching on the index of an existing variant, we want to dispatch on the
 * serialized index, before a variant is instantiated.
 *
 * We use an easily extensible fixed upper bound on the number of variant types.
 */
template <class TVar>
struct value_decoder<TVar, std::enable_if_t<is_variant<TVar>::value>>
{
    template <class TIterator>
    static std::optional<TVar> decode_value(TIterator& it, const TIterator& end)
    {
        // Expand the switch statement below if we get variants with more alternative types
        static_assert(std::variant_size_v<TVar> < 9);
        auto index = decode<uint32_t>(it, end);
        if(!index.has_value())
        {
            return std::nullopt;
        }
        switch(index.value())
        {
        case 0: return decode_variant_from_index<TVar, 0>(it, end);
        case 1: return decode_variant_from_index<TVar, 1>(it, end);
        case 2: return decode_variant_from_index<TVar, 2>(it, end);
        case 3: return decode_variant_from_index<TVar, 3>(it, end);
        case 4: return decode_variant_from_index<TVar, 4>(it, end);
        case 5: return decode_variant_from_index<TVar, 5>(it, end);
        case 6: return decode_variant_from_index<TVar, 6>(it, end);
        case 7: return decode_variant_from_index<TVar, 7>(it, end);
        }
        return std::nullopt;
    }
};

template <class TValue, class TEnable = void>
struct value_to_string;

/// Specialization of value_to_string for integral types.
template <class T>
struct value_to_string<T, std::enable_if_t<std::is_integral_v<T>>>
{
    static std::string to_str(T t)
    {
        return std::to_string(t);
    }
};
/// Specialization of value_to_string for std::variant types.
template <class T>
struct value_to_string<T, std::enable_if_t<is_variant<T>::value>>
{
    static std::string to_str(const T& t)
    {
        return std::visit([&](auto&& vt) //
                          {
                              using var_type_t = typename std::remove_const_t<std::remove_reference_t<decltype(vt)>>;
                              return value_to_string<var_type_t>::to_str(vt);
                          },
                          t);
    }
};

template <class TStringIterator>
TStringIterator find_non_whitespace(const TStringIterator& begin,
                                    const TStringIterator& end)
{
    return std::find_if(begin,
                        end,
                        [](unsigned char c) //
                        {
                            return !std::isspace(c);
                        });
}

template <class TStringIterator>
TStringIterator find_non_identifier(const TStringIterator& begin,
                                    const TStringIterator& end)
{
    // Check for empty string
    if(begin == end)
        return begin;
    // First character must be an underscore or a letter (lower or upper)
    if(!std::isalpha(*begin) && ('_' != *begin))
        return begin;
    // Subsequent characters can be underscore, letter, or digit.
    return std::find_if(begin,
                        end,
                        [](unsigned char c) //
                        {
                            return !std::isalnum(c) && (c != '_');
                        });
}

// Forward declaration of parse_from_chars_advance, used by from_chars_base.
template <class T>
std::optional<T>
parse_from_chars_advance(const char*& begin, const char* end);

/**
 * @brief Base class for parsers used to generate cutegen objects from strings
 *
 * @tparam T Type of value to parse
 *
 * The cutegen parsing framework is loosely based on the C++ standard library
 * from_chars() function. Upon return from cg_from_chars(), the
 * from_chars_result structure contains a pointer to the first part of
 * the input string that DOES NOT match the expected pattern for a type (e.g.
 * integers or floating point numbers in the standard C++ library).
 *
 * Cutegen uses classes that group a from_chars_result structure with
 * a std::optional that holds the type to be parsed. If parsing was successful,
 * the std::optional will hold a value of the type, and the error code (ec
 * member of from_chars_result) will be equal to the default-initialized enum
 * std::errc{}.
 *
 * The from_chars_base class takes a template type T for the type being parsed,
 * and defines storage for an instance of from_chars_result and
 * std::optional<T>. The constructor takes pointers to the string range to be
 * considered for parsing, and an additional boolean that indicates whether or
 * not the entire input must be "consumed" for the parse to be considered
 * successful.
 * Whether or not the entire input string should be consumed depends on the
 * parsing context. For example, a top-level API function that intends to parse
 * an integer would must likely want to return an error if the input string
 * was "1024qzv", due to the extra "qzv" at the end of the string. However, in
 * other situations, we may want parsing to just provide the next character to
 * be parsed as other (subsequent) values. For example, with a string "3 4 5",
 * we might like the parse to parse the value 3 and advance the pointer to the
 * '4' character as part of a larger string.
 *
 * Derived classes should implement parsing functionality in the constructor. At
 * the completion of the constructor, the from_chars_result and optional value
 * should be set to reflect whether a value was parsed, and where the "current"
 * string pointer is. This string pointer can represent the location of the
 * parse failure (if parsing was not successful) or the location to continue
 * parsing (if the parsing was successful).
 *
 * The cg_from_chars_base class constructor initializes the from_chars_result
 * member to have an error code of std::errc::invalid_argument. Derived classes
 * must set the std::optional value using the set_value_with_check() function.
 * This function takes an argument of the type being parsed, and checks the
 * current pointer along with the must_consume_all value to determine whether or
 * not to actually assign the value. (If must_consume_all is true, and the
 * pointer is not at the end of the input string, the std::optional value will
 * not be set, and the error code will remain std::errc::invalid_argument.)
 *
 * In general, derived classes should accept strings with leading whitespace
 * and consume trailing whitespace by advancing the string pointer to the
 * next non-whitespace character.
 */
template <class T>
class cg_from_chars_base
{
public:
    using optional_t = std::optional<T>;
    const optional_t&        parse_value() const { return value_; }
    const from_chars_result& parse_result() const { return result_; }

protected:
    cg_from_chars_base(const char* first, const char* last, bool must_consume_all) :
        result_{first, std::errc::invalid_argument},
        last_(last),
        must_consume_all_(must_consume_all)
    {
    }
    const char* get_ptr() const
    {
        return result_.ptr;
    }
    void set_ptr(const char* p)
    {
        result_.ptr = p;
    }
    bool at_end()
    {
        return (result_.ptr == last_);
    }
    void set_value_with_check(const T& v)
    {
        if(!must_consume_all_ || (result_.ptr == last_))
        {
            value_     = v;
            result_.ec = std::errc{};
        }
    }
    void set_value_with_check(T&& v)
    {
        if(!must_consume_all_ || (result_.ptr == last_))
        {
            value_     = std::move(v);
            result_.ec = std::errc{};
        }
    }
    // Parse a "sub-element" for the type being parsed. For example, a type that
    // consists of 3 integers might call this function for each integer.
    template <class TType>
    std::optional<TType> parse_type()
    {
        // Attempt to parse the type, updating the pointer currently stored in
        // the from_chars_result.
        return detail::parse_from_chars_advance<TType>(result_.ptr,
                                                       last_);
    }
    // Parse a "sub-element", with an explicit end argument. This can be used to
    // constrain a parsing region.
    template <class TType>
    std::optional<TType> parse_type_up_to(const char* end)
    {
        // Attempt to parse the type, updating the pointer currently stored in
        // the from_chars_result.
        return detail::parse_from_chars_advance<TType>(result_.ptr,
                                                       end);
    }
    void skip_whitespace()
    {
        result_.ptr = detail::find_non_whitespace(result_.ptr, last_);
    }

private:
    from_chars_result result_;
    optional_t        value_;
    const char*       last_;
    bool              must_consume_all_;
};

/**
 * @brief Template class for parsers used to generate cutegen objects from strings
 *
 * @tparam T Type of value to parse
 * @tparam TEnable Type used to allow distinct specializations
 *
 * Internal class used for string parsing. Specializations of this class
 * should have:
 * - A constructor that takes const char* first and last arguments
 * - A parse_value() function that returns a const reference to a
 *       std::optional<T>
 * - A parse_result() function that returns a reference to an instance of the
 *       from_chars_result structure.
 */
template <class T, class TEnable = void>
class cg_from_chars;

/**
 * @brief Structure to represent a single-character token in the parser
 *
 * @tparam T character to be parsed
 *
 */
template <char T>
struct char_token
{
    static constexpr char value = T;
    char_token()                = default;
};

using token_comma         = char_token<','>;
using token_lt            = char_token<'<'>;
using token_gt            = char_token<'>'>;
using token_question_mark = char_token<'?'>;
using token_underscore    = char_token<'_'>;
using token_lbrace        = char_token<'{'>;
using token_rbrace        = char_token<'}'>;
using token_eq            = char_token<'='>;
using token_ampersand     = char_token<'@'>;
using token_composition   = char_token<'o'>;
using token_fwd_slash     = char_token<'/'>;
using token_i             = char_token<'i'>;
using token_asterisk      = char_token<'*'>;

/**
 * @brief Structure to represent a generic keyword token in the parser
 *
 * This struct maintains a pointer a number of chracters that represent a
 * generic keyword or identifier in the input string.
 *
 */
struct token_keyword
{
    const char* ptr;
    ptrdiff_t   len;
    std::string get_string() const
    {
        return std::string(ptr, len);
    }
    bool operator==(const char* str) const
    {
        return ((len == static_cast<ptrdiff_t>(strlen(str))) &&
                (0 == strncmp(str, ptr, len)));
    }
    bool begins_with(const char* str) const
    {
        return (0 == strncmp(ptr, str, strlen(str)));
    }
};

/**
 * @brief Internal function used to parse a specific type
 *
 * @tparam T Type to be parsed
 * @arg begin Starting character pointer
 * @arg end End character pointer (beyond the last valid character)
 *
 * This function attempts to parse a value of type T, updating the
 * begin character pointer to the first part of the string that does
 * not match the type being parsed (for subsequent parsing).
 *
 */
template <class T>
std::optional<T>
parse_from_chars_advance(const char*& begin, const char* end)
{
    cg_from_chars<T> fc(begin, end, /* must_consume_all = */ false);
    // Return success if and only if the from_chars_result structure
    // has a default initialized error code (0).
    if(fc.parse_value().has_value())
    {
        // Return the parsed value and a pointer to the next character
        begin += (fc.parse_result().ptr - begin);
        return fc.parse_value();
    }
    return std::nullopt;
}

template <class T, class TIterator>
std::optional<T>
parse_from_chars_advance(TIterator& begin, TIterator end)
{
    return parse_from_chars_advance(&(*begin), &(*end), /* must_consume_all = */ false);
}

template <class T>
std::optional<T>
parse_from_chars(const char* begin, const char* end, bool must_consume_all = true)
{
    cg_from_chars<T> fc(begin, end, must_consume_all);
    return fc.parse_value();
}

// Specialization of the detail::cg_from_chars class for character tokens
template <char c>
class cg_from_chars<char_token<c>> : public cg_from_chars_base<char_token<c>>
{
public:
    static_assert(c != ' ');
    cg_from_chars(const char* first, const char* last, bool must_consume_all) :
        cg_from_chars_base<char_token<c>>(first, last, must_consume_all)
    {
        this->skip_whitespace();
        if(!this->at_end() && (*(this->get_ptr()) == c))
        {
            // Advance past the found character
            this->set_ptr(this->get_ptr() + 1);
            this->skip_whitespace();
            this->set_value_with_check(char_token<c>{});
        }
    }
};

// Specialization of the detail::cg_from_chars class for keyword tokens
template <>
class cg_from_chars<token_keyword> : public cg_from_chars_base<token_keyword>
{
public:
    cg_from_chars(const char* first, const char* last, bool must_consume_all) :
        cg_from_chars_base<token_keyword>(first, last, must_consume_all)
    {
        this->skip_whitespace();
        auto p0 = this->get_ptr();
        auto p1 = find_non_identifier(p0, last);
        if(p1 != p0)
        {
            auto nw = detail::find_non_whitespace(p1, last);
            this->set_ptr(nw);
            this->set_value_with_check(token_keyword{p0, p1 - p0});
        }
    }
};

// Try to parse each variant type until we find one that matches.
template <class TVariant, std::size_t I = 0>
std::tuple<std::optional<TVariant>, from_chars_result>
parse_variant_type(const char* first, [[maybe_unused]] const char* last, [[maybe_unused]] bool must_consume_all)
{
    using variant_t  = TVariant;
    using optional_t = std::optional<variant_t>;
    using pair_t     = std::pair<optional_t, from_chars_result>;
    using tuple_t    = std::tuple<std::optional<TVariant>, from_chars_result>;

    if constexpr(I < std::variant_size_v<variant_t>)
    {
        using vtype_t = std::variant_alternative_t<I, variant_t>;
        // Construct an object that will attempt to parse the current variant
        // type. On success, return the value. Otherwise, recurse to the next
        // variant type.
        cg_from_chars<vtype_t> fc(first, last, must_consume_all);
        return (fc.parse_value().has_value()) ?
                   static_cast<tuple_t>(pair_t{fc.parse_value().value(), fc.parse_result()}) :
                   parse_variant_type<variant_t, I + 1>(first, last, must_consume_all);
    }
    else
    {
        return pair_t{std::nullopt, from_chars_result{first, std::errc::invalid_argument}};
    }
}

// Specialization of the detail::from_chars class for std::variant
template <class... TVarElemTypes>
class cg_from_chars<std::variant<TVarElemTypes...>>
{
public:
    using variant_t  = std::variant<TVarElemTypes...>;
    using optional_t = std::optional<variant_t>;
    cg_from_chars(const char* first, const char* last, bool must_consume_all)
    {
        // Try to parse each variant type, starting with index 0
        std::tie(value_, result_) = parse_variant_type<variant_t>(first,
                                                                  last,
                                                                  must_consume_all);
    }
    const optional_t&        parse_value() { return value_; }
    const from_chars_result& parse_result() { return result_; }

private:
    from_chars_result result_;
    optional_t        value_;
};

template <class TSep, class TType>
struct token_separated_vector
{
    using vector_t = std::vector<TType>;
    vector_t values;
};

// Specialization of the detail::from_chars class for a vector of values
// separated by a token.
template <class TSep, class TType>
class cg_from_chars<token_separated_vector<TSep, TType>> : public cg_from_chars_base<token_separated_vector<TSep, TType>>
{
public:
    using token_sep_vec_t = token_separated_vector<TSep, TType>;
    using vector_t        = typename token_sep_vec_t::vector_t;
    cg_from_chars(const char* first, const char* last, bool must_consume_all) :
        cg_from_chars_base<token_sep_vec_t>(first, last, must_consume_all)
    {
        vector_t val_vec;
        while(true)
        {
            // A separator was found during the previous iteration, or this is
            // the first time through. Failure to parse a type should be
            // considered a parse failure.
            auto val = this->template parse_type<TType>();
            if(val.has_value())
            {
                val_vec.push_back(val.value());
                // Check for a separator. If one is not found, exit the loop.
                auto sep = this->template parse_type<TSep>();
                if(!sep.has_value())
                {
                    break;
                }
            }
            else
            {
                val_vec.resize(0);
                break;
            }
        }
        if(!val_vec.empty())
        {
            this->set_value_with_check(token_sep_vec_t{std::move(val_vec)});
        }
    }
};

// Forward declaration to allow declaring this visitor as friend in our types.
// We don't want non-const accessors. However, we also need to be able to set
// the mlir_dynamic_t instances from provided MLIR Values.
struct set_with_mlir_values_visitor;
struct nullify_dynamics_visitor;
struct reset_properties_to_default_visitor;

// helper type for visitor lambdas  (https://en.cppreference.com/w/cpp/utility/variant/visit)
template <class... Ts>
struct overload : Ts...
{
    using Ts::operator()...;
};
// explicit deduction guide (not needed as of C++20)
template <class... Ts>
overload(Ts...) -> overload<Ts...>;

// Trait to determine, at compile time, whether or not a type has a member
// function called without_codegen(), that takes no arguments.
// Default case: doesn't have the member function without_codegen()
template <typename T, typename = void>
struct has_without_codegen_member_fn : std::false_type
{};

// Specialization: if decltype(std::declval<T>().without_codegen()) is valid, this is chosen
template <typename T>
struct has_without_codegen_member_fn<T, std::void_t<decltype(std::declval<T>().without_codegen())>> : std::true_type
{};

// Visitor for variants/recursive variants that returns the result of
// arg.without_codegen() if the argument type has a without_codegen() member
// function, and returns a copy of the argument if it does not.
template <class TResult>
struct without_codegen_leaf_visitor
{
    template <class T,
              std::enable_if_t<has_without_codegen_member_fn<T>::value, bool> = true>
    TResult operator()(const T& arg) const
    {
        return TResult{arg.without_codegen()};
    }
    template <class T,
              std::enable_if_t<!has_without_codegen_member_fn<T>::value, bool> = true>
    TResult operator()(const T& arg) const
    {
        return TResult{arg};
    }
};

} // namespace detail

template <class T, class TString>
std::optional<T> from_string(const TString& str)
{
    auto b = &(*str.begin());
    // For "top-level" from_string() function calls, we want to return an error
    // if there are extra non-whitespace characters at the end of the string.
    // Therefore, must_consume_all = true.
    detail::cg_from_chars<T> fc(b, b + str.size(), /* must_consume_all = */ true);
    return fc.parse_value();
}

template <class T>
std::optional<T> from_string(const char* str)
{
    return from_string<T>(std::string_view(str));
}

template <class T>
[[nodiscard]] std::string to_string(const T& t)
{
    return detail::value_to_string<T>::to_str(t);
}

template <class T, class TBuffer>
void encode(TBuffer& buf, const T& t)
{
    detail::value_encoder<T>::encode_value(t, buf);
}

template <class T, class TBuffer>
std::optional<T> decode(const TBuffer& buf)
{
    auto it = buf.begin();
    return detail::value_decoder<T>::decode_value(it, buf.end());
}

template <class T, class TIterator>
std::optional<T> decode(TIterator& it, const TIterator& end)
{
    return detail::value_decoder<T>::decode_value(it, end);
}
} // namespace cutegen
#endif
