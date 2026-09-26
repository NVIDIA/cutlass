# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""CUTLASS C++ CTest suites."""

from __future__ import annotations

import os
import shutil
import tarfile
from pathlib import Path
from typing import Dict, Tuple

from cutlass_cicd.common.execution import TestCommand, TestContext
from cutlass_cicd.common.log import G_LOGGER
from cutlass_cicd.common.reporting import JUnitReport


_PERFORMANCE_TEST_REGEX = r"ctest_performance_*|ctpp_*"
_EXAMPLE_TEST_REGEX = r"ctest_example_*"


def _test_environment(package_dir: Path) -> Dict[str, str]:
    package_dir = package_dir.resolve()
    path_entries = (
        package_dir / "bin",
        package_dir / "test" / "cutlass" / "bin",
    )
    library_entries = (
        package_dir / "lib64",
        package_dir / "lib",
        package_dir / "test" / "cutlass" / "lib64",
        package_dir / "test" / "cutlass" / "lib",
    )
    if os.name == "nt":
        windows_path_entries = (
            package_dir / "bin",
            package_dir / "lib64",
            package_dir / "lib",
            package_dir / "test" / "cutlass" / "bin",
            package_dir / "test" / "cutlass" / "lib64",
            package_dir / "test" / "cutlass" / "lib",
        )
        return {
            "PATH": os.pathsep.join(
                [
                    *(str(path) for path in windows_path_entries),
                    os.environ.get("PATH", "."),
                ]
            )
        }

    return {
        "PATH": os.pathsep.join(
            [*(str(path) for path in path_entries), os.environ.get("PATH", ".")]
        ),
        "LD_LIBRARY_PATH": os.pathsep.join(
            [
                *(str(path) for path in library_entries),
                os.environ.get("LD_LIBRARY_PATH", "."),
            ]
        ),
    }


def _ctest_base_args(context: TestContext) -> Tuple[str, ...]:
    return (
        "ctest",
        "-T",
        "Test",
        "-V",
        "--no-compress-output",
        "--test-output-size-passed",
        "1000000",
        "--test-output-size-failed",
        "1000000",
        "--timeout",
        str(context.ctest_timeout),
        "-j",
        str(context.ctest_parallelism),
    )


def l0_functional_commands(context: TestContext) -> Tuple[TestCommand, ...]:
    if context.package_dir is None:
        raise ValueError("L0_functional requires an extracted CUTLASS package")

    package_dir = context.package_dir
    test_dir = package_dir / "test" / "cutlass"
    environment = _test_environment(package_dir)
    base_args = _ctest_base_args(context)
    examples_junit = context.junit_report_dir / "L0_functional_junit.xml"
    performance_exclusions = f"({_PERFORMANCE_TEST_REGEX})"
    non_example_exclusions = f"({_PERFORMANCE_TEST_REGEX}|{_EXAMPLE_TEST_REGEX})"

    return (
        TestCommand(
            name="ctest_l0_example_tests",
            args=(
                *base_args,
                "-R",
                "(test_example)",
                "-E",
                performance_exclusions,
                "--output-junit",
                str(examples_junit),
            ),
            cwd=test_dir,
            env=environment,
        ),
        TestCommand(
            name="ctest_l0_non_example_tests",
            args=(*base_args, "-E", non_example_exclusions),
            cwd=test_dir,
            env=environment,
        ),
        TestCommand(
            name="ctest_l0_tmem_alloc_tracking_tests",
            args=(*base_args, "-E", non_example_exclusions),
            cwd=test_dir,
            env={**environment, "CUTLASS_TEST_SETS": "tmem_alloc_tracking"},
        ),
    )


def _move_native_junit_files(context: TestContext) -> None:
    if context.package_dir is None:
        return
    native_report_dir = context.package_dir / "test" / "cutlass" / "bin"
    if not native_report_dir.is_dir():
        return
    context.junit_report_dir.mkdir(parents=True, exist_ok=True)
    for report_path in native_report_dir.glob("*.xml"):
        shutil.move(str(report_path), context.junit_report_dir / report_path.name)


def _archive_test_outputs(context: TestContext) -> None:
    archive_path = Path.cwd() / "test_outputs.tgz"
    with tarfile.open(archive_path, mode="w:gz") as archive:
        archive.add(context.test_outputs_dir, arcname="test_outputs")
    G_LOGGER.info("Test output archive: %s", archive_path)


def run_l0_functional(context: TestContext) -> int:
    report = JUnitReport(testsuites_name="L0_functional")

    try:
        with report.testsuite_runner(context, "ctest") as runner:
            if context.package_dir is None:
                runner.fail(
                    "check_package",
                    "L0_functional requires an extracted CUTLASS package",
                )
                return 1

            if not context.dry_run:
                context.junit_report_dir.mkdir(parents=True, exist_ok=True)
            for command in l0_functional_commands(context):
                runner.run(command)

        return report.exit_code()
    finally:
        if not context.dry_run:
            _move_native_junit_files(context)
            report.write(context.junit_report_dir / "L0_functional.xml")
            _archive_test_outputs(context)
