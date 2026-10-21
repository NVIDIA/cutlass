# SPDX-FileCopyrightText: Copyright (c) 2026 Martin Vit
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html

"""Host-only tests for runtime argument binding; no compilation or GPU required."""

import inspect
import unittest

import numpy as np

from cutlass import Int32
from cutlass.base_dsl.common import DSLUserCodeError
from cutlass.base_dsl.jit_executor import ExecutionArgs


class EqualityTrap:
    def __eq__(self, other):
        raise AssertionError("Argument binding must not compare operand values")


class EqualToEverything:
    def __eq__(self, other):
        return True


class TestExecutionArgs(unittest.TestCase):
    def setUp(self):
        def signature(a, b=2, *, c, d=4):
            pass

        self.binder = ExecutionArgs(inspect.signature(signature), "signature")

    def test_positional_keyword_and_default_binding(self):
        cases = [
            ((1,), {"c": 3}, [1, 2, 3, 4]),
            ((1, 5), {"c": 6, "d": 7}, [1, 5, 6, 7]),
            ((), {"a": 1, "c": 3}, [1, 2, 3, 4]),
        ]
        for args, kwargs, expected in cases:
            with self.subTest(args=args, kwargs=kwargs):
                self.assertEqual(self.binder.get_rectified_args(args, kwargs), expected)

    def test_supplied_values_do_not_use_equality(self):
        for value in (EqualityTrap(), EqualToEverything(), np.arange(2), Int32(7)):
            with self.subTest(value_type=type(value).__name__):
                for args, kwargs, index in (
                    ((value,), {"c": 3}, 0),
                    ((), {"a": value, "c": 3}, 0),
                    ((1,), {"c": value}, 2),
                ):
                    with self.subTest(index=index, positional=bool(args)):
                        result = self.binder.get_rectified_args(args, kwargs)
                        self.assertIs(result[index], value)

    def test_default_values_do_not_use_equality(self):
        value = EqualityTrap()

        def signature(a=value, *, b=value):
            pass

        binder = ExecutionArgs(inspect.signature(signature), "signature")
        result = binder.get_rectified_args((), {})
        self.assertIs(result[0], value)
        self.assertIs(result[1], value)

    def test_missing_argument_after_opaque_value(self):
        with self.assertRaises(DSLUserCodeError) as ctx:
            self.binder.get_rectified_args((EqualityTrap(),), {})
        self.assertEqual(ctx.exception.code, "CALL_MISSING_ARGS")
        self.assertIn("c", str(ctx.exception))

    def test_binding_errors(self):
        cases = [
            ((1, 2, 3), {"c": 3}, "CALL_TOO_MANY_ARGS"),
            ((1,), {"a": 2, "c": 3}, "CALL_DUPLICATE_ARGUMENT"),
            ((1,), {"wrong": 2}, "CALL_UNEXPECTED_KWARG"),
            ((1,), {}, "CALL_MISSING_ARGS"),
            ((), {"c": 3}, "CALL_MISSING_ARGS"),
        ]
        for args, kwargs, code in cases:
            with self.subTest(code=code, args=args, kwargs=kwargs):
                with self.assertRaises(DSLUserCodeError) as ctx:
                    self.binder.get_rectified_args(args, kwargs)
                self.assertEqual(ctx.exception.code, code)

    def test_sentinel_itself_is_missing(self):
        with self.assertRaises(DSLUserCodeError) as ctx:
            self.binder.get_rectified_args((self.binder._missing,), {"c": 3})
        self.assertEqual(ctx.exception.code, "CALL_MISSING_ARGS")

    def test_empty_signature(self):
        def signature():
            pass

        binder = ExecutionArgs(inspect.signature(signature), "signature")
        self.assertEqual(binder.get_rectified_args((), {}), [])


if __name__ == "__main__":
    unittest.main()
