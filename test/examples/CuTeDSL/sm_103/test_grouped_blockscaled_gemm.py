# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
Tests for sm103_grouped_blockscaled_gemm.py (SM103 / B300).

Covers:
- Functional correctness across dtype/tiler/cluster/layout combinations
- Single-group and multi-group problem sets
- host_problem_shape_available = True / False
- All `can_implement` negative paths (dtype, layout, tiler/cluster, alignment)
- New run() validation guards: num_groups mismatch and l != 1
"""

from typing import List, Tuple, Type

import pytest

import cutlass
from blackwell.sm103_grouped_blockscaled_gemm import (
    Sm103GroupedBlockScaledGemmKernel,
    run,
)

pytestmark = [pytest.mark.arch(["103"])]


def _run_case(
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    ab_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    host_problem_shape_available: bool,
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
):
    run(
        num_groups=len(problem_sizes_mnkl),
        problem_sizes_mnkl=problem_sizes_mnkl,
        host_problem_shape_available=host_problem_shape_available,
        ab_dtype=ab_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        c_dtype=c_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        mma_tiler_mn=mma_tiler_mn,
        cluster_shape_mn=cluster_shape_mn,
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
    )


# ---------------------------------------------------------------------------
# Functional tests
# ---------------------------------------------------------------------------

@pytest.mark.parametrize(
    "problem_sizes_mnkl, sf_dtype, sf_vec_size, c_dtype, mma_tiler_mn, cluster_shape_mn, c_major, host_problem_shape_available",
    [
        (
            [(128, 128, 128, 1)],
            cutlass.Float8E8M0FNU,
            32,
            cutlass.Float32,
            (128, 128),
            (1, 1),
            "n",
            True,
        ),
        (
            [(128, 256, 128, 1), (256, 128, 256, 1)],
            cutlass.Float8E4M3FN,
            16,
            cutlass.Float16,
            (128, 256),
            (1, 2),
            "m",
            False,
        ),
        (
            [(256, 128, 256, 1)],
            cutlass.Float8E8M0FNU,
            32,
            cutlass.BFloat16,
            (256, 128),
            (2, 1),
            "n",
            True,
        ),
    ],
)
def test_grouped_blockscaled_gemm(
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    c_major: str,
    host_problem_shape_available: bool,
):
    assert Sm103GroupedBlockScaledGemmKernel.can_implement(
        cutlass.Float4E2M1FN,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        mma_tiler_mn,
        cluster_shape_mn,
        problem_sizes_mnkl,
        "k",
        "k",
        c_major,
    )
    _run_case(
        problem_sizes_mnkl,
        cutlass.Float4E2M1FN,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        "k",
        "k",
        c_major,
        mma_tiler_mn,
        cluster_shape_mn,
        host_problem_shape_available,
    )


# ---------------------------------------------------------------------------
# Negative tests — invalid dtypes / sf_vec_size
# ---------------------------------------------------------------------------

@pytest.mark.parametrize(
    "ab_dtype, sf_dtype, sf_vec_size, c_dtype",
    [
        # Non-FP4 A/B dtype
        (cutlass.Float8E5M2,  cutlass.Float8E8M0FNU, 32, cutlass.Float32),
        (cutlass.Float8E4M3FN, cutlass.Float8E8M0FNU, 32, cutlass.Float32),
        # Unsupported sf_vec_size
        (cutlass.Float4E2M1FN, cutlass.Float8E8M0FNU, 64, cutlass.Float32),
        (cutlass.Float4E2M1FN, cutlass.Float8E8M0FNU,  8, cutlass.Float32),
        # Float8E4M3FN sf_dtype is only valid with sf_vec_size=16, not 32
        (cutlass.Float4E2M1FN, cutlass.Float8E4M3FN,  32, cutlass.Float32),
    ],
)
def test_invalid_dtypes_and_sf_vec_size(
    ab_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
):
    problem_sizes_mnkl = [(128, 128, 128, 1)]
    mma_tiler_mn = (128, 128)
    cluster_shape_mn = (1, 1)
    with pytest.raises((ValueError, TypeError)):
        run(
            num_groups=1,
            problem_sizes_mnkl=problem_sizes_mnkl,
            host_problem_shape_available=True,
            ab_dtype=ab_dtype,
            sf_dtype=sf_dtype,
            sf_vec_size=sf_vec_size,
            c_dtype=c_dtype,
            a_major="k",
            b_major="k",
            c_major="n",
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            tolerance=1e-1,
        )


# ---------------------------------------------------------------------------
# Negative tests — invalid layouts
# ---------------------------------------------------------------------------

@pytest.mark.parametrize(
    "a_major, b_major, c_major",
    [
        # FP4 requires a_major="k" and b_major="k"
        ("m", "k", "n"),
        ("k", "n", "n"),
        ("m", "n", "n"),
    ],
)
def test_invalid_layouts(a_major: str, b_major: str, c_major: str):
    problem_sizes_mnkl = [(128, 128, 128, 1)]
    mma_tiler_mn = (128, 128)
    cluster_shape_mn = (1, 1)
    with pytest.raises((ValueError, TypeError)):
        run(
            num_groups=1,
            problem_sizes_mnkl=problem_sizes_mnkl,
            host_problem_shape_available=True,
            ab_dtype=cutlass.Float4E2M1FN,
            sf_dtype=cutlass.Float8E8M0FNU,
            sf_vec_size=32,
            c_dtype=cutlass.Float32,
            a_major=a_major,
            b_major=b_major,
            c_major=c_major,
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            tolerance=1e-1,
        )


# ---------------------------------------------------------------------------
# Negative tests — invalid mma_tiler / cluster_shape
# ---------------------------------------------------------------------------

@pytest.mark.parametrize(
    "mma_tiler_mn, cluster_shape_mn",
    [
        # mma_tiler N not in {128, 256}
        ((128, 64),  (1, 1)),
        ((128, 192), (1, 1)),
        # mma_tiler M not in {128, 256}
        ((64, 128),  (1, 1)),
        # cluster product > 16
        ((128, 128), (4, 8)),
        # cluster dim > 4
        ((128, 128), (8, 1)),
        # cluster not power of 2
        ((128, 128), (3, 1)),
        # 2-CTA MMA (mma_tiler_M=256) requires cluster_M divisible by 2
        ((256, 128), (1, 1)),
    ],
)
def test_invalid_mma_tiler_and_cluster_shape(
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
):
    problem_sizes_mnkl = [(128, 128, 128, 1)]
    with pytest.raises((ValueError, TypeError)):
        run(
            num_groups=1,
            problem_sizes_mnkl=problem_sizes_mnkl,
            host_problem_shape_available=True,
            ab_dtype=cutlass.Float4E2M1FN,
            sf_dtype=cutlass.Float8E8M0FNU,
            sf_vec_size=32,
            c_dtype=cutlass.Float32,
            a_major="k",
            b_major="k",
            c_major="n",
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            tolerance=1e-1,
        )


# ---------------------------------------------------------------------------
# Negative tests — invalid tensor alignment
# ---------------------------------------------------------------------------

@pytest.mark.parametrize(
    "problem_sizes_mnkl",
    [
        # K not 32-element aligned for FP4 (contiguous dim for k-major A is K)
        [(128, 128, 100, 1)],
        # N not aligned for n-major C; A/B remain valid because they are k-major.
        [(128, 130, 128, 1)],
    ],
)
def test_invalid_tensor_alignment(problem_sizes_mnkl: List[Tuple[int, int, int, int]]):
    mma_tiler_mn = (128, 128)
    cluster_shape_mn = (1, 1)
    with pytest.raises((ValueError, TypeError)):
        run(
            num_groups=len(problem_sizes_mnkl),
            problem_sizes_mnkl=problem_sizes_mnkl,
            host_problem_shape_available=True,
            ab_dtype=cutlass.Float4E2M1FN,
            sf_dtype=cutlass.Float8E8M0FNU,
            sf_vec_size=32,
            c_dtype=cutlass.Float32,
            a_major="k",
            b_major="k",
            c_major="n",
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            tolerance=1e-1,
        )


# ---------------------------------------------------------------------------
# Negative tests — run() validation guards (added in second commit)
# ---------------------------------------------------------------------------

def test_num_groups_mismatch():
    """run() must raise ValueError when num_groups != len(problem_sizes_mnkl)."""
    with pytest.raises(ValueError, match="num_groups must match"):
        run(
            num_groups=3,
            problem_sizes_mnkl=[(128, 128, 128, 1), (128, 128, 128, 1)],
            host_problem_shape_available=True,
            ab_dtype=cutlass.Float4E2M1FN,
            sf_dtype=cutlass.Float8E8M0FNU,
            sf_vec_size=32,
            c_dtype=cutlass.Float32,
            a_major="k",
            b_major="k",
            c_major="n",
            mma_tiler_mn=(128, 128),
            cluster_shape_mn=(1, 1),
            tolerance=1e-1,
        )


def test_batch_dimension_not_one():
    """run() must raise ValueError when any group has l != 1."""
    with pytest.raises(ValueError, match="l == 1"):
        run(
            num_groups=2,
            problem_sizes_mnkl=[(128, 128, 128, 1), (128, 128, 128, 2)],
            host_problem_shape_available=True,
            ab_dtype=cutlass.Float4E2M1FN,
            sf_dtype=cutlass.Float8E8M0FNU,
            sf_vec_size=32,
            c_dtype=cutlass.Float32,
            a_major="k",
            b_major="k",
            c_major="n",
            mma_tiler_mn=(128, 128),
            cluster_shape_mn=(1, 1),
            tolerance=1e-1,
        )
