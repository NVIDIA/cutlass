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
Unit test for ``inline_ptx(force_register_args=...)``.

A compile-time constant that reaches a read-only operand of ``nvvm.inline_ptx``
is given the immediate constraint ``n`` by the NVVM to LLVM conversion.  Some
PTX instructions accept only a register in a given operand slot
(``max.xorsign.abs.bf16x2`` is one), so such a constant is rejected by ptxas
with "Arguments mismatch for instruction 'max'".

``force_register_args`` names the read-only operands that must be moved into a
register first.  These tests are CPU only: they build the IR and assert on its
shape, so they need neither a GPU nor ptxas.
"""

import unittest

from cutlass._mlir import ir
from cutlass._mlir.dialects import func
from cutlass import Int32, Int64
from cutlass.cute.arch.nvvm_wrappers import inline_ptx

_PTX_MAX = "max.xorsign.abs.bf16x2 {$w0}, {$r0}, {$r1};"


def _build(body, arg_types=("i32", "i32")):
    """Build ``func.func @test`` with ``arg_types`` and return its IR text."""
    with ir.Context(), ir.Location.unknown():
        module = ir.Module.create()
        with ir.InsertionPoint(module.body):
            fn = func.FuncOp(
                "test",
                ir.FunctionType.get([ir.Type.parse(a) for a in arg_types], []),
            )
            with ir.InsertionPoint(fn.add_entry_block()):
                body(fn)
                func.ReturnOp([])
        module.operation.verify()
        return str(module)


class TestInlinePtxForceRegisterArgs(unittest.TestCase):
    def test_default_path_is_unchanged(self):
        """Without the opt-in the constant stays an operand of the target op."""
        def body(_fn):
            inline_ptx(
                _PTX_MAX,
                write_only_types=[Int32],
                read_only_args=[Int32(0), Int32(7)],
                ip=ir.InsertionPoint.current,
            )

        text = _build(body)
        self.assertNotIn("mov.", text)
        self.assertIn(
            'nvvm.inline_ptx "max.xorsign.abs.bf16x2 {$w0}, {$r0}, {$r1};" '
            "ro(%c0_i32, %c7_i32 : i32, i32)",
            text,
        )

    def test_forced_operand_is_materialized(self):
        """The named operand becomes the result of an explicit ``mov``."""
        def body(_fn):
            inline_ptx(
                _PTX_MAX,
                write_only_types=[Int32],
                read_only_args=[Int32(0), Int32(7)],
                force_register_args=(0,),
                ip=ir.InsertionPoint.current,
            )

        text = _build(body)
        self.assertIn('nvvm.inline_ptx "mov.b32 {$w0}, {$r0};" ro(%c0_i32 : i32)', text)
        # The target instruction must consume the materialized value, not %c0_i32.
        self.assertIn(
            'nvvm.inline_ptx "max.xorsign.abs.bf16x2 {$w0}, {$r0}, {$r1};" '
            "ro(%0, %c7_i32 : i32, i32)",
            text,
        )

    def test_index_refers_to_read_only_args_only(self):
        """Index 1 selects the second read-only operand and leaves index 0 alone."""
        def body(_fn):
            inline_ptx(
                _PTX_MAX,
                write_only_types=[Int32],
                read_only_args=[Int32(5), Int32(0)],
                force_register_args=[1],
                ip=ir.InsertionPoint.current,
            )

        text = _build(body)
        self.assertIn('nvvm.inline_ptx "mov.b32 {$w0}, {$r0};" ro(%c0_i32 : i32)', text)
        self.assertIn(
            'nvvm.inline_ptx "max.xorsign.abs.bf16x2 {$w0}, {$r0}, {$r1};" '
            "ro(%c5_i32, %0 : i32, i32)",
            text,
        )

    def test_identical_constants_are_treated_by_index(self):
        """Two operands with the same value can be treated differently."""
        def body(_fn):
            inline_ptx(
                _PTX_MAX,
                write_only_types=[Int32],
                read_only_args=[Int32(0), Int32(0)],
                force_register_args=(1,),
                ip=ir.InsertionPoint.current,
            )

        text = _build(body)
        # Exactly one materialization, feeding the second read-only operand.
        self.assertEqual(text.count('"mov.b32 {$w0}, {$r0};"'), 1)
        self.assertIn(
            'nvvm.inline_ptx "max.xorsign.abs.bf16x2 {$w0}, {$r0}, {$r1};" '
            "ro(%c0_i32, %0 : i32, i32)",
            text,
        )

    def test_mov_type_follows_operand_type(self):
        """The materialization preserves the operand's own type."""
        def body(_fn):
            inline_ptx(
                "mov.b64 {$w0}, {$r0};",
                write_only_types=[Int64],
                read_only_args=[Int64(0)],
                force_register_args=(0,),
                ip=ir.InsertionPoint.current,
            )

        text = _build(body, arg_types=("i64", "i64"))
        self.assertIn('nvvm.inline_ptx "mov.b64 {$w0}, {$r0};" ro(%c0_i64 : i64)', text)

    def test_pointer_operand_uses_64_bit_mov(self):
        """A generic pointer operand is materialized with mov.b64."""
        def body(fn):
            inline_ptx(
                "mov.b64 {$w0}, {$r0};",
                write_only_types=[Int64],
                read_only_args=[fn.arguments[0]],
                force_register_args=(0,),
                ip=ir.InsertionPoint.current,
            )

        text = _build(body, arg_types=("!llvm.ptr", "i32"))
        self.assertEqual(text.count('"mov.b64 {$w0}, {$r0};"'), 2)
        self.assertIn("%0 = nvvm.inline_ptx \"mov.b64 {$w0}, {$r0};\" ro(%arg0", text)
        self.assertIn('ro(%0', text)

    def test_duplicate_indices_are_deduplicated(self):
        """Repeating an index must not materialize the operand twice."""
        def body(_fn):
            inline_ptx(
                _PTX_MAX,
                write_only_types=[Int32],
                read_only_args=[Int32(0), Int32(7)],
                force_register_args=(0, 0),
                ip=ir.InsertionPoint.current,
            )

        self.assertEqual(_build(body).count('"mov.b32 {$w0}, {$r0};"'), 1)

    def test_out_of_range_index_is_rejected(self):
        def body(_fn):
            inline_ptx(
                _PTX_MAX,
                write_only_types=[Int32],
                read_only_args=[Int32(0)],
                force_register_args=(1,),
                ip=ir.InsertionPoint.current,
            )

        with self.assertRaises(IndexError):
            _build(body)

    def test_negative_index_is_rejected(self):
        def body(_fn):
            inline_ptx(
                _PTX_MAX,
                write_only_types=[Int32],
                read_only_args=[Int32(0)],
                force_register_args=(-1,),
                ip=ir.InsertionPoint.current,
            )

        with self.assertRaises(IndexError):
            _build(body)

    def test_bare_int_is_rejected(self):
        """A bare int is a common mistake; it must not be read as an index."""
        def body(_fn):
            inline_ptx(
                _PTX_MAX,
                write_only_types=[Int32],
                read_only_args=[Int32(0), Int32(7)],
                force_register_args=0,
                ip=ir.InsertionPoint.current,
            )

        with self.assertRaises(TypeError):
            _build(body)

    def test_non_integer_entry_is_rejected(self):
        def body(_fn):
            inline_ptx(
                _PTX_MAX,
                write_only_types=[Int32],
                read_only_args=[Int32(0)],
                force_register_args=("0",),
                ip=ir.InsertionPoint.current,
            )

        with self.assertRaises(TypeError):
            _build(body)


if __name__ == "__main__":
    unittest.main()
