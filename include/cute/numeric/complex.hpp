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
#pragma once

#include <cute/util/type_traits.hpp>

//#if defined(__CUDA_ARCH__)
//#  include <cuda/std/complex>
//#else
//#  include <complex>
//#endif

// Suppress warnings for code in Thrust headers.

#if defined(_MSC_VER)
  // We check for MSVC first, because MSVC also defines __GNUC__.
  // It's common for non-GCC compilers that emulate GCC's behavior
  // to define __GNUC__.
  //
  // thrust/complex.h triggers MSVC's warning on conversion
  // from double to float (or const float) ("possible loss of data").
  // MSVC treats this as an error by default (at least with
  // CUTLASS's default CMake configuration).
#pragma warning( push )
#pragma warning( disable : 4244 )
#elif defined(__GNUC__)
  // With GCC + CUDA 11.4, builds show spurious "-Wconversion"
  // warnings on line 656 of thrust/detail/type_traits.h.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wconversion"
#endif

#if defined(__CUDACC_RTC__)
#include <cuda/std/complex>
#else
#include <thrust/complex.h>
#endif

#if defined(_MSC_VER)
#pragma warning( pop )
#elif defined(__GNUC__)
#pragma GCC diagnostic pop
#endif

#include <cute/config.hpp>

namespace cute
{

//#if defined(__CUDA_ARCH__)
//template <class T>
//using complex = cuda::std::complex<T>;
//#else
//template <class T>
//using complex = std::complex<T>;
//#endif

//template <class T>
//using complex = thrust::complex<T>;

#if defined(__CUDACC_RTC__)
using cuda::std::complex;
#else
using thrust::complex;
#endif

template <class T>
CUTE_HOST_DEVICE
T real(complex<T> const& z) {
  return z.real();
}

template <class T>
CUTE_HOST_DEVICE
T imag(complex<T> const& z) {
  return z.imag();
}

template <class T>
CUTE_HOST_DEVICE
complex<T> conj(complex<T> const& z) {
  return complex<T>(real(z), -imag(z));
}

// cute::conj forwards scalars
template <class T>
CUTE_HOST_DEVICE
T conj(T z) {
  return z;
}

//CUTE_HOST_DEVICE constexpr
//float conj(float z) { return z; }
//CUTE_HOST_DEVICE constexpr
//double conj(double z) { return z; }

/// Fused multiply-add for complex numbers
template <class T>
CUTE_HOST_DEVICE constexpr
void
fma(complex<T>      & d,
    complex<T> const& a,
    complex<T> const& b,
    complex<T> const& c)
{
  d.real(c.real() + a.real() * b.real());
  d.imag(c.imag() + a.real() * b.imag());
  d.real(d.real() - a.imag() * b.imag());
  d.imag(d.imag() + a.imag() * b.real());
}

/// Fused multiply-add for triplets
template <class T>
CUTE_HOST_DEVICE constexpr
void
fma(complex<T> const& a,
    complex<T> const& b,
    complex<T>      & c)
{
  return fma(c, a, b, c);
}

/// Used to determine the real-valued underlying type of a numeric type T
template <class T>
struct RealType {
  using Type = T;
};

/// Partial specialization for complex-valued type
template <class T>
struct RealType<complex<T>> {
  using Type = T;
};

//////////////////////////////////////////////////////////////////////////////////////////////////

template <class T>
struct is_complex {
  static bool const value = false;
};

template <class T>
struct is_complex<complex<T>> {
  static bool const value = true;
};

//////////////////////////////////////////////////////////////////////////////////////////////////
// Display utilities

#if !defined(__CUDACC_RTC__)
template <class T>
CUTE_HOST std::ostream& operator<<(std::ostream& os, complex<T> const& z)
{
  T _r = z.real();
  T _i = z.imag();

  if (bool(_i)) {
    return os << _r << "+i" << _i;
  } else {
    return os << _r;
  }
}
#endif

} // end namespace cute
