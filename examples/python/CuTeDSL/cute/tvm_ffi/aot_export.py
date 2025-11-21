# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Example demonstrating how to use TVM-FFI ABI with CuTe.

This example shows how to:
1. Compile a CuTe function with "--enable-tvm-ffi" option
2. Export the compiled function to a shared library
3. Load the shared library and use the compiled function to work with torch.Tensor

To run this example:

.. code-block:: bash

    python examples/cute/tvm_ffi/aot_export.py
    # run example to use in torch
    python examples/cute/tvm_ffi/aot_use_in_torch.py
    # run example to use in jax
    python examples/cute/tvm_ffi/aot_use_in_jax.py
    # run example to use in c++ bundle
    bash examples/cute/tvm_ffi/aot_use_in_cpp_bundle.sh
"""

from pathlib import Path
import torch
import os
import subprocess
import tvm_ffi
import torch
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def device_add_one(a: cute.Tensor, b: cute.Tensor):
    for i in range(a.shape[0]):
        b[i] = a[i] + 1


@cute.jit
def add_one(a: cute.Tensor, b: cute.Tensor):
    """b = a + 1"""
    device_add_one(a, b).launch(grid=(1, 1, 1), block=(1, 1, 1))


def main():
    # compile the kernel with "--enable-tvm-ffi" option
    a_torch = torch.arange(10, dtype=torch.float32, device="cuda")
    b_torch = torch.zeros(10, dtype=torch.float32, device="cuda")
    a_cute = from_dlpack(a_torch, enable_tvm_ffi=True).mark_layout_dynamic()
    b_cute = from_dlpack(b_torch, enable_tvm_ffi=True).mark_layout_dynamic()
    # compile the kernel with "--enable-tvm-ffi" option
    compiled_add_one = cute.compile(add_one, a_cute, b_cute, options="--enable-tvm-ffi")

    object_file_path = "./build/add_one.o"
    lib_path = "./build/add_one.so"
    compiled_add_one.export_to_c(object_file_path, function_name="add_one")
    shared_libs = cute.runtime.find_runtime_libraries(enable_tvm_ffi=True)
    # compile the object file to a shared library
    cmd = ["gcc", "-shared", "-o", lib_path, object_file_path, *shared_libs]
    print(cmd)
    subprocess.run(cmd, check=True)
    print(f"Successfully created shared library: {lib_path}")


if __name__ == "__main__":
    main()
