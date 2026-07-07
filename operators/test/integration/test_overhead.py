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


import time

import pytest
import torch
from torch.cuda import current_stream

import cutlass.operators as ops
from cutlass.operators.utils.device import (
    device_or_env_supports,
    device_or_env_target_sm,
    to_cuda_stream,
)
from cutlass.operators.utils.tensor import TensorWrapper

from test_utils import assert_close_with_reference_conversion


def _benchmark_cpu(label, code, n_iterations):
    """Measure CPU-side wall time per call for `code`"""

    # Warmup
    for _ in range(n_iterations):
        code()
    # Sync before timed code
    torch.cuda.synchronize()

    start = time.perf_counter()
    for _ in range(n_iterations):
        code()
    # Skip synchronization here: we only measure host time
    # independent of device code perf
    end = time.perf_counter()
    elapsed = end - start

    avg_us = elapsed / n_iterations * 1e6
    print(f"[{label:40}] avg of {n_iterations} iterations: {avg_us:8.1f} us")
    return avg_us


def _extract_runtime_args(*fn_args):
    """Extract runtime tensors from TensorWrappers, passing other args through."""
    return [x.runtime_tensor if isinstance(x, TensorWrapper) else x for x in fn_args]


def test_overhead(fixture_toggle_tvm_ffi):
    """Compare CPU overhead of operator.run() vs direct compiled_obj() call."""
    print()
    M, N, K = 256, 512, 1024
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N), device="cuda", dtype=torch.float16)

    args = ops.GemmArguments(A=A, B=B, out=D, accumulator_type=torch.float32)
    operators = ops.get_operators(args, target_sm="80", providers=[ops.CuTeDSLProvider])
    assert len(operators) > 0
    operator = operators[0]

    assert operator.supports(args)
    compiled_artifact = operator.compile(args)
    stream = current_stream()

    n_iterations = 100

    api_time = _benchmark_cpu(
        "With CUTLASS Operator API (operator.run())",
        lambda: operator.run(
            args,
            compiled_artifact=compiled_artifact,
            stream=stream,
            assume_supported_args=True,
        ),
        n_iterations,
    )

    compiled_obj = compiled_artifact.compiled_obj
    direct_args = _extract_runtime_args(
        args.A.tensor,
        args.B.tensor,
        args.out.tensor,
        to_cuda_stream(stream),
    )

    _benchmark_cpu(
        "Argument extraction",
        lambda: _extract_runtime_args(
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            to_cuda_stream(stream),
        ),
        n_iterations,
    )
    direct_time = _benchmark_cpu(
        "Direct CuTe DSL (compiled_obj())",
        lambda: compiled_obj(*direct_args),
        n_iterations,
    )

    overhead_us = api_time - direct_time
    print(f"  Overhead: {overhead_us:.1f} us over direct CuTe DSL")

    torch.cuda.synchronize()
    reference = A @ B
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_overhead_big_epilogue(fixture_toggle_tvm_ffi):
    """Compare CPU overhead with a large epilogue (8 aux inputs, 8 aux outputs)."""
    print()

    M, N, K, L = 256, 512, 128, 2
    ab_dtype = torch.float16
    c_dtype = torch.float32
    d_dtype = torch.bfloat16
    accumulator_type = torch.float16

    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)

    In0 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In1 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In2 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In3 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In4 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In5 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In6 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In7 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)

    Out0 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out1 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out2 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out3 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out4 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out5 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out6 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out7 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    sc0, sc1, sc2, sc3 = 1.0, 2.0, 3.0, 4.0
    sc4, sc5, sc6, sc7, sc8 = 5.0, 6.0, 7.0, 8.0, 9.0

    def epi(
        accum,
        In0,
        In1,
        In2,
        In3,
        In4,
        In5,
        In6,
        In7,
        sc0,
        sc1,
        sc2,
        sc3,
        sc4,
        sc5,
        sc6,
        sc7,
        sc8,
    ):
        Out0 = accum * sc0 + In0
        Out1 = Out0 + In1 * sc1
        Out2 = Out1 - In2 * sc2
        Out3 = Out2 + In3 * sc3
        Out4 = Out3 - In4 * sc4
        Out5 = Out4 + In5 * sc5
        Out6 = Out5 - In6 * sc6
        Out7 = Out6 + In7 * sc7
        D = Out7 * sc8
        return Out0, Out1, Out2, Out3, Out4, Out5, Out6, Out7, D

    epi_args = ops.EpilogueArguments(
        epi,
        In0=In0,
        In1=In1,
        In2=In2,
        In3=In3,
        In4=In4,
        In5=In5,
        In6=In6,
        In7=In7,
        Out0=Out0,
        Out1=Out1,
        Out2=Out2,
        Out3=Out3,
        Out4=Out4,
        Out5=Out5,
        Out6=Out6,
        Out7=Out7,
        D=D,
        sc0=sc0,
        sc1=sc1,
        sc2=sc2,
        sc3=sc3,
        sc4=sc4,
        sc5=sc5,
        sc6=sc6,
        sc7=sc7,
        sc8=sc8,
    )
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(
        args, target_sm=device_or_env_target_sm(), providers=[ops.CuTeDSLProvider]
    )
    assert len(operators) > 0
    operator = operators[0]

    assert operator.supports(args)
    compiled_artifact = operator.compile(args)
    stream = current_stream()

    n_iterations = 100

    api_time = _benchmark_cpu(
        "With CUTLASS Operator API (operator.run())",
        lambda: operator.run(
            args,
            compiled_artifact=compiled_artifact,
            stream=stream,
            assume_supported_args=True,
        ),
        n_iterations,
    )

    compiled_obj = compiled_artifact.compiled_obj
    direct_args = _extract_runtime_args(
        args.A.tensor,
        args.B.tensor,
        to_cuda_stream(stream),
        *args.epilogue.parameters,
    )

    _benchmark_cpu(
        "Argument extraction",
        lambda: _extract_runtime_args(
            args.A.tensor,
            args.B.tensor,
            to_cuda_stream(stream),
            *args.epilogue.parameters,
        ),
        n_iterations,
    )

    direct_time = _benchmark_cpu(
        "Direct CuTe DSL",
        lambda: compiled_obj(*direct_args),
        n_iterations,
    )

    overhead_us = api_time - direct_time
    print(f"  Overhead: {overhead_us:.1f} us over direct CuTe DSL")

    torch.cuda.synchronize()
    reference = epi(
        A @ B,
        In0,
        In1,
        In2,
        In3,
        In4,
        In5,
        In6,
        In7,
        sc0,
        sc1,
        sc2,
        sc3,
        sc4,
        sc5,
        sc6,
        sc7,
        sc8,
    )
    for out, ref in zip([Out0, Out1, Out2, Out3, Out4, Out5, Out6, Out7, D], reference):
        assert_close_with_reference_conversion(out, ref, out.dtype)
