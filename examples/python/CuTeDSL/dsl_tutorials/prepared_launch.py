# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""
An example demonstrating prepared launches for low-overhead kernel replay.

Calling a compiled CuTe DSL function re-marshals every argument on every
call: argument objects are rebuilt, scalars are cast into fresh ctypes
storage, and the packed argument array is regenerated. For a small kernel
launched in a tight loop — the steady state of most training and inference
wrappers — that host-side Python work dominates the launch cost.

``compiled.prepare(*args)`` performs the marshalling exactly once and
returns a ``PreparedLaunch`` whose ``launch(*args)`` only rewrites pointer
addresses, scalar values, and the stream handle in place before invoking the
compiled entry point directly. Launches are bitwise-identical to
``compiled(*args)``; only the per-call host overhead changes.

Prepared launches accept runtime pointers (``make_ptr``), numeric scalars,
and CUDA streams — exactly the by-passing-dlpack argument style shown in
``call_bypass_dlpack.py``. Raw integers are accepted wherever a pointer or
stream is expected, so the hot loop below needs no per-call object
construction at all. Argument mixes that need per-call marshalling (e.g.
dlpack tensors) raise ``PreparedLaunchError`` at prepare time and keep using
the normal call path.

To run this example:

.. code-block:: bash

    python examples/python/CuTeDSL/dsl_tutorials/prepared_launch.py
"""

import time

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_ptr


@cute.kernel
def scale_kernel(
    gOut: cute.Tensor, gIn: cute.Tensor, alpha: cutlass.Float32, n: cutlass.Int32
):
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()
    bdim, _, _ = cute.arch.block_dim()
    i = bidx * bdim + tidx
    if i < n:
        gOut[i] = gIn[i] * alpha


@cute.jit
def scale(
    out_ptr: cute.Pointer,
    in_ptr: cute.Pointer,
    alpha: cutlass.Float32,
    n: cutlass.Int32,
    stream: cuda.CUstream,
):
    layout = cute.make_layout(n)
    gOut = cute.make_tensor(out_ptr, layout)
    gIn = cute.make_tensor(in_ptr, layout)
    scale_kernel(gOut, gIn, alpha, n).launch(
        grid=((n + 255) // 256, 1, 1), block=(256, 1, 1), stream=stream
    )


def f32_ptr(tensor: torch.Tensor) -> cute.Pointer:
    return make_ptr(
        cutlass.Float32, tensor.data_ptr(), cute.AddressSpace.gmem, assumed_align=16
    )


def run_prepared_launch(n: int = 4096, iterations: int = 2000):
    x = torch.randn(n, device="cuda", dtype=torch.float32)
    y = torch.empty_like(x)
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)

    # Compile once, then bind the launch arguments once.
    compiled = cute.compile(scale, f32_ptr(y), f32_ptr(x), 2.0, n, stream)
    prepared = compiled.prepare(f32_ptr(y), f32_ptr(x), 2.0, n, stream)

    # Steady state: raw addresses and values only, no per-call objects.
    out_addr, in_addr, handle = y.data_ptr(), x.data_ptr(), int(stream)
    prepared.launch(out_addr, in_addr, 2.0, n, handle)
    torch.cuda.synchronize()
    assert torch.equal(y, x * 2.0)

    # Arguments may change between launches: new buffers, new scalar values.
    x2 = torch.randn(2 * n, device="cuda", dtype=torch.float32)
    y2 = torch.empty_like(x2)
    prepared.launch(y2.data_ptr(), x2.data_ptr(), -0.5, 2 * n, handle)
    torch.cuda.synchronize()
    assert torch.equal(y2, x2 * -0.5)

    # Compare steady-state host launch cost against the normal call path.
    def per_call_us(fn) -> float:
        for _ in range(100):
            fn()
        torch.cuda.synchronize()
        start = time.perf_counter()
        for _ in range(iterations):
            fn()
        elapsed = time.perf_counter() - start
        torch.cuda.synchronize()
        return elapsed / iterations * 1e6

    direct_us = per_call_us(lambda: compiled(f32_ptr(y), f32_ptr(x), 2.0, n, stream))
    prepared_us = per_call_us(
        lambda: prepared.launch(out_addr, in_addr, 2.0, n, handle)
    )
    print(f"direct call:     {direct_us:6.2f} us/launch (host)")
    print(f"prepared launch: {prepared_us:6.2f} us/launch (host)")


if __name__ == "__main__":
    run_prepared_launch()
