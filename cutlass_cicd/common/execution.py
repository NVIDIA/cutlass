# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import os
import shlex
import signal
import subprocess
import sys
import tempfile
import threading
import time
from contextlib import ExitStack
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Mapping, Optional, Sequence, TextIO

from cutlass_cicd.common.log import G_LOGGER


# Keep typical command output in memory, then roll unusually verbose output to
# disk so successful tests do not retain an unbounded in-memory buffer.
_OUTPUT_SPOOL_MAX_SIZE = 8 * 1024 * 1024


@dataclass(frozen=True)
class TestContext:
    source_dir: Path
    workspace: Path
    sm: str
    python: str
    cuda_major: int
    arch: str
    package_dir: Optional[Path] = None
    setup_environment: bool = True
    pytest_workers: str = "8"
    dry_run: bool = False
    ctest_timeout: int = 7200
    ctest_parallelism: int = 6

    @property
    def test_outputs_dir(self) -> Path:
        """Return the common directory for externally consumed test artifacts."""
        if self.workspace.name == "test_outputs":
            return self.workspace
        return self.workspace / "test_outputs"

    @property
    def junit_report_dir(self) -> Path:
        return self.test_outputs_dir / "junit_report"


@dataclass(frozen=True)
class TestCommand:
    name: str
    args: Sequence[str]
    cwd: Path
    env: Mapping[str, str] = field(default_factory=dict)
    timeout: Optional[int] = None

    def display(self) -> str:
        return shlex.join(str(arg) for arg in self.args)


@dataclass(frozen=True)
class TestResult:
    name: str
    returncode: int
    command: Optional[TestCommand] = None
    skipped: bool = False
    waived: bool = False
    message: Optional[str] = None
    duration_seconds: float = 0.0
    stdout: Optional[str] = None
    stderr: Optional[str] = None

    @property
    def failed(self) -> bool:
        return not self.skipped and not self.waived and self.returncode != 0


class CommandRunner:
    def __init__(
        self,
        *,
        dry_run: bool = False,
        collect_result: Optional[Callable[[TestResult], None]] = None,
    ) -> None:
        self.dry_run = dry_run
        self._collect_result = collect_result

    def skip(self, name: str, reason: str) -> None:
        G_LOGGER.info("&&&& SKIPPED %s: %s", name, reason)
        self._emit_result(
            TestResult(
                name=name,
                returncode=0,
                skipped=True,
                message=reason,
            )
        )

    def waive(self, name: str) -> None:
        G_LOGGER.info("&&&& WAIVED %s", name)
        self._emit_result(
            TestResult(
                name=name,
                returncode=0,
                waived=True,
                message="waived",
            )
        )

    def fail(self, name: str, message: str, *, returncode: int = 1) -> None:
        G_LOGGER.error("&&&& FAILED %s: %s", name, message)
        self._emit_result(
            TestResult(
                name=name,
                returncode=returncode,
                message=message,
            )
        )

    def run(self, command: TestCommand) -> int:
        G_LOGGER.info("&&&& RUNNING %s", command.name)
        G_LOGGER.info("Test command: %s", command.display())

        if self.dry_run:
            G_LOGGER.info("&&&& PASSED %s (dry run)", command.name)
            result = TestResult(
                name=command.name,
                returncode=0,
                command=command,
            )
            self._emit_result(result)
            return result.returncode

        env = os.environ.copy()
        env.update(command.env)
        start_time = time.monotonic()
        message = None
        stdout = None
        stderr = None

        with ExitStack() as capture_stack:
            stdout_capture = capture_stack.enter_context(
                tempfile.SpooledTemporaryFile(
                    mode="w+",
                    max_size=_OUTPUT_SPOOL_MAX_SIZE,
                    encoding="utf-8",
                    errors="replace",
                )
            )
            stderr_capture = capture_stack.enter_context(
                tempfile.SpooledTemporaryFile(
                    mode="w+",
                    max_size=_OUTPUT_SPOOL_MAX_SIZE,
                    encoding="utf-8",
                    errors="replace",
                )
            )
            try:
                with subprocess.Popen(
                    [str(arg) for arg in command.args],
                    cwd=command.cwd,
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    errors="replace",
                    start_new_session=os.name == "posix",
                ) as process:
                    assert process.stdout is not None
                    assert process.stderr is not None
                    output_threads = (
                        self._start_output_thread(
                            process.stdout,
                            sys.stdout,
                            stdout_capture,
                        ),
                        self._start_output_thread(
                            process.stderr,
                            sys.stderr,
                            stderr_capture,
                        ),
                    )
                    try:
                        returncode = process.wait(timeout=command.timeout)
                    except subprocess.TimeoutExpired:
                        G_LOGGER.error(
                            "Command timed out after %s seconds",
                            command.timeout,
                        )
                        self._kill_process(process)
                        process.wait()
                        returncode = 124
                        message = (
                            f"Command timed out after {command.timeout} seconds"
                        )
                    except BaseException:
                        self._kill_process(process)
                        process.wait()
                        raise
                    finally:
                        for output_thread in output_threads:
                            output_thread.join()
            except FileNotFoundError as error:
                G_LOGGER.error("Command failed to start: %s", error)
                returncode = 127
                message = str(error)

            if returncode != 0:
                stdout = self._read_capture(stdout_capture) or None
                stderr = self._read_capture(stderr_capture) or None

        duration_seconds = time.monotonic() - start_time

        if returncode == 0:
            G_LOGGER.info("&&&& PASSED %s", command.name)
        else:
            G_LOGGER.error("&&&& FAILED %s", command.name)
            if message is None:
                message = f"Command exited with code {returncode}"

        self._emit_result(
            TestResult(
                name=command.name,
                returncode=returncode,
                command=command,
                message=message,
                duration_seconds=duration_seconds,
                stdout=stdout if returncode != 0 else None,
                stderr=stderr if returncode != 0 else None,
            )
        )
        return returncode

    def _emit_result(self, result: TestResult) -> None:
        if self._collect_result is not None:
            self._collect_result(result)

    @staticmethod
    def _start_output_thread(
        source: TextIO,
        destination: TextIO,
        capture: TextIO,
    ) -> threading.Thread:
        output_thread = threading.Thread(
            target=CommandRunner._tee_output,
            args=(source, destination, capture),
            daemon=True,
        )
        output_thread.start()
        return output_thread

    @staticmethod
    def _kill_process(process: subprocess.Popen) -> None:
        if os.name == "posix":
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
        else:
            process.kill()

    @staticmethod
    def _tee_output(
        source: TextIO,
        destination: TextIO,
        capture: TextIO,
    ) -> None:
        while True:
            chunk = source.readline(8192)
            if not chunk:
                return
            capture.write(chunk)
            try:
                destination.write(chunk)
                destination.flush()
            except (OSError, ValueError):
                pass

    @staticmethod
    def _read_capture(capture: TextIO) -> str:
        capture.flush()
        capture.seek(0)
        return capture.read()
