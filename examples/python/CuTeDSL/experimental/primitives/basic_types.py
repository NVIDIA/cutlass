# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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

"""Basic Pointer and Vector primitive API examples.

This module keeps small, architecture-portable examples for the low-level
``cutlass.Pointer`` and ``cutlass.Vector`` APIs:

* ``Pointer.masked_load`` / ``Pointer.masked_store``
* 2-D ``Vector`` slicing
* scalar broadcasting in ``Vector`` arithmetic
* ``cutlass.vector.outerproduct``

Each example has a compile/run/verify entry point so pytest can call the Python
API directly without shelling out through this file's CLI.
"""

import argparse
from functools import lru_cache
from typing import Callable, Literal, TypeAlias, cast

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor

ExampleName: TypeAlias = Literal[
    "masked_load_store",
    "vector_2d_slice",
    "vector_scalar_broadcast",
    "vector_outerproduct",
]
EXAMPLES: tuple[ExampleName, ...] = (
    "masked_load_store",
    "vector_2d_slice",
    "vector_scalar_broadcast",
    "vector_outerproduct",
)


def _normalize_example(example: str) -> ExampleName:
    if example not in EXAMPLES:
        raise ValueError(f"example must be one of {EXAMPLES}, got {example!r}")
    return cast(ExampleName, example)


@cute.kernel
def _masked_load_store_kernel(src: cute.Tensor, dst: cute.Tensor) -> None:
    """Exercise masked pointer load and masked pointer store."""
    src_ptr = src.iterator.raw_ptr()
    dst_ptr = dst.iterator.raw_ptr()
    load_mask = cutlass.Vector.from_elements((True, True, True, True), cutlass.Boolean)
    store_mask = cutlass.Vector.from_elements(
        (True, False, True, False),
        cutlass.Boolean,
    )

    values = src_ptr.masked_load(load_mask, alignment=16)
    dst_ptr.store(values, alignment=16)

    shifted = values + cutlass.Float32(10.0)
    (dst_ptr + 4).masked_store(shifted, store_mask, alignment=16)


@cute.jit
def _masked_load_store_host(src: cute.Tensor, dst: cute.Tensor) -> None:
    _masked_load_store_kernel(src, dst).launch(grid=(1, 1, 1), block=(1, 1, 1))


@cute.kernel
def _vector_2d_slice_kernel(dst: cute.Tensor) -> None:
    """Take a 2-D vector slice and store its extracted lanes."""
    row = cutlass.Vector.from_elements((1.0, 2.0, 3.0, 4.0), cutlass.Float32)
    matrix = cutlass.vector.broadcast_to(row, (2, 4))
    sub = matrix[:, 1:3]
    dst_ptr = dst.iterator.raw_ptr()

    dst_ptr[0] = sub[0, 0]
    dst_ptr[1] = sub[0, 1]
    dst_ptr[2] = sub[1, 0]
    dst_ptr[3] = sub[1, 1]


@cute.jit
def _vector_2d_slice_host(dst: cute.Tensor) -> None:
    _vector_2d_slice_kernel(dst).launch(grid=(1, 1, 1), block=(1, 1, 1))


@cute.kernel
def _vector_scalar_broadcast_kernel(scale_src: cute.Tensor, dst: cute.Tensor) -> None:
    """Broadcast a runtime scalar load across vector arithmetic."""
    base = cutlass.Vector.from_elements((1.0, 2.0, 3.0, 4.0), cutlass.Float32)
    scale = scale_src.iterator.raw_ptr().load()
    result = base * scale + cutlass.Float32(1.0)
    dst.iterator.raw_ptr().store(result, alignment=16)


@cute.jit
def _vector_scalar_broadcast_host(scale_src: cute.Tensor, dst: cute.Tensor) -> None:
    _vector_scalar_broadcast_kernel(scale_src, dst).launch(
        grid=(1, 1, 1), block=(1, 1, 1)
    )


@cute.kernel
def _vector_outerproduct_kernel(dst: cute.Tensor) -> None:
    """Build a rank-1 outer product through the vector helper namespace."""
    a = cutlass.Vector.from_elements((1.0, 2.0), cutlass.Float32)
    b = cutlass.Vector.from_elements((3.0, 4.0, 5.0), cutlass.Float32)
    matrix = cutlass.vector.outerproduct(a, b)
    dst_ptr = dst.iterator.raw_ptr()

    dst_ptr[0] = matrix[0, 0]
    dst_ptr[1] = matrix[0, 1]
    dst_ptr[2] = matrix[0, 2]
    dst_ptr[3] = matrix[1, 0]
    dst_ptr[4] = matrix[1, 1]
    dst_ptr[5] = matrix[1, 2]


@cute.jit
def _vector_outerproduct_host(dst: cute.Tensor) -> None:
    _vector_outerproduct_kernel(dst).launch(grid=(1, 1, 1), block=(1, 1, 1))


@lru_cache(maxsize=None)
def compile(example: str = "masked_load_store") -> Callable:  # noqa: A001
    """AOT-compile one Pointer/Vector primitive example."""
    example = _normalize_example(example)
    if example == "masked_load_store":
        fake_src = make_fake_compact_tensor(cutlass.Float32, (4,), assumed_align=16)
        fake_dst = make_fake_compact_tensor(cutlass.Float32, (8,), assumed_align=16)
        return cute.compile(
            _masked_load_store_host,
            fake_src,
            fake_dst,
            options="--enable-tvm-ffi",
        )
    if example == "vector_2d_slice":
        fake_dst = make_fake_compact_tensor(cutlass.Float32, (4,), assumed_align=16)
        return cute.compile(
            _vector_2d_slice_host,
            fake_dst,
            options="--enable-tvm-ffi",
        )
    if example == "vector_scalar_broadcast":
        fake_scale = make_fake_compact_tensor(cutlass.Float32, (1,), assumed_align=4)
        fake_dst = make_fake_compact_tensor(cutlass.Float32, (4,), assumed_align=16)
        return cute.compile(
            _vector_scalar_broadcast_host,
            fake_scale,
            fake_dst,
            options="--enable-tvm-ffi",
        )

    fake_dst = make_fake_compact_tensor(cutlass.Float32, (6,), assumed_align=16)
    return cute.compile(
        _vector_outerproduct_host,
        fake_dst,
        options="--enable-tvm-ffi",
    )


def run(compiled_fn: Callable, example: str = "masked_load_store") -> tuple:
    """Run one compiled example and return tensors needed by verification."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    example = _normalize_example(example)
    if example == "masked_load_store":
        src = torch.arange(4, dtype=torch.float32, device="cuda")
        dst = torch.full((8,), -5.0, dtype=torch.float32, device="cuda")
        compiled_fn(src, dst)
        torch.cuda.synchronize()
        return dst, src

    if example == "vector_2d_slice":
        dst = torch.empty(4, dtype=torch.float32, device="cuda")
        compiled_fn(dst)
        torch.cuda.synchronize()
        return (dst,)

    if example == "vector_scalar_broadcast":
        scale = torch.tensor([2.0], dtype=torch.float32, device="cuda")
        dst = torch.empty(4, dtype=torch.float32, device="cuda")
        compiled_fn(scale, dst)
        torch.cuda.synchronize()
        return dst, scale

    dst = torch.empty(6, dtype=torch.float32, device="cuda")
    compiled_fn(dst)
    torch.cuda.synchronize()
    return (dst,)


def _expected(example: ExampleName, run_result: tuple) -> torch.Tensor:
    if example == "masked_load_store":
        return torch.tensor(
            [0.0, 1.0, 2.0, 3.0, 10.0, -5.0, 12.0, -5.0],
            dtype=torch.float32,
            device="cuda",
        )
    if example == "vector_2d_slice":
        return torch.tensor([2.0, 3.0, 2.0, 3.0], dtype=torch.float32, device="cuda")
    if example == "vector_scalar_broadcast":
        _dst, scale = run_result
        base = torch.tensor([1.0, 2.0, 3.0, 4.0], dtype=torch.float32, device="cuda")
        return base * scale[0] + 1.0
    return torch.tensor(
        [3.0, 4.0, 5.0, 6.0, 8.0, 10.0],
        dtype=torch.float32,
        device="cuda",
    )


def verify(example: str = "all") -> None:
    """Compile, run, and verify one example or the full suite."""
    examples = EXAMPLES if example == "all" else (_normalize_example(example),)
    for name in examples:
        compiled_fn = compile(name)
        print(f"Compile basic_types ({name}) OK", flush=True)
        run_result = run(compiled_fn, name)
        dst = run_result[0]
        expected = _expected(name, run_result)
        torch.testing.assert_close(dst, expected, atol=0, rtol=0)
        print(f"verify basic_types ({name}): PASS", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Pointer and Vector primitive API examples",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--example",
        choices=("all",) + EXAMPLES,
        default="all",
        help="example variant to run",
    )
    args = parser.parse_args()
    verify(args.example)
