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
    IndexPtrGroupedGemmArguments,
    Load,
    Operand,
    PerformanceControls,
    RuntimeArguments,
    ScaledOperand,
    ScaleMode,
    ScaleSwizzleMode,
    Store,
    Transport,
)
from cutlass.operators.artifact import CompiledArtifact
from cutlass.operators.base import Operator
from cutlass.operators.config import GlobalOptions
from cutlass.operators.heuristics import (
    Heuristic,
    available_heuristics,
    get_heuristic,
    register_heuristic,
)
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


__version__ = "0.3.0"


def get_operators(
    args: RuntimeArguments | None = None,
    metadata_filter: Callable[[OperatorMetadata], bool] | None = None,
    target_sm: TargetSm | str | None = None,
    providers: list[Provider] | None = None,
    heuristic: Heuristic | None = None,
    limit: int | None = None,
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
        heuristic (Heuristic | None): Optional performance heuristic used to
            order the matching Operators best-first. When ``None`` (the default),
            the unranked filtered list is returned (identical to discovery
            without a heuristic). When a heuristic is requested, it may also
            narrow the list to the Operators it can recommend.
        limit (int | None): If set, return at most ``limit`` Operators.
            With a heuristic, that is the top ``limit`` ranked Operators;
            without one, the first ``limit`` in discovery order. Forwarded to
            the heuristic when ranking.

    Returns:
        list[Operator]: Operators matching all filters. When a ``heuristic``
        is provided, the list is ranked best-first by the heuristic, and
        may potentially prune some suboptimal but otherwise valid candidates.

    Raises:
        ValueError: If ``limit`` is set and is not a positive integer.
        ImportError: If the requested heuristic's required packages are not
            installed.
        TypeError: If the heuristic rejects the provided ``args`` type (e.g.
            ``nvmatmul`` with non-:class:`GemmArguments`).
        RuntimeError: If the heuristic returns an Operator that wasn't in the
            candidate list, or duplicates one beyond its original count.
        Exception: Any other error raised by the heuristic while ranking.
    """
    if limit is not None and limit <= 0:
        raise ValueError(f"limit must be a positive integer, got {limit}")

    candidates = Manifest.get_operators(args, metadata_filter, target_sm, providers)

    if heuristic is None:
        return candidates if limit is None else candidates[:limit]

    # Copy so an in-place reorder by the heuristic cannot corrupt the
    # subset check against discovery order.
    unranked_ids = _multiset_ids(candidates)
    ranked = heuristic.rank(args, list(candidates), target_sm=target_sm, limit=limit)

    ranked_ids = _multiset_ids(ranked)
    for operator_id, count in ranked_ids.items():
        if count > unranked_ids.get(operator_id, 0):
            raise RuntimeError(
                f"Heuristic {type(heuristic).__name__} returned an Operator "
                "not present in (or duplicated beyond its count in) the "
                "candidate operators."
            )

    return ranked if limit is None else ranked[:limit]


def _multiset_ids(operators: list[Operator]) -> dict[int, int]:
    """Return a multiset of operator object identities for subset checks."""
    counts: dict[int, int] = {}
    for operator in operators:
        counts[id(operator)] = counts.get(id(operator), 0) + 1
    return counts


__all__ = [
    # Central class exposing the Operator interface
    "Operator",
    # Runtime arguments
    "RuntimeArguments",
    "PerformanceControls",
    "EpilogueArguments",
    "GemmArguments",
    "GroupedGemmArguments",
    "IndexPtrGroupedGemmArguments",
    "Load",
    "Store",
    "Transport",
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
    # Heuristics (kernel-selection ranking) management
    "Heuristic",  # base class for all ranking heuristics
    "available_heuristics",  # global registry of available, registered heuristics
    "register_heuristic",  # decorator to register a new heuristic
    "get_heuristic",  # look up a registered heuristic by name
    # Submodules to access less commonly used public surfaces
    "mma",
    "workspace",
]
