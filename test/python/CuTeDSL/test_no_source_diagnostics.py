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
Regression tests for issue #3413: a ``@cute.jit`` function with no
retrievable source raised an internal error and killed the interpreter.
"""

import subprocess
import sys
import textwrap
import unittest

import cutlass.cute as cute
from cutlass.base_dsl.common import DSLUserCodeError


class TestNoSourceDiagnostic(unittest.TestCase):
    def test_exec_defined_function_raises_user_error(self):
        namespace = {"cute": cute}
        exec(
            textwrap.dedent(
                """
                @cute.jit
                def kernel_without_source():
                    pass
                """
            ),
            namespace,
        )
        with self.assertRaises(DSLUserCodeError) as ctx:
            namespace["kernel_without_source"]()
        self.assertEqual(ctx.exception.code, "UNSUP_NO_SOURCE")
        rendered = str(ctx.exception)
        self.assertNotIn("Internal Error", rendered)
        self.assertIn("Save the function to a .py file", rendered)


class TestReplSurvivesDslError(unittest.TestCase):
    def test_uncaught_dsl_error_does_not_kill_interactive_session(self):
        # Session from issue #3413; the interpreter used to exit at run()
        repl_session = textwrap.dedent(
            """\
            from cutlass import cute

            @cute.jit
            def run(f):
                f()

            run(lambda: 0)
            print("REPL-STILL-ALIVE")
            """
        )
        proc = subprocess.run(
            [sys.executable, "-i"],
            input=repl_session,
            capture_output=True,
            text=True,
            timeout=300,
        )
        self.assertIn("REPL-STILL-ALIVE", proc.stdout)
        self.assertEqual(proc.returncode, 0)
        self.assertNotIn("Internal Error", proc.stderr)
        self.assertIn("Save the function to a .py file", proc.stderr)

    def test_uncaught_dsl_error_in_script_still_exits_nonzero(self):
        script = textwrap.dedent(
            """\
            from cutlass.base_dsl.common import DSLRuntimeError

            raise DSLRuntimeError("boom test")
            """
        )
        proc = subprocess.run(
            [sys.executable, "-c", script],
            capture_output=True,
            text=True,
            timeout=300,
        )
        self.assertEqual(proc.returncode, 1)
        self.assertIn("boom test", proc.stderr)


if __name__ == "__main__":
    unittest.main()
