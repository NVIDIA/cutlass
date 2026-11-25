# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary

"""Tests for the CuTeDSL PEP 660 editable overlay."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from types import ModuleType, SimpleNamespace
from unittest.mock import patch


def _load_editable_backend():
    project_root = Path(__file__).parents[2] / "python" / "CuTeDSL"
    backend_path = project_root / "_editable_backend.py"
    spec = importlib.util.spec_from_file_location(
        "cutedsl_editable_backend", backend_path
    )
    assert spec is not None and spec.loader is not None
    backend = importlib.util.module_from_spec(spec)

    # Overlay creation does not depend on setuptools. Stub the build hooks so
    # this unit test does not require the PEP 517 build dependency at runtime.
    def unused_hook(*_args, **_kwargs):
        return None

    build_meta = SimpleNamespace(
        build_editable=unused_hook,
        get_requires_for_build_wheel=unused_hook,
        get_requires_for_build_sdist=unused_hook,
        prepare_metadata_for_build_wheel=unused_hook,
        get_requires_for_build_editable=unused_hook,
        prepare_metadata_for_build_editable=unused_hook,
    )
    setuptools = ModuleType("setuptools")
    setuptools.build_meta = build_meta
    with patch.dict(sys.modules, {"setuptools": setuptools}):
        spec.loader.exec_module(backend)
    return backend


def test_overlay_uses_repo_helpers_and_installed_runtime(tmp_path, monkeypatch):
    backend = _load_editable_backend()

    project_root = tmp_path / "project"
    source_package = project_root / "cutlass"
    local_helpers = project_root / "_mlir_helpers"
    source_package.mkdir(parents=True)
    local_helpers.mkdir()
    (source_package / "__init__.py").write_text(
        '__version__ = "@CUTLASS_IR_WHEEL_RELEASE_VERSION@"\n',
        encoding="utf-8",
    )
    (source_package / "local_module.py").touch()
    (local_helpers / "vector.py").touch()

    platlib = tmp_path / "platlib"
    installed_namespace = platlib / "nvidia_cutlass_dsl"
    installed_dsl_packages = installed_namespace / "dsl_packages"
    installed_cutlass = installed_dsl_packages / "cutlass"
    installed_mlir = installed_cutlass / "_mlir"
    installed_helpers = installed_cutlass / "_mlir_helpers"
    installed_iket = installed_dsl_packages / "iket"
    installed_mlir.mkdir(parents=True)
    installed_helpers.mkdir()
    installed_iket.mkdir()
    (installed_mlir / "ir.py").touch()
    (installed_helpers / "published.py").touch()
    (installed_iket / "__init__.py").touch()
    for flavor in backend._CUDA_FLAVORS:
        (installed_namespace / flavor).mkdir(parents=True)

    monkeypatch.setattr(backend, "_PROJECT_ROOT", project_root)
    monkeypatch.setattr(backend, "_SOURCE_PACKAGE", source_package)

    def get_path(name):
        assert name == "platlib"
        return str(platlib)

    monkeypatch.setattr(backend.sysconfig, "get_path", get_path)

    dsl_packages = backend._create_editable_overlay()
    overlay_cutlass = dsl_packages / "cutlass"
    overlay_namespace = dsl_packages.parent

    overlay_init = overlay_cutlass / "__init__.py"
    assert overlay_init.is_file()
    assert not overlay_init.is_symlink()
    assert (overlay_cutlass / "local_module.py").resolve() == (
        source_package / "local_module.py"
    )
    assert (overlay_cutlass / "_mlir_helpers").resolve() == local_helpers
    assert (overlay_cutlass / "_mlir").resolve() == installed_mlir
    assert (dsl_packages / "iket").resolve() == installed_iket
    for flavor in backend._CUDA_FLAVORS:
        assert (overlay_namespace / flavor).resolve() == (
            installed_namespace / flavor
        )

    assert not (overlay_cutlass / "__pycache__").exists()
    assert not (overlay_cutlass / "_mlir_helpers" / "published.py").exists()


def test_editable_init_uses_editable_version(tmp_path):
    backend = _load_editable_backend()
    assert backend.EDITABLE_VERSION == f"{backend._RUNTIME_VERSION}+editable"

    source = tmp_path / "source-init.py"
    destination = tmp_path / "editable-init.py"
    source.write_bytes(
        b'before = True\n__version__ = "'
        + backend._VERSION_PLACEHOLDER
        + b'"\nafter = True\n'
    )

    backend._write_editable_init(source, destination)

    expected = source.read_bytes().replace(
        backend._VERSION_PLACEHOLDER,
        backend.EDITABLE_VERSION.encode("ascii"),
    )
    assert destination.read_bytes() == expected
    assert source.read_bytes().count(backend._VERSION_PLACEHOLDER) == 1
