# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from cutlass_cicd import test as test_entrypoint
from cutlass_cicd.common.execution import CommandRunner, TestContext
from cutlass_cicd.cutlass_cpp import suites as cpp_suites
from cutlass_cicd.cutlass_cpp.suites import (
    _move_native_junit_files,
    l0_functional_commands,
    run_l0_functional,
)


class CutlassCppTest(unittest.TestCase):
    def make_context(self, root: Path, *, dry_run: bool = True) -> TestContext:
        package_dir = root / "cutlass-4.6.1"
        package_dir.mkdir()
        return TestContext(
            source_dir=root / "source",
            workspace=root / "workspace",
            sm="90",
            python="python3",
            cuda_major=12,
            arch="x86_64",
            package_dir=package_dir,
            setup_environment=False,
            ctest_timeout=1234,
            ctest_parallelism=5,
            dry_run=dry_run,
        )

    def test_l0_functional_uses_three_legacy_ctest_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir))

            commands = l0_functional_commands(context)

            self.assertEqual(len(commands), 3)
            self.assertEqual(
                [command.name for command in commands],
                [
                    "ctest_l0_example_tests",
                    "ctest_l0_non_example_tests",
                    "ctest_l0_tmem_alloc_tracking_tests",
                ],
            )
            resolved_package_dir = context.package_dir.resolve()
            for command in commands:
                self.assertEqual(
                    command.cwd,
                    context.package_dir / "test" / "cutlass",
                )
                self.assertEqual(command.args[:4], ("ctest", "-T", "Test", "-V"))
                self.assertIn("1234", command.args)
                self.assertIn("5", command.args)
                self.assertTrue(
                    command.env["PATH"].startswith(
                        os.pathsep.join(
                            (
                                str(resolved_package_dir / "bin"),
                                str(resolved_package_dir / "test" / "cutlass" / "bin"),
                            )
                        )
                    )
                )
            self.assertIn("--output-junit", commands[0].args)
            self.assertEqual(
                commands[2].env["CUTLASS_TEST_SETS"],
                "tmem_alloc_tracking",
            )
            self.assertNotIn("CUTLASS_TEST_SETS", commands[0].env)

    def test_l0_functional_dry_run_does_not_require_a_gpu_or_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir))

            self.assertEqual(run_l0_functional(context), 0)
            self.assertFalse(context.test_outputs_dir.exists())

    def test_native_xml_reports_are_moved_to_current_report_directory(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir), dry_run=False)
            native_dir = context.package_dir / "test" / "cutlass" / "bin"
            native_dir.mkdir(parents=True)
            native_report = native_dir / "unit_sm90.gtest.xml"
            native_report.write_text("<testsuites/>", encoding="utf-8")

            _move_native_junit_files(context)

            self.assertFalse(native_report.exists())
            self.assertTrue(
                (context.junit_report_dir / native_report.name).is_file()
            )

    def test_windows_environment_puts_library_directories_on_path(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            package_dir = Path(temp_dir) / "cutlass"

            with patch.object(cpp_suites.os, "name", "nt"):
                environment = cpp_suites._test_environment(package_dir)

            self.assertNotIn("LD_LIBRARY_PATH", environment)
            self.assertIn(str((package_dir / "lib64").resolve()), environment["PATH"])
            self.assertIn(
                str((package_dir / "test" / "cutlass" / "lib").resolve()),
                environment["PATH"],
            )

    def test_missing_ctest_manifest_is_left_for_ctest_to_handle(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir), dry_run=False)

            with patch.object(
                CommandRunner,
                "run",
                return_value=0,
            ) as run, patch.object(cpp_suites, "_archive_test_outputs"):
                result = run_l0_functional(context)

            self.assertEqual(result, 0)
            self.assertEqual(run.call_count, 3)
            self.assertTrue(
                (context.junit_report_dir / "L0_functional.xml").is_file()
            )

    def test_l0_functional_cli_dry_run(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            context = self.make_context(root)

            result = test_entrypoint.main(
                [
                    "--source-dir",
                    str(context.source_dir),
                    "--workspace",
                    str(context.workspace),
                    "--package-dir",
                    str(context.package_dir),
                    "--sm",
                    "90",
                    "--test",
                    "L0_functional",
                    "--cuda-major",
                    "12",
                    "--skip-setup",
                    "--dry-run",
                ]
            )

            self.assertEqual(result, 0)


if __name__ == "__main__":
    unittest.main()
