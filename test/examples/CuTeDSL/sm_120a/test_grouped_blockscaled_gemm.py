# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

from typing import List, Tuple, Type

import pytest
import torch

import cutlass
from blackwell_geforce.kernel.blockscaled_grouped_gemm.grouped_blockscaled_gemm import (
    Sm120GroupedBlockScaledGemmKernel,
    run,
)


def _require_sm120():
    if not torch.cuda.is_available() or torch.cuda.get_device_capability() != (12, 0):
        pytest.skip("This test requires an SM120 GPU")


def _run_case(
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    tile_shape_mnk: Tuple[int, int, int] = (128, 128, 128),
    epi_tile: Tuple[int, int] = (64, 32),
    c_major: str = "n",
    host_problem_shape_available: bool = True,
    use_cached_problem_shapes: bool = True,
    tolerance: float = 1e-1,
):
    _require_sm120()
    assert Sm120GroupedBlockScaledGemmKernel.can_implement(
        a_dtype,
        b_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        tile_shape_mnk,
        epi_tile,
        problem_sizes_mnkl,
        "k",
        "k",
        c_major,
    )
    run(
        num_groups=len(problem_sizes_mnkl),
        problem_sizes_mnkl=problem_sizes_mnkl,
        host_problem_shape_available=host_problem_shape_available,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        c_dtype=c_dtype,
        a_major="k",
        b_major="k",
        c_major=c_major,
        tile_shape_mnk=tile_shape_mnk,
        epi_tile=epi_tile,
        tolerance=tolerance,
        warmup_iterations=0,
        iterations=1,
        skip_ref_check=False,
        use_cold_l2=False,
        use_cached_problem_shapes=use_cached_problem_shapes,
    )


# ---------------------------------------------------------------------------
# Functional tests — all supported block-scaled formats (NVFP4, MXFP4, MXFP8, Mixed)
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize(
    "a_dtype, b_dtype, sf_dtype, sf_vec_size, tile_shape_mnk",
    [
        # NVFP4 with both supported K tiles
        (
            cutlass.Float4E2M1FN,
            cutlass.Float4E2M1FN,
            cutlass.Float8E4M3FN,
            16,
            (128, 128, 128),
        ),
        (
            cutlass.Float4E2M1FN,
            cutlass.Float4E2M1FN,
            cutlass.Float8E4M3FN,
            16,
            (128, 128, 256),
        ),
        # MXFP4
        (
            cutlass.Float4E2M1FN,
            cutlass.Float4E2M1FN,
            cutlass.Float8E8M0FNU,
            32,
            (128, 128, 128),
        ),
        # MXFP8 (E4M3FN and E5M2)
        (
            cutlass.Float8E4M3FN,
            cutlass.Float8E4M3FN,
            cutlass.Float8E8M0FNU,
            32,
            (128, 128, 128),
        ),
        (
            cutlass.Float8E5M2,
            cutlass.Float8E5M2,
            cutlass.Float8E8M0FNU,
            32,
            (128, 128, 128),
        ),
        # Mixed FP4 x FP8 (all 4 operand combinations)
        (
            cutlass.Float4E2M1FN,
            cutlass.Float8E4M3FN,
            cutlass.Float8E8M0FNU,
            32,
            (128, 128, 128),
        ),
        (
            cutlass.Float4E2M1FN,
            cutlass.Float8E5M2,
            cutlass.Float8E8M0FNU,
            32,
            (128, 128, 128),
        ),
        (
            cutlass.Float8E4M3FN,
            cutlass.Float4E2M1FN,
            cutlass.Float8E8M0FNU,
            32,
            (128, 128, 128),
        ),
        (
            cutlass.Float8E5M2,
            cutlass.Float4E2M1FN,
            cutlass.Float8E8M0FNU,
            32,
            (128, 128, 128),
        ),
    ],
)
def test_grouped_blockscaled_gemm_formats(
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    tile_shape_mnk: Tuple[int, int, int],
):
    """Verify NVFP4, MXFP4, MXFP8, and mixed FP4xFP8 across heterogeneous groups."""
    problem_sizes_mnkl = [
        (192, 160, 256, 1),
        (128, 384, 128, 1),
        (320, 128, 512, 1),
    ]
    _run_case(
        problem_sizes_mnkl=problem_sizes_mnkl,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        c_dtype=cutlass.BFloat16,
        tile_shape_mnk=tile_shape_mnk,
        epi_tile=(64, 32),
        c_major="n",
    )


# ---------------------------------------------------------------------------
# Functional tests — output dtypes, layouts, and epilogue tiles
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize(
    "c_dtype, c_major, epi_tile",
    [
        (cutlass.Float16, "n", (64, 32)),
        (cutlass.Float16, "m", (64, 32)),
        (cutlass.BFloat16, "m", (64, 32)),
        (cutlass.BFloat16, "n", (128, 128)),
        (cutlass.Float32, "n", (64, 32)),
        (cutlass.Float32, "m", (64, 32)),
        (cutlass.Float8E4M3FN, "n", (64, 32)),
        (cutlass.Float8E5M2, "m", (64, 32)),
    ],
)
def test_grouped_blockscaled_gemm_epilogue(
    c_dtype: Type[cutlass.Numeric],
    c_major: str,
    epi_tile: Tuple[int, int],
):
    """Verify all supported output dtypes, row/col major C layouts, and epi tiles."""
    problem_sizes_mnkl = [
        (256, 192, 256, 1),
        (160, 256, 384, 1),
    ]
    tol = 2e-1 if c_dtype in (cutlass.Float8E4M3FN, cutlass.Float8E5M2) else 1e-1
    _run_case(
        problem_sizes_mnkl=problem_sizes_mnkl,
        a_dtype=cutlass.Float4E2M1FN,
        b_dtype=cutlass.Float4E2M1FN,
        sf_dtype=cutlass.Float8E4M3FN,
        sf_vec_size=16,
        c_dtype=c_dtype,
        tile_shape_mnk=(128, 128, 128),
        epi_tile=epi_tile,
        c_major=c_major,
        tolerance=tol,
    )


# ---------------------------------------------------------------------------
# Functional tests — edge cases (single group, K=0 groups, >32 groups, scheduler modes)
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize(
    "case_name, problem_sizes_mnkl, host_problem_shape_available, use_cached_problem_shapes",
    [
        # Single group with non-tile-multiple M, N, K
        ("single_group_tail", [(160, 192, 160, 1)], True, True),
        # Leading K=0 group followed by valid work
        ("leading_k_zero", [(128, 128, 0, 1), (256, 256, 256, 1)], True, True),
        # Consecutive middle K=0 groups (stresses pingpong peer K-tile advancement)
        (
            "middle_consecutive_k_zero",
            [
                (128, 128, 256, 1),
                (256, 128, 0, 1),
                (128, 256, 0, 1),
                (192, 192, 128, 1),
            ],
            True,
            True,
        ),
        # All K=0 groups (outputs must be zeroed cleanly without deadlock)
        ("all_k_zero", [(128, 128, 0, 1), (256, 128, 0, 1)], True, True),
        # Device-only problem shapes (host_problem_shape_available=False)
        (
            "device_only_shapes",
            [(256, 256, 256, 1), (128, 384, 512, 1), (384, 128, 128, 1)],
            False,
            True,
        ),
        # Uncached problem shape path (use_cached_problem_shapes=False)
        (
            "uncached_shapes",
            [(256, 256, 256, 1), (192, 160, 384, 1)],
            True,
            False,
        ),
        # Multi-window scheduler group search (>32 groups exercises 32-lane prefix-sum loop)
        (
            "many_groups_40",
            [
                (
                    128 + (i % 3) * 64,
                    128 + ((i + 1) % 3) * 64,
                    0 if i % 11 == 0 else 128 * (1 + (i % 3)),
                    1,
                )
                for i in range(40)
            ],
            True,
            True,
        ),
    ],
)
def test_grouped_blockscaled_gemm_edge_cases(
    case_name: str,
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    host_problem_shape_available: bool,
    use_cached_problem_shapes: bool,
):
    """Exercise scheduler, K=0 handling, >32-group search, and pingpong parity edge cases."""
    _run_case(
        problem_sizes_mnkl=problem_sizes_mnkl,
        a_dtype=cutlass.Float4E2M1FN,
        b_dtype=cutlass.Float4E2M1FN,
        sf_dtype=cutlass.Float8E4M3FN,
        sf_vec_size=16,
        c_dtype=cutlass.BFloat16,
        tile_shape_mnk=(128, 128, 128),
        epi_tile=(64, 32),
        c_major="n",
        host_problem_shape_available=host_problem_shape_available,
        use_cached_problem_shapes=use_cached_problem_shapes,
    )


@pytest.mark.L0
def test_grouped_blockscaled_gemm_large_persistent():
    """Multi-wave persistent workload verifying cross-group tensormap reuse at scale."""
    _run_case(
        problem_sizes_mnkl=[(1024, 1024, 1024, 1)] * 8,
        a_dtype=cutlass.Float4E2M1FN,
        b_dtype=cutlass.Float4E2M1FN,
        sf_dtype=cutlass.Float8E4M3FN,
        sf_vec_size=16,
        c_dtype=cutlass.BFloat16,
        tile_shape_mnk=(128, 128, 128),
        epi_tile=(64, 32),
        c_major="n",
    )


# ---------------------------------------------------------------------------
# Negative validation tests (host-only, no GPU required)
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize(
    "a_dtype, b_dtype, sf_dtype, sf_vec_size, c_dtype",
    [
        # Unsupported operand dtype
        (cutlass.Float16, cutlass.Float16, cutlass.Float8E8M0FNU, 32, cutlass.Float16),
        # Unsupported sf_vec_size
        (
            cutlass.Float4E2M1FN,
            cutlass.Float4E2M1FN,
            cutlass.Float8E8M0FNU,
            64,
            cutlass.BFloat16,
        ),
        (
            cutlass.Float4E2M1FN,
            cutlass.Float4E2M1FN,
            cutlass.Float8E4M3FN,
            32,
            cutlass.BFloat16,
        ),
        # Mismatched FP8 x FP8 (E4M3FN x E5M2 not supported)
        (
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
            cutlass.Float8E8M0FNU,
            32,
            cutlass.BFloat16,
        ),
        # Mixed FP4 x FP8 requires sf_vec_size=32 and Float8E8M0FNU
        (
            cutlass.Float4E2M1FN,
            cutlass.Float8E4M3FN,
            cutlass.Float8E4M3FN,
            16,
            cutlass.BFloat16,
        ),
        # Unsupported output dtype
        (
            cutlass.Float4E2M1FN,
            cutlass.Float4E2M1FN,
            cutlass.Float8E4M3FN,
            16,
            cutlass.Int32,
        ),
    ],
)
def test_invalid_dtypes_and_sf_vec_size(
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
):
    assert not Sm120GroupedBlockScaledGemmKernel.can_implement(
        a_dtype,
        b_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        (128, 128, 128),
        (64, 32),
        [(128, 128, 128, 1)],
    )
    with pytest.raises((ValueError, TypeError, cutlass.testing.CantImplementError)):
        run(
            num_groups=1,
            problem_sizes_mnkl=[(128, 128, 128, 1)],
            a_dtype=a_dtype,
            b_dtype=b_dtype,
            sf_dtype=sf_dtype,
            sf_vec_size=sf_vec_size,
            c_dtype=c_dtype,
        )


@pytest.mark.L0
@pytest.mark.parametrize(
    "a_major, b_major, c_major",
    [
        ("m", "k", "n"),
        ("k", "n", "n"),
        ("k", "k", "k"),
    ],
)
def test_invalid_layouts(a_major: str, b_major: str, c_major: str):
    assert not Sm120GroupedBlockScaledGemmKernel.can_implement(
        cutlass.Float4E2M1FN,
        cutlass.Float4E2M1FN,
        cutlass.Float8E4M3FN,
        16,
        cutlass.BFloat16,
        (128, 128, 128),
        (64, 32),
        [(128, 128, 128, 1)],
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
    )


@pytest.mark.L0
@pytest.mark.parametrize(
    "a_dtype, b_dtype, sf_dtype, sf_vec_size, c_dtype, tile_shape_mnk, epi_tile",
    [
        # MXFP4 / MXFP8 / Mixed only support K=128
        (
            cutlass.Float4E2M1FN,
            cutlass.Float4E2M1FN,
            cutlass.Float8E8M0FNU,
            32,
            cutlass.BFloat16,
            (128, 128, 256),
            (64, 32),
        ),
        (
            cutlass.Float8E4M3FN,
            cutlass.Float8E4M3FN,
            cutlass.Float8E8M0FNU,
            32,
            cutlass.BFloat16,
            (128, 128, 256),
            (64, 32),
        ),
        # Unsupported epilogue tile
        (
            cutlass.Float4E2M1FN,
            cutlass.Float4E2M1FN,
            cutlass.Float8E4M3FN,
            16,
            cutlass.BFloat16,
            (128, 128, 128),
            (128, 32),
        ),
        # Exceeds SM120 SMEM capacity: MXFP8 + Float32 + full (128, 128) epilogue
        (
            cutlass.Float8E4M3FN,
            cutlass.Float8E4M3FN,
            cutlass.Float8E8M0FNU,
            32,
            cutlass.Float32,
            (128, 128, 128),
            (128, 128),
        ),
    ],
)
def test_invalid_tile_and_epi_shape(
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    tile_shape_mnk: Tuple[int, int, int],
    epi_tile: Tuple[int, int],
):
    assert not Sm120GroupedBlockScaledGemmKernel.can_implement(
        a_dtype,
        b_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        tile_shape_mnk,
        epi_tile,
        [(128, 128, 128, 1)],
    )


@pytest.mark.L0
@pytest.mark.parametrize(
    "problem_sizes_mnkl",
    [
        # Empty group list
        [],
        # K not 32-element aligned for FP4
        [(128, 128, 100, 1)],
        # N not 8-element aligned for n-major BF16 C
        [(128, 130, 128, 1)],
        # Zero M or N
        [(0, 128, 128, 1)],
    ],
)
def test_invalid_tensor_alignment(problem_sizes_mnkl: List[Tuple[int, int, int, int]]):
    assert not Sm120GroupedBlockScaledGemmKernel.can_implement(
        cutlass.Float4E2M1FN,
        cutlass.Float4E2M1FN,
        cutlass.Float8E4M3FN,
        16,
        cutlass.BFloat16,
        (128, 128, 128),
        (64, 32),
        problem_sizes_mnkl,
    )


@pytest.mark.L0
def test_num_groups_mismatch():
    with pytest.raises(ValueError, match="num_groups must match"):
        run(
            num_groups=3,
            problem_sizes_mnkl=[(128, 128, 128, 1), (128, 128, 128, 1)],
        )


@pytest.mark.L0
def test_batch_dimension_not_one():
    with pytest.raises(ValueError, match="l == 1"):
        run(
            num_groups=2,
            problem_sizes_mnkl=[(128, 128, 128, 1), (128, 128, 128, 2)],
        )
