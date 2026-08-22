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

This setup script automatically downloads the nvidia-cutlass-dsl wheel,
extracts required libraries and Python packages, and sets up the development
environment for CuTeDSL.
"""

import argparse
import subprocess
import sys
import shutil
import tempfile
import zipfile
import re
from email.parser import Parser
from pathlib import Path
from typing import List, Optional, Tuple
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

# Constants
PACKAGE_NAME = "nvidia-cutlass-dsl"
# Starting with 4.4.0, the nvidia-cutlass-dsl wheel on PyPI is a metadata-only
# shim: the runtime libraries and python packages moved to per-platform wheels
# (nvidia-cutlass-dsl-libs-base/-core/-cu12/-cu13) referenced via Requires-Dist.
SPLIT_PACKAGE_PREFIX = f"{PACKAGE_NAME}-libs-"
DEFAULT_CUDA_VARIANT = "cu12"
# Directory names that carry the bundled cutlass python package inside the
# wheel(s): pre-split wheels use python_packages/, split wheels dsl_packages/.
PYTHON_PACKAGE_DIR_NAMES = ("python_packages", "dsl_packages")


class CutlassDSLSetupError(Exception):
    """Custom exception for setup errors."""

    pass


def _normalize_name(name: str) -> str:
    """Normalize a distribution name per PEP 503 for comparison."""
    return re.sub(r"[-_.]+", "-", name).lower()


def _download_one_wheel(requirement: str, temp_dir: Path) -> Path:
    """
    Download a single wheel (without dependencies) to a temporary directory.

    Args:
        requirement: Requirement string to download, e.g. 'pkg' or 'pkg==1.0'
        temp_dir: Temporary directory path for downloading

    Returns:
        Path to the downloaded wheel file

    Raises:
        CutlassDSLSetupError: If download fails or wheel not found
    """
    logger.info(f"Downloading {requirement} wheel to {temp_dir}")

    try:
        subprocess.check_call(
            [
                sys.executable,
                "-m",
                "pip",
                "download",
                "--no-deps",
                requirement,
                "--dest",
                str(temp_dir),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as e:
        error_msg = f"Failed to download {requirement}: {e}"
        if e.stdout:
            error_msg += f"\nstdout: {e.stdout.decode()}"
        if e.stderr:
            error_msg += f"\nstderr: {e.stderr.decode()}"
        if _normalize_name(requirement).startswith(SPLIT_PACKAGE_PREFIX):
            error_msg += (
                f"\nNo {requirement} wheel matches this Python interpreter or "
                "platform; check the available wheels at "
                f"https://pypi.org/project/{requirement.split('==')[0]}/#files"
            )
        raise CutlassDSLSetupError(error_msg)

    # Find the downloaded wheel file
    package_name = re.split(r"[=<>!~;\[\s]", requirement, maxsplit=1)[0]
    wheel_pattern = f"{package_name.replace('-', '_')}-*.whl"
    wheel_files = sorted(temp_dir.glob(wheel_pattern))
    if not wheel_files:
        raise CutlassDSLSetupError(
            f"No wheel file matching {wheel_pattern} found after download"
        )

    wheel_path = wheel_files[0]
    logger.info(f"Successfully downloaded: {wheel_path.name}")
    return wheel_path


def _wheel_requirements(wheel_path: Path) -> List[str]:
    """Read the Requires-Dist entries from a wheel's METADATA file."""
    with zipfile.ZipFile(wheel_path, "r") as wheel_zip:
        metadata_names = [
            n
            for n in wheel_zip.namelist()
            if re.fullmatch(r"[^/]+\.dist-info/METADATA", n)
        ]
        if not metadata_names:
            return []
        metadata_text = wheel_zip.read(metadata_names[0]).decode(
            "utf-8", errors="replace"
        )
    metadata = Parser().parsestr(metadata_text, headersonly=True)
    return metadata.get_all("Requires-Dist") or []


def _wheel_has_payload(wheel_path: Path) -> bool:
    """
    Check whether a wheel carries any content this script extracts:
    lib/*.so runtime libraries or a bundled cutlass python package.
    Metadata-only shim wheels (PyPI layout since 4.4.0) contain neither.
    """
    payload_regex = re.compile(
        rf"(^|/)lib/[^/]+\.so$|(^|/)({'|'.join(PYTHON_PACKAGE_DIR_NAMES)})/cutlass/"
    )
    with zipfile.ZipFile(wheel_path, "r") as wheel_zip:
        return any(payload_regex.search(name) for name in wheel_zip.namelist())


def _requirement_to_download(
    requirement: str, cuda_variant: str
) -> Optional[Tuple[str, str]]:
    """
    Decide whether a Requires-Dist entry names a nvidia-cutlass-dsl-libs-*
    wheel that should be downloaded for the requested CUDA variant.

    Among the cuNN variant wheels only the requested one is kept (the
    metadata may list other variants unconditionally or behind an
    extra == "cuNN" marker); non-variant entries guarded by an extra we did
    not request are skipped as well.

    Args:
        requirement: A Requires-Dist entry, e.g. 'pkg==1.0; extra == "cu13"'
        cuda_variant: Requested CUDA variant, e.g. 'cu12'

    Returns:
        Tuple of (normalized package name, requirement to download) or None
        if the entry should be skipped
    """
    spec, _, marker = requirement.partition(";")
    spec = spec.strip()
    name = _normalize_name(re.split(r"[=<>!~;\[\s]", spec, maxsplit=1)[0])
    if not name.startswith(SPLIT_PACKAGE_PREFIX):
        return None

    variant_suffix = name[len(SPLIT_PACKAGE_PREFIX) :]
    if re.fullmatch(r"cu\d+", variant_suffix) and variant_suffix != cuda_variant:
        return None

    extra_match = re.search(r"""extra\s*==\s*['"]([^'"]+)['"]""", marker)
    if extra_match and extra_match.group(1) != cuda_variant:
        return None

    return name, spec


def download_wheels(temp_dir: Path, cuda_variant: str) -> Tuple[Path, List[Path]]:
    """
    Download the nvidia-cutlass-dsl wheel(s) to a temporary directory.

    Wheels published before the 4.4.0 package split bundle all payload into
    the top-level wheel, which is then the only artifact. Starting with
    4.4.0 the top-level PyPI wheel is a metadata-only shim, so its
    nvidia-cutlass-dsl-libs-* dependencies (restricted to the requested CUDA
    variant) are followed transitively to collect the artifact wheels.

    Args:
        temp_dir: Temporary directory path for downloading
        cuda_variant: Requested CUDA variant, e.g. 'cu12'

    Returns:
        Tuple of (top-level wheel path, list of wheel paths to extract)

    Raises:
        CutlassDSLSetupError: If a download fails or no artifact wheel exists
    """
    top_wheel = _download_one_wheel(PACKAGE_NAME, temp_dir)
    if _wheel_has_payload(top_wheel):
        return top_wheel, [top_wheel]

    logger.info(
        f"{top_wheel.name} is a metadata-only wheel (split package layout); "
        f"resolving {SPLIT_PACKAGE_PREFIX}* wheels for CUDA variant {cuda_variant}"
    )
    artifact_wheels: List[Path] = []
    seen_names = {_normalize_name(PACKAGE_NAME)}
    pending_wheels = [top_wheel]
    while pending_wheels:
        for requirement in _wheel_requirements(pending_wheels.pop()):
            name_and_spec = _requirement_to_download(requirement, cuda_variant)
            if name_and_spec is None or name_and_spec[0] in seen_names:
                continue
            name, spec = name_and_spec
            seen_names.add(name)
            artifact_wheel = _download_one_wheel(spec, temp_dir)
            artifact_wheels.append(artifact_wheel)
            pending_wheels.append(artifact_wheel)

    if not artifact_wheels:
        raise CutlassDSLSetupError(
            f"{top_wheel.name} is metadata-only and declares no "
            f"{SPLIT_PACKAGE_PREFIX}* dependencies; the {PACKAGE_NAME} wheel "
            "layout may have changed. Please report this at "
            "https://github.com/NVIDIA/cutlass/issues"
        )
    return top_wheel, artifact_wheels


def extract_version_from_wheel(wheel_path: Path) -> str:
    """
    Extract version from wheel filename and convert to dev version.

    Args:
        wheel_path: Path to the wheel file

    Returns:
        Version string in format '{version}.dev0' or '{base_version}.dev{n+1}' if already has dev{n}

    Raises:
        CutlassDSLSetupError: If version cannot be extracted from filename
    """
    wheel_filename = wheel_path.name
    # Construct version regex from package name
    # Wheel filename format: {package_name_with_underscores}-{version}-{python}-{abi}-{platform}.whl
    package_pattern = PACKAGE_NAME.replace("-", "_")
    version_regex = rf"{re.escape(package_pattern)}-([^-]+)-"
    version_match = re.match(version_regex, wheel_filename)

    if version_match:
        version = version_match.group(1)

        # Check if version already has .dev<n> pattern
        dev_pattern = r"^(.+)\.dev(\d+)"
        dev_match = re.match(dev_pattern, version)

        if dev_match:
            base_version = dev_match.group(1)
            dev_number = int(dev_match.group(2))
            new_dev_number = dev_number + 1
            dev_version = f"{base_version}.dev{new_dev_number}"
            logger.info(
                f"Detected version with dev{dev_number}: {version} -> using {dev_version}"
            )
        else:
            dev_version = f"{version}.dev0"
            logger.info(f"Detected version: {version} -> using {dev_version}")

        return dev_version
    else:
        raise CutlassDSLSetupError(
            f"Could not parse version from wheel filename: {wheel_filename}"
        )


def extract_wheel_contents(wheel_path: Path, extract_dir: Path) -> None:
    """
    Extract wheel contents to specified directory.

    Args:
        wheel_path: Path to the wheel file
        extract_dir: Directory to extract contents to

    Raises:
        CutlassDSLSetupError: If extraction fails
    """
    logger.info(f"Extracting wheel contents to {extract_dir}")

    try:
        with zipfile.ZipFile(wheel_path, "r") as wheel_zip:
            wheel_zip.extractall(extract_dir)
        logger.info("Wheel extraction completed successfully")
    except zipfile.BadZipFile as e:
        raise CutlassDSLSetupError(f"Invalid wheel file {wheel_path}: {e}")
    except Exception as e:
        raise CutlassDSLSetupError(f"Failed to extract wheel: {e}")


def copy_library_files(extract_dir: Path, package_root: Path) -> int:
    """
    Copy .so library files from extracted wheel to package lib directory.

    Args:
        extract_dir: Directory containing extracted wheel contents
        package_root: Root directory of the package

    Returns:
        Number of files copied
    """
    extract_dir / "**" / "lib" / "*.so"
    so_files = [f for f in extract_dir.rglob("lib/*.so")]

    if not so_files:
        logger.warning("No .so files found in the wheel")
        return 0

    logger.info(f"Found {len(so_files)} .so files")

    # Create lib directory
    lib_dir = package_root / "lib"
    lib_dir.mkdir(exist_ok=True)

    # Copy .so files
    copied_count = 0
    for so_file in so_files:
        dest_path = lib_dir / so_file.name
        logger.info(f"Copying {so_file.name} to {dest_path}")
        shutil.copy2(so_file, dest_path)
        copied_count += 1

    logger.info(f"Successfully copied {copied_count} .so files to lib/")
    return copied_count


def copy_python_packages(extract_dir: Path, package_root: Path) -> Tuple[int, int]:
    """
    Copy python_packages/cutlass/ directory to local cutlass/ directory.
    Ignores conflicts with existing files.

    Args:
        extract_dir: Directory containing extracted wheel contents
        package_root: Root directory of the package

    Returns:
        Tuple of (files_copied, files_skipped)
    """
    # Find source cutlass directories. Pre-split wheels carry a single
    # python_packages/cutlass tree; split wheels spread dsl_packages/cutlass
    # across the libs wheels (base/core/cuNN), so merge every match.
    cutlass_source_dirs = [
        source_dir
        for dir_name in PYTHON_PACKAGE_DIR_NAMES
        for source_dir in sorted(extract_dir.rglob(f"{dir_name}/cutlass"))
        if source_dir.is_dir()
    ]

    if not cutlass_source_dirs:
        logger.warning(
            "No python_packages/cutlass/ or dsl_packages/cutlass/ directory "
            "found in the wheel"
        )
        return 0, 0

    cutlass_dest_dir = package_root / "cutlass"

    copied_count = 0
    skipped_count = 0

    for cutlass_source_dir in cutlass_source_dirs:
        logger.info(f"Copying from {cutlass_source_dir} to {cutlass_dest_dir}")

        # Walk through source directory
        for src_file in cutlass_source_dir.rglob("*"):
            if src_file.is_file():
                # Calculate relative path and destination
                rel_path = src_file.relative_to(cutlass_source_dir)
                dest_file = cutlass_dest_dir / rel_path

                # Create parent directories
                dest_file.parent.mkdir(parents=True, exist_ok=True)

                # Copy file if it doesn't exist
                if dest_file.exists():
                    skipped_count += 1
                    logger.debug(f"  Skipping {rel_path} (already exists)")
                else:
                    shutil.copy2(src_file, dest_file)
                    copied_count += 1
                    logger.info(f"  Copied {rel_path}")

    logger.info(
        f"Cutlass directory update: {copied_count} files copied, {skipped_count} files skipped"
    )
    return copied_count, skipped_count


def write_version_file(version: str, package_root: Path) -> None:
    """
    Write version string to VERSION file in the package root directory.

    Args:
        version: Version string to write
        package_root: Root directory of the package
    """
    version_file = package_root / "VERSION.EDITABLE"
    logger.info(f"Writing version {version} to {version_file}")

    try:
        with open(version_file, "w", encoding="utf-8") as f:
            f.write(version + "\n")
        logger.info(f"Successfully created VERSION file with version: {version}")
    except Exception as e:
        raise CutlassDSLSetupError(f"Failed to write VERSION file: {e}")


def prep_editable_install(cuda_variant: str = DEFAULT_CUDA_VARIANT) -> None:
    """
    Set up the CuTeDSL development environment.

    Downloads the nvidia-cutlass-dsl wheel(s), extracts version, and copies
    required files.

    Args:
        cuda_variant: Requested CUDA variant, e.g. 'cu12'

    Raises:
        CutlassDSLSetupError: If setup fails
    """
    package_root = Path(__file__).parent

    with tempfile.TemporaryDirectory() as temp_dir_str:
        temp_dir = Path(temp_dir_str)
        extract_dir = temp_dir / "extracted"

        # Download and extract wheel(s)
        top_wheel, artifact_wheels = download_wheels(temp_dir, cuda_variant)
        version = extract_version_from_wheel(top_wheel)
        for wheel_path in artifact_wheels:
            extract_wheel_contents(wheel_path, extract_dir)

        # Copy files
        lib_files_copied = copy_library_files(extract_dir, package_root)
        py_files_copied, py_files_skipped = copy_python_packages(
            extract_dir, package_root
        )

        # A working editable install needs both the runtime libraries and the
        # bundled python files (cutlass/_mlir in particular); fail loudly
        # rather than leaving a broken environment behind.
        if lib_files_copied == 0 or (py_files_copied + py_files_skipped) == 0:
            wheel_names = ", ".join(w.name for w in artifact_wheels)
            raise CutlassDSLSetupError(
                f"No runtime libraries (lib/*.so) and/or cutlass python "
                f"packages were found in {wheel_names}; the editable install "
                "would be missing cutlass._mlir or libcute_dsl_runtime.so. "
                f"The {PACKAGE_NAME} wheel layout may have changed. Please "
                "report this at https://github.com/NVIDIA/cutlass/issues"
            )

        # Write version file
        write_version_file(version, package_root)

        logger.info("Setup completed successfully!")
        logger.info(
            f"Summary: {lib_files_copied} lib files, "
            f"{py_files_copied} Python files copied, "
            f"{py_files_skipped} Python files skipped"
        )
        logger.info(f"Detected upstream version: {version}")


def _parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Set up the CuTeDSL development environment."
    )
    variant_group = parser.add_mutually_exclusive_group()
    variant_group.add_argument(
        "--cu12",
        dest="cuda_variant",
        action="store_const",
        const="cu12",
        help="Download CUDA 12 runtime wheels (default)",
    )
    variant_group.add_argument(
        "--cu13",
        dest="cuda_variant",
        action="store_const",
        const="cu13",
        help="Download CUDA 13 runtime wheels",
    )
    parser.set_defaults(cuda_variant=DEFAULT_CUDA_VARIANT)
    return parser.parse_args()


if __name__ == "__main__":
    prep_editable_install(_parse_args().cuda_variant)
