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
 *  math.hpp
 *
 *  Description:
 *    math utilities for the SYCL compatibility extension.
 **************************************************************************/

// The original source was under the license below:
//==---- math.hpp ---------------------------------*- C++ -*----------------==//
//
// Copyright (C) Intel Corporation
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// See https://llvm.org/LICENSE.txt for license information.
//
//===----------------------------------------------------------------------===//

#pragma once

#include <limits>
#include <sycl/feature_test.hpp>
#include <type_traits>

// TODO(compat-lib-reviewers): this should not be required
#ifndef SYCL_EXT_ONEAPI_COMPLEX
#define SYCL_EXT_ONEAPI_COMPLEX
#endif

#ifdef SYCL_EXT_ONEAPI_BFLOAT16_MATH_FUNCTIONS
#include <sycl/ext/oneapi/experimental/bfloat16_math.hpp>
#endif
#include <sycl/ext/oneapi/experimental/complex/complex.hpp>
#include <compat/traits.hpp>

namespace compat {
namespace detail {

namespace complex_namespace = sycl::ext::oneapi::experimental;

template <typename ValueT>
using complex_type = detail::complex_namespace::complex<ValueT>;

template <typename T>
constexpr bool is_int32_type = std::is_same_v<std::decay_t<T>, int32_t> ||
  std::is_same_v<std::decay_t<T>, uint32_t>;

// Helper constexpr bool to avoid ugly macros where possible
#ifdef SYCL_EXT_ONEAPI_BFLOAT16_MATH_FUNCTIONS
constexpr bool support_bfloat16_math = true;
#else
constexpr bool support_bfloat16_math = false;
#endif

template <typename ValueT>
inline ValueT clamp(ValueT val, ValueT min_val, ValueT max_val) {
  return sycl::clamp(val, min_val, max_val);
}
#ifdef SYCL_EXT_ONEAPI_BFLOAT16_MATH_FUNCTIONS
// TODO(compat-lib-reviewers): Follow the process to add this (& other math
// fns) to the bfloat16 math function extension. If added, remove this
// functionality from the header.
template <>
inline sycl::ext::oneapi::bfloat16 clamp(sycl::ext::oneapi::bfloat16 val,
                                         sycl::ext::oneapi::bfloat16 min_val,
                                         sycl::ext::oneapi::bfloat16 max_val) {
  if (val < min_val)
    return min_val;
  if (val > max_val)
    return max_val;
  return val;
}

template <typename T, int Size>
inline std::enable_if_t<std::is_same_v<T, sycl::ext::oneapi::bfloat16>,
                        sycl::vec<T, Size>>
clamp(sycl::vec<T, Size> val, sycl::vec<T, Size> min_val,
      sycl::vec<T, Size> max_val) {
  return [&val, &min_val, &max_val]<int... I>(std::integer_sequence<int, I...>) {
    return sycl::vec<T, Size>{
        clamp<sycl::ext::oneapi::bfloat16>(val[I], min_val[I], max_val[I])...};
  }(std::make_integer_sequence<int, Size>{});
}

template <typename T, std::size_t Size>
inline std::enable_if_t<std::is_same_v<T, sycl::ext::oneapi::bfloat16>,
                        sycl::marray<T, Size>>
clamp(sycl::marray<T, Size> val, sycl::marray<T, Size> min_val,
      sycl::marray<T, Size> max_val) {
  return [&val, &min_val, &max_val]<std::size_t... I>(std::index_sequence<I...>) {
    return sycl::marray<T, Size>{
        clamp<sycl::ext::oneapi::bfloat16>(val[I], min_val[I], max_val[I])...};
  }(std::make_index_sequence<Size>{});
}
#endif

template <typename VecT, class BinaryOperation, class = void>
class vectorized_binary {
public:
  inline VecT operator()(VecT a, VecT b, const BinaryOperation binary_op) {
    VecT v4;
    for (size_t i = 0; i < v4.size(); ++i) {
      v4[i] = binary_op(a[i], b[i]);
    }
    return v4;
  }
};

template <typename VecT, class BinaryOperation>
class vectorized_binary<
    VecT, BinaryOperation,
    std::void_t<std::invoke_result_t<BinaryOperation, VecT, VecT>>> {
public:
  inline VecT operator()(VecT a, VecT b, const BinaryOperation binary_op) {
    return binary_op(a, b).template as<VecT>();
  }
};

/// Extend the 'val' to 'bit' size, zero extend for unsigned int and signed
/// extend for signed int. Returns a signed integer type.
template <typename ValueT>
inline auto zero_or_signed_extend(ValueT val, unsigned bit) {
  static_assert(std::is_integral_v<ValueT>);
  if constexpr (sizeof(ValueT) == 4) {
    assert(bit < 64 &&
           "When extending int32 value, bit must be smaller than 64.");
    if constexpr (std::is_signed_v<ValueT>)
      return int64_t(val) << (64 - bit) >> (64 - bit);
    else
      return int64_t(val);
  } else if constexpr (sizeof(ValueT) == 2) {
    assert(bit < 32 &&
           "When extending int16 value, bit must be smaller than 32.");
    if constexpr (std::is_signed_v<ValueT>)
      return int32_t(val) << (32 - bit) >> (32 - bit);
    else
      return int32_t(val);
  } else if constexpr (sizeof(ValueT) == 1) {
    assert(bit < 16 &&
           "When extending int8 value, bit must be smaller than 16.");
    if constexpr (std::is_signed_v<ValueT>)
      return int16_t(val) << (16 - bit) >> (16 - bit);
    else
      return int16_t(val);
  } else {
    static_assert(sizeof(ValueT) == 8);
    assert(bit < 64 && "Cannot extend int64 value.");
    return static_cast<int64_t>(val);
  }
}

template <typename RetT, bool needSat, typename AT, typename BT,
          typename BinaryOperation>
inline constexpr RetT extend_binary(AT a, BT b, BinaryOperation binary_op) {
  const int64_t extend_a = zero_or_signed_extend(a, 33);
  const int64_t extend_b = zero_or_signed_extend(b, 33);
  const int64_t ret = binary_op(extend_a, extend_b);
  if constexpr (needSat)
    return detail::clamp<int64_t>(ret, std::numeric_limits<RetT>::min(),
                                  std::numeric_limits<RetT>::max());
  return ret;
}

template <typename RetT, bool needSat, typename AT, typename BT, typename CT,
          typename BinaryOperation1, typename BinaryOperation2>
inline constexpr RetT extend_binary(AT a, BT b, CT c,
                                    BinaryOperation1 binary_op,
                                    BinaryOperation2 second_op) {
  const int64_t extend_a = zero_or_signed_extend(a, 33);
  const int64_t extend_b = zero_or_signed_extend(b, 33);
  int64_t extend_temp =
      zero_or_signed_extend(binary_op(extend_a, extend_b), 34);
  if constexpr (needSat)
    extend_temp =
        detail::clamp<int64_t>(extend_temp, std::numeric_limits<RetT>::min(),
                               std::numeric_limits<RetT>::max());
  const int64_t extend_c = zero_or_signed_extend(c, 33);
  return second_op(extend_temp, extend_c);
}

template <typename T> sycl::vec<int32_t, 2> extract_and_extend2(T a) {
  sycl::vec<int32_t, 2> ret;
  sycl::vec<T, 1> va{a};
  using IntT = std::conditional_t<std::is_signed_v<T>, int16_t, uint16_t>;
  auto v = va.template as<sycl::vec<IntT, 2>>();
  ret[0] = zero_or_signed_extend(v[0], 17);
  ret[1] = zero_or_signed_extend(v[1], 17);
  return ret;
}

template <typename T> sycl::vec<int16_t, 4> extract_and_extend4(T a) {
  sycl::vec<int16_t, 4> ret;
  sycl::vec<T, 1> va{a};
  using IntT = std::conditional_t<std::is_signed_v<T>, int8_t, uint8_t>;
  auto v = va.template as<sycl::vec<IntT, 4>>();
  ret[0] = zero_or_signed_extend(v[0], 9);
  ret[1] = zero_or_signed_extend(v[1], 9);
  ret[2] = zero_or_signed_extend(v[2], 9);
  ret[3] = zero_or_signed_extend(v[3], 9);
  return ret;
}

template <typename RetT, bool NeedSat, bool NeedAdd, typename AT, typename BT,
          typename BinaryOperation>
inline constexpr RetT extend_vbinary2(AT a, BT b, RetT c,
                                      BinaryOperation binary_op) {
  static_assert(is_int32_type<AT> && is_int32_type<BT> && is_int32_type<RetT>);
  sycl::vec<int32_t, 2> extend_a = extract_and_extend2(a);
  sycl::vec<int32_t, 2> extend_b = extract_and_extend2(b);
  sycl::vec<int32_t, 2> temp{binary_op(extend_a[0], extend_b[0]),
                             binary_op(extend_a[1], extend_b[1])};
  using IntT = std::conditional_t<std::is_signed_v<RetT>, int16_t, uint16_t>;

  if constexpr (NeedSat) {
    int32_t min_val = 0, max_val = 0;
    min_val = std::numeric_limits<IntT>::min();
    max_val = std::numeric_limits<IntT>::max();
    temp = detail::clamp(temp, sycl::vec<int32_t, 2>(min_val),
                         sycl::vec<int32_t, 2>(max_val));
  }
  if constexpr (NeedAdd) {
    return temp[0] + temp[1] + c;
  }
  return sycl::vec<IntT, 2>{temp[0], temp[1]}.template as<sycl::vec<RetT, 1>>();
}

template <typename RetT, bool NeedSat, bool NeedAdd, typename AT, typename BT,
          typename BinaryOperation>
inline constexpr RetT extend_vbinary4(AT a, BT b, RetT c,
                                      BinaryOperation binary_op) {
  static_assert(is_int32_type<AT> && is_int32_type<BT> && is_int32_type<RetT>);
  sycl::vec<int16_t, 4> extend_a = extract_and_extend4(a);
  sycl::vec<int16_t, 4> extend_b = extract_and_extend4(b);
  sycl::vec<int16_t, 4> temp{
      binary_op(extend_a[0], extend_b[0]), binary_op(extend_a[1], extend_b[1]),
      binary_op(extend_a[2], extend_b[2]), binary_op(extend_a[3], extend_b[3])};
  using IntT = std::conditional_t<std::is_signed_v<RetT>, int8_t, uint8_t>;

  if constexpr (NeedSat) {
    int16_t min_val = 0, max_val = 0;
    min_val = std::numeric_limits<IntT>::min();
    max_val = std::numeric_limits<IntT>::max();
    temp = detail::clamp(temp, sycl::vec<int16_t, 4>(min_val),
                         sycl::vec<int16_t, 4>(max_val));
  }
  if constexpr (NeedAdd) {
    return temp[0] + temp[1] + temp[2] + temp[3] + c;
  }

  return sycl::vec<IntT, 4>{temp[0], temp[1], temp[2], temp[3]}
      .template as<sycl::vec<RetT, 1>>();
}

template <typename ValueT> inline bool isnan(const ValueT a) {
  if constexpr (std::is_same_v<ValueT, sycl::ext::oneapi::bfloat16>) {
    static_assert(detail::support_bfloat16_math);
    return sycl::ext::oneapi::experimental::isnan(a);
  } else {
    return sycl::isnan(a);
  }
}

// FIXME(compat-lib-reviewers): move bfe outside detail once perf is
// improved & semantics understood
/// Bitfield-extract.
///
/// \tparam T The type of \param source value, must be an integer.
/// \param source The source value to extracting.
/// \param bit_start The position to start extracting.
/// \param num_bits The number of bits to extracting.
template <typename T>
inline T bfe(const T source, const uint32_t bit_start,
             const uint32_t num_bits) {
  static_assert(std::is_unsigned_v<T>);
  // FIXME(compat-lib-reviewers): This ternary was added to catch a case
  // which may be undefined anyway. Consider that we are losing perf here.
  const T mask =
      num_bits >= std::numeric_limits<unsigned char>::digits * sizeof(T)
          ? static_cast<T>(-1)
          : ((static_cast<T>(1) << num_bits) - 1);
  return (source >> bit_start) & mask;
}

} // namespace detail

/// Bitfield-extract with boundary checking.
///
/// Extract bit field from \param source and return the zero or sign-extended
/// result. Source \param bit_start gives the bit field starting bit position,
/// and source \param num_bits gives the bit field length in bits.
///
/// The result is padded with the sign bit of the extracted field. If `num_bits`
/// is zero, the result is zero. If the start position is beyond the msb of the
/// input, the result is filled with the replicated sign bit of the extracted
/// field.
///
/// \tparam T The type of \param source value, must be an integer.
/// \param source The source value to extracting.
/// \param bit_start The position to start extracting.
/// \param num_bits The number of bits to extracting.
template <typename T>
inline T bfe_safe(const T source, const uint32_t bit_start,
                  const uint32_t num_bits) {
  static_assert(std::is_integral_v<T>);
#if defined(__SYCL_DEVICE_ONLY__) && defined(__NVPTX__)
  if constexpr (std::is_same_v<T, int8_t> || std::is_same_v<T, int16_t> ||
                std::is_same_v<T, int32_t>) {
    int32_t res{};
    asm volatile("bfe.s32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"((int32_t)source), "r"(bit_start), "r"(num_bits));
    return res;
  } else if constexpr (std::is_same_v<T, uint8_t> ||
                       std::is_same_v<T, uint16_t> ||
                       std::is_same_v<T, uint32_t>) {
    uint32_t res{};
    asm volatile("bfe.u32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"((uint32_t)source), "r"(bit_start), "r"(num_bits));
    return res;
  } else if constexpr (std::is_same_v<T, int64_t>) {
    T res{};
    asm volatile("bfe.s64 %0, %1, %2, %3;"
                 : "=l"(res)
                 : "l"(source), "r"(bit_start), "r"(num_bits));
    return res;
  } else if constexpr (std::is_same_v<T, uint64_t>) {
    T res{};
    asm volatile("bfe.u64 %0, %1, %2, %3;"
                 : "=l"(res)
                 : "l"(source), "r"(bit_start), "r"(num_bits));
    return res;
  }
#endif
  const uint32_t bit_width =
      std::numeric_limits<unsigned char>::digits * sizeof(T);
  const uint32_t pos = std::min(bit_start, bit_width);
  const uint32_t len = std::min(pos + num_bits, bit_width) - pos;
  if constexpr (std::is_signed_v<T>) {
    // FIXME(compat-lib-reviewers): As above, catching a case whose result
    // is undefined and likely losing perf.
    const T mask = len >= bit_width ? T{-1} : static_cast<T>((T{1} << len) - 1);

    // Find the sign-bit, the result is padded with the sign bit of the
    // extracted field.
    // Note if requested num_bits==0, we return zero via sign_bit=0
    const uint32_t sign_bit_pos = std::min(pos + len - 1, bit_width - 1);
    const T sign_bit = num_bits != 0 && ((source >> sign_bit_pos) & 1);
    const T sign_bit_padding = (-sign_bit & ~mask);
    return ((source >> pos) & mask) | sign_bit_padding;
  } else {
    return compat::detail::bfe(source, pos, len);
  }
}

namespace detail {
// FIXME(compat-lib-reviewers): move bfi outside detail once perf is
// improved & semantics understood
/// Bitfield-insert.
///
/// \tparam T The type of \param x and \param y , must be an unsigned integer.
/// \param x The source of the bitfield.
/// \param y The source where bitfield is inserted.
/// \param bit_start The position to start insertion.
/// \param num_bits The number of bits to insertion.
template <typename T>
inline T bfi(const T x, const T y, const uint32_t bit_start,
             const uint32_t num_bits) {
  static_assert(std::is_unsigned_v<T>);
  constexpr unsigned bit_width =
      std::numeric_limits<unsigned char>::digits * sizeof(T);

  // if bit_start > bit_width || len == 0, should return y.
  const T ignore_bfi = static_cast<T>(bit_start > bit_width || num_bits == 0);
  T extract_bitfield_mask = (static_cast<T>(~T{0}) >> (bit_width - num_bits))
                            << bit_start;
  T clean_bitfield_mask = ~extract_bitfield_mask;
  return (y & (-ignore_bfi | clean_bitfield_mask)) |
         (~-ignore_bfi & ((x << bit_start) & extract_bitfield_mask));
}
} // namespace detail

/// Bitfield-insert with boundary checking.
///
/// Align and insert a bit field from \param x into \param y . Source \param
/// bit_start gives the starting bit position for the insertion, and source
/// \param num_bits gives the bit field length in bits.
///
/// \tparam T The type of \param x and \param y , must be an unsigned integer.
/// \param x The source of the bitfield.
/// \param y The source where bitfield is inserted.
/// \param bit_start The position to start insertion.
/// \param num_bits The number of bits to insertion.
template <typename T>
inline T bfi_safe(const T x, const T y, const uint32_t bit_start,
                  const uint32_t num_bits) {
  static_assert(std::is_unsigned_v<T>);
#if defined(__SYCL_DEVICE_ONLY__) && defined(__NVPTX__)
  if constexpr (std::is_same_v<T, uint8_t> || std::is_same_v<T, uint16_t> ||
                std::is_same_v<T, uint32_t>) {
    uint32_t res{};
    asm volatile("bfi.b32 %0, %1, %2, %3, %4;"
                 : "=r"(res)
                 : "r"((uint32_t)x), "r"((uint32_t)y), "r"(bit_start),
                   "r"(num_bits));
    return res;
  } else if constexpr (std::is_same_v<T, uint64_t>) {
    uint64_t res{};
    asm volatile("bfi.b64 %0, %1, %2, %3, %4;"
                 : "=l"(res)
                 : "l"(x), "l"(y), "r"(bit_start), "r"(num_bits));
    return res;
  }
#endif
  constexpr unsigned bit_width =
      std::numeric_limits<unsigned char>::digits * sizeof(T);
  const uint32_t pos = std::min(bit_start, bit_width);
  const uint32_t len = std::min(pos + num_bits, bit_width) - pos;
  return compat::detail::bfi(x, y, pos, len);
}

/// Emulated function for __funnelshift_l
inline unsigned int funnelshift_l(unsigned int low, unsigned int high,
                                  unsigned int shift) {
  return (sycl::upsample(high, low) << (shift & 31U)) >> 32;
}

/// Emulated function for __funnelshift_lc
inline unsigned int funnelshift_lc(unsigned int low, unsigned int high,
                                   unsigned int shift) {
  return (sycl::upsample(high, low) << sycl::min(shift, 32U)) >> 32;
}

/// Emulated function for __funnelshift_r
inline unsigned int funnelshift_r(unsigned int low, unsigned int high,
                                  unsigned int shift) {
  return (sycl::upsample(high, low) >> (shift & 31U)) & 0xFFFFFFFF;
}

/// Emulated function for __funnelshift_rc
inline unsigned int funnelshift_rc(unsigned int low, unsigned int high,
                                   unsigned int shift) {
  return (sycl::upsample(high, low) >> sycl::min(shift, 32U)) & 0xFFFFFFFF;
}

/// Compute fast_length for variable-length array
/// \param [in] a The array
/// \param [in] len Length of the array
/// \returns The computed fast_length
inline float fast_length(const float *a, int len) {
  switch (len) {
  case 1:
    return sycl::fast_length(a[0]);
  case 2:
    return sycl::fast_length(sycl::float2(a[0], a[1]));
  case 3:
    return sycl::fast_length(sycl::float3(a[0], a[1], a[2]));
  case 4:
    return sycl::fast_length(sycl::float4(a[0], a[1], a[2], a[3]));
  case 0:
    return 0;
  default:
    float f = 0;
    for (int i = 0; i < len; ++i)
      f += a[i] * a[i];
    return sycl::sqrt(f);
  }
}

/// Calculate the square root of the input array.
/// \param [in] a The array pointer
/// \param [in] len Length of the array
/// \returns The square root
template <typename ValueT>
inline ValueT length(const ValueT *a, const int len) {
  switch (len) {
  case 1:
    return a[0];
  case 2:
    return sycl::length(sycl::vec<ValueT, 2>(a[0], a[1]));
  case 3:
    return sycl::length(sycl::vec<ValueT, 3>(a[0], a[1], a[2]));
  case 4:
    return sycl::length(sycl::vec<ValueT, 4>(a[0], a[1], a[2], a[3]));
  default:
    ValueT ret = 0;
    for (int i = 0; i < len; ++i)
      ret += a[i] * a[i];
    return sycl::sqrt(ret);
  }
}

/// Performs comparison.
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] binary_op functor that implements the binary operation
/// \returns the comparison result
template <typename ValueT, class BinaryOperation>
inline std::enable_if_t<
    std::is_same_v<std::invoke_result_t<BinaryOperation, ValueT, ValueT>, bool>,
    bool>
compare(const ValueT a, const ValueT b, const BinaryOperation binary_op) {
  return binary_op(a, b);
}
template <typename ValueT>
inline std::enable_if_t<
    std::is_same_v<std::invoke_result_t<std::not_equal_to<>, ValueT, ValueT>,
                   bool>,
    bool>
compare(const ValueT a, const ValueT b, const std::not_equal_to<> binary_op) {
  return !detail::isnan(a) && !detail::isnan(b) && binary_op(a, b);
}

/// Performs 2 element comparison.
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] binary_op functor that implements the binary operation
/// \returns the comparison result
template <typename ValueT, class BinaryOperation>
inline std::enable_if_t<ValueT::size() == 2, ValueT>
compare(const ValueT a, const ValueT b, const BinaryOperation binary_op) {
  return {compare(a[0], b[0], binary_op), compare(a[1], b[1], binary_op)};
}

/// Performs unordered comparison.
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] binary_op functor that implements the binary operation
/// \returns the comparison result
template <typename ValueT, class BinaryOperation>
inline std::enable_if_t<
    std::is_same_v<std::invoke_result_t<BinaryOperation, ValueT, ValueT>, bool>,
    bool>
unordered_compare(const ValueT a, const ValueT b,
                  const BinaryOperation binary_op) {
  return detail::isnan(a) || detail::isnan(b) || binary_op(a, b);
}

/// Performs 2 element unordered comparison.
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] binary_op functor that implements the binary operation
/// \returns the comparison result
template <typename ValueT, class BinaryOperation>
inline std::enable_if_t<ValueT::size() == 2, ValueT>
unordered_compare(const ValueT a, const ValueT b,
                  const BinaryOperation binary_op) {
  return {unordered_compare(a[0], b[0], binary_op),
          unordered_compare(a[1], b[1], binary_op)};
}

/// Performs 2 element comparison and return true if both results are true.
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] binary_op functor that implements the binary operation
/// \returns the comparison result
template <typename ValueT, class BinaryOperation>
inline std::enable_if_t<ValueT::size() == 2, bool>
compare_both(const ValueT a, const ValueT b, const BinaryOperation binary_op) {
  return compare(a[0], b[0], binary_op) && compare(a[1], b[1], binary_op);
}

/// Performs 2 element unordered comparison and return true if both results are
/// true.
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] binary_op functor that implements the binary operation
/// \returns the comparison result
template <typename ValueT, class BinaryOperation>
inline std::enable_if_t<ValueT::size() == 2, bool>
unordered_compare_both(const ValueT a, const ValueT b,
                       const BinaryOperation binary_op) {
  return unordered_compare(a[0], b[0], binary_op) &&
         unordered_compare(a[1], b[1], binary_op);
}

/// Performs 2 elements comparison, compare result of each element is 0 (false)
/// or 0xffff (true), returns an unsigned int by composing compare result of two
/// elements.
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] binary_op functor that implements the binary operation
/// \returns the comparison result
template <typename ValueT, class BinaryOperation>
inline std::enable_if_t<ValueT::size() == 2, unsigned>
compare_mask(const ValueT a, const ValueT b, const BinaryOperation binary_op) {
  // Since compare returns 0 or 1, -compare will be 0x00000000 or 0xFFFFFFFF
  return ((-compare(a[0], b[0], binary_op)) & 0xFFFF) |
         ((-compare(a[1], b[1], binary_op)) << 16u);
}

/// Performs 2 elements unordered comparison, compare result of each element is
/// 0 (false) or 0xffff (true), returns an unsigned int by composing compare
/// result of two elements.
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] binary_op functor that implements the binary operation
/// \returns the comparison result
template <typename ValueT, class BinaryOperation>
inline std::enable_if_t<ValueT::size() == 2, unsigned>
unordered_compare_mask(const ValueT a, const ValueT b,
                       const BinaryOperation binary_op) {
  return ((-unordered_compare(a[0], b[0], binary_op)) & 0xFFFF) |
         ((-unordered_compare(a[1], b[1], binary_op)) << 16);
}

/// Compute vectorized max for two values, with each value treated as a vector
/// type \p S
/// \param [in] S The type of the vector
/// \param [in] T The type of the original values
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The vectorized max of the two values
template <typename S, typename T> inline T vectorized_max(T a, T b) {
  sycl::vec<T, 1> v0{a}, v1{b};
  auto v2 = v0.template as<S>();
  auto v3 = v1.template as<S>();
  v2 = sycl::max(v2, v3);
  v0 = v2.template as<sycl::vec<T, 1>>();
  return v0;
}

/// Compute vectorized min for two values, with each value treated as a vector
/// type \p S
/// \param [in] S The type of the vector
/// \param [in] T The type of the original values
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The vectorized min of the two values
template <typename S, typename T> inline T vectorized_min(T a, T b) {
  sycl::vec<T, 1> v0{a}, v1{b};
  auto v2 = v0.template as<S>();
  auto v3 = v1.template as<S>();
  v2 = sycl::min(v2, v3);
  v0 = v2.template as<sycl::vec<T, 1>>();
  return v0;
}

/// Compute vectorized unary operation for a value, with the value treated as a
/// vector type \p VecT.
/// \tparam [in] VecT The type of the vector
/// \tparam [in] UnaryOperation The unary operation class
/// \param [in] a The input value
/// \returns The vectorized unary operation value of the input value
template <typename VecT, class UnaryOperation>
inline unsigned vectorized_unary(unsigned a, const UnaryOperation unary_op) {
  sycl::vec<unsigned, 1> v0{a};
  auto v1 = v0.as<VecT>();
  auto v2 = unary_op(v1);
  v0 = v2.template as<sycl::vec<unsigned, 1>>();
  return v0;
}

/// Compute vectorized absolute difference for two values without modulo
/// overflow, with each value treated as a vector type \p VecT.
/// \tparam [in] VecT The type of the vector
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The vectorized absolute difference of the two values
template <typename VecT>
inline unsigned vectorized_sum_abs_diff(unsigned a, unsigned b) {
  sycl::vec<unsigned, 1> v0{a}, v1{b};
  // Need convert element type to wider signed type to avoid overflow.
  auto v2 = v0.as<VecT>().template convert<int>();
  auto v3 = v1.as<VecT>().template convert<int>();
  auto v4 = sycl::abs_diff(v2, v3);
  unsigned sum = 0;
  for (size_t i = 0; i < v4.size(); ++i) {
    sum += v4[i];
  }
  return sum;
}

/// Compute vectorized isgreater for two values, with each value treated as a
/// vector type \p S
/// \param [in] S The type of the vector
/// \param [in] T The type of the original values
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The vectorized greater than of the two values
template <typename S, typename T> inline T vectorized_isgreater(T a, T b) {
  sycl::vec<T, 1> v0{a}, v1{b};
  auto v2 = v0.template as<S>();
  auto v3 = v1.template as<S>();
  auto v4 = sycl::isgreater(v2, v3);
  v0 = v4.template as<sycl::vec<T, 1>>();
  return v0;
}

/// Compute vectorized isgreater for two unsigned int values, with each value
/// treated as a vector of two unsigned short
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The vectorized greater than of the two values
template <>
inline unsigned vectorized_isgreater<sycl::ushort2, unsigned>(unsigned a,
                                                              unsigned b) {
  sycl::vec<unsigned, 1> v0{a}, v1{b};
  auto v2 = v0.template as<sycl::ushort2>();
  auto v3 = v1.template as<sycl::ushort2>();
  sycl::ushort2 v4;
  v4[0] = v2[0] > v3[0];
  v4[1] = v2[1] > v3[1];
  v0 = v4.template as<sycl::vec<unsigned, 1>>();
  return v0;
}

/// Returns min(max(val, min_val), max_val)
/// \param [in] val The input value
/// \param [in] min_val The minimum value
/// \param [in] max_val The maximum value
/// \returns the value between min_val and max_val
template <typename ValueT>
inline ValueT clamp(ValueT val, ValueT min_val, ValueT max_val) {
  return detail::clamp(val, min_val, max_val);
}

/// Determine whether 2 element value is NaN.
/// \param [in] a The input value
/// \returns the comparison result
template <typename ValueT>
inline std::enable_if_t<ValueT::size() == 2, ValueT> isnan(const ValueT a) {
  return {detail::isnan(a[0]), detail::isnan(a[1])};
}

/// cbrt function wrapper.
template <typename ValueT>
inline std::enable_if_t<std::is_floating_point_v<ValueT> ||
                            std::is_same_v<ValueT, sycl::half>,
                        ValueT>
cbrt(ValueT val) {
  return sycl::cbrt(static_cast<ValueT>(val));
}

// min/max function overloads.
// For floating-point types, `float` or `double` arguments are acceptable.
// For integer types, `std::uint32_t`, `std::int32_t`, `std::uint64_t` or
// `std::int64_t` type arguments are acceptable.
// sycl::half supported as well, and sycl::ext::oneapi::bfloat16 if available.
template <typename ValueT, typename ValueU>
inline std::enable_if_t<std::is_integral_v<ValueT> &&
                            std::is_integral_v<ValueU>,
                        std::common_type_t<ValueT, ValueU>>
min(ValueT a, ValueU b) {
  return sycl::min(static_cast<std::common_type_t<ValueT, ValueU>>(a),
                   static_cast<std::common_type_t<ValueT, ValueU>>(b));
}

template <typename ValueT, typename ValueU>
inline std::enable_if_t<compat::is_floating_point_v<ValueT> &&
                            compat::is_floating_point_v<ValueU>,
                        std::common_type_t<ValueT, ValueU>>
min(ValueT a, ValueU b) {
  if constexpr (std::is_same_v<std::common_type_t<ValueT, ValueU>,
                               sycl::ext::oneapi::bfloat16>) {
    static_assert(detail::support_bfloat16_math);
    return sycl::ext::oneapi::experimental::fmin(
        static_cast<std::common_type_t<ValueT, ValueU>>(a),
        static_cast<std::common_type_t<ValueT, ValueU>>(b));
  } else {
    return sycl::fmin(static_cast<std::common_type_t<ValueT, ValueU>>(a),
                      static_cast<std::common_type_t<ValueT, ValueU>>(b));
  }
}

template <typename ValueT, typename ValueU>
inline std::enable_if_t<std::is_integral_v<ValueT> &&
                            std::is_integral_v<ValueU>,
                        std::common_type_t<ValueT, ValueU>>
max(ValueT a, ValueU b) {
  return sycl::max(static_cast<std::common_type_t<ValueT, ValueU>>(a),
                   static_cast<std::common_type_t<ValueT, ValueU>>(b));
}
template <typename ValueT, typename ValueU>
inline std::enable_if_t<compat::is_floating_point_v<ValueT> &&
                            compat::is_floating_point_v<ValueU>,
                        std::common_type_t<ValueT, ValueU>>
max(ValueT a, ValueU b) {
  if constexpr (std::is_same_v<std::common_type_t<ValueT, ValueU>,
                               sycl::ext::oneapi::bfloat16>) {
    static_assert(detail::support_bfloat16_math);
    return sycl::ext::oneapi::experimental::fmax(
        static_cast<std::common_type_t<ValueT, ValueU>>(a),
        static_cast<std::common_type_t<ValueT, ValueU>>(b));
  } else {
    return sycl::fmax(static_cast<std::common_type_t<ValueT, ValueU>>(a),
                      static_cast<std::common_type_t<ValueT, ValueU>>(b));
  }
}

/// Performs 2 elements comparison and returns the bigger one. If either of
/// inputs is NaN, then return NaN.
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns the bigger value
template <typename ValueT, typename ValueU>
inline std::common_type_t<ValueT, ValueU> fmax_nan(const ValueT a,
                                                   const ValueU b) {
  if (detail::isnan(a) || detail::isnan(b))
    return NAN;
  return compat::max(a, b);
}

template <typename ValueT, typename ValueU>
inline sycl::vec<std::common_type_t<ValueT, ValueU>, 2>
fmax_nan(const sycl::vec<ValueT, 2> a, const sycl::vec<ValueU, 2> b) {
  return {fmax_nan(a[0], b[0]), fmax_nan(a[1], b[1])};
}

template <typename ValueT, typename ValueU>
inline sycl::marray<std::common_type_t<ValueT, ValueU>, 2>
fmax_nan(const sycl::marray<ValueT, 2> a, const sycl::marray<ValueU, 2> b) {
  return {fmax_nan(a[0], b[0]), fmax_nan(a[1], b[1])};
}

/// Performs 2 elements comparison and returns the smaller one. If either of
/// inputs is NaN, then return NaN.
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns the smaller value
template <typename ValueT, typename ValueU>
inline std::common_type_t<ValueT, ValueU> fmin_nan(const ValueT a,
                                                   const ValueU b) {
  if (detail::isnan(a) || detail::isnan(b))
    return NAN;
  return compat::min(a,b);
}

template <typename ValueT, typename ValueU>
inline sycl::vec<std::common_type_t<ValueT, ValueU>, 2>
fmin_nan(const sycl::vec<ValueT, 2> a, const sycl::vec<ValueU, 2> b) {
  return {fmin_nan(a[0], b[0]), fmin_nan(a[1], b[1])};
}

template <typename ValueT, typename ValueU>
inline sycl::marray<std::common_type_t<ValueT, ValueU>, 2>
fmin_nan(const sycl::marray<ValueT, 2> a, const sycl::marray<ValueU, 2> b) {
  return {fmin_nan(a[0], b[0]), fmin_nan(a[1], b[1])};
}

// pow functions overload.
inline float pow(const float a, const int b) { return sycl::pown(a, b); }
inline double pow(const double a, const int b) { return sycl::pown(a, b); }

template <typename ValueT, typename ValueU>
inline typename std::enable_if_t<std::is_floating_point_v<ValueT>, ValueT>
pow(const ValueT a, const ValueU b) {
  return sycl::pow(a, static_cast<ValueT>(b));
}
// TODO(compat-lib-reviewers)  calling pow with non-floating point values
// is currently defaulting to double, which fails on devices without
// aspect::fp64. This has to be properly documented, and maybe changed to
// support all devices.
template <typename ValueT, typename ValueU>
inline typename std::enable_if_t<!std::is_floating_point_v<ValueT>, double>
pow(const ValueT a, const ValueU b) {
  return sycl::pow(static_cast<double>(a), static_cast<double>(b));
}

/// Performs relu saturation.
/// \param [in] a The input value
/// \returns the relu saturation result
template <typename ValueT> inline ValueT relu(const ValueT a) {
  if constexpr (compat::is_floating_point_v<ValueT>)
    if (detail::isnan(a))
      return a;
  if (a < ValueT(0))
    return ValueT(0);
  return a;
}
template <class ValueT, int NumElements>
inline sycl::vec<ValueT, NumElements>
relu(const sycl::vec<ValueT, NumElements> a) {
  sycl::vec<ValueT, NumElements> ret;
  for (int i = 0; i < NumElements; ++i)
    ret[i] = relu(a[i]);
  return ret;
}
template <class ValueT>
inline sycl::marray<ValueT, 2> relu(const sycl::marray<ValueT, 2> a) {
  return {relu(a[0]), relu(a[1])};
}

/// Computes the multiplication of two complex numbers.
/// \tparam T Complex element type
/// \param [in] x The first input complex number
/// \param [in] y The second input complex number
/// \returns The result
template <typename T>
sycl::vec<T, 2> cmul(sycl::vec<T, 2> x, sycl::vec<T, 2> y) {
  sycl::ext::oneapi::experimental::complex<T> t1(x[0], x[1]), t2(y[0], y[1]);
  t1 = t1 * t2;
  return sycl::vec<T, 2>(t1.real(), t1.imag());
}

/// Computes the division of two complex numbers.
/// \tparam T Complex element type
/// \param [in] x The first input complex number
/// \param [in] y The second input complex number
/// \returns The result
template <typename T>
sycl::vec<T, 2> cdiv(sycl::vec<T, 2> x, sycl::vec<T, 2> y) {
  sycl::ext::oneapi::experimental::complex<T> t1(x[0], x[1]), t2(y[0], y[1]);
  t1 = t1 / t2;
  return sycl::vec<T, 2>(t1.real(), t1.imag());
}

/// Computes the magnitude of a complex number.
/// \tparam T Complex element type
/// \param [in] x The input complex number
/// \returns The result
template <typename T> T cabs(sycl::vec<T, 2> x) {
  sycl::ext::oneapi::experimental::complex<T> t(x[0], x[1]);
  return sycl::ext::oneapi::experimental::abs(t);
}

/// Computes the complex conjugate of a complex number.
/// \tparam T Complex element type
/// \param [in] x The input complex number
/// \returns The result
template <typename T> sycl::vec<T, 2> conj(sycl::vec<T, 2> x) {
  sycl::ext::oneapi::experimental::complex<T> t(x[0], x[1]);
  t = conj(t);
  return sycl::vec<T, 2>(t.real(), t.imag());
}

/// Performs complex number multiply addition.
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns the operation result
template <typename ValueT>
inline sycl::vec<ValueT, 2> cmul_add(const sycl::vec<ValueT, 2> a,
                                     const sycl::vec<ValueT, 2> b,
                                     const sycl::vec<ValueT, 2> c) {
  sycl::ext::oneapi::experimental::complex<ValueT> t(a[0], a[1]);
  sycl::ext::oneapi::experimental::complex<ValueT> u(b[0], b[1]);
  sycl::ext::oneapi::experimental::complex<ValueT> v(c[0], c[1]);
  t = t * u + v;
  return sycl::vec<ValueT, 2>{t.real(), t.imag()};
}
template <typename ValueT>
inline sycl::marray<ValueT, 2> cmul_add(const sycl::marray<ValueT, 2> a,
                                        const sycl::marray<ValueT, 2> b,
                                        const sycl::marray<ValueT, 2> c) {
  sycl::ext::oneapi::experimental::complex<ValueT> t(a[0], a[1]);
  sycl::ext::oneapi::experimental::complex<ValueT> u(b[0], b[1]);
  sycl::ext::oneapi::experimental::complex<ValueT> v(c[0], c[1]);
  t = t * u + v;
  return sycl::marray<ValueT, 2>{t.real(), t.imag()};
}

/// A sycl::abs wrapper functors.
struct abs {
  template <typename ValueT> auto operator()(const ValueT x) const {
    return sycl::abs(x);
  }
};

/// A sycl::abs_diff wrapper functors.
struct abs_diff {
  template <typename ValueT>
  auto operator()(const ValueT x, const ValueT y) const {
    return sycl::abs_diff(x, y);
  }
};

/// A sycl::add_sat wrapper functors.
struct add_sat {
  template <typename ValueT>
  auto operator()(const ValueT x, const ValueT y) const {
    return sycl::add_sat(x, y);
  }
};

/// A sycl::rhadd wrapper functors.
struct rhadd {
  template <typename ValueT>
  auto operator()(const ValueT x, const ValueT y) const {
    return sycl::rhadd(x, y);
  }
};

/// A sycl::hadd wrapper functors.
struct hadd {
  template <typename ValueT>
  auto operator()(const ValueT x, const ValueT y) const {
    return sycl::hadd(x, y);
  }
};

/// A sycl::max wrapper functors.
struct maximum {
  template <typename ValueT>
  auto operator()(const ValueT x, const ValueT y) const {
    return sycl::max(x, y);
  }
  template <typename ValueT>
  auto operator()(const ValueT x, const ValueT y, bool *pred) const {
    return (x >= y) ? ((*pred = true), x) : ((*pred = false), y);
  }
};

/// A sycl::min wrapper functors.
struct minimum {
  template <typename ValueT>
  auto operator()(const ValueT x, const ValueT y) const {
    return sycl::min(x, y);
  }
  template <typename ValueT>
  auto operator()(const ValueT x, const ValueT y, bool *pred) const {
    return (x <= y) ? ((*pred = true), x) : ((*pred = false), y);
  }
};

/// A sycl::sub_sat wrapper functors.
struct sub_sat {
  template <typename ValueT>
  auto operator()(const ValueT x, const ValueT y) const {
    return sycl::sub_sat(x, y);
  }
};

namespace detail {
struct shift_left {
  template <typename T>
  auto operator()(const T x, const uint32_t offset) const {
    return x << offset;
  }
};

struct shift_right {
  template <typename T>
  auto operator()(const T x, const uint32_t offset) const {
    return x >> offset;
  }
};

struct average {
  template <typename T> auto operator()(const T x, const T y) const {
    return (x + y + (x + y >= 0)) >> 1;
  }
};

} // namespace detail

/// Compute vectorized binary operation value for two/four values, with each
/// treated as a vector type \p VecT.
/// \tparam [in] VecT The type of the vector
/// \tparam [in] BinaryOperation The binary operation class
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] binary_op The operation to do with the two values
/// \param [in] need_relu Whether the result need relu saturation
/// \returns The vectorized binary operation value of the two values
template <typename VecT, class BinaryOperation>
inline unsigned vectorized_binary(unsigned a, unsigned b,
                                  const BinaryOperation binary_op,
                                  [[maybe_unused]] bool need_relu = false) {
  sycl::vec<unsigned, 1> v0{a}, v1{b};
  auto v2 = v0.as<VecT>();
  auto v3 = v1.as<VecT>();
  auto v4 =
      detail::vectorized_binary<VecT, BinaryOperation>()(v2, v3, binary_op);
  if (need_relu)
    v4 = relu(v4);
  v0 = v4.template as<sycl::vec<unsigned, 1>>();
  return v0;
}

/// Compute two vectorized binary operation value with pred for three values,
/// with each value treated as a 2 \p T type elements vector type.
///
/// \tparam [in] VecT The type of the vector
/// \tparam [in] BinaryOperation1 The first binary operation class
/// \tparam [in] BinaryOperation2 The second binary operation class
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] binary_op1 The first operation to do with the first two values
/// \param [in] binary_op2 The second operation to do with the third values
/// \param [in] need_relu Whether the result need relu saturation
/// \returns The two vectorized binary operation value of the three values
template <typename VecT, typename BinaryOperation1, typename BinaryOperation2>
inline unsigned vectorized_ternary(unsigned a, unsigned b, unsigned c,
                                   const BinaryOperation1 binary_op1,
                                   const BinaryOperation2 binary_op2,
                                   bool need_relu = false) {
  const auto v1 = sycl::vec<unsigned, 1>(a).as<VecT>();
  const auto v2 = sycl::vec<unsigned, 1>(b).as<VecT>();
  const auto v3 = sycl::vec<unsigned, 1>(c).as<VecT>();
  auto v4 =
      detail::vectorized_binary<VecT, BinaryOperation1>()(v1, v2, binary_op1);
  v4 = detail::vectorized_binary<VecT, BinaryOperation2>()(v4, v3, binary_op2);
  if (need_relu)
    v4 = relu(v4);
  return v4.template as<sycl::vec<unsigned, 1>>();
}

/// Compute vectorized binary operation value with pred for two values, with
/// each value treated as a 2 \p T type elements vector type.
///
/// \tparam [in] VecT The type of the vector
/// \tparam [in] BinaryOperation The binary operation class
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] binary_op The operation with pred to do with the two values
/// \param [out] pred_hi The pred pointer that pass into high halfword operation
/// \param [out] pred_lo The pred pointer that pass into low halfword operation
/// \returns The vectorized binary operation value of the two values
template <typename VecT, typename BinaryOperation>
inline unsigned vectorized_binary_with_pred(unsigned a, unsigned b,
                                            const BinaryOperation binary_op,
                                            bool *pred_hi, bool *pred_lo) {
  auto v1 = sycl::vec<unsigned, 1>(a).as<VecT>();
  auto v2 = sycl::vec<unsigned, 1>(b).as<VecT>();
  VecT ret;
  ret[0] = binary_op(v1[0], v2[0], pred_lo);
  ret[1] = binary_op(v1[1], v2[1], pred_hi);
  return ret.template as<sycl::vec<unsigned, 1>>();
}

template <typename T1, typename T2>
using dot_product_acc_t =
    std::conditional_t<std::is_unsigned_v<T1> && std::is_unsigned_v<T2>,
                       uint32_t, int32_t>;

namespace detail {

template <typename T> sycl::vec<T, 4> extract_and_sign_or_zero_extend4(T val) {
  return sycl::vec<T, 1>(val)
      .template as<sycl::vec<
          std::conditional_t<std::is_signed_v<T>, int8_t, uint8_t>, 4>>()
      .template convert<T>();
}

template <typename T> sycl::vec<T, 2> extract_and_sign_or_zero_extend2(T val) {
  return sycl::vec<T, 1>(val)
      .template as<sycl::vec<
          std::conditional_t<std::is_signed_v<T>, int16_t, uint16_t>, 2>>()
      .template convert<T>();
}

} // namespace detail

/// Two-way dot product-accumulate. Calculate and return integer_vector2(
/// \param a) dot product integer_vector2(low16_bit( \param b)) + \param c
///
/// \tparam [in] T1 The type of first value.
/// \tparam [in] T2 The type of second value.
/// \param [in] a The first value.
/// \param [in] b The second value.
/// \param [in] c The third value. It has type uint32_t if both T1 and T1 are
/// uint32_t else has type int32_t.
/// \return Two-way 16-bit to 8-bit dot product which is accumulated in 32-bit
/// result.
template <typename T1, typename T2>
inline dot_product_acc_t<T1, T2> dp2a_lo(T1 a, T2 b,
                                         dot_product_acc_t<T1, T2> c) {
  static_assert(detail::is_int32_type<T1> && detail::is_int32_type<T2>,
                "[Compat] dp2a_lo expects 32-bit integers as operands.");
#if defined(__SYCL_DEVICE_ONLY__) && defined(__NVPTX__) &&                     \
    defined(__SYCL_CUDA_ARCH__) && __SYCL_CUDA_ARCH__ >= 610
  dot_product_acc_t<T1, T2> res;
  if constexpr (std::is_signed_v<T1> && std::is_signed_v<T2>) {
    asm volatile("dp2a.lo.s32.s32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"(a), "r"(b), "r"(c));
  } else if constexpr (std::is_signed_v<T1> && std::is_unsigned_v<T2>) {
    asm volatile("dp2a.lo.s32.u32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"(a), "r"(b), "r"(c));
  } else if constexpr (std::is_unsigned_v<T1> && std::is_signed_v<T2>) {
    asm volatile("dp2a.lo.u32.s32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"(a), "r"(b), "r"(c));
  } else {
    asm volatile("dp2a.lo.u32.u32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"(a), "r"(b), "r"(c));
  }
  return res;
#else
  dot_product_acc_t<T1, T2> res = c;
  auto va = detail::extract_and_sign_or_zero_extend2(a);
  auto vb = detail::extract_and_sign_or_zero_extend4(b);
  res += va[0] * vb[0];
  res += va[1] * vb[1];
  return res;
#endif
}

/// Two-way dot product-accumulate. Calculate and return integer_vector2(
/// \param a) dot product integer_vector2(high_16bit( \param b)) + \param c
///
/// \tparam [in] T1 The type of first value.
/// \tparam [in] T2 The type of second value.
/// \param [in] a The first value.
/// \param [in] b The second value.
/// \param [in] c The third value. uint32_t if both T1 and T1 are
/// uint32_t else has type int32_t.
/// \return Two-way 16-bit to 8-bit dot product which is accumulated in 32-bit
/// result.
template <typename T1, typename T2>
inline dot_product_acc_t<T1, T2> dp2a_hi(T1 a, T2 b,
                                         dot_product_acc_t<T1, T2> c) {
  static_assert(detail::is_int32_type<T1> && detail::is_int32_type<T2>,
                "[Compat] dp2a_hi expects 32-bit integers as operands.");
#if defined(__SYCL_DEVICE_ONLY__) && defined(__NVPTX__) &&                     \
    defined(__SYCL_CUDA_ARCH__) && __SYCL_CUDA_ARCH__ >= 610
  dot_product_acc_t<T1, T2> res;
  if constexpr (std::is_signed_v<T1> && std::is_signed_v<T2>) {
    asm volatile("dp2a.hi.s32.s32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"(a), "r"(b), "r"(c));
  } else if constexpr (std::is_signed_v<T1> && std::is_unsigned_v<T2>) {
    asm volatile("dp2a.hi.s32.u32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"(a), "r"(b), "r"(c));
  } else if constexpr (std::is_unsigned_v<T1> && std::is_signed_v<T2>) {
    asm volatile("dp2a.hi.u32.s32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"(a), "r"(b), "r"(c));
  } else {
    asm volatile("dp2a.hi.u32.u32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"(a), "r"(b), "r"(c));
  }
  return res;
#else
  dot_product_acc_t<T1, T2> res = c;
  auto va = detail::extract_and_sign_or_zero_extend2(a);
  auto vb = detail::extract_and_sign_or_zero_extend4(b);
  res += va[0] * vb[2];
  res += va[1] * vb[3];
  return res;
#endif
}

/// Four-way byte dot product-accumulate. Calculate and return integer_vector4(
/// \param a) dot product integer_vector4( \param b)  + \param c
///
/// \tparam [in] T1 The type of first value.
/// \tparam [in] T2 The type of second value.
/// \param [in] a The first value.
/// \param [in] b The second value.
/// \param [in] c The third value. It has type uint32_t if both T1 and T1 are
/// uint32_t else has type int32_t.
/// \return Four-way byte dot product which is accumulated in 32-bit result.
template <typename T1, typename T2>
inline dot_product_acc_t<T1, T2> dp4a(T1 a, T2 b, dot_product_acc_t<T1, T2> c) {
  static_assert(detail::is_int32_type<T1> && detail::is_int32_type<T2>,
                "[Compat] dp4a expects 32-bit integers as operands.");
#if defined(__SYCL_DEVICE_ONLY__) && defined(__NVPTX__) &&                     \
    defined(__SYCL_CUDA_ARCH__) && __SYCL_CUDA_ARCH__ >= 610
  dot_product_acc_t<T1, T2> res;
  if constexpr (std::is_signed_v<T1> && std::is_signed_v<T2>) {
    asm volatile("dp4a.s32.s32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"(a), "r"(b), "r"(c));
  } else if constexpr (std::is_signed_v<T1> && std::is_unsigned_v<T2>) {
    asm volatile("dp4a.s32.u32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"(a), "r"(b), "r"(c));
  } else if constexpr (std::is_unsigned_v<T1> && std::is_signed_v<T2>) {
    asm volatile("dp4a.u32.s32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"(a), "r"(b), "r"(c));
  } else {
    asm volatile("dp4a.u32.u32 %0, %1, %2, %3;"
                 : "=r"(res)
                 : "r"(a), "r"(b), "r"(c));
  }
  return res;
#else
  dot_product_acc_t<T1, T2> res = c;
  auto va = detail::extract_and_sign_or_zero_extend4(a);
  auto vb = detail::extract_and_sign_or_zero_extend4(b);
  res += va[0] * vb[0];
  res += va[1] * vb[1];
  res += va[2] * vb[2];
  res += va[3] * vb[3];
  return res;
#endif
}

/// Extend \p a and \p b to 33 bit and add them.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The extend addition of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_add(AT a, BT b) {
  return detail::extend_binary<RetT, false>(a, b, std::plus());
}

/// Extend Inputs to 33 bit, add \p a, \p b, then do \p second_op with \p c.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \tparam [in] CT The type of the third value
/// \tparam [in] BinaryOperation The type of the second operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] second_op The operation to do with the third value
/// \returns The extend addition of \p a, \p b and \p second_op with \p c
template <typename RetT, typename AT, typename BT, typename CT,
          typename BinaryOperation>
inline constexpr RetT extend_add(AT a, BT b, CT c, BinaryOperation second_op) {
  return detail::extend_binary<RetT, false>(a, b, c, std::plus(), second_op);
}

/// Extend \p a and \p b to 33 bit and add them with saturation.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The extend addition of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_add_sat(AT a, BT b) {
  return detail::extend_binary<RetT, true>(a, b, std::plus());
}

/// Extend Inputs to 33 bit, add \p a, \p b with saturation, then do \p
/// second_op with \p c.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \tparam [in] CT The type of the third value
/// \tparam [in] BinaryOperation The type of the second operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] second_op The operation to do with the third value
/// \returns The extend addition of \p a, \p b with saturation and \p second_op
/// with \p c
template <typename RetT, typename AT, typename BT, typename CT,
          typename BinaryOperation>
inline constexpr RetT extend_add_sat(AT a, BT b, CT c,
                                     BinaryOperation second_op) {
  return detail::extend_binary<RetT, true>(a, b, c, std::plus(), second_op);
}

/// Extend \p a and \p b to 33 bit and minus them.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The extend subtraction of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_sub(AT a, BT b) {
  return detail::extend_binary<RetT, false>(a, b, std::minus());
}

/// Extend Inputs to 33 bit, minus \p a, \p b, then do \p second_op with \p c.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \tparam [in] CT The type of the third value
/// \tparam [in] BinaryOperation The type of the second operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] second_op The operation to do with the third value
/// \returns The extend subtraction of \p a, \p b and \p second_op with \p c
template <typename RetT, typename AT, typename BT, typename CT,
          typename BinaryOperation>
inline constexpr RetT extend_sub(AT a, BT b, CT c, BinaryOperation second_op) {
  return detail::extend_binary<RetT, false>(a, b, c, std::minus(), second_op);
}

/// Extend \p a and \p b to 33 bit and minus them with saturation.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The extend subtraction of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_sub_sat(AT a, BT b) {
  return detail::extend_binary<RetT, true>(a, b, std::minus());
}

/// Extend Inputs to 33 bit, minus \p a, \p b with saturation, then do \p
/// second_op with \p c.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \tparam [in] CT The type of the third value
/// \tparam [in] BinaryOperation The type of the second operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] second_op The operation to do with the third value
/// \returns The extend subtraction of \p a, \p b with saturation and \p
/// second_op with \p c
template <typename RetT, typename AT, typename BT, typename CT,
          typename BinaryOperation>
inline constexpr RetT extend_sub_sat(AT a, BT b, CT c,
                                     BinaryOperation second_op) {
  return detail::extend_binary<RetT, true>(a, b, c, std::minus(), second_op);
}

/// Extend \p a and \p b to 33 bit and do abs_diff.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The extend abs_diff of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_absdiff(AT a, BT b) {
  return detail::extend_binary<RetT, false>(a, b, abs_diff());
}

/// Extend Inputs to 33 bit, abs_diff \p a, \p b, then do \p second_op with \p
/// c.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \tparam [in] CT The type of the third value
/// \tparam [in] BinaryOperation The type of the second operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] second_op The operation to do with the third value
/// \returns The extend abs_diff of \p a, \p b and \p second_op with \p c
template <typename RetT, typename AT, typename BT, typename CT,
          typename BinaryOperation>
inline constexpr RetT extend_absdiff(AT a, BT b, CT c,
                                     BinaryOperation second_op) {
  return detail::extend_binary<RetT, false>(a, b, c, abs_diff(), second_op);
}

/// Extend \p a and \p b to 33 bit and do abs_diff with saturation.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The extend abs_diff of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_absdiff_sat(AT a, BT b) {
  return detail::extend_binary<RetT, true>(a, b, abs_diff());
}

/// Extend Inputs to 33 bit, abs_diff \p a, \p b with saturation, then do \p
/// second_op with \p c.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \tparam [in] CT The type of the third value
/// \tparam [in] BinaryOperation The type of the second operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] second_op The operation to do with the third value
/// \returns The extend abs_diff of \p a, \p b with saturation and \p
/// second_op with \p c
template <typename RetT, typename AT, typename BT, typename CT,
          typename BinaryOperation>
inline constexpr RetT extend_absdiff_sat(AT a, BT b, CT c,
                                         BinaryOperation second_op) {
  return detail::extend_binary<RetT, true>(a, b, c, abs_diff(), second_op);
}

/// Extend \p a and \p b to 33 bit and return smaller one.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The smaller one of the two extended values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_min(AT a, BT b) {
  return detail::extend_binary<RetT, false>(a, b, minimum());
}

/// Extend Inputs to 33 bit, find the smaller one in \p a, \p b, then do \p
/// second_op with \p c.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \tparam [in] CT The type of the third value
/// \tparam [in] BinaryOperation The type of the second operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] second_op The operation to do with the third value
/// \returns The smaller one of \p a, \p b and \p second_op with \p c
template <typename RetT, typename AT, typename BT, typename CT,
          typename BinaryOperation>
inline constexpr RetT extend_min(AT a, BT b, CT c, BinaryOperation second_op) {
  return detail::extend_binary<RetT, false>(a, b, c, minimum(), second_op);
}

/// Extend \p a and \p b to 33 bit and return smaller one with saturation.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The smaller one of the two extended values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_min_sat(AT a, BT b) {
  return detail::extend_binary<RetT, true>(a, b, minimum());
}

/// Extend Inputs to 33 bit, find the smaller one in \p a, \p b with saturation,
/// then do \p second_op with \p c.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \tparam [in] CT The type of the third value
/// \tparam [in] BinaryOperation The type of the second operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] second_op The operation to do with the third value
/// \returns The smaller one of \p a, \p b with saturation and \p
/// second_op with \p c
template <typename RetT, typename AT, typename BT, typename CT,
          typename BinaryOperation>
inline constexpr RetT extend_min_sat(AT a, BT b, CT c,
                                     BinaryOperation second_op) {
  return detail::extend_binary<RetT, true>(a, b, c, minimum(), second_op);
}

/// Extend \p a and \p b to 33 bit and return bigger one.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The bigger one of the two extended values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_max(AT a, BT b) {
  return detail::extend_binary<RetT, false>(a, b, maximum());
}

/// Extend Inputs to 33 bit, find the bigger one in \p a, \p b, then do \p
/// second_op with \p c.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \tparam [in] CT The type of the third value
/// \tparam [in] BinaryOperation The type of the second operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] second_op The operation to do with the third value
/// \returns The bigger one of \p a, \p b and \p second_op with \p c
template <typename RetT, typename AT, typename BT, typename CT,
          typename BinaryOperation>
inline constexpr RetT extend_max(AT a, BT b, CT c, BinaryOperation second_op) {
  return detail::extend_binary<RetT, false>(a, b, c, maximum(), second_op);
}

/// Extend \p a and \p b to 33 bit and return bigger one with saturation.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \param [in] a The first value
/// \param [in] b The second value
/// \returns The bigger one of the two extended values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_max_sat(AT a, BT b) {
  return detail::extend_binary<RetT, true>(a, b, maximum());
}

/// Extend Inputs to 33 bit, find the bigger one in \p a, \p b with saturation,
/// then do \p second_op with \p c.
/// \tparam [in] RetT The type of the return value
/// \tparam [in] AT The type of the first value
/// \tparam [in] BT The type of the second value
/// \tparam [in] CT The type of the third value
/// \tparam [in] BinaryOperation The type of the second operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] second_op The operation to do with the third value
/// \returns The bigger one of \p a, \p b with saturation and \p
/// second_op with \p c
template <typename RetT, typename AT, typename BT, typename CT,
          typename BinaryOperation>
inline constexpr RetT extend_max_sat(AT a, BT b, CT c,
                                     BinaryOperation second_op) {
  return detail::extend_binary<RetT, true>(a, b, c, maximum(), second_op);
}

/// Extend \p a and \p b to 33 bit and return a << clamp(b, 0, 32).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \returns a << clamp(b, 0, 32)
template <typename RetT, typename T>
inline constexpr RetT extend_shl_clamp(T a, uint32_t b) {
  return detail::extend_binary<RetT, false>(a, sycl::clamp(b, 0u, 32u),
                                            detail::shift_left());
}

/// Extend Inputs to 33 bit, and return second_op(a << clamp(b, 0, 32), c).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \param [in] c The value to merge
/// \param [in] second_op The operation to do with the third value
/// \returns second_op(a << clamp(b, 0, 32), c)
template <typename RetT, typename T, typename BinaryOperation>
inline constexpr RetT extend_shl_clamp(T a, uint32_t b, uint32_t c,
                                       BinaryOperation second_op) {
  return detail::extend_binary<RetT, false>(a, sycl::clamp(b, 0u, 32u), c,
                                            detail::shift_left(), second_op);
}

/// Extend \p a and \p b to 33 bit and return sat(a << clamp(b, 0, 32)).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \returns sat(a << clamp(b, 0, 32))
template <typename RetT, typename T>
inline constexpr RetT extend_shl_sat_clamp(T a, uint32_t b) {
  return detail::extend_binary<RetT, true>(a, sycl::clamp(b, 0u, 32u),
                                           detail::shift_left());
}

/// Extend Inputs to 33 bit, and return second_op(sat(a << clamp(b, 0, 32)), c).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \param [in] c The value to merge
/// \param [in] second_op The operation to do with the third value
/// \returns second_op(sat(a << clamp(b, 0, 32)), c)
template <typename RetT, typename T, typename BinaryOperation>
inline constexpr RetT extend_shl_sat_clamp(T a, uint32_t b, uint32_t c,
                                           BinaryOperation second_op) {
  return detail::extend_binary<RetT, true>(a, sycl::clamp(b, 0u, 32u), c,
                                           detail::shift_left(), second_op);
}

/// Extend \p a and \p b to 33 bit and return a << (b & 0x1F).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \returns a << (b & 0x1F)
template <typename RetT, typename T>
inline constexpr RetT extend_shl_wrap(T a, uint32_t b) {
  return detail::extend_binary<RetT, false>(a, b & 0x1F, detail::shift_left());
}

/// Extend Inputs to 33 bit, and return second_op(a << (b & 0x1F), c).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \param [in] c The value to merge
/// \param [in] second_op The operation to do with the third value
/// \returns second_op(a << (b & 0x1F), c)
template <typename RetT, typename T, typename BinaryOperation>
inline constexpr RetT extend_shl_wrap(T a, uint32_t b, uint32_t c,
                                      BinaryOperation second_op) {
  return detail::extend_binary<RetT, false>(a, b & 0x1F, c,
                                            detail::shift_left(), second_op);
}

/// Extend \p a and \p b to 33 bit and return sat(a << (b & 0x1F)).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \returns sat(a << (b & 0x1F))
template <typename RetT, typename T>
inline constexpr RetT extend_shl_sat_wrap(T a, uint32_t b) {
  return detail::extend_binary<RetT, true>(a, b & 0x1F, detail::shift_left());
}

/// Extend Inputs to 33 bit, and return second_op(sat(a << (b & 0x1F)), c).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \param [in] c The value to merge
/// \param [in] second_op The operation to do with the third value
/// \returns second_op(sat(a << (b & 0x1F)), c)
template <typename RetT, typename T, typename BinaryOperation>
inline constexpr RetT extend_shl_sat_wrap(T a, uint32_t b, uint32_t c,
                                          BinaryOperation second_op) {
  return detail::extend_binary<RetT, true>(a, b & 0x1F, c, detail::shift_left(),
                                           second_op);
}

/// Extend \p a and \p b to 33 bit and return a >> clamp(b, 0, 32).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \returns a >> clamp(b, 0, 32)
template <typename RetT, typename T>
inline constexpr RetT extend_shr_clamp(T a, uint32_t b) {
  return detail::extend_binary<RetT, false>(a, sycl::clamp(b, 0u, 32u),
                                            detail::shift_right());
}

/// Extend Inputs to 33 bit, and return second_op(a >> clamp(b, 0, 32), c).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \param [in] c The value to merge
/// \param [in] second_op The operation to do with the third value
/// \returns second_op(a >> clamp(b, 0, 32), c)
template <typename RetT, typename T, typename BinaryOperation>
inline constexpr RetT extend_shr_clamp(T a, uint32_t b, uint32_t c,
                                       BinaryOperation second_op) {
  return detail::extend_binary<RetT, false>(a, sycl::clamp(b, 0u, 32u), c,
                                            detail::shift_right(), second_op);
}

/// Extend \p a and \p b to 33 bit and return sat(a >> clamp(b, 0, 32)).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \returns sat(a >> clamp(b, 0, 32))
template <typename RetT, typename T>
inline constexpr RetT extend_shr_sat_clamp(T a, uint32_t b) {
  return detail::extend_binary<RetT, true>(a, sycl::clamp(b, 0u, 32u),
                                           detail::shift_right());
}

/// Extend Inputs to 33 bit, and return second_op(sat(a >> clamp(b, 0, 32)), c).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \param [in] c The value to merge
/// \param [in] second_op The operation to do with the third value
/// \returns second_op(sat(a >> clamp(b, 0, 32)), c)
template <typename RetT, typename T, typename BinaryOperation>
inline constexpr RetT extend_shr_sat_clamp(T a, uint32_t b, uint32_t c,
                                           BinaryOperation second_op) {
  return detail::extend_binary<RetT, true>(a, sycl::clamp(b, 0u, 32u), c,
                                           detail::shift_right(), second_op);
}

/// Extend \p a and \p b to 33 bit and return a >> (b & 0x1F).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \returns a >> (b & 0x1F)
template <typename RetT, typename T>
inline constexpr RetT extend_shr_wrap(T a, uint32_t b) {
  return detail::extend_binary<RetT, false>(a, b & 0x1F, detail::shift_right());
}

/// Extend Inputs to 33 bit, and return second_op(a >> (b & 0x1F), c).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \param [in] c The value to merge
/// \param [in] second_op The operation to do with the third value
/// \returns second_op(a >> (b & 0x1F), c)
template <typename RetT, typename T, typename BinaryOperation>
inline constexpr RetT extend_shr_wrap(T a, uint32_t b, uint32_t c,
                                      BinaryOperation second_op) {
  return detail::extend_binary<RetT, false>(a, b & 0x1F, c,
                                            detail::shift_right(), second_op);
}

/// Extend \p a and \p b to 33 bit and return sat(a >> (b & 0x1F)).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \returns sat(a >> (b & 0x1F))
template <typename RetT, typename T>
inline constexpr RetT extend_shr_sat_wrap(T a, uint32_t b) {
  return detail::extend_binary<RetT, true>(a, b & 0x1F, detail::shift_right());
}

/// Extend Inputs to 33 bit, and return second_op(sat(a >> (b & 0x1F)), c).
/// \param [in] a The source value
/// \param [in] b The offset to shift
/// \param [in] c The value to merge
/// \param [in] second_op The operation to do with the third value
/// \returns second_op(sat(a >> (b & 0x1F)), c)
template <typename RetT, typename T, typename BinaryOperation>
inline constexpr RetT extend_shr_sat_wrap(T a, uint32_t b, uint32_t c,
                                          BinaryOperation second_op) {
  return detail::extend_binary<RetT, true>(a, b & 0x1F, c,
                                           detail::shift_right(), second_op);
}

/// Compute vectorized addition of \p a and \p b, with each value treated as a
/// 2 elements vector type and extend each element to 17 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized addition of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vadd2(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, false, false>(a, b, c, std::plus());
}

/// Compute vectorized addition of \p a and \p b, with each value treated as a 2
/// elements vector type and extend each element to 17 bit. Then add each half
/// of the result and add with \p c.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The addition of each half of extend vectorized addition of the two
/// values and the third value
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vadd2_add(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, false, true>(a, b, c, std::plus());
}

/// Compute vectorized addition of \p a and \p b with saturation, with each
/// value treated as a 2 elements vector type and extend each element to 17 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized addition of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vadd2_sat(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, true, false>(a, b, c, std::plus());
}

/// Compute vectorized subtraction of \p a and \p b, with each value treated as
/// a 2 elements vector type and extend each element to 17 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized subtraction of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vsub2(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, false, false>(a, b, c, std::minus());
}

/// Compute vectorized subtraction of \p a and \p b, with each value treated as
/// a 2 elements vector type and extend each element to 17 bit. Then add each
/// half of the result and add with \p c.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The addition of each half of extend vectorized subtraction of the
/// two values and the third value
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vsub2_add(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, false, true>(a, b, c, std::minus());
}

/// Compute vectorized subtraction of \p a and \p b with saturation, with each
/// value treated as a 2 elements vector type and extend each element to 17 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized subtraction of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vsub2_sat(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, true, false>(a, b, c, std::minus());
}

/// Compute vectorized abs_diff of \p a and \p b, with each value treated as a 2
/// elements vector type and extend each element to 17 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized abs_diff of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vabsdiff2(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, false, false>(a, b, c, abs_diff());
}

/// Compute vectorized abs_diff of \p a and \p b, with each value treated as a 2
/// elements vector type and extend each element to 17 bit. Then add each half
/// of the result and add with \p c.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The addition of each half of extend vectorized abs_diff of the
/// two values and the third value
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vabsdiff2_add(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, false, true>(a, b, c, abs_diff());
}

/// Compute vectorized abs_diff of \p a and \p b with saturation, with each
/// value treated as a 2 elements vector type and extend each element to 17 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized abs_diff of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vabsdiff2_sat(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, true, false>(a, b, c, abs_diff());
}

/// Compute vectorized minimum of \p a and \p b, with each value treated as a 2
/// elements vector type and extend each element to 17 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized minimum of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vmin2(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, false, false>(a, b, c, minimum());
}

/// Compute vectorized minimum of \p a and \p b, with each value treated as a 2
/// elements vector type and extend each element to 17 bit. Then add each half
/// of the result and add with \p c.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The addition of each half of extend vectorized minimum of the
/// two values and the third value
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vmin2_add(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, false, true>(a, b, c, minimum());
}

/// Compute vectorized minimum of \p a and \p b with saturation, with each value
/// treated as a 2 elements vector type and extend each element to 17 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized minimum of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vmin2_sat(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, true, false>(a, b, c, minimum());
}

/// Compute vectorized maximum of \p a and \p b, with each value treated as a 2
/// elements vector type and extend each element to 17 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized maximum of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vmax2(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, false, false>(a, b, c, maximum());
}

/// Compute vectorized maximum of \p a and \p b, with each value treated as a 2
/// elements vector type and extend each element to 17 bit. Then add each half
/// of the result and add with \p c.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The addition of each half of extend vectorized maximum of the
/// two values and the third value
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vmax2_add(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, false, true>(a, b, c, maximum());
}

/// Compute vectorized maximum of \p a and \p b with saturation, with each value
/// treated as a 2 elements vector type and extend each element to 17 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized maximum of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vmax2_sat(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, true, false>(a, b, c, maximum());
}

/// Compute vectorized average of \p a and \p b, with each value treated as a 2
/// elements vector type and extend each element to 17 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized average of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vavrg2(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, false, false>(a, b, c,
                                                     detail::average());
}

/// Compute vectorized average of \p a and \p b, with each value treated as a 2
/// elements vector type and extend each element to 17 bit. Then add each half
/// of the result and add with \p c.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The addition of each half of extend average maximum of the
/// two values and the third value
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vavrg2_add(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, false, true>(a, b, c, detail::average());
}

/// Compute vectorized average of \p a and \p b with saturation, with each value
/// treated as a 2 elements vector type and extend each element to 17 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized average of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vavrg2_sat(AT a, BT b, RetT c) {
  return detail::extend_vbinary2<RetT, true, false>(a, b, c, detail::average());
}

/// Extend \p a and \p b to 33 bit and vectorized compare input values using
/// specified comparison \p cmp .
///
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \tparam [in] BinaryOperation The type of the compare operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] cmp The comparsion operator
/// \returns The comparison result of the two extended values.
template <typename AT, typename BT, typename BinaryOperation>
inline constexpr unsigned extend_vcompare2(AT a, BT b, BinaryOperation cmp) {
  return detail::extend_vbinary2<unsigned, false, false>(a, b, 0, cmp);
}

/// Extend Inputs to 33 bit, and vectorized compare input values using specified
/// comparison \p cmp , then add the result with \p c .
///
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \tparam [in] BinaryOperation The type of the compare operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] cmp The comparsion operator
/// \returns The comparison result of the two extended values, and add the
/// result with \p c .
template <typename AT, typename BT, typename BinaryOperation>
inline constexpr unsigned extend_vcompare2_add(AT a, BT b, unsigned c,
                                               BinaryOperation cmp) {
  return detail::extend_vbinary2<unsigned, false, true>(a, b, c, cmp);
}

/// Compute vectorized addition of \p a and \p b, with each value treated as a
/// 4 elements vector type and extend each element to 9 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized addition of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vadd4(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, false, false>(a, b, c, std::plus());
}

/// Compute vectorized addition of \p a and \p b, with each value treated as a 4
/// elements vector type and extend each element to 9 bit. Then add each half
/// of the result and add with \p c.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The addition of each half of extend vectorized addition of the two
/// values and the third value
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vadd4_add(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, false, true>(a, b, c, std::plus());
}

/// Compute vectorized addition of \p a and \p b with saturation, with each
/// value treated as a 4 elements vector type and extend each element to 9 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized addition of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vadd4_sat(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, true, false>(a, b, c, std::plus());
}

/// Compute vectorized subtraction of \p a and \p b, with each value treated as
/// a 4 elements vector type and extend each element to 9 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized subtraction of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vsub4(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, false, false>(a, b, c, std::minus());
}

/// Compute vectorized subtraction of \p a and \p b, with each value treated as
/// a 4 elements vector type and extend each element to 9 bit. Then add each
/// half of the result and add with \p c.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The addition of each half of extend vectorized subtraction of the
/// two values and the third value
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vsub4_add(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, false, true>(a, b, c, std::minus());
}

/// Compute vectorized subtraction of \p a and \p b with saturation, with each
/// value treated as a 4 elements vector type and extend each element to 9 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized subtraction of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vsub4_sat(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, true, false>(a, b, c, std::minus());
}

/// Compute vectorized abs_diff of \p a and \p b, with each value treated as a 4
/// elements vector type and extend each element to 9 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized abs_diff of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vabsdiff4(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, false, false>(a, b, c, abs_diff());
}

/// Compute vectorized abs_diff of \p a and \p b, with each value treated as a 4
/// elements vector type and extend each element to 9 bit. Then add each half
/// of the result and add with \p c.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The addition of each half of extend vectorized abs_diff of the
/// two values and the third value
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vabsdiff4_add(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, false, true>(a, b, c, abs_diff());
}

/// Compute vectorized abs_diff of \p a and \p b with saturation, with each
/// value treated as a 4 elements vector type and extend each element to 9 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized abs_diff of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vabsdiff4_sat(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, true, false>(a, b, c, abs_diff());
}

/// Compute vectorized minimum of \p a and \p b, with each value treated as a 4
/// elements vector type and extend each element to 9 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized minimum of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vmin4(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, false, false>(a, b, c, minimum());
}

/// Compute vectorized minimum of \p a and \p b, with each value treated as a 4
/// elements vector type and extend each element to 9 bit. Then add each half
/// of the result and add with \p c.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The addition of each half of extend vectorized minimum of the
/// two values and the third value
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vmin4_add(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, false, true>(a, b, c, minimum());
}

/// Compute vectorized minimum of \p a and \p b with saturation, with each value
/// treated as a 4 elements vector type and extend each element to 9 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized minimum of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vmin4_sat(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, true, false>(a, b, c, minimum());
}

/// Compute vectorized maximum of \p a and \p b, with each value treated as a 4
/// elements vector type and extend each element to 9 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized maximum of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vmax4(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, false, false>(a, b, c, maximum());
}

/// Compute vectorized maximum of \p a and \p b, with each value treated as a 4
/// elements vector type and extend each element to 9 bit. Then add each half
/// of the result and add with \p c.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The addition of each half of extend vectorized maximum of the
/// two values and the third value
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vmax4_add(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, false, true>(a, b, c, maximum());
}

/// Compute vectorized maximum of \p a and \p b with saturation, with each value
/// treated as a 4 elements vector type and extend each element to 9 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized maximum of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vmax4_sat(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, true, false>(a, b, c, maximum());
}

/// Compute vectorized average of \p a and \p b, with each value treated as a 4
/// elements vector type and extend each element to 9 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized average of the two values
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vavrg4(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, false, false>(a, b, c,
                                                     detail::average());
}

/// Compute vectorized average of \p a and \p b, with each value treated as a 4
/// elements vector type and extend each element to 9 bit. Then add each half
/// of the result and add with \p c.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The addition of each half of extend vectorized average of the
/// two values and the third value
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vavrg4_add(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, false, true>(a, b, c, detail::average());
}

/// Compute vectorized average of \p a and \p b with saturation, with each value
/// treated as a 4 elements vector type and extend each element to 9 bit.
/// \tparam [in] RetT The type of the return value, can only be 32 bit integer
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \returns The extend vectorized average of the two values with saturation
template <typename RetT, typename AT, typename BT>
inline constexpr RetT extend_vavrg4_sat(AT a, BT b, RetT c) {
  return detail::extend_vbinary4<RetT, true, false>(a, b, c, detail::average());
}

/// Extend \p a and \p b to 33 bit and vectorized compare input values using
/// specified comparison \p cmp .
///
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \tparam [in] BinaryOperation The type of the compare operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] cmp The comparsion operator
/// \returns The comparison result of the two extended values.
template <typename AT, typename BT, typename BinaryOperation>
inline constexpr unsigned extend_vcompare4(AT a, BT b, BinaryOperation cmp) {
  return detail::extend_vbinary4<unsigned, false, false>(a, b, 0, cmp);
}

/// Extend Inputs to 33 bit, and vectorized compare input values using specified
/// comparison \p cmp , then add the result with \p c .
///
/// \tparam [in] AT The type of the first value, can only be 32 bit integer
/// \tparam [in] BT The type of the second value, can only be 32 bit integer
/// \tparam [in] BinaryOperation The type of the compare operation
/// \param [in] a The first value
/// \param [in] b The second value
/// \param [in] c The third value
/// \param [in] cmp The comparsion operator
/// \returns The comparison result of the two extended values, and add the
/// result with \p c .
template <typename AT, typename BT, typename BinaryOperation>
inline constexpr unsigned extend_vcompare4_add(AT a, BT b, unsigned c,
                                               BinaryOperation cmp) {
  return detail::extend_vbinary4<unsigned, false, true>(a, b, c, cmp);
}

} // namespace compat
