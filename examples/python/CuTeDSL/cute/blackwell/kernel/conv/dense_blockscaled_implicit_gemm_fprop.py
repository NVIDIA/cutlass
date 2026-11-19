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
from typing import Optional, Tuple, Type, Union, Literal
from functools import lru_cache
import cuda.bindings.driver as cuda
import sys
import os

import torch
import torch.nn.functional as F

import cutlass
import cutlass.cute as cute
from cutlass import testing
from cutlass.cute.runtime import from_dlpack
import cutlass.torch as cutlass_torch
from cutlass.memory import (
    SmemAllocator,
    TmemAllocator,
    get_num_tmem_alloc_cols,
    get_smem_capacity_in_bytes,
)
from cutlass.tensor_utils import LayoutEnum
from cutlass.cute.nvgpu import cpasync, tcgen05
import cutlass.pipeline as pipeline
from dataclasses import dataclass
from cutlass.pipeline import (
    Agent,
    CooperativeGroup,
    PipelineOp,
    PipelineState,
    PipelineAsync,
    agent_sync,
    pipeline_init_arrive,
    pipeline_init_wait,
)
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
from pathlib import Path

if __name__ == "__main__":
    # `helpers` sits at the examples/CuTeDSL root; running this file as a
    # script only puts its own directory on sys.path.
    cutedsl_dir = str(Path(__file__).resolve().parents[4])
    if cutedsl_dir not in sys.path:
        sys.path.insert(0, cutedsl_dir)

from helpers.dynamic_persistent_tile_scheduler import (
    ClcDynamicPersistentTileScheduler,
    ClcDynamicPersistentTileSchedulerParams,
)
from helpers.conv_helpers import (
    EPILOGUE_ACTIVATIONS,
    SMEM_BUFFER_ALIGN_BYTES,
    SMEM_VECTOR_ALIGN_BYTES,
    add_dummy_batch_dimension,
    bias_dtype_for_output,
    check_conv_geometry,
    check_im2col_descriptor_limits,
    check_cluster_shape,
    check_preferred_cluster_problem_size,
    check_swizzle_size,
    check_tensor_alignment,
    compute_grid,
    compute_zpq,
    create_cute_tensor,
    create_scale_factor_tensor_swizzled,
    create_scale_factor_tensor_unswizzled,
    frontend_cache_token,
    make_fake_conv_tensor,
    parse_comma_separated_ints,
    prepare_fprop_tensors,
    rt_conv_scalars,
    sf_k_tile_channels,
    sfb_per_position_channels,
    solve_max_smem_stages,
    trace_conv_scalars,
)

if __name__ == "__main__":
    # Sibling kernel modules are imported through their arch package root.
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))


from cutlass.cutlass_dsl import if_generate as _if_generate
from cutlass._mlir.dialects import nvvm


"""
A high-performance 3D implicit-GEMM based block-scaled fprop convolution example for the
NVIDIA Blackwell SM100 architecture using CUTE DSL.
- Input tensor A is NxDxHxWxC, must be C major.
- Filter tensor B is KxTxRxSxC, must be C major.
- Output tensor D is NxZxPxQxK, must be K major.

This kernel supports the following features:
    - Operand loads: the input tensor A by Tensor Memory Access (TMA) im2col, which
      performs the
      im2col transformation on the fly; the filter tensor B and its scale factor SFB by
      TMA tiled;
      the input scale factor SFA by cp.async
    - Utilizes Blackwell's tcgen05 block-scaled MMA for matrix multiply-accumulate (MMA)
      operations (including 2cta mma
      instructions): A and B are NVFP4 or MXFP8 and carry per-block scale factors (SFA,
      SFB)
    - Copies both scale factors from shared memory to Tensor Memory ahead of the MMA
    - Implements TMA multicast with cluster to reduce L2 memory traffic
    - CLC-based dynamic persistent tile scheduling
    - Fused epilogue computing in FP32, D = activation(alpha * acc + bias + beta *
      residual),
      with an optional per-output-channel bias, an optional residual (fused when beta !=
      0)
      and a compile-time activation
    - Block-scaled narrow output (FP4 / FP8 E4M3) with its scale factor SFD computed in
      the epilogue

This implicit-GEMM based convolution works by converting the convolution into a GEMM
problem with the following mapping:
- GEMM M dimension maps to NxZxPxQ
- GEMM N dimension maps to K
- GEMM K dimension maps to TxRxSxC
During the load of input tensor to SMEM, the TMA operation performs the im2col
transformation on the input tensor A.
This transforms the A matrix into the required shape for the GEMM operation (NxZxPxQ by
TxRxSxC), and may involve replication of the input elements.
Filter tensor can be loaded to SMEM without any transformation.
The output tensor D is then stored to GMEM via the im2col TMA store (no transformation
necessary).

To run this example:

.. code-block:: bash

    python examples/CuTeDSL/cute/blackwell/kernel/conv/dense_blockscaled_implicit_gemm_fprop.py \
      --ncdhw 1,128,32,32,32 --ktrs 256,3,3,3                         \
      --use_2cta_instrs --mma_tiler_mn 256,128                        \
      --preferred_cluster_shape_mn 2,1 --fallback_cluster_shape_mn 2,1 \
      --upper_pad_dhw 1,1,1 --lower_pad_dhw 1,1,1                     \
      --stride_dhw 1,1,1 --dil_dhw 1,1,1

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/CuTeDSL/cute/blackwell/kernel/conv/dense_blockscaled_implicit_gemm_fprop.py \
      --ncdhw 1,128,32,32,32 --ktrs 256,3,3,3                         \
      --use_2cta_instrs --mma_tiler_mn 256,128                        \
      --preferred_cluster_shape_mn 2,1 --fallback_cluster_shape_mn 2,1 \
      --upper_pad_dhw 1,1,1 --lower_pad_dhw 1,1,1                     \
      --stride_dhw 1,1,1 --dil_dhw 1,1,1                              \
      --warmup_iterations 1 --iterations 10 --skip_ref_check

Constraints:
* A/B data type is Float4E2M1FN (NVFP4) or Float8E4M3FN (MXFP8). Each pins its
  scale-factor format: NVFP4 takes a Float8E4M3FN scale over 16 channels, MXFP8 a
  Float8E8M0FNU scale over 32. A block-scaled narrow output takes the same format
  for its own scale factor, which pairs NVFP4 with an FP4 output and MXFP8 with an
  FP8 E4M3 one; a 16-bit output carries no scale factor.
* A/B tensor must have the same data type
* Mma tiler M must be 128 with use_2cta_instrs=False or 256 with True, the two
  shapes giving the per-CTA M of 128 that the block-scaled MMA requires
* Mma tiler N must be a multiple of 32 up to 256. Only 64, 128, 192 and 256 have a
  per-tile offset into the staged scale-factor chunk, so the others serve problems
  needing a single N tile
* Cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Cluster shape M must be multiple of 2 if use_2cta_instrs=True
* Preferred cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Preferred cluster shape M must be multiple of 2 if use_2cta_instrs=True
* Preferred cluster shape M/N must be multiple of fallback cluster shape M/N
* The contiguous dimension of A/B/D tensors must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 8, 16, and 32 for Float16/BFloat16,
  Float8E4M3FN, and Float4E2M1FN, respectively.
* The GEMM-K tile is an independent compile-time choice: 64, 128 or 256 channels
  for NVFP4 (one, two or four MMA K instructions), 64 or 128 for MXFP8. It need not
  divide the input channel count C, which only has to be a whole number of
  scale-factor atoms (4 * sf_vec_size channels). A K tile wider than the channels
  a filter position has left is a partial tile: the im2col TMA zero-fills the A
  and B channels past C, the SFA transfer is clamped back inside the pixel's
  scale-factor row, and SFB is addressed per filter position over a span rounded
  out to whole K tiles, so the tail contributes nothing.
"""


@dataclass(frozen=True)
class PipelineTmaCpAsyncUmma(PipelineAsync):
    """
    Merged pipeline for TMA (A+B+SFB) producers AND cp.async (SFA) producers sharing a
    single mbarrier set.

    Full mbarrier uses BOTH independent mbarrier counters:
      - tx_count   : incremented via mbarrier.expect_tx for TMA bytes, decremented by
        TMA completion
      - arrive_cnt : initialized to cp.async producer group size; decremented by
        cp.async.mbarrier.arrive.noinc

    Barrier phase flips only when tx_count == 0 AND arrive_cnt == 0, so the UMMA
    consumer performs
    a single wait/release per stage covering both producer streams.

    General variant: supports arbitrary cluster shapes (including cluster_shape_n > 1).
    """

    is_leader_cta: bool
    cta_group: cute.nvgpu.tcgen05.CtaGroup
    tx_count: int

    @staticmethod
    def create(
        *,
        num_stages: int,
        cpasynd_producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        tx_count: int,
        barrier_storage: cute.Pointer,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        mcast_mode_mn: Tuple[int, int] = (1, 1),
        defer_sync: bool = False,
    ) -> "PipelineTmaCpAsyncUmma":
        """Creates and initializes a merged TMA+cp.async / UMMA pipeline."""
        if not isinstance(barrier_storage, cute.Pointer):
            raise ValueError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        producer = (PipelineOp.AsyncLoad, cpasynd_producer_group)
        consumer = (PipelineOp.TCGen05Mma, consumer_group)

        sync_object_full = pipeline.PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8), num_stages, producer, tx_count
        )
        sync_object_empty = pipeline.PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages, num_stages, consumer
        )

        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk, mode=[0]) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )

        if cta_layout_vmnk is None or cute.size(cta_layout_vmnk) == 1:
            consumer_mask = None
            is_leader_cta = True
            # No cross-CTA; remote arrives degenerate to self-arrive.
            producer_mask = cutlass.Int32(0)
        else:
            # The empty-drain multicast mask: OR over the A-axis and B-axis TMA
            # multicast sets plus their V-peers.
            cta_rank_here = cute.arch.make_warp_uniform(
                cute.arch.block_idx_in_cluster()
            )
            coord_self = cta_layout_vmnk.get_flat_coord(cta_rank_here)
            coord_peer = (coord_self[0] ^ 1, *coord_self[1:])
            # Target CTA of the SFA cp.async arrives. Under 2CTA the peer's cp.async
            # lands in the leader's SMEM, so both CTAs arrive on the leader's barrier;
            # clearing the V bit of the flat rank (v + m*V + ...) gives the leader.
            # Without 2CTA each CTA arrives on its own barrier and the value is unused.
            producer_mask = (
                cta_rank_here & ~cutlass.Int32(1)
                if cta_group == cute.nvgpu.tcgen05.CtaGroup.TWO
                else cta_rank_here
            )
            mask_a_self = cute.nvgpu.cpasync.create_tma_multicast_mask(
                cta_layout_vmnk, coord_self, mcast_mode=2
            )
            mask_b_self = cute.nvgpu.cpasync.create_tma_multicast_mask(
                cta_layout_vmnk, coord_self, mcast_mode=1
            )
            mask_a_peer = cute.nvgpu.cpasync.create_tma_multicast_mask(
                cta_layout_vmnk, coord_peer, mcast_mode=2
            )
            mask_b_peer = cute.nvgpu.cpasync.create_tma_multicast_mask(
                cta_layout_vmnk, coord_peer, mcast_mode=1
            )
            if mcast_mode_mn[0] == 1 and mcast_mode_mn[1] == 1:
                consumer_mask = (
                    cutlass.Int32(mask_a_self)
                    | cutlass.Int32(mask_b_self)
                    | cutlass.Int32(mask_a_peer)
                    | cutlass.Int32(mask_b_peer)
                )
            elif mcast_mode_mn[1] == 1:
                consumer_mask = cutlass.Int32(mask_b_self) | cutlass.Int32(mask_b_peer)
            else:
                assert mcast_mode_mn[0] == 1
                consumer_mask = cutlass.Int32(mask_a_self) | cutlass.Int32(mask_a_peer)
            is_leader_cta = pipeline.PipelineTmaUmma._compute_is_leader_cta(
                cta_layout_vmnk
            )

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk) == 1:
                agent_sync(Agent.ThreadBlock)
            else:
                agent_sync(Agent.ThreadBlockCluster, is_relaxed=True)

        return PipelineTmaCpAsyncUmma(
            sync_object_full,
            sync_object_empty,
            num_stages,
            producer_mask,
            consumer_mask,
            is_leader_cta,
            cta_group,
            tx_count,
        )

    def producer_acquire_tma(
        self,
        state: PipelineState,
        try_acquire_token: Optional[cutlass.Boolean] = None,
        *,
        expected_tx: Optional[cutlass.Int32] = None,
    ) -> None:
        """TMA producer path.

        Only the leader CTA issues ``arrive_and_expect_tx``. The multicast
        variant broadcasts BOTH the arrive and the tx-expect to every peer
        barrier in the cluster, so peer CTAs must do nothing here. Any peer
        ``arrive(1)`` would double-count the arrive on the peer barrier and
        opens a race window against cp.async producers draining first.
        """
        _if_generate(
            try_acquire_token is None or try_acquire_token == 0,
            lambda: self.sync_object_empty.wait(state.index, state.phase),
        )
        tx = self.tx_count if expected_tx is None else expected_tx

        def _leader_arrive_and_expect_tx() -> None:
            self.sync_object_full.arrive_and_expect_tx(state.index, tx)

        _if_generate(
            self.is_leader_cta,
            _leader_arrive_and_expect_tx,
        )

    def consumer_release(self, state: PipelineState) -> None:
        """UMMA consumer releases the shared empty barrier once per stage."""
        self.sync_object_empty.arrive(state.index, self.consumer_mask, self.cta_group)

    # Shift-by-K cross-CTA producer commit. cp.async.mbarrier.arrive.noinc signals
    # only the local barrier and so misses the peer's copy into the leader's SMEM
    # under 2CTA. The commit is split into commit_group + wait_group(K) + an arrive
    # on the leader's barrier, sent K iterations later once the cp.async has landed.
    def producer_cp_async_commit(self) -> None:
        """Register all prior cp.async copies as one cp.async group."""
        cute.arch.cp_async_commit_group()

    def producer_cp_async_wait(self, num_inflight: int) -> None:
        """Block until at most ``num_inflight`` cp.async groups remain pending."""
        cute.arch.cp_async_wait_group(num_inflight)

    def producer_arrive_remote(self, stage_index) -> None:
        """Signal SFA cp.async completion on sfa_full[stage_index].

        In a 2CTA cluster the peer CTA's cp.async lands in the leader's SMEM,
        so both CTAs must arrive on the leader's sfa_full via DSMEM (producer_mask
        holds the leader rank). In a non-2CTA cluster every CTA owns its SFA
        locally, so the arrive stays on the local barrier with no DSMEM
        retargeting.
        """
        bar = self.sync_object_full.get_barrier(stage_index)
        if cutlass.const_expr(self.cta_group == cute.nvgpu.tcgen05.CtaGroup.TWO):
            cute.arch.mbarrier_arrive(bar, self.producer_mask)
        else:
            cute.arch.mbarrier_arrive(bar)


class Sm100BlockScaledDenseImplicitGemmFpropKernel:
    """
    Persistent block-scaled 3D convolution kernel.
    The input (A) is expected to be in 5D tensor (NDHWC) format and is loaded via the
    TMA im2col load atom.
    The filter (B) is expected to be in 5D tensor (KTRSC) format and is loaded via the
    TMA tiled load atom.
    The filter scale factor (SFB) is loaded via the TMA tiled load atom, and the input
    scale factor (SFA) via cp.async.
    The output (D) is expected to be in 5D tensor (NZPQK) format and is stored via the
    im2col TMA store.
    The optional residual (C) has D's format and is loaded via the TMA im2col load atom.
    One kernel carries a code path per cluster shape and runs the one matching the
    cluster the launch actually formed, so a single launch serves both the preferred
    and the fallback cluster.

    :param acc_dtype: Data type for accumulation during computation
    :type acc_dtype: type[cutlass.Numeric]
    :param sf_vec_size: Channels one scale factor covers, 16 for NVFP4 and 32 for MXFP8
    :type sf_vec_size: int
    :param use_2cta_instrs: Whether to use CTA group 2 for advanced thread cooperation
    :type use_2cta_instrs: bool
    :param mma_tiler_mn: Shape of the Matrix Multiply-Accumulate (MMA) tiler (M,N)
    :type mma_tiler_mn: Tuple[int, int]
    :param preferred_cluster_shape_mn: Preferred cluster dimensions (M,N) for optimal
        performance
    :type preferred_cluster_shape_mn: Tuple[int, int]
    :param fallback_cluster_shape_mn: Fallback cluster dimensions (M,N) for parallel
        processing
    :type fallback_cluster_shape_mn: Tuple[int, int]
    :param cta_tile_k: GEMM-K tile in input channels, a compile-time choice independent
        of C
    :type cta_tile_k: int
    :param swizzle_size: Swizzling size in the unit of cluster. 1 means no swizzle
    :type swizzle_size: int
    :param raster_along: Rasterization order of clusters. Only used when swizzle_size >
        1.
    :type raster_along: Literal["m", "n"]

    :note: The convolution geometry (filter T/R/S, padding, stride, dilation) is not a
        constructor parameter: T/R/S come from the filter tensor extents and
        pad/stride/dilation arrive as runtime Int32 operands to __call__, so a single
        compiled cubin serves any geometry.

    :note: In current version, A and B tensor must be C major. D tensor must be K major.

    :note: Supported A/B data types, which A and B share:
        - Float4E2M1FN (NVFP4), scaled by a Float8E4M3FN factor over 16 channels
        - Float8E4M3FN (MXFP8), scaled by a Float8E8M0FNU factor over 32 channels

    :note: The accumulator is Float32.

    :note: Supported D data types:
        - the block-scaled narrow output that pairs with A/B -- Float4E2M1FN for
          NVFP4, Float8E4M3FN for MXFP8 -- which carries its own scale factor
        - Float16/BFloat16, which carry none

    :note: Constraints:
        - MMA tiler M must be 128 (use_2cta_instrs=False) or 256 (use_2cta_instrs=True),
          the two shapes giving the per-CTA M of 128 the block-scaled MMA requires
        - MMA tiler N must be a multiple of 32 up to 256; only 64, 128, 192 and 256
          have a per-tile offset into the staged scale-factor chunk, so the others
          serve problems needing a single N tile
        - Cluster shape M must be multiple of 2 if use_2cta_instrs=True
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 16
        - Preferred cluster shape M must be multiple of 2 if use_2cta_instrs=True
        - Preferred cluster shape M/N must be positive and power of 2, total cluster
          size <= 16
        - Preferred cluster shape M/N must be multiple of fallback cluster shape M/N
        - The contiguous dimension of A/B/D tensors must be at least 16 bytes aligned,
          i.e, number of elements is a multiple of 8, 16, and 32 for Float16/BFloat16,
          Float8E4M3FN, and Float4E2M1FN, respectively
        - The GEMM-K tile is 64, 128 or 256 channels for NVFP4 and 64 or 128 for MXFP8
        - C must be a whole number of scale-factor atoms, 4 * sf_vec_size channels
        - The residual C, when fused (beta != 0), has D's shape and data type

    **Example:**

    .. code-block:: python
        conv = Sm100BlockScaledDenseImplicitGemmFpropKernel(
            acc_dtype=cutlass.Float32,
            sf_vec_size=16,
            use_2cta_instrs=True,
            mma_tiler_mn=(256, 128),
            preferred_cluster_shape_mn=(4, 2),
            fallback_cluster_shape_mn=(2, 1),
            cta_tile_k=128,
        )
        conv(
            a, b, sfa, sfb, d,
            sfd,  # optional D scale-factor tensor for a block-scaled narrow D, or None
            bias,  # optional length-K bias tensor, or None
            c,  # optional residual tensor with D's shape, or None
            alpha,  # FP32 runtime accumulator scale
            beta,  # compile-time residual scale; 0.0 compiles the residual away
            norm_const,  # FP32 global scale for the SFD encode, 1.0 when unused
            upper_pad_d, upper_pad_h, upper_pad_w,
            lower_pad_d, lower_pad_h, lower_pad_w,
            stride_d, stride_h, stride_w,
            dil_d, dil_h, dil_w,
            stream,
            epilogue_op,
        )
    """

    # The epilogue warps are fixed for every configuration, so they live on the
    # class, where static checks can read them.
    epilogue_warp_id = (0, 1, 2, 3)

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        use_2cta_instrs: bool,
        mma_tiler_mn: Tuple[int, int],
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
        cta_tile_k: int,
        swizzle_size: int = 1,
        raster_along: Literal["m", "n"] = "m",
    ):
        self.acc_dtype: Type[cutlass.Numeric] = acc_dtype
        self.use_2cta_instrs = use_2cta_instrs
        # cluster_shape_mn is the fallback cluster shape, which every launch is
        # guaranteed to be able to form; the fallback cluster layout and its
        # multicast counts are sized against it.
        self.cluster_shape_mn = fallback_cluster_shape_mn
        self.swizzle_size = swizzle_size
        self.raster_along = raster_along
        # K dimension is deferred in _setup_attributes
        self.mma_tiler_mn = mma_tiler_mn
        self.mma_tiler = (*mma_tiler_mn, 1)
        self.arch = "sm_100"
        # Shared memory capacity of the compile target.
        self.smem_capacity = get_smem_capacity_in_bytes()

        self.num_clc_stage = 1
        # Response size is 4B * 4 elements
        self.num_clc_response_bytes = 16

        self.cta_group = (
            tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
        )
        self.tiled_mma = None

        # Set specialized warp ids
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.sched_warp_id = 6
        self.threads_per_cta = 32 * len(
            (
                self.mma_warp_id,
                self.tma_warp_id,
                self.sched_warp_id,
                *self.epilogue_warp_id,
            )
        )
        # Set barrier ids for the epilogue sync and the tmem ptr sync
        self.epilog_sync_bar_id = 1
        self.tmem_alloc_sync_bar_id = 2

        # Both shapes are kept: the kernel dispatches on which one the launch
        # actually formed.
        self.preferred_cluster_shape_mn = preferred_cluster_shape_mn
        self.fallback_cluster_shape_mn = fallback_cluster_shape_mn

        self.sf_vec_size = sf_vec_size
        self.tiled_mma_sfb = None

        # cta_tile_k is the compile-time K tile (shapes the SMEM allocation).
        # The input channel count C is read from the dynamic tensors at runtime and
        # bounded only by the alignment of the channel axis, so one cubin serves
        # every C this kernel accepts. All output geometry (N/Z/P/Q/K) is runtime
        # as well.
        self.cta_tile_k = cta_tile_k

        # Override warp specialization for fp4 conv: 4 cp.async SFA warps + sched warp.
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.cpasync_sfa_warp_id = (6, 7, 8, 9)
        self.sched_warp_id = 10
        # Dedicated residual G2S warp, only spawned when beta != 0 (has_residual).
        # threads_per_cta is finalized in __call__ once has_residual is known.
        self.residual_warp_id = 11
        self.base_warp_ids = (
            self.mma_warp_id,
            self.tma_warp_id,
            *self.cpasync_sfa_warp_id,
            self.sched_warp_id,
            *self.epilogue_warp_id,
        )
        self.threads_per_cta = 32 * len(self.base_warp_ids)
        # Barrier id 0 is cta_sync; the epilogue sync takes 1.
        self.epilog_sync_bar_id = 1
        self.epilog_sync_barrier = pipeline.NamedBarrier(
            barrier_id=self.epilog_sync_bar_id,
            num_threads=32 * len(self.epilogue_warp_id),
        )
        self.tmem_alloc_sync_bar_id = 2

    def _setup_conv_input_attrs(self, a, b, d) -> None:
        """Validate and set input-dependent attributes.

        Sets a_dtype, b_dtype, d_dtype, a_major_mode, b_major_mode, d_layout,
        sfd_vec_size, M_D.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        """
        self.a_dtype: Type[cutlass.Numeric] = a.element_type
        self.b_dtype: Type[cutlass.Numeric] = b.element_type
        self.d_dtype: Type[cutlass.Numeric] = d.element_type
        self.a_major_mode = cute.nvgpu.OperandMajorMode.K
        self.b_major_mode = cute.nvgpu.OperandMajorMode.K
        self.d_layout = LayoutEnum.ROW_MAJOR  # K dimension contiguous

        # Block-scaled D (SFD) output, opted into by passing sfd. A narrow
        # output carries one scale factor per sfd_vec_size elements; a 16-bit output
        # carries none. The SFD block takes the input SF block's element type and
        # vector size, so a quantized output feeds the next operation directly:
        # NVFP4 is E4M3 over 16 channels, MXFP8 E8M0 over 32.
        self.sfd_vec_size: int = self.sf_vec_size
        # M_D is the largest absolute value representable in the output dtype,
        # the full-scale target when quantizing each block to it. FP4 (E2M1)
        # magnitudes are {0,.5,1,1.5,2,3,4,6} so max is 6.0; E4M3 max normal is
        # 448.0. Only narrow SFD outputs use it, hence None otherwise.
        self.M_D: Optional[float] = {
            cutlass.Float4E2M1FN: 6.0,
            cutlass.Float8E4M3FN: 448.0,
        }.get(self.d_dtype, None)

    def _setup_attributes(self) -> None:
        """Set up configurations that are dependent on convolution inputs."""
        # --- MMA and tile shapes ---
        # Compute mma instruction shapes
        # (MMA_Tile_Shape_M, MMA_Tile_Shape_N)
        self.mma_inst_shape_mn = (
            self.mma_tiler[0],
            self.mma_tiler[1],
        )
        # (CTA_Tile_Shape_M, Round_Up(MMA_Tile_Shape_N, 128))
        self.mma_inst_shape_mn_sfb = (
            self.mma_inst_shape_mn[0] // (2 if self.use_2cta_instrs else 1),
            cute.round_up(self.mma_inst_shape_mn[1], 128),
        )

        self.tiled_mma = sm100_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape_mn,
        )

        # SFB tiled_mma (always 1CTA group for SFB)
        self.tiled_mma_sfb = sm100_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_mn_sfb,
        )

        mma_inst_shape_k = cute.size(self.tiled_mma.shape_mnk, mode=[2])
        # cta_tile_k is a compile-time choice (64, 128 or 256 for FP4). It sets
        # how many MMA-instruction K blocks a K tile spans.
        mma_inst_tile_k = self.cta_tile_k // mma_inst_shape_k
        # Expose for overlapping-accum SF column accounting (see below).
        self.mma_inst_tile_k = mma_inst_tile_k
        self.mma_tiler = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            (mma_inst_shape_k * mma_inst_tile_k,),
        )
        # Scale factors tile K on their own cadence: an SF atom cannot be staged
        # in part, so a narrower A/B K tile stages a whole one and the A/B
        # tiles sharing it each read their own part. Only MXFP8 gets there, with a
        # 128-channel atom against a 64 tile; NVFP4's atom is 64, at or below
        # every legal tile, so its ratio is 1 and every SF path keeps the A/B one.
        self.sf_tile_k = sf_k_tile_channels(self.cta_tile_k, self.sf_vec_size)
        self.ab_k_tiles_per_sf_k_tile = self.sf_tile_k // self.cta_tile_k
        self.sf_mma_inst_tile_k = self.sf_tile_k // mma_inst_shape_k
        # Flat-K tiler the SF layouts (smem, tmem, TMA box) are built from.
        self.flat_mma_tiler_sf = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            self.sf_tile_k,
        )
        self.mma_tiler_sfb = (
            self.mma_inst_shape_mn_sfb[0],
            self.mma_inst_shape_mn_sfb[1],
            self.sf_tile_k,
        )
        # SFA 4-byte cp.async per SF K tile: each carries 4 SF blocks, and an SF
        # K tile is a whole number of atoms at every legal tile_k, so the count is
        # at least one and the power of two the group rotation below needs.
        self.num_sfa_cpasync = self.sf_tile_k // (self.sf_vec_size * 4)
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(self.tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )
        # CTA-level SFB tile shape (used for SFB TMEM column accounting in
        # overlapping-accum). N-mode rounds MMA_N up to 128 like SFB MMA.
        self.cta_tile_shape_mnk_sfb = (
            self.mma_tiler_sfb[0] // cute.size(self.tiled_mma.thr_id.shape),
            self.mma_tiler_sfb[1],
            self.sf_tile_k,
        )

        # --- Epilogue tile ---
        self.epi_tile = sm100_utils.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.d_layout,
            self.d_dtype,
        )
        # FP4 A/B with 16-bit D: widen the epilogue subtile N to 64 (e.g. 32 -> 64),
        # so a tile runs half as many subtiles and pays the per-subtile TMEM load,
        # store and barrier cost half as often (a 256-wide tile: 8 subtiles -> 4).
        if cutlass.const_expr(
            self.a_dtype.width == 4
            and self.d_dtype.width == 16
            and cute.size(self.epi_tile[1]) < 64
            and self.cta_tile_shape_mnk[1] % 64 == 0
        ):
            self.epi_tile = (self.epi_tile[0], cute.make_layout(64))
        # N-extent of one epilogue subtile (used by overlapping-accum early release).
        self.epi_tile_n = cute.size(self.epi_tile[1])

        # --- Pipeline stages and smem layouts ---
        # ACC stages in TMEM: one when MMA_N is 256, two otherwise.
        self.num_acc_stage = 1 if self.mma_tiler[1] == 256 else 2
        self._solve_smem_stages(
            Sm100BlockScaledDenseImplicitGemmFpropKernel._make_shared_storage
        )
        (
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.d_smem_layout_staged,
        ) = self._make_smem_layouts(
            self.tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.d_dtype,
            self.d_layout,
            self.epi_tile,
            self.num_ab_stage,
            self.num_d_stage,
        )
        self.sfa_smem_layout_staged, self.sfb_smem_layout_staged = (
            self._make_sf_smem_layouts(
                self.tiled_mma,
                self.flat_mma_tiler_sf,
                self.sf_vec_size,
                self.num_ab_stage,
            )
        )

        # --- TMA transaction bytes and TMEM columns ---
        # Compute A, B, SFB copy sizes for separate TMA pipelines.
        # SFB has its own pipeline because B and SFB use different mcast
        # masks (cluster_layout_vmnk vs cluster_layout_sfb_vmnk), so bundling
        # them into one pipeline can stall TX accumulation in cluster > 1.
        atom_thr_size = cute.size(self.tiled_mma.thr_id.shape)
        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, None, 0))
        sfb_smem_layout = cute.slice_(
            self.sfb_smem_layout_staged, (None, None, None, 0)
        )
        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        sfb_copy_size = cute.size_in_bytes(self.sf_dtype, sfb_smem_layout)
        self.num_tma_load_a_bytes = a_copy_size * atom_thr_size
        self.num_tma_load_b_bytes = b_copy_size * atom_thr_size
        self.num_tma_load_sfb_bytes = sfb_copy_size * atom_thr_size

        # Residual reuses the D epilogue smem layout (same shape/dtype as the
        # output); one epilogue subtile's worth of bytes per TMA load.
        c_smem_layout = cute.slice_(self.d_smem_layout_staged, (None, None, 0))
        self.num_tma_load_c_bytes = cute.size_in_bytes(self.d_dtype, c_smem_layout)

        # Overlapping-accum: when only one accumulator stage fits in TMEM
        # (MMA_N == 256), squeeze a second logical acc buffer into the columns
        # otherwise reserved for SFA/SFB so the math mainloop of the next tile
        # can overlap the epilogue of the current tile.
        self.overlapping_accum = self.num_acc_stage == 1
        # SF columns follow the SF K cadence: TMEM holds whole chunks.
        self.num_sfa_tmem_cols = (
            self.cta_tile_shape_mnk[0] // 32
        ) * self.sf_mma_inst_tile_k
        self.num_sfb_tmem_cols = (
            self.cta_tile_shape_mnk_sfb[1] // 32
        ) * self.sf_mma_inst_tile_k
        self.num_sf_tmem_cols = self.num_sfa_tmem_cols + self.num_sfb_tmem_cols
        # Overlapping-accum: the two accumulator buffers share num_sf_tmem_cols
        # columns, and the epilogue reads those first (buffer 0 back to front,
        # buffer 1 front to back). Once the subtile at this loop step is loaded they
        # are all read, so the accumulator is released for the next tile's MMA.
        # E.g. 48 shared columns, 32-wide subtiles: 48 // 32 = 1, release after 2.
        self.iter_acc_early_release_in_epilogue = (
            self.num_sf_tmem_cols // self.epi_tile_n
        )

        # Compute the number of tensor memory allocation columns. For
        # overlapping-accum the second acc buffer is strided into the SFA/SFB
        # columns, so the count comes from the fake tensor the injection sites use.
        if cutlass.const_expr(self.overlapping_accum):
            self.num_tmem_alloc_cols = get_num_tmem_alloc_cols(
                self._make_acc_fake_tensor(self.tiled_mma, self.mma_tiler),
                arch=self.arch,
            )
        else:
            self.num_tmem_alloc_cols = self._compute_num_tmem_alloc_cols(
                self.tiled_mma, self.mma_tiler, self.num_acc_stage, self.arch
            )

        # --- Cluster layouts ---
        self._setup_cluster_attrs()
        # SFB cluster layouts (SFB always uses 1CTA group, thr_id shape = 1)
        self.preferred_cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.preferred_cluster_shape_mn, 1)),
            (self.tiled_mma_sfb.thr_id.shape,),
        )
        self.fallback_cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (self.tiled_mma_sfb.thr_id.shape,),
        )

    def _solve_smem_stages(self, make_shared_storage) -> None:
        """Solve the A/B and D pipeline stage counts that fit in shared memory.

        :param make_shared_storage: Unbound _make_shared_storage of the kernel
            class, called with self for every candidate stage assignment
        """
        # The D-store ring starts at two and deepens with whatever smem the A/B
        # pipeline leaves over -- A/B depth is filled first. Both are solved
        # against the exact SharedStorage footprint so the stage-scaled
        # mbarriers, the optional bias row and every alignment pad are accounted
        # for.
        counts = solve_max_smem_stages(
            lambda **kw: make_shared_storage(self, **kw),
            self.smem_capacity,
            primary="num_ab_stage",
            start={"num_ab_stage": 1, "num_d_stage": 2},
            deepen=("num_d_stage",),
        )
        self.num_ab_stage = counts["num_ab_stage"]
        self.num_d_stage = counts["num_d_stage"]

    def _setup_cluster_attrs(self) -> None:
        """Set up the preferred and fallback cluster layouts and their A/B multicast."""
        self.preferred_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.preferred_cluster_shape_mn, 1)),
            (self.tiled_mma.thr_id.shape,),
        )
        self.num_preferred_mcast_ctas_a = cute.size(
            self.preferred_cluster_layout_vmnk.shape[2]
        )
        self.num_preferred_mcast_ctas_b = cute.size(
            self.preferred_cluster_layout_vmnk.shape[1]
        )
        self.is_preferred_a_mcast = self.num_preferred_mcast_ctas_a > 1
        self.is_preferred_b_mcast = self.num_preferred_mcast_ctas_b > 1

        self.fallback_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (self.tiled_mma.thr_id.shape,),
        )
        self.num_fallback_mcast_ctas_a = cute.size(
            self.fallback_cluster_layout_vmnk.shape[2]
        )
        self.num_fallback_mcast_ctas_b = cute.size(
            self.fallback_cluster_layout_vmnk.shape[1]
        )
        self.is_fallback_a_mcast = self.num_fallback_mcast_ctas_a > 1
        self.is_fallback_b_mcast = self.num_fallback_mcast_ctas_b > 1

    def _setup_conv_tma(
        self,
        a,
        b,
        d,
        c,
        sfb,
        tiled_mma,
        tiled_mma_sfb,
        rt_upper_pad_dhw,
        rt_lower_pad_dhw,
        rt_stride_dhw,
        rt_dil_dhw,
    ):
        """Set up dual-cluster TMA atoms and tensors for im2col convolution.

        Creates preferred and fallback TMA atoms for the A, B and SFB tensors, and a
        single TMA atom each for D and, when a residual is fused, C (the im2col store
        and load are cluster-independent).

        The pad / stride / dilation operand tuples build the im2col A descriptor
        corner. They arrive as runtime cutlass.Int32, which the rt_ prefix marks,
        so one compiled cubin serves any geometry.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        :param c: Residual tensor C - (N, Z, P, Q, K) layout, or None
        :param sfb: Block scale factor tensor for B
        :param tiled_mma: Tiled MMA configuration
        :param tiled_mma_sfb: Tiled MMA configuration of the SFB tiling
        :param rt_upper_pad_dhw: Upper padding (D, H, W)
        :param rt_lower_pad_dhw: Lower padding (D, H, W)
        :param rt_stride_dhw: Convolution stride (D, H, W)
        :param rt_dil_dhw: Dilation (D, H, W)
        :returns: (tma_atom_a_preferred, tma_tensor_a_preferred,
                   tma_atom_a_fallback, tma_tensor_a_fallback,
                   tma_atom_b_preferred, tma_tensor_b_preferred,
                   tma_atom_b_fallback, tma_tensor_b_fallback,
                   tma_atom_d, tma_tensor_d,
                   tma_atom_c, tma_tensor_c,
                   tma_atom_sfb_preferred, tma_tensor_sfb_preferred,
                   tma_atom_sfb_fallback, tma_tensor_sfb_fallback)
        """
        (
            tma_atom_a_preferred,
            tma_tensor_a_preferred,
            tma_atom_a_fallback,
            tma_tensor_a_fallback,
        ) = self._make_a_im2col_tma_atoms(
            a,
            b,
            tiled_mma,
            rt_upper_pad_dhw,
            rt_lower_pad_dhw,
            rt_stride_dhw,
            rt_dil_dhw,
        )

        (
            tma_atom_b_preferred,
            tma_tensor_b_preferred,
            tma_atom_b_fallback,
            tma_tensor_b_fallback,
        ) = self._make_b_tiled_tma_atoms(b, tiled_mma)

        # --- D: im2col TMA store (cluster-independent) ---
        # Change view of output tensor from (N, Z, P, Q, K) to ((Q, P, Z, N), K)
        mD = cute.make_tensor(d.iterator, cute.select(d.layout, mode=[3, 2, 1, 0, 4]))
        mD = cute.group_modes(mD, begin=0, end=4)

        epi_smem_layout = cute.slice_(
            self.d_smem_layout_staged, (None, None, (None, 0))
        )

        tma_atom_d, tma_tensor_d = cpasync.make_im2col_tma_atom(
            cpasync.CopyBulkTensorIm2ColS2GOp(),
            mD,
            epi_smem_layout,
            self.epi_tile,
        )
        tma_tensor_d = cute.coalesce(tma_tensor_d, target_profile=(1, 1))

        # Add dummy batch dimension to all tensors (GEMM expects batch dimension)
        tma_tensor_a_preferred = add_dummy_batch_dimension(tma_tensor_a_preferred)
        tma_tensor_a_fallback = add_dummy_batch_dimension(tma_tensor_a_fallback)
        tma_tensor_b_preferred = add_dummy_batch_dimension(tma_tensor_b_preferred)
        tma_tensor_b_fallback = add_dummy_batch_dimension(tma_tensor_b_fallback)
        tma_tensor_d = add_dummy_batch_dimension(tma_tensor_d)

        # --- Residual: im2col G2S load, the inverse of the D im2col store ---
        # The residual has D's (N,Z,P,Q,K) shape/layout, so it takes D's hierarchical
        # view and D's epilogue smem layout. G2S needs the full im2col descriptor
        # corner set, and the residual is an identity element map (a 1x1x1 tap), so
        # every corner and stride is trivial: corners/padding 0, DHW 1, SRT 0/1.
        if cutlass.const_expr(self.has_residual):
            mC = cute.make_tensor(
                c.iterator, cute.select(c.layout, mode=[3, 2, 1, 0, 4])
            )
            mC = cute.group_modes(mC, begin=0, end=4)
            epi_smem_layout = cute.slice_(
                self.d_smem_layout_staged, (None, None, (None, 0))
            )
            tma_atom_c, tma_tensor_c = cpasync.make_im2col_tma_atom(
                cpasync.CopyBulkTensorIm2ColG2SOp(),
                mC,
                epi_smem_layout,
                self.epi_tile,
                lower_corner_whd=(0, 0, 0),
                upper_corner_whd=(0, 0, 0),
                lower_padding_whd=(0, 0, 0),
                upper_padding_whd=(0, 0, 0),
                stride_whd=(1, 1, 1),
                lower_srt=(0, 0, 0),
                stride_srt=(1, 1, 1),
            )
            tma_tensor_c = cute.coalesce(tma_tensor_c, target_profile=(1, 1))
            tma_tensor_c = add_dummy_batch_dimension(tma_tensor_c)
        else:
            tma_atom_c, tma_tensor_c = None, None

        (
            tma_atom_sfb_preferred,
            tma_tensor_sfb_preferred,
            tma_atom_sfb_fallback,
            tma_tensor_sfb_fallback,
        ) = self._make_sfb_tiled_tma_atoms(sfb, b, tiled_mma, tiled_mma_sfb)

        return (
            tma_atom_a_preferred,
            tma_tensor_a_preferred,
            tma_atom_a_fallback,
            tma_tensor_a_fallback,
            tma_atom_b_preferred,
            tma_tensor_b_preferred,
            tma_atom_b_fallback,
            tma_tensor_b_fallback,
            tma_atom_d,
            tma_tensor_d,
            tma_atom_c,
            tma_tensor_c,
            tma_atom_sfb_preferred,
            tma_tensor_sfb_preferred,
            tma_atom_sfb_fallback,
            tma_tensor_sfb_fallback,
        )

    def _make_a_im2col_tma_atoms(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        tiled_mma: cute.TiledMma,
        rt_upper_pad_dhw: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        rt_lower_pad_dhw: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        rt_stride_dhw: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        rt_dil_dhw: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
    ) -> Tuple[cute.CopyAtom, cute.Tensor, cute.CopyAtom, cute.Tensor]:
        """Make A's preferred and fallback im2col TMA load atoms.

        A is the operand the im2col descriptor walks: it is viewed as
        ((W, H, D, N), C) so the descriptor's box slides over the spatial modes,
        and its corners come from the runtime pad/stride/dilation operands and the
        filter tensor's own extents. The two atoms differ only in the cluster shape
        they multicast over, and each drops the multicast op when its cluster does
        not multicast A.

        Pad / stride / dilation arrive as runtime cutlass.Int32, which the rt_ prefix
        marks, so one compiled cubin serves any geometry.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param tiled_mma: Tiled MMA configuration
        :param rt_upper_pad_dhw: Upper padding (D, H, W)
        :param rt_lower_pad_dhw: Lower padding (D, H, W)
        :param rt_stride_dhw: Convolution stride (D, H, W)
        :param rt_dil_dhw: Dilation (D, H, W)

        :return: (tma_atom_a_preferred, tma_tensor_a_preferred,
                tma_atom_a_fallback, tma_tensor_a_fallback)
        """
        # Create 2-mode hierarchical tensor layout: (N, D, H, W, C) -> ((W, H, D, N), C)
        mA = cute.make_tensor(a.iterator, cute.select(a.layout, mode=[3, 2, 1, 0, 4]))
        mA = cute.group_modes(mA, begin=0, end=4)

        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        a_internal_type = (
            cutlass.TFloat32 if mA.element_type is cutlass.Float32 else None
        )

        # Filter T/R/S come from the filter tensor (K, T, R, S, C), whose dynamic
        # layout makes the extents runtime Int32, so one cubin serves any T/R/S.
        rt_filter_trs = (b.shape[1], b.shape[2], b.shape[3])

        # --- A preferred ---
        a_copy_atom_preferred = (
            cpasync.CopyBulkTensorIm2ColG2SMulticastOp(cta_group=self.cta_group)
            if self.is_preferred_a_mcast
            else cpasync.CopyBulkTensorIm2ColG2SOp(cta_group=self.cta_group)
        )
        tma_atom_a_preferred, tma_tensor_a_preferred = (
            cute.nvgpu.make_im2col_tma_atom_A(
                a_copy_atom_preferred,
                mA,
                a_smem_layout,
                self.mma_tiler,
                tiled_mma,
                rt_filter_trs,
                rt_upper_pad_dhw,
                rt_lower_pad_dhw,
                rt_stride_dhw,
                rt_dil_dhw,
                self.preferred_cluster_layout_vmnk.shape,
                internal_type=a_internal_type,
            )
        )

        # --- A fallback ---
        a_copy_atom_fallback = (
            cpasync.CopyBulkTensorIm2ColG2SMulticastOp(cta_group=self.cta_group)
            if self.is_fallback_a_mcast
            else cpasync.CopyBulkTensorIm2ColG2SOp(cta_group=self.cta_group)
        )
        tma_atom_a_fallback, tma_tensor_a_fallback = cute.nvgpu.make_im2col_tma_atom_A(
            a_copy_atom_fallback,
            mA,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            rt_filter_trs,
            rt_upper_pad_dhw,
            rt_lower_pad_dhw,
            rt_stride_dhw,
            rt_dil_dhw,
            self.fallback_cluster_layout_vmnk.shape,
            internal_type=a_internal_type,
        )
        return (
            tma_atom_a_preferred,
            tma_tensor_a_preferred,
            tma_atom_a_fallback,
            tma_tensor_a_fallback,
        )

    def _make_b_tiled_tma_atoms(
        self,
        b: cute.Tensor,
        tiled_mma: cute.TiledMma,
    ) -> Tuple[cute.CopyAtom, cute.Tensor, cute.CopyAtom, cute.Tensor]:
        """Make B's preferred and fallback tiled TMA load atoms.

        B is the filter, which reaches shared memory without any transformation: it
        is viewed as (K, (C, S, R, T)) so its GEMM-K mode groups the channel and
        filter-spatial modes. The two atoms differ only in the cluster shape they
        multicast over.

        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param tiled_mma: Tiled MMA configuration

        :return: (tma_atom_b_preferred, tma_tensor_b_preferred,
                tma_atom_b_fallback, tma_tensor_b_fallback)
        """
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, None, 0))
        # Change view of filter tensor from (K, T, R, S, C) to (K, (C, S, R, T))
        mB = cute.make_tensor(b.iterator, cute.select(b.layout, mode=[0, 4, 3, 2, 1]))
        mB = cute.group_modes(mB, begin=1, end=5)
        b_internal_type = (
            cutlass.TFloat32 if mB.element_type is cutlass.Float32 else None
        )

        # --- B preferred ---
        b_op_preferred = sm100_utils.cluster_shape_to_tma_atom_B(
            self.preferred_cluster_shape_mn, tiled_mma.thr_id
        )
        tma_atom_b_preferred, tma_tensor_b_preferred = cute.nvgpu.make_tiled_tma_atom_B(
            b_op_preferred,
            mB,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
            internal_type=b_internal_type,
        )

        # --- B fallback ---
        b_op_fallback = sm100_utils.cluster_shape_to_tma_atom_B(
            self.fallback_cluster_shape_mn, tiled_mma.thr_id
        )
        tma_atom_b_fallback, tma_tensor_b_fallback = cute.nvgpu.make_tiled_tma_atom_B(
            b_op_fallback,
            mB,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.fallback_cluster_layout_vmnk.shape,
            internal_type=b_internal_type,
        )
        return (
            tma_atom_b_preferred,
            tma_tensor_b_preferred,
            tma_atom_b_fallback,
            tma_tensor_b_fallback,
        )

    def _make_sfb_tiled_tma_atoms(
        self,
        sfb: cute.Tensor,
        b: cute.Tensor,
        tiled_mma: cute.TiledMma,
        tiled_mma_sfb: cute.TiledMma,
    ) -> Tuple[cute.CopyAtom, cute.Tensor, cute.CopyAtom, cute.Tensor]:
        """Make SFB's preferred and fallback tiled TMA load atoms.

        SFB is viewed in B's GEMM shape and tiled by tiled_mma_sfb; each atom's copy
        op comes from its cluster shape and tiled_mma's CTA group. The two atoms
        differ only in the cluster shape they multicast over.

        :param sfb: Block scale factor tensor for B
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param tiled_mma: Tiled MMA configuration
        :param tiled_mma_sfb: Tiled MMA configuration of the SFB tiling, always one
            CTA group

        :return: (tma_atom_sfb_preferred, tma_tensor_sfb_preferred,
                tma_atom_sfb_fallback, tma_tensor_sfb_fallback)
        """
        # SFB takes B's GEMM view (K, C*S*R*T) with a flat integer K extent, which
        # maps onto the flat swizzled SFB storage. The N extent is the dynamic
        # b.shape[0], which keeps the window mode for a partial last tile. The
        # channel extent is SFB's padded span.
        sfb_c_span = cute.ceil_div(b.shape[4], self.sf_tile_k) * self.sf_tile_k
        b_shape_for_sfb = (
            b.shape[0],
            sfb_c_span * b.shape[1] * b.shape[2] * b.shape[3],
            1,
        )
        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
            b_shape_for_sfb, self.sf_vec_size
        )
        sfb = cute.make_tensor(sfb.iterator, sfb_layout)

        sfb_smem_layout = cute.slice_(
            self.sfb_smem_layout_staged, (None, None, None, 0)
        )

        # One atom per cluster shape: preferred first, then fallback.
        tma_atoms_and_tensors_sfb = []
        for cluster_shape_mn, cluster_layout_sfb_vmnk in (
            (self.preferred_cluster_shape_mn, self.preferred_cluster_layout_sfb_vmnk),
            (self.fallback_cluster_shape_mn, self.fallback_cluster_layout_sfb_vmnk),
        ):
            sfb_op = sm100_utils.cluster_shape_to_tma_atom_SFB(
                cluster_shape_mn, tiled_mma.thr_id
            )
            atom, tensor = cute.nvgpu.make_tiled_tma_atom_B(
                sfb_op,
                sfb,
                sfb_smem_layout,
                self.mma_tiler_sfb,
                tiled_mma_sfb,
                cluster_layout_sfb_vmnk.shape,
                internal_type=cutlass.Int16,
            )
            # Special-case for N=192: align the SFB scale-factor layout for Tensor
            # Memory packing
            if cutlass.const_expr(self.cta_tile_shape_mnk[1] == 192):
                x = tensor.stride[0][1]
                y = cute.ceil_div(tensor.shape[0][1], 4)
                new_shape = (
                    (tensor.shape[0][0], ((2, 2), y)),
                    tensor.shape[1],
                    tensor.shape[2],
                )
                x_times_3 = 3 * x
                new_stride = (
                    (tensor.stride[0][0], ((x, x), x_times_3)),
                    tensor.stride[1],
                    tensor.stride[2],
                )
                tensor = cute.make_tensor(
                    tensor.iterator,
                    cute.make_layout(new_shape, stride=new_stride),
                )
            tma_atoms_and_tensors_sfb += [atom, tensor]
        return tuple(tma_atoms_and_tensors_sfb)

    @staticmethod
    def _make_smem_layouts(
        tiled_mma: cute.TiledMma,
        mma_tiler: Tuple[int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        d_dtype: Type[cutlass.Numeric],
        d_layout: LayoutEnum,
        epi_tile: cute.Tile,
        num_ab_stage: int,
        num_d_stage: int,
    ) -> Tuple[cute.ComposedLayout, cute.ComposedLayout, cute.ComposedLayout]:
        """Build the staged shared memory layouts for A, B and the epilogue.

        :param tiled_mma: The tiled MMA the operands feed
        :param mma_tiler: The MMA tiler shape (M, N, K)
        :param a_dtype: Element type of A
        :param b_dtype: Element type of B
        :param d_dtype: Element type of D
        :param d_layout: Layout enum of D
        :param epi_tile: The epilogue tiler
        :param num_ab_stage: Number of A/B pipeline stages
        :param num_d_stage: Number of epilogue pipeline stages

        :return: The A, B and epilogue layouts, each staged
        """
        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma, mma_tiler, a_dtype, num_ab_stage
        )
        b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma, mma_tiler, b_dtype, num_ab_stage
        )
        d_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            d_dtype, d_layout, epi_tile, num_d_stage
        )
        return a_smem_layout_staged, b_smem_layout_staged, d_smem_layout_staged

    @staticmethod
    def _make_sf_smem_layouts(
        tiled_mma: cute.TiledMma,
        flat_mma_tiler_sf: Tuple[int, int, int],
        sf_vec_size: int,
        num_ab_stage: int,
    ) -> Tuple[cute.Layout, cute.Layout]:
        """Build the staged shared memory layouts for the A and B scale factors.

        These take the flat-K SF tiler: the blockscaled utils expect a scalar K
        where conv carries a (K,) tuple, and K runs on the SF cadence.

        :param tiled_mma: The tiled MMA the scale factors feed
        :param flat_mma_tiler_sf: The MMA tiler with a flat K on the SF cadence
        :param sf_vec_size: Number of channels one scale factor covers
        :param num_ab_stage: Number of A/B pipeline stages

        :return: The SFA and SFB layouts, each staged
        """
        sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma, flat_mma_tiler_sf, sf_vec_size, num_ab_stage
        )
        sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma, flat_mma_tiler_sf, sf_vec_size, num_ab_stage
        )
        return sfa_smem_layout_staged, sfb_smem_layout_staged

    def _make_shared_storage(self, *, num_ab_stage: int, num_d_stage: int):
        """Complete shared-memory layout for one candidate stage assignment.

        Stage selection sizes candidates through it and the device entry allocates
        through it. Every shared-memory consumer of this kernel is a field here, in
        three runs: pipeline barriers, small odds and ends, then the tensor buffers.
        """
        a_smem, b_smem, d_smem = self._make_smem_layouts(
            self.tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.d_dtype,
            self.d_layout,
            self.epi_tile,
            num_ab_stage,
            num_d_stage,
        )
        sfa_smem, sfb_smem = self._make_sf_smem_layouts(
            self.tiled_mma, self.flat_mma_tiler_sf, self.sf_vec_size, num_ab_stage
        )
        num_acc_stage = self.num_acc_stage
        num_clc_stage = self.num_clc_stage
        num_clc_response_bytes = self.num_clc_response_bytes
        has_bias = self.has_bias
        has_residual = self.has_residual
        cta_tile_n = self.cta_tile_shape_mnk[1]
        a_dtype, b_dtype = self.a_dtype, self.b_dtype
        sf_dtype, d_dtype = self.sf_dtype, self.d_dtype
        bias_dtype = self.bias_dtype if has_bias else d_dtype
        align = SMEM_BUFFER_ALIGN_BYTES

        @cute.struct
        class SharedStorage:
            # Pipeline barriers, in construction order.
            # Shared TMA pipeline barriers for A, B and SFB
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, num_ab_stage * 2]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, num_acc_stage * 2]
            # Residual TMA load pipeline barriers (full/empty per stage).
            c_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, num_d_stage * 2 if has_residual else 0
            ]
            tmem_dealloc_mbar: cutlass.Int64
            # CLC pipeline barriers and response buffer
            clc_mbar_ptr: cute.struct.MemRange[cutlass.Int64, num_clc_stage * 2]
            # Small odds and ends.
            tmem_holding_buf: cutlass.Int32
            clc_response: cute.struct.Align[
                cute.struct.MemRange[
                    cutlass.Int32, num_clc_response_bytes // 4 * num_clc_stage
                ],
                16,
            ]
            # Tensor buffers, last: epilogue staging first, then the mainloop
            # operand buffers at the very end of the storage, which keeps every
            # other field's offset fixed when an operand buffer grows.
            # (EPI_TILE_M, EPI_TILE_N, STAGE)
            sD: cute.struct.Align[
                cute.struct.MemRange[d_dtype, cute.cosize(d_smem.outer)], align
            ]
            # (cta_tile_n,) staged bias row for the shared-memory broadcast.
            # One value per output channel in the CTA's N-tile, in the bias element
            # type, which has a 16-bit floor and so can be wider than the output;
            # sized to zero when no bias is supplied so it costs no smem.
            sBias: cute.struct.Align[
                cute.struct.MemRange[bias_dtype, cta_tile_n if has_bias else 0],
                SMEM_VECTOR_ALIGN_BYTES,
            ]
            # (EPI_TILE_M, EPI_TILE_N, STAGE) residual tile, same layout as sD.
            # Sized to zero when no residual is supplied so it costs no smem.
            sC: cute.struct.Align[
                cute.struct.MemRange[
                    d_dtype,
                    cute.cosize(d_smem.outer) if has_residual else 0,
                ],
                align,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            sA: cute.struct.Align[
                cute.struct.MemRange[a_dtype, cute.cosize(a_smem.outer)], align
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sB: cute.struct.Align[
                cute.struct.MemRange[b_dtype, cute.cosize(b_smem.outer)], align
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            sSFA: cute.struct.Align[
                cute.struct.MemRange[sf_dtype, cute.cosize(sfa_smem)], align
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sSFB: cute.struct.Align[
                cute.struct.MemRange[sf_dtype, cute.cosize(sfb_smem)], align
            ]

        return SharedStorage

    def _make_acc_fake_tensor(self, tiled_mma, mma_tiler):
        """Build the accumulator fake tensor used for TMEM column accounting.

        For overlapping-accum the second logical acc buffer is strided into the
        columns otherwise reserved for SFA/SFB (so the next tile's math can
        overlap the current tile's epilogue). The stride for the stage dim is
        (cta_tile_n - num_sf_tmem_cols) * stride[0][1], the block-scaled GEMM
        overlapping-accum layout. Otherwise fall back to a plain num_acc_stage fake.
        """
        acc_shape = tiled_mma.partition_shape_C(mma_tiler[:2])
        if cutlass.const_expr(self.overlapping_accum):
            tCtAcc_fake = tiled_mma.make_fragment_C(cute.append(acc_shape, 2))
            s = tCtAcc_fake.stride
            return cute.make_tensor(
                tCtAcc_fake.iterator,
                cute.make_layout(
                    tCtAcc_fake.shape,
                    stride=(
                        s[0],
                        s[1],
                        s[2],
                        (self.cta_tile_shape_mnk[1] - self.num_sf_tmem_cols) * s[0][1],
                    ),
                ),
            )
        return tiled_mma.make_fragment_C(cute.append(acc_shape, self.num_acc_stage))

    @staticmethod
    def _compute_num_tmem_alloc_cols(
        tiled_mma: cute.TiledMma,
        mma_tiler: Tuple[int, int, int],
        num_acc_stage: int,
        arch: str,
    ) -> int:
        """
        Compute the number of tensor memory allocation columns.

        :param tiled_mma: The tiled MMA object defining the core computation.
        :type tiled_mma: cute.TiledMma
        :param mma_tiler: The shape (M, N, K) of the MMA tile.
        :type mma_tiler: tuple[int, int, int]
        :param num_acc_stage: The stage of the accumulator tensor.
        :type num_acc_stage: int

        :return: The number of tensor memory allocation columns.
        :rtype: int
        """
        acc_shape = tiled_mma.partition_shape_C(mma_tiler[:2])
        tCtAcc_fake = tiled_mma.make_fragment_C(cute.append(acc_shape, num_acc_stage))
        num_tmem_alloc_cols = cutlass.memory.get_num_tmem_alloc_cols(
            tCtAcc_fake, arch=arch
        )

        return num_tmem_alloc_cols

    # Stage one k tile of SFA from a gmem row offset and predicate the caller keeps
    # on per-tile state. The row offset and predicate are rebuilt only when a filter
    # counter carries, so only the finished values are read every iteration.
    @cute.jit
    def sfa_cpasync_copy_tile_precomputed(
        self,
        mSFA_mkl: cute.Tensor,
        sSFA_ktile: cute.Tensor,
        atom: cute.CopyAtom,
        predicate_tensor: cute.Tensor,
        sfa_row_off: cutlass.Int32,
        sfa_pred_val: cutlass.Boolean,
        sf_k_base: cutlass.Int32,
        sf_k_per_ktile: int,
        sfa_last_group: cutlass.Int32,
        tidx_in_warpgroup: cutlass.Int32,
    ) -> None:
        """Issue this k tile's SFA cp.async transfers into the staged smem tile.

        :param mSFA_mkl: The global SFA tensor
        :param sSFA_ktile: This stage's slice of the staged SFA smem tensor
        :param atom: The 4-byte gmem->smem copy atom
        :param predicate_tensor: The single-element register predicate the copy reads
        :param sfa_row_off: Gmem row offset of this lane's pixel, 0 when predicated off
        :param sfa_pred_val: Whether this lane's pixel is in bounds
        :param sf_k_base: SF-K base offset of the current channel tile
        :param sf_k_per_ktile: SF blocks one k tile spans
        :param sfa_last_group: Last whole SF atom this row owns
        :param tidx_in_warpgroup: This thread's index within the SFA warp group
        """
        # 4-byte cp.async SFA -- all SI share the same fpos. Each thread covers every
        # SI in [0, num_sfa_cpasync) exactly once so all SF-K groups of its row get
        # written: the rotation (q + i) % num is a complete cyclic cover for any
        # count and keeps quarter-warps on distinct groups.
        for i in range(self.num_sfa_cpasync):
            SI = ((tidx_in_warpgroup % 32) // 8 + i) % self.num_sfa_cpasync

            # One 4-byte cp.async moves 4 contiguous SF blocks (4 x 1-byte E4M3 = the
            # 4-byte transfer). SI indexes which group of 4, so its SF-block base is
            # SI * 4 and the copy shape is (4,).
            sf_k_smem = SI * 4
            local_sf_k = sf_k_base + (sf_k_smem % sf_k_per_ktile)
            # A partial trailing tile reaches past the scale factors this pixel owns.
            # Clamping the group start to the row's last whole atom keeps it in bounds
            # and finite, which the MMA needs since it applies the scale before seeing
            # the zero operand.
            local_sf_k = local_sf_k if local_sf_k <= sfa_last_group else sfa_last_group

            predicate_tensor[0] = sfa_pred_val

            # Gmem: this fpos's row offset plus the local SF-K offset
            tAgSFA_slice_ptr = mSFA_mkl.iterator + (sfa_row_off + local_sf_k)
            tAgSFA_slice = cute.make_tensor(
                tAgSFA_slice_ptr, layout=cute.make_layout((4,))
            )

            # Smem: write to swizzled position. Adjacent SF-block groups are 512 bytes
            # apart in the SFA smem layout: CTA_M (128 rows) x 4 bytes per group = 512.
            tAsSFA_slice_ptr = sSFA_ktile.iterator + 512 * SI
            tAsSFA_slice = cute.make_tensor(tAsSFA_slice_ptr, cute.make_layout((4,)))

            cute.copy_atom_call(
                atom,
                tAgSFA_slice,
                tAsSFA_slice,
                pred=predicate_tensor,
            )

    def mainloop_s2t_copy_and_partition(
        self,
        sSF: cute.Tensor,
        tSF: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Make tiledCopy for smem to tmem load for scale factor tensor, then use it to
        partition smem memory (source) and tensor memory (destination).

        :param sSF: The scale factor tensor in smem
        :type sSF: cute.Tensor
        :param tSF: The scale factor tensor in tmem
        :type tSF: cute.Tensor

        :return: A tuple containing (tiled_copy_s2t, tCsSF_compact_s2t,
            tCtSF_compact_s2t) where:
            - tiled_copy_s2t: The tiled copy operation for smem to tmem load for scale
              factor tensor(s2t)
            - tCsSF_compact_s2t: The partitioned scale factor tensor in smem
            - tSF_compact_s2t: The partitioned scale factor tensor in tmem
        :rtype: Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]
        """
        # (MMA, MMA_MN, MMA_K, STAGE)
        tCsSF_compact = cute.filter_zeros(sSF)
        # (MMA, MMA_MN, MMA_K)
        tCtSF_compact = cute.filter_zeros(tSF)

        # Make S2T CopyAtom and tiledCopy
        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp4x32x128bOp(self.cta_group),
            self.sf_dtype,
        )
        tiled_copy_s2t = tcgen05.make_s2t_copy(copy_atom_s2t, tCtSF_compact)
        thr_copy_s2t = tiled_copy_s2t.get_slice(0)

        # ((ATOM_V, REST_V), Rest_Tiler, MMA_MN, MMA_K, STAGE)
        tCsSF_compact_s2t_ = thr_copy_s2t.partition_S(tCsSF_compact)
        # ((ATOM_V, REST_V), Rest_Tiler, MMA_MN, MMA_K, STAGE)
        tCsSF_compact_s2t = tcgen05.get_s2t_smem_desc_tensor(
            tiled_copy_s2t, tCsSF_compact_s2t_
        )
        # ((ATOM_V, REST_V), Rest_Tiler, MMA_MN, MMA_K)
        tCtSF_compact_s2t = thr_copy_s2t.partition_D(tCtSF_compact)

        return tiled_copy_s2t, tCsSF_compact_s2t, tCtSF_compact_s2t

    def epilog_tmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        tAcc: cute.Tensor,
        gD_mnl: cute.Tensor,
        epi_tile: cute.Tile,
        use_2cta_instrs: Union[cutlass.Boolean, bool],
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Make tiledCopy for tensor memory load, then use it to partition tensor memory
        (source) and register array (destination).

        :param tidx: The thread index in epilogue warp groups
        :type tidx: cutlass.Int32
        :param tAcc: The accumulator tensor to be copied and partitioned
        :type tAcc: cute.Tensor
        :param gD_mnl: The global tensor D
        :type gD_mnl: cute.Tensor
        :param epi_tile: The epilogue tiler
        :type epi_tile: cute.Tile
        :param use_2cta_instrs: Whether use_2cta_instrs is enabled
        :type use_2cta_instrs: bool

        :return: A tuple containing (tiled_copy_t2r, tTR_tAcc, tTR_rAcc) where:
            - tiled_copy_t2r: The tiled copy operation for tmem to register copy(t2r)
            - tTR_tAcc: The partitioned accumulator tensor
            - tTR_rAcc: The accumulated tensor in register used to hold t2r results
        :rtype: Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]
        """
        # Make tiledCopy for tensor memory load
        copy_atom_t2r = sm100_utils.get_tmem_load_op(
            self.cta_tile_shape_mnk,
            self.d_layout,
            self.d_dtype,
            self.acc_dtype,
            epi_tile,
            use_2cta_instrs,
        )
        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, STAGE)
        tAcc_epi = cute.flat_divide(
            tAcc[((None, None), 0, 0, None)],
            epi_tile,
        )
        # (EPI_TILE_M, EPI_TILE_N)
        tiled_copy_t2r = tcgen05.make_tmem_copy(
            copy_atom_t2r, tAcc_epi[(None, None, 0, 0, 0)]
        )

        thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_M, STAGE)
        tTR_tAcc = thr_copy_t2r.partition_S(tAcc_epi)

        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, RestM, RestN, RestL)
        gD_mnl_epi = cute.flat_divide(
            gD_mnl[((None, None), 0, 0, None, None, None)], epi_tile
        )
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
        tTR_gD = thr_copy_t2r.partition_D(gD_mnl_epi)
        # (T2R, T2R_M, T2R_N)
        tTR_rAcc = cute.make_rmem_tensor(
            tTR_gD[(None, None, None, 0, 0, 0, 0, 0)].shape, self.acc_dtype
        )
        return tiled_copy_t2r, tTR_tAcc, tTR_rAcc

    def epilog_smem_store_copy_and_partition(
        self,
        tiled_copy_t2r: cute.TiledCopy,
        tTR_rD: cute.Tensor,
        tidx: cutlass.Int32,
        sD: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for shared memory store, then use it to partition register
        array (source) and shared memory (destination).

        :param tiled_copy_t2r: The tiled copy operation for tmem to register copy(t2r)
        :param tTR_rD: The partitioned accumulator tensor
        :param tidx: The thread index in epilogue warp groups
        :param sD: The shared memory tensor to be copied and partitioned

        :return: A tuple containing (tiled_copy_r2s, tRS_rD, tRS_sD) where:
            - tiled_copy_r2s: The tiled copy operation for register to smem copy(r2s)
            - tRS_rD: The partitioned tensor D (register source)
            - tRS_sD: The partitioned tensor D (smem destination)
        """
        copy_atom_r2s = sm100_utils.get_smem_store_op(
            self.d_layout, self.d_dtype, self.acc_dtype, tiled_copy_t2r
        )
        tiled_copy_r2s = cute.make_tiled_copy_D(copy_atom_r2s, tiled_copy_t2r)
        # (R2S, R2S_M, R2S_N, PIPE_D)
        thr_copy_r2s = tiled_copy_r2s.get_slice(tidx)
        tRS_sD = thr_copy_r2s.partition_D(sD)
        # (R2S, R2S_M, R2S_N)
        tRS_rD = tiled_copy_r2s.retile(tTR_rD)
        return tiled_copy_r2s, tRS_rD, tRS_sD

    def epilog_smem_load_copy_and_partition(
        self,
        tiled_copy_t2r: cute.TiledCopy,
        tTR_rC: cute.Tensor,
        tidx: cutlass.Int32,
        sC: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Make tiledCopy for shared memory load, then use it to partition register
        array (destination) and shared memory (source). Used to read a residual
        tile that was TMA-loaded into smem back into registers, aligned to the
        accumulator's T2R fragment.

        :param tiled_copy_t2r: The tiled copy operation for tmem to register copy(t2r)
        :type tiled_copy_t2r: cute.TiledCopy
        :param tTR_rC: The register tensor shaped like the accumulator fragment
        :type tTR_rC: cute.Tensor
        :param tidx: The thread index in epilogue warp groups
        :type tidx: cutlass.Int32
        :param sC: The shared memory tensor to be copied and partitioned
        :type sC: cute.Tensor

        :return: A tuple containing (tiled_copy_s2r, tSR_rC, tSR_sC) where:
            - tiled_copy_s2r: The tiled copy operation for smem to register copy(s2r)
            - tSR_rC: The partitioned register tensor (destination)
            - tSR_sC: The partitioned shared memory tensor (source)
        :rtype: Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]
        """
        copy_atom_s2r = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), self.d_dtype)
        tiled_copy_s2r = cute.make_tiled_copy_D(copy_atom_s2r, tiled_copy_t2r)
        # (S2R, S2R_M, S2R_N, PIPE)
        thr_copy_s2r = tiled_copy_s2r.get_slice(tidx)
        tSR_sC = thr_copy_s2r.partition_D(sC)
        # (S2R, S2R_M, S2R_N)
        tSR_rC = tiled_copy_s2r.retile(tTR_rC)
        return tiled_copy_s2r, tSR_rC, tSR_sC

    def epilog_gmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        atom: Union[cute.CopyAtom, cute.TiledCopy],
        gD_mnl: cute.Tensor,
        epi_tile: cute.Tile,
        sD: cute.Tensor,
    ) -> Tuple[cute.CopyAtom, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for global memory store, then use it to:
        partition shared memory (source) and global memory (destination) for TMA store
        version.

        :param tidx: The thread index in epilogue warp groups
        :type tidx: cutlass.Int32
        :param atom: The copy_atom_d to be used for TMA store version, or tiled_copy_t2r
            for none TMA store version
        :type atom: cute.CopyAtom or cute.TiledCopy
        :param gD_mnl: The global tensor D
        :type gD_mnl: cute.Tensor
        :param epi_tile: The epilogue tiler
        :type epi_tile: cute.Tile
        :param sD: The shared memory tensor to be copied and partitioned
        :type sD: cute.Tensor

        :return: A tuple containing (tma_atom_d, bSG_sD, bSG_gD) where:
            - tma_atom_d: The TMA copy atom
            - bSG_sD: The partitioned shared memory tensor D
            - bSG_gD: The partitioned global tensor D
        :rtype: Tuple[cute.CopyAtom, cute.Tensor, cute.Tensor]
        """
        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, RestM, RestN, RestL)
        gD_epi = cute.flat_divide(
            gD_mnl[((None, None), 0, 0, None, None, None)], epi_tile
        )

        tma_atom_d = atom
        sD_for_tma_partition = cute.group_modes(sD, 0, 2)
        gD_for_tma_partition = cute.group_modes(gD_epi, 0, 2)
        # ((ATOM_V, REST_V), EPI_M, EPI_N)
        # ((ATOM_V, REST_V), EPI_M, EPI_N, RestM, RestN, RestL)
        bSG_sD, bSG_gD = cpasync.tma_partition(
            tma_atom_d,
            0,
            cute.make_layout(1),
            sD_for_tma_partition,
            gD_for_tma_partition,
        )
        return tma_atom_d, bSG_sD, bSG_gD

    def epilog_bias_smem_partition(
        self,
        tiled_copy_t2r: cute.TiledCopy,
        tidx: cutlass.Int32,
        sBias: cute.Tensor,
        epi_tile: cute.Tile,
    ) -> cute.Tensor:
        """Partition the CTA-staged bias row for the epilogue's shared memory reads.

        The row holds this CTA tile's output channels, so it is viewed as a CTA
        tile whose N axis is the channel (stride 1) and whose M axis repeats it
        (stride 0), then partitioned through the same tmem->rmem thread layout as
        the accumulator. Rooting that partition at the row itself puts a thread's
        own tile-local N offset on the shared memory pointer, which matters whenever
        the CTA tile has fewer M rows than the epilogue has threads and the thread
        layout also spans N.

        :param tiled_copy_t2r: The tiled copy operation for tmem to register copy(t2r)
        :param tidx: The thread index in epilogue warp groups
        :param sBias: The staged bias row, one value per output channel of this CTA tile
        :param epi_tile: The epilogue tiler

        :return: The staged row partitioned as (T2R, T2R_M, T2R_N, SUBTILE), with
            the subtiles grouped to index alongside the accumulator's
        """
        # (cta_tile_m, cta_tile_n) - one channel per N column, repeated over M
        sBias_mn = cute.make_tensor(
            sBias.iterator,
            cute.make_layout(
                (self.cta_tile_shape_mnk[0], self.cta_tile_shape_mnk[1]),
                stride=(0, 1),
            ),
        )
        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N)
        sBias_epi = cute.flat_divide(sBias_mn, epi_tile)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N)
        tTR_sBias = tiled_copy_t2r.get_slice(tidx).partition_D(sBias_epi)
        return cute.group_modes(tTR_sBias, 3, 5)

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        sfa: cute.Tensor,
        sfb: cute.Tensor,
        d: cute.Tensor,
        sfd: Optional[cute.Tensor],
        bias: Optional[cute.Tensor],
        c: Optional[cute.Tensor],
        alpha: cutlass.Float32,
        beta: cutlass.Constexpr,
        norm_const: cutlass.Float32,
        # Conv pad / stride / dilation as cute.compile entry scalars, boxed as
        # cutlass.Int32 by the caller so they lower to runtime SSA.
        rt_upper_pad_d: cutlass.Int32,
        rt_upper_pad_h: cutlass.Int32,
        rt_upper_pad_w: cutlass.Int32,
        rt_lower_pad_d: cutlass.Int32,
        rt_lower_pad_h: cutlass.Int32,
        rt_lower_pad_w: cutlass.Int32,
        rt_stride_d: cutlass.Int32,
        rt_stride_h: cutlass.Int32,
        rt_stride_w: cutlass.Int32,
        rt_dil_d: cutlass.Int32,
        rt_dil_h: cutlass.Int32,
        rt_dil_w: cutlass.Int32,
        stream: cuda.CUstream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ) -> None:
        """Execute the persistent convolution with dynamic preferred-cluster scheduling.

        Pad / stride / dilation arrive as runtime cutlass.Int32, which the rt_ prefix
        marks, so one compiled cubin serves any geometry. The same values feed both
        the host im2col A descriptor corner and the device SFA cp.async coord
        reconstruction, keeping A's load coords and SFA's in lockstep.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param sfa: Block scale factor tensor for A
        :param sfb: Block scale factor tensor for B, same element type as sfa
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        :param sfd: Output scale factor tensor, same element type as sfa; pass None
            to skip SFD generation
        :param bias: Optional length-K (output channel) device tensor; a
            per-output-channel bias added to the accumulator in FP32 as
            D = epilogue_op(alpha * acc + bias). Pass None to skip bias.
        :param c: Optional (N, Z, P, Q, K) device tensor with the
            same shape/layout as the output D; a per-element residual added to
            the accumulator in FP32 as D = epilogue_op(alpha * acc + bias +
            beta * residual). Loaded through the epilogue via a TMA im2col G2S
            copy (the inverse of the output store) into shared memory, then read
            to registers. Required when beta != 0.
        :param alpha: FP32 runtime scalar; applied to the accumulator in FP32
            before output quantization
        :param beta: compile-time residual scaling constant. beta == 0 removes
            the entire residual path (smem, pipeline, TMA load, add) via const
            DCE; beta != 0 scales the residual as D = alpha * acc + bias +
            beta * residual and requires c. A distinct beta value
            yields a distinct cubin.
        :param norm_const: FP32 runtime scalar; per-tensor amax-derived global FP4
            scale, multiplied into the SFD encode step. Only used when sfd is
            provided.
        :param rt_upper_pad_d/h/w: Upper padding (D, H, W)
        :param rt_lower_pad_d/h/w: Lower padding (D, H, W)
        :param rt_stride_d/h/w: Convolution stride (D, H, W)
        :param rt_dil_d/h/w: Dilation (D, H, W)
        :param stream: CUDA stream for asynchronous execution
        :param epilogue_op: Optional elementwise lambda function to apply to the output
            tensor
        """
        self._setup_conv_input_attrs(a, b, d)
        self.sf_dtype: Type[cutlass.Numeric] = sfa.element_type
        # Bias opt-in: caller supplies a length-K per-output-channel tensor.
        self.has_bias: bool = bias is not None
        self.bias_dtype: Optional[Type[cutlass.Numeric]] = (
            bias.element_type if bias is not None else None
        )
        # Residual opt-in via compile-time beta: beta == 0 removes the whole
        # residual path through const DCE; beta != 0 scales the per-element
        # residual as alpha*acc + bias + beta*residual and needs c.
        self.beta: cutlass.Constexpr = beta
        self.has_residual: bool = beta != 0.0
        # Finalize the CTA thread count now that has_residual is known: the
        # dedicated residual G2S warp only exists when beta != 0, so beta == 0
        # launches with no extra idle warp.
        if cutlass.const_expr(self.has_residual):
            self.threads_per_cta = 32 * (len(self.base_warp_ids) + 1)
        else:
            self.threads_per_cta = 32 * len(self.base_warp_ids)
        # SFD shares the input sf_dtype (E4M3 for NVFP4, E8M0 for MXFP8).
        self.sfd_dtype: Type[cutlass.Numeric] = self.sf_dtype
        # SFD opt-in: caller supplies sfd. SFD is valid only with a narrow
        # output (FP4 or FP8 E4M3). norm_const is a plain FP32 scalar folded
        # into the SFD scale-up.
        self.gen_sfd: bool = sfd is not None
        self._setup_attributes()

        # Pack the pad/stride/dilation operands into the tuples that the im2col A
        # descriptor corner and the device per-tile coord math both consume.
        rt_upper_pad_dhw = (rt_upper_pad_d, rt_upper_pad_h, rt_upper_pad_w)
        rt_lower_pad_dhw = (rt_lower_pad_d, rt_lower_pad_h, rt_lower_pad_w)
        rt_stride_dhw = (rt_stride_d, rt_stride_h, rt_stride_w)
        rt_dil_dhw = (rt_dil_d, rt_dil_h, rt_dil_w)
        # Filter T/R/S from the dynamic-layout filter tensor b (K, T, R, S, C):
        # runtime Int32 so one cubin serves any T/R/S. Fed to the device
        # kernel's rt_filter_t/r/s params.
        rt_filter_t, rt_filter_r, rt_filter_s = (
            b.shape[1],
            b.shape[2],
            b.shape[3],
        )

        (
            tma_atom_a_preferred,
            tma_tensor_a_preferred,
            tma_atom_a_fallback,
            tma_tensor_a_fallback,
            tma_atom_b_preferred,
            tma_tensor_b_preferred,
            tma_atom_b_fallback,
            tma_tensor_b_fallback,
            tma_atom_d,
            tma_tensor_d,
            tma_atom_c,
            tma_tensor_c,
            tma_atom_sfb_preferred,
            tma_tensor_sfb_preferred,
            tma_atom_sfb_fallback,
            tma_tensor_sfb_fallback,
        ) = self._setup_conv_tma(
            a,
            b,
            d,
            c,
            sfb,
            self.tiled_mma,
            self.tiled_mma_sfb,
            rt_upper_pad_dhw,
            rt_lower_pad_dhw,
            rt_stride_dhw,
            rt_dil_dhw,
        )

        # Compute grid size and scheduler params for both cluster shapes
        self.fallback_tile_sched_params, _ = compute_grid(
            tma_tensor_d,
            self.cta_tile_shape_mnk,
            self.fallback_cluster_shape_mn,
            self.swizzle_size,
            self.raster_along,
        )
        self.preferred_tile_sched_params, preferred_grid = compute_grid(
            tma_tensor_d,
            self.cta_tile_shape_mnk,
            self.preferred_cluster_shape_mn,
            self.swizzle_size,
            self.raster_along,
        )

        K_gemm_tile = self.mma_tiler[2][0]  # mma_inst_shape_k * mma_inst_tile_k

        # mSFD takes mD's (M, K, 1) profile, with M the flat NZPQ pixel axis and K
        # as (sfd_vec_size, sf_k_padded) strided (0, 1) so sfd_vec_size consecutive
        # K elements share one physical scale factor. Storage takes SFA's
        # K-contig-in-M form, (mn, sf_k, 1) with mn-stride = sf_k, except that sf_k
        # is rounded up: it counts Kout, which no gate constrains.
        if cutlass.const_expr(self.gen_sfd):
            # Source N/Z/P/Q/K from the dynamic input/output tensors (runtime Int) so
            # one cubin serves any output geometry. The SFD store is a scalar
            # per-element STG with a static (unrolled) element count, so only the
            # per-thread tile is static; the global extent/strides can be runtime.
            sfd_N = cute.size(a, mode=[0])
            sfd_Z = cute.size(d, mode=[1])
            sfd_P = cute.size(d, mode=[2])
            sfd_Q = cute.size(d, mode=[3])
            sf_k = (cute.size(d, mode=[4]) + self.sfd_vec_size - 1) // self.sfd_vec_size
            sf_k_padded = ((sf_k + 3) // 4) * 4  # pad sf_k to multiple of 4
            stride_mn = sf_k_padded
            # The M axis is a single flat N*Z*P*Q extent with a uniform row stride,
            # which local_tile splits by the CTA tile. The SFD buffer is dense
            # row-major NZPQ, so the flat extent tiles cleanly.
            sfd_M = sfd_N * sfd_Z * sfd_P * sfd_Q
            mSFD_layout = cute.make_layout(
                (
                    sfd_M,
                    (self.sfd_vec_size, sf_k_padded),
                    1,
                ),
                stride=(
                    stride_mn,
                    (0, 1),
                    sfd_M * stride_mn,
                ),
            )
            mSFD_mnl = cute.make_tensor(sfd.iterator, mSFD_layout)
        else:
            mSFD_mnl = None

        # Per-output-channel bias broadcast to mD's ((Q,P,Z,N), K, 1) = (M, N, L)
        # profile: real stride 1 along the output channel (GEMM-N), stride 0 across
        # every spatial position (GEMM-M = Q,P,Z,N), so the epilogue reads it through
        # the accumulator's partition_C chain and each thread lands on its own
        # N-column bias scalar.
        if cutlass.const_expr(self.has_bias):
            # The M (spatial) modes are stride-0 broadcast: every output row reads
            # the same bias[k], so a static M extent keeps the partitioned smem-read
            # layout static for a vectorized load, while the runtime N stride lets
            # one cubin serve any channel count. The M extent only covers the CTA
            # tile; the real output-M size arrives at the store site as a coordinate.
            mBias_layout = cute.make_layout(
                (
                    (self.cta_tile_shape_mnk[0], 1, 1, 1),
                    cute.size(d, mode=[4]),
                    1,
                ),
                stride=((0, 0, 0, 0), 1, 0),
            )
            mBias_mnl = cute.make_tensor(bias.iterator, mBias_layout)
        else:
            mBias_mnl = None

        self.shared_storage = (
            Sm100BlockScaledDenseImplicitGemmFpropKernel._make_shared_storage(
                self, num_ab_stage=self.num_ab_stage, num_d_stage=self.num_d_stage
            )
        )

        # Launch the kernel synchronously; it selects the preferred or fallback path.
        self.kernel(
            tma_atom_a_preferred,
            tma_tensor_a_preferred,
            tma_atom_a_fallback,
            tma_tensor_a_fallback,
            tma_atom_b_preferred,
            tma_tensor_b_preferred,
            tma_atom_b_fallback,
            tma_tensor_b_fallback,
            sfa,
            tma_atom_sfb_preferred,
            tma_tensor_sfb_preferred,
            tma_atom_sfb_fallback,
            tma_tensor_sfb_fallback,
            tma_atom_d,
            tma_tensor_d,
            mSFD_mnl,
            mBias_mnl,
            tma_atom_c,
            tma_tensor_c,
            alpha,
            norm_const,
            self.tiled_mma,
            self.tiled_mma_sfb,
            self.preferred_cluster_layout_vmnk,
            self.fallback_cluster_layout_vmnk,
            self.preferred_cluster_layout_sfb_vmnk,
            self.fallback_cluster_layout_sfb_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.d_smem_layout_staged,
            self.epi_tile,
            self.preferred_tile_sched_params,
            self.fallback_tile_sched_params,
            # a: (N, D, H, W, C), d: (N, Z, P, Q, K)
            cute.size(a, mode=[0]),
            cute.size(a, mode=[1]),
            cute.size(a, mode=[2]),
            cute.size(a, mode=[3]),
            cute.size(a, mode=[4]),
            cute.size(d, mode=[1]),
            cute.size(d, mode=[2]),
            cute.size(d, mode=[3]),
            rt_filter_t,
            rt_filter_r,
            rt_filter_s,
            # The leading (lower) pad is what the im2col A descriptor subtracts
            # when it maps output coords to input coords:
            #   d_in = z*stride - lower_pad + t*dil
            rt_lower_pad_dhw[0],
            rt_lower_pad_dhw[1],
            rt_lower_pad_dhw[2],
            rt_stride_dhw[0],
            rt_stride_dhw[1],
            rt_stride_dhw[2],
            rt_dil_dhw[0],
            rt_dil_dhw[1],
            rt_dil_dhw[2],
            K_gemm_tile,
            epilogue_op,
        ).launch(
            grid=preferred_grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.preferred_cluster_shape_mn, 1),
            fallback_cluster=(*self.fallback_cluster_shape_mn, 1),
            stream=stream,
            smem_merge_branch_allocs=True,
        )
        return

    # GPU device kernel - dispatches to the preferred or the fallback cluster path
    @cute.kernel
    def kernel(
        self,
        tma_atom_a_preferred: cute.CopyAtom,
        mA_mkl_preferred: cute.Tensor,
        tma_atom_a_fallback: cute.CopyAtom,
        mA_mkl_fallback: cute.Tensor,
        tma_atom_b_preferred: cute.CopyAtom,
        mB_nkl_preferred: cute.Tensor,
        tma_atom_b_fallback: cute.CopyAtom,
        mB_nkl_fallback: cute.Tensor,
        mSFA_mkl: cute.Tensor,
        tma_atom_sfb_preferred: cute.CopyAtom,
        mSFB_nkl_preferred: cute.Tensor,
        tma_atom_sfb_fallback: cute.CopyAtom,
        mSFB_nkl_fallback: cute.Tensor,
        tma_atom_d: cute.CopyAtom,
        mD_mnl: cute.Tensor,
        mSFD_mnl: Optional[cute.Tensor],
        mBias_mnl: Optional[cute.Tensor],
        tma_atom_c: Optional[cute.CopyAtom],
        mC_mnl: Optional[cute.Tensor],
        alpha: cutlass.Float32,
        norm_const: cutlass.Float32,
        tiled_mma: cute.TiledMma,
        tiled_mma_sfb: cute.TiledMma,
        preferred_cluster_layout_vmnk: cute.Layout,
        fallback_cluster_layout_vmnk: cute.Layout,
        preferred_cluster_layout_sfb_vmnk: cute.Layout,
        fallback_cluster_layout_sfb_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        d_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
        preferred_tile_sched_params: ClcDynamicPersistentTileSchedulerParams,
        fallback_tile_sched_params: ClcDynamicPersistentTileSchedulerParams,
        # Conv parameters for SFA im2col coordinate mapping.
        # Coordinate geometry: runtime Int32 so the per-tile NDHW decomposition
        # (m_global -> n,z,p,q) divides by runtime extents and one cubin serves
        # any N/D/H/W/Z/P/Q.
        input_N: cutlass.Int32,
        input_D: cutlass.Int32,
        input_H: cutlass.Int32,
        input_W: cutlass.Int32,
        input_C: cutlass.Int32,
        output_Z: cutlass.Int32,
        output_P: cutlass.Int32,
        output_Q: cutlass.Int32,
        # rt_filter_t/r/s are runtime Int32 so one cubin serves any filter size;
        # they only feed the K-loop's filter-position wrap comparisons (S->R->T).
        rt_filter_t: cutlass.Int32,
        rt_filter_r: cutlass.Int32,
        rt_filter_s: cutlass.Int32,
        # pad/stride/dilation are runtime Int32 so one cubin serves any conv
        # config; they feed the per-tile base-coord arithmetic (z*stride - pad)
        # and the K-loop dilation step.
        rt_lower_pad_d: cutlass.Int32,
        rt_lower_pad_h: cutlass.Int32,
        rt_lower_pad_w: cutlass.Int32,
        rt_stride_d: cutlass.Int32,
        rt_stride_h: cutlass.Int32,
        rt_stride_w: cutlass.Int32,
        rt_dil_d: cutlass.Int32,
        rt_dil_h: cutlass.Int32,
        rt_dil_w: cutlass.Int32,
        K_gemm_tile: cutlass.Constexpr,
        epilogue_op: cutlass.Constexpr,
    ) -> None:
        """
        GPU device kernel entry point: dispatches to preferred or fallback cluster path.
        """
        # Determine if this CTA is launched in a preferred-shape cluster
        cbdim_x, cbdim_y, cbdim_z = cute.arch.block_in_cluster_dim()
        is_preferred_cluster = (
            cbdim_x == self.preferred_cluster_shape_mn[0]
            and cbdim_y == self.preferred_cluster_shape_mn[1]
            and cbdim_z == 1
        )

        # Two mutually exclusive code branches, one per cluster shape; only one runs
        # per launch. smem_merge_branch_allocs=True at launch enables shared memory
        # reuse between the two paths.
        if is_preferred_cluster:
            self.cluster_specific_kernel(
                tma_atom_a_preferred,
                mA_mkl_preferred,
                tma_atom_b_preferred,
                mB_nkl_preferred,
                mSFA_mkl,
                tma_atom_sfb_preferred,
                mSFB_nkl_preferred,
                tma_atom_d,
                mD_mnl,
                mSFD_mnl,
                mBias_mnl,
                tma_atom_c,
                mC_mnl,
                alpha,
                norm_const,
                tiled_mma,
                tiled_mma_sfb,
                preferred_cluster_layout_vmnk,
                preferred_cluster_layout_sfb_vmnk,
                a_smem_layout_staged,
                b_smem_layout_staged,
                sfa_smem_layout_staged,
                sfb_smem_layout_staged,
                d_smem_layout_staged,
                epi_tile,
                preferred_tile_sched_params,
                input_N,
                input_D,
                input_H,
                input_W,
                input_C,
                output_Z,
                output_P,
                output_Q,
                rt_filter_t,
                rt_filter_r,
                rt_filter_s,
                rt_lower_pad_d,
                rt_lower_pad_h,
                rt_lower_pad_w,
                rt_stride_d,
                rt_stride_h,
                rt_stride_w,
                rt_dil_d,
                rt_dil_h,
                rt_dil_w,
                K_gemm_tile,
                self.num_preferred_mcast_ctas_a + self.num_preferred_mcast_ctas_b - 1,
                self.is_preferred_a_mcast,
                self.is_preferred_b_mcast,
                self.preferred_cluster_shape_mn,
                epilogue_op,
            )
        else:
            self.cluster_specific_kernel(
                tma_atom_a_fallback,
                mA_mkl_fallback,
                tma_atom_b_fallback,
                mB_nkl_fallback,
                mSFA_mkl,
                tma_atom_sfb_fallback,
                mSFB_nkl_fallback,
                tma_atom_d,
                mD_mnl,
                mSFD_mnl,
                mBias_mnl,
                tma_atom_c,
                mC_mnl,
                alpha,
                norm_const,
                tiled_mma,
                tiled_mma_sfb,
                fallback_cluster_layout_vmnk,
                fallback_cluster_layout_sfb_vmnk,
                a_smem_layout_staged,
                b_smem_layout_staged,
                sfa_smem_layout_staged,
                sfb_smem_layout_staged,
                d_smem_layout_staged,
                epi_tile,
                fallback_tile_sched_params,
                input_N,
                input_D,
                input_H,
                input_W,
                input_C,
                output_Z,
                output_P,
                output_Q,
                rt_filter_t,
                rt_filter_r,
                rt_filter_s,
                rt_lower_pad_d,
                rt_lower_pad_h,
                rt_lower_pad_w,
                rt_stride_d,
                rt_stride_h,
                rt_stride_w,
                rt_dil_d,
                rt_dil_h,
                rt_dil_w,
                K_gemm_tile,
                self.num_fallback_mcast_ctas_a + self.num_fallback_mcast_ctas_b - 1,
                self.is_fallback_a_mcast,
                self.is_fallback_b_mcast,
                self.fallback_cluster_shape_mn,
                epilogue_op,
            )

    @cute.jit()
    def cluster_specific_kernel(
        self,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        mSFA_mkl: cute.Tensor,
        tma_atom_sfb: cute.CopyAtom,
        mSFB_nkl: cute.Tensor,
        tma_atom_d: cute.CopyAtom,
        mD_mnl: cute.Tensor,
        mSFD_mnl: Optional[cute.Tensor],
        mBias_mnl: Optional[cute.Tensor],
        tma_atom_c: Optional[cute.CopyAtom],
        mC_mnl: Optional[cute.Tensor],
        alpha: cutlass.Float32,
        norm_const: cutlass.Float32,
        tiled_mma: cute.TiledMma,
        tiled_mma_sfb: cute.TiledMma,
        cluster_layout_vmnk: cute.Layout,
        cluster_layout_sfb_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        d_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
        tile_sched_params: ClcDynamicPersistentTileSchedulerParams,
        # Conv parameters for SFA im2col coordinate mapping.
        # Coordinate geometry: runtime Int32 so the per-tile NDHW decomposition
        # (m_global -> n,z,p,q) divides by runtime extents and one cubin serves
        # any N/D/H/W/Z/P/Q.
        input_N: cutlass.Int32,
        input_D: cutlass.Int32,
        input_H: cutlass.Int32,
        input_W: cutlass.Int32,
        input_C: cutlass.Int32,
        output_Z: cutlass.Int32,
        output_P: cutlass.Int32,
        output_Q: cutlass.Int32,
        # rt_filter_t/r/s are runtime Int32 so one cubin serves any filter size;
        # they only feed the K-loop's filter-position wrap comparisons (S->R->T).
        rt_filter_t: cutlass.Int32,
        rt_filter_r: cutlass.Int32,
        rt_filter_s: cutlass.Int32,
        # pad/stride/dilation are runtime Int32 so one cubin serves any conv
        # config; they feed the per-tile base-coord arithmetic (z*stride - pad)
        # and the K-loop dilation step.
        rt_lower_pad_d: cutlass.Int32,
        rt_lower_pad_h: cutlass.Int32,
        rt_lower_pad_w: cutlass.Int32,
        rt_stride_d: cutlass.Int32,
        rt_stride_h: cutlass.Int32,
        rt_stride_w: cutlass.Int32,
        rt_dil_d: cutlass.Int32,
        rt_dil_h: cutlass.Int32,
        rt_dil_w: cutlass.Int32,
        K_gemm_tile: cutlass.Constexpr,
        num_tma_producer: int,
        effective_is_a_mcast: bool,
        effective_is_b_mcast: bool,
        cluster_shape: Tuple[int, int],
        epilogue_op: cutlass.Constexpr,
    ) -> None:
        """
        GPU device kernel performing the CLC dynamic persistent convolution computation.
        """
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        #
        # Prefetch tma desc
        #
        if warp_idx == self.tma_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            # SFA has no TMA descriptor to prefetch: it is loaded via cp.async.
            cpasync.prefetch_descriptor(tma_atom_sfb)
            cpasync.prefetch_descriptor(tma_atom_d)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

        #
        # Setup cta/thread coordinates
        #
        # Coords inside cluster
        bidx, bidy, bidz = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        is_first_cta_in_cluster = cta_rank_in_cluster == 0
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        block_in_cluster_coord_sfb_vmnk = cluster_layout_sfb_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        # Coord inside cta
        tidx, _, _ = cute.arch.thread_idx()

        #
        # Alloc and init: a+b full/empty, accumulator full/empty, tensor memory dealloc
        # barrier
        #
        smem = SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # One mbarrier is shared between the TMA (A+B+SFB) and cp.async (SFA)
        # producers. arrive_count is the 128 cp.async lanes plus one TMA arrive,
        # which hardware propagates from the leader's multicast to every peer
        # barrier. Under 2CTA the peer's cp.async threads remote-arrive on the
        # leader's sfa_full too, keeping its MMA behind their copies: 257 total.
        sfa_cpasync_arrive_count = 257 if use_2cta_instrs else 129
        cpasynd_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, sfa_cpasync_arrive_count
        )
        merged_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_tma_producer
        )
        merged_tx_count = (
            self.num_tma_load_a_bytes
            + self.num_tma_load_b_bytes
            + self.num_tma_load_sfb_bytes
        )
        ab_sfa_pipeline = PipelineTmaCpAsyncUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            cpasynd_producer_group=cpasynd_producer_group,
            consumer_group=merged_consumer_group,
            tx_count=merged_tx_count,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )

        # Pipeline Init: Initialize acd_pipeline (barrier) and states
        acd_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_acc_consumer_threads = len(self.epilogue_warp_id) * (
            2 if use_2cta_instrs else 1
        )
        acd_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_acc_consumer_threads
        )
        acd_pipeline = pipeline.PipelineUmmaAsync.create(
            barrier_storage=storage.acc_full_mbar_ptr.data_ptr(),
            num_stages=self.num_acc_stage,
            producer_group=acd_pipeline_producer_group,
            consumer_group=acd_pipeline_consumer_group,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )

        # Pipeline Init: residual TMA load. The dedicated residual warp issues
        # the TMA load (single-thread producer arrive) into sC; all epilogue
        # warps consume it (one release arrive per warp). No multicast: each CTA
        # loads its own output-tile residual.
        if cutlass.const_expr(mC_mnl is not None):
            c_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
            c_consumer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len(self.epilogue_warp_id)
            )
            c_pipeline = pipeline.PipelineTmaAsync.create(
                barrier_storage=storage.c_full_mbar_ptr.data_ptr(),
                num_stages=self.num_d_stage,
                producer_group=c_producer_group,
                consumer_group=c_consumer_group,
                tx_count=self.num_tma_load_c_bytes,
                defer_sync=True,
            )
        else:
            c_pipeline = None

        # CLC fetch pipeline. Consumers per CTA: TMA(1) + cp.async SFA(4) + MMA(1)
        # + epilogue(4) [+ residual(1) when beta != 0] warps, times cluster_size,
        # plus sched(1) on the first CTA only; the tile-coord query is broadcast to
        # the whole cluster. The residual term must gate on the SAME const as the
        # residual warp's CLC-consume block or the counts diverge and this hangs.
        clc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        cluster_size = cute.size(cluster_shape)
        num_residual_clc_warps = 1 if cutlass.const_expr(mC_mnl is not None) else 0
        num_clc_consumer_threads = 32 * (
            1
            + cluster_size
            * (
                1
                + len(self.cpasync_sfa_warp_id)
                + len(self.epilogue_warp_id)
                + 1
                + num_residual_clc_warps
            )
        )
        clc_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_clc_consumer_threads
        )
        clc_pipeline = pipeline.PipelineClcFetchAsync.create(
            barrier_storage=storage.clc_mbar_ptr.data_ptr(),
            num_stages=self.num_clc_stage,
            producer_group=clc_pipeline_producer_group,
            consumer_group=clc_pipeline_consumer_group,
            tx_count=self.num_clc_response_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )

        # Pipeline Init: Tensor memory alloc/dealloc barrier init
        tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=self.tmem_alloc_sync_bar_id,
            num_threads=32 * len((self.mma_warp_id, *self.epilogue_warp_id)),
        )
        tmem = TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
        )

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=cluster_shape, is_relaxed=True)

        # CLC response buffer pointer + consumer state
        clc_response_ptr = storage.clc_response.data_ptr()
        clc_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self.num_clc_stage
        )

        #
        # Setup smem tensor A/B/SFA/SFB/D
        #
        # (EPI_TILE_M, EPI_TILE_N, STAGE)
        sD = storage.sD.get_tensor(
            d_smem_layout_staged.outer, swizzle=d_smem_layout_staged.inner
        )
        # (cta_tile_n,) bias row for the shared-memory-staged broadcast.
        if cutlass.const_expr(mBias_mnl is not None):
            sBias = storage.sBias.get_tensor(
                cute.make_layout(self.cta_tile_shape_mnk[1])
            )
        else:
            sBias = None
        # (EPI_TILE_M, EPI_TILE_N, STAGE) residual tile, same layout as sD.
        if cutlass.const_expr(mC_mnl is not None):
            sC = storage.sC.get_tensor(
                d_smem_layout_staged.outer, swizzle=d_smem_layout_staged.inner
            )
        else:
            sC = None
        # (MMA, MMA_M, MMA_K, STAGE)
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        # (MMA, MMA_N, MMA_K, STAGE)
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )
        # (MMA, MMA_M, MMA_K, STAGE)
        sSFA = storage.sSFA.get_tensor(sfa_smem_layout_staged)
        # (MMA, MMA_N, MMA_K, STAGE)
        sSFB = storage.sSFB.get_tensor(sfb_smem_layout_staged)

        #
        # Compute multicast mask for A/B/SFA/SFB buffer full
        #
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        sfb_full_mcast_mask = None

        if cutlass.const_expr(
            effective_is_a_mcast or effective_is_b_mcast or use_2cta_instrs
        ):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )
            sfb_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_sfb_vmnk, block_in_cluster_coord_sfb_vmnk, mcast_mode=1
            )

        #
        # Local_tile partition global tensors
        #
        # (bM, bK, RestM, RestK, RestL)
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )

        # (bN, bK, RestN, RestK, RestL)
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.mma_tiler, (0, None, None)), (None, None, None)
        )
        # (bN, bK, RestN, RestK, RestL)
        gSFB_nkl = cute.local_tile(
            mSFB_nkl,
            cute.slice_(self.mma_tiler_sfb, (0, None, None)),
            (None, None, None),
        )
        # (bM, bN, RestM, RestN, RestL)
        gD_mnl = cute.local_tile(
            mD_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        # (bM, bN, RestM, RestN, RestL) - same MNL tiling as gD; the K-axis (N
        # of MMA) carries a stride-0 broadcast over self.sfd_vec_size groups.
        if cutlass.const_expr(self.gen_sfd):
            gSFD_mnl = cute.local_tile(
                mSFD_mnl,
                cute.slice_(self.mma_tiler, (None, None, 0)),
                (None, None, None),
            )
        else:
            gSFD_mnl = None
        # (bM, bN, RestM, RestN, RestL) - residual shares D's MNL tiling; it is a
        # full per-element tensor (no broadcast) loaded via TMA, so it is tiled
        # exactly like gD.
        if cutlass.const_expr(mC_mnl is not None):
            gC_mnl = cute.local_tile(
                mC_mnl,
                cute.slice_(self.mma_tiler, (None, None, 0)),
                (None, None, None),
            )
        else:
            gC_mnl = None

        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        #
        # Partition global tensor for TiledMMA_A/B/C
        #
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        thr_mma_sfb = tiled_mma_sfb.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_K, RestM, RestK, RestL)
        tCgA = thr_mma.partition_A(gA_mkl)
        # (MMA, MMA_N, MMA_K, RestN, RestK, RestL)
        tCgB = thr_mma.partition_B(gB_nkl)
        # (MMA, MMA_N, MMA_K, RestN, RestK, RestL)
        tCgSFB = thr_mma_sfb.partition_B(gSFB_nkl)
        # (MMA, MMA_M, MMA_N, RestM, RestN, RestL)
        tCgD = thr_mma.partition_C(gD_mnl)
        # SFD: same partition shape as gD; broadcast strides preserved through
        # partition.
        if cutlass.const_expr(self.gen_sfd):
            tCgSFD = thr_mma.partition_C(gSFD_mnl)
        else:
            tCgSFD = None
        # Residual: same partition_C chain as the accumulator/D, so the residual
        # TMA load walks the output tile exactly like the D store.
        if cutlass.const_expr(mC_mnl is not None):
            tCgC = thr_mma.partition_C(gC_mnl)
        else:
            tCgC = None

        #
        # Partition global/shared tensor for TMA load B/SFB
        #
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestM, RestK, RestL)
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA, 0, 3),
            cute.group_modes(tCgA, 0, 3),
        )
        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestN, RestK, RestL)
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB, 0, 3),
            cute.group_modes(tCgB, 0, 3),
        )

        # TMA load SFB partition_S/D
        sfb_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_sfb_vmnk, (0, None, 0, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestN, RestK, RestL)
        tBsSFB, tBgSFB = cute.nvgpu.cpasync.tma_partition(
            tma_atom_sfb,
            block_in_cluster_coord_sfb_vmnk[1],
            sfb_cta_layout,
            cute.group_modes(sSFB, 0, 3),
            cute.group_modes(tCgSFB, 0, 3),
        )
        tBsSFB = cute.filter_zeros(tBsSFB)
        tBgSFB = cute.filter_zeros(tBgSFB)

        #
        # Partition shared/tensor memory tensor for TiledMMA_A/B/C
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        tCrA = tiled_mma.make_fragment_A(sA)
        # (MMA, MMA_N, MMA_K, STAGE)
        tCrB = tiled_mma.make_fragment_B(sB)
        # (MMA, MMA_M, MMA_N, STAGE)
        # For overlapping-accum this carries the strided 2-buffer layout so the
        # accumulator's second stage aliases the SFA/SFB columns.
        tCtAcc_fake = self._make_acc_fake_tensor(tiled_mma, self.mma_tiler)

        #
        # Cluster wait before tensor memory alloc
        #
        pipeline_init_wait(cluster_shape_mn=cluster_shape)

        #
        # Specialized TMA load A/B/SFA/SFB warp
        #
        if warp_idx == self.tma_warp_id:
            #
            # Persistent tile scheduling loop
            #
            tile_sched = ClcDynamicPersistentTileScheduler.create(
                tile_sched_params,
                cute.arch.block_idx(),
                cute.arch.grid_dim(),
                clc_response_ptr,
            )
            work_tile = tile_sched.initial_work_tile_info()

            ab_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_ab_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                #
                # Slice to per mma tile index
                #
                # ((atom_v, rest_v), RestK)
                tAgA_slice = tAgA[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]
                # ((atom_v, rest_v), RestK)
                tBgB_slice = tBgB[
                    (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                ]

                # Special-case for N=64: SFB scale-factor slicing to match Tensor Memory
                # packing
                slice_n = mma_tile_coord_mnl[1]
                if cutlass.const_expr(self.cta_tile_shape_mnk[1] == 64):
                    slice_n = mma_tile_coord_mnl[1] // 2
                # ((atom_v, rest_v), RestK)
                tBgSFB_slice = tBgSFB[(None, slice_n, None, mma_tile_coord_mnl[2])]

                # Peek (try_wait) shared AB/SFB buffer empty
                ab_producer_state.reset_count()
                peek_ab_empty_status = ab_sfa_pipeline.producer_try_acquire(
                    ab_producer_state
                )

                # TMA load loop with increment_coord for the im2col K
                # traversal, in S innermost -> R -> T -> C outermost order.
                # A's RestK shape is (C_tiles, S, R, T) with C_tiles leftmost,
                # so the traversal shape is permuted and coords are remapped
                # when indexing.
                k_shape = cute.shape(tAgA_slice, mode=1)  # (C_tiles, S, R, T)
                k_C_tiles = cute.size(k_shape, mode=0)
                k_S = cute.size(k_shape, mode=1)
                k_R = cute.size(k_shape, mode=2)
                k_T = cute.size(k_shape, mode=3)
                # SFB boxes per filter position: one box is a whole SF K tile, so a
                # position holds that many fewer boxes than A/B tiles. Rounding up
                # matches the span the host padded SFB to.
                sfb_C_tiles = cute.ceil_div(k_C_tiles, self.ab_k_tiles_per_sf_k_tile)
                # Traversal shape in S->R->T->C order (colexicographic on this)
                trav_shape = (k_S, k_R, k_T, k_C_tiles)
                trav_coord = cute.repeat_like(0, trav_shape)

                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # TMA producer path on the merged pipeline (leader does
                    # arrive_and_expect_tx, peer does nothing).
                    ab_sfa_pipeline.producer_acquire_tma(
                        ab_producer_state, peek_ab_empty_status
                    )

                    # Remap (s,r,t,c) -> (c,s,r,t) to match A/B RestK layout
                    ab_coord = (
                        trav_coord[3],  # C_tiles
                        trav_coord[0],  # S
                        trav_coord[1],  # R
                        trav_coord[2],  # T
                    )

                    # TMA load A (use multi-dim coord for im2col K indexing)
                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, ab_coord)],
                        tAsA[(None, ab_producer_state.index)],
                        tma_bar_ptr=ab_sfa_pipeline.producer_get_barrier(
                            ab_producer_state
                        ),
                        mcast_mask=a_full_mcast_mask,
                    )
                    # TMA load B (multi-dim K layout, use same coord)
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, ab_coord)],
                        tBsB[(None, ab_producer_state.index)],
                        tma_bar_ptr=ab_sfa_pipeline.producer_get_barrier(
                            ab_producer_state
                        ),
                        mcast_mask=b_full_mcast_mask,
                    )
                    # TMA load SFB: compute flat K tile index from (c,s,r,t)
                    # SFB uses flat layout with C->S->R->T physical order. The
                    # channel coordinate is on the SF cadence, so the A/B tiles
                    # sharing one chunk name the same box and each stages it whole.
                    sfb_flat_k = (
                        ab_coord[0] // self.ab_k_tiles_per_sf_k_tile
                        + ab_coord[1] * sfb_C_tiles
                        + ab_coord[2] * k_S * sfb_C_tiles
                        + ab_coord[3] * k_R * k_S * sfb_C_tiles
                    )
                    cute.copy(
                        tma_atom_sfb,
                        tBgSFB_slice[(None, sfb_flat_k)],
                        tBsSFB[(None, ab_producer_state.index)],
                        tma_bar_ptr=ab_sfa_pipeline.producer_get_barrier(
                            ab_producer_state
                        ),
                        mcast_mask=sfb_full_mcast_mask,
                    )

                    # Peek (try_wait) shared AB/SFB buffer empty for next iteration
                    ab_producer_state.advance()
                    peek_ab_empty_status = cutlass.Boolean(1)
                    if ab_producer_state.count < k_tile_cnt:
                        peek_ab_empty_status = ab_sfa_pipeline.producer_try_acquire(
                            ab_producer_state
                        )

                    # Advance traversal coord in S->R->T->C order
                    trav_coord = cute.increment_coord(trav_coord, trav_shape)

                #
                # Advance to next tile (CLC consumer)
                #
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()

            #
            # Wait shared AB/SFB buffer empty
            #
            ab_sfa_pipeline.producer_tail(ab_producer_state)

        #
        # Specialized cp.async SFA warp
        #
        if (
            warp_idx >= self.cpasync_sfa_warp_id[0]
            and warp_idx <= self.cpasync_sfa_warp_id[-1]
        ):
            #
            # Setup SFA CPASYNC copy atom
            #
            sfa_atom_copy = cute.make_copy_atom(
                cute.nvgpu.cpasync.CopyG2SOp(),
                mSFA_mkl.element_type,
                num_bits_per_copy=32,
            )
            tidx_in_warpgroup = tidx % 128

            # SFA predicate: dynamically computed per cp.async for conv3x3
            sfa_predicate_tensor = cute.make_rmem_tensor(
                cute.make_layout((1,)),
                cutlass.Boolean,
            )

            # Identity M offset (no permutation) + CTA offset within cluster
            cta_m_offset = mma_tile_coord_v * self.cta_tile_shape_mnk[0]
            sfa_m_offset = (
                cta_m_offset
                + 8 * (tidx_in_warpgroup // 32)
                + 32 * ((tidx_in_warpgroup % 32) // 8)
                + (tidx_in_warpgroup % 8)
            )

            # Slice sSFA for this thread's M-row and sub-row
            tAsSFA = sSFA[
                (
                    (
                        (
                            (
                                8 * (tidx_in_warpgroup // 32) + (tidx_in_warpgroup % 8),
                                (tidx_in_warpgroup % 32) // 8,
                            ),
                            None,
                        ),
                        None,
                    ),
                    None,
                    None,
                    None,
                )
            ]

            # SFA global tensor: shape (MN, SF_K, L) with K contiguous
            # For conv3x3 with arbitrary C, each cp.async may load from a different
            # input element (different M address) depending on the filter position.
            # When C < K_gemm_tile, a single K tile spans multiple filter positions.

            # Precompute conv spatial constants
            K_gemm_tile = self.mma_tiler[2][0]
            ZPQ = output_Z * output_P * output_Q
            PQ = output_P * output_Q
            DHW = input_D * input_H * input_W
            HW = input_H * input_W
            CTA_M = self.cta_tile_shape_mnk[0]
            # SF blocks one SF K tile holds. The SF tile widens to a whole atom
            # when the A/B K tile is narrower, and every A/B tile sharing it stages
            # the whole thing.
            sf_k_per_ktile = self.sf_tile_k // self.sf_vec_size
            # C tiles per filter position, rounded up: a partial trailing tile
            # consumes a k_tile, and its tail reads zero-filled A and B from the TMA.
            c_tiles_per_fpos = (input_C + K_gemm_tile - 1) // K_gemm_tile
            # SF blocks a pixel's row holds. The host rounds it up to a whole 4-block
            # atom and zero-fills the tail, so a group on the last one is in bounds.
            sfa_sf_k_extent = mSFA_mkl.shape[1]
            sfa_last_group = sfa_sf_k_extent - 4
            # Per-carry address deltas for the linear im2col walk: the unclamped
            # gmem M address decomposes as m_base + t*rt_dil_d*HW + r*rt_dil_h*W +
            # s*rt_dil_w, so each carry level advances one running delta by a
            # precomputed step. Steps carry the SFA row stride, so the loop
            # adds element offsets directly.
            sfa_step_s = rt_dil_w * sfa_sf_k_extent
            sfa_step_r = (rt_dil_h * input_W - rt_filter_s * rt_dil_w) * sfa_sf_k_extent
            sfa_step_t = (
                rt_dil_d * HW - rt_filter_r * rt_dil_h * input_W
            ) * sfa_sf_k_extent

            #
            # Persistent tile scheduling loop
            #
            tile_sched = ClcDynamicPersistentTileScheduler.create(
                tile_sched_params,
                cute.arch.block_idx(),
                cute.arch.grid_dim(),
                clc_response_ptr,
            )
            work_tile = tile_sched.initial_work_tile_info()

            sfa_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_ab_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # Compute this thread's global M index (output pixel)
                # Use mma_tile_coord_mnl[0] (M tile index without V) * full MMA tile M
                # because sfa_m_offset already includes the V (CTA-within-pair) offset
                cta_m_tile_offset = (
                    mma_tile_coord_mnl[0] * CTA_M * cute.size(tiled_mma.thr_id.shape)
                )
                m_global = cta_m_tile_offset + sfa_m_offset

                # Decompose m_global -> (n, z, p, q) output coordinates
                n_idx = m_global // ZPQ
                zpq_rem = m_global % ZPQ
                z_idx = zpq_rem // PQ
                pq_rem = zpq_rem % PQ
                p_idx = pq_rem // output_Q
                q_idx = pq_rem % output_Q

                # Check if m_global is within valid output range
                m_valid = m_global < (input_N * ZPQ)

                # Initialize base spatial coordinates for filter pos (t=0, r=0, s=0)
                d_in_base = z_idx * rt_stride_d - rt_lower_pad_d
                h_in_base = p_idx * rt_stride_h - rt_lower_pad_h
                w_in_base = q_idx * rt_stride_w - rt_lower_pad_w
                n_clamped = n_idx if m_valid else 0

                # Maintain (s,r,t,c) coords for the S->R->T->C order the A/B K tiles
                # are loaded in
                sfa_s_idx = 0
                sfa_r_idx = 0
                sfa_t_idx = 0
                sfa_c_tile_idx = 0
                sfa_m_base = (
                    n_clamped * DHW + d_in_base * HW + h_in_base * input_W + w_in_base
                ) * sfa_sf_k_extent
                sfa_delta = cutlass.Int32(0)
                # Running unclamped coords for the predicate, advanced with the
                # same carry chain as the delta.
                sfa_d_in = d_in_base + 0
                sfa_h_in = h_in_base + 0
                sfa_w_in = w_in_base + 0

                # Peek (try_wait) SFA buffer empty
                sfa_producer_state.reset_count()
                peek_sfa_empty_status = cutlass.Boolean(1)
                if sfa_producer_state.count < k_tile_cnt:
                    peek_sfa_empty_status = ab_sfa_pipeline.producer_try_acquire(
                        sfa_producer_state
                    )

                # Shift-by-K cross-CTA commit ringbuffer (K=2). Each iter
                # commits the prior copies as a cp.async group and waits
                # wait_group(K), then remote-arrives on the leader's sfa_full
                # for the stage from K iters ago, so cp.async has landed
                # globally before the leader's MMA sees the barrier full.
                sfa_shift_K = 2
                pending_a = cutlass.Int32(0)
                pending_b = cutlass.Int32(0)

                #
                # CPASYNC SFA load loop with coordinate-based im2col
                # Traversal order: S->R->T->C, the A/B K-tile order
                #
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # Conditionally wait for SFA buffer empty
                    ab_sfa_pipeline.producer_acquire(
                        sfa_producer_state, peek_sfa_empty_status
                    )

                    cur_stage = sfa_producer_state.index

                    tAsSFA_ktile = tAsSFA[(None, None, None, None, cur_stage)]

                    # Predicate: m_valid AND spatial bounds check
                    sfa_pred_val = cutlass.Boolean(0)
                    if m_valid:
                        if sfa_d_in >= 0 and sfa_d_in < input_D:
                            if sfa_h_in >= 0 and sfa_h_in < input_H:
                                if sfa_w_in >= 0 and sfa_w_in < input_W:
                                    sfa_pred_val = cutlass.Boolean(1)

                    # A predicated-off row reads address 0, always in bounds;
                    # its predicate suppresses the actual copy.
                    sfa_row_off = (sfa_m_base + sfa_delta) if sfa_pred_val else 0

                    # SF K base offset for current C tile within this fpos. A/B
                    # tiles sharing one SF tile take the same base: they sit in one
                    # filter position, so one transfer covers them all.
                    sf_k_base = (
                        sfa_c_tile_idx // self.ab_k_tiles_per_sf_k_tile
                    ) * sf_k_per_ktile

                    self.sfa_cpasync_copy_tile_precomputed(
                        mSFA_mkl,
                        tAsSFA_ktile,
                        sfa_atom_copy,
                        sfa_predicate_tensor,
                        sfa_row_off,
                        sfa_pred_val,
                        sf_k_base,
                        sf_k_per_ktile,
                        sfa_last_group,
                        tidx_in_warpgroup,
                    )

                    # Increment in S->R->T->C order (S innermost, C outermost)
                    sfa_s_idx = sfa_s_idx + 1
                    sfa_delta = sfa_delta + sfa_step_s
                    sfa_w_in = sfa_w_in + rt_dil_w
                    if sfa_s_idx >= rt_filter_s:
                        sfa_s_idx = 0
                        sfa_w_in = w_in_base + 0
                        sfa_r_idx = sfa_r_idx + 1
                        sfa_delta = sfa_delta + sfa_step_r
                        sfa_h_in = sfa_h_in + rt_dil_h
                        if sfa_r_idx >= rt_filter_r:
                            sfa_r_idx = 0
                            sfa_h_in = h_in_base + 0
                            sfa_t_idx = sfa_t_idx + 1
                            sfa_delta = sfa_delta + sfa_step_t
                            sfa_d_in = sfa_d_in + rt_dil_d
                            if sfa_t_idx >= rt_filter_t:
                                sfa_t_idx = 0
                                sfa_d_in = d_in_base + 0
                                sfa_delta = 0
                                sfa_c_tile_idx = sfa_c_tile_idx + 1
                                if sfa_c_tile_idx >= c_tiles_per_fpos:
                                    sfa_c_tile_idx = 0

                    # Commit this iter's copies as one cp.async group and
                    # gate on <=K inflight. After wait_group(K), the cp.async
                    # for the stage from K iters ago is guaranteed complete
                    # on every CTA in the cluster.
                    ab_sfa_pipeline.producer_cp_async_commit()
                    ab_sfa_pipeline.producer_cp_async_wait(sfa_shift_K)

                    # Shift-by-K: arrive on stage from K iters ago.
                    if k_tile >= sfa_shift_K:
                        ab_sfa_pipeline.producer_arrive_remote(pending_a)

                    # Advance ringbuffer (oldest <- 2nd oldest <- current).
                    pending_a = pending_b
                    pending_b = cur_stage

                    # Peek (try_wait) SFA buffer empty for next iteration
                    sfa_producer_state.advance()
                    peek_sfa_empty_status = cutlass.Boolean(1)
                    if sfa_producer_state.count < k_tile_cnt:
                        peek_sfa_empty_status = ab_sfa_pipeline.producer_try_acquire(
                            sfa_producer_state
                        )

                #
                # Shift-by-K tail: drain all inflight cp.async, then arrive on
                # the K stages whose arrives were deferred.
                #
                ab_sfa_pipeline.producer_cp_async_wait(0)
                if k_tile_cnt >= sfa_shift_K:
                    ab_sfa_pipeline.producer_arrive_remote(pending_a)
                if k_tile_cnt >= 1:
                    ab_sfa_pipeline.producer_arrive_remote(pending_b)

                #
                # Advance to next tile (CLC consumer)
                #
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()

            #
            # Wait SFA buffer empty
            #
            ab_sfa_pipeline.producer_tail(sfa_producer_state)

        # Specialized residual G2S warp (only spawned when beta != 0). The residual
        # load owns a dedicated warp, so the producer and the consumer of the
        # residual barrier sit in different warps. It runs its own persistent
        # tile-scheduler loop and consumes one CLC response per tile, under the same
        # const gate as the CLC count.
        if warp_idx == self.residual_warp_id:
            if cutlass.const_expr(mC_mnl is not None):
                tile_sched = ClcDynamicPersistentTileScheduler.create(
                    tile_sched_params,
                    cute.arch.block_idx(),
                    cute.arch.grid_dim(),
                    clc_response_ptr,
                )
                work_tile = tile_sched.initial_work_tile_info()

                # The gmem/smem TMA partition is thread-invariant, so recompute
                # the exact handles the epilogue consumer expects.
                (
                    tma_atom_c,
                    bGS_sC,
                    bGS_gC_partitioned,
                ) = self.epilog_gmem_copy_and_partition(
                    tidx, tma_atom_c, tCgC, epi_tile, sC
                )
                c_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.num_d_stage
                )
                # Overlapping-accum walks output subtiles back-to-front on the
                # phase-0 tile; track the epilogue's acc-consumer phase with a
                # shadow state so the producer stages subtiles in the order the
                # consumer reads them.
                if cutlass.const_expr(self.overlapping_accum):
                    c_acc_shadow_state = pipeline.make_pipeline_state(
                        pipeline.PipelineUserType.Consumer, self.num_acc_stage
                    )

                while work_tile.is_valid_tile:
                    cur_tile_coord = work_tile.tile_idx
                    mma_tile_coord_mnl = (
                        cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                        cur_tile_coord[1],
                        cur_tile_coord[2],
                    )

                    # Issue this output tile's residual TMA loads (gmem ->
                    # smem), one per output N-subtile, walking subtiles in
                    # lockstep with the epilogue consumer. Whole-warp producer
                    # arrive (no elect_one): PipelineTmaAsync's single-thread
                    # producer group self-elects the signaling lane.
                    bGS_gC = bGS_gC_partitioned[
                        (
                            None,
                            None,
                            None,
                            *mma_tile_coord_mnl,
                        )
                    ]
                    bGS_gC = cute.group_modes(bGS_gC, 1, cute.rank(bGS_gC))
                    subtile_cnt = cute.size(bGS_gC.shape, mode=[1])
                    if cutlass.const_expr(self.overlapping_accum):
                        reverse_subtile = c_acc_shadow_state.phase == 0
                    for subtile_idx in cutlass.range(subtile_cnt):
                        real_subtile_idx = subtile_idx
                        if cutlass.const_expr(self.overlapping_accum):
                            if reverse_subtile:
                                real_subtile_idx = (
                                    self.cta_tile_shape_mnk[1] // self.epi_tile_n
                                    - 1
                                    - subtile_idx
                                )
                        # The ring slot comes from the pipeline state, the same
                        # place the barrier below and the epilogue consumer take
                        # theirs, so the ring holds at any stage count.
                        c_pipeline.producer_acquire(c_producer_state)
                        cute.copy(
                            tma_atom_c,
                            bGS_gC[(None, real_subtile_idx)],
                            bGS_sC[(None, c_producer_state.index)],
                            tma_bar_ptr=c_pipeline.producer_get_barrier(
                                c_producer_state
                            ),
                        )
                        c_producer_state.advance()
                    if cutlass.const_expr(self.overlapping_accum):
                        c_acc_shadow_state.advance()

                    #
                    # Advance to next tile (CLC consumer)
                    #
                    clc_pipeline.consumer_wait(clc_consumer_state)
                    work_tile = tile_sched.get_current_work()
                    clc_pipeline.consumer_release(clc_consumer_state)
                    clc_consumer_state.advance()

                #
                # Drain the residual TMA load pipeline before exiting.
                #
                c_pipeline.producer_tail(c_producer_state)

        #
        # Specialized scheduler warp (drives CLC fetch, only first CTA in cluster)
        #
        if warp_idx == self.sched_warp_id and is_first_cta_in_cluster:
            clc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.ProducerConsumer, self.num_clc_stage
            )

            tile_sched = ClcDynamicPersistentTileScheduler.create(
                tile_sched_params,
                cute.arch.block_idx(),
                cute.arch.grid_dim(),
                clc_response_ptr,
            )
            work_tile = tile_sched.initial_work_tile_info()
            while work_tile.is_valid_tile:
                clc_pipeline.producer_acquire(clc_producer_state)
                mbarrier_addr = clc_pipeline.producer_get_barrier(clc_producer_state)
                tile_sched.advance_to_next_work(mbarrier_addr)
                clc_producer_state.advance()

                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
            clc_pipeline.producer_tail(clc_producer_state)

        #
        # Specialized MMA warp
        #
        if warp_idx == self.mma_warp_id:
            #
            # Bar sync for retrieve tensor memory ptr from shared mem
            #
            tmem.wait_for_alloc()

            #
            # Retrieving tensor memory ptr and make accumulator/SFA/SFB tensor
            #
            acc_tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # Make accumulator tmem tensor
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            # Make SFA tmem tensor
            sfa_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr + tcgen05.find_tmem_tensor_col_offset(tCtAcc_base),
                dtype=self.sf_dtype,
            )
            # (MMA, MMA_M, MMA_K)
            tCtSFA_layout = blockscaled_utils.make_tmem_layout_sfa(
                tiled_mma,
                self.flat_mma_tiler_sf,
                self.sf_vec_size,
                cute.slice_(sfa_smem_layout_staged, (None, None, None, 0)),
            )
            tCtSFA = cute.make_tensor(sfa_tmem_ptr, tCtSFA_layout)

            # Make SFB tmem tensor
            sfb_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr
                + tcgen05.find_tmem_tensor_col_offset(tCtAcc_base)
                + tcgen05.find_tmem_tensor_col_offset(tCtSFA),
                dtype=self.sf_dtype,
            )
            # (MMA, MMA_N, MMA_K)
            tCtSFB_layout = blockscaled_utils.make_tmem_layout_sfb(
                tiled_mma,
                self.flat_mma_tiler_sf,
                self.sf_vec_size,
                cute.slice_(sfb_smem_layout_staged, (None, None, None, 0)),
            )
            tCtSFB = cute.make_tensor(sfb_tmem_ptr, tCtSFB_layout)
            #
            # Partition for S2T copy of SFA/SFB
            #
            (
                tiled_copy_s2t_sfa,
                tCsSFA_compact_s2t,
                tCtSFA_compact_s2t,
            ) = self.mainloop_s2t_copy_and_partition(sSFA, tCtSFA)
            (
                tiled_copy_s2t_sfb,
                tCsSFB_compact_s2t,
                tCtSFB_compact_s2t,
            ) = self.mainloop_s2t_copy_and_partition(sSFB, tCtSFB)

            #
            # Persistent tile scheduling loop
            #
            tile_sched = ClcDynamicPersistentTileScheduler.create(
                tile_sched_params,
                cute.arch.block_idx(),
                cute.arch.grid_dim(),
                clc_response_ptr,
            )
            work_tile = tile_sched.initial_work_tile_info()

            ab_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_ab_stage
            )
            sfa_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_ab_stage
            )
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )

            # Filter positions one channel tile sweeps. The K loop walks S->R->T->C
            # with C outermost, so the chunk part below has to come from the channel
            # tile: the running k_tile count keeps advancing across positions.
            if cutlass.const_expr(self.ab_k_tiles_per_sf_k_tile > 1):
                sf_fpos_per_c_tile = rt_filter_t * rt_filter_r * rt_filter_s

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # Channel tile and its filter-position counter, reset per work tile.
                if cutlass.const_expr(self.ab_k_tiles_per_sf_k_tile > 1):
                    sf_c_tile_idx = cutlass.Int32(0)
                    sf_fpos_idx = cutlass.Int32(0)

                # Set tensor memory buffer for current tile (MMA, MMA_M, MMA_N).
                # Overlapping-accum squeezes two acc buffers into 512-col TMEM by
                # aliasing the second onto the SFA/SFB columns, so the producer
                # writes the buffer the consumer is not draining: phase ^ 1
                # (producer phase inits to 1, consumer to 0, so tile 0 picks stage 0).
                if cutlass.const_expr(self.overlapping_accum):
                    acc_stage_index = acc_producer_state.phase ^ 1
                else:
                    acc_stage_index = acc_producer_state.index
                tCtAcc = tCtAcc_base[(None, None, None, acc_stage_index)]

                # Peek (try_wait) shared AB/SFB + SFA buffer full for k_tile = 0
                ab_consumer_state.reset_count()
                sfa_consumer_state.reset_count()
                peek_ab_full_status = cutlass.Boolean(1)
                if ab_consumer_state.count < k_tile_cnt and is_leader_cta:
                    peek_ab_full_status = ab_sfa_pipeline.consumer_try_wait(
                        ab_consumer_state
                    )
                # Merged pipeline: sfa shares ab mbarrier, no separate try_wait needed.

                #
                # Wait for accumulator buffer empty
                #
                if is_leader_cta:
                    acd_pipeline.producer_acquire(acc_producer_state)

                # Special-case for N=192/N=64: shift the SFB Tensor Memory pointer to
                # match its packing
                tCtSFB_mma = tCtSFB
                if cutlass.const_expr(self.cta_tile_shape_mnk[1] == 192):
                    # If this is an ODD tile, shift the Tensor Memory start address for
                    # cta_tile_shape_n=192 case by two words (ignores first 64 columns
                    # of SFB)
                    offset = (
                        cutlass.Int32(2)
                        if mma_tile_coord_mnl[1] % 2 == 1
                        else cutlass.Int32(0)
                    )
                    shifted_ptr = cute.recast_ptr(
                        acc_tmem_ptr
                        + tcgen05.find_tmem_tensor_col_offset(tCtAcc_base)
                        + tcgen05.find_tmem_tensor_col_offset(tCtSFA)
                        + offset,
                        dtype=self.sf_dtype,
                    )
                    tCtSFB_mma = cute.make_tensor(shifted_ptr, tCtSFB_layout)
                elif cutlass.const_expr(self.cta_tile_shape_mnk[1] == 64):
                    # Move in increments of 64 columns of SFB
                    offset = cutlass.Int32((mma_tile_coord_mnl[1] % 2) * 2)
                    shifted_ptr = cute.recast_ptr(
                        acc_tmem_ptr
                        + tcgen05.find_tmem_tensor_col_offset(tCtAcc_base)
                        + tcgen05.find_tmem_tensor_col_offset(tCtSFA)
                        + offset,
                        dtype=self.sf_dtype,
                    )
                    tCtSFB_mma = cute.make_tensor(shifted_ptr, tCtSFB_layout)

                #
                # Reset the ACCUMULATE field for each tile
                #
                tiled_mma.set(tcgen05.Field.ACCUMULATE, False)

                #
                # Mma mainloop
                #
                for k_tile in cutlass.range(k_tile_cnt, unroll=1):
                    if cutlass.const_expr(self.ab_k_tiles_per_sf_k_tile > 1):
                        sf_kblock_base = (
                            sf_c_tile_idx % self.ab_k_tiles_per_sf_k_tile
                        ) * self.mma_inst_tile_k
                    else:
                        sf_kblock_base = 0

                    if is_leader_cta:
                        # Merged pipeline: single consumer_wait covers both TMA and
                        # cp.async producers.
                        ab_sfa_pipeline.consumer_wait(
                            ab_consumer_state, peek_ab_full_status
                        )

                        #  Copy SFA/SFB from smem to tmem
                        sfa_s2t_stage_coord = (
                            None,
                            None,
                            None,
                            None,
                            sfa_consumer_state.index,
                        )
                        sfb_s2t_stage_coord = (
                            None,
                            None,
                            None,
                            None,
                            ab_consumer_state.index,
                        )
                        tCsSFA_compact_s2t_staged = tCsSFA_compact_s2t[
                            sfa_s2t_stage_coord
                        ]
                        tCsSFB_compact_s2t_staged = tCsSFB_compact_s2t[
                            sfb_s2t_stage_coord
                        ]
                        cute.copy(
                            tiled_copy_s2t_sfa,
                            tCsSFA_compact_s2t_staged,
                            tCtSFA_compact_s2t,
                        )
                        cute.copy(
                            tiled_copy_s2t_sfb,
                            tCsSFB_compact_s2t_staged,
                            tCtSFB_compact_s2t,
                        )

                        # Block-scaled MMA: acc += (A * SFA) * (B * SFB)
                        num_kblocks = cute.size(tCrA, mode=[2])
                        for kblock_idx in cutlass.range(num_kblocks, unroll_full=True):
                            kblock_coord = (
                                None,
                                None,
                                kblock_idx,
                                ab_consumer_state.index,
                            )

                            # Set SFA/SFB tensor to tiled_mma. The K blocks this
                            # tile owns start at its own part of the shared chunk
                            # (offset 0 for NVFP4, whose ratio is 1).
                            sf_kblock_coord = (
                                None,
                                None,
                                sf_kblock_base + kblock_idx,
                            )
                            tiled_mma.set(
                                tcgen05.Field.SFA,
                                tCtSFA[sf_kblock_coord].iterator,
                            )
                            tiled_mma.set(
                                tcgen05.Field.SFB,
                                tCtSFB_mma[sf_kblock_coord].iterator,
                            )

                            cute.gemm(
                                tiled_mma,
                                tCtAcc,
                                tCrA[kblock_coord],
                                tCrB[kblock_coord],
                                tCtAcc,
                            )

                            # Enable accumulate on tCtAcc after first kblock
                            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

                        # Merged pipeline: single consumer_release covers both TMA and
                        # cp.async producers.
                        ab_sfa_pipeline.consumer_release(ab_consumer_state)

                    # Advance the channel tile once the whole filter has been
                    # swept: the K loop walks S->R->T->C with C outermost.
                    if cutlass.const_expr(self.ab_k_tiles_per_sf_k_tile > 1):
                        sf_fpos_idx = sf_fpos_idx + 1
                        if sf_fpos_idx >= sf_fpos_per_c_tile:
                            sf_fpos_idx = cutlass.Int32(0)
                            sf_c_tile_idx = sf_c_tile_idx + 1

                    # Peek (try_wait) shared AB/SFB + SFA buffer full for k_tile+1
                    ab_consumer_state.advance()
                    sfa_consumer_state.advance()

                    peek_ab_full_status = cutlass.Boolean(1)
                    if ab_consumer_state.count < k_tile_cnt:
                        if is_leader_cta:
                            peek_ab_full_status = ab_sfa_pipeline.consumer_try_wait(
                                ab_consumer_state
                            )
                    # Merged pipeline: sfa shares ab mbarrier, try_wait above handles
                    # both.

                #
                # Async arrive accumulator buffer full
                #
                if is_leader_cta:
                    acd_pipeline.producer_commit(acc_producer_state)
                acc_producer_state.advance()

                #
                # Advance to next tile (CLC consumer)
                #
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()

            #
            # Wait for accumulator buffer empty
            #
            acd_pipeline.producer_tail(acc_producer_state)

        #
        # Specialized epilogue warps
        #
        if warp_idx <= self.epilogue_warp_id[-1]:
            #
            # Alloc tensor memory buffer
            #
            tmem.allocate(self.num_tmem_alloc_cols)

            #
            # Bar sync for retrieve tensor memory ptr from shared memory
            #
            tmem.wait_for_alloc()

            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            acc_tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            #
            # Partition for epilogue
            #
            epi_tidx = tidx
            (
                tiled_copy_t2r,
                tTR_tAcc_base,
                tTR_rAcc,
            ) = self.epilog_tmem_copy_and_partition(
                epi_tidx, tCtAcc_base, tCgD, epi_tile, use_2cta_instrs
            )

            tTR_rD = cute.make_rmem_tensor(tTR_rAcc.shape, self.d_dtype)
            tiled_copy_r2s, tRS_rD, tRS_sD = self.epilog_smem_store_copy_and_partition(
                tiled_copy_t2r, tTR_rD, epi_tidx, sD
            )
            (
                tma_atom_d,
                bSG_sD,
                bSG_gD_partitioned,
            ) = self.epilog_gmem_copy_and_partition(
                epi_tidx, tma_atom_d, tCgD, epi_tile, sD
            )

            # Residual smem->reg partition, built from the accumulator's T2R
            # tiled copy so each thread's residual register tile lines up with its
            # acc tile. The gmem->smem TMA producer runs on the residual warp; the
            # epilogue only consumes the staged smem tile here.
            if cutlass.const_expr(mC_mnl is not None):
                tTR_rC = cute.make_rmem_tensor(tTR_rAcc.shape, self.d_dtype)
                (
                    tiled_copy_s2r_c,
                    tSR_rC,
                    tSR_sC,
                ) = self.epilog_smem_load_copy_and_partition(
                    tiled_copy_t2r, tTR_rC, epi_tidx, sC
                )
            else:
                tTR_rC = None
                tiled_copy_s2r_c = None
                tSR_rC = None
                tSR_sC = None

            # SFD partition: same epi-tile/T2R structure as gD, but written
            # directly to GMEM via STG (no SMEM/TMA path).
            if cutlass.const_expr(self.gen_sfd):
                thr_copy_t2r = tiled_copy_t2r.get_slice(epi_tidx)
                # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, RestM, RestN, RestL)
                gSFD_epi = cute.flat_divide(
                    tCgSFD[((None, None), 0, 0, None, None, None)], epi_tile
                )
                # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
                tTR_gSFD_partitioned = thr_copy_t2r.partition_D(gSFD_epi)
                # The SFD store is a plain STG whose partition rounds M up to a
                # tile multiple, so the last m-tile has overhang rows with no
                # backing storage. Build an identity-coordinate mirror through the
                # D path (which has no stride-0 broadcast mode), partitioned
                # identically, so the store site can predicate on the real M extent.
                sfd_ceil_m, sfd_ceil_n, _ = cute.ceil_div(
                    mD_mnl.shape, (self.mma_tiler[0], self.mma_tiler[1], 1)
                )
                mcSFD = cute.make_identity_tensor(
                    (
                        cute.size(sfd_ceil_m) * self.mma_tiler[0],
                        cute.size(sfd_ceil_n) * self.mma_tiler[1],
                        1,
                    )
                )
                gcSFD = cute.local_tile(
                    mcSFD,
                    cute.slice_(self.mma_tiler, (None, None, 0)),
                    (None, None, None),
                )
                tCgcSFD = thr_mma.partition_C(gcSFD)
                gcSFD_epi = cute.flat_divide(
                    tCgcSFD[((None, None), 0, 0, None, None, None)], epi_tile
                )
                # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
                tTR_cSFD_partitioned = thr_copy_t2r.partition_D(gcSFD_epi)
            else:
                tTR_gSFD_partitioned = None
                tTR_cSFD_partitioned = None

            # Bias read view: the staged row carries the same epi-tile/T2R
            # structure as the accumulator, so each epilogue thread's bias
            # register fragment lines up with its acc fragment. It is tile
            # invariant, since every tile restages the row in place.
            if cutlass.const_expr(mBias_mnl is not None):
                # (T2R, T2R_M, T2R_N, SUBTILE)
                tTR_sBias = self.epilog_bias_smem_partition(
                    tiled_copy_t2r, epi_tidx, sBias, epi_tile
                )
                # smem-load atom: each thread reads its own N columns back from the
                # CTA-staged sBias row.
                simt_atom_bias = cute.make_copy_atom(
                    cute.nvgpu.CopyUniversalOp(), mBias_mnl.element_type
                )
                # cp.async transfers at least 32 bits, so each lane moves a
                # 32-bit-wide vector of bias elements: one at a 32-bit bias
                # width, two at 16 bits.
                bias_elems_per_copy = 32 // mBias_mnl.element_type.width
                bias_g2s_atom = cute.make_copy_atom(
                    cute.nvgpu.cpasync.CopyG2SOp(),
                    mBias_mnl.element_type,
                    num_bits_per_copy=32,
                )
            else:
                tTR_sBias = None
                simt_atom_bias = None
                bias_g2s_atom = None
                bias_elems_per_copy = None

            #
            # Persistent tile scheduling loop
            #
            tile_sched = ClcDynamicPersistentTileScheduler.create(
                tile_sched_params,
                cute.arch.block_idx(),
                cute.arch.grid_dim(),
                clc_response_ptr,
            )
            work_tile = tile_sched.initial_work_tile_info()

            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )

            # Pipeline Init: Threads/warps participating in tma store pipeline
            d_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.epilogue_warp_id),
            )
            d_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.num_d_stage,
                producer_group=d_producer_group,
            )

            # The residual producer state lives on the dedicated residual warp;
            # the epilogue only tracks the consumer side of the residual load
            # pipeline.
            if cutlass.const_expr(mC_mnl is not None):
                c_consumer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer, self.num_d_stage
                )
            else:
                c_consumer_state = None

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )
                #
                # Slice to per mma tile index
                #
                # ((ATOM_V, REST_V), EPI_M, EPI_N)
                bSG_gD = bSG_gD_partitioned[
                    (
                        None,
                        None,
                        None,
                        *mma_tile_coord_mnl,
                    )
                ]
                if cutlass.const_expr(self.gen_sfd):
                    # (T2R, T2R_M, T2R_N, EPI_M, EPI_N)
                    tTR_gSFD = tTR_gSFD_partitioned[
                        (
                            None,
                            None,
                            None,
                            None,
                            None,
                            *mma_tile_coord_mnl,
                        )
                    ]
                    # Identity-coordinate mirror, sliced identically, for the
                    # STG M-bound predicate at the SFD store site.
                    tTR_cSFD = tTR_cSFD_partitioned[
                        (
                            None,
                            None,
                            None,
                            None,
                            None,
                            *mma_tile_coord_mnl,
                        )
                    ]
                if cutlass.const_expr(mBias_mnl is not None):
                    # The CTA cp.async's this tile's contiguous cta_tile_n bias
                    # values (K stride 1) into sBias, then syncs so every
                    # epilogue thread can load its columns back from smem. One value per
                    # output channel is fetched once and broadcast to all M rows.
                    cta_n = self.cta_tile_shape_mnk[1]
                    n_base = mma_tile_coord_mnl[1] * cta_n
                    # Each lane cp.async's a contiguous 32-bit vector
                    # (bias_elems_per_copy elements) of this tile's bias row.
                    # Layout (elems, lanes) with column-major stride so lane t
                    # owns the block [t*elems : (t+1)*elems); the K axis of
                    # mBias_mnl has stride 1, so the segment is contiguous.
                    n_active = cta_n // bias_elems_per_copy
                    row_layout = cute.make_layout(
                        (bias_elems_per_copy, n_active),
                        stride=(1, bias_elems_per_copy),
                    )
                    # cp.async needs 32-bit source/dest alignment; the tile
                    # base (n_base is a multiple of cta_tile_n) keeps both on a
                    # 4-byte boundary, so re-annotate the pointers to satisfy
                    # the 32-bit atom.
                    gBias_row = cute.make_tensor(
                        (mBias_mnl.iterator + n_base).align(min_align=4),
                        row_layout,
                    )
                    sBias_tiled = cute.make_tensor(
                        sBias.iterator.align(min_align=4), row_layout
                    )
                    # Predicated cp.async: a CTA N-tile rounds up to cta_tile_n, but
                    # K need not divide it, so tail lanes address bias columns with no
                    # backing storage. Guard each lane's vector on its base channel;
                    # cp.async zero-fills on a false predicate. K % 8 == 0 makes every
                    # vector wholly in- or out-of-bounds, so one predicate is exact.
                    if epi_tidx < n_active:
                        bias_pred = cute.make_rmem_tensor(
                            cute.make_layout((1,)), cutlass.Boolean
                        )
                        bias_pred[0] = cutlass.Boolean(
                            n_base + epi_tidx * bias_elems_per_copy < mD_mnl.shape[1]
                        )
                        cute.copy_atom_call(
                            bias_g2s_atom,
                            gBias_row[(None, epi_tidx)],
                            sBias_tiled[(None, epi_tidx)],
                            pred=bias_pred,
                        )
                    cute.arch.cp_async_commit_group()
                    cute.arch.cp_async_wait_group(0)
                    self.epilog_sync_barrier.arrive_and_wait()

                # Set tensor memory buffer for current tile
                # (T2R, T2R_M, T2R_N, EPI_M, EPI_M). Overlapping-accum: the consumer
                # reads the buffer its phase (0/1) indexes. Stage-1 acc is strided so
                # its high subtiles alias the SFA/SFB columns; to drain those first the
                # epilogue walks subtiles in REVERSE when phase == 0.
                if cutlass.const_expr(self.overlapping_accum):
                    acc_stage_index = acc_consumer_state.phase
                    reverse_subtile = acc_stage_index == 0
                else:
                    acc_stage_index = acc_consumer_state.index
                tTR_tAcc = tTR_tAcc_base[
                    (None, None, None, None, None, acc_stage_index)
                ]

                #
                # Wait for accumulator buffer full
                #
                acd_pipeline.consumer_wait(acc_consumer_state)

                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                bSG_gD = cute.group_modes(bSG_gD, 1, cute.rank(bSG_gD))
                if cutlass.const_expr(self.gen_sfd):
                    # ((T2R, T2R_M, T2R_N), SUBTILE_CNT)
                    tTR_gSFD = cute.group_modes(tTR_gSFD, 3, cute.rank(tTR_gSFD))
                    tTR_cSFD = cute.group_modes(tTR_cSFD, 3, cute.rank(tTR_cSFD))

                #
                # Store accumulator to global memory in subtiles
                #
                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                num_prev_subtiles = tile_sched.num_tiles_executed * subtile_cnt
                for subtile_idx in cutlass.range(subtile_cnt):
                    # Map the loop counter to the true output N-subtile. Under
                    # reverse_subtile the output subtiles are walked back-to-front
                    # so the SFA/SFB-aliased columns drain before the next tile's
                    # MMA reuses them. real_subtile_idx addresses every actual
                    # output position; subtile_idx stays a sequential counter.
                    real_subtile_idx = subtile_idx
                    if cutlass.const_expr(self.overlapping_accum):
                        if reverse_subtile:
                            real_subtile_idx = (
                                self.cta_tile_shape_mnk[1] // self.epi_tile_n
                                - 1
                                - subtile_idx
                            )
                    #
                    # Load accumulator from tensor memory buffer to register
                    #
                    tTR_tAcc_mn = tTR_tAcc[(None, None, None, real_subtile_idx)]
                    cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)

                    # Async arrive accumulator buffer empty earlier when
                    # overlapping_accum is enabled. Trigger keyed on the raw loop
                    # counter so it fires exactly once after the shared columns
                    # (drained first under reverse) have been read out.
                    if cutlass.const_expr(self.overlapping_accum):
                        if subtile_idx == self.iter_acc_early_release_in_epilogue:
                            cute.arch.fence_view_async_tmem_load()
                            with cute.arch.elect_one():
                                acd_pipeline.consumer_release(acc_consumer_state)
                            acc_consumer_state.advance()

                    # Apply per-tensor alpha.
                    tTR_rAcc.store(tTR_rAcc.load() * alpha)

                    # Add per-output-channel bias in FP32 (D = alpha*acc + bias).
                    # Load this subtile's bias from the CTA-staged sBias row into a
                    # register fragment shaped like the acc fragment, then add.
                    # The M-axis stride-0 broadcast means each thread reads only
                    # its own N-column bias.
                    if cutlass.const_expr(mBias_mnl is not None):
                        tTR_rBias = cute.make_rmem_tensor(
                            tTR_rAcc.shape, mBias_mnl.element_type
                        )
                        cute.copy(
                            simt_atom_bias,
                            tTR_sBias[(None, None, None, real_subtile_idx)],
                            tTR_rBias,
                        )
                        tTR_rAcc.store(
                            tTR_rAcc.load() + tTR_rBias.load().to(cutlass.Float32)
                        )

                    # Add the per-element residual in FP32 (D = alpha*acc + bias
                    # + beta*residual). Wait for this subtile's TMA load to land,
                    # copy it to registers aligned with the acc fragment, then
                    # accumulate. The residual shares the output dtype and widens
                    # to FP32; beta is a compile-time constant folded into the add.
                    if cutlass.const_expr(mC_mnl is not None):
                        c_pipeline.consumer_wait(c_consumer_state)
                        cute.copy(
                            tiled_copy_s2r_c,
                            tSR_sC[(None, None, None, c_consumer_state.index)],
                            tSR_rC,
                        )
                        cute.arch.fence_proxy(
                            "async.shared",
                            space="cta",
                        )
                        # consumer_release self-elects its signaling threads
                        # (is_signaling_thread by tidx); all epilogue threads
                        # call it directly, no explicit elect_one.
                        c_pipeline.consumer_release(c_consumer_state)
                        c_consumer_state.advance()
                        # tSR_rC is the S2R-partition view of tTR_rC
                        # (shared storage); read back through the acc-shaped view
                        # so the add lines up with tTR_rAcc.
                        tTR_rAcc.store(
                            tTR_rAcc.load()
                            + self.beta * tTR_rC.load().to(cutlass.Float32)
                        )

                    # SFD generation (narrow output only): activation on the FP32
                    # accumulator -> per sfd_vec_size abs-max -> pvscale_f32 -> cast
                    # to sf_dtype -> STG. Then rescale acc by norm_const *
                    # rcp(qpvscale_f32), where qpvscale_f32 is the SFD value read back
                    # after the cast so D_quant * SFD stays self-consistent.
                    if cutlass.const_expr(self.gen_sfd):
                        # Run the activation on the FP32 accumulator and write it
                        # back, so every scale factor below is derived from the
                        # final output value it describes.
                        tTR_rAcc.store(epilogue_op(tTR_rAcc.load()))
                        # Slice gSFD for this subtile and collapse stride-0 broadcast.
                        gSFD_subtile = tTR_gSFD[(None, None, None, real_subtile_idx)]
                        t2r_gSFD = cute.filter_zeros(gSFD_subtile)
                        # The plain SFD STG has no extent clamp, so it is predicated
                        # on BOTH the real M and N extents: the partition rounds the
                        # cta tile up in both axes, and an unguarded N-overhang store
                        # folds onto the next row's low sf_k columns. The fragment
                        # lies on one (m, n_base), so its first element gates it all.
                        cSFD_subtile = tTR_cSFD[(None, None, None, real_subtile_idx)]
                        sfd_m_in_bounds = cute.elem_less(
                            cSFD_subtile[0][0], mD_mnl.shape[0]
                        )
                        sfd_n_in_bounds = cute.elem_less(
                            cSFD_subtile[0][1], mD_mnl.shape[1]
                        )
                        sfd_in_bounds = sfd_m_in_bounds and sfd_n_in_bounds
                        # Partition tTR_rAcc into vec_size groups along the contig (K)
                        # mode.
                        sfgen_rAcc = cute.logical_divide(tTR_rAcc, self.sfd_vec_size)
                        n_sf = cute.size[1](sfgen_rAcc)
                        rSFD = cute.make_rmem_tensor((1, n_sf), dtype=self.sfd_dtype)
                        # Reciprocal of the output dtype's full-scale max (M_D).
                        rcp_max = cutlass.Float32(1.0 / self.M_D)
                        fp32_max = cutlass.Float32(3.40282346638528859812e38)
                        # Single-pass: compute amax, quantize SFD, and rescale acc
                        # in the same loop. The acc rescale reads the SFD value
                        # back after the E4M3 cast (qpvscale_f32), so the dequant
                        # identity D_quant * SFD reproduces the pre-quant
                        # accumulator to within the FP4 data round-off.
                        for i_sf in cutlass.range(n_sf, unroll_full=True):
                            sfgen_slice = sfgen_rAcc[(None, i_sf)]
                            red_ssa = sfgen_slice.load()
                            red_abs_ssa = cute.math.absf(red_ssa)
                            amax = cutlass.Float32(
                                red_abs_ssa.reduce(
                                    cute.ReductionOp.MAX,
                                    cutlass.Float32(0.0),
                                    0,
                                )
                            )
                            pvscale_f32 = amax * rcp_max * norm_const
                            rSFD[(0, i_sf)] = pvscale_f32.to(self.sfd_dtype)
                            qpvscale_f32 = cutlass.Float32(
                                rSFD[(0, i_sf)].to(cutlass.Float32)
                            )
                            acc_scale = norm_const * cute.arch.rcp_approx(qpvscale_f32)
                            acc_scale = cutlass.Float32(
                                nvvm.fmin(
                                    acc_scale.ir_value(),
                                    fp32_max.ir_value(),
                                    nan=True,
                                )
                            )
                            sfgen_slice.store(sfgen_slice.load() * acc_scale)
                        # Store SFD to gmem, predicated on both the M and N bounds.
                        # Scalar STG per SF element with a static (unrolled) index:
                        # the gmem address is base + i * runtime_stride, so the
                        # tensor's global extent may be a runtime Int and only the
                        # per-thread element count has to be static.
                        if sfd_in_bounds:
                            for i_st in cutlass.range(n_sf, unroll_full=True):
                                t2r_gSFD[i_st] = rSFD[(0, i_st)]

                    # Convert to D type. With SFD the activation has already run on
                    # the FP32 accumulator, so the rescaled values are only narrowed
                    # here. A 16-bit output takes the activation at this step.
                    acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
                    if cutlass.const_expr(self.gen_sfd):
                        acc_vec = acc_vec.to(self.d_dtype)
                    else:
                        acc_vec = epilogue_op(acc_vec).to(self.d_dtype)
                    tRS_rD.store(acc_vec)

                    #
                    # Store D to shared memory
                    #
                    d_buffer = (num_prev_subtiles + subtile_idx) % self.num_d_stage
                    cute.copy(
                        tiled_copy_r2s,
                        tRS_rD,
                        tRS_sD[(None, None, None, d_buffer)],
                    )
                    # Fence and barrier to make sure shared memory store is visible to
                    # TMA store
                    cute.arch.fence_proxy(
                        "async.shared",
                        space="cta",
                    )
                    self.epilog_sync_barrier.arrive_and_wait()

                    #
                    # TMA store D to global memory
                    #
                    if warp_idx == self.epilogue_warp_id[0]:
                        cute.copy(
                            tma_atom_d,
                            bSG_sD[(None, d_buffer)],
                            bSG_gD[(None, real_subtile_idx)],
                        )
                        # Fence and barrier to make sure shared memory store is visible
                        # to TMA store
                        d_pipeline.producer_commit()
                        d_pipeline.producer_acquire()
                    self.epilog_sync_barrier.arrive_and_wait()

                #
                # Async arrive accumulator buffer empty. Under overlapping-accum
                # the release already happened mid-loop (early release above), so
                # only the non-overlapping path releases here.
                #
                if cutlass.const_expr(not self.overlapping_accum):
                    with cute.arch.elect_one():
                        acd_pipeline.consumer_release(acc_consumer_state)
                    acc_consumer_state.advance()

                #
                # Advance to next tile (CLC consumer)
                #
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            self.epilog_sync_barrier.arrive_and_wait()
            tmem.free(acc_tmem_ptr)
            #
            # Wait for D store complete
            #
            d_pipeline.producer_tail()

    @staticmethod
    def can_implement(
        ncdhw: Tuple[int, int, int, int, int],
        k: int,
        filter_trs: Tuple[int, int, int],
        upper_pad_dhw: Tuple[int, int, int],
        lower_pad_dhw: Tuple[int, int, int],
        stride_dhw: Tuple[int, int, int],
        dil_dhw: Tuple[int, int, int],
        ab_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        d_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mn: Tuple[int, int],
        cta_tile_k: int,
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
        swizzle_size: int,
        raster_along: Literal["m", "n"],
        has_bias: bool = False,
        bias_dtype: Optional[Type[cutlass.Numeric]] = None,
        c_dtype: Optional[Type[cutlass.Numeric]] = None,
        beta: float = 0.0,
        activation: str = "identity",
    ) -> bool:
        """Run every host-side check and tell whether the configuration is supported.

        The checks go from the structural ones to the geometry-derived ones: element
        and scale-factor types, epilogue activation, mma tiler, cluster shapes and K
        tile, channel count, convolution geometry, tensor alignment, cluster problem
        size and swizzle, im2col descriptor limits.

        :param ncdhw: Input extents (N, C, D, H, W)
        :type ncdhw: Tuple[int, int, int, int, int]
        :param k: Output channel count, which is the implicit-GEMM N extent
        :type k: int
        :param filter_trs: Filter extents (T, R, S)
        :type filter_trs: Tuple[int, int, int]
        :param upper_pad_dhw: Trailing padding per spatial dimension
        :type upper_pad_dhw: Tuple[int, int, int]
        :param lower_pad_dhw: Leading padding per spatial dimension
        :type lower_pad_dhw: Tuple[int, int, int]
        :param stride_dhw: Convolution stride per spatial dimension
        :type stride_dhw: Tuple[int, int, int]
        :param dil_dhw: Dilation per spatial dimension
        :type dil_dhw: Tuple[int, int, int]
        :param ab_dtype: A/B element type
        :type ab_dtype: Type[cutlass.Numeric]
        :param sf_dtype: Scale-factor element type, shared by SFA, SFB and SFD
        :type sf_dtype: Type[cutlass.Numeric]
        :param sf_vec_size: Channels one scale factor covers
        :type sf_vec_size: int
        :param d_dtype: Output element type
        :type d_dtype: Type[cutlass.Numeric]
        :param acc_dtype: Accumulator element type
        :type acc_dtype: Type[cutlass.Numeric]
        :param use_2cta_instrs: Whether the MMA runs on a 2-CTA instruction
        :type use_2cta_instrs: bool
        :param mma_tiler_mn: MMA tiler shape (M, N)
        :type mma_tiler_mn: Tuple[int, int]
        :param cta_tile_k: Compile-time K tile in channels
        :type cta_tile_k: int
        :param preferred_cluster_shape_mn: Preferred cluster shape (M, N)
        :type preferred_cluster_shape_mn: Tuple[int, int]
        :param fallback_cluster_shape_mn: Fallback cluster shape (M, N), which every
            launch can form
        :type fallback_cluster_shape_mn: Tuple[int, int]
        :param swizzle_size: Tile-scheduler swizzle size
        :type swizzle_size: int
        :param raster_along: Tile-scheduler rasterization order
        :type raster_along: Literal["m", "n"]
        :param has_bias: Whether a per-output-channel bias is supplied
        :type has_bias: bool
        :param bias_dtype: Bias element type, or None when no bias is supplied
        :type bias_dtype: Optional[Type[cutlass.Numeric]]
        :param c_dtype: Residual (C) element type, or None when no residual is passed
        :type c_dtype: Optional[Type[cutlass.Numeric]]
        :param beta: Compile-time residual coefficient
        :type beta: float
        :param activation: Name of the compile-time epilogue activation, one of
            EPILOGUE_ACTIVATIONS
        :type activation: str

        :return: True if the configuration can be implemented, False otherwise
        :rtype: bool
        """
        try:
            # The block-scaled MMA accumulates in FP32 only.
            if acc_dtype is not cutlass.Float32:
                raise testing.CantImplementError(
                    f"acc_dtype must be Float32, got {acc_dtype}"
                )
            # The residual path is compiled in by beta != 0 and reads C, so the two go
            # together. C is loaded by an im2col TMA atom built on D's geometry into
            # smem laid out like D's, so it must match D's dtype exactly.
            if (beta != 0.0) != (c_dtype is not None):
                raise testing.CantImplementError(
                    f"beta = {beta} with c_dtype = {c_dtype}: beta != 0 requires a "
                    "residual C and beta == 0 takes none."
                )
            if c_dtype is not None and c_dtype is not d_dtype:
                raise testing.CantImplementError(
                    f"Residual c_dtype ({c_dtype}) must equal d_dtype ({d_dtype})."
                )
            # Two input formats, each pinned to one scale-factor format:
            #   NVFP4  : Float4E2M1FN A/B, Float8E4M3FN scale over 16 channels.
            #   MXFP8  : Float8E4M3FN A/B, Float8E8M0FNU scale over 32 channels.
            # The element type is pinned with the vector size because it drives the SFB
            # layout, transaction bytes and SFD rounding; a mismatch is misinterpreted.
            sf_format = {
                cutlass.Float4E2M1FN: (cutlass.Float8E4M3FN, 16),
                cutlass.Float8E4M3FN: (cutlass.Float8E8M0FNU, 32),
            }.get(ab_dtype)
            if sf_format is None:
                raise testing.CantImplementError(
                    f"Only Float4E2M1FN (NVFP4) and Float8E4M3FN (MXFP8) A/B "
                    f"are supported, got {ab_dtype}."
                )
            want_sf_dtype, want_sf_vec_size = sf_format
            if sf_dtype is not want_sf_dtype or sf_vec_size != want_sf_vec_size:
                raise testing.CantImplementError(
                    f"{ab_dtype} A/B requires sf_dtype={want_sf_dtype} over "
                    f"{want_sf_vec_size} channels, got sf_dtype={sf_dtype}, "
                    f"sf_vec_size={sf_vec_size}."
                )
            # D is either the narrow output paired with the input format -- NVFP4
            # with FP4, MXFP8 with FP8 E4M3 -- or a 16-bit wide output. The pairing
            # is forced by the SFD: the epilogue rescales by an approximate
            # reciprocal of the quantized scale factor, which FP4's eight magnitudes
            # absorb and FP8 E4M3's few hundred do not. A wide output carries no SFD.
            paired_narrow_output = {
                cutlass.Float4E2M1FN: cutlass.Float4E2M1FN,
                cutlass.Float8E4M3FN: cutlass.Float8E4M3FN,
            }[ab_dtype]
            if d_dtype not in (
                paired_narrow_output,
                cutlass.BFloat16,
                cutlass.Float16,
            ):
                raise testing.CantImplementError(
                    f"d_dtype must be {paired_narrow_output} (the block-scaled narrow "
                    f"output paired with {ab_dtype} A/B), BFloat16 or Float16, got "
                    f"{d_dtype}."
                )
            if d_dtype in (cutlass.Float4E2M1FN, cutlass.Float8E4M3FN):
                if has_bias:
                    raise testing.CantImplementError(
                        f"A block-scaled {d_dtype} output does not support a bias."
                    )
                # The residual shares D's own dtype, so a block-scaled narrow
                # output makes the addend FP4 or FP8 -- eight magnitudes in one
                # case, a few hundred in the other -- putting the term's
                # quantization error at the same order as the term itself.
                if c_dtype is not None:
                    raise testing.CantImplementError(
                        f"A block-scaled {d_dtype} output does not support a residual."
                    )
            # The staged bias row is filled with 32-bit vectors and the epilogue's bias
            # floor is 16 bits, so the bias is one of these 16- or 32-bit floats.
            allowed_bias_dtype = (cutlass.Float16, cutlass.BFloat16, cutlass.Float32)
            if has_bias and bias_dtype not in allowed_bias_dtype:
                raise testing.CantImplementError(
                    f"bias_dtype must be one of {allowed_bias_dtype}, got {bias_dtype}"
                )
            # One epilogue lane stages one 32-bit vector of the bias row, so the row
            # takes cta_tile_n / (32 / bias_dtype.width) lanes and the whole row is
            # filled in a single pass. A row that needs more lanes than the epilogue
            # has would be read back with part of it unwritten, so a wider tile or a
            # wider bias element type is refused here.
            if has_bias:
                bias_lanes = mma_tiler_mn[1] // (32 // bias_dtype.width)
                epilogue_lanes = 32 * len(
                    Sm100BlockScaledDenseImplicitGemmFpropKernel.epilogue_warp_id
                )
                if bias_lanes > epilogue_lanes:
                    raise testing.CantImplementError(
                        f"Staging a {bias_dtype} bias row for a "
                        f"{mma_tiler_mn[1]}-wide N tile takes {bias_lanes} lanes, "
                        f"more than the {epilogue_lanes} the epilogue has."
                    )
            # The activation's device op is folded into the cubin, so only a name the
            # table carries can be served.
            if activation not in EPILOGUE_ACTIVATIONS:
                raise testing.CantImplementError(
                    f"Unsupported activation {activation!r}; "
                    f"choose from {sorted(EPILOGUE_ACTIVATIONS)}"
                )
            # tcgen05.mma fills N in 32-wide steps up to 256. The legal M is
            # pinned further down, to the single value the blockscaled MMA atom has.
            if mma_tiler_mn[1] not in range(32, 257, 32):
                raise testing.CantImplementError(
                    f"Invalid mma tiler N: {mma_tiler_mn[1]}"
                )
            check_cluster_shape(
                use_2cta_instrs,
                preferred_cluster_shape_mn,
                fallback_cluster_shape_mn,
                swizzle_size,
                raster_along,
            )
            # make_blockscaled_trivial_tiled_mma has no M=64 atom, so the per-CTA M
            # has to be 128. The per-CTA M is mma_tiler_m halved under 2CTA, so
            # mma_tiler_m has to be 128 with 1CTA and 256 with 2CTA.
            required_mma_tiler_m = 256 if use_2cta_instrs else 128
            if mma_tiler_mn[0] != required_mma_tiler_m:
                raise testing.CantImplementError(
                    f"Blockscaled conv requires per-CTA M=128, so mma_tiler_m must be "
                    f"{required_mma_tiler_m} with use_2cta_instrs={use_2cta_instrs}, "
                    f"got {mma_tiler_mn[0]}. Use mma_tiler_m=128 with 1CTA or "
                    f"mma_tiler_m=256 with 2CTA."
                )
            # cta_tile_k legality. Both formats take a whole number of MMA K
            # instructions. 192 is excluded: its odd SF-K atom count cannot be halved
            # when the 2CTA SFB multicast splits along K. MXFP8 stops at 128, its SF
            # atom width; NVFP4 goes up to 256.
            allowed_tile_k = (
                (64, 128) if ab_dtype is cutlass.Float8E4M3FN else (64, 128, 256)
            )
            if cta_tile_k not in allowed_tile_k:
                raise testing.CantImplementError(
                    f"{ab_dtype} requires cta_tile_k in {allowed_tile_k}, got "
                    f"{cta_tile_k}."
                )
            # The SFB multicast hands each cluster-M CTA a part of the staged scale
            # factors, split along K, so the cluster cannot be deeper in M than the K
            # tile has parts to give out. Past the limit the descriptor addresses a
            # part that is not there and the store faults on a misaligned address, so
            # it is refused up front. MXFP8 stages one atom whatever the tile_k.
            sf_per_k_tile = sf_k_tile_channels(cta_tile_k, sf_vec_size) // sf_vec_size
            for which, cluster_mn in (
                ("preferred", preferred_cluster_shape_mn),
                ("fallback", fallback_cluster_shape_mn),
            ):
                if cluster_mn[0] > sf_per_k_tile:
                    raise testing.CantImplementError(
                        f"{ab_dtype} with cta_tile_k = {cta_tile_k} stages "
                        f"{sf_per_k_tile} scale factors per K tile, so the {which} "
                        f"cluster cannot span more than {sf_per_k_tile} CTAs along M, "
                        f"got {cluster_mn[0]}."
                    )
            # C legality. Either format takes a partial trailing K tile -- its A and
            # B arrive zero-filled and its scale factors are read in bounds -- so C
            # need not be a whole number of K tiles. It must be a whole number of
            # scale-factor atoms, 4 * sf_vec_size channels: SFA's 4-byte cp.async
            # carries one atom and walks a row stride this keeps a multiple of 4.
            c = ncdhw[1]
            sf_atom_channels = sf_vec_size * 4
            if c % sf_atom_channels != 0:
                raise testing.CantImplementError(
                    f"{ab_dtype} requires C to be a multiple of {sf_atom_channels}, "
                    f"got C = {c}."
                )
            check_conv_geometry(
                ncdhw,
                (k, *filter_trs),
                stride_dhw,
                upper_pad_dhw,
                lower_pad_dhw,
                dil_dhw,
            )
            # 16B output alignment forces Kout % 32 == 0 for FP4 D, which is
            # what makes the SFD N-bound predicate (gates a whole subtile on its
            # first-element N coord) exact -- so no separate Kout guard is needed.
            check_tensor_alignment(c, k, ab_dtype, d_dtype)
            # Implicit-GEMM M is N*Z*P*Q.
            z, p, q = compute_zpq(
                ncdhw[2:],
                filter_trs,
                stride_dhw,
                upper_pad_dhw,
                lower_pad_dhw,
                dil_dhw,
            )
            gemm_m = ncdhw[0] * z * p * q
            check_preferred_cluster_problem_size(
                gemm_m,
                k,
                use_2cta_instrs,
                mma_tiler_mn,
                preferred_cluster_shape_mn,
            )
            # SFB stages 128 output channels at a time, so an mma_tiler_n below that
            # puts several N tiles in one chunk, each needing its own Tensor Memory
            # read offset. That offset exists for 64 (two tiles per chunk) and 192
            # (the chunk pair reshaped into overlapping 256-wide windows); 128 and
            # 256 sit on chunk boundaries, and the rest serve a single N tile only.
            cta_tile_n = mma_tiler_mn[1]
            if cta_tile_n not in (64, 128, 192, 256):
                n_tiles = -(-k // cta_tile_n)
                if n_tiles > 1:
                    raise testing.CantImplementError(
                        f"mma_tiler_n={cta_tile_n} has no per-tile SFB chunk offset, "
                        f"so it only serves a single N tile, but K={k} needs "
                        f"{n_tiles}. Use mma_tiler_n of 64, 128, 192 or 256."
                    )
            # Require enough clusters along the swizzled dimension
            check_swizzle_size(
                gemm_m,
                k,
                mma_tiler_mn,
                use_2cta_instrs,
                preferred_cluster_shape_mn,
                fallback_cluster_shape_mn,
                swizzle_size,
                raster_along,
            )
            check_im2col_descriptor_limits(
                filter_trs,
                upper_pad_dhw,
                lower_pad_dhw,
                stride_dhw,
                dil_dhw,
            )
        except (testing.CantImplementError, ValueError) as e:
            print(e)
            return False
        return True


def emits_sfd(d_dtype: Type[cutlass.Numeric]) -> bool:
    """Whether the epilogue writes output scale factors.

    A narrow (block-scaled) output carries an SFD tensor; a 16-bit one carries none.
    The answer follows from the output type alone, so the compile entry and the
    caller that allocates the SFD tensor both derive it here and always agree.
    """
    return d_dtype in (cutlass.Float4E2M1FN, cutlass.Float8E4M3FN)


@lru_cache(maxsize=None)
def compile_conv(
    ab_dtype: Type[cutlass.Numeric],
    d_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    cta_tile_k: int,
    bias_dtype: Optional[Type[cutlass.Numeric]] = None,
    beta: float = 0.0,
    mma_tiler: Tuple[int, int] = (256, 256),
    preferred_cluster_shape_mn: Tuple[int, int] = (2, 1),
    fallback_cluster_shape_mn: Tuple[int, int] = (2, 1),
    swizzle_size: int = 1,
    raster_along: Literal["m", "n"] = "m",
    use_2cta_instrs: bool = True,
    activation: str = "identity",
    frontendnext: bool = False,
):
    """
    Compile a 3D convolution kernel.

    Every parameter is a hashable scalar that selects a cubin, so the result is
    cached unbounded: a repeat configuration skips both the trace and the compile.
    The tensors are stood in for by fakes built from the element types, because the
    compiled module reads nothing else from them. Which of them exist follows from
    the scalars: an SFD from the output type, a residual from beta, a bias from
    bias_dtype.

    :param ab_dtype: Element type of the input and filter tensors
    :param d_dtype: Element type of the output tensor
    :param acc_dtype: Accumulator data type
    :param sf_dtype: Element type of the block scale factors
    :param sf_vec_size: Channels one scale factor covers
    :param cta_tile_k: Compile-time K tile extent
    :param bias_dtype: Element type of the per-output-channel bias, or None for a
        cubin without the bias path
    :param beta: Compile-time residual scale; 0.0 compiles the residual path away
    :param mma_tiler: MMA tile shape (M, N)
    :param preferred_cluster_shape_mn: Preferred cluster shape (M, N) for CLC dynamic
        scheduling
    :param fallback_cluster_shape_mn: Fallback cluster shape (M, N) for CLC dynamic
        scheduling
    :param swizzle_size: Swizzling size in the unit of cluster. 1 means no swizzle
    :param raster_along: Rasterization order of clusters. Only used when swizzle_size >
        1
    :param use_2cta_instrs: Whether to use 2CTA instructions
    :param activation: Name of the compile-time epilogue activation, one of
        EPILOGUE_ACTIVATIONS. One activation per cubin
    :param frontendnext: Whether the caller is running under the pyir frontend. A
        key-only parameter: the two frontends emit different cubins for the same
        inputs, so an artifact compiled under one must not be served to the other
    :return: Compiled kernel function
    """
    from cutlass.cute.runtime import make_fake_stream

    input = make_fake_conv_tensor(ab_dtype, 5, 4)
    filter = make_fake_conv_tensor(ab_dtype, 5, 4)
    output = make_fake_conv_tensor(d_dtype, 5, 4)
    sfa = make_fake_conv_tensor(sf_dtype, 3, 1)
    sfb = make_fake_conv_tensor(sf_dtype, 6, 3)
    sfd = make_fake_conv_tensor(sf_dtype, 3, 1) if emits_sfd(d_dtype) else None
    bias = None if bias_dtype is None else make_fake_conv_tensor(bias_dtype, 1, 0)
    # The residual shares the output's descriptor, so can_implement pins its type to
    # the output's; beta alone says whether the path is compiled in.
    c = make_fake_conv_tensor(d_dtype, 5, 4) if beta != 0.0 else None
    # alpha and norm_const reach the kernel as runtime FP32, so a placeholder traces
    # the same module the caller's value launches against.
    alpha = cutlass.Float32(1.0)
    norm_const = cutlass.Float32(1.0)

    # The activation's device op is folded into the cubin, so a different activation
    # is a different kernel.
    epilogue_op = EPILOGUE_ACTIVATIONS[activation]["device"]

    # Create convolution kernel object. Only cta_tile_k (compile-time K tile) is
    # a build-time shape parameter; the input channel count C and all output
    # geometry (N/Z/P/Q/K) are read from the dynamic tensors at runtime, so one
    # cubin serves every C. Filter T/R/S and pad/stride/dil are likewise runtime
    # (dynamic filter extents + boxed Int32).
    conv_op = Sm100BlockScaledDenseImplicitGemmFpropKernel(
        acc_dtype,
        sf_vec_size,
        use_2cta_instrs,
        mma_tiler,
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
        cta_tile_k,
        swizzle_size,
        raster_along,
    )

    stream = make_fake_stream()
    return cute.compile(
        conv_op,
        input,
        filter,
        sfa,
        sfb,
        output,
        sfd,
        bias,
        c,
        alpha,
        beta,
        norm_const,
        *trace_conv_scalars(),
        stream,
        epilogue_op,
    )


# Create scale factor tensor SFA/SFB


def create_sfd_tensor(
    l: int,
    mn: int,
    k: int,
    sf_vec_size: int,
    dtype: Type[cutlass.Numeric],
) -> Tuple[cute.Tensor, torch.Tensor]:
    """SFD gmem tensor, the scale factors the epilogue writes for a block-scaled
    narrow output, in natural (M, ceil(Kout/vec), L) layout. Zero-filled, so what
    a readback finds is what the kernel wrote. Returns (cute tensor, backing
    storage)."""

    def ceil_div(a, b):
        return (a + b - 1) // b

    # The M-direction stride is sf_k and the 4-byte cp.async that walks it needs a
    # multiple of 4 factors. k is Kout here, which no gate constrains, so the
    # allocation rounds sf_k up to that multiple and the tail stays zero.
    sf_k = ceil_div(k, sf_vec_size)
    alloc_sf_k = ceil_div(sf_k, 4) * 4

    torch_tensor = torch.empty(
        (l, mn, alloc_sf_k), dtype=cutlass_torch.dtype(dtype), device="cuda"
    ).permute(1, 2, 0)
    torch_tensor.zero_()

    cute_tensor = from_dlpack(torch_tensor, assumed_align=16)
    cute_tensor.element_type = dtype
    # The device reaches this tensor's gmem through its own strides, with no host
    # rebuild, so the row stride over the sf_k extent must stay runtime for one
    # compiled module to serve every channel count. A frozen stride reads every
    # row at the wrong offset once that count changes.
    cute_tensor = cute_tensor.mark_layout_dynamic(leading_dim=1)
    return cute_tensor, torch_tensor


def run(
    ncdhw: Tuple[int, int, int, int, int],
    ktrs: Tuple[int, int, int, int],
    stride_dhw: Tuple[int, int, int] = (1, 1, 1),
    upper_pad_dhw: Tuple[int, int, int] = (0, 0, 0),
    lower_pad_dhw: Tuple[int, int, int] = (0, 0, 0),
    dil_dhw: Tuple[int, int, int] = (1, 1, 1),
    ab_dtype: Type[cutlass.Numeric] = cutlass.Float4E2M1FN,
    d_dtype: Type[cutlass.Numeric] = cutlass.Float4E2M1FN,
    c_dtype: Optional[Type[cutlass.Numeric]] = None,
    acc_dtype: Type[cutlass.Numeric] = cutlass.Float32,
    sf_dtype: Type[cutlass.Numeric] = cutlass.Float8E4M3FN,
    sf_vec_size: int = 16,
    cta_tile_k: Optional[int] = None,
    mma_tiler_mn: Tuple[int, int] = (128, 128),
    preferred_cluster_shape_mn: Tuple[int, int] = (2, 1),
    fallback_cluster_shape_mn: Tuple[int, int] = (1, 1),
    swizzle_size: int = 1,
    raster_along: Literal["m", "n"] = "m",
    use_2cta_instrs: bool = False,
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 0,
    use_cold_l2: bool = False,
    skip_ref_check: bool = False,
    use_bias: bool = False,
    bias_dtype: Optional[Type[cutlass.Numeric]] = None,
    alpha: float = 1.0,
    beta: float = 0.0,
    activation: str = "identity",
    **kwargs,
):
    """Run 3D convolution and compare against PyTorch reference.

    The filter tensor uses native KTRSC layout (K, T, R, S, C) with C contiguous.

    :param ncdhw: Input tensor shape (N, C, D, H, W)
    :param ktrs: Filter tensor shape components (K, T, R, S)
    :param stride_dhw: Stride (Sd, Sh, Sw)
    :param upper_pad_dhw: Upper padding (PadD, PadH, PadW)
    :param lower_pad_dhw: Lower padding (PadD, PadH, PadW)
    :param dil_dhw: Dilation (DilD, DilH, DilW)
    :param ab_dtype: Data type for A/B input tensors
    :param d_dtype: Data type for output tensor D
    :param c_dtype: Residual (C) data type; None takes the output type, which is the
        only value it can hold since C is staged in smem laid out like D's
    :param acc_dtype: Accumulator data type
    :param sf_dtype: Scale factor element type, E4M3 for NVFP4 and E8M0 for MXFP8
    :param sf_vec_size: Channels one scale factor covers, 16 for NVFP4 and 32 for MXFP8
    :param cta_tile_k: Compile-time K tile. The legal widths follow ab_dtype: NVFP4
        A/B takes 64, 128 or 256, MXFP8 A/B takes 64 or 128. None takes 128 for MXFP8
        and, for NVFP4, the widest legal width at or below C clamped into [64, 256]
    :param mma_tiler_mn: MMA tiler shape
    :param preferred_cluster_shape_mn: Preferred cluster shape (M, N) for CLC dynamic
        scheduling
    :param fallback_cluster_shape_mn: Fallback cluster shape (M, N) for CLC dynamic
        scheduling
    :param swizzle_size: Swizzling size in the unit of cluster. 1 means no swizzle
    :param raster_along: Rasterization order of clusters
    :param use_2cta_instrs: Whether to use 2CTA instructions
    :param tolerance: Tolerance for result comparison
    :param warmup_iterations: Number of warmup iterations
    :param iterations: Number of benchmark iterations
    :param use_cold_l2: Whether to flush L2 cache between iterations
    :param skip_ref_check: Whether to skip reference checking
    :param use_bias: Add a per-output-channel bias as D = activation(alpha*acc + bias +
        beta*residual); bias and no-bias are separate cubins
    :param bias_dtype: Bias element type; None derives it from the output type
    :param alpha: Per-tensor accumulator scale, applied before the SFD quantize.
        Runtime scalar: one cubin serves any value
    :param beta: Residual scaling; beta != 0 enables the residual path and beta == 0
        compiles it away
    :param activation: Compile-time epilogue activation, one per cubin
    :param kwargs: Extra keyword arguments, accepted and ignored
    """
    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    N, C, D, H, W = ncdhw
    K, T, R, S = ktrs

    # Residual (C) shares the output's shape and im2col TMA descriptor, so its
    # dtype defaults to the output dtype when the caller does not set one.
    if c_dtype is None:
        c_dtype = d_dtype

    # cta_tile_k is the compile-time K tile. When unset, take the largest legal tile
    # that fits in the channel count; a C the tile does not divide is fine, the
    # trailing tile is partial. A caller may pass one explicitly to reuse a cubin
    # across several C, or to trade tile width against channel padding. MXFP8
    # defaults to 128, the width of its SF atom, so a K tile stages exactly one.
    if cta_tile_k is None:
        if ab_dtype is cutlass.Float8E4M3FN:
            cta_tile_k = 128
        else:
            cta_tile_k = max(t for t in (64, 128, 256) if t <= max(64, min(256, C)))

    # Settle the bias element type before the configuration is checked, so the check
    # sees the type the bias tensor will actually carry.
    if use_bias and bias_dtype is None:
        bias_dtype = bias_dtype_for_output(d_dtype)
    # Every host-side check runs here, before any tensor or compile work.
    if not Sm100BlockScaledDenseImplicitGemmFpropKernel.can_implement(
        ncdhw,
        ktrs[0],
        ktrs[1:],
        upper_pad_dhw,
        lower_pad_dhw,
        stride_dhw,
        dil_dhw,
        ab_dtype,
        sf_dtype,
        sf_vec_size,
        d_dtype,
        acc_dtype,
        use_2cta_instrs,
        mma_tiler_mn,
        cta_tile_k,
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
        swizzle_size,
        raster_along,
        use_bias,
        bias_dtype if use_bias else None,
        c_dtype if beta != 0.0 else None,
        beta,
        activation,
    ):
        raise testing.CantImplementError(
            f"Config not implementable: ncdhw={ncdhw}, ktrs={ktrs}, "
            f"stride={stride_dhw}, pad=({upper_pad_dhw}, {lower_pad_dhw}), "
            f"dilation={dil_dhw}, mma_tiler={mma_tiler_mn}, cta_tile_k={cta_tile_k}, "
            f"use_2cta_instrs={use_2cta_instrs}, "
            f"cluster=({preferred_cluster_shape_mn}, {fallback_cluster_shape_mn}), "
            f"swizzle=({swizzle_size}, {raster_along}), "
            f"dtypes=({ab_dtype}, {sf_dtype}/{sf_vec_size}, {d_dtype}, {acc_dtype}), "
            f"bias_dtype={bias_dtype if use_bias else None}, beta={beta}, "
            f"activation={activation}"
        )
    Z, P, Q = compute_zpq(
        ncdhw[2:], ktrs[1:], stride_dhw, upper_pad_dhw, lower_pad_dhw, dil_dhw
    )

    print("Running Blackwell 3D Convolution test with:")
    print(f"  Input shape (N, C, D, H, W): {ncdhw}")
    print(f"  Filter shape (K, C, T, R, S): ({K}, {C}, {T}, {R}, {S})")
    print(f"  Output shape (N, K, Z, P, Q): ({N}, {K}, {Z}, {P}, {Q})")
    print(f"  Stride (Sd, Sh, Sw): {stride_dhw}")
    print(f"  Upper padding (PadD, PadH, PadW): {upper_pad_dhw}")
    print(f"  Lower padding (PadD, PadH, PadW): {lower_pad_dhw}")
    print(f"  Dilation (DilD, DilH, DilW): {dil_dhw}")
    print(f"  A/B data type: {ab_dtype}")
    print(f"  D data type: {d_dtype}")
    print(f"  Accumulator type: {acc_dtype}")
    print(f"  sf data type: {sf_dtype}")
    print(f"  sf vec size: {sf_vec_size}")
    print(f"  MMA tiler (M, N): {mma_tiler_mn}")
    print(f"  Preferred cluster shape (M, N): {preferred_cluster_shape_mn}")
    print(f"  Fallback cluster shape (M, N): {fallback_cluster_shape_mn}")
    print(f"  Swizzle size: {swizzle_size}")
    print(f"  Raster along: {raster_along}")
    print(f"  Use 2CTA instructions: {use_2cta_instrs}")
    print()

    # Create input and filter tensors
    input_tensor, filter_tensor, output_tensor = prepare_fprop_tensors(
        ncdhw, ktrs, (Z, P, Q), ab_dtype
    )

    # Prepare cute tensors
    input_, input_storage = create_cute_tensor(input_tensor, ab_dtype, leading_dim=4)
    filter_, filter_storage = create_cute_tensor(filter_tensor, ab_dtype, leading_dim=4)
    output_, output_storage = create_cute_tensor(output_tensor, d_dtype, leading_dim=4)
    # Free staging buffers once consumed to bound peak memory and avoid OOM.
    del output_tensor

    sfa_ref, sfa_, sfa_storage = create_scale_factor_tensor_unswizzled(
        1,
        N * D * H * W,
        C,
        sf_vec_size,
        sf_dtype,
    )
    # Allocate SFB at the per-position span: the channels past C pair with the
    # zero-filled B the TMA produces there, so what they scale is zero.
    sfb_c_span = sfb_per_position_channels(C, cta_tile_k, sf_vec_size)
    sfb_ref, sfb_, sfb_storage = create_scale_factor_tensor_swizzled(
        1,
        K,
        sfb_c_span * T * R * S,
        sf_vec_size,
        sf_dtype,
    )
    # SFD: emitted for a narrow (block-scaled) output; FP16 and BF16 carry none. It
    # takes the input's scale format outright, so NVFP4 stays E4M3 over 16 channels
    # and MXFP8 E8M0 over 32 on both sides.
    gen_sfd = emits_sfd(d_dtype)
    sfd_vec_size = sf_vec_size
    sfd_dtype = sf_dtype
    if gen_sfd:
        sfd_, sfd_storage = create_sfd_tensor(
            1, N * Z * P * Q, K, sfd_vec_size, sfd_dtype
        )
    else:
        sfd_, sfd_storage = None, None

    # Per-output-channel bias of length K, in the bias element type (the epilogue's
    # 16-bit floor keeps it wider than a narrow output). Added to the accumulator in
    # FP32 as D = alpha*acc + bias, broadcast across every spatial output position.
    # Marked dynamic-layout so the length-K extent lowers to runtime SSA; a static
    # extent would freeze K into the compiled module.
    if use_bias:
        bias_storage = torch.randn(K, dtype=torch.float32, device="cuda").to(
            cutlass_torch.dtype(bias_dtype)
        )
        bias_ = from_dlpack(bias_storage, assumed_align=16).mark_layout_dynamic(
            leading_dim=0
        )
    else:
        bias_storage, bias_ = None, None

    # Per-element residual (C), same (N, Z, P, Q, K) shape as the output D.
    # Added to the accumulator in FP32 as D = alpha*acc + bias + beta*C.
    # Built as a dynamic-layout cute tensor (leading_dim=4, K contiguous) so it
    # is described by the same im2col TMA descriptor as the output store.
    if beta != 0.0:
        c_f32_src = torch.randn((N, Z, P, Q, K), dtype=torch.float32, device="cuda")
        c_, c_storage = create_cute_tensor(c_f32_src, c_dtype, leading_dim=4)
    else:
        c_f32_src, c_storage, c_ = None, None, None

    # Per-tensor FP32 scaling factors, passed as runtime scalars, so one cubin
    # serves any value:
    #   alpha:      applied in accumulator precision before quantize
    #   norm_const: folded into SFD scale-up (only used when gen_sfd)
    alpha_ = cutlass.Float32(alpha)
    norm_const_ = cutlass.Float32(1.0)

    # Compile convolution kernel
    print("Compiling kernel with cute.compile ...")
    compiled_fn = compile_conv(
        ab_dtype,
        d_dtype,
        acc_dtype,
        sf_dtype,
        sf_vec_size,
        cta_tile_k,
        bias_dtype=bias_dtype if use_bias else None,
        beta=beta,
        mma_tiler=mma_tiler_mn,
        preferred_cluster_shape_mn=preferred_cluster_shape_mn,
        fallback_cluster_shape_mn=fallback_cluster_shape_mn,
        swizzle_size=swizzle_size,
        raster_along=raster_along,
        use_2cta_instrs=use_2cta_instrs,
        activation=activation,
        frontendnext=frontend_cache_token(),
    )

    # A fresh non-default stream carries the kernel: CUDA graph capture, which the
    # benchmark below uses, requires one.
    torch_stream = torch.cuda.Stream()
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # The compiled entry expects the 12 pad / stride / dilation scalars (upper
    # d/h/w, lower d/h/w, stride d/h/w, dil d/h/w). They are passed as runtime
    # cutlass.Int32, which the rt_ prefix marks, so one compiled cubin serves any
    # geometry.
    print("Running Blackwell 3D convolution...")
    # The inputs initialize on other streams; drain them so the kernel's
    # stream never reads a tensor mid-initialization.
    torch.cuda.synchronize()
    compiled_fn(
        input_,
        filter_,
        sfa_,
        sfb_,
        output_,
        sfd_,
        bias_,
        c_,
        alpha_,
        norm_const_,
        *rt_conv_scalars(
            upper_pad=upper_pad_dhw,
            lower_pad=lower_pad_dhw,
            stride=stride_dhw,
            dil=dil_dhw,
        ),
        current_stream,
    )
    torch_stream.synchronize()

    if not skip_ref_check:
        print("Verifying results with block-scaled reference...")
        # Block-scaled reference using F.conv3d with pre-scaled inputs
        # This handles padding/stride/dilation correctly

        # Pre-scale input by SFA: sfa_ref shape (N*D*H*W, C, 1). The kernel has read
        # A, so its f32 source takes the scale factors in place.
        sfa_expanded = sfa_ref.squeeze(-1).reshape(N, D, H, W, C).cuda()
        scaled_input = input_tensor.mul_(sfa_expanded)
        # Free staging buffers once consumed to bound peak memory and avoid OOM.
        del input_tensor, sfa_ref, sfa_expanded

        # Pre-scale filter by SFB: sfb_ref shape (K, C*T*R*S, 1)
        # Drop the per-position padding channels: they scale zero-filled B and have
        # no counterpart in the reference convolution.
        sfb_expanded = (
            sfb_ref.squeeze(-1).reshape(K, T, R, S, sfb_c_span)[..., :C].cuda()
        )
        scaled_filter = filter_tensor.cuda().float() * sfb_expanded

        # F.conv3d expects (N, C, D, H, W) and (K, C, T, R, S)
        scaled_input_ncdhw = scaled_input.permute(0, 4, 1, 2, 3).contiguous()
        # Free staging buffers once consumed to bound peak memory and avoid OOM.
        del scaled_input
        scaled_filter_kctrs = scaled_filter.permute(0, 4, 1, 2, 3).contiguous()

        if upper_pad_dhw == lower_pad_dhw:
            ref_nkzpq = F.conv3d(
                scaled_input_ncdhw,
                scaled_filter_kctrs,
                padding=upper_pad_dhw,
                stride=stride_dhw,
                dilation=dil_dhw,
            )
            # Free staging buffers once consumed to bound peak memory and avoid OOM.
            del scaled_input_ncdhw
        else:
            # Asymmetric padding: F.pad then conv3d without padding.
            # Convention: lower_pad = leading (left), upper_pad = trailing (right).
            # This must match the im2col TMA descriptor which subtracts lower_pad
            # when mapping output coords to input coords (d_in = z*stride - lower_pad +
            # t*dil).
            padded = F.pad(
                scaled_input_ncdhw,
                (
                    lower_pad_dhw[2],
                    upper_pad_dhw[2],
                    lower_pad_dhw[1],
                    upper_pad_dhw[1],
                    lower_pad_dhw[0],
                    upper_pad_dhw[0],
                ),
            )
            # Free staging buffers once consumed to bound peak memory and avoid OOM.
            del scaled_input_ncdhw
            ref_nkzpq = F.conv3d(
                padded,
                scaled_filter_kctrs,
                stride=stride_dhw,
                dilation=dil_dhw,
            )
            # Free staging buffers once consumed to bound peak memory and avoid OOM.
            del padded

        # Convert to NZPQK layout (matching kernel output)
        ref = ref_nkzpq.permute(0, 2, 3, 4, 1).contiguous()  # (N, Z, P, Q, K)
        # Free staging buffers once consumed to bound peak memory and avoid OOM.
        del ref_nkzpq
        # Scale the accumulator by alpha in the FP32 domain, then add the
        # per-output-channel bias broadcast across N/Z/P/Q
        # (D = alpha*acc + bias). The SFD replay below takes its per-vector amax
        # from the activated result, so alpha, the bias, the residual and the
        # activation all land ahead of it.
        ref = alpha * ref
        if use_bias:
            ref = ref + bias_storage.float().view(1, 1, 1, 1, K)
        # Add the per-element residual (D = alpha*acc + bias + beta*residual) in
        # the FP32 domain. c_storage holds the exact bf16 values the
        # kernel loads, so float() reproduces them bit-for-bit.
        if beta != 0.0:
            ref = ref + beta * c_storage.float().reshape(N, Z, P, Q, K).cuda()
        # Apply the epilogue activation on the full linear combination
        # (D = activation(alpha*acc + bias + beta*residual)), matching the
        # device op folded into the kernel.
        ref = EPILOGUE_ACTIVATIONS[activation]["ref"](ref)
        # Snapshot the un-quantized FP32 ref BEFORE the in-place quantize round-trip
        # below mutates `ref` (shares GPU storage with ref_device).
        ref_unquant_cpu = ref.detach().cpu().clone()

        # Convert kernel FP4 output to f32 for comparison
        d_ref_device = torch.empty((N, Z, P, Q, K), dtype=torch.float32, device="cuda")
        cute.testing.convert(
            output_,
            from_dlpack(d_ref_device, assumed_align=16).mark_layout_dynamic(
                leading_dim=4
            ),
        )
        d_ref_result = d_ref_device

        # Quantize reference: f32 -> d_dtype -> f32 (mutates ref in-place via shared
        # storage). Scratch storage dtype follows the kernel-convert rule: sub-byte
        # FP4 and <=8-bit floats pack into a uint8 byte buffer, while wider types
        # (f16/bf16/f32) use their native torch dtype so the buffer is not
        # under-allocated (f16 needs 2 bytes/elem, not 1).
        ref_quant_byte_storage = (d_dtype.is_float and d_dtype.width <= 8) or (
            d_dtype.is_integer and d_dtype.width == 4
        )
        ref_quant_storage_dtype = (
            torch.uint8 if ref_quant_byte_storage else cutlass_torch.dtype(d_dtype)
        )
        ref_f4_ = torch.empty(
            (N, Z, P, Q, K), dtype=ref_quant_storage_dtype, device="cuda"
        )
        ref_f4 = from_dlpack(ref_f4_, assumed_align=16).mark_layout_dynamic(
            leading_dim=4
        )
        ref_f4.element_type = d_dtype
        ref_device = ref.contiguous()
        ref_tensor = from_dlpack(ref_device, assumed_align=16).mark_layout_dynamic(
            leading_dim=4
        )
        cute.testing.convert(ref_tensor, ref_f4)
        cute.testing.convert(ref_f4, ref_tensor)
        # Free staging buffers once consumed to bound peak memory and avoid OOM.
        del ref_f4, ref_f4_
        ref_quantized = ref_device

        if gen_sfd:
            # SFD path: the kernel rescales acc by norm_const / SFD before the narrow
            # cast, so the raw kernel D is only meaningful together with SFD. Recompute
            # the reference SFD and the SFD-rescaled reference output fully on the host
            # -- amax, scale factor and rescale all from the un-quantized reference,
            # independent of the kernel's SFD -- then compare both elementwise.
            sf_k = (K + sfd_vec_size - 1) // sfd_vec_size
            # norm_const_ is a device Float32; the torch-side replay takes its value
            # as a host float (the host path always uses the 1.0 default).
            norm_const_host = 1.0
            fp32_max = torch.finfo(torch.float32).max

            # 1. Reference SFD and SFD-rescaled reference output, host-side:
            #    per-vector amax over sfd_vec_size contiguous K elements
            #    -> pvscale = amax * norm_const / M_D
            #    -> cast to sfd_dtype and read back (sfd_ref)
            #    -> rescale ref by norm_const / sfd_ref.
            m_d = 6.0 if d_dtype is cutlass.Float4E2M1FN else 448.0
            sfd_torch_dtype = cutlass_torch.dtype(sfd_dtype)
            k_pad = sf_k * sfd_vec_size
            ref_pad = torch.zeros((N, Z, P, Q, k_pad), dtype=torch.float32)
            ref_pad[..., :K] = ref_unquant_cpu
            amax = (
                ref_pad.reshape(N, Z, P, Q, sf_k, sfd_vec_size).abs().amax(dim=5)
            )  # (N, Z, P, Q, sf_k)
            pvscale = amax * norm_const_host / m_d
            if sfd_dtype is cutlass.Float8E8M0FNU:
                # E8M0 SFD (MXFP8) rounds toward +inf to the next power of two,
                # matching the device cvt.rp.ue8m0; a plain round-to-nearest cast
                # would disagree by up to one exponent step. exp2/log2 run on CPU
                # (the CUDA path goes through nvrtc jiterator). E8M0 has no zero;
                # its smallest value is 2^-127, which cvt.rp of 0.0 also yields.
                sfd_ref = torch.exp2(
                    torch.ceil(torch.log2(pvscale)).clamp(-127.0, 127.0)
                )
            else:
                # E4M3 SFD (NVFP4) has a mantissa; round-to-nearest is exact enough.
                sfd_ref = pvscale.to(sfd_torch_dtype).to(torch.float32)
            acc_scale = (norm_const_host / sfd_ref.clamp(min=1e-30)).clamp(max=fp32_max)
            d_scaled = (
                ref_unquant_cpu
                * acc_scale.unsqueeze(-1)
                .expand(N, Z, P, Q, sf_k, sfd_vec_size)
                .reshape(N, Z, P, Q, k_pad)[..., :K]
            )

            # 2. Quantize the rescaled reference through d_dtype (f32 -> FP4 ->
            #    f32) via the same convert path the kernel output went through.
            d_ref_narrow_ = torch.empty(
                (N, Z, P, Q, K), dtype=ref_quant_storage_dtype, device="cuda"
            )
            d_ref_narrow = from_dlpack(
                d_ref_narrow_, assumed_align=16
            ).mark_layout_dynamic(leading_dim=4)
            d_ref_narrow.element_type = d_dtype
            d_scaled_dev = d_scaled.contiguous().cuda()
            d_scaled_tensor = from_dlpack(
                d_scaled_dev, assumed_align=16
            ).mark_layout_dynamic(leading_dim=4)
            cute.testing.convert(d_scaled_tensor, d_ref_narrow)
            cute.testing.convert(d_ref_narrow, d_scaled_tensor)
            d_ref_quant = d_scaled_dev

            # 3. Decode the kernel-written SFD (plain (NZPQ, sf_k_padded, 1)
            #    layout) to f32 in the same (N, Z, P, Q, sf_k) shape as sfd_ref,
            #    reinterpreting the raw bytes through the actual SFD dtype.
            sfd_cpu = sfd_storage.cpu()
            sfd_bytes_view = sfd_cpu.view(torch.uint8)
            sfd_kernel = (
                sfd_bytes_view[:, :sf_k, :]
                .view(sfd_torch_dtype)
                .float()
                .squeeze(-1)
                .reshape(N, Z, P, Q, sf_k)
            )
            n_nonzero = (sfd_bytes_view[:, :sf_k, :] != 0).sum().item()
            assert n_nonzero > 0, "SFD is all zero -- kernel did not write SFD"

            # Compare SFD first: the output rescale depends on it, so an SFD
            # mismatch is the more fundamental signal.
            torch.testing.assert_close(sfd_kernel, sfd_ref, atol=1e-01, rtol=1e-01)
            torch.testing.assert_close(
                d_ref_result, d_ref_quant, atol=1e-01, rtol=1e-01
            )
            print("SFD dequant refcheck passed.")
        else:
            torch.testing.assert_close(
                d_ref_result,
                ref_quantized,
                atol=tolerance,
                rtol=1e-02,
            )
            print("✓ Results match within tolerance!")

    # Benchmark if requested
    if iterations > 0:
        print(
            f"\nBenchmarking with {warmup_iterations} warmup and {iterations} iterations..."
        )

        def generate_tensors():
            input_tensor, filter_tensor, output_tensor = prepare_fprop_tensors(
                ncdhw, ktrs, (Z, P, Q), ab_dtype
            )
            input_, input_storage = create_cute_tensor(
                input_tensor, ab_dtype, leading_dim=4
            )
            filter_, filter_storage = create_cute_tensor(
                filter_tensor, ab_dtype, leading_dim=4
            )
            output_, output_storage = create_cute_tensor(
                output_tensor, d_dtype, leading_dim=4
            )
            # SFA and SFB scale every A and B element the mainloop reads, so they
            # rotate alongside them and their bytes count toward one workspace.
            _, ws_sfa_, _ = create_scale_factor_tensor_unswizzled(
                1,
                N * D * H * W,
                C,
                sf_vec_size,
                sf_dtype,
            )
            _, ws_sfb_, _ = create_scale_factor_tensor_swizzled(
                1,
                K,
                sfb_c_span * T * R * S,
                sf_vec_size,
                sf_dtype,
            )
            if use_bias:
                ws_bias_storage = torch.randn(K, dtype=torch.float32, device="cuda").to(
                    cutlass_torch.dtype(bias_dtype)
                )
                ws_bias_ = from_dlpack(
                    ws_bias_storage, assumed_align=16
                ).mark_layout_dynamic(leading_dim=0)
            else:
                ws_bias_ = None
            if beta != 0.0:
                ws_c_, _ = create_cute_tensor(
                    torch.randn((N, Z, P, Q, K), dtype=torch.float32, device="cuda"),
                    c_dtype,
                    leading_dim=4,
                )
            else:
                ws_c_ = None
            # The workspace initializes on other streams; drain them so the
            # benchmark stream never reads a tensor mid-initialization.
            torch.cuda.synchronize()
            # Arg order must match the compiled entry exactly (activation and beta are
            # Constexpr, folded in at cute.compile time, so NOT runtime args): a, b,
            # sfa, sfb, d, sfd, bias, c, alpha, norm_const, the 12 pad/stride/dil
            # Int32, then stream. Every tensor rotates per cold-L2 workspace, so each
            # is rebuilt here and counts toward the workspace bytes below.
            return testing.JitArguments(
                input_,
                filter_,
                ws_sfa_,
                ws_sfb_,
                output_,
                sfd_,
                ws_bias_,
                ws_c_,
                alpha_,
                norm_const_,
                *rt_conv_scalars(
                    upper_pad=upper_pad_dhw,
                    lower_pad=lower_pad_dhw,
                    stride=stride_dhw,
                    dil=dil_dhw,
                ),
                current_stream,
            )

        workspace_count = 1
        if use_cold_l2:
            one_workspace_bytes = (
                input_storage.numel() * input_storage.element_size()
                + filter_storage.numel() * filter_storage.element_size()
                + output_storage.numel() * output_storage.element_size()
                + sfa_storage.numel() * sfa_storage.element_size()
                + sfb_storage.numel() * sfb_storage.element_size()
            )
            # beta*residual is output-sized, so it counts toward the bytes of each
            # cold-L2 workspace; bias is a small K vector but counted for symmetry.
            if bias_storage is not None:
                one_workspace_bytes += (
                    bias_storage.numel() * bias_storage.element_size()
                )
            if c_storage is not None:
                one_workspace_bytes += c_storage.numel() * c_storage.element_size()
            workspace_count = testing.get_workspace_count(
                one_workspace_bytes, warmup_iterations, iterations
            )

        # exec_time is in microseconds
        exec_time = testing.benchmark(
            compiled_fn,
            workspace_generator=generate_tensors,
            workspace_count=workspace_count,
            stream=current_stream,
            warmup_iterations=warmup_iterations,
            iterations=iterations,
            use_cuda_graphs=True,
        )
        runtime_s = exec_time / 1.0e6
        fmas = (N * Z * P * Q) * K * (C * T * R * S)
        flop = 2 * fmas
        gflop = flop / 1.0e9
        gflops = gflop / runtime_s

        print("Average Runtime : ", exec_time / 1000, "ms")
        print("GFLOPS          : ", gflops)

        return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Blackwell 3D convolution")

    # Convolution parameters
    parser.add_argument(
        "--ncdhw",
        type=parse_comma_separated_ints,
        default=(1, 128, 32, 32, 32),
        help="Input tensor shape (N,C,D,H,W)",
    )
    parser.add_argument(
        "--ktrs",
        type=parse_comma_separated_ints,
        default=(256, 3, 3, 3),
        help="Filter tensor shape components (K,T,R,S)",
    )
    parser.add_argument(
        "--stride_dhw",
        type=parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Stride (Sd,Sh,Sw)",
    )
    parser.add_argument(
        "--upper_pad_dhw",
        type=parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Upper padding (PadD,PadH,PadW)",
    )
    parser.add_argument(
        "--lower_pad_dhw",
        type=parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Lower padding (PadD,PadH,PadW)",
    )
    parser.add_argument(
        "--dil_dhw",
        type=parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Dilation (DilD,DilH,DilW)",
    )

    # Data type parameters
    parser.add_argument(
        "--ab_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.Float4E2M1FN,
            cutlass.Float8E4M3FN,
        ],
        default=cutlass.Float4E2M1FN,
        help="Data type for A/B input tensors",
    )
    parser.add_argument(
        "--d_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.Float4E2M1FN,
            cutlass.Float8E4M3FN,
            cutlass.Float16,
            cutlass.BFloat16,
        ],
        default=cutlass.Float4E2M1FN,
        help="Output D data type. The block-scaled narrow output is the one paired "
        "with --ab_dtype: FP4 D with NVFP4 A/B, FP8 E4M3 D with MXFP8 A/B. SFD is "
        "generated only when width <= 8.",
    )
    parser.add_argument(
        "--c_dtype",
        type=cutlass.dtype,
        default=None,
        help="Residual (C) input data type. Defaults to --d_dtype; must equal "
        "it since C is staged in smem laid out like D's.",
    )
    parser.add_argument(
        "--acc_dtype",
        type=cutlass.dtype,
        choices=[cutlass.Float32],
        default=cutlass.Float32,
        help="Accumulator data type. The block-scaled MMA accumulates in FP32.",
    )
    parser.add_argument(
        "--sf_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.Float8E4M3FN,
            cutlass.Float8E8M0FNU,
        ],
        default=cutlass.Float8E4M3FN,
        help="Data type for A/B/D scaling factor tensors (NVFP4 default: E4M3)",
    )
    parser.add_argument("--sf_vec_size", type=int, choices=[16, 32], default=16)
    parser.add_argument(
        "--cta_tile_k",
        type=int,
        default=None,
        help="Compile-time K tile. The legal widths follow --ab_dtype: NVFP4 A/B "
        "takes 64, 128 or 256, MXFP8 A/B takes 64 or 128. Left unset, MXFP8 takes "
        "128 and NVFP4 the widest legal width at or below C, clamped into "
        "[64, 256].",
    )

    # Kernel parameters
    parser.add_argument(
        "--mma_tiler_mn",
        type=parse_comma_separated_ints,
        default=(128, 128),
        help="MMA tiler shape (M,N)",
    )
    parser.add_argument(
        "--preferred_cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(2, 1),
        help="Preferred cluster shape (M,N) for CLC dynamic scheduling",
    )
    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(2, 1),
        help="Fallback cluster shape (M,N) for CLC dynamic scheduling",
    )
    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Enable 2CTA MMA instructions",
    )
    parser.add_argument(
        "--swizzle_size",
        type=int,
        default=1,
        help="Swizzling size in the unit of cluster for improving L2 cache hit rate",
    )
    parser.add_argument(
        "--raster_order",
        type=str,
        choices=["m", "n"],
        default="m",
        help="Rasterization order of clusters",
    )
    # Testing parameters
    parser.add_argument(
        "--tolerance",
        type=float,
        default=1e-01,
        help="Tolerance for result comparison",
    )
    parser.add_argument(
        "--warmup_iterations",
        type=int,
        default=0,
        help="Number of warmup iterations",
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=0,
        help="Number of benchmark iterations",
    )
    parser.add_argument(
        "--skip_ref_check",
        action="store_true",
        help="Skip reference checking",
    )
    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )
    parser.add_argument(
        "--use_bias",
        action="store_true",
        default=False,
        help="Add a per-output-channel bias (D = alpha*acc + bias)",
    )
    parser.add_argument(
        "--bias_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
        ],
        default=None,
        help="Bias element type. Left unset it is derived from the output type, "
        "which has a 16-bit floor.",
    )
    parser.add_argument(
        "--alpha",
        type=float,
        default=1.0,
        help="Per-tensor accumulator scale (D = alpha*acc + bias + "
        "beta*residual), applied before the SFD quantize. Runtime scalar: one "
        "cubin serves any value",
    )
    parser.add_argument(
        "--beta",
        type=float,
        default=0.0,
        help="Residual scaling (D = alpha*acc + bias + beta*residual); "
        "beta != 0 enables the residual path, beta == 0 disables it",
    )
    parser.add_argument(
        "--activation",
        type=str,
        default="identity",
        choices=sorted(EPILOGUE_ACTIVATIONS),
        help="Compile-time epilogue activation applied as "
        "D = activation(alpha*acc + bias + beta*residual). One activation per "
        "cubin (folded in as a Constexpr). Non-identity is unsupported for FP4 "
        "output.",
    )
    args = parser.parse_args()

    if len(args.ncdhw) != 5:
        parser.error("--ncdhw must contain exactly 5 values (N,C,D,H,W)")
    if len(args.ktrs) != 4:
        parser.error("--ktrs must contain exactly 4 values (K,T,R,S)")
    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values (M,N)")

    run(
        args.ncdhw,
        args.ktrs,
        args.stride_dhw,
        args.upper_pad_dhw,
        args.lower_pad_dhw,
        args.dil_dhw,
        args.ab_dtype,
        args.d_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.sf_dtype,
        args.sf_vec_size,
        args.cta_tile_k,
        args.mma_tiler_mn,
        args.preferred_cluster_shape_mn,
        args.fallback_cluster_shape_mn,
        args.swizzle_size,
        args.raster_order,
        args.use_2cta_instrs,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.skip_ref_check,
        args.use_bias,
        args.bias_dtype,
        args.alpha,
        args.beta,
        args.activation,
    )
    print("PASS")
