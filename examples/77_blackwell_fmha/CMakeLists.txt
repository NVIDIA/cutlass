# Copyright (c) 2014 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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


set_property(
  SOURCE
      77_blackwell_fmha.cu
      77_blackwell_fmha_gen.cu
      77_blackwell_mla.cu
      77_blackwell_fmha_bwd.cu
  PROPERTY
      COMPILE_FLAGS "--use_fast_math -ftemplate-backtrace-limit=0"
)

set(TEST_BASIC --b=1 --h=4 --q=512 --k=512 --d=128 --verify --mask=no)
set(TEST_CAUSAL --b=1 --h=4 --q=512 --k=512 --d=128 --verify --mask=causal)
set(TEST_VARLEN --b=1 --h=4 --q=512 --k=512 --d=128 --verify --mask=residual --varlen)
set(TEST_HDIM64 --b=2 --h=4 --q=512 --k=512 --d=64 --verify)
set(TEST_GQA --b=2 --h=4 --h_k=2 --q=512 --k=512 --d=64 --verify)

set(TEST_GEN_BASIC --b=1 --h=4 --k=512 --d=128 --verify)
set(TEST_GEN_VARLEN --b=1 --h=4 --k=512 --d=128 --verify  --varlen)
set(TEST_GEN_HDIM64 --b=2 --h=4 --k=512 --d=64 --verify)
set(TEST_GEN_GQA --b=2 --h=4 --h_k=2 --k=512 --d=64 --verify)
set(TEST_GEN_REMAP --b=2 --h=4 --h_k=2 --k=512 --d=128 --verify --remap)
set(TEST_GEN_CACHEONLY --b=2 --h=4 --h_k=2 --k=512 --d=128 --verify --cache-only)

set(TEST_MLA_BASIC --b=1 --k=512 --verify)

if(NOT WIN32 AND (NOT (CMAKE_CXX_COMPILER_ID MATCHES "Clang")) AND (CUTLASS_NVCC_ARCHS MATCHES 100a))

  foreach(PREC fp8 fp16)
    string(TOUPPER "${PREC}" PREC_MACRO)

    cutlass_example_add_executable(
        77_blackwell_fmha_${PREC}
        77_blackwell_fmha.cu
        TEST_COMMAND_OPTIONS
        TEST_BASIC
        # TEST_CAUSAL
        # TEST_VARLEN
        # TEST_HDIM64
        # TEST_GQA)
        )
    target_include_directories(77_blackwell_fmha_${PREC} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_compile_definitions(77_blackwell_fmha_${PREC} PRIVATE ${PREC_MACRO})
  
    cutlass_example_add_executable(
        77_blackwell_fmha_gen_${PREC}
        77_blackwell_fmha_gen.cu
        TEST_COMMAND_OPTIONS
        TEST_GEN_BASIC
        # TEST_GEN_VARLEN
        # TEST_GEN_HDIM64
        # TEST_GEN_GQA
        # TEST_GEN_REMAP
        # TEST_GEN_CACHEONLY)
        )
    target_include_directories(77_blackwell_fmha_gen_${PREC} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_compile_definitions(77_blackwell_fmha_gen_${PREC} PRIVATE ${PREC_MACRO})

    cutlass_example_add_executable(
        77_blackwell_mla_2sm_${PREC}
        77_blackwell_mla.cu
        TEST_COMMAND_OPTIONS
        TEST_MLA_BASIC
        )
    target_include_directories(77_blackwell_mla_2sm_${PREC} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_compile_definitions(77_blackwell_mla_2sm_${PREC} PRIVATE ${PREC_MACRO})
    target_compile_options(77_blackwell_mla_2sm_${PREC} PRIVATE -Xptxas -v)

    cutlass_example_add_executable(
        77_blackwell_mla_2sm_cpasync_${PREC}
        77_blackwell_mla.cu
        TEST_COMMAND_OPTIONS
        TEST_MLA_BASIC
        )
    target_include_directories(77_blackwell_mla_2sm_cpasync_${PREC} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_compile_definitions(77_blackwell_mla_2sm_cpasync_${PREC} PRIVATE ${PREC_MACRO} CPASYNC)
    target_compile_options(77_blackwell_mla_2sm_cpasync_${PREC} PRIVATE -Xptxas -v)

    cutlass_example_add_executable(
        77_blackwell_mla_b2b_2sm_${PREC}
        77_blackwell_mla.cu
        TEST_COMMAND_OPTIONS
        TEST_MLA_BASIC
        )
    target_include_directories(77_blackwell_mla_b2b_2sm_${PREC} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_compile_definitions(77_blackwell_mla_b2b_2sm_${PREC} PRIVATE ${PREC_MACRO} B2B)
    target_compile_options(77_blackwell_mla_b2b_2sm_${PREC} PRIVATE -Xptxas -v)

    cutlass_example_add_executable(
        77_blackwell_fmha_bwd_${PREC}
        77_blackwell_fmha_bwd.cu
        TEST_COMMAND_OPTIONS
        TEST_BASIC
        # TEST_GEN_VARLEN
        # TEST_GEN_HDIM64
        # TEST_GEN_GQA
        # TEST_GEN_REMAP
        # TEST_GEN_CACHEONLY)
        )
    target_include_directories(77_blackwell_fmha_bwd_${PREC} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_compile_definitions(77_blackwell_fmha_bwd_${PREC} PRIVATE ${PREC_MACRO})
    target_compile_options(77_blackwell_fmha_bwd_${PREC} PRIVATE -Xptxas -v)

    cutlass_example_add_executable(
        77_blackwell_fmha_bwd_sat_${PREC}
        77_blackwell_fmha_bwd.cu
        TEST_COMMAND_OPTIONS
        TEST_BASIC
        # TEST_GEN_VARLEN
        TEST_GEN_HDIM64
        # TEST_GEN_GQA
        # TEST_GEN_REMAP
        # TEST_GEN_CACHEONLY)
        )
    target_include_directories(77_blackwell_fmha_bwd_sat_${PREC} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_compile_definitions(77_blackwell_fmha_bwd_sat_${PREC} PRIVATE ${PREC_MACRO} SKIP_ATOMIC)
    target_compile_options(77_blackwell_fmha_bwd_sat_${PREC} PRIVATE -Xptxas -v)
  endforeach()
endif()
