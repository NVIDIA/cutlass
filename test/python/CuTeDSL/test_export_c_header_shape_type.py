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
Unit tests for the dynamic shape slots of the tensor descriptor emitted by
`export_to_c`.

Each dynamic dimension crosses the ABI at the width the calling convention
gave it: a `SymInt` dimension keeps its declared width, any other dynamic
dimension is 32-bit. The generated C header has to declare the shape slots at
that same width, or the descriptor a C caller builds does not match the one
the compiled function reads.
"""

import os
import re
import tempfile
import unittest

import numpy as np

import cutlass
import cutlass.cute as cute
from cutlass import Float32
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.cute.runtime import from_dlpack, make_fake_stream, make_fake_tensor

from cuda.bindings import driver as cuda


@cute.kernel
def _k(mA: cute.Tensor):
    pass


@cute.jit
def _entry(mA: cute.Tensor, stream: cuda.CUstream):
    _k(mA).launch(grid=[1, 1, 1], block=[1, 1, 1], stream=stream)


@cute.jit
def _entry_list(mAs: list[cute.Tensor], stream: cuda.CUstream):
    _k(mAs[0]).launch(grid=[1, 1, 1], block=[1, 1, 1], stream=stream)


def _export_header(tensor, entry=_entry):
    """Compile `entry` for `tensor` and return the generated C header text."""
    compiled = cute.compile(entry, tensor, make_fake_stream())
    out_dir = tempfile.mkdtemp()
    compiled.export_to_c(file_path=out_dir, file_name="k", function_prefix="k")
    with open(os.path.join(out_dir, "k.h")) as f:
        return f.read()


def _flat_message(exc):
    """Diagnostics are wrapped and colorized before they reach the user, so
    match against the message with that formatting flattened out."""
    return " ".join(re.sub(r"\x1b\[[0-9;]*m", "", str(exc)).split())


def _shape_slot_decl(header):
    """The `dynamic_shapes` declaration of the tensor descriptor, or None when
    the descriptor has no dynamic dimensions."""
    match = re.search(r"(\w+) dynamic_shapes\[(\d+)\]", header)
    return match.groups() if match else None


class TestExportCHeaderShapeType(unittest.TestCase):
    def test_sym_int32_shape_slots(self):
        """32-bit symbolic dimensions are passed as i32, so the header
        declares int32_t slots."""
        a = make_fake_tensor(
            Float32,
            (cute.sym_int32(), cute.sym_int32()),
            stride=(cute.sym_int64(), 1),
        )
        self.assertEqual(_shape_slot_decl(_export_header(a)), ("int32_t", "2"))

    def test_sym_int64_shape_slots(self):
        """64-bit symbolic dimensions are passed as i64. The header used to
        declare int32_t slots for them, which is half the width the compiled
        function reads."""
        a = make_fake_tensor(
            Float32,
            (cute.sym_int64(), cute.sym_int64()),
            stride=(cute.sym_int64(), 1),
        )
        self.assertEqual(_shape_slot_decl(_export_header(a)), ("int64_t", "2"))

    def test_sym_int64_shape_slots_match_abi(self):
        """The width in the header is the width in the calling convention, not
        a constant that happens to agree with it."""
        a = make_fake_tensor(
            Float32,
            (cute.sym_int64(), cute.sym_int64()),
            stride=(cute.sym_int64(), 1),
        )
        compiled = cute.compile(_entry, a, make_fake_stream())
        ciface = [
            line
            for line in str(compiled.ir_module).splitlines()
            if "llvm.func @_mlir_ciface" in line
        ]
        self.assertEqual(len(ciface), 1)
        self.assertIn("struct<(i64, i64)>", ciface[0])

    def test_static_shape_has_no_shape_slots(self):
        """A fully static shape needs no runtime slots at all."""
        a = make_fake_tensor(Float32, (128, 256), stride=(256, 1))
        self.assertIsNone(_shape_slot_decl(_export_header(a)))

    def test_dlpack_tensor_shape_slots(self):
        """A tensor marked dynamic through DLPack has no SymInt dimensions, so
        its slots stay 32-bit."""
        a = from_dlpack(np.zeros((8, 16), dtype=np.float32)).mark_layout_dynamic()
        self.assertEqual(_shape_slot_decl(_export_header(a)), ("int32_t", "2"))

    def test_mixed_width_shape_dims_rejected(self):
        """One array cannot hold dimensions of two widths, so a tensor mixing
        them is refused instead of being truncated to the narrower one."""
        a = make_fake_tensor(
            Float32,
            (cute.sym_int32(), cute.sym_int64()),
            stride=(cute.sym_int64(), 1),
        )
        with self.assertRaises(DSLRuntimeError) as ctx:
            _export_header(a)
        self.assertIn("to be of the same width", _flat_message(ctx.exception))

    def test_tensor_list_shape_slots(self):
        """A list of tensors shares one descriptor typedef, which takes the
        width of the dimensions its elements agree on."""
        tensors = [
            make_fake_tensor(
                Float32,
                (cute.sym_int64(), cute.sym_int64()),
                stride=(cute.sym_int64(), 1),
            )
            for _ in range(2)
        ]
        header = _export_header(tensors, entry=_entry_list)
        self.assertEqual(_shape_slot_decl(header), ("int64_t", "2"))

    def test_tensor_list_mismatched_widths_rejected(self):
        """Elements that disagree on width would need two typedefs, so the
        descriptor consistency check covers width as well as the masks."""
        tensors = [
            make_fake_tensor(Float32, (sym(), sym()), stride=(cute.sym_int64(), 1))
            for sym in (cute.sym_int64, cute.sym_int32)
        ]
        with self.assertRaises(DSLRuntimeError) as ctx:
            _export_header(tensors, entry=_entry_list)
        self.assertIn("dynamic shape width", _flat_message(ctx.exception))


if __name__ == "__main__":
    unittest.main()
