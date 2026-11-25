# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from cutlass_cicd.common.execution import CommandRunner, TestContext
from cutlass_cicd.cutedsl.commands import make_command
from cutlass_cicd.cutedsl.setup import setup_cutedsl_environment
from cutlass_cicd.cutedsl.tests.pytest_flow import run_pytest_flow


class CutedslEnvironmentTest(unittest.TestCase):
    def setUp(self) -> None:
        free_threaded_probe = patch(
            "cutlass_cicd.cutedsl.setup._is_free_threaded_python",
            return_value=False,
        )
        self.is_free_threaded_python = free_threaded_probe.start()
        self.addCleanup(free_threaded_probe.stop)

    def make_context(self, root: Path, **overrides: object) -> TestContext:
        values = {
            "source_dir": root / "source",
            "workspace": root / "workspace",
            "sm": "100",
            "python": "/usr/bin/python3",
            "cuda_major": 12,
            "arch": "x86_64",
            "package_dir": root / "package",
            "setup_environment": True,
            "pytest_workers": "4",
        }
        values.update(overrides)
        context = TestContext(**values)
        context.source_dir.mkdir(parents=True)
        context.workspace.mkdir(parents=True)
        return context

    def prepare_editable_tree(self, context: TestContext) -> None:
        editable_root = context.source_dir / "python" / "CuTeDSL"
        editable_root.mkdir(parents=True)
        (editable_root / "pyproject.toml").write_text("", encoding="utf-8")

    def test_setup_dry_run_matches_bloom_editable_sequence(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir))
            self.prepare_editable_tree(context)
            results = []
            runner = CommandRunner(dry_run=True, collect_result=results.append)

            configured = setup_cutedsl_environment(context, runner)

            self.assertIsNotNone(configured)
            assert configured is not None
            self.assertEqual(
                configured.python,
                str(context.workspace / "wheel_test" / "bin" / "python"),
            )
            step_names = [result.name for result in results]
            self.assertEqual(step_names[0], "setup_create_venv")
            self.assertEqual(step_names[-1], "setup_editable_install")
            for required_step in (
                "setup_pytorch",
                "setup_test_requirements",
            ):
                self.assertIn(required_step, step_names)
            self.assertNotIn("setup_distributed_requirements", step_names)
            pytorch_command = next(
                result.command for result in results if result.name == "setup_pytorch"
            )
            self.assertEqual(
                pytorch_command.args[-3:],
                [
                    "torch==2.11.0",
                    "--index-url",
                    "https://download.pytorch.org/whl/cu128",
                ],
            )
            self.assertIn("--clear", results[0].command.args)
            self.assertIn(
                str(context.source_dir / "python" / "CuTeDSL"),
                results[-1].command.args,
            )

    def test_setup_uses_cu13_editable_extra(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir), cuda_major=13, sm="90")
            self.prepare_editable_tree(context)
            results = []
            runner = CommandRunner(dry_run=True, collect_result=results.append)

            configured = setup_cutedsl_environment(context, runner)

            self.assertIsNotNone(configured)
            pytorch_command = next(
                result.command for result in results if result.name == "setup_pytorch"
            )
            self.assertEqual(
                pytorch_command.args[-1],
                "https://download.pytorch.org/whl/cu130",
            )
            editable_command = results[-1].command
            self.assertEqual(
                editable_command.args[-1],
                f"{context.source_dir / 'python' / 'CuTeDSL'}[cu13]",
            )

    def test_setup_filters_torch_c_dlpack_for_free_threaded_python(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir), cuda_major=13)
            self.prepare_editable_tree(context)
            self.is_free_threaded_python.return_value = True
            results = []
            runner = CommandRunner(dry_run=True, collect_result=results.append)

            configured = setup_cutedsl_environment(context, runner)

            self.assertIsNotNone(configured)
            requirements_command = next(
                result.command
                for result in results
                if result.name == "setup_test_requirements"
            )
            filtered_requirements = Path(requirements_command.args[-1])
            self.assertEqual(filtered_requirements.parent, context.workspace)
            self.assertNotIn(
                "torch-c-dlpack-ext",
                filtered_requirements.read_text(encoding="utf-8"),
            )

    def test_setup_stops_after_the_first_failed_command(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir))
            self.prepare_editable_tree(context)
            runner = CommandRunner()

            with patch.object(runner, "run", side_effect=[0, 3]) as run:
                configured = setup_cutedsl_environment(context, runner)

            self.assertIsNone(configured)
            self.assertEqual(run.call_count, 2)

    def test_pytest_flow_invokes_l0_harness(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(
                Path(temp_dir),
                python="/tmp/wheel_test/bin/python",
                setup_environment=False,
            )
            results = []
            runner = CommandRunner(dry_run=True, collect_result=results.append)

            run_pytest_flow(context, runner)

            self.assertEqual(len(results), 1)
            command = results[0].command
            assert command is not None
            self.assertEqual(command.name, "pytest_sm100_L0")
            self.assertIn("cutlass_cicd/pytest/run_pytest.py", command.args[1])
            self.assertEqual(command.cwd, context.workspace)
            self.assertIn("L0", command.args)
            self.assertIn(str(context.junit_report_dir), command.args)
            self.assertIn(str(context.source_dir / "test" / "examples" / "CuTeDSL"), command.args)

    def test_commands_use_workspace_and_venv_path(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(
                Path(temp_dir), python="/tmp/wheel_test/bin/python"
            )

            command = make_command(context, "example", [context.python, "example.py"])

            self.assertEqual(command.cwd, context.workspace)
            self.assertTrue(command.env["PATH"].startswith("/tmp/wheel_test/bin"))
            self.assertEqual(command.env["CUTE_DSL_ARCH"], "sm_100a")
            self.assertEqual(command.env["VENV_PYTHON_PATH"], context.python)
            python_paths = command.env["PYTHONPATH"].split(os.pathsep)
            self.assertNotIn(str(context.source_dir), python_paths)
            self.assertIn(
                str(context.source_dir / "python" / "CuTeDSL"),
                python_paths,
            )

    def test_commands_set_expected_cute_dsl_arch(self) -> None:
        expected_arches = {
            "80": "sm_80",
            "90": "sm_90a",
            "100": "sm_100a",
            "103": "sm_103a",
            "120": "sm_120a",
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            for sm, expected_arch in expected_arches.items():
                with self.subTest(sm=sm):
                    context = self.make_context(Path(temp_dir) / sm, sm=sm)
                    command = make_command(
                        context,
                        "example",
                        [context.python, "example.py"],
                    )

                    self.assertEqual(command.env["CUTE_DSL_ARCH"], expected_arch)


if __name__ == "__main__":
    unittest.main()
