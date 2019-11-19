/***************************************************************************************************
 * Copyright (c) 2019, NVIDIA CORPORATION.  All rights reserved.
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
/*! 
  \file

  \brief CUTLASS Library is an object-oriented approach to managing operations implemented by CUTLASS.

  Generally,
    
    description   - compile-time constant parameters used to instantiate an operation

    configuration - runtime parameters with computationally expensive initialization 
    
    arguments     - runtime parameters that may be passed to an initialized operation with low
                    computational overhead
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/complex.h"
#include "cutlass/numeric_types.h"
#include "cutlass/arch/arch.h"
#include "cutlass/arch/mma.h"
#include "cutlass/layout/matrix.h"

#include "cutlass/library/library.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace library {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename T> struct NumericTypeMap;

template <> struct NumericTypeMap<cutlass::int4b_t> {
  static NumericTypeID const kId = NumericTypeID::kS4;
};

template <> struct NumericTypeMap<int8_t> {
  static NumericTypeID const kId = NumericTypeID::kS8;
};

template <> struct NumericTypeMap<int16_t> {
  static NumericTypeID const kId = NumericTypeID::kS16;
};

template <> struct NumericTypeMap<int32_t> {
  static NumericTypeID const kId = NumericTypeID::kS32;
};

template <> struct NumericTypeMap<int64_t> {
  static NumericTypeID const kId = NumericTypeID::kS64;
};

template <> struct NumericTypeMap<cutlass::uint4b_t> {
  static NumericTypeID const kId = NumericTypeID::kU4;
};

template <> struct NumericTypeMap<uint8_t> {
  static NumericTypeID const kId = NumericTypeID::kU8;
};

template <> struct NumericTypeMap<uint16_t> {
  static NumericTypeID const kId = NumericTypeID::kU16;
};

template <> struct NumericTypeMap<uint32_t> {
  static NumericTypeID const kId = NumericTypeID::kU32;
};

template <> struct NumericTypeMap<uint64_t> {
  static NumericTypeID const kId = NumericTypeID::kU64;
};

template <> struct NumericTypeMap<cutlass::half_t> {
  static NumericTypeID const kId = NumericTypeID::kF16;
};

template <> struct NumericTypeMap<float> {
  static NumericTypeID const kId = NumericTypeID::kF32;
};

template <> struct NumericTypeMap<double> {
  static NumericTypeID const kId = NumericTypeID::kF64;
};

template <> struct NumericTypeMap<cutlass::complex<cutlass::half_t> > {
  static NumericTypeID const kId = NumericTypeID::kCF16;
};

template <> struct NumericTypeMap<cutlass::complex<float> > {
  static NumericTypeID const kId = NumericTypeID::kCF32;
};

template <> struct NumericTypeMap<cutlass::complex<double> > {
  static NumericTypeID const kId = NumericTypeID::kCF64;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename T> struct LayoutMap;

template <> struct LayoutMap<cutlass::layout::ColumnMajor> {
  static LayoutTypeID const kId = LayoutTypeID::kColumnMajor;
};

template <> struct LayoutMap<cutlass::layout::RowMajor> {
  static LayoutTypeID const kId = LayoutTypeID::kRowMajor;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename T> struct OpcodeClassMap;

template <> struct OpcodeClassMap<arch::OpClassSimt> {
  static OpcodeClassID const kId = OpcodeClassID::kSimt;
};

template <> struct OpcodeClassMap<arch::OpClassTensorOp> {
  static OpcodeClassID const kId = OpcodeClassID::kTensorOp;
};

template <> struct OpcodeClassMap<arch::OpClassWmmaTensorOp> {
  static OpcodeClassID const kId = OpcodeClassID::kWmmaTensorOp;
};
/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename T> struct ArchMap;

template <> struct ArchMap<arch::Sm50> {
  static int const kMin = 50;
  static int const kMax = 1024;
};

template <> struct ArchMap<arch::Sm60> {
  static int const kMin = 60;
  static int const kMax = 1024;
};

template <> struct ArchMap<arch::Sm61> {
  static int const kMin = 61;
  static int const kMax = 1024;
};

template <> struct ArchMap<arch::Sm70> {
  static int const kMin = 70;
  static int const kMax = 75;
};

template <> struct ArchMap<arch::Sm75> {
  static int const kMin = 75;
  static int const kMax = 1024;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Element, typename Layout>
TensorDescription make_TensorDescription(int alignment = 1) {
  TensorDescription desc;

  desc.element = NumericTypeMap<Element>::kId;
  desc.layout = LayoutMap<Layout>::kId;
  desc.alignment = alignment;
  desc.log_extent_range = int(sizeof(typename Layout::TensorCoord::Index) - 1) * 8;
  desc.log_stride_range = int(sizeof(typename Layout::Stride::Index) - 1) * 8;

  return desc;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace library
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
