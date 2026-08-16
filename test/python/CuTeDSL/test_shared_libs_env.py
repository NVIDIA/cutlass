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
Unit tests for resolving the DSL runtime libraries from CUTE_DSL_LIBS.

CUTE_DSL_LIBS is a colon separated list and is routinely inherited by
processes that never set it themselves, for example under Slurm, whose
sbatch defaults to --export=ALL. An entry that names a path on the
submitting machine must not prevent a valid local runtime from being
used; only the complete absence of a usable runtime is an error.
"""

import os
import tempfile
import unittest
from unittest import mock

import cutlass
from cutlass.cutlass_dsl.cutlass import CuTeDSL


class TestSharedLibsFromEnv(unittest.TestCase):
    def setUp(self):
        self.dsl = CuTeDSL._get_dsl()
        self._saved = self.dsl.envar.shared_libs
        tmpdir = tempfile.TemporaryDirectory()
        self.addCleanup(tmpdir.cleanup)
        self.valid = os.path.join(tmpdir.name, "libcute_dsl_runtime.so")
        with open(self.valid, "w"):
            pass
        self.stale = "/nonexistent/submitter/libcute_dsl_runtime.so"

    def tearDown(self):
        self.dsl.envar.shared_libs = self._saved

    def test_valid_entries_are_returned_unchanged(self):
        self.dsl.envar.shared_libs = self.valid
        self.assertEqual(self.dsl.get_shared_libs(), [self.valid])

    def test_stale_entry_is_skipped_when_a_valid_one_remains(self):
        """A path inherited from another machine must not mask the local
        runtime that sits next to it in the same list."""
        self.dsl.envar.shared_libs = f"{self.valid}:{self.stale}"
        with self.assertWarns(UserWarning) as caught:
            self.assertEqual(self.dsl.get_shared_libs(), [self.valid])
        self.assertIn(self.stale, str(caught.warning))

    def test_all_entries_stale_falls_back_to_auto_discovery(self):
        self.dsl.envar.shared_libs = self.stale
        with mock.patch(
            "cutlass.base_dsl.dsl.discover_dsl_libs", return_value=self.valid
        ) as discover:
            with self.assertWarns(UserWarning):
                self.assertEqual(self.dsl.get_shared_libs(), [self.valid])
        discover.assert_called_once_with(self.dsl.name)

    def test_raises_when_no_usable_runtime_is_found(self):
        """Preserves the hard failure of issue #3329: a missing runtime is
        still reported at compile time rather than deferred to a confusing
        downstream symbol error."""
        self.dsl.envar.shared_libs = self.stale
        with mock.patch("cutlass.base_dsl.dsl.discover_dsl_libs", return_value=None):
            with self.assertRaises(FileNotFoundError) as caught:
                self.dsl.get_shared_libs()
        self.assertEqual(caught.exception.filename, self.stale)

    def test_empty_entries_are_ignored(self):
        """A trailing separator, as produced by joining onto an empty
        CUTE_DSL_LIBS, is not a missing library."""
        self.dsl.envar.shared_libs = f"{self.valid}:"
        self.assertEqual(self.dsl.get_shared_libs(), [self.valid])


if __name__ == "__main__":
    unittest.main()
