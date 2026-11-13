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
Unit tests for @cute.struct and @cute.union declared in a module that uses
`from __future__ import annotations`, where every field annotation is stored
as a string instead of the DSL type object.
"""

from __future__ import annotations

import unittest

import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
from cutlass import Float32, Int16, Int32, Int64, Int8
from cutlass.cute.runtime import make_fake_tensor

_STAGES = 3


@cute.struct
class _Inner:
    a: Int16
    b: cutlass.Float32


@cute.struct
class _Storage:
    bar: cute.struct.MemRange[Int64, _STAGES]
    inner: _Inner
    x: cute.struct.Align[Int32, 16]


@cute.union
class _Union:
    i: Int32
    raw: cute.struct.MemRange[Int8, 20]


@cute.struct
class _OneTile:
    sA: cute.struct.MemRange[Float32, 128]


def _make_local_struct(n):
    @cute.struct
    class _Local:
        buf: cute.struct.MemRange[Float32, n]
        flag: Int32

    return _Local


class TestStructPostponedAnnotations(unittest.TestCase):
    def test_struct_layout(self):
        self.assertEqual(_Inner.__sizeof__(), 8)
        self.assertEqual(_Inner.__alignof__(), 4)
        self.assertEqual(_Storage._offsets, {"bar": 0, "inner": 24, "x": 32})
        self.assertEqual(_Storage.__sizeof__(), 48)
        self.assertEqual(_Storage.__alignof__(), 16)

    def test_union_layout(self):
        self.assertEqual(_Union.__sizeof__(), 20)
        self.assertEqual(_Union.__alignof__(), 4)

    def test_annotation_from_enclosing_function_scope(self):
        local = _make_local_struct(5)
        self.assertEqual(local._offsets, {"buf": 0, "flag": 20})
        self.assertEqual(local.__sizeof__(), 24)

    def test_allocate_in_kernel(self):
        @cute.kernel
        def k(gA: cute.Tensor):
            tidx, _, _ = cute.arch.thread_idx()
            smem_alloc = utils.SmemAllocator()
            storage = smem_alloc.allocate(_OneTile)
            sA = storage.sA.get_tensor(cute.make_layout((128,), stride=(1,)))
            sA[tidx] = gA[tidx]

        @cute.jit
        def entry(gA: cute.Tensor):
            k(gA).launch(grid=(1, 1, 1), block=(32, 1, 1), smem=512)

        gA = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
        cute.compile(entry, gA)


if __name__ == "__main__":
    unittest.main()
