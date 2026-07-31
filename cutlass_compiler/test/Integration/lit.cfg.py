# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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

# -*- Python -*-


import os
import shutil
import subprocess

import lit.formats
import lit.util
from lit.llvm import llvm_config
from lit.llvm.subst import ToolSubst

config.name = "CUTLASS_COMPILER_INTEGRATION"
try:
    config.test_format = lit.formats.ShTest(not llvm_config.use_lit_shell)
except ValueError:
    config.test_format = lit.formats.ShTest(
        not llvm_config.use_lit_shell, force_execute_external=True
    )
config.suffixes = [".mlir"]
config.test_source_root = os.path.dirname(__file__)
config.test_exec_root = os.path.join(config.cutlass_compiler_obj_root, "test")
config.excludes = ["CMakeLists.txt", "lit.cfg.py", "lit.site.cfg.py.in"]

config.substitutions.append(("%shlibext", config.llvm_shlib_ext))

llvm_config.with_system_environment(["HOME", "PATH"])
# Do not call use_default_substitutions(): bundled/public LLVM builds may not
# have optional utilities such as `count` under LLVM_TOOLS_DIR. Register only
# the tools this suite actually uses.
integration_tool_dirs = [
    config.cutlass_compiler_tools_dir,
    config.llvm_tools_dir,
]
for tool_dir in integration_tool_dirs:
    llvm_config.with_environment("PATH", tool_dir, append_path=True)

# The integration shell wrappers also support manual usage where tool paths are
# derived from $CUTLASS_COMPILER_BUILD_DIR. LIT runs in a clean shell, so feed the wrappers
# explicit paths from the configured LLVM build.
config.environment["CUTLASS_COMPILER_BUILD_DIR"] = config.cutlass_compiler_build_root
# Merge LD_LIBRARY_PATH with the LLVM build lib dir so
# mlir-runner finds libmlir_* dependencies (e.g. libmlir_float16_utils.so).
_ld_paths = []
if config.llvm_lib_dir:
    _ld_paths.append(config.llvm_lib_dir)
for _existing in (
    os.environ.get("LD_LIBRARY_PATH", ""),
    config.environment.get("LD_LIBRARY_PATH", ""),
):
    for _entry in _existing.split(os.pathsep):
        if _entry and _entry not in _ld_paths:
            _ld_paths.append(_entry)
if _ld_paths:
    _merged_ld_library_path = os.pathsep.join(_ld_paths)
    config.environment["LD_LIBRARY_PATH"] = _merged_ld_library_path
    llvm_config.with_environment("LD_LIBRARY_PATH", _merged_ld_library_path)

for tmp_var in ("TMPDIR", "TMP", "TEMP"):
    if not os.path.isdir(config.environment.get(tmp_var, "")):
        config.environment[tmp_var] = "/tmp"

# Push lit-resolved tool/library paths into the script env so the
# integration scripts work regardless of build-tree layout (local
# `llvm-build/bin/` vs `third_party/llvm/bin/`). The scripts
# already honour each of these via `VAR="${VAR:-<default>}"`.
config.environment["CUTLASS_COMPILER"] = config.cutlass_compiler
config.environment["MLIR_RUNNER"] = config.mlir_runner
config.environment["MLIR_RUNNER_UTILS"] = config.mlir_runner_utils
config.environment["MLIR_C_RUNNER_UTILS"] = config.mlir_c_runner_utils
config.environment["MLIR_CUDA_RUNTIME"] = config.mlir_cuda_runtime

for k in ("CUDA_HOME", "CUDA_PATH", "CUTLASS_COMPILER_DEVICE_SM", "TEST_GPU_ARCH"):
    if os.environ.get(k):
        config.environment[k] = os.environ.get(k)
        llvm_config.with_environment(k, os.environ.get(k))


_NVIDIA_SMI = shutil.which("nvidia-smi")


def _parse_cuda_visible_devices():
    """Parse CUDA_VISIBLE_DEVICES for nvidia-smi -i selectors.

    Returns:
        None: unset — all physical GPUs are visible to CUDA.
        []: explicitly no GPU (empty, or a lone hide sentinel).
        non-empty list: physical indices ("0") or UUIDs ("GPU-…").

    Hide sentinels (none, -1, …) stop parsing but keep valid entries
    before them, e.g. ``0,-1`` → ``["0"]``.
    """
    _HIDE_SENTINELS = frozenset({"none", "-1", "void", "null", "no"})

    raw = os.environ.get("CUDA_VISIBLE_DEVICES")
    if raw is None:
        return None
    raw = raw.strip()
    if not raw:
        return []
    if raw.lower() in _HIDE_SENTINELS:
        return []
    selectors = []
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        if part.lower() in _HIDE_SENTINELS:
            break
        selectors.append(part)
    return selectors


def _has_visible_gpu():
    """True when CUDA can see at least one GPU in this process."""
    if _NVIDIA_SMI is None:
        return False
    selectors = _parse_cuda_visible_devices()
    if selectors is not None and not selectors:
        return False
    try:
        cmd = [_NVIDIA_SMI, "-L"]
        output = subprocess.check_output(
            cmd,
            stderr=subprocess.DEVNULL,
            timeout=10,
        ).decode("utf-8")
    except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return False
    return bool(output.strip()) and ("GPU " in output or "MIG" in output)


def _detect_gpu_sm():
    """Return attach-nvvm-target chip (e.g. sm_90) from the first visible GPU."""
    if _NVIDIA_SMI is None:
        return ""
    selectors = _parse_cuda_visible_devices()
    if selectors is not None and not selectors:
        return ""
    gpu_selector = selectors[0] if selectors is not None else "0"
    try:
        output = subprocess.check_output(
            [
                _NVIDIA_SMI,
                "-i",
                gpu_selector,
                "--query-gpu=compute_cap",
                "--format=csv,noheader",
            ],
            stderr=subprocess.DEVNULL,
            timeout=10,
        ).decode("utf-8").strip()
    except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return ""
    if not output:
        return ""
    major, _, minor = output.splitlines()[0].partition(".")
    if not major.isdigit():
        return ""
    cc = f"{major}{minor}" if minor else major
    return f"sm_{cc}"


_has_cuda_runtime = os.path.isfile(config.mlir_cuda_runtime)

# Run Device/ tests on real silicon when CUDA can see a GPU.
_use_silicon_device = _has_cuda_runtime and _has_visible_gpu()

_device_runner = os.path.join(
    config.cutlass_compiler_source_root, "scripts", "run_integration_device.sh"
)

# Tool substitutions:
#   - cutlass-compiler: full pipeline driver (cute + base + upstream).
#   - mlir-runner: JIT executor for the LLVM-dialect output.
#   - run_integration_host.sh: Host/ wrapper (host-only JIT).
#   - run_integration_device.sh: Device/ wrapper (GPU silicon).
tools = [
    ToolSubst("cutlass-compiler", unresolved="fatal"),
    ToolSubst("mlir-runner", unresolved="fatal"),
    ToolSubst(
        "%cutlass-compiler-run-host",
        command=os.path.join(
            config.cutlass_compiler_source_root, "scripts", "run_integration_host.sh"
        ),
        unresolved="fatal",
    ),
    ToolSubst(
        "%cutlass-compiler-run-device",
        command=_device_runner,
        unresolved="fatal",
    ),
]
llvm_config.add_tool_substitutions(
    tools,
    integration_tool_dirs,
)

# Device/ tests JIT-launch kernels through mlir-runner + the MLIR CUDA runtime.
# Expose the `cutlass_compiler_device` feature only when a device execution path exists, so
# `REQUIRES: cutlass_compiler_device` tests skip cleanly (UNSUPPORTED) otherwise.
if _use_silicon_device:
    config.available_features.add("cutlass_compiler_device")
    test_gpu_arch = os.environ.get("TEST_GPU_ARCH", "")
    if not test_gpu_arch:
        test_gpu_arch = _detect_gpu_sm()
    if test_gpu_arch:
        config.available_features.add(test_gpu_arch)
        if not os.environ.get("CUTLASS_COMPILER_DEVICE_SM"):
            config.environment["CUTLASS_COMPILER_DEVICE_SM"] = test_gpu_arch
            llvm_config.with_environment("CUTLASS_COMPILER_DEVICE_SM", test_gpu_arch)
