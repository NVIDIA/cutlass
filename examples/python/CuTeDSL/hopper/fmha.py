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

"""
A fused multi-head attention (FMHA) example for the NVIDIA Hopper SM90 architecture using CUTE DSL

This example demonstrates an implementation of fused multi-head attention using a TMA + Hopper SM90
TensorCore warp-specialized kernel. The implementation integrates the Q*K^T matrix multiplication,
softmax normalization, and softmax(Q*K^T)*V into a single kernel, avoiding intermediate data movement between
global memory and shared memory, thus improving computational efficiency.

The kernel implements key optimizations including:
- Warp specialization for different computation phases (load, MMA)
- 2 MMA WarpGroup for compute
- Pipeline stages between different warps for overlapping computation and memory access
- Support for different precision data types
- Optional causal masking for autoregressive models
- Sliding window attention masking for efficient long sequence processing

To run this example:

.. code-block:: bash

    python examples/hopper/fmha.py                                        \
      --qk_acc_dtype Float32 --pv_acc_dtype Float32                       \
      --mma_tiler_mn 64,128                                              \
      --q_shape 4,1024,8,64 --k_shape 4,1024,8,64                         \
      --is_persistent

The above example runs FMHA with batch size 4, sequence length 1024, 8 attention heads, and head
dimension 64. The Hopper MMA tile shape is (64, 128), and the kernel uses fp16 for input/output
with fp32 for accumulation.

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/hopper/fmha.py                                    \
      --qk_acc_dtype Float32 --pv_acc_dtype Float32                       \
      --mma_tiler_mn 64,128                                              \
      --q_shape 4,1024,8,64 --k_shape 4,1024,8,64                         \
      --is_persistent --warmup_iterations 10                              \
      --iterations 10 --skip_ref_check

Constraints for this example:
* Supported head dimensions: 32, 64, 128, 256
  ** 256 for `mma_tiler_mn` shoule be (64, 256) with non-persistent mode(not present `--is_persistent` in command line
* Number of heads in Q must equal with  number of heads in K
* For causal masking, use --is_causal (note: specify without =True/False)
* For persistent scheduling, use --is_persistent (note: specify without =True/False)
* For sliding window, use --window_size x,y where x is left window size and y is right window size
"""

import argparse
import math
import os
import sys
import time
from typing import Type, Tuple, Optional

import torch


import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute

import cutlass.cute.testing as testing
import cutlass.cute.nvgpu.warpgroup as warpgroup
import cutlass.utils as utils
import cutlass.pipeline as pipeline
import cutlass.torch as cutlass_torch
from cutlass._mlir.dialects import math as _math

import cutlass.utils.hopper_helpers as sm90_utils
from cutlass.cute.runtime import from_dlpack

current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(current_dir, ".."))
from utils import fmha_helpers as fmha_utils


class HopperFusedMultiHeadAttentionForward:
    def __init__(
        self,
        qk_acc_dtype,
        pv_acc_dtype,
        mma_tiler,
        is_persistent,
        mask_type: fmha_utils.MaskEnum,
    ):
        """Initializes the configuration for a Hopper Fused Multi-Head Attention (FMHA) kernel.

        This configuration includes several key aspects:

        1.  Data Type Settings:
            - qk_acc_dtype: Data type for Q*K^T matrix multiplication accumulator
            - pv_acc_dtype: Data type for P*V matrix multiplication accumulator

        2.  MMA Instruction Settings:
            - mma_tiler: The (M, N, K) shape of the MMA instruction unit
            - qk_mma_tiler: MMA shape for Q*K^T computation
            - pv_mma_tiler: MMA shape for P*V computation

        3.  Kernel Execution Mode:
            - is_persistent: Boolean indicating whether to use persistent kernel mode
            - mask_type: Specifies the type of mask to use (no mask, residual mask, or causal mask)
            - window_size_left/right: Sliding window parameters for attention masking

        :param qk_acc_dtype: Data type for Q*K^T matrix multiplication accumulator
        :type qk_acc_dtype: Type[cutlass.Numeric]
        :param pv_acc_dtype: Data type for P*V matrix multiplication accumulator
        :type pv_acc_dtype: Type[cutlass.Numeric]
        :param mma_tiler: The (M, N, K) shape of the MMA instruction
        :type mma_tiler: Tuple[int, int, int]
        :param is_persistent: Whether to use persistent kernel mode
        :type is_persistent: bool
        :param mask_type: Type of mask to use
        :type mask_type: fmha_utils.MaskEnum
        """

        self.num_mma_warp_groups = 2
        self.qk_acc_dtype = qk_acc_dtype
        self.pv_acc_dtype = pv_acc_dtype
        self.cta_tiler = self.cta_tile_shape_mnk = (
            mma_tiler[0] * self.num_mma_warp_groups,
            mma_tiler[1],
            mma_tiler[2],
        )

        self.qk_mma_tiler = (
            mma_tiler[0],
            mma_tiler[1],
            mma_tiler[2],
        )

        self.pv_mma_tiler = (
            self.qk_mma_tiler[0],
            self.qk_mma_tiler[2],
            self.qk_mma_tiler[1],
        )

        self.cluster_shape_mn = (1, 1)
        self.atom_layout_mnk = (1, 1, 1)
        self.is_persistent = is_persistent
        self.mask_type = mask_type
        self.threads_per_warp = 32
        self.num_threads_per_warp_group = 128
        self.num_warps_per_warp_group = (
            self.num_threads_per_warp_group / self.threads_per_warp
        )

        # WarpGroupRole
        self.load_warp_group_id = 0
        self.compute_epilogue_0_warp_group_id = 1
        self.compute_epilogue_1_warp_group_id = 2
        # ProducerWarpRole
        self.producer_warp_loadkv_id = 1

        self.num_regs_load = 40 - 2 * 8
        num_load_warp_groups = 1
        self.num_threads_per_warp_group = 128
        max_threads_per_block = (
            self.num_mma_warp_groups + num_load_warp_groups
        ) * self.num_threads_per_warp_group
        self.threads_per_cta = max_threads_per_block
        self.num_regs_mma = 240
        self.buffer_align_bytes = 1024

    def _setup_attributes(self):
        self.q_stage = 2
        self.kv_stage = 5
        self.epi_stage = 2

    @cute.jit
    def __call__(
        self,
        q: cute.Tensor,
        k: cute.Tensor,
        v: cute.Tensor,
        o: cute.Tensor,
        lse: cute.Tensor,
        scale_softmax_log2: cutlass.Float32,
        scale_softmax: cutlass.Float32,
        scale_output: cutlass.Float32,
        window_size_left: Optional[cutlass.Int32],
        window_size_right: Optional[cutlass.Int32],
        stream: cuda.CUstream,
    ):
        # setup static attributes before smem/grid/tma computation
        self.q_dtype = q.element_type
        self.k_dtype = k.element_type
        self.v_dtype = v.element_type
        self.o_dtype = o.element_type

        # (s, d, ((h_r, h_k), b)), 0-stride for h_r to broadcast
        k = cute.make_tensor(
            k.iterator,
            cute.make_layout(
                (k.shape[0], k.shape[1], ((q.shape[2], k.shape[3]), k.shape[4])),
                stride=(
                    k.stride[0],
                    k.stride[1],
                    ((0, k.stride[3]), k.stride[4]),
                ),
            ),
        )

        # (d, s, ((h_r, h_k), b)), 0-stride for h_r to broadcast
        v = cute.make_tensor(
            v.iterator,
            cute.make_layout(
                (v.shape[1], v.shape[0], ((q.shape[2], v.shape[3]), v.shape[4])),
                stride=(
                    v.stride[1],
                    v.stride[0],
                    ((0, v.stride[3]), v.stride[4]),
                ),
            ),
        )

        # (s, d, ((h_r, h_k), b))
        q = cute.group_modes(cute.group_modes(q, begin=2, end=4), begin=2, end=4)
        o = cute.group_modes(cute.group_modes(o, begin=2, end=4), begin=2, end=4)

        # (s, ((h_r, h_k), b))
        lse = cute.make_tensor(
            lse.iterator,
            cute.make_layout(
                (
                    lse.shape[0],
                    self.pv_mma_tiler[1],
                    ((lse.shape[2], lse.shape[3]), lse.shape[4]),
                ),
                stride=(
                    lse.stride[0],
                    0,
                    ((lse.stride[2], lse.stride[3]), lse.stride[4]),
                ),
            ),
        )

        if cutlass.const_expr(self.q_dtype != self.k_dtype):
            raise TypeError(f"Type mismatch: {self.q_dtype} != {self.k_dtype}")
        if cutlass.const_expr(self.q_dtype != self.v_dtype):
            raise TypeError(f"Type mismatch: {self.q_dtype} != {self.v_dtype}")

        if cutlass.const_expr(q.leading_dim != 1):  # k-major
            raise RuntimeError("The layout of q is not supported")

        if cutlass.const_expr(k.leading_dim != 1):  # k-major
            raise RuntimeError("The layout of k is not supported")

        self._setup_attributes()

        tile_shape_mnk = self.cta_tiler
        self.epi_tile = sm90_utils.compute_tile_shape_or_override(
            tile_shape_mnk, self.o_dtype
        )

        self.q_layout = utils.LayoutEnum.from_tensor(q)
        self.k_layout = utils.LayoutEnum.from_tensor(k)
        self.v_layout = utils.LayoutEnum.from_tensor(v)
        self.o_layout = utils.LayoutEnum.from_tensor(o)

        self.q_major_mode = self.q_layout.sm90_mma_major_mode()
        self.k_major_mode = self.k_layout.sm90_mma_major_mode()
        self.v_major_mode = self.v_layout.sm90_mma_major_mode()

        p_major_mode = cute.nvgpu.warpgroup.OperandMajorMode.K
        qk_tiled_mma = sm90_utils.make_trivial_tiled_mma(
            self.q_dtype,
            self.k_dtype,
            self.q_major_mode,
            self.k_major_mode,
            self.qk_acc_dtype,
            self.atom_layout_mnk,
            self.qk_mma_tiler[:2],
        )

        pv_tiled_mma = sm90_utils.make_trivial_tiled_mma(
            self.v_dtype,
            self.v_dtype,
            p_major_mode,
            self.v_major_mode,
            self.pv_acc_dtype,
            self.atom_layout_mnk,
            self.pv_mma_tiler[:2],
            warpgroup.OperandSource.RMEM,
        )

        self.cluster_shape_mnk = (*self.cluster_shape_mn, 1)
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(self.cluster_shape_mnk),
            (qk_tiled_mma.thr_id.shape,),
        )

        q_smem_layout_staged = sm90_utils.make_smem_layout_a(
            self.q_layout,
            self.qk_mma_tiler,
            self.q_dtype,
            self.q_stage,
        )

        k_smem_layout_staged = sm90_utils.make_smem_layout_b(
            self.k_layout,
            self.qk_mma_tiler,
            self.k_dtype,
            self.kv_stage,
        )

        v_smem_layout_staged = sm90_utils.make_smem_layout_b(
            self.v_layout,
            self.pv_mma_tiler,
            self.v_dtype,
            self.kv_stage,
        )

        o_smem_layout_staged = sm90_utils.make_smem_layout_epi(
            self.o_dtype,
            self.o_layout,
            self.epi_tile,
            self.epi_stage,
            cute.append(
                cute.append(self.epi_tile, self.epi_stage), self.num_mma_warp_groups
            ),
            smem_order=(1, 0, 2, 3) if self.o_layout.is_m_major_c() else (0, 1, 2, 3),
        )

        # TMA load for Q
        q_smem_layout = cute.slice_(q_smem_layout_staged, (None, None, 0))
        tma_atom_q, tma_tensor_q = self._make_tma_atoms_and_tensors(
            q,
            q_smem_layout_staged,
            (self.qk_mma_tiler[0], self.qk_mma_tiler[2]),
            self.cluster_shape_mnk[1],
        )

        # TMA load for K
        k_smem_layout = cute.slice_(k_smem_layout_staged, (None, None, 0))
        tma_atom_k, tma_tensor_k = self._make_tma_atoms_and_tensors(
            k,
            k_smem_layout_staged,
            (self.qk_mma_tiler[1], self.qk_mma_tiler[2]),
            self.cluster_shape_mnk[0],
        )

        # TMA load for V
        pv_tile_shape_mnk = (
            self.qk_mma_tiler[0],
            self.qk_mma_tiler[2],
            self.qk_mma_tiler[1],
        )
        tma_atom_v, tma_tensor_v = self._make_tma_atoms_and_tensors(
            v,
            v_smem_layout_staged,
            (pv_tile_shape_mnk[1], pv_tile_shape_mnk[2]),
            self.cluster_shape_mnk[0],
        )

        o_cta_v_layout = cute.composition(
            cute.make_identity_layout(o.shape), self.epi_tile
        )
        o_smem_layout = cute.slice_(o_smem_layout_staged, (None, None, 0, 0))

        tma_store_op = cute.nvgpu.cpasync.CopyBulkTensorTileS2GOp()
        tma_atom_o, tma_tensor_o = cute.nvgpu.cpasync.make_tiled_tma_atom(
            tma_store_op,
            o,
            o_smem_layout,
            self.epi_tile,
        )

        q_copy_size = cute.size_in_bytes(self.q_dtype, q_smem_layout)
        k_copy_size = cute.size_in_bytes(self.k_dtype, k_smem_layout)
        self.tma_copy_q_bytes = q_copy_size
        self.tma_copy_kv_bytes = k_copy_size

        self.tile_sched_params, grid = fmha_utils.compute_grid(
            o.shape,
            self.cta_tiler,
            self.is_persistent,
        )

        @cute.struct
        class SharedStorage:
            # 2 for full/empty
            load_q_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.q_stage * 2]
            load_kv_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.kv_stage * 2]
            MathWarpGroupOrderBarrier: cute.struct.MemRange[
                cutlass.Int64, self.num_mma_warp_groups
            ]

            sO: cute.struct.Align[
                cute.struct.MemRange[
                    self.o_dtype,
                    (
                        cute.cosize(o_smem_layout_staged)
                        if cutlass.const_expr(self.is_persistent)
                        else 0
                    ),
                ],
                self.buffer_align_bytes,
            ]
            sQ: cute.struct.Align[
                cute.struct.MemRange[self.q_dtype, cute.cosize(q_smem_layout_staged)],
                self.buffer_align_bytes,
            ]
            sK: cute.struct.Align[
                cute.struct.MemRange[self.k_dtype, cute.cosize(k_smem_layout_staged)],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        # Launch the kernel synchronously
        self.kernel(
            qk_tiled_mma,
            pv_tiled_mma,
            tma_atom_q,
            tma_tensor_q,
            tma_atom_k,
            tma_tensor_k,
            tma_atom_v,
            tma_tensor_v,
            tma_atom_o,
            tma_tensor_o,
            lse,
            scale_softmax_log2,
            scale_softmax,
            scale_output,
            window_size_left,
            window_size_right,
            q_smem_layout_staged,
            k_smem_layout_staged,
            v_smem_layout_staged,
            o_smem_layout_staged,
            self.tile_sched_params,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=self.cluster_shape_mnk,
            smem=self.shared_storage.size_in_bytes(),
            stream=stream,
            min_blocks_per_mp=1,
        )

    #  GPU device kernel
    @cute.kernel
    def kernel(
        self,
        qk_tiled_mma: cute.TiledMma,
        pv_tiled_mma: cute.TiledMma,
        tma_atom_q: cute.CopyAtom,
        mQ_qdl: cute.Tensor,
        tma_atom_k: cute.CopyAtom,
        mK_kdl: cute.Tensor,
        tma_atom_v: cute.CopyAtom,
        mV_dkl: cute.Tensor,
        tma_atom_o: cute.CopyAtom,
        mO_qdl: cute.Tensor,
        mLse_qdl: cute.Tensor,
        scale_softmax_log2: cutlass.Float32,
        scale_softmax: cutlass.Float32,
        scale_output: cutlass.Float32,
        window_size_left: Optional[cutlass.Int32],
        window_size_right: Optional[cutlass.Int32],
        q_smem_layout_staged: cute.ComposedLayout,
        k_smem_layout_staged: cute.ComposedLayout,
        v_smem_layout_staged: cute.ComposedLayout,
        o_smem_layout_staged: cute.ComposedLayout,
        tile_sched_params: fmha_utils.FmhaStaticTileSchedulerParams,
    ):
        """The device kernel implementation of the Fused Multi-Head Attention for Hopper architecture.

        This kernel coordinates multiple specialized warps to perform different phases of the FMHA computation:
        1. Load warp group: Loads Q, K, V data from global memory to shared memory using TMA
        2. Comput warps groups: Performs matrix multiplications (Q*K^T and P*V) using Hopper TensorCores,
        then compute softmax normalization on attention scores with numerical stability.
        Handle final output transformation and storage.

        The kernel implements a complex pipeline with overlapping computation and memory operations,
        using tensor memory access (TMA) for efficient data loading, warp specialization for different
        computation phases, and optional attention masking for causal or residual attention patterns.

        Key optimizations include:
        - Warp group specialization for load, compute/epilogue phases
        - Pipeline stages between different warps for overlapping computation and memory access
        - Efficient shared memory layouts optimized for Hopper architecture
        - Support for different precision data types and accumulation types
        - Optional causal masking for autoregressive models
        - Sliding window attention masking for efficient long sequence processing

        :param qk_tiled_mma: Tiled MMA for Q*K^T matrix multiplication
        :type qk_tiled_mma: cute.TiledMma
        :param pv_tiled_mma: Tiled MMA for P*V matrix multiplication
        :type pv_tiled_mma: cute.TiledMma
        :param tma_atom_q: TMA copy atom for query tensor loading
        :type tma_atom_q: cute.CopyAtom
        :param mQ_qdl: Partitioned query tensor for TMA loading
        :type mQ_qdl: cute.Tensor
        :param tma_atom_k: TMA copy atom for key tensor loading
        :type tma_atom_k: cute.CopyAtom
        :param mK_kdl: Partitioned key tensor for TMA loading
        :type mK_kdl: cute.Tensor
        :param tma_atom_v: TMA copy atom for value tensor loading
        :type tma_atom_v: cute.CopyAtom
        :param mV_dkl: Partitioned value tensor for TMA loading
        :type mV_dkl: cute.Tensor
        :param tma_atom_o: TMA copy atom for output tensor storage
        :type tma_atom_o: cute.CopyAtom
        :param mO_qdl: Partitioned output tensor for TMA storage
        :type mO_qdl: cute.Tensor
        :param mLse_qdl: Tensor for lse
        :type mLse_qdl: cute.Tensor
        :param scale_softmax_log2: The log2 scale factor for softmax computation
        :type scale_softmax_log2: cutlass.Float32
        :param scale_softmax: The scale factor for softmax (currently unused)
        :type scale_softmax: cutlass.Float32
        :param scale_output: The scale factor for the final output
        :type scale_output: cutlass.Float32
        :param window_size_left: Left-side sliding window size for attention masking
        :type window_size_left: Optional[cutlass.Int32]
        :param window_size_right: Right-side sliding window size for attention masking
        :type window_size_right: Optional[cutlass.Int32]
        :param q_smem_layout_staged: Shared memory layout for query tensor with staging
        :type q_smem_layout_staged: cute.ComposedLayout
        :param k_smem_layout_staged: Shared memory layout for key tensor with staging
        :type k_smem_layout_staged: cute.ComposedLayout
        :param v_smem_layout_staged: Shared memory layout for value tensor with staging
        :type v_smem_layout_staged: cute.ComposedLayout
        :param o_smem_layout_staged: Shared memory layout for output tensor with staging
        :type o_smem_layout_staged: cute.ComposedLayout
        :param tile_sched_params: Scheduling parameters for work distribution across blocks
        :type tile_sched_params: fmha_utils.FmhaStaticTileSchedulerParams
        """

        tidx, _, _ = cute.arch.thread_idx()

        # Alloc
        smem = utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        load_q_producer, load_q_consumer = self.make_and_init_load_q_pipeline(
            storage.load_q_mbar_ptr.data_ptr()
        )
        load_kv_producer, load_kv_consumer = self.make_and_init_load_kv_pipeline(
            storage.load_kv_mbar_ptr.data_ptr()
        )
        tma_store_pipeline = self.make_and_init_tma_store_pipeline()

        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        warp_group_idx = cute.arch.make_warp_uniform(
            tidx // self.num_threads_per_warp_group
        )

        math_wg_order_barrier = self.make_and_init_order_barrier(
            storage.MathWarpGroupOrderBarrier.data_ptr(),
            warp_group_idx - 1,
        )

        #  Generate smem tensor Q/K/V/O
        # (MMA, MMA_Q, MMA_D, PIPE)
        sQ = storage.sQ.get_tensor(
            q_smem_layout_staged.outer, swizzle=q_smem_layout_staged.inner
        )
        # (MMA, MMA_K, MMA_D, PIPE)
        sK = storage.sK.get_tensor(
            k_smem_layout_staged.outer, swizzle=k_smem_layout_staged.inner
        )
        # (MMA, MMA_K, MMA_D, PIPE)
        sV_ptr = cute.recast_ptr(sK.iterator, v_smem_layout_staged.inner)
        sV = cute.make_tensor(sV_ptr, v_smem_layout_staged.outer)

        if cutlass.const_expr(self.is_persistent):
            sO = storage.sO.get_tensor(
                o_smem_layout_staged.outer, swizzle=o_smem_layout_staged.inner
            )
        else:
            sO = cute.make_tensor(
                cute.recast_ptr(sQ.iterator, o_smem_layout_staged.inner, self.o_dtype),
                o_smem_layout_staged.outer,
            )

        seqlen_q = mQ_qdl.shape[0]
        gQ_qdl = cute.flat_divide(mQ_qdl, cute.select(self.qk_mma_tiler, mode=[0, 2]))
        qk_thr_mma = qk_tiled_mma.get_slice(tidx)
        tSgQ_qdl = qk_thr_mma.partition_A(gQ_qdl)

        tQsQ, tQgQ_qdl = cute.nvgpu.cpasync.tma_partition(
            tma_atom_q,
            0,  # no multicast
            cute.make_layout(1),
            cute.group_modes(sQ, 0, 2),
            cute.group_modes(tSgQ_qdl, 0, 3),
        )

        seqlen_k = mK_kdl.shape[0]
        gK_kdl = cute.flat_divide(mK_kdl, cute.select(self.qk_mma_tiler, mode=[1, 2]))
        tSgK_kdl = qk_thr_mma.partition_B(gK_kdl)
        tKsK, tKgK_kdl = cute.nvgpu.cpasync.tma_partition(
            tma_atom_k,
            0,  # no multicast
            cute.make_layout(1),
            cute.group_modes(sK, 0, 2),
            cute.group_modes(tSgK_kdl, 0, 3),
        )

        gV_dkl = cute.flat_divide(mV_dkl, cute.select(self.pv_mma_tiler, mode=[1, 2]))
        pv_thr_mma = pv_tiled_mma.get_slice(tidx)
        tSgV_dkl = pv_thr_mma.partition_B(gV_dkl)
        tVsV, tVgV_dkl = cute.nvgpu.cpasync.tma_partition(
            tma_atom_v,
            0,  # no multicast
            cute.make_layout(1),
            cute.group_modes(sV, 0, 2),
            cute.group_modes(tSgV_dkl, 0, 3),
        )

        producer_warp_role = warp_idx % 4  # self.num_warps_per_warp_group

        # We need this to guarantee that the Pipeline init is visible
        # To all producers and consumer blocks in the Cluster
        # and to finish smem init
        if cute.size(self.cluster_shape_mnk) > 1:
            cute.arch.cluster_arrive_relaxed()
            cute.arch.cluster_wait()
        else:
            cute.arch.sync_threads()

        if warp_idx == 0:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_q)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_k)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_v)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_o)

        if warp_group_idx == self.load_warp_group_id:
            cute.arch.warpgroup_reg_dealloc(self.num_regs_load)

            tile_sched = fmha_utils.create_fmha_static_tile_scheduler(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx

                q0_index = 0
                k_index = fmha_utils.FusedMask.get_trip_start(
                    self.mask_type,
                    curr_block_coord,
                    self.cta_tiler,
                    seqlen_q,
                    seqlen_k,
                    window_size_left,
                )
                fusion_tile_count = fmha_utils.FusedMask.get_trip_count(
                    self.mask_type,
                    curr_block_coord,
                    self.cta_tiler,
                    seqlen_q,
                    seqlen_k,
                    window_size_left,
                    window_size_right,
                )

                q_tile_count = self.num_mma_warp_groups
                k_tile_count = 2 * fusion_tile_count

                curr_block_coord_m = curr_block_coord[0]
                _tQgQ = tQgQ_qdl[(None, None, 0, curr_block_coord[2])]
                tQgQ = cute.domain_offset(
                    (0, curr_block_coord_m * self.num_mma_warp_groups), _tQgQ
                )

                if producer_warp_role == self.producer_warp_loadkv_id:
                    # LoadQ
                    if q_tile_count > 0:
                        q_handle = load_q_producer.acquire_and_advance()
                        cute.copy(
                            tma_atom_q,
                            tQgQ[(None, q0_index)],
                            tQsQ[(None, q_handle.index)],
                            tma_bar_ptr=q_handle.barrier,
                        )
                        q0_index += 1

                    q_tile_count -= 1

                    tKgK = tKgK_kdl[(None, None, 0, curr_block_coord[2])]
                    tVgV = tVgV_dkl[(None, 0, None, curr_block_coord[2])]

                    # Load K
                    if k_tile_count > 0:
                        k_handle = load_kv_producer.acquire_and_advance()
                        cute.copy(
                            tma_atom_k,
                            tKgK[(None, k_index)],
                            tKsK[(None, k_handle.index)],
                            tma_bar_ptr=k_handle.barrier,
                        )

                    k_tile_count -= 1

                    # Q1
                    if q_tile_count > 0:
                        q_handle = load_q_producer.acquire_and_advance()
                        cute.copy(
                            tma_atom_q,
                            tQgQ[(None, q0_index)],
                            tQsQ[(None, q_handle.index)],
                            tma_bar_ptr=q_handle.barrier,
                        )
                        q0_index += 1
                    q_tile_count -= 1

                    # LoadV
                    if k_tile_count > 0:
                        k_handle = load_kv_producer.acquire_and_advance()
                        cute.copy(
                            tma_atom_v,
                            tVgV[(None, k_index)],
                            tVsV[(None, k_handle.index)],
                            tma_bar_ptr=k_handle.barrier,
                        )

                        k_index += 1
                    k_tile_count -= 1

                    while k_tile_count > 0:
                        # Load KV
                        k_handle = load_kv_producer.acquire_and_advance()
                        cute.copy(
                            tma_atom_k,
                            tKgK[(None, k_index)],
                            tKsK[(None, k_handle.index)],
                            tma_bar_ptr=k_handle.barrier,
                        )

                        k_tile_count -= 1

                        v_handle = load_kv_producer.acquire_and_advance()
                        cute.copy(
                            tma_atom_v,
                            tVgV[(None, k_index)],
                            tVsV[(None, v_handle.index)],
                            tma_bar_ptr=v_handle.barrier,
                        )

                        k_index += 1
                        k_tile_count -= 1

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

        # Mainloop
        if (
            warp_group_idx == self.compute_epilogue_0_warp_group_id
            or warp_group_idx == self.compute_epilogue_1_warp_group_id
        ):
            cute.arch.warpgroup_reg_alloc(self.num_regs_mma)

            tile_sched = fmha_utils.create_fmha_static_tile_scheduler(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            kOuterLoads = 1

            cP = cute.make_identity_tensor((mQ_qdl.shape[0], seqlen_k))
            gPcP = cute.local_tile(cP, self.qk_mma_tiler[:2], (None, None))

            while work_tile.is_valid_tile:
                for i in cutlass.range((warp_group_idx - 1) * kOuterLoads, unroll=1):
                    load_q_consumer.advance()

                curr_block_coord = work_tile.tile_idx

                # _wg_coord_1 is work_tile.tile_idx[1], which is always 0.
                _wg_coord_0 = self.num_mma_warp_groups * curr_block_coord[0] + (
                    warp_group_idx - 1
                )
                _wg_coord_1 = curr_block_coord[1]

                wg_coord = (_wg_coord_0, _wg_coord_1, *curr_block_coord[2:])

                # Mainloop setup QK
                tSsQ = qk_thr_mma.partition_A(sQ)  # (MMA,MMA_M,MMA_K,PIPE)
                tSsK = qk_thr_mma.partition_B(sK)  # (MMA,MMA_N,MMA_K,PIPE)
                tSrQ = qk_thr_mma.make_fragment_A(tSsQ)  # (MMA,MMA_M,MMA_K,PIPE)
                tSrK = qk_thr_mma.make_fragment_B(tSsK)  # (MMA,MMA_N,MMA_K,PIPE)

                # Prepare: MMA PV
                thr_mma_pv = pv_tiled_mma.get_slice(tidx)

                # Mainloop setup PV
                tOsV = thr_mma_pv.partition_B(sV)  # (MMA,MMA_N,MMA_K,PIPE)
                tOrV = thr_mma_pv.make_fragment_B(tOsV)  # (MMA,MMA_M,MMA_N,PIPE)

                q_handle = load_q_consumer.wait()

                # mapping into QK accumulator
                ptPcP = qk_thr_mma.partition_C(gPcP)

                # Allocate PV acc
                pv_acc_shape = pv_thr_mma.partition_shape_C(
                    (self.pv_mma_tiler[0], self.pv_mma_tiler[1])
                )
                acc_pv = pv_thr_mma.make_fragment_C(pv_acc_shape)

                qk_acc_shape = qk_thr_mma.partition_shape_C(
                    (self.qk_mma_tiler[0], self.qk_mma_tiler[1])
                )

                s_max_layout = cute.make_layout(
                    cute.size(layout_acc_mn(pv_tiled_mma, acc_pv.layout), mode=[0])
                )
                s_max = cute.make_rmem_tensor_like(s_max_layout, self.qk_acc_dtype)
                a_sum = cute.make_rmem_tensor_like(s_max, cutlass.Float32)

                kv_offset = fmha_utils.FusedMask.get_trip_start(
                    self.mask_type,
                    curr_block_coord,
                    self.cta_tiler,
                    seqlen_q,
                    seqlen_k,
                    window_size_left,
                )

                masked_leading_count = fmha_utils.FusedMask.get_masked_leading_count(
                    self.mask_type,
                    curr_block_coord,
                    self.cta_tiler,
                    seqlen_q,
                    seqlen_k,
                    window_size_left,
                    window_size_right,
                )
                unmasked_trip_count = fmha_utils.FusedMask.get_unmasked_trip_count(
                    self.mask_type,
                    curr_block_coord,
                    self.cta_tiler,
                    seqlen_q,
                    seqlen_k,
                    window_size_left,
                    window_size_right,
                )

                # mapping into QK accumulator
                tPcP = cute.slice_(ptPcP, (None, None, None, wg_coord[0], kv_offset))
                kv_offset += 1

                qk_acc_shape = qk_thr_mma.partition_shape_C(
                    (self.qk_mma_tiler[0], self.qk_mma_tiler[1])
                )

                # Allocate QK acc
                acc_qk = qk_thr_mma.make_fragment_C(qk_acc_shape)
                k_handle = load_kv_consumer.wait_and_advance()
                math_wg_order_barrier.wait()

                # MMA QK
                cute.nvgpu.warpgroup.fence()

                gemm_zero_acc(
                    qk_tiled_mma,
                    tSrQ[(None, None, None, q_handle.index)],
                    tSrK[(None, None, None, k_handle.index)],
                    acc_qk,
                )
                cute.nvgpu.warpgroup.commit_group()

                math_wg_order_barrier.arrive()

                # Wait for the pipeline MMAs to drain
                cute.nvgpu.warpgroup.wait_group(0)

                s_max, a_sum = softmax_step(
                    True,
                    self.mask_type,
                    acc_qk,
                    qk_tiled_mma,
                    tPcP,
                    s_max,
                    a_sum,
                    acc_qk,
                    qk_tiled_mma,
                    scale_softmax_log2,
                    seqlen_k,
                    seqlen_q,
                    window_size_left,
                    window_size_right,
                    True,
                )

                acc_qk_fixed = make_acc_into_op(
                    acc_qk, pv_tiled_mma.tv_layout_A, self.q_dtype
                )

                v_handle = load_kv_consumer.wait_and_advance()

                # MMA PV
                cute.nvgpu.warpgroup.fence()

                gemm_zero_acc(
                    pv_tiled_mma,
                    acc_qk_fixed,
                    tOrV[(None, None, None, v_handle.index)],
                    acc_pv,
                )
                cute.nvgpu.warpgroup.commit_group()
                cute.nvgpu.warpgroup.wait_group(0)

                k_handle.release()
                v_handle.release()

                if masked_leading_count >= 1:
                    masked_leading_count -= 1
                    load_kv_consumer, k_tile_count, kv_offset, s_max, a_sum = (
                        self.compute(
                            True,
                            masked_leading_count,
                            qk_thr_mma,
                            acc_pv,
                            qk_tiled_mma,
                            pv_tiled_mma,
                            load_kv_consumer,
                            q_handle,
                            tSrQ,
                            tSrK,
                            s_max,
                            a_sum,
                            tOrV,
                            ptPcP,
                            wg_coord,
                            kv_offset,
                            scale_softmax_log2,
                            seqlen_k,
                            seqlen_q,
                            qk_acc_shape,
                            window_size_left,
                            window_size_right,
                        )
                    )
                else:
                    unmasked_trip_count -= 1

                load_kv_consumer, k_tile_count, kv_offset, s_max, a_sum = self.compute(
                    False,
                    unmasked_trip_count,
                    qk_thr_mma,
                    acc_pv,
                    qk_tiled_mma,
                    pv_tiled_mma,
                    load_kv_consumer,
                    q_handle,
                    tSrQ,
                    tSrK,
                    s_max,
                    a_sum,
                    tOrV,
                    ptPcP,
                    wg_coord,
                    kv_offset,
                    scale_softmax_log2,
                    seqlen_k,
                    seqlen_q,
                    qk_acc_shape,
                    window_size_left,
                    window_size_right,
                )

                k_tile_count = fmha_utils.FusedMask.get_masked_trailing_count(
                    self.mask_type,
                    curr_block_coord,
                    self.cta_tiler,
                    seqlen_q,
                    seqlen_k,
                    window_size_left,
                    window_size_right,
                    k_tile_count,
                )

                # Use fusion in softmax
                load_kv_consumer, k_tile_count, kv_offset, s_max, a_sum = self.compute(
                    True,
                    k_tile_count,
                    qk_thr_mma,
                    acc_pv,
                    qk_tiled_mma,
                    pv_tiled_mma,
                    load_kv_consumer,
                    q_handle,
                    tSrQ,
                    tSrK,
                    s_max,
                    a_sum,
                    tOrV,
                    ptPcP,
                    wg_coord,
                    kv_offset,
                    scale_softmax_log2,
                    seqlen_k,
                    seqlen_q,
                    qk_acc_shape,
                    window_size_left,
                    window_size_right,
                )

                if cutlass.const_expr(self.is_persistent):
                    q_handle.release()

                # Wait for the pipeline MMAs to drain
                cute.nvgpu.warpgroup.wait_group(0)

                # acc_pv updated
                lse = tail(
                    s_max, a_sum, acc_pv, pv_tiled_mma, scale_softmax, scale_output
                )

                if warp_group_idx == self.compute_epilogue_0_warp_group_id:
                    for i in cutlass.range_constexpr(
                        kOuterLoads * (self.num_mma_warp_groups - 0)
                    ):
                        load_q_consumer.advance()

                if cutlass.const_expr(self.num_mma_warp_groups >= 2):
                    if warp_group_idx == self.compute_epilogue_1_warp_group_id:
                        for i in cutlass.range_constexpr(
                            kOuterLoads * (self.num_mma_warp_groups - 1)
                        ):
                            load_q_consumer.advance()

                math_wg_order_barrier.wait()

                # store log-sum-exp (LSE)
                thr_mma = pv_tiled_mma.get_slice(tidx)

                gLSE_full = cute.local_tile(
                    mLse_qdl, self.pv_mma_tiler[:2], (None, None, None)
                )
                gLSE = cute.slice_(
                    gLSE_full, (None, None, wg_coord[0], wg_coord[1], wg_coord[2])
                )

                tOgLSE = thr_mma.partition_C(gLSE)
                cO = cute.make_identity_tensor(
                    (self.pv_mma_tiler[0], self.pv_mma_tiler[1])
                )
                tOcO = thr_mma.partition_C(cO)

                if tOcO[0][1] == 0:
                    tOgLSE_mn = cute.make_tensor(
                        tOgLSE.iterator, layout_acc_mn(pv_tiled_mma, tOgLSE.layout)
                    )
                    tOcO_mn = cute.make_tensor(
                        tOcO.iterator, layout_acc_mn(pv_tiled_mma, tOcO.layout)
                    )
                    for i in cutlass.range_constexpr(cute.size(tOgLSE_mn, mode=[0])):
                        if (
                            tOcO_mn[i][0] + wg_coord[0] * self.pv_mma_tiler[0]
                            < seqlen_q
                        ):
                            tOgLSE_mn[(i, 0)] = lse[i]

                # Epilogue
                cO = cute.make_identity_tensor((self.cta_tiler[0], self.cta_tiler[2]))
                copy_atom_r2s = sm90_utils.sm90_get_smem_store_op(
                    self.o_layout,
                    elem_ty_d=self.o_dtype,
                    elem_ty_acc=self.pv_acc_dtype,
                )

                copy_atom_O = cute.make_copy_atom(
                    cute.nvgpu.warp.StMatrix8x8x16bOp(
                        self.o_layout.is_m_major_c(),
                        4,
                    ),
                    self.o_dtype,
                )

                tiled_copy_O_Atom = cute.make_tiled_copy_C_atom(
                    copy_atom_O, pv_tiled_mma
                )

                tiled_copy_r2s = cute.make_tiled_copy_S(
                    copy_atom_r2s,
                    tiled_copy_O_Atom,
                )

                thr_copy_r2s = tiled_copy_r2s.get_slice(
                    tidx % self.num_threads_per_warp_group
                )
                tRS_sD = thr_copy_r2s.partition_D(sO)
                tRS_rAcc = tiled_copy_r2s.retile(acc_pv)

                # Allocate D registers.
                rD_shape = cute.shape(thr_copy_r2s.partition_S(sO))
                tRS_rD_layout = cute.make_layout(rD_shape[:3])

                tRS_rD = cute.make_rmem_tensor_like(tRS_rD_layout, self.pv_acc_dtype)
                size_tRS_rD = cute.size(tRS_rD)

                gD = cute.local_tile(
                    mO_qdl,
                    self.pv_mma_tiler[:2],
                    (wg_coord[0], 0, wg_coord[2]),
                )

                sepi_for_tma_partition = cute.group_modes(sO, 0, 2)
                tcgc_for_tma_partition = cute.zipped_divide(gD, self.epi_tile)

                bSG_sD, bSG_gD = cute.nvgpu.cpasync.tma_partition(
                    tma_atom_o,
                    0,
                    cute.make_layout(1),
                    sepi_for_tma_partition,
                    tcgc_for_tma_partition,
                )

                epi_tile_num = cute.size(tcgc_for_tma_partition, mode=[1])

                for epi_idx in cutlass.range_constexpr(epi_tile_num):
                    # Copy from accumulators to D registers
                    for epi_v in cutlass.range_constexpr(size_tRS_rD):
                        tRS_rD[epi_v] = tRS_rAcc[epi_idx * size_tRS_rD + epi_v]

                    # Type conversion
                    tRS_rD_out = cute.make_rmem_tensor_like(tRS_rD_layout, self.o_dtype)
                    acc_vec = tRS_rD.load()
                    tRS_rD_out.store(acc_vec.to(self.o_dtype))

                    # Copy from D registers to shared memory
                    epi_buffer = epi_idx % self.epi_stage
                    cute.copy(
                        tiled_copy_r2s,
                        tRS_rD_out,
                        tRS_sD[(None, None, None, epi_buffer, warp_group_idx - 1)],
                    )

                    cute.arch.fence_proxy(
                        cute.arch.ProxyKind.async_shared,
                        space=cute.arch.SharedSpace.shared_cta,
                    )
                    pipeline.arrive_and_wait(
                        barrier_id=warp_group_idx,
                        num_threads=self.num_threads_per_warp_group,
                    )

                    # only one warp in each warpgroup copy shared memory to global memory
                    if warp_idx == 4 or warp_idx == 8:
                        cute.copy(
                            tma_atom_o,
                            bSG_sD[(None, epi_buffer, warp_group_idx - 1)],
                            bSG_gD[(None, epi_idx)],
                        )

                        tma_store_pipeline.producer_commit()
                        tma_store_pipeline.producer_acquire()

                    pipeline.arrive_and_wait(
                        barrier_id=warp_group_idx,
                        num_threads=self.num_threads_per_warp_group,
                    )

                math_wg_order_barrier.arrive()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
        return

    @cute.jit
    def compute(
        self,
        fusion: bool,
        k_tile_count: cutlass.Int32,
        qk_thr_mma: cute.ThrMma,
        acc_pv: cute.ThrMma,
        qk_tiled_mma: cute.TiledMma,
        pv_tiled_mma: cute.TiledMma,
        load_kv_consumer: pipeline.PipelineConsumer,
        q_handle: pipeline.PipelineConsumer.ImmutableResourceHandle,
        tSrQ: cute.Tensor,
        tSrK: cute.Tensor,
        s_max: cute.Tensor,
        a_sum: cute.Tensor,
        tOrV: cute.Tensor,
        ptPcP: cute.Tensor,
        wg_coord: tuple,
        kv_offset: cutlass.Int32,
        scale_softmax_log2: cutlass.Float32,
        seqlen_k: cutlass.Int32,
        seqlen_q: cutlass.Int32,
        qk_acc_shape: cute.Shape,
        window_size_left: Optional[cutlass.Int32],
        window_size_right: Optional[cutlass.Int32],
    ) -> Tuple[
        pipeline.PipelineConsumer,
        cutlass.Int32,
        cutlass.Int32,
        cute.Tensor,
        cute.Tensor,
    ]:
        while k_tile_count > 0:
            k_tile_count -= 1

            tPcP = cute.slice_(ptPcP, (None, None, None, wg_coord[0], kv_offset))
            kv_offset += 1

            # Allocate QK acc
            acc_qk = qk_thr_mma.make_fragment_C(qk_acc_shape)

            k_handle = load_kv_consumer.wait_and_advance()

            # MMA QK
            cute.nvgpu.warpgroup.fence()

            gemm_zero_acc(
                qk_tiled_mma,
                tSrQ[(None, None, None, q_handle.index)],
                tSrK[(None, None, None, k_handle.index)],
                acc_qk,
            )

            cute.nvgpu.warpgroup.commit_group()

            tok = load_kv_consumer.try_wait()

            # Wait for the pipeline MMAs to drain
            cute.nvgpu.warpgroup.wait_group(0)

            s_max, a_sum = softmax_step(
                fusion,
                self.mask_type,
                acc_qk,
                qk_tiled_mma,
                tPcP,
                s_max,
                a_sum,
                acc_pv,
                pv_tiled_mma,
                scale_softmax_log2,
                seqlen_k,
                seqlen_q,
                window_size_left,
                window_size_right,
            )

            acc_qk_fixed = make_acc_into_op(
                acc_qk, pv_tiled_mma.tv_layout_A, self.q_dtype
            )

            v_handle = load_kv_consumer.wait_and_advance(tok)

            # MMA PV
            cute.nvgpu.warpgroup.fence()

            pv_tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)
            cute.gemm(
                pv_tiled_mma,
                acc_pv,
                acc_qk_fixed,
                tOrV[(None, None, None, v_handle.index)],
                acc_pv,
            )

            cute.nvgpu.warpgroup.commit_group()
            cute.nvgpu.warpgroup.wait_group(0)

            k_handle.release()
            v_handle.release()

        return load_kv_consumer, k_tile_count, kv_offset, s_max, a_sum

    @cute.jit
    def softmax_step(
        fusion: bool,
        mask_type: fmha_utils.MaskEnum,
        acc_qk: cute.ThrMma,
        tiled_mma_qk: cute.TiledMma,
        count_qk: cute.Tensor,
        s_max: cute.Tensor,
        a_sum: cute.Tensor,
        acc_pv: cute.ThrMma,
        tiled_mma_pv: cute.TiledMma,
        scale_softmax_log2: cutlass.Float32,
        seqlen_k: cutlass.Int32,
        seqlen_q: cutlass.Int32,
        window_size_left: Optional[cutlass.Int32],
        window_size_right: Optional[cutlass.Int32],
        is_first_iter: bool = False,
    ) -> Tuple[cute.Tensor, cute.Tensor]:
        if cutlass.const_expr(fusion):
            fmha_utils.FusedMask.apply_mask(
                mask_type,
                acc_qk,
                count_qk,
                seqlen_q,
                seqlen_k,
                window_size_left,
                window_size_right,
            )

        acc_qk_mn = cute.make_tensor(
            acc_qk.iterator, layout_acc_mn(tiled_mma_qk, acc_qk.layout)
        )

        reduction_target_qk = reduction_target_n(tiled_mma_qk)
        red_rank = cute.rank(reduction_target_qk)

        s_max_prev = None
        acc_pv_mn = None
        if cutlass.const_expr(is_first_iter):
            # Linear reduction is faster for the first iteration
            for i in cutlass.range_constexpr(cute.size(acc_qk_mn, mode=[0])):
                s_max[i] = acc_qk_mn[i, 0]

            for j in cutlass.range_constexpr(1, cute.size(acc_qk_mn, mode=[1])):
                for i in cutlass.range_constexpr(cute.size(acc_qk_mn, mode=[0])):
                    s_max[i] = cute.arch.fmax(s_max[i], acc_qk_mn[i, j])
        else:
            acc_pv_mn = cute.make_tensor(
                acc_pv.iterator, layout_acc_mn(tiled_mma_pv, acc_pv.layout)
            )
            s_max_prev = cute.make_rmem_tensor_like(s_max, s_max._dtype)

        for i in cutlass.range_constexpr(cute.size(acc_qk_mn, mode=[0])):
            if cutlass.const_expr(not is_first_iter):
                s_max_prev[i] = s_max[i]

                # Linear reduction is faster here, as well
                for j in cutlass.range_constexpr(cute.size(acc_qk_mn, mode=[1])):
                    s_max[i] = cutlass.max(s_max[i], acc_qk_mn[i, j])

            # reduce max
            for r in cutlass.range_constexpr(red_rank):
                s_max[i] = cute.arch.warp_reduction_max(
                    s_max[i], threads_in_group=reduction_target_qk.shape[r]
                )

            local_max = s_max[i]
            if s_max[i] == -cutlass.Float32.inf:
                local_max = 0.0
            scale_max = scale_softmax_log2 * local_max

            for j in cutlass.range_constexpr(cute.size(acc_qk_mn, mode=[1])):
                acc_qk_mn[i, j] = cute.math.exp2(
                    scale_softmax_log2 * acc_qk_mn[i, j] - scale_max, fastmath=True
                )

            _a_sum = 0.0
            if cutlass.const_expr(not is_first_iter):
                s_max_cur = s_max[i]
                if s_max[i] == -cutlass.Float32.inf:
                    s_max_cur = 0.0
                scale_pv = cute.math.exp2(
                    (s_max_prev[i] - s_max_cur) * scale_softmax_log2, fastmath=True
                )
                a_sum[i] *= scale_pv

                for j in cutlass.range_constexpr(cute.size(acc_pv_mn, mode=[1])):
                    acc_pv_mn[i, j] *= scale_pv

                _a_sum = a_sum[i]

            a_sum[i] = _a_sum + acc_qk_mn[i, None].load().reduce(
                cute.ReductionOp.ADD, cutlass.Float32.zero, 0
            )

        return s_max, a_sum

    @cute.jit
    def reduction_target_n(tiled_mma):
        separated = layout_separate(
            tiled_mma.shape_mnk[0],
            cute.make_layout(tiled_mma.tv_layout_C.shape[0]),
            tiled_mma.tv_layout_C.stride[0],
        )
        return separated[1]

    @cute.jit
    def convert_c_layout_to_a_layout(c, a):
        return cute.make_layout(
            (a, c.shape[1], (c.shape[2], cute.size(c, mode=[0]) // cute.size(a))),
            stride=(
                c.stride[0],
                c.stride[1],
                (c.stride[2], cute.size(a, mode=[2]) * c.stride[0][2]),
            ),
        )

    @cute.jit
    def make_acc_into_op(acc, operand_layout_tv, Element):
        operand = cute.make_rmem_tensor_like(
            convert_c_layout_to_a_layout(acc.layout, operand_layout_tv.shape[1]),
            Element,
        )
        operand_as_acc = cute.make_tensor(operand.iterator, acc.layout)
        acc_vec = acc.load()
        operand_as_acc.store(acc_vec.to(Element))

        if cutlass.const_expr(Element.width == 8 and True):
            ## 00 11 22 33 00 11 22 33 acc layout
            ## 00 00 11 11 22 22 33 33 operand layout
            ## BB AA AA BB AA BB BB AA conflict-free exchange pattern
            ##                         16-bit exchange; so process two at a time potentially
            # int tid = threadIdx.x % 4;
            tidx, _, _ = cute.arch.thread_idx()
            tid = tidx % 4
            values_u32 = cute.recast_tensor(operand, cutlass.Uint32)
            for n in cutlass.range_constexpr(cute.size(values_u32, mode=[1])):
                for k in cutlass.range_constexpr(cute.size(values_u32, mode=[2])):
                    for ii in cutlass.range_constexpr(0, 8, 4):
                        values_tmp_0 = values_u32[ii // 2 + 0, n, k]
                        values_tmp_1 = values_u32[ii // 2 + 1, n, k]

                        ## step A:
                        ## t 1 v 0 -> t 0 v 1
                        ## t 2 v 0 -> t 1 v 0
                        ## t 0 v 1 -> t 2 v 0
                        ## t 3 v 1 -> t 3 v 1

                        v_to_send = 1
                        if tid == 1 or tid == 2:
                            v_to_send = 0

                        v_to_recv = v_to_send
                        t_to_recv_from = (0x3021 >> (tid * 4)) & 0xF

                        values_tmp_a = values_tmp_1
                        if v_to_send == 0:
                            values_tmp_a = values_tmp_0

                        values_tmp_a = cute.arch.shuffle_sync_op(
                            values_tmp_a, t_to_recv_from, 0xFFFFFFFF, 7199
                        )

                        # step B:
                        # t 0 v 0 -> t 0 v 0
                        # t 3 v 0 -> t 1 v 1
                        # t 1 v 1 -> t 2 v 1
                        # t 2 v 1 -> t 3 v 0

                        v_to_send = 1 - v_to_send
                        v_to_recv = 1 - v_to_recv
                        t_to_recv_from = (0x2130 >> (tid * 4)) & 0xF

                        values_tmp_b = values_tmp_1
                        if v_to_send == 0:
                            values_tmp_b = values_tmp_0

                        values_tmp_b = cute.arch.shuffle_sync_op(
                            values_tmp_b, t_to_recv_from, 0xFFFFFFFF, 7199
                        )

                        # __byte_perm
                        order = 0x5410
                        if v_to_send == 0:
                            order = 0x1054

                        values_u32[ii // 2 + 0, n, k] = cute.arch.prmt(
                            values_tmp_a,
                            values_tmp_b,
                            order,
                        )

                        order = 0x7632
                        if v_to_send == 0:
                            order = 0x3276
                        values_u32[ii // 2 + 1, n, k] = cute.arch.prmt(
                            values_tmp_a, values_tmp_b, order
                        )
        return operand

    @cute.jit
    def tail(s_max, a_sum, acc_pv, tiled_mma_pv, scale_softmax, scale_output):
        """
        Final processing step for FMHA that computes log-sum-exp (LSE) and scales the output.

        This function performs the following operations:
        1. Reduces the attention sums across warps using butterfly shuffle
        2. Computes the log-sum-exp (LSE) for numerical stability
        3. Applies softmax scaling and output scaling to the accumulated values
        4. Handles edge cases like zero sums and NaN values

        :param s_max: Maximum attention scores for each position (for numerical stability)
        :type s_max: cute.Tensor
        :param a_sum: Sum of attention scores after softmax
        :type a_sum: cute.Tensor
        :param acc_pv: Accumulated P*V values from the attention computation
        :type acc_pv: cute.ThrMma
        :param tiled_mma_pv: Tiled MMA for P*V computation
        :type tiled_mma_pv: cute.TiledMma
        :param scale_softmax: Scaling factor for softmax computation
        :type scale_softmax: cutlass.Float32
        :param scale_output: Scaling factor for final output
        :type scale_output: cutlass.Float32

        :return: Log-sum-exp values for each position
        :rtype: cute.Tensor
        """
        # Create tensor view of accumulated P*V values with M*N layout
        acc_pv_mn = cute.make_tensor(
            acc_pv.iterator, layout_acc_mn(tiled_mma_pv, acc_pv.layout)
        )
        reduction_target = reduction_target_n(tiled_mma_pv)
        red_rank = cute.rank(reduction_target)
        for r in cutlass.range_constexpr(red_rank):
            for i in cutlass.range_constexpr(cute.size(acc_pv_mn, mode=[0])):
                a_sum[i] = cute.arch.warp_reduction_sum(
                    a_sum[i], threads_in_group=reduction_target.shape[r]
                )

        acc_mn = cute.make_tensor(
            acc_pv.iterator, layout_acc_mn(tiled_mma_pv, acc_pv.layout)
        )

        lse = cute.make_rmem_tensor_like(a_sum, a_sum._dtype)
        for i in cutlass.range_constexpr(cute.size(acc_mn, mode=[0])):
            sum = a_sum[i]
            inv_sum = cute.arch.rcp_approx(sum)
            if sum == 0.0 or sum != sum:
                inv_sum = 1.0

            lse[i] = s_max[i] * scale_softmax + _math.log(sum)
            if sum == 0.0 or sum != sum:
                lse[i] = cutlass.Float32.inf

            rp_dropout = 1
            scale = rp_dropout * inv_sum
            for j in cutlass.range_constexpr(cute.size(acc_mn, mode=[1])):
                acc_mn[i, j] *= scale * scale_output

        return lse

    @cute.jit
    def layout_separate(thr, src, ref):
        lt = cute.make_layout(())
        ge = cute.make_layout(())

        for k, v in enumerate(ref):
            if cutlass.const_expr(v < thr):
                lt = cute.append(lt, src[k])
            else:
                ge = cute.append(ge, src[k])

        r = None
        if cutlass.const_expr(cute.rank(lt) == 1):
            r = cute.append(lt, ge)
        else:
            r = cute.append(cute.append(cute.make_layout(()), lt), ge)
        return r

    @cute.jit
    def gemm_zero_acc(tiled_mma, A, B, C):
        rA = cute.rank(A)
        rB = cute.rank(B)
        rC = cute.rank(C)
        if cutlass.const_expr(rA == 2 and rB == 2 and rC == 1):
            for k_block_idx in range(cute.size(A, mode=[1]), unroll_full=True):
                tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, k_block_idx != 0)
                cute.gemm(
                    tiled_mma,
                    C,
                    A[None, k_block_idx],
                    B[None, k_block_idx],
                    C,
                )
        elif cutlass.const_expr(rA == 3 and rB == 3 and rC == 3):
            for k_block_idx in range(cute.size(A, mode=[2]), unroll_full=True):
                tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, k_block_idx != 0)
                cute.gemm(
                    tiled_mma,
                    C,
                    A[None, None, k_block_idx],
                    B[None, None, k_block_idx],
                    C,
                )
        else:
            assert 0

    @cute.jit
    def layout_acc_mn(tiled_mma, acc):
        separated = layout_separate(
            tiled_mma.shape_mnk[0], acc[0], tiled_mma.tv_layout_C.stride[1]
        )

        V_M = separated[0]
        V_N = separated[1]
        V_M1 = None
        V_N1 = None
        if cutlass.const_expr(cute.rank(V_M) == 1):
            V_M1 = cute.append(V_M, acc[1])
        else:
            V_M1 = cute.append(cute.append(cute.make_layout(()), V_M), acc[1])

        if cutlass.const_expr(cute.rank(V_N) == 1):
            V_N1 = cute.append(V_N, acc[2])
        else:
            V_N1 = cute.append(cute.append(cute.make_layout(()), V_N), acc[2])
        r = None
        if cutlass.const_expr(cute.rank(V_M1) == 1):
            r = cute.append(V_M1, V_N1)
        else:
            r = cute.append(cute.append(cute.make_layout(()), V_M1), V_N1)
        return r

    def make_and_init_load_q_pipeline(self, load_q_mbar_ptr):
        load_q_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            len([self.load_warp_group_id]),
        )
        load_q_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            self.num_warps_per_warp_group,
        )
        return pipeline.PipelineTmaAsync.create(
            barrier_storage=load_q_mbar_ptr,
            num_stages=self.q_stage,
            producer_group=load_q_producer_group,
            consumer_group=load_q_consumer_group,
            tx_count=self.tma_copy_q_bytes,
        ).make_participants()

    def make_and_init_load_kv_pipeline(self, load_kv_mbar_ptr):
        load_kv_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            len([self.load_warp_group_id]),
        )
        load_kv_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            self.num_mma_warp_groups * self.num_warps_per_warp_group,
        )
        return pipeline.PipelineTmaAsync.create(
            barrier_storage=load_kv_mbar_ptr,
            num_stages=self.kv_stage,
            producer_group=load_kv_producer_group,
            consumer_group=load_kv_consumer_group,
            tx_count=self.tma_copy_kv_bytes,
        ).make_participants()

    def make_and_init_tma_store_pipeline(self):
        tma_store_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            1,
        )
        return pipeline.PipelineTmaStore.create(
            num_stages=self.epi_stage,
            producer_group=tma_store_producer_group,
        )

    def make_and_init_order_barrier(self, order_mbar_ptr, group_id):
        StagesPerMathWarpGroup = 1
        return pipeline.PipelineOrder.create(
            barrier_storage=order_mbar_ptr,
            depth=StagesPerMathWarpGroup,
            length=self.num_mma_warp_groups,
            group_id=group_id,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.num_threads_per_warp_group,
            ),
        )

    @staticmethod
    def _make_tma_atoms_and_tensors(
        tensor: cute.Tensor,
        smem_layout_staged: cute.ComposedLayout,
        smem_tile: tuple[int, int],
        mcast_dim: int,
    ) -> tuple[cute.CopyAtom, cute.Tensor]:
        """Create TMA atoms and tensors for input tensors.

        :param tensor: Input tensor (A or B)
        :type tensor: cute.Tensor
        :param smem_layout_staged: Shared memory layout for the tensor
        :type smem_layout_staged: cute.ComposedLayout
        :param smem_tile: Shared memory tile shape
        :type smem_tile: Tuple[int, int]
        :param mcast_dim: Multicast dimension
        :type mcast_dim: int

        :return: TMA atom and tensor
        :rtype: Tuple[cute.CopyAtom, cute.Tensor]
        """
        op = (
            cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp()
            if mcast_dim == 1
            else cute.nvgpu.cpasync.CopyBulkTensorTileG2SMulticastOp()
        )

        smem_layout = cute.slice_(smem_layout_staged, (None, None, 0))
        tma_atom, tma_tensor = cute.nvgpu.cpasync.make_tiled_tma_atom(
            op,
            tensor,
            smem_layout,
            smem_tile,
            num_multicast=mcast_dim,
        )
        return tma_atom, tma_tensor

    @staticmethod
    def can_implement(
        q_shape: Tuple[int, int, int, int],
        k_shape: Tuple[int, int, int, int],
        in_dtype: Type[cutlass.Numeric],
        out_dtype: Type[cutlass.Numeric],
        qk_acc_dtype: Type[cutlass.Numeric],
        pv_acc_dtype: Type[cutlass.Numeric],
        mma_tiler_mn: Tuple[int, int],
        is_persistent: bool,
        scale_softmax: float,
        window_size: Tuple[int, int],
        iterations: int,
    ) -> Tuple[bool, str]:
        """Check if the FMHA kernel can be implemented with the given parameters.

        This method validates that the input parameters are compatible with the Hopper
        Fused Multi-Head Attention implementation. It checks tensor shapes, data types,
        window sizes, and other constraints to ensure the kernel can be successfully
        compiled and executed.

        :param q_shape: Query tensor shape (B, S_q, H, D) where B=batch size, S_q=query sequence length,
                       H=number of heads, D=head dimension
        :type q_shape: Tuple[int, int, int, int]
        :param k_shape: Key tensor shape (B, S_k, H_k, D) where B=batch size, S_k=key sequence length,
                       H_k=number of key heads, D=head dimension
        :type k_shape: Tuple[int, int, int, int]
        :param in_dtype: Input data type for query, key and value tensors
        :type in_dtype: Type[cutlass.Numeric]
        :param out_dtype: Output data type for attention output
        :type out_dtype: Type[cutlass.Numeric]
        :param qk_acc_dtype: Accumulator data type for query-key matrix multiplication
        :type qk_acc_dtype: Type[cutlass.Numeric]
        :param pv_acc_dtype: Accumulator data type for probability-value matrix multiplication
        :type pv_acc_dtype: Type[cutlass.Numeric]
        :param mma_tiler_mn: Matrix multiply accumulate tile shape (M, N)
        :type mma_tiler_mn: Tuple[int, int]
        :param is_persistent: Whether to use persistent kernel optimization
        :type is_persistent: bool
        :param scale_softmax: Attention score scaling factor
        :type scale_softmax: float
        :param window_size: Sliding window size (left, right) for attention masking
        :type window_size: Tuple[int, int]
        :param iterations: Number of iterations to run for performance testing
        :type iterations: int

        :return: Tuple of (can_implement, error_message) where can_implement is True if the kernel
                 can be implemented, False otherwise, and error_message contains the reason for failure
        :rtype: Tuple[bool, str]
        """

        # Unpack parameters
        b, s_q, h, d = q_shape
        b_, s_k, h_k, d_ = k_shape
        window_size_left, window_size_right = window_size

        if b != b_:
            return False, "q & k must have the same batch size"

        if d != d_:
            return False, "q & k must have the same head dimension"

        if window_size_left >= s_k - 1:
            return False, "window_size_left must be less than s_k_max - 1"
        if window_size_right >= s_q - 1:
            return False, "window_size_right must be less than s_q_max - 1"

        if h % h_k != 0:
            return False, "h must be divisible by h_k"

        if in_dtype not in {cutlass.Float8E4M3FN, cutlass.Float16, cutlass.BFloat16}:
            return False, "in_dtype must be Float16, BFloat16, Float8E4M3FN"

        if out_dtype not in {cutlass.Float8E4M3FN, cutlass.Float16, cutlass.BFloat16}:
            return False, "out_dtype must be Float16, BFloat16, Float8E4M3FN"

        if qk_acc_dtype not in {cutlass.Float32}:
            return False, "qk_acc_dtype must be Float32"

        if pv_acc_dtype not in {cutlass.Float32}:
            return False, "pv_acc_dtype must be Float32"

        if iterations < 1:
            return False, "iterations must be at least 1"

        if (
            in_dtype.width == 16
            and out_dtype.width == 16
            and (
                (d_ == 256 and mma_tiler_mn[1] >= 128)
                or (d_ == 128 and mma_tiler_mn[1] >= 256)
            )
        ) or (
            in_dtype.width == 8
            and out_dtype.width == 8
            and d_ == 256
            and mma_tiler_mn[1] >= 256
        ):
            return False, "not enough smem"

        if is_persistent and (
            (
                in_dtype.width == 16
                and out_dtype.width == 16
                and (
                    (d_ == 128 and mma_tiler_mn[1] >= 256)
                    or (d_ == 256 and mma_tiler_mn[1] > 32)
                )
            )
            or (
                in_dtype.width == 8
                and out_dtype.width == 8
                and d_ == 256
                and mma_tiler_mn[1] == 256
            )
        ):
            return False, "not supported persistent"

        return True, None


def run(
    q_shape: Tuple[int, int, int, int],
    k_shape: Tuple[int, int, int, int],
    in_dtype: Type[cutlass.Numeric],
    out_dtype: Type[cutlass.Numeric],
    qk_acc_dtype: Type[cutlass.Numeric],
    pv_acc_dtype: Type[cutlass.Numeric],
    mma_tiler_mn: Tuple[int, int],
    is_persistent: bool,
    is_causal: bool,
    bottom_right_align: bool,
    scale_q: float,
    scale_k: float,
    scale_v: float,
    inv_scale_o: float,
    scale_softmax: float,
    window_size: Tuple[int, int],
    tolerance: float,
    warmup_iterations: int,
    iterations: int,
    skip_ref_check: bool,
    use_cold_l2: bool = False,
    **kwargs,
):
    """Execute Fused Multi-Head Attention (FMHA) on Hopper architecture and validate results.

    This function creates random input tensors for query, key, and value, then performs the
    complete FMHA computation pipeline. It supports configurable data types, tiling parameters,
    and various attention masking options. Results can be validated against a PyTorch reference
    implementation or run multiple times for performance measurement.

    The implementation leverages specialized tensor memory operations and efficient math
    operations optimized for Hopper architecture, including pipelined computation stages
    for maximum throughput.

    :param q_shape: Query tensor shape (B, S_q, H, D) where B=batch size, S_q=query sequence length,
                    H=number of heads, D=head dimension.
                    If S_q is a tuple, it is the variable sequence length.
    :type q_shape: Tuple[int, int, int, int] | Tuple[int, Tuple[int, ...], int, int]
    :param k_shape: Key tensor shape (B, S_k, H_k, D) where B=batch size, S_k=key sequence length,
                    H_k=number of key heads (H must be divisible by H_k), D=head dimension.
                    If S_k is a tuple, it is the variable sequence length.
    :type k_shape: Tuple[int, int, int, int] | Tuple[int, Tuple[int, ...], int, int]
    :param in_dtype: Input data type for query, key and value tensors
    :type in_dtype: Type[cutlass.Numeric]
    :param out_dtype: Output data type for attention output
    :type out_dtype: Type[cutlass.Numeric]
    :param qk_acc_dtype: Accumulator data type for query-key matrix multiplication
    :type qk_acc_dtype: Type[cutlass.Numeric]
    :param pv_acc_dtype: Accumulator data type for probability-value matrix multiplication
    :type pv_acc_dtype: Type[cutlass.Numeric]
    :param mma_tiler_mn: Matrix multiply accumulate tile shape (M, N)
    :type mma_tiler_mn: Tuple[int, int]
    :param is_persistent: Whether to use persistent kernel optimization
    :type is_persistent: bool
    :param is_causal: Whether to apply causal masking
    :type is_causal: bool
    :param bottom_right_align: Whether to use bottom right align, under this settion, the end of q is aligned with the end of k.
    :type bottom_right_align: bool
    :param scale_q: Scaling factor for query tensor
    :type scale_q: float
    :param scale_k: Scaling factor for key tensor
    :type scale_k: float
    :param scale_v: Scaling factor for value tensor
    :type scale_v: float
    :param inv_scale_o: Inverse scaling factor for output tensor
    :type inv_scale_o: float
    :param scale_softmax: Attention score scaling factor (defaults to 1/sqrt(D) if set to 0)
    :type scale_softmax: float
    :param window_size: Sliding window size (left, right) for attention masking. Controls which positions each query can attend to. Negative values disable windowing.
    :type window_size: Tuple[int, int]
    :param tolerance: Maximum acceptable error for validation
    :type tolerance: float
    :param warmup_iterations: Number of warmup iterations
    :type warmup_iterations: int
    :param iterations: Number of iterations to run for performance testing
    :type iterations: int
    :param skip_ref_check: Skip validation against reference implementation
    :type skip_ref_check: bool
    :param use_cold_l2: Whether to use circular buffer strategy to ensure cold L2 cache
    :type use_cold_l2: bool

    :raises ValueError: If input shapes are incompatible or head dimension is unsupported
    :raises RuntimeError: If GPU is unavailable for computation
    :return: Execution time of the FMHA kernel in microseconds
    :rtype: float
    """
    print("Running Hopper SM90 FMHA test with:")
    print(f"  q_shape: {q_shape}")
    print(f"  k_shape: {k_shape}")
    print(f"  in_dtype: {in_dtype}")
    print(f"  out_dtype: {out_dtype}")
    print(f"  qk_acc_dtype: {qk_acc_dtype}")
    print(f"  pv_acc_dtype: {pv_acc_dtype}")
    print(f"  mma_tiler_mn: {mma_tiler_mn}")
    print(f"  is_persistent: {is_persistent}")
    print(f"  is_causal: {is_causal}")
    print(f"  bottom_right_align: {bottom_right_align}")
    print(f"  scale_q: {scale_q}")
    print(f"  scale_k: {scale_k}")
    print(f"  scale_v: {scale_v}")
    print(f"  inv_scale_o: {inv_scale_o}")
    print(f"  scale_softmax: {scale_softmax}")
    print(f"  window_size: {window_size}")
    print(f"  tolerance: {tolerance}")
    print(f"  skip_ref_check: {skip_ref_check}")
    print(f"  use_cold_l2: {use_cold_l2}")

    # Prepare pytorch tensors: Q, K, V (random from 0 to 2) and O (all zero)
    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    ret, msg = HopperFusedMultiHeadAttentionForward.can_implement(
        q_shape,
        k_shape,
        in_dtype,
        out_dtype,
        qk_acc_dtype,
        pv_acc_dtype,
        mma_tiler_mn,
        is_persistent,
        scale_softmax,
        window_size,
        iterations,
    )
    if not ret:
        raise TypeError(msg)

    # Unpack parameters
    b, s_q, h, d = q_shape
    b_, s_k, h_k, d_ = k_shape
    window_size_left, window_size_right = window_size
    if window_size_left == -1:
        window_size_left = None
    if window_size_right == -1:
        window_size_right = None

    h_r = h // h_k

    torch.manual_seed(1111)

    def create_and_permute_tensor(
        b, s, h_k, h_r, d, dtype, is_dynamic_layout=True, tensor_name=""
    ):
        # (b, s, h_k, h_r, d) -> (s, d, h_r, h_k, b)
        # torch SPDA order is (h_k, h_r), then kernel is (h_r, h_k)
        shape = (b, s, h_k, h_r, d)
        permute_order = (1, 4, 3, 2, 0)
        is_fp8 = dtype in {cutlass.Float8E4M3FN}
        leading_dim = 1
        if is_fp8 and tensor_name == "v":
            permute_order = (4, 1, 3, 2, 0)
            leading_dim = 0
            shape = (b, d, h_k, h_r, s)

        # torch does not support fp8 type
        torch_dtype = cutlass.torch.dtype(dtype) if not is_fp8 else torch.int8

        # Create dtype torch tensor (cpu)
        torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
            shape,
            torch_dtype,
            permute_order=permute_order,
            init_type=cutlass.torch.TensorInitType.RANDOM,
            init_config=cutlass.torch.RandomInitConfig(
                min_val=-2,
                max_val=2,
            ),
        )
        # Create dtype torch tensor (gpu)
        torch_tensor_gpu = torch_tensor_cpu.cuda()

        # Create f32 torch tensor (cpu)
        f32_torch_tensor = torch_tensor_cpu.to(dtype=torch.float32)

        # Create dtype cute tensor (gpu)
        cute_tensor = from_dlpack(torch_tensor_gpu, assumed_align=16)
        cute_tensor.element_type = dtype
        if is_dynamic_layout:
            cute_tensor = cute_tensor.mark_layout_dynamic(leading_dim=leading_dim)
        cute_tensor = cutlass_torch.convert_cute_tensor(
            f32_torch_tensor,
            cute_tensor,
            dtype,
            is_dynamic_layout=is_dynamic_layout,
        )

        return f32_torch_tensor, cute_tensor, torch_tensor_gpu

    q_ref, q_tensor, q_torch = create_and_permute_tensor(
        b, s_q, h_k, h_r, d, in_dtype, is_dynamic_layout=True
    )
    k_ref, k_tensor, k_torch = create_and_permute_tensor(
        b, s_k, h_k, 1, d, in_dtype, is_dynamic_layout=True
    )
    v_ref, v_tensor, v_torch = create_and_permute_tensor(
        b, s_k, h_k, 1, d, in_dtype, is_dynamic_layout=True, tensor_name="v"
    )
    o_ref, o_tensor, o_torch = create_and_permute_tensor(
        b, s_q, h_k, h_r, d, out_dtype, is_dynamic_layout=True
    )
    lse_ref, lse_tensor, lse_torch = create_and_permute_tensor(
        b, s_q, h_k, h_r, 1, qk_acc_dtype, is_dynamic_layout=True
    )

    mma_tiler = (*mma_tiler_mn, d)

    mask_type = fmha_utils.MaskEnum.WINDOW_MASK
    if bottom_right_align:
        mask_type = fmha_utils.MaskEnum.WINDOW_MASK_INFERENCE
    if is_causal:
        window_size_right = 0
    elif window_size_left is None and window_size_right is None:
        if s_k % mma_tiler_mn[1] != 0:
            mask_type = fmha_utils.MaskEnum.RESIDUAL_MASK

    # To avoid mask out the whole row which results in NaN in softmax
    def check_seqlen_valid(
        s_q, s_k, window_size_left, window_size_right, bottom_right_align
    ):
        for i in range(s_q):
            offset = 0 if not bottom_right_align else s_k - s_q

            s_q_start = 0 if window_size_left is None else i + offset - window_size_left
            s_q_end = (
                s_q if window_size_right is None else i + offset + window_size_right
            )
            s_q_min = max(s_q_start, 0)
            s_q_max = min(s_q_end, s_k)

            if s_q_max - s_q_min == 0 and (i != 0 and i != s_q - 1):
                return False
        return True

    need_check_seqlen_valid = (
        window_size_left is not None or window_size_right is not None
    )
    if need_check_seqlen_valid and not check_seqlen_valid(
        s_q,
        s_k,
        window_size_left,
        window_size_right,
        bottom_right_align,
    ):
        raise ValueError("sliding window doesn't support current setting")

    fmha = HopperFusedMultiHeadAttentionForward(
        qk_acc_dtype,
        pv_acc_dtype,
        mma_tiler,
        is_persistent,
        mask_type,
    )

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    if scale_softmax == 0.0:  # default to 1/sqrt(d)
        scale_softmax = 1.0 / math.sqrt(q_shape[1])

    scale_softmax = scale_q * scale_k * scale_softmax

    LOG2_E = 1.4426950408889634074
    scale_softmax_log2 = scale_softmax * LOG2_E
    scale_output = scale_v * inv_scale_o

    print("Compiling kernel with cute.compile ...")
    start_time = time.time()
    # compile fmha kernel
    compiled_fmha = cute.compile(
        fmha,
        q_tensor,
        k_tensor,
        v_tensor,
        o_tensor,
        lse_tensor,
        scale_softmax_log2,
        scale_softmax,
        scale_output,
        (
            window_size_left
            if window_size_left is None
            else cutlass.Int32(window_size_left)
        ),
        (
            window_size_right
            if window_size_right is None
            else cutlass.Int32(window_size_right)
        ),
        current_stream,
    )
    compilation_time = time.time() - start_time
    print(f"Compilation time: {compilation_time:.4f} seconds")

    def run_torch_fmha(
        q,
        k,
        v,
        scale_softmax=1.0,
        scale_output=1.0,
        is_causal=False,
        window_size_left=None,
        window_size_right=None,
    ):
        s_q, d, h_r, h_k, b = q.shape
        s_k = k.shape[0]

        # broadcast k and v to have the same shape as q
        k = k.expand(s_k, d, h_r, h_k, b)
        v = v.expand(s_k, d, h_r, h_k, b)

        q_tmp = q.permute(4, 2, 3, 0, 1).contiguous().view(b, -1, s_q, d)
        k_tmp = k.permute(4, 2, 3, 0, 1).contiguous().view(b, -1, s_k, d)
        v_tmp = v.permute(4, 2, 3, 0, 1).contiguous().view(b, -1, s_k, d)

        cur_S = torch.einsum("bhqd,bhkd->bhqk", q_tmp, k_tmp)

        # For causal masking, disable right-side windowing (no future tokens)
        if is_causal:
            window_size_right = 0

        if window_size_left is not None or window_size_right is not None:
            q_coords = torch.arange(0, s_q).cuda().view(-1, 1)
            k_coords = torch.arange(0, s_k).cuda().view(1, -1)
            offset = 0 if not bottom_right_align else s_k - s_q
            if window_size_left is None:
                _mask = k_coords > q_coords + offset + window_size_right
            elif window_size_right is None:
                _mask = k_coords < q_coords + offset - window_size_left
            else:
                _mask = (k_coords > q_coords + offset + window_size_right) | (
                    k_coords < q_coords + offset - window_size_left
                )
            cur_S = cur_S.masked_fill(_mask.cpu(), -torch.inf)

        p_tmp = torch.softmax(cur_S * scale_softmax, dim=-1)
        ref = torch.einsum("bhsl,bhld->bhsd", p_tmp, v_tmp)
        ref = ref.view(b, h_r, h_k, s_q, d).permute(3, 4, 1, 2, 0) * scale_output

        cur_S_max = torch.max(cur_S, dim=-1, keepdim=True).values
        cur_S_sum = torch.sum(
            torch.exp2((cur_S - cur_S_max) * scale_softmax_log2), dim=-1, keepdim=True
        )

        lse = cur_S_max * scale_softmax + torch.log(cur_S_sum)

        # [B, H, Q, 1]->[Q,1,H,B]
        lse = lse.permute(2, 3, 1, 0).contiguous().view(s_q, 1, h_r, h_k, b)

        return ref, lse

    if not skip_ref_check:
        # Execute kernel oneshot for verify
        compiled_fmha(
            q_tensor,
            k_tensor,
            v_tensor,
            o_tensor,
            lse_tensor,
            scale_softmax_log2,
            scale_softmax,
            scale_output,
            (
                window_size_left
                if window_size_left is None
                else cutlass.Int32(window_size_left)
            ),
            (
                window_size_right
                if window_size_right is None
                else cutlass.Int32(window_size_right)
            ),
            current_stream,
        )

        print("Verifying results...")
        o_ref, lse_ref = run_torch_fmha(
            q_ref,
            k_ref,
            v_ref,
            scale_softmax,
            scale_output,
            is_causal,
            window_size_left,
            window_size_right,
        )

        # convert o back to f32 for comparison
        o_fp32, o_fp32_torch = cutlass_torch.cute_tensor_like(
            torch.empty(*o_torch.shape, dtype=torch.float32),
            cutlass.Float32,
            is_dynamic_layout=True,
            assumed_align=16,
        )
        cute.testing.convert(o_tensor, o_fp32)

        ref_o_f32, ref_o_f32_torch = cutlass_torch.cute_tensor_like(
            o_ref,
            cutlass.Float32,
            is_dynamic_layout=True,
            assumed_align=16,
        )

        if out_dtype.is_float and out_dtype.width <= 8:
            ref_narrow_precision, _ = cutlass_torch.cute_tensor_like(
                torch.empty_strided(o_ref.shape, o_ref.stride(), dtype=torch.uint8),
                out_dtype,
                is_dynamic_layout=True,
                assumed_align=16,
            )

            # convert ref : f32 -> fp4/fp8 -> f32
            cute.testing.convert(ref_o_f32, ref_narrow_precision)
            cute.testing.convert(ref_narrow_precision, ref_o_f32)

        # check output ref
        torch.testing.assert_close(
            o_fp32_torch, ref_o_f32_torch, atol=tolerance, rtol=1e-05
        )

        # check lse ref
        lse_result = lse_torch.cpu()
        torch.testing.assert_close(lse_result, lse_ref, atol=tolerance, rtol=1e-05)

        print("Results verified successfully!")

    def generate_tensors():
        _, q_tensor_workspace, _ = create_and_permute_tensor(
            b, s_q, h_k, h_r, d, in_dtype, is_dynamic_layout=True
        )
        _, k_tensor_workspace, _ = create_and_permute_tensor(
            b, s_k, h_k, 1, d, in_dtype, is_dynamic_layout=True
        )
        _, v_tensor_workspace, _ = create_and_permute_tensor(
            b, s_k, h_k, 1, d, in_dtype, is_dynamic_layout=True, tensor_name="v"
        )
        _, o_tensor_workspace, _ = create_and_permute_tensor(
            b, s_q, h_k, h_r, d, out_dtype, is_dynamic_layout=True
        )
        _, lse_tensor_workspace, _ = create_and_permute_tensor(
            b, s_q, h_k, h_r, 1, qk_acc_dtype, is_dynamic_layout=True
        )

        return testing.JitArguments(
            q_tensor_workspace,
            k_tensor_workspace,
            v_tensor_workspace,
            o_tensor_workspace,
            lse_tensor_workspace,
            scale_softmax_log2,
            scale_softmax,
            scale_output,
            (
                window_size_left
                if window_size_left is None
                else cutlass.Int32(window_size_left)
            ),
            (
                window_size_right
                if window_size_right is None
                else cutlass.Int32(window_size_right)
            ),
            current_stream,
        )

    workspace_count = 1
    if use_cold_l2:
        q_torch_effective = q_torch.values() if q_torch.is_nested else q_torch
        k_torch_effective = k_torch.values() if k_torch.is_nested else k_torch
        v_torch_effective = v_torch.values() if v_torch.is_nested else v_torch
        o_torch_effective = o_torch.values() if o_torch.is_nested else o_torch
        lse_torch_effective = lse_torch.values() if lse_torch.is_nested else lse_torch
        one_workspace_bytes = (
            q_torch_effective.numel() * q_torch_effective.element_size()
            + k_torch_effective.numel() * k_torch_effective.element_size()
            + v_torch_effective.numel() * v_torch_effective.element_size()
            + o_torch_effective.numel() * o_torch_effective.element_size()
            + lse_torch_effective.numel() * lse_torch_effective.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_fmha,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time  # Return execution time in microseconds


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str):
        try:
            return [int(x.strip()) for x in s.split(",")]
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(
        description="""
This example showcases the use of CUTE DSL builders to easily construct fused multi-head attention forward-pass kernels targeting NVIDIA's Hopper architecture.
"""
    )

    parser.add_argument(
        "--in_dtype",
        type=cutlass.dtype,
        default=cutlass.Float16,
        help="Input data type",
    )

    parser.add_argument(
        "--out_dtype",
        type=cutlass.dtype,
        default=cutlass.Float16,
        help="Output data type",
    )

    parser.add_argument(
        "--qk_acc_dtype",
        type=cutlass.dtype,
        default=cutlass.Float32,
        help="QK accumulator data type",
    )

    parser.add_argument(
        "--pv_acc_dtype",
        type=cutlass.dtype,
        default=cutlass.Float32,
        help="PV accumulator data type",
    )

    parser.add_argument(
        "--mma_tile_shape_mn",
        type=parse_comma_separated_ints,
        default=[64, 128],
        help="MMA tile shape (M, N)",
    )

    parser.add_argument(
        "--is_persistent",
        action="store_true",
        help="Is persistent",
    )

    parser.add_argument(
        "--is_causal",
        action="store_true",
        help="Whether to use causal mask",
    )

    parser.add_argument(
        "--q_shape",
        type=parse_comma_separated_ints,
        default=[1, 128, 16, 128],
        help="Shape of Q (B, S_q, H, D)",
    )

    parser.add_argument(
        "--k_shape",
        type=parse_comma_separated_ints,
        default=[1, 128, 16, 128],
        help="Shape of K (B, S_k, H_k, D)",
    )

    parser.add_argument(
        "--scale_q",
        type=float,
        default=1.0,
        help="Scaling factors to dequantize Q",
    )

    parser.add_argument(
        "--scale_k",
        type=float,
        default=1.0,
        help="Scaling factors to dequantize K",
    )

    parser.add_argument(
        "--scale_v",
        type=float,
        default=1.0,
        help="Scaling factors to dequantize V",
    )

    parser.add_argument(
        "--inv_scale_o",
        type=float,
        default=1.0,
        help="Scaling factor to quantize O",
    )

    parser.add_argument(
        "--scale_softmax",
        type=float,
        default=1.0,
        help="Scaling factor to scale S (i.e. Q*K); if zero, defaults to 1/sqrt(D)",
    )

    parser.add_argument(
        "--window_size",
        type=parse_comma_separated_ints,
        default=(-1, -1),
        help="Sliding window size (left, right) for attention masking.",
    )

    parser.add_argument(
        "--bottom_right_align",
        action="store_true",
        help="Whether to use bottom right align, under this settion, the end of q is aligned with the end of k.",
    )

    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )

    parser.add_argument(
        "--warmup_iterations",
        type=int,
        default=0,
        help="Number of iterations for warmup",
    )

    parser.add_argument(
        "--iterations",
        type=int,
        default=1,
        help="Number of iterations after warmup",
    )

    parser.add_argument(
        "--skip_ref_check",
        action="store_true",
        help="Skip reference check",
    )

    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )

    args = parser.parse_args()

    if len(args.q_shape) != 4:
        parser.error("--q_shape must contain exactly 4 values")

    if len(args.k_shape) != 4:
        parser.error("--k_shape must contain exactly 4 values")

    if len(args.mma_tile_shape_mn) != 2:
        parser.error("--mma_tile_shape_mn must contain exactly 2 values")

    run(
        args.q_shape,
        args.k_shape,
        args.in_dtype,
        args.out_dtype,
        args.qk_acc_dtype,
        args.pv_acc_dtype,
        args.mma_tile_shape_mn,
        args.is_persistent,
        args.is_causal,
        args.bottom_right_align,
        args.scale_q,
        args.scale_k,
        args.scale_v,
        args.inv_scale_o,
        args.scale_softmax,
        args.window_size,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
    )

    print("PASS")
