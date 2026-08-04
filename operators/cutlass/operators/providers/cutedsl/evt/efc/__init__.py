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

"""Epilogue Fusion Codegen (EFC) kernel-agnostic core.

EFC lets a user write a single Python function describing the fused
epilogue of a kernel; the framework re-executes that function under
several phases (parameter analysis, on-device thread operation, CPU
reference evaluation) to synthesize the CuTe DSL code and a reference
implementation from one description.

The public API lives here for convenience; operator- and arch-specific
realizations live in sibling subpackages (for example, ``dense_gemm.sm100``).

Internal layout (top of import graph last):
  _helpers       -- logging, tracing, naming, and element-wise CuTe
                   helpers (``log``, ``trace_in_mlir``, ``maximum``,
                   ``minimum``, ...).  Leaf module with no sibling
                   imports.
  _phase         -- the ``Phase`` enum (``ParameterAnalysis`` /
                   ``ThreadOperation`` / ``PyTorchEvaluation``).
  _remap         -- tensor-mode remap helpers (standalone functions).
  _tensor        -- ``Tensor`` user-facing proxy, the ``Transport``
                   enum selecting a per-tensor load/store path
                   (TMA / sync GMEM / async GMEM), and the
                   ``_RemapModesAccessor`` subscript helper.
  _configuration -- ``Configuration`` epilogue dispatch object.
  _base          -- ``VariadicParameters``, ``JIT`` and ``Kernel``
                   companion base classes (host / @cute.jit and
                   device / @cute.kernel boundaries) and the outer
                   ``EFC`` class.  ``EFC.Phase`` / ``EFC.Tensor`` /
                   ``EFC._RemapModesAccessor`` / ``EFC.Configuration``
                   are class-body ``ClassVar`` aliases pointing at
                   the sibling-module definitions.

Contract on user epilogue functions: they are re-invoked per phase
under different EFC.Configuration implementations, so they must be
pure across phases: no side effects, no control flow conditional on
state that differs between phases.
"""

from ._base import EFC, VariadicParameters  # noqa: F401 — public re-export.
from ._helpers import (  # noqa: F401 — public re-export.
    ACTIVATION_FUNCTIONS,
    NEWLINE_AND_TAB,
    TAB,
    create_named_epilogue,
    if_debug,
    if_info,
    log,
    mark_mlir,
    trace_in_mlir,
)
from ._remap import remap_modes, torch_tensor_remap_modes  # noqa: F401
from ._tensor import Transport  # noqa: F401 — public re-export.

__all__ = [
    "ACTIVATION_FUNCTIONS",
    "EFC",
    "NEWLINE_AND_TAB",
    "TAB",
    "VariadicParameters",
    "create_named_epilogue",
    "if_debug",
    "if_info",
    "log",
    "mark_mlir",
    "Transport",
    "remap_modes",
    "torch_tensor_remap_modes",
    "trace_in_mlir",
]
