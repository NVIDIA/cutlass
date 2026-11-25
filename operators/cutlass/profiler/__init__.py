# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Public entry points for the CUTLASS Operator API Profiler."""

import importlib.util
import sys
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from cutlass.profiler.operations import OperationProfiler

TORCH_REQUIRED_MESSAGE = (
    "cutlass_profiler requires PyTorch to allocate operands and verify results. "
    "Install it with: pip install 'nvidia-cutlass-operators[torch]'"
)
"""Diagnostic printed when the profiler runs without its PyTorch dependency."""


def main(argv: list[str] | None = None) -> int:
    """Run the profiler command-line interface with optional arguments.

    This is the ``cutlass_profiler`` console script installed by the wheel, and
    is also what ``python -m cutlass.profiler`` runs.

    Args:
        argv (list[str] | None): Command-line arguments. Default is sys.argv[1:].

    Returns:
        int: Exit code.
    """
    # torch is an optional dependency of the wheel but a hard requirement of the
    # profiler, so report it as a usage error instead of an import traceback.
    if importlib.util.find_spec("torch") is None:
        print(TORCH_REQUIRED_MESSAGE, file=sys.stderr)
        return 1

    from cutlass.profiler.__main__ import main as _main

    return _main(argv)


def __getattr__(name: str) -> object:
    """Load extension APIs only when requested.

    This keeps importing cutlass.profiler usable without the optional PyTorch
    dependency that execution and operation registration require.
    """
    if name == "OperationProfiler":
        from cutlass.profiler.operations import OperationProfiler

        return OperationProfiler
    if name == "register_operation":
        from cutlass.profiler.operations import register_operation

        return register_operation
    if name == "register_design":
        from cutlass.profiler.cli_reflection.registry import register_design

        return register_design
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


__all__ = [
    "main",
    "OperationProfiler",
    "register_design",
    "register_operation",
]
