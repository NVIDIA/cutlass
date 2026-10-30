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

from cutlass_library.generator import CreateGemmOperator, CreateRankKOperator, define_parser
from cutlass_library.library import (
    BlasMode,
    DataType,
    FillMode,
    LayoutType,
    MathInstruction,
    OpcodeClass,
    OperationKind,
    TileDescription,
)
from cutlass_library.manifest import Manifest


class TestOperationSelection(unittest.TestCase):
    def generate_operations(self, operations):
        args = define_parser().parse_args(["--operations", operations, "--architectures", "50"])
        manifest = Manifest(args)
        instruction = MathInstruction(
            [1, 1, 1], DataType.f32, DataType.f32, DataType.f32, OpcodeClass.Simt
        )
        tile = TileDescription([32, 32, 8], 2, [2, 2, 1], instruction, 50, 1024)
        CreateGemmOperator(
            manifest,
            [[LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.RowMajor]],
            [tile], [DataType.f32] * 4, [1],
        )
        # This generator creates both rank-k and rank-2k candidates.
        CreateRankKOperator(
            manifest,
            [[LayoutType.RowMajor, LayoutType.RowMajor]],
            [FillMode.Lower], [tile], [DataType.f32] * 3, [1], BlasMode.symmetric,
        )
        return list(manifest.operations_by_name.values())

    def assert_operation_kinds(self, selection, expected):
        operations = self.generate_operations(selection)
        self.assertEqual(len(operations), len(expected))
        self.assertEqual({operation.operation_kind for operation in operations}, expected)
        return operations

    def test_rank_2k_only(self):
        operations = self.assert_operation_kinds("rank_2k", {OperationKind.Rank2K})
        self.assertIn("syr2k", operations[0].procedural_name())

    def test_rank_2k_with_gemm(self):
        self.assert_operation_kinds("gemm,rank_2k", {OperationKind.Gemm, OperationKind.Rank2K})

    def test_rank_k_only(self):
        self.assert_operation_kinds("rank_k", {OperationKind.RankK})

    def test_all_operations(self):
        self.assert_operation_kinds(
            "all", {OperationKind.Gemm, OperationKind.RankK, OperationKind.Rank2K}
        )


if __name__ == "__main__":
    unittest.main()
