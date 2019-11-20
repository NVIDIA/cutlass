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

cmake_minimum_required(VERSION 3.12.4 FATAL_ERROR)

if(cutlass_LOADED)
  # If CUTLASS has been previously fetched and loaded, don't do it again.
  return()
else()
  set(cutlass_LOADED ON)
  set(CUTLASS_DIR ${CMAKE_CURRENT_SOURCE_DIR} CACHE PATH "CUTLASS Repository Directory")
endif()

message(STATUS "CMake Version: ${CMAKE_VERSION}")

project(CUTLASS VERSION 2.0.0 LANGUAGES CXX)
include(${CMAKE_CURRENT_SOURCE_DIR}/CUDA.cmake)

find_package(Doxygen QUIET)

#
# CUTLASS 2.0 requires C++11
#

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(CUTLASS_NATIVE_CUDA)
  set(CMAKE_CUDA_STANDARD 11)
  set(CMAKE_CUDA_STANDARD_REQUIRED ON)
else()
  string(APPEND NVCC_FLAGS " --std=c++11")
endif()

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX install CACHE PATH "Default installation location." FORCE)
endif()

message(STATUS "Default Install Location: ${CMAKE_INSTALL_PREFIX}")

if(${CMAKE_PROJECT_NAME} MATCHES ${PROJECT_NAME})
  set(_CUTLASS_ENABLE_TESTS ON)
else()
  set(_CUTLASS_ENABLE_TESTS OFF)
endif()

set(CUTLASS_ENABLE_TESTS ${_CUTLASS_ENABLE_TESTS} CACHE BOOL "Enable CUTLASS Tests")

if (CUTLASS_ENABLE_TESTS)
  include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/googletest.cmake)
endif()

set(CUTLASS_NVCC_ARCHS_SUPPORTED "")
if (NOT CUDA_VERSION VERSION_LESS 7.5)
  list(APPEND CUTLASS_NVCC_ARCHS_SUPPORTED 50)
endif()
if (NOT CUDA_VERSION VERSION_LESS 8.0)
  list(APPEND CUTLASS_NVCC_ARCHS_SUPPORTED 60 61)
endif()
if (NOT CUDA_VERSION VERSION_LESS 9.0)
  list(APPEND CUTLASS_NVCC_ARCHS_SUPPORTED 70)
endif()
if (NOT CUDA_VERSION VERSION_LESS 9.2)
  list(APPEND CUTLASS_NVCC_ARCHS_SUPPORTED 72)
endif()
if (NOT CUDA_VERSION VERSION_LESS 10.0)
  list(APPEND CUTLASS_NVCC_ARCHS_SUPPORTED 75)
endif()

if(CUDA_COMPILER MATCHES "[Cc]lang")
  if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang" )
    message(FATAL_ERROR "Clang CUDA compilation requires Clang CXX compilation. Currently CMAKE_CXX_COMPILER is ${CMAKE_CXX_COMPILER_ID}" )
  endif()
  if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 7.0)
    message(FATAL_ERROR "Clang 7.0+ required for GPU compilation")
  endif()
endif()
    
set(CUTLASS_NVCC_ARCHS ${CUTLASS_NVCC_ARCHS_SUPPORTED} CACHE STRING "The SM architectures requested.")
set(CUTLASS_NVCC_ARCHS_ENABLED ${CUTLASS_NVCC_ARCHS} CACHE STRING "The SM architectures to build code for.")

# Special policy introduced in CMake 3.13
if (POLICY CMP0076)
  cmake_policy(SET CMP0076 NEW)
endif() 

# check if the configuration is supported
if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "CUTLASS requires a 64-bit compiler!")
endif()

include(GNUInstallDirs)

###################################################################################################
#
# Configure CMake variables
#
###################################################################################################

message(STATUS "CUDA Compilation Architectures: ${CUTLASS_NVCC_ARCHS_ENABLED}")

if (NOT (CMAKE_BUILD_TYPE OR CONFIGURATION_TYPES))
  # By default we want to build in Release mode to ensure that we're getting best performance. 
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose build level" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "RelWithDebInfo" "Release")
endif()

if(WIN32)
  # On Windows we link against the shared (DLL) runtime. Change gtest settings to match this.
  set(gtest_force_shared_crt ON CACHE BOOL "Use shared (DLL) run-time lib even when Google Test is built as static lib" FORCE)
endif()

if (WIN32)
  # Enable more warnings and treat as errors
  string(APPEND NVCC_FLAGS " -Xcompiler /W3 -Xcompiler /WX")

  # Disable warning on Unicode characters
  string(APPEND NVCC_FLAGS " -Xcompiler /wd4819")

  # Disable excess x86 floating point precision that can lead to results being labeled incorrectly
  string(APPEND NVCC_FLAGS " -Xcompiler /fp:strict")
endif(WIN32)

if (${CUTLASS_NVCC_VERBOSE})
  string(APPEND NVCC_FLAGS " -v")
endif()

set(CUTLASS_NVCC_EMBED_CUBIN ON CACHE BOOL "Embed compiled CUDA kernel binaries into executables.")
set(CUTLASS_NVCC_EMBED_PTX ON CACHE BOOL "Embed compiled PTX into executables.")
set(CUTLASS_NVCC_KEEP OFF CACHE BOOL "Keep intermediate files generated by NVCC.")
set(CUTLASS_ENABLE_F16C ON CACHE BOOL "Enable F16C x86 extensions in host code.")
set(CUTLASS_LIBRARY_KERNELS "128x128" CACHE STRING "Comma delimited list of kernel name filters. Default '' means all kernels are enabled.")

# Test Levels L0, L1, L2
set(CUTLASS_TEST_LEVEL "0" CACHE STRING "Level of tests to compile.")
set_property(CACHE CUTLASS_TEST_LEVEL PROPERTY STRINGS 0 1 2)
string(APPEND NVCC_FLAGS " -DCUTLASS_TEST_LEVEL=${CUTLASS_TEST_LEVEL}")

#
# CUDA 10.1 introduces "mma" in PTX performing collective matrix multiply operations.
#

if (CUDA_VERSION VERSION_LESS 10.1)
  set(CUTLASS_ENABLE_TENSOR_CORE_MMA_DEFAULT OFF)
else()
  set(CUTLASS_ENABLE_TENSOR_CORE_MMA_DEFAULT ON)
endif()

set(CUTLASS_ENABLE_TENSOR_CORE_MMA ${CUTLASS_ENABLE_TENSOR_CORE_MMA_DEFAULT} CACHE BOOL 
  "Enable PTX mma instruction for collective matrix multiply operations.")

#
# NOTE: running with asan and CUDA requires the following environment variable:
#
#  ASAN_OPTIONS=protect_shadow_gap=0:replace_intrin=0:detect_leaks=0
#
# without the above environment setting, an error like the following may be generated:
#
#  *** Error: Could not detect active GPU device ID [out of memory]
#  ...
#  ==9149==ERROR: LeakSanitizer: detected memory leaks
#  ...
#
if(ENABLE_ASAN)  # https://github.com/google/sanitizers/wiki/AddressSanitizer
  string(APPEND NVCC_FLAGS " --compiler-options -fsanitize=address --compiler-options -fno-omit-frame-pointer")
  string(APPEND CMAKE_EXE_LINKER_FLAGS " -fsanitize=address")
endif()

###################################################################################################
#
# Configure CUDA build options
#
###################################################################################################

foreach(ARCH ${CUTLASS_NVCC_ARCHS_ENABLED})
  if(CUTLASS_NVCC_EMBED_CUBIN)
    string(APPEND NVCC_GENCODE_FLAGS " -gencode=arch=compute_${ARCH},code=sm_${ARCH}")
  endif()
  if(CUTLASS_NVCC_EMBED_PTX)
    string(APPEND NVCC_GENCODE_FLAGS " -gencode=arch=compute_${ARCH},code=compute_${ARCH}")
  endif()
  string(APPEND CLANG_FLAGS " --cuda-gpu-arch=sm_${ARCH}")
endforeach()

if(CUTLASS_NVCC_EMBED_PTX)
  string(APPEND CLANG_FLAGS " --cuda-include-ptx=all")
endif()

if (CUTLASS_ENABLE_TENSOR_CORE_MMA)
  string(APPEND COMMON_FLAGS " -DCUTLASS_ENABLE_TENSOR_CORE_MMA=1")
endif()

if (NOT MSVC AND CUTLASS_NVCC_KEEP)
  # MSVC flow handles caching already, but for other generators we handle it here.
  set(CUTLASS_NVCC_KEEP_DIR ${CMAKE_CURRENT_BINARY_DIR}/tmp CACHE PATH "Location to store NVCC scratch files")
  file(MAKE_DIRECTORY ${CUTLASS_NVCC_KEEP_DIR})
  string(APPEND NVCC_FLAGS " --keep") # --keep-dir may not work with nvcc for some directories.
  string(APPEND CLANG_FLAGS " -save-temps=${CUTLASS_NVCC_KEEP_DIR}")
endif()

if (CUTLASS_ENABLE_F16C)
  string(APPEND COMPILER_FLAGS " -DCUTLASS_ENABLE_F16C=1")
  if ((CMAKE_CXX_COMPILER_ID MATCHES "GNU") OR (CMAKE_CXX_COMPILER_ID MATCHES "Clang"))
    string(APPEND NVCC_FLAGS " -Xcompiler -mf16c")
  elseif((CMAKE_CXX_COMPILER_ID MATCHES "MSVC"))
    string(APPEND NVCC_FLAGS " -Xcompiler /arch:AVX2")
  endif()
endif()

string(APPEND NVCC_FLAGS " -lineinfo")

string(APPEND CLANG_FLAGS " -gmlt")

if (UNIX)
  string(APPEND NVCC_FLAGS " -Xcompiler -Wconversion")
  string(APPEND NVCC_FLAGS " -Xcompiler -fno-strict-aliasing")
endif()

if(CUDA_COMPILER MATCHES "[Cc]lang")
  string(APPEND CLANG_FLAGS " --cuda-path=${CUDA_TOOLKIT_ROOT_DIR}")
  string(APPEND CLANG_FLAGS " -mllvm -pragma-unroll-threshold=100000")
  string(APPEND CLANG_FLAGS " -mllvm -unroll-threshold=5000")
  string(APPEND CLANG_FLAGS " -Wno-unused-command-line-argument")

  string(REPLACE "." ";" CUDA_VERSION_PARTS ${CMAKE_CUDA_COMPILER_VERSION})
  list(GET CUDA_VERSION_PARTS 0 CUDA_VERSION_MAJOR)
  list(GET CUDA_VERSION_PARTS 1 CUDA_VERSION_MINOR)
  string(APPEND CLANG_FLAGS " -D__CUDACC_VER_MAJOR__=${CUDA_VERSION_MAJOR} -D__CUDACC_VER_MINOR__=${CUDA_VERSION_MINOR}")

  # needed for libcublasLt.so in case it's installed in the same location as libcudart.so
  # dynamic linker can find it if linker sets RPATH (forced by --disable-new-tags)
  # Otherwise linker uses RUNPATH and that does not propagate to loaded libs.
  string(APPEND CLANG_FLAGS " -Wl,--disable-new-dtags")

  link_libraries(nvidia::cudart)
endif()

if(CUDA_COMPILER MATCHES "[Cc]lang")
  string(APPEND CMAKE_CXX_FLAGS "${COMMON_FLAGS} ${CLANG_FLAGS}")
  string(APPEND CMAKE_CXX_FLAGS_RELEASE "${COMMON_FLAGS_RELEASE} ${CLANG_FLAGS_RELEASE}")
  string(APPEND CMAKE_CXX_FLAGS_RELWITHDEBINFO "${COMMON_FLAGS_RELWITHDEBINFO} ${CLANG_FLAGS_RELWITHDEBINFO}")
  string(APPEND CMAKE_CXX_FLAGS_DEBUG "${COMMON_FLAGS_DEBUG} ${CLANG_FLAGS_DEBUG}")
elseif (CUTLASS_NATIVE_CUDA)
  string(APPEND CMAKE_CUDA_FLAGS "${COMMON_FLAGS} ${NVCC_FLAGS} ${NVCC_GENCODE_FLAGS}")
  string(APPEND CMAKE_CUDA_FLAGS_RELEASE "${COMMON_FLAGS_RELEASE} ${NVCC_FLAGS_RELEASE}")
  string(APPEND CMAKE_CUDA_FLAGS_RELWITHDEBINFO "${COMMON_FLAGS_RELWITHDEBINFO} ${NVCC_FLAGS_RELWITHDEBINFO}")
  string(APPEND CMAKE_CUDA_FLAGS_DEBUG "${COMMON_FLAGS_DEBUG} ${NVCC_FLAGS_DEBUG}")
else()
  string(APPEND CUDA_NVCC_FLAGS "${COMMON_FLAGS} ${NVCC_FLAGS} ${NVCC_GENCODE_FLAGS}")
  string(APPEND CUDA_NVCC_FLAGS_RELEASE "${COMMON_FLAGS_RELEASE} ${NVCC_FLAGS_RELEASE}")
  string(APPEND CUDA_NVCC_FLAGS_RELWITHDEBINFO "${COMMON_FLAGS_RELWITHDEBINFO} ${NVCC_FLAGS_RELWITHDEBINFO}")
  string(APPEND CUDA_NVCC_FLAGS_DEBUG "${COMMON_FLAGS_DEBUG} ${NVCC_FLAGS_DEBUG}")
endif()

#
# The following items should eventually be pushed into cutlass/CMakeLists.txt
#

# GLOB for CUTLASS header files. Should we use a static list instead?
file(GLOB_RECURSE CUTLASS_INCLUDE RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} include/cutlass/*.h)
file(GLOB_RECURSE CUTLASS_CUTLASS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/include include/cutlass/*.h)
file(GLOB_RECURSE CUTLASS_NVRTC RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/test test/unit/nvrtc/kernel/*.h)

###################################################################################################
#
# Define build targets
#
###################################################################################################

source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR}/include REGULAR_EXPRESSION ".*\.h")

add_library(CUTLASS INTERFACE)
add_library(nvidia::cutlass::cutlass ALIAS CUTLASS)
set_target_properties(CUTLASS PROPERTIES EXPORT_NAME cutlass)

set(CUTLASS_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include CACHE PATH "CUTLASS Header Library")

set(CUTLASS_GENERATOR_DIR ${CMAKE_CURRENT_SOURCE_DIR}/tools/library/)

# The following utility directory is needed even if the tools build is disabled, so it exists here.
set(CUTLASS_TOOLS_UTIL_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/tools/util/include CACHE INTERNAL "")

include_directories(${CUTLASS_INCLUDE_DIR})

target_compile_features(CUTLASS INTERFACE cxx_std_11)

if (NOT DEFINED CUTLASS_REVISION)

  find_package(Git QUIET)

  execute_process(
    COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
    RESULT_VARIABLE CUTLASS_REVISION_RESULT
    OUTPUT_VARIABLE CUTLASS_REVISION
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  if (CUTLASS_REVISION_RESULT)
    message(STATUS "CUTLASS Revision: Unable to detect, Git returned code ${CUTLASS_REVISION_RESULT}.")
  else()
    message(STATUS "CUTLASS Revision: ${CUTLASS_REVISION}")
  endif()

endif()

configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/version.h.in 
  ${CMAKE_CURRENT_BINARY_DIR}/include/cutlass/version.h 
  @ONLY)

target_include_directories(
  CUTLASS
  INTERFACE
  $<INSTALL_INTERFACE:include>
  $<BUILD_INTERFACE:${CUTLASS_INCLUDE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
  $<BUILD_INTERFACE:${CUDA_TOOLKIT_ROOT_DIR}/include>
  )

install(
  DIRECTORY 
  ${CUTLASS_INCLUDE_DIR}/ 
  ${CMAKE_CURRENT_BINARY_DIR}/include/
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  )

install(
  TARGETS CUTLASS
  EXPORT NvidiaCutlass
  PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  )

################################################################################

# Doxygen is available. Generate documentation
if (DOXYGEN_FOUND)
    # DOT is available. Enable graph generation in the documentation
    if (DOXYGEN_DOT_EXECUTABLE)
        set(CUTLASS_ENABLE_DOXYGEN_DOT ON CACHE BOOL "Use dot to generate graphs in the doxygen documentation.")
    else()
        set(CUTLASS_ENABLE_DOXYGEN_DOT OFF CACHE BOOL "Use dot to generate graphs in the doxygen documentation." FORCE)
    endif()

    if (CUTLASS_ENABLE_DOXYGEN_DOT)
        set(HAVE_DOT "YES")
    else()
        set(HAVE_DOT "NO")
    endif()

    # Add custom target for Doxygen.
    add_custom_target(cutlass_docs ${CMAKE_COMMAND} -E env
        "DOT_PATH=${DOXYGEN_DOT_EXECUTABLE}"
        "HAVE_DOT=${HAVE_DOT}"
        ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        VERBATIM
    )
endif()

if(NOT WIN32)
  # Add common library search paths so executables and libraries can load and run
  # without LD_LIBRARY_PATH being set.
  link_libraries(
    "-Wl,-rpath,'$ORIGIN'"
    "-Wl,-rpath,'$ORIGIN/../lib64'"
    "-Wl,-rpath,'$ORIGIN/../lib'"
    "-Wl,-rpath,'${CUDA_TOOLKIT_ROOT_DIR}/lib64'"
    "-Wl,-rpath,'${CUDA_TOOLKIT_ROOT_DIR}/lib'"
    )
endif()

################################################################################

include(${CMAKE_CURRENT_SOURCE_DIR}/cuBLAS.cmake)

if (CUTLASS_ENABLE_CUBLAS)
  target_compile_definitions(CUTLASS INTERFACE CUTLASS_ENABLE_CUBLAS=1)
endif()

################################################################################

set(CUTLASS_ENABLE_HEADERS_ONLY OFF CACHE BOOL "Enable only the header library")

if(CUTLASS_ENABLE_HEADERS_ONLY)
  set(CUTLASS_ENABLE_EXAMPLES_INIT OFF)
  set(CUTLASS_ENABLE_TOOLS_INIT OFF)
else()
  set(CUTLASS_ENABLE_EXAMPLES_INIT ON)
  set(CUTLASS_ENABLE_TOOLS_INIT ON)
endif()

set(CUTLASS_ENABLE_EXAMPLES ${CUTLASS_ENABLE_EXAMPLES_INIT} CACHE BOOL "Enable CUTLASS Examples")
set(CUTLASS_ENABLE_TOOLS ${CUTLASS_ENABLE_TOOLS_INIT} CACHE BOOL "Enable CUTLASS Tools")

if(${CMAKE_PROJECT_NAME} STREQUAL ${PROJECT_NAME})
  set(CUTLASS_ENABLE_TESTS_INIT ${CUTLASS_ENABLE_TOOLS_INIT})
else()
  set(CUTLASS_ENABLE_TESTS_INIT OFF)
endif()

set(CUTLASS_ENABLE_TESTS ${CUTLASS_ENABLE_TESTS_INIT} CACHE BOOL "Enable CUTLASS Tests")

if(CUTLASS_ENABLE_TOOLS)
  add_subdirectory(tools)
endif()
if(CUTLASS_ENABLE_EXAMPLES)
  add_subdirectory(examples)
endif()

if(CUTLASS_ENABLE_TESTS)
  include(CTest)
  enable_testing()
  add_subdirectory(test)
endif()

################################################################################

install(
  FILES ${CMAKE_CURRENT_SOURCE_DIR}/cmake/NvidiaCutlassConfig.cmake
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/
  )

install(
  EXPORT NvidiaCutlass
  NAMESPACE nvidia::cutlass::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/
  FILE NvidiaCutlassTargets.cmake
  )

################################################################################

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/NvidiaCutlassPackageConfig.cmake)
