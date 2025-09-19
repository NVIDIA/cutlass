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
 *  group_utils.hpp
 *
 *  Description:
 *    Group util functionality for the SYCL compatibility extension
 **************************************************************************/

// The original source was under the license below:
//==---- group_utils.hpp ------------------*- C++ -*--------------------==//
//
// Copyright (C) Intel Corporation
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// See https://llvm.org/LICENSE.txt for license information.
//
//===------------------------------------------------------------------===//

#pragma once

#include <iterator>
#include <stdexcept>
#include <sycl/sycl.hpp>

#include <compat/defs.hpp>
#include <compat/math.hpp>

namespace compat {
namespace group {
namespace detail {

template <typename... _Args>
constexpr auto __reduce_over_group(_Args... __args) {
  return sycl::reduce_over_group(__args...);
}

template <typename... _Args> constexpr auto __group_broadcast(_Args... __args) {
  return sycl::group_broadcast(__args...);
}

template <typename... _Args>
constexpr auto __exclusive_scan_over_group(_Args... __args) {
  return sycl::exclusive_scan_over_group(__args...);
}

template <typename... _Args>
constexpr auto __inclusive_scan_over_group(_Args... __args) {
  return sycl::inclusive_scan_over_group(__args...);
}

template <typename Item, typename T, class BinaryOperation,
          class GroupPrefixCallbackOperation>
__compat_inline__ T
exclusive_scan(const Item &item, T input, BinaryOperation binary_op,
               GroupPrefixCallbackOperation &prefix_callback_op) {
  T group_aggregate;

  T output =
      detail::__exclusive_scan_over_group(item.get_group(), input, binary_op);
  if (item.get_local_linear_id() == item.get_local_range().size() - 1) {
    group_aggregate = binary_op(output, input);
  }

  group_aggregate = detail::__group_broadcast(
      item.get_group(), group_aggregate, item.get_local_range().size() - 1);

  T group_prefix = prefix_callback_op(group_aggregate);
  if (item.get_local_linear_id() == 0) {
    output = group_prefix;
  } else {
    output = binary_op(group_prefix, output);
  }

  return output;
}

typedef uint16_t digit_counter_type;
typedef uint32_t packed_counter_type;

template <int N, int CURRENT_VAL = N, int COUNT = 0> struct log2 {
  enum { VALUE = log2<N, (CURRENT_VAL >> 1), COUNT + 1>::VALUE };
};

template <int N, int COUNT> struct log2<N, 0, COUNT> {
  enum { VALUE = (1 << (COUNT - 1) < N) ? COUNT : COUNT - 1 };
};

template <int RADIX_BITS, bool DESCENDING = false> class radix_rank {
public:
  static size_t get_local_memory_size(size_t group_threads) {
    return group_threads * PADDED_COUNTER_LANES * sizeof(packed_counter_type);
  }

  radix_rank(uint8_t *local_memory) : _local_memory(local_memory) {}

  template <typename Item, int VALUES_PER_THREAD>
  __compat_inline__ void
  rank_keys(const Item &item, uint32_t (&keys)[VALUES_PER_THREAD],
            int (&ranks)[VALUES_PER_THREAD], int current_bit, int num_bits) {

    digit_counter_type thread_prefixes[VALUES_PER_THREAD];
    digit_counter_type *digit_counters[VALUES_PER_THREAD];
    digit_counter_type *buffer =
        reinterpret_cast<digit_counter_type *>(_local_memory);
    auto g = item.get_group();
    reset_local_memory(item);

    sycl::group_barrier(g, sycl::memory_scope::work_group);

#pragma unroll
    for (int i = 0; i < VALUES_PER_THREAD; ++i) {
      uint32_t digit =
          ::compat::detail::bfe(keys[i], current_bit, num_bits);
      uint32_t sub_counter = digit >> LOG_COUNTER_LANES;
      uint32_t counter_lane = digit & (COUNTER_LANES - 1);

      if (DESCENDING) {
        sub_counter = PACKING_RATIO - 1 - sub_counter;
        counter_lane = COUNTER_LANES - 1 - counter_lane;
      }

      digit_counters[i] =
          &buffer[counter_lane * item.get_local_range().size() * PACKING_RATIO +
                  item.get_local_linear_id() * PACKING_RATIO + sub_counter];
      thread_prefixes[i] = *digit_counters[i];
      *digit_counters[i] = thread_prefixes[i] + 1;
    }

    sycl::group_barrier(g, sycl::memory_scope::work_group);

    scan_counters(item);

    sycl::group_barrier(g, sycl::memory_scope::work_group);

    for (int i = 0; i < VALUES_PER_THREAD; ++i) {
      ranks[i] = thread_prefixes[i] + *digit_counters[i];
    }
  }

private:
  template <typename Item>
  __compat_inline__ void reset_local_memory(const Item &item) {
    packed_counter_type *ptr =
        reinterpret_cast<packed_counter_type *>(_local_memory);

#pragma unroll
    for (int i = 0; i < PADDED_COUNTER_LANES; ++i) {
      ptr[i * item.get_local_range().size() + item.get_local_linear_id()] = 0;
    }
  }

  template <typename Item>
  __compat_inline__ packed_counter_type upsweep(const Item &item) {
    packed_counter_type sum = 0;
    packed_counter_type *ptr =
        reinterpret_cast<packed_counter_type *>(_local_memory);

#pragma unroll
    for (int i = 0; i < PADDED_COUNTER_LANES; i++) {
      cached_segment[i] =
          ptr[item.get_local_linear_id() * PADDED_COUNTER_LANES + i];
    }

#pragma unroll
    for (int i = 0; i < PADDED_COUNTER_LANES; ++i) {
      sum += cached_segment[i];
    }

    return sum;
  }

  template <typename Item>
  __compat_inline__ void
  exclusive_downsweep(const Item &item, packed_counter_type raking_partial) {
    packed_counter_type *ptr =
        reinterpret_cast<packed_counter_type *>(_local_memory);
    packed_counter_type sum = raking_partial;

#pragma unroll
    for (int i = 0; i < PADDED_COUNTER_LANES; ++i) {
      packed_counter_type value = cached_segment[i];
      cached_segment[i] = sum;
      sum += value;
    }

#pragma unroll
    for (int i = 0; i < PADDED_COUNTER_LANES; ++i) {
      ptr[item.get_local_linear_id() * PADDED_COUNTER_LANES + i] =
          cached_segment[i];
    }
  }

  struct prefix_callback {
    __compat_inline__ packed_counter_type
    operator()(packed_counter_type block_aggregate) {
      packed_counter_type block_prefix = 0;

#pragma unroll
      for (int packed = 1; packed < PACKING_RATIO; packed++) {
        block_prefix += block_aggregate
                        << (sizeof(digit_counter_type) * 8 * packed);
      }

      return block_prefix;
    }
  };

  template <typename Item>
  __compat_inline__ void scan_counters(const Item &item) {
    packed_counter_type raking_partial = upsweep(item);

    prefix_callback callback;
    packed_counter_type exclusive_partial = exclusive_scan(
        item, raking_partial, sycl::ext::oneapi::plus<packed_counter_type>(),
        callback);

    exclusive_downsweep(item, exclusive_partial);
  }

private:
  static constexpr int PACKING_RATIO =
      sizeof(packed_counter_type) / sizeof(digit_counter_type);
  static constexpr int LOG_PACKING_RATIO = log2<PACKING_RATIO>::VALUE;
  static constexpr int LOG_COUNTER_LANES = RADIX_BITS - LOG_PACKING_RATIO;
  static constexpr int COUNTER_LANES = 1 << LOG_COUNTER_LANES;
  static constexpr int PADDED_COUNTER_LANES = COUNTER_LANES + 1;

  packed_counter_type cached_segment[PADDED_COUNTER_LANES];
  uint8_t *_local_memory;
};

template <typename T, typename U> struct base_traits {

  static __compat_inline__ U twiddle_in(U key) {
    throw std::runtime_error("Not implemented");
  }
  static __compat_inline__ U twiddle_out(U key) {
    throw std::runtime_error("Not implemented");
  }
};

template <typename U> struct base_traits<uint32_t, U> {
  static __compat_inline__ U twiddle_in(U key) { return key; }
  static __compat_inline__ U twiddle_out(U key) { return key; }
};

template <typename U> struct base_traits<int, U> {
  static constexpr U HIGH_BIT = U(1) << ((sizeof(U) * 8) - 1);
  static __compat_inline__ U twiddle_in(U key) { return key ^ HIGH_BIT; }
  static __compat_inline__ U twiddle_out(U key) { return key ^ HIGH_BIT; }
};

template <typename U> struct base_traits<float, U> {
  static constexpr U HIGH_BIT = U(1) << ((sizeof(U) * 8) - 1);
  static __compat_inline__ U twiddle_in(U key) {
    U mask = (key & HIGH_BIT) ? U(-1) : HIGH_BIT;
    return key ^ mask;
  }
  static __compat_inline__ U twiddle_out(U key) {
    U mask = (key & HIGH_BIT) ? HIGH_BIT : U(-1);
    return key ^ mask;
  }
};

template <typename T> struct traits : base_traits<T, T> {};
template <> struct traits<uint32_t> : base_traits<uint32_t, uint32_t> {};
template <> struct traits<int> : base_traits<int, uint32_t> {};
template <> struct traits<float> : base_traits<float, uint32_t> {};

template <int N> struct power_of_two {
  enum { VALUE = ((N & (N - 1)) == 0) };
};

__compat_inline__ uint32_t shr_add(uint32_t x, uint32_t shift,
                                       uint32_t addend) {
  return (x >> shift) + addend;
}

} // namespace detail

/// Rearranging data partitioned across a work-group.
///
/// \tparam T The type of the data elements.
/// \tparam ElementsPerWorkItem The number of data elements assigned to a
/// work-item.
template <typename T, size_t ElementsPerWorkItem> class exchange {
public:
  static size_t get_local_memory_size(size_t group_threads) {
    size_t padding_values =
        (INSERT_PADDING)
            ? ((group_threads * ElementsPerWorkItem) >> LOG_LOCAL_MEMORY_BANKS)
            : 0;
    return (group_threads * ElementsPerWorkItem + padding_values) * sizeof(T);
  }

  exchange(uint8_t *local_memory) : _local_memory(local_memory) {}

  // TODO: Investigate if padding is required for performance,
  // and if specializations are required for specific target hardware.
  static size_t adjust_by_padding(size_t offset) {

    if constexpr (INSERT_PADDING) {
      offset = detail::shr_add(offset, LOG_LOCAL_MEMORY_BANKS, offset);
    }
    return offset;
  }

  struct blocked_offset {
    template <typename Item> size_t operator()(Item item, size_t i) {
      size_t offset = item.get_local_linear_id() * ElementsPerWorkItem + i;
      return adjust_by_padding(offset);
    }
  };

  struct striped_offset {
    template <typename Item> size_t operator()(Item item, size_t i) {
      size_t offset = i * item.get_local_range(2) * item.get_local_range(1) *
                          item.get_local_range(0) +
                      item.get_local_linear_id();
      return adjust_by_padding(offset);
    }
  };

  template <typename Iterator> struct scatter_offset {
    Iterator begin;
    scatter_offset(const int (&ranks)[ElementsPerWorkItem]) {
      begin = std::begin(ranks);
    }
    template <typename Item> size_t operator()(Item item, size_t i) const {
      // iterator i is expected to be within bounds [0,VALUES_PER_THREAD)
      return adjust_by_padding(begin[i]);
    }
  };

  /// Inplace rearrange elements from blocked order to striped order.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and the
  /// blocked \p input across the work-group is:
  ///
  ///   {[0, 1, 2, 3], [4, 5, 6, 7], ..., [508, 509, 510, 511]}.
  ///
  /// The striped order output is:
  ///
  ///   {[0, 128, 256, 384], [1, 129, 257, 385], ..., [127, 255, 383, 511]}.
  ///
  /// \tparam Item The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data of each work-item.
  template <typename Item>
  __compat_inline__ void
  blocked_to_striped(Item item, T (&input)[ElementsPerWorkItem]) {
    striped_offset get_striped_offset;
    blocked_offset get_blocked_offset;
    helper_exchange(item, input, input, get_blocked_offset, get_striped_offset);
  }

  /// Inplace rearrange elements from striped order to blocked order.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and the
  /// striped \p input across the work-group is:
  ///
  ///   { [0, 128, 256, 384], [1, 129, 257, 385], ..., [127, 255, 383, 511] }.
  ///
  /// The blocked order output is:
  ///
  ///   { [0, 1, 2, 3], [4, 5, 6, 7], ..., [508, 509, 510, 511] }.
  ///
  /// \tparam Item The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data of each work-item.
  template <typename Item>
  __compat_inline__ void
  striped_to_blocked(Item item, T (&input)[ElementsPerWorkItem]) {
    blocked_offset get_blocked_offset;
    striped_offset get_striped_offset;
    helper_exchange(item, input, input, get_striped_offset, get_blocked_offset);
  }

  /// Rearrange elements from blocked order to striped order.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and the
  /// blocked \p input across the work-group is:
  ///
  ///   { [0, 1, 2, 3], [4, 5, 6, 7], ..., [508, 509, 510, 511] }.
  ///
  /// The striped order output is:
  ///
  ///   { [0, 128, 256, 384], [1, 129, 257, 385], ..., [127, 255, 383, 511] }.
  ///
  /// \tparam Item The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data of each work-item.
  /// \param output The corresponding output data of each work-item.
  template <typename Item>
  __compat_inline__ void
  blocked_to_striped(Item item, T (&input)[ElementsPerWorkItem],
                     T (&output)[ElementsPerWorkItem]) {
    striped_offset get_striped_offset;
    blocked_offset get_blocked_offset;
    helper_exchange(item, input, output, get_blocked_offset,
                    get_striped_offset);
  }

  /// Rearrange elements from striped order to blocked order.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and the
  /// striped \p input across the work-group is:
  ///
  ///   { [0, 128, 256, 384], [1, 129, 257, 385], ..., [127, 255, 383, 511] }.
  ///
  /// The blocked order output is:
  ///
  ///   { [0, 1, 2, 3], [4, 5, 6, 7], ..., [508, 509, 510, 511] }.
  ///
  /// \tparam Item The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data of each work-item.
  /// \param output The corresponding output data of each work-item.
  template <typename Item>
  __compat_inline__ void
  striped_to_blocked(Item item, T (&input)[ElementsPerWorkItem],
                     T (&output)[ElementsPerWorkItem]) {
    blocked_offset get_blocked_offset;
    striped_offset get_striped_offset;
    helper_exchange(item, input, output, get_striped_offset,
                    get_blocked_offset);
  }

  /// Inplace exchanges data items annotated by rank into blocked arrangement.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and the
  /// striped \p input across the work-group is:
  ///
  ///   { [0, 128, 256, 384], [1, 129, 257, 385], ..., [127, 255, 383, 511] }.
  ///
  /// The rank across the work-group is:
  ///
  ///   { [0, 1, 2, 3], [4, 5, 6, 7], ..., [508, 509, 510, 511] }.
  ///
  /// The blocked order output is:
  ///
  ///   { [0, 1, 2, 3], [4, 5, 6, 7], ..., [508, 509, 510, 511] }.
  ///
  /// \tparam Item The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data of each work-item.
  /// \param ranks The corresponding rank annotation of each work-item.
  template <typename Item>
  __compat_inline__ void
  scatter_to_blocked(Item item, T (&input)[ElementsPerWorkItem],
                     int (&ranks)[ElementsPerWorkItem]) {
    scatter_offset<const int *> get_scatter_offset(ranks);
    blocked_offset get_blocked_offset;
    helper_exchange(item, input, input, get_scatter_offset, get_blocked_offset);
  }

  /// Inplace exchanges data items annotated by rank into striped arrangement.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and the
  /// blocked \p input across the work-group is:
  ///
  ///   { [0, 1, 2, 3], [4, 5, 6, 7], ..., [508, 509, 510, 511] }.
  ///
  /// The rank across the work-group is:
  ///
  ///   { [16, 20, 24, 28], [32, 36, 40, 44], ..., [499, 503, 507, 511] }.
  ///
  /// The striped order output of each work-item will be:
  ///
  ///   { [0, 128, 256, 384], [1, 129, 257, 385], ..., [127, 255, 383, 511] }.
  ///
  /// \tparam Item The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data of each work-item.
  /// \param ranks The corresponding rank annotation of each work-item.
  template <typename Item>
  __compat_inline__ void
  scatter_to_striped(Item item, T (&input)[ElementsPerWorkItem],
                     int (&ranks)[ElementsPerWorkItem]) {
    scatter_offset<const int *> get_scatter_offset(ranks);
    striped_offset get_striped_offset;
    helper_exchange(item, input, input, get_scatter_offset, get_striped_offset);
  }

private:
  template <typename Item, typename offsetFunctorTypeFW,
            typename offsetFunctorTypeRV>
  __compat_inline__ void
  helper_exchange(Item item, T (&input)[ElementsPerWorkItem],
                  T (&output)[ElementsPerWorkItem],
                  offsetFunctorTypeFW &offset_functor_fw,
                  offsetFunctorTypeRV &offset_functor_rv) {
    T *buffer = reinterpret_cast<T *>(_local_memory);
#pragma unroll
    for (size_t i = 0; i < ElementsPerWorkItem; i++) {
      size_t offset = offset_functor_fw(item, i);
      buffer[offset] = input[i];
    }
    sycl::group_barrier(item.get_group());
#pragma unroll
    for (size_t i = 0; i < ElementsPerWorkItem; i++) {
      size_t offset = offset_functor_rv(item, i);
      output[i] = buffer[offset];
    }
  }

  static constexpr int LOG_LOCAL_MEMORY_BANKS = 4;
  static constexpr bool INSERT_PADDING =
      (ElementsPerWorkItem > 4) &&
      (detail::power_of_two<ElementsPerWorkItem>::VALUE);

  uint8_t *_local_memory;
};

/// The work-group wide radix sort to sort integer data elements
/// assigned to all work-items in the work-group.
///
/// \tparam T The type of the data elements.
/// \tparam ElementsPerWorkItem The number of data elements assigned to
/// a work-item.
/// \tparam RADIX_BITS The number of radix bits per digit place.
template <typename T, int ElementsPerWorkItem, int RADIX_BITS = 4>
class group_radix_sort {
  uint8_t *_local_memory;

public:
  group_radix_sort(uint8_t *local_memory) : _local_memory(local_memory) {}

  static size_t get_local_memory_size(size_t group_threads) {
    size_t ranks_size =
        detail::radix_rank<RADIX_BITS>::get_local_memory_size(group_threads);
    size_t exchange_size =
        exchange<T, ElementsPerWorkItem>::get_local_memory_size(group_threads);
    return sycl::max(ranks_size, exchange_size);
  }

private:
  template <typename Item, bool DESCENDING>
  __compat_inline__ void
  helper_sort(const Item &item, T (&keys)[ElementsPerWorkItem],
              int begin_bit = 0, int end_bit = 8 * sizeof(T),
              bool is_striped = false) {

    uint32_t(&unsigned_keys)[ElementsPerWorkItem] =
        reinterpret_cast<uint32_t(&)[ElementsPerWorkItem]>(keys);

#pragma unroll
    for (int i = 0; i < ElementsPerWorkItem; ++i) {
      unsigned_keys[i] = detail::traits<T>::twiddle_in(unsigned_keys[i]);
    }

    for (int i = begin_bit; i < end_bit; i += RADIX_BITS) {
      int pass_bits = sycl::min(RADIX_BITS, end_bit - begin_bit);

      int ranks[ElementsPerWorkItem];
      detail::radix_rank<RADIX_BITS, DESCENDING>(_local_memory)
          .template rank_keys<Item, ElementsPerWorkItem>(item, unsigned_keys,
                                                         ranks, i, pass_bits);

      sycl::group_barrier(item.get_group());

      bool last_iter = i + RADIX_BITS >= end_bit;
      if (last_iter && is_striped) {
        exchange<T, ElementsPerWorkItem>(_local_memory)
            .scatter_to_striped(item, keys, ranks);

      } else {
        exchange<T, ElementsPerWorkItem>(_local_memory)
            .scatter_to_blocked(item, keys, ranks);
      }

      sycl::group_barrier(item.get_group());
    }

#pragma unroll
    for (int i = 0; i < ElementsPerWorkItem; ++i) {
      unsigned_keys[i] = detail::traits<T>::twiddle_out(unsigned_keys[i]);
    }
  }

public:
  /// Performs an ascending work-group wide radix sort over a blocked
  /// arrangement of input elements.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and the
  /// \p input across the work-group is:
  ///
  ///   { [0,511,1,510], [2,509,3,508], [4,507,5,506], ..., [254,257,255,256] }.
  ///
  /// The ascending order output is:
  ///
  ///   { [0,1,2,3], [4,5,6,7], [8,9,10,11], ..., [508,509,510,511] }.
  ///
  /// \tparam Item The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data of each work-item.
  /// \param begin_bit The beginning (least-significant) bit index needed for
  /// key comparison.
  /// \param end_bit The past-the-end (most-significant) bit
  /// index needed for key comparison.
  template <typename Item>
  __compat_inline__ void
  sort(const Item &item, T (&input)[ElementsPerWorkItem], int begin_bit = 0,
       int end_bit = 8 * sizeof(T)) {
    helper_sort<Item, /*DESCENDING=*/false>(item, input, begin_bit, end_bit);
  }

  /// Performs an descending work-group wide radix sort over a blocked
  /// arrangement of input elements.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and the
  /// \p input across the work-group is:
  ///
  ///   { [0,511,1,510], [2,509,3,508], [4,507,5,506], ..., [254,257,255,256] }.
  ///
  /// The descending order output is:
  ///
  ///   { [511,510,509,508], [11,10,9,8], [7,6,5,4], ..., [3,2,1,0] }.
  ///
  /// \tparam Item The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data of each work-item.
  /// \param begin_bit The beginning (least-significant) bit index needed for
  /// key comparison.
  /// \param end_bit The past-the-end (most-significant) bit
  /// index needed for key comparison.
  template <typename Item>
  __compat_inline__ void
  sort_descending(const Item &item, T (&input)[ElementsPerWorkItem],
                  int begin_bit = 0, int end_bit = 8 * sizeof(T)) {
    helper_sort<Item, /*DESCENDING=*/true>(item, input, begin_bit, end_bit);
  }

  /// Performs an ascending radix sort across a blocked arrangement of input
  /// elements, leaving them in a striped arrangement.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and the
  /// \p input across the work-group is:
  ///
  ///   { [0,511,1,510], [2,509,3,508], [4,507,5,506], ..., [254,257,255,256] }.
  ///
  /// The corresponding output of each work-item will be:
  ///
  ///   { [0,128,256,384], [1,129,257,385], [2,130,258,386], ...,
  ///   [127,255,383,511] }.
  ///
  /// \tparam Item The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data of each work-item.
  /// \param begin_bit The beginning (least-significant) bit index needed for
  /// key comparison.
  /// \param end_bit The past-the-end (most-significant) bit
  /// index needed for key comparison.
  template <typename Item>
  __compat_inline__ void
  sort_blocked_to_striped(const Item &item, T (&input)[ElementsPerWorkItem],
                          int begin_bit = 0, int end_bit = 8 * sizeof(T)) {
    helper_sort<Item, /*DESCENDING=*/false>(item, input, begin_bit, end_bit,
                                            /*is_striped=*/true);
  }

  /// Performs an descending radix sort across a blocked arrangement of input
  /// elements, leaving them in a striped arrangement.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and the
  /// \p input across the work-group is:
  ///
  ///   { [0,511,1,510], [2,509,3,508], [4,507,5,506], ..., [254,257,255,256] }.
  ///
  /// The descending striped order output is:
  ///
  ///   { [0,128,256,384], [1,129,257,385], [2,130,258,386], ...,
  ///   [127,255,383,511] }.
  ///
  /// \tparam Item The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data of each work-item.
  /// \param begin_bit The beginning (least-significant) bit index needed for
  /// key comparison.
  /// \param end_bit The past-the-end (most-significant) bit
  /// index needed for key comparison.
  template <typename Item>
  __compat_inline__ void sort_descending_blocked_to_striped(
      const Item &item, T (&input)[ElementsPerWorkItem], int begin_bit = 0,
      int end_bit = 8 * sizeof(T)) {
    helper_sort<Item, /*DESCENDING=*/true>(item, input, begin_bit, end_bit,
                                           /*is_striped=*/true);
  }
};

/// Load linear segment items into block format across threads
/// Helper for Block Load
enum load_algorithm {
  BLOCK_LOAD_DIRECT,
  BLOCK_LOAD_STRIPED,
};

/// Load a linear segment of elements into a blocked arrangement across the
/// work-group.
///
/// \tparam T The data type to load.
/// \tparam ElementsPerWorkItem The number of consecutive elements partitioned
/// onto each work-item.
/// \tparam InputIteratorT  The random-access iterator type for input \iterator.
/// \tparam ItemT The sycl::nd_item index space class.
/// \param item The calling work-item.
/// \param input_iter The work-group's base input iterator for loading from.
/// \param data Data to load.
template <typename T, size_t ElementsPerWorkItem, typename InputIteratorT,
          typename ItemT>
__compat_inline__ void load_direct_blocked(const ItemT &item,
                                               InputIteratorT input_iter,
                                               T (&data)[ElementsPerWorkItem]) {
  size_t work_item_id = item.get_local_linear_id();
#pragma unroll
  for (size_t i = 0; i < ElementsPerWorkItem; i++)
    data[i] = input_iter[(work_item_id * ElementsPerWorkItem) + i];
}

/// Load a linear segment of elements into a striped arrangement across the
/// work-group.
///
/// \tparam T The data type to load.
/// \tparam ElementsPerWorkItem The number of consecutive elements partitioned
/// onto each work-item.
/// \tparam InputIteratorT  The random-access iterator type for input \iterator.
/// \tparam ItemT The sycl::nd_item index space class.
/// \param item The calling work-item.
/// \param input_iter The work-group's base input iterator for loading from.
/// \param data Data to load.
template <typename T, int ElementsPerWorkItem, typename InputIteratorT,
          typename ItemT>
__compat_inline__ void load_direct_striped(const ItemT &item,
                                               InputIteratorT input_iter,
                                               T (&data)[ElementsPerWorkItem]) {
  size_t work_group_size = item.get_group().get_local_linear_range();
  size_t work_item_id = item.get_local_linear_id();
#pragma unroll
  for (size_t i = 0; i < ElementsPerWorkItem; i++)
    data[i] = input_iter[work_item_id + i * work_group_size];
}

/// Load a linear segment of elements into a blocked arrangement across the
/// work-group, guarded by range.
///
/// \tparam T The data type to load.
/// \tparam ElementsPerWorkItem The number of consecutive elements partitioned
/// onto each work-item.
/// \tparam InputIteratorT  The random-access iterator type for input \iterator.
/// \tparam ItemT The sycl::nd_item index space class.
/// \param item The calling work-item.
/// \param input_iter The work-group's base input iterator for loading from.
/// \param data Data to load.
/// \param valid_items Number of valid items to load
template <typename T, size_t ElementsPerWorkItem, typename InputIteratorT,
          typename ItemT>
__compat_inline__ void
load_direct_blocked(const ItemT &item, InputIteratorT input_iter,
                    T (&data)[ElementsPerWorkItem], int valid_items) {
  size_t work_item_id = item.get_local_linear_id();
#pragma unroll
  for (size_t i = 0; i < ElementsPerWorkItem; i++)
    if ((work_item_id * ElementsPerWorkItem) + i < valid_items)
      data[i] = input_iter[(work_item_id * ElementsPerWorkItem) + i];
}

/// Load a linear segment of elements into a striped arrangement across the
/// work-group, guarded by range.
///
/// \tparam T The data type to load.
/// \tparam ElementsPerWorkItem The number of consecutive elements partitioned
/// onto each work-item.
/// \tparam InputIteratorT  The random-access iterator type for input \iterator.
/// \tparam ItemT The sycl::nd_item index space class.
/// \param item The calling work-item.
/// \param input_iter The work-group's base input iterator for loading from.
/// \param data Data to load.
/// \param valid_items Number of valid items to load
template <typename T, int ElementsPerWorkItem, typename InputIteratorT,
          typename ItemT>
__compat_inline__ void
load_direct_striped(const ItemT &item, InputIteratorT input_iter,
                    T (&data)[ElementsPerWorkItem], int valid_items) {
  size_t work_group_size = item.get_group().get_local_linear_range();
  size_t work_item_id = item.get_local_linear_id();
#pragma unroll
  for (size_t i = 0; i < ElementsPerWorkItem; i++)
    if (work_item_id + (i * work_group_size) < valid_items)
      data[i] = input_iter[work_item_id + i * work_group_size];
}

/// Store a blocked arrangement of items across a work-group into a linear
/// segment of items.
///
/// \tparam T The data type to store.
/// \tparam ElementsPerWorkItem The number of consecutive elements partitioned
/// onto each work-item.
/// \tparam OutputIteratorT  The random-access iterator type for output.
/// \iterator.
/// \tparam ItemT The sycl::nd_item index space class.
/// \param item The calling work-item.
/// \param output_iter The work-group's base output iterator for writing.
/// \param data Data to store.
template <typename T, size_t ElementsPerWorkItem, typename OutputIteratorT,
          typename ItemT>
__compat_inline__ void
store_direct_blocked(const ItemT &item, OutputIteratorT output_iter,
                     T (&data)[ElementsPerWorkItem]) {
  size_t work_item_id = item.get_local_linear_id();
  OutputIteratorT work_item_iter =
      output_iter + (work_item_id * ElementsPerWorkItem);
#pragma unroll
  for (size_t i = 0; i < ElementsPerWorkItem; i++)
    work_item_iter[i] = data[i];
}

/// Store a striped arrangement of items across a work-group into a linear
/// segment of items.
///
/// \tparam T The data type to store.
/// \tparam ElementsPerWorkItem The number of consecutive elements partitioned
/// onto each work-item.
/// \tparam OutputIteratorT  The random-access iterator type for output.
/// \iterator.
/// \tparam ItemT The sycl::nd_item index space class.
/// \param item The calling work-item.
/// \param output_iter The work-group's base output iterator for writing.
/// \param items Data to store.
template <typename T, size_t ElementsPerWorkItem, typename OutputIteratorT,
          typename ItemT>
__compat_inline__ void
store_direct_striped(const ItemT &item, OutputIteratorT output_iter,
                     T (&data)[ElementsPerWorkItem]) {
  size_t work_group_size = item.get_group().get_local_linear_range();
  size_t work_item_id = item.get_local_linear_id();
  OutputIteratorT work_item_iter = output_iter + work_item_id;
#pragma unroll
  for (size_t i = 0; i < ElementsPerWorkItem; i++)
    work_item_iter[i * work_group_size] = data[i];
}

/// Store a blocked arrangement of items across a work-group into a linear
/// segment of items, guarded by range.
///
/// \tparam T The data type to store.
/// \tparam ElementsPerWorkItem The number of consecutive elements partitioned
/// onto each work-item.
/// \tparam OutputIteratorT  The random-access iterator type for output.
/// \iterator.
/// \tparam ItemT The sycl::nd_item index space class.
/// \param item The calling work-item.
/// \param output_iter The work-group's base output iterator for writing.
/// \param data Data to store.
/// \param valid_items Number of valid items to load
template <typename T, size_t ElementsPerWorkItem, typename OutputIteratorT,
          typename ItemT>
__compat_inline__ void
store_direct_blocked(const ItemT &item, OutputIteratorT output_iter,
                     T (&data)[ElementsPerWorkItem], size_t valid_items) {
  size_t work_item_id = item.get_local_linear_id();
  OutputIteratorT work_item_iter =
      output_iter + (work_item_id * ElementsPerWorkItem);
#pragma unroll
  for (size_t i = 0; i < ElementsPerWorkItem; i++)
    if (i + (work_item_id * ElementsPerWorkItem) < valid_items)
      work_item_iter[i] = data[i];
}

/// Store a striped arrangement of items across a work-group into a linear
/// segment of items, guarded by range.
///
/// \tparam T The data type to store.
/// \tparam ElementsPerWorkItem The number of consecutive elements partitioned
/// onto each work-item.
/// \tparam OutputIteratorT  The random-access iterator type for output.
/// \iterator.
/// \tparam ItemT The sycl::nd_item index space class.
/// \param item The calling work-item.
/// \param output_iter The work-group's base output iterator for writing.
/// \param items Data to store.
/// \param valid_items Number of valid items to load
template <typename T, size_t ElementsPerWorkItem, typename OutputIteratorT,
          typename ItemT>
__compat_inline__ void
store_direct_striped(const ItemT &item, OutputIteratorT output_iter,
                     T (&data)[ElementsPerWorkItem], size_t valid_items) {
  size_t work_group_size = item.get_group().get_local_linear_range();
  size_t work_item_id = item.get_local_linear_id();
  OutputIteratorT work_item_iter = output_iter + work_item_id;
#pragma unroll
  for (size_t i = 0; i < ElementsPerWorkItem; i++)
    if ((i * work_group_size) + work_item_id < valid_items)
      work_item_iter[i * work_group_size] = data[i];
}

/// Enumerates alternative algorithms for compat::group::group_load to read
/// a linear segment of data from memory into a blocked arrangement across a
/// work-group.
enum class group_load_algorithm {
  /// A blocked arrangement of data is read directly from memory.
  blocked,

  /// A striped arrangement of data is read directly from memory.
  striped
};

/// Provide methods for loading a linear segment of items from memory into a
/// blocked arrangement across a work-group.
///
/// \tparam T The input data type.
/// \tparam ElementsPerWorkItem The number of data elements assigned to a
/// work-item.
/// \tparam LoadAlgorithm The data movement strategy, default is blocked.
template <typename T, size_t ElementsPerWorkItem,
          group_load_algorithm LoadAlgorithm = group_load_algorithm::blocked>
class group_load {
public:
  static size_t get_local_memory_size([[maybe_unused]] size_t work_group_size) {
    return 0;
  }
  group_load(uint8_t *) {}

  /// Load a linear segment of items from memory.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and the
  /// \p input across the work-group is:
  ///
  ///   1, 2, 3, 4, 5, 6, 7, ..., 508, 509, 510, 511.
  ///
  /// The blocked order \p data of each work-item will be:
  ///
  ///   {[0,1,2,3], [4,5,6,7], ..., [508,509,510,511]}.
  ///
  /// The striped order \p output of each work-item will be:
  ///
  ///   {[0,128,256,384], [1,129,257,385], ..., [127,255,383,511]}.
  ///
  /// \tparam ItemT The sycl::nd_item index space class.
  /// \tparam InputIteratorT The random-access iterator type for input
  /// \iterator.
  /// \param item The work-item identifier.
  /// \param input_iter The work-group's base input iterator for loading from.
  /// \param data The data to load.
  template <typename ItemT, typename InputIteratorT>
  __compat_inline__ void load(const ItemT &item, InputIteratorT input_iter,
                                  T (&data)[ElementsPerWorkItem]) {
    if constexpr (LoadAlgorithm == group_load_algorithm::blocked) {
      load_direct_blocked<T, ElementsPerWorkItem, InputIteratorT, ItemT>(
          item, input_iter, data);
    } else if constexpr (LoadAlgorithm == group_load_algorithm::striped) {
      load_direct_striped<T, ElementsPerWorkItem, InputIteratorT, ItemT>(
          item, input_iter, data);
    }
  }

  /// Load a linear segment of items from memory, guarded by range.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and
  /// valid_items is 5, the \p input across the work-group is:
  ///
  ///   0, 1, 2, 3, 4, 5, 6, 7, ..., 508, 509, 510, 511.
  ///
  /// The blocked order \p data of each work-item will be:
  ///
  ///   {[0,1,2,3], [4,?,?,?], ..., [?,?,?,?]}.
  ///
  /// The striped order \p output of each work-item will be:
  ///
  ///   {[0,?,?,?], [1,?,?,?], [2,?,?,?], [3,?,?,?] ..., [?,?,?,?]}.
  ///
  /// \tparam ItemT The sycl::nd_item index space class.
  /// \tparam InputIteratorT The random-access iterator type for input
  /// \iterator.
  /// \param item The work-item identifier.
  /// \param input_iter The work-group's base input iterator for loading from.
  /// \param data The data to load.
  /// \param valid_items Number of valid items to load
  template <typename ItemT, typename InputIteratorT>
  __compat_inline__ void load(const ItemT &item, InputIteratorT input_iter,
                                  T (&data)[ElementsPerWorkItem],
                                  int valid_items) {
    if constexpr (LoadAlgorithm == group_load_algorithm::blocked) {
      load_direct_blocked<T, ElementsPerWorkItem, InputIteratorT, ItemT>(
          item, input_iter, data, valid_items);
    } else if constexpr (LoadAlgorithm == group_load_algorithm::striped) {
      load_direct_striped<T, ElementsPerWorkItem, InputIteratorT, ItemT>(
          item, input_iter, data, valid_items);
    }
  }
};

/// Enumerates alternative algorithms for compat::group::group_load to write
/// a blocked arrangement of items across a work-group to a linear segment of
/// memory.
enum class group_store_algorithm {
  /// A blocked arrangement of data is written directly to memory.
  blocked,

  /// A striped arrangement of data is written directly to memory.
  striped,
};

/// Provide methods for writing a blocked arrangement of elements partitioned
/// across a work-group to a linear segment of memory.
///
/// \tparam T The output data type.
/// \tparam ElementsPerWorkItem The number of data elements assigned to a
/// work-item.
/// \tparam StoreAlgorithm The data movement strategy, default is blocked.
template <typename T, size_t ElementsPerWorkItem,
          group_store_algorithm StoreAlgorithm = group_store_algorithm::blocked>
class group_store {
public:
  static size_t get_local_memory_size([[maybe_unused]] size_t work_group_size) {
    return 0;
  }
  group_store(uint8_t *) {}

  /// Store items into a linear segment of memory.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and the
  /// \p input across the work-group is:
  ///
  ///   {[0,1,2,3], [4,5,6,7], ..., [508,509,510,511]}.
  ///
  /// The blocked order \p output will be:
  ///
  ///   1, 2, 3, 4, 5, 6, 7, ..., 508, 509, 510, 511.
  ///
  /// The striped order \p output will be:
  ///
  ///   0, 128, 256, 384, 1, 129, 257, 385, ..., 127, 255, 383, 511.
  ///
  /// \tparam ItemT The sycl::nd_item index space class.
  /// \tparam OutputIteratorT The random-access iterator type for \p output
  /// iterator.
  /// \param item The work-item identifier.
  /// \param input The input data of each work-item.
  /// \param data The data to store.
  template <typename ItemT, typename OutputIteratorT>
  __compat_inline__ void store(const ItemT &item,
                                   OutputIteratorT output_iter,
                                   T (&data)[ElementsPerWorkItem]) {
    if constexpr (StoreAlgorithm == group_store_algorithm::blocked) {
      store_direct_blocked<T, ElementsPerWorkItem, OutputIteratorT, ItemT>(
          item, output_iter, data);
    } else if constexpr (StoreAlgorithm == group_store_algorithm::striped) {
      store_direct_striped<T, ElementsPerWorkItem, OutputIteratorT, ItemT>(
          item, output_iter, data);
    }
  }

  /// Store items into a linear segment of memory, guarded by range.
  ///
  /// Suppose 512 integer data elements partitioned across 128 work-items, where
  /// each work-item owns 4 ( \p ElementsPerWorkItem ) data elements and
  /// \p valid_items is 5, the \p output across the work-group is:
  ///
  ///   {[0,0,0,0], [0,0,0,0], ..., [0,0,0,0]}.
  ///
  /// The blocked order \p output will be:
  ///
  ///   0, 1, 2, 3, 4, 5, 0, 0, ..., 0, 0, 0, 0.
  ///
  /// The striped order \p output will be:
  ///
  ///   0, 4, 8, 12, 16, 0, 0, 0, ..., 0, 0, 0, 0.
  ///
  /// \tparam ItemT The sycl::nd_item index space class.
  /// \tparam OutputIteratorT The random-access iterator type for \p output
  /// iterator.
  /// \param item The work-item identifier.
  /// \param input The input data of each work-item.
  /// \param data The data to store.
  /// \param valid_items Number of valid items to load
  template <typename ItemT, typename OutputIteratorT>
  __compat_inline__ void
  store(const ItemT &item, OutputIteratorT output_iter,
        T (&data)[ElementsPerWorkItem], size_t valid_items) {
    if constexpr (StoreAlgorithm == group_store_algorithm::blocked) {
      store_direct_blocked<T, ElementsPerWorkItem, OutputIteratorT, ItemT>(
          item, output_iter, data, valid_items);
    } else if constexpr (StoreAlgorithm == group_store_algorithm::striped) {
      store_direct_striped<T, ElementsPerWorkItem, OutputIteratorT, ItemT>(
          item, output_iter, data, valid_items);
    }
  }
};

/// The work-group wide shuffle operations that allow work-items to exchange
/// data elements with other work-items within the same work-group.
///
/// \tparam T The type of the data elements.
/// \tparam group_dim_0 The first dimension size of the work-group.
/// \tparam group_dim_1 The second dimension size of the work-group.
/// \tparam group_dim_2 The third dimension size of the work-group.
template <typename T, int group_dim_0, int group_dim_1 = 1, int group_dim_2 = 1>
class group_shuffle {
  T *_local_memory = nullptr;
  static constexpr size_t group_work_items =
      group_dim_0 * group_dim_1 * group_dim_2;

public:
  static constexpr size_t get_local_memory_size(size_t work_group_size) {
    return sizeof(T) * work_group_size;
  }
  group_shuffle(uint8_t *local_memory) : _local_memory((T *)local_memory) {}

  /// Selects a value from a work-item at a given distance in the work-group
  /// and stores the value in the output.
  ///
  /// \tparam ItemT The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input from the calling work-item.
  /// \param output The output where the selected data will be stored.
  /// \param distance The distance of work-items to look ahead or behind in the
  /// work-group.
  template <typename ItemT>
  __compat_inline__ void select(const ItemT &item, T input, T &output,
                                    int distance = 1) {
    auto g = item.get_group();
    size_t id = g.get_local_linear_id();
    _local_memory[id] = input;

    sycl::group_barrier(g, sycl::memory_scope::work_group);

    const int target_id = static_cast<int>(id) + distance;
    if ((target_id >= 0) && (target_id < group_work_items)) {
      output = _local_memory[static_cast<size_t>(target_id)];
    }
  }
  /// Selects a value from a work-item at a given distance in the work-group
  /// and stores the value in the output, using a wrapped index to handle
  /// overflow.
  ///
  /// \tparam ItemT The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data to be selected.
  /// \param output The output where the selected data will be stored.
  /// \param distance The number of work-items to look ahead in the
  /// work-group.
  template <typename ItemT>
  __compat_inline__ void select2(const ItemT &item, T input, T &output,
                                     unsigned int distance = 1) {
    auto g = item.get_group();
    size_t id = g.get_local_linear_id();
    _local_memory[id] = input;

    sycl::group_barrier(g, sycl::memory_scope::work_group);

    unsigned int offset = id + distance;
    if (offset >= group_work_items)
      offset -= group_work_items;

    output = _local_memory[offset];
  }
  /// Performs a shuffle operation to move data to the right across the
  /// work-items, shifting elements in a work-item array by one position to the
  /// right.
  ///
  /// \tparam ElementsPerWorkItem The number of data elements per work-item.
  /// \tparam ItemT The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data to be shuffled.
  /// \param output The array that will store the shuffle result.
  template <int ElementsPerWorkItem, typename ItemT>
  __compat_inline__ void shuffle_right(const ItemT &item,
                                           T (&input)[ElementsPerWorkItem],
                                           T (&output)[ElementsPerWorkItem]) {
    auto g = item.get_group();
    size_t id = g.get_local_linear_id();
    _local_memory[id] = input[ElementsPerWorkItem - 1];

    sycl::group_barrier(g, sycl::memory_scope::work_group);

#pragma unroll
    for (int index = ElementsPerWorkItem - 1; index > 0; --index)
      output[index] = input[index - 1];

    if (id > 0)
      output[0] = _local_memory[id - 1];
  }
  /// Performs a shuffle operation to move data to the right across the
  /// work-items, storing the suffix of the group after the shuffle operation.
  ///
  /// \tparam ElementsPerWorkItem The number of data elements per work-item.
  /// \tparam ItemT The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data to be shuffled.
  /// \param output The array that will store the shuffle result.
  /// \param group_suffix The suffix of the group after the shuffle.
  template <int ElementsPerWorkItem, typename ItemT>
  __compat_inline__ void
  shuffle_right(const ItemT &item, T (&input)[ElementsPerWorkItem],
                T (&output)[ElementsPerWorkItem], T &group_suffix) {
    shuffle_right(item, input, output);
    group_suffix = _local_memory[group_work_items - 1];
  }
  /// Performs a shuffle operation to move data to the left across the
  /// work-items, shifting elements in a work-item array by one position to the
  /// left.
  ///
  /// \tparam ElementsPerWorkItem The number of data elements per work-item.
  /// \tparam ItemT The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data to be shuffled.
  /// \param output The array that will store the shuffle result.
  template <int ElementsPerWorkItem, typename ItemT>
  __compat_inline__ void shuffle_left(const ItemT &item,
                                          T (&input)[ElementsPerWorkItem],
                                          T (&output)[ElementsPerWorkItem]) {
    auto g = item.get_group();
    size_t id = g.get_local_linear_id();
    _local_memory[id] = input[0];

    sycl::group_barrier(g, sycl::memory_scope::work_group);

#pragma unroll
    for (int index = 0; index < ElementsPerWorkItem - 1; index++)
      output[index] = input[index + 1];

    if (id < group_work_items - 1)
      output[ElementsPerWorkItem - 1] = _local_memory[id + 1];
  }
  /// Performs a shuffle operation to move data to the left across the
  /// work-items, storing the prefix of the group before the shuffle operation.
  ///
  /// \tparam ElementsPerWorkItem The number of data elements per work-item.
  /// \tparam ItemT The work-item identifier type.
  /// \param item The work-item identifier.
  /// \param input The input data to be shuffled.
  /// \param output The array that will store the shuffle result.
  /// \param group_prefix The prefix of the group before the shuffle.
  template <int ElementsPerWorkItem, typename ItemT>
  __compat_inline__ void
  shuffle_left(const ItemT &item, T (&input)[ElementsPerWorkItem],
               T (&output)[ElementsPerWorkItem], T &group_prefix) {
    shuffle_left(item, input, output);
    group_prefix = _local_memory[0];
  }
};
} // namespace group
} // namespace compat
