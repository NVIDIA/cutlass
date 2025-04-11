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

cutlass_example_add_executable(
  05_pvc_gemm_with_epilogue_gelu
  05_pvc_gemm_with_epilogue_gelu.cpp
  TEST_COMMAND_OPTIONS
  TEST_BATCHES
)

#TODO(Codeplay): enable batch > 1 test once implementation is fixed.
cutlass_example_add_executable(
  05_pvc_gemm_with_epilogue_lincombdeeltact
  05_pvc_gemm_with_epilogue_lincombdeeltact.cpp
)

cutlass_example_add_executable(
  05_pvc_gemm_with_epilogue_relu
  05_pvc_gemm_with_epilogue_relu.cpp
  TEST_COMMAND_OPTIONS
  TEST_BATCHES
)

#TODO(Codeplay): enable batch > 1 test once implementation is fixed.
cutlass_example_add_executable(
  05_pvc_gemm_with_epilogue_softmax
  05_pvc_gemm_with_epilogue_softmax.cpp
)

cutlass_example_add_executable(
  05_pvc_gemm_with_per_row_bias
  05_pvc_gemm_with_per_row_bias.cpp
  TEST_COMMAND_OPTIONS
  TEST_BATCHES
)

cutlass_example_add_executable(
  05_pvc_gemm_with_per_col_bias
  05_pvc_gemm_with_per_col_bias.cpp
  TEST_COMMAND_OPTIONS
  TEST_BATCHES
)

cutlass_example_add_executable(
  05_pvc_gemm_with_topk_and_softmax
  05_pvc_gemm_with_topk_and_softmax.cpp
  TEST_COMMAND_OPTIONS
  TEST_BATCHES
)
