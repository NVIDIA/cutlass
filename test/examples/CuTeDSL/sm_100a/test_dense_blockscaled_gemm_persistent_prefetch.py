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
Test cases for dense_blockscaled_gemm_persistent_prefetch.py with TMA prefetch support.

Tests various configurations of:
- prefetch_dist: None (default auto), 0 (disabled), explicit values (2, 4)
- Data types: Float8E5M2, Float8E4M3FN, Float4E2M1FN with various scale factor types
- MMA tiler shapes and cluster shapes
- Scale factor vector sizes (16, 32)
- Tensor layouts
"""

from typing import Tuple, Type, Optional

import pytest

from blackwell.dense_blockscaled_gemm_persistent_prefetch import (
    Sm100BlockScaledPersistentDenseGemmKernel,
    run,
)

import cutlass
pytestmark = [pytest.mark.arch(["100a"])]

@pytest.mark.invalid_case(
    lambda: not Sm100BlockScaledPersistentDenseGemmKernel.can_implement(
        ab_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        mma_tiler_mn,
        cluster_shape_mn,
        mnkl[0],
        mnkl[1],
        mnkl[2],
        mnkl[3],
        a_major,
        b_major,
        c_major,
    )
)
@pytest.mark.parametrize(
    "mnkl",
    [
        (512, 512, 1024, 1),
        (512, 512, 128, 2),
        (64, 64, 32, 1),
    ],
)
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, sf_dtype",
    [
        (cutlass.Float8E5M2, cutlass.Float32, cutlass.Float8E8M0FNU),
        (cutlass.Float8E4M3FN, cutlass.Float16, cutlass.Float8E8M0FNU),
        (cutlass.Float8E5M2, cutlass.Float8E5M2, cutlass.Float8E8M0FNU),
        (cutlass.Float4E2M1FN, cutlass.Float32, cutlass.Float8E8M0FNU),
        (cutlass.Float4E2M1FN, cutlass.BFloat16, cutlass.Float8E4M3FN),
        (cutlass.Float4E2M1FN, cutlass.Float4E2M1FN, cutlass.Float8E4M3FN),
    ],
)
@pytest.mark.parametrize("sf_vec_size", [16, 32])
@pytest.mark.parametrize(
    "mma_tiler_mn",
    [
        (128, 64),
        (128, 128),
        (256, 64),
        (256, 128),
    ],
)
@pytest.mark.parametrize(
    "cluster_shape_mn",
    [
        (1, 1),
        (2, 1),
        (1, 2),
    ],
)
@pytest.mark.parametrize("a_major", ["k", "m"])
@pytest.mark.parametrize("b_major", ["k", "n"])
@pytest.mark.parametrize("c_major", ["n", "m"])
@pytest.mark.parametrize(
    "prefetch_dist",
    [
        None,  # Default: auto (uses num_ab_stage)
        0,     # Disabled
    ],
)
@pytest.mark.parametrize("tolerance", [1e-01])
def test_dense_blockscaled_gemm_prefetch(
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    prefetch_dist: Optional[int],
    tolerance: float,
):
    run(
        mnkl,
        ab_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        a_major,
        b_major,
        c_major,
        mma_tiler_mn,
        cluster_shape_mn,
        tolerance,
        prefetch_dist=prefetch_dist,
    )


@pytest.mark.invalid_case(
    lambda: not Sm100BlockScaledPersistentDenseGemmKernel.can_implement(
        ab_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        mma_tiler_mn,
        cluster_shape_mn,
        mnkl[0],
        mnkl[1],
        mnkl[2],
        mnkl[3],
        a_major,
        b_major,
        c_major,
    )
)
@pytest.mark.parametrize(
    "mnkl",
    [(512, 512, 1024, 1), (64, 64, 32, 1)],
)
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, sf_dtype",
    [
        (cutlass.Float8E5M2, cutlass.Float32, cutlass.Float8E8M0FNU),
        (cutlass.Float8E4M3FN, cutlass.Float16, cutlass.Float8E8M0FNU),
        (cutlass.Float4E2M1FN, cutlass.Float32, cutlass.Float8E8M0FNU),
        (cutlass.Float4E2M1FN, cutlass.BFloat16, cutlass.Float8E4M3FN),
    ],
)
@pytest.mark.parametrize("sf_vec_size", [16, 32])
@pytest.mark.parametrize(
    "mma_tiler_mn",
    [(128, 192), (128, 256), (256, 64), (256, 128)],
)
@pytest.mark.parametrize(
    "cluster_shape_mn",
    [(1, 1), (2, 2)],
)
@pytest.mark.parametrize(
    "a_major, b_major, c_major", [("k", "k", "n"), ("m", "n", "m")]
)
@pytest.mark.parametrize(
    "prefetch_dist",
    [
        None,  # Default: auto (uses num_ab_stage)
        4,     # Explicit distance
    ],
)
@pytest.mark.parametrize("tolerance", [1e-01])
def test_dense_blockscaled_gemm_prefetch_L0(
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    prefetch_dist: Optional[int],
    tolerance: float,
):
    run(
        mnkl,
        ab_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        a_major,
        b_major,
        c_major,
        mma_tiler_mn,
        cluster_shape_mn,
        tolerance,
        prefetch_dist=prefetch_dist,
    )


@pytest.mark.parametrize(
    "prefetch_dist",
    [
        None,  # Auto: uses num_ab_stage
        0,     # Disabled
        2,     # Small distance
        4,     # Medium distance
    ],
)
def test_prefetch_dist_configurations(prefetch_dist: Optional[int]):
    """
    Test different prefetch_dist configurations specifically for blockscaled GEMM.
    
    - None: Auto mode, uses num_ab_stage as prefetch distance
    - 0: Prefetch disabled
    - >0: Explicit prefetch distance
    """
    mnkl = (512, 512, 512, 1)
    ab_dtype = cutlass.Float8E5M2
    sf_dtype = cutlass.Float8E8M0FNU
    sf_vec_size = 32
    c_dtype = cutlass.Float32
    a_major = "k"
    b_major = "k"
    c_major = "n"
    mma_tiler_mn = (128, 128)
    cluster_shape_mn = (1, 1)
    tolerance = 1e-01

    # Check if this configuration can be implemented
    if not Sm100BlockScaledPersistentDenseGemmKernel.can_implement(
        ab_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        mma_tiler_mn,
        cluster_shape_mn,
        mnkl[0],
        mnkl[1],
        mnkl[2],
        mnkl[3],
        a_major,
        b_major,
        c_major,
    ):
        pytest.skip(f"Configuration not supported with prefetch_dist={prefetch_dist}")

    run(
        mnkl,
        ab_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        a_major,
        b_major,
        c_major,
        mma_tiler_mn,
        cluster_shape_mn,
        tolerance,
        prefetch_dist=prefetch_dist,
    )


@pytest.mark.parametrize(
    "ab_dtype, sf_dtype, sf_vec_size, c_dtype",
    [
        (cutlass.Float8E5M2, cutlass.Float8E4M3FN, 16, cutlass.Float32),
        (cutlass.Float4E2M1FN, cutlass.Float8E4M3FN, 32, cutlass.Float32),
        (cutlass.Float4E2M1FN, cutlass.Float8E8M0FNU, 64, cutlass.Float32),
    ],
)
def test_invalid_dtypes_and_scale_factor_vec_size(
    ab_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
):
    mnkl = (512, 512, 1024, 1)
    a_major = "k"
    b_major = "k"
    c_major = "n"
    mma_tiler_mn = (128, 128)
    cluster_shape_mn = (1, 1)
    tolerance = 1e-01
    with pytest.raises((ValueError, TypeError)):
        run(
            mnkl,
            ab_dtype,
            sf_dtype,
            sf_vec_size,
            c_dtype,
            a_major,
            b_major,
            c_major,
            mma_tiler_mn,
            cluster_shape_mn,
            tolerance,
        )


@pytest.mark.parametrize(
    "a_major, b_major, c_major",
    [
        ("m", "n", "m"),
        ("m", "k", "n"),
        ("k", "n", "m"),
    ],
)
def test_invalid_layouts(
    a_major: str,
    b_major: str,
    c_major: str,
):
    mnkl = (512, 512, 1024, 1)
    ab_dtype = cutlass.Float4E2M1FN
    sf_dtype = cutlass.Float8E4M3FN
    sf_vec_size = 16
    c_dtype = cutlass.Float32
    mma_tiler_mn = (128, 128)
    cluster_shape_mn = (1, 1)
    tolerance = 1e-01
    with pytest.raises((ValueError, TypeError)):
        run(
            mnkl,
            ab_dtype,
            sf_dtype,
            sf_vec_size,
            c_dtype,
            a_major,
            b_major,
            c_major,
            mma_tiler_mn,
            cluster_shape_mn,
            tolerance,
        )


@pytest.mark.parametrize(
    "mma_tiler_mn, cluster_shape_mn",
    [
        ((256, 96), (1, 1)),
        ((64, 160), (2, 1)),
        ((128, 128), (3, 8)),
        ((256, 128), (16, 1)),
    ],
)
def test_invalid_mma_tiler_and_cluster_shape(
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
):
    mnkl = (512, 512, 1024, 1)
    ab_dtype = cutlass.Float4E2M1FN
    sf_dtype = cutlass.Float8E4M3FN
    sf_vec_size = 16
    c_dtype = cutlass.Float32
    a_major = "k"
    b_major = "k"
    c_major = "n"
    tolerance = 1e-01
    with pytest.raises((ValueError, TypeError)):
        run(
            mnkl,
            ab_dtype,
            sf_dtype,
            sf_vec_size,
            c_dtype,
            a_major,
            b_major,
            c_major,
            mma_tiler_mn,
            cluster_shape_mn,
            tolerance,
        )


@pytest.mark.parametrize(
    "mnkl, ab_dtype, sf_dtype, sf_vec_size, c_dtype, a_major, b_major, c_major",
    [
        (
            (500, 500, 1000, 1),
            cutlass.Float8E5M2,
            cutlass.Float8E8M0FNU,
            32,
            cutlass.Float32,
            "m",
            "n",
            "n",
        ),
        (
            (500, 500, 1000, 1),
            cutlass.Float4E2M1FN,
            cutlass.Float8E4M3FN,
            16,
            cutlass.Float32,
            "k",
            "k",
            "n",
        ),
    ],
)
def test_invalid_tensor_alignment(
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
):
    mma_tiler_mn = (128, 128)
    cluster_shape_mn = (1, 1)
    tolerance = 1e-01
    with pytest.raises((ValueError, TypeError)):
        run(
            mnkl,
            ab_dtype,
            sf_dtype,
            sf_vec_size,
            c_dtype,
            a_major,
            b_major,
            c_major,
            mma_tiler_mn,
            cluster_shape_mn,
            tolerance,
        )

