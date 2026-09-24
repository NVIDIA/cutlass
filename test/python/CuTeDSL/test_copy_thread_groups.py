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

import unittest

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu.warp import StMatrix16x8x8bOp


@cute.jit
def make_copy(threads: cutlass.Constexpr, matrices: cutlass.Constexpr):
    atom = cute.make_copy_atom(
        StMatrix16x8x8bOp(transpose=True, num_matrices=matrices), cutlass.Uint8
    )
    cute.make_tiled_copy_tv(
        atom, cute.make_layout((threads, 1)), cute.make_layout((1, 4 * matrices))
    )


@cute.jit
def make_scalar_copy():
    atom = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), cutlass.Float32)
    cute.make_tiled_copy_tv(atom, cute.make_layout((1, 1)), cute.make_layout((1, 1)))


@cute.jit
def make_direct_copy(groups: cutlass.Constexpr, matrices: cutlass.Constexpr):
    atom = cute.make_copy_atom(
        StMatrix16x8x8bOp(transpose=True, num_matrices=matrices), cutlass.Uint8
    )
    # Nested thread modes must be counted by their product, not their rank.
    layout_tv = cute.make_layout(((8, groups), 4 * matrices))
    cute.make_tiled_copy(atom, layout_tv, (8 * groups, 4 * matrices))


class TestCopyThreadGroups(unittest.TestCase):
    def test_rejects_partial_warps(self):
        for matrices in (1, 2, 4):
            for threads in (1, 16, 48):
                with self.subTest(matrices=matrices, threads=threads):
                    with self.assertRaisesRegex(ValueError, "multiple of 32 threads"):
                        cute.compile(make_copy, threads, matrices)

    def test_accepts_whole_warps(self):
        for matrices in (1, 2, 4):
            for threads in (32, 64):
                with self.subTest(matrices=matrices, threads=threads):
                    cute.compile(make_copy, threads, matrices)

    def test_scalar_atom_keeps_single_thread_support(self):
        cute.compile(make_scalar_copy)

    def test_direct_constructor_rejects_partial_nested_warps(self):
        for matrices in (1, 2, 4):
            for groups in (1, 2, 6):
                with self.subTest(matrices=matrices, groups=groups):
                    with self.assertRaisesRegex(ValueError, "multiple of 32 threads"):
                        cute.compile(make_direct_copy, groups, matrices)

    def test_direct_constructor_accepts_nested_whole_warps(self):
        for matrices in (1, 2, 4):
            for groups in (4, 8):
                with self.subTest(matrices=matrices, groups=groups):
                    cute.compile(make_direct_copy, groups, matrices)


if __name__ == "__main__":
    unittest.main()
