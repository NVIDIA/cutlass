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

"""Tests for cutlass_profiler's CLI parsing (no GPU required)."""

import importlib.util
import inspect
import sys
from types import SimpleNamespace

import pytest

import cutlass
from cutlass import operators as ops

import cutlass.profiler
import cutlass.profiler.__main__ as profiler_main
from cutlass.operators.metadata import (
    BLASDesignMetadata,
    Sm100DesignMetadata,
)
from cutlass.operators.mma import HopperWgmma
from cutlass.profiler.__main__ import (
    PROGRAM_NAME,
    build_parser,
    invocation_command,
    parse_commandline,
)
from cutlass.profiler.analysis import verify_gemm
from cutlass.profiler.cli import AUTO_INITIALIZATION
from cutlass.profiler.cli_reflection.command_line import UNSET_CLI_FIELD
from cutlass.profiler.cli_reflection.registry import CATEGORIES


def gemm_args(*extra: str) -> list[str]:
    """Return a minimal valid dry-run GEMM invocation with extra flags."""
    return [
        "dry-run",
        "--operation",
        "gemm",
        "--M",
        "1024",
        "--N",
        "1024",
        "--K",
        "512",
        *extra,
    ]


def grouped_gemm_args(*extra: str) -> list[str]:
    """Return a minimal valid dry-run grouped GEMM invocation."""
    return [
        "dry-run",
        "--operation",
        "grouped_gemm",
        "--M-extents",
        "64,128,64",
        "--N",
        "64",
        "--K",
        "128",
        *extra,
    ]


# =============================================================================
# Common CLI
# =============================================================================


def test_profiler_dry_run(capsys):
    """CLI dry-run returns 0 and prints expected config fields."""
    from cutlass.profiler.__main__ import main

    rc = main(
        ["dry-run", "--operation", "gemm", "--M", "128", "--N", "128", "--K", "64"]
    )
    assert rc == 0

    captured = capsys.readouterr().out
    assert "Operation: gemm" in captured
    assert "Provider:" in captured
    assert "Measure performance: False" in captured
    assert "Warmup iterations: 0" in captured
    assert "Profiling iterations: 1" in captured
    assert "Workspace count: 1" in captured
    assert "L2 rotation: disabled" in captured
    assert "Output format: yaml" in captured
    assert "Output file: None" in captured
    assert "Append output: False" in captured


def test_default_output_format_is_yaml():
    args = parse_commandline(gemm_args())
    assert args.output_format == "yaml"
    assert args.output_file is None
    assert not args.append


@pytest.mark.parametrize("output_format", ["yaml", "json", "csv"])
def test_output_file_and_append_parse_for_all_formats(output_format):
    args = parse_commandline(
        gemm_args(
            "--output-format",
            output_format,
            "--output-file",
            f"results.{output_format}",
            "--append",
        )
    )

    assert args.output_format == output_format
    assert args.output_file == f"results.{output_format}"
    assert args.append


def test_append_requires_output_file(capsys):
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(gemm_args("--append"))

    assert exc_info.value.code == 2
    assert "--append requires --output-file" in capsys.readouterr().err


def test_legacy_output_option_is_rejected():
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(gemm_args("--output", "results"))

    assert exc_info.value.code == 2


def test_operator_class_regex_filters_metadata_and_records_command():
    class Sm100PersistentDenseGemmOperator:
        pass

    class Sm100BlockscaledStaticPersistentOperator:
        pass

    args = parse_commandline(
        gemm_args("--op_class", r"^Sm100PersistentDenseGemmOperator$")
    )
    assert args.metadata_filter(
        SimpleNamespace(operator_class=Sm100PersistentDenseGemmOperator)
    )
    assert not args.metadata_filter(
        SimpleNamespace(operator_class=Sm100BlockscaledStaticPersistentOperator)
    )
    assert "--operation gemm" in args.cmd
    assert "--op_class '^Sm100PersistentDenseGemmOperator$'" in args.cmd


@pytest.mark.parametrize("mode", ["none", "cpu", "cuda"])
def test_recorded_command_preserves_verification_mode(mode):
    """An explicit mode survives parsing verbatim and is reproducible."""
    argv = gemm_args("--verification-mode", mode)
    argv[0] = "run"

    args = parse_commandline(argv)

    assert args.verification_mode == mode
    assert f"--verification-mode {mode}" in args.cmd


def test_verification_mode_defaults_to_a_resolved_device():
    """'auto' is the default and never survives parsing as a literal."""
    args = parse_commandline(gemm_args())

    assert args.verification_mode in ("cpu", "cuda")


def test_auto_verification_mode_resolves_to_reference_device(monkeypatch):
    monkeypatch.setattr(profiler_main, "reference_device", lambda: "cpu")
    args = parse_commandline(gemm_args("--verification-mode", "auto"))
    assert args.verification_mode == "cpu"

    monkeypatch.setattr(profiler_main, "reference_device", lambda: "cuda")
    args = parse_commandline(gemm_args("--verification-mode", "auto"))
    assert args.verification_mode == "cuda"


def test_explicit_verification_mode_overrides_the_reference_device(monkeypatch):
    """Only 'auto' consults reference_device; an explicit mode is honored."""
    monkeypatch.setattr(profiler_main, "reference_device", lambda: "cuda")

    args = parse_commandline(gemm_args("--verification-mode", "cpu"))

    assert args.verification_mode == "cpu"


@pytest.mark.parametrize(
    "legacy_argv",
    [
        ["--no-verify"],
        ["--verify-device", "cpu"],
        ["--verify-device", "cuda"],
    ],
)
def test_legacy_verification_options_are_rejected(legacy_argv):
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(gemm_args(*legacy_argv))
    assert exc_info.value.code == 2


def test_tolerance_defaults_match_verify_gemm():
    """Unset tolerances stay None so verify_gemm derives them per problem.

    Both sides must agree that None means "derive"; a concrete CLI default
    would silently override the derivation.
    """
    args = parse_commandline(gemm_args())
    signature = inspect.signature(verify_gemm)

    assert args.atol is None
    assert args.rtol is None
    assert args.atol == signature.parameters["atol"].default
    assert args.rtol == signature.parameters["rtol"].default


def test_initialization_defaults_to_auto():
    """The derived tolerances assume the low-variance scheme, so it is default."""
    args = parse_commandline(gemm_args())

    assert args.initialization == AUTO_INITIALIZATION


def test_initialization_is_overridable():
    args = parse_commandline(gemm_args("--initialization", "uniform:-1,1"))

    assert args.initialization == "uniform:-1,1"


def test_tolerances_are_overridable():
    args = parse_commandline(gemm_args("--atol", "1e-3", "--rtol", "0"))

    assert args.atol == pytest.approx(1e-3)
    assert args.rtol == 0.0


def test_recorded_command_preserves_tolerances():
    argv = gemm_args("--atol", "1e-3", "--rtol", "1e-4")
    argv[0] = "run"

    args = parse_commandline(argv)

    assert "--atol 1e-3" in args.cmd
    assert "--rtol 1e-4" in args.cmd


def test_negative_tolerance_reports_a_tolerance_diagnostic(capsys):
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(gemm_args("--atol", "-0.5"))
    assert exc_info.value.code == 2
    assert "tolerance must be a non-negative number" in capsys.readouterr().err


def test_invalid_operator_class_regex_is_rejected(capsys):
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(gemm_args("--op_class", "["))
    assert exc_info.value.code == 2
    assert "invalid operator-class regular expression" in capsys.readouterr().err


def test_measure_performance_cli_flag():
    default_args = parse_commandline(gemm_args())
    performance_args = parse_commandline(gemm_args("--measure-performance"))
    assert default_args.measure_performance is False
    assert default_args.warmup_iterations == 0
    assert default_args.profiling_iterations == 1
    assert default_args.workspace_count == 1
    assert performance_args.measure_performance is True
    assert performance_args.warmup_iterations == 10
    assert performance_args.profiling_iterations == 100
    assert performance_args.workspace_count == "auto"


@pytest.mark.parametrize(
    ("value", "expected"),
    [("auto", "auto"), ("3", 3)],
)
def test_workspace_count_parser(value, expected):
    args = parse_commandline(
        gemm_args("--measure-performance", "--workspace-count", value)
    )
    assert args.workspace_count == expected


def test_layout_and_dtype_parsers():
    args = parse_commandline(gemm_args("--layout", "ttt,ntt", "--A-dtype", "F16"))
    assert args.layout == ["ttt", "ntt"]
    assert args.A_dtype == [cutlass.Float16]


def test_heuristic_flag_resolves_to_instance():
    """``--heuristic`` must resolve to a constructed Heuristic instance."""
    from cutlass.operators.heuristics.nvmatmul import NvMatmulHeuristics

    args = parse_commandline(gemm_args("--heuristic", "nvmatmul"))
    assert isinstance(args.heuristic, NvMatmulHeuristics)
    assert args.heuristic.gpu == "B200"


def test_no_heuristic_flag_leaves_heuristic_none():
    args = parse_commandline(gemm_args())
    assert args.heuristic is None


@pytest.mark.parametrize(
    ("option", "value"),
    [
        ("--workspace-count", "0"),
        ("--warmup-iterations", "-1"),
        ("--profiling-iterations", "0"),
        ("--layout", "ttx"),
        ("--A-dtype", "f64"),
        ("--A-dtype", "ue8m0"),
        ("--A-dtype", "f16,,f32"),
        ("--AB-scale-dtype", "f16"),
        ("--AB-scale-dtype", "ue8m0,"),
        ("--AB-scale-mode", "1x32,"),
        ("--M", "0"),
        ("--timing-method", "host_timer"),
        ("--output-format", "toml"),
        ("--output-format", "text"),
        ("--verification-mode", "tpu"),
        ("--verification-mode", "gpu"),
        ("--atol", "-0.5"),
        ("--rtol", "-0.5"),
        ("--atol", "nan"),
        ("--rtol", "inf"),
        ("--atol", "loose"),
    ],
)
def test_invalid_common_arguments_are_rejected(option, value):
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(gemm_args(option, value))
    assert exc_info.value.code == 2


@pytest.mark.parametrize(
    ("option", "value", "invalid_option"),
    [
        ("--warmup-iterations", "2", "warmup_iterations=2"),
        ("--profiling-iterations", "3", "profiling_iterations=3"),
        ("--workspace-count", "4", "workspace_count=4"),
    ],
)
def test_performance_options_require_measure_performance(
    capsys, option, value, invalid_option
):
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(gemm_args(option, value))
    assert exc_info.value.code == 2
    error = capsys.readouterr().err
    assert "--measure-performance" in error
    assert invalid_option in error


def test_profiler_requires_mode_before_operation():
    """Operation names are nested under an explicit profiler mode."""
    from cutlass.profiler.__main__ import main

    with pytest.raises(SystemExit) as exc_info:
        main(["gemm", "--M", "128", "--N", "128", "--K", "64"])
    assert exc_info.value.code == 2


@pytest.mark.parametrize("alias", ["r", "c", "i"])
def test_legacy_mode_aliases_are_rejected(alias):
    """Profiler modes must use their full names."""
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline([alias])
    assert exc_info.value.code == 2


def test_operation_option_is_required(capsys):
    """Every mode requires explicit operation selection."""
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(["dry-run", "--M", "128", "--N", "128", "--K", "64"])
    assert exc_info.value.code == 2
    assert "--operation" in capsys.readouterr().err


def test_positional_operation_is_rejected():
    """Operations must be selected with --operation."""
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(["dry-run", "gemm", "--M", "128", "--N", "128", "--K", "64"])
    assert exc_info.value.code == 2


def test_legacy_dry_run_flag_is_rejected():
    """Dry-run is a mode, not an option on run."""
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(
            [
                "run",
                "--operation",
                "gemm",
                "--M",
                "128",
                "--N",
                "128",
                "--K",
                "64",
                "--dry-run",
            ]
        )
    assert exc_info.value.code == 2


@pytest.mark.parametrize(
    "extra",
    [
        ("--use-graphs",),
        ("--nsys-args", "--sample=cpu"),
        ("--sort-results-flops-per-sec", "--sort-results-flops-per-byte"),
    ],
)
def test_dependent_or_exclusive_options_are_rejected(extra):
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(gemm_args(*extra))
    assert exc_info.value.code == 2


def test_shared_ab_scale_options_configure_both_operands():
    args = parse_commandline(
        gemm_args(
            "--AB-scale-dtype=ue8m0",
            "--AB-scale-mode=1x32",
        )
    )
    assert args.AB_scale_dtype == [cutlass.Float8E8M0FNU]
    assert args.AB_scale_mode == [ops.ScaleMode.Blockwise1x32]
    assert args.AB_scale_swizzle is ops.ScaleSwizzleMode.Swizzle32x4x4


def test_gemm_dtype_layout_and_scale_options_accept_lists():
    args = parse_commandline(
        gemm_args(
            "--A-dtype",
            "e4m3,e5m2",
            "--B-dtype",
            "e2m1,e4m3",
            "--out-dtype",
            "f16,f32",
            "--accum-dtype",
            "f16,f32",
            "--layout",
            "tnt,ttt",
            "--AB-scale-dtype",
            "ue8m0,ue4m3",
            "--AB-scale-mode",
            "1x16,1x32",
        )
    )
    assert args.A_dtype == [cutlass.Float8E4M3FN, cutlass.Float8E5M2]
    assert args.B_dtype == [cutlass.Float4E2M1FN, cutlass.Float8E4M3FN]
    assert args.out_dtype == [cutlass.Float16, cutlass.Float32]
    assert args.accum_dtype == [cutlass.Float16, cutlass.Float32]
    assert args.layout == ["tnt", "ttt"]
    assert args.AB_scale_dtype == [cutlass.Float8E8M0FNU, cutlass.Float8E4M3FN]
    assert args.AB_scale_mode == [
        ops.ScaleMode.Blockwise1x16,
        ops.ScaleMode.Blockwise1x32,
    ]


def test_grouped_gemm_dtype_options_accept_lists():
    args = parse_commandline(
        grouped_gemm_args(
            "--A-dtype",
            "f16,bf16",
            "--B-dtype",
            "f16,bf16",
            "--out-dtype",
            "f16,f32",
            "--accum-dtype",
            "f16,f32",
        )
    )
    assert args.A_dtype == [cutlass.Float16, cutlass.BFloat16]
    assert args.B_dtype == [cutlass.Float16, cutlass.BFloat16]
    assert args.out_dtype == [cutlass.Float16, cutlass.Float32]
    assert args.accum_dtype == [cutlass.Float16, cutlass.Float32]


def test_shared_ab_scale_swizzle_overrides_default():
    args = parse_commandline(
        gemm_args(
            "--AB-scale-dtype=ue8m0",
            "--AB-scale-mode=1x32",
            "--AB-scale-swizzle=none",
        )
    )
    assert args.AB_scale_swizzle is ops.ScaleSwizzleMode.SwizzleNone


@pytest.mark.parametrize(
    "options",
    [
        ("--AB-scale-dtype", "ue8m0"),
        ("--AB-scale-mode", "1x32"),
        ("--AB-scale-swizzle", "none"),
    ],
)
def test_shared_ab_scale_requires_dtype_and_mode(capsys, options):
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(gemm_args(*options))
    assert exc_info.value.code == 2
    assert "requires --AB-scale-dtype" in capsys.readouterr().err


@pytest.mark.parametrize(
    "legacy_option",
    [
        "--AB-scale",
        "--A-scale-dtype",
        "--A-scale-mode",
        "--A-scale-swizzle",
        "--B-scale-dtype",
        "--B-scale-mode",
        "--B-scale-swizzle",
    ],
)
def test_per_operand_scale_options_are_rejected(legacy_option):
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(gemm_args(legacy_option, "unused"))
    assert exc_info.value.code == 2


def test_scaled_gemm_rejects_cpu_verification(capsys):
    with pytest.raises(SystemExit) as exc_info:
        parse_commandline(
            gemm_args(
                "--AB-scale-dtype",
                "ue8m0",
                "--AB-scale-mode",
                "1x32",
                "--AB-scale-swizzle",
                "none",
                "--verification-mode",
                "cpu",
            )
        )
    assert exc_info.value.code == 2
    assert "Scaled GEMM verification is unavailable on CPU" in capsys.readouterr().err


class TestCommonCli:
    """Test documented top-level CLI help."""

    def test_help_text_lists_modes(self):
        help_text = build_parser(CATEGORIES).format_help()
        assert "run" in help_text
        assert "dry-run" in help_text
        assert "compile" in help_text
        assert "inspect" in help_text


class TestProfilerModeAndRuntimeArguments:
    """Test profiler modes and operation-specific runtime arguments."""

    def test_dry_run_mode_and_gemm_operation(self):
        namespace = parse_commandline(gemm_args())
        assert namespace.mode_name == "dry-run"
        assert namespace.operation == "gemm"
        assert namespace.operation_instance is not None
        assert namespace.L == [1]

    def test_gemm_dimensions_use_uppercase_options(self):
        namespace = parse_commandline(gemm_args("--L", "3", "--out-dtype", "f32"))
        assert namespace.M == [1024]
        assert namespace.N == [1024]
        assert namespace.K == [512]
        assert namespace.L == [3]
        assert namespace.out_dtype == [cutlass.Float32]

    @pytest.mark.parametrize("option", ["--M", "--N", "--K", "--L"])
    @pytest.mark.parametrize(
        ("value", "expected"),
        [
            ("1024", [1024]),
            ("128, 1024", [128, 1024]),
            ("512:2048:512", [512, 1024, 1536, 2048]),
        ],
    )
    def test_gemm_dimensions_accept_all_forms(self, option, value, expected):
        namespace = parse_commandline(gemm_args(option, value))
        assert getattr(namespace, option.removeprefix("--")) == expected

    def test_grouped_gemm_accepts_multiple_M_extent_tuples(self):
        namespace = parse_commandline(
            [
                "dry-run",
                "--operation",
                "grouped_gemm",
                "--M-extents",
                "64,128,64;128,128,128",
                "--N",
                "64",
                "--K",
                "128",
                "--out-dtype",
                "f32",
            ]
        )
        assert namespace.M_extents == (
            (64, 128, 64),
            (128, 128, 128),
        )
        assert namespace.N == [64]
        assert namespace.K == [128]
        assert namespace.out_dtype == [cutlass.Float32]

    @pytest.mark.parametrize(
        ("extent_option", "fixed_dimensions", "axis"),
        [
            ("--M-extents", ("--N", "64", "--K", "128"), "M"),
            ("--N-extents", ("--M", "64", "--K", "128"), "N"),
            ("--K-extents", ("--M", "64", "--N", "128"), "K"),
        ],
    )
    def test_grouped_gemm_accepts_each_extent_axis(
        self, extent_option, fixed_dimensions, axis
    ):
        namespace = parse_commandline(
            [
                "dry-run",
                "--operation",
                "grouped_gemm",
                extent_option,
                "16,32",
                *fixed_dimensions,
            ]
        )
        assert getattr(namespace, f"{axis}_extents") == ((16, 32),)

    def test_grouped_gemm_rejects_fixed_value_for_varying_axis(self, capsys):
        with pytest.raises(SystemExit) as exc_info:
            parse_commandline(
                [
                    "dry-run",
                    "--operation",
                    "grouped_gemm",
                    "--M-extents",
                    "16,32",
                    "--M",
                    "48",
                    "--N",
                    "64",
                    "--K",
                    "128",
                ]
            )
        assert exc_info.value.code == 2
        assert "--M cannot be combined with --M-extents" in capsys.readouterr().err

    def test_grouped_gemm_rejects_multiple_extent_axes(self):
        with pytest.raises(SystemExit) as exc_info:
            parse_commandline(
                [
                    "dry-run",
                    "--operation",
                    "grouped_gemm",
                    "--M-extents",
                    "16,32",
                    "--N-extents",
                    "16,32",
                    "--K",
                    "128",
                ]
            )
        assert exc_info.value.code == 2

    @pytest.mark.parametrize(
        ("extent_option", "dimensions", "error_option"),
        [
            ("--M-extents", ("--N", "64"), "--K"),
            ("--N-extents", ("--M", "64"), "--K"),
            ("--K-extents", ("--M", "64"), "--N"),
        ],
    )
    def test_grouped_gemm_requires_both_fixed_dimensions(
        self, capsys, extent_option, dimensions, error_option
    ):
        with pytest.raises(SystemExit) as exc_info:
            parse_commandline(
                [
                    "dry-run",
                    "--operation",
                    "grouped_gemm",
                    extent_option,
                    "16,32",
                    *dimensions,
                ]
            )
        assert exc_info.value.code == 2
        assert error_option in capsys.readouterr().err

    @pytest.mark.parametrize("option", ["--N", "--K"])
    @pytest.mark.parametrize(
        ("value", "expected"),
        [
            ("1024", [1024]),
            ("128, 1024", [128, 1024]),
            ("512:2048:512", [512, 1024, 1536, 2048]),
        ],
    )
    def test_grouped_gemm_dimensions_accept_all_forms(self, option, value, expected):
        namespace = parse_commandline(grouped_gemm_args(option, value))
        assert getattr(namespace, option.removeprefix("--")) == expected

    @pytest.mark.parametrize("option", ["--m", "--n", "--k", "--l"])
    def test_gemm_lowercase_dimension_options_are_rejected(self, option):
        with pytest.raises(SystemExit) as exc_info:
            parse_commandline(gemm_args(option, "2"))
        assert exc_info.value.code == 2

    @pytest.mark.parametrize("mode", ["compile", "inspect"])
    def test_non_run_modes_parse_successfully(self, mode):
        """compile and inspect parse cleanly; whether they do anything useful is an e2e concern."""
        namespace = parse_commandline([mode, "--operation", "gemm"])
        assert namespace.mode_name == mode


# =============================================================================
# Design Metadata Category
# =============================================================================


class TestDesignMetadataCliCategory:
    """Tests that CLI parsing works for the library-provided DesignMetadata classes.

    Test Input Space Covered So Far:
    - --design
        - appears in --help when run mode is specified
        - =sm100
        - =blas
        - don't set
    - Design fields
        - field that appears on 2 distinct metadata classes
        - field that appears on 1 metadata class
        - field in parent class ex. cluster_shape in BLASDesignMetadata
        - field with tuple type
        - field that is T | None
        - field is enum or type
        - field is bool but value is omitted -> default to True
    - Omitted fields are set as UNSET_CLI_FIELD sentinel value
    - Rejects invalid CLI values
        - Ex. --design sm100 --design.use_tma_store true
    """

    def test_design_appears_in_run_gemm_help(self, capsys):
        with pytest.raises(SystemExit) as exc_info:
            build_parser(CATEGORIES, "gemm").parse_args(
                ["run", "--operation", "gemm", "--help"]
            )
        assert exc_info.value.code == 0
        assert "--design" in capsys.readouterr().out

    @pytest.mark.parametrize(
        "cli_name,expected_class",
        [
            ("sm100", Sm100DesignMetadata),
            ("blas", BLASDesignMetadata),
        ],
    )
    def test_design_choice(self, cli_name, expected_class):
        namespace = parse_commandline(gemm_args("--design", cli_name))
        assert namespace.design is expected_class

    def test_design_not_set_is_unset_sentinel(self):
        namespace = parse_commandline(gemm_args())
        assert namespace.design is UNSET_CLI_FIELD

    def test_shared_field_use_tma_store(self):
        namespace_true = parse_commandline(
            gemm_args("--design.use_tma_store")
        )  # no value -> const=True
        namespace_false = parse_commandline(
            gemm_args("--design.use_tma_store", "false")
        )
        namespace_unset = parse_commandline(gemm_args())
        assert namespace_true.use_tma_store is True
        assert namespace_false.use_tma_store is False
        assert namespace_unset.use_tma_store is UNSET_CLI_FIELD

    def test_parent_class_field_cluster_shape(self):
        """cluster_shape is defined on BLASDesignMetadata, the parent of all design classes."""
        namespace = parse_commandline(gemm_args("--design.cluster_shape", "4x2x1"))
        assert namespace.cluster_shape == (4, 2, 1)

    def test_tuple_field_tile_shape(self):
        """Tuple fields accept both 'x'-separated and ','-separated formats."""
        namespace_x = parse_commandline(gemm_args("--design.tile_shape", "128x64x32"))
        namespace_csv = parse_commandline(gemm_args("--design.tile_shape", "128,64,32"))
        assert namespace_x.tile_shape == (128, 64, 32)
        assert namespace_csv.tile_shape == (128, 64, 32)

    def test_optional_int_field_none_and_value(self):
        """T | None fields accept 'none' (-> None) and integer strings (-> int)."""
        namespace_none = parse_commandline(
            gemm_args("--design.num_smem_stages", "none")
        )
        namespace_val = parse_commandline(gemm_args("--design.num_smem_stages", "4"))
        assert namespace_none.num_smem_stages is None
        assert namespace_val.num_smem_stages == 4

    def test_type_field_mma_instruction_type(self):
        """type[T] fields are parsed by class name from recursive subclasses of the base type."""
        namespace = parse_commandline(
            gemm_args("--design.mma_instruction_type", "HopperWgmma")
        )
        assert namespace.mma_instruction_type is HopperWgmma

    def test_bool_field_value_omitted_uses_const_true(self):
        """Bool flags with nargs='?' use const=True when the flag is present without a value."""
        namespace = parse_commandline(gemm_args("--design.use_tma_store"))
        assert namespace.use_tma_store is True

    def test_all_omitted_fields_are_unset_sentinel(self):
        """Every design field not provided by the user defaults to UNSET_CLI_FIELD (not None).

        UNSET_CLI_FIELD is a distinct sentinel so build_metadata_filter can tell apart
        "user didn't set this flag" from "user explicitly passed --foo none", which is a
        valid value for T | None fields.
        """
        namespace = parse_commandline(gemm_args())
        for attr in (
            "use_tma_store",
            "use_2cta_mma",
            "tile_shape",
            "cluster_shape",
            "mma_instruction_type",
            "num_smem_stages",
            "fallback_cluster_shape",
        ):
            value = getattr(namespace, attr)
            assert value is UNSET_CLI_FIELD, (
                f"{attr}: expected UNSET_CLI_FIELD, got {value!r}"
            )
            assert value is not None, (
                f"{attr}: None would be mistaken for an explicit 'none' input"
            )


@pytest.mark.parametrize(
    "executable", ["/usr/bin/pytest", "__main__.py", "/opt/venv/bin/cutlass_profiler"]
)
def test_reproduction_command_uses_public_cli(executable, monkeypatch):
    """Library, module, and CLI invocations recommend the same public command."""
    monkeypatch.setattr(sys, "argv", [executable])
    assert invocation_command() == [PROGRAM_NAME]
    assert parse_commandline(gemm_args()).cmd.startswith("cutlass_profiler dry-run")


def test_main_reports_missing_torch(monkeypatch, capsys):
    """torch is an optional wheel dependency, so its absence is a usage error.

    Without the guard the console script would fail with an import traceback
    from deep inside the operand-allocation code.
    """
    monkeypatch.setattr(importlib.util, "find_spec", lambda name: None)

    assert cutlass.profiler.main(gemm_args()) == 1
    assert "nvidia-cutlass-operators[torch]" in capsys.readouterr().err
