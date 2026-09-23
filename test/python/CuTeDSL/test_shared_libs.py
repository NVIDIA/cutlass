#################################################################################################
#
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#################################################################################################

"""
Unit tests for BaseDSL.get_shared_libs handling of stale entries.

The shared library list can name files from another machine when an
environment is forwarded (e.g. Slurm --export=ALL); missing entries must be
skipped while at least one usable runtime remains.
"""

import os
import tempfile
import types
import unittest

from cutlass.base_dsl.dsl import BaseDSL


def make_dsl(shared_libs):
    dsl = object.__new__(BaseDSL)
    dsl.name = "TEST_DSL"
    dsl.envar = types.SimpleNamespace(shared_libs=shared_libs, prefix="TEST_DSL")
    dsl.warnings = []
    dsl.print_warning = lambda message: dsl.warnings.append(message)
    return dsl


class TestGetSharedLibs(unittest.TestCase):

  def test_missing_entries_skipped_when_others_valid(self):
    with tempfile.TemporaryDirectory() as tmp:
      valid = os.path.join(tmp, "libruntime.so")
      open(valid, "w").close()

      dsl = make_dsl(f"/nonexistent/liba.so:{valid}:/nonexistent/libb.so")
      libs = dsl.get_shared_libs()

      self.assertEqual(libs, [valid])
      self.assertEqual(len(dsl.warnings), 2)

  def test_all_entries_missing_raises(self):
    dsl = make_dsl("/nonexistent/liba.so:/nonexistent/libb.so")
    with self.assertRaises(FileNotFoundError):
      dsl.get_shared_libs()

  def test_unset_list_returns_empty(self):
    dsl = make_dsl(None)
    dsl.print_warning = lambda message: None
    self.assertEqual(dsl.get_shared_libs(), [])


if __name__ == "__main__":
  unittest.main()
