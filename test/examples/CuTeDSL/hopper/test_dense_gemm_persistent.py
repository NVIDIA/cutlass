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

"""
Pytest test suite for hopper/dense_gemm_persistent.py.

Test organization
-----------------
L0 — compile and launch once (skip_ref_check=True, iterations=1)
    Cover tile shapes, cluster shapes, data types and major modes.

L1 — correctness tests (GPU execution, checked against torch.einsum)
    Validate the same configurations, plus batched and unaligned problem sizes.
"""

import pytest

import cutlass
from hopper.kernel.dense_gemm.dense_gemm_persistent import run


F16 = cutlass.Float16
F32 = cutlass.Float32
F8E4 = cutlass.Float8E4M3FN
F8E5 = cutlass.Float8E5M2
I8 = cutlass.Int8
U8 = cutlass.Uint8
I32 = cutlass.Int32


TILE_SHAPES = [(64, 64), (128, 64), (128, 128), (128, 256)]
CLUSTER_SHAPES = [(1, 1), (2, 1), (1, 2), (2, 2)]

# (a/b dtype, c dtype, acc dtype)
DTYPES = [
    pytest.param(F16, F16, F32, id="f16-f16-f32acc"),
    pytest.param(F16, F32, F32, id="f16-f32-f32acc"),
    pytest.param(F16, F16, F16, id="f16-f16-f16acc"),
    pytest.param(F8E4, F16, F32, id="e4m3-f16-f32acc"),
    pytest.param(F8E5, F16, F32, id="e5m2-f16-f32acc"),
    pytest.param(I8, I32, I32, id="s8-s32-s32acc"),
    pytest.param(U8, I32, I32, id="u8-s32-s32acc"),
]

# (a_major, b_major, c_major); 8-bit inputs support only k-major A and B
MAJORS = [
    pytest.param("k", "k", "n", id="kkn"),
    pytest.param("k", "k", "m", id="kkm"),
    pytest.param("m", "n", "n", id="mnn"),
    pytest.param("m", "k", "m", id="mkm"),
    pytest.param("k", "n", "n", id="knn"),
]


def _run(
    mnkl=(1024, 1024, 1024, 1),
    ab_dtype=F16,
    c_dtype=F16,
    acc_dtype=F32,
    a_major="k",
    b_major="k",
    c_major="n",
    tile_shape_mn=(128, 128),
    cluster_shape_mn=(1, 1),
    swizzle_size=1,
    raster_along_m=True,
    tolerance=0.1,
    skip_ref_check=False,
):
    run(
        mnkl=mnkl,
        a_dtype=ab_dtype,
        b_dtype=ab_dtype,
        c_dtype=c_dtype,
        acc_dtype=acc_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        tile_shape_mn=tile_shape_mn,
        cluster_shape_mn=cluster_shape_mn,
        swizzle_size=swizzle_size,
        raster_along_m=raster_along_m,
        tolerance=tolerance,
        warmup_iterations=0,
        iterations=1,
        skip_ref_check=skip_ref_check,
        use_cold_l2=False,
    )


@pytest.mark.parametrize("tile_shape_mn", TILE_SHAPES, ids=str)
@pytest.mark.parametrize("cluster_shape_mn", CLUSTER_SHAPES, ids=str)
@pytest.mark.L0
@pytest.mark.L1(0)
def test_l0_tile_and_cluster_shapes(tile_shape_mn, cluster_shape_mn):
    _run(
        tile_shape_mn=tile_shape_mn,
        cluster_shape_mn=cluster_shape_mn,
        skip_ref_check=True,
    )


@pytest.mark.parametrize("ab_dtype, c_dtype, acc_dtype", DTYPES)
@pytest.mark.L0
@pytest.mark.L1(0)
def test_l0_dtypes(ab_dtype, c_dtype, acc_dtype):
    _run(ab_dtype=ab_dtype, c_dtype=c_dtype, acc_dtype=acc_dtype, skip_ref_check=True)


@pytest.mark.parametrize("a_major, b_major, c_major", MAJORS)
@pytest.mark.L0
@pytest.mark.L1(0)
def test_l0_majors(a_major, b_major, c_major):
    _run(a_major=a_major, b_major=b_major, c_major=c_major, skip_ref_check=True)


@pytest.mark.parametrize("tile_shape_mn", TILE_SHAPES, ids=str)
@pytest.mark.parametrize("cluster_shape_mn", CLUSTER_SHAPES, ids=str)
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_tile_and_cluster_shapes(tile_shape_mn, cluster_shape_mn):
    _run(tile_shape_mn=tile_shape_mn, cluster_shape_mn=cluster_shape_mn)


@pytest.mark.parametrize("ab_dtype, c_dtype, acc_dtype", DTYPES)
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_dtypes(ab_dtype, c_dtype, acc_dtype):
    _run(ab_dtype=ab_dtype, c_dtype=c_dtype, acc_dtype=acc_dtype)


@pytest.mark.parametrize("a_major, b_major, c_major", MAJORS)
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_majors(a_major, b_major, c_major):
    _run(a_major=a_major, b_major=b_major, c_major=c_major)


@pytest.mark.parametrize(
    "mnkl",
    [
        pytest.param((1024, 1536, 512, 3), id="batched"),
        pytest.param((1000, 1000, 1000, 1), id="partial-tiles"),
        pytest.param((128, 128, 64, 1), id="single-tile"),
    ],
)
@pytest.mark.parametrize("cluster_shape_mn", [(1, 1), (2, 2)], ids=str)
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_problem_sizes(mnkl, cluster_shape_mn):
    _run(mnkl=mnkl, cluster_shape_mn=cluster_shape_mn)


@pytest.mark.parametrize("swizzle_size", [1, 2, 4])
@pytest.mark.parametrize("raster_along_m", [True, False], ids=["along_m", "along_n"])
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_tile_scheduler(swizzle_size, raster_along_m):
    _run(
        mnkl=(2048, 1536, 512, 2),
        cluster_shape_mn=(2, 1),
        swizzle_size=swizzle_size,
        raster_along_m=raster_along_m,
    )
