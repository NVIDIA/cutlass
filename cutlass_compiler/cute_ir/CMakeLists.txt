# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/AddCute.cmake)

# -------------------------------------------------------------------------------
# Project options
# -------------------------------------------------------------------------------
option(CUTLASS_COMPILER_CUTE_IR_ENABLE_TESTS "Generate build targets for the Cute dialect unit tests." ON)
# The Cute C++ unit tests build automatically when LLVM's vendored googletest
# from the pinned public llvm-project checkout is available, and are skipped
# when that checkout is not initialized. No user-facing flag controls this.
set(_cutlass_compiler_cute_unittests ON)
if(NOT EXISTS "${CUTLASS_COMPILER_BUNDLED_LLVM_DIR}/third-party/unittest/CMakeLists.txt")
  set(_cutlass_compiler_cute_unittests OFF)
endif()
option(CUTLASS_COMPILER_CUTE_IR_ENABLE_DOC_GEN "Whether to generate doc for the Cute dialect." OFF)

# -------------------------------------------------------------------------------
# Cute dialect configuration
# -------------------------------------------------------------------------------
set(CUTLASS_COMPILER_CUTE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(CUTLASS_COMPILER_CUTE_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include)
set(CUTLASS_COMPILER_CUTE_BINARY_INCLUDE_DIR ${CMAKE_CURRENT_BINARY_DIR}/include)
set(CUTLASS_COMPILER_CUTE_BINARY_LIB_DIR ${CMAKE_CURRENT_BINARY_DIR}/lib)
set(CUTLASS_COMPILER_CUTE_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})
set(CUTLASS_COMPILER_CUTE_TOOL_DIR ${CMAKE_CURRENT_BINARY_DIR}/tools/cute-opt)
set(CUTLASS_COMPILER_CUTE_LIBRARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/lib)

include_directories(${CUTLASS_COMPILER_CUTE_INCLUDE_DIR})
include_directories(${CUTLASS_COMPILER_CUTE_BINARY_INCLUDE_DIR})

# Include dir for dialect headers (lib/Dialect uses this for ADDITIONAL_HEADER_DIRS).
set(CUTLASS_COMPILER_CUTE_IR_DIALECT_INCLUDE_DIR ${CUTLASS_COMPILER_CUTE_INCLUDE_DIR})

add_subdirectory(include/cute_ir)
add_subdirectory(lib)
add_subdirectory(tools)

if(CUTLASS_COMPILER_CUTE_IR_ENABLE_TESTS)
  if(_cutlass_compiler_cute_unittests)
    # CMake may fail to auto-detect CXX compile features for the custom GCC path;
    # populate them manually so gtest's target_compile_features() call succeeds.
    if(CMAKE_CXX_COMPILE_FEATURES STREQUAL "")
      set(CMAKE_CXX_COMPILE_FEATURES
          "cxx_std_98;cxx_std_11;cxx_std_14;cxx_std_17;cxx_std_20;cxx_std_23"
          CACHE INTERNAL "CXX compile features (manually populated)")
      set(CMAKE_CXX14_COMPILE_FEATURES "cxx_std_14" CACHE INTERNAL "")
      set(CMAKE_CXX17_COMPILE_FEATURES "cxx_std_17" CACHE INTERNAL "")
    endif()
    # CMP0169 (cmake 3.31+) deprecates FetchContent_Populate; set OLD so that
    # IncludeGTest.cmake's macro continues to work unmodified. Guard for
    # older cmakes that don't know the policy.
    if(POLICY CMP0169)
      cmake_policy(SET CMP0169 OLD)
    endif()
    cutlass_compiler_configure_gtest()
  endif()
  add_subdirectory(test)
endif()
