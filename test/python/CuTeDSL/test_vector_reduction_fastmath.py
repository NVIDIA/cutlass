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
Unit test for the ``fastmath`` parameter on ``Vector.reduce``.
"""

import unittest

from cutlass._mlir import ir
from cutlass._mlir.dialects import arith, func
from cutlass._mlir_helpers.vector import Vector


def _reduce_ir(fastmath=None):
    """Return the IR for a ``Vector.reduce("add")`` over ``vector<16xf32>``."""
    with ir.Context(), ir.Location.unknown():
        module = ir.Module.create()
        vec_ty = ir.VectorType.get([16], ir.F32Type.get())
        with ir.InsertionPoint(module.body):
            fn = func.FuncOp("test", ir.FunctionType.get([vec_ty], []))
            with ir.InsertionPoint(fn.add_entry_block()):
                Vector(fn.arguments[0]).reduce("add", fastmath=fastmath)
                func.ReturnOp([])
        module.operation.verify()
        return str(module)


class TestVectorReduceFastmath(unittest.TestCase):
    def test_fastmath_flag(self):
        self.assertIn("fastmath<reassoc>", _reduce_ir(arith.FastMathFlags.reassoc))
        self.assertNotIn("reassoc", _reduce_ir())


if __name__ == "__main__":
    unittest.main()
