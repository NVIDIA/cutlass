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

#include <iosfwd>
#include <complex>

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"
#include "cutlass/complex.h"

#include "cutlass/library/library.h"
#include "cutlass/layout/matrix.h"

namespace cutlass {
namespace library {

/////////////////////////////////////////////////////////////////////////////////////////////////

static struct {
  char const *text;
  char const *pretty;
  OperationKind enumerant;
}
OperationKind_enumerants[] = {
  {"gemm", "Gemm", OperationKind::kGemm},
};

/// Converts a Status enumerant to a string
char const *to_string(OperationKind enumerant, bool pretty) {

  for (auto const & possible : OperationKind_enumerants) {
    if (enumerant == possible.enumerant) {
      if (pretty) {
        return possible.pretty;
      }
      else {
        return possible.text;
      }
    }
  }

  return pretty ? "Invalid" : "invalid";
}

/// Converts a Status enumerant from a string
template <>
OperationKind from_string<OperationKind>(std::string const &str) {

  for (auto const & possible : OperationKind_enumerants) {
    if ((str.compare(possible.text) == 0) ||
        (str.compare(possible.pretty) == 0)) {
      return possible.enumerant;
    }
  }

  return OperationKind::kInvalid;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

static struct {
  char const *text;
  char const *pretty;
  Status enumerant;
}
Status_enumerants[] = {
  {"success", "Success", Status::kSuccess},
  {"misaligned_operand", "Error: misaligned operand", Status::kErrorMisalignedOperand},
  {"invalid_problem", "Error: invalid problem", Status::kErrorInvalidProblem},
  {"not_supported", "Error: not supported", Status::kErrorNotSupported},
  {"internal", "Error: internal", Status::kErrorInternal}
};

/// Converts a Status enumerant to a string
char const *to_string(Status status, bool pretty) {

  for (auto const & possible : Status_enumerants) {
    if (status == possible.enumerant) {
      if (pretty) {
        return possible.pretty;
      }
      else {
        return possible.text;
      }
    }
  }

  return pretty ? "Invalid" : "invalid";
}

/// Converts a Status enumerant from a string
template <>
Status from_string<Status>(std::string const &str) {

  for (auto const & possible : Status_enumerants) {
    if ((str.compare(possible.text) == 0) ||
        (str.compare(possible.pretty) == 0)) {
      return possible.enumerant;
    }
  }

  return Status::kInvalid;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

static struct {
  char const *text;
  char const *pretty;
  NumericTypeID enumerant;
}
NumericTypeID_enumerants[] = {
  {"unknown", "<unkown>", NumericTypeID::kUnknown},
  {"void", "Void", NumericTypeID::kVoid},
  {"b1", "B1", NumericTypeID::kB1},
  {"u4", "U4", NumericTypeID::kU4},
  {"u8", "U8", NumericTypeID::kU8},
  {"u16", "U16", NumericTypeID::kU16},
  {"u32", "U32", NumericTypeID::kU32},
  {"u64", "U64", NumericTypeID::kU64},
  {"s4", "S4", NumericTypeID::kS4},
  {"s8", "S8", NumericTypeID::kS8},
  {"s16", "S16", NumericTypeID::kS16},
  {"s32", "S32", NumericTypeID::kS32},
  {"s64", "S64", NumericTypeID::kS64},
  {"f16", "F16", NumericTypeID::kF16},
  {"f32", "F32", NumericTypeID::kF32},
  {"f64", "F64", NumericTypeID::kF64},
  {"cf16", "CF16", NumericTypeID::kCF16},
  {"cf32", "CF32", NumericTypeID::kCF32},
  {"cf64", "CF64", NumericTypeID::kCF64},
  {"cu4", "CU4", NumericTypeID::kCU4},
  {"cu8", "CU8", NumericTypeID::kCU8},
  {"cu16", "CU16", NumericTypeID::kCU16},
  {"cu32", "CU32", NumericTypeID::kCU32},
  {"cu64", "CU64", NumericTypeID::kCU64},  
  {"cs4", "CS4", NumericTypeID::kCS4},
  {"cs8", "CS8", NumericTypeID::kCS8},
  {"cs16", "CS16", NumericTypeID::kCS16},
  {"cs32", "CS32", NumericTypeID::kCS32},
  {"cs64", "CS64", NumericTypeID::kCS64},
  {"*", "<unkown/enumerate all>", NumericTypeID::kUnknown}
};

/// Converts a NumericTypeID enumerant to a string
char const *to_string(NumericTypeID type, bool pretty) {

  for (auto const & possible : NumericTypeID_enumerants) {
    if (type == possible.enumerant) {
      if (pretty) {
        return possible.pretty;
      }
      else {
        return possible.text;
      }
    }
  }

  return pretty ? "Invalid" : "invalid";
}

/// Parses a NumericTypeID enumerant from a string
template <>
NumericTypeID from_string<NumericTypeID>(std::string const &str) {

  for (auto const & possible : NumericTypeID_enumerants) {
    if ((str.compare(possible.text) == 0) ||
        (str.compare(possible.pretty) == 0)) {
      return possible.enumerant;
    }
  }

  return NumericTypeID::kInvalid;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Returns the size of a data type in bits
int sizeof_bits(NumericTypeID type) {
  switch (type) {
    case NumericTypeID::kF16: return 16;
    case NumericTypeID::kF32: return 32;
    case NumericTypeID::kF64: return 64;
    case NumericTypeID::kS4: return 4;
    case NumericTypeID::kS8: return 8;
    case NumericTypeID::kS16: return 16;
    case NumericTypeID::kS32: return 32;
    case NumericTypeID::kS64: return 64;
    case NumericTypeID::kU4: return 4;
    case NumericTypeID::kU8: return 8;
    case NumericTypeID::kU16: return 16;
    case NumericTypeID::kU32: return 32;
    case NumericTypeID::kU64: return 64;
    case NumericTypeID::kB1:  return 1;
    default: break;
  }
  return 0;
}

/// Returns true if the numeric type is a complex data type or false if real-valued.
bool is_complex_type(NumericTypeID type) {
  switch (type) {
    case NumericTypeID::kCF16: return true;
    case NumericTypeID::kCF32: return true;
    case NumericTypeID::kCF64: return true;
    default: break;
  }
  return false;
}

/// Returns the field underlying a complex valued type
NumericTypeID get_real_type(NumericTypeID type) {
  switch (type) {
    case NumericTypeID::kCF16: return NumericTypeID::kF16;
    case NumericTypeID::kCF32: return NumericTypeID::kF32;
    case NumericTypeID::kCF64: return NumericTypeID::kF64;
    default: break;
  }
  return type;
}

/// Returns true if numeric type is integer
bool is_integer_type(NumericTypeID type) {
  switch (type) {
    case NumericTypeID::kS4: return true;
    case NumericTypeID::kS8: return true;
    case NumericTypeID::kS16: return true;
    case NumericTypeID::kS32: return true;
    case NumericTypeID::kS64: return true;
    case NumericTypeID::kU4: return true;
    case NumericTypeID::kU8: return true;
    case NumericTypeID::kU16: return true;
    case NumericTypeID::kU32: return true;
    case NumericTypeID::kU64: return true;
    default: break;
  }
  return false;
}

/// Returns true if numeric type is signed
bool is_signed_type(NumericTypeID type) {
  switch (type) {
    case NumericTypeID::kF16: return true;
    case NumericTypeID::kF32: return true;
    case NumericTypeID::kF64: return true;
    case NumericTypeID::kS4: return true;
    case NumericTypeID::kS8: return true;
    case NumericTypeID::kS16: return true;
    case NumericTypeID::kS32: return true;
    case NumericTypeID::kS64: return true;
    default: break;
  }
  return false;
}

/// Returns true if numeric type is a signed integer
bool is_signed_integer(NumericTypeID type) {
  return is_integer_type(type) && is_signed_type(type);
}

/// returns true if numeric type is an unsigned integer
bool is_unsigned_integer(NumericTypeID type) {
  return is_integer_type(type) && !is_signed_type(type);
}

/// Returns true if numeric type is floating-point type
bool is_float_type(NumericTypeID type) {
  switch (type) {
  case NumericTypeID::kF16: return true;
  case NumericTypeID::kF32: return true;
  case NumericTypeID::kF64: return true;
  default: break;
  }
  return false;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

static struct {
  LayoutTypeID layout;
  char const *alias;
}
layout_aliases[] = {
  {LayoutTypeID::kUnknown, "unknown"},
  {LayoutTypeID::kRowMajor, "row"},
  {LayoutTypeID::kRowMajor, "t"},
  {LayoutTypeID::kColumnMajor, "column"},
  {LayoutTypeID::kColumnMajor, "col"},
  {LayoutTypeID::kColumnMajor, "n"},
  {LayoutTypeID::kTensorNCHW, "nchw"},
  {LayoutTypeID::kTensorNHWC, "packed_nhwc"},
  {LayoutTypeID::kUnknown, "*"},
  {LayoutTypeID::kInvalid, nullptr}
};

/// Converts a LayoutTypeID enumerant to a string
char const *to_string(LayoutTypeID layout, bool pretty) {
  for (auto const & alias : layout_aliases) {
    if (alias.layout == layout) {
      return alias.alias;
    }
  }
  return pretty ? "Invalid" : "invalid";
}

/// Parses a LayoutTypeID enumerant from a string
template <>
LayoutTypeID from_string<LayoutTypeID>(std::string const &str) {
  for (auto const & alias : layout_aliases) {
    if (str.compare(alias.alias) == 0) {
      return alias.layout;
    }
  }
  return LayoutTypeID::kInvalid;
}

/// Gets stride rank for the layout_id (static function)
int get_layout_stride_rank(LayoutTypeID layout_id) {
  switch (layout_id) {
    case LayoutTypeID::kColumnMajor: return cutlass::layout::ColumnMajor::kStrideRank;
    case LayoutTypeID::kRowMajor:  return cutlass::layout::RowMajor::kStrideRank;
    case LayoutTypeID::kColumnMajorInterleavedK4:
    case LayoutTypeID::kRowMajorInterleavedK4:
    case LayoutTypeID::kColumnMajorInterleavedK16:
    case LayoutTypeID::kRowMajorInterleavedK16: return 1;
    case LayoutTypeID::kTensorNCHW:
    case LayoutTypeID::kTensorNHWC: return 3;
    default : throw std::runtime_error("Unsupported LayoutTypeID in LayoutType::get_stride_rank");
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////

static struct {
  char const *text;
  char const *pretty;
  OpcodeClassID enumerant;
}
OpcodeClassID_enumerants[] = {
  {"simt", "<simt>", OpcodeClassID::kSimt},
  {"tensorop", "<tensorop>", OpcodeClassID::kTensorOp},
  {"wmmatensorop", "<wmmatensorop>", OpcodeClassID::kWmmaTensorOp},
  {"wmma", "<wmma>", OpcodeClassID::kWmmaTensorOp}
};

/// Converts a OpcodeClassID enumerant to a string
char const *to_string(OpcodeClassID type, bool pretty) {

  for (auto const & possible : OpcodeClassID_enumerants) {
    if (type == possible.enumerant) {
      if (pretty) {
        return possible.pretty;
      }
      else {
        return possible.text;
      }
    }
  }

  return pretty ? "Invalid" : "invalid";
}

/// Converts a OpcodeClassID enumerant from a string
template <>
OpcodeClassID from_string<OpcodeClassID>(std::string const &str) {

  for (auto const & possible : OpcodeClassID_enumerants) {
    if ((str.compare(possible.text) == 0) ||
        (str.compare(possible.pretty) == 0)) {
      return possible.enumerant;
    }
  }

  return OpcodeClassID::kInvalid;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Lexical cast a string to a byte array. Returns true if cast is successful or false if invalid.
bool lexical_cast(std::vector<uint8_t> &bytes, NumericTypeID type, std::string const &str) {
  int size_bytes = sizeof_bits(type) / 8;
  if (!size_bytes) {
    return false;
  }

  bytes.resize(size_bytes, 0);

  std::stringstream ss;
  ss << str;

  switch (type) {
  case NumericTypeID::kU8:
  {
    ss >> *reinterpret_cast<uint8_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kU16:
  {
    ss >> *reinterpret_cast<uint16_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kU32:
  {
    ss >> *reinterpret_cast<uint32_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kU64:
  {
    ss >> *reinterpret_cast<uint64_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kS8:
  {
    ss >> *reinterpret_cast<int8_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kS16:
  {
    ss >> *reinterpret_cast<int16_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kS32:
  {
    ss >> *reinterpret_cast<int32_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kS64:
  {
    ss >> *reinterpret_cast<int64_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kF16:
  {
    float tmp;
    ss >> tmp;
    *reinterpret_cast<half_t *>(bytes.data()) = static_cast<half_t>(tmp);
  }
    break;
  case NumericTypeID::kF32:
  {
    ss >> *reinterpret_cast<float *>(bytes.data());
  }
    break;
  case NumericTypeID::kF64:
  {
    ss >> *reinterpret_cast<double *>(bytes.data());
  }
    break;
  case NumericTypeID::kCF16:
  {
    std::complex<float> tmp;
    ss >> tmp;
    cutlass::complex<cutlass::half_t> *x = reinterpret_cast<cutlass::complex<half_t> *>(bytes.data());
    x->real() = static_cast<half_t>(std::real(tmp));
    x->imag() = static_cast<half_t>(std::imag(tmp));
  }
    break;
  case NumericTypeID::kCF32:
  {
    ss >> *reinterpret_cast<std::complex<float>*>(bytes.data());
  }
    break;
  case NumericTypeID::kCF64:
  {
    ss >> *reinterpret_cast<std::complex<double>*>(bytes.data());
  }
    break;
  default:
    return false;
  }

  return true;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

std::string lexical_cast(int64_t int_value) {
  std::stringstream ss;
  ss << int_value;
  return ss.str();
}

/// Lexical cast TO a string FROM a byte array. Returns true if cast is successful or false if invalid.
std::string lexical_cast(std::vector<uint8_t> &bytes, NumericTypeID type) {

  int size_bytes = sizeof_bits(type) / 8;

  if (!size_bytes || size_bytes != bytes.size()) {
    return "<invalid>";
  }

  bytes.resize(size_bytes, 0);

  std::stringstream ss;

  switch (type) {
  case NumericTypeID::kU8:
  {
    ss << *reinterpret_cast<uint8_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kU16:
  {
    ss << *reinterpret_cast<uint16_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kU32:
  {
    ss << *reinterpret_cast<uint32_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kU64:
  {
    ss << *reinterpret_cast<uint64_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kS8:
  {
    ss << *reinterpret_cast<int8_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kS16:
  {
    ss << *reinterpret_cast<int16_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kS32:
  {
    ss << *reinterpret_cast<int32_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kS64:
  {
    ss << *reinterpret_cast<int64_t *>(bytes.data());
  }
    break;
  case NumericTypeID::kF16:
  {
    float tmp = *reinterpret_cast<half_t *>(bytes.data());
    ss << tmp;
  }
    break;
  case NumericTypeID::kF32:
  {
    ss << *reinterpret_cast<float *>(bytes.data());
  }
    break;
  case NumericTypeID::kF64:
  {
    ss << *reinterpret_cast<double *>(bytes.data());
  }
    break;
  case NumericTypeID::kCF16:
  {
    std::complex<float> tmp;
    
    cutlass::complex<half_t> const *x = 
      reinterpret_cast<cutlass::complex<half_t> const *>(bytes.data());

    tmp.real(x->real());
    tmp.imag(x->imag());

    ss << tmp;
  }
    break;
  case NumericTypeID::kCF32:
  {
    ss << *reinterpret_cast<std::complex<float>*>(bytes.data());
  }
    break;
  case NumericTypeID::kCF64:
  {
    ss << *reinterpret_cast<std::complex<double>*>(bytes.data());
  }
    break;
  default:
    return "<unknown>";
  }

  return ss.str();
}

/// Casts from a signed int64 to the destination type. Returns true if successful.
bool cast_from_int64(std::vector<uint8_t> &bytes, NumericTypeID type, int64_t src) {
  int size_bytes = sizeof_bits(type) / 8;
  if (!size_bytes) {
    return false;
  }

  bytes.resize(size_bytes, 0);

  switch (type) {
  case NumericTypeID::kU8:
  {
    *reinterpret_cast<uint8_t *>(bytes.data()) = static_cast<uint8_t>(src);
  }
    break;
  case NumericTypeID::kU16:
  {
    *reinterpret_cast<uint16_t *>(bytes.data()) = static_cast<uint16_t>(src);
  }
    break;
  case NumericTypeID::kU32:
  {
    *reinterpret_cast<uint32_t *>(bytes.data()) = static_cast<uint32_t>(src);
  }
    break;
  case NumericTypeID::kU64:
  {
    *reinterpret_cast<uint64_t *>(bytes.data()) = static_cast<uint64_t>(src);
  }
    break;
  case NumericTypeID::kS8:
  {
    *reinterpret_cast<int8_t *>(bytes.data()) = static_cast<int8_t>(src);
  }
    break;
  case NumericTypeID::kS16:
  {
    *reinterpret_cast<int16_t *>(bytes.data()) = static_cast<int16_t>(src);
  }
    break;
  case NumericTypeID::kS32:
  {
    *reinterpret_cast<int32_t *>(bytes.data()) = static_cast<int32_t>(src);
  }
    break;
  case NumericTypeID::kS64:
  {
    *reinterpret_cast<int64_t *>(bytes.data()) = static_cast<int64_t>(src);
  }
    break;
  case NumericTypeID::kF16:
  {
    *reinterpret_cast<half_t *>(bytes.data()) = static_cast<half_t>(float(src));
  }
    break;
  case NumericTypeID::kF32:
  {
    *reinterpret_cast<float *>(bytes.data()) = static_cast<float>(src);
  }
    break;
  case NumericTypeID::kF64:
  {
    *reinterpret_cast<double *>(bytes.data()) = double(src);
  }
    break;
  case NumericTypeID::kCF16:
  {
    cutlass::complex<cutlass::half_t> *x = reinterpret_cast<cutlass::complex<half_t> *>(bytes.data());
    x->real() = static_cast<half_t>(float(src));
    x->imag() = static_cast<half_t>(float(0));
  }
    break;
  case NumericTypeID::kCF32:
  {
    *reinterpret_cast<std::complex<float>*>(bytes.data()) = std::complex<float>(float(src), float(0));
  }
    break;
  case NumericTypeID::kCF64:
  {
    *reinterpret_cast<std::complex<double>*>(bytes.data()) = std::complex<double>(double(src), double(0));
  }
    break;
  default:
    return false;
  }

  return true;

}

/// Casts from an unsigned int64 to the destination type. Returns true if successful.
bool cast_from_uint64(std::vector<uint8_t> &bytes, NumericTypeID type, uint64_t src) {
  int size_bytes = sizeof_bits(type) / 8;
  if (!size_bytes) {
    return false;
  }

  bytes.resize(size_bytes, 0);

  switch (type) {
  case NumericTypeID::kU8:
  {
    *reinterpret_cast<uint8_t *>(bytes.data()) = static_cast<uint8_t>(src);
  }
    break;
  case NumericTypeID::kU16:
  {
    *reinterpret_cast<uint16_t *>(bytes.data()) = static_cast<uint16_t>(src);
  }
    break;
  case NumericTypeID::kU32:
  {
    *reinterpret_cast<uint32_t *>(bytes.data()) = static_cast<uint32_t>(src);
  }
    break;
  case NumericTypeID::kU64:
  {
    *reinterpret_cast<uint64_t *>(bytes.data()) = static_cast<uint64_t>(src);
  }
    break;
  case NumericTypeID::kS8:
  {
    *reinterpret_cast<int8_t *>(bytes.data()) = static_cast<int8_t>(src);
  }
    break;
  case NumericTypeID::kS16:
  {
    *reinterpret_cast<int16_t *>(bytes.data()) = static_cast<int16_t>(src);
  }
    break;
  case NumericTypeID::kS32:
  {
    *reinterpret_cast<int32_t *>(bytes.data()) = static_cast<int32_t>(src);
  }
    break;
  case NumericTypeID::kS64:
  {
    *reinterpret_cast<int64_t *>(bytes.data()) = static_cast<int64_t>(src);
  }
    break;
  case NumericTypeID::kF16:
  {
    *reinterpret_cast<half_t *>(bytes.data()) = static_cast<half_t>(float(src));
  }
    break;
  case NumericTypeID::kF32:
  {
    *reinterpret_cast<float *>(bytes.data()) = static_cast<float>(src);
  }
    break;
  case NumericTypeID::kF64:
  {
    *reinterpret_cast<double *>(bytes.data()) = double(src);
  }
    break;
  case NumericTypeID::kCF16:
  {
    cutlass::complex<cutlass::half_t> *x = reinterpret_cast<cutlass::complex<half_t> *>(bytes.data());
    x->real() = static_cast<half_t>(float(src));
    x->imag() = static_cast<half_t>(float(0));
  }
    break;
  case NumericTypeID::kCF32:
  {
    *reinterpret_cast<std::complex<float>*>(bytes.data()) = std::complex<float>(float(src), float(0));
  }
    break;
  case NumericTypeID::kCF64:
  {
    *reinterpret_cast<std::complex<double>*>(bytes.data()) = std::complex<double>(double(src), double(0));
  }
    break;
  default:
    return false;
  }

  return true;

}

/// Lexical cast a string to a byte array. Returns true if cast is successful or false if invalid.
bool cast_from_double(std::vector<uint8_t> &bytes, NumericTypeID type, double src) {

  int size_bytes = sizeof_bits(type) / 8;
  if (!size_bytes) {
    return false;
  }

  bytes.resize(size_bytes, 0);

  switch (type) {
  case NumericTypeID::kU8:
  {
    *reinterpret_cast<uint8_t *>(bytes.data()) = static_cast<uint8_t>(src);
  }
    break;
  case NumericTypeID::kU16:
  {
    *reinterpret_cast<uint16_t *>(bytes.data()) = static_cast<uint16_t>(src);
  }
    break;
  case NumericTypeID::kU32:
  {
    *reinterpret_cast<uint32_t *>(bytes.data()) = static_cast<uint32_t>(src);
  }
    break;
  case NumericTypeID::kU64:
  {
    *reinterpret_cast<uint64_t *>(bytes.data()) = static_cast<uint64_t>(src);
  }
    break;
  case NumericTypeID::kS8:
  {
    *reinterpret_cast<int8_t *>(bytes.data()) = static_cast<int8_t>(src);
  }
    break;
  case NumericTypeID::kS16:
  {
    *reinterpret_cast<int16_t *>(bytes.data()) = static_cast<int16_t>(src);
  }
    break;
  case NumericTypeID::kS32:
  {
    *reinterpret_cast<int32_t *>(bytes.data()) = static_cast<int32_t>(src);
  }
    break;
  case NumericTypeID::kS64:
  {
    *reinterpret_cast<int64_t *>(bytes.data()) = static_cast<int64_t>(src);
  }
    break;
  case NumericTypeID::kF16:
  {
    *reinterpret_cast<half_t *>(bytes.data()) = static_cast<half_t>(float(src));
  }
    break;
  case NumericTypeID::kF32:
  {
    *reinterpret_cast<float *>(bytes.data()) = static_cast<float>(src);
  }
    break;
  case NumericTypeID::kF64:
  {
    *reinterpret_cast<double *>(bytes.data()) = src;
  }
    break;
  case NumericTypeID::kCF16:
  {
    cutlass::complex<cutlass::half_t> *x = reinterpret_cast<cutlass::complex<half_t> *>(bytes.data());
    x->real() = static_cast<half_t>(float(src));
    x->imag() = static_cast<half_t>(float(0));
  }
    break;
  case NumericTypeID::kCF32:
  {
    *reinterpret_cast<std::complex<float>*>(bytes.data()) = std::complex<float>(float(src), float(0));
  }
    break;
  case NumericTypeID::kCF64:
  {
    *reinterpret_cast<std::complex<double>*>(bytes.data()) = std::complex<double>(src, double(0));
  }
    break;
  default:
    return false;
  }

  return true;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace library
} // namespace cutlass

///////////////////////////////////////////////////////////////////////////////////////////////////


