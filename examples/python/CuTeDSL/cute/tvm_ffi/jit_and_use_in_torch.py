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

"""Example demonstrating how to use TVM-FFI ABI with CuTe.

This example shows how to:
1. Compile a CuTe function with "--enable-tvm-ffi" option
2. Directly use the compiled function to work with torch.Tensor

To run this example:

.. code-block:: bash

    python cutlass_ir/compiler/python/examples/cute/tvm_ffi/jit_and_use_in_torch.py
"""

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
    import torch

    # compile the kernel with "--enable-tvm-ffi" option
    a_torch = torch.arange(10, dtype=torch.float32, device="cuda")
    b_torch = torch.zeros(10, dtype=torch.float32, device="cuda")
    a_cute = from_dlpack(a_torch, enable_tvm_ffi=True).mark_layout_dynamic()
    b_cute = from_dlpack(b_torch, enable_tvm_ffi=True).mark_layout_dynamic()
    # compile the kernel with "--enable-tvm-ffi" option
    compiled_add_one = cute.compile(add_one, a_cute, b_cute, options="--enable-tvm-ffi")
    # run the compiled function by passing in cute.Tensor as input
    # you need to set enable_tvm_ffi=True for now
    compiled_add_one(a_cute, b_cute)
    # print the result
    print("result of b after compiled_add_one(a, b)")
    print(b_torch)
    a_torch = a_torch + 1
    # We can directly pass in torch.Tensor as input
    # the call overhead is optimized so it is very fast to pass in torch.Tensor as input
    # takes about less than 0.5us per call likely in terms of API overhead
    compiled_add_one(a_torch, b_torch)
    # print the result
    print("result of b after compiled_add_one(a, b)")
    print(b_torch)


if __name__ == "__main__":
    main()
