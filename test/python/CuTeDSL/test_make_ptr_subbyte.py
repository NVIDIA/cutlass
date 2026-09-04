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
Unit tests for cute.runtime.make_ptr with sub-byte element types.

make_ptr derived the pointer's assumed alignment as `dtype.width // 8`, which
is 0 for sub-byte element types (Float4E2M1FN, Int4, Float6*); the subsequent
`int(ptr) % assumed_align` alignment check then raised ZeroDivisionError on
every call. Such pointers should default to 1-byte alignment, matching the
compile-time make_ptr in cute/core.py.
"""

import unittest

import cutlass
from cutlass.cute.runtime import make_ptr


class TestMakePtrSubByte(unittest.TestCase):
    def test_sub_byte_dtypes(self):
        for dtype in (
            cutlass.Float4E2M1FN,
            cutlass.Int4,
            cutlass.Float6E2M3FN,
            cutlass.Float6E3M2FN,
        ):
            with self.subTest(dtype=dtype.__name__):
                # Must not raise ZeroDivisionError.
                self.assertIsNotNone(make_ptr(dtype, 0x1000))

    def test_byte_dtypes_unchanged(self):
        for dtype in (cutlass.Int8, cutlass.Float16, cutlass.Float32):
            with self.subTest(dtype=dtype.__name__):
                self.assertIsNotNone(make_ptr(dtype, 0x1000))


if __name__ == "__main__":
    unittest.main()
