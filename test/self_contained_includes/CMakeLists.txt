# Copyright (c) 2024 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

# The purpose of this target is to check if the following header files are self-contained,
# i.e. they can be included in a source file without needing to include other headers before it.

set(header_files_to_check
    cutlass/gemm/kernel/default_gemm.h
    cutlass/gemm/kernel/default_gemm_complex.h
    cutlass/gemm/kernel/gemm_universal_decl.h
    # cutlass/gemm/kernel/sm90_gemm_warpspecialized.hpp

    cute/tensor_impl.hpp
)

# for each header in _header_files:
#   create a .cu file with the same name as the header's path, except with / replaced with %
#   have the .cu file include that header
set(_gen_source_files "")
foreach(header_file ${header_files_to_check})
  string(REPLACE "/" "%" header_file_esc ${header_file})

  file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${header_file_esc}.cu"
       "#include <${header_file}>")

  list(APPEND _gen_source_files
       "${CMAKE_CURRENT_BINARY_DIR}/${header_file_esc}.cu")
endforeach()

# build all generated .cu files into a single library
cutlass_add_library(test_self_contained_includes MODULE ${_gen_source_files})

