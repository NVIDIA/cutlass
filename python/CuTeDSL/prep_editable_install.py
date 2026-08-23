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

"""
CuTeDSL Development Package Setup

This setup script downloads the nvidia-cutlass-dsl wheel and the matching
nvidia-cutlass-dsl-libs-cuXX wheel, and copies the pieces of an editable
install that are not part of this source tree: the version string, the
native cutlass._mlir package, and libcute_dsl_runtime.so.
"""

import argparse
import logging
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path
from typing import Tuple

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

PACKAGE_NAME = "nvidia-cutlass-dsl"
ARCH_TO_LINUX_TAG = {
    "x86_64": "x86_64",
    "amd64": "x86_64",
    "aarch64": "aarch64",
    "arm64": "aarch64",
}


class CutlassDSLSetupError(Exception):
    """Custom exception for setup errors."""

    pass


def download_wheel(package: str, temp_dir: Path) -> Path:
    """
    Download a wheel for `package` matching the running interpreter.

    The libs wheels are manylinux-only, so the download pins the platform
    tags explicitly; the main wheel is pure Python and ignores them.
    """
    logger.info(f"Downloading {package} wheel to {temp_dir}")
    machine = ARCH_TO_LINUX_TAG.get(platform.machine().lower())
    if machine is None:
        raise CutlassDSLSetupError(
            f"Unsupported architecture: {platform.machine()}"
        )
    python_version = f"{sys.version_info.major}{sys.version_info.minor}"
    cmd = [
        sys.executable,
        "-m",
        "pip",
        "download",
        "--no-deps",
        "--only-binary",
        ":all:",
        "--python-version",
        python_version,
        "--implementation",
        "cp",
        "--abi",
        f"cp{python_version}",
        package,
        "--dest",
        str(temp_dir),
    ]
    # The main wheel is py3-none-any; adding linux platform tags would make
    # pip reject it, so only constrain the platform for the libs packages.
    if package != PACKAGE_NAME:
        for tag in (
            f"manylinux_2_28_{machine}",
            f"manylinux2014_{machine}",
            f"manylinux_2_17_{machine}",
        ):
            cmd += ["--platform", tag]
    result = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise CutlassDSLSetupError(
            f"Failed to download {package}:\n{result.stderr.decode()}"
        )

    package_name = package.split("==")[0]
    wheel_pattern = package_name.replace("-", "_") + "-*.whl"
    wheel_files = list(temp_dir.glob(wheel_pattern))
    if not wheel_files:
        raise CutlassDSLSetupError(
            f"No wheel file matching {wheel_pattern} found after download"
        )
    wheel_path = max(wheel_files, key=lambda p: p.stat().st_mtime)
    logger.info(f"Successfully downloaded: {wheel_path.name}")
    return wheel_path


def extract_versions_from_wheel(wheel_path: Path) -> Tuple[str, str]:
    """
    Extract the release version from the wheel filename and derive the dev
    version written to VERSION.EDITABLE.

    Args:
        wheel_path: Path to the downloaded main wheel file

    Returns:
        Tuple of (release_version, dev_version). release_version is exactly
        the version in the wheel filename and is what the libs wheels are
        pinned with; dev_version appends or bumps a .dev<n> suffix.

    Raises:
        CutlassDSLSetupError: If version cannot be extracted from filename
    """
    wheel_filename = wheel_path.name
    version_regex = re.escape(PACKAGE_NAME.replace("-", "_")) + r"-([^-]+)-"
    version_match = re.match(version_regex, wheel_filename)

    if not version_match:
        raise CutlassDSLSetupError(
            f"Could not parse version from wheel filename: {wheel_filename}"
        )

    release_version = version_match.group(1)

    dev_match = re.match(r"^(.+)\.dev(\d+)$", release_version)
    if dev_match:
        dev_version = f"{dev_match.group(1)}.dev{int(dev_match.group(2)) + 1}"
        logger.info(
            f"Detected version with dev suffix: {release_version} -> using {dev_version}"
        )
    else:
        dev_version = f"{release_version}.dev0"
        logger.info(f"Detected version: {release_version} -> using {dev_version}")

    return release_version, dev_version


def extract_wheel_contents(wheel_path: Path, extract_dir: Path) -> None:
    """
    Extract wheel contents to specified directory.

    Args:
        wheel_path: Path to the wheel file
        extract_dir: Directory to extract contents to

    Raises:
        CutlassDSLSetupError: If extraction fails
    """
    logger.info(f"Extracting {wheel_path.name} to {extract_dir}")

    try:
        with zipfile.ZipFile(wheel_path, "r") as wheel_zip:
            wheel_zip.extractall(extract_dir)
    except zipfile.BadZipFile as e:
        raise CutlassDSLSetupError(f"Invalid wheel file {wheel_path}: {e}")
    except Exception as e:
        raise CutlassDSLSetupError(f"Failed to extract wheel: {e}")


def find_mlir_source(extract_dir: Path):
    """Return the dsl_packages/cutlass/_mlir directory inside an extraction."""
    source_dirs = list(extract_dir.rglob("dsl_packages/cutlass/_mlir"))
    return source_dirs[0] if source_dirs else None


def copy_mlir_package(base_extract_dir: Path, ctk_extract_dir: Path,
                      package_root: Path) -> int:
    """
    Copy the cutlass._mlir package into the local cutlass/ package directory.

    The python glue comes from nvidia-cutlass-dsl-libs-base; the native
    bindings for the selected CUDA toolkit come from nvidia-cutlass-dsl-libs-
    cuXX and are merged on top of it.

    Args:
        base_extract_dir: Extraction of the libs-base wheel
        ctk_extract_dir: Extraction of the libs-cuXX wheel
        package_root: Root directory of the package

    Returns:
        Number of files copied
    """
    base_mlir = find_mlir_source(base_extract_dir)
    if base_mlir is None:
        logger.warning(
            "No dsl_packages/cutlass/_mlir directory found in the libs-base wheel"
        )
        return 0

    mlir_dest_dir = package_root / "cutlass" / "_mlir"

    logger.info(f"Copying _mlir from {base_mlir} to {mlir_dest_dir}")
    if mlir_dest_dir.exists():
        shutil.rmtree(mlir_dest_dir)
    shutil.copytree(base_mlir, mlir_dest_dir)

    ctk_mlir = find_mlir_source(ctk_extract_dir)
    if ctk_mlir is not None:
        logger.info(f"Merging toolkit-specific files from {ctk_mlir}")
        for src_file in ctk_mlir.rglob("*"):
            if src_file.is_file():
                dest_file = mlir_dest_dir / src_file.relative_to(ctk_mlir)
                dest_file.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src_file, dest_file)
    else:
        logger.warning(
            "No dsl_packages/cutlass/_mlir directory found in the toolkit libs wheel"
        )

    copied_count = sum(1 for f in mlir_dest_dir.rglob("*") if f.is_file())
    logger.info(f"Copied {copied_count} files into cutlass/_mlir")
    return copied_count


def copy_runtime_libs(extract_dir: Path, package_root: Path) -> Tuple[int, str]:
    """
    Copy the cuXX/lib runtime libraries from the libs wheel next to the
    cutlass package, mirroring the layout of an installed wheel so the
    DSL's library discovery finds libcute_dsl_runtime.so.

    Args:
        extract_dir: Directory containing extracted libs wheel contents
        package_root: Root directory of the package

    Returns:
        Tuple of (files_copied, ctk_tag)
    """
    lib_source_dirs = sorted(extract_dir.rglob("cu1*/lib"))
    if not lib_source_dirs:
        logger.warning("No cuXX/lib directory found in the wheel")
        return 0, ""

    files_copied = 0
    tag = ""
    libs_root = extract_dir / "nvidia_cutlass_dsl"
    for lib_source_dir in lib_source_dirs:
        if libs_root not in lib_source_dir.parents:
            continue
        rel = lib_source_dir.relative_to(libs_root)
        lib_dest_dir = package_root / rel
        logger.info(f"Copying runtime libs from {lib_source_dir} to {lib_dest_dir}")
        if lib_dest_dir.exists():
            shutil.rmtree(lib_dest_dir)
        shutil.copytree(lib_source_dir, lib_dest_dir)
        files_copied += sum(1 for f in lib_dest_dir.rglob("*") if f.is_file())
        tag = rel.parts[0]

    logger.info(f"Copied {files_copied} runtime library files under {tag}/lib")
    return files_copied, tag


def remove_legacy_runtime_libs(package_root: Path) -> None:
    """
    Delete the flat lib/ directory the pre-4.7 script used to fill. The
    runtime library search checks lib/ before cuXX/lib, so a stale copy
    there would silently shadow freshly downloaded runtime libraries.
    """
    legacy_lib_dir = package_root / "lib"
    if legacy_lib_dir.is_dir():
        logger.warning(
            f"Removing stale {legacy_lib_dir} left behind by an older run; "
            "runtime libraries now live under cuXX/lib"
        )
        shutil.rmtree(legacy_lib_dir)


def copy_source_mlir_helpers(package_root: Path) -> int:
    """
    Place this tree's own _mlir_helpers sources inside the cutlass/ package,
    where their relative imports expect them.

    Args:
        package_root: Root directory of the package

    Returns:
        Number of files copied
    """
    helpers_source_dir = package_root / "_mlir_helpers"
    helpers_dest_dir = package_root / "cutlass" / "_mlir_helpers"
    if not helpers_source_dir.is_dir():
        logger.warning(f"No {helpers_source_dir} directory found")
        return 0

    logger.info(f"Copying {helpers_source_dir} to {helpers_dest_dir}")
    if helpers_dest_dir.exists():
        shutil.rmtree(helpers_dest_dir)
    shutil.copytree(helpers_source_dir, helpers_dest_dir)

    copied_count = sum(1 for f in helpers_dest_dir.rglob("*") if f.is_file())
    logger.info(f"Copied {copied_count} files into cutlass/_mlir_helpers")
    return copied_count


def write_version_file(version: str, package_root: Path) -> None:
    """
    Write version string to VERSION.EDITABLE in the package root directory.

    Args:
        version: Version string to write
        package_root: Root directory of the package
    """
    version_file = package_root / "VERSION.EDITABLE"
    logger.info(f"Writing version {version} to {version_file}")

    try:
        with open(version_file, "w", encoding="utf-8") as f:
            f.write(version + "\n")
    except Exception as e:
        raise CutlassDSLSetupError(f"Failed to write VERSION file: {e}")


def pinned_main_package() -> str:
    """
    Return the main wheel requirement exactly as requirements.txt pins it, so
    the downloaded wheel matches the release this tree corresponds to.
    """
    requirements = Path(__file__).parent / "requirements.txt"
    if requirements.exists():
        for line in requirements.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line.startswith(PACKAGE_NAME) and "==" in line:
                logger.info(f"Using pinned requirement from requirements.txt: {line}")
                return line
    return PACKAGE_NAME


def prep_editable_install(ctk_tag: str) -> None:
    """
    Set up the CuTeDSL development environment.

    Downloads the nvidia-cutlass-dsl wheel and its matching libs wheel, and
    copies everything an editable install needs beyond this source tree.

    Args:
        ctk_tag: CUDA toolkit flavor of the libs wheel, 'cu12' or 'cu13'

    Raises:
        CutlassDSLSetupError: If setup fails
    """
    package_root = Path(__file__).parent

    with tempfile.TemporaryDirectory() as temp_dir_str:
        temp_dir = Path(temp_dir_str)

        main_extract_dir = temp_dir / "main"
        main_wheel = download_wheel(pinned_main_package(), temp_dir / "main_dl")
        release_version, dev_version = extract_versions_from_wheel(main_wheel)
        extract_wheel_contents(main_wheel, main_extract_dir)

        base_extract_dir = temp_dir / "libs_base"
        base_wheel = download_wheel(
            f"{PACKAGE_NAME}-libs-base=={release_version}", temp_dir / "dl_base"
        )
        extract_wheel_contents(base_wheel, base_extract_dir)

        ctk_extract_dir = temp_dir / "libs_ctk"
        ctk_wheel = download_wheel(
            f"{PACKAGE_NAME}-libs-{ctk_tag}=={release_version}", temp_dir / "dl_ctk"
        )
        extract_wheel_contents(ctk_wheel, ctk_extract_dir)

        mlir_files_copied = copy_mlir_package(
            base_extract_dir, ctk_extract_dir, package_root
        )
        helper_files_copied = copy_source_mlir_helpers(package_root)
        remove_legacy_runtime_libs(package_root)
        lib_files_copied, detected_tag = copy_runtime_libs(
            ctk_extract_dir, package_root
        )

        flavor_so = list(
            (package_root / "cutlass" / "_mlir" / "_mlir_libs").glob(
                "_cutlass_ir.*.*.so"
            )
        )
        if mlir_files_copied == 0 or not flavor_so:
            raise CutlassDSLSetupError(
                "No toolkit-native _cutlass_ir module was extracted; the "
                "editable install will not be importable. Check that the "
                "libs wheels match the main wheel version "
                f"({release_version})."
            )

        write_version_file(dev_version, package_root)

        logger.info("Setup completed successfully!")
        logger.info(
            f"Summary: {mlir_files_copied} _mlir files, "
            f"{helper_files_copied} _mlir_helpers files, "
            f"{lib_files_copied} runtime library files ({detected_tag}/lib)"
        )
        logger.info(f"Detected upstream version: {dev_version}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cu13",
        action="store_true",
        help="Use the CUDA 13 libs wheel instead of the default CUDA 12 one",
    )
    args = parser.parse_args()
    prep_editable_install("cu13" if args.cu13 else "cu12")
