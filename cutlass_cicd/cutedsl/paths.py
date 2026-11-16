# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import re
from pathlib import Path
from typing import Union

from cutlass_cicd.common.log import G_LOGGER


PUBLIC_EXAMPLES_REL = Path("examples") / "python" / "CuTeDSL"
PUBLIC_PYTEST_REL = Path("test") / "examples" / "CuTeDSL"


def get_example_root(source_dir: Path) -> Path:
    return source_dir / PUBLIC_EXAMPLES_REL


def get_notebook_root(source_dir: Path) -> Path:
    return get_example_root(source_dir) / "cute" / "notebooks"


def get_pytest_root(source_dir: Path) -> Path:
    return source_dir / PUBLIC_PYTEST_REL


def check_layout(source_dir: Path) -> bool:
    example_root = get_example_root(source_dir)
    missing = [
        path
        for path in (
            example_root / "dsl_tutorials",
            example_root / "cute",
            example_root / "cute_ext",
            get_pytest_root(source_dir),
        )
        if not path.is_dir()
    ]
    if missing:
        G_LOGGER.error(
            "Expected CuTeDSL public layout, but missing: "
            + ", ".join(str(path) for path in missing)
        )
        return False
    return True


def normalize_rel_path(path: Union[Path, str]) -> str:
    return str(path).replace("\\", "/")


def join_rel_path(root: Path, rel_path: str) -> Path:
    return root.joinpath(*normalize_rel_path(rel_path).split("/"))


def has_main_entrypoint(file_path: Path) -> bool:
    try:
        source = file_path.read_text(encoding="utf-8")
    except OSError as error:
        G_LOGGER.warning("Failed to read %s when checking __main__: %s", file_path, error)
        return False

    return re.search(r"""if\s+__name__\s*==\s*['"]__main__['"]\s*:""", source) is not None
