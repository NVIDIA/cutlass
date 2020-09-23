/***************************************************************************************************
 * Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
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
    \brief Helpers for printing cutlass/core objects
*/

#pragma once

#include <iostream>
#include <typeinfo>

#include "cutlass/array.h"
#include "cutlass/coord.h"
#include "cutlass/numeric_types.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/layout/pitch_linear.h"
#include "cutlass/tensor_view.h"
#include "cutlass/gemm/gemm.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Output operator for CUDA built-in dim3 type
inline std::ostream &operator<<(std::ostream &out, dim3 d) {
  return out << d.x << ", " << d.y << ", " << d.z;
}

/// Output operator for CUDA built-in error type
inline std::ostream &operator<<(std::ostream &out, cudaError_t error) {
  return out << cudaGetErrorString(error);
}

///////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {

///////////////////////////////////////////////////////////////////////////////////////////////////
//                    stream operators for cutlass namespace                                     //
///////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Element, int Rank>
inline
std::ostream& operator<<(std::ostream& out, Array<Element, Rank> const& v) {
  for (int i = 0; i < Rank; ++i) {
    out << (i ? ", " : "") << v[i];
  }
  return out;
}

template <int Rank>
inline
std::ostream& operator<<(std::ostream& out, Coord<Rank> const& coord) {
  for (int i = 0; i < Rank; ++i) {
    out << (i ? ", " : "") << coord[i];
  }
  return out;
}

inline
std::istream & operator>>(std::istream &stream, half_t &x) {
  float tmp;
  stream >> tmp;
  x = static_cast<cutlass::half_t>(tmp);
  return stream;
}

inline
std::ostream & operator<<(std::ostream &out, half_t const &x) {
  return out << float(x);
}

inline
std::ostream & operator<<(std::ostream &out, bfloat16_t const &x) {
  return out << float(x);
}

inline
std::ostream & operator<<(std::ostream &out, tfloat32_t const &x) {
  return out << float(x);
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to enable formatted printing of CUTLASS scalar types to an ostream
template <typename T>
struct ScalarIO {

  /// Value to print
  T value;

  /// Default ctor
  ScalarIO() { }

  /// Constructs from a value
  ScalarIO(T value): value(value) {}
};

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Default printing to ostream
template <typename T>
inline std::ostream &operator<<(std::ostream &out, ScalarIO<T> const &scalar) {
  return out << scalar.value;
}

/// Printing to ostream of int8_t as integer rather than character
template <>
inline std::ostream &operator<<(std::ostream &out, ScalarIO<int8_t> const &scalar) {
  return out << int(scalar.value);
}

/// Printing to ostream of uint8_t as integer rather than character
template <>
inline std::ostream &operator<<(std::ostream &out, ScalarIO<uint8_t> const &scalar) {
  return out << unsigned(scalar.value);
}


/// Default printing to ostream for MatrixShape
template <int Row, int Column>
inline
std::ostream & operator<<(std::ostream &out, MatrixShape<Row, Column> const &matrix_shape) {
  out << "cutlass::MatrixShape::(kRow, kColumn) {"
    << cutlass::MatrixShape<Row,Column>::kRow <<","
    << cutlass::MatrixShape<Row,Column>::kColumn <<"}";
  return out;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
//                         stream operators for cutlass::gemm namespace                          //
///////////////////////////////////////////////////////////////////////////////////////////////////
namespace gemm {

/// Default printing to ostream for GemmShape
template <int M, int N, int K>
inline
std::ostream & operator<<(std::ostream &out, GemmShape<M,N,K> const &gemm_shape) {
  out << "cutlass::GemmShape::(kM, kN, kK) {"
    << cutlass::gemm::GemmShape<M,N,K>::kM <<","
    << cutlass::gemm::GemmShape<M,N,K>::kN <<","
    << cutlass::gemm::GemmShape<M,N,K>::kK << "}";
  return out;
}

} //namespace gemm
///////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////////////////////
//                       stream operators for cutlass::layout namespace                          //
///////////////////////////////////////////////////////////////////////////////////////////////////
namespace layout {

/// Default printing to ostream for PitchLinearShape
template < int Contiguous, int Strided>
inline
std::ostream & operator<<(std::ostream &out, PitchLinearShape<Contiguous, Strided> const &pitch_linear_shape) {
  out << "cutlass::layout::PitchLinearShape::(kContiguous, kStrided) {"
    << cutlass::layout::PitchLinearShape<Contiguous,Strided>::kContiguous <<","
    << cutlass::layout::PitchLinearShape<Contiguous,Strided>::kStrided <<"}";
  return out;
}

} //namespace layout
///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass
///////////////////////////////////////////////////////////////////////////////////////////////////
