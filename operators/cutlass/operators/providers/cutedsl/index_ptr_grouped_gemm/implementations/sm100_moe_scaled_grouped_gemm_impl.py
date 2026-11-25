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

from typing import Optional, Tuple, Literal, Type, Union

import cuda.bindings.driver as cuda

import cutlass
import cutlass.utils as utils
import cutlass.cute as cute
from cutlass.cute.typing import Pointer
from cutlass.cute.nvgpu import cpasync, tcgen05
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait

from .moe_utils import (
    MoEScaledGroupedGemmTensormapConstructor,
)
from .moe_persistent_scheduler import (
    MoEStaticSchedulerParams,
    MoEStaticPersistentTileScheduler,
    MoEWorkTileInfo,
)
from .moe_sched_extension import ScaledGroupedMmSchedExtension
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
        scale_offsets_match_data: bool,
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
        self.scale_offsets_match_data = scale_offsets_match_data
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

        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes(self.arch)
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
        padded_offs_bytes = expert_cnt * 4 if not self.scale_offsets_match_data else 0
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
        self.sched_work_tile_bytes_per_stage = 16  # 4 fields * sizeof(Int32)

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
        c_layout: cutlass.tensor_utils.LayoutEnum,
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
        workspace_ptr: Pointer,  # Expert-wise TMA desc + padded offs
        max_active_clusters: cutlass.Int32,
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

            # Rank-2 carrier dimensions report padded extents; values are already swizzled.
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

            # Rank-2 carrier dimensions report padded extents; values are already swizzled.
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
        self.a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            a_gemm
        ).mma_major_mode()
        self.b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            b_gemm
        ).mma_major_mode()
        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(c_gemm)

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

        # scale_offsets_match_data=True → offs_padded=None, main kernel reuses offs
        # scale_offsets_match_data=False → offs_padded in GMEM workspace, written by desc_init
        if cutlass.const_expr(self.scale_offsets_match_data):
            offs_padded = None
        else:
            desc_bytes = MoEScaledGroupedGemmTensormapConstructor.get_workspace_size(
                self.scenario, expert_cnt
            )
            offs_padded = cute.make_tensor(
                cute.recast_ptr(workspace_ptr + desc_bytes, dtype=offs.dtype),
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
                workspace_ptr,
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
            workspace_ptr,
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
        # Only allocated when scale_offsets_match_data=False.
        # =================================================================

        if cutlass.const_expr(not self.scale_offsets_match_data):
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

        smem = cutlass.memory.SmemAllocator()

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
            if cutlass.const_expr(self.scale_offsets_match_data)
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

                if cutlass.const_expr(self.scale_offsets_match_data):
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
            sched_buf_align_bytes = self.sched_work_tile_bytes_per_stage
            sched_buf: cute.struct.Align[
                cute.struct.MemRange[cutlass.Int32, self.num_sched_stages * 4],
                sched_buf_align_bytes,
            ]
            sched_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_sched_stages * 2
            ]
            tmem_dealloc_mbar_ptr: cutlass.Int64
            tmem_holding_buf: cutlass.Int32

        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(SharedStorage)

        # =================================================================
        # Pipelines
        # =================================================================

        # AB pipeline (TMA load → MMA) — same as grouped_mm
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
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
        tmem = cutlass.memory.TmemAllocator(
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
