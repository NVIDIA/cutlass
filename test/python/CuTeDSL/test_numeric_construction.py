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
Unit tests for constructing Integer types from Python scalars.

`Integer.__init__` skips the numpy round-trip when the incoming value is
already representable in the target dtype, since the cast would return it
unchanged. The tests below pin that shortcut to the numpy cast it replaces:
the same stored value for in-range input, the same wrap-around for out-of-range
input, and the same exceptions for values numpy refuses outright.

No GPU or compilation is involved, so these run anywhere.
"""

import math
import unittest

import numpy as np

import cutlass
from cutlass import (
    Boolean,
    Int4,
    Int8,
    Int16,
    Int32,
    Int64,
    Int128,
    Uint8,
    Uint16,
    Uint32,
    Uint64,
    Uint128,
)

# Integer types backed by a numpy dtype, so a cast reference exists.
CASTABLE = [Boolean, Int8, Uint8, Int16, Uint16, Int32, Uint32, Int64, Uint64]

# Widths with no numpy dtype. Constructing these from a Python scalar has always
# tripped the assert in Integer.__init__, and the shortcut must not start
# quietly accepting them.
NOT_CASTABLE = [Int4, Int128, Uint128]

# Boundaries, wrap-around candidates, and values wider than any supported dtype.
INT_VALUES = [
    0,
    1,
    -1,
    5,
    127,
    128,
    255,
    256,
    -128,
    -129,
    32767,
    32768,
    -32768,
    -32769,
    65535,
    65536,
    123456789,
    2**31 - 1,
    2**31,
    -(2**31),
    -(2**31) - 1,
    2**32 - 1,
    2**32,
    -(2**32),
    2**63 - 1,
    2**63,
    -(2**63),
    -(2**63) - 1,
    2**64 - 1,
    2**64,
    2**128,
    10**30,
    -(10**30),
]

BOOL_VALUES = [True, False]

# Only floats whose truncation is well defined for the dtype under test are
# checked against numpy: casting an out-of-range float is undefined behavior in
# numpy and merely warns, so there is no meaningful reference to compare with.
FLOAT_VALUES = [0.0, -0.0, 0.5, -0.5, 1.0, -1.0, 3.7, -3.7, 99.9, -99.9]


def numpy_reference(dtype, x):
    """The cast Integer.__init__ used to perform unconditionally."""
    return int(np.array(x).astype(dtype))


class TestIntegerFromPythonScalar(unittest.TestCase):
    def test_matches_numpy_cast(self):
        """The shortcut and the numpy cast agree, value for value.

        Where numpy refuses the input outright (integers too wide for any C
        type), the same exception must still surface.
        """
        for ty in CASTABLE:
            for x in INT_VALUES + BOOL_VALUES + FLOAT_VALUES:
                if isinstance(x, float) and not (
                    ty._exact_range[0] <= x <= ty._exact_range[1]
                ):
                    continue
                with self.subTest(dtype=ty.__name__, value=x):
                    try:
                        expected = numpy_reference(ty.numpy_dtype, x)
                    except OverflowError:
                        with self.assertRaises(OverflowError):
                            ty(x)
                    else:
                        self.assertEqual(ty(x).value, expected)

    def test_in_range_values_are_preserved(self):
        """Spot-check the shortcut itself rather than its agreement with numpy."""
        self.assertEqual(Int32(5).value, 5)
        self.assertEqual(Int32(-5).value, -5)
        self.assertEqual(Int32(2**31 - 1).value, 2**31 - 1)
        self.assertEqual(Int32(-(2**31)).value, -(2**31))
        self.assertEqual(Uint8(255).value, 255)
        self.assertEqual(Int64(2**63 - 1).value, 2**63 - 1)
        self.assertEqual(Uint64(2**64 - 1).value, 2**64 - 1)

    def test_out_of_range_values_still_wrap(self):
        """Values outside the dtype keep the C wrap-around numpy provides."""
        self.assertEqual(Int32(2**31).value, -(2**31))
        self.assertEqual(Int32(2**32 + 5).value, 5)
        self.assertEqual(Int8(128).value, -128)
        self.assertEqual(Int8(-129).value, 127)
        self.assertEqual(Uint8(256).value, 0)
        self.assertEqual(Uint8(-1).value, 255)
        self.assertEqual(Uint16(65536 + 7).value, 7)

    def test_floats_truncate_toward_zero(self):
        self.assertEqual(Int32(3.7).value, 3)
        self.assertEqual(Int32(-3.7).value, -3)
        self.assertEqual(Int32(0.5).value, 0)
        self.assertEqual(Int32(-0.5).value, 0)
        self.assertEqual(Int8(99.9).value, 99)

    def test_bools_fold_to_zero_and_one(self):
        """bool is an int subclass, so it reaches the same path as an int."""
        for ty in CASTABLE:
            with self.subTest(dtype=ty.__name__):
                self.assertEqual(ty(True).value, 1)
                self.assertEqual(ty(False).value, 0)

    def test_boolean_folds_nonzero_to_one(self):
        """Boolean stores 0/1, never the value it was handed."""
        self.assertEqual(Boolean(0).value, 0)
        self.assertEqual(Boolean(1).value, 1)
        self.assertEqual(Boolean(-1).value, 1)
        self.assertEqual(Boolean(5).value, 1)
        self.assertEqual(Boolean(256).value, 1)
        self.assertEqual(Boolean(3.7).value, 1)

    def test_nan_and_infinity_are_rejected(self):
        """Boolean is exempt: it runs bool() first, so the float never reaches
        the guard. Every other integer type rejects both."""
        for ty in CASTABLE:
            if ty is Boolean:
                continue
            with self.subTest(dtype=ty.__name__):
                with self.assertRaises(ValueError):
                    ty(math.nan)
                with self.assertRaises(OverflowError):
                    ty(math.inf)
                with self.assertRaises(OverflowError):
                    ty(-math.inf)

    def test_boolean_folds_nan_and_infinity_to_true(self):
        """Pins the exemption above, which predates the shortcut."""
        self.assertEqual(Boolean(math.nan).value, 1)
        self.assertEqual(Boolean(math.inf).value, 1)
        self.assertEqual(Boolean(-math.inf).value, 1)

    def test_widths_without_a_numpy_dtype_are_rejected(self):
        """Int4/Int128/Uint128 have no numpy dtype and must keep failing.

        The shortcut sits behind the same guard as the cast, so these still
        raise instead of silently gaining support.
        """
        for ty in NOT_CASTABLE:
            with self.subTest(dtype=ty.__name__):
                self.assertIsNone(ty.numpy_dtype)
                self.assertIsNone(ty._exact_range)
                for x in (0, 1, 5, -1, 3.7, True):
                    with self.assertRaises(AssertionError):
                        ty(x)

    def test_exact_range_tracks_the_numpy_dtype(self):
        for ty in CASTABLE:
            with self.subTest(dtype=ty.__name__):
                if ty is Boolean:
                    self.assertEqual(ty._exact_range, (0, 1))
                    continue
                info = np.iinfo(ty.numpy_dtype)
                self.assertEqual(ty._exact_range, (int(info.min), int(info.max)))

    def test_range_follows_the_dtype_not_the_width(self):
        """A subclass may widen `width` after the class is built.

        WgmmaSmemDesc and Tcgen05SmemDesc do exactly this, which leaves their
        `min`/`max` describing a wider type than the dtype they actually cast
        through. The shortcut has to agree with the cast, so it keys off the
        dtype's range instead of the bounds.
        """

        class _WidthPatched(Int32):
            pass

        _WidthPatched.width = Int64.width

        self.assertIs(_WidthPatched.numpy_dtype, np.int32)
        self.assertEqual(_WidthPatched._exact_range, (-(2**31), 2**31 - 1))
        # min/max now describe 64 bits, but the value still casts through int32.
        self.assertEqual(_WidthPatched.max, 2**63 - 1)
        self.assertEqual(_WidthPatched(2**40).value, numpy_reference(np.int32, 2**40))
        self.assertEqual(_WidthPatched(2**31).value, -(2**31))


class TestIntegerFromNumericTypes(unittest.TestCase):
    """Construction from another DSL scalar is untouched by the shortcut, but
    it shares the storage contract, so keep it covered."""

    def test_from_same_type(self):
        self.assertEqual(Int32(Int32(5)).value, 5)
        self.assertEqual(Uint8(Uint8(200)).value, 200)

    def test_from_other_integer_type(self):
        self.assertEqual(Int64(Int32(5)).value, 5)
        self.assertEqual(Int8(Int32(300)).value, 44)
        self.assertEqual(Int32(Int8(-1)).value, -1)

    def test_from_float_type(self):
        self.assertEqual(Int32(cutlass.Float32(5.7)).value, 5)
        self.assertEqual(Int32(cutlass.Float32(-5.7)).value, -5)


if __name__ == "__main__":
    unittest.main()
