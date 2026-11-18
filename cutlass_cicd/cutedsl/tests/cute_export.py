# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import os
from typing import Dict

from cutlass_cicd.common.env import detect_cuda_home
from cutlass_cicd.common.execution import CommandRunner, TestContext
from cutlass_cicd.cutedsl.commands import iter_file_commands, make_command


CUTE_EXPORT_TESTS = (
    ("export_export_to_c", "dsl_tutorials/export/export_to_c.py", "python"),
    ("export_load_in_python", "dsl_tutorials/export/load_in_python.py", "python"),
    ("export_run_with_dynamic_loading", "dsl_tutorials/export/run_with_dynamic_loading.sh", "bash"),
    ("export_run_with_static_linking", "dsl_tutorials/export/run_with_static_linking.sh", "bash"),
)


def _missing_cuda_home_env(context: TestContext) -> Dict[str, str]:
    if os.getenv("CUDA_HOME"):
        return {}

    return {"CUDA_HOME": detect_cuda_home(context.package_dir)}


def run_cute_export_flow(context: TestContext, runner: CommandRunner) -> None:
    if context.sm not in {"80", "100"}:
        runner.skip(f"cute_export_sm{context.sm}", f"No cute_export flow for sm {context.sm}")
        return

    export_env = _missing_cuda_home_env(context)
    for name, args in iter_file_commands(context, CUTE_EXPORT_TESTS, runner):
        runner.run(make_command(context, name, args, env=export_env))
