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
Regression tests for issue #3142: compiling exited with ``SystemExit: 2`` when
the host program had its own ``-d 0`` flag, because the ``-diagnostic`` command
line check took ``-d`` as an abbreviation of ``-diagnostic``.
"""

import sys
import unittest
from unittest import mock

import cutlass.cute as cute
from cutlass._mlir import ir


@cute.jit
def _noop():
    pass


def _enabled_diagnostic_types(*args):
    """Compile with ``args`` on the command line; return the enabled debug types."""
    with (
        mock.patch.object(sys, "argv", ["prog", *args]),
        mock.patch.object(ir, "_GlobalDebug") as global_debug,
    ):
        cute.compile(_noop)
    return [call.args[0] for call in global_debug.set_types.call_args_list]


class TestDiagnosticArgv(unittest.TestCase):
    def test_host_program_flags_are_ignored(self):
        self.assertEqual(_enabled_diagnostic_types("-d", "0"), [])
        self.assertEqual(_enabled_diagnostic_types("-d", "fail"), [])

    def test_diagnostic_flag_is_parsed(self):
        self.assertEqual(_enabled_diagnostic_types("-diagnostic"), ["diagnostic"])
        self.assertEqual(
            _enabled_diagnostic_types("-d", "0", "-diagnostic", "fail"),
            ["diagnostic-fail"],
        )
        self.assertEqual(
            _enabled_diagnostic_types("-diagnostic=info"), ["diagnostic-info"]
        )


if __name__ == "__main__":
    unittest.main()
