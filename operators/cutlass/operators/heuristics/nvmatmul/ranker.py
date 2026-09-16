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

"""The ``nvmatmul`` heuristic: rank Operators with nvMatmulHeuristics.

Uses the Operator-API-owned :class:`MatmulHeuristics` wrapper. The optional
``nvidia-matmul-heuristics`` package (``>=0.1.0.27``) is required when this
heuristic is requested; a missing or too-old install raises :class:`ImportError`.
"""

from __future__ import annotations

from importlib.metadata import PackageNotFoundError
from importlib.metadata import version as package_version
from typing import TYPE_CHECKING, Literal

from cutlass.operators.arguments import GemmArguments
from cutlass.operators.heuristics.base import Heuristic, register_heuristic
from cutlass.operators.heuristics.nvmatmul._mapping import (
    NvmmhQuery,
    match_operators_to_configs,
)

if TYPE_CHECKING:
    from cutlass.operators.arch import TargetSm
    from cutlass.operators.arguments import RuntimeArguments
    from cutlass.operators.base import Operator

# Over-fetch configs relative to the candidate count so several candidates can
# match a recommended shape and be ordered by heuristic preference.
_CONFIG_OVERFETCH_FACTOR = 3

# Minimum nvidia-matmul-heuristics version for the single API shape we support
# (GPU at construct time / setBackendValueProperty / scalar m,n,k). Public PyPI
# currently tops out at 0.1.0.27; newer API shapes are intentionally not wired.
MIN_NVMMH_VERSION = "0.1.0.27"
_NVMMH_DIST_NAME = "nvidia-matmul-heuristics"

_MISSING_DEPS_MSG = (
    f"nvmatmul heuristic requires '{_NVMMH_DIST_NAME}>={MIN_NVMMH_VERSION}'. "
    "Install it (e.g. pip install 'nvidia-cutlass-operators[heuristics]'), "
    "or omit heuristic= / do not pass NvMatmulHeuristics()."
)


def _deps_error_message() -> str:
    """Build an ImportError message that names the required / found versions."""
    try:
        installed = package_version(_NVMMH_DIST_NAME)
    except PackageNotFoundError:
        return _MISSING_DEPS_MSG
    return (
        f"nvmatmul heuristic requires '{_NVMMH_DIST_NAME}>={MIN_NVMMH_VERSION}' "
        f"with the 0.1.0.27 API shape (found {installed}). "
        "Install/upgrade to a compatible package, or omit heuristic= / "
        "do not pass NvMatmulHeuristics()."
    )


def _version_tuple(version: str) -> tuple[int, ...]:
    """Parse a dotted version into an int tuple for ordering (e.g. 0.1.0.27)."""
    parts: list[int] = []
    for part in version.split("."):
        if part.isdigit():
            parts.append(int(part))
        else:
            # Stop at first non-numeric pre-release / local segment.
            break
    return tuple(parts)


def is_available() -> bool:
    """Return whether a compatible ``nvidia-matmul-heuristics`` install exists.

    Mirrors the availability signalling of ``cutlass.operators.available_providers``:
    the heuristic is always registered, but this reports whether it can actually
    run in this environment (importable, ``>={MIN_NVMMH_VERSION}``, and the
    0.1.0.27 constructor API shape).

    Returns:
        bool: ``True`` if a call to :meth:`NvMatmulHeuristics.rank` can use
        nvMMH, ``False`` if it would raise :class:`ImportError`.
    """
    try:
        import inspect

        import nvMatmulHeuristics as mmh_lib

        installed = package_version(_NVMMH_DIST_NAME)
    except (ImportError, PackageNotFoundError):
        return False
    if _version_tuple(installed) < _version_tuple(MIN_NVMMH_VERSION):
        return False
    # Single supported API shape: GPU / load_discovery_implicitly at construct.
    init_params = inspect.signature(
        mmh_lib.NvMatmulHeuristicsInterfaceEx.__init__
    ).parameters
    return "load_discovery_implicitly" in init_params


@register_heuristic("nvmatmul")
class NvMatmulHeuristics(Heuristic):
    """Rank Operators using NVIDIA's nvMatmulHeuristics analytical model.

    Currently supports only SM100 non-blockscaled dense GEMM (:class:`~cutlass.operators.GemmArguments`).

    Queries nvMMH for recommended configs, ranks Operators that match the recommended
    configs, and prunes away Operators that do not match any recommended config or that
    do not exactly match the GPU modeled in `self.gpu`.

    Missing optional dependencies raise :class:`ImportError`. Non-GEMM
    ``args`` raise :class:`TypeError`.
    """

    def __init__(self, gpu: Literal["B200", "GB200_NVL", "GB300_NVL"] = "B200") -> None:
        """Select the nvMMH device this heuristic instance models.

        Args:
            gpu (Literal["B200", "GB200_NVL", "GB300_NVL"]): An
                ``NvMatmulHeuristicsNvidiaGpu`` member name. Currently, this
                must be a Blackwell GPU SKU, namely ``"B200"``,
                ``"GB200_NVL"``, or ``"GB300_NVL"``.

        Raises:
            ValueError: If ``gpu`` isn't a device nvmatmul supports ranking
                for (only SM100 devices are supported today).
        """
        from cutlass.operators.heuristics.nvmatmul._provider import (
            gpu_compute_capability,
        )

        try:
            self.modeled_cc = gpu_compute_capability(gpu)
        except KeyError:
            raise ValueError(
                f"nvmatmul only supports SM100 today; {gpu!r} isn't a "
                'recognized/supported device (e.g. "B200", "GB200_NVL", '
                '"GB300_NVL").'
            ) from None
        self.gpu = gpu

    def rank(
        self,
        args: RuntimeArguments | None,
        operators: list[Operator],
        *,
        target_sm: TargetSm | str | None = None,
        limit: int | None = None,
    ) -> list[Operator]:
        """Order ``operators`` best-first for ``args`` using nvMatmulHeuristics.

        See :meth:`cutlass.operators.heuristics.base.Heuristic.rank`.

        Args:
            args (RuntimeArguments | None): The problem to rank for. Must be
                :class:`~cutlass.operators.GemmArguments` when ``operators`` is
                non-empty.
            operators (list[Operator]): Filtered candidate Operators.
            target_sm (TargetSm | str | None): Accepted for
                :meth:`Heuristic.rank` compatibility; unused.
            limit (int | None): When set, the caller will keep only the first
                ``limit`` Operators from the ranked result.

        Returns:
            list[Operator]: The subset of ``operators`` matching a
            recommended config for this instance's modeled hardware (see
            ``self.modeled_cc``), best-first. Empty only if ``operators`` was
            empty.

        Raises:
            ImportError: If ``nvMatmulHeuristics`` is not installed. The caller
                asked for this heuristic explicitly, so a missing install is
                not silently ignored.
            TypeError: If ``operators`` is non-empty and ``args`` is not a
                :class:`~cutlass.operators.GemmArguments`, or if operands are
                not dense (:class:`~cutlass.operators.DenseTensor`).
            ValueError: If ``operators`` is non-empty and no candidate
                matches any heuristic config.
        """
        del target_sm
        if not operators:
            return operators
        if not isinstance(args, GemmArguments):
            raise TypeError(
                "nvmatmul heuristic requires GemmArguments; "
                f"got {type(args).__name__}. Pass GEMM args, or omit heuristic=."
            )

        if not is_available():
            raise ImportError(_deps_error_message())

        from cutlass.operators.heuristics.nvmatmul._provider import (
            MatmulHeuristics,
        )

        heuristics = MatmulHeuristics(gpu=self.gpu)
        query = NvmmhQuery.from_args(args)
        # Size the nvMMH query from how many Operators the caller will keep.
        config_budget = limit if limit is not None else len(operators)
        configs = heuristics.get_configs(
            query.m,
            query.n,
            query.k,
            query.batch_count,
            query.precision,
            query.layouts,
            query.align_a,
            query.align_b,
            count=max(1, _CONFIG_OVERFETCH_FACTOR * config_budget),
        )

        return match_operators_to_configs(operators, configs, self.modeled_cc)
