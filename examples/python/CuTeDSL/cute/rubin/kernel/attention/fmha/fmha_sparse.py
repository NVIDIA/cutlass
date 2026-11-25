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
import math
import os
import sys
import time
from dataclasses import replace
from typing import Callable, Type, Tuple, Union, Optional
from functools import partial

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import tcgen05
from cutlass.cute.nvgpu.common import OperandMajorMode
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import cutlass.torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.rubin_helpers as sm107_utils
from cutlass import testing
from cutlass.cute.typing import Int32, Int64, Float32, Float16

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../../"))
    sys.path.insert(0, os.path.join(current_dir, "../../../../../"))

from helpers import fmha_helpers as fmha_utils
from blackwell.kernel.attention.fmha.fmha import make_thread_cooperative_group
from rubin.kernel.attention.fmha.fmha import RubinFusedMultiHeadAttentionForward

"""
A sparse fused multi-head attention (FMHA) example for the NVIDIA Rubin SM107
architecture using CUTE DSL.

This example extends the FP8 FMHA kernel with TMEM load STAT+SPARSIFY (``tcgen05.ld.red.spcompress``) based 2:4 structured
sparsity on the attention matrix. The BMM2 (P*V) uses sparse tensor-core
instructions (MMA.SP) so that only half of the softmax probabilities need to be
computed and stored. Causal / residual / window boundary tiles fall back to the
dense softmax/PV path; fully unmasked tiles keep the sparse path.

The ``--enable_fp16_mixed_softmax`` flag enables Rubin's mixed-precision softmax
recipe. By default, the kernel uses the FP32 softmax path.

To run this example:

.. code-block:: bash

    python examples/CuTeDSL/cute/rubin/kernel/attention/fmha/fmha_sparse.py \\
      --in_dtype Float8E4M3FN --out_dtype Float8E4M3FN                      \\
      --qk_acc_dtype Float32 --pv_acc_dtype Float32                         \\
      --mma_tiler_mn 128,128                                                \\
      --q_shape 4,1024,8,192 --k_shape 4,1024,1,192                         \\
      --is_persistent                                                       \\
      --enable_fp16_mixed_softmax

Constraints for this example:
* Inputs only support Float8E4M3FN; output could be Float8E4M3FN / Float16 / BFloat16
* Supported head dimensions: 32, 64, 128, and 192 (MLA mode with d_v=128)
* Number of heads in Q must be divisible by number of heads in K
* mma_tiler_mn must be 128,128
"""


class RubinSparseFusedMultiHeadAttentionForward(RubinFusedMultiHeadAttentionForward):
    """Sparse (2:4 structured) FMHA forward kernel for Rubin SM107.

    Inherits the Rubin/Blackwell warp specialization, TMEM layout, and
    barriers, and adds the sparse-specific 2:4 metadata TMEM offsets plus
    sparse-only pipeline/staging attributes in `_setup_attributes`.
    """

    arch_name: str = "Rubin SM107 Sparse"

    def __init__(
        self,
        qk_acc_dtype: Type[cutlass.Numeric],
        pv_acc_dtype: Type[cutlass.Numeric],
        mma_tiler: Tuple[int, int, int],
        is_persistent: bool,
        mask_type: fmha_utils.MaskEnum,
        enable_skip_correction: bool,
        rescale_threshold: float = 8.0,
        enable_fp16_mixed_softmax: bool = False,
    ):
        """Initialize the sparse Rubin SM107 FMHA configuration.

        :param qk_acc_dtype: Accumulator dtype for Q*K^T.
        :param pv_acc_dtype: Accumulator dtype for P*V.
        :param mma_tiler: The (M, N, D) shape of the MMA instruction; the
            third element is `head_dim` (192 enables MLA with head_dim_v=128).
        :param is_persistent: Whether to use persistent kernel mode.
        :param mask_type: Which attention mask to apply.
        :param enable_skip_correction: Whether to skip the correction step
            when rowmax does not update beyond a threshold.
        :param enable_fp16_mixed_softmax: Whether to use Rubin's mixed-precision
            softmax recipe. BMM accumulators stay in FP32.
        """
        head_dim = mma_tiler[2]
        # MLA mode (head_dim=192) uses head_dim_v=128 via Blackwell's tuple form.
        head_dim_arg = (head_dim, 128) if head_dim == 192 else head_dim
        super().__init__(
            qk_acc_dtype=qk_acc_dtype,
            pv_acc_dtype=pv_acc_dtype,
            mma_tiler=mma_tiler[:2],
            head_dim=head_dim_arg,
            is_persistent=is_persistent,
            mask_type=mask_type,
            enable_ex2_emulation=False,
            enable_skip_correction=enable_skip_correction,
            rescale_threshold=rescale_threshold,
        )
        # Sparse-only TMEM column offsets: 2:4 metadata follows P_compressed
        # in the same region (inplaced with S1/S0 like P_compressed itself).
        self.tmem_meta0_offset = 176
        self.tmem_meta1_offset = 48
        self.enable_fp16_mixed_softmax = enable_fp16_mixed_softmax

    def _setup_attributes(self):
        """Add sparse-specific attributes on top of the inherited Rubin setup.

        `super()._setup_attributes()` provides the shared staging parameters
        (`q_stage`, `kv_stage=6`, `p_mma_stage`, `acc_stage`, etc.), the FP8
        pre-scale, `mma_inst_k`, `enable_sequence_barrier=True`, and
        `enable_ex2_emulation=False`. This override adds the correction
        double-buffering toggle and the mixed-residency Q-in-TMEM cache.
        """
        super()._setup_attributes()
        self.correction_rescale_tile_size = 16
        self.enable_correction_double_buffer = True
        self.enable_q_mixed_residency = (
            self.head_dim == 192 and self.q_dtype is cutlass.Float8E4M3FN
        )
        self.q_mixed_phase_dim = 64
        self.q_mixed_tmem_kphases = 2
        self.q_mixed_total_kphases = 3 if self.enable_q_mixed_residency else 0
        # d=192 caches the first two 64-wide Q kphases in TMEM.
        self.tmem_q_latent_offset = self.tmem_o1_offset + self.qk_mma_tiler[1]
        self.tmem_q_latent_cols = (
            self.q_stage * self.q_mixed_tmem_kphases * self.q_mixed_phase_dim // 4
            if self.enable_q_mixed_residency
            else 0
        )
        if self.enable_q_mixed_residency and (
            self.tmem_q_latent_offset + self.tmem_q_latent_cols
            > self.num_tmem_alloc_cols
        ):
            raise ValueError(
                "Q mixed-residency TMEM buffer exceeds available TMEM columns"
            )

    @cute.jit
    def __call__(
        self,
        q_iter: cute.Pointer,
        k_iter: cute.Pointer,
        v_iter: cute.Pointer,
        o_iter: cute.Pointer,
        problem_size: Tuple[Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32],
        cum_seqlen_q: Optional[cute.Tensor],
        cum_seqlen_k: Optional[cute.Tensor],
        lse_iter: Optional[cute.Pointer],
        scale_softmax_log2: Float32,
        scale_softmax: Float32,
        scale_output: Float32,
        window_size_left: Optional[Int32],
        window_size_right: Optional[Int32],
        stream: cuda.CUstream,
    ):
        """Execute the Fused Multi-Head Attention operation on the provided tensors.

        This method prepares the input tensors for processing, validates their shapes and types,
        configures the computation parameters, and launches the CUDA kernel.

        The method handles:
        1. Tensor layout transformations for specific memory access patterns
        2. Validation of tensor shapes and data types
        3. Initialization of hardware-specific parameters and memory layouts
        4. Configuration of TMA (Tensor Memory Access) operations
        5. Grid and work scheduling computation
        6. Kernel launch with appropriate parameters

        :param q_iter: The query tensor pointer
        :type q_iter: cute.Pointer
        :param k_iter: The key tensor pointer
        :type k_iter: cute.Pointer
        :param v_iter: The value tensor pointer
        :type v_iter: cute.Pointer
        :param o_iter: The output tensor pointer
        :type o_iter: cute.Pointer
        :param problem_size: The problem size with shape [b, s_q_max, s_lse, s_k, h_q, h_k, d, dv]. For varlen, s_lse is total Q length and s_k is total K/V length; per-batch lengths come from cum_seqlen_q/k.
        :type problem_size: Tuple[Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32]
        :param cum_seqlen_q: The cumulative sequence length tensor for query
        :type cum_seqlen_q: Optional[cute.Tensor]
        :param cum_seqlen_k: The cumulative sequence length tensor for key
        :type cum_seqlen_k: Optional[cute.Tensor]
        :param scale_softmax_log2: The log2 scale factor for softmax
        :type scale_softmax_log2: Float32
        :param scale_softmax: The scale factor for softmax
        :type scale_softmax: Float32
        :param scale_output: The scale factor for the output
        :type scale_output: Float32
        :param window_size_left: Left-side sliding window size for attention masking.
        :type window_size_left: Optional[Int32]
        :param window_size_right: Right-side sliding window size for attention masking.
        :type window_size_right: Optional[Int32]
        :param stream: The CUDA stream to execute the kernel on
        :type stream: cuda.CUstream
        :raises TypeError: If tensor data types don't match or aren't supported
        :raises RuntimeError: If tensor layouts aren't in supported formats
        """
        b, s_q_max, s_lse, s_k, h_q, h_k, d, dv = problem_size
        h_r = h_q // h_k
        s_q = s_q_max if cum_seqlen_q is None else s_lse
        stride_b_q = h_r * h_k * s_q * d if cum_seqlen_q is None else 0
        stride_b_o = h_r * h_k * s_q * dv if cum_seqlen_q is None else 0
        stride_b_k = h_k * s_k * d if cum_seqlen_k is None else 0
        stride_b_v = h_k * s_k * dv if cum_seqlen_k is None else 0
        stride_b_lse = h_r * h_k * s_lse if cum_seqlen_q is None else 0

        # (s, d, ((h_r, h_k), b))
        q_layout = cute.make_layout(
            (s_q, d, ((h_r, h_k), b)),
            stride=(d * h_r * h_k, 1, ((d, d * h_r), stride_b_q)),
        )
        q = cute.make_tensor(q_iter, q_layout)
        # (s, d, ((h_r, h_k), b)), 0-stride for h_r to broadcast
        k_layout = cute.make_layout(
            (s_k, d, ((h_r, h_k), b)),
            stride=(d * h_k, 1, ((0, d), stride_b_k)),
        )
        k = cute.make_tensor(k_iter, k_layout)
        # (d, s, ((h_r, h_k), b)), 0-stride for h_r to broadcast
        v_layout = cute.make_layout(
            (dv, s_k, ((h_r, h_k), b)),
            stride=(1, dv * h_k, ((0, dv), stride_b_v)),
        )
        v = cute.make_tensor(v_iter, v_layout)
        # (s, d, ((h_r, h_k), b))
        o_layout = cute.make_layout(
            (s_q, dv, ((h_r, h_k), b)),
            stride=(dv * h_r * h_k, 1, ((dv, dv * h_r), stride_b_o)),
        )
        o = cute.make_tensor(o_iter, o_layout)
        if cutlass.const_expr(lse_iter is not None):
            # (s, ((h_r, h_k), b)) - head stride=1 to match FlashInfer convention.
            lse_layout = cute.make_layout(
                (s_lse, ((h_r, h_k), b)),
                stride=(h_r * h_k, ((1, h_r), stride_b_lse)),
            )
            lse = cute.make_tensor(lse_iter, lse_layout)
        else:
            lse = None

        # setup static attributes before smem/grid/tma computation
        self.q_dtype = q.element_type
        self.k_dtype = k.element_type
        self.v_dtype = v.element_type
        self.o_dtype = o.element_type
        self.enable_nvfp4_output = self.o_dtype is cutlass.Float4E2M1FN
        self.tile_sched_params, grid = fmha_utils.compute_grid(
            cute.shape((s_q_max, d, ((h_r, h_k), b))),
            self.cta_tiler,
            self.is_persistent,
        )
        self.q_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            q
        ).mma_major_mode()
        self.k_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            k
        ).mma_major_mode()
        self.v_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            v
        ).mma_major_mode()
        self.o_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(o)

        if cutlass.const_expr(self.q_major_mode != OperandMajorMode.K):
            raise RuntimeError("The layout of q is not supported")
        if cutlass.const_expr(self.k_major_mode != OperandMajorMode.K):
            raise RuntimeError("The layout of k is not supported")
        if cutlass.const_expr(self.v_major_mode != OperandMajorMode.MN):
            raise RuntimeError("The layout of v is not supported")

        # check type consistency
        if cutlass.const_expr(self.q_dtype != self.k_dtype):
            raise TypeError(f"Type mismatch: {self.q_dtype} != {self.k_dtype}")
        if cutlass.const_expr(self.q_dtype != self.v_dtype):
            raise TypeError(f"Type mismatch: {self.q_dtype} != {self.v_dtype}")
        self._setup_attributes()

        cta_group = tcgen05.CtaGroup.ONE
        # the intermediate tensor p is from tmem & k-major
        p_source = tcgen05.OperandSource.TMEM
        p_major_mode = cute.nvgpu.OperandMajorMode.K
        qk_tiled_mma = self._make_qk_tiled_mma(cta_group)
        if cutlass.const_expr(self.enable_q_mixed_residency):
            qk_tiled_mma_tmem = sm107_utils.make_trivial_tiled_mma(
                self.q_dtype,
                self.k_dtype,
                self.q_major_mode,
                self.k_major_mode,
                self.qk_acc_dtype,
                cta_group,
                (*self.qk_mma_tiler[:2], self.mma_inst_k),
                a_source=tcgen05.OperandSource.TMEM,
            )
        else:
            qk_tiled_mma_tmem = qk_tiled_mma
        pv_tiled_mma = sm107_utils.make_sparse_trivial_tiled_mma(
            self.v_dtype,
            p_major_mode,
            self.v_major_mode,
            self.pv_acc_dtype,
            cta_group,
            self.pv_mma_tiler[:2],
            a_source=p_source,
        )
        pv_tiled_mma_dense = sm107_utils.make_trivial_tiled_mma(
            self.q_dtype,
            self.v_dtype,
            p_major_mode,
            self.v_major_mode,
            self.pv_acc_dtype,
            cta_group,
            (*self.pv_mma_tiler[:2], 64),
            a_source=p_source,
        )
        self.cluster_shape_mnk = (*self.cluster_shape_mn, 1)
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(self.cluster_shape_mnk),
            (qk_tiled_mma.thr_id.shape,),
        )
        self.epi_tile = self.pv_mma_tiler[:2]

        q_smem_layout_staged = sm100_utils.make_smem_layout_a(
            qk_tiled_mma,
            self.qk_mma_tiler,
            self.q_dtype,
            self.q_stage,
        )
        if cutlass.const_expr(self.enable_q_mixed_residency):
            # Re-interpret the Q tile as 3 logical 64-wide kphases in SMEM.
            q_mixed_phase_tiler = (
                self.qk_mma_tiler[0],
                self.qk_mma_tiler[1],
                self.q_mixed_phase_dim,
            )
            q_mixed_smem_layout_staged = sm100_utils.make_smem_layout_a(
                qk_tiled_mma,
                q_mixed_phase_tiler,
                self.q_dtype,
                self.q_stage * self.q_mixed_total_kphases,
            )
            q_mixed_smem_layout_staged = cute.logical_divide(
                q_mixed_smem_layout_staged,
                (None, None, None, self.q_mixed_total_kphases),
            )
            # Cache only the first two 64-wide kphases in TMEM. The staged TMEM
            # layout is indexed as (kphase, pipe_stage) over one unified base.
            q_mixed_tmem_layout_staged = sm100_utils.make_smem_layout_a(
                qk_tiled_mma_tmem,
                q_mixed_phase_tiler,
                self.q_dtype,
                self.q_stage * self.q_mixed_tmem_kphases,
            )
            q_mixed_tmem_layout_staged = cute.logical_divide(
                q_mixed_tmem_layout_staged,
                (None, None, None, self.q_mixed_tmem_kphases),
            )
            q_mixed_tmem_layout = q_mixed_tmem_layout_staged.outer
        else:
            q_mixed_smem_layout_staged = q_smem_layout_staged
            q_mixed_tmem_layout = cute.make_layout(1)
        k_smem_layout_staged = sm100_utils.make_smem_layout_b(
            qk_tiled_mma,
            self.qk_mma_tiler,
            self.k_dtype,
            self.kv_stage,
        )
        # Sparse A (P_compressed) uses compressed K dimension.
        pv_mma_tiler_compressed_k = (
            self.pv_mma_tiler[0],
            self.pv_mma_tiler[1],
            self.pv_mma_tiler[2] // 2,
        )
        p_tmem_layout_staged = sm100_utils.make_sparse_smem_layout_a(
            pv_tiled_mma,
            pv_mma_tiler_compressed_k,
            self.q_dtype,
            self.acc_stage,
            sparsity=2,
        )
        # Full-width P layout for dense boundary tiles. It overlaps the sparse
        # metadata region, which is unused on the dense path.
        p_dense_tmem_layout_staged = sm100_utils.make_smem_layout_a(
            pv_tiled_mma_dense,
            self.pv_mma_tiler,
            self.q_dtype,
            self.acc_stage,
        )
        self.e_sparse_dtype = sm100_utils.make_sparse_e_dtype(self.q_dtype)
        tensor_e_atom_k = cute.size(
            sm100_utils.make_tensor_e_atom_layout(self.q_dtype), mode=[1]
        )
        pv_mma_tiler_e = (
            pv_mma_tiler_compressed_k[0],
            pv_mma_tiler_compressed_k[1],
            (pv_mma_tiler_compressed_k[2] * tensor_e_atom_k)
            // math.gcd(pv_mma_tiler_compressed_k[2], tensor_e_atom_k),
        )
        e_smem_layout_staged = sm100_utils.make_sparse_smem_layout_e(
            pv_tiled_mma,
            pv_mma_tiler_e,
            self.q_dtype,
            num_stages=1,
        )
        e_tmem_layout = sm100_utils.make_sparse_tmem_layout_e(
            cute.select(
                e_smem_layout_staged,
                mode=list(range(cute.rank(e_smem_layout_staged) - 1)),
            ).shape,
            self.q_dtype,
        )
        v_smem_layout_staged = sm100_utils.make_smem_layout_b(
            pv_tiled_mma_dense,
            self.pv_mma_tiler,
            self.v_dtype,
            self.kv_stage,
        )
        o_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            self.o_dtype,
            self.o_layout,
            self.epi_tile,
            self.epi_stage,
        )

        # TMA load for Q
        tma_load_op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp(cta_group)
        tma_store_op = cute.nvgpu.cpasync.CopyBulkTensorTileS2GOp()

        q_smem_layout = cute.select(q_smem_layout_staged, mode=[0, 1, 2])
        tma_atom_q, tma_tensor_q = cute.nvgpu.make_tiled_tma_atom_A(
            tma_load_op,
            q,
            q_smem_layout,
            self.qk_mma_tiler,
            qk_tiled_mma,
            self.cluster_layout_vmnk.shape,
        )

        # TMA load for K
        k_smem_layout = cute.select(k_smem_layout_staged, mode=[0, 1, 2])
        tma_atom_k, tma_tensor_k = cute.nvgpu.make_tiled_tma_atom_B(
            tma_load_op,
            k,
            k_smem_layout,
            self.qk_mma_tiler,
            qk_tiled_mma,
            self.cluster_layout_vmnk.shape,
        )
        # TMA load for V
        v_smem_layout = cute.select(v_smem_layout_staged, mode=[0, 1, 2])
        tma_atom_v, tma_tensor_v = cute.nvgpu.make_tiled_tma_atom_B(
            tma_load_op,
            v,
            v_smem_layout,
            self.pv_mma_tiler,
            pv_tiled_mma,
            self.cluster_layout_vmnk.shape,
        )

        o_smem_layout = cute.select(o_smem_layout_staged, mode=[0, 1])
        tma_atom_o, tma_tensor_o = cute.nvgpu.cpasync.make_tiled_tma_atom(
            tma_store_op,
            o,
            o_smem_layout,
            self.epi_tile,
        )

        q_copy_size = cute.size_in_bytes(self.q_dtype, q_smem_layout)
        k_copy_size = cute.size_in_bytes(self.k_dtype, k_smem_layout)
        v_copy_size = cute.size_in_bytes(self.v_dtype, v_smem_layout)
        self.tma_copy_q_bytes = q_copy_size
        self.tma_copy_k_bytes = k_copy_size
        self.tma_copy_v_bytes = v_copy_size

        @cute.struct
        class MmaSoftmaxBarrierPair:
            stage0: cute.struct.MemRange[Int64, self.mma_softmax_stage * 2]
            stage1: cute.struct.MemRange[Int64, self.mma_softmax_stage * 2]

        @cute.struct
        class PMmaBarrierPair:
            stage0: cute.struct.MemRange[Int64, self.p_mma_stage * 2]
            stage1: cute.struct.MemRange[Int64, self.p_mma_stage * 2]

        @cute.struct
        class SoftmaxCorrectionBarrierPair:
            stage0: cute.struct.MemRange[Int64, self.softmax_corr_stage * 2]
            stage1: cute.struct.MemRange[Int64, self.softmax_corr_stage * 2]

        @cute.struct
        class InplaceBarrierPair:
            stage0: cute.struct.MemRange[Int64, self.p_mma_stage * 2]
            stage1: cute.struct.MemRange[Int64, self.p_mma_stage * 2]

        def assert_barrier_pair_layout(pair_type, num_stages: int) -> None:
            """Prove runtime stage offsets stay inside one contiguous pair."""
            group_size_bytes = num_stages * 2 * (Int64.width // 8)
            assert pair_type._offsets["stage0"] == 0
            assert pair_type._offsets["stage1"] == group_size_bytes
            assert pair_type.__sizeof__() == group_size_bytes * 2
            assert pair_type.__alignof__() == Int64.width // 8

        assert_barrier_pair_layout(MmaSoftmaxBarrierPair, self.mma_softmax_stage)
        assert_barrier_pair_layout(PMmaBarrierPair, self.p_mma_stage)
        assert_barrier_pair_layout(
            SoftmaxCorrectionBarrierPair, self.softmax_corr_stage
        )
        assert_barrier_pair_layout(InplaceBarrierPair, self.p_mma_stage)

        @cute.struct
        class SharedStorage:
            # Pipeline barriers
            load_q_mbar_ptr: cute.struct.MemRange[Int64, self.q_stage * 2]
            load_kv_mbar_ptr: cute.struct.MemRange[Int64, self.kv_stage * 2]
            mma_s_mbar: MmaSoftmaxBarrierPair
            p_mma_mbar: PMmaBarrierPair
            s_corr_mbar: SoftmaxCorrectionBarrierPair
            corr_epi_mbar_ptr: cute.struct.MemRange[Int64, self.epi_stage * 2]
            mma_corr_mbar_ptr: cute.struct.MemRange[Int64, self.mma_corr_stage * 2]
            inplace_mbar: InplaceBarrierPair
            # Tmem holding buffer
            tmem_holding_buf: Int32
            # Smem tensors
            sO: cute.struct.Align[
                cute.struct.MemRange[self.o_dtype, cute.cosize(o_smem_layout_staged)],
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
            qk_tiled_mma_tmem,
            pv_tiled_mma,
            pv_tiled_mma_dense,
            tma_atom_q,
            tma_tensor_q,
            tma_atom_k,
            tma_tensor_k,
            tma_atom_v,
            tma_tensor_v,
            tma_atom_o,
            tma_tensor_o,
            cum_seqlen_q,
            cum_seqlen_k,
            lse,
            scale_softmax_log2,
            scale_softmax,
            scale_output,
            window_size_left,
            window_size_right,
            q_smem_layout_staged,
            q_mixed_smem_layout_staged,
            q_mixed_tmem_layout,
            k_smem_layout_staged,
            p_tmem_layout_staged,
            p_dense_tmem_layout_staged,
            v_smem_layout_staged,
            o_smem_layout_staged,
            e_tmem_layout,
            self.tile_sched_params,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=None,
            stream=stream,
            min_blocks_per_mp=1,
        )

    #  GPU device kernel
    @cute.kernel
    def kernel(
        self,
        qk_tiled_mma: cute.TiledMma,
        qk_tiled_mma_tmem: cute.TiledMma,
        pv_tiled_mma: cute.TiledMma,
        pv_tiled_mma_dense: cute.TiledMma,
        tma_atom_q: cute.CopyAtom,
        mQ_qdl: cute.Tensor,
        tma_atom_k: cute.CopyAtom,
        mK_kdl: cute.Tensor,
        tma_atom_v: cute.CopyAtom,
        mV_dkl: cute.Tensor,
        tma_atom_o: cute.CopyAtom,
        mO_qdl: cute.Tensor,
        cum_seqlen_q: Optional[cute.Tensor],
        cum_seqlen_k: Optional[cute.Tensor],
        mLSE: Optional[cute.Tensor],
        scale_softmax_log2: Float32,
        scale_softmax: Float32,
        scale_output: Float32,
        window_size_left: Optional[Int32],
        window_size_right: Optional[Int32],
        q_smem_layout_staged: cute.ComposedLayout,
        q_mixed_smem_layout_staged: cute.ComposedLayout,
        q_mixed_tmem_layout: cute.Layout,
        k_smem_layout_staged: cute.ComposedLayout,
        p_tmem_layout_staged: cute.ComposedLayout,
        p_dense_tmem_layout_staged: cute.ComposedLayout,
        v_smem_layout_staged: cute.ComposedLayout,
        o_smem_layout_staged: cute.ComposedLayout,
        e_tmem_layout: cute.Layout,
        tile_sched_params: fmha_utils.FmhaStaticTileSchedulerParams,
    ):
        """The device kernel implementation of the Sparse Fused Multi-Head Attention.

        This kernel coordinates multiple specialized warps to perform different phases of the FMHA computation:
        1. Load warp: Loads Q, K, V data from global memory to shared memory using TMA
        2. MMA warp: Performs matrix multiplications (Q*K^T and P*V)
        3. Softmax warps: Compute softmax normalization on attention scores
        4. Correction warps: Apply adjustments to intermediate results
        5. Epilogue warp: Handles final output transformation and storage

        The kernel implements a complex pipeline with overlapping computation and memory operations,
        using tensor memory access (TMA) for efficient data loading, warp specialization for different
        computation phases, and optional attention masking.

        :param qk_tiled_mma: Tiled MMA for Q*K^T
        :type qk_tiled_mma: cute.TiledMma
        :param pv_tiled_mma: Tiled MMA for P*V
        :type pv_tiled_mma: cute.TiledMma
        :param tma_atom_q: TMA copy atom for query tensor
        :type tma_atom_q: cute.CopyAtom
        :param mQ_qdl: Partitioned query tensor
        :type mQ_qdl: cute.Tensor
        :param tma_atom_k: TMA copy atom for key tensor
        :type tma_atom_k: cute.CopyAtom
        :param mK_kdl: Partitioned key tensor
        :type mK_kdl: cute.Tensor
        :param tma_atom_v: TMA copy atom for value tensor
        :type tma_atom_v: cute.CopyAtom
        :param mV_dkl: Partitioned value tensor
        :type mV_dkl: cute.Tensor
        :param tma_atom_o: TMA copy atom for output tensor
        :type tma_atom_o: cute.CopyAtom
        :param mO_qdl: Partitioned output tensor
        :type mO_qdl: cute.Tensor
        :param scale_softmax_log2: The log2 scale factor for softmax
        :type scale_softmax_log2: Float32
        :param scale_output: The scale factor for the output
        :type scale_output: Float32
        :param window_size_left: Left-side sliding window size for attention masking.
        :type window_size_left: Optional[Int32]
        :param window_size_right: Right-side sliding window size for attention masking.
        :type window_size_right: Optional[Int32]
        :param q_smem_layout_staged: Shared memory layout for query tensor
        :type q_smem_layout_staged: cute.ComposedLayout
        :param k_smem_layout_staged: Shared memory layout for key tensor
        :type k_smem_layout_staged: cute.ComposedLayout
        :param p_tmem_layout_staged: Tensor memory layout for probability matrix
        :type p_tmem_layout_staged: cute.ComposedLayout
        :param v_smem_layout_staged: Shared memory layout for value tensor
        :type v_smem_layout_staged: cute.ComposedLayout
        :param o_smem_layout_staged: Shared memory layout for output tensor
        :type o_smem_layout_staged: cute.ComposedLayout
        :param tile_sched_params: Scheduling parameters for work distribution
        :type tile_sched_params: fmha_utils.FmhaStaticTileSchedulerParams
        """
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        # coord inside cta
        tidx, _, _ = cute.arch.thread_idx()

        #
        # Prefetch tma desc
        #
        if warp_idx == self.load_warp_id:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_q)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_k)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_v)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_o)

        # Alloc
        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        load_q_producer, load_q_consumer = pipeline.PipelineTmaUmma.create(
            num_stages=self.q_stage,
            producer_group=make_thread_cooperative_group(len([self.load_warp_id])),
            consumer_group=make_thread_cooperative_group(len([self.mma_warp_id])),
            tx_count=self.tma_copy_q_bytes,
            barrier_storage=storage.load_q_mbar_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        load_kv_producer, load_kv_consumer = pipeline.PipelineTmaUmma.create(
            num_stages=self.kv_stage,
            producer_group=make_thread_cooperative_group(len([self.load_warp_id])),
            consumer_group=make_thread_cooperative_group(len([self.mma_warp_id])),
            tx_count=self.tma_copy_k_bytes,
            barrier_storage=storage.load_kv_mbar_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        mma_s0_pipeline = pipeline.PipelineUmmaAsync.create(
            num_stages=self.mma_softmax_stage,
            producer_group=make_thread_cooperative_group(len([self.mma_warp_id])),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax0_warp_ids)
            ),
            barrier_storage=storage.mma_s_mbar.stage0.data_ptr(),
            defer_sync=True,
        )
        mma_s0_producer, mma_s0_consumer = mma_s0_pipeline.make_participants()
        mma_s1_pipeline = pipeline.PipelineUmmaAsync.create(
            num_stages=self.mma_softmax_stage,
            producer_group=make_thread_cooperative_group(len([self.mma_warp_id])),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax1_warp_ids)
            ),
            barrier_storage=storage.mma_s_mbar.stage1.data_ptr(),
            defer_sync=True,
        )
        mma_s1_producer, mma_s1_consumer = mma_s1_pipeline.make_participants()
        p0_mma_pipeline = pipeline.PipelineAsyncUmma.create(
            num_stages=self.p_mma_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax0_warp_ids)
            ),
            consumer_group=make_thread_cooperative_group(len([self.mma_warp_id])),
            barrier_storage=storage.p_mma_mbar.stage0.data_ptr(),
            defer_sync=True,
        )
        p0_mma_producer, p0_mma_consumer = p0_mma_pipeline.make_participants()
        p1_mma_pipeline = pipeline.PipelineAsyncUmma.create(
            num_stages=self.p_mma_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax1_warp_ids)
            ),
            consumer_group=make_thread_cooperative_group(len([self.mma_warp_id])),
            barrier_storage=storage.p_mma_mbar.stage1.data_ptr(),
            defer_sync=True,
        )
        p1_mma_producer, p1_mma_consumer = p1_mma_pipeline.make_participants()
        s0_corr_pipeline = pipeline.PipelineAsync.create(
            num_stages=self.softmax_corr_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len((*self.softmax0_warp_ids, self.mma_warp_id))
            ),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.correction_warp_ids)
            ),
            barrier_storage=storage.s_corr_mbar.stage0.data_ptr(),
            defer_sync=True,
        )
        s0_corr_producer, s0_corr_consumer = s0_corr_pipeline.make_participants()
        s1_corr_pipeline = pipeline.PipelineAsync.create(
            num_stages=self.softmax_corr_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len((*self.softmax1_warp_ids, self.mma_warp_id))
            ),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.correction_warp_ids)
            ),
            barrier_storage=storage.s_corr_mbar.stage1.data_ptr(),
            defer_sync=True,
        )
        s1_corr_producer, s1_corr_consumer = s1_corr_pipeline.make_participants()
        corr_epi_producer, corr_epi_consumer = pipeline.PipelineAsync.create(
            num_stages=self.epi_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.correction_warp_ids)
            ),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len([self.epilogue_warp_id])
            ),
            barrier_storage=storage.corr_epi_mbar_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        mma_corr_producer, mma_corr_consumer = pipeline.PipelineUmmaAsync.create(
            num_stages=self.mma_corr_stage,
            producer_group=make_thread_cooperative_group(len([self.mma_warp_id])),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.correction_warp_ids)
            ),
            barrier_storage=storage.mma_corr_mbar_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        s0_p1_inplace_pipeline = pipeline.PipelineAsync.create(
            num_stages=self.p_mma_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax0_warp_ids)
            ),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax1_warp_ids)
            ),
            barrier_storage=storage.inplace_mbar.stage0.data_ptr(),
            defer_sync=True,
        )
        s0_p1_inplace_producer, s0_p1_inplace_consumer = (
            s0_p1_inplace_pipeline.make_participants()
        )
        s1_p0_inplace_pipeline = pipeline.PipelineAsync.create(
            num_stages=self.p_mma_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax0_warp_ids)
            ),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax1_warp_ids)
            ),
            barrier_storage=storage.inplace_mbar.stage1.data_ptr(),
            defer_sync=True,
        )
        s1_p0_inplace_producer, s1_p0_inplace_consumer = (
            s1_p0_inplace_pipeline.make_participants()
        )
        tmem = cutlass.memory.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=self.tmem_alloc_barrier,
            # Correction warp is the last one that accesses tmem
            allocator_warp_id=self.correction_warp_ids[0],
            arch=self.arch_str,
        )
        pipeline_init_arrive(is_relaxed=True)

        #  Generate smem tensor Q/K/V/O
        # (MMA, MMA_Q, MMA_D, PIPE)
        sQ = storage.sQ.get_tensor(
            q_smem_layout_staged.outer, swizzle=q_smem_layout_staged.inner
        )
        sQ_mixed = None
        if cutlass.const_expr(self.enable_q_mixed_residency):
            sQ_mixed = storage.sQ.get_tensor(
                q_mixed_smem_layout_staged.outer,
                swizzle=q_mixed_smem_layout_staged.inner,
            )
        # (MMA, MMA_K, MMA_D, PIPE)
        sK = storage.sK.get_tensor(
            k_smem_layout_staged.outer, swizzle=k_smem_layout_staged.inner
        )
        # (MMA, MMA_K, MMA_D, PIPE)
        # Strip swizzle info to reuse smem
        sV_ptr = cute.recast_ptr(sK.iterator, v_smem_layout_staged.inner)
        if cutlass.const_expr(self.head_dim != self.head_dim_v):
            # When K and V have different tile sizes (d=192, dv=128), V's per-stage
            # cosize is smaller than K's.  With the default staged layout the stage
            # strides differ, so V at stage N can physically overlap K at stage N-1.
            # Align V's stage stride to K's so every V stage starts where the
            # corresponding K stage starts, which the pipeline already guards.
            v_1s_outer = cute.select(v_smem_layout_staged.outer, mode=[0, 1, 2])
            k_1s_outer = cute.select(k_smem_layout_staged.outer, mode=[0, 1, 2])
            v_aligned_outer = cute.make_layout(
                cute.append(cute.shape(v_1s_outer), self.kv_stage),
                stride=cute.append(v_1s_outer.stride, cute.cosize(k_1s_outer)),
            )
            sV = cute.make_tensor(sV_ptr, v_aligned_outer)
        else:
            sV = cute.make_tensor(sV_ptr, v_smem_layout_staged.outer)
        sO = storage.sO.get_tensor(
            o_smem_layout_staged.outer, swizzle=o_smem_layout_staged.inner
        )
        # Keep a view-only MMA handle separate from the mutable GEMM handles used
        # in `mma_qk*()`, so later `.set(ACCUMULATE, ...)` updates do not leak into
        # partition/view code that is traced in sibling regions.
        qk_tiled_mma_view = sm107_utils.make_trivial_tiled_mma(
            self.q_dtype,
            self.q_dtype,
            self.q_major_mode,
            self.k_major_mode,
            self.qk_acc_dtype,
            tcgen05.CtaGroup.ONE,
            (*self.qk_mma_tiler[:2], self.mma_inst_k),
        )
        qk_thr_mma = qk_tiled_mma_view.get_slice(0)  # default 1sm
        pv_thr_mma = pv_tiled_mma.get_slice(0)  # default 1sm
        pv_thr_mma_dense = pv_tiled_mma_dense.get_slice(0)  # default 1sm
        tSrQ = qk_thr_mma.make_fragment_A(sQ)
        tSrK = qk_thr_mma.make_fragment_B(sK)
        tOrV = pv_thr_mma.make_fragment_B(sV)
        # Same V SMEM tile as the sparse path; only the MMA atom differs.
        tOrV_dense = pv_thr_mma_dense.make_fragment_B(sV)

        def make_acc_tmem_tensors(self, qk_thr_mma, pv_thr_mma, tmem_ptr):
            """S/O accumulator tensors needed by every warp that touches TMEM."""
            qk_acc_shape = qk_thr_mma.partition_shape_C(
                (self.qk_mma_tiler[0], self.qk_mma_tiler[1])
            )
            tStS_fake = qk_thr_mma.make_fragment_C(qk_acc_shape)
            # Correction/epilogue partition O with pv_thr_mma, so both PV paths
            # must share this accumulator layout.
            pv_acc_shape = pv_thr_mma.partition_shape_C(
                (self.pv_mma_tiler[0], self.pv_mma_tiler[1])
            )
            tOtO_fake = pv_thr_mma.make_fragment_C(pv_acc_shape)
            tStS = cute.make_tensor(tmem_ptr + self.tmem_s0_offset, tStS_fake.layout)
            tStS0 = cute.make_tensor(tmem_ptr + self.tmem_s0_offset, tStS_fake.layout)
            tStS1 = cute.make_tensor(tmem_ptr + self.tmem_s1_offset, tStS_fake.layout)
            tOtO0 = cute.make_tensor(tmem_ptr + self.tmem_o0_offset, tOtO_fake.layout)
            tOtO1 = cute.make_tensor(tmem_ptr + self.tmem_o1_offset, tOtO_fake.layout)
            return tStS, tStS0, tStS1, tOtO0, tOtO1

        def make_mma_tmem_tensors(
            self,
            pv_thr_mma,
            pv_thr_mma_dense,
            qk_tiled_mma_tmem,
            p_tmem_layout_staged,
            p_dense_tmem_layout_staged,
            e_tmem_layout,
            q_mixed_tmem_layout,
            sQ_mixed,
            tmem_ptr,
            tStS,
        ):
            """MMA-only TMEM tensors: sparse/dense P, sparse metadata, and the
            mixed-residency Q view + S2T copy partitioning."""
            tP = cute.make_tensor(tStS.iterator, p_tmem_layout_staged.outer)
            tOrP = pv_thr_mma.make_fragment_A(tP)[None, None, None, 0]
            half_k_compressed = cute.size(tOrP.shape, mode=[0, 1]) // 2
            p_half_layout = cute.make_layout(
                ((cute.size(tOrP.shape, mode=[0, 0]), half_k_compressed), 1),
                stride=(
                    (tOrP.layout.stride[0][0], tOrP.layout.stride[0][1]),
                    tOrP.layout.stride[1],
                ),
            )
            p_offset_scale = self.qk_acc_dtype.width // self.q_dtype.width
            p_half_k_offset = p_offset_scale * (
                self.qk_mma_tiler[1] // 2 // Float32.width * self.q_dtype.width // 2
            )
            tOrP0_base = cute.recast_ptr(
                tmem_ptr + self.tmem_p0_offset, dtype=tOrP.dtype
            )
            tOrP1_base = cute.recast_ptr(
                tmem_ptr + self.tmem_p1_offset, dtype=tOrP.dtype
            )
            tOrP0_h0 = cute.make_tensor(tOrP0_base, p_half_layout)
            tOrP0_h1 = cute.make_tensor(tOrP0_base + p_half_k_offset, p_half_layout)
            tOrP1_h0 = cute.make_tensor(tOrP1_base, p_half_layout)
            tOrP1_h1 = cute.make_tensor(tOrP1_base + p_half_k_offset, p_half_layout)
            # Dense boundary tiles reuse the P base but span the full K tile.
            tP_dense = cute.make_tensor(tStS.iterator, p_dense_tmem_layout_staged.outer)
            tOrP_dense = pv_thr_mma_dense.make_fragment_A(tP_dense)[None, None, None, 0]
            tOrP0_dense = cute.make_tensor(
                cute.recast_ptr(tmem_ptr + self.tmem_p0_offset, dtype=tOrP_dense.dtype),
                tOrP_dense.layout,
            )
            tOrP1_dense = cute.make_tensor(
                cute.recast_ptr(tmem_ptr + self.tmem_p1_offset, dtype=tOrP_dense.dtype),
                tOrP_dense.layout,
            )
            # Apply TMEM column offsets in the original dp32bit pointer domain
            # first, then recast to sparse metadata dtype.
            tCtE0 = cute.make_tensor(
                cute.recast_ptr(
                    tmem_ptr + self.tmem_meta0_offset,
                    dtype=self.e_sparse_dtype,
                ),
                e_tmem_layout,
            )
            tCtE1 = cute.make_tensor(
                cute.recast_ptr(
                    tmem_ptr + self.tmem_meta1_offset,
                    dtype=self.e_sparse_dtype,
                ),
                e_tmem_layout,
            )
            tTrQ_tmem = None
            s2t_tiled_copy_q = None
            tCsQ_s2t = None
            tCtQ_s2t = None
            if cutlass.const_expr(self.enable_q_mixed_residency):
                tQ_tmem = cute.make_tensor(
                    cute.recast_ptr(
                        tmem_ptr + self.tmem_q_latent_offset,
                        dtype=self.q_dtype,
                    ),
                    q_mixed_tmem_layout,
                )
                tTrQ_fake = qk_tiled_mma_tmem.make_fragment_A(tQ_tmem)
                tTrQ_tmem = cute.make_tensor(tQ_tmem.iterator, tTrQ_fake.layout)
                s2t_tiled_copy_q, tCsQ_s2t, tCtQ_s2t = self._s2t_copy_and_partition(
                    sQ_mixed, tTrQ_tmem
                )
            return (
                tOrP0_h0,
                tOrP0_h1,
                tOrP1_h0,
                tOrP1_h1,
                tOrP0_dense,
                tOrP1_dense,
                tCtE0,
                tCtE1,
                tTrQ_tmem,
                s2t_tiled_copy_q,
                tCsQ_s2t,
                tCtQ_s2t,
            )

        def make_pipeline_view(prototype, barrier_storage: cute.Pointer):
            """Rebase an initialized pipeline without reinitializing mbarriers."""
            full = prototype.sync_object_full
            empty = prototype.sync_object_empty
            assert isinstance(full, pipeline.MbarrierArray)
            assert isinstance(empty, pipeline.MbarrierArray)
            full_view = full.__new_from_mlir_values__([barrier_storage])
            empty_view = empty.__new_from_mlir_values__(
                [barrier_storage + prototype.num_stages]
            )
            return replace(
                prototype,
                sync_object_full=full_view,
                sync_object_empty=empty_view,
            )

        tile_sched = fmha_utils.create_fmha_static_tile_scheduler(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()
        pipeline_init_wait()
        softmax_fn = partial(
            self.softmax,
            qk_thr_mma=qk_thr_mma,
            value_args=(mK_kdl.shape[0], mQ_qdl.shape[0], scale_softmax_log2),
            mask_args=(window_size_left, window_size_right),
            sched_args=(tile_sched, work_tile),
            e_tmem_layout=e_tmem_layout,
        )
        # ///////////////////////////////////////////////////////////////////////////////
        #  EMPTY
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.empty_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_other)

        # ///////////////////////////////////////////////////////////////////////////////
        #  LOAD
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.load_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_other)
            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                batch_coord = curr_block_coord[2][1]
                continue_cond = False
                cuseqlen_q = Int32(0)
                seqlen_q = mQ_qdl.shape[0]
                seqlen_k = mK_kdl.shape[0]
                if cutlass.const_expr(cum_seqlen_q is not None):
                    cuseqlen_q = cum_seqlen_q[batch_coord]
                    seqlen_q = cum_seqlen_q[batch_coord + 1] - cuseqlen_q
                    continue_cond = not fmha_utils.FmhaStaticTileScheduler.check_valid_work_for_seqlen_q(
                        self.cta_tiler[0],
                        curr_block_coord[0],
                        seqlen_q,
                    )
                if not continue_cond:
                    if cutlass.const_expr(cum_seqlen_k is not None):
                        seqlen_k = (
                            cum_seqlen_k[batch_coord + 1] - cum_seqlen_k[batch_coord]
                        )
                    continue_cond = seqlen_k <= 0
                if not continue_cond:
                    mQ_qdl_ = mQ_qdl
                    mK_kdl_ = mK_kdl
                    mV_dkl_ = mV_dkl
                    if cutlass.const_expr(cum_seqlen_q is not None):
                        mQ_qdl_ = cute.domain_offset(
                            (cum_seqlen_q[batch_coord], 0, ((0, 0), 0)), mQ_qdl
                        )
                    if cutlass.const_expr(cum_seqlen_k is not None):
                        mK_kdl_ = cute.domain_offset(
                            (cum_seqlen_k[batch_coord], 0, ((0, 0), 0)), mK_kdl
                        )
                        mV_dkl_ = cute.domain_offset(
                            (0, cum_seqlen_k[batch_coord], ((0, 0), 0)), mV_dkl
                        )
                    # Local tile partition global tensors
                    gQ_qdl = cute.flat_divide(
                        mQ_qdl_, cute.select(self.qk_mma_tiler, mode=[0, 2])
                    )
                    tSgQ_qdl = qk_thr_mma.partition_A(gQ_qdl)
                    tQsQ, tQgQ_qdl = cute.nvgpu.cpasync.tma_partition(
                        tma_atom_q,
                        0,  # no multicast
                        cute.make_layout(1),
                        cute.group_modes(sQ, 0, 3),
                        cute.group_modes(tSgQ_qdl, 0, 3),
                    )
                    tQgQ = tQgQ_qdl[None, None, 0, curr_block_coord[2]]
                    # Q0
                    q0_coord = 2 * curr_block_coord[0]
                    q0_handle = load_q_producer.acquire_and_advance()
                    cute.copy(
                        tma_atom_q,
                        tQgQ[None, q0_coord],
                        tQsQ[None, q0_handle.index],
                        tma_bar_ptr=q0_handle.barrier,
                    )
                    gK_kdl = cute.flat_divide(
                        mK_kdl_, cute.select(self.qk_mma_tiler, mode=[1, 2])
                    )
                    tSgK_kdl = qk_thr_mma.partition_B(gK_kdl)
                    tKsK, tKgK_kdl = cute.nvgpu.cpasync.tma_partition(
                        tma_atom_k,
                        0,  # no multicast
                        cute.make_layout(1),
                        cute.group_modes(sK, 0, 3),
                        cute.group_modes(tSgK_kdl, 0, 3),
                    )
                    tKgK = tKgK_kdl[None, None, 0, curr_block_coord[2]]
                    seqlen_kv_loop_start = fmha_utils.FusedMask.get_trip_start(
                        self.mask_type,
                        curr_block_coord,
                        self.cta_tiler,
                        seqlen_q,
                        seqlen_k,
                        window_size_left,
                    )
                    # K0
                    kv_coord = seqlen_kv_loop_start
                    k_handle = load_kv_producer.acquire_and_advance()
                    cute.copy(
                        tma_atom_k,
                        tKgK[None, kv_coord],
                        tKsK[None, k_handle.index],
                        tma_bar_ptr=k_handle.barrier,
                    )
                    gV_dkl = cute.flat_divide(
                        mV_dkl_, cute.select(self.pv_mma_tiler, mode=[1, 2])
                    )
                    tSgV_dkl = pv_thr_mma.partition_B(gV_dkl)
                    tVsV, tVgV_dkl = cute.nvgpu.cpasync.tma_partition(
                        tma_atom_v,
                        0,  # no multicast
                        cute.make_layout(1),
                        cute.group_modes(sV, 0, 3),
                        cute.group_modes(tSgV_dkl, 0, 3),
                    )
                    tVgV = tVgV_dkl[None, 0, None, curr_block_coord[2]]
                    seqlen_kv_loop_steps = fmha_utils.FusedMask.get_trip_count(
                        self.mask_type,
                        curr_block_coord,
                        self.cta_tiler,
                        seqlen_q,
                        seqlen_k,
                        window_size_left,
                        window_size_right,
                    )
                    # Q1
                    q1_coord = q0_coord + 1
                    q1_handle = load_q_producer.acquire_and_advance()
                    cute.copy(
                        tma_atom_q,
                        tQgQ[None, q1_coord],
                        tQsQ[None, q1_handle.index],
                        tma_bar_ptr=q1_handle.barrier,
                    )
                    kv_coord += 1

                    for i in cutlass.range(1, seqlen_kv_loop_steps, 1, unroll=1):
                        # Ki
                        k_handle = load_kv_producer.acquire_and_advance()
                        cute.copy(
                            tma_atom_k,
                            tKgK[None, kv_coord],
                            tKsK[None, k_handle.index],
                            tma_bar_ptr=k_handle.barrier,
                        )
                        # Vi-1
                        v_handle = load_kv_producer.acquire_and_advance(
                            expected_tx=self.tma_copy_v_bytes
                        )
                        cute.copy(
                            tma_atom_v,
                            tVgV[None, kv_coord - 1],
                            tVsV[None, v_handle.index],
                            tma_bar_ptr=v_handle.barrier,
                        )
                        kv_coord += 1
                    # End of seqlen_kv loop
                    # Vi_end
                    v_handle = load_kv_producer.acquire_and_advance(
                        expected_tx=self.tma_copy_v_bytes
                    )
                    cute.copy(
                        tma_atom_v,
                        tVgV[None, kv_coord - 1],
                        tVsV[None, v_handle.index],
                        tma_bar_ptr=v_handle.barrier,
                    )
                # End of if not continue_cond
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                # End of persistent scheduler loop
        # ///////////////////////////////////////////////////////////////////////////////
        #  MMA
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.mma_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_other)
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.qk_acc_dtype)
            tStS, tStS0, tStS1, tOtO0, tOtO1 = make_acc_tmem_tensors(
                self, qk_thr_mma, pv_thr_mma, tmem_ptr
            )
            (
                tOrP0_h0,
                tOrP0_h1,
                tOrP1_h0,
                tOrP1_h1,
                tOrP0_dense,
                tOrP1_dense,
                tCtE0,
                tCtE1,
                tTrQ_tmem,
                s2t_tiled_copy_q,
                tCsQ_s2t,
                tCtQ_s2t,
            ) = make_mma_tmem_tensors(
                self,
                pv_thr_mma,
                pv_thr_mma_dense,
                qk_tiled_mma_tmem,
                p_tmem_layout_staged,
                p_dense_tmem_layout_staged,
                e_tmem_layout,
                q_mixed_tmem_layout,
                sQ_mixed,
                tmem_ptr,
                tStS,
            )
            tCtE_for_p0 = tCtE0
            tCtE_for_p1 = tCtE1
            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                batch_coord = curr_block_coord[2][1]
                continue_cond = False
                seqlen_q = mQ_qdl.shape[0]
                seqlen_k = mK_kdl.shape[0]
                if cutlass.const_expr(cum_seqlen_q is not None):
                    cuseqlen_q = cum_seqlen_q[batch_coord]
                    seqlen_q = cum_seqlen_q[batch_coord + 1] - cuseqlen_q
                    continue_cond = not fmha_utils.FmhaStaticTileScheduler.check_valid_work_for_seqlen_q(
                        self.cta_tiler[0],
                        curr_block_coord[0],
                        seqlen_q,
                    )
                if not continue_cond:
                    if cutlass.const_expr(cum_seqlen_k is not None):
                        cuseqlen_k = cum_seqlen_k[batch_coord]
                        seqlen_k = cum_seqlen_k[batch_coord + 1] - cuseqlen_k
                    continue_cond = seqlen_k <= 0
                if not continue_cond:
                    # Wait for Q0
                    q0_handle = load_q_consumer.wait_and_advance()
                    tSrQ0 = tSrQ[None, None, None, q0_handle.index]
                    if cutlass.const_expr(self.enable_q_mixed_residency):
                        self._copy_q_latent_to_tmem(
                            s2t_tiled_copy_q,
                            tCsQ_s2t,
                            tCtQ_s2t,
                            q0_handle.index,
                            self.q_mixed_tmem_kphases,
                        )
                    # Wait for K0
                    k_handle = load_kv_consumer.wait_and_advance()
                    tSrK0 = tSrK[None, None, None, k_handle.index]
                    # Hoist the QK0 sync probes into the previous work so their
                    # phase checks do not all sit immediately in front of the
                    # next QK issue group.
                    next_k_peek_status = None
                    next_s0_si_peek_status = None
                    next_s0_vec_peek_status = None
                    # GEMM_QK00 (Q0 * K0 -> S0)
                    if cutlass.const_expr(self.enable_q_mixed_residency):
                        mma_s0_producer, s0_corr_producer = self.mma_qk_mixed(
                            qk_tiled_mma,
                            qk_tiled_mma_tmem,
                            (tSrQ0, tTrQ_tmem, q0_handle.index, tSrK0, tStS0),
                            (mma_s0_producer, s0_corr_producer),
                            num_cached_kphases=self.q_mixed_tmem_kphases,
                        )
                    else:
                        mma_s0_producer, s0_corr_producer = self.mma_qk(
                            qk_tiled_mma,
                            (tSrQ0, tSrK0, tStS0),
                            (mma_s0_producer, s0_corr_producer),
                        )
                    next_s0_si_peek_status = mma_s0_producer.try_acquire()
                    next_s0_vec_peek_status = s0_corr_producer.try_acquire()
                    # Wait for Q1
                    q1_handle = load_q_consumer.wait_and_advance()
                    tSrQ1 = tSrQ[None, None, None, q1_handle.index]
                    if cutlass.const_expr(self.enable_q_mixed_residency):
                        self._copy_q_latent_to_tmem(
                            s2t_tiled_copy_q,
                            tCsQ_s2t,
                            tCtQ_s2t,
                            q1_handle.index,
                            self.q_mixed_tmem_kphases,
                        )
                    # GEMM_QK10 (Q1 * K0 -> S1), K0 is ready in GEMM_QK00
                    if cutlass.const_expr(self.enable_q_mixed_residency):
                        mma_s1_producer, s1_corr_producer = self.mma_qk_mixed(
                            qk_tiled_mma,
                            qk_tiled_mma_tmem,
                            (tSrQ1, tTrQ_tmem, q1_handle.index, tSrK0, tStS1),
                            (mma_s1_producer, s1_corr_producer),
                            num_cached_kphases=self.q_mixed_tmem_kphases,
                        )
                    else:
                        mma_s1_producer, s1_corr_producer = self.mma_qk(
                            qk_tiled_mma,
                            (tSrQ1, tSrK0, tStS1),
                            (mma_s1_producer, s1_corr_producer),
                        )
                    # Release K0
                    k_handle.release()
                    next_k_peek_status = load_kv_consumer.try_wait()
                    # Note: Q0 & Q1 are still needed in the seqlen_kv loop
                    # so we need to release them after the seqlen_kv loop
                    seqlen_kv_loop_steps = fmha_utils.FusedMask.get_trip_count(
                        self.mask_type,
                        curr_block_coord,
                        self.cta_tiler,
                        seqlen_q,
                        seqlen_k,
                        window_size_left,
                        window_size_right,
                    )
                    _, _, ld_mask_cnt, unmask_cnt, _ = (
                        fmha_utils.FusedMask.get_masked_info(
                            self.mask_type,
                            curr_block_coord,
                            self.cta_tiler,
                            seqlen_q,
                            seqlen_k,
                            window_size_left,
                            window_size_right,
                        )
                    )
                    # No window -> no dense boundary tiles: pure sparse PV.
                    # Masked shapes run boundary tiles in dense segments below.
                    is_pv_always_sparse = (
                        self.mask_type is fmha_utils.MaskEnum.WINDOW_MASK
                        and window_size_left is None
                        and window_size_right is None
                    )
                    # The first PV step of each O accumulator must not accumulate.
                    pv_whether_acc = False

                    mma_kv_ctx = (
                        tSrQ0,
                        tSrQ1,
                        tSrK,
                        tOrV,
                        tOrV_dense,
                        tOrP0_h0,
                        tOrP0_h1,
                        tOrP1_h0,
                        tOrP1_h1,
                        tOrP0_dense,
                        tOrP1_dense,
                        tOtO0,
                        tOtO1,
                        tCtE_for_p0,
                        tCtE_for_p1,
                        tStS0,
                        tStS1,
                        tTrQ_tmem,
                        q0_handle,
                        q1_handle,
                    )

                    def mma_kv_loop(
                        pv_is_sparse,
                        iter_num,
                        carried,
                        inner_fn,
                        kv_ctx,
                    ):
                        # Induction value unused: tile positions advance via
                        # the consumer handles.
                        for _ in cutlass.range(0, iter_num, 1, unroll=2):
                            carried = inner_fn(pv_is_sparse, carried, kv_ctx)
                        return carried

                    mma_kv_loop_fn = partial(
                        mma_kv_loop,
                        inner_fn=self._mma_kv_iter,
                        kv_ctx=mma_kv_ctx,
                    )
                    # Field order must match _mma_kv_iter's unpack/return.
                    # Tiled-MMA wrappers must be carried, not ctx-passed:
                    # their cached IR values break dominance across loops.
                    carried = (
                        load_kv_consumer,
                        next_k_peek_status,
                        next_s0_si_peek_status,
                        next_s0_vec_peek_status,
                        mma_s0_producer,
                        s0_corr_producer,
                        mma_s1_producer,
                        s1_corr_producer,
                        mma_corr_producer,
                        p0_mma_consumer,
                        p1_mma_consumer,
                        pv_whether_acc,
                        qk_tiled_mma,
                        qk_tiled_mma_tmem,
                        pv_tiled_mma,
                        pv_tiled_mma_dense,
                    )
                    if cutlass.const_expr(is_pv_always_sparse):
                        carried = mma_kv_loop_fn(
                            True, seqlen_kv_loop_steps - 1, carried
                        )
                    else:
                        # Leading-masked / unmasked / trailing-masked segments
                        # (leading is empty for pure causal): runtime bounds,
                        # compile-time bodies — a per-tile runtime PV branch here
                        # seeds a slow-phase attractor. Only the tail PV keeps a
                        # runtime pick (RESIDUAL_MASK needs it).
                        pv_lead_cnt = min(ld_mask_cnt, seqlen_kv_loop_steps - 1)
                        pv_sparse_cnt = min(
                            unmask_cnt, seqlen_kv_loop_steps - 1 - pv_lead_cnt
                        )
                        pv_trail_cnt = (
                            seqlen_kv_loop_steps - 1 - pv_lead_cnt - pv_sparse_cnt
                        )
                        carried = mma_kv_loop_fn(False, pv_lead_cnt, carried)
                        carried = mma_kv_loop_fn(True, pv_sparse_cnt, carried)
                        carried = mma_kv_loop_fn(False, pv_trail_cnt, carried)
                    (
                        load_kv_consumer,
                        next_k_peek_status,
                        next_s0_si_peek_status,
                        next_s0_vec_peek_status,
                        mma_s0_producer,
                        s0_corr_producer,
                        mma_s1_producer,
                        s1_corr_producer,
                        mma_corr_producer,
                        p0_mma_consumer,
                        p1_mma_consumer,
                        pv_whether_acc,
                        qk_tiled_mma,
                        qk_tiled_mma_tmem,
                        pv_tiled_mma,
                        pv_tiled_mma_dense,
                    ) = carried
                    # release Q0 & Q1
                    q0_handle.release()
                    q1_handle.release()
                    # Wait for Vi_end
                    v_handle = load_kv_consumer.wait_and_advance()
                    tOrVi = tOrV[None, None, None, v_handle.index]
                    if cutlass.const_expr(is_pv_always_sparse):
                        mma_corr_producer, p0_mma_consumer = self.mma_pv_sparse(
                            pv_tiled_mma,
                            pv_whether_acc,
                            (tOrP0_h0, tOrP0_h1),
                            tOrVi,
                            tOtO0,
                            tCtE_for_p0,
                            (mma_corr_producer, p0_mma_consumer),
                        )
                        mma_corr_producer, p1_mma_consumer = self.mma_pv_sparse(
                            pv_tiled_mma,
                            pv_whether_acc,
                            (tOrP1_h0, tOrP1_h1),
                            tOrVi,
                            tOtO1,
                            tCtE_for_p1,
                            (mma_corr_producer, p1_mma_consumer),
                        )
                    else:
                        tOrVi_dense = tOrV_dense[None, None, None, v_handle.index]
                        last_kv_iter = seqlen_kv_loop_steps - 1
                        is_pv_sparse_last = self._is_sparse_kv_iter(
                            last_kv_iter, ld_mask_cnt, unmask_cnt
                        )
                        mma_corr_producer, p0_mma_consumer = (
                            self.mma_pv_sparse_or_dense(
                                pv_tiled_mma,
                                pv_tiled_mma_dense,
                                is_pv_sparse_last,
                                pv_whether_acc,
                                (tOrP0_h0, tOrP0_h1),
                                tOrP0_dense,
                                tOrVi,
                                tOrVi_dense,
                                tOtO0,
                                tCtE_for_p0,
                                (mma_corr_producer, p0_mma_consumer),
                            )
                        )
                        mma_corr_producer, p1_mma_consumer = (
                            self.mma_pv_sparse_or_dense(
                                pv_tiled_mma,
                                pv_tiled_mma_dense,
                                is_pv_sparse_last,
                                pv_whether_acc,
                                (tOrP1_h0, tOrP1_h1),
                                tOrP1_dense,
                                tOrVi,
                                tOrVi_dense,
                                tOtO1,
                                tCtE_for_p1,
                                (mma_corr_producer, p1_mma_consumer),
                            )
                        )
                    # Release Vi_end
                    v_handle.release()
                    # Empty step for correction epilog
                    vec0_handle = s0_corr_producer.acquire_and_advance()
                    vec0_handle.commit()
                    vec1_handle = s1_corr_producer.acquire_and_advance()
                    vec1_handle.commit()
                # End of if not continue_cond
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # End of persistent scheduler loop
        # ///////////////////////////////////////////////////////////////////////////////
        #  Epilogue
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.epilogue_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_other)
            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                batch_coord = curr_block_coord[2][1]
                continue_cond = False
                cuseqlen_q = Int32(0)
                seqlen_q = mQ_qdl.shape[0]
                seqlen_k = mK_kdl.shape[0]

                if cutlass.const_expr(cum_seqlen_q is not None):
                    cuseqlen_q = cum_seqlen_q[batch_coord]
                    seqlen_q = cum_seqlen_q[batch_coord + 1] - cuseqlen_q
                    continue_cond = not fmha_utils.FmhaStaticTileScheduler.check_valid_work_for_seqlen_q(
                        self.cta_tiler[0],
                        curr_block_coord[0],
                        seqlen_q,
                    )
                if not continue_cond:
                    if cutlass.const_expr(cum_seqlen_k is not None):
                        seqlen_k = (
                            cum_seqlen_k[batch_coord + 1] - cum_seqlen_k[batch_coord]
                        )
                    continue_cond = seqlen_k <= 0
                if not continue_cond:
                    mO_qdl_ = mO_qdl
                    if cutlass.const_expr(cum_seqlen_q is not None):
                        mO_qdl_ = cute.domain_offset(
                            (cuseqlen_q, 0, ((0, 0), 0)), mO_qdl_
                        )

                    o0_coord = 2 * curr_block_coord[0]
                    o1_coord = o0_coord + 1
                    gO_qdl = cute.flat_divide(
                        mO_qdl_, cute.select(self.pv_mma_tiler, mode=[0, 1])
                    )
                    gO = gO_qdl[None, None, None, 0, curr_block_coord[2]]
                    tOsO, tOgO = cute.nvgpu.cpasync.tma_partition(
                        tma_atom_o,
                        0,
                        cute.make_layout(1),
                        cute.group_modes(sO, 0, 2),
                        cute.group_modes(gO, 0, 2),
                    )

                    # O0 O1 using the same pipeline
                    # wait from corr, issue tma store on smem
                    # O0
                    # 1. Wait for O0 final
                    o0_handle = corr_epi_consumer.wait_and_advance()
                    # 2. Copy O0 to gmem
                    cute.copy(tma_atom_o, tOsO[None, 0], tOgO[None, o0_coord])
                    cute.arch.cp_async_bulk_commit_group()
                    # O1
                    # 1. Wait for O1 final
                    o1_handle = corr_epi_consumer.wait_and_advance()
                    # 2. Copy O1 to gmem
                    cute.copy(tma_atom_o, tOsO[None, 1], tOgO[None, o1_coord])
                    cute.arch.cp_async_bulk_commit_group()

                    # Ensure O0 buffer is ready to be released
                    cute.arch.cp_async_bulk_wait_group(1, read=True)
                    o0_handle.release()
                    # Ensure O1 buffer is ready to be released
                    cute.arch.cp_async_bulk_wait_group(0, read=True)
                    o1_handle.release()

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # End of persistent scheduler loop
        # ///////////////////////////////////////////////////////////////////////////////
        #  Softmax0 + Softmax1
        # ///////////////////////////////////////////////////////////////////////////////
        softmax_stage_specializations = (
            (None,) if self.merge_softmax_warp_groups else (0, 1)
        )
        for stage_spec in softmax_stage_specializations:
            softmax_warp_lo = self.softmax1_warp_ids[0] if stage_spec == 1 else 0
            softmax_warp_hi = (
                self.softmax1_warp_ids[0]
                if stage_spec == 0
                else self.correction_warp_ids[0]
            )
            if cutlass.const_expr(softmax_warp_lo == 0):
                softmax_warp_sel = warp_idx < softmax_warp_hi
            else:
                softmax_warp_sel = (warp_idx >= softmax_warp_lo) and (
                    warp_idx < softmax_warp_hi
                )
            if softmax_warp_sel:
                cute.arch.setmaxregister_increase(self.num_regs_softmax)
                tmem.wait_for_alloc()
                tmem_ptr = tmem.retrieve_ptr(self.qk_acc_dtype)
                tStS, _, _, _, _ = make_acc_tmem_tensors(
                    self, qk_thr_mma, pv_thr_mma, tmem_ptr
                )
                stage = (
                    warp_idx // len(self.softmax0_warp_ids)
                    if stage_spec is None
                    else stage_spec
                )
                mma_s_mbar_base = cute.recast_ptr(storage.mma_s_mbar.base, dtype=Int64)
                s_corr_mbar_base = cute.recast_ptr(
                    storage.s_corr_mbar.base, dtype=Int64
                )
                p_mma_mbar_base = cute.recast_ptr(storage.p_mma_mbar.base, dtype=Int64)
                inplace_mbar_base = cute.recast_ptr(
                    storage.inplace_mbar.base, dtype=Int64
                )

                mma_si_pipeline = make_pipeline_view(
                    mma_s0_pipeline,
                    mma_s_mbar_base + stage * self.mma_softmax_stage * 2,
                )
                si_corr_pipeline = make_pipeline_view(
                    s0_corr_pipeline,
                    s_corr_mbar_base + stage * self.softmax_corr_stage * 2,
                )
                pi_mma_pipeline = make_pipeline_view(
                    p0_mma_pipeline,
                    p_mma_mbar_base + stage * self.p_mma_stage * 2,
                )
                inplace_producer_pipeline = make_pipeline_view(
                    s0_p1_inplace_pipeline,
                    inplace_mbar_base + stage * self.p_mma_stage * 2,
                )
                inplace_consumer_pipeline = make_pipeline_view(
                    s0_p1_inplace_pipeline,
                    inplace_mbar_base + (stage ^ 1) * self.p_mma_stage * 2,
                )

                mma_si_consumer = mma_si_pipeline.make_consumer()
                si_corr_producer = si_corr_pipeline.make_producer()
                pi_mma_producer = pi_mma_pipeline.make_producer()
                inplace_producer = inplace_producer_pipeline.make_producer()
                inplace_consumer = inplace_consumer_pipeline.make_consumer()

                tStSi = cute.make_tensor(
                    tStS.iterator + stage * (self.tmem_s1_offset - self.tmem_s0_offset),
                    tStS.layout,
                )
                softmax_fn(
                    stage=stage,
                    tensor_args=(tStS, tStSi, cum_seqlen_k, cum_seqlen_q),
                    pipeline_args=(
                        mma_si_consumer,
                        si_corr_producer,
                        pi_mma_producer,
                    ),
                    inplace_args=(inplace_producer, inplace_consumer),
                )

        # ///////////////////////////////////////////////////////////////////////////////
        #  Correction
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx >= self.correction_warp_ids[0] and warp_idx < self.mma_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_correction)
            tmem.allocate(self.num_tmem_alloc_cols)
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.qk_acc_dtype)
            tStS, tStS0, tStS1, tOtO0, tOtO1 = make_acc_tmem_tensors(
                self, qk_thr_mma, pv_thr_mma, tmem_ptr
            )
            cS = cute.make_identity_tensor((self.qk_mma_tiler[0], self.qk_mma_tiler[1]))
            tScS = qk_thr_mma.partition_C(cS)
            tStS_vec_layout = cute.composition(tStS.layout, cute.make_layout((128, 2)))
            tStS_vec0 = cute.make_tensor(
                tStS.iterator + self.tmem_vec0_offset, tStS_vec_layout
            )
            tStS_vec1 = cute.make_tensor(
                tStS.iterator + self.tmem_vec1_offset, tStS_vec_layout
            )
            tScS_vec_layout = cute.composition(tScS.layout, cute.make_layout((128, 2)))
            tScS_vec = cute.make_tensor(tScS.iterator, tScS_vec_layout)
            tmem_load_v_atom = cute.make_copy_atom(
                tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(2)),
                self.qk_acc_dtype,
            )
            tiled_tmem_load_vec = tcgen05.make_tmem_copy(tmem_load_v_atom, tStS_vec0)
            thread_idx = tidx % (self.threads_per_warp * len(self.correction_warp_ids))
            thr_tmem_load_vec = tiled_tmem_load_vec.get_slice(thread_idx)
            tTMEM_LOAD_VECtS0 = thr_tmem_load_vec.partition_S(tStS_vec0)
            tTMEM_LOAD_VECtS1 = thr_tmem_load_vec.partition_S(tStS_vec1)
            tTMEM_LOAD_VECcS = thr_tmem_load_vec.partition_D(tScS_vec)
            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                batch_coord = curr_block_coord[2][1]
                seqlen_k = mK_kdl.shape[0]
                continue_cond = False
                cuseqlen_q = Int32(0)
                seqlen_q = mQ_qdl.shape[0]

                if cutlass.const_expr(cum_seqlen_q is not None):
                    cuseqlen_q = cum_seqlen_q[batch_coord]
                    seqlen_q = cum_seqlen_q[batch_coord + 1] - cuseqlen_q
                    continue_cond = not fmha_utils.FmhaStaticTileScheduler.check_valid_work_for_seqlen_q(
                        self.cta_tiler[0],
                        curr_block_coord[0],
                        seqlen_q,
                    )
                if not continue_cond:
                    if cutlass.const_expr(cum_seqlen_k is not None):
                        cuseqlen_k = cum_seqlen_k[batch_coord]
                        seqlen_k = cum_seqlen_k[batch_coord + 1] - cuseqlen_k
                    continue_cond = seqlen_k <= 0
                if not continue_cond:
                    row_idx = (
                        curr_block_coord[0] * self.cta_tiler[0] + tTMEM_LOAD_VECcS[0][0]
                    )
                    # Ignore first signal from softmax as no correction is required
                    vec0_handle = s0_corr_consumer.wait_and_advance()
                    vec0_handle.release()
                    vec1_handle = s1_corr_consumer.wait_and_advance()
                    vec1_handle.release()
                    seqlen_kv_loop_steps = fmha_utils.FusedMask.get_trip_count(
                        self.mask_type,
                        curr_block_coord,
                        self.cta_tiler,
                        seqlen_q,
                        seqlen_k,
                        window_size_left,
                        window_size_right,
                    )
                    # O0/O1 share the same mma_corr consumer state, so the
                    # Oi peek token rolls from O0 -> O1 -> next O0. Seed
                    # with a blocking token and only refresh it near the
                    # end of the rescale loop.
                    oi_peek_status = cutlass.Boolean(False)
                    for _ in cutlass.range(1, seqlen_kv_loop_steps, 1, unroll=1):
                        # Rescale O0
                        (
                            (
                                s0_corr_consumer,
                                mma_corr_consumer,
                            ),
                            oi_peek_status,
                        ) = self.correction_rescale(
                            pv_thr_mma,
                            tiled_tmem_load_vec,
                            scale_softmax_log2,
                            (tOtO0, tTMEM_LOAD_VECtS0, tTMEM_LOAD_VECcS),
                            (s0_corr_consumer, mma_corr_consumer),
                            oi_peek_status,
                        )
                        # Rescale O1
                        (
                            (
                                s1_corr_consumer,
                                mma_corr_consumer,
                            ),
                            oi_peek_status,
                        ) = self.correction_rescale(
                            pv_thr_mma,
                            tiled_tmem_load_vec,
                            scale_softmax_log2,
                            (tOtO1, tTMEM_LOAD_VECtS1, tTMEM_LOAD_VECcS),
                            (s1_corr_consumer, mma_corr_consumer),
                            oi_peek_status,
                        )
                    # End of seqlen_corr_loop_steps
                    value_args = (
                        cuseqlen_q,
                        None,
                        seqlen_q,
                        curr_block_coord,
                        scale_softmax,
                        scale_output,
                        None,
                        None,
                    )
                    # Normalize O0
                    s0_corr_consumer, mma_corr_consumer, corr_epi_producer = (
                        self.correction_epilog(
                            pv_thr_mma,
                            tiled_tmem_load_vec,
                            (
                                tOtO0,
                                tTMEM_LOAD_VECtS0,
                                tTMEM_LOAD_VECcS,
                                sO[None, None, 0],
                                mLSE,
                                None,
                                None,
                            ),
                            (s0_corr_consumer, mma_corr_consumer, corr_epi_producer),
                            (row_idx, *value_args),
                        )
                    )
                    row_idx += self.qk_mma_tiler[0]
                    # Normalize O1
                    s1_corr_consumer, mma_corr_consumer, corr_epi_producer = (
                        self.correction_epilog(
                            pv_thr_mma,
                            tiled_tmem_load_vec,
                            (
                                tOtO1,
                                tTMEM_LOAD_VECtS1,
                                tTMEM_LOAD_VECcS,
                                sO[None, None, 1],
                                mLSE,
                                None,
                                None,
                            ),
                            (s1_corr_consumer, mma_corr_consumer, corr_epi_producer),
                            (row_idx, *value_args),
                        )
                    )
                # End of if not continue_cond
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # End of persistent scheduler loop
            tmem.relinquish_alloc_permit()
            # Synchronize before TMEM dealloc (done by the caller)
            self.tmem_dealloc_barrier.arrive_and_wait()
            tmem.free(tmem_ptr)
        return

    @cute.jit
    def _s2t_copy_and_partition(
        self,
        sQ: cute.Tensor,
        tQ: cute.Tensor,
    ):
        """Setup S2T copy for the 64-wide Q latent slices cached in TMEM."""
        tCsQ_compact = cute.filter_zeros(sQ)
        tCtQ_compact_staged = cute.filter_zeros(tQ)
        tCtQ_compact = cute.filter_zeros(tQ[None, None, None, 0])

        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp128x128bOp(tcgen05.CtaGroup.ONE),
            self.q_dtype,
        )
        tiled_copy_s2t = tcgen05.make_s2t_copy(copy_atom_s2t, tCtQ_compact)
        thr_copy_s2t = tiled_copy_s2t.get_slice(0)

        tCsQ_s2t_ = thr_copy_s2t.partition_S(tCsQ_compact)
        tCsQ_s2t = tcgen05.get_s2t_smem_desc_tensor(tiled_copy_s2t, tCsQ_s2t_)
        tCtQ_s2t = thr_copy_s2t.partition_D(tCtQ_compact_staged)
        return tiled_copy_s2t, tCsQ_s2t, tCtQ_s2t

    @cute.jit
    def _copy_q_latent_to_tmem(
        self,
        tiled_copy_q: cute.TiledCopy,
        tCsQ_s2t: cute.Tensor,
        tCtQ_s2t: cute.Tensor,
        q_stage_idx: Int32,
        num_cached_kphases: int,
    ) -> None:
        """Copy the leading Q kphases of one CTA Q tile from SMEM to TMEM.

        The last mode of `tCsQ_s2t` / `tCtQ_s2t` is `(kphase, pipe_stage)`.
        `q_stage_idx` selects the pipe stage at runtime;
        `num_cached_kphases` is the per-Q-slot TMEM residency depth.
        """
        for q_phase_idx in cutlass.range_constexpr(num_cached_kphases):
            for k_block in cutlass.range_constexpr(cute.size(tCtQ_s2t.shape[3])):
                cute.copy(
                    tiled_copy_q,
                    tCsQ_s2t[None, None, None, k_block, (q_phase_idx, q_stage_idx)],
                    tCtQ_s2t[None, None, None, k_block, (q_phase_idx, q_stage_idx)],
                )

    @cute.jit
    def mma_qk_mixed(
        self,
        tiled_mma_smem: cute.TiledMma,
        tiled_mma_tmem: cute.TiledMma,
        tensor_args: Tuple,
        pipeline_args: Tuple,
        pipeline_tokens: Tuple = (None, None),
        num_cached_kphases: int = None,
    ) -> Tuple[
        pipeline.PipelineProducer,
        pipeline.PipelineProducer,
    ]:
        """Perform a QK GEMM step with Q latent kphases in TMEM and the trailing kphase(s) in SMEM."""
        tSrQi, tTrQ_tmem, q_stage_idx, tSrK, tStSi = tensor_args
        mma_si_producer, si_corr_producer = pipeline_args
        si_peek_status, veci_peek_status = pipeline_tokens
        if cutlass.const_expr(num_cached_kphases is None):
            num_cached_kphases = self.q_mixed_tmem_kphases

        si_handle = mma_si_producer.acquire_and_advance(si_peek_status)
        veci_handle = si_corr_producer.acquire_and_advance(veci_peek_status)
        veci_handle.commit()

        for kphase_idx in cutlass.range_constexpr(self.q_mixed_total_kphases):
            tiled_mma_smem.set(tcgen05.Field.ACCUMULATE, kphase_idx != 0)
            if kphase_idx < num_cached_kphases:
                tiled_mma_tmem.set(tcgen05.Field.ACCUMULATE, kphase_idx != 0)
                cute.gemm(
                    tiled_mma_tmem,
                    tStSi,
                    tTrQ_tmem[None, None, 0, (kphase_idx, q_stage_idx)],
                    tSrK[None, None, kphase_idx],
                    tStSi,
                )
            else:
                kphase_coord = (None, None, kphase_idx)
                cute.gemm(
                    tiled_mma_smem,
                    tStSi,
                    tSrQi[kphase_coord],
                    tSrK[kphase_coord],
                    tStSi,
                )
        si_handle.commit()
        return mma_si_producer, si_corr_producer

    @cute.jit
    def _mma_kv_iter(
        self,
        pv_is_sparse: cutlass.Constexpr,
        carried: Tuple,
        kv_ctx: Tuple,
    ) -> Tuple:
        # One pipelined KV step: QK0i / PV0(i-1) / QK1i / PV1(i-1);
        # ``pv_is_sparse`` is constexpr, so each PV body is static.
        # NOTE: tuple field order must match the MMA-warp pack sites.
        (
            tSrQ0,
            tSrQ1,
            tSrK,
            tOrV,
            tOrV_dense,
            tOrP0_h0,
            tOrP0_h1,
            tOrP1_h0,
            tOrP1_h1,
            tOrP0_dense,
            tOrP1_dense,
            tOtO0,
            tOtO1,
            tCtE_for_p0,
            tCtE_for_p1,
            tStS0,
            tStS1,
            tTrQ_tmem,
            q0_handle,
            q1_handle,
        ) = kv_ctx
        (
            load_kv_consumer,
            next_k_peek_status,
            next_s0_si_peek_status,
            next_s0_vec_peek_status,
            mma_s0_producer,
            s0_corr_producer,
            mma_s1_producer,
            s1_corr_producer,
            mma_corr_producer,
            p0_mma_consumer,
            p1_mma_consumer,
            pv_whether_acc,
            qk_tiled_mma,
            qk_tiled_mma_tmem,
            pv_tiled_mma,
            pv_tiled_mma_dense,
        ) = carried
        # Wait for Ki
        k_handle = load_kv_consumer.wait_and_advance(next_k_peek_status)
        tSrKi = tSrK[None, None, None, k_handle.index]
        # GEMM_QK0i (Q0 * Ki -> S0)
        if cutlass.const_expr(self.enable_q_mixed_residency):
            mma_s0_producer, s0_corr_producer = self.mma_qk_mixed(
                qk_tiled_mma,
                qk_tiled_mma_tmem,
                (tSrQ0, tTrQ_tmem, q0_handle.index, tSrKi, tStS0),
                (mma_s0_producer, s0_corr_producer),
                (next_s0_si_peek_status, next_s0_vec_peek_status),
                num_cached_kphases=self.q_mixed_tmem_kphases,
            )
        else:
            mma_s0_producer, s0_corr_producer = self.mma_qk(
                qk_tiled_mma,
                (tSrQ0, tSrKi, tStS0),
                (mma_s0_producer, s0_corr_producer),
                (next_s0_si_peek_status, next_s0_vec_peek_status),
            )
        next_s0_si_peek_status = mma_s0_producer.try_acquire()
        next_s0_vec_peek_status = s0_corr_producer.try_acquire()
        # Wait for Vi-1
        v_handle = load_kv_consumer.wait_and_advance()
        tOrVi = tOrV[None, None, None, v_handle.index]
        if cutlass.const_expr(pv_is_sparse):
            mma_corr_producer, p0_mma_consumer = self.mma_pv_sparse(
                pv_tiled_mma,
                pv_whether_acc,
                (tOrP0_h0, tOrP0_h1),
                tOrVi,
                tOtO0,
                tCtE_for_p0,
                (mma_corr_producer, p0_mma_consumer),
            )
        else:
            tOrVi_dense = tOrV_dense[None, None, None, v_handle.index]
            mma_corr_producer, p0_mma_consumer = self.mma_pv_sparse_or_dense(
                pv_tiled_mma,
                pv_tiled_mma_dense,
                False,
                pv_whether_acc,
                (tOrP0_h0, tOrP0_h1),
                tOrP0_dense,
                tOrVi,
                tOrVi_dense,
                tOtO0,
                tCtE_for_p0,
                (mma_corr_producer, p0_mma_consumer),
            )
        # GEMM_QK1i (Q1 * Ki -> S1)
        if cutlass.const_expr(self.enable_q_mixed_residency):
            mma_s1_producer, s1_corr_producer = self.mma_qk_mixed(
                qk_tiled_mma,
                qk_tiled_mma_tmem,
                (tSrQ1, tTrQ_tmem, q1_handle.index, tSrKi, tStS1),
                (mma_s1_producer, s1_corr_producer),
                num_cached_kphases=self.q_mixed_tmem_kphases,
            )
        else:
            mma_s1_producer, s1_corr_producer = self.mma_qk(
                qk_tiled_mma,
                (tSrQ1, tSrKi, tStS1),
                (mma_s1_producer, s1_corr_producer),
            )
        # Release Ki
        k_handle.release()
        next_k_peek_status = load_kv_consumer.try_wait()
        if cutlass.const_expr(pv_is_sparse):
            mma_corr_producer, p1_mma_consumer = self.mma_pv_sparse(
                pv_tiled_mma,
                pv_whether_acc,
                (tOrP1_h0, tOrP1_h1),
                tOrVi,
                tOtO1,
                tCtE_for_p1,
                (mma_corr_producer, p1_mma_consumer),
            )
        else:
            mma_corr_producer, p1_mma_consumer = self.mma_pv_sparse_or_dense(
                pv_tiled_mma,
                pv_tiled_mma_dense,
                False,
                pv_whether_acc,
                (tOrP1_h0, tOrP1_h1),
                tOrP1_dense,
                tOrVi,
                tOrVi_dense,
                tOtO1,
                tCtE_for_p1,
                (mma_corr_producer, p1_mma_consumer),
            )
        pv_whether_acc = True
        # Release Vi-1
        v_handle.release()
        return (
            load_kv_consumer,
            next_k_peek_status,
            next_s0_si_peek_status,
            next_s0_vec_peek_status,
            mma_s0_producer,
            s0_corr_producer,
            mma_s1_producer,
            s1_corr_producer,
            mma_corr_producer,
            p0_mma_consumer,
            p1_mma_consumer,
            pv_whether_acc,
            qk_tiled_mma,
            qk_tiled_mma_tmem,
            pv_tiled_mma,
            pv_tiled_mma_dense,
        )

    @cute.jit
    def mma_pv_sparse_or_dense(
        self,
        sparse_tiled_mma: cute.TiledMma,
        dense_tiled_mma: cute.TiledMma,
        is_tile_sparse: bool,
        whether_acc: bool,
        tOrPi_halves: Tuple,
        tOrPi_dense: cute.Tensor,
        tOrVi: cute.Tensor,
        tOrVi_dense: cute.Tensor,
        tOtOi: cute.Tensor,
        tCtEi: cute.Tensor,
        pipeline_args: Tuple,
    ) -> Tuple[
        pipeline.PipelineProducer,
        pipeline.PipelineConsumer,
    ]:
        """Perform a PV GEMM step on a fully-unmasked tile (sparse MMA.SP) or a boundary tile (dense MMA)."""
        mma_corr_producer, pi_mma_consumer = pipeline_args
        # 0. Make sure Vi is ready when calling mma_pv
        # 1. acquire Oi
        oi_handle = mma_corr_producer.acquire_and_advance()
        # 2. wait for Pi (compressed + metadata for sparse, full-width for dense)
        pi_handle = pi_mma_consumer.wait_and_advance()
        # 3. gemm
        if is_tile_sparse:
            local_tiled_mma = sparse_tiled_mma.with_()
            local_tiled_mma.set(tcgen05.Field.ACCUMULATE, whether_acc)
            for e_idx, tOrPi_half in enumerate(tOrPi_halves):
                coord = (None, None, e_idx)
                local_tiled_mma.set(tcgen05.Field.METADATA, tCtEi[coord].iterator)
                cute.gemm(
                    local_tiled_mma,
                    tOtOi,
                    tOrPi_half,
                    tOrVi[coord],
                    tOtOi,
                )
                local_tiled_mma.set(tcgen05.Field.ACCUMULATE, True)
        else:
            local_tiled_mma = dense_tiled_mma.with_()
            local_tiled_mma.set(tcgen05.Field.ACCUMULATE, whether_acc)
            num_kphases = cute.size(tOrPi_dense, mode=[2])
            for kphase_idx in cutlass.range(num_kphases, unroll_full=True):
                kphase_coord = (None, None, kphase_idx)
                cute.gemm(
                    local_tiled_mma,
                    tOtOi,
                    tOrPi_dense[kphase_coord],
                    tOrVi_dense[kphase_coord],
                    tOtOi,
                )
                local_tiled_mma.set(tcgen05.Field.ACCUMULATE, True)
        # 4. commit Pi
        pi_handle.release()
        # 5. commit Oi
        oi_handle.commit()
        return mma_corr_producer, pi_mma_consumer

    @cute.jit
    def mma_pv_sparse(
        self,
        tiled_mma: cute.TiledMma,
        whether_acc: bool,
        tOrPi_halves: Tuple,
        tOrVi: cute.Tensor,
        tOtOi: cute.Tensor,
        tCtEi: cute.Tensor,
        pipeline_args: Tuple,
    ) -> Tuple[
        pipeline.PipelineProducer,
        pipeline.PipelineConsumer,
    ]:
        """Perform a sparse PV GEMM step on fully-unmasked tiles."""
        mma_corr_producer, pi_mma_consumer = pipeline_args
        oi_handle = mma_corr_producer.acquire_and_advance()
        pi_handle = pi_mma_consumer.wait_and_advance()
        local_tiled_mma = tiled_mma.with_()
        local_tiled_mma.set(tcgen05.Field.ACCUMULATE, whether_acc)
        for e_idx, tOrPi_half in enumerate(tOrPi_halves):
            coord = (None, None, e_idx)
            local_tiled_mma.set(tcgen05.Field.METADATA, tCtEi[coord].iterator)
            cute.gemm(
                local_tiled_mma,
                tOtOi,
                tOrPi_half,
                tOrVi[coord],
                tOtOi,
            )
            local_tiled_mma.set(tcgen05.Field.ACCUMULATE, True)
        pi_handle.release()
        oi_handle.commit()
        return mma_corr_producer, pi_mma_consumer

    @cute.jit
    def _is_sparse_kv_iter(
        self,
        kv_iter: Int32,
        leading_mask_count: Int32,
        unmask_count: Int32,
    ) -> bool:
        """Return True when ``kv_iter`` falls inside the fully unmasked KV segment."""
        return kv_iter >= leading_mask_count and kv_iter < (
            leading_mask_count + unmask_count
        )

    @cute.jit
    def softmax_step_dense(
        self,
        stage,
        iter_args: Tuple,
        stats_args: Tuple,
        pipeline_args: Tuple,
        value_args: Tuple,
        atom_args: Tuple,
        tensor_args: Tuple,
    ) -> Tuple[Tuple, Tuple]:
        """Boundary-tile softmax: apply position mask and write a full-width dense P tile."""
        row_sum, row_max = stats_args
        cS, is_last_iter = iter_args
        seqlen_k, seqlen_q, scale_softmax_log2, window_size_left, window_size_right = (
            value_args
        )
        (
            si_peek_status,
            mma_si_consumer,
            si_corr_producer,
            pi_mma_producer,
            inplace_producer,
            inplace_consumer,
        ) = pipeline_args
        (
            qk_thr_mma,
            _,
            _,
            tiled_tmem_store_vec,
            _,
            _,
            thr_tmem_store_vec,
            tiled_tmem_dense_load,
            tiled_tmem_dense_store,
            thr_tmem_dense_load,
            thr_tmem_dense_store,
        ) = atom_args
        (
            _,
            tTMEM_DENSE_LOADtS,
            tTMEM_DENSE_STOREtS,
            tTMEM_STORE_VECtS,
            _,
            _,
            _,
            _,
            _,
        ) = tensor_args

        tScS = qk_thr_mma.partition_C(cS)
        tScS_vec_layout = cute.composition(tScS.layout, cute.make_layout((128, 2)))
        tScS_vec = cute.make_tensor(tScS.iterator, tScS_vec_layout)
        tilePlikeFP32_dense = self.qk_mma_tiler[1] // Float32.width * self.q_dtype.width
        tScS_P_dense_layout = cute.composition(
            tScS.layout, cute.make_layout((128, tilePlikeFP32_dense))
        )
        tScS_P_dense = cute.make_tensor(tScS.iterator, tScS_P_dense_layout)
        tTMEM_DENSE_LOADcS = thr_tmem_dense_load.partition_D(tScS)
        tTMEM_DENSE_STOREcS = thr_tmem_dense_store.partition_S(tScS_P_dense)
        tTMEM_STORE_VECcS = thr_tmem_store_vec.partition_S(tScS_vec)

        # Wait for Si
        si_handle = mma_si_consumer.wait_and_advance(si_peek_status)
        old_row_max = row_max
        tTMEM_LOADrS = cute.make_rmem_tensor(
            tTMEM_DENSE_LOADcS.shape, self.qk_acc_dtype
        )
        cute.copy(tiled_tmem_dense_load, tTMEM_DENSE_LOADtS, tTMEM_LOADrS)

        fmha_utils.FusedMask.apply_mask(
            self.mask_type,
            tTMEM_LOADrS,
            tTMEM_DENSE_LOADcS,
            seqlen_q,
            seqlen_k,
            window_size_left,
            window_size_right,
            use_causal_setp_selp_inline=cutlass.const_expr(
                self.use_causal_setp_selp_inline
                and (
                    window_size_left is not None
                    or window_size_right is not None
                    or self.mask_type is fmha_utils.MaskEnum.RESIDUAL_MASK
                )
            ),
        )

        tile_row_max = tTMEM_LOADrS.load().reduce(
            cute.ReductionOp.MAX, -cutlass.Float32.inf, 0
        )
        row_max = cute.arch.fmax(row_max, tile_row_max)
        si_handle.release()
        # S0 -> P1 / S1 -> P0
        inplace_producer.commit()
        inplace_producer.advance()

        row_max_safe = row_max
        if row_max == -cutlass.Float32.inf:
            row_max_safe = 0.0
        if cutlass.const_expr(self.rescale_threshold > 0.0):
            if (
                row_max_safe - old_row_max
            ) * scale_softmax_log2 <= self.rescale_threshold:
                row_max_safe = old_row_max

        tTMEM_STORE_VECrS = cute.make_rmem_tensor(
            tTMEM_STORE_VECcS.shape, self.qk_acc_dtype
        )
        tTMEM_STORE_VECrS[0] = old_row_max
        tTMEM_STORE_VECrS[1] = row_max_safe
        vec_i_peek_status = si_corr_producer.try_acquire()

        # Reinterpret the dense P registers in q_dtype for FP8 CVT
        tTMEM_STORErS_x4 = cute.make_rmem_tensor(
            tTMEM_DENSE_STOREcS.shape, self.qk_acc_dtype
        )
        tTMEM_STORErS_x4_e = cute.make_tensor(
            cute.recast_ptr(tTMEM_STORErS_x4.iterator, dtype=self.q_dtype),
            tTMEM_LOADrS.layout,
        )
        scale = scale_softmax_log2
        minus_row_max_scale = (0.0 - row_max_safe) * scale
        if cutlass.const_expr(self.q_dtype.width == 8 and self.p_fp8_prescale_log2 > 0):
            minus_row_max_scale = minus_row_max_scale + self.p_fp8_prescale_log2

        ARV_PIPE_COUNT = 4
        FMA_PIPE_COUNT = 8
        CVT_PIPE_COUNT = 8 if self.q_dtype.width == 8 else 4
        CVT_PER_STEP = 4 if self.q_dtype.width == 8 else 2
        assert CVT_PIPE_COUNT % CVT_PER_STEP == 0, (
            f"CVT_PIPE_COUNT {CVT_PIPE_COUNT} must be divisible by CVT_PER_STEP {CVT_PER_STEP}"
        )
        tTMEM_LOADrS_cvt = cute.logical_divide(
            tTMEM_LOADrS, cute.make_layout(CVT_PER_STEP)
        )
        tTMEM_STORErS_x4_e_cvt = cute.logical_divide(
            tTMEM_STORErS_x4_e, cute.make_layout(CVT_PER_STEP)
        )

        if cutlass.const_expr(not self.enable_fp16_mixed_softmax):
            for i in cutlass.range_constexpr(0, FMA_PIPE_COUNT, 2):
                tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1] = cute.arch.fma_packed_f32x2(
                    (tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1]),
                    (scale, scale),
                    (minus_row_max_scale, minus_row_max_scale),
                )

        if cutlass.const_expr(self.enable_fp16_mixed_softmax):
            exp_buf_dense = cute.make_rmem_tensor(tTMEM_LOADrS.layout, Float16)
            exp_buf_dense_cvt = cute.logical_divide(
                exp_buf_dense, cute.make_layout(CVT_PER_STEP)
            )

        vec_i_handle = si_corr_producer.acquire_and_advance(vec_i_peek_status)
        cute.copy(tiled_tmem_store_vec, tTMEM_STORE_VECrS, tTMEM_STORE_VECtS)
        cute.arch.fence_view_async_tmem_store()
        vec_i_handle.commit()

        if cutlass.const_expr(self.enable_fp16_mixed_softmax):
            acc_scale_f16 = self._fp16_mixed_correction_factor(
                old_row_max, row_max_safe, scale, half_scale=True
            )
        else:
            acc_scale_ = scale * (old_row_max - row_max_safe)
            acc_scale = cute.math.exp2(acc_scale_, fastmath=True) * 0.5
        if cutlass.const_expr(self.enable_sequence_barrier):
            self._sequence_barrier(stage).arrive_and_wait()
        pi_peek_status = None
        if cutlass.const_expr(self.enable_fp16_mixed_softmax):
            pi_peek_status = pi_mma_producer.try_acquire()

        if cutlass.const_expr(self.enable_fp16_mixed_softmax):
            row_sum_pair = fmha_utils.fma_packed_f32x2_f16x2_f32x2_f32x2(
                (acc_scale_f16, acc_scale_f16),
                (row_sum, row_sum),
                (Float32(0.0), Float32(0.0)),
            )
            local_row_sum = row_sum_pair
        else:
            row_sum *= acc_scale
            local_row_sum = (row_sum, row_sum)
        if cutlass.const_expr(self.enable_fp16_mixed_softmax):
            row_max_for_exp = row_max_safe
            if cutlass.const_expr(
                self.q_dtype.width == 8 and self.p_fp8_prescale_log2 > 0
            ):
                row_max_for_exp = row_max_safe - self.p_fp8_prescale_log2 / scale
            local_row_sum, inplace_consumer = self.apply_exp_and_cvt_fp16_mixed(
                tTMEM_LOADrS,
                exp_buf_dense,
                exp_buf_dense_cvt,
                tTMEM_STORErS_x4_e_cvt,
                stage,
                scale,
                row_max_for_exp,
                local_row_sum,
                inplace_consumer,
                CVT_PER_STEP,
            )
        else:
            (
                local_row_sum,
                inplace_consumer,
                pi_peek_status,
                _,
            ) = self.apply_exp_and_cvt(
                tTMEM_LOADrS,
                tTMEM_LOADrS_cvt,
                tTMEM_STORErS_x4_e_cvt,
                stage,
                scale,
                minus_row_max_scale,
                local_row_sum,
                pi_mma_producer,
                inplace_consumer,
                cute.size(tTMEM_LOADrS),
                0,
                CVT_PIPE_COUNT,
                CVT_PER_STEP,
                FMA_PIPE_COUNT,
                ARV_PIPE_COUNT,
            )

        pi_handle = pi_mma_producer.acquire_and_advance(pi_peek_status)
        cute.copy(tiled_tmem_dense_store, tTMEM_STORErS_x4, tTMEM_DENSE_STOREtS)
        cute.arch.fence_view_async_tmem_store()
        row_sum = local_row_sum[0] + local_row_sum[1]
        cute.arch.fence_view_async_tmem_store()

        # Notify tensor core warp that softmax(S->P) is ready.
        pi_handle.commit()

        if not is_last_iter:
            si_peek_status = mma_si_consumer.try_wait()
        stats_args = (row_sum, row_max_safe)
        pipeline_args = (
            si_peek_status,
            mma_si_consumer,
            si_corr_producer,
            pi_mma_producer,
            inplace_producer,
            inplace_consumer,
        )
        return stats_args, pipeline_args

    @cute.jit
    def softmax_step(
        self,
        stage,
        whether_apply_mask: bool,
        iter_args: Tuple,
        stats_args: Tuple,
        pipeline_args: Tuple,
        value_args: Tuple,
        atom_args: Tuple,
        tensor_args: Tuple,
    ) -> Tuple[Tuple, Tuple]:
        """Perform a single step of the softmax computation on a block of attention scores.

        Fully-unmasked tiles take the sparse path: TMEM load STAT+SPARSIFY selects 2-of-4 by
        value, exp2 normalization runs on the compressed half, and the compressed
        P + metadata are stored to TMEM for sparse MMA.SP. Boundary tiles take the
        dense path via :py:meth:`softmax_step_dense`.

        :param stage: Processing stage (0 for first half, 1 for second half)
        :type stage: int
        :param whether_apply_mask: Whether to apply attention masking (dense path)
        :type whether_apply_mask: bool
        :param iter_args: Tuple containing the counting tensor and last-iter flag
        :type iter_args: Tuple
        :param stats_args: Tuple containing row_sum and row_max
        :type stats_args: Tuple
        :param pipeline_args: Tuple of pipeline handles for MMA, correction, and inplace sync
        :type pipeline_args: Tuple
        :param value_args: Tuple containing seqlen_k, seqlen_q, scale_softmax_log2, window_size_left/right
        :type value_args: Tuple
        :param atom_args: Tuple of MMA and TMEM copy atoms
        :type atom_args: Tuple
        :param tensor_args: Tuple of softmax-related tensors
        :type tensor_args: Tuple
        :return: Updated stats_args and pipeline_args
        :rtype: Tuple[Tuple, Tuple]
        """
        if cutlass.const_expr(whether_apply_mask):
            return self.softmax_step_dense(
                stage,
                iter_args,
                stats_args,
                pipeline_args,
                value_args,
                atom_args,
                tensor_args,
            )
        row_sum, row_max = stats_args
        cS, is_last_iter = iter_args
        seqlen_k, seqlen_q, scale_softmax_log2, window_size_left, window_size_right = (
            value_args
        )
        (
            si_peek_status,
            mma_si_consumer,
            si_corr_producer,
            pi_mma_producer,
            inplace_producer,
            inplace_consumer,
        ) = pipeline_args
        (
            qk_thr_mma,
            sp_tiled_copy,
            tiled_tmem_store,
            tiled_tmem_store_vec,
            tiled_tmem_store_meta_e0,
            tiled_tmem_store_meta_e1,
            thr_tmem_store_vec,
            _,  # tiled_tmem_dense_load (unused in sparse path)
            _,  # tiled_tmem_dense_store (unused in sparse path)
            _,  # thr_tmem_dense_load (unused in sparse path)
            _,  # thr_tmem_dense_store (unused in sparse path)
        ) = atom_args
        (
            tSP_src,
            _,  # tTMEM_DENSE_LOADtS (unused in sparse path)
            _,  # tTMEM_DENSE_STOREtS (unused in sparse path)
            tTMEM_STORE_VECtS,
            tTMEM_STOREtS_x4,
            tTMEM_STOREtMeta_e0,
            tTMEM_STOREtMeta_e1,
            tTMEM_STOREcS_P,
            tTMEM_STOREcS_Meta,
        ) = tensor_args

        tScS = qk_thr_mma.partition_C(cS)
        tScS_vec_layout = cute.composition(tScS.layout, cute.make_layout((128, 2)))
        tScS_vec = cute.make_tensor(tScS.iterator, tScS_vec_layout)
        tTMEM_STORE_VECcS = thr_tmem_store_vec.partition_S(tScS_vec)

        sp_compressed_per_thread = 128 // 2
        sp_meta_uint8_per_thread = 128 // 8

        sparse_dtype = cute.get_sparse_elem_type(
            num_logical=2,
            num_phys=1,
            elem_type=self.qk_acc_dtype,
        )
        rData_raw = cute.make_rmem_tensor(
            ((sp_compressed_per_thread, 1), 1),
            self.qk_acc_dtype,
        )
        rData = cute.make_tensor(
            cute.recast_ptr(rData_raw.iterator, dtype=sparse_dtype),
            rData_raw.layout,
        )
        meta_sparse_dtype = cute.get_sparse_elem_type(
            num_logical=8,
            num_phys=1,
            elem_type=cutlass.Uint8,
        )
        rMeta_raw = cute.make_rmem_tensor(
            ((sp_meta_uint8_per_thread, 1), 1),
            cutlass.Uint8,
        )
        rMeta = cute.make_tensor(
            cute.recast_ptr(rMeta_raw.iterator, dtype=meta_sparse_dtype),
            rMeta_raw.layout,
        )
        rStat = cute.make_rmem_tensor((1, 1), self.qk_acc_dtype)

        # Wait for Si
        si_handle = mma_si_consumer.wait_and_advance(si_peek_status)
        old_row_max = row_max

        # TMEM load STAT+SPARSIFY returns compressed values, metadata, and row max.
        cute.copy(sp_tiled_copy, tSP_src[None, None, 0, 0], (rData, rMeta, rStat))
        # The tcgen05.ld is asynchronous: wait for it before the S stage is
        # released, or the MMA warp may overwrite it while the load is in flight.
        cute.arch.fence_view_async_tmem_load()
        si_handle.release()
        # S0 -> P1 / S1 -> P0
        inplace_producer.commit()
        inplace_producer.advance()

        row_max = cute.arch.fmax(row_max, rStat[0])
        row_max_safe = row_max
        if row_max == -cutlass.Float32.inf:
            row_max_safe = 0.0
        if cutlass.const_expr(self.rescale_threshold > 0.0):
            if (
                row_max_safe - old_row_max
            ) * scale_softmax_log2 <= self.rescale_threshold:
                row_max_safe = old_row_max

        tTMEM_STORE_VECrS = cute.make_rmem_tensor(
            tTMEM_STORE_VECcS.shape, self.qk_acc_dtype
        )
        tTMEM_STORE_VECrS[0] = old_row_max
        tTMEM_STORE_VECrS[1] = row_max_safe
        vec_i_peek_status = si_corr_producer.try_acquire()

        scale = scale_softmax_log2
        minus_row_max_scale = (0.0 - row_max_safe) * scale
        if cutlass.const_expr(self.q_dtype.width == 8 and self.p_fp8_prescale_log2 > 0):
            minus_row_max_scale = minus_row_max_scale + self.p_fp8_prescale_log2
        ARV_PIPE_COUNT = 4
        FMA_PIPE_COUNT = 8
        CVT_PIPE_COUNT = 8 if self.q_dtype.width == 8 else 4
        CVT_PER_STEP = 4 if self.q_dtype.width == 8 else 2
        assert CVT_PIPE_COUNT % CVT_PER_STEP == 0, (
            f"CVT_PIPE_COUNT {CVT_PIPE_COUNT} must be divisible by CVT_PER_STEP {CVT_PER_STEP}"
        )

        rP_compressed = cute.make_rmem_tensor(
            cute.flatten(rData_raw).shape, self.q_dtype
        )
        rData_flat = cute.flatten(rData_raw)
        rP_flat = cute.flatten(rP_compressed)
        rData_cvt = cute.logical_divide(rData_flat, cute.make_layout(CVT_PER_STEP))
        rP_cvt = cute.logical_divide(rP_flat, cute.make_layout(CVT_PER_STEP))

        if cutlass.const_expr(not self.enable_fp16_mixed_softmax):
            for i in cutlass.range_constexpr(0, FMA_PIPE_COUNT, 2):
                rData_flat[i], rData_flat[i + 1] = cute.arch.fma_packed_f32x2(
                    (rData_flat[i], rData_flat[i + 1]),
                    (scale, scale),
                    (minus_row_max_scale, minus_row_max_scale),
                )

        # FP16 mixed: allocate an FP16 scratch buffer for exp(S - max) results.
        if cutlass.const_expr(self.enable_fp16_mixed_softmax):
            exp_buf = cute.make_rmem_tensor(cute.flatten(rData_raw).shape, Float16)
            exp_buf_cvt = cute.logical_divide(exp_buf, cute.make_layout(CVT_PER_STEP))

        vec_i_handle = si_corr_producer.acquire_and_advance(vec_i_peek_status)
        cute.copy(tiled_tmem_store_vec, tTMEM_STORE_VECrS, tTMEM_STORE_VECtS)
        cute.arch.fence_view_async_tmem_store()
        # Notify correction wg that row_max is ready
        vec_i_handle.commit()

        if cutlass.const_expr(self.enable_fp16_mixed_softmax):
            # Correction factor via the packed-f16 chain, then * 0.5
            # (matched to the FP32 path's ``exp2(...) * 0.5``).
            acc_scale_f16 = self._fp16_mixed_correction_factor(
                old_row_max, row_max_safe, scale, half_scale=True
            )
        else:
            acc_scale_ = scale * (old_row_max - row_max_safe)
            acc_scale = cute.math.exp2(acc_scale_, fastmath=True) * 0.5
        if cutlass.const_expr(self.enable_sequence_barrier):
            self._sequence_barrier(stage).arrive_and_wait()
        pi_peek_status = None
        if cutlass.const_expr(self.enable_fp16_mixed_softmax):
            pi_peek_status = pi_mma_producer.try_acquire()

        if cutlass.const_expr(self.enable_fp16_mixed_softmax):
            # row_sum_f32 *= acc_scale_f16, via FHFMA2 with zero accumulator.
            row_sum_pair = fmha_utils.fma_packed_f32x2_f16x2_f32x2_f32x2(
                (acc_scale_f16, acc_scale_f16),
                (row_sum, row_sum),
                (Float32(0.0), Float32(0.0)),
            )
            local_row_sum = row_sum_pair
        else:
            row_sum *= acc_scale
            local_row_sum = (row_sum, row_sum)
        if cutlass.const_expr(self.enable_fp16_mixed_softmax):
            # Fold the FP8 pre-scale into the row_max so the picture-aligned
            # FHADD2 step ``(S - row_max).to_f16`` followed by HMUL2 / ex2
            # produces ``exp((S - row_max) * scale + p_fp8_prescale)``.
            row_max_for_exp = row_max_safe
            if cutlass.const_expr(
                self.q_dtype.width == 8 and self.p_fp8_prescale_log2 > 0
            ):
                row_max_for_exp = row_max_safe - self.p_fp8_prescale_log2 / scale
            local_row_sum, inplace_consumer = self.apply_exp_and_cvt_fp16_mixed(
                rData_flat,
                exp_buf,
                exp_buf_cvt,
                rP_cvt,
                stage,
                scale,
                row_max_for_exp,
                local_row_sum,
                inplace_consumer,
                CVT_PER_STEP,
            )
        else:
            (
                local_row_sum,
                inplace_consumer,
                pi_peek_status,
                _,
            ) = self.apply_exp_and_cvt(
                rData_flat,
                rData_cvt,
                rP_cvt,
                stage,
                scale,
                minus_row_max_scale,
                local_row_sum,
                pi_mma_producer,
                inplace_consumer,
                cute.size(rData_flat),
                0,
                CVT_PIPE_COUNT,
                CVT_PER_STEP,
                FMA_PIPE_COUNT,
                ARV_PIPE_COUNT,
            )

        rP_f32 = cute.make_tensor(
            cute.recast_ptr(rP_compressed.iterator, dtype=self.qk_acc_dtype),
            tTMEM_STOREcS_P.shape,
        )
        rMeta_f32_e0 = cute.make_tensor(
            cute.recast_ptr(rMeta_raw.iterator, dtype=self.qk_acc_dtype),
            tTMEM_STOREcS_Meta.shape,
        )
        rMeta_f32_e1 = cute.make_tensor(
            cute.recast_ptr(rMeta_raw.iterator, dtype=self.qk_acc_dtype)
            + cute.size(tTMEM_STOREcS_Meta),
            tTMEM_STOREcS_Meta.shape,
        )
        pi_handle = pi_mma_producer.acquire_and_advance(pi_peek_status)
        cute.copy(tiled_tmem_store, rP_f32, tTMEM_STOREtS_x4)
        cute.copy(tiled_tmem_store_meta_e0, rMeta_f32_e0, tTMEM_STOREtMeta_e0)
        cute.copy(tiled_tmem_store_meta_e1, rMeta_f32_e1, tTMEM_STOREtMeta_e1)
        cute.arch.fence_view_async_tmem_store()
        row_sum = local_row_sum[0] + local_row_sum[1]
        cute.arch.fence_view_async_tmem_store()

        pi_handle.commit()

        if not is_last_iter:
            si_peek_status = mma_si_consumer.try_wait()
        stats_args = (row_sum, row_max_safe)
        pipeline_args = (
            si_peek_status,
            mma_si_consumer,
            si_corr_producer,
            pi_mma_producer,
            inplace_producer,
            inplace_consumer,
        )
        return stats_args, pipeline_args

    # ------------------------------------------------------------------
    # FP16-mixed softmax helpers (only used when self.enable_fp16_mixed_softmax is True).
    # ------------------------------------------------------------------

    @cute.jit
    def apply_exp_and_cvt_fp16_mixed(
        self,
        rData_flat,  # (N,) Float32, raw S values (post-STAT reduction)
        exp_buf,  # (N,) Float16, scratch for exp results
        exp_buf_cvt,  # logical_divide(exp_buf,  cute.make_layout(CVT_PER_STEP))
        rP_cvt,  # logical_divide(rP (q_dtype), cute.make_layout(CVT_PER_STEP))
        stage,
        scale_softmax_log2,  # Float32 scalar
        row_max_safe,  # Float32 scalar
        local_row_sum,  # (Float32, Float32)
        inplace_consumer,
        CVT_PER_STEP: int,
    ):
        """Packed-FP16 ``exp2((S - max) * scale_log2)`` + row sum + FP8 CVT.

        Uses the original Rubin mixed-precision recipe: packed mixed-source
        addition rounds ``S - max`` directly to F16x2, packed F16
        multiplication applies the scale, and the result feeds packed EX2.
        Consecutive pairs update alternating row-sum chains, and each
        conversion group ends at a warp-switch issue boundary. The final
        merge reassociates FP32 additions but preserves the online softmax sum
        mathematically.

        The FP8 prescale is folded into ``row_max_safe`` by the caller so
        ``exp2((S - row_max_adj) * scale_log2)`` includes the prescale factor.
        """
        total = cute.size(rData_flat)
        row_sum_lag: cutlass.Constexpr = 24
        # This rounds to f16 once (after scale) instead of twice.
        scale_pair = (scale_softmax_log2, scale_softmax_log2)
        minus_row_max_scale = (Float32(0.0) - row_max_safe) * scale_softmax_log2
        offset_pair = (minus_row_max_scale, minus_row_max_scale)
        # Keep the carried online sum in only one chain. Initializing both
        # from local_row_sum would count the previous K tile twice after the
        # merge.
        local_row_sums = [
            local_row_sum,
            (Float32(0.0), Float32(0.0)),
        ]

        for i in cutlass.range_constexpr(0, total, 2):
            scaled_pair = cute.arch.fma_packed_f32x2(
                (rData_flat[i], rData_flat[i + 1]), scale_pair, offset_pair
            )
            exp_pair = fmha_utils.cvt_packed_f16x2_f32x2(scaled_pair)
            exp_pair = fmha_utils.ex2_packed_f16x2(exp_pair)
            exp_buf[i] = exp_pair[0]
            exp_buf[i + 1] = exp_pair[1]
            if cutlass.const_expr((i + 2) % CVT_PER_STEP == 0):
                fmha_utils.cvt_f16x4_to_f8x4(
                    exp_buf_cvt[None, i // CVT_PER_STEP],
                    rP_cvt[None, i // CVT_PER_STEP],
                )
            if cutlass.const_expr(i >= row_sum_lag):
                row_sum_index = i - row_sum_lag
                row_sum_slot = (row_sum_index // 2) % 2
                local_row_sums[row_sum_slot] = fmha_utils.add_packed_f32x2_f16x2_f32x2(
                    (
                        exp_buf[row_sum_index],
                        exp_buf[row_sum_index + 1],
                    ),
                    local_row_sums[row_sum_slot],
                )
            if cutlass.const_expr(self.enable_sequence_barrier and i == total - 4):
                self._sequence_barrier(1 - stage).arrive()

        row_sum_tail_start: cutlass.Constexpr = total - row_sum_lag
        for i in cutlass.range_constexpr(row_sum_tail_start, total, 2):
            row_sum_slot = (i // 2) % 2
            local_row_sums[row_sum_slot] = fmha_utils.add_packed_f32x2_f16x2_f32x2(
                (exp_buf[i], exp_buf[i + 1]),
                local_row_sums[row_sum_slot],
            )
        local_row_sum = cute.arch.add_packed_f32x2(local_row_sums[0], local_row_sums[1])
        inplace_consumer.wait_and_advance()
        return local_row_sum, inplace_consumer

    @cute.jit
    def _fp16_mixed_correction_factor(
        self,
        old_row_max: Float32,
        row_max_safe: Float32,
        scale_softmax_log2: Float32,
        half_scale: bool = False,
    ) -> Float16:
        """Compute the correction scale in FP16 (used by both ``softmax_step``
        and ``correction_rescale``).

        Sequence (per the Rubin "Compute correction factor" row): a packed
        f16 subtract of the row-max delta, a packed f16 multiply by the
        softmax scale, then ``ex2.approx.f16x2``.

        When ``half_scale`` is True the result is multiplied by ``0.5`` to
        match the softmax_step pre-scaling of ``row_sum`` (the FP32 path uses
        ``cute.math.exp2(...) * 0.5`` here).
        """
        tmp_f16 = cute.arch.sub_packed_f16x2_f32x2_f32x2(
            (old_row_max, old_row_max),
            (row_max_safe, row_max_safe),
        )
        # The packed multiply reads FP32 sources; preserve the f16-rounded
        # delta by converting it back to FP32 before applying the FP32 scale.
        scaled_f16 = fmha_utils.mul_packed_f16x2_f32x2_f32x2(
            (Float32(tmp_f16[0]), Float32(tmp_f16[1])),
            (scale_softmax_log2, scale_softmax_log2),
        )
        exp_f16 = fmha_utils.ex2_packed_f16x2(scaled_f16)
        scale_f16 = exp_f16[0]
        if cutlass.const_expr(half_scale):
            scale_f16 = fmha_utils.mul_packed_f16x2(
                (scale_f16, scale_f16), (Float16(0.5), Float16(0.5))
            )[0]
        return scale_f16

    @cute.jit
    def correction_rescale(
        self,
        thr_mma: cute.ThrMma,
        tiled_tmem_load_vec: cute.TiledCopy,
        scale_softmax_log2: Float32,
        tensor_args: Tuple,
        pipeline_args: Tuple,
        oi_peek_status=None,
    ):
        """Rescale partial O accumulators using the new row-max.

        Overrides the Blackwell parent to optionally use the Rubin mixed
        precision recipe when ``self.enable_fp16_mixed_softmax`` is True:

        * Correction factor:  FHADD2 -> FHMUL2 -> MUFU.fp16x2.ex2 (FP16)
        * Apply correction:   FHFMA2.F32x2.F16x2.F32x2 (O *= scale_f16)

        Falls through to the parent's FP32 path otherwise.
        """
        if cutlass.const_expr(not self.enable_fp16_mixed_softmax):
            return super().correction_rescale(
                thr_mma,
                tiled_tmem_load_vec,
                scale_softmax_log2,
                tensor_args,
                pipeline_args,
                oi_peek_status,
            )

        tOtO, tTMEM_LOAD_VECtSi, tTMEM_LOAD_VECcS = tensor_args
        si_corr_consumer, mma_corr_consumer = pipeline_args

        pv_tiled_mma_shape = (
            self.pv_mma_tiler[0],
            self.pv_mma_tiler[1],
        )
        cO = cute.make_identity_tensor(pv_tiled_mma_shape)
        tOcO = thr_mma.partition_C(cO)
        corr_tile_size = 16  # tuneable parameter
        tmem_load_atom = cute.make_copy_atom(
            tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(corr_tile_size)),
            self.pv_acc_dtype,
        )
        tmem_store_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(corr_tile_size)),
            self.pv_acc_dtype,
        )
        tOtO_i_layout = cute.composition(
            tOtO.layout, cute.make_layout((128, corr_tile_size))
        )
        tOcO_i_layout = cute.composition(
            tOcO.layout, cute.make_layout((128, corr_tile_size))
        )
        tOtO_i = cute.make_tensor(tOtO.iterator, tOtO_i_layout)
        tOcO_i = cute.make_tensor(tOcO.iterator, tOcO_i_layout)
        tiled_tmem_load = tcgen05.make_tmem_copy(tmem_load_atom, tOtO_i)
        tiled_tmem_store = tcgen05.make_tmem_copy(tmem_store_atom, tOtO_i)
        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (self.threads_per_warp * len(self.correction_warp_ids))
        thr_tmem_load = tiled_tmem_load.get_slice(thread_idx)
        thr_tmem_store = tiled_tmem_store.get_slice(thread_idx)
        tTMEM_LOADtO = thr_tmem_load.partition_S(tOtO_i)
        tTMEM_LOADcO = thr_tmem_load.partition_D(tOcO_i)
        tTMEM_STOREtO = thr_tmem_store.partition_D(tOtO_i)
        num_tiles = self.cta_tiler[2] // corr_tile_size
        if cutlass.const_expr(self.enable_correction_double_buffer):
            tTMrO = cute.make_rmem_tensor((tTMEM_LOADcO.shape, 2), self.pv_acc_dtype)
            copy_layout = cute.make_layout(tTMrO.shape[0])
            view_0 = tTMrO[None, 0]
            view_1 = tTMrO[None, 1]
            tTMrO_copy = (
                cute.make_tensor(
                    view_0.iterator,
                    cute.composition(view_0.layout, copy_layout),
                ),
                cute.make_tensor(
                    view_1.iterator,
                    cute.composition(view_1.layout, copy_layout),
                ),
            )
        else:
            tTMrO = cute.make_rmem_tensor(
                (tTMEM_LOADcO.shape, num_tiles), self.pv_acc_dtype
            )
        tTMEM_LOAD_VECrS = cute.make_rmem_tensor(
            tTMEM_LOAD_VECcS.shape, self.qk_acc_dtype
        )
        # Wait for vec_i (row_wise current max & previous max)
        vec_i_handle = si_corr_consumer.wait_and_advance()
        cute.copy(tiled_tmem_load_vec, tTMEM_LOAD_VECtSi, tTMEM_LOAD_VECrS)
        cute.arch.fence_view_async_tmem_load()
        vec_i_handle.release()
        # Wait for Oi (peek-token aware: None/False falls back to blocking).
        oi_handle = mma_corr_consumer.wait_and_advance(oi_peek_status)
        next_oi_peek_status = cutlass.Boolean(False)
        vote_ballot_cnt = cute.arch.vote_ballot_sync(
            tTMEM_LOAD_VECrS[0] != tTMEM_LOAD_VECrS[1]
        )
        should_rescale = vote_ballot_cnt != 0
        if should_rescale:
            # FP16 correction scale -- FHADD2 / FHMUL2 / MUFU.fp16x2.ex2.
            scale_f16 = self._fp16_mixed_correction_factor(
                tTMEM_LOAD_VECrS[0], tTMEM_LOAD_VECrS[1], scale_softmax_log2
            )
            scale_pair_f16 = (scale_f16, scale_f16)
            zero_pair_f32 = (Float32(0.0), Float32(0.0))
            if cutlass.const_expr(self.enable_correction_double_buffer):
                num_elems = cute.size(tTMrO, mode=[0])
                # Prologue: load first tile into buffer 0
                cute.copy(tiled_tmem_load, tTMEM_LOADtO, tTMrO_copy[0])
                # Steady state.
                for i in cutlass.range_constexpr(1, num_tiles):
                    cute.copy(
                        tiled_tmem_load,
                        cute.make_tensor(
                            tTMEM_LOADtO.iterator + i * corr_tile_size,
                            tTMEM_LOADtO.layout,
                        ),
                        tTMrO_copy[i % 2],
                    )
                    for j in range(0, num_elems, 2):
                        # Apply correction: FHFMA2.F32x2.F16x2.F32x2 (O *= scale_f16).
                        tTMrO[j, (i - 1) % 2], tTMrO[j + 1, (i - 1) % 2] = (
                            fmha_utils.fma_packed_f32x2_f16x2_f32x2_f32x2(
                                scale_pair_f16,
                                (
                                    tTMrO[j, (i - 1) % 2],
                                    tTMrO[j + 1, (i - 1) % 2],
                                ),
                                zero_pair_f32,
                            )
                        )
                    cute.copy(
                        tiled_tmem_store,
                        tTMrO_copy[(i - 1) % 2],
                        cute.make_tensor(
                            tTMEM_STOREtO.iterator + (i - 1) * corr_tile_size,
                            tTMEM_STOREtO.layout,
                        ),
                    )
                next_oi_peek_status = mma_corr_consumer.try_wait()
                last = (num_tiles - 1) % 2
                for j in range(0, num_elems, 2):
                    tTMrO[j, last], tTMrO[j + 1, last] = (
                        fmha_utils.fma_packed_f32x2_f16x2_f32x2_f32x2(
                            scale_pair_f16,
                            (tTMrO[j, last], tTMrO[j + 1, last]),
                            zero_pair_f32,
                        )
                    )
                cute.copy(
                    tiled_tmem_store,
                    tTMrO_copy[last],
                    cute.make_tensor(
                        tTMEM_STOREtO.iterator + (num_tiles - 1) * corr_tile_size,
                        tTMEM_STOREtO.layout,
                    ),
                )
            else:
                for i in cutlass.range_constexpr(0, num_tiles):
                    tTMrO_i_ = tTMrO[None, i]
                    tTMrO_i = cute.make_tensor(
                        tTMrO_i_.iterator,
                        cute.composition(
                            tTMrO_i_.layout, cute.make_layout(tTMrO.shape[0])
                        ),
                    )
                    cute.copy(
                        tiled_tmem_load,
                        cute.make_tensor(
                            tTMEM_LOADtO.iterator + i * corr_tile_size,
                            tTMEM_LOADtO.layout,
                        ),
                        tTMrO_i,
                    )
                    for j in range(0, cute.size(tTMrO_i), 2):
                        tTMrO_i[j], tTMrO_i[j + 1] = (
                            fmha_utils.fma_packed_f32x2_f16x2_f32x2_f32x2(
                                scale_pair_f16,
                                (tTMrO_i[j], tTMrO_i[j + 1]),
                                zero_pair_f32,
                            )
                        )
                    cute.copy(
                        tiled_tmem_store,
                        tTMrO_i,
                        cute.make_tensor(
                            tTMEM_STOREtO.iterator + i * corr_tile_size,
                            tTMEM_STOREtO.layout,
                        ),
                    )
                next_oi_peek_status = mma_corr_consumer.try_wait()
        # Release Oi
        cute.arch.fence_view_async_tmem_store()
        oi_handle.release()
        return (si_corr_consumer, mma_corr_consumer), next_oi_peek_status

    # For both softmax0 and softmax1 warp group
    @cute.jit
    def softmax(
        self,
        stage,
        tensor_args: Tuple,
        pipeline_args: Tuple,
        inplace_args: Tuple,
        qk_thr_mma: cute.ThrMma,
        value_args: Tuple,
        mask_args: Tuple,
        sched_args: Tuple,
        e_tmem_layout: cute.Layout,
    ):
        """Compute softmax on attention scores from QK matrix multiplication.

        This method handles the softmax computation for either the first or second half of the
        attention matrix, depending on the 'stage' parameter. It calculates row-wise maximum
        and sum values needed for stable softmax computation, applies optional masking, and
        transforms raw attention scores into probability distributions.

        The implementation uses specialized memory access patterns and efficient math operations
        for computing exp(x) using exp2 functions. It also coordinates pipeline
        synchronization between MMA, correction, and sequence processing stages.

        :param stage: Processing stage (0 for first half, 1 for second half of attention matrix)
        :type stage: int
        :param seqlen_k: Length of the key sequence
        :type seqlen_k: Int32
        :param seqlen_q: Length of the query sequence
        :type seqlen_q: Int32
        :param cum_seqlen_q: Cumulative sequence lengths for queries
        :type cum_seqlen_q: cute.Tensor | None
        :param cum_seqlen_k: Cumulative sequence lengths for keys
        :type cum_seqlen_k: cute.Tensor | None
        :param scale_softmax_log2: Log2 scale factor for softmax operation
        :type scale_softmax_log2: Float32
        :param qk_thr_mma: Thread MMA operation for QK matrix multiplication
        :type qk_thr_mma: cute.ThrMma
        :param tStS: Shared tensor for softmax input/output
        :type tStS: cute.Tensor
        :param tStSi: Input tensor containing attention scores
        :type tStSi: cute.Tensor
        :param window_size_left: Left-side sliding window size for attention masking.
        :type window_size_left: Optional[Int32]
        :param window_size_right: Right-side sliding window size for attention masking.
        :type window_size_right: Optional[Int32]
        :param mma_si_consumer: Pipeline for synchronizing with Si tensors
        :type mma_si_consumer: pipeline.PipelineConsumer
        :param si_corr_producer: Pipeline for synchronizing with correction operations
        :type si_corr_producer: pipeline.PipelineProducer
        :param pi_mma_producer: Pipeline for synchronizing with Pi tensors
        :type pi_mma_producer: pipeline.PipelineProducer
        :param tile_sched_params: Parameters for tile scheduling
        :type tile_sched_params: fmha_utils.FmhaStaticTileSchedulerParams
        :param fused_mask: Compute trip counts and apply masking for attention blocks
        :type fused_mask: fmha_utils.FusedMask
        """
        tStS, tStSi, cum_seqlen_k, cum_seqlen_q = tensor_args
        mma_si_consumer, si_corr_producer, pi_mma_producer = pipeline_args
        inplace_producer, inplace_consumer = inplace_args
        seqlen_k, seqlen_q, scale_softmax_log2 = value_args
        window_size_left, window_size_right = mask_args
        tile_sched, work_tile = sched_args

        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (self.threads_per_warp * len(self.softmax0_warp_ids))

        cS_base = cute.make_identity_tensor(
            (self.qk_mma_tiler[0], self.qk_mma_tiler[1])
        )
        tScS = qk_thr_mma.partition_C(cS_base)

        # row_max / row_sum vec buffer
        tStS_vec_layout = cute.composition(tStS.layout, cute.make_layout((128, 2)))
        tmem_vec_offset = self.tmem_vec0_offset + stage * (
            self.tmem_vec1_offset - self.tmem_vec0_offset
        )
        tStS_vec = cute.make_tensor(tStS.iterator + tmem_vec_offset, tStS_vec_layout)
        tScS_vec_layout = cute.composition(tScS.layout, cute.make_layout((128, 2)))
        tScS_vec = cute.make_tensor(tScS.iterator, tScS_vec_layout)

        tilePlikeFP32 = self.qk_mma_tiler[1] // 2 // Float32.width * self.q_dtype.width
        tStS_P_layout = cute.composition(
            tStS.layout, cute.make_layout((128, tilePlikeFP32))
        )
        tmem_p_offset = self.tmem_p0_offset + stage * (
            self.tmem_p1_offset - self.tmem_p0_offset
        )
        tStS_P = cute.make_tensor(tStS.iterator + tmem_p_offset, tStS_P_layout)

        tmem_meta_offset = self.tmem_meta0_offset + stage * (
            self.tmem_meta1_offset - self.tmem_meta0_offset
        )
        meta_total_bytes = (self.qk_mma_tiler[1] // 8) * cutlass.Uint8.width // 8
        meta_half_cols_fp32 = meta_total_bytes // 2 // (Float32.width // 8)
        tStS_Meta_layout_half = cute.composition(
            tStS.layout, cute.make_layout((128, meta_half_cols_fp32))
        )
        tCtE = cute.make_tensor(
            cute.recast_ptr(
                tStS.iterator + tmem_meta_offset,
                dtype=self.e_sparse_dtype,
            ),
            e_tmem_layout,
        )
        tStS_Meta_e0 = cute.make_tensor(
            cute.recast_ptr(tCtE[(None, None, 0)].iterator, dtype=self.qk_acc_dtype),
            tStS_Meta_layout_half,
        )
        tStS_Meta_e1 = cute.make_tensor(
            cute.recast_ptr(tCtE[(None, None, 1)].iterator, dtype=self.qk_acc_dtype),
            tStS_Meta_layout_half,
        )

        tmem_sp_repeat = tcgen05.Repetition.x128
        sp_atom = cute.make_copy_atom(
            tcgen05.LdRedSPCompress32x32bOp(
                repeat=tmem_sp_repeat,
                redOp=tcgen05.TmemLoadRedOp.MAX,
            ),
            self.qk_acc_dtype,
        )
        sp_tiled_copy = tcgen05.make_tmem_copy(sp_atom, tStSi)
        sp_thr_copy = sp_tiled_copy.get_slice(thread_idx)
        tSP_src = sp_thr_copy.partition_S(tStSi)

        tmem_store_vec_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(2)),
            self.qk_acc_dtype,
        )
        tiled_tmem_store_vec = tcgen05.make_tmem_copy(tmem_store_vec_atom, tStS_vec)
        thr_tmem_store_vec = tiled_tmem_store_vec.get_slice(thread_idx)
        tTMEM_STORE_VECtS = thr_tmem_store_vec.partition_D(tStS_vec)
        tTMEM_STORE_VECcS = thr_tmem_store_vec.partition_S(tScS_vec)

        tmem_store_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(tilePlikeFP32)),
            self.qk_acc_dtype,
        )
        tiled_tmem_store = tcgen05.make_tmem_copy(tmem_store_atom, tStS_P)
        thr_tmem_store = tiled_tmem_store.get_slice(thread_idx)
        tTMEM_STOREtS_x4 = thr_tmem_store.partition_D(tStS_P)
        tScS_P_layout = cute.composition(
            tScS.layout, cute.make_layout((128, tilePlikeFP32))
        )
        tScS_P = cute.make_tensor(tScS.iterator, tScS_P_layout)
        tTMEM_STOREcS_P = thr_tmem_store.partition_S(tScS_P)

        meta_tmem_st_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(meta_half_cols_fp32)),
            self.qk_acc_dtype,
        )
        tiled_tmem_store_meta_e0 = tcgen05.make_tmem_copy(
            meta_tmem_st_atom, tStS_Meta_e0
        )
        thr_tmem_store_meta_e0 = tiled_tmem_store_meta_e0.get_slice(thread_idx)
        tTMEM_STOREtMeta_e0 = thr_tmem_store_meta_e0.partition_D(tStS_Meta_e0)
        tiled_tmem_store_meta_e1 = tcgen05.make_tmem_copy(
            meta_tmem_st_atom, tStS_Meta_e1
        )
        thr_tmem_store_meta_e1 = tiled_tmem_store_meta_e1.get_slice(thread_idx)
        tTMEM_STOREtMeta_e1 = thr_tmem_store_meta_e1.partition_D(tStS_Meta_e1)
        tScS_Meta_layout_half = cute.composition(
            tScS.layout, cute.make_layout((128, meta_half_cols_fp32))
        )
        tScS_Meta = cute.make_tensor(tScS.iterator, tScS_Meta_layout_half)
        tTMEM_STOREcS_Meta = thr_tmem_store_meta_e0.partition_S(tScS_Meta)

        tilePlikeFP32_dense = self.qk_mma_tiler[1] // Float32.width * self.q_dtype.width
        tStS_P_dense_layout = cute.composition(
            tStS.layout, cute.make_layout((128, tilePlikeFP32_dense))
        )
        tStS_P_dense = cute.make_tensor(
            tStS.iterator + tmem_p_offset, tStS_P_dense_layout
        )
        tmem_dense_load_atom = cute.make_copy_atom(
            tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(32)),
            self.qk_acc_dtype,
        )
        tiled_tmem_dense_load = tcgen05.make_tmem_copy(tmem_dense_load_atom, tStSi)
        thr_tmem_dense_load = tiled_tmem_dense_load.get_slice(thread_idx)
        tTMEM_DENSE_LOADtS = thr_tmem_dense_load.partition_S(tStSi)
        tmem_dense_store_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(tilePlikeFP32_dense)),
            self.qk_acc_dtype,
        )
        tiled_tmem_dense_store = tcgen05.make_tmem_copy(
            tmem_dense_store_atom, tStS_P_dense
        )
        thr_tmem_dense_store = tiled_tmem_dense_store.get_slice(thread_idx)
        tTMEM_DENSE_STOREtS = thr_tmem_dense_store.partition_D(tStS_P_dense)

        if cutlass.const_expr(self.enable_sequence_barrier):
            if stage == 1:
                self._sequence_barrier(0).arrive()
        while work_tile.is_valid_tile:
            curr_block_coord = work_tile.tile_idx
            batch_coord = curr_block_coord[2][1]
            seqlen_k_ = seqlen_k
            seqlen_q_ = seqlen_q
            continue_cond = False
            cuseqlen_q = Int32(0)
            seqlen_q_ = seqlen_q
            if cutlass.const_expr(cum_seqlen_q is not None):
                cuseqlen_q = cum_seqlen_q[batch_coord]
                seqlen_q_ = cum_seqlen_q[batch_coord + 1] - cuseqlen_q
                continue_cond = not fmha_utils.FmhaStaticTileScheduler.check_valid_work_for_seqlen_q(
                    self.cta_tiler[0],
                    curr_block_coord[0],
                    seqlen_q_,
                )
            if not continue_cond:
                if cutlass.const_expr(cum_seqlen_k is not None):
                    cuseqlen_k = cum_seqlen_k[batch_coord]
                    seqlen_k_ = cum_seqlen_k[batch_coord + 1] - cuseqlen_k
                continue_cond = seqlen_k_ <= 0
            if not continue_cond:
                value_args_ = (
                    seqlen_k_,
                    seqlen_q_,
                    scale_softmax_log2,
                    window_size_left,
                    window_size_right,
                )
                atom_args = (
                    qk_thr_mma,
                    sp_tiled_copy,
                    tiled_tmem_store,
                    tiled_tmem_store_vec,
                    tiled_tmem_store_meta_e0,
                    tiled_tmem_store_meta_e1,
                    thr_tmem_store_vec,
                    tiled_tmem_dense_load,
                    tiled_tmem_dense_store,
                    thr_tmem_dense_load,
                    thr_tmem_dense_store,
                )
                tensor_args_ = (
                    tSP_src,
                    tTMEM_DENSE_LOADtS,
                    tTMEM_DENSE_STOREtS,
                    tTMEM_STORE_VECtS,
                    tTMEM_STOREtS_x4,
                    tTMEM_STOREtMeta_e0,
                    tTMEM_STOREtMeta_e1,
                    tTMEM_STOREcS_P,
                    tTMEM_STOREcS_Meta,
                )
                logical_offset = (
                    curr_block_coord[0] * self.cta_tiler[0]
                    + stage * self.qk_mma_tiler[0],
                    0,
                )
                cS = cute.domain_offset(logical_offset, cS_base)
                st_cnt, end_cnt, ld_mask_cnt, unmask_cnt, tl_mask_cnt = (
                    fmha_utils.FusedMask.get_masked_info(
                        self.mask_type,
                        curr_block_coord,
                        self.cta_tiler,
                        seqlen_q_,
                        seqlen_k_,
                        window_size_left,
                        window_size_right,
                    )
                )
                row_max = -Float32.inf
                row_sum = 0.0
                stats_args = (row_sum, row_max)

                def softmax_loop(
                    whether_apply_mask: bool,
                    loop_args: Tuple,
                    stats_args: Tuple,
                    pipeline_args: Tuple,
                    inner_fn: Callable,
                    value_args: Tuple,
                    atom_args: Tuple,
                    tensor_args: Tuple,
                    cS: cute.Tensor,
                ) -> Tuple[Tuple, Tuple]:
                    start_index, iter_num, upper_bound = loop_args
                    for i in cutlass.range(
                        start_index, start_index + iter_num, 1, unroll=1
                    ):
                        cS_iter = cute.domain_offset((0, i * self.qk_mma_tiler[1]), cS)
                        iter_args = (cS_iter, i == upper_bound - 1)
                        stats_args, pipeline_args = inner_fn(
                            stage,
                            whether_apply_mask,
                            iter_args,
                            stats_args,
                            pipeline_args,
                            value_args,
                            atom_args,
                            tensor_args,
                        )
                    return stats_args, pipeline_args

                softmax_step_fn = self.softmax_step
                softmax_loop_fn = partial(
                    softmax_loop,
                    inner_fn=softmax_step_fn,
                    value_args=value_args_,
                    atom_args=atom_args,
                    tensor_args=tensor_args_,
                    cS=cS,
                )
                si_peek_status = mma_si_consumer.try_wait()
                if stage == 1:
                    inplace_consumer.wait_and_advance()
                pipeline_args_ = (
                    si_peek_status,
                    mma_si_consumer,
                    si_corr_producer,
                    pi_mma_producer,
                    inplace_producer,
                    inplace_consumer,
                )
                # 1. Leading mask loop
                loop_args = (st_cnt, ld_mask_cnt, end_cnt)
                stats_args, pipeline_args_ = softmax_loop_fn(
                    True, loop_args, stats_args, pipeline_args_
                )
                # 2. Unmasked loop
                loop_args = (st_cnt + ld_mask_cnt, unmask_cnt, end_cnt)
                stats_args, pipeline_args_ = softmax_loop_fn(
                    False, loop_args, stats_args, pipeline_args_
                )
                # 3. Trailing mask loop
                loop_args = (st_cnt + ld_mask_cnt + unmask_cnt, tl_mask_cnt, end_cnt)
                stats_args, pipeline_args_ = softmax_loop_fn(
                    True, loop_args, stats_args, pipeline_args_
                )

                # Unpack pipeline_args
                (
                    _,
                    mma_si_consumer,
                    si_corr_producer,
                    pi_mma_producer,
                    inplace_producer,
                    inplace_consumer,
                ) = pipeline_args_
                if stage == 0:
                    inplace_producer.commit()
                    inplace_producer.advance()
                # 4. Copy the final stats for correction epilog
                tTMEM_STORE_VECrS = cute.make_rmem_tensor(
                    tTMEM_STORE_VECcS.shape, self.qk_acc_dtype
                )
                tTMEM_STORE_VECrS[0] = stats_args[0]
                tTMEM_STORE_VECrS[1] = stats_args[1]
                vec_i_handle = si_corr_producer.acquire_and_advance()
                cute.copy(tiled_tmem_store_vec, tTMEM_STORE_VECrS, tTMEM_STORE_VECtS)
                cute.arch.fence_view_async_tmem_store()
                vec_i_handle.commit()
            # End of if not continue_cond
            # Advance to next tile
            tile_sched.advance_to_next_work()
            work_tile = tile_sched.get_current_work()
        # End of persistent scheduler loop

    def check_supported_dtypes(
        self,
        qk_dtype: Type[cutlass.Numeric],
        pv_dtype: Type[cutlass.Numeric],
        out_dtype: Type[cutlass.Numeric],
        qk_acc_dtype: Type[cutlass.Numeric],
        pv_acc_dtype: Type[cutlass.Numeric],
    ):
        super().check_supported_dtypes(
            qk_dtype, pv_dtype, out_dtype, qk_acc_dtype, pv_acc_dtype
        )
        if qk_dtype is not cutlass.Float8E4M3FN:
            raise testing.CantImplementError(
                "Sparse FMHA currently supports Float8E4M3FN Q/K only"
            )
        if pv_dtype is not cutlass.Float8E4M3FN:
            raise testing.CantImplementError(
                "Sparse FMHA currently supports Float8E4M3FN V only"
            )
        if out_dtype not in {
            cutlass.Float8E4M3FN,
            cutlass.Float16,
            cutlass.BFloat16,
        }:
            raise testing.CantImplementError(
                "Sparse FMHA output must be Float8E4M3FN / Float16 / BFloat16"
            )
        if self.enable_fp16_mixed_softmax:
            if qk_acc_dtype is not cutlass.Float32:
                raise testing.CantImplementError(
                    "enable_fp16_mixed_softmax requires qk_acc_dtype=Float32"
                )
            if pv_acc_dtype is not cutlass.Float32:
                raise testing.CantImplementError(
                    "enable_fp16_mixed_softmax requires pv_acc_dtype=Float32"
                )

    def check_invalid_shape(
        self,
        qk_dtype: Type[cutlass.Numeric],
        q_shape: Union[
            Tuple[int, int, int, int], Tuple[int, Tuple[int, ...], int, int]
        ],
        k_shape: Union[
            Tuple[int, int, int, int], Tuple[int, Tuple[int, ...], int, int]
        ],
    ):
        # Inherit the shared shape checks (batch, head dim, GQA divisibility,
        # variable-seqlen length matching, d=192 dtype gate) from the base and
        # only add the sparse-specific MMA tiler constraint here.
        super().check_invalid_shape(qk_dtype, q_shape, k_shape)
        if self.qk_mma_tiler[:2] != (128, 128):
            raise testing.CantImplementError(
                "Sparse FMHA requires mma_tiler_mn 128,128"
            )


def run(
    q_shape: Union[Tuple[int, int, int, int], Tuple[int, Tuple[int, ...], int, int]],
    k_shape: Union[Tuple[int, int, int, int], Tuple[int, Tuple[int, ...], int, int]],
    in_dtype: Type[cutlass.Numeric],
    out_dtype: Type[cutlass.Numeric],
    qk_acc_dtype: Type[cutlass.Numeric],
    pv_acc_dtype: Type[cutlass.Numeric],
    mma_tiler_mn: Tuple[int, int],
    enable_skip_correction: bool,
    is_persistent: bool,
    is_causal: bool,
    bottom_right_align: bool,
    lse_calculation: bool,
    window_size: Tuple[int, int],
    scale_q: float,
    scale_k: float,
    scale_v: float,
    inv_scale_o: float,
    scale_softmax: float,
    tolerance: float,
    warmup_iterations: int,
    iterations: int,
    skip_ref_check: bool,
    use_cold_l2: bool = False,
    enable_fp16_mixed_softmax: bool = False,
):
    """Execute Fused Multi-Head Attention (FMHA) on Rubin SM107 architecture and validate results.

    This function creates random input tensors for query, key, and value, then performs the
    complete FMHA computation pipeline. It supports configurable data types, tiling parameters,
    and various attention masking options. Results can be validated against a PyTorch reference
    implementation or run multiple times for performance measurement.

    The implementation leverages specialized tensor memory operations and efficient math
    operations optimized for Rubin SM107 architecture, including pipelined computation stages
    for maximum throughput.

    :param q_shape: Query tensor shape (B, S_q, H, D) where B=batch size, S_q=query sequence length,
                    H=number of heads, D=head dimension.
                    If S_q is a tuple, it is the variable sequence length.
    :type q_shape: Union[Tuple[int, int, int, int], Tuple[int, Tuple[int, ...], int, int]]
    :param k_shape: Key tensor shape (B, S_k, H_k, D) where B=batch size, S_k=key sequence length,
                    H_k=number of key heads (H must be divisible by H_k), D=head dimension.
                    If S_k is a tuple, it is the variable sequence length.
    :type k_shape: Union[Tuple[int, int, int, int], Tuple[int, Tuple[int, ...], int, int]]
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
    :param enable_skip_correction: Whether to enable skip correction
    :type enable_skip_correction: bool
    :param is_persistent: Whether to use persistent kernel optimization
    :type is_persistent: bool
    :param is_causal: Whether to apply causal masking
    :type is_causal: bool
    :param lse_calculation: Whether to calculate lse
    :type lse_calculation: bool
    :param window_size: Sliding window size (left, right) for attention masking. Controls which positions each query can attend to.
    :type window_size: Tuple[int, int]
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
    :param enable_fp16_mixed_softmax: Whether to use Rubin's mixed-precision softmax
        recipe. BMM accumulators stay in FP32.
    :type enable_fp16_mixed_softmax: bool

    :raises testing.CantImplementError: If the problem shape or dtypes are unsupported
    :raises ValueError: If iteration counts are invalid
    :raises RuntimeError: If GPU is unavailable for computation
    :return: Execution time of the FMHA kernel in microseconds
    :rtype: float
    """

    print("Running Rubin SM107 Sparse FMHA test with:")
    print(f"  q_shape: {q_shape}")
    print(f"  k_shape: {k_shape}")
    print(f"  in_dtype: {in_dtype}")
    print(f"  out_dtype: {out_dtype}")
    print(f"  qk_acc_dtype: {qk_acc_dtype}")
    print(f"  pv_acc_dtype: {pv_acc_dtype}")
    print(f"  mma_tiler_mn: {mma_tiler_mn}")
    print(f"  enable_skip_correction: {enable_skip_correction}")
    print(f"  is_persistent: {is_persistent}")
    print(f"  is_causal: {is_causal}")
    print(f"  bottom_right_align: {bottom_right_align}")
    print(f"  lse_calculation: {lse_calculation}")
    print(f"  window_size: {window_size}")
    print(f"  scale_q: {scale_q}")
    print(f"  scale_k: {scale_k}")
    print(f"  scale_v: {scale_v}")
    print(f"  inv_scale_o: {inv_scale_o}")
    print(f"  scale_softmax: {scale_softmax}")
    print(f"  tolerance: {tolerance}")
    print(f"  warmup_iterations: {warmup_iterations}")
    print(f"  iterations: {iterations}")
    print(f"  skip_ref_check: {skip_ref_check}")
    print(f"  use_cold_l2: {use_cold_l2}")
    print(f"  enable_fp16_mixed_softmax: {enable_fp16_mixed_softmax}")

    # Unpack parameters
    b, s_q, h_q, d = q_shape
    b_, s_k, h_k, d_ = k_shape
    window_size_left, window_size_right = window_size
    if window_size_left == -1:
        window_size_left = None
    if window_size_right == -1:
        window_size_right = None

    if iterations < 1:
        raise ValueError("iterations must be at least 1")
    if len(mma_tiler_mn) != 2:
        raise testing.CantImplementError("mma_tiler_mn must contain exactly 2 values")

    mma_tiler = (*mma_tiler_mn, d)
    mask_type = fmha_utils.MaskEnum.WINDOW_MASK
    if bottom_right_align:
        mask_type = fmha_utils.MaskEnum.WINDOW_MASK_INFERENCE
    if is_causal:
        window_size_right = 0
    elif window_size_left is None and window_size_right is None:
        if isinstance(s_k, tuple):
            for i in range(len(s_k)):
                if s_k[i] % mma_tiler_mn[1] != 0:
                    mask_type = fmha_utils.MaskEnum.RESIDUAL_MASK
        else:
            if s_k % mma_tiler_mn[1] != 0:
                mask_type = fmha_utils.MaskEnum.RESIDUAL_MASK

    fmha = RubinSparseFusedMultiHeadAttentionForward(
        qk_acc_dtype,
        pv_acc_dtype,
        mma_tiler,
        is_persistent,
        mask_type,
        enable_skip_correction,
        enable_fp16_mixed_softmax=enable_fp16_mixed_softmax,
    )
    if not fmha.can_implement(
        q_shape,
        k_shape,
        in_dtype,
        in_dtype,
        out_dtype,
        qk_acc_dtype,
        pv_acc_dtype,
    ):
        raise testing.CantImplementError(
            f"The current config is invalid/unsupported: "
            f"q_shape = {q_shape}, k_shape = {k_shape}, in_dtype = {in_dtype}, "
            f"out_dtype = {out_dtype}, qk_acc_dtype = {qk_acc_dtype}, "
            f"pv_acc_dtype = {pv_acc_dtype}"
        )

    h_r = h_q // h_k
    dv = d if d != 192 else 128

    s_q_list = s_q if isinstance(s_q, tuple) else [s_q] * b
    s_k_list = s_k if isinstance(s_k, tuple) else [s_k] * b

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
    for i in range(b):
        if need_check_seqlen_valid and not check_seqlen_valid(
            s_q_list[i],
            s_k_list[i],
            window_size_left,
            window_size_right,
            bottom_right_align,
        ):
            raise testing.CantImplementError(
                "sliding window doesn't support current setting"
            )

    # Prepare pytorch tensors: Q, K, V (random from 0 to 2) and O (all zero)
    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch.manual_seed(1111)

    def create_cumulative_sequence_lengths(s):
        s_cumsum = [0]
        for i in range(len(s)):
            s_cumsum.append(s_cumsum[-1] + s[i])

        s_cumsum_cute_tensor, s_cumsum_torch_tensor = cutlass_torch.cute_tensor_like(
            torch.tensor(s_cumsum, dtype=torch.int32),
            Int32,
            is_dynamic_layout=True,
            assumed_align=16,
        )

        return s_cumsum_cute_tensor, s_cumsum_torch_tensor

    cum_seqlen_q, cum_seqlen_q_torch = (
        create_cumulative_sequence_lengths(s_q)
        if isinstance(s_q, tuple)
        else (None, None)
    )
    cum_seqlen_k, cum_seqlen_k_torch = (
        create_cumulative_sequence_lengths(s_k)
        if isinstance(s_k, tuple)
        else (None, None)
    )

    def create_and_pad_tensor(
        shape, padding, dtype, s_cumsum=None, is_dynamic_layout=True
    ):
        # (b, s, h, d)
        shape_ = tuple(map(lambda x, y: x + y, shape, padding))
        if s_cumsum is not None:
            if shape_[0] != 1 or padding[0] != 0:
                raise ValueError("Invalid tensor creation for variable sequence length")
            # (s_total + padding, h, d)
            shape_ = shape_[1:]
            padding = padding[1:]

        # Create f32 torch tensor (cpu)
        f32_torch_tensor_full = cutlass_torch.create_and_permute_torch_tensor(
            shape_,
            torch.float32,
            permute_order=None,
            init_type=cutlass_torch.TensorInitType.GAUSSIAN,
            init_config=cutlass_torch.GaussianInitConfig(mean=0, std=1, scale=1),
        )
        storage_dtype = (
            torch.uint8 if utils.is_fp8_dtype(dtype) else cutlass_torch.dtype(dtype)
        )
        torch_tensor_full = f32_torch_tensor_full.to(dtype=storage_dtype, device="cuda")

        # Offset the tensor
        slices = tuple(slice(s, e) for s, e in zip(padding, shape_))
        torch_tensor = torch_tensor_full[slices].detach()
        f32_torch_tensor = f32_torch_tensor_full[slices].detach()
        torch_tensor._keep_alive = torch_tensor_full
        f32_torch_tensor._keep_alive = f32_torch_tensor_full

        cute_tensor = utils.create_cute_tensor_for_fp8(
            torch_tensor,
            dtype,
            leading_dim=cutlass_torch.get_leading_dim(torch_tensor),
            source_f32_tensor=f32_torch_tensor,
            assumed_align=16,
            mark_dynamic_layout=is_dynamic_layout,
        )

        # From ragged to jagged
        if s_cumsum is not None:
            if len(shape) == 4:
                jagged_dim = 1  # for q,k,v,o
            else:
                jagged_dim = 2  # for lse
            torch_tensor = torch.nested.nested_tensor_from_jagged(
                values=torch_tensor, offsets=s_cumsum, jagged_dim=jagged_dim
            )
            f32_torch_tensor = torch.nested.nested_tensor_from_jagged(
                values=f32_torch_tensor, offsets=s_cumsum.cpu(), jagged_dim=jagged_dim
            )

        return (
            f32_torch_tensor,
            cute_tensor,
            torch_tensor,
        )

    q_shape = (b, s_q, h_r * h_k, d)
    o_shape = (b, s_q, h_r * h_k, dv)
    k_shape = (b, s_k, h_k, d)
    v_shape = (b, s_k, h_k, dv)
    lse_shape = (b, s_q, h_k, h_r)
    qo_padding = (0, 0, 0, 0, 0)
    kv_padding = (0, 0, 0, 0, 0)
    lse_padding = (0, 0, 0, 0)

    if isinstance(s_q, tuple):
        q_shape = (1, sum(s_q), h_r * h_k, d)
        o_shape = (1, sum(s_q), h_r * h_k, dv)
        lse_shape = (1, sum(s_q), h_k, h_r)

    if isinstance(s_k, tuple):
        k_shape = (1, sum(s_k), h_k, d)
        v_shape = (1, sum(s_k), h_k, dv)

    q_ref, q_tensor, q_torch = create_and_pad_tensor(
        q_shape,
        qo_padding,
        in_dtype,
        s_cumsum=cum_seqlen_q_torch,
    )
    k_ref, k_tensor, k_torch = create_and_pad_tensor(
        k_shape,
        kv_padding,
        in_dtype,
        s_cumsum=cum_seqlen_k_torch,
    )
    v_ref, v_tensor, v_torch = create_and_pad_tensor(
        v_shape,
        kv_padding,
        in_dtype,
        s_cumsum=cum_seqlen_k_torch,
    )
    _, o_tensor, o_torch = create_and_pad_tensor(
        o_shape,
        qo_padding,
        out_dtype,
        s_cumsum=cum_seqlen_q_torch,
    )
    if lse_calculation:
        _, lse_tensor, lse_torch = create_and_pad_tensor(
            lse_shape,
            lse_padding,
            cutlass.Float32,
        )
    else:
        lse_tensor = None
        lse_torch = None

    # Initialize Stream
    current_stream = cutlass_torch.default_stream()

    if scale_softmax == 0.0:  # default to 1/sqrt(d)
        scale_softmax = 1.0 / math.sqrt(d)
    log2_e = math.log2(
        math.exp(1.0)
    )  # gpu uses exp2 for perf concerns, we need an extra factor 'log2_e' here

    scale_softmax = scale_q * scale_k * scale_softmax
    scale_softmax_log2 = scale_softmax * log2_e
    scale_output = scale_v * inv_scale_o

    problem_size = (
        b,
        max(s_q) if isinstance(s_q, tuple) else s_q,
        sum(s_q) if isinstance(s_q, tuple) else s_q,  # s_lse
        sum(s_k) if isinstance(s_k, tuple) else s_k,
        h_q,
        h_k,
        d,
        dv,
    )

    print("Compiling kernel with cute.compile ...")
    start_time = time.time()
    compiled_fmha = cute.compile(
        fmha,
        q_tensor.iterator,
        k_tensor.iterator,
        v_tensor.iterator,
        o_tensor.iterator,
        problem_size,
        cum_seqlen_q,
        cum_seqlen_k,
        lse_tensor.iterator if lse_calculation else None,
        scale_softmax_log2,
        scale_softmax,
        scale_output,
        window_size_left if window_size_left is None else Int32(window_size_left),
        window_size_right if window_size_right is None else Int32(window_size_right),
        current_stream,
    )
    compilation_time = time.time() - start_time
    print(f"Compilation time: {compilation_time:.4f} seconds")

    def sparsify_2_4_max(s):
        """Return MAX-mode 2:4 sparsified values and the selected mask."""
        assert s.shape[-1] % 4 == 0
        grouped = s.reshape(*s.shape[:-1], s.shape[-1] // 4, 4)
        _, topk_indices = grouped.topk(2, dim=-1)
        mask = torch.zeros_like(grouped, dtype=torch.bool)
        mask.scatter_(-1, topk_indices, True)
        keep_mask = mask.reshape_as(s)
        return s * keep_mask, keep_mask

    def _apply_sparse_dual_path(
        s: torch.Tensor,
        position_mask: torch.Tensor,
        cta_tiler_m: int,
        cta_tiler_n: int,
    ) -> torch.Tensor:
        """Apply sparse 2:4 only to CTA/K tiles that need no masking."""
        assert cta_tiler_n % 4 == 0, (
            f"cta_tiler_n={cta_tiler_n} must be divisible by 4 "
            "(TMEM load STAT+SPARSIFY group size)"
        )
        device = s.device
        position_mask = position_mask.to(device)
        h, s_q, s_k = s.shape

        pad_q = (-s_q) % cta_tiler_m
        pad_k = (-s_k) % cta_tiler_n
        if pad_q > 0 or pad_k > 0:
            position_mask_padded = torch.nn.functional.pad(
                position_mask, (0, pad_k, 0, pad_q), value=True
            )
            s_padded = torch.nn.functional.pad(
                s, (0, pad_k, 0, pad_q), value=-torch.inf
            )
        else:
            position_mask_padded = position_mask
            s_padded = s

        n_qb = (s_q + pad_q) // cta_tiler_m
        n_kt = (s_k + pad_k) // cta_tiler_n

        mask_tiled = position_mask_padded.view(n_qb, cta_tiler_m, n_kt, cta_tiler_n)
        fully_unmasked = ~mask_tiled.any(dim=3).any(dim=1)  # (n_qb, n_kt)

        s_blocks = s_padded.view(h, n_qb, cta_tiler_m, n_kt, cta_tiler_n)
        _, keep_mask = sparsify_2_4_max(s_blocks)
        enforce = fully_unmasked.view(1, n_qb, 1, n_kt, 1)
        s_blocks = torch.where(
            enforce & ~keep_mask,
            torch.full_like(s_blocks, -torch.inf),
            s_blocks,
        )
        s_padded = s_blocks.view(h, n_qb * cta_tiler_m, n_kt * cta_tiler_n)
        return s_padded[:, :s_q, :s_k]

    def run_torch_fmha(
        q,
        k,
        v,
        scale_softmax=1.0,
        scale_output=1.0,
        is_causal=False,
        bottom_right_align=False,
        lse_calculation=False,
        window_size_left=None,
        window_size_right=None,
        cta_tiler_m=128,
        cta_tiler_n=128,
    ):
        def quantize_e4m3_to_f32(tensor):
            """Mirror the kernel's FP8 input tensors in the reference path."""
            if tensor.is_nested:
                values = tensor.values().to(torch.float8_e4m3fn).to(torch.float32)
                return torch.nested.nested_tensor_from_jagged(
                    values=values, offsets=tensor.offsets()
                )
            return tensor.to(torch.float8_e4m3fn).to(torch.float32)

        q = quantize_e4m3_to_f32(q)
        k = quantize_e4m3_to_f32(k)
        v = quantize_e4m3_to_f32(v)

        h_q = q.shape[2]
        h_k = k.shape[2]
        h_r = h_q // h_k

        if not h_q == h_k:
            repeat_factor = h_q // h_k
            if k.is_nested:
                k_offsets = k.offsets()
                v_offsets = v.offsets()
                k_values = k.values().repeat_interleave(repeat_factor, dim=1)
                v_values = v.values().repeat_interleave(repeat_factor, dim=1)

                k = torch.nested.nested_tensor_from_jagged(
                    values=k_values, offsets=k_offsets
                )
                v = torch.nested.nested_tensor_from_jagged(
                    values=v_values, offsets=v_offsets
                )
            else:
                k = k.repeat_interleave(repeat_factor, dim=2)
                v = v.repeat_interleave(repeat_factor, dim=2)

        q = q.transpose(1, 2)
        k = k.transpose(1, 2)
        v = v.transpose(1, 2)

        batch_size = q.size(0)
        ref_list = []
        lse_list = []
        for batch_idx in range(batch_size):
            q_i = q[batch_idx]
            k_i = k[batch_idx]
            v_i = v[batch_idx]
            s_i = torch.einsum("hqd,hkd->hqk", q_i, k_i) * scale_softmax
            s_q = q_i.shape[1]
            s_k = k_i.shape[1]

            if is_causal:
                window_size_right = 0
            if window_size_left is not None or window_size_right is not None:
                q_coords = torch.arange(0, s_q).cuda().view(-1, 1)
                k_coords = torch.arange(0, s_k).cuda().view(1, -1)
                offset = 0 if not bottom_right_align else s_k - s_q
                if window_size_left is None:
                    position_mask = k_coords > q_coords + offset + window_size_right
                elif window_size_right is None:
                    position_mask = k_coords < q_coords + offset - window_size_left
                else:
                    position_mask = (
                        k_coords > q_coords + offset + window_size_right
                    ) | (k_coords < q_coords + offset - window_size_left)
                position_mask = position_mask.to(s_i.device)
            else:
                position_mask = torch.zeros(
                    s_q, s_k, dtype=torch.bool, device=s_i.device
                )

            s_i = s_i.masked_fill(position_mask, -torch.inf)

            s_i = _apply_sparse_dual_path(s_i, position_mask, cta_tiler_m, cta_tiler_n)

            if lse_calculation:
                # The inherited Blackwell epilogue stores LSE in log2 space.
                lse_i = torch.logsumexp(s_i, dim=-1) * log2_e
            else:
                lse_i = None

            row_max = s_i.max(dim=-1, keepdim=True).values
            p_i = torch.exp(s_i - row_max)
            p_i = torch.nan_to_num(p_i, nan=0.0)
            row_sum = p_i.sum(dim=-1, keepdim=True)
            p_i = p_i.to(torch.float8_e4m3fn).to(torch.float32)
            ref_i = torch.einsum("hqk,hkd->hqd", p_i, v_i) / row_sum
            ref_i = ref_i.transpose(0, 1) * scale_output
            ref_list.append(ref_i)
            if lse_calculation:
                lse_list.append(lse_i)
        if q.is_nested:
            ref = torch.nested.nested_tensor(ref_list, layout=torch.jagged)
            if lse_calculation:
                lse = (
                    torch.cat(lse_list, dim=1).transpose(0, 1).reshape(1, -1, h_k, h_r)
                )
            else:
                lse = None
        else:
            ref = torch.stack(ref_list)
            if lse_calculation:
                lse = torch.stack(
                    [
                        lse_i.transpose(0, 1).reshape(lse_i.shape[1], h_k, h_r)
                        for lse_i in lse_list
                    ]
                )
            else:
                lse = None

        return ref, lse

    compiled_fmha(
        q_tensor.iterator,
        k_tensor.iterator,
        v_tensor.iterator,
        o_tensor.iterator,
        problem_size,
        cum_seqlen_q,
        cum_seqlen_k,
        lse_tensor.iterator if lse_calculation else None,
        scale_softmax_log2,
        scale_softmax,
        scale_output,
        window_size_left if window_size_left is None else Int32(window_size_left),
        window_size_right if window_size_right is None else Int32(window_size_right),
        current_stream,
    )
    if not skip_ref_check:
        print("Verifying results...")
        o_ref, lse_ref = run_torch_fmha(
            q_ref,
            k_ref,
            v_ref,
            scale_softmax,
            scale_output,
            is_causal,
            bottom_right_align,
            lse_calculation,
            window_size_left,
            window_size_right,
            cta_tiler_m=2 * mma_tiler_mn[0],
            cta_tiler_n=mma_tiler_mn[1],
        )

        if o_ref.is_nested:
            o_ref = o_ref.values()

        if o_torch.is_nested:
            o_torch = o_torch.values()

        # convert o back to f32 for comparison
        o_fp32, o_fp32_torch = cutlass_torch.cute_tensor_like(
            torch.empty(*o_torch.shape, dtype=torch.float32),
            Float32,
            is_dynamic_layout=True,
            assumed_align=16,
        )
        cute.testing.convert(o_tensor, o_fp32)
        o_result = o_fp32_torch.cpu()

        if out_dtype.is_float and out_dtype.width <= 8:
            ref_narrow_precision, _ = cutlass_torch.cute_tensor_like(
                torch.empty(*o_ref.shape, dtype=torch.uint8),
                out_dtype,
                is_dynamic_layout=True,
                assumed_align=16,
            )

            ref_o_f32, ref_o_f32_torch = cutlass_torch.cute_tensor_like(
                o_ref,
                cutlass.Float32,
                is_dynamic_layout=True,
                assumed_align=16,
            )

            # convert ref : f32 -> fp4/fp8 -> f32
            cute.testing.convert(ref_o_f32, ref_narrow_precision)
            cute.testing.convert(ref_narrow_precision, ref_o_f32)

            o_ref = ref_o_f32_torch.cpu()

            # override tolerance
            tolerance = 0.25

        # Assert close results
        torch.testing.assert_close(o_result, o_ref, atol=tolerance, rtol=1e-05)
        if lse_calculation:
            torch.testing.assert_close(
                lse_torch.cpu(), lse_ref, atol=tolerance, rtol=1e-05
            )
        print("Results verified successfully!")

    def generate_tensors():
        _, q_tensor_workspace, _ = create_and_pad_tensor(
            q_shape,
            qo_padding,
            in_dtype,
            s_cumsum=cum_seqlen_q_torch,
        )
        _, k_tensor_workspace, _ = create_and_pad_tensor(
            k_shape,
            kv_padding,
            in_dtype,
            s_cumsum=cum_seqlen_k_torch,
        )
        _, v_tensor_workspace, _ = create_and_pad_tensor(
            v_shape,
            kv_padding,
            in_dtype,
            s_cumsum=cum_seqlen_k_torch,
        )
        _, o_tensor_workspace, _ = create_and_pad_tensor(
            o_shape,
            qo_padding,
            out_dtype,
            s_cumsum=cum_seqlen_q_torch,
        )
        if lse_calculation:
            _, lse_tensor, lse_torch = create_and_pad_tensor(
                lse_shape,
                lse_padding,
                cutlass.Float32,
            )
        else:
            lse_tensor = None

        args = testing.JitArguments(
            q_tensor_workspace.iterator,
            k_tensor_workspace.iterator,
            v_tensor_workspace.iterator,
            o_tensor_workspace.iterator,
            problem_size,
            cum_seqlen_q,
            cum_seqlen_k,
            lse_tensor,
            scale_softmax_log2,
            scale_softmax,
            scale_output,
            window_size_left if window_size_left is None else Int32(window_size_left),
            (
                window_size_right
                if window_size_right is None
                else Int32(window_size_right)
            ),
            current_stream,
        )
        args.add_to_scope(
            [
                q_tensor_workspace,
                k_tensor_workspace,
                v_tensor_workspace,
                o_tensor_workspace,
            ]
        )
        return args

    workspace_count = 1
    if use_cold_l2:
        q_torch_effective = q_torch.values() if q_torch.is_nested else q_torch
        k_torch_effective = k_torch.values() if k_torch.is_nested else k_torch
        v_torch_effective = v_torch.values() if v_torch.is_nested else v_torch
        o_torch_effective = o_torch.values() if o_torch.is_nested else o_torch
        one_workspace_bytes = (
            q_torch_effective.numel() * q_torch_effective.element_size()
            + k_torch_effective.numel() * k_torch_effective.element_size()
            + v_torch_effective.numel() * v_torch_effective.element_size()
            + o_torch_effective.numel() * o_torch_effective.element_size()
            + (
                lse_torch.numel() * lse_torch.element_size()
                if lse_torch is not None
                else 0
            )
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
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    def parse_nested_comma_separated_ints(s: str):
        try:
            s = s.strip()
            if "(" not in s:
                return tuple(int(x.strip()) for x in s.split(","))

            start = s.find("(")
            end = s.find(")")
            if start == -1 or end == -1:
                raise ValueError("Mismatched parentheses")

            before = s[:start].strip().rstrip(",")
            middle = s[start + 1 : end].strip()
            after = s[end + 1 :].strip().lstrip(",")

            result = []
            if before:
                result.extend(int(x.strip()) for x in before.split(","))

            if middle:
                nested_tuple = tuple(int(x.strip()) for x in middle.split(","))
                result.append(nested_tuple)

            if after:
                result.extend(int(x.strip()) for x in after.split(","))

            return tuple(result)

        except ValueError as e:
            if str(e) == "Mismatched parentheses":
                raise argparse.ArgumentTypeError("Mismatched parentheses in input")
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers with optional parentheses for nested tuple."
            )

    parser = argparse.ArgumentParser(description="Example of Sparse FMHA on Rubin.")

    parser.add_argument(
        "--in_dtype",
        type=cutlass.dtype,
        default=cutlass.Float8E4M3FN,
        help="Input data type for Q, K, and V",
    )

    parser.add_argument(
        "--out_dtype",
        type=cutlass.dtype,
        default=cutlass.Float8E4M3FN,
        help="Output data type",
    )

    parser.add_argument(
        "--qk_acc_dtype",
        type=cutlass.dtype,
        default=Float32,
        help="QK accumulator data type",
    )

    parser.add_argument(
        "--pv_acc_dtype",
        type=cutlass.dtype,
        default=Float32,
        help="PV accumulator data type",
    )

    parser.add_argument(
        "--mma_tiler_mn",
        type=parse_comma_separated_ints,
        default=(128, 128),
        help="MMA tile shape (M, N)",
    )

    parser.add_argument(
        "--enable_skip_correction",
        action="store_true",
        default=False,
        help="Enable skip correction",
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
        "--bottom_right_align",
        action="store_true",
        help="Whether to use bottom right align (end of q is aligned with end of k).",
    )

    parser.add_argument(
        "--lse_calculation",
        action="store_true",
        help="Whether to calculate lse",
    )

    parser.add_argument(
        "--window_size",
        type=parse_comma_separated_ints,
        default=(-1, -1),
        help="Sliding window size (left, right) for attention masking.",
    )

    parser.add_argument(
        "--q_shape",
        type=parse_nested_comma_separated_ints,
        default=(4, 1024, 8, 192),
        help="Shape of Q (B, S_q, H, D)",
    )

    parser.add_argument(
        "--k_shape",
        type=parse_nested_comma_separated_ints,
        default=(4, 1024, 1, 192),
        help="Shape of K (B, S_k, H_k, D)",
    )

    parser.add_argument(
        "--scale_q",
        type=float,
        default=1.0,
        help="Scaling factor to dequantize Q",
    )

    parser.add_argument(
        "--scale_k",
        type=float,
        default=1.0,
        help="Scaling factor to dequantize K",
    )

    parser.add_argument(
        "--scale_v",
        type=float,
        default=1.0,
        help="Scaling factor to dequantize V",
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
        default=0.0,
        help="Scaling factor to scale S (i.e. Q*K); if zero, defaults to 1/sqrt(D)",
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
    parser.add_argument(
        "--enable_fp16_mixed_softmax",
        action="store_true",
        default=False,
        help="Use Rubin's mixed-precision softmax recipe.",
    )
    args = parser.parse_args()

    if len(args.q_shape) != 4:
        parser.error("--q_shape must contain exactly 4 values")

    if len(args.k_shape) != 4:
        parser.error("--k_shape must contain exactly 4 values")

    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values")

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    run(
        args.q_shape,
        args.k_shape,
        args.in_dtype,
        args.out_dtype,
        args.qk_acc_dtype,
        args.pv_acc_dtype,
        args.mma_tiler_mn,
        args.enable_skip_correction,
        args.is_persistent,
        args.is_causal,
        args.bottom_right_align,
        args.lse_calculation,
        args.window_size,
        args.scale_q,
        args.scale_k,
        args.scale_v,
        args.inv_scale_o,
        args.scale_softmax,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
        args.enable_fp16_mixed_softmax,
    )

    print("PASS")
