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

#if !defined(CUTEGEN_REC_VAR_HPP_INCLUDED_)
#define CUTEGEN_REC_VAR_HPP_INCLUDED_

#include <algorithm>
#include <array>
#include <assert.h>
#include <cstdlib>
#include <functional>
#include <iostream>
#include <iterator>
#include <optional>
#include <stack>
#include <stdexcept>
#include <stdint.h>
#include <string>
#include <system_error>
#include <tuple>
#include <type_traits>
#include <utility>
#include <variant>
#include <vector>

#include "cutegen/charconv.hpp"
#include "cutegen/cutegen.hpp"
#include "cutegen/cg_error.hpp"
#include "cutegen/underscore.hpp"
#include "cutegen/dynamic.hpp"
#include "cutegen/scaled_basis.hpp"

namespace cutegen
{
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// rec_var.hpp - Public API
//
////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @brief Wrapper class for creating nested hierarchical objects
 *
 * Recursive variant structures created using a C++ constructor create an
 * unnested instance of the class:
 * cutegen::int_tuple t(4);        // prints as: 4              (depth=0)
 * cutegen::int_tuple t2(4, 5, 6); // prints as (4, 5, 6)       (depth=1)
 * In some cases, we may want to create an instance with a single value, but a
 * depth greater than 0. Our first attempt might be:
 * cutegen::int_tuple t3(cutegen::int_tuple(7));
 * However, this does not achieve the desired result, as this statement invokes
 * the C++ copy constructor for int_tuple.
 * The wrap() function (below) can be used to create nested values:
 * cutegen::int_tuple t4(cutegen::wrap(7)); // prints as (7)
 * The wrap function can be called multiple times:
 * cutegen::int_tuple t5(cutegen::wrap(cutegen::wrap(8))); // prints as ((8))
 */
template <class T>
struct wrapped_value_t
{
    wrapped_value_t(const T& v);
    const T& value_ref;
};

/**
 * @brief Return a "wrapped" reference to the function argument to increase the
 *        depth of the hierarchical object being created.
 */
template <class T>
wrapped_value_t<T> wrap(const T& t);

/**
 * @brief Recursive variant struct.
 *
 * A recursive variant is a structure that contains either:
 *
 * 1. a leaf "element", or
 * 2. a vector containing one or more instance of this structure. Each vector element in turn
 *    contains a leaf "element" or a vector - thus the name "recursive."
 *
 * In the C++ standard library, "tuple" indicates a collection with the size fixed at compile time.
 * In our case, the collection size is not fixed at compile time, but we retain the name "tuple" for
 * consistency with CuTe.
 *
 * A canonical "int tuple" contains some sort of int OR a vector of int tuples. However, some
 * recursive variants may allow more than one "element" type. This feature can be used to allow a
 * recursive variant to hold special values of a separate type - e.g. a special "all coordinates"
 * value for coordinates, as represented by an underscore in CuTe.
 *
 * This recursive variant can be "empty." This is currently represented by an empty vector. A
 * std::variant initialized with no arguments will hold a value of its first alternative. For this
 * reason, the vector variant type must be the first type alternative. An alternative approach might
 * be to use std::monostate.
 */
template <class TDerived, class... TElemTypes>
struct rec_var_base : std::variant<std::vector<TDerived>, TElemTypes...>
{
public:
    /// The concrete recursive variant type
    using rv_t = TDerived;
    /// The vector of recursive variants type
    using vector_t = std::vector<rv_t>;
    /// The base variant type
    using variant_t = std::variant<vector_t, TElemTypes...>;
    /// The element types
    using elem_types_t = std::tuple<TElemTypes...>;
    /// The leaf type (i.e. a variant that can hold all non-vector types)
    using leaf_t = std::variant<TElemTypes...>;
    /// The variant types, i.e. the element types and the vector type which provides recursion
    using variant_types_t = std::tuple<vector_t, TElemTypes...>;

    /// The first integral type or void
    using int_t = typename detail::find_type_or<void, std::is_integral, elem_types_t>::type;

    using vector_iterator_t       = typename vector_t::iterator;
    using vector_const_iterator_t = typename vector_t::const_iterator;

    // Bitwidth of the "static" integral type (the first type in the template parameter pack)
    static constexpr int elem_bw = sizeof_bits_v<int_t>;

    // Use base class variant constructors for the types supported by the
    // variant (elem, vector of rec_var, ...).
    using variant_t::variant_t;

public:
    // Add a constructor that will handle 2 or more arguments by creating an
    // empty vector, and then populating it.
    template <class T0, class T1, class... T>
    rec_var_base(T0&& arg0, T1&& arg1, T&&... args);
    template <class T, size_t N>
    rec_var_base(const std::array<T, N> arr);
    /// Copy constructor from a base variant type.
    rec_var_base(const variant_t& var_);
    /// Move constructor from a base variant type.
    rec_var_base(variant_t&& var_);

    template <class T>
    rec_var_base(const wrapped_value_t<T>& w)
    {
        append(rv_t{w.value_ref});
    }

public:
    rv_t&       as_derived();
    const rv_t& as_derived() const;
    template <typename T = int_t>
    typename std::enable_if_t<!std::is_same_v<T, void>, T&> as_int();
    template <typename T = int_t>
    typename std::enable_if_t<!std::is_same_v<T, void>, const T&> as_int() const;
    /**
     * @brief Return the static integral value, cast to an int32 type.
     *
     * Asserts if the static integer value is out of range when static_int_t
     * is int64_t (assert-enabled builds only).
     */
    template <typename T = int_t>
    typename std::enable_if_t<!std::is_same_v<T, void>, int32_t> as_int32() const;
    /**
     * @brief Return the static integral value, cast to an int64 type.
     */
    template <typename T = int_t>
    typename std::enable_if_t<!std::is_same_v<T, void>, int64_t> as_int64() const;
    template <class... T>
    void append(T&&... a);
    void pop_back();

    /**
     * @brief Swap the contents of the current recursive variant with the other
     */
    void swap(rv_t& other);

    // Workaround for implementation-specific issues with std::visit() and
    // classes that inherit from std::variant. (See the links in the comments
    // above.)
    template <typename F>
    decltype(auto) visit(F&& f);
    template <typename F>
    decltype(auto) visit(F&& f) const;

private:
    // iterator class
    // When the containing variant class instance holds a vector, we use the
    // underlying vector iterator. When the instance does not hold a vector, we
    // treat the recursive variant instance as an element of an array with
    // length 1.
    // The C++ standard allows forming the address of an element that is "one
    // past the end of an array." However, here the variant is not an array of
    // length 1.
    // According to the C++ standard, when using the + additive operator, a
    // pointer to a non-array object is treated as a pointer to the first
    // element of an array with size 1. Therefore, it seems like we can use
    // this + 1 as a pointer for the end iterator.
    // 1. https://stackoverflow.com/questions/21411102/treating-a-single-object-like-an-array-with-one-element-taking-one-past-end-poi
    // 2. https://en.cppreference.com/w/cpp/language/operator_arithmetic
    template <bool TIsConst = false>
    struct iterator_base : std::variant<typename std::conditional_t<TIsConst,
                                                                    vector_const_iterator_t,
                                                                    vector_iterator_t>,
                                        typename std::conditional_t<TIsConst,
                                                                    const rv_t*,
                                                                    rv_t*>>
    {
        // clang-format off
        using variant_base_t    = std::variant<typename std::conditional_t<TIsConst,
                                                                           vector_const_iterator_t,
                                                                           vector_iterator_t>,
                                               typename std::conditional_t<TIsConst,
                                                                           const rv_t*,
                                                                           rv_t*>>;
        using value_type        = typename std::conditional_t<TIsConst,
                                                              const rv_t,
                                                              rv_t>;
        // clang-format on
        using iterator_category = std::random_access_iterator_tag;
        using difference_type   = std::ptrdiff_t;
        using pointer           = value_type*;
        using reference         = value_type&;
        // Use base class variant constructors for supported types
        using variant_base_t::variant_base_t;

        // Construct a const_iterator from a non-const iterator
        template <bool T                                 = TIsConst,
                  typename std::enable_if<T, bool>::type = true>
        iterator_base(const iterator_base<false>& it)
        {
            if(0 == it.index())
            {
                this->operator=(std::get<0>(it));
            }
            else
            {
                this->operator=(std::get<1>(it));
            }
        }

        reference operator*() const
        {
            return (0 == this->index()) ? *(std::get<0>(*this)) : *(std::get<1>(*this));
        }
        pointer operator->() const
        {
            return (0 == this->index()) ? &(*(std::get<0>(*this))) : std::get<1>(*this);
        }
        iterator_base& operator++() // prefix increment
        {
            if(0 == this->index())
            {
                ++std::get<0>(*this);
            }
            else
            {
                ++std::get<1>(*this);
            }
            return *this;
        }
        iterator_base operator++(int) // postfix increment
        {
            iterator_base tmp = *this;
            ++(*this);
            return tmp;
        }
        iterator_base& operator--() // prefix decrement
        {
            if(0 == this->index())
            {
                --std::get<0>(*this);
            }
            else
            {
                --std::get<1>(*this);
            }
            return *this;
        }
        iterator_base operator--(int) // postfix decrement
        {
            iterator_base tmp = *this;
            --(*this);
            return tmp;
        }

        // iterator comparison operators (==, !=, <, >, <=, >=) are handled
        // correctly by the base variant class when the variants are holding
        // the same type (which we assume to be the case here).

        iterator_base operator+(difference_type op) const
        {
            if(0 == this->index())
            {
                return iterator_base(std::get<0>(*this) + op);
            }
            else
            {
#if !defined(_MSC_VER)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warray-bounds"
#endif // !defined(_MSC_VER)
                return iterator_base(std::get<1>(*this) + op);
#if !defined(_MSC_VER)
#pragma GCC diagnostic pop
#endif
            }
        }
        iterator_base& operator+=(difference_type op)
        {
            if(0 == this->index())
            {
                std::get<0>(*this) += op;
            }
            else
            {
#if !defined(_MSC_VER)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warray-bounds"
#endif // !defined(_MSC_VER)
                std::get<1>(*this) += op;
#if !defined(_MSC_VER)
#pragma GCC diagnostic pop
#endif
            }
            return *this;
        }
        iterator_base operator-(difference_type op) const
        {
            // clang-format off
            return (0 == this->index()) ? iterator_base(std::get<0>(*this) - op)
                                        : iterator_base(std::get<1>(*this) - op);
            // clang-format on
        }
        difference_type operator-(const iterator_base& b) const
        {
            // clang-format off
            assert(this->index() == b.index());
            return (0 == this->index()) ? (std::get<0>(*this) - std::get<0>(b))
                                        : (std::get<1>(*this) - std::get<1>(b));
            // clang-format on
        }
        bool operator<(const iterator_base& b) const
        {
            return ((b - (*this)) > 0);
        }
        bool operator<=(const iterator_base& b) const
        {
            return ((b - (*this)) >= 0);
        }
        bool operator>(const iterator_base& b) const
        {
            return (((*this) - b) > 0);
        }
        bool operator>=(const iterator_base& b) const
        {
            return (((*this) - b) >= 0);
        }
    };

public:
    using iterator       = iterator_base<false>;
    using const_iterator = iterator_base<true>;
    iterator       begin();
    iterator       end();
    const_iterator begin() const;
    const_iterator end() const;
    const_iterator cbegin() const;
    const_iterator cend() const;
    rv_t&          front();
    const rv_t&    front() const;
    rv_t&          back();
    const rv_t&    back() const;
    rv_t&          operator[](size_t idx);
    const rv_t&    operator[](size_t idx) const;
    /**
     * Returns a reference to the recursive variant using the given indices to
     * traverse the hierarchical structure.
     */
    template <typename... TInt, std::enable_if_t<(std::is_integral_v<TInt> && ...), bool> = true>
    rv_t& get(TInt... idx)
    {
        std::reference_wrapper<rv_t> ref(as_derived());
        [[maybe_unused]] auto        get_at = [&](auto index) // unused when idx is empty
        {
            ref = ref.get()[index];
        };
        (get_at(idx), ...);
        return ref.get();
    }

    template <typename... TInt, std::enable_if_t<(std::is_integral_v<TInt> && ...), bool> = true>
    const rv_t& get(TInt... idx) const
    {
        std::reference_wrapper<const rv_t> ref(as_derived());
        [[maybe_unused]] auto              get_at = [&](auto index) // unused when idx is empty
        {
            ref = ref.get()[index];
        };
        (get_at(idx), ...);
        return ref.get();
    }

    // Get with a range (i.e. a type that can be used by a range-based for loop)
    template <class TRange, std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
    rv_t& get(const TRange& r)
    {
        std::reference_wrapper<rv_t> ref(as_derived());
        for(auto& idx : r)
        {
            ref = ref.get()[idx];
        }
        return ref.get();
    }

    template <class TRange, std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
    const rv_t& get(const TRange& r) const
    {
        std::reference_wrapper<const rv_t> ref(as_derived());
        for(auto& idx : r)
        {
            ref = ref.get()[idx];
        }
        return ref.get();
    }

    /**
     * Extend the recursive variant by inserting a new element before the element
     * at the specified position
     *
     * @param pos An iterator pointing to where the new element should be inserted
     * @param value Value to be copied to the new element
     * @return An iterator that points to the inserted element
     */
    iterator insert(const_iterator pos, const rv_t& value);

    /**
     * Remove the specified element from the recursive variant
     *
     * @param pos An iterator pointing to the element that should be erased
     * @return An iterator that points to the element after the removed element
     */
    iterator erase(const_iterator pos);

    /**
     * Remove the specified range of elements from the recursive variant
     *
     * @param first An iterator pointing to the element that should be erased
     * @param last An iterator pointing after the last element that should be erased
     * @return An iterator that points to the element after the last removed element
     */
    iterator erase(const_iterator first, const_iterator last);
};

/// wrapped_value_t constructor
template <class T>
wrapped_value_t<T>::wrapped_value_t(const T& v) :
    value_ref(v)
{
}

/// wrap() function to increase nesting of constructed recursive variants
template <class T>
wrapped_value_t<T> wrap(const T& t)
{
    return wrapped_value_t<T>{t};
}

/// Generic concrete recursive variant type for internal use (e.g. wrapping scalars).
template <class... TRecVarElemTypes>
struct rec_var : public rec_var_base<rec_var<TRecVarElemTypes...>, TRecVarElemTypes...>
{
    using base_rv_t = rec_var_base<rec_var<TRecVarElemTypes...>, TRecVarElemTypes...>;
    using base_rv_t::base_rv_t;
};

//
// Type traits
//

// Forward declaration of some internal utilities used to implement the traits
namespace detail
{
template <template <class> class TPred, class TElemTypesTuple, class TSeq>
struct is_rec_var_with_type_pred_expand;
template <class TBase, class TElemTypesTuple, class TSeq>
struct rec_var_has_type_derived_from_expand;
} // namespace detail

/// Type trait to check whether a type is a recursive variant type.
template <class T>
struct is_rec_var : std::false_type
{};

/// Type trait to check whether a type is a recursive variant type.
template <class... TRecVarElemTypes>
struct is_rec_var<rec_var_base<TRecVarElemTypes...>> : std::true_type
{};

template <class... TRecVarElemTypes>
struct is_rec_var<rec_var<TRecVarElemTypes...>> : std::true_type
{};

template <class T, class TType, class TEnable = void>
struct is_rec_var_and_can_hold_type
{
    static constexpr bool value = false;
};

template <class TRecVar, class TType>
struct is_rec_var_and_can_hold_type<TRecVar, TType, std::enable_if_t<is_rec_var<TRecVar>::value>>
{
    using rec_var_t = TRecVar;
    static constexpr bool value =
        detail::tuple_has_type<typename rec_var_t::elem_types_t, TType>::value;
};

template <class T, class TType, class TEnable = void>
struct is_rec_var_and_convertible_from_type
{
    static constexpr bool value = false;
};

template <class TRecVar, class TType>
struct is_rec_var_and_convertible_from_type<TRecVar,
                                            TType,
                                            std::enable_if_t<is_rec_var<TRecVar>::value>>
{
    using rec_var_t = TRecVar;
    static constexpr bool value =
        detail::tuple_is_convertible_from_type<typename rec_var_t::variant_types_t, TType>::value;
};

// This allows to write std::enable_if_t<is_rec_var_with_type_pred<T>::value> when T is not a
// rec_var
template <class T, template <class> class TPredicate, class TEnable = void>
struct is_rec_var_with_type_pred
{
    static constexpr bool value = false;
};

template <class TRecVar, template <class> class TPredicate>
struct is_rec_var_with_type_pred<TRecVar, TPredicate, std::enable_if_t<is_rec_var<TRecVar>::value>>
{
    using rec_var_t = TRecVar;
    using vector_t  = typename rec_var_t::vector_t;
    using index_seq_t =
        typename std::make_index_sequence<std::tuple_size_v<typename TRecVar::elem_types_t>>;
    static constexpr bool value =
        TPredicate<vector_t>::value ||
        detail::is_rec_var_with_type_pred_expand<TPredicate,
                                                 typename TRecVar::elem_types_t,
                                                 index_seq_t>::value;
};

/// Type trait to check whether a recursive variant can hold a type derived from the base `TBase`.
template <class TRecVar, class TBase, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
struct rec_var_has_type_derived_from
{
    using rec_var_t = TRecVar;
    using index_seq_t =
        typename std::make_index_sequence<std::tuple_size_v<typename TRecVar::elem_types_t>>;
    static constexpr bool value =
        detail::rec_var_has_type_derived_from_expand<TBase,
                                                     typename TRecVar::elem_types_t,
                                                     index_seq_t>::value;
};

// Tile types require parsing elements that are layouts, therfore they need a special treatment for
// recursive variant seprators and delimitors
template <class T, class TEnable = void>
struct is_tile : std::false_type
{};

//
// Fixes to std::visit
//

/**
 * Some initial implementations of the std::visit() standard library function
 * did not support classes that inherit from std::variant.
 *
 * 1 https://stackoverflow.com/questions/63616709/incomplete-type-stdvariant-used-in-nested-name-specifier
 * 2.https://cplusplus.github.io/LWG/issue3052
 * 3.https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2021/p2162r2.html
 * 4. __cpp_lib_variant feature test macro
 *
 * The __cpp_lib_variant feature test macro can be used to detect whether the
 * library implementation supports std::visit() on derived classes.
 */
#if __cpp_lib_variant >= 202102L
// Use the standard library implementation
using std::visit;
#else
// An implementation of visit() that supports rec_var will require us to cast
// arguments of type rec_var to the std::variant base class. In order to support
// both rec_var and std::variant arguments to cutegen::visit() with template
// parameter packs and perfect forwarding, we will use the base_var_t struct to
// provide the template type to std::forward.
// This can be removed when all supported compilers have the required feature
// macro.
namespace detail
{
template <class T, class TEnable = void>
struct base_var_t;

template <class... VTypes>
struct base_var_t<std::variant<VTypes...>>
{
    using value = std::variant<VTypes...>;
};
template <class... VTypes>
struct base_var_t<std::variant<VTypes...>&>
{
    using value = std::variant<VTypes...>&;
};
template <class... VTypes>
struct base_var_t<const std::variant<VTypes...>&>
{
    using value = const std::variant<VTypes...>&;
};

template <class TRV>
struct base_var_t<TRV, std::enable_if_t<is_rec_var<TRV>::value, void>>
{
    using value = typename TRV::variant_t;
};
template <class TRV>
struct base_var_t<TRV&, std::enable_if_t<is_rec_var<TRV>::value, void>>
{
    using value = typename TRV::variant_t&;
};
template <class TRV>
struct base_var_t<const TRV&, std::enable_if_t<is_rec_var<TRV>::value, void>>
{
    using value = const typename TRV::variant_t&;
};
} // namespace detail

template <typename Visitor, class Variant0, class... VariantN>
decltype(auto) visit(Visitor&& vs, Variant0&& v0, VariantN&&... vN)
{
    // Arguments v0 and vN... are forwarding references. The Variant0/VariantN
    // types will be deduced as:
    // - Variant0/VariantN when called with an rvalue
    // - Variant0&/VariantN& (optionally with const) when called with an lvalue
    // The base_var_t struct specializations provide the appropriate type for
    // std::forward().
    return std::visit(std::forward<Visitor>(vs),
                      std::forward<typename detail::base_var_t<Variant0>::value>(v0),
                      std::forward<typename detail::base_var_t<VariantN>::value>(vN)...);
}
#endif // __cpp_lib_variant >= 202102L

// Trait to indicate whether a type can be used with the visit() function. A
// recursive variant inherits from std::variant, so it might be possible to
// instead use std::is_base_of, but we use this for now.
template <class T>
struct is_visitable
{
    static constexpr bool value = is_rec_var<T>::value || detail::is_variant<T>::value;
};
template <class T>
constexpr bool is_visitable_v = is_visitable<T>::value;

//
// Basics
//

/**
 * @brief operator<< reload for rec_var.
 *
 * The fundamental convert implementation of rec_var to string is done by to_string.
 *
 * @see to_string()
 */
template <class... TRecVarElemTypes>
std::ostream& operator<<(std::ostream&                            os,
                         const rec_var_base<TRecVarElemTypes...>& rv);

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
std::ostream& operator<<(std::ostream&               os,
                         const std::vector<TRecVar>& v);

/// Convenience equality operator between a recursive variant and an integral leaf value.
template <class TRecVar,
          class TIntegral,
          std::enable_if_t<std::is_integral<TIntegral>::value, bool> = true>
bool operator==(const TRecVar& rva, [[maybe_unused]] const TIntegral b);

/// Convenience equality operator between a recursive variant and an integral leaf value.
template <class TRecVar,
          class TIntegral,
          std::enable_if_t<std::is_integral<TIntegral>::value, bool> = true>
bool operator==(const TIntegral a, const TRecVar& rvb);

/// Convenience inequality operator between a recursive variant and an integral leaf value.
template <class TRecVar,
          class TIntegral,
          std::enable_if_t<std::is_integral<TIntegral>::value, bool> = true>
bool operator!=(const TRecVar& rva, const TIntegral b);

/// Convenience inequality operator between a recursive variant and an integral leaf value.
template <class TRecVar,
          class TIntegral,
          std::enable_if_t<std::is_integral<TIntegral>::value, bool> = true>
bool operator!=(const TIntegral a, const TRecVar& rvb);

//
// Functions common to all recursive variant types
//

template <class... TElemTypes>
size_t rank(const rec_var_base<TElemTypes...>& rv);

template <class... TElemTypes>
size_t rank(const rec_var_base<TElemTypes...>& rv, int mode);

template <class... Args>
size_t max_rank(Args... args);

template <class... TElemTypes>
size_t depth(const rec_var_base<TElemTypes...>& rv);

/**
 * @brief Verify that the set of indices in the provided range
 * are valid for the profile of the recursive variant.
 */
template <class TRecVar, class TRange>
bool check_get_indices(const TRecVar& rv, const TRange& r);

/// get as a function with value semantics.
template <class... Ts>
auto get(const rec_var_base<Ts...>& rv, size_t mode);

/// get as a function with value semantics.
template <class... Ts, class TRange, std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
auto get(const rec_var_base<Ts...>& rv, const TRange& range);

/// get as a function with value semantics.
template <class... Ts,
          class... TInt,
          std::enable_if_t<(std::is_integral_v<TInt> && ...), bool> = true>
auto get(const rec_var_base<Ts...>& rv, TInt... idx);

/// generates a new recursive variant containing elements specified by the provided indices.
template <class TRecVar, class... TInt, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
TRecVar select(const TRecVar& rv, TInt... idx);

/// generates a new recursive variant containing elements specified by the provided indices.
template <class TRecVar, class TRange, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true, std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
TRecVar select(const TRecVar& rv, const TRange& range);

/// Checks if two tuples have identical profiles.
template <class... TAs, class... TBs>
bool is_congruent(const rec_var_base<TAs...>& rvA, const rec_var_base<TBs...>& rvB);

/// Checks if two tuples have identical profiles up to the profile of A.
template <class... TAs, class... TBs>
bool weakly_congruent(const rec_var_base<TAs...>& rvA, const rec_var_base<TBs...>& rvB);

// Returns true if the arguments are compatible. Tuples A and B are compatible
// if:
// 1.) prod(A) == prod(B)
// 2.) If A is a tuple, then for all 0 <=i < rank(A), A[i] is compatible with
//     B[i].
template <class TRecVarA, class TRecVarB>
bool compatible(const TRecVarA& rvA, const TRecVarB& rvB);

// Returns the number of leaf elements in the given recursive variant. This is
// conceptually equivalent to rank(flatten(rv)).
template <class TRecVar>
size_t leaf_count(const TRecVar& rv);

// Returns the number of leaf elements that satisfy the given boolean function
// in the input recursive variant.
template <class TRecVar, class Fn>
size_t leaf_count_if(const TRecVar& rv, Fn&& f);

/**
 * @brief Wrap non-tuples into rank-1 tuples or forward
 *
 *  E.g. wrap_if_leaf(1)     => (1, )
 *       wrap_if_leaf((1,))  => (1, )
 *
 * @tparam TRecVar type of input rec_var
 * @param rv input rec_var
 * @return TRecVar wrapped result if it's not tuple
 */
template <class TRecVar, class T = std::remove_const_t<std::remove_reference_t<TRecVar>>>
T wrap_if_leaf(TRecVar&& rv);

/// Checks whether a predicate applies to any recursive variant leaf.
template <class TPredicate,
          class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
bool any_leaf_is(const TRecVar& rv, TPredicate&& f);

/// Returns true if the predicate is true for all leaf values of the recursive variant.
template <class TPredicate,
          class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
bool all_leaves(const TRecVar& rv, TPredicate&& f);

// Return a reference to the recursive variant at the "flattened position"
// (fpos) given by idx. The "flatted position" is the position that a leaf
// value would be in if the recursive variant were converted to a string,
// proceeding from left to right. For example:
//
// recursive variant: (128, 16, (256, (1024, 16)), 99)
// flattened position:   0   1     2      3   4     5
template <class TRecVar>
TRecVar& leaf_at_fpos(TRecVar& rv, size_t idx);

/// Constructs a flat recursive variant of rank @p n with elements equal to @p value.
template <class TRecVar, class T>
TRecVar repeat(const size_t n, const T& value);

/// Constructs a recursive variant of the same type and profile as @p rv with all elements replaced
/// by @p value.
template <class TRV1,
          class TRV0,
          class T,
          std::enable_if_t<is_rec_var_and_convertible_from_type<TRV1, T>::value, bool> = true>
TRV1 repeat_like(const TRV0& rv, const T& value);

/**
 * @brief An implementation of `cute::append` in cutegen. It appends elements to
 *  input tuple to rank-N tuple. For rank-M tuple, if M < N, then appends
 *   (N - M) `e` to it. Otherwise, do nothing.
 *
 *  E.g. append_to_rank_N(N, (1, 3, .., m-th), 5) ==> (1, 3, .., m-th, 5, 5, ...) : rank-N
 *
 * @tparam TRecVar  Type of input tuple
 * @tparam TElem    Element type of input tuple
 * @param N         Size N to append
 * @param rv        Intput tuple
 * @param e         Element append to input tuple
 * @return auto
 */
template <class TRecVar, class TElem>
auto append_to_rank_N(size_t N, const TRecVar& rv, const TElem& e);

/**
 * @brief An implementation of `cute::prepend` in cutegen. It inserts elements to
 *  beginning of input tuple to rank-N tuple. For rank-M tuple, if M < N, then prepends
 *   (N - M) `e` to it. Otherwise, do nothing.
 *
 *  E.g. prepend_to_rank_N(N, (1, 3, .., m-th), 5) ==> (5, 5, ..., 1, 3, .., m-th) : rank-N
 *
 * @tparam TRecVar  Type of input tuple
 * @tparam TElem    Element type of input tuple
 * @param N         prepend input up to rank-N
 * @param rv        Intput tuple
 * @param e         Element prepend to input tuple
 * @return auto
 */
template <class TRecVar, class TElem>
auto prepend_to_rank_N(size_t N, const TRecVar& rv, const TElem& e);

/**
 * @brief Insert `x` into the Nth position of the input tuple
 *
 * @tparam TRVElemTypes
 * @tparam TElem        Element type to insert
 * @param pos           position to insert
 * @param tup           input tuple (pass-by-value and move to potentially reduce copy)
 * @param x             element to insert
 * @return auto
 */
template <class TRecVar, class TElem, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
auto insert(int pos, TRecVar tup, TElem x);

/// Returns a vector with all leaves of the input recursive variant. Similar to
/// flatten, but the return type here can only hold leaves. whereas the flatten()
/// return type is the same as the input.
template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
auto get_leaves(const TRecVar& rv) -> std::vector<typename TRecVar::leaf_t>;

/// Helper to determine the element type for get_leaves_with_type:
/// - Returns TLeaf directly when only one type is specified
/// - Returns std::variant<TLeaf, TAdditional...> when multiple types are specified
template <class TLeaf, class... TAdditional>
struct get_leaves_type
{
    using type = typename std::conditional<0 == sizeof...(TAdditional),
                                           TLeaf,
                                           std::variant<TLeaf, TAdditional...>>::type;
};

/// Returns a vector with all leaf instances of the given type (with recursion) from left to right.
template <class... TLeafTypes,
          class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
auto get_leaves_with_type(const TRecVar& rv) -> std::vector<typename get_leaves_type<TLeafTypes...>::type>;

/**
 * @brief Group the elements in [B,E) of a recursive variant into a single element.
 *
 * Group the elements [B,E) of a recursive variant into a single element, copying elements before
 * index B and after/including index E unmodified.
 *
 * Examples: group(2, 4, (1, 2, 3, 4, 5, 6)) => (1, 2, (3, 4), 5, 6)
 *           group(-3, -1, (1, 2, 3, 4, 5, 6)) => (1, 2, 3, (4, 5), 6)
 *
 * The formation of a "group" places the selected elements into a recursive variant that holds a
 * vector type.
 *
 * The following edge case(s) are handled in the following order:
 * 1. If the input t is a leaf (i.e. either an integer element, or an underscore, or a dynamic
 *    value), the returned tuple contains that leaf element as the only element in a variant that
 *    holds a vector type. This is true regardless of the provided indices B and E.
 *    group(-1, 0, 12) => (12)
 */
template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
auto group(int B, int E, const TRecVar& t);

/**
 * @brief Take the elements in [B,E) of a recursive variant into a vector recursive variant.
 *
 * This function proceeds as follows:
 * 1. If E < 0 or E > rank(t), E = rank(t).
 * 2. If B >= rank(t), return an empty vector.
 * 3. Take the elements in [B,E) into a vector. In particular, recursive variants holding an element
 *    gets wrapped.
 */
template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
auto take(int B, int E, const TRecVar& t);

template <class T0, class... Ts>
T0 cat_tuple(const T0& a, Ts&&... b);

/**
 * @brief Concatenate all the elements of a "tuple" recursive variant.
 *
 * @pre holds_vector(rv)
 * @pre holds_vector(rv[i]), i in [0,rank(rv))
 *
 * In CuTe, a tuple is not a leaf, hence the preconditions. This is implemented as a variadic
 * function in CuTe.
 */
template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
auto rec_var_tuple_cat(const TRecVar& rv);

// Return a new tuple with contents (a0,a1,...,x0,x1,...)
template <class T, class X>
auto prepend(const T& a, const X& x);

// Return a new tuple with contents (x,t1,t2,...) (t0 is removed)
template <class T, class X>
auto replace_front(const T& t, const X& x);

template <class TRVA,
          class TRVB,
          class TEnable = std::void_t<std::enable_if_t<is_rec_var<TRVA>::value>,
                                      std::enable_if_t<is_rec_var<TRVB>::value>>>
bool elem_less(const TRVA& lhs, const TRVB& rhs);

/**
 * @brief Check whether the first value is lexicographically less than
 *        the second value. (Currently restricted to static integer values.)
 */
template <class TA, class TB>
bool lex_less(const TA& lhs, const TB& rhs);

/**
 * @brief Check whether the first value is colexicographically less than
 *        the second value. (Currently restricted to static integer values.)
 */
template <class TA, class TB>
bool colex_less(const TA& lhs, const TB& rhs);

// Transpose operation in tuple space.
// Input: ((a,b,c,...),(x,y,z,...),...)        rank-R0 x rank-R1 input
// Output ((a,x,...),(b,y,...),(c,z,...),...)  rank-R1 x rank-R0 output
// When t is a leaf element, t is returned.
// When t is empty, t is returned.
// When t[0] is a leaf element, t is wrapped once and is returned.
template <class T>
T zip(const T& t);

// Utility function to zip arguments without combining them into a
// single tuple (as required for the function implementation above).
template <class T0, class T1, class... Tn>
T0 zip(const T0& t0, const T1& t1, const Tn&... tn);

/// @return A tuple of the elements of @c t in reverse order.
/// Input: (3,(5,4))
/// Output: ((5,4),3)
template <class TRecVar>
TRecVar reverse(const TRecVar& rv);

/// Folds a recursive variant using the binary function @p fn.
template <class TRecVar, class T, class BinaryFunction>
T fold(const TRecVar& rv, const T& init, BinaryFunction&& fn);

/**
 * @brief Folds a recursive variant following the profile of @p profile using the binary function
 *        @p fn.
 *
 * This function folds the recursive variant @p rv using the initial value @p init, the binary
 * function @p fn, and following the profile of another recursive variant @p profile. If the
 * profiles of @p rv and @p profile do not match, this implies that @p fn must support operating
 * on vectors of recursive variants.
 *
 * @pre    For all depth levels of @p profile, for all modes, the rank of that mode in @p profile
 *         is equal to the associated mode in @p rv.
 * @see    fold()
 */
template <class TRV0,
          class TRV1,
          class T,
          class BinaryFunction,
          class = std::void_t<std::enable_if_t<is_rec_var<TRV0>::value>,
                              std::enable_if_t<is_rec_var<TRV1>::value>>>
auto fold_with_profile(const TRV0& rv, const TRV1& profile, const T& init, BinaryFunction&& fn);

/**
 * @brief Applies a function to each recursive variant item.
 *
 * @pre `rv0`, `rvArgs...` are congruent with one another
 *
 * The signature of @p fn must be `(const TRV0&, const TRVs&...) -> result_t` with `result_t` a
 * recursive variant type.
 *
 * `transform` behaves as follows:
 *
 * - for non-vector recursive variants, it returns `fn(rv0, rvArgs...)`
 * - otherwise, it applies @p fn to each depth-1 elements
 *
 * Therefore, @p fn cannot assume any precondition on its arguments. It must be able to handle all
 * types in `rv0::variant_types_t`, `rvArgs::variant_types_t`,... (including the recursive vector
 * type) even if that means a treatment agnostic to the actual item's type.
 *
 * Examples (`xi` does not necessarily denote a recursive variant element):
 *
 * - `transform[f, x0]                = f(x0)`
 * - `transform[f, (x0)]              = (f(x0))`
 * - `transform[f, (x0,x1)]           = (f(x0),f(x1))`
 * - `transform[f, ((x0,x1),x2)]      = (f((x0,x1)),f(x2))`
 * - `transform[f, (x0,x1), (y0,y1)]  = (f(x0,y0), f(x1,y1))`
 */
template <class TFunction, class TRV0, class... TRVs>
auto transform(TFunction&& fn, const TRV0& rv0, const TRVs&... rvArgs);

/// Apply g to the result of transform(f,rv0,rvArgs...).
template <class TF, class TG, class TRV0, class... TRVs>
auto transform_apply(TF&& f, TG&& g, const TRV0& rv0, const TRVs&... rvArgs);

/**
 * @brief Applies a function to all leaf elements.
 *
 * @pre `rv0`, `rvArgs...` are congruent with one another
 *
 * The signature of @p fn must be `(const TRV0&, const TRVs&...) -> result_t` with `result_t` a
 * recursive variant type.
 *
 * `transform_leaf` returns a recursive variant that is congruent to @p rv0 and applies @p fn to
 * all leaf elements. Therefore, @p fn can assume that the following precondition is satisfied when
 * used within `transform_leaf`: `!holds_vector(rv0) && !holds_vector(rvArgs) && ...`.
 *
 * Examples (`xi` denotes a recursive variant element):
 *
 * - `transform_leaf[f, x0]               = f(x0)`
 * - `transform_leaf[f, (x0)]             = (f(x0))`
 * - `transform_leaf[f, (x0,x1)]          = (f(x0),f(x1))`
 * - `transform_leaf[f, ((x0,x1),x2)]     = ((f(x0),f(x1)),f(x2))`
 * - `transform_leaf[f, (x0,x1), (y0,y1)] = (f(x0,y0),f(x1,y1))`
 */
template <class TFunction, class TRV0, class... TRVs>
auto transform_leaf(TFunction&& fn, const TRV0& rv0, const TRVs&... rvArgs);

/**
 * @brief Apply f to leaf elements and g to construct results.
 *
 * (g, f, t...) = g(f(t)...)
 *
 * The current implementation required that f(t)... have the same return type
 * as g(f(t)...). g() muse accept an operand that is a std::vector with the
 * return type of f(t) as its vector element type.
 *
 * @param g      Function to combine results
 * @param f      Function to apply to leaf elements
 * @param rv0    First argument to f
 * @param rvArgs Additional (optional) arguments to f
 * @return auto
 */
template <class TG, class TF, class TRV0, class... TRVs>
auto transform_apply_leaf(TG&& g, TF&& f, const TRV0& rv0, const TRVs&... rvArgs);

// Replace zero elements in tuple t with a value of 1
template <class IntTuple>
IntTuple filter_zeros(const IntTuple& t);

// Repace all elements in tuple b that are paired with a 0 element in
// tuple a with a value of 1.
template <class IntTupleA, class IntTupleB>
IntTupleB filter_zeros(const IntTupleA& a, const IntTupleB& b);

// Returns an int tuple with depth 1
template <class IntTuple, std::enable_if_t<is_rec_var<IntTuple>::value, bool> = true>
IntTuple flatten(const IntTuple& t);

// Returns an int tuple with depth 1, flattening tSrc at the end of tDst
template <class IntTupleSrc,
          class TDst,
          std::enable_if_t<is_rec_var<IntTupleSrc>::value, bool> = true>
void flatten_into(const IntTupleSrc& tSrc, TDst& tDst);

//
// Integral variant
//

template <class TRecVar>
bool holds_int(TRecVar&& rv);

template <class... T>
bool all_hold_int(const T&... values);

template <class TRecVar>
auto&& get_int(TRecVar&& rv);

/**
 * @brief Checks recursively whether a recursive variant only has integral elements.
 *
 * This function returns true for empty recursive variants. Any other similar function should return
 * false for empty recursive variants, e.g. is_underscore_only().
 */
template <class... TRecVarElemTypes>
bool is_integral_only(const rec_var_base<TRecVarElemTypes...>& rv);

//
// Vector variant
//

template <class TRecVar>
bool holds_leaf(TRecVar&& rv);

template <class TRecVar>
bool holds_vector(TRecVar&& rv);

template <class TRecVar>
auto&& get_vector(TRecVar&& rv);

template <class TRecVar>
auto&& get_vector_elem(TRecVar&& rv, size_t index);

template <class... Ts>
bool is_empty(const rec_var_base<Ts...>& rv);

//
// cg_error_t variant
//

/**
 * @brief Checks recursively whether a recursive variant has an error.
 *
 * @see cg_error_t
 * @see holds_error()
 */
template <class... TRecVarElemTypes>
bool has_error(const rec_var_base<TRecVarElemTypes...>& rv);

/**
 * @brief Checks if a recursive variant is valid.
 *
 * A recursive variant is valid if and only if it does not have an error.
 *
 * @see has_error()
 */
template <class... TRecVarElemTypes>
bool is_valid(const rec_var_base<TRecVarElemTypes...>& rv);

//
// underscore variant
//

/**
 * @brief Checks whether a recursive variant holds an underscore.
 *
 * @see underscore_t
 * @see has_underscore()
 */
template <class... TRecVarElemTypes>
bool holds_underscore(const rec_var_base<TRecVarElemTypes...>& rv);

/**
 * @brief Checks recursively whether a recursive variant has an underscore.
 *
 * @see underscore_t
 * @see holds_error()
 */
template <class... TRecVarElemTypes>
bool has_underscore(const rec_var_base<TRecVarElemTypes...>& rv);

/**
 * @brief Checks recursively whether a recursive variant only has underscore elements.
 *
 * This function returns false for empty recursive variants.
 */
template <class... TRecVarElemTypes>
bool is_underscore_only(const rec_var_base<TRecVarElemTypes...>& rv);

//
// dynamic_t variant
//

template <class T>
struct rec_var_has_dynamic_type : is_rec_var_with_type_pred<T, type_can_hold_dynamic_int>
{};

template <class TRecVar>
using find_dynamic_in_rec_var = detail::find_in_tuple<typename TRecVar::elem_types_t,
                                                      has_dynamic_t_base>;

/**
 * @brief Checks whether the leaves of a recursive variant hold only certain types
 */
template <class... TLeaves,
          class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
bool has_only_leaves_of_type(const TRecVar& rv);

/**
 * @brief Checks whether any leaves of a recursive variant hold one of the given types
 */
template <class... TLeaves,
          class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
bool has_leaf_with_type(const TRecVar& rv);

/**
 * @brief Checks whether a recursive variant holds a dynamic integer.
 *
 * A dynamic integer is any instance of a class derived from dynamic_t. This function is not
 * recursive and simply wraps `std::holds_alternative`.
 *
 * @see dynamic_t
 * @see has_dynamic()
 */
template <class... TRecVarElemTypes>
bool holds_dynamic_int(const rec_var_base<TRecVarElemTypes...>& rv);

/**
 * @brief Checks whether none of the arguments holds a dynamic integer.
 *
 * @see holds_dynamic_int()
 */
template <class... T>
bool none_holds_dynamic_int(const T&... t);

/**
 * @brief Checks recursively whether a recursive variant has a dynamic int.
 *
 * @see dynamic_t
 * @see holds_dynamic_int()
 */
template <class... TRecVarElemTypes>
bool has_dynamic_int(const rec_var_base<TRecVarElemTypes...>& rv);

/// Checks whether a recursive variant holds an integer or a dynamic integer.
template <class... TRecVarElemTypes>
bool holds_int_or_dynamic_int(const rec_var_base<TRecVarElemTypes...>& rv);

/**
 * @brief Extracts the integral or dynamic element from a leaf recursive variant of a given type
 *        into another recursive variant type.
 *
 * @pre `holds_int_or_dynamic_int(rv)`
 */
template <class TDst, class TSrc>
TDst get_int_or_dynamic_int(const TSrc& rv);

/**
 * @brief Extracts the dynamic integer from a recursive variant type.
 *
 * @pre `holds_dynamic_int(rv)`
 */
template <class... TRecVarElemTypes>
auto get_dynamic_int(const rec_var_base<TRecVarElemTypes...>& rv);

/**
 * @brief Checks recursively whether a recursive variant only has integral or dynamic elements.
 *
 * This function returns true for empty recursive variants.
 */
template <class... TRecVarElemTypes>
bool is_int_or_dynamic_int_only(const rec_var_base<TRecVarElemTypes...>& rv);

/**
 * @brief Checks recursively whether a recursive variant only has integral, dynamic, or indxed_t elements.
 *
 * This function returns true for empty recursive variants.
 */
template <class... TRecVarElemTypes>
bool is_integral_or_dynamic_or_indexed_only(const rec_var_base<TRecVarElemTypes...>& rv);

//
// scaled_basis_t variant
//

/// Specialization of type_can_hold_dynamic_int for scaled basis types
template <class... TValueTypes>
struct type_can_hold_dynamic_int<scaled_basis_t<TValueTypes...>>
{
    static constexpr bool value = detail::tuple_has_type_pred<std::tuple<TValueTypes...>, has_dynamic_t_base>::value;
};

template <class TRecVar>
using rec_var_can_hold_scaled_basis = is_rec_var_with_type_pred<TRecVar, is_scaled_basis>;

template <class TRecVar>
using find_scaled_basis_in_rec_var = detail::find_in_tuple<typename TRecVar::elem_types_t,
                                                           is_scaled_basis>;

/**
 * @brief Checks whether a recursive variant holds a scaled basis.
 *
 * @see scaled_basis_t
 * @see has_scaled_basis()
 */
template <class... TRecVarElemTypes>
bool holds_scaled_basis(const rec_var_base<TRecVarElemTypes...>& rv);

/**
 * @brief Retrieve the underlying scaled basis from a leaf recursive variant.
 *
 * @pre holds_scaled_basis(rv)
 */
template <class... TRecVarElemTypes>
auto get_scaled_basis(const rec_var_base<TRecVarElemTypes...>& rv);

/**
 * @brief Checks recursively whether a recursive variant has a scaled basis.
 *
 * @see scaled_basis_t
 * @see holds_scaled_basis()
 */
template <class... TRecVarElemTypes>
bool has_scaled_basis(const rec_var_base<TRecVarElemTypes...>& rv);

template <class... Ts>
bool holds_int_like(const rec_var_base<Ts...>& rv);

//
// Others
//

/**
 * @brief Checks whether the argument holds any one of the given types
 */
template <class... TTypes, class TRecVar>
bool holds_type(const TRecVar& rv);

/**
 * @brief Checks whether all elements of the input vector hold one of the given
 *        types
 */
template <class... TTypes, class TElem>
bool all_hold_types(const std::vector<TElem>& values);

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// rec_var.hpp - Implementation and internals
//
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail
{

template <class... Types,
          class TVar>
bool holds_any_alternative(const TVar& v)
{
    return (std::holds_alternative<Types>(v) || ...);
}

//
// Helper type traits
//

template <template <class> class TPred, class TElemTypesTuple, size_t... ISeq>
struct is_rec_var_with_type_pred_expand<TPred, TElemTypesTuple, std::index_sequence<ISeq...>>
{
    static constexpr bool value =
        (TPred<std::tuple_element_t<ISeq, TElemTypesTuple>>::value || ...);
};

template <class TBase, class TElemTypesTuple, size_t... ISeq>
struct rec_var_has_type_derived_from_expand<TBase, TElemTypesTuple, std::index_sequence<ISeq...>>
{
    static constexpr bool value =
        (std::is_base_of<TBase, std::tuple_element_t<ISeq, TElemTypesTuple>>::value || ...);
};

// The recursive variant type takes its (non-vector) element types as a template
// parameter pack. The template below allows one to generate a recursive variant
// type, given a std::tuple of types, by expanding the tuple elements into a
// template parameter pack.
template <class TElemTypesTuple, class TSeq>
struct rec_var_from_tuple_seq;

template <class TElemTypesTuple, size_t... ISeq>
struct rec_var_from_tuple_seq<TElemTypesTuple, std::index_sequence<ISeq...>>
{
    using type = rec_var<std::tuple_element_t<ISeq, TElemTypesTuple>...>;
};

// Not used for now
template <class TElemTypesTuple>
struct rec_var_from_tuple
{
    using index_seq_t = typename std::make_index_sequence<std::tuple_size_v<TElemTypesTuple>>;
    using type        = typename detail::rec_var_from_tuple_seq<TElemTypesTuple, index_seq_t>::type;
};

/// Specialization for recursive variants.
template <class TDefault,
          template <class>
          class TPredicate,
          class TRecVar>
struct find_type_or<TDefault, TPredicate, TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value>>
{
    using type = typename detail::find_type_or<void, TPredicate, typename TRecVar::variant_types_t>::type;
};

//
// To/From strings
//

/**
 * @brief Struct containing customizable tokens for parsing strings.
 *
 * @tparam RecVar_ Any legal defined rec_var.
 *
 * To make parsing recursive variants easier, the following tokens are customizable:
 * - the left delimiter of the vector-of-variants type (defaults to `(`)
 * - the right delimiter of the vector-of-variants type (defaults to `)`)
 * - the separator of elements of vector of variants (defaults to `,`)
 *
 * The "tile" type has different tokens: '[', ']', ';' for the delimiters and the separator.
 */
template <class RecVar_>
struct customizable_tokens
{
    using RecVar = remove_cvref_t<RecVar_>;
    template <class T, int pos_idx>
    static constexpr char infer_token()
    {
        if constexpr(is_tile<T>::value)
        {
            if constexpr(pos_idx == 0)
            {
                return '[';
            }
            else if constexpr(pos_idx == 1)
            {
                return ']';
            }
            else if constexpr(pos_idx == 2)
            {
                return ';';
            }
        }
        else
        {
            if constexpr(pos_idx == 0)
            {
                return '(';
            }
            else if constexpr(pos_idx == 1)
            {
                return ')';
            }
            else if constexpr(pos_idx == 2)
            {
                return ',';
            }
        }
    }

    static constexpr char delimiter_left  = infer_token<RecVar, 0>();
    static constexpr char delimiter_right = infer_token<RecVar, 1>();
    static constexpr char separator       = infer_token<RecVar, 2>();
};
/// Specialization of value_to_string for vectors of recursive variants.
template <class TRecVar>
struct value_to_string<std::vector<TRecVar>,
                       std::enable_if_t<is_rec_var<TRecVar>::value>>
{
    using vector_t = std::vector<TRecVar>;
    using value_t  = typename vector_t::value_type;
    static std::string to_str(const vector_t& v)
    {
        constexpr auto toks = customizable_tokens<value_t>{};
        std::string    s(1, toks.delimiter_left);
        for(auto& e : v)
        {
            s.append(to_string(e));
            s += toks.separator;
        }
        if(s.length() > 1)
            s.back() = toks.delimiter_right;
        else
            s += toks.delimiter_right;
        return s;
    }
};

/// Specialization of value_to_string for recursive variants.
template <class TRecVar>
struct value_to_string<TRecVar,
                       std::enable_if_t<is_rec_var<TRecVar>::value>>
{
    using rec_var_t = TRecVar;
    static std::string to_str(const rec_var_t& rv)
    {
        return rv.visit([](auto&& v) //
                        {
                            return to_string(std::forward<decltype(v)>(v));
                        });
    }
};

// Try to parse each variant type until we find one that matches. We start at
// 1 because we are assuming that index zero belongs to the vector variant type.
// (Parsing a vector of elements is handled separately by the cg_from_chars<>
// specialization for recursive variants.)
template <class TRV, std::size_t I = 1>
std::optional<TRV> parse_rec_var_type([[maybe_unused]] const char* first,
                                      [[maybe_unused]] const char* last)
{
    using variant_t = typename TRV::variant_t;

    // We start the loop below at 1 (via the default template parameter value)
    // as we are attempting to avoid the vector variant type. This static_assert
    // verifies that index 0 is in fact the vector type.
    static_assert(std::is_same_v<std::vector<TRV>,
                                 std::variant_alternative_t<0, variant_t>>);

    if constexpr(I < std::variant_size_v<variant_t>)
    {
        using vtype_t = std::variant_alternative_t<I, variant_t>;
        // Construct an object that will attempt to parse the current variant
        // type. On success, return the value. Otherwise, recurse to the next
        // variant type.
        cg_from_chars<vtype_t> fc(first, last, /* must_consume_all = */ true);
        return (fc.parse_value().has_value()) ?
                   TRV{fc.parse_value().value()} :
                   parse_rec_var_type<TRV, I + 1>(first, last);
    }
    else
    {
        return std::nullopt;
    }
}

// Parse the given string and return a recursive variant instance if successful.
// We are using std::enable_if here to enable this function version only for
// explicit template types (TRV) that:
// - have a type elem_types_t
// - are derived from (or the same as) rec_var<elem_types_t...>.
template <class TRecVar>
class cg_from_chars<TRecVar,
                    std::enable_if_t<is_rec_var<TRecVar>::value>>
{
public:
    using rec_var_t  = TRecVar;
    using optional_t = std::optional<rec_var_t>;
    cg_from_chars(const char* begin, const char* end, bool must_consume_all) :
        result_{begin, std::errc::invalid_argument}
    {
        constexpr auto toks = customizable_tokens<rec_var_t>{};
        // Parser state machine:
        //
        //                                         if(depth=0)   else
        //                                 [done] <--------.------------
        //                                 ^    ^          |           |
        //                                 |    |         ')'          |
        //                      if(depth=0)|    |          |           |
        //                                 |else|          |           |
        // start --> [pre_elem] --- elem --.----)------> [post_elem] <--
        //            |   ^   |                 |            ^
        //           '('  |  ')'   if(depth=0)  |       else |
        //            |   |   |                 |            |
        //            -----   ------------------.-------------
        //                       (empty tuple)
        enum parser_state
        {
            state_pre_elem,
            state_post_elem,
            state_error,
            state_done,
            state_return
        };
        enum parser_token
        {
            token_left,
            token_right,
            token_sep,
            token_elem,
            token_eof
        };
        //--------------------------------------------------------------------------
        // get_next_token()
        // Lambda to advance the given iterator past any whitespace (if it exists)
        // and return the type of the next parsing token found.
        auto get_next_token = [toks](const char*& it,
                                     const char*  end) -> parser_token //
        {
            while(it != end)
            {
                if(*it == toks.delimiter_left)
                    return token_left;
                else if(*it == toks.delimiter_right)
                    return token_right;
                else if(*it == toks.separator)
                    return token_sep;
                switch(*it)
                {
                case ' ': // fall through, skip whitespace
                case '\t': ++it; break;
                default: return token_elem;
                }
            }
            return token_eof;
        };
        //--------------------------------------------------------------------------
        // read_element()
        // Attempts to read a leaf element for the template recursive variant,
        // returning the result (std::optional). The input iterator is updated to
        // point to the input sequence after the consumed characters.
        auto read_element = [toks](const char*& it,
                                   const char*  end) -> std::optional<rec_var_t> //
        {
            // Allow/expect individual variant types to handle whitespace
            std::array<char, 2> sep = {toks.separator, toks.delimiter_right};

            auto elemEnd    = std::find_first_of(it, end, sep.begin(), sep.end());
            auto parsedElem = detail::parse_rec_var_type<rec_var_t>(&(*it), &(*elemEnd));
            if(parsedElem.has_value())
            {
                // On success, update the iterator
                it = elemEnd;
            }
            return parsedElem;
        };
        parser_state                                  state = state_pre_elem;
        std::stack<std::reference_wrapper<rec_var_t>> stack;
        rec_var_t                                     rv;
        auto                                          it = begin;

        //--------------------------------------------------------------------------
        // handle_lparen()
        // Lambda for state updates when the left parenthesis token is encountered.
        auto handle_lparen = [&]() //
        {
            state = state_pre_elem;
            ++it;
            if(stack.empty())
            {
                // For the first '(', we use the default-constructed recursive
                // variant.
                assert(is_empty(rv));
                stack.push(std::ref(rv));
            }
            else
            {
                stack.top().get().append(rec_var_t{});
                stack.push(stack.top().get().back());
            }
        };
        //--------------------------------------------------------------------------
        // handle_rparen()
        // Lambda for state updates when the right parenthesis token is encountered.
        auto handle_rparen = [&]() //
        {
            if(!stack.empty())
            {
                ++it;
                stack.pop();
                state = (stack.empty()) ? state_done : state_post_elem;
            }
            else
            {
                state = state_error;
            }
        };
        //--------------------------------------------------------------------------
        // handle_elem()
        // Lambda for reading ane element
        auto handle_elem = [&]() //
        {
            // Attempt to read an element and update the iterator accordingly
            auto r = read_element(it, end);
            if(r.has_value())
            {
                if(stack.empty())
                {
                    // "Bare" top-level tuple element - not contained in a tuple.
                    // Assign the returned variant directly.
                    rv = r.value();
                    // Set state to done so that an error occurs on any further
                    // input tokens.
                    state = state_done;
                }
                else
                {
                    stack.top().get().append(r.value());
                    state = state_post_elem;
                }
            }
            else
            {
                // Failure to read element
                state = state_error;
            }
        };
        while((it != end) && (state != state_error) && (state != state_return))
        {
            auto tok = get_next_token(it, end);
            // clang-format off
            switch(state)
            {
            case state_pre_elem:
                switch(tok)
                {
                case token_left:    handle_lparen();        break;
                case token_right:   handle_rparen();        break;
                case token_elem:    handle_elem();          break;
                default:            state = state_error;    break;
                }
                break;
            case state_post_elem:
                switch(tok)
                {
                case token_right:   handle_rparen();                break;
                case token_sep:     ++it; state = state_pre_elem;   break;
                default:            state = state_error;            break;
                }
                break;
            case state_done:
                switch(tok)
                {
                case token_eof:                      break;
                default:
                    {
                        // There is a token after the rec_var is complete. Use
                        // the value of the must_consume_all argument to determine
                        // whether to return an error or to just update the
                        // iterator.
                        if(must_consume_all)
                            state = state_error;
                        else
                            state = state_return;
                    }
                    break;
                }
                break;
            case state_return:
                break;
            case state_error:
                break;
            }
            // clang-format on
        }
        if((state_done == state) || (state_return == state))
        {
            value_  = std::move(rv);
            result_ = from_chars_result{it, std::errc{}};
        }
        //return (state_done == state) ? std::optional<TRV>(rv) : std::nullopt;
    }
    const optional_t&        parse_value() { return value_; }
    const from_chars_result& parse_result() { return result_; }

private:
    from_chars_result result_;
    optional_t        value_;
};

//
// Encode/Decode
//

// Generate a binary storage representation of a given recursive variant.
// The encoded format has the following form:
// [ variant_index_32 ] [ variant_type_encoding ]
// variant_index_32 represents the std::variant index of the current variant
// type, truncated to 32 bits.
// Each variant type is responsible for defining its own encoding:
// empty types:  (no data is written)
// integral types: direct copy of in-memory representation
// vector: 32-bit value for vector size, followed by a recursive
//     [index][encoding] pair for each element.
// As written here, the encoding is not fully robust to changes over time:
//     - changing the order of variant fields will invalidate any stored
//       encodings
//     - the encoding uses the host endian convention, and does not currently
//       accommodate read/writing on systems with different endianness
template <class TRecVar>
struct value_encoder<TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value>>
{
    template <class TBuffer>
    static void encode_value(const TRecVar& rv, TBuffer& buffer)
    {
        // Variant index is size_t, but truncate to 32 bits to use less space.
        encode(buffer, static_cast<uint32_t>(rv.index()));
        // The visit() function will invoke the lambda with the specific variant
        // type held by the variant.
        rv.visit([&](auto&& v) //
                 {
                     encode(buffer, std::forward<decltype(v)>(v));
                 });
    }
};

/// Specialization of value_decoder for recursive variant vector types.
template <class TRecVar>
struct value_decoder<std::vector<TRecVar>,
                     std::enable_if_t<is_rec_var<TRecVar>::value>>
{
    using vector_t = std::vector<TRecVar>;
    template <class TIterator>
    static std::optional<vector_t> decode_value(TIterator& it, const TIterator& end)
    {
        // Decode the number of items in the vector
        auto sz = decode<uint32_t>(it, end);
        if(!sz.has_value())
        {
            return std::nullopt;
        }
        // Initialize a vector with the desired size
        vector_t vec(static_cast<size_t>(sz.value()), TRecVar{});
        for(size_t i = 0; i < vec.size(); ++i)
        {
            auto optRV = decode<TRecVar>(it, end);
            if(!optRV.has_value())
            {
                // Decoding an element has failed - return error
                return std::nullopt;
            }
            vec[i] = optRV.value();
        }
        return vec;
    }
};

template <class TRecVar>
struct value_decoder<TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value>>
{
    template <class TIterator>
    static std::optional<TRecVar> decode_value(TIterator& it, const TIterator& end)
    {
        using rv_t       = TRecVar;
        auto opt_variant = decode<typename rv_t::variant_t>(it, end);
        if(!opt_variant.has_value()) return std::nullopt;
        return rv_t(std::move(opt_variant.value()));
    }
};

//
// Other helpers
//

/**
 * @brief Check if the class owns shape() or stride() member func
 *
 * @tparam T
 * @return value is true if the class owns, false otherwise.
 * @return false
 */
template <typename T>
struct has_member_shape
{
private:
    template <typename U>
    static auto check(int) -> decltype(std::declval<U>().shape(), std::true_type());
    template <typename U>
    static std::false_type check(...);

public:
    enum
    {
        value = std::is_same<decltype(check<T>(0)), std::true_type>::value
    };
};

template <typename T>
struct has_member_stride
{
private:
    template <typename U>
    static auto check(int) -> decltype(std::declval<U>().stride(), std::true_type());
    template <typename U>
    static std::false_type check(...);

public:
    enum
    {
        value = std::is_same<decltype(check<T>(0)), std::true_type>::value
    };
};

template <class TRecVar>
void get_leaves(const TRecVar& rv, std::vector<typename TRecVar::leaf_t>& vec)
{
    if(holds_vector(rv))
    {
        for(auto& e : get_vector(rv))
        {
            get_leaves(e, vec);
        }
    }
    else
    {
        visit(detail::overload{
                  [&](const std::vector<TRecVar>& v) {},
                  [&](auto t) { vec.push_back(t); }},
              rv);
    }
}

template <class... TLeafTypes,
          class TRecVar,
          class TElemType>
void get_leaves_with_type(const TRecVar& rv, std::vector<TElemType>& vec)
{
    if(holds_vector(rv))
    {
        for(auto& e : get_vector(rv))
        {
            detail::get_leaves_with_type<TLeafTypes...>(e, vec);
        }
    }
    else
    {
        auto collector = detail::overload{
            // Do not add the recursive variant vector type
            [](std::vector<TRecVar> v) {},
            // Do not add values with type not in the parameter pack
            [](auto t) {},
            // Add any value with a type in the parameter pack
            [&](TLeafTypes t) { vec.push_back(t); }...};
        visit(collector, rv);
    }
}

template <class TRecVar>
TRecVar
construct(typename TRecVar::const_iterator begin,
          typename TRecVar::const_iterator end)
{
    TRecVar ret;
    for(auto it = begin; it != end; ++it)
    {
        ret.append(*it);
    }
    return ret;
}

/**
 * A dynamic collection visitor for the rec_var_base type.
 * @tparam Container A container to append dynamic_t values to, must support push_back method.
 */
template <class Container>
struct rec_var_dynamic_collection_visitor
{
    explicit rec_var_dynamic_collection_visitor(Container& c) :
        c_(c) {}

    /**
     * A templated method which will dispatch to the appropriate
     * collect_dynamics method for each visited variant type. The method
     * will only be called if the variant contains the given instance
     * at runtime.
     * @tparam TType The type possibly contained in the variant.
     * @param t A value that is an instance of or possibly contains a dynamic value.
     */
    template <typename TType>
    void operator()(const TType& t)
    {
        collect_dynamics(c_, t);
    }

private:
    Container& c_;
};
} // namespace detail

template <class TDerived, class... TElemTypes>
template <class T0, class T1, class... T>
rec_var_base<TDerived, TElemTypes...>::rec_var_base(T0&& arg0, T1&& arg1, T&&... args) :
    variant_t(vector_t{})
{
    auto& v = std::get<vector_t>(*this);
    // Internal resizing in emplace_back calls the copy constructor
    // Therefore, reserve upfront to make sure this doesn't happen
    v.reserve(2 + sizeof...(T));
    auto append_arg = [&](auto&& rvarg) //
    {
        v.emplace_back(std::forward<decltype(rvarg)>(rvarg));
    };
    append_arg(std::forward<T0>(arg0));
    append_arg(std::forward<T1>(arg1));
    (append_arg(std::forward<T>(args)), ...);
}

template <class TDerived, class... TElemTypes>
template <class T, size_t N>
rec_var_base<TDerived, TElemTypes...>::rec_var_base(const std::array<T, N> arr) :
    variant_t(vector_t(std::begin(arr), std::end(arr))) {}

template <class TDerived, class... TElemTypes>
rec_var_base<TDerived, TElemTypes...>::rec_var_base(const variant_t& var_) :
    variant_t(var_) {}

template <class TDerived, class... TElemTypes>
rec_var_base<TDerived, TElemTypes...>::rec_var_base(variant_t&& var_) :
    variant_t(std::move(var_)) {}

template <class TDerived, class... TElemTypes>
TDerived& rec_var_base<TDerived, TElemTypes...>::as_derived()
{
    return static_cast<TDerived&>(*this);
}

template <class TDerived, class... TElemTypes>
const TDerived& rec_var_base<TDerived, TElemTypes...>::as_derived() const
{
    return static_cast<const TDerived&>(*this);
}

template <class TDerived, class... TElemTypes>
template <class T>
typename std::enable_if_t<!std::is_same_v<T, void>, T&>
rec_var_base<TDerived, TElemTypes...>::as_int()
{
    return std::get<T>(*this);
}

template <class TDerived, class... TElemTypes>
template <typename T>
typename std::enable_if_t<!std::is_same_v<T, void>, const T&>
rec_var_base<TDerived, TElemTypes...>::as_int() const
{
    return std::get<T>(*this);
}

template <class TDerived, class... TElemTypes>
template <typename T>
typename std::enable_if_t<!std::is_same_v<T, void>, int32_t>
rec_var_base<TDerived, TElemTypes...>::as_int32() const
{
    assert(in_range<int32_t>(this->as_int()));
    return static_cast<int32_t>(this->as_int());
}

template <class TDerived, class... TElemTypes>
template <typename T>
typename std::enable_if_t<!std::is_same_v<T, void>, int64_t>
rec_var_base<TDerived, TElemTypes...>::as_int64() const
{
    return static_cast<int64_t>(this->as_int());
}

template <class TDerived, class... TElemTypes>
template <class... T>
void rec_var_base<TDerived, TElemTypes...>::append(T&&... a)
{
    // If the variant does not hold a vector element, convert to hold a
    // vector, and then place the existing leaf as the first element
    // before appending to the vector below.
    if(!std::holds_alternative<vector_t>(*this))
    {
        this->operator=(vector_t(1, as_derived()));
    }
    (std::get<vector_t>(*this).push_back(std::forward<T>(a)),
     ...);
}

template <class TDerived, class... TElemTypes>
void rec_var_base<TDerived, TElemTypes...>::swap(TDerived& other)
{
    static_cast<variant_t&>(*this).swap(static_cast<variant_t&>(other));
}

template <class TDerived, class... TElemTypes>
void rec_var_base<TDerived, TElemTypes...>::pop_back()
{
    if(std::holds_alternative<vector_t>(*this))
    {
        auto& vec = std::get<vector_t>(*this);
        assert(!vec.empty());
        vec.pop_back();
    }
    else
    {
        this->operator=(vector_t{});
    }
}

template <class TDerived, class... TElemTypes>
template <typename F>
decltype(auto) rec_var_base<TDerived, TElemTypes...>::visit(F&& f)
{
    return std::visit(std::forward<F>(f), static_cast<variant_t&>(*this));
}

template <class TDerived, class... TElemTypes>
template <typename F>
decltype(auto) rec_var_base<TDerived, TElemTypes...>::visit(F&& f) const
{
    return std::visit(std::forward<F>(f), static_cast<const variant_t&>(*this));
}

template <class TDerived, class... TElemTypes>
typename rec_var_base<TDerived, TElemTypes...>::iterator rec_var_base<TDerived, TElemTypes...>::begin()
{
    return std::holds_alternative<vector_t>(*this) ?
               iterator(std::get<vector_t>(*this).begin()) :
               iterator(&as_derived());
}

template <class TDerived, class... TElemTypes>
typename rec_var_base<TDerived, TElemTypes...>::iterator rec_var_base<TDerived, TElemTypes...>::end()
{
    return std::holds_alternative<vector_t>(*this) ?
               iterator(std::get<vector_t>(*this).end()) :
               iterator(&(as_derived()) + 1);
}

template <class TDerived, class... TElemTypes>
typename rec_var_base<TDerived, TElemTypes...>::const_iterator
rec_var_base<TDerived, TElemTypes...>::begin() const { return cbegin(); }

template <class TDerived, class... TElemTypes>
typename rec_var_base<TDerived, TElemTypes...>::const_iterator
rec_var_base<TDerived, TElemTypes...>::end() const { return cend(); }

template <class TDerived, class... TElemTypes>
typename rec_var_base<TDerived, TElemTypes...>::const_iterator
rec_var_base<TDerived, TElemTypes...>::cbegin() const
{
    return std::holds_alternative<vector_t>(*this) ?
               const_iterator(std::get<vector_t>(*this).begin()) :
               const_iterator(&as_derived());
}

template <class TDerived, class... TElemTypes>
typename rec_var_base<TDerived, TElemTypes...>::const_iterator
rec_var_base<TDerived, TElemTypes...>::cend() const
{
    return std::holds_alternative<vector_t>(*this) ?
               const_iterator(std::get<vector_t>(*this).end()) :
               const_iterator(&(as_derived()) + 1);
}

template <class TDerived, class... TElemTypes>
TDerived& rec_var_base<TDerived, TElemTypes...>::front()
{
    return std::holds_alternative<vector_t>(*this) ?
               std::get<vector_t>(*this).front() :
               as_derived();
}

template <class TDerived, class... TElemTypes>
const TDerived& rec_var_base<TDerived, TElemTypes...>::front() const
{
    return std::holds_alternative<vector_t>(*this) ?
               std::get<vector_t>(*this).front() :
               as_derived();
}

template <class TDerived, class... TElemTypes>
TDerived& rec_var_base<TDerived, TElemTypes...>::back()
{
    return std::holds_alternative<vector_t>(*this) ?
               std::get<vector_t>(*this).back() :
               as_derived();
}

template <class TDerived, class... TElemTypes>
const TDerived& rec_var_base<TDerived, TElemTypes...>::back() const
{
    return std::holds_alternative<vector_t>(*this) ?
               std::get<vector_t>(*this).back() :
               as_derived();
}

template <class TDerived, class... TElemTypes>
TDerived& rec_var_base<TDerived, TElemTypes...>::operator[](size_t idx)
{
    if(std::holds_alternative<vector_t>(*this))
    {
        return std::get<vector_t>(*this).at(idx);
    }
    else if(0 == idx)
    {
        return as_derived();
    }
    else
    {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        throw std::out_of_range("Invalid tuple index");
#else
        assert(false && "Invalid tuple index");
        return as_derived();
#endif
    }
}

template <class TDerived, class... TElemTypes>
const TDerived& rec_var_base<TDerived, TElemTypes...>::operator[](size_t idx) const
{
    if(std::holds_alternative<vector_t>(*this))
    {
        return std::get<vector_t>(*this).at(idx);
    }
    else if(0 == idx)
    {
        return as_derived();
    }
    else
    {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        throw std::out_of_range("Invalid tuple index");
#else
        assert(false && "Invalid tuple index");
        return as_derived();
#endif
    }
}

template <class TDerived, class... TElemTypes>
typename rec_var_base<TDerived, TElemTypes...>::iterator
rec_var_base<TDerived, TElemTypes...>::insert(const_iterator pos, const TDerived& value)
{
    assert((pos >= begin()) && (pos <= end()));
    if(std::holds_alternative<vector_t>(as_derived()))
    {
        // A valid iterator for a recursive variant holding the vector type
        // must hold a vector iterator.
        assert(std::holds_alternative<vector_const_iterator_t>(pos));
        return std::get<vector_t>(as_derived()).insert(std::get<vector_const_iterator_t>(pos), value);
    }
    else
    {
        // A valid iterator for a recursive variant holding a non-vector
        // type must hold a "bare pointer" iterator.
        assert(std::holds_alternative<const rv_t*>(pos));
        // Get the original offset (either 0 or 1)
        auto diff = pos - begin();
        // Convert the recursive variant to one holding a vector with a
        // single element.
        this->operator=(vector_t(1, as_derived()));
        return std::get<vector_t>(as_derived()).insert(std::get<vector_t>(as_derived()).begin() + diff, value);
    }
}

template <class TDerived, class... TElemTypes>
typename rec_var_base<TDerived, TElemTypes...>::iterator
rec_var_base<TDerived, TElemTypes...>::erase(const_iterator pos)
{
    // For the standard C++ library std::vector::erase() method, the end()
    // iterator cannot be passed as the argument to erase(), so we follow that
    // convention here.
    assert((pos >= begin()) && (pos < end()));
    if(std::holds_alternative<vector_t>(as_derived()))
    {
        // A valid iterator for a recursive variant holding the vector type
        // must hold a vector iterator.
        assert(std::holds_alternative<vector_const_iterator_t>(pos));
        auto& vec = std::get<vector_t>(as_derived());
        return vec.erase(std::get<vector_const_iterator_t>(pos));
    }
    else
    {
        // A valid iterator for a recursive variant holding a non-vector
        // type must hold a "bare pointer" iterator, and the iterator must
        // point to the single element of the recursive variant.
        assert(std::holds_alternative<const rv_t*>(pos));
        assert(pos == const_iterator(begin()));
        // Convert the 'this' recursive variant to one holding an empty vector
        this->operator=(vector_t{});
        return std::get<vector_t>(as_derived()).end();
    }
}

template <class TDerived, class... TElemTypes>
typename rec_var_base<TDerived, TElemTypes...>::iterator
rec_var_base<TDerived, TElemTypes...>::erase(const_iterator first, const_iterator last)
{
    // Erasing an empty range is a no-op
    if(first == last)
    {
        return begin() + (last - begin());
    }
    if(std::holds_alternative<vector_t>(as_derived()))
    {
        // A valid iterator for a recursive variant holding the vector type
        // must hold a vector iterator.
        assert(std::holds_alternative<vector_const_iterator_t>(first));
        assert(std::holds_alternative<vector_const_iterator_t>(last));
        auto& vec = std::get<vector_t>(as_derived());
        return vec.erase(std::get<vector_const_iterator_t>(first),
                         std::get<vector_const_iterator_t>(last));
    }
    else
    {
        // A valid iterator for a recursive variant holding a non-vector
        // type must hold a "bare pointer" iterator, and the iterator must
        // point to the single element of the recursive variant.
        assert(std::holds_alternative<const rv_t*>(first));
        assert(std::holds_alternative<const rv_t*>(last));
        // The first = last = end() case was handled above, so we the only valid
        // case is that first == begin().
        assert(first == const_iterator(begin()));
        // Convert the 'this' recursive variant to one holding an empty vector
        this->operator=(vector_t{});
        return std::get<vector_t>(as_derived()).end();
    }
}

//
// Basics
//

template <class... TRecVarElemTypes>
std::ostream& operator<<(std::ostream&                            os,
                         const rec_var_base<TRecVarElemTypes...>& rv)
{
    os << to_string(rv);
    return os;
}

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
std::ostream& operator<<(std::ostream&               os,
                         const std::vector<TRecVar>& v)
{
    os << to_string(v);
    return os;
}

template <class TRecVar,
          class TIntegral,
          std::enable_if_t<std::is_integral<TIntegral>::value, bool>>
inline bool operator==(const TRecVar& rva, [[maybe_unused]] const TIntegral b)
{
    if constexpr(!std::is_same_v<typename TRecVar::int_t, void>)
    {
        return holds_int(rva) &&
               (rva.as_int() == static_cast<typename TRecVar::int_t>(b));
    }
    // TRecVar cannot hold any integral type
    return false;
}

template <class TRecVar,
          class TIntegral,
          std::enable_if_t<std::is_integral<TIntegral>::value, bool>>
inline bool operator==(const TIntegral a, const TRecVar& rvb)
{
    return (rvb == a);
}

template <class TRecVar,
          class TIntegral,
          std::enable_if_t<std::is_integral<TIntegral>::value, bool>>
inline bool operator!=(const TRecVar& rva, const TIntegral b)
{
    return !(rva == b);
}

template <class TRecVar,
          class TIntegral,
          std::enable_if_t<std::is_integral<TIntegral>::value, bool>>
inline bool operator!=(const TIntegral a, const TRecVar& rvb)
{
    return !(a == rvb);
}

//
// Functions common to all recursive variant types
//

template <class... TElemTypes>
size_t rank(const rec_var_base<TElemTypes...>& rv)
{
    return holds_vector(rv) ? get_vector(rv).size() : 1;
}

template <class... TElemTypes>
size_t rank(const rec_var_base<TElemTypes...>& rv, int mode)
{
    return rank(rv[mode]);
}

template <class... Args>
size_t max_rank(Args... args)
{
    size_t max_val = 0;
    ((max_val = std::max(max_val, rank(args))), ...);
    return max_val;
}

template <class... TElemTypes>
size_t depth(const rec_var_base<TElemTypes...>& rv)
{
    if(holds_leaf(rv))
    {
        // Leaf values have an intrinsic depth of 0
        return 0;
    }
    else
    {
        // Vectors have a depth of 1 plus the maximum sub-element depth
        size_t sub_depth = 0;
        for(auto& c : get_vector(rv))
        {
            sub_depth = std::max(sub_depth, depth(c));
        }
        return 1 + sub_depth;
    }
}

template <class TRecVar, class TRange>
bool check_get_indices(const TRecVar& rv, const TRange& r)
{
    std::reference_wrapper<const TRecVar> ref(rv);
    for(auto& idx : r)
    {
        if(idx >= 0 && (static_cast<size_t>(idx) < rank(ref.get())))
        {
            ref = ref.get()[idx];
        }
        else
        {
            return false;
        }
    }
    return true;
}

template <class... Ts>
auto get(const rec_var_base<Ts...>& rv, size_t mode)
{
    assert(mode < rank(rv));
    return rv[mode];
}

template <class... Ts, class TRange, std::enable_if_t<!std::is_integral_v<TRange>, bool>>
auto get(const rec_var_base<Ts...>& rv, const TRange& range)
{
    return rv.get(range);
}

template <class... Ts, class... TInt, std::enable_if_t<(std::is_integral_v<TInt> && ...), bool>>
auto get(const rec_var_base<Ts...>& rv, TInt... idx)
{
    return rv.get(idx...);
}

template <class TRecVar, class... TInt, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
TRecVar select(const TRecVar& rv, TInt... idx)
{
    TRecVar ret;
    (ret.append(rv[idx]), ...);
    return ret;
}

template <class TRecVar, class TRange, std::enable_if_t<is_rec_var<TRecVar>::value, bool>, std::enable_if_t<!std::is_integral_v<TRange>, bool>>
TRecVar select(const TRecVar& rv, const TRange& range)
{
    TRecVar ret;
    for(const auto& idx : range)
    {
        ret.append(rv[idx]);
    }
    return ret;
}

template <class TRecVar>
TRecVar unwrap(const TRecVar& rv)
{
    if(holds_vector(rv) && (rank(rv) == 1))
    {
        return unwrap(rv[0]);
    }
    return rv;
}

template <class... TAs, class... TBs>
bool is_congruent(const rec_var_base<TAs...>& rvA, const rec_var_base<TBs...>& rvB)
{
    using rva_t = rec_var_base<TAs...>;
    using rvb_t = rec_var_base<TBs...>;
    if(holds_leaf(rvA) && holds_leaf(rvB))
    {
        return true;
    }

    if(!(holds_vector(rvA) && holds_vector(rvB)))
    {
        /* If A and B are not leaf or vector at the same time, they are not congruent unless they are tile type,
         * non-vector element is a layout type. In this case, we continue to check whether layout's shape and stride
         * are congruent recursively.
         */
        if constexpr(detail::has_member_shape<typename std::tuple_element_t<0, typename rva_t::elem_types_t>>::value &&
                     detail::has_member_stride<typename std::tuple_element_t<0, typename rva_t::elem_types_t>>::value &&
                     detail::has_member_shape<typename std::tuple_element_t<0, typename rvb_t::elem_types_t>>::value &&
                     detail::has_member_stride<typename std::tuple_element_t<0, typename rvb_t::elem_types_t>>::value)
        {
            return is_congruent(std::get<1>(rvA).shape(), std::get<1>(rvB).shape()) &&
                   is_congruent(std::get<1>(rvA).stride(), std::get<1>(rvB).stride());
        }
        else
        {
            return false;
        }
    }

    if(rank(rvA) != rank(rvB))
    {
        return false;
    }

    if(holds_vector(rvA) && holds_vector(rvB))
    {
        for(size_t i = 0; i < rank(rvA); ++i)
        {
            if(!is_congruent(rvA[i], rvB[i]))
            {
                return false;
            }
        }
    }

    return true;
}

template <class... TAs, class... TBs>
bool weakly_congruent(const rec_var_base<TAs...>& rvA, const rec_var_base<TBs...>& rvB)
{
    if(holds_vector(rvA) && holds_vector(rvB))
    {
        if(rank(rvA) != rank(rvB))
        {
            return false;
        }
        else
        {
            for(size_t i = 0; i < rank(rvA); ++i)
            {
                if(!weakly_congruent(rvA[i], rvB[i]))
                {
                    return false;
                }
            }
            return true;
        }
    }

    if(holds_leaf(rvA))
    {
        return true;
    }

    return false;
}

template <class TRecVarA, class TRecVarB>
bool compatible(const TRecVarA& rvA, const TRecVarB& rvB)
{
    if(holds_int(rvA))
        return (rvA.as_int() == product(rvB));
    else if(rank(rvA) != rank(rvB))
        return false;
    else
    {
        for(size_t i = 0; i < rank(rvA); ++i)
        {
            if(!compatible(get_vector_elem(rvA, i),
                           get_vector_elem(rvB, i)))
                return false;
        }
        return true;
    }
}

template <class TRecVar>
size_t leaf_count(const TRecVar& rv)
{
    return fold(rv,
                size_t(0),
                [](size_t init, const TRecVar&) //
                {
                    return (init + 1);
                });
}

template <class TRecVar, class Fn>
size_t leaf_count_if(const TRecVar& rv, Fn&& f)
{
    return fold(rv,
                0,
                [&f](size_t init, const TRecVar& a) //
                {
                    return (f(a) ? (init + 1) : init);
                });
}

template <class TRecVar, class T>
T wrap_if_leaf(TRecVar&& rv)
{
    if(holds_leaf(rv))
    {
        return T(std::vector<T>{{rv}});
    }
    else
    {
        return T{std::forward<TRecVar>(rv)};
    }
}

template <class TPredicate, class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
bool any_leaf_is(const TRecVar& rv,
                 TPredicate&&   f)
{
    if(holds_vector(rv))
    {
        for(auto& e : get_vector(rv))
        {
            if(any_leaf_is(e, f))
            {
                return true;
            }
        }
        return false;
    }
    else
    {
        return f(rv);
    }
}

template <class TPredicate, class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
bool all_leaves(const TRecVar& rv,
                TPredicate&&   f)
{
    if(holds_vector(rv))
    {
        for(auto& e : get_vector(rv))
        {
            if(!all_leaves(e, f))
            {
                return false;
            }
        }
        return true;
    }
    else
    {
        return f(rv);
    }
}

namespace detail
{
// Support function for the leaf_at_fpos() function below.
template <class TRV>
TRV* leaf_at_fpos_(TRV& rv, size_t& cur, size_t idx)
{
    if(holds_leaf(rv))
    {
        // Increment the current index before returning
        return (cur++ == idx) ? &rv : nullptr;
    }
    else
    {
        for(auto& e : get_vector(rv))
        {
            TRV* p = leaf_at_fpos_(e, cur, idx);
            if(p)
            {
                return p;
            }
        }
        return nullptr;
    }
}
} // namespace detail

template <class TRecVar>
TRecVar& leaf_at_fpos(TRecVar& rv, size_t idx)
{
    size_t cur = 0;
    return *detail::leaf_at_fpos_(rv, cur, idx);
}

template <class TRecVar, class T>
TRecVar repeat(const size_t n, const T& value)
{
    TRecVar res;
    for(size_t i = 0; i < n; i++) res.append(value);
    return res;
}

template <class TRV1,
          class TRV0,
          class T,
          std::enable_if_t<is_rec_var_and_convertible_from_type<TRV1, T>::value, bool>>
TRV1 repeat_like(const TRV0& rv, const T& value)
{
    if(holds_leaf(rv)) return value;
    TRV1 res;
    for(size_t i = 0; i < rank(rv); i++) res.append(repeat_like<TRV1>(rv[i], value));
    return res;
}

template <class TRecVar, class TElem>
auto append_to_rank_N(size_t N, const TRecVar& rv, const TElem& e)
{
    TRecVar res = rv;
    for(auto i = rank(rv); i < N; i++)
    {
        res.append(e);
    }
    return res;
}

template <class TRecVar, class TElem>
auto prepend_to_rank_N(size_t N, const TRecVar& rv, const TElem& e)
{
    if(rank(rv) >= N)
        return rv;

    TRecVar res = repeat<TRecVar>(N - rank(rv), e);
    for(auto x : rv)
    {
        res.append(x);
    }
    return res;
}

template <class TRecVar, class TElem, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
auto insert(int pos, TRecVar tup, TElem x)
{
    using rv_t = TRecVar;
    if(pos > (int)rank(tup) || pos < 0 || !holds_vector(tup))
        return rv_t(cg_error_t{});

    auto& vect = get_vector(tup);
    vect.insert(vect.begin() + pos, x);
    return tup;
}

template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
auto get_leaves(const TRecVar& rv) -> std::vector<typename TRecVar::leaf_t>
{
    std::vector<typename TRecVar::leaf_t> vec;
    detail::get_leaves(rv, vec);
    return vec;
}

template <class... TLeafTypes,
          class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
auto get_leaves_with_type(const TRecVar& rv) -> std::vector<typename get_leaves_type<TLeafTypes...>::type>
{
    // The vector element type will be the single type if sizeof...(TLeafTypes)
    // is 1, and std::variant<TLeafTypes...> otherwise.
    using vec_elem_t = typename get_leaves_type<TLeafTypes...>::type;
    std::vector<vec_elem_t> res;
    detail::get_leaves_with_type<TLeafTypes...>(rv, res);
    return res;
}

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
auto group(int B, int E, const TRecVar& t)
{
    using rv_t = TRecVar;
    // Edge case 1
    if(holds_leaf(t))
    {
        // Place the leaf item into a variant that holds a vector
        return detail::construct<rv_t>(t.begin(), t.end());
    }
    auto R = static_cast<int>(rank(t));

    // Should ensure that -rank <= beginNum and beginNum < rank
    if((B < -R) || (B >= R))
    {
        return rv_t(cg_error_t{});
    }

    // Should ensure that -rank+1 <= endNum and endNum <= rank
    if((E <= -R) || (E > R))
    {
        return rv_t(cg_error_t{});
    }

    B = (B < 0) ? (R + B) : B;
    E = (E < 0) ? (R + E) : E;

    // Should ensure that beginNum < endNum
    if(B >= E)
    {
        return rv_t(cg_error_t{});
    }
    auto t0 = detail::construct<rv_t>(t.begin(), t.begin() + B);
    auto t1 = detail::construct<rv_t>(t.begin() + B, t.begin() + E);
    t0.append(t1);
    for(auto it = t.begin() + E; it != t.end(); ++it)
        t0.append(*it);
    return t0;
}

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
auto take(int B, int E, const TRecVar& t)
{
    using rv_t = TRecVar;
    // Readjust the end index
    auto R = static_cast<int>(rank(t));
    (E < 0) ? E = R : E = std::min(E, R);
    // B >= E
    if(B >= E) return rv_t{};
    // General case
    assert((B < E) && (E <= R));
    return detail::construct<rv_t>(t.begin() + B, t.begin() + E);
}

template <class T0, class... Ts>
T0 cat_tuple(const T0& a, Ts&&... b)
{
    T0 rv(a);
    // lambda is unused when b is empty
    [[maybe_unused]] auto append_to_result = [&](const auto& b_arg) {
        if(holds_vector(b_arg))
        {
            // Add each element of the tuple individually
            for(auto& e : get_vector(b_arg))
            {
                rv.append(e);
            }
        }
        else
        {
            // Add the leaf element
            rv.append(b_arg);
        }
    };
    // Call append_to_result() for each b argument using a fold expression
    // with the comma operator to expand the variadic template.
    (append_to_result(b), ...);
    return rv;
}

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
auto rec_var_tuple_cat(const TRecVar& rv)
{
    using rv_t  = TRecVar;
    using vec_t = typename rv_t::vector_t;
    bool ok     = holds_vector(rv);
    if(!ok) return rv_t(cg_error_t{});
    for(size_t i = 0; i < rank(rv); i++)
        ok = ok && holds_vector(rv[i]);
    if(!ok) return rv_t(cg_error_t{});
    rv_t res; // Empty vector
    for(size_t i = 0; i < rank(rv); i++)
    {
        const vec_t& v     = get_vector(get_vector_elem(rv, i));
        vec_t&       v_res = get_vector(res);
        v_res.insert(v_res.end(), v.begin(), v.end());
    }
    return res;
}

template <class T, class X>
auto prepend(const T& a, const X& x)
{
    return cat_tuple(a, x);
}

template <class T, class X>
auto replace_front(const T& t, const X& x)
{
    T cp(x);
    if(holds_vector(t))
    {
        // Skip the first element!
        for(auto it = ++get_vector(t).begin();
            it != get_vector(t).end();
            ++it)
        {
            cp.append(*it);
        }
    }
    return cp;
}

template <class TRVA, class TRVB, class TEnable>
bool elem_less(const TRVA& lhs, const TRVB& rhs)
{
    if(holds_vector(lhs) && holds_vector(rhs))
    {
        for(size_t i = 0; i < rank(lhs); ++i)
        {
            // if:
            // - lhs is not exhausted, rhs is exhausted: return false
            // - !(lhs[v] < rhs[v])
            // return false
            if((i >= rank(rhs)) ||
               !elem_less(get_vector_elem(lhs, i),
                          get_vector_elem(rhs, i)))
            {
                return false;
            }
        }
        // Either:
        // - lhs is exhausted, rhs is not exhausted: return true
        // - all lhs < rhs: return true
        return true;
    }
    else
    {
        // Perform direct element comparison
        return lhs.as_int() < rhs.as_int();
    }
}

template <class TA, class TB>
bool lex_less(const TA& lhs, const TB& rhs)
{
    if(holds_vector(lhs) && holds_vector(rhs))
    {
        for(size_t i = 0; i < rank(lhs); ++i)
        {
            // For comparison of sequences with different sizes, the
            // result is as if the shorter sequence is padded with a
            // value that is smaller than all other possible values.
            if(i >= rank(rhs))
            {
                return false;
            }
            if(lex_less(get_vector_elem(lhs, i),
                        get_vector_elem(rhs, i)))
            {
                return true;
            }
            else if(lex_less(get_vector_elem(rhs, i),
                             get_vector_elem(lhs, i)))
            {
                return false;
            }
            // if neither (lhs < rhs) nor (rhs < lhs) are true, we
            // must have lhs == rhs. We will check the next element.
        }
        // All elements were equal.
        return false;
    }
    else
    {
        assert(holds_int(lhs) && holds_int(rhs));
        // Perform direct element comparison
        return lhs.as_int() < rhs.as_int();
    }
}

template <class TA, class TB>
bool colex_less(const TA& lhs, const TB& rhs)
{
    if(holds_vector(lhs) && holds_vector(rhs))
    {
        if(rank(lhs) != rank(rhs))
        {
            // For comparison of sequences with different sizes, the
            // result is as if the shorter sequence is padded with a
            // value that is smaller than all other possible values.
            return (rank(lhs) < rank(rhs));
        }
        for(size_t i = rank(lhs); i > 0; --i)
        {
            const size_t idx = i - 1;
            if(colex_less(get_vector_elem(lhs, idx),
                          get_vector_elem(rhs, idx)))
            {
                return true;
            }
            else if(colex_less(get_vector_elem(rhs, idx),
                               get_vector_elem(lhs, idx)))
            {
                return false;
            }
            // if neither (lhs < rhs) nor (rhs < lhs) are true, we
            // must have lhs == rhs. We will check the next element.
        }
        // All elements were equal.
        return false;
    }
    else
    {
        // Perform direct element comparison
        return lhs.as_int() < rhs.as_int();
    }
}

template <class T>
T zip(const T& t)
{
    if(holds_leaf(t)) return t;
    if(is_empty(t)) return t;
    if(holds_leaf(t[0]))
    {
        // Wrap t once more
        // Not sure why this is the natural implementation, but this is required to make it
        // consistent with C++
        T res;
        res.append(t);
        return res;
    }

    if(!std::all_of(t.begin(), t.end(), [&](const auto& e) { return rank(e) == rank(t[0]); }) ||
       !std::all_of(t.begin(), t.end(), [](const auto& e) { return depth(e) > 0; }))
    {
        return cg_error_t{};
    }

    T rv;
    for(size_t i = 0; i < rank(t[0]); ++i)
    {
        T inner;
        std::for_each(t.begin(),
                      t.end(),
                      [&](const auto& e) //
                      {
                          inner.append(e[i]);
                      });
        rv.append(std::move(inner));
    };
    return rv;
}

template <class T0, class T1, class... Tn>
T0 zip(const T0& t0, const T1& t1, const Tn&... tn)
{
    T0 rv;
    rv.append(t0, t1, tn...);
    return zip(rv);
}

template <class TRecVar>
TRecVar reverse(const TRecVar& rv)
{
    if(!holds_vector(rv))
        return rv;

    using vector_t = typename TRecVar::vector_t;
    auto& vect     = std::get<typename TRecVar::vector_t>(rv);
    return TRecVar{vector_t{vect.rbegin(), vect.rend()}};
}

template <class TRecVar, class T, class BinaryFunction>
T fold(const TRecVar& rv, const T& init, BinaryFunction&& fn)
{
    if(!holds_vector(rv))
    {
        return fn(init, rv);
    }
    else
    {
        T val = init;
        for(auto& c : get_vector(rv))
        {
            val = fold(c, val, fn);
        }
        return val;
    }
}

template <class TRV0, class TRV1, class T, class BinaryFunction, class TEnable>
auto fold_with_profile(const TRV0& rv, const TRV1& profile, const T& init, BinaryFunction&& fn)
{
    using result_t = std::invoke_result_t<BinaryFunction, T, TRV0>;
    if(holds_leaf(profile))
    {
        return fn(init, rv);
    }
    else
    {
        T val = init;
        if(rank(rv) != rank(profile)) return result_t(cg_error_t{});
        for(size_t i = 0; i < rank(rv); i++)
        {
            val = fold_with_profile(rv[i], profile[i], val, fn);
        }
        return val;
    }
}

template <class TFunction, class TRV0, class... TRVs>
auto transform(TFunction&& fn, const TRV0& rv0, const TRVs&... rvArgs)
{
    using result_t = std::invoke_result_t<TFunction, TRV0, TRVs...>;
    if(!holds_vector(rv0) && (!holds_vector(rvArgs) && ...))
        return result_t(fn(rv0, rvArgs...));
    else if(holds_vector(rv0) && (holds_vector(rvArgs) && ...))
    {
        result_t rv;
        for(size_t i = 0; i < rank(rv0); ++i)
            rv.append(fn(get_vector_elem(rv0, i), get_vector_elem(rvArgs, i)...));
        return rv;
    }
    else
    {
        // Mismatched tuples...
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        throw std::runtime_error("Incompatible stride/index values");
#else
        return result_t(cg_error_t{});
#endif
    }
}

template <class TF, class TG, class TRV0, class... TRVs>
auto transform_apply(TF&& f, TG&& g, const TRV0& rv0, const TRVs&... rvArgs)
{
    return g(transform(f, rv0, rvArgs...));
}

namespace detail
{
// MSVC can error with C2187 on generic lambdas (`auto` parameters) used here;
// a function template avoids that parser bug.
template <class TRV0, class T>
bool transform_leaf_ranks_equal(const TRV0& r0, const T& t)
{
    return rank(r0) == rank(t);
}
} // namespace detail

template <class TFunction, class TRV0, class... TRVs>
auto transform_leaf(TFunction&& fn, const TRV0& rv0, const TRVs&... rvArgs)
{
    using result_t = std::invoke_result_t<TFunction, TRV0, TRVs...>;

    if(!holds_vector(rv0))
    {
        return result_t(fn(rv0, rvArgs...));
    }
    else if((detail::transform_leaf_ranks_equal(rv0, rvArgs) && ...))
    {
        result_t rv;
        for(size_t i = 0; i < rank(rv0); ++i)
        {
            rv.append(transform_leaf(fn, rv0[i], rvArgs[i]...));
        }
        return rv;
    }
    else
    {
        // Mismatched tuples...
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        throw std::runtime_error("Incompatible stride/index values");
#else
        return result_t(cg_error_t{});
#endif
    }
}

template <class TG, class TF, class TRV0, class... TRVs>
auto transform_apply_leaf(TG&& g, TF&& f, const TRV0& rv0, const TRVs&... rvArgs)
{
    using result_f_t = std::invoke_result_t<TF, TRV0, TRVs...>;
    using result_g_t = std::invoke_result_t<TG, std::vector<result_f_t>>;
    // Currently required because the function returns either f() or g(),
    // but there may be more general implementations possible.
    static_assert(std::is_same_v<result_f_t, result_g_t>);

    // We may encounter empty () tuples with rank 0 when we iterate using the
    // maximum rank of a pack of arguments as the upper bound. (For lower rank
    // variables, the user functions will be passed a default-initialized value,
    // which is () for tuple types.)
    if(!holds_vector(rv0) || (0 == rank(rv0)))
    {
        return f(rv0, rvArgs...);
    }
    //result_f_t rv;
    std::vector<result_f_t> rv;
    for(size_t i = 0; i < max_rank(rv0, rvArgs...); ++i)
    {
        rv.push_back(transform_apply_leaf(g,
                                          f,
                                          (i < rank(rv0)) ? rv0[i] : decltype(rv0){},
                                          ((i < rank(rvArgs)) ? rvArgs[i] : decltype(rvArgs){})...));
    }
    return g(rv);
}

template <class IntTupleA, class IntTupleB>
IntTupleB filter_zeros(const IntTupleA& a, const IntTupleB& b)
{
    if(holds_vector(a))
    {
        return transform_leaf([](const IntTupleA& x, const IntTupleB& y) //
                              {
                                  return filter_zeros(x, y);
                              },
                              a,
                              b);
    }
    else if(holds_int(a) && (0 == a.as_int()))
    {
        return IntTupleB(1);
    }
    else
    {
        return b;
    }
}

template <class IntTuple>
IntTuple filter_zeros(const IntTuple& t)
{
    return filter_zeros(t, t);
}

template <class IntTuple, std::enable_if_t<is_rec_var<IntTuple>::value, bool>>
IntTuple flatten(const IntTuple& t)
{
    if(holds_vector(t))
    {
        return fold(t,
                    IntTuple(),
                    [](const IntTuple& a, const IntTuple& b) //
                    {
                        return cat_tuple(a, b);
                    });
    }
    else
    {
        return t;
    }
}

template <class IntTupleSrc,
          class TDst,
          std::enable_if_t<is_rec_var<IntTupleSrc>::value, bool>>
void flatten_into(const IntTupleSrc& tSrc, TDst& tDst)
{
    if(holds_vector(tSrc))
    {
        for(auto& e : get_vector(tSrc))
        {
            flatten_into(e, tDst);
        }
    }
    else
    {
        tDst.append(tSrc);
    }
}

//
// Integral variant
//

template <class TRecVar>
bool holds_int(TRecVar&& rv)
{
    using int_t = typename std::remove_reference<TRecVar>::type::int_t;
    if constexpr(std::is_same_v<int_t, void>)
    {
        // TRecVar cannot hold any integral type
        return false;
    }
    else
    {
        return std::holds_alternative<int_t>(std::forward<TRecVar>(rv));
    }

    CUTEGEN_GCC_UNREACHABLE;
}

template <class... T>
bool all_hold_int(const T&... values)
{
    return (holds_int(values) && ...);
}

template <class TRecVar>
auto&& get_int(TRecVar&& rv)
{
    using int_t = typename std::remove_reference<TRecVar>::type::int_t;
    assert(holds_int(rv));
    return std::get<int_t>(std::forward<TRecVar>(rv));
}

template <class... TRecVarElemTypes>
bool is_integral_only(const rec_var_base<TRecVarElemTypes...>& rv)
{
    return fold(rv,
                true,
                [](bool pred, const auto& r) {
                    return pred && holds_int(r);
                });
}

//
// Vector variant
//

template <class TRecVar>
bool holds_vector(TRecVar&& rv)
{
    using vector_t = typename std::remove_reference<TRecVar>::type::vector_t;
    return std::holds_alternative<vector_t>(std::forward<TRecVar>(rv));
}

template <class TRecVar>
bool holds_leaf(TRecVar&& rv)
{
    return !holds_vector(std::forward<TRecVar>(rv));
}

template <class TRecVar>
auto&& get_vector(TRecVar&& rv)
{
    using vector_t = typename std::remove_reference<TRecVar>::type::vector_t;
    assert(holds_vector(rv));
    return std::get<vector_t>(std::forward<TRecVar>(rv));
}

template <class TRecVar>
auto&& get_vector_elem(TRecVar&& rv, size_t index)
{
    using vector_t = typename std::remove_reference<TRecVar>::type::vector_t;
    assert(holds_vector(rv));
    return std::get<vector_t>(std::forward<TRecVar>(rv)).at(index);
}

template <class... Ts>
bool is_empty(const rec_var_base<Ts...>& rv)
{
    return (holds_vector(rv) && get_vector(rv).empty());
}

//
// cg_error_t variant
//

template <class... TRecVarElemTypes>
bool holds_error(const rec_var_base<TRecVarElemTypes...>& rv)
{
    using rv_t = rec_var_base<TRecVarElemTypes...>;
    if constexpr(is_rec_var_and_can_hold_type<rv_t, cg_error_t>::value)
    {
        return std::holds_alternative<cg_error_t>(rv);
    }
    return false;
}

template <class... TRecVarElemTypes>
bool has_error(const rec_var_base<TRecVarElemTypes...>& rv)
{
    using rv_t = rec_var_base<TRecVarElemTypes...>;
    return any_leaf_is(rv,
                       [](const rv_t& rv) //
                       {
                           return holds_error(rv);
                       });
}

template <class... TRecVarElemTypes>
bool is_valid(const rec_var_base<TRecVarElemTypes...>& rv)
{
    return !has_error(rv);
}

//
// underscore variant
//

template <class... TRecVarElemTypes>
bool holds_underscore(const rec_var_base<TRecVarElemTypes...>& rv)
{
    using rv_t = rec_var_base<TRecVarElemTypes...>;
    if constexpr(is_rec_var_and_can_hold_type<rv_t, underscore_t>::value)
    {
        return std::holds_alternative<underscore_t>(rv);
    }
    return false;
}

template <class... TRecVarElemTypes>
bool has_underscore(const rec_var_base<TRecVarElemTypes...>& rv)
{
    using rv_t = rec_var_base<TRecVarElemTypes...>;
    return any_leaf_is(rv,
                       [](const rv_t& rv) //
                       {
                           return holds_underscore(rv);
                       });
}

template <class... TRecVarElemTypes>
bool is_underscore_only(const rec_var_base<TRecVarElemTypes...>& rv)
{
    // The desired value for empty recursive variant is not the one use for the initial fold's value
    if(is_empty(rv)) return false;
    return fold(rv,
                true,
                [](bool pred, const auto& r) {
                    return pred && holds_underscore(r);
                });
}

template <class... TLeaves,
          class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
bool has_only_leaves_of_type(const TRecVar& rv)
{
    return fold(rv,
                true,
                [](bool pred, const auto& r) {
                    return pred && detail::holds_any_alternative<TLeaves...>(r);
                });
}

template <class... TLeaves,
          class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
bool has_leaf_with_type(const TRecVar& rv)
{
    return any_leaf_is(rv, [](const TRecVar& rv) {
        return detail::holds_any_alternative<TLeaves...>(rv);
    });
}

//
// dynamic_t variant
//

template <class... TRecVarElemTypes>
bool holds_dynamic_int(const rec_var_base<TRecVarElemTypes...>& rv)
{
    using rv_t = rec_var_base<TRecVarElemTypes...>;
    if constexpr(is_rec_var_with_type_pred<rv_t, has_dynamic_t_base>::value)
    {
        using elem_types_t = typename rv_t::elem_types_t;
        using rv_dyn_t     = typename detail::find_in_tuple<elem_types_t, has_dynamic_t_base>::value;
        return std::holds_alternative<rv_dyn_t>(rv);
    }
    return false;
}

template <class... T>
bool none_holds_dynamic(const T&... t)
{
    return (!holds_dynamic_int(t) && ...);
}

template <class... TRecVarElemTypes>
bool has_dynamic(const rec_var_base<TRecVarElemTypes...>& rv)
{
    using rec_var_t = rec_var_base<TRecVarElemTypes...>;
    if constexpr(rec_var_has_dynamic_type<rec_var_t>::value)
    {
        return any_leaf_is(rv,
                           [](const rec_var_t& rv) //
                           {
                               return holds_dynamic_int(rv);
                           });
    }
    return false;
}

template <class... TRecVarElemTypes>
bool holds_int_or_dynamic_int(const rec_var_base<TRecVarElemTypes...>& rv)
{
    return holds_int(rv) || holds_dynamic_int(rv);
}

template <class TDst, class TSrc>
TDst get_int_or_dynamic_int(const TSrc& rv)
{
    assert(holds_int_or_dynamic_int(rv));
    if constexpr(rec_var_has_dynamic_type<TSrc>::value)
    {
        using dyn_t = typename find_dynamic_in_rec_var<TSrc>::value;
        static_assert(std::is_same_v<dyn_t, typename find_dynamic_in_rec_var<TDst>::value>);
        if(holds_dynamic_int(rv)) return std::get<dyn_t>(rv);
    }
    return rv.as_int();
}

template <class... TRecVarElemTypes>
auto get_dynamic_int(const rec_var_base<TRecVarElemTypes...>& rv)
{
    using rv_t = rec_var_base<TRecVarElemTypes...>;
    static_assert(rec_var_has_dynamic_type<rv_t>::value);
    assert(holds_dynamic_int(rv));
    using dyn_t = typename find_dynamic_in_rec_var<rv_t>::value;
    return std::get<dyn_t>(rv);
}

template <class... TRecVarElemTypes>
bool is_int_or_dynamic_int_only(const rec_var_base<TRecVarElemTypes...>& rv)
{
    return fold(rv,
                true,
                [](bool pred, const auto& r) {
                    return pred && holds_int_or_dynamic_int(r);
                });
}

//
// scaled_basis_t variant
//

template <class... TRecVarElemTypes>
bool holds_scaled_basis(const rec_var_base<TRecVarElemTypes...>& rv)
{
    using rv_t = rec_var_base<TRecVarElemTypes...>;
    if constexpr(rec_var_can_hold_scaled_basis<rv_t>::value)
    {
        using sb_t = typename find_scaled_basis_in_rec_var<rv_t>::value;
        return std::holds_alternative<sb_t>(rv);
    }
    return false;
}

template <class... TRecVarElemTypes>
auto get_scaled_basis(const rec_var_base<TRecVarElemTypes...>& rv)
{
    using rv_t = rec_var_base<TRecVarElemTypes...>;
    static_assert(rec_var_can_hold_scaled_basis<rv_t>::value);
    assert(holds_scaled_basis(rv));
    using sb_t = typename find_scaled_basis_in_rec_var<rv_t>::value;
    return std::get<sb_t>(rv);
}

template <class... TRecVarElemTypes>
bool has_scaled_basis(const rec_var_base<TRecVarElemTypes...>& rv)
{
    using rec_var_t = rec_var_base<TRecVarElemTypes...>;
    return any_leaf_is(rv,
                       [](const rec_var_t& rv) //
                       {
                           return holds_scaled_basis(rv);
                       });
}

//
// Others
//

template <class... Ts>
bool holds_int_like(const rec_var_base<Ts...>& rv)
{
    return holds_int(rv) || holds_dynamic_int(rv);
}

template <class... TTypes, class TRecVar>
bool holds_type(const TRecVar& rv)
{
    return detail::holds_any_alternative<TTypes...>(rv);
}

template <class... TTypes, class TElem>
bool all_hold_types(const std::vector<TElem>& values)
{
    return std::all_of(values.begin(),
                       values.end(),
                       [](const TElem& e) {
                           return detail::holds_any_alternative<TTypes...>(e);
                       });
}

} // namespace cutegen
#endif
