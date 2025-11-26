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
import time

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack

"""Demonstrates calling off-the-shelf kernels with TVM FFI without DLPack.

This example shows how to compile CuTe JIT function with fake tensors then run it with TVM FFI.
"""

if __name__ == "__main__":
    # Add the current directory to sys.path
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, ".."))
from ampere.tensorop_gemm import TensorOpGemm


def compile_op(use_tvm_ffi: bool = True):
    from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_tensor

    a_shape = (cute.sym_int(), cute.sym_int(divisibility=16), cute.sym_int())
    b_shape = (cute.sym_int(), cute.sym_int(divisibility=16), cute.sym_int())
    c_shape = (cute.sym_int(), cute.sym_int(divisibility=16), cute.sym_int())
    a = make_fake_compact_tensor(
        cutlass.Float16, a_shape, stride_order=(1, 0, 2), assumed_align=16
    )
    b = make_fake_compact_tensor(
        cutlass.Float16, b_shape, stride_order=(1, 0, 2), assumed_align=16
    )
    c = make_fake_compact_tensor(
        cutlass.Float16, c_shape, stride_order=(1, 0, 2), assumed_align=16
    )

    tensor_op_gemm = TensorOpGemm(
        cutlass.Float16, cutlass.Float16, cutlass.Float32, (2, 2, 1)
    )
    compiled_fn = cute.compile(
        tensor_op_gemm, a, b, c, options="--enable-tvm-ffi" if use_tvm_ffi else ""
    )
    return compiled_fn


def run_op(compiled_fn, mnkl, *, use_tvm_ffi: bool = True):
    print("\nRunning TensorOpGemm test with:")
    print(f"Tensor dimensions: {mnkl}")
    torch.manual_seed(1112)
    # (M,K,L)
    a_torch = torch.randn(
        mnkl[3], mnkl[0], mnkl[2], dtype=torch.float16, device="cuda"
    ).permute(1, 2, 0)
    # (N,K,L)
    b_torch = torch.randn(
        mnkl[3], mnkl[1], mnkl[2], dtype=torch.float16, device="cuda"
    ).permute(1, 2, 0)
    # (N,M,L)
    c_torch = torch.randn(
        mnkl[3], mnkl[0], mnkl[1], dtype=torch.float16, device="cuda"
    ).permute(1, 2, 0)

    print("Input tensor shapes:")
    print(f"a: {a_torch.shape}, dtype: {a_torch.dtype}")
    print(f"b: {b_torch.shape}, dtype: {b_torch.dtype}")
    print(f"c: {c_torch.shape}, dtype: {c_torch.dtype}\n")
    if not use_tvm_ffi:
        a = from_dlpack(a_torch).mark_layout_dynamic(leading_dim=1)
        b = from_dlpack(b_torch).mark_layout_dynamic(leading_dim=1)
        c = from_dlpack(c_torch).mark_layout_dynamic(leading_dim=1)
    else:
        a = a_torch
        b = b_torch
        c = c_torch
    # pass in torch tensor as input
    compiled_fn(a, b, c)
    torch.cuda.synchronize()

    # measure the launch overhead of tvm ffi function
    repeat = 100
    start_time = time.time()
    for i in range(repeat):
        compiled_fn(a, b, c)
    end_time = time.time()
    print(
        f"Launch overhead of tvm ffi function: {(end_time - start_time) / repeat} seconds"
    )

    ref = torch.einsum("mkl,nkl->mnl", a_torch, b_torch)
    torch.testing.assert_close(c_torch, ref, atol=1e-05, rtol=1e-05)
    print("\n[DSL INFO] Results verified successfully!")
    print(f"First few elements of result: \n{c_torch[:3, :3, :3]}")


if __name__ == "__main__":
    compiled_fn = compile_op(use_tvm_ffi=False)
    run_op(compiled_fn, [512, 512, 256, 1], use_tvm_ffi=False)
    compiled_fn = compile_op(use_tvm_ffi=True)
    run_op(compiled_fn, [512, 512, 256, 1], use_tvm_ffi=True)
