# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

if (CUTLASS_NVCC_ARCHS MATCHES "120a|120f|121a")
  cutlass_test_unit_gemm_device_add_executable(
    cutlass_test_unit_gemm_device_sm120_nvfp4_w4a16
    sm120_nvfp4_w4a16.cu
  )
endif()
