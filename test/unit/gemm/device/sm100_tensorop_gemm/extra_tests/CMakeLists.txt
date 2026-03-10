# Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

if (CUTLASS_NVCC_ARCHS MATCHES 100a)
add_custom_target(
  cutlass_test_unit_gemm_device_sm100_tensorop_extra
  DEPENDS
  cutlass_test_unit_gemm_device_tensorop_runtime_datatype_sm100
  cutlass_test_unit_gemm_device_tensorop_epilogue_fusion_sm100
  cutlass_test_unit_gemm_device_fp8_tensorop_epilogue_fusion_sm100
  cutlass_test_unit_gemm_device_sm100_dense_and_bs_gemm_stage
  cutlass_test_unit_gemm_device_tensorop_stride_batch_alpha_beta_sm100
)

cutlass_test_unit_gemm_device_add_executable_split_file(
  cutlass_test_unit_gemm_device_tensorop_runtime_datatype_sm100

  # No batching of source to control compiler memory usage
  BATCH_SOURCES ON
  BATCH_SIZE 1

  sm100_gemm_f8_f8_f8_tensor_op_f32_runtime_datatype.cu
  sm100_gemm_f6_f6_f32_tensor_op_f32_runtime_datatype.cu
  sm100_gemm_f4_f4_f32_tensor_op_f32_runtime_datatype.cu
  sm100_gemm_f8_f4_f32_tensor_op_f32_runtime_datatype.cu
)

cutlass_test_unit_gemm_device_add_executable_split_file(
  cutlass_test_unit_gemm_device_tensorop_epilogue_fusion_sm100

  # No batching of source to control compiler memory usage
  BATCH_SOURCES ON
  BATCH_SIZE 1

  sm100_gemm_i8_i8_i8_tensor_op_s32_bias_relu.cu
  sm100_gemm_i8_i8_i8_tensor_op_s32_vector_alpha_beta.cu
)

cutlass_test_unit_gemm_device_add_executable_split_file(
  cutlass_test_unit_gemm_device_fp8_tensorop_epilogue_fusion_sm100

  # No batching of source to control compiler memory usage
  BATCH_SOURCES ON
  BATCH_SIZE 1

  sm100_gemm_f8_f8_f8_tensor_op_f32_bias_relu.cu
  sm100_gemm_f8_f8_f8_tensor_op_f32_bias_gelu.cu
  sm100_gemm_f8_f8_f8_tensor_op_f32_bias_gelu_amax_aux.cu
)

cutlass_test_unit_gemm_device_add_executable_split_file(
  cutlass_test_unit_gemm_device_sm100_dense_and_bs_gemm_stage

  BATCH_SOURCES ON
  BATCH_SIZE 1

  sm100_gemm_f8_f8_f32_void_f8_stage.cu
  sm100_gemm_f32_f32_f32_void_f32_stage.cu
)

cutlass_test_unit_gemm_device_add_executable_split_file(
  cutlass_test_unit_gemm_device_tensorop_stride_batch_alpha_beta_sm100

  # No batching of source to control compiler memory usage
  BATCH_SOURCES ON
  BATCH_SIZE 1

  sm100_gemm_f8_f8_f8_tensor_op_s32_batch_alpha_beta.cu
)
endif()
