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
Unit tests for ``cutlass.utils.blackwell_helpers.get_smem_layout_atom_ab`` with
MN-major 32-bit operands.

UMMA reads an MN-major 32-bit (tf32) operand only through the 128B swizzle
with 32B atomicity (``MN_SW128_32B``), whose atom spans 32 elements along the
major mode. The helper used to fall back to ``MN_SW64`` / ``MN_SW32`` /
``MN_INTER`` for smaller major extents, as it does for 16- and 8-bit types;
those layouts compile and run but the MMA produces wrong results silently
(e.g. the dense GEMM examples with tf32, ``use_2cta_instrs``, an MN-major B
and an MMA tiler N of 32, 96, 160 or 224). The helper now raises
``ValueError`` for such extents, mirroring ``sm100_smem_selector`` in the C++
collective builders. Host-only; no GPU is needed.
"""

import os
import unittest

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import tcgen05
from cutlass.utils import blackwell_helpers as sm100_utils

os.environ.setdefault("CUTE_DSL_ARCH", "sm_100a")

MN = tcgen05.OperandMajorMode.MN
K = tcgen05.OperandMajorMode.K
Kind = tcgen05.SmemLayoutAtomKind


def _select(major_mode, dtype, smem_shape_mn_k):
    """Run the heuristic inside a traced @cute.jit function and return the kind."""
    picked = []

    @cute.jit
    def entry():
        picked.append(
            sm100_utils.get_smem_layout_atom_ab(major_mode, dtype, smem_shape_mn_k)
        )

    cute.compile(entry)
    return picked[0]


class TestSmemLayoutAtomAbMnMajor32Bit(unittest.TestCase):
    def test_mn_major_32bit_multiple_of_32_rows_is_sw128_32b(self):
        for rows in (32, 64, 96, 128):
            for dtype in (cutlass.TFloat32, cutlass.Float32):
                with self.subTest(rows=rows, dtype=dtype):
                    self.assertIs(
                        _select(MN, dtype, (rows, 32)), Kind.MN_SW128_32B
                    )

    def test_mn_major_32bit_other_rows_raises(self):
        # 2-CTA B tiles with MMA tiler N of 32 / 96 / 160 / 224 have N/2 rows.
        for rows in (8, 16, 24, 48, 80, 112):
            with self.subTest(rows=rows):
                with self.assertRaisesRegex(ValueError, "multiple of 32 elements"):
                    _select(MN, cutlass.TFloat32, (rows, 32))

    def test_mn_major_narrow_types_unchanged(self):
        self.assertIs(_select(MN, cutlass.BFloat16, (64, 64)), Kind.MN_SW128)
        self.assertIs(_select(MN, cutlass.BFloat16, (32, 64)), Kind.MN_SW64)
        self.assertIs(_select(MN, cutlass.BFloat16, (48, 64)), Kind.MN_SW32)
        self.assertIs(_select(MN, cutlass.BFloat16, (8, 64)), Kind.MN_INTER)
        self.assertIs(_select(MN, cutlass.Float8E4M3FN, (32, 128)), Kind.MN_SW32)
        self.assertIs(_select(MN, cutlass.Float8E4M3FN, (48, 128)), Kind.MN_INTER)

    def test_k_major_32bit_unchanged(self):
        self.assertIs(_select(K, cutlass.TFloat32, (48, 32)), Kind.K_SW128)
        self.assertIs(_select(K, cutlass.TFloat32, (48, 16)), Kind.K_SW64)
        self.assertIs(_select(K, cutlass.TFloat32, (48, 8)), Kind.K_SW32)


if __name__ == "__main__":
    unittest.main()
