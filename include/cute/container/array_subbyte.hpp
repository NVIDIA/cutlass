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

#include <cute/numeric/int.hpp>           // sizeof_bits
#include <cute/numeric/integral_constant.hpp>
#include <cute/container/bit_field.hpp>   // dummy_type

namespace cute
{

//
// Underlying subbyte storage type
//
template <class T>
using subbyte_storage_type_t = conditional_t<(sizeof_bits_v<T> <=   8), uint8_t,
                               conditional_t<(sizeof_bits_v<T> <=  16), uint16_t,
                               conditional_t<(sizeof_bits_v<T> <=  32), uint32_t,
                               conditional_t<(sizeof_bits_v<T> <=  64), uint64_t,
                               conditional_t<(sizeof_bits_v<T> <= 128), uint128_t,
                               dummy_type>>>>>;

template <class T>
struct subbyte_iterator;

//
// subbyte_reference
//   Proxy object for sub-byte element references
//
template <class T>
struct subbyte_reference 
{
  // Iterator Element type (const or non-const)
  using element_type = T;
  // Iterator Value type without type qulifier.
  using value_type   = remove_cv_t<T>;
  // Storage type (const or non-const)
  using storage_type = conditional_t<(is_const_v<T>), subbyte_storage_type_t<T> const, subbyte_storage_type_t<T>>;

  static_assert(!is_same_v<storage_type, dummy_type>, "Storage type is not supported");

  static_assert(sizeof_bits_v<element_type> <= sizeof_bits_v<storage_type>,
                "Size of Element must not be greater than Storage.");

  // Number of logical elements per stored object
  static constexpr uint8_t ElementsPerStoredItem = sizeof_bits_v<storage_type> / sizeof_bits_v<element_type>;
  // Bitmask for covering one item
  static constexpr storage_type BitMask = storage_type((storage_type(1) << sizeof_bits_v<element_type>) - 1);

private:

  friend class subbyte_iterator<T>;
  
  // Pointer to storage element
  storage_type* ptr_ = nullptr;

  // Index into elements packed into storage_type element. RI: 0 <= idx_ < ElementsPerStoredItem
  uint8_t idx_ = 0;

  // Ctor
  template <class PointerType>
  CUTE_HOST_DEVICE constexpr
  subbyte_reference(PointerType* ptr, uint8_t idx = 0) : ptr_(reinterpret_cast<storage_type*>(ptr)), idx_(idx) {}

public:

  // Copy Ctor
  CUTE_HOST_DEVICE constexpr 
  subbyte_reference(subbyte_reference const& other) {
    *this = element_type(other);
  }

  // Copy Assignment
  CUTE_HOST_DEVICE constexpr 
  subbyte_reference& operator=(subbyte_reference const& other) {
    return *this = element_type(other);
  }

  // Dtor
  ~subbyte_reference() = default;

  // Assignment
  template<class T_=element_type>
  CUTE_HOST_DEVICE constexpr
  enable_if_t<!is_const_v<T_>,  subbyte_reference&> operator=(element_type x) {
    static_assert(is_same_v<T_, element_type>, "Do not specify template arguments!");
    storage_type item = (reinterpret_cast<storage_type const &>(x) & BitMask);
    storage_type kUpdateMask = storage_type(~(BitMask << (idx_ * sizeof_bits_v<element_type>)));
    *ptr_ = storage_type((*ptr_ & kUpdateMask) | (item << (idx_ * sizeof_bits_v<element_type>)));
    return *this;
  }

  CUTE_HOST_DEVICE
  element_type get() const {
    if constexpr (is_same_v<bool, value_type>) {      // Extract to bool -- potentially faster impl
      return bool((*ptr_) & (BitMask << (idx_ * sizeof_bits_v<element_type>)));
    } else {                                          // Extract to element_type
      storage_type item = storage_type((*ptr_ >> (idx_ * sizeof_bits_v<element_type>)) & BitMask);
      return reinterpret_cast<element_type &>(item);
    }
  }

  // Extract to type element_type
  CUTE_HOST_DEVICE constexpr
  operator element_type() const {
    return get();
  }
};


//
// subbyte_iterator
//   Random-access iterator over subbyte references
//
template <class T>
struct subbyte_iterator 
{
  // Iterator Element type (const or non-const)
  using element_type = T;
  // Iterator Value type without type qulifier.
  using value_type   = remove_cv_t<T>;
  // Storage type (const or non-const)
  using storage_type = conditional_t<(is_const_v<T>), subbyte_storage_type_t<T> const, subbyte_storage_type_t<T>>;
  // Reference proxy type
  using reference = subbyte_reference<element_type>;

  static_assert(!is_same_v<storage_type, dummy_type>, "Storage type is not supported");

  static_assert(sizeof_bits_v<element_type> <= sizeof_bits_v<storage_type>,
                "Size of Element must not be greater than Storage.");

  // Number of logical elements per stored object
  static constexpr uint8_t ElementsPerStoredItem = sizeof_bits_v<storage_type> / sizeof_bits_v<element_type>;

private:

  // Pointer to storage element
  storage_type* ptr_ = nullptr;

  // Index into elements packed into storage_type element. RI: 0 <= idx_ < ElementsPerStoredItem
  uint8_t idx_ = 0;

public:

  template <class PointerType>
  CUTE_HOST_DEVICE constexpr
  subbyte_iterator(PointerType* ptr, uint8_t idx = 0): ptr_(reinterpret_cast<storage_type*>(ptr)), idx_(idx) { }

  subbyte_iterator() = default;
  CUTE_HOST_DEVICE constexpr
  subbyte_iterator& operator++() {
    ++idx_;
    if (idx_ == ElementsPerStoredItem) {
      ++ptr_;
      idx_ = 0;
    }
    return *this;
  }

  CUTE_HOST_DEVICE constexpr
  subbyte_iterator& operator--() {
    if (idx_) {
      --idx_;
    } else {
      --ptr_;
      idx_ = ElementsPerStoredItem - 1;
    }
    return *this;
  }

  CUTE_HOST_DEVICE constexpr
  subbyte_iterator operator++(int) {
    subbyte_iterator ret(*this);
    ++(*this);
    return ret;
  }

  CUTE_HOST_DEVICE constexpr
  subbyte_iterator operator--(int) {
    subbyte_iterator ret(*this);
    --(*this);
    return ret;
  }

  CUTE_HOST_DEVICE constexpr
  subbyte_iterator& operator+=(uint64_t k) {
    k += idx_;
    ptr_ += k / ElementsPerStoredItem;
    idx_  = k % ElementsPerStoredItem;
    return *this;
  }

  CUTE_HOST_DEVICE constexpr
  subbyte_iterator operator+(uint64_t k) const {
    return subbyte_iterator(ptr_,idx_) += k;
  }

  CUTE_HOST_DEVICE constexpr
  reference operator*() const {
    return reference(ptr_, idx_);
  }

  CUTE_HOST_DEVICE constexpr
  reference operator[](uint64_t k) const {
    return *(*this + k);
  }

  CUTE_HOST_DEVICE constexpr
  friend bool operator==(subbyte_iterator const& x, subbyte_iterator const& y) {
    return x.ptr_ == y.ptr_ && x.idx_ == y.idx_;
  }

  CUTE_HOST_DEVICE constexpr
  friend bool operator!=(subbyte_iterator const& x, subbyte_iterator const& y) {
    return !(x == y);
  }
};

//
// array_subbyte
//   Statically sized array for non-byte-aligned data types
//
template <class T, size_t N>
struct array_subbyte
{
  using element_type    = T;
  using value_type      = remove_cv_t<T>;
  using pointer         = element_type*;
  using const_pointer   = element_type const*;

  using size_type       = size_t;
  using difference_type = ptrdiff_t;

  //
  // References
  //
  using reference       = subbyte_reference<element_type>;
  using const_reference = subbyte_reference<element_type const>;

  //
  // Iterators
  //
  using iterator        = subbyte_iterator<element_type>;
  using const_iterator  = subbyte_iterator<element_type const>;

  // Storage type (const or non-const)
  using storage_type = conditional_t<(is_const_v<T>), subbyte_storage_type_t<T> const, subbyte_storage_type_t<T>>;

  static_assert(!is_same_v<storage_type, dummy_type>, "Storage type is not supported");

  // Number of logical elements per stored object
  static constexpr uint8_t ElementsPerStoredItem = sizeof_bits_v<storage_type> / sizeof_bits_v<T>;

  // Bitmask for covering one item
  static constexpr storage_type BitMask = ((storage_type(1) << sizeof_bits<T>::value) - 1);

  // Number of storage elements
  static constexpr size_type StorageElements = (N + ElementsPerStoredItem - 1) / ElementsPerStoredItem;

private:

  // Internal storage
  storage_type storage[StorageElements];

public:

  CUTE_HOST_DEVICE constexpr
  array_subbyte() { }

  CUTE_HOST_DEVICE constexpr
  array_subbyte(array_subbyte const& x) {
    CUTE_UNROLL
    for (size_type i = 0; i < StorageElements; ++i) {
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

  // Efficient clear method
  CUTE_HOST_DEVICE constexpr
  void clear() {
    CUTE_UNROLL
    for (size_type i = 0; i < StorageElements; ++i) {
      storage[i] = storage_type(0);
    }
  }

  // Efficient fill method
  CUTE_HOST_DEVICE constexpr
  void fill(T const& value) {
    storage_type item = (reinterpret_cast<storage_type const&>(value) & BitMask);

    // Reproduce the value over the bits of the storage item
    CUTE_UNROLL
    for (size_type s = sizeof_bits_v<T>; s < sizeof_bits_v<storage_type>; s *= 2) {
      item |= item << s;
    }

    CUTE_UNROLL
    for (size_type i = 0; i < StorageElements; ++i) {
      storage[i] = item;
    }
  }

  CUTE_HOST_DEVICE constexpr
  reference at(size_type pos) {
    return iterator(storage)[pos];
  }

  CUTE_HOST_DEVICE constexpr
  const_reference at(size_type pos) const {
    return const_iterator(storage)[pos];
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
    return at(N-1);
  }

  CUTE_HOST_DEVICE constexpr
  const_reference back() const {
    return at(N-1);
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
  storage_type* raw_data() {
    return storage;
  }

  CUTE_HOST_DEVICE constexpr
  storage_type const* raw_data() const {
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
    return iterator(storage + N / ElementsPerStoredItem, N % ElementsPerStoredItem);
  }

  CUTE_HOST_DEVICE constexpr
  const_iterator end() const {
    return const_iterator(storage + N / ElementsPerStoredItem, N % ElementsPerStoredItem);
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
    : CUTE_STL_NAMESPACE::integral_constant<size_t, N>
{};

template <size_t I, class T, size_t N>
struct tuple_element<I, cute::array_subbyte<T,N>>
{
  using type = T;
};

template <class T, size_t N>
struct tuple_size<const cute::array_subbyte<T,N>>
    : CUTE_STL_NAMESPACE::integral_constant<size_t, N>
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
    : CUTE_STL_NAMESPACE::integral_constant<size_t, N>
{};

template <size_t I, class T, size_t N>
struct tuple_element<I, cute::array_subbyte<T,N>>
{
  using type = T;
};

template <class T, size_t N>
struct tuple_size<const cute::array_subbyte<T,N>>
    : CUTE_STL_NAMESPACE::integral_constant<size_t, N>
{};

template <size_t I, class T, size_t N>
struct tuple_element<I, const cute::array_subbyte<T,N>>
{
  using type = T;
};

} // end namespace std
#endif // CUTE_STL_NAMESPACE_IS_CUDA_STD
