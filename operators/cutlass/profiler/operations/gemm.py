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

"""Profiler for every operation accepting GemmArguments."""

import argparse
import fnmatch
import logging
import re
import time
from collections.abc import Callable
from copy import copy
from itertools import product

import torch

import cutlass

import cutlass.operators as ops
from cutlass.operators.arguments import GemmProblemSize
from cutlass.operators.utils.tensor import strides_to_layout_string
from cutlass.profiler.analysis import PerfMetrics, verify_gemm
from cutlass.profiler.cli import (
    DATA_DTYPE_NAMES,
    GLOB_ALL,
    SCALE_DTYPE_NAMES,
    get_dtype_name,
    parse_data_dtypes,
    parse_dimension,
    parse_layout,
    parse_scale_dtypes,
    parse_scale_modes,
    parse_scale_swizzle,
)
from cutlass.profiler.operations.base import (
    OperationProfiler,
    _dtype_layout_command,
    _dtype_layout_configurations,
    _rewrite_command_options,
    set_rng_seed,
)
from cutlass.profiler.operations.desc import GemmProblemDesc
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


def _extract_layout_from_pattern(pattern: str) -> str | None:
    match = re.search(r"(?:^|[_.*])([tn]{3})(?:[_.*]|$)", pattern)
    return match.group(1) if match else None


def _operator_layout(operator: ops.Operator) -> str:
    metadata = operator.metadata.operands
    try:
        return strides_to_layout_string(
            metadata.A.stride, metadata.B.stride, metadata.out.stride
        )
    except (AttributeError, KeyError, ValueError) as e:
        raise ValueError(
            f"Operator {operator.metadata.operator_name} has incomplete "
            "GEMM layout metadata"
        ) from e


def _resolve_layouts(
    cli_layouts: list[str],
    operator_filter: str = GLOB_ALL,
    provider: type[ops.Provider] | None = None,
    target_sm: ops.TargetSm | None = None,
    metadata_filter=lambda _: True,
) -> list[str]:
    """Determine which tensor layouts to profile.

    When layout is explicitly set, use those values directly.

    When layout is 'auto', determine which layouts are needed:
    - If --operators has an embedded layout token (e.g. '*_ntt_*'), use that.
    - Otherwise, inspect all matching operators and inspect their metadata
      to collect every supported layout.  This mirrors the CUTLASS C++
      profiler behaviour of running each operator with its native layout.
    - Falls back to 'ttt' only if no layout can be determined.
    """
    if cli_layouts != ["auto"]:
        return cli_layouts
    if operator_filter and (layout := _extract_layout_from_pattern(operator_filter)):
        return [layout]

    def _metadata_filter(md: ops.OperatorMetadata):
        return fnmatch.fnmatchcase(
            md.operator_name, operator_filter
        ) and metadata_filter(md)

    provider_list = [provider] if provider else None
    operators = ops.get_operators(
        args=None,
        metadata_filter=_metadata_filter,
        target_sm=target_sm,
        providers=provider_list,
    )

    layouts = {
        _operator_layout(operator)
        for operator in operators
        if operator.metadata.operator_class.supported_args_type is ops.GemmArguments
    }

    return sorted(layouts) if layouts else ["ttt"]


def _gemm_shapes(problem_size: GemmProblemSize) -> tuple[tuple[int, ...], ...]:
    M, N, K, L = problem_size
    if L > 1:
        return (L, M, K), (L, K, N), (L, M, N)
    return (M, K), (K, N), (M, N)


def _scale_fields(
    args: argparse.Namespace,
) -> tuple[type[cutlass.Numeric], ops.ScaleMode, ops.ScaleSwizzleMode] | None:
    scale_dtype = args.AB_scale_dtype
    scale_mode = args.AB_scale_mode
    scale_swizzle = args.AB_scale_swizzle
    if scale_dtype is None and scale_mode is None:
        if scale_swizzle is not None:
            raise ValueError("Scaling requires --AB-scale-dtype and --AB-scale-mode")
        return None
    if scale_dtype is None or scale_mode is None:
        raise ValueError("Scaling requires --AB-scale-dtype and --AB-scale-mode")
    if scale_swizzle is None:
        scale_swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
        # Keep configuration and result reporting aligned with the effective default.
        args.AB_scale_swizzle = scale_swizzle
    return scale_dtype, scale_mode, scale_swizzle


def _argument_configurations(
    args: argparse.Namespace, layouts: list[str]
) -> list[tuple[argparse.Namespace, str, str]]:
    """Expand every dtype, layout, and scale sweep into concrete arguments."""
    scale_dtypes = args.AB_scale_dtype or [None]
    scale_modes = args.AB_scale_mode or [None]
    configurations = []
    for base_args, layout in _dtype_layout_configurations(args, layouts):
        for scale_dtype, scale_mode in product(scale_dtypes, scale_modes):
            concrete_args = copy(base_args)
            concrete_args.AB_scale_dtype = scale_dtype
            concrete_args.AB_scale_mode = scale_mode
            scale = _scale_fields(concrete_args)
            command = _dtype_layout_command(args.cmd, concrete_args, layout)
            if scale is not None:
                command = _rewrite_command_options(
                    command,
                    {
                        "--AB-scale-dtype": get_dtype_name(scale[0], scale_factor=True),
                        "--AB-scale-mode": str(scale[1]),
                    },
                )
            configurations.append((concrete_args, layout, command))
    return configurations


def _problem_command(command: str, problem_size: GemmProblemSize) -> str:
    """Return a command reproducing one concrete GEMM problem size."""
    return _rewrite_command_options(
        command,
        {
            "--M": str(problem_size.M),
            "--N": str(problem_size.N),
            "--K": str(problem_size.K),
            "--L": str(problem_size.L),
        },
    )


def _make_operand(
    args: argparse.Namespace,
    operand_name: str,
    logical_shape: tuple[int, ...],
    column_major: bool,
    device: str,
) -> ops.Operand:
    scale_fields = _scale_fields(args)
    quantized = tensor_from_dtype(
        logical_shape,
        getattr(args, f"{operand_name}_dtype"),
        args.initialization,
        device,
        column_major=column_major,
        out_dtype=args.out_dtype,
    )
    if scale_fields is None:
        return ops.DenseTensor(quantized)

    scale_dtype, mode, swizzle = scale_fields
    scale_shape = logical_shape
    if operand_name == "B":
        scale_shape = (
            (logical_shape[0], logical_shape[2], logical_shape[1])
            if len(logical_shape) == 3
            else (logical_shape[1], logical_shape[0])
        )
    scale_elements = ops.ScaledOperand.numel_scale(scale_shape, mode, swizzle)
    scale = tensor_from_dtype(
        (scale_elements,),
        scale_dtype,
        "constant:1",
        device,
    )
    return ops.ScaledOperand(quantized, scale, mode, swizzle)


def make_gemm_arguments(
    problem_size: GemmProblemSize,
    args: argparse.Namespace,
    layout: str,
    device: str = "cuda",
) -> ops.GemmArguments:
    """Construct runnable GEMM arguments from command-line configuration."""
    a_shape, b_shape, out_shape = _gemm_shapes(problem_size)
    return ops.GemmArguments(
        A=_make_operand(args, "A", a_shape, layout[0] == "n", device),
        B=_make_operand(args, "B", b_shape, layout[1] == "n", device),
        out=tensor_from_dtype(
            out_shape,
            args.out_dtype,
            args.initialization,
            device,
            column_major=layout[2] == "n",
            empty=True,
        ),
        accumulator_type=args.accum_dtype,
    )


def _gemm_argument_nbytes(arguments: ops.GemmArguments) -> int:
    return sum(
        runtime_operand_nbytes(operand)
        for operand in (arguments.A, arguments.B, arguments.out)
    )


class GemmProfiler(OperationProfiler):
    """Profiler for operators whose supported argument type is GemmArguments."""

    @staticmethod
    def name() -> str:
        """Operation name used by --operation."""
        return "gemm"

    @staticmethod
    def add_arguments(parser: argparse.ArgumentParser) -> None:
        """Register GEMM-specific command-line arguments."""
        parser.add_argument(
            "--M",
            type=parse_dimension,
            required=True,
            help="M dimension: integer, comma-separated values, or inclusive range",
        )
        parser.add_argument(
            "--N",
            type=parse_dimension,
            required=True,
            help="N dimension: integer, comma-separated values, or inclusive range",
        )
        parser.add_argument(
            "--K",
            type=parse_dimension,
            required=True,
            help="K dimension: integer, comma-separated values, or inclusive range",
        )
        parser.add_argument(
            "--L",
            type=parse_dimension,
            default=[1],
            help=(
                "L dimension (batch count): integer, comma-separated values, "
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
        parser.add_argument(
            "--AB-scale-dtype",
            type=parse_scale_dtypes,
            default=None,
            help=f"Comma-separated shared A/B scale factor dtype list: {list(SCALE_DTYPE_NAMES)}",
        )
        parser.add_argument(
            "--AB-scale-mode",
            type=parse_scale_modes,
            default=None,
            help="Comma-separated shared A/B scale mode list: 1x16 or 1x32",
        )
        parser.add_argument(
            "--AB-scale-swizzle",
            type=parse_scale_swizzle,
            default=None,
            help="Shared A/B scale swizzle: none or 32x4x4 (default when scaling: none)",
        )

    @staticmethod
    def validate_arguments(args: argparse.Namespace) -> None:
        """Validate dense and block-scaled GEMM arguments."""
        has_scale_dtype = args.AB_scale_dtype is not None
        has_scale_mode = args.AB_scale_mode is not None
        if has_scale_dtype != has_scale_mode:
            raise ValueError("Scaling requires --AB-scale-dtype and --AB-scale-mode")
        if args.AB_scale_swizzle is not None and not has_scale_dtype:
            raise ValueError("Scaling requires --AB-scale-dtype and --AB-scale-mode")
        if has_scale_dtype and args.AB_scale_swizzle is None:
            args.AB_scale_swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
        if has_scale_dtype and args.verification_mode == "cpu":
            raise ValueError(
                "Scaled GEMM verification is unavailable on CPU; "
                "use --verification-mode cuda or --verification-mode none"
            )

    @staticmethod
    def _get_problem_sizes(args: argparse.Namespace) -> list[GemmProblemSize]:
        return [
            GemmProblemSize(m, n, k, batch_count)
            for m in args.M
            for n in args.N
            for k in args.K
            for batch_count in args.L
        ]

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
        configurations = _argument_configurations(args, layouts)
        outputs = []
        problem_id = 1

        for problem_size in self._get_problem_sizes(args):
            for concrete_args, layout, configuration_command in configurations:
                command = _problem_command(configuration_command, problem_size)
                ab_scale = _scale_fields(concrete_args)

                def arg_factory(
                    size: GemmProblemSize = problem_size,
                    selected_layout: str = layout,
                    selected_args: argparse.Namespace = concrete_args,
                ) -> ops.GemmArguments:
                    set_rng_seed(args.seed)
                    return make_gemm_arguments(size, selected_args, selected_layout)

                gemm_args = arg_factory()
                operators = self._get_all_operators(
                    gemm_args,
                    args.provider,
                    target_sm,
                    args.operators or GLOB_ALL,
                    metadata_filter=args.metadata_filter,
                    heuristic=args.heuristic,
                    limit=args.limit,
                )
                if not operators:
                    problem_id += 1
                    continue

                argument_bytes = _gemm_argument_nbytes(gemm_args)
                benchmark_options = resolve_benchmark_options(
                    measure_performance=args.measure_performance,
                    arg_bytes=argument_bytes,
                    warmup_iterations=args.warmup_iterations,
                    profiling_iterations=args.profiling_iterations,
                    workspace_count=args.workspace_count,
                )
                for operator_idx, operator in enumerate(operators):
                    logger.info(
                        "Profiling operator %d/%d for problem %d: %s",
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
                            operator_args=gemm_args,
                            arg_factory=arg_factory,
                            use_cuda_graphs=args.use_graphs,
                            timing_method=args.timing_method,
                        )
                        / 1000.0
                    )
                    metrics = PerfMetrics.from_workload(
                        operator_runtime_ms,
                        2
                        * problem_size.L
                        * problem_size.M
                        * problem_size.N
                        * problem_size.K,
                        argument_bytes,
                    )

                    verification = None
                    if args.verification_mode != "none":
                        verification = verify_gemm(
                            gemm_args,
                            atol=args.atol,
                            rtol=args.rtol,
                            use_cpu=args.verification_mode == "cpu",
                        )

                    test_time_elapsed_ms = (time.perf_counter() - test_started) * 1000.0
                    profile_result = ProfileResult(
                        operator_name=operator.metadata.operator_name,
                        provider=operator.metadata.provider,
                        operation_kind="gemm",
                        problem_id=problem_id,
                        status=ProfileStatus.SUCCESS,
                        metrics=metrics,
                        cmd=command,
                        test_time_elapsed_ms=test_time_elapsed_ms,
                        verification=verification,
                        problem=GemmProblemDesc(
                            M=problem_size.M,
                            N=problem_size.N,
                            K=problem_size.K,
                            L=problem_size.L,
                            a_dtype=concrete_args.A_dtype,
                            b_dtype=concrete_args.B_dtype,
                            out_dtype=concrete_args.out_dtype,
                            layout=layout,
                            ab_scale_dtype=ab_scale[0] if ab_scale else None,
                            ab_scale_mode=ab_scale[1] if ab_scale else None,
                            ab_scale_swizzle=ab_scale[2] if ab_scale else None,
                        ),
                    )
                    outputs.append(profile_result)
                    if on_result is not None:
                        on_result(profile_result)
                problem_id += 1

        return outputs

    def _print_operation_config(self, args: argparse.Namespace) -> None:
        print(f"Problem sizes: {self._get_problem_sizes(args)}")
        print(f"A dtypes: {[get_dtype_name(dtype) for dtype in args.A_dtype]}")
        print(f"B dtypes: {[get_dtype_name(dtype) for dtype in args.B_dtype]}")
        print(f"D dtypes: {[get_dtype_name(dtype) for dtype in args.out_dtype]}")
        print(
            "Accumulator dtypes: "
            f"{[get_dtype_name(dtype) for dtype in args.accum_dtype]}"
        )
        print(f"Layouts: {args.layout}")
        if args.AB_scale_dtype is None:
            print("A/B scaling: dense")
        else:
            scale_dtypes = [
                get_dtype_name(dtype, scale_factor=True)
                for dtype in args.AB_scale_dtype
            ]
            scale_modes = [str(mode) for mode in args.AB_scale_mode]
            scale_swizzle = args.AB_scale_swizzle or "32x4x4 (default)"
            print(f"A/B scale dtypes: {scale_dtypes}")
            print(f"A/B scale modes: {scale_modes}")
            print(f"A/B scale swizzle: {scale_swizzle}")
