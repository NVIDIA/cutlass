# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited

"""
GEMM Tensor Utilities for CuTe DSL

This module provides end-to-end helpers for creating and wrapping GEMM operands
when using CuTe DSL with PyTorch integration. It consolidates tensor creation,
layout management, and DLPack-based wrapping for GPU kernels.

Key functions:
- create_gemm_tensor_torch: Allocate PyTorch CUDA tensors with MN-major or K-major layouts
- get_gemm_tensor: Wrap PyTorch tensors as CuTe tensors via DLPack
- get_gemm_tensors: Convenience wrapper for complete GEMM problem (A, B, D)
- create_scale_factor_tensor: Generate block-scaled GEMM scale factors
- decode_float4e2m1fn: Decode packed FP4 tensors to float32

Supports FP8/FP4 types with workarounds for DLPack limitations.
"""

import math
from typing import Tuple, Type

import torch

import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack
from cutlass.cutlass_dsl import Numeric
import cutlass.torch as cutlass_torch

__all__ = [
    "create_gemm_tensor_torch",
    "get_gemm_tensor",
    "get_gemm_tensors",
    "create_scale_factor_tensor",
    "decode_float4e2m1fn",
]


def create_gemm_tensor_torch(
    M_or_N: int,
    K_or_N: int,
    L: int,
    major_mode: cute.nvgpu.OperandMajorMode,
    dtype: torch.dtype,
) -> torch.Tensor:
    """
    Allocate a random GEMM operand as a PyTorch CUDA tensor.

    Returns a tensor of shape ``(M_or_N, K_or_N, L)`` with a physical layout
    determined by ``major_mode``:

    * ``MN``-major: stride ``(1, M_or_N, M_or_N * K_or_N)``
    * ``K``-major:  stride ``(K_or_N, 1, M_or_N * K_or_N)``

    Elements are initialised randomly from ``{-1, 0, 1}``.

    :param M_or_N: Size of the M (for A/D) or N (for B) dimension.
    :type M_or_N: int
    :param K_or_N: Size of the K (for A/B) or N (for D) dimension.
    :type K_or_N: int
    :param L: Batch dimension (number of independent GEMM problems).
    :type L: int
    :param major_mode: ``MN`` for MN-major layout, ``K`` for K-major layout.
    :type major_mode: cute.nvgpu.OperandMajorMode
    :param dtype: Element type of the returned tensor.
    :type dtype: torch.dtype
    :return: A CUDA tensor of shape ``(M_or_N, K_or_N, L)`` with the
        requested layout and dtype.
    :rtype: torch.Tensor
    """

    if major_mode == cute.nvgpu.OperandMajorMode.MN:
        result = torch.empty(L, K_or_N, M_or_N).permute(2, 1, 0)
    elif major_mode == cute.nvgpu.OperandMajorMode.K:
        result = torch.empty(L, M_or_N, K_or_N).permute(1, 2, 0)

    if dtype == torch.float4_e2m1fn_x2:
        values = torch.tensor(
            [
                0x00,  # { 0,  0}
                0x02,  # { 0,  1}
                0x0A,  # { 0, -1}
                0x20,  # { 1,  0}
                0x22,  # { 1,  1}
                0x2A,  # { 1, -1}
                0xA0,  # {-1,  0}
                0xA2,  # {-1,  1}
                0xAA,  # {-1, -1}
            ],
            dtype=torch.uint8,
        )

        # Note [dkb 16 Jan '26] we are consciously over-allocating by 2x
        # because it makes the code much simpler and terser.
        result = result.to(torch.uint8)
        result[:] = values[torch.randint(0, len(values), result.size())]

    else:
        result = result.random_(-1, 2).to(dtype)

    return result.cuda()


def get_gemm_tensor(
    torch_tensor: torch.Tensor,
    major_mode: cute.nvgpu.OperandMajorMode,
    dtype: torch.dtype,
) -> cute.Tensor:
    """
    Wrap a PyTorch tensor as a CuTe tensor for passing to a GPU kernel.

    Converts ``torch_tensor`` to a CuTe ``Tensor`` via DLPack and marks the
    leading dimension as dynamic so the compiler treats the corresponding
    stride as a runtime value:

    * ``K``-major  -> leading dim is 1 (K dimension has unit stride)
    * ``MN``-major -> leading dim is 0 (MN dimension has unit stride)

    :param torch_tensor: Source PyTorch CUDA tensor, typically created by
        :func:`create_gemm_tensor_torch`.
    :type torch_tensor: torch.Tensor
    :param major_mode: ``MN`` or ``K``, indicating which dimension has unit
        stride.
    :type major_mode: cute.nvgpu.OperandMajorMode
    :param dtype: Logical element type of the tensor.
    :type dtype: torch.dtype
    :return: A CuTe tensor backed by the same GPU memory, with its leading
        dimension marked dynamic and element type set to the CuTe equivalent
        of ``dtype``.
    :rtype: cutlass.cute.Tensor
    """

    _TYPES_NOT_SUPPORTED_BY_DLPACK = {
        torch.float8_e4m3fn: cute.Float8E4M3FN,
        torch.float8_e5m2: cute.Float8E5M2,
        torch.float8_e4m3fnuz: cute.Float8E4M3B11FNUZ,
        torch.float4_e2m1fn_x2: cute.Float4E2M1FN,
    }

    dlpack_tensor = torch_tensor
    if dtype in _TYPES_NOT_SUPPORTED_BY_DLPACK:
        dlpack_tensor = torch_tensor.view(dtype=torch.uint8)

    result = from_dlpack(dlpack_tensor, assumed_align=16).mark_layout_dynamic(
        leading_dim=1 if major_mode == cute.nvgpu.OperandMajorMode.K else 0
    )

    if dtype in _TYPES_NOT_SUPPORTED_BY_DLPACK:
        result.element_type = _TYPES_NOT_SUPPORTED_BY_DLPACK[dtype]

    return result


def get_gemm_tensors(
    M: int,
    N: int,
    K: int,
    L: int,
    majors: tuple[
        cute.nvgpu.OperandMajorMode,
        cute.nvgpu.OperandMajorMode,
        cute.nvgpu.OperandMajorMode,
    ],
    dtypes: tuple[torch.dtype, torch.dtype, torch.dtype],
) -> Tuple[
    torch.Tensor, torch.Tensor, torch.Tensor, cute.Tensor, cute.Tensor, cute.Tensor
]:
    """
    Allocate all three GEMM operands (A, B, D) as paired PyTorch / CuTe tensors.

    Convenience wrapper around :func:`create_gemm_tensor_torch` and
    :func:`get_gemm_tensor` for a complete GEMM problem ``D = A @ B``.

    :param M: Number of rows of A and D.
    :type M: int
    :param N: Number of columns of B and D.
    :type N: int
    :param K: Shared (contraction) dimension of A and B.
    :type K: int
    :param L: Batch dimension (number of independent GEMM problems).
    :type L: int
    :param majors: ``(major_A, major_B, major_D)`` specifying the physical
        layout of each operand.
    :type majors: tuple[OperandMajorMode, OperandMajorMode, OperandMajorMode]
    :param dtypes: ``(dtype_A, dtype_B, dtype_D)`` specifying the element type
        of each operand.
    :type dtypes: tuple[torch.dtype, torch.dtype, torch.dtype]
    :return: ``(A, B, D, A_cute, B_cute, D_cute)`` where ``A``, ``B``, ``D``
        are PyTorch CUDA tensors and ``A_cute``, ``B_cute``, ``D_cute`` are
        CuTe tensors wrapping the same memory.
    :rtype: tuple[torch.Tensor, torch.Tensor, torch.Tensor,
        cutlass.cute.Tensor, cutlass.cute.Tensor, cutlass.cute.Tensor]
    """

    A = create_gemm_tensor_torch(M, K, L, majors[0], dtypes[0])
    B = create_gemm_tensor_torch(N, K, L, majors[1], dtypes[1])
    D = create_gemm_tensor_torch(M, N, L, majors[2], dtypes[2])

    A_cute = get_gemm_tensor(A, majors[0], dtypes[0])
    B_cute = get_gemm_tensor(B, majors[1], dtypes[1])
    D_cute = get_gemm_tensor(D, majors[2], dtypes[2])

    return A, B, D, A_cute, B_cute, D_cute


def create_scale_factor_tensor(
    MN: int, K: int, L: int, sf_vec_size: int, sf_dtype: Type[Numeric]
) -> Tuple[torch.Tensor, cute.Tensor]:
    """
    Create a random scale-factor tensor in BlockScaledBasicChunk layout.

    Allocates a scale-factor tensor for block-scaled GEMM, where each scale
    factor covers ``sf_vec_size`` contiguous elements along K.  The MN and K
    dimensions are padded up to the required atom boundaries.

    Scale factor values are drawn uniformly from ``{1.0, 2.0, 4.0}``.

    Two tensors are returned: a logical FP32 tensor for host-side reference
    computation, and a CuTe tensor in the on-device packed layout for passing
    to the GPU kernel.

    :param MN: Size of the MN dimension of the operand to be scaled.
    :type MN: int
    :param K: Size of the K dimension of the operand to be scaled.
    :type K: int
    :param L: Batch dimension (number of independent GEMM problems).
    :type L: int
    :param sf_vec_size: Number of contiguous K-elements sharing a single
        scale factor (block-scaling granularity along K).
    :type sf_vec_size: int
    :param sf_dtype: CuTe element type for the on-device scale factors
        (e.g. ``cute.Float8E4M3FN``, ``cute.Float8E8M0FNU``).
    :return: ``(sf_torch, sf_cute)`` where ``sf_torch`` is an FP32 CPU tensor
        of shape ``(MN, K, L)`` with scale factors unpacked into a dense
        layout suitable for element-wise multiplication with A or B, and
        ``sf_cute`` is a CuTe CUDA tensor in BlockScaledBasicChunk layout
        with ``element_type`` set to ``sf_dtype``.
    :rtype: tuple[torch.Tensor, cutlass.cute.Tensor]
    """

    def unpack_scale_factors(
        sf: torch.Tensor, sf_vec_size: int, MN: int, K: int, L: int
    ) -> torch.Tensor:
        """
        Unpack a scale-factor tensor from BlockScaledBasicChunk layout to a
        dense ``(MN, K, L)`` tensor.

        The on-device SF layout packs scale factors into 512-byte atoms with
        a specific index mapping: 128-row MN tiles, 4-element K groups, and
        an interleaved ``(mn0, mn1, k1)`` addressing within each atom.  This
        function inverts that mapping so that the output element at position
        ``(m, k, l)`` holds the scale factor that applies to element
        ``(m, k, l)`` in A/B, ready for direct element-wise multiplication.

        :param sf: Scale-factor tensor in packed layout, shape
            ``(L, m_padded, k_padded)``.
        :type sf: torch.Tensor
        :param sf_vec_size: Number of K-elements per scale-factor block.
        :type sf_vec_size: int
        :param MN: Logical (unpadded) MN dimension.
        :type MN: int
        :param K: Logical (unpadded) K dimension.
        :type K: int
        :param L: Batch dimension.
        :type L: int
        :return: Dense FP32 tensor of shape ``(MN, K, L)`` with unpacked
            scale factors.
        :rtype: torch.Tensor
        """

        def index_map() -> torch.Tensor:
            ATOM = 512
            ATOM_MN = 128
            ATOM_K = 4
            DATA_PATHS = 32
            DATA_PATH_STRIDE = ATOM // DATA_PATHS  # 16
            K_TILE = ATOM_K * sf_vec_size

            k_tiles = (K + K_TILE - 1) // K_TILE
            mn_tiles = (MN + ATOM_MN - 1) // ATOM_MN
            sf_per_l = ATOM * mn_tiles * k_tiles

            m, k = torch.meshgrid(
                torch.arange(MN, device=sf.device),
                torch.arange(K, device=sf.device),
                indexing="ij",
            )

            base = (
                (m // ATOM_MN) * (ATOM * k_tiles)
                + (k // K_TILE) * ATOM
                + DATA_PATH_STRIDE * (m % DATA_PATHS)
                + ATOM_K * ((m % ATOM_MN) // DATA_PATHS)
                + ((k // sf_vec_size) % ATOM_K)
            )

            l_offsets = torch.arange(L, device=sf.device)[:, None, None] * sf_per_l
            return base.unsqueeze(0) + l_offsets

        return sf.flatten()[index_map()].permute(1, 2, 0)

    ATOM_MN = 128
    ATOM_K = 4

    m_padded = math.ceil(MN / ATOM_MN) * ATOM_MN
    k_padded = math.ceil(math.ceil(K / sf_vec_size) / ATOM_K) * ATOM_K

    lut = torch.tensor([1.0, 2.0, 4.0])  # subset of numbers supported by all SF dtypes
    sf_torch = lut[torch.randint(0, lut.numel(), (L, m_padded, k_padded))].to(
        cutlass_torch.dtype(sf_dtype)
    )

    sf_cute = from_dlpack(sf_torch.cuda().view(dtype=torch.uint8), assumed_align=16)
    sf_cute.element_type = sf_dtype
    sf_torch = unpack_scale_factors(sf_torch.to(torch.float32), sf_vec_size, MN, K, L)

    return sf_torch, sf_cute


def decode_float4e2m1fn(u8: torch.Tensor) -> torch.Tensor:
    """
    Decode a packed FP4 (E2M1) tensor into float32.

    Each byte in the input encodes two FP4 values: the low nibble holds the
    even-indexed element and the high nibble holds the odd-indexed element.
    Because ``create_gemm_tensor_torch`` intentionally over-allocates FP4
    tensors by 2x (one byte per logical element instead of one nibble), only
    the first half of the input bytes contain data.  This function unpacks
    those bytes via a 16-entry LUT covering all representable E2M1 values.

    :param u8: Packed FP4 tensor of shape ``(MN, K, L)`` with dtype
        ``torch.uint8``, as produced by :func:`create_gemm_tensor_torch`
        with ``dtype=torch.float4_e2m1fn_x2``.
    :type u8: torch.Tensor
    :return: Decoded float32 tensor of shape ``(MN, K, L)``.
    :rtype: torch.Tensor
    """

    lut = torch.tensor(
        [
            0.0,
            0.5,
            1.0,
            1.5,
            2.0,
            3.0,
            4.0,
            6.0,
            -0.0,
            -0.5,
            -1.0,
            -1.5,
            -2.0,
            -3.0,
            -4.0,
            -6.0,
        ],
        dtype=torch.float32,
    )

    MN, K, L = u8.shape
    flat = u8.permute(2, 0, 1).flatten()
    idx = torch.arange(u8.numel())
    byte_idx = idx // 2
    shift = (idx % 2) * 4
    return lut[(flat[byte_idx] >> shift) & 0xF].view(L, MN, K).permute(1, 2, 0)
