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
 *  defs.hpp
 *
 *  Description:
 *    helper aliases and definitions for Compat
 *
 **************************************************************************/

// The original source was under the license below:
//==---- defs.hpp ---------------------------------*- C++ -*----------------==//
//
// Copyright (C) Intel Corporation
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// See https://llvm.org/LICENSE.txt for license information.
//
//===----------------------------------------------------------------------===//

#pragma once
#pragma GCC system_header

#include <iostream>

template <class... Args> class compat_kernel_name;
template <int Arg> class compat_kernel_scalar;

#if defined(_MSC_VER)
#define __compat_align__(n) __declspec(align(n))
#define __compat_inline__ __forceinline
#define __compat_noinline__ __declspec(noinline)
#else
#define __compat_align__(n) __attribute__((aligned(n)))
#define __compat_inline__ __inline__ __attribute__((always_inline))
#define __compat_noinline__ __attribute__((noinline))
#endif

#define COMPAT_COMPATIBILITY_TEMP (900)

#ifdef _WIN32
#define COMPAT_EXPORT __declspec(dllexport)
#else
#define COMPAT_EXPORT
#endif

#define COMPAT_MAJOR_VERSION 0
#define COMPAT_MINOR_VERSION 2
#define COMPAT_PATCH_VERSION 0

#define COMPAT_MAKE_VERSION(_major, _minor, _patch)                        \
  ((1E6 * _major) + (1E3 * _minor) + _patch)

#define COMPAT_VERSION                                                     \
  COMPAT_MAKE_VERSION(COMPAT_MAJOR_VERSION, COMPAT_MINOR_VERSION,  \
                          COMPAT_PATCH_VERSION)

namespace compat {
enum error_code { success = 0, backend_error = 1, default_error = 999 };
/// A dummy function introduced to assist auto migration.
/// The SYCLomatic user should replace it with a real error-handling function.
/// SYCL reports errors using exceptions and does not use error codes.
inline const char *get_error_string_dummy(int ec) {
  (void)ec;
  return "<FIXME: Placeholder>"; // Return the error string for the error code
                                 // ec.
}
} // namespace compat

#define COMPAT_CHECK_ERROR(expr)                                           \
  [&]() {                                                                      \
    try {                                                                      \
      expr;                                                                    \
      return compat::error_code::success;                                  \
    } catch (sycl::exception const &e) {                                       \
      std::cerr << e.what() << std::endl;                                      \
      return compat::error_code::backend_error;                            \
    } catch (std::runtime_error const &e) {                                    \
      std::cerr << e.what() << std::endl;                                      \
      return compat::error_code::default_error;                            \
    }                                                                          \
  }()
