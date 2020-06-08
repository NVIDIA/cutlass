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
    \brief CUTLASS Library handle.
*/
#include <iostream> 
#include <stdexcept>
#include <cstdint>

#include "cutlass/library/handle.h"
#include "cutlass/library/singleton.h"
#include "cutlass/library/util.h"

namespace cutlass {
namespace library {

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Constructor
Handle::Handle(
  cudaStream_t stream, 
  size_t workspace_size
):
  provider_(Provider::kCUTLASS), 
  stream_(stream), 
  workspace_(nullptr), 
  workspace_size_(0), 
  scalar_pointer_mode_(ScalarPointerMode::kHost), 
  last_operation_(nullptr) {

  int device_idx = -1;

  cudaError_t error = cudaGetDevice(&device_idx);
  if (error != cudaSuccess) {
    throw std::runtime_error("cudaGetDevice() failed");
  }

  error = cudaGetDeviceProperties(&device_, device_idx);
  if (error != cudaSuccess) {
    throw std::runtime_error("cudaGetDeviceProperties() failed");
  }

  set_workspace_size(workspace_size);

  Singleton::get();
}

/// Destructor
Handle::~Handle() {
  if (workspace_) {

    if (workspace_) {
      cudaFree(workspace_);
    }

    workspace_ = nullptr;
    workspace_size_ = 0;
  }
}

/// Move constructor
Handle::Handle(Handle && handle) {
  device_ = handle.device_;
  workspace_size_ = handle.workspace_size_;
  workspace_ = handle.workspace_;
  stream_ = handle.stream_;
  scalar_pointer_mode_ = handle.scalar_pointer_mode_;
  
  handle.workspace_ = nullptr;
  handle.workspace_size_ = 0;
}

/// Move assignment operator
Handle & Handle::operator=(Handle && handle) {

  provider_ = handle.provider_;
  device_ = handle.device_;
  workspace_size_ = handle.workspace_size_;
  workspace_ = handle.workspace_;
  stream_ = handle.stream_;
  scalar_pointer_mode_ = handle.scalar_pointer_mode_;

  handle.workspace_ = nullptr;
  handle.workspace_size_ = 0;

  return *this;
}

int Handle::compute_capability() const {
  return device_.major * 10 + device_.minor;
}

/// Sets the current CUDA stream
void Handle::set_stream(cudaStream_t stream) {
  stream_ = stream;
}

/// Gets the current CUDA stream
cudaStream_t Handle::get_stream() const {
  return stream_;
}

/// Gets the current provider
Provider Handle::get_provider() const {
  return provider_;
}

/// Sets the provider of operations
void Handle::set_provider(Provider provider) {
  provider_ = provider;
}

/// Gets the device workspace size
size_t Handle::get_workspace_size() const {
  return workspace_size_;
}

/// Gets a pointer to the device workspace allocation in Global Memory
void *Handle::get_workspace() const {
  return workspace_;
}

/// Sets the size of device workspace, invalidating previous calls to get_device_workspace()
void Handle::set_workspace_size(size_t bytes) {
  if (bytes != workspace_size_) {

    if (workspace_) {
      cudaFree(workspace_);
    }
      
    workspace_ = nullptr;
    workspace_size_ = bytes;

    if (workspace_size_) {
  
      cudaError_t error = cudaMalloc((void **)&workspace_, workspace_size_);
  
      if (error != cudaSuccess) {
        throw std::runtime_error("Failed to allocate workspace");
      }
    }
  }

  if (workspace_) {
    cudaError_t error = cudaMemset(workspace_, 0, workspace_size_);

    if (error != cudaSuccess) {
      throw std::runtime_error("Failed to clear workspace");
    }
  }
}

/// Gets the scalar pointer mode
ScalarPointerMode Handle::get_scalar_pointer_mode() const {
  return scalar_pointer_mode_;
}

/// Sets the scalar pointer mode
void Handle::set_scalar_pointer_mode(ScalarPointerMode mode) {
  scalar_pointer_mode_ = mode;
}

/// Gets the last operation
Operation const *Handle::get_last_operation() const {
  return last_operation_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Returns the maximum required alignment for each operator
static int maximum_alignment_requirement(GemmDescription const &desc) {
  return std::max(
    std::max(desc.A.alignment, desc.B.alignment), desc.C.alignment);
}

/// Returns the largest alignment (in units of elements) the problem satisfies, starting from a
/// given upper limit.
static int gemm_problem_alignment(
  int M,
  int N,
  int K,
  NumericTypeID element_A,
  void const *ptr_A,
  int lda,
  int64_t batch_stride_A,
  NumericTypeID element_B,
  void const *ptr_B,
  int ldb,
  int64_t batch_stride_B,
  NumericTypeID element_C,
  void const * ptr_C,
  int ldc,
  int64_t batch_stride_C,
  void const * ptr_D,
  int ldd,
  int64_t batch_stride_D,
  int max_alignment_in_bytes = 16
) {

  void const *pointers[] = {
    ptr_A, ptr_B, ptr_C, ptr_D
  };

  int64_t extents[] = {
    M, N, K, lda, ldb, ldc, ldd, batch_stride_A, batch_stride_B, batch_stride_C, batch_stride_D
  };

  NumericTypeID elements[] = {
    element_A, element_B, element_C
  };

  for (; max_alignment_in_bytes > 0; max_alignment_in_bytes /= 2) {
    
    bool satisfied = true;

    // Can pointers satisfy this?
    for (void const *ptr : pointers) {
      std::uintptr_t int_ptr = reinterpret_cast<std::uintptr_t>(ptr);

      if (int_ptr % max_alignment_in_bytes) {
        satisfied = false;
        break;
      }
    }

    if (!satisfied) {
      continue;
    }

    // Compute the maximum alignment based on element data types
    int max_element_alignment = 0;

    for (NumericTypeID type_id : elements) {
      int element_alignment = max_alignment_in_bytes * 8 / library::sizeof_bits(type_id); 
      max_element_alignment = std::max(max_element_alignment, element_alignment);
    }

    // Can the problem size and leading dimensions satisfy this?
    for (int64_t extent : extents) {
      if (extent % max_element_alignment) {
        satisfied = false;
        break;
      }
    }

    if (!satisfied) {
      continue;
    }

    // Yes
    return max_element_alignment;
  }

  // No alignment satisfies this problem
  return 0;
}

/// Find the best kernel in descending order of preference.
static Operation const * find_gemm_operation(
  GemmOperationFunctionalMap::const_iterator operators_it, 
  GemmPreferenceKey const preference_key) {

  auto cc_it = operators_it->second.upper_bound(preference_key);

  if (cc_it == operators_it->second.begin()) {
    return nullptr;
  }

  Operation const *operation = nullptr;

  // Search in descending order of compute capability
  do {
    --cc_it;

    // Search tile sizes in order, for now.
    for (auto const * op : cc_it->second) {

      GemmDescription const &desc = static_cast<GemmDescription const &>(op->description());

      int min_cc = desc.tile_description.minimum_compute_capability;
      int max_cc = desc.tile_description.maximum_compute_capability;

      int op_alignment = maximum_alignment_requirement(desc);

      if ((min_cc <= preference_key.compute_capability) &&
        (preference_key.compute_capability <= max_cc) &&
        (op_alignment <= preference_key.alignment)) {

        operation = op;
        break;
      }
    }
  } while (!operation && cc_it != operators_it->second.begin());

  return operation;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Executes a GEMM computation: D <= alpha * A*B + beta * C
Status Handle::gemm(

  int M,                                    /// GEMM M dimension
  int N,                                    /// GEMM N dimension
  int K,                                    /// GEMM K dimension

  NumericTypeID element_compute,            /// Data type of internal accumulation

  NumericTypeID element_scalar,             /// Data type of alpha/beta scalars

  void const *alpha,                        /// Pointer to alpha scalar

  NumericTypeID element_A,                  /// Data type of A matrix elements
  LayoutTypeID layout_A,                    /// Layout of A matrix
  ComplexTransform transform_A,             /// Complex transformation applied to A matrix - ignored for real-valued matrices

  void const * ptr_A,                       /// Pointer to A matrix in Global Memory
  int lda,                                  /// Leading dimension of A matrix

  NumericTypeID element_B,                  /// Data type of B matrix elements
  LayoutTypeID layout_B,                    /// Layout of B matrix
  ComplexTransform transform_B,             /// Complex transformation applied to B matrix - ignored for real-valued matrices

  void const * ptr_B,                       /// Pointer to B matrix in Global Memory
  int ldb,                                  /// Leading dimension of B matrix

  void const * beta,                        /// Pointer to beta scalar

  NumericTypeID element_C,                  /// Data type of C and D matrices

  void const * ptr_C,                       /// Pointer to C matrix
  int ldc,                                  /// Leading dimension of C matrix

  void * ptr_D,                             /// Pointer to D matrix
  int ldd                                   /// Leading dimension of D matrix
) {
  
  //
  // Find the operation
  //

  GemmFunctionalKey key(
    provider_,
    GemmKind::kGemm,
    element_compute,
    element_scalar,
    element_A,
    layout_A,
    transform_A,
    element_B,
    layout_B,
    transform_B,
    element_C
  );

  auto operators_it = Singleton::get().operation_table.gemm_operations.find(key);

  if (operators_it == Singleton::get().operation_table.gemm_operations.end()) {
    return cutlass::Status::kErrorNotSupported;
  }
  
  if (operators_it->second.empty()) {
    return cutlass::Status::kErrorNotSupported;
  }

  //
  // Compute the largest alignment restriction the kernel can satisfy.
  //

  // Maximum alignment expectation among all kernels (in units of bytes)
  int const kMaximumAlignmentSize = 16;

  int alignment = gemm_problem_alignment(
    M, N, K, 
    element_A, ptr_A, lda, 0,
    element_B, ptr_B, ldb, 0,
    element_C, ptr_C, ldc, 0,
    ptr_D, ldd, 0, kMaximumAlignmentSize
  );

  //
  // Find the best kernel in descending order of preference.
  //

  GemmPreferenceKey preference_key(compute_capability(), alignment);

  Operation const *operation = find_gemm_operation(operators_it, preference_key);

  if (!operation) {
    return cutlass::Status::kErrorNotSupported;
  }

  last_operation_ = operation;

  //
  // Configure operation
  //

  GemmConfiguration configuration{
    {M, N, K},
    lda,
    ldb,
    ldc,
    ldd,
    1
  };

  // Query host work space size
  uint64_t host_workspace_size_needed = operation->get_host_workspace_size(&configuration);

  if (uint64_t(kHostWorkspaceSize) < host_workspace_size_needed) {
    return cutlass::Status::kErrorNotSupported;
  }

  char host_workspace[kHostWorkspaceSize];

  // Query device workspace size
  uint64_t device_workspace_size_needed = operation->get_device_workspace_size(&configuration);

  if (uint64_t(workspace_size_) < device_workspace_size_needed) {
    return cutlass::Status::kErrorNotSupported;
  }

  // Initialize host and device workspaces
  Status status = operation->initialize(
    &configuration,
    host_workspace,
    workspace_,
    stream_);

  if (status != cutlass::Status::kSuccess) {
    return status;
  }

  // Run the operator
  GemmArguments arguments{
    ptr_A,
    ptr_B,
    ptr_C,
    ptr_D,
    alpha,
    beta,
    scalar_pointer_mode_
  };

  return operation->run(&arguments, host_workspace, workspace_, stream_);
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Executes a GEMM computation: D <= alpha * A*B + beta * C.
//
// Supports batched-strided, batched array or split-K serial or split-K parallel.
//
Status Handle::gemm_universal(

  GemmUniversalMode mode,                   /// indicates the mode in which the kUniversal GEMM is launched

  int M,                                    /// GEMM M dimension
  int N,                                    /// GEMM N dimension
  int K,                                    /// GEMM K dimension

  NumericTypeID element_compute,            /// Data type of internal accumulation

  NumericTypeID element_scalar,             /// Data type of alpha/beta scalars

  void const *alpha,                        /// Pointer to alpha scalar

  NumericTypeID element_A,                  /// Data type of A matrix elements
  LayoutTypeID layout_A,                    /// Layout of A matrix
  ComplexTransform transform_A,             /// Complex transformation applied to A matrix - ignored for real-valued matrices

  void const * ptr_A,                       /// Pointer to A matrix in Global Memory
  int lda,                                  /// Leading dimension of A matrix

  NumericTypeID element_B,                  /// Data type of B matrix elements
  LayoutTypeID layout_B,                    /// Layout of B matrix
  ComplexTransform transform_B,             /// Complex transformation applied to B matrix - ignored for real-valued matrices

  void const * ptr_B,                       /// Pointer to B matrix in Global Memory
  int ldb,                                  /// Leading dimension of B matrix

  void const * beta,                        /// Pointer to beta scalar

  NumericTypeID element_C,                  /// Data type of C and D matrices

  void const * ptr_C,                       /// Pointer to C matrix
  int ldc,                                  /// Leading dimension of C matrix

  void * ptr_D,                             /// Pointer to D matrix
  int ldd,                                  /// Leading dimension of D matrix

  int batch_count,                          /// Batch count or number of split-K slices

  int64_t batch_stride_A,                   /// Batch stride of A operand
  int64_t batch_stride_B,                   /// Batch stride of B operand
  int64_t batch_stride_C,                   /// Batch stride of C operand
  int64_t batch_stride_D                    /// Batch stride of D operand
) {
  
  //
  // Find the operation
  //

  GemmFunctionalKey key(
    provider_,
    GemmKind::kUniversal,
    element_compute,
    element_scalar,
    element_A,
    layout_A,
    transform_A,
    element_B,
    layout_B,
    transform_B,
    element_C
  );

  auto operators_it = Singleton::get().operation_table.gemm_operations.find(key);

  if (operators_it == Singleton::get().operation_table.gemm_operations.end()) {
    return cutlass::Status::kErrorNotSupported;
  }
  
  if (operators_it->second.empty()) {
    return cutlass::Status::kErrorNotSupported;
  }

  //
  // Compute the largest alignment restriction the kernel can satisfy.
  //

  // Maximum alignment expectation among all kernels (in units of bytes)
  int const kMaximumAlignmentSize = 16;

  void const *ptr_A_check = ptr_A;
  void const *ptr_B_check = ptr_B;
  void const *ptr_C_check = ptr_C;
  void *      ptr_D_check = ptr_D;

  // Ignore alignment of pointers to pointers. We can't check this from the host,
  // as each batch index has its own pointer in device memory.
  if (mode == GemmUniversalMode::kArray) {
    ptr_A_check = nullptr; 
    ptr_B_check = nullptr; 
    ptr_C_check = nullptr; 
    ptr_D_check = nullptr; 
  }

  int alignment = gemm_problem_alignment(
    M, N, K, 
    element_A, ptr_A_check, lda, 0,
    element_B, ptr_B_check, ldb, 0,
    element_C, ptr_C_check, ldc, 0,
    ptr_D_check, ldd, 0, kMaximumAlignmentSize
  );

  //
  // Find the best kernel in descending order of preference.
  //

  GemmPreferenceKey preference_key(compute_capability(), alignment);

  Operation const *operation = find_gemm_operation(operators_it, preference_key);

  if (!operation) {
    return cutlass::Status::kErrorNotSupported;
  }

  last_operation_ = operation;

  //
  // Configure operation
  //

  GemmUniversalConfiguration configuration{
    mode,
    {M, N, K},
    batch_count,
    lda,
    ldb,
    ldc,
    ldd
  };

  // Query host work space size
  uint64_t host_workspace_size_needed = operation->get_host_workspace_size(&configuration);

  if (uint64_t(kHostWorkspaceSize) < host_workspace_size_needed) {
    return cutlass::Status::kErrorNotSupported;
  }

  char host_workspace[kHostWorkspaceSize];

  // Query device workspace size
  uint64_t device_workspace_size_needed = operation->get_device_workspace_size(&configuration);

  if (uint64_t(workspace_size_) < device_workspace_size_needed) {
    return cutlass::Status::kErrorNotSupported;
  }

  // Initialize host and device workspaces
  Status status = operation->initialize(
    &configuration,
    host_workspace,
    workspace_,
    stream_);

  if (status != cutlass::Status::kSuccess) {
    return status;
  }

  // Run the operator
  GemmUniversalArguments arguments{
    ptr_A,
    ptr_B,
    ptr_C,
    ptr_D,
    alpha,
    beta,
    scalar_pointer_mode_,
    batch_stride_A,
    batch_stride_B,
    batch_stride_C,
    batch_stride_D
  };

  return operation->run(&arguments, host_workspace, workspace_, stream_);
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Planar complex GEMM
Status Handle::gemm_planar_complex(

  int M,                                    /// GEMM M dimension
  int N,                                    /// GEMM N dimension
  int K,                                    /// GEMM K dimension

  NumericTypeID element_compute,            /// Data type of internal accumulation

  NumericTypeID element_scalar,             /// Data type of alpha/beta scalars

  void const *alpha,                        /// Pointer to alpha scalar

  NumericTypeID element_A,                  /// Data type of A matrix elements
  LayoutTypeID layout_A,                    /// Layout of A matrix
  ComplexTransform transform_A,             /// Complex transformation applied to A matrix

  void const * ptr_A_real,                  /// Pointer to real part of A matrix
  void const * ptr_A_imag,                  /// Pointer to imaginary part of A matrix
  int lda_real,                             /// Leading dimension of real part of A matrix
  int lda_imag,                             /// Leading dimension of imaginary part of A matrix

  NumericTypeID element_B,                  /// Data type of B matrix elements
  LayoutTypeID layout_B,                    /// Layout of B matrix
  ComplexTransform transform_B,             /// Complex transformation applied to B matrix

  void const * ptr_B_real,                  /// Pointer to real part of B matrix
  void const * ptr_B_imag,                  /// Pointer to imaginary part of B matrix
  int ldb_real,                             /// Leading dimension of real part of B matrix
  int ldb_imag,                             /// Leading dimension of imaginary part of B matrix

  void const * beta,                        /// Pointer to beta scalar

  NumericTypeID element_C,                  /// Data type of C and D matrix

  void const * ptr_C_real,                  /// Pointer to real part of C matrix
  void const * ptr_C_imag,                  /// Pointer to imaginary part of C matrix
  int ldc_real,                             /// Leading dimension of real part of C matrix
  int ldc_imag,                             /// Leading dimension of imaginary part of C matrix

  void * ptr_D_real,                        /// Pointer to real part of D matrix
  void * ptr_D_imag,                        /// Pointer to imaginary part of D matrix
  int ldd_real,                             /// Leading dimension of real part of D matrix
  int ldd_imag,                             /// Leading dimension of imaginary part of D matrix

  int batch_count,                          /// Number of batched GEMMs to execute

  int64_t batch_stride_A_real,
  int64_t batch_stride_A_imag,

  int64_t batch_stride_B_real,
  int64_t batch_stride_B_imag,

  int64_t batch_stride_C_real,
  int64_t batch_stride_C_imag,

  int64_t batch_stride_D_real,
  int64_t batch_stride_D_imag
) {

  //
  // Find the operation
  //

  GemmFunctionalKey key(
    provider_,
    GemmKind::kPlanarComplex,
    element_compute,
    element_scalar,
    element_A,
    layout_A,
    transform_A,
    element_B,
    layout_B,
    transform_B,
    element_C
  );

  auto operators_it = Singleton::get().operation_table.gemm_operations.find(key);

  if (operators_it == Singleton::get().operation_table.gemm_operations.end()) {
    return cutlass::Status::kErrorNotSupported;
  }
  
  if (operators_it->second.empty()) {
    return cutlass::Status::kErrorNotSupported;
  }

  //
  // Compute the largest alignment restriction the kernel can satisfy.
  //

  // Maximum alignment expectation among all kernels (in units of bytes)
  int const kMaximumAlignmentSize = 16;

  int alignment = std::max(
    gemm_problem_alignment(
      M, N, K, 
      element_A, ptr_A_real, lda_real, batch_stride_A_real,
      element_B, ptr_B_real, ldb_real, batch_stride_B_real,
      element_C, ptr_C_real, ldc_real, batch_stride_C_real,
      ptr_D_real, ldd_real, batch_stride_D_real, kMaximumAlignmentSize
    ),
    gemm_problem_alignment(
      M, N, K, 
      element_A, ptr_A_imag, lda_imag, batch_stride_A_imag,
      element_B, ptr_B_imag, ldb_imag, batch_stride_B_imag,
      element_C, ptr_C_imag, ldc_imag, batch_stride_C_imag,
      ptr_D_imag, ldd_imag, batch_stride_D_imag, kMaximumAlignmentSize
    )
  );

  //
  // Find the best kernel in descending order of preference.
  //

  GemmPreferenceKey preference_key(compute_capability(), alignment);

  Operation const *operation = find_gemm_operation(operators_it, preference_key);

  if (!operation) {
    return cutlass::Status::kErrorNotSupported;
  }

  last_operation_ = operation;

  //
  // Configure operation
  //

  GemmPlanarComplexConfiguration configuration{
    GemmUniversalMode::kBatched,
    {M, N, K},
    batch_count,
    lda_real,
    lda_imag,
    ldb_real,
    ldb_imag,
    ldc_real,
    ldc_imag,
    ldd_real,
    ldd_imag
  };

  // Query host work space size
  uint64_t host_workspace_size_needed = operation->get_host_workspace_size(&configuration);

  if (uint64_t(kHostWorkspaceSize) < host_workspace_size_needed) {
    return cutlass::Status::kErrorNotSupported;
  }

  char host_workspace[kHostWorkspaceSize];

  // Query device workspace size
  uint64_t device_workspace_size_needed = operation->get_device_workspace_size(&configuration);

  if (uint64_t(workspace_size_) < device_workspace_size_needed) {
    return cutlass::Status::kErrorNotSupported;
  }

  // Initialize host and device workspaces
  Status status = operation->initialize(
    &configuration,
    host_workspace,
    workspace_,
    stream_);

  if (status != cutlass::Status::kSuccess) {
    return status;
  }

  // Run the operator
  GemmPlanarComplexArguments arguments{
    ptr_A_real,
    ptr_A_imag,
    ptr_B_real,
    ptr_B_imag,
    ptr_C_real,
    ptr_C_imag,
    ptr_D_real,
    ptr_D_imag,
    alpha,
    beta,
    scalar_pointer_mode_,
    batch_stride_A_real,
    batch_stride_A_imag,
    batch_stride_B_real,
    batch_stride_B_imag,
    batch_stride_C_real,
    batch_stride_C_imag,
    batch_stride_D_real,
    batch_stride_D_imag
  };

  return operation->run(&arguments, host_workspace, workspace_, stream_);
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Planar complex batched GEMM loading pointers from arrays in global memory
Status Handle::gemm_planar_complex_array(

  int expected_M,                           /// Expected GEMM M dimension (used for sizing CUDA grid)
  int expected_N,                           /// Expected GEMM N dimension (used for sizing CUDA grid)
  int expected_K,                           /// Expected GEMM K dimension
  int batch_count,                          /// Number of independent GEMM computations to execute

  int const *M,                             /// Array containing the GEMM M dimension for each batch index
  int const *N,                             /// Array containing the GEMM N dimension for each batch index
  int const *K,                             /// Array containing the GEMM K dimension for each batch index

  NumericTypeID element_compute,            /// Data type of internal accumulation

  NumericTypeID element_scalar,             /// Data type of alpha/beta scalars

  void const *alpha,                        /// Pointer to alpha scalar

  NumericTypeID element_A,                  /// Data type of A matrix elements
  LayoutTypeID layout_A,                    /// Layout of A matrix
  ComplexTransform transform_A,             /// Complex transformation applied to A matrix

  void const * const * ptr_A_real,          /// Pointer to array containing pointers to real part of A matrices
  void const * const * ptr_A_imag,          /// Pointer to array containing pointers to imaginary part of A matrices

  int lda_real,                             /// Leading dimension of real part of A matrix
  int lda_imag,                             /// Leading dimension of imaginary part of A matrix

  NumericTypeID element_B,                  /// Data type of B matrix elements
  LayoutTypeID layout_B,                    /// Layout of B matrix
  ComplexTransform transform_B,             /// Complex transformation applied to B matrix

  void const * const * ptr_B_real,          /// Pointer to array containing pointers to real part of B matrices
  void const * const * ptr_B_imag,          /// Pointer to array containing pointers to imaginary part of B matrices

  int ldb_real,                             /// Leading dimension of real part of B matrix
  int ldb_imag,                             /// Leading dimension of imaginary part of B matrix

  void const * beta,                        /// Pointer to beta scalar

  NumericTypeID element_C,                  /// Data type of C and D matrix

  void const * const * ptr_C_real,          /// Pointer to array containing pointers to real part of C matrices
  void const * const * ptr_C_imag,          /// Pointer to array containing poitners to imaginary part of C matrices

  int ldc_real,                             /// Leading dimension of real part of C matrix
  int ldc_imag,                             /// Leading dimension of imaginary part of C matrix

  void * const * ptr_D_real,                /// Pointer to array containing pointers to real part of D matrices
  void * const * ptr_D_imag,                /// Pointer to array containing poitners to imaginary part of D matrices

  int ldd_real,                             /// Leading dimension of real part of D matrix
  int ldd_imag                              /// Leading dimension of imaginary part of D matrix
) {
  
  //
  // Find the operation
  //

  GemmFunctionalKey key(
    provider_,
    GemmKind::kPlanarComplexArray,
    element_compute,
    element_scalar,
    element_A,
    layout_A,
    transform_A,
    element_B,
    layout_B,
    transform_B,
    element_C
  );

  auto operators_it = Singleton::get().operation_table.gemm_operations.find(key);

  if (operators_it == Singleton::get().operation_table.gemm_operations.end()) {
    return cutlass::Status::kErrorNotSupported;
  }
  
  if (operators_it->second.empty()) {
    return cutlass::Status::kErrorNotSupported;
  }

  //
  // Compute the largest alignment restriction the kernel can satisfy.
  //

  // Maximum alignment expectation among all kernels (in units of bytes)
  int const kMaximumAlignmentSize = 16;

  int alignment = std::max(
    gemm_problem_alignment(
      expected_M, expected_N, expected_K, 
      element_A, nullptr, lda_real, 0,
      element_B, nullptr, ldb_real, 0,
      element_C, nullptr, ldc_real, 0,
      nullptr, ldd_real, 0, kMaximumAlignmentSize
    ),
    gemm_problem_alignment(
      expected_M, expected_N, expected_K, 
      element_A, nullptr, lda_imag, 0,
      element_B, nullptr, ldb_imag, 0,
      element_C, nullptr, ldc_imag, 0,
      nullptr, ldd_imag, 0, kMaximumAlignmentSize
    )
  );

  //
  // Find the best kernel in descending order of preference.
  //

  GemmPreferenceKey preference_key(compute_capability(), alignment);

  Operation const *operation = find_gemm_operation(operators_it, preference_key);

  if (!operation) {
    return cutlass::Status::kErrorNotSupported;
  }

  last_operation_ = operation;

  //
  // Configure operation
  //

  GemmPlanarComplexArrayConfiguration configuration{
    {expected_M, expected_N, expected_K},
    batch_count,
    lda_real,
    lda_imag,
    ldb_real,
    ldb_imag,
    ldc_real,
    ldc_imag,
    ldd_real,
    ldd_imag
  };

  // Query host work space size
  uint64_t host_workspace_size_needed = operation->get_host_workspace_size(&configuration);

  if (uint64_t(kHostWorkspaceSize) < host_workspace_size_needed) {
    return cutlass::Status::kErrorNotSupported;
  }

  char host_workspace[kHostWorkspaceSize];

  // Query device workspace size
  uint64_t device_workspace_size_needed = operation->get_device_workspace_size(&configuration);

  if (uint64_t(workspace_size_) < device_workspace_size_needed) {
    return cutlass::Status::kErrorNotSupported;
  }

  // Initialize host and device workspaces
  Status status = operation->initialize(
    &configuration,
    host_workspace,
    workspace_,
    stream_);

  if (status != cutlass::Status::kSuccess) {
    return status;
  }

  // Run the operator
  GemmPlanarComplexArrayArguments arguments{
    M, N, K,
    ptr_A_real,
    ptr_A_imag,
    ptr_B_real,
    ptr_B_imag,
    ptr_C_real,
    ptr_C_imag,
    ptr_D_real,
    ptr_D_imag,
    alpha,
    beta,
    scalar_pointer_mode_
  };

  return operation->run(&arguments, host_workspace, workspace_, stream_);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
} // namespace library
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////

