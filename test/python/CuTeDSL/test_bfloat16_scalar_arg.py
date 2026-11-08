# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
Unit tests for passing a ``BFloat16`` scalar from the host to a kernel.

The value must be rounded to nearest even, like torch does, and not truncated.
A kernel stores the argument, through the default call path and, when
``tvm_ffi`` is installed, through the TVM FFI path.
"""

import importlib.util
import math
import unittest

import cutlass.cute as cute
import torch
from cutlass import BFloat16
from cutlass.cute.runtime import from_dlpack

VALUES = [
    0.0,
    -0.0,
    0.1,
    -0.1,
    1.0,
    1.0 + 2**-8,  # tie, rounds down to even
    1.0 + 3 * 2**-8,  # tie, rounds up to even
    1.0 + 2**-8 + 2**-20,  # just above a tie
    3.0e-39,  # subnormal
    1e-40,
    1e-7,
    65520.0,
    3.38e38,
    3.4e38,  # rounds to inf
    -3.4e38,
    1e39,
    float("inf"),
    float("-inf"),
]


def _torch_bits(v):
    return torch.tensor(v, dtype=torch.bfloat16).view(torch.int16).item() & 0xFFFF


def _is_nan(bits):
    return (bits & 0x7FFF) > 0x7F80


@cute.kernel
def _store_kernel(x: BFloat16, out: cute.Tensor):
    out[0] = x


@cute.jit
def _store(x: BFloat16, out: cute.Tensor):
    _store_kernel(x, out).launch(grid=[1, 1, 1], block=[1, 1, 1])


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class BFloat16ArgKernelTest(unittest.TestCase):
    def _check(self, call):
        out = torch.zeros(1, dtype=torch.bfloat16, device="cuda")
        for v in VALUES + [float("nan")]:
            with self.subTest(v=v):
                call(v, out)
                torch.cuda.synchronize()
                got = out.view(torch.int16).item() & 0xFFFF
                if math.isnan(v):
                    self.assertTrue(_is_nan(got))
                else:
                    self.assertEqual(hex(got), hex(_torch_bits(v)))

    def test_default(self):
        def call(v, out):
            _store(BFloat16(v), from_dlpack(out))

        self._check(call)

    @unittest.skipUnless(importlib.util.find_spec("tvm_ffi"), "needs tvm_ffi")
    def test_tvm_ffi(self):
        out = torch.zeros(1, dtype=torch.bfloat16, device="cuda")
        compiled = cute.compile(
            _store,
            BFloat16(0.0),
            from_dlpack(out, enable_tvm_ffi=True),
            options="--enable-tvm-ffi",
        )
        self._check(compiled)


if __name__ == "__main__":
    unittest.main()
