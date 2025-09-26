/***************************************************************************
 *
 *  Copyright (C) Codeplay Software Ltd.
 *  Copyright (C) 2025 Intel Corporation, All rights reserved.
 *
 *  Part of the LLVM Project, under the Apache License v2.0 with LLVM
 *  Exceptions. See https://llvm.org/LICENSE.txt for license information.
 *  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 *  SYCL compatibility extension
 *
 *  traits.hpp
 *
 *  Description:
 *    Type traits for the SYCL compatibility extension
 **************************************************************************/

#pragma once
#pragma GCC system_header

#include <sycl/feature_test.hpp>
#ifdef SYCL_EXT_ONEAPI_BFLOAT16_MATH_FUNCTIONS
#include <sycl/ext/oneapi/bfloat16.hpp>
#endif
#include <cstddef>
#include <sycl/ext/oneapi/properties/properties.hpp>
#include <sycl/ext/oneapi/properties/property_value.hpp>
#include <sycl/range.hpp>
#include <sycl/nd_range.hpp>
#include <type_traits>

namespace compat {

// Equivalent to C++20's std::type_identity (used to create non-deduced
// contexts)
template <class T> struct type_identity {
  using type = T;
};
template <class T> using type_identity_t = typename type_identity<T>::type;

// Defines the operand type for arithemtic operations on T. This is identity
// for all types except pointers, for which it is std::ptrdiff_t
template <typename T> struct arith {
  using type = std::conditional_t<std::is_pointer_v<T>, std::ptrdiff_t, T>;
};
template <typename T> using arith_t = typename arith<T>::type;

// Traits to check device function signature matches args (with or without local
// mem)
template <auto F, typename... Args>
struct device_fn_invocable : std::is_invocable<decltype(F), Args...> {};

template <auto F, typename... Args>
struct device_fn_lmem_invocable
    : std::is_invocable<decltype(F), Args..., char *> {};

template <typename LaunchPolicy, auto F, typename... Args>
constexpr inline bool args_compatible =
    std::conditional_t<LaunchPolicy::HasLocalMem,
                       device_fn_lmem_invocable<F, Args...>,
                       device_fn_invocable<F, Args...>>::value;

namespace detail {

// Trait for identifying sycl::range and sycl::nd_range.
template <typename T> struct is_range : std::false_type {};
template <int Dim> struct is_range<sycl::range<Dim>> : std::true_type {};

template <typename T> constexpr bool is_range_v = is_range<T>::value;

template <typename T> struct is_nd_range : std::false_type {};
template <int Dim> struct is_nd_range<sycl::nd_range<Dim>> : std::true_type {};

template <typename T> constexpr bool is_nd_range_v = is_nd_range<T>::value;

template <typename T>
constexpr bool is_range_or_nd_range_v =
    std::disjunction_v<is_range<T>, is_nd_range<T>>;

// Trait range_to_item_t to convert nd_range -> nd_item, range -> item
template <typename T> struct range_to_item_map;
template <int Dim> struct range_to_item_map<sycl::nd_range<Dim>> {
  using ItemT = sycl::nd_item<Dim>;
};
template <int Dim> struct range_to_item_map<sycl::range<Dim>> {
  using ItemT = sycl::item<Dim>;
};

template <typename T>
using range_to_item_t = typename range_to_item_map<T>::ItemT;

} // namespace detail

// Forward decls
namespace experimental {

template <typename Properties> struct kernel_properties;
template <typename Properties> struct launch_properties;
struct local_mem_size;

template <typename Range, typename KProps, typename LProps, bool LocalMem>
class launch_policy;
} // namespace experimental

namespace experimental::detail {

// Helper for tuple_template_index
template <template <typename TT> typename PropertyContainer, typename Tuple>
struct tuple_template_index_helper;

template <template <typename TT> typename PropertyContainer>
struct tuple_template_index_helper<PropertyContainer, std::tuple<>> {
  static constexpr std::size_t value = 0;
};

template <template <typename TT> typename PropertyContainer, typename T,
          typename... Rest>
struct tuple_template_index_helper<PropertyContainer,
                                   std::tuple<PropertyContainer<T>, Rest...>> {
  static constexpr std::size_t value = 0;
  using RestTuple = std::tuple<Rest...>;
  static_assert(
      tuple_template_index_helper<PropertyContainer, RestTuple>::value ==
          std::tuple_size_v<RestTuple>,
      "type appears more than once in tuple");
};

template <template <typename TT> typename PropertyContainer, typename First,
          typename... Rest>
struct tuple_template_index_helper<PropertyContainer,
                                   std::tuple<First, Rest...>> {
  using RestTuple = std::tuple<Rest...>;
  static constexpr std::size_t value =
      1 + tuple_template_index_helper<PropertyContainer, RestTuple>::value;
};

// tuple_template_index is a trait helper which finds the index of a class
// template in a std::tuple<Ts...>. During template argument deduction for
// launch, this enables us to search the tuple for e.g. `kernel_properties`
// without knowing the concrete type (e.g. kernel_properties<KProps>) A compile
// time error is raised if the class template is found more than once. If not
// found, returns the tuple size (i.e. this is not an error).
template <template <typename TT> typename PropertyContainer, typename Tuple>
struct tuple_template_index {
  static constexpr std::size_t value =
      tuple_template_index_helper<PropertyContainer, Tuple>::value;
};

// tuple_contains_template piggy-backs on the functionality of
// tuple_template_index to detect whether a class template exists in the tuple
template <template <typename TT> typename PropertyContainer, typename Tuple>
    struct tuple_contains_template
    : std::conditional_t <
      tuple_template_index<PropertyContainer, Tuple>::value<
          std::tuple_size_v<Tuple>, std::true_type, std::false_type> {};

template <bool TupleContains, typename PropertyContainerConcrete,
          typename Tuple>
struct property_getter_helper;

template <typename PropertyContainerConcrete, typename Tuple>
struct property_getter_helper<true, PropertyContainerConcrete, Tuple> {
  PropertyContainerConcrete operator()(Tuple tuple) {
    return std::get<PropertyContainerConcrete>(tuple);
  }
};

template <typename PropertyContainerConcrete, typename Tuple>
struct property_getter_helper<false, PropertyContainerConcrete, Tuple> {
  PropertyContainerConcrete operator()(Tuple) {
    return {};
  }
};

// For local_mem_size
template <typename T, typename Tuple> struct has_type;

template <typename T, typename... Us>
struct has_type<T, std::tuple<Us...>>
    : std::disjunction<std::is_same<T, Us>...> {};

template <template <typename TT> typename PropertyContainer,
          typename PropertyContainerConcrete, typename Tuple>
using property_getter = property_getter_helper<
    detail::tuple_contains_template<PropertyContainer, Tuple>::value,
    PropertyContainerConcrete, Tuple>;

template <typename PropertyContainerConcrete, typename Tuple>
using local_mem_getter =
    property_getter_helper<has_type<PropertyContainerConcrete, Tuple>::value,
                           PropertyContainerConcrete, Tuple>;

// Helpers for properties_or_empty
template <bool InTuple, template <typename TT> typename PropertyContainer,
          typename... Ts>
struct properties_or_empty_helper;

template <template <typename TT> typename PropertyContainer, typename... Ts>
struct properties_or_empty_helper<false, PropertyContainer, Ts...> {
  using Props = sycl::ext::oneapi::experimental::empty_properties_t;
};

template <template <typename TT> typename PropertyContainer, typename... Ts>
struct properties_or_empty_helper<true, PropertyContainer, Ts...> {
  using Props = typename std::tuple_element_t<
      tuple_template_index<PropertyContainer, std::tuple<Ts...>>::value,
      std::tuple<Ts...>>::Props;
};

// Template type alias which searches variadic types for e.g.
// compat::experimental::kernel_properties, launch_properties and returns
// the contained sycl_exp::properties. If not found, returns
// sycl_exp::empty_properties_t
template <template <typename TT> typename PropertyContainer, typename... Ts>
using properties_or_empty = typename properties_or_empty_helper<
    tuple_contains_template<PropertyContainer, std::tuple<Ts...>>::value,
    PropertyContainer, Ts...>::Props;

// Traits to detect objects related to compat_exp::launch
// ========================================================

// Trait to detect compat_exp::kernel_properties
template <typename T> struct is_kernel_properties : std::false_type {};
template <typename TT>
struct is_kernel_properties<kernel_properties<TT>> : std::true_type {};

// Trait to detect compat_exp::launch_properties
template <typename T> struct is_launch_properties : std::false_type {};
template <typename TT>
struct is_launch_properties<launch_properties<TT>> : std::true_type {};

// Trait to detect compat_exp::local_mem_size
template <typename T> struct is_local_mem_size : std::false_type {};
template <> struct is_local_mem_size<local_mem_size> : std::true_type {};

// Traits to detect compat_exp::launch_policy
template <typename T> struct is_launch_policy : std::false_type {};

template <typename RangeT, typename KProps, typename LProps, bool LocalMem>
struct is_launch_policy<launch_policy<RangeT, KProps, LProps, LocalMem>>
    : std::true_type {};

template <typename T>
inline constexpr bool is_launch_policy_v = is_launch_policy<T>::value;

// Trait to detect if all args are sycl_exp property types
template <typename... Args>
using are_all_props = std::conjunction<
    sycl::ext::oneapi::experimental::is_property_value<Args>...>;

} // namespace experimental::detail

// Trait for extended floating point definition
template <typename T>
struct is_floating_point : std::is_floating_point<T>{};

template <> struct is_floating_point<sycl::half> : std::true_type {};

#ifdef SYCL_EXT_ONEAPI_BFLOAT16_MATH_FUNCTIONS
template <> struct is_floating_point<sycl::ext::oneapi::bfloat16> : std::true_type {};
#endif

template <typename T>
inline constexpr bool is_floating_point_v = is_floating_point<T>::value;

} // namespace compat

// Specialize std::common_type for bfloat16
// Semantics here match bfloat16.hpp operator overloads (all mixed type math
// ops return bfloat16)
// TODO(compat-lib-reviewers) Move this to bfloat extension
namespace std {
template <> struct common_type<sycl::ext::oneapi::bfloat16> {
  using type = sycl::ext::oneapi::bfloat16;
};

template <>
struct common_type<sycl::ext::oneapi::bfloat16, sycl::ext::oneapi::bfloat16> {
  using type = sycl::ext::oneapi::bfloat16;
};

template <typename T> struct common_type<sycl::ext::oneapi::bfloat16, T> {
  using type = sycl::ext::oneapi::bfloat16;
};

template <typename T> struct common_type<T, sycl::ext::oneapi::bfloat16> {
  using type = sycl::ext::oneapi::bfloat16;
};
} // namespace std
