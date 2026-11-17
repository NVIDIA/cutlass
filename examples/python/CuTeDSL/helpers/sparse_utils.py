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

import numpy as np
import cutlass
import cutlass.torch as cutlass_torch
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack
from typing import Optional, Tuple, Type
import torch


# Layout codes for the E (metadata) tensor emitted by :meth:`SparseUtils.compress`.
# Kept as module-level integer constants so they can be used as compile-time
# selectors inside ``@cute.kernel`` without CuTe having to reason about Python
# enums. See the matching branches in :meth:`SparseUtils._compress_kernel` and
# :meth:`SparseUtils._SparseUtils__compress_on_cpu`.
E_LAYOUT_RAW = 0
"""e_raw layout: ``((M, _16, K/128), L) : ((_16, _1, M*_16), M*_16*K/128)``.
Used for element sizes other than 2 bytes in the legacy default."""

E_LAYOUT_FP16_HIERARCHICAL = 1
"""FP16/BF16 2:4 hierarchical TMEM layout:
``((_8,_2,_8, M/128),(_2,_2,_4, K/128), L) :
  ((_16,_2,_256, 2048),(_1,_128,_4, 2048*M/128), 2048*M/128*K/128)``."""

E_LAYOUT_TF32_1_2_TMEM = 2
"""TF32 1:2 hierarchical TMEM layout:
``((_8,_2,_8, M/128),(_2,_2,_4, K/64), L) :
  ((_16,_2,_256, 2048),(_1,_128,_4, 2048*M/128), 2048*M/128*K/64)``."""


class SparseUtils:
    """Utility class for generating and compressing sparse tensors with 4:2 structured sparsity.

    This class provides methods to generate sparse tensors with shape (M, K, L) following
    the 4:2 sparsity pattern, where every group of 4 elements contains exactly 2 non-zero values.

    :param M: Number of rows in the tensor
    :type M: int
    :param K: Number of columns in the tensor
    :type K: int
    :param L: Batch size
    :type L: int
    :param dtype: Data type of the tensor elements
    """

    def __init__(self, M: int, K: int, L: int, dtype):
        self.M = M
        self.K = K
        self.L = L
        self.dtype = dtype
        self._is_fp8 = dtype in {cutlass.Float8E4M3FN, cutlass.Float8E5M2}
        # Kernel-safe dtype: types that the DSL can't lower (FP8, TF32) are
        # mapped to their storage-equivalent type for zero-detection and
        # byte-copy operations in compiled CUDA kernels.
        if self._is_fp8:
            self._kernel_dtype = cutlass.Int8
        elif dtype == cutlass.TFloat32:
            self._kernel_dtype = cutlass.Float32
        else:
            self._kernel_dtype = dtype
        self.meta_data = self._generate_meta_data_4_2()

    def _encode_chunk_metadata(self, non_zero_indices):
        """Encode chunk metadata following C++ compressor_impl logic.

        :param non_zero_indices: Indices of non-zero elements in the chunk
        :type non_zero_indices: torch.Tensor

        :return: Tuple of (meta_val, pos0, pos1) where meta_val is 4-bit metadata,
                 pos0 and pos1 are the positions of non-zero elements
        :rtype: Tuple[int, int, int]
        """
        num_nonzeros = len(non_zero_indices)

        if num_nonzeros == 0:
            return 0xE, 2, 3
        elif num_nonzeros == 1:
            idx = non_zero_indices[0].item()
            if idx == 0:
                return 0xC, 0, 3
            elif idx == 1:
                return 0xD, 1, 3
            else:
                return 0xE, 2, 3
        elif num_nonzeros == 2:
            idx0, idx1 = non_zero_indices[0].item(), non_zero_indices[1].item()
            if idx0 == 0 and idx1 == 1:
                return 0x4, 0, 1
            elif idx0 == 0 and idx1 == 2:
                return 0x8, 0, 2
            elif idx0 == 0 and idx1 == 3:
                return 0xC, 0, 3
            elif idx0 == 1 and idx1 == 2:
                return 0x9, 1, 2
            elif idx0 == 1 and idx1 == 3:
                return 0xD, 1, 3
            elif idx0 == 2 and idx1 == 3:
                return 0xE, 2, 3
            else:
                return 0xE, 2, 3
        else:
            return 0xE, 2, 3

    def _generate_meta_data_4_2(self):
        """Generate uint8 packed metadata for 4:2 sparsity.

        Metadata encoding (4 bits per chunk):
        - 0x4: positions 0,1 are non-zero
        - 0x8: positions 0,2 are non-zero
        - 0xC: positions 0,3 are non-zero
        - 0x9: positions 1,2 are non-zero
        - 0xD: positions 1,3 are non-zero
        - 0xE: positions 2,3 are non-zero

        :return: Packed metadata with shape (M, K // 8, L)
        :rtype: torch.Tensor
        """
        meta_value = np.array([0x4, 0x8, 0x9, 0xC, 0xD, 0xE], dtype=np.uint8)

        K_NumChunk = self.K // 4
        K_Packed = K_NumChunk // 2

        raw_meta = np.random.choice(meta_value, size=(self.M, K_NumChunk, self.L))
        raw_meta = raw_meta.reshape(self.M, K_Packed, 2, self.L)

        shifts = np.array([0, 4], dtype=np.uint8).reshape(1, 1, 2, 1)
        packed_meta = np.sum(raw_meta << shifts, axis=2, dtype=np.uint8)

        return torch.from_numpy(packed_meta)

    def generate_4_2_sparse_tensor(self, run_on_cpu, meta_data: torch.Tensor = None):
        """Generate sparse tensor with shape (M, K, L).

        :param run_on_cpu: If True, generate tensor on CPU; otherwise on CUDA
        :type run_on_cpu: bool
        :param meta_data: Optional pre-generated metadata tensor
        :type meta_data: torch.Tensor, optional

        :return: Sparse tensor with 4:2 sparsity pattern
        :rtype: torch.Tensor
        """
        dtype = cutlass_torch.dtype(self.dtype)
        a = torch.empty(self.M, self.K, self.L).random_(-5, 5).to(dtype)
        if run_on_cpu:
            return self.generate_sparse_4_2_tensor_with_tensor(a, run_on_cpu, meta_data)
        else:
            return self.generate_sparse_4_2_tensor_with_tensor(
                a.cuda(), run_on_cpu, meta_data
            )

    def generate_sparse_4_2_tensor_with_tensor(
        self, a, run_on_cpu, meta_data: torch.Tensor = None
    ):
        """Generate sparse tensor from existing tensor.

        :param a: Input tensor to apply sparsity pattern to
        :type a: torch.Tensor
        :param run_on_cpu: If True, run on CPU; otherwise on CUDA
        :type run_on_cpu: bool
        :param meta_data: Optional pre-generated metadata tensor
        :type meta_data: torch.Tensor, optional

        :return: Sparse tensor with 4:2 sparsity pattern applied
        :rtype: torch.Tensor
        """
        meta = meta_data if meta_data is not None else self.meta_data

        if run_on_cpu:
            if a.device.type != "cpu":
                raise ValueError("a must be on cpu")
            return self.__generate_sparse_tensor_cpu(a, meta)
        else:
            if a.device.type != "cuda":
                raise ValueError("a must be on cuda")
            a_cute = from_dlpack(a)
            a_cute.element_type = self._kernel_dtype
            meta_cute = from_dlpack(meta.cuda())
            self.__generate_sparse_tensor_cuda(a_cute, meta_cute)
            return a

    def __generate_sparse_tensor_cpu(self, a, meta: torch.Tensor):
        """Generate sparse tensor on CPU using uint8 packed metadata.

        :param a: Input tensor to apply sparsity pattern to
        :type a: torch.Tensor
        :param meta: Packed metadata tensor with shape (M, K // 8, L)
        :type meta: torch.Tensor

        :return: Sparse tensor with 4:2 sparsity pattern applied
        :rtype: torch.Tensor
        """
        meta_to_mask = {
            0x4: [1, 1, 0, 0],
            0x8: [1, 0, 1, 0],
            0xC: [1, 0, 0, 1],
            0x9: [0, 1, 1, 0],
            0xD: [0, 1, 0, 1],
            0xE: [0, 0, 1, 1],
        }

        K_Packed = self.K // 8

        for l in range(self.L):
            tensor_mask = []
            for m in range(self.M):
                for j in range(K_Packed):
                    packed_val = int(meta[m, j, l])
                    for k in range(2):
                        meta_val = (packed_val >> (k * 4)) & 0xF
                        tensor_mask.extend(meta_to_mask[meta_val])

            a_slice = a[:, :, l].reshape(-1)
            mask = torch.tensor(tensor_mask, dtype=a.dtype, device=a.device)
            a[:, :, l] = (a_slice * mask).reshape(self.M, self.K)

        return a

    @cute.jit
    def __generate_sparse_tensor_cuda(self, a: cute.Tensor, meta: cute.Tensor):
        """Generate sparse tensor on CUDA using uint8 packed metadata.

        :param a: Input tensor to apply sparsity pattern to
        :type a: cute.Tensor
        :param meta: Packed metadata tensor with shape (M, K // 8, L)
        :type meta: cute.Tensor
        """
        assert a.shape[0] == self.M and a.shape[1] == self.K and a.shape[2] == self.L
        assert (
            meta.shape[0] == self.M
            and meta.shape[1] == self.K // 8
            and meta.shape[2] == self.L
        )

        num_threads = 128
        grid = (cute.ceil_div(self.M, num_threads), self.L, 1)
        block = (num_threads, 1, 1)
        self._apply_4_2_sparsity_kernel(a, meta).launch(grid=grid, block=block)

    @cute.kernel
    def _apply_4_2_sparsity_kernel(self, a: cute.Tensor, meta: cute.Tensor):
        """CUDA kernel to apply 4:2 sparsity mask using uint8 packed metadata.

        :param a: Input tensor to apply sparsity pattern to
        :type a: cute.Tensor
        :param meta: Packed metadata tensor with shape (M, K // 8, L)
        :type meta: cute.Tensor
        """
        tidx, tidy, tidz = cute.arch.thread_idx()
        bidx, bidy, bidz = cute.arch.block_idx()

        # Int64: crd2idx takes its width from the coordinate and defaults to 32
        # bits, so an i32 coordinate silently wraps. row_idx * K overflows once
        # M*K > 2^31 and batch_idx * M*K once M*K*L > 2^31.
        row_idx = cutlass.Int64(tidx) + cutlass.Int64(bidx) * 128
        batch_idx = cutlass.Int64(bidy)
        meta_count = self.K // 8

        if row_idx < self.M:
            for i in range(meta_count):
                meta_val = meta[(row_idx, i, batch_idx)]
                for j in range(2):
                    meta_nibble = (meta_val >> (j * 4)) & 0xF
                    idx0 = meta_nibble & 0x3
                    idx1 = (meta_nibble >> 2) & 0x3

                    r_id0 = 0
                    r_id1 = 0
                    if idx0 >= 2 and idx1 >= 2:
                        r_id0 = 0
                        r_id1 = 1
                    elif idx0 <= 1 and idx1 <= 1:
                        r_id0 = 2
                        r_id1 = 3
                    else:
                        r_id0 = idx0 ^ 0b1
                        r_id1 = idx1 ^ 0b1

                    col_id0 = r_id0 + i * 8 + j * 4
                    col_id1 = r_id1 + i * 8 + j * 4

                    zero_val = self._kernel_dtype(0)
                    a[row_idx, col_id0, batch_idx] = zero_val
                    a[row_idx, col_id1, batch_idx] = zero_val
        return

    def compress(
        self,
        a: torch.Tensor,
        a_compressed: torch.Tensor,
        meta: torch.Tensor,
        run_on_cpu: bool,
        e_layout: Optional[int] = None,
    ):
        """Compress a 4:2 / 1:2 sparse tensor to dense format with metadata.

        The output metadata ``meta`` is written in the layout selected by
        ``e_layout``. When ``e_layout`` is ``None`` (default), it is inferred
        from ``a.element_size()`` to preserve the prior behaviour:

        - ``a.element_size() == 2`` (FP16 / BF16)    -> ``E_LAYOUT_FP16_HIERARCHICAL``
        - any other element size                     -> ``E_LAYOUT_RAW``

        To opt in to the TF32 1:2 TMEM layout, pass
        ``e_layout=E_LAYOUT_TF32_1_2_TMEM`` explicitly. That path requires a
        *different* ``meta`` shape (``(M, K // 4, L)`` bytes rather than
        ``(M, K // 8, L)``) and a different sparsity encoding (one non-zero
        per pair of 2 TF32 elements, encoded as the 4-bit nibbles
        ``0x4`` / ``0xE`` packed 2-per-byte). See
        :meth:`__compress_tf32_1_2_on_cpu` for details.

        :param a: Sparse tensor with shape (M, K, L)
        :type a: torch.Tensor
        :param a_compressed: Output tensor with shape (M, K // 2, L)
        :type a_compressed: torch.Tensor
        :param meta: Output uint8 packed metadata with shape ``(M, K // 8, L)``
            for the 2:4 paths or ``(M, K // 4, L)`` for TF32 1:2.
        :type meta: torch.Tensor
        :param run_on_cpu: If True, run compression on CPU; otherwise on CUDA
        :type run_on_cpu: bool
        :param e_layout: Target layout code for ``meta``; one of
            ``E_LAYOUT_RAW``, ``E_LAYOUT_FP16_HIERARCHICAL``,
            ``E_LAYOUT_TF32_1_2_TMEM``. ``None`` auto-selects based on
            ``a.element_size()`` for backward compatibility.
        :type e_layout: Optional[int]

        :raises ValueError: if ``e_layout`` is not a recognised layout code.
        """
        if e_layout is None:
            e_layout = (
                E_LAYOUT_FP16_HIERARCHICAL if a.element_size() == 2 else E_LAYOUT_RAW
            )
        if e_layout not in (
            E_LAYOUT_RAW,
            E_LAYOUT_FP16_HIERARCHICAL,
            E_LAYOUT_TF32_1_2_TMEM,
        ):
            raise ValueError(
                f"Unknown e_layout={e_layout}; expected one of "
                f"{{E_LAYOUT_RAW={E_LAYOUT_RAW}, "
                f"E_LAYOUT_FP16_HIERARCHICAL={E_LAYOUT_FP16_HIERARCHICAL}, "
                f"E_LAYOUT_TF32_1_2_TMEM={E_LAYOUT_TF32_1_2_TMEM}}}"
            )

        is_1_2 = e_layout == E_LAYOUT_TF32_1_2_TMEM

        if run_on_cpu:
            if a.device.type != "cpu":
                raise ValueError("a must be on cpu")
            if is_1_2:
                self.__compress_tf32_1_2_on_cpu(a, a_compressed, meta)
            else:
                self.__compress_on_cpu(a, a_compressed, meta, e_layout)
            return

        if a.device.type != "cuda":
            raise ValueError("a must be on cuda")
        a_cute = from_dlpack(a)
        a_cute.element_type = self._kernel_dtype
        a_compressed_cute = from_dlpack(a_compressed)
        a_compressed_cute.element_type = self._kernel_dtype
        meta_cute = from_dlpack(meta)
        write_hierarchical_e = is_1_2 or e_layout == E_LAYOUT_FP16_HIERARCHICAL
        logical_per_nibble = 2 if is_1_2 else 4
        self.__compress_on_cuda(
            a_cute,
            a_compressed_cute,
            meta_cute,
            write_hierarchical_e,
            logical_per_nibble,
        )

    def __compress_on_cpu(
        self,
        a: torch.Tensor,
        a_compressed: torch.Tensor,
        meta: torch.Tensor,
        e_layout: int,
    ):
        """Compress sparse tensor on CPU following C++ compressor_impl logic.

        The CPU path always writes ``meta`` in the e_raw layout first, then
        dispatches a pure-Python reorder into the target layout in-place:

        - ``E_LAYOUT_RAW``                -> leave e_raw as written
        - ``E_LAYOUT_FP16_HIERARCHICAL``  -> :meth:`fp16_e_meta_reorder`

        :param a: Sparse tensor with shape (M, K, L)
        :type a: torch.Tensor
        :param a_compressed: Output compressed tensor with shape (M, K // 2, L)
        :type a_compressed: torch.Tensor
        :param meta: Output metadata tensor with shape (M, K // 8, L)
        :type meta: torch.Tensor
        :param e_layout: Target layout code for ``meta``. Must be
            ``E_LAYOUT_RAW`` or ``E_LAYOUT_FP16_HIERARCHICAL``;
            ``E_LAYOUT_TF32_1_2_TMEM`` is dispatched from :meth:`compress` to
            :meth:`__compress_tf32_1_2_on_cpu` directly and never reaches
            this function.
        :type e_layout: int
        """
        M, K, L = a.shape

        ChunkSize = 4
        tile_step_a = 2 * ChunkSize
        k_tile_num = (K + tile_step_a - 1) // tile_step_a

        # e_raw layout:
        #   shape  ((  M,  _16,    K/128),                 L)
        #   stride ((_16,   _1, M*_16), M*_16*K/128)
        e_raw_shape_k0 = 16
        e_raw_stride_m = e_raw_shape_k0
        e_raw_stride_k1 = M * e_raw_stride_m

        for batch_idx in range(L):
            meta_batch = meta[:, :, batch_idx].view(-1)
            for m_idx in range(M):
                for tiler_k_idx in range(k_tile_num):
                    k_base = tiler_k_idx * tile_step_a
                    meta_two_chunk = 0

                    for chunk_idx in range(2):
                        chunk_start = k_base + chunk_idx * ChunkSize

                        if chunk_start + ChunkSize <= K:
                            chunk = a[
                                m_idx, chunk_start : chunk_start + ChunkSize, batch_idx
                            ]
                        else:
                            remaining = K - chunk_start
                            if remaining > 0:
                                chunk = torch.cat(
                                    [
                                        a[m_idx, chunk_start:K, batch_idx],
                                        torch.zeros(
                                            ChunkSize - remaining, dtype=a.dtype
                                        ),
                                    ]
                                )
                            else:
                                chunk = torch.zeros(ChunkSize, dtype=a.dtype)

                        non_zero_mask = chunk != 0
                        non_zero_indices = torch.nonzero(non_zero_mask).squeeze()

                        if non_zero_indices.dim() == 0:
                            non_zero_indices = (
                                non_zero_indices.unsqueeze(0)
                                if non_zero_mask.any()
                                else torch.tensor([], dtype=torch.long)
                            )

                        meta_val, pos0, pos1 = self._encode_chunk_metadata(
                            non_zero_indices
                        )
                        meta_two_chunk |= meta_val << (chunk_idx * 4)

                        compressed_base = tiler_k_idx * ChunkSize + chunk_idx * 2
                        if compressed_base < K // 2:
                            a_compressed[m_idx, compressed_base, batch_idx] = chunk[
                                pos0
                            ]
                            if compressed_base + 1 < K // 2:
                                a_compressed[m_idx, compressed_base + 1, batch_idx] = (
                                    chunk[pos1]
                                )

                    # Map to e_raw layout: k = k0 + k1*16
                    e_raw_index_k0 = tiler_k_idx % e_raw_shape_k0
                    e_raw_index_k1 = tiler_k_idx // e_raw_shape_k0

                    meta_linear_idx = (
                        m_idx * e_raw_stride_m
                        + e_raw_index_k0
                        + e_raw_index_k1 * e_raw_stride_k1
                    )

                    if meta_linear_idx < len(meta_batch):
                        meta_batch[meta_linear_idx] = meta_two_chunk

        # Post-hoc reorder into the requested output layout. The e_raw path is
        # a no-op because the loop above already writes the e_raw layout.
        if e_layout == E_LAYOUT_FP16_HIERARCHICAL:
            meta_reordered = self.fp16_e_meta_reorder(meta)
            meta.copy_(meta_reordered)

    def fp16_e_meta_reorder(self, e_raw: torch.Tensor) -> torch.Tensor:
        """Reorder metadata tensor from e_raw format to final e format for FP16/BF16.

        Input e_raw layout: (M, K//8, L) with strides (16, 1, M*16) per batch
        Output e layout: (M, K//8, L) with hierarchical permuted layout

        :param e_raw: Raw metadata tensor with shape (M, K // 8, L)
        :type e_raw: torch.Tensor

        :return: Reordered metadata tensor with hierarchical layout
        :rtype: torch.Tensor
        """
        m, k_div_8, l = e_raw.shape
        k = k_div_8 * 8

        assert e_raw.shape == (self.M, self.K // 8, self.L)
        assert e_raw.dtype == torch.uint8

        e = torch.zeros_like(e_raw)

        # e_raw layout (input):
        #   shape  ((  M,  _16,    K/128),                 L)
        #   stride ((_16,   _1, M*_16), M*_16*K/128)
        e_raw_stride_m = 16
        e_raw_stride_k1 = m * e_raw_stride_m

        # e layout (output):
        #   shape  (( _8,_2,  _8, M/128),(_2,  _2,_4,      K/128),               L)
        #   stride ((_16,_2,_256,  2048),(_1,_128,_4, 2048*M/128),2048*M/128*K/128)
        e_shape_m3 = m // 128
        e_shape_k3 = k // 128
        e_stride_m3 = 2048
        e_stride_k3 = e_stride_m3 * e_shape_m3

        for l_idx in range(l):
            e_raw_batch = e_raw[:, :, l_idx].view(-1)
            e_batch = e[:, :, l_idx].view(-1)
            for m0 in range(8):
                for m1 in range(2):
                    for m2 in range(8):
                        for m3 in range(e_shape_m3):
                            for k0 in range(2):
                                for k1 in range(2):
                                    for k2 in range(4):
                                        for k3 in range(e_shape_k3):
                                            # Logical coordinates
                                            m_index = m0 + m1 * 8 + m2 * 16 + m3 * 128
                                            k_index = k0 + k1 * 2 + k2 * 4 + k3 * 16

                                            # e_raw offset
                                            e_raw_k0 = k_index % 16
                                            e_raw_k1 = k_index // 16
                                            e_raw_offset = (
                                                m_index * e_raw_stride_m
                                                + e_raw_k0
                                                + e_raw_k1 * e_raw_stride_k1
                                            )

                                            # Hierarchical e offset
                                            e_offset = (
                                                m0 * 16
                                                + m1 * 2
                                                + m2 * 256
                                                + m3 * e_stride_m3
                                                + k0
                                                + k1 * 128
                                                + k2 * 4
                                                + k3 * e_stride_k3
                                            )

                                            e_batch[e_offset] = e_raw_batch[
                                                e_raw_offset
                                            ]

        return e

    def apply_1_2_sparsity_cpu(self, a: torch.Tensor) -> torch.Tensor:
        """Create a sparse tensor with 1:2 sparsity

        For 1:2 sparse granularity, every consecutive pair of 2 K-elements,
        exactly one is kept (non-zero) and the other is zeroed.
        The kept position is chosen uniformly at random.

        :param a: Tensor with shape (M, K, L). Modified in-place.
        :type a: torch.Tensor
        :return: The same tensor ``a``, for chaining.
        :rtype: torch.Tensor
        """
        M, K, L = a.shape
        if K % 2 != 0:
            raise ValueError(f"TF32 1:2 sparsity requires K % 2 == 0, got K={K}")

        # Pick position 0 or 1 for each pair; expand to a per-element mask.
        # selections[m, p, l] in {0, 1} -> which K-element of pair p to keep.
        selections = torch.randint(0, 2, (M, K // 2, L), dtype=torch.long)
        mask_per_pair = torch.stack([selections == 0, selections == 1], dim=2).to(
            a.dtype
        )
        mask = mask_per_pair.reshape(M, K, L)
        a.mul_(mask)
        return a

    def __compress_tf32_1_2_on_cpu(
        self,
        a: torch.Tensor,
        a_compressed: torch.Tensor,
        meta: torch.Tensor,
    ):
        """Compress a TF32 1:2 sparse tensor on CPU directly into the kernel's
        TMEM E atom layout.

        Semantics (vs. the 2:4 path in :meth:`__compress_on_cpu`):

        - *Pair* granularity, not *chunk* granularity. We walk ``a`` in
          consecutive pairs of 2 K-elements and emit one 4-bit nibble per
          pair:

          ==========  ===============  ==============
          Position 0  Position 1       Nibble
          ==========  ===============  ==============
          non-zero    zero             ``0x4`` (0100)
          zero        non-zero         ``0xE`` (1110)
          zero        zero             ``0x4`` (conventional; value is 0)
          non-zero    non-zero         rejected (ValueError)
          ==========  ===============  ==============

        - Two pair-nibbles pack into one byte (low nibble = pair 0 of the
          byte, high nibble = pair 1), so one byte carries metadata for 4
          consecutive TF32 elements. This matches the ``num_logical=4`` sparse
          E dtype returned by
          :func:`cutlass.utils.blackwell_helpers.make_sparse_e_dtype` for
          TF32.

        - Metadata budget is therefore ``M * K / 4`` bytes per batch (not
          ``M * K / 8`` as the 2:4 path uses).

        The bytes are placed directly into the atom layout returned by
        :func:`cutlass.utils.blackwell_helpers.sm100_utils.make_tensor_e_atom_layout`
        for TF32:

        .. code-block:: text

            atom shape  ((8, 2, 8), (8, 2, 4))        # logical (m_in_atom, k_tf32_in_atom)
            atom stride ((64, 8, 1024), (1, 512, 16)) # logical units (4 logical per byte)
            atom cosize 8192 logical = 2048 bytes, covering M=128 x K_tf32=64

        Converted to byte coordinates (divide logical stride by 4) this
        becomes:

        .. code-block:: text

            M:      (8, 2, 8)  byte stride (16, 2, 256)
            K_byte: (2, 2, 4)  byte stride ( 1, 128,   4)    # K=8 logical inner dim
                                                             # split into 4 sub-byte
                                                             # + 2 byte-granular halves.

        The outer tiling matches
        :func:`make_sparse_gmem_layout_e` exactly:

        .. code-block:: text

            outer M stride  = 2048 bytes                    (= atom cosize in bytes)
            outer K stride  = M * 16 bytes                  (= m_aligned_e * atom_k_bytes)
            batch stride    = M * K / 4 bytes               (full tensor per batch)

        :param a: Sparse tensor with shape (M, K, L). Must already satisfy
            the 1:2 invariant (see :meth:`apply_1_2_sparsity_cpu`).
        :type a: torch.Tensor
        :param a_compressed: Output packed non-zero values with shape
            ``(M, K/2, L)`` and the same dtype as ``a``.
        :type a_compressed: torch.Tensor
        :param meta: Output uint8 metadata with shape ``(M, K/4, L)``. Its
            underlying storage must be laid out as ``(L, M, K/4)``
            contiguous (i.e. allocated via
            ``cutlass_torch.matrix(L, M, K//4, is_mode0_major=False, ...)``),
            so that ``meta.permute(2, 0, 1)`` is contiguous and can be
            reshaped to a flat 1D view of the storage for direct
            offset-based writes.
        :type meta: torch.Tensor

        :raises ValueError: if the shapes, dtypes, or strides don't line up,
            or if any pair of ``a`` has both positions non-zero (violates
            1:2 invariant).
        """
        M, K, L = a.shape

        if M % 128 != 0:
            raise ValueError(f"TF32 1:2 TMEM layout requires M % 128 == 0, got M={M}")
        if K % 64 != 0:
            raise ValueError(f"TF32 1:2 TMEM layout requires K % 64 == 0, got K={K}")
        if tuple(meta.shape) != (M, K // 4, L):
            raise ValueError(
                f"meta must have shape (M, K/4, L) = ({M}, {K // 4}, {L}) "
                f"for TF32 1:2, got {tuple(meta.shape)}"
            )
        if tuple(a_compressed.shape) != (M, K // 2, L):
            raise ValueError(
                f"a_compressed must have shape (M, K/2, L) = "
                f"({M}, {K // 2}, {L}), got {tuple(a_compressed.shape)}"
            )
        if meta.dtype != torch.uint8:
            raise ValueError(f"meta must be uint8, got {meta.dtype}")

        # Get a contiguous flat 1D view of the meta tensor's storage so we
        # can write bytes at the atom-layout-computed flat offsets directly.
        # The assumed storage order is (L, M, K/4) contiguous, which is what
        # ``cutlass_torch.matrix(L, M, K//4, is_mode0_major=False, ...)``
        # produces; its permute(2, 0, 1) view is contiguous.
        meta_lmk = meta.permute(2, 0, 1)
        if not meta_lmk.is_contiguous():
            raise ValueError(
                "meta tensor's storage must be (L, M, K/4) contiguous for "
                "TF32 1:2 writes. Allocate via "
                "`cutlass_torch.matrix(L, M, K//4, is_mode0_major=False, "
                "Uint8, SKIP)`."
            )
        meta_flat = meta_lmk.reshape(-1)
        meta_flat.zero_()

        # Atom-layout constants (see docstring).
        outer_m_stride = 2048
        outer_k_stride = M * 16
        batch_stride = M * (K // 4)

        for l_idx in range(L):
            for m in range(M):
                # Atom M decomposition: m = m0 + m1*8 + m2*16 + m_outer*128
                m_in_atom = m % 128
                m_outer = m // 128
                m0 = m_in_atom % 8
                m1 = (m_in_atom // 8) % 2
                m2 = m_in_atom // 16
                m_byte_inner = m0 * 16 + m1 * 2 + m2 * 256
                m_byte_outer = m_outer * outer_m_stride

                for byte_idx in range(K // 4):
                    # Each byte covers 4 consecutive K TF32 elements = 2 pairs.
                    k_base = byte_idx * 4
                    v = [a[m, k_base + i, l_idx] for i in range(4)]
                    nz = [bool(v_i != 0) for v_i in v]

                    # Encode two pair-nibbles:
                    #   pair 0 -> (v[0], v[1]) -> low nibble
                    #   pair 1 -> (v[2], v[3]) -> high nibble
                    nibbles = []
                    kept = []
                    for p in range(2):
                        off0 = 2 * p
                        off1 = off0 + 1
                        if nz[off0] and nz[off1]:
                            raise ValueError(
                                f"TF32 1:2 pair at (m={m}, "
                                f"k_start={k_base + off0}, l={l_idx}) has "
                                f"both positions non-zero; 1:2 sparsity "
                                f"requires at most one non-zero per pair."
                            )
                        if nz[off1]:
                            nibbles.append(0xE)
                            kept.append(v[off1])
                        else:
                            nibbles.append(0x4)
                            kept.append(v[off0])

                    byte_val = (nibbles[0] & 0xF) | ((nibbles[1] & 0xF) << 4)

                    # Atom K_byte decomposition:
                    #   byte_in_atom = k0_b + k1*2 + k2*4 with sizes (2, 2, 4)
                    #   byte strides                    (1, 128, 4)
                    byte_in_atom = byte_idx % 16
                    k_outer = byte_idx // 16
                    k0_b = byte_in_atom % 2
                    k1 = (byte_in_atom // 2) % 2
                    k2 = byte_in_atom // 4
                    k_byte_inner = k0_b + k1 * 128 + k2 * 4
                    k_byte_outer = k_outer * outer_k_stride

                    flat_offset = (
                        m_byte_inner
                        + m_byte_outer
                        + k_byte_inner
                        + k_byte_outer
                        + l_idx * batch_stride
                    )
                    meta_flat[flat_offset] = byte_val

                    # Emit compressed non-zero values for both pairs.
                    a_compressed[m, byte_idx * 2, l_idx] = kept[0]
                    a_compressed[m, byte_idx * 2 + 1, l_idx] = kept[1]

    @cute.jit
    def __compress_on_cuda(
        self,
        a: cute.Tensor,
        a_compressed: cute.Tensor,
        meta: cute.Tensor,
        write_hierarchical_e: cutlass.Constexpr[bool],
        logical_per_nibble: cutlass.Constexpr[int],
    ):
        """Compress a 2:4 or 1:2 sparse tensor on CUDA.

        :param a: Sparse tensor with shape (M, K, L)
        :type a: cute.Tensor
        :param a_compressed: Output compressed tensor with shape (M, K // 2, L)
        :type a_compressed: cute.Tensor
        :param meta: Output metadata tensor with shape
            ``(M, K // (2 * logical_per_nibble), L)``
        :type meta: cute.Tensor
        :param write_hierarchical_e: True to write the hierarchical TMEM layout
            directly, False to write to plain layout.
        :type write_hierarchical_e: cutlass.Constexpr[bool]
        :param logical_per_nibble: 4 for 2:4 sparsity, 2 for 1:2.
        :type logical_per_nibble: cutlass.Constexpr[int]
        """
        num_threads = 128
        grid = (cute.ceil_div(self.M, num_threads), self.L, 1)
        block = (num_threads, 1, 1)
        self._compress_kernel(
            a, a_compressed, meta, write_hierarchical_e, logical_per_nibble
        ).launch(grid=grid, block=block)

    @cute.kernel
    def _compress_kernel(
        self,
        a: cute.Tensor,
        a_compressed: cute.Tensor,
        meta: cute.Tensor,
        write_hierarchical_e: cutlass.Constexpr[bool],
        logical_per_nibble: cutlass.Constexpr[int],
    ):
        """CUDA kernel to compress a 2:4 or 1:2 sparse tensor.

        The compression can vary based on:

        Granularity selection:
        - logical_per_nibble = 4 -> 2:4. A nibble names the two nonzeros of a group of four, so a
          metadata byte covers 8 logical elements and the compressed A has K/8 elements.
        - logical_per_nibble = 2 -> 1:2 . A nibble names the sole nonzero of a pair, so a byte
          covers 4 logical elements and the compressed A has K/4 elements.

        Layout selection. This picks the offset the metadata byte is written
        to:
        - write_hierarchical_e=True: the interleaved 128x16-byte atom
        - write_hierarchical_e=False: The flat row-major atom

        A group that has more nonzeros than the granularity allows is not rejected.
        It silently drops the excess.

        :param a: Sparse tensor with shape (M, K, L)
        :type a: cute.Tensor
        :param a_compressed: Output compressed tensor with shape (M, K // 2, L)
        :type a_compressed: cute.Tensor
        :param meta: Output metadata tensor with shape (M, K // 8, L) for 2:4
            or (M, K // 4, L) for 1:2. Its storage must be (L, M, bytes)
            contiguous.
        :type meta: cute.Tensor
        :param write_hierarchical_e: True for the interleaved atom, False for
            e_raw.
        :type write_hierarchical_e: cutlass.Constexpr[bool]
        :param logical_per_nibble: 4 for 2:4 sparsity, 2 for 1:2.
        :type logical_per_nibble: cutlass.Constexpr[int]
        """
        if cutlass.const_expr(logical_per_nibble not in (2, 4)):
            raise ValueError(
                f"logical_per_nibble must be 4 (2:4) or 2 (1:2), got "
                f"{logical_per_nibble}"
            )
        if cutlass.const_expr(logical_per_nibble == 2 and not write_hierarchical_e):
            raise ValueError(
                "1:2 sparsity can only be written in the hierarchical layout: "
                "the e_raw strides below hard-code 16 metadata bytes per row "
                "per 128 logical elements, which assumes 2:4."
            )

        tidx, tidy, tidz = cute.arch.thread_idx()
        bidx, bidy, bidz = cute.arch.block_idx()

        # Int64: crd2idx takes its width from the coordinate and defaults to 32
        # bits, so an i32 coordinate silently wraps. row_idx * K overflows once
        # M*K > 2^31 and batch_idx * M*K once M*K*L > 2^31.
        row_idx = cutlass.Int64(tidx) + cutlass.Int64(bidx) * 128
        batch_idx = cutlass.Int64(bidy)
        logical_per_byte = 2 * logical_per_nibble
        meta_count = self.K // logical_per_byte

        # e_raw layout:
        #   shape  ((  M,  _16,    K/128),                 L)
        #   stride ((_16,   _1, M*_16), M*_16*K/128)
        e_raw_stride_m = 16
        e_raw_stride_k1 = self.M * 16

        # e layout (hierarchical):
        #   shape  (( _8,_2,  _8, M/128),(_2,  _2,_4,      K/128),               L)
        #   stride ((_16,_2,_256,  2048),(_1,_128,_4, 2048*M/128),2048*M/128*K/128)
        e_shape_m3 = self.M // 128
        e_stride_m3 = 2048
        e_stride_k3 = e_stride_m3 * e_shape_m3

        if row_idx < self.M:
            # Decompose M: row_idx = m0 + m1*8 + m2*16 + m3*128
            m0 = row_idx % 8
            m1 = (row_idx // 8) % 2
            m2 = (row_idx // 16) % 8
            m3 = row_idx // 128

            for i in range(meta_count):
                meta_two_chunk = cutlass.Uint8(0)

                for j in range(2):
                    base_k = i * logical_per_byte + j * logical_per_nibble
                    compressed_base = base_k // 2
                    cmp_zero = self._kernel_dtype(0.0)

                    if cutlass.const_expr(logical_per_nibble == 4):
                        val0 = a[row_idx, base_k, batch_idx]
                        val1 = a[row_idx, base_k + 1, batch_idx]
                        val2 = a[row_idx, base_k + 2, batch_idx]
                        val3 = a[row_idx, base_k + 3, batch_idx]

                        nz0 = val0 != cmp_zero
                        nz1 = val1 != cmp_zero
                        nz2 = val2 != cmp_zero
                        nz3 = val3 != cmp_zero

                        tmp = cutlass.Uint8(0xE)
                        pos0 = 2
                        pos1 = 3

                        if nz0 and nz1:
                            tmp = cutlass.Uint8(0x4)
                            pos0 = 0
                            pos1 = 1
                        elif nz0 and nz2:
                            tmp = cutlass.Uint8(0x8)
                            pos0 = 0
                            pos1 = 2
                        elif nz0 and nz3:
                            tmp = cutlass.Uint8(0xC)
                            pos0 = 0
                            pos1 = 3
                        elif nz1 and nz2:
                            tmp = cutlass.Uint8(0x9)
                            pos0 = 1
                            pos1 = 2
                        elif nz1 and nz3:
                            tmp = cutlass.Uint8(0xD)
                            pos0 = 1
                            pos1 = 3
                        elif nz2 and nz3:
                            tmp = cutlass.Uint8(0xE)
                            pos0 = 2
                            pos1 = 3
                        elif nz0:
                            tmp = cutlass.Uint8(0xC)
                            pos0 = 0
                            pos1 = 3
                        elif nz1:
                            tmp = cutlass.Uint8(0xD)
                            pos0 = 1
                            pos1 = 3
                        elif nz2:
                            tmp = cutlass.Uint8(0xE)
                            pos0 = 2
                            pos1 = 3
                        elif nz3:
                            tmp = cutlass.Uint8(0xE)
                            pos0 = 2
                            pos1 = 3

                        v0 = val0
                        v1 = val0
                        if pos0 == 1:
                            v0 = val1
                        elif pos0 == 2:
                            v0 = val2
                        elif pos0 == 3:
                            v0 = val3

                        if pos1 == 1:
                            v1 = val1
                        elif pos1 == 2:
                            v1 = val2
                        elif pos1 == 3:
                            v1 = val3

                        a_compressed[row_idx, compressed_base, batch_idx] = v0
                        a_compressed[row_idx, compressed_base + 1, batch_idx] = v1
                    else:
                        val0 = a[row_idx, base_k, batch_idx]
                        val1 = a[row_idx, base_k + 1, batch_idx]

                        # the two zeroes pair keeps position 0 and encodes 0x4;
                        # the value it selects is zero either way.
                        tmp = cutlass.Uint8(0x4)
                        v0 = val0
                        if val1 != cmp_zero:
                            # if both values are nonzero, drop the first
                            tmp = cutlass.Uint8(0xE)
                            v0 = val1

                        a_compressed[row_idx, compressed_base, batch_idx] = v0

                    meta_two_chunk = cutlass.Uint8(meta_two_chunk | (tmp << (j * 4)))

                # Int64: both branches derive from the Int64 row_idx.
                meta_linear_idx = cutlass.Int64(0)
                if cutlass.const_expr(write_hierarchical_e):
                    # Hierarchical e layout: k = k0 + k1*2 + k2*4 + k3*16
                    k0 = i % 2
                    k1 = (i // 2) % 2
                    k2 = (i // 4) % 4
                    k3 = i // 16

                    meta_linear_idx = (
                        m0 * 16
                        + m1 * 2
                        + m2 * 256
                        + m3 * e_stride_m3
                        + k0
                        + k1 * 128
                        + k2 * 4
                        + k3 * e_stride_k3
                    )
                else:
                    # e_raw layout: k = k0 + k1*16
                    e_raw_index_k0 = i % 16
                    e_raw_index_k1 = i // 16
                    meta_linear_idx = (
                        row_idx * e_raw_stride_m
                        + e_raw_index_k0
                        + e_raw_index_k1 * e_raw_stride_k1
                    )

                m_idx = meta_linear_idx // meta_count
                k_idx = meta_linear_idx % meta_count

                meta[m_idx, k_idx, batch_idx] = meta_two_chunk

        return


def make_zero_cute_tensor_on_gpu(
    shape: Tuple[int, ...],
    permute_order: Tuple[int, ...],
    cutlass_dtype: Type[cutlass.Numeric],
    assumed_align: int = 16,
) -> Tuple:
    """Allocate a zero-initialized GPU torch tensor and wrap it as a CuTe tensor.

    Bypasses CPU allocation and :func:`convert_cute_tensor` — intended for
    ``skip_ref_check`` perf paths where tensor contents do not affect kernel
    correctness. Storage torch dtype mirrors the mapping in
    ``cutlass/torch.py:cute_tensor_like`` (FP<=8 / Int4 -> int8, else native).
    """
    if (cutlass_dtype.is_float and cutlass_dtype.width <= 8) or (
        cutlass_dtype.is_integer and cutlass_dtype.width == 4
    ):
        torch_storage_dtype = torch.int8
    else:
        torch_storage_dtype = cutlass_torch.dtype(cutlass_dtype)

    torch_tensor = torch.zeros(
        shape, dtype=torch_storage_dtype, device=torch.device("cuda")
    ).permute(permute_order)

    cute_tensor = from_dlpack(torch_tensor, assumed_align=assumed_align)
    cute_tensor.element_type = cutlass_dtype

    leading_dim = next((i for i, s in enumerate(torch_tensor.stride()) if s == 1), None)
    cute_tensor = cute_tensor.mark_layout_dynamic(leading_dim=leading_dim)
    return cute_tensor, torch_tensor


def create_4_2_sparse_tensors(
    l: int,
    m: int,
    k: int,
    a_major: str,
    a_dtype: Type[cutlass.Numeric],
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    skip_ref_check: bool = False,
    run_on_cpu: Optional[bool] = None,
) -> Tuple:
    """Create 4:2 sparse tensors on CPU, with special handling for FP4 (Float4E2M1FN).

    For FP4 dtype, the function first creates sparse tensors in FP32, then recasts
    the A and A_compressed tensors to FP4 while keeping the reference tensors in FP32
    for numerical verification.

    For other dtypes, delegates directly to :func:`create_4_2_sparse_tensors_impl`.

    When ``skip_ref_check=True``, sparsification and metadata compression are skipped
    entirely: A / A_compressed / E are allocated directly via torch and zero-initialized.
    Use only for perf benchmarking where numerical correctness is not checked.

    :param l: Batch size
    :type l: int
    :param m: Number of rows in the tensor
    :type m: int
    :param k: Number of columns in the tensor
    :type k: int
    :param a_major: Memory layout major of tensor A, either "m" (row-major) or "k" (column-major)
    :type a_major: str
    :param a_dtype: Data type of tensor A elements
    :type a_dtype: Type[cutlass.Numeric]

    :return: Tuple of (a_tensor, a_compressed_tensor, a_ref, a_compressed_torch_cpu, e_tensor, e_torch_cpu)
             where a_tensor and a_compressed_tensor are CuTe tensors (FP4 for Float4E2M1FN, original dtype otherwise),
             a_ref and a_compressed_torch_cpu are FP32 torch tensors for reference,
             e_tensor is the CuTe metadata tensor, and e_torch_cpu is the torch metadata tensor
    :rtype: Tuple
    """
    if skip_ref_check:
        # All tensors live on GPU, zero-filled. Sparsification, metadata compression,
        # CPU allocation, and convert kernels are all skipped. Valid only for perf
        # benchmarking where numerical correctness is not checked.
        is_m_major = a_major == "m"

        def _shape_and_permute(mode0, mode1):
            shape = (l, mode1, mode0) if is_m_major else (l, mode0, mode1)
            permute = (2, 1, 0) if is_m_major else (1, 2, 0)
            return shape, permute

        shape_a, perm_a = _shape_and_permute(m, k)
        a_tensor_cute, a_torch = make_zero_cute_tensor_on_gpu(
            shape_a, perm_a, a_dtype, assumed_align=16
        )

        shape_ac, perm_ac = _shape_and_permute(m, k // 2)
        a_compressed_tensor_cute, a_compressed_torch = make_zero_cute_tensor_on_gpu(
            shape_ac, perm_ac, a_dtype, assumed_align=16
        )

        # Pad E metadata M and K to the kernel's E-atom alignment (128). The kernel's
        # make_sparse_gmem_layout_e (rubin_helpers.py) builds the E descriptor with
        # m_aligned_e = round_up(m, 128) and per-batch(L) stride m_aligned_e * k_aligned_e,
        # then imposes that layout on this buffer's pointer. A true-M allocation therefore
        # under-sizes the E buffer for M < 128, so batched (L > 1) E TMA loads overshoot the
        # allocation -> IMA (small-M x large-L). Allocate the buffer rounded (the scale-factor
        # tensors are already allocated rounded). The padding bytes stay 0xEE (the valid
        # num_nonzeros == 0 fallback) via the fill below, and the extra M rows are masked out
        # by the MMA, so the result is unchanged.
        _e_atom = 128
        m_e = ((m + _e_atom - 1) // _e_atom) * _e_atom
        k_e = ((k + _e_atom - 1) // _e_atom) * _e_atom
        shape_e, perm_e = _shape_and_permute(m_e, k_e // 8)
        e_cute_tensor, e_torch = make_zero_cute_tensor_on_gpu(
            shape_e, perm_e, cutlass.Uint8, assumed_align=16
        )
        # Each uint8 packs two 4-bit 2:4 metadata nibbles. 0x0 is not a valid
        # nibble — use 0xE (positions 2,3), which matches the num_nonzeros==0
        # fallback in _encode_chunk_metadata. Packed byte = 0xEE.
        e_torch.fill_(0xEE)

        return (
            a_tensor_cute,
            a_compressed_tensor_cute,
            a_torch,
            a_compressed_torch,
            e_cute_tensor,
            e_torch,
        )

    if a_dtype == cutlass.Float4E2M1FN:
        fp32_a_dtype = cutlass.Float32

        (
            fp32_a_cute,
            fp32_a_compressed_cute,
            fp32_a_torch_cpu,
            fp32_a_compressed_torch_cpu,
            e_cute_tensor,
            e_torch_cpu,
        ) = create_4_2_sparse_tensors_impl(
            l,
            m,
            k,
            a_major,
            fp32_a_dtype,
            init_normal=init_normal,
            normal_mean=normal_mean,
            normal_std=normal_std,
            run_on_cpu=run_on_cpu,
        )

        fp4_a_cute_tensor, _ = cutlass_torch.cute_tensor_like(
            fp32_a_torch_cpu,
            cutlass.Float4E2M1FN,
            is_dynamic_layout=True,
            assumed_align=16,
        )
        fp4_a_compressed_cute_tensor, _ = cutlass_torch.cute_tensor_like(
            fp32_a_compressed_torch_cpu,
            cutlass.Float4E2M1FN,
            is_dynamic_layout=True,
            assumed_align=16,
        )

        return (
            fp4_a_cute_tensor,
            fp4_a_compressed_cute_tensor,
            fp32_a_torch_cpu,
            fp32_a_compressed_torch_cpu,
            e_cute_tensor,
            e_torch_cpu,
        )

    return create_4_2_sparse_tensors_impl(
        l,
        m,
        k,
        a_major,
        a_dtype,
        init_normal=init_normal,
        normal_mean=normal_mean,
        normal_std=normal_std,
        run_on_cpu=run_on_cpu,
    )


def create_4_2_sparse_tensors_impl(
    l: int,
    m: int,
    k: int,
    a_major: str,
    a_dtype: Type[cutlass.Numeric],
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    run_on_cpu: Optional[bool] = None,
) -> Tuple:
    """Create sparse tensor A(M, K, L) tensor A_compressed(M, K//2, L) and metadata E(M, K//8, L).

    For 2:4 sparsity:
    - A is compressed: stores only non-zero values (50% of original size)
    - E is metadata (uint8): encodes which 2 of every 4 elements are non-zero
        Shape: (M, K//8, L) - each uint8 byte encodes 8 A elements (2 chunks of 4)
        Note: For FP16/BF16, metadata is automatically reordered to hierarchical layout

    Constraints:
    - K must be >= 8 and divisible by 8 (for metadata encoding)
    - For FP16/BF16: M and K must be divisible by 128 (for hierarchical metadata layout)
    """
    # Validate k for 2:4 sparsity
    if k < 8:
        raise ValueError(
            f"k must be at least 8 for 2:4 structured sparsity with metadata encoding, got k={k}"
        )
    if k % 8 != 0:
        raise ValueError(
            f"k should be divisible by 8 for 2:4 structured sparsity (metadata encoding requirement), got k={k}"
        )

    # For FP16/BF16, validate M and K divisibility by 128
    if a_dtype.width == 16:  # FP16 or BF16
        if m % 128 != 0:
            raise ValueError(
                f"For FP16/BF16, M must be divisible by 128 for hierarchical metadata layout, got m={m}"
            )
        if k % 128 != 0:
            raise ValueError(
                f"For FP16/BF16, K must be divisible by 128 for hierarchical metadata layout, got k={k}"
            )

    torch.manual_seed(1111)

    sparse_gen = SparseUtils(m, k, l, a_dtype)
    a_torch_cpu = cutlass_torch.matrix(
        l,
        m,
        k,
        a_major == "m",
        a_dtype,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(min_val=1, max_val=3),
    )

    # Override dense A values with a normal distribution (prior to sparsification)
    if init_normal:
        a_torch_cpu.normal_(mean=normal_mean, std=normal_std)

    # Select the CPU or GPU implementation.
    if run_on_cpu is None:
        run_on_cpu = not torch.cuda.is_available() or (m * k * l) < (1 << 24)

    a_torch_gpu = None
    if not run_on_cpu:
        a_torch_gpu = a_torch_cpu.cuda()

    # Apply 2:4 sparsity pattern
    if run_on_cpu:
        sparse_gen.generate_sparse_4_2_tensor_with_tensor(a_torch_cpu, run_on_cpu=True)
    else:
        sparse_gen.generate_sparse_4_2_tensor_with_tensor(a_torch_gpu, run_on_cpu=False)

    a_compressed_torch_cpu = cutlass_torch.matrix(
        l,
        m,
        k // 2,
        a_major == "m",
        a_dtype,
        init_type=cutlass_torch.TensorInitType.SKIP,
    )

    e_torch_cpu = cutlass_torch.matrix(
        l,
        m,
        k // 8,
        a_major == "m",
        cutlass.Uint8,
        init_type=cutlass_torch.TensorInitType.SKIP,
    )

    # Compress the sparse tensor
    if run_on_cpu:
        sparse_gen.compress(
            a_torch_cpu, a_compressed_torch_cpu, e_torch_cpu, run_on_cpu=True
        )
    else:
        a_compressed_torch_gpu = a_compressed_torch_cpu.cuda()
        e_torch_gpu = e_torch_cpu.cuda()
        sparse_gen.compress(
            a_torch_gpu, a_compressed_torch_gpu, e_torch_gpu, run_on_cpu=False
        )
        torch.cuda.synchronize()

        a_torch_cpu.copy_(a_torch_gpu)
        a_compressed_torch_cpu.copy_(a_compressed_torch_gpu)
        e_torch_cpu.copy_(e_torch_gpu)

        del a_torch_gpu, a_compressed_torch_gpu, e_torch_gpu

    # Create the device-backed tensor after compression so E data is current.
    e_cute_tensor, e_torch_gpu = cutlass_torch.cute_tensor_like(
        e_torch_cpu, cutlass.Uint8, is_dynamic_layout=True, assumed_align=16
    )

    # Convert to CUTE tensors
    a_tensor_cute, _ = cutlass_torch.cute_tensor_like(
        a_torch_cpu, a_dtype, is_dynamic_layout=True, assumed_align=16
    )
    a_compressed_tensor_cute, _ = cutlass_torch.cute_tensor_like(
        a_compressed_torch_cpu, a_dtype, is_dynamic_layout=True, assumed_align=16
    )

    return (
        a_tensor_cute,
        a_compressed_tensor_cute,
        a_torch_cpu,
        a_compressed_torch_cpu,
        e_cute_tensor,
        e_torch_cpu,
    )


def create_1_2_sparse_tensors(
    l: int,
    m: int,
    k: int,
    a_major: str,
    a_dtype: Type[cutlass.Numeric],
    run_on_cpu: Optional[bool] = None,
) -> Tuple:
    """Create sparse tensor A(M, K, L), A_compressed(M, K//2, L) and metadata
    E(M, K//4, L) for TF32 1:2 sparsity.

    :param l: Batch size
    :type l: int
    :param m: Number of rows in A; must be divisible by 128
    :type m: int
    :param k: Number of columns in A; must be divisible by 64, the K extent of
        the metadata atom
    :type k: int
    :param a_major: Memory layout of A, either ``"m"`` or ``"k"``
    :type a_major: str
    :param a_dtype: Element type of A; must be a 32-bit type
        (e.g. :class:`cutlass.TFloat32` or :class:`cutlass.Float32`)
    :type a_dtype: Type[cutlass.Numeric]
    :param run_on_cpu: True for compression on the CPU, False for compression on the GPU
    :type run_on_cpu: Optional[bool]

    :return: Tuple of ``(a_tensor_cute, a_compressed_tensor_cute, a_torch_cpu,
        a_compressed_torch_cpu, e_tensor_cute, e_torch_cpu)``
    :rtype: Tuple

    :raises ValueError: if ``a_dtype`` is not 32-bit, or if the shape
        constraints for 1:2 structured sparsity are not satisfied.
    """
    if a_dtype.width != 32:
        raise ValueError(
            f"TF32 1:2 sparsity expects a 32-bit A dtype (TFloat32/Float32), "
            f"got {a_dtype} with width {a_dtype.width}"
        )
    if m % 128 != 0:
        raise ValueError(f"TF32 1:2 TMEM layout requires M % 128 == 0, got m={m}")
    if k % 64 != 0:
        raise ValueError(f"TF32 1:2 TMEM atom layout requires K % 64 == 0, got k={k}")

    torch.manual_seed(1111)

    sparse_gen = SparseUtils(m, k, l, a_dtype)
    a_torch_cpu = cutlass_torch.matrix(
        l,
        m,
        k,
        a_major == "m",
        a_dtype,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(min_val=1, max_val=3),
    )

    sparse_gen.apply_1_2_sparsity_cpu(a_torch_cpu)

    # Select the CPU or GPU implementation.
    if run_on_cpu is None:
        run_on_cpu = not torch.cuda.is_available()

    a_compressed_torch_cpu = cutlass_torch.matrix(
        l,
        m,
        k // 2,
        a_major == "m",
        a_dtype,
        init_type=cutlass_torch.TensorInitType.SKIP,
    )

    e_torch_cpu = cutlass_torch.matrix(
        l,
        m,
        k // 4,
        False,  # is_mode0_major
        cutlass.Uint8,
        init_type=cutlass_torch.TensorInitType.SKIP,
    )

    # Compress the sparse tensor
    if run_on_cpu:
        sparse_gen.compress(
            a_torch_cpu,
            a_compressed_torch_cpu,
            e_torch_cpu,
            run_on_cpu=True,
            e_layout=E_LAYOUT_TF32_1_2_TMEM,
        )
    else:
        a_torch_gpu = a_torch_cpu.cuda()
        a_compressed_torch_gpu = a_compressed_torch_cpu.cuda()
        e_torch_gpu = e_torch_cpu.cuda()
        sparse_gen.compress(
            a_torch_gpu,
            a_compressed_torch_gpu,
            e_torch_gpu,
            run_on_cpu=False,
            e_layout=E_LAYOUT_TF32_1_2_TMEM,
        )
        torch.cuda.synchronize()

        # A is not copied back: it was sparsified on the host and the device
        # copy is read-only to the compressor.
        a_compressed_torch_cpu.copy_(a_compressed_torch_gpu)
        e_torch_cpu.copy_(e_torch_gpu)

        del a_torch_gpu, a_compressed_torch_gpu, e_torch_gpu

    e_cute_tensor, _ = cutlass_torch.cute_tensor_like(
        e_torch_cpu, cutlass.Uint8, is_dynamic_layout=True, assumed_align=16
    )

    a_tensor_cute, _ = cutlass_torch.cute_tensor_like(
        a_torch_cpu, a_dtype, is_dynamic_layout=True, assumed_align=16
    )
    a_compressed_tensor_cute, _ = cutlass_torch.cute_tensor_like(
        a_compressed_torch_cpu, a_dtype, is_dynamic_layout=True, assumed_align=16
    )

    return (
        a_tensor_cute,
        a_compressed_tensor_cute,
        a_torch_cpu,
        a_compressed_torch_cpu,
        e_cute_tensor,
        e_torch_cpu,
    )
