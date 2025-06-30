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

set(TEST_EXES "")
set(TEST_RUNS "")

foreach(INPUT_TYPE bfloat16_t half_t float_e5m2_t float_e4m3_t)
  set(input_name "cutlass_test_unit_flash_attention_prefill_bf16")
  set(test_name_input "XE_Flash_Attention_Prefill_bf16")
  set(is_bf16 true)
  set(MMAOP MMAOperationBF16)
  set(OUT_TYPE_LIST float)
  if(${INPUT_TYPE} STREQUAL "half_t")
    set(input_name "cutlass_test_unit_flash_attention_prefill_fp16")
    set(is_bf16 false)
    list(APPEND OUT_TYPE_LIST half_t)
    set(test_name_input "XE_Flash_Attention_Prefill_fp16")
    set(MMAOP MMAOperationFP16)
  elseif(${INPUT_TYPE} STREQUAL "float_e5m2_t")
    set(input_name "cutlass_test_unit_flash_attention_prefill_fp8e5m2")
    set(is_bf16 false)
    list(APPEND OUT_TYPE_LIST float_e5m2_t)
    set(test_name_input "XE_Flash_Attention_Prefill_fp8e5m2")
    set(MMAOP MMAOperationFP16)
  elseif(${INPUT_TYPE} STREQUAL "float_e4m3_t")
    set(input_name "cutlass_test_unit_flash_attention_prefill_fp8e4m3")
    set(is_bf16 false)
    list(APPEND OUT_TYPE_LIST float_e4m3_t)
    set(test_name_input "XE_Flash_Attention_Prefill_fp8e4m3")
    set(MMAOP MMAOperationFP16)
  else()
    list(APPEND OUT_TYPE_LIST bfloat16_t)
  endif()

  foreach(OUT_TYPE IN LISTS OUT_TYPE_LIST)
    set(out_name "fp32")
    if(${OUT_TYPE} STREQUAL "bfloat16_t")
      set(out_name "bf16")
    elseif(${OUT_TYPE} STREQUAL "half_t")
      set(out_name "fp16")
    elseif(${OUT_TYPE} STREQUAL "float_e5m2_t")
      set(out_name "fp8e5m2")
    elseif(${OUT_TYPE} STREQUAL "float_e4m3_t")
      set(out_name "fp8e4m3")
    endif()
    set(input_name_out "${input_name}_fp32_${out_name}")
    set(test_name_input_out "${test_name_input}_fp32_${out_name}")
    foreach(HEAD_DIM 64 96 128 192)
      set(out_exe "${input_name_out}_h${HEAD_DIM}_xe")
      set(TEST_NAME "${test_name_input_out}_h${HEAD_DIM}")
      set(SHAPE_H "Shape_h${HEAD_DIM}")
      cutlass_test_unit_add_executable(
        ${out_exe} xe_flash_prefill.cpp
      )
      target_compile_definitions(${out_exe} PRIVATE
                                  INPUT_TYPE=${INPUT_TYPE}
                                  OUT_TYPE=${OUT_TYPE}
                                  TEST_NAME=${TEST_NAME}
                                  HEAD_DIM=${HEAD_DIM}
                                  SHAPE_H=${SHAPE_H}
                                  MMAOP=${MMAOP})
      list(APPEND TEST_EXES ${out_exe})
      string(REGEX REPLACE cutlass_ "" out_exe_snipped ${out_exe})
      list(APPEND TEST_RUNS ${out_exe_snipped})
    endforeach()
  endforeach()
endforeach()

add_custom_target(
  cutlass_test_unit_flash_attention_prefill
  DEPENDS
  ${TEST_EXES}
)

add_custom_target(
  test_unit_flash_attention_prefill
  DEPENDS
  ${TEST_RUNS}
)
