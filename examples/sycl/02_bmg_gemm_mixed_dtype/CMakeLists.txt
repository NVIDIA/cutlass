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

set(TEST_BATCHES --l=2)
set(TEST_MODE_1 --l=2 --mode=1)
set(TEST_MODE_0 --l=2 --mode=0)
set(TEST_A_NARROW --l=2 --a_narrower)

cutlass_example_add_executable(
  02_bmg_gemm_bf16_s8
  02_bmg_gemm_bf16_s8.cpp
  TEST_COMMAND_OPTIONS
  TEST_BATCHES
  TEST_MODE_1
  TEST_MODE_0
  TEST_A_NARROW
)

cutlass_example_add_executable(
  02_bmg_gemm_f16_u4
  02_bmg_gemm_f16_u4.cpp
  TEST_COMMAND_OPTIONS
  TEST_BATCHES
  TEST_MODE_1
  TEST_MODE_0
  #TEST_A_NARROW
)

if(NOT DPCPP_SYCL_TARGET STREQUAL "spir64")
  # TODO(codeplay): Remove these once IGC block load loop hoisting bug is fixed
  target_link_options( 02_bmg_gemm_bf16_s8 PRIVATE -Xs "-options \"-igc_opts 'allowDecompose2DBlockFuncs=0'\"" )
  target_link_options( 02_bmg_gemm_f16_u4 PRIVATE -Xs "-options \"-igc_opts 'allowDecompose2DBlockFuncs=0'\"" )
endif()
