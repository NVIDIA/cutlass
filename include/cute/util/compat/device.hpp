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
 *  device.hpp
 *
 *  Description:
 *    Device functionality for the SYCL compatibility extension
 **************************************************************************/
//
// Modifications, Copyright (C) 2025 Intel Corporation
//
// This software and the related documents are Intel copyrighted materials, and
// your use of them is governed by the express license under which they were
// provided to you ("License"). Unless the License provides otherwise, you may
// not use, modify, copy, publish, distribute, disclose or transmit this
// software or the related documents without Intel's prior written permission.
//
// This software and the related documents are provided as is, with no express
// or implied warranties, other than those that are expressly stated in the
// License.
//
// The original source was under the license below:
//==---- device.hpp -------------------------------*- C++ -*----------------==//
//
// Copyright (C) Intel Corporation
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// See https://llvm.org/LICENSE.txt for license information.
//
//===----------------------------------------------------------------------===//

#pragma once
#pragma GCC system_header

#include <algorithm>
#include <cstring>
#include <iostream>
#include <map>
#include <mutex>
#include <set>
#include <sstream>
#include <thread>
#include <vector>
#if defined(__linux__)
#include <sys/syscall.h>
#include <unistd.h>
#endif
#if defined(_WIN64)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

#include <sycl/detail/defines_elementary.hpp>
#include <sycl/exception_list.hpp>
#include <sycl/properties/queue_properties.hpp>
#include <sycl/queue.hpp>

namespace compat {

namespace detail {
static void parse_version_string(const std::string &ver, int &major,
                                 int &minor) {
  // Version string has the following format:
  // a. OpenCL<space><major.minor><space><vendor-specific-information>
  // b. <major.minor>
  // c. <AmdGcnArchName> e.g gfx1030
  std::string::size_type i = 0;
  while (i < ver.size()) {
    if (isdigit(ver[i]))
      break;
    i++;
  }
  if (i < ver.size())
    major = std::stoi(&(ver[i]));
  else
    major = 0;
  while (i < ver.size()) {
    if (ver[i] == '.')
      break;
    i++;
  }
  i++;
  if (i < ver.size())
    minor = std::stoi(&(ver[i]));
  else
    minor = 0;
}

static void get_version(const sycl::device &dev, int &major, int &minor) {
  std::string ver = dev.get_info<sycl::info::device::version>();
  parse_version_string(ver, major, minor);
}

/// SYCL default exception handler
inline auto exception_handler = [](sycl::exception_list exceptions) {
  for (std::exception_ptr const &e : exceptions) {
    try {
      std::rethrow_exception(e);
    } catch (sycl::exception const &e) {
      std::cerr << "[Compat] Caught asynchronous SYCL exception:"
                << std::endl
                << e.what() << std::endl
                << "Exception caught at file:" << __FILE__
                << ", line:" << __LINE__ << std::endl;
    }
  }
};

} // namespace detail

using event_ptr = sycl::event *;

using queue_ptr = sycl::queue *;

using device_ptr = char *;

/// Destroy \p event pointed memory.
///
/// \param event Pointer to the sycl::event address.
static void destroy_event(event_ptr event) { delete event; }

class device_info {
public:
  // get interface
  const char *get_name() const { return _name; }
  char *get_name() { return _name; }
  template <typename WorkItemSizesTy = sycl::range<3>,
            std::enable_if_t<std::is_same_v<WorkItemSizesTy, sycl::range<3>> ||
                                 std::is_same_v<WorkItemSizesTy, int *>,
                             int> = 0>
  auto get_max_work_item_sizes() const {
    if constexpr (std::is_same_v<WorkItemSizesTy, sycl::range<3>>)
      return _max_work_item_sizes;
    else
      return _max_work_item_sizes_i;
  }
  template <typename WorkItemSizesTy = sycl::range<3>,
            std::enable_if_t<std::is_same_v<WorkItemSizesTy, sycl::range<3>> ||
                                 std::is_same_v<WorkItemSizesTy, int *>,
                             int> = 0>
  auto get_max_work_item_sizes() {
    if constexpr (std::is_same_v<WorkItemSizesTy, sycl::range<3>>)
      return _max_work_item_sizes;
    else
      return _max_work_item_sizes_i;
  }
  bool get_host_unified_memory() const { return _host_unified_memory; }
  int get_major_version() const { return _major; }
  int get_minor_version() const { return _minor; }
  int get_integrated() const { return _integrated; }
  int get_max_clock_frequency() const { return _frequency; }
  int get_max_compute_units() const { return _max_compute_units; }
  int get_max_work_group_size() const { return _max_work_group_size; }
  int get_max_sub_group_size() const { return _max_sub_group_size; }
  int get_max_work_items_per_compute_unit() const {
    return _max_work_items_per_compute_unit;
  }
  int get_max_register_size_per_work_group() const {
    return _max_register_size_per_work_group;
  }
  template <typename NDRangeSizeTy = size_t *,
            std::enable_if_t<std::is_same_v<NDRangeSizeTy, size_t *> ||
                                 std::is_same_v<NDRangeSizeTy, int *>,
                             int> = 0>
  auto get_max_nd_range_size() const {
    if constexpr (std::is_same_v<NDRangeSizeTy, size_t *>)
      return _max_nd_range_size;
    else
      return _max_nd_range_size_i;
  }
  template <typename NDRangeSizeTy = size_t *,
            std::enable_if_t<std::is_same_v<NDRangeSizeTy, size_t *> ||
                                 std::is_same_v<NDRangeSizeTy, int *>,
                             int> = 0>
  auto get_max_nd_range_size() {
    if constexpr (std::is_same_v<NDRangeSizeTy, size_t *>)
      return _max_nd_range_size;
    else
      return _max_nd_range_size_i;
  }
  size_t get_global_mem_size() const { return _global_mem_size; }
  size_t get_local_mem_size() const { return _local_mem_size; }
  /// Returns the maximum clock rate of device's global memory in kHz. If
  /// compiler does not support this API then returns default value 3200000 kHz.
  unsigned int get_memory_clock_rate() const { return _memory_clock_rate; }
  /// Returns the maximum bus width between device and memory in bits. If
  /// compiler does not support this API then returns default value 64 bits.
  unsigned int get_memory_bus_width() const { return _memory_bus_width; }
  uint32_t get_device_id() const { return _device_id; }
  std::array<unsigned char, 16> get_uuid() const { return _uuid; }
  /// Returns global memory cache size in bytes.
  unsigned int get_global_mem_cache_size() const {
    return _global_mem_cache_size;
  }
  int get_image1d_max() const { return _image1d_max; }
  auto get_image2d_max() const { return _image2d_max; }
  auto get_image2d_max() { return _image2d_max; }
  auto get_image3d_max() const { return _image3d_max; }
  auto get_image3d_max() { return _image3d_max; }

  // set interface
  void set_name(const char *name) {
    size_t length = strlen(name);
    if (length < device_info::NAME_BUFFER_SIZE) {
      std::memcpy(_name, name, length + 1);
    } else {
      std::memcpy(_name, name, device_info::NAME_BUFFER_SIZE - 1);
      _name[255] = '\0';
    }
  }
  void set_max_work_item_sizes(const sycl::range<3> max_work_item_sizes) {
    _max_work_item_sizes = max_work_item_sizes;
    for (int i = 0; i < 3; ++i)
      _max_work_item_sizes_i[i] = max_work_item_sizes[i];
  }
  [[deprecated]] void
  set_max_work_item_sizes(const sycl::id<3> max_work_item_sizes) {
    for (int i = 0; i < 3; ++i) {
      _max_work_item_sizes[i] = max_work_item_sizes[i];
      _max_work_item_sizes_i[i] = max_work_item_sizes[i];
    }
  }
  void set_host_unified_memory(bool host_unified_memory) {
    _host_unified_memory = host_unified_memory;
  }
  void set_major_version(int major) { _major = major; }
  void set_minor_version(int minor) { _minor = minor; }
  void set_integrated(int integrated) { _integrated = integrated; }
  void set_max_clock_frequency(int frequency) { _frequency = frequency; }
  void set_max_compute_units(int max_compute_units) {
    _max_compute_units = max_compute_units;
  }
  void set_global_mem_size(size_t global_mem_size) {
    _global_mem_size = global_mem_size;
  }
  void set_local_mem_size(size_t local_mem_size) {
    _local_mem_size = local_mem_size;
  }
  void set_max_work_group_size(int max_work_group_size) {
    _max_work_group_size = max_work_group_size;
  }
  void set_max_sub_group_size(int max_sub_group_size) {
    _max_sub_group_size = max_sub_group_size;
  }
  void
  set_max_work_items_per_compute_unit(int max_work_items_per_compute_unit) {
    _max_work_items_per_compute_unit = max_work_items_per_compute_unit;
  }
  void set_max_nd_range_size(int max_nd_range_size[]) {
    for (int i = 0; i < 3; i++) {
      _max_nd_range_size[i] = max_nd_range_size[i];
      _max_nd_range_size_i[i] = max_nd_range_size[i];
    }
  }
  void set_max_nd_range_size(sycl::id<3> max_nd_range_size) {
    for (int i = 0; i < 3; i++) {
      _max_nd_range_size[i] = max_nd_range_size[i];
      _max_nd_range_size_i[i] = max_nd_range_size[i];
    }
  }
  void set_memory_clock_rate(unsigned int memory_clock_rate) {
    _memory_clock_rate = memory_clock_rate;
  }
  void set_memory_bus_width(unsigned int memory_bus_width) {
    _memory_bus_width = memory_bus_width;
  }
  void
  set_max_register_size_per_work_group(int max_register_size_per_work_group) {
    _max_register_size_per_work_group = max_register_size_per_work_group;
  }
  void set_device_id(uint32_t device_id) { _device_id = device_id; }
  void set_uuid(std::array<unsigned char, 16> uuid) { _uuid = std::move(uuid); }
  void set_global_mem_cache_size(unsigned int global_mem_cache_size) {
    _global_mem_cache_size = global_mem_cache_size;
  }
  void set_image1d_max(size_t image_max_buffer_size) {
    _image1d_max = image_max_buffer_size;
  }
  void set_image2d_max(size_t image_max_width_buffer_size,
                       size_t image_max_height_buffer_size) {
    _image2d_max[0] = image_max_width_buffer_size;
    _image2d_max[1] = image_max_height_buffer_size;
  }
  void set_image3d_max(size_t image_max_width_buffer_size,
                       size_t image_max_height_buffer_size,
                       size_t image_max_depth_buffer_size) {
    _image3d_max[0] = image_max_width_buffer_size;
    _image3d_max[1] = image_max_height_buffer_size;
    _image3d_max[2] = image_max_depth_buffer_size;
  }

private:
  constexpr static size_t NAME_BUFFER_SIZE = 256;

  char _name[device_info::NAME_BUFFER_SIZE];
  sycl::range<3> _max_work_item_sizes;
  int _max_work_item_sizes_i[3];
  bool _host_unified_memory = false;
  int _major;
  int _minor;
  int _integrated = 0;
  int _frequency;
  // Set estimated value 3200000 kHz as default value.
  unsigned int _memory_clock_rate = 3200000;
  // Set estimated value 64 bits as default value.
  unsigned int _memory_bus_width = 64;
  unsigned int _global_mem_cache_size;
  int _max_compute_units;
  int _max_work_group_size;
  int _max_sub_group_size;
  int _max_work_items_per_compute_unit;
  int _max_register_size_per_work_group;
  size_t _global_mem_size;
  size_t _local_mem_size;
  size_t _max_nd_range_size[3];
  int _max_nd_range_size_i[3];
  uint32_t _device_id;
  std::array<unsigned char, 16> _uuid;
  int _image1d_max;
  int _image2d_max[2];
  int _image3d_max[3];
};

static int get_major_version(const sycl::device &dev) {
  int major, minor;
  detail::get_version(dev, major, minor);
  return major;
}

static int get_minor_version(const sycl::device &dev) {
  int major, minor;
  detail::get_version(dev, major, minor);
  return minor;
}

static inline void
has_capability_or_fail(const sycl::device &dev,
                       const std::initializer_list<sycl::aspect> &props) {
  for (const auto &it : props) {
    if (dev.has(it))
      continue;
    switch (it) {
    case sycl::aspect::fp64:
      throw sycl::exception(sycl::make_error_code(sycl::errc::runtime),
                            "[Compat] 'double' is not supported in '" +
                                dev.get_info<sycl::info::device::name>() +
                                "' device");
      break;
    case sycl::aspect::fp16:
      throw sycl::exception(sycl::make_error_code(sycl::errc::runtime),
                            "[Compat] 'half' is not supported in '" +
                                dev.get_info<sycl::info::device::name>() +
                                "' device");
      break;
    default:
#define __SYCL_ASPECT(ASPECT, ID)                                              \
  case sycl::aspect::ASPECT:                                                   \
    return #ASPECT;
#define __SYCL_ASPECT_DEPRECATED(ASPECT, ID, MESSAGE) __SYCL_ASPECT(ASPECT, ID)
#define __SYCL_ASPECT_DEPRECATED_ALIAS(ASPECT, ID, MESSAGE)
      auto getAspectNameStr = [](sycl::aspect AspectNum) -> std::string {
        switch (AspectNum) {
#include <sycl/info/aspects.def>
#include <sycl/info/aspects_deprecated.def>
        default:
          return "unknown aspect";
        }
      };
#undef __SYCL_ASPECT_DEPRECATED_ALIAS
#undef __SYCL_ASPECT_DEPRECATED
#undef __SYCL_ASPECT
      throw sycl::exception(
          sycl::make_error_code(sycl::errc::runtime),
          "[Compat] '" + getAspectNameStr(it) + "' is not supported in '" +
              dev.get_info<sycl::info::device::name>() + "' device");
    }
    break;
  }
}

/// device extension
class device_ext : public sycl::device {
public:
  device_ext() : sycl::device(), _ctx(*this) {}
  ~device_ext() {
    try {
      std::lock_guard<std::mutex> lock(m_mutex);
      sycl::event::wait(_events);
      _queues.clear();
    } catch (std::exception &e) {
      __SYCL_REPORT_EXCEPTION_TO_STREAM("exception in ~device_ext", e);
    }
  }
  device_ext(const sycl::device &base, bool print_on_async_exceptions = false,
             bool in_order = true)
      : sycl::device(base), _ctx(*this) {
    if (!this->has(sycl::aspect::usm_device_allocations)) {
      throw std::invalid_argument(
          "Device does not support device USM allocations");
    }
    // calls create_queue since we don't have a locked m_mutex
    _default_queue = create_queue(print_on_async_exceptions, in_order);
    _saved_queue = _default_queue;
  }

  bool is_native_host_atomic_supported() { return false; }
  int get_major_version() const { return compat::get_major_version(*this); }

  int get_minor_version() const { return compat::get_minor_version(*this); }

  int get_max_compute_units() const {
    return get_device_info().get_max_compute_units();
  }

  /// Return the maximum clock frequency of this device in KHz.
  int get_max_clock_frequency() const {
    return get_device_info().get_max_clock_frequency();
  }

  int get_integrated() const { return get_device_info().get_integrated(); }

  int get_max_sub_group_size() const {
    return get_device_info().get_max_sub_group_size();
  }

  int get_max_register_size_per_work_group() const {
    return get_device_info().get_max_register_size_per_work_group();
  }

  int get_max_work_group_size() const {
    return get_device_info().get_max_work_group_size();
  }

  int get_mem_base_addr_align() const {
    return get_info<sycl::info::device::mem_base_addr_align>();
  }

  size_t get_global_mem_size() const {
    return get_device_info().get_global_mem_size();
  }

  size_t get_local_mem_size() const {
    return get_device_info().get_local_mem_size();
  }

  /// Get the number of bytes of free and total memory on the SYCL device.
  /// \param [out] free_memory The number of bytes of free memory on the SYCL
  /// device.
  /// \param [out] total_memory The number of bytes of total memory on the SYCL
  /// device.
  void get_memory_info(size_t &free_memory, size_t &total_memory) const {
    if (!has(sycl::aspect::ext_intel_free_memory)) {
      std::cerr << "[Compat] get_memory_info: ext_intel_free_memory is not "
                   "supported."
                << std::endl;
      free_memory = 0;
    } else {
      free_memory = get_info<sycl::ext::intel::info::device::free_memory>();
    }
    total_memory = get_device_info().get_global_mem_size();
  }

  void get_device_info(device_info &out) const {
    if (_dev_info) {
      out = *_dev_info;
      return;
    }

    std::lock_guard<std::mutex> lock(m_mutex);
    device_info prop;
    prop.set_name(get_info<sycl::info::device::name>().c_str());

    int major, minor;
    get_version(major, minor);
    prop.set_major_version(major);
    prop.set_minor_version(minor);

    prop.set_max_work_item_sizes(
        // SYCL 2020-conformant code, max_work_item_sizes is a struct
        // templated by an int
        get_info<sycl::info::device::max_work_item_sizes<3>>());

    prop.set_host_unified_memory(has(sycl::aspect::usm_host_allocations));

    prop.set_max_clock_frequency(
        get_info<sycl::info::device::max_clock_frequency>());
    prop.set_max_compute_units(
        get_info<sycl::info::device::max_compute_units>());
    prop.set_max_work_group_size(
        get_info<sycl::info::device::max_work_group_size>());
    prop.set_global_mem_size(get_info<sycl::info::device::global_mem_size>());
    prop.set_local_mem_size(get_info<sycl::info::device::local_mem_size>());

#if (defined(SYCL_EXT_INTEL_DEVICE_INFO) && SYCL_EXT_INTEL_DEVICE_INFO >= 6)
    if (has(sycl::aspect::ext_intel_memory_clock_rate)) {
      unsigned int tmp =
          get_info<sycl::ext::intel::info::device::memory_clock_rate>();
      if (tmp != 0)
        prop.set_memory_clock_rate(1000 * tmp);
    }
    if (has(sycl::aspect::ext_intel_memory_bus_width)) {
      prop.set_memory_bus_width(
          get_info<sycl::ext::intel::info::device::memory_bus_width>());
    }
    if (has(sycl::aspect::ext_intel_device_id)) {
      prop.set_device_id(get_info<sycl::ext::intel::info::device::device_id>());
    }
    if (has(sycl::aspect::ext_intel_device_info_uuid)) {
      prop.set_uuid(get_info<sycl::ext::intel::info::device::uuid>());
    }
#elif defined(_MSC_VER) && !defined(__clang__)
#pragma message("get_device_info: querying memory_clock_rate and \
memory_bus_width are not supported by the compiler used. \
Use 3200000 kHz as memory_clock_rate default value. \
Use 64 bits as memory_bus_width default value.")
#else
#warning "get_device_info: querying memory_clock_rate and \
memory_bus_width are not supported by the compiler used. \
Use 3200000 kHz as memory_clock_rate default value. \
Use 64 bits as memory_bus_width default value."
#endif

    size_t max_sub_group_size = 1;
    std::vector<size_t> sub_group_sizes =
        get_info<sycl::info::device::sub_group_sizes>();

    for (const auto &sub_group_size : sub_group_sizes) {
      if (max_sub_group_size < sub_group_size)
        max_sub_group_size = sub_group_size;
    }

    prop.set_max_sub_group_size(max_sub_group_size);

    prop.set_max_work_items_per_compute_unit(
        get_info<sycl::info::device::max_work_group_size>());
#ifdef SYCL_EXT_ONEAPI_MAX_WORK_GROUP_QUERY
    prop.set_max_nd_range_size(
        get_info<sycl::ext::oneapi::experimental::info::device::max_work_groups<
            3>>());
#else
#if defined(_MSC_VER) && !defined(__clang__)
#pragma message("get_device_info: querying the maximum number \
    of work groups is not supported.")
#else
#warning "get_device_info: querying the maximum number of \
    work groups is not supported."
#endif
    int max_nd_range_size[] = {0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF};
    prop.set_max_nd_range_size(max_nd_range_size);
#endif

    // Estimates max register size per work group, feel free to update the
    // value according to device properties.
    prop.set_max_register_size_per_work_group(65536);

    prop.set_global_mem_cache_size(
        get_info<sycl::info::device::global_mem_cache_size>());

    prop.set_image1d_max(get_info<sycl::info::device::image_max_buffer_size>());
    prop.set_image1d_max(get_info<sycl::info::device::image_max_buffer_size>());
    prop.set_image2d_max(get_info<sycl::info::device::image2d_max_width>(),
                         get_info<sycl::info::device::image2d_max_height>());
    prop.set_image3d_max(get_info<sycl::info::device::image3d_max_width>(),
                         get_info<sycl::info::device::image3d_max_height>(),
                         get_info<sycl::info::device::image3d_max_height>());

    _dev_info = prop;
    out = prop;
  }

  device_info get_device_info() const {
    if (!_dev_info) {
      this->get_device_info(*_dev_info);
    }
    return _dev_info.value();
  }

  void reset(bool print_on_async_exceptions = false, bool in_order = true) {
    std::lock_guard<std::mutex> lock(m_mutex);
    // The queues are shared_ptrs and the ref counts of the shared_ptrs increase
    // only in wait_and_throw(). If there is no other thread calling
    // wait_and_throw(), the queues will be destructed. The destructor waits for
    // all commands executing on the queue to complete. It isn't possible to
    // destroy a queue immediately. This is a synchronization point in SYCL.
    _queues.clear();
    // create new default queue
    // calls create_queue_impl since we already have a locked m_mutex

    _saved_queue = _default_queue =
        in_order ? create_queue_impl(print_on_async_exceptions,
                                     sycl::property::queue::in_order())
                 : create_queue_impl(print_on_async_exceptions);
  }

  void set_default_queue(const sycl::queue &q) {
    std::lock_guard<std::mutex> lock(m_mutex);
    _queues.front().get()->wait_and_throw();
    _queues[0] = std::make_shared<sycl::queue>(q);
    if (_saved_queue == _default_queue)
      _saved_queue = _queues.front().get();
    _default_queue = _queues.front().get();
  }

  queue_ptr default_queue() { return _default_queue; }

  void queues_wait_and_throw() {
    std::unique_lock<std::mutex> lock(m_mutex);
    std::vector<std::shared_ptr<sycl::queue>> current_queues(_queues);
    lock.unlock();
    for (const auto &q : current_queues) {
      q->wait_and_throw();
    }
    // Guard the destruct of current_queues to make sure the ref count is safe.
    lock.lock();
  }
  queue_ptr create_queue(bool print_on_async_exceptions = false,
                         bool in_order = true) {
    std::lock_guard<std::mutex> lock(m_mutex);
    return in_order ? create_queue_impl(print_on_async_exceptions,
                                        sycl::property::queue::in_order())
                    : create_queue_impl(print_on_async_exceptions);
  }
  void destroy_queue(queue_ptr &queue) {
    std::lock_guard<std::mutex> lock(m_mutex);
    _queues.erase(
        std::remove_if(_queues.begin(), _queues.end(),
                       [=](const std::shared_ptr<sycl::queue> &q) -> bool {
                         return q.get() == queue;
                       }),
        _queues.end());
    queue = nullptr;
  }
  void set_saved_queue(queue_ptr q) {
    std::lock_guard<std::mutex> lock(m_mutex);
    _saved_queue = q;
  }
  queue_ptr get_saved_queue() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return _saved_queue;
  }
  sycl::context get_context() const { return _ctx; }

  /// Util function to check whether a device supports some kinds of
  /// sycl::aspect.
  void has_capability_or_fail(
      const std::initializer_list<sycl::aspect> &props) const {
    ::compat::has_capability_or_fail(*this, props);
  }

private:
  /// Caller should only be done from functions where the resource \p m_mutex
  /// has been acquired.
  template <typename... PropertiesT>
  queue_ptr create_queue_impl(bool print_on_async_exceptions = false,
                              PropertiesT... properties) {
    sycl::property_list prop = sycl::property_list(
#ifdef COMPAT_PROFILING_ENABLED
        sycl::property::queue::enable_profiling(),
#endif
        properties...);
    if (print_on_async_exceptions) {
      _queues.push_back(std::make_shared<sycl::queue>(
          _ctx, *this, detail::exception_handler, prop));
    } else {
      _queues.push_back(std::make_shared<sycl::queue>(_ctx, *this, prop));
    }
    return _queues.back().get();
  }

  void get_version(int &major, int &minor) const {
    detail::get_version(*this, major, minor);
  }
  void add_event(sycl::event event) {
    std::lock_guard<std::mutex> lock(m_mutex);
    _events.push_back(event);
  }
  friend sycl::event enqueue_free(const std::vector<void *> &,
                                  const std::vector<sycl::event> &,
                                  sycl::queue);
  queue_ptr _default_queue;
  queue_ptr _saved_queue;
  sycl::context _ctx;
  std::vector<std::shared_ptr<sycl::queue>> _queues;
  mutable std::mutex m_mutex;
  std::vector<sycl::event> _events;
  mutable std::optional<device_info> _dev_info;
};

namespace detail {

static inline unsigned int get_tid() {
#if defined(__linux__)
  return syscall(SYS_gettid);
#elif defined(_WIN64)
  return GetCurrentThreadId();
#else
#error "Only support Windows and Linux."
#endif
}

/// device manager
class dev_mgr {
public:
  device_ext &current_device() {
    unsigned int dev_id = current_device_id();
    check_id(dev_id);
    return *_devs[dev_id];
  }
  device_ext &cpu_device() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (_cpu_device == -1) {
      throw std::runtime_error("[Compat] No valid cpu device");
    } else {
      return *_devs[_cpu_device];
    }
  }
  device_ext &get_device(unsigned int id) const {
    std::lock_guard<std::mutex> lock(m_mutex);
    check_id(id);
    return *_devs[id];
  }
  unsigned int current_device_id() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    auto it = _thread2dev_map.find(get_tid());
    if (it != _thread2dev_map.end())
      return it->second;
    return _default_device_id;
  }

  /// Select device with a device ID.
  /// \param [in] id The id of the device which can
  /// be obtained through get_device_id(const sycl::device).
  void select_device(unsigned int id) {
    std::lock_guard<std::mutex> lock(m_mutex);
    check_id(id);
    _thread2dev_map[get_tid()] = id;
  }
  unsigned int device_count() { return _devs.size(); }

  unsigned int get_device_id(const sycl::device &dev) {
    if (!_devs.size()) {
      throw std::runtime_error(
          "[Compat] No SYCL devices found in the device list. Device list "
          "may have been filtered by compat::filter_device");
    }
    unsigned int id = 0;
    for (auto dev_item : _devs) {
      if (*dev_item == dev) {
        return id;
      }
      id++;
    }
    throw std::runtime_error("[Compat] The device[" +
                             dev.get_info<sycl::info::device::name>() +
                             "] is filtered out by compat::filter_device "
                             "in current device list!");
  }

  /// List all the devices with its id in dev_mgr.
  void list_devices() const {
    for (size_t i = 0; i < _devs.size(); ++i) {
      std::cout << "Device " << i << ": "
                << _devs[i]->get_info<sycl::info::device::name>() << std::endl;
    }
  }

  /// Filter out devices; only keep the device whose name contains one of the
  /// subname in \p dev_subnames.
  /// May break device id mapping and change current device. It's better to be
  /// called before other Compat/SYCL APIs.
  void filter(const std::vector<std::string> &dev_subnames) {
    std::lock_guard<std::mutex> lock(m_mutex);
    auto iter = _devs.begin();
    while (iter != _devs.end()) {
      std::string dev_name = (*iter)->get_info<sycl::info::device::name>();
      bool matched = false;
      for (const auto &name : dev_subnames) {
        if (dev_name.find(name) != std::string::npos) {
          matched = true;
          break;
        }
      }
      if (matched)
        ++iter;
      else
        iter = _devs.erase(iter);
    }
    _cpu_device = -1;
    for (unsigned i = 0; i < _devs.size(); ++i) {
      if (_devs[i]->is_cpu()) {
        _cpu_device = i;
        break;
      }
    }
    _thread2dev_map.clear();
#ifdef COMPAT_VERBOSE
    list_devices();
#endif
  }

  /// Select device with a Device Selector
  /// \param selector device selector to get the device id from. Defaults to
  /// sycl::gpu_selector_v
  template <class DeviceSelector>
  std::enable_if_t<
      std::is_invocable_r_v<int, DeviceSelector, const sycl::device &>>
  select_device(const DeviceSelector &selector = sycl::gpu_selector_v) {
    sycl::device selected_device = sycl::device(selector);
    unsigned int selected_device_id = get_device_id(selected_device);
    select_device(selected_device_id);
  }

  /// Returns the instance of device manager singleton.
  static dev_mgr &instance() {
    static dev_mgr d_m;
    return d_m;
  }
  dev_mgr(const dev_mgr &) = delete;
  dev_mgr &operator=(const dev_mgr &) = delete;
  dev_mgr(dev_mgr &&) = delete;
  dev_mgr &operator=(dev_mgr &&) = delete;

private:
  mutable std::mutex m_mutex;

  dev_mgr() {
    sycl::device default_device = sycl::device(sycl::default_selector_v);
    _devs.push_back(std::make_shared<device_ext>(default_device));

    std::vector<sycl::device> sycl_all_devs =
        sycl::device::get_devices(sycl::info::device_type::all);
    // Collect other devices except for the default device.
    if (default_device.is_cpu())
      _cpu_device = 0;
    for (auto &dev : sycl_all_devs) {
      if (dev == default_device) {
        continue;
      }
      _devs.push_back(std::make_shared<device_ext>(dev));
      if (_cpu_device == -1 && dev.is_cpu()) {
        _cpu_device = _devs.size() - 1;
      }
    }
#ifdef COMPAT_VERBOSE
    list_devices();
#endif
  }
  void check_id(unsigned int id) const {
    if (id >= _devs.size()) {
      throw std::runtime_error("invalid device id");
    }
  }
  std::vector<std::shared_ptr<device_ext>> _devs;
  /// DEFAULT_DEVICE_ID is used, if current_device_id() can not find current
  /// thread id in _thread2dev_map, which means default device should be used
  /// for the current thread.
  const unsigned int _default_device_id = 0;
  /// thread-id to device-id map.
  std::map<unsigned int, unsigned int> _thread2dev_map;
  int _cpu_device = -1;
};

} // namespace detail

static inline sycl::queue create_queue(bool print_on_async_exceptions = false,
                                       bool in_order = true) {
  return *detail::dev_mgr::instance().current_device().create_queue(
      print_on_async_exceptions, in_order);
}

/// Util function to get the default queue of current device in
/// device manager.
static inline sycl::queue get_default_queue() {
  return *detail::dev_mgr::instance().current_device().default_queue();
}

/// Util function to change the default queue of the current device in the
/// device manager
/// If the device extension saved queue is the default queue,
/// the previous saved queue will be overwritten as well.
/// This function will be blocking if there are submitted kernels in the
/// previous default queue.
/// @param q New user-defined queue
static inline void set_default_queue(const sycl::queue &q) {
  detail::dev_mgr::instance().current_device().set_default_queue(q);
}

static inline void wait(sycl::queue q = get_default_queue()) { q.wait(); }

static inline void wait_and_throw(sycl::queue q = get_default_queue()) {
  q.wait_and_throw();
}

/// Util function to get the id of current device in
/// device manager.
static inline unsigned int get_current_device_id() {
  return detail::dev_mgr::instance().current_device_id();
}

/// Util function to get the current device.
static inline device_ext &get_current_device() {
  return detail::dev_mgr::instance().current_device();
}

/// Util function to get a device by id.
static inline device_ext &get_device(unsigned int id) {
  return detail::dev_mgr::instance().get_device(id);
}

/// Util function to get the context of the default queue of current
/// device in device manager.
static inline sycl::context get_default_context() {
  return get_current_device().get_context();
}

/// Util function to get a CPU device.
static inline device_ext &cpu_device() {
  return detail::dev_mgr::instance().cpu_device();
}

/// Filter out devices; only keep the device whose name contains one of the
/// subname in \p dev_subnames.
/// May break device id mapping and change current device. It's better to be
/// called before other Compat or SYCL APIs.
static inline void filter_device(const std::vector<std::string> &dev_subnames) {
  detail::dev_mgr::instance().filter(dev_subnames);
}

/// List all the devices with its id in dev_mgr.
static inline void list_devices() {
  detail::dev_mgr::instance().list_devices();
}

static inline unsigned int select_device(unsigned int id) {
  detail::dev_mgr::instance().select_device(id);
  return id;
}

template <class DeviceSelector>
static inline std::enable_if_t<
    std::is_invocable_r_v<int, DeviceSelector, const sycl::device &>>
select_device(const DeviceSelector &selector = sycl::gpu_selector_v) {
  detail::dev_mgr::instance().select_device(selector);
}

static inline unsigned int get_device_id(const sycl::device &dev) {
  return detail::dev_mgr::instance().get_device_id(dev);
}

static inline unsigned int device_count() {
  return detail::dev_mgr::instance().device_count();
}
} // namespace compat
