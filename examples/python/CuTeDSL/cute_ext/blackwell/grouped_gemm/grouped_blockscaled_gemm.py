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

"""
Block-scaled grouped GEMM for the Blackwell SM100 architecture using CUTE IR.

Computes D_g = (A_g * SFA_g) @ (B_g * SFB_g) for each group g,
where SFA/SFB are per-block scale factors in the MXF8/MXF4/NVF4 format.

Supported ``(ab_dtype, sf_dtype, sf_vec_size)`` combinations: 

  - ``(Float8E4M3FN, Float8E8M0FNU, 32)`` -- MXF8
  - ``(Float8E5M2,  Float8E8M0FNU, 32)``  -- MXF8
  - ``(Float4E2M1FN, Float8E8M0FNU, 32)`` -- MXF4
  - ``(Float4E2M1FN, Float8E8M0FNU, 16)`` -- NVF4
  - ``(Float4E2M1FN, Float8E4M3FN,  16)`` -- NVF4

Additional constraints / features:
  - FP4 (``Float4E2M1FN``) inputs require ``a_major='k'`` and
    ``b_major='k'``.
  - Output (``c_dtype``) may be Float32/Float16/BFloat16/Float8E4M3FN/
    Float8E5M2. FP4 output is not supported.
  - 1SM or 2SM (``use_2cta_instrs``) MMA atoms.
  - Cluster shapes up to (4,2) -- 2x2 effective multicast with 2CTA,
    or 2x2 directly with 1CTA.
  - Persistent tile scheduling with per-group pointer/shape/stride arrays.

Examples:

    # MXF8
    python blockscaled_grouped_gemm.py \\
        --problem_sizes_mnkl "(512,256,256,1),(256,128,256,1)" \\
        --ab_dtype Float8E4M3FN --sf_dtype Float8E8M0FNU --sf_vec_size 32 \\
        --c_dtype Float16

    # NVF4 (FP4 inputs with sf_vec_size=16)
    python blockscaled_grouped_gemm.py \\
        --problem_sizes_mnkl "(512,256,256,1),(256,128,256,1)" \\
        --ab_dtype Float4E2M1FN --sf_dtype Float8E8M0FNU --sf_vec_size 16 \\
        --c_dtype Float16
"""

import argparse

import torch
from typing import Type, Tuple, List

import cutlass
from cutlass.cute import experimental as cute_ext
from cutlass.base_dsl.typing import Numeric
from cutlass import cute as cute
from cutlass import utils
from cutlass import torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
from cutlass.cute.nvgpu import tcgen05
import cutlass.cute.testing as testing
from cutlass.cute.experimental.host_runtime import QueryDeviceWorkspaceFunc
from cutlass.cute.runtime import from_dlpack
import os
import sys

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))

from helpers import cli_helper as cli
from helpers.grouped_gemm_persistent_tile_scheduler import (
    GroupSearchResult,
    StaticPersistentGroupTileScheduler,
    create_initial_search_state,
)


class GroupedBlockScaledGemmKernel:
    """Persistent tile-scheduled grouped GEMM kernel with block-scaled MMA.

    Each group computes D = (A * SFA) @ (B * SFB), where the scale factors
    are loaded from global memory alongside A/B and copied to TMEM before
    each block-scaled MMA instruction.

    :param mn_tiler: MMA tile shape (M, N).
    :param mma_dtype: Tuple of (ab_dtype, acc_dtype).
    :param tmem_output_dtype: Output D element type.
    :param sf_dtype: Scale-factor element type.
    :param sf_vec_size: Number of K-elements sharing one scale factor.
    :param group_count: Number of GEMM groups.
    :param a_major_mode: Leading dimension of operand A.
    :param b_major_mode: Leading dimension of operand B.
    :param d_layout: Layout enum for output tensor D.
    :param max_active_clusters: Hardware limit on active clusters.
    """

    def __init__(
        self,
        mn_tiler: tuple[int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric]],
        tmem_output_dtype: Type[Numeric],
        sf_dtype: Type[Numeric],
        sf_vec_size: int,
        group_count: int,
        a_major_mode: cute.nvgpu.OperandMajorMode,
        b_major_mode: cute.nvgpu.OperandMajorMode,
        d_layout: cutlass.tensor_utils.LayoutEnum,
        max_active_clusters: int,
        epilogue_op=lambda x: x,
        use_2cta_instrs: bool = False,
        cluster_shape_mn: Tuple[int, int] = (1, 1),
        fallback_cluster_shape_mn: Tuple[int, int] = None,
        tma_update_mode: str | None = None,
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.d_dtype = tmem_output_dtype
        self.sf_dtype = sf_dtype
        self.sf_vec_size = sf_vec_size
        self.use_2cta_instrs = use_2cta_instrs
        self.num_sched_stage = 2
        self.epilogue_op = epilogue_op
        self.cluster_shape = (cluster_shape_mn[0], cluster_shape_mn[1], 1)
        cluster_shape_mn_selfcast = (2, 1) if use_2cta_instrs else (1, 1)
        # The TMA pipeline uses one op kind for all operand loads, so only use
        # multicast when A and B both have real cluster fan-out.
        self.use_tma_multicast = (
            cluster_shape_mn[0] > cluster_shape_mn_selfcast[0]
            and cluster_shape_mn[1] > cluster_shape_mn_selfcast[1]
        )
        self.a_major_mode = a_major_mode
        self.b_major_mode = b_major_mode
        self.d_layout = d_layout
        self.group_count = group_count
        self.max_active_clusters = max_active_clusters
        self.tma_update_mode = tma_update_mode
        self.cta_group = (
            tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
        )
        if fallback_cluster_shape_mn is None:
            self.fallback_cluster_shape = self.cluster_shape
            fallback_use_tma_multicast = self.use_tma_multicast
        else:
            if (
                not isinstance(fallback_cluster_shape_mn, (tuple, list))
                or len(fallback_cluster_shape_mn) != 2
                or not all(isinstance(x, int) for x in fallback_cluster_shape_mn)
            ):
                raise ValueError(
                    "fallback_cluster_shape_mn must be a length-2 tuple of "
                    f"ints, got {fallback_cluster_shape_mn!r}"
                )
            self.fallback_cluster_shape = (
                fallback_cluster_shape_mn[0],
                fallback_cluster_shape_mn[1],
                1,
            )
            fallback_use_tma_multicast = (
                fallback_cluster_shape_mn[0] > cluster_shape_mn_selfcast[0]
                and fallback_cluster_shape_mn[1] > cluster_shape_mn_selfcast[1]
            )
        # Mixed-cluster: TMA op kind is baked into the IR once for both body clones.
        # Use the multicast op only if a clone has non-degenerate fan-out for
        # all operand loads; singleton-projection shapes use plain TMA.
        self.use_tma_multicast = self.use_tma_multicast or fallback_use_tma_multicast

    def _setup_stages(self):
        tiled_mma = sm100_utils.make_blockscaled_trivial_tiled_mma(
            self.ab_dtype,
            self.ab_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mn_tiler,
        )
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        mnk_tiler = (
            self.mn_tiler[0],
            self.mn_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        cta_tile_shape_mnk = (
            mnk_tiler[0] // num_mma_ctas,
            mnk_tiler[1],
            mnk_tiler[2],
        )
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.d_layout,
            self.d_dtype,
        )
        smem_capacity = cutlass.memory.get_smem_capacity_in_bytes("sm_100")
        (
            self.mainloop_stage,
            self.TMA_STORE_STAGE,
            self.acc_stage,
        ) = self._compute_stages(
            tiled_mma,
            mnk_tiler,
            self.ab_dtype,
            self.sf_dtype,
            self.sf_vec_size,
            epi_tile,
            self.d_dtype,
            self.d_layout,
            smem_capacity,
        )

    @staticmethod
    def _compute_stages(
        tiled_mma,
        mma_tiler_mnk: tuple[int, int, int],
        ab_dtype: Type[Numeric],
        sf_dtype: Type[Numeric],
        sf_vec_size: int,
        epi_tile,
        d_dtype: Type[Numeric],
        d_layout: cutlass.tensor_utils.LayoutEnum,
        smem_capacity: int,
        occupancy: int = 1,
    ) -> tuple[int, int, int]:
        """Compute pipeline stages accounting for A/B and SFA/SFB SMEM usage.

        Heuristic: fill shared memory with as many mainloop (A+B+SFA+SFB)
        stages as possible, then allocate remaining capacity to epilogue
        (TMA store) stages.
        """
        # Mx256 tile size exhausts TMEM for 2 stages, drop to 1
        num_acc_stage = 1 if mma_tiler_mnk[1] == 256 else 2
        num_tma_store_stage = 2
        reserved_smem_bytes = 2048

        a_smem_layout_one = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mma_tiler_mnk,
            ab_dtype,
            1,
        )
        b_smem_layout_one = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mma_tiler_mnk,
            ab_dtype,
            1,
        )
        sfa_smem_layout_one = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            mma_tiler_mnk,
            sf_vec_size,
            1,
        )
        sfb_smem_layout_one = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            mma_tiler_mnk,
            sf_vec_size,
            1,
        )
        epi_smem_layout_one = sm100_utils.make_smem_layout_epi(
            d_dtype,
            d_layout,
            epi_tile,
            1,
        )

        ab_bytes_per_stage = cute.size_in_bytes(
            ab_dtype, a_smem_layout_one
        ) + cute.size_in_bytes(ab_dtype, b_smem_layout_one)
        sf_bytes_per_stage = cute.size_in_bytes(
            sf_dtype, sfa_smem_layout_one
        ) + cute.size_in_bytes(sf_dtype, sfb_smem_layout_one)
        mainloop_bytes_per_stage = ab_bytes_per_stage + sf_bytes_per_stage
        epi_bytes_per_stage = cute.size_in_bytes(d_dtype, epi_smem_layout_one)
        epi_bytes = epi_bytes_per_stage * num_tma_store_stage

        num_mainloop_stage = (
            smem_capacity // occupancy - reserved_smem_bytes - epi_bytes
        ) // mainloop_bytes_per_stage

        remaining_smem = (
            smem_capacity
            - occupancy * mainloop_bytes_per_stage * num_mainloop_stage
            - occupancy * (reserved_smem_bytes + epi_bytes)
        )
        num_tma_store_stage += remaining_smem // (occupancy * epi_bytes_per_stage)

        assert num_mainloop_stage >= 1, (
            f"Insufficient SMEM for at least 1 mainloop stage "
            f"(need {mainloop_bytes_per_stage} B/stage, "
            f"have {smem_capacity // occupancy - reserved_smem_bytes - epi_bytes} B)"
        )
        assert num_tma_store_stage >= 1, (
            "Insufficient SMEM for at least 1 TMA store stage"
        )
        assert num_acc_stage >= 1, "Insufficient TMEM for at least 1 accumulator stage"
        return num_mainloop_stage, num_tma_store_stage, num_acc_stage

    @cute.experimental.jit
    def __call__(
        self,
        mA_ptrs: cute.Tensor,
        mB_ptrs: cute.Tensor,
        mD_ptrs: cute.Tensor,
        mSFA_ptrs: cute.Tensor,
        mSFB_ptrs: cute.Tensor,
        A_shapes: cute.Tensor,
        B_shapes: cute.Tensor,
        D_shapes: cute.Tensor,
        A_strides: cute.Tensor,
        B_strides: cute.Tensor,
        D_strides: cute.Tensor,
        problem_sizes_mnkl: cute.Tensor,
    ):
        self._setup_stages()

        problem_shape_ntile_mnl = (
            self.cluster_shape[0],
            self.cluster_shape[1],
            cutlass.Int32(self.max_active_clusters),
        )
        # NOTE: master migrated the rest of this file to the `helpers/` copy
        # of PersistentTileSchedulerParams, but that copy doesn't have the
        # `fallback_cluster_shape_mnk` kwarg that the mixed-cluster path on this
        # branch needs. Keep this single call on the `cutlass.utils` version
        # until the helpers/ copy adopts the same fallback plumbing.
        tile_sched_params = utils.PersistentTileSchedulerParams(
            problem_shape_ntile_mnl,
            self.cluster_shape,
            fallback_cluster_shape_mnk=self.fallback_cluster_shape,
        )
        grid_sched = StaticPersistentGroupTileScheduler.get_grid_shape(
            tile_sched_params, self.max_active_clusters
        )
        self.kernel(
            mA_ptrs,
            mB_ptrs,
            mD_ptrs,
            mSFA_ptrs,
            mSFB_ptrs,
            A_shapes,
            B_shapes,
            D_shapes,
            A_strides,
            B_strides,
            D_strides,
            problem_sizes_mnkl,
            tile_sched_params,
        ).launch(
            grid=grid_sched,
            block=(224, 1, 1),
            cluster=self.cluster_shape,
            fallback_cluster=self.fallback_cluster_shape,
            smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100")),
            min_blocks_per_mp=1,
        )

    @cute.experimental.jit
    def _get_pointer(self, address_as_int, cute_type):
        """Convert an int64 device address to a typed gmem pointer."""
        cute_ptr = cute.make_ptr(
            cute_type,
            address_as_int,
            mem_space=cutlass.AddressSpace.gmem,
            assumed_align=16,
        )
        return cute_ptr

    @cute.experimental.jit
    def _get_shape_tuple_from_cute_tensor(
        self, cute_shape_tensor: cute.Tensor, group_idx: int
    ):
        """Read a (mn, k, l) tuple from a (G, 3):(3,1) device tensor."""
        shape_gmem = cute_shape_tensor[(group_idx, None)]
        mn = shape_gmem[0]
        k = shape_gmem[1]
        l = shape_gmem[2]
        return (mn, k, l)

    @cute.experimental.jit
    def _make_sf_layout(self, shape_mnk_l):
        """Build a BlockScaledBasicChunk-tiled layout from dynamic (MN, K, L).

        Constructs the layout explicitly with ``cute.make_layout`` so
        that the static inner atom modes are preserved in the MLIR type.
        This is necessary because ``tile_to_shape`` with dynamic shapes
        erases the atom structure to a fully-dynamic ``(?,?,?)`` type
        which the TMA lowering cannot handle after ``zipped_divide``
        resolves it to the static atom with zero strides.

        The atom is always K-major: ``((32,4), (sv,4)) : ((16,4), (0,1))``.
        The input shape is always ``(MN, K, L)`` regardless of operand
        majorness (CuTe encodes majorness in strides, not shape order).
        """
        shape_mn = shape_mnk_l[0]
        shape_k = shape_mnk_l[1]
        shape_l = shape_mnk_l[2]

        ATOM_MN = 128
        ATOM_K = self.sf_vec_size * 4
        ATOM_COSIZE = 512

        mn_tiles = cute.ceil_div(shape_mn, ATOM_MN)
        k_tiles = cute.ceil_div(shape_k, ATOM_K)

        sf_shape = (
            (32, 4, mn_tiles),
            (self.sf_vec_size, 4, k_tiles),
            shape_l,
        )
        sf_stride = (
            (16, 4, ATOM_COSIZE * k_tiles),
            (0, 1, ATOM_COSIZE),
            ATOM_COSIZE * k_tiles * mn_tiles,
        )
        return cute.make_layout(sf_shape, stride=sf_stride)

    @cute.experimental.jit
    def _consume_work_tile_info(
        self,
        tile_info_pipe: cute_ext.GroupedGemmSchedulerPipeline,
        sTile_info: cute.Tensor,
    ) -> Tuple[cute_ext.GroupedGemmSchedulerPipeline, GroupSearchResult, bool]:
        """Consume the next work tile info from the scheduler pipeline."""
        _, tile_info_idx = tile_info_pipe.consumer_wait_and_get_stage()
        cur_sTile = sTile_info[(None, tile_info_idx)]
        work_tile_info = cute.make_rmem_tensor(cur_sTile.shape, cur_sTile.element_type)
        cute.autovec_copy(cur_sTile, work_tile_info)
        tile_info_pipe.consumer_release_and_advance()

        is_valid_tile = work_tile_info[0] == 1
        group_search_result = GroupSearchResult(
            work_tile_info[1],
            work_tile_info[2],
            work_tile_info[3],
            work_tile_info[4],
            work_tile_info[5],
            work_tile_info[6],
            work_tile_info[7],
        )
        return tile_info_pipe, group_search_result, is_valid_tile

    @cute.experimental.kernel(
        attributes=lambda self, _kernel_name: (
            {"lir.tma_update_mode": self.tma_update_mode}
            if self.tma_update_mode is not None
            else {}
        )
    )
    def kernel(
        self,
        mA_ptrs: cute.Tensor,
        mB_ptrs: cute.Tensor,
        mD_ptrs: cute.Tensor,
        mSFA_ptrs: cute.Tensor,
        mSFB_ptrs: cute.Tensor,
        A_shapes: cute.Tensor,
        B_shapes: cute.Tensor,
        D_shapes: cute.Tensor,
        A_strides: cute.Tensor,
        B_strides: cute.Tensor,
        D_strides: cute.Tensor,
        problem_sizes_mnkl: cute.Tensor,
        tile_sched_params: utils.PersistentTileSchedulerParams,
    ):
        tiled_mma = sm100_utils.make_blockscaled_trivial_tiled_mma(
            self.ab_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mn_tiler,
        )

        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4

        mnk_tiler = (
            self.mn_tiler[0],
            self.mn_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )

        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        cta_tile_shape_mnk = cute.shape_div(mnk_tiler, (num_mma_ctas, 1, 1))

        tiled_mma_sfb = sm100_utils.make_blockscaled_trivial_tiled_mma(
            self.ab_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            (cta_tile_shape_mnk[0], cta_tile_shape_mnk[1]),
        )

        # For 2CTA, A/SFA are split along M and B is split along N across
        # the peer CTAs, but SFB is *replicated* across peers -- each peer
        # loads the full MMA-N scale factor tile.
        a_tiler_mk = (cta_tile_shape_mnk[0], cta_tile_shape_mnk[2])
        b_tiler_nk = (cta_tile_shape_mnk[1] // num_mma_ctas, cta_tile_shape_mnk[2])
        sfa_tiler_mk = a_tiler_mk
        sfb_tiler_nk = (cta_tile_shape_mnk[1], cta_tile_shape_mnk[2])

        mainloop_stage = self.mainloop_stage
        acc_stage = self.acc_stage

        cta_m, cta_n, cta_l = cute.arch.block_idx()

        cluster_shape = cute.arch.block_in_cluster_dim()
        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(cluster_shape),
            cute.core._pack_shape((cute.size(tiled_mma.thr_id.shape),)),
        )

        cluster_tile_shape_mnk = (
            cta_tile_shape_mnk[0] * cluster_shape[0],
            cta_tile_shape_mnk[1] * cluster_shape[1],
            cta_tile_shape_mnk[2],
        )
        cluster_layout_v_size = cute.size(cluster_layout_vmnk.shape[0])

        mma_coord_vmnk = (
            cta_m % cluster_layout_v_size,
            cta_m // cluster_layout_v_size,
            cta_n,
        )
        is_leader_cta = mma_coord_vmnk[0] == 0
        thr_mma_sfb = tiled_mma_sfb.get_slice(mma_coord_vmnk[0])
        thr_mma = tiled_mma.get_slice(mma_coord_vmnk[0])

        # --- A/B shared memory layouts ---
        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mnk_tiler,
            self.ab_dtype,
            mainloop_stage,
        )
        b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mnk_tiler,
            self.ab_dtype,
            mainloop_stage,
        )

        # --- SFA/SFB shared memory layouts ---
        sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            mnk_tiler,
            self.sf_vec_size,
            mainloop_stage,
        )
        sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            mnk_tiler,
            self.sf_vec_size,
            mainloop_stage,
        )

        # --- SFA/SFB TMEM layouts ---
        sfa_tmem_layout = blockscaled_utils.make_tmem_layout_sfa(
            tiled_mma,
            mnk_tiler,
            self.sf_vec_size,
            cute.slice_(sfa_smem_layout_staged, (None, None, None, 0)),
        )
        sfb_tmem_layout = blockscaled_utils.make_tmem_layout_sfb(
            tiled_mma,
            mnk_tiler,
            self.sf_vec_size,
            cute.slice_(sfb_smem_layout_staged, (None, None, None, 0)),
        )

        # --- UMMA ACC TMEM layout ---
        acc_shape = tiled_mma.partition_shape_C(mnk_tiler[:2])
        tmem_layout = tiled_mma.make_fragment_C(
            cute.append(acc_shape, acc_stage)
        ).layout

        # --- Allocate SMEM buffers for A/B ---
        bufferA = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )
        bufferB = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )

        # --- Allocate SMEM buffers for SFA/SFB ---
        buffer_smem_sfa = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.smem,
            sfa_smem_layout_staged,
            alignment=1024,
        )
        buffer_smem_sfb = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.smem,
            sfb_smem_layout_staged,
            alignment=1024,
        )

        # --- Allocate TMEM buffers ---
        # ``is2cta`` tells the allocator to reserve "wide" TMEM that the
        # 2-CTA MMA can address across both peers. For 1-CTA it is a no-op.
        bufferAcc = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )
        buffer_tmem_sfa = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.tmem,
            sfa_tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )
        buffer_tmem_sfb = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.tmem,
            sfb_tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )

        buffer_tmem_sfa_compact = cute.filter_zeros(buffer_tmem_sfa)
        buffer_tmem_sfb_compact = cute.filter_zeros(buffer_tmem_sfb)

        # --- S2T copy atoms for scale factors (SMEM -> TMEM) ---
        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp4x32x128bOp(self.cta_group),
            self.sf_dtype,
        )
        tiled_copy_s2t_sfa = cute.nvgpu.tcgen05.make_s2t_copy(
            copy_atom_s2t,
            buffer_tmem_sfa_compact,
        )
        tiled_copy_s2t_sfb = cute.nvgpu.tcgen05.make_s2t_copy(
            copy_atom_s2t,
            buffer_tmem_sfb_compact,
        )

        # --- Pipelines ---
        # Pick MMA / TMA op types from the CtaGroup and whether we need
        # TMA multicast. The four combinations are:
        #   1CTA selfcast  -> SM100_MMA_1SM_SS + SM90_TMA_LOAD
        #   1CTA multicast -> SM100_MMA_1SM_SS + SM90_TMA_LOAD_MULTICAST
        #   2CTA selfcast  -> SM100_MMA_2SM_SS + SM100_TMA_LOAD_2SM
        #   2CTA multicast -> SM100_MMA_2SM_SS + SM100_TMA_LOAD_2SM_MULTICAST
        if cutlass.const_expr(self.use_2cta_instrs):
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_2SM_SS
            if cutlass.const_expr(self.use_tma_multicast):
                tma_operation_type = (
                    cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST
                )
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM
        else:
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS
            if cutlass.const_expr(self.use_tma_multicast):
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD

        # TMA multicast projection modes. ``proj_A == 2`` broadcasts A (and
        # SFA) along cluster-N, where A does not vary. ``proj_B == 1``
        # broadcasts B (and SFB) along cluster-M, where B does not vary.
        tma_mcast_proj_A = 2
        tma_mcast_proj_B = 1

        mainloop_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=mainloop_stage,
            mma_operation_type=mma_operation_type,
            tma_operation_type=tma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # For 2-CTA MMA, warpgroups from both peer and leader CTA consume
        # the accumulator, so the consumer arrive count doubles.
        acc_pipe_consumer_arv_count = 256 if self.use_2cta_instrs else 128
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=acc_stage,
            mma_operation_type=mma_operation_type,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=acc_pipe_consumer_arv_count,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_warp_id = 5
        scheduler_warp_id = 6
        is_tma_thr = warp_idx == tma_load_warp_id
        is_mma_thr = warp_idx == mma_warp_id
        is_epi_thr = warp_idx < 4
        is_sched_thr = warp_idx == scheduler_warp_id

        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=self.TMA_STORE_STAGE,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        # Scheduler -> consumer pipeline for tile info prefetch.
        # Producer: scheduler warp (32 threads), Consumer: all other 6 warps (192 threads).
        tile_info_pipe = cute_ext.GroupedGemmSchedulerPipeline.create(
            num_stages=self.num_sched_stage,
            producer_arv_count=32,
            consumer_arv_count=192,
        )

        # The tile info field of the scheduler pipeline is 9 int32 values.
        # 0: is_valid_tile
        # 1: group_idx
        # 2: cta_tile_idx_m
        # 3: cta_tile_idx_n
        # 4: problem_shape_m
        # 5: problem_shape_n
        # 6: problem_shape_k
        # 7: cta_tile_count_k
        # 8: num_tiles_executed
        tile_info_fields = 9
        sTile_info_layout = cute.make_layout(
            (tile_info_fields, self.num_sched_stage), stride=(1, tile_info_fields)
        )
        sTile_info = cute_ext.allocate(
            cutlass.Int32,
            cutlass.AddressSpace.smem,
            sTile_info_layout,
            alignment=32,
        )

        tile_sched = StaticPersistentGroupTileScheduler.create(
            tile_sched_params,
            cute.arch.block_idx(),
            cute.arch.grid_dim(),
            cluster_tile_shape_mnk,
            create_initial_search_state(),
            self.group_count,
            problem_sizes_mnkl,
        )
        tile_sched.prefetch_problem_shapes()
        initial_work_tile_info = tile_sched.initial_work_tile_info()

        # =====================================================================
        # Dedicated scheduler warp (warp 6)
        # =====================================================================
        if is_sched_thr:
            cute.arch.setmaxregister_decrease(40)
            work_tile = initial_work_tile_info

            while work_tile.is_valid_tile:
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

                _, sched_idx = tile_info_pipe.producer_acquire_and_get_stage()

                with cute.arch.elect_one():
                    cur_sTile_info = sTile_info[(None, sched_idx)]
                    cur_sTile_info[0] = cutlass.Int32(work_tile.is_valid_tile)
                    cur_sTile_info[1] = work_tile.group_search_result.group_idx
                    cur_sTile_info[2] = work_tile.group_search_result.cta_tile_idx_m
                    cur_sTile_info[3] = work_tile.group_search_result.cta_tile_idx_n
                    cur_sTile_info[4] = work_tile.group_search_result.problem_shape_m
                    cur_sTile_info[5] = work_tile.group_search_result.problem_shape_n
                    cur_sTile_info[6] = work_tile.group_search_result.problem_shape_k
                    cur_sTile_info[7] = work_tile.group_search_result.cta_tile_count_k
                    cur_sTile_info[8] = tile_sched.num_tiles_executed

                tile_info_pipe.producer_commit_and_advance()

        # =====================================================================
        # Specialized TMA load warp (warp 5)
        # Loads A, B, SFA, SFB from global memory into shared memory.
        # =====================================================================
        elif is_tma_thr and initial_work_tile_info.is_valid_tile:
            cute.arch.setmaxregister_decrease(40)

            # Initial group 0 tensors
            A_0_ptr = self._get_pointer(mA_ptrs[0], self.ab_dtype)
            B_0_ptr = self._get_pointer(mB_ptrs[0], self.ab_dtype)
            SFA_0_ptr = self._get_pointer(mSFA_ptrs[0], self.sf_dtype)
            SFB_0_ptr = self._get_pointer(mSFB_ptrs[0], self.sf_dtype)

            A_shape = self._get_shape_tuple_from_cute_tensor(A_shapes, 0)
            A_stride = self._get_shape_tuple_from_cute_tensor(A_strides, 0)
            B_shape = self._get_shape_tuple_from_cute_tensor(B_shapes, 0)
            B_stride = self._get_shape_tuple_from_cute_tensor(B_strides, 0)

            mA = cute.make_tensor(
                A_0_ptr, layout=cute.make_layout(A_shape, stride=A_stride)
            )
            mB = cute.make_tensor(
                B_0_ptr, layout=cute.make_layout(B_shape, stride=B_stride)
            )

            # Build SF layouts from A/B shapes using the known atom structure.
            # _make_sf_layout works with runtime-dynamic shapes, unlike
            # tile_atom_to_shape_SF which requires compile-time static shapes.
            mSFA = cute.make_tensor(SFA_0_ptr, self._make_sf_layout(A_shape))
            mSFB = cute.make_tensor(SFB_0_ptr, self._make_sf_layout(B_shape))

            last_group_idx = cutlass.Int32(0)
            is_valid_tile = initial_work_tile_info.is_valid_tile
            group_search_result = initial_work_tile_info.group_search_result

            while is_valid_tile:
                cur_k_tile_cnt = group_search_result.cta_tile_count_k
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0
                cur_group_idx = group_search_result.group_idx

                if not is_k_tile_cnt_zero:
                    is_group_changed = cur_group_idx != last_group_idx

                    if is_group_changed:
                        A_shape = self._get_shape_tuple_from_cute_tensor(
                            A_shapes, cur_group_idx
                        )
                        A_stride = self._get_shape_tuple_from_cute_tensor(
                            A_strides, cur_group_idx
                        )
                        B_shape = self._get_shape_tuple_from_cute_tensor(
                            B_shapes, cur_group_idx
                        )
                        B_stride = self._get_shape_tuple_from_cute_tensor(
                            B_strides, cur_group_idx
                        )

                        ptr_A = self._get_pointer(mA_ptrs[cur_group_idx], self.ab_dtype)
                        ptr_B = self._get_pointer(mB_ptrs[cur_group_idx], self.ab_dtype)
                        mA = cute.make_tensor(
                            ptr_A,
                            layout=cute.make_layout(A_shape, stride=A_stride),
                        )
                        mB = cute.make_tensor(
                            ptr_B,
                            layout=cute.make_layout(B_shape, stride=B_stride),
                        )

                        # Reconstruct SF tensors for the new group
                        sfa_ptr = self._get_pointer(
                            mSFA_ptrs[cur_group_idx], self.sf_dtype
                        )
                        sfb_ptr = self._get_pointer(
                            mSFB_ptrs[cur_group_idx], self.sf_dtype
                        )
                        mSFA = cute.make_tensor(sfa_ptr, self._make_sf_layout(A_shape))
                        mSFB = cute.make_tensor(sfb_ptr, self._make_sf_layout(B_shape))

                        last_group_idx = cur_group_idx

                    gA_mkl = cute.local_tile(
                        mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
                    )
                    gB_nkl = cute.local_tile(
                        mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
                    )
                    gSFA_mkl = cute.local_tile(
                        mSFA,
                        cute.slice_(mnk_tiler, (None, 0, None)),
                        (None, None, None),
                    )
                    gSFB_nkl = cute.local_tile(
                        mSFB,
                        cute.slice_(mnk_tiler, (0, None, None)),
                        (None, None, None),
                    )
                    tCgA = thr_mma.partition_A(gA_mkl)
                    tCgB = thr_mma.partition_B(gB_nkl)
                    tCgSFA = thr_mma.partition_A(gSFA_mkl)
                    tCgSFB = thr_mma_sfb.partition_B(gSFB_nkl)

                    mma_tile_coord_m = (
                        group_search_result.cta_tile_idx_m // num_mma_ctas
                    )
                    mma_tile_coord_n = group_search_result.cta_tile_idx_n
                    tAgA_slice = tCgA[(None, None, None, mma_tile_coord_m, None, 0)]
                    tBgB_slice = tCgB[(None, None, None, mma_tile_coord_n, None, 0)]
                    tAgSFA_slice = tCgSFA[(None, None, None, mma_tile_coord_m, None, 0)]
                    tBgSFB_slice = tCgSFB[(None, None, None, mma_tile_coord_n, None, 0)]

                    for k in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                        gA_k = tAgA_slice[(None, None, None, k)]
                        gB_k = tBgB_slice[(None, None, None, k)]
                        gSFA_k = tAgSFA_slice[(None, None, None, k)]
                        gSFB_k = tBgSFB_slice[(None, None, None, k)]

                        (
                            producer_stage_token,
                            idx,
                        ) = mainloop_pipe.producer_acquire_and_get_stage()
                        mbar = cute_ext.get_mbarrier(producer_stage_token)

                        bufferA_sliced = bufferA[None, None, None, idx]
                        bufferB_sliced = bufferB[None, None, None, idx]
                        buffer_smem_sfa_sliced = buffer_smem_sfa[None, None, None, idx]
                        buffer_smem_sfb_sliced = buffer_smem_sfb[None, None, None, idx]

                        if cutlass.const_expr(self.use_tma_multicast):
                            cute_ext.tma_load(
                                gA_k,
                                bufferA_sliced,
                                mbar,
                                vmnk_layout=cluster_layout_vmnk,
                                tma_operation_type=tma_operation_type,
                                multicast_mode=tma_mcast_proj_A,
                            )
                            cute_ext.tma_load(
                                gB_k,
                                bufferB_sliced,
                                mbar,
                                vmnk_layout=cluster_layout_vmnk,
                                tma_operation_type=tma_operation_type,
                                multicast_mode=tma_mcast_proj_B,
                            )
                            cute_ext.tma_load(
                                gSFA_k,
                                buffer_smem_sfa_sliced,
                                mbar,
                                vmnk_layout=cluster_layout_vmnk,
                                tma_operation_type=tma_operation_type,
                                multicast_mode=tma_mcast_proj_A,
                            )
                            cute_ext.tma_load(
                                gSFB_k,
                                buffer_smem_sfb_sliced,
                                mbar,
                                vmnk_layout=cluster_layout_vmnk,
                                tma_operation_type=tma_operation_type,
                                multicast_mode=tma_mcast_proj_B,
                            )
                        else:
                            cute_ext.tma_load(
                                gA_k,
                                bufferA_sliced,
                                mbar,
                                tma_operation_type=tma_operation_type,
                            )
                            cute_ext.tma_load(
                                gB_k,
                                bufferB_sliced,
                                mbar,
                                tma_operation_type=tma_operation_type,
                            )
                            cute_ext.tma_load(
                                gSFA_k,
                                buffer_smem_sfa_sliced,
                                mbar,
                                tma_operation_type=tma_operation_type,
                            )
                            cute_ext.tma_load(
                                gSFB_k,
                                buffer_smem_sfb_sliced,
                                mbar,
                                tma_operation_type=tma_operation_type,
                            )

                        # In 2CTA mode only the leader CTA commits the
                        # mainloop pipeline; both peers advance their
                        # producer state so the next iteration targets
                        # the next stage.
                        if cutlass.const_expr(self.use_2cta_instrs):
                            if is_leader_cta:
                                mainloop_pipe.producer_commit()
                            mainloop_pipe.producer_state = (
                                cute_ext.pipeline_advance_iterator(
                                    mainloop_pipe.raw_pipeline,
                                    mainloop_pipe.producer_state,
                                )
                            )
                        else:
                            mainloop_pipe.producer_commit_and_advance()

                tile_info_pipe, group_search_result, is_valid_tile = (
                    self._consume_work_tile_info(tile_info_pipe, sTile_info)
                )

        # =====================================================================
        # Specialized MMA warp (warp 4)
        # Performs S2T copy of scale factors then block-scaled MMA.
        # =====================================================================
        elif is_mma_thr and initial_work_tile_info.is_valid_tile:
            cute.arch.setmaxregister_increase(256)
            is_valid_tile = initial_work_tile_info.is_valid_tile
            group_search_result = initial_work_tile_info.group_search_result

            mma_atom = cute.make_mma_atom(tiled_mma.op)

            filtered_buffer_smem_sfa = cute.filter_zeros(buffer_smem_sfa)
            filtered_buffer_smem_sfb = cute.filter_zeros(buffer_smem_sfb)

            while is_valid_tile:
                cur_k_tile_cnt = group_search_result.cta_tile_count_k

                if is_leader_cta:
                    _, acc_idx = acc_pipe.producer_acquire_and_get_stage()
                    accumulators_sliced = bufferAcc[None, None, None, acc_idx]

                    mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)

                    for k_tile_idx in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                        (
                            _,
                            mainloop_idx,
                        ) = mainloop_pipe.consumer_wait_and_get_stage()

                        buffer_smem_a_stage = bufferA[(None, None, None, mainloop_idx)]
                        buffer_smem_b_stage = bufferB[(None, None, None, mainloop_idx)]
                        filtered_sfa_stage = filtered_buffer_smem_sfa[
                            (None, None, None, mainloop_idx)
                        ]
                        filtered_sfb_stage = filtered_buffer_smem_sfb[
                            (None, None, None, mainloop_idx)
                        ]

                        # S2T copy SFA from SMEM to TMEM
                        src_partitioned_SFA = cute_ext.partition(
                            filtered_sfa_stage,
                            cute.Int32(0),
                            layout_tv=tiled_copy_s2t_sfa.layout_src_tv_tiled,
                            tiler=cute.core._pack_tile(tiled_copy_s2t_sfa.tiler_mn),
                        )
                        dst_partitioned_SFA = cute_ext.partition(
                            buffer_tmem_sfa_compact,
                            cute.Int32(0),
                            layout_tv=tiled_copy_s2t_sfa.layout_dst_tv_tiled,
                            tiler=cute.core._pack_tile(tiled_copy_s2t_sfa.tiler_mn),
                        )
                        cute_ext.copy(
                            src_partitioned_SFA,
                            dst_partitioned_SFA,
                            copy_atom=copy_atom_s2t,
                        )

                        # S2T copy SFB from SMEM to TMEM
                        src_partitioned_SFB = cute_ext.partition(
                            filtered_sfb_stage,
                            cute.Int32(0),
                            layout_tv=tiled_copy_s2t_sfb.layout_src_tv_tiled,
                            tiler=cute.core._pack_tile(tiled_copy_s2t_sfb.tiler_mn),
                        )
                        dst_partitioned_SFB = cute_ext.partition(
                            buffer_tmem_sfb_compact,
                            cute.Int32(0),
                            layout_tv=tiled_copy_s2t_sfb.layout_dst_tv_tiled,
                            tiler=cute.core._pack_tile(tiled_copy_s2t_sfb.tiler_mn),
                        )
                        cute_ext.copy(
                            src_partitioned_SFB,
                            dst_partitioned_SFB,
                            copy_atom=copy_atom_s2t,
                        )

                        # Inner k-block MMA loop
                        for k_block_idx in cutlass.range(
                            mma_inst_tile_k, unroll_full=True
                        ):
                            buffer_smem_a_sliced = buffer_smem_a_stage[
                                None, None, k_block_idx
                            ]
                            buffer_smem_b_sliced = buffer_smem_b_stage[
                                None, None, k_block_idx
                            ]

                            cute_ext.dot_block_scaled(
                                mma_atom,
                                cute.append_ones(buffer_smem_a_sliced, up_to_rank=3),
                                cute.group_modes(
                                    buffer_tmem_sfa[
                                        (None, (None, 0)), None, k_block_idx
                                    ],
                                    0,
                                    2,
                                ),
                                cute.append_ones(buffer_smem_b_sliced, up_to_rank=3),
                                cute.group_modes(
                                    buffer_tmem_sfb[
                                        (None, (None, 0)), None, k_block_idx
                                    ],
                                    0,
                                    2,
                                ),
                                accumulators_sliced,
                            )
                            mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)

                        mainloop_pipe.consumer_release_and_advance()

                    acc_pipe.producer_commit_and_advance()

                tile_info_pipe, group_search_result, is_valid_tile = (
                    self._consume_work_tile_info(tile_info_pipe, sTile_info)
                )

        # =====================================================================
        # Specialized epilogue warps (warps 0-3)
        # =====================================================================
        elif is_epi_thr and initial_work_tile_info.is_valid_tile:
            cute.arch.setmaxregister_increase(256)
            D_0_ptr = self._get_pointer(mD_ptrs[0], self.d_dtype)
            D_shape = self._get_shape_tuple_from_cute_tensor(D_shapes, 0)
            D_stride = self._get_shape_tuple_from_cute_tensor(D_strides, 0)
            mD = cute.make_tensor(
                D_0_ptr, layout=cute.make_layout(D_shape, stride=D_stride)
            )
            is_valid_tile = initial_work_tile_info.is_valid_tile
            group_search_result = initial_work_tile_info.group_search_result
            last_group_idx = cutlass.Int32(0)

            while is_valid_tile:
                cur_group_idx = group_search_result.group_idx
                is_k_tile_cnt_zero = group_search_result.cta_tile_count_k == 0
                is_group_changed = cur_group_idx != last_group_idx

                if is_group_changed:
                    ptr_D = self._get_pointer(mD_ptrs[cur_group_idx], self.d_dtype)
                    D_shape = self._get_shape_tuple_from_cute_tensor(
                        D_shapes, cur_group_idx
                    )
                    D_stride = self._get_shape_tuple_from_cute_tensor(
                        D_strides, cur_group_idx
                    )
                    mD = cute.make_tensor(
                        ptr_D,
                        layout=cute.make_layout(D_shape, stride=D_stride),
                    )
                    last_group_idx = cur_group_idx

                _, idx = acc_pipe.consumer_wait_and_get_stage()
                accumulators_sliced = bufferAcc[(None, None), 0, 0, idx]
                cta_d_tile_coord = (
                    group_search_result.cta_tile_idx_m,
                    group_search_result.cta_tile_idx_n,
                    0,
                )
                if not is_k_tile_cnt_zero:
                    tma_store_pipe = cute_ext.epilogue_tma_store(
                        cta_tile_shape_mnk,
                        self.use_2cta_instrs,
                        accumulators_sliced,
                        mD,
                        cta_d_tile_coord,
                        tma_store_pipe,
                        tma_store_warp_id,
                        self.epilogue_op,
                        d_major_mode=self.d_layout,
                    )
                acc_pipe.consumer_release_and_advance()

                tile_info_pipe, group_search_result, is_valid_tile = (
                    self._consume_work_tile_info(tile_info_pipe, sTile_info)
                )


# =============================================================================
# Host-side helpers
# =============================================================================


def create_tensors(l, m, n, k, a_major, b_major, d_major, ab_dtype, d_dtype):
    """Create A, B, D tensors using tensor_utils which handles FP8 via DLPack."""
    from cutlass.utils.gemm.tensor_utils import get_gemm_tensors

    a_major_mode = (
        cute.nvgpu.OperandMajorMode.K
        if a_major == "k"
        else cute.nvgpu.OperandMajorMode.MN
    )
    b_major_mode = (
        cute.nvgpu.OperandMajorMode.K
        if b_major == "k"
        else cute.nvgpu.OperandMajorMode.MN
    )
    d_major_mode = (
        cute.nvgpu.OperandMajorMode.K
        if d_major == "n"
        else cute.nvgpu.OperandMajorMode.MN
    )

    (
        a_torch_gpu,
        b_torch_gpu,
        d_torch_gpu,
        a_tensor,
        b_tensor,
        d_tensor,
    ) = get_gemm_tensors(
        m,
        n,
        k,
        l,
        (a_major_mode, b_major_mode, d_major_mode),
        (
            cutlass_torch.dtype(ab_dtype),
            cutlass_torch.dtype(ab_dtype),
            cutlass_torch.dtype(d_dtype),
        ),
    )

    return (
        a_tensor,
        b_tensor,
        d_tensor,
        a_torch_gpu,
        b_torch_gpu,
        d_torch_gpu,
    )


def create_sf_tensor_for_group(mn, k, sf_vec_size, sf_dtype):
    """Create a scale-factor tensor for one group (L=1).

    Delegates to ``create_scale_factor_tensor`` from ``tensor_utils``.

    Returns (sf_ref, sf_torch_gpu) where:
      - sf_ref: FP32 CPU tensor (MN, K, 1) for reference computation
      - sf_torch_gpu: GPU torch tensor whose memory the kernel reads
    """
    from cutlass.utils.gemm.tensor_utils import create_scale_factor_tensor

    sf_ref, _sf_cute, sf_torch_gpu = create_scale_factor_tensor(
        mn, k, 1, sf_vec_size, sf_dtype
    )
    return sf_ref, sf_torch_gpu


def make_tensor_of_ptrs(torch_tensor_array: List):
    """Create a cute.Tensor of int64 device pointers from a list of torch tensors."""
    tensor_of_ptrs_torch = torch.tensor(
        [t.data_ptr() for t in torch_tensor_array],
        dtype=torch.int64,
        device="cuda",
        requires_grad=False,
    )
    tensor_of_ptrs_cute, backing_torch_tensor = cutlass_torch.cute_tensor_like(
        tensor_of_ptrs_torch,
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )
    return tensor_of_ptrs_cute, backing_torch_tensor


def make_2D_shape_tensor(shapes_list: List[List[int]]):
    """Create a cute.Tensor from a 2D list of int32 values, shape (G, N):(N, 1)."""
    shape_torch = torch.tensor(
        shapes_list, dtype=torch.int32, device="cuda", requires_grad=False
    )
    tensor_of_shapes_cute, torch_tensor_of_shapes = cutlass_torch.cute_tensor_like(
        shape_torch,
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )
    return tensor_of_shapes_cute, torch_tensor_of_shapes


def create_tensors_for_grouped_gemm(
    M_sizes: List,
    N_sizes: List,
    K_sizes: List,
    a_major,
    b_major,
    d_major,
    ab_dtype,
    d_dtype,
    sf_dtype,
    sf_vec_size: int,
):
    """Create all per-group tensors (A, B, D, SFA, SFB) and pack into pointer/shape arrays."""
    num_groups = len(M_sizes)

    As_torch_gpu = []
    Bs_torch_gpu = []
    Ds_torch_gpu = []
    SFAs_torch_gpu = []
    SFBs_torch_gpu = []
    SFAs_ref = []
    SFBs_ref = []

    A_cutes = []
    B_cutes = []
    D_cutes = []

    A_shapes_host = []
    B_shapes_host = []
    D_shapes_host = []
    A_strides_host = []
    B_strides_host = []
    D_strides_host = []

    for group_index in range(num_groups):
        M = M_sizes[group_index]
        N = N_sizes[group_index]
        K = K_sizes[group_index]
        batches = 1

        for batch_index in range(batches):
            torch.manual_seed(111 + batch_index)
            (
                A_tensor,
                B_tensor,
                D_tensor,
                A_torch_gpu,
                B_torch_gpu,
                D_torch_gpu,
            ) = create_tensors(
                1,
                M,
                N,
                K,
                a_major,
                b_major,
                d_major,
                ab_dtype,
                d_dtype,
            )

            A_cutes.append(A_tensor)
            B_cutes.append(B_tensor)
            D_cutes.append(D_tensor)
            As_torch_gpu.append(A_torch_gpu)
            Bs_torch_gpu.append(B_torch_gpu)
            Ds_torch_gpu.append(D_torch_gpu)

        # Scale factor tensors for this group
        torch.manual_seed(222 + group_index)
        sfa_ref, sfa_gpu = create_sf_tensor_for_group(M, K, sf_vec_size, sf_dtype)
        torch.manual_seed(333 + group_index)
        sfb_ref, sfb_gpu = create_sf_tensor_for_group(N, K, sf_vec_size, sf_dtype)
        SFAs_torch_gpu.append(sfa_gpu)
        SFBs_torch_gpu.append(sfb_gpu)
        SFAs_ref.append(sfa_ref)
        SFBs_ref.append(sfb_ref)

        A_shapes_host.append(A_cutes[-1].shape)
        B_shapes_host.append(B_cutes[-1].shape)
        D_shapes_host.append(D_cutes[-1].shape)
        A_strides_host.append(A_cutes[-1].stride)
        B_strides_host.append(B_cutes[-1].stride)
        D_strides_host.append(D_cutes[-1].stride)

    assert len(A_cutes) == num_groups

    a_tensor, a_backing = make_tensor_of_ptrs(As_torch_gpu)
    b_tensor, b_backing = make_tensor_of_ptrs(Bs_torch_gpu)
    d_tensor, d_backing = make_tensor_of_ptrs(Ds_torch_gpu)
    sfa_tensor, sfa_backing = make_tensor_of_ptrs(SFAs_torch_gpu)
    sfb_tensor, sfb_backing = make_tensor_of_ptrs(SFBs_torch_gpu)

    A_shapes_cute, A_shapes_torch = make_2D_shape_tensor(A_shapes_host)
    B_shapes_cute, B_shapes_torch = make_2D_shape_tensor(B_shapes_host)
    D_shapes_cute, D_shapes_torch = make_2D_shape_tensor(D_shapes_host)
    A_strides_cute, A_strides_torch = make_2D_shape_tensor(A_strides_host)
    B_strides_cute, B_strides_torch = make_2D_shape_tensor(B_strides_host)
    D_strides_cute, D_strides_torch = make_2D_shape_tensor(D_strides_host)

    problem_sizes_mnkl = [(M, N, K, 1) for M, N, K in zip(M_sizes, N_sizes, K_sizes)]
    problem_sizes_mnkl_cute, problem_sizes_mnkl_torch = make_2D_shape_tensor(
        problem_sizes_mnkl
    )

    return (
        a_tensor,
        b_tensor,
        d_tensor,
        sfa_tensor,
        sfb_tensor,
        a_backing,
        b_backing,
        d_backing,
        sfa_backing,
        sfb_backing,
        A_cutes,
        B_cutes,
        D_cutes,
        As_torch_gpu,
        Bs_torch_gpu,
        Ds_torch_gpu,
        SFAs_torch_gpu,
        SFBs_torch_gpu,
        SFAs_ref,
        SFBs_ref,
        A_shapes_cute,
        B_shapes_cute,
        D_shapes_cute,
        A_shapes_torch,
        B_shapes_torch,
        D_shapes_torch,
        A_strides_cute,
        B_strides_cute,
        D_strides_cute,
        A_strides_torch,
        B_strides_torch,
        D_strides_torch,
        problem_sizes_mnkl_cute,
        problem_sizes_mnkl_torch,
    )


def compare(
    a_torch_cpu,
    b_torch_cpu,
    sfa_ref,
    sfb_ref,
    c_cute_tensor,
    c_torch_gpu,
    c_dtype,
    c_major,
    tolerance,
):
    """Reference check: D = (A * SFA) @ (B * SFB).

    FP8 A/B tensors ``.to(torch.float32)`` directly yields the correct
    numeric values. FP4 A/B tensors are stored in packed ``torch.uint8``
    form (two E2M1 nibbles per byte, over-allocated by 2x -- see
    ``create_gemm_tensor_torch``), so they must first be decoded via
    ``decode_float4e2m1fn``.

    For FP8 output types the float32 reference is round-tripped through
    the hardware FP8 converter (f32 -> f8 -> f32) so that rounding and
    saturation match the kernel's epilogue exactly.
    """
    from cutlass.cute.runtime import from_dlpack
    from cutlass.utils.gemm.tensor_utils import decode_float4e2m1fn

    # A/B tensors in packed FP4 form arrive here as torch.uint8; any
    # other dtype is a native float format that we can cast to float32.
    decode_ab = (
        decode_float4e2m1fn
        if a_torch_cpu.dtype == torch.uint8
        else lambda x: x.to(torch.float32)
    )

    ref = torch.einsum(
        "mkl,nkl->mnl",
        decode_ab(a_torch_cpu) * sfa_ref,
        decode_ab(b_torch_cpu) * sfb_ref,
    )

    m, n, l = ref.shape[0], ref.shape[1], ref.shape[2]

    # Build a (M, N, L)-shaped CUDA tensor whose physical strides put unit
    # stride on the dim that ``c_major`` selects.
    leading_dim = 1 if c_major == "n" else 0

    def _make_d_torch(dtype):
        if c_major == "m":
            # M-major: logical (M, N, L), physical strides (1, M, M*N).
            return torch.empty(l, n, m, dtype=dtype, device="cuda").permute(2, 1, 0)
        # N-major: logical (M, N, L), physical strides (N, 1, M*N).
        return torch.empty(l, m, n, dtype=dtype, device="cuda").permute(1, 2, 0)

    # Copy GPU result from CuTe tensor to a torch tensor via cute.testing.convert
    gpu_f32_ = _make_d_torch(torch.float32)
    gpu_f32 = from_dlpack(gpu_f32_, assumed_align=16).mark_layout_dynamic(
        leading_dim=leading_dim
    )
    cute.testing.convert(c_cute_tensor, gpu_f32)
    gpu_result = gpu_f32_.cpu()

    if c_dtype in (cutlass.Float8E5M2, cutlass.Float8E4M3FN):
        # Round-trip the reference through the hardware FP8 converter
        ref_f8_ = _make_d_torch(torch.uint8)
        ref_f8 = from_dlpack(ref_f8_, assumed_align=16).mark_layout_dynamic(
            leading_dim=leading_dim
        )
        ref_f8.element_type = c_dtype

        ref_device = _make_d_torch(torch.float32)
        ref_device.copy_(ref)
        ref_tensor = from_dlpack(ref_device, assumed_align=16).mark_layout_dynamic(
            leading_dim=leading_dim
        )
        cute.testing.convert(ref_tensor, ref_f8)
        cute.testing.convert(ref_f8, ref_tensor)
        ref = ref_device.cpu()

    torch.testing.assert_close(
        gpu_result,
        ref,
        atol=tolerance,
        rtol=1e-02,
    )


def run(
    num_groups: int,
    problem_sizes_mnkl: tuple[int, int, int, int],
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    ab_dtype: Type[Numeric],
    sf_dtype: Type[Numeric],
    sf_vec_size: int,
    c_dtype: Type[Numeric],
    acc_dtype: Type[Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    warmup_iterations: int = 0,
    iterations: int = 1,
    use_cold_l2: bool = False,
    tolerance: float = 1e-01,
    skip_ref_check: bool = False,
    use_2cta_instrs: bool = False,
    tma_update_mode: str | None = None,
    fallback_cluster_shape_mn: Tuple[int, int] = None,
    **kwargs,
):
    """Execute a block-scaled grouped GEMM on Blackwell architecture.

    :param num_groups: Number of GEMM groups.
    :param problem_sizes_mnkl: List of (M, N, K, L) per group.
    :param mma_tiler_mn: MMA tile shape (M, N).
    :param cluster_shape_mn: Raw hardware cluster shape (M, N). For 2CTA
        selfcast pass ``(2, 1)``; for 2CTA with 2x2 multicast pass
        ``(4, 2)``. Matches the ``grouped_gemm.py`` convention.
    :param ab_dtype: Input data type for A and B.
    :param sf_dtype: Scale-factor data type.
    :param sf_vec_size: Block-scaling vector size along K.
    :param c_dtype: Output data type for D.
    :param acc_dtype: Accumulator data type.
    :param use_2cta_instrs: Use 2-CTA (2SM) MMA instructions; the raw
        cluster-M must be a multiple of 2 in this mode.
    :param fallback_cluster_shape_mn: Optional. When provided and different
        from cluster_shape_mn, the kernel runs in mixed-cluster mode.
    """
    if tma_update_mode not in (None, "gmem", "smem"):
        raise ValueError(
            f"Invalid tma_update_mode '{tma_update_mode}'. Expected one of: gmem, smem."
        )

    # Allowed (ab_dtype, sf_dtype, sf_vec_size) combinations.
    # MXF8 uses FP8 inputs with sf_vec_size=32;
    # MXF4 / NVF4 use FP4 inputs with sf_vec_size=32 / 16.
    supported_mma_configs = (
        (cutlass.Float8E4M3FN, cutlass.Float8E8M0FNU, 32),
        (cutlass.Float8E5M2, cutlass.Float8E8M0FNU, 32),
        (cutlass.Float4E2M1FN, cutlass.Float8E8M0FNU, 32),
        (cutlass.Float4E2M1FN, cutlass.Float8E8M0FNU, 16),
        (cutlass.Float4E2M1FN, cutlass.Float8E4M3FN, 16),
    )
    if (ab_dtype, sf_dtype, sf_vec_size) not in supported_mma_configs:
        raise RuntimeError(
            f"Unsupported (ab_dtype, sf_dtype, sf_vec_size) combination: "
            f"({ab_dtype}, {sf_dtype}, {sf_vec_size}). Supported combos: "
            f"(Float8E4M3FN, Float8E8M0FNU, 32), "
            f"(Float8E5M2, Float8E8M0FNU, 32), "
            f"(Float4E2M1FN, Float8E8M0FNU, 32), "
            f"(Float4E2M1FN, Float8E8M0FNU, 16), "
            f"(Float4E2M1FN, Float8E4M3FN, 16)."
        )
    # FP4 block-scaled MMA only accepts K-major A and K-major B operands.
    if ab_dtype is cutlass.Float4E2M1FN and not (a_major == "k" and b_major == "k"):
        raise RuntimeError(
            f"FP4 block-scaled MMA requires a_major='k' and b_major='k', "
            f"got a_major={a_major!r}, b_major={b_major!r}."
        )
    # FP4 output is not supported in this example because no SFD
    # (scale-factor-D) generation is implemented here.
    if c_dtype is cutlass.Float4E2M1FN:
        raise RuntimeError(
            "FP4 output (c_dtype=Float4E2M1FN) is not supported by this "
            "example; use Float32/Float16/BFloat16/Float8E4M3FN/Float8E5M2."
        )
    if use_2cta_instrs and cluster_shape_mn[0] % 2 != 0:
        raise RuntimeError(
            f"2CTA mode requires cluster_shape_mn[0] to be a multiple of 2, "
            f"got {cluster_shape_mn}."
        )
    if (
        use_2cta_instrs
        and fallback_cluster_shape_mn is not None
        and fallback_cluster_shape_mn[0] % 2 != 0
    ):
        raise RuntimeError(
            f"2CTA mode requires fallback_cluster_shape_mn[0] to be a multiple "
            f"of 2, got {fallback_cluster_shape_mn}."
        )

    cli.print_problem_config(
        "Blackwell Block-Scaled Grouped GEMM",
        lines=[
            f"{num_groups} groups",
            *(
                f"  Group {i}: {m}x{n}x{k}x{l}"
                for i, (m, n, k, l) in enumerate(problem_sizes_mnkl)
            ),
            f"AB dtype: {ab_dtype}, D dtype: {c_dtype}, Acc dtype: {acc_dtype}",
            f"SF dtype: {sf_dtype}, SF vec size: {sf_vec_size}",
        ],
        majors={"A": a_major, "B": b_major, "D": c_major},
        mma_tiler_mn=mma_tiler_mn,
        cluster_shape_mn=cluster_shape_mn,
    )
    if fallback_cluster_shape_mn is not None:
        print(f"Fallback Cluster Shape (M, N): {fallback_cluster_shape_mn}")
    print(f"2CTA MMA instructions: {'True' if use_2cta_instrs else 'False'}")
    print(f"Tolerance: {tolerance}")

    d_dtype = c_dtype
    d_major = c_major

    for m, n, k, _ in problem_sizes_mnkl:
        sm100_utils.check_gemm_tma_alignment(
            m,
            n,
            k,
            ab_dtype,
            ab_dtype,
            d_dtype,
            a_major,
            b_major,
            d_major,
            output_tensor_name="D",
        )

    M_sizes = [m for m, _, _, _ in problem_sizes_mnkl]
    N_sizes = [n for _, n, _, _ in problem_sizes_mnkl]
    K_sizes = [k for _, _, k, _ in problem_sizes_mnkl]

    (
        a_tensor,
        b_tensor,
        d_tensor,
        sfa_tensor,
        sfb_tensor,
        a_backing,
        b_backing,
        d_backing,
        sfa_backing,
        sfb_backing,
        A_cutes,
        B_cutes,
        D_cutes,
        As_torch_gpu,
        Bs_torch_gpu,
        Ds_torch_gpu,
        SFAs_torch_gpu,
        SFBs_torch_gpu,
        SFAs_ref,
        SFBs_ref,
        A_shapes_cute,
        B_shapes_cute,
        D_shapes_cute,
        A_shapes_torch,
        B_shapes_torch,
        D_shapes_torch,
        A_strides_cute,
        B_strides_cute,
        D_strides_cute,
        A_strides_torch,
        B_strides_torch,
        D_strides_torch,
        problem_sizes_mnkl_cute,
        problem_sizes_mnkl_torch,
    ) = create_tensors_for_grouped_gemm(
        M_sizes,
        N_sizes,
        K_sizes,
        a_major,
        b_major,
        d_major,
        ab_dtype,
        d_dtype,
        sf_dtype,
        sf_vec_size,
    )

    a_major_mode = (
        cute.nvgpu.OperandMajorMode.K
        if a_major == "k"
        else cute.nvgpu.OperandMajorMode.MN
    )
    b_major_mode = (
        cute.nvgpu.OperandMajorMode.K
        if b_major == "k"
        else cute.nvgpu.OperandMajorMode.MN
    )
    d_layout = (
        cutlass.tensor_utils.LayoutEnum.ROW_MAJOR
        if d_major == "n"
        else cutlass.tensor_utils.LayoutEnum.COL_MAJOR
    )
    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    grouped_gemm = GroupedBlockScaledGemmKernel(
        mn_tiler=mma_tiler_mn,
        mma_dtype=(ab_dtype, acc_dtype),
        tmem_output_dtype=d_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        group_count=num_groups,
        a_major_mode=a_major_mode,
        b_major_mode=b_major_mode,
        d_layout=d_layout,
        epilogue_op=lambda x: x,
        use_2cta_instrs=use_2cta_instrs,
        cluster_shape_mn=cluster_shape_mn,
        fallback_cluster_shape_mn=fallback_cluster_shape_mn,
        max_active_clusters=max_active_clusters,
        tma_update_mode=tma_update_mode,
    )

    compiled_grouped_gemm = cute_ext.compile(
        grouped_gemm,
        a_tensor,
        b_tensor,
        d_tensor,
        sfa_tensor,
        sfb_tensor,
        A_shapes_cute,
        B_shapes_cute,
        D_shapes_cute,
        A_strides_cute,
        B_strides_cute,
        D_strides_cute,
        problem_sizes_mnkl_cute,
    )

    query = compiled_grouped_gemm.get_aux_func(
        QueryDeviceWorkspaceFunc, kernel=grouped_gemm.kernel
    )
    req = query(
        a_tensor,
        b_tensor,
        d_tensor,
        sfa_tensor,
        sfb_tensor,
        A_shapes_cute,
        B_shapes_cute,
        D_shapes_cute,
        A_strides_cute,
        B_strides_cute,
        D_strides_cute,
        problem_sizes_mnkl_cute,
    )
    workspace = torch.empty(req.size_in_bytes, dtype=torch.uint8, device="cuda")
    workspace_cute = from_dlpack(workspace)

    compiled_grouped_gemm(
        a_tensor,
        b_tensor,
        d_tensor,
        sfa_tensor,
        sfb_tensor,
        A_shapes_cute,
        B_shapes_cute,
        D_shapes_cute,
        A_strides_cute,
        B_strides_cute,
        D_strides_cute,
        problem_sizes_mnkl_cute,
        workspace_cute,
    )

    if not skip_ref_check:
        for group_idx in range(num_groups):
            compare(
                As_torch_gpu[group_idx].cpu(),
                Bs_torch_gpu[group_idx].cpu(),
                SFAs_ref[group_idx],
                SFBs_ref[group_idx],
                D_cutes[group_idx],
                Ds_torch_gpu[group_idx],
                d_dtype,
                d_major,
                tolerance,
            )
        print("check reference: PASS")

    def generate_tensors():
        (
            a_tensor,
            b_tensor,
            d_tensor,
            sfa_tensor,
            sfb_tensor,
            a_backing,
            b_backing,
            d_backing,
            sfa_backing,
            sfb_backing,
            A_cutes,
            B_cutes,
            D_cutes,
            As_torch_gpu,
            Bs_torch_gpu,
            Ds_torch_gpu,
            SFAs_torch_gpu,
            SFBs_torch_gpu,
            SFAs_ref,
            SFBs_ref,
            A_shapes_cute,
            B_shapes_cute,
            D_shapes_cute,
            A_shapes_torch,
            B_shapes_torch,
            D_shapes_torch,
            A_strides_cute,
            B_strides_cute,
            D_strides_cute,
            A_strides_torch,
            B_strides_torch,
            D_strides_torch,
            problem_sizes_mnkl_cute,
            problem_sizes_mnkl_torch,
        ) = create_tensors_for_grouped_gemm(
            M_sizes,
            N_sizes,
            K_sizes,
            a_major,
            b_major,
            d_major,
            ab_dtype,
            d_dtype,
            sf_dtype,
            sf_vec_size,
        )

        ws = torch.empty(req.size_in_bytes, dtype=torch.uint8, device="cuda")
        ws_cute = from_dlpack(ws)

        args = testing.JitArguments(
            a_tensor,
            b_tensor,
            d_tensor,
            sfa_tensor,
            sfb_tensor,
            A_shapes_cute,
            B_shapes_cute,
            D_shapes_cute,
            A_strides_cute,
            B_strides_cute,
            D_strides_cute,
            problem_sizes_mnkl_cute,
            ws_cute,
        )
        args.add_to_scope(
            [
                A_cutes,
                B_cutes,
                D_cutes,
                As_torch_gpu,
                Bs_torch_gpu,
                Ds_torch_gpu,
                SFAs_torch_gpu,
                SFBs_torch_gpu,
            ]
        )
        return args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            sum(
                As_torch_gpu[g].numel() * As_torch_gpu[g].element_size()
                for g in range(num_groups)
            )
            + sum(
                Bs_torch_gpu[g].numel() * Bs_torch_gpu[g].element_size()
                for g in range(num_groups)
            )
            + sum(
                Ds_torch_gpu[g].numel() * Ds_torch_gpu[g].element_size()
                for g in range(num_groups)
            )
            + sum(
                SFAs_torch_gpu[g].numel() * SFAs_torch_gpu[g].element_size()
                for g in range(num_groups)
            )
            + sum(
                SFBs_torch_gpu[g].numel() * SFBs_torch_gpu[g].element_size()
                for g in range(num_groups)
            )
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_grouped_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
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
    gflops = 0.0 if runtime_s == 0 else gflop / runtime_s

    print("Average Runtime : ", exec_time / 1000, "ms")
    print("GFLOPS          : ", gflops)

    return exec_time


if __name__ == "__main__":

    def parse_problem_sizes_mnkl(s: str) -> List[Tuple[int, int, int, int]]:
        """Parse "(M,N,K,L),(M,N,K,L),..." into a list of tuples."""
        import re

        try:
            s = s.strip()
            pattern = r"\((\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\)"
            matches = re.findall(pattern, s)
            if not matches:
                raise ValueError("No valid tuples found")
            result = [(int(m), int(n), int(k), int(l)) for m, n, k, l in matches]
            for i, (m, n, k, l) in enumerate(result):
                if l != 1:
                    raise ValueError(
                        f"L must be 1 in each (M,N,K,L) tuple, but got L={l} "
                        f"in tuple {i}: ({m},{n},{k},{l})"
                    )
            return result
        except Exception as e:
            raise argparse.ArgumentTypeError(
                f"Invalid format. Expected '(M,N,K,L),(M,N,K,L),...' "
                f"but got '{s}'. Error: {e}"
            )

    parser = argparse.ArgumentParser(
        description="Block-Scaled Grouped GEMM on Blackwell (SM100)."
    )

    parser.add_argument(
        "--problem_sizes_mnkl",
        type=parse_problem_sizes_mnkl,
        default=None,
        help='Problem sizes, e.g. "(512,256,256,1),(256,128,256,1)". '
        "Defaults to (512,256,256,1),(256,128,256,1) if omitted.",
    )
    parser.add_argument(
        "--num_groups",
        type=int,
        default=None,
        help="Number of groups (inferred from --problem_sizes_mnkl if omitted)",
    )
    cli.add_mma_tiler_arg(parser, help="MMA tile shape (comma-separated)")
    cli.add_cluster_shape_arg(parser)
    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=cli.comma_separated_ints,
        default=None,
        help="Optional fallback cluster shape (comma-separated).",
    )

    parser.add_argument(
        "--ab_dtype",
        type=cutlass.dtype,
        default=cutlass.Float8E4M3FN,
        help="A/B element type. Supported: Float8E4M3FN, Float8E5M2 (MXF8) "
        "or Float4E2M1FN (MXF4/NVF4).",
    )
    parser.add_argument(
        "--sf_dtype",
        type=cutlass.dtype,
        default=cutlass.Float8E8M0FNU,
        help="Scale-factor element type. Supported: Float8E8M0FNU (MXF8, "
        "MXF4, NVF4) or Float8E4M3FN (NVF4 only).",
    )
    parser.add_argument(
        "--sf_vec_size",
        type=int,
        default=32,
        help="Scale-factor vector size along K. Supported: 32 (MXF8 or "
        "MXF4) or 16 (NVF4). Must match --ab_dtype/--sf_dtype combo: "
        "(FP8, Float8E8M0FNU, 32), (FP4, Float8E8M0FNU, 32/16), or "
        "(FP4, Float8E4M3FN, 16).",
    )
    cli.add_dtype_args(parser, c=cutlass.Float16)
    cli.add_major_args(parser)
    cli.add_benchmark_args(parser)

    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Use 2-CTA (2SM) MMA instructions. Raw cluster-M must be a "
        "multiple of 2 (e.g. (2,1) for selfcast, (4,2) for 2x2 multicast).",
    )
    parser.add_argument(
        "--tma_update_mode",
        choices=["gmem", "smem"],
        default=None,
        help="TMA descriptor update mode.",
    )

    args = parser.parse_args()

    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values")

    if (
        args.fallback_cluster_shape_mn is not None
        and len(args.fallback_cluster_shape_mn) != 2
    ):
        parser.error("--fallback_cluster_shape_mn must contain exactly 2 values")

    if args.problem_sizes_mnkl is not None:
        problem_sizes_mnkl = args.problem_sizes_mnkl
    else:
        problem_sizes_mnkl = [(512, 256, 256, 1), (256, 128, 256, 1)]

    if args.num_groups is not None:
        num_groups = args.num_groups
        if len(problem_sizes_mnkl) != num_groups:
            parser.error(
                f"--num_groups ({num_groups}) must match the number of problem sizes "
                f"in --problem_sizes_mnkl ({len(problem_sizes_mnkl)})"
            )
    else:
        num_groups = len(problem_sizes_mnkl)

    exec_time = run(
        num_groups,
        problem_sizes_mnkl,
        args.mma_tiler_mn,
        args.cluster_shape_mn,
        args.ab_dtype,
        args.sf_dtype,
        args.sf_vec_size,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.tolerance,
        args.skip_ref_check,
        args.use_2cta_instrs,
        args.tma_update_mode,
        fallback_cluster_shape_mn=args.fallback_cluster_shape_mn,
    )

    print(f"Execution time: {exec_time} microseconds per iteration")
