# Copyright (c) 2017 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# Copyright (c) 2025 INTEL CORPORATION. All rights reserved.
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

if(CUTLASS_ENABLE_SYCL)
  if(SYCL_INTEL_TARGET)
    cutlass_test_unit_add_executable(
      cutlass_test_unit_gemm_device_tensorop_xe
      xe_gemm_bf16_bf16_bf16_tensor_op_bf16.cpp
      xe_gemm_fp16_fp16_fp16_tensor_op_fp16.cpp
      xe_gemm_bf16_bf16_bf16_tensor_op_fp32.cpp
      xe_gemm_bf16_bf16_fp32_tensor_op_bf16.cpp
      xe_gemm_bf16_bf16_fp32_tensor_op_fp32.cpp
      xe_gemm_fp16_fp16_fp16_tensor_op_fp32.cpp
      xe_gemm_fp16_fp16_fp32_tensor_op_fp32.cpp
      xe_gemm_s8_s8_s32_tensor_op_s32.cpp
      xe_gemm_tf32_tf32_fp32_tensor_op_fp32.cpp
      xe_gemm_f8_f8_fp32_tensor_op_fp32.cpp
      xe_gemm_fp16_s8_fp32_tensor_op_fp32.cpp
      gemm_universal_bf16n_bf16t_f32n_tensor_op_f32_xe.cpp
      gemm_universal_fp8_fp8_fp32_tensor_op_f32_xe_models.cpp
    )

    cutlass_test_unit_add_executable(
      cutlass_test_unit_gemm_device_tensorop_cooperative_xe
      xe_gemm_bf16_bf16_fp32_tensor_op_fp32_cooperative.cpp
      xe_gemm_fp16_fp16_fp32_tensor_op_fp32_cooperative.cpp
      # TODO (Codeplay): fix gemm cooperative tests for s8 and tf32
      # xe_gemm_s8_s8_s32_tensor_op_s32_cooperative.cpp
      # xe_gemm_tf32_tf32_fp32_tensor_op_fp32_cooperative.cpp
    )

    cutlass_test_unit_add_executable(
      cutlass_test_unit_gemm_device_tensorop_epilogue_fusion_xe
      xe_gemm_bf16_bf16_fp32_tensor_op_fp32_evt.cpp
    )

    cutlass_test_unit_add_executable(
      cutlass_test_unit_gemm_device_mixed_input_tensorop_xe
      gemm_universal_s8t_bf16n_f32t_mixed_input_tensor_op_f32_xe.cpp
      gemm_universal_f16t_s4t_f32t_mixed_input_tensor_op_f32_xe.cpp
      gemm_universal_f16t_s4n_f32t_mixed_input_tensor_op_f32_xe.cpp
    )

    # Group Gemm test
    cutlass_test_unit_add_executable(
      cutlass_test_unit_gemm_device_tensorop_xe_group_gemm
      xe_gemm_bf16_bf16_fp32_tensor_op_fp32_group_gemm.cpp
      xe_gemm_bf16_bf16_bf16_tensor_op_fp32_group_gemm.cpp
      xe_gemm_fp16_fp16_fp32_tensor_op_fp32_group_gemm.cpp
      xe_gemm_fp16_fp16_fp16_tensor_op_fp32_group_gemm.cpp
    )

    cutlass_test_unit_add_executable(
      cutlass_test_unit_gemm_device_mixed_dtype_tensorop_xe_group_gemm
      xe_gemm_bf16_s8_fp32_tensor_op_fp32_group_gemm.cpp
      xe_gemm_fp16_s8_fp32_tensor_op_fp32_group_gemm.cpp
      xe_gemm_bf16_u4_fp32_tensor_op_fp32_group_gemm.cpp
      xe_gemm_fp16_u4_fp32_tensor_op_fp32_group_gemm.cpp
      xe_gemm_fp16_fp8_fp32_tensor_op_fp32_group_gemm.cpp
    )

    add_custom_target(
      cutlass_test_unit_gemm_device
      DEPENDS
      cutlass_test_unit_gemm_device_tensorop_xe
      cutlass_test_unit_gemm_device_tensorop_cooperative_xe
      cutlass_test_unit_gemm_device_tensorop_epilogue_fusion_xe
      cutlass_test_unit_gemm_device_mixed_input_tensorop_xe
      cutlass_test_unit_gemm_device_tensorop_xe_group_gemm
      cutlass_test_unit_gemm_device_mixed_dtype_tensorop_xe_group_gemm
      cutlass_test_unit_gemm_device_tensorop_xe
    )

    add_custom_target(
      test_unit_gemm_device
      DEPENDS
      test_unit_gemm_device_tensorop_xe
      test_unit_gemm_device_tensorop_cooperative_xe
      test_unit_gemm_device_tensorop_epilogue_fusion_xe
      test_unit_gemm_device_mixed_input_tensorop_xe
      test_unit_gemm_device_tensorop_xe_group_gemm
      test_unit_gemm_device_mixed_dtype_tensorop_xe_group_gemm
    )
  else()
    # Dummy targets if not building for Intel
    add_custom_target(cutlass_test_unit_gemm_device)
    add_custom_target(test_unit_gemm_device)
  endif()
endif()
