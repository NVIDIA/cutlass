#!/usr/bin/env python3
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""CUTLASS public CI test entry point."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Callable, Dict, Optional, Sequence


if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from cutlass_cicd.common.env import default_arch, detect_cuda_major
from cutlass_cicd.common.execution import TestContext
from cutlass_cicd.common.log import G_LOGGER
from cutlass_cicd.cutlass_cpp import run_l0_functional
from cutlass_cicd.cutedsl import run_l0_oss_dsl_test


TESTS: Dict[str, Callable[[TestContext], int]] = {
    "L0_functional": run_l0_functional,
    "L0_oss_dsl_test": run_l0_oss_dsl_test,
}


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    repo_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description="Entrypoint for CUTLASS public tests.")
    parser.add_argument(
        "-w",
        "--workspace",
        default=str(repo_root / "test_outputs"),
        help="Directory to use for test outputs and temporary files.",
    )
    parser.add_argument(
        "-s",
        "--source-dir",
        default=str(repo_root),
        help="Path to the CUTLASS source directory.",
    )
    parser.add_argument(
        "-p",
        "--package-dir",
        default=None,
        help="Extracted CUTLASS package directory; used to locate a packaged CUDA toolkit.",
    )
    parser.add_argument(
        "--sm",
        default=None,
        help="SM to test, for example 80, 90, 100, 103, or 120.",
    )
    parser.add_argument(
        "-t",
        "--test",
        default="L0_oss_dsl_test",
        help="Test list to run.",
    )
    parser.add_argument("--list-test", action="store_true", help="List available tests and exit.")
    parser.add_argument("--test-spec", help=argparse.SUPPRESS)
    parser.add_argument("--scm-properties", help=argparse.SUPPRESS)
    parser.add_argument(
        "--cuda-major",
        type=int,
        default=None,
        help=(
            "CUDA major version for version-specific setup and skips. "
            "Defaults to environment detection, then CUDA 13."
        ),
    )
    parser.add_argument(
        "--python",
        default=sys.executable,
        help="Python executable used to create the clean test environment.",
    )
    parser.add_argument(
        "--skip-setup",
        action="store_true",
        help="Use --python as-is instead of creating the clean editable-test environment.",
    )
    parser.add_argument(
        "--pytest-workers",
        default="8",
        help="Number of pytest-xdist workers used by the migrated pytest harness.",
    )
    parser.add_argument(
        "--ctest-timeout",
        type=int,
        default=7200,
        help="Per-test CTest timeout in seconds.",
    )
    parser.add_argument(
        "--ctest-parallelism",
        type=int,
        default=6,
        help="Number of tests CTest may run concurrently.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print test commands without executing them.",
    )
    return parser.parse_args(argv)


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = parse_args(argv)

    if args.list_test:
        G_LOGGER.info(", ".join(sorted(TESTS)))
        return 0

    if args.test not in TESTS:
        G_LOGGER.error("Unknown test list: %s", args.test)
        G_LOGGER.error("Available tests: %s", ", ".join(sorted(TESTS)))
        return 2

    if not args.sm:
        G_LOGGER.error("--sm is required unless --list-test is specified.")
        return 2

    source_dir = Path(args.source_dir).resolve()
    workspace = Path(args.workspace).resolve()
    package_dir = Path(args.package_dir).resolve() if args.package_dir else source_dir
    if not args.dry_run:
        workspace.mkdir(parents=True, exist_ok=True)

    context = TestContext(
        source_dir=source_dir,
        workspace=workspace,
        sm=str(args.sm),
        python=args.python,
        cuda_major=args.cuda_major if args.cuda_major is not None else detect_cuda_major(),
        arch=default_arch(),
        package_dir=package_dir,
        setup_environment=not args.skip_setup,
        pytest_workers=str(args.pytest_workers),
        ctest_timeout=args.ctest_timeout,
        ctest_parallelism=args.ctest_parallelism,
        dry_run=args.dry_run,
    )

    return TESTS[args.test](context)


if __name__ == "__main__":
    sys.exit(main())
