  /***************************************************************************************************
 * Copyright (c) 2017-2021, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Define basic numeric operators with specializations for Array<T, N>. SIMD-ize where possible.

    This is inspired by the Standard Library's <functional> header.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"
#include "cutlass/complex.h"
#include "cutlass/quaternion.h"
#include "cutlass/array.h"
#include "cutlass/half.h"
#include "cutlass/functional.h"

namespace cutlass {

template <int N>
struct plus<AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)>> {
  CUTLASS_HOST_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const & lhs, AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const &rhs) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;
    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 const *lhs_ptr = reinterpret_cast<__half2 const *>(&lhs);
    __half2 const *rhs_ptr = reinterpret_cast<__half2 const *>(&rhs);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hadd2(lhs_ptr[i], rhs_ptr[i]);
    }

    if (N % 2) {
      __half const *a_residual_ptr = reinterpret_cast<__half const *>(&lhs);
      __half const *b_residual_ptr = reinterpret_cast<__half const *>(&rhs);
      __half d_residual = __hadd(a_residual_ptr[N - 1], b_residual_ptr[N - 1]);

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    #else

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      result[i] = lhs[i] + rhs[i];
    }
    #endif

    return result;
  }

  CUTLASS_HOST_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(half_t const & lhs, AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const &rhs) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;
    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 lhs_pair = __half2half2(reinterpret_cast<__half const &>(lhs));
    __half2 const *rhs_ptr = reinterpret_cast<__half2 const *>(&rhs);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hadd2(lhs_pair, rhs_ptr[i]);
    }

    if (N % 2) {
      __half const *b_residual_ptr = reinterpret_cast<__half const *>(&rhs);
      __half d_residual = __hadd(reinterpret_cast<__half const &>(lhs), b_residual_ptr[N - 1]);

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    #else

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      result[i] = lhs + rhs[i];
    }
    #endif

    return result;
  }

  CUTLASS_HOST_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const & lhs, half_t const &rhs) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;
    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 const *lhs_ptr = reinterpret_cast<__half2 const *>(&lhs);
    __half2 rhs_pair = __half2half2(reinterpret_cast<__half const &>(rhs));

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hadd2(lhs_ptr[i], rhs_pair);
    }

    if (N % 2) {
      __half const *a_residual_ptr = reinterpret_cast<__half const *>(&lhs);
      __half d_residual = __hadd(a_residual_ptr[N - 1], reinterpret_cast<__half const &>(rhs));

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    #else

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      result[i] = lhs[i] + rhs;
    }
    #endif

    return result;
  }
};



template <int N>
struct minus<AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)>> {
  CUTLASS_HOST_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const & lhs, AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const &rhs) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;
    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 const *lhs_ptr = reinterpret_cast<__half2 const *>(&lhs);
    __half2 const *rhs_ptr = reinterpret_cast<__half2 const *>(&rhs);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hsub2(lhs_ptr[i], rhs_ptr[i]);
    }

    if (N % 2) {
      __half const *a_residual_ptr = reinterpret_cast<__half const *>(&lhs);
      __half const *b_residual_ptr = reinterpret_cast<__half const *>(&rhs);
      __half d_residual = __hsub(a_residual_ptr[N - 1], b_residual_ptr[N - 1]);

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    #else

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      result[i] = lhs[i] - rhs[i];
    }
    #endif

    return result;
  }

  CUTLASS_HOST_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(half_t const & lhs, AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const &rhs) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;
    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 lhs_pair = __half2half2(reinterpret_cast<__half const &>(lhs));
    __half2 const *rhs_ptr = reinterpret_cast<__half2 const *>(&rhs);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hsub2(lhs_pair, rhs_ptr[i]);
    }

    if (N % 2) {
      __half const *b_residual_ptr = reinterpret_cast<__half const *>(&rhs);
      __half d_residual = __hsub(reinterpret_cast<__half const &>(lhs), b_residual_ptr[N - 1]);

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    #else

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      result[i] = lhs - rhs[i];
    }
    #endif

    return result;
  }

  CUTLASS_HOST_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const & lhs, half_t const &rhs) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;
    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 const *lhs_ptr = reinterpret_cast<__half2 const *>(&lhs);
    __half2 rhs_pair = __half2half2(reinterpret_cast<__half const &>(rhs));

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hsub2(lhs_ptr[i], rhs_pair);
    }

    if (N % 2) {
      __half const *a_residual_ptr = reinterpret_cast<__half const *>(&lhs);
      __half d_residual = __hsub(a_residual_ptr[N - 1], reinterpret_cast<__half const &>(rhs));

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    #else

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      result[i] = lhs[i] - rhs;
    }
    #endif

    return result;
  }
};

template <int N>
struct multiplies<AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)>> {
  CUTLASS_HOST_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const & lhs, AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const &rhs) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;
    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 const *lhs_ptr = reinterpret_cast<__half2 const *>(&lhs);
    __half2 const *rhs_ptr = reinterpret_cast<__half2 const *>(&rhs);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hmul2(lhs_ptr[i], rhs_ptr[i]);
    }

    if (N % 2) {
      __half const *a_residual_ptr = reinterpret_cast<__half const *>(&lhs);
      __half const *b_residual_ptr = reinterpret_cast<__half const *>(&rhs);
      __half d_residual = __hmul(a_residual_ptr[N - 1], b_residual_ptr[N - 1]);

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    #else

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      result[i] = lhs[i] * rhs[i];
    }
    #endif

    return result;
  }

  CUTLASS_HOST_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(half_t const & lhs, AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const &rhs) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;
    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 lhs_pair = __half2half2(reinterpret_cast<__half const &>(lhs));
    __half2 const *rhs_ptr = reinterpret_cast<__half2 const *>(&rhs);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hmul2(lhs_pair, rhs_ptr[i]);
    }

    if (N % 2) {
      __half const *b_residual_ptr = reinterpret_cast<__half const *>(&rhs);

      __half d_residual = __hmul(
        reinterpret_cast<__half const &>(lhs), 
        b_residual_ptr[N - 1]);

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    #else

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      result[i] = lhs * rhs[i];
    }
    #endif

    return result;
  }

  CUTLASS_HOST_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const & lhs, half_t const &rhs) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;
    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 const *lhs_ptr = reinterpret_cast<__half2 const *>(&lhs);
    __half2 rhs_pair = __half2half2(reinterpret_cast<__half const &>(rhs));

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hmul2(lhs_ptr[i], rhs_pair);
    }

    if (N % 2) {
      __half const *a_residual_ptr = reinterpret_cast<__half const *>(&lhs);

      __half d_residual = __hmul(
        a_residual_ptr[N - 1], 
        reinterpret_cast<__half const &>(rhs));

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    #else

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      result[i] = lhs[i] * rhs;
    }
    #endif

    return result;
  }
};


template <int N>
struct fused_minus_multiply {
  CUTLASS_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const & lhs, half_t const &rhs, half_t const &scalar) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 const *lhs_ptr = reinterpret_cast<__half2 const *>(&lhs);
    __half2 rhs_pair = __half2half2(reinterpret_cast<__half const &>(rhs));
    __half2 scalar_pair = __half2half2(reinterpret_cast<__half const &>(scalar));

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hmul2(__hsub2(lhs_ptr[i], rhs_pair), scalar_pair);
    }

    if (N % 2) {
      __half const *a_residual_ptr = reinterpret_cast<__half const *>(&lhs);
      __half d_residual = __hmul(__hsub(a_residual_ptr[N - 1], reinterpret_cast<__half const &>(rhs) ),\
                                     reinterpret_cast<__half const &>(scalar));

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    return result;
  }
};

template <int N>
struct fused_multiply_add {
  CUTLASS_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const & lhs, \
   AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const &gamma, AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const &beta) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 const *lhs_ptr = reinterpret_cast<__half2 const *>(&lhs);
    __half2 const *gamma_ptr = reinterpret_cast<__half2 const *>(&gamma);
    __half2 const *beta_ptr = reinterpret_cast<__half2 const *>(&beta);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hfma2(lhs_ptr[i], gamma_ptr[i], beta_ptr[i]);
    }

    if (N % 2) {
      __half const *a_residual_ptr = reinterpret_cast<__half const *>(&lhs);
      __half const *gamma_residual_ptr = reinterpret_cast<__half const *>(&gamma);
      __half const *beta_residual_ptr = reinterpret_cast<__half const *>(&beta);
      __half d_residual = __hfma(a_residual_ptr[N - 1],\
                                    gamma_residual_ptr[N - 1], beta_residual_ptr[N - 1]);

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    return result;
  }
};

template <int N>
struct fused_minus_multiply_add2 {
  CUTLASS_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const & lhs, half_t const &rhs,\
   AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const &gamma, AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const &beta) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 const *lhs_ptr = reinterpret_cast<__half2 const *>(&lhs);
    __half2 rhs_pair = __half2half2(reinterpret_cast<__half const &>(rhs));
    __half2 const *gamma_ptr = reinterpret_cast<__half2 const *>(&gamma);
    __half2 const *beta_ptr = reinterpret_cast<__half2 const *>(&beta);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hfma2(__hsub2(lhs_ptr[i], rhs_pair), gamma_ptr[i], beta_ptr[i]);
    }

    if (N % 2) {
      __half const *a_residual_ptr = reinterpret_cast<__half const *>(&lhs);
      __half const *gamma_residual_ptr = reinterpret_cast<__half const *>(&gamma);
      __half const *beta_residual_ptr = reinterpret_cast<__half const *>(&beta);
      __half d_residual = __hfma(__hsub(a_residual_ptr[N - 1], reinterpret_cast<__half const &>(rhs) ),\
                                    gamma_residual_ptr[N - 1], beta_residual_ptr[N - 1]);

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    return result;
  }
};

template <int N>
struct fused_minus_multiply_add {
  CUTLASS_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const & lhs, half_t const &rhs, half_t const &scalar,\
   AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const &gamma, AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const &beta) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 const *lhs_ptr = reinterpret_cast<__half2 const *>(&lhs);
    __half2 rhs_pair = __half2half2(reinterpret_cast<__half const &>(rhs));
    __half2 scalar_pair = __half2half2(reinterpret_cast<__half const &>(scalar));
    __half2 const *gamma_ptr = reinterpret_cast<__half2 const *>(&gamma);
    __half2 const *beta_ptr = reinterpret_cast<__half2 const *>(&beta);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hfma2(__hsub2(lhs_ptr[i], rhs_pair), __hmul2(scalar_pair, gamma_ptr[i]), beta_ptr[i]);
    }

    if (N % 2) {
      __half const *a_residual_ptr = reinterpret_cast<__half const *>(&lhs);
      __half const *gamma_residual_ptr = reinterpret_cast<__half const *>(&gamma);
      __half const *beta_residual_ptr = reinterpret_cast<__half const *>(&beta);
      __half d_residual = __hfma(__hsub(a_residual_ptr[N - 1], reinterpret_cast<__half const &>(rhs) ),\
                                    __hmul(reinterpret_cast<__half const &>(scalar), gamma_residual_ptr[N - 1]), beta_residual_ptr[N - 1]);

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    return result;
  }
};
/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
