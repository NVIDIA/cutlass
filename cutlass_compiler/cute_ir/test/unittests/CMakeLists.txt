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

add_custom_target(CutlassCompilerCuteUnitTests)

function(add_cute_ut ARG_TARGET)
  add_cutlass_compiler_ut(${ARG_TARGET} ${ARGN})
  add_dependencies(CutlassCompilerCuteUnitTests ${ARG_TARGET})
  install(TARGETS ${ARG_TARGET}
    RUNTIME DESTINATION test/cutlass_compiler_cute)
  # Expose the unittests/ directory so tests can #include "CuteTest.h".
  target_include_directories(${ARG_TARGET} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
  )
endfunction()

set(_TEST_LIBS
  gtest_main
  # MLIRCuteRegistration transitively brings in MLIRCuteDialect,
  # MLIRArithDialect, and MLIRFuncDialect.
  MLIRCuteRegistration
)

set(_CUTE_UT_TARGETS)
file(GLOB _TEST_SOURCES CONFIGURE_DEPENDS "*Tests.cpp")

foreach(_SRC ${_TEST_SOURCES})
  get_filename_component(_TEST_NAME ${_SRC} NAME_WE)
  add_cute_ut(${_TEST_NAME}
    SRCS ${_SRC}
    LINK_LIBS ${_TEST_LIBS}
  )
  list(APPEND _CUTE_UT_TARGETS ${_TEST_NAME})
endforeach()

# Build one COMMAND entry per binary so each runs in sequence.
set(_RUN_CMDS)
foreach(_TGT ${_CUTE_UT_TARGETS})
  list(APPEND _RUN_CMDS COMMAND $<TARGET_FILE:${_TGT}>)
endforeach()

add_custom_target(check-cute-unittests
  ${_RUN_CMDS}
  DEPENDS ${_CUTE_UT_TARGETS}
  COMMENT "Running Cute dialect unit tests"
  USES_TERMINAL
)
