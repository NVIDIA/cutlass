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


from __future__ import annotations

from typing import TYPE_CHECKING

from cutlass.operators import mma, workspace
from cutlass.operators.arch import ArchPortability, TargetSm
from cutlass.operators.arguments import (
    DenseTensor,
    EpilogueArguments,
    GemmArguments,
    GroupedGemmArguments,
    Operand,
    PerformanceControls,
    RuntimeArguments,
    ScaledOperand,
    ScaleMode,
    ScaleSwizzleMode,
)
from cutlass.operators.artifact import CompiledArtifact
from cutlass.operators.base import Operator
from cutlass.operators.config import GlobalOptions
from cutlass.operators.manifest import Manifest
from cutlass.operators.metadata import OperatorMetadata
from cutlass.operators.providers import (
    CuTeDSLProvider,
    Provider,
    available_providers,
    register_provider,
)
from cutlass.operators.status import Status
from cutlass.operators.typing import NumericLike, TensorLike

if TYPE_CHECKING:
    from collections.abc import Callable


__version__ = "0.1.0"


def get_operators(
    args: RuntimeArguments | None = None,
    metadata_filter: Callable[[OperatorMetadata], bool] | None = None,
    target_sm: TargetSm | str | None = None,
    providers: list[Provider] | None = None,
) -> list[Operator]:
    """Return Operators that match the given arguments, metadata filter, and target.

    Args:
        args (RuntimeArguments | None): Runtime arguments describing the
            operator invocation (e.g. :class:`GemmArguments`). When ``None``,
            no argument-based filtering is applied.
        metadata_filter (Callable[[OperatorMetadata], bool] | None): An
            optional Callable that takes OperatorMetadata as input and returns
            a boolean indicating if it should be considered for inclusion in
            results. The result is an intersection of operators filtered by the
            callable and by other parameters passed to this method.
        target_sm (TargetSm | str | None): Compute capability to target (e.g.
            ``"100a"`` or a :class:`TargetSm` instance). Filters Operators that
            cannot run on this target.
        providers (list[Provider] | None): Optional list of Providers to
            restrict discovery to (e.g. ``[ops.CuTeDSLProvider]``).

    Returns:
        list[Operator]: Operators matching all filters.
    """
    return Manifest.get_operators(args, metadata_filter, target_sm, providers)


__all__ = [
    # Central class exposing the Operator interface
    "Operator",
    # Runtime arguments
    "RuntimeArguments",
    "PerformanceControls",
    "EpilogueArguments",
    "GemmArguments",
    "GroupedGemmArguments",
    # Operands
    "Operand",
    "DenseTensor",
    "ScaledOperand",
    "ScaleMode",
    "ScaleSwizzleMode",
    # Operator Discovery
    "get_operators",
    "Manifest",
    "OperatorMetadata",
    # Misc. core types
    "Status",
    "CompiledArtifact",
    # Arch
    "TargetSm",
    "ArchPortability",
    # Typing markers
    "TensorLike",
    "NumericLike",
    # Configuration
    "GlobalOptions",
    # Provider management
    "Provider",  # base class for all Providers
    "CuTeDSLProvider",  # CuTeDSLProvider holding registry of kernels written in CuTe DSL
    "available_providers",  # global list of available, registered Providers
    "register_provider",  # decorator to register a new Provider
    # Submodules to access less commonly used public surfaces
    "mma",
    "workspace",
]
