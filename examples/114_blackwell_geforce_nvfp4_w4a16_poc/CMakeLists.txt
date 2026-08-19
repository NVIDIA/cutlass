# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

set(_CUTLASS_114_ARCH_REGEX "120a|120f|121a")

if (CUTLASS_NVCC_ARCHS MATCHES "${_CUTLASS_114_ARCH_REGEX}")
  cutlass_example_add_executable(
    114_sm120_nvfp4_w4a16_poc
    114_sm120_nvfp4_w4a16_poc.cu
  )

  cutlass_example_add_executable(
    114b_sm120_nvfp4_w4a16_cute_pipeline
    114b_sm120_nvfp4_w4a16_cute_pipeline.cu
  )
endif()
