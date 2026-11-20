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
Unit tests for the TMA global-stride alignment check (NVIDIA/cutlass#3866).

TMA descriptors need every global stride (in bytes) to be a multiple of 16.
The driver rejects other strides, but the CuTe DSL used to build a descriptor
with the stride silently rounded down, so a TMA load read the wrong rows.
``_misaligned_tma_strides`` is the pure rule (plain Python values, no IR);
``_check_tma_gmem_strides`` applies it to a tensor's static shape/stride and
raises ``ValueError``. Host-only; no GPU is needed.
"""

import unittest

import cutlass
from cutlass.cute.nvgpu.cpasync.helpers import (
    _check_tma_gmem_strides,
    _misaligned_tma_strides,
)

DYN = "dynamic"  # stands in for any non-int (dynamic) shape or stride entry


class TestMisalignedTmaStrides(unittest.TestCase):
    def test_aligned_pitches_are_clean(self):
        for pitch in (64, 72):  # 128 B and 144 B
            with self.subTest(pitch=pitch):
                self.assertEqual(_misaligned_tma_strides((128, 64), (pitch, 1), 16), [])

    def test_padded_pitches_are_flagged(self):
        for pitch in (68, 66):  # 136 B and 132 B
            with self.subTest(pitch=pitch):
                self.assertEqual(
                    _misaligned_tma_strides((128, 64), (pitch, 1), 16),
                    [(0, 128, pitch)],
                )

    def test_extent_one_mode_is_ignored(self):
        # The L = 1 batch mode created by unsqueeze(-1) has stride 1 and must not
        # be flagged, or every aligned kernel in the issue's own sweep would break.
        self.assertEqual(
            _misaligned_tma_strides((128, 64, 1), (68, 1, 1), 16), [(0, 128, 68)]
        )
        self.assertEqual(_misaligned_tma_strides((128, 64, 1), (72, 1, 1), 16), [])

    def test_extent_one_mode_with_odd_stride_is_ignored(self):
        self.assertEqual(_misaligned_tma_strides((128, 64, 1), (64, 1, 3), 16), [])

    def test_mn_major_flags_the_pitch_mode(self):
        self.assertEqual(
            _misaligned_tma_strides((64, 128), (1, 68), 16), [(1, 128, 68)]
        )

    def test_every_misaligned_mode_is_reported(self):
        # 66 el = 132 B and 530 el = 1060 B are not multiples of 16 B.
        self.assertEqual(
            _misaligned_tma_strides((16, 8, 4), (1, 66, 530), 16),
            [(1, 8, 66), (2, 4, 530)],
        )
        # 1056 el = 2112 B is a multiple of 16 B.
        self.assertEqual(
            _misaligned_tma_strides((16, 8, 4), (1, 66, 1056), 16), [(1, 8, 66)]
        )

    def test_32bit_elements(self):
        self.assertEqual(_misaligned_tma_strides((128, 64), (4, 1), 32), [])
        self.assertEqual(_misaligned_tma_strides((128, 64), (36, 1), 32), [])
        self.assertEqual(
            _misaligned_tma_strides((128, 64), (3, 1), 32), [(0, 128, 3)]
        )

    def test_sub_byte_elements_use_bits_not_elements(self):
        self.assertEqual(_misaligned_tma_strides((128, 64), (32, 1), 4), [])  # 16 B
        self.assertEqual(
            _misaligned_tma_strides((128, 64), (24, 1), 4), [(0, 128, 24)]  # 12 B
        )
        self.assertEqual(
            _misaligned_tma_strides((128, 64), (36, 1), 4), [(0, 128, 36)]  # 18 B
        )

    def test_broadcast_stride_zero_is_fine(self):
        self.assertEqual(_misaligned_tma_strides((128, 64), (0, 1), 16), [])

    def test_dynamic_entries_are_ignored(self):
        self.assertEqual(_misaligned_tma_strides((128, 64), (DYN, 1), 16), [])
        self.assertEqual(_misaligned_tma_strides((DYN, 64), (68, 1), 16), [])

    def test_hierarchical_modes_are_skipped(self):
        # Sub-modes of a nested mode can be merged by the TMA lowering, so the
        # check only judges modes whose shape and stride are plain ints.
        self.assertEqual(
            _misaligned_tma_strides(((2, 64), 128), ((1, 2), 68), 16), [(1, 128, 68)]
        )


class _FakeTensor:
    """Just the attributes the check reads: shape, stride and element_type."""

    def __init__(self, shape, stride, element_type=cutlass.Float16):
        self.shape = shape
        self.stride = stride
        self.element_type = element_type


class TestCheckTmaGmemStrides(unittest.TestCase):
    def test_aligned_static_tensor_passes(self):
        _check_tma_gmem_strides(_FakeTensor((128, 64, 1), (64, 1, 1)))
        _check_tma_gmem_strides(_FakeTensor((128, 64, 1), (72, 1, 1)))

    def test_padded_static_tensor_raises(self):
        with self.assertRaisesRegex(ValueError, r"136 B"):
            _check_tma_gmem_strides(_FakeTensor((128, 64, 1), (68, 1, 1)))
        with self.assertRaisesRegex(ValueError, r"mode 0"):
            _check_tma_gmem_strides(_FakeTensor((128, 64, 1), (66, 1, 1)))

    def test_error_message_states_the_rule(self):
        with self.assertRaisesRegex(ValueError, r"16 B"):
            _check_tma_gmem_strides(_FakeTensor((128, 64, 1), (68, 1, 1)))

    def test_32bit_and_sub_byte_tensors(self):
        _check_tma_gmem_strides(_FakeTensor((128, 64), (36, 1), cutlass.Float32))
        with self.assertRaises(ValueError):
            _check_tma_gmem_strides(_FakeTensor((128, 64), (3, 1), cutlass.Float32))
        with self.assertRaises(ValueError):
            _check_tma_gmem_strides(_FakeTensor((128, 64), (24, 1), cutlass.Int4))

    def test_dynamic_strides_are_not_checked(self):
        _check_tma_gmem_strides(_FakeTensor((128, 64, 1), (DYN, 1, 1)))

    def test_element_type_without_width_is_skipped(self):
        _check_tma_gmem_strides(_FakeTensor((128, 64, 1), (68, 1, 1), element_type=None))

    def test_rank_one_tensor_reports_bare_values(self):
        # A rank-1 shape/stride can come back as a bare value instead of a tuple.
        _check_tma_gmem_strides(_FakeTensor(64, 1))


if __name__ == "__main__":
    unittest.main()
