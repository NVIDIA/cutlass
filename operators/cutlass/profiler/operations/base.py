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

"""Abstract base class for operation profilers."""

import argparse
import fnmatch
import logging
import shlex
from abc import ABC, abstractmethod
from collections.abc import Callable
from copy import copy
from itertools import product

import torch

import cutlass.operators as ops
from cutlass.operators.metadata import OperatorMetadata
from cutlass.operators.utils.device import device_or_env_target_sm
from cutlass.profiler.cli import GLOB_ALL, get_dtype_name
from cutlass.profiler.profiling_results import ProfileResult, get_provider_name

logger = logging.getLogger(__name__)


def set_rng_seed(seed: int) -> None:
    """Reset CPU and CUDA RNGs to the explicit operand-generation seed.

    Reset before each argument allocation so identical problems and workspaces
    receive identical inputs regardless of invocation, sweep order, or operator.
    """
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def _dtype_layout_configurations(
    args: argparse.Namespace, layouts: list[str]
) -> list[tuple[argparse.Namespace, str]]:
    """Expand dtype and layout sweeps into scalar argument namespaces."""
    configurations = []
    for a_dtype, b_dtype, out_dtype, accum_dtype, layout in product(
        args.A_dtype,
        args.B_dtype,
        args.out_dtype,
        args.accum_dtype,
        layouts,
    ):
        concrete_args = copy(args)
        concrete_args.A_dtype = a_dtype
        concrete_args.B_dtype = b_dtype
        concrete_args.out_dtype = out_dtype
        concrete_args.accum_dtype = accum_dtype
        concrete_args.layout = layout
        configurations.append((concrete_args, layout))
    return configurations


def _rewrite_command_options(command: str, replacements: dict[str, str]) -> str:
    """Replace selected CLI options and return a shell-safe concrete command."""
    tokens = shlex.split(command)
    rewritten = []
    index = 0
    while index < len(tokens):
        token = tokens[index]
        option = token.split("=", maxsplit=1)[0]
        if option not in replacements:
            rewritten.append(token)
            index += 1
            continue
        index += 1 if "=" in token else 2

    for option, value in replacements.items():
        rewritten.extend((option, value))
    return shlex.join(rewritten)


def _dtype_layout_command(command: str, args: argparse.Namespace, layout: str) -> str:
    """Return a command reproducing one concrete dtype/layout configuration."""
    return _rewrite_command_options(
        command,
        {
            "--A-dtype": get_dtype_name(args.A_dtype),
            "--B-dtype": get_dtype_name(args.B_dtype),
            "--out-dtype": get_dtype_name(args.out_dtype),
            "--accum-dtype": get_dtype_name(args.accum_dtype),
            "--layout": layout,
        },
    )


def _tolerance_text(value: float | None) -> str:
    """Render a tolerance override, or note that it is derived per problem."""
    if value is None:
        return "auto (derived from accumulator dtype and K)"
    return str(value)


class OperationProfiler(ABC):
    """Abstract base class for profiling different operation types (GEMM, conv, etc.).

    Subclasses construct real sample arguments, select compatible operators,
    and benchmark them. Problem-size schmooing is left to each subclass.
    """

    @staticmethod
    @abstractmethod
    def name() -> str:
        """Operation name used by --operation."""
        ...

    @staticmethod
    @abstractmethod
    def add_arguments(parser: argparse.ArgumentParser) -> None:
        """Add operation-specific CLI arguments to the parser."""
        ...

    @staticmethod
    @abstractmethod
    def validate_arguments(args: argparse.Namespace) -> None:
        """Validate operation-specific command-line arguments."""

    @abstractmethod
    def profile(
        self,
        args: argparse.Namespace,
        on_result: Callable[[ProfileResult], None] | None = None,
    ) -> list[ProfileResult]:
        """Run profiling, reporting and returning operation-independent results.

        Args:
            args: Validated profiler arguments.
            on_result: Optional callback invoked exactly once when each result is
                complete.

        Returns:
            All completed results in profiling order.
        """
        ...

    @abstractmethod
    def _print_operation_config(self, args: argparse.Namespace) -> None:  # noqa: B027
        """Print operation-specific configuration. Override in subclasses."""
        ...

    def print_config(self, args: argparse.Namespace) -> None:
        """Print profiler configuration (common + operation-specific)."""
        print("CUTLASS Profiler Configuration")
        print("=" * 50)
        print(f"Operation: {self.name()}")
        provider_name = (
            get_provider_name(args.provider) if args.provider else "all (no constraint)"
        )
        print(f"Provider: {provider_name}")
        print(f"Target SM: {args.target_sm or 'environment/device'}")
        self._print_operation_config(args)
        print(f"Initialization: {args.initialization}")
        measure_performance = args.measure_performance
        warmup_iterations = args.warmup_iterations if measure_performance else 0
        profiling_iterations = args.profiling_iterations if measure_performance else 1
        workspace_count = args.workspace_count if measure_performance else 1
        l2_rotation = "enabled" if measure_performance else "disabled"
        print(f"Measure performance: {measure_performance}")
        print(f"Warmup iterations: {warmup_iterations}")
        print(f"Profiling iterations: {profiling_iterations}")
        print(f"Workspace count: {workspace_count}")
        print(f"L2 rotation: {l2_rotation}")
        print(f"Use CUDA graphs: {args.use_graphs}")
        print(f"Verification mode: {args.verification_mode}")
        if args.verification_mode != "none":
            print(f"Verify atol: {_tolerance_text(args.atol)}")
            print(f"Verify rtol: {_tolerance_text(args.rtol)}")
        print(f"Seed: {args.seed if args.seed is not None else 'None (random)'}")
        print(f"Output format: {args.output_format}")
        print(f"Operator Name filter: {args.operators or 'No name filter'}")
        print(f"Output file: {args.output_file or 'None'}")
        print(f"Append output: {args.append}")
        operator_class_pattern = (
            args.op_class.pattern if args.op_class else "No class filter"
        )
        print(f"Operator class regex: {operator_class_pattern}")
        print(
            f"Metadata filter: "
            f"{'Custom metadata filter. See CLI arguments' if not args.is_metadata_filter_identity else 'No metadata filter'}"  # noqa: E501 Can't split until Python 3.12
        )
        heuristic = getattr(args, "heuristic", None)
        heuristic_desc = (
            type(heuristic).__name__ if heuristic else "None (discovery order)"
        )
        print(f"Heuristic: {heuristic_desc}")
        print(
            f"Operator limit: {args.limit if getattr(args, 'limit', None) else 'None (all matches)'}"
        )
        print(f"Nsys profiling: {args.nsys}")
        if args.nsys and args.nsys_args:
            print(f"Nsys args: {args.nsys_args}")
        print("=" * 50)
        print()

    @staticmethod
    def _get_all_operators(
        sample_args: ops.RuntimeArguments,
        provider: type[ops.Provider] | None,
        target_sm: ops.TargetSm,
        operator_pattern: str | None = GLOB_ALL,
        metadata_filter: Callable[[OperatorMetadata], bool] = lambda _: True,
        heuristic: ops.Heuristic | None = None,
        limit: int | None = None,
    ) -> list[ops.Operator]:
        """Get matching operators for the problem.

        When ``heuristic`` is set, candidates are reordered best-first via the
        Operator API heuristics layer. When ``limit`` is set, it is forwarded to
        :func:`cutlass.operators.get_operators` so at most ``limit`` operators
        are returned. Without a heuristic, discovery order is preserved. Layout
        probing must not pass a heuristic (order is unused there).
        """
        provider_list = [provider] if provider is not None else None
        operator_pattern = operator_pattern or GLOB_ALL

        # create metadata filter from operator pattern if specified
        def _combined_metadata_filter(md: OperatorMetadata) -> bool:
            return fnmatch.fnmatchcase(
                md.operator_name, operator_pattern
            ) and metadata_filter(md)

        operators = ops.get_operators(
            sample_args,
            target_sm=target_sm,
            providers=provider_list,
            metadata_filter=_combined_metadata_filter,
            heuristic=heuristic,
            limit=limit,
        )

        if len(operators) == 0:
            provider_msg = (
                f" for provider '{get_provider_name(provider)}'" if provider else ""
            )
            pattern_msg = (
                f" matching pattern '{operator_pattern}'"
                if operator_pattern != GLOB_ALL
                else ""
            )
            logger.warning(
                f"No operators available{provider_msg}{pattern_msg} for {target_sm}, skipping..."
            )
        return operators

    @staticmethod
    def _resolve_target_sm(args: argparse.Namespace) -> ops.TargetSm:
        """Resolve the operator-selection target.

        An explicit target avoids querying the active CUDA device.
        """
        target_sm = getattr(args, "target_sm", None)
        return target_sm if target_sm is not None else device_or_env_target_sm()
