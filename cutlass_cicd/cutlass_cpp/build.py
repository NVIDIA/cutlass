#!/usr/bin/env python3
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""Bloom-compatible build and packaging for CUTLASS C++ CI jobs."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import tarfile
from collections import namedtuple
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Mapping, Optional, Sequence, Tuple

from cutlass_cicd.common.execution import CommandRunner, TestCommand


CutlassVariant = namedtuple("CutlassVariant", ["cuda", "arch", "os", "compiler"])

_SM_SUFFIX_PATTERN = re.compile(r"_?sm(\d+[af]?(?:;\d+[af]?)*)")
_WORKSPACE_MARKER = ".cutlass-cicd-build-workspace"


def get_cutlass_version(cutlass_dir: Path) -> str:
    version_header = cutlass_dir / "include" / "cutlass" / "version.h"
    contents = version_header.read_text(encoding="utf-8")
    components = []
    for component in ("MAJOR", "MINOR", "PATCH"):
        match = re.search(
            rf"^\s*#define\s+CUTLASS_{component}\s+(\d+)\s*$",
            contents,
            flags=re.MULTILINE,
        )
        if match is None:
            raise ValueError(f"CUTLASS_{component} is missing from {version_header}")
        components.append(match.group(1))
    return ".".join(components)


def architectures_from_build_suffix(build_suffix: str) -> Tuple[str, ...]:
    """Extract ordered, unique CUDA architectures from a Bloom build suffix."""

    architectures = []
    seen = set()
    for match in _SM_SUFFIX_PATTERN.finditer(str(build_suffix or "")):
        for architecture in match.group(1).split(";"):
            if architecture not in seen:
                architectures.append(architecture)
                seen.add(architecture)
    return tuple(architectures)


def _cuda_root() -> Path:
    for variable in ("CUDA_INSTALL_DIR", "CUDA_HOME", "CUDA_PATH"):
        value = os.environ.get(variable)
        if value:
            return Path(value)
    return Path("/usr/local/cuda")


def cmake_configure_command(
    source_dir: Path,
    workspace: Path,
    build_config: Mapping[str, Any],
) -> Tuple[str, ...]:
    """Return the CMake configure command for a Bloom build spec."""

    architecture = str(build_config["arch"]).lower()
    operating_system = str(build_config["os"]).lower()
    target_platform = "aarch64" if architecture == "aarch64sbsa" else architecture
    toolchain_platform = "qnx" if operating_system == "qnx" else target_platform

    extra_flags = build_config.get("extraBuildFlags") or {}
    build_suffix = str(build_config.get("buildSuffix", ""))
    architectures = architectures_from_build_suffix(build_suffix)
    build_all_kernels = build_suffix == "build_all_kernels"

    compile_type = str(build_config.get("compileType", "release")).capitalize()
    command = [
        "cmake",
        "-S",
        str(source_dir),
        "-B",
        str(workspace),
        "-DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc",
        f"-DCMAKE_INSTALL_PREFIX={workspace / 'install'}",
        "-DCUTLASS_ENABLE_CUBLAS=ON",
        "-DCUTLASS_CMAKE_VERBOSE=ON",
        "-DCUTLASS_UNIT_TEST_SPLIT_FILES=ON",
        f"-DTARGET_PLATFORM={target_platform}",
    ]

    qnx_toolkit_root: Optional[Path] = None
    if operating_system == "qnx":
        qnx_toolkit_root = Path("/usr/local/cuda-safe-10.2/targets/aarch64-qnx")
        external_qnx_root = Path("/externals/cuda-10.2-qnx")
        if external_qnx_root.exists():
            qnx_toolkit_root = external_qnx_root
        command.append(f"-DQNX_TOOLKIT_ROOT={qnx_toolkit_root}")

    if architecture != "x86_64":
        cuda_roots = {
            "aarch64": Path("/externals/cuda-aarch64"),
            "aarch64sbsa": Path("/externals/cuda-aarch64"),
            "ppc64le": Path("/externals/cuda-ppc64le"),
        }
        cuda_root = cuda_roots.get(architecture, _cuda_root())
        cudart_root = qnx_toolkit_root or cuda_root
        toolchain_file = (
            source_dir
            / "bloom"
            / "toolchains"
            / f"cmake_{toolchain_platform}.toolchain"
        )
        command.extend(
            (
                f"-DCMAKE_TOOLCHAIN_FILE={toolchain_file}",
                f"-DCUDA_ROOT={cuda_root}",
                f"-DCUDA_CUDART_LIBRARY={cudart_root / 'lib64' / 'libcudart.so'}",
            )
        )

    if compile_type == "Debug":
        command.extend(("-DCMAKE_BUILD_TYPE=Debug", "-DCMAKE_DEBUG_POSTFIX=d"))

    if "clang" in str(build_config.get("compiler", "")):
        command.extend(
            (
                "-DCMAKE_CXX_COMPILER=clang++",
                "-DCMAKE_CUDA_HOST_COMPILER=clang++",
            )
        )

    if build_all_kernels:
        command.append("-DCUTLASS_LIBRARY_KERNELS=all")
    if architectures:
        command.append(f"-DCUTLASS_NVCC_ARCHS={';'.join(architectures)}")

    clang_build = re.search(r"clang(\d+)(?:_device)?", build_suffix)
    if clang_build is not None:
        clang_path = f"/home/utils/clang-{int(clang_build.group(1))}/bin/clang++"
        command.extend(
            (
                f"-DCMAKE_CXX_COMPILER={clang_path}",
                f"-DCMAKE_CUDA_HOST_COMPILER={clang_path}",
                "-DCMAKE_CXX_FLAGS=-D__NV_NO_HOST_COMPILER_CHECK=1",
                "-DCMAKE_CUDA_FLAGS=-D__NV_NO_HOST_COMPILER_CHECK=1",
            )
        )
    command.extend(f"-D{name}={value}" for name, value in extra_flags.items())
    return tuple(command)


def cmake_build_command(
    workspace: Path,
    num_processors: str,
    build_config: Optional[Mapping[str, Any]] = None,
) -> Tuple[str, ...]:
    targets = []
    artifact_url = str((build_config or {}).get("artifactUrl", "")).lower()
    if "perf" in artifact_url:
        targets.append("cutlass_profiler")
    targets.append("install")

    return (
        "cmake",
        "--build",
        str(workspace),
        "--verbose",
        "--target",
        *targets,
        "--parallel",
        str(num_processors),
    )


def _validate_workspace(workspace: Path, source_dir: Path) -> None:
    resolved_workspace = workspace.resolve()
    resolved_source_dir = source_dir.resolve()
    unsafe_workspaces = {
        Path("/").resolve(),
        Path("/tmp").resolve(),
        Path("/var/tmp").resolve(),
        Path("/private/tmp").resolve(),
        Path.home().resolve(),
        Path.cwd().resolve(),
    }
    if resolved_workspace in unsafe_workspaces:
        raise ValueError(f"Refusing to clean unsafe build workspace: {workspace}")
    if (
        resolved_workspace == resolved_source_dir
        or resolved_workspace in resolved_source_dir.parents
    ):
        raise ValueError("Build workspace must not contain the CUTLASS source tree")


def prepare_workspace(workspace: Path, source_dir: Path) -> None:
    _validate_workspace(workspace, source_dir)
    if workspace.exists():
        if workspace.is_symlink() or not workspace.is_dir():
            raise ValueError(f"Build workspace must be a real directory: {workspace}")
        marker = workspace / _WORKSPACE_MARKER
        if any(workspace.iterdir()) and not marker.is_file():
            raise ValueError(
                f"Refusing to clean an unmarked, non-empty workspace: {workspace}"
            )
        shutil.rmtree(workspace)
    workspace.mkdir(parents=True)
    (workspace / _WORKSPACE_MARKER).touch()


def _resolve_workspace(workspace_argument: str) -> Path:
    workspace = Path(workspace_argument).absolute()
    if workspace.is_symlink():
        raise ValueError(f"Build workspace must not be a symlink: {workspace}")
    return workspace.resolve()


def build_install(
    source_dir: Path,
    workspace: Path,
    build_config: Mapping[str, Any],
    num_processors: str,
) -> None:
    runner = CommandRunner()
    configure_command = TestCommand(
        name="cmake_configure",
        args=cmake_configure_command(source_dir, workspace, build_config),
        cwd=workspace,
    )
    returncode = runner.run(configure_command)
    if returncode != 0:
        returncode = runner.run(configure_command)
    if returncode != 0:
        raise RuntimeError(
            f"{configure_command.name} failed with return code {returncode}"
        )

    install_command = TestCommand(
        name="cmake_install",
        args=cmake_build_command(workspace, num_processors, build_config),
        cwd=workspace,
    )
    returncode = runner.run(install_command)
    if returncode != 0:
        raise RuntimeError(
            f"{install_command.name} failed with return code {returncode}"
        )


def save_build_parameters(install_dir: Path, build_params: Dict[str, Any]) -> None:
    build_params_file = install_dir / "build_params.json"
    build_params_file.write_text(
        json.dumps(
            build_params,
            sort_keys=True,
            indent=4,
            separators=(",", ": "),
            default=str,
        ),
        encoding="utf-8",
    )


def normalize_install_tree(install_dir: Path, package_only: bool) -> None:
    """Apply the small layout normalizations expected by downstream jobs."""

    if package_only:
        install_dir.mkdir(parents=True, exist_ok=True)
        return
    if not install_dir.is_dir():
        raise RuntimeError(f"CUTLASS install directory not found: {install_dir}")

    cudnn_header = install_dir / "include" / "cudnn.h"
    if cudnn_header.is_file() or cudnn_header.is_symlink():
        cudnn_header.unlink()

    lib_dir = install_dir / "lib"
    lib64_dir = install_dir / "lib64"
    if not lib_dir.is_symlink() and lib_dir.is_dir() and lib64_dir.is_dir():
        shutil.copytree(lib_dir, lib64_dir, dirs_exist_ok=True)
        shutil.rmtree(lib_dir)
    if not lib_dir.exists() and not lib_dir.is_symlink():
        lib_dir.symlink_to("lib64", target_is_directory=True)

    if lib_dir.is_dir():
        for static_library in sorted(lib_dir.glob("*.a")):
            if static_library.name.endswith("d.a"):
                continue
            debug_library = static_library.with_name(
                f"{static_library.stem}d{static_library.suffix}"
            )
            if not debug_library.exists() and not debug_library.is_symlink():
                debug_library.symlink_to(static_library.name)


def package_build(
    workspace: Path,
    output: Path,
    version: str,
    build_params: Dict[str, Any],
) -> None:
    # Bloom intentionally does not package debug builds to keep their turnaround time
    # manageable.
    if str(build_params.get("compile_type", "release")).lower() == "debug":
        return

    install_dir = workspace / "install"
    normalize_install_tree(install_dir, bool(build_params["package_only"]))

    save_build_parameters(install_dir, build_params)
    with (install_dir / "nvcc-v.txt").open("w", encoding="utf-8") as nvcc_version:
        subprocess.check_call(
            ["nvcc.exe" if os.name == "nt" else "nvcc", "--version"],
            stdout=nvcc_version,
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        output.unlink()

    archive_prefix = f"cutlass-{version}"
    items = sorted(os.listdir(install_dir))
    if os.name != "nt" and shutil.which("pigz"):
        tar_command = [
            "tar",
            "--use-compress-program=pigz",
            "-cf",
            str(output),
            "-C",
            str(install_dir),
            "--transform",
            f"flags=r;s,^,{archive_prefix}/,",
            *items,
        ]
        subprocess.check_call(tar_command)
    else:
        with tarfile.open(output, mode="w:gz", compresslevel=5) as archive:
            for item in items:
                archive.add(install_dir / item, arcname=f"{archive_prefix}/{item}")


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bloom entrypoint for building CUTLASS.")
    parser.add_argument("-o", "--output", default="build.tar.gz", help="Output package name")
    parser.add_argument(
        "-w",
        "--workspace",
        default="/tmp/build",
        help="Directory to use for build workspace",
    )
    parser.add_argument(
        "-s",
        "--source-dir",
        required=True,
        help="Path to CUTLASS source directory",
    )
    parser.add_argument(
        "--params",
        required=True,
        help="Path to JSON file containing Bloom job parameters",
    )
    parser.add_argument(
        "--num-processors",
        default="8",
        help="Specifies number of processors in Bloom build",
    )
    parser.add_argument(
        "--package-only",
        action="store_true",
        help="Skip compilation and produce only the dummy test package",
    )
    return parser.parse_args(argv)


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = parse_args(argv)
    source_dir = Path(args.source_dir).resolve()
    workspace = _resolve_workspace(args.workspace)
    output = Path(args.output).resolve()

    with Path(args.params).open(encoding="utf-8") as params_file:
        bloom_build_params = json.load(params_file)

    build_config = bloom_build_params["buildSpecCommon"]
    scm_properties = bloom_build_params["scmProperties"]
    package_only = bool(
        args.package_only or build_config.get("packagingLevel") == "package_only"
    )
    requested_variant = CutlassVariant(
        str(build_config["cuda"]),
        build_config["arch"],
        build_config["os"],
        build_config.get("compiler", "N/A"),
    )
    start_time = datetime.now().astimezone()
    version = get_cutlass_version(source_dir)
    build_params: Dict[str, Any] = {
        "bloom_build_params": bloom_build_params,
        "build_tag": scm_properties["buildId"],
        "build_timestamp": start_time.strftime(r"%Y_%m_%d.%H_%M_%S.%Z"),
        "cutlass_dir": str(source_dir),
        "cutlass_variant": requested_variant,
        "commit": scm_properties["buildRef"],
        "target_branch": build_config["jobCommon"]["branchSpec"]["ref"],
        "compile_type": build_config.get("compileType", "release"),
        "num_processors": args.num_processors,
        "output": args.output,
        "package_only": package_only,
        "start_time": start_time,
        "version": version,
        "workspace": str(workspace),
        "cuda_path": os.environ.get(
            "CUDA_PATH" if os.name == "nt" else "CUDA_INSTALL_DIR"
        ),
    }
    if "subRepos" in scm_properties:
        build_params["sub_repos"] = {
            name: properties["buildRef"]
            for name, properties in scm_properties["subRepos"].items()
        }

    prepare_workspace(workspace, source_dir)
    if not package_only:
        build_install(source_dir, workspace, build_config, args.num_processors)
    package_build(workspace, output, version, build_params)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
