# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import os
import platform
import re
import subprocess
from pathlib import Path
from typing import Optional

from cutlass_cicd.common.log import G_LOGGER


def detect_cuda_home(package_dir: Optional[Path] = None) -> str:
    for name in ("CUDA_HOME", "CUDA_PATH"):
        value = os.getenv(name)
        if value:
            return value

    if package_dir is not None:
        packaged_cuda = package_dir / "third_party" / "cuda"
        if packaged_cuda.is_dir():
            return str(packaged_cuda)

    return os.getenv("CUDA_TOOLKIT_PATH") or "/usr/local/cuda"


def detect_cuda_major() -> int:
    for name in ("CUTLASS_CUDA_MAJOR", "CUDA_MAJOR", "CTK_VERSION", "CUDA_VERSION"):
        value = os.getenv(name)
        if not value:
            continue
        match = re.search(r"(\d+)", value)
        if match:
            return int(match.group(1))

    cuda_home = detect_cuda_home()
    match = re.search(r"cuda[-_/]?(\d+)", cuda_home, re.IGNORECASE)
    if match:
        return int(match.group(1))

    return 13


def default_arch() -> str:
    return os.getenv("TR_ARCH") or platform.machine()


def detect_gpu_count() -> int:
    try:
        completed = subprocess.run(
            ["nvidia-smi", "-L"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            encoding="utf-8",
            check=False,
        )
    except FileNotFoundError:
        return 8

    if completed.returncode != 0:
        return 8

    gpu_count = len([line for line in completed.stdout.splitlines() if line.strip()])
    return gpu_count or 8


def ensure_imex_channel() -> None:
    channel_path = Path("/dev/nvidia-caps-imex-channels/channel0")
    if channel_path.exists():
        return

    devices_path = Path("/proc/devices")
    try:
        for line in devices_path.read_text(encoding="utf-8").splitlines():
            if "nvidia-caps-imex-channels" not in line:
                continue
            major = line.split()[0]
            subprocess.run(["sudo", "mkdir", "-p", str(channel_path.parent)], check=False)
            subprocess.run(
                ["sudo", "mknod", str(channel_path), "c", major, "0"],
                check=False,
            )
            subprocess.run(["sudo", "chmod", "666", str(channel_path)], check=False)
            return
    except OSError as error:
        G_LOGGER.warning("Unable to prepare IMEX channel: %s", error)

    G_LOGGER.warning("nvidia-caps-imex-channels not found in /proc/devices, continuing")
