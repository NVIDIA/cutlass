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

include(ExternalProject)

option(CUTLASS_SYCL_DISCONNECT_ONEMKL_UPDATE "Stop oneMKL from updating when the git tag is not changed" YES)

set(ONEMKL_INSTALL_DIR ${CMAKE_BINARY_DIR}/deps/oneMKL)

# Try to find oneMKL using find_package
find_package(MKL CONFIG QUIET PATHS $ENV{MKLROOT})

if (MKL_FOUND)
  message(STATUS "oneMKL found.")
  set(CUTLASS_USING_SYSTEM_ONEMKL TRUE)
else()
  message(STATUS "oneMKL not found, downloading and installing...")

  set(CUTLASS_USING_SYSTEM_ONEMKL FALSE)
  set(ONEMKL_INCLUDE_DIR ${ONEMKL_INSTALL_DIR}/include)
  set(ONEMKL_LIB ${ONEMKL_INSTALL_DIR}/lib/libonemkl.so)

  ExternalProject_Add(
    onemkl_project

    PREFIX                  ${ONEMKL_INSTALL_DIR}
    GIT_REPOSITORY          "https://github.com/oneapi-src/oneMKL.git"
    GIT_TAG                 "v0.6"

    CMAKE_ARGS
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    -DCMAKE_GENERATOR=${CMAKE_GENERATOR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX=${ONEMKL_INSTALL_DIR}
    -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath=${ONEMKL_INSTALL_DIR}/lib"
    -DENABLE_MKLCPU_BACKEND=OFF
    -DENABLE_MKLGPU_BACKEND=OFF
    -DBUILD_FUNCTIONAL_TESTS=OFF
    -DBUILD_EXAMPLES=OFF
    -DBUILD_DOC=OFF
    -DTARGET_DOMAINS=rng
    INSTALL_DIR ${ONEMKL_INSTALL_DIR}
    BUILD_BYPRODUCTS ${ONEMKL_LIB}
    UPDATE_DISCONNECTED ${CUTLASS_SYCL_DISCONNECT_ONEMKL_UPDATE}
  )

endif()


function(add_onemkl_to_target)
  set(options)
  set(oneValueArgs TARGET)
  set(multiValueArgs SOURCES)
  cmake_parse_arguments(CUTLASS_ADD_ONEMKL_TARGET
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  if (CUTLASS_USING_SYSTEM_ONEMKL)
    target_link_libraries(${NAME} PUBLIC MKL::MKL)
  else ()
    add_dependencies(${NAME} onemkl_project)
    target_include_directories(${NAME} PRIVATE ${ONEMKL_INCLUDE_DIR})
    target_link_libraries(${NAME} PUBLIC ${ONEMKL_LIB})
  endif ()
endfunction()
