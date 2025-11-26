# Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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

if(NOT DEFINED IGC_VERSION_MAJOR)
  set(IGC_VERSION_MAJOR 2)
endif()
if(NOT DEFINED IGC_VERSION_MINOR)
  set(IGC_VERSION_MINOR 18)
endif()

add_compile_definitions(
    IGC_VERSION_MAJOR=${IGC_VERSION_MAJOR}
    IGC_VERSION_MINOR=${IGC_VERSION_MINOR}
)

if(SYCL_INTEL_TARGET)
cutlass_test_unit_add_executable(
  cutlass_test_unit_cute_intel_xe
  copy_1d.cpp
  copy_subgroup_block.cpp
  copy_block.cpp
  copy_scatter.cpp
  mma.cpp
  tiled_mma.cpp
  xe_copy_2d_test.cpp
  xe_copy_prefetch_2d.cpp
  xe_vnni_2d.cpp
  xe_transpose_2d.cpp
)
else()
cutlass_test_unit_add_executable(
  cutlass_test_unit_cute_intel_xe
)
endif()
