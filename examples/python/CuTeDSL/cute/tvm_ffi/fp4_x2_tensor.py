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

"""Example demonstrating how to pass torch.float4_e2m1fn_x2 tensors to CuTe JIT functions.

This example shows how to:
1. Use make_fake_compact_tensor with Float4E2M1FN dtype for compilation
2. Compile the function with "--enable-tvm-ffi" option
3. Pass torch tensors with dtype=float4_e2m1fn_x2 to the compiled function

Note: Float4E2M1FN is a 4-bit floating point type (2-bit exponent, 1-bit mantissa).
In PyTorch, this is represented as torch.float4_e2m1fn_x2, where two float4 values
are packed into a single byte. The tensor is stored as uint8 and viewed as float4_e2m1fn_x2.

To run this example:

.. code-block:: bash

    python examples/python/CuTeDSL/cute/tvm_ffi/float4_tensor_example.py
"""

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor


@cute.kernel
def print_fp4_x2_tensor_info_kernel(t_f4: cute.Tensor, t_uint8: cute.Tensor):
    print("[Compile INFO] Float4E2M1FN:", t_f4)
    print("[Compile INFO] Uint8:", t_uint8)
    t_f4_casted = cute.recast_tensor(t_uint8, cutlass.Float4E2M1FN)
    print("[Compile INFO] Float4E2M1FN casted from Uint8:", t_f4_casted)


@cute.jit
def print_fp4_x2_tensor_info(t_f4: cute.Tensor, t_uint8: cute.Tensor):
    """Process a fp4_x2 tensor - prints its layout information.

    Note: Float4E2M1FN is a sub-byte type (4-bit), so individual element
    dereference operations are not supported. This function demonstrates
    passing float4 tensors through the TVM-FFI interface.
    """
    print_fp4_x2_tensor_info_kernel(t_f4, t_uint8).launch(grid=(1, 1, 1), block=(1, 1, 1))


def torch_float4_x2_tensor():
    """Demonstrate passing torch.float4_e2m1fn_x2 tensors to compiled function."""
    print("=" * 60)
    print("Example 3: Pass torch.float4_e2m1fn_x2 tensor to compiled function")
    print("=" * 60)

    if not torch.cuda.is_available():
        print("CUDA not available, skipping runtime example")
        return

    m = cute.sym_int()
    # f4 is packed as x2 which must be divisible by 2
    k_f4 = cute.sym_int(divisibility=2)
    k_uint8 = cute.sym_int()
    fake_tensor_f4 = make_fake_compact_tensor(
        cutlass.Float4E2M1FN,
        (m, k_f4),
        stride_order=(1, 0),
        assumed_align=16,
    )
    fake_tensor_uint8 = make_fake_compact_tensor(
        cutlass.Uint8,
        (m, k_uint8),
        stride_order=(1, 0),
        assumed_align=16,
    )

    print(f"[Compile INFO] Compiling function for Float4E2M1FN tensor")

    compiled_fn = cute.compile(
        print_fp4_x2_tensor_info, fake_tensor_f4, fake_tensor_uint8, options="--enable-tvm-ffi"
    )

    tensor_uint8 = torch.randint(0, 256, (16, 16), dtype=torch.uint8, device="cuda")
    tensor_f4 = tensor_uint8.view(torch.float4_e2m1fn_x2)

    print(f"\n[Runtime INFO] Created torch tensor:")
    print(f"  Underlying uint8 shape: {tensor_uint8.shape}")
    print(f"  Float4 view shape: {tensor_f4.shape}")
    print(f"  Device: {tensor_f4.device}")

    print("\n[Runtime INFO] Calling compiled function with float4 tensor...")
    compiled_fn(tensor_f4, tensor_uint8)
    torch.cuda.synchronize()

    print("[Runtime INFO] Function call completed successfully!")


if __name__ == "__main__":
    torch_float4_x2_tensor()
