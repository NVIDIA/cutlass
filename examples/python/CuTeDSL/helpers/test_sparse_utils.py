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

import sparse_utils as su
import cutlass
import torch
import pytest


# Valid 4:2 sparsity metadata values and their corresponding mask patterns
META_TO_MASK = {
    0x4: [1, 1, 0, 0],
    0x8: [1, 0, 1, 0],
    0x9: [0, 1, 1, 0],
    0xC: [1, 0, 0, 1],
    0xD: [0, 1, 0, 1],
    0xE: [0, 0, 1, 1],
}
VALID_META_VALUES = set(META_TO_MASK.keys())

# Valid 1:2 sparsity metadata values
VALID_1_2_META_VALUES = {0x4, 0xE}


def pack_meta_value(meta_val: int) -> int:
    """Pack a single 4-bit meta value into both nibbles of a uint8.

    :param meta_val: 4-bit metadata value to pack
    :type meta_val: int

    :return: Packed uint8 value with meta_val in both nibbles
    :rtype: int
    """
    packed = 0
    for k in range(2):
        packed |= meta_val << (k * 4)
    return packed


def verify_sparsity_pattern(
    tensor: torch.Tensor, M: int, K: int, L: int, exact_zeros: bool = True
):
    """Verify 4:2 sparsity pattern in tensor.

    :param tensor: Sparse tensor with shape (M, K, L)
    :type tensor: torch.Tensor
    :param M: Number of rows in the tensor
    :type M: int
    :param K: Number of columns in the tensor
    :type K: int
    :param L: Batch size
    :type L: int
    :param exact_zeros: If True, expect exactly 2 zeros per chunk.
                        If False, expect at least 2 zeros (for random tensors)
    :type exact_zeros: bool
    """
    for l in range(L):
        for m in range(M):
            for k_start in range(0, K, 4):
                chunk = tensor[m, k_start : k_start + 4, l]
                num_zeros = (chunk == 0).sum().item()
                if exact_zeros:
                    assert num_zeros == 2, (
                        f"Expected 2 zeros at m={m}, k={k_start}, l={l}, got {num_zeros}"
                    )
                else:
                    assert num_zeros >= 2, (
                        f"Expected at least 2 zeros at m={m}, k={k_start}, l={l}, got {num_zeros}"
                    )


def verify_1_2_meta_nibbles(meta: torch.Tensor):
    """Verify every nibble in a TF32 1:2 metadata tensor is 0x4 or 0xE."""
    flat = meta.reshape(-1)
    for packed_val in flat.tolist():
        for shift in (0, 4):
            nibble = (int(packed_val) >> shift) & 0xF
            assert nibble in VALID_1_2_META_VALUES, (
                f"Invalid 1:2 meta nibble {hex(nibble)} in packed byte "
                f"{hex(int(packed_val))}"
            )


def expected_1_2_compressed(a: torch.Tensor) -> torch.Tensor:
    """Reference compressed values for a 1:2 sparse tensor (keep the non-zero)."""
    M, K, L = a.shape
    out = torch.empty(M, K // 2, L, dtype=a.dtype, device=a.device)
    for p in range(K // 2):
        v0 = a[:, 2 * p, :]
        v1 = a[:, 2 * p + 1, :]
        out[:, p, :] = torch.where(v1 != 0, v1, v0)
    return out


@pytest.mark.L0
def test_meta_data_generation():
    """Test that metadata is generated with correct shape and valid values.

    Verifies that the generated metadata tensor has the expected shape (M, K // 8, L)
    and contains only valid 4:2 sparsity metadata values.
    """
    M, K, L = 128, 64, 2
    sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)

    # Verify shape and dtype: expected (M, K // 8, L)
    assert sparse_utils.meta_data.shape == (M, K // 8, L)
    assert sparse_utils.meta_data.dtype == torch.uint8

    # Verify all unpacked nibbles are valid meta values
    for l in range(L):
        for m in range(M):
            for j in range(K // 8):
                packed_val = int(sparse_utils.meta_data[m, j, l])
                for k in range(2):
                    meta_val = (packed_val >> (k * 4)) & 0xF
                    assert meta_val in VALID_META_VALUES, (
                        f"Invalid meta value {hex(meta_val)} at m={m}, j={j}, l={l}, k={k}"
                    )

    print("test_meta_data_generation passed")


@pytest.mark.L0
def test_sparse_cpu():
    """Test sparse tensor generation on CPU.

    Verifies that a sparse tensor can be generated on CPU and maintains
    the 4:2 sparsity pattern.
    """
    M, K, L = 128, 64, 2
    sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)

    a_sparse = sparse_utils.generate_4_2_sparse_tensor(run_on_cpu=True)

    assert a_sparse.shape == (M, K, L)
    assert a_sparse.device.type == "cpu"

    # Use exact_zeros=False because random_(-5, 5) can generate 0 values
    verify_sparsity_pattern(a_sparse, M, K, L, exact_zeros=False)

    print("test_sparse_cpu passed")


@pytest.mark.L0
def test_sparse_with_tensor():
    """Test applying sparsity to an existing tensor of ones, then compress.

    Verifies that sparsity can be applied to a pre-existing tensor and that
    the resulting sparse tensor can be compressed with valid metadata.

    Note: M and K must be multiples of 128 for FP16 metadata reordering.
    """
    # Test parameters
    M, K, L = 256, 256, 2
    sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)

    a = torch.ones(M, K, L, dtype=torch.float16)
    a_sparse = sparse_utils.generate_sparse_4_2_tensor_with_tensor(a, run_on_cpu=True)

    assert a_sparse.shape == (M, K, L)

    # With all-ones input, should have exactly 2 zeros per chunk
    verify_sparsity_pattern(a_sparse, M, K, L, exact_zeros=True)

    # Test compression
    a_compressed = torch.empty(M, K // 2, L, dtype=torch.float16)
    meta = torch.zeros(M, K // 8, L, dtype=torch.uint8)
    sparse_utils.compress(a_sparse, a_compressed, meta, run_on_cpu=True)

    # Verify compressed shape and values (all 1s from ones tensor)
    assert a_compressed.shape == (M, K // 2, L)
    assert (a_compressed == 1).all(), "All compressed values should be 1"

    # Verify metadata contains valid values
    for l in range(L):
        for m in range(M):
            for j in range(K // 8):
                packed_val = int(meta[m, j, l])
                for k in range(2):
                    meta_val = (packed_val >> (k * 4)) & 0xF
                    assert meta_val in VALID_META_VALUES

    print("test_sparse_with_tensor passed")


@pytest.mark.L0
def test_sparse_with_custom_metadata():
    """Test sparse tensor generation with custom provided metadata.

    Verifies that custom metadata can be provided to control the exact
    sparsity pattern applied to the tensor.

    Note: Using smaller dimensions is acceptable for sparsity-only tests
    (no compression/FP16 reorder required).
    """
    # Test parameters
    M, K, L = 128, 128, 2
    sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)

    # Create custom metadata: all 0x4 (pattern [1,1,0,0]) with shape (M, K // 8, L)
    # 0x44 = 0x4 in low nibble and 0x4 in high nibble
    custom_meta = torch.full((M, K // 8, L), 0x44, dtype=torch.uint8)
    a = torch.ones(M, K, L, dtype=torch.float16)

    a_sparse = sparse_utils.generate_sparse_4_2_tensor_with_tensor(
        a, run_on_cpu=True, meta_data=custom_meta
    )

    # Verify all chunks match expected pattern [1,1,0,0]
    expected = torch.tensor([1, 1, 0, 0], dtype=torch.float16)
    for l in range(L):
        for m in range(M):
            for k_start in range(0, K, 4):
                chunk = a_sparse[m, k_start : k_start + 4, l]
                assert torch.allclose(chunk, expected), (
                    f"Expected [1,1,0,0] at m={m}, k={k_start}, l={l}, got {chunk.tolist()}"
                )

    print("test_sparse_with_custom_metadata passed")


@pytest.mark.L0
def test_different_meta_patterns():
    """Test all 6 valid metadata patterns.

    Verifies that each of the 6 valid 4:2 sparsity metadata patterns
    produces the expected sparsity pattern in the output tensor.
    """
    M, K, L = 128, 128, 2

    for meta_val, expected_pattern in META_TO_MASK.items():
        sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)

        packed_val = pack_meta_value(meta_val)
        custom_meta = torch.full((M, K // 8, L), packed_val, dtype=torch.uint8)
        a = torch.ones(M, K, L, dtype=torch.float16)

        a_sparse = sparse_utils.generate_sparse_4_2_tensor_with_tensor(
            a, run_on_cpu=True, meta_data=custom_meta
        )

        expected = torch.tensor(expected_pattern, dtype=torch.float16)
        for l in range(L):
            for m in range(M):
                for k_start in range(0, K, 4):
                    chunk = a_sparse[m, k_start : k_start + 4, l]
                    assert torch.allclose(chunk, expected), (
                        f"Meta {hex(meta_val)}: Expected {expected_pattern} at m={m}, k={k_start}, l={l}, got {chunk.tolist()}"
                    )

        print(f"  Pattern {hex(meta_val)} -> {expected_pattern} verified")

    print("test_different_meta_patterns passed")


@pytest.mark.L0
def test_large_tensor():
    """Test with larger tensor dimensions.

    Verifies that sparse tensor generation works correctly with larger
    tensor sizes using sample-based validation for efficiency.
    """
    M, K, L = 512, 256, 2
    sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)

    a_sparse = sparse_utils.generate_4_2_sparse_tensor(run_on_cpu=True)

    assert a_sparse.shape == (M, K, L)

    # Sample check (full check would be slow)
    sample_rows = [0, M // 4, M // 2, 3 * M // 4, M - 1]
    for l in range(L):
        for m in sample_rows:
            for k_start in range(0, K, 4):
                chunk = a_sparse[m, k_start : k_start + 4, l]
                num_zeros = (chunk == 0).sum().item()
                assert num_zeros >= 2, (
                    f"Expected at least 2 zeros at m={m}, k={k_start}, l={l}, got {num_zeros}"
                )

    print("test_large_tensor passed")


# ============================================================================
# CUDA Tests
# ============================================================================


@pytest.mark.L0
def test_sparse_cuda():
    """Test sparse tensor generation on CUDA.

    Verifies that a sparse tensor can be generated on CUDA device and maintains
    the 4:2 sparsity pattern.
    """
    M, K, L = 128, 64, 2
    sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)

    a_sparse = sparse_utils.generate_4_2_sparse_tensor(run_on_cpu=False)

    assert a_sparse.shape == (M, K, L)
    assert a_sparse.device.type == "cuda"

    # Move to CPU for verification
    # Use exact_zeros=False because random_(-5, 5) can generate 0 values
    a_sparse_cpu = a_sparse.cpu()
    verify_sparsity_pattern(a_sparse_cpu, M, K, L, exact_zeros=False)

    print("test_sparse_cuda passed")


@pytest.mark.L0
def test_sparse_cuda_with_tensor():
    """Test applying sparsity to an existing CUDA tensor of ones, then compress.

    Verifies that sparsity can be applied to a CUDA tensor and that the resulting
    sparse tensor can be compressed with valid metadata on GPU.

    Note: M and K must be multiples of 128 for FP16 metadata reordering.
    """
    # Test parameters
    M, K, L = 256, 256, 2
    sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)

    a = torch.ones(M, K, L, dtype=torch.float16).cuda()
    a_sparse = sparse_utils.generate_sparse_4_2_tensor_with_tensor(a, run_on_cpu=False)

    assert a_sparse.shape == (M, K, L)
    assert a_sparse.device.type == "cuda"

    # Move to CPU for verification
    a_sparse_cpu = a_sparse.cpu()
    verify_sparsity_pattern(a_sparse_cpu, M, K, L, exact_zeros=True)

    # Test CUDA compression
    a_compressed = torch.empty(M, K // 2, L, dtype=torch.float16, device="cuda")
    meta = torch.zeros(M, K // 8, L, dtype=torch.uint8, device="cuda")
    sparse_utils.compress(a_sparse, a_compressed, meta, run_on_cpu=False)

    # Verify compressed shape and values
    assert a_compressed.shape == (M, K // 2, L)
    a_compressed_cpu = a_compressed.cpu()
    assert (a_compressed_cpu == 1).all(), "All compressed values should be 1"

    # Verify metadata contains valid values
    meta_cpu = meta.cpu()
    for l in range(L):
        for m in range(M):
            for j in range(K // 8):
                packed_val = int(meta_cpu[m, j, l])
                for k in range(2):
                    meta_val = (packed_val >> (k * 4)) & 0xF
                    assert meta_val in VALID_META_VALUES

    print("test_sparse_cuda_with_tensor passed")


@pytest.mark.L0
def test_sparse_cuda_with_custom_metadata():
    """Test CUDA sparse tensor generation with custom provided metadata.

    Verifies that custom metadata can be provided to control the sparsity
    pattern on CUDA tensors.

    Note: Using smaller dimensions is acceptable for sparsity-only tests
    (no compression/FP16 reorder required).
    """
    # Test parameters
    M, K, L = 128, 128, 2
    sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)

    # Create custom metadata: all 0x4 (pattern [1,1,0,0]) with shape (M, K // 8, L)
    # 0x44 = 0x4 in low nibble and 0x4 in high nibble
    custom_meta = torch.full((M, K // 8, L), 0x44, dtype=torch.uint8)
    a = torch.ones(M, K, L, dtype=torch.float16).cuda()

    a_sparse = sparse_utils.generate_sparse_4_2_tensor_with_tensor(
        a, run_on_cpu=False, meta_data=custom_meta
    )

    # Verify all chunks match expected pattern [1,1,0,0]
    a_sparse_cpu = a_sparse.cpu()
    expected = torch.tensor([1, 1, 0, 0], dtype=torch.float16)
    for l in range(L):
        for m in range(M):
            for k_start in range(0, K, 4):
                chunk = a_sparse_cpu[m, k_start : k_start + 4, l]
                assert torch.allclose(chunk, expected), (
                    f"Expected [1,1,0,0] at m={m}, k={k_start}, l={l}, got {chunk.tolist()}"
                )

    print("test_sparse_cuda_with_custom_metadata passed")


@pytest.mark.L0
def test_cuda_different_meta_patterns():
    """Test all 6 valid metadata patterns on CUDA.

    Verifies that each of the 6 valid 4:2 sparsity metadata patterns
    produces the expected sparsity pattern on CUDA tensors.
    """
    M, K, L = 128, 128, 2

    for meta_val, expected_pattern in META_TO_MASK.items():
        sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)

        packed_val = pack_meta_value(meta_val)
        custom_meta = torch.full((M, K // 8, L), packed_val, dtype=torch.uint8)
        a = torch.ones(M, K, L, dtype=torch.float16).cuda()

        a_sparse = sparse_utils.generate_sparse_4_2_tensor_with_tensor(
            a, run_on_cpu=False, meta_data=custom_meta
        )

        a_sparse_cpu = a_sparse.cpu()
        expected = torch.tensor(expected_pattern, dtype=torch.float16)
        for l in range(L):
            for m in range(M):
                for k_start in range(0, K, 4):
                    chunk = a_sparse_cpu[m, k_start : k_start + 4, l]
                    assert torch.allclose(chunk, expected), (
                        f"Meta {hex(meta_val)}: Expected {expected_pattern} at m={m}, k={k_start}, l={l}, got {chunk.tolist()}"
                    )

        print(f"  CUDA Pattern {hex(meta_val)} -> {expected_pattern} verified")

    print("test_cuda_different_meta_patterns passed")


@pytest.mark.L0
def test_cuda_large_tensor():
    """Test CUDA with larger tensor dimensions.

    Verifies that sparse tensor generation works correctly with larger
    tensor sizes on CUDA using sample-based validation for efficiency.
    """
    M, K, L = 512, 256, 2
    sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)

    a_sparse = sparse_utils.generate_4_2_sparse_tensor(run_on_cpu=False)

    assert a_sparse.shape == (M, K, L)
    assert a_sparse.device.type == "cuda"

    # Sample check on CPU
    # Note: may have more than 2 zeros if original random tensor contained zeros
    a_sparse_cpu = a_sparse.cpu()
    sample_rows = [0, M // 4, M // 2, 3 * M // 4, M - 1]
    for l in range(L):
        for m in sample_rows:
            for k_start in range(0, K, 4):
                chunk = a_sparse_cpu[m, k_start : k_start + 4, l]
                num_zeros = (chunk == 0).sum().item()
                assert num_zeros >= 2, (
                    f"Expected at least 2 zeros at m={m}, k={k_start}, l={l}, got {num_zeros}"
                )

    print("test_cuda_large_tensor passed")


@pytest.mark.L0
def test_cpu_cuda_consistency():
    """Test that CPU and CUDA implementations produce consistent results.

    Verifies that CPU and CUDA implementations produce identical results for
    both sparsity pattern application and tensor compression with metadata.

    Note: M and K must be multiples of 128 for FP16 metadata reordering.
    """
    # Test parameters
    M, K, L = 256, 256, 2

    # Use same metadata for both
    sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)
    meta_input = sparse_utils.meta_data

    # Create identical input tensors
    a_cpu = torch.ones(M, K, L, dtype=torch.float16)
    a_cuda = torch.ones(M, K, L, dtype=torch.float16).cuda()

    # Apply sparsity with same metadata
    result_cpu = sparse_utils.generate_sparse_4_2_tensor_with_tensor(
        a_cpu, run_on_cpu=True, meta_data=meta_input
    )
    result_cuda = sparse_utils.generate_sparse_4_2_tensor_with_tensor(
        a_cuda, run_on_cpu=False, meta_data=meta_input
    )

    # Compare sparsity results
    torch.testing.assert_close(result_cpu, result_cuda.cpu())

    # Test compression consistency
    a_compressed_cpu = torch.empty(M, K // 2, L, dtype=torch.float16)
    meta_cpu = torch.zeros(M, K // 8, L, dtype=torch.uint8)
    sparse_utils.compress(result_cpu, a_compressed_cpu, meta_cpu, run_on_cpu=True)

    a_compressed_cuda = torch.empty(M, K // 2, L, dtype=torch.float16, device="cuda")
    meta_cuda = torch.zeros(M, K // 8, L, dtype=torch.uint8, device="cuda")
    sparse_utils.compress(result_cuda, a_compressed_cuda, meta_cuda, run_on_cpu=False)

    # Compare compression results
    torch.testing.assert_close(a_compressed_cpu, a_compressed_cuda.cpu())
    torch.testing.assert_close(meta_cpu, meta_cuda.cpu())

    print("test_cpu_cuda_consistency passed")


@pytest.mark.L0
def test_tf32_1_2_cuda_compress():
    """GPU 1:2 compress creates the expected compressed tensor and metadata."""
    M, K, L = 256, 128, 2
    sparse_utils = su.SparseUtils(M, K, L, cutlass.TFloat32)
    a_cpu = torch.empty(M, K, L, dtype=torch.float32).random_(1, 4)
    sparse_utils.apply_1_2_sparsity_cpu(a_cpu)

    a_compressed = torch.zeros(M, K // 2, L, dtype=torch.float32, device="cuda")
    # E is written in the TMEM atom layout, which requires (L, M, K/4) contiguous
    # storage; allocate it that way and view it as (M, K/4, L).
    meta = torch.zeros(L, M, K // 4, dtype=torch.uint8, device="cuda").permute(1, 2, 0)
    sparse_utils.compress(
        a_cpu.cuda(),
        a_compressed,
        meta,
        run_on_cpu=False,
        e_layout=su.E_LAYOUT_TF32_1_2_TMEM,
    )

    torch.testing.assert_close(a_compressed.cpu(), expected_1_2_compressed(a_cpu))
    verify_1_2_meta_nibbles(meta.cpu())

    print("test_tf32_1_2_cuda_compress passed")


if __name__ == "__main__":
    cutlass.cuda.initialize_cuda_context()
    # CPU tests (including compression)
    test_meta_data_generation()
    test_sparse_cpu()
    test_sparse_with_tensor()
    test_sparse_with_custom_metadata()
    test_different_meta_patterns()
    test_large_tensor()
    # CUDA tests (including compression)
    test_sparse_cuda()
    test_sparse_cuda_with_tensor()
    test_sparse_cuda_with_custom_metadata()
    test_cuda_different_meta_patterns()
    test_cuda_large_tensor()
    # Consistency tests (sparsity + compression)
    test_cpu_cuda_consistency()
    test_tf32_1_2_cuda_compress()
    print("All tests passed!")
