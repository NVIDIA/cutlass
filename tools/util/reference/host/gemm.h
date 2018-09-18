/***************************************************************************************************
 * Copyright (c) 2017-2018, NVIDIA CORPORATION.  All rights reserved.
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
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Reference implementation for GEMM in host-side code.
*/

#pragma once

#include "cutlass/coord.h"
#include "cutlass/matrix_traits.h"
#include "cutlass/tensor_view.h"
#include "cutlass/gemm/gemm_coord.h"

namespace cutlass {
namespace reference {
namespace host {

////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

/// Template function to compute an inner product.
template <typename Atype, typename Btype, typename Ctype>
Ctype inner_product(Atype a, Btype b, Ctype c) {
  return Ctype(a) * Ctype(b) + c;
}

/// Specialization for matrix multiplication with binary operands
template <>
inline int inner_product<Vector<bin1_t, 32>, Vector<bin1_t, 32>, int>(
    Vector<bin1_t, 32> a,
    Vector<bin1_t, 32> b,
    int c) {

  int accum = 0;
  for (int bit = 0; bit < 32; bit++) {
    accum += a[bit] ^ b[bit];
  }
  return accum + c;
}

/// Specialization for matrix multiplication with signed 4-bit integer operands
template <> inline
int inner_product<Vector<int4_t, 8>, Vector<int4_t, 8>, int>(
    Vector<int4_t, 8> a,
    Vector<int4_t, 8> b,
    int c) {

  int accum = 0;
  for (int k = 0; k < 8; k++) {
    accum += a[k] * b[k];
  }
  return accum + c;
}

/// Specialization for matrix multiplication with unsigned 4-bit integer operands
template <> inline
int inner_product<Vector<uint4_t, 8>, Vector<uint4_t, 8>, int>(
    Vector<uint4_t, 8> a,
    Vector<uint4_t, 8> b,
    int c) {

  int accum = 0;
  for (int k = 0; k < 8; k++) {
    accum += a[k] * b[k];
  }
  return accum + c;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename SrcType, typename DstType>
struct Cast {
  // Default behavior: convert to the destination type
  static inline DstType apply(SrcType src) { return static_cast<DstType>(src); };
};

template <>
struct Cast<float, int8_t> {
  static inline int8_t apply(float src) {
    // Clamp to the range of signed 8-bit integers.
    return static_cast<int8_t>(fmaxf(-128.f, fminf(127.f, src)));
  };
};

template <>
struct Cast<float, uint8_t> {
  static inline uint8_t apply(float src) {
    // Clamp to the range of signed 8-bit integers.
    return static_cast<uint8_t>(fmaxf(0.f, fminf(255.f, src)));
  };
};

} // namespace detail

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Computes a general matrix product among matrices (tensors of rank=2) pointed to by TensorRef
/// objects.
///
/// Explicitly naming types needed by this template can be cumbersome, particularly for the
/// accumulator type, so a function argument 'initial_accum' is exposed. Passing
/// AccumulatorType(0) as the last function argument can be easier than naming all template
/// arguments explicitly.
template <
  typename TensorRefA,
  typename TensorRefB,
  typename TensorRefC,
  typename ScalarType,
  typename AccumulatorType
>
void Gemm(
  gemm::GemmCoord problem_size,
  ScalarType alpha,
  TensorRefA tensor_a,
  TensorRefB tensor_b,
  ScalarType beta,
  TensorRefC tensor_c,
  AccumulatorType initial_accum) {

  typedef typename TensorRefA::Storage AType;
  typedef typename TensorRefB::Storage BType;
  typedef typename TensorRefC::Storage CType;

  static_assert(
    TensorRefA::kRank == 2 &&
    TensorRefB::kRank == 2 &&
    TensorRefC::kRank == 2, "Tensors must be of rank 2");

  // Note: batch is ignored.
  int const M = problem_size.m();
  int const N = problem_size.n();
  int const K = problem_size.k();

  // Blocking necessary to speedup reference implementation
  int const Mblock = 32;
  int const Nblock = 32;

  for (int row_block = 0; row_block < M; row_block += Mblock) {
    for (int col_block = 0; col_block < N; col_block += Nblock) {
      AccumulatorType accum[Mblock][Nblock];

      for (int j = 0; j < Nblock; j++) {
        for (int i = 0; i < Mblock; i++) {
          accum[i][j] = initial_accum;
        }
      }

      for (int k_block = 0; k_block < K; ++k_block) {
        for (int j = 0; j < Nblock; j++) {
          for (int i = 0; i < Mblock; i++) {
            int row = row_block + i;
            int col = col_block + j;

            if (row < M && col < N) {
              AType a = tensor_a.at(MatrixCoord(row, k_block));
              BType b = tensor_b.at(MatrixCoord(k_block, col));

              accum[i][j] = detail::inner_product(a, b, accum[i][j]);
            }
          }
        }
      }

      for (int j = 0; j < Nblock; j++) {
        for (int i = 0; i < Mblock; i++) {
          int row = row_block + i;
          int col = col_block + j;

          MatrixCoord coord = MatrixCoord(row, col);
          if (row < M && col < N) {

            tensor_c.at(coord) = detail::Cast<ScalarType, CType>::apply(
              alpha * ScalarType(accum[i][j]) +
              beta * ScalarType(tensor_c.at(coord)));
          }
        }
      }
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Computes a general matrix product among matrices (tensors of rank=2) pointed to by TensorRef
/// objects.
///
/// This assumes the accumulator type is the same type as the scalars.
template <
  typename TensorRefA,
  typename TensorRefB,
  typename TensorRefC,
  typename ScalarType
>
void Gemm(
  gemm::GemmCoord problem_size,
  ScalarType alpha,
  TensorRefA tensor_a,
  TensorRefB tensor_b,
  ScalarType beta,
  TensorRefC tensor_c) {

  Gemm(problem_size, alpha, tensor_a, tensor_b, beta, tensor_c, ScalarType(0));
}

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Computes a batch of GEMMs over a set of matrices of common dimension.
template <
  typename TensorRefCollectionA,
  typename TensorRefCollectionB,
  typename TensorRefCollectionC,
  typename ScalarType,
  typename AccumulatorType
>
void BatchGemm(
  gemm::GemmCoord problem_size,
  ScalarType alpha,
  TensorRefCollectionA const& tensor_a,
  TensorRefCollectionB const& tensor_b,
  ScalarType beta,
  TensorRefCollectionC &tensor_c,
  AccumulatorType initial_accum = AccumulatorType(0)) {

  typename TensorRefCollectionA::ConstIterator tensor_a_it = tensor_a.begin();
  typename TensorRefCollectionB::ConstIterator tensor_b_it = tensor_b.begin();
  typename TensorRefCollectionC::ConstIterator tensor_c_it = tensor_c.begin();

  for (int batch = 0;
    batch < problem_size.batch();
    ++batch, ++tensor_a_it, ++tensor_b_it, ++tensor_c_it) {

    Gemm(
      problem_size,
      alpha,
      *tensor_a_it,
      *tensor_b_it,
      beta,
      *tensor_c_it,
      initial_accum);
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace host
} // namespace reference
} // namespace cutlass
