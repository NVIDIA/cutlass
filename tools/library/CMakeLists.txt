# Copyright (c) 2017-2019, NVIDIA CORPORATION.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright notice, this list of
#       conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice, this list of
#       conditions and the following disclaimer in the documentation and/or other materials
#       provided with the distribution.
#     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
#       to endorse or promote products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

include(GNUInstallDirs)

find_package(Python3 3.5 COMPONENTS Interpreter REQUIRED)

add_library(cutlass_library_includes INTERFACE)
add_library(nvidia::cutlass::library::includes ALIAS cutlass_library_includes)
set_target_properties(cutlass_library_includes PROPERTIES EXPORT_NAME library::includes)

target_include_directories(
  cutlass_library_includes
  INTERFACE
  $<INSTALL_INTERFACE:include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  )

target_link_libraries(
  cutlass_library_includes 
  INTERFACE 
  CUTLASS
  cutlass_tools_util_includes
  )

install(
  DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/
  )

#
# CUTLASS Deliverables Library
#

cutlass_add_library(
  cutlass_lib
  SHARED
  src/library.cu
  src/manifest.cpp
  )
add_library(nvidia::cutlass::library ALIAS cutlass_lib)
set_target_properties(cutlass_lib PROPERTIES EXPORT_NAME library)

file(GLOB_RECURSE GENERATOR_PYTHON_SOURCES CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/scripts/*.py)

#
# auto-instantiation of CUTLASS kernels
#

execute_process(
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/scripts
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/scripts/generator.py
    --operations all 
    --build-dir ${PROJECT_BINARY_DIR}
    --curr-build-dir ${CMAKE_CURRENT_BINARY_DIR}
    --generator-target library
    --architectures "${CUTLASS_NVCC_ARCHS_ENABLED}"
    --kernels "${CUTLASS_LIBRARY_KERNELS}"
    --cuda-version "${CMAKE_CUDA_COMPILER_VERSION}"
  RESULT_VARIABLE cutlass_lib_INSTANCE_GENERATION_RESULT
  OUTPUT_VARIABLE cutlass_lib_INSTANCE_GENERATION_OUTPUT
  OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/library_instance_generation.log
  ERROR_FILE ${CMAKE_CURRENT_BINARY_DIR}/library_instance_generation.log
)

if(NOT cutlass_lib_INSTANCE_GENERATION_RESULT EQUAL 0)
  message(FATAL_ERROR "Error generating library instances. See ${CMAKE_CURRENT_BINARY_DIR}/library_instance_generation.log")
endif()

# include auto-instantiated kernels in he CUTLASS Deliverables Library
set(CUTLASS_LIBRARY_MANIFEST_CMAKE_FILE ${CMAKE_CURRENT_BINARY_DIR}/generated/manifest.cmake)
if(EXISTS "${CUTLASS_LIBRARY_MANIFEST_CMAKE_FILE}")
  include(${CUTLASS_LIBRARY_MANIFEST_CMAKE_FILE})
else()
  message(STATUS "auto-generated library manifest cmake file (${CUTLASS_LIBRARY_MANIFEST_CMAKE_FILE}) not found.")
endif()

target_include_directories(
  cutlass_lib
  PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/src
  ${CMAKE_CURRENT_BINARY_DIR}/include
  )

set_target_properties(
  cutlass_lib
  PROPERTIES
  OUTPUT_NAME cutlass
  WINDOWS_EXPORT_ALL_SYMBOLS 1
  )

target_link_libraries(
  cutlass_lib 
  PUBLIC 
    cutlass_library_includes
  )

install(
  DIRECTORY
    ${CMAKE_CURRENT_SOURCE_DIR}/include/
  DESTINATION
    ${CMAKE_INSTALL_INCLUDEDIR}
  )

install(
  TARGETS cutlass_lib cutlass_library_includes
  EXPORT NvidiaCutlass
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )
