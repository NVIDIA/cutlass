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
import itertools
from typing import Callable, Type, Tuple, Union, Optional
from functools import partial

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import tcgen05
from cutlass.cute.nvgpu.tcgen05 import OperandMajorMode
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import cutlass.torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.cute.testing as testing
from cutlass.cute.runtime import from_dlpack
from cutlass.cute.typing import Int8, Int32, Int64, Float32
from cutlass.base_dsl.arch import Arch
from cutlass.cutlass_dsl import BaseDSL

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../../../"))

from helpers import fmha_helpers as fmha_utils

"""
A fused multi-head attention (FMHA) example for the NVIDIA Blackwell SM100 architecture using CUTE DSL

This example demonstrates an implementation of fused multi-head attention using a TMA + Blackwell SM100
TensorCore warp-specialized persistent kernel. The implementation integrates the Q*K^T matrix multiplication,
softmax normalization, and softmax(Q*K^T)*V into a single kernel, avoiding intermediate data movement between
global memory and shared memory, thus improving computational efficiency.

The kernel implements key optimizations including:
- Warp specialization for different computation phases (load, MMA, softmax, correction, epilogue)
- Pipeline stages between different warps for overlapping computation and memory access
- Support for different precision data types
- Optional causal masking for autoregressive models

To run this example:

.. code-block:: bash

    python examples/python/CuTeDSL/cute/blackwell/kernel/attention/fmha/fmha.py \
      --qk_acc_dtype Float32 --pv_acc_dtype Float32                             \
      --mma_tiler_mn 128,128                                                    \
      --q_shape 4,1024,8,64 --k_shape 4,1024,8,64                               \
      --is_persistent

The above example runs FMHA with batch size 4, sequence length 1024, 8 attention heads, and head
dimension 64. The Blackwell tcgen05 MMA tile shape is (128, 128), and the kernel uses fp16 for input/output
with fp32 for accumulation.

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/python/CuTeDSL/cute/blackwell/kernel/attention/fmha/fmha.py  \
      --qk_acc_dtype Float32 --pv_acc_dtype Float32                                  \
      --mma_tiler_mn 128,128                                                         \
      --q_shape 4,1024,8,64 --k_shape 4,1024,8,64                                    \
      --is_persistent --warmup_iterations 10                                         \
      --iterations 10 --skip_ref_check

Constraints for this example:
* Supported head dimensions: 32, 64, and 128
* Number of heads in Q must be divisible by number of heads in K
* mma_tiler_mn must be 128,128
* Batch size must be the same for Q, K, and V tensors
* For causal masking, use --is_causal (note: specify without =True/False)
* For persistent scheduling, use --is_persistent (note: specify without =True/False)

For details on the skip softmax algorithm, please refer to the paper: https://arxiv.org/abs/2512.12087.
"""


def make_thread_cooperative_group(size: int):
    return pipeline.CooperativeGroup(pipeline.Agent.Thread, size)


class BlackwellFusedMultiHeadAttentionForward:
    arch_str: str = "sm_100"
    arch_name: str = "Blackwell SM100"

    def __init__(
        self,
        qk_acc_dtype: Type[cutlass.Numeric],
        pv_acc_dtype: Type[cutlass.Numeric],
        mma_tiler: Tuple[int, int],
        head_dim: Union[int, Tuple[int, int]],
        is_persistent: bool,
        mask_type: fmha_utils.MaskEnum,
        enable_ex2_emulation: bool,
        enable_skip_correction: bool,
        use_tma_store: bool = True,
    ):
        """Initializes the configuration for a Blackwell Fused Multi-Head Attention (FMHA) kernel.

        This configuration includes several key aspects:

        1.  Data Type Settings:
            - qk_acc_dtype: Data type for Q*K^T matrix multiplication accumulator
            - pv_acc_dtype: Data type for P*V matrix multiplication accumulator

        2.  MMA Instruction Settings:
            - mma_tiler: The shape of the MMA instruction unit: (M, N) for BMM1 and (M, K) for BMM2
            - head_dim: The head dimension, it can be a single integer or a tuple of two integers (D, Dv).
                        If it is a tuple, Dv is the head dimension of the value & output tensors.
                        It also determines the K dimension of the BMM1's MMA instruction unit
                        & N dimension of the BMM2's MMA instruction unit.
            - qk_mma_tiler: MMA shape for Q*K^T computation
            - pv_mma_tiler: MMA shape for P*V computation

        3.  Kernel Execution Mode:
            - is_persistent: Boolean indicating whether to use persistent kernel mode
            - mask_type: Specifies the type of mask to use (no mask, residual mask, or causal mask)
            - window_size_left/right: Sliding window size for attention masking
            - enable_ex2_emulation: Whether to enable exp2 emulation
            - enable_skip_correction: Whether to skip the correction when rowmax is not updated larger than a threshold

        :param qk_acc_dtype: Data type for Q*K^T matrix multiplication accumulator
        :type qk_acc_dtype: Type[cutlass.Numeric]
        :param pv_acc_dtype: Data type for P*V matrix multiplication accumulator
        :type pv_acc_dtype: Type[cutlass.Numeric]
        :param mma_tiler: The (M, N) shape of the MMA instruction
        :type mma_tiler: Tuple[int, int]
        :param head_dim: The head dimension, it can be a single integer or a tuple of two integers (D, Dv).
        :type head_dim: Union[int, Tuple[int, int]]
        :param is_persistent: Whether to use persistent kernel mode
        :type is_persistent: bool
        :param mask_type: Type of mask to use
        :type mask_type: fmha_utils.MaskEnum
        :param window_size_left: Left-side sliding window size for attention masking
        :type window_size_left: int
        :param window_size_right: Right-side sliding window size for attention masking
        :type window_size_right: int
        """

        self.qk_acc_dtype = qk_acc_dtype
        self.pv_acc_dtype = pv_acc_dtype
        if isinstance(head_dim, tuple):
            self.head_dim = head_dim[0]
            self.head_dim_v = head_dim[1]
            assert self.head_dim == 192 and self.head_dim_v == 128, (
                f"When Headdim is a tuple, it's for MLA. Must be (192, 128), but got {head_dim}"
            )
        else:
            self.head_dim = head_dim
            self.head_dim_v = head_dim
        self.cta_tiler = (
            2 * mma_tiler[0],  # 2 O tile per CTA
            mma_tiler[1],
            self.head_dim_v,
        )
        self.qk_mma_tiler = (
            *mma_tiler,
            self.head_dim,
        )
        self.pv_mma_tiler = (
            mma_tiler[0],
            self.head_dim_v,
            mma_tiler[1],
        )
        self.cluster_shape_mn = (1, 1)
        self.is_persistent = is_persistent
        self.mask_type = mask_type
        self.enable_skip_correction = enable_skip_correction
        self.enable_ex2_emulation = enable_ex2_emulation
        self.use_tma_store = use_tma_store

        self.softmax0_warp_ids = (0, 1, 2, 3)
        self.softmax1_warp_ids = (4, 5, 6, 7)
        self.correction_warp_ids = (8, 9, 10, 11)
        self.mma_warp_id = 12
        self.load_warp_id = 13
        self.epilogue_warp_id = 14
        self.empty_warp_id = 15
        self.num_tmem_alloc_cols = cute.arch.get_max_tmem_alloc_cols(self.arch_str)

        self.threads_per_warp = 32
        self.threads_per_cta = self.threads_per_warp * len(
            (
                *self.softmax0_warp_ids,
                *self.softmax1_warp_ids,
                *self.correction_warp_ids,
                self.mma_warp_id,
                self.load_warp_id,
                self.epilogue_warp_id,
                self.empty_warp_id,
            )
        )
        self.tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=2,
            num_threads=self.threads_per_warp
            * sum(
                (
                    len((self.mma_warp_id,)),
                    len(self.softmax0_warp_ids),
                    len(self.softmax1_warp_ids),
                    len(self.correction_warp_ids),
                )
            ),
        )
        self.sequence_s0_s1_barrier = pipeline.NamedBarrier(
            barrier_id=3,
            num_threads=self.threads_per_warp
            * len((*self.softmax0_warp_ids, *self.softmax1_warp_ids)),
        )
        self.sequence_s1_s0_barrier = pipeline.NamedBarrier(
            barrier_id=4,
            num_threads=self.threads_per_warp
            * len((*self.softmax0_warp_ids, *self.softmax1_warp_ids)),
        )
        self.s0_warpgroup_barrier = pipeline.NamedBarrier(
            barrier_id=5,
            num_threads=self.threads_per_warp * len(self.softmax0_warp_ids),
        )
        self.s1_warpgroup_barrier = pipeline.NamedBarrier(
            barrier_id=6,
            num_threads=self.threads_per_warp * len(self.softmax1_warp_ids),
        )
        self.tmem_dealloc_barrier = pipeline.NamedBarrier(
            barrier_id=7,
            num_threads=self.threads_per_warp * len(self.correction_warp_ids),
        )

        self.tmem_s0_offset = 0
        self.tmem_s1_offset = 128
        self.tmem_o0_offset = 256
        self.tmem_o1_offset = 384
        # inplaced with s1
        self.tmem_p0_offset = 160
        # inplaced with s0
        self.tmem_p1_offset = 32
        # vec buffer for row_max & row_sum
        # inplaced with s0
        self.tmem_vec0_offset = 0
        # inplaced with s1
        self.tmem_vec1_offset = 128
        # skip mma pv flag offset regarding to the vec buffer
        # inplaced with s1
        self.tmem_skip_softmax0_offset = 136
        # inplaced with s0
        self.tmem_skip_softmax1_offset = 8

        self.num_regs_softmax = 192
        self.num_regs_correction = 96
        self.num_regs_other = 32
        self.buffer_align_bytes = 1024
        self.arch = BaseDSL._get_dsl().get_arch_enum()

        if self.arch >= Arch.sm_103:
            assert self.enable_ex2_emulation == False, (
                f"Don't enable exp2 emulation for {self.arch}, it doesn't help performance"
            )

        num_warps_per_warpgroup = 4
        self.softmax_warpgroup_count = (
            len((*self.softmax0_warp_ids, *self.softmax1_warp_ids))
            // num_warps_per_warpgroup
        )

    def _make_qk_tiled_mma(self, cta_group):
        """Build the QK tiled MMA. Override in subclasses to target a different arch."""
        return sm100_utils.make_trivial_tiled_mma(
            self.q_dtype,
            self.q_dtype,
            self.q_major_mode,
            self.k_major_mode,
            self.qk_acc_dtype,
            cta_group,
            self.qk_mma_tiler[:2],
        )

    def _make_pv_tiled_mma(self, cta_group, p_major_mode, p_source):
        """Build the PV tiled MMA. Override in subclasses to target a different arch."""
        return sm100_utils.make_trivial_tiled_mma(
            self.v_dtype,
            self.v_dtype,
            p_major_mode,
            self.v_major_mode,
            self.pv_acc_dtype,
            cta_group,
            self.pv_mma_tiler[:2],
            p_source,
        )

    def _setup_attributes(self):
        """Set up configurations and parameters for the FMHA kernel operation.

        This method initializes and configures various attributes required for the
        execution of the fused multi-head attention kernel, mainly about the pipeline stages:

        - Sets up staging parameters for Q, K, V inputs and accumulator data
        - Configures pipeline stages for softmax, correction, and epilogue operations
        """

        self.q_stage = 2
        k_stage = 4 if self.q_dtype.width == 8 else 3
        v_stage = 4 if self.v_dtype.width == 8 else 3
        self.kv_stage = min(k_stage, v_stage)
        # For D192, the smem usage of Q & K is larger. So, we need to reduce the stage count.
        if self.head_dim == 192 and self.q_dtype.width == 16:
            self.kv_stage = 2
        self.p_mma_stage = 1
        self.acc_stage = 1
        self.softmax_corr_stage = 1
        self.mma_corr_stage = 2
        self.mma_softmax_stage = 1
        self.epi_stage = 2

        # Tunable parameters
        self.rescale_threshold = 8.0 if self.enable_skip_correction else 0.0
        # FP8 P pre-scale: offset added to exp2 exponent so that P*2^offset fills
        # more of E4M3's [0, 448] range, improving quantization precision.
        # Derived from rescale_threshold to guarantee P*2^offset <= 448.
        self.p_fp8_prescale_log2 = max(
            0.0, math.floor(math.log2(448) - self.rescale_threshold)
        )
        # ln(2) * offset correction for LSE when pre-scale is active
        self.p_fp8_prescale_lse_correction = self.p_fp8_prescale_log2 * math.log(2)
        # For most cases, seq barrier is needed to help keep the pipeline stable
        # But sometimes, compiler will schedule the barrier at an unexpected place
        # if it hurts perf a lot, try to quickly fix it by disabling seq barrier
        self.enable_sequence_barrier = False
        # Optional double buffering for correction rescale.
        self.enable_correction_double_buffer = False

    @cute.jit
    def __call__(
        self,
        q_tensor: cute.Tensor,
        k_tensor: cute.Tensor,
        v_tensor: cute.Tensor,
        o_tensor: cute.Tensor,
        problem_size: Tuple[Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32],
        cum_seqlen_q: Optional[cute.Tensor],
        cum_seqlen_k: Optional[cute.Tensor],
        lse_tensor: Optional[cute.Tensor],
        sink_tensor: Optional[cute.Tensor],
        scale_softmax_log2: Float32,
        scale_softmax: Float32,
        scale_output: Float32,
        skip_softmax_threshold_log2: Optional[Float32],
        window_size_left: Optional[Int32],
        window_size_right: Optional[Int32],
        skip_softmax_count: Optional[cute.Tensor],
        total_softmax_count: Optional[cute.Tensor],
        stream: cuda.CUstream,
        use_pdl: bool,
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

        :param q_tensor: The query tensor with shape (b, s_q, h_k, h_r, d)
        :type q_tensor: cute.Tensor
        :param k_tensor: The key tensor with shape (b, s_k, h_k, 1, d)
        :type k_tensor: cute.Tensor
        :param v_tensor: The value tensor with shape (b, s_v, h_k, 1, dv)
        :type v_tensor: cute.Tensor
        :param o_tensor: The output tensor with shape (b, s_q, h_k, h_r, dv)
        :type o_tensor: cute.Tensor
        :param problem_size: The problem size with shape [b, s_q_max, s_lse_max, s_k_max, h_q, h_k, d, dv]. If cum_seqlen_q or cum_seqlen_k is not None, s_q_max and s_k_max are the max of the per-batch sequence lengths respectively.
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
        b, s_q_max, s_lse_max, s_k_max, h_q, h_k, d, dv = problem_size
        h_r = h_q // h_k
        # setup static attributes before smem/grid/tma computation
        self.q_dtype = q_tensor.element_type
        self.k_dtype = k_tensor.element_type
        self.v_dtype = v_tensor.element_type
        self.o_dtype = o_tensor.element_type

        # s_q, s_k, s_v are the actual tensor dimensions (total seqlen for varlen)
        s_q = q_tensor.shape[1]
        s_k = k_tensor.shape[1]
        s_v = v_tensor.shape[1]
        s_lse = s_lse_max
        # Important for performance
        align = 256 // self.o_dtype.width
        d = cute.assume(Int32(d), align)
        dv = cute.assume(Int32(dv), align)

        stride_b_q = h_r * h_k * s_q * d if cum_seqlen_q is None else 0
        stride_b_o = h_r * h_k * s_q * dv if cum_seqlen_q is None else 0
        stride_b_k = h_k * s_k * d if cum_seqlen_k is None else 0
        stride_b_v = h_k * s_v * dv if cum_seqlen_k is None else 0
        stride_b_lse = h_r * h_k * s_lse if cum_seqlen_q is None else 0

        # (b, s_q, h_k, h_r, d) -> (s_q, d, ((h_r, h_k), b))
        q_layout = cute.make_layout(
            (s_q, d, ((h_r, h_k), b)),
            stride=(d * h_r * h_k, 1, ((d, d * h_r), stride_b_q)),
        )
        q = cute.make_tensor(q_tensor.iterator, q_layout)
        # (b, s_k, h_k, 1, d) -> (s_k, d, ((h_r, h_k), b)), 0-stride for h_r to broadcast
        k_layout = cute.make_layout(
            (s_k, d, ((h_r, h_k), b)),
            stride=(d * h_k, 1, ((0, d), stride_b_k)),
        )
        k = cute.make_tensor(k_tensor.iterator, k_layout)
        # (b, s_v, h_k, 1, dv) -> (dv, s_v, ((h_r, h_k), b)), 0-stride for h_r to broadcast
        v_layout = cute.make_layout(
            (dv, s_v, ((h_r, h_k), b)),
            stride=(1, dv * h_k, ((0, dv), stride_b_v)),
        )
        v = cute.make_tensor(v_tensor.iterator, v_layout)
        # (b, s_q, h_k, h_r, dv) -> (s_q, dv, ((h_r, h_k), b))
        o_layout = cute.make_layout(
            (s_q, dv, ((h_r, h_k), b)),
            stride=(dv * h_r * h_k, 1, ((dv, dv * h_r), stride_b_o)),
        )
        o = cute.make_tensor(o_tensor.iterator, o_layout)
        if cutlass.const_expr(lse_tensor is not None):
            # (s, ((h_r, h_k), b)) - head stride=1 to match FlashInfer (total_q, h_q) convention
            lse_layout = cute.make_layout(
                (s_lse, ((h_r, h_k), b)),
                stride=(h_r * h_k, ((1, h_r), stride_b_lse)),
            )
            lse = cute.make_tensor(lse_tensor.iterator, lse_layout)
        else:
            lse = None

        if cutlass.const_expr(sink_tensor is not None):
            # sink_tensor is 1D with shape (h_q,) = (h_k * h_r,)
            # Create layout ((h_r, h_k), b) with stride 0 for batch so blk_coord[2] works
            sink_layout = cute.make_layout(
                ((h_r, h_k), b),
                stride=((1, h_r), 0),
            )
            sink = cute.make_tensor(sink_tensor.iterator, sink_layout)
        else:
            sink = None

        self.tile_sched_params, grid = fmha_utils.compute_grid(
            cute.shape((s_q_max, d, ((h_r, h_k), b))),
            self.cta_tiler,
            self.is_persistent,
        )
        self.q_major_mode = utils.LayoutEnum.from_tensor(q).mma_major_mode()
        self.k_major_mode = utils.LayoutEnum.from_tensor(k).mma_major_mode()
        self.v_major_mode = utils.LayoutEnum.from_tensor(v).mma_major_mode()
        self.o_layout = utils.LayoutEnum.from_tensor(o)

        if cutlass.const_expr(self.q_major_mode != OperandMajorMode.K):
            raise RuntimeError("The layout of q is not supported")
        if cutlass.const_expr(self.k_major_mode != OperandMajorMode.K):
            raise RuntimeError("The layout of k is not supported")
        if cutlass.const_expr(self.v_major_mode != OperandMajorMode.MN):
            raise RuntimeError("The layout of v is not supported")

        # check type consistency: Q and K must share the same dtype (qk_dtype);
        # V may use a different dtype (pv_dtype) to allow qk_dtype != pv_dtype.
        if cutlass.const_expr(self.q_dtype != self.k_dtype):
            raise TypeError(f"Type mismatch: {self.q_dtype} != {self.k_dtype}")
        self._setup_attributes()

        cta_group = tcgen05.CtaGroup.ONE
        # the intermediate tensor p is from tmem & k-major
        p_source = tcgen05.OperandSource.TMEM
        p_major_mode = cute.nvgpu.OperandMajorMode.K
        qk_tiled_mma = self._make_qk_tiled_mma(cta_group)
        pv_tiled_mma = self._make_pv_tiled_mma(cta_group, p_major_mode, p_source)

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
        k_smem_layout_staged = sm100_utils.make_smem_layout_b(
            qk_tiled_mma,
            self.qk_mma_tiler,
            self.k_dtype,
            self.kv_stage,
        )
        p_tmem_layout_staged = sm100_utils.make_smem_layout_a(
            pv_tiled_mma,
            self.pv_mma_tiler,
            self.v_dtype,
            self.acc_stage,
        )
        v_smem_layout_staged_origin = sm100_utils.make_smem_layout_b(
            pv_tiled_mma,
            self.pv_mma_tiler,
            self.v_dtype,
            self.kv_stage,
        )
        # k & v share the same smem buffer. Pad the smaller-tile operand's stage stride to
        # match the larger tile. Stride is scaled to the target operand's element width.
        # sK_cosize covers all kv_stage slots at the larger tile's byte footprint.
        if cutlass.const_expr(self.k_dtype.width >= self.v_dtype.width):
            # k tile >= v tile: give v k's stage stride in v_dtype units
            k_tile_cosize = cute.cosize(
                cute.select(k_smem_layout_staged, mode=[0, 1, 2])
            )
            v_stage_stride = k_tile_cosize * self.k_dtype.width // self.v_dtype.width
            v_smem_layout_staged = cute.append(
                cute.select(v_smem_layout_staged_origin, mode=[0, 1, 2]),
                cute.make_layout(self.kv_stage, stride=v_stage_stride),
            )
            sK_cosize = cute.cosize(k_smem_layout_staged)
        else:
            # v tile > k tile: give k v's stage stride in k_dtype units
            v_tile_cosize = cute.cosize(
                cute.select(v_smem_layout_staged_origin, mode=[0, 1, 2])
            )
            k_stage_stride = v_tile_cosize * self.v_dtype.width // self.k_dtype.width
            k_smem_layout_staged = cute.append(
                cute.select(k_smem_layout_staged, mode=[0, 1, 2]),
                cute.make_layout(self.kv_stage, stride=k_stage_stride),
            )
            v_smem_layout_staged = v_smem_layout_staged_origin
            # cute.cosize gives (kv_stage-1)*k_stage_stride + k_tile_cosize, but the
            # last stage must also accommodate a full V tile, so size for kv_stage slots.
            sK_cosize = self.kv_stage * k_stage_stride

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
        class SharedStorage:
            # Pipeline barriers
            load_q_mbar_ptr: cute.struct.MemRange[Int64, self.q_stage * 2]
            load_kv_mbar_ptr: cute.struct.MemRange[Int64, self.kv_stage * 2]
            mma_s0_mbar_ptr: cute.struct.MemRange[Int64, self.mma_softmax_stage * 2]
            mma_s1_mbar_ptr: cute.struct.MemRange[Int64, self.mma_softmax_stage * 2]
            p0_mma_mbar_ptr: cute.struct.MemRange[Int64, self.p_mma_stage * 2]
            p1_mma_mbar_ptr: cute.struct.MemRange[Int64, self.p_mma_stage * 2]
            s0_corr_mbar_ptr: cute.struct.MemRange[Int64, self.softmax_corr_stage * 2]
            s1_corr_mbar_ptr: cute.struct.MemRange[Int64, self.softmax_corr_stage * 2]
            corr_epi_mbar_ptr: cute.struct.MemRange[Int64, self.epi_stage * 2]
            mma_corr_mbar_ptr: cute.struct.MemRange[Int64, self.mma_corr_stage * 2]
            s0_p1_inplace_barrier_ptr: cute.struct.MemRange[Int64, self.p_mma_stage * 2]
            s1_p0_inplace_barrier_ptr: cute.struct.MemRange[Int64, self.p_mma_stage * 2]
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
                cute.struct.MemRange[self.k_dtype, sK_cosize],
                self.buffer_align_bytes,
            ]
            # Skip softmax and PV warpgroup votes
            s0_warp_wants_skip_softmax_exchange: cute.struct.MemRange[Int8, 4]
            s1_warp_wants_skip_softmax_exchange: cute.struct.MemRange[Int8, 4]

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
            o,
            cum_seqlen_q,
            cum_seqlen_k,
            lse,
            sink,
            scale_softmax_log2,
            scale_softmax,
            scale_output,
            skip_softmax_threshold_log2,
            window_size_left,
            window_size_right,
            q_smem_layout_staged,
            k_smem_layout_staged,
            p_tmem_layout_staged,
            v_smem_layout_staged,
            o_smem_layout_staged,
            skip_softmax_count,
            total_softmax_count,
            self.tile_sched_params,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=self.cluster_shape_mnk,
            stream=stream,
            min_blocks_per_mp=1,
            use_pdl=use_pdl,
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
        mO: cute.Tensor,
        cum_seqlen_q: Optional[cute.Tensor],
        cum_seqlen_k: Optional[cute.Tensor],
        mLSE: Optional[cute.Tensor],
        mSink: Optional[cute.Tensor],
        scale_softmax_log2: Float32,
        scale_softmax: Float32,
        scale_output: Float32,
        skip_softmax_threshold_log2: Optional[Float32],
        window_size_left: Optional[Int32],
        window_size_right: Optional[Int32],
        q_smem_layout_staged: cute.ComposedLayout,
        k_smem_layout_staged: cute.ComposedLayout,
        p_tmem_layout_staged: cute.ComposedLayout,
        v_smem_layout_staged: cute.ComposedLayout,
        o_smem_layout_staged: cute.ComposedLayout,
        skip_softmax_count: Optional[cute.Tensor],
        total_softmax_count: Optional[cute.Tensor],
        tile_sched_params: fmha_utils.FmhaStaticTileSchedulerParams,
    ):
        """The device kernel implementation of the Fused Multi-Head Attention.

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
        :param mO: Non-partitioned output tensor
        :type mO: cute.Tensor
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
            if cutlass.const_expr(self.use_tma_store):
                cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_o)

        # Alloc
        smem = utils.SmemAllocator()
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
        load_kv_full_mbar_ptr = storage.load_kv_mbar_ptr.data_ptr()
        load_kv_empty_mbar_ptr = load_kv_full_mbar_ptr + self.kv_stage
        mma_s0_producer, mma_s0_consumer = pipeline.PipelineUmmaAsync.create(
            num_stages=self.mma_softmax_stage,
            producer_group=make_thread_cooperative_group(len([self.mma_warp_id])),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax0_warp_ids)
            ),
            barrier_storage=storage.mma_s0_mbar_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        mma_s1_producer, mma_s1_consumer = pipeline.PipelineUmmaAsync.create(
            num_stages=self.mma_softmax_stage,
            producer_group=make_thread_cooperative_group(len([self.mma_warp_id])),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax1_warp_ids)
            ),
            barrier_storage=storage.mma_s1_mbar_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        p0_mma_producer, p0_mma_consumer = pipeline.PipelineAsyncUmma.create(
            num_stages=self.p_mma_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax0_warp_ids)
            ),
            consumer_group=make_thread_cooperative_group(len([self.mma_warp_id])),
            barrier_storage=storage.p0_mma_mbar_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        p1_mma_producer, p1_mma_consumer = pipeline.PipelineAsyncUmma.create(
            num_stages=self.p_mma_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax1_warp_ids)
            ),
            consumer_group=make_thread_cooperative_group(len([self.mma_warp_id])),
            barrier_storage=storage.p1_mma_mbar_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        s0_corr_producer, s0_corr_consumer = pipeline.PipelineAsync.create(
            num_stages=self.softmax_corr_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len((*self.softmax0_warp_ids, self.mma_warp_id))
            ),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.correction_warp_ids)
            ),
            barrier_storage=storage.s0_corr_mbar_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        s1_corr_producer, s1_corr_consumer = pipeline.PipelineAsync.create(
            num_stages=self.softmax_corr_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len((*self.softmax1_warp_ids, self.mma_warp_id))
            ),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.correction_warp_ids)
            ),
            barrier_storage=storage.s1_corr_mbar_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
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
        s0_p1_inplace_producer, s0_p1_inplace_consumer = pipeline.PipelineAsync.create(
            num_stages=self.p_mma_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax0_warp_ids)
            ),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax1_warp_ids)
            ),
            barrier_storage=storage.s0_p1_inplace_barrier_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        s1_p0_inplace_producer, s1_p0_inplace_consumer = pipeline.PipelineAsync.create(
            num_stages=self.p_mma_stage,
            producer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax0_warp_ids)
            ),
            consumer_group=make_thread_cooperative_group(
                self.threads_per_warp * len(self.softmax1_warp_ids)
            ),
            barrier_storage=storage.s1_p0_inplace_barrier_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        tmem = utils.TmemAllocator(
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
        # (MMA, MMA_K, MMA_D, PIPE)
        sK = storage.sK.get_tensor(
            k_smem_layout_staged.outer, swizzle=k_smem_layout_staged.inner
        )
        # (MMA, MMA_K, MMA_D, PIPE)
        # Reuse k's smem buffer for v. Recast element type so MMA descriptor matches v_dtype.
        sV_ptr = cute.recast_ptr(
            cute.recast_ptr(sK.iterator, dtype=self.v_dtype),
            v_smem_layout_staged.inner,
        )
        sV = cute.make_tensor(sV_ptr, v_smem_layout_staged.outer)
        sO = storage.sO.get_tensor(
            o_smem_layout_staged.outer, swizzle=o_smem_layout_staged.inner
        )
        s0_warp_wants_skip_softmax_exchange = (
            storage.s0_warp_wants_skip_softmax_exchange.get_tensor(
                cute.make_layout((4,))
            )
        )
        s1_warp_wants_skip_softmax_exchange = (
            storage.s1_warp_wants_skip_softmax_exchange.get_tensor(
                cute.make_layout((4,))
            )
        )

        qk_thr_mma = qk_tiled_mma.get_slice(0)  # default 1sm
        pv_thr_mma = pv_tiled_mma.get_slice(0)  # default 1sm
        tSrQ = qk_thr_mma.make_fragment_A(sQ)
        tSrK = qk_thr_mma.make_fragment_B(sK)
        tOrV = pv_thr_mma.make_fragment_B(sV)

        def make_tmem_tensors(
            self,
            qk_thr_mma: cute.TiledMma,
            pv_thr_mma: cute.TiledMma,
            p_tmem_layout_staged: cute.Layout,
            tmem_ptr: cute.Pointer,
        ):
            qk_acc_shape = qk_thr_mma.partition_shape_C(
                (self.qk_mma_tiler[0], self.qk_mma_tiler[1])
            )
            tStS_fake = qk_thr_mma.make_fragment_C(qk_acc_shape)
            tStS = cute.make_tensor(tmem_ptr + self.tmem_s0_offset, tStS_fake.layout)
            pv_acc_shape = pv_thr_mma.partition_shape_C(
                (self.pv_mma_tiler[0], self.pv_mma_tiler[1])
            )
            tOtO = pv_thr_mma.make_fragment_C(pv_acc_shape)
            tStS0 = cute.make_tensor(tmem_ptr + self.tmem_s0_offset, tStS.layout)
            tStS1 = cute.make_tensor(tmem_ptr + self.tmem_s1_offset, tStS.layout)
            tOtO0 = cute.make_tensor(tmem_ptr + self.tmem_o0_offset, tOtO.layout)
            tOtO1 = cute.make_tensor(tmem_ptr + self.tmem_o1_offset, tOtO.layout)
            tP = cute.make_tensor(tStS.iterator, p_tmem_layout_staged.outer)
            tOrP = pv_thr_mma.make_fragment_A(tP)[None, None, None, 0]
            tOrP0 = cute.make_tensor(
                cute.recast_ptr(
                    tmem_ptr + self.tmem_p0_offset,
                    dtype=tOrP.dtype,
                ),
                tOrP.layout,
            )
            tOrP1 = cute.make_tensor(
                cute.recast_ptr(
                    tmem_ptr + self.tmem_p1_offset,
                    dtype=tOrP.dtype,
                ),
                tOrP.layout,
            )
            return tStS, tStS0, tStS1, tOtO0, tOtO1, tOrP0, tOrP1

        tile_sched = fmha_utils.create_fmha_static_tile_scheduler(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()
        pipeline_init_wait()
        softmax_fn = partial(
            self.softmax,
            qk_thr_mma=qk_thr_mma,
            value_args=(
                mK_kdl.shape[0],
                mQ_qdl.shape[0],
                scale_softmax_log2,
                skip_softmax_threshold_log2,
            ),
            mask_args=(window_size_left, window_size_right),
            sched_args=(tile_sched, work_tile),
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
            cute.arch.griddepcontrol_wait()
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
                    seqlen_kv_loop_start = fmha_utils.FusedMask.get_trip_start(
                        self.mask_type,
                        curr_block_coord,
                        self.cta_tiler,
                        seqlen_q,
                        seqlen_k,
                        window_size_left,
                    )
                    # Q0
                    q0_coord = 2 * curr_block_coord[0]
                    q0_handle = load_q_producer.acquire_and_advance()
                    cute.copy(
                        tma_atom_q,
                        tQgQ[None, q0_coord],
                        tQsQ[None, q0_handle.index],
                        tma_bar_ptr=q0_handle.barrier,
                    )
                    seqlen_kv_loop_steps = fmha_utils.FusedMask.get_trip_count(
                        self.mask_type,
                        curr_block_coord,
                        self.cta_tiler,
                        seqlen_q,
                        seqlen_k,
                        window_size_left,
                        window_size_right,
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
                        v_handle, load_kv_producer = (
                            self.kv_producer_update_tx_acquire_and_advance(
                                load_kv_producer,
                                load_kv_empty_mbar_ptr,
                                load_kv_full_mbar_ptr,
                                self.tma_copy_v_bytes,
                            )
                        )
                        cute.copy(
                            tma_atom_v,
                            tVgV[None, kv_coord - 1],
                            tVsV[None, v_handle.index],
                            tma_bar_ptr=load_kv_full_mbar_ptr + v_handle.index,
                        )
                        kv_coord += 1
                    # End of seqlen_kv loop
                    # Vi_end
                    v_handle, load_kv_producer = (
                        self.kv_producer_update_tx_acquire_and_advance(
                            load_kv_producer,
                            load_kv_empty_mbar_ptr,
                            load_kv_full_mbar_ptr,
                            self.tma_copy_v_bytes,
                        )
                    )
                    cute.copy(
                        tma_atom_v,
                        tVgV[None, kv_coord - 1],
                        tVsV[None, v_handle.index],
                        tma_bar_ptr=load_kv_full_mbar_ptr + v_handle.index,
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
            tStS, tStS0, tStS1, tOtO0, tOtO1, tOrP0, tOrP1 = make_tmem_tensors(
                self, qk_thr_mma, pv_thr_mma, p_tmem_layout_staged, tmem_ptr
            )
            enable_skip_softmax = skip_softmax_threshold_log2 is not None
            tiled_tmem_load_v = None
            tTMEM_LOADtS_v0, tTMEM_LOADtS_v1 = None, None
            tTMEM_LOADrS_v0, tTMEM_LOADrS_v1 = None, None
            if cutlass.const_expr(enable_skip_softmax):
                cS = cute.make_identity_tensor(
                    cute.select(self.qk_mma_tiler, mode=[0, 1])
                )
                tScS = qk_thr_mma.partition_C(cS)
                tStS_v = cute.composition(
                    tStS, cute.make_layout((self.threads_per_warp, 1))
                )
                tScS_v = cute.composition(
                    tScS, cute.make_layout((self.threads_per_warp, 1))
                )
                tmem_load_v_atom = cute.make_copy_atom(
                    tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(1)),
                    self.qk_acc_dtype,
                )
                thread_idx = tidx % self.threads_per_warp

                tiled_tmem_load_v = tcgen05.make_tmem_copy(tmem_load_v_atom, tStS_v)
                thr_tmem_load_v = tiled_tmem_load_v.get_slice(thread_idx)
                tTMEM_LOADtS_v = thr_tmem_load_v.partition_S(tStS_v)
                tTMEM_LOADcS_v = thr_tmem_load_v.partition_D(tScS_v)
                tTMEM_LOADrS_v0 = cute.make_rmem_tensor(
                    tTMEM_LOADcS_v.shape, self.qk_acc_dtype
                )
                tTMEM_LOADrS_v1 = cute.make_rmem_tensor(
                    tTMEM_LOADcS_v.shape, self.qk_acc_dtype
                )
                tTMEM_LOADtS_v0 = cute.make_tensor(
                    tTMEM_LOADtS_v.iterator + self.tmem_skip_softmax0_offset,
                    tTMEM_LOADtS_v.layout,
                )
                tTMEM_LOADtS_v1 = cute.make_tensor(
                    tTMEM_LOADtS_v.iterator + self.tmem_skip_softmax1_offset,
                    tTMEM_LOADtS_v.layout,
                )

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
                    # Wait for K0
                    k_handle = load_kv_consumer.wait_and_advance()
                    tSrK0 = tSrK[None, None, None, k_handle.index]
                    # GEMM_QK00 (Q0 * K0 -> S0)
                    mma_s0_producer, s0_corr_producer = self.mma_qk(
                        qk_tiled_mma,
                        (tSrQ0, tSrK0, tStS0),
                        (mma_s0_producer, s0_corr_producer),
                    )
                    # Wait for Q1
                    q1_handle = load_q_consumer.wait_and_advance()
                    tSrQ1 = tSrQ[None, None, None, q1_handle.index]
                    # GEMM_QK10 (Q1 * K0 -> S1), K0 is ready in GEMM_QK00
                    mma_s1_producer, s1_corr_producer = self.mma_qk(
                        qk_tiled_mma,
                        (tSrQ1, tSrK0, tStS1),
                        (mma_s1_producer, s1_corr_producer),
                    )
                    # Release K0
                    k_handle.release()
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
                    # O1 hasn't been accumulated yet, its first MMA calculation doesn't need to accumulate
                    pv_whether_acc = False
                    for i in cutlass.range(1, seqlen_kv_loop_steps, 1, unroll=1):
                        # Wait for Ki
                        k_handle = load_kv_consumer.wait_and_advance()
                        tSrKi = tSrK[None, None, None, k_handle.index]
                        # GEMM_QK0i (Q0 * Ki -> S0)
                        mma_s0_producer, s0_corr_producer = self.mma_qk(
                            qk_tiled_mma,
                            (tSrQ0, tSrKi, tStS0),
                            (mma_s0_producer, s0_corr_producer),
                        )
                        # Wait for Vi-1
                        v_handle = load_kv_consumer.wait_and_advance()
                        tOrVi = tOrV[None, None, None, v_handle.index]
                        # GEMM_PV0(i-1) (P0 * Vi-1 -> O0_partial)
                        mma_corr_producer, p0_mma_consumer = self.mma_pv(
                            pv_tiled_mma,
                            pv_whether_acc,
                            (tOrP0, tOrVi, tOtO0),
                            (mma_corr_producer, p0_mma_consumer),
                            (
                                enable_skip_softmax,
                                tiled_tmem_load_v,
                                tTMEM_LOADtS_v0,
                                tTMEM_LOADrS_v0,
                            ),
                        )
                        # GEMM_QK1i (Q1 * Ki -> S1)
                        mma_s1_producer, s1_corr_producer = self.mma_qk(
                            qk_tiled_mma,
                            (tSrQ1, tSrKi, tStS1),
                            (mma_s1_producer, s1_corr_producer),
                        )
                        # Release Ki
                        k_handle.release()
                        # GEMM_PV1(i-1) (P1 * Vi-1 -> O1_partial)
                        mma_corr_producer, p1_mma_consumer = self.mma_pv(
                            pv_tiled_mma,
                            pv_whether_acc,
                            (tOrP1, tOrVi, tOtO1),
                            (mma_corr_producer, p1_mma_consumer),
                            (
                                enable_skip_softmax,
                                tiled_tmem_load_v,
                                tTMEM_LOADtS_v1,
                                tTMEM_LOADrS_v1,
                            ),
                        )
                        pv_whether_acc = True
                        # Release Vi-1
                        v_handle.release()
                    # End of seqlen_kv loop
                    # release Q0 & Q1
                    q0_handle.release()
                    q1_handle.release()
                    # Wait for Vi_end
                    v_handle = load_kv_consumer.wait_and_advance()
                    tOrVi = tOrV[None, None, None, v_handle.index]
                    # GEMM_PV0(i_end) (P0 * Vi_end -> O0)
                    mma_corr_producer, p0_mma_consumer = self.mma_pv(
                        pv_tiled_mma,
                        pv_whether_acc,
                        (tOrP0, tOrVi, tOtO0),
                        (mma_corr_producer, p0_mma_consumer),
                        (
                            enable_skip_softmax,
                            tiled_tmem_load_v,
                            tTMEM_LOADtS_v0,
                            tTMEM_LOADrS_v0,
                        ),
                    )
                    # GEMM_PV1(i_end) (P1 * Vi_end -> O1)
                    mma_corr_producer, p1_mma_consumer = self.mma_pv(
                        pv_tiled_mma,
                        pv_whether_acc,
                        (tOrP1, tOrVi, tOtO1),
                        (mma_corr_producer, p1_mma_consumer),
                        (
                            enable_skip_softmax,
                            tiled_tmem_load_v,
                            tTMEM_LOADtS_v1,
                            tTMEM_LOADrS_v1,
                        ),
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
        #  Epilogue (TMA store path only)
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.epilogue_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_other)
            if cutlass.const_expr(self.use_tma_store):
                while work_tile.is_valid_tile:
                    curr_block_coord = work_tile.tile_idx
                    batch_coord = curr_block_coord[2][1]
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
                        mO_qdl_ = mO_qdl
                        if cutlass.const_expr(cum_seqlen_q is not None):
                            mO_qdl_ = cute.domain_offset(
                                (cum_seqlen_q[batch_coord], 0, ((0, 0), 0)), mO_qdl
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
                cute.arch.griddepcontrol_launch_dependents()
            # End of persistent scheduler loop
        # ///////////////////////////////////////////////////////////////////////////////
        #  Softmax0
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx < self.softmax1_warp_ids[0]:
            cute.arch.setmaxregister_increase(self.num_regs_softmax)
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.qk_acc_dtype)
            tStS, tStS0, tStS1, tOtO0, tOtO1, tOrP0, tOrP1 = make_tmem_tensors(
                self, qk_thr_mma, pv_thr_mma, p_tmem_layout_staged, tmem_ptr
            )
            softmax_fn(
                stage=0,
                tensor_args=(
                    tStS,
                    tStS0,
                    cum_seqlen_k,
                    cum_seqlen_q,
                    s0_warp_wants_skip_softmax_exchange,
                    skip_softmax_count,
                    total_softmax_count,
                ),
                pipeline_args=(mma_s0_consumer, s0_corr_producer, p0_mma_producer),
                inplace_args=(s0_p1_inplace_producer, s1_p0_inplace_consumer),
            )

        # ///////////////////////////////////////////////////////////////////////////////
        #  Softmax1
        # ///////////////////////////////////////////////////////////////////////////////
        if (
            warp_idx < self.correction_warp_ids[0]
            and warp_idx >= self.softmax1_warp_ids[0]
        ):
            cute.arch.setmaxregister_increase(self.num_regs_softmax)
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.qk_acc_dtype)
            tStS, tStS0, tStS1, tOtO0, tOtO1, tOrP0, tOrP1 = make_tmem_tensors(
                self, qk_thr_mma, pv_thr_mma, p_tmem_layout_staged, tmem_ptr
            )
            softmax_fn(
                stage=1,
                tensor_args=(
                    tStS,
                    tStS1,
                    cum_seqlen_k,
                    cum_seqlen_q,
                    s1_warp_wants_skip_softmax_exchange,
                    skip_softmax_count,
                    total_softmax_count,
                ),
                pipeline_args=(mma_s1_consumer, s1_corr_producer, p1_mma_producer),
                inplace_args=(s1_p0_inplace_producer, s0_p1_inplace_consumer),
            )

        # ///////////////////////////////////////////////////////////////////////////////
        #  Correction
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx >= self.correction_warp_ids[0] and warp_idx < self.mma_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_correction)
            tmem.allocate(self.num_tmem_alloc_cols)
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.qk_acc_dtype)
            tStS, tStS0, tStS1, tOtO0, tOtO1, tOrP0, tOrP1 = make_tmem_tensors(
                self, qk_thr_mma, pv_thr_mma, p_tmem_layout_staged, tmem_ptr
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
                row_idx = Int32(0)
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
                    row_idx = (
                        curr_block_coord[0] * self.cta_tiler[0] + tTMEM_LOAD_VECcS[0][0]
                    )
                    if cutlass.const_expr(cum_seqlen_k is not None):
                        cuseqlen_k = cum_seqlen_k[batch_coord]
                        seqlen_k = cum_seqlen_k[batch_coord + 1] - cuseqlen_k
                    continue_cond = seqlen_k <= 0
                if not continue_cond:
                    # Ignore first signal from softmax as no correction is required
                    vec0_handle = s0_corr_consumer.wait_and_advance()
                    vec0_handle.release()
                    vec1_handle = s1_corr_consumer.wait_and_advance()
                    vec1_handle.release()
                    # O0/O1 share the same mma_corr consumer state, so the Oi
                    # peek token rolls from O0 -> O1 -> next O0. Seed with a
                    # blocking token; the rescale helper refreshes it near the
                    # end of each iteration.
                    oi_peek_status = cutlass.Boolean(False)
                    seqlen_kv_loop_steps = fmha_utils.FusedMask.get_trip_count(
                        self.mask_type,
                        curr_block_coord,
                        self.cta_tiler,
                        seqlen_q,
                        seqlen_k,
                        window_size_left,
                        window_size_right,
                    )
                    for i in cutlass.range(1, seqlen_kv_loop_steps, 1, unroll=1):
                        # Rescale O0
                        (
                            (s0_corr_consumer, mma_corr_consumer),
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
                            (s1_corr_consumer, mma_corr_consumer),
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
                        seqlen_q,
                        curr_block_coord,
                        scale_softmax,
                        scale_output,
                    )
                    if cutlass.const_expr(self.use_tma_store):
                        # TMA store path: write to sO, signal epilogue warp
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
                                    mSink,
                                ),
                                (
                                    s0_corr_consumer,
                                    mma_corr_consumer,
                                    corr_epi_producer,
                                ),
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
                                    mSink,
                                ),
                                (
                                    s1_corr_consumer,
                                    mma_corr_consumer,
                                    corr_epi_producer,
                                ),
                                (row_idx, *value_args),
                            )
                        )
                    else:
                        # st.global path: store directly to global memory
                        block_offset_o = Int32(0)
                        if cutlass.const_expr(cum_seqlen_q is not None):
                            block_offset_o = cum_seqlen_q[batch_coord]
                        mO_ = cute.make_tensor(
                            mO.iterator + block_offset_o * mO.stride[0],
                            cute.make_layout(
                                (seqlen_q, mO.shape[1], mO.shape[2]),
                                stride=mO.stride,
                            ),
                        )
                        o0_coord = 2 * curr_block_coord[0]
                        o1_coord = o0_coord + 1
                        gO_stg = cute.local_tile(
                            mO_,
                            (self.pv_mma_tiler[0], self.pv_mma_tiler[1]),
                            (None, None, None),
                        )
                        gO0 = gO_stg[None, None, o0_coord, 0, curr_block_coord[2]]
                        gO1 = gO_stg[None, None, o1_coord, 0, curr_block_coord[2]]
                        # Normalize O0 and store to global memory
                        s0_corr_consumer, mma_corr_consumer = self.correction_epilog(
                            pv_thr_mma,
                            tiled_tmem_load_vec,
                            (
                                tOtO0,
                                tTMEM_LOAD_VECtS0,
                                tTMEM_LOAD_VECcS,
                                gO0,
                                mLSE,
                                mSink,
                            ),
                            (s0_corr_consumer, mma_corr_consumer),
                            (row_idx, *value_args),
                        )
                        row_idx += self.qk_mma_tiler[0]
                        # Normalize O1 and st.global to global memory
                        s1_corr_consumer, mma_corr_consumer = self.correction_epilog(
                            pv_thr_mma,
                            tiled_tmem_load_vec,
                            (
                                tOtO1,
                                tTMEM_LOAD_VECtS1,
                                tTMEM_LOAD_VECcS,
                                gO1,
                                mLSE,
                                mSink,
                            ),
                            (s1_corr_consumer, mma_corr_consumer),
                            (row_idx, *value_args),
                        )
                # End of if not continue_cond
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            if cutlass.const_expr(not self.use_tma_store):
                cute.arch.griddepcontrol_launch_dependents()
            # End of persistent scheduler loop
            tmem.relinquish_alloc_permit()
            # Synchronize before TMEM dealloc (done by the caller)
            self.tmem_dealloc_barrier.arrive_and_wait()
            tmem.free(tmem_ptr)
        return

    @cute.jit
    def kv_producer_update_tx_acquire_and_advance(
        self, tma_producer, empty_mbar_ptr, full_mbar_ptr, tx_bytes
    ):
        # This utility function is a special version of tma_producer.acquire_and_advance().
        # This is used to customize the tx bytes which is different from
        # the initialized tx bytes of tma_producer.
        state = tma_producer._PipelineProducer__state.clone()
        cute.arch.mbarrier_wait(empty_mbar_ptr + state.index, state.phase)
        with cute.arch.elect_one():
            cute.arch.mbarrier_arrive_and_expect_tx(
                full_mbar_ptr + state.index,
                tx_bytes,
            )
        tma_producer.advance()
        return state, tma_producer

    @cute.jit
    def get_skip_softmax_flag(self, tiled_tmem_load_v, tTMEM_LOADtS_v, tTMEM_LOADrS_v):
        cute.copy(tiled_tmem_load_v, tTMEM_LOADtS_v, tTMEM_LOADrS_v)
        tTMEM_LOADrS_v_i32 = cute.recast_tensor(tTMEM_LOADrS_v, dtype=cutlass.Int32)
        skip_softmax_flag = cute.arch.make_warp_uniform(tTMEM_LOADrS_v_i32[0])
        return skip_softmax_flag

    @cute.jit
    def mma_qk(
        self,
        tiled_mma: cute.TiledMma,
        tensor_args: Tuple,
        pipeline_args: Tuple,
        pipeline_tokens: Tuple = (None, None),
    ) -> Tuple[pipeline.PipelineProducer, pipeline.PipelineProducer]:
        """Perform a single step of the QK GEMM computation on a block of attention scores.

        :param tiled_mma: Tiled MMA for QK GEMM
        :type tiled_mma: cute.TiledMma
        :param tensor_args: Tuple containing Qi, K, and Si
        :type tensor_args: Tuple
        :param pipeline_args: Tuple containing mma_si_producer and si_corr_producer
        :type pipeline_args: Tuple
        :param pipeline_tokens: Optional non-blocking peek tokens for the Si and
            vec_i producers, in the form ``(si_peek_status, veci_peek_status)``.
            ``None`` for either token falls back to a blocking acquire.
        :type pipeline_tokens: Tuple
        :return: Tuple containing mma_si_producer and si_corr_producer
        :rtype: Tuple[pipeline.PipelineProducer, pipeline.PipelineProducer]
        """
        tSrQi, tSrK, tStSi = tensor_args
        mma_si_producer, si_corr_producer = pipeline_args
        si_peek_status, veci_peek_status = pipeline_tokens
        # 0. Make sure Qi & K are ready when calling mma_qk
        # 1. acquire S0
        si_handle = mma_si_producer.acquire_and_advance(si_peek_status)
        # 2. make sure vec is already released in corr
        veci_handle = si_corr_producer.acquire_and_advance(veci_peek_status)
        veci_handle.commit()
        # 3. gemm
        num_kphases = cute.size(tSrQi, mode=[2])
        for kphase_idx in cutlass.range(num_kphases, unroll_full=True):
            kphase_coord = (None, None, kphase_idx)
            tiled_mma.set(tcgen05.Field.ACCUMULATE, kphase_idx != 0)
            cute.gemm(
                tiled_mma,
                tStSi,
                tSrQi[kphase_coord],
                tSrK[kphase_coord],
                tStSi,
            )
        # 4. release S0
        si_handle.commit()
        return mma_si_producer, si_corr_producer

    @cute.jit
    def mma_pv(
        self,
        tiled_mma: cute.TiledMma,
        whether_acc: bool,
        tensor_args: Tuple,
        pipeline_args: Tuple,
        skip_pv_args: Tuple,
    ) -> Tuple[
        pipeline.PipelineProducer,
        pipeline.PipelineConsumer,
    ]:
        """Perform a single step of the PV GEMM computation on accumulating O.

        :param tiled_mma: Tiled MMA for PV GEMM
        :type tiled_mma: cute.TiledMma
        :param whether_acc: Whether to accumulate O
        :type whether_acc: bool
        :param tensor_args: Tuple containing Pi, Vi, and Oi
        :type tensor_args: Tuple
        :param pipeline_args: Tuple containing mma_corr_producer and pi_mma_consumer
        :type pipeline_args: Tuple
        :param skip_pv_args: Tuple containing enable_skip_softmax, tiled_tmem_load_v, tTMEM_LOADtS_v, tTMEM_LOADrS_v
        :type skip_pv_args: Tuple
        :return: Tuple containing mma_corr_producer and pi_mma_consumer
        :rtype: Tuple[pipeline.PipelineProducer, pipeline.PipelineConsumer]
        """
        tOrPi, tOrVi, tOtOi = tensor_args
        mma_corr_producer, pi_mma_consumer = pipeline_args
        enable_skip_softmax, tiled_tmem_load_v, tTMEM_LOADtS_v, tTMEM_LOADrS_v = (
            skip_pv_args
        )
        # 0. Make sure Vi is ready when calling mma_pv
        # 1. acquire Oi
        oi_handle = mma_corr_producer.acquire_and_advance()
        # 2. wait for Pi
        pi_handle = pi_mma_consumer.wait_and_advance()
        # 3. gemm
        num_kphases = cute.size(tOrPi, mode=[2])
        if cutlass.const_expr(enable_skip_softmax):
            skip_pv = self.get_skip_softmax_flag(
                tiled_tmem_load_v, tTMEM_LOADtS_v, tTMEM_LOADrS_v
            )
            if not skip_pv:
                for kphase_idx in cutlass.range(num_kphases, unroll_full=True):
                    kphase_coord = (None, None, kphase_idx)
                    tiled_mma.set(
                        tcgen05.Field.ACCUMULATE, whether_acc or kphase_idx != 0
                    )
                    cute.gemm(
                        tiled_mma,
                        tOtOi,
                        tOrPi[kphase_coord],
                        tOrVi[kphase_coord],
                        tOtOi,
                    )
        else:
            for kphase_idx in cutlass.range(num_kphases, unroll_full=True):
                kphase_coord = (None, None, kphase_idx)
                tiled_mma.set(tcgen05.Field.ACCUMULATE, whether_acc or kphase_idx != 0)
                cute.gemm(
                    tiled_mma,
                    tOtOi,
                    tOrPi[kphase_coord],
                    tOrVi[kphase_coord],
                    tOtOi,
                )
        # 4. commit Pi
        pi_handle.release()
        # 5. commit Oi
        oi_handle.commit()
        return mma_corr_producer, pi_mma_consumer

    @cute.jit
    def calculate_skip_softmax_flag(
        self,
        row_max,
        tile_row_max,
        scale_softmax_log2,
        skip_softmax_threshold_log2,
        seqlen_q,
        thread_idx,
        logical_offset,
        warp_wants_skip_softmax_exchange,
        stage,
        skip_softmax_count,
        total_softmax_count,
    ) -> Tuple[bool, float]:
        """Calculate the skip softmax flag and the row maximum.

        :param row_max: The row maximum.
        :type row_max: float
        :param tile_row_max: The tile row maximum.
        :type tile_row_max: float
        :param scale_softmax_log2: The scale softmax log2.
        :type scale_softmax_log2: float
        :param skip_softmax_threshold_log2: The skip softmax threshold log2.
        :type skip_softmax_threshold_log2: float
        :param seqlen_q: The sequence length q.
        :type seqlen_q: int
        :param thread_idx: The thread index.
        :type thread_idx: int
        :param logical_offset: The logical offset.
        :type logical_offset: Tuple[int, int]
        :param warp_wants_skip_softmax_exchange: The warp wants skip softmax exchange.
        :type warp_wants_skip_softmax_exchange: cute.Tensor
        :param stage: The stage.
        :type stage: int
        :param skip_softmax_count: The skip softmax count.
        :type skip_softmax_count: cute.Tensor
        :param total_softmax_count: The total softmax count.
        :type total_softmax_count: cute.Tensor
        :return: Tuple containing the skip softmax flag and the row maximum.
        :rtype: Tuple[bool, float]
        """
        thread_wants_skip = (
            tile_row_max * scale_softmax_log2 - row_max * scale_softmax_log2
        ) < skip_softmax_threshold_log2
        thread_wants_skip = thread_wants_skip or (
            (logical_offset[0] + thread_idx) >= seqlen_q
        )
        warp_wants_skip = cute.arch.vote_all_sync(thread_wants_skip)

        with cute.arch.elect_one():
            warp_wants_skip_softmax_exchange[cute.arch.warp_idx() % 4] = warp_wants_skip
        softmax_barrier = (
            self.s0_warpgroup_barrier if stage == 0 else self.s1_warpgroup_barrier
        )
        softmax_barrier.arrive_and_wait()
        warp_wants_skip_softmax_exchange_i32 = cute.make_tensor(
            cute.recast_ptr(
                warp_wants_skip_softmax_exchange.iterator, dtype=cutlass.Int32
            ),
            cute.make_layout((1,)),
        )
        skip_softmax = cute.arch.popc(warp_wants_skip_softmax_exchange_i32[0]) == 4

        if not skip_softmax:
            row_max = max(row_max, tile_row_max)

        if cutlass.const_expr(skip_softmax_count is not None):
            if thread_idx == 0:
                if skip_softmax:
                    cute.arch.atomic_add(skip_softmax_count.iterator.llvm_ptr, Int32(1))
                cute.arch.atomic_add(total_softmax_count.iterator.llvm_ptr, Int32(1))
        return skip_softmax, row_max

    @cute.jit
    def apply_exp_and_cvt(
        self,
        tTMEM_LOADrS,
        tTMEM_LOADrS_cvt,
        tTMEM_STORErS_x4_e_cvt,
        stage,
        scale,
        minus_row_max_scale,
        local_row_sum,
        inplace_consumer,
        EXP2_EMULATION_OFFSET,
        EXP2_EMULATION_COUNT,
        CVT_COUNT,
        CVT_PER_STEP,
        FMA_COUNT,
        ARV_COUNT,
    ):
        """Apply the exp and conversion to the P data type on fragment.

        :param tTMEM_LOADrS: The tTMEM_LOADrS tensor.
        :type tTMEM_LOADrS: cute.Tensor
        :param tTMEM_LOADrS_cvt: The tTMEM_LOADrS_cvt tensor.
        :type tTMEM_LOADrS_cvt: cute.Tensor
        :param tTMEM_STORErS_x4_e_cvt: The tTMEM_STORErS_x4_e_cvt tensor.
        :type tTMEM_STORErS_x4_e_cvt: cute.Tensor
        :param stage: The stage.
        :type stage: int
        :param scale: The scale.
        :type scale: float
        :param minus_row_max_scale: The minus row maximum scale.
        :type minus_row_max_scale: float
        :param local_row_sum: The local row sum.
        :type local_row_sum: float
        :param inplace_consumer: The inplace consumer.
        :type inplace_consumer: cute.Tensor
        :param EXP2_EMULATION_OFFSET: The exp2 emulation offset.
        :type EXP2_EMULATION_OFFSET: int
        :param EXP2_EMULATION_COUNT: The exp2 emulation count.
        :type EXP2_EMULATION_COUNT: int
        :param CVT_COUNT: The cvt count.
        :type CVT_COUNT: int
        :param CVT_PER_STEP: The cvt per step.
        :type CVT_PER_STEP: int
        :param FMA_COUNT: The fma count.
        :type FMA_COUNT: int
        :param ARV_COUNT: The arv count.
        :type ARV_COUNT: int
        :return: The local row sum and the inplace consumer.
        :rtype: Tuple[float, cute.Tensor]
        """
        for i in cutlass.range_constexpr(0, EXP2_EMULATION_OFFSET, 2):
            if cutlass.const_expr(i >= CVT_COUNT):
                if cutlass.const_expr(i % CVT_PER_STEP == 0):
                    if cutlass.const_expr(self.v_dtype.width == 8):
                        fmha_utils.cvt_f32x4_to_f8x4(
                            tTMEM_LOADrS_cvt[None, (i - CVT_COUNT) // CVT_PER_STEP],
                            tTMEM_STORErS_x4_e_cvt[
                                None, (i - CVT_COUNT) // CVT_PER_STEP
                            ],
                        )
                    else:
                        s_vec = tTMEM_LOADrS_cvt[
                            None, (i - CVT_COUNT) // CVT_PER_STEP
                        ].load()
                        tTMEM_STORErS_x4_e_cvt[
                            None, (i - CVT_COUNT) // CVT_PER_STEP
                        ].store(s_vec.to(self.v_dtype))
                local_row_sum = cute.arch.add_packed_f32x2(
                    local_row_sum,
                    (
                        tTMEM_LOADrS[i - CVT_COUNT],
                        tTMEM_LOADrS[i - CVT_COUNT + 1],
                    ),
                )
            tTMEM_LOADrS[i] = cute.math.exp2(tTMEM_LOADrS[i], fastmath=True)
            if cutlass.const_expr(i + FMA_COUNT < EXP2_EMULATION_OFFSET):
                (
                    tTMEM_LOADrS[i + FMA_COUNT],
                    tTMEM_LOADrS[i + FMA_COUNT + 1],
                ) = cute.arch.fma_packed_f32x2(
                    (
                        tTMEM_LOADrS[i + FMA_COUNT],
                        tTMEM_LOADrS[i + FMA_COUNT + 1],
                    ),
                    (scale, scale),
                    (minus_row_max_scale, minus_row_max_scale),
                )
            tTMEM_LOADrS[i + 1] = cute.math.exp2(tTMEM_LOADrS[i + 1], fastmath=True)
            if cutlass.const_expr(i == EXP2_EMULATION_OFFSET - ARV_COUNT):
                if cutlass.const_expr(self.enable_sequence_barrier):
                    if cutlass.const_expr(stage == 0):
                        self.sequence_s1_s0_barrier.arrive()
                    else:
                        self.sequence_s0_s1_barrier.arrive()
        # The remaining conversion steps
        for i in cutlass.range_constexpr(
            EXP2_EMULATION_OFFSET - CVT_COUNT,
            EXP2_EMULATION_OFFSET,
            2,
        ):
            if cutlass.const_expr(i % CVT_PER_STEP == 0):
                if cutlass.const_expr(self.v_dtype.width == 8):
                    fmha_utils.cvt_f32x4_to_f8x4(
                        tTMEM_LOADrS_cvt[None, i // CVT_PER_STEP],
                        tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP],
                    )
                else:
                    s_vec = tTMEM_LOADrS_cvt[None, i // CVT_PER_STEP].load()
                    tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP].store(
                        s_vec.to(self.v_dtype)
                    )
            local_row_sum = cute.arch.add_packed_f32x2(
                local_row_sum, (tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1])
            )
        for i in cutlass.range_constexpr(
            EXP2_EMULATION_OFFSET, EXP2_EMULATION_OFFSET + EXP2_EMULATION_COUNT // 2, 2
        ):
            tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1] = cute.arch.fma_packed_f32x2(
                (tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1]),
                (scale, scale),
                (minus_row_max_scale, minus_row_max_scale),
            )
            tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1] = (
                fmha_utils.ex2_emulation_packed_f32x2(
                    tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1]
                )
            )
            if cutlass.const_expr((i + 2) % CVT_PER_STEP == 0):
                if cutlass.const_expr(self.v_dtype.width == 8):
                    fmha_utils.cvt_f32x4_to_f8x4(
                        tTMEM_LOADrS_cvt[None, i // CVT_PER_STEP],
                        tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP],
                    )
                else:
                    s_vec = tTMEM_LOADrS_cvt[None, i // CVT_PER_STEP].load()
                    tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP].store(
                        s_vec.to(self.v_dtype)
                    )

        inplace_peek_status = inplace_consumer.try_wait()
        for i in cutlass.range_constexpr(
            EXP2_EMULATION_OFFSET + EXP2_EMULATION_COUNT // 2,
            EXP2_EMULATION_OFFSET + EXP2_EMULATION_COUNT,
            2,
        ):
            tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1] = cute.arch.fma_packed_f32x2(
                (tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1]),
                (scale, scale),
                (minus_row_max_scale, minus_row_max_scale),
            )
            tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1] = (
                fmha_utils.ex2_emulation_packed_f32x2(
                    tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1]
                )
            )
            if cutlass.const_expr((i + 2) % CVT_PER_STEP == 0):
                if cutlass.const_expr(self.v_dtype.width == 8):
                    fmha_utils.cvt_f32x4_to_f8x4(
                        tTMEM_LOADrS_cvt[None, i // CVT_PER_STEP],
                        tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP],
                    )
                else:
                    s_vec = tTMEM_LOADrS_cvt[None, i // CVT_PER_STEP].load()
                    tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP].store(
                        s_vec.to(self.v_dtype)
                    )
        inplace_consumer.wait_and_advance(inplace_peek_status)
        return local_row_sum, inplace_consumer

    @cute.jit
    def softmax_step(
        self,
        stage: int,
        whether_apply_mask: bool,
        iter_args: Tuple,
        stats_args: Tuple,
        pipeline_args: Tuple,
        value_args: Tuple,
        atom_args: Tuple,
        tensor_args: Tuple,
    ) -> Tuple[Tuple, Tuple]:
        """Perform a single step of the softmax computation on a block of attention scores.

        This method processes one block of the attention matrix, computing numerically stable
        softmax by first finding the row maximum, subtracting it from all elements, applying
        exponential function, and then normalizing by the sum of exponentials. It also handles
        optional masking of attention scores.

        The method involves several key operations:
        1. Loading attention scores from tensor memory
        2. Applying optional masking based on position
        3. Computing row-wise maximum values for numerical stability
        4. Transforming scores using exp2(x*scale - max*scale)
        5. Computing row sums for normalization
        6. Coordinating pipeline synchronization between different processing stages

        :param stage: Processing stage (0 for first half, 1 for second half)
        :type stage: int
        :param whether_apply_mask: Whether to apply attention masking
        :type whether_apply_mask: bool
        :param iter_args: Tuple containing the counting tensor, row_max, row_sum, and vector buffer's handle for current iteration
        :type iter_args: Tuple
        :param stats_args: Tuple containing row_sum and row_max
        :type stats_args: Tuple
        :param pipeline_args: Tuple containing pipeline related arguments for MMA, correction, and sequence synchronization
        :type pipeline_args: Tuple
        :param value_args: Tuple containing seqlen_k, seqlen_q, and scale_softmax_log2
        :type value_args: Tuple
        :param atom_args: Tuple containing mma & copy atoms
        :type atom_args: Tuple
        :param tensor_args: Tuple containing softmax related tensors
        :type tensor_args: Tuple
        :param fused_mask: Compute trip counts and apply masking for attention blocks
        :type fused_mask: fmha_utils.FusedMask
        :return: Updated stats_args and pipeline_args
        :rtype: Tuple[Tuple, Tuple]
        """
        row_sum, row_max = stats_args
        cS, is_last_iter = iter_args
        (
            seqlen_k,
            seqlen_q,
            scale_softmax_log2,
            window_size_left,
            window_size_right,
            skip_softmax_threshold_log2,
            thread_idx,
            logical_offset,
        ) = value_args
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
            tiled_tmem_load,
            tiled_tmem_store,
            tiled_tmem_store_vec,
            thr_tmem_load,
            thr_tmem_store,
            thr_tmem_store_vec,
        ) = atom_args
        (
            tTMEM_LOADtS,
            tTMEM_STORE_VECtS,
            tTMEM_STORE_SKIP_SOFTMAX,
            tTMEM_STOREtS_x4,
            warp_wants_skip_softmax_exchange,
            skip_softmax_count,
            total_softmax_count,
        ) = tensor_args
        tilePlikeFP32 = self.qk_mma_tiler[1] // Float32.width * self.o_dtype.width
        tScS = qk_thr_mma.partition_C(cS)
        enable_skip_softmax = skip_softmax_threshold_log2 is not None
        tScS_vec_layout = cute.composition(tScS.layout, cute.make_layout((128, 2)))
        tScS_vec = cute.make_tensor(tScS.iterator, tScS_vec_layout)
        tScS_P_layout = cute.composition(
            tScS.layout, cute.make_layout((128, tilePlikeFP32))
        )
        tScS_P = cute.make_tensor(tScS.iterator, tScS_P_layout)
        tTMEM_LOADcS = thr_tmem_load.partition_D(tScS)
        tTMEM_STORE_VECcS = thr_tmem_store_vec.partition_S(tScS_vec)
        tTMEM_STOREcS = thr_tmem_store.partition_S(tScS_P)
        # Wait for Si
        si_handle = mma_si_consumer.wait_and_advance(si_peek_status)
        tTMEM_LOADrS = cute.make_rmem_tensor(tTMEM_LOADcS.shape, self.qk_acc_dtype)
        old_row_max = row_max
        skip_softmax = cutlass.Boolean(False)
        if whether_apply_mask:
            if cutlass.const_expr(
                self.arch >= Arch.sm_100 and self.arch <= Arch.sm_100f
            ):
                cute.copy(tiled_tmem_load, tTMEM_LOADtS, tTMEM_LOADrS)
            else:
                tTMEM_LOADrMax = cute.make_rmem_tensor(
                    cute.make_layout((1, cute.size(tTMEM_LOADrS, mode=[1]))),
                    self.qk_acc_dtype,
                )
                for i in cutlass.range_constexpr(0, cute.size(tTMEM_LOADrS, mode=[1])):
                    cute.copy_atom_call(
                        tiled_tmem_load,
                        tTMEM_LOADtS[None, i, 0, 0],
                        (tTMEM_LOADrS[None, i, 0, 0], tTMEM_LOADrMax[None, i]),
                    )
            fmha_utils.FusedMask.apply_mask(
                self.mask_type,
                tTMEM_LOADrS,
                tTMEM_LOADcS,
                seqlen_q,
                seqlen_k,
                window_size_left,
                window_size_right,
            )
            tile_row_max = tTMEM_LOADrS.load().reduce(
                cute.ReductionOp.MAX, -cutlass.Float32.inf, 0
            )
            if cutlass.const_expr(not enable_skip_softmax):
                row_max = cute.arch.fmax(row_max, tile_row_max)
            else:
                skip_softmax, row_max = self.calculate_skip_softmax_flag(
                    row_max,
                    tile_row_max,
                    scale_softmax_log2,
                    skip_softmax_threshold_log2,
                    seqlen_q,
                    thread_idx,
                    logical_offset,
                    warp_wants_skip_softmax_exchange,
                    stage,
                    skip_softmax_count,
                    total_softmax_count,
                )
            si_handle.release()
            # S0 -> P1 / S1 -> P0
            inplace_producer.commit()
            inplace_producer.advance()
        else:
            if cutlass.const_expr(
                self.arch >= Arch.sm_100 and self.arch <= Arch.sm_100f
            ):
                cute.copy(
                    tiled_tmem_load,
                    tTMEM_LOADtS[None, 0, None, None],
                    tTMEM_LOADrS[None, 0, None, None],
                )
                cute.copy(
                    tiled_tmem_load,
                    tTMEM_LOADtS[None, 1, None, None],
                    tTMEM_LOADrS[None, 1, None, None],
                )
                tile_row_max = -cutlass.Float32.inf
                tile_row_max_ = tile_row_max
                for i in cutlass.range_constexpr(
                    0, cute.size(tTMEM_LOADrS, mode=[0]), 4
                ):
                    tile_row_max = cute.arch.fmax(
                        tile_row_max, tTMEM_LOADrS[i, 0, 0, 0]
                    )
                    tile_row_max = cute.arch.fmax(
                        tile_row_max, tTMEM_LOADrS[i + 1, 0, 0, 0]
                    )
                    tile_row_max_ = cute.arch.fmax(
                        tile_row_max_, tTMEM_LOADrS[i + 2, 0, 0, 0]
                    )
                    tile_row_max_ = cute.arch.fmax(
                        tile_row_max_, tTMEM_LOADrS[i + 3, 0, 0, 0]
                    )
                cute.copy(
                    tiled_tmem_load,
                    tTMEM_LOADtS[None, 2, None, None],
                    tTMEM_LOADrS[None, 2, None, None],
                )
                for i in cutlass.range_constexpr(
                    0, cute.size(tTMEM_LOADrS, mode=[0]), 4
                ):
                    tile_row_max = cute.arch.fmax(
                        tile_row_max, tTMEM_LOADrS[i, 1, 0, 0]
                    )
                    tile_row_max = cute.arch.fmax(
                        tile_row_max, tTMEM_LOADrS[i + 1, 1, 0, 0]
                    )
                    tile_row_max_ = cute.arch.fmax(
                        tile_row_max_, tTMEM_LOADrS[i + 2, 1, 0, 0]
                    )
                    tile_row_max_ = cute.arch.fmax(
                        tile_row_max_, tTMEM_LOADrS[i + 3, 1, 0, 0]
                    )
                cute.copy(
                    tiled_tmem_load,
                    tTMEM_LOADtS[None, 3, None, None],
                    tTMEM_LOADrS[None, 3, None, None],
                )
                for i in cutlass.range_constexpr(
                    0, cute.size(tTMEM_LOADrS, mode=[0]), 4
                ):
                    tile_row_max = cute.arch.fmax(
                        tile_row_max, tTMEM_LOADrS[i, 2, 0, 0]
                    )
                    tile_row_max = cute.arch.fmax(
                        tile_row_max, tTMEM_LOADrS[i + 1, 2, 0, 0]
                    )
                    tile_row_max_ = cute.arch.fmax(
                        tile_row_max_, tTMEM_LOADrS[i + 2, 2, 0, 0]
                    )
                    tile_row_max_ = cute.arch.fmax(
                        tile_row_max_, tTMEM_LOADrS[i + 3, 2, 0, 0]
                    )
                cute.arch.fence_view_async_tmem_store()
                si_handle.release()
                # S0 -> P1 / S1 -> P0
                inplace_producer.commit()
                inplace_producer.advance()
                for i in cutlass.range_constexpr(
                    0, cute.size(tTMEM_LOADrS, mode=[0]), 4
                ):
                    tile_row_max = cute.arch.fmax(
                        tile_row_max, tTMEM_LOADrS[i, 3, 0, 0]
                    )
                    tile_row_max = cute.arch.fmax(
                        tile_row_max, tTMEM_LOADrS[i + 1, 3, 0, 0]
                    )
                    tile_row_max_ = cute.arch.fmax(
                        tile_row_max_, tTMEM_LOADrS[i + 2, 3, 0, 0]
                    )
                    tile_row_max_ = cute.arch.fmax(
                        tile_row_max_, tTMEM_LOADrS[i + 3, 3, 0, 0]
                    )
                tile_row_max = cute.arch.fmax(tile_row_max, tile_row_max_)
                if cutlass.const_expr(not enable_skip_softmax):
                    row_max = cute.arch.fmax(tile_row_max, row_max)
                else:
                    skip_softmax, row_max = self.calculate_skip_softmax_flag(
                        row_max,
                        tile_row_max,
                        scale_softmax_log2,
                        skip_softmax_threshold_log2,
                        seqlen_q,
                        thread_idx,
                        logical_offset,
                        warp_wants_skip_softmax_exchange,
                        stage,
                        skip_softmax_count,
                        total_softmax_count,
                    )
            else:
                tTMEM_LOADrMax = cute.make_rmem_tensor(
                    cute.make_layout((1, cute.size(tTMEM_LOADrS, mode=[1]))),
                    self.qk_acc_dtype,
                )
                for i in cutlass.range_constexpr(0, cute.size(tTMEM_LOADrS, mode=[1])):
                    cute.copy_atom_call(
                        tiled_tmem_load,
                        tTMEM_LOADtS[None, i, 0, 0],
                        (tTMEM_LOADrS[None, i, 0, 0], tTMEM_LOADrMax[None, i]),
                    )
                cute.arch.fence_view_async_tmem_store()
                tile_row_max = tTMEM_LOADrMax.load().reduce(
                    cute.ReductionOp.MAX, -cutlass.Float32.inf, 0
                )
                if cutlass.const_expr(not enable_skip_softmax):
                    row_max = cute.arch.fmax(tile_row_max, row_max)
                else:
                    skip_softmax, row_max = self.calculate_skip_softmax_flag(
                        row_max,
                        tile_row_max,
                        scale_softmax_log2,
                        skip_softmax_threshold_log2,
                        seqlen_q,
                        thread_idx,
                        logical_offset,
                        warp_wants_skip_softmax_exchange,
                        stage,
                        skip_softmax_count,
                        total_softmax_count,
                    )
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
        tTMEM_STORErS_x4 = cute.make_rmem_tensor(tTMEM_STOREcS.shape, self.qk_acc_dtype)
        tTMEM_STORErS_x4_e = cute.make_tensor(
            cute.recast_ptr(tTMEM_STORErS_x4.iterator, dtype=self.v_dtype),
            tTMEM_LOADrS.layout,
        )
        scale = scale_softmax_log2
        minus_row_max_scale = (0.0 - row_max_safe) * scale
        if cutlass.const_expr(self.v_dtype.width == 8 and self.p_fp8_prescale_log2 > 0):
            minus_row_max_scale = minus_row_max_scale + self.p_fp8_prescale_log2

        ARV_COUNT = 4
        FMA_COUNT = 8
        CVT_COUNT = 8 if self.v_dtype.width == 8 else 4
        CVT_PER_STEP = 4 if self.v_dtype.width == 8 else 2
        assert CVT_COUNT % CVT_PER_STEP == 0, (
            f"CVT_COUNT {CVT_COUNT} must be divisible by CVT_PER_STEP {CVT_PER_STEP}"
        )
        tTMEM_LOADrS_cvt = cute.logical_divide(
            tTMEM_LOADrS, cute.make_layout(CVT_PER_STEP)
        )
        tTMEM_STORErS_x4_e_cvt = cute.logical_divide(
            tTMEM_STORErS_x4_e, cute.make_layout(CVT_PER_STEP)
        )
        for i in cutlass.range_constexpr(0, FMA_COUNT, 2):
            tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1] = cute.arch.fma_packed_f32x2(
                (tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1]),
                (scale, scale),
                (minus_row_max_scale, minus_row_max_scale),
            )
        vec_i_handle = si_corr_producer.acquire_and_advance(vec_i_peek_status)
        cute.copy(tiled_tmem_store_vec, tTMEM_STORE_VECrS, tTMEM_STORE_VECtS)
        cute.arch.fence_view_async_tmem_store()
        # Notify correction wg that row_max is ready
        vec_i_handle.commit()

        EXP2_EMULATION_COUNT = (
            20 if self.enable_ex2_emulation and not whether_apply_mask else 0
        )
        EXP2_EMULATION_OFFSET = cute.size(tTMEM_LOADrS) - EXP2_EMULATION_COUNT
        acc_scale_ = scale * (old_row_max - row_max_safe)
        acc_scale = cute.math.exp2(acc_scale_, fastmath=True) * 0.5
        if cutlass.const_expr(self.enable_sequence_barrier):
            if cutlass.const_expr(stage == 0):
                self.sequence_s0_s1_barrier.arrive_and_wait()
            else:
                self.sequence_s1_s0_barrier.arrive_and_wait()
        if cutlass.const_expr(enable_skip_softmax):
            if not skip_softmax:
                row_sum *= acc_scale
                local_row_sum = (row_sum, row_sum)
                local_row_sum, inplace_consumer = self.apply_exp_and_cvt(
                    tTMEM_LOADrS,
                    tTMEM_LOADrS_cvt,
                    tTMEM_STORErS_x4_e_cvt,
                    stage,
                    scale,
                    minus_row_max_scale,
                    local_row_sum,
                    inplace_consumer,
                    EXP2_EMULATION_OFFSET,
                    EXP2_EMULATION_COUNT,
                    CVT_COUNT,
                    CVT_PER_STEP,
                    FMA_COUNT,
                    ARV_COUNT,
                )
                tTMEM_STORE_VECrS_i32 = cute.recast_tensor(
                    tTMEM_STORE_VECrS, dtype=cutlass.Int32
                )
                tTMEM_STORE_VECrS_i32[0] = 0
                pi_handle = pi_mma_producer.acquire_and_advance()
                # store skip softmax flag
                cute.copy(
                    tiled_tmem_store_vec,
                    tTMEM_STORE_VECrS_i32,
                    tTMEM_STORE_SKIP_SOFTMAX,
                )
                # store P
                cute.copy(tiled_tmem_store, tTMEM_STORErS_x4, tTMEM_STOREtS_x4)
                cute.arch.fence_view_async_tmem_store()
                pi_handle.commit()
                for j in cutlass.range_constexpr(
                    EXP2_EMULATION_OFFSET,
                    EXP2_EMULATION_OFFSET + EXP2_EMULATION_COUNT,
                    2,
                ):
                    local_row_sum = cute.arch.add_packed_f32x2(
                        (tTMEM_LOADrS[j], tTMEM_LOADrS[j + 1]),
                        local_row_sum,
                    )
                row_sum = local_row_sum[0] + local_row_sum[1]
                cute.arch.fence_view_async_tmem_store()
            else:
                if cutlass.const_expr(self.enable_sequence_barrier):
                    if cutlass.const_expr(stage == 0):
                        self.sequence_s1_s0_barrier.arrive()
                    else:
                        self.sequence_s0_s1_barrier.arrive()
                inplace_peek_status = inplace_consumer.try_wait()
                inplace_consumer.wait_and_advance(inplace_peek_status)
                tTMEM_STORE_VECrS_i32 = cute.recast_tensor(
                    tTMEM_STORE_VECrS, dtype=cutlass.Int32
                )
                tTMEM_STORE_VECrS_i32[0] = 1
                pi_handle = pi_mma_producer.acquire_and_advance()
                # store skip softmax flag
                cute.copy(
                    tiled_tmem_store_vec,
                    tTMEM_STORE_VECrS_i32,
                    tTMEM_STORE_SKIP_SOFTMAX,
                )
                cute.arch.fence_view_async_tmem_store()
                pi_handle.commit()
        else:
            row_sum *= acc_scale
            local_row_sum = (row_sum, row_sum)
            local_row_sum, inplace_consumer = self.apply_exp_and_cvt(
                tTMEM_LOADrS,
                tTMEM_LOADrS_cvt,
                tTMEM_STORErS_x4_e_cvt,
                stage,
                scale,
                minus_row_max_scale,
                local_row_sum,
                inplace_consumer,
                EXP2_EMULATION_OFFSET,
                EXP2_EMULATION_COUNT,
                CVT_COUNT,
                CVT_PER_STEP,
                FMA_COUNT,
                ARV_COUNT,
            )
            pi_handle = pi_mma_producer.acquire_and_advance()
            # store P
            cute.copy(tiled_tmem_store, tTMEM_STORErS_x4, tTMEM_STOREtS_x4)
            cute.arch.fence_view_async_tmem_store()
            for j in cutlass.range_constexpr(
                EXP2_EMULATION_OFFSET,
                EXP2_EMULATION_OFFSET + EXP2_EMULATION_COUNT,
                2,
            ):
                local_row_sum = cute.arch.add_packed_f32x2(
                    (tTMEM_LOADrS[j], tTMEM_LOADrS[j + 1]),
                    local_row_sum,
                )
            row_sum = local_row_sum[0] + local_row_sum[1]
            cute.arch.fence_view_async_tmem_store()
            # Notify tensor core warp that softmax(S->P) is ready
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

    # For both softmax0 and softmax1 warp group
    @cute.jit
    def softmax(
        self,
        stage: int,
        tensor_args: Tuple,
        pipeline_args: Tuple,
        inplace_args: Tuple,
        qk_thr_mma: cute.ThrMma,
        value_args: Tuple,
        mask_args: Tuple,
        sched_args: Tuple,
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
        (
            tStS,
            tStSi,
            cum_seqlen_k,
            cum_seqlen_q,
            warp_wants_skip_softmax_exchange,
            skip_softmax_count,
            total_softmax_count,
        ) = tensor_args
        mma_si_consumer, si_corr_producer, pi_mma_producer = pipeline_args
        inplace_producer, inplace_consumer = inplace_args
        (
            seqlen_k,
            seqlen_q,
            scale_softmax_log2,
            skip_softmax_threshold_log2,
        ) = value_args
        window_size_left, window_size_right = mask_args
        tile_sched, work_tile = sched_args

        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (self.threads_per_warp * len(self.softmax0_warp_ids))

        cS_base = cute.make_identity_tensor(
            (self.qk_mma_tiler[0], self.qk_mma_tiler[1])
        )
        tilePlikeFP32 = self.qk_mma_tiler[1] // 32 * self.o_dtype.width
        tScS = qk_thr_mma.partition_C(cS_base)
        tStS_vec_layout = cute.composition(tStS.layout, cute.make_layout((128, 2)))
        tmem_vec_offset = self.tmem_vec0_offset if stage == 0 else self.tmem_vec1_offset
        tStS_vec = cute.make_tensor(tStS.iterator + tmem_vec_offset, tStS_vec_layout)
        tmem_skip_softmax_offset = (
            self.tmem_skip_softmax0_offset
            if stage == 0
            else self.tmem_skip_softmax1_offset
        )
        tStS_skip_softmax = cute.make_tensor(
            tStS.iterator + tmem_skip_softmax_offset, tStS_vec_layout
        )
        tScS_vec_layout = cute.composition(tScS.layout, cute.make_layout((128, 2)))
        tScS_vec = cute.make_tensor(tScS.iterator, tScS_vec_layout)
        tStS_P_layout = cute.composition(
            tStS.layout, cute.make_layout((128, tilePlikeFP32))
        )
        tmem_p_offset = self.tmem_p0_offset if stage == 0 else self.tmem_p1_offset
        tStS_P = cute.make_tensor(tStS.iterator + tmem_p_offset, tStS_P_layout)
        if cutlass.const_expr(self.arch >= Arch.sm_100 and self.arch <= Arch.sm_100f):
            tmem_load_atom = cute.make_copy_atom(
                tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(32)),
                self.qk_acc_dtype,
            )
        else:
            tmem_load_atom = cute.make_copy_atom(
                tcgen05.copy.LdRed32x32bOp(
                    tcgen05.copy.Repetition(32), redOp=tcgen05.TmemLoadRedOp.MAX
                ),
                self.qk_acc_dtype,
            )

        tiled_tmem_load = tcgen05.make_tmem_copy(tmem_load_atom, tStSi)
        thr_tmem_load = tiled_tmem_load.get_slice(thread_idx)
        tTMEM_LOADtS = thr_tmem_load.partition_S(tStSi)
        tmem_store_vec_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(2)),
            self.qk_acc_dtype,
        )
        tiled_tmem_store_vec = tcgen05.make_tmem_copy(tmem_store_vec_atom, tStS_vec)
        thr_tmem_store_vec = tiled_tmem_store_vec.get_slice(thread_idx)
        tTMEM_STORE_VECtS = thr_tmem_store_vec.partition_D(tStS_vec)
        tTMEM_STORE_VECcS = thr_tmem_store_vec.partition_S(tScS_vec)
        tTMEM_STORE_SKIP_SOFTMAX = thr_tmem_store_vec.partition_D(tStS_skip_softmax)
        tmem_store_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(32)),
            self.qk_acc_dtype,
        )
        tiled_tmem_store = tcgen05.make_tmem_copy(tmem_store_atom, tStS_P)
        thr_tmem_store = tiled_tmem_store.get_slice(thread_idx)
        tTMEM_STOREtS_x4 = thr_tmem_store.partition_D(tStS_P)
        if cutlass.const_expr(self.enable_sequence_barrier):
            if cutlass.const_expr(stage == 1):
                self.sequence_s0_s1_barrier.arrive()
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
                logical_offset = (
                    curr_block_coord[0] * self.cta_tiler[0]
                    + stage * self.qk_mma_tiler[0],
                    0,
                )
                cS = cute.domain_offset(logical_offset, cS_base)
                value_args_ = (
                    seqlen_k_,
                    seqlen_q_,
                    scale_softmax_log2,
                    window_size_left,
                    window_size_right,
                    skip_softmax_threshold_log2,
                    thread_idx,
                    logical_offset,
                )
                atom_args = (
                    qk_thr_mma,
                    tiled_tmem_load,
                    tiled_tmem_store,
                    tiled_tmem_store_vec,
                    thr_tmem_load,
                    thr_tmem_store,
                    thr_tmem_store_vec,
                )
                tensor_args_ = (
                    tTMEM_LOADtS,
                    tTMEM_STORE_VECtS,
                    tTMEM_STORE_SKIP_SOFTMAX,
                    tTMEM_STOREtS_x4,
                    warp_wants_skip_softmax_exchange,
                    skip_softmax_count,
                    total_softmax_count,
                )
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
                if cutlass.const_expr(stage == 1):
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
                if cutlass.const_expr(stage == 0):
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
        """Rescale intermediate attention results based on softmax normalization factor.

        This method performs a crucial correction step in the attention computation pipeline.
        When processing attention in blocks, the softmax normalization factors may change
        as new blocks are processed. This method rescales previously computed partial
        output values to account for updated normalization factors.

        The implementation uses efficient tensor memory operations to:
        1. Load existing partial attention output from tensor memory
        2. Apply the scaling factor to all elements
        3. Store the rescaled results back to tensor memory

        When ``self.enable_correction_double_buffer`` is True, the rescale loop
        runs as a 2-buffer pipeline.

        :param thr_mma: Thread MMA operation for the computation
        :type thr_mma: cute.ThrMma
        :param tiled_tmem_load_vec: Tiled memory load operation for the vectorized row-wise max
        :type tiled_tmem_load_vec: cute.TiledCopy
        :param scale_softmax_log2: Log2 of the softmax factor
        :type scale_softmax_log2: Float32
        :param tensor_args: Tuple containing the tensors for the correction
        :type tensor_args: Tuple[cute.Tensor, cute.Tensor, cute.Tensor]
        :param pipeline_args: Tuple containing the pipeline arguments for the correction
        :type pipeline_args: Tuple[pipeline.PipelineConsumer, pipeline.PipelineConsumer]
        :param oi_peek_status: Optional non-blocking token for the Oi consumer
            wait. ``None`` or ``False`` falls back to a blocking wait.
        :return: ``((si_corr_consumer, mma_corr_consumer), next_oi_peek_status)``
            where ``next_oi_peek_status`` is the peek for the next Oi (only
            refreshed when a rescale actually ran; otherwise stays
            ``cutlass.Boolean(False)``).
        """
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
            # Rank-matching views for cute.copy (TMEM partitions are rank-3,
            # raw tTMrO[None, idx] is rank-1; composition restores the rank).
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
            scale_ = scale_softmax_log2 * (tTMEM_LOAD_VECrS[0] - tTMEM_LOAD_VECrS[1])
            scale = cute.math.exp2(scale_, fastmath=True)
            if cutlass.const_expr(self.enable_correction_double_buffer):
                num_elems = cute.size(tTMrO, mode=[0])
                # Prologue: load first tile into buffer 0
                cute.copy(tiled_tmem_load, tTMEM_LOADtO, tTMrO_copy[0])
                # Steady state. Refresh the next Oi probe near the end of the
                # current rescale pipeline.
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
                        tTMrO[j, (i - 1) % 2], tTMrO[j + 1, (i - 1) % 2] = (
                            cute.arch.mul_packed_f32x2(
                                (
                                    tTMrO[j, (i - 1) % 2],
                                    tTMrO[j + 1, (i - 1) % 2],
                                ),
                                (scale, scale),
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
                # Epilogue: compute and store last tile
                last = (num_tiles - 1) % 2
                for j in range(0, num_elems, 2):
                    tTMrO[j, last], tTMrO[j + 1, last] = cute.arch.mul_packed_f32x2(
                        (tTMrO[j, last], tTMrO[j + 1, last]),
                        (scale, scale),
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
                        tTMrO_i[j], tTMrO_i[j + 1] = cute.arch.mul_packed_f32x2(
                            (tTMrO_i[j], tTMrO_i[j + 1]),
                            (scale, scale),
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

    @cute.jit
    def correction_epilog(
        self,
        thr_mma: cute.ThrMma,
        tiled_tmem_load_vec: cute.TiledCopy,
        tensor_args: Tuple,
        pipeline_args: Tuple,
        value_args: Tuple,
    ):
        """Apply final scaling and transformation to attention output.

        When use_tma_store=True: writes to shared memory and signals epilogue warp for TMA store.
        When use_tma_store=False: writes directly to global memory via st.global.

        :param thr_mma: Thread MMA operation for the computation
        :type thr_mma: cute.ThrMma
        :param tiled_tmem_load_vec: Tiled memory load operation for the vectorized row-wise max
        :type tiled_tmem_load_vec: cute.TiledCopy
        :param tensor_args: Tuple containing (tOtO, tTMEM_LOAD_VECtSi, tTMEM_LOAD_VECcS, sO_or_gO, mLSE, mSink)
        :type tensor_args: Tuple
        :param pipeline_args: When use_tma_store: (si_corr_consumer, mma_corr_consumer, corr_epi_producer).
                              When not use_tma_store: (si_corr_consumer, mma_corr_consumer).
        :type pipeline_args: Tuple
        :param value_args: Tuple containing (row_idx, cuseqlen_q, seqlen_q, blk_coord, scale_softmax, scale_output)
        :type value_args: Tuple
        """
        tOtO, tTMEM_LOAD_VECtSi, tTMEM_LOAD_VECcS, dest_O, mLSE, mSink = tensor_args
        row_idx, cuseqlen_q, seqlen_q, blk_coord, scale_softmax, scale_output = (
            value_args
        )

        pv_tiled_mma_shape = (
            self.pv_mma_tiler[0],
            self.pv_mma_tiler[1],
        )
        cO = cute.make_identity_tensor(pv_tiled_mma_shape)

        corr_tile_size = 32 * 8 // self.o_dtype.width
        tOdO = thr_mma.partition_C(dest_O)
        tOcO = thr_mma.partition_C(cO)
        tOtO_i = cute.logical_divide(tOtO, cute.make_layout((128, corr_tile_size)))
        tOcO_i = cute.logical_divide(tOcO, cute.make_layout((128, corr_tile_size)))
        tOdO_i = cute.logical_divide(tOdO, cute.make_layout((128, corr_tile_size)))

        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (self.threads_per_warp * len(self.correction_warp_ids))
        epi_subtile = (self.epi_tile[0], corr_tile_size)
        tmem_copy_atom = sm100_utils.get_tmem_load_op(
            self.pv_mma_tiler,
            self.o_layout,
            self.o_dtype,
            self.pv_acc_dtype,
            epi_subtile,
            use_2cta_instrs=False,
        )
        tiled_tmem_load = tcgen05.make_tmem_copy(
            tmem_copy_atom, tOtO_i[(None, None), 0]
        )
        thr_tmem_load = tiled_tmem_load.get_slice(thread_idx)
        tTMEM_LOADtO = thr_tmem_load.partition_S(tOtO_i[(None, None), None])
        tTMEM_LOADdO = thr_tmem_load.partition_D(tOdO_i[(None, None), None])
        tTMEM_LOADoO = thr_tmem_load.partition_D(tOcO_i[(None, None), None])

        if cutlass.const_expr(self.use_tma_store):
            si_corr_consumer, mma_corr_consumer, corr_epi_producer = pipeline_args
            smem_copy_atom = sm100_utils.get_smem_store_op(
                self.o_layout, self.o_dtype, self.pv_acc_dtype, tiled_tmem_load
            )
            tiled_smem_store = cute.make_tiled_copy_D(smem_copy_atom, tiled_tmem_load)
        else:
            si_corr_consumer, mma_corr_consumer = pipeline_args

        # Wait for vec_i (row_wise global sum)
        vec_i_handle = si_corr_consumer.wait_and_advance()
        tTMEM_LOAD_VECrS = cute.make_rmem_tensor(
            tTMEM_LOAD_VECcS.shape, self.qk_acc_dtype
        )
        cute.copy(tiled_tmem_load_vec, tTMEM_LOAD_VECtSi, tTMEM_LOAD_VECrS)
        cute.arch.fence_view_async_tmem_load()
        vec_i_handle.release()

        # Wait for Oi
        oi_handle = mma_corr_consumer.wait_and_advance()
        if cutlass.const_expr(self.use_tma_store):
            oi_final_handle = corr_epi_producer.acquire_and_advance()
        row_sum = tTMEM_LOAD_VECrS[0]
        if cutlass.const_expr(mSink is not None):
            sink_val = mSink[blk_coord[2]]
            row_max_raw = tTMEM_LOAD_VECrS[1]
            # sink is already in scaled logit space, row_max_raw is unscaled
            # exp2((sink - max_scaled) * log2(e)) = exp(sink - max_scaled)
            log2_e = Float32(1.4426950408889634)
            sink_exp = cute.math.exp2(
                (sink_val - row_max_raw * scale_softmax) * log2_e, fastmath=True
            )
            row_sum = row_sum + sink_exp
        scale = scale_output / row_sum

        for i in range(self.cta_tiler[2] // corr_tile_size):
            tTMEM_LOADtO_i = tTMEM_LOADtO[None, 0, 0, i]
            tTMEM_LOADdO_i = tTMEM_LOADdO[None, 0, 0, i]
            tTMrO = cute.make_rmem_tensor(
                tTMEM_LOADoO[None, 0, 0, i].shape, self.pv_acc_dtype
            )
            cute.copy(tiled_tmem_load, tTMEM_LOADtO_i, tTMrO)
            for j in range(0, cute.size(tTMrO), 2):
                tTMrO[j], tTMrO[j + 1] = cute.arch.mul_packed_f32x2(
                    (tTMrO[j], tTMrO[j + 1]),
                    (scale, scale),
                )
            tDMrO = cute.make_rmem_tensor(tTMrO.shape, self.o_dtype)
            o_vec = tTMrO.load()
            tDMrO.store(o_vec.to(self.o_dtype))
            if cutlass.const_expr(self.use_tma_store):
                # TMA store path: write to shared memory
                cute.copy(tiled_smem_store, tDMrO, tTMEM_LOADdO_i)
            else:
                # st.global path: write directly to global memory with bounds check
                if row_idx < seqlen_q:
                    cute.autovec_copy(tDMrO, tTMEM_LOADdO_i)

        if cutlass.const_expr(mLSE is not None):
            scaled_tmp = scale_softmax * tTMEM_LOAD_VECrS[1]
            # Convert LSE from natural log to log2 space, consistent with flashinfer backend
            lse = (cute.math.log(row_sum, fastmath=True) + scaled_tmp) * Float32(
                1.4426950408889634
            )
            # Pre-scale correction: row_sum was inflated by 2^offset, so the
            # log2-space LSE is too large by exactly `p_fp8_prescale_log2`.
            if cutlass.const_expr(
                self.v_dtype.width == 8 and self.p_fp8_prescale_log2 > 0
            ):
                lse = lse - self.p_fp8_prescale_log2
            if row_idx < seqlen_q:
                mLSE[row_idx + cuseqlen_q, blk_coord[2]] = lse
        if cutlass.const_expr(self.use_tma_store):
            # fence view async shared
            cute.arch.fence_view_async_shared()
            oi_handle.release()
            oi_final_handle.commit()
            return (si_corr_consumer, mma_corr_consumer, corr_epi_producer)
        else:
            oi_handle.release()
            return (si_corr_consumer, mma_corr_consumer)

    def check_supported_dtypes(
        self,
        qk_dtype: Type[cutlass.Numeric],
        pv_dtype: Type[cutlass.Numeric],
        out_dtype: Type[cutlass.Numeric],
        qk_acc_dtype: Type[cutlass.Numeric],
        pv_acc_dtype: Type[cutlass.Numeric],
    ):
        supported = {cutlass.Float8E4M3FN, cutlass.Float16, cutlass.BFloat16}
        if qk_dtype not in supported:
            raise testing.CantImplementError("Unsupported qk_dtype")
        if pv_dtype not in supported:
            raise testing.CantImplementError("Unsupported pv_dtype")
        if out_dtype not in {cutlass.Float8E4M3FN, cutlass.Float16, cutlass.BFloat16}:
            raise testing.CantImplementError("Unsupported out_dtype")
        if qk_acc_dtype not in {cutlass.Float32}:
            raise testing.CantImplementError("Unsupported qk_acc_dtype")
        if pv_acc_dtype not in {cutlass.Float32}:
            raise testing.CantImplementError("Unsupported pv_acc_dtype")

    def check_invalid_shape(
        self,
        qk_dtype: Type[cutlass.Numeric],
        q_shape: Tuple[int, int, int, int],
        k_shape: Tuple[int, int, int, int],
    ):
        # Shapes are passed around this example as (batch, seq_len, num_heads, head_dim).
        b, s_q, h_q, d = q_shape
        b_, s_k, h_k, d_ = k_shape

        if b != b_:
            raise testing.CantImplementError("q & k must have the same batch size")
        if d != d_:
            raise testing.CantImplementError("q & k must have the same head dimension")
        if d not in {32, 64, 128, 192}:
            raise testing.CantImplementError("Unsupported head dimension")
        if h_q % h_k != 0:
            raise testing.CantImplementError("h_q must be divisible by h_k")
        if isinstance(s_q, tuple) and len(s_q) != b:
            raise testing.CantImplementError(
                "variable_seqlen s_q must have the length of batch size"
            )
        if isinstance(s_k, tuple) and len(s_k) != b:
            raise testing.CantImplementError(
                "variable_seqlen s_k must have the length of batch size"
            )
        if d == 192 and qk_dtype not in {cutlass.Float8E4M3FN}:
            raise testing.CantImplementError("unimplemented dtypes for headdim 192")

    def can_implement(
        self,
        q_shape: Tuple[int, int, int, int],
        k_shape: Tuple[int, int, int, int],
        qk_dtype: Type[cutlass.Numeric],
        pv_dtype: Type[cutlass.Numeric],
        out_dtype: Type[cutlass.Numeric],
        qk_acc_dtype: Type[cutlass.Numeric],
        pv_acc_dtype: Type[cutlass.Numeric],
    ) -> bool:
        """
        :param q_shape: Shape of the query tensor.
        :type q_shape: Tuple[int, int, int, int]
        :param k_shape: Shape of the key tensor.
        :type k_shape: Tuple[int, int, int, int]
        :param qk_dtype: Data type for Q and K (Bmm1 inputs).
        :type qk_dtype: Type[cutlass.Numeric]
        :param pv_dtype: Data type for P and V (Bmm2 inputs).
        :type pv_dtype: Type[cutlass.Numeric]
        :param out_dtype: Data type of the output tensor.
        :type out_dtype: Type[cutlass.Numeric]
        :param qk_acc_dtype: Data type of the qk accumulator tensor.
        :type qk_acc_dtype: Type[cutlass.Numeric]
        :param pv_acc_dtype: Data type of the pv accumulator tensor.
        :type pv_acc_dtype: Type[cutlass.Numeric]
        :return: True if the kernel can be implemented, False otherwise.
        :rtype: bool
        """
        try:
            # Skip unsupported types
            self.check_supported_dtypes(
                qk_dtype,
                pv_dtype,
                out_dtype,
                qk_acc_dtype,
                pv_acc_dtype,
            )
            # Skip invalid shape
            self.check_invalid_shape(
                qk_dtype,
                q_shape,
                k_shape,
            )
        except testing.CantImplementError:
            return False
        return True


def run(
    q_shape: Union[Tuple[int, int, int, int], Tuple[int, Tuple[int, ...], int, int]],
    k_shape: Union[Tuple[int, int, int, int], Tuple[int, Tuple[int, ...], int, int]],
    qk_dtype: Type[cutlass.Numeric],
    pv_dtype: Type[cutlass.Numeric],
    out_dtype: Type[cutlass.Numeric],
    qk_acc_dtype: Type[cutlass.Numeric],
    pv_acc_dtype: Type[cutlass.Numeric],
    mma_tiler_mn: Tuple[int, int],
    enable_ex2_emulation: bool,
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
    skip_softmax_threshold: float,
    tolerance: float,
    warmup_iterations: int,
    iterations: int,
    skip_ref_check: bool,
    use_cold_l2: bool = False,
    stats_skip_softmax_ratio: bool = False,
    enable_sink: bool = False,
    use_pdl: bool = False,
    fmha_class: Optional[Type["BlackwellFusedMultiHeadAttentionForward"]] = None,
    **kwargs,
):
    """Execute Fused Multi-Head Attention (FMHA) on Blackwell architecture and validate results.

    This function creates random input tensors for query, key, and value, then performs the
    complete FMHA computation pipeline. It supports configurable data types, tiling parameters,
    and various attention masking options. Results can be validated against a PyTorch reference
    implementation or run multiple times for performance measurement.

    The implementation leverages specialized tensor memory operations and efficient math
    operations optimized for Blackwell architecture, including pipelined computation stages
    for maximum throughput.

    :param q_shape: Query tensor shape (B, S_q, H, D) where B=batch size, S_q=query sequence length,
                    H=number of heads, D=head dimension.
                    If S_q is a tuple, it is the variable sequence length.
    :type q_shape: Union[Tuple[int, int, int, int], Tuple[int, Tuple[int, ...], int, int]]
    :param k_shape: Key tensor shape (B, S_k, H_k, D) where B=batch size, S_k=key sequence length,
                    H_k=number of key heads (H must be divisible by H_k), D=head dimension.
                    If S_k is a tuple, it is the variable sequence length.
    :type k_shape: Union[Tuple[int, int, int, int], Tuple[int, Tuple[int, ...], int, int]]
    :param qk_dtype: Input data type for Q and K tensors (Bmm1)
    :type qk_dtype: Type[cutlass.Numeric]
    :param pv_dtype: Input data type for P and V tensors (Bmm2)
    :type pv_dtype: Type[cutlass.Numeric]
    :param out_dtype: Output data type for attention output
    :type out_dtype: Type[cutlass.Numeric]
    :param qk_acc_dtype: Accumulator data type for query-key matrix multiplication
    :type qk_acc_dtype: Type[cutlass.Numeric]
    :param pv_acc_dtype: Accumulator data type for probability-value matrix multiplication
    :type pv_acc_dtype: Type[cutlass.Numeric]
    :param mma_tiler_mn: Matrix multiply accumulate tile shape (M, N)
    :type mma_tiler_mn: Tuple[int, int]
    :param enable_ex2_emulation: Whether to enable ex2 emulation
    :type enable_ex2_emulation: bool
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
    :param stats_skip_softmax_ratio: Whether to calculate the ratio of skipped softmax tiles
    :type stats_skip_softmax_ratio: bool
    :raises ValueError: If input shapes are incompatible or head dimension is unsupported
    :raises RuntimeError: If GPU is unavailable for computation
    :return: Execution time of the FMHA kernel in microseconds
    :rtype: float
    """

    if fmha_class is None:
        fmha_class = BlackwellFusedMultiHeadAttentionForward
    print(f"Running {fmha_class.arch_name} FMHA test with:")
    print(f"  q_shape: {q_shape}")
    print(f"  k_shape: {k_shape}")
    print(f"  qk_dtype: {qk_dtype}")
    print(f"  pv_dtype: {pv_dtype}")
    print(f"  out_dtype: {out_dtype}")
    print(f"  qk_acc_dtype: {qk_acc_dtype}")
    print(f"  pv_acc_dtype: {pv_acc_dtype}")
    print(f"  mma_tiler_mn: {mma_tiler_mn}")
    print(f"  enable_ex2_emulation: {enable_ex2_emulation}")
    print(f"  enable_skip_correction: {enable_skip_correction}")
    print(f"  is_persistent: {is_persistent}")
    print(f"  is_causal: {is_causal}")
    print(f"  bottom_right_align: {bottom_right_align}")
    print(f"  lse_calculation: {lse_calculation}")
    print(f"  enable_sink: {enable_sink}")
    print(f"  window_size: {window_size}")
    print(f"  scale_q: {scale_q}")
    print(f"  scale_k: {scale_k}")
    print(f"  scale_v: {scale_v}")
    print(f"  inv_scale_o: {inv_scale_o}")
    print(f"  scale_softmax: {scale_softmax}")
    print(f"  skip_softmax_threshold: {skip_softmax_threshold}")
    print(f"  tolerance: {tolerance}")
    print(f"  warmup_iterations: {warmup_iterations}")
    print(f"  iterations: {iterations}")
    print(f"  skip_ref_check: {skip_ref_check}")
    print(f"  use_cold_l2: {use_cold_l2}")
    print(f"  stats_skip_softmax_ratio: {stats_skip_softmax_ratio}")
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

    h_r = h_q // h_k
    dv = d if d != 192 else 128

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

    def create_and_permute_tensor(
        shape,
        dtype,
        is_dynamic_layout=True,
        use_random_int=True,
        zero_out=False,
    ):
        # Random int initialization can ensure the refcheck is stable
        # via different problem shapes & random seeds.
        # However, gaussian initialization can ensure the performance measurement is
        # close to the production environment.
        if use_random_int:
            init_type = cutlass_torch.TensorInitType.RANDOM
            init_config = cutlass_torch.RandomInitConfig(
                min_val=-2 if dtype.is_float or dtype.signed else 0, max_val=2
            )
        else:
            init_type = cutlass_torch.TensorInitType.GAUSSIAN
            init_config = cutlass_torch.GaussianInitConfig(mean=0, std=1, scale=1)

        if zero_out:
            f32_torch_tensor = torch.zeros(*shape, dtype=torch.float32)
        else:
            # Create f32 torch tensor (cpu)
            f32_torch_tensor = cutlass_torch.create_and_permute_torch_tensor(
                shape,
                torch.float32,
                permute_order=None,
                init_type=init_type,
                init_config=init_config,
            )
        storage_dtype = (
            torch.uint8 if utils.is_fp8_dtype(dtype) else cutlass_torch.dtype(dtype)
        )
        torch_tensor = f32_torch_tensor.to(dtype=storage_dtype, device="cuda")
        cute_tensor, torch_tensor = cutlass_torch.cute_tensor_like(
            f32_torch_tensor,
            dtype,
            is_dynamic_layout,
            assumed_align=32,
        )
        f32_torch_tensor_gpu = f32_torch_tensor.cuda()
        cute.testing.convert(
            cute_tensor, from_dlpack(f32_torch_tensor_gpu, assumed_align=32)
        )
        f32_torch_tensor = f32_torch_tensor_gpu.cpu()

        return (
            f32_torch_tensor,
            cute_tensor,
            torch_tensor,
        )

    # Tensor shapes: 5D for q/k/v/o, 4D for lse
    # q/o: (b, s_q, h_k, h_r, d/dv)
    # k/v: (b, s_k, h_k, 1, d/dv)
    # lse: (b, h_k, h_r, s_q)
    qo_shape = (b, s_q, h_k, h_r, d)
    o_shape = (b, s_q, h_k, h_r, dv)
    kv_shape = (b, s_k, h_k, 1, d)
    v_shape = (b, s_k, h_k, 1, dv)
    lse_shape = (b, s_q, h_k, h_r)

    if isinstance(s_q, tuple):
        qo_shape = (1, sum(s_q), h_k, h_r, d)
        o_shape = (1, sum(s_q), h_k, h_r, dv)
        lse_shape = (1, sum(s_q), h_k, h_r)

    if isinstance(s_k, tuple):
        kv_shape = (1, sum(s_k), h_k, 1, d)
        v_shape = (1, sum(s_k), h_k, 1, dv)

    # Create tensors with random int initialization if not skip ref check
    # to ensure the refcheck is stable via different problem shapes & random seeds.
    # for skip softmax, we use gaussian initialization to ensure the results are
    # close to the production environment.
    use_random = not skip_ref_check and (
        skip_softmax_threshold is None or skip_softmax_threshold <= 0
    )
    q_ref, q_tensor, q_torch = create_and_permute_tensor(
        qo_shape,
        qk_dtype,
        is_dynamic_layout=True,
        use_random_int=use_random,
    )
    k_ref, k_tensor, k_torch = create_and_permute_tensor(
        kv_shape,
        qk_dtype,
        is_dynamic_layout=True,
        use_random_int=use_random,
    )
    v_ref, v_tensor, v_torch = create_and_permute_tensor(
        v_shape,
        pv_dtype,
        is_dynamic_layout=True,
        use_random_int=use_random,
    )
    _, o_tensor, o_torch = create_and_permute_tensor(
        o_shape,
        out_dtype,
        is_dynamic_layout=True,
        zero_out=True,
    )
    if lse_calculation:
        _, lse_tensor, lse_torch = create_and_permute_tensor(
            lse_shape,
            cutlass.Float32,
            is_dynamic_layout=True,
            zero_out=True,
        )
    else:
        lse_tensor = None
        lse_torch = None

    if enable_sink:
        sink_shape = (h_q,)
        sink_ref, sink_tensor, sink_torch = create_and_permute_tensor(
            sink_shape,
            cutlass.Float32,
            is_dynamic_layout=True,
            use_random_int=use_random,
        )
    else:
        sink_ref = None
        sink_tensor = None
        sink_torch = None

    mask_type = fmha_utils.MaskEnum.WINDOW_MASK
    if bottom_right_align:
        mask_type = fmha_utils.MaskEnum.WINDOW_MASK_INFERENCE
    if is_causal:
        window_size_right = 0
    elif window_size_left is None and window_size_right is None:
        if isinstance(s_k, tuple):
            # For variable length input, we always use residual mask
            # as we don't know the sequence length in advance.
            mask_type = fmha_utils.MaskEnum.RESIDUAL_MASK
        else:
            if s_k % mma_tiler_mn[1] != 0:
                mask_type = fmha_utils.MaskEnum.RESIDUAL_MASK

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

    fmha = fmha_class(
        qk_acc_dtype,
        pv_acc_dtype,
        mma_tiler_mn,
        d if d == dv else (d, dv),
        is_persistent,
        mask_type,
        enable_ex2_emulation,
        enable_skip_correction,
        use_tma_store=False if isinstance(s_q, tuple) else True,
    )

    can_implement = fmha.can_implement(
        q_shape,
        k_shape,
        qk_dtype,
        pv_dtype,
        out_dtype,
        qk_acc_dtype,
        pv_acc_dtype,
    )

    if not can_implement:
        raise testing.CantImplementError(
            f"The current config which is invalid/unsupported: "
            f"q_shape = {q_shape}, k_shape = {k_shape}, qk_dtype = {qk_dtype}, pv_dtype = {pv_dtype}, "
            f"out_dtype = {out_dtype}, qk_acc_dtype = {qk_acc_dtype}, pv_acc_dtype = {pv_acc_dtype}"
        )

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

    skip_softmax_threshold_log2 = None
    if skip_softmax_threshold is not None and skip_softmax_threshold > 0:
        skip_softmax_threshold_log2 = Float32(math.log2(skip_softmax_threshold))
    skip_softmax_count, total_softmax_count = None, None
    if stats_skip_softmax_ratio:
        skip_softmax_count_torch = torch.zeros(1, dtype=torch.int32).cuda()
        total_softmax_count_torch = torch.zeros(1, dtype=torch.int32).cuda()
        skip_softmax_count = from_dlpack(skip_softmax_count_torch)
        total_softmax_count = from_dlpack(total_softmax_count_torch)
    problem_size = (
        b,
        max(s_q) if isinstance(s_q, tuple) else s_q,
        sum(s_q) if isinstance(s_q, tuple) else s_q,  # s_lse
        max(s_k) if isinstance(s_k, tuple) else s_k,
        h_q,
        h_k,
        d,
        dv,
    )

    print("Compiling kernel with cute.compile ...")
    start_time = time.time()
    # compile fmha kernel
    compiled_fmha = cute.compile(
        fmha,
        q_tensor,
        k_tensor,
        v_tensor,
        o_tensor,
        problem_size,
        cum_seqlen_q,
        cum_seqlen_k,
        lse_tensor if lse_calculation else None,
        sink_tensor if enable_sink else None,
        scale_softmax_log2,
        scale_softmax,
        scale_output,
        skip_softmax_threshold_log2,
        window_size_left if window_size_left is None else Int32(window_size_left),
        window_size_right if window_size_right is None else Int32(window_size_right),
        skip_softmax_count,
        total_softmax_count,
        current_stream,
        use_pdl,
        options=f"--opt-level=2" if cutlass.__version__[0:3]=="4.6" else "",
    )
    compilation_time = time.time() - start_time
    print(f"Compilation time: {compilation_time:.4f} seconds")

    def run_torch_fmha(
        problem_size,
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
        skip_softmax_threshold_log2=None,
        cum_seqlen_q=None,
        cum_seqlen_k=None,
        sink_ref=None,
    ):
        # q: (b, s_q, h_k, h_r, d), k: (b, s_k, h_k, 1, d), v: (b, s_k, h_k, 1, dv)
        batch, s_q_max, s_lse_max, s_k_max, h_q, h_k, d, dv = problem_size
        h_r = h_q // h_k

        ref_o_shape = list(q.shape[:-1]) + [v.shape[-1]]  # same as q but with dv
        ref_o = torch.zeros(ref_o_shape)
        ref_lse = None
        if lse_calculation:
            ref_lse = torch.zeros(list(lse_shape))

        for batch_idx in range(batch):
            b_idx_q = batch_idx if cum_seqlen_q is None else 0
            b_idx_k = batch_idx if cum_seqlen_k is None else 0
            q_offset = cum_seqlen_q[batch_idx].item() if cum_seqlen_q is not None else 0
            k_offset = cum_seqlen_k[batch_idx].item() if cum_seqlen_k is not None else 0
            cur_s_q = (
                (cum_seqlen_q[batch_idx + 1] - cum_seqlen_q[batch_idx]).item()
                if cum_seqlen_q is not None
                else s_q_max
            )
            cur_s_k = (
                (cum_seqlen_k[batch_idx + 1] - cum_seqlen_k[batch_idx]).item()
                if cum_seqlen_k is not None
                else s_k_max
            )

            # Slice per-batch data: (s, h_k, h_r, d)
            cur_q = q[b_idx_q, q_offset : q_offset + cur_s_q, :, :, :]
            cur_k = k[b_idx_k, k_offset : k_offset + cur_s_k, :, :, :]
            cur_v = v[b_idx_k, k_offset : k_offset + cur_s_k, :, :, :]

            # Expand k/v h_r dimension if GQA
            if h_q != h_k:
                repeat_factor = h_q // h_k
                cur_k = cur_k.repeat(1, 1, repeat_factor, 1)
                cur_v = cur_v.repeat(1, 1, repeat_factor, 1)

            # cur_q: (s_q, h_k, h_r, d), cur_k: (s_k, h_k, h_r, d)
            cur_s = torch.einsum("qhld,khld->qkhl", cur_q, cur_k) * scale_softmax

            if is_causal:
                window_size_right = 0
            if window_size_left is not None or window_size_right is not None:
                q_coords = torch.arange(0, cur_s_q).cuda().view(-1, 1)
                k_coords = torch.arange(0, cur_s_k).cuda().view(1, -1)
                offset = 0 if not bottom_right_align else cur_s_k - cur_s_q
                if window_size_left is None:
                    _mask = k_coords > q_coords + offset + window_size_right
                elif window_size_right is None:
                    _mask = k_coords < q_coords + offset - window_size_left
                else:
                    _mask = (k_coords > q_coords + offset + window_size_right) | (
                        k_coords < q_coords + offset - window_size_left
                    )
                cur_s = cur_s.masked_fill(
                    _mask.cpu().unsqueeze(-1).unsqueeze(-1), -torch.inf
                )

            if skip_softmax_threshold_log2 is not None:
                br, bc = mma_tiler_mn[0], mma_tiler_mn[1]
                num_block_rows = (cur_s_q + br - 1) // br
                num_block_cols = (cur_s_k + bc - 1) // bc
                padded_s_q = num_block_rows * br
                padded_s_k = num_block_cols * bc
                # cur_s: (s_q, s_k, h_k, h_r) -> permute to (h_k, h_r, s_q, s_k) for blocking
                cur_s_perm = cur_s.permute(2, 3, 0, 1) * log2_e
                padded_s_i = torch.nn.functional.pad(
                    cur_s_perm,
                    (0, padded_s_k - cur_s_k, 0, padded_s_q - cur_s_q),
                    value=float("-inf"),
                )
                blocked_s_i = padded_s_i.view(
                    h_k, h_r, num_block_rows, br, num_block_cols, bc
                )
                block_max = blocked_s_i.max(dim=-1).values
                block_max_cummax = block_max.cummax(dim=-1)[0]
                block_cur_max = torch.ones(
                    block_max.shape[:-1], device=block_max.device
                ).float() * float("-inf")
                for idx in itertools.product(*[range(x) for x in block_max.shape[:-2]]):
                    for i in range(block_max.shape[-1]):
                        block_max_cummax[idx + (slice(None), i)] = block_cur_max[
                            idx + (slice(None),)
                        ]
                        if (
                            (
                                block_max[idx + (slice(None), i)]
                                - block_cur_max[idx + (slice(None),)]
                                >= skip_softmax_threshold_log2.value
                            )
                            .any()
                            .bool()
                        ):
                            block_cur_max[idx + (slice(None),)] = torch.max(
                                block_cur_max[idx + (slice(None),)],
                                block_max[idx + (slice(None), i)],
                            )
                blocked_s_i = blocked_s_i - block_max_cummax[..., None]
                s_i_larger_than_thresh = (
                    blocked_s_i >= skip_softmax_threshold_log2.value
                )
                s_i_any_larger = s_i_larger_than_thresh.any(dim=-1, keepdim=True).any(
                    dim=-3, keepdim=True
                )
                padded_mask_s_i = (torch.ones_like(blocked_s_i) * s_i_any_larger).view(
                    h_k, h_r, padded_s_q, padded_s_k
                )
                # Back to (s_q, s_k, h_k, h_r)
                mask_s_i = padded_mask_s_i[:, :, :cur_s_q, :cur_s_k].permute(2, 3, 0, 1)
                cur_s = cur_s.masked_fill(mask_s_i == 0, float("-inf"))

            cur_lse = None
            if sink_ref is not None:
                # Concat sink as an extra logit, then softmax - numerically stable
                # sink_ref shape: (h_q,) = (h_k * h_r,) -> (1, 1, h_k, h_r)
                # sink is already in the scaled logit space, no need to multiply scale_softmax
                cur_sink = sink_ref.reshape(h_k, h_r).unsqueeze(0).unsqueeze(0)
                # Broadcast to (s_q, 1, h_k, h_r) and concat along s_k dim
                cur_sink = cur_sink.expand(cur_s_q, -1, -1, -1)
                # cur_s: (s_q, s_k, h_k, h_r) -> (s_q, s_k+1, h_k, h_r)
                cur_s_with_sink = torch.cat([cur_s, cur_sink], dim=1)
                if lse_calculation:
                    cur_lse = (
                        torch.logsumexp(cur_s_with_sink, dim=1) * 1.4426950408889634
                    )
                cur_p = torch.softmax(cur_s_with_sink, dim=1)[:, :cur_s_k, :, :]
            else:
                if lse_calculation:
                    # Use log2 space for LSE, consistent with flashinfer backend
                    cur_lse = (
                        torch.logsumexp(cur_s, dim=1) * 1.4426950408889634
                    )  # reduce over s_k
                cur_p = torch.softmax(cur_s, dim=1)  # softmax over s_k

            # (s_q, s_k, h_k, h_r) x (s_k, h_k, h_r, dv) -> (s_q, h_k, h_r, dv)
            cur_o = torch.einsum("qkhl,khld->qhld", cur_p, cur_v) * scale_output

            ref_o[b_idx_q, q_offset : q_offset + cur_s_q, :, :, :] = cur_o
            if lse_calculation:
                # cur_lse: (s_q, h_k, h_r)
                ref_lse[b_idx_q, q_offset : q_offset + cur_s_q, :, :] = cur_lse

        return ref_o, ref_lse

    compiled_fmha(
        q_tensor,
        k_tensor,
        v_tensor,
        o_tensor,
        problem_size,
        cum_seqlen_q,
        cum_seqlen_k,
        lse_tensor if lse_calculation else None,
        sink_tensor if enable_sink else None,
        scale_softmax_log2,
        scale_softmax,
        scale_output,
        skip_softmax_threshold_log2,
        window_size_left if window_size_left is None else Int32(window_size_left),
        window_size_right if window_size_right is None else Int32(window_size_right),
        skip_softmax_count,
        total_softmax_count,
        current_stream,
        use_pdl,
    )
    if stats_skip_softmax_ratio:
        print(
            f"Skip softmax ratio: {skip_softmax_count_torch.cpu()[0]}/{total_softmax_count_torch.cpu()[0]}={skip_softmax_count_torch.cpu()[0] / total_softmax_count_torch.cpu()[0]}"
        )
    if not skip_ref_check:
        # Execute kernel once for reference checking
        print("Verifying results...")
        cum_seqlen_q_list = None
        cum_seqlen_k_list = None
        if cum_seqlen_q_torch is not None:
            cum_seqlen_q_list = cum_seqlen_q_torch.cpu()
        if cum_seqlen_k_torch is not None:
            cum_seqlen_k_list = cum_seqlen_k_torch.cpu()

        o_ref, lse_ref = run_torch_fmha(
            problem_size,
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
            skip_softmax_threshold_log2,
            cum_seqlen_q=cum_seqlen_q_list,
            cum_seqlen_k=cum_seqlen_k_list,
            sink_ref=sink_ref if enable_sink else None,
        )

        # convert o back to f32 for comparison
        o_fp32, o_fp32_torch = cutlass_torch.cute_tensor_like(
            torch.empty(*o_torch.shape, dtype=torch.float32),
            Float32,
            is_dynamic_layout=True,
            assumed_align=16,
        )
        cute.testing.convert(o_tensor, o_fp32)
        o_result = o_fp32_torch.cpu()

        if out_dtype.is_float and (out_dtype.width <= 8 or pv_dtype.width <= 8):
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
            if skip_softmax_threshold is None or skip_softmax_threshold <= 0:
                tolerance = 0.13
            else:
                tolerance = 0.25

        # Assert close results
        torch.testing.assert_close(o_result, o_ref, atol=tolerance, rtol=1e-05)
        if lse_calculation:
            torch.testing.assert_close(
                lse_torch.cpu(), lse_ref, atol=tolerance, rtol=1e-05
            )
        print("Results verified successfully!")

    def generate_tensors():
        _, q_tensor_workspace, _ = create_and_permute_tensor(
            qo_shape,
            qk_dtype,
            is_dynamic_layout=True,
            use_random_int=False,
        )
        _, k_tensor_workspace, _ = create_and_permute_tensor(
            kv_shape,
            qk_dtype,
            is_dynamic_layout=True,
            use_random_int=False,
        )
        _, v_tensor_workspace, _ = create_and_permute_tensor(
            v_shape,
            pv_dtype,
            is_dynamic_layout=True,
            use_random_int=False,
        )
        _, o_tensor_workspace, _ = create_and_permute_tensor(
            o_shape,
            out_dtype,
            is_dynamic_layout=True,
            zero_out=True,
        )
        if lse_calculation:
            _, lse_tensor, lse_torch = create_and_permute_tensor(
                lse_shape,
                cutlass.Float32,
                is_dynamic_layout=True,
                zero_out=True,
            )
        else:
            lse_tensor = None

        if enable_sink:
            _, sink_tensor_workspace, _ = create_and_permute_tensor(
                sink_shape,
                cutlass.Float32,
                is_dynamic_layout=True,
                use_random_int=False,
            )
        else:
            sink_tensor_workspace = None

        args = testing.JitArguments(
            q_tensor_workspace,
            k_tensor_workspace,
            v_tensor_workspace,
            o_tensor_workspace,
            problem_size,
            cum_seqlen_q,
            cum_seqlen_k,
            lse_tensor,
            sink_tensor_workspace if enable_sink else None,
            scale_softmax_log2,
            scale_softmax,
            scale_output,
            skip_softmax_threshold_log2,
            window_size_left if window_size_left is None else Int32(window_size_left),
            (
                window_size_right
                if window_size_right is None
                else Int32(window_size_right)
            ),
            skip_softmax_count,
            total_softmax_count,
            current_stream,
            use_pdl,
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
        q_torch_effective = q_torch
        k_torch_effective = k_torch
        v_torch_effective = v_torch
        o_torch_effective = o_torch
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
            else:
                raise argparse.ArgumentTypeError(
                    "Invalid format. Expected comma-separated integers with optional parentheses for nested tuple."
                )

    parser = argparse.ArgumentParser(description="Example of FMHA on Blackwell.")

    parser.add_argument(
        "--in_dtype",
        type=cutlass.dtype,
        default=cutlass.Float16,
        help="Input data type for Q, K, and V (overridden per-operand by --qk_dtype/--pv_dtype)",
    )

    parser.add_argument(
        "--qk_dtype",
        type=cutlass.dtype,
        default=None,
        help="Input data type for Q and K (Bmm1); defaults to --in_dtype if not set",
    )

    parser.add_argument(
        "--pv_dtype",
        type=cutlass.dtype,
        default=None,
        help="Input data type for P and V (Bmm2); defaults to --in_dtype if not set",
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
        "--enable_ex2_emulation",
        action="store_true",
        default=False,
        help="Enable ex2 emulation",
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
        help="Whether to use casual mask",
    )

    parser.add_argument(
        "--bottom_right_align",
        action="store_true",
        help="Whether to use bottom right align, under this settion, the end of q is aligned with the end of k.",
    )

    parser.add_argument(
        "--lse_calculation",
        action="store_true",
        help="Whether to calculate lse",
    )

    parser.add_argument(
        "--enable_sink",
        action="store_true",
        default=False,
        help="Enable sink token support, adding sink contribution to softmax denominator",
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
        default=(1, 256, 8, 128),
        help="Shape of Q (B, S_q, H, D)",
    )

    parser.add_argument(
        "--k_shape",
        type=parse_nested_comma_separated_ints,
        default=(1, 256, 8, 128),
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
        default=0.0,
        help="Scaling factor to scale S (i.e. Q*K); if zero, defaults to 1/sqrt(D)",
    )

    parser.add_argument(
        "--skip_softmax_threshold",
        type=float,
        default=None,
        help="Skip softmax and PV on a tile if e^(max(S tile) - old_max(S tile)) <= threshold",
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
        "--stats_skip_softmax_ratio",
        action="store_true",
        default=False,
        help="Stats skip softmax ratio, used to print the skip softmax ratio, used for debugging.",
    )

    parser.add_argument(
        "--use_pdl",
        action="store_true",
        default=False,
        help="Enable PDL (Programmatic Dependent Launch) for kernel launch",
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

    # --qk_dtype/--pv_dtype override --in_dtype per-operand when explicitly set
    qk_dtype = args.qk_dtype if args.qk_dtype is not None else args.in_dtype
    pv_dtype = args.pv_dtype if args.pv_dtype is not None else args.in_dtype

    run(
        args.q_shape,
        args.k_shape,
        qk_dtype,
        pv_dtype,
        args.out_dtype,
        args.qk_acc_dtype,
        args.pv_acc_dtype,
        args.mma_tiler_mn,
        args.enable_ex2_emulation,
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
        args.skip_softmax_threshold,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
        args.stats_skip_softmax_ratio,
        args.enable_sink,
        args.use_pdl,
    )

    print("PASS")
