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

from types import SimpleNamespace
import unittest
import warnings

from cutlass.base_dsl.dsl import BaseDSL


class _DummyDSL:
    def __init__(self, *, warnings_ignore: bool = False) -> None:
        self.envar = SimpleNamespace(warnings_ignore=warnings_ignore)


class TestPrintWarningOnce(unittest.TestCase):
    def test_caches_each_distinct_message(self):
        dsl = _DummyDSL(warnings_ignore=False)
        BaseDSL.print_warning_once.cache_clear()
        try:
            with warnings.catch_warnings(record=True) as caught:
                warnings.simplefilter("always")
                BaseDSL.print_warning_once(dsl, "first warning")
                BaseDSL.print_warning_once(dsl, "second warning")
                BaseDSL.print_warning_once(dsl, "first warning")
                BaseDSL.print_warning_once(dsl, "second warning")

            self.assertEqual(
                [str(item.message) for item in caught],
                ["first warning", "second warning"],
            )
        finally:
            BaseDSL.print_warning_once.cache_clear()

    def test_warnings_ignore_suppresses_emission(self):
        ignored_dsl = _DummyDSL(warnings_ignore=True)
        enabled_dsl = _DummyDSL(warnings_ignore=False)
        BaseDSL.print_warning_once.cache_clear()
        try:
            with warnings.catch_warnings(record=True) as caught:
                warnings.simplefilter("always")
                BaseDSL.print_warning_once(ignored_dsl, "ignored warning")
                BaseDSL.print_warning_once(enabled_dsl, "ignored warning")

            self.assertEqual(
                [str(item.message) for item in caught],
                ["ignored warning"],
            )
        finally:
            BaseDSL.print_warning_once.cache_clear()


if __name__ == "__main__":
    unittest.main()
