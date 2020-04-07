/***************************************************************************************************
 * Copyright (c) 2017-2019, NVIDIA CORPORATION.  All rights reserved.
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
/* \file
   \brief Helper functions for mapping CUTLASS concepts to cuBLAS.
*/

#include <stdexcept>

#if CUTLASS_ENABLE_CUBLAS
#include "cublas_helpers.h"

namespace cutlass {
namespace profiler {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Converts a cuBLAS status to cutlass::Status
Status get_cutlass_status(cublasStatus_t cublas) {

  switch (cublas) {
    case CUBLAS_STATUS_SUCCESS: 
      return Status::kSuccess;
    case CUBLAS_STATUS_INVALID_VALUE:
      return Status::kErrorInvalidProblem;
    case CUBLAS_STATUS_NOT_SUPPORTED:
      return Status::kErrorNotSupported;
    default: break;
  }
  return Status::kErrorInternal;
}

/// Maps a CUTLASS tensor layout to a cuBLAS transpose operation
cublasOperation_t get_cublas_transpose_operation(library::LayoutTypeID layout) {
  switch (layout) {
    case library::LayoutTypeID::kColumnMajor:
      return CUBLAS_OP_N;
    case library::LayoutTypeID::kRowMajor:
      return CUBLAS_OP_T;
    default: break;
  }
  throw std::runtime_error("CUTLASS layout type does not correspond to cublas type");
}

/// Maps a CUTLASS numeric type to a cuBLAS data type enumeration
bool get_cublas_datatype(cublasDataType_t &data_type, library::NumericTypeID element_type) {
  switch (element_type) {
  case library::NumericTypeID::kF16:
    data_type = CUDA_R_16F;
    return true;
    
  case library::NumericTypeID::kF32:
    data_type = CUDA_R_32F;
    return true;
    
  case library::NumericTypeID::kF64: 
    data_type = CUDA_R_64F;
    return true;
  
  case library::NumericTypeID::kS4: 
    break;
  
  case library::NumericTypeID::kS8: 
    data_type = CUDA_R_8I;
    return true;
    
  case library::NumericTypeID::kS16: 
   break;
 
  case library::NumericTypeID::kS32: 
    data_type = CUDA_R_32I;
    return true;
    
  case library::NumericTypeID::kS64: 
    break;
  
  case library::NumericTypeID::kU4: 
    break;
  
  case library::NumericTypeID::kU8: 
    data_type = CUDA_R_8U;
    return true;
    
  case library::NumericTypeID::kU16: 
    break;
    
  case library::NumericTypeID::kU32: 
    data_type = CUDA_R_32U;
    return true;
    
  case library::NumericTypeID::kU64: 
    break;

  case library::NumericTypeID::kB1: 
    break;
  
  case library::NumericTypeID::kInvalid:
  
  default: 
    break;
  }

  return false;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Gets the cublas algorithm given threadblock tile dimensions and math opcode class
cublasGemmAlgo_t get_cublas_gemm_algo(int cta_m, int cta_n, int cta_k, library::OpcodeClassID opcode_class) {
  // TODO
  return (opcode_class == library::OpcodeClassID::kSimt ? 
    CUBLAS_GEMM_DEFAULT : CUBLAS_GEMM_DEFAULT_TENSOR_OP);
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Returns a status if cuBLAS can satisfy a particular GEMM description
Status cublas_satisfies(library::GemmDescription const &desc) {
  auto const &math_instruction = desc.tile_description.math_instruction;

  if (math_instruction.element_accumulator == library::NumericTypeID::kS32 && 
    math_instruction.opcode_class == library::OpcodeClassID::kTensorOp) {

    return Status::kErrorNotSupported;
  }

  // output type S4 and S8 not supported in cuBLAS
  if (desc.C.element == library::NumericTypeID::kS4 || 
    desc.C.element == library::NumericTypeID::kS8) {

    return Status::kErrorNotSupported;
  }

  return Status::kSuccess;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace profiler
} // namespace cutlass

#endif // #if CUTLASS_ENABLE_CUBLAS
