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
Grouped GEMM example for the Rubin (SM107) architecture using CuTe DSL Extensions.

This example implements a *grouped* GEMM: given ``G`` independent problems
``(M_g, N_g, K_g)`` with ``L = 1``, it computes::

    D_g = epilogue(A_g @ B_g)   for g in 0..G-1

All groups are launched together as a single persistent kernel; the device
arrays ``mA_ptrs / mB_ptrs / mD_ptrs`` hold per-group base pointers and the
companion ``A_shapes / B_shapes / D_shapes`` and ``A_strides / B_strides /
D_strides``are also device tensors holding the problem shapes and strides.
launch is shared.
Most of the implementation is the same as the Blackwell grouped gemm example, but with the following differences:
- It uses oversized 328Kb smem capacity and 576 column tmem capacity.
- It exposes the mma instruction shape to the user via CLI to
  enable the B-reuse/REST_M > 1 path.
- It exercises the B-reuse/B-keep feature in the LIR compiler.

NOTE: This feature is currently only supported for FP8 inputs.

The B-reuse Feature:

  **B-reuse / REST_M > 1 path.** When the per-cluster ``mn_tiler`` is
  larger than the MMA atom shape (``mma_inst_shape_mn``) along M, a single
  cluster tile is covered by REST_M atom calls that share the same B
  operand. Setting ``mn_tiler[0] // mma_inst_shape_mn[0] == 2``
  will trigger the heuristic to enable this path.

This example also demonstrates different approach to partition the gmem tensor compared to Blackwell examples.
We need to retain and propagate the REST_M mode for the TMA Load and store ops.
We use the CuteDSL way of partitioning : local_tile -> thr_mma.partition_{A,B} -> slice

The standard epilogue path has an outer loop that iterates over the M atoms with updated indexing.
In effect, as the CTA tile M is 2x larger, we break it into rest_m pieces and perform subtiling + tma store for each piece.
This outer loop can be wrapped into the utility with updated TMEM layouts carrying the REST_M mode. This is a future TODO.

The ``run(...)`` helper at the bottom builds the per-group torch tensors,
JIT-compiles the kernel via ``cute_ext.compile``, allocates the device
workspace queried with ``QueryDeviceWorkspaceFunc``, optionally validates
against a torch matmul reference, and benchmarks the result.
"""

import argparse
import os
import sys

import torch
from typing import Type, Tuple, List

import cutlass
from cutlass import utils
from cutlass.cute import experimental as cute_ext
from cutlass.base_dsl.typing import Numeric
from cutlass import cute as cute
from cutlass import torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.rubin_helpers as sm107_utils
from cutlass import testing
from cutlass.cute.experimental.host_runtime import QueryDeviceWorkspaceFunc
from cutlass.cute.runtime import from_dlpack

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../.."))

from helpers import cli_helper as cli
from helpers.static_persistent_tile_scheduler import PersistentTileSchedulerParams
from helpers.grouped_gemm_persistent_tile_scheduler import (
    GroupSearchResult,
    StaticPersistentGroupTileScheduler,
    create_initial_search_state,
)


class GroupedGemmKernel:
    def __init__(
        self,
        mn_tiler: tuple[int, int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric]],
        tmem_output_dtype: Type[Numeric],
        group_count: int,
        a_major_mode: cute.nvgpu.OperandMajorMode,
        b_major_mode: cute.nvgpu.OperandMajorMode,
        d_layout: cutlass.tensor_utils.LayoutEnum,
        max_active_clusters: int,
        epilogue_op=lambda x: x,
        use_2cta_instrs: bool = False,
        cluster_shape_mn: Tuple[int, int] = (2, 1),
        tma_update_mode: str | None = None,
        mma_inst_shape: Tuple[int, int, int] | None = None,
        arch: str = "sm_107",
    ):
        if mma_inst_shape is None:
            mma_inst_shape = mn_tiler
        self.mn_tiler = mn_tiler
        self.mma_inst_shape = mma_inst_shape
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.tmem_output_dtype = tmem_output_dtype
        self.d_dtype = tmem_output_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.num_sched_stage = 2
        self.epilogue_op = epilogue_op
        self.cluster_shape = (cluster_shape_mn[0], cluster_shape_mn[1], 1)
        cluster_shape_mn_selfcast = (2, 1) if use_2cta_instrs else (1, 1)
        self.use_tma_multicast = cluster_shape_mn != cluster_shape_mn_selfcast
        self.a_major_mode_ = a_major_mode
        self.b_major_mode_ = b_major_mode
        self.d_layout_ = d_layout
        self.group_count = group_count
        self.max_active_clusters = max_active_clusters
        self.tma_update_mode = tma_update_mode
        self.enable_breuse = True if mn_tiler[0] // mma_inst_shape[0] == 2 else False
        self.arch = utils.sm107.canonicalize_rubin_resource_arch(arch)
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes(self.arch)

        # Validate the configuration up front so that unsupported tile /
        # cluster / dtype combinations fail fast with a clear message.
        self.can_implement()

    def can_implement(self):
        """Validate that this kernel supports the requested configuration.

        Checks the operand / accumulator dtypes together with the MMA tiler,
        MMA instruction shape and cluster shape. Raises
        ``testing.CantImplementError`` when the configuration is not supported.
        """
        #
        # Check supported Data types
        #
        supported_ab_dtypes = {
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float32,
        }
        if self.ab_dtype not in supported_ab_dtypes:
            raise testing.CantImplementError(
                f"Unsupported ab_dtype: {self.ab_dtype}; supported: "
                "Float8E4M3FN, Float8E5M2, Float16, BFloat16, Float32"
            )
        if self.acc_dtype not in {cutlass.Float32, cutlass.Float16}:
            raise testing.CantImplementError(
                f"Unsupported acc_dtype: {self.acc_dtype}; supported: Float32, Float16"
            )

        #
        # Check supported MMA tiler / instruction shape
        #
        # The cluster tile is covered by REST_M atom calls along M, so the tile
        # M must be an integer multiple of the instruction M.
        if self.mn_tiler[0] % self.mma_inst_shape[0] != 0:
            raise testing.CantImplementError(
                f"mn_tiler[0]={self.mn_tiler[0]} must be a multiple of "
                f"mma_inst_shape[0]={self.mma_inst_shape[0]}"
            )
        # REST_N != 1 is not supported: the tile N must match the instruction N.
        if self.mn_tiler[1] != self.mma_inst_shape[1]:
            raise testing.CantImplementError(
                f"mn_tiler[1]={self.mn_tiler[1]} must equal "
                f"mma_inst_shape[1]={self.mma_inst_shape[1]} "
                "(REST_N != 1 is not supported by this kernel)"
            )
        # Only REST_M == 1 (no B-reuse) or REST_M == 2 (B-reuse path) are
        # supported.
        rest_m = self.mn_tiler[0] // self.mma_inst_shape[0]
        if rest_m not in (1, 2):
            raise testing.CantImplementError(
                f"Unsupported REST_M={rest_m} (mn_tiler[0]={self.mn_tiler[0]}, "
                f"mma_inst_shape[0]={self.mma_inst_shape[0]}); "
                "REST_M must be 1 or 2"
            )
        # The MMA instruction M is fixed by the CTA group (2-CTA doubles M).
        expected_inst_m = 256 if self.use_2cta_instrs else 128
        if self.mma_inst_shape[0] != expected_inst_m:
            raise testing.CantImplementError(
                f"Invalid mma_inst_shape_m={self.mma_inst_shape[0]}; expected "
                f"{expected_inst_m} for use_2cta_instrs={self.use_2cta_instrs}"
            )
        if self.mma_inst_shape[1] not in (128, 256):
            raise testing.CantImplementError(
                f"Invalid mma_inst_shape_n={self.mma_inst_shape[1]}; "
                "expected 128 or 256"
            )

        #
        # Cluster shape
        #
        cluster_shape_mn = (self.cluster_shape[0], self.cluster_shape[1])
        # Cluster M must be a multiple of the CTA-group size.
        if cluster_shape_mn[0] % (2 if self.use_2cta_instrs else 1) != 0:
            raise testing.CantImplementError(
                f"Invalid cluster_shape_m={cluster_shape_mn[0]} for "
                f"use_2cta_instrs={self.use_2cta_instrs}"
            )
        # Cluster dimensions must be positive powers of two with a total
        # cluster size of at most 16.
        if (
            cluster_shape_mn[0] <= 0
            or cluster_shape_mn[1] <= 0
            or cluster_shape_mn[0] * cluster_shape_mn[1] > 16
            or (cluster_shape_mn[0] & (cluster_shape_mn[0] - 1)) != 0
            or (cluster_shape_mn[1] & (cluster_shape_mn[1] - 1)) != 0
        ):
            raise testing.CantImplementError(
                f"Invalid cluster_shape: {cluster_shape_mn}"
            )

        return True

    def _is_fp8(self) -> bool:
        return self.ab_dtype in (cutlass.Float8E4M3FN, cutlass.Float8E5M2)

    """
    Consider this example with mma_inst = 256x128 and mma_tiler = 512x128.
    In regular 2CTA mode, we have 2 CTAs cooperating to cover the tile in this format 
    with per-CTA M=128:
                      REST_M = 0                 REST_M = 1
                  (atom call #0)             (atom call #1)
                  +-----------+--------+     +-----------+--------+
        M chunk:  | chunk0    | chunk1 |     | chunk2    | chunk3 |
        owner:    | CTA0      | CTA1   |     | CTA0      | CTA1   |
                  +-----------+--------+     +-----------+--------+
        M range:   [0..128)    [128..256)     [256..384)  [384..512)

    CTA0's A footprint across the kernel: chunk0 + chunk2  -> NON-contiguous in M
    CTA1's A footprint:                   chunk1 + chunk3  -> NON-contiguous in M

    This is what happens in the legacy path where we return a (1,1,1) permutation.

    With B-keep/B-reuse, we want CTA0 to hold a full tile worth the entire MMA-M and same for CTA1 
    so that the B matrix can be reused. 

                    REST_M = 0                 REST_M = 1
                  (atom call #0)             (atom call #1)
                  +-----------+              +-----------+
       CTA0 ->    |  chunk0   |              |  chunk1   |
                  | [0..128)  |              | [128..256)|
                  +-----------+              +-----------+
                                                  |
                                                  | (same B reused)
                                                  v
                  +-----------+              +-----------+
       CTA1 ->    |  chunk2   |              |  chunk3   |
                  | [256..384)|              | [384..512)|
                  +-----------+              +-----------+

    CTA0's A footprint: chunk0 + chunk1 = M[0..256)    -> CONTIGUOUS
    CTA1's A footprint: chunk2 + chunk3 = M[256..512)  -> CONTIGUOUS
    The layout of the permutation is of this form : (per-CTA M, CTA-index, REST_M) : (1, CTA stride, REST_M stride)
    Plugging in the values, we get a layout (128, 2, 2) : (1, 256, 128)
    So each CTA handles 128 rows, the stride between the starting rows in a CTA pair is 256 
    and the stride across atoms within a CTA is 128.
    """

    def _get_mma_permutation_mnk(self):
        if cutlass.const_expr(self.use_2cta_instrs and self.enable_breuse):
            m_layout = cute.make_layout(
                shape=(self.mma_inst_shape[0] // 2, 2, 2),
                stride=(1, self.mma_inst_shape[0], self.mma_inst_shape[0] // 2),
            )
            return (m_layout, self.mma_inst_shape[1], self.mma_inst_shape[2])

        else:
            return (1, 1, 1)

    def _make_tiled_mma(self, cta_group):
        # FP8 inputs use the SM107 (Rubin) MMA op which requires the full
        # (M, N, K) instruction shape. Other dtypes (FP16/BF16/TF32/...)
        # use the SM100 helper which infers K from the operand dtype and
        # only takes (M, N).
        if self._is_fp8():
            # TODO: Add support for FP16/BF16/TF32 types.
            return sm107_utils.make_trivial_tiled_mma(
                self.ab_dtype,
                self.ab_dtype,
                self.a_major_mode_,
                self.b_major_mode_,
                self.acc_dtype,
                cta_group,
                self.mma_inst_shape,
                permutation_mnk=self._get_mma_permutation_mnk(),
            )
        return sm100_utils.make_trivial_tiled_mma(
            self.ab_dtype,
            self.ab_dtype,
            self.a_major_mode_,
            self.b_major_mode_,
            self.acc_dtype,
            cta_group,
            (self.mn_tiler[0], self.mn_tiler[1]),
        )

    def _setup_stages(self):
        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.TWO
            if self.use_2cta_instrs
            else cute.nvgpu.tcgen05.CtaGroup.ONE
        )
        tiled_mma = self._make_tiled_mma(cta_group)
        mnk_tiler = self.mn_tiler
        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        cta_tile_shape_mnk = (
            mnk_tiler[0] // num_mma_ctas,
            mnk_tiler[1],
            mnk_tiler[2],
        )
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.d_layout_,
            self.d_dtype,
        )
        (
            self.mainloop_stage,
            self.TMA_STORE_STAGE,
            self.acc_stage,
        ) = self._compute_stages(
            tiled_mma,
            mnk_tiler,
            self.ab_dtype,
            epi_tile,
            self.d_dtype,
            self.d_layout_,
            self.smem_capacity,
        )

    @staticmethod
    def _compute_stages(
        tiled_mma,
        mma_tiler_mnk: tuple[int, int, int],
        ab_dtype: Type[Numeric],
        epi_tile,
        d_dtype: Type[Numeric],
        d_layout: cutlass.tensor_utils.LayoutEnum,
        smem_capacity: int,
        occupancy: int = 1,
    ) -> tuple[int, int, int]:
        """Computes the number of pipeline stages for mainloop, TMA store, and accumulator.

        Heuristic: fill shared memory with as many A/B (mainloop) stages as possible,
        then allocate remaining capacity to epilogue (TMA store) stages.
        Accumulator stages are fixed at 2, scheduler stages are fixed at 2.

        :param tiled_mma: The tiled MMA object defining the core computation.
        :param mma_tiler_mnk: The shape (M, N, K) of the MMA tiler.
        :param ab_dtype: Data type of operands A and B.
        :param epi_tile: The epilogue tile shape.
        :param d_dtype: Data type of the output tensor D.
        :param d_layout: Layout enum of the output tensor D.
        :param smem_capacity: Total available shared memory capacity in bytes.
        :param occupancy: Target number of CTAs per SM, defaults to 1.
        :return: (mainloop_stages, tma_store_stages, acc_stages)
        """
        num_acc_stage = 2
        num_tma_store_stage = 2
        reserved_smem_bytes = 1024

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
        epi_smem_layout_one = sm100_utils.make_smem_layout_epi(
            d_dtype,
            d_layout,
            epi_tile,
            1,
        )

        ab_bytes_per_stage = cute.size_in_bytes(
            ab_dtype, a_smem_layout_one
        ) + cute.size_in_bytes(ab_dtype, b_smem_layout_one)
        epi_bytes_per_stage = cute.size_in_bytes(d_dtype, epi_smem_layout_one)
        epi_bytes = epi_bytes_per_stage * num_tma_store_stage

        num_mainloop_stage = (
            smem_capacity // occupancy - reserved_smem_bytes - epi_bytes
        ) // ab_bytes_per_stage

        remaining_smem = (
            smem_capacity
            - occupancy * ab_bytes_per_stage * num_mainloop_stage
            - occupancy * (reserved_smem_bytes + epi_bytes)
        )
        num_tma_store_stage += remaining_smem // (occupancy * epi_bytes_per_stage)
        return num_mainloop_stage, num_tma_store_stage, num_acc_stage

    @cute.experimental.jit
    def __call__(
        self,
        mA_ptrs: cute.Tensor,
        mB_ptrs: cute.Tensor,
        mD_ptrs: cute.Tensor,
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
        tile_sched_params = PersistentTileSchedulerParams(
            problem_shape_ntile_mnl, (*self.cluster_shape, 1)
        )
        grid_sched = StaticPersistentGroupTileScheduler.get_grid_shape(
            tile_sched_params, self.max_active_clusters
        )
        self.kernel(
            mA_ptrs,
            mB_ptrs,
            mD_ptrs,
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
            smem=cute.Int64(self.smem_capacity),
            min_blocks_per_mp=1,
        )

    """
    Helper function to convert an int64 to a cute.ptr of a certain type.
    The cute.ptr is always located in Gmem.
    This is used to load the pointers for A/B/D from the Ptr array.
    """

    @cute.experimental.jit
    def _get_pointer(self, address_as_int, cute_type):
        cute_ptr = cute.make_ptr(
            cute_type,
            address_as_int,
            mem_space=cutlass.AddressSpace.gmem,
            assumed_align=16,
        )
        return cute_ptr

    """
    Helper function to convert a cute.Tensor containing List of int32 values in device memory 
    to a tuple of 3 python integers.
    In device memory, the tensor has a shape of (G, 3) : (3,1).
    The input `cute_shape_tensor` stores G values and can contain either the shape or 
    stride values for a tensor. The parameter `group_idx` is used to index
    into this tensor to get the raw values. The returned tuple is used in calls to 
    cute.make_tensor to create the actual tensor.
    """

    @cute.experimental.jit
    def _get_shape_tuple_from_cute_tensor(
        self, cute_shape_tensor: cute.Tensor, group_idx: int
    ):
        shape_gmem = cute_shape_tensor[(group_idx, None)]
        mn = shape_gmem[0]
        k = shape_gmem[1]
        l = shape_gmem[2]
        return (mn, k, l)

    """
    Helper function to consume the work tile info from the shared memory.
    NOTE: This function returns the tile info pipeline because Python uses pass by value semantics.
    A @jit decorated function creates a new region and the new state of the pipeline isn't visible 
    outside the region.
    """

    @cute.experimental.jit
    def _consume_work_tile_info(
        self,
        tile_info_pipe: cute_ext.GroupedGemmSchedulerPipeline,
        sTile_info: cute.Tensor,
    ) -> Tuple[cute_ext.GroupedGemmSchedulerPipeline, GroupSearchResult, bool]:
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
        A_shapes: cute.Tensor,
        B_shapes: cute.Tensor,
        D_shapes: cute.Tensor,
        A_strides: cute.Tensor,
        B_strides: cute.Tensor,
        D_strides: cute.Tensor,
        problem_sizes_mnkl: cute.Tensor,
        tile_sched_params: PersistentTileSchedulerParams,
    ):
        # The tiled MMA, smem layouts, smem and tmem memory allocations
        # can all be done outside the main kernel body.

        # Determine CTA group based on 2-CTA mode
        if cutlass.const_expr(self.use_2cta_instrs):
            cta_group = cute.nvgpu.tcgen05.CtaGroup.TWO
        else:
            cta_group = cute.nvgpu.tcgen05.CtaGroup.ONE

        tiled_mma = self._make_tiled_mma(cta_group)

        # Tiler for 2xSM if use 2xSM, otherwise it's for 1 SM/cta.
        mnk_tiler = self.mn_tiler

        # Number of MMA instructions along K per loaded K-tile.
        # This derivation works for the SM100 and SM107 atoms.
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = mnk_tiler[2] // mma_inst_shape_k

        # Tiler down to 1 SM
        # For 2xSM, each CTA loads half of mma_M for A and half of mma_N for B.
        # The accumulator is split along M only (each CTA holds full N columns).
        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        cta_tile_shape_mnk = cute.shape_div(mnk_tiler, (num_mma_ctas, 1, 1))
        # Cluster tile shape: each cluster covers cta_tile * cluster_shape along M and N.
        # The tile scheduler operates at cluster granularity.
        cluster_tile_shape_mnk = (
            cta_tile_shape_mnk[0] * self.cluster_shape[0],
            cta_tile_shape_mnk[1] * self.cluster_shape[1],
            cta_tile_shape_mnk[2],
        )

        mainloop_stage = self.mainloop_stage
        acc_stage = self.acc_stage

        cta_m, cta_n, cta_l = cute.arch.block_idx()
        mma_tile_coord_v = cta_m % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0

        # Per-CTA slice of the tiled MMA.
        # The pre-split tile keeps the per-atom inner-mode
        # structure that the TMA partition expects.
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)

        # Cluster layout for 2-CTA coordination
        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(self.cluster_shape),
            cute.core._pack_shape((cute.size(tiled_mma.thr_id.shape),)),
        )

        # Compute A/B/C shared memory layout
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

        # UMMA ACC TMEM Layout
        acc_shape = tiled_mma.partition_shape_C(mnk_tiler[:2])
        tmem_layout = tiled_mma.make_fragment_C(
            cute.append(acc_shape, acc_stage)
        ).layout

        # Allocate UMMA Buffers
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

        bufferAcc = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )

        # TMA multicast projection modes
        # A is shared by CTAs with same M (multicast across N, proj=2)
        # B is shared by CTAs with same N (multicast across M, proj=1)
        tma_mcast_proj_A = 2
        tma_mcast_proj_B = 1

        # Determine pipeline operation types based on 2-CTA mode and TMA multicast.
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

        # TMA -> UMMA pipeline
        mainloop_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=mainloop_stage,
            mma_operation_type=mma_operation_type,
            tma_operation_type=tma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # UMMA -> tcgen05.ld pipeline
        # For 2-CTA MMA, warpgroup from both peer and leader CTA consumer release
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
        # warp assignment: [0]-tma_store, [0-3]-epi, [4]-mma, [5]-tma_load, [6]-scheduler
        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_warp_id = 5
        scheduler_warp_id = 6
        is_tma_thr = warp_idx == tma_load_warp_id
        is_mma_thr = warp_idx == mma_warp_id
        is_epi_thr = warp_idx < 4
        is_sched_thr = warp_idx == scheduler_warp_id

        # st.shared -> TMA store
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

        # Shared memory buffer for tile scheduling info (9 int32 values per stage)
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

        # Create the persistent tile scheduler (used by scheduler warp only)
        tile_sched = StaticPersistentGroupTileScheduler.create(
            tile_sched_params,
            cute.arch.block_idx(),
            cute.arch.grid_dim(),
            cluster_tile_shape_mnk,
            create_initial_search_state(),
            self.group_count,
            problem_sizes_mnkl,  # device side problem shapes
        )
        tile_sched.prefetch_problem_shapes()
        initial_work_tile_info = tile_sched.initial_work_tile_info()

        #
        # Dedicated scheduler warp (warp 6)
        # Produces tile info into shared memory via mbarrier pipeline.
        #
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

        #
        # Specialized TMA load warp (warp 5)
        #
        elif is_tma_thr and initial_work_tile_info.is_valid_tile:
            cute.arch.setmaxregister_decrease(40)
            # Get initial pointers and tensors - Group 0, batch 0
            A_0_ptr = self._get_pointer(mA_ptrs[0], self.ab_dtype)
            B_0_ptr = self._get_pointer(mB_ptrs[0], self.ab_dtype)
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

            # group index of last tile
            last_group_idx = cutlass.Int32(0)
            # Decompose initial work tile into scalar loop-carried state
            is_valid_tile = initial_work_tile_info.is_valid_tile
            group_search_result = initial_work_tile_info.group_search_result

            # Persistent tile scheduling loop
            while is_valid_tile:
                cur_k_tile_cnt = group_search_result.cta_tile_count_k
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0
                cur_group_idx = group_search_result.group_idx

                if not is_k_tile_cnt_zero:
                    is_group_changed = cur_group_idx != last_group_idx

                    if is_group_changed:
                        # update pointers for the new group, call make_tensor
                        # Get problem shape and stride for each group
                        # Layout of the shape and strides is Tensor<ptr_address@gmem o (group_count,3):(3,1)>
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
                            ptr_A, layout=cute.make_layout(A_shape, stride=A_stride)
                        )
                        mB = cute.make_tensor(
                            ptr_B, layout=cute.make_layout(B_shape, stride=B_stride)
                        )
                        last_group_idx = cur_group_idx

                    # Tile by the full mma_tile and V-split the per-CTA atoms
                    # with `thr_mma.partition_{A,B}`.
                    # (bM, bK, RestM, RestK, RestL)
                    gA_mkl = cute.local_tile(
                        mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
                    )
                    # (bN, bK, RestN, RestK, RestL)
                    gB_nkl = cute.local_tile(
                        mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
                    )

                    # (MMA, MMA_M, MMA_K, RestM, RestK, RestL)
                    tCgA = thr_mma.partition_A(gA_mkl)
                    # (MMA, MMA_N, MMA_K, RestN, RestK, RestL)
                    tCgB = thr_mma.partition_B(gB_nkl)

                    # The scheduler hands out `cta_tile_idx_m` at per-CTA-M
                    # granularity; RestM is at mma_tile_M granularity, so divide
                    # by `num_mma_ctas`. RestN matches `cta_tile_idx_n` directly
                    # (thr_mma already V-split the per-CTA N for B).
                    mma_tile_coord_m = (
                        group_search_result.cta_tile_idx_m // num_mma_ctas
                    )
                    mma_tile_coord_n = group_search_result.cta_tile_idx_n

                    # Index the MMA atom (mode 0) with a single `None` so it
                    # stays one nested mode.
                    # Select the per-CTA M tile for A and N tile for B.
                    # The batch dim 0 is selected because we have only 1 batch per group.
                    # (MMA, MMA_M, MMA_K, RestK)
                    tAgA_slice = tCgA[(None, None, None, mma_tile_coord_m, None, 0)]
                    # (MMA, MMA_N, MMA_K, RestK)
                    tBgB_slice = tCgB[(None, None, None, mma_tile_coord_n, None, 0)]

                    for k in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                        # One per-atom slice per K iteration.
                        # (MMA, MMA_M, Stage)
                        gA_k = tAgA_slice[(None, None, None, k)]
                        # (MMA, MMA_N, Stage)
                        gB_k = tBgB_slice[(None, None, None, k)]

                        # Scoped state management - pipeline object manages state internally
                        (
                            producer_stage_token,
                            idx,
                        ) = mainloop_pipe.producer_acquire_and_get_stage()
                        mbar = cute_ext.get_mbarrier(producer_stage_token)
                        # Per-stage SMEM slice: (MMA, MMA_M, Stage)
                        bufferA_sliced = bufferA[None, None, None, idx]
                        # Per-stage SMEM slice: (MMA, MMA_N, Stage)
                        bufferB_sliced = bufferB[None, None, None, idx]

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

                        # For 2-CTA mode, only leader CTA commits
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

                # Consume next tile info from the scheduler pipeline
                tile_info_pipe, group_search_result, is_valid_tile = (
                    self._consume_work_tile_info(tile_info_pipe, sTile_info)
                )

        #
        # Specialized MMA warp (warp 4)
        #
        elif is_mma_thr and initial_work_tile_info.is_valid_tile:
            cute.arch.setmaxregister_increase(256)
            is_valid_tile = initial_work_tile_info.is_valid_tile
            group_search_result = initial_work_tile_info.group_search_result

            while is_valid_tile:
                cur_k_tile_cnt = group_search_result.cta_tile_count_k

                # Only leader CTA performs actual MMA work and acc pipeline ops.
                # Non-leader CTA's MMA warp still participates in the tile_info
                # pipeline to satisfy consumer_arv_count.
                if is_leader_cta:
                    _, idx = acc_pipe.producer_acquire_and_get_stage()
                    accumulators_sliced = bufferAcc[None, None, None, idx]

                    (updated_a_pipe, _updated_b_pipe) = cute_ext.mainloop_mma(
                        tiled_mma,
                        bufferA,
                        bufferB,
                        accumulators_sliced,
                        0,
                        cur_k_tile_cnt,
                        mma_inst_tile_k,
                        mainloop_pipe,
                        mainloop_pipe,
                    )
                    mainloop_pipe = updated_a_pipe

                    acc_pipe.producer_commit_and_advance()

                # Consume next tile info from the scheduler pipeline
                # (both leader and non-leader CTA MMA warps must participate)
                tile_info_pipe, group_search_result, is_valid_tile = (
                    self._consume_work_tile_info(tile_info_pipe, sTile_info)
                )

        #
        # Specialized epilogue warps (warps 0-3)
        #
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
            # group index of last tile
            last_group_idx = cutlass.Int32(0)

            # Persistent tile scheduling loop
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
                        ptr_D, layout=cute.make_layout(D_shape, stride=D_stride)
                    )
                    last_group_idx = cur_group_idx

                _, idx = acc_pipe.consumer_wait_and_get_stage()
                if not is_k_tile_cnt_zero:
                    # The MMA tiler covers REST_M = mn_tiler[0]/mma_inst_shape[0]
                    # atom tiles along M; the TMEM accumulator carries one
                    # output per atom.
                    # epilogue_tma_store handles REST_N but not REST_M > 1
                    # So we run a loop over REST_M and call epilogue_tma_store for each atom.

                    # This gives us the rest mode of M - will be 2
                    epi_rest_m = self.mn_tiler[0] // self.mma_inst_shape[0]
                    # Per-CTA M of a single atom = cta_tile_shape_mnk[0]/REST_M.
                    # For 2CTA with TILE_M=512, this becomes 128 because
                    # we have 2 CTAs and each should operate on half of the data.
                    epi_atom_m_per_cta = cta_tile_shape_mnk[0] // epi_rest_m
                    epi_atom_tile_shape_mnk = (
                        epi_atom_m_per_cta,
                        cta_tile_shape_mnk[1],
                        cta_tile_shape_mnk[2],
                    )

                    for m_atom in range(epi_rest_m):
                        accumulators_per_atom = bufferAcc[(None, None), m_atom, 0, idx]
                        cta_d_tile_coord_per_atom = (
                            group_search_result.cta_tile_idx_m * epi_rest_m + m_atom,
                            group_search_result.cta_tile_idx_n,
                            0,
                        )
                        tma_store_pipe = cute_ext.epilogue_tma_store(
                            epi_atom_tile_shape_mnk,
                            self.use_2cta_instrs,
                            accumulators_per_atom,
                            mD,
                            cta_d_tile_coord_per_atom,
                            tma_store_pipe,
                            tma_store_warp_id,
                            self.epilogue_op,
                            d_major_mode=self.d_layout_,
                        )
                acc_pipe.consumer_release_and_advance()

                # Consume next tile info from the scheduler pipeline
                tile_info_pipe, group_search_result, is_valid_tile = (
                    self._consume_work_tile_info(tile_info_pipe, sTile_info)
                )


def create_tensors(l, m, n, k, a_major, b_major, d_major, ab_dtype, d_dtype):
    a_torch_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype)
    b_torch_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype)
    d_torch_cpu = cutlass_torch.matrix(l, m, n, d_major == "m", d_dtype)

    a_tensor, a_torch_gpu = cutlass_torch.cute_tensor_like(
        a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b_tensor, b_torch_gpu = cutlass_torch.cute_tensor_like(
        b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    d_tensor, d_torch_gpu = cutlass_torch.cute_tensor_like(
        d_torch_cpu, d_dtype, is_dynamic_layout=True, assumed_align=16
    )

    return (
        a_tensor,
        b_tensor,
        d_tensor,
        a_torch_cpu,
        b_torch_cpu,
        d_torch_cpu,
        a_torch_gpu,
        b_torch_gpu,
        d_torch_gpu,
    )


# Helper creates a cute.Tensor from a List of device pointers
def make_tensor_of_ptrs(torch_tensor_array: List):
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


# Helper creates a cute.Tensor from a 2D List of int32 values
# The returned tensor has a shape of (G, 3) : (3,1),
# where G is the group count or size of the input list.
def make_2D_shape_tensor(shapes_list: List[List[int]]):
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
):
    num_groups = len(M_sizes)
    # Store torch gpu pointers
    As_torch_gpu = []
    Bs_torch_gpu = []
    Ds_torch_gpu = []
    # Store cute tensors
    A_cutes = []
    B_cutes = []
    D_cutes = []

    # Lists to store shapes and strides for each tensor
    A_shapes_host = []
    B_shapes_host = []
    D_shapes_host = []
    A_strides_host = []
    B_strides_host = []
    D_strides_host = []

    # Iterate over all groups
    # For each tensor A/B/D,
    # we need to have a list of `num_groups` pointers
    # and a list of `num_groups` problem shapes and strides
    for group_index in range(num_groups):
        # for each group, generate L tensors for M/N/K
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
                A_torch_cpu,
                B_torch_cpu,
                D_torch_cpu,
                A_torch_gpu,
                B_torch_gpu,
                D_torch_gpu,
            ) = create_tensors(
                1,  # hard code the L to 1 because we have a new pointer for each batch
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

        # Insert the shape and stride only after we have processed all batches in the group
        A_shapes_host.append(A_cutes[-1].shape)
        B_shapes_host.append(B_cutes[-1].shape)
        D_shapes_host.append(D_cutes[-1].shape)
        A_strides_host.append(A_cutes[-1].stride)
        B_strides_host.append(B_cutes[-1].stride)
        D_strides_host.append(D_cutes[-1].stride)

    assert len(A_cutes) == num_groups
    assert len(A_shapes_host) == num_groups
    assert len(A_strides_host) == num_groups

    # Create cute tensors of pointers
    # Layout: (num_groups) : (1)
    a_tensor, a_backing_torch_tensor = make_tensor_of_ptrs(As_torch_gpu)
    b_tensor, b_backing_torch_tensor = make_tensor_of_ptrs(Bs_torch_gpu)
    d_tensor, d_backing_torch_tensor = make_tensor_of_ptrs(Ds_torch_gpu)
    # Create cute tensors of shapes and strides
    # Layout: (num_groups, 3) : (3, 1)
    A_shapes_cute, A_shapes_torch = make_2D_shape_tensor(A_shapes_host)
    B_shapes_cute, B_shapes_torch = make_2D_shape_tensor(B_shapes_host)
    D_shapes_cute, D_shapes_torch = make_2D_shape_tensor(D_shapes_host)
    A_strides_cute, A_strides_torch = make_2D_shape_tensor(A_strides_host)
    B_strides_cute, B_strides_torch = make_2D_shape_tensor(B_strides_host)
    D_strides_cute, D_strides_torch = make_2D_shape_tensor(D_strides_host)

    problem_sizes_mnkl = [(M, N, K, 1) for M, N, K in zip(M_sizes, N_sizes, K_sizes)]
    # Layout: (num_groups, 4) : (4, 1)
    problem_sizes_mnkl_cute, problem_sizes_mnkl_torch = make_2D_shape_tensor(
        problem_sizes_mnkl
    )

    return (
        a_tensor,
        b_tensor,
        d_tensor,
        a_backing_torch_tensor,
        b_backing_torch_tensor,
        d_backing_torch_tensor,
        A_cutes,
        B_cutes,
        D_cutes,
        As_torch_gpu,
        Bs_torch_gpu,
        Ds_torch_gpu,
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


def compare(a_torch_cpu, b_torch_cpu, c_torch_gpu, c_dtype, tolerance):
    # FP8 tensors do not support torch.einsum directly; promote to float32
    # for the host-side reference computation. Round-tripping the FP8
    # values through float32 preserves the exact value of every element
    # since float32 is a strict superset of FP8.
    _FP8_DTYPES = (torch.float8_e4m3fn, torch.float8_e5m2)

    def _to_f32(x):
        return x.to(torch.float32) if x.dtype in _FP8_DTYPES else x

    ref = torch.einsum("mkl,nkl->mnl", _to_f32(a_torch_cpu), _to_f32(b_torch_cpu))

    _, ref_torch_gpu = cutlass_torch.cute_tensor_like(
        ref, c_dtype, is_dynamic_layout=True, assumed_align=16
    )
    ref_result = ref_torch_gpu.cpu()
    actual = c_torch_gpu.cpu()
    # torch.testing.assert_close does not accept FP8 dtypes directly; lift
    # both sides to float32 before comparing when the output is FP8.
    if actual.dtype in _FP8_DTYPES or ref_result.dtype in _FP8_DTYPES:
        actual = actual.to(torch.float32)
        ref_result = ref_result.to(torch.float32)
    torch.testing.assert_close(actual, ref_result, atol=tolerance, rtol=1e-05)


def run(
    num_groups: int,
    problem_sizes_mnkl: tuple[int, int, int, int],
    mma_tiler: Tuple[int, int, int],
    cluster_shape_mn: Tuple[int, int],
    ab_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
    acc_dtype: Type[Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    warmup_iterations: int = 0,
    iterations: int = 1,
    use_cold_l2: bool = False,
    tolerance: float = 1e-02,
    skip_ref_check: bool = False,
    use_2cta_instrs: bool = False,
    tma_update_mode: str | None = None,
    mma_inst_shape: Tuple[int, int, int] | None = None,
    arch: str = "sm_107",
    **kwargs,
):
    """Execute a grouped GEMM operation on the Rubin architecture with performance benchmarking.

    This function prepares input tensors, configures and launches the GEMM kernel,
    optionally performs reference validation, and benchmarks the execution performance.

    This kernel demonstrates the B-keep/B-reuse feature on Rubin when using a 2x larger tile size than the MMA instruction shape.
    The MMA instruction shape is exposed as an optional argument to the user.
    For a 1CTA run, mma_inst_shape_mn=128,128 and mma_tiler_mn=256,128 would trigger the B-keep/B-reuse feature.
    This is internally handled within the compiler via heuristics.

    NOTE: This is currently only supported for FP8 inputs. FP16 types will be supported in the future.

    :param mnkl: Problem size (M, N, K, L)
    :type mnkl: Tuple[int, int, int, int]
    :param mma_tiler_mn: MMA tiling size.
    :type mma_tiler_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster shape.
    :type cluster_shape_mn: Tuple[int, int]
    :param ab_dtype: Data type for input tensors A and B
    :type ab_dtype: Type[Numeric]
    :param c_dtype: Data type for output tensor C
    :type c_dtype: Type[Numeric]
    :param use_2cta_instrs: Use 2-CTA (2SM) instructions for larger tile sizes
    :type use_2cta_instrs: bool
    :param mma_inst_shape: Optional (M, N, K) shape of a single MMA instruction.
        When smaller than `mma_tiler_mn` along M, a single dot covers
        REST_M > 1 atom tiles, exposing the B-reuse expansion opportunity.
        Defaults to `mma_tiler_mn` (REST_M = 1).
    :type mma_inst_shape: Tuple[int, int, int] | None
    """
    if tma_update_mode not in (None, "gmem", "smem"):
        raise ValueError(
            f"Invalid tma_update_mode '{tma_update_mode}'. Expected one of: gmem, smem."
        )

    cli.print_problem_config(
        f"LIR Rubin ({arch.upper()}) Grouped GEMM",
        lines=[
            f"{num_groups} groups",
            *(
                f"Group {i}: {m}x{n}x{k}x{l}"
                for i, (m, n, k, l) in enumerate(problem_sizes_mnkl)
            ),
            f"AB dtype: {ab_dtype}, D dtype: {c_dtype}, Acc dtype: {acc_dtype}",
        ],
        majors={"A": a_major, "B": b_major, "D": c_major},
    )
    print(f"Mma Tiler (M, N, K): {mma_tiler}, Cluster Shape (M, N): {cluster_shape_mn}")
    print(
        "Mma Inst Shape (M, N, K): "
        f"{mma_inst_shape if mma_inst_shape is not None else mma_tiler}"
    )
    print(f"2CTA MMA instructions: {'True' if use_2cta_instrs else 'False'}")
    cli.print_benchmark_config(
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
        use_cold_l2=use_cold_l2,
    )
    print(
        f"TMA update mode: {tma_update_mode if tma_update_mode is not None else 'default(gmem)'}"
    )

    ab_dtype = ab_dtype
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
        a_backing_torch_tensor,
        b_backing_torch_tensor,
        d_backing_torch_tensor,
        A_cutes,
        B_cutes,
        D_cutes,
        As_torch_gpu,
        Bs_torch_gpu,
        Ds_torch_gpu,
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
        M_sizes, N_sizes, K_sizes, a_major, b_major, d_major, ab_dtype, d_dtype
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
    grouped_gemm = GroupedGemmKernel(
        mn_tiler=mma_tiler,
        mma_dtype=(ab_dtype, acc_dtype),
        tmem_output_dtype=d_dtype,
        group_count=num_groups,
        a_major_mode=a_major_mode,
        b_major_mode=b_major_mode,
        d_layout=d_layout,
        epilogue_op=lambda x: x,
        use_2cta_instrs=use_2cta_instrs,
        cluster_shape_mn=cluster_shape_mn,
        max_active_clusters=max_active_clusters,
        tma_update_mode=tma_update_mode,
        mma_inst_shape=mma_inst_shape,
        arch=arch,
    )

    compiled_grouped_gemm = cute_ext.compile(
        grouped_gemm,
        a_tensor,
        b_tensor,
        d_tensor,
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
                Ds_torch_gpu[group_idx],
                d_dtype,
                tolerance,
            )
        print("check reference: PASS")

    def generate_tensors():
        (
            a_tensor,
            b_tensor,
            d_tensor,
            a_backing_torch_tensor,
            b_backing_torch_tensor,
            d_backing_torch_tensor,
            A_cutes,
            B_cutes,
            D_cutes,
            As_torch_gpu,
            Bs_torch_gpu,
            Ds_torch_gpu,
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
        )

        ws = torch.empty(req.size_in_bytes, dtype=torch.uint8, device="cuda")
        ws_cute = from_dlpack(ws)

        args = testing.JitArguments(
            a_tensor,
            b_tensor,
            d_tensor,
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
            [A_cutes, B_cutes, D_cutes, As_torch_gpu, Bs_torch_gpu, Ds_torch_gpu]
        )
        return args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            sum(
                [
                    As_torch_gpu[group_idx].numel()
                    * As_torch_gpu[group_idx].element_size()
                    for group_idx in range(num_groups)
                ]
            )
            + sum(
                [
                    Bs_torch_gpu[group_idx].numel()
                    * Bs_torch_gpu[group_idx].element_size()
                    for group_idx in range(num_groups)
                ]
            )
            + sum(
                [
                    Ds_torch_gpu[group_idx].numel()
                    * Ds_torch_gpu[group_idx].element_size()
                    for group_idx in range(num_groups)
                ]
            )
            + sum(
                [
                    A_shapes_torch[group_idx].numel()
                    * A_shapes_torch[group_idx].element_size()
                    for group_idx in range(num_groups)
                ]
            )
            + sum(
                [
                    B_shapes_torch[group_idx].numel()
                    * B_shapes_torch[group_idx].element_size()
                    for group_idx in range(num_groups)
                ]
            )
            + sum(
                [
                    D_shapes_torch[group_idx].numel()
                    * D_shapes_torch[group_idx].element_size()
                    for group_idx in range(num_groups)
                ]
            )
            + sum(
                [
                    A_strides_torch[group_idx].numel()
                    * A_strides_torch[group_idx].element_size()
                    for group_idx in range(num_groups)
                ]
            )
            + sum(
                [
                    B_strides_torch[group_idx].numel()
                    * B_strides_torch[group_idx].element_size()
                    for group_idx in range(num_groups)
                ]
            )
            + sum(
                [
                    D_strides_torch[group_idx].numel()
                    * D_strides_torch[group_idx].element_size()
                    for group_idx in range(num_groups)
                ]
            )
            + sum(
                [
                    problem_sizes_mnkl_torch[group_idx].numel()
                    * problem_sizes_mnkl_torch[group_idx].element_size()
                    for group_idx in range(num_groups)
                ]
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

    print("Average Runtime : ", exec_time / 1000, "ms")
    if runtime_s == 0:
        print("GFLOPS          :  n/a (zero measured runtime)")
    else:
        print("GFLOPS          : ", gflop / runtime_s)

    return exec_time  # Return execution time in microseconds


if __name__ == "__main__":

    def parse_problem_sizes_mnkl(s: str) -> List[Tuple[int, int, int, int]]:
        """
        Parse a string of problem sizes in the format "(M,N,K,L),(M,N,K,L),..."
        Example: "(512,1024,128,1),(128,256,128,1),(384,1408,128,1)"
        Returns a list of (M, N, K, L) tuples.
        """
        import re

        try:
            # Remove any whitespace
            s = s.strip()
            # Find all tuples matching the pattern (int,int,int,int)
            pattern = r"\((\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\)"
            matches = re.findall(pattern, s)
            if not matches:
                raise ValueError("No valid tuples found")
            result = [(int(m), int(n), int(k), int(l)) for m, n, k, l in matches]
            # Validate that L must be 1 for each tuple
            for i, (m, n, k, l) in enumerate(result):
                if l != 1:
                    raise ValueError(
                        f"L must be 1 in each (M,N,K,L) tuple, but got L={l} in tuple {i}: ({m},{n},{k},{l})"
                    )
            return result
        except Exception as e:
            raise argparse.ArgumentTypeError(
                f"Invalid format. Expected '(M,N,K,L),(M,N,K,L),...' but got '{s}'. Error: {e}"
            )

    parser = argparse.ArgumentParser(
        description="Example of LIR Dense GEMM on Blackwell."
    )

    parser.add_argument(
        "--mnkl",
        type=cli.comma_separated_ints,
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--problem_sizes_mnkl",
        type=parse_problem_sizes_mnkl,
        default=[(256, 256, 512, 1), (1024, 512, 256, 1)],
        help='Problem sizes as comma-separated tuples, e.g. "(512,1024,128,1),(128,256,128,1),(384,1408,128,1)"',
    )
    parser.add_argument(
        "--num_groups",
        type=int,
        default=None,
        help="Number of groups (must match the number of tuples in --problem_sizes_mnkl)",
    )
    parser.add_argument(
        "--mma_tiler",
        type=cli.comma_separated_ints,
        default=(128, 128, 128),
        help="Mma tile shape (comma-separated)",
    )
    parser.add_argument(
        "--mma_inst_shape",
        type=cli.comma_separated_ints,
        default=None,
        help=(
            "MMA instruction (atom) shape M,N (comma-separated). When smaller "
            "than --mma_tiler_mn along M, REST_M > 1 and the LIR B-reuse "
            "expansion pass becomes applicable. Defaults to --mma_tiler_mn."
        ),
    )
    cli.add_cluster_shape_arg(parser)
    cli.add_dtype_args(parser, ab=cutlass.Float32, c=cutlass.Float32)
    cli.add_major_args(parser)
    cli.add_benchmark_args(parser, tolerance=1e-02)
    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Use 2-CTA (2SM) instructions for larger tile sizes",
    )
    parser.add_argument(
        "--tma_update_mode",
        choices=["gmem", "smem"],
        default=None,
        help="Per-kernel TMA descriptor update mode. If unset, falls back to env var compatibility.",
    )
    parser.add_argument("--arch", type=str, default="sm_107")

    args = parser.parse_args()

    if len(args.mma_tiler) != 3:
        parser.error("--mma_tiler must contain exactly 3 values")

    if args.mma_inst_shape is not None and len(args.mma_inst_shape) != 3:
        parser.error("--mma_inst_shape must contain exactly 3 values")

    problem_sizes_mnkl = args.problem_sizes_mnkl

    # Determine num_groups: use --num_groups if provided, otherwise infer from problem_sizes_mnkl
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
        args.mma_tiler,
        args.cluster_shape_mn,
        args.ab_dtype,
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
        mma_inst_shape=args.mma_inst_shape,
        arch=args.arch,
    )

    print(f"Execution time: {exec_time} microseconds per iteration")
