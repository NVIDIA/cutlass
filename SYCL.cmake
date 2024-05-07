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

function(cutlass_add_library NAME)
  set(options SKIP_GENCODE_FLAGS)
  set(oneValueArgs EXPORT_NAME)
  set(multiValueArgs)
  cmake_parse_arguments(_ "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(TARGET_SOURCE_ARGS ${__UNPARSED_ARGUMENTS})
  set(${TARGET_ARGS_VAR} ${TARGET_SOURCE_ARGS} PARENT_SCOPE)

  add_library(${NAME} ${TARGET_SOURCE_ARGS} "")

  cutlass_apply_standard_compile_options(${NAME})

  target_compile_features(
    ${NAME}
    INTERFACE
    cxx_std_17
  )

  get_target_property(TARGET_TYPE ${NAME} TYPE)

  if(__EXPORT_NAME)
    add_library(nvidia::cutlass::${__EXPORT_NAME} ALIAS ${NAME})
    set_target_properties(${NAME} PROPERTIES EXPORT_NAME ${__EXPORT_NAME})
  endif()
endfunction()

function(cutlass_add_executable NAME)
  set(options)
  set(oneValueArgs BATCH_SOURCES)
  set(multiValueArgs)
  cmake_parse_arguments(_ "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(TARGET_SOURCE_ARGS ${__UNPARSED_ARGUMENTS})
  set(${TARGET_ARGS_VAR} ${TARGET_SOURCE_ARGS} PARENT_SCOPE)

  add_executable(${NAME} ${TARGET_SOURCE_ARGS})

  cutlass_apply_standard_compile_options(${NAME})
  target_compile_features(
    ${NAME}
    INTERFACE
    cxx_std_11
  )
endfunction()
