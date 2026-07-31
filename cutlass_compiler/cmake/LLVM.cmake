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

include_guard(GLOBAL)

macro(cutlass_compiler_configure_llvm)
  option(CUTLASS_COMPILER_USE_BUNDLED_LLVM
    "Build the bundled llvm-project checkout instead of finding LLVM/MLIR."
    OFF)
  set(CUTLASS_COMPILER_BUNDLED_LLVM_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/external/llvm-project"
    CACHE PATH "Path to the bundled llvm-project source checkout.")
  set(CUTLASS_COMPILER_BUNDLED_LLVM_TARGETS "Native;NVPTX" CACHE STRING
    "LLVM targets to build when using the bundled llvm-project checkout.")
  option(CUTLASS_COMPILER_BUNDLED_LLVM_ENABLE_CUDA_RUNNER
    "Enable MLIR's CUDA runner when building the bundled LLVM."
    OFF)

  if(CUTLASS_COMPILER_USE_BUNDLED_LLVM)
    set(_llvm_source_dir "${CUTLASS_COMPILER_BUNDLED_LLVM_DIR}")
    if(NOT EXISTS "${_llvm_source_dir}/llvm/CMakeLists.txt")
      message(FATAL_ERROR
        "CUTLASS_COMPILER_USE_BUNDLED_LLVM=ON but llvm-project was not found at:\n"
        "  ${_llvm_source_dir}\n"
        "Fetch the revision recorded in LLVM_COMMIT as described in README.md.")
    endif()

    set(LLVM_INCLUDE_EXAMPLES OFF CACHE BOOL "")
    set(LLVM_INCLUDE_TESTS OFF CACHE BOOL "")
    set(LLVM_INCLUDE_BENCHMARKS OFF CACHE BOOL "")
    set(LLVM_APPEND_VC_REV OFF CACHE BOOL "")
    set(LLVM_ENABLE_PROJECTS "mlir" CACHE STRING "")
    set(LLVM_TARGETS_TO_BUILD "${CUTLASS_COMPILER_BUNDLED_LLVM_TARGETS}"
      CACHE STRING "")
    set(LLVM_BUILD_EXAMPLES OFF CACHE BOOL "")
    set(MLIR_ENABLE_CUDA_RUNNER
      ${CUTLASS_COMPILER_BUNDLED_LLVM_ENABLE_CUDA_RUNNER} CACHE BOOL "")
    set(MLIR_ENABLE_BINDINGS_PYTHON OFF CACHE BOOL "")

    add_subdirectory(
      "${_llvm_source_dir}/llvm"
      "${CMAKE_CURRENT_BINARY_DIR}/llvm-project"
      EXCLUDE_FROM_ALL)

    include("${LLVM_BINARY_DIR}/lib/cmake/llvm/LLVMConfig.cmake")
    set(LLVM_DIR "${LLVM_BINARY_DIR}/lib/cmake/llvm" CACHE PATH "" FORCE)
    set(MLIR_DIR "${CMAKE_CURRENT_BINARY_DIR}/lib/cmake/mlir"
      CACHE PATH "" FORCE)
    find_package(MLIR REQUIRED CONFIG PATHS "${MLIR_DIR}" NO_DEFAULT_PATH)

    set(MLIR_MAIN_SRC_DIR "${_llvm_source_dir}/mlir" CACHE PATH "" FORCE)
    set(MLIR_INCLUDE_DIR "${LLVM_BINARY_DIR}/tools/mlir/include" CACHE PATH "" FORCE)
    set(MLIR_INCLUDE_DIRS
      "${MLIR_INCLUDE_DIR}"
      "${MLIR_MAIN_SRC_DIR}/include"
      CACHE STRING "" FORCE)
    set(LLVM_TOOLS_DIR "${LLVM_BINARY_DIR}/bin" CACHE PATH "" FORCE)
    if(NOT LLVM_EXTERNAL_LIT)
      set(LLVM_EXTERNAL_LIT "${_llvm_source_dir}/llvm/utils/lit/lit.py"
        CACHE FILEPATH "lit executable" FORCE)
    endif()
  else()
    if(DEFINED LLVM_PROJECT_BUILD_DIR AND NOT LLVM_DIR)
      set(LLVM_DIR "${LLVM_PROJECT_BUILD_DIR}/lib/cmake/llvm" CACHE PATH "" FORCE)
    endif()
    if(DEFINED LLVM_PROJECT_BUILD_DIR AND NOT MLIR_DIR)
      set(MLIR_DIR "${LLVM_PROJECT_BUILD_DIR}/lib/cmake/mlir" CACHE PATH "" FORCE)
    endif()

    find_package(LLVM REQUIRED CONFIG)
    find_package(MLIR REQUIRED CONFIG)

    if(NOT LLVM_TOOLS_DIR)
      if(LLVM_TOOLS_BINARY_DIR)
        set(LLVM_TOOLS_DIR "${LLVM_TOOLS_BINARY_DIR}" CACHE PATH "" FORCE)
      elseif(LLVM_BINARY_DIR)
        set(LLVM_TOOLS_DIR "${LLVM_BINARY_DIR}/bin" CACHE PATH "" FORCE)
      endif()
    endif()
  endif()

  find_package(Python3 REQUIRED COMPONENTS Interpreter)

  include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
  include_directories(SYSTEM ${MLIR_INCLUDE_DIRS})
  link_directories(${LLVM_LIBRARY_DIRS})

  set(_cutlass_compiler_llvm_library_dir "")
  if(LLVM_LIBRARY_DIRS)
    list(GET LLVM_LIBRARY_DIRS 0 _cutlass_compiler_llvm_library_dir)
  elseif(LLVM_LIBRARY_DIR)
    set(_cutlass_compiler_llvm_library_dir "${LLVM_LIBRARY_DIR}")
  elseif(LLVM_BINARY_DIR)
    set(_cutlass_compiler_llvm_library_dir "${LLVM_BINARY_DIR}/lib")
  endif()
  set(CUTLASS_COMPILER_LLVM_LIBRARY_DIR "${_cutlass_compiler_llvm_library_dir}"
    CACHE PATH "Directory containing LLVM/MLIR runtime libraries." FORCE)

  separate_arguments(_cutlass_compiler_llvm_defs NATIVE_COMMAND "${LLVM_DEFINITIONS}")
  add_definitions(${_cutlass_compiler_llvm_defs})

  list(APPEND CMAKE_MODULE_PATH "${LLVM_DIR}" "${MLIR_DIR}")
  include(TableGen)
  include(AddLLVM)
  include(AddMLIR)

  if(NOT LLVM_EXTERNAL_LIT)
    find_program(LLVM_LIT_EXECUTABLE llvm-lit HINTS "${LLVM_TOOLS_DIR}" NO_DEFAULT_PATH)
    if(LLVM_LIT_EXECUTABLE)
      set(LLVM_EXTERNAL_LIT "${LLVM_LIT_EXECUTABLE}" CACHE FILEPATH
        "lit executable" FORCE)
    endif()
  endif()

  if(NOT LLVM_TABLEGEN_EXE)
    find_program(LLVM_TABLEGEN_EXE llvm-tblgen HINTS "${LLVM_TOOLS_DIR}" NO_DEFAULT_PATH)
    if(LLVM_TABLEGEN_EXE)
      set(LLVM_TABLEGEN_EXE "${LLVM_TABLEGEN_EXE}" CACHE FILEPATH
        "llvm-tblgen executable" FORCE)
    endif()
  endif()

  if(NOT MLIR_TABLEGEN_EXE)
    find_program(MLIR_TABLEGEN_EXE mlir-tblgen HINTS "${LLVM_TOOLS_DIR}" NO_DEFAULT_PATH)
    if(MLIR_TABLEGEN_EXE)
      set(MLIR_TABLEGEN_EXE "${MLIR_TABLEGEN_EXE}" CACHE FILEPATH
        "mlir-tblgen executable" FORCE)
    endif()
  endif()

  if(NOT TARGET FileCheck)
    find_program(LLVM_FILECHECK_EXECUTABLE FileCheck HINTS "${LLVM_TOOLS_DIR}" NO_DEFAULT_PATH)
    if(LLVM_FILECHECK_EXECUTABLE)
      add_custom_target(FileCheck)
    endif()
  endif()
endmacro()

function(cutlass_compiler_configure_gtest)
  if(TARGET gtest_main)
    return()
  endif()

  if(TARGET llvm_gtest_main AND TARGET llvm_gtest)
    if(NOT TARGET gtest)
      add_library(gtest ALIAS llvm_gtest)
    endif()
    if(NOT TARGET gtest_main)
      add_library(gtest_main ALIAS llvm_gtest_main)
    endif()
    return()
  endif()

  set(CUTLASS_COMPILER_GTEST_SOURCE_DIR
    "${CUTLASS_COMPILER_BUNDLED_LLVM_DIR}/third-party/unittest"
    CACHE PATH "Path to LLVM's vendored googletest source directory.")

  if(NOT EXISTS "${CUTLASS_COMPILER_GTEST_SOURCE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR
      "The Cute C++ unit tests require LLVM-vendored googletest.\n"
      "Expected LLVM's googletest source at:\n"
      "  ${CUTLASS_COMPILER_GTEST_SOURCE_DIR}\n"
      "Fetch the revision recorded in LLVM_COMMIT as described in README.md, "
      "or set CUTLASS_COMPILER_GTEST_SOURCE_DIR.")
  endif()

  set(LLVM_INSTALL_GTEST OFF CACHE BOOL "" FORCE)

  add_subdirectory(
    "${CUTLASS_COMPILER_GTEST_SOURCE_DIR}"
    "${CMAKE_CURRENT_BINARY_DIR}/third-party/unittest"
    EXCLUDE_FROM_ALL)

  if(TARGET llvm_gtest_main AND TARGET llvm_gtest)
    if(NOT TARGET gtest)
      add_library(gtest ALIAS llvm_gtest)
    endif()
    if(NOT TARGET gtest_main)
      add_library(gtest_main ALIAS llvm_gtest_main)
    endif()
    return()
  endif()

  message(FATAL_ERROR
    "Failed to configure LLVM-vendored googletest from ${CUTLASS_COMPILER_GTEST_SOURCE_DIR}.")
endfunction()
