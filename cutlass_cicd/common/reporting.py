# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import xml.etree.ElementTree as ET
from contextlib import contextmanager
from pathlib import Path
from typing import Dict, Iterator, List, Optional, Sequence

from cutlass_cicd.common.execution import CommandRunner, TestContext, TestResult
from cutlass_cicd.common.log import G_LOGGER


def _xml_safe_text(text: str) -> str:
    """Render XML 1.0-invalid characters as visible escape sequences."""
    escaped = []
    for character in text:
        codepoint = ord(character)
        if (
            codepoint in {0x09, 0x0A, 0x0D}
            or 0x20 <= codepoint <= 0xD7FF
            or 0xE000 <= codepoint <= 0xFFFD
            or 0x10000 <= codepoint <= 0x10FFFF
        ):
            escaped.append(character)
        elif codepoint <= 0xFF:
            escaped.append(f"\\x{codepoint:02x}")
        elif codepoint <= 0xFFFF:
            escaped.append(f"\\u{codepoint:04x}")
        else:
            escaped.append(f"\\U{codepoint:08x}")
    return "".join(escaped)


class JUnitReport:
    """Collect test results and serialize them as a JUnit XML report."""

    def __init__(
        self,
        *,
        testsuites_name: str = "cutlass_cicd",
    ) -> None:
        self.testsuites_name = testsuites_name
        self._results_by_testsuite: Dict[str, List[TestResult]] = {}

    def collect_result(self, testsuite_name: str, result: TestResult) -> None:
        self._results_by_testsuite.setdefault(testsuite_name, []).append(result)

    @contextmanager
    def testsuite_runner(
        self,
        context: TestContext,
        testsuite_name: str,
    ) -> Iterator[CommandRunner]:
        """Provide a runner whose results belong to one JUnit testsuite."""
        self._results_by_testsuite.setdefault(testsuite_name, [])

        def collect_result(result: TestResult) -> None:
            self.collect_result(testsuite_name, result)

        runner = CommandRunner(
            dry_run=context.dry_run,
            collect_result=collect_result,
        )
        try:
            yield runner
        except Exception as error:
            runner.fail(
                "unhandled_exception",
                f"{type(error).__name__}: {error}",
            )
            raise

    def has_failures(self, testsuite_name: Optional[str] = None) -> bool:
        if testsuite_name is not None:
            results = self._results_by_testsuite.get(testsuite_name)
            return any(result.failed for result in results or ())
        return any(
            result.failed
            for results in self._results_by_testsuite.values()
            for result in results
        )

    def exit_code(self) -> int:
        return 1 if self.has_failures() else 0

    def write(self, report_path: Path) -> Path:
        all_results = [
            result
            for results in self._results_by_testsuite.values()
            for result in results
        ]
        root = ET.Element(
            "testsuites",
            {
                "name": _xml_safe_text(self.testsuites_name),
                **self._summary_attributes(all_results),
            },
        )

        for testsuite_name, results in self._results_by_testsuite.items():
            suite = ET.SubElement(
                root,
                "testsuite",
                {
                    "name": _xml_safe_text(testsuite_name),
                    **self._summary_attributes(results),
                },
            )
            for result in results:
                testcase = ET.SubElement(
                    suite,
                    "testcase",
                    {
                        "classname": _xml_safe_text(testsuite_name),
                        "name": _xml_safe_text(result.name),
                        "time": f"{result.duration_seconds:.6f}",
                    },
                )
                self._populate_testcase(testcase, result)

        report_path.parent.mkdir(parents=True, exist_ok=True)
        tree = ET.ElementTree(root)
        indent = getattr(ET, "indent", None)
        if indent is not None:
            indent(tree, space="  ")
        tree.write(report_path, encoding="utf-8", xml_declaration=True)
        G_LOGGER.info("JUnit report: %s", report_path)
        return report_path

    @staticmethod
    def _summary_attributes(results: Sequence[TestResult]) -> Dict[str, str]:
        return {
            "tests": str(len(results)),
            "failures": str(sum(result.failed for result in results)),
            "errors": "0",
            "skipped": str(
                sum(result.skipped or result.waived for result in results)
            ),
            "time": f"{sum(result.duration_seconds for result in results):.6f}",
        }

    @classmethod
    def _populate_testcase(
        cls,
        testcase: ET.Element,
        result: TestResult,
    ) -> None:
        details = cls._result_details(result)
        if result.skipped or result.waived:
            ET.SubElement(
                testcase,
                "skipped",
                {"message": _xml_safe_text(result.message or "skipped")},
            )
        elif result.failed:
            failure = ET.SubElement(
                testcase,
                "failure",
                {
                    "message": _xml_safe_text(
                        result.message
                        or f"Command exited with code {result.returncode}"
                    ),
                    "type": "CommandFailure",
                },
            )
            failure.text = _xml_safe_text(details)
            if result.stdout is not None:
                system_out = ET.SubElement(testcase, "system-out")
                system_out.text = _xml_safe_text(result.stdout)
            if result.stderr is not None:
                system_err = ET.SubElement(testcase, "system-err")
                system_err.text = _xml_safe_text(result.stderr)
        elif details:
            system_out = ET.SubElement(testcase, "system-out")
            system_out.text = _xml_safe_text(details)

    @staticmethod
    def _result_details(result: TestResult) -> str:
        details = []
        if result.message:
            details.append(result.message)
        if result.command is not None:
            details.extend(
                (
                    f"Command: {result.command.display()}",
                    f"Working directory: {result.command.cwd}",
                    f"Return code: {result.returncode}",
                )
            )
        return "\n".join(details)
