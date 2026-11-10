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
Regression tests for IKET calls in host-side ``@cute.jit`` code.

IKET calls outside a ``@cute.kernel`` record no events. They compiled while
IKET was stripped, but with IKET lowering enabled (``options="iket"``,
``CUTE_DSL_COMPILER_OPT=iket``, or a ``run-iket`` profiling run) the compile
crashed the process with a segmentation fault. The compiles run in a
subprocess so that a crash fails the test instead of killing the runner.
"""

import os
import subprocess
import sys
import tempfile
import textwrap
import unittest

_SCRIPT = textwrap.dedent(
    """
    import sys

    import cutlass
    import cutlass.cute as cute

    iket = cute.experimental.iket


    @cute.kernel
    def kernel(x: cutlass.Int32):
        iket.mark("in_kernel", x)


    @cute.jit
    def host_mark(x: cutlass.Int32):
        iket.mark("host_side", x)
        kernel(x).launch(grid=[1, 1, 1], block=[32, 1, 1])


    @cute.jit
    def host_range(x: cutlass.Int32):
        token = iket.range_start("host_side")
        kernel(x).launch(grid=[1, 1, 1], block=[32, 1, 1])
        iket.range_end(token)


    @cute.jit
    def host_sentinel(x: cutlass.Int32):
        token = iket.sentinel_token("host_side")
        iket.range_end(token)
        kernel(x).launch(grid=[1, 1, 1], block=[32, 1, 1])


    @cute.jit
    def host_push_pop(x: cutlass.Int32):
        iket.range_push("host_side", 1)
        kernel(x).launch(grid=[1, 1, 1], block=[32, 1, 1])
        iket.range_pop()


    variant, options = sys.argv[1], sys.argv[2]
    compiled = cute.compile(globals()[variant], cutlass.Int32(1), options=options)
    mlir = compiled.artifacts.MLIR
    print("host_side" in mlir, "in_kernel" in mlir)
    """
)

VARIANTS = ("host_mark", "host_range", "host_sentinel", "host_push_pop")


class TestIketHostSideCalls(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.dump_dir = tmp.name
        self.script = os.path.join(tmp.name, "iket_host_side.py")
        with open(self.script, "w") as f:
            f.write(_SCRIPT)

    def compile(self, variant, options):
        env = dict(os.environ, CUTE_DSL_KEEP="ir", CUTE_DSL_DUMP_DIR=self.dump_dir)
        env.pop("CUTE_DSL_COMPILER_OPT", None)
        return subprocess.run(
            [sys.executable, self.script, variant, options],
            capture_output=True,
            text=True,
            env=env,
            timeout=600,
            check=False,
        )

    def test_host_side_calls_emit_nothing(self):
        for options in ("", "iket"):
            for variant in VARIANTS:
                with self.subTest(variant=variant, options=options):
                    proc = self.compile(variant, options)
                    self.assertEqual(proc.returncode, 0, proc.stderr[-2000:])
                    # The kernel's own event is kept; the host-side one is not.
                    self.assertEqual(
                        proc.stdout.split()[-2:], ["False", "True"], proc.stdout
                    )


if __name__ == "__main__":
    unittest.main()
