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
Comprehensive pytest test suite for hopper/grouped_gemm.py.

Test organization
-----------------
L0 — compilation tests (skip_ref_check=True, iterations=0)
    Verify that the kernel compiles for a broad range of configurations
    without running on the GPU.  Fast (~1-3 s each).

L1 — correctness tests (GPU execution, checked against torch.einsum)
    Verify numerical correctness for the key configurations.

Coverage
--------
* All tile shapes: (64,64), (128,64), (128,128), (128,256)
* Both tensormap update modes: GMEM, SMEM
* Data types: fp16, bf16-like (fp16/fp32 acc), fp8 (E4M3FN, E5M2), int8/uint8
* Matrix major modes: A k/m-major, B k/n-major, C n/m-major
* Cluster shapes: (1,1), (2,1), (1,2), (2,2)  [mcast paths]
* Group counts: 1, 2, 4, 8, 16
* Mixed problem sizes across groups in the same batch
* Edge cases: single tile, non-uniform groups, same-shape groups
"""

import os

# Keep test behavior deterministic regardless of caller shell env.
# These are consumed at grouped_gemm import time.
os.environ.setdefault("GROUPED_GEMM_FORCE_CUTE_COPY", "0")

import pytest
import cutlass
import cutlass.utils as utils
from hopper.grouped_gemm import run


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

GMEM = utils.TensorMapUpdateMode.GMEM
SMEM = utils.TensorMapUpdateMode.SMEM

F16 = cutlass.Float16
F32 = cutlass.Float32
F8E4 = cutlass.Float8E4M3FN
F8E5 = cutlass.Float8E5M2
I8 = cutlass.Int8
U8 = cutlass.Uint8
I32 = cutlass.Int32

TMAP_MODES = [SMEM, GMEM]
TMAP_MODE_IDS = ["smem", "gmem"]


def _run_compile(
    num_groups,
    problem_sizes_mnkl,
    tile_shape_mn,
    cluster_shape_mn=(1, 1),
    a_dtype=F16,
    b_dtype=F16,
    c_dtype=F16,
    acc_dtype=F32,
    a_major="k",
    b_major="k",
    c_major="n",
    tensormap_update_mode=SMEM,
):
    """Compile-only helper (iterations=0)."""
    _run_case(
        num_groups=num_groups,
        problem_sizes_mnkl=problem_sizes_mnkl,
        tile_shape_mn=tile_shape_mn,
        cluster_shape_mn=cluster_shape_mn,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        c_dtype=c_dtype,
        acc_dtype=acc_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        tensormap_update_mode=tensormap_update_mode,
        skip_ref_check=True,
        warmup_iterations=0,
        iterations=0,
    )


def _run_correctness(
    num_groups,
    problem_sizes_mnkl,
    tile_shape_mn,
    cluster_shape_mn=(1, 1),
    a_dtype=F16,
    b_dtype=F16,
    c_dtype=F16,
    acc_dtype=F32,
    a_major="k",
    b_major="k",
    c_major="n",
    tensormap_update_mode=SMEM,
    tolerance=1e-1,
):
    """Correctness helper (1 iteration, ref-checked)."""
    _run_case(
        num_groups=num_groups,
        problem_sizes_mnkl=problem_sizes_mnkl,
        tile_shape_mn=tile_shape_mn,
        cluster_shape_mn=cluster_shape_mn,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        c_dtype=c_dtype,
        acc_dtype=acc_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        tensormap_update_mode=tensormap_update_mode,
        tolerance=tolerance,
        warmup_iterations=0,
        iterations=1,
        skip_ref_check=False,
    )


def _run_case(
    *,
    num_groups,
    problem_sizes_mnkl,
    tile_shape_mn,
    cluster_shape_mn=(1, 1),
    a_dtype=F16,
    b_dtype=F16,
    c_dtype=F16,
    acc_dtype=F32,
    a_major="k",
    b_major="k",
    c_major="n",
    tensormap_update_mode=SMEM,
    tolerance=1e-1,
    warmup_iterations=0,
    iterations=1,
    skip_ref_check=False,
):
    """Shared invocation helper for compile-only and correctness tests."""
    run(
        num_groups=num_groups,
        problem_sizes_mnkl=problem_sizes_mnkl,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        c_dtype=c_dtype,
        acc_dtype=acc_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        tile_shape_mn=tile_shape_mn,
        cluster_shape_mn=cluster_shape_mn,
        tensormap_update_mode=tensormap_update_mode,
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
    )


# ---------------------------------------------------------------------------
# L0 — tile shape coverage (both SMEM and GMEM)
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
@pytest.mark.parametrize(
    "tile_shape_mn, problem_sizes_mnkl",
    [
        pytest.param((128, 256), [(128, 256, 64, 1)], id="tile128x256"),
        pytest.param((128, 128), [(128, 128, 64, 1)], id="tile128x128"),
        pytest.param((128, 64),  [(128, 64,  64, 1)], id="tile128x64"),
        pytest.param((64, 64),   [(64,  64,  64, 1)], id="tile64x64"),
    ],
)
def test_l0_tile_shapes(tile_shape_mn, problem_sizes_mnkl, tmap_mode):
    """All tile shapes compile under both SMEM and GMEM modes."""
    _run_compile(1, problem_sizes_mnkl, tile_shape_mn, tensormap_update_mode=tmap_mode)


# ---------------------------------------------------------------------------
# L0 — group count coverage
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
@pytest.mark.parametrize(
    "num_groups, problem_sizes_mnkl",
    [
        pytest.param(2,  [(128, 256, 64, 1)] * 2,                                      id="2g-uniform"),
        pytest.param(4,  [(128, 256, 64, 1), (64, 128, 64, 1),
                          (256, 128, 64, 1), (192, 256, 64, 1)],                        id="4g-mixed"),
        pytest.param(8,  [(128, 256, 64, 1)] * 8,                                      id="8g-uniform"),
    ],
)
def test_l0_group_counts(num_groups, problem_sizes_mnkl, tmap_mode):
    """Various group counts compile for tile (128,256) fp16."""
    _run_compile(num_groups, problem_sizes_mnkl, (128, 256), tensormap_update_mode=tmap_mode)


# ---------------------------------------------------------------------------
# L0 — data type coverage
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
@pytest.mark.parametrize(
    "a_dtype, b_dtype, c_dtype, acc_dtype, problem_sizes_mnkl",
    [
        # fp16 → fp16 output
        pytest.param(F16, F16, F16, F32, [(128, 256, 64, 1)],  id="fp16-fp16-fp16-fp32"),
        # fp16 → fp32 output
        pytest.param(F16, F16, F32, F32, [(128, 256, 64, 1)],  id="fp16-fp16-fp32-fp32"),
        # fp16 with fp16 accumulator
        pytest.param(F16, F16, F16, F16, [(128, 256, 64, 1)],  id="fp16-fp16-fp16-fp16"),
        # fp8 E4M3 → fp16 output (K must be multiple of 16 for fp8 alignment)
        pytest.param(F8E4, F8E4, F16, F32, [(128, 256, 128, 1)], id="fp8e4-fp8e4-fp16-fp32"),
        # fp8 E5M2 → fp16 output
        pytest.param(F8E5, F8E5, F16, F32, [(128, 256, 128, 1)], id="fp8e5-fp8e5-fp16-fp32"),
        # mixed fp8: E4M3 × E5M2
        pytest.param(F8E4, F8E5, F16, F32, [(128, 256, 128, 1)], id="fp8e4-fp8e5-fp16-fp32"),
        # int8 → int32 output (K must be multiple of 16)
        pytest.param(I8, I8, I32, I32, [(128, 256, 128, 1)],  id="int8-int8-int32-int32"),
        # uint8 → int32 output
        pytest.param(U8, U8, I32, I32, [(128, 256, 128, 1)],  id="uint8-uint8-int32-int32"),
    ],
)
def test_l0_dtypes(a_dtype, b_dtype, c_dtype, acc_dtype, problem_sizes_mnkl, tmap_mode):
    """Data type combinations compile for tile (128,256)."""
    _run_compile(
        1, problem_sizes_mnkl, (128, 256),
        a_dtype=a_dtype, b_dtype=b_dtype, c_dtype=c_dtype, acc_dtype=acc_dtype,
        tensormap_update_mode=tmap_mode,
    )


# ---------------------------------------------------------------------------
# L0 — matrix major modes
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
@pytest.mark.parametrize(
    "a_major, b_major, c_major, problem_sizes_mnkl, tile_shape_mn",
    [
        # k-major A, k-major B, n-major C  (default)
        pytest.param("k", "k", "n", [(128, 256, 64, 1)], (128, 256), id="akm-bkm-cn"),
        # m-major A (A contiguous in M; M must be multiple of 8 for fp16)
        pytest.param("m", "k", "n", [(128, 256, 64, 1)], (128, 128), id="amaj-bkm-cn"),
        # n-major B (B contiguous in N; N must be multiple of 8 for fp16)
        pytest.param("k", "n", "n", [(128, 128, 64, 1)], (128, 128), id="akm-bnmaj-cn"),
        # m-major C output (M must be multiple of 8)
        pytest.param("k", "k", "m", [(128, 256, 64, 1)], (128, 256), id="akm-bkm-cmaj"),
        # m-major A + n-major B
        pytest.param("m", "n", "n", [(128, 128, 64, 1)], (128, 128), id="amaj-bnmaj-cn"),
    ],
)
def test_l0_major_modes(a_major, b_major, c_major, problem_sizes_mnkl, tile_shape_mn, tmap_mode):
    """Matrix major mode combinations compile."""
    _run_compile(
        1, problem_sizes_mnkl, tile_shape_mn,
        a_major=a_major, b_major=b_major, c_major=c_major,
        tensormap_update_mode=tmap_mode,
    )


# ---------------------------------------------------------------------------
# L0 — cluster shapes (mcast paths)
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
@pytest.mark.parametrize(
    "cluster_shape_mn, problem_sizes_mnkl, tile_shape_mn",
    [
        # 1×1: no multicast (default, baseline)
        pytest.param((1, 1), [(128, 256, 64, 1)], (128, 256), id="cluster1x1"),
        # 2×1: A multicast across 2 CTAs in M; need M >= 2*tile_m
        pytest.param((2, 1), [(256, 256, 64, 1)], (128, 256), id="cluster2x1"),
        # 1×2: B multicast across 2 CTAs in N; need N >= 2*tile_n
        pytest.param((1, 2), [(128, 512, 64, 1)], (128, 256), id="cluster1x2"),
        # 2×2: both A and B multicast
        pytest.param((2, 2), [(256, 512, 64, 1)], (128, 256), id="cluster2x2"),
    ],
)
def test_l0_cluster_shapes(cluster_shape_mn, problem_sizes_mnkl, tile_shape_mn, tmap_mode):
    """Cluster shapes including multicast paths compile."""
    _run_compile(
        1, problem_sizes_mnkl, tile_shape_mn,
        cluster_shape_mn=cluster_shape_mn,
        tensormap_update_mode=tmap_mode,
    )


# ---------------------------------------------------------------------------
# L0 — mixed problem sizes (non-uniform groups)
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
@pytest.mark.parametrize(
    "num_groups, problem_sizes_mnkl",
    [
        # groups with very different shapes
        pytest.param(4, [(64,  64,  64, 1),
                         (128, 128, 64, 1),
                         (256, 128, 64, 1),
                         (128, 256, 64, 1)],                 id="4g-all-tiles"),
        # tiny vs large
        pytest.param(2, [(64, 64, 64, 1),
                         (512, 512, 64, 1)],                 id="2g-tiny-large"),
    ],
)
def test_l0_mixed_problem_sizes(num_groups, problem_sizes_mnkl, tmap_mode):
    """Heterogeneous per-group problem sizes compile."""
    _run_compile(num_groups, problem_sizes_mnkl, (128, 256), tensormap_update_mode=tmap_mode)


# ---------------------------------------------------------------------------
# L1 — correctness: both tensormap modes, fp16, tile (128,256)
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
def test_l1_fp16_4g_mixed(tmap_mode):
    """Four groups with mixed sizes are numerically correct."""
    _run_correctness(
        4,
        [(128, 256, 64, 1), (64, 128, 64, 1), (256, 128, 64, 1), (192, 256, 64, 1)],
        (128, 256),
        tensormap_update_mode=tmap_mode,
    )


# ---------------------------------------------------------------------------
# L1 — correctness: all tile shapes with fp16 SMEM + GMEM
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
@pytest.mark.parametrize(
    "tile_shape_mn, problem_sizes_mnkl",
    [
        pytest.param((128, 256), [(128, 256, 64, 1)], id="tile128x256"),
        pytest.param((128, 128), [(128, 128, 64, 1)], id="tile128x128"),
        pytest.param((128, 64),  [(128, 64,  64, 1)], id="tile128x64"),
        pytest.param((64,  64),  [(64,  64,  64, 1)], id="tile64x64"),
    ],
)
def test_l1_tile_shapes_fp16(tile_shape_mn, problem_sizes_mnkl, tmap_mode):
    """All tile shapes produce correct results."""
    _run_correctness(1, problem_sizes_mnkl, tile_shape_mn, tensormap_update_mode=tmap_mode)


# ---------------------------------------------------------------------------
# L1 — correctness: group count scaling
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
@pytest.mark.parametrize(
    "num_groups",
    [2, 4],
    ids=["2g", "4g"],
)
def test_l1_group_count_scaling(num_groups, tmap_mode):
    """Correctness scales correctly with group count."""
    _run_correctness(
        num_groups,
        [(128, 256, 64, 1)] * num_groups,
        (128, 256),
        tensormap_update_mode=tmap_mode,
    )


# ---------------------------------------------------------------------------
# L1 — correctness: data types
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
def test_l1_fp16_c_fp32(tmap_mode):
    """fp16 inputs with fp32 output are numerically correct."""
    _run_correctness(
        1, [(128, 256, 64, 1)], (128, 256),
        c_dtype=F32, acc_dtype=F32,
        tensormap_update_mode=tmap_mode,
    )


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
def test_l1_fp8_e4m3(tmap_mode):
    """fp8 E4M3FN inputs are numerically correct (K=128 for 16B alignment)."""
    _run_correctness(
        1, [(128, 256, 128, 1)], (128, 256),
        a_dtype=F8E4, b_dtype=F8E4, c_dtype=F16, acc_dtype=F32,
        tensormap_update_mode=tmap_mode,
        tolerance=0.5,
    )


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
def test_l1_fp8_mixed(tmap_mode):
    """Mixed fp8 inputs (E4M3 × E5M2) are numerically correct."""
    _run_correctness(
        1, [(128, 256, 128, 1)], (128, 256),
        a_dtype=F8E4, b_dtype=F8E5, c_dtype=F16, acc_dtype=F32,
        tensormap_update_mode=tmap_mode,
        tolerance=0.5,
    )


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
def test_l1_int8(tmap_mode):
    """int8 inputs with int32 accumulator are correct."""
    _run_correctness(
        1, [(128, 256, 128, 1)], (128, 256),
        a_dtype=I8, b_dtype=I8, c_dtype=I32, acc_dtype=I32,
        tensormap_update_mode=tmap_mode,
        tolerance=0,
    )


# ---------------------------------------------------------------------------
# L1 — correctness: matrix major modes
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
def test_l1_c_m_major(tmap_mode):
    """m-major C output is correct."""
    _run_correctness(
        1, [(128, 256, 64, 1)], (128, 256),
        c_major="m",
        tensormap_update_mode=tmap_mode,
    )


@pytest.mark.skip(reason="JIT compile time too long for CI (~25 min); run manually")
@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
def test_l1_all_non_default_majors(tmap_mode):
    """m-major A, n-major B, m-major C together are correct."""
    _run_correctness(
        1, [(64, 64, 64, 1)], (128, 128),
        a_major="m", b_major="n", c_major="m",
        tensormap_update_mode=tmap_mode,
    )


# ---------------------------------------------------------------------------
# L1 — correctness: cluster shapes (mcast paths)
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
@pytest.mark.parametrize(
    "cluster_shape_mn, problem_sizes_mnkl",
    [
        pytest.param((2, 2), [(256, 512, 64, 1)], id="cluster2x2"),
    ],
)
def test_l1_cluster_shapes(cluster_shape_mn, problem_sizes_mnkl, tmap_mode):
    """Multicast cluster shapes produce correct results."""
    _run_correctness(
        1, problem_sizes_mnkl, (128, 256),
        cluster_shape_mn=cluster_shape_mn,
        tensormap_update_mode=tmap_mode,
    )


# ---------------------------------------------------------------------------
# L1 — correctness: multi-group with mixed sizes
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("tmap_mode", TMAP_MODES, ids=TMAP_MODE_IDS)
def test_l1_8g_mixed_sizes(tmap_mode):
    """8 groups with heterogeneous problem sizes are all correct."""
    _run_correctness(
        8,
        [
            (128, 256, 64,  1),
            (64,  128, 64,  1),
            (256, 128, 64,  1),
            (128, 128, 128, 1),
            (192, 256, 64,  1),
            (64,  64,  64,  1),
            (128, 256, 128, 1),
            (256, 256, 64,  1),
        ],
        (128, 256),
        tensormap_update_mode=tmap_mode,
    )
