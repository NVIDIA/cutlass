# Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
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

include(CTest)

cutlass_add_library(
  cutlass_test_unit_infra 
  OBJECT
  common/filter_architecture.cpp
  )

target_link_libraries(
  cutlass_test_unit_infra
  PUBLIC
  CUTLASS
  cutlass_tools_util_includes
  $<$<BOOL:${CUTLASS_ENABLE_CUBLAS}>:nvidia::cublas>
  gtest
  )

cutlass_add_library(
  cutlass_test_unit_infra_lib
  OBJECT
  test_unit.cpp
  )

target_link_libraries(
  cutlass_test_unit_infra_lib
  PUBLIC
  cutlass_test_unit_infra
  )

set(CUTLASS_INSTALL_TESTS ON CACHE BOOL "Install test executables")
set(CUTLASS_TEST_EXECUTION_ENVIRONMENT "" CACHE BOOL "Environment in which to invoke unit test executables")
  
function(cutlass_test_unit_add_executable)

  set(options)
  set(oneValueArgs)
  set(multiValueArgs)
  cmake_parse_arguments(_ "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  cutlass_add_executable(${__UNPARSED_ARGUMENTS})

  list(GET __UNPARSED_ARGUMENTS 0 NAME)

  target_link_libraries(
    ${NAME}
    PRIVATE
    cutlass_test_unit_infra
    cutlass_test_unit_infra_lib
  )

  string(REGEX REPLACE cutlass_ "" NAME_STEM ${NAME})

  add_test(c${NAME_STEM} ${NAME})

  add_custom_target(
    ${NAME_STEM}
    COMMAND
    ${CUTLASS_TEST_EXECUTION_ENVIRONMENT} $<TARGET_FILE:${NAME}>
  DEPENDS
    ${NAME}
    )

  if (CUTLASS_INSTALL_TESTS)

    install(
      TARGETS ${NAME}
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      )

  endif()

endfunction()

add_custom_target(cutlass_test_unit)
add_custom_target(test_unit)

set(SUBDIRS
  core
  gemm
  layout
  transform
  epilogue
  reduction
  )

if(TARGET nvidia::nvrtc AND TARGET nvidia::cuda_driver)
  set(CUTLASS_NVRTC_ENABLE_INIT ON)
else()
  set(CUTLASS_NVRTC_ENABLE_INIT OFF)
endif()  

set(CUTLASS_NVRTC_ENABLE ${CUTLASS_NVRTC_ENABLE_INIT} CACHE BOOL "Enable NVRTC support")

if (CUTLASS_NVRTC_ENABLE)
  list(APPEND SUBDIRS nvrtc)
endif()

foreach(SUBDIR ${SUBDIRS})

  add_subdirectory(${SUBDIR})
  add_dependencies(cutlass_test_unit cutlass_test_unit_${SUBDIR})
  add_dependencies(test_unit test_unit_${SUBDIR})

endforeach()

