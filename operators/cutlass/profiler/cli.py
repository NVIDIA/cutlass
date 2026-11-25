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

"""Command-line parsing and shared CLI value conversions for CUTLASS profiler.

This module consolidates all dtype-related constants and configuration:
- STR_TO_DTYPE_MAP: Maps short dtype strings to full names
- DTYPE_TO_STR_MAP: Maps CUTLASS numeric types to short dtype strings
"""

import argparse
import math
import re
from collections.abc import Callable
from typing import Literal, TypeVar

import cutlass
from cutlass import operators as ops

from cutlass.operators.heuristics import available_heuristics

GLOB_ALL = "*"
"""fnmatch pattern that matches every operator name."""

AUTO_INITIALIZATION = "auto"
"""``--initialization`` value selecting dtype-derived low-variance integers."""

# =============================================================================
# Dtype Constants
# =============================================================================


# Data dtype names
DATA_DTYPE_NAMES = (
    "f32",
    "f16",
    "bf16",
    "e4m3",
    "e5m2",
    "e2m1",
    "i8",
    "i32",
)


# Scale factor dtype names
SCALE_DTYPE_NAMES = (
    "ue8m0",
    "ue4m3",
    "ue5m3",
)


# map profiler dtype strings to cutlass.Numeric types
STR_TO_DTYPE_MAP = {
    "f32": cutlass.Float32,
    "f16": cutlass.Float16,
    "bf16": cutlass.BFloat16,
    "e4m3": cutlass.Float8E4M3FN,
    "e5m2": cutlass.Float8E5M2,
    "e2m1": cutlass.Float4E2M1FN,
    "i8": cutlass.Int8,
    "i32": cutlass.Int32,
    # scale factor types
    "ue8m0": cutlass.Float8E8M0FNU,
    "ue4m3": cutlass.Float8E4M3FN,
    "ue5m3": cutlass.FloatNV8E5M3FNU,
}

# Reverse of STR_TO_DTYPE_MAP. Declared explicitly rather than derived, because
# the forward map is not injective: "ue4m3" is the block-scale spelling of the
# same encoding as "e4m3". Pass scale_factor=True to get_dtype_name to recover
# the "ue4m3" spelling.
DTYPE_TO_STR_MAP = {
    cutlass.Float32: "f32",
    cutlass.Float16: "f16",
    cutlass.BFloat16: "bf16",
    cutlass.Float8E4M3FN: "e4m3",
    cutlass.Float8E5M2: "e5m2",
    cutlass.Float4E2M1FN: "e2m1",
    cutlass.Int8: "i8",
    cutlass.Int32: "i32",
    cutlass.Float8E8M0FNU: "ue8m0",
    cutlass.FloatNV8E5M3FNU: "ue5m3",
}


def get_dtype_name(dtype: type[cutlass.Numeric], *, scale_factor: bool = False) -> str:
    """Return the canonical profiler spelling for a CUTLASS numeric type.

    Args:
        dtype (type[cutlass.Numeric]): CUTLASS numeric type to look up.
        scale_factor (bool): If True and ``dtype`` is ``Float8E4M3FN``, return
            the scale-token spelling ``"ue4m3"`` instead of ``"e4m3"``. Other
            scale-factor types (``ue8m0``, ``ue5m3``) already have unique
            reverse mappings and are unaffected.

    Returns:
        str: Profiler dtype string.

    Raises:
        ValueError: If ``dtype`` is not registered in ``DTYPE_TO_STR_MAP``.
    """
    if scale_factor and dtype is cutlass.Float8E4M3FN:
        return "ue4m3"
    try:
        return DTYPE_TO_STR_MAP[dtype]
    except KeyError as err:
        raise ValueError(f"No profiler dtype name is registered for {dtype}") from err


# =============================================================================
# Parsing Helpers
# =============================================================================


def parse_provider_type(value: str | None) -> type[ops.Provider] | None:
    """Parse provider type from a string."""
    if value in (None, "None"):
        return None
    try:
        return ops.providers.available_providers[value]
    except KeyError as err:
        provider_cli_keys = list(ops.providers.available_providers.keys())
        raise argparse.ArgumentTypeError(
            f"Unknown provider: {value}. Must be one of: {provider_cli_keys}"
        ) from err


def parse_dimension(value: str) -> list[int]:
    """Parse positive dimensions from one value, a list, or an inclusive range."""
    try:
        if "," in value:
            dimensions = [int(part.strip()) for part in value.split(",")]
        elif ":" in value:
            parts = value.split(":")
            if len(parts) not in (2, 3):
                raise ValueError(
                    "expected an inclusive range in start:end[:step] format"
                )
            start, end = int(parts[0]), int(parts[1])
            step = int(parts[2]) if len(parts) == 3 else 1
            if step <= 0:
                raise ValueError("range step must be positive")
            dimensions = list(range(start, end + 1, step))
        else:
            dimensions = [int(value)]
    except ValueError as error:
        raise ValueError(f"Invalid dimension {value!r}: {error}") from error

    if not dimensions or any(dimension <= 0 for dimension in dimensions):
        raise ValueError(f"Dimensions must be positive and non-empty, got {value!r}")
    return dimensions


def parse_operator_class_regex(value: str) -> re.Pattern[str]:
    """Compile an operator-class regular expression for metadata filtering."""
    try:
        return re.compile(value)
    except re.error as error:
        raise argparse.ArgumentTypeError(
            f"invalid operator-class regular expression {value!r}: {error}"
        ) from error


def parse_workspace_count(value: str) -> int | Literal["auto"]:
    """Parse L2 workspace count as either 'auto' or a positive integer."""
    if value == "auto":
        return "auto"
    try:
        count = int(value)
    except ValueError as err:
        raise argparse.ArgumentTypeError(
            "workspace count must be a positive integer or 'auto'"
        ) from err
    if count <= 0:
        raise argparse.ArgumentTypeError(
            "workspace count must be a positive integer or 'auto'"
        )
    return count


def parse_positive_int(value: str) -> int:
    """Parse a positive integer CLI argument."""
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError(f"must be a positive integer, got {value!r}")
    return parsed


def parse_tolerance(value: str) -> float:
    """Parse a verification tolerance as a non-negative, finite float."""
    try:
        parsed = float(value)
    except ValueError as err:
        raise argparse.ArgumentTypeError(
            f"tolerance must be a non-negative number, got {value!r}"
        ) from err
    if not math.isfinite(parsed) or parsed < 0:
        raise argparse.ArgumentTypeError(
            f"tolerance must be a non-negative number, got {value!r}"
        )
    return parsed


def parse_dtype(value: str) -> type[cutlass.Numeric]:
    """Parse a profiler data type name into its CUTLASS numeric type."""
    value = value.lower()
    try:
        return STR_TO_DTYPE_MAP[value]
    except KeyError as err:
        raise ValueError(
            f"Unsupported dtype: {value}. Supported: {list(STR_TO_DTYPE_MAP.keys())}"
        ) from err


def _parse_restricted_dtype(
    value: str, supported_names: tuple[str, ...], kind: str
) -> type[cutlass.Numeric]:
    normalized = value.lower()
    if normalized not in supported_names:
        raise ValueError(
            f"Unsupported {kind} dtype: {normalized}. Supported: {list(supported_names)}"
        )
    return STR_TO_DTYPE_MAP[normalized]


def parse_data_dtype(value: str) -> type[cutlass.Numeric]:
    """Parse a numeric data or accumulator dtype."""
    return _parse_restricted_dtype(value, DATA_DTYPE_NAMES, "data")


_ParsedItem = TypeVar("_ParsedItem")


def _parse_comma_separated(
    value: str,
    item_parser: Callable[[str], _ParsedItem],
    description: str,
) -> list[_ParsedItem]:
    """Parse a non-empty comma-separated list with an item-specific parser."""
    items = [item.strip() for item in value.split(",")]
    if any(not item for item in items):
        raise ValueError(f"Invalid {description} list: {value!r}")
    return [item_parser(item) for item in items]


def parse_data_dtypes(value: str) -> list[type[cutlass.Numeric]]:
    """Parse one or more comma-separated data or accumulator dtypes."""
    return _parse_comma_separated(value, parse_data_dtype, "data dtype")


def parse_scale_dtype(value: str) -> type[cutlass.Numeric]:
    """Parse a block-scale factor dtype."""
    return _parse_restricted_dtype(value, SCALE_DTYPE_NAMES, "scale factor")


def parse_scale_dtypes(value: str) -> list[type[cutlass.Numeric]]:
    """Parse one or more comma-separated block-scale factor dtypes."""
    return _parse_comma_separated(value, parse_scale_dtype, "scale factor dtype")


def parse_grouped_extents(value: str) -> tuple[tuple[int, ...], ...]:
    """Parse semicolon-separated grouped-GEMM extent tuples."""
    try:
        extents_sets = tuple(
            tuple(int(part) for part in extents_set.split(","))
            for extents_set in value.split(";")
        )
    except ValueError as e:
        raise ValueError(f"Invalid grouped GEMM extents list: {value}") from e
    if any(extent <= 0 for extents in extents_sets for extent in extents):
        raise ValueError(f"Grouped GEMM extents must be positive, got {value}")
    return extents_sets


def parse_scale_mode(value: str) -> ops.ScaleMode:
    """Parse a scale mode from a string."""
    return ops.ScaleMode.from_string(value)


def parse_scale_modes(value: str) -> list[ops.ScaleMode]:
    """Parse one or more comma-separated scale modes."""
    return _parse_comma_separated(value, parse_scale_mode, "scale mode")


def parse_scale_swizzle(value: str) -> ops.ScaleSwizzleMode:
    """Parse the scale swizzle mode from a string."""
    return ops.ScaleSwizzleMode.from_string(value)


def parse_target_sm(value: str) -> ops.TargetSm:
    """Parse a target architecture such as ``100a`` or ``sm_100a``."""
    try:
        return ops.TargetSm(value.removeprefix("sm_"))
    except ValueError as e:
        raise ValueError(f"Invalid target SM: {value}") from e


VALID_GEMM_LAYOUTS = {
    "ttt",
    "ttn",
    "tnt",
    "tnn",
    "ntt",
    "ntn",
    "nnt",
    "nnn",
}


def parse_layout(value: str) -> list[str]:
    """Parse layout argument. Accepts comma-separated layout strings or 'auto'.

    Each layout is a 3-character string of 't' (row-major) or 'n' (col-major)
    representing layouts for A, B, out respectively.

    :param value: Layout specification string
    :type value: str
    :return: List of layout strings
    :rtype: list[str]
    :raises ValueError: If an invalid layout string is provided
    """
    value = value.lower().strip()
    if value == "auto":
        return ["auto"]
    layouts = [layout.strip() for layout in value.split(",")]
    for layout in layouts:
        if layout not in VALID_GEMM_LAYOUTS:
            raise ValueError(
                f"Invalid layout: {layout!r}. "
                f"Each layout must be 3 characters of 't' (row-major) or 'n' (col-major) "
                f"for A, B, out respectively. Valid: {sorted(VALID_GEMM_LAYOUTS)}"
            )
    return layouts


# =============================================================================
# Common CLI Arguments
# =============================================================================


def add_common_cli_args(parser: argparse.ArgumentParser) -> None:
    """Add common profiling arguments shared by all operations."""
    # Common filtering
    parser.add_argument(
        "--provider",
        type=parse_provider_type,
        default=None,
        metavar="{" + ",".join(ops.providers.available_providers.keys()) + "}",
        help="Operator provider. If not specified, queries all providers (no provider constraint).",
    )
    parser.add_argument(
        "--op_class",
        type=parse_operator_class_regex,
        default=None,
        metavar="REGEX",
        help=(
            "Filter operators by the OperatorMetadata.operator_class class name "
            "using a regular expression."
        ),
    )
    parser.add_argument(
        "--operators",
        type=str,
        default=GLOB_ALL,  # by default, match all operator names
        help="Filter operators by name pattern (wildcards supported, e.g., 'cutedsl.Sm100*' or 'cutedsl.Sm100DenseGemmUniversalOperator*')",
    )
    parser.add_argument(
        "--target-sm",
        type=parse_target_sm,
        default=None,
        help="Target architecture for operator selection, for example 100a or sm_100a.",
    )

    # Heuristic and limit
    parser.add_argument(
        "--heuristic",
        type=str,
        default=None,
        choices=[None] + list(available_heuristics.keys()),
        help=(
            "Optional Operator API heuristic used to order matching operators "
            "best-first before profiling (e.g. 'nvmatmul'). Default: none "
            "(discovery order). Combine with --limit to profile only the first N "
            "ranked operators."
        ),
    )
    parser.add_argument(
        "--limit",
        type=parse_positive_int,
        default=None,
        metavar="N",
        help=(
            "Profile only the first N matching operators via "
            "get_operators(limit=N). Default: profile all matches. Without "
            "--heuristic, N is taken from discovery order."
        ),
    )

    # profiling
    parser.add_argument(
        "--measure-performance",
        action="store_true",
        help=("Enable warmups, repeated timed iterations, and L2 cache rotation"),
    )
    parser.add_argument(
        "--warmup-iterations",
        type=int,
        default=None,
        help="Warmup iterations (default: 0, or 10 with --measure-performance)",
    )
    parser.add_argument(
        "--profiling-iterations",
        type=int,
        default=None,
        help="Timed iterations (default: 1, or 100 with --measure-performance)",
    )
    parser.add_argument(
        "--workspace-count",
        type=parse_workspace_count,
        default=None,
        help="Argument count (default: 1, or 'auto' with --measure-performance)",
    )
    parser.add_argument("--use-graphs", action="store_true", help="Use CUDA graphs")
    parser.add_argument(
        "--timing-method",
        type=str,
        default="cuda_events",
        choices=["cuda_events"],
        help="Timing backend (default: cuda_events).",
    )

    # initialization & verification
    parser.add_argument(
        "--initialization",
        type=str,
        default=AUTO_INITIALIZATION,
        help=(
            f"Input data distribution. '{AUTO_INITIALIZATION}' (default) draws "
            "low-variance integers whose range is derived from the operand and "
            "output dtypes, keeping products and sums exactly representable so "
            "verification can use tight derived tolerances. Other forms "
            "(uniform:min,max, normal:mean,std, randint:min,max, "
            "constant:value) are higher variance, so pass --atol/--rtol with "
            "them."
        ),
    )
    parser.add_argument(
        "--verification-mode",
        type=str,
        default="auto",
        choices=[
            "none",
            "cpu",
            "cuda",
            "auto",
        ],
        help="Correctness verification against the PyTorch reference: 'none' "
        "skips verification, 'cpu' runs the reference on the host, 'cuda' runs "
        "it on the device, and 'auto' verifies on the device cutlass_profiler "
        "selects. Default to 'auto'",
    )
    parser.add_argument(
        "--atol",
        type=parse_tolerance,
        default=None,
        metavar="FLOAT",
        help=(
            "Absolute tolerance for correctness verification. Default: derived "
            "per problem from the accumulator dtype and K."
        ),
    )
    parser.add_argument(
        "--rtol",
        type=parse_tolerance,
        default=None,
        metavar="FLOAT",
        help=(
            "Relative tolerance for correctness verification. Default: derived "
            "per problem from the accumulator dtype and K."
        ),
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=2026,
        help="Operand seed, reset for each problem and workspace (default: 2026)",
    )

    # report
    parser.add_argument(
        "--output-format",
        choices=["yaml", "json", "csv"],
        default="yaml",
        help="Format for standard output and --output-file (default: yaml).",
    )
    parser.add_argument(
        "--output-file",
        type=str,
        default=None,
        metavar="PATH",
        help="Optional path that receives the same formatted results as standard output.",
    )
    parser.add_argument(
        "--append",
        action="store_true",
        default=False,
        help=(
            "Append results to --output-file while preserving valid YAML, JSON, "
            "or CSV. Requires --output-file."
        ),
    )
    parser.add_argument(
        "--verbose",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Print configuration in dry-run mode. Use --no-verbose to suppress it.",
    )
    sort_group = parser.add_mutually_exclusive_group()
    sort_group.add_argument(
        "--sort-results-flops-per-sec",
        action="store_true",
        default=False,
        help="Sort final results by GFLOP/s (descending)",
    )
    sort_group.add_argument(
        "--sort-results-flops-per-byte",
        action="store_true",
        default=False,
        help="Sort final results by FLOPs/Byte (descending)",
    )

    # nsys profiling
    parser.add_argument("--nsys", action="store_true", help="Run under nsys profiler")
    parser.add_argument(
        "--nsys-args",
        type=str,
        help='Additional nsys arguments (e.g., "--trace cuda,nvtx --sample cpu")',
    )
