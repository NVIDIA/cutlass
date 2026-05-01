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
Scaled Grouped GEMM for MoE operations with block scaling (MXFP8, MXFP4, NVFP4).

PyTorch interface (from torch.nn.functional.scaled_grouped_mm):
- 2Dx3D (Forward): mat_a(tokens_sum, K) x mat_b(experts, K, N) -> out(tokens_sum, N)
- 2Dx2D (Weight grad): mat_a(M, tokens_sum) x mat_b(tokens_sum, N) -> out(experts, M, N)

Kernel interface uses GEMM MNKL domain (same as torch_grouped_mm.py):
  A_cute: (M, K, L)
  B_cute: (N, K, L)
  C_cute: (M, N, L)
  SFA_cute, SFB_cute: scale factors with block-scaled atom layout

The scheduler handles fake dimensions by computing token_offset from offs.
"""

import os
import sys
from typing import Optional, Tuple, Literal, Type, Union

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.typing import Pointer
from cutlass.cute.nvgpu import cpasync, tcgen05
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../.."))

from blackwell.kernel.moe.moe_utils import (
    MoEScaledGroupedGemmTensormapConstructor,
)
from blackwell.kernel.moe.moe_persistent_scheduler import (
    MoEStaticSchedulerParams,
    MoEStaticPersistentTileScheduler,
    MoEWorkTileInfo,
)
from blackwell.kernel.moe.moe_sched_extension import ScaledGroupedMmSchedExtension
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
from cutlass.utils.gemm.sm100 import (
    transform_partitioned_tensor_layout,
    epilogue_tmem_copy_and_partition,
    epilogue_smem_copy_and_partition,
)

# =============================================================================
# ScaledGroupedGemmKernel
# =============================================================================


class ScaledGroupedGemmKernel:
    """
    Scaled Grouped GEMM kernel for MoE operations with block scaling.

    Combines:
    - MoE grouped structure from GroupedGemmKernel (scheduler warp, expert-wise
      TMA descriptors, MoEStaticPersistentTileScheduler)
    - Block-scaled MMA from Sm100BlockScaledPersistentDenseGemmKernel (SFA/SFB
      tensors, blockscaled tiled_mma, SMEM→TMEM SF copy)

    Warp specialization (7 warps):
    - Warps 0-3: Epilogue (TMEM → RMEM → SMEM → GMEM, global_scale multiply)
    - Warp 4:    MMA (tcgen05.mma.block_scale with SFA/SFB in TMEM)
    - Warp 5:    TMA load (A, B, SFA, SFB from GMEM → SMEM)
    - Warp 6:    Scheduler (MoEStaticPersistentTileScheduler, produces work tiles)

    __init__ parameters are codegen-time configuration only.
    Runtime dtypes (a_dtype, b_dtype, sf_dtype, c_dtype) and layout modes
    (a_major_mode, b_major_mode, c_layout) are inferred from input tensors
    in __call__.
    """

    def __init__(
        self,
        scenario: Literal["2Dx3D", "2Dx2D"],
        sf_vec_size: int,
        accumulate_on_output: bool,
        separate_tensormap_init: bool,
        consistent_token_padding: bool,
        acc_dtype: Type[cutlass.Numeric] = cutlass.Float32,
        mma_tiler_mnk: Tuple[int, int, int] = (128, 128, 64),
        cluster_shape_mnk: Tuple[int, int, int] = (1, 1, 1),
        use_2cta_instrs: bool = False,
        fixed_expert_cnt: Optional[int] = None,
    ):
        # ── User-provided codegen-time configuration ──
        self.scenario = scenario
        self.sf_vec_size = sf_vec_size
        self.accumulate_on_output = accumulate_on_output
        self.separate_tensormap_init = separate_tensormap_init
        self.consistent_token_padding = consistent_token_padding
        self.acc_dtype = acc_dtype
        self.mma_tiler_mnk = mma_tiler_mnk
        self.cluster_shape_mn = (cluster_shape_mnk[0], cluster_shape_mnk[1])
        self.use_2cta_instrs = use_2cta_instrs
        self.fixed_expert_cnt = fixed_expert_cnt
        self.arch = "sm_100"

        if accumulate_on_output and scenario == "2Dx3D":
            raise ValueError(
                "accumulate_on_output only makes sense for 2Dx2D (weight grad)."
            )

        self._validate_mma_tiler_and_cluster_shape()

        # ── MMA tiler — K is refined in _setup_attributes ──
        self.mma_tiler = (mma_tiler_mnk[0], mma_tiler_mnk[1], 1)

        # ── CTA group for tcgen05 MMA ──
        self.cta_group = (
            tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        # ── Warp specialization (7 warps) ──
        self.occupancy = 1
        self.epilogue_warp_id = (0, 1, 2, 3)
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

        # ── Barrier IDs for synchronization ──
        self.epilog_sync_bar_id = 1
        self.tmem_alloc_sync_bar_id = 2
        self.tmem_dealloc_sync_bar_id = 3

        self.smem_capacity = utils.get_smem_capacity_in_bytes(self.arch)
        self.num_tmem_alloc_cols = cute.arch.get_max_tmem_alloc_cols(self.arch)

    # -----------------------------------------------------------------
    # Workspace size
    # -----------------------------------------------------------------

    def get_workspace_size(self, expert_cnt: int) -> int:
        """Workspace size for the aux init kernel.

        Layout: [TMA descriptors (managed by tensormap ctor)] [padded scale offsets]
        """
        desc_bytes = MoEScaledGroupedGemmTensormapConstructor.get_workspace_size(
            self.scenario, expert_cnt
        )
        padded_offs_bytes = expert_cnt * 4 if not self.consistent_token_padding else 0
        return desc_bytes + padded_offs_bytes

    # -----------------------------------------------------------------
    # Static validation
    # -----------------------------------------------------------------

    def _validate_mma_tiler_and_cluster_shape(self):
        """Validate codegen-time MMA tiler and cluster shape constraints."""
        m, n, k = self.mma_tiler_mnk
        cm, cn = self.cluster_shape_mn

        if m not in [128, 256]:
            raise ValueError(f"mma_tiler M ({m}) must be one of [128, 256]")

        per_cta_m = m // (2 if self.use_2cta_instrs else 1)
        if per_cta_m != 128:
            raise ValueError(
                f"per-CTA mma_tiler M must be 128, got {per_cta_m} "
                f"(mma_tiler_m={m}, use_2cta_instrs={self.use_2cta_instrs})"
            )

        if n not in [64, 128, 256]:
            raise ValueError(f"mma_tiler N ({n}) must be one of [64, 128, 256]")

        sf_k_granularity = self.sf_vec_size * 4
        if k % sf_k_granularity != 0:
            raise ValueError(
                f"mma_tiler K ({k}) must be a multiple of "
                f"sf_vec_size * 4 = {sf_k_granularity}"
            )

        if cm % (2 if self.use_2cta_instrs else 1) != 0:
            raise ValueError(
                f"cluster_shape M ({cm}) must be even when use_2cta_instrs=True"
            )

        is_pow2 = lambda x: x > 0 and (x & (x - 1)) == 0
        if cm * cn > 16 or not is_pow2(cm) or not is_pow2(cn) or cm > 4 or cn > 4:
            raise ValueError(
                f"Invalid cluster_shape ({cm}, {cn}): each dim must be "
                f"a power of 2 and <= 4, product must be <= 16"
            )

        if self.sf_vec_size not in {16, 32}:
            raise ValueError(f"sf_vec_size ({self.sf_vec_size}) must be 16 or 32")

    # -----------------------------------------------------------------
    # _create_tiled_mma / _create_tiled_mma_sfb
    # -----------------------------------------------------------------

    def _create_tiled_mma(self) -> cute.TiledMma:
        """Create blockscaled tiled MMA atom."""
        return sm100_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape_mn,
        )

    def _create_tiled_mma_sfb(self) -> cute.TiledMma:
        """Create blockscaled tiled MMA atom for SFB (always CtaGroup.ONE)."""
        return sm100_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_mn_sfb,
        )

    # -----------------------------------------------------------------
    # _setup_attributes
    # -----------------------------------------------------------------

    def _setup_attributes(self) -> None:
        """
        Set up configurations that depend on GEMM inputs.

        Configures:
        - tiled_mma / tiled_mma_sfb with correct dtypes and major modes
        - MMA/cluster/tile shapes
        - Cluster layouts (main + sfb)
        - Multicast CTA counts
        - Epilogue tile shape
        - Stage counts (ACC, AB+SF, C)
        - SMEM layouts for A/B/SFA/SFB/C
        - TMEM column counts (accumulator + SFA + SFB)
        - TMA load bytes
        - Overlapping accumulator support
        """
        # ── MMA instruction shapes ──
        self.mma_inst_shape_mn = (self.mma_tiler[0], self.mma_tiler[1])
        self.mma_inst_shape_mn_sfb = (
            self.mma_inst_shape_mn[0] // (2 if self.use_2cta_instrs else 1),
            cute.round_up(self.mma_inst_shape_mn[1], 128),
        )

        tiled_mma = self._create_tiled_mma()
        tiled_mma_sfb = self._create_tiled_mma_sfb()

        # ── MMA / cluster / tile shapes ──
        # Use user-specified K dimension from mma_tiler_mnk
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        assert self.mma_tiler_mnk[2] % mma_inst_shape_k == 0, (
            f"mma_tiler K ({self.mma_tiler_mnk[2]}) must be a multiple of "
            f"MMA instruction K ({mma_inst_shape_k})"
        )
        mma_inst_tile_k = self.mma_tiler_mnk[2] // mma_inst_shape_k
        self.mma_tiler = (
            self.mma_inst_shape_mn[0],
            self.mma_inst_shape_mn[1],
            self.mma_tiler_mnk[2],
        )
        self.mma_tiler_sfb = (
            self.mma_inst_shape_mn_sfb[0],
            self.mma_inst_shape_mn_sfb[1],
            self.mma_tiler_mnk[2],
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )
        self.cta_tile_shape_mnk_sfb = (
            self.mma_tiler_sfb[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler_sfb[1],
            self.mma_tiler_sfb[2],
        )

        # ── Cluster layouts ──
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        self.cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma_sfb.thr_id.shape,),
        )

        # ── Multicast CTA counts ──
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.num_mcast_ctas_sfb = cute.size(self.cluster_layout_sfb_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1
        self.is_sfb_mcast = self.num_mcast_ctas_sfb > 1

        # ── Epilogue tile shape ──
        self.epi_tile = sm100_utils.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.c_layout,
            self.c_dtype,
        )
        self.epi_tile_n = cute.size(self.epi_tile[1])

        # ── Stage counts ──
        self.num_acc_stage, self.num_ab_stage, self.num_c_stage = self._compute_stages(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.epi_tile,
            self.c_dtype,
            self.c_layout,
            self.sf_dtype,
            self.sf_vec_size,
            self.smem_capacity,
            self.occupancy,
        )

        self.num_sched_stages = 2

        # ── SMEM layouts ──
        self.a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.num_ab_stage,
        )
        self.b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma,
            self.mma_tiler,
            self.b_dtype,
            self.num_ab_stage,
        )
        self.sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.num_ab_stage,
        )
        self.sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.num_ab_stage,
        )
        self.c_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            self.c_dtype,
            self.c_layout,
            self.epi_tile,
            self.num_c_stage,
        )

        # ── Overlapping accumulator ──
        # N=256: TMEM can't fit 2 full acc buffers + SF, so acc and SF share columns.
        # The acc pipeline uses 1 barrier stage with phase-based toggling.
        # N<256: TMEM fits 2 independent acc buffers, normal 2-stage pipeline.
        self.overlapping_accum = self.cta_tile_shape_mnk[1] == 256
        self.num_acc_pipeline_stages = (
            1 if self.overlapping_accum else self.num_acc_stage
        )

        # ── TMEM column counts ──
        sf_atom_mn = 32
        self.num_sfa_tmem_cols = (
            self.cta_tile_shape_mnk[0] // sf_atom_mn
        ) * mma_inst_tile_k
        self.num_sfb_tmem_cols = (
            self.cta_tile_shape_mnk_sfb[1] // sf_atom_mn
        ) * mma_inst_tile_k
        self.num_sf_tmem_cols = self.num_sfa_tmem_cols + self.num_sfb_tmem_cols
        self.num_accumulator_tmem_cols = self.cta_tile_shape_mnk[
            1
        ] * self.num_acc_stage - (
            self.num_sf_tmem_cols if self.overlapping_accum else 0
        )

        # Only when overlapping_accum, release accumulator buffer early in epilogue
        self.iter_acc_early_release_in_epilogue = (
            self.num_sf_tmem_cols // self.epi_tile_n
        )

        # ── TMA load bytes (A + B + SFA + SFB per stage) ──
        atom_thr_size = cute.size(tiled_mma.thr_id.shape)
        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, None, 0))
        sfa_smem_layout = cute.slice_(
            self.sfa_smem_layout_staged, (None, None, None, 0)
        )
        sfb_smem_layout = cute.slice_(
            self.sfb_smem_layout_staged, (None, None, None, 0)
        )
        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        sfa_copy_size = cute.size_in_bytes(self.sf_dtype, sfa_smem_layout)
        sfb_copy_size = cute.size_in_bytes(self.sf_dtype, sfb_smem_layout)
        self.num_tma_load_bytes = (
            a_copy_size + b_copy_size + sfa_copy_size + sfb_copy_size
        ) * atom_thr_size

    # -----------------------------------------------------------------
    # _compute_stages (static)
    # -----------------------------------------------------------------

    @staticmethod
    def _compute_stages(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: Tuple[int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        epi_tile: cute.Tile,
        c_dtype: Type[cutlass.Numeric],
        c_layout: utils.LayoutEnum,
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        smem_capacity: int,
        occupancy: int,
    ) -> Tuple[int, int, int]:
        """Compute stage counts for ACC, A/B/SFA/SFB, and C."""
        num_acc_stage = 2
        num_c_stage = 2

        a_smem_layout_stage_one = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mma_tiler_mnk,
            a_dtype,
            1,
        )
        b_smem_layout_staged_one = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mma_tiler_mnk,
            b_dtype,
            1,
        )
        sfa_smem_layout_staged_one = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            mma_tiler_mnk,
            sf_vec_size,
            1,
        )
        sfb_smem_layout_staged_one = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            mma_tiler_mnk,
            sf_vec_size,
            1,
        )
        c_smem_layout_staged_one = sm100_utils.make_smem_layout_epi(
            c_dtype,
            c_layout,
            epi_tile,
            1,
        )

        ab_bytes_per_stage = (
            cute.size_in_bytes(a_dtype, a_smem_layout_stage_one)
            + cute.size_in_bytes(b_dtype, b_smem_layout_staged_one)
            + cute.size_in_bytes(sf_dtype, sfa_smem_layout_staged_one)
            + cute.size_in_bytes(sf_dtype, sfb_smem_layout_staged_one)
        )
        mbar_helpers_bytes = 1024
        c_bytes_per_stage = cute.size_in_bytes(c_dtype, c_smem_layout_staged_one)
        c_bytes = c_bytes_per_stage * num_c_stage

        sched_work_tile_bytes_per_stage = 16  # 4 fields * sizeof(Int32)
        num_sched_stages = 2
        sched_bytes = sched_work_tile_bytes_per_stage * num_sched_stages

        fixed_overhead = mbar_helpers_bytes + c_bytes + sched_bytes

        num_ab_stage = (
            smem_capacity // occupancy - fixed_overhead
        ) // ab_bytes_per_stage

        num_c_stage += (
            smem_capacity
            - occupancy * ab_bytes_per_stage * num_ab_stage
            - occupancy * fixed_overhead
        ) // (occupancy * c_bytes_per_stage)

        return num_acc_stage, num_ab_stage, num_c_stage

    # -----------------------------------------------------------------
    # mainloop_s2t_copy_and_partition (from dense_blockscaled)
    # -----------------------------------------------------------------

    def mainloop_s2t_copy_and_partition(
        self,
        sSF: cute.Tensor,
        tSF: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Make tiledCopy for smem → tmem load of a scale factor tensor,
        then partition smem (source) and tmem (destination).
        """
        tCsSF_compact = cute.filter_zeros(sSF)
        tCtSF_compact = cute.filter_zeros(tSF)

        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp4x32x128bOp(self.cta_group),
            self.sf_dtype,
        )
        tiled_copy_s2t = tcgen05.make_s2t_copy(copy_atom_s2t, tCtSF_compact)
        thr_copy_s2t = tiled_copy_s2t.get_slice(0)

        tCsSF_compact_s2t_ = thr_copy_s2t.partition_S(tCsSF_compact)
        tCsSF_compact_s2t = tcgen05.get_s2t_smem_desc_tensor(
            tiled_copy_s2t, tCsSF_compact_s2t_
        )
        tCtSF_compact_s2t = thr_copy_s2t.partition_D(tCtSF_compact)

        return tiled_copy_s2t, tCsSF_compact_s2t, tCtSF_compact_s2t

    # -----------------------------------------------------------------
    # __call__ (JIT entry point)
    # -----------------------------------------------------------------

    @cute.jit
    def __call__(
        self,
        mat_a: cute.Tensor,  # PyTorch mat_a (data)
        mat_b: cute.Tensor,  # PyTorch mat_b (data)
        scale_a: cute.Tensor,  # SFA (assembled block-scaled layout)
        scale_b: cute.Tensor,  # SFB (assembled block-scaled layout)
        out: cute.Tensor,  # Output C
        offs: cute.Tensor,  # (experts,) cumsum end offsets, int32
        workspace: cute.Tensor,  # Expert-wise TMA desc + padded offs
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        global_scale_a: Optional[cute.Tensor] = None,  # NVFP4: per-expert f32 scalar
        global_scale_b: Optional[cute.Tensor] = None,  # NVFP4: per-expert f32 scalar
        bias: Optional[cute.Tensor] = None,
    ) -> None:
        """Launch the scaled grouped GEMM kernel."""
        if cutlass.const_expr(bias is not None):
            raise NotImplementedError("bias is not supported yet (align with torch).")

        # =================================================================
        # Step 1: Transform PyTorch tensors to GEMM domain (fake MNKL)
        # =================================================================
        c1 = cutlass.Int32(1)
        c0 = cutlass.Int32(0)

        if cutlass.const_expr(self.scenario == "2Dx3D"):
            # mat_a: (tokens_sum, hidden) -> A: (fake_m, k, 1)
            tokens_sum, hidden = mat_a.shape
            a_gemm = cute.make_tensor(
                mat_a.iterator,
                cute.make_layout(
                    (tokens_sum, hidden, c1),
                    stride=(mat_a.stride[0], mat_a.stride[1], c0),
                ),
            )
            # mat_b: (experts, hidden, intermediate) -> B: (n, k, fake_l)
            experts, hidden_b, intermediate = mat_b.shape
            b_gemm = cute.make_tensor(
                mat_b.iterator,
                cute.make_layout(
                    (intermediate, hidden_b, experts),
                    stride=(mat_b.stride[2], mat_b.stride[1], mat_b.stride[0]),
                ),
            )
            # out: (tokens_sum, intermediate) -> C: (fake_m, n, 1)
            c_gemm = cute.make_tensor(
                out.iterator,
                cute.make_layout(
                    (tokens_sum, intermediate, c1),
                    stride=(out.stride[0], out.stride[1], c0),
                ),
            )
            expert_cnt = experts
            intermediate_dim = intermediate
            hidden_dim = hidden

            # SFA/SFB: scale tensors have host-padded dimensions.
            # Use their own shape as the "data shape" for atom tiling.
            tokens_sum_padded = scale_a.shape[0]
            hidden_padded = scale_a.shape[1] * self.sf_vec_size
            sfa_gemm = cute.make_tensor(
                scale_a.iterator,
                blockscaled_utils.tile_atom_to_shape_SF(
                    (tokens_sum_padded, hidden_padded, c1), self.sf_vec_size
                ),
            )
            intermediate_padded_mul_hidden_padded = scale_b.shape[1]
            intermediate_padded = (
                intermediate_padded_mul_hidden_padded * self.sf_vec_size
            ) // hidden_padded
            sfb_gemm = cute.make_tensor(
                scale_b.iterator,
                blockscaled_utils.tile_atom_to_shape_SF(
                    (intermediate_padded, hidden_padded, experts), self.sf_vec_size
                ),
            )

        else:  # 2Dx2D
            # mat_a: (hidden, tokens_sum) -> A: (m, fake_k, 1)
            hidden, tokens_sum = mat_a.shape
            a_gemm = cute.make_tensor(
                mat_a.iterator,
                cute.make_layout(
                    (hidden, tokens_sum, c1),
                    stride=(mat_a.stride[0], mat_a.stride[1], c0),
                ),
            )
            # mat_b: (tokens_sum, intermediate) -> B: (n, fake_k, 1)
            tokens_sum_b, intermediate = mat_b.shape
            b_gemm = cute.make_tensor(
                mat_b.iterator,
                cute.make_layout(
                    (intermediate, tokens_sum_b, c1),
                    stride=(mat_b.stride[1], mat_b.stride[0], c0),
                ),
            )
            # out: (experts, hidden, intermediate) -> C: (m, n, fake_l)
            experts, hidden_c, intermediate_c = out.shape
            c_gemm = cute.make_tensor(
                out.iterator,
                cute.make_layout(
                    (hidden_c, intermediate_c, experts),
                    stride=(out.stride[1], out.stride[2], out.stride[0]),
                ),
            )
            expert_cnt = experts
            intermediate_dim = intermediate
            hidden_dim = hidden

            # SFA/SFB: scale tensors have host-padded dimensions.
            hidden_padded = scale_a.shape[0]
            tokens_sum_padded = scale_a.shape[1] * self.sf_vec_size
            sfa_gemm = cute.make_tensor(
                scale_a.iterator,
                blockscaled_utils.tile_atom_to_shape_SF(
                    (hidden_padded, tokens_sum_padded, c1), self.sf_vec_size
                ),
            )
            intermediate_padded = scale_b.shape[0]
            sfb_gemm = cute.make_tensor(
                scale_b.iterator,
                blockscaled_utils.tile_atom_to_shape_SF(
                    (intermediate_padded, tokens_sum_padded, c1), self.sf_vec_size
                ),
            )

        # =================================================================
        # Step 2: Infer dtypes and major modes
        # =================================================================

        self.a_dtype: Type[cutlass.Numeric] = a_gemm.element_type
        self.b_dtype: Type[cutlass.Numeric] = b_gemm.element_type
        self.c_dtype: Type[cutlass.Numeric] = c_gemm.element_type
        self.sf_dtype: Type[cutlass.Numeric] = sfa_gemm.element_type
        self.a_major_mode = utils.LayoutEnum.from_tensor(a_gemm).mma_major_mode()
        self.b_major_mode = utils.LayoutEnum.from_tensor(b_gemm).mma_major_mode()
        self.c_layout = utils.LayoutEnum.from_tensor(c_gemm)

        # =================================================================
        # Step 3: Setup kernel attributes
        # =================================================================

        self._setup_attributes()
        tiled_mma = self._create_tiled_mma()
        tiled_mma_sfb = self._create_tiled_mma_sfb()

        # =================================================================
        # Step 4: Create TMA atoms for A, B, SFA, SFB, C
        # =================================================================

        # ── TMA load A ──
        a_op = sm100_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            a_gemm,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
        )

        # ── TMA load B ──
        b_op = sm100_utils.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, None, 0))
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            b_op,
            b_gemm,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
        )

        # ── TMA load SFA ──
        # sfa_gemm is already atom-tiled from tile_atom_to_shape_SF
        sfa_op = sm100_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfa_smem_layout = cute.slice_(
            self.sfa_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfa, tma_tensor_sfa = cute.nvgpu.make_tiled_tma_atom_A(
            sfa_op,
            sfa_gemm,
            sfa_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=cutlass.Uint64,
        )

        # ── TMA load SFB ──
        # sfb_gemm is already atom-tiled from tile_atom_to_shape_SF
        sfb_op = sm100_utils.cluster_shape_to_tma_atom_SFB(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfb_smem_layout = cute.slice_(
            self.sfb_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfb, tma_tensor_sfb = cute.nvgpu.make_tiled_tma_atom_B(
            sfb_op,
            sfb_gemm,
            sfb_smem_layout,
            self.mma_tiler_sfb,
            tiled_mma_sfb,
            self.cluster_layout_sfb_vmnk.shape,
            internal_type=cutlass.Uint64,
        )

        # ── TMA store/reduce C ──
        if cutlass.const_expr(self.accumulate_on_output):
            c_tma_op = cpasync.CopyReduceBulkTensorTileS2GOp()
        else:
            c_tma_op = cpasync.CopyBulkTensorTileS2GOp()

        epi_smem_layout = cute.select(self.c_smem_layout_staged, mode=[0, 1])
        tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
            c_tma_op, c_gemm, epi_smem_layout, self.epi_tile
        )

        # =================================================================
        # Step 5: offs_padded tensor (written by desc_init_kernel)
        # =================================================================

        # consistent_token_padding=True → offs_padded=None, main kernel reuses offs
        # consistent_token_padding=False → offs_padded in GMEM workspace, written by desc_init
        if cutlass.const_expr(self.consistent_token_padding):
            offs_padded = None
        else:
            desc_bytes = MoEScaledGroupedGemmTensormapConstructor.get_workspace_size(
                self.scenario, expert_cnt
            )
            offs_padded = cute.make_tensor(
                cute.recast_ptr(workspace.iterator + desc_bytes, dtype=offs.dtype),
                cute.make_layout((expert_cnt,)),
            )

        # =================================================================
        # Step 6: Create MoEStaticSchedulerParams and compute grid
        # =================================================================

        sched_params = MoEStaticSchedulerParams(
            scenario=self.scenario,
            expert_shape=(expert_cnt, intermediate_dim, hidden_dim),
            cta_tile_shape_mnk=self.cta_tile_shape_mnk,
            cluster_shape_mn=self.cluster_shape_mn,
        )

        grid = MoEStaticSchedulerParams.get_grid_shape(
            sched_params, max_active_clusters
        )

        # =================================================================
        # Step 7: Launch desc_init_kernel (if separate_tensormap_init)
        # =================================================================

        if cutlass.const_expr(self.separate_tensormap_init):
            self.desc_init_kernel(
                tiled_mma,
                tiled_mma_sfb,
                a_gemm,
                b_gemm,
                c_gemm,
                sfa_gemm,
                sfb_gemm,
                offs,
                expert_cnt,
                workspace.iterator,
                self.cluster_layout_vmnk,
                self.cluster_layout_sfb_vmnk,
                self.a_smem_layout_staged,
                self.b_smem_layout_staged,
                self.sfa_smem_layout_staged,
                self.sfb_smem_layout_staged,
                self.c_smem_layout_staged,
                self.epi_tile,
            ).launch(
                grid=(1, 1, 1),
                block=[self._desc_init_block_threads, 1, 1],
                stream=stream,
                min_blocks_per_mp=1,
            )

        # =================================================================
        # Step 8: Launch main kernel
        # =================================================================

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
            a_gemm,
            b_gemm,
            c_gemm,
            sfa_gemm,
            sfb_gemm,
            offs,
            sched_params,
            workspace.iterator,
            self.cluster_layout_vmnk,
            self.cluster_layout_sfb_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.c_smem_layout_staged,
            self.epi_tile,
            offs_padded,
            global_scale_a,
            global_scale_b,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
            min_blocks_per_mp=self.occupancy,
        )

    # -----------------------------------------------------------------
    # desc_init_kernel (GPU device kernel)
    # -----------------------------------------------------------------

    # Number of warps per warp-group in desc_init_kernel.
    _desc_init_warps_per_group = 4
    # Threads per warp-group (must equal MoEScaledGroupedGemmTensormapConstructor.ChunkSize).
    _desc_init_group_threads = _desc_init_warps_per_group * 32  # 128
    # Total threads in desc_init_kernel (2 warp-groups × 4 warps each).
    _desc_init_block_threads = _desc_init_group_threads * 2  # 256
    # Named barrier ID for warp-group-internal sync within Group A.
    _desc_init_group_a_bar_id = 1

    @cute.kernel
    def desc_init_kernel(
        self,
        # ── MMA atoms ──
        tiled_mma: cute.TiledMma,
        tiled_mma_sfb: cute.TiledMma,
        # ── GEMM domain tensors (fake MNKL) ──
        a_gemm: cute.Tensor,
        b_gemm: cute.Tensor,
        c_gemm: cute.Tensor,
        sfa_gemm: cute.Tensor,
        sfb_gemm: cute.Tensor,
        # ── Scheduling / workspace ──
        offs: cute.Tensor,
        expert_cnt: Union[cutlass.Int32, int],
        workspace_ptr: Pointer,
        # ── Cluster layouts ──
        cluster_layout_vmnk: cute.Layout,
        cluster_layout_sfb_vmnk: cute.Layout,
        # ── SMEM layouts ──
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
    ):
        """
        Pre-initialize expert-wise TMA descriptors and compute padded scale
        offsets (``offs_padded``).

        Grid: (1, 1, 1)
        Block: (256, 1, 1) — 8 warps split into two groups of 4:

        - **Group A** (warps 0-3, threads 0..127): Compute ``offs_padded``
          prefix sum, write to SMEM + GMEM.
        - **Group B** (warps 4-7, threads 128..255): Create TMA descriptors
          via ``construct_and_write`` (chunked, with pipeline sync).

        Synchronization:
        - Group A internal: NamedBarrier (for cross-warp prefix sum)
        - Group A → Group B: PipelineAsync (mbarrier producer-consumer)
        """
        chunk_size = self._desc_init_group_threads  # 128
        full_mask = 0xFFFFFFFF
        warp_size = 32

        # =================================================================
        # Thread identity
        # =================================================================

        tidx, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.warp_idx()
        lane_in_group = tidx % chunk_size  # 0..127 within each group

        # =================================================================
        # Reconstruct TMA ops (same as before)
        # =================================================================

        a_smem_layout = cute.slice_(a_smem_layout_staged, (None, None, None, 0))
        b_smem_layout = cute.slice_(b_smem_layout_staged, (None, None, None, 0))
        sfa_smem_layout = cute.slice_(sfa_smem_layout_staged, (None, None, None, 0))
        sfb_smem_layout = cute.slice_(sfb_smem_layout_staged, (None, None, None, 0))
        epi_smem_layout = cute.select(c_smem_layout_staged, mode=[0, 1])

        a_tma_op = sm100_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        b_tma_op = sm100_utils.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfa_tma_op = sm100_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfb_tma_op = sm100_utils.cluster_shape_to_tma_atom_SFB(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        if cutlass.const_expr(self.accumulate_on_output):
            c_tma_op = cpasync.CopyReduceBulkTensorTileS2GOp()
        else:
            c_tma_op = cpasync.CopyBulkTensorTileS2GOp()

        # =================================================================
        # GMEM offs_padded tensor (written by Group A, read by main kernel)
        # Only allocated when consistent_token_padding=False.
        # =================================================================

        if cutlass.const_expr(not self.consistent_token_padding):
            desc_bytes = MoEScaledGroupedGemmTensormapConstructor.get_workspace_size(
                self.scenario, expert_cnt
            )
            gmem_offs_padded = cute.make_tensor(
                cute.recast_ptr(workspace_ptr + desc_bytes, dtype=offs.dtype),
                cute.make_layout((expert_cnt,)),
            )

        # =================================================================
        # SMEM allocation
        # =================================================================

        smem = utils.SmemAllocator()

        @cute.struct
        class DescInitStorage:
            # offs_padded SMEM buffer: [carry, chunk[0..127]]
            offs_padded_buf: cute.struct.MemRange[cutlass.Int32, chunk_size + 1]
            # Cross-warp prefix sum scratch (one per warp in Group A)
            warp_sums: cute.struct.MemRange[
                cutlass.Int32, self._desc_init_warps_per_group
            ]
            # Pipeline mbarrier storage (PipelineAsync with 1 stage needs 2 mbarriers)
            pipeline_mbar: cute.struct.MemRange[cutlass.Int64, 2]

        storage = smem.allocate(DescInitStorage)

        # Make a tensor view for the SMEM offs_padded buffer
        smem_offs_padded = cute.make_tensor(
            storage.offs_padded_buf.data_ptr(),
            cute.make_layout((chunk_size + 1,)),
        )
        smem_warp_sums = cute.make_tensor(
            storage.warp_sums.data_ptr(),
            cute.make_layout((self._desc_init_warps_per_group,)),
        )

        # =================================================================
        # Pipeline: Group A (producer) → Group B (consumer)
        # =================================================================

        producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread, chunk_size)
        consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread, chunk_size)
        pipe = pipeline.PipelineAsync.create(
            num_stages=1,
            producer_group=producer_group,
            consumer_group=consumer_group,
            barrier_storage=storage.pipeline_mbar.data_ptr(),
        )
        producer, consumer = pipe.make_participants()

        # Named barrier for Group A internal sync (cross-warp prefix sum)
        group_a_sync = pipeline.NamedBarrier(
            barrier_id=self._desc_init_group_a_bar_id,
            num_threads=chunk_size,
        )

        # =================================================================
        # Padding granularity P
        # =================================================================

        if cutlass.const_expr(self.scenario == "2Dx2D"):
            # tokens = K (reduce dim): pad scale cols → P = sf_vec_size × 4
            pad_granularity = self.sf_vec_size * 4
        else:
            # tokens = M (non-reduce dim): pad scale rows → P = 128
            pad_granularity = 128

        # =================================================================
        # Tensormap constructor (for Group B)
        # =================================================================

        tensormap_ctor = MoEScaledGroupedGemmTensormapConstructor(
            scenario=self.scenario,
            sf_vec_size=self.sf_vec_size,
            a_dtype=self.a_dtype,
            b_dtype=self.b_dtype,
            c_dtype=self.c_dtype,
            sf_dtype=self.sf_dtype,
            a_smem_layout=a_smem_layout,
            b_smem_layout=b_smem_layout,
            epi_smem_layout=epi_smem_layout,
            sfa_smem_layout=sfa_smem_layout,
            sfb_smem_layout=sfb_smem_layout,
            a_tma_op=a_tma_op,
            b_tma_op=b_tma_op,
            c_tma_op=c_tma_op,
            sfa_tma_op=sfa_tma_op,
            sfb_tma_op=sfb_tma_op,
            tiled_mma=tiled_mma,
            tiled_mma_sfb=tiled_mma_sfb,
            mma_tiler=self.mma_tiler,
            mma_tiler_sfb=self.mma_tiler_sfb,
            cluster_layout_vmnk_shape=cluster_layout_vmnk.shape,
            cluster_layout_sfb_vmnk_shape=cluster_layout_sfb_vmnk.shape,
            epi_tile=epi_tile,
            a_tensor=a_gemm,
            b_tensor=b_gemm,
            c_tensor=c_gemm,
            sfa_tensor=sfa_gemm,
            sfb_tensor=sfb_gemm,
            offs=offs,
            offs_padded=offs
            if cutlass.const_expr(self.consistent_token_padding)
            else gmem_offs_padded,
            workspace_ptr=workspace_ptr,
            expert_cnt=expert_cnt,
        )

        # =================================================================
        # Warp-group split
        # =================================================================

        num_chunks = (expert_cnt + chunk_size - 1) // chunk_size

        if warp_idx < self._desc_init_warps_per_group:
            # =============================================================
            # Group A: produce offs_padded into SMEM (+ GMEM if needed)
            # =============================================================

            warp_in_group = warp_idx  # 0..3
            lane_in_warp = tidx % warp_size

            carry = cutlass.Int32(0)
            chunk_idx = cutlass.Int32(0)

            while chunk_idx < num_chunks:
                expert_idx = chunk_idx * chunk_size + lane_in_group

                if cutlass.const_expr(self.consistent_token_padding):
                    # ── Fast path: offs_padded == offs, just load ──
                    offs_val = cutlass.Int32(0)
                    if expert_idx < expert_cnt:
                        offs_val = offs[expert_idx]

                    # Wait for consumer to release SMEM from previous chunk
                    producer.acquire_and_advance()

                    # Write SMEM: [carry, offs[chunk_base..chunk_base+127]]
                    if lane_in_group == cutlass.Int32(0):
                        smem_offs_padded[0] = carry
                    smem_offs_padded[lane_in_group + 1] = offs_val

                    # Ensure all SMEM writes visible, then signal consumer
                    group_a_sync.arrive_and_wait()
                    producer.commit()

                    # Only thread 0 needs carry (to write smem[0] next iteration)
                    if lane_in_group == cutlass.Int32(0):
                        carry = smem_offs_padded[chunk_size]

                else:
                    # ── Full path: compute prefix sum of padded sizes ──

                    # Load and compute per-thread padded size
                    padded_size = cutlass.Int32(0)
                    if expert_idx < expert_cnt:
                        prev_off = cutlass.Int32(0)
                        if expert_idx > cutlass.Int32(0):
                            prev_off = offs[expert_idx - 1]
                        size_i = offs[expert_idx] - prev_off
                        padded_size = (
                            (size_i + pad_granularity - 1) // pad_granularity
                        ) * pad_granularity

                    # Stage 1: warp-level inclusive prefix sum (shfl_up)
                    val = padded_size
                    for d in [1, 2, 4, 8, 16]:
                        n = cute.arch.shuffle_sync_up(
                            val, d, mask=full_mask, mask_and_clamp=0
                        )
                        if lane_in_warp >= d:
                            val = val + n

                    # Lane 31 of each warp holds the warp total
                    if lane_in_warp == warp_size - 1:
                        smem_warp_sums[warp_in_group] = val

                    # Group A internal sync (warp_sums visible)
                    group_a_sync.arrive_and_wait()

                    # Stage 2: cross-warp correction
                    cross_warp_prefix = cutlass.Int32(0)
                    if warp_in_group >= 1:
                        cross_warp_prefix = smem_warp_sums[0]
                    if warp_in_group >= 2:
                        cross_warp_prefix = cross_warp_prefix + smem_warp_sums[1]
                    if warp_in_group >= 3:
                        cross_warp_prefix = cross_warp_prefix + smem_warp_sums[2]

                    offs_padded_val = carry + val + cross_warp_prefix

                    # Wait for consumer to release SMEM from previous chunk
                    producer.acquire_and_advance()

                    # Write SMEM: [carry, offs_padded[chunk_base..chunk_base+127]]
                    if lane_in_group == cutlass.Int32(0):
                        smem_offs_padded[0] = carry
                    smem_offs_padded[lane_in_group + 1] = offs_padded_val

                    # Ensure all SMEM writes visible, then signal consumer
                    group_a_sync.arrive_and_wait()
                    producer.commit()

                    # Write GMEM (overlaps with Group B's phase 2)
                    if expert_idx < expert_cnt:
                        gmem_offs_padded[expert_idx] = offs_padded_val

                    # Update carry
                    carry = smem_offs_padded[chunk_size]

                chunk_idx += 1

        else:
            # =============================================================
            # Group B: create TMA descriptors (chunked, with pipeline sync)
            # =============================================================

            tensormap_ctor.construct_and_write(
                lane_in_group,
                dependency=(consumer, smem_offs_padded),
            )

    # -----------------------------------------------------------------
    # kernel (GPU device kernel)
    # -----------------------------------------------------------------

    @cute.kernel
    def kernel(
        self,
        # ── MMA atoms ──
        tiled_mma: cute.TiledMma,
        tiled_mma_sfb: cute.TiledMma,
        # ── TMA atoms and tensors: A ──
        tma_atom_a: cute.CopyAtom,
        tma_tensor_a: cute.Tensor,
        # ── TMA atoms and tensors: B ──
        tma_atom_b: cute.CopyAtom,
        tma_tensor_b: cute.Tensor,
        # ── TMA atoms and tensors: SFA ──
        tma_atom_sfa: cute.CopyAtom,
        tma_tensor_sfa: cute.Tensor,
        # ── TMA atoms and tensors: SFB ──
        tma_atom_sfb: cute.CopyAtom,
        tma_tensor_sfb: cute.Tensor,
        # ── TMA atoms and tensors: C ──
        tma_atom_c: cute.CopyAtom,
        tma_tensor_c: cute.Tensor,
        # ── GEMM domain tensors ──
        a_gemm: cute.Tensor,
        b_gemm: cute.Tensor,
        c_gemm: cute.Tensor,
        sfa_gemm: cute.Tensor,
        sfb_gemm: cute.Tensor,
        # ── Scheduling / workspace ──
        offs: cute.Tensor,
        sched_params: MoEStaticSchedulerParams,
        workspace_ptr: Pointer,
        # ── Cluster layouts ──
        cluster_layout_vmnk: cute.Layout,
        cluster_layout_sfb_vmnk: cute.Layout,
        # ── SMEM layouts ──
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
        # ── Optional: padded offsets ──
        offs_padded: Optional[cute.Tensor],
        # ── Optional: NVFP4 per-expert global scales ──
        global_scale_a: Optional[cute.Tensor],
        global_scale_b: Optional[cute.Tensor],
    ):
        """
        GPU device kernel for MoE Scaled Grouped GEMM with block scaling.

        Backbone: torch_grouped_mm.py (7-warp MoE scheduler structure)
        GEMM internals: dense_blockscaled_gemm_persistent.py
        """
        # =================================================================
        # Reconstruct objects that can't be passed as kernel params
        # =================================================================

        a_smem_layout = cute.slice_(a_smem_layout_staged, (None, None, None, 0))
        b_smem_layout = cute.slice_(b_smem_layout_staged, (None, None, None, 0))
        sfa_smem_layout = cute.slice_(sfa_smem_layout_staged, (None, None, None, 0))
        sfb_smem_layout = cute.slice_(sfb_smem_layout_staged, (None, None, None, 0))
        epi_smem_layout = cute.select(c_smem_layout_staged, mode=[0, 1])

        a_tma_op = sm100_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        b_tma_op = sm100_utils.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfa_tma_op = sm100_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfb_tma_op = sm100_utils.cluster_shape_to_tma_atom_SFB(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        if cutlass.const_expr(self.accumulate_on_output):
            c_tma_op = cpasync.CopyReduceBulkTensorTileS2GOp()
        else:
            c_tma_op = cpasync.CopyBulkTensorTileS2GOp()

        # Build offs tuple for the extension
        if cutlass.const_expr(offs_padded is not None):
            offs_for_ext = (offs, offs_padded)
        else:
            offs_for_ext = (offs, offs)

        tensormap_ctor = MoEScaledGroupedGemmTensormapConstructor(
            scenario=self.scenario,
            sf_vec_size=self.sf_vec_size,
            a_dtype=self.a_dtype,
            b_dtype=self.b_dtype,
            c_dtype=self.c_dtype,
            sf_dtype=self.sf_dtype,
            a_smem_layout=a_smem_layout,
            b_smem_layout=b_smem_layout,
            epi_smem_layout=epi_smem_layout,
            sfa_smem_layout=sfa_smem_layout,
            sfb_smem_layout=sfb_smem_layout,
            a_tma_op=a_tma_op,
            b_tma_op=b_tma_op,
            c_tma_op=c_tma_op,
            sfa_tma_op=sfa_tma_op,
            sfb_tma_op=sfb_tma_op,
            tiled_mma=tiled_mma,
            tiled_mma_sfb=tiled_mma_sfb,
            mma_tiler=self.mma_tiler,
            mma_tiler_sfb=self.mma_tiler_sfb,
            cluster_layout_vmnk_shape=cluster_layout_vmnk.shape,
            cluster_layout_sfb_vmnk_shape=cluster_layout_sfb_vmnk.shape,
            epi_tile=epi_tile,
            a_tensor=a_gemm,
            b_tensor=b_gemm,
            c_tensor=c_gemm,
            sfa_tensor=sfa_gemm,
            sfb_tensor=sfb_gemm,
            offs=offs,
            offs_padded=offs_padded if offs_padded is not None else offs,
            workspace_ptr=workspace_ptr,
        )
        ext = ScaledGroupedMmSchedExtension(
            scenario=self.scenario, tensormap_ctor=tensormap_ctor
        )

        # =================================================================
        # Kernel setup
        # =================================================================

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

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
        tidx, _, _ = cute.arch.thread_idx()

        # =================================================================
        # SharedStorage
        # =================================================================

        @cute.struct
        class SharedStorage:
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage * 2]
            acc_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_acc_pipeline_stages * 2
            ]
            sched_buf: cute.struct.MemRange[cutlass.Int32, self.num_sched_stages * 4]
            sched_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_sched_stages * 2
            ]
            tmem_dealloc_mbar_ptr: cutlass.Int64
            tmem_holding_buf: cutlass.Int32

        smem = utils.SmemAllocator()
        storage = smem.allocate(SharedStorage)

        # =================================================================
        # Pipelines
        # =================================================================

        # AB pipeline (TMA load → MMA) — same as grouped_mm
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_tma_producer = self.num_mcast_ctas_a + self.num_mcast_ctas_b - 1
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_tma_producer
        )
        ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        ).make_participants()

        # ACC pipeline (MMA → epilogue)
        acc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_acc_consumer_threads = (
            len(self.epilogue_warp_id) * 32 * (2 if use_2cta_instrs else 1)
        )
        acc_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_acc_consumer_threads
        )
        acc_pipeline = pipeline.PipelineUmmaAsync.create(
            barrier_storage=storage.acc_full_mbar_ptr.data_ptr(),
            num_stages=self.num_acc_pipeline_stages,
            producer_group=acc_pipeline_producer_group,
            consumer_group=acc_pipeline_consumer_group,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )

        # Scheduler pipeline (sched warp → tma/mma/epi warps)
        sched_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread, 32)
        num_sched_consumer_threads = 32 * len(
            (self.tma_warp_id, self.mma_warp_id, *self.epilogue_warp_id)
        )
        sched_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_sched_consumer_threads
        )
        sched_pipeline = pipeline.PipelineAsync.create(
            num_stages=self.num_sched_stages,
            producer_group=sched_producer_group,
            consumer_group=sched_consumer_group,
            barrier_storage=storage.sched_mbar_ptr.data_ptr(),
            defer_sync=True,
        )

        # TMEM allocator
        tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=self.tmem_alloc_sync_bar_id,
            num_threads=32 * len((self.mma_warp_id, *self.epilogue_warp_id)),
        )
        tmem = utils.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar_ptr.ptr,
        )

        # Cluster barrier sync after init
        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)

        # =================================================================
        # SMEM tensors A/B/SFA/SFB
        # =================================================================

        sA = smem.allocate_tensor(
            element_type=self.a_dtype,
            layout=a_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=a_smem_layout_staged.inner,
        )
        sB = smem.allocate_tensor(
            element_type=self.b_dtype,
            layout=b_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=b_smem_layout_staged.inner,
        )
        sSFA = smem.allocate_tensor(
            element_type=self.sf_dtype,
            layout=sfa_smem_layout_staged,
            byte_alignment=128,
        )
        sSFB = smem.allocate_tensor(
            element_type=self.sf_dtype,
            layout=sfb_smem_layout_staged,
            byte_alignment=128,
        )

        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])

        # (MMA, MMA_M, MMA_N, STAGE=2)
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )
        if cutlass.const_expr(self.overlapping_accum):
            # Overlapping: two acc buffers share TMEM with SF columns,
            # so the stage stride is smaller than a full N-width.
            tCtAcc_fake = cute.make_tensor(
                tCtAcc_fake.iterator,
                cute.make_layout(
                    tCtAcc_fake.shape,
                    stride=(
                        tCtAcc_fake.stride[0],
                        tCtAcc_fake.stride[1],
                        tCtAcc_fake.stride[2],
                        (256 - self.num_sf_tmem_cols) * tCtAcc_fake.stride[0][1],
                    ),
                ),
            )

        # Cluster wait before TMEM alloc
        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        # =================================================================
        # Scheduler warp (warp 6) — same as grouped_mm
        # =================================================================

        sched_buf_ptr = storage.sched_buf.data_ptr()
        sched_copy_atom = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), cutlass.Int32, num_bits_per_copy=128
        )
        sched_buf_tensor = cute.make_tensor(
            sched_buf_ptr, cute.make_layout((4, self.num_sched_stages), stride=(1, 4))
        )

        if warp_idx == self.sched_warp_id:
            scheduler = MoEStaticPersistentTileScheduler.create(
                sched_params, offs, cute.arch.block_idx(), cute.arch.grid_dim()
            )

            sched_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_sched_stages
            )

            work_tile_info = scheduler.initial_work_tile_info()
            sched_pipeline.producer_acquire(sched_producer_state)
            rmem = work_tile_info.to_rmem_tensor()
            cute.copy(
                sched_copy_atom,
                rmem,
                sched_buf_tensor[(None, sched_producer_state.index)],
            )
            cute.arch.fence_proxy("async.shared", space="cta")
            sched_pipeline.producer_commit(sched_producer_state)
            sched_producer_state.advance()

            work_tile_info = scheduler.advance_to_next_work()
            while work_tile_info.is_valid_tile:
                ext.prefetch_for_expert(work_tile_info.expert_idx)
                sched_pipeline.producer_acquire(sched_producer_state)
                rmem = work_tile_info.to_rmem_tensor()
                cute.copy(
                    sched_copy_atom,
                    rmem,
                    sched_buf_tensor[(None, sched_producer_state.index)],
                )
                cute.arch.fence_proxy("async.shared", space="cta")
                sched_pipeline.producer_commit(sched_producer_state)
                sched_producer_state.advance()

                work_tile_info = scheduler.advance_to_next_work()

            sched_pipeline.producer_acquire(sched_producer_state)
            sentinel = MoEWorkTileInfo(
                cutlass.Int32(-1),
                cutlass.Int32(0),
                cutlass.Int32(0),
                cutlass.Int32(0),
            )
            rmem = sentinel.to_rmem_tensor()
            cute.copy(
                sched_copy_atom,
                rmem,
                sched_buf_tensor[(None, sched_producer_state.index)],
            )
            cute.arch.fence_proxy("async.shared", space="cta")
            sched_pipeline.producer_commit(sched_producer_state)

            sched_pipeline.producer_tail(sched_producer_state)

        # =================================================================
        # TMA load warp (warp 5)
        # =================================================================

        if warp_idx == self.tma_warp_id:
            # Multicast masks, only used in TMA load warp
            a_full_mcast_mask = None
            b_full_mcast_mask = None
            sfa_full_mcast_mask = None
            sfb_full_mcast_mask = None
            if cutlass.const_expr(
                self.is_a_mcast or self.is_b_mcast or use_2cta_instrs
            ):
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
                    cluster_layout_sfb_vmnk,
                    block_in_cluster_coord_sfb_vmnk,
                    mcast_mode=1,
                )

            sched_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_sched_stages
            )

            # Read initial work_tile_info
            sched_pipeline.consumer_wait(sched_consumer_state)
            rmem = cute.make_rmem_tensor((4,), cutlass.Int32)
            cute.copy(
                sched_copy_atom,
                sched_buf_tensor[(None, sched_consumer_state.index)],
                rmem,
            )
            work_tile_info = MoEWorkTileInfo.from_rmem_tensor(rmem)
            cute.arch.fence_acq_rel_cta()
            sched_pipeline.consumer_release(sched_consumer_state)
            sched_consumer_state.advance()

            while work_tile_info.is_valid_tile:
                k_tile_cnt = work_tile_info.k_tile_cnt

                # Get real GEMM domain tensors + TMA desc ptrs via extension
                real_a, desc_ptr_a = ext.get_gmem_tensor(
                    "a",
                    tma_tensor_a,
                    offs_for_ext,
                    work_tile_info,
                )
                real_b, desc_ptr_b = ext.get_gmem_tensor(
                    "b",
                    tma_tensor_b,
                    offs_for_ext,
                    work_tile_info,
                )
                real_sfa, desc_ptr_sfa = ext.get_gmem_tensor(
                    "sfa",
                    tma_tensor_sfa,
                    offs_for_ext,
                    work_tile_info,
                )
                real_sfb, desc_ptr_sfb = ext.get_gmem_tensor(
                    "sfb",
                    tma_tensor_sfb,
                    offs_for_ext,
                    work_tile_info,
                )

                # local_tile for A, B
                gA_mkl = cute.local_tile(
                    real_a,
                    cute.slice_(self.mma_tiler, (None, 0, None)),
                    (None, None, None),
                )
                gB_nkl = cute.local_tile(
                    real_b,
                    cute.slice_(self.mma_tiler, (0, None, None)),
                    (None, None, None),
                )

                # local_tile for SFA, SFB
                gSFA_mkl = cute.local_tile(
                    real_sfa,
                    cute.slice_(self.mma_tiler, (None, 0, None)),
                    (None, None, None),
                )
                gSFB_nkl = cute.local_tile(
                    real_sfb,
                    cute.slice_(self.mma_tiler_sfb, (0, None, None)),
                    (None, None, None),
                )

                # MMA partition for TMA
                thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
                thr_mma_sfb = tiled_mma_sfb.get_slice(mma_tile_coord_v)
                tCgA = thr_mma.partition_A(gA_mkl)
                tCgB = thr_mma.partition_B(gB_nkl)
                tCgSFA = thr_mma.partition_A(gSFA_mkl)
                tCgSFB = thr_mma_sfb.partition_B(gSFB_nkl)

                # TMA partition A
                a_cta_layout = cute.make_layout(
                    cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
                )
                tAsA, tAgA = cpasync.tma_partition(
                    tma_atom_a,
                    block_in_cluster_coord_vmnk[2],
                    a_cta_layout,
                    cute.group_modes(sA, 0, 3),
                    cute.group_modes(tCgA, 0, 3),
                )
                # TMA partition B
                b_cta_layout = cute.make_layout(
                    cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
                )
                tBsB, tBgB = cpasync.tma_partition(
                    tma_atom_b,
                    block_in_cluster_coord_vmnk[1],
                    b_cta_layout,
                    cute.group_modes(sB, 0, 3),
                    cute.group_modes(tCgB, 0, 3),
                )
                # TMA partition SFA
                sfa_cta_layout = a_cta_layout
                tAsSFA, tAgSFA = cpasync.tma_partition(
                    tma_atom_sfa,
                    block_in_cluster_coord_vmnk[2],
                    sfa_cta_layout,
                    cute.group_modes(sSFA, 0, 3),
                    cute.group_modes(tCgSFA, 0, 3),
                )
                tAsSFA = cute.filter_zeros(tAsSFA)
                tAgSFA = cute.filter_zeros(tAgSFA)
                # TMA partition SFB
                sfb_cta_layout = cute.make_layout(
                    cute.slice_(cluster_layout_sfb_vmnk, (0, None, 0, 0)).shape
                )
                tBsSFB, tBgSFB = cpasync.tma_partition(
                    tma_atom_sfb,
                    block_in_cluster_coord_sfb_vmnk[1],
                    sfb_cta_layout,
                    cute.group_modes(sSFB, 0, 3),
                    cute.group_modes(tCgSFB, 0, 3),
                )
                tBsSFB = cute.filter_zeros(tBsSFB)
                tBgSFB = cute.filter_zeros(tBgSFB)

                # Slice to current tile coords (L=0, expert already selected)
                mma_tile_m = work_tile_info.tile_m_idx // cute.size(
                    tiled_mma.thr_id.shape
                )
                tAgA_slice = tAgA[(None, mma_tile_m, None, 0)]
                tBgB_slice = tBgB[(None, work_tile_info.tile_n_idx, None, 0)]
                tAgSFA_slice = tAgSFA[(None, mma_tile_m, None, 0)]

                # SFB slice — N=64
                slice_n = work_tile_info.tile_n_idx
                if cutlass.const_expr(self.cta_tile_shape_mnk[1] == 64):
                    slice_n = work_tile_info.tile_n_idx // 2
                tBgSFB_slice = tBgSFB[(None, slice_n, None, 0)]

                # TMA load loop
                ab_producer.reset()
                peek_ab_empty_status = ab_producer.try_acquire()

                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    handle = ab_producer.acquire_and_advance(peek_ab_empty_status)
                    peek_ab_empty_status = cutlass.Boolean(1)
                    if handle.count + 1 < k_tile_cnt:
                        peek_ab_empty_status = ab_producer.try_acquire()
                    # TMA load A
                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, handle.count)],
                        tAsA[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        tma_desc_ptr=desc_ptr_a,
                        mcast_mask=a_full_mcast_mask,
                    )
                    # TMA load B
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, handle.count)],
                        tBsB[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        tma_desc_ptr=desc_ptr_b,
                        mcast_mask=b_full_mcast_mask,
                    )
                    # TMA load SFA
                    cute.copy(
                        tma_atom_sfa,
                        tAgSFA_slice[(None, handle.count)],
                        tAsSFA[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        tma_desc_ptr=desc_ptr_sfa,
                        mcast_mask=sfa_full_mcast_mask,
                    )
                    # TMA load SFB
                    cute.copy(
                        tma_atom_sfb,
                        tBgSFB_slice[(None, handle.count)],
                        tBsSFB[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        tma_desc_ptr=desc_ptr_sfb,
                        mcast_mask=sfb_full_mcast_mask,
                    )

                # Read next work_tile_info
                sched_pipeline.consumer_wait(sched_consumer_state)
                rmem = cute.make_rmem_tensor((4,), cutlass.Int32)
                cute.copy(
                    sched_copy_atom,
                    sched_buf_tensor[(None, sched_consumer_state.index)],
                    rmem,
                )
                work_tile_info = MoEWorkTileInfo.from_rmem_tensor(rmem)
                cute.arch.fence_acq_rel_cta()
                sched_pipeline.consumer_release(sched_consumer_state)
                sched_consumer_state.advance()

            ab_producer.tail()

        # =================================================================
        # MMA warp (warp 4)
        # =================================================================

        if warp_idx == self.mma_warp_id:
            # MMA fragments (SMEM → TMEM partitions), only used in this warp
            tCrA = tiled_mma.make_fragment_A(sA)
            tCrB = tiled_mma.make_fragment_B(sB)

            tmem.wait_for_alloc()
            acc_tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            # SFA TMEM tensor
            sfa_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr + self.num_accumulator_tmem_cols,
                dtype=self.sf_dtype,
            )
            tCtSFA_layout = blockscaled_utils.make_tmem_layout_sfa(
                tiled_mma,
                self.mma_tiler,
                self.sf_vec_size,
                cute.slice_(sfa_smem_layout_staged, (None, None, None, 0)),
            )
            tCtSFA = cute.make_tensor(sfa_tmem_ptr, tCtSFA_layout)

            # SFB TMEM tensor
            sfb_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr + self.num_accumulator_tmem_cols + self.num_sfa_tmem_cols,
                dtype=self.sf_dtype,
            )
            tCtSFB_layout = blockscaled_utils.make_tmem_layout_sfb(
                tiled_mma,
                self.mma_tiler,
                self.sf_vec_size,
                cute.slice_(sfb_smem_layout_staged, (None, None, None, 0)),
            )
            tCtSFB = cute.make_tensor(sfb_tmem_ptr, tCtSFB_layout)

            # S2T copy partitions for SFA/SFB
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

            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_pipeline_stages
            )
            sched_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_sched_stages
            )

            # Read initial work_tile_info
            sched_pipeline.consumer_wait(sched_consumer_state)
            rmem = cute.make_rmem_tensor((4,), cutlass.Int32)
            cute.copy(
                sched_copy_atom,
                sched_buf_tensor[(None, sched_consumer_state.index)],
                rmem,
            )
            work_tile_info = MoEWorkTileInfo.from_rmem_tensor(rmem)
            cute.arch.fence_acq_rel_cta()
            sched_pipeline.consumer_release(sched_consumer_state)
            sched_consumer_state.advance()

            while work_tile_info.is_valid_tile:
                k_tile_cnt = work_tile_info.k_tile_cnt

                # Get accumulator stage index
                if cutlass.const_expr(self.overlapping_accum):
                    acc_stage_index = acc_producer_state.phase ^ 1
                else:
                    acc_stage_index = acc_producer_state.index

                if is_leader_cta:
                    tCtAcc = tCtAcc_base[(None, None, None, acc_stage_index)]

                    # SFB TMEM pointer offset for N=64
                    tCtSFB_mma = tCtSFB
                    if cutlass.const_expr(self.cta_tile_shape_mnk[1] == 64):
                        offset = cutlass.Int32((work_tile_info.tile_n_idx % 2) * 2)
                        shifted_ptr = cute.recast_ptr(
                            acc_tmem_ptr
                            + self.num_accumulator_tmem_cols
                            + self.num_sfa_tmem_cols
                            + offset,
                            dtype=self.sf_dtype,
                        )
                        tCtSFB_mma = cute.make_tensor(shifted_ptr, tCtSFB_layout)

                    # AB consumer mainloop
                    ab_consumer.reset()
                    peek_ab_full_status = cutlass.Boolean(1)
                    if k_tile_cnt > 0:
                        peek_ab_full_status = ab_consumer.try_wait()
                        acc_pipeline.producer_acquire(acc_producer_state)

                    tiled_mma.set(tcgen05.Field.ACCUMULATE, False)

                    for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                        handle = ab_consumer.wait_and_advance(peek_ab_full_status)
                        peek_ab_full_status = cutlass.Boolean(1)
                        if handle.count + 1 < k_tile_cnt:
                            peek_ab_full_status = ab_consumer.try_wait()

                        # S2T copy SFA/SFB from SMEM to TMEM
                        s2t_stage_coord = (
                            None,
                            None,
                            None,
                            None,
                            handle.index,
                        )
                        cute.copy(
                            tiled_copy_s2t_sfa,
                            tCsSFA_compact_s2t[s2t_stage_coord],
                            tCtSFA_compact_s2t,
                        )
                        cute.copy(
                            tiled_copy_s2t_sfb,
                            tCsSFB_compact_s2t[s2t_stage_coord],
                            tCtSFB_compact_s2t,
                        )

                        # Block-scaled GEMM with paired operands
                        tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile != 0)
                        tile_crd = (None, None, None, handle.index)
                        cute.gemm(
                            tiled_mma,
                            tCtAcc,
                            [tCrA[tile_crd], tCtSFA],
                            [tCrB[tile_crd], tCtSFB_mma],
                            tCtAcc,
                        )
                        handle.release()

                    if k_tile_cnt > 0:
                        acc_pipeline.producer_commit(acc_producer_state)
                if k_tile_cnt > 0:
                    acc_producer_state.advance()

                # Read next work_tile_info
                sched_pipeline.consumer_wait(sched_consumer_state)
                rmem = cute.make_rmem_tensor((4,), cutlass.Int32)
                cute.copy(
                    sched_copy_atom,
                    sched_buf_tensor[(None, sched_consumer_state.index)],
                    rmem,
                )
                work_tile_info = MoEWorkTileInfo.from_rmem_tensor(rmem)
                cute.arch.fence_acq_rel_cta()
                sched_pipeline.consumer_release(sched_consumer_state)
                sched_consumer_state.advance()

            acc_pipeline.producer_tail(acc_producer_state)

        # =================================================================
        # SMEM tensor C (allocated after MMA section)
        # =================================================================

        sC = smem.allocate_tensor(
            element_type=self.c_dtype,
            layout=c_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=c_smem_layout_staged.inner,
        )

        # =================================================================
        # Epilogue warps (warps 0-3)
        # =================================================================

        if warp_idx < self.mma_warp_id:
            tmem.allocate(self.num_tmem_alloc_cols)
            tmem.wait_for_alloc()
            acc_tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_pipeline_stages
            )
            sched_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_sched_stages
            )
            c_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.epilogue_warp_id),
            )
            c_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.num_c_stage, producer_group=c_producer_group
            )

            epilog_sync_barrier = pipeline.NamedBarrier(
                barrier_id=self.epilog_sync_bar_id,
                num_threads=32 * len(self.epilogue_warp_id),
            )

            # Layout transformation for epilogue
            tCtAcc_transformed = transform_partitioned_tensor_layout(tCtAcc_base)

            num_tiles_executed = cutlass.Int32(0)

            # Read initial work_tile_info
            sched_pipeline.consumer_wait(sched_consumer_state)
            rmem = cute.make_rmem_tensor((4,), cutlass.Int32)
            cute.copy(
                sched_copy_atom,
                sched_buf_tensor[(None, sched_consumer_state.index)],
                rmem,
            )
            work_tile_info = MoEWorkTileInfo.from_rmem_tensor(rmem)
            cute.arch.fence_acq_rel_cta()
            sched_pipeline.consumer_release(sched_consumer_state)
            sched_consumer_state.advance()

            while work_tile_info.is_valid_tile:
                k_tile_cnt = work_tile_info.k_tile_cnt

                # Get real C tensor + TMA desc ptr
                real_c, desc_ptr_c = ext.get_gmem_tensor(
                    "c",
                    tma_tensor_c,
                    offs_for_ext,
                    work_tile_info,
                )
                # local_tile + partition for C
                gC_mnl = cute.local_tile(
                    real_c,
                    cute.slice_(self.mma_tiler, (None, None, 0)),
                    (None, None, None),
                )
                thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
                tCgC = thr_mma.partition_C(gC_mnl)
                tCgC_transformed = transform_partitioned_tensor_layout(tCgC)

                mma_tile_coord_mnl = (
                    work_tile_info.tile_m_idx // cute.size(tiled_mma.thr_id.shape),
                    work_tile_info.tile_n_idx,
                    cutlass.Int32(0),
                )

                # Partition for TMEM → RMEM copy
                tiled_copy_t2r, tTR_tAcc_base_epi, tTR_rAcc = (
                    epilogue_tmem_copy_and_partition(
                        self,
                        tidx,
                        tCtAcc_transformed,
                        tCgC_transformed,
                        epi_tile,
                        use_2cta_instrs,
                    )
                )
                tTR_rC = cute.make_rmem_tensor(tTR_rAcc.shape, self.c_dtype)
                tiled_copy_r2s, tRS_rC, tRS_sC = epilogue_smem_copy_and_partition(
                    self, tiled_copy_t2r, tTR_rC, tidx, sC
                )

                # TMA partition for C store
                tCgC_epi = cute.flat_divide(tCgC_transformed, epi_tile)
                bSG_sC, bSG_gC_partitioned = cpasync.tma_partition(
                    tma_atom_c,
                    0,
                    cute.make_layout(1),
                    cute.group_modes(sC, 0, 2),
                    cute.group_modes(tCgC_epi, 0, 2),
                )
                bSG_gC = bSG_gC_partitioned[(None, None, None, *mma_tile_coord_mnl)]

                # Get accumulator stage index
                if cutlass.const_expr(self.overlapping_accum):
                    acc_stage_index = acc_consumer_state.phase
                    reverse_subtile = True if acc_stage_index == 0 else False
                else:
                    acc_stage_index = acc_consumer_state.index

                # Set TMEM buffer for current tile
                tTR_tAcc = tTR_tAcc_base_epi[
                    (None, None, None, None, None, acc_stage_index)
                ]

                # Wait for accumulator buffer full
                if k_tile_cnt > 0:
                    acc_pipeline.consumer_wait(acc_consumer_state)

                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                bSG_gC = cute.group_modes(bSG_gC, 1, cute.rank(bSG_gC))

                # Compute per-expert global_scale alpha for NVFP4
                if cutlass.const_expr(global_scale_a is not None):
                    expert_idx = work_tile_info.expert_idx
                    alpha = cute.arch.load(
                        global_scale_a.iterator + expert_idx,
                        cutlass.Float32,
                    ) * cute.arch.load(
                        global_scale_b.iterator + expert_idx,
                        cutlass.Float32,
                    )
                else:
                    alpha = None

                # Store accumulator to global memory in subtiles
                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                num_prev_subtiles = num_tiles_executed * subtile_cnt

                for subtile_idx in cutlass.range(subtile_cnt):
                    real_subtile_idx = subtile_idx
                    if cutlass.const_expr(self.overlapping_accum):
                        if reverse_subtile:
                            real_subtile_idx = (
                                self.cta_tile_shape_mnk[1] // self.epi_tile_n
                                - 1
                                - subtile_idx
                            )

                    # TMEM → RMEM
                    tTR_tAcc_mn = tTR_tAcc[(None, None, None, real_subtile_idx)]
                    if cutlass.const_expr(self.scenario == "2Dx2D"):
                        if k_tile_cnt > 0:
                            cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)
                    else:
                        cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)

                    # Early release for overlapping_accum
                    if cutlass.const_expr(self.overlapping_accum):
                        if subtile_idx == self.iter_acc_early_release_in_epilogue:
                            cute.arch.fence_view_async_tmem_load()
                            if k_tile_cnt > 0:
                                acc_pipeline.consumer_release(acc_consumer_state)
                                acc_consumer_state.advance()

                    # Convert to output dtype, apply global_scale
                    acc_vec = cute.zeros_like(tiled_copy_r2s.retile(tTR_rAcc))
                    if cutlass.const_expr(self.scenario == "2Dx2D"):
                        if k_tile_cnt > 0:
                            acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
                    else:
                        acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
                    if cutlass.const_expr(global_scale_a is not None):
                        acc_vec = acc_vec * alpha
                    acc_vec = acc_vec.to(self.c_dtype)
                    tRS_rC.store(acc_vec)

                    # RMEM → SMEM
                    c_buffer = (num_prev_subtiles + subtile_idx) % self.num_c_stage
                    cute.copy(
                        tiled_copy_r2s, tRS_rC, tRS_sC[(None, None, None, c_buffer)]
                    )
                    cute.arch.fence_proxy("async.shared", space="cta")
                    epilog_sync_barrier.arrive_and_wait()

                    # SMEM → GMEM (TMA store or TMA reduce)
                    if warp_idx == self.epilogue_warp_id[0]:
                        cute.copy(
                            tma_atom_c,
                            bSG_sC[(None, c_buffer)],
                            bSG_gC[(None, real_subtile_idx)],
                            tma_desc_ptr=desc_ptr_c,
                        )
                        c_pipeline.producer_commit()
                        c_pipeline.producer_acquire()
                    epilog_sync_barrier.arrive_and_wait()

                # Release accumulator buffer (non-overlapping path)
                if cutlass.const_expr(not self.overlapping_accum):
                    if k_tile_cnt > 0:
                        acc_pipeline.consumer_release(acc_consumer_state)
                        acc_consumer_state.advance()
                num_tiles_executed += cutlass.Int32(1)

                # Read next work_tile_info
                sched_pipeline.consumer_wait(sched_consumer_state)
                rmem = cute.make_rmem_tensor((4,), cutlass.Int32)
                cute.copy(
                    sched_copy_atom,
                    sched_buf_tensor[(None, sched_consumer_state.index)],
                    rmem,
                )
                work_tile_info = MoEWorkTileInfo.from_rmem_tensor(rmem)
                cute.arch.fence_acq_rel_cta()
                sched_pipeline.consumer_release(sched_consumer_state)
                sched_consumer_state.advance()

            # Wait for C store complete
            c_pipeline.producer_tail()

            # Free TMEM
            tmem.relinquish_alloc_permit()
            epilog_sync_barrier.arrive_and_wait()
            tmem.free(acc_tmem_ptr)


# =============================================================================
# Non-Kernel Part
# =============================================================================

from dataclasses import dataclass, field
import re

import numpy as np
import torch
import cutlass.torch as cutlass_torch

# =============================================================================
# Utility functions
# =============================================================================


def ceil_div(a: int, b: int) -> int:
    return (a + b - 1) // b


def round_up(a: int, b: int) -> int:
    return ceil_div(a, b) * b


def torch_version_lt(major: int, minor: int) -> bool:
    """Best-effort torch version check that tolerates local build suffixes."""
    match = re.match(r"^\s*(\d+)\.(\d+)", torch.__version__)
    if match is None:
        print(
            "WARNING: failed to parse torch.__version__, "
            "falling back to manual host reference."
        )
        return True
    version = (int(match.group(1)), int(match.group(2)))
    return version < (major, minor)


def offs_to_group_sizes(offs: torch.Tensor) -> list[int]:
    """Convert cumulative end offsets to per-group sizes."""
    offs_cpu = offs.cpu().tolist()
    prev = 0
    sizes = []
    for end in offs_cpu:
        sizes.append(end - prev)
        prev = end
    return sizes


def l2_flush(size_mb: int = 400) -> None:
    """Best-effort L2 flush by touching a large temporary tensor."""
    num_bytes = size_mb * 1024 * 1024
    flush_buf = torch.randint(0, 256, (num_bytes,), dtype=torch.uint8, device="cuda")
    del flush_buf


# =============================================================================
# Format configuration
#
# Note: For all current formats, sf_vec_size == blocksize.
# The kernel can derive sf_vec_size from blocksize directly.
# =============================================================================

_FORMAT_CONFIG = {
    "mxfp8": {
        "data_dtype": torch.float8_e4m3fn,
        "blocksize": 32,
        "scale_dtype": torch.float8_e8m0fnu,
        "has_global_scale": False,
    },
    "mxfp4": {
        "data_dtype": torch.float4_e2m1fn_x2,
        "blocksize": 32,
        "scale_dtype": torch.float8_e8m0fnu,
        "has_global_scale": False,
    },
    "nvfp4": {
        "data_dtype": torch.float4_e2m1fn_x2,
        "blocksize": 16,
        "scale_dtype": torch.float8_e4m3fn,
        "has_global_scale": True,
    },
}

# FP4 nibble encoding: value → 4-bit nibble (float4 e2m1 format)
#   0   → 0x0
#   0.5 → 0x1    1.0 → 0x2    1.5 → 0x3
#   2.0 → 0x4    3.0 → 0x5    4.0 → 0x6    6.0 → 0x7
#  -0   → 0x8   -0.5 → 0x9   -1.0 → 0xA   -1.5 → 0xB
#  -2.0 → 0xC   -3.0 → 0xD   -4.0 → 0xE   -6.0 → 0xF

# Correctness-friendly: only {0, 1, -1} → nibbles {0x0, 0x2, 0xA}
_FP4_CORRECTNESS_NIBBLES = torch.tensor([0x0, 0x2, 0xA], dtype=torch.uint8)
# Perf: all 16 valid nibbles (index == nibble value)
_FP4_PERF_NIBBLES = torch.arange(16, dtype=torch.uint8)
_FP4_DECODE_TABLE = torch.tensor(
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


# =============================================================================
# Scale shape computation
# =============================================================================


def compute_scale_shape(
    scenario: str,
    operand: str,
    group_sizes: list[int],
    hidden: int,
    intermediate: int,
    K_fixed: int,
    blocksize: int,
    expert_cnt: int,
) -> tuple[int, ...]:
    """
    Compute the assembled (swizzled 32_4_4) scale tensor shape.

    Swizzle 32_4_4 pads each group's scale to rows=round_up(non_K, 128),
    cols=round_up(ceil_div(K, blocksize), 4), then flattens per group.

    Scale layout per scenario/operand:
      2Dx3D A: groups along M (variable per expert), K fixed
               -> (sum(round_up(M_g, 128)), round_up(ceil_div(K, bs), 4))
      2Dx3D B: per-expert (K, N same for all)
               -> (G, round_up(N, 128) * round_up(ceil_div(K, bs), 4))
      2Dx2D A: M fixed, groups along K (variable per expert)
               -> (round_up(M, 128), sum(round_up(ceil_div(K_g, bs), 4)))
      2Dx2D B: N fixed, groups along K (variable per expert)
               -> (round_up(N, 128), sum(round_up(ceil_div(K_g, bs), 4)))

    Args:
        scenario: "2Dx3D" or "2Dx2D"
        operand: "a" or "b"
        group_sizes: per-expert sizes of the grouped dimension
                     (M sizes for 2Dx3D, K sizes for 2Dx2D)
        hidden: M dimension (hidden_size)
        intermediate: N dimension (intermediate_size)
        K_fixed: K dimension (used where K is fixed across experts)
        blocksize: 32 for MXFP8/MXFP4, 16 for NVFP4
        expert_cnt: number of experts (G)
    """
    if scenario == "2Dx3D":
        # group_sizes = per-expert M sizes; K is fixed for all experts
        if operand == "a":
            total_rows = sum(round_up(mg, 128) for mg in group_sizes)
            total_cols = round_up(ceil_div(K_fixed, blocksize), 4)
            return (total_rows, total_cols)
        else:
            padded_N = round_up(intermediate, 128)
            padded_K_scale = round_up(ceil_div(K_fixed, blocksize), 4)
            return (expert_cnt, padded_N * padded_K_scale)
    else:  # 2Dx2D
        # group_sizes = per-expert K sizes; M and N are fixed
        if operand == "a":
            padded_M = round_up(hidden, 128)
            total_cols = sum(round_up(ceil_div(kg, blocksize), 4) for kg in group_sizes)
            return (padded_M, total_cols)
        else:
            padded_N = round_up(intermediate, 128)
            total_cols = sum(round_up(ceil_div(kg, blocksize), 4) for kg in group_sizes)
            return (padded_N, total_cols)


def to_blocked(scale_2d: torch.Tensor) -> torch.Tensor:
    """Pad and apply the Blackwell 32_4_4 scale swizzle to one raw scale tensor."""
    if scale_2d.dim() != 2:
        raise ValueError(f"Expected 2D scale tensor, got {scale_2d.dim()}D.")
    rows, cols = scale_2d.shape
    if rows == 0 or cols == 0:
        return scale_2d.new_empty((0,))

    row_blocks = ceil_div(rows, 128)
    col_blocks = ceil_div(cols, 4)
    padded_rows = row_blocks * 128
    padded_cols = col_blocks * 4

    padded = scale_2d
    if (rows, cols) != (padded_rows, padded_cols):
        padded = torch.zeros(
            (padded_rows, padded_cols), dtype=scale_2d.dtype, device=scale_2d.device
        )
        padded[:rows, :cols] = scale_2d

    blocks = padded.view(row_blocks, 128, col_blocks, 4).permute(0, 2, 1, 3)
    rearranged = blocks.reshape(-1, 4, 32, 4).transpose(1, 2).reshape(-1, 32, 16)
    return rearranged.flatten()


def pad_and_swizzle_single(raw_scale_2d: torch.Tensor) -> torch.Tensor:
    if raw_scale_2d.dim() != 2:
        raise ValueError(f"Expected 2D scale tensor, got {raw_scale_2d.dim()}D.")
    return to_blocked(raw_scale_2d)


def create_raw_scale_tensor(
    non_k_size: int,
    k_size: int,
    blocksize: int,
    scale_dtype: torch.dtype,
    device: str = "cuda",
) -> torch.Tensor:
    """Create one raw, non-swizzled scale tensor with exact values in {1, 2}."""
    scale_cols = ceil_div(k_size, blocksize)
    return (
        torch.randint(
            1,
            3,
            (non_k_size, scale_cols),
            dtype=torch.float32,
            device=device,
        )
        .to(scale_dtype)
        .reshape(non_k_size, scale_cols)
    )


def cat_byte_reinterpretable_tensors(
    tensors: list[torch.Tensor], dim: int = 0
) -> torch.Tensor:
    """Concatenate byte-backed float tensors via uint8 view when native cat is unsupported."""
    if not tensors:
        raise ValueError("Expected at least one tensor to concatenate.")
    first = tensors[0]
    if first.is_floating_point() and first.element_size() == 1:
        concatenated = torch.cat(
            [tensor.view(torch.uint8) for tensor in tensors], dim=dim
        )
        return concatenated.view(first.dtype)
    return torch.cat(tensors, dim=dim)


def stack_byte_reinterpretable_tensors(
    tensors: list[torch.Tensor], dim: int = 0
) -> torch.Tensor:
    """Stack byte-backed float tensors via uint8 view when native stack is unsupported."""
    if not tensors:
        raise ValueError("Expected at least one tensor to stack.")
    first = tensors[0]
    if first.is_floating_point() and first.element_size() == 1:
        stacked = torch.stack([tensor.view(torch.uint8) for tensor in tensors], dim=dim)
        return stacked.view(first.dtype)
    return torch.stack(tensors, dim=dim)


def assemble_raw_scales_2d2d(
    raw_scales: list[torch.Tensor], non_k_size: int
) -> torch.Tensor:
    flat_parts = [pad_and_swizzle_single(scale) for scale in raw_scales]
    all_flat = cat_byte_reinterpretable_tensors(flat_parts, dim=0)
    return all_flat.reshape(round_up(non_k_size, 128), -1)


def assemble_raw_scales_2d3d_3d_side(raw_scales: list[torch.Tensor]) -> torch.Tensor:
    flat_parts = [pad_and_swizzle_single(scale) for scale in raw_scales]
    return stack_byte_reinterpretable_tensors(flat_parts, dim=0)


def assemble_raw_scales_2d3d_2d_side(raw_scales: list[torch.Tensor]) -> torch.Tensor:
    flat_parts = [pad_and_swizzle_single(scale) for scale in raw_scales]
    all_flat = cat_byte_reinterpretable_tensors(flat_parts, dim=0)
    total_rows = sum(round_up(scale.shape[0], 128) for scale in raw_scales)
    return all_flat.reshape(total_rows, -1)


def fp4_packed_dim(tensor: torch.Tensor) -> int:
    positive_strides = [
        (abs(stride), idx) for idx, stride in enumerate(tensor.stride()) if stride > 0
    ]
    if not positive_strides:
        return tensor.dim() - 1
    return min(positive_strides)[1]


def unpack_fp4_to_f32(packed: torch.Tensor) -> torch.Tensor:
    """Unpack a float4_e2m1fn_x2 tensor into float32 along the packed dimension."""
    packed_dim = fp4_packed_dim(packed)
    raw = packed.view(torch.uint8)

    if packed_dim != raw.dim() - 1:
        perm = list(range(raw.dim()))
        perm[packed_dim], perm[-1] = perm[-1], perm[packed_dim]
        raw = raw.permute(perm).contiguous()
    else:
        perm = None

    lo = (raw & 0x0F).to(torch.int64)
    hi = (raw >> 4).to(torch.int64)
    lut = _FP4_DECODE_TABLE.to(raw.device)

    unpacked_shape = list(raw.shape)
    unpacked_shape[-1] *= 2
    unpacked = torch.empty(unpacked_shape, dtype=torch.float32, device=raw.device)
    unpacked[..., ::2] = lut[lo]
    unpacked[..., 1::2] = lut[hi]

    if perm is not None:
        unpacked = unpacked.permute(perm)
    return unpacked


def slice_tensor_logical_dim(
    tensor: torch.Tensor, dim: int, start: int, end: int
) -> torch.Tensor:
    """Slice along the logical dimension, compensating for FP4 packing when needed."""
    if tensor.dtype == torch.float4_e2m1fn_x2 and dim == fp4_packed_dim(tensor):
        if start % 2 != 0 or end % 2 != 0:
            raise ValueError(
                f"FP4 packed slicing requires even indices, got start={start}, end={end}."
            )
        start = start // 2
        end = end // 2
    return tensor.narrow(dim, start, end - start)


def dequant_block_scale_to_fp32(
    data: torch.Tensor,
    raw_scale: torch.Tensor,
    blocksize: int,
    global_scale: Optional[torch.Tensor] = None,
) -> torch.Tensor:
    """Dequantize a single 2D tensor using raw block scales into fp32."""
    if data.dtype == torch.float4_e2m1fn_x2:
        data_fp32 = unpack_fp4_to_f32(data)
    else:
        data_fp32 = data.to(torch.float32)

    if data_fp32.dim() != 2 or raw_scale.dim() != 2:
        raise ValueError(
            f"Expected 2D tensors, got data={data_fp32.dim()}D raw_scale={raw_scale.dim()}D."
        )

    expected_scale_shape = (data_fp32.shape[0], ceil_div(data_fp32.shape[1], blocksize))
    if tuple(raw_scale.shape) != expected_scale_shape:
        raise ValueError(
            f"Scale shape mismatch: expected {expected_scale_shape}, got {tuple(raw_scale.shape)}."
        )

    scale_fp32 = raw_scale.to(torch.float32)
    expanded_scale = scale_fp32.repeat_interleave(blocksize, dim=-1)[
        :, : data_fp32.shape[1]
    ]
    result = data_fp32 * expanded_scale

    if global_scale is not None:
        result = result * global_scale.to(torch.float32).reshape(1, 1)
    return result


def transpose_rhs_for_block_dequant(data: torch.Tensor) -> torch.Tensor:
    """Convert a (K, N) RHS slice into an (N, K) tensor for block dequant along K."""
    if data.dim() != 2:
        raise ValueError(f"Expected 2D RHS tensor, got {data.dim()}D.")
    if data.dtype == torch.float4_e2m1fn_x2:
        # Avoid contiguous()/copy_ on FP4 tensors; unpack first, then transpose in fp32.
        return unpack_fp4_to_f32(data).transpose(0, 1)
    return data.transpose(0, 1)


# =============================================================================
# Host Validation
# =============================================================================


@dataclass
class ProblemDesc:
    tokens: int
    experts: int
    top_k_select: int
    balance_route: bool
    hidden: int
    intermediate: int
    scenario: Literal["2Dx3D", "2Dx2D"]
    kind: Literal["mxfp8", "mxfp4", "nvfp4"]
    out_dtype: torch.dtype = torch.bfloat16
    acc_dtype: torch.dtype = torch.float32
    grad_accumulate: bool = False
    # If True, the user guarantees activation tensors (with tokens_sum dim)
    # are padded per-group to the same granularity as the block-scale layout:
    #   2Dx3D (groups along M): each group's M_g padded to 128
    #   2Dx2D (groups along K): each group's K_g padded to sf_vec_size * 4
    # This enables the kernel to skip padded-offset computation.
    # Currently NOT implemented — forced to False at CLI level.
    consistent_token_padding: bool = False
    # GEMM-domain layout control (which axis is stride-1)
    # Only effective for FP8.  FP4 always uses the torch-expected layout
    # (K stride-1 for both A and B).
    #   A (M, K): "k_major" → K stride-1 (default)  |  "m_major" → M stride-1
    #   B (N, K): "k_major" → K stride-1 (default)   |  "n_major" → N stride-1
    #   C (M, N): "n_major" → N stride-1 (default)   |  "m_major" → M stride-1
    # Note: default b_layout is "k_major" (unlike torch_grouped_mm.py's "n_major")
    # because torch.nn.functional.scaled_grouped_mm expects K stride-1 for B.
    a_layout: Literal["k_major", "m_major"] = "k_major"
    b_layout: Literal["k_major", "n_major"] = "k_major"
    c_layout: Literal["n_major", "m_major"] = "n_major"

    def __str__(self) -> str:
        d = lambda t: str(t).split(".")[-1]
        route = "balanced" if self.balance_route else "random"
        return (
            f"ProblemDesc: {self.scenario} | kind={self.kind} | "
            f"tokens={self.tokens} experts={self.experts} "
            f"top_k={self.top_k_select} route={route} | "
            f"hidden={self.hidden} intermediate={self.intermediate} | "
            f"out={d(self.out_dtype)} acc={d(self.acc_dtype)} "
            f"grad_acc={self.grad_accumulate} "
            f"consistent_pad={self.consistent_token_padding} | "
            f"layout: A={self.a_layout} B={self.b_layout} C={self.c_layout}"
        )


@dataclass
class ImplDesc:
    mma_tiler_mnk: Tuple[int, int, int] = (128, 128, 64)
    cluster_shape_mnk: Tuple[int, int, int] = (1, 1, 1)
    use_2cta_instrs: bool = False
    static_expert_cnt: Optional[int] = None
    separate_tensormap_init: bool = True

    def __str__(self) -> str:
        tile = ",".join(map(str, self.mma_tiler_mnk))
        cluster = ",".join(map(str, self.cluster_shape_mnk))
        static_e = (
            self.static_expert_cnt if self.static_expert_cnt is not None else "dynamic"
        )
        return (
            f"ImplDesc: tile={tile} cluster={cluster} "
            f"2cta={self.use_2cta_instrs} | "
            f"static_E={static_e} sep_tmap={self.separate_tensormap_init}"
        )


@dataclass
class MiscDesc:
    perf_run: bool = False
    perf_e2e: bool = False
    compare_with_sol: bool = False
    no_torch_210: bool = field(init=False)

    def __post_init__(self):
        self.no_torch_210 = torch_version_lt(2, 10)
        if self.perf_e2e and not self.perf_run:
            raise ValueError("--perf_e2e requires --perf_run to be enabled.")
        if self.perf_e2e and self.compare_with_sol:
            raise ValueError(
                "--perf_e2e and --compare_with_sol are mutually exclusive."
            )

    def __str__(self) -> str:
        return (
            f"MiscDesc: perf={self.perf_run} perf_e2e={self.perf_e2e} "
            f"sol={self.compare_with_sol} no_torch_210={self.no_torch_210}"
        )


class ScaledGroupedGemmTester:
    def __init__(self, problem: ProblemDesc, impl: ImplDesc, misc: MiscDesc):
        self.problem = problem
        self.impl = impl
        self.misc = misc

        self.cfg = _FORMAT_CONFIG[problem.kind]
        self.tokens_after_repeat = problem.tokens * problem.top_k_select
        self.expert_cnt = problem.experts
        self.hidden = problem.hidden
        self.intermediate = problem.intermediate

        self.A_tensor: Optional[torch.Tensor] = None
        self.B_tensor: Optional[torch.Tensor] = None
        self.C_tensor: Optional[torch.Tensor] = None
        self.C_ref_tensor: Optional[torch.Tensor] = None
        self.scale_a_tensor: Optional[torch.Tensor] = None
        self.scale_b_tensor: Optional[torch.Tensor] = None
        self.raw_scale_a_tensors: Optional[list[torch.Tensor]] = None
        self.raw_scale_b_tensors: Optional[list[torch.Tensor]] = None
        self.global_scale_a: Optional[torch.Tensor] = None
        self.global_scale_b: Optional[torch.Tensor] = None
        self.offs_tensor: Optional[torch.Tensor] = None
        self.workspace_tensor: Optional[torch.Tensor] = None

        if problem.grad_accumulate and problem.scenario == "2Dx3D":
            raise ValueError(
                "grad_accumulate only makes sense for 2Dx2D (weight grad) scenario."
            )

    # -----------------------------------------------------------------
    # Offs generation (aligned to blocksize)
    # -----------------------------------------------------------------

    def _generate_offs(self) -> torch.Tensor:
        """Generate group-end offsets aligned to blocksize.

        Some experts may receive 0 tokens (valid in real MoE routing).
        Each non-empty group's size is a multiple of blocksize.
        """
        blocksize = self.cfg["blocksize"]
        total = self.tokens_after_repeat
        expert_cnt = self.expert_cnt

        assert total % blocksize == 0, (
            f"tokens_after_repeat ({total}) must be divisible by "
            f"blocksize ({blocksize})"
        )
        n_slots = total // blocksize

        if self.problem.balance_route:
            # Distribute as evenly as possible; some experts get 0 if n_slots < expert_cnt
            base = n_slots // expert_cnt
            remainder = n_slots % expert_cnt
            slots = [base + (1 if i < remainder else 0) for i in range(expert_cnt)]
        else:
            # Dirichlet distribution: naturally allows 0-size groups
            # alpha=1.0 → uniform on simplex (moderate variation)
            # alpha<1.0 → skewed (few experts get most tokens)
            # alpha>1.0 → more uniform
            proportions = np.random.dirichlet([0.5] * expert_cnt)
            raw = np.floor(proportions * n_slots).astype(int)
            deficit = n_slots - raw.sum()
            while deficit > 0:
                idx = int(np.argmin(raw / (proportions * n_slots + 1e-12)))
                raw[idx] += 1
                deficit -= 1
            while deficit < 0:
                ratios = np.where(
                    raw > 0,
                    raw / (proportions * n_slots + 1e-12),
                    -np.inf,
                )
                idx = int(np.argmax(ratios))
                raw[idx] -= 1
                deficit += 1
            slots = raw.tolist()

        assert sum(slots) == n_slots

        cum = 0
        offsets = []
        for s in slots:
            cum += s * blocksize
            offsets.append(cum)
        return torch.tensor(offsets, dtype=torch.int32, device="cuda")

    # -----------------------------------------------------------------
    # Tensor creation helpers
    # -----------------------------------------------------------------

    def _create_fp8_tensor(self, shape: tuple) -> torch.Tensor:
        """Create FP8 tensor.

        - correctness mode: randint {-1, 0, 1} via bf16 cast
        - perf mode: random valid fp8 bit patterns via uint8
          (float8_e4m3fn NaN encodings 0x7F/0xFF are replaced)
        """
        data_dtype = self.cfg["data_dtype"]
        elem_cnt = 1
        for s in shape:
            elem_cnt *= s
        if self.misc.perf_run:
            raw = torch.randint(0, 256, (elem_cnt,), dtype=torch.uint8, device="cuda")
            # float8_e4m3fn: 0x7F and 0xFF are NaN → clamp to valid max
            if data_dtype == torch.float8_e4m3fn:
                raw[raw == 0x7F] = 0x7E
                raw[raw == 0xFF] = 0xFE
            return raw.view(data_dtype).reshape(shape)
        else:
            return (
                torch.randint(-1, 2, (elem_cnt,), dtype=torch.bfloat16, device="cuda")
                .to(data_dtype)
                .reshape(shape)
            )

    def _create_fp4_tensor(
        self, logical_shape: tuple, packed_dim: int = -1
    ) -> torch.Tensor:
        """Create FP4 tensor.

        Args:
            logical_shape: shape in FP4 elements (packed_dim size must be even).
            packed_dim: dimension to pack (halve). This dim becomes stride-1.

        - perf mode: random uint8 bytes (all 256 values are valid FP4 pairs,
          FP4 e2m1 has no NaN/inf). No nibble mapping needed.
        - correctness mode: index→nibble mapping for values {0, 1, -1},
          then explicit nibble packing.

        Returns:
            float4_e2m1fn_x2 tensor with packed_dim halved and stride-1.
        """
        ndim = len(logical_shape)
        packed_dim = packed_dim % ndim
        assert logical_shape[packed_dim] % 2 == 0, (
            f"packed_dim {packed_dim} size ({logical_shape[packed_dim]}) must be even"
        )

        if self.misc.perf_run:
            # All 256 byte values are valid FP4 pairs — just random bytes
            elem_cnt = 1
            for s in logical_shape:
                elem_cnt *= s
            byte_cnt = elem_cnt // 2

            flat = torch.randint(0, 256, (byte_cnt,), dtype=torch.uint8, device="cuda")

            # Build shape with packed dim moved to last and halved
            shape_reordered = list(logical_shape)
            need_perm = packed_dim != ndim - 1
            if need_perm:
                shape_reordered[packed_dim], shape_reordered[-1] = (
                    shape_reordered[-1],
                    shape_reordered[packed_dim],
                )
            shape_reordered[-1] //= 2

            tensor = flat.view(torch.float4_e2m1fn_x2).reshape(shape_reordered)

            if need_perm:
                perm = list(range(ndim))
                perm[packed_dim], perm[-1] = perm[-1], perm[packed_dim]
                tensor = tensor.permute(perm)
            return tensor

        # ── Correctness mode: index→nibble mapping + explicit pack ──
        # Use uint8 + masked_fill_ instead of int64 fancy indexing to avoid
        # 16x memory overhead (int64 = 8 bytes vs FP4 = 0.5 bytes per element).

        nibbles = torch.randint(0, 3, logical_shape, dtype=torch.uint8, device="cuda")
        nibbles.masked_fill_(nibbles == 2, 0xA)
        nibbles.masked_fill_(nibbles == 1, 0x2)

        # Move packed_dim to last for packing
        need_perm = packed_dim != ndim - 1
        if need_perm:
            perm_to_last = list(range(ndim))
            perm_to_last[packed_dim], perm_to_last[-1] = (
                perm_to_last[-1],
                perm_to_last[packed_dim],
            )
            nibbles = nibbles.permute(perm_to_last).contiguous()

        # Pack pairs along last dim: byte = (odd_nibble << 4) | even_nibble
        even = nibbles[..., ::2]
        odd = nibbles[..., 1::2]
        packed_uint8 = (odd << 4) | even

        tensor = packed_uint8.view(torch.float4_e2m1fn_x2)

        if need_perm:
            inv_perm = list(range(ndim))
            inv_perm[packed_dim], inv_perm[-1] = inv_perm[-1], inv_perm[packed_dim]
            tensor = tensor.permute(inv_perm)

        return tensor

    def _create_scale_tensor(self, shape: tuple) -> torch.Tensor:
        """Scale tensor: random values {1, 2} (exact in all scale dtypes)."""
        elem_cnt = 1
        for s in shape:
            elem_cnt *= s
        return (
            torch.randint(1, 3, (elem_cnt,), dtype=torch.float32, device="cuda")
            .to(self.cfg["scale_dtype"])
            .reshape(shape)
        )

    def _generate_raw_scales(
        self, group_sizes: list[int]
    ) -> tuple[list[torch.Tensor], list[torch.Tensor]]:
        blocksize = self.cfg["blocksize"]
        scale_dtype = self.cfg["scale_dtype"]
        device = self.A_tensor.device.type if self.A_tensor is not None else "cuda"

        if self.problem.scenario == "2Dx3D":
            raw_scale_a = [
                create_raw_scale_tensor(
                    non_k_size=group_size,
                    k_size=self.hidden,
                    blocksize=blocksize,
                    scale_dtype=scale_dtype,
                    device=device,
                )
                for group_size in group_sizes
            ]
            raw_scale_b = [
                create_raw_scale_tensor(
                    non_k_size=self.intermediate,
                    k_size=self.hidden,
                    blocksize=blocksize,
                    scale_dtype=scale_dtype,
                    device=device,
                )
                for _ in range(self.expert_cnt)
            ]
        else:
            raw_scale_a = [
                create_raw_scale_tensor(
                    non_k_size=self.hidden,
                    k_size=group_size,
                    blocksize=blocksize,
                    scale_dtype=scale_dtype,
                    device=device,
                )
                for group_size in group_sizes
            ]
            raw_scale_b = [
                create_raw_scale_tensor(
                    non_k_size=self.intermediate,
                    k_size=group_size,
                    blocksize=blocksize,
                    scale_dtype=scale_dtype,
                    device=device,
                )
                for group_size in group_sizes
            ]

        return raw_scale_a, raw_scale_b

    def _assemble_scales_from_raw(
        self, raw_scale_a: list[torch.Tensor], raw_scale_b: list[torch.Tensor]
    ) -> tuple[torch.Tensor, torch.Tensor]:
        if self.problem.scenario == "2Dx3D":
            scale_a = assemble_raw_scales_2d3d_2d_side(raw_scale_a)
            scale_b = assemble_raw_scales_2d3d_3d_side(raw_scale_b)
        else:
            scale_a = assemble_raw_scales_2d2d(raw_scale_a, self.hidden)
            scale_b = assemble_raw_scales_2d2d(raw_scale_b, self.intermediate)
        return scale_a, scale_b

    # -----------------------------------------------------------------
    # generate_inputs
    # -----------------------------------------------------------------

    def generate_inputs(self) -> None:
        self.offs_tensor = self._generate_offs()
        group_sizes = offs_to_group_sizes(self.offs_tensor)

        tokens = self.tokens_after_repeat
        hidden = self.hidden
        intermediate = self.intermediate
        expert_cnt = self.expert_cnt
        blocksize = self.cfg["blocksize"]
        is_fp4 = self.cfg["data_dtype"] == torch.float4_e2m1fn_x2

        if is_fp4:
            if self.problem.a_layout != "k_major":
                print("WARNING: FP4 ignores a_layout, always uses k_major (K stride-1)")
            if self.problem.b_layout != "k_major":
                print("WARNING: FP4 ignores b_layout, always uses k_major (K stride-1)")

        if self.problem.scenario == "2Dx3D":
            # ── Data tensors ──
            # PyTorch: A (tokens, hidden), B (expert_cnt, hidden, intermediate)
            # GEMM:    A (M=tokens, K=hidden), B (N=intermediate, K=hidden, L=expert_cnt)

            # A: (tokens, hidden) — K=hidden is last dim
            if is_fp4:
                self.A_tensor = self._create_fp4_tensor((tokens, hidden), packed_dim=-1)
            elif self.problem.a_layout == "k_major":
                self.A_tensor = self._create_fp8_tensor((tokens, hidden))
            else:  # m_major
                self.A_tensor = self._create_fp8_tensor((hidden, tokens)).T

            # B: (expert_cnt, hidden, intermediate) — K=hidden is dim 1
            if is_fp4:
                self.B_tensor = self._create_fp4_tensor(
                    (expert_cnt, hidden, intermediate), packed_dim=1
                )
            elif self.problem.b_layout == "k_major":
                self.B_tensor = self._create_fp8_tensor(
                    (expert_cnt, intermediate, hidden)
                ).transpose(1, 2)
            else:  # n_major
                self.B_tensor = self._create_fp8_tensor(
                    (expert_cnt, hidden, intermediate)
                )

            # C: (tokens, intermediate)
            # GEMM C (M=tokens, N=intermediate): n_major → N stride-1; m_major → M stride-1
            if self.problem.c_layout == "n_major":
                self.C_tensor = torch.full(
                    (tokens, intermediate),
                    -1,
                    dtype=self.problem.out_dtype,
                    device="cuda",
                )
            else:  # m_major
                self.C_tensor = torch.full(
                    (intermediate, tokens),
                    -1,
                    dtype=self.problem.out_dtype,
                    device="cuda",
                ).T

            # ── Scale tensors ──
            K_fixed = hidden
            sfa_shape = compute_scale_shape(
                "2Dx3D",
                "a",
                group_sizes,
                hidden,
                intermediate,
                K_fixed,
                blocksize,
                expert_cnt,
            )
            sfb_shape = compute_scale_shape(
                "2Dx3D",
                "b",
                group_sizes,
                hidden,
                intermediate,
                K_fixed,
                blocksize,
                expert_cnt,
            )

        elif self.problem.scenario == "2Dx2D":
            # ── Data tensors ──
            # PyTorch: A (hidden, tokens), B (tokens, intermediate)
            # GEMM:    A (M=hidden, K=tokens), B (N=intermediate, K=tokens, L=expert_cnt)

            # A: (hidden, tokens) — K=tokens is last dim
            if is_fp4:
                self.A_tensor = self._create_fp4_tensor((hidden, tokens), packed_dim=-1)
            elif self.problem.a_layout == "k_major":
                self.A_tensor = self._create_fp8_tensor((hidden, tokens))
            else:  # m_major
                self.A_tensor = self._create_fp8_tensor((tokens, hidden)).T

            # B: (tokens, intermediate) — K=tokens is dim 0
            if is_fp4:
                self.B_tensor = self._create_fp4_tensor(
                    (tokens, intermediate), packed_dim=0
                )
            elif self.problem.b_layout == "k_major":
                self.B_tensor = self._create_fp8_tensor((intermediate, tokens)).T
            else:  # n_major
                self.B_tensor = self._create_fp8_tensor((tokens, intermediate))

            # C: (expert_cnt, hidden, intermediate)
            # GEMM C (M=hidden, N=intermediate): n_major → N stride-1; m_major → M stride-1
            if self.problem.c_layout == "n_major":
                if self.problem.grad_accumulate:
                    self.C_tensor = torch.zeros(
                        (expert_cnt, hidden, intermediate),
                        dtype=self.problem.out_dtype,
                        device="cuda",
                    )
                else:
                    self.C_tensor = torch.full(
                        (expert_cnt, hidden, intermediate),
                        -1,
                        dtype=self.problem.out_dtype,
                        device="cuda",
                    )
            else:  # m_major
                if self.problem.grad_accumulate:
                    self.C_tensor = torch.zeros(
                        (expert_cnt, intermediate, hidden),
                        dtype=self.problem.out_dtype,
                        device="cuda",
                    ).transpose(1, 2)
                else:
                    self.C_tensor = torch.full(
                        (expert_cnt, intermediate, hidden),
                        -1,
                        dtype=self.problem.out_dtype,
                        device="cuda",
                    ).transpose(1, 2)

            # ── Scale tensors ──
            K_total = tokens
            sfa_shape = compute_scale_shape(
                "2Dx2D",
                "a",
                group_sizes,
                hidden,
                intermediate,
                K_total,
                blocksize,
                expert_cnt,
            )
            sfb_shape = compute_scale_shape(
                "2Dx2D",
                "b",
                group_sizes,
                hidden,
                intermediate,
                K_total,
                blocksize,
                expert_cnt,
            )
        else:
            raise ValueError(f"Unknown scenario: {self.problem.scenario}")

        self.raw_scale_a_tensors, self.raw_scale_b_tensors = self._generate_raw_scales(
            group_sizes
        )
        self.scale_a_tensor, self.scale_b_tensor = self._assemble_scales_from_raw(
            self.raw_scale_a_tensors, self.raw_scale_b_tensors
        )
        assert tuple(self.scale_a_tensor.shape) == tuple(sfa_shape), (
            f"scale_a shape mismatch: expected {sfa_shape}, "
            f"got {tuple(self.scale_a_tensor.shape)}"
        )
        assert tuple(self.scale_b_tensor.shape) == tuple(sfb_shape), (
            f"scale_b shape mismatch: expected {sfb_shape}, "
            f"got {tuple(self.scale_b_tensor.shape)}"
        )

        # NVFP4: per-expert global scales
        if self.cfg["has_global_scale"]:
            self.global_scale_a = torch.randint(
                1, 3, (expert_cnt,), dtype=torch.float32, device="cuda"
            )
            self.global_scale_b = torch.randint(
                1, 3, (expert_cnt,), dtype=torch.float32, device="cuda"
            )

    # -----------------------------------------------------------------
    # Reference preparation
    # -----------------------------------------------------------------

    @staticmethod
    def _prepare_ref_ab(
        tensor: torch.Tensor,
        k_dim: int,
        pad_k_size: Optional[int] = None,
        pad_non_k_size: Optional[int] = None,
    ) -> torch.Tensor:
        """Prepare a ref tensor: make ``k_dim`` stride-1 and optionally pad.

        Args:
            tensor: input data tensor (A or B).
            k_dim: which dimension is K (must become stride-1).
            pad_k_size: zero-pad K to this size (workaround: PyTorch 3D
                scale validation uses floor division for K // blocksize).
            pad_non_k_size: zero-pad the trailing dim (N) to this size
                (workaround: PyTorch requires trailing dim % 16 == 0).
                Only effective when ``k_dim`` is not the trailing dim.

        All padding happens in the permuted-contiguous space (standard layout)
        so it is safe for packed sub-byte types like float4_e2m1fn_x2.
        After permute(k_dim↔last), K is last and N is second-to-last:
          F.pad(t, (0, k_pad))        -> pads K (last dim)
          F.pad(t, (0, 0, 0, n_pad)) -> pads N (second-to-last dim)
        The final permute restores the original dim order with K stride-1.
        """
        ndim = tensor.dim()
        k_dim = k_dim % ndim
        needs_k_pad = pad_k_size is not None and pad_k_size > tensor.shape[k_dim]
        needs_n_pad = (
            pad_non_k_size is not None
            and k_dim != ndim - 1
            and pad_non_k_size > tensor.shape[-1]
        )
        if tensor.stride(k_dim) == 1 and not needs_k_pad and not needs_n_pad:
            return tensor
        print(
            f"WARNING: _prepare_ref_ab is copying/padding k_dim={k_dim} "
            f"(stride={tensor.stride(k_dim)}, "
            f"pad_k={'yes' if needs_k_pad else 'no'}, "
            f"pad_n={'yes' if needs_n_pad else 'no'}); "
            f"perf comparison with the kernel is not apples-to-apples."
        )
        perm = list(range(ndim))
        perm[k_dim], perm[-1] = perm[-1], perm[k_dim]
        orig_dtype = tensor.dtype
        t = tensor.permute(perm).contiguous()
        if needs_k_pad or needs_n_pad:
            t = t.view(torch.uint8)
            if needs_k_pad:
                t = torch.nn.functional.pad(t, (0, pad_k_size - t.shape[-1]))
            if needs_n_pad:
                t = torch.nn.functional.pad(t, (0, 0, 0, pad_non_k_size - t.shape[-2]))
            t = t.view(orig_dtype)
        res = t.permute(perm)
        return res

    def _prepare_ref_tensors(
        self,
    ) -> tuple[torch.Tensor, torch.Tensor]:
        """Prepare A and B for torch.nn.functional.scaled_grouped_mm.

        The torch API requires K to be stride-1 for both A and B.
        For FP8 with non-standard layout, we permute+contiguous.
        For FP4, tensors are already created with K stride-1.

        WORKAROUND (two PyTorch bugs in scaled_grouped_mm):
        1. 3D scale validation uses K // blocksize (floor) instead of ceil_div,
           producing zero-sized expectations when K < blocksize.
           Fix: zero-pad data along K to the next blocksize multiple.
           Safe because K is the reduction dimension (zero * scale = zero).
        2. Requires mat_a.size(-1) % 16 == 0 and mat_b.size(-1) % 16 == 0
           regardless of which dimension is stride-1.
           Fix: zero-pad B's trailing dim (N=intermediate) to next 16-multiple.
           Safe because padded N columns produce zero output columns; the
           reference output is sliced back in compute_reference.
        """
        blocksize = self.cfg["blocksize"]
        # For the torch's incomplete and unreasonable check.
        N_padded = round_up(self.problem.intermediate, 16)

        if self.problem.scenario == "2Dx3D":
            K_padded = round_up(self.problem.hidden, blocksize)
            if self.problem.kind in ["nvfp4", "mxfp4"]:
                K_padded = K_padded // 2
            # A: (tokens, hidden) — K=hidden is dim -1
            ref_a = self._prepare_ref_ab(self.A_tensor, k_dim=-1, pad_k_size=K_padded)
            # B: (expert_cnt, hidden, intermediate) — K=hidden dim 1, N=intermediate dim -1
            ref_b = self._prepare_ref_ab(
                self.B_tensor, k_dim=1, pad_k_size=K_padded, pad_non_k_size=N_padded
            )
        else:
            # A: (hidden, tokens) — K=tokens is dim -1
            # 2Dx2D: K=total_tokens, already blocksize-aligned by _generate_offs
            ref_a = self._prepare_ref_ab(self.A_tensor, k_dim=-1)
            # B: (tokens, intermediate) — K=tokens dim 0, N=intermediate dim -1
            ref_b = self._prepare_ref_ab(
                self.B_tensor, k_dim=0, pad_non_k_size=N_padded
            )
        return ref_a, ref_b

    def _compute_reference_manual_2d2d(self) -> torch.Tensor:
        group_sizes = offs_to_group_sizes(self.offs_tensor)
        results = []
        prev = 0
        blocksize = self.cfg["blocksize"]

        for expert_idx, group_size in enumerate(group_sizes):
            cur = prev + group_size
            a_slice = slice_tensor_logical_dim(
                self.A_tensor, dim=1, start=prev, end=cur
            )
            b_slice = slice_tensor_logical_dim(
                self.B_tensor, dim=0, start=prev, end=cur
            )

            global_scale_a = (
                self.global_scale_a[expert_idx : expert_idx + 1]
                if self.global_scale_a is not None
                else None
            )
            global_scale_b = (
                self.global_scale_b[expert_idx : expert_idx + 1]
                if self.global_scale_b is not None
                else None
            )

            a_fp32 = dequant_block_scale_to_fp32(
                a_slice,
                self.raw_scale_a_tensors[expert_idx],
                blocksize,
                global_scale_a,
            )
            b_fp32_t = dequant_block_scale_to_fp32(
                transpose_rhs_for_block_dequant(b_slice),
                self.raw_scale_b_tensors[expert_idx],
                blocksize,
                global_scale_b,
            )
            b_fp32 = b_fp32_t.transpose(0, 1)
            results.append((a_fp32 @ b_fp32).to(self.problem.out_dtype))
            prev = cur

        return torch.stack(results, dim=0)

    def _compute_reference_manual_2d3d(self) -> torch.Tensor:
        group_sizes = offs_to_group_sizes(self.offs_tensor)
        results = []
        prev = 0
        blocksize = self.cfg["blocksize"]

        for expert_idx, group_size in enumerate(group_sizes):
            cur = prev + group_size
            a_slice = slice_tensor_logical_dim(
                self.A_tensor, dim=0, start=prev, end=cur
            )
            b_slice = self.B_tensor[expert_idx]

            global_scale_a = (
                self.global_scale_a[expert_idx : expert_idx + 1]
                if self.global_scale_a is not None
                else None
            )
            global_scale_b = (
                self.global_scale_b[expert_idx : expert_idx + 1]
                if self.global_scale_b is not None
                else None
            )

            a_fp32 = dequant_block_scale_to_fp32(
                a_slice,
                self.raw_scale_a_tensors[expert_idx],
                blocksize,
                global_scale_a,
            )
            b_fp32_t = dequant_block_scale_to_fp32(
                transpose_rhs_for_block_dequant(b_slice),
                self.raw_scale_b_tensors[expert_idx],
                blocksize,
                global_scale_b,
            )
            b_fp32 = b_fp32_t.transpose(0, 1)
            results.append((a_fp32 @ b_fp32).to(self.problem.out_dtype))
            prev = cur

        return torch.cat(results, dim=0)

    def _compute_reference_manual(self) -> None:
        if self.raw_scale_a_tensors is None or self.raw_scale_b_tensors is None:
            raise RuntimeError("Raw scale tensors must be generated before manual ref.")

        if self.problem.scenario == "2Dx2D":
            self.C_ref_tensor = self._compute_reference_manual_2d2d()
        else:
            self.C_ref_tensor = self._compute_reference_manual_2d3d()

    def _compute_reference_torch(self) -> None:
        from torch.nn.functional import scaled_grouped_mm, ScalingType, SwizzleType

        ref_a, ref_b = self._prepare_ref_tensors()

        if self.problem.kind in ("mxfp8", "mxfp4"):
            scale_a_arg = self.scale_a_tensor
            scale_b_arg = self.scale_b_tensor
            recipe_a = ScalingType.BlockWise1x32
            recipe_b = ScalingType.BlockWise1x32
        else:  # nvfp4
            scale_a_arg = [self.scale_a_tensor, self.global_scale_a]
            scale_b_arg = [self.scale_b_tensor, self.global_scale_b]
            recipe_a = [ScalingType.BlockWise1x16, ScalingType.TensorWise]
            recipe_b = [ScalingType.BlockWise1x16, ScalingType.TensorWise]

        swizzle = SwizzleType.SWIZZLE_32_4_4
        ref_result = scaled_grouped_mm(
            ref_a,
            ref_b,
            scale_a=scale_a_arg,
            scale_recipe_a=recipe_a,
            scale_b=scale_b_arg,
            scale_recipe_b=recipe_b,
            swizzle_a=swizzle,
            swizzle_b=swizzle,
            offs=self.offs_tensor,
            output_dtype=self.problem.out_dtype,
        )

        self.C_ref_tensor = ref_result[..., : self.problem.intermediate]

    # -----------------------------------------------------------------
    # compute_reference
    # -----------------------------------------------------------------

    def compute_reference(self) -> None:
        if self.misc.perf_run:
            return
        if self.misc.no_torch_210:
            self._compute_reference_manual()
        else:
            self._compute_reference_torch()

    # -----------------------------------------------------------------
    # Kernel execution (stub — to be filled when kernel is implemented)
    # -----------------------------------------------------------------

    def create_kernel(self) -> ScaledGroupedGemmKernel:
        _torch_to_cutlass = {
            torch.float32: cutlass.Float32,
            torch.bfloat16: cutlass.BFloat16,
            torch.float16: cutlass.Float16,
        }
        return ScaledGroupedGemmKernel(
            scenario=self.problem.scenario,
            sf_vec_size=self.cfg["blocksize"],
            accumulate_on_output=(
                self.problem.grad_accumulate and self.problem.scenario == "2Dx2D"
            ),
            separate_tensormap_init=self.impl.separate_tensormap_init,
            consistent_token_padding=self.problem.consistent_token_padding,
            acc_dtype=_torch_to_cutlass[self.problem.acc_dtype],
            mma_tiler_mnk=self.impl.mma_tiler_mnk,
            cluster_shape_mnk=self.impl.cluster_shape_mnk,
            use_2cta_instrs=self.impl.use_2cta_instrs,
            fixed_expert_cnt=self.impl.static_expert_cnt,
        )

    def run_kernel(self, kernel: ScaledGroupedGemmKernel) -> Optional[float]:
        """Run our CuTe kernel.

        Returns:
            Average kernel time in ms when perf_e2e is enabled, None otherwise.
        """
        _torch_to_cutlass = {
            torch.float32: cutlass.Float32,
            torch.bfloat16: cutlass.BFloat16,
            torch.float16: cutlass.Float16,
            torch.float8_e4m3fn: cutlass.Float8E4M3FN,
            torch.float8_e5m2: cutlass.Float8E5M2,
            torch.float4_e2m1fn_x2: cutlass.Float4E2M1FN,
        }
        if hasattr(torch, "float8_e8m0fnu"):
            _torch_to_cutlass[torch.float8_e8m0fnu] = cutlass.Float8E8M0FNU

        # Allocate workspace
        workspace_size = kernel.get_workspace_size(self.expert_cnt)
        self.workspace_tensor = torch.full(
            (workspace_size,), 255, dtype=torch.uint8, device="cuda"
        )
        torch.cuda.synchronize()

        # Convert torch tensors → cute tensors
        data_dtype = _torch_to_cutlass[self.cfg["data_dtype"]]
        sf_cutlass_dtype = _torch_to_cutlass[self.cfg["scale_dtype"]]
        out_cutlass_dtype = _torch_to_cutlass[self.problem.out_dtype]

        is_dynamic_expert_cnt = self.impl.static_expert_cnt is None

        def torch_tensor_to_cute_tensor_with_dyn_layout(
            torch_tensor: torch.Tensor,
        ) -> cute.Tensor:
            cute_tensor = cutlass_torch.from_dlpack(torch_tensor)
            leading_dim = cutlass_torch.get_leading_dim(torch_tensor)
            cute_tensor = cute_tensor.mark_layout_dynamic(leading_dim=leading_dim)
            return cute_tensor

        a_cute = torch_tensor_to_cute_tensor_with_dyn_layout(self.A_tensor)
        b_cute = torch_tensor_to_cute_tensor_with_dyn_layout(self.B_tensor)
        scale_a_cute = torch_tensor_to_cute_tensor_with_dyn_layout(self.scale_a_tensor)
        scale_b_cute = torch_tensor_to_cute_tensor_with_dyn_layout(self.scale_b_tensor)
        c_cute = torch_tensor_to_cute_tensor_with_dyn_layout(self.C_tensor)
        offs_cute = torch_tensor_to_cute_tensor_with_dyn_layout(self.offs_tensor)
        workspace_cute = torch_tensor_to_cute_tensor_with_dyn_layout(
            self.workspace_tensor
        )

        # Query max active clusters from hardware
        cluster_size = self.impl.cluster_shape_mnk[0] * self.impl.cluster_shape_mnk[1]
        max_active_clusters = utils.HardwareInfo().get_max_active_clusters(cluster_size)

        # Prepare optional NVFP4 global scales
        global_scale_a_cute = None
        global_scale_b_cute = None
        if self.global_scale_a is not None:
            global_scale_a_cute = torch_tensor_to_cute_tensor_with_dyn_layout(
                self.global_scale_a
            )
            global_scale_b_cute = torch_tensor_to_cute_tensor_with_dyn_layout(
                self.global_scale_b
            )

        stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)

        if self.misc.perf_e2e:
            compiled = cute.compile(
                kernel,
                a_cute,
                b_cute,
                scale_a_cute,
                scale_b_cute,
                c_cute,
                offs_cute,
                workspace_cute,
                max_active_clusters,
                stream,
                global_scale_a=global_scale_a_cute,
                global_scale_b=global_scale_b_cute,
            )

            warmup_iters = 4
            timed_iters = 4

            for _ in range(warmup_iters):
                compiled(
                    a_cute,
                    b_cute,
                    scale_a_cute,
                    scale_b_cute,
                    c_cute,
                    offs_cute,
                    workspace_cute,
                    stream,
                    global_scale_a=global_scale_a_cute,
                    global_scale_b=global_scale_b_cute,
                )
            torch.cuda.synchronize()

            times = []
            for _ in range(timed_iters):
                l2_flush()
                torch.cuda.synchronize()
                start_evt = torch.cuda.Event(enable_timing=True)
                end_evt = torch.cuda.Event(enable_timing=True)
                start_evt.record()
                compiled(
                    a_cute,
                    b_cute,
                    scale_a_cute,
                    scale_b_cute,
                    c_cute,
                    offs_cute,
                    workspace_cute,
                    stream,
                    global_scale_a=global_scale_a_cute,
                    global_scale_b=global_scale_b_cute,
                )
                end_evt.record()
                torch.cuda.synchronize()
                times.append(start_evt.elapsed_time(end_evt))

            avg_ms = sum(times) / len(times)
            print(f"[perf_e2e] Individual times (ms): {[f'{t:.4f}' for t in times]}")
            print(f"[perf_e2e] Average kernel time: {avg_ms:.4f} ms")
            return avg_ms
        else:
            l2_flush()
            kernel(
                a_cute,
                b_cute,
                scale_a_cute,
                scale_b_cute,
                c_cute,
                offs_cute,
                workspace_cute,
                max_active_clusters,
                stream,
                global_scale_a=global_scale_a_cute,
                global_scale_b=global_scale_b_cute,
            )
            torch.cuda.synchronize()
            return None

    # -----------------------------------------------------------------
    # Validation
    # -----------------------------------------------------------------

    def validate(self) -> None:
        if self.misc.perf_run:
            return
        using_torch_ref = not self.misc.no_torch_210
        if using_torch_ref and self.problem.scenario == "2Dx2D":
            # Pytorch bug: zero token does not write out due to the incorrect arg setting.
            self.C_ref_tensor = self.C_ref_tensor.contiguous()
            group_sizes = offs_to_group_sizes(self.offs_tensor)
            for i, g in enumerate(group_sizes):
                if g == 0:
                    self.C_ref_tensor[i].zero_()
        if using_torch_ref and (
            self.problem.scenario == "2Dx3D"
            and self.tokens_after_repeat // self.expert_cnt == 0
        ):
            print(
                "Warning: Due to the Pytorch 2.10 FBGEMM bug (incorrect `M/G` early exit), ref tensor will be all 0 in this case, skip ref check."
            )
            return
        try:
            diff = (self.C_tensor - self.C_ref_tensor).float().abs()
            max_diff = diff.max().item()
            if max_diff == 0.0:
                print("Validation PASSED (exact match)")
            else:
                print(
                    f"C_tensor:     shape={tuple(self.C_tensor.shape)}  "
                    f"stride={self.C_tensor.stride()}  dtype={self.C_tensor.dtype}"
                )
                print(
                    f"C_ref_tensor: shape={tuple(self.C_ref_tensor.shape)}  "
                    f"stride={self.C_ref_tensor.stride()}  dtype={self.C_ref_tensor.dtype}"
                )
                print(
                    f"Validation FAILED: "
                    f"max_diff={max_diff}  "
                    f"mean_diff={diff.mean().item()}"
                )
                assert False, "C_tensor != C_ref_tensor"
        except torch.cuda.OutOfMemoryError:
            print("OOM during diff computation, falling back to torch.equal")
            assert torch.equal(self.C_tensor, self.C_ref_tensor), (
                "C_tensor != C_ref_tensor"
            )

    # -----------------------------------------------------------------
    # SOL comparison
    # -----------------------------------------------------------------

    def run_sol_comparison(self) -> None:
        """Run a dense batched block-scaled GEMM as Speed-of-Light reference.

        Reuses the same tensor memory from the grouped run by passing
        raw pointers with a batched problem_mnkl -- zero GPU allocation.
        """
        import sys, os

        _examples_root = os.path.abspath(
            os.path.join(os.path.dirname(__file__), "..", "..", "..")
        )
        if _examples_root not in sys.path:
            sys.path.insert(0, _examples_root)

        from blackwell.kernel.blockscaled_gemm.dense_blockscaled_gemm_persistent import (
            Sm100BlockScaledPersistentDenseGemmKernel,
        )
        from cutlass.cute.nvgpu import OperandMajorMode
        from cutlass.cute.runtime import make_ptr

        tokens = self.tokens_after_repeat
        experts = self.expert_cnt
        blocksize = self.cfg["blocksize"]
        n_slots = tokens // blocksize
        assert tokens % blocksize == 0 and n_slots % experts == 0, (
            f"compare_with_sol requires tokens*top_k ({tokens}) to be "
            f"divisible by blocksize ({blocksize}), and the resulting "
            f"n_slots ({n_slots}) evenly divisible by experts ({experts}) "
            f"so every group has exactly the same size"
        )
        tpe = tokens // experts

        if self.problem.scenario == "2Dx3D":
            M, N, K, L = tpe, self.intermediate, self.hidden, experts
        else:  # 2Dx2D
            M, N, K, L = self.hidden, self.intermediate, tpe, experts

        # Dtype mapping
        _torch_to_cutlass = {
            torch.float32: cutlass.Float32,
            torch.bfloat16: cutlass.BFloat16,
            torch.float16: cutlass.Float16,
            torch.float8_e4m3fn: cutlass.Float8E4M3FN,
            torch.float8_e5m2: cutlass.Float8E5M2,
            torch.float4_e2m1fn_x2: cutlass.Float4E2M1FN,
        }
        if hasattr(torch, "float8_e8m0fnu"):
            _torch_to_cutlass[torch.float8_e8m0fnu] = cutlass.Float8E8M0FNU

        data_dtype = _torch_to_cutlass[self.cfg["data_dtype"]]
        sf_dtype = _torch_to_cutlass[self.cfg["scale_dtype"]]
        out_dtype = _torch_to_cutlass[self.problem.out_dtype]

        # Layout mapping
        a_major = (
            OperandMajorMode.K
            if self.problem.a_layout == "k_major"
            else OperandMajorMode.MN
        )
        b_major = (
            OperandMajorMode.K
            if self.problem.b_layout == "k_major"
            else OperandMajorMode.MN
        )
        c_layout = (
            utils.LayoutEnum.ROW_MAJOR
            if self.problem.c_layout == "n_major"
            else utils.LayoutEnum.COL_MAJOR
        )
        layouts = (a_major, b_major, c_layout)

        # Construct pointers from existing grouped tensors
        a_ptr = make_ptr(
            data_dtype,
            self.A_tensor.data_ptr(),
            cute.AddressSpace.gmem,
            assumed_align=16,
        )
        b_ptr = make_ptr(
            data_dtype,
            self.B_tensor.data_ptr(),
            cute.AddressSpace.gmem,
            assumed_align=16,
        )
        sfa_ptr = make_ptr(
            sf_dtype,
            self.scale_a_tensor.data_ptr(),
            cute.AddressSpace.gmem,
            assumed_align=32,
        )
        sfb_ptr = make_ptr(
            sf_dtype,
            self.scale_b_tensor.data_ptr(),
            cute.AddressSpace.gmem,
            assumed_align=32,
        )
        c_ptr = make_ptr(
            out_dtype,
            self.C_tensor.data_ptr(),
            cute.AddressSpace.gmem,
            assumed_align=16,
        )

        mma_tiler_mn = self.impl.mma_tiler_mnk[:2]
        cluster_shape_mn = self.impl.cluster_shape_mnk[:2]
        cluster_size = cluster_shape_mn[0] * cluster_shape_mn[1]
        max_active_clusters = utils.HardwareInfo().get_max_active_clusters(cluster_size)

        sol_kernel = Sm100BlockScaledPersistentDenseGemmKernel(
            sf_vec_size=self.cfg["blocksize"],
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
        )

        problem_mnkl = (
            cutlass.Int32(M),
            cutlass.Int32(N),
            cutlass.Int32(K),
            cutlass.Int32(L),
        )

        print(f"\n[SOL] Dense block-scaled BMM: M={M} N={N} K={K} L={L}")
        print(f"[SOL] kind={self.problem.kind}  sf_vec_size={self.cfg['blocksize']}")

        l2_flush()
        sol_kernel(
            a_ptr,
            b_ptr,
            sfa_ptr,
            sfb_ptr,
            c_ptr,
            layouts,
            problem_mnkl,
            max_active_clusters,
            cuda.CUstream(torch.cuda.current_stream().cuda_stream),
        )
        torch.cuda.synchronize()

    # -----------------------------------------------------------------
    # Run
    # -----------------------------------------------------------------

    def run(self) -> None:
        print(self.problem)
        print(self.impl)
        print(self.misc)

        self.generate_inputs()

        group_sizes = offs_to_group_sizes(self.offs_tensor)
        print(
            f"A:  shape={tuple(self.A_tensor.shape)}  "
            f"stride={self.A_tensor.stride()}  dtype={self.A_tensor.dtype}"
        )
        print(
            f"B:  shape={tuple(self.B_tensor.shape)}  "
            f"stride={self.B_tensor.stride()}  dtype={self.B_tensor.dtype}"
        )
        print(
            f"C:  shape={tuple(self.C_tensor.shape)}  "
            f"stride={self.C_tensor.stride()}  dtype={self.C_tensor.dtype}"
        )
        print(
            f"scale_a: shape={tuple(self.scale_a_tensor.shape)}  "
            f"stride={self.scale_a_tensor.stride()}  dtype={self.scale_a_tensor.dtype}"
        )
        print(
            f"scale_b: shape={tuple(self.scale_b_tensor.shape)}  "
            f"stride={self.scale_b_tensor.stride()}  dtype={self.scale_a_tensor.dtype}"
        )
        if self.cfg["has_global_scale"]:
            print(f"global_scale_a: {self.global_scale_a.cpu().tolist()}")
            print(f"global_scale_b: {self.global_scale_b.cpu().tolist()}")
        print(f"offs: {self.offs_tensor.cpu().tolist()}  group_sizes={group_sizes}")

        kernel = self.create_kernel()

        if self.misc.perf_e2e:
            self.run_kernel(kernel)
        else:
            from torch.profiler import profile, ProfilerActivity

            with profile(
                activities=[ProfilerActivity.CUDA], record_shapes=True
            ) as prof:
                self.compute_reference()
                self.run_kernel(kernel)
                if (
                    self.misc.compare_with_sol
                    and self.misc.perf_run
                    and self.problem.balance_route
                ):
                    self.run_sol_comparison()
            print(prof.key_averages().table(sort_by="cuda_time_total", row_limit=20))

        self.validate()
        print("PASS")


# =============================================================================
# CLI entry point
# =============================================================================

if __name__ == "__main__":
    import argparse

    def parse_tuple(s: str) -> Tuple[int, ...]:
        return tuple(int(x) for x in s.split(","))

    parser = argparse.ArgumentParser(
        description="Scaled Grouped GEMM for MoE (MXFP8 / MXFP4 / NVFP4)",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    # ── Problem ──
    parser.add_argument("--tokens", type=int, default=128)
    parser.add_argument("--experts", type=int, default=4)
    parser.add_argument("--top_k_select", type=int, default=2)
    parser.add_argument("--balance_route", action="store_true", default=False)
    parser.add_argument("--hidden", type=int, default=512)
    parser.add_argument("--intermediate", type=int, default=384)
    parser.add_argument(
        "--scenario", type=str, default="2Dx3D", choices=["2Dx3D", "2Dx2D"]
    )
    parser.add_argument(
        "--kind", type=str, default="mxfp8", choices=["mxfp8", "mxfp4", "nvfp4"]
    )
    parser.add_argument("--out_dtype", type=str, default="bfloat16")
    parser.add_argument("--acc_dtype", type=str, default="float32")
    parser.add_argument("--grad_accumulate", action="store_true", default=False)
    parser.add_argument(
        "--consistent_token_padding", action="store_true", default=False
    )
    parser.add_argument(
        "--a_layout", type=str, default="k_major", choices=["k_major", "m_major"]
    )
    parser.add_argument(
        "--b_layout", type=str, default="k_major", choices=["k_major", "n_major"]
    )
    parser.add_argument(
        "--c_layout", type=str, default="n_major", choices=["n_major", "m_major"]
    )

    # ── Impl ──
    parser.add_argument("--mma_tiler_mnk", type=str, default="128,128,128")
    parser.add_argument("--cluster_shape_mnk", type=str, default="1,1,1")
    parser.add_argument("--use_2cta_instrs", action="store_true", default=False)
    parser.add_argument("--static_expert_cnt", type=int, default=None)
    parser.add_argument("--separate_tensormap_init", action="store_true", default=True)

    # ── Misc ──
    parser.add_argument("--perf_run", action="store_true", default=False)
    parser.add_argument("--perf_e2e", action="store_true", default=False)
    parser.add_argument("--compare_with_sol", action="store_true", default=False)

    args = parser.parse_args()

    if args.consistent_token_padding:
        print(
            "WARNING: Overriding consistent_token_padding to False "
            "(not implemented yet)."
        )
        args.consistent_token_padding = False

    problem = ProblemDesc(
        tokens=args.tokens,
        experts=args.experts,
        top_k_select=args.top_k_select,
        balance_route=args.balance_route,
        hidden=args.hidden,
        intermediate=args.intermediate,
        scenario=args.scenario,
        kind=args.kind,
        out_dtype=getattr(torch, args.out_dtype),
        acc_dtype=getattr(torch, args.acc_dtype),
        grad_accumulate=args.grad_accumulate,
        consistent_token_padding=args.consistent_token_padding,
        a_layout=args.a_layout,
        b_layout=args.b_layout,
        c_layout=args.c_layout,
    )

    if not args.separate_tensormap_init:
        print(
            "Overriding separate_tensormap_init to True "
            "(fused version not implemented yet)."
        )
        args.separate_tensormap_init = True

    impl = ImplDesc(
        mma_tiler_mnk=parse_tuple(args.mma_tiler_mnk),
        cluster_shape_mnk=parse_tuple(args.cluster_shape_mnk),
        use_2cta_instrs=args.use_2cta_instrs,
        static_expert_cnt=args.static_expert_cnt,
        separate_tensormap_init=args.separate_tensormap_init,
    )
    misc = MiscDesc(
        perf_run=args.perf_run,
        perf_e2e=args.perf_e2e,
        compare_with_sol=args.compare_with_sol,
    )

    tester = ScaledGroupedGemmTester(problem, impl, misc)
    tester.run()
    print("DONE")
