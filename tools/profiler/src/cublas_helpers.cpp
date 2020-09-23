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

/// Converts a cuBLASS status to cutlass::profiler::Disposition
Disposition get_cutlass_disposition(cublasStatus_t cublas_status) {

  if (cublas_status == CUBLAS_STATUS_INVALID_VALUE) {
    return Disposition::kInvalidProblem;
  }
  else if (cublas_status == CUBLAS_STATUS_NOT_SUPPORTED) {
    return Disposition::kNotSupported;
  }
  return Disposition::kFailed;
}

/// Maps a CUTLASS tensor layout to a cuBLAS transpose operation
bool get_cublas_transpose_operation(
  cublasOperation_t &operation,
  library::LayoutTypeID layout, 
  library::ComplexTransform transform) {

  switch (layout) {
    case library::LayoutTypeID::kColumnMajor:
      if (transform == library::ComplexTransform::kNone) {
        operation = CUBLAS_OP_N;
        return true;
      }
      else {
        return false;
      }
      break;
    case library::LayoutTypeID::kRowMajor:
      if (transform == library::ComplexTransform::kNone) {
        operation = CUBLAS_OP_T;
        return true;
      }
      else if (transform == library::ComplexTransform::kConjugate) {
        operation = CUBLAS_OP_C;
        return true;
      }
      break;
    default: break;
  }

  return false;
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

  case library::NumericTypeID::kCF32:
    data_type = CUDA_C_32F;
    return true;

  case library::NumericTypeID::kCF64:
    data_type = CUDA_C_64F;
    return true;
  
  case library::NumericTypeID::kInvalid:
  
  default: 
    break;
  }

  return false;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Gets the cublas algorithm given threadblock tile dimensions and math opcode class
cublasGemmAlgo_t get_cublas_gemm_algo(int cta_m, int cta_n, int cta_k, library::OpcodeClassID opcode_class) {
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

namespace detail {

cublasGemmExDispatcher::cublasGemmExDispatcher(
  library::GemmDescription const &op_desc,
  library::GemmUniversalConfiguration configuration_,
  library::GemmUniversalArguments arguments_,
  cublasGemmAlgo_t algorithm
):
  configuration(configuration_), arguments(arguments_), algo(algorithm), status(Status::kSuccess) {

  bool good = true;

  good = (good && get_cublas_transpose_operation(trans_A, op_desc.A.layout, op_desc.transform_A));
  good = (good && get_cublas_transpose_operation(trans_B, op_desc.B.layout, op_desc.transform_B));
  good = (good && get_cublas_datatype(data_type_A, op_desc.A.element));
  good = (good && get_cublas_datatype(data_type_B, op_desc.B.element));
  good = (good && get_cublas_datatype(data_type_C, op_desc.C.element));

  good = (good && get_cublas_datatype(
    compute_data_type,
    op_desc.tile_description.math_instruction.element_accumulator));

  // cuBLAS introduces a separate cublasComputeType enumerant to more precisely describe
  // internal numerical data types used in the computation.
#if (__CUDA_VER_MAJOR__ >= 11)
  library::OpcodeClassID const & opcode_class =
    op_desc.tile_description.math_instruction.opcode_class;

  if (good &&
    op_desc.A.element == library::NumericTypeID::kF32 &&
    op_desc.B.element == library::NumericTypeID::kF32 &&
    opcode_class == library::OpcodeClassID::kTensorOp) {

    compute_type = CUBLAS_COMPUTE_32F_FAST_TF32;
  }
  else if (good) {
    bool const isPedantic = false;
    switch (compute_data_type) {
      case CUDA_R_32F:
      case CUDA_C_32F:
        compute_type = isPedantic ? CUBLAS_COMPUTE_32F_PEDANTIC : CUBLAS_COMPUTE_32F;
        break;
      case CUDA_R_64F:
      case CUDA_C_64F:
        compute_type = isPedantic ? CUBLAS_COMPUTE_64F_PEDANTIC : CUBLAS_COMPUTE_64F;
        break;
      case CUDA_R_16F:
        compute_type = isPedantic ? CUBLAS_COMPUTE_16F_PEDANTIC : CUBLAS_COMPUTE_16F;
        break;
      case CUDA_R_32I:
        compute_type = isPedantic ? CUBLAS_COMPUTE_32I_PEDANTIC : CUBLAS_COMPUTE_32I;
        break;
      default:
        good = false;
        break;
    }
  }
#endif // __CUDA_VER_MAJOR__ >= 11

  if (!good) {
    status = Status::kErrorNotSupported;
  }
}

/// Executes GEMM using these arguments
cublasStatus_t cublasGemmExDispatcher::operator()(cublasHandle_t handle) {

  if (configuration.mode == library::GemmUniversalMode::kBatched) {
    return cublasGemmStridedBatchedEx(
      handle,
      trans_A,
      trans_B,
      configuration.problem_size.m(),
      configuration.problem_size.n(),
      configuration.problem_size.k(),
      arguments.alpha,
      arguments.A,
      data_type_A,
      int(configuration.lda),
      arguments.batch_stride_A,
      arguments.B,
      data_type_B,
      int(configuration.ldb),
      arguments.batch_stride_B,
      arguments.beta,
      arguments.D,
      data_type_C,
      int(configuration.ldc),
      arguments.batch_stride_C,
      configuration.batch_count,
  #if (__CUDA_VER_MAJOR__ >= 11)
      compute_type,
  #else
      compute_data_type,
  #endif
      algo
    );
  }
  else {
    return cublasGemmEx(
      handle,
      trans_A,
      trans_B,
      configuration.problem_size.m(),
      configuration.problem_size.n(),
      configuration.problem_size.k(),
      arguments.alpha,
      arguments.A,
      data_type_A,
      int(configuration.lda),
      arguments.B,
      data_type_B,
      int(configuration.ldb),
      arguments.beta,
      arguments.D,
      data_type_C,
      int(configuration.ldc),
  #if (__CUDA_VER_MAJOR__ >= 11)
      compute_type,
  #else
      compute_data_type,
  #endif
      algo
    );
  }
}

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////
} // namespace profiler
} // namespace cutlass

#endif // #if CUTLASS_ENABLE_CUBLAS
