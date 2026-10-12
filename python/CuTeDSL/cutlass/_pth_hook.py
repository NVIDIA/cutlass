# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Hook script loaded by cutlass-dsl-dev.pth at Python startup.

This script sets up the editable install environment:
1. Sets CUTE_DSL_LIBS environment variable
2. Installs the custom editable finder for cutlass._mlir and legacy DSL modules

The .pth file calls setup() with paths configured during installation.
"""

from __future__ import annotations

import os
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path


def setup(
    cutlass_source_dir: str | Path,
    vendored_mlir_dir: str | Path,
    lib_so_path: str | Path,
    finder_module_path: str | Path,
    root_dir: str | Path | None = None,
    vendored_iket_parent_dir: str | Path | None = None,
) -> None:
    """Set up the editable install environment.

    This function is called by the .pth file at Python startup with paths
    configured during pip installation.

    :param cutlass_source_dir: Path to cutlass source package directory
    :param vendored_mlir_dir: Path to vendored _mlir directory
    :param lib_so_path: Path to libcute_dsl_runtime.so
    :param finder_module_path: Path to _editable_finder.py module
    :param root_dir: Path to DSL root directory (optional)
    :param vendored_iket_parent_dir: The *parent* directory of a vendored
        ``iket/`` package — i.e. the directory whose immediate child is
        ``iket/`` — typically a dedicated sibling under egg-info such as
        ``cutlass-dsl-dev.egg-info/_iket_vendor/``. Pass this parent (NOT
        ``iket/`` itself, NOT the egg-info root). When provided, the
        parent is prepended to ``sys.path`` so top-level ``import iket``
        resolves to the vendored runtime. The directory MUST NOT contain
        any other top-level package directory (e.g. ``cutlass/``);
        otherwise Python would discover a namespace portion for that
        package, which can shadow / break the real package's regular
        ``__init__.py`` resolution. Optional; omit when iket bundling is
        not wanted.
    """
    # Convert to Path objects
    cutlass_source_dir = Path(cutlass_source_dir)
    vendored_mlir_dir = Path(vendored_mlir_dir)
    lib_so_path = Path(lib_so_path)
    finder_module_path = Path(finder_module_path)
    if root_dir is not None:
        root_dir = Path(root_dir)

    # Make top-level `import iket` resolvable for editable install: the iket
    # runtime package is vendored into <egg-info>/_iket_vendor/iket/ by
    # setup.py; put its parent (`_iket_vendor/`, which contains ONLY iket/)
    # on sys.path so `iket` is importable without polluting resolution of
    # `cutlass` (which would otherwise pick up a namespace portion from any
    # sibling directory under egg-info).
    import sys as _sys

    if vendored_iket_parent_dir is not None:
        vip = str(Path(vendored_iket_parent_dir))
        if vip not in _sys.path:
            _sys.path.insert(0, vip)

    # Set CUTE_DSL_LIBS environment variable
    os.environ.setdefault("CUTE_DSL_LIBS", str(lib_so_path))

    # Load and configure the custom editable finder module
    spec = spec_from_file_location("_editable_finder", finder_module_path)
    if spec is None:
        raise ImportError(
            f"Failed to obtain module spec for '_editable_finder' at {finder_module_path}. "
            f"Ensure the file exists and is a valid Python module."
        )
    if spec.loader is None:
        raise ImportError(
            f"Failed to obtain loader for '_editable_finder' from spec at {finder_module_path}. "
            f"The module spec was created but has no loader."
        )

    finder_mod = module_from_spec(spec)
    spec.loader.exec_module(finder_mod)

    # Configure the finder's path variables
    finder_mod.CUTLASS_SOURCE_DIR = cutlass_source_dir
    finder_mod.VENDORED_MLIR_DIR = vendored_mlir_dir
    if root_dir is not None:
        finder_mod.ROOT_DIR = root_dir

    # Install the finder into sys.meta_path
    finder_mod.install()
