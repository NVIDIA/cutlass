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

#include <sycl/accessor.hpp>
#include <sycl/event.hpp>
#include <sycl/nd_range.hpp>
#include <sycl/queue.hpp>
#include <sycl/range.hpp>
#include <sycl/reduction.hpp>

#include <compat/device.hpp>
#include <compat/dims.hpp>
#include <compat/launch_policy.hpp>

namespace compat {

namespace detail {

template <typename R, typename... Types>
constexpr size_t getArgumentCount(R (*f)(Types...)) {
  return sizeof...(Types);
}

template <int Dim>
sycl::nd_range<3> transform_nd_range(const sycl::nd_range<Dim> &range) {
  sycl::range<Dim> global_range = range.get_global_range();
  sycl::range<Dim> local_range = range.get_local_range();
  if constexpr (Dim == 3) {
    return range;
  } else if constexpr (Dim == 2) {
    return sycl::nd_range<3>{{1, global_range[0], global_range[1]},
                             {1, local_range[0], local_range[1]}};
  }
  return sycl::nd_range<3>{{1, 1, global_range[0]}, {1, 1, local_range[0]}};
}

template <auto F, typename... Args>
std::enable_if_t<std::is_invocable_v<decltype(F), Args...>, sycl::event>
launch(const sycl::nd_range<3> &range, sycl::queue q, Args... args) {
  static_assert(detail::getArgumentCount(F) == sizeof...(args),
                "Wrong number of arguments to SYCL kernel");
  static_assert(
      std::is_same<std::invoke_result_t<decltype(F), Args...>, void>::value,
      "SYCL kernels should return void");

  return q.parallel_for(
      range, [=](sycl::nd_item<3>) { [[clang::always_inline]] F(args...); });
}

} // namespace detail

template <int Dim>
inline sycl::nd_range<Dim> compute_nd_range(sycl::range<Dim> global_size_in,
                                            sycl::range<Dim> work_group_size) {

  if (global_size_in.size() == 0 || work_group_size.size() == 0) {
    throw std::invalid_argument("Global or local size is zero!");
  }
  for (size_t i = 0; i < Dim; ++i) {
    if (global_size_in[i] < work_group_size[i])
      throw std::invalid_argument("Work group size larger than global size");
  }

  auto global_size =
      ((global_size_in + work_group_size - 1) / work_group_size) *
      work_group_size;
  return {global_size, work_group_size};
}

inline sycl::nd_range<1> compute_nd_range(int global_size_in,
                                          int work_group_size) {
  return compute_nd_range<1>(global_size_in, work_group_size);
}

template <auto F, int Dim, typename... Args>
std::enable_if_t<std::is_invocable_v<decltype(F), Args...>, sycl::event>
launch(const sycl::nd_range<Dim> &range, sycl::queue q, Args... args) {
  return detail::launch<F>(detail::transform_nd_range<Dim>(range), q, args...);
}

template <auto F, int Dim, typename... Args>
std::enable_if_t<std::is_invocable_v<decltype(F), Args...>, sycl::event>
launch(const sycl::nd_range<Dim> &range, Args... args) {
  return launch<F>(range, get_default_queue(), args...);
}

// Alternative launch through dim3 objects
template <auto F, typename... Args>
std::enable_if_t<std::is_invocable_v<decltype(F), Args...>, sycl::event>
launch(const dim3 &grid, const dim3 &threads, sycl::queue q, Args... args) {
  return launch<F>(sycl::nd_range<3>{grid * threads, threads}, q, args...);
}

template <auto F, typename... Args>
std::enable_if_t<std::is_invocable_v<decltype(F), Args...>, sycl::event>
launch(const dim3 &grid, const dim3 &threads, Args... args) {
  return launch<F>(grid, threads, get_default_queue(), args...);
}

} // namespace compat

namespace compat::experimental {

namespace detail {

template <auto F, typename LaunchPolicy, typename... Args>
sycl::event launch(LaunchPolicy launch_policy, sycl::queue q, Args... args) {
  static_assert(compat::args_compatible<LaunchPolicy, F, Args...>,
                "Mismatch between device function signature and supplied "
                "arguments. Have you correctly handled local memory/char*?");

  sycl_exp::launch_config config(launch_policy.get_range(),
                                 launch_policy.get_launch_properties());

  return sycl_exp::submit_with_event(q, [&](sycl::handler &cgh) {
    auto KernelFunctor = build_kernel_functor<F>(cgh, launch_policy, args...);
    if constexpr (compat::detail::is_range_v<
                      typename LaunchPolicy::RangeT>) {
      parallel_for(cgh, config, KernelFunctor);
    } else {
      static_assert(
          compat::detail::is_nd_range_v<typename LaunchPolicy::RangeT>);
      nd_launch(cgh, config, KernelFunctor);
    }
  });
}

}


template <auto F, typename LaunchPolicy, typename... Args>
sycl::event launch(LaunchPolicy launch_policy, sycl::queue q, Args... args) {
  static_assert(detail::is_launch_policy_v<LaunchPolicy>);
  return detail::launch<F>(launch_policy, q, args...);
}

template <auto F, typename LaunchPolicy, typename... Args>
sycl::event launch(LaunchPolicy launch_policy, Args... args) {
  static_assert(detail::is_launch_policy_v<LaunchPolicy>);
  return launch<F>(launch_policy, get_default_queue(), args...);
}

} // namespace compat::experimental
