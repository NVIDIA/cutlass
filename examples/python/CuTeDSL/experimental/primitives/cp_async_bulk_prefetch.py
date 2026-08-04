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

"""
Raw ``cp.async.bulk.prefetch`` smoke test.

The PTX instruction prefetches a global-memory byte range into L2 without a
destination or completion token.  This example issues one best-effort prefetch
through ``cutlass.experimental.primitives`` and then performs an ordinary
global-memory copy so ``verify`` has an observable result.

Requires SM90+.
"""

from functools import lru_cache
from typing import Callable

import torch

import cutlass
import cutlass.cute as cute
import cutlass.experimental.primitives as prims
from cutlass.cute.runtime import make_fake_compact_tensor


_PREFETCH_BYTES: int = 128
_BLOCK: int = 128
_DEFAULT_N: int = _BLOCK


@cute.kernel
def kernel(src: cute.Tensor, dst: cute.Tensor) -> None:
    """Prefetch one compact Float32 tile and copy it to ``dst``.

    ``src`` and ``dst`` are expected to be CUDA tensors with shape
    ``(_DEFAULT_N,)`` and compact layout.  The first thread issues the SM90+
    ``cp.async.bulk.prefetch`` hint, and all ``_BLOCK`` threads copy one
    element so verification has an observable result.
    """
    tidx, _, _ = cute.arch.thread_idx()

    if tidx == 0:
        prims.cp_async_bulk_prefetch(src.iterator.raw_ptr(), _PREFETCH_BYTES)

    dst[tidx] = src[tidx]


@cute.jit
def host(src: cute.Tensor, dst: cute.Tensor) -> None:
    """Launch ``kernel`` as one CTA with ``_BLOCK`` threads."""
    kernel(src, dst).launch(grid=(1, 1, 1), block=(_BLOCK, 1, 1))


@lru_cache(maxsize=None)
def compile() -> Callable:  # noqa: A001
    """Compile and cache the host wrapper for compact Float32 test tensors.

    The fake tensors model ``(_DEFAULT_N,)`` compact layouts.  Compilation uses
    ``--enable-tvm-ffi`` and still requires an environment capable of compiling
    the SM90+ primitive.
    """
    fake_src = make_fake_compact_tensor(cutlass.Float32, (_DEFAULT_N,))
    fake_dst = make_fake_compact_tensor(cutlass.Float32, (_DEFAULT_N,))
    return cute.compile(host, fake_src, fake_dst, options="--enable-tvm-ffi")


def run(compiled_fn: Callable) -> tuple[torch.Tensor, torch.Tensor]:
    """Run the compiled function on CUDA tensors and return ``(dst, src)``.

    Raises:
        RuntimeError: If CUDA is unavailable.  ``src`` and ``dst`` are compact
            CUDA Float32 tensors with shape ``(_DEFAULT_N,)``.
    """
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    src = torch.arange(_DEFAULT_N, dtype=torch.float32, device="cuda")
    dst = torch.zeros_like(src)
    compiled_fn(src, dst)
    torch.cuda.synchronize()
    return dst, src


def _require_sm90_device() -> None:
    """Raise a clear error before compilation on devices below SM90."""
    if not torch.cuda.is_available():
        raise RuntimeError("cp_async_bulk_prefetch requires an SM90+ CUDA GPU")

    major, minor = torch.cuda.get_device_capability()
    if major < 9:
        raise RuntimeError(
            "cp_async_bulk_prefetch requires an SM90+ CUDA GPU, "
            f"got compute capability {major}.{minor}"
        )


def verify() -> None:
    """Compile, run, and assert that the copied tensor matches the source.

    The SM90+ guard runs before compilation to avoid opaque backend failures.
    ``torch.testing.assert_close`` raises if the copied result differs.
    """
    _require_sm90_device()

    compiled_fn = compile()
    print("Compile cp_async_bulk_prefetch OK", flush=True)

    dst, src = run(compiled_fn)
    print("Run cp_async_bulk_prefetch OK", flush=True)

    torch.testing.assert_close(dst, src)
    print(f"verify: PASS  dst[:8] = {dst[:8].tolist()}")


if __name__ == "__main__":
    verify()
