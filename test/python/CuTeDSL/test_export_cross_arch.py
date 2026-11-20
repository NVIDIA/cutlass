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

"""
Regression test for issue #3680: ``export_to_c`` failed for a ``--gpu-arch``
this machine cannot run.

Such a compile builds no JIT engine, and building the engine was the only
thing that loaded the runtime libraries the object file dump resolves symbols
from. The export therefore only worked in a process that had already compiled
something for the native arch, so the test runs in a fresh interpreter.
"""

import os
import subprocess
import sys
import tempfile
import textwrap
import unittest

_EXPORT_SCRIPT = textwrap.dedent(
    """\
    import sys

    import cutlass
    import cutlass.cute as cute
    from cutlass.cute.runtime import make_fake_stream
    from cutlass.cutlass_dsl import CuTeDSL

    from cuda.bindings import driver as cuda


    @cute.kernel
    def _k(x: cutlass.Int32):
        pass


    @cute.jit
    def _entry(x: cutlass.Int32, stream: cuda.CUstream):
        _k(x).launch(grid=[1, 1, 1], block=[1, 1, 1], stream=stream)


    arch = "sm_100a" if CuTeDSL._get_dsl().envar.arch == "sm_90a" else "sm_90a"
    compiled = cute.compile(
        _entry, cutlass.Int32(0), make_fake_stream(), options=f"--gpu-arch {arch}"
    )
    assert compiled.engine is None, f"expected no JIT engine for {arch}"
    compiled.export_to_c(file_path=sys.argv[1], file_name="k", function_prefix="k")
    """
)


class TestExportCrossArch(unittest.TestCase):
    def test_export_without_jit_engine(self):
        with tempfile.TemporaryDirectory() as out_dir:
            # The DSL reads the source of traced functions, so the script has
            # to be a file rather than a -c string.
            script = os.path.join(out_dir, "export_cross_arch.py")
            with open(script, "w") as f:
                f.write(_EXPORT_SCRIPT)
            proc = subprocess.run(
                [sys.executable, script, out_dir],
                capture_output=True,
                text=True,
                timeout=300,
                check=False,
            )
            self.assertEqual(proc.returncode, 0, proc.stderr)
            self.assertGreater(os.path.getsize(os.path.join(out_dir, "k.h")), 0)
            self.assertGreater(os.path.getsize(os.path.join(out_dir, "k.o")), 0)


if __name__ == "__main__":
    unittest.main()
