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

cutlass_test_unit_add_executable(
  cutlass_test_unit_flash_attention_prefill_cachedkv_64_xe
  xe_flash_prefill_cachedkv_bf16_fp32_fp32_64.cpp
  xe_flash_prefill_cachedkv_fp16_fp32_fp32_64.cpp
)

cutlass_test_unit_add_executable(
  cutlass_test_unit_flash_attention_prefill_cachedkv_96_xe
  xe_flash_prefill_cachedkv_bf16_fp32_fp32_96.cpp
  xe_flash_prefill_cachedkv_fp16_fp32_fp32_96.cpp
)

cutlass_test_unit_add_executable(
  cutlass_test_unit_flash_attention_prefill_cachedkv_128_xe
  xe_flash_prefill_cachedkv_bf16_fp32_fp32_128.cpp
  xe_flash_prefill_cachedkv_fp16_fp32_fp32_128.cpp
)

cutlass_test_unit_add_executable(
  cutlass_test_unit_flash_attention_prefill_cachedkv_192_xe
  xe_flash_prefill_cachedkv_bf16_fp32_fp32_192.cpp
  xe_flash_prefill_cachedkv_fp16_fp32_fp32_192.cpp
)

add_custom_target(
  cutlass_test_unit_flash_attention_prefill_cachedkv
  DEPENDS
  cutlass_test_unit_flash_attention_prefill_cachedkv_64_xe
  cutlass_test_unit_flash_attention_prefill_cachedkv_96_xe
  cutlass_test_unit_flash_attention_prefill_cachedkv_128_xe
  cutlass_test_unit_flash_attention_prefill_cachedkv_192_xe
)

add_custom_target(
  test_unit_flash_attention_prefill_cachedkv
  DEPENDS
  test_unit_flash_attention_prefill_cachedkv_64_xe
  test_unit_flash_attention_prefill_cachedkv_96_xe
  test_unit_flash_attention_prefill_cachedkv_128_xe
  test_unit_flash_attention_prefill_cachedkv_192_xe
)
