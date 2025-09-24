# Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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

include_guard()

include(CheckCXXCompilerFlag)
include(FindPackageHandleStandardArgs)

set(DPCPP_USER_FLAGS "" CACHE STRING "Additional user-specified compiler flags for DPC++")

get_filename_component(DPCPP_BIN_DIR ${CMAKE_CXX_COMPILER} DIRECTORY)
find_library(DPCPP_LIB_DIR NAMES sycl sycl6 PATHS "${DPCPP_BIN_DIR}/../lib")

add_library(DPCPP::DPCPP INTERFACE IMPORTED)

set(DPCPP_FLAGS "-fsycl;")
if(DPCPP_HOST_COMPILER)
  list(APPEND DPCPP_FLAGS "-fsycl-host-compiler=${DPCPP_HOST_COMPILER}")
  list(APPEND DPCPP_FLAGS "-fsycl-host-compiler-options=-Wno-changes-meaning -D$<JOIN:$<TARGET_PROPERTY:COMPILE_DEFINITIONS>, -D> -I$<JOIN:$<TARGET_PROPERTY:INCLUDE_DIRECTORIES>, -I>")
endif()
set(DPCPP_COMPILE_ONLY_FLAGS "")
set(DPCPP_LINK_ONLY_FLAGS "")

if(NOT "${DPCPP_SYCL_TARGET}" STREQUAL "")
  list(APPEND DPCPP_FLAGS "-fsycl-targets=${DPCPP_SYCL_TARGET};")
endif()

option(DPCPP_DISABLE_ITT_FOR_CUTLASS "Disables linking of the Instrumentation and Tracing Technology (ITT) device libraries for VTune" ON)

if(NOT "${DPCPP_USER_FLAGS}" STREQUAL "")
  list(APPEND DPCPP_FLAGS "${DPCPP_USER_FLAGS};")
endif()

if(NOT "${DPCPP_SYCL_ARCH}" STREQUAL "")
  if("${DPCPP_SYCL_TARGET}" STREQUAL "nvptx64-nvidia-cuda")
    list(APPEND DPCPP_FLAGS "-Xsycl-target-backend")
    list(APPEND DPCPP_FLAGS "--cuda-gpu-arch=${DPCPP_SYCL_ARCH}")
    list(APPEND DPCPP_COMPILE_ONLY_FLAGS; "-mllvm;-enable-global-offset=false;")
  endif()
endif()

if("${DPCPP_SYCL_TARGET}" STREQUAL "intel_gpu_pvc" OR
   "${DPCPP_SYCL_TARGET}" STREQUAL "spir64" OR
   "${DPCPP_SYCL_TARGET}" STREQUAL "intel_gpu_bmg_g21")
  if ((CMAKE_CXX_COMPILER_ID MATCHES "IntelLLVM" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 2025.2) OR CUTLASS_SYCL_BUILTIN_ENABLE)
    list(APPEND DPCPP_LINK_ONLY_FLAGS "-Xspirv-translator;-spirv-ext=+SPV_INTEL_split_barrier")
  else()
    list(APPEND DPCPP_LINK_ONLY_FLAGS "-Xspirv-translator;-spirv-ext=+SPV_INTEL_split_barrier,+SPV_INTEL_2d_block_io,+SPV_INTEL_subgroup_matrix_multiply_accumulate")
  endif()
  if(DPCPP_DISABLE_ITT_FOR_CUTLASS)
    list(APPEND DPCPP_FLAGS "-fno-sycl-instrument-device-code")
  endif()

endif()

if(UNIX)
  set_target_properties(DPCPP::DPCPP PROPERTIES
    INTERFACE_COMPILE_OPTIONS "${DPCPP_FLAGS};${DPCPP_COMPILE_ONLY_FLAGS}"
    INTERFACE_LINK_OPTIONS "${DPCPP_FLAGS};${DPCPP_LINK_ONLY_FLAGS}"
    INTERFACE_LINK_LIBRARIES ${DPCPP_LIB_DIR}
    INTERFACE_INCLUDE_DIRECTORIES "${DPCPP_BIN_DIR}/../include/sycl;${DPCPP_BIN_DIR}/../include")
  message(STATUS "DPCPP INCLUDE DIR: ${DPCPP_BIN_DIR}/../include/sycl;${DPCPP_BIN_DIR}/../include")
  message(STATUS "Using DPCPP compile flags: ${DPCPP_FLAGS};${DPCPP_COMPILE_ONLY_FLAGS}")
  message(STATUS "Using DPCPP link flags: ${DPCPP_FLAGS};${DPCPP_LINK_ONLY_FLAGS}")
else()
  set_target_properties(DPCPP::DPCPP PROPERTIES
    INTERFACE_COMPILE_OPTIONS "${DPCPP_FLAGS};${DPCPP_COMPILE_ONLY_FLAGS}"
    INTERFACE_LINK_OPTIONS "${DPCPP_FLAGS};${DPCPP_LINK_ONLY_FLAGS}"
    INTERFACE_LINK_LIBRARIES ${DPCPP_LIB_DIR}
    INTERFACE_INCLUDE_DIRECTORIES "${DPCPP_BIN_DIR}/../include/sycl")
endif()

function(add_sycl_to_target)
  set(options)
  set(oneValueArgs TARGET)
  set(multiValueArgs SOURCES)
  cmake_parse_arguments(CUTLASS_ADD_SYCL
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )
  target_compile_options(
    ${CUTLASS_ADD_SYCL_TARGET}
    PUBLIC
    $<$<COMPILE_LANGUAGE:CXX>:${DPCPP_FLAGS}>
  )
  get_target_property(target_type ${CUTLASS_ADD_SYCL_TARGET} TYPE)
  if (NOT target_type STREQUAL "OBJECT_LIBRARY")
    target_link_options(${CUTLASS_ADD_SYCL_TARGET} PUBLIC ${DPCPP_FLAGS} ${DPCPP_LINK_ONLY_FLAGS})
  endif()
endfunction()

function(add_sycl_include_directories_to_target NAME)
  target_include_directories(${NAME} SYSTEM
    PUBLIC ${DPCPP_BIN_DIR}/../include/sycl
    PUBLIC ${DPCPP_BIN_DIR}/../include
  )
endfunction()
