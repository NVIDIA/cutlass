/***************************************************************************************************
 * Copyright (c) 2024 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#pragma once

#include <cute/config.hpp>
#include <cute/util/type_traits.hpp>
#include <cute/numeric/integral_constant.hpp>
#include <cute/container/type_list.hpp>

namespace cute {

namespace detail {

// Empty Structure Optimization
template <bool IsFirstEmpty, bool IsRestEmpty, class... T>
struct ESO;

template <class First, class... Rest>
static constexpr bool is_first_empty_v = cute::is_empty<First>::value;
template <class First, class... Rest>
static constexpr bool is_rest_empty_v  = (cute::is_empty<Rest>::value && ...);

template <class... T>
using ESO_t = ESO<is_first_empty_v<T...>, is_rest_empty_v<T...>, T...>;

// Empty First and Empty Rest...
template <class First, class... Rest>
struct ESO<true, true, First, Rest...> {
  CUTE_HOST_DEVICE constexpr
  ESO() {}

  CUTE_HOST_DEVICE constexpr
  ESO(First const&, Rest const&...) {}
};

// NonEmpty First and Empty Rest...
template <class First, class... Rest>
struct ESO<false, true, First, Rest...> {
  CUTE_HOST_DEVICE constexpr
  ESO() : first_{} {}

  CUTE_HOST_DEVICE constexpr
  ESO(First const& first, Rest const&...) : first_{first} {}

  First first_;
};

// Empty First and NonEmpty Rest...
template <class First, class... Rest>
struct ESO<true, false, First, Rest...> {
  CUTE_HOST_DEVICE constexpr
  ESO() : rest_{} {}

  CUTE_HOST_DEVICE constexpr
  ESO(First const&, Rest const&... rest) : rest_{rest...} {}

  ESO_t<Rest...> rest_;
};

// NonEmpty T and NonEmpty Rest...
template <class First, class... Rest>
struct ESO<false, false, First, Rest...> {
  CUTE_HOST_DEVICE constexpr
  ESO() : first_{}, rest_{} {}

  CUTE_HOST_DEVICE constexpr
  ESO(First const& first, Rest const&... rest) : first_{first}, rest_{rest...} {}

  First first_;
  ESO_t<Rest...> rest_;
};

// Get Nth value from ESO
template <size_t N, class T, class... Rest, bool F, bool R>
CUTE_HOST_DEVICE constexpr decltype(auto) getv(ESO<F, R, T, Rest...> const& s) {
  if constexpr (N == 0) {
    if constexpr (F) { return T{}; }
    else             { return static_cast<T const&>(s.first_); }
  } else {
    if constexpr (R) { return cute::tuple_element_t<N-1, cute::type_list<Rest...>>{}; }
    else             { return getv<N-1>(s.rest_); }
  }
}

template <size_t N, class T, class... Rest, bool F, bool R>
CUTE_HOST_DEVICE constexpr decltype(auto) getv(ESO<F, R, T, Rest...>& s) {
  if constexpr (N == 0) {
    if constexpr (F) { return T{}; }
    else             { return static_cast<T&>(s.first_); }
  } else {
    if constexpr (R) { return cute::tuple_element_t<N-1, cute::type_list<Rest...>>{}; }
    else             { return getv<N-1>(s.rest_); }
  }
}

template <size_t N, class T, class... Rest, bool F, bool R>
CUTE_HOST_DEVICE constexpr decltype(auto) getv(ESO<F, R, T, Rest...>&& s) {
  if constexpr (N == 0) {
    if constexpr (F) { return T{}; }
    else             { return static_cast<T&&>(s.first_); }
  } else {
    if constexpr (R) { return cute::tuple_element_t<N-1, cute::type_list<Rest...>>{}; }
    else             { return getv<N-1>(static_cast<ESO_t<Rest...>&&>(s.rest_)); }
  }
}

// findt: Implementation detail of cute::find.
// If X is the first template argument of the tuple, findt returns C<N>.

template <class X, size_t N,
  bool IsFirstEmpty, bool IsRestEmpty, class First, class... Rest>
CUTE_HOST_DEVICE constexpr
auto
findt(ESO<IsFirstEmpty, IsRestEmpty, First, Rest...> const& t) noexcept
{
  if constexpr (cute::is_same_v<X, First>) {
    return C<N>{};
  }
  else {
    static_assert(sizeof...(Rest) != 0,
      "The type does not appear in the argument list of the tuple.");
    if constexpr (IsRestEmpty) {
      // The rest is empty, so creating an instance of it is cheap.
      return cute::detail::findt<X, N+1>(ESO_t<Rest...>{});
    }
    else {
      return cute::detail::findt<X, N+1>(t.rest_);
    }
  }
}

} // end namespace detail

// packed_tuple<T...> is a tuple type that is a standard-layout type
// whenever all of its template arguments are standard layout types:
//   (cute::is_standard_layout_v<T> && ...) implies (cute::is_standard_layout_v<packed_tuple<T...>>)

template <class... T>
struct packed_tuple : detail::ESO_t<T...>
{
  CUTE_HOST_DEVICE constexpr
  packed_tuple() {}

  CUTE_HOST_DEVICE constexpr
  packed_tuple(T const&... ts)
    : detail::ESO_t<T...>(ts...)
  {}
};

template <>
struct packed_tuple<> {};

template <size_t I, class... T>
CUTE_HOST_DEVICE constexpr
decltype(auto)
get(packed_tuple<T...> const& t) {
  static_assert(I < sizeof...(T), "Index out of range");
  return detail::getv<I>(t);
}

template <size_t I, class... T>
CUTE_HOST_DEVICE constexpr
decltype(auto)
get(packed_tuple<T...>& t) {
  static_assert(I < sizeof...(T), "Index out of range");
  return detail::getv<I>(t);
}

template <size_t I, class... T>
CUTE_HOST_DEVICE constexpr
decltype(auto)
get(packed_tuple<T...>&& t) {
  static_assert(I < sizeof...(T), "Index out of range");
  return detail::getv<I>(static_cast<detail::ESO_t<T...>&&>(t));
}

template <class... T>
CUTE_HOST_DEVICE constexpr
packed_tuple<T...>
make_packed_tuple(T const&... t)
{
  return {t...};
}

// Returns the position of type X (as a static integer) in the tuple
// type's argument list.  X must be unique in the argument list.
template <class X, class... T>
CUTE_HOST_DEVICE constexpr
auto
find(packed_tuple<T...> const& t) noexcept
{
  return detail::findt<X, 0>(t);
}

} // end namespace cute

namespace CUTE_STL_NAMESPACE
{

template <class... T>
struct tuple_size<cute::packed_tuple<T...>>
    : CUTE_STL_NAMESPACE::integral_constant<size_t, sizeof...(T)>
{};

template <size_t I, class... T>
struct tuple_element<I, cute::packed_tuple<T...>>
    : CUTE_STL_NAMESPACE::tuple_element<I, CUTE_STL_NAMESPACE::tuple<T...>>
{};

} // end namespace CUTE_STL_NAMESPACE

#ifdef CUTE_STL_NAMESPACE_IS_CUDA_STD
namespace std {

template <class ... T>
struct tuple_size<cute::packed_tuple<T...>>
  : CUTE_STL_NAMESPACE::integral_constant<size_t, sizeof...(T)>
{};

template <size_t I, class ... T>
struct tuple_element<I, cute::packed_tuple<T...>>
  : CUTE_STL_NAMESPACE::tuple_element<I, cute::packed_tuple<T...>>
{};

} // end namespace std
#endif // CUTE_STL_NAMESPACE_IS_CUDA_STD
