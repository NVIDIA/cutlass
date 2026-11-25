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

"""Unit tests for cutlass_profiler core logic (CPU-only, no GPU required)."""

import argparse
import ast
import csv
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from types import SimpleNamespace

import pytest
import torch
import yaml

import cutlass

import cutlass.operators as ops
import cutlass.profiler
import cutlass.profiler.__main__ as profiler_main
import cutlass.profiler.operations.base as operation_base
import cutlass.profiler.operations.gemm as gemm_operation
import cutlass.profiler.operations.grouped_gemm as grouped_gemm_operation
import cutlass.profiler.timing as profiler_timing
from cutlass.operators.arguments import GemmProblemSize, IndexPtrGroupedGemmProblemSize
from cutlass.operators.heuristics import available_heuristics
from cutlass.profiler.__main__ import parse_commandline, sort_results
from cutlass.profiler.analysis import (
    PerfMetrics,
    ReferenceTolerances,
    VerificationResult,
    compute_reference_grouped_gemm,
    compute_reference_scaled_gemm,
    gemm_reference_tolerances,
    grouped_gemm_reference_tolerances,
    reference_tolerances,
    verify_gemm,
    verify_grouped_gemm,
)
from cutlass.profiler.cli import (
    DTYPE_TO_STR_MAP,
    STR_TO_DTYPE_MAP,
    add_common_cli_args,
    get_dtype_name,
    parse_dimension,
    parse_dtype,
    parse_grouped_extents,
    parse_scale_mode,
    parse_scale_swizzle,
    parse_target_sm,
)
from cutlass.profiler.cli_reflection.registry import register_design
from cutlass.profiler.formatters import (
    format_csv,
    format_json,
    format_output,
    format_results_csv,
    format_yaml,
    write_output_file,
)
from cutlass.profiler.operations import OPERATIONS, register_operation
from cutlass.profiler.operations.desc import GemmProblemDesc, GroupedGemmProblemDesc
from cutlass.profiler.operations.gemm import make_gemm_arguments
from cutlass.profiler.operations.grouped_gemm import make_grouped_gemm_arguments
from cutlass.profiler.operations.operand_factory import (
    _low_variance_range,
    initialize_tensor,
    runtime_operand_nbytes,
    tensor_from_dtype,
)
from cutlass.profiler.profiling_results import (
    ProfileResult,
    ProfileStatus,
)
from cutlass.profiler.timing import (
    BenchmarkOptions,
    _get_tensor_bytes,
    benchmark_operator,
    resolve_benchmark_options,
)

# ── package layout ───────────────────────────────────────────────────────────


class TestPackageIndependence:
    """cutlass_profiler ships in the wheel; test/ does not."""

    def test_package_does_not_import_from_the_test_tree(self):
        """An import from test/ resolves under pytest and fails for the CLI.

        pytest puts test/ on sys.path (pyproject's ``pythonpath``), but the
        wheel packages only ``cutlass`` and its subpackages. A helper
        imported from test/ would therefore pass CI and raise ImportError for
        anyone running the installed profiler, so the package must restate
        what it needs instead of importing across that boundary.
        """
        package_root = Path(cutlass.profiler.__file__).resolve().parent
        test_root = Path(__file__).resolve().parents[1]
        importable_from_test_tree = {
            path.stem if path.suffix == ".py" else path.name
            for path in test_root.iterdir()
            if not path.name.startswith((".", "__"))
        }
        assert "test_utils" in importable_from_test_tree, (
            "expected test/test_utils to exist; the guard would be vacuous"
        )

        offenders = []
        for source in sorted(package_root.rglob("*.py")):
            for node in ast.walk(ast.parse(source.read_text())):
                if isinstance(node, ast.Import):
                    imported = [(alias.name, 0) for alias in node.names]
                elif isinstance(node, ast.ImportFrom):
                    imported = [(node.module or "", node.level)]
                else:
                    continue
                for module, level in imported:
                    # Relative imports stay inside cutlass.profiler by construction.
                    if level == 0 and module.split(".")[0] in importable_from_test_tree:
                        relative = source.relative_to(package_root)
                        offenders.append(f"{relative}:{node.lineno} imports {module}")

        assert not offenders, (
            "cutlass_profiler must not import from the test tree: "
            + "; ".join(offenders)
        )


# ── cli.py ────────────────────────────────────────────────────────────────


class TestPublicApi:
    def test_exports_only_entrypoint_and_extension_points(self):
        assert cutlass.profiler.__all__ == [
            "main",
            "OperationProfiler",
            "register_design",
            "register_operation",
        ]
        assert callable(cutlass.profiler.main)
        assert cutlass.profiler.OperationProfiler is operation_base.OperationProfiler
        assert cutlass.profiler.register_design is register_design
        assert cutlass.profiler.register_operation is register_operation

    def test_import_does_not_require_torch(self):
        subprocess.run(
            [
                sys.executable,
                "-c",
                (
                    "import sys\n"
                    "import cutlass.profiler\n"
                    "assert 'torch' not in sys.modules\n"
                ),
            ],
            cwd=Path(__file__).parents[2],
            check=True,
            capture_output=True,
            text=True,
        )


class TestParseDimension:
    def test_range_with_step(self):
        assert parse_dimension("512:2048:512") == [512, 1024, 1536, 2048]

    def test_range_without_step(self):
        result = parse_dimension("10:13")
        assert result == [10, 11, 12, 13]

    def test_single_value(self):
        assert parse_dimension("1024") == [1024]

    def test_comma_separated_values(self):
        assert parse_dimension("128, 1024,2048") == [128, 1024, 2048]

    def test_malformed_comma_separated_values_raise(self):
        with pytest.raises(ValueError, match="Invalid dimension"):
            parse_dimension("128,,1024")

    def test_malformed_raises(self):
        with pytest.raises(ValueError, match="Invalid dimension"):
            parse_dimension("1:2:3:4")

    @pytest.mark.parametrize("value", ["0", "-1", "4:1", "1:4:0"])
    def test_non_positive_or_empty_dimensions_raise(self, value):
        with pytest.raises(ValueError, match="dimension|Dimensions"):
            parse_dimension(value)


class TestGetDtypeName:
    def test_round_trip_canonical_spellings(self):
        for dtype, name in DTYPE_TO_STR_MAP.items():
            assert STR_TO_DTYPE_MAP[name] is dtype
            assert get_dtype_name(dtype) == name

    def test_parse_dtype_returns_cutlass_numeric_type(self):
        assert parse_dtype("f16") is cutlass.Float16

    def test_parse_dtype_rejects_unknown_name(self):
        with pytest.raises(ValueError, match="Unsupported dtype"):
            parse_dtype("unknown")

    def test_forward_only_alias_is_ue4m3(self):
        # Every forward-only spelling must be a deliberate alias.
        assert set(STR_TO_DTYPE_MAP) - set(DTYPE_TO_STR_MAP.values()) == {"ue4m3"}
        assert STR_TO_DTYPE_MAP["ue4m3"] is cutlass.Float8E4M3FN
        assert STR_TO_DTYPE_MAP["e4m3"] is cutlass.Float8E4M3FN

    def test_scale_factor_recovers_ue4m3(self):
        assert get_dtype_name(cutlass.Float8E4M3FN) == "e4m3"
        assert get_dtype_name(cutlass.Float8E4M3FN, scale_factor=True) == "ue4m3"

    def test_scale_factor_does_not_change_unique_scale_types(self):
        assert get_dtype_name(cutlass.Float8E8M0FNU, scale_factor=True) == "ue8m0"

    def test_unregistered_dtype_raises(self):
        with pytest.raises(ValueError, match="No profiler dtype name is registered"):
            get_dtype_name(cutlass.Float64)


class TestCommonCliArgs:
    def test_provider_parser_returns_registered_provider_type(self):
        parser = argparse.ArgumentParser()
        add_common_cli_args(parser)

        args = parser.parse_args(["--provider", "cutedsl"])

        assert args.provider is ops.available_providers["cutedsl"]

    def test_provider_parser_rejects_unknown_name(self):
        parser = argparse.ArgumentParser()
        add_common_cli_args(parser)
        with pytest.raises(SystemExit):
            parser.parse_args(["--provider", "unknown"])


class TestInitializeTensor:
    def test_constant(self):
        t = initialize_tensor((3, 4), torch.float32, "cpu", "constant:7.0")
        assert t.shape == (3, 4)
        assert torch.all(t == 7.0)

    def test_unknown_type_raises(self):
        with pytest.raises(ValueError, match="Unknown initialization type"):
            initialize_tensor((2,), torch.float32, "cpu", "bogus:1")

    def test_invalid_format_raises(self):
        with pytest.raises(ValueError, match="Invalid initialization format"):
            initialize_tensor((2,), torch.float32, "cpu", "nocolon")


class TestAutoInitialization:
    """The dtype-derived low-variance scheme the default tolerances assume."""

    @pytest.mark.parametrize(
        ("dtype", "out_dtype", "expected"),
        [
            # Wide float operands and output: {-2, -1, 0, 1, 2}.
            (cutlass.Float32, cutlass.Float32, (-2, 3, 1.0)),
            (cutlass.Float16, cutlass.Float32, (-2, 3, 1.0)),
            # A narrow operand *or* a narrow output halves the range.
            (cutlass.Float8E4M3FN, cutlass.Float32, (-2, 3, 0.5)),
            (cutlass.Float32, cutlass.Float8E4M3FN, (-2, 3, 0.5)),
            # Integers narrow the range itself rather than scaling it.
            (cutlass.Int32, cutlass.Float32, (-2, 3, 1.0)),
            (cutlass.Int8, cutlass.Float32, (-1, 2, 1.0)),
            # Unsigned integers start at zero.
            (cutlass.Uint8, cutlass.Float32, (0, 2, 1.0)),
        ],
    )
    def test_range_matches_operand_and_output_width(self, dtype, out_dtype, expected):
        value_range = _low_variance_range(dtype, out_dtype)
        assert (
            value_range.min_val,
            value_range.max_val,
            value_range.global_scale,
        ) == expected

    def test_values_are_exact_powers_of_two(self):
        """Every drawn value must be exactly representable, or the derived
        tolerances (which assume exact accumulation) are unsound."""
        tensor = tensor_from_dtype(
            (64, 64),
            cutlass.Float32,
            "auto",
            "cpu",
            out_dtype=cutlass.Float8E4M3FN,
        )
        assert set(tensor.unique().tolist()) <= {-1.0, -0.5, 0.0, 0.5, 1.0}

    def test_wide_dtypes_draw_small_integers(self):
        tensor = tensor_from_dtype(
            (64, 64), cutlass.Float32, "auto", "cpu", out_dtype=cutlass.Float32
        )
        assert set(tensor.unique().tolist()) <= {-2.0, -1.0, 0.0, 1.0, 2.0}

    def test_auto_requires_out_dtype(self):
        with pytest.raises(ValueError, match="requires out_dtype"):
            tensor_from_dtype((4, 4), cutlass.Float32, "auto", "cpu")


# ── analysis.py ──────────────────────────────────────────────────────────────


class TestPerfMetrics:
    def test_throughput_uses_supplied_flop_count(self):
        metrics = PerfMetrics.from_workload(
            operator_runtime_ms=0.1,
            flop_count=1_000_000,
            total_bytes=4096,
        )
        assert metrics.tflop_per_sec == pytest.approx(1e-2)
        assert metrics.flop_count == 1_000_000

    def test_arithmetic_intensity_uses_supplied_bytes(self):
        metrics = PerfMetrics.from_workload(
            operator_runtime_ms=0.01,
            flop_count=2048,
            total_bytes=512,
        )
        assert metrics.flop_per_byte == 4.0

    def test_zero_time_returns_zero_rates(self):
        metrics = PerfMetrics.from_workload(
            operator_runtime_ms=0.0,
            flop_count=1024,
            total_bytes=1024,
        )
        assert metrics.tflop_per_sec == 0.0
        assert metrics.bandwidth_gb_per_sec == 0.0
        assert metrics.bandwidth_gib_per_sec == 0.0

    def test_bandwidth_uses_supplied_byte_count(self):
        metrics = PerfMetrics.from_workload(
            operator_runtime_ms=1000.0,
            flop_count=0,
            total_bytes=1_000_000_000,
        )
        assert metrics.bandwidth_gb_per_sec == pytest.approx(1.0)
        assert metrics.bandwidth_gib_per_sec == pytest.approx(1_000_000_000 / 2**30)

    @pytest.mark.parametrize(
        ("kwargs", "match"),
        [
            (
                {"operator_runtime_ms": -1.0, "flop_count": 0, "total_bytes": 0},
                "operator_runtime_ms",
            ),
            (
                {"operator_runtime_ms": 1.0, "flop_count": -1, "total_bytes": 0},
                "flop_count",
            ),
            (
                {"operator_runtime_ms": 1.0, "flop_count": 0, "total_bytes": -1},
                "total_bytes",
            ),
        ],
    )
    def test_negative_workload_values_raise(self, kwargs, match):
        with pytest.raises(ValueError, match=match):
            PerfMetrics.from_workload(**kwargs)


# ── formatters.py ────────────────────────────────────────────────────────────


@dataclass
class BasicMetrics:
    """Metrics for an operation without a defined FLOP count."""

    operator_runtime_ms: float
    total_bytes: int
    tflop_per_sec: float | None = None
    flop_per_byte: float | None = None


def _make_output(
    *,
    operation_kind: str = "gemm",
    offsets: tuple[int, ...] | None = None,
    M: int = 128,
    N: int = 128,
    K: int = 64,
    offsets_along: str = "m",
    metrics: PerfMetrics | None = None,
    scaled: bool = False,
) -> ProfileResult:
    """Create a GEMM profiling result with reasonable defaults."""
    if metrics is None:
        metrics = PerfMetrics(
            operator_runtime_ms=0.01,
            flop_count=10_000_000,
            total_bytes=1024,
        )
    if offsets is None:
        problem = GemmProblemDesc(
            M=M,
            N=N,
            K=K,
            L=1,
            a_dtype=cutlass.Float16,
            b_dtype=cutlass.Float16,
            out_dtype=cutlass.Float16,
            ab_scale_dtype=cutlass.Float8E8M0FNU if scaled else None,
            ab_scale_mode=ops.ScaleMode.Blockwise1x32 if scaled else None,
            ab_scale_swizzle=(ops.ScaleSwizzleMode.SwizzleNone if scaled else None),
        )
    else:
        problem = GroupedGemmProblemDesc(
            M=M,
            N=N,
            K=K,
            offsets=offsets,
            offsets_along=offsets_along,
            a_dtype=cutlass.Float16,
            b_dtype=cutlass.Float16,
            out_dtype=cutlass.Float16,
        )
    return ProfileResult(
        operator_name="test_operator",
        provider=ops.available_providers["cutedsl"],
        operation_kind=operation_kind,
        problem_id=0,
        status=ProfileStatus.SUCCESS,
        metrics=metrics,
        cmd="cutlass_profiler run --operation gemm",
        test_time_elapsed_ms=1.25,
        problem=problem,
    )


class TestProfileResultParsing:
    def test_profile_status_preserves_string_behavior(self):
        status = ProfileStatus.SUCCESS

        assert isinstance(status, str)
        assert status == "Success"
        assert str(status) == "Success"

    def test_parse_converts_provider_and_status_strings(self):
        source = _make_output()
        result = ProfileResult.parse(
            operator_name=source.operator_name,
            provider="cutedsl",
            operation_kind=source.operation_kind,
            problem_id=source.problem_id,
            status="Success",
            metrics=source.metrics,
            cmd=source.cmd,
            test_time_elapsed_ms=source.test_time_elapsed_ms,
            problem=source.problem,
        )
        assert result.provider is ops.available_providers["cutedsl"]
        assert result.status is ProfileStatus.SUCCESS
        assert result.problem is source.problem

    def test_parse_rejects_unknown_provider(self):
        with pytest.raises(ValueError, match="Unknown provider"):
            ProfileResult.parse(
                operator_name="operator",
                provider="unknown",
                operation_kind="gemm",
                problem_id=1,
                status="Success",
                metrics=_make_output().metrics,
                cmd="cutlass_profiler run --operation gemm",
                test_time_elapsed_ms=1.0,
            )

    def test_parse_rejects_unknown_status(self):
        with pytest.raises(ValueError, match="Unknown profile status"):
            ProfileResult.parse(
                operator_name="operator",
                provider="cutedsl",
                operation_kind="gemm",
                problem_id=1,
                status="Unknown",
                metrics=_make_output().metrics,
                cmd="cutlass_profiler run --operation gemm",
                test_time_elapsed_ms=1.0,
            )


class TestFormatJson:
    def test_valid_json_with_required_fields(self):
        out = _make_output()
        parsed = json.loads(format_json(out))
        for key in [
            "problem_id",
            "provider",
            "operation_kind",
            "operator_name",
            "cmd",
            "status",
            "operator_runtime_ms",
            "test_elapsed_ms",
            "tflop_per_sec",
            "flop_count",
            "bandwidth_gb_per_sec",
        ]:
            assert key in parsed
        assert parsed["operator_name"] == "test_operator"
        assert parsed["operator_runtime_ms"] == 0.01
        assert parsed["test_elapsed_ms"] == 1.25
        assert parsed["cmd"].startswith("cutlass_profiler")
        assert "math_utilization_percent" not in parsed
        assert "memory_utilization_percent" not in parsed

    def test_grouped_shape_and_operation_kind(self):
        parsed = json.loads(
            format_json(
                _make_output(
                    operation_kind="grouped_gemm",
                    offsets=(16, 48, 112),
                    M=112,
                )
            )
        )
        assert parsed["operation_kind"] == "grouped_gemm"
        assert parsed["M"] == 112
        assert parsed["offsets"] == [16, 48, 112]
        assert parsed["offsets_along"] == "m"
        assert "L" not in parsed

    def test_float_metrics_are_rounded_but_stay_numbers(self):
        """Six significant digits, still parsed as numbers rather than strings."""
        output = _make_output(
            metrics=PerfMetrics.from_workload(
                operator_runtime_ms=1474.4288283400238,
                flop_count=2_097_152,
                total_bytes=65_536,
            )
        )

        parsed = json.loads(format_json(output))
        assert parsed["operator_runtime_ms"] == 1474.43
        assert parsed["tflop_per_sec"] == 1.42235e-06
        assert all(
            isinstance(parsed[key], float)
            for key in ("operator_runtime_ms", "tflop_per_sec", "bandwidth_gb_per_sec")
        )
        # flop_count is reported to six significant digits like the other
        # wide-range metrics; 2 * M * N * K * L in the same record is exact.
        assert parsed["flop_count"] == 2_097_150.0
        assert parsed["total_bytes"] == 65_536

    def test_shared_ab_scale_fields(self):
        output = _make_output(scaled=True)
        parsed = json.loads(format_json(output))
        assert parsed["ab_scale_dtype"] == "ue8m0"
        assert parsed["ab_scale_mode"] == "1x32"
        assert parsed["ab_scale_swizzle"] == "none"

        header, row = (line.split(",") for line in format_csv([output]).splitlines())
        values = dict(zip(header, row, strict=True))
        assert values["AB_scale_dtype"] == "ue8m0"
        assert values["AB_scale_mode"] == "1x32"
        assert values["AB_scale_swizzle"] == "none"


class TestFormatYaml:
    def test_default_output_uses_yaml_schema(self):
        parsed = yaml.safe_load(format_output([_make_output()]))
        assert parsed["problem_id"] == 0
        assert parsed["operator_name"] == "test_operator"
        assert parsed["operator_runtime_ms"] == 0.01
        assert parsed["test_elapsed_ms"] == 1.25
        assert parsed["cmd"].startswith("cutlass_profiler")

    def test_wide_range_fields_use_scientific_notation(self):
        """These span many orders of magnitude, so pin the exponent form."""
        output = _make_output(
            metrics=PerfMetrics.from_workload(
                operator_runtime_ms=60.481536865234375,
                flop_count=2_097_152,
                total_bytes=65_536,
            )
        )
        output.verification = VerificationResult(
            passed=True,
            max_abs_error=0.001953125,
            max_rel_error=0.003355685854330659,
        )

        rendered = format_yaml([output])

        assert "max_abs_error: 1.95312e-03" in rendered
        assert "max_rel_error: 3.35569e-03" in rendered
        assert "bandwidth_gb_per_sec: 1.08357e-03" in rendered
        assert "bandwidth_gib_per_sec: 1.00915e-03" in rendered
        assert "flop_count: 2.09715e+06" in rendered
        # Other floats keep the %g form, which only goes scientific when small.
        assert "test_elapsed_ms: 1.25" in rendered
        # total_bytes is the one count still reported exactly.
        assert "total_bytes: 65536" in rendered

        # Rendering only: they are still YAML floats, not quoted strings.
        document = yaml.safe_load(rendered)
        assert all(
            isinstance(document[field], float)
            for field in (
                "max_abs_error",
                "max_rel_error",
                "bandwidth_gb_per_sec",
                "bandwidth_gib_per_sec",
                "flop_count",
            )
        )
        assert document["bandwidth_gb_per_sec"] == 0.00108357

    def test_appended_yaml_keeps_scientific_notation(self, tmp_path):
        """Appending reloads earlier records, which must not revert to %g."""
        output_file = tmp_path / "results.yaml"
        write_output_file(format_yaml([_make_output()]), str(output_file), "yaml")
        write_output_file(
            format_yaml([_make_output()]), str(output_file), "yaml", append=True
        )

        bandwidths = [
            line
            for line in output_file.read_text().splitlines()
            if line.startswith("bandwidth_gb_per_sec:")
        ]
        assert len(bandwidths) == 2
        assert all("e+" in line or "e-" in line for line in bandwidths)

    def test_outputs_form_separate_yaml_documents(self):
        rendered = format_yaml([_make_output(), _make_output()])
        documents = list(yaml.safe_load_all(rendered))

        assert rendered.count("---\n") == 2
        assert len(documents) == 2
        assert all(isinstance(document, dict) for document in documents)


class TestFormatOutput:
    def test_single_output_is_dict(self):
        result = format_output([_make_output()], format="json")
        parsed = json.loads(result)
        assert isinstance(parsed, dict)

    def test_multiple_outputs_is_array(self):
        result = format_output([_make_output(), _make_output()], format="json")
        parsed = json.loads(result)
        assert isinstance(parsed, list)
        assert len(parsed) == 2

    @pytest.mark.parametrize("output_format", ["text", "xml"])
    def test_invalid_format_raises(self, output_format):
        with pytest.raises(ValueError, match="Unsupported format"):
            format_output([_make_output()], format=output_format)

    @pytest.mark.parametrize("output_format", ["yaml", "json", "csv"])
    def test_output_file_matches_standard_output(
        self, monkeypatch, capsys, tmp_path, output_format
    ):
        class StubOperation:
            def profile(self, args, on_result=None):
                outputs = [_make_output()]
                if on_result is not None:
                    on_result(outputs[0])
                return outputs

        output_file = tmp_path / f"results.{output_format}"
        args = SimpleNamespace(
            mode_name="run",
            operation_instance=StubOperation(),
            nsys=False,
            verbose=False,
            output_format=output_format,
            output_file=str(output_file),
            append=False,
            sort_results_flops_per_sec=False,
            sort_results_flops_per_byte=False,
            verification_mode="none",
        )
        monkeypatch.setattr(profiler_main, "parse_commandline", lambda argv: args)
        monkeypatch.setattr(profiler_main.torch.cuda, "is_available", lambda: True)

        assert profiler_main.main([]) == 0
        standard_output = capsys.readouterr().out
        assert standard_output.strip()
        assert output_file.read_bytes().decode() == standard_output

    def test_yaml_result_is_printed_before_profile_returns(self, monkeypatch):
        printed: list[str] = []
        results = [_make_output(), _make_output()]
        results[0].operator_name = "first_operator"
        results[1].operator_name = "second_operator"

        def record_print(output: str, *, flush: bool) -> None:
            assert flush
            printed.append(output)

        class StubOperation:
            def profile(self, args, on_result=None):
                assert on_result is not None
                for expected_count, result in enumerate(results, start=1):
                    on_result(result)
                    assert len(printed) == expected_count
                return results

        args = SimpleNamespace(
            mode_name="run",
            operation_instance=StubOperation(),
            nsys=False,
            output_format="yaml",
            output_file=None,
            sort_results_flops_per_sec=False,
            sort_results_flops_per_byte=False,
            verification_mode="none",
        )
        monkeypatch.setattr(profiler_main, "parse_commandline", lambda argv: args)
        monkeypatch.setattr(profiler_main.torch.cuda, "is_available", lambda: True)
        monkeypatch.setattr("builtins.print", record_print)

        assert profiler_main.main([]) == 0
        assert [
            list(yaml.safe_load_all(output))[0]["operator_name"] for output in printed
        ] == ["first_operator", "second_operator"]

    @pytest.mark.parametrize("output_format", ["yaml", "json", "csv"])
    def test_append_preserves_valid_output_file(self, tmp_path, output_format):
        first_result = _make_output()
        second_result = _make_output()
        second_result.problem_id = 1
        output_file = tmp_path / f"results.{output_format}"

        write_output_file(
            format_output([first_result], format=output_format),
            str(output_file),
            output_format,
        )
        write_output_file(
            format_output([second_result], format=output_format),
            str(output_file),
            output_format,
            append=True,
        )

        file_output = output_file.read_text()
        if output_format == "yaml":
            records = list(yaml.safe_load_all(file_output))
        elif output_format == "json":
            records = json.loads(file_output)
        else:
            records = list(csv.DictReader(file_output.splitlines()))

        assert isinstance(records, list)
        problem_id_key = "Problem" if output_format == "csv" else "problem_id"
        assert [int(record[problem_id_key]) for record in records] == [0, 1]

    def test_write_output_file_rejects_empty_output(self, tmp_path):
        with pytest.raises(ValueError, match="empty profiler output"):
            write_output_file("", str(tmp_path / "results.yaml"), "yaml")

    def test_append_rejects_csv_header_mismatch(self, tmp_path):
        output_file = tmp_path / "results.csv"
        output_file.write_text("Problem,Value\n0,first\n")

        with pytest.raises(ValueError, match="different header"):
            write_output_file(
                "Other,Value\n1,second", str(output_file), "csv", append=True
            )


class TestFormatCsv:
    def test_header_and_row_count(self):
        outputs = [_make_output(), _make_output()]
        csv_str = format_csv(outputs)
        lines = csv_str.strip().split("\n")
        assert len(lines) == 3  # 1 header + 2 data rows
        assert lines[0].startswith("Problem,Provider,OperationKind,")
        assert "math_utilization_percent" not in lines[0]
        assert "memory_utilization_percent" not in lines[0]

    def test_dense_gemm_scale_fields_are_empty(self):
        header, row = csv.reader(format_results_csv([_make_output()]).splitlines())
        values = dict(zip(header, row, strict=True))
        assert {
            field: values[field]
            for field in ("AB_scale_dtype", "AB_scale_mode", "AB_scale_swizzle")
        } == {
            "AB_scale_dtype": "",
            "AB_scale_mode": "",
            "AB_scale_swizzle": "",
        }

    def test_small_metric_values_keep_significant_digits(self):
        """Fixed-point CSV formatting used to flatten sub-0.01 metrics to zero."""
        output = _make_output(
            metrics=PerfMetrics.from_workload(
                operator_runtime_ms=60.0,
                flop_count=2_097_152,
                total_bytes=65_536,
            )
        )

        header, row = csv.reader(format_results_csv([output]).splitlines())
        values = dict(zip(header, row, strict=True))
        # .2f and .3f rendered these as "0.00" and "0.001".
        assert values["TFLOP/s"] == "3.49525e-05"
        assert values["GB/s"] == "1.09227e-03"
        assert values["FlopCount"] == "2.09715e+06"

    def test_csv_quotes_commands_containing_commas(self):
        output = _make_output()
        output.cmd = (
            "cutlass_profiler run --operation gemm --A-dtype e4m3,e5m2 --M 64,128"
        )

        rows = list(csv.reader(format_output([output], format="csv").splitlines()))

        assert len(rows) == 2
        assert len(rows[1]) == len(rows[0])
        values = dict(zip(rows[0], rows[1], strict=True))
        assert values["Command"] == output.cmd

    def test_grouped_gemm_csv_uses_offsets_without_l(self):
        output = _make_output(
            operation_kind="grouped_gemm",
            offsets=(16, 48, 112),
            M=112,
        )
        for csv_text in (format_csv([output]), format_results_csv([output])):
            header, row = (line.split(",") for line in csv_text.splitlines())
            values = dict(zip(header, row, strict=True))
            assert values["L"] == ""
            assert values["offsets"] == "16;48;112"
            assert values["offsets_along"] == "m"


class TestGenericFormatting:
    def test_yaml_json_and_csv_accept_result_without_perf_metrics(self):
        result = ProfileResult(
            operator_name="custom_reduce",
            provider=ops.available_providers["cutedsl"],
            operation_kind="reduction",
            problem_id=7,
            status=ProfileStatus.SUCCESS,
            metrics=BasicMetrics(
                operator_runtime_ms=0.0125,
                total_bytes=2048,
            ),
            cmd="cutlass_profiler run --operation reduction",
            test_time_elapsed_ms=1.0,
        )
        parsed = json.loads(format_json(result))
        assert parsed["operation_kind"] == "reduction"
        assert "M" not in parsed
        assert "flop_count" not in parsed
        yaml_data = yaml.safe_load(format_output([result], format="yaml"))
        assert yaml_data["operation_kind"] == "reduction"
        assert yaml_data["total_bytes"] == 2048
        assert "M" not in yaml_data
        assert "flop_count" not in yaml_data
        header, row = csv.reader(format_results_csv([result]).splitlines())
        values = dict(zip(header, row, strict=True))
        assert values["Problem"] == "7"
        assert values["Operation"] == "custom_reduce"
        assert values["Status"] == "Success"
        assert values["Verified"] == ""


class TestSortResults:
    @pytest.mark.parametrize("metric_name", ["tflop_per_sec", "flop_per_byte"])
    def test_missing_flop_metric_raises_clear_error(self, metric_name):
        result = ProfileResult(
            operator_name="custom_reduce",
            provider=ops.available_providers["cutedsl"],
            operation_kind="reduction",
            problem_id=7,
            status=ProfileStatus.SUCCESS,
            metrics=BasicMetrics(
                operator_runtime_ms=0.0125,
                total_bytes=2048,
            ),
            cmd="cutlass_profiler run --operation reduction",
            test_time_elapsed_ms=1.0,
        )
        with pytest.raises(ValueError) as error:
            sort_results([result], metric_name)
        assert metric_name in str(error.value)
        assert "custom_reduce (reduction)" in str(error.value)

    def test_available_flop_metric_sorts_descending(self):
        slow_metrics = PerfMetrics.from_workload(
            operator_runtime_ms=0.02,
            flop_count=1024,
            total_bytes=512,
        )
        fast_metrics = PerfMetrics.from_workload(
            operator_runtime_ms=0.01,
            flop_count=1024,
            total_bytes=512,
        )
        slow = _make_output(metrics=slow_metrics)
        slow.operator_name = "slow"
        fast = _make_output(metrics=fast_metrics)
        fast.operator_name = "fast"
        outputs = [slow, fast]
        sort_results(outputs, "tflop_per_sec")
        assert [output.operator_name for output in outputs] == ["fast", "slow"]


# ── timing.py ────────────────────────────────────────────────────────────────


class TestGetTensorBytes:
    def test_pytorch_tensor(self):
        t = torch.zeros(10, 20, dtype=torch.float32)
        assert _get_tensor_bytes(t) == 10 * 20 * 4

    def test_cute_like_mock(self):
        """Mock a CuTe-style tensor with .shape and .element_type (no .nbytes)."""

        class FakeElementType:
            width = 16  # bits (fp16)

        class FakeCuteTensor:
            shape = (8, 16)
            element_type = FakeElementType()

        assert _get_tensor_bytes(FakeCuteTensor()) == 8 * 16 * 2

    def test_sub_byte_dtype(self):
        """fp4 (4 bits) should round up via ceiling division."""

        class FakeElementType:
            width = 4

        class FakeCuteTensor:
            shape = (3,)
            element_type = FakeElementType()

        # 3 elements * 4 bits = 12 bits => ceil(12/8) = 2 bytes
        assert _get_tensor_bytes(FakeCuteTensor()) == 2

    def test_unsupported_type_raises(self):
        with pytest.raises(TypeError, match="Unsupported tensor type"):
            _get_tensor_bytes("not a tensor")


class TestResolveBenchmarkOptions:
    def test_default_mode_disables_rotation_and_repeated_timing(self):
        options = resolve_benchmark_options(
            measure_performance=False,
            arg_bytes=1024,
            warmup_iterations=7,
            profiling_iterations=13,
            workspace_count=5,
        )
        assert options == BenchmarkOptions(
            arg_count=1,
            warmup_iterations=0,
            profiling_iterations=1,
        )

    def test_measure_performance_preserves_timing_and_rotation(self):
        options = resolve_benchmark_options(
            measure_performance=True,
            arg_bytes=1024,
            warmup_iterations=7,
            profiling_iterations=13,
            workspace_count=5,
        )
        assert options == BenchmarkOptions(
            arg_count=5,
            warmup_iterations=7,
            profiling_iterations=13,
        )

    @pytest.mark.parametrize(
        ("warmup_iterations", "profiling_iterations", "match"),
        [(-1, 1, "warmup_iterations"), (0, 0, "profiling_iterations")],
    )
    def test_rejects_invalid_iteration_counts(
        self, warmup_iterations, profiling_iterations, match
    ):
        with pytest.raises(ValueError, match=match):
            resolve_benchmark_options(
                measure_performance=True,
                arg_bytes=1024,
                warmup_iterations=warmup_iterations,
                profiling_iterations=profiling_iterations,
            )


class TestBenchmarkOperatorGuards:
    def test_existing_args_seed_factory_without_reallocation(self, monkeypatch):
        initial_args = object()
        expected_compiled_artifact = object()
        factory_calls = 0
        run_args = []

        class FakeOperator:
            def compile(self, operator_args):
                assert operator_args is initial_args
                return expected_compiled_artifact

            def get_workspace_size(self, operator_args):
                assert operator_args is initial_args
                return ops.workspace.AllocationRequirement.empty()

            def run(self, operator_args, *, compiled_artifact, stream, workspace):
                assert compiled_artifact is expected_compiled_artifact
                assert workspace is None
                run_args.append(operator_args)

        def arg_factory():
            nonlocal factory_calls
            factory_calls += 1
            return object()

        def fake_benchmark_direct(
            loop_fn, warmup_iterations, profiling_iterations, stream
        ):
            assert warmup_iterations == 0
            assert profiling_iterations == 1
            loop_fn(profiling_iterations, 0)
            return 12.5

        monkeypatch.setattr(profiler_timing, "_benchmark_direct", fake_benchmark_direct)

        time_us = benchmark_operator(
            operator=FakeOperator(),
            benchmark_options=BenchmarkOptions(
                arg_count=1,
                warmup_iterations=0,
                profiling_iterations=1,
            ),
            operator_args=initial_args,
            arg_factory=arg_factory,
            stream=object(),
        )

        assert time_us == 12.5
        assert factory_calls == 0
        assert run_args == [initial_args]

    @pytest.mark.parametrize(
        ("options", "match"),
        [
            (BenchmarkOptions(0, 0, 1), "arg_count"),
            (BenchmarkOptions(1, -1, 1), "warmup_iterations"),
            (BenchmarkOptions(1, 0, 0), "profiling_iterations"),
        ],
    )
    def test_invalid_benchmark_options_raise(self, options, match):
        with pytest.raises(ValueError, match=match):
            benchmark_operator(
                operator=object(),
                benchmark_options=options,
                operator_args=object(),
            )

    def test_no_args_raises(self):
        with pytest.raises(
            ValueError, match="must provide operator_args or arg_factory"
        ):
            benchmark_operator(
                operator=object(),
                benchmark_options=BenchmarkOptions(
                    arg_count=1,
                    warmup_iterations=10,
                    profiling_iterations=100,
                ),
            )

    def test_arg_count_gt1_without_generator_raises(self):
        with pytest.raises(ValueError, match="arg_count must be 1"):
            benchmark_operator(
                operator=object(),
                benchmark_options=BenchmarkOptions(
                    arg_count=2,
                    warmup_iterations=10,
                    profiling_iterations=100,
                ),
                operator_args=object(),
            )


# ── argument-oriented operation profiling ───────────────────────────────────


def _argument_namespace(**overrides) -> argparse.Namespace:
    values = {
        "A_dtype": cutlass.Float16,
        "B_dtype": cutlass.Float16,
        "out_dtype": cutlass.Float16,
        "accum_dtype": cutlass.Float32,
        "initialization": "constant:1",
        "AB_scale_dtype": None,
        "AB_scale_mode": None,
        "AB_scale_swizzle": None,
    }
    values.update(overrides)
    return argparse.Namespace(**values)


_MX_FP4_DTYPES_AVAILABLE = all(
    hasattr(torch, name)
    for name in ("float4_e2m1fn_x2", "float8_e8m0fnu", "float8_e4m3fn")
)


def _packed_fp4_ones(shape: tuple[int, ...]) -> torch.Tensor:
    """Return tightly packed FP4 storage whose logical elements are all one."""
    return torch.full(shape, 0x22, dtype=torch.uint8).view(torch.float4_e2m1fn_x2)


class TestArgumentOrientedProfiler:
    def test_operator_queries_pass_provider_type_through(self, monkeypatch):
        provider = ops.available_providers["cutedsl"]
        provider_calls: list[list[type[ops.Provider]]] = []
        metadata_filters = []

        def fake_get_operators(args=None, *, providers, metadata_filter=None, **kwargs):
            provider_calls.append(providers)
            metadata_filters.append(metadata_filter)
            return []

        monkeypatch.setattr(operation_base.ops, "get_operators", fake_get_operators)

        operators = operation_base.OperationProfiler._get_all_operators(
            object(),
            provider,
            parse_target_sm("100a"),
        )

        layouts = grouped_gemm_operation._resolve_layouts(
            ["auto"],
            "wanted*",
            provider,
            parse_target_sm("100a"),
            lambda metadata: metadata.design_matches,
        )

        assert operators == []
        assert layouts == ["ttt"]
        assert provider_calls == [[provider], [provider]]
        grouped_filter = metadata_filters[-1]
        assert grouped_filter(
            SimpleNamespace(operator_name="wanted", design_matches=True)
        )
        assert not grouped_filter(
            SimpleNamespace(operator_name="wanted", design_matches=False)
        )
        assert not grouped_filter(
            SimpleNamespace(operator_name="other", design_matches=True)
        )

    def test_builtin_operations_are_registered(self):
        assert {"gemm", "grouped_gemm"} <= set(OPERATIONS)

    def test_gemm_problem_sizes_include_all_l_values(self):
        profiler = OPERATIONS["gemm"]()
        sizes = profiler._get_problem_sizes(
            argparse.Namespace(M=[64], N=[32], K=[16], L=[1, 4])
        )
        assert sizes == [
            GemmProblemSize(64, 32, 16, 1),
            GemmProblemSize(64, 32, 16, 4),
        ]

    def test_gemm_argument_sweeps_form_cartesian_product(self):
        args = argparse.Namespace(
            A_dtype=[cutlass.Float8E4M3FN, cutlass.Float8E5M2],
            B_dtype=[cutlass.Float4E2M1FN, cutlass.Float8E4M3FN],
            out_dtype=[cutlass.Float16, cutlass.Float32],
            accum_dtype=[cutlass.Float16, cutlass.Float32],
            AB_scale_dtype=[cutlass.Float8E8M0FNU, cutlass.Float8E4M3FN],
            AB_scale_mode=[
                ops.ScaleMode.Blockwise1x16,
                ops.ScaleMode.Blockwise1x32,
            ],
            AB_scale_swizzle=ops.ScaleSwizzleMode.Swizzle32x4x4,
            cmd=(
                "cutlass_profiler run --operation gemm "
                "--M 64 --N 32 --K 16 --A-dtype e4m3,e5m2 "
                "--B-dtype e2m1,e4m3 --out-dtype f16,f32 "
                "--accum-dtype f16,f32 --layout tnt,ttt "
                "--AB-scale-dtype ue8m0,ue4m3 "
                "--AB-scale-mode 1x16,1x32"
            ),
        )

        configurations = gemm_operation._argument_configurations(args, ["tnt", "ttt"])

        assert len(configurations) == 128
        assert len({command for _, _, command in configurations}) == 128
        for concrete_args, layout, command in configurations:
            assert not isinstance(concrete_args.A_dtype, list)
            assert not isinstance(concrete_args.B_dtype, list)
            assert not isinstance(concrete_args.out_dtype, list)
            assert not isinstance(concrete_args.accum_dtype, list)
            assert not isinstance(concrete_args.AB_scale_dtype, list)
            assert not isinstance(concrete_args.AB_scale_mode, list)
            assert f"--layout {layout}" in command
            assert "," not in command

    @pytest.mark.parametrize("operation", ["gemm", "grouped_gemm"])
    def test_operand_seed_is_independent_of_invocation_and_sweep(
        self, operation, monkeypatch
    ):
        module = gemm_operation if operation == "gemm" else grouped_gemm_operation
        factory_name = (
            "make_gemm_arguments"
            if operation == "gemm"
            else "make_grouped_gemm_arguments"
        )
        factory = getattr(module, factory_name)
        allocations = []

        def allocate_on_cpu(size, args, layout):
            operands = factory(size, args, layout, device="cpu")
            allocations.append(
                (
                    operands.A.tensor.runtime_tensor.clone(),
                    operands.B.tensor.runtime_tensor.clone(),
                )
            )
            return operands

        # Exercise the real profiling loop and operand construction, replacing
        # GPU availability/allocation and kernel discovery for this CPU test.
        monkeypatch.setattr(torch.cuda, "is_available", lambda: True)
        monkeypatch.setattr(module, factory_name, allocate_on_cpu)
        monkeypatch.setattr(operation_base.ops, "get_operators", lambda *a, **kw: [])
        shape = ["--M", "32"] if operation == "gemm" else ["--M-extents", "16,16"]

        def inputs(seed, n, prefix, extra=()):
            monkeypatch.setattr(sys, "argv", [prefix])
            args = parse_commandline(
                [
                    "run",
                    "--operation",
                    operation,
                    *shape,
                    "--N",
                    n,
                    "--K",
                    "16",
                    "--layout",
                    "ttt",
                    "--target-sm",
                    "100a",
                    "--seed",
                    str(seed),
                    "--verification-mode",
                    "cpu",
                    *extra,
                ]
            )
            allocations.clear()
            OPERATIONS[operation]().profile(args)
            return allocations[-1]

        baseline = inputs(2026, "32", "cutlass_profiler")
        problem = (
            GemmProblemSize(32, 32, 16, 1)
            if operation == "gemm"
            else IndexPtrGroupedGemmProblemSize(32, 32, 16, 2, (16, 32), "m")
        )
        torch.manual_seed(2026)
        expected = factory(
            problem, _argument_namespace(initialization="auto"), "ttt", device="cpu"
        )
        assert torch.equal(baseline[0], expected.A.tensor.runtime_tensor)
        assert torch.equal(baseline[1], expected.B.tensor.runtime_tensor)
        variants = [
            inputs(2026, "32", "__main__.py", ["--output-format", "json"]),
            inputs(2026, "16,32", "cutlass_profiler", ["--operators", "different*"]),
        ]
        for actual in variants:
            for expected_operand, actual_operand in zip(baseline, actual):
                assert torch.equal(expected_operand, actual_operand)
        changed_seed = inputs(2027, "32", "cutlass_profiler")
        assert any(not torch.equal(a, b) for a, b in zip(baseline, changed_seed))

    def test_gemm_problem_command_uses_scalar_dimensions(self):
        command = gemm_operation._problem_command(
            "cutlass_profiler run --operation gemm --M 64,128 --N 32:64 --K 16 --L 1,2",
            GemmProblemSize(128, 64, 16, 2),
        )

        assert command == (
            "cutlass_profiler run --operation gemm --M 128 --N 64 --K 16 --L 2"
        )

    def test_grouped_problem_command_uses_one_extent_tuple(self):
        command = grouped_gemm_operation._problem_command(
            "cutlass_profiler run --operation grouped_gemm "
            "--M-extents '64,128,64;128,128,128' --N 32,64 --K 16",
            IndexPtrGroupedGemmProblemSize(
                384,
                64,
                16,
                3,
                (128, 256, 384),
                "m",
            ),
        )

        assert command == (
            "cutlass_profiler run --operation grouped_gemm "
            "--M-extents 128,128,128 --N 64 --K 16"
        )

    def test_grouped_problem_sizes_expand_all_dimensions(self):
        profiler = OPERATIONS["grouped_gemm"]()
        sizes = profiler._get_problem_sizes(
            argparse.Namespace(
                M_extents=((64, 128, 64), (128, 128, 128)),
                N=[32, 64],
                K=[16],
            )
        )
        assert sizes == [
            IndexPtrGroupedGemmProblemSize(256, 32, 16, 3, (64, 192, 256), "m"),
            IndexPtrGroupedGemmProblemSize(384, 32, 16, 3, (128, 256, 384), "m"),
            IndexPtrGroupedGemmProblemSize(256, 64, 16, 3, (64, 192, 256), "m"),
            IndexPtrGroupedGemmProblemSize(384, 64, 16, 3, (128, 256, 384), "m"),
        ]

    def test_grouped_operation_config_prints_expanded_problem_sizes(self, capsys):
        profiler = OPERATIONS["grouped_gemm"]()
        args = argparse.Namespace(
            M_extents=((64, 128, 64),),
            N=[32],
            K=[16],
            A_dtype=[cutlass.Float16],
            B_dtype=[cutlass.Float16],
            out_dtype=[cutlass.Float16],
            accum_dtype=[cutlass.Float32],
            layout=["ttt"],
        )

        profiler._print_operation_config(args)

        first_line = capsys.readouterr().out.splitlines()[0]
        assert first_line == (
            "Problem sizes: "
            "[IndexPtrGroupedGemmProblemSize(M=256, N=32, K=16, G=3, "
            "offsets=(64, 192, 256), offsets_along='m')]"
        )

    def test_grouped_problem_sizes_support_n_extents(self):
        profiler = OPERATIONS["grouped_gemm"]()
        sizes = profiler._get_problem_sizes(
            argparse.Namespace(
                M=[32, 64],
                N=None,
                K=[8],
                M_extents=None,
                N_extents=((16, 32),),
                K_extents=None,
            )
        )
        assert sizes == [
            IndexPtrGroupedGemmProblemSize(32, 48, 8, 2, (16, 48), "n"),
            IndexPtrGroupedGemmProblemSize(64, 48, 8, 2, (16, 48), "n"),
        ]

    def test_grouped_problem_sizes_support_k_extents(self):
        profiler = OPERATIONS["grouped_gemm"]()
        sizes = profiler._get_problem_sizes(
            argparse.Namespace(
                M=[32],
                N=[16, 32],
                K=None,
                M_extents=None,
                N_extents=None,
                K_extents=((8, 24),),
            )
        )
        assert sizes == [
            IndexPtrGroupedGemmProblemSize(32, 16, 32, 2, (8, 32), "k"),
            IndexPtrGroupedGemmProblemSize(32, 32, 32, 2, (8, 32), "k"),
        ]

    def test_registered_profilers_use_direct_profile_contract(self):
        for name, cls in OPERATIONS.items():
            profiler = cls()
            assert not hasattr(profiler, "discover"), f"{name} exposes discover"
            assert callable(profiler.profile), f"{name} missing profile"

    def test_profiler_without_discover_is_concrete(self):
        class DirectProfiler(operation_base.OperationProfiler):
            @staticmethod
            def name() -> str:
                return "direct"

            @staticmethod
            def add_arguments(parser: argparse.ArgumentParser) -> None:
                return None

            @staticmethod
            def validate_arguments(args: argparse.Namespace) -> None:
                return None

            def _print_operation_config(self, args: argparse.Namespace) -> None:
                return None

            def profile(self, args: argparse.Namespace, on_result=None):
                return []

        assert isinstance(DirectProfiler(), operation_base.OperationProfiler)

    def test_target_sm_parser_accepts_prefixed_and_unprefixed(self):
        assert parse_target_sm("100a") == parse_target_sm("sm_100a")

    def test_explicit_target_does_not_query_cuda(self, monkeypatch):
        target = parse_target_sm("100a")

        def fail_device_query():
            raise AssertionError("device query must not run")

        monkeypatch.setattr(
            operation_base, "device_or_env_target_sm", fail_device_query
        )
        resolved = operation_base.OperationProfiler._resolve_target_sm(
            argparse.Namespace(target_sm=target)
        )
        assert resolved == target

    def test_m_extents_parser_accepts_multiple_shapes(self):
        assert parse_grouped_extents("64,128,64;128,128,128") == (
            (64, 128, 64),
            (128, 128, 128),
        )

    @pytest.mark.parametrize(
        ("value", "match"),
        [
            ("64,0;128,128", "must be positive"),
            ("64,,128", "Invalid grouped GEMM extents list"),
        ],
    )
    def test_m_extents_parser_rejects_invalid_shapes(self, value, match):
        with pytest.raises(ValueError, match=match):
            parse_grouped_extents(value)

    def test_grouped_problem_size_matches_contiguous_offsets(self):
        problem = IndexPtrGroupedGemmProblemSize(
            M=112,
            N=32,
            K=16,
            G=3,
            offsets=(16, 48, 112),
            offsets_along="m",
        )

        assert (problem.M, problem.N, problem.K, problem.G) == (112, 32, 16, 3)
        assert problem.offsets == (16, 48, 112)
        assert problem.offsets_along == "m"

    def test_scale_parsers(self):
        assert parse_scale_mode("1x16") is ops.ScaleMode.Blockwise1x16
        assert parse_scale_mode("1x32") is ops.ScaleMode.Blockwise1x32
        with pytest.raises(ValueError, match="Invalid scale mode"):
            parse_scale_mode("2x1x32")
        assert parse_scale_swizzle("none") is ops.ScaleSwizzleMode.SwizzleNone
        assert parse_scale_swizzle("32x4x4") is ops.ScaleSwizzleMode.Swizzle32x4x4
        with pytest.raises(ValueError, match="Unsupported scale swizzle"):
            parse_scale_swizzle("bad")

    def test_dense_gemm_arguments_allocate_runtime_storage(self):
        args = make_gemm_arguments(
            GemmProblemSize(64, 32, 16, 1),
            _argument_namespace(),
            "tnt",
            device="cpu",
        )
        assert args.A.tensor.runtime_tensor.shape == (64, 16)
        assert args.B.tensor.runtime_tensor.shape == (16, 32)
        assert args.B.tensor.runtime_tensor.stride()[-2] == 1
        assert args.out.tensor.runtime_tensor.shape == (64, 32)

    def test_scaled_gemm_arguments_allocate_scale_storage(self):
        args = make_gemm_arguments(
            GemmProblemSize(64, 32, 32, 1),
            _argument_namespace(
                A_dtype=cutlass.Float8E4M3FN,
                AB_scale_dtype=cutlass.Float16,
                AB_scale_mode=(1, 1, 32),
                AB_scale_swizzle=ops.ScaleSwizzleMode.SwizzleNone,
            ),
            "ttt",
            device="cpu",
        )
        assert isinstance(args.A, ops.ScaledOperand)
        assert args.A.quantized.tensor.runtime_tensor.shape == (64, 32)
        assert args.A.scale.tensor.runtime_tensor.numel() == 64
        assert isinstance(args.B, ops.ScaledOperand)
        assert args.A.mode == args.B.mode
        assert args.A.swizzle == args.B.swizzle
        assert runtime_operand_nbytes(args.A) == 2048 + 128

    def test_dense_gemm_verification_remains_supported(self):
        A = torch.tensor([[1, 2], [3, 4]], dtype=torch.float32)
        B = torch.tensor([[5, 6], [7, 8]], dtype=torch.float32)

        arguments = ops.GemmArguments(
            A=A,
            B=B,
            out=A @ B,
            accumulator_type=cutlass.Float32,
        )
        verification = verify_gemm(arguments, use_cpu=True)

        assert verification.passed
        assert verification.max_abs_error == 0

    def test_dense_gemm_verification_honors_tolerances(self):
        """A perturbed output passes under a loose atol and fails under a tight one."""
        A = torch.tensor([[1, 2], [3, 4]], dtype=torch.float32)
        B = torch.tensor([[5, 6], [7, 8]], dtype=torch.float32)
        # 2**-4 is exact in float32, so max_abs_error is exactly the offset.
        perturbed = (A @ B) + 0.0625

        arguments = ops.GemmArguments(
            A=A,
            B=B,
            out=perturbed,
            accumulator_type=cutlass.Float32,
        )

        loose = verify_gemm(arguments, atol=1e-1, rtol=0.0, use_cpu=True)
        assert loose.passed

        tight = verify_gemm(arguments, atol=1e-3, rtol=0.0, use_cpu=True)
        assert not tight.passed
        assert tight.error_message is not None
        assert tight.max_abs_error == pytest.approx(0.0625)

    def test_derived_tolerances_are_exact_below_the_k_threshold(self):
        """Small-K float and any integer accumulator compare exactly."""
        assert reference_tolerances(cutlass.Float32, 64) == ReferenceTolerances(
            atol=0.0, rtol=0.0
        )
        assert reference_tolerances(cutlass.Float16, 511) == ReferenceTolerances(
            atol=0.0, rtol=0.0
        )
        assert reference_tolerances(cutlass.Int32, 4096) == ReferenceTolerances(
            atol=0.0, rtol=0.0
        )

    def test_derived_rtol_grows_with_k_and_accumulator_ulp(self):
        """rtol scales with K**1.5 and with the accumulator's ULP; atol stays 0."""
        at_threshold = reference_tolerances(cutlass.Float16, 512)
        assert at_threshold.atol == 0.0
        assert at_threshold.rtol == pytest.approx(0.001)

        # (1500/512)**1.5 ~= 5.01 -- the tuning target named in the formula.
        assert reference_tolerances(cutlass.Float16, 1500).rtol == pytest.approx(
            0.00501, rel=1e-3
        )

        # Doubling K raises rtol by 2**1.5.
        assert reference_tolerances(cutlass.Float16, 1024).rtol == pytest.approx(
            0.001 * 2**1.5
        )

        # A coarser accumulator gets a proportionally looser rtol.
        fp16 = reference_tolerances(cutlass.Float16, 1024).rtol
        fp32 = reference_tolerances(cutlass.Float32, 1024).rtol
        assert fp32 < fp16
        assert fp16 / fp32 == pytest.approx(
            torch.finfo(torch.float16).eps / torch.finfo(torch.float32).eps
        )

        # atol is always 0: the modelled error is proportional to magnitude.
        for k in (512, 1024, 4096):
            assert reference_tolerances(cutlass.Float32, k).atol == 0.0

    def test_derived_tolerances_reject_negative_k(self):
        with pytest.raises(ValueError, match="k must be non-negative"):
            reference_tolerances(cutlass.Float32, -1)

    def test_gemm_tolerances_read_k_from_the_problem(self):
        A = torch.zeros((8, 1024), dtype=torch.float32)
        B = torch.zeros((1024, 8), dtype=torch.float32)
        arguments = ops.GemmArguments(
            A=A, B=B, out=A @ B, accumulator_type=cutlass.Float32
        )

        assert gemm_reference_tolerances(arguments) == reference_tolerances(
            cutlass.Float32, 1024
        )

    def test_dense_gemm_verification_derives_tolerances_by_default(self):
        """With no explicit tolerances, an exact result passes and a perturbed one fails."""
        A = torch.tensor([[1, 2], [3, 4]], dtype=torch.float32)
        B = torch.tensor([[5, 6], [7, 8]], dtype=torch.float32)

        exact = ops.GemmArguments(A=A, B=B, out=A @ B, accumulator_type=cutlass.Float32)
        assert verify_gemm(exact, use_cpu=True).passed

        # K=2 is below the threshold, so the derived tolerance is exact and
        # even a tiny perturbation must fail -- the old 0.1/0.01 default
        # would have accepted this.
        perturbed = ops.GemmArguments(
            A=A, B=B, out=(A @ B) + 0.0625, accumulator_type=cutlass.Float32
        )
        assert not verify_gemm(perturbed, use_cpu=True).passed

    def test_explicit_tolerance_overrides_only_that_one(self):
        """Passing atol leaves rtol derived, and vice versa."""
        A = torch.tensor([[1, 2], [3, 4]], dtype=torch.float32)
        B = torch.tensor([[5, 6], [7, 8]], dtype=torch.float32)
        arguments = ops.GemmArguments(
            A=A, B=B, out=(A @ B) + 0.0625, accumulator_type=cutlass.Float32
        )

        assert verify_gemm(arguments, atol=1e-1, use_cpu=True).passed
        assert not verify_gemm(arguments, rtol=1e-9, use_cpu=True).passed

    def test_scaled_gemm_reference_rejects_mixed_ranks(self):
        with pytest.raises(ValueError, match="both be rank 2 or rank 3"):
            compute_reference_scaled_gemm(
                torch.ones((1, 2, 4), dtype=torch.float32),
                torch.ones((4, 2), dtype=torch.float32),
                torch.ones(2, dtype=torch.float32),
                torch.ones(2, dtype=torch.float32),
                torch.float32,
                torch.float32,
            )

    @pytest.mark.skipif(
        not _MX_FP4_DTYPES_AVAILABLE,
        reason="PyTorch build does not expose MX FP4 dtypes",
    )
    def test_scaled_gemm_reference_emulates_fp4_e8m0_swizzled_scales(self):
        m, n, k = 2, 3, 32
        mode = ops.ScaleMode.Blockwise1x32
        swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
        A = _packed_fp4_ones((m, k // 2))
        B = _packed_fp4_ones((k // 2, n))
        scale_A = torch.ones(
            ops.ScaledOperand.numel_scale((1, m, k), mode, swizzle)
        ).to(torch.float8_e8m0fnu)
        scale_B = torch.ones(
            ops.ScaledOperand.numel_scale((1, n, k), mode, swizzle)
        ).to(torch.float8_e8m0fnu)

        reference = compute_reference_scaled_gemm(
            A,
            B,
            scale_A,
            scale_B,
            torch.float32,
            torch.float32,
            scale_mode_A=mode,
            scale_mode_B=mode,
            scale_swizzle_A=swizzle,
            scale_swizzle_B=swizzle,
        )

        torch.testing.assert_close(
            reference, torch.full((m, n), float(k), dtype=torch.float32)
        )

    @pytest.mark.skipif(
        not _MX_FP4_DTYPES_AVAILABLE,
        reason="PyTorch build does not expose MX FP4 dtypes",
    )
    @pytest.mark.parametrize("fp4_operand", ["A", "B"])
    def test_scaled_gemm_reference_emulates_mixed_fp4_fp8(self, fp4_operand):
        m, n, k = 2, 3, 32
        A = (
            _packed_fp4_ones((m, k // 2))
            if fp4_operand == "A"
            else torch.ones((m, k)).to(torch.float8_e4m3fn)
        )
        B = (
            _packed_fp4_ones((k // 2, n))
            if fp4_operand == "B"
            else torch.ones((k, n)).to(torch.float8_e4m3fn)
        )
        scale_A = torch.tensor([2.0, 4.0]).to(torch.float8_e8m0fnu)
        scale_B = torch.tensor([1.0, 2.0, 4.0]).to(torch.float8_e8m0fnu)
        mode = ops.ScaleMode.Blockwise1x32
        swizzle = ops.ScaleSwizzleMode.SwizzleNone

        reference = compute_reference_scaled_gemm(
            A,
            B,
            scale_A,
            scale_B,
            torch.float32,
            torch.float32,
            scale_mode_A=mode,
            scale_mode_B=mode,
            scale_swizzle_A=swizzle,
            scale_swizzle_B=swizzle,
        )

        expected = (
            float(k) * torch.tensor([[2.0], [4.0]]) * torch.tensor([[1.0, 2.0, 4.0]])
        )
        torch.testing.assert_close(reference, expected)

    def test_scaled_gemm_verification_uses_torch_scaled_mm(
        self, monkeypatch: pytest.MonkeyPatch
    ):
        A = torch.tensor(
            [[1, 2, 3, 4], [5, 6, 7, 8]],
            dtype=torch.float32,
        )
        B = torch.tensor(
            [[1, 2], [3, 4], [5, 6], [7, 8]],
            dtype=torch.float32,
        )
        a_scale = torch.tensor([2, 3, 4, 5], dtype=torch.float32)
        b_scale = torch.tensor([1, 2, 3, 4], dtype=torch.float32)
        expected = A @ B
        arguments = ops.GemmArguments(
            A=ops.ScaledOperand(
                A,
                a_scale,
                mode=(1, 1, 2),
                swizzle=ops.ScaleSwizzleMode.SwizzleNone,
            ),
            B=ops.ScaledOperand(
                B,
                b_scale,
                mode=(1, 1, 2),
                swizzle=ops.ScaleSwizzleMode.SwizzleNone,
            ),
            out=expected.clone(),
            accumulator_type=cutlass.Float32,
        )
        calls = []

        def scaled_mm(
            a: torch.Tensor,
            b: torch.Tensor,
            *,
            scale_a: torch.Tensor,
            scale_b: torch.Tensor,
            out_dtype: torch.dtype,
        ) -> torch.Tensor:
            calls.append((a, b, scale_a, scale_b, out_dtype))
            result = torch.zeros((2, 16), dtype=out_dtype)
            result[:, :2] = expected
            return result

        monkeypatch.setattr(torch, "_scaled_mm", scaled_mm, raising=False)
        verification = verify_gemm(arguments)

        assert verification.passed
        assert verification.max_abs_error == 0
        assert len(calls) == 1
        passed_a, padded_b, passed_scale_a, passed_scale_b, _ = calls[0]
        torch.testing.assert_close(passed_a, A)
        assert padded_b.shape == (4, 16)
        torch.testing.assert_close(padded_b[:, :2], B)
        torch.testing.assert_close(passed_scale_a, a_scale)
        torch.testing.assert_close(passed_scale_b, b_scale)

        with pytest.raises(ValueError, match="requires CUDA"):
            verify_gemm(arguments, use_cpu=True)

    def test_gemm_verification_rejects_non_gemm_arguments(self):
        with pytest.raises(TypeError, match="Expected args to be GemmArguments"):
            verify_gemm(object())

    def test_gemm_verification_rejects_mixed_operand_types(self):
        A = torch.ones((2, 4), dtype=torch.float32)
        B = torch.ones((4, 2), dtype=torch.float32)
        arguments = ops.GemmArguments(
            A=ops.ScaledOperand(
                A,
                torch.ones(4, dtype=torch.float32),
                mode=(1, 1, 2),
                swizzle=ops.ScaleSwizzleMode.SwizzleNone,
            ),
            B=B,
            out=torch.empty((2, 2), dtype=torch.float32),
            accumulator_type=cutlass.Float32,
        )

        with pytest.raises(TypeError, match="Unsupported GEMM operand types"):
            verify_gemm(arguments)

    def test_incomplete_scale_description_fails_fast(self):
        with pytest.raises(ValueError, match="requires --AB-scale-dtype"):
            make_gemm_arguments(
                GemmProblemSize(64, 32, 32, 1),
                _argument_namespace(AB_scale_dtype=cutlass.Float16),
                "ttt",
                device="cpu",
            )

    def test_grouped_arguments_allocate_runtime_storage_and_offsets(self):
        problem = IndexPtrGroupedGemmProblemSize(
            M=112,
            N=32,
            K=16,
            G=3,
            offsets=(16, 48, 112),
            offsets_along="m",
        )
        args = make_grouped_gemm_arguments(
            problem,
            _argument_namespace(),
            "tnt",
            device="cpu",
        )
        assert isinstance(args, ops.IndexPtrGroupedGemmArguments)
        assert args.offsets_along == "m"
        assert args.A.tensor.runtime_tensor.shape == (112, 16)
        assert args.B.tensor.runtime_tensor.shape == (3, 16, 32)
        assert args.B.tensor.runtime_tensor.stride()[-2] == 1
        assert args.out.tensor.runtime_tensor.shape == (112, 32)
        assert args.offsets.tensor.runtime_tensor.tolist() == [16, 48, 112]

    def test_grouped_traffic_bytes_exclude_offsets(self):
        """Offsets are index metadata, so the roofline must not count them."""
        args = make_grouped_gemm_arguments(
            IndexPtrGroupedGemmProblemSize(
                M=112,
                N=32,
                K=16,
                G=3,
                offsets=(16, 48, 112),
                offsets_along="m",
            ),
            _argument_namespace(),
            "tnt",
            device="cpu",
        )

        operand_bytes = sum(
            operand.tensor.runtime_tensor.nbytes
            for operand in (args.A, args.B, args.out)
        )
        # Guards against the exclusion being vacuous.
        assert args.offsets.tensor.runtime_tensor.nbytes > 0
        assert grouped_gemm_operation._gemm_traffic_nbytes(args) == operand_bytes

    @pytest.mark.parametrize(
        ("offsets_along", "problem", "expected_shapes"),
        [
            (
                "n",
                IndexPtrGroupedGemmProblemSize(32, 112, 16, 3, (16, 48, 112), "n"),
                ((3, 32, 16), (16, 112), (32, 112)),
            ),
            (
                "k",
                IndexPtrGroupedGemmProblemSize(32, 16, 112, 3, (16, 48, 112), "k"),
                ((32, 112), (112, 16), (3, 32, 16)),
            ),
        ],
    )
    def test_grouped_arguments_allocate_non_m_storage(
        self, offsets_along, problem, expected_shapes
    ):
        args = make_grouped_gemm_arguments(
            problem,
            _argument_namespace(),
            "ttt",
            device="cpu",
        )
        assert args.offsets_along == offsets_along
        assert args.A.tensor.runtime_tensor.shape == expected_shapes[0]
        assert args.B.tensor.runtime_tensor.shape == expected_shapes[1]
        assert args.out.tensor.runtime_tensor.shape == expected_shapes[2]
        assert args.offsets.tensor.runtime_tensor.tolist() == [16, 48, 112]

    def test_grouped_gemm_verification_uses_grouped_reference(self):
        A = torch.tensor(
            [[1, 2], [3, 4], [5, 6]],
            dtype=torch.float32,
        )
        B = torch.tensor(
            [
                [[1, 0], [0, 1]],
                [[2, 0], [0, 3]],
            ],
            dtype=torch.float32,
        )
        offsets = torch.tensor([1, 3], dtype=torch.int32)
        expected = torch.cat((A[:1] @ B[0], A[1:] @ B[1]))
        reference = compute_reference_grouped_gemm(
            A,
            B,
            offsets,
            "m",
            torch.float32,
            torch.float32,
            use_cpu=True,
        )
        torch.testing.assert_close(reference, expected)

        arguments = ops.IndexPtrGroupedGemmArguments(
            A=A,
            B=B,
            out=expected.clone(),
            accumulator_type=cutlass.Float32,
            offsets=offsets,
            offsets_along="m",
        )
        verification = verify_grouped_gemm(arguments, use_cpu=True)
        assert verification.passed
        assert verification.max_abs_error == 0

    def test_grouped_gemm_verification_supports_n_offsets(self):
        A = torch.tensor(
            [
                [[1, 2], [3, 4]],
                [[2, 0], [0, 3]],
            ],
            dtype=torch.float32,
        )
        B = torch.tensor([[1, 2, 3], [4, 5, 6]], dtype=torch.float32)
        offsets = torch.tensor([1, 3], dtype=torch.int32)
        expected = torch.cat((A[0] @ B[:, :1], A[1] @ B[:, 1:]), dim=1)
        arguments = ops.IndexPtrGroupedGemmArguments(
            A=A,
            B=B,
            out=expected.clone(),
            accumulator_type=cutlass.Float32,
            offsets=offsets,
            offsets_along="n",
        )

        verification = verify_grouped_gemm(arguments, use_cpu=True)
        assert verification.passed

    def test_grouped_gemm_verification_supports_k_offsets(self):
        A = torch.tensor([[1, 2, 3], [4, 5, 6]], dtype=torch.float32)
        B = torch.tensor([[1, 2], [3, 4], [5, 6]], dtype=torch.float32)
        offsets = torch.tensor([1, 3], dtype=torch.int32)
        expected = torch.stack((A[:, :1] @ B[:1], A[:, 1:] @ B[1:]))
        arguments = ops.IndexPtrGroupedGemmArguments(
            A=A,
            B=B,
            out=expected.clone(),
            accumulator_type=cutlass.Float32,
            offsets=offsets,
            offsets_along="k",
        )

        verification = verify_grouped_gemm(arguments, use_cpu=True)
        assert verification.passed

    def test_grouped_tolerances_use_the_largest_group_k(self):
        """K-offset problems vary K per group; the widest group sets the tolerance."""
        A = torch.zeros((2, 3), dtype=torch.float32)
        B = torch.zeros((3, 2), dtype=torch.float32)
        # Cumulative boundaries [1, 3] -> per-group K of 1 and 2.
        offsets = torch.tensor([1, 3], dtype=torch.int32)
        arguments = ops.IndexPtrGroupedGemmArguments(
            A=A,
            B=B,
            out=torch.zeros((2, 2, 2), dtype=torch.float32),
            accumulator_type=cutlass.Float32,
            offsets=offsets,
            offsets_along="k",
        )

        assert grouped_gemm_reference_tolerances(arguments) == reference_tolerances(
            cutlass.Float32, 2
        )

    def test_grouped_tolerances_use_shared_k_for_m_offsets(self):
        """M-offset groups share K, which is A's trailing extent."""
        A = torch.zeros((4, 1024), dtype=torch.float32)
        B = torch.zeros((2, 1024, 2), dtype=torch.float32)
        arguments = ops.IndexPtrGroupedGemmArguments(
            A=A,
            B=B,
            out=torch.zeros((4, 2), dtype=torch.float32),
            accumulator_type=cutlass.Float32,
            offsets=torch.tensor([2, 4], dtype=torch.int32),
            offsets_along="m",
        )

        assert grouped_gemm_reference_tolerances(arguments) == reference_tolerances(
            cutlass.Float32, 1024
        )

    def test_grouped_gemm_verification_rejects_non_grouped_arguments(self):
        with pytest.raises(
            TypeError, match="Expected args to be IndexPtrGroupedGemmArguments"
        ):
            verify_grouped_gemm(object())


class TestMetadataWorkloadMetrics:
    def test_exact_grouped_workload(self):
        group_m = (16, 32, 64)
        n, k = 32, 16
        flops = sum(2 * m * n * k for m in group_m)
        metrics = PerfMetrics.from_workload(
            operator_runtime_ms=0.01,
            flop_count=flops,
            total_bytes=4096,
        )
        assert metrics.flop_count == flops
        assert metrics.total_bytes == 4096
        assert set(metrics.__dataclass_fields__) == {
            "operator_runtime_ms",
            "flop_count",
            "total_bytes",
        }


# ── --heuristic / --limit wire-through ───────────────────────────────────────


class TestHeuristicCliFlag:
    """Wire-only ``--heuristic``: CLI parse + pass-through to ``get_operators``."""

    def test_default_heuristic_is_none(self):
        parser = argparse.ArgumentParser()
        add_common_cli_args(parser)
        args = parser.parse_args([])
        assert args.heuristic is None

    def test_heuristic_flag_parses_registered_name(self):
        assert "nvmatmul" in available_heuristics
        parser = argparse.ArgumentParser()
        add_common_cli_args(parser)
        args = parser.parse_args(["--heuristic", "nvmatmul"])
        assert args.heuristic == "nvmatmul"

    def test_unknown_heuristic_rejected_by_argparse(self):
        parser = argparse.ArgumentParser()
        add_common_cli_args(parser)
        with pytest.raises(SystemExit):
            parser.parse_args(["--heuristic", "_does_not_exist"])

    def test_get_all_operators_forwards_heuristic(self, monkeypatch):
        """Profiling discovery must pass ``heuristic=`` into ``get_operators``."""
        captured = {}

        def fake_get_operators(*args, **kwargs):
            captured.update(kwargs)
            return []

        monkeypatch.setattr(
            "cutlass.profiler.operations.base.ops.get_operators",
            fake_get_operators,
        )
        # TargetSm is only forwarded; a stub string is enough for this unit test
        # once get_operators is mocked.
        operation_base.OperationProfiler._get_all_operators(
            sample_args=None,
            provider=None,
            target_sm="100a",
            operator_pattern=None,
            heuristic="nvmatmul",
        )
        assert captured.get("heuristic") == "nvmatmul"

    def test_get_all_operators_default_heuristic_is_none(self, monkeypatch):
        captured = {}

        def fake_get_operators(*args, **kwargs):
            captured.update(kwargs)
            return []

        monkeypatch.setattr(
            "cutlass.profiler.operations.base.ops.get_operators",
            fake_get_operators,
        )
        operation_base.OperationProfiler._get_all_operators(
            sample_args=None,
            provider=None,
            target_sm="100a",
            operator_pattern=None,
        )
        assert captured.get("heuristic") is None


class TestLimitCliFlag:
    def test_default_limit_is_none(self):
        parser = argparse.ArgumentParser()
        add_common_cli_args(parser)
        args = parser.parse_args([])
        assert args.limit is None

    def test_limit_parses_positive_integer(self):
        parser = argparse.ArgumentParser()
        add_common_cli_args(parser)
        args = parser.parse_args(["--limit", "5"])
        assert args.limit == 5

    @pytest.mark.parametrize("value", ["0", "-1"])
    def test_limit_rejects_non_positive_integer(self, value):
        parser = argparse.ArgumentParser()
        add_common_cli_args(parser)
        with pytest.raises(SystemExit):
            parser.parse_args(["--limit", value])

    def test_get_all_operators_forwards_limit(self, monkeypatch):
        """Profiling discovery must pass ``limit=`` into ``get_operators``."""
        captured = {}

        def fake_get_operators(*args, **kwargs):
            captured.update(kwargs)
            return [object(), object()]

        monkeypatch.setattr(
            "cutlass.profiler.operations.base.ops.get_operators",
            fake_get_operators,
        )

        operators = operation_base.OperationProfiler._get_all_operators(
            sample_args=None,
            provider=None,
            target_sm="100a",
            operator_pattern=None,
            heuristic="nvmatmul",
            limit=2,
        )

        assert captured.get("limit") == 2
        assert captured.get("heuristic") == "nvmatmul"
        assert len(operators) == 2

    def test_get_all_operators_forwards_limit_without_heuristic(self, monkeypatch):
        captured = {}

        def fake_get_operators(*args, **kwargs):
            captured.update(kwargs)
            return [object(), object()]

        monkeypatch.setattr(
            "cutlass.profiler.operations.base.ops.get_operators",
            fake_get_operators,
        )

        operators = operation_base.OperationProfiler._get_all_operators(
            sample_args=None,
            provider=None,
            target_sm="100a",
            operator_pattern=None,
            limit=2,
        )

        assert captured.get("limit") == 2
        assert captured.get("heuristic") is None
        assert len(operators) == 2
