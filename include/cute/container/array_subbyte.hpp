/***************************************************************************************************
 * Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
/*! \file
    \brief Statically sized array of elements that accommodates subbyte trivial types
           in a packed storage.
*/

#pragma once

#include <cute/config.hpp>

#include <cute/numeric/int.hpp>   // sizeof_bits
#include <cute/numeric/integral_constant.hpp>

namespace cute
{

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Statically sized array for any data type
template <class T, size_t N>
class array_subbyte
{
 public:

  /// Number of total bits in the array
  static constexpr int kSizeBits = sizeof_bits<T>::value * N;

  /// Storage type
  using Storage = conditional_t<(kSizeBits % 32) == 0, uint32_t,
                  conditional_t<(kSizeBits % 16) == 0, uint16_t,
                                                                           uint8_t>>;

  /// Number of logical elements per stored object
  static constexpr int kElementsPerStoredItem = sizeof_bits<Storage>::value / sizeof_bits<T>::value;

  /// Number of storage elements
  static constexpr size_t kStorageElements = (N + kElementsPerStoredItem - 1) / kElementsPerStoredItem;

  /// Bitmask for covering one item
  static constexpr Storage bit_mask_ = ((Storage(1) << sizeof_bits<T>::value) - 1);

  //
  // C++ standard members with reference and iterator types omitted
  //

  using value_type    = T;
  using pointer       = value_type*;
  using const_pointer = value_type const*;

  using size_type       = size_t;
  using difference_type = ptrdiff_t;

  //
  // References
  //

  /// Reference object inserts or extracts sub-byte items
  class reference {
    /// Pointer to storage element
    Storage* ptr_;

    /// Index into elements packed into Storage object
    int idx_;

  public:

    /// Default ctor
    CUTE_HOST_DEVICE constexpr
    reference() : ptr_(nullptr), idx_(0) {}

    /// Ctor
    CUTE_HOST_DEVICE constexpr
    reference(Storage* ptr, int idx = 0) : ptr_(ptr), idx_(idx) {}

    /// Assignment
    CUTE_HOST_DEVICE constexpr
    reference& operator=(T x) {
      Storage item = (x & bit_mask_);
      Storage kUpdateMask = Storage(~(bit_mask_ << (idx_ * sizeof_bits<T>::value)));
      *ptr_ = Storage((*ptr_ & kUpdateMask) | (item << (idx_ * sizeof_bits<T>::value)));
      return *this;
    }

    CUTE_HOST_DEVICE constexpr
    T get() const {
      if constexpr (is_same<bool, T>::value) {
        // Extract to bool -- potentially faster impl
        return bool((*ptr_) & (bit_mask_ << (idx_ * sizeof_bits<T>::value)));
      } else {
        // Extract to T
        Storage item = Storage((*ptr_ >> (idx_ * sizeof_bits<T>::value)) & bit_mask_);
        return reinterpret_cast<T const&>(item);
      }
    }

    /// Extract to type T
    CUTE_HOST_DEVICE constexpr
    operator T() const {
      return get();
    }
  };

  /// Reference object extracts sub-byte items
  class const_reference {

    /// Pointer to storage element
    Storage const* ptr_;

    /// Index into elements packed into Storage object
    int idx_;

  public:

    /// Default ctor
    CUTE_HOST_DEVICE constexpr
    const_reference(): ptr_(nullptr), idx_(0) { }

    /// Ctor
    CUTE_HOST_DEVICE constexpr
    const_reference(Storage const* ptr, int idx = 0): ptr_(ptr), idx_(idx) { }

    CUTE_HOST_DEVICE constexpr
    const T get() const {
      if constexpr (is_same<bool, T>::value) {
        // Extract to bool -- potentially faster impl
        return bool((*ptr_) & (bit_mask_ << (idx_ * sizeof_bits<T>::value)));
      } else {
        // Extract to T
        Storage item = Storage((*ptr_ >> (idx_ * sizeof_bits<T>::value)) & bit_mask_);
        return reinterpret_cast<T const&>(item);
      }
    }

    /// Extract to type T
    CUTE_HOST_DEVICE constexpr
    operator T() const {
      return get();
    }
  };

  //
  // Iterators
  //

  /// Bidirectional iterator over elements
  class iterator {

    /// Pointer to storage element
    Storage* ptr_;

    /// Index into elements packed into Storage object
    int idx_;

  public:

    CUTE_HOST_DEVICE constexpr
    iterator(): ptr_(nullptr), idx_(0) { }

    CUTE_HOST_DEVICE constexpr
    iterator(Storage* ptr, int idx = 0): ptr_(ptr), idx_(idx) { }

    CUTE_HOST_DEVICE constexpr
    iterator& operator++() {
      ++idx_;
      if (idx_ == kElementsPerStoredItem) {
        ++ptr_;
        idx_ = 0;
      }
      return *this;
    }

    CUTE_HOST_DEVICE constexpr
    iterator& operator--() {
      if (idx_) {
        --idx_;
      } else {
        --ptr_;
        idx_ = kElementsPerStoredItem - 1;
      }
      return *this;
    }

    CUTE_HOST_DEVICE constexpr
    iterator operator++(int) {
      iterator ret(*this);
      ++(*this);
      return ret;
    }

    CUTE_HOST_DEVICE constexpr
    iterator operator--(int) {
      iterator ret(*this);
      --(*this);
      return ret;
    }

    CUTE_HOST_DEVICE constexpr
    iterator& operator+=(int k) {
      idx_ += k;
      ptr_ += idx_ / kElementsPerStoredItem;
      idx_  = idx_ % kElementsPerStoredItem;
      return *this;
    }

    CUTE_HOST_DEVICE constexpr
    iterator operator+(int k) const {
      return iterator(ptr_,idx_) += k;
    }

    CUTE_HOST_DEVICE constexpr
    reference operator*() const {
      return reference(ptr_, idx_);
    }

    CUTE_HOST_DEVICE constexpr
    reference operator[](int k) const {
      return *(*this + k);
    }

    CUTE_HOST_DEVICE constexpr
    bool operator==(iterator const& other) const {
      return ptr_ == other.ptr_ && idx_ == other.idx_;
    }

    CUTE_HOST_DEVICE constexpr
    bool operator!=(iterator const& other) const {
      return !(*this == other);
    }
  };

  /// Bidirectional constant iterator over elements
  class const_iterator {

    /// Pointer to storage element
    Storage const* ptr_;

    /// Index into elements packed into Storage object
    int idx_;

  public:

    CUTE_HOST_DEVICE constexpr
    const_iterator(): ptr_(nullptr), idx_(0) { }

    CUTE_HOST_DEVICE constexpr
    const_iterator(Storage const* ptr, int idx = 0): ptr_(ptr), idx_(idx) { }

    CUTE_HOST_DEVICE constexpr
    const_iterator& operator++() {
      ++idx_;
      if (idx_ == kElementsPerStoredItem) {
        ++ptr_;
        idx_ = 0;
      }
      return *this;
    }

    CUTE_HOST_DEVICE constexpr
    const_iterator& operator--() {
      if (idx_) {
        --idx_;
      } else {
        --ptr_;
        idx_ = kElementsPerStoredItem - 1;
      }
      return *this;
    }

    CUTE_HOST_DEVICE constexpr
    const_iterator operator++(int) {
      iterator ret(*this);
      ++idx_;
      if (idx_ == kElementsPerStoredItem) {
        ++ptr_;
        idx_ = 0;
      }
      return ret;
    }

    CUTE_HOST_DEVICE constexpr
    const_iterator operator--(int) {
      iterator ret(*this);
      if (idx_) {
        --idx_;
      } else {
        --ptr_;
        idx_ = kElementsPerStoredItem - 1;
      }
      return ret;
    }

    CUTE_HOST_DEVICE constexpr
    const_iterator& operator+=(int k) {
      idx_ += k;
      ptr_ += idx_ / kElementsPerStoredItem;
      idx_  = idx_ % kElementsPerStoredItem;
      return *this;
    }

    CUTE_HOST_DEVICE constexpr
    const_iterator operator+(int k) const {
      return const_iterator(ptr_,idx_) += k;
    }

    CUTE_HOST_DEVICE constexpr
    const_reference operator*() const {
      return const_reference(ptr_, idx_);
    }

    CUTE_HOST_DEVICE constexpr
    const_reference operator[](int k) const {
      return *(*this + k);
    }

    CUTE_HOST_DEVICE constexpr
    bool operator==(iterator const& other) const {
      return ptr_ == other.ptr_ && idx_ == other.idx_;
    }

    CUTE_HOST_DEVICE constexpr
    bool operator!=(iterator const& other) const {
      return !(*this == other);
    }
  };

private:

  /// Internal storage
  Storage storage[kStorageElements];

public:

  CUTE_HOST_DEVICE constexpr
  array_subbyte() { }

  CUTE_HOST_DEVICE constexpr
  array_subbyte(array_subbyte const& x) {
    CUTE_UNROLL
    for (unsigned i = 0; i < kStorageElements; ++i) {
      storage[i] = x.storage[i];
    }
  }

  CUTE_HOST_DEVICE constexpr
  size_type size() const {
    return N;
  }

  CUTE_HOST_DEVICE constexpr
  size_type max_size() const {
    return N;
  }

  CUTE_HOST_DEVICE constexpr
  bool empty() const {
    return !N;
  }

  /// Efficient clear method
  CUTE_HOST_DEVICE constexpr
  void clear() {
    CUTE_UNROLL
    for (unsigned i = 0; i < kStorageElements; ++i) {
      storage[i] = Storage(0);
    }
  }

  // Efficient fill method
  CUTE_HOST_DEVICE constexpr
  void fill(T const& value) {
    Storage item = (reinterpret_cast<Storage const&>(value) & bit_mask_);

    // Reproduce the value over the bits of the storage item
    CUTE_UNROLL
    for (unsigned s = sizeof_bits<T>::value; s < sizeof_bits<Storage>::value; s *= 2) {
      item |= item << s;
    }

    CUTE_UNROLL
    for (unsigned i = 0; i < kStorageElements; ++i) {
      storage[i] = item;
    }
  }

  CUTE_HOST_DEVICE constexpr
  reference at(size_type pos) {
    return reference(storage + pos / kElementsPerStoredItem, pos % kElementsPerStoredItem);
  }

  CUTE_HOST_DEVICE constexpr
  const_reference at(size_type pos) const {
    return const_reference(storage + pos / kElementsPerStoredItem, pos % kElementsPerStoredItem);
  }

  CUTE_HOST_DEVICE constexpr
  reference operator[](size_type pos) {
    return at(pos);
  }

  CUTE_HOST_DEVICE constexpr
  const_reference operator[](size_type pos) const {
    return at(pos);
  }

  CUTE_HOST_DEVICE constexpr
  reference front() {
    return at(0);
  }

  CUTE_HOST_DEVICE constexpr
  const_reference front() const {
    return at(0);
  }

  CUTE_HOST_DEVICE constexpr
  reference back() {
    return reference(storage + kStorageElements - 1, kElementsPerStoredItem - 1);
  }

  CUTE_HOST_DEVICE constexpr
  const_reference back() const {
    return const_reference(storage + kStorageElements - 1, kElementsPerStoredItem - 1);
  }

  CUTE_HOST_DEVICE constexpr
  pointer data() {
    return reinterpret_cast<pointer>(storage);
  }

  CUTE_HOST_DEVICE constexpr
  const_pointer data() const {
    return reinterpret_cast<const_pointer>(storage);
  }

  CUTE_HOST_DEVICE constexpr
  Storage* raw_data() {
    return storage;
  }

  CUTE_HOST_DEVICE constexpr
  Storage const* raw_data() const {
    return storage;
  }

  CUTE_HOST_DEVICE constexpr
  iterator begin() {
    return iterator(storage);
  }

  CUTE_HOST_DEVICE constexpr
  const_iterator begin() const {
    return const_iterator(storage);
  }

  CUTE_HOST_DEVICE constexpr
  const_iterator cbegin() const {
    return begin();
  }

  CUTE_HOST_DEVICE constexpr
  iterator end() {
    return iterator(storage + N / kElementsPerStoredItem, N % kElementsPerStoredItem);
  }

  CUTE_HOST_DEVICE constexpr
  const_iterator end() const {
    return const_iterator(storage + N / kElementsPerStoredItem, N % kElementsPerStoredItem);
  }

  CUTE_HOST_DEVICE constexpr
  const_iterator cend() const {
    return end();
  }

  //
  // Comparison operators
  //

};

//
// Operators
//

template <class T, size_t N>
CUTE_HOST_DEVICE constexpr
void clear(array_subbyte<T,N>& a)
{
  a.clear();
}

template <class T, size_t N>
CUTE_HOST_DEVICE constexpr
void fill(array_subbyte<T,N>& a, T const& value)
{
  a.fill(value);
}

////////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cute

//
// Specialize tuple-related functionality for cute::array_subbyte
//

#if defined(__CUDACC_RTC__)
#include <cuda/std/tuple>
#else
#include <tuple>
#endif

namespace cute
{

template <size_t I, class T, size_t N>
CUTE_HOST_DEVICE constexpr
T& get(array_subbyte<T,N>& a)
{
  static_assert(I < N, "Index out of range");
  return a[I];
}

template <size_t I, class T, size_t N>
CUTE_HOST_DEVICE constexpr
T const& get(array_subbyte<T,N> const& a)
{
  static_assert(I < N, "Index out of range");
  return a[I];
}

template <size_t I, class T, size_t N>
CUTE_HOST_DEVICE constexpr
T&& get(array_subbyte<T,N>&& a)
{
  static_assert(I < N, "Index out of range");
  return std::move(a[I]);
}

} // end namespace cute

namespace CUTE_STL_NAMESPACE
{

template <class T, size_t N>
struct tuple_size<cute::array_subbyte<T,N>>
    : cute::integral_constant<size_t, N>
{};

template <size_t I, class T, size_t N>
struct tuple_element<I, cute::array_subbyte<T,N>>
{
  using type = T;
};

template <class T, size_t N>
struct tuple_size<const cute::array_subbyte<T,N>>
    : cute::integral_constant<size_t, N>
{};

template <size_t I, class T, size_t N>
struct tuple_element<I, const cute::array_subbyte<T,N>>
{
  using type = T;
};

} // end namespace CUTE_STL_NAMESPACE

#ifdef CUTE_STL_NAMESPACE_IS_CUDA_STD
namespace std
{

#if defined(__CUDACC_RTC__)
template <class... _Tp>
struct tuple_size;

template<size_t _Ip, class... _Tp>
struct tuple_element;
#endif

template <class T, size_t N>
struct tuple_size<cute::array_subbyte<T,N>>
    : cute::integral_constant<size_t, N>
{};

template <size_t I, class T, size_t N>
struct tuple_element<I, cute::array_subbyte<T,N>>
{
  using type = T;
};

template <class T, size_t N>
struct tuple_size<const cute::array_subbyte<T,N>>
    : cute::integral_constant<size_t, N>
{};

template <size_t I, class T, size_t N>
struct tuple_element<I, const cute::array_subbyte<T,N>>
{
  using type = T;
};

} // end namespace std
#endif // CUTE_STL_NAMESPACE_IS_CUDA_STD
