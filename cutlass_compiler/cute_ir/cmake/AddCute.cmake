# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

# Cute dialect CMake utilities.

# Declare the library associated with a dialect.
function(add_cutlass_compiler_cute_dialect_library name)
  set_property(GLOBAL APPEND PROPERTY CUTLASS_COMPILER_CUTE_IR_DIALECT_LIBS ${name})
  add_cutlass_compiler_dialect_library(${ARGV})
endfunction(add_cutlass_compiler_cute_dialect_library)

# Declare the library associated with a conversion.
function(add_cutlass_compiler_cute_conversion_library name)
  set_property(GLOBAL APPEND PROPERTY CUTLASS_COMPILER_CUTE_IR_CONVERSION_LIBS ${name})
  add_cutlass_compiler_conversion_library(${ARGV})
endfunction(add_cutlass_compiler_cute_conversion_library)

# Declare the library associated with a test.
function(add_cutlass_compiler_cute_test_library name)
  set_property(GLOBAL APPEND PROPERTY CUTLASS_COMPILER_CUTE_IR_TEST_LIBS ${name})
  add_cutlass_compiler_library(${ARGV})
endfunction(add_cutlass_compiler_cute_test_library)
