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
Unit tests for cute.is_major mode argument handling.

is_major is typed `mode: Union[int, List[int]]`, but it wrapped its argument
as `get(stride, mode=[mode])`, which double-listed a list input and raised
`TypeError: '<=' not supported between instances of 'int' and 'list'` for any
List[int] mode. A single int mode and its single-element list form must agree,
and a hierarchical list path must not crash.
"""

import unittest

from cutlass.cute import is_major


class TestIsMajorListMode(unittest.TestCase):
    def test_single_mode_int_and_list_agree(self):
        for stride in ((8, 1), (1, 8)):
            for m in (0, 1):
                self.assertEqual(
                    is_major([m], stride),
                    is_major(m, stride),
                    msg=f"mode {m} on stride {stride}",
                )

    def test_hierarchical_list_mode(self):
        # A multi-index path into a nested stride must resolve, not crash.
        self.assertIsInstance(is_major([0, 1], ((8, 1), 4)), bool)
        self.assertIsInstance(is_major([0, 0], ((8, 1), 4)), bool)


if __name__ == "__main__":
    unittest.main()
