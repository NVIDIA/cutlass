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

import sys
import os
import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack

"""Demonstrates calling off-the-shelf kernels with TVM FFI without DLPack.

This example shows how to compile CuTe JIT function with fake tensors then run it with TVM FFI.
"""

if __name__ == "__main__":
    # Add the current directory to sys.path
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "..", ".."))
from ampere.tensorop_gemm import TensorOpGemm


@cute.jit
def bmm(
    a: cute.Tensor,  # (l, m, k)
    b: cute.Tensor,  # (l, k, n)
    c: cute.Tensor,  # (l, m, n)
):
    gemm_op = TensorOpGemm(cutlass.Float16, cutlass.Float16, cutlass.Float32, (2, 2, 1))

    # Permute to follow convention of CuTe

    # (l, m, k) -> (m, k, l)
    a = cute.make_tensor(a.iterator, cute.select(a.layout, mode=[1, 2, 0]))
    # (l, k, n) -> (n, k, l)
    b = cute.make_tensor(b.iterator, cute.select(b.layout, mode=[2, 1, 0]))
    # (l, m, n) -> (m, n, l)
    c = cute.make_tensor(c.iterator, cute.select(c.layout, mode=[1, 2, 0]))

    gemm_op(a, b, c)


def compile_bmm_dynamic_layout():
    from cutlass.cute.runtime import make_fake_compact_tensor

    m = cute.sym_int()
    n = cute.sym_int(divisibility=16)
    k = cute.sym_int(divisibility=16)
    l = cute.sym_int()

    # Contiguous on K
    fake_a = make_fake_compact_tensor(
        cutlass.Float16, (l, m, k), stride_order=(2, 1, 0), assumed_align=16
    )
    # Contiguous on N
    fake_b = make_fake_compact_tensor(
        cutlass.Float16, (l, k, n), stride_order=(2, 1, 0), assumed_align=16
    )
    # Contiguous on N
    fake_c = make_fake_compact_tensor(
        cutlass.Float16, (l, m, n), stride_order=(2, 1, 0), assumed_align=16
    )

    compiled_fn = cute.compile(bmm, fake_a, fake_b, fake_c, options="--enable-tvm-ffi")
    return compiled_fn


def compile_bmm_static_layout(m, n, k, l):
    from cutlass.cute.runtime import make_fake_compact_tensor

    fake_a = make_fake_compact_tensor(
        cutlass.Float16, (l, m, k), stride_order=(2, 1, 0), assumed_align=16
    )
    fake_b = make_fake_compact_tensor(
        cutlass.Float16, (l, k, n), stride_order=(2, 1, 0), assumed_align=16
    )
    fake_c = make_fake_compact_tensor(
        cutlass.Float16, (l, m, n), stride_order=(2, 1, 0), assumed_align=16
    )

    compiled_fn = cute.compile(bmm, fake_a, fake_b, fake_c, options="--enable-tvm-ffi")
    return compiled_fn


def run_bmm_and_verify(compiled_fn, m, n, k, l):
    torch.manual_seed(1112)

    a = torch.randn(l, m, k, dtype=torch.float16, device="cuda")
    b = torch.randn(l, k, n, dtype=torch.float16, device="cuda")
    c = torch.randn(l, m, n, dtype=torch.float16, device="cuda")

    print("[Runtime INFO] Input tensor shapes:")
    print(f"a: {a.shape=}, {a.stride()=}, {a.dtype=}")
    print(f"b: {b.shape=}, {b.stride()=}, {b.dtype=}")
    print(f"c: {c.shape=}, {c.stride()=}, {c.dtype=}\n")

    # pass in torch tensor as input
    compiled_fn(a, b, c)
    torch.cuda.synchronize()

    ref = torch.bmm(a, b)
    torch.testing.assert_close(c, ref, atol=1e-05, rtol=1e-05)
    print("[Runtime INFO] Verification successful!")
    print(f"  First few elements of result: \n{c[:3, :3, :3]}")


if __name__ == "__main__":
    m, n, k, l = (512, 512, 256, 2)

    compiled_fn_dynamic = compile_bmm_dynamic_layout()
    run_bmm_and_verify(compiled_fn_dynamic, m, n, k, l)

    compiled_fn_static = compile_bmm_static_layout(m, n, k, l)
    run_bmm_and_verify(compiled_fn_static, m, n, k, l)

    # Error Check:
    #   1. mis-matched tensor dim raise error
    a = torch.randn(l, m, k, dtype=torch.float16, device="cuda")
    b = torch.randn(l, 2 * k, n, dtype=torch.float16, device="cuda")
    c = torch.randn(l, m, n, dtype=torch.float16, device="cuda")
    try:
        compiled_fn_dynamic(a, b, c)
    except Exception as e:
        print(f"\n[Runtime Error]: {e}")

    #   2. mis-matched divisibility
    a = torch.randn(l, m, k + 1, dtype=torch.float16, device="cuda")
    b = torch.randn(l, k + 1, n, dtype=torch.float16, device="cuda")
    c = torch.randn(l, m, n, dtype=torch.float16, device="cuda")

    try:
        compiled_fn_dynamic(a, b, c)
    except Exception as e:
        print(f"\n[Runtime Error]: {e}")

    # 3. mis-matched static shape constraint
    a = torch.randn(l * 2, m, k, dtype=torch.float16, device="cuda")
    b = torch.randn(l * 2, k, n, dtype=torch.float16, device="cuda")
    c = torch.randn(l * 2, m, n, dtype=torch.float16, device="cuda")

    try:
        compiled_fn_static(a, b, c)
    except Exception as e:
        print(f"\n[Runtime Error]: {e}")
