# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import os
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

from cutlass_cicd.common.execution import CommandRunner, TestCommand, TestContext
from cutlass_cicd.cutedsl.paths import get_example_root, join_rel_path


def base_env(context: TestContext) -> Dict[str, str]:
    env = {
        "PYTHONUNBUFFERED": "1",
        "CUTLASS_SOURCE_DIR": str(context.source_dir),
        "CUTE_DSL_ARCH": (
            f"sm_{context.sm}a"
            if context.sm in {"90", "100", "103", "120"}
            else f"sm_{context.sm}"
        ),
        "VENV_PYTHON_PATH": context.python,
    }
    python_path = str(context.source_dir / "python" / "CuTeDSL")
    existing = os.getenv("PYTHONPATH")
    python_paths = (python_path,)
    if existing:
        python_paths += (existing,)
    env["PYTHONPATH"] = os.pathsep.join(python_paths)

    python_dir = str(Path(context.python).parent)
    if python_dir not in {"", "."}:
        existing_path = os.getenv("PATH", "")
        env["PATH"] = os.pathsep.join((python_dir, existing_path))

    if context.package_dir is not None:
        packaged_cuda = context.package_dir / "third_party" / "cuda"
        if packaged_cuda.is_dir():
            env["CUDA_TOOLKIT_PATH"] = str(packaged_cuda)
    return env


def make_command(
    context: TestContext,
    name: str,
    args: Sequence[str],
    *,
    timeout: Optional[int] = None,
    env: Optional[Dict[str, str]] = None,
    cwd: Optional[Path] = None,
) -> TestCommand:
    command_env = base_env(context)
    if env:
        command_env.update(env)
    return TestCommand(
        name=name,
        args=[str(arg) for arg in args],
        cwd=cwd or context.workspace,
        env=command_env,
        timeout=timeout,
    )


def iter_file_commands(
    context: TestContext,
    tests: Iterable[Tuple[str, str, str]],
    runner: CommandRunner,
) -> Iterable[Tuple[str, List[str]]]:
    example_root = get_example_root(context.source_dir)
    for name, rel_path, executable in tests:
        test_path = join_rel_path(example_root, rel_path)
        if not test_path.exists():
            runner.skip(name, f"{test_path} does not exist")
            continue

        if executable == "python":
            args = [context.python, str(test_path)]
        elif executable == "bash":
            args = ["bash", str(test_path)]
        else:
            raise ValueError(f"Unsupported executable for {name}: {executable}")

        yield name, args
