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

include(CTest)
enable_testing()

if (${CXX_SUPPORTS_WERROR_GLOBAL_CONSTRUCTOR})
  append("-Wno-global-constructors" CMAKE_CXX_FLAGS)
endif()

file(GLOB _TEST_SOURCES "*_test.cpp")
set(_CUTEGEN_UT_TARGETS)
foreach(_SRC ${_TEST_SOURCES})
  get_filename_component(_TEST_NAME ${_SRC} NAME_WE)
  add_executable(${_TEST_NAME} ${_SRC})
  target_link_libraries(${_TEST_NAME} cutegen gtest gtest_main)
  add_test(NAME "cutegen/${_TEST_NAME}" COMMAND ${_TEST_NAME})
  install(TARGETS ${_TEST_NAME} DESTINATION test/cutlass_compiler_cutegen)
  list(APPEND _CUTEGEN_UT_TARGETS ${_TEST_NAME})
endforeach()

# Convenience target to run all cutegen google tests in one command
add_executable(cutegen_all_tests EXCLUDE_FROM_ALL ${_TEST_SOURCES})
target_link_libraries(cutegen_all_tests cutegen gtest gtest_main)

# Aggregate ctest-style runner — one COMMAND per test binary so each
# runs in sequence under the umbrella `check-cutlass-all`.
set(_RUN_CMDS)
foreach(_TGT ${_CUTEGEN_UT_TARGETS})
  list(APPEND _RUN_CMDS COMMAND $<TARGET_FILE:${_TGT}>)
endforeach()

add_custom_target(check-cutegen-unittests
  ${_RUN_CMDS}
  DEPENDS ${_CUTEGEN_UT_TARGETS}
  COMMENT "Running cutegen unit tests"
  USES_TERMINAL
)
set_target_properties(check-cutegen-unittests PROPERTIES FOLDER "Tests")
