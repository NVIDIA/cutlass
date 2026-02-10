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
# Set up library paths for runtime
export LD_LIBRARY_PATH=$(python3 -m cutlass.cute.export.aot_config --libdir):$(tvm-ffi-config --libdir)

CUDA_HOME=/usr/local/cuda
SOURCE_FILE="$(dirname "$0")/aot_use_in_cpp_bundle.cpp"

echo "Compiling the executable..."
g++ -o build/aot_use_in_cpp_bundle \
  -I${CUDA_HOME}/include \
  `tvm-ffi-config --cxxflags`  \
  ${SOURCE_FILE} build/add_one.o \
  $(python3 -m cutlass.cute.export.aot_config --ldflags) \
  -L${CUDA_HOME}/lib64 \
  $(python3 -m cutlass.cute.export.aot_config --libs) -lcuda -lcudart \
  $(tvm-ffi-config --ldflags) \
  $(tvm-ffi-config --libs)

echo "Running the executable..."
./build/aot_use_in_cpp_bundle
