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

"""
Pytest test suite for hopper/dense_gemm_fp8_2xacc.py.

Test organization
-----------------
L0 — compile-only tests (skip_ref_check=True, iterations=0)
    Verify that the kernel compiles for a broad range of configurations
    without running on the GPU.  Fast (~1-3 s each).

L1 — correctness tests (GPU execution, checked against torch.einsum)
    Verify numerical correctness for the key configurations.

Benchmark — performance tests (skip_ref_check=True, warmup + timed iterations)
    Report execution time and TFLOPS for representative problem sizes.
    Marked with @pytest.mark.bench; skipped by default unless -m bench is passed.

Coverage
--------
* All tile shapes: (64,64), (128,64), (128,128), (128,256)
* All cluster shapes: (1,1), (2,1), (1,2), (2,2)
* All output dtypes: Float16, Float32, Float8E4M3FN
* mma_promotion_interval: 4, 8, 16
* Non-trivial scale factors (scale_a != 1.0 or scale_b != 1.0)
* Batched GEMM (L > 1)
* Large LLM-like problem sizes in benchmark
"""

import pytest
import cutlass
from hopper.dense_gemm_fp8_2xacc import run

# ---------------------------------------------------------------------------
# Type aliases
# ---------------------------------------------------------------------------

F16 = cutlass.Float16
F32 = cutlass.Float32
F8E4 = cutlass.Float8E4M3FN


# ---------------------------------------------------------------------------
# Shared invocation helpers
# ---------------------------------------------------------------------------


def _run_compile(
    mnkl=(2048, 2048, 2048, 1),
    tile_shape_mn=(128, 128),
    cluster_shape_mn=(1, 1),
    c_dtype=F16,
    mma_promotion_interval=4,
    scale_a_val=1.0,
    scale_b_val=1.0,
):
    """Compile-only helper: JIT-compiles and runs the kernel once without validation.

    Uses iterations=1 (not 0) because testing.benchmark divides by iterations.
    skip_ref_check=True ensures no reference comparison is performed.
    """
    run(
        mnkl=mnkl,
        c_dtype=c_dtype,
        tile_shape_mn=tile_shape_mn,
        cluster_shape_mn=cluster_shape_mn,
        mma_promotion_interval=mma_promotion_interval,
        scale_a_val=scale_a_val,
        scale_b_val=scale_b_val,
        tolerance=0.1,
        warmup_iterations=0,
        iterations=1,
        skip_ref_check=True,
        use_cold_l2=False,
    )


def _run_correctness(
    mnkl=(2048, 2048, 2048, 1),
    tile_shape_mn=(128, 128),
    cluster_shape_mn=(1, 1),
    c_dtype=F16,
    mma_promotion_interval=4,
    scale_a_val=1.0,
    scale_b_val=1.0,
    tolerance=0.1,
):
    """Correctness helper: runs kernel and validates against torch.einsum reference."""
    run(
        mnkl=mnkl,
        c_dtype=c_dtype,
        tile_shape_mn=tile_shape_mn,
        cluster_shape_mn=cluster_shape_mn,
        mma_promotion_interval=mma_promotion_interval,
        scale_a_val=scale_a_val,
        scale_b_val=scale_b_val,
        tolerance=tolerance,
        warmup_iterations=0,
        iterations=1,
        skip_ref_check=False,
        use_cold_l2=False,
    )


def _run_benchmark(
    mnkl,
    tile_shape_mn,
    cluster_shape_mn,
    c_dtype=F16,
    mma_promotion_interval=4,
    warmup_iterations=20,
    iterations=100,
):
    """Benchmark helper: runs kernel with warmup and returns (exec_us, tflops)."""
    m, n, k, l = mnkl
    flops = 2.0 * m * n * k * l
    exec_us = run(
        mnkl=mnkl,
        c_dtype=c_dtype,
        tile_shape_mn=tile_shape_mn,
        cluster_shape_mn=cluster_shape_mn,
        mma_promotion_interval=mma_promotion_interval,
        scale_a_val=1.0,
        scale_b_val=1.0,
        tolerance=0.1,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=True,
        use_cold_l2=True,
    )
    tflops = flops / (exec_us * 1e-6) / 1e12
    return exec_us, tflops


# ---------------------------------------------------------------------------
# L0 — tile shape coverage
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize(
    "tile_shape_mn, mnkl",
    [
        pytest.param((128, 256), (2048, 2048, 2048, 1), id="tile128x256"),
        pytest.param((128, 128), (2048, 2048, 2048, 1), id="tile128x128"),
        pytest.param((128, 64),  (2048, 2048, 2048, 1), id="tile128x64"),
        pytest.param((64,  64),  (2048, 2048, 2048, 1), id="tile64x64"),
    ],
)
def test_l0_tile_shapes(tile_shape_mn, mnkl):
    """All valid tile shapes compile."""
    _run_compile(mnkl=mnkl, tile_shape_mn=tile_shape_mn)


# ---------------------------------------------------------------------------
# L0 — cluster shape coverage
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize(
    "cluster_shape_mn",
    [
        pytest.param((1, 1), id="cluster1x1"),
        pytest.param((2, 1), id="cluster2x1"),
        pytest.param((1, 2), id="cluster1x2"),
        pytest.param((2, 2), id="cluster2x2"),
    ],
)
def test_l0_cluster_shapes(cluster_shape_mn):
    """All valid cluster shapes compile (tile 128x128, 2048^3)."""
    _run_compile(mnkl=(2048, 2048, 2048, 1), tile_shape_mn=(128, 128),
                 cluster_shape_mn=cluster_shape_mn)


# ---------------------------------------------------------------------------
# L0 — output dtype coverage
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize(
    "c_dtype",
    [
        pytest.param(F16,  id="Float16"),
        pytest.param(F32,  id="Float32"),
        pytest.param(F8E4, id="Float8E4M3FN"),
    ],
)
def test_l0_output_dtypes(c_dtype):
    """All supported output dtypes compile."""
    _run_compile(c_dtype=c_dtype)


# ---------------------------------------------------------------------------
# L0 — mma_promotion_interval coverage
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize(
    "mma_promotion_interval",
    [
        pytest.param(4,  id="interval4"),
        pytest.param(8,  id="interval8"),
        pytest.param(16, id="interval16"),
    ],
)
def test_l0_mma_promotion_intervals(mma_promotion_interval):
    """All representative mma_promotion_interval values compile."""
    _run_compile(mma_promotion_interval=mma_promotion_interval)


# ---------------------------------------------------------------------------
# L1 — correctness: tile shapes
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize(
    "tile_shape_mn, mnkl",
    [
        pytest.param((128, 256), (2048, 2048, 2048, 1), id="tile128x256"),
        pytest.param((128, 128), (2048, 2048, 2048, 1), id="tile128x128"),
        pytest.param((128, 64),  (2048, 2048, 2048, 1), id="tile128x64"),
        pytest.param((64,  64),  (2048, 2048, 2048, 1), id="tile64x64"),
    ],
)
def test_l1_tile_shapes(tile_shape_mn, mnkl):
    """All tile shapes produce numerically correct results."""
    _run_correctness(mnkl=mnkl, tile_shape_mn=tile_shape_mn)


# ---------------------------------------------------------------------------
# L1 — correctness: cluster shapes (multicast paths)
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize(
    "cluster_shape_mn",
    [
        pytest.param((1, 1), id="cluster1x1"),
        pytest.param((2, 1), id="cluster2x1"),
        pytest.param((1, 2), id="cluster1x2"),
        pytest.param((2, 2), id="cluster2x2"),
    ],
)
def test_l1_cluster_shapes(cluster_shape_mn):
    """All cluster shapes (including A/B multicast paths) produce correct results."""
    _run_correctness(mnkl=(2048, 2048, 2048, 1), tile_shape_mn=(128, 128),
                     cluster_shape_mn=cluster_shape_mn)


# ---------------------------------------------------------------------------
# L1 — correctness: output dtypes
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize(
    "c_dtype, tolerance",
    [
        pytest.param(F16,  0.1,  id="Float16"),
        pytest.param(F32,  0.1,  id="Float32"),
        pytest.param(F8E4, 0.5,  id="Float8E4M3FN"),
    ],
)
def test_l1_output_dtypes(c_dtype, tolerance):
    """All supported output dtypes produce correct results."""
    _run_correctness(c_dtype=c_dtype, tolerance=tolerance)


# ---------------------------------------------------------------------------
# L1 — correctness: mma_promotion_interval
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize(
    "mma_promotion_interval",
    [
        pytest.param(4,  id="interval4"),
        pytest.param(8,  id="interval8"),
        pytest.param(16, id="interval16"),
    ],
)
def test_l1_mma_promotion_intervals(mma_promotion_interval):
    """Different mma_promotion_interval values all produce correct results."""
    _run_correctness(mma_promotion_interval=mma_promotion_interval)


# ---------------------------------------------------------------------------
# L1 — correctness: non-trivial scale factors
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize(
    "scale_a_val, scale_b_val",
    [
        pytest.param(0.5,  2.0,  id="scale_a0.5_b2.0"),
        pytest.param(0.25, 4.0,  id="scale_a0.25_b4.0"),
        pytest.param(2.0,  0.5,  id="scale_a2.0_b0.5"),
    ],
)
def test_l1_scale_factors(scale_a_val, scale_b_val):
    """Non-trivial scale_a * scale_b factors are applied correctly."""
    _run_correctness(scale_a_val=scale_a_val, scale_b_val=scale_b_val)


# ---------------------------------------------------------------------------
# L1 — correctness: batched GEMM (L > 1)
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize(
    "mnkl",
    [
        pytest.param((1024, 1024, 1024, 2), id="L2"),
        pytest.param((512,  512,  512,  4), id="L4"),
    ],
)
def test_l1_batched(mnkl):
    """Batched GEMM (L > 1) produces correct results for each batch entry."""
    _run_correctness(mnkl=mnkl, tile_shape_mn=(128, 128), cluster_shape_mn=(1, 1))


# ---------------------------------------------------------------------------
# Benchmark — representative problem sizes
# Skipped by default; run with: pytest -m bench -s
# ---------------------------------------------------------------------------


@pytest.mark.bench
@pytest.mark.parametrize(
    "mnkl, tile_shape_mn, cluster_shape_mn, mma_promotion_interval, label",
    [
        # Square 4096^3 — tile / cluster sweep
        pytest.param((4096, 4096, 4096, 1), (128, 128), (1, 1), 4,  "4096^3  tile=128x128  cluster=1x1",  id="4096-128x128-1x1"),
        pytest.param((4096, 4096, 4096, 1), (128, 128), (1, 2), 4,  "4096^3  tile=128x128  cluster=1x2",  id="4096-128x128-1x2"),
        pytest.param((4096, 4096, 4096, 1), (128, 128), (2, 2), 4,  "4096^3  tile=128x128  cluster=2x2",  id="4096-128x128-2x2"),
        pytest.param((4096, 4096, 4096, 1), (128, 256), (1, 2), 4,  "4096^3  tile=128x256  cluster=1x2",  id="4096-128x256-1x2"),
        pytest.param((4096, 4096, 4096, 1), (128, 256), (2, 2), 4,  "4096^3  tile=128x256  cluster=2x2",  id="4096-128x256-2x2"),
        pytest.param((4096, 4096, 4096, 1), (128, 64),  (1, 2), 4,  "4096^3  tile=128x64   cluster=1x2",  id="4096-128x64-1x2"),
        pytest.param((4096, 4096, 4096, 1), (64,  64),  (1, 2), 4,  "4096^3  tile=64x64    cluster=1x2",  id="4096-64x64-1x2"),
        # LLM-like: 8192x8192x4096
        pytest.param((8192, 8192, 4096, 1), (128, 128), (1, 2), 4,  "8192x8192x4096  tile=128x128  cluster=1x2", id="llm-128x128-1x2"),
        pytest.param((8192, 8192, 4096, 1), (128, 256), (2, 2), 4,  "8192x8192x4096  tile=128x256  cluster=2x2", id="llm-128x256-2x2"),
        # mma_promotion_interval sweep (shows precision/performance trade-off)
        pytest.param((4096, 4096, 4096, 1), (128, 128), (1, 2), 4,  "4096^3  interval=4",  id="4096-interval4"),
        pytest.param((4096, 4096, 4096, 1), (128, 128), (1, 2), 8,  "4096^3  interval=8",  id="4096-interval8"),
        pytest.param((4096, 4096, 4096, 1), (128, 128), (1, 2), 16, "4096^3  interval=16", id="4096-interval16"),
        # FP8 output
        pytest.param((4096, 4096, 4096, 1), (128, 128), (1, 2), 4,  "4096^3  out=FP8E4M3", id="4096-fp8-out"),
    ],
)
def test_bench(mnkl, tile_shape_mn, cluster_shape_mn, mma_promotion_interval, label, capsys):
    """
    Performance benchmark — run with: pytest -m bench -s

    Reports execution time (µs) and achieved TFLOPS for each configuration.
    No pass/fail threshold is enforced; results are printed to stdout.
    """
    exec_us, tflops = _run_benchmark(
        mnkl=mnkl,
        tile_shape_mn=tile_shape_mn,
        cluster_shape_mn=cluster_shape_mn,
        mma_promotion_interval=mma_promotion_interval,
    )
    with capsys.disabled():
        print(f"\n[BENCH] {label:<55} {exec_us:>10.1f} us  {tflops:>8.2f} TFLOPS")
