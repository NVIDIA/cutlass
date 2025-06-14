# Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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


add_custom_target(cutlass_benchmarks)
add_custom_target(benchmarks)


function(cutlass_benchmark_add_suite NAME)

  set(options)
  set(oneValueArgs SUPERSUITE)
  set(multiValueArgs)
  cmake_parse_arguments(_ "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  string(REGEX REPLACE cutlass_ "" NAME_STEM ${NAME})
  add_custom_target(${NAME})
  add_custom_target(${NAME_STEM})

  if(DEFINED __SUPERSUITE)
    string(REGEX REPLACE cutlass_ "" SUPERSUITE_STEM ${__SUPERSUITE})
    add_dependencies(${__SUPERSUITE} ${NAME})
    add_dependencies(${SUPERSUITE_STEM} ${NAME_STEM})
  else()
    add_dependencies(cutlass_benchmarks ${NAME})
    add_dependencies(benchmarks ${NAME_STEM})
  endif()
endfunction()

function(cutlass_benchmark_add_executable NAME)

  set(options)
  set(oneValueArgs DISABLE_TESTS SUITE)
  set(multiValueArgs DEPENDS DEPENDEES TEST_COMMAND_OPTIONS LIBRARIES INCLUDES)
  cmake_parse_arguments(_ "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT DEFINED __SUITE)
    message(FATAL_ERROR "Missing required benchmark suite (SUITE)")
  endif()

  set(__DISABLE_TESTS ON)

  cutlass_add_executable(${NAME} ${__UNPARSED_ARGUMENTS} BATCH_SOURCES OFF)

  if (NOT CUTLASS_ENABLE_SYCL)
    SET(ADD_CUDA ON)
  endif()

  target_link_libraries(
    ${NAME}
    PRIVATE
    CUTLASS
    cutlass_tools_util_includes
    $<$<BOOL:${CUTLASS_ENABLE_CUBLAS}>:nvidia::cublas>
    $<$<BOOL:${ADD_CUDA}>:cuda>
    benchmark::benchmark
    ${__LIBRARIES}
  )

  target_include_directories(
    ${NAME}
    PRIVATE
    ${CUTLASS_APPLICATIONS_DIR}
    ${__INCLUDES}
  )

  if (CUTLASS_ENABLE_SYCL)
    add_onemkl_to_target(TARGET ${NAME})
    add_sycl_to_target(TARGET ${NAME})
  endif()

  string(REGEX REPLACE cutlass_ "" NAME_STEM ${NAME})
  string(REGEX REPLACE cutlass_ "" SUITE_STEM ${__SUITE})

  add_dependencies(${__SUITE} ${NAME})
  add_dependencies(${SUITE_STEM} ${NAME_STEM})

  cutlass_add_executable_tests(
    ${NAME_STEM} ${NAME}
    DEPENDS ${__DEPENDS}
    DEPENDEES ${__DEPENDEES}
    TEST_COMMAND_OPTIONS ${__TEST_COMMAND_OPTIONS}
    )

  install(
    TARGETS ${NAME}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  )
endfunction()

set(SUBDIRS gemm)

if(SYCL_INTEL_TARGET)
  list(APPEND SUBDIRS flash_attention)
endif()

foreach(SUBDIR ${SUBDIRS})

  add_subdirectory(${SUBDIR})

endforeach()
