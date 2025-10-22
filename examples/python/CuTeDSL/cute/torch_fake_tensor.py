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


import torch

import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


"""Example demonstrating how to use CuTe with PyTorch's FakeTensor mode.

This example shows how to:
1. Use PyTorch's FakeTensor mode to compile a CuTe function without real data
2. Execute the compiled function on real data later

FakeTensor mode allows compiling code without allocating real memory, which is useful
for ahead-of-time compilation scenarios. The compiled function can then be executed
on real tensors that match the expected shapes and dtypes.

Primary goals of this example are to demonstrate: How to use PyTorch's FakeTensor mode with CuTe
to enable ahead-of-time compilation without real data allocation.

The example:
1. Creates a fake tensor in PyTorch using FakeTensor mode
2. Compiles a CuTe function using the fake tensor without allocating real memory
3. Creates a real tensor with matching shape and dtype
4. Executes the compiled function on the real tensor

To run this example:

.. code-block:: bash

    python examples/cute/torch_fake_tensor.py
"""


@cute.jit
def print_tensor(t: cute.Tensor):
    cute.print_tensor(t)


if __name__ == "__main__":
    from torch._subclasses.fake_tensor import FakeTensorMode

    shape = (3, 4)
    with FakeTensorMode():
        fake_tensor = torch.zeros(shape, dtype=torch.float32)
        compiled_fn = cute.compile(print_tensor, from_dlpack(fake_tensor))

    real_tensor = torch.randn(shape, dtype=torch.float32)
    compiled_fn(from_dlpack(real_tensor))
