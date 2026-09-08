# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest
from unittest.mock import patch

from bloom import test as bloom_test


class BloomWrapperTest(unittest.TestCase):
    def test_forwards_shared_arguments_and_removes_bloom_metadata(self) -> None:
        argv = [
            "-s",
            "source",
            "-p",
            "cutlass-4.5.0",
            "-w",
            ".",
            "--sm",
            "100",
            "-t",
            "L0_oss_dsl_test",
            "--test-spec",
            "testSpec.json",
            "--scm-properties=scmProperties.json",
            "--subrepo",
            "cutlass",
            "--dry-run",
        ]

        forwarded = bloom_test._forwarded_args(argv)

        self.assertEqual(
            forwarded,
            [
                "-s",
                "source",
                "-p",
                "cutlass-4.5.0",
                "-w",
                ".",
                "--sm",
                "100",
                "-t",
                "L0_oss_dsl_test",
                "--dry-run",
            ],
        )

    def test_delegates_to_cutlass_cicd_main(self) -> None:
        with patch.object(bloom_test, "cutlass_cicd_main", return_value=7) as delegated:
            result = bloom_test.main(["--sm", "100", "--test-spec", "spec.json"])

        self.assertEqual(result, 7)
        delegated.assert_called_once_with(["--sm", "100"])


if __name__ == "__main__":
    unittest.main()
