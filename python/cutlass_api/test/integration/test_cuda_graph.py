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

import pytest
import torch
from torch.cuda import current_stream

import cutlass_api
from cutlass_api.utils import is_device_cc_supported


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
        20,
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
    fixture_toggle_tvm_ffi,
):
    A = torch.randint(-1, 2, (M, K), device="cuda").to(ab_dtype)
    B = torch.randint(-1, 2, (K, N), device="cuda").to(ab_dtype)
    D = torch.randint(-1, 2, (M, N), device="cuda").to(c_dtype)

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernel = kernels[0]

    """
    Compile the kernel and capture CUDA Graph.
    The kernel needs to be compiled outside the CUDA graph.
    """

    assert kernel.supports(args)
    compiled_artifact = kernel.compile(args)
    stream = torch.cuda.Stream()

    # Create a CUDA Graph to run our compiled kernel N times
    g = torch.cuda.CUDAGraph()
    with torch.cuda.graph(g):
        # Run N iterations of our compiled kernel on the current stream
        for _ in range(n_iterations):
            kernel.run(
                args,
                compiled_artifact=compiled_artifact,
                stream=current_stream(),
                assume_supported_args=True,
            )

    # Zero the output so we don't refcheck stale results
    D.zero_()

    # Replay captured graph & check result
    g.replay()
    torch.cuda.synchronize()

    reference = A @ B
    assert torch.allclose(D, reference.to(D.dtype)), "Refcheck failed!"

    """
    Run with & without graph capture to compare overhead
    """

    # Create CUDA events for measuring performance
    start = torch.cuda.Event(enable_timing=True)
    end = torch.cuda.Event(enable_timing=True)

    # Warmup the GPU
    for _ in range(n_iterations):
        kernel.run(
            args,
            compiled_artifact=compiled_artifact,
            stream=stream,
            assume_supported_args=True,
        )

    # Run without CUDA graph and time it
    start.record()
    for _ in range(n_iterations):
        kernel.run(
            args,
            compiled_artifact=compiled_artifact,
            stream=stream,
            assume_supported_args=True,
        )
    end.record()
    torch.cuda.synchronize()
    without_graph_time = start.elapsed_time(end)

    # Warmup again
    for _ in range(n_iterations):
        kernel.run(
            args,
            compiled_artifact=compiled_artifact,
            stream=stream,
            assume_supported_args=True,
        )

    # Run with CUDA graph and time it
    start.record()
    g.replay()
    end.record()
    torch.cuda.synchronize()
    with_graph_time = start.elapsed_time(end)

    percent_speedup = (without_graph_time - with_graph_time) / with_graph_time
    print("-" * 80)
    print(f"Number of launches     : {n_iterations}")
    print(f"Time without CUDA graph: {without_graph_time:.2f} ms")
    print(f"Time with    CUDA graph: {with_graph_time:.2f} ms")
    print(f"Speedup                : {percent_speedup * 100.0:.2f}%")
