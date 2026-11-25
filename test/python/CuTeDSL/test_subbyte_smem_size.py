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
Unit tests for shared memory sizes of sub-byte element arrays.

``struct.MemRange[T, n]`` and ``SmemAllocator.allocate_array(T, n)`` have to
round the number of bits up to whole bytes; rounding down leaves the last,
partially filled byte of an fp4/int4 array to the next allocation or struct
member.
"""

import re
import unittest
from unittest import mock

import cutlass
import cutlass.cute as cute
from cutlass import Float4E2M1FN, Int4, Int8
from cutlass.cutlass_dsl import CuTeDSL
from cutlass.memory import SmemAllocator


class TestMemRangeSubbyteSize(unittest.TestCase):
    def test_size_in_bytes_rounds_up(self):
        for n, expected in [(1, 1), (2, 1), (3, 2), (4, 2), (5, 3), (128, 64)]:
            with self.subTest(n=n):
                self.assertEqual(
                    cute.struct.MemRange[Float4E2M1FN, n].size_in_bytes, expected
                )
                self.assertEqual(cute.struct.MemRange[Int4, n].size_in_bytes, expected)

    def test_byte_sized_elements_unchanged(self):
        self.assertEqual(cute.struct.MemRange[Int8, 3].size_in_bytes, 3)
        self.assertEqual(cute.struct.MemRange[cutlass.Float32, 3].size_in_bytes, 12)
        self.assertEqual(cute.struct.MemRange[cutlass.Boolean, 3].size_in_bytes, 3)

    def test_struct_member_after_odd_fp4_array_does_not_overlap(self):
        @cute.struct
        class _S:
            a: cute.struct.MemRange[Float4E2M1FN, 3]
            b: Int8

        self.assertEqual(_S._offsets["b"], 2)
        self.assertEqual(_S.__sizeof__(), 3)

    def test_union_with_odd_fp4_array(self):
        @cute.union
        class _U:
            a: cute.struct.MemRange[Float4E2M1FN, 5]
            b: Int8

        self.assertEqual(_U.__sizeof__(), 3)


class TestAllocateArraySubbyteSize(unittest.TestCase):
    def setUp(self):
        dsl = CuTeDSL._get_dsl()
        patcher = mock.patch.object(dsl.envar, "keep_ir_clean", True)
        patcher.start()
        self.addCleanup(patcher.stop)

    def alloca_sizes(self, num_elems):
        @cute.kernel
        def k():
            smem = SmemAllocator()
            smem.allocate_array(Float4E2M1FN, num_elems)
            smem.allocate_array(Int8, 1)

        @cute.jit
        def entry():
            k().launch(grid=(1, 1, 1), block=(32, 1, 1))

        mlir = cute.compile(entry).artifacts.MLIR
        aliases = dict(
            re.findall(r'^(!memref_smem_i8\w*) = !cute.memref<i8, smem, "(\d+):', mlir, re.M)
        )
        allocas = re.findall(r"cute\.memref\.alloca\(\).*: (!memref_smem_i8\w*)", mlir)
        return [int(aliases[a]) for a in allocas]

    def test_allocate_array_rounds_up(self):
        for n, expected in [(1, 1), (3, 2), (4, 2), (5, 3)]:
            with self.subTest(n=n):
                self.assertEqual(self.alloca_sizes(n), [expected, 1])


if __name__ == "__main__":
    unittest.main()
