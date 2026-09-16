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

"""
This example implements the SM107 grouped block-scaled GEMM kernel with MXFP6 data types.

It combines the features in two existing examples:

* the ptr-array grouped machinery of ``grouped_blockscaled_gemm.py`` -- a persistent kernel over
  a batch of GEMMs with distinct problem sizes, whose A/B/SFA/SFB/C tensormaps live in an array
  in GMEM and are rewritten per group (``TensorMapUpdateMode.SMEM``); and
* the MXFP6 execution protocol of ``dense_blockscaled_mxfp6_gemm_persistent.py`` -- an 8 K-tile
  circular buffer, B-keep/B-reuse MMA sequencing, split A/B and SFA/SFB load pipelines, and 
  byte-denominated TMA for the packed 6-bit operands.

This GEMM works as follows.  Seven warps are specialized; each runs a persistent loop over the work
tiles handed out by the group tile scheduler, and each rewrites the tensormaps it owns whenever the
scheduler moves it on to a new group:
1. DMA warp for the FP6 operand(s) (warp 5):
    - Rewrite their tensormaps to the new group's base address, sizes and strides.
    - Load them from GMEM to SMEM using TMA, as 3x 128B buffers.
2. DMA warp for SFA/SFB and the FP4/FP8 operand, if any (warp 6):
    - Rewrite the tensormaps it owns for the new group.
    - Load them from GMEM to SMEM using TMA, as 4 buffers per k-tile.
3. MMA warp (warp 4):
    - Load scale factor SFA/SFB from shared memory (SMEM) to tensor memory (TMEM).
    - Perform matrix multiply-accumulate (MMA) operations using tcgen05.mma instruction 8x per
      k-tile, issued with circular-buffer operands so one MMA can straddle two A/B buffers.
4. EPILOGUE warps (warps 0-3):
    - Rewrite the C tensormap for the new group.
    - Load completed accumulator from tensor memory (TMEM) to registers (RMEM).
    - Type convert C matrix to output type.
    - Stores C matrix from registers (RMEM) to shared memory (SMEM) to global memory (GMEM) with TMA operations.

To run this example:

.. code-block:: bash

    python grouped_blockscaled_mxfp6_gemm.py                                                   \
      --a_dtype Float6E2M3FN --b_dtype Float6E3M2FN --sf_dtype Float8E8M0FNU --sf_vec_size 32  \
      --c_dtype Float32 --a_major k --b_major k --c_major n                                    \
      --mma_tiler 128,128,512 --mma_inst_shape 128,128,64 --cluster_shape_mn 2,2               \
      --problem_sizes_mnkl "(512,256,256,1),(256,512,256,1),(512,256,768,1)" --num_groups 3

Constraints:
* Operands may be FP6 (Float6E3M2FN, Float6E2M3FN), FP8 (Float8E4M3FN, Float8E5M2) or
  FP4 (Float4E2M1FN); at least one of A and B must be FP6
* Scale factors must be Float8E8M0FNU with sf_vec_size == 32
* A and B must be K-major; C must be N-major
* Mma tiler K must be 512 and MMA instruction shape K must be 64 (8 MMAs per k-tile)
* Mma tiler M must be inst_M or 2 * inst_M (2x enables B-reuse); inst_M is 128 (.1CTA) or 256 (.2CTA)
* Mma tiler N must equal MMA instruction shape N, which must be 128 or 256
* Cluster shape M/N must be positive powers of 2, total cluster size <= 16, each <= 4
* Cluster shape M must be a multiple of 2 if MMA instruction shape M is 256 (.2CTA)
* Every group's operands must be aligned to one MMA K-extent in the contiguous dim:
  48 bytes for FP6, 32 for FP4, 16 for FP8 (all satisfied by K % 64 == 0)
* The l mode (batch size) for each group must be 1
* The majorness for A, B and C must be the same across all groups
"""

import argparse
import functools
import os
import sys
from typing import List, Literal, Tuple, Type, Union

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute as cute
import cutlass.pipeline as pipeline
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
import cutlass.utils.rubin_helpers as sm107_utils
from cutlass import testing
from cutlass.cute.nvgpu import cpasync, tcgen05
from cutlass.cute.nvgpu.tcgen05.mma import CollectorOp
from cutlass.cute.runtime import from_dlpack
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait

if __name__ == "__main__":
    # ../../.. = cute/ (rubin, blackwell packages); ../../../.. = CuTeDSL/ (helpers).
    _here = os.path.dirname(os.path.abspath(__file__))
    for _d in ("../../..", "../../../.."):
        sys.path.insert(0, os.path.normpath(os.path.join(_here, _d)))

from rubin.kernel.blockscaled_gemm.dense_blockscaled_gemm_persistent import (  # noqa: E402
    Sm107BlockScaledPersistentDenseGemmKernel,
)
from rubin.kernel.blockscaled_gemm.dense_blockscaled_mxfp6_gemm_persistent import (  # noqa: E402
    Sm107Mxfp6BlockScaledPersistentDenseGemmKernel,
    _Mxfp6KTileCtx,
    _is_fp4,
    _is_fp6,
)
from rubin.kernel.blockscaled_grouped_gemm.grouped_blockscaled_gemm import (  # noqa: E402
    Sm107GroupedBlockScaledGemmKernel,
)

from blackwell.kernel.blockscaled_grouped_gemm.grouped_blockscaled_gemm import (  # noqa: E402
    create_tensor_and_stride,
    create_tensors_abc_for_all_groups,
    create_tensors_sfasfb_for_all_groups,
)


class Sm107Mxfp6GroupedBlockScaledGemmKernel(Sm107GroupedBlockScaledGemmKernel):
    """Grouped (ptr-array) block-scaled GEMM for SM107 with MXFP6 operands.
    :note: Supported combinations of A/B data types, SF data type and SF vector size:
        - FP6xFP6, FP8xFP6, FP6xFP8, FP4xFP6, FP6xFP4, all + Float8E8M0FNU + 32
          (at least one operand must be FP6)
    """

    # Reuse layout constructors from dense gemm.
    make_smem_layout_a = staticmethod(
        Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.make_smem_layout_a
    )
    make_smem_layout_b = staticmethod(
        Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.make_smem_layout_b
    )
    adapt_layout_for_tma_ab = staticmethod(
        Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.adapt_layout_for_tma_ab
    )
    adapt_layout_for_tma_sf = staticmethod(
        Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.adapt_layout_for_tma_sf
    )
    append_coalesce_layout = staticmethod(
        Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.append_coalesce_layout
    )

    # k-tile geometry hard-coded by the `_Mxfp6KTileCtx` 8-phase schedule: 8 MMAs per
    # k-tile. An FP6 operand needs 3 buffers of 128 B; an FP4/FP8 operand (and SF) needs
    # 4. Per-operand byte sizes are dtype-dependent and derived in `_setup_attributes`.
    fp6_buffers_per_tile_k = 3
    fp8_buffers_per_tile_k = 4
    fp4_buffers_per_tile_k = 4

    def __init__(
        self,
        sf_vec_size: int,
        mma_inst_shape: Tuple[int, int, int],
        mma_tiler: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        use_cached_problem_shapes: bool = True,
    ):
        """Initialize the static configuration of the grouped MXFP6 kernel.

        The signature is the grouped parent's verbatim, so ``run()`` and the tests can
        construct either kernel interchangeably.

        :param sf_vec_size: Scale factor vector size (must be 32 for MXFP6).
        :type sf_vec_size: int
        :param mma_inst_shape: Shape (M, N, K) of the MMA instruction; K must be 64.
        :type mma_inst_shape: Tuple[int, int, int]
        :param mma_tiler: Shape (M, N, K) of the MMA tile; K must be 512.
        :type mma_tiler: Tuple[int, int, int]
        :param cluster_shape_mn: Cluster dimensions (M, N).
        :type cluster_shape_mn: Tuple[int, int]
        :param use_cached_problem_shapes: Enable double-buffered caching of problem shapes.
        :type use_cached_problem_shapes: bool
        """
        super().__init__(
            sf_vec_size,
            mma_inst_shape,
            mma_tiler,
            cluster_shape_mn,
            use_cached_problem_shapes,
        )

        # MXFP6 splits the single TMA warp of the grouped parent in two so the producer
        # pipelines drain independently (3 A/B buffers vs 4 SF buffers per k-tile). Warp 6
        # is the parent's `scheduler_warp_id`, allocated but never read, so this costs no
        # extra threads.
        self.tma_ab_warp_id = self.tma_warp_id
        self.tma_sf_warp_id = self.scheduler_warp_id
        assert self.threads_per_cta == 32 * 7, (
            f"grouped MXFP6 expects 7 warps (4 epilogue + mma + tma_ab + tma_sf), "
            f"parent allocated {self.threads_per_cta} threads"
        )

        # A/B tensormap init is cooperative across 3 warps; ids 1-3 are taken in the grouped chain.
        self.tensormap_ab_init_barrier = pipeline.NamedBarrier(
            barrier_id=3,
            num_threads=32 * 3,
        )

        self.fp8_subtile_k = mma_tiler[2] // self.fp8_buffers_per_tile_k

        # MXFP6 does not support TMA descriptor prefetch of the packed operands.
        self.prefetch_enabled = False

        assert not hasattr(self, "mxf8f6f4"), (
            "mxf8f6f4 must never be set on the grouped MXFP6 kernel;"
        )

    def _setup_attributes(self):
        """Set up configurations that are dependent on GEMM inputs."""
        # Number of MMAs covered by one fp8-pipe buffer (8 MMAs / 4 buffers = 2).
        num_mma_per_tile_k = self.mma_tiler[2] // self.mma_inst_shape[2]
        self.num_mma_per_fp8_buffer = num_mma_per_tile_k // self.fp8_buffers_per_tile_k

        # Per-operand k-tile geometry, mirroring the dense kernel. FP4 keeps the FP8
        # stage count so data and SF advance in lock-step, with half-size buffers.
        self.a_buffers_per_tile_k = (
            self.fp6_buffers_per_tile_k
            if cutlass.const_expr(_is_fp6(self.a_dtype))
            else self.fp4_buffers_per_tile_k
            if cutlass.const_expr(_is_fp4(self.a_dtype))
            else self.fp8_buffers_per_tile_k
        )
        self.b_buffers_per_tile_k = (
            self.fp6_buffers_per_tile_k
            if cutlass.const_expr(_is_fp6(self.b_dtype))
            else self.fp4_buffers_per_tile_k
            if cutlass.const_expr(_is_fp4(self.b_dtype))
            else self.fp8_buffers_per_tile_k
        )
        # FP4: 8 x (64 x 4/8) = 256 B; FP6: 384 B; FP8: 512 B per k-tile.
        self.a_num_bytes_per_tile_k = (
            num_mma_per_tile_k * self.mma_inst_shape[2] * self.a_dtype.width // 8
        )
        self.b_num_bytes_per_tile_k = (
            num_mma_per_tile_k * self.mma_inst_shape[2] * self.b_dtype.width // 8
        )
        # Per-buffer byte size: FP4 64 B; FP6 and FP8 128 B.
        self.a_bytes_per_buffer = (
            self.a_num_bytes_per_tile_k // self.a_buffers_per_tile_k
        )
        self.b_bytes_per_buffer = (
            self.b_num_bytes_per_tile_k // self.b_buffers_per_tile_k
        )

        # Compute mma instruction shapes
        # (CTA_Tile_Shape_M, Round_Up(MMA_Tile_Shape_N, 128), MMA_Inst_Shape_K)
        self.mma_inst_shape_sfb = (
            self.mma_inst_shape[0] // (2 if self.use_2cta_instrs else 1),
            cute.round_up(self.mma_inst_shape[1], 128),
            self.mma_inst_shape[2],
        )

        tiled_mma = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
            atom_layout_mnk=(1, 1, 1),
            permutation_mnk=self._get_mma_permutation_mnk(),
        )

        tiled_mma_sfb = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_sfb,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
        )

        # Compute mma/cluster/tile shapes
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )
        self.cluster_tile_shape_mnk = tuple(
            x * y for x, y in zip(self.cta_tile_shape_mnk, (*self.cluster_shape_mn, 1))
        )

        # SF tilers are cut at the SF subtile in K (128), NOT at mma_tiler[2] (512).
        self.mma_tiler_sfa = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            self.fp8_subtile_k,
        )
        self.mma_tiler_sfb = (
            self.mma_inst_shape_sfb[0],
            self.mma_inst_shape_sfb[1],
            self.fp8_subtile_k,
        )

        # Compute cluster layout
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        self.cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma_sfb.thr_id.shape,),
        )

        # Compute number of multicast CTAs for A/B
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.num_mcast_ctas_sfb = cute.size(self.cluster_layout_sfb_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1
        self.is_sfb_mcast = self.num_mcast_ctas_sfb > 1

        # Compute epilogue subtile
        self.epi_tile = sm107_utils.compute_epilogue_tile_shape(
            tiled_mma.op,
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.c_layout,
            self.c_dtype,
        )

        self.num_acc_stage, num_load_stage, self.num_c_stage = (
            Sm107Mxfp6BlockScaledPersistentDenseGemmKernel._compute_stages(
                tiled_mma=tiled_mma,
                mma_tiler_mnk=self.mma_tiler,
                mma_tiler_sfa=self.mma_tiler_sfa,
                mma_tiler_sfb=self.mma_tiler_sfb,
                epi_tile=self.epi_tile,
                c_dtype=self.c_dtype,
                c_layout=self.c_layout,
                sf_dtype=self.sf_dtype,
                sf_vec_size=self.sf_vec_size,
                smem_capacity=self.smem_capacity,
                occupancy=self.occupancy,
                with_breuse=self.enable_breuse,
                a_dtype=self.a_dtype,
                b_dtype=self.b_dtype,
            )
        )
        mbar_budget_bytes = (
            self.reserved_smem_bytes
            - Sm107Mxfp6GroupedBlockScaledGemmKernel.bytes_per_tensormap
            * Sm107Mxfp6GroupedBlockScaledGemmKernel.num_tensormaps
            - Sm107Mxfp6GroupedBlockScaledGemmKernel.tensor_memory_management_bytes
        )
        max_load_stage = (mbar_budget_bytes - 16 * self.num_acc_stage) // 32
        if num_load_stage > max_load_stage:
            print(
                f"[DSL INFO] clamping load stages {num_load_stage} -> {max_load_stage} "
                f"to fit the {mbar_budget_bytes} byte mbarrier budget"
            )
            num_load_stage = max_load_stage

        # For simplicity, the fp6 and fp8 pipelines carry the same number of stages.
        self.num_ab_stage = num_load_stage
        self.num_sf_stage = num_load_stage

        min_load_stage = max(
            self.a_buffers_per_tile_k,
            self.b_buffers_per_tile_k,
        )
        if num_load_stage < min_load_stage:
            raise ValueError(
                f"grouped MXFP6 needs at least {min_load_stage} load stages to cover "
                f"one k-tile, computed {num_load_stage}"
            )

        print(
            f"[DSL INFO] stages: acc={self.num_acc_stage}, ab={self.num_ab_stage}, "
            f"sf={self.num_sf_stage}, c (epi)={self.num_c_stage}"
        )

        # Compute A/B/SFA/SFB/C shared memory layouts.
        # ((CTA_MMA_M, k_sub_bytes), 1, k_sub_count, num_ab_stage)
        self.a_smem_layout_staged = self.make_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.num_ab_stage,
            self.a_dtype,
        )
        # The TMA box spans one k-tile: a_buffers_per_tile_k buffers.
        self.a_smem_layout_staged_tma = self.make_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.a_buffers_per_tile_k,
            self.a_dtype,
        )
        # ((CTA_MMA_N, k_sub_bytes), 1, k_sub_count, num_ab_stage)
        self.b_smem_layout_staged = self.make_smem_layout_b(
            tiled_mma,
            self.mma_tiler,
            self.num_ab_stage,
            self.b_dtype,
        )
        self.b_smem_layout_staged_tma = self.make_smem_layout_b(
            tiled_mma,
            self.mma_tiler,
            self.b_buffers_per_tile_k,
            self.b_dtype,
        )
        self.sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            self.mma_tiler_sfa,
            self.sf_vec_size,
            self.num_sf_stage,
        )
        self.sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            self.mma_tiler_sfb,
            self.sf_vec_size,
            self.num_sf_stage,
        )
        self.c_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            self.c_dtype,
            self.c_layout,
            self.epi_tile,
            self.num_c_stage,
        )

        # Shares `mbar_budget_bytes` with the clamp above, so the two cannot drift.
        mbar_smem_bytes = self._get_mbar_smem_bytes(
            num_acc_stage=self.num_acc_stage,
            num_ab_stage=self.num_ab_stage,
            num_sf_stage=self.num_sf_stage,
        )
        if mbar_smem_bytes > mbar_budget_bytes:
            raise ValueError(
                f"mbarrier smem consumption {mbar_smem_bytes} exceeds the "
                f"{mbar_budget_bytes} bytes left for mbarriers after the "
                f"{Sm107Mxfp6GroupedBlockScaledGemmKernel.num_tensormaps} tensormaps "
                f"and tensor memory management are taken out of the "
                f"{self.reserved_smem_bytes} reserved bytes"
            )

        # (MMA, MMA_M, MMA_K) / (MMA, MMA_N, MMA_K)
        self.tCtSFA_layout = blockscaled_utils.make_tmem_layout_sfa(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            cute.select(
                self.sfa_smem_layout_staged,
                mode=list(range(cute.rank(self.sfa_smem_layout_staged) - 1)),
            ),
        )
        self.tCtSFB_layout = blockscaled_utils.make_tmem_layout_sfb(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            cute.select(
                self.sfb_smem_layout_staged,
                mode=list(range(cute.rank(self.sfb_smem_layout_staged) - 1)),
            ),
        )

        self.num_sfa_tmem_cols = (
            cute.cosize(cute.recast_layout(32, self.sf_dtype.width, self.tCtSFA_layout))
            & 0x0000FFFF
        )
        self.num_sfb_tmem_cols = (
            cute.cosize(cute.recast_layout(32, self.sf_dtype.width, self.tCtSFB_layout))
            & 0x0000FFFF
        )
        self.num_sf_tmem_cols = self.num_sfa_tmem_cols + self.num_sfb_tmem_cols
        self.num_accumulator_tmem_cols = (
            self.cta_tile_shape_mnk[1]
            * self.num_acc_stage
            * (2 if self.enable_breuse else 1)
        )

    @cute.jit
    def __call__(
        self,
        initial_a: cute.Tensor,
        initial_b: cute.Tensor,
        initial_c: cute.Tensor,
        initial_sfa: cute.Tensor,
        initial_sfb: cute.Tensor,
        group_count: cutlass.Constexpr[int],
        problem_shape_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        tensor_address_abc: cute.Tensor,
        tensor_address_sfasfb: cute.Tensor,
        total_num_clusters: cutlass.Constexpr[int],
        tensormap_cute_tensor: cute.Tensor,
        max_active_clusters: cutlass.Constexpr[int],
        stream: cuda.CUstream,
    ):
        """Execute the grouped MXFP6 GEMM.

        Signature is the grouped parent's verbatim; ``initial_*`` carry only dtype and
        majorness information, everything else comes from the per-group GMEM arrays.

        The A/B TMA atoms are the reason this method exists as a full override rather
        than a call to ``super()``: they are built with the low-level
        ``cpasync.make_tiled_tma_atom`` over a ``Uint8`` recast of the FP6 tensor so the
        box can be expressed in BYTES (M_cta, 384). ``make_tiled_tma_atom_A/B`` derive
        the box from ``mma_tiler`` and cannot express that.
        """
        self.a_dtype = initial_a.element_type
        self.b_dtype = initial_b.element_type
        self.sf_dtype = initial_sfa.element_type
        self.c_dtype = initial_c.element_type
        self.a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            initial_a
        ).mma_major_mode()
        self.b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            initial_b
        ).mma_major_mode()
        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(initial_c)

        # Setup attributes that depend on gemm inputs
        self._setup_attributes()

        # Setup sfa/sfb tensors by filling the A/B shapes into the SF atom layout.
        # ((Atom_M, Rest_M),(Atom_K, Rest_K),RestL)
        sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(
            initial_a.shape, self.sf_vec_size
        )
        initial_sfa = cute.make_tensor(initial_sfa.iterator, sfa_layout)
        # ((Atom_N, Rest_N),(Atom_K, Rest_K),RestL)
        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
            initial_b.shape, self.sf_vec_size
        )
        initial_sfb = cute.make_tensor(initial_sfb.iterator, sfb_layout)

        atom_layout_mnk = (1, 1, 1)
        permutation_mnk = self._get_mma_permutation_mnk()

        tiled_mma = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
            atom_layout_mnk=atom_layout_mnk,
            permutation_mnk=permutation_mnk,
        )
        tiled_mma.set(tcgen05.Field.NEGATE_A, False)
        tiled_mma.set(tcgen05.Field.NEGATE_B, False)

        # For 2CTA blockscaled kernels, SFB needs to be replicated across peer CTAs.
        tiled_mma_sfb = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_sfb,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
        )
        tiled_mma_sfb.set(tcgen05.Field.NEGATE_A, False)
        tiled_mma_sfb.set(tcgen05.Field.NEGATE_B, False)

        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

        # Setup TMA load for A.
        #
        # Recast to Uint8 FIRST. Passing an un-recast FP6 tensor sets `use_unpack` and
        # bakes the U6_UNPACK_U8 format -- the Blackwell unpacked regime, not this one.
        a_op = sm100_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        a_smem_layout_tma_ready = self.adapt_layout_for_tma_ab(
            self.a_smem_layout_staged_tma
        )
        initial_a_uint8 = cute.recast_tensor(initial_a, cutlass.Uint8)
        tma_atom_a, tma_tensor_a = cpasync.make_tiled_tma_atom(
            a_op,
            initial_a_uint8,
            a_smem_layout_tma_ready,
            (
                self.mma_tiler[0] // (2 if self.use_2cta_instrs else 1),
                self.a_num_bytes_per_tile_k,
            ),
            self.cluster_shape_mn[1],
            internal_type=cutlass.Uint8,
        )

        # Setup TMA load for B
        b_op = sm100_utils.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        b_smem_layout_tma_ready = self.adapt_layout_for_tma_ab(
            self.b_smem_layout_staged_tma
        )
        initial_b_uint8 = cute.recast_tensor(initial_b, cutlass.Uint8)
        tma_atom_b, tma_tensor_b = cpasync.make_tiled_tma_atom(
            b_op,
            initial_b_uint8,
            b_smem_layout_tma_ready,
            (
                self.mma_tiler[1] // (2 if self.use_2cta_instrs else 1),
                self.b_num_bytes_per_tile_k,
            ),
            self.cluster_shape_mn[0] // cute.size(tiled_mma.thr_id.shape),
            internal_type=cutlass.Uint8,
        )

        # Setup TMA load for SFA. Scale factors are 8-bit and stay element-denominated;
        # the box K is the SF subtile (128), not the full k-tile.
        sfa_op = sm100_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfa_smem_layout = cute.slice_(
            self.sfa_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfa, tma_tensor_sfa = cpasync.make_tiled_tma_atom(
            sfa_op,
            initial_sfa,
            self.adapt_layout_for_tma_sf(sfa_smem_layout),
            (
                self.mma_tiler[0] // (2 if self.use_2cta_instrs else 1),
                self.fp8_subtile_k,
            ),
            self.cluster_shape_mn[1],
            internal_type=cutlass.Int16,
        )

        # Setup TMA load for SFB. The parent's N == 192 layout patch is dead here (N is 128 or 256).
        sfb_op = sm100_utils.cluster_shape_to_tma_atom_SFB(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfb_smem_layout = cute.slice_(
            self.sfb_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfb, tma_tensor_sfb = cpasync.make_tiled_tma_atom(
            sfb_op,
            initial_sfb,
            self.adapt_layout_for_tma_sf(sfb_smem_layout),
            (self.mma_tiler_sfb[1], self.mma_tiler_sfb[2]),
            self.cluster_shape_mn[0],
            internal_type=cutlass.Int16,
        )

        epi_smem_layout = cute.select(
            self.c_smem_layout_staged,
            mode=list(range(cute.rank(self.c_smem_layout_staged) - 1)),
        )
        tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(),
            initial_c,
            epi_smem_layout,
            self.epi_tile,
        )

        # Transaction-byte counts, split per producer pipeline.
        a_copy_size = cute.size_in_bytes(
            cutlass.Uint8,
            cute.select(
                self.a_smem_layout_staged_tma,
                mode=list(range(cute.rank(self.a_smem_layout_staged_tma) - 1)),
            ),
        )
        b_copy_size = cute.size_in_bytes(
            cutlass.Uint8,
            cute.select(
                self.b_smem_layout_staged_tma,
                mode=list(range(cute.rank(self.b_smem_layout_staged_tma) - 1)),
            ),
        )
        sfa_copy_size = cute.size_in_bytes(
            self.sf_dtype,
            cute.select(
                self.sfa_smem_layout_staged,
                mode=list(range(cute.rank(self.sfa_smem_layout_staged) - 1)),
            ),
        )
        sfb_copy_size = cute.size_in_bytes(
            self.sf_dtype,
            cute.select(
                self.sfb_smem_layout_staged,
                mode=list(range(cute.rank(self.sfb_smem_layout_staged) - 1)),
            ),
        )
        # fp6-pipe tx: A+B data (both FP6) | FP6-operand data only (mixed)
        # fp8-pipe tx: SFA+SFB (both FP6) | FP4/FP8-operand data + SFA+SFB (mixed)
        a_is_fp6 = _is_fp6(self.a_dtype)
        b_is_fp6 = _is_fp6(self.b_dtype)
        sf_copy_size = sfa_copy_size + sfb_copy_size
        if cutlass.const_expr(a_is_fp6 and b_is_fp6):
            self.num_tma_load_bytes_ab = (a_copy_size + b_copy_size) * atom_thr_size
            self.num_tma_load_bytes_sf = sf_copy_size * atom_thr_size
        elif cutlass.const_expr(not a_is_fp6):  # A=FP4/FP8, B=FP6
            self.num_tma_load_bytes_ab = b_copy_size * atom_thr_size
            self.num_tma_load_bytes_sf = (a_copy_size + sf_copy_size) * atom_thr_size
        else:  # A=FP6, B=FP4/FP8
            self.num_tma_load_bytes_ab = a_copy_size * atom_thr_size
            self.num_tma_load_bytes_sf = (b_copy_size + sf_copy_size) * atom_thr_size

        # Compute grid size
        self.tile_sched_params, grid = self._compute_grid(
            total_num_clusters, self.cluster_shape_mn, max_active_clusters
        )

        self.buffer_align_bytes = 1024
        self.size_tensormap_in_i64 = (
            Sm107Mxfp6GroupedBlockScaledGemmKernel.num_tensormaps
            * Sm107Mxfp6GroupedBlockScaledGemmKernel.bytes_per_tensormap
            // 8
        )

        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            tensormap_buffer: cute.struct.MemRange[
                cutlass.Int64, self.size_tensormap_in_i64
            ]
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            ab_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            sf_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_sf_stage]
            sf_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_sf_stage]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32
            # (EPI_TILE_M, EPI_TILE_N, STAGE)
            #
            # C lives in the struct, as in the grouped parent. Allocating it from the
            # SmemAllocator too would double-count the budget `_compute_stages` reserved.
            sC: cute.struct.Align[
                cute.struct.MemRange[
                    self.c_dtype,
                    cute.cosize(self.c_smem_layout_staged.outer),
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            #
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    cutlass.Uint8, cute.cosize(self.a_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    cutlass.Uint8, cute.cosize(self.b_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            sSFA: cute.struct.Align[
                cute.struct.MemRange[
                    self.sf_dtype, cute.cosize(self.sfa_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sSFB: cute.struct.Align[
                cute.struct.MemRange[
                    self.sf_dtype, cute.cosize(self.sfb_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        # Launch the kernel synchronously
        self.kernel(
            tiled_mma,
            tiled_mma_sfb,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_sfa,
            tma_tensor_sfa,
            tma_atom_sfb,
            tma_tensor_sfb,
            tma_atom_c,
            tma_tensor_c,
            self.cluster_layout_vmnk,
            self.cluster_layout_sfb_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.tCtSFA_layout,
            self.tCtSFB_layout,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            group_count,
            problem_shape_mnkl,
            strides_abc,
            tensor_address_abc,
            tensor_address_sfasfb,
            tensormap_cute_tensor,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
            min_blocks_per_mp=1,
        )
        return

    #
    # GPU device kernel implementation.
    #
    @cute.jit
    def kernel_impl(
        self,
        tiled_mma: cute.TiledMma,
        tiled_mma_sfb: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_sfa: cute.CopyAtom,
        mSFA_mkl: cute.Tensor,
        tma_atom_sfb: cute.CopyAtom,
        mSFB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        cluster_layout_sfb_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        tCtSFA_layout: cute.Layout,
        tCtSFB_layout: cute.Layout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        group_count: cutlass.Constexpr,
        problem_sizes_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        ptrs_abc: cute.Tensor,
        ptrs_sfasfb: cute.Tensor,
        tensormaps: cute.Tensor,
        cluster_shape_mn: Tuple[int, int],
        is_a_mcast: bool,
        is_b_mcast: bool,
    ):
        """GPU device kernel implementation performing the grouped MXFP6 GEMM.

        Seven warps, one more producer warp than the grouped parent:

        * warps 0-3 (``epilog_warp_id``) -- epilogue.
        * warp 4 (``mma_warp_id``) -- initialises ALL FOUR A/B/SFA/SFB tensormaps, then
          runs the 8-phase circular-buffer MMA schedule of the dense MXFP6 kernel.
        * warp 5 (``tma_ab_warp_id``) -- fp6 pipe: per-group tensormap update + fence
          and TMA loads for the FP6 operand(s) only, ``fp6_buffers_per_tile_k`` (3)
          buffers of 128 bytes each per k-tile.
        * warp 6 (``tma_sf_warp_id``) -- fp8 pipe: per-group tensormap update + fence
          and TMA loads for SFA/SFB plus the FP4/FP8 operand if there is one,
          ``fp8_buffers_per_tile_k`` (4) buffers per k-tile.

        Each producer warp updates only the descriptors it later uses and passes its own
        id: ``TensorMapManager.update_tensormap`` self-guards on ``warp_idx == warp_id``
        (``cutlass/tensor_utils/tensormap.py:159``), so any other id is a silent no-op.
        """
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        #
        # Prefetch tma descriptors. This grouping is inherited and no longer matches the
        # load split, which is now by dtype rather than A/B versus SF. Harmless: every
        # TMA copy below overrides tma_desc_ptr with the per-CTA workspace descriptor,
        # so the atoms' own descriptors are never the ones consumed.
        #
        if warp_idx == self.tma_ab_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            cpasync.prefetch_descriptor(tma_atom_c)
        if warp_idx == self.tma_sf_warp_id:
            cpasync.prefetch_descriptor(tma_atom_sfa)
            cpasync.prefetch_descriptor(tma_atom_sfb)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

        #
        # Setup cta/thread coordinates
        #
        bidx, bidy, bidz = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        block_in_cluster_coord_sfb_vmnk = cluster_layout_sfb_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        # Coord inside cta
        tidx, _, _ = cute.arch.thread_idx()

        #
        # Alloc and init: tensormap buffer, A/B and SF full/empty, accumulator
        # full/empty, tensor memory dealloc barrier
        #
        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # The five tensormap SMEM slots are offsets from `tensormap_buffer.data_ptr()`, so
        # that field must stay first in the struct.
        tensormap_i64_per_map = (
            Sm107Mxfp6GroupedBlockScaledGemmKernel.bytes_per_tensormap // 8
        )
        tensormap_a_smem_ptr = storage.tensormap_buffer.data_ptr()
        tensormap_b_smem_ptr = tensormap_a_smem_ptr + tensormap_i64_per_map
        tensormap_sfa_smem_ptr = tensormap_b_smem_ptr + tensormap_i64_per_map
        tensormap_sfb_smem_ptr = tensormap_sfa_smem_ptr + tensormap_i64_per_map
        tensormap_c_smem_ptr = tensormap_sfb_smem_ptr + tensormap_i64_per_map

        tmem_dealloc_mbar_ptr = storage.tmem_dealloc_mbar.ptr
        tmem_holding_buf = storage.tmem_holding_buf.ptr

        # A/B load pipeline. `defer_sync=True` defers the fence and cluster arrive to the
        # single `pipeline_init_arrive` below, fencing all four objects exactly once.
        ab_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        ab_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        ab_pipeline = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_producer_group,
            consumer_group=ab_consumer_group,
            tx_count=self.num_tma_load_bytes_ab,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        )
        # The MMA warp keeps the consumer ENDPOINT: `_Mxfp6KTileCtx` (owned by the dense
        # MXFP6 kernel) holds three AB stage handles at once and reads `.index` off them,
        # which the raw pipeline+state form cannot express without a snapshot shim.
        ab_consumer = ab_pipeline.make_consumer()

        # SF load pipeline: separate from A/B, 4 buffers per k-tile against 3, different warp.
        sf_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        sf_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        sf_pipeline = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.sf_full_mbar_ptr.data_ptr(),
            num_stages=self.num_sf_stage,
            producer_group=sf_producer_group,
            consumer_group=sf_consumer_group,
            tx_count=self.num_tma_load_bytes_sf,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        )
        sf_consumer = sf_pipeline.make_consumer()

        # Accumulator pipeline (MMA warp -> epilogue warps)
        acc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_acc_consumer_threads = len(self.epilog_warp_id) * (
            2 if use_2cta_instrs else 1
        )
        acc_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_acc_consumer_threads
        )
        acc_pipeline = pipeline.PipelineUmmaAsync.create(
            barrier_storage=storage.acc_full_mbar_ptr.data_ptr(),
            num_stages=self.num_acc_stage,
            producer_group=acc_pipeline_producer_group,
            consumer_group=acc_pipeline_consumer_group,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )

        # Tensor memory dealloc barrier init
        if use_2cta_instrs:
            if warp_idx == self.tma_ab_warp_id:
                num_tmem_dealloc_threads = 32
                with cute.arch.elect_one():
                    cute.arch.mbarrier_init(
                        tmem_dealloc_mbar_ptr, num_tmem_dealloc_threads
                    )

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=cluster_shape_mn, is_relaxed=True)

        #
        # Setup smem tensor A/B/SFA/SFB/C
        #
        # sA/sB are byte-denominated Uint8 MemRanges.
        #
        # (EPI_TILE_M, EPI_TILE_N, STAGE)
        sC = storage.sC.get_tensor(
            c_smem_layout_staged.outer, swizzle=c_smem_layout_staged.inner
        )
        # ((CTA_MMA_M, 16), 1, 8, STAGE)
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        # ((CTA_MMA_N, 16), 1, 8, STAGE)
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
        sfa_full_mcast_mask = None
        sfb_full_mcast_mask = None
        if cutlass.const_expr(is_a_mcast or is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )
            sfa_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            sfb_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_sfb_vmnk, block_in_cluster_coord_sfb_vmnk, mcast_mode=1
            )

        #
        # Local_tile partition global tensors
        #
        # mA_mkl/mB_nkl are byte-denominated, and the per-k-tile byte count is
        # dtype-dependent (FP4 256 B, FP6 384 B, FP8 512 B), so A and B get own tilers.
        a_tiler_bytes = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            self.a_num_bytes_per_tile_k,
        )
        b_tiler_bytes = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            self.b_num_bytes_per_tile_k,
        )
        # (BLK_M, BLK_K_BYTES, m, k, l)
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(a_tiler_bytes, (None, 0, None)), (None, None, None)
        )
        # (BLK_N, BLK_K_BYTES, n, k, l)
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(b_tiler_bytes, (0, None, None)), (None, None, None)
        )
        # Scale factors are 8-bit and stay element-denominated, but they are tiled at
        # the SF subtile (128) because one SF buffer covers a quarter of a k-tile.
        sf_tiler = (self.mma_tiler[0], self.mma_tiler[1], self.fp8_subtile_k)
        # (BLK_M, SF_SUBTILE_K, m, k, l)
        gSFA_mkl = cute.local_tile(
            mSFA_mkl, cute.slice_(sf_tiler, (None, 0, None)), (None, None, None)
        )
        # (BLK_N, SF_SUBTILE_K, n, k, l)
        gSFB_nkl = cute.local_tile(
            mSFB_nkl,
            cute.slice_(self.mma_tiler_sfb, (0, None, None)),
            (None, None, None),
        )
        # (bM, bN, RestM, RestN, RestL)
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )

        #
        # Partition global tensor for TiledMMA_A/B/C
        #
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        thr_mma_sfb = tiled_mma_sfb.get_slice(mma_tile_coord_v)

        # A/B are re-tiled a second time, into the 128-byte A/B buffers the circular
        # buffer protocol loads one at a time: ((M_cta, 128), RestM, RestK=3, m, k, l).
        tCgA_mkl_tmp = thr_mma.partition_A(gA_mkl)
        cta_tCgA = cute.make_tensor(
            tCgA_mkl_tmp.iterator, self.append_coalesce_layout(tCgA_mkl_tmp.layout)
        )
        tCgA = cute.make_tensor(
            cta_tCgA.iterator,
            cute.tiled_divide(
                cta_tCgA.layout,
                (
                    self.mma_tiler[0] // (2 if self.use_2cta_instrs else 1),
                    self.a_bytes_per_buffer,
                ),
            ),
        )

        tCgB_nkl_tmp = thr_mma.partition_B(gB_nkl)
        cta_tCgB = cute.make_tensor(
            tCgB_nkl_tmp.iterator, self.append_coalesce_layout(tCgB_nkl_tmp.layout)
        )
        tCgB = cute.make_tensor(
            cta_tCgB.iterator,
            cute.tiled_divide(
                cta_tCgB.layout,
                (
                    self.mma_tiler[1] // (2 if self.use_2cta_instrs else 1),
                    self.b_bytes_per_buffer,
                ),
            ),
        )

        # (MMA, MMA_M, MMA_K, m, k, l)
        tCgSFA = thr_mma.partition_A(gSFA_mkl)
        # (MMA, MMA_N, MMA_K, n, k, l)
        tCgSFB = thr_mma_sfb.partition_B(gSFB_nkl)
        # (MMA, MMA_M, MMA_N, RestM, RestN, RestL)
        tCgC = thr_mma.partition_C(gC_mnl)

        #
        # Partition global/shared tensor for TMA load A/B
        #
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestM, RestK, m, k, l)
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA, 0, 3),
            cute.group_modes(tCgA, 0, 1),
        )
        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestN, RestK, n, k, l)
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB, 0, 3),
            cute.group_modes(tCgB, 0, 1),
        )

        # TMA load SFA partition_S/D
        sfa_cta_layout = a_cta_layout
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), m, k, l)
        tAsSFA, tAgSFA = cpasync.tma_partition(
            tma_atom_sfa,
            block_in_cluster_coord_vmnk[2],
            sfa_cta_layout,
            cute.group_modes(sSFA, 0, 3),
            cute.group_modes(tCgSFA, 0, 3),
        )
        tAsSFA_compact = cute.filter_zeros(tAsSFA)

        # TMA load SFB partition_S/D; the parent's N == 64 special case is unreachable here.
        sfb_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_sfb_vmnk, (0, None, 0, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), n, k, l)
        tBsSFB, tBgSFB = cpasync.tma_partition(
            tma_atom_sfb,
            block_in_cluster_coord_sfb_vmnk[1],
            sfb_cta_layout,
            cute.group_modes(sSFB, 0, 3),
            cute.group_modes(tCgSFB, 0, 3),
        )
        tBsSFB_compact = cute.filter_zeros(tBsSFB)

        #
        # Partition tensor memory tensor for TiledMMA_C
        #
        # A/B never become MMA fragments: the 8-phase schedule builds SMEM descriptors
        # straight from sA/sB, so there is no `make_fragment_A/B` here.
        #
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        # (MMA, MMA_M, MMA_N, STAGE)
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        #
        # Cluster wait before tensor memory alloc
        #
        pipeline_init_wait(cluster_shape_mn=cluster_shape_mn)

        #
        # Get tensormap buffer address
        #
        grid_dim = cute.arch.grid_dim()
        tensormap_workspace_idx = (
            bidz * grid_dim[1] * grid_dim[0] + bidy * grid_dim[0] + bidx
        )

        tensormap_manager = cutlass.tensor_utils.TensorMapManager(
            cutlass.tensor_utils.TensorMapUpdateMode.SMEM,
            Sm107Mxfp6GroupedBlockScaledGemmKernel.bytes_per_tensormap,
        )
        tensormap_a_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 0, None)].iterator
        )
        tensormap_b_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 1, None)].iterator
        )
        tensormap_sfa_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 2, None)].iterator
        )
        tensormap_sfb_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 3, None)].iterator
        )
        tensormap_c_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 4, None)].iterator
        )

        # Trace-time constants. `update_tensormap` is a silent no-op off its own warp,
        # so each operand's descriptor is updated by the warp that loads it: the FP6
        # operand(s) by the fp6 warp, the FP4/FP8 operand by the fp8 warp.
        a_is_fp6 = _is_fp6(self.a_dtype)
        b_is_fp6 = _is_fp6(self.b_dtype)

        #
        # Persistent tile scheduling loop
        #
        tile_sched = utils.StaticPersistentGroupTileScheduler.create(
            tile_sched_params,
            cute.arch.block_idx(),
            grid_dim,
            self.cluster_tile_shape_mnk,
            utils.create_initial_search_state(),
            group_count,
            problem_sizes_mnkl,
            use_cached_problem_shapes=self.use_cached_problem_shapes,
        )
        # Prefetch the problem shapes into caches
        tile_sched.prefetch_problem_shapes()
        # Get the initial tile information
        initial_work_tile_info = tile_sched.initial_work_tile_info()

        #
        # Specialized TMA load warp for A/B
        #
        if warp_idx == self.tma_ab_warp_id and initial_work_tile_info.is_valid_tile:
            work_tile = initial_work_tile_info

            ab_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_ab_stage
            )

            tensormap_init_done = cutlass.Boolean(False)
            # group index of last tile
            last_group_idx = cutlass.Int32(-1)

            while work_tile.is_valid_tile:
                grouped_gemm_cta_tile_info = work_tile.group_search_result
                cur_k_tile_cnt = grouped_gemm_cta_tile_info.cta_tile_count_k
                cur_group_idx = grouped_gemm_cta_tile_info.group_idx
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0

                if not is_k_tile_cnt_zero:
                    is_group_changed = cur_group_idx != last_group_idx
                    # skip tensormap update if we're working on the same group
                    if is_group_changed:
                        problem_shape_mnk = (
                            grouped_gemm_cta_tile_info.problem_shape_m,
                            grouped_gemm_cta_tile_info.problem_shape_n,
                            grouped_gemm_cta_tile_info.problem_shape_k,
                        )
                        # Only the FP6 operand(s) belong to this warp. Accumulate rather
                        # than loop: a comprehension in this staged block defeats the
                        # DSL's control-flow rewrite of `if is_group_changed`.
                        real_tensors = ()
                        tma_atoms = ()
                        gmem_ptrs = ()
                        smem_ptrs = ()
                        if cutlass.const_expr(a_is_fp6):
                            real_tensors += (
                                self.make_tensor_abc_for_tensormap_update(
                                    cur_group_idx,
                                    self.a_dtype,
                                    problem_shape_mnk,
                                    strides_abc,
                                    ptrs_abc,
                                    0,  # 0 for tensor A
                                ),
                            )
                            tma_atoms += (tma_atom_a,)
                            gmem_ptrs += (tensormap_a_gmem_ptr,)
                            smem_ptrs += (tensormap_a_smem_ptr,)
                        if cutlass.const_expr(b_is_fp6):
                            real_tensors += (
                                self.make_tensor_abc_for_tensormap_update(
                                    cur_group_idx,
                                    self.b_dtype,
                                    problem_shape_mnk,
                                    strides_abc,
                                    ptrs_abc,
                                    1,  # 1 for tensor B
                                ),
                            )
                            tma_atoms += (tma_atom_b,)
                            gmem_ptrs += (tensormap_b_gmem_ptr,)
                            smem_ptrs += (tensormap_b_smem_ptr,)

                        if not tensormap_init_done:
                            # wait tensormap initialization complete
                            self.tensormap_ab_init_barrier.arrive_and_wait()
                            tensormap_init_done = True

                        tensormap_manager.update_tensormap(
                            real_tensors,
                            tma_atoms,
                            gmem_ptrs,
                            # Must be THIS warp's id, or the update is a silent no-op.
                            self.tma_ab_warp_id,
                            smem_ptrs,
                        )

                    mma_tile_coord_mnl = (
                        grouped_gemm_cta_tile_info.cta_tile_idx_m
                        // cute.size(tiled_mma.thr_id.shape),
                        grouped_gemm_cta_tile_info.cta_tile_idx_n,
                        0,
                    )

                    #
                    # Slice to per mma tile index
                    #
                    # ((atom_v, rest_v), RestM, RestK, k)
                    tAgA_slice = (
                        tAgA[
                            (
                                None,
                                None,
                                None,
                                mma_tile_coord_mnl[0],
                                None,
                                mma_tile_coord_mnl[2],
                            )
                        ]
                        if cutlass.const_expr(a_is_fp6)
                        else None
                    )
                    # ((atom_v, rest_v), RestN, RestK, k)
                    tBgB_slice = (
                        tBgB[
                            (
                                None,
                                None,
                                None,
                                mma_tile_coord_mnl[1],
                                None,
                                mma_tile_coord_mnl[2],
                            )
                        ]
                        if cutlass.const_expr(b_is_fp6)
                        else None
                    )

                    ab_producer_state.reset_count()
                    peek_ab_empty_status = cutlass.Boolean(1)
                    peek_ab_empty_status = ab_pipeline.producer_try_acquire(
                        ab_producer_state
                    )

                    if is_group_changed:
                        if cutlass.const_expr(a_is_fp6):
                            tensormap_manager.fence_tensormap_update(
                                tensormap_a_gmem_ptr
                            )
                        if cutlass.const_expr(b_is_fp6):
                            tensormap_manager.fence_tensormap_update(
                                tensormap_b_gmem_ptr
                            )

                    #
                    # Tma load loop -- fp6_buffers_per_tile_k 128-byte buffers/k-tile
                    #
                    for k_tile in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                        for buffer in cutlass.range(
                            self.fp6_buffers_per_tile_k, unroll_full=True
                        ):
                            # Acquire next empty fp6-pipe buffer
                            ab_pipeline.producer_acquire(
                                ab_producer_state, peek_ab_empty_status
                            )

                            if cutlass.const_expr(a_is_fp6):
                                cute.copy(
                                    tma_atom_a,
                                    cute.group_modes(
                                        tAgA_slice[(None, None, buffer, k_tile)], 0, 2
                                    ),
                                    tAsA[(None, ab_producer_state.index)],
                                    tma_bar_ptr=ab_pipeline.producer_get_barrier(
                                        ab_producer_state
                                    ),
                                    mcast_mask=a_full_mcast_mask,
                                    tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                        tensormap_a_gmem_ptr,
                                        cutlass.AddressSpace.generic,
                                    ),
                                )
                            if cutlass.const_expr(b_is_fp6):
                                cute.copy(
                                    tma_atom_b,
                                    cute.group_modes(
                                        tBgB_slice[(None, None, buffer, k_tile)], 0, 2
                                    ),
                                    tBsB[(None, ab_producer_state.index)],
                                    tma_bar_ptr=ab_pipeline.producer_get_barrier(
                                        ab_producer_state
                                    ),
                                    mcast_mask=b_full_mcast_mask,
                                    tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                        tensormap_b_gmem_ptr,
                                        cutlass.AddressSpace.generic,
                                    ),
                                )

                            # Peek (try_wait) fp6 buffer empty for the next buffer,
                            # unless this was the last buffer of the last k-tile.
                            ab_producer_state.advance()
                            peek_ab_empty_status = cutlass.Boolean(1)
                            if not (
                                (k_tile == cur_k_tile_cnt - 1)
                                and (buffer == self.fp6_buffers_per_tile_k - 1)
                            ):
                                peek_ab_empty_status = ab_pipeline.producer_try_acquire(
                                    ab_producer_state
                                )
                else:
                    # Degenerate group: no loads, but this warp still owes its arrival on the init
                    # barrier.
                    if not tensormap_init_done:
                        self.tensormap_ab_init_barrier.arrive_and_wait()
                        tensormap_init_done = True

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                last_group_idx = cur_group_idx

            #
            # Wait A/B buffer empty
            #
            ab_pipeline.producer_tail(ab_producer_state)

        #
        # Specialized TMA load warp for the scale factors
        #
        if warp_idx == self.tma_sf_warp_id and initial_work_tile_info.is_valid_tile:
            work_tile = initial_work_tile_info

            sf_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_sf_stage
            )

            tensormap_init_done = cutlass.Boolean(False)
            last_group_idx = cutlass.Int32(-1)

            while work_tile.is_valid_tile:
                grouped_gemm_cta_tile_info = work_tile.group_search_result
                cur_k_tile_cnt = grouped_gemm_cta_tile_info.cta_tile_count_k
                cur_group_idx = grouped_gemm_cta_tile_info.group_idx
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0
                if not is_k_tile_cnt_zero:
                    is_group_changed = cur_group_idx != last_group_idx
                    if is_group_changed:
                        problem_shape_mnk = (
                            grouped_gemm_cta_tile_info.problem_shape_m,
                            grouped_gemm_cta_tile_info.problem_shape_n,
                            grouped_gemm_cta_tile_info.problem_shape_k,
                        )
                        real_tensor_sfa = self.make_tensor_sfasfb_for_tensormap_update(
                            cur_group_idx,
                            self.sf_dtype,
                            problem_shape_mnk,
                            ptrs_sfasfb,
                            0,  # 0 for tensor SFA
                        )
                        real_tensor_sfb = self.make_tensor_sfasfb_for_tensormap_update(
                            cur_group_idx,
                            self.sf_dtype,
                            problem_shape_mnk,
                            ptrs_sfasfb,
                            1,  # 1 for tensor SFB
                        )
                        # SF always rides this pipe; the FP4/FP8 operand joins it, so
                        # its descriptor is updated here, not in the fp6 warp.
                        real_tensors = (real_tensor_sfa, real_tensor_sfb)
                        tma_atoms = (tma_atom_sfa, tma_atom_sfb)
                        gmem_ptrs = (tensormap_sfa_gmem_ptr, tensormap_sfb_gmem_ptr)
                        smem_ptrs = (tensormap_sfa_smem_ptr, tensormap_sfb_smem_ptr)
                        if cutlass.const_expr(not a_is_fp6):
                            real_tensors += (
                                self.make_tensor_abc_for_tensormap_update(
                                    cur_group_idx,
                                    self.a_dtype,
                                    problem_shape_mnk,
                                    strides_abc,
                                    ptrs_abc,
                                    0,  # 0 for tensor A
                                ),
                            )
                            tma_atoms += (tma_atom_a,)
                            gmem_ptrs += (tensormap_a_gmem_ptr,)
                            smem_ptrs += (tensormap_a_smem_ptr,)
                        if cutlass.const_expr(not b_is_fp6):
                            real_tensors += (
                                self.make_tensor_abc_for_tensormap_update(
                                    cur_group_idx,
                                    self.b_dtype,
                                    problem_shape_mnk,
                                    strides_abc,
                                    ptrs_abc,
                                    1,  # 1 for tensor B
                                ),
                            )
                            tma_atoms += (tma_atom_b,)
                            gmem_ptrs += (tensormap_b_gmem_ptr,)
                            smem_ptrs += (tensormap_b_smem_ptr,)

                        if not tensormap_init_done:
                            self.tensormap_ab_init_barrier.arrive_and_wait()
                            tensormap_init_done = True

                        tensormap_manager.update_tensormap(
                            real_tensors,
                            tma_atoms,
                            gmem_ptrs,
                            self.tma_sf_warp_id,
                            smem_ptrs,
                        )

                    mma_tile_coord_mnl = (
                        grouped_gemm_cta_tile_info.cta_tile_idx_m
                        // cute.size(tiled_mma.thr_id.shape),
                        grouped_gemm_cta_tile_info.cta_tile_idx_n,
                        0,
                    )

                    #
                    # Slice to per mma tile index
                    #
                    # ((atom_v, rest_v), k)
                    tAgSFA_slice = tAgSFA[
                        (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                    ]
                    # ((atom_v, rest_v), k)
                    tBgSFB_slice = tBgSFB[
                        (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                    ]
                    # The FP4/FP8 operand, if any, rides this pipe alongside the SFs.
                    tAgA_slice = (
                        tAgA[
                            (
                                None,
                                None,
                                None,
                                mma_tile_coord_mnl[0],
                                None,
                                mma_tile_coord_mnl[2],
                            )
                        ]
                        if cutlass.const_expr(not a_is_fp6)
                        else None
                    )
                    tBgB_slice = (
                        tBgB[
                            (
                                None,
                                None,
                                None,
                                mma_tile_coord_mnl[1],
                                None,
                                mma_tile_coord_mnl[2],
                            )
                        ]
                        if cutlass.const_expr(not b_is_fp6)
                        else None
                    )

                    # Same indivisible reset + peek + loop unit as the fp6 warp, with
                    # 4 arrivals per k-tile instead of 3.
                    sf_producer_state.reset_count()
                    peek_sf_empty_status = cutlass.Boolean(1)
                    peek_sf_empty_status = sf_pipeline.producer_try_acquire(
                        sf_producer_state
                    )

                    if is_group_changed:
                        tensormap_manager.fence_tensormap_update(tensormap_sfa_gmem_ptr)
                        tensormap_manager.fence_tensormap_update(tensormap_sfb_gmem_ptr)
                        if cutlass.const_expr(not a_is_fp6):
                            tensormap_manager.fence_tensormap_update(
                                tensormap_a_gmem_ptr
                            )
                        if cutlass.const_expr(not b_is_fp6):
                            tensormap_manager.fence_tensormap_update(
                                tensormap_b_gmem_ptr
                            )

                    #
                    # Tma load loop -- 4 fp8-pipe buffers per k-tile
                    #
                    for k_tile in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                        for sf_stage in cutlass.range(
                            self.fp8_buffers_per_tile_k, unroll_full=True
                        ):
                            sf_pipeline.producer_acquire(
                                sf_producer_state, peek_sf_empty_status
                            )

                            # FP4/FP8-operand data (emitted only when not FP6)
                            if cutlass.const_expr(not a_is_fp6):
                                cute.copy(
                                    tma_atom_a,
                                    cute.group_modes(
                                        tAgA_slice[(None, None, sf_stage, k_tile)], 0, 2
                                    ),
                                    tAsA[(None, sf_producer_state.index)],
                                    tma_bar_ptr=sf_pipeline.producer_get_barrier(
                                        sf_producer_state
                                    ),
                                    mcast_mask=a_full_mcast_mask,
                                    tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                        tensormap_a_gmem_ptr,
                                        cutlass.AddressSpace.generic,
                                    ),
                                )
                            if cutlass.const_expr(not b_is_fp6):
                                cute.copy(
                                    tma_atom_b,
                                    cute.group_modes(
                                        tBgB_slice[(None, None, sf_stage, k_tile)], 0, 2
                                    ),
                                    tBsB[(None, sf_producer_state.index)],
                                    tma_bar_ptr=sf_pipeline.producer_get_barrier(
                                        sf_producer_state
                                    ),
                                    mcast_mask=b_full_mcast_mask,
                                    tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                        tensormap_b_gmem_ptr,
                                        cutlass.AddressSpace.generic,
                                    ),
                                )

                            # Each SF subtile maps to 2 mmas, 4 subtiles in total.
                            sf_subtile_idx = (
                                k_tile * self.fp8_buffers_per_tile_k + sf_stage
                            )
                            tAgSFA_compact = cute.filter_zeros(
                                tAgSFA_slice[(None, sf_subtile_idx)]
                            )
                            tBgSFB_compact = cute.filter_zeros(
                                tBgSFB_slice[(None, sf_subtile_idx)]
                            )

                            cute.copy(
                                tma_atom_sfa,
                                tAgSFA_compact,
                                tAsSFA_compact[(None, sf_producer_state.index)],
                                tma_bar_ptr=sf_pipeline.producer_get_barrier(
                                    sf_producer_state
                                ),
                                mcast_mask=sfa_full_mcast_mask,
                                tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                    tensormap_sfa_gmem_ptr,
                                    cutlass.AddressSpace.generic,
                                ),
                            )
                            cute.copy(
                                tma_atom_sfb,
                                tBgSFB_compact,
                                tBsSFB_compact[(None, sf_producer_state.index)],
                                tma_bar_ptr=sf_pipeline.producer_get_barrier(
                                    sf_producer_state
                                ),
                                mcast_mask=sfb_full_mcast_mask,
                                tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                    tensormap_sfb_gmem_ptr,
                                    cutlass.AddressSpace.generic,
                                ),
                            )

                            sf_producer_state.advance()
                            peek_sf_empty_status = cutlass.Boolean(1)
                            if not (
                                (k_tile == cur_k_tile_cnt - 1)
                                and (sf_stage == self.fp8_buffers_per_tile_k - 1)
                            ):
                                peek_sf_empty_status = sf_pipeline.producer_try_acquire(
                                    sf_producer_state
                                )
                else:
                    if not tensormap_init_done:
                        self.tensormap_ab_init_barrier.arrive_and_wait()
                        tensormap_init_done = True

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                last_group_idx = cur_group_idx

            #
            # Wait SF buffer empty
            #
            sf_pipeline.producer_tail(sf_producer_state)

        #
        # Specialized MMA warp
        #
        if warp_idx == self.mma_warp_id and initial_work_tile_info.is_valid_tile:
            #
            # Initialize tensormaps for A, B, SFA and SFB
            #
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_a, tensormap_a_smem_ptr, self.mma_warp_id
            )
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_b, tensormap_b_smem_ptr, self.mma_warp_id
            )
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_sfa, tensormap_sfa_smem_ptr, self.mma_warp_id
            )
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_sfb, tensormap_sfb_smem_ptr, self.mma_warp_id
            )
            # indicate tensormap initialization has finished
            self.tensormap_ab_init_barrier.arrive_and_wait()

            #
            # Bar sync for retrieve tensor memory ptr from shared mem
            #
            self.tmem_alloc_barrier.arrive_and_wait()

            #
            # Retrieving tensor memory ptr and make accumulator/SFA/SFB tensor
            #
            acc_tmem_ptr = cute.arch.retrieve_tmem_ptr(
                self.acc_dtype,
                alignment=16,
                ptr_to_buffer_holding_addr=tmem_holding_buf,
            )
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            # SFA/SFB live immediately after the accumulator columns.
            sfa_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr + self.num_accumulator_tmem_cols,
                dtype=self.sf_dtype,
            )
            sfb_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr + self.num_accumulator_tmem_cols + self.num_sfa_tmem_cols,
                dtype=self.sf_dtype,
            )
            tCtSFA = cute.make_tensor(sfa_tmem_ptr, tCtSFA_layout)
            tCtSFB = cute.make_tensor(sfb_tmem_ptr, tCtSFB_layout)

            #
            # Partition for S2T copy of SFA/SFB
            #
            # Pinned: the unprefixed spelling resolves through this class's MRO to the
            # Blackwell impl, which drops the Rubin-only `tcgen05.append_s2t_broadcast_mode`.
            sfa_s2t_bundle = (
                Sm107GroupedBlockScaledGemmKernel._mainloop_s2t_copy_and_partition(
                    self, sSFA, tCtSFA
                )
            )
            sfb_s2t_bundle = (
                Sm107GroupedBlockScaledGemmKernel._mainloop_s2t_copy_and_partition(
                    self, sSFB, tCtSFB
                )
            )

            #
            # Persistent tile scheduling loop
            #
            work_tile = initial_work_tile_info

            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )

            while work_tile.is_valid_tile:
                grouped_gemm_cta_tile_info = work_tile.group_search_result
                cur_k_tile_cnt = grouped_gemm_cta_tile_info.cta_tile_count_k
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0

                if not is_k_tile_cnt_zero:
                    # (MMA, MMA_M, MMA_N)
                    tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]

                    # Same indivisible reset + peek + loop as the producers: AB advances 3 per k-tile,
                    # SF 4.
                    ab_consumer.reset()
                    peek_ab_full_status = cutlass.Boolean(1)
                    if is_leader_cta:
                        peek_ab_full_status = ab_consumer.try_wait()

                    sf_consumer.reset()
                    peek_sf_full_status = cutlass.Boolean(1)
                    if is_leader_cta:
                        peek_sf_full_status = sf_consumer.try_wait()

                    is_first_iteration = True
                    accumulate = False

                    # Trace-time constant -- no runtime overhead.
                    both_fp6 = a_is_fp6 and b_is_fp6

                    for k_tile in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                        if is_leader_cta:

                            def s2t(sf_idx):
                                self._mainloop_s2t_copies(
                                    sf_idx, sfa_s2t_bundle, sfb_s2t_bundle
                                )

                            # -- fp8-pipe stage 0: SF (+ FP4/FP8 data) for MMA 0, 1 --
                            sf_full0 = sf_consumer.wait_and_advance(peek_sf_full_status)
                            s2t(sf_full0.index)
                            peek_sf_full_status = sf_consumer.try_wait()
                            # With two FP6 operands, the FP8 pipe is SF-only and releases after S2T.
                            if cutlass.const_expr(both_fp6):
                                sf_full0.release()

                            # -- fp6-pipe stage 0: FP6 data for MMA 0..2 --
                            ab_full0 = ab_consumer.wait_and_advance(peek_ab_full_status)
                            peek_ab_full_status = ab_consumer.try_wait()

                            # delay the acc acquire to unblock tmem
                            if is_first_iteration:
                                acc_pipeline.producer_acquire(acc_producer_state)
                                is_first_iteration = False

                            m_per_cta = self.mma_inst_shape[0] // (
                                2 if self.use_2cta_instrs else 1
                            )
                            # Route each operand to the pipe that loaded it.
                            a_full0 = (
                                ab_full0 if cutlass.const_expr(a_is_fp6) else sf_full0
                            )
                            b_full0 = (
                                ab_full0 if cutlass.const_expr(b_is_fp6) else sf_full0
                            )
                            tile_ctx = _Mxfp6KTileCtx(
                                self.a_dtype,
                                self.b_dtype,
                                a_full0,
                                b_full0,
                                sA=(
                                    sA
                                    if cutlass.const_expr(self.enable_breuse)
                                    else None
                                ),
                                m_per_cta=m_per_cta,
                                k_per_subtile=self.a_bytes_per_buffer,
                            )

                            def mma(idx):
                                nonlocal accumulate
                                # Not on this class's MRO, so called unbound. It derives
                                # the B-keep/B-reuse variants per MMA; those return a
                                # plain TiledMma and do not chain, so each call must
                                # start from the wrapper handed in here.
                                Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.make_desc_and_call_mma(
                                    self,
                                    tiled_mma,
                                    tCtAcc,
                                    idx,
                                    tile_ctx,
                                    sA,
                                    tCtSFA,
                                    sB,
                                    tCtSFB,
                                    tCtAcc,
                                    accumulate,
                                )
                                accumulate = True

                            mma(0)
                            mma(1)
                            # Mixed: fp8-pipe buf0 no longer needed after MMA 1
                            if cutlass.const_expr(not both_fp6):
                                sf_full0.release()

                            # -- fp8-pipe stage 1: SF (+ FP4/FP8 data) for MMA 2, 3 --
                            sf_full1 = sf_consumer.wait_and_advance(peek_sf_full_status)
                            s2t(sf_full1.index)
                            peek_sf_full_status = sf_consumer.try_wait()
                            if cutlass.const_expr(both_fp6):
                                sf_full1.release()

                            # -- fp6-pipe stage 1: FP6 data for MMA 2..5 --
                            ab_full1 = ab_consumer.wait_and_advance(peek_ab_full_status)
                            peek_ab_full_status = ab_consumer.try_wait()
                            a_full1 = (
                                ab_full1 if cutlass.const_expr(a_is_fp6) else sf_full1
                            )
                            b_full1 = (
                                ab_full1 if cutlass.const_expr(b_is_fp6) else sf_full1
                            )
                            tile_ctx.set_a_stage(1, a_full1)
                            tile_ctx.set_b_stage(1, b_full1)

                            # MMA 2: FP6 crosses buf0->buf1; FP4/FP8 uses buf1
                            mma(2)
                            ab_full0.release()

                            mma(3)
                            if cutlass.const_expr(not both_fp6):
                                sf_full1.release()

                            # -- fp8-pipe stage 2: SF (+ FP4/FP8 data) for MMA 4, 5 --
                            sf_full2 = sf_consumer.wait_and_advance(peek_sf_full_status)
                            s2t(sf_full2.index)
                            peek_sf_full_status = sf_consumer.try_wait()
                            if cutlass.const_expr(both_fp6):
                                sf_full2.release()

                            # FP4/FP8-operand stage 2 must be registered before mma(4)
                            # (_FP8_BUF_IDX[4]=2; FP6 uses _FP6_CUR_IDX[4]=1)
                            if cutlass.const_expr(not a_is_fp6):
                                tile_ctx.set_a_stage(2, sf_full2)
                            if cutlass.const_expr(not b_is_fp6):
                                tile_ctx.set_b_stage(2, sf_full2)

                            mma(4)

                            # -- fp6-pipe stage 2: FP6 data for MMA 5..7 --
                            ab_full2 = ab_consumer.wait_and_advance(peek_ab_full_status)
                            peek_ab_full_status = cutlass.Boolean(1)
                            if k_tile + 1 < cur_k_tile_cnt:
                                peek_ab_full_status = ab_consumer.try_wait()
                            # FP6-operand stage 2 registered before mma(5)
                            # (_FP6_CUR_IDX[5]=1 set; _FP6_NEXT_IDX[5]=2 needs buf2)
                            if cutlass.const_expr(a_is_fp6):
                                tile_ctx.set_a_stage(2, ab_full2)
                            if cutlass.const_expr(b_is_fp6):
                                tile_ctx.set_b_stage(2, ab_full2)

                            # MMA 5: FP6 crosses buf1->buf2; FP4/FP8 uses buf2
                            mma(5)
                            ab_full1.release()
                            if cutlass.const_expr(not both_fp6):
                                sf_full2.release()

                            # -- fp8-pipe stage 3: SF (+ FP4/FP8 data) for MMA 6, 7 --
                            sf_full3 = sf_consumer.wait_and_advance(peek_sf_full_status)
                            s2t(sf_full3.index)
                            peek_sf_full_status = cutlass.Boolean(1)
                            if k_tile + 1 < cur_k_tile_cnt:
                                peek_sf_full_status = sf_consumer.try_wait()
                            if cutlass.const_expr(both_fp6):
                                sf_full3.release()

                            # FP4/FP8-operand stage 3 (only when the operand is not FP6)
                            if cutlass.const_expr(not a_is_fp6):
                                tile_ctx.set_a_stage(3, sf_full3)
                            if cutlass.const_expr(not b_is_fp6):
                                tile_ctx.set_b_stage(3, sf_full3)

                            mma(6)
                            mma(7)
                            ab_full2.release()
                            if cutlass.const_expr(not both_fp6):
                                sf_full3.release()

                    #
                    # Async arrive accumulator buffer full
                    #
                    # Skipped for a degenerate group, matching the epilogue's own guard.
                    if is_leader_cta:
                        acc_pipeline.producer_commit(acc_producer_state)
                    acc_producer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Wait for accumulator buffer empty
            #
            acc_pipeline.producer_tail(acc_producer_state)

        #
        # Specialized epilogue warps
        #
        if warp_idx < self.mma_warp_id and initial_work_tile_info.is_valid_tile:
            # Only the C descriptor is initialised here; A/B/SFA/SFB are done by the MMA warp.
            # `init_tensormap_from_atom` self-guards on the warp id, so warps 1-3 fall through.
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_c,
                tensormap_c_smem_ptr,
                self.epilog_warp_id[0],
            )
            #
            # Alloc tensor memory buffer
            #
            if warp_idx == self.epilog_warp_id[0]:
                cute.arch.alloc_tmem(
                    self.num_tmem_alloc_cols,
                    tmem_holding_buf,
                    is_two_cta=use_2cta_instrs,
                    arch=self.arch,
                )

            #
            # Bar sync for retrieve tensor memory ptr from shared memory
            #
            # Other half of the MMA warp's rendezvous: 160 threads = MMA warp plus these
            # four. The two TMA warps do not participate.
            #
            self.tmem_alloc_barrier.arrive_and_wait()

            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            acc_tmem_ptr = cute.arch.retrieve_tmem_ptr(
                self.acc_dtype,
                alignment=16,
                ptr_to_buffer_holding_addr=tmem_holding_buf,
            )
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            # Layout transformation for tCgC
            # ((MMA_ATOM_M, MMA_ATOM_N), MMA_M, MMA_N, TILE_M, TILE_N, TILE_K)
            # -> ((MMA_ATOM_M, MMA_M), (MMA_ATOM_N, MMA_N), TILE_M, TILE_N, TILE_K)
            tCgC_new = utils.gemm.sm100.transform_partitioned_tensor_layout(tCgC)

            # Layout transformation for tCtAcc_base
            # ((MMA_ATOM_M, MMA_ATOM_N), MMA_M, MMA_N, STAGE)
            # -> ((MMA_ATOM_M, MMA_M), (MMA_ATOM_N, MMA_N), STAGE)
            tCtAcc = utils.gemm.sm100.transform_partitioned_tensor_layout(tCtAcc_base)

            #
            # Partition for epilogue
            #
            # C is the one tensor that stays element-denominated: >= 8 bits, no Uint8 recast,
            # inherited descriptor-update branch.
            #
            epi_tidx = tidx
            tiled_copy_t2r, tTR_tAcc_base, tTR_rAcc = (
                utils.gemm.sm100.epilogue_tmem_copy_and_partition(
                    self, epi_tidx, tCtAcc, tCgC_new, epi_tile, self.use_2cta_instrs
                )
            )

            tTR_rC = cute.make_rmem_tensor(tTR_rAcc.shape, self.c_dtype)
            tiled_copy_r2s, tRS_rC, tRS_sC = (
                utils.gemm.sm100.epilogue_smem_copy_and_partition(
                    self, tiled_copy_t2r, tTR_rC, epi_tidx, sC
                )
            )

            # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, RestM, RestN, RestL)
            tCgC_epi = cute.flat_divide(tCgC_new, epi_tile)
            # ((ATOM_V, REST_V), EPI_M, EPI_N)
            # ((ATOM_V, REST_V), EPI_M, EPI_N, RestM, RestN, RestL)
            bSG_sC, bSG_gC_partitioned = cpasync.tma_partition(
                tma_atom_c,
                0,
                cute.make_layout(1),
                cute.group_modes(sC, 0, 2),
                cute.group_modes(tCgC_epi, 0, 2),
            )

            #
            # Persistent tile scheduling loop
            #
            work_tile = initial_work_tile_info

            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )

            # Threads/warps participating in tma store pipeline
            c_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.epilog_warp_id),
            )
            # `PipelineTmaStore` uses TMA store commit/wait rather than mbarriers, which is why
            # `_setup_attributes` does not charge `num_c_stage` against the mbarrier budget.
            c_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.num_c_stage,
                producer_group=c_producer_group,
            )
            # group index to start searching
            last_group_idx = cutlass.Int32(-1)

            while work_tile.is_valid_tile:
                grouped_gemm_cta_tile_info = work_tile.group_search_result
                cur_group_idx = grouped_gemm_cta_tile_info.group_idx
                # Same `cta_tile_count_k` field the two TMA warps and the MMA warp read.
                cur_k_tile_cnt = grouped_gemm_cta_tile_info.cta_tile_count_k
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0
                is_group_changed = cur_group_idx != last_group_idx

                # We still need to store 0s when k_tile_cnt is 0
                if is_group_changed:
                    # construct tensor c based on real shape, stride information
                    real_tensor_c = self.make_tensor_abc_for_tensormap_update(
                        cur_group_idx,
                        self.c_dtype,
                        (
                            grouped_gemm_cta_tile_info.problem_shape_m,
                            grouped_gemm_cta_tile_info.problem_shape_n,
                            grouped_gemm_cta_tile_info.problem_shape_k,
                        ),
                        strides_abc,
                        ptrs_abc,
                        2,  # 2 for tensor C
                    )
                    tensormap_manager.update_tensormap(
                        ((real_tensor_c),),
                        ((tma_atom_c),),
                        ((tensormap_c_gmem_ptr),),
                        # Must be the calling warp's id, or `update_tensormap` is a silent no-op.
                        self.epilog_warp_id[0],
                        (tensormap_c_smem_ptr,),
                    )

                mma_tile_coord_mnl = (
                    grouped_gemm_cta_tile_info.cta_tile_idx_m
                    // cute.size(tiled_mma.thr_id.shape),
                    grouped_gemm_cta_tile_info.cta_tile_idx_n,
                    0,
                )

                #
                # Slice to per mma tile index
                #
                # ((ATOM_V, REST_V), EPI_M, EPI_N)
                bSG_gC = bSG_gC_partitioned[
                    (
                        None,
                        None,
                        None,
                        *mma_tile_coord_mnl,
                    )
                ]

                # Set tensor memory buffer for current tile
                # (T2R, T2R_M, T2R_N, EPI_M, EPI_M)
                tTR_tAcc = tTR_tAcc_base[
                    (None, None, None, None, None, acc_consumer_state.index)
                ]

                #
                # Wait for accumulator buffer full
                #
                # Mirrors the MMA warp's `producer_commit` gate. Both sides must stay
                # under the same guard or the accumulator pipeline desynchronizes.
                if not is_k_tile_cnt_zero:
                    acc_pipeline.consumer_wait(acc_consumer_state)

                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                bSG_gC = cute.group_modes(bSG_gC, 1, cute.rank(bSG_gC))

                if is_group_changed:
                    if warp_idx == self.epilog_warp_id[0]:
                        tensormap_manager.fence_tensormap_update(tensormap_c_gmem_ptr)

                #
                # Store accumulator to global memory in subtiles
                #
                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                num_prev_subtiles = tile_sched.num_tiles_executed * subtile_cnt
                for subtile_idx in range(subtile_cnt):
                    if not is_k_tile_cnt_zero:
                        #
                        # Load accumulator from tensor memory buffer to register
                        #
                        tTR_tAcc_mn = tTR_tAcc[(None, None, None, subtile_idx)]
                        cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)

                        #
                        # Convert to C type
                        #
                        acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
                        tRS_rC.store(acc_vec.to(self.c_dtype))
                    else:
                        # A degenerate group ran no MMA, so C is written as zeros. The parent's sub-byte
                        # fill path is not ported: C is always >= 16 bits here.
                        tRS_rC.fill(0)

                    #
                    # Store C to shared memory
                    #
                    c_buffer = (num_prev_subtiles + subtile_idx) % self.num_c_stage
                    cute.copy(
                        tiled_copy_r2s,
                        tRS_rC,
                        tRS_sC[(None, None, None, c_buffer)],
                    )
                    # Fence and barrier to make sure shared memory store is visible to TMA store
                    cute.arch.fence_proxy(
                        "async.shared",
                        space="cta",
                    )
                    self.epilog_sync_barrier.arrive_and_wait()

                    #
                    # TMA store C to global memory
                    #
                    if warp_idx == self.epilog_warp_id[0]:
                        cute.copy(
                            tma_atom_c,
                            bSG_sC[(None, c_buffer)],
                            bSG_gC[(None, subtile_idx)],
                            tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                tensormap_c_gmem_ptr,
                                cutlass.AddressSpace.generic,
                            ),
                        )
                        # Fence and barrier to make sure shared memory store is visible to TMA store
                        c_pipeline.producer_commit()
                        c_pipeline.producer_acquire()
                    self.epilog_sync_barrier.arrive_and_wait()
                #
                # Async arrive accumulator buffer empty
                #
                # Second half of the mirror: gated identically to the `consumer_wait` above.
                if not is_k_tile_cnt_zero:
                    with cute.arch.elect_one():
                        acc_pipeline.consumer_release(acc_consumer_state)
                    acc_consumer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                last_group_idx = cur_group_idx

            #
            # Dealloc the tensor memory buffer
            #
            if warp_idx == self.epilog_warp_id[0]:
                cute.arch.relinquish_tmem_alloc_permit(is_two_cta=use_2cta_instrs)
            self.epilog_sync_barrier.arrive_and_wait()
            if warp_idx == self.epilog_warp_id[0]:
                if use_2cta_instrs:
                    cute.arch.mbarrier_arrive(
                        tmem_dealloc_mbar_ptr, cta_rank_in_cluster ^ 1
                    )
                    cute.arch.mbarrier_wait(tmem_dealloc_mbar_ptr, 0)
                cute.arch.dealloc_tmem(
                    acc_tmem_ptr,
                    self.num_tmem_alloc_cols,
                    is_two_cta=use_2cta_instrs,
                    arch=self.arch,
                )
            #
            # Wait for C store complete
            #
            c_pipeline.producer_tail()

    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tiled_mma_sfb: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_sfa: cute.CopyAtom,
        mSFA_mkl: cute.Tensor,
        tma_atom_sfb: cute.CopyAtom,
        mSFB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        cluster_layout_sfb_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        tCtSFA_layout: cute.Layout,
        tCtSFB_layout: cute.Layout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        group_count: cutlass.Constexpr,
        problem_sizes_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        ptrs_abc: cute.Tensor,
        ptrs_sfasfb: cute.Tensor,
        tensormaps: cute.Tensor,
    ):
        """Thin ``@cute.kernel`` forwarder; the trailing three arguments are the
        ``self.*`` values that must be read on the host side."""
        self.kernel_impl(
            tiled_mma,
            tiled_mma_sfb,
            tma_atom_a,
            mA_mkl,
            tma_atom_b,
            mB_nkl,
            tma_atom_sfa,
            mSFA_mkl,
            tma_atom_sfb,
            mSFB_nkl,
            tma_atom_c,
            mC_mnl,
            cluster_layout_vmnk,
            cluster_layout_sfb_vmnk,
            a_smem_layout_staged,
            b_smem_layout_staged,
            sfa_smem_layout_staged,
            sfb_smem_layout_staged,
            tCtSFA_layout,
            tCtSFB_layout,
            c_smem_layout_staged,
            epi_tile,
            tile_sched_params,
            group_count,
            problem_sizes_mnkl,
            strides_abc,
            ptrs_abc,
            ptrs_sfasfb,
            tensormaps,
            self.cluster_shape_mn,
            self.is_a_mcast,
            self.is_b_mcast,
        )

    @cute.jit
    def make_tensor_abc_for_tensormap_update(
        self,
        group_idx: cutlass.Int32,
        dtype: Type[cutlass.Numeric],
        problem_shape_mnk: tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        strides_abc: cute.Tensor,
        tensor_address_abc: cute.Tensor,
        tensor_index: int,
    ):
        """Build the per-group A/B/C tensor handed to ``update_tma_descriptor``.

        Signature matches the inherited one exactly, because the epilogue calls the
        same method name for C.

        For the packed 6-bit A and B operands the tensor is in BYTES, not elements.
        ``update_tma_descriptor`` rewrites the base address, GLOBAL_DIM and
        GLOBAL_STRIDE fields of a descriptor whose element format was frozen to U8 when
        the atom was built (see ``__call__``), and the lowering does NOT rescale
        GLOBAL_DIM by the element width.

        :param group_idx: Index of the current group.
        :type group_idx: cutlass.Int32
        :param dtype: Element type of the tensor being described.
        :type dtype: Type[cutlass.Numeric]
        :param problem_shape_mnk: (M, N, K) problem shape of the current group.
        :type problem_shape_mnk: tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32]
        :param strides_abc: Strides for A, B, C for all groups. Layout: (group_count, 3, 2).
        :type strides_abc: cute.Tensor
        :param tensor_address_abc: Base addresses for A, B, C for all groups. Layout: (group_count, 3).
        :type tensor_address_abc: cute.Tensor
        :param tensor_index: 0 for A, 1 for B, 2 for C.
        :type tensor_index: int
        :return: The GMEM tensor describing the requested operand for this group.
        :rtype: cute.Tensor
        """
        # C keeps the inherited element-denominated build; qualified call so it cannot re-enter here.
        if cutlass.const_expr(tensor_index == 2 or dtype.width >= 8):
            return (
                Sm107GroupedBlockScaledGemmKernel.make_tensor_abc_for_tensormap_update(
                    self,
                    group_idx,
                    dtype,
                    problem_shape_mnk,
                    strides_abc,
                    tensor_address_abc,
                    tensor_index,
                )
            )

        ptr_i64 = tensor_address_abc[(group_idx, tensor_index)]
        # The descriptor's baked element format is U8.
        tensor_gmem_ptr = cute.make_ptr(
            cutlass.Uint8, ptr_i64, cutlass.AddressSpace.gmem, assumed_align=16
        )

        strides_tensor_gmem = strides_abc[(group_idx, tensor_index, None)]
        strides_tensor_reg = cute.make_rmem_tensor(
            cute.make_layout(2),
            strides_abc.element_type,
        )
        cute.autovec_copy(strides_tensor_gmem, strides_tensor_reg)
        # The K stride is 1 by construction (K-major A/B), so the byte-denominated K stride
        # is the literal 1 below.
        stride_mn = strides_tensor_reg[0]

        w = dtype.width
        mn = (
            problem_shape_mnk[0]
            if cutlass.const_expr(tensor_index == 0)
            else problem_shape_mnk[1]
        )
        k = problem_shape_mnk[2]
        # K % 64 == 0 is enforced for 6-bit A/B, so both products are exact.
        k_bytes = (k * w) // 8
        stride_mn_bytes = (stride_mn * w) // 8

        # The 1 and 0 are PYTHON LITERALS: `recast(8, 6, .)` only scales the shape when the
        # innermost stride is STATIC 1, else it silently leaves the extent unscaled.
        return cute.make_tensor(
            tensor_gmem_ptr,
            cute.make_layout((mn, k_bytes, 1), stride=(stride_mn_bytes, 1, 0)),
        )

    #
    # Validators. The dense checker is per-GEMM; this one runs it per group.
    #

    @staticmethod
    def is_valid_tensor_alignment(
        problem_sizes_mnkl: List[Tuple[int, int, int, int]],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: Literal["m", "k"],
        b_major: Literal["n", "k"],
        c_major: Literal["m", "n"],
    ) -> None:
        """Check the per-group tensor alignment.
        Reuse dense gemm's requirement.

        :param problem_sizes_mnkl: The problem shape for each group
        :type problem_sizes_mnkl: List[Tuple[int, int, int, int]]

        :raises testing.CantImplementError: If misaligned tensors.
        """
        for m, n, k, l in problem_sizes_mnkl:
            Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.is_valid_tensor_alignment(
                m, n, k, l, a_dtype, b_dtype, c_dtype, a_major, b_major, c_major
            )

    @staticmethod
    def can_implement(
        problem_sizes_mnkl: List[Tuple[int, int, int, int]],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: Literal["m", "k"],
        b_major: Literal["n", "k"],
        c_major: Literal["m", "n"],
        sf_vec_size: int,
        mma_tiler: Tuple[int, int, int],
        mma_inst_shape: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
    ) -> bool:
        """Check whether this grouped MXFP6 GEMM can be implemented.

        :return: True if the gemm can be implemented, False otherwise
        :rtype: bool
        """
        CurrentClass = Sm107Mxfp6GroupedBlockScaledGemmKernel
        DenseGemmClass = Sm107Mxfp6BlockScaledPersistentDenseGemmKernel
        try:
            # Skip unsupported types
            DenseGemmClass.is_valid_dtypes_and_scale_factor_vec_size(
                a_dtype, b_dtype, sf_dtype, sf_vec_size, c_dtype
            )

            # Skip unsupported layouts
            DenseGemmClass.is_valid_layouts(
                a_dtype, b_dtype, c_dtype, a_major, b_major, c_major
            )

            # Skip invalid mma tile shape
            DenseGemmClass.is_valid_mma_tiler(mma_inst_shape, mma_tiler)

            # Skip invalid cluster shape. The grouped parent folds this into
            # is_valid_mma_tiler_and_cluster_shape, so take the cluster half from the dense kernel.
            Sm107BlockScaledPersistentDenseGemmKernel.is_valid_cluster_shape(
                cluster_shape_mn, mma_inst_shape[0]
            )

            # Skip illegal problem shapes with respect to alignment requirements
            CurrentClass.is_valid_tensor_alignment(
                problem_sizes_mnkl, a_dtype, b_dtype, c_dtype, a_major, b_major, c_major
            )

        except testing.CantImplementError as e:
            print(f"[DSL ERROR] CantImplementError: {e}")
            return False

        return True


def run(
    num_groups: int,
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    host_problem_shape_available: bool,
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler: Tuple[int, int, int],
    mma_inst_shape: Tuple[int, int, int],
    cluster_shape_mn: Tuple[int, int],
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    use_cached_problem_shapes: bool = True,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    **kwargs,
):
    """Run the SM107 grouped MXFP6 block-scaled GEMM example.

    The parameter list is the Rubin grouped example's verbatim (grouped:2466-2490) so the
    two are interchangeable from a caller's point of view; the test file calls this
    all-keyword.

    Unlike the DENSE MXFP6 example, this driver does NOT go through
    ``run_scaled_mm_with_emulated_dtype``. No emulated-dtype harness is needed: FP6 is a
    <= 8-bit float, so ``cutlass.torch.cute_tensor_like`` (torch.py:290-300) already
    allocates a ``torch.uint8`` buffer and routes the values through
    ``convert_cute_tensor``, which lists both FP6 flavours explicitly (torch.py:178-186).

    :param use_cold_l2: Whether to use circular buffer strategy to ensure cold L2 cache, defaults to False
    :type use_cold_l2: bool, optional
    :param use_cached_problem_shapes: Enable double-buffered caching of problem
        shapes for better performance with many small groups, defaults to True.
    :type use_cached_problem_shapes: bool, optional
    :param init_normal: Whether to use normal (Gaussian) initialization for tensors, defaults to False.
        When True, tensors are initialized with normal distribution N(normal_mean, normal_std).
    :type init_normal: bool, optional
    :param normal_mean: Mean of the normal distribution for initialization, defaults to 0.0.
    :type normal_mean: float, optional
    :param normal_std: Standard deviation of the normal distribution for initialization, defaults to 1.0.
    :type normal_std: float, optional
    :return: Execution time of the GEMM kernel in microseconds
    :rtype: float
    """
    print("Running Rubin Grouped MXFP6 Blockscaled GEMM test with:")
    print(f"{num_groups} groups")
    for i, (m, n, k, l) in enumerate(problem_sizes_mnkl):
        print(f"Group {i}: {m}x{n}x{k}x{l}")
    print(
        f"A dtype: {a_dtype}, B dtype: {b_dtype}, SF dtype: {sf_dtype}, SF Vec size: {sf_vec_size}"
    )
    print(f"C dtype: {c_dtype}")
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(
        f"Mma Tiler (M, N, K): {mma_tiler}, MMA instruction shape (M, N, K): {mma_inst_shape}"
    )
    print(f"Cluster Shape (M, N): {cluster_shape_mn}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")
    print(f"Use cached problem shapes: {use_cached_problem_shapes}")

    # `can_implement` must run BEFORE the `torch.cuda.is_available()` guard so the
    # rejection tests never touch the GPU.
    if not Sm107Mxfp6GroupedBlockScaledGemmKernel.can_implement(
        problem_sizes_mnkl,
        a_dtype,
        b_dtype,
        sf_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        sf_vec_size,
        mma_tiler,
        mma_inst_shape,
        cluster_shape_mn,
    ):
        raise cutlass.testing.CantImplementError(
            f"Unsupported testcase {a_dtype}, {b_dtype}, {sf_dtype}, {sf_vec_size}, {c_dtype},  {mma_tiler}, "
            f"{mma_inst_shape}, {cluster_shape_mn}, {problem_sizes_mnkl}, {a_major}, {b_major}, {c_major}"
        )

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch.manual_seed(2026)

    # Determine initialization mode (same pattern as dense_gemm_persistent.py)
    use_normal_init = init_normal and (
        a_dtype not in [cutlass.Int8, cutlass.Uint8]
        and b_dtype not in [cutlass.Int8, cutlass.Uint8]
    )

    # Create tensors A, B, C for all groups. Strides stay in ELEMENTS;
    # `make_tensor_abc_for_tensormap_update` converts to bytes device-side.
    (
        ptrs_abc,
        torch_tensors_abc,
        cute_tensors_abc,
        strides_abc,
        ref_f32_torch_tensors_abc,
    ) = create_tensors_abc_for_all_groups(
        problem_sizes_mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        init_normal=use_normal_init,
        normal_mean=normal_mean,
        normal_std=normal_std,
    )
    # Create tensors SFA, SFB for all groups
    # Scale factors are NOT normal-initialized (they need positive values for correctness)
    (
        ptrs_sfasfb,
        torch_tensors_sfasfb,
        cute_tensors_sfasfb,
        refs_f32_torch_tensors_sfasfb,
    ) = create_tensors_sfasfb_for_all_groups(
        problem_sizes_mnkl,
        sf_dtype,
        sf_vec_size,
    )

    # Dummy "initial" tensors for the five TMA atoms: dtype and majorness only, since
    # every descriptor is rewritten per group on the device.
    #
    # min_ab_size is 64 FP6 elements (48 bytes), not the parent's `alignment * 8 //
    # width` (21 for FP6), and stays under the 128 KiB `oob_addr_gen_mode_` threshold.
    alignment = 16  # 16 bytes aligned
    divisibility_c = 32 if c_dtype == cutlass.Float4E2M1FN else 16
    divisibility_sf = 16

    min_ab_width = min(a_dtype.width, b_dtype.width)
    min_ab_size = 64
    assert (min_ab_size * min_ab_width) % 8 == 0, (
        f"the A/B dummy extent {min_ab_size} is not a whole number of bytes at "
        f"{min_ab_width} bits per element"
    )

    min_c_size = alignment * 8 // c_dtype.width
    div_mul_c = (divisibility_c + min_c_size - 1) // min_c_size
    min_c_size = min_c_size * div_mul_c

    min_sf_size = alignment * 8 // sf_dtype.width
    div_mul_sf = (divisibility_sf + min_sf_size - 1) // min_sf_size
    min_sf_size = min_sf_size * div_mul_sf

    initial_cute_tensors_abc = [
        create_tensor_and_stride(1, min_ab_size, min_ab_size, a_major == "m", a_dtype)[
            2
        ],
        create_tensor_and_stride(1, min_ab_size, min_ab_size, b_major == "n", b_dtype)[
            2
        ],
        create_tensor_and_stride(1, min_c_size, min_c_size, c_major == "m", c_dtype)[2],
    ]
    initial_cute_tensors_sfasfb = [
        create_tensor_and_stride(1, min_sf_size, min_sf_size, a_major == "m", sf_dtype)[
            2
        ],
        create_tensor_and_stride(1, min_sf_size, min_sf_size, b_major == "n", sf_dtype)[
            2
        ],
    ]

    hardware_info = cutlass.utils.HardwareInfo()
    sm_count = hardware_info.get_max_active_clusters(1)
    max_active_clusters = hardware_info.get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )
    # Prepare tensormap buffer for each SM
    num_tensormap_buffers = sm_count
    tensormap_shape = (
        num_tensormap_buffers,
        Sm107Mxfp6GroupedBlockScaledGemmKernel.num_tensormaps,
        Sm107Mxfp6GroupedBlockScaledGemmKernel.bytes_per_tensormap // 8,
    )
    tensor_of_tensormap, tensor_of_tensormap_torch = cutlass_torch.cute_tensor_like(
        torch.empty(tensormap_shape, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
    )

    grouped_blockscaled_gemm = Sm107Mxfp6GroupedBlockScaledGemmKernel(
        sf_vec_size,
        mma_inst_shape,
        mma_tiler,
        cluster_shape_mn,
        use_cached_problem_shapes,
    )

    # layout (num_groups, 4):(4, 1)
    (
        tensor_of_dim_size_mnkl,
        tensor_of_dim_size_mnkl_torch,
    ) = cutlass_torch.cute_tensor_like(
        torch.tensor(problem_sizes_mnkl, dtype=torch.int32),
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # layout (num_groups, 3, 2):(6, 2, 1) -- FP6 ELEMENT strides for A/B, see above.
    tensor_of_strides_abc, tensor_of_strides_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(strides_abc, dtype=torch.int32),
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # layout (num_groups,3):(3, 1)
    tensor_of_ptrs_abc, tensor_of_ptrs_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(ptrs_abc, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # layout (num_groups,2):(2, 1)
    tensor_of_ptrs_sfasfb, tensor_of_ptrs_sfasfb_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(ptrs_sfasfb, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # Compute total number of cluster tiles we need to compute for given grouped GEMM problem
    def compute_total_num_clusters(
        problem_sizes_mnkl: List[tuple[int, int, int, int]],
        cluster_tile_shape_mn: tuple[int, int],
    ) -> int:
        total_num_clusters = 0
        for m, n, _, _ in problem_sizes_mnkl:
            num_clusters_mn = tuple(
                (x + y - 1) // y for x, y in zip((m, n), cluster_tile_shape_mn)
            )
            total_num_clusters += functools.reduce(lambda x, y: x * y, num_clusters_mn)
        return total_num_clusters

    # Compute cluster tile shape. The 128 is the family's conservative CTA tile M, which
    # can only over-estimate the cluster count.
    def compute_cluster_tile_shape(
        mma_tiler_mn: tuple[int, int],
        cluster_shape_mn: tuple[int, int],
    ) -> tuple[int, int]:
        cta_tile_shape_mn = [128, mma_tiler_mn[1]]
        return tuple(x * y for x, y in zip(cta_tile_shape_mn, cluster_shape_mn))

    cluster_tile_shape_mn = compute_cluster_tile_shape(
        (mma_tiler[0], mma_tiler[1]), cluster_shape_mn
    )

    # Initialize Stream
    current_stream = cutlass_torch.default_stream()

    # If the host problem shape is available, we will launch the grid with only
    # the necessary clusters. The function compute_total_num_clusters() does that.
    # If the problem shape only exists on device, we will need to launch all active
    # clusters possible on a device.
    if host_problem_shape_available:
        print("Problem shapes available on host and device")
        total_num_clusters = compute_total_num_clusters(
            problem_sizes_mnkl, cluster_tile_shape_mn
        )
    else:
        print("Problem shapes available only on device")
        total_num_clusters = max_active_clusters

    # Compile grouped GEMM kernel
    compiled_grouped_gemm = cute.compile(
        grouped_blockscaled_gemm,
        initial_cute_tensors_abc[0],
        initial_cute_tensors_abc[1],
        initial_cute_tensors_abc[2],
        initial_cute_tensors_sfasfb[0],
        initial_cute_tensors_sfasfb[1],
        num_groups,
        tensor_of_dim_size_mnkl,
        tensor_of_strides_abc,
        tensor_of_ptrs_abc,
        tensor_of_ptrs_sfasfb,
        total_num_clusters,
        tensor_of_tensormap,
        max_active_clusters,
        current_stream,
    )

    # reference check
    if not skip_ref_check:
        compiled_grouped_gemm(
            initial_cute_tensors_abc[0],
            initial_cute_tensors_abc[1],
            initial_cute_tensors_abc[2],
            initial_cute_tensors_sfasfb[0],
            initial_cute_tensors_sfasfb[1],
            tensor_of_dim_size_mnkl,
            tensor_of_strides_abc,
            tensor_of_ptrs_abc,
            tensor_of_ptrs_sfasfb,
            tensor_of_tensormap,
            current_stream,
        )
        print("Verifying results...")

        for i, (
            (a_ref, b_ref, c_ref),
            (sfa_ref, sfb_ref),
            (a_tensor, b_tensor, c_tensor),
            (m, n, k, l),
        ) in enumerate(
            zip(
                ref_f32_torch_tensors_abc,
                refs_f32_torch_tensors_sfasfb,
                cute_tensors_abc,
                problem_sizes_mnkl,
            )
        ):
            # Per-group oracle: broadcast the scale factors back, then a plain f32 einsum.
            ref_res_a = torch.einsum("mkl,mkl->mkl", a_ref, sfa_ref)
            ref_res_b = torch.einsum("nkl,nkl->nkl", b_ref, sfb_ref)
            ref = torch.einsum("mkl,nkl->mnl", ref_res_a, ref_res_b)

            print(f"checking group {i}")
            c_ref_device = c_ref.cuda()

            cute.testing.convert(
                c_tensor,
                from_dlpack(c_ref_device, assumed_align=16).mark_layout_dynamic(
                    leading_dim=(1 if c_major == "n" else 0)
                ),
            )

            c_ref = c_ref_device.cpu()

            # Only the >= 16-bit branch survives; the grouped example's FP8/FP4 branches are unreachable.
            torch.testing.assert_close(c_ref, ref, atol=tolerance, rtol=1e-02)

    def generate_tensors():
        (
            ptrs_abc_workspace,
            torch_tensors_abc_workspace,
            cute_tensors_abc_workspace,
            strides_abc_workspace,
            _,
        ) = create_tensors_abc_for_all_groups(
            problem_sizes_mnkl,
            a_dtype,
            b_dtype,
            c_dtype,
            a_major,
            b_major,
            c_major,
            init_normal=use_normal_init,
            normal_mean=normal_mean,
            normal_std=normal_std,
        )

        (
            ptrs_sfasfb_workspace,
            torch_tensors_sfasfb_workspace,
            cute_tensors_sfasfb_workspace,
            _,
        ) = create_tensors_sfasfb_for_all_groups(
            problem_sizes_mnkl,
            sf_dtype,
            sf_vec_size,
        )

        initial_cute_tensors_abc_workspace = [
            create_tensor_and_stride(
                1, min_ab_size, min_ab_size, a_major == "m", a_dtype
            )[2],
            create_tensor_and_stride(
                1, min_ab_size, min_ab_size, b_major == "n", b_dtype
            )[2],
            create_tensor_and_stride(
                1, min_c_size, min_c_size, c_major == "m", c_dtype
            )[2],
        ]
        initial_cute_tensors_sfasfb_workspace = [
            create_tensor_and_stride(
                1, min_sf_size, min_sf_size, a_major == "m", sf_dtype
            )[2],
            create_tensor_and_stride(
                1, min_sf_size, min_sf_size, b_major == "n", sf_dtype
            )[2],
        ]

        # Create new tensors for this workspace
        tensor_of_strides_abc_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(strides_abc_workspace, dtype=torch.int32),
            cutlass.Int32,
            is_dynamic_layout=False,
            assumed_align=16,
        )

        tensor_of_ptrs_abc_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(ptrs_abc_workspace, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
            assumed_align=16,
        )

        tensor_of_ptrs_sfasfb_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(ptrs_sfasfb_workspace, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
            assumed_align=16,
        )

        tensormap_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.empty(tensormap_shape, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
        )

        args = cutlass.testing.JitArguments(
            initial_cute_tensors_abc_workspace[0],
            initial_cute_tensors_abc_workspace[1],
            initial_cute_tensors_abc_workspace[2],
            initial_cute_tensors_sfasfb_workspace[0],
            initial_cute_tensors_sfasfb_workspace[1],
            tensor_of_dim_size_mnkl,
            tensor_of_strides_abc_workspace,
            tensor_of_ptrs_abc_workspace,
            tensor_of_ptrs_sfasfb_workspace,
            tensormap_workspace,
            current_stream,
        )
        args.add_to_scope([torch_tensors_abc_workspace, torch_tensors_sfasfb_workspace])
        return args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            sum(
                [
                    sum(
                        [
                            torch_tensor.numel() * torch_tensor.element_size()
                            for torch_tensor in group_tensors
                        ]
                    )
                    for group_tensors in torch_tensors_abc + torch_tensors_sfasfb
                ]
            )
            +
            # Add size of strides tensor
            tensor_of_strides_abc_torch.numel()
            * tensor_of_strides_abc_torch.element_size()
            +
            # Add size of ptrs tensor A, B, C
            tensor_of_ptrs_abc_torch.numel() * tensor_of_ptrs_abc_torch.element_size()
            +
            # Add size of ptrs tensor SFA, SFB
            tensor_of_ptrs_sfasfb_torch.numel()
            * tensor_of_ptrs_sfasfb_torch.element_size()
            +
            # Add size of tensormap tensor
            tensor_of_tensormap_torch.numel() * tensor_of_tensormap_torch.element_size()
        )
        workspace_count = cutlass.testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = cutlass.testing.benchmark(
        compiled_grouped_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    runtime_s = exec_time / 1.0e6
    fmas = 0
    for group in range(num_groups):
        [M, N, K, _] = problem_sizes_mnkl[group]
        fmas += M * N * K
    flop = 2 * fmas
    gflop = flop / 1.0e9

    print("Average Runtime : ", exec_time / 1000, "ms")
    if runtime_s > 0:
        gflops = gflop / runtime_s
        print("GFLOPS          : ", gflops)

    return exec_time  # Return execution time in microseconds


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    def parse_comma_separated_tuples(s: str) -> List[tuple[int, ...]]:
        if s.strip().startswith("("):
            # Split on ),( to separate tuples
            tuples = s.strip("()").split("),(")
            result = []
            tuple_len = None

            for t in tuples:
                # Parse individual tuple
                nums = [int(x.strip()) for x in t.split(",")]

                # Validate tuple length consistency
                if tuple_len is None:
                    tuple_len = len(nums)
                elif len(nums) != tuple_len:
                    raise argparse.ArgumentTypeError(
                        "All tuples must have the same length"
                    )

                result.append(tuple(nums))
            return result

        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers or list of tuples"
        )

    parser = argparse.ArgumentParser(
        description="Example of Grouped MXFP6 BlockScaled GEMM on Rubin."
    )
    parser.add_argument(
        "--num_groups",
        type=int,
        default=3,
        help="Number of groups",
    )
    parser.add_argument(
        "--problem_sizes_mnkl",
        type=parse_comma_separated_tuples,
        default=((512, 256, 256, 1), (256, 512, 256, 1), (512, 256, 768, 1)),
        help="a tuple of problem sizes for each group (comma-separated tuples)",
    )
    parser.add_argument(
        "--mma_tiler",
        type=parse_comma_separated_ints,
        default=(128, 128, 512),
        help="Mma tile shape (M, N, K) (comma-separated)",
    )
    parser.add_argument(
        "--mma_inst_shape",
        type=parse_comma_separated_ints,
        default=(128, 128, 64),
        help="Mma inst shape (M, N, K) (comma-separated)",
    )
    parser.add_argument(
        "--host_problem_shape_available",
        action="store_true",
        help="Enable the compute of grid based upon host problem shape",
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(2, 2),
        help="Cluster shape (comma-separated)",
    )
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Float6E2M3FN)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float6E3M2FN)
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E8M0FNU)
    parser.add_argument("--sf_vec_size", type=int, default=32)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float32)
    # Majorness is a singleton choice: K-major A/B is required, only N-major C is exercised.
    parser.add_argument("--a_major", choices=["k"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n"], type=str, default="n")
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--warmup_iterations", type=int, default=0, help="Warmup iterations"
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=1,
        help="Number of iterations to run the kernel",
    )
    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference checking"
    )
    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )
    parser.add_argument(
        "--no_use_cached_problem_shapes",
        action="store_true",
        default=False,
        help="Disable double-buffered caching of problem shapes. "
        "By default, caching is enabled for better performance with many small groups.",
    )
    parser.add_argument(
        "--init_normal",
        action="store_true",
        help="Use normal (Gaussian) initialization for tensors instead of uniform random",
    )
    parser.add_argument(
        "--normal_mean",
        type=float,
        default=0.0,
        help="Mean of normal distribution for initialization (default: 0.0)",
    )
    parser.add_argument(
        "--normal_std",
        type=float,
        default=1.0,
        help="Standard deviation of normal distribution for initialization (default: 1.0)",
    )

    args = parser.parse_args()

    if (
        len(args.problem_sizes_mnkl) != 0
        and len(args.problem_sizes_mnkl) != args.num_groups
    ):
        parser.error("--problem_sizes_mnkl must contain exactly num_groups tuples")

    # l mode must be 1 for all groups
    for _, _, _, l in args.problem_sizes_mnkl:
        if l != 1:
            parser.error("l must be 1 for all groups")

    if len(args.mma_tiler) != 3:
        parser.error("--mma_tiler must contain exactly 3 values (M, N, K)")

    if len(args.mma_inst_shape) != 3:
        parser.error("--mma_inst_shape must contain exactly 3 values (M, N, K)")

    if len(args.cluster_shape_mn) != 2:
        parser.error("--cluster_shape_mn must contain exactly 2 values")

    # Every argument passed by KEYWORD: an inserted parameter would otherwise shift the rest.
    run(
        num_groups=args.num_groups,
        problem_sizes_mnkl=args.problem_sizes_mnkl,
        host_problem_shape_available=args.host_problem_shape_available,
        a_dtype=args.a_dtype,
        b_dtype=args.b_dtype,
        sf_dtype=args.sf_dtype,
        sf_vec_size=args.sf_vec_size,
        c_dtype=args.c_dtype,
        a_major=args.a_major,
        b_major=args.b_major,
        c_major=args.c_major,
        mma_tiler=args.mma_tiler,
        mma_inst_shape=args.mma_inst_shape,
        cluster_shape_mn=args.cluster_shape_mn,
        tolerance=args.tolerance,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        skip_ref_check=args.skip_ref_check,
        use_cold_l2=args.use_cold_l2,
        use_cached_problem_shapes=not args.no_use_cached_problem_shapes,
        init_normal=args.init_normal,
        normal_mean=args.normal_mean,
        normal_std=args.normal_std,
    )
    print("PASS")
