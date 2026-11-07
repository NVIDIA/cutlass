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
Unit tests for the RMSNorm example on Hopper (SM90).

The kernel lives under ``cute/blackwell`` but uses no tcgen05 or TMEM: the
large-N path splits a row across a thread block cluster and reduces through
``mapa`` / ``st.async`` into distributed shared memory, which SM90 supports.

Tests cover:
- Data types: Float16, BFloat16, Float32
- Hidden dimensions from 256 to 512K, which selects cluster sizes 1, 2, 4,
  8 and 16 (16 is a non-portable cluster size on SM90)
- With and without learnable weight
"""

import pytest

import cutlass

from blackwell.kernel.rmsnorm.rmsnorm import (
    RMSNormConfig,
    get_sm_version,
    run,
    supports_cluster,
)


F16 = cutlass.Float16
BF16 = cutlass.BFloat16
F32 = cutlass.Float32


def _run(M, N, dtype=F16, has_weight=True, tolerance=1e-2):
    run(
        M=M,
        N=N,
        dtype=dtype,
        has_weight=has_weight,
        eps=1e-6,
        tolerance=tolerance,
        skip_ref_check=False,
        benchmark=False,
    )


def test_sm_version():
    assert get_sm_version() == 90
    assert supports_cluster()


@pytest.mark.parametrize("M", [1, 8, 32, 128, 256])
@pytest.mark.parametrize("N", [256, 512, 1024, 2048, 4096, 8192])
@pytest.mark.parametrize("dtype", [F16, BF16], ids=["f16", "bf16"])
def test_rmsnorm_correctness(M, N, dtype):
    _run(M, N, dtype)


@pytest.mark.parametrize("N", [256, 1024, 4096, 8192])
def test_rmsnorm_without_weight(N):
    _run(32, N, has_weight=False)


@pytest.mark.parametrize("N", [256, 1024, 4096])
def test_float32_correctness(N):
    _run(32, N, F32, tolerance=1e-4)


@pytest.mark.parametrize("M", [1024, 4096, 16384])
def test_large_batch_dim(M):
    _run(M, 4096)


# (dtype, N, expected cluster size)
CLUSTER_CASES = [
    pytest.param(F16, 32 * 1024, 2, id="f16-32k-cluster2"),
    pytest.param(BF16, 64 * 1024, 4, id="bf16-64k-cluster4"),
    pytest.param(F16, 128 * 1024, 8, id="f16-128k-cluster8"),
    pytest.param(F16, 256 * 1024, 16, id="f16-256k-cluster16"),
    pytest.param(BF16, 256 * 1024, 16, id="bf16-256k-cluster16"),
    pytest.param(F32, 64 * 1024, 2, id="f32-64k-cluster2"),
    pytest.param(F32, 256 * 1024, 8, id="f32-256k-cluster8"),
    pytest.param(F32, 512 * 1024, 16, id="f32-512k-cluster16"),
]


@pytest.mark.parametrize("dtype, N, cluster_n", CLUSTER_CASES)
def test_cluster_path(dtype, N, cluster_n):
    assert RMSNormConfig(dtype, N, True).cluster_n == cluster_n
    _run(32, N, dtype, tolerance=1e-4 if dtype is F32 else 1e-2)
