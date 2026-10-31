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
Pytest test suite for hopper/cta_norm/cta_norm.py.

Test organization
-----------------
L0 — one hidden size for each norm type and data type
    ``run_layernorm`` launches the kernel only when it checks the result, so
    these cases also check against torch.layer_norm / torch.rms_norm.

L1 — correctness tests (GPU execution, checked against torch.layer_norm /
    torch.rms_norm)
    Cover hidden sizes, explicit thread counts and problem shapes. The kernel
    loads 8 elements per thread, so N must be a multiple of 8; the default
    thread count comes from a heuristic, and the explicit counts cover one
    warp up to a full 1024-thread CTA.
"""

import pytest

import cutlass
from hopper.kernel.cta_norm.cta_norm import run_layernorm


F16 = cutlass.Float16
BF16 = cutlass.BFloat16
F32 = cutlass.Float32


def _run(M, N, norm_type, dtype=F16, threads_per_cta=None):
    run_layernorm(
        M,
        N,
        threads_per_cta,
        norm_type,
        dtype,
        skip_ref_check=False,
        benchmark=False,
    )


@pytest.mark.parametrize("norm_type", ["layer", "rms"])
@pytest.mark.parametrize("dtype", [F16, BF16, F32], ids=["f16", "bf16", "f32"])
@pytest.mark.L0
@pytest.mark.L1(0)
def test_l0_dtypes(norm_type, dtype):
    _run(512, 4096, norm_type, dtype)


@pytest.mark.parametrize("norm_type", ["layer", "rms"])
@pytest.mark.parametrize("dtype", [F16, BF16, F32], ids=["f16", "bf16", "f32"])
@pytest.mark.parametrize("N", [256, 1024, 4096, 8192])
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_dtypes_and_hidden_sizes(norm_type, dtype, N):
    _run(512, N, norm_type, dtype)


@pytest.mark.parametrize("norm_type", ["layer", "rms"])
@pytest.mark.parametrize("threads_per_cta", [32, 128, 512, 1024])
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_threads_per_cta(norm_type, threads_per_cta):
    _run(256, 4096, norm_type, threads_per_cta=threads_per_cta)


@pytest.mark.parametrize("norm_type", ["layer", "rms"])
@pytest.mark.parametrize(
    "M, N",
    [
        pytest.param(1, 4096, id="single-row"),
        pytest.param(3, 1000, id="N-not-multiple-of-a-warp-tile"),
        pytest.param(8192, 2048, id="many-rows"),
        pytest.param(64, 16384, id="large-N"),
    ],
)
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_shapes(norm_type, M, N):
    _run(M, N, norm_type)
