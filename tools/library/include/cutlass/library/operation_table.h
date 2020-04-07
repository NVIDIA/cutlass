/***************************************************************************************************
 * Copyright (c) 2020, NVIDIA CORPORATION.  All rights reserved.
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
/*
  \file
  \brief Defines a data structure in which a set of functionally equivalent library::Operation
        instances may be queried.
*/

#pragma once

#include <iosfwd>
#include <unordered_map>
#include <algorithm>

#include "cutlass/library/library.h"
#include "cutlass/library/manifest.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace library {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Tuple uniquely identifying functional behavior
struct GemmFunctionalKey {

  NumericTypeID element_compute;
  NumericTypeID element_scalar;
  NumericTypeID element_A;
  LayoutTypeID layout_A;
  ComplexTransform transform_A;
  NumericTypeID element_B;
  LayoutTypeID layout_B;
  ComplexTransform transform_B;
  NumericTypeID element_C;

  //
  // Methods
  //

  inline
  GemmFunctionalKey(
    NumericTypeID element_compute = NumericTypeID::kF32,
    NumericTypeID element_scalar = NumericTypeID::kF32,
    NumericTypeID element_A = NumericTypeID::kF16,
    LayoutTypeID layout_A = LayoutTypeID::kColumnMajor,
    ComplexTransform transform_A = ComplexTransform::kNone,
    NumericTypeID element_B = NumericTypeID::kF16,
    LayoutTypeID layout_B = LayoutTypeID::kColumnMajor,
    ComplexTransform transform_B = ComplexTransform::kNone,
    NumericTypeID element_C = NumericTypeID::kF16
  ):
    element_compute(element_compute),
    element_scalar(element_scalar),
    element_A(element_A),
    layout_A(layout_A),
    transform_A(transform_A),
    element_B(element_B),
    layout_B(layout_B),
    transform_B(transform_B),
    element_C(element_C)
  { }

  inline
  bool operator==(GemmFunctionalKey const &rhs) const {
    return 
      (element_compute == rhs.element_compute) &&
      (element_scalar == rhs.element_scalar) &&
      (element_A == rhs.element_A) &&
      (layout_A == rhs.layout_A) &&
      (transform_A == rhs.transform_A) &&
      (element_B == rhs.element_B) &&
      (layout_B == rhs.layout_B) &&
      (transform_B == rhs.transform_B) &&
      (element_C == rhs.element_C);
  }

  inline
  bool operator!=(GemmFunctionalKey const &rhs) const {
    return !(*this == rhs);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Hash function for GemmFunctionalKey
struct GemmFunctionalKeyHasher {
  using IntHash = std::hash<int>;

  inline
  static size_t rotl(size_t key, int shl) {
    return (key << shl) | (key >> (sizeof(key)*8 - shl));
  }

  inline
  size_t operator()(GemmFunctionalKey const &key) const {
    IntHash hash;

    return 
      rotl(hash(int(key.element_compute)), 2) ^
      rotl(hash(int(key.element_scalar)), 3) ^
      rotl(hash(int(key.element_A)), 4) ^
      rotl(hash(int(key.layout_A)), 5) ^
      rotl(hash(int(key.transform_A)), 6) ^
      rotl(hash(int(key.element_B)), 7) ^
      rotl(hash(int(key.layout_B)), 8) ^
      rotl(hash(int(key.transform_B)), 9) ^
      rotl(hash(int(key.element_C)), 10);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Establishes a partial ordering to search for GEMM operators
struct GemmPreferenceKey {

  int compute_capability;
  int alignment;

  //
  // Methods
  //

  GemmPreferenceKey(): compute_capability(), alignment() { }

  GemmPreferenceKey(int cc, int alignment): compute_capability(cc), alignment(alignment) { }

  bool operator<(GemmPreferenceKey const &rhs) const {
    return (compute_capability < rhs.compute_capability) || 
      ((compute_capability == rhs.compute_capability) && (alignment < rhs.alignment));
  }

  bool operator==(GemmPreferenceKey const &rhs) const {
    return compute_capability == rhs.compute_capability;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Maps minimum compute capability onto a vector of possible operations
using GemmOperationVectorMap = std::map<
  GemmPreferenceKey,
  std::vector<Operation const *>
>;

/// Maps a GemmFunctionalKey onto a vector of Operation * objects expected to be of kind kGemm
using GemmOperationFunctionalMap = std::unordered_map<
  GemmFunctionalKey,
  GemmOperationVectorMap,
  GemmFunctionalKeyHasher
>;

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Table of cutlass::library::Operation instances
class OperationTable {
public:

  /// Map of all operations of type kGemm and gemm_kind of type kGemm
  GemmOperationFunctionalMap gemm_operations;

  /// Map of all operations of type kGemm and gemm_kind of type kPlanarComplex
  GemmOperationFunctionalMap gemm_planar_complex_operations;
  
  /// Map of all operations of type kGemm and gemm_kind of type kPlanarComplexArray
  GemmOperationFunctionalMap gemm_planar_complex_array_operations;

public:

  void append(Manifest const &manifest);

};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace library
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////

std::ostream & operator<<(std::ostream &out, cutlass::library::GemmFunctionalKey const &k);

