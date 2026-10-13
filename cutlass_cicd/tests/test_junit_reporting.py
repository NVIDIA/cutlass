# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import io
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest.mock import DEFAULT, patch

from cutlass_cicd import test as test_entrypoint
from cutlass_cicd.common.execution import (
    CommandRunner,
    TestCommand,
    TestContext,
    TestResult,
)
from cutlass_cicd.common.reporting import JUnitReport
from cutlass_cicd.cutedsl import suites as cutedsl_suites


class JunitReportingTest(unittest.TestCase):
    def make_context(self, workspace: Path, **overrides: object) -> TestContext:
        values = {
            "source_dir": workspace.parent / "source",
            "workspace": workspace,
            "sm": "100",
            "python": "python3",
            "cuda_major": 12,
            "arch": "x86_64",
            "setup_environment": False,
        }
        values.update(overrides)
        return TestContext(**values)

    def test_report_directory_is_nested_once_under_test_outputs(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)

            regular_context = self.make_context(root / "workspace")
            output_context = self.make_context(root / "test_outputs")

            self.assertEqual(
                regular_context.junit_report_dir,
                root / "workspace" / "test_outputs" / "junit_report",
            )
            self.assertEqual(
                output_context.junit_report_dir,
                root / "test_outputs" / "junit_report",
            )

    def test_junit_report_collects_and_serializes_results(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir), dry_run=True)
            report_path = (
                Path(temp_dir)
                / "test_outputs"
                / "junit_report"
                / "L0_oss_dsl_test.xml"
            )
            command = TestCommand(
                name="passing_example",
                args=("python3", "example.py"),
                cwd=Path(temp_dir),
            )
            report = JUnitReport(testsuites_name="L0_oss_dsl_test")
            report.collect_result(
                "notebooks",
                TestResult(
                    name="passing_example",
                    returncode=0,
                    command=command,
                    duration_seconds=0.5,
                ),
            )
            report.collect_result(
                "notebooks",
                TestResult(
                    name="failing_example",
                    returncode=3,
                    command=command,
                    message="Command exited with code 3",
                    duration_seconds=0.25,
                ),
            )
            with report.testsuite_runner(
                context,
                "notebooks",
            ) as runner:
                runner.skip("skipped_example", "unsupported architecture")
                runner.waive("waived_example")
            with report.testsuite_runner(context, "empty"):
                pass

            written_path = report.write(report_path)

            self.assertEqual(written_path, report_path)
            root = ET.parse(report_path).getroot()
            self.assertEqual(root.get("name"), "L0_oss_dsl_test")
            suite = root.find("./testsuite[@name='notebooks']")
            assert suite is not None
            self.assertEqual(suite.get("tests"), "4")
            self.assertEqual(suite.get("failures"), "1")
            self.assertEqual(suite.get("skipped"), "2")
            empty_suite = root.find("./testsuite[@name='empty']")
            assert empty_suite is not None
            self.assertEqual(empty_suite.get("tests"), "0")

            testcases = {
                case.get("name"): case for case in suite.findall("testcase")
            }
            self.assertIn(
                "Command: python3 example.py",
                testcases["passing_example"].findtext("system-out"),
            )
            failure = testcases["failing_example"].find("failure")
            assert failure is not None
            self.assertEqual(failure.get("message"), "Command exited with code 3")
            self.assertEqual(
                testcases["skipped_example"].find("skipped").get("message"),
                "unsupported architecture",
            )
            self.assertEqual(
                testcases["waived_example"].find("skipped").get("message"),
                "waived",
            )

    def test_entrypoint_dispatches_single_context_argument(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            contexts = []

            def run_fake_test(context: TestContext) -> int:
                contexts.append(context)
                return 0

            with patch.dict(
                test_entrypoint.TESTS,
                {"fake_test_suite": run_fake_test},
                clear=True,
            ):
                returncode = test_entrypoint.main(
                    (
                        "-w",
                        str(root),
                        "-s",
                        str(root / "source"),
                        "--sm",
                        "100",
                        "--skip-setup",
                        "--dry-run",
                        "-t",
                        "fake_test_suite",
                    )
                )

            self.assertEqual(returncode, 0)
            self.assertEqual(len(contexts), 1)
            self.assertEqual(contexts[0].workspace, root.resolve())
            self.assertTrue(contexts[0].dry_run)

    def test_suite_writes_aggregate_report(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            context = self.make_context(root)

            def record_skip(_context: TestContext, runner: CommandRunner) -> None:
                runner.skip("fake_test", "fixture")

            with (
                patch.object(cutedsl_suites, "check_layout", return_value=True),
                patch.multiple(
                    cutedsl_suites,
                    run_pytest_flow=DEFAULT,
                    run_examples_flow=DEFAULT,
                    run_distributed_flow=DEFAULT,
                    run_notebook_flow=record_skip,
                ),
            ):
                returncode = cutedsl_suites.run_l0_oss_dsl_test(context)

            self.assertEqual(returncode, 0)
            report_path = (
                root
                / "test_outputs"
                / "junit_report"
                / "L0_oss_dsl_test.xml"
            )
            self.assertTrue(report_path.is_file())
            root_element = ET.parse(report_path).getroot()
            self.assertEqual(root_element.get("name"), "L0_oss_dsl_test")
            suite = root_element.find("./testsuite[@name='notebooks']")
            assert suite is not None
            self.assertEqual(suite.get("tests"), "1")
            self.assertEqual(suite.get("skipped"), "1")
            testcase = suite.find("testcase")
            assert testcase is not None
            self.assertEqual(testcase.get("name"), "fake_test")

    def test_suite_records_layout_failure(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            context = self.make_context(root)

            with patch.object(cutedsl_suites, "check_layout", return_value=False):
                returncode = cutedsl_suites.run_l0_oss_dsl_test(context)

            self.assertEqual(returncode, 1)
            report_path = (
                root
                / "test_outputs"
                / "junit_report"
                / "L0_oss_dsl_test.xml"
            )
            suite = ET.parse(report_path).getroot().find(
                "./testsuite[@name='setup']"
            )
            assert suite is not None
            self.assertEqual(suite.get("tests"), "1")
            self.assertEqual(suite.get("failures"), "1")
            testcase = suite.find("testcase")
            assert testcase is not None
            self.assertEqual(testcase.get("name"), "check_layout")

    def test_failed_command_stdout_and_stderr_are_in_junit(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            command = TestCommand(
                name="failing_notebook",
                args=(
                    sys.executable,
                    "-c",
                    (
                        "import sys; "
                        "print('complete stdout'); "
                        "print('complete stderr', file=sys.stderr); "
                        "raise SystemExit(7)"
                    ),
                ),
                cwd=root,
            )
            report = JUnitReport(testsuites_name="L0_oss_dsl_test")
            context = self.make_context(root)

            with (
                redirect_stdout(io.StringIO()),
                redirect_stderr(io.StringIO()),
            ):
                with report.testsuite_runner(
                    context,
                    "notebooks",
                ) as runner:
                    returncode = runner.run(command)

            self.assertEqual(returncode, 7)

            report_path = root / "report.xml"
            report.write(report_path)
            testcase = ET.parse(report_path).getroot().find(
                "./testsuite[@name='notebooks']/testcase"
            )
            assert testcase is not None
            self.assertEqual(testcase.findtext("system-out"), "complete stdout\n")
            self.assertEqual(testcase.findtext("system-err"), "complete stderr\n")

    def test_failed_output_is_safe_for_xml(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            report = JUnitReport(testsuites_name="L0_oss_dsl_test")
            report.collect_result(
                "examples",
                TestResult(
                    name="invalid_xml_output",
                    returncode=1,
                    stdout="before\x1b[31mred\x1b[0m\x00after\n",
                    stderr="bad surrogate: \ud800\n",
                ),
            )
            report_path = Path(temp_dir) / "report.xml"

            report.write(report_path)

            testcase = ET.parse(report_path).getroot().find(
                "./testsuite[@name='examples']/testcase"
            )
            assert testcase is not None
            self.assertEqual(
                testcase.findtext("system-out"),
                r"before\x1b[31mred\x1b[0m\x00after" + "\n",
            )
            self.assertEqual(
                testcase.findtext("system-err"),
                r"bad surrogate: \ud800" + "\n",
            )

    def test_timed_out_command_is_reported_as_failure(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            report = JUnitReport(testsuites_name="L0_oss_dsl_test")
            context = self.make_context(root)
            command = TestCommand(
                name="timed_out_example",
                args=(
                    sys.executable,
                    "-u",
                    "-c",
                    (
                        "import sys, time; "
                        "print('stdout before timeout', flush=True); "
                        "print('stderr before timeout', file=sys.stderr, flush=True); "
                        "time.sleep(5)"
                    ),
                ),
                cwd=root,
                timeout=0.1,
            )

            with (
                redirect_stdout(io.StringIO()),
                redirect_stderr(io.StringIO()),
                report.testsuite_runner(context, "examples") as runner,
            ):
                returncode = runner.run(command)

            self.assertEqual(returncode, 124)
            report_path = root / "report.xml"
            report.write(report_path)
            testcase = ET.parse(report_path).getroot().find(
                "./testsuite[@name='examples']/testcase"
            )
            assert testcase is not None
            failure = testcase.find("failure")
            assert failure is not None
            self.assertIn("timed out", failure.get("message", ""))

    def test_missing_executable_is_collected_as_return_code_127(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            results = []
            runner = CommandRunner(collect_result=results.append)

            returncode = runner.run(
                TestCommand(
                    name="missing_executable",
                    args=("cutlass-command-that-does-not-exist",),
                    cwd=Path(temp_dir),
                )
            )

            self.assertEqual(returncode, 127)
            self.assertEqual(results[0].returncode, 127)
            self.assertIn("No such file", results[0].message or "")

    def test_testsuite_runner_records_and_reraises_unhandled_exception(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            report = JUnitReport(testsuites_name="test_suite")
            context = self.make_context(Path(temp_dir))

            with self.assertRaisesRegex(RuntimeError, "fixture failure"):
                with report.testsuite_runner(context, "examples"):
                    raise RuntimeError("fixture failure")

            self.assertTrue(report.has_failures("examples"))

    def test_dry_run_suite_does_not_write_report(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            context = self.make_context(root, dry_run=True)
            report_path = (
                root
                / "test_outputs"
                / "junit_report"
                / "L0_oss_dsl_test.xml"
            )

            with (
                patch.object(cutedsl_suites, "check_layout", return_value=True),
                patch.multiple(
                    cutedsl_suites,
                    run_pytest_flow=DEFAULT,
                    run_examples_flow=DEFAULT,
                    run_distributed_flow=DEFAULT,
                    run_notebook_flow=DEFAULT,
                ),
            ):
                returncode = cutedsl_suites.run_l0_oss_dsl_test(context)

            self.assertEqual(returncode, 0)
            self.assertFalse(report_path.exists())


if __name__ == "__main__":
    unittest.main()
