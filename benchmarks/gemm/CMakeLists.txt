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

# Pass these configuration files for the CI
set(CONFIG_FILE_INTEL_DEFAULT --config_file=${CMAKE_SOURCE_DIR}/benchmarks/device/pvc/input_files/input_gemm.in)
set(CONFIG_FILE_INTEL_LINEAR --config_file=${CMAKE_SOURCE_DIR}/benchmarks/device/pvc/input_files/input_linear.in)
set(CONFIG_FILE_INTEL_PYTORCH --config_file=${CMAKE_SOURCE_DIR}/benchmarks/device/pvc/input_files/input_pytorch_2.in)
set(CONFIG_FILE_INTEL_SGLANG --config_file=${CMAKE_SOURCE_DIR}/benchmarks/device/bmg/input_files/input_sglang_gemm.in)
set(CONFIG_FILE_INTEL_SGLANG_SPLITK --config_file=${CMAKE_SOURCE_DIR}/benchmarks/device/bmg/input_files/input_sglang_gemm_splitk.in)

set(CONFIG_FILE_CUDA --config_file=${CMAKE_SOURCE_DIR}/benchmarks/device/ampere/input_files/input_gemm.in)

set(CONFIG_FILE_INTEL_MIXED_DTYPE --config_file=${CMAKE_SOURCE_DIR}/benchmarks/device/bmg/input_files/input_sglang_gemm_mixed_dtype.in)

cutlass_benchmark_add_suite(cutlass_benchmarks_gemm)

if(CUTLASS_ENABLE_SYCL)

if(SYCL_INTEL_TARGET)

cutlass_benchmark_add_executable(
    cutlass_benchmarks_gemm_sycl
    main.cpp
    SUITE cutlass_benchmarks_gemm
    TEST_COMMAND_OPTIONS
    CONFIG_FILE_INTEL_DEFAULT
    # CONFIG_FILE_INTEL_LINEAR
    CONFIG_FILE_INTEL_PYTORCH
    CONFIG_FILE_INTEL_SGLANG
    CONFIG_FILE_INTEL_SGLANG_SPLITK
    CONFIG_FILE_INTEL_MIXED_DTYPE
)

else()
cutlass_benchmark_add_executable(
    cutlass_benchmarks_gemm_sycl
    main.cpp
    SUITE cutlass_benchmarks_gemm
    TEST_COMMAND_OPTIONS
    CONFIG_FILE_CUDA
)
endif()

else()

cutlass_benchmark_add_executable(
    cutlass_benchmarks_gemm_cuda
    main.cu
    SUITE cutlass_benchmarks_gemm
    TEST_COMMAND_OPTIONS
    CONFIG_FILE_CUDA
)

endif()
