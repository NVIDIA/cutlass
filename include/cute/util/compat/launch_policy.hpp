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
 *  launch.hpp
 *
 *  Description:
 *    launch functionality for the SYCL compatibility extension
 **************************************************************************/

#pragma once
#pragma GCC system_header

#include "sycl/ext/oneapi/experimental/enqueue_functions.hpp"
#include "sycl/ext/oneapi/properties/properties.hpp"
#include <sycl/event.hpp>
#include <sycl/nd_range.hpp>
#include <sycl/queue.hpp>
#include <sycl/range.hpp>

#include <cute/util/compat/defs.hpp>
#include <cute/util/compat/device.hpp>
#include <cute/util/compat/dims.hpp>
#include <cute/util/compat/traits.hpp>

namespace compat {
namespace experimental {

namespace sycl_exp = sycl::ext::oneapi::experimental;

// Wrapper for kernel sycl_exp::properties
template <typename Properties> struct kernel_properties {
  static_assert(sycl_exp::is_property_list_v<Properties>);
  using Props = Properties;

  template <typename... Props>
  kernel_properties(Props... properties) : props{properties...} {}

  template <typename... Props>
  kernel_properties(sycl_exp::properties<Props...> properties)
      : props{properties} {}

  Properties props;
};

template <typename... Props, typename = std::enable_if_t<detail::are_all_props<Props...>::value, void>>
kernel_properties(Props... props)
    -> kernel_properties<decltype(sycl_exp::properties(props...))>;

template <typename... Props>
kernel_properties(sycl_exp::properties<Props...> props)
    -> kernel_properties<sycl_exp::properties<Props...>>;

// Wrapper for launch sycl_exp::properties
template <typename Properties> struct launch_properties {
  static_assert(sycl_exp::is_property_list_v<Properties>);
  using Props = Properties;

  template <typename... Props>
  launch_properties(Props... properties) : props{properties...} {}

  template <typename... Props>
  launch_properties(sycl_exp::properties<Props...> properties)
      : props{properties} {}

  Properties props;
};

template <typename... Props, typename = std::enable_if_t<detail::are_all_props<Props...>::value, void>>
launch_properties(Props... props)
    -> launch_properties<decltype(sycl_exp::properties(props...))>;

template <typename... Props>
launch_properties(sycl_exp::properties<Props...> props)
    -> launch_properties<sycl_exp::properties<Props...>>;

// Wrapper for local memory size
struct local_mem_size {
  local_mem_size(size_t size = 0) : size{size} {};
  size_t size;
};

// launch_policy is constructed by the user & passed to `compat_exp::launch`
template <typename Range, typename KProps, typename LProps, bool LocalMem>
class launch_policy {
  static_assert(sycl_exp::is_property_list_v<KProps>);
  static_assert(sycl_exp::is_property_list_v<LProps>);
  static_assert(compat::detail::is_range_or_nd_range_v<Range>);
  static_assert(compat::detail::is_nd_range_v<Range> || !LocalMem,
                "sycl::range kernel launches are incompatible with local "
                "memory usage!");

public:
  using KPropsT = KProps;
  using LPropsT = LProps;
  using RangeT = Range;
  static constexpr bool HasLocalMem = LocalMem;

private:
  launch_policy() = default;

  template <typename... Ts>
  launch_policy(Ts... ts)
      : _kernel_properties{detail::property_getter<
            kernel_properties, kernel_properties<KPropsT>, std::tuple<Ts...>>()(
            std::tuple<Ts...>(ts...))},
        _launch_properties{detail::property_getter<
            launch_properties, launch_properties<LPropsT>, std::tuple<Ts...>>()(
            std::tuple<Ts...>(ts...))},
        _local_mem_size{
            detail::local_mem_getter<local_mem_size, std::tuple<Ts...>>()(
                std::tuple<Ts...>(ts...))} {
    check_variadic_args(ts...);
  }

  template <typename... Ts> void check_variadic_args(Ts...) {
    static_assert(
        std::conjunction_v<std::disjunction<detail::is_kernel_properties<Ts>,
                                            detail::is_launch_properties<Ts>,
                                            detail::is_local_mem_size<Ts>>...>,
        "Received an unexpected argument to ctor. Did you forget to wrap "
        "in "
        "compat::kernel_properties, launch_properties, local_mem_size?");
  }

public:
  template <typename... Ts>
  launch_policy(Range range, Ts... ts) : launch_policy(ts...) {
    _range = range;
    check_variadic_args(ts...);
  }

  template <typename... Ts>
  launch_policy(dim3 global_range, Ts... ts) : launch_policy(ts...) {
    _range = Range{global_range};
    check_variadic_args(ts...);
  }

  template <typename... Ts>
  launch_policy(dim3 global_range, dim3 local_range, Ts... ts)
      : launch_policy(ts...) {
    _range = Range{global_range * local_range, local_range};
    check_variadic_args(ts...);
  }

  KProps get_kernel_properties() { return _kernel_properties.props; }
  LProps get_launch_properties() { return _launch_properties.props; }
  size_t get_local_mem_size() { return _local_mem_size.size; }
  Range get_range() { return _range; }

private:
  Range _range;
  kernel_properties<KProps> _kernel_properties;
  launch_properties<LProps> _launch_properties;
  local_mem_size _local_mem_size;
};

// Deduction guides for launch_policy
template <typename Range, typename... Ts>
launch_policy(Range, Ts...) -> launch_policy<
    Range, detail::properties_or_empty<kernel_properties, Ts...>,
    detail::properties_or_empty<launch_properties, Ts...>,
    detail::has_type<local_mem_size, std::tuple<Ts...>>::value>;

template <int Dim, typename... Ts>
launch_policy(sycl::range<Dim>, sycl::range<Dim>, Ts...) -> launch_policy<
    sycl::nd_range<Dim>, detail::properties_or_empty<kernel_properties, Ts...>,
    detail::properties_or_empty<launch_properties, Ts...>,
    detail::has_type<local_mem_size, std::tuple<Ts...>>::value>;

template <typename... Ts>
launch_policy(dim3, Ts...) -> launch_policy<
    sycl::range<3>, detail::properties_or_empty<kernel_properties, Ts...>,
    detail::properties_or_empty<launch_properties, Ts...>,
    detail::has_type<local_mem_size, std::tuple<Ts...>>::value>;

template <typename... Ts>
launch_policy(dim3, dim3, Ts...) -> launch_policy<
    sycl::nd_range<3>, detail::properties_or_empty<kernel_properties, Ts...>,
    detail::properties_or_empty<launch_properties, Ts...>,
    detail::has_type<local_mem_size, std::tuple<Ts...>>::value>;

namespace detail {
// Custom std::apply helpers to enable inlining
template <class F, class Tuple, size_t... Is>
__compat_inline__ constexpr void apply_expand(F &&f, Tuple &&t,
                                                  std::index_sequence<Is...>) {
  [[clang::always_inline]] std::forward<F>(f)(
      std::get<Is>(std::forward<Tuple>(t))...);
}

template <class F, class Tuple>
__compat_inline__ constexpr void apply_helper(F &&f, Tuple &&t) {
  apply_expand(
      std::forward<F>(f), std::forward<Tuple>(t),
      std::make_index_sequence<std::tuple_size_v<std::decay_t<Tuple>>>{});
}

template <auto F, typename Range, typename KProps, bool HasLocalMem,
          typename... Args>
struct KernelFunctor {
  KernelFunctor(KProps kernel_props, Args... args)
      : _kernel_properties{kernel_props},
        _argument_tuple(std::make_tuple(args...)) {}

  KernelFunctor(KProps kernel_props, sycl::local_accessor<char, 1> local_acc,
                Args... args)
      : _kernel_properties{kernel_props}, _local_acc{local_acc},
        _argument_tuple(std::make_tuple(args...)) {}

  auto get(sycl_exp::properties_tag) const { return _kernel_properties; }

  __compat_inline__ void
  operator()(compat::detail::range_to_item_t<Range>) const {
    if constexpr (HasLocalMem) {
      char *local_mem_ptr = static_cast<char *>(
          _local_acc.template get_multi_ptr<sycl::access::decorated::no>()
              .get());
      apply_helper(
          [lmem_ptr = local_mem_ptr](auto &&...args) {
            [[clang::always_inline]] F(args..., lmem_ptr);
          },
          _argument_tuple);
    } else {
      apply_helper([](auto &&...args) { [[clang::always_inline]] F(args...); },
                   _argument_tuple);
    }
  }

  KProps _kernel_properties;
  std::tuple<Args...> _argument_tuple;
  std::conditional_t<HasLocalMem, sycl::local_accessor<char, 1>, std::monostate>
      _local_acc; // monostate for empty type
};

//====================================================================
// This helper function avoids 2 nested `if constexpr` in detail::launch
template <auto F, typename LaunchPolicy, typename... Args>
auto build_kernel_functor(sycl::handler &cgh, LaunchPolicy launch_policy,
                          Args... args)
    -> KernelFunctor<F, typename LaunchPolicy::RangeT,
                     typename LaunchPolicy::KPropsT, LaunchPolicy::HasLocalMem,
                     Args...> {
  if constexpr (LaunchPolicy::HasLocalMem) {
    sycl::local_accessor<char, 1> local_memory(
        launch_policy.get_local_mem_size(), cgh);
    return KernelFunctor<F, typename LaunchPolicy::RangeT,
                         typename LaunchPolicy::KPropsT,
                         LaunchPolicy::HasLocalMem, Args...>(
        launch_policy.get_kernel_properties(), local_memory, args...);
  } else {
    return KernelFunctor<F, typename LaunchPolicy::RangeT,
                         typename LaunchPolicy::KPropsT,
                         LaunchPolicy::HasLocalMem, Args...>(
        launch_policy.get_kernel_properties(), args...);
  }
}

} // namespace detail
} // namespace experimental
} // namespace compat
