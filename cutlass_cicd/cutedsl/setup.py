# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import os
import re
import subprocess
from dataclasses import replace
from pathlib import Path
from typing import Optional

from cutlass_cicd.common.execution import CommandRunner, TestCommand, TestContext
from cutlass_cicd.common.log import G_LOGGER


TORCH_REQUIREMENT = "torch==2.11.0"
TORCH_INDEX_URLS = {
    12: "https://download.pytorch.org/whl/cu128",
    13: "https://download.pytorch.org/whl/cu130",
}
_TORCH_C_DLPACK_EXT_LINE_RE = re.compile(
    r"(?im)^\s*torch[-_]c[-_]dlpack[-_]ext\b.*$\n?"
)


def _venv_executable(venv_dir: Path, executable: str) -> Path:
    if os.name == "nt":
        suffix = ".exe" if executable in {"python", "pip"} else ""
        return venv_dir / "Scripts" / f"{executable}{suffix}"
    return venv_dir / "bin" / executable


def _is_free_threaded_python(python: str) -> bool:
    output = subprocess.check_output(
        [
            python,
            "-c",
            "import sysconfig; "
            "print(int(bool(sysconfig.get_config_var('Py_GIL_DISABLED'))))",
        ],
        text=True,
    ).strip()
    if output not in {"0", "1"}:
        raise RuntimeError(
            f"Unexpected free-threaded Python probe output from {python}: {output!r}"
        )
    return output == "1"


def _requirements_for_python(
    requirements: Path, workspace: Path, python: str
) -> Path:
    if not _is_free_threaded_python(python):
        return requirements

    contents = requirements.read_text(encoding="utf-8")
    filtered_contents = _TORCH_C_DLPACK_EXT_LINE_RE.sub("", contents)
    if filtered_contents == contents:
        return requirements

    filtered_requirements = workspace / f".{requirements.stem}.free-threaded.txt"
    filtered_requirements.write_text(filtered_contents, encoding="utf-8")
    G_LOGGER.info(
        "Free-threaded Python: removed torch-c-dlpack-ext from %s",
        requirements.name,
    )
    return filtered_requirements


def _run_setup_command(
    runner: CommandRunner,
    *,
    name: str,
    args: list[str],
    cwd: Path,
    env: Optional[dict[str, str]] = None,
) -> bool:
    return (
        runner.run(
            TestCommand(
                name=name,
                args=args,
                cwd=cwd,
                env=env or {},
            )
        )
        == 0
    )


def setup_cutedsl_environment(
    context: TestContext, runner: CommandRunner
) -> Optional[TestContext]:
    """Create Bloom's clean test venv and install the editable CuTeDSL tree."""

    editable_root = context.source_dir / "python" / "CuTeDSL"
    pyproject = editable_root / "pyproject.toml"
    if not pyproject.is_file():
        G_LOGGER.error("Editable-install project file is missing: %s", pyproject)
        return None

    requirements_name = (
        "requirements-test-cu13.txt"
        if context.cuda_major >= 13
        else "requirements-test-cu12.txt"
    )
    requirements = Path(__file__).with_name(requirements_name)
    if not requirements.is_file():
        G_LOGGER.error("Required setup file is missing: %s", requirements)
        return None
    requirements = _requirements_for_python(
        requirements, context.workspace, context.python
    )

    editable_requirement = str(editable_root)
    if context.cuda_major >= 13:
        editable_requirement += "[cu13]"

    venv_dir = context.workspace / "wheel_test"
    venv_python = _venv_executable(venv_dir, "python")
    torch_cuda_major = 13 if context.cuda_major >= 13 else 12

    setup_steps = [
        (
            "setup_create_venv",
            [context.python, "-m", "venv", "--clear", str(venv_dir)],
            context.workspace,
        ),
        (
            "setup_upgrade_pip",
            [str(venv_python), "-m", "pip", "install", "--upgrade", "pip"],
            context.workspace,
        ),
        (
            "setup_pytorch",
            [
                str(venv_python),
                "-m",
                "pip",
                "install",
                TORCH_REQUIREMENT,
                "--index-url",
                TORCH_INDEX_URLS[torch_cuda_major],
            ],
            context.workspace,
        ),
        (
            "setup_test_requirements",
            [str(venv_python), "-m", "pip", "install", "-r", str(requirements)],
            context.workspace,
        ),
        (
            "setup_editable_install",
            [
                str(venv_python),
                "-m",
                "pip",
                "install",
                "-e",
                editable_requirement,
            ],
            context.workspace,
        ),
    ]

    for name, args, cwd in setup_steps:
        if not _run_setup_command(runner, name=name, args=args, cwd=cwd):
            G_LOGGER.error("CuTeDSL environment setup stopped after %s failed", name)
            return None

    return replace(context, python=str(venv_python))
