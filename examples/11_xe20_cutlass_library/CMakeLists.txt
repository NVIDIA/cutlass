# Copyright (C) 2025 Intel Corporation, All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Example 11: XE20 CUTLASS Library BF16 GEMM
# This example creates a shared library (.so) that exports CUTLASS BF16 GEMM
# functionality for use with Python via ctypes.

# Create shared library for Python integration
add_library(xe20_cutlass_library_bf16 SHARED
  xe20_cutlass_library_b16.cpp
)

# Set library properties (this creates shared library for python example to link)
set_target_properties(xe20_cutlass_library_bf16 PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED ON
  VERSION 1.0
  SOVERSION 1
  OUTPUT_NAME "xe20_cutlass_library_bf16"
  POSITION_INDEPENDENT_CODE ON
)

# Include directories
target_include_directories(xe20_cutlass_library_bf16 PRIVATE
  ${CUTLASS_EXAMPLES_COMMON_SOURCE_DIR}
  ${CUTLASS_EXAMPLES_UTILS_DIR}
  ${CUTLASS_APPLICATIONS_DIR}
)

# Link libraries
target_link_libraries(xe20_cutlass_library_bf16 PRIVATE
  CUTLASS
  cutlass_tools_util_includes
)

# Add compile definitions
target_compile_definitions(xe20_cutlass_library_bf16 PRIVATE
  CUTLASS_ENABLE_SYCL=1
  SYCL_INTEL_TARGET=1
  DPCPP_SYCL_TARGET=intel_gpu_bmg_g21
)

# Add Intel-specific SYCL link flags for XE20 optimization
if(CUTLASS_ENABLE_SYCL AND SYCL_INTEL_TARGET)
  target_link_options(xe20_cutlass_library_bf16 PRIVATE
    -Xspirv-translator
    -spirv-ext=+SPV_INTEL_split_barrier,+SPV_INTEL_2d_block_io,+SPV_INTEL_subgroup_matrix_multiply_accumulate
  )
  
  add_sycl_to_target(TARGET xe20_cutlass_library_bf16)
  add_onemkl_to_target(TARGET xe20_cutlass_library_bf16)
endif()

# Link against CUTLASS XE20 GEMM library if available
if(TARGET cutlass_gemm_xe20_gemm)
  target_link_libraries(xe20_cutlass_library_bf16 PRIVATE cutlass_gemm_xe20_gemm)
endif()

# Install the shared library
install(TARGETS xe20_cutlass_library_bf16
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Add to examples target
add_dependencies(cutlass_examples xe20_cutlass_library_bf16)

# Custom target for building just this library
add_custom_target(xe20_cutlass_library 
  DEPENDS xe20_cutlass_library_bf16
  COMMENT "Building XE20 CUTLASS Library BF16 GEMM Shared Library (.so)"
)

message(STATUS "Added shared library xe20_cutlass_library_bf16 for Python integration")
