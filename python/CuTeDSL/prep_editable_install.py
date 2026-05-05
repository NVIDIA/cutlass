# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
from typing import Optional, Tuple
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

# Constants
PACKAGE_NAME = "nvidia-cutlass-dsl"
RUNTIME_PACKAGE_PREFIX = "nvidia-cutlass-dsl-libs-"
RUNTIME_PROVIDER_ENV = "CUTLASS_DSL_RUNTIME_PROVIDER"
DEFAULT_RUNTIME_PROVIDER = "base"
GENERATED_RUNTIME_DIRS = (
    Path("cutlass") / "_mlir",
    Path("lib"),
)
GENERATED_RUNTIME_FILE_GLOBS = (
    str(Path("cutlass") / "**" / "py.typed"),
)
REQUIRED_RUNTIME_ARTIFACTS = (
    Path("cutlass") / "_mlir",
    Path("lib"),
)


class CutlassDSLSetupError(Exception):
    """Custom exception for setup errors."""

    pass


def get_package_spec(requirements_path: Optional[Path] = None) -> str:
    """
    Return the pip requirement spec for nvidia-cutlass-dsl from requirements.txt.

    If anything goes wrong (file not found, parse failure, line missing),
    return PACKAGE_NAME as a safe default.
    """
    try:
        req_path = requirements_path or Path(__file__).with_name("requirements.txt")
        with open(req_path, "r", encoding="utf-8") as f:
            for raw_line in f:
                line = raw_line.strip()
                if not line or line.startswith("#"):
                    continue
                if line.lower().startswith(PACKAGE_NAME):
                    return line.split("#", 1)[0].strip()
    except Exception:
        pass
    return PACKAGE_NAME


def download_requirement(requirement_spec: str, temp_dir: Path) -> Path:
    """
    Download one wheel to a temporary directory without dependencies.

    Args:
        requirement_spec: pip requirement spec to download
        temp_dir: Temporary directory path for downloading

    Returns:
        Path to the downloaded wheel file

    Raises:
        CutlassDSLSetupError: If download fails or wheel not found
    """
    logger.info(f"Downloading {requirement_spec} wheel to {temp_dir}")
    before = set(temp_dir.glob("*.whl"))

    try:
        subprocess.check_call(
            [
                sys.executable,
                "-m",
                "pip",
                "download",
                "--no-deps",
                requirement_spec,
                "--dest",
                str(temp_dir),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as e:
        error_msg = f"Failed to download {requirement_spec}: {e}"
        if e.stdout:
            error_msg += f"\nstdout: {e.stdout.decode()}"
        if e.stderr:
            error_msg += f"\nstderr: {e.stderr.decode()}"
        raise CutlassDSLSetupError(error_msg)

    # Find the newly downloaded wheel file.
    wheel_pattern = "*.whl"
    wheel_files = [path for path in temp_dir.glob(wheel_pattern) if path not in before]
    if not wheel_files:
        raise CutlassDSLSetupError(
            f"No wheel file matching {wheel_pattern} found after downloading "
            f"{requirement_spec}"
        )
    if len(wheel_files) != 1:
        raise CutlassDSLSetupError(
            f"Expected one wheel for {requirement_spec}, found "
            f"{[path.name for path in wheel_files]}"
        )

    wheel_path = wheel_files[0]
    logger.info(f"Successfully downloaded: {wheel_path.name}")
    return wheel_path


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
    # Resolve package spec from requirements, or fall back to PACKAGE_NAME
    package_spec = get_package_spec()
    return download_requirement(package_spec, temp_dir)


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
    version_regex = rf"{re.escape(package_pattern)}-([^-]+)"
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
        return "9.9.9.dev0"


def read_wheel_metadata(wheel_path: Path) -> str:
    """Read the METADATA payload from a wheel."""
    try:
        with zipfile.ZipFile(wheel_path, "r") as wheel_zip:
            metadata_files = [
                name
                for name in wheel_zip.namelist()
                if name.endswith(".dist-info/METADATA")
            ]
            if len(metadata_files) != 1:
                raise CutlassDSLSetupError(
                    f"Expected one METADATA file in {wheel_path.name}, found "
                    f"{metadata_files}"
                )
            return wheel_zip.read(metadata_files[0]).decode("utf-8")
    except zipfile.BadZipFile as e:
        raise CutlassDSLSetupError(f"Invalid wheel file {wheel_path}: {e}")


def _canonical_package_name(name: str) -> str:
    return name.lower().replace("_", "-")


def _extract_runtime_requires(metadata: str) -> dict[str, str]:
    """Return exact runtime companion requirements keyed by provider name."""
    runtime_requires: dict[str, str] = {}
    for raw_line in metadata.splitlines():
        if not raw_line.startswith("Requires-Dist:"):
            continue
        requirement = raw_line.split(":", 1)[1].strip()
        requirement_name = re.split(r"[ ;(<>=!~]", requirement, maxsplit=1)[0]
        requirement_name = _canonical_package_name(requirement_name)
        if not requirement_name.startswith(RUNTIME_PACKAGE_PREFIX):
            continue
        provider = requirement_name.removeprefix(RUNTIME_PACKAGE_PREFIX)
        version_match = re.search(r"==\s*([A-Za-z0-9_.!+\-]+)", requirement)
        if version_match is None:
            raise CutlassDSLSetupError(
                "Runtime companion dependency must be exact-pinned, got "
                f"{requirement!r}"
            )
        runtime_requires[provider] = (
            f"{RUNTIME_PACKAGE_PREFIX}{provider}=={version_match.group(1)}"
        )
    return runtime_requires


def _runtime_provider_from_package_spec(package_spec: str) -> str | None:
    extras_match = re.search(r"\[([^\]]+)\]", package_spec)
    if extras_match is None:
        return None
    extras = {
        item.strip().lower().replace("_", "-")
        for item in extras_match.group(1).split(",")
        if item.strip()
    }
    providers = [extra for extra in extras if extra]
    if len(providers) > 1:
        raise CutlassDSLSetupError(
            "Editable install runtime provider must be unique when selected "
            f"through extras, got {providers}"
        )
    return providers[0] if providers else None


def select_runtime_provider(runtime_requires: dict[str, str]) -> str:
    """Select a runtime companion provider without consulting site-packages."""
    requested_provider = None
    try:
        import os

        requested_provider = os.environ.get(RUNTIME_PROVIDER_ENV)
    except Exception:
        requested_provider = None

    if requested_provider:
        provider = requested_provider.strip().lower().replace("_", "-")
    else:
        provider = _runtime_provider_from_package_spec(get_package_spec())
        if provider is None:
            provider = DEFAULT_RUNTIME_PROVIDER

    if provider not in runtime_requires:
        raise CutlassDSLSetupError(
            f"Requested runtime provider {provider!r} is not available. "
            f"Available providers: {sorted(runtime_requires)}. Set "
            f"{RUNTIME_PROVIDER_ENV}=<provider> to select one explicitly."
        )
    logger.info(f"Selected runtime provider: {provider}")
    return provider


def download_runtime_payload_wheel(dsl_wheel_path: Path, temp_dir: Path) -> Path | None:
    """
    Download the exact runtime companion wheel required by nvidia-cutlass-dsl.

    The generated Python payload and shared libraries must come from a companion
    wheel whose version and provider match the downloaded DSL wheel metadata.
    Copying from ambient site-packages is intentionally avoided because
    nvidia-cutlass-dsl-libs-* wheels can install overlapping payload paths.
    """
    metadata = read_wheel_metadata(dsl_wheel_path)
    runtime_requires = _extract_runtime_requires(metadata)
    if not runtime_requires:
        logger.info("No nvidia-cutlass-dsl runtime companion dependency found")
        return None
    provider = select_runtime_provider(runtime_requires)
    return download_requirement(runtime_requires[provider], temp_dir)


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


def clean_generated_runtime_payload(package_root: Path) -> None:
    """
    Remove generated runtime payload copied by previous editable setup runs.

    The _mlir Python package, runtime shared library directory, and py.typed
    markers come from the downloaded runtime wheel. They must be replaced as a
    unit to avoid stale Python/.so skew across runtime package versions.
    """
    for rel_path in GENERATED_RUNTIME_DIRS:
        path = package_root / rel_path
        if path.exists():
            logger.info(f"Removing generated runtime directory {path}")
            shutil.rmtree(path)

    for pattern in GENERATED_RUNTIME_FILE_GLOBS:
        for path in package_root.glob(pattern):
            if path.is_file():
                logger.info(f"Removing generated runtime file {path}")
                path.unlink()


def validate_runtime_payload(package_root: Path) -> None:
    """Validate that editable setup left the required runtime payload in place."""
    missing = [
        str(package_root / rel_path)
        for rel_path in REQUIRED_RUNTIME_ARTIFACTS
        if not (package_root / rel_path).exists()
    ]
    if missing:
        raise CutlassDSLSetupError(
            "Editable CuTe DSL runtime payload is incomplete; missing "
            f"{missing}"
        )

    if not any((package_root / "lib").glob("*.so")):
        raise CutlassDSLSetupError(
            "Editable CuTe DSL runtime payload is incomplete; "
            f"no shared libraries found in {package_root / 'lib'}"
        )


def copy_library_files(extract_dir: Path, package_root: Path) -> int:
    """
    Copy .so library files from extracted wheel to package lib directory.

    Args:
        extract_dir: Directory containing extracted wheel contents
        package_root: Root directory of the package

    Returns:
        Number of files copied
    """
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

    logger.info("Found python_packages/cutlass/ directory")
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

            # Copy runtime files only when they do not overlap with source files.
            # Generated payload state is cleaned before this pass.
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

        # Download and extract the exact companion runtime payload when the
        # DSL wheel declares one. The payload provider can be selected with
        # CUTLASS_DSL_RUNTIME_PROVIDER=base/cu13.
        runtime_wheel_path = download_runtime_payload_wheel(wheel_path, temp_dir)
        if runtime_wheel_path is not None:
            extract_wheel_contents(runtime_wheel_path, extract_dir)

        # Replace generated runtime files as a unit so stale _mlir/Python
        # payloads cannot survive across runtime package version changes.
        clean_generated_runtime_payload(package_root)

        # Copy files from the downloaded wheels.
        lib_files_copied = copy_library_files(extract_dir, package_root)
        py_files_copied, py_files_skipped = copy_python_packages(
            extract_dir, package_root
        )
        validate_runtime_payload(package_root)

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
