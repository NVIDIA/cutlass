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

"""Adapter between Operator API GEMM args and the ``nvmatmul`` heuristic.

* **args -> query**: turn :class:`~cutlass.operators.GemmArguments` into the
  problem description expected by :meth:`MatmulHeuristics.get_configs`.
* **configs -> ranking**: match candidate Operators against the recommended
  configs, keeping only matches, best-first. Pure Python over config dicts
  and :class:`~cutlass.operators.metadata.design.sm100.Sm100DesignMetadata`,
  so it is unit-testable without the optional heuristic package.

Resulting operators are limited to those native to the GPU SKU requested
(designed_for_min_cc==modeled_cc) that also match a configuration
recommended by the heuristic. All other Operators are excluded from the
results.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from cutlass.operators.arguments.operand import DenseTensor
from cutlass.operators.utils.tensor import normalized_major_stride

if TYPE_CHECKING:
    from typing import Any

    from cutlass.cute.typing import Numeric

    from cutlass.operators.arguments import GemmArguments, Operand
    from cutlass.operators.base import Operator
    from cutlass.operators.heuristics.nvmatmul._provider import TnLayout
    from cutlass.operators.metadata.design.sm100 import Sm100DesignMetadata


@dataclass(frozen=True)
class NvmmhQuery:
    """A fully-resolved problem description for :meth:`MatmulHeuristics.get_configs`."""

    m: int
    """GEMM M extent (rows of A and out)."""

    n: int
    """GEMM N extent (columns of B and out)."""

    k: int
    """GEMM K extent (contraction dimension)."""

    batch_count: int
    """GEMM batch count (L); 1 for an un-batched problem."""

    precision: str
    """nvMMH precision string (e.g. ``'HSH'`` for f16/f32/f16)."""

    layouts: tuple[TnLayout, TnLayout, TnLayout]
    """``(A, B, out)`` majors as ``'t'`` (row-major) / ``'n'`` (column-major)."""

    align_a: int
    """Alignment of operand A in elements (for a 16-byte access)."""

    align_b: int
    """Alignment of operand B in elements (for a 16-byte access)."""

    @classmethod
    def from_args(cls, args: GemmArguments) -> NvmmhQuery:
        """Build a query from dense-GEMM :class:`~cutlass.operators.GemmArguments`.

        Only plain :class:`~cutlass.operators.DenseTensor` operands are
        supported. Block-scaled / sparse / indexed operands (e.g.
        :class:`~cutlass.operators.ScaledOperand`) forward ``dtype`` /
        ``shape`` / ``stride`` to an underlying dense tensor, so without an
        explicit check they would be silently treated as dense GEMM.

        Args:
            args (GemmArguments): The runtime GEMM arguments to rank for.

        Returns:
            NvmmhQuery: The resolved query for :meth:`MatmulHeuristics.get_configs`.

        Raises:
            KeyError: If an operand dtype has no precision-letter mapping.
            TypeError: If ``A``, ``B``, or ``out`` is not a
                :class:`~cutlass.operators.DenseTensor`.
            ValueError: If an operand is not a plain row-/column-major dense
                tensor.
        """
        for name, operand in (("A", args.A), ("B", args.B), ("out", args.out)):
            if not isinstance(operand, DenseTensor):
                raise TypeError(
                    "nvmatmul heuristic supports dense GEMM only "
                    f"(DenseTensor operands); got {type(operand).__name__} "
                    f"for {name}. Omit heuristic= for non-dense args."
                )

        problem = args.problem_size
        a_dtype = _to_cutlass_numeric(args.A.dtype)
        b_dtype = _to_cutlass_numeric(args.B.dtype)
        out_dtype = _to_cutlass_numeric(args.out.dtype)
        acc_dtype = _to_cutlass_numeric(args.accumulator_type)

        return cls(
            m=problem.M,
            n=problem.N,
            k=problem.K,
            batch_count=problem.L,
            precision=build_precision_string(
                a_dtype, b_dtype, acc_dtype, out_dtype, out_dtype
            ),
            layouts=(
                operand_to_tn_layout(args.A),
                operand_to_tn_layout(args.B),
                operand_to_tn_layout(args.out),
            ),
            align_a=_alignment_elements(a_dtype),
            align_b=_alignment_elements(b_dtype),
        )


def _to_cutlass_numeric(dtype: Any) -> type[Numeric]:
    """Return a CUTLASS ``Numeric`` type for ``dtype`` (pass-through or torch)."""
    try:
        import torch
    except ImportError:
        return dtype
    if isinstance(dtype, torch.dtype):
        from cutlass.operators.utils.dtype import cutlass_type_from_torch_type

        return cutlass_type_from_torch_type(dtype)
    return dtype


def numeric_to_precision_letter(numeric: type[Numeric]) -> str:
    """Map a CUTLASS ``Numeric`` type to an nvMMH / cuBLAS-style precision letter.

    Args:
        numeric (type[Numeric]): A CUTLASS numeric type (e.g. ``cutlass.Float16``).

    Returns:
        str: A single precision letter (``'H'``, ``'S'``, ``'Q'``, ...).

    Raises:
        KeyError: If ``numeric`` has no known precision-letter counterpart.
    """
    import cutlass

    # Only the dtypes the SM100 dense GEMM operator can produce are mapped; any
    # other dtype raises KeyError rather than guessing a precision letter.
    numeric_to_letter = {
        cutlass.Float64: "D",
        cutlass.Float32: "S",
        cutlass.Float16: "H",
        cutlass.BFloat16: "T",
        cutlass.Float8E4M3FN: "Q",
        cutlass.Float8E5M2: "R",
        cutlass.Int32: "I",
        cutlass.Int8: "B",
        cutlass.Uint8: "B",
    }
    try:
        return numeric_to_letter[numeric]
    except KeyError:
        raise KeyError(f"No nvMMH precision letter mapping for {numeric!r}") from None


def build_precision_string(
    a: type[Numeric],
    b: type[Numeric],
    acc: type[Numeric],
    c: type[Numeric],
    d: type[Numeric],
) -> str:
    """Build the nvMMH precision string for ``(A, B, acc, C, D)``.

    Non-FP8 A uses the short form ``A + acc + D``. FP8 A (``'Q'``) uses the
    longer form ``A + B + C + acc + D``.
    """
    a_letter = numeric_to_precision_letter(a)
    if a_letter.lower() != "q":
        return (
            a_letter + numeric_to_precision_letter(acc) + numeric_to_precision_letter(d)
        )
    return (
        a_letter
        + numeric_to_precision_letter(b)
        + numeric_to_precision_letter(c)
        + numeric_to_precision_letter(acc)
        + numeric_to_precision_letter(d)
    )


def operand_to_tn_layout(operand: Operand) -> TnLayout:
    """Map an operand's major stride to nvMMH ``'t'`` / ``'n'``.

    A tensor whose last dimension is contiguous is row-major (``'t'``); one
    whose second-to-last dimension is contiguous is column-major (``'n'``).

    Args:
        operand (Operand): A dense GEMM operand exposing ``shape`` and ``stride``.

    Returns:
        TnLayout: ``'t'`` (row-major) or ``'n'`` (column-major).

    Raises:
        ValueError: If the operand has no single major mode (e.g. it is not a
            plain row- or column-major dense tensor).
    """
    normalized = normalized_major_stride(
        operand.shape, operand.stride, prepend_zeros_to_rank=3
    )
    row_major = (0, 0, 1)
    col_major = (0, 1, 0)
    if normalized == row_major:
        return "t"
    if normalized == col_major:
        return "n"
    raise ValueError(
        f"Operand is neither row- nor column-major (normalized stride "
        f"{normalized}); nvMatmulHeuristics only supports dense major layouts."
    )


def _alignment_elements(numeric: type[Numeric], access_bytes: int = 16) -> int:
    """Return the number of elements of ``numeric`` in an ``access_bytes`` access.

    A 16-byte (128-bit) vectorized access holds ``128 / width`` elements, e.g. 8
    for FP16 and 16 for FP8/INT8.
    """
    return max(1, (access_bytes * 8) // numeric.width)


def _tile_k_penalty(design_tile_k: int | None, config_tile_k: int | None) -> int:
    """Absolute distance between Operator CTA tile-K and nvMMH ``cta_tile_k``.

    Tile-K is a tie-breaker only (never a hard match criterion). Compares
    ``design.tile_shape[2]`` to the config's CTA tile-K directly.
    """
    if design_tile_k is None or config_tile_k is None:
        return 0
    return abs(design_tile_k - config_tile_k)


def _config_matches_design(design: Sm100DesignMetadata, config: dict[str, Any]) -> bool:
    """Return whether ``config`` and ``design`` agree on MMA tile and cluster shape.

    nvMMH reports per-CTA tiles; even ``cluster_m`` means 2-CTA, and the
    Operator MMA tiler M is ``2 * cta_tile_m`` in that case (same convention as
    ``cutlass_library.heuristics``).
    """
    tile = design.tile_shape
    cluster = design.cluster_shape
    config_uses_2cta = config.get("cluster_m", 1) % 2 == 0
    expected_tile_m = config.get("cta_tile_m")
    if expected_tile_m is not None and config_uses_2cta:
        expected_tile_m = 2 * expected_tile_m
    if tile[0] != expected_tile_m or tile[1] != config.get("cta_tile_n"):
        return False
    if config.get("cluster_m") != cluster[0] or config.get("cluster_n") != cluster[1]:
        return False
    return bool(design.use_2cta_mma) == config_uses_2cta


def _is_nvmatmul_scope(operator: Operator, modeled_cc: int) -> bool:
    """Return whether operator was designed for modeled_cc.

    Currently, we do not handle heuristics for Operators ported over from different compute capabilities.
    """
    return operator.metadata.operator_class.designed_for_min_cc == modeled_cc


def match_operators_to_configs(
    operators: list[Operator], configs: list[dict[str, Any]], modeled_cc: int
) -> list[Operator]:
    """Reorder and prune ``operators`` best-first according to heuristic ``configs``.

    nvMMH provides configs describing recommended kernel properties.
    This method matches those configs to candidate operators, and ranks
    them by best match.

    Operators outside ``modeled_cc``, and operators of the right generation
    that match no recommended config, are both pruned from the result --
    only Operators matching a recommended config are returned. Otherwise, it
    would not be possible for a user to tell where the recommended matches
    end and an unsorted leftover tail begins.

    Currently, we only support matching operators written for the same arch
    as that modeled by nvMMH (modeled_cc) -- operators written for older archs
    which are portable to this cc are currently excluded.

    Args:
        operators (list[Operator]): The filtered candidate Operators to order.
        configs (list[dict]): Heuristic configs, best-first.
        modeled_cc (int): The compute capability ``configs`` were fetched
            for (see ``NvMatmulHeuristics.modeled_cc``).

    Returns:
        list[Operator]: The subset of ``operators`` matching a recommended
            config, best-first. Empty only if ``operators`` was empty --
            never contains an Operator outside ``operators``, and never
            duplicates one.

    Raises:
        ValueError: If ``operators`` is non-empty and no candidate matches
            any heuristic config.
    """

    def best_match(
        design: Sm100DesignMetadata,
    ) -> tuple[int, float, int] | None:
        best: tuple[int, float, int] | None = None
        for rank, config in enumerate(configs):
            if not _config_matches_design(design, config):
                continue
            runtime = float(config.get("estimated_runtime", float("inf")))
            tile_k_gap = _tile_k_penalty(
                design.tile_shape[2] if len(design.tile_shape) > 2 else None,
                config.get("cta_tile_k"),
            )
            candidate = (rank, runtime, tile_k_gap)
            if best is None or candidate < best:
                best = candidate
        return best

    matched: list[tuple[tuple[int, float, int], int, Operator]] = []
    for original_index, operator in enumerate(operators):
        if not _is_nvmatmul_scope(operator, modeled_cc):
            # Out of scope: this heuristic has no config data for this
            # generation, so there's nothing meaningful to rank it against.
            # exclude from the result
            continue
        best = best_match(operator.metadata.design)
        if best is not None:
            matched.append((best, original_index, operator))

    if operators and not matched:
        raise ValueError(
            "No candidate Operator matched any nvmatmul heuristic config. "
            "Omit heuristic= to get the unsorted discovery list."
        )

    matched.sort(key=lambda item: (*item[0], item[1]))
    return [operator for _, _, operator in matched]
