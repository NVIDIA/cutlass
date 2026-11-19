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
Regression tests for boolean IKET payloads.

The IKET profiling guide lists Python boolean literals among the supported
payloads, but a boolean reached the iket ops as an i1, which their verifier
rejects. Every kernel with a boolean payload then failed to compile, with or
without IKET lowering. Booleans are now recorded as 32-bit 0 or 1.
"""

import re
import tempfile
import unittest
from unittest import mock

import cutlass
import cutlass.cute as cute
from cutlass.cutlass_dsl import CuTeDSL

iket = cute.experimental.iket

# Payload operand type of an iket op, e.g. `iket.mark("flag", %1 : i32)`.
_PAYLOAD_TYPE = re.compile(r"iket\.\w+\([^)]*%\w+ : (\w+)\)")


@cute.kernel
def _mark_literal(x: cutlass.Int32):
    iket.mark("flag", True)


@cute.kernel
def _mark_comparison(x: cutlass.Int32):
    iket.mark("flag", x == 0)


@cute.kernel
def _mark_boolean(x: cutlass.Int32):
    iket.mark("flag", cutlass.Boolean(x > 1))


@cute.kernel
def _push_literal(x: cutlass.Int32):
    iket.range_push("flag", False)
    iket.range_pop()


@cute.kernel
def _start_end_mixed(x: cutlass.Int32):
    token = iket.range_start("flag", True)
    iket.range_end(token, x == 0)


def _launcher(kernel):
    @cute.jit
    def launch(x: cutlass.Int32):
        kernel(x).launch(grid=[1, 1, 1], block=[32, 1, 1])

    return launch


KERNELS = {
    "mark_literal": _mark_literal,
    "mark_comparison": _mark_comparison,
    "mark_boolean": _mark_boolean,
    "push_literal": _push_literal,
    "start_end_mixed": _start_end_mixed,
}


class TestIketBoolPayload(unittest.TestCase):
    def compile(self, kernel, options):
        return cute.compile(_launcher(kernel), cutlass.Int32(1), options=options)

    def test_compiles_without_iket_lowering(self):
        for name, kernel in KERNELS.items():
            with self.subTest(name):
                self.compile(kernel, "")

    def test_compiles_with_iket_lowering(self):
        for name, kernel in KERNELS.items():
            with self.subTest(name):
                self.compile(kernel, "iket")

    def test_payload_is_32_bit(self):
        dsl = CuTeDSL._get_dsl()
        with tempfile.TemporaryDirectory() as dump_dir, mock.patch.multiple(
            dsl.envar, dump_dir=dump_dir, keep_ir_clean=True
        ):
            for name, kernel in KERNELS.items():
                with self.subTest(name):
                    ir_text = self.compile(kernel, "").artifacts.MLIR
                    payload_types = _PAYLOAD_TYPE.findall(ir_text)
                    self.assertTrue(payload_types, ir_text)
                    self.assertEqual(set(payload_types), {"i32"}, ir_text)


if __name__ == "__main__":
    unittest.main()
