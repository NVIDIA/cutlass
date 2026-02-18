if (CUTLASS_NVCC_ARCHS MATCHES 121a)

add_custom_target(
  cutlass_test_unit_gemm_device_sm121_bs
  DEPENDS
  cutlass_test_unit_bs_grouped_gemm_device_tensorop_sm121
)

cutlass_test_unit_gemm_device_add_executable(
  cutlass_test_unit_bs_grouped_gemm_device_tensorop_sm121
  ../sm120_blockscaled_tensorop_gemm/sm120_bs_gemm_mxf8_mxf4_f32_group_gemm_fusion.cu
)

endif()
