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
Unit tests for ``cute.arch.red`` with its default memory ordering.

``sem=None`` is the default and means relaxed, as in PTX. The tests reduce
from every thread of a block with and without ``sem`` and check the totals.
They need a CUDA GPU and skip without one.
"""

import unittest

import torch

import cutlass.cute as cute
from cutlass import Float32, Int32
from cutlass.cute.runtime import from_dlpack

THREADS = 64


def _run(dtype, sem, scope):
    @cute.kernel
    def kernel(x: cute.Tensor):
        cute.arch.red(
            x.iterator.llvm_ptr, dtype(1), op="add", dtype=dtype, sem=sem, scope=scope
        )

    @cute.jit
    def launch(x: cute.Tensor):
        kernel(x).launch(grid=[1, 1, 1], block=[THREADS, 1, 1])

    torch_dtype = torch.float32 if dtype is Float32 else torch.int32
    x = torch.zeros(1, dtype=torch_dtype, device="cuda")
    launch(from_dlpack(x))
    torch.cuda.synchronize()
    return x.item()


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class RedDefaultSemTest(unittest.TestCase):
    def test_add(self):
        for dtype in (Float32, Int32):
            for sem in (None, "relaxed", "release"):
                for scope in (None, "gpu"):
                    with self.subTest(dtype=dtype.__name__, sem=sem, scope=scope):
                        self.assertEqual(_run(dtype, sem, scope), THREADS)


if __name__ == "__main__":
    unittest.main()
