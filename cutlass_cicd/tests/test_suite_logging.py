# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from cutlass_cicd.common.log import LOG_CALL_SEPARATOR_WIDTH, log_call


class SuiteLoggingTest(unittest.TestCase):
    def test_log_call_forwards_arguments_and_returns_result(self) -> None:
        messages = []

        def multiply(value: int, *, factor: int) -> int:
            return value * factor

        result = log_call(messages.append, multiply, 6, factor=7)

        self.assertEqual(result, 42)
        self.assertEqual(len(messages), 1)
        separator = messages[0].strip("\n")
        self.assertGreaterEqual(len(separator), LOG_CALL_SEPARATOR_WIDTH)
        self.assertIn(f" {multiply.__module__}.{multiply.__qualname__} ", separator)

if __name__ == "__main__":
    unittest.main()
