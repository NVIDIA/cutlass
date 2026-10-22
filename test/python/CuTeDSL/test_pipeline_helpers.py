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

import unittest

import cutlass.pipeline as pipeline


class TestPipelineHelpers(unittest.TestCase):
    def test_cooperative_group_accepts_deprecated_alignment_argument(self):
        with self.assertWarnsRegex(DeprecationWarning, "alignment"):
            group = pipeline.CooperativeGroup(pipeline.Agent.Thread, 128, 32)

        self.assertIs(group.agent, pipeline.Agent.Thread)
        self.assertEqual(group.size, 128)

    def test_cooperative_group_rejects_non_positive_thread_size_with_alignment(self):
        with self.assertWarnsRegex(DeprecationWarning, "alignment"):
            with self.assertRaisesRegex(ValueError, "greater than 0"):
                pipeline.CooperativeGroup(pipeline.Agent.Thread, 0, 32)


if __name__ == "__main__":
    unittest.main()
