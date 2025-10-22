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

from typing import Type
import argparse

import torch
import cuda.bindings.driver as cuda
import cutlass
import cutlass.torch as cutlass_torch
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack
from cutlass._mlir.dialects import llvm
import cutlass.pipeline as pipeline
import cutlass.utils as utils

"""
A HSTU attention forward pass example for NVIDIA Ampere SM80 architecture using Cute DSL, based on the example of flash_attention_v2 for Ampere.

The example showcases an implementation of HSTU attention(https://arxiv.org/abs/2402.17152) within generative recommender system. It utilize the formula: `mask(silu(q@k+rab))@v`. The implementation includes the following features:
- efficient fast sigmoid implementation
- block rasterization to improve L2 cache hit rate.
- The correct approach to verify the results of the HSTU attention with a Pytorch implementation.

To run this example:

.. code-block:: bash

    python examples/ampere/hstu_attention.py --batch_size 4 --seqlen_q 8192 --seqlen_kv 8192 --num_head 4 --head_dim 128 --m_block_size 128 --n_block_size 64 --is_causal --perf_test

The above example tests the performance of HSTU attention with batch size 4, sequence length 8192, 4 attention heads, and head dimension 128. The m_block_size is 128, and n_block_size is 64. The causal masking is enabled.

There are some constraints for this example:
* Only Float16 and BFloat16 are supported.
* The contiguous dimension of each tensor must be at least 16 bytes aligned.
* The values of `m_block_size`, `n_block_size`, and `head_dim` must be selected to stay within shared memory capacity limits.
* `m_block_size * 2` must be divisible by `num_threads`, otherwise the kernel will not be able to get the correct result.
* "seqlen_kv should be greater or equal to seqlen_q.
"""


class HSTUAttentionForwardAmpere(object):
    def __init__(
        self,
        dtype,
        batch_size,
        seqlen_q,
        seqlen_kv,
        num_head,
        head_dim,
        m_block_size=128,
        n_block_size=128,
        num_threads=128,
        enable_fast_sigmoid=False,
        enable_block_rasterization=False,
        is_causal=False,
    ):
        self._dtype = dtype
        self._batch_size = batch_size
        self._seqlen_q = seqlen_q
        self._seqlen_kv = seqlen_kv
        self._num_head = num_head
        self._head_dim = head_dim
        self._m_block_size = m_block_size
        self._n_block_size = n_block_size
        # padded head_dim to 32 for cta tile.
        self._head_dim_padded = (head_dim + 31) // 32 * 32
        self._num_threads = num_threads
        self._enable_fast_sigmoid = enable_fast_sigmoid
        self._enable_block_rasterization = enable_block_rasterization
        self._is_causal = is_causal
        assert self._dtype == cutlass.Float16 or self._dtype == cutlass.BFloat16, (
            "Only Float16 or BFloat16 is supported"
        )
        assert self._head_dim % 8 == 0, "head dim should be multiply of 8"
        assert self._num_threads % 32 == 0, "num_threads should be multiply of 32"
        assert self._m_block_size * self._head_dim_padded // self._num_threads >= 8, (
            "Small m_block_size and too many threads"
        )
        assert self._n_block_size * self._head_dim_padded // self._num_threads >= 8, (
            "Small n_block_size and too many threads"
        )
        assert seqlen_kv >= seqlen_q, "seqlen_kv should be greater or equal to seqlen_q"
        self.cta_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1, num_threads=num_threads
        )

    @cute.jit
    def __call__(
        self,
        mQ: cute.Tensor,
        mK: cute.Tensor,
        mV: cute.Tensor,
        mO: cute.Tensor,
        mRAB: cute.Tensor,
        stream: cuda.CUstream,
    ):
        """Configures and launches the HSTU attention kernel.
        mQ/mK/mV/mO/mRAB has same data types(supports fp16 and bf16).
        mQ has layout: (batch_size, seqlen_q, num_head, head_dim):(seqlen_q * num_head * head_dim, num_head * head_dim, head_dim, 1)
        mK/mV/mO has same layout: (batch_size, seqlen_kv, num_head, head_dim):(seqlen_kv * num_head * head_dim, num_head * head_dim, head_dim, 1)
        mRAB has layout: (batch_size, num_head, seqlen_q, seqlen_kv):(seqlen_q*seqlen_kv*num_head, seqlen_q*seqlen_kv, seqlen_kv, 1)

        Prepares the shared memory layout, tiled copy atoms, tiled mma and shared memory storage.
        Then launches the kernel function with the prepared parameters.

        :param mQ: query tensor
        :type mQ: cute.Tensor
        :param mK: key tensor
        :type mK: cute.Tensor
        :param mV: value tensor
        :type mV: cute.Tensor
        :param mO: output tensor
        :type mO: cute.Tensor
        :param mRAB: RAB tensor
        :type mRAB: cute.Tensor
        """
        # ///////////////////////////////////////////////////////////////////////////////
        # Shared memory layout: Q/K/V/RAB
        # ///////////////////////////////////////////////////////////////////////////////
        smem_k_block_size = 64 if self._head_dim_padded % 64 == 0 else 32
        swizzle_bits = 3 if smem_k_block_size == 64 else 2
        sQ_layout_atom = cute.make_composed_layout(
            cute.make_swizzle(swizzle_bits, 4, 3),
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
        sRAB_layout_atom = sQ_layout_atom
        sRAB_layout = cute.tile_to_shape(
            sRAB_layout_atom, (self._m_block_size, self._n_block_size), (0, 1)
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
            sRAB: cute.struct.Align[
                cute.struct.MemRange[self._dtype, cute.cosize(sRAB_layout)], 1024
            ]

        assert SharedStorage.size_in_bytes() < utils.get_smem_capacity_in_bytes(
            "sm_80"
        ), "insufficient shared memory"

        # ///////////////////////////////////////////////////////////////////////////////
        # GMEM Tiled copy:
        # ///////////////////////////////////////////////////////////////////////////////
        # Thread layouts for copies
        universal_copy_bits = 128
        async_copy_elems = universal_copy_bits // self._dtype.width
        # atom_async_copy: async copy atom for QKV load
        atom_async_copy = cute.make_copy_atom(
            cute.nvgpu.cpasync.CopyG2SOp(),
            self._dtype,
            num_bits_per_copy=universal_copy_bits,
        )
        # atom_universal_copy: universal copy atom for O store
        atom_universal_copy = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            self._dtype,
            num_bits_per_copy=universal_copy_bits,
        )
        # tQKV_layout: thread layout for QKV load
        tQKV_shape_dim_1 = sQ_layout_atom.outer.shape[1] // async_copy_elems
        tQKV_layout = cute.make_layout(
            (self._num_threads // tQKV_shape_dim_1, tQKV_shape_dim_1),
            stride=(tQKV_shape_dim_1, 1),
        )
        # tO_layout: thread layout for O store
        tO_layout = tQKV_layout

        # Value layouts for copies
        vQKV_layout = cute.make_layout((1, async_copy_elems))
        vO_layout = vQKV_layout

        # gmem_tiled_copy_QKV: tiled copy for QKV load
        gmem_tiled_copy_QKV = cute.make_tiled_copy_tv(
            atom_async_copy, tQKV_layout, vQKV_layout
        )

        # gmem_tiled_copy_O: tiled copy for O store
        gmem_tiled_copy_O = cute.make_tiled_copy_tv(
            atom_universal_copy, tO_layout, vO_layout
        )

        # ///////////////////////////////////////////////////////////////////////////////
        # Tiled mma
        # ///////////////////////////////////////////////////////////////////////////////
        tiled_mma = cute.make_tiled_mma(
            cute.nvgpu.warp.MmaF16BF16Op(self._dtype, cutlass.Float32, (16, 8, 16)),
            (self._num_threads // 32, 1, 1),
            permutation_mnk=(self._num_threads // 32 * 16, 16, 16),
        )

        # block rasterization
        if cutlass.const_expr(self._enable_block_rasterization):
            grid_dim = (
                self._batch_size,
                self._num_head,
                cute.ceil_div(mQ.shape[1], self._m_block_size),
            )
        else:
            grid_dim = (
                cute.ceil_div(mQ.shape[1], self._m_block_size),
                self._batch_size,
                self._num_head,
            )

        self.kernel(
            mQ,
            mK,
            mV,
            mO,
            mRAB,
            sQ_layout,
            sKV_layout,
            sRAB_layout,
            sO_layout,
            gmem_tiled_copy_QKV,
            gmem_tiled_copy_O,
            tiled_mma,
            SharedStorage,
        ).launch(
            grid=grid_dim,
            block=[self._num_threads, 1, 1],
            smem=SharedStorage.size_in_bytes(),
            stream=stream,
        )

    @cute.kernel
    def kernel(
        self,
        mQ: cute.Tensor,
        mK: cute.Tensor,
        mV: cute.Tensor,
        mO: cute.Tensor,
        mRAB: cute.Tensor,
        sQ_layout: cute.ComposedLayout,
        sKV_layout: cute.ComposedLayout,
        sRAB_layout: cute.ComposedLayout,
        sO_layout: cute.ComposedLayout,
        gmem_tiled_copy_QKV: cute.TiledCopy,
        gmem_tiled_copy_O: cute.TiledCopy,
        tiled_mma: cute.TiledMma,
        SharedStorage: cutlass.Constexpr,
    ):
        """Kernel function for HSTU attention.

        :param mQ: query tensor
        :type mQ: cute.Tensor
        :param mK: key tensor
        :type mK: cute.Tensor
        :param mV: value tensor
        :type mV: cute.Tensor
        :param mO: output tensor
        :type mO: cute.Tensor
        :param mRAB: RAB(Relative Attention Bias) tensor
        :type mRAB: cute.Tensor
        :param sQ_layout: shared memory layout for Q
        :type sQ_layout: cute.ComposedLayout
        :param sKV_layout: shared memory layout for K/V
        :type sKV_layout: cute.ComposedLayout
        :param sRAB_layout: shared memory layout for RAB
        :type sRAB_layout: cute.ComposedLayout
        :param sO_layout: shared memory layout for O
        :type sO_layout: cute.ComposedLayout
        :param gmem_tiled_copy_QKV: tiled copy for QKV load
        :type gmem_tiled_copy_QKV: cute.TiledCopy
        :param gmem_tiled_copy_O: tiled copy for O store
        :type gmem_tiled_copy_O: cute.TiledCopy
        :param tiled_mma: tiled mma
        :type tiled_mma: cute.TiledMma
        :param SharedStorage: shared storage
        :type SharedStorage: cutlass.Constexpr
        """
        # Thread index, block index
        tidx, _, _ = cute.arch.thread_idx()

        if cutlass.const_expr(self._enable_block_rasterization):
            batch_size, num_head, m_block = cute.arch.block_idx()
        else:
            m_block, batch_size, num_head = cute.arch.block_idx()

        # reverse the m_block index
        m_block = cute.ceil_div(mQ.shape[1], self._m_block_size) - m_block - 1

        if cutlass.const_expr(self._is_causal):
            n_block = (
                cute.ceil_div((m_block + 1) * self._m_block_size, self._n_block_size)
                - 1
            )  # for causal case, only process the first n_block tiles
        else:
            n_block = cute.ceil_div(mK.shape[1], self._n_block_size) - 1

        # ///////////////////////////////////////////////////////////////////////////////
        # Get the appropriate tiles for this thread block.
        # ///////////////////////////////////////////////////////////////////////////////
        # (m_block_size, head_dim)
        gQ = cute.local_tile(
            mQ[batch_size, None, num_head, None],
            (self._m_block_size, self._head_dim_padded),
            (m_block, 0),
        )
        # (n_block_size, head_dim, n_block)
        gK = cute.local_tile(
            mK[batch_size, None, num_head, None],
            (self._n_block_size, self._head_dim_padded),
            (None, 0),
        )
        # (n_block_size, head_dim, n_block)
        gV = cute.local_tile(
            mV[batch_size, None, num_head, None],
            (self._n_block_size, self._head_dim_padded),
            (None, 0),
        )
        # (m_block_size, n_block_size)
        gRAB = cute.local_tile(
            mRAB[batch_size, num_head, None, None],
            (self._m_block_size, self._n_block_size),
            (m_block, None),
        )

        # ///////////////////////////////////////////////////////////////////////////////
        # Get shared memory buffer
        # ///////////////////////////////////////////////////////////////////////////////
        smem = cutlass.utils.SmemAllocator()
        storage = smem.allocate(SharedStorage)
        sQ = storage.sQ.get_tensor(sQ_layout)
        sK = storage.sK.get_tensor(sKV_layout)
        sV = storage.sV.get_tensor(sKV_layout)
        sRAB = storage.sRAB.get_tensor(sRAB_layout)

        # Transpose view of V to tensor with layout (head_dim, n_block_size) for tiled mma
        sVt = cute.composition(
            sV,
            cute.make_layout(
                (self._head_dim_padded, self._n_block_size),
                stride=(self._n_block_size, 1),
            ),
        )

        gmem_thr_copy_QKV = gmem_tiled_copy_QKV.get_slice(tidx)
        # (CPY_Atom, CPY_M, CPY_K)
        tQgQ = gmem_thr_copy_QKV.partition_S(gQ)
        tQsQ = gmem_thr_copy_QKV.partition_D(sQ)
        # (CPY_Atom, CPY_N, CPY_K, n_block)
        tKgK = gmem_thr_copy_QKV.partition_S(gK)
        tKsK = gmem_thr_copy_QKV.partition_D(sK)
        # (CPY_Atom, CPY_N, CPY_K, n_block)
        tVgV = gmem_thr_copy_QKV.partition_S(gV)
        tVsV = gmem_thr_copy_QKV.partition_D(sV)
        # (CPY_Atom, CPY_M, CPY_N, n_block)
        tRABgRAB = gmem_tiled_copy_QKV.get_slice(tidx).partition_S(gRAB)
        tRabsRAB = gmem_tiled_copy_QKV.get_slice(tidx).partition_D(sRAB)

        # ///////////////////////////////////////////////////////////////////////////////
        # Tile MMA compute thread partitions and allocate accumulators
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
        # Smem copy atom tiling
        # ///////////////////////////////////////////////////////////////////////////////
        smem_copy_atom_Q = cute.make_copy_atom(
            cute.nvgpu.warp.LdMatrix8x8x16bOp(transpose=False, num_matrices=4),
            self._dtype,
        )
        smem_copy_atom_K = cute.make_copy_atom(
            cute.nvgpu.warp.LdMatrix8x8x16bOp(transpose=False, num_matrices=4),
            self._dtype,
        )
        smem_copy_atom_V = cute.make_copy_atom(
            cute.nvgpu.warp.LdMatrix8x8x16bOp(transpose=True, num_matrices=4),
            self._dtype,
        )
        smem_copy_atom_RAB = cute.make_copy_atom(
            cute.nvgpu.warp.LdMatrix8x8x16bOp(transpose=False, num_matrices=4),
            self._dtype,
        )
        smem_tiled_copy_Q = cute.make_tiled_copy_A(smem_copy_atom_Q, tiled_mma)
        smem_tiled_copy_K = cute.make_tiled_copy_B(smem_copy_atom_K, tiled_mma)
        smem_tiled_copy_V = cute.make_tiled_copy_B(smem_copy_atom_V, tiled_mma)
        smem_tiled_copy_RAB = cute.make_tiled_copy_C(smem_copy_atom_RAB, tiled_mma)

        smem_thr_copy_Q = smem_tiled_copy_Q.get_slice(tidx)
        smem_thr_copy_K = smem_tiled_copy_K.get_slice(tidx)
        smem_thr_copy_V = smem_tiled_copy_V.get_slice(tidx)
        smem_thr_copy_RAB = smem_tiled_copy_RAB.get_slice(tidx)

        tSsQ = smem_thr_copy_Q.partition_S(sQ)
        tSrQ_copy_view = smem_thr_copy_Q.retile(tSrQ)
        tSsK = smem_thr_copy_K.partition_S(sK)
        tSrK_copy_view = smem_thr_copy_K.retile(tSrK)
        tOsVt = smem_thr_copy_V.partition_S(sVt)
        tOrVt_copy_view = smem_thr_copy_V.retile(tOrVt)
        tSsRAB = smem_thr_copy_RAB.partition_S(sRAB)

        # ///////////////////////////////////////////////////////////////////////////////
        # Predicate: Mark indices that need to copy when problem_shape isn't a multiple
        # of tile_shape
        # ///////////////////////////////////////////////////////////////////////////////
        # Construct identity layout for Q, KV and RAB
        mcQ = cute.make_identity_tensor(mQ.layout.shape)
        mcKV = cute.make_identity_tensor(mK.layout.shape)
        mcRAB = cute.make_identity_tensor(mRAB.layout.shape)

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
        cRAB = cute.local_tile(
            mcRAB[batch_size, num_head, None, None],
            (self._m_block_size, self._n_block_size),
            (m_block, None),
        )

        # Repeat the partitioning with identity layouts
        tQcQ = gmem_thr_copy_QKV.partition_S(cQ)
        tKVcKV = gmem_thr_copy_QKV.partition_S(cKV)
        tRABcRAB = gmem_thr_copy_QKV.partition_S(cRAB)

        tQpQ = cute.make_rmem_tensor(
            cute.make_layout(
                (
                    tQsQ.shape[0][1],
                    cute.size(tQsQ, mode=[1]),
                    cute.size(tQsQ, mode=[2]),
                ),
                stride=(cute.size(tQsQ, mode=[2]), 0, 1),
            ),
            cutlass.Boolean,
        )
        tKVpKV = cute.make_rmem_tensor(
            cute.make_layout(
                (
                    tKsK.shape[0][1],
                    cute.size(tKsK, mode=[1]),
                    cute.size(tKsK, mode=[2]),
                ),
                stride=(cute.size(tKsK, mode=[2]), 0, 1),
            ),
            cutlass.Boolean,
        )

        # Set predicates for head_dim bounds, seqlen_q/k/v bounds is processed at the first tile.
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
        # Prefetch Prologue
        # ///////////////////////////////////////////////////////////////////////////////
        # Start async loads of the last mn-tile, where we take care of the mn residue
        for m in cutlass.range_constexpr(cute.size(tQsQ.shape[1])):
            if cute.elem_less(tQcQ[0, m, 0][1], mQ.layout.shape[1]):
                cute.copy(
                    gmem_tiled_copy_QKV,
                    tQgQ[None, m, None],
                    tQsQ[None, m, None],
                    pred=tQpQ[None, m, None],
                )
            else:
                # Clear the smem tiles to account for predicated off loads
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
                # Clear the smem tiles to account for predicated off loads
                tKsK[None, n, None].fill(0)

        for m in cutlass.range_constexpr(cute.size(tRABcRAB.shape[1])):
            for n in cutlass.range_constexpr(cute.size(tRABcRAB.shape[2])):
                if cute.elem_less(
                    tRABcRAB[0, m, n, n_block][1], mRAB.layout.shape[2]
                ) and cute.elem_less(
                    tRABcRAB[0, m, n, n_block][2], mRAB.layout.shape[3]
                ):
                    cute.copy(
                        gmem_tiled_copy_QKV,
                        tRABgRAB[None, m, n, n_block],
                        tRabsRAB[None, m, n],
                    )
                else:
                    # Clear the smem tiles to account for predicated off loads
                    tRabsRAB[None, m, n].fill(0)
        cute.arch.cp_async_commit_group()

        # ///////////////////////////////////////////////////////////////////////////////
        # Mainloop
        # ///////////////////////////////////////////////////////////////////////////////
        for n_block_idx in range(n_block, -1, -1):
            # wait for smem tile QK before mma caculation for S
            cute.arch.cp_async_wait_group(0)
            self.cta_sync_barrier.arrive_and_wait()

            if n_block_idx == n_block:
                for n in cutlass.range_constexpr(cute.size(tVsV.shape[1])):
                    if cute.elem_less(tKVcKV[0, n, 0][1], mV.layout.shape[1]):
                        cute.copy(
                            gmem_tiled_copy_QKV,
                            tVgV[None, n, None, n_block_idx],
                            tVsV[None, n, None],
                            pred=tKVpKV[None, n, None],
                        )
                    else:
                        tVsV[None, n, None].fill(0)
            else:
                cute.copy(
                    gmem_tiled_copy_QKV,
                    tVgV[None, None, None, n_block_idx],
                    tVsV[None, None, None],
                    pred=tKVpKV[None, None, None],
                )
            cute.arch.cp_async_commit_group()

            acc_shape_S = thr_mma.partition_shape_C(
                (self._m_block_size, self._n_block_size)
            )
            acc_S = cute.make_rmem_tensor(acc_shape_S, cutlass.Float32)

            rRAB_shape_S = thr_mma.partition_shape_C(
                (self._m_block_size, self._n_block_size)
            )
            rRAB = cute.make_rmem_tensor(rRAB_shape_S, self._dtype)
            tSrRAB_copy_view = smem_thr_copy_RAB.retile(rRAB)
            cute.copy(
                smem_tiled_copy_RAB,
                tSsRAB[None, None, None],
                tSrRAB_copy_view[None, None, None],
            )
            acc_S.store(rRAB.load().to(cutlass.Float32))

            # ///////////////////////////////////////////////////////////////////////////////
            # S gemm calculation
            # ///////////////////////////////////////////////////////////////////////////////
            # ldmatrix first QK k-block for mma
            cute.copy(
                smem_tiled_copy_Q,
                tSsQ[None, None, 0],
                tSrQ_copy_view[None, None, 0],
            )
            cute.copy(
                smem_tiled_copy_K,
                tSsK[None, None, 0],
                tSrK_copy_view[None, None, 0],
            )
            for k in cutlass.range_constexpr(0, cute.size(tSsQ.shape[2])):
                # ldmatrix next QK k-block for mma
                if k < cute.size(tSsQ.shape[2]) - 1:
                    cute.copy(
                        smem_tiled_copy_Q,
                        tSsQ[None, None, k + 1],
                        tSrQ_copy_view[None, None, k + 1],
                    )
                    cute.copy(
                        smem_tiled_copy_K,
                        tSsK[None, None, k + 1],
                        tSrK_copy_view[None, None, k + 1],
                    )
                # mma for S=Q@K
                cute.gemm(
                    tiled_mma,
                    acc_S,
                    tSrQ[None, None, k],
                    tSrK[None, None, k],
                    acc_S,
                )

            # wait for smem tile V for O
            cute.arch.cp_async_wait_group(0)
            self.cta_sync_barrier.arrive_and_wait()

            if n_block_idx > 0:
                cute.copy(
                    gmem_tiled_copy_QKV,
                    tKgK[None, None, None, n_block_idx - 1],
                    tKsK[None, None, None],
                    pred=tKVpKV[None, None, None],
                )
                # m residue handling for RAB
                for m in cutlass.range_constexpr(cute.size(tRABcRAB.shape[1])):
                    if cute.elem_less(
                        tRABcRAB[0, m, 0, n_block][1], mRAB.layout.shape[2]
                    ):
                        cute.copy(
                            gmem_tiled_copy_QKV,
                            tRABgRAB[None, m, None, n_block_idx - 1],
                            tRabsRAB[None, m, None],
                        )
                    else:
                        tRabsRAB[None, m, None].fill(0)

                cute.arch.cp_async_commit_group()

            # ///////////////////////////////////////////////////////////////////////////////
            # silu activation
            # ///////////////////////////////////////////////////////////////////////////////
            if self._enable_fast_sigmoid:
                t1 = acc_S.load()
                t2 = t1 * 0.5
                acc_S.store(t2)
                for i in cutlass.range_constexpr(cute.size(acc_S.shape[0])):
                    for j in cutlass.range_constexpr(cute.size(acc_S.shape[1])):
                        for k in cutlass.range_constexpr(cute.size(acc_S.shape[2])):
                            ret = llvm.inline_asm(
                                cutlass.Float32.mlir_type,
                                [acc_S[i, j, k].ir_value()],
                                "tanh.approx.f32 $0, $1;",
                                "=f,f",
                                has_side_effects=False,
                                is_align_stack=False,
                                asm_dialect=llvm.AsmDialect.AD_ATT,
                            )
                            acc_S[i, j, k] = ret
                t3 = acc_S.load()
                t4 = t2 * t3 + t2
                acc_S.store(t4)
            else:
                LOG2_E = 1.4426950408889634074
                t1 = acc_S.load()
                t2 = t1 * -LOG2_E
                t3 = cute.math.exp2(t2, fastmath=True) + 1.0
                t4 = t1 / t3
                acc_S.store(t4)

            mACC = cute.make_identity_tensor(
                (mRAB.layout.shape[2], mRAB.layout.shape[3])
            )  # (seqlen_q, seqlen_kv)
            cACC = cute.local_tile(
                mACC[None, None],
                (self._m_block_size, self._n_block_size),
                (m_block, n_block_idx),
            )

            if self._is_causal and (n_block - n_block_idx) < cute.ceil_div(
                self._m_block_size, self._n_block_size
            ):
                tACCcACC = thr_mma.partition_C(cACC)
                for i in cutlass.range_constexpr(cute.size(tACCcACC.shape[0])):
                    for j in cutlass.range_constexpr(cute.size(tACCcACC.shape[1])):
                        for k in cutlass.range_constexpr(cute.size(tACCcACC.shape[2])):
                            if cute.elem_less(
                                tACCcACC[i, j, k][0], tACCcACC[i, j, k][1]
                            ):
                                acc_S[i, j, k] = 0.0

            rP = cute.make_rmem_tensor_like(acc_S, self._dtype)
            rP.store(acc_S.load().to(self._dtype))

            # ///////////////////////////////////////////////////////////////////////////////
            # O gemm calculation
            # ///////////////////////////////////////////////////////////////////////////////
            # Convert layout of acc_S to gemm O accept layout.
            # Due to the mma instruction shape is 16x8x16, we need to convert from (4, MMA_M, MMA_N) to ((4, 2), MMA_M, MMA_N / 2)
            # (4, MMA_M, MMA_N) -> (4, MMA_M, (2, MMA_N / 2))
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
            tOrP = cute.make_tensor(rP.iterator, rP_mma_view)

            # ldmatrix first V k-block for mma
            cute.copy(
                smem_tiled_copy_V,
                tOsVt[None, None, 0],
                tOrVt_copy_view[None, None, 0],
            )
            for k in cutlass.range_constexpr(0, cute.size(tOrP.shape[2])):
                # ldmatrix next V k-block for mma
                if k < cute.size(tOrP.shape[2]) - 1:
                    cute.copy(
                        smem_tiled_copy_V,
                        tOsVt[None, None, k + 1],
                        tOrVt_copy_view[None, None, k + 1],
                    )
                # mma for O=P@V
                cute.gemm(
                    tiled_mma,
                    acc_O,
                    tOrP[None, None, k],
                    tOrVt[None, None, k],
                    acc_O,
                )

        # ///////////////////////////////////////////////////////////////////////////////
        # Epilogue
        # ///////////////////////////////////////////////////////////////////////////////
        # store acc_O
        rO = cute.make_rmem_tensor(acc_O.layout, self._dtype)
        rO.store(acc_O.load().to(self._dtype))
        # reuse sQ's data iterator
        sO_iter = cute.recast_ptr(sQ.iterator, sO_layout.inner)
        sO = cute.make_tensor(sO_iter, sO_layout.outer)
        smem_copy_atom_O = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), self._dtype
        )
        smem_tiled_copy_O = cute.make_tiled_copy_C(smem_copy_atom_O, tiled_mma)
        smem_thr_copy_O = smem_tiled_copy_O.get_slice(tidx)
        taccOrO = smem_thr_copy_O.retile(rO)
        taccOsO = smem_thr_copy_O.partition_D(sO)
        # copy acc O from rmem to smem with sts.32(auto vectorization)
        cute.copy(
            smem_copy_atom_O,
            taccOrO,
            taccOsO,
        )
        gO = cute.local_tile(
            mO[batch_size, None, num_head, None],
            (self._m_block_size, self._head_dim_padded),
            (m_block, 0),
        )

        gmem_thr_copy_O = gmem_tiled_copy_O.get_slice(tidx)
        tOsO = gmem_thr_copy_O.partition_S(sO)
        tOgO = gmem_thr_copy_O.partition_D(gO)
        tOrO = cute.make_fragment_like(tOgO, self._dtype)
        # sync before all sts are done.
        self.cta_sync_barrier.arrive_and_wait()
        # load acc O from smem to rmem for wider vectorization
        cute.copy(
            gmem_tiled_copy_O,
            tOsO,
            tOrO,
        )
        # predicate for O
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
        # copy acc O from rmem to gmem
        for rest_m in cutlass.range_constexpr(cute.size(tOpO.shape[1])):
            if cute.elem_less(tOcO[0, rest_m, 0][1], mO.layout.shape[1]):
                cute.copy(
                    gmem_tiled_copy_O,
                    tOrO[None, rest_m, None],
                    tOgO[None, rest_m, None],
                    pred=tOpO[None, rest_m, None],
                )


def run_pytorch_hstu_test(
    dtype: torch.dtype,
    q: torch.Tensor,
    k: torch.Tensor,
    v: torch.Tensor,
    rab: torch.Tensor,
    is_causal: bool,
):
    """Generate the reference output of the HSTU attention with Pytorch.

    :param dtype: data type of the input tensors
    :type dtype: torch.dtype
    :param q: query tensor
    :type q: torch.Tensor
    :param k: key tensor
    :type k: torch.Tensor
    :param v: value tensor
    :type v: torch.Tensor
    :param rab: RAB tensor
    :type rab: torch.Tensor
    :param is_causal: whether to use causal masking
    :type is_causal: bool
    """
    q = q.to(dtype)
    k = k.to(dtype)
    v = v.to(dtype)
    rab = rab.to(dtype)

    s_ = torch.matmul(q, k.transpose(-2, -1)) + rab
    s_ = torch.nn.functional.silu(s_)
    if is_causal:
        mask = torch.ones(1, 1, q.shape[2], k.shape[2], dtype=dtype)
        mask = torch.tril(mask)
        s_ = s_ * mask.cuda()

    o = torch.matmul(s_, v).permute(0, 2, 1, 3).contiguous()
    return o


def run(
    dtype: Type[cutlass.Numeric],
    batch_size: int,
    seqlen_q: int,
    seqlen_kv: int,
    num_head: int,
    head_dim: int,
    m_block_size: int = 128,
    n_block_size: int = 128,
    num_threads: int = 128,
    enable_fast_sigmoid: bool = False,
    enable_block_rasterization: bool = False,
    is_causal: bool = False,
    perf_test: bool = False,
    **kwargs,
):
    """
    Run the HSTU attention kernel.

    :param dtype: data type of the input tensors
    :type dtype: Type[cutlass.Numeric]
    :param batch_size: batch size
    :type batch_size: int
    :param seqlen_q: sequence length of the query
    :type seqlen_q: int
    :param seqlen_kv: sequence length of the key
    :type seqlen_kv: int
    :param num_head: number of attention heads
    :type num_head: int
    :param head_dim: dimension of the head
    :type head_dim: int
    :param m_block_size: block size for the m dimension of computation
    :type m_block_size: int
    :param n_block_size: block size for the n dimension of computation
    :type n_block_size: int
    :param num_threads: number of threads
    :type num_threads: int
    :param enable_fast_sigmoid: whether to use fast sigmoid
    :type enable_fast_sigmoid: bool
    :param enable_block_rasterization: whether to use block rasterization
    :type enable_block_rasterization: bool
    :param is_causal: whether to use causal masking
    :type is_causal: bool
    """
    assert dtype == cutlass.Float16 or dtype == cutlass.BFloat16

    torch_stream = torch.cuda.current_stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    print("Running Ampere SM80 HSTUAttentionForward test with:")
    print("batch_size: ", batch_size)
    print("seqlen_q: ", seqlen_q)
    print("seqlen_kv: ", seqlen_kv)
    print("num_head: ", num_head)
    print("head_dim: ", head_dim)
    print("m_block_size: ", m_block_size)
    print("n_block_size: ", n_block_size)
    print("num_threads: ", num_threads)
    print("is_causal: ", is_causal)
    print("enable_fast_sigmoid: ", enable_fast_sigmoid)
    print("enable_block_rasterization: ", enable_block_rasterization)
    print("dtype: ", dtype)

    # reduced tensor num and iter num for functionality test
    TENSOR_NUM = 1
    ITER_NUM = 1
    WARMUP_NUM = 0
    if perf_test:
        TENSOR_NUM = 3
        ITER_NUM = 100
        WARMUP_NUM = 10

    # Create tensor Q/K/V/O
    qs = [
        torch.randn(
            batch_size, seqlen_q, num_head, head_dim, dtype=cutlass_torch.dtype(dtype)
        ).cuda()
        for _ in range(TENSOR_NUM)
    ]
    ks = [
        torch.randn(
            batch_size, seqlen_kv, num_head, head_dim, dtype=cutlass_torch.dtype(dtype)
        ).cuda()
        for _ in range(TENSOR_NUM)
    ]
    vs = [
        torch.randn(
            batch_size, seqlen_kv, num_head, head_dim, dtype=cutlass_torch.dtype(dtype)
        ).cuda()
        for _ in range(TENSOR_NUM)
    ]
    os = [
        torch.randn(
            batch_size, seqlen_q, num_head, head_dim, dtype=cutlass_torch.dtype(dtype)
        ).cuda()
        for _ in range(TENSOR_NUM)
    ]

    rabs = [
        torch.randn(
            batch_size, num_head, seqlen_q, seqlen_kv, dtype=cutlass_torch.dtype(dtype)
        ).cuda()
        for _ in range(TENSOR_NUM)
    ]

    fa2_fwd = HSTUAttentionForwardAmpere(
        dtype,
        batch_size,
        seqlen_q,
        seqlen_kv,
        num_head,
        head_dim,
        m_block_size,
        n_block_size,
        num_threads,
        enable_fast_sigmoid=enable_fast_sigmoid,
        enable_block_rasterization=enable_block_rasterization,
        is_causal=is_causal,
    )
    # assume input is 16B align.
    mqs = [
        (
            from_dlpack(qs[i], assumed_align=16)
            .mark_layout_dynamic(leading_dim=3)
            .mark_compact_shape_dynamic(
                mode=3,
                stride_order=qs[i].dim_order(),
                divisibility=(128 // dtype.width),
            )
        )
        for i in range(TENSOR_NUM)
    ]
    mks = [
        (
            from_dlpack(ks[i], assumed_align=16)
            .mark_layout_dynamic(leading_dim=3)
            .mark_compact_shape_dynamic(
                mode=3,
                stride_order=ks[i].dim_order(),
                divisibility=(128 // dtype.width),
            )
        )
        for i in range(TENSOR_NUM)
    ]
    mvs = [
        (
            from_dlpack(vs[i], assumed_align=16)
            .mark_layout_dynamic(leading_dim=3)
            .mark_compact_shape_dynamic(
                mode=3,
                stride_order=vs[i].dim_order(),
                divisibility=(128 // dtype.width),
            )
        )
        for i in range(TENSOR_NUM)
    ]
    mos = [
        (
            from_dlpack(os[i], assumed_align=16)
            .mark_layout_dynamic(leading_dim=3)
            .mark_compact_shape_dynamic(
                mode=3,
                stride_order=os[i].dim_order(),
                divisibility=(128 // dtype.width),
            )
        )
        for i in range(TENSOR_NUM)
    ]
    mrabs = [
        (
            from_dlpack(rabs[i], assumed_align=16)
            .mark_layout_dynamic(leading_dim=3)
            .mark_compact_shape_dynamic(
                mode=3,
                stride_order=rabs[i].dim_order(),
                divisibility=(128 // dtype.width),
            )
        )
        for i in range(TENSOR_NUM)
    ]
    start_event = torch.cuda.Event(enable_timing=True)
    end_event = torch.cuda.Event(enable_timing=True)

    kernel = cute.compile(
        fa2_fwd,
        mqs[0],
        mks[0],
        mvs[0],
        mos[0],
        mrabs[0],
        stream,
    )

    for i in range(0, ITER_NUM):
        if i == WARMUP_NUM:
            start_event.record(torch_stream)
        # Run the kernel
        kernel(
            mqs[i % TENSOR_NUM],
            mks[i % TENSOR_NUM],
            mvs[i % TENSOR_NUM],
            mos[i % TENSOR_NUM],
            mrabs[i % TENSOR_NUM],
            stream,
        )

    end_event.record(torch_stream)
    torch.cuda.synchronize(torch_stream)

    elapsed_time = start_event.elapsed_time(end_event)
    elapsed_time_avg = elapsed_time / (ITER_NUM - WARMUP_NUM)

    LAST_USED_TENSOR = (ITER_NUM - 1) % TENSOR_NUM
    q = qs[LAST_USED_TENSOR].permute(0, 2, 1, 3).contiguous()
    k = ks[LAST_USED_TENSOR].permute(0, 2, 1, 3).contiguous()
    v = vs[LAST_USED_TENSOR].permute(0, 2, 1, 3).contiguous()
    rab = rabs[LAST_USED_TENSOR]

    kernel_out = os[LAST_USED_TENSOR].cpu()

    with torch.cuda.stream(torch_stream):
        ref_bf16 = run_pytorch_hstu_test(torch.bfloat16, q, k, v, rab, is_causal).cpu()
        ref_fp32 = run_pytorch_hstu_test(torch.float32, q, k, v, rab, is_causal).cpu()
    torch.cuda.synchronize(torch_stream)

    assert (kernel_out - ref_fp32).abs().max().item() <= 4 * (
        ref_bf16 - ref_fp32
    ).abs().max().item()
    print("Results verified successfully!")

    if perf_test:
        print(f"Elapsed time: {elapsed_time_avg:.3f} ms")
    return elapsed_time_avg * 1000  # return in microseconds


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="example of HSTU attention with CuTe")
    parser.add_argument("--dtype", type=cutlass.dtype, default=cutlass.BFloat16)
    parser.add_argument("--batch_size", type=int, default=4)
    parser.add_argument("--seqlen_q", type=int, default=2048)
    parser.add_argument("--seqlen_kv", type=int, default=2048)
    parser.add_argument("--num_head", type=int, default=4)
    parser.add_argument("--head_dim", type=int, default=128)
    parser.add_argument("--m_block_size", type=int, default=64)
    parser.add_argument("--n_block_size", type=int, default=64)
    parser.add_argument("--num_threads", type=int, default=128)
    parser.add_argument(
        "--no_fast_sigmoid", action="store_false", dest="enable_fast_sigmoid"
    )
    parser.add_argument(
        "--no_block_rasterization",
        action="store_false",
        dest="enable_block_rasterization",
    )
    parser.add_argument("--is_causal", action="store_true", dest="is_causal")
    parser.add_argument("--perf_test", action="store_true", dest="perf_test")
    args = parser.parse_args()

    run(
        args.dtype,
        args.batch_size,
        args.seqlen_q,
        args.seqlen_kv,
        args.num_head,
        args.head_dim,
        args.m_block_size,
        args.n_block_size,
        args.num_threads,
        args.enable_fast_sigmoid,
        args.enable_block_rasterization,
        args.is_causal,
        args.perf_test,
    )
    print("PASS")
