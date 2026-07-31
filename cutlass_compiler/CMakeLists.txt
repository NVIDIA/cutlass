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

cmake_minimum_required(VERSION 3.20)
project(CutlassCompiler LANGUAGES C CXX)

# cutlass_compiler's bundled LLVM does not support the 'Assert' build type, so we
# convert it to 'Release' with LLVM assertions enabled.
if(CMAKE_BUILD_TYPE STREQUAL "Assert")
  set(CMAKE_BUILD_TYPE "Release")
  set(LLVM_ENABLE_ASSERTIONS ON CACHE BOOL "")
endif()

# cutlass_compiler is configured as a standalone CMake project, built only
# against public LLVM/MLIR.
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/Standalone.cmake)

# Top-level cutlass_compiler paths consumed by Integration / PipelineLit lit.site.cfg.py.in
set(CUTLASS_COMPILER_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(CUTLASS_COMPILER_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
set(CUTLASS_COMPILER_TOOL_DIR "${CMAKE_CURRENT_BINARY_DIR}/tools/cutlass-compiler")
set(CUTLASS_COMPILER_TEST_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/test")

option(CUTLASS_COMPILER_RUN_CUDA_SM90_TESTS "Whether to run cutlass_compiler Device integration tests on SM90 silicon" OFF)

# cutegen is added by cmake/Standalone.cmake.
add_subdirectory(base)
add_subdirectory(cute_ir)
add_subdirectory(tools)

# Project-level integration tests (host-side JIT via mlir-runner).
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/test/CMakeLists.txt")
  add_subdirectory(test)
endif()

# Aggregate target over every cutlass_compiler suite that exists in this build.
# Integration and pipelinelit only exist when integration tests are enabled, so
# each entry is guarded by if(TARGET ...).
set(_cutlass_compiler_all_test_deps)
foreach(_cutlass_compiler_test_target IN ITEMS
    check-cute
    check-cute-unittests
    check-cutegen-unittests
    check-base
    check-cutlass-integration
    check-cutlass-pipelinelit)
  if(TARGET ${_cutlass_compiler_test_target})
    list(APPEND _cutlass_compiler_all_test_deps ${_cutlass_compiler_test_target})
  endif()
endforeach()

add_custom_target(check-cutlass-all
  DEPENDS ${_cutlass_compiler_all_test_deps}
  COMMENT "Running every cutlass_compiler test suite"
)
set_target_properties(check-cutlass-all PROPERTIES FOLDER "Tests")

# The lit suites depend on LLVM test/run tools (FileCheck, mlir-runner, MLIR
# runtime libs) from the bundled llvm-project, which is added EXCLUDE_FROM_ALL.
# `ninja all` skips them and only `ninja check-*` pulls them in.
if(_cutlass_compiler_all_test_deps)
  set(_cutlass_compiler_lit_tools)
  foreach(_tool IN ITEMS FileCheck mlir-runner mlir_cuda_runtime
      mlir_runner_utils mlir_c_runner_utils)
    if(TARGET ${_tool})
      list(APPEND _cutlass_compiler_lit_tools ${_tool})
    endif()
  endforeach()
  if(_cutlass_compiler_lit_tools)
    add_custom_target(cutlass-compiler-lit-tools ALL)
    add_dependencies(cutlass-compiler-lit-tools ${_cutlass_compiler_lit_tools})
  endif()
endif()
