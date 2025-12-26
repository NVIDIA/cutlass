# Copyright (c) 2017 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# Copyright (C) 2025 Intel Corporation, All rights reserved.
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


set(CUTLASS_EXAMPLES_COMMON_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/common)

add_custom_target(cutlass_examples)
add_custom_target(test_examples)

function(cutlass_example_add_executable NAME)

  set(options)
  set(oneValueArgs DISABLE_TESTS)
  set(multiValueArgs DEPENDS DEPENDEES TEST_COMMAND_OPTIONS)
  cmake_parse_arguments(_ "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if (NOT DEFINED __DISABLE_TESTS)
    set(__DISABLE_TESTS OFF)
  endif()

  cutlass_add_executable(${NAME} ${__UNPARSED_ARGUMENTS} BATCH_SOURCES OFF)

  add_dependencies(cutlass_examples ${NAME})

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
    )

  target_include_directories(
    ${NAME}
    PRIVATE
    ${CUTLASS_EXAMPLES_COMMON_SOURCE_DIR}
    ${CUTLASS_EXAMPLES_UTILS_DIR}
    ${CUTLASS_APPLICATIONS_DIR}
    )

  if (CUTLASS_ENABLE_SYCL)
    add_onemkl_to_target(TARGET ${NAME})
    add_sycl_to_target(TARGET ${NAME})
  endif()

  install(
    TARGETS ${NAME}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )

  cutlass_add_executable_tests(
    test_examples_${NAME} ${NAME}
    DEPENDS ${__DEPENDS}
    DEPENDEES test_examples ${__DEPENDEES}
    TEST_COMMAND_OPTIONS ${__TEST_COMMAND_OPTIONS}
    DISABLE_EXECUTABLE_INSTALL_RULE
    DISABLE_TESTS ${__DISABLE_TESTS}
    )

endfunction()

# =============================================================================
# CUTLASS SYCL Examples
# =============================================================================
# This CMakeLists.txt builds SYCL-based examples for CUTLASS.

if(CUTLASS_ENABLE_SYCL)
  message(STATUS "Building CUTLASS SYCL Examples")
  if(SYCL_INTEL_TARGET)
    message(STATUS "Building examples for Intel GPU targets")
    foreach(EXAMPLE
      00_bmg_gemm
      00_bmg_gemm/legacy
      01_bmg_gemm_with_collective_builder
      02_bmg_gemm_mixed_dtype
      02_bmg_gemm_mixed_dtype/legacy
      03_bmg_gemm_streamk
      03_bmg_gemm_streamk/legacy
      04_bmg_grouped_gemm
      04_bmg_grouped_gemm/legacy
      05_bmg_gemm_with_epilogues
      05_bmg_gemm_with_epilogues/legacy
      06_bmg_flash_attention
      07_bmg_dual_gemm
      08_bmg_gemm_f8
      09_bmg_grouped_gemm_f8
      09_bmg_grouped_gemm_f8/legacy
      10_bmg_grouped_gemm_mixed_dtype
      11_xe20_cutlass_library
      12_xe20_moe_gemm_cute_interface
      )
      add_subdirectory(${EXAMPLE})
    endforeach()
  endif()
  add_subdirectory(generics)
  add_subdirectory(nv_sycl)
  add_subdirectory(cute)
else()
  message(STATUS "CUTLASS_ENABLE_SYCL is OFF - no examples will be built")
  message(STATUS "Enable SYCL support to build CUTLASS examples")
endif()

