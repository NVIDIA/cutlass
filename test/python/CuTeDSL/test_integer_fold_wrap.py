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
Unit tests for folding integer arithmetic on Python-payload operands.

When both operands of ``+``, ``-``, ``*``, ``<<`` or ``**`` hold Python
integers, ``Numeric`` computes the result in Python. The emitted arith ops
wrap in two's complement, so the fold has to wrap the exact result into the
result dtype the same way: without a literal-out-of-range warning, and without
an ``OverflowError`` when the exact result leaves the 64-bit range.

No GPU is needed: the folds are pure Python and the jit case only compiles.
"""

import operator
import unittest
import warnings

import cutlass
import cutlass.cute as cute
from cutlass import Int8, Int16, Int32, Int64, Uint8, Uint16, Uint32, Uint64

TYPES = [Int8, Uint8, Int16, Uint16, Int32, Uint32, Int64, Uint64]

OPS = [
    ("add", operator.add),
    ("sub", operator.sub),
    ("mul", operator.mul),
    ("lshift", operator.lshift),
    ("pow", operator.pow),
]


def _wrap(value, ty):
    bits = value & ((1 << ty.width) - 1)
    if ty.signed and bits >> (ty.width - 1):
        bits -= 1 << ty.width
    return bits


def _operands(ty):
    lo, hi = ty.min, ty.max
    return [(hi, hi), (lo, lo), (hi, 1), (lo, 1), (hi, 2), (3, ty.width - 1)]


class TestIntegerFoldWrap(unittest.TestCase):
    def test_fold_wraps_like_twos_complement(self):
        for ty in TYPES:
            for a, b in _operands(ty):
                for name, op in OPS:
                    if name in ("lshift", "pow") and not 0 <= b < ty.width:
                        continue
                    with self.subTest(ty=ty.__name__, a=a, b=b, op=name):
                        with warnings.catch_warnings():
                            warnings.simplefilter("error")
                            res = op(ty(a), ty(b))
                        self.assertIs(type(res), ty)
                        self.assertEqual(res.value, _wrap(op(a, b), ty))

    def test_fold_with_python_int_operand(self):
        with warnings.catch_warnings():
            warnings.simplefilter("error")
            self.assertEqual((Uint64(2**64 - 1) + 1).value, 0)
            self.assertEqual((Int64(-(2**63)) - 1).value, 2**63 - 1)
            self.assertEqual((Int32(2**31 - 1) + 1).value, -(2**31))

    def test_64bit_hash_constants(self):
        # splitmix64 style multiply of two 64-bit constants.
        res = Uint64(0x9E3779B97F4A7C15) * Uint64(0xBF58476D1CE4E5B9)
        self.assertEqual(res.value, (0x9E3779B97F4A7C15 * 0xBF58476D1CE4E5B9) % 2**64)

    def test_in_range_folds_unchanged(self):
        self.assertEqual((Int32(-7) // Int32(2)).value, -4)
        self.assertEqual((Int32(5) * Int32(-3)).value, -15)
        self.assertEqual((Uint8(250) - Uint8(10)).value, 240)

    def test_fold_inside_jit(self):
        @cute.jit
        def fold():
            x = Uint64(2**63) + Uint64(2**63)
            y = Int64(2**40) * Int64(2**40)
            cute.printf("%llu %lld", x, y)

        cute.compile(fold)


if __name__ == "__main__":
    unittest.main()
