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

"""End-to-end tests for cutlass_profiler (requires CUDA device)."""

import logging

import pytest
import torch
import yaml

from cutlass.operators.utils.device import device_or_env_supports
from cutlass.profiler.cli_reflection.registry import DESIGN_REGISTRY, register_design

pytestmark = [
    pytest.mark.skipif(not torch.cuda.is_available(), reason="CUDA device required"),
    pytest.mark.L0(False),
    pytest.mark.L1(True),
]


def _assert_valid_gemm_yaml_stream(stream: str) -> None:
    """Check every result in the profiler's streamed YAML output."""
    results = list(yaml.safe_load_all(stream))
    assert results

    for data in results:
        assert isinstance(data, dict)
        assert data["operator_runtime_ms"] >= 0
        assert data["test_elapsed_ms"] >= data["operator_runtime_ms"]
        assert data["problem_id"] >= 1
        assert data["operator_name"]
        assert "cutlass_profiler run --operation gemm" in data["cmd"]
        assert data["tflop_per_sec"] >= 0
        assert data["verified"] is True


@pytest.mark.parametrize(
    ("mode", "canonical_mode"),
    [
        ("compile", "compile"),
    ],
)
def test_profiler_unimplemented_modes(caplog, mode, canonical_mode):
    """Stub modes parse operation flags before reporting they are not implemented."""
    from cutlass.profiler.__main__ import main

    with caplog.at_level(logging.ERROR, logger="cutlass.profiler.__main__"):
        rc = main([mode, "--operation", "gemm"])
    assert rc == 1
    assert f"The '{canonical_mode}' mode is not implemented" in caplog.text


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_profiler_gemm_e2e(capsys):
    """Run a small GEMM and check every streamed YAML result."""
    from cutlass.profiler.__main__ import main

    rc = main(
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
            "--A-dtype",
            "f16",
            "--B-dtype",
            "f16",
            "--out-dtype",
            "f16",
            "--measure-performance",
            "--profiling-iterations",
            "5",
            "--warmup-iterations",
            "2",
            "--workspace-count",
            "2",
            "--seed",
            "42",
            "--operators",
            "cutedsl.Sm100DenseGemmUniversalOperator_*cluster1x1x1_tile128x128x64*",
            # One match: the glob otherwise JIT-compiles until xdist's 900s worker timeout.
            "--limit",
            "1",
        ]
    )
    assert rc == 0

    _assert_valid_gemm_yaml_stream(capsys.readouterr().out)



@pytest.mark.parametrize(
    "cli_args",
    [
        [
            "dry-run",
            "--operation",
            "gemm",
            "--M",
            "128",
            "--N",
            "128",
            "--K",
            "64",
            "--design",
            "sm100",
        ],
        [
            "dry-run",
            "--operation",
            "gemm",
            "--M",
            "128",
            "--N",
            "128",
            "--K",
            "64",
            "--design",
            "blas",
            "--design.tile_shape",
            "128x128x64",
        ],
        [
            "dry-run",
            "--operation",
            "gemm",
            "--M",
            "128",
            "--N",
            "128",
            "--K",
            "64",
            "--design",
            "blas",
            "--design.tile_shape",
            "128,128,64",
        ],
        [
            "dry-run",
            "--operation",
            "gemm",
            "--M",
            "128",
            "--N",
            "128",
            "--K",
            "64",
            "--design",
            "blas",
            "--design.mma_instruction_type",
            "BlackwellTcgen05Mma",
        ],
        [
            "dry-run",
            "--operation",
            "gemm",
            "--M",
            "128",
            "--N",
            "128",
            "--K",
            "64",
            "--A-dtype",
            "f16",
            "--B-dtype",
            "f16",
            "--out-dtype",
            "f16",
            "--accum-dtype",
            "f32",
            "--layout",
            "ttt",
            "--provider",
            "cutedsl",
            "--warmup-iterations",
            "0",
            "--profiling-iterations",
            "1",
            "--design.use_tma_store",
            "true",
        ],
    ],
)
def test_profiler_design_dry_run(capsys, cli_args):
    """Design flags are accepted in dry-run mode."""
    from cutlass.profiler.__main__ import main

    rc = main(cli_args)
    assert rc == 0
    assert "Operation: gemm" in capsys.readouterr().out


def test_profiler_design_cli_uses_registered_custom_design(capsys, request):
    """Design CLI generation uses designs registered before parser construction."""
    from dataclasses import dataclass
    from typing import Literal

    from cutlass.operators.metadata.design.base import DesignMetadata
    from cutlass.operators.status import Status
    from cutlass.profiler.__main__ import main

    @dataclass
    class CustomNestedMetadata:
        stages: int
        mode: Literal["fast", "small"]

    @dataclass
    class CustomDesignMetadata(DesignMetadata):
        nested: CustomNestedMetadata
        enabled: bool

        def supports(self, args, target_sm=None):
            return Status.success()

    custom_cli_name = "custom"
    custom_class = register_design(custom_cli_name, CustomDesignMetadata)
    request.addfinalizer(lambda: DESIGN_REGISTRY.classes.remove(custom_class))

    rc = main(
        [
            "dry-run",
            "--operation",
            "gemm",
            "--M",
            "128",
            "--N",
            "128",
            "--K",
            "64",
            "--design",
            custom_cli_name,
            "--design.nested.stages",
            "2",
            "--design.nested.mode",
            "fast",
            "--design.enabled",
            "true",
        ]
    )
    assert rc == 0
    assert "Operation: gemm" in capsys.readouterr().out


def test_profiler_design_invalid_choice():
    """--design with invalid value raises SystemExit (argparse error)."""
    from cutlass.profiler.__main__ import main

    with pytest.raises(SystemExit):
        main(
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
                "--design",
                "sm999",
            ]
        )
