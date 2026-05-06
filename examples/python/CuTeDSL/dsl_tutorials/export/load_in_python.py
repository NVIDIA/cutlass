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
import cuda.bindings.driver as cuda


"""Example demonstrating how to load a CuTe module/function in Python.

This example shows how to:
1. Load a CuTe module from a object file or a shared library
2. Extract the function from the module and call it in Python

To run this example:

.. code-block:: bash

    # prerequesites: export the compiled functions to object files and compile them into a shared library
    python examples/cute/export/export_to_c.py
    # load the module from a object file or a shared library
    python examples/cute/export/load_in_python.py
"""


def run():
    import torch
    from cutlass.cute.runtime import from_dlpack

    a = (
        torch.arange(16 * 10, dtype=torch.float32, device="cuda")
        .reshape(16, 10)
        .permute(1, 0)
    )
    b = torch.ones(16, 10, dtype=torch.float32, device="cuda").permute(1, 0)
    a_cute = from_dlpack(a).mark_layout_dynamic()
    b_cute = from_dlpack(b).mark_layout_dynamic()
    stream = cuda.CUstream(0)

    print_tensor_mod = cute.runtime.load_module("./build/print_tensor_example.o")
    print_tensor_mod.print_tensor(a_cute, stream=stream)

    add_one_mod = cute.runtime.load_module("./build/add_one_example.o")
    add_one_mod.add_one(a_cute, b_cute, stream=stream)
    assert a[0, 0] == b[0, 0] + 1

    shared_mod = cute.runtime.load_module("./build/libexport_example.so")
    shared_mod.print_tensor(a_cute, stream=stream)
    shared_mod.add_one(a_cute, b_cute, stream=stream)
    assert a[0, 0] == b[0, 0] + 1


if __name__ == "__main__":
    run()
