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
Pytest test suite for hopper/dense_gemm.py and hopper/dense_gemm_persistent.py.

Test organization
-----------------
L0 — compile tests (skip_ref_check=True, iterations=1)
    Verify that both kernels compile for 16-bit inputs across tile and
    cluster shapes.

L1 — correctness tests (GPU execution, checked against torch.einsum)
    Verify numerical correctness of Float16 and BFloat16 inputs across
    tile shapes, cluster shapes, operand majors, output dtypes, batched
    problems and non-tile-aligned problem sizes.

Validation — host-side rejection of unsupported type combinations
    BFloat16 inputs require Float32 accumulation (WGMMA constraint).
"""

import pytest
import cutlass
from hopper.kernel.dense_gemm import dense_gemm, dense_gemm_persistent

F16 = cutlass.Float16
BF16 = cutlass.BFloat16
F32 = cutlass.Float32

KERNELS = [
    pytest.param(dense_gemm, id="dense_gemm"),
    pytest.param(dense_gemm_persistent, id="dense_gemm_persistent"),
]
AB_DTYPES = [pytest.param(F16, id="Float16"), pytest.param(BF16, id="BFloat16")]


def _run(
    kernel,
    ab_dtype,
    mnkl=(1024, 1024, 1024, 1),
    c_dtype=None,
    acc_dtype=F32,
    tile_shape_mn=(128, 128),
    cluster_shape_mn=(1, 1),
    a_major="k",
    b_major="k",
    c_major="n",
    skip_ref_check=False,
):
    kernel.run(
        mnkl=mnkl,
        a_dtype=ab_dtype,
        b_dtype=ab_dtype,
        c_dtype=ab_dtype if c_dtype is None else c_dtype,
        acc_dtype=acc_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        tile_shape_mn=tile_shape_mn,
        cluster_shape_mn=cluster_shape_mn,
        tolerance=0.1,
        warmup_iterations=0,
        iterations=1,
        skip_ref_check=skip_ref_check,
        use_cold_l2=False,
    )


# ---------------------------------------------------------------------------
# L0 — compile coverage
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize("kernel", KERNELS)
@pytest.mark.parametrize("ab_dtype", AB_DTYPES)
@pytest.mark.parametrize(
    "tile_shape_mn",
    [(128, 256), (128, 128), (128, 64), (64, 64)],
    ids=lambda t: f"tile{t[0]}x{t[1]}",
)
def test_l0_tile_shapes(kernel, ab_dtype, tile_shape_mn):
    """All valid tile shapes compile for 16-bit inputs."""
    _run(kernel, ab_dtype, tile_shape_mn=tile_shape_mn, skip_ref_check=True)


# ---------------------------------------------------------------------------
# L1 — correctness
# ---------------------------------------------------------------------------


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("kernel", KERNELS)
@pytest.mark.parametrize("ab_dtype", AB_DTYPES)
@pytest.mark.parametrize(
    "tile_shape_mn",
    [(128, 256), (128, 128), (128, 64), (64, 64)],
    ids=lambda t: f"tile{t[0]}x{t[1]}",
)
def test_l1_tile_shapes(kernel, ab_dtype, tile_shape_mn):
    """All tile shapes produce correct results."""
    _run(kernel, ab_dtype, tile_shape_mn=tile_shape_mn)


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("kernel", KERNELS)
@pytest.mark.parametrize("ab_dtype", AB_DTYPES)
@pytest.mark.parametrize(
    "cluster_shape_mn",
    [(1, 1), (2, 1), (1, 2), (2, 2)],
    ids=lambda c: f"cluster{c[0]}x{c[1]}",
)
def test_l1_cluster_shapes(kernel, ab_dtype, cluster_shape_mn):
    """All cluster shapes (including TMA multicast paths) produce correct results."""
    _run(kernel, ab_dtype, cluster_shape_mn=cluster_shape_mn)


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("kernel", KERNELS)
@pytest.mark.parametrize("ab_dtype", AB_DTYPES)
@pytest.mark.parametrize("a_major", ["k", "m"])
@pytest.mark.parametrize("b_major", ["k", "n"])
@pytest.mark.parametrize("c_major", ["n", "m"])
def test_l1_majors(kernel, ab_dtype, a_major, b_major, c_major):
    """16-bit inputs support every A/B/C major combination."""
    _run(
        kernel,
        ab_dtype,
        mnkl=(512, 512, 256, 2),
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
    )


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("kernel", KERNELS)
@pytest.mark.parametrize("ab_dtype", AB_DTYPES)
@pytest.mark.parametrize(
    "c_dtype", [F16, BF16, F32], ids=["cFloat16", "cBFloat16", "cFloat32"]
)
def test_l1_output_dtypes(kernel, ab_dtype, c_dtype):
    """Float32 accumulation supports Float16, BFloat16 and Float32 outputs."""
    _run(kernel, ab_dtype, c_dtype=c_dtype)


@pytest.mark.L0(0)
@pytest.mark.L1
@pytest.mark.parametrize("kernel", KERNELS)
@pytest.mark.parametrize("ab_dtype", AB_DTYPES)
@pytest.mark.parametrize(
    "mnkl",
    [(1000, 1032, 264, 1), (136, 72, 72, 3)],
    ids=["residue", "residue_batched"],
)
def test_l1_residue(kernel, ab_dtype, mnkl):
    """Problem sizes that are not multiples of the CTA tile are handled."""
    _run(kernel, ab_dtype, mnkl=mnkl)


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------


@pytest.mark.L0
@pytest.mark.parametrize("kernel", KERNELS)
def test_bf16_requires_fp32_accumulator(kernel):
    """BFloat16 WGMMA only accumulates in Float32; Float16 accumulation is rejected."""
    cls = (
        kernel.HopperWgmmaGemmKernel
        if hasattr(kernel, "HopperWgmmaGemmKernel")
        else kernel.HopperWgmmaGemmPersistentKernel
    )
    assert cls.is_valid_dtypes(BF16, BF16, F32, BF16, "k", "k")
    assert not cls.is_valid_dtypes(BF16, BF16, F16, BF16, "k", "k")
    assert not cls.is_valid_dtypes(BF16, F16, F32, BF16, "k", "k")
