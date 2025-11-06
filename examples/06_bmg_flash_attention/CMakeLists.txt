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


set(CUTLASS_APPLICATIONS_DIR ${CMAKE_SOURCE_DIR}/applications)

set(TEST_NO_PAGED "")
set(TEST_PAGED "--use_paged_kv")

foreach(HEAD_DIM 64 96 128 192)
  foreach(INPUT_TYPE bfloat16_t float_e5m2_t float_e4m3_t)
    cutlass_example_add_executable(
      06_xe_fmha_fwd_prefill_${INPUT_TYPE}_hdim${HEAD_DIM}
      06_xe_fmha_fwd.cpp
    )

    cutlass_example_add_executable(
      06_xe_fmha_fwd_decode_${INPUT_TYPE}_hdim${HEAD_DIM}
      06_xe_fmha_fwd.cpp
    )
    if(INPUT_TYPE STREQUAL "bfloat16_t")
      set(INPUT_MACRO "IS_BFLOAT16")
    elseif(INPUT_TYPE STREQUAL "float_e5m2_t")
      set(INPUT_MACRO "IS_FLOAT_E5M2")
    elseif(INPUT_TYPE STREQUAL "float_e4m3_t")
      set(INPUT_MACRO "IS_FLOAT_E4M3")
    endif()

    target_compile_definitions(06_xe_fmha_fwd_prefill_${INPUT_TYPE}_hdim${HEAD_DIM} PRIVATE HEAD_DIM=${HEAD_DIM} PREFILL SHOW_DIFF=1 INPUT_TYPE=${INPUT_TYPE} ${INPUT_MACRO})
    target_compile_definitions(06_xe_fmha_fwd_decode_${INPUT_TYPE}_hdim${HEAD_DIM} PRIVATE HEAD_DIM=${HEAD_DIM} DECODE SHOW_DIFF=1 INPUT_TYPE=${INPUT_TYPE} ${INPUT_MACRO})
  endforeach()

  cutlass_example_add_executable(
    06_bmg_prefill_attention_hdim${HEAD_DIM}
    06_bmg_prefill_attention.cpp
  )

  cutlass_example_add_executable(
    06_bmg_prefill_attention_cachedKV_hdim${HEAD_DIM}
    06_bmg_prefill_attention_prefill_cachedKV.cpp
    TEST_COMMAND_OPTIONS
    TEST_NO_PAGED
    TEST_PAGED
  )

  cutlass_example_add_executable(
    06_bmg_decode_attention_hdim${HEAD_DIM}
    06_bmg_decode_attention.cpp
    TEST_COMMAND_OPTIONS
    TEST_NO_PAGED
    TEST_PAGED
  )
  cutlass_example_add_executable(
    06_bmg_prefill_attention_fp8_hdim${HEAD_DIM}
    06_bmg_prefill_attention_fp8.cpp
    TEST_COMMAND_OPTIONS
  )

  cutlass_example_add_executable(
    06_bmg_decode_attention_fp8_hdim${HEAD_DIM}
    06_bmg_decode_attention_fp8.cpp
    TEST_COMMAND_OPTIONS
    TEST_NO_PAGED
    TEST_PAGED
  )
  target_compile_definitions(06_bmg_prefill_attention_hdim${HEAD_DIM} PRIVATE HEAD_DIM=${HEAD_DIM})
  target_compile_definitions(06_bmg_prefill_attention_cachedKV_hdim${HEAD_DIM} PRIVATE HEAD_DIM=${HEAD_DIM})
  target_compile_definitions(06_bmg_decode_attention_hdim${HEAD_DIM} PRIVATE HEAD_DIM=${HEAD_DIM})
  target_compile_definitions(06_bmg_prefill_attention_fp8_hdim${HEAD_DIM} PRIVATE HEAD_DIM=${HEAD_DIM})
  target_compile_definitions(06_bmg_decode_attention_fp8_hdim${HEAD_DIM} PRIVATE HEAD_DIM=${HEAD_DIM})
endforeach()
