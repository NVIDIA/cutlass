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
Regression test for the vectorization of bf16 tile stores (#3463).

A per-thread ``[8, 8]`` bf16 tile is converted from f32 one row at a time and
written out with ``autovec_copy``. Each row is 16 bytes, so the stores should
be ``st.global.v4.b32``. In 4.7.0 they were split into 64 scalar
``st.global.b16`` stores. The kernel is compiled with fake tensors for an
explicit target and only the PTX is checked, so no GPU is needed.
"""

import re
import tempfile
import unittest

import cutlass
import cutlass.cute as cute
from cutlass import Float32


CHUNKS, ELTS, THREADS = 8, 8, 32  # per-thread bf16 tile: 8 rows x 8 elements
N = THREADS * ELTS


class _Bf16TileStore:
    @cute.jit
    def __call__(self, mX, mY, stream):
        self.kernel(mX, mY).launch(
            grid=[1, 1, 1], block=[THREADS, 1, 1], stream=stream
        )

    @cute.kernel
    def kernel(self, mX: cute.Tensor, mY: cute.Tensor):
        tidx, _, _ = cute.arch.thread_idx()
        gX = cute.local_tile(mX, (CHUNKS, ELTS), (0, tidx))
        rX = cute.make_rmem_tensor_like(gX)
        cute.autovec_copy(gX, rX)
        acc = cute.make_rmem_tensor_like(rX, Float32)
        for c in cutlass.range_constexpr(CHUNKS):
            acc[c, None].store(rX[c, None].load().to(Float32) * 2.0)
        rY = cute.make_rmem_tensor_like(gX)
        for c in cutlass.range_constexpr(CHUNKS):
            rY[c, None].store(acc[c, None].load().to(mY.element_type))
        gY = cute.local_tile(mY, (CHUNKS, ELTS), (0, tidx))
        cute.autovec_copy(rY, gY)


def _fake_2d(n: int) -> cute.Tensor:
    stride = (cute.sym_int64(divisibility=n), 1)
    return cute.runtime.make_fake_tensor(
        cute.BFloat16, (cute.sym_int64(), n), stride=stride, assumed_align=16
    )


def _global_stores(arch: str) -> dict:
    """Return a histogram of the ``st.global`` instructions in the PTX."""
    with tempfile.TemporaryDirectory() as dump_dir:
        compiled = cute.compile(
            _Bf16TileStore(),
            _fake_2d(N),
            _fake_2d(N),
            cute.runtime.make_fake_stream(),
            options=f"--keep-ptx --gpu-arch={arch} --dump-dir={dump_dir}",
        )
        ptx = compiled.__ptx__
    stores = re.findall(r"st\.global[.a-z0-9]*", ptx)
    return {op: stores.count(op) for op in set(stores)}


class TestBf16TileStoreVectorization(unittest.TestCase):
    def check(self, arch: str):
        hist = _global_stores(arch)
        self.assertNotIn("st.global.b16", hist, f"{arch}: {hist}")
        self.assertEqual(hist.get("st.global.v4.b32", 0), CHUNKS, f"{arch}: {hist}")

    def test_sm90a(self):
        self.check("sm_90a")

    def test_sm100a(self):
        self.check("sm_100a")

    def test_sm103a(self):
        self.check("sm_103a")


if __name__ == "__main__":
    unittest.main()
