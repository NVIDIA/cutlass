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

"""Unit tests for TensorWrapper with packed sub-byte types (float4_e2m1fn_x2)."""

import pytest
import torch

import cutlass
import cutlass.operators as ops
from cutlass.operators.utils.tensor import TensorWrapper


@pytest.fixture(autouse=True)
def _enable_tvm_ffi():
    """TensorWrapper's FP4 packing logic lives in the TVM-FFI path."""
    prev = ops.GlobalOptions().use_tvm_ffi
    ops.GlobalOptions().use_tvm_ffi = True
    yield
    ops.GlobalOptions().use_tvm_ffi = prev


class TestTensorWrapperFP4Packing:
    """Tests that TensorWrapper correctly reports logical shape/stride for
    float4_e2m1fn_x2 tensors, which pack 2 FP4 values per byte.
    """

    def _make_fp4_tensor(self, phys_shape: tuple[int, ...]) -> torch.Tensor:
        """Create a float4_e2m1fn_x2 tensor with given physical shape."""
        return torch.randint(
            0, 256, phys_shape, dtype=torch.uint8, device="cpu"
        ).view(torch.float4_e2m1fn_x2)

    def test_2d_row_major(self):
        """2D row-major (M, K_phys): logical K should be 2x physical."""
        M, K_phys = 64, 128
        t = self._make_fp4_tensor((M, K_phys))
        assert t.stride() == (K_phys, 1)

        wrapper = TensorWrapper(t, alignment_bytes=16)
        assert wrapper.shape == (M, K_phys * 2)
        assert wrapper.stride == (K_phys * 2, 1)

    def test_2d_col_major(self):
        """2D col-major (K_phys, N): logical K should be 2x physical."""
        K_phys, N = 128, 64
        # Create (N, K_phys) contiguous then transpose to get col-major:
        # shape (K_phys, N) with stride (1, K_phys)
        t = torch.randint(
            0, 256, (N, K_phys), dtype=torch.uint8, device="cpu"
        ).view(torch.float4_e2m1fn_x2).t()
        assert t.shape == (K_phys, N)
        assert t.stride() == (1, K_phys)

        wrapper = TensorWrapper(t, alignment_bytes=16)
        assert wrapper.shape == (K_phys * 2, N)
        assert wrapper.stride == (1, K_phys * 2)

    def test_3d_row_major(self):
        """3D row-major (L, M, K_phys): logical K should be 2x physical."""
        L, M, K_phys = 2, 64, 128
        t = self._make_fp4_tensor((L, M, K_phys))
        assert t.stride() == (M * K_phys, K_phys, 1)

        wrapper = TensorWrapper(t, alignment_bytes=16)
        assert wrapper.shape == (L, M, K_phys * 2)
        assert wrapper.stride == (M * K_phys * 2, K_phys * 2, 1)

    def test_3d_col_major_innermost(self):
        """3D with stride-1 on dim 1 (e.g. B tensor stored as (L, K_phys, N)
        but physically contiguous on K): logical K should be 2x physical."""
        L, K_phys, N = 2, 128, 64
        # Create (L, N, K_phys) contiguous then transpose dims 1,2
        base = torch.randint(
            0, 256, (L, N, K_phys), dtype=torch.uint8, device="cpu"
        ).view(torch.float4_e2m1fn_x2)
        t = base.transpose(1, 2)
        # t.shape = (L, K_phys, N), t.stride = (N*K_phys, 1, K_phys)
        assert t.shape == (L, K_phys, N)
        assert t.stride() == (N * K_phys, 1, K_phys)

        wrapper = TensorWrapper(t, alignment_bytes=16)
        assert wrapper.shape == (L, K_phys * 2, N)
        assert wrapper.stride == (N * K_phys * 2, 1, K_phys * 2)

    def test_batch_1(self):
        """3D with L=1 should still produce correct logical shape."""
        L, M, K_phys = 1, 32, 256
        t = self._make_fp4_tensor((L, M, K_phys))

        wrapper = TensorWrapper(t, alignment_bytes=16)
        assert wrapper.shape == (L, M, K_phys * 2)
        assert wrapper.stride == (M * K_phys * 2, K_phys * 2, 1)

    def test_dtype_is_logical(self):
        """TensorWrapper.dtype should be the logical unpacked type."""
        t = self._make_fp4_tensor((32, 64))
        wrapper = TensorWrapper(t, alignment_bytes=16)
        assert wrapper.dtype == cutlass.Float4E2M1FN


class TestTensorWrapperNonPackedTypes:
    """Sanity checks: non-packed types should pass through shape/stride unchanged."""

    @pytest.mark.parametrize("dtype", [torch.float16, torch.float32, torch.bfloat16])
    def test_standard_dtypes_2d(self, dtype):
        M, K = 64, 128
        t = torch.randn(M, K, dtype=dtype)
        wrapper = TensorWrapper(t, alignment_bytes=16)
        assert wrapper.shape == (M, K)
        assert wrapper.stride == (K, 1)

    def test_float8_e4m3fn_3d(self):
        L, M, K = 2, 64, 128
        t = torch.randint(0, 127, (L, M, K), dtype=torch.uint8).view(
            torch.float8_e4m3fn
        )
        wrapper = TensorWrapper(t, alignment_bytes=16)
        assert wrapper.shape == (L, M, K)
        assert wrapper.stride == (M * K, K, 1)
