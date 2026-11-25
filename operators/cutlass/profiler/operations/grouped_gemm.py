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

"""Profiler for operations accepting GroupedGemmArguments."""

import argparse
import fnmatch
import logging
import time
from collections.abc import Callable
from itertools import accumulate, product

import torch

import cutlass.operators as ops
from cutlass.operators.arguments import IndexPtrGroupedGemmProblemSize
from cutlass.operators.utils.tensor import strides_to_layout_string
from cutlass.profiler.analysis import PerfMetrics, verify_grouped_gemm
from cutlass.profiler.cli import (
    DATA_DTYPE_NAMES,
    GLOB_ALL,
    get_dtype_name,
    parse_data_dtypes,
    parse_dimension,
    parse_grouped_extents,
    parse_layout,
)
from cutlass.profiler.operations.base import (
    OperationProfiler,
    _dtype_layout_command,
    _dtype_layout_configurations,
    _rewrite_command_options,
    set_rng_seed,
)
from cutlass.profiler.operations.desc import GroupedGemmProblemDesc
from cutlass.profiler.operations.operand_factory import (
    runtime_operand_nbytes,
    tensor_from_dtype,
)
from cutlass.profiler.profiling_results import ProfileResult, ProfileStatus
from cutlass.profiler.timing import (
    benchmark_operator,
    resolve_benchmark_options,
)

logger = logging.getLogger(__name__)
_OFFSET_AXES = ("M", "N", "K")
"""Offset axes as spelled on the command line and in ``argparse`` destinations.

``IndexPtrGroupedGemmArguments.offsets_along`` spells the same axes in
lowercase, so cross the boundary with ``str.lower()`` / ``str.upper()``.
"""


def _grouped_shapes(
    problem_size: IndexPtrGroupedGemmProblemSize,
) -> tuple[tuple[int, ...], ...]:
    if problem_size.offsets_along == "m":
        return (
            (problem_size.M, problem_size.K),
            (problem_size.G, problem_size.K, problem_size.N),
            (problem_size.M, problem_size.N),
            (problem_size.G,),
        )
    if problem_size.offsets_along == "n":
        return (
            (problem_size.G, problem_size.M, problem_size.K),
            (problem_size.K, problem_size.N),
            (problem_size.M, problem_size.N),
            (problem_size.G,),
        )
    if problem_size.offsets_along == "k":
        return (
            (problem_size.M, problem_size.K),
            (problem_size.K, problem_size.N),
            (problem_size.G, problem_size.M, problem_size.N),
            (problem_size.G,),
        )
    raise ValueError(
        f"Unsupported grouped GEMM offset axis: {problem_size.offsets_along}"
    )


def _offset_axis(args: argparse.Namespace) -> str:
    selected = [
        axis
        for axis in _OFFSET_AXES
        if getattr(args, f"{axis}_extents", None) is not None
    ]
    if len(selected) != 1:
        raise ValueError(
            "Exactly one of --M-extents, --N-extents, or --K-extents is required"
        )
    return selected[0]


def _operator_layout(operator: ops.Operator) -> str:
    metadata = operator.metadata.operands
    return strides_to_layout_string(
        metadata.A.stride, metadata.B.stride, metadata.out.stride
    )


def _resolve_layouts(
    cli_layouts: list[str],
    operator_filter: str | None,
    provider: type[ops.Provider] | None,
    target_sm: ops.TargetSm,
    metadata_filter=lambda _: True,
) -> list[str]:
    if cli_layouts != ["auto"]:
        return cli_layouts

    def combined_metadata_filter(metadata: ops.OperatorMetadata) -> bool:
        return (
            not operator_filter
            or fnmatch.fnmatchcase(metadata.operator_name, operator_filter)
        ) and metadata_filter(metadata)

    providers = [provider] if provider is not None else None
    operators = ops.get_operators(
        args=None,
        metadata_filter=combined_metadata_filter,
        target_sm=target_sm,
        providers=providers,
    )
    layouts = {
        _operator_layout(operator)
        for operator in operators
        if operator.metadata.operator_class.supported_args_type
        is ops.IndexPtrGroupedGemmArguments
    }
    return sorted(layouts) if layouts else ["ttt"]


def _problem_command(command: str, problem_size: IndexPtrGroupedGemmProblemSize) -> str:
    """Return a command reproducing one concrete grouped-GEMM problem size."""
    previous_offset = 0
    extents = []
    for offset in problem_size.offsets:
        extents.append(offset - previous_offset)
        previous_offset = offset

    offset_axis = problem_size.offsets_along.upper()
    dimensions = {
        "M": problem_size.M,
        "N": problem_size.N,
        "K": problem_size.K,
    }
    replacements = {
        f"--{offset_axis}-extents": ",".join(str(extent) for extent in extents),
        **{
            f"--{axis}": str(value)
            for axis, value in dimensions.items()
            if axis != offset_axis
        },
    }
    return _rewrite_command_options(command, replacements)


def make_grouped_gemm_arguments(
    problem_size: IndexPtrGroupedGemmProblemSize,
    args: argparse.Namespace,
    layout: str,
    device: str = "cuda",
) -> ops.IndexPtrGroupedGemmArguments:
    """Construct runnable grouped GEMM arguments from command-line configuration."""
    a_shape, b_shape, out_shape, _ = _grouped_shapes(problem_size)
    offsets = torch.tensor(
        problem_size.offsets,
        dtype=torch.int32,
        device=device,
    )
    return ops.IndexPtrGroupedGemmArguments(
        A=tensor_from_dtype(
            a_shape,
            args.A_dtype,
            args.initialization,
            device,
            column_major=layout[0] == "n",
            out_dtype=args.out_dtype,
        ),
        B=tensor_from_dtype(
            b_shape,
            args.B_dtype,
            args.initialization,
            device,
            column_major=layout[1] == "n",
            out_dtype=args.out_dtype,
        ),
        out=tensor_from_dtype(
            out_shape,
            args.out_dtype,
            args.initialization,
            device,
            column_major=layout[2] == "n",
            empty=True,
        ),
        accumulator_type=args.accum_dtype,
        offsets=offsets,
        offsets_along=problem_size.offsets_along,
    )


def _gemm_traffic_nbytes(arguments: ops.IndexPtrGroupedGemmArguments) -> int:
    """Return the operand bytes the grouped GEMM moves.

    The offsets buffer is excluded: it is per-group index metadata, not GEMM
    operand traffic, so counting it would understate the arithmetic intensity
    reported by ``flop_per_byte`` and overstate ``bandwidth_gb_per_sec``. It is
    most a few KB against operands measured in MB, so leaving it out of the L2
    rotation sizing that shares this value does not change the rotation count.
    """
    return sum(
        runtime_operand_nbytes(operand)
        for operand in (arguments.A, arguments.B, arguments.out)
    )


class GroupedGemmProfiler(OperationProfiler):
    """Profiler for contiguous-offset grouped GEMM operators."""

    @staticmethod
    def name() -> str:
        """Return the command-line operation name."""
        return "grouped_gemm"

    @staticmethod
    def add_arguments(parser: argparse.ArgumentParser) -> None:
        """Register grouped-GEMM-specific command-line arguments."""
        extent_options = parser.add_mutually_exclusive_group(required=True)
        for axis in _OFFSET_AXES:
            extent_options.add_argument(
                f"--{axis}-extents",
                type=parse_grouped_extents,
                help=(
                    f"Semicolon-separated {axis}-extents tuples "
                    "(e.g., 64,128,64;128,128,128)"
                ),
            )
        for axis in _OFFSET_AXES:
            parser.add_argument(
                f"--{axis}",
                type=parse_dimension,
                help=(
                    f"Fixed {axis} dimension: integer, comma-separated values, "
                    "or inclusive range"
                ),
            )
        parser.add_argument(
            "--A-dtype",
            type=parse_data_dtypes,
            default="f16",
            help=f"Comma-separated A matrix dtype list: {list(DATA_DTYPE_NAMES)}",
        )
        parser.add_argument(
            "--B-dtype",
            type=parse_data_dtypes,
            default="f16",
            help=f"Comma-separated B matrix dtype list: {list(DATA_DTYPE_NAMES)}",
        )
        parser.add_argument(
            "--out-dtype",
            dest="out_dtype",
            type=parse_data_dtypes,
            default="f16",
            help=f"Comma-separated D matrix dtype list: {list(DATA_DTYPE_NAMES)}",
        )
        parser.add_argument(
            "--accum-dtype",
            type=parse_data_dtypes,
            default="f32",
            help=f"Comma-separated accumulator dtype list: {list(DATA_DTYPE_NAMES)}",
        )
        parser.add_argument(
            "--layout",
            type=parse_layout,
            default="auto",
            help=(
                "Tensor memory layout for A, B, D. "
                "3-char string of 't' (row-major) / 'n' (col-major). "
                "Comma-separated for multiple (e.g., 'ttt,ntt'). "
                "'auto' (default) detects layout from --operators filter, "
                "falling back to 'ttt'."
            ),
        )

    @staticmethod
    def validate_arguments(args: argparse.Namespace) -> None:
        """Validate the selected offset axis and its two fixed dimensions."""
        offset_axis = _offset_axis(args)
        if getattr(args, offset_axis, None) is not None:
            raise ValueError(
                f"--{offset_axis} cannot be combined with --{offset_axis}-extents"
            )
        missing = [
            f"--{axis}"
            for axis in _OFFSET_AXES
            if axis != offset_axis and getattr(args, axis, None) is None
        ]
        if missing:
            raise ValueError(
                f"{' and '.join(missing)} required with --{offset_axis}-extents"
            )

    @staticmethod
    def _get_problem_sizes(
        args: argparse.Namespace,
    ) -> list[IndexPtrGroupedGemmProblemSize]:
        """Expand CLI dimensions into grouped GEMM problem sizes."""
        GroupedGemmProfiler.validate_arguments(args)
        offset_axis = _offset_axis(args)
        varying_dimension = offset_axis
        extents_sets = getattr(args, f"{varying_dimension}_extents")
        fixed_axes = tuple(axis for axis in _OFFSET_AXES if axis != offset_axis)
        fixed_values = tuple(getattr(args, axis) for axis in fixed_axes)

        problem_sizes = []
        for values in product(*fixed_values):
            dimensions = dict(
                zip(
                    fixed_axes,
                    values,
                    strict=True,
                )
            )
            for extents in extents_sets:
                offsets = tuple(accumulate(extents))
                dimensions[varying_dimension] = offsets[-1]
                problem_sizes.append(
                    IndexPtrGroupedGemmProblemSize(
                        M=dimensions["M"],
                        N=dimensions["N"],
                        K=dimensions["K"],
                        G=len(offsets),
                        offsets=offsets,
                        offsets_along=offset_axis.lower(),
                    )
                )
        return problem_sizes

    def profile(
        self,
        args: argparse.Namespace,
        on_result: Callable[[ProfileResult], None] | None = None,
    ) -> list[ProfileResult]:
        """Profile matching operators and report each result when complete."""
        if not torch.cuda.is_available():
            raise RuntimeError("CUDA is required for benchmarking")

        target_sm = self._resolve_target_sm(args)
        layouts = _resolve_layouts(
            args.layout,
            args.operators,
            args.provider,
            target_sm,
            args.metadata_filter,
        )
        configurations = _dtype_layout_configurations(args, layouts)
        outputs = []
        problem_id = 1

        for problem_size in self._get_problem_sizes(args):
            for concrete_args, layout in configurations:
                configuration_command = _dtype_layout_command(
                    args.cmd, concrete_args, layout
                )
                command = _problem_command(configuration_command, problem_size)

                def arg_factory(
                    size: IndexPtrGroupedGemmProblemSize = problem_size,
                    selected_layout: str = layout,
                    selected_args: argparse.Namespace = concrete_args,
                ) -> ops.IndexPtrGroupedGemmArguments:
                    set_rng_seed(args.seed)
                    return make_grouped_gemm_arguments(
                        size,
                        selected_args,
                        selected_layout,
                    )

                grouped_gemm_args = arg_factory()
                operators = self._get_all_operators(
                    grouped_gemm_args,
                    args.provider,
                    target_sm,
                    args.operators or GLOB_ALL,
                    metadata_filter=args.metadata_filter,
                )
                if not operators:
                    problem_id += 1
                    continue

                argument_bytes = _gemm_traffic_nbytes(grouped_gemm_args)
                benchmark_options = resolve_benchmark_options(
                    measure_performance=args.measure_performance,
                    arg_bytes=argument_bytes,
                    warmup_iterations=args.warmup_iterations,
                    profiling_iterations=args.profiling_iterations,
                    workspace_count=args.workspace_count,
                )
                for operator_idx, operator in enumerate(operators):
                    logger.info(
                        "Profiling grouped operator %d/%d for problem %d: %s",
                        operator_idx + 1,
                        len(operators),
                        problem_id,
                        operator.metadata.operator_name,
                    )
                    test_started = time.perf_counter()
                    operator_runtime_ms = (
                        benchmark_operator(
                            operator=operator,
                            benchmark_options=benchmark_options,
                            operator_args=grouped_gemm_args,
                            arg_factory=arg_factory,
                            use_cuda_graphs=args.use_graphs,
                            timing_method=args.timing_method,
                        )
                        / 1000.0
                    )
                    metrics = PerfMetrics.from_workload(
                        operator_runtime_ms,
                        2 * problem_size.M * problem_size.N * problem_size.K,
                        argument_bytes,
                    )

                    verification = None
                    if args.verification_mode != "none":
                        verification = verify_grouped_gemm(
                            grouped_gemm_args,
                            atol=args.atol,
                            rtol=args.rtol,
                            use_cpu=args.verification_mode == "cpu",
                        )

                    test_time_elapsed_ms = (time.perf_counter() - test_started) * 1000.0
                    profile_result = ProfileResult(
                        operator_name=operator.metadata.operator_name,
                        provider=operator.metadata.provider,
                        operation_kind="grouped_gemm",
                        problem_id=problem_id,
                        status=ProfileStatus.SUCCESS,
                        metrics=metrics,
                        cmd=command,
                        test_time_elapsed_ms=test_time_elapsed_ms,
                        verification=verification,
                        problem=GroupedGemmProblemDesc(
                            M=problem_size.M,
                            N=problem_size.N,
                            K=problem_size.K,
                            offsets=problem_size.offsets,
                            offsets_along=problem_size.offsets_along,
                            a_dtype=concrete_args.A_dtype,
                            b_dtype=concrete_args.B_dtype,
                            out_dtype=concrete_args.out_dtype,
                            layout=layout,
                        ),
                    )
                    outputs.append(profile_result)
                    if on_result is not None:
                        on_result(profile_result)
                problem_id += 1

        return outputs

    def _print_operation_config(self, args: argparse.Namespace) -> None:
        print(f"Problem sizes: {self._get_problem_sizes(args)}")
        print(f"A dtype list: {[get_dtype_name(dtype) for dtype in args.A_dtype]}")
        print(f"B dtype list: {[get_dtype_name(dtype) for dtype in args.B_dtype]}")
        print(f"D dtype list: {[get_dtype_name(dtype) for dtype in args.out_dtype]}")
        print(
            "Accumulator dtype list: "
            f"{[get_dtype_name(dtype) for dtype in args.accum_dtype]}"
        )
        print(f"Layouts: {args.layout}")
