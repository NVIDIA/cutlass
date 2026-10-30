# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Environment detection shared by every notebook in this series.

Each notebook calls :func:`report` once, near the top, and uses the returned
:class:`EnvInfo` to decide whether its ``run-iket`` cell can actually execute.
Notebooks must READ correctly without a GPU -- the profiling cells degrade to
printing the command they would have run, rather than raising.
"""

from __future__ import annotations

import shutil
import subprocess
from dataclasses import dataclass, field

# Architectures the IKET device API supports, per the CUTLASS IKET profiling
# guide (media/docs/pythonDSL/guides/iket_profiling.rst).
SUPPORTED_SM = {"10.0": "SM100 (Blackwell)",
                "10.3": "SM103 (Blackwell)",
                "11.0": "SM110 (Thor)",
                "12.0": "SM120 (Blackwell)"}


@dataclass
class EnvInfo:
    gpu_name: str | None = None
    compute_capability: str | None = None
    driver: str | None = None
    dsl_version: str | None = None
    has_run_iket: bool = False
    has_iket_api: bool = False
    notes: list[str] = field(default_factory=list)

    @property
    def arch_supported(self) -> bool:
        return self.compute_capability in SUPPORTED_SM

    @property
    def can_profile(self) -> bool:
        """True only when a live ``run-iket`` collection can realistically work."""
        return bool(self.gpu_name) and self.arch_supported and self.has_run_iket and self.has_iket_api


def _query_gpu() -> tuple[str | None, str | None, str | None]:
    if not shutil.which("nvidia-smi"):
        return None, None, None
    try:
        out = subprocess.run(
            ["nvidia-smi",
             "--query-gpu=name,compute_cap,driver_version",
             "--format=csv,noheader"],
            capture_output=True, text=True, timeout=30, check=True,
        ).stdout.strip().splitlines()
    except (subprocess.SubprocessError, OSError):
        return None, None, None
    if not out:
        return None, None, None
    name, cap, driver = (f.strip() for f in out[0].split(","))
    return name, cap, driver


def probe() -> EnvInfo:
    info = EnvInfo()
    info.gpu_name, info.compute_capability, info.driver = _query_gpu()

    try:
        import cutlass  # noqa: F401
        info.dsl_version = getattr(cutlass, "__version__", "unknown")
    except ImportError:
        info.notes.append("nvidia-cutlass-dsl is not installed (pip install nvidia-cutlass-dsl)")

    try:
        import cutlass.cute.experimental.iket  # noqa: F401
        info.has_iket_api = True
    except ImportError:
        if info.dsl_version:
            info.notes.append(
                "cutlass.cute.experimental.iket is missing -- the installed wheel predates the "
                "public IKET API. Upgrade nvidia-cutlass-dsl."
            )

    info.has_run_iket = shutil.which("run-iket") is not None
    if not info.has_run_iket and info.dsl_version:
        info.notes.append(
            "run-iket is not on PATH. It ships as a console script with nvidia-cutlass-dsl; "
            "check that the environment's bin/ directory is active."
        )

    if info.gpu_name and not info.arch_supported:
        info.notes.append(
            f"Compute capability {info.compute_capability} is outside the set IKET supports "
            f"({', '.join(sorted(SUPPORTED_SM))}). The notebook still reads correctly; the "
            f"profiling cells will not run."
        )

    return info


def report() -> EnvInfo:
    """Probe the environment and print a short human-readable summary."""
    info = probe()

    print("Environment")
    print("-" * 58)
    if info.gpu_name:
        cap = info.compute_capability or "unknown"
        arch = SUPPORTED_SM.get(cap, f"cc {cap}")
        print(f"  GPU           {info.gpu_name}  [{arch}]")
        print(f"  Driver        {info.driver}")
    else:
        print("  GPU           none detected")
    print(f"  cutlass-dsl   {info.dsl_version or 'not installed'}")
    print(f"  iket API      {'yes' if info.has_iket_api else 'no'}")
    print(f"  run-iket      {'yes' if info.has_run_iket else 'no'}")
    print("-" * 58)
    print(f"  Live profiling: {'AVAILABLE' if info.can_profile else 'unavailable (read-only mode)'}")

    for note in info.notes:
        print(f"\n  note: {note}")

    return info


def run_or_show(cmd: str, info: EnvInfo, *, est: str | None = None) -> int | None:
    """Execute ``cmd`` when the environment supports it, otherwise print it.

    Returns the process return code, or None when the command was only shown.
    """
    if not info.can_profile:
        print("Live profiling is unavailable here, so this cell only shows the command:\n")
        print(f"    {cmd}\n")
        if est:
            print(f"Expected runtime on a supported GPU: {est}.")
        print("The result of this command is the figure shown below.")
        return None

    print(f"$ {cmd}\n")
    proc = subprocess.run(cmd, shell=True)
    if proc.returncode != 0:
        print(f"\nrun-iket exited {proc.returncode}. See the troubleshooting notes in notebook 11.")
    return proc.returncode
