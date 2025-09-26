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
 *  Compat
 *
 *  dims.hpp
 *
 *  Description:
 *    dim3 functionality for Compat
 **************************************************************************/

#pragma once
#pragma GCC system_header

#include <tuple>

#include <sycl/range.hpp>

namespace compat {

class dim3 {
public:
  unsigned int x, y, z;

  dim3(const sycl::range<3> &r) : x(r[2]), y(r[1]), z(r[0]) {}

  dim3(const sycl::range<2> &r) : x(r[1]), y(r[0]), z(1) {}

  dim3(const sycl::range<1> &r) : x(r[0]), y(1), z(1) {}

  constexpr dim3(unsigned int x = 1, unsigned int y = 1, unsigned int z = 1)
      : x(x), y(y), z(z) {}

  constexpr size_t size() const { return x * y * z; }

  operator sycl::range<3>() const { return sycl::range<3>(z, y, x); }
  operator sycl::range<2>() const {
    if (z != 1)
      throw std::invalid_argument(
          "Attempting to convert a 3D dim3 into sycl::range<2>");
    return sycl::range<2>(y, x);
  }
  operator sycl::range<1>() const {
    if (z != 1 || y != 1)
      throw std::invalid_argument(
          "Attempting to convert a 2D or 3D dim3 into sycl::range<1>");
    return sycl::range<1>(x);
  }
}; // namespace dim3

inline dim3 operator*(const dim3 &a, const dim3 &b) {
  return dim3{a.x * b.x, a.y * b.y, a.z * b.z};
}

inline dim3 operator+(const dim3 &a, const dim3 &b) {
  return dim3{a.x + b.x, a.y + b.y, a.z + b.z};
}

inline dim3 operator-(const dim3 &a, const dim3 &b) {
  return dim3{a.x - b.x, a.y - b.y, a.z - b.z};
}

} // namespace compat
