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

"""Preprocessor coverage for staged bool() with no arguments (issue 3506)."""

import ast
import unittest

from cutlass.base_dsl.ast_preprocessor import DSLPreprocessor


class TestBoolZeroArgs(unittest.TestCase):
    def _preprocess(self, source: str) -> ast.AST:
        preprocessor = DSLPreprocessor(["cutlass"])
        preprocessor._start_session()
        return preprocessor.visit(ast.parse(source))

    def test_bool_without_args_is_left_alone(self):
        tree = self._preprocess("z = bool()")
        call = tree.body[0].value
        self.assertIsInstance(call, ast.Call)
        self.assertIsInstance(call.func, ast.Name)
        self.assertEqual(call.func.id, "bool")
        self.assertEqual(call.args, [])

    def test_bool_with_one_arg_is_redirected(self):
        tree = self._preprocess("z = bool(x)")
        call = tree.body[0].value
        self.assertIsInstance(call, ast.Call)
        self.assertNotEqual(getattr(call.func, "id", None), "bool")
        self.assertEqual(len(call.args), 1)


if __name__ == "__main__":
    unittest.main()
