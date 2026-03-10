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
Unit tests for RMSNorm implementation on Blackwell (SM100).

Tests various configurations of:
- Data types: Float16, BFloat16, Float32
- Hidden dimensions: small to very large N
- Batch sizes: M from 1 to large values
- With and without learnable weight
- Cluster mode for large N (SM90+/SM100)
"""

import pytest
import torch

import cutlass

from blackwell.rmsnorm import (
    run,
    get_sm_version,
    supports_cluster,
)


class TestRMSNormArchitecture:
    """Test architecture detection and cluster support."""

    def test_get_sm_version(self):
        """Test SM version detection."""
        sm_version = get_sm_version()
        assert sm_version >= 70, f"Got SM{sm_version}, expected at least SM70"

    def test_supports_cluster(self):
        """Test cluster support detection."""
        sm_version = get_sm_version()
        expected = sm_version >= 90
        assert supports_cluster() == expected


class TestRMSNormCorrectness:
    """Test correctness of RMSNorm kernel."""

    @pytest.mark.parametrize("M", [1, 8, 32, 128, 256])
    @pytest.mark.parametrize("N", [256, 512, 1024, 2048, 4096, 8192])
    @pytest.mark.parametrize(
        "dtype",
        [cutlass.Float16, cutlass.BFloat16],
    )
    def test_rmsnorm_correctness(self, M, N, dtype):
        """Test RMSNorm against reference implementation."""
        run(
            M=M,
            N=N,
            dtype=dtype,
            has_weight=True,
            eps=1e-6,
            tolerance=1e-2,
            skip_ref_check=False,
            benchmark=False,
        )

    @pytest.mark.parametrize("N", [256, 1024, 4096, 8192])
    def test_rmsnorm_without_weight(self, N):
        """Test RMSNorm without weight parameter."""
        run(
            M=32,
            N=N,
            dtype=cutlass.Float16,
            has_weight=False,
            eps=1e-6,
            tolerance=1e-2,
            skip_ref_check=False,
            benchmark=False,
        )


class TestRMSNormClusterPath:
    """Test the cluster path for large N (SM90+/SM100 only)."""

    @pytest.mark.skipif(not supports_cluster(), reason="Cluster not supported on this GPU")
    @pytest.mark.parametrize("N", [32768, 65536])
    def test_cluster_path_correctness(self, N):
        """Test cluster path produces correct results."""
        run(
            M=32,
            N=N,
            dtype=cutlass.Float16,
            has_weight=True,
            eps=1e-6,
            tolerance=1e-2,
            skip_ref_check=False,
            benchmark=False,
        )

class TestRMSNormLargeN:
    """Test RMSNorm with large N values."""

    @pytest.mark.parametrize("N", [8192, 16384, 32768])
    def test_large_hidden_dim(self, N):
        """Test with large N."""
        run(
            M=32,
            N=N,
            dtype=cutlass.Float16,
            has_weight=True,
            eps=1e-6,
            tolerance=1e-2,
            skip_ref_check=False,
            benchmark=False,
        )

    @pytest.mark.parametrize("M", [1024, 4096, 16384])
    def test_large_batch_dim(self, M):
        """Test with large M (batch) dimension."""
        run(
            M=M,
            N=4096,
            dtype=cutlass.Float16,
            has_weight=True,
            eps=1e-6,
            tolerance=1e-2,
            skip_ref_check=False,
            benchmark=False,
        )



class TestRMSNormEdgeCases:
    """Test edge cases for RMSNorm."""

    def test_single_row(self):
        """Test with M=1."""
        run(
            M=1,
            N=1024,
            dtype=cutlass.Float16,
            has_weight=True,
            eps=1e-6,
            tolerance=1e-2,
            skip_ref_check=False,
            benchmark=False,
        )

    def test_many_rows(self):
        """Test with many rows."""
        run(
            M=8192,
            N=4096,
            dtype=cutlass.Float16,
            has_weight=True,
            eps=1e-6,
            tolerance=1e-2,
            skip_ref_check=False,
            benchmark=False,
        )


class TestRMSNormFloat32:
    """Test RMSNorm with Float32 data type."""

    @pytest.mark.parametrize("N", [256, 1024, 4096])
    def test_float32_correctness(self, N):
        """Test Float32 RMSNorm correctness."""
        run(
            M=32,
            N=N,
            dtype=cutlass.Float32,
            has_weight=True,
            eps=1e-6,
            tolerance=1e-4,  # Tighter tolerance for FP32
            skip_ref_check=False,
            benchmark=False,
        )