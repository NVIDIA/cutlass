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

from typing import Callable, Tuple

import pytest

import cutlass
from hopper.kernel.dense_gemm.dense_gemm_fp8_gelu_persistent import (
    run as run_exact_gelu,
)
from hopper.kernel.dense_gemm.dense_gemm_fp8_gelu_persistent_approx import (
    run as run_approx_gelu,
)


F8E4 = cutlass.Float8E4M3FN
BF16 = cutlass.BFloat16
F32 = cutlass.Float32


CUSTOMER_CASES = [
    pytest.param(
        run_exact_gelu,
        (12800, 4096, 1024, 1),
        (1, 2),
        id="exact-up-projection",
    ),
    pytest.param(
        run_approx_gelu,
        (12800, 4096, 1024, 1),
        (2, 1),
        id="approx-up-projection",
    ),
    pytest.param(
        run_exact_gelu,
        (12800, 1024, 4096, 1),
        (2, 2),
        id="exact-down-projection",
    ),
    pytest.param(
        run_approx_gelu,
        (12800, 1024, 4096, 1),
        (2, 2),
        id="approx-down-projection",
    ),
]


def _run_customer_case(
    run_gemm: Callable[..., float],
    mnkl: Tuple[int, int, int, int],
    cluster_shape_mn: Tuple[int, int],
    skip_ref_check: bool,
):
    run_gemm(
        mnkl=mnkl,
        a_dtype=F8E4,
        b_dtype=F8E4,
        c_dtype=BF16,
        acc_dtype=F32,
        a_major="k",
        b_major="k",
        c_major="n",
        tile_shape_mn=(128, 256),
        cluster_shape_mn=cluster_shape_mn,
        swizzle_size=1,
        raster_along_m=False,
        scale_a_val=0.75,
        scale_b_val=1.25,
        tolerance=2.0e-3,
        rtol=1.6e-2,
        warmup_iterations=0,
        iterations=1,
        skip_ref_check=skip_ref_check,
        use_cold_l2=False,
    )


@pytest.mark.parametrize("run_gemm, mnkl, cluster_shape_mn", CUSTOMER_CASES)
@pytest.mark.L0
@pytest.mark.L1(0)
def test_l0_customer_problem_sizes(run_gemm, mnkl, cluster_shape_mn):
    """Compile and execute both epilogues for the customer problem sizes."""
    _run_customer_case(run_gemm, mnkl, cluster_shape_mn, skip_ref_check=True)


@pytest.mark.parametrize("run_gemm, mnkl, cluster_shape_mn", CUSTOMER_CASES)
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_customer_problem_sizes(run_gemm, mnkl, cluster_shape_mn):
    """Validate both epilogues at full customer problem sizes."""
    _run_customer_case(run_gemm, mnkl, cluster_shape_mn, skip_ref_check=False)
