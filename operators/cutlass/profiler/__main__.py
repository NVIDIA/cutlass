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

"""CUTLASS Operator API Profiler - CLI entry point.

Installing nvidia-cutlass-operators puts a ``cutlass_profiler`` executable on
$PATH. Every example below also runs as ``python -m cutlass.profiler ...``.

Usage (queries all providers by default):
    cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512
        --A-dtype f16 --B-dtype f16

With specific provider:
    cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512 --provider cutedsl

Example with dimension ranges:
    cutlass_profiler run --operation gemm --M 512:2048:512 --N 1024 --K 256

Example with operator name filtering (wildcards supported):
    cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512 --operators 'cutedsl.Sm100*'

Example dry-run (show config without profiling):
    cutlass_profiler dry-run --operation gemm --M 1024 --N 1024 --K 512
"""

import argparse
import logging
import os
import shlex
import shutil
import subprocess
import sys
from collections.abc import Sequence
from typing import TYPE_CHECKING, Literal

from cutlass.profiler import TORCH_REQUIRED_MESSAGE

# `python -m cutlass.profiler` runs this module directly, so it never reaches
# the equivalent check in `cutlass.profiler.main` (the console script). torch is
# an optional dependency of the wheel, so report it the same way here instead of
# surfacing a bare ModuleNotFoundError.
try:
    import torch
except ModuleNotFoundError as error:
    raise SystemExit(TORCH_REQUIRED_MESSAGE) from error

from cutlass.operators.heuristics import get_heuristic
from cutlass.operators.utils.device import reference_device
from cutlass.profiler.cli import add_common_cli_args
from cutlass.profiler.cli_reflection import (
    CATEGORIES,
    MetadataCliCategory,
    add_cli_arguments,
    build_metadata_filter,
    is_metadata_filter_identity,
)
from cutlass.profiler.formatters import format_output, write_output_file
from cutlass.profiler.operations import OPERATIONS
from cutlass.profiler.profiling_results import ProfileResult

from . import inspect

if TYPE_CHECKING:
    from cutlass.profiler.operations.base import OperationProfiler

PROGRAM_NAME = "cutlass_profiler"
"""Name shared by the installed console script and the importable module."""

RUN_MODE = "run"
DRY_RUN_MODE = "dry-run"
COMPILE_MODE = "compile"
INSPECT_MODE = "inspect"

MODES = (RUN_MODE, DRY_RUN_MODE, COMPILE_MODE, INSPECT_MODE)
MODE_HELP = {
    RUN_MODE: "Run end-to-end GPU operator profiling and testing.",
    DRY_RUN_MODE: "Validate and print an operator configuration without executing it.",
    COMPILE_MODE: "Reserved; this mode is not implemented.",
    INSPECT_MODE: "Query available operators and their metadata.",
}

LOG_LEVEL_ENV_VAR = "CUTLASS_PROFILER_LOG_LEVEL"


def _resolve_log_level() -> int:
    """Resolve the profiler's log level from the environment.

    Defaults to WARNING so INFO messages are silent unless the user opts in
    via ``CUTLASS_PROFILER_LOG_LEVEL`` (e.g. ``DEBUG``, ``INFO``, ``10``).

    Returns:
        int: A logging level suitable for ``logging.basicConfig(level=...)``.
    """
    raw_level = os.environ.get(LOG_LEVEL_ENV_VAR)
    if not raw_level:
        return logging.WARNING

    raw_level = raw_level.strip().upper()
    if raw_level.isdigit():
        return int(raw_level)

    resolved = logging.getLevelName(raw_level)
    if isinstance(resolved, int):
        return resolved

    raise SystemExit(
        f"Invalid {LOG_LEVEL_ENV_VAR}={raw_level!r}; expected a logging level "
        "name (DEBUG, INFO, WARNING, ERROR, CRITICAL) or numeric value."
    )


# configure logging
logging.basicConfig(
    level=_resolve_log_level(),
    format="%(levelname)s: %(message)s",
)
logger = logging.getLogger(__name__)


def run_with_nsys(argv: list[str] | None, nsys_args: str | None) -> int:
    """Re-execute the profiler under Nsight Systems.

    Args:
        argv (list[str] | None): Original command-line arguments. When None,
            use sys.argv[1:].
        nsys_args (str | None): Additional Nsight Systems arguments.

    Returns:
        int: Exit code from Nsight Systems.
    """
    # check if nsys is available
    nsys_path = shutil.which("nsys")
    if nsys_path is None:
        logger.error("nsys not found in PATH. Please install NVIDIA Nsight Systems.")
        return 1

    # rebuild command without --nsys flags
    if argv is None:
        argv = sys.argv[1:]

    filtered_args = []
    skip_next = False
    for arg in argv:
        if skip_next:
            skip_next = False
            continue
        if arg == "--nsys":
            continue
        if arg == "--nsys-args":
            skip_next = True
            continue
        if arg.startswith("--nsys-args="):
            continue
        filtered_args.append(arg)

    # construct nsys command
    default_nsys_args = [
        "--trace=cuda,nvtx,osrt",
        "--cuda-memory-usage=true",
        "--force-overwrite=true",
    ]

    # parse custom nsys args if provided
    custom_args = []
    if nsys_args:
        custom_args = shlex.split(nsys_args)

    # build full command
    nsys_cmd = [
        nsys_path,
        "profile",
        *default_nsys_args,
        *custom_args,
        sys.executable,
        "-m",
        PROGRAM_NAME,
        *filtered_args,
    ]

    logger.info(f"Running under nsys: {' '.join(nsys_cmd)}")
    logger.info("-" * 80)

    # execute nsys
    result = subprocess.run(nsys_cmd)
    return result.returncode


def sort_results(
    outputs: list[ProfileResult],
    metric_name: Literal["tflop_per_sec", "flop_per_byte"],
) -> None:
    """Sort results by an optional FLOP metric, failing when it is unavailable."""
    if metric_name == "tflop_per_sec":
        raw_values = [output.metrics.tflop_per_sec for output in outputs]
    elif metric_name == "flop_per_byte":
        raw_values = [output.metrics.flop_per_byte for output in outputs]
    else:
        raise ValueError(f"Unsupported sorting metric: {metric_name}")

    missing = [
        f"{output.operator_name} ({output.operation_kind})"
        for output, value in zip(outputs, raw_values, strict=True)
        if value is None
    ]
    if missing:
        raise ValueError(
            f"Cannot sort results by {metric_name}: the metric is unavailable for "
            f"{', '.join(missing)}"
        )
    values = [value for value in raw_values if value is not None]
    ranked = sorted(
        zip(values, outputs, strict=True),
        key=lambda item: item[0],
        reverse=True,
    )
    outputs[:] = [output for _, output in ranked]


def build_parser(
    metadata_categories: Sequence[MetadataCliCategory],
    operation_name: str | None = None,
) -> argparse.ArgumentParser:
    """Build the mode-based command-line parser for one selected operation."""
    parser = argparse.ArgumentParser(
        # Without an explicit prog, `python -m cutlass.profiler` reports itself
        # as "__main__.py" in usage and error messages.
        prog=PROGRAM_NAME,
        description="CUTLASS Operator API Profiler - Benchmark CUTLASS operators",
        allow_abbrev=False,
    )
    mode_subparsers = parser.add_subparsers(
        dest="mode",
        required=True,
        help="Mode of operation. (run, dry-run, compile, inspect)",
    )

    operation = OPERATIONS[operation_name]() if operation_name in OPERATIONS else None
    for mode_name in MODES:
        mode_parser = mode_subparsers.add_parser(
            mode_name,
            help=MODE_HELP[mode_name],
            allow_abbrev=False,
        )
        operation_choices = list(OPERATIONS)
        if mode_name == INSPECT_MODE:
            operation_choices.append("all")
        mode_parser.add_argument(
            "--operation",
            required=True,
            choices=operation_choices,
            help="Operation type to profile",
        )
        mode_parser.set_defaults(
            mode_name=mode_name,
            operation_instance=operation,
        )
        add_common_cli_args(mode_parser)
        if mode_name in (RUN_MODE, DRY_RUN_MODE) and operation is not None:
            operation.add_arguments(mode_parser)
        for category in metadata_categories:
            _ = add_cli_arguments(mode_parser, category)

    return parser


def _operation_from_argv(argv: list[str]) -> str | None:
    """Extract --operation so the full parser can add its specific options."""
    if not argv or argv[0] in ("-h", "--help"):
        return None

    parser = argparse.ArgumentParser(add_help=False, allow_abbrev=False)
    parser.add_argument("mode", choices=MODES)
    parser.add_argument(
        "--operation",
        choices=[*OPERATIONS, "all"],
    )
    args, _ = parser.parse_known_args(argv)
    return args.operation


def _apply_performance_defaults(args: argparse.Namespace) -> None:
    """Apply and validate benchmark defaults."""
    if args.warmup_iterations is None:
        args.warmup_iterations = 10 if args.measure_performance else 0
    if args.profiling_iterations is None:
        args.profiling_iterations = 100 if args.measure_performance else 1
    if args.workspace_count is None:
        args.workspace_count = "auto" if args.measure_performance else 1

    if args.warmup_iterations < 0:
        raise ValueError("warmup iterations must be non-negative")
    if args.profiling_iterations <= 0:
        raise ValueError("profiling iterations must be positive")
    if args.use_graphs and args.warmup_iterations == 0:
        raise ValueError(
            "--use-graphs requires at least one warmup iteration; "
            "use --measure-performance"
        )
    if args.nsys_args and not args.nsys:
        raise ValueError("--nsys-args requires --nsys")
    if args.append and args.output_file is None:
        raise ValueError("--append requires --output-file")

    if args.measure_performance:
        return
    invalid_options = []
    if args.warmup_iterations != 0:
        invalid_options.append(
            f"warmup_iterations={args.warmup_iterations} (expected 0)"
        )
    if args.profiling_iterations != 1:
        invalid_options.append(
            f"profiling_iterations={args.profiling_iterations} (expected 1)"
        )
    if args.workspace_count != 1:
        invalid_options.append(f"workspace_count={args.workspace_count!r} (expected 1)")
    if invalid_options:
        raise ValueError(
            "Invalid benchmark options without --measure-performance: "
            + ", ".join(invalid_options)
        )


def invocation_command() -> list[str]:
    """Return the public CLI prefix for reproducible profiler commands."""
    return [PROGRAM_NAME]


def parse_commandline(argv: list[str] | None = None) -> argparse.Namespace:
    """Parses cutlass-profiler CLI string arguments.

    Returns Namespace with all requires fields set.
    """
    raw_argv = sys.argv[1:] if argv is None else argv
    operation_name = _operation_from_argv(raw_argv)
    parser = build_parser(CATEGORIES, operation_name)
    args = parser.parse_args(raw_argv)

    if args.mode_name in (RUN_MODE, DRY_RUN_MODE):
        # Resolve 'auto' to the device the reference should run on, so every
        # later consumer sees a concrete 'none', 'cpu', or 'cuda'.
        if args.verification_mode == "auto":
            args.verification_mode = reference_device()
        try:
            args.operation_instance.validate_arguments(args)
        except ValueError as e:
            parser.error(str(e))

    # get_operators() only accepts a constructed Heuristic instance, not a
    # bare registry name -- construct it here, once, from the CLI's string.
    heuristic_name = getattr(args, "heuristic", None)
    if heuristic_name is not None:
        try:
            args.heuristic = get_heuristic(heuristic_name)()
        except (KeyError, ValueError, TypeError) as e:
            parser.error(str(e))

    try:
        _apply_performance_defaults(args)
    except ValueError as e:
        parser.error(str(e))

    # Once user specifies specific flags to filter on, build the operator metadata filter.
    try:
        if is_metadata_filter_identity(args, CATEGORIES):
            args.metadata_filter = lambda _: True
            args.is_metadata_filter_identity = True
        else:
            args.metadata_filter = build_metadata_filter(args, CATEGORIES)
            args.is_metadata_filter_identity = False
    except ValueError as e:
        parser.error(str(e))

    args.cmd = shlex.join([*invocation_command(), *raw_argv])

    return args


def main(argv: list[str] | None = None) -> int:
    """Entry point for the profiler.

    :param argv: Command-line arguments. Default is sys.argv[1:].
    :type argv: list[str] | None

    :return: Exit code
    :rtype: int
    """
    args = parse_commandline(argv)
    if args.mode_name not in (RUN_MODE, DRY_RUN_MODE, INSPECT_MODE):
        logger.error(
            "The '%s' mode is not implemented. Use 'run' to execute operators, "
            "'dry-run' to validate a configuration, or 'inspect' to query "
            "available operators.",
            args.mode_name,
        )
        return 1

    operation: OperationProfiler = args.operation_instance
    # -- Inspect Mode --
    if args.mode_name == INSPECT_MODE:
        results = inspect.inspect(args)
        print("\n".join(results))
        return 0

    # -- Dry Run Mode --
    if args.mode_name == DRY_RUN_MODE:
        if args.verbose:
            operation.print_config(args)
        logger.info("(dry-run mode - not executing)")
        return 0

    # -- Run Mode with nsys --
    if args.mode_name == RUN_MODE and args.nsys:
        return run_with_nsys(argv, args.nsys_args)

    # check cuda availability
    if not torch.cuda.is_available():
        logger.error("CUDA not available. The profiler requires a CUDA-capable GPU.")
        return 1

    sort_requested = args.sort_results_flops_per_sec or args.sort_results_flops_per_byte
    stream_yaml = args.output_format == "yaml" and not sort_requested

    def emit_yaml_result(output: ProfileResult) -> None:
        print(format_output([output], "yaml"), flush=True)

    try:
        outputs = operation.profile(
            args,
            on_result=emit_yaml_result if stream_yaml else None,
        )
    except NotImplementedError as error:
        logger.error("Unsupported profiler feature: %s", error)
        return 1
    except Exception as error:
        logger.error(
            "Profiling failed in '%s' mode (%s): %s",
            args.mode_name,
            type(error).__name__,
            error,
        )
        logger.debug("Profiler failure details", exc_info=True)
        return 1

    if not outputs:
        logger.error("No profiling results generated.")
        return 1

    # apply sorting if requested
    try:
        if args.sort_results_flops_per_sec:
            sort_results(outputs, "tflop_per_sec")
        elif args.sort_results_flops_per_byte:
            sort_results(outputs, "flop_per_byte")
    except ValueError as error:
        logger.error(str(error))
        return 1

    # JSON and CSV must be buffered to preserve their single-document formats.
    # Sorted YAML must also be buffered because completion order may not be the
    # requested output order.
    rendered_output = format_output(outputs, args.output_format)
    if not stream_yaml:
        print(rendered_output)

    if args.output_file:
        write_output_file(
            rendered_output,
            args.output_file,
            args.output_format,
            append=args.append,
        )
        logger.info(
            "Wrote %s results to '%s'",
            args.output_format.upper(),
            args.output_file,
        )

    # check if any verification failed
    if args.verification_mode != "none":
        verification_failed = any(
            output.verification and not output.verification.passed for output in outputs
        )
        if verification_failed:
            logger.error("One or more operators failed verification.")
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
