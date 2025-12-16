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


import os

import cuda.bindings.driver as cuda
import pytest
import torch
from torch.cuda import current_stream

import cutlass_api
from cutlass_api.config import GlobalOptions
from cutlass_api.utils import is_device_cc_supported


def benchmark(label, code, n_iterations):
    start = torch.cuda.Event(enable_timing=True)
    end = torch.cuda.Event(enable_timing=True)

    for _ in range(n_iterations):
        code()

    start.record()
    for _ in range(n_iterations):
        code()
    end.record()
    torch.cuda.synchronize()

    avg_time = start.elapsed_time(end) / n_iterations
    print(f"[{label:20}] avg of {n_iterations} iterations: {avg_time:1.3e} ms")
    return avg_time


@pytest.mark.parametrize(
    "M, N, K",
    [
        (256, 512, 1024),
    ],
)
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, accumulator_type",
    [
        (torch.float16, torch.float16, torch.float16),
    ],
)
@pytest.mark.parametrize(
    "n_iterations",
    [
        50,
    ],
)
@pytest.mark.skipif(
    not is_device_cc_supported({100})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_100f"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_sm100(
    M: int,
    N: int,
    K: int,
    ab_dtype: torch.dtype,
    c_dtype: torch.dtype,
    accumulator_type: torch.dtype,
    n_iterations: int,
):
    print()

    A = torch.randint(-1, 2, (M, K), device="cuda").to(ab_dtype)
    B = torch.randint(-1, 2, (K, N), device="cuda").to(ab_dtype)
    D = torch.empty((M, N), device="cuda").to(c_dtype)

    GlobalOptions().use_tvm_ffi = True

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernel = kernels[0]

    """
    Compile & run the kernel with TVM-FFI.
    """

    assert kernel.supports(args)
    compiled_artifact_with_tvm_ffi = kernel.compile(args)
    kernel.run(
        args,
        compiled_artifact=compiled_artifact_with_tvm_ffi,
        stream=current_stream(),
        assume_supported_args=True,
    )
    reference = A @ B
    assert torch.allclose(D, reference.to(D.dtype)), "Refcheck failed!"

    # Also works with CUDA graphs
    g = torch.cuda.CUDAGraph()
    with torch.cuda.graph(g):
        kernel.run(
            args,
            compiled_artifact=compiled_artifact_with_tvm_ffi,
            stream=current_stream(),
            assume_supported_args=True,
        )

    D.zero_()
    g.replay()
    torch.cuda.synchronize()
    assert torch.allclose(D, reference.to(D.dtype)), "Refcheck failed!"

    """
    Create args & run with & without TVM-FFI to compare overhead
    """

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type
    )
    compiled_artifact_with_tvm_ffi = kernel.compile(args)

    # Run with TVM-FFI and time it
    avg_time_with_tvm_ffi = benchmark(
        "Run with TVM-FFI",
        lambda: kernel.run(
            args,
            compiled_artifact=compiled_artifact_with_tvm_ffi,
            stream=current_stream(),
            assume_supported_args=True,
        ),
        n_iterations,
    )

    # Run without TVM-FFI and time it
    GlobalOptions().use_tvm_ffi = False
    args_without_tvm_ffi = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type
    )
    compiled_artifact_without_tvm_ffi = kernel.compile(args_without_tvm_ffi)
    stream = cuda.CUstream(current_stream().cuda_stream)
    avg_time_without_tvm_ffi = benchmark(
        "Run without TVM-FFI",
        lambda: kernel.run(
            args_without_tvm_ffi,
            compiled_artifact=compiled_artifact_without_tvm_ffi,
            stream=stream,
            assume_supported_args=True,
        ),
        n_iterations,
    )

    speedup = avg_time_without_tvm_ffi / avg_time_with_tvm_ffi
    print(f"Speedup with TVM-FFI: {speedup:.3f}x")
