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

} // namespace profiler
} // namespace cutlass


#endif // #if CUTLASS_ENABLE_CUBLAS
