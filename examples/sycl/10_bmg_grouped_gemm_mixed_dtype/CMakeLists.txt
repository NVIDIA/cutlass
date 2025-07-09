# Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
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

set(TEST_GROUPS --groups=2)
set(TEST_MODE_1 --groups=2 --mode=1)
set(TEST_MODE_0 --groups=2 --mode=0)
set(TEST_A_NARROW --groups=2 --a_narrower)
set(TEST_GROUP_DEQUANT --g=128)

set(MMA_T bfloat16_t half_t)
set(QUANT_T int8_t)
set(EXE_LIST "")

foreach(MMA_TYPE IN LISTS MMA_T)
  set(mma_name "10_bmg_grouped_gemm_bf16")
  if(${MMA_TYPE} STREQUAL "half_t")
    set(mma_name "10_bmg_grouped_gemm_f16")
  endif()
  foreach(QUANT_TYPE IN LISTS QUANT_T)
    set(exe_name "${mma_name}_s8")
    if(${MMA_TYPE} STREQUAL "half_t" AND ${QUANT_TYPE} STREQUAL "int8_t")
      set(exe_name "${mma_name}_s8_tensorwise")
      set(TEST_GROUP_DEQUANT --g=0)
    endif()

    cutlass_example_add_executable(
      ${exe_name}
      10_bmg_grouped_gemm_bf16_f16_s8.cpp
      TEST_COMMAND_OPTIONS
      TEST_GROUPS
      TEST_MODE_1
      TEST_MODE_0
      TEST_A_NARROW
      TEST_GROUP_DEQUANT
    )
    list(APPEND EXE_LIST ${exe_name})
    target_compile_definitions(${exe_name} PRIVATE MMA_TYPE=${MMA_TYPE} QUANT_TYPE=${QUANT_TYPE})
  endforeach()
endforeach()

cutlass_example_add_executable(
  10_bmg_grouped_gemm_f16_u4
  10_bmg_grouped_gemm_f16_u4.cpp
  TEST_COMMAND_OPTIONS
  TEST_GROUPS
  TEST_MODE_1
  TEST_MODE_0
  TEST_A_NARROW
  TEST_GROUP_DEQUANT
)

if(NOT DPCPP_SYCL_TARGET STREQUAL "spir64")
  # TODO(codeplay): Remove these once IGC block load loop hoisting bug is fixed
  foreach(target_exe IN LISTS EXE_LIST)
    target_link_options(${target_exe} PRIVATE -Xs "-options \"-igc_opts 'allowDecompose2DBlockFuncs=0'\"" )
  endforeach()
  target_link_options(10_bmg_grouped_gemm_f16_u4 PRIVATE -Xs "-options \"-igc_opts 'allowDecompose2DBlockFuncs=0'\"" )
endif()
