# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

from cutlass_cicd.common.execution import CommandRunner, TestContext
from cutlass_cicd.cutedsl.commands import make_command
from cutlass_cicd.cutedsl.paths import get_pytest_root


PYTEST_SKIP_EXPRESSION = "not test_binary_ops"


def run_pytest_flow(context: TestContext, runner: CommandRunner) -> None:
    if context.sm not in {"90", "100"}:
        runner.skip(f"pytest_sm{context.sm}_L0", f"No pytest flow for sm {context.sm}")
        return

    pytest_root = get_pytest_root(context.source_dir)
    harness = context.source_dir / "cutlass_cicd" / "pytest" / "run_pytest.py"
    editable_root = context.source_dir / "python" / "CuTeDSL"

    args = [
        context.python,
        str(harness),
        "--arch",
        context.sm,
        "--test-level",
        "L0",
        "--package",
        str(editable_root),
        "--workers",
        context.pytest_workers,
        "--report-path",
        str(context.junit_report_dir),
        "--test-path",
        str(pytest_root),
    ]
    if context.cuda_major == 12:
        args.extend(["-k", PYTEST_SKIP_EXPRESSION])

    runner.run(make_command(context, f"pytest_sm{context.sm}_L0", args))
