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
Unit tests for lowering integer constants to MLIR.

Regression for #3312: an unsigned integer constant whose magnitude exceeds
``INT64_MAX`` (e.g. ``Uint64(2**64 - 1)``) used to raise
``TypeError: get(): incompatible function arguments`` during IR emission,
because ``IntegerAttr.get()`` takes a signed C ``int64_t``. Such values must
be lowered as their two's-complement signed representation (same bit pattern).
"""

import unittest

import cutlass
import cutlass.cute as cute
from cutlass import Int64, Uint32, Uint64


def _compile_constant(dtype, value):
    """Compile a nullary kernel that materializes ``dtype(value)`` into IR."""

    @cute.jit
    def entry():
        # Forcing the constant into an MLIR value is the path that used to
        # raise for unsigned magnitudes above INT64_MAX.
        dtype(value).ir_value()

    cute.compile(entry)


class TestIntegerConstantLowering(unittest.TestCase):
    def test_uint64_above_int64_max(self):
        """The reported failing range: Uint64 magnitudes > INT64_MAX."""
        for value in (2**63, 2**63 + 12345, 2**64 - 1):
            with self.subTest(value=value):
                _compile_constant(Uint64, value)

    def test_uint64_within_int64_range(self):
        """Uint64 values that already fit a signed int64 keep working."""
        for value in (0, 1, 2**63 - 1):
            with self.subTest(value=value):
                _compile_constant(Uint64, value)

    def test_other_integer_types_unaffected(self):
        """Narrower unsigned and signed types are unchanged."""
        _compile_constant(Uint32, 2**32 - 1)
        _compile_constant(Int64, -1)
        _compile_constant(Int64, 2**63 - 1)

    def test_uint64_above_int64_max_in_binary_ops(self):
        """The same overflow reached through binary operators on a dynamic
        operand: masking / offsetting / comparing a Uint64 against a literal
        above INT64_MAX (e.g. an all-ones 0xFFFFFFFFFFFFFFFF mask). The
        Numeric.to path fix alone does not cover this operator path. (#3312)"""

        @cute.jit
        def mask(a: Uint64):
            (a | (2**64 - 1)).ir_value()

        @cute.jit
        def offset(a: Uint64):
            (a + (2**63)).ir_value()

        @cute.jit
        def compare(a: Uint64):
            (a < (2**63 + 7)).ir_value()

        cute.compile(mask, Uint64(1))
        cute.compile(offset, Uint64(1))
        cute.compile(compare, Uint64(1))


if __name__ == "__main__":
    unittest.main()
