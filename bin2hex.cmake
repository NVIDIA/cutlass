# Copyright (c) 2019 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

# Option to control raw string generation method for performance optimization
# ON: Always use fast mode (maximum performance, assumes text content)
# OFF: Always use original hex method (maximum compatibility)
# Option to enable faster raw string generation method
# This maintains exact backward compatibility while providing performance improvement
set(CUTLASS_BIN2HEX_FAST_MODE ON CACHE BOOL "Enable faster raw string generation for bin2hex")

# A small utility function which generates a C-header from an input file
function(FILE_TO_C_STRING FILENAME VARIABLE_NAME OUTPUT_STRING)

  if(CUTLASS_BIN2HEX_FAST_MODE)
    # Fast mode: Generate raw string literal with custom delimiter for maximum performance
    # This avoids the expensive hex conversion and generates compact, fast-to-compile code

    # Read file as raw content
    FILE(READ "${FILENAME}" RAW_CONTENT)

    # Unique delimiter that won't appear in the content
    set(RAW_DELIM "abc1ae6e1e82e3de")

    # Create the raw string literal format: R"delimiter(...)delimiter"
    set(RESULT "static char constexpr ${VARIABLE_NAME}[] = R\"${RAW_DELIM}(${RAW_CONTENT})${RAW_DELIM}\";\n")

  else()

    # Original method: Read as hex and format (slower but proven)
    FILE(READ "${FILENAME}" HEX_INPUT HEX)

    string(REGEX REPLACE "(....)" "\\1\n" HEX_OUTPUT ${HEX_INPUT})
    string(REGEX REPLACE "([0-9a-f][0-9a-f])" "char(0x\\1)," HEX_OUTPUT ${HEX_OUTPUT})

    set(RESULT "static char const ${VARIABLE_NAME}[] = {\n  ${HEX_OUTPUT}\n};\n")

  endif()

  set(${OUTPUT_STRING} "${RESULT}" PARENT_SCOPE)

endfunction()

# message("Create header file for ${FILE_IN}")
# message("Create header file for ${FILE_OUT}")
file_to_c_string(${FILE_IN} ${VARIABLE_NAME} OUTPUT_STRING)

set(RESULT "#pragma once\n")
string(APPEND RESULT "namespace cutlass {\n")
string(APPEND RESULT "namespace nvrtc {\n")
string(APPEND RESULT "${OUTPUT_STRING}")
string(APPEND RESULT "} // namespace nvrtc\n")
string(APPEND RESULT "} // namespace cutlass\n")
file(WRITE "${FILE_OUT}" "${RESULT}")
