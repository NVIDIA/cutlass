# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
Test cases for dense_gemm_persistent_prefetch.py with TMA prefetch support.

Tests various configurations of:
- prefetch_dist: None (default auto), 0 (disabled), explicit values (2, 4)
- Data types: Float16, BFloat16, TFloat32
- MMA tiler shapes and cluster shapes
- Tensor layouts
"""

from typing import Tuple, Type, Optional

import pytest

from blackwell.dense_gemm_persistent_prefetch import (
    PersistentDenseGemmKernel,
    run,
)

import cutlass
import cutlass.cute.testing as testing


@pytest.mark.parametrize(
    "mnkl",
    [
        (512, 512, 1024, 1),
        (512, 512, 64, 2),
    ],
)
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, acc_dtype",
    [
        (cutlass.Float16, cutlass.Float16, cutlass.Float32),
        (cutlass.BFloat16, cutlass.BFloat16, cutlass.Float32),
    ],
)
@pytest.mark.parametrize(
    "mma_tiler_mn",
    [
        (128, 256),
        (64, 128),
    ],
)
@pytest.mark.parametrize(
    "cluster_shape_mn",
    [
        (1, 1),
        (2, 1),
    ],
)
@pytest.mark.parametrize("a_major", ["k", "m"])
@pytest.mark.parametrize("b_major", ["k", "n"])
@pytest.mark.parametrize("c_major", ["n", "m"])
@pytest.mark.parametrize(
    "use_2cta_instrs",
    [False, True],
)
@pytest.mark.parametrize(
    "use_tma_store",
    [False, True],
)
@pytest.mark.parametrize(
    "prefetch_dist",
    [
        None,  # Default: auto (uses num_ab_stage)
        0,     # Disabled
        2,     # Explicit distance
    ],
)
@pytest.mark.parametrize("tolerance", [1e-01])
def test_dense_gemm_prefetch(
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    use_2cta_instrs: bool,
    use_tma_store: bool,
    prefetch_dist: Optional[int],
    tolerance: float,
):
    try:
        run(
            mnkl=mnkl,
            ab_dtype=ab_dtype,
            c_dtype=c_dtype,
            acc_dtype=acc_dtype,
            a_major=a_major,
            b_major=b_major,
            c_major=c_major,
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            use_2cta_instrs=use_2cta_instrs,
            use_tma_store=use_tma_store,
            tolerance=tolerance,
            prefetch_dist=prefetch_dist,
        )
    except testing.CantImplementError:
        pytest.skip(
            f"Skip unsupported testcase {ab_dtype}, {acc_dtype}, {c_dtype}, "
            f"{use_2cta_instrs}, {mma_tiler_mn}, {cluster_shape_mn}, "
            f"{use_tma_store}, {mnkl}, {a_major}, {b_major}, {c_major}, "
            f"prefetch_dist={prefetch_dist}"
        )


@pytest.mark.parametrize(
    "mnkl, use_tma_store",
    [
        ((256, 256, 1024, 1), False),
        ((256, 256, 64, 2), True),
        # non-power of two shape
        ((256, 224, 64, 2), True),
    ],
)
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, acc_dtype, tolerance",
    [
        (cutlass.Float16, cutlass.Float16, cutlass.Float32, 1e-05),
    ],
)
@pytest.mark.parametrize(
    "cluster_shape_mn, use_2cta_instrs",
    [
        ((1, 1), False),
        ((2, 1), False),
        ((2, 2), True),
        ((2, 2), False),
    ],
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
def test_dense_gemm_prefetch_L0(
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    cluster_shape_mn: Tuple[int, int],
    use_2cta_instrs: bool,
    use_tma_store: bool,
    tolerance: float,
    prefetch_dist: Optional[int],
):
    mma_tiler_mn = (64, 128)
    try:
        run(
            mnkl=mnkl,
            ab_dtype=ab_dtype,
            c_dtype=c_dtype,
            acc_dtype=acc_dtype,
            a_major=a_major,
            b_major=b_major,
            c_major=c_major,
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            use_2cta_instrs=use_2cta_instrs,
            use_tma_store=use_tma_store,
            tolerance=tolerance,
            prefetch_dist=prefetch_dist,
        )
    except testing.CantImplementError:
        pytest.skip(
            f"Skip unsupported testcase {ab_dtype}, {acc_dtype}, {c_dtype}, "
            f"{use_2cta_instrs}, {mma_tiler_mn}, {cluster_shape_mn}, "
            f"{use_tma_store}, {mnkl}, {a_major}, {b_major}, {c_major}, "
            f"prefetch_dist={prefetch_dist}"
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
    Test different prefetch_dist configurations specifically.
    
    - None: Auto mode, uses num_ab_stage as prefetch distance
    - 0: Prefetch disabled
    - >0: Explicit prefetch distance
    """
    mnkl = (512, 512, 512, 1)
    ab_dtype = cutlass.Float16
    c_dtype = cutlass.Float16
    acc_dtype = cutlass.Float32
    a_major = "k"
    b_major = "k"
    c_major = "n"
    mma_tiler_mn = (128, 128)
    cluster_shape_mn = (1, 1)
    use_2cta_instrs = False
    use_tma_store = True
    tolerance = 1e-01

    try:
        run(
            mnkl=mnkl,
            ab_dtype=ab_dtype,
            c_dtype=c_dtype,
            acc_dtype=acc_dtype,
            a_major=a_major,
            b_major=b_major,
            c_major=c_major,
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            use_2cta_instrs=use_2cta_instrs,
            use_tma_store=use_tma_store,
            tolerance=tolerance,
            prefetch_dist=prefetch_dist,
        )
    except testing.CantImplementError:
        pytest.skip(f"Skip unsupported testcase with prefetch_dist={prefetch_dist}")

