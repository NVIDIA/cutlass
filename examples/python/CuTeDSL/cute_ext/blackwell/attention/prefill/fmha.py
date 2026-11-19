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

import argparse
import math
import os
import sys
import time
from typing import Callable, Type, Tuple, Union, Optional
from functools import partial

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute import experimental as cute_ext
from cutlass.cute.nvgpu import tcgen05
from cutlass.cute.nvgpu.common import OperandMajorMode
import cutlass.pipeline as pipeline
import cutlass.torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.cute.testing as testing
from cutlass.cute.runtime import from_dlpack
from cutlass.cute.typing import Int32, Float32
from cutlass import Arch
from cutlass.cutlass_dsl import BaseDSL

_CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
_CUTE_DSL_EXAMPLES_ROOT = os.path.abspath(os.path.join(_CURRENT_DIR, "../../../.."))
if (
    __name__ == "__main__"
    and os.path.isdir(os.path.join(_CUTE_DSL_EXAMPLES_ROOT, "helpers"))
    and _CUTE_DSL_EXAMPLES_ROOT not in sys.path
):
    sys.path.insert(0, _CUTE_DSL_EXAMPLES_ROOT)
from pathlib import Path

if __name__ == "__main__":
    # `helpers` sits at the examples/CuTeDSL root; running this file as a
    # script only puts its own directory on sys.path.
    cutedsl_dir = str(Path(__file__).resolve().parents[4])
    if cutedsl_dir not in sys.path:
        sys.path.insert(0, cutedsl_dir)

from helpers import fmha_helpers as fmha_utils
from cutlass.tensor_utils import LayoutEnum
from cutlass.memory import TmemAllocator

try:
    from .fmha_operand_layouts import FmhaOperandLayouts
    from .fmha_pipeline import SoftmaxPipes, make_fmha_pipeline
    from .fmha_spec import make_fmha_spec
except ImportError:
    from fmha_operand_layouts import FmhaOperandLayouts
    from fmha_pipeline import SoftmaxPipes, make_fmha_pipeline
    from fmha_spec import make_fmha_spec

"""
A fused multi-head attention (FMHA) example for the NVIDIA Blackwell SM100
architecture using the CuTe experimental APIs.

This file is the CuTe experimental counterpart of ``fmha.py`` (the CuTeDSL
baseline). It is the same warp-specialized persistent FMHA kernel (TMA +
Blackwell SM100 tensor cores, integrating Q*K^T, online softmax, and P*V
into a single kernel) but using the ``cutlass.cute.experimental`` APIs --
``@cute.jit`` / ``@cute.kernel``,
``cute_ext.tma_load`` / ``cute_ext.tma_store``, ``cute_ext.dot``,
``cute_ext.partition_and_copy``, and the ``cute_ext.*Pipeline`` classes
(see ``fmha_pipeline.py``) -- instead of their CuTeDSL equivalents.

This is the **fixed-seqlen-only** variant. Variable-length (ragged)
prefill is intentionally outside the scope of this example.

Key optimizations:

- Warp specialization for the load / MMA / softmax / correction / epilogue
  phases, with pipelines between them for overlap.
- Online softmax with per-row-max correction of the running PV partial.
- Optional sliding-window / causal / sink-token masking.
- LSE output for downstream backward / log-prob computation.

To run this example:

.. code-block:: bash

    python fmha.py                                                          \\
      --qk_acc_dtype Float32 --pv_acc_dtype Float32                         \\
      --mma_tiler_mn 128,128                                                \\
      --q_shape 4,1024,8,64 --k_shape 4,1024,8,64                           \\
      --is_persistent

To collect performance with NCU profiler, append
``--warmup_iterations 10 --iterations 10 --skip_ref_check`` and prefix
with ``ncu``.

Constraints for this example:

- Supported head dimensions: 32, 64, 128, and 192 (MLA: ``D=192, Dv=128``)
- Supported input dtypes: fp16, bf16, fp8
- Number of heads in Q must be divisible by number of heads in K
- ``mma_tiler_mn`` must be ``128,128``
- Batch size must be the same for Q, K, and V tensors
- Single-CTA only (``cluster_shape = (1, 1)``, ``CtaGroup.ONE``)
- For causal masking, use ``--is_causal``
- For persistent scheduling, use ``--is_persistent``

Tensor name legend (CuTe Hungarian style; the canonical reference is
``cutlass/media/docs/pythonDSL/cute_dsl_general/naming_conventions.rst``):

- ``sQ``, ``sK``, ``sV``, ``sO``: staged SMEM tiles.
- ``tStS`` / ``tStS0`` / ``tStS1``: TMEM QK score accumulators,
  ``S_i = Q_i @ K^T``, logical shape ``(MMA, M, N)``.
- ``tOtO0`` / ``tOtO1``: TMEM PV output accumulators, ``O_i = P_i @ V``,
  logical shape ``(MMA, M, Dv)``.
- ``tPtP0`` / ``tPtP1``: softmax probability tiles recast as PV-A operands,
  logical shape ``(MMA, M, N)``.
"""


# TODO: re-enable skip-softmax (skip_softmax_threshold,
# stats_skip_softmax_ratio, enable_skip_correction) once the TMEM
# skip-flag store/load path is ported and validated.
_SKIP_SOFTMAX_UNSUPPORTED_MSG = (
    "skip_softmax_threshold, stats_skip_softmax_ratio, and "
    "enable_skip_correction are temporarily unsupported in this FMHA example."
)


class BlackwellFusedMultiHeadAttentionForward:
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
    ):
        """Configure a Blackwell Fused Multi-Head Attention (FMHA) kernel.

        Sets compile-time options only; per-launch values (Q/K/V/O pointers,
        softmax scales, window sizes, ...) are passed to :meth:`__call__`.
        From ``mma_tiler`` + ``head_dim`` this also derives
        ``qk_mma_tiler = (M, N, D)`` and ``pv_mma_tiler = (M, Dv, N)``.

        :param qk_acc_dtype: Accumulator dtype for the Q @ K^T MMA.
        :type qk_acc_dtype: Type[cutlass.Numeric]
        :param pv_acc_dtype: Accumulator dtype for the P @ V MMA.
        :type pv_acc_dtype: Type[cutlass.Numeric]
        :param mma_tiler: ``(M, N)`` of one MMA tile (M == query tile rows,
            N == key tile cols == PV k-dim).
        :type mma_tiler: Tuple[int, int]
        :param head_dim: Head dim ``D``. Pass ``(D, Dv)`` for MLA
            (restricted to ``(192, 128)``); an ``int`` sets ``Dv = D``.
        :type head_dim: Union[int, Tuple[int, int]]
        :param is_persistent: Use a persistent tile scheduler.
        :type is_persistent: bool
        :param mask_type: Mask flavor (no mask / residual / causal /
            bottom-right causal); the sliding-window left/right arguments
            live on :meth:`__call__`.
        :type mask_type: fmha_utils.MaskEnum
        :param enable_ex2_emulation: Enable the exp2 software emulation
            path (not supported / zero-gain on ``sm_103+``).
        :type enable_ex2_emulation: bool
        :param enable_skip_correction: Public use is disabled in ``run()``,
            but the compile-time constant is retained to keep the disabled
            specialization aligned with the baseline kernel.
        :type enable_skip_correction: bool
        """

        if enable_skip_correction:
            raise NotImplementedError(_SKIP_SOFTMAX_UNSUPPORTED_MSG)

        self.spec = make_fmha_spec(
            qk_acc_dtype,
            pv_acc_dtype,
            mma_tiler,
            head_dim,
            is_persistent,
            mask_type,
            enable_ex2_emulation,
            enable_skip_correction,
        )
        self._setup_named_barriers()
        self.num_tmem_alloc_cols = cute.arch.get_max_tmem_alloc_cols("sm_100")
        self.arch = BaseDSL._get_dsl().get_arch_enum()

        if self.arch >= Arch.sm_103:
            assert self.spec.enable_ex2_emulation == False, (
                f"Don't enable exp2 emulation for {self.arch}, it doesn't help performance"
            )

    def _setup_named_barriers(self):
        spec = self.spec
        self.tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=2,
            num_threads=spec.threads_per_warp * len(spec.tmem_alloc_warp_ids),
        )
        self.sequence_s0_s1_barrier = pipeline.NamedBarrier(
            barrier_id=3,
            num_threads=spec.threads_per_warp * len(spec.softmax_warp_ids),
        )
        self.sequence_s1_s0_barrier = pipeline.NamedBarrier(
            barrier_id=4,
            num_threads=spec.threads_per_warp * len(spec.softmax_warp_ids),
        )
        self.s0_warpgroup_barrier = pipeline.NamedBarrier(
            barrier_id=5,
            num_threads=spec.threads_per_warp * len(spec.softmax0_warp_ids),
        )
        self.s1_warpgroup_barrier = pipeline.NamedBarrier(
            barrier_id=6,
            num_threads=spec.threads_per_warp * len(spec.softmax1_warp_ids),
        )
        self.tmem_dealloc_barrier = pipeline.NamedBarrier(
            barrier_id=7,
            num_threads=spec.threads_per_warp * len(spec.correction_warp_ids),
        )

    def _setup_attributes(self):
        """Set up configurations and parameters for the FMHA kernel operation.

        This method initializes and configures various attributes required for the
        execution of the fused multi-head attention kernel, mainly about the pipeline stages:

        - Sets up staging parameters for Q, K, V inputs and accumulator data
        - Configures pipeline stages for softmax, correction, and epilogue operations
        """

        self.spec = self.spec.with_dtypes(
            self.q_dtype, self.k_dtype, self.v_dtype, self.o_dtype
        )
        self.rescale_threshold = 8.0 if self.spec.enable_skip_correction else 0.0
        # FP8 P pre-scale: offset added to exp2 exponent so that P*2^offset fills
        # more of E4M3's [0, 448] range, improving quantization precision.
        self.p_fp8_prescale_log2 = max(
            0.0, math.floor(math.log2(448) - self.rescale_threshold)
        )
        # ln(2) * offset correction for LSE when pre-scale is active
        self.p_fp8_prescale_lse_correction = self.p_fp8_prescale_log2 * math.log(2)
        # For most cases, seq barrier is needed to help keep the pipeline stable
        # But sometimes, compiler will schedule the barrier at an unexpected place
        # if it hurts perf a lot, try to quickly fix it by disabling seq barrier
        self.enable_sequence_barrier = False
    @cute.jit
    def __call__(
        self,
        q_tensor: cute.Tensor,
        k_tensor: cute.Tensor,
        v_tensor: cute.Tensor,
        o_tensor: cute.Tensor,
        problem_size: Tuple[Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32],
        lse_tensor: Optional[cute.Tensor],
        sink_tensor: Optional[cute.Tensor],
        scale_softmax_log2: Float32,
        scale_softmax: Float32,
        scale_output: Float32,
        skip_softmax_threshold_log2: Optional[Float32],
        window_size_left: Optional[Int32],
        window_size_right: Optional[Int32],
        stream: cuda.CUstream,
        use_pdl: bool,
    ):
        """Host wrapper that shapes Q/K/V/O into the
        ``(s, d, ((h_r, h_k), b))`` layouts expected by :meth:`kernel`,
        computes the persistent-grid tile schedule, and launches the kernel.

        ``problem_size`` is ``(b, s_q, s_lse, s_k, h_q, h_k, d, dv)``;
        ``s_lse == s_q`` for the fixed-seqlen path. ``lse_tensor`` is
        optional; when provided, :meth:`correction_epilog` writes per-row
        ``log(row_sum) + scale_softmax * row_max`` into it.

        Raises :class:`TypeError` / :class:`RuntimeError` if the Q/K/V dtypes
        disagree or any layout is not in a supported format. See also
        :meth:`can_implement`, which encodes the same constraints without a
        compile.

        This wrapper is intentionally thin -- it does *not* build TMA
        atoms, TMA-partitioned gmem views, per-operand SMEM staging layouts,
        or the QK/PV ``TiledMma`` objects. Those are either implicit in
        ``cute_ext`` (TMA plumbing) or rebuilt inside :meth:`kernel` from
        ``self``-attributes.

        :param q_tensor: Query tensor, shape ``(b, s_q, h_k, h_r, d)``.
        :type q_tensor: cute.Tensor
        :param k_tensor: Key tensor, shape ``(b, s_k, h_k, 1, d)``.
        :type k_tensor: cute.Tensor
        :param v_tensor: Value tensor, shape ``(b, s_k, h_k, 1, dv)``.
        :type v_tensor: cute.Tensor
        :param o_tensor: Output tensor, shape ``(b, s_q, h_k, h_r, dv)``.
        :type o_tensor: cute.Tensor
        :param problem_size: ``(b, s_q, s_lse, s_k, h_q, h_k, d, dv)``.
        :type problem_size: Tuple[Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32]
        :param lse_tensor: Optional log-sum-exp output buffer; ``None`` skips LSE.
        :type lse_tensor: Optional[cute.Tensor]
        :param sink_tensor: Optional sink-token logits; ``None`` disables sink.
        :type sink_tensor: Optional[cute.Tensor]
        :param scale_softmax_log2: ``scale_softmax * log2(e)``.
        :type scale_softmax_log2: Float32
        :param scale_softmax: Softmax scale (typically ``1/sqrt(d)``).
        :type scale_softmax: Float32
        :param scale_output: Multiplied into O after the softmax-denominator divide.
        :type scale_output: Float32
        :param skip_softmax_threshold_log2: Internal disabled skip-softmax
            specialization argument; always ``None`` from ``run()``.
        :type skip_softmax_threshold_log2: Optional[Float32]
        :param window_size_left: Sliding-window left bound; ``None`` disables.
        :type window_size_left: Optional[Int32]
        :param window_size_right: Sliding-window right bound; ``None`` disables.
        :type window_size_right: Optional[Int32]
        :param stream: CUDA stream to launch on.
        :type stream: cuda.CUstream
        :param use_pdl: Enable Programmatic Dependent Launch.
        :type use_pdl: bool
        :raises TypeError: If Q/K/V dtypes disagree.
        :raises RuntimeError: If any tensor's major mode is unsupported.
        """
        if cutlass.const_expr(skip_softmax_threshold_log2 is not None):
            raise NotImplementedError(_SKIP_SOFTMAX_UNSUPPORTED_MSG)

        b, s_q, s_lse, s_k, h_q, h_k, d, dv = problem_size
        h_r = h_q // h_k
        # setup static attributes before smem/grid/tma computation
        self.q_dtype = q_tensor.element_type
        self.k_dtype = k_tensor.element_type
        self.v_dtype = v_tensor.element_type
        self.o_dtype = o_tensor.element_type

        # Pull seqlens from tensor shapes (they match the problem_size entries
        # for fixed-seqlen; using tensor shapes lets the kernel handle
        # constant-folding more aggressively).
        s_q = q_tensor.shape[1]
        s_k = k_tensor.shape[1]
        # Important for performance
        align = 256 // self.o_dtype.width
        d = cute.assume(Int32(d), align)
        dv = cute.assume(Int32(dv), align)

        # Canonical Q/K/V/O/LSE/sink GMEM views. The helper owns the logical
        # shapes, strides, and GQA broadcast rules; see fmha_operand_layouts.py.
        operand_layouts = FmhaOperandLayouts((b, s_q, s_lse, s_k, h_q, h_k, d, dv))
        q = operand_layouts.make_q_tensor(q_tensor)
        k = operand_layouts.make_k_tensor(k_tensor)
        v = operand_layouts.make_v_tensor(v_tensor)
        o = operand_layouts.make_o_tensor(o_tensor)
        if cutlass.const_expr(lse_tensor is not None):
            lse = operand_layouts.make_lse_tensor(lse_tensor)
        else:
            lse = None
        if cutlass.const_expr(sink_tensor is not None):
            sink = operand_layouts.make_sink_tensor(sink_tensor)
        else:
            sink = None

        self.tile_sched_params, grid = fmha_utils.compute_grid(
            operand_layouts.shape_q(),
            self.spec.cta_tiler,
            self.spec.is_persistent,
        )
        self.q_major_mode = LayoutEnum.from_tensor(q).mma_major_mode()
        self.k_major_mode = LayoutEnum.from_tensor(k).mma_major_mode()
        self.v_major_mode = LayoutEnum.from_tensor(v).mma_major_mode()
        self.o_layout = LayoutEnum.from_tensor(o)

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

        # Thin host wrapper. The TiledMMAs and staged SMEM layouts are
        # rebuilt inside kernel() from `self.spec`; the host does not
        # build TMA atoms or SharedStorage dataclasses.
        self.kernel(
            q,
            k,
            v,
            o,
            lse,
            sink,
            scale_softmax_log2,
            scale_softmax,
            scale_output,
            skip_softmax_threshold_log2,
            window_size_left,
            window_size_right,
            self.tile_sched_params,
        ).launch(
            grid=grid,
            block=[self.spec.threads_per_cta, 1, 1],
            cluster=self.spec.cluster_shape_mnk,
            stream=stream,
            min_blocks_per_mp=1,
            use_pdl=use_pdl,
        )

    #  GPU device kernel
    @cute.kernel
    def kernel(
        self,
        # Base GMEM views consumed directly by cute_ext.tma_load
        # (loads partitioned via qk/pv_thr_mma.partition_A/B) and
        # cute_ext.tma_store + cute_ext.get_cta_v_map_c.
        mQ_qdl: cute.Tensor,
        mK_kdl: cute.Tensor,
        mV_dkl: cute.Tensor,
        mO_qdl: cute.Tensor,
        mLSE: Optional[cute.Tensor],
        mSink: Optional[cute.Tensor],
        scale_softmax_log2: Float32,
        scale_softmax: Float32,
        scale_output: Float32,
        skip_softmax_threshold_log2: Optional[Float32],
        window_size_left: Optional[Int32],
        window_size_right: Optional[Int32],
        tile_sched_params: fmha_utils.FmhaStaticTileSchedulerParams,
    ):
        """FMHA device kernel (warp-specialized).

        Warp roles (16 warps per CTA):
          * load warp: streams Q/K/V from gmem to smem via ``cute_ext.tma_load``;
          * mma warp: issues the QK and PV ``cute_ext.dot`` tiles;
          * softmax warps (x2 warpgroups): online row-max / row-sum update;
          * correction warps: rescale running O partials on row-max changes;
          * epilogue warp: divide by row-sum, cast, stage through smem,
            emit O via ``cute_ext.tma_store`` (plus optional LSE).

        :param mQ_qdl: Base GMEM view of Q (consumed by ``cute_ext.tma_load``).
        :type mQ_qdl: cute.Tensor
        :param mK_kdl: Base GMEM view of K.
        :type mK_kdl: cute.Tensor
        :param mV_dkl: Base GMEM view of V.
        :type mV_dkl: cute.Tensor
        :param mO_qdl: Base GMEM view of O (consumed by ``cute_ext.tma_store``).
        :type mO_qdl: cute.Tensor
        :param mLSE: Optional gmem LSE output; ``None`` skips LSE.
        :type mLSE: Optional[cute.Tensor]
        :param mSink: Optional gmem sink-token logits; ``None`` disables sink.
        :type mSink: Optional[cute.Tensor]
        :param scale_softmax_log2: ``scale_softmax * log2(e)``.
        :type scale_softmax_log2: Float32
        :param scale_softmax: Softmax scale (typically ``1/sqrt(d)``).
        :type scale_softmax: Float32
        :param scale_output: Multiplied into O after the softmax-denominator divide.
        :type scale_output: Float32
        :param skip_softmax_threshold_log2: Internal disabled skip-softmax
            specialization argument; always ``None`` from ``run()``.
        :type skip_softmax_threshold_log2: Optional[Float32]
        :param window_size_left: Sliding-window left bound; ``None`` disables.
        :type window_size_left: Optional[Int32]
        :param window_size_right: Sliding-window right bound; ``None`` disables.
        :type window_size_right: Optional[Int32]
        :param tile_sched_params: Persistent/static tile scheduler parameters.
        :type tile_sched_params: fmha_utils.FmhaStaticTileSchedulerParams
        """
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        # coord inside cta
        tidx, _, _ = cute.arch.thread_idx()

        # TiledMMAs and staged SMEM layouts are rebuilt here from `self.spec`
        # so the kernel signature does not carry them.
        # The host wrapper (__call__) is intentionally thin.
        cta_group = tcgen05.CtaGroup.ONE
        p_source = tcgen05.OperandSource.TMEM
        p_major_mode = cute.nvgpu.OperandMajorMode.K
        qk_tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.q_dtype,
            self.q_dtype,
            self.q_major_mode,
            self.k_major_mode,
            self.spec.qk_acc_dtype,
            cta_group,
            self.spec.qk_mma_tiler[:2],
        )
        pv_tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.v_dtype,
            self.v_dtype,
            p_major_mode,
            self.v_major_mode,
            self.spec.pv_acc_dtype,
            cta_group,
            self.spec.pv_mma_tiler[:2],
            p_source,
        )
        q_smem_layout_staged = sm100_utils.make_smem_layout_a(
            qk_tiled_mma, self.spec.qk_mma_tiler, self.q_dtype, self.spec.q_stage
        )
        k_smem_layout_staged = sm100_utils.make_smem_layout_b(
            qk_tiled_mma, self.spec.qk_mma_tiler, self.k_dtype, self.spec.kv_stage
        )
        p_tmem_layout_staged = sm100_utils.make_smem_layout_a(
            pv_tiled_mma, self.spec.pv_mma_tiler, self.q_dtype, self.spec.acc_stage
        )
        # K & V share the same SMEM ring. For D192 they have different
        # per-tile layouts; force the stage stride to the larger one so
        # stages don't overlap.
        v_smem_layout_staged = cute.append(
            cute.select(
                sm100_utils.make_smem_layout_b(
                    pv_tiled_mma,
                    self.spec.pv_mma_tiler,
                    self.v_dtype,
                    self.spec.kv_stage,
                ),
                mode=[0, 1, 2],
            ),
            cute.select(k_smem_layout_staged, mode=[3]).outer,
        )
        o_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            self.o_dtype, self.o_layout, self.spec.epi_tile, self.spec.epi_stage
        )
        # Buffers are allocated through cute_ext.allocate (lir.allocate_buffer)
        # like the rest of cute_ext, so LIR's allocation planning sees every
        # buffer. The LIR pipelines allocate their own mbarriers, and TMA
        # transaction bytes are set per-load by cute_ext.tma_load, so neither
        # needs plumbing here.
        fmha_pipeline = make_fmha_pipeline(self.spec)
        tmem_holding_buf_ptr = cute_ext.allocate(
            Int32,
            cutlass.AddressSpace.smem,
            cute.make_layout(1),
            alignment=4,
        ).iterator

        # Staged SMEM layouts expose logical tile modes plus a final pipeline
        # stage mode. The A/B helpers partition one CTA tile into three modes:
        #   sQ: (Q_mma, Q_m_rest, D_rest,  q_stage)   for a (M, D) tile
        #   sK: (K_mma, K_m_rest, D_rest,  kv_stage)  for a (N, D) tile
        #   sV: (V_mma, Dv_rest,  K_rest,  kv_stage)  for a (D_v, N) tile
        # The epilogue helper exposes two tile modes:
        #   sO: (O_mma, O_rest, epi_stage)             for a (M, D_v) tile
        # Thus Q/K/V are indexed as sX[mode0, mode1, mode2, stage], while O is
        # indexed as sO[mode0, mode1, stage].
        sO = cute_ext.allocate(
            self.o_dtype,
            cutlass.AddressSpace.smem,
            o_smem_layout_staged,
            alignment=self.spec.buffer_align_bytes,
        )
        sQ = cute_ext.allocate(
            self.q_dtype,
            cutlass.AddressSpace.smem,
            q_smem_layout_staged,
            alignment=self.spec.buffer_align_bytes,
        )
        sK = cute_ext.allocate(
            self.k_dtype,
            cutlass.AddressSpace.smem,
            k_smem_layout_staged,
            alignment=self.spec.buffer_align_bytes,
        )
        # sV aliases sK storage with the PV-B operand's partitioned tile modes.
        sV_ptr = cute.recast_ptr(sK.iterator, v_smem_layout_staged.inner)
        sV = cute.make_tensor(sV_ptr, v_smem_layout_staged.outer)

        # LIR pipelines: a single object carries both the producer and the
        # consumer cursor; each warp-specialized role only touches its own
        # side.
        load_q_pipe = fmha_pipeline.load_q
        load_kv_pipe = fmha_pipeline.load_kv
        mma_s0_pipe = fmha_pipeline.qk_to_softmax0
        mma_s1_pipe = fmha_pipeline.qk_to_softmax1
        p0_mma_pipe = fmha_pipeline.softmax0_to_mma_av
        p1_mma_pipe = fmha_pipeline.softmax1_to_mma_av
        s0_corr_pipe = fmha_pipeline.softmax0_to_correction
        s1_corr_pipe = fmha_pipeline.softmax1_to_correction
        corr_epi_pipe = fmha_pipeline.correction_to_epilogue
        mma_corr_pipe = fmha_pipeline.mma_av_to_correction
        s0_p1_inplace_pipe = fmha_pipeline.softmax0_to_softmax1_p1
        s1_p0_inplace_pipe = fmha_pipeline.softmax1_to_softmax0_p0
        tmem = TmemAllocator(
            tmem_holding_buf_ptr,
            barrier_for_retrieve=self.tmem_alloc_barrier,
            # Correction warp is the last one that accesses tmem
            allocator_warp_id=self.spec.correction_warp_ids[0],
        )
        # Not required for correctness: LIR already fences the pipelines'
        # mbarrier inits (fence.mbarrier_init + CTA barrier after the
        # create_pipeline ops). This explicit fence plus the sync below are
        # kept because dropping either measures slightly slower (~0.5-1% on
        # persistent / short-Q causal shapes) -- the later alignment point,
        # right before the scheduler loop, starts the warps closer together.
        cute.arch.mbarrier_init_fence()

        qk_thr_mma = qk_tiled_mma.get_slice(0)  # default 1sm
        pv_thr_mma = pv_tiled_mma.get_slice(0)  # default 1sm
        # Raw staged SMEM operands expose the logical tile modes used by QK/PV:
        #   sQ: (MMA, M,  D, q_stage)
        #   sK: (MMA, N,  D, kv_stage)
        #   sV: (MMA, Dv, N, kv_stage)
        # Each wait site fixes the final stage mode before the dot loop.

        def make_tmem_tensors(
            self,
            qk_thr_mma: cute.TiledMma,
            pv_thr_mma: cute.TiledMma,
            p_tmem_layout_staged: cute.Layout,
            tmem_ptr: cute.Pointer,
        ):
            # TMEM tensor legend. See the module docstring's "Tensor name
            # legend" for the local naming pattern.
            #
            # QK score tiles, logical shape (MMA, M, N):
            #   tStS  : base score view at the S0 offset, used for shared
            #           score/vector layouts.
            #   tStS0 : score accumulator for the first Q tile, S0 = Q0 @ K^T.
            #   tStS1 : score accumulator for the second Q tile, S1 = Q1 @ K^T.
            #
            # PV output accumulators, logical shape (MMA, M, Dv):
            #   tOtO0 : running output accumulator for O0 = P0 @ V.
            #   tOtO1 : running output accumulator for O1 = P1 @ V.
            #
            # Softmax probability tiles consumed as PV-A, logical shape
            # (MMA, M, N):
            #   tPtP0 : P0 = softmax(S0), recast/laid out for PV MMA A.
            #   tPtP1 : P1 = softmax(S1), recast/laid out for PV MMA A.
            qk_acc_shape = qk_thr_mma.partition_shape_C(
                (self.spec.qk_mma_tiler[0], self.spec.qk_mma_tiler[1])
            )
            tStS_fake = qk_thr_mma.make_fragment_C(qk_acc_shape)
            tStS = cute.make_tensor(
                tmem_ptr + self.spec.tmem_s0_offset, tStS_fake.layout
            )
            pv_acc_shape = pv_thr_mma.partition_shape_C(
                (self.spec.pv_mma_tiler[0], self.spec.pv_mma_tiler[1])
            )
            tOtO = pv_thr_mma.make_fragment_C(pv_acc_shape)
            tStS0 = cute.make_tensor(tmem_ptr + self.spec.tmem_s0_offset, tStS.layout)
            tStS1 = cute.make_tensor(tmem_ptr + self.spec.tmem_s1_offset, tStS.layout)
            tOtO0 = cute.make_tensor(tmem_ptr + self.spec.tmem_o0_offset, tOtO.layout)
            tOtO1 = cute.make_tensor(tmem_ptr + self.spec.tmem_o1_offset, tOtO.layout)
            tP = cute.make_tensor(tStS.iterator, p_tmem_layout_staged.outer)
            tPtP = pv_thr_mma.make_fragment_A(tP)[None, None, None, 0]
            tPtP0 = cute.make_tensor(
                cute.recast_ptr(
                    tmem_ptr + self.spec.tmem_p0_offset,
                    dtype=tPtP.dtype,
                ),
                tPtP.layout,
            )
            tPtP1 = cute.make_tensor(
                cute.recast_ptr(
                    tmem_ptr + self.spec.tmem_p1_offset,
                    dtype=tPtP.dtype,
                ),
                tPtP.layout,
            )
            return tStS, tStS0, tStS1, tOtO0, tOtO1, tPtP0, tPtP1

        tile_sched = fmha_utils.create_fmha_static_tile_scheduler(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()
        cute.arch.sync_threads()
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
        if warp_idx == self.spec.empty_warp_id:
            cute.arch.setmaxregister_decrease(self.spec.num_regs_other)

        # ///////////////////////////////////////////////////////////////////////////////
        #  LOAD
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.spec.load_warp_id:
            cute.arch.setmaxregister_decrease(self.spec.num_regs_other)
            cute.arch.griddepcontrol_wait()
            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                seqlen_q = mQ_qdl.shape[0]
                seqlen_k = mK_kdl.shape[0]
                continue_cond = seqlen_k <= 0
                if not continue_cond:
                    mQ_qdl_ = mQ_qdl
                    mK_kdl_ = mK_kdl
                    mV_dkl_ = mV_dkl
                    # GMEM logical modes before tiling:
                    #   Q: (S_q, D, L), K: (S_k, D, L), V: (D_v, S_k, L),
                    #   with L = ((h_r, h_k), b).
                    #
                    # flat_divide introduces CTA-local modes followed by tile
                    # block modes:
                    #   gQ: (M, D, Q_blk, D_blk, L)
                    #   gK: (N, D, K_blk, D_blk, L)
                    #   gV: (D_v, N, Dv_blk, K_blk, L)
                    # The TMA load sites below keep the first two modes
                    # unsliced, then select (Q_blk/K_blk, dim_blk, L).
                    gQ_qdl = cute.flat_divide(
                        mQ_qdl_, cute.select(self.spec.qk_mma_tiler, mode=[0, 2])
                    )
                    gK_kdl = cute.flat_divide(
                        mK_kdl_, cute.select(self.spec.qk_mma_tiler, mode=[1, 2])
                    )
                    gV_dkl = cute.flat_divide(
                        mV_dkl_, cute.select(self.spec.pv_mma_tiler, mode=[1, 2])
                    )
                    seqlen_kv_loop_start, seqlen_kv_loop_steps = self.get_kv_loop_range(
                        curr_block_coord,
                        seqlen_q,
                        seqlen_k,
                        window_size_left,
                        window_size_right,
                    )
                    # Partition the base GMEM tile through the MMA thread
                    # slice and feed the partitioned view directly to
                    # tma_load (no cta_v_map). Q is operand A of
                    # qk_tiled_mma; K is operand B; V is operand B of
                    # pv_tiled_mma.
                    # Each load: acquire a stage (waits for the MMA release),
                    # then issue the TMA against the stage mbarrier --
                    # tma_load sets the expected transaction bytes and the
                    # TMA engine's completion arrives the full barrier.
                    # Q0
                    q0_coord = 2 * curr_block_coord[0]
                    q_tok, q_idx = load_q_pipe.producer_acquire_and_get_stage()
                    cute_ext.tma_load(
                        qk_thr_mma.partition_A(
                            gQ_qdl[None, None, q0_coord, 0, curr_block_coord[2]]
                        ),
                        sQ[None, None, None, q_idx],
                        cute_ext.get_mbarrier(q_tok),
                    )
                    load_q_pipe.producer_commit_and_advance()
                    # K0
                    kv_coord = seqlen_kv_loop_start
                    kv_tok, kv_idx = load_kv_pipe.producer_acquire_and_get_stage()
                    cute_ext.tma_load(
                        qk_thr_mma.partition_B(
                            gK_kdl[None, None, kv_coord, 0, curr_block_coord[2]]
                        ),
                        sK[None, None, None, kv_idx],
                        cute_ext.get_mbarrier(kv_tok),
                    )
                    load_kv_pipe.producer_commit_and_advance()
                    # Q1
                    q1_coord = q0_coord + 1
                    q_tok, q_idx = load_q_pipe.producer_acquire_and_get_stage()
                    cute_ext.tma_load(
                        qk_thr_mma.partition_A(
                            gQ_qdl[None, None, q1_coord, 0, curr_block_coord[2]]
                        ),
                        sQ[None, None, None, q_idx],
                        cute_ext.get_mbarrier(q_tok),
                    )
                    load_q_pipe.producer_commit_and_advance()
                    kv_coord += 1

                    for i in cutlass.range(1, seqlen_kv_loop_steps, 1, unroll=1):
                        # Ki
                        kv_tok, kv_idx = load_kv_pipe.producer_acquire_and_get_stage()
                        cute_ext.tma_load(
                            qk_thr_mma.partition_B(
                                gK_kdl[None, None, kv_coord, 0, curr_block_coord[2]]
                            ),
                            sK[None, None, None, kv_idx],
                            cute_ext.get_mbarrier(kv_tok),
                        )
                        load_kv_pipe.producer_commit_and_advance()
                        # Vi-1
                        kv_tok, kv_idx = load_kv_pipe.producer_acquire_and_get_stage()
                        cute_ext.tma_load(
                            pv_thr_mma.partition_B(
                                gV_dkl[None, None, 0, kv_coord - 1, curr_block_coord[2]]
                            ),
                            sV[None, None, None, kv_idx],
                            cute_ext.get_mbarrier(kv_tok),
                        )
                        load_kv_pipe.producer_commit_and_advance()
                        kv_coord += 1
                    # End of seqlen_kv loop
                    # Vi_end
                    kv_tok, kv_idx = load_kv_pipe.producer_acquire_and_get_stage()
                    cute_ext.tma_load(
                        pv_thr_mma.partition_B(
                            gV_dkl[None, None, 0, kv_coord - 1, curr_block_coord[2]]
                        ),
                        sV[None, None, None, kv_idx],
                        cute_ext.get_mbarrier(kv_tok),
                    )
                    load_kv_pipe.producer_commit_and_advance()
                # End of if not continue_cond
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                # End of persistent scheduler loop
        # ///////////////////////////////////////////////////////////////////////////////
        #  MMA
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.spec.mma_warp_id:
            cute.arch.setmaxregister_decrease(self.spec.num_regs_other)
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.spec.qk_acc_dtype)
            # See make_tmem_tensors() above for the TMEM tensor legend.
            tStS, tStS0, tStS1, tOtO0, tOtO1, tPtP0, tPtP1 = make_tmem_tensors(
                self, qk_thr_mma, pv_thr_mma, p_tmem_layout_staged, tmem_ptr
            )
            # The MMA warp holds several load stages at once (Q0/Q1 across the
            # whole KV loop; K_i and V_{i-1} simultaneously), so waits run on
            # clones of the same raw pipelines whose cursors advance ahead,
            # while load_*_pipe's own consumer cursor stays behind for the
            # in-order (FIFO) releases.
            load_q_wait = load_q_pipe.clone()
            load_kv_wait = load_kv_pipe.clone()

            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                seqlen_q = mQ_qdl.shape[0]
                seqlen_k = mK_kdl.shape[0]
                continue_cond = seqlen_k <= 0
                if not continue_cond:
                    # Wait for Q0
                    _, q0_idx = load_q_wait.consumer_wait_and_get_stage()
                    load_q_wait.consumer_advance()
                    # Q0 stage slice:
                    #   sQ  (MMA, M, D, q_stage)
                    #   tSrQ0 = sQ[..., q0_stage] -> (MMA, M, D)
                    tSrQ0 = sQ[None, None, None, q0_idx]
                    # Wait for K0
                    _, k_idx = load_kv_wait.consumer_wait_and_get_stage()
                    load_kv_wait.consumer_advance()
                    # K0 stage slice:
                    #   sK  (MMA, N, D, kv_stage)
                    #   tSrK0 = sK[..., k_stage] -> (MMA, N, D)
                    tSrK0 = sK[None, None, None, k_idx]
                    # GEMM_QK00 (Q0 * K0 -> S0)
                    mma_s0_pipe, s0_corr_pipe = self.mma_qk(
                        qk_tiled_mma,
                        (tSrQ0, tSrK0, tStS0),
                        mma_s0_pipe,
                        s0_corr_pipe,
                    )
                    # Wait for Q1
                    _, q1_idx = load_q_wait.consumer_wait_and_get_stage()
                    load_q_wait.consumer_advance()
                    # Q1 stage slice has the same shape as Q0:
                    #   tSrQ1 -> (MMA, M, D)
                    tSrQ1 = sQ[None, None, None, q1_idx]
                    # GEMM_QK10 (Q1 * K0 -> S1), K0 is ready in GEMM_QK00
                    mma_s1_pipe, s1_corr_pipe = self.mma_qk(
                        qk_tiled_mma,
                        (tSrQ1, tSrK0, tStS1),
                        mma_s1_pipe,
                        s1_corr_pipe,
                    )
                    # Release K0
                    load_kv_pipe.consumer_release_and_advance()
                    # Note: Q0 & Q1 are still needed in the seqlen_kv loop
                    # so we need to release them after the seqlen_kv loop
                    _, seqlen_kv_loop_steps = self.get_kv_loop_range(
                        curr_block_coord,
                        seqlen_q,
                        seqlen_k,
                        window_size_left,
                        window_size_right,
                    )
                    # O1 hasn't been accumulated yet, its first MMA calculation doesn't need to accumulate
                    pv_whether_acc = False
                    for i in cutlass.range(1, seqlen_kv_loop_steps, 1, unroll=1):
                        # Wait for Ki
                        _, k_idx = load_kv_wait.consumer_wait_and_get_stage()
                        load_kv_wait.consumer_advance()
                        # Ki stage slice:
                        #   tSrKi -> (MMA, N, D)
                        tSrKi = sK[None, None, None, k_idx]
                        # GEMM_QK0i (Q0 * Ki -> S0)
                        mma_s0_pipe, s0_corr_pipe = self.mma_qk(
                            qk_tiled_mma,
                            (tSrQ0, tSrKi, tStS0),
                            mma_s0_pipe,
                            s0_corr_pipe,
                        )
                        # Wait for Vi-1
                        _, v_idx = load_kv_wait.consumer_wait_and_get_stage()
                        load_kv_wait.consumer_advance()
                        # Vi stage slice for PV:
                        #   sV    (MMA, Dv, N, kv_stage)
                        #   tOrVi = sV[..., v_stage] -> (MMA, Dv, N)
                        tOrVi = sV[None, None, None, v_idx]
                        # GEMM_PV0(i-1) (P0 * Vi-1 -> O0_partial)
                        mma_corr_pipe, p0_mma_pipe = self.mma_pv(
                            pv_tiled_mma,
                            pv_whether_acc,
                            (tPtP0, tOrVi, tOtO0),
                            mma_corr_pipe,
                            p0_mma_pipe,
                        )
                        # GEMM_QK1i (Q1 * Ki -> S1)
                        mma_s1_pipe, s1_corr_pipe = self.mma_qk(
                            qk_tiled_mma,
                            (tSrQ1, tSrKi, tStS1),
                            mma_s1_pipe,
                            s1_corr_pipe,
                        )
                        # Release Ki
                        load_kv_pipe.consumer_release_and_advance()
                        # GEMM_PV1(i-1) (P1 * Vi-1 -> O1_partial)
                        mma_corr_pipe, p1_mma_pipe = self.mma_pv(
                            pv_tiled_mma,
                            pv_whether_acc,
                            (tPtP1, tOrVi, tOtO1),
                            mma_corr_pipe,
                            p1_mma_pipe,
                        )
                        pv_whether_acc = True
                        # Release Vi-1
                        load_kv_pipe.consumer_release_and_advance()
                    # End of seqlen_kv loop
                    # release Q0 & Q1
                    load_q_pipe.consumer_release_and_advance()
                    load_q_pipe.consumer_release_and_advance()
                    # Wait for Vi_end
                    _, v_idx = load_kv_wait.consumer_wait_and_get_stage()
                    load_kv_wait.consumer_advance()
                    # Final V stage slice has the same PV-B shape:
                    #   tOrVi -> (MMA, Dv, N)
                    tOrVi = sV[None, None, None, v_idx]
                    # GEMM_PV0(i_end) (P0 * Vi_end -> O0)
                    mma_corr_pipe, p0_mma_pipe = self.mma_pv(
                        pv_tiled_mma,
                        pv_whether_acc,
                        (tPtP0, tOrVi, tOtO0),
                        mma_corr_pipe,
                        p0_mma_pipe,
                    )
                    # GEMM_PV1(i_end) (P1 * Vi_end -> O1)
                    mma_corr_pipe, p1_mma_pipe = self.mma_pv(
                        pv_tiled_mma,
                        pv_whether_acc,
                        (tPtP1, tOrVi, tOtO1),
                        mma_corr_pipe,
                        p1_mma_pipe,
                    )
                    # Release Vi_end
                    load_kv_pipe.consumer_release_and_advance()
                    # Empty step for correction epilog
                    s0_corr_pipe.producer_acquire()
                    s0_corr_pipe.producer_commit_and_advance()
                    s1_corr_pipe.producer_acquire()
                    s1_corr_pipe.producer_commit_and_advance()
                # End of if not continue_cond
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # End of persistent scheduler loop
        # ///////////////////////////////////////////////////////////////////////////////
        #  Epilogue (TMA store)
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.spec.epilogue_warp_id:
            cute.arch.setmaxregister_decrease(self.spec.num_regs_other)
            O_epi_tile = cute.select(self.spec.pv_mma_tiler, mode=[0, 1])
            # O GMEM starts as (S_q, D_v, L), L = ((h_r, h_k), b).
            # flat_divide by (M, D_v) gives:
            #   gO: (M, D_v, Q_blk, Dv_blk, L)
            # The store keeps (M, D_v) unsliced, then selects
            # (Q_blk=o0/o1_coord, Dv_blk=0, L=curr_block_coord[2]).
            # sO is (M, D_v, epi_stage); epi_stage 0/1 holds O0/O1.
            gO_qdl = cute.flat_divide(mO_qdl, O_epi_tile)
            O_cta_v_map = cute_ext.get_cta_v_map_c(mO_qdl, O_epi_tile)
            # Both O tiles are waited before either is released: waits run
            # ahead on a clone while corr_epi_pipe's own consumer cursor lags
            # for the deferred in-order releases.
            corr_epi_wait = corr_epi_pipe.clone()
            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                o0_coord = 2 * curr_block_coord[0]
                o1_coord = o0_coord + 1

                # Both O tiles are waited before either is released, so the
                # waits run on a clone whose cursor runs ahead while the pipe's
                # own consumer cursor stays behind for the deferred releases.
                # O0: wait for final, TMA store, commit
                corr_epi_wait.consumer_wait()
                corr_epi_wait.consumer_advance()
                cute_ext.tma_store(
                    sO[None, None, 0],
                    gO_qdl[None, None, o0_coord, 0, curr_block_coord[2]],
                    cta_v_map=O_cta_v_map,
                )
                cute.arch.cp_async_bulk_commit_group()
                # O1: wait for final, TMA store, commit
                corr_epi_wait.consumer_wait()
                corr_epi_wait.consumer_advance()
                cute_ext.tma_store(
                    sO[None, None, 1],
                    gO_qdl[None, None, o1_coord, 0, curr_block_coord[2]],
                    cta_v_map=O_cta_v_map,
                )
                cute.arch.cp_async_bulk_commit_group()

                # Release O0 then O1 buffers in commit-group order.
                cute.arch.cp_async_bulk_wait_group(1, read=True)
                corr_epi_pipe.consumer_release_and_advance()
                cute.arch.cp_async_bulk_wait_group(0, read=True)
                corr_epi_pipe.consumer_release_and_advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # End of persistent scheduler loop
        # ///////////////////////////////////////////////////////////////////////////////
        #  Softmax0
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx < self.spec.softmax1_warp_ids[0]:
            cute.arch.setmaxregister_increase(self.spec.num_regs_softmax)
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.spec.qk_acc_dtype)
            # See make_tmem_tensors() above for the TMEM tensor legend.
            tStS, tStS0, tStS1, tOtO0, tOtO1, tPtP0, tPtP1 = make_tmem_tensors(
                self, qk_thr_mma, pv_thr_mma, p_tmem_layout_staged, tmem_ptr
            )
            softmax_fn(
                stage=0,
                tensor_args=(
                    tStS,
                    tStS0,
                ),
                pipes=SoftmaxPipes(
                    si_peek=cutlass.Boolean(False),
                    mma_si=mma_s0_pipe,
                    si_corr=s0_corr_pipe,
                    pi_mma=p0_mma_pipe,
                    inplace_produce=s0_p1_inplace_pipe,
                    inplace_consume=s1_p0_inplace_pipe,
                ),
            )

        # ///////////////////////////////////////////////////////////////////////////////
        #  Softmax1
        # ///////////////////////////////////////////////////////////////////////////////
        if (
            warp_idx < self.spec.correction_warp_ids[0]
            and warp_idx >= self.spec.softmax1_warp_ids[0]
        ):
            cute.arch.setmaxregister_increase(self.spec.num_regs_softmax)
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.spec.qk_acc_dtype)
            # See make_tmem_tensors() above for the TMEM tensor legend.
            tStS, tStS0, tStS1, tOtO0, tOtO1, tPtP0, tPtP1 = make_tmem_tensors(
                self, qk_thr_mma, pv_thr_mma, p_tmem_layout_staged, tmem_ptr
            )
            softmax_fn(
                stage=1,
                tensor_args=(
                    tStS,
                    tStS1,
                ),
                pipes=SoftmaxPipes(
                    si_peek=cutlass.Boolean(False),
                    mma_si=mma_s1_pipe,
                    si_corr=s1_corr_pipe,
                    pi_mma=p1_mma_pipe,
                    inplace_produce=s1_p0_inplace_pipe,
                    inplace_consume=s0_p1_inplace_pipe,
                ),
            )

        # ///////////////////////////////////////////////////////////////////////////////
        #  Correction
        # ///////////////////////////////////////////////////////////////////////////////
        if (
            warp_idx >= self.spec.correction_warp_ids[0]
            and warp_idx < self.spec.mma_warp_id
        ):
            cute.arch.setmaxregister_decrease(self.spec.num_regs_correction)
            tmem.allocate(self.num_tmem_alloc_cols)
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.spec.qk_acc_dtype)
            # See make_tmem_tensors() above for the TMEM tensor legend.
            tStS, tStS0, tStS1, tOtO0, tOtO1, tPtP0, tPtP1 = make_tmem_tensors(
                self, qk_thr_mma, pv_thr_mma, p_tmem_layout_staged, tmem_ptr
            )
            cS = cute.make_identity_tensor(
                (self.spec.qk_mma_tiler[0], self.spec.qk_mma_tiler[1])
            )
            tScS = qk_thr_mma.partition_C(cS)

            tStS_vec_layout = cute.composition(tStS.layout, cute.make_layout((128, 2)))

            tStS_vec0 = cute.make_tensor(
                tStS.iterator + self.spec.tmem_vec0_offset, tStS_vec_layout
            )
            tStS_vec1 = cute.make_tensor(
                tStS.iterator + self.spec.tmem_vec1_offset, tStS_vec_layout
            )

            tScS_vec_layout = cute.composition(tScS.layout, cute.make_layout((128, 2)))
            tScS_vec = cute.make_tensor(tScS.iterator, tScS_vec_layout)
            tmem_load_v_atom = cute.make_copy_atom(
                tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(2)),
                self.spec.qk_acc_dtype,
            )
            tiled_tmem_load_vec = tcgen05.make_tmem_copy(tmem_load_v_atom, tStS_vec0)
            thread_idx = tidx % (
                self.spec.threads_per_warp * len(self.spec.correction_warp_ids)
            )
            thr_tmem_load_vec = tiled_tmem_load_vec.get_slice(thread_idx)
            tTMEM_LOAD_VECcS = thr_tmem_load_vec.partition_D(tScS_vec)
            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                seqlen_k = mK_kdl.shape[0]
                seqlen_q = mQ_qdl.shape[0]
                row_idx = (
                    curr_block_coord[0] * self.spec.cta_tiler[0]
                    + tTMEM_LOAD_VECcS[0][0]
                )
                continue_cond = seqlen_k <= 0
                if not continue_cond:
                    # Ignore first signal from softmax as no correction is required
                    s0_corr_pipe.consumer_wait()
                    s0_corr_pipe.consumer_release_and_advance()
                    s1_corr_pipe.consumer_wait()
                    s1_corr_pipe.consumer_release_and_advance()
                    _, seqlen_kv_loop_steps = self.get_kv_loop_range(
                        curr_block_coord,
                        seqlen_q,
                        seqlen_k,
                        window_size_left,
                        window_size_right,
                    )
                    for i in cutlass.range(1, seqlen_kv_loop_steps, 1, unroll=1):
                        # Rescale O0
                        s0_corr_pipe, mma_corr_pipe = self.correction_rescale(
                            pv_thr_mma,
                            thr_tmem_load_vec,
                            scale_softmax_log2,
                            (tOtO0, tStS_vec0, tTMEM_LOAD_VECcS),
                            s0_corr_pipe,
                            mma_corr_pipe,
                        )
                        # Rescale O1
                        s1_corr_pipe, mma_corr_pipe = self.correction_rescale(
                            pv_thr_mma,
                            thr_tmem_load_vec,
                            scale_softmax_log2,
                            (tOtO1, tStS_vec1, tTMEM_LOAD_VECcS),
                            s1_corr_pipe,
                            mma_corr_pipe,
                        )
                    # End of seqlen_corr_loop_steps
                    value_args = (
                        seqlen_q,
                        curr_block_coord,
                        scale_softmax,
                        scale_output,
                    )
                    # TMA store path: write to sO, signal epilogue warp
                    # Normalize O0
                    s0_corr_pipe, mma_corr_pipe, corr_epi_pipe = self.correction_epilog(
                        pv_thr_mma,
                        thr_tmem_load_vec,
                        (
                            tOtO0,
                            tStS_vec0,
                            tTMEM_LOAD_VECcS,
                            sO[None, None, 0],
                            mLSE,
                            mSink,
                        ),
                        s0_corr_pipe,
                        mma_corr_pipe,
                        corr_epi_pipe,
                        (row_idx, *value_args),
                    )
                    row_idx += self.spec.qk_mma_tiler[0]
                    # Normalize O1
                    s1_corr_pipe, mma_corr_pipe, corr_epi_pipe = self.correction_epilog(
                        pv_thr_mma,
                        thr_tmem_load_vec,
                        (
                            tOtO1,
                            tStS_vec1,
                            tTMEM_LOAD_VECcS,
                            sO[None, None, 1],
                            mLSE,
                            mSink,
                        ),
                        s1_corr_pipe,
                        mma_corr_pipe,
                        corr_epi_pipe,
                        (row_idx, *value_args),
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
    def get_kv_loop_range(
        self,
        curr_block_coord,
        seqlen_q,
        seqlen_k,
        window_size_left,
        window_size_right,
    ):
        mask_type = self.spec.mask_type
        tile_shape = self.spec.cta_tiler

        offset = 0
        if cutlass.const_expr(mask_type is fmha_utils.MaskEnum.WINDOW_MASK_INFERENCE):
            offset = seqlen_k - seqlen_q
        if cutlass.const_expr(
            mask_type is fmha_utils.MaskEnum.WINDOW_MASK_BWD_INFERENCE
        ):
            offset = seqlen_q - seqlen_k

        start_block = 0
        if cutlass.const_expr(
            mask_type is fmha_utils.MaskEnum.WINDOW_MASK
            or mask_type is fmha_utils.MaskEnum.WINDOW_MASK_INFERENCE
        ):
            if cutlass.const_expr(window_size_left is not None):
                min_idx_q = curr_block_coord[0] * tile_shape[0]
                idx_k = min_idx_q + offset - window_size_left
                tmp_blocks_k = idx_k // tile_shape[1]
                start_block = max(tmp_blocks_k, start_block)
        if cutlass.const_expr(
            mask_type is fmha_utils.MaskEnum.WINDOW_MASK_BWD
            or mask_type is fmha_utils.MaskEnum.WINDOW_MASK_BWD_INFERENCE
        ):
            if cutlass.const_expr(window_size_right is not None):
                min_idx_k = curr_block_coord[1] * tile_shape[1]
                idx_q = min_idx_k + offset - window_size_right
                tmp_blocks_q = idx_q // tile_shape[0]
                start_block = max(tmp_blocks_q, start_block)

        end_block = 0
        if cutlass.const_expr(mask_type == fmha_utils.MaskEnum.RESIDUAL_MASK):
            end_block = cute.ceil_div(seqlen_k, tile_shape[1])
        if cutlass.const_expr(mask_type is fmha_utils.MaskEnum.RESIDUAL_MASK_BWD):
            end_block = cute.ceil_div(seqlen_q, tile_shape[0])
        if cutlass.const_expr(
            mask_type == fmha_utils.MaskEnum.WINDOW_MASK
            or mask_type == fmha_utils.MaskEnum.WINDOW_MASK_INFERENCE
        ):
            if cutlass.const_expr(window_size_right is None):
                end_block = cute.ceil_div(seqlen_k, tile_shape[1])
            else:
                max_idx_q = (curr_block_coord[0] + 1) * tile_shape[0]
                idx_k = max_idx_q + offset + window_size_right
                tmp_blocks_k = cute.ceil_div(idx_k, tile_shape[1])
                max_blocks_k = cute.ceil_div(seqlen_k, tile_shape[1])
                end_block = min(max_blocks_k, tmp_blocks_k)
        if cutlass.const_expr(
            mask_type == fmha_utils.MaskEnum.WINDOW_MASK_BWD
            or mask_type == fmha_utils.MaskEnum.WINDOW_MASK_BWD_INFERENCE
        ):
            if cutlass.const_expr(window_size_left is None):
                end_block = cute.ceil_div(seqlen_q, tile_shape[0])
            else:
                max_idx_k = (curr_block_coord[1] + 1) * tile_shape[1]
                idx_k = max_idx_k + offset + window_size_left
                tmp_blocks_q = cute.ceil_div(idx_k, tile_shape[0])
                max_blocks_q = cute.ceil_div(seqlen_q, tile_shape[0])
                end_block = min(max_blocks_q, tmp_blocks_q)

        return start_block, end_block - start_block

    @cute.jit
    def mma_qk(
        self,
        tiled_mma: cute.TiledMma,
        tensor_args: Tuple,
        mma_si_pipe,
        si_corr_pipe,
    ) -> Tuple:
        """Perform a single step of the QK GEMM computation on a block of attention scores.

        The Q/K operands are stage-sliced SMEM tiles:
        ``tSrQi: (MMA, M, D)`` and ``tSrK: (MMA, N, D)``. The final mode is
        the QK reduction dimension and is sliced by ``kphase_idx`` before dot.

        :param tiled_mma: Tiled MMA for QK GEMM
        :type tiled_mma: cute.TiledMma
        :param tensor_args: Tuple containing Qi (stage-sliced sQ), K (stage-sliced sK), Si
        :type tensor_args: Tuple
        :param mma_si_pipe: QK MMA -> softmax score pipeline (producer side).
        :param si_corr_pipe: softmax -> correction row-vec pipeline (the MMA
            warp's ordering arrive; see fmha_pipeline.py).
        :return: Updated (mma_si_pipe, si_corr_pipe)
        :rtype: Tuple
        """
        tSrQi, tSrK, tStSi = tensor_args
        # 0. Make sure Qi & K are ready when calling mma_qk
        # 1. acquire S0
        mma_si_pipe.producer_acquire()
        # 2. make sure vec is already released in corr (the vec TMEM slot
        # aliases the S accumulator this dot is about to overwrite); the
        # immediate commit is the MMA warp's ordering arrive on the vec-full
        # barrier -- see fmha_pipeline.py.
        si_corr_pipe.producer_acquire()
        si_corr_pipe.producer_commit_and_advance()
        # 3. dot
        mma_atom = cute.make_mma_atom(tiled_mma.op)
        # tSrQi/tSrK are rank-3 logical tiles:
        #   tSrQi: (MMA, M, D)
        #   tSrK : (MMA, N, D)
        # mode 2 is the D/kphase loop for QK.
        num_kphases = cute.size(tSrQi, mode=[2])
        for kphase_idx in cutlass.range(num_kphases, unroll_full=True):
            mma_atom.set(tcgen05.Field.ACCUMULATE, kphase_idx != 0)
            # Slicing mode 2 gives rank-2 operands:
            #   Q phase: (MMA, M)
            #   K phase: (MMA, N)
            # cute_ext.dot restores the rank-3 MMA contract internally.
            cute_ext.dot(
                mma_atom,
                tSrQi[None, None, kphase_idx],
                tSrK[None, None, kphase_idx],
                tStSi,
            )
        # 4. release S0 (tcgen05 UMMA completion arrives the full barrier)
        mma_si_pipe.producer_commit_and_advance()
        return mma_si_pipe, si_corr_pipe

    @cute.jit
    def mma_pv(
        self,
        tiled_mma: cute.TiledMma,
        whether_acc: bool,
        tensor_args: Tuple,
        mma_corr_pipe,
        pi_mma_pipe,
    ) -> Tuple:
        """Perform a single step of the PV GEMM computation on accumulating O.

        :param tiled_mma: Tiled MMA for PV GEMM
        :type tiled_mma: cute.TiledMma
        :param whether_acc: Whether to accumulate O
        :type whether_acc: bool
        :param tensor_args: Tuple containing Pi, Vi, and Oi
        :type tensor_args: Tuple
        :param mma_corr_pipe: PV MMA -> correction O pipeline (producer side).
        :param pi_mma_pipe: softmax -> PV MMA probability pipeline (consumer
            side).
        :return: Updated (mma_corr_pipe, pi_mma_pipe)
        :rtype: Tuple
        """
        tPtPi, tOrVi, tOtOi = tensor_args
        # 0. Make sure Vi is ready when calling mma_pv
        # 1. acquire Oi
        mma_corr_pipe.producer_acquire()
        # 2. wait for Pi
        pi_mma_pipe.consumer_wait()
        # 3. gemm
        # PV operands are rank-3 logical tiles:
        #   tPtPi: (MMA, M,  N)  from TMEM P
        #   tOrVi: (MMA, Dv, N)  from the V stage slice
        # mode 2 is the PV reduction dimension. Each kphase slice is rank 2;
        # cute_ext.dot restores the rank-3 MMA contract internally.
        num_kphases = cute.size(tPtPi, mode=[2])
        mma_atom = cute.make_mma_atom(tiled_mma.op)
        for kphase_idx in cutlass.range(num_kphases, unroll_full=True):
            mma_atom.set(tcgen05.Field.ACCUMULATE, whether_acc or kphase_idx != 0)
            cute_ext.dot(
                mma_atom,
                tPtPi[None, None, kphase_idx],
                tOrVi[None, None, kphase_idx],
                tOtOi,
            )
        # 4. commit Pi (UMMA completion releases the P buffer)
        pi_mma_pipe.consumer_release_and_advance()
        # 5. commit Oi (UMMA completion arrives the full barrier)
        mma_corr_pipe.producer_commit_and_advance()
        return mma_corr_pipe, pi_mma_pipe

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
        inplace_consume_pipe,
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
        :param inplace_consume_pipe: The inplace exchange pipeline
            (consumer side).
        :type inplace_consume_pipe: cute_ext.GenericPipeline
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
                    if cutlass.const_expr(self.q_dtype.width == 8):
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
                        ].store(s_vec.to(self.q_dtype))
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
                if cutlass.const_expr(self.q_dtype.width == 8):
                    fmha_utils.cvt_f32x4_to_f8x4(
                        tTMEM_LOADrS_cvt[None, i // CVT_PER_STEP],
                        tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP],
                    )
                else:
                    s_vec = tTMEM_LOADrS_cvt[None, i // CVT_PER_STEP].load()
                    tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP].store(
                        s_vec.to(self.q_dtype)
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
                if cutlass.const_expr(self.q_dtype.width == 8):
                    fmha_utils.cvt_f32x4_to_f8x4(
                        tTMEM_LOADrS_cvt[None, i // CVT_PER_STEP],
                        tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP],
                    )
                else:
                    s_vec = tTMEM_LOADrS_cvt[None, i // CVT_PER_STEP].load()
                    tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP].store(
                        s_vec.to(self.q_dtype)
                    )

        inplace_peek_status = inplace_consume_pipe.consumer_try_wait()
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
                if cutlass.const_expr(self.q_dtype.width == 8):
                    fmha_utils.cvt_f32x4_to_f8x4(
                        tTMEM_LOADrS_cvt[None, i // CVT_PER_STEP],
                        tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP],
                    )
                else:
                    s_vec = tTMEM_LOADrS_cvt[None, i // CVT_PER_STEP].load()
                    tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP].store(
                        s_vec.to(self.q_dtype)
                    )
        # Pure semaphore wait: never released, so advance the consumer cursor
        # manually past the waited stage.
        inplace_consume_pipe.consumer_wait_and_get_stage(token=inplace_peek_status)
        inplace_consume_pipe.consumer_advance()
        return local_row_sum, inplace_consume_pipe

    @cute.jit
    def softmax_step(
        self,
        stage: int,
        whether_apply_mask: bool,
        iter_args: Tuple,
        stats_args: Tuple,
        pipes: SoftmaxPipes,
        value_args: Tuple,
        atom_args: Tuple,
        tensor_args: Tuple,
    ) -> Tuple[Tuple, SoftmaxPipes]:
        """One inner-loop step of online softmax over a single ``(M, N)`` S-tile.

        Computes the numerically-stable softmax by tracking running row-max
        and row-sum, applies the optional mask, transforms via
        ``exp2(x*scale_log2 - row_max*scale_log2)``, and stores the result
        back into TMEM as the P operand for PV.

        :param stage: ``0`` for the top half / ``1`` for the bottom half of
            the S/P tile.
        :type stage: int
        :param whether_apply_mask: Apply the per-tile sliding-window /
            causal mask to ``cS`` before the row-max update.
        :type whether_apply_mask: bool
        :param iter_args: ``(cS, is_last_iter)`` -- coord tensor for this
            tile and the end-of-loop flag (controls which mbarrier signals
            fire on the last iteration).
        :type iter_args: Tuple
        :param stats_args: Running ``(row_sum, row_max)``; updated and
            returned.
        :type stats_args: Tuple
        :param pipes: Named carrier for the pipelines this step participates
            in; cursors and the ``si_peek`` token are mutated and the carrier
            is returned for loop-carrying. See :class:`SoftmaxPipes`.
        :type pipes: SoftmaxPipes
        :param value_args: ``(seqlen_k, seqlen_q, scale_softmax_log2,
            window_size_left, window_size_right, skip_softmax_threshold_log2)``.
        :type value_args: Tuple
        :param atom_args: ``(qk_thr_mma, tiled_tmem_load, thr_tmem_load,
            thr_tmem_store, thr_tmem_store_vec)`` -- pre-built MMA / TMEM
            atoms and thread slices.
        :type atom_args: Tuple
        :param tensor_args: Partitioned and raw TMEM views consumed here:
            ``tTMEM_LOADtS, tStSi, tStS_vec, tStS_P``.  The load-side
            partition feeds remaining CuTeDSL copy paths. ``partition_and_copy``
            receives raw logical TMEM views and derives thread partitions for
            non-RMEM operands internally.
        :type tensor_args: Tuple
        :return: Updated ``(stats_args, pipes)``.
        :rtype: Tuple[Tuple, SoftmaxPipes]
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
        ) = value_args
        (
            qk_thr_mma,
            tiled_tmem_load,
            thr_tmem_load,
            thr_tmem_store,
            thr_tmem_store_vec,
        ) = atom_args
        (
            tTMEM_LOADtS,
            tStSi,
            tStS_vec,
            tStS_P,
        ) = tensor_args
        tilePlikeFP32 = self.spec.qk_mma_tiler[1] // Float32.width * self.o_dtype.width
        tScS = qk_thr_mma.partition_C(cS)
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
        pipes.mma_si.consumer_wait_and_get_stage(token=pipes.si_peek)
        tTMEM_LOADrS = cute.make_rmem_tensor(tTMEM_LOADcS.shape, self.spec.qk_acc_dtype)
        old_row_max = row_max
        if whether_apply_mask:
            if cutlass.const_expr(
                self.arch >= Arch.sm_100 and self.arch <= Arch.sm_100f
            ):
                cute_ext.partition_and_copy(thr_tmem_load, tStSi, tTMEM_LOADrS)
            else:
                tTMEM_LOADrMax = cute.make_rmem_tensor(
                    cute.make_layout((1, cute.size(tTMEM_LOADrS, mode=[1]))),
                    self.spec.qk_acc_dtype,
                )
                for i in cutlass.range_constexpr(0, cute.size(tTMEM_LOADrS, mode=[1])):
                    cute.copy_atom_call(
                        tiled_tmem_load,
                        tTMEM_LOADtS[None, i, 0, 0],
                        (tTMEM_LOADrS[None, i, 0, 0], tTMEM_LOADrMax[None, i]),
                    )
            fmha_utils.FusedMask.apply_mask(
                self.spec.mask_type,
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
            row_max = cute.arch.fmax(row_max, tile_row_max)
            pipes.mma_si.consumer_release_and_advance()
            # S0 -> P1 / S1 -> P0
            pipes.inplace_produce.producer_commit_and_advance()
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
                pipes.mma_si.consumer_release_and_advance()
                # S0 -> P1 / S1 -> P0
                pipes.inplace_produce.producer_commit_and_advance()
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
                row_max = cute.arch.fmax(tile_row_max, row_max)
            else:
                tTMEM_LOADrMax = cute.make_rmem_tensor(
                    cute.make_layout((1, cute.size(tTMEM_LOADrS, mode=[1]))),
                    self.spec.qk_acc_dtype,
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
                row_max = cute.arch.fmax(tile_row_max, row_max)
                pipes.mma_si.consumer_release_and_advance()
                # S0 -> P1 / S1 -> P0
                pipes.inplace_produce.producer_commit_and_advance()

        row_max_safe = row_max
        if row_max == -cutlass.Float32.inf:
            row_max_safe = 0.0
        tTMEM_STORE_VECrS = cute.make_rmem_tensor(
            tTMEM_STORE_VECcS.shape, self.spec.qk_acc_dtype
        )
        tTMEM_STORE_VECrS[0] = old_row_max
        tTMEM_STORE_VECrS[1] = row_max_safe
        vec_i_peek_status = pipes.si_corr.producer_try_acquire()
        tTMEM_STORErS_x4 = cute.make_rmem_tensor(
            tTMEM_STOREcS.shape, self.spec.qk_acc_dtype
        )
        tTMEM_STORErS_x4_e = cute.make_tensor(
            cute.recast_ptr(tTMEM_STORErS_x4.iterator, dtype=self.q_dtype),
            tTMEM_LOADrS.layout,
        )
        scale = scale_softmax_log2
        minus_row_max_scale = (0.0 - row_max_safe) * scale
        if cutlass.const_expr(self.q_dtype.width == 8 and self.p_fp8_prescale_log2 > 0):
            minus_row_max_scale = minus_row_max_scale + self.p_fp8_prescale_log2

        ARV_COUNT = 4
        FMA_COUNT = 8
        CVT_COUNT = 8 if self.q_dtype.width == 8 else 4
        CVT_PER_STEP = 4 if self.q_dtype.width == 8 else 2
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
        pipes.si_corr.producer_acquire_and_get_stage(token=vec_i_peek_status)
        # Store row max/sum into the stage-local TMEM vector slot.
        cute_ext.partition_and_copy(thr_tmem_store_vec, tTMEM_STORE_VECrS, tStS_vec)
        # No explicit store fence: the R2T producer commit below emits
        # tcgen05.wait::st itself (LIR fences commits from the declared
        # access types).
        # Notify correction wg that row_max is ready
        pipes.si_corr.producer_commit_and_advance()

        EXP2_EMULATION_COUNT = (
            20 if self.spec.enable_ex2_emulation and not whether_apply_mask else 0
        )
        EXP2_EMULATION_OFFSET = cute.size(tTMEM_LOADrS) - EXP2_EMULATION_COUNT
        acc_scale_ = scale * (old_row_max - row_max_safe)
        acc_scale = cute.math.exp2(acc_scale_, fastmath=True) * 0.5
        if cutlass.const_expr(self.enable_sequence_barrier):
            if cutlass.const_expr(stage == 0):
                self.sequence_s0_s1_barrier.arrive_and_wait()
            else:
                self.sequence_s1_s0_barrier.arrive_and_wait()
        row_sum *= acc_scale
        local_row_sum = (row_sum, row_sum)
        local_row_sum, inplace_consume = self.apply_exp_and_cvt(
            tTMEM_LOADrS,
            tTMEM_LOADrS_cvt,
            tTMEM_STORErS_x4_e_cvt,
            stage,
            scale,
            minus_row_max_scale,
            local_row_sum,
            pipes.inplace_consume,
            EXP2_EMULATION_OFFSET,
            EXP2_EMULATION_COUNT,
            CVT_COUNT,
            CVT_PER_STEP,
            FMA_COUNT,
            ARV_COUNT,
        )
        pipes.inplace_consume = inplace_consume
        pipes.pi_mma.producer_acquire()
        # Store P from RMEM into the stage-local TMEM tile.
        cute_ext.partition_and_copy(thr_tmem_store, tTMEM_STORErS_x4, tStS_P)
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
        # No explicit store fence: the R2T producer commit below emits
        # tcgen05.wait::st itself.
        # Notify tensor core warp that softmax(S->P) is ready
        pipes.pi_mma.producer_commit_and_advance()
        if not is_last_iter:
            pipes.si_peek = pipes.mma_si.consumer_try_wait()

        stats_args = (row_sum, row_max_safe)
        return stats_args, pipes

    # For both softmax0 and softmax1 warp group
    @cute.jit
    def softmax(
        self,
        stage: int,
        tensor_args: Tuple,
        pipes: SoftmaxPipes,
        qk_thr_mma: cute.ThrMma,
        value_args: Tuple,
        mask_args: Tuple,
        sched_args: Tuple,
    ):
        """Online softmax driver for one half (``stage=0`` top, ``stage=1``
        bottom) of the S/P tile. Walks the persistent tile-scheduler loop;
        for each work tile, slices the masked / un-masked KV ranges and
        delegates each S-tile to :meth:`softmax_step`.

        :param stage: ``0`` (top half) or ``1`` (bottom half) of the
            ``2 * mma_tiler[0]`` query rows handled by this CTA.
        :type stage: int
        :param tensor_args: ``(tStS, tStSi)`` -- base TMEM score view and
            this stage's score accumulator.
        :type tensor_args: Tuple
        :param pipes: Named carrier for every pipeline this warpgroup
            participates in; threaded (and mutated) through the staged
            loops. See :class:`SoftmaxPipes`.
        :type pipes: SoftmaxPipes
        :param qk_thr_mma: Thread-sliced QK ``TiledMma`` (``get_slice(0)``).
        :type qk_thr_mma: cute.ThrMma
        :param value_args: ``(seqlen_k, seqlen_q, scale_softmax_log2,
            skip_softmax_threshold_log2)``.
        :type value_args: Tuple
        :param mask_args: ``(window_size_left, window_size_right)``.
        :type mask_args: Tuple
        :param sched_args: ``(tile_sched, work_tile)`` -- persistent
            scheduler state (advanced inside the loop).
        :type sched_args: Tuple
        """
        tStS, tStSi = tensor_args
        seqlen_k, seqlen_q, scale_softmax_log2, skip_softmax_threshold_log2 = value_args
        window_size_left, window_size_right = mask_args
        tile_sched, work_tile = sched_args

        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (
            self.spec.threads_per_warp * len(self.spec.softmax0_warp_ids)
        )

        cS_base = cute.make_identity_tensor(
            (self.spec.qk_mma_tiler[0], self.spec.qk_mma_tiler[1])
        )
        tilePlikeFP32 = self.spec.qk_mma_tiler[1] // 32 * self.o_dtype.width
        tScS = qk_thr_mma.partition_C(cS_base)
        tStS_vec_layout = cute.composition(tStS.layout, cute.make_layout((128, 2)))
        tmem_vec_offset = (
            self.spec.tmem_vec0_offset if stage == 0 else self.spec.tmem_vec1_offset
        )
        tStS_vec = cute.make_tensor(tStS.iterator + tmem_vec_offset, tStS_vec_layout)
        tScS_vec_layout = cute.composition(tScS.layout, cute.make_layout((128, 2)))
        tScS_vec = cute.make_tensor(tScS.iterator, tScS_vec_layout)
        tStS_P_layout = cute.composition(
            tStS.layout, cute.make_layout((128, tilePlikeFP32))
        )
        tmem_p_offset = (
            self.spec.tmem_p0_offset if stage == 0 else self.spec.tmem_p1_offset
        )
        tStS_P = cute.make_tensor(tStS.iterator + tmem_p_offset, tStS_P_layout)
        if cutlass.const_expr(self.arch >= Arch.sm_100 and self.arch <= Arch.sm_100f):
            tmem_load_atom = cute.make_copy_atom(
                tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(32)),
                self.spec.qk_acc_dtype,
            )
        else:
            tmem_load_atom = cute.make_copy_atom(
                tcgen05.copy.LdRed32x32bOp(
                    tcgen05.copy.Repetition(32), redOp=tcgen05.TmemLoadRedOp.MAX
                ),
                self.spec.qk_acc_dtype,
            )

        tiled_tmem_load = tcgen05.make_tmem_copy(tmem_load_atom, tStSi)
        thr_tmem_load = tiled_tmem_load.get_slice(thread_idx)
        tTMEM_LOADtS = thr_tmem_load.partition_S(tStSi)
        tmem_store_vec_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(2)),
            self.spec.qk_acc_dtype,
        )
        tiled_tmem_store_vec = tcgen05.make_tmem_copy(tmem_store_vec_atom, tStS_vec)
        thr_tmem_store_vec = tiled_tmem_store_vec.get_slice(thread_idx)
        tTMEM_STORE_VECcS = thr_tmem_store_vec.partition_S(tScS_vec)
        tmem_store_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(32)),
            self.spec.qk_acc_dtype,
        )
        tiled_tmem_store = tcgen05.make_tmem_copy(tmem_store_atom, tStS_P)
        thr_tmem_store = tiled_tmem_store.get_slice(thread_idx)
        if cutlass.const_expr(self.enable_sequence_barrier):
            if cutlass.const_expr(stage == 1):
                self.sequence_s0_s1_barrier.arrive()
        while work_tile.is_valid_tile:
            curr_block_coord = work_tile.tile_idx
            seqlen_k_ = seqlen_k
            seqlen_q_ = seqlen_q
            continue_cond = seqlen_k_ <= 0
            if not continue_cond:
                logical_offset = (
                    curr_block_coord[0] * self.spec.cta_tiler[0]
                    + stage * self.spec.qk_mma_tiler[0],
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
                )
                atom_args = (
                    qk_thr_mma,
                    tiled_tmem_load,
                    thr_tmem_load,
                    thr_tmem_store,
                    thr_tmem_store_vec,
                )
                tensor_args_ = (
                    tTMEM_LOADtS,
                    tStSi,
                    tStS_vec,
                    tStS_P,
                )
                st_cnt, end_cnt, ld_mask_cnt, unmask_cnt, tl_mask_cnt = (
                    fmha_utils.FusedMask.get_masked_info(
                        self.spec.mask_type,
                        curr_block_coord,
                        self.spec.cta_tiler,
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
                    pipes: SoftmaxPipes,
                    inner_fn: Callable,
                    value_args: Tuple,
                    atom_args: Tuple,
                    tensor_args: Tuple,
                    cS: cute.Tensor,
                ) -> Tuple[Tuple, SoftmaxPipes]:
                    start_index, iter_num, upper_bound = loop_args
                    for i in cutlass.range(
                        start_index, start_index + iter_num, 1, unroll=1
                    ):
                        cS_iter = cute.domain_offset(
                            (0, i * self.spec.qk_mma_tiler[1]), cS
                        )
                        iter_args = (cS_iter, i == upper_bound - 1)
                        stats_args, pipes = inner_fn(
                            stage,
                            whether_apply_mask,
                            iter_args,
                            stats_args,
                            pipes,
                            value_args,
                            atom_args,
                            tensor_args,
                        )
                    return stats_args, pipes

                softmax_step_fn = self.softmax_step
                softmax_loop_fn = partial(
                    softmax_loop,
                    inner_fn=softmax_step_fn,
                    value_args=value_args_,
                    atom_args=atom_args,
                    tensor_args=tensor_args_,
                    cS=cS,
                )
                pipes.si_peek = pipes.mma_si.consumer_try_wait()
                if cutlass.const_expr(stage == 1):
                    # Pure semaphore wait: never released, so advance the
                    # consumer cursor manually past the waited stage.
                    pipes.inplace_consume.consumer_wait()
                    pipes.inplace_consume.consumer_state = (
                        pipes.inplace_consume.increment_state(
                            pipes.inplace_consume.consumer_state
                        )
                    )
                # 1. Leading mask loop
                loop_args = (st_cnt, ld_mask_cnt, end_cnt)
                stats_args, pipes = softmax_loop_fn(True, loop_args, stats_args, pipes)
                # 2. Unmasked loop
                loop_args = (st_cnt + ld_mask_cnt, unmask_cnt, end_cnt)
                stats_args, pipes = softmax_loop_fn(False, loop_args, stats_args, pipes)
                # 3. Trailing mask loop
                loop_args = (st_cnt + ld_mask_cnt + unmask_cnt, tl_mask_cnt, end_cnt)
                stats_args, pipes = softmax_loop_fn(True, loop_args, stats_args, pipes)

                if cutlass.const_expr(stage == 0):
                    pipes.inplace_produce.producer_commit_and_advance()
                # 4. Copy the final stats for correction epilog
                tTMEM_STORE_VECrS = cute.make_rmem_tensor(
                    tTMEM_STORE_VECcS.shape, self.spec.qk_acc_dtype
                )
                tTMEM_STORE_VECrS[0] = stats_args[0]
                tTMEM_STORE_VECrS[1] = stats_args[1]
                pipes.si_corr.producer_acquire()
                cute_ext.partition_and_copy(
                    thr_tmem_store_vec, tTMEM_STORE_VECrS, tStS_vec
                )
                # No explicit store fence: the R2T producer commit below
                # emits tcgen05.wait::st itself.
                pipes.si_corr.producer_commit_and_advance()
            # End of if not continue_cond
            # Advance to next tile
            tile_sched.advance_to_next_work()
            work_tile = tile_sched.get_current_work()
        # End of persistent scheduler loop

    @cute.jit
    def correction_rescale(
        self,
        thr_mma: cute.ThrMma,
        thr_tmem_load_vec,
        scale_softmax_log2: Float32,
        tensor_args: Tuple,
        si_corr_pipe,
        mma_corr_pipe,
    ):
        """Rescale the running PV partial when the row-max changes.

        Online softmax tracks a running ``row_max`` per query row. When a
        new KV block bumps the max, the previously-accumulated PV partial
        (in TMEM) is too large by ``exp2((old_max - new_max) * scale_log2)``;
        this method walks the PV TMEM buffer in slices and applies that
        rescale in place, then releases ``vec_i`` and ``Oi`` for the next
        round.

        :param thr_mma: Thread-sliced PV ``TiledMma`` (``get_slice(0)``).
        :type thr_mma: cute.ThrMma
        :param thr_tmem_load_vec: Thread-sliced TMEM-load copy for the
            row-max/row-sum vector slot.
        :type thr_tmem_load_vec: cute.ThrCopy
        :param scale_softmax_log2: ``scale_softmax * log2(e)``.
        :type scale_softmax_log2: Float32
        :param tensor_args: ``(tOtO, tStS_vec_i, tTMEM_LOAD_VECcS)`` --
            PV-accumulator TMEM, raw (iterator-offset-shifted) row-vec slot
            for this stage, and the partition_D shape used to size RMEM
            staging.
        :type tensor_args: Tuple[cute.Tensor, cute.Tensor, cute.Tensor]
        :param si_corr_pipe: softmax -> correction row-vec pipeline (consumer
            side; released here).
        :param mma_corr_pipe: PV MMA -> correction O pipeline (consumer side;
            released here).
        """
        tOtO, tStS_vec_i, tTMEM_LOAD_VECcS = tensor_args

        pv_tiled_mma_shape = (
            self.spec.pv_mma_tiler[0],
            self.spec.pv_mma_tiler[1],
        )
        cO = cute.make_identity_tensor(pv_tiled_mma_shape)
        tOcO = thr_mma.partition_C(cO)
        corr_tile_size = 16  # tuneable parameter
        tmem_load_atom = cute.make_copy_atom(
            tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(corr_tile_size)),
            self.spec.pv_acc_dtype,
        )
        tmem_store_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(corr_tile_size)),
            self.spec.pv_acc_dtype,
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
        thread_idx = tidx % (
            self.spec.threads_per_warp * len(self.spec.correction_warp_ids)
        )
        thr_tmem_load = tiled_tmem_load.get_slice(thread_idx)
        thr_tmem_store = tiled_tmem_store.get_slice(thread_idx)
        tTMEM_LOADcO = thr_tmem_load.partition_D(tOcO_i)
        tTMrO = cute.make_rmem_tensor(
            (tTMEM_LOADcO.shape, 128 // corr_tile_size), self.spec.pv_acc_dtype
        )
        tTMEM_LOAD_VECrS = cute.make_rmem_tensor(
            tTMEM_LOAD_VECcS.shape, self.spec.qk_acc_dtype
        )
        # Wait for vec_i (row_wise current max & previous max)
        si_corr_pipe.consumer_wait()
        # Load current/previous row max from the stage-local TMEM vector slot.
        cute_ext.partition_and_copy(thr_tmem_load_vec, tStS_vec_i, tTMEM_LOAD_VECrS)
        # No explicit load fence: the T2R consumer release below emits
        # tcgen05.wait::ld itself.
        si_corr_pipe.consumer_release_and_advance()
        # Wait for Oi
        mma_corr_pipe.consumer_wait()
        vote_ballot_cnt = cute.arch.vote_ballot_sync(
            tTMEM_LOAD_VECrS[0] != tTMEM_LOAD_VECrS[1]
        )
        should_rescale = vote_ballot_cnt != 0
        if should_rescale:
            scale_ = scale_softmax_log2 * (tTMEM_LOAD_VECrS[0] - tTMEM_LOAD_VECrS[1])
            scale = cute.math.exp2(scale_, fastmath=True)
            for i in range(self.spec.cta_tiler[2] // corr_tile_size):
                tTMrO_i_ = tTMrO[None, i]
                tTMrO_i_layout = cute.composition(
                    tTMrO_i_.layout, cute.make_layout(tTMrO.shape[0])
                )
                tTMrO_i = cute.make_tensor(tTMrO_i_.iterator, tTMrO_i_layout)
                # Shift the raw PV TMEM window to this corr_tile_size slice.
                tOtO_i_iter_shifted = cute.make_tensor(
                    tOtO_i.iterator + i * corr_tile_size, tOtO_i.layout
                )

                cute_ext.partition_and_copy(thr_tmem_load, tOtO_i_iter_shifted, tTMrO_i)
                for j in range(0, cute.size(tTMrO_i), 2):
                    tTMrO_i[j], tTMrO_i[j + 1] = cute.arch.mul_packed_f32x2(
                        (tTMrO_i[j], tTMrO_i[j + 1]),
                        (scale, scale),
                    )
                cute_ext.partition_and_copy(
                    thr_tmem_store, tTMrO_i, tOtO_i_iter_shifted
                )
        # Release Oi
        cute.arch.fence_view_async_tmem_store()
        mma_corr_pipe.consumer_release_and_advance()
        return (si_corr_pipe, mma_corr_pipe)

    @cute.jit
    def correction_epilog(
        self,
        thr_mma: cute.ThrMma,
        thr_tmem_load_vec,
        tensor_args: Tuple,
        si_corr_pipe,
        mma_corr_pipe,
        corr_epi_pipe,
        value_args: Tuple,
    ):
        """Apply final scaling and transformation to attention output.

        Writes to shared memory and signals the epilogue warp for TMA store.

        :param thr_mma: Thread MMA operation for the computation
        :type thr_mma: cute.ThrMma
        :param thr_tmem_load_vec: Thread-sliced TMEM load copy for the row-wise vec
            (pre-sliced, used by cute_ext.partition_and_copy).
        :type thr_tmem_load_vec: cute.ThrCopy
        :param tensor_args: Tuple containing (tOtO, tStS_vec_i (raw), tTMEM_LOAD_VECcS,
            sO, mLSE, mSink)
        :type tensor_args: Tuple
        :param si_corr_pipe: softmax -> correction row-vec pipeline (consumer
            side; released here).
        :param mma_corr_pipe: PV MMA -> correction O pipeline (consumer side;
            released here).
        :param corr_epi_pipe: correction -> epilogue O pipeline (producer
            side; committed here after the SMEM stores).
        :param value_args: Tuple containing (row_idx, seqlen_q, blk_coord, scale_softmax, scale_output)
        :type value_args: Tuple
        """
        tOtO, tStS_vec_i, tTMEM_LOAD_VECcS, dest_O, mLSE, mSink = tensor_args
        row_idx, seqlen_q, blk_coord, scale_softmax, scale_output = value_args

        pv_tiled_mma_shape = (
            self.spec.pv_mma_tiler[0],
            self.spec.pv_mma_tiler[1],
        )
        cO = cute.make_identity_tensor(pv_tiled_mma_shape)

        corr_tile_size = 32 * 8 // self.o_dtype.width
        tOdO = thr_mma.partition_C(dest_O)
        tOcO = thr_mma.partition_C(cO)
        tOtO_i = cute.logical_divide(tOtO, cute.make_layout((128, corr_tile_size)))
        tOcO_i = cute.logical_divide(tOcO, cute.make_layout((128, corr_tile_size)))
        tOdO_i = cute.logical_divide(tOdO, cute.make_layout((128, corr_tile_size)))

        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (
            self.spec.threads_per_warp * len(self.spec.correction_warp_ids)
        )
        epi_subtile = (self.spec.epi_tile[0], corr_tile_size)
        tmem_copy_atom = sm100_utils.get_tmem_load_op(
            self.spec.pv_mma_tiler,
            self.o_layout,
            self.o_dtype,
            self.spec.pv_acc_dtype,
            epi_subtile,
            use_2cta_instrs=False,
        )
        tiled_tmem_load = tcgen05.make_tmem_copy(
            tmem_copy_atom, tOtO_i[(None, None), 0]
        )
        thr_tmem_load = tiled_tmem_load.get_slice(thread_idx)
        tTMEM_LOADdO = thr_tmem_load.partition_D(tOdO_i[(None, None), None])
        tTMEM_LOADoO = thr_tmem_load.partition_D(tOcO_i[(None, None), None])

        smem_copy_atom = sm100_utils.get_smem_store_op(
            self.o_layout, self.o_dtype, self.spec.pv_acc_dtype, tiled_tmem_load
        )
        tiled_smem_store = cute.make_tiled_copy_D(smem_copy_atom, tiled_tmem_load)

        # Wait for vec_i (row_wise global sum)
        si_corr_pipe.consumer_wait()
        tTMEM_LOAD_VECrS = cute.make_rmem_tensor(
            tTMEM_LOAD_VECcS.shape, self.spec.qk_acc_dtype
        )
        # Load final row sum/max from the stage-local TMEM vector slot.
        cute_ext.partition_and_copy(thr_tmem_load_vec, tStS_vec_i, tTMEM_LOAD_VECrS)
        # No explicit load fence: the T2R consumer release below emits
        # tcgen05.wait::ld itself.
        si_corr_pipe.consumer_release_and_advance()

        # Wait for Oi, acquire epilogue slot
        mma_corr_pipe.consumer_wait()
        corr_epi_pipe.producer_acquire()
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
        # A fully-masked query row has row_sum == 0 (every score was -inf, so
        # every probability is 0). The divide above yields inf, which would make
        # O = 0 * inf = NaN; force scale = 0 so that row's O is defined as 0.
        if row_sum == 0.0:
            scale = Float32(0.0)

        for i in range(self.spec.cta_tiler[2] // corr_tile_size):
            # Keep the logical M/N modes and select the i-th corr_tile_size
            # slice of O for TMEM load and SMEM store.
            tOtO_raw_i = tOtO_i[(None, None), i]
            tOdO_raw_i = tOdO_i[(None, None), i]
            tTMEM_LOADdO_i = tTMEM_LOADdO[None, 0, 0, i]
            tTMrO = cute.make_rmem_tensor(
                tTMEM_LOADoO[None, 0, 0, i].shape, self.spec.pv_acc_dtype
            )
            cute_ext.partition_and_copy(thr_tmem_load, tOtO_raw_i, tTMrO)
            for j in range(0, cute.size(tTMrO), 2):
                tTMrO[j], tTMrO[j + 1] = cute.arch.mul_packed_f32x2(
                    (tTMrO[j], tTMrO[j + 1]),
                    (scale, scale),
                )
            tDMrO = cute.make_rmem_tensor(tTMrO.shape, self.o_dtype)
            o_vec = tTMrO.load()
            tDMrO.store(o_vec.to(self.o_dtype))
            # RMEM→SMEM via tiled_smem_store. partition_D was applied with
            # tiled_tmem_load, so the destination domain matches partition_D
            # under tiled_tmem_load. The copy atom (smem_store) is bound to
            # tiled_smem_store and the src/dst pair is already partitioned;
            # there is no clean "thread-sliced copy + raw dst" mapping here
            # without restructuring the atom — keep cute.copy.
            cute.copy(tiled_smem_store, tDMrO, tTMEM_LOADdO_i)

        if cutlass.const_expr(mLSE is not None):
            scaled_tmp = scale_softmax * tTMEM_LOAD_VECrS[1]
            # Convert LSE from natural log to log2 space, matching the
            # convention expected by downstream attention serving backends.
            lse = (cute.math.log(row_sum, fastmath=True) + scaled_tmp) * Float32(
                1.4426950408889634
            )
            # Pre-scale correction: row_sum was inflated by 2^offset, so the
            # log2-space LSE is too large by exactly `p_fp8_prescale_log2`.
            if cutlass.const_expr(
                self.q_dtype.width == 8 and self.p_fp8_prescale_log2 > 0
            ):
                lse = lse - self.p_fp8_prescale_log2
            if row_idx < seqlen_q:
                mLSE[row_idx, blk_coord[2]] = lse
        # fence view async shared, release Oi, commit final to epilogue
        cute.arch.fence_view_async_shared()
        mma_corr_pipe.consumer_release_and_advance()
        corr_epi_pipe.producer_commit_and_advance()
        return (si_corr_pipe, mma_corr_pipe, corr_epi_pipe)

    def check_supported_dtypes(
        self,
        in_dtype: Type[cutlass.Numeric],
        out_dtype: Type[cutlass.Numeric],
        qk_acc_dtype: Type[cutlass.Numeric],
        pv_acc_dtype: Type[cutlass.Numeric],
    ):
        if in_dtype not in {cutlass.Float8E4M3FN, cutlass.Float16, cutlass.BFloat16}:
            raise testing.CantImplementError("Unsupported in_dtype")
        if out_dtype not in {cutlass.Float8E4M3FN, cutlass.Float16, cutlass.BFloat16}:
            raise testing.CantImplementError("Unsupported out_dtype")
        if qk_acc_dtype not in {cutlass.Float32}:
            raise testing.CantImplementError("Unsupported qk_acc_dtype")
        if pv_acc_dtype not in {cutlass.Float32}:
            raise testing.CantImplementError("Unsupported pv_acc_dtype")

    def check_invalid_shape(
        self,
        in_dtype: Type[cutlass.Numeric],
        q_shape: Tuple[int, int, int, int],
        k_shape: Tuple[int, int, int, int],
    ):
        # Shapes are passed around this example as (batch, seq_len, num_heads, head_dim).
        if len(q_shape) != 4 or len(k_shape) != 4:
            raise testing.CantImplementError("q_shape and k_shape must be 4D")

        b, s_q, h_q, d = q_shape
        b_, s_k, h_k, d_ = k_shape

        if min(b, s_q, h_q, d, b_, s_k, h_k, d_) <= 0:
            raise testing.CantImplementError(
                "q_shape and k_shape dimensions must be positive"
            )
        if b != b_:
            raise testing.CantImplementError("q & k must have the same batch size")
        if d != d_:
            raise testing.CantImplementError("q & k must have the same head dimension")
        if d not in {32, 64, 128, 192}:
            raise testing.CantImplementError("Unsupported head dimension")
        if h_q % h_k != 0:
            raise testing.CantImplementError("h_q must be divisible by h_k")
        if d == 192 and in_dtype not in {cutlass.Float8E4M3FN}:
            raise testing.CantImplementError("unimplemented dtypes for headdim 192")

    def check_mma_tiler(self):
        if self.spec.qk_mma_tiler[:2] != (128, 128):
            raise testing.CantImplementError("mma_tiler_mn must be (128, 128)")

    def can_implement(
        self,
        q_shape: Tuple[int, int, int, int],
        k_shape: Tuple[int, int, int, int],
        in_dtype: Type[cutlass.Numeric],
        out_dtype: Type[cutlass.Numeric],
        qk_acc_dtype: Type[cutlass.Numeric],
        pv_acc_dtype: Type[cutlass.Numeric],
    ) -> bool:
        """Static feasibility check for a Q/K shape and dtype combination.

        Returns ``True`` iff this kernel can be compiled and run for the
        given configuration without hitting an unsupported dtype, head dim,
        or shape constraint. Encodes the same constraints as
        :meth:`check_supported_dtypes` and :meth:`check_invalid_shape`
        without forcing a compile.

        :param q_shape: Query shape ``(B, S_q, H, D)``.
        :type q_shape: Tuple[int, int, int, int]
        :param k_shape: Key shape ``(B, S_k, H_k, D)``.
        :type k_shape: Tuple[int, int, int, int]
        :param in_dtype: Q/K/V dtype.
        :type in_dtype: Type[cutlass.Numeric]
        :param out_dtype: O dtype.
        :type out_dtype: Type[cutlass.Numeric]
        :param qk_acc_dtype: Q @ K^T accumulator dtype.
        :type qk_acc_dtype: Type[cutlass.Numeric]
        :param pv_acc_dtype: P @ V accumulator dtype.
        :type pv_acc_dtype: Type[cutlass.Numeric]
        :return: ``True`` if implementable, else ``False``.
        :rtype: bool
        """
        try:
            # Skip unsupported types
            self.check_supported_dtypes(
                in_dtype,
                out_dtype,
                qk_acc_dtype,
                pv_acc_dtype,
            )
            self.check_mma_tiler()
            # Skip invalid shape
            self.check_invalid_shape(
                in_dtype,
                q_shape,
                k_shape,
            )
        except testing.CantImplementError:
            return False
        return True


def run(
    q_shape: Tuple[int, int, int, int],
    k_shape: Tuple[int, int, int, int],
    in_dtype: Type[cutlass.Numeric],
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

    :param q_shape: Query tensor shape ``(B, S_q, H, D)``: batch, query
        seqlen, number of heads, head dim.
    :type q_shape: Tuple[int, int, int, int]
    :param k_shape: Key tensor shape ``(B, S_k, H_k, D)``: batch, key
        seqlen, number of K/V heads (``H`` must be divisible by ``H_k``),
        head dim.
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
    :param enable_ex2_emulation: Whether to enable ex2 emulation
    :type enable_ex2_emulation: bool
    :param enable_skip_correction: Unsupported skip-softmax option;
        active use raises ``NotImplementedError``.
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
    :param skip_softmax_threshold: Unsupported skip-softmax option;
        active use raises ``NotImplementedError``.
    :type skip_softmax_threshold: float
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
    :param stats_skip_softmax_ratio: Unsupported skip-softmax option;
        active use raises ``NotImplementedError``.
    :type stats_skip_softmax_ratio: bool
    :raises ValueError: If input shapes are incompatible or head dimension is unsupported
    :raises RuntimeError: If GPU is unavailable for computation
    :return: Execution time of the FMHA kernel in microseconds
    :rtype: float
    """

    if kwargs:
        unexpected = ", ".join(sorted(kwargs))
        raise TypeError(f"Unexpected keyword argument(s): {unexpected}")

    if (
        enable_skip_correction
        or stats_skip_softmax_ratio
        or skip_softmax_threshold is not None
    ):
        raise NotImplementedError(_SKIP_SOFTMAX_UNSUPPORTED_MSG)

    print("Running Blackwell SM100 FMHA test with:")
    print(f"  q_shape: {q_shape}")
    print(f"  k_shape: {k_shape}")
    print(f"  in_dtype: {in_dtype}")
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
    if len(q_shape) != 4 or len(k_shape) != 4:
        raise testing.CantImplementError("q_shape and k_shape must be 4D")
    if mma_tiler_mn != (128, 128):
        raise testing.CantImplementError("mma_tiler_mn must be (128, 128)")

    b, s_q, h_q, d = q_shape
    b_, s_k, h_k, d_ = k_shape
    if min(b, s_q, h_q, d, b_, s_k, h_k, d_) <= 0:
        raise testing.CantImplementError(
            "q_shape and k_shape dimensions must be positive"
        )
    if b != b_:
        raise testing.CantImplementError("q & k must have the same batch size")
    if d != d_:
        raise testing.CantImplementError("q & k must have the same head dimension")
    if d not in {32, 64, 128, 192}:
        raise testing.CantImplementError("Unsupported head dimension")
    if d == 192 and in_dtype not in {cutlass.Float8E4M3FN}:
        raise testing.CantImplementError("unimplemented dtypes for headdim 192")
    if h_q % h_k != 0:
        raise testing.CantImplementError("h_q must be divisible by h_k")

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
        # Create dtype cute & torch tensor (gpu)
        _, torch_tensor = cutlass_torch.cute_tensor_like(
            f32_torch_tensor,
            dtype,
            is_dynamic_layout,
            assumed_align=32,
        )
        cute_tensor = from_dlpack(torch_tensor, assumed_align=32)
        cute_tensor.element_type = dtype
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
    # lse: (b, s_q, h_k, h_r)
    qo_shape = (b, s_q, h_k, h_r, d)
    o_shape = (b, s_q, h_k, h_r, dv)
    kv_shape = (b, s_k, h_k, 1, d)
    v_shape = (b, s_k, h_k, 1, dv)
    lse_shape = (b, s_q, h_k, h_r)

    # Create tensors with random int initialization if not skip ref check
    # to ensure the refcheck is stable via different problem shapes & random seeds.
    use_random = not skip_ref_check
    q_ref, q_tensor, q_torch = create_and_permute_tensor(
        qo_shape,
        in_dtype,
        is_dynamic_layout=True,
        use_random_int=use_random,
    )
    k_ref, k_tensor, k_torch = create_and_permute_tensor(
        kv_shape,
        in_dtype,
        is_dynamic_layout=True,
        use_random_int=use_random,
    )
    v_ref, v_tensor, v_torch = create_and_permute_tensor(
        v_shape,
        in_dtype,
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
        if s_k % mma_tiler_mn[1] != 0:
            mask_type = fmha_utils.MaskEnum.RESIDUAL_MASK

    s_q_list = [s_q] * b
    s_k_list = [s_k] * b

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

    fmha = BlackwellFusedMultiHeadAttentionForward(
        qk_acc_dtype,
        pv_acc_dtype,
        mma_tiler_mn,
        d if d == dv else (d, dv),
        is_persistent,
        mask_type,
        enable_ex2_emulation,
        enable_skip_correction,
    )

    can_implement = fmha.can_implement(
        q_shape,
        k_shape,
        in_dtype,
        out_dtype,
        qk_acc_dtype,
        pv_acc_dtype,
    )

    if not can_implement:
        raise testing.CantImplementError(
            f"The current config which is invalid/unsupported: "
            f"q_shape = {q_shape}, k_shape = {k_shape}, in_dtype = {in_dtype}, out_dtype = {out_dtype}, "
            f"qk_acc_dtype = {qk_acc_dtype}, pv_acc_dtype = {pv_acc_dtype}"
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

    problem_size = (
        b,
        s_q,
        s_q,  # s_lse (== s_q for fixed-seqlen)
        s_k,
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
        lse_tensor if lse_calculation else None,
        sink_tensor if enable_sink else None,
        scale_softmax_log2,
        scale_softmax,
        scale_output,
        skip_softmax_threshold_log2,
        window_size_left if window_size_left is None else Int32(window_size_left),
        window_size_right if window_size_right is None else Int32(window_size_right),
        current_stream,
        use_pdl,
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
        sink_ref=None,
    ):
        # q: (b, s_q, h_k, h_r, d), k: (b, s_k, h_k, 1, d), v: (b, s_k, h_k, 1, dv)
        batch, s_q_max, s_lse_max, s_k_max, h_q, h_k, d, dv = problem_size
        h_r = h_q // h_k

        # Run the per-batch reference math on the GPU when available: the
        # dense (s_q, s_k, h) score tensor makes a CPU reference infeasible at
        # long-context lengths (8K+). Results are stored back to CPU, and
        # f32 matmul precision is unaffected (TF32 is off by default).
        compute_device = "cuda" if torch.cuda.is_available() else "cpu"

        ref_o_shape = list(q.shape[:-1]) + [v.shape[-1]]  # same as q but with dv
        ref_o = torch.zeros(ref_o_shape)
        ref_lse = None
        if lse_calculation:
            ref_lse = torch.zeros(list(lse_shape))

        for batch_idx in range(batch):
            b_idx = batch_idx
            q_offset = 0
            k_offset = 0
            cur_s_q = s_q_max
            cur_s_k = s_k_max

            # Slice per-batch data: (s, h_k, h_r, d)
            cur_q = q[b_idx, q_offset : q_offset + cur_s_q, :, :, :].to(compute_device)
            cur_k = k[b_idx, k_offset : k_offset + cur_s_k, :, :, :].to(compute_device)
            cur_v = v[b_idx, k_offset : k_offset + cur_s_k, :, :, :].to(compute_device)

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
                q_coords = torch.arange(0, cur_s_q, device=compute_device).view(-1, 1)
                k_coords = torch.arange(0, cur_s_k, device=compute_device).view(1, -1)
                offset = 0 if not bottom_right_align else cur_s_k - cur_s_q
                if window_size_left is None:
                    _mask = k_coords > q_coords + offset + window_size_right
                elif window_size_right is None:
                    _mask = k_coords < q_coords + offset - window_size_left
                else:
                    _mask = (k_coords > q_coords + offset + window_size_right) | (
                        k_coords < q_coords + offset - window_size_left
                    )
                cur_s = cur_s.masked_fill(_mask.unsqueeze(-1).unsqueeze(-1), -torch.inf)

            cur_lse = None
            if sink_ref is not None:
                # Concat sink as an extra logit, then softmax - numerically stable
                # sink_ref shape: (h_q,) = (h_k * h_r,) -> (1, 1, h_k, h_r)
                # sink is already in the scaled logit space, no need to multiply scale_softmax
                cur_sink = (
                    sink_ref.to(compute_device)
                    .reshape(h_k, h_r)
                    .unsqueeze(0)
                    .unsqueeze(0)
                )
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
                    # Use log2 space for LSE, matching the convention expected
                    # by downstream attention serving backends.
                    cur_lse = (
                        torch.logsumexp(cur_s, dim=1) * 1.4426950408889634
                    )  # reduce over s_k
                cur_p = torch.softmax(cur_s, dim=1)  # softmax over s_k

            # (s_q, s_k, h_k, h_r) x (s_k, h_k, h_r, dv) -> (s_q, h_k, h_r, dv)
            cur_o = torch.einsum("qkhl,khld->qhld", cur_p, cur_v) * scale_output

            ref_o[b_idx, q_offset : q_offset + cur_s_q, :, :, :] = cur_o.cpu()
            if lse_calculation:
                # cur_lse: (s_q, h_k, h_r)
                ref_lse[b_idx, q_offset : q_offset + cur_s_q, :, :] = cur_lse.cpu()

        return ref_o, ref_lse

    compiled_fmha(
        q_tensor,
        k_tensor,
        v_tensor,
        o_tensor,
        problem_size,
        lse_tensor if lse_calculation else None,
        sink_tensor if enable_sink else None,
        scale_softmax_log2,
        scale_softmax,
        scale_output,
        skip_softmax_threshold_log2,
        window_size_left if window_size_left is None else Int32(window_size_left),
        window_size_right if window_size_right is None else Int32(window_size_right),
        current_stream,
        use_pdl,
    )
    if not skip_ref_check:
        # Execute kernel once for reference checking
        print("Verifying results...")

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
            tolerance = 0.13

        # Assert close results
        torch.testing.assert_close(o_result, o_ref, atol=tolerance, rtol=1e-05)
        if lse_calculation:
            torch.testing.assert_close(
                lse_torch.cpu(), lse_ref, atol=tolerance, rtol=1e-05
            )
        print("Results verified successfully!")

    # Benchmark on a dedicated non-default stream so cute.testing can capture
    # the launch loop into a CUDA graph (graph capture is not permitted on the
    # default stream). Matches the decode kernels' perf methodology and avoids
    # a CPU-launch-bound floor (the DSL per-launch dispatch cost, ~tens of us)
    # that otherwise dominates small / short-sequence problems.
    profile_torch_stream = torch.cuda.Stream()
    profile_stream = cuda.CUstream(profile_torch_stream.cuda_stream)

    def generate_tensors():
        _, q_tensor_workspace, _ = create_and_permute_tensor(
            qo_shape,
            in_dtype,
            is_dynamic_layout=True,
            use_random_int=False,
        )
        _, k_tensor_workspace, _ = create_and_permute_tensor(
            kv_shape,
            in_dtype,
            is_dynamic_layout=True,
            use_random_int=False,
        )
        _, v_tensor_workspace, _ = create_and_permute_tensor(
            v_shape,
            in_dtype,
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
            profile_stream,
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

    # Multi-iteration perf runs use CUDA graphs to remove the per-launch DSL
    # dispatch overhead that would otherwise floor small problems; single-shot
    # functional runs (iterations == 1) keep the simpler CUDA-event path. A
    # captured graph cannot cycle Python-side workspaces, so skip graphs when
    # L2-cold rotation is requested (workspace_count > 1).
    use_cuda_graphs = iterations > 1 and workspace_count == 1
    exec_time = testing.benchmark(
        compiled_fmha,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=profile_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        use_cuda_graphs=use_cuda_graphs,
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

    parser = argparse.ArgumentParser(description="Example of FMHA on Blackwell.")

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
        help="Temporarily unsupported in this FMHA example.",
    )

    parser.add_argument(
        "--is_persistent",
        action="store_true",
        help="Use the persistent tile scheduler.",
    )

    parser.add_argument(
        "--is_causal",
        action="store_true",
        help="Whether to use causal masking.",
    )

    parser.add_argument(
        "--bottom_right_align",
        action="store_true",
        help=(
            "Whether to use bottom-right alignment; when enabled, the end of Q "
            "is aligned with the end of K."
        ),
    )

    parser.add_argument(
        "--lse_calculation",
        action="store_true",
        help="Whether to calculate LSE.",
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
        type=parse_comma_separated_ints,
        default=(1, 256, 8, 128),
        help="Shape of Q (B, S_q, H, D)",
    )

    parser.add_argument(
        "--k_shape",
        type=parse_comma_separated_ints,
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
        help="Temporarily unsupported in this FMHA example.",
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
        help="Temporarily unsupported in this FMHA example.",
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

    run(
        args.q_shape,
        args.k_shape,
        args.in_dtype,
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
