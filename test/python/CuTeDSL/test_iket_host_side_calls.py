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

IKET events are recorded by kernels only. A host-side IKET call used to compile
while IKET was stripped, and crash the process with a segmentation fault when
IKET lowering was enabled (``options="iket"``, ``CUTE_DSL_COMPILER_OPT=iket``,
or a ``run-iket`` profiling run). It is now rejected with
``CALL_IKET_OUTSIDE_KERNEL`` while the function is traced, in both modes.
"""

import tempfile
import unittest
from unittest import mock

import cutlass
import cutlass.cute as cute
from cutlass.base_dsl.common import DSLUserCodeError
from cutlass.cutlass_dsl import CuTeDSL

iket = cute.experimental.iket

OPTIONS = ("", "iket")


@cute.jit
def _helper(x: cutlass.Int32):
    iket.range_push("in_helper", x)
    iket.range_pop()


@cute.kernel
def kernel(x: cutlass.Int32):
    iket.mark("in_kernel", x)
    _helper(x)
    token = iket.sentinel_token("in_kernel_range")
    iket.range_end(token)
    token = iket.range_start("in_kernel_range")
    iket.range_end(token)


@cute.jit
def launch_kernel(x: cutlass.Int32):
    kernel(x).launch(grid=[1, 1, 1], block=[32, 1, 1])


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
def host_range_end(x: cutlass.Int32):
    kernel(x).launch(grid=[1, 1, 1], block=[32, 1, 1])
    iket.range_end(iket.RangeToken())


@cute.jit
def host_push_pop(x: cutlass.Int32):
    iket.range_push("host_side", 1)
    kernel(x).launch(grid=[1, 1, 1], block=[32, 1, 1])
    iket.range_pop()


@cute.jit
def host_pop(x: cutlass.Int32):
    kernel(x).launch(grid=[1, 1, 1], block=[32, 1, 1])
    iket.range_pop()


# Host function -> IKET function that rejects it.
HOST_SIDE = {
    host_mark: "mark",
    host_range: "range_start",
    host_sentinel: "sentinel_token",
    host_range_end: "range_end",
    host_push_pop: "range_push",
    host_pop: "range_pop",
}


class TestIketHostSideCalls(unittest.TestCase):
    def test_host_side_calls_raise(self):
        for options in OPTIONS:
            for host_fn, api in HOST_SIDE.items():
                with self.subTest(host_fn.__name__, options=options):
                    with self.assertRaises(DSLUserCodeError) as ctx:
                        cute.compile(host_fn, cutlass.Int32(1), options=options)
                    self.assertEqual(ctx.exception.code, "CALL_IKET_OUTSIDE_KERNEL")
                    self.assertIn(f"cute.experimental.iket.{api}", str(ctx.exception))

    def test_in_kernel_calls_compile(self):
        dsl = CuTeDSL._get_dsl()
        with tempfile.TemporaryDirectory() as dump_dir, mock.patch.multiple(
            dsl.envar, dump_dir=dump_dir, keep_ir_clean=True
        ):
            for options in OPTIONS:
                with self.subTest(options=options):
                    compiled = cute.compile(
                        launch_kernel, cutlass.Int32(1), options=options
                    )
                    ir_text = compiled.artifacts.MLIR
                    for name in ("in_kernel", "in_helper", "in_kernel_range"):
                        self.assertIn(name, ir_text)

    def test_call_outside_jit(self):
        with self.assertRaises(DSLUserCodeError) as ctx:
            iket.mark("plain_python")
        self.assertEqual(ctx.exception.code, "CALL_OUTSIDE_JIT")


if __name__ == "__main__":
    unittest.main()
