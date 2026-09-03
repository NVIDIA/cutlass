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
Unit tests for the loud failure when jit preprocessing reads a stale source.

The preprocessor re-reads function sources from disk at first compile. When
a module changed after import, the recorded line number slices text that no
longer starts with the decorated definition; that must fail loudly instead
of silently skipping staging.
"""

import importlib
import pathlib
import sys
import tempfile
import unittest

import cutlass
import cutlass.cute as cute
from cutlass import Int32
from cutlass.base_dsl.common import DSLUserCodeError


MODULE_SOURCE = """\
import cutlass
import cutlass.cute as cute

def helper(x):
    return x

@cute.jit
def kernel_add(x: cutlass.Int32):
    return x + 1
"""


class TestStaleSource(unittest.TestCase):

  def compile_kernel(self, module):
    cute.compile(module.kernel_add, Int32(0))

  def shift_lines(self, module, count):
    path = pathlib.Path(module.__file__)
    original = path.read_text()
    path.write_text("\n".join(["# pad"] * count) + "\n" + original)
    return original

  def test_stale_slice_on_undecorated_def_raises(self):
    with tempfile.TemporaryDirectory() as tmp:
      pathlib.Path(tmp, "mod_stale_def.py").write_text(MODULE_SOURCE)
      sys.path.insert(0, tmp)
      try:
        module = importlib.import_module("mod_stale_def")
        # kernel_add's recorded line now points at "def helper".
        self.shift_lines(module, 3)
        with self.assertRaises(DSLUserCodeError):
          self.compile_kernel(module)
      finally:
        sys.path.remove(tmp)

  def test_stale_slice_on_import_raises(self):
    with tempfile.TemporaryDirectory() as tmp:
      pathlib.Path(tmp, "mod_stale_import.py").write_text(MODULE_SOURCE)
      sys.path.insert(0, tmp)
      try:
        module = importlib.import_module("mod_stale_import")
        self.shift_lines(module, 6)
        with self.assertRaises(DSLUserCodeError):
          self.compile_kernel(module)
      finally:
        sys.path.remove(tmp)

  def test_restored_source_compiles_after_failure(self):
    with tempfile.TemporaryDirectory() as tmp:
      path = pathlib.Path(tmp, "mod_restore.py")
      path.write_text(MODULE_SOURCE)
      sys.path.insert(0, tmp)
      try:
        module = importlib.import_module("mod_restore")
        original = self.shift_lines(module, 3)
        with self.assertRaises(DSLUserCodeError):
          self.compile_kernel(module)
        path.write_text(original)
        self.compile_kernel(module)
      finally:
        sys.path.remove(tmp)


if __name__ == "__main__":
  unittest.main()
