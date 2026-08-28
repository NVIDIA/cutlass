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

if (NOT MSVC)

# Cover exact, partial-stage, and stage-boundary K tails.
set(TEST_K_288  --m=256 --k=288  --batch=1 --epilogue_st=1.0 --profiling=false)
set(TEST_K_1024 --m=256 --k=1024 --batch=1 --epilogue_st=1.0 --profiling=false)
set(TEST_K_1056 --m=256 --k=1056 --batch=1 --epilogue_st=1.0 --profiling=false)
set(TEST_K_1152 --m=256 --k=1152 --batch=1 --epilogue_st=1.0 --profiling=false)
set(TEST_K_1280 --m=256 --k=1280 --batch=1 --epilogue_st=1.0 --profiling=false)
set(TEST_K_1312 --m=256 --k=1312 --batch=1 --epilogue_st=1.0 --profiling=false)
set(TEST_K_2048 --m=256 --k=2048 --batch=1 --epilogue_st=1.0 --profiling=false)
set(TEST_K_2176 --m=256 --k=2176 --batch=1 --epilogue_st=1.0 --profiling=false)

cutlass_example_add_executable(
  91_fp4_gemv
  91_fp4_gemv.cu
  TEST_COMMAND_OPTIONS
  TEST_K_288
  TEST_K_1024
  TEST_K_1056
  TEST_K_1152
  TEST_K_1280
  TEST_K_1312
  TEST_K_2048
  TEST_K_2176
)

endif()
