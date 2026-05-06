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

import cutlass
import cutlass.cute as cute

import os
import subprocess
import cuda.bindings.driver as cuda

"""Example demonstrating how to export a CuTe function.

This example shows how to:
1. Compile a CuTe function
2. Export the compiled function to a object file and a C header file
3. Compile the object file to a shared library

To run this example:

.. code-block:: bash

    # export the compiled function to a object file and a C header file
    python cutlass_ir/compiler/python/examples/cute/export/export_to_c.py
"""


@cute.kernel
def print_tensor_kernel(a: cute.Tensor):
    cute.printf("a: {}", a)


@cute.jit
def print_tensor(a: cute.Tensor, stream: cuda.CUstream):
    print_tensor_kernel(a).launch(grid=(1, 1, 1), block=(1, 1, 1), stream=stream)


@cute.kernel
def add_one_kernel(a: cute.Tensor, b: cute.Tensor):
    a[0] = b[0] + 1


@cute.jit
def add_one(a: cute.Tensor, b: cute.Tensor, stream: cuda.CUstream):
    add_one_kernel(a, b).launch(grid=(1, 1, 1), block=(1, 1, 1), stream=stream)


def run():
    from cutlass.cute.runtime import make_fake_compact_tensor

    shape = (cute.SymInt(divisibility=16), cute.SymInt())
    a = make_fake_compact_tensor(cutlass.Float32, shape, stride_order=(1, 0))
    b = make_fake_compact_tensor(cutlass.Float32, shape, stride_order=(1, 0))
    stream = cuda.CUstream(0)
    compiled_print_tensor = cute.compile(print_tensor, a, stream=stream)
    compiled_add_one = cute.compile(add_one, a, b, stream=stream)

    os.makedirs("./build", exist_ok=True)
    compiled_print_tensor.export_to_c(
        file_path="./build",
        file_name="print_tensor_example",
        function_prefix="print_tensor",
    )
    compiled_add_one.export_to_c(
        file_path="./build", file_name="add_one_example", function_prefix="add_one"
    )

    cc = os.environ.get("CC", "gcc")

    # compile the object file to a shared library
    cmd = [
        cc,
        "-shared",
        "-o",
        "./build/libexport_example.so",
        "./build/print_tensor_example.o",
        "./build/add_one_example.o",
    ]
    subprocess.run(cmd, check=True)


if __name__ == "__main__":
    run()
