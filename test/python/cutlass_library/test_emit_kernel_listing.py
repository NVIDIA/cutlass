# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import unittest

from cutlass_library.emit_kernel_listing import audit_csv_fields, get_kernel_features
from cutlass_library.gemm_operation import GemmOperation
from cutlass_library.library import (
    DataType,
    GemmKind,
    LayoutType,
    MathInstruction,
    OpcodeClass,
    TensorDescription,
    TileDescription,
)


class TestKernelAuditScaleFactors(unittest.TestCase):
    def make_operation(self, block_scaled, output_scale=DataType.void):
        element = DataType.e2m1 if block_scaled else DataType.f16
        opcode = OpcodeClass.BlockScaledTensorOp if block_scaled else OpcodeClass.TensorOp
        instruction = MathInstruction([128, 128, 64], element, element, DataType.f32, opcode)
        tile = TileDescription([128, 128, 64], 0, [4, 1, 1], instruction, 100, 100)
        tensor = TensorDescription(element, LayoutType.RowMajor, 16)
        output = TensorDescription(DataType.f16, LayoutType.RowMajor, 8)
        return GemmOperation(
            GemmKind.BlockScaledUniversal3x if block_scaled else GemmKind.Universal3x,
            100, tile, tensor, tensor, output, DataType.f32,
            ScaleFactorA=DataType.ue8m0,
            ScaleFactorB=DataType.ue8m0,
            ScaleFactorD={
                "tensor": TensorDescription(output_scale, LayoutType.RowMajor),
                "vector_size": 16,
            },
        )

    def audit_columns(self, operation):
        features = get_kernel_features(operation, "test_kernel", False, None)
        return dict(zip(audit_csv_fields, features))

    def test_block_scaled_input_without_scaled_output(self):
        columns = self.audit_columns(self.make_operation(True))
        self.assertEqual(columns["Type_SFA"], "ue8m0")
        self.assertEqual(columns["Type_SFD"], "void")

    def test_distinct_input_and_output_scale_types(self):
        columns = self.audit_columns(self.make_operation(True, DataType.ue4m3))
        self.assertEqual(columns["Type_SFA"], "ue8m0")
        self.assertEqual(columns["Type_SFD"], "ue4m3")

    def test_unscaled_gemm(self):
        columns = self.audit_columns(self.make_operation(False))
        self.assertEqual(columns["Type_SFA"], "void")
        self.assertEqual(columns["Type_SFD"], "void")


if __name__ == "__main__":
    unittest.main()
