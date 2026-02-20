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

import argparse
from types import SimpleNamespace
from typing import Type, Callable

import torch
import cuda.bindings.driver as cuda
import cutlass.cute.testing as testing
import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import cpasync, warp
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import from_dlpack
import cutlass.pipeline as pipeline
import cutlass.utils as utils


"""
A flash attention v2 forward pass example for NVIDIA Blackwell GeForce SM120 architecture
(RTX 5090, GB10 / DGX Spark) using CUTE DSL.

- Matrix Q is BxSqxNxH, B is batch, Sq is query sequence length, N is heads, H is head dim
- Matrix K is BxSkxNxH, B is batch, Sk is key sequence length, N is heads, H is head dim
- Matrix V is BxSkxNxH, B is batch, Sk is key sequence length, N is heads, H is head dim
- Matrix O is BxSqxNxH, B is batch, Sq is query sequence length, N is heads, H is head dim

SM120 Architecture Notes:
    - Supports SM80-era `mma.sync.aligned.m16n8k16` tensor core instructions for FP16/BF16
    - Supports CpAsync (cp.async) for asynchronous global → shared memory copies
    - Supports TMA (cp.async.bulk) for bulk memory transfers (used in GEMM, future FA opt)
    - Does NOT support tcgen05 MMA (datacenter Blackwell SM100 only)
    - Does NOT support TMA multicast (single-CTA copies only)
    - Has 101 KB shared memory per SM (vs 164 KB for SM80, 228 KB for SM90)

This kernel leverages:
    - CpAsync for efficient global → shared memory transfers
    - SM80-compatible tensor cores for MMA operations
    - Online softmax fusion following the Flash Attention v2 algorithm
    - Register pipeline to overlap shared memory-to-register transfers with computation

To run this example:

.. code-block:: bash

    python examples/blackwell_geforce/flash_attention_v2.py                        \\
      --dtype Float16 --head_dim 128 --m_block_size 128 --n_block_size 128         \\
      --num_threads 128 --batch_size 1 --seqlen_q 1024 --seqlen_k 1024            \\
      --num_head 16 --softmax_scale 1.0 --is_causal

Constraints:
* Only fp16 and bf16 data types are supported.
* The contiguous dimension of each tensor must be at least 16 bytes aligned.
* The log-sum-exp (for training) is not computed in the kernel.
* `m_block_size`, `n_block_size`, and `head_dim` must fit within SM120 shared memory.
* `m_block_size * 2` must be divisible by `num_threads`.
"""


class FlashAttentionForwardSm120:
    def __init__(
        self,
        head_dim: int,
        m_block_size: int = 128,
        n_block_size: int = 128,
        num_threads: int = 128,
        is_causal: bool = False,
    ):
        """Initializes the configuration for an SM120 flash attention v2 kernel.

        :param head_dim: head dimension
        :type head_dim: int
        :param m_block_size: m block size (query tile rows)
        :type m_block_size: int
        :param n_block_size: n block size (key/value tile rows)
        :type n_block_size: int
        :param num_threads: number of threads per CTA
        :type num_threads: int
        :param is_causal: enable causal masking
        :type is_causal: bool
        """
        self._head_dim = head_dim
        self._m_block_size = m_block_size
        self._n_block_size = n_block_size
        # Pad head_dim to a multiple of 32 for MMA alignment
        self._head_dim_padded = (head_dim + 31) // 32 * 32
        self._num_threads = num_threads
        self._is_causal = is_causal

        self.cta_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1, num_threads=num_threads
        )

    @staticmethod
    def can_implement(
        dtype, head_dim, m_block_size, n_block_size, num_threads, is_causal
    ) -> bool:
        """Check if the kernel can be implemented with the given parameters."""
        if dtype != cutlass.Float16 and dtype != cutlass.BFloat16:
            return False
        if head_dim % 8 != 0:
            return False
        if num_threads % 32 != 0:
            return False
        # SM120 shared memory capacity check
        smem_usage = (m_block_size * head_dim + n_block_size * head_dim * 2) * 2
        smem_capacity = utils.get_smem_capacity_in_bytes("sm_120")
        if smem_usage > smem_capacity:
            return False
        if (m_block_size * 2) % num_threads != 0:
            return False
        return True

    @cute.jit
    def __call__(
        self,
        mQ: cute.Tensor,
        mK: cute.Tensor,
        mV: cute.Tensor,
        mO: cute.Tensor,
        softmax_scale: cutlass.Float32,
        stream: cuda.CUstream,
    ):
        """Configures and launches the SM120 flash attention v2 kernel.

        mQ/mK/mV/mO layout: (batch_size, seqlen, num_head, head_dim)
        """
        if cutlass.const_expr(
            not (
                mQ.element_type == mK.element_type == mV.element_type == mO.element_type
            )
        ):
            raise TypeError("All tensors must have the same data type")
        if cutlass.const_expr(
            not (
                mQ.element_type == cutlass.Float16
                or mQ.element_type == cutlass.BFloat16
            )
        ):
            raise TypeError("Only Float16 or BFloat16 is supported")
        self._dtype: Type[cutlass.Numeric] = mQ.element_type

        # ///////////////////////////////////////////////////////////////////////////////
        # Shared memory layout: Q/K/V (swizzled for bank conflict avoidance)
        # ///////////////////////////////////////////////////////////////////////////////
        smem_k_block_size = 64 if self._head_dim_padded % 64 == 0 else 32
        swizzle_bits = 3 if smem_k_block_size == 64 else 2
        sQ_layout_atom = cute.make_composed_layout(
            cute.make_swizzle(swizzle_bits, 3, 3),
            0,
            cute.make_layout((8, smem_k_block_size), stride=(smem_k_block_size, 1)),
        )
        sQ_layout = cute.tile_to_shape(
            sQ_layout_atom,
            (self._m_block_size, self._head_dim_padded),
            (0, 1),
        )
        sKV_layout_atom = sQ_layout_atom
        sKV_layout = cute.tile_to_shape(
            sKV_layout_atom,
            (self._n_block_size, self._head_dim_padded),
            (0, 1),
        )
        sO_layout = sQ_layout

        @cute.struct
        class SharedStorage:
            sQ: cute.struct.Align[
                cute.struct.MemRange[self._dtype, cute.cosize(sQ_layout)], 1024
            ]
            sK: cute.struct.Align[
                cute.struct.MemRange[self._dtype, cute.cosize(sKV_layout)], 1024
            ]
            sV: cute.struct.Align[
                cute.struct.MemRange[self._dtype, cute.cosize(sKV_layout)], 1024
            ]

        # ///////////////////////////////////////////////////////////////////////////////
        # GMEM Tiled copy: CpAsync for QKV load, Universal for O store
        # ///////////////////////////////////////////////////////////////////////////////
        universal_copy_bits = 128
        async_copy_elems = universal_copy_bits // self._dtype.width
        atom_async_copy = cute.make_copy_atom(
            cpasync.CopyG2SOp(cache_mode=cpasync.LoadCacheMode.GLOBAL),
            self._dtype,
            num_bits_per_copy=universal_copy_bits,
        )
        atom_universal_copy = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            self._dtype,
            num_bits_per_copy=universal_copy_bits,
        )
        tQKV_shape_dim_1 = sQ_layout_atom.outer.shape[1] // async_copy_elems
        tQKV_layout = cute.make_layout(
            (self._num_threads // tQKV_shape_dim_1, tQKV_shape_dim_1),
            stride=(tQKV_shape_dim_1, 1),
        )
        tO_layout = tQKV_layout
        vQKV_layout = cute.make_layout((1, async_copy_elems))
        vO_layout = vQKV_layout

        gmem_tiled_copy_QKV = cute.make_tiled_copy_tv(
            atom_async_copy, tQKV_layout, vQKV_layout
        )
        gmem_tiled_copy_O = cute.make_tiled_copy_tv(
            atom_universal_copy, tO_layout, vO_layout
        )

        # ///////////////////////////////////////////////////////////////////////////////
        # Tiled MMA — SM80-compatible tensor core ops (supported on SM120)
        # ///////////////////////////////////////////////////////////////////////////////
        tiled_mma = cute.make_tiled_mma(
            warp.MmaF16BF16Op(self._dtype, cutlass.Float32, (16, 8, 16)),
            (self._num_threads // 32, 1, 1),
            permutation_mnk=(self._num_threads // 32 * 16, 16, 16),
        )

        grid_dim = (
            cute.ceil_div(mQ.shape[1], self._m_block_size),
            cute.size(mQ.shape[0]),
            cute.size(mQ.shape[2]),
        )
        LOG2_E = 1.4426950408889634074
        softmax_scale_log2 = softmax_scale * LOG2_E
        self.kernel(
            mQ,
            mK,
            mV,
            mO,
            softmax_scale_log2,
            sQ_layout,
            sKV_layout,
            sO_layout,
            gmem_tiled_copy_QKV,
            gmem_tiled_copy_O,
            tiled_mma,
            SharedStorage,
        ).launch(
            grid=grid_dim,
            block=[self._num_threads, 1, 1],
            stream=stream,
        )

    @cute.kernel
    def kernel(
        self,
        mQ: cute.Tensor,
        mK: cute.Tensor,
        mV: cute.Tensor,
        mO: cute.Tensor,
        softmax_scale_log2: cutlass.Float32,
        sQ_layout: cute.ComposedLayout,
        sKV_layout: cute.ComposedLayout,
        sO_layout: cute.ComposedLayout,
        gmem_tiled_copy_QKV: cute.TiledCopy,
        gmem_tiled_copy_O: cute.TiledCopy,
        tiled_mma: cute.TiledMma,
        SharedStorage: cutlass.Constexpr,
    ):
        """SM120 flash attention v2 kernel.

        Uses CpAsync for global→shared loads, SM80-compatible tensor core
        MMA for computation, and online softmax for numerical stability.
        """
        tidx, _, _ = cute.arch.thread_idx()
        m_block, batch_size, num_head = cute.arch.block_idx()

        n_block_max = cute.ceil_div(mK.shape[1], self._n_block_size)
        if self._is_causal:
            n_block_max = min(
                cute.ceil_div(
                    (m_block + 1) * self._m_block_size,
                    self._n_block_size,
                ),
                n_block_max,
            )
        n_block = n_block_max - 1

        # ///////////////////////////////////////////////////////////////////////////////
        # Get tiles for this thread block
        # ///////////////////////////////////////////////////////////////////////////////
        gQ = cute.local_tile(
            mQ[batch_size, None, num_head, None],
            (self._m_block_size, self._head_dim_padded),
            (m_block, 0),
        )
        gK = cute.local_tile(
            mK[batch_size, None, num_head, None],
            (self._n_block_size, self._head_dim_padded),
            (None, 0),
        )
        gV = cute.local_tile(
            mV[batch_size, None, num_head, None],
            (self._n_block_size, self._head_dim_padded),
            (None, 0),
        )

        # ///////////////////////////////////////////////////////////////////////////////
        # Get shared memory
        # ///////////////////////////////////////////////////////////////////////////////
        smem = cutlass.utils.SmemAllocator()
        storage = smem.allocate(SharedStorage)
        sQ = storage.sQ.get_tensor(sQ_layout)
        sK = storage.sK.get_tensor(sKV_layout)
        sV = storage.sV.get_tensor(sKV_layout)

        sVt = cute.composition(
            sV,
            cute.make_layout(
                (self._head_dim_padded, self._n_block_size),
                stride=(self._n_block_size, 1),
            ),
        )

        gmem_thr_copy_QKV = gmem_tiled_copy_QKV.get_slice(tidx)
        tQgQ = gmem_thr_copy_QKV.partition_S(gQ)
        tQsQ = gmem_thr_copy_QKV.partition_D(sQ)
        tKgK = gmem_thr_copy_QKV.partition_S(gK)
        tKsK = gmem_thr_copy_QKV.partition_D(sK)
        tVgV = gmem_thr_copy_QKV.partition_S(gV)
        tVsV = gmem_thr_copy_QKV.partition_D(sV)

        # ///////////////////////////////////////////////////////////////////////////////
        # MMA compute partitions and accumulators
        # ///////////////////////////////////////////////////////////////////////////////
        thr_mma = tiled_mma.get_slice(tidx)
        tSrQ = thr_mma.make_fragment_A(thr_mma.partition_A(sQ))
        tSrK = thr_mma.make_fragment_B(thr_mma.partition_B(sK))
        tOrVt = thr_mma.make_fragment_B(thr_mma.partition_B(sVt))
        acc_shape_O = thr_mma.partition_shape_C(
            (self._m_block_size, self._head_dim_padded)
        )
        acc_O = cute.make_rmem_tensor(acc_shape_O, cutlass.Float32)
        acc_O.fill(0.0)

        # ///////////////////////////////////////////////////////////////////////////////
        # Smem copy atoms (LdMatrix: shared → register)
        # ///////////////////////////////////////////////////////////////////////////////
        smem_copy_atom_Q = cute.make_copy_atom(
            warp.LdMatrix8x8x16bOp(transpose=False, num_matrices=4),
            self._dtype,
        )
        smem_copy_atom_K = cute.make_copy_atom(
            warp.LdMatrix8x8x16bOp(transpose=False, num_matrices=4),
            self._dtype,
        )
        smem_copy_atom_V = cute.make_copy_atom(
            warp.LdMatrix8x8x16bOp(transpose=True, num_matrices=4),
            self._dtype,
        )
        smem_tiled_copy_Q = cute.make_tiled_copy_A(smem_copy_atom_Q, tiled_mma)
        smem_tiled_copy_K = cute.make_tiled_copy_B(smem_copy_atom_K, tiled_mma)
        smem_tiled_copy_V = cute.make_tiled_copy_B(smem_copy_atom_V, tiled_mma)

        smem_thr_copy_Q = smem_tiled_copy_Q.get_slice(tidx)
        smem_thr_copy_K = smem_tiled_copy_K.get_slice(tidx)
        smem_thr_copy_V = smem_tiled_copy_V.get_slice(tidx)

        tSsQ = smem_thr_copy_Q.partition_S(sQ)
        tSrQ_copy_view = smem_thr_copy_Q.retile(tSrQ)
        tSsK = smem_thr_copy_K.partition_S(sK)
        tSrK_copy_view = smem_thr_copy_K.retile(tSrK)
        tOsVt = smem_thr_copy_V.partition_S(sVt)
        tOrVt_copy_view = smem_thr_copy_V.retile(tOrVt)

        # ///////////////////////////////////////////////////////////////////////////////
        # Predicates for out-of-bounds handling
        # ///////////////////////////////////////////////////////////////////////////////
        mcQ = cute.make_identity_tensor(mQ.layout.shape)
        mcKV = cute.make_identity_tensor(mK.layout.shape)
        cQ = cute.local_tile(
            mcQ[batch_size, None, num_head, None],
            (self._m_block_size, self._head_dim_padded),
            (m_block, 0),
        )
        cKV = cute.local_tile(
            mcKV[batch_size, None, num_head, None],
            (self._n_block_size, self._head_dim_padded),
            (n_block, 0),
        )
        tQcQ = gmem_thr_copy_QKV.partition_S(cQ)
        tKVcKV = gmem_thr_copy_QKV.partition_S(cKV)
        tQpQ = cute.make_rmem_tensor(
            cute.make_layout(
                (tQsQ.shape[0][1], cute.size(tQsQ, mode=[1]), cute.size(tQsQ, mode=[2])),
                stride=(cute.size(tQsQ, mode=[2]), 0, 1),
            ),
            cutlass.Boolean,
        )
        tKVpKV = cute.make_rmem_tensor(
            cute.make_layout(
                (tKsK.shape[0][1], cute.size(tKsK, mode=[1]), cute.size(tKsK, mode=[2])),
                stride=(cute.size(tKsK, mode=[2]), 0, 1),
            ),
            cutlass.Boolean,
        )
        for rest_v in cutlass.range_constexpr(tQpQ.shape[0]):
            for rest_k in cutlass.range_constexpr(tQpQ.shape[2]):
                tQpQ[rest_v, 0, rest_k] = cute.elem_less(
                    tQcQ[(0, rest_v), 0, rest_k][3], mQ.layout.shape[3]
                )
        for rest_v in cutlass.range_constexpr(tKVpKV.shape[0]):
            for rest_k in cutlass.range_constexpr(tKVpKV.shape[2]):
                tKVpKV[rest_v, 0, rest_k] = cute.elem_less(
                    tKVcKV[(0, rest_v), 0, rest_k][3], mK.layout.shape[3]
                )

        # ///////////////////////////////////////////////////////////////////////////////
        # Prologue: async load Q and first K tile
        # ///////////////////////////////////////////////////////////////////////////////
        for m in cutlass.range_constexpr(cute.size(tQsQ.shape[1])):
            if cute.elem_less(tQcQ[0, m, 0][1], mQ.layout.shape[1]):
                cute.copy(
                    gmem_tiled_copy_QKV,
                    tQgQ[None, m, None],
                    tQsQ[None, m, None],
                    pred=tQpQ[None, m, None],
                )
            else:
                tQsQ[None, m, None].fill(0)
        for n in cutlass.range_constexpr(cute.size(tKsK.shape[1])):
            if cute.elem_less(tKVcKV[0, n, 0][1], mK.layout.shape[1]):
                cute.copy(
                    gmem_tiled_copy_QKV,
                    tKgK[None, n, None, n_block],
                    tKsK[None, n, None],
                    pred=tKVpKV[None, n, None],
                )
            else:
                tKsK[None, n, None].fill(0)

        cute.arch.cp_async_commit_group()

        # ///////////////////////////////////////////////////////////////////////////////
        # Softmax intermediate results
        # ///////////////////////////////////////////////////////////////////////////////
        row_max = cute.make_rmem_tensor(
            (acc_O.shape[0][0] * acc_O.shape[1]), cutlass.Float32
        )
        row_sum = cute.make_rmem_tensor(
            (acc_O.shape[0][0] * acc_O.shape[1]), cutlass.Float32
        )
        row_max.fill(-cutlass.Float32.inf)
        row_sum.fill(0.0)

        basic_params = SimpleNamespace(
            m_block=m_block, n_block=n_block, mQ=mQ, mK=mK,
            batch_size=batch_size, num_head=num_head,
        )
        mma_params = SimpleNamespace(
            thr_mma=thr_mma, tiled_mma=tiled_mma,
            tSrQ=tSrQ, tSrK=tSrK, tOrVt=tOrVt, acc_O=acc_O,
        )
        gmem_copy_params = SimpleNamespace(
            gmem_tiled_copy_QKV=gmem_tiled_copy_QKV,
            tKVcKV=tKVcKV,
            tKgK=tKgK, tKsK=tKsK,
            tVgV=tVgV, tVsV=tVsV,
            tKVpKV=tKVpKV,
        )
        smem_copy_params = SimpleNamespace(
            smem_tiled_copy_Q=smem_tiled_copy_Q,
            smem_tiled_copy_K=smem_tiled_copy_K,
            smem_tiled_copy_V=smem_tiled_copy_V,
            tSsQ=tSsQ, tSrQ_copy_view=tSrQ_copy_view,
            tSsK=tSsK, tSrK_copy_view=tSrK_copy_view,
            tOsVt=tOsVt, tOrVt_copy_view=tOrVt_copy_view,
        )
        softmax_params = SimpleNamespace(
            row_max=row_max, row_sum=row_sum,
            softmax_scale_log2=softmax_scale_log2,
        )

        # ///////////////////////////////////////////////////////////////////////////////
        # Main attention loop
        # ///////////////////////////////////////////////////////////////////////////////
        mask_steps = 1
        if cutlass.const_expr(self._is_causal):
            mask_steps = cute.ceil_div(self._m_block_size, self._n_block_size)

        for n_tile in cutlass.range_constexpr(mask_steps):
            n_block = n_block_max - n_tile - 1
            basic_params.n_block = n_block
            if cutlass.const_expr(self._is_causal):
                if n_block >= 0:
                    self.compute_one_n_block(
                        basic_params, mma_params, gmem_copy_params,
                        smem_copy_params, softmax_params,
                        is_first_n_block=(n_tile == 0), in_mask_steps=True,
                    )
            else:
                self.compute_one_n_block(
                    basic_params, mma_params, gmem_copy_params,
                    smem_copy_params, softmax_params,
                    is_first_n_block=True, in_mask_steps=True,
                )

        for n_tile in range(mask_steps, n_block_max, 1):
            n_block = n_block_max - n_tile - 1
            basic_params.n_block = n_block
            self.compute_one_n_block(
                basic_params, mma_params, gmem_copy_params,
                smem_copy_params, softmax_params,
                is_first_n_block=False, in_mask_steps=False,
            )

        # ///////////////////////////////////////////////////////////////////////////////
        # Epilogue: normalize and store O
        # ///////////////////////////////////////////////////////////////////////////////
        self.normalize_softmax(acc_O, row_sum)
        rO = cute.make_fragment_like(acc_O, self._dtype)
        rO.store(acc_O.load().to(self._dtype))
        sO = cute.make_tensor(sQ.iterator, sO_layout)

        smem_copy_atom_O = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), self._dtype
        )
        smem_tiled_copy_O = cute.make_tiled_copy_C(smem_copy_atom_O, tiled_mma)
        smem_thr_copy_O = smem_tiled_copy_O.get_slice(tidx)
        taccOrO = smem_thr_copy_O.retile(rO)
        taccOsO = smem_thr_copy_O.partition_D(sO)
        cute.copy(smem_copy_atom_O, taccOrO, taccOsO)

        gO = cute.local_tile(
            mO[batch_size, None, num_head, None],
            (self._m_block_size, self._head_dim_padded),
            (m_block, 0),
        )
        gmem_thr_copy_O = gmem_tiled_copy_O.get_slice(tidx)
        tOsO = gmem_thr_copy_O.partition_S(sO)
        tOgO = gmem_thr_copy_O.partition_D(gO)
        tOrO = cute.make_fragment_like(tOgO, self._dtype)
        self.cta_sync_barrier.arrive_and_wait()
        cute.copy(gmem_tiled_copy_O, tOsO, tOrO)

        mcO = cute.make_identity_tensor(mO.layout.shape)
        cO = cute.local_tile(
            mcO[batch_size, None, num_head, None],
            (self._m_block_size, self._head_dim_padded),
            (m_block, 0),
        )
        tOcO = gmem_thr_copy_O.partition_D(cO)
        tOpO = cute.make_rmem_tensor(
            cute.make_layout(
                (tOgO.shape[0][1], tOgO.shape[1], tOgO.shape[2]),
                stride=(tOgO.shape[2], 0, 1),
            ),
            cutlass.Boolean,
        )
        for rest_v in cutlass.range_constexpr(tOpO.shape[0]):
            for rest_n in cutlass.range_constexpr(cute.size(tOpO.shape[2])):
                tOpO[rest_v, 0, rest_n] = cute.elem_less(
                    tOcO[(0, rest_v), 0, rest_n][3], mO.layout.shape[3]
                )
        for rest_m in cutlass.range_constexpr(cute.size(tOpO.shape[1])):
            if cute.elem_less(tOcO[0, rest_m, 0][1], mO.layout.shape[1]):
                cute.copy(
                    gmem_tiled_copy_O,
                    tOrO[None, rest_m, None],
                    tOgO[None, rest_m, None],
                    pred=tOpO[None, rest_m, None],
                )

    @cute.jit
    def compute_one_n_block(
        self,
        basic_params: SimpleNamespace,
        mma_params: SimpleNamespace,
        gmem_copy_params: SimpleNamespace,
        smem_copy_params: SimpleNamespace,
        softmax_params: SimpleNamespace,
        is_first_n_block: cutlass.Constexpr,
        in_mask_steps: cutlass.Constexpr,
    ):
        """Compute one n_block of S/O."""
        acc_shape_S = mma_params.thr_mma.partition_shape_C(
            (self._m_block_size, self._n_block_size)
        )
        acc_S = cute.make_rmem_tensor(acc_shape_S, cutlass.Float32)
        acc_S.fill(0.0)

        # Wait for QK smem tiles
        cute.arch.cp_async_wait_group(0)
        self.cta_sync_barrier.arrive_and_wait()

        # Load V (overlap with S computation)
        if is_first_n_block:
            for n in cutlass.range_constexpr(cute.size(gmem_copy_params.tVsV.shape[1])):
                if cute.elem_less(
                    gmem_copy_params.tKVcKV[0, n, 0][1],
                    basic_params.mK.layout.shape[1],
                ):
                    cute.copy(
                        gmem_copy_params.gmem_tiled_copy_QKV,
                        gmem_copy_params.tVgV[None, n, None, basic_params.n_block],
                        gmem_copy_params.tVsV[None, n, None],
                        pred=gmem_copy_params.tKVpKV[None, n, None],
                    )
                else:
                    gmem_copy_params.tVsV[None, n, None].fill(0.0)
        else:
            cute.copy(
                gmem_copy_params.gmem_tiled_copy_QKV,
                gmem_copy_params.tVgV[None, None, None, basic_params.n_block],
                gmem_copy_params.tVsV,
                pred=gmem_copy_params.tKVpKV,
            )

        cute.arch.cp_async_commit_group()

        # ///////////////////////////////////////////////////////////////////////////////
        # S = Q * K^T
        # ///////////////////////////////////////////////////////////////////////////////
        cute.copy(
            smem_copy_params.smem_tiled_copy_Q,
            smem_copy_params.tSsQ[None, None, 0],
            smem_copy_params.tSrQ_copy_view[None, None, 0],
        )
        cute.copy(
            smem_copy_params.smem_tiled_copy_K,
            smem_copy_params.tSsK[None, None, 0],
            smem_copy_params.tSrK_copy_view[None, None, 0],
        )
        for k in cutlass.range_constexpr(cute.size(smem_copy_params.tSsQ.shape[2])):
            k_next = (k + 1) % cute.size(smem_copy_params.tSsQ.shape[2])
            cute.copy(
                smem_copy_params.smem_tiled_copy_Q,
                smem_copy_params.tSsQ[None, None, k_next],
                smem_copy_params.tSrQ_copy_view[None, None, k_next],
            )
            cute.copy(
                smem_copy_params.smem_tiled_copy_K,
                smem_copy_params.tSsK[None, None, k_next],
                smem_copy_params.tSrK_copy_view[None, None, k_next],
            )
            cute.gemm(
                mma_params.tiled_mma, acc_S,
                mma_params.tSrQ[None, None, k],
                mma_params.tSrK[None, None, k],
                acc_S,
            )

        # Wait for V
        cute.arch.cp_async_wait_group(0)
        self.cta_sync_barrier.arrive_and_wait()

        # Prefetch next K
        if basic_params.n_block > 0:
            cute.copy(
                gmem_copy_params.gmem_tiled_copy_QKV,
                gmem_copy_params.tKgK[None, None, None, basic_params.n_block - 1],
                gmem_copy_params.tKsK,
                pred=gmem_copy_params.tKVpKV,
            )
            cute.arch.cp_async_commit_group()

        # ///////////////////////////////////////////////////////////////////////////////
        # Online softmax
        # ///////////////////////////////////////////////////////////////////////////////
        self.softmax_rescale_O(
            basic_params, mma_params, softmax_params, acc_S,
            is_first_n_block, in_mask_steps,
        )

        rP = cute.make_fragment_like(acc_S, self._dtype)
        rP.store(acc_S.load().to(self._dtype))

        # ///////////////////////////////////////////////////////////////////////////////
        # O += P * V
        # ///////////////////////////////////////////////////////////////////////////////
        rP_layout_divided = cute.logical_divide(rP.layout, (None, None, 2))
        rP_mma_view = cute.make_layout(
            (
                (rP_layout_divided.shape[0], rP_layout_divided.shape[2][0]),
                rP_layout_divided.shape[1],
                rP_layout_divided.shape[2][1],
            ),
            stride=(
                (rP_layout_divided.stride[0], rP_layout_divided.stride[2][0]),
                rP_layout_divided.stride[1],
                rP_layout_divided.stride[2][1],
            ),
        )
        tOrS = cute.make_tensor(rP.iterator, rP_mma_view)

        cute.copy(
            smem_copy_params.smem_tiled_copy_V,
            smem_copy_params.tOsVt[None, None, 0],
            smem_copy_params.tOrVt_copy_view[None, None, 0],
        )
        for k in cutlass.range_constexpr(cute.size(tOrS.shape[2])):
            k_next = (k + 1) % cute.size(tOrS.shape[2])
            cute.copy(
                smem_copy_params.smem_tiled_copy_V,
                smem_copy_params.tOsVt[None, None, k_next],
                smem_copy_params.tOrVt_copy_view[None, None, k_next],
            )
            cute.gemm(
                mma_params.tiled_mma, mma_params.acc_O,
                tOrS[None, None, k],
                mma_params.tOrVt[None, None, k],
                mma_params.acc_O,
            )

    @cute.jit
    def softmax_rescale_O(
        self,
        basic_params: SimpleNamespace,
        mma_params: SimpleNamespace,
        softmax_params: SimpleNamespace,
        acc_S: cute.Tensor,
        is_first_n_block: cutlass.Constexpr,
        in_mask_steps: cutlass.Constexpr,
    ):
        """Apply online softmax and rescale acc_O."""
        acc_S_mn = self._make_acc_tensor_mn_view(acc_S)
        acc_O_mn = self._make_acc_tensor_mn_view(mma_params.acc_O)
        row_max_prev = None
        if cutlass.const_expr(not is_first_n_block):
            row_max_prev = cute.make_fragment_like(
                softmax_params.row_max, cutlass.Float32
            )
            cute.basic_copy(softmax_params.row_max, row_max_prev)

        tScS_mn = None
        if cutlass.const_expr(in_mask_steps):
            mcS = cute.make_identity_tensor((
                basic_params.mQ.shape[0], basic_params.mQ.shape[1],
                basic_params.mQ.shape[2], basic_params.mK.shape[1],
            ))
            cS = cute.local_tile(
                mcS[basic_params.batch_size, None, basic_params.num_head, None],
                (self._m_block_size, self._n_block_size),
                (basic_params.m_block, basic_params.n_block),
            )
            tScS = mma_params.thr_mma.partition_C(cS)
            tScS_mn = self._make_acc_tensor_mn_view(tScS)

        for r in cutlass.range_constexpr(cute.size(softmax_params.row_max)):
            if cutlass.const_expr(in_mask_steps):
                if cutlass.const_expr(not self._is_causal):
                    for c in cutlass.range_constexpr(cute.size(tScS_mn.shape[1])):
                        if cute.elem_less(
                            basic_params.mK.shape[1], tScS_mn[0, c][3] + 1
                        ):
                            acc_S_mn[r, c] = -cutlass.Float32.inf
                else:
                    col_idx_limit = cutlass.min(
                        tScS_mn[r, 0][1] + 1, basic_params.mK.shape[1]
                    )
                    for c in cutlass.range_constexpr(cute.size(tScS_mn.shape[1])):
                        if cute.elem_less(col_idx_limit, tScS_mn[0, c][3] + 1):
                            acc_S_mn[r, c] = -cutlass.Float32.inf

            acc_S_row = acc_S_mn[r, None].load()
            row_max_cur_row = acc_S_row.reduce(
                cute.ReductionOp.MAX, -cutlass.Float32.inf, 0
            )
            row_max_cur_row = self._threadquad_reduce_max(row_max_cur_row)
            row_max_prev_row = None
            if cutlass.const_expr(not is_first_n_block):
                row_max_prev_row = row_max_prev[r]
                row_max_cur_row = cute.arch.fmax(row_max_prev_row, row_max_cur_row)
            if cutlass.const_expr(self._is_causal):
                row_max_cur_row = (
                    0.0
                    if row_max_cur_row == -cutlass.Float32.inf
                    else row_max_cur_row
                )

            acc_S_row_exp = cute.math.exp2(
                acc_S_row * softmax_params.softmax_scale_log2
                - row_max_cur_row * softmax_params.softmax_scale_log2,
                fastmath=True,
            )
            acc_S_row_sum = acc_S_row_exp.reduce(
                cute.ReductionOp.ADD, cutlass.Float32.zero, 0
            )
            if cutlass.const_expr(not is_first_n_block):
                prev_minus_cur_exp = cute.math.exp2(
                    row_max_prev_row * softmax_params.softmax_scale_log2
                    - row_max_cur_row * softmax_params.softmax_scale_log2,
                    fastmath=True,
                )
                acc_S_row_sum = (
                    acc_S_row_sum + softmax_params.row_sum[r] * prev_minus_cur_exp
                )
                acc_O_mn[r, None] = acc_O_mn[r, None].load() * prev_minus_cur_exp
            softmax_params.row_max[r] = row_max_cur_row
            softmax_params.row_sum[r] = acc_S_row_sum
            acc_S_mn[r, None] = acc_S_row_exp

    @cute.jit
    def normalize_softmax(self, acc_O: cute.Tensor, row_sum: cute.Tensor):
        """Normalize acc_O by row_sum."""
        acc_O_mn = self._make_acc_tensor_mn_view(acc_O)
        for r in cutlass.range_constexpr(cute.size(row_sum)):
            row_sum[r] = self._threadquad_reduce_sum(row_sum[r])
            acc_O_mn_row_is_zero_or_nan = row_sum[r] == 0.0 or row_sum[r] != row_sum[r]
            scale = (
                1.0
                if acc_O_mn_row_is_zero_or_nan
                else cute.arch.rcp_approx(row_sum[r])
            )
            acc_O_mn[r, None] = acc_O_mn[r, None].load() * scale

    def _make_acc_tensor_mn_view(self, acc: cute.Tensor) -> cute.Tensor:
        """Reshape accumulator to M,N layout view."""
        acc_layout_col_major = cute.make_layout(acc.layout.shape)
        acc_layout_mn = cute.make_layout(
            (
                (acc_layout_col_major.shape[0][1], acc_layout_col_major.shape[1]),
                (acc_layout_col_major.shape[0][0], acc_layout_col_major.shape[2]),
            ),
            stride=(
                (acc_layout_col_major.stride[0][1], acc_layout_col_major.stride[1]),
                (acc_layout_col_major.stride[0][0], acc_layout_col_major.stride[2]),
            ),
        )
        acc_layout_mn = cute.composition(acc.layout, acc_layout_mn)
        return cute.make_tensor(acc.iterator, acc_layout_mn)

    def _threadquad_reduce(
        self, val: cutlass.Float32, op: Callable
    ) -> cutlass.Float32:
        """Thread quad reduction."""
        val = op(
            val,
            cute.arch.shuffle_sync_bfly(val, offset=2, mask=-1, mask_and_clamp=31),
        )
        val = op(
            val,
            cute.arch.shuffle_sync_bfly(val, offset=1, mask=-1, mask_and_clamp=31),
        )
        return val

    def _threadquad_reduce_max(self, val: cutlass.Float32) -> cutlass.Float32:
        return self._threadquad_reduce(val, lambda x, y: cute.arch.fmax(x, y))

    def _threadquad_reduce_sum(self, val: cutlass.Float32) -> cutlass.Float32:
        return self._threadquad_reduce(val, lambda x, y: x + y)


class FlashAttentionForwardSm120Tma:
    """Flash Attention v2 for SM120 using TMA loads and warp specialization.

    Uses TMA (cp.async.bulk) for global→shared memory transfers with a dedicated
    DMA warp, while MMA warps perform computation. This enables overlapping loads
    with compute via multi-stage KV pipelining.

    Key differences from FlashAttentionForwardSm120 (CpAsync):
      - TMA loads instead of CpAsync (hardware-managed bulk transfers)
      - Warp specialization: 1 DMA warp + N MMA warps (vs all threads load+compute)
      - PipelineTmaAsync with mbarrier synchronization
      - Multi-stage KV double-buffering for load/compute overlap
    """

    def __init__(
        self,
        head_dim: int,
        m_block_size: int = 128,
        n_block_size: int = 64,
        num_mma_warps: int = 4,
        kv_stages: int = 2,
        is_causal: bool = False,
    ):
        self._head_dim = head_dim
        self._m_block_size = m_block_size
        self._n_block_size = n_block_size
        self._head_dim_padded = (head_dim + 31) // 32 * 32
        self._num_mma_warps = num_mma_warps
        self._kv_stages = kv_stages
        self._num_threads = (num_mma_warps + 1) * 32  # +1 for DMA warp
        self._is_causal = is_causal

        # NamedBarrier for MMA warps only (DMA warp does not participate)
        self.mma_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1, num_threads=num_mma_warps * 32
        )
        self.load_register_requirement = 40
        self.mma_register_requirement = 232

    @staticmethod
    def can_implement(
        dtype, head_dim, m_block_size, n_block_size, num_mma_warps, kv_stages,
        is_causal,
    ) -> bool:
        if dtype != cutlass.Float16 and dtype != cutlass.BFloat16:
            return False
        if head_dim % 8 != 0:
            return False
        # m_block_size must be divisible by MMA tile M (num_mma_warps * 16)
        if m_block_size % (num_mma_warps * 16) != 0:
            return False
        head_dim_padded = (head_dim + 31) // 32 * 32
        # SMEM: sQ (1 stage) + sK (kv_stages) + sV (kv_stages) + mbar arrays
        smem_q = m_block_size * head_dim_padded * (dtype.width // 8)
        smem_kv = n_block_size * head_dim_padded * (dtype.width // 8) * kv_stages * 2
        smem_mbar = (1 * 2 + kv_stages * 2 * 2) * 8  # Q + K + V mbar arrays
        smem_align = 3 * 1024  # alignment overhead for 3 buffers
        smem_total = smem_q + smem_kv + smem_mbar + smem_align
        smem_capacity = utils.get_smem_capacity_in_bytes("sm_120")
        if smem_total > smem_capacity:
            return False
        return True

    @cute.jit
    def __call__(
        self,
        mQ: cute.Tensor,
        mK: cute.Tensor,
        mV: cute.Tensor,
        mO: cute.Tensor,
        softmax_scale: cutlass.Float32,
        stream: cuda.CUstream,
    ):
        if cutlass.const_expr(
            not (
                mQ.element_type == mK.element_type
                == mV.element_type == mO.element_type
            )
        ):
            raise TypeError("All tensors must have the same data type")
        if cutlass.const_expr(
            not (
                mQ.element_type == cutlass.Float16
                or mQ.element_type == cutlass.BFloat16
            )
        ):
            raise TypeError("Only Float16 or BFloat16 is supported")
        self._dtype = mQ.element_type

        # /////////////////////////////////////////////////////////////////////
        # SMEM layouts with TMA-compatible swizzle (M=4 required for TMA).
        # TMA hardware supports only Swizzle(B, 4, 3) patterns:
        #   SW128: Swizzle(3, 4, 3) for 128-byte rows (64 bf16 elems)
        #   SW64:  Swizzle(2, 4, 3) for 64-byte rows  (32 bf16 elems)
        # The CpAsync version uses Swizzle(B, 3, 3) which is NOT valid for TMA.
        # /////////////////////////////////////////////////////////////////////
        smem_k_block_size = 64 if self._head_dim_padded % 64 == 0 else 32
        # TMA-compatible swizzle: Swizzle(B, 4, 3) where B depends on row size.
        # For bf16 with smem_k_block_size=64: 64*16=1024 bits → SW128 → B=3
        # For bf16 with smem_k_block_size=32: 32*16=512 bits  → SW64  → B=2
        swizzle_bits = 3 if smem_k_block_size == 64 else 2
        sQ_layout_atom = cute.make_composed_layout(
            cute.make_swizzle(swizzle_bits, 4, 3),
            0,
            cute.make_layout(
                (8, smem_k_block_size), stride=(smem_k_block_size, 1)
            ),
        )
        # Staged Q layout: (m_block, head_dim, 1_stage)
        sQ_layout_staged = cute.tile_to_shape(
            sQ_layout_atom,
            (self._m_block_size, self._head_dim_padded, 1),
            (0, 1, 2),
        )
        sQ_layout_one_stage = cute.slice_(sQ_layout_staged, (None, None, 0))
        sKV_layout_atom = sQ_layout_atom
        # Staged KV layout: (n_block, head_dim, kv_stages)
        sKV_layout_staged = cute.tile_to_shape(
            sKV_layout_atom,
            (self._n_block_size, self._head_dim_padded, self._kv_stages),
            (0, 1, 2),
        )
        sKV_layout_one_stage = cute.slice_(sKV_layout_staged, (None, None, 0))
        sO_layout = sQ_layout_one_stage

        # /////////////////////////////////////////////////////////////////////
        # Reshape tensors for TMA: (batch, seq, head, dim) → (seq, dim, head, batch)
        # TMA tiles the leading 2 modes (seq, dim); head and batch are
        # coordinate modes indexed per CTA.
        # /////////////////////////////////////////////////////////////////////
        mQ_for_tma = cute.make_tensor(
            mQ.iterator,
            cute.make_layout(
                (mQ.shape[1], mQ.shape[3], mQ.shape[2], mQ.shape[0]),
                stride=(mQ.stride[1], mQ.stride[3], mQ.stride[2], mQ.stride[0]),
            ),
        )
        mK_for_tma = cute.make_tensor(
            mK.iterator,
            cute.make_layout(
                (mK.shape[1], mK.shape[3], mK.shape[2], mK.shape[0]),
                stride=(mK.stride[1], mK.stride[3], mK.stride[2], mK.stride[0]),
            ),
        )
        mV_for_tma = cute.make_tensor(
            mV.iterator,
            cute.make_layout(
                (mV.shape[1], mV.shape[3], mV.shape[2], mV.shape[0]),
                stride=(mV.stride[1], mV.stride[3], mV.stride[2], mV.stride[0]),
            ),
        )

        # /////////////////////////////////////////////////////////////////////
        # TMA descriptors for Q, K, V
        # /////////////////////////////////////////////////////////////////////
        tma_op = cpasync.CopyBulkTensorTileG2SOp()
        tma_atom_q, tma_tensor_q = cpasync.make_tiled_tma_atom(
            tma_op, mQ_for_tma, sQ_layout_one_stage,
            (self._m_block_size, self._head_dim_padded), num_multicast=1,
        )
        tma_atom_k, tma_tensor_k = cpasync.make_tiled_tma_atom(
            tma_op, mK_for_tma, sKV_layout_one_stage,
            (self._n_block_size, self._head_dim_padded), num_multicast=1,
        )
        tma_atom_v, tma_tensor_v = cpasync.make_tiled_tma_atom(
            tma_op, mV_for_tma, sKV_layout_one_stage,
            (self._n_block_size, self._head_dim_padded), num_multicast=1,
        )

        # TMA transfer sizes (bytes per load)
        q_copy_bytes = cute.size_in_bytes(self._dtype, sQ_layout_one_stage)
        kv_copy_bytes = cute.size_in_bytes(self._dtype, sKV_layout_one_stage)

        # /////////////////////////////////////////////////////////////////////
        # Shared storage
        # /////////////////////////////////////////////////////////////////////
        @cute.struct
        class SharedStorage:
            q_mbar_ptr: cute.struct.MemRange[cutlass.Int64, 1 * 2]
            k_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self._kv_stages * 2]
            v_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self._kv_stages * 2]
            sQ: cute.struct.Align[
                cute.struct.MemRange[self._dtype, cute.cosize(sQ_layout_staged)], 1024
            ]
            sK: cute.struct.Align[
                cute.struct.MemRange[
                    self._dtype, cute.cosize(sKV_layout_staged)
                ],
                1024,
            ]
            sV: cute.struct.Align[
                cute.struct.MemRange[
                    self._dtype, cute.cosize(sKV_layout_staged)
                ],
                1024,
            ]

        # /////////////////////////////////////////////////////////////////////
        # MMA (same SM80-compatible tensor core ops as CpAsync version)
        # /////////////////////////////////////////////////////////////////////
        tiled_mma = cute.make_tiled_mma(
            warp.MmaF16BF16Op(self._dtype, cutlass.Float32, (16, 8, 16)),
            (self._num_mma_warps, 1, 1),
            permutation_mnk=(self._num_mma_warps * 16, 16, 16),
        )

        # Grid: (m_blocks, head*batch, 1) — head+batch folded into grid.y
        # to match the 3D TMA tensor layout (seq, dim, (head, batch))
        num_heads = cute.size(mQ.shape[2])
        num_batches = cute.size(mQ.shape[0])
        grid_dim = (
            cute.ceil_div(mQ.shape[1], self._m_block_size),
            num_heads * num_batches,
            1,
        )
        LOG2_E = 1.4426950408889634074
        softmax_scale_log2 = softmax_scale * LOG2_E
        self.kernel(
            tma_atom_q, tma_tensor_q,
            tma_atom_k, tma_tensor_k,
            tma_atom_v, tma_tensor_v,
            mQ, mK, mV, mO,
            softmax_scale_log2,
            q_copy_bytes,
            kv_copy_bytes,
            sQ_layout_staged,
            sKV_layout_staged,
            sO_layout,
            tiled_mma,
            SharedStorage,
            num_heads,
        ).launch(
            grid=grid_dim,
            block=[self._num_threads, 1, 1],
            cluster=[1, 1, 1],
            smem=SharedStorage.size_in_bytes(),
            stream=stream,
        )

    @cute.kernel
    def kernel(
        self,
        tma_atom_q: cute.CopyAtom,
        mQ_tma: cute.Tensor,
        tma_atom_k: cute.CopyAtom,
        mK_tma: cute.Tensor,
        tma_atom_v: cute.CopyAtom,
        mV_tma: cute.Tensor,
        mQ: cute.Tensor,
        mK: cute.Tensor,
        mV: cute.Tensor,
        mO: cute.Tensor,
        softmax_scale_log2: cutlass.Float32,
        q_copy_bytes: cutlass.Constexpr,
        kv_copy_bytes: cutlass.Constexpr,
        sQ_layout_staged: cute.ComposedLayout,
        sKV_layout_staged: cute.ComposedLayout,
        sO_layout: cute.ComposedLayout,
        tiled_mma: cute.TiledMma,
        SharedStorage: cutlass.Constexpr,
        num_heads: cutlass.Int32,
    ):
        tidx, _, _ = cute.arch.thread_idx()
        # Grid is (m_blocks, head*batch, 1) — decompose hb_idx
        m_block, hb_idx, _ = cute.arch.block_idx()
        head_idx = hb_idx % num_heads
        batch_idx = hb_idx // num_heads
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        n_block_max = cute.ceil_div(mK.shape[1], self._n_block_size)
        if self._is_causal:
            n_block_max = min(
                cute.ceil_div(
                    (m_block + 1) * self._m_block_size,
                    self._n_block_size,
                ),
                n_block_max,
            )

        # /////////////////////////////////////////////////////////////////////
        # Allocate SMEM and create tensors
        # /////////////////////////////////////////////////////////////////////
        smem = cutlass.utils.SmemAllocator()
        storage = smem.allocate(SharedStorage)
        sQ = storage.sQ.get_tensor(
            sQ_layout_staged.outer, swizzle=sQ_layout_staged.inner
        )
        sK = storage.sK.get_tensor(
            sKV_layout_staged.outer, swizzle=sKV_layout_staged.inner
        )
        sV = storage.sV.get_tensor(
            sKV_layout_staged.outer, swizzle=sKV_layout_staged.inner
        )

        # Transposed V view for PV GEMM (same composition as CpAsync version,
        # extended with stage dimension)
        sVt_staged = cute.composition(
            sV,
            cute.make_layout(
                (self._head_dim_padded, self._n_block_size, self._kv_stages),
                stride=(
                    self._n_block_size,
                    1,
                    self._n_block_size * self._head_dim_padded,
                ),
            ),
        )

        # /////////////////////////////////////////////////////////////////////
        # TMA partition: global → smem tile mapping
        # /////////////////////////////////////////////////////////////////////
        # Q, K, V: (seq, dim, head, batch) → 4D TMA
        # Tile first 2 modes (seq, dim); head and batch are coordinate modes
        gQ = cute.local_tile(
            mQ_tma,
            (self._m_block_size, self._head_dim_padded),
            (None, 0, None, None),
        )
        tQsQ, tQgQ = cpasync.tma_partition(
            tma_atom_q, 0, cute.make_layout(1),
            cute.group_modes(sQ, 0, 2),
            cute.group_modes(gQ, 0, 2),
        )

        gK = cute.local_tile(
            mK_tma,
            (self._n_block_size, self._head_dim_padded),
            (None, 0, None, None),
        )
        tKsK, tKgK = cpasync.tma_partition(
            tma_atom_k, 0, cute.make_layout(1),
            cute.group_modes(sK, 0, 2),
            cute.group_modes(gK, 0, 2),
        )

        gV = cute.local_tile(
            mV_tma,
            (self._n_block_size, self._head_dim_padded),
            (None, 0, None, None),
        )
        tVsV, tVgV = cpasync.tma_partition(
            tma_atom_v, 0, cute.make_layout(1),
            cute.group_modes(sV, 0, 2),
            cute.group_modes(gV, 0, 2),
        )

        # Select this CTA's head and batch coordinates
        tQgQ_block = tQgQ[(None, m_block, head_idx, batch_idx)]
        tKgK_block = tKgK[(None, None, head_idx, batch_idx)]
        tVgV_block = tVgV[(None, None, head_idx, batch_idx)]

        # /////////////////////////////////////////////////////////////////////
        # Init pipelines
        # /////////////////////////////////////////////////////////////////////
        q_pipeline = pipeline.PipelineTmaAsync.create(
            num_stages=1,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self._num_mma_warps
            ),
            tx_count=q_copy_bytes,
            barrier_storage=storage.q_mbar_ptr.data_ptr(),
        )
        k_pipeline = pipeline.PipelineTmaAsync.create(
            num_stages=self._kv_stages,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self._num_mma_warps
            ),
            tx_count=kv_copy_bytes,
            barrier_storage=storage.k_mbar_ptr.data_ptr(),
        )
        v_pipeline = pipeline.PipelineTmaAsync.create(
            num_stages=self._kv_stages,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self._num_mma_warps
            ),
            tx_count=kv_copy_bytes,
            barrier_storage=storage.v_mbar_ptr.data_ptr(),
        )

        pipeline.sync(barrier_id=0)

        # Prefetch TMA descriptors
        if warp_idx == 0:
            cpasync.prefetch_descriptor(tma_atom_q)
            cpasync.prefetch_descriptor(tma_atom_k)
            cpasync.prefetch_descriptor(tma_atom_v)

        # /////////////////////////////////////////////////////////////////////
        # MMA partition setup (same as CpAsync version)
        # /////////////////////////////////////////////////////////////////////
        thr_mma = tiled_mma.get_slice(tidx)
        sQ_one = sQ[None, None, 0]
        sK_one = sK[None, None, 0]
        tSrQ = thr_mma.make_fragment_A(thr_mma.partition_A(sQ_one))
        tSrK = thr_mma.make_fragment_B(thr_mma.partition_B(sK_one))
        sVt_one = sVt_staged[None, None, 0]
        tOrVt = thr_mma.make_fragment_B(thr_mma.partition_B(sVt_one))
        acc_shape_O = thr_mma.partition_shape_C(
            (self._m_block_size, self._head_dim_padded)
        )
        acc_O = cute.make_rmem_tensor(acc_shape_O, cutlass.Float32)
        acc_O.fill(0.0)

        # LdMatrix atoms: shared → register
        smem_copy_atom_Q = cute.make_copy_atom(
            warp.LdMatrix8x8x16bOp(transpose=False, num_matrices=4),
            self._dtype,
        )
        smem_copy_atom_K = cute.make_copy_atom(
            warp.LdMatrix8x8x16bOp(transpose=False, num_matrices=4),
            self._dtype,
        )
        smem_copy_atom_V = cute.make_copy_atom(
            warp.LdMatrix8x8x16bOp(transpose=True, num_matrices=4),
            self._dtype,
        )
        smem_tiled_copy_Q = cute.make_tiled_copy_A(smem_copy_atom_Q, tiled_mma)
        smem_tiled_copy_K = cute.make_tiled_copy_B(smem_copy_atom_K, tiled_mma)
        smem_tiled_copy_V = cute.make_tiled_copy_B(smem_copy_atom_V, tiled_mma)

        smem_thr_copy_Q = smem_tiled_copy_Q.get_slice(tidx)
        smem_thr_copy_K = smem_tiled_copy_K.get_slice(tidx)
        smem_thr_copy_V = smem_tiled_copy_V.get_slice(tidx)

        tSsQ = smem_thr_copy_Q.partition_S(sQ_one)
        tSrQ_copy_view = smem_thr_copy_Q.retile(tSrQ)

        # Softmax state
        row_max = cute.make_rmem_tensor(
            (acc_O.shape[0][0] * acc_O.shape[1]), cutlass.Float32
        )
        row_sum = cute.make_rmem_tensor(
            (acc_O.shape[0][0] * acc_O.shape[1]), cutlass.Float32
        )
        row_max.fill(-cutlass.Float32.inf)
        row_sum.fill(0.0)

        # Pipeline states
        q_producer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Producer, 1
        )
        k_producer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Producer, self._kv_stages
        )
        v_producer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Producer, self._kv_stages
        )
        k_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self._kv_stages
        )
        v_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self._kv_stages
        )

        # /////////////////////////////////////////////////////////////////////
        # Warp specialization
        # /////////////////////////////////////////////////////////////////////
        if warp_idx < self._num_mma_warps:
            # === MMA warps (consumer) ===
            cute.arch.setmaxregister_increase(232)

            # Wait for Q to be loaded
            q_pipeline.consumer_wait(
                pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer, 1
                )
            )

            # Main attention loop (iterate over KV tiles, high to low for causal)
            for n_tile in range(0, n_block_max, 1, unroll=1):
                n_block = n_block_max - n_tile - 1

                # --- Wait for K, compute S = Q * K^T ---
                k_pipeline.consumer_wait(k_consumer_state)
                k_stage = k_consumer_state.index

                acc_shape_S = thr_mma.partition_shape_C(
                    (self._m_block_size, self._n_block_size)
                )
                acc_S = cute.make_rmem_tensor(acc_shape_S, cutlass.Float32)
                acc_S.fill(0.0)

                # Partition K for this stage
                tSsK_stage = smem_thr_copy_K.partition_S(sK[None, None, k_stage])
                tSrK_copy_view = smem_thr_copy_K.retile(tSrK)

                # Prefetch Q and K into registers
                cute.copy(
                    smem_tiled_copy_Q,
                    tSsQ[None, None, 0],
                    tSrQ_copy_view[None, None, 0],
                )
                cute.copy(
                    smem_tiled_copy_K,
                    tSsK_stage[None, None, 0],
                    tSrK_copy_view[None, None, 0],
                )
                # QK GEMM with register pipeline
                for k in cutlass.range_constexpr(cute.size(tSsQ.shape[2])):
                    k_next = (k + 1) % cute.size(tSsQ.shape[2])
                    cute.copy(
                        smem_tiled_copy_Q,
                        tSsQ[None, None, k_next],
                        tSrQ_copy_view[None, None, k_next],
                    )
                    cute.copy(
                        smem_tiled_copy_K,
                        tSsK_stage[None, None, k_next],
                        tSrK_copy_view[None, None, k_next],
                    )
                    cute.gemm(
                        tiled_mma, acc_S,
                        tSrQ[None, None, k],
                        tSrK[None, None, k],
                        acc_S,
                    )

                k_pipeline.consumer_release(k_consumer_state)
                k_consumer_state.advance()

                # --- Online softmax ---
                self._softmax_rescale_O(
                    m_block, n_block, mQ, mK, batch_idx, head_idx,
                    thr_mma, tiled_mma, acc_O,
                    row_max, row_sum, softmax_scale_log2,
                    acc_S,
                    in_mask_steps=cutlass.const_expr(self._is_causal),
                )
                rP = cute.make_fragment_like(acc_S, self._dtype)
                rP.store(acc_S.load().to(self._dtype))

                # --- Wait for V, compute O += P * V ---
                v_pipeline.consumer_wait(v_consumer_state)
                v_stage = v_consumer_state.index

                rP_layout_divided = cute.logical_divide(rP.layout, (None, None, 2))
                rP_mma_view = cute.make_layout(
                    (
                        (rP_layout_divided.shape[0], rP_layout_divided.shape[2][0]),
                        rP_layout_divided.shape[1],
                        rP_layout_divided.shape[2][1],
                    ),
                    stride=(
                        (rP_layout_divided.stride[0], rP_layout_divided.stride[2][0]),
                        rP_layout_divided.stride[1],
                        rP_layout_divided.stride[2][1],
                    ),
                )
                tOrS = cute.make_tensor(rP.iterator, rP_mma_view)

                # Partition V for this stage
                tOsVt_stage = smem_thr_copy_V.partition_S(
                    sVt_staged[None, None, v_stage]
                )
                tOrVt_copy_view = smem_thr_copy_V.retile(tOrVt)

                cute.copy(
                    smem_tiled_copy_V,
                    tOsVt_stage[None, None, 0],
                    tOrVt_copy_view[None, None, 0],
                )
                for k in cutlass.range_constexpr(cute.size(tOrS.shape[2])):
                    k_next = (k + 1) % cute.size(tOrS.shape[2])
                    cute.copy(
                        smem_tiled_copy_V,
                        tOsVt_stage[None, None, k_next],
                        tOrVt_copy_view[None, None, k_next],
                    )
                    cute.gemm(
                        tiled_mma, acc_O,
                        tOrS[None, None, k],
                        tOrVt[None, None, k],
                        acc_O,
                    )

                v_pipeline.consumer_release(v_consumer_state)
                v_consumer_state.advance()

            # Epilogue: normalize and store O
            self._normalize_softmax(acc_O, row_sum)
            rO = cute.make_fragment_like(acc_O, self._dtype)
            rO.store(acc_O.load().to(self._dtype))
            # sQ_one.iterator already has the swizzle from get_tensor(outer, swizzle=inner),
            # so use sO_layout.outer (plain layout) to avoid double-swizzle conflict
            sO = cute.make_tensor(sQ_one.iterator, sO_layout.outer)

            smem_copy_atom_O = cute.make_copy_atom(
                cute.nvgpu.CopyUniversalOp(), self._dtype
            )
            smem_tiled_copy_O = cute.make_tiled_copy_C(
                smem_copy_atom_O, tiled_mma
            )
            smem_thr_copy_O = smem_tiled_copy_O.get_slice(tidx)
            taccOrO = smem_thr_copy_O.retile(rO)
            taccOsO = smem_thr_copy_O.partition_D(sO)
            cute.copy(smem_copy_atom_O, taccOrO, taccOsO)

            gO = cute.local_tile(
                mO[batch_idx, None, head_idx, None],
                (self._m_block_size, self._head_dim_padded),
                (m_block, 0),
            )
            universal_copy_bits = 128
            async_copy_elems = universal_copy_bits // self._dtype.width
            atom_universal_copy = cute.make_copy_atom(
                cute.nvgpu.CopyUniversalOp(),
                self._dtype,
                num_bits_per_copy=universal_copy_bits,
            )
            tO_shape_dim_1 = cute.size(sO_layout.outer.shape[1]) // async_copy_elems
            tO_layout = cute.make_layout(
                (self._num_mma_warps * 32 // tO_shape_dim_1, tO_shape_dim_1),
                stride=(tO_shape_dim_1, 1),
            )
            vO_layout = cute.make_layout((1, async_copy_elems))
            gmem_tiled_copy_O = cute.make_tiled_copy_tv(
                atom_universal_copy, tO_layout, vO_layout
            )
            gmem_thr_copy_O = gmem_tiled_copy_O.get_slice(tidx)
            tOsO = gmem_thr_copy_O.partition_S(sO)
            tOgO = gmem_thr_copy_O.partition_D(gO)
            tOrO_out = cute.make_fragment_like(tOgO, self._dtype)
            self.mma_sync_barrier.arrive_and_wait()
            cute.copy(gmem_tiled_copy_O, tOsO, tOrO_out)

            mcO = cute.make_identity_tensor(mO.layout.shape)
            cO = cute.local_tile(
                mcO[batch_idx, None, head_idx, None],
                (self._m_block_size, self._head_dim_padded),
                (m_block, 0),
            )
            tOcO = gmem_thr_copy_O.partition_D(cO)
            tOpO = cute.make_rmem_tensor(
                cute.make_layout(
                    (tOgO.shape[0][1], tOgO.shape[1], tOgO.shape[2]),
                    stride=(tOgO.shape[2], 0, 1),
                ),
                cutlass.Boolean,
            )
            for rest_v in cutlass.range_constexpr(tOpO.shape[0]):
                for rest_n in cutlass.range_constexpr(cute.size(tOpO.shape[2])):
                    tOpO[rest_v, 0, rest_n] = cute.elem_less(
                        tOcO[(0, rest_v), 0, rest_n][3], mO.layout.shape[3]
                    )
            for rest_m in cutlass.range_constexpr(cute.size(tOpO.shape[1])):
                if cute.elem_less(tOcO[0, rest_m, 0][1], mO.layout.shape[1]):
                    cute.copy(
                        gmem_tiled_copy_O,
                        tOrO_out[None, rest_m, None],
                        tOgO[None, rest_m, None],
                        pred=tOpO[None, rest_m, None],
                    )

        elif warp_idx == self._num_mma_warps:
            # === DMA warp (producer) ===
            cute.arch.setmaxregister_decrease(40)

            # Load Q (once, stage 0)
            q_pipeline.producer_acquire(q_producer_state)
            cute.copy(
                tma_atom_q, tQgQ_block,
                tQsQ[(None, q_producer_state.index)],
                tma_bar_ptr=q_pipeline.producer_get_barrier(q_producer_state),
            )
            q_pipeline.producer_commit(q_producer_state)

            # Load KV tiles (high to low for causal, matching consumer order)
            for n_tile in range(0, n_block_max, 1, unroll=1):
                n_block = n_block_max - n_tile - 1

                # Load K
                k_pipeline.producer_acquire(k_producer_state)
                cute.copy(
                    tma_atom_k,
                    tKgK_block[(None, n_block)],
                    tKsK[(None, k_producer_state.index)],
                    tma_bar_ptr=k_pipeline.producer_get_barrier(
                        k_producer_state
                    ),
                )
                k_pipeline.producer_commit(k_producer_state)
                k_producer_state.advance()

                # Load V
                v_pipeline.producer_acquire(v_producer_state)
                cute.copy(
                    tma_atom_v,
                    tVgV_block[(None, n_block)],
                    tVsV[(None, v_producer_state.index)],
                    tma_bar_ptr=v_pipeline.producer_get_barrier(
                        v_producer_state
                    ),
                )
                v_pipeline.producer_commit(v_producer_state)
                v_producer_state.advance()

            # Signal pipeline tail
            k_pipeline.producer_tail(k_producer_state)
            v_pipeline.producer_tail(v_producer_state)

    # /////////////////////////////////////////////////////////////////////////
    # Softmax helpers (reused from CpAsync version)
    # /////////////////////////////////////////////////////////////////////////
    @cute.jit
    def _softmax_rescale_O(
        self,
        m_block, n_block, mQ, mK, batch_idx, head_idx,
        thr_mma, tiled_mma, acc_O,
        row_max, row_sum, softmax_scale_log2,
        acc_S, in_mask_steps,
    ):
        acc_S_mn = self._make_acc_tensor_mn_view(acc_S)
        acc_O_mn = self._make_acc_tensor_mn_view(acc_O)
        # Save previous row_max for rescaling (on first iter, row_max=-inf
        # so prev_minus_cur_exp=0, making rescale a no-op)
        row_max_prev = cute.make_fragment_like(row_max, cutlass.Float32)
        cute.basic_copy(row_max, row_max_prev)

        for r in cutlass.range_constexpr(cute.size(row_max)):
            if cutlass.const_expr(in_mask_steps and self._is_causal):
                mcS = cute.make_identity_tensor((
                    mQ.shape[0], mQ.shape[1], mQ.shape[2], mK.shape[1],
                ))
                cS = cute.local_tile(
                    mcS[batch_idx, None, head_idx, None],
                    (self._m_block_size, self._n_block_size),
                    (m_block, n_block),
                )
                tScS = thr_mma.partition_C(cS)
                tScS_mn = self._make_acc_tensor_mn_view(tScS)
                col_idx_limit = cutlass.min(
                    tScS_mn[r, 0][1] + 1, mK.shape[1]
                )
                for c in cutlass.range_constexpr(cute.size(tScS_mn.shape[1])):
                    if cute.elem_less(col_idx_limit, tScS_mn[0, c][3] + 1):
                        acc_S_mn[r, c] = -cutlass.Float32.inf

            acc_S_row = acc_S_mn[r, None].load()
            row_max_cur_row = acc_S_row.reduce(
                cute.ReductionOp.MAX, -cutlass.Float32.inf, 0
            )
            row_max_cur_row = self._threadquad_reduce_max(row_max_cur_row)
            row_max_prev_row = row_max_prev[r]
            row_max_cur_row = cute.arch.fmax(
                row_max_prev_row, row_max_cur_row
            )
            if cutlass.const_expr(self._is_causal):
                row_max_cur_row = (
                    0.0
                    if row_max_cur_row == -cutlass.Float32.inf
                    else row_max_cur_row
                )

            acc_S_row_exp = cute.math.exp2(
                acc_S_row * softmax_scale_log2
                - row_max_cur_row * softmax_scale_log2,
                fastmath=True,
            )
            acc_S_row_sum = acc_S_row_exp.reduce(
                cute.ReductionOp.ADD, cutlass.Float32.zero, 0
            )
            prev_minus_cur_exp = cute.math.exp2(
                row_max_prev_row * softmax_scale_log2
                - row_max_cur_row * softmax_scale_log2,
                fastmath=True,
            )
            acc_S_row_sum = (
                acc_S_row_sum + row_sum[r] * prev_minus_cur_exp
            )
            acc_O_mn[r, None] = acc_O_mn[r, None].load() * prev_minus_cur_exp
            row_max[r] = row_max_cur_row
            row_sum[r] = acc_S_row_sum
            acc_S_mn[r, None] = acc_S_row_exp

    @cute.jit
    def _normalize_softmax(self, acc_O: cute.Tensor, row_sum: cute.Tensor):
        acc_O_mn = self._make_acc_tensor_mn_view(acc_O)
        for r in cutlass.range_constexpr(cute.size(row_sum)):
            row_sum[r] = self._threadquad_reduce_sum(row_sum[r])
            acc_O_mn_row_is_zero_or_nan = (
                row_sum[r] == 0.0 or row_sum[r] != row_sum[r]
            )
            scale = (
                1.0
                if acc_O_mn_row_is_zero_or_nan
                else cute.arch.rcp_approx(row_sum[r])
            )
            acc_O_mn[r, None] = acc_O_mn[r, None].load() * scale

    def _make_acc_tensor_mn_view(self, acc: cute.Tensor) -> cute.Tensor:
        acc_layout_col_major = cute.make_layout(acc.layout.shape)
        acc_layout_mn = cute.make_layout(
            (
                (acc_layout_col_major.shape[0][1], acc_layout_col_major.shape[1]),
                (acc_layout_col_major.shape[0][0], acc_layout_col_major.shape[2]),
            ),
            stride=(
                (acc_layout_col_major.stride[0][1], acc_layout_col_major.stride[1]),
                (acc_layout_col_major.stride[0][0], acc_layout_col_major.stride[2]),
            ),
        )
        acc_layout_mn = cute.composition(acc.layout, acc_layout_mn)
        return cute.make_tensor(acc.iterator, acc_layout_mn)

    def _threadquad_reduce(
        self, val: cutlass.Float32, op
    ) -> cutlass.Float32:
        val = op(
            val,
            cute.arch.shuffle_sync_bfly(
                val, offset=2, mask=-1, mask_and_clamp=31
            ),
        )
        val = op(
            val,
            cute.arch.shuffle_sync_bfly(
                val, offset=1, mask=-1, mask_and_clamp=31
            ),
        )
        return val

    def _threadquad_reduce_max(self, val: cutlass.Float32) -> cutlass.Float32:
        return self._threadquad_reduce(val, lambda x, y: cute.arch.fmax(x, y))

    def _threadquad_reduce_sum(self, val: cutlass.Float32) -> cutlass.Float32:
        return self._threadquad_reduce(val, lambda x, y: x + y)


# NOTE: FP8 FA on SM120 requires the `kind::f8f6f4` MMA instruction variant
# (SM120_16x8x32_TN in mma_sm120.hpp), which is not yet exposed in the CuTe
# Python DSL. The SM89-era mma.sync.aligned.m16n8k32 FP8 MMA does not work on
# SM120. Once the Python DSL exposes SM120's F8F6F4 MMA, an FP8 FA kernel can
# be added here with 2x theoretical throughput over BF16.


def run(
    dtype: Type[cutlass.Numeric],
    batch_size: int,
    seqlen_q: int,
    seqlen_k: int,
    num_head: int,
    head_dim: int,
    softmax_scale: float = 1.0,
    m_block_size: int = 128,
    n_block_size: int = 128,
    num_threads: int = 128,
    is_causal: bool = False,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    **kwargs,
):
    if not FlashAttentionForwardSm120.can_implement(
        dtype, head_dim, m_block_size, n_block_size, num_threads, is_causal,
    ):
        raise TypeError(
            f"Unsupported config: {dtype}, {head_dim}, {m_block_size}, "
            f"{n_block_size}, {num_threads}, {is_causal}"
        )

    print("Running Blackwell GeForce SM120 FlashAttentionForward test with:")
    print(f"  dtype: {dtype}")
    print(f"  batch_size: {batch_size}")
    print(f"  seqlen_q: {seqlen_q}")
    print(f"  seqlen_k: {seqlen_k}")
    print(f"  num_head: {num_head}")
    print(f"  head_dim: {head_dim}")
    print(f"  softmax_scale: {softmax_scale}")
    print(f"  m_block_size: {m_block_size}")
    print(f"  n_block_size: {n_block_size}")
    print(f"  num_threads: {num_threads}")
    print(f"  is_causal: {is_causal}")

    def create_tensor(batch_size, seqlen, num_head, head_dim, dtype):
        shape = (batch_size, seqlen, num_head, head_dim)
        torch_tensor = (
            torch.empty(*shape, dtype=torch.int32)
            .random_(-2, 2)
            .to(dtype=cutlass_torch.dtype(dtype))
            .cuda()
        )
        cute_tensor = (
            from_dlpack(torch_tensor, assumed_align=16)
            .mark_layout_dynamic(leading_dim=3)
            .mark_compact_shape_dynamic(
                mode=3,
                stride_order=torch_tensor.dim_order(),
                divisibility=(128 // dtype.width),
            )
        )
        return cute_tensor, torch_tensor

    q, q_torch = create_tensor(batch_size, seqlen_q, num_head, head_dim, dtype)
    k, k_torch = create_tensor(batch_size, seqlen_k, num_head, head_dim, dtype)
    v, v_torch = create_tensor(batch_size, seqlen_k, num_head, head_dim, dtype)
    o, o_torch = create_tensor(batch_size, seqlen_q, num_head, head_dim, dtype)

    fa2_fwd = FlashAttentionForwardSm120(
        head_dim, m_block_size, n_block_size, num_threads, is_causal,
    )

    torch_stream = torch.cuda.current_stream()
    current_stream = cuda.CUstream(torch_stream.cuda_stream)
    compiled_fa2_fwd = cute.compile(
        fa2_fwd, q, k, v, o, softmax_scale, current_stream
    )

    if not skip_ref_check:
        compiled_fa2_fwd(q, k, v, o, softmax_scale, current_stream)
        torch.cuda.synchronize()
        q_ref = q_torch.permute(0, 2, 1, 3)
        k_ref = k_torch.permute(0, 2, 1, 3)
        v_ref = v_torch.permute(0, 2, 1, 3)
        torch.backends.cuda.enable_flash_sdp(enabled=True)
        ref_o = torch.nn.functional.scaled_dot_product_attention(
            q_ref, k_ref, v_ref, scale=softmax_scale, is_causal=is_causal
        ).permute(0, 2, 1, 3)
        torch.testing.assert_close(o_torch.cpu(), ref_o.cpu(), atol=1e-02, rtol=1e-04)
        print("Results verified successfully!")

    def generate_tensors():
        q_w, _ = create_tensor(batch_size, seqlen_q, num_head, head_dim, dtype)
        k_w, _ = create_tensor(batch_size, seqlen_k, num_head, head_dim, dtype)
        v_w, _ = create_tensor(batch_size, seqlen_k, num_head, head_dim, dtype)
        o_w, _ = create_tensor(batch_size, seqlen_q, num_head, head_dim, dtype)
        return testing.JitArguments(
            q_w, k_w, v_w, o_w, softmax_scale, current_stream,
        )

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            q_torch.numel() * q_torch.element_size()
            + k_torch.numel() * k_torch.element_size()
            + v_torch.numel() * v_torch.element_size()
            + o_torch.numel() * o_torch.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    avg_time_us = testing.benchmark(
        compiled_fa2_fwd,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return avg_time_us


def run_tma(
    dtype: Type[cutlass.Numeric],
    batch_size: int,
    seqlen_q: int,
    seqlen_k: int,
    num_head: int,
    head_dim: int,
    softmax_scale: float = 1.0,
    m_block_size: int = 128,
    n_block_size: int = 64,
    num_mma_warps: int = 4,
    kv_stages: int = 2,
    is_causal: bool = False,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    **kwargs,
):
    if not FlashAttentionForwardSm120Tma.can_implement(
        dtype, head_dim, m_block_size, n_block_size, num_mma_warps, kv_stages,
        is_causal,
    ):
        raise TypeError(
            f"Unsupported config: {dtype}, {head_dim}, {m_block_size}, "
            f"{n_block_size}, {num_mma_warps}, {kv_stages}, {is_causal}"
        )

    num_threads = (num_mma_warps + 1) * 32

    print("Running Blackwell GeForce SM120 FlashAttentionForward TMA test with:")
    print(f"  dtype: {dtype}")
    print(f"  batch_size: {batch_size}")
    print(f"  seqlen_q: {seqlen_q}")
    print(f"  seqlen_k: {seqlen_k}")
    print(f"  num_head: {num_head}")
    print(f"  head_dim: {head_dim}")
    print(f"  softmax_scale: {softmax_scale}")
    print(f"  m_block_size: {m_block_size}")
    print(f"  n_block_size: {n_block_size}")
    print(f"  num_mma_warps: {num_mma_warps} (num_threads: {num_threads})")
    print(f"  kv_stages: {kv_stages}")
    print(f"  is_causal: {is_causal}")

    def create_tensor(batch_size, seqlen, num_head, head_dim, dtype):
        shape = (batch_size, seqlen, num_head, head_dim)
        torch_tensor = (
            torch.empty(*shape, dtype=torch.int32)
            .random_(-2, 2)
            .to(dtype=cutlass_torch.dtype(dtype))
            .cuda()
        )
        cute_tensor = (
            from_dlpack(torch_tensor, assumed_align=16)
            .mark_layout_dynamic(leading_dim=3)
            .mark_compact_shape_dynamic(
                mode=3,
                stride_order=torch_tensor.dim_order(),
                divisibility=(128 // dtype.width),
            )
        )
        return cute_tensor, torch_tensor

    q, q_torch = create_tensor(batch_size, seqlen_q, num_head, head_dim, dtype)
    k, k_torch = create_tensor(batch_size, seqlen_k, num_head, head_dim, dtype)
    v, v_torch = create_tensor(batch_size, seqlen_k, num_head, head_dim, dtype)
    o, o_torch = create_tensor(batch_size, seqlen_q, num_head, head_dim, dtype)

    fa2_fwd = FlashAttentionForwardSm120Tma(
        head_dim, m_block_size, n_block_size, num_mma_warps, kv_stages, is_causal,
    )

    torch_stream = torch.cuda.current_stream()
    current_stream = cuda.CUstream(torch_stream.cuda_stream)
    compiled_fa2_fwd = cute.compile(
        fa2_fwd, q, k, v, o, softmax_scale, current_stream
    )

    if not skip_ref_check:
        compiled_fa2_fwd(q, k, v, o, softmax_scale, current_stream)
        torch.cuda.synchronize()
        q_ref = q_torch.permute(0, 2, 1, 3)
        k_ref = k_torch.permute(0, 2, 1, 3)
        v_ref = v_torch.permute(0, 2, 1, 3)
        torch.backends.cuda.enable_flash_sdp(enabled=True)
        ref_o = torch.nn.functional.scaled_dot_product_attention(
            q_ref, k_ref, v_ref, scale=softmax_scale, is_causal=is_causal
        ).permute(0, 2, 1, 3)
        torch.testing.assert_close(o_torch.cpu(), ref_o.cpu(), atol=1e-02, rtol=1e-04)
        print("Results verified successfully!")

    def generate_tensors():
        q_w, _ = create_tensor(batch_size, seqlen_q, num_head, head_dim, dtype)
        k_w, _ = create_tensor(batch_size, seqlen_k, num_head, head_dim, dtype)
        v_w, _ = create_tensor(batch_size, seqlen_k, num_head, head_dim, dtype)
        o_w, _ = create_tensor(batch_size, seqlen_q, num_head, head_dim, dtype)
        return testing.JitArguments(
            q_w, k_w, v_w, o_w, softmax_scale, current_stream,
        )

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            q_torch.numel() * q_torch.element_size()
            + k_torch.numel() * k_torch.element_size()
            + v_torch.numel() * v_torch.element_size()
            + o_torch.numel() * o_torch.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    avg_time_us = testing.benchmark(
        compiled_fa2_fwd,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return avg_time_us


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Flash Attention v2 for Blackwell GeForce SM120"
    )
    parser.add_argument("--dtype", type=cutlass.dtype, default=cutlass.BFloat16)
    parser.add_argument("--batch_size", type=int, default=4)
    parser.add_argument("--seqlen_q", type=int, default=8192)
    parser.add_argument("--seqlen_k", type=int, default=8192)
    parser.add_argument("--num_head", type=int, default=16)
    parser.add_argument("--head_dim", type=int, default=128)
    parser.add_argument("--softmax_scale", type=float, default=0.5)
    parser.add_argument("--m_block_size", type=int, default=128)
    parser.add_argument("--n_block_size", type=int, default=64)
    parser.add_argument("--num_threads", type=int, default=128)
    parser.add_argument("--is_causal", action="store_true", help="Enable causal mask")
    parser.add_argument("--warmup_iterations", type=int, default=3)
    parser.add_argument("--iterations", type=int, default=10)
    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference check"
    )
    parser.add_argument(
        "--use_cold_l2", action="store_true", default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )
    parser.add_argument(
        "--use_tma", action="store_true", default=False,
        help="Use TMA variant with warp specialization",
    )
    parser.add_argument("--num_mma_warps", type=int, default=4,
        help="Number of MMA warps (TMA variant only)")
    parser.add_argument("--kv_stages", type=int, default=2,
        help="Number of KV pipeline stages (TMA variant only)")

    args = parser.parse_args()

    if args.use_tma:
        avg_time_us = run_tma(
            args.dtype, args.batch_size, args.seqlen_q, args.seqlen_k,
            args.num_head, args.head_dim, args.softmax_scale,
            args.m_block_size, args.n_block_size, args.num_mma_warps,
            args.kv_stages, args.is_causal, args.warmup_iterations,
            args.iterations, args.skip_ref_check, args.use_cold_l2,
        )
    else:
        avg_time_us = run(
            args.dtype, args.batch_size, args.seqlen_q, args.seqlen_k,
            args.num_head, args.head_dim, args.softmax_scale,
            args.m_block_size, args.n_block_size, args.num_threads,
            args.is_causal, args.warmup_iterations, args.iterations,
            args.skip_ref_check, args.use_cold_l2,
        )
    if avg_time_us is not None:
        print(f"avg execution time: {avg_time_us:.2f} us")
    print("PASS")
