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

"""CPU IR regressions for domain_offset address-width propagation (#3604)."""

import unittest

import cutlass
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass._mlir.dialects import func


def offset_ir(space=cute.AddressSpace.gmem, *, nested=False, identity=False,
              constant=False, dynamic_stride=False, row_type=cutlass.Int32,
              divisor=1):
    with ir.Context(), ir.Location.unknown():
        module = ir.Module.create()
        with ir.InsertionPoint(module.body):
            signature = ir.FunctionType.get(
                [ir.IntegerType.get_signless(64), row_type.mlir_type,
                 ir.IntegerType.get_signless(64)], [])
            function = func.FuncOp("offset", signature)
            with ir.InsertionPoint(function.add_entry_block()):
                row = row_type(function.arguments[1])
                if divisor != 1:
                    row = cute.assume(row, divby=divisor)
                stride = cutlass.Int64(function.arguments[2]) if dynamic_stride else 4
                if nested:
                    shape, strides, coord = ((2**29 + 1, 1), 4), ((stride, 0), 1), ((row, 0), 0)
                else:
                    shape, strides, coord = (2**29 + 1, 4), (stride, 1), (row, 0)
                if constant:
                    coord = (2, 0)
                if identity:
                    tensor = cute.make_identity_tensor(shape)
                else:
                    pointer = cute.make_ptr(cutlass.BFloat16,
                                            cutlass.Int64(function.arguments[0]),
                                            space, assumed_align=16)
                    tensor = cute.make_tensor(pointer, cute.make_layout(shape, stride=strides))
                shifted = cute.domain_offset(coord, tensor)
                iterator_type = str(shifted.iterator.type) if not identity else str(shifted.type)
                func.ReturnOp([])
        module.operation.verify()
        return str(module), iterator_type


class TestDomainOffset(unittest.TestCase):
    def test_global_static_stride_widens_before_crd2idx(self):
        text, _ = offset_ir()
        line = next(x for x in text.splitlines() if "cute.crd2idx" in x)
        self.assertIn("i64", line)
        self.assertLess(text.index("arith.extsi"), text.index("cute.crd2idx"))

    def test_generic_pointer_uses_wide_offset(self):
        text, _ = offset_ir(cute.AddressSpace.generic)
        self.assertIn("i64", next(x for x in text.splitlines() if "cute.crd2idx" in x))

    def test_nested_coordinates(self):
        text, _ = offset_ir(nested=True)
        self.assertIn("i64", next(x for x in text.splitlines() if "cute.crd2idx" in x))

    def test_divisibility_and_alignment(self):
        text, pointer_type = offset_ir(divisor=8)
        self.assertIn("?{i64 div=32}", text)
        self.assertIn("align<16>", pointer_type)

    def test_static_constants_remain_static(self):
        text, _ = offset_ir(constant=True)
        self.assertNotIn("arith.extsi", text)
        self.assertIn('!cute.int_tuple<"8">', text)

    def test_shared_memory_keeps_narrow_arithmetic(self):
        text, _ = offset_ir(cute.AddressSpace.smem)
        self.assertNotIn("arith.extsi", text)
        self.assertNotIn("i64", next(x for x in text.splitlines() if "cute.crd2idx" in x))

    def test_identity_tensor_is_unchanged(self):
        text, _ = offset_ir(identity=True)
        self.assertNotIn("arith.extsi", text)
        self.assertNotIn("i64", next(x for x in text.splitlines() if "cute.crd2idx" in x))

    def test_existing_wide_coordinate(self):
        text, _ = offset_ir(row_type=cutlass.Int64)
        self.assertNotIn("arith.extsi", text)
        self.assertIn("i64", next(x for x in text.splitlines() if "cute.crd2idx" in x))

    def test_unsigned_coordinate_zero_extends(self):
        text, _ = offset_ir(row_type=cutlass.Uint32)
        self.assertIn("arith.extui", text)
        self.assertNotIn("arith.extsi", text)

    def test_dynamic_i64_stride_stays_wide(self):
        text, _ = offset_ir(dynamic_stride=True)
        self.assertIn("i64", next(x for x in text.splitlines() if "cute.crd2idx" in x))


if __name__ == "__main__":
    unittest.main()
