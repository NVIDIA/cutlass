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

"""Move flat Tensor view construction into a host JIT function.

Run from the repository root::

    python examples/python/CuTeDSL/dsl_tutorials/tensor_layout_manipulation.py

``permute``, ``transpose``, ``unsqueeze`` and ``expand`` can be expressed by
reusing a tensor's iterator with a different layout. These operations do not
move tensor data. The copy kernel below only materializes each view so that
its values can be compared with PyTorch.

The examples reuse each compiled function with two different input shapes.
They use flat, positive-stride input layouts. They are recipes for the
specific ranks shown here, not general Tensor methods for nested layouts.
Expanded views have a zero stride and are only read by the kernel; writing
through them would let multiple logical elements address the same location.

The optional benchmark measures CPU submission time, including argument
packing and the kernel launch. It compares per-call PyTorch view creation and
CuTe wrapping, view construction inside host JIT, and a cached view. Compilation,
allocation and GPU synchronization are outside the timed region. Results
depend on the host CPU and invocation path as well as the GPU workload.
"""

import argparse
import statistics
import time

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def copy_kernel(source: cute.Tensor, destination: cute.Tensor):
    thread, _, _ = cute.arch.thread_idx()
    block, _, _ = cute.arch.block_idx()
    index = block * 256 + thread
    if index < cute.size(destination):
        destination[index] = source[index]


@cute.jit
def copy_view(source: cute.Tensor, destination: cute.Tensor, stream: cuda.CUstream):
    copy_kernel(source, destination).launch(
        grid=(cute.ceil_div(cute.size(destination), 256), 1, 1),
        block=(256, 1, 1),
        stream=stream,
    )


@cute.jit
def transform_and_copy(
    source: cute.Tensor,
    destination: cute.Tensor,
    operation: cutlass.Constexpr,
    stream: cuda.CUstream,
):
    if cutlass.const_expr(operation == "permute"):
        # (batch, M, N) -> (N, batch, M): permute shape AND stride.
        layout = cute.select(source.layout, mode=[2, 0, 1])
    elif cutlass.const_expr(operation == "transpose"):
        # Swap the last two modes: (batch, M, N) -> (batch, N, M).
        layout = cute.select(source.layout, mode=[0, 2, 1])
    elif cutlass.const_expr(operation == "unsqueeze"):
        # (M, N) -> (M, 1, N). The inserted mode's stride is arbitrary
        # because its only valid coordinate is zero.
        layout = cute.make_layout(
            (source.shape[0], 1, source.shape[1]),
            stride=(source.stride[0], 0, source.stride[1]),
        )
    else:
        # Expand (M, 1) -> (M, N) by reading each row's element N times.
        # N comes from the output's dynamic shape.
        layout = cute.make_layout(destination.shape, stride=(source.stride[0], 0))
    view = cute.make_tensor(source.iterator, layout)
    copy_view(view, destination, stream)


def torch_view(source, operation, columns):
    if operation == "permute":
        return source.permute(2, 0, 1)
    if operation == "transpose":
        return source.transpose(1, 2)
    if operation == "unsqueeze":
        return source.unsqueeze(1)
    return source.expand(source.shape[0], columns)


def host_time_us(call, iterations, *args, repeats=5):
    for _ in range(10):
        call(*args)
    samples = []
    for _ in range(repeats):
        torch.cuda.synchronize()
        start = time.perf_counter_ns()
        for _ in range(iterations):
            call(*args)
        elapsed = time.perf_counter_ns() - start
        torch.cuda.synchronize()
        samples.append(elapsed / iterations / 1000)
    return statistics.median(samples)


def copy_torch_view(source, operation, columns, compiled_copy, destination, stream):
    view = torch_view(source, operation, columns)
    view_cute = from_dlpack(view).mark_layout_dynamic()
    compiled_copy(view_cute, destination, stream)


def run(iterations=0):
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    operations = ("permute", "transpose", "unsqueeze", "expand")
    for operation in operations:
        compiled_transform = None
        for rows, columns, batch in ((17, 23, 2), (31, 9, 3)):
            # Strided input also exercises preservation of the existing strides.
            if operation in ("permute", "transpose"):
                storage_shape = (batch, rows, columns * 2)
            elif operation == "unsqueeze":
                storage_shape = (rows, columns * 2)
            else:
                storage_shape = (rows, 2)
            source = torch.randn(storage_shape, device="cuda")[..., ::2]
            reference = torch_view(source, operation, columns)
            destination = torch.empty(reference.shape, device="cuda")
            source_cute = from_dlpack(source).mark_layout_dynamic()
            destination_cute = from_dlpack(destination).mark_layout_dynamic()
            reference_cute = from_dlpack(reference).mark_layout_dynamic()

            if compiled_transform is None:
                compiled_transform = cute.compile(
                    transform_and_copy, source_cute, destination_cute, operation, stream
                )
                compiled_copy = cute.compile(
                    copy_view, reference_cute, destination_cute, stream
                )
            compiled_transform(source_cute, destination_cute, stream)
            torch.testing.assert_close(destination, reference, atol=0, rtol=0)
            compiled_copy(reference_cute, destination_cute, stream)
            torch.testing.assert_close(destination, reference, atol=0, rtol=0)
            print(
                f"{operation}: {tuple(source.shape)} -> {tuple(reference.shape)} PASS"
            )

        if iterations:
            timings = {
                "PyTorch view + CuTe wrapping per call": host_time_us(
                    copy_torch_view,
                    iterations,
                    source,
                    operation,
                    columns,
                    compiled_copy,
                    destination_cute,
                    stream,
                ),
                "host JIT view": host_time_us(
                    compiled_transform,
                    iterations,
                    source_cute,
                    destination_cute,
                    stream,
                ),
                "cached view": host_time_us(
                    compiled_copy,
                    iterations,
                    reference_cute,
                    destination_cute,
                    stream,
                ),
            }
            for name, latency in timings.items():
                print(f"  {name}: {latency:.3f} us/call (CPU submission)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--iterations",
        type=int,
        default=0,
        help="Calls per timing sample; zero runs only correctness checks",
    )
    args = parser.parse_args()
    if args.iterations < 0:
        parser.error("--iterations must be nonnegative")
    run(args.iterations)
