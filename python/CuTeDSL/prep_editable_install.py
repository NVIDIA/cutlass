# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

"""
CuTeDSL Development Package Setup

This setup script automatically downloads the nvidia-cutlass-dsl wheel,
extracts required libraries and Python packages, and sets up the development
environment for CuTeDSL.
"""

import subprocess
import sys
import shutil
import tempfile
import zipfile
import re
from pathlib import Path
from typing import Optional, Tuple, List
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

# Constants
PACKAGE_NAME = "nvidia-cutlass-dsl"


class CutlassDSLSetupError(Exception):
    """Custom exception for setup errors."""

    pass


def download_wheel(temp_dir: Path) -> Path:
    """
    Download the nvidia-cutlass-dsl wheel to a temporary directory.

    Args:
        temp_dir: Temporary directory path for downloading

    Returns:
        Path to the downloaded wheel file

    Raises:
        CutlassDSLSetupError: If download fails or wheel not found
    """
    logger.info(f"Downloading {PACKAGE_NAME} wheel to {temp_dir}")

    try:
        subprocess.check_call(
            [
                sys.executable,
                "-m",
                "pip",
                "download",
                "--no-deps",
                PACKAGE_NAME,
                "--dest",
                str(temp_dir),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as e:
        error_msg = f"Failed to download {PACKAGE_NAME}: {e}"
        if e.stdout:
            error_msg += f"\nstdout: {e.stdout.decode()}"
        if e.stderr:
            error_msg += f"\nstderr: {e.stderr.decode()}"
        raise CutlassDSLSetupError(error_msg)

    # Find the downloaded wheel file
    wheel_pattern = f"{PACKAGE_NAME.replace('-', '_')}-*.whl"
    wheel_files = list(temp_dir.glob(wheel_pattern))
    if not wheel_files:
        raise CutlassDSLSetupError(
            f"No wheel file matching {wheel_pattern} found after download"
        )

    wheel_path = wheel_files[0]
    logger.info(f"Successfully downloaded: {wheel_path.name}")
    return wheel_path


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
    lib_pattern = extract_dir / "**" / "lib" / "*.so"
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
    # Find source cutlass directory
    cutlass_source_dirs = list(extract_dir.rglob("python_packages/cutlass"))

    if not cutlass_source_dirs:
        logger.warning("No python_packages/cutlass/ directory found in the wheel")
        return 0, 0

    cutlass_source_dir = cutlass_source_dirs[0]
    cutlass_dest_dir = package_root / "cutlass"

    logger.info(f"Found python_packages/cutlass/ directory")
    logger.info(f"Copying from {cutlass_source_dir} to {cutlass_dest_dir}")

    copied_count = 0
    skipped_count = 0

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


def prep_editable_install() -> None:
    """
    Set up the CuTeDSL development environment.

    Downloads nvidia-cutlass-dsl wheel, extracts version, and copies required files.

    Raises:
        CutlassDSLSetupError: If setup fails
    """
    package_root = Path(__file__).parent

    with tempfile.TemporaryDirectory() as temp_dir_str:
        temp_dir = Path(temp_dir_str)
        extract_dir = temp_dir / "extracted"

        # Download and extract wheel
        wheel_path = download_wheel(temp_dir)
        version = extract_version_from_wheel(wheel_path)
        extract_wheel_contents(wheel_path, extract_dir)

        # Copy files
        lib_files_copied = copy_library_files(extract_dir, package_root)
        py_files_copied, py_files_skipped = copy_python_packages(
            extract_dir, package_root
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


if __name__ == "__main__":
    prep_editable_install()
