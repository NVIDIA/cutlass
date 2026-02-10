# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

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

#!/bin/bash
set -eu

# Try to find the wheel path of nvidia-cutlass-dsl
WHEEL_PATH=$(python3 -c "import cutlass, os; print(os.path.dirname(cutlass.__file__))" 2>/dev/null)/../..

if [[ -z "$WHEEL_PATH" ]]; then
    echo "nvidia-cutlass-dsl wheel not found in the current Python environment."
    exit 1
else
    echo "nvidia-cutlass-dsl wheel path found at: $WHEEL_PATH"
fi

CUTE_DSL_LIB_PATH="${WHEEL_PATH}/lib/"
export LD_LIBRARY_PATH=${CUTE_DSL_LIB_PATH}:${CUDA_HOME}/lib64:./build

if [ -z "$CUDA_HOME" ]; then
    CUDA_HOME=/usr/local/cuda
    echo "CUDA_HOME not set, using default: $CUDA_HOME"
else
    echo "CUDA_HOME found: $CUDA_HOME"
fi
SOURCE_FILE="$(dirname "$0")/run_with_dynamic_loading.cpp"

echo "Compiling the executable..."
# Search for a common C++ compiler: g++, clang++, or c++
if [ -n "${CXX-}" ] && command -v "$CXX" &> /dev/null; then
    CXX="$CXX"
elif command -v g++ &> /dev/null; then
    CXX="g++"
elif command -v clang++ &> /dev/null; then
    CXX="clang++"
elif command -v c++ &> /dev/null; then
    CXX="c++"
else
    echo "Error: No common C++ compiler found (g++, clang++, or c++). Please install a C++ compiler to continue."
    exit 1
fi

$CXX -o build/run_with_dynamic_loading \
  -I${CUDA_HOME}/include \
  -I${WHEEL_PATH}/include \
  ${SOURCE_FILE} \
  -L${CUTE_DSL_LIB_PATH} \
  -L${CUDA_HOME}/lib64 \
  -L./build \
  -lcudart \
  -lcute_dsl_runtime \
  -lexport_example

echo "Running the executable..."
./build/run_with_dynamic_loading
