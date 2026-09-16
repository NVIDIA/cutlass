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

import contextlib

from cutlass.operators.heuristics.base import (
    Heuristic,
    available_heuristics,
    get_heuristic,
    register_heuristic,
)

# Import each heuristic submodule's class so it registers itself as a side
# effect. ``nvmatmul`` registers unconditionally (its optional
# nvidia-matmul-heuristics dependency is only touched inside ``rank()``); the
# suppress is defensive so an unexpected import failure never breaks the core.
with contextlib.suppress(ImportError):
    from cutlass.operators.heuristics.nvmatmul import NvMatmulHeuristics


def __getattr__(name: str) -> object:
    """Give a clear ImportError for known but unavailable heuristics.

    For unknown attributes, raise the generic AttributeError.
    """
    heuristic_install_hints = {
        "NvMatmulHeuristics": (
            "install 'nvidia-matmul-heuristics>=0.1.0.27' "
            "(or 'nvidia-cutlass-operators[heuristics]') to enable it"
        ),
    }
    if name in heuristic_install_hints:
        raise ImportError(
            f"{name} is unavailable: {heuristic_install_hints[name]}. Check "
            f"`available_heuristics` for runtime availability."
        )
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


__all__ = [
    "Heuristic",
    "register_heuristic",
    "get_heuristic",
    "available_heuristics",
    "NvMatmulHeuristics",
]
