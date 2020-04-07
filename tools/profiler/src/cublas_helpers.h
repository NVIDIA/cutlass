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

#pragma once

#if CUTLASS_ENABLE_CUBLAS
#include <cublas_v2.h>

#include "cutlass/cutlass.h"
#include "cutlass/library/library.h"
#include "options.h"
/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace profiler {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Converts a cuBLAS status to cutlass::Status
Status get_cutlass_status(cublasStatus_t cublas);

/// Maps a CUTLASS tensor layout to a cuBLAS transpose operation
cublasOperation_t get_cublas_transpose_operation(library::LayoutTypeID layout);

/// Maps a CUTLASS numeric type to a cuBLAS data type enumeration
bool get_cublas_datatype(cublasDataType_t &data_type, library::NumericTypeID element_type);

/// Gets the cublas algorithm given threadblock tile dimensions and math opcode class
cublasGemmAlgo_t get_cublas_gemm_algo(
  int cta_m, 
  int cta_n, 
  int cta_k, 
  library::OpcodeClassID opcode_class);

/// Returns a status if cuBLAS can satisfy a particular GEMM description
Status cublas_satisfies(library::GemmDescription const &desc);

/// This is a helper class to create cublasHandle_t automatically on CublasCreate object creation and 
/// to destroy cublasHandle_t on CublasCreate object destruction. 
/// Additionaly, it provides implicit cast from CublasCreate's object to cublasHandle_t's object
class CublasCreate {
private:
	cublasHandle_t handle;
	cublasStatus_t status;

public:
	CublasCreate() {
		status = cublasCreate(&handle);
	}

	~CublasCreate() {
		cublasDestroy(handle);
	}

    /// Implicit cast CublasCreate object to cublasHandle_t
    operator cublasHandle_t() const { return handle; }

    /// returns cublasStatus_t for handle creation
    cublasStatus_t get_cublas_create_status() { return status; }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

/// Selects one or more cuBLAS algorithms.
static void select_cublas_algorithms(
  std::vector<cublasGemmAlgo_t> &algorithms,
  Options const &options, 
  library::GemmDescription const &op_desc) {

  library::OpcodeClassID const & opcode_class = 
    op_desc.tile_description.math_instruction.opcode_class;

  switch (options.library.algorithm_mode) {
    case AlgorithmMode::kMatching:
    {
      algorithms.push_back(get_cublas_gemm_algo(
        op_desc.tile_description.threadblock_shape.m(), 
        op_desc.tile_description.threadblock_shape.n(), 
        op_desc.tile_description.threadblock_shape.k(), 
        opcode_class));
      break;
    }

    case AlgorithmMode::kBest:
    {
      // Choose first enumerated mode. If none are enumerated, choose based on opcode class
      // and evaluate all of them.

      if (options.library.algorithms.empty()) {
        // Enumerate all algorithms
        if (opcode_class == library::OpcodeClassID::kSimt) {
          
          for (int algo = CUBLAS_GEMM_DEFAULT; 
            algo <= CUBLAS_GEMM_ALGO23; 
            ++algo) {

            algorithms.push_back(cublasGemmAlgo_t(algo));
          }
        }
        else {
          
          for (int algo = CUBLAS_GEMM_DEFAULT_TENSOR_OP; 
            algo <= CUBLAS_GEMM_ALGO15_TENSOR_OP; 
            ++algo) {

            algorithms.push_back(cublasGemmAlgo_t(algo));
          }
        }
      }
      else {
        // Use the listed algorithms
        algorithms.reserve(options.library.algorithms.size());

        for (int algo : options.library.algorithms) {
          algorithms.push_back(reinterpret_cast<cublasGemmAlgo_t const &>(algo));
        }
      }

      break;
    }

    case AlgorithmMode::kDefault:
    {

      // Use the library's default algorithm
      algorithms.push_back((opcode_class == library::OpcodeClassID::kSimt ? 
        CUBLAS_GEMM_DEFAULT : CUBLAS_GEMM_DEFAULT_TENSOR_OP)); 

      break;
    }
    default:
    {
      break;
    }
  }
}

/// Dispatcher to cublasGemmEx() 
struct cublasGemmExDispatcher {

  //
  // Data members
  //
  library::GemmConfiguration configuration;
  library::GemmArguments arguments;

  // cublass-specific data structures to fill cublas API call arguments
  cublasOperation_t trans_A;
  cublasOperation_t trans_B;
  cudaDataType_t data_type_A;
  cudaDataType_t data_type_B;
  cudaDataType_t data_type_C;
  cudaDataType_t compute_type;
  cublasGemmAlgo_t algo;
  Status status;
  
  //
  // Methods
  //

  cublasGemmExDispatcher( 
    library::GemmDescription const &op_desc,
    library::GemmConfiguration configuration_,
    library::GemmArguments arguments_,
    cublasGemmAlgo_t algorithm = CUBLAS_GEMM_DFALT
  ):
    configuration(configuration_), arguments(arguments_), algo(algorithm), status(Status::kSuccess) {

    trans_A = get_cublas_transpose_operation(op_desc.A.layout);
    trans_B = get_cublas_transpose_operation(op_desc.B.layout);

    bool good = true;
    good = (good && get_cublas_datatype(data_type_A, op_desc.A.element));
    good = (good && get_cublas_datatype(data_type_B, op_desc.B.element));
    good = (good && get_cublas_datatype(data_type_C, op_desc.C.element));

    good = (good && get_cublas_datatype(
      compute_type, 
      op_desc.tile_description.math_instruction.element_accumulator));

    if (!good) {
      status = Status::kErrorNotSupported;
    }
  }

  /// Executes GEMM using these arguments
  cublasStatus_t operator()(cublasHandle_t handle) {

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
      compute_type,
      algo
    );
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace detail

} // namespace profiler
} // namespace cutlass


#endif // #if CUTLASS_ENABLE_CUBLAS
