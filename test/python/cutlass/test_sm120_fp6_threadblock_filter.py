#################################################################################################
#
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
#################################################################################################

"""
Regression tests for SM120 manifest filtering of FP6 ElementD threadblock shapes.

See https://github.com/NVIDIA/cutlass/issues/3211
"""

import os
import sys
import unittest

_CUTLASS_PY = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "python")
)
if _CUTLASS_PY not in sys.path:
  sys.path.insert(0, _CUTLASS_PY)

from cutlass_library.library import (  # noqa: E402
    DataType,
    LayoutType,
    MathInstruction,
    MathOperation,
    OpcodeClass,
    TileDescription,
    sm120_fp6_epilogue_threadblock_shape_ok,
)


class Sm120Fp6ThreadblockFilterTests(unittest.TestCase):
  def test_helper_non_fp6_always_ok(self):
    self.assertTrue(
        sm120_fp6_epilogue_threadblock_shape_ok(
            (32, 32, 128), DataType.f32, LayoutType.RowMajor))

  def test_helper_fp6_rowmajor_needs_cta_n_divisible_by_128(self):
    self.assertFalse(
        sm120_fp6_epilogue_threadblock_shape_ok(
            (128, 32, 128), DataType.e3m2, LayoutType.RowMajor))
    self.assertFalse(
        sm120_fp6_epilogue_threadblock_shape_ok(
            (128, 64, 128), DataType.e3m2, LayoutType.RowMajor))
    self.assertTrue(
        sm120_fp6_epilogue_threadblock_shape_ok(
            (128, 128, 128), DataType.e3m2, LayoutType.RowMajor))

  def test_helper_fp6_colmajor_needs_cta_m_divisible_by_128(self):
    self.assertFalse(
        sm120_fp6_epilogue_threadblock_shape_ok(
            (64, 128, 128), DataType.e2m3, LayoutType.ColumnMajor))
    self.assertTrue(
        sm120_fp6_epilogue_threadblock_shape_ok(
            (128, 128, 128), DataType.e2m3, LayoutType.ColumnMajor))

  def test_mixed_8bits_tile_list_matches_epilogue_constraint(self):
    """Same threadblocks / dtypes as GenerateSM120_TensorOp_mixed_8bits_UMMA_gemm_with_block_scaled."""
    tile_sizes = [
        [128, 32, 128],
        [128, 64, 128],
        [128, 128, 128],
    ]
    d_layout = LayoutType.RowMajor
    d_type = DataType.e3m2
    filtered = [
        ts for ts in tile_sizes
        if sm120_fp6_epilogue_threadblock_shape_ok(ts, d_type, d_layout)
    ]
    self.assertEqual(filtered, [[128, 128, 128]])

  def test_filtered_tile_descriptions_non_empty_for_fp32(self):
    """Sanity: filtering must not drop all tiles for non-FP6 D types."""
    tile_sizes = [[128, 32, 128], [128, 128, 128]]
    math_inst = MathInstruction(
        [16, 8, 32],
        DataType.e4m3,
        DataType.e4m3,
        DataType.f32,
        OpcodeClass.BlockScaledTensorOp,
        MathOperation.multiply_add,
        DataType.ue8m0,
    )
    tile_descriptions = [
        TileDescription(ts, 0, [4, 1, 1], math_inst, 120, 121, [1, 1, 1])
        for ts in tile_sizes
    ]
    layouts = [[
        [LayoutType.RowMajor, 128],
        [LayoutType.ColumnMajor, 128],
        [LayoutType.RowMajor, 0],
    ]]
    data_type = {
        "d_type": DataType.f32,
    }
    filtered = [
        td for td in tile_descriptions
        if all(
            sm120_fp6_epilogue_threadblock_shape_ok(
                td.threadblock_shape, data_type["d_type"], ly[2][0])
            for ly in layouts)
    ]
    self.assertEqual(len(filtered), 2)


if __name__ == "__main__":
  unittest.main()
