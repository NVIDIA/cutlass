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

"""Output formatting for CUTLASS profiler."""

import csv
import enum
import io
import json
from pathlib import Path

import yaml

import cutlass

from cutlass.profiler.analysis import PerfMetrics
from cutlass.profiler.cli import get_dtype_name
from cutlass.profiler.operations.desc import (
    GemmProblemDesc,
    GroupedGemmProblemDesc,
)
from cutlass.profiler.profiling_results import ProfileResult

_PROBLEM_TYPES = (GemmProblemDesc, GroupedGemmProblemDesc)

_SIGNIFICANT_DIGITS = 6
"""Significant digits kept for every reported float.

Full repr adds noise without meaning -- a timing is not repeatable to
``1474.4288283400238`` ms. Six digits also keeps small values legible:
fixed-point CSV formatting used to round a 0.00108 GB/s result to ``0.001``
and a 0.000347 TFLOP/s result to ``0.00``.
"""


def _rounded(value: float) -> float:
    """Round a float to the reported precision, keeping it a number.

    YAML and JSON both render the result as a number, switching to scientific
    notation on their own when the magnitude calls for it.
    """
    return float(f"{value:.{_SIGNIFICANT_DIGITS}g}")


def _formatted(value: float) -> str:
    """Render a float for CSV, using scientific notation when needed."""
    return f"{value:.{_SIGNIFICANT_DIGITS}g}"


def _scientific(value: float) -> str:
    """Render a float in scientific notation at the reported precision."""
    return f"{value:.{_SIGNIFICANT_DIGITS - 1}e}"


_SCIENTIFIC_FIELDS = frozenset(
    {
        "max_abs_error",
        "max_rel_error",
        "bandwidth_gb_per_sec",
        "bandwidth_gib_per_sec",
        "flop_count",
    }
)
"""Fields always reported in scientific notation.

Errors, bandwidths, and FLOP counts span many orders of magnitude between
runs, so a fixed exponent form keeps them comparable at a glance. ``%g`` would
instead flip between ``0.00108357`` and ``1.08357e-09`` depending on the
magnitude, and would print a FLOP count as ``17592186044416``.

``flop_count`` is therefore reported to six significant digits rather than
exactly; the exact value is ``2 * M * N * K * L`` from the same record.
``total_bytes`` stays an exact integer.
"""


class _Scientific(float):
    """A float that YAML renders in scientific notation.

    Only the rendering differs: the value is an ordinary float, and YAML reads
    it back as one. ``json.dumps`` ignores a subclass ``__repr__``, so JSON
    keeps the plain number -- the same value, rendered by the json module.
    """

    def __new__(cls, value: float) -> "_Scientific":
        """Round on construction so every format reports the same value."""
        return super().__new__(cls, _rounded(value))

    def __repr__(self) -> str:
        """Return the scientific-notation spelling."""
        return _scientific(self)

    __str__ = __repr__


def _represent_scientific(dumper: yaml.Dumper, data: _Scientific) -> yaml.Node:
    """Emit a ``_Scientific`` as a YAML float scalar rather than a string."""
    return dumper.represent_scalar("tag:yaml.org,2002:float", _scientific(data))


yaml.SafeDumper.add_representer(_Scientific, _represent_scientific)


def _as_scientific(record: dict[str, object]) -> dict[str, object]:
    """Mark the scientific-notation fields of one record before dumping.

    Applied on the way out rather than in ``_result_data`` so that records
    reloaded from an existing file during ``--append`` are rendered the same
    way as freshly formatted ones.
    """
    return {
        key: _Scientific(value)
        if key in _SCIENTIFIC_FIELDS and isinstance(value, (int, float))
        else value
        for key, value in record.items()
    }


def _scale_dtype_name(dtype: type[cutlass.Numeric] | None) -> str:
    """Return the CLI spelling for an optional scale-factor dtype."""
    return get_dtype_name(dtype, scale_factor=True) if dtype is not None else ""


def _optional_enum_str(value: enum.Enum | None) -> str:
    """Return an enum's display spelling, or an empty string when absent."""
    return str(value) if value is not None else ""


def _common_gemm_fields(
    problem: GemmProblemDesc | GroupedGemmProblemDesc,
) -> dict[str, str | int]:
    """Return the problem-spec fields shared by dense and grouped GEMM."""
    return {
        "M": problem.M,
        "N": problem.N,
        "K": problem.K,
        "layout": problem.layout,
        "a_dtype": get_dtype_name(problem.a_dtype),
        "b_dtype": get_dtype_name(problem.b_dtype),
        "out_dtype": get_dtype_name(problem.out_dtype),
    }


def _result_data(
    output: ProfileResult,
) -> dict[str, str | int | float | bool | list[int]]:
    """Convert one result to the canonical machine-readable schema."""
    metrics = output.metrics
    data: dict[str, str | int | float | bool | list[int]] = {
        "problem_id": output.problem_id,
        "provider": output.provider_name,
        "operation_kind": output.operation_kind,
        "operator_name": output.operator_name,
        "cmd": output.cmd,
    }

    # Problem spec.
    problem = output.problem
    if isinstance(problem, GemmProblemDesc):
        data.update(_common_gemm_fields(problem))
        data["L"] = problem.L
        if problem.ab_scale_dtype is not None:
            data["ab_scale_dtype"] = _scale_dtype_name(problem.ab_scale_dtype)
            data["ab_scale_mode"] = _optional_enum_str(problem.ab_scale_mode)
            data["ab_scale_swizzle"] = _optional_enum_str(problem.ab_scale_swizzle)
    elif isinstance(problem, GroupedGemmProblemDesc):
        data.update(_common_gemm_fields(problem))
        data["offsets"] = list(problem.offsets)
        data["offsets_along"] = problem.offsets_along

    # Correctness: run status, verification result, and timing.
    data["status"] = output.status.value
    if output.verification is not None:
        data["verified"] = output.verification.passed
        data["max_abs_error"] = _rounded(output.verification.max_abs_error)
        data["max_rel_error"] = _rounded(output.verification.max_rel_error)
    data["test_elapsed_ms"] = _rounded(output.test_time_elapsed_ms)

    # Performance metrics. total_bytes stays exact; the rest are rounded.
    data["operator_runtime_ms"] = _rounded(metrics.operator_runtime_ms)
    data["total_bytes"] = metrics.total_bytes
    if metrics.tflop_per_sec is not None:
        data["tflop_per_sec"] = _rounded(metrics.tflop_per_sec)
    if metrics.flop_per_byte is not None:
        data["flop_per_byte"] = _rounded(metrics.flop_per_byte)
    if isinstance(metrics, PerfMetrics):
        # Rounded here, not just in _as_scientific, so JSON carries the same
        # value YAML renders as 2.09715e+06 rather than the exact integer.
        data["flop_count"] = _rounded(metrics.flop_count)
        data["bandwidth_gb_per_sec"] = _rounded(metrics.bandwidth_gb_per_sec)
        data["bandwidth_gib_per_sec"] = _rounded(metrics.bandwidth_gib_per_sec)

    return data


def format_json(output: ProfileResult) -> str:
    """Format one profile result as JSON."""
    return json.dumps(_result_data(output), indent=2)


def format_yaml(outputs: list[ProfileResult]) -> str:
    """Format each profiling output as an explicit YAML document."""
    records = [_as_scientific(_result_data(output)) for output in outputs]
    return yaml.safe_dump_all(
        records, explicit_start=True, sort_keys=False, width=float("inf")
    ).rstrip()


def format_csv(outputs: list[ProfileResult]) -> str:
    """Format profiling outputs with the canonical profiler CSV schema."""
    return format_results_csv(outputs)


def format_output(outputs: list[ProfileResult], format: str = "yaml") -> str:
    """Format profiling outputs using the requested output format."""
    if format == "yaml":
        return format_yaml(outputs)
    if format == "json":
        records = [_result_data(output) for output in outputs]
        data = records[0] if len(records) == 1 else records
        return json.dumps(data, indent=2)
    if format == "csv":
        return format_csv(outputs)
    raise ValueError(f"Unsupported format: {format}. Use yaml, json, or csv.")


# Column order follows the C++ profiler; the metric columns are named for their
# units instead, so a CSV run and a YAML run of the same command report the same
# numbers (the C++ spellings "Flops" and "GFLOPs" read as counts and disagree
# with the TFLOP/s reported everywhere else here).
_CSV_COLUMNS = [
    "Problem",
    "Provider",
    "OperationKind",
    "Operation",
    "Command",
    "M",
    "N",
    "K",
    "L",
    "layout",
    "A_dtype",
    "B_dtype",
    "out_dtype",
    "offsets",
    "offsets_along",
    "AB_scale_dtype",
    "AB_scale_mode",
    "AB_scale_swizzle",
    "Status",
    "Verified",
    "MaxAbsErr",
    "MaxRelErr",
    "TestElapsed",
    "OperatorRuntime",
    "Bytes",
    "FlopCount",
    "Flop/Byte",
    "GB/s",
    "TFLOP/s",
]


def _output_to_csv_row(output: ProfileResult) -> list[str]:
    """Convert a ProfileResult to a CSV row matching _CSV_COLUMNS."""
    problem = output.problem if isinstance(output.problem, _PROBLEM_TYPES) else None
    metrics = output.metrics
    perf_metrics = metrics if isinstance(metrics, PerfMetrics) else None
    offsets = (
        ";".join(str(value) for value in problem.offsets)
        if isinstance(problem, GroupedGemmProblemDesc)
        else ""
    )
    verification = output.verification
    return [
        str(output.problem_id),
        output.provider_name,
        output.operation_kind,
        output.operator_name,
        output.cmd,
        str(problem.M) if problem is not None else "",
        str(problem.N) if problem is not None else "",
        str(problem.K) if problem is not None else "",
        str(problem.L) if isinstance(problem, GemmProblemDesc) else "",
        problem.layout if problem is not None else "",
        get_dtype_name(problem.a_dtype) if problem is not None else "",
        get_dtype_name(problem.b_dtype) if problem is not None else "",
        get_dtype_name(problem.out_dtype) if problem is not None else "",
        offsets,
        problem.offsets_along if isinstance(problem, GroupedGemmProblemDesc) else "",
        _scale_dtype_name(problem.ab_scale_dtype)
        if isinstance(problem, GemmProblemDesc)
        else "",
        _optional_enum_str(problem.ab_scale_mode)
        if isinstance(problem, GemmProblemDesc)
        else "",
        _optional_enum_str(problem.ab_scale_swizzle)
        if isinstance(problem, GemmProblemDesc)
        else "",
        output.status.value,
        str(verification.passed) if verification is not None else "",
        _scientific(verification.max_abs_error) if verification is not None else "",
        _scientific(verification.max_rel_error) if verification is not None else "",
        _formatted(output.test_time_elapsed_ms),
        _formatted(metrics.operator_runtime_ms),
        str(metrics.total_bytes),
        _scientific(perf_metrics.flop_count) if perf_metrics is not None else "",
        _formatted(metrics.flop_per_byte) if metrics.flop_per_byte is not None else "",
        _scientific(perf_metrics.bandwidth_gb_per_sec)
        if perf_metrics is not None
        else "",
        _formatted(metrics.tflop_per_sec) if metrics.tflop_per_sec is not None else "",
    ]


def format_results_csv(outputs: list[ProfileResult]) -> str:
    """Format results as CSV string with C++ profiler-style columns."""
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(_CSV_COLUMNS)
    for output in outputs:
        writer.writerow(_output_to_csv_row(output))
    return buffer.getvalue().rstrip("\r\n")


def _as_result_records(data: object, output_format: str) -> list[dict[str, object]]:
    """Normalize one formatted result document to a list of records."""
    if isinstance(data, dict):
        return [data]
    if isinstance(data, list) and all(isinstance(record, dict) for record in data):
        return data
    raise ValueError(
        f"Cannot append {output_format} output that is not a result mapping or sequence"
    )


def _append_structured_output(
    existing_output: str, new_output: str, output_format: str
) -> str:
    """Merge JSON or YAML result documents into one valid result stream."""
    if output_format == "json":
        existing_data = json.loads(existing_output)
        new_data = json.loads(new_output)
        records = _as_result_records(existing_data, output_format)
        records.extend(_as_result_records(new_data, output_format))
        return json.dumps(records, indent=2)

    records: list[dict[str, object]] = []
    for document in yaml.safe_load_all(existing_output):
        records.extend(_as_result_records(document, output_format))
    for document in yaml.safe_load_all(new_output):
        records.extend(_as_result_records(document, output_format))
    return yaml.safe_dump_all(
        [_as_scientific(record) for record in records],
        explicit_start=True,
        sort_keys=False,
        width=float("inf"),
    ).rstrip()


def _append_csv_output(existing_output: str, new_output: str) -> str:
    """Append CSV data rows while retaining exactly one compatible header."""
    existing_rows = list(csv.reader(io.StringIO(existing_output)))
    new_rows = list(csv.reader(io.StringIO(new_output)))
    if not existing_rows or not new_rows:
        raise ValueError("Cannot append empty CSV output")
    if existing_rows[0] != new_rows[0]:
        raise ValueError("Cannot append CSV output with a different header")

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerows([*existing_rows, *new_rows[1:]])
    return buffer.getvalue().rstrip("\r\n")


def _append_formatted_output(
    existing_output: str, new_output: str, output_format: str
) -> str:
    """Append formatted output while preserving a valid document."""
    if output_format in ("yaml", "json"):
        return _append_structured_output(existing_output, new_output, output_format)
    if output_format == "csv":
        return _append_csv_output(existing_output, new_output)
    raise ValueError(f"Unsupported format: {output_format}. Use yaml, json, or csv.")


def write_output_file(
    output: str,
    filepath: str,
    output_format: str,
    append: bool = False,
) -> None:
    """Write formatted profiler results to a file.

    Args:
        output (str): Formatted results emitted to standard output.
        filepath (str): Exact path of the output file.
        output_format (str): Output format: ``yaml``, ``json``, or ``csv``.
        append (bool): Whether to merge results with an existing output file.

    Raises:
        ValueError: If output is empty, has an unsupported format, or cannot be
            appended to the existing document.
        RuntimeError: If the requested output file is not created or is empty.
    """
    formatted_output = output.rstrip("\r\n")
    if not formatted_output:
        raise ValueError("Cannot write empty profiler output")

    filepath_obj = Path(filepath)
    if append and filepath_obj.exists() and filepath_obj.stat().st_size > 0:
        existing_output = filepath_obj.read_text(encoding="utf-8").rstrip("\r\n")
        formatted_output = _append_formatted_output(
            existing_output, formatted_output, output_format
        )
    elif output_format not in ("yaml", "json", "csv"):
        raise ValueError(
            f"Unsupported format: {output_format}. Use yaml, json, or csv."
        )

    with filepath_obj.open("w", encoding="utf-8", newline="") as output_file:
        output_file.write(formatted_output)
        output_file.write("\n")

    if not filepath_obj.exists():
        raise RuntimeError(f"Failed to create output file: {filepath_obj}")
    if filepath_obj.stat().st_size == 0:
        raise RuntimeError(f"Output file is empty: {filepath_obj}")
