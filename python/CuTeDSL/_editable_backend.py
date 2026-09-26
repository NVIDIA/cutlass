# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary

"""PEP 660 backend that assembles CuTeDSL's split packages with symlinks."""

from __future__ import annotations

import base64
import csv
import hashlib
import io
import os
import shutil
import sysconfig
import zipfile
from pathlib import Path

from setuptools import build_meta as _setuptools


_PROJECT_ROOT = Path(__file__).resolve().parent
_SOURCE_PACKAGE = _PROJECT_ROOT / "cutlass"
_RUNTIME_PORTIONS = ("_mlir", "_mlir_helpers")
_CUDA_FLAVORS = ("cu12", "cu13")
_OVERLAY_PTH = "00_nvidia_cutlass_dsl_editable_overlay.pth"
_EDITABLE_FINDER = "_nvidia_cutlass_dsl_editable_finder.py"
_EDITABLE_ONLY_ERROR = (
    "CuTeDSL editable_backend supports only: python -m pip install -e ."
)


def _read_exact_requirement_version(path: Path, requirement: str) -> str:
    prefix = f"{requirement}=="
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.partition("#")[0].strip()
        if line.startswith(prefix):
            version = line.removeprefix(prefix).strip()
            if version:
                return version
    raise RuntimeError(f"{path} must contain an exact {requirement}==VERSION pin")


EDITABLE_VERSION = _read_exact_requirement_version(
    _PROJECT_ROOT / "requirements.txt", "nvidia-cutlass-dsl"
)
_CU13_VERSION = _read_exact_requirement_version(
    _PROJECT_ROOT / "requirements-cu13.txt", "nvidia-cutlass-dsl[cu13]"
)
if _CU13_VERSION != EDITABLE_VERSION:
    raise RuntimeError(
        "CuTeDSL requirements version mismatch: "
        f"requirements.txt pins {EDITABLE_VERSION}, but requirements-cu13.txt "
        f"pins {_CU13_VERSION}"
    )


def _symlink(source: Path, destination: Path, *, is_directory: bool) -> None:
    try:
        destination.symlink_to(source, target_is_directory=is_directory)
    except OSError as error:
        raise RuntimeError(
            "CuTeDSL editable installation requires filesystem symlink support: "
            f"could not link {destination} to {source}: {error}"
        ) from error


def _create_editable_overlay() -> Path:
    """Create one merged package tree for the local core and installed runtimes."""
    purelib = Path(sysconfig.get_path("purelib")).resolve()
    environment_id = hashlib.sha256(str(purelib).encode()).hexdigest()[:12]
    overlay_root = _PROJECT_ROOT / "build" / f"editable-{environment_id}"
    if overlay_root.exists():
        shutil.rmtree(overlay_root)

    namespace_root = overlay_root / "nvidia_cutlass_dsl"
    dsl_packages = namespace_root / "dsl_packages"
    cutlass_package = dsl_packages / "cutlass"
    cutlass_package.mkdir(parents=True)

    for source in sorted(_SOURCE_PACKAGE.iterdir()):
        if source.name in _RUNTIME_PORTIONS or source.name == "__pycache__":
            continue
        _symlink(source, cutlass_package / source.name, is_directory=source.is_dir())

    installed_namespace = purelib / "nvidia_cutlass_dsl"
    installed_dsl_packages = installed_namespace / "dsl_packages"
    installed_cutlass = installed_dsl_packages / "cutlass"

    # These targets are intentionally allowed to be dangling while the editable
    # wheel is built: pip installs the declared runtime dependencies immediately
    # after building the local core wheel.
    for portion in _RUNTIME_PORTIONS:
        _symlink(
            installed_cutlass / portion,
            cutlass_package / portion,
            is_directory=True,
        )

    _symlink(
        installed_dsl_packages / "iket",
        dsl_packages / "iket",
        is_directory=True,
    )
    for flavor in _CUDA_FLAVORS:
        _symlink(
            installed_namespace / flavor,
            namespace_root / flavor,
            is_directory=True,
        )

    return dsl_packages


def _record_hash(data: bytes) -> str:
    digest = base64.urlsafe_b64encode(hashlib.sha256(data).digest())
    return "sha256=" + digest.rstrip(b"=").decode("ascii")


def _editable_finder_data(overlay_path: Path) -> bytes:
    cutlass_package = str(overlay_path / "cutlass")
    return (
        '"""Import the editable cutlass package from its merged link tree."""\n\n'
        "import importlib.util\n"
        "import os\n"
        "import sys\n\n"
        f"_CUTLASS_PACKAGE = {cutlass_package!r}\n\n"
        "class _CutlassEditableFinder:\n"
        "    def find_spec(self, fullname, path=None, target=None):\n"
        '        if fullname != "cutlass":\n'
        "            return None\n"
        "        return importlib.util.spec_from_file_location(\n"
        "            fullname,\n"
        '            os.path.join(_CUTLASS_PACKAGE, "__init__.py"),\n'
        "            submodule_search_locations=[_CUTLASS_PACKAGE],\n"
        "        )\n\n"
        "sys.meta_path.insert(0, _CutlassEditableFinder())\n"
    ).encode()


def _inject_overlay_path(wheel_path: Path, overlay_path: Path) -> None:
    """Install a narrow cutlass finder for the merged overlay and update RECORD."""
    finder_module = _EDITABLE_FINDER.removesuffix(".py")
    pth_data = (f"import {finder_module}" + os.linesep).encode()
    finder_data = _editable_finder_data(overlay_path)
    injected_files = {
        _OVERLAY_PTH: pth_data,
        _EDITABLE_FINDER: finder_data,
    }
    temporary_wheel = wheel_path.with_name(wheel_path.name + ".tmp")

    with zipfile.ZipFile(wheel_path, "r") as source_wheel:
        entries = [
            (info, source_wheel.read(info.filename))
            for info in source_wheel.infolist()
            if info.filename not in injected_files
        ]

    record_name = next(
        info.filename
        for info, _ in entries
        if info.filename.endswith(".dist-info/RECORD")
    )
    record_data = next(data for info, data in entries if info.filename == record_name)
    record_rows = [
        row
        for row in csv.reader(io.StringIO(record_data.decode()))
        if row and row[0] not in injected_files
    ]
    for filename, data in injected_files.items():
        record_rows.append([filename, _record_hash(data), str(len(data))])

    record_output = io.StringIO(newline="")
    csv.writer(record_output, lineterminator="\n").writerows(record_rows)
    updated_record = record_output.getvalue().encode()

    with zipfile.ZipFile(temporary_wheel, "w") as output_wheel:
        for info, data in entries:
            output_wheel.writestr(
                info,
                updated_record if info.filename == record_name else data,
            )
        for filename, data in injected_files.items():
            output_wheel.writestr(
                filename,
                data,
                compress_type=zipfile.ZIP_DEFLATED,
            )

    os.replace(temporary_wheel, wheel_path)


def build_editable(
    wheel_directory: str,
    config_settings: dict[str, object] | None = None,
    metadata_directory: str | None = None,
) -> str:
    overlay_path = _create_editable_overlay()
    wheel_name = _setuptools.build_editable(
        wheel_directory,
        config_settings=config_settings,
        metadata_directory=metadata_directory,
    )
    _inject_overlay_path(Path(wheel_directory) / wheel_name, overlay_path)
    return wheel_name


def build_wheel(
    wheel_directory: str,
    config_settings: dict[str, object] | None = None,
    metadata_directory: str | None = None,
) -> str:
    raise RuntimeError(_EDITABLE_ONLY_ERROR)


def build_sdist(
    sdist_directory: str,
    config_settings: dict[str, object] | None = None,
) -> str:
    raise RuntimeError(_EDITABLE_ONLY_ERROR)


get_requires_for_build_wheel = _setuptools.get_requires_for_build_wheel
get_requires_for_build_sdist = _setuptools.get_requires_for_build_sdist
prepare_metadata_for_build_wheel = _setuptools.prepare_metadata_for_build_wheel
get_requires_for_build_editable = _setuptools.get_requires_for_build_editable
prepare_metadata_for_build_editable = _setuptools.prepare_metadata_for_build_editable
