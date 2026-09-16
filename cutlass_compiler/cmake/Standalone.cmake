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

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(GNUInstallDirs)
include(${CMAKE_CURRENT_LIST_DIR}/LLVM.cmake)

cutlass_compiler_configure_llvm()

if(NOT COMMAND print_var)
  macro(print_var name)
    message(STATUS " ${name}: ${${name}}")
  endmacro()
endif()

function(add_cutlass_compiler_mlir_doc doc_filename output_file output_path command)
  set(LLVM_TARGET_DEFINITIONS ${doc_filename}.td)
  tablegen(MLIR ${output_file}.md ${command} ${ARGN})
  add_custom_target(${output_file}DocGen
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${output_file}.md)
endfunction()

function(add_cutlass_compiler_library_install name)
  if(NOT LLVM_INSTALL_TOOLCHAIN_ONLY)
    install(TARGETS ${name}
      LIBRARY DESTINATION lib${LLVM_LIBDIR_SUFFIX}
      ARCHIVE DESTINATION lib${LLVM_LIBDIR_SUFFIX}
      RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
      OBJECTS DESTINATION lib${LLVM_LIBDIR_SUFFIX})
  endif()
endfunction()

function(add_cutlass_compiler_dialect_library name)
  set_property(GLOBAL APPEND PROPERTY CUTLASS_COMPILER_ALL_DIALECTS_TARGETS ${name})
  if(TARGET mlir-headers)
    add_mlir_library(${ARGV} DISABLE_INSTALL DEPENDS mlir-headers)
  else()
    add_mlir_library(${ARGV} DISABLE_INSTALL)
  endif()
  add_cutlass_compiler_library_install(${name})
endfunction()

function(add_cutlass_compiler_library name)
  add_mlir_library(${ARGV} DISABLE_INSTALL)
  add_cutlass_compiler_library_install(${name})
endfunction()

function(add_cutlass_compiler_conversion_library name)
  add_mlir_conversion_library(${ARGV} DISABLE_INSTALL)
  add_cutlass_compiler_library_install(${name})
endfunction()

function(add_cutlass_compiler_ut ARG_TARGET)
  set(options)
  set(oneValueArgs)
  set(multiValueArgs SRCS LINK_LIBS)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  add_executable(${ARG_TARGET} ${ARG_SRCS})
  llvm_update_compile_flags(${ARG_TARGET})
  target_link_libraries(${ARG_TARGET} PRIVATE ${ARG_LINK_LIBS})
endfunction()

if(NOT TARGET cutegen)
  if(NOT DEFINED CUTLASS_COMPILER_CUTEGEN_DIR OR CUTLASS_COMPILER_CUTEGEN_DIR STREQUAL "")
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cutegen/CMakeLists.txt")
      set(CUTLASS_COMPILER_CUTEGEN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/cutegen")
    elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../cutegen/CMakeLists.txt")
      set(CUTLASS_COMPILER_CUTEGEN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../cutegen")
    else()
      set(CUTLASS_COMPILER_CUTEGEN_DIR "")
    endif()
    set(CUTLASS_COMPILER_CUTEGEN_DIR "${CUTLASS_COMPILER_CUTEGEN_DIR}" CACHE PATH
      "Path to the cutegen source tree.")
  endif()
  if(NOT EXISTS "${CUTLASS_COMPILER_CUTEGEN_DIR}/CMakeLists.txt")
    message(FATAL_ERROR
      "CUTLASS_COMPILER_CUTEGEN_DIR=${CUTLASS_COMPILER_CUTEGEN_DIR} does not "
      "contain a CMakeLists.txt.")
  endif()
  if(NOT DEFINED CUTEGEN_ENABLE_TESTS)
    set(CUTEGEN_ENABLE_TESTS ON CACHE BOOL "" FORCE)
  endif()

  add_subdirectory(
    "${CUTLASS_COMPILER_CUTEGEN_DIR}"
    "${CMAKE_CURRENT_BINARY_DIR}/cutegen_external"
    EXCLUDE_FROM_ALL)
endif()

enable_testing()
