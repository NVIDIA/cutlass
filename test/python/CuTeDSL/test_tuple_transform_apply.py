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
Unit tests for ``cute.transform_apply`` and ``cute.filter_tuple``.

Like C++ CuTe (``include/cute/algorithm/tuple_algorithms.hpp``), both apply
``f`` to the top-level modes of their arguments and keep nested modes intact.

No GPU or compilation is involved, so these run anywhere.
"""

import unittest

import cutlass.cute as cute


def _keep_non_unit(x):
    return () if x == 1 else (x,)


class TestTransformApply(unittest.TestCase):
    def test_flat_tuple(self):
        self.assertEqual(
            cute.transform_apply((1, 2, 3), f=lambda x: x * 2, g=lambda *a: sum(a)),
            12,
        )
        self.assertEqual(
            cute.transform_apply((1, 2), (3, 4), f=lambda x, y: x + y, g=lambda *a: a),
            (4, 6),
        )

    def test_f_receives_top_level_modes(self):
        self.assertEqual(
            cute.transform_apply(((1, 2), (3, 4)), f=lambda x: (x,), g=cute.tuple_cat),
            ((1, 2), (3, 4)),
        )
        self.assertEqual(
            cute.transform_apply(((1, 2), 3, (4, 5, 6)), f=len_or_one, g=lambda *a: a),
            (2, 1, 3),
        )

    def test_only_top_level_rank_must_match(self):
        self.assertEqual(
            cute.transform_apply(
                ((1, 2), 3), (4, 5), f=lambda a, b: (a,), g=cute.tuple_cat
            ),
            ((1, 2), 3),
        )

    def test_non_tuple(self):
        self.assertEqual(cute.transform_apply(3, f=lambda x: x + 1, g=lambda x: x), 4)
        self.assertEqual(
            cute.transform_apply(3, 4, f=lambda x, y: x * y, g=lambda x: x), 12
        )

    def test_rank_mismatch_raises(self):
        with self.assertRaises(ValueError):
            cute.transform_apply((1, 2), (3,), f=lambda a, b: a, g=lambda *a: a)
        with self.assertRaises(ValueError):
            cute.transform_apply((1, 2), 3, f=lambda a, b: a, g=lambda *a: a)
        with self.assertRaises(ValueError):
            cute.transform_apply(1, (2, 3), f=lambda a, b: a, g=lambda *a: a)


class TestFilterTuple(unittest.TestCase):
    def test_flat_tuple(self):
        self.assertEqual(
            cute.filter_tuple((1, 2, 3, 4), f=lambda x: (x,) if x % 2 == 0 else ()),
            (2, 4),
        )
        self.assertEqual(
            cute.filter_tuple((1, 2, 3), f=lambda x: (x, x)), (1, 1, 2, 2, 3, 3)
        )

    def test_keeps_nested_modes(self):
        self.assertEqual(
            cute.filter_tuple(((2, 3), 1, 4), f=_keep_non_unit), ((2, 3), 4)
        )

    def test_two_tuples(self):
        # Keep the shape modes whose stride is not 0, as in C++ filter_zeros.
        shape = ((2, 3), 4, 5)
        stride = ((1, 2), 0, 6)
        self.assertEqual(
            cute.filter_tuple(shape, stride, f=lambda s, d: () if d == 0 else (s,)),
            ((2, 3), 5),
        )


def len_or_one(x):
    return len(x) if isinstance(x, tuple) else 1


if __name__ == "__main__":
    unittest.main()
