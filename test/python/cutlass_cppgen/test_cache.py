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
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#################################################################################################

import ctypes
import importlib
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock

import cutlass_cppgen


compiler = importlib.import_module("cutlass_cppgen.backend.compiler")


class TestCache(unittest.TestCase):
    def test_cache_path_uses_configured_cache_root(self):
        with tempfile.TemporaryDirectory() as cache_root:
            with mock.patch.dict(os.environ, {"CUTLASS_CPPGEN_CACHE": cache_root}):
                cache_file = Path(cutlass_cppgen._cache_path())

            self.assertEqual(cache_file, Path(cache_root) / "cutlass_cppgen" / "compiled_cache.db")
            self.assertTrue(cache_file.parent.is_dir())
            if os.name == "posix":
                self.assertEqual(cache_file.parent.stat().st_mode & 0o777, 0o700)

    def test_cache_path_falls_back_to_xdg_cache_home(self):
        with tempfile.TemporaryDirectory() as cache_root:
            with mock.patch.dict(os.environ, {"XDG_CACHE_HOME": cache_root}, clear=True):
                cache_file = Path(cutlass_cppgen._cache_path())

            self.assertEqual(cache_file, Path(cache_root) / "cutlass_cppgen" / "compiled_cache.db")

    def test_cache_file_is_created_with_user_only_permissions(self):
        with tempfile.TemporaryDirectory() as cache_root:
            cache_file = Path(cache_root) / "compiled_cache.db"
            with mock.patch.object(compiler, "CACHE_FILE", str(cache_file)):
                connection = compiler._connect_cache()
                connection.close()

            if os.name == "posix":
                self.assertEqual(cache_file.stat().st_mode & 0o777, 0o600)

    def test_cdll_bin_does_not_use_the_current_working_directory(self):
        with tempfile.TemporaryDirectory() as temp_root, tempfile.TemporaryDirectory() as work_root:
            with mock.patch.dict(os.environ, {"TMPDIR": temp_root}):
                with mock.patch.object(tempfile, "tempdir", None):
                    with mock.patch.object(ctypes, "CDLL", return_value=object()) as cdll:
                        old_cwd = os.getcwd()
                        os.chdir(work_root)
                        try:
                            compiler.CDLLBin(b"not a real shared library")
                        finally:
                            os.chdir(old_cwd)

            loaded_path = Path(cdll.call_args.args[0])
            self.assertEqual(loaded_path.parent, Path(temp_root))
            self.assertNotEqual(loaded_path.parent, Path(work_root))


if __name__ == "__main__":
    unittest.main()
