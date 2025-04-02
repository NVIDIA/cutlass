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

include(FetchContent)

set(GOOGLEBENCHMARK_DIR "" CACHE STRING "Location of local GoogleBenchmark repo to build against")
set(BENCHMARK_ENABLE_ASSEMBLY_TESTS OFF)

if(GOOGLEBENCHMARK_DIR)
  set(FETCHCONTENT_SOURCE_DIR_GOOGLEBENCHMARK ${GOOGLEBENCHMARK_DIR} CACHE STRING "GoogleBenchmark source directory override")
endif()

set(GBENCH_REPOSITORY "https://github.com/google/benchmark.git" CACHE STRING "GoogleBench repo to fetch")
FetchContent_Declare(
  googlebenchmark
  GIT_REPOSITORY ${GBENCH_REPOSITORY}
  GIT_TAG        v1.9.0
  )

FetchContent_GetProperties(googlebenchmark)

if(NOT googlebenchmark_POPULATED)
  FetchContent_Populate(googlebenchmark)
  add_subdirectory(${googlebenchmark_SOURCE_DIR} ${googlebenchmark_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()
