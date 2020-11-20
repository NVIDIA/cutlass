# Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright notice, this list of
#       conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice, this list of
#       conditions and the following disclaimer in the documentation and/or other materials
#       provided with the distribution.
#     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
#       to endorse or promote products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 add_custom_target(
  cutlass_test_unit_conv_device
  DEPENDS
  cutlass_test_unit_conv_device_simt
  cutlass_test_unit_conv_device_tensorop_f32_sm70
  cutlass_test_unit_conv_device_tensorop_f32_sm75
  cutlass_test_unit_conv_device_tensorop_f16_sm80
  cutlass_test_unit_conv_device_tensorop_f32_sm80
  cutlass_test_unit_conv_device_tensorop_f32_tf32_sm80
  cutlass_test_unit_conv_device_tensorop_s32
  cutlass_test_unit_conv_device_tensorop_s32_interleaved
)

 add_custom_target(
  test_unit_conv_device
  DEPENDS
  test_unit_conv_device_simt
  test_unit_conv_device_tensorop_f32_sm70
  test_unit_conv_device_tensorop_f32_sm75
  test_unit_conv_device_tensorop_f16_sm80
  test_unit_conv_device_tensorop_f32_sm80
  test_unit_conv_device_tensorop_f32_tf32_sm80
  test_unit_conv_device_tensorop_s32
  test_unit_conv_device_tensorop_s32_interleaved
)

#
# OpClassSimt (CUDA cores)
#

cutlass_test_unit_add_executable(
  cutlass_test_unit_conv_device_simt
  
  # F32  
  conv2d_fprop_implicit_gemm_f32nhwc_f32nhwc_f32nhwc_simt_f32_sm50.cu

  conv2d_fprop_implicit_gemm_f32nhwc_f32nhwc_f32nhwc_simt_f32_sm80.cu
  conv2d_dgrad_implicit_gemm_f32nhwc_f32nhwc_f32nhwc_simt_f32_sm80.cu
  conv2d_wgrad_implicit_gemm_f32nhwc_f32nhwc_f32nhwc_simt_f32_sm80.cu

  # CF32
  conv2d_fprop_implicit_gemm_cf32nhwc_cf32nhwc_cf32nhwc_simt_f32_sm50.cu
  conv2d_dgrad_implicit_gemm_cf32nhwc_cf32nhwc_cf32nhwc_simt_f32_sm50.cu
  conv2d_wgrad_implicit_gemm_cf32nhwc_cf32nhwc_cf32nhwc_simt_f32_sm50.cu 
  
  conv2d_fprop_implicit_gemm_cf32nhwc_cf32nhwc_cf32nhwc_simt_f32_sm80.cu
  conv2d_dgrad_implicit_gemm_cf32nhwc_cf32nhwc_cf32nhwc_simt_f32_sm80.cu
  conv2d_wgrad_implicit_gemm_cf32nhwc_cf32nhwc_cf32nhwc_simt_f32_sm80.cu
)

#
# OpClassTensorOp (Tensor cores)
#

# Conv - F16 input, F32 output, F32 accumulation
cutlass_test_unit_add_executable(
  cutlass_test_unit_conv_device_tensorop_f32_sm70
  
  conv2d_fprop_implicit_gemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_sm70.cu
  conv2d_dgrad_implicit_gemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_sm70.cu
  conv2d_wgrad_implicit_gemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_sm70.cu
)

# Conv2d - F16 input, F32 output, F32 accumulation - SM75
cutlass_test_unit_add_executable(
  cutlass_test_unit_conv_device_tensorop_f32_sm75

  conv2d_fprop_implicit_gemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_sm75.cu
  conv2d_dgrad_implicit_gemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_sm75.cu
  conv2d_wgrad_implicit_gemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_sm75.cu
)

# Conv2d - F16 input, F16 output, F16 accumulation 
cutlass_test_unit_add_executable(
  cutlass_test_unit_conv_device_tensorop_f16_sm80

  conv2d_fprop_implicit_gemm_f16nhwc_f16nhwc_f16nhwc_tensor_op_f16_sm80.cu
  conv2d_dgrad_implicit_gemm_f16nhwc_f16nhwc_f16nhwc_tensor_op_f16_sm80.cu 
  conv2d_wgrad_implicit_gemm_f16nhwc_f16nhwc_f16nhwc_tensor_op_f16_sm80.cu 
)

# Conv2d - F16 input, F32 output, F32 accumulation
cutlass_test_unit_add_executable(
  cutlass_test_unit_conv_device_tensorop_f32_sm80


  conv2d_fprop_implicit_gemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_sm80.cu
  conv2d_dgrad_implicit_gemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_sm80.cu
  conv2d_wgrad_implicit_gemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_sm80.cu

  conv3d_wgrad_implicit_gemm_f16ndhwc_f16ndhwc_f32ndhwc_tensor_op_f32_sm75.cu
  conv3d_wgrad_implicit_gemm_f16ndhwc_f16ndhwc_f32ndhwc_tensor_op_f32_sm80.cu
)

# Conv2d - TF32 input, F32 output, F32 accumulation
cutlass_test_unit_add_executable(
  cutlass_test_unit_conv_device_tensorop_f32_tf32_sm80

  conv2d_fprop_implicit_gemm_tf32nhwc_tf32nhwc_f32nhwc_tensor_op_f32_sm80.cu
  conv2d_dgrad_implicit_gemm_tf32nhwc_tf32nhwc_f32nhwc_tensor_op_f32_sm80.cu
  conv2d_wgrad_implicit_gemm_tf32nhwc_tf32nhwc_f32nhwc_tensor_op_f32_sm80.cu

  conv3d_fprop_implicit_gemm_tf32ndhwc_tf32ndhwc_f32ndhwc_tensor_op_f32_sm80.cu
  conv3d_dgrad_implicit_gemm_tf32ndhwc_tf32ndhwc_f32ndhwc_tensor_op_f32_sm80.cu
  conv3d_wgrad_implicit_gemm_tf32ndhwc_tf32ndhwc_f32ndhwc_tensor_op_f32_sm80.cu
)

# Conv2d - S8 input, S32 output, S32 accumulation
cutlass_test_unit_add_executable(
  cutlass_test_unit_conv_device_tensorop_s32

  conv2d_fprop_implicit_gemm_s8nhwc_s8nhwc_s32nhwc_tensor_op_s32_sm75.cu
  conv2d_fprop_implicit_gemm_s4nhwc_s4nhwc_s32nhwc_tensor_op_s32_sm75.cu
  conv2d_fprop_implicit_gemm_s8nhwc_s8nhwc_s32nhwc_tensor_op_s32_sm80.cu
  conv2d_fprop_implicit_gemm_s4nhwc_s4nhwc_s32nhwc_tensor_op_s32_sm80.cu
)

# Conv2d - S8 interleaved input, S8 interleaved output, S32 accumulation
cutlass_test_unit_add_executable(
  cutlass_test_unit_conv_device_tensorop_s32_interleaved

  conv2d_fprop_implicit_gemm_s8ncxhwx_s8cxrskx_s8ncxhwx_tensor_op_s32_sm75.cu
  conv2d_fprop_implicit_gemm_s4ncxhwx_s4cxrskx_s4ncxhwx_tensor_op_s32_sm75.cu
  conv2d_fprop_implicit_gemm_s8ncxhwx_s8cxrskx_s8ncxhwx_tensor_op_s32_sm80.cu
  conv2d_fprop_implicit_gemm_s4ncxhwx_s4cxrskx_s4ncxhwx_tensor_op_s32_sm80.cu
)
