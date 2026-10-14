# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import os
from pathlib import Path
from typing import List

from cutlass_cicd.common.execution import CommandRunner, TestContext
from cutlass_cicd.common.log import G_LOGGER
from cutlass_cicd.cutedsl.commands import make_command
from cutlass_cicd.cutedsl.paths import get_notebook_root, normalize_rel_path


NOTEBOOK_SKIP_TESTS_BY_SM = {
    "tour_to_sol_gemm": {"80", "90", "103", "120"},
    "async_pipeline": {"80"},
}


def collect_notebook_tests(notebook_dir: Path) -> List[Path]:
    if not notebook_dir.is_dir():
        G_LOGGER.warning("Notebook dir %s does not exist", notebook_dir)
        return []

    notebooks = []
    for root, _, files in os.walk(notebook_dir):
        for file_name in sorted(files):
            if file_name.endswith(".ipynb") and not file_name.startswith("_"):
                notebooks.append(Path(root) / file_name)
    return sorted(notebooks)


def parse_notebook_name(file_path: Path, notebook_root: Path) -> str:
    rel_path = normalize_rel_path(file_path.relative_to(notebook_root))
    return rel_path.replace(".ipynb", "").replace("/", "_")


def run_notebook_flow(context: TestContext, runner: CommandRunner) -> None:
    if context.arch == "aarch64":
        runner.skip(f"notebooks_sm{context.sm}", "Notebook tests are skipped on aarch64")
        return

    notebook_root = get_notebook_root(context.source_dir)
    notebooks = collect_notebook_tests(notebook_root)
    if not notebooks:
        runner.skip(f"notebooks_sm{context.sm}", "No notebooks collected")
        return

    for notebook_path in notebooks:
        notebook_name = parse_notebook_name(notebook_path, notebook_root)
        if context.sm in NOTEBOOK_SKIP_TESTS_BY_SM.get(notebook_name, set()):
            runner.waive(notebook_name)
            continue

        args = ["jupyter", "nbconvert", "--to", "notebook", "--execute", str(notebook_path)]
        runner.run(make_command(context, notebook_name, args, timeout=600))
