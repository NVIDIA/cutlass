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


import cuda.bindings.driver as cuda
import pytest
import torch
from torch.cuda import current_stream

import cutlass.operators as ops

from test_utils import assert_close_with_reference_conversion

# Skip this entire module if tvm_ffi is not available, rather than producing a
# collection-time ImportError.
tvm_ffi = pytest.importorskip("tvm_ffi")


def _benchmark(label, code, n_iterations):
    """Helper function to benchmark code execution."""
    start = torch.cuda.Event(enable_timing=True)
    end = torch.cuda.Event(enable_timing=True)

    # Warmup
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


@pytest.mark.parametrize("M, N, K", [(256, 512, 1024)])
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float32)],
)
def test_option_takes_effect(
    M: int,
    N: int,
    K: int,
    ab_dtype: torch.dtype,
    c_dtype: torch.dtype,
    accumulator_type: torch.dtype,
    fixture_toggle_tvm_ffi,
):
    """Test refcheck passes and compiled object type matches TVM FFI setting."""
    A = torch.randint(-1, 2, (M, K), device="cuda").to(ab_dtype)
    B = torch.randint(-1, 2, (K, N), device="cuda").to(ab_dtype)
    D = torch.empty((M, N), device="cuda").to(c_dtype)

    args = ops.GemmArguments(A=A, B=B, out=D, accumulator_type=accumulator_type)
    operators = ops.get_operators(args, target_sm="80")

    assert len(operators) > 0
    operator = operators[0]

    # Compile and verify the compiled object type
    assert operator.supports(args)
    compiled_artifact = operator.compile(args)

    use_tvm_ffi = ops.GlobalOptions().use_tvm_ffi
    obj_to_check = compiled_artifact.compiled_obj
    if use_tvm_ffi:
        obj_to_check = tvm_ffi.convert(obj_to_check)
    is_tvm_ffi_function = isinstance(obj_to_check, tvm_ffi.Function)
    assert is_tvm_ffi_function == use_tvm_ffi, (
        "Compiled object should be tvm_ffi.Function if and only if TVM FFI is enabled."
    )

    # Run and verify results
    operator.run(
        args,
        compiled_artifact=compiled_artifact,
        stream=current_stream(),
        assume_supported_args=True,
    )

    reference = A @ B
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K", [(256, 512, 1024)])
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float32)],
)
def test_cuda_graph(
    M: int,
    N: int,
    K: int,
    ab_dtype: torch.dtype,
    c_dtype: torch.dtype,
    accumulator_type: torch.dtype,
    fixture_enable_tvm_ffi,
):
    """Test that CUDA graphs work correctly with TVM FFI enabled."""
    A = torch.randint(-1, 2, (M, K), device="cuda").to(ab_dtype)
    B = torch.randint(-1, 2, (K, N), device="cuda").to(ab_dtype)
    D = torch.empty((M, N), device="cuda").to(c_dtype)

    args = ops.GemmArguments(A=A, B=B, out=D, accumulator_type=accumulator_type)
    operators = ops.get_operators(args, target_sm="80")

    assert len(operators) > 0
    operator = operators[0]

    # Compile the Operator (must be done outside CUDA graph capture)
    assert operator.supports(args)
    compiled_artifact = operator.compile(args)

    # Capture CUDA graph
    g = torch.cuda.CUDAGraph()
    with torch.cuda.graph(g):
        operator.run(
            args,
            compiled_artifact=compiled_artifact,
            stream=current_stream(),
            assume_supported_args=True,
        )

    # Zero output and replay the graph
    D.zero_()
    g.replay()
    torch.cuda.synchronize()

    # Verify results
    reference = A @ B
    assert_close_with_reference_conversion(
        D, reference, D.dtype, msg="Refcheck failed with CUDA graph + TVM FFI!"
    )


@pytest.mark.parametrize("M, N, K", [(256, 512, 1024)])
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float32)],
)
@pytest.mark.parametrize("n_iterations", [50])
def test_speedup_comparison(
    M: int,
    N: int,
    K: int,
    ab_dtype: torch.dtype,
    c_dtype: torch.dtype,
    accumulator_type: torch.dtype,
    n_iterations: int,
):
    """Compare performance between TVM FFI enabled and disabled to measure speedup."""
    print()

    A = torch.randint(-1, 2, (M, K), device="cuda").to(ab_dtype)
    B = torch.randint(-1, 2, (K, N), device="cuda").to(ab_dtype)
    D = torch.empty((M, N), device="cuda").to(c_dtype)

    # Compile and run with TVM FFI enabled
    ops.GlobalOptions().use_tvm_ffi = True
    args_with_tvm_ffi = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type
    )
    operators = ops.get_operators(args_with_tvm_ffi, target_sm="80")

    assert len(operators) > 0
    operator = operators[0]

    compiled_artifact_with_tvm_ffi = operator.compile(args_with_tvm_ffi)

    avg_time_with_tvm_ffi = _benchmark(
        "Run with TVM-FFI",
        lambda: operator.run(
            args_with_tvm_ffi,
            compiled_artifact=compiled_artifact_with_tvm_ffi,
            stream=current_stream(),
            assume_supported_args=True,
        ),
        n_iterations,
    )

    # Compile and run with TVM FFI disabled
    ops.GlobalOptions().use_tvm_ffi = False
    args_without_tvm_ffi = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type
    )
    compiled_artifact_without_tvm_ffi = operator.compile(args_without_tvm_ffi)

    stream = cuda.CUstream(current_stream().cuda_stream)
    avg_time_without_tvm_ffi = _benchmark(
        "Run without TVM-FFI",
        lambda: operator.run(
            args_without_tvm_ffi,
            compiled_artifact=compiled_artifact_without_tvm_ffi,
            stream=stream,
            assume_supported_args=True,
        ),
        n_iterations,
    )

    speedup = avg_time_without_tvm_ffi / avg_time_with_tvm_ffi
    print(f"Speedup with TVM-FFI: {speedup:.3f}x")
