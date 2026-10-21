# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""
Unit tests for cutlass.cute.arch.load — in particular the f16/bf16 path,
which nvvm.load.ext rejects directly and load() must route via uint16 +
bitcast.
"""

import unittest

import cutlass
import cutlass.cute as cute
from cutlass import (
    BFloat16,
    Float16,
    Float32,
    Int32,
    Uint16,
    Uint32,
)
from cutlass.cute.runtime import make_fake_tensor


def _compile_load(dtype):
    """Compile a kernel that loads one element of `dtype` and sinks it as f32.

    Raises DSLRuntimeError if MLIR verification fails (which is what happens
    when nvvm.load.ext rejects the dtype).
    """

    @cute.kernel
    def k(buf: cute.Tensor, out: cute.Tensor):
        tidx, _, _ = cute.arch.thread_idx()
        v = cute.arch.load(buf.iterator + tidx, dtype)
        cute.arch.store(out.iterator + tidx, Float32(v))

    @cute.jit
    def entry(buf: cute.Tensor, out: cute.Tensor):
        k(buf, out).launch(grid=(1, 1, 1), block=(32, 1, 1))

    buf = make_fake_tensor(dtype, (32,), stride=(1,), assumed_align=4)
    out = make_fake_tensor(Float32, (32,), stride=(1,), assumed_align=4)
    cute.compile(entry, buf, out)


class TestArchLoad(unittest.TestCase):
    # ---- 16-bit FP: covered by the uint16+bitcast workaround in load() ----

    def test_bfloat16(self):
        _compile_load(BFloat16)

    def test_float16(self):
        _compile_load(Float16)

    # ---- regression: types that go through nvvm.load.ext directly ----

    def test_float32(self):
        _compile_load(Float32)

    def test_uint16(self):
        _compile_load(Uint16)

    def test_uint32(self):
        _compile_load(Uint32)

    def test_int32(self):
        _compile_load(Int32)


if __name__ == "__main__":
    unittest.main()
