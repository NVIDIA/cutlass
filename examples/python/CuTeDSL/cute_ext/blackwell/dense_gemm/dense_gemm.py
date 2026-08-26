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
import os
import sys

import torch
from typing import Type, Tuple

import cutlass
from cutlass.cute import experimental as cute_ext
from cutlass.base_dsl.typing import Numeric
from cutlass import cute as cute
from cutlass import torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils

from cutlass import testing

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))

from helpers import cli_helper as cli

# ====================================================================================================
#
# This kernel implements a batched dense GEMM operation: D = A @ B
# where:
#   - A has shape (M, K, L) and is stored in global memory
#   - B has shape (N, K, L) and is stored in global memory
#   - D has shape (M, N, L) and is the output in global memory
#   - L is the batch dimension
#
# The kernel uses Python DSL for writing high-performance, Blackwell (SM100)-targeted kernels on top of CuTe abstractions.
#
# KEY CONCEPTS:
# - TMA (Tensor Memory Accelerator): Hardware feature for high-bandwidth GMEM <-> SMEM transfers
# - UMMA/MMA: Unified Matrix Multiply-Accumulate hardware units on SM100
# - TMEM: Tensor Memory - Blackwell's specialized memory for MMA accumulators
# - SMEM: Shared Memory - CTA-local memory for staging data
# - RMEM: Register Memory - Per-thread registers
#
# DATA FLOW:
#   GMEM (A,B) --TMA--> SMEM (bufferA, bufferB) --MMA--> TMEM (accumulators)
#   TMEM --copy--> RMEM (bufferRAcc) --epilogue--> RMEM (bufferRD) --copy--> SMEM (bufferC) --TMA--> GMEM (D)
#
# WARP SPECIALIZATION:
# This kernel uses 6 warps (192 threads) with specialized roles:
#   - Warp 5: TMA load producer (loads A, B tiles from GMEM to SMEM)
#   - Warp 4: MMA compute (performs matrix multiply-accumulate)
#   - Warps 0-3: Epilogue (TMEM->RMEM->SMEM) and TMA store (warp 0 only)
#
# PIPELINE ARCHITECTURE:
# The kernel uses software pipelining to overlap memory transfers with compute:
#   - mainloop_pipe: TMAToUMMAPipeline - synchronizes TMA loads with MMA operations
#   - acc_pipe: UMMAtoAsyncPipeline - synchronizes MMA with TMEM->RMEM copies
#   - tma_store_pipe: TMAStorePipeline - synchronizes SMEM writes with TMA stores
#
# ====================================================================================================


def _compute_stages(
    tiled_mma: cute.TiledMma,
    mnk_tiler: Tuple[int, int, int],
    ab_dtype: Type[Numeric],
    tmem_output_dtype: Type[Numeric],
    mD: cute.Tensor,
    use_2cta_instrs: bool,
    smem_capacity: int,
    occupancy: int = 1,
    reserved_smem_bytes: int = 1024,
) -> Tuple[int, int, int]:
    """Computes the number of pipeline stages for the accumulator, mainloop (A/B),
    and TMA-store epilogue (C).

    Uses a two-pass allocation: first fixes A/B stages with 2 initial epilogue
    stages, then grows the epilogue stage count from leftover SMEM.

    :param tiled_mma: The tiled MMA object defining the core computation.
    :param mnk_tiler: The shape (M, N, K) of the MMA tiler.
    :param ab_dtype: Data type of operands A and B.
    :param tmem_output_dtype: Data type written to SMEM for TMA store.
    :param mD: Output tensor D, used to derive the epilogue layout.
    :param use_2cta_instrs: Whether 2-CTA MMA instructions are used.
    :param smem_capacity: Total available shared memory capacity in bytes.
    :param occupancy: Target number of CTAs per SM (default 1 for persistent kernels).
    :param reserved_smem_bytes: Bytes reserved for mbarriers and CLC response buffer.

    :return: (acc_stage, mainloop_stage, tma_store_stage)
    :rtype: Tuple[int, int, int]
    """
    acc_stage = 2
    initial_epi_stage = 2

    ab_bytes_per_stage = cute.size_in_bytes(
        ab_dtype,
        sm100_utils.make_smem_layout_a(tiled_mma, mnk_tiler, ab_dtype, 1),
    ) + cute.size_in_bytes(
        ab_dtype,
        sm100_utils.make_smem_layout_b(tiled_mma, mnk_tiler, ab_dtype, 1),
    )

    cta_tile_shape_mnk = cute.shape_div(
        mnk_tiler, (cute.size(tiled_mma.thr_id.shape), 1, 1)
    )
    d_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD)
    epi_tile = sm100_utils.compute_epilogue_tile_shape(
        cta_tile_shape_mnk, use_2cta_instrs, d_layout, tmem_output_dtype
    )
    epi_bytes_per_stage = cute.size_in_bytes(
        tmem_output_dtype,
        sm100_utils.make_smem_layout_epi(tmem_output_dtype, d_layout, epi_tile, 1),
    )
    epi_bytes_initial = epi_bytes_per_stage * initial_epi_stage

    mainloop_stage = max(
        1,
        (smem_capacity // occupancy - epi_bytes_initial - reserved_smem_bytes)
        // ab_bytes_per_stage,
    )

    # Grow epilogue stages from leftover SMEM (mirrors CuteDSL refine step).
    leftover = (
        smem_capacity // occupancy
        - mainloop_stage * ab_bytes_per_stage
        - epi_bytes_initial
        - reserved_smem_bytes
    )
    tma_store_stage = initial_epi_stage + max(0, leftover // epi_bytes_per_stage)

    return acc_stage, mainloop_stage, tma_store_stage


class DenseGemmKernel:
    """
    Dense GEMM kernel class for Blackwell (SM100) GPUs.

    This class encapsulates all the configuration and logic for a high-performance
    batched matrix multiplication: D = A @ B (with optional epilogue operation).

    The design follows IR conventions:
    1. __init__: Store configuration parameters
    2. __call__: JIT-decorated host launcher that computes grid and calls kernel
    3. kernel: Device kernel that performs the actual computation

    Attributes:
        mn_tiler (tuple[int, int]): Tile sizes for M and N dimensions (e.g., (128, 256))
        mma_dtype (tuple[Type[Numeric], Type[Numeric]]): Data types for input matrices A and B
            and accumulators
        tmem_output_dtype (Type[Numeric]): Data type for TMEM->RMEM copy output
        use_2cta_instrs (bool): Whether to use 2-CTA MMA instructions (False = 1-CTA mode)
        epilogue_op (callable): Optional epilogue function applied to output (default: identity)
    """

    def __init__(
        self,
        mn_tiler: tuple[int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric]],
        tmem_output_dtype: Type[Numeric],
        epilogue_op=lambda x: x,
        use_2cta_instrs: bool = False,
        cluster_shape_mn: Tuple[int, int] = (2, 1),
        use_tma_store: bool = True,
    ):
        """
        Initialize the Dense GEMM kernel configuration.

        Args:
            mn_tiler: Tuple (M_tile, N_tile) specifying the tile dimensions.
                     CONSTRAINT: M must be 64 or 128 (SM100 hardware requirement).
                     Common configurations: (128, 256), (128, 128), (64, 128)

            mma_dtype: Tuple (input_dtype, accumulator_dtype)
                      - input_dtype: Element type for A and B (e.g., Float16, Float8E4M3FN)
                      - accumulator_dtype: Precision for accumulation (typically Float32)

            tmem_output_dtype: Element type for TMEM output during epilogue.
                              Typically matches the output matrix type.

            epilogue_op: Optional function applied to accumulator values before store.
                        Default is identity (lambda x: x).
                        Examples: relu, sigmoid, GELU approximations using cute.exp/cute.where

            use_tma_store: Whether to use TMA store for the epilogue (RMEM→SMEM→TMA→GMEM).
                          When False, uses direct RMEM→GMEM store via SIMT copy.
                          Non-TMA store requires M,N divisible by CTA tile (no OOB predication).
        """
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.tmem_output_dtype = tmem_output_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.use_tma_store = use_tma_store

        # Pipeline stage counts. __call__ overwrites these via _compute_stages
        # when launched normally. Callers that invoke kernel() directly (e.g.
        # GETT tests) use these defaults, which match the pre-dynamic values.
        self.mainloop_stage = 4
        self.acc_stage = 2
        self.TMA_STORE_STAGE = 2

        # Epilogue operation applied in registers before storing output.
        self.epilogue_op = epilogue_op

        # Cluster shape for CTA grouping and TMA multicast coordination.
        # Default is (2, 1) for 2-CTA mode, (1, 1) for 1-CTA mode.
        self.cluster_shape = (cluster_shape_mn[0], cluster_shape_mn[1], 1)
        cluster_shape_mn_selfcast = (2, 1) if use_2cta_instrs else (1, 1)
        self.use_tma_multicast = cluster_shape_mn != cluster_shape_mn_selfcast

    @cute.experimental.jit
    def __call__(self, mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        """
        Host-side JIT-compiled launcher function.

        The @cute.experimental.jit decorator indicates this function:
        - Runs on the HOST (CPU)
        - Is JIT-compiled when first called
        - Computes launch configuration and invokes the GPU kernel

        This function performs two key tasks:
        1. Compute the grid dimensions based on output tensor shape and tile size
        2. Launch the kernel with appropriate grid/block/cluster/smem configuration

        Args:
            mA: Input tensor A in global memory, shape (M, K, L) where L is batch
            mB: Input tensor B in global memory, shape (N, K, L)
            mD: Output tensor D in global memory, shape (M, N, L)

        CUTE ALGEBRA EXPLANATION - tiled_divide:
        -----------------------------------------
        cute.tiled_divide(tensor, tiler) divides a tensor into tiles, producing a tensor
        with shape: ((Tile), Rest_M, Rest_N, ...)

        Unlike zipped_divide which groups rest dimensions: ((Tile), (Rest_M, Rest_N, ...))
        tiled_divide keeps rest dimensions SEPARATE, making it ideal for grid computation.

        For example, if mD has shape (1024, 1024, 2) and tile_mn = (128, 128, 1):
        - div.shape[0] = (128, 128, 1) - the tile shape
        - div.shape[1] = 8             - number of tiles in M dimension (1024/128)
        - div.shape[2] = 8             - number of tiles in N dimension (1024/128)
        - div.shape[3] = 2             - batch dimension L

        The grid is then (8, 8, 2) = 128 CTAs total, each processing one (128, 128) tile.
        """

        cta_tile_mnk = (
            self.mn_tiler[0] // 2 if self.use_2cta_instrs else self.mn_tiler[0],
            self.mn_tiler[1],
            1,
        )

        # Grid dimensions: (num_tiles_M, num_tiles_N, batch_size)
        # Each CTA (Cooperative Thread Array / thread block) processes one tile.
        grid = cute.round_up(
            (
                cute.ceil_div(mD.layout.shape[0], cta_tile_mnk[0]),
                cute.ceil_div(mD.layout.shape[1], cta_tile_mnk[1]),
                mD.layout.shape[2],
            ),
            self.cluster_shape,
        )

        # Compute pipeline stages in the host JIT context (smem capacity is
        # device-queried) so the static-scheduler kernel uses the same staging
        # depth as the persistent dynamic kernel.
        if cutlass.const_expr(self.use_2cta_instrs):
            cta_group = cute.nvgpu.tcgen05.CtaGroup.TWO
        else:
            cta_group = cute.nvgpu.tcgen05.CtaGroup.ONE
        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.ab_dtype,
            self.ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            self.acc_dtype,
            cta_group,
            self.mn_tiler,
        )
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        mnk_tiler = (
            self.mn_tiler[0],
            self.mn_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        self.acc_stage, self.mainloop_stage, self.TMA_STORE_STAGE = _compute_stages(
            tiled_mma,
            mnk_tiler,
            self.ab_dtype,
            self.tmem_output_dtype,
            mD,
            self.use_2cta_instrs,
            smem_capacity=cutlass.memory.get_smem_capacity_in_bytes(),
        )

        # Launch the kernel with Blackwell-specific configuration:
        # - block=(192, 1, 1): 6 warps × 32 threads/warp = 192 threads
        #   Warp assignment: warps 0-3 (epilogue), warp 4 (MMA), warp 5 (TMA load)
        # - cluster=(1, 1, 1): Single-CTA mode (no cluster cooperation)
        # - smem: Request maximum shared memory capacity for SM100 (~232KB)
        self.kernel(mA, mB, mD).launch(
            grid=grid,
            block=(192, 1, 1),
            cluster=self.cluster_shape,
            smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100")),
        )

    @cute.experimental.kernel
    def kernel(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mD: cute.Tensor,
    ):
        """
        Device-side kernel function - the actual GPU computation.

        The @cute.experimental.kernel decorator indicates this function:
        - Runs on the DEVICE (GPU)
        - Contains all SMEM/TMEM/RMEM allocations, pipeline setup, and compute logic
        - Is compiled to PTX and executed by each thread in the grid

        This kernel follows the standard IR GEMM structure:
        1. Create tiled_mma configuration
        2. Compute tiler and divide tensors
        3. Allocate SMEM, TMEM, and RMEM buffers
        4. Create pipelines for producer/consumer synchronization
        5. Assign warps to specialized roles
        6. Execute TMA load, MMA compute, and epilogue/store phases

        Args:
            mA: Input A tensor (GMEM), shape (M, K, L)
            mB: Input B tensor (GMEM), shape (N, K, L)
            mD: Output D tensor (GMEM), shape (M, N, L)
        """

        # ========================================================================================
        # STEP 1: CREATE TILED MMA CONFIGURATION
        # ========================================================================================
        # The tiled_mma object encapsulates the MMA instruction configuration for Blackwell.
        # It defines:
        # - The MMA atom shape (the hardware instruction's native tile size)
        # - Thread-to-data mapping for the MMA operation
        # - Layout requirements for operands
        #
        # make_trivial_tiled_mma creates a basic tiled MMA configuration:
        # - ab_dtype: Element type for A and B operands
        # - mma_major_mode(): Returns the major mode for MMA (K-major or MN-major)
        # - acc_dtype: Accumulator precision (typically Float32)
        # - CtaGroup.ONE: Single-CTA MMA (vs TWO for cooperative 2-CTA)
        # - mn_tiler: The (M, N) tile dimensions
        #
        # The mma_major_mode() is derived from the tensor layout:
        # - K-major A: stride(A)[1] < stride(A)[0] (K is the fast dimension)
        # - M-major A: stride(A)[0] < stride(A)[1] (M is the fast dimension)
        # Determine CTA group based on 2-CTA mode
        if cutlass.const_expr(self.use_2cta_instrs):
            cta_group = cute.nvgpu.tcgen05.CtaGroup.TWO
        else:
            cta_group = cute.nvgpu.tcgen05.CtaGroup.ONE
        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.ab_dtype,
            self.ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            self.acc_dtype,
            cta_group,
            self.mn_tiler,
        )

        # ========================================================================================
        # STEP 2: COMPUTE TILER DIMENSIONS (MNK)
        # ========================================================================================
        # The MMA instruction operates on tiles. We need to compute the full MNK tiler
        # which includes the K dimension (reduction dimension).
        #
        # cute.size(tiled_mma.shape_mnk, mode=[2]):
        # - tiled_mma.shape_mnk is the (M, N, K) shape of the MMA instruction
        # - mode=[2] extracts the K dimension (0=M, 1=N, 2=K)
        # - For SM100, this is typically 16 (the instruction's native K)
        #
        # mma_inst_tile_k (=4) is the number of MMA instructions per K-tile iteration.
        # This is a tuning parameter:
        # - Higher values (8): Larger K-tile, better MMA utilization, but more SMEM
        # - Lower values (2): Smaller K-tile, less SMEM, but more loop iterations
        # - 4 is a safe default that balances these tradeoffs
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4

        # Tiler for 2xSM if use 2xSM, otherwise it's for 1 SM/cta.
        # Full MNK tiler: (M_tile, N_tile, K_tile)
        # K_tile = mma_inst_shape_k * mma_inst_tile_k (e.g., 16 * 4 = 64)
        mnk_tiler = (
            self.mn_tiler[0],
            self.mn_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )

        # Get output tensor layout and type for epilogue configuration
        d_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD)
        d_dtype = mD.element_type

        # Tiler down to 1 SM
        # For 2xSM, each CTA loads half of mma_M for A and half of mma_N for B.
        # The accumulator is split along M only (each CTA holds full N columns).
        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        cta_tile_shape_mnk = cute.shape_div(mnk_tiler, (num_mma_ctas, 1, 1))
        a_tiler_mk = (cta_tile_shape_mnk[0], cta_tile_shape_mnk[2])
        b_tiler_nk = (cta_tile_shape_mnk[1] // num_mma_ctas, cta_tile_shape_mnk[2])
        c_tiler_mn = (cta_tile_shape_mnk[0], cta_tile_shape_mnk[1])

        # ========================================================================================
        # STEP 3: DIVIDE GLOBAL TENSORS INTO TILES (zipped_divide)
        # ========================================================================================
        # cute.zipped_divide is the PRIMARY tiling operation in IR kernels.
        #
        # CUTE ALGEBRA EXPLANATION - zipped_divide:
        # ------------------------------------------
        # zipped_divide(tensor, tiler) divides a tensor into tiles and produces:
        # - Mode 0: The tile shape itself
        # - Mode 1: A "zipped" layout of tile coordinates
        #
        # Result shape: ((TileM, TileK), (RestM, RestK, L))
        #
        # For example, if mA has shape (1024, 512, 2) and tiler_mk = (128, 64):
        # - gA shape = ((128, 64), (8, 8, 2))
        # - (128, 64): One tile of A
        # - (8, 8, 2): 8 tiles in M, 8 tiles in K, 2 batches = 128 total tiles
        #
        # Key difference from tiled_divide:
        # - zipped_divide: ((Tile), (Rest...)) - rest dimensions grouped together
        # - tiled_divide:  ((Tile), Rest_M, Rest_N, ...) - rest dimensions separate
        #
        # zipped_divide is preferred for CTA tile selection because the zipped
        # rest coordinates can be indexed with a single (cta_m, k, batch) tuple.
        gA = cute.zipped_divide(mA, a_tiler_mk)
        gB = cute.zipped_divide(mB, b_tiler_nk)
        gD = cute.zipped_divide(mD, c_tiler_mn)

        # ========================================================================================
        # STEP 4: PIPELINE CONFIGURATION
        # ========================================================================================
        # mainloop_stage: Number of pipeline stages for the TMA load → MMA pipeline.
        # acc_stage: Number of accumulator stages in TMEM.
        # Both are computed on the host in __call__ via _compute_stages (the same
        # SMEM-budget calculation the persistent dynamic kernel uses) so the
        # static-scheduler kernel pipelines to the same depth -- a prerequisite
        # for a fair comparison. They replace the previously hard-coded
        # mainloop_stage=4 / acc_stage=2.
        mainloop_stage = self.mainloop_stage
        acc_stage = self.acc_stage

        # ========================================================================================
        # STEP 5: GET CTA AND THREAD INDICES
        # ========================================================================================
        # Each CTA is identified by its position in the 3D grid: (cta_m, cta_n, cta_l)
        # - cta_m: Which M-tile this CTA processes
        # - cta_n: Which N-tile this CTA processes
        # - cta_l: Which batch element this CTA processes
        #
        # Each thread within a CTA is identified by tid_x (0-191 for 192 threads).
        cta_m, cta_n, cta_l = cute.arch.block_idx()
        tid_x, _, _ = cute.arch.thread_idx()

        # Cluster layout for 2-CTA coordination
        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(self.cluster_shape),
            cute.core._pack_shape((cute.size(tiled_mma.thr_id.shape),)),
        )
        cluster_layout_v_size = cute.size(cluster_layout_vmnk.shape[0])

        # MMA coordinate within cluster
        mma_coord_vmnk = (
            cta_m % cluster_layout_v_size,
            cta_m // cluster_layout_v_size,
            cta_n,
        )
        is_leader_cta = mma_coord_vmnk[0] == 0
        thr_mma = tiled_mma.get_slice(mma_coord_vmnk[0])

        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB_nkl = cute.local_tile(
            mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        tCgA = thr_mma.partition_A(gA_mkl)
        tCgB = thr_mma.partition_B(gB_nkl)
        mma_tile_coord_m = cta_m // cluster_layout_v_size
        tAgA_slice = tCgA[(None, None, None, mma_tile_coord_m, None, cta_l)]
        tBgB_slice = tCgB[(None, None, None, cta_n, None, cta_l)]
        gD_tile = gD[(None, None), (cta_m, cta_n, cta_l)]

        # ========================================================================================
        # STEP 7: CREATE SMEM LAYOUTS WITH SWIZZLING
        # ========================================================================================
        # SMEM layouts must:
        # 1. Match the tile dimensions from the tiler
        # 2. Include staging for pipeline buffers
        # 3. Use swizzle patterns to avoid bank conflicts
        #
        # make_smem_layout_a/b are helper functions that:
        # - Select appropriate swizzle patterns based on major mode and element type
        # - Append the stage dimension for pipelining
        # - Return a ComposedLayout (layout + swizzle function)
        #
        # The swizzle pattern interleaves memory addresses across the 32 SMEM banks,
        # ensuring that when a warp accesses consecutive elements, they hit different
        # banks (avoiding serialization from bank conflicts).
        #
        # LAYOUT SHAPE: (MMA_ATOM, MMA_TILE, MMA_K, PIPELINE_STAGES)
        # For operand A: this encodes how to store M×K tiles with proper bank conflict avoidance
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

        # ========================================================================================
        # STEP 8: COMPUTE EPILOGUE TILE SHAPE
        # ========================================================================================
        # The epilogue processes output tiles in smaller sub-tiles (epi_tile).
        # This is necessary because:
        # 1. TMEM→RMEM copies have granularity constraints
        # 2. TMA stores work on specific tile sizes
        #
        # cta_tile_shape_mnk: The effective tile shape per CTA after accounting for
        # thread-level tiling. This is computed as:
        #   mnk_tiler / (num_threads_in_mma, 1, 1)
        #
        # cute.shape_div performs element-wise division of shapes.
        # cute.size(tiled_mma.thr_id.shape) gives the number of threads participating in MMA.

        # compute_epilogue_tile_shape determines the sub-tile size for epilogue operations.
        # It considers:
        # - CTA tile shape
        # - Whether using 1-CTA or 2-CTA instructions
        # - Output layout (M-major or N-major)
        # - Output data type
        if cutlass.const_expr(self.use_tma_store):
            epi_tile = sm100_utils.compute_epilogue_tile_shape(
                cta_tile_shape_mnk,
                self.use_2cta_instrs,
                d_layout,
                d_dtype,
            )

            # Create epilogue SMEM layout for TMA stores.
            # This layout is used for the bufferC staging buffer before TMA store to GMEM.
            sc_smem_layout_staged = sm100_utils.make_smem_layout_epi(
                d_dtype,
                d_layout,
                epi_tile,
                self.TMA_STORE_STAGE,
            )
        else:
            # Non-TMA store: use full CTA tile as epilogue tile (no subtiling).
            epi_tile = cta_tile_shape_mnk[:2]

        # ========================================================================================
        # STEP 9: CREATE TMEM LAYOUT FOR ACCUMULATORS
        # ========================================================================================
        # TMEM (Tensor Memory) is Blackwell's specialized memory for MMA accumulators.
        # It provides high-bandwidth access for accumulator updates during MMA operations.
        #
        # TMEM CHARACTERISTICS:
        # - Accessible only by the MMA unit within a warpgroup
        # - Has a capacity limit of 512 columns
        # - Requires specific layout patterns matching MMA instructions
        #
        # make_tmem_layout_acc: Derives the TMEM accumulator buffer layout from the
        # tiled MMA and MNK tiler, with the given number of pipeline stages.
        tmem_layout = cute_ext.make_tmem_layout_acc(tiled_mma, mnk_tiler, acc_stage)

        # ========================================================================================
        # STEP 10: ALLOCATE SMEM BUFFERS
        # ========================================================================================
        # cute_ext.allocate creates a tensor in the specified address space.
        #
        # Arguments:
        # - type: Element type (e.g., Float16, Float32)
        # - address_space: One of smem, tmem, rmem, gmem
        # - layout: The layout including staging dimensions
        # - alignment: Byte alignment (1024 for SMEM, 16 for TMEM, 32 for RMEM)
        #
        # ALIGNMENT RATIONALE:
        # - SMEM (1024 bytes): Optimal for TMA transfers and swizzle patterns
        # - TMEM (16 bytes): Standard tensor memory alignment
        # - RMEM (32 bytes): Vectorized register loads/stores

        # Allocate SMEM buffers for A and B operands.
        # These buffers hold multiple pipeline stages of tiles loaded from GMEM.
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

        # Allocate TMEM buffer for MMA accumulators.
        # This stores the running sum: C += A × B across K iterations.
        bufferAcc = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )

        # Allocate SMEM buffer for output (C) - used during epilogue before TMA store.
        if cutlass.const_expr(self.use_tma_store):
            bufferC = cute_ext.allocate(
                d_dtype,
                cutlass.AddressSpace.smem,
                sc_smem_layout_staged,
                alignment=1024,
            )

        # ========================================================================================
        # STEP 11: CREATE TMEM->RMEM COPY CONFIGURATION
        # ========================================================================================
        # The epilogue copies data from TMEM (accumulators) → RMEM (registers) → SMEM → GMEM.
        # This section sets up the copy atoms and tiled copies for this path.
        #
        # get_tmem_load_op: Returns the appropriate tcgen05 load operation for TMEM→RMEM.
        # It selects the right instruction based on:
        # - CTA tile shape
        # - Output layout orientation
        # - Data types
        # - Epilogue tile size
        # - 1-CTA vs 2-CTA mode
        copy_atom_t2r = sm100_utils.get_tmem_load_op(
            cta_tile_shape_mnk,
            d_layout,
            self.tmem_output_dtype,
            self.acc_dtype,
            epi_tile,
            self.use_2cta_instrs,
        )

        # ========================================================================================
        # STEP 12: PREPARE ACCUMULATOR FOR EPILOGUE ITERATION
        # ========================================================================================
        # The accumulator buffer is divided into epilogue-sized sub-tiles for iteration.
        #
        # CUTE ALGEBRA EXPLANATION - zipped_divide on accumulators:
        # ----------------------------------------------------------
        # We divide bufferAcc by (epi_tile, 1) to create sub-tiles for epilogue processing.
        # The "1" preserves the stage dimension.
        #
        # accumulators = cute.zipped_divide(bufferAcc, ((epi_tile), 1))
        # This creates: ((epi_tile_shape), (rest_subtiles, stages))
        #
        # acc_epi_div = accumulators[((None, None), 0), 0]
        # - (None, None): Keep the epilogue tile shape
        # - 0: Select the first rest-mode position
        # - 0: Select the first stage (for tiled_copy_t2r creation)
        #
        # This gives us one epilogue tile's worth of data for configuring the copy.
        accumulators = cute.zipped_divide(bufferAcc, ((epi_tile), 1))
        acc_epi_div = accumulators[((None, None), 0), 0]

        # Create the tiled copy operation for TMEM→RMEM.
        # make_tmem_copy creates a TiledCopy object that defines:
        # - How threads partition the source (TMEM)
        # - How threads partition the destination (RMEM)
        # - The mapping between source and destination layouts
        tiled_copy_t2r = cute.nvgpu.tcgen05.make_tmem_copy(copy_atom_t2r, acc_epi_div)

        # ========================================================================================
        # STEP 13: DERIVE RMEM LAYOUT FROM COPY PARTITION
        # ========================================================================================
        # RMEM layouts must match the thread-value ownership pattern of the copy.
        # We derive the RMEM layout by partitioning the destination and extracting
        # the per-thread layout.
        #
        # CUTE ALGEBRA EXPLANATION - flat_divide:
        # ---------------------------------------
        # flat_divide(tensor, tiler) flattens all dimensions:
        # Result shape: (Tile_M, Tile_N, Rest_M, Rest_N, ...)
        #
        # Unlike zipped_divide which groups tile and rest separately,
        # flat_divide keeps everything flat, which is useful for iteration.
        #
        # make_t2r_rmem_layout: Derives the per-thread RMEM buffer layout
        # produced by a TMEM->RMEM copy for a single epilogue iteration.
        gC_mnl_epi = cute.flat_divide(gD_tile, epi_tile)
        acc_d_rmem_layout = cute_ext.make_t2r_rmem_layout(
            tiled_copy_t2r, gC_mnl_epi, tid_x
        )

        # ========================================================================================
        # STEP 14: ALLOCATE RMEM BUFFERS FOR EPILOGUE
        # ========================================================================================
        # RMEM (Register Memory) is per-thread storage. Each thread has its own
        # private copy of these buffers.
        #
        # bufferRAcc: Holds accumulator values copied from TMEM (FP32)
        # bufferRD: Holds output values after epilogue conversion (output dtype)
        bufferRAcc = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout,
            alignment=32,
        )
        bufferRD = cute_ext.allocate(
            d_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout,
            alignment=32,
        )

        # ========================================================================================
        # STEP 15: CREATE PIPELINES
        # ========================================================================================
        # Pipelines provide producer/consumer synchronization using hardware barriers.
        # They enable overlapping of memory operations with compute.

        # TMA multicast projection modes
        # A is shared by CTAs with same M (multicast across N, proj=2)
        # B is shared by CTAs with same N (multicast across M, proj=1)
        tma_mcast_proj_A = 2
        tma_mcast_proj_B = 1

        # Determine pipeline operation types based on 2-CTA mode and TMA multicast
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

        # PIPELINE 1: TMAToUMMAPipeline (mainloop_pipe)
        # ---------------------------------------------
        # Synchronizes TMA loads (producer) with UMMA/MMA operations (consumer).
        # - num_stages: Number of pipeline stages (matches mainloop_stage)
        # - mma_operation_type: The type of MMA operation being consumed
        mainloop_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=mainloop_stage,
            mma_operation_type=mma_operation_type,
            tma_operation_type=tma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # PIPELINE 2: UMMAtoAsyncPipeline (acc_pipe)
        # ------------------------------------------
        # Synchronizes UMMA/MMA operations (producer) with TMEM→RMEM copies (consumer).
        # - num_stages: Accumulator stages (acc_stage)
        # - mma_operation_type: The MMA operation producing data
        # - consumer: The operation consuming data (SM100_COPY_T2R = TMEM→RMEM copy)
        # - consumer_arv_count: Number of threads participating as consumers (128 = 4 warps)
        # For 2-CTA MMA, warpgroup from both peer and leader CTA consumer.release
        acc_pipe_consumer_arv_count = 256 if self.use_2cta_instrs else 128
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=acc_stage,
            mma_operation_type=mma_operation_type,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=acc_pipe_consumer_arv_count,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # ========================================================================================
        # STEP 16: WARP ASSIGNMENT AND SPECIALIZATION
        # ========================================================================================
        # This kernel uses 6 warps (192 threads) with specialized roles:
        #
        # Warp 0: TMA store (also participates in epilogue)
        # Warps 0-3: Epilogue processing (TMEM→RMEM→SMEM)
        # Warp 4: MMA compute
        # Warp 5: TMA load
        #
        # cute.arch.warp_idx(): Returns this thread's warp index (0-5)
        # make_warp_uniform: Ensures all threads in a warp see the same value
        #   (important for conditional branching to avoid divergence)
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        # warp assignment: [0]-tma_store, [0-3]-epi, [4]-mma, [5]-tma_load
        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_warp_id = 5
        is_tma_thr = warp_idx == tma_load_warp_id
        is_mma_thr = warp_idx == mma_warp_id
        is_epi_thr = warp_idx < 4

        # PIPELINE 3: TMAStorePipeline (tma_store_pipe)
        # ---------------------------------------------
        # Synchronizes RMEM→SMEM writes with TMA stores.
        # Uses named barriers (not mbarriers) for synchronization.
        #
        # - stages: Number of TMA store pipeline stages
        # - arv_count: Number of threads participating in barriers (128 = 4 warps)
        # - barrier_id: Named barrier ID (must be unique per pipeline)
        # - tma_warp_id: Which warp issues TMA stores (warp 0)
        if cutlass.const_expr(self.use_tma_store):
            tma_store_pipe = cute_ext.TMAStorePipeline(
                stages=self.TMA_STORE_STAGE,
                arv_count=128,
                barrier_id=1,
                tma_warp_id=tma_store_warp_id,
            )

        # ========================================================================================
        # STEP 17: COMPUTE K-TILE ITERATION COUNT
        # ========================================================================================
        # cute.size(gA, mode=[1, 1]) extracts the size of the K-tile dimension.
        # gA shape after zipped_divide: ((M_tile, K_tile), (num_M_tiles, num_K_tiles, batch))
        # mode=[1, 1] accesses the second element of the second mode = num_K_tiles
        k_tile_size = cute.size(gA, mode=[1, 1])

        # ========================================================================================
        # STEP 18: TMA LOAD WARP - PRODUCER PHASE
        # ========================================================================================
        # The TMA load warp (warp 5) loads A and B tiles from GMEM to SMEM.
        # This is the PRODUCER in the mainloop pipeline.
        #
        # The producer loop iterates over K-tiles, loading data ahead of consumption.
        # Pipeline stages allow loads to overlap with MMA operations.
        if is_tma_thr:
            # cutlass.range: A loop construct that supports unrolling.
            # unroll=1 means don't unroll (iterate normally).
            # This iterates over K-tiles: k = 0, 1, 2, ... k_tile_size-1
            for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                gA_k = tAgA_slice[(None, None, None, k)]
                gB_k = tBgB_slice[(None, None, None, k)]

                # ============================================================================
                # PIPELINE PRODUCER PROTOCOL
                # ============================================================================
                # 1. Acquire a pipeline stage (wait for it to be empty)
                # 2. Get the mbarrier for TMA synchronization
                # 3. Issue TMA loads
                # 4. Commit and advance to the next stage
                #
                # producer_acquire_and_get_stage():
                # - Waits for the next pipeline stage to be empty (consumer released it)
                # - Returns (stage_token, idx) where:
                #   - stage_token: Handle for getting the mbarrier
                #   - idx: Integer index (0 to num_stages-1) for buffer slicing
                (
                    producer_stage_token,
                    idx,
                ) = mainloop_pipe.producer_acquire_and_get_stage()

                # get_mbarrier: Retrieves the hardware mbarrier pointer for this stage.
                # The mbarrier is signaled by TMA hardware when the load completes.
                mbar = cute_ext.get_mbarrier(producer_stage_token)

                ## producer_body begin ##

                # Slice SMEM buffers to the current pipeline stage.
                # bufferA has shape (atoms, M, K, stages)
                # bufferA[None, None, None, idx] selects stage idx: shape (atoms, M, K)
                bufferA_sliced = bufferA[None, None, None, idx]
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

                # producer_commit_and_advance:
                # - Signals that producer work is complete (mbarrier will be triggered by TMA)
                # - Advances internal pipeline state to the next stage
                mainloop_pipe.producer_commit_and_advance()

        # ========================================================================================
        # STEP 19: MMA WARP - COMPUTE PHASE
        # ========================================================================================
        # The MMA warp (warp 4) performs matrix multiply-accumulate operations.
        # It consumes data from SMEM (loaded by TMA warp) and produces results in TMEM.
        #
        # The MMA warp is both:
        # - CONSUMER of mainloop_pipe (waits for TMA loads to complete)
        # - PRODUCER of acc_pipe (signals when accumulation is complete)
        if is_mma_thr and is_leader_cta:
            # Acquire accumulator pipeline stage before starting MMA operations.
            # This reserves a TMEM accumulator buffer for this K-reduction.
            _, idx = acc_pipe.producer_acquire_and_get_stage()

            ## acc_producer_body begin ##

            # Select the TMEM accumulator for this stage.
            # bufferAcc has shape (MMA_shape, stages)
            accumulators_sliced = bufferAcc[None, None, None, idx]

            # ============================================================================
            # MMA ATOM CONFIGURATION
            # ============================================================================
            # cute.make_mma_atom: Creates an MMA atom from the tiled_mma operation.
            # The MMA atom represents the hardware MMA instruction configuration.
            #
            # ACCUMULATE field controls whether to:
            # - False: Overwrite accumulator (C = A × B) - used for first iteration
            # - True: Accumulate into existing value (C += A × B) - used after first
            mma_atom = cute.make_mma_atom(tiled_mma.op)
            mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)

            # Iterate over K-tiles (same loop as TMA load warp)
            for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                # ============================================================================
                # PIPELINE CONSUMER PROTOCOL
                # ============================================================================
                # Wait for TMA load to complete before reading from SMEM.
                # consumer_wait_and_get_stage():
                # - Waits for the producer (TMA) to signal the mbarrier
                # - Returns (stage_token, mainloop_idx) where mainloop_idx is the stage to read
                (
                    _,
                    mainloop_idx,
                ) = mainloop_pipe.consumer_wait_and_get_stage()

                ## tma_consumer_body begin ##

                # cute.core.slice_: An alternative slicing function that creates a view.
                # This slices the SMEM buffers to the current pipeline stage.
                # Equivalent to bufferA[None, None, None, mainloop_idx]
                bufferA_sliced_stage = cute.core.slice_(
                    bufferA, (None, None, None, mainloop_idx)
                )
                bufferB_sliced_stage = cute.core.slice_(
                    bufferB, (None, None, None, mainloop_idx)
                )

                # ============================================================================
                # INNER K-TILE LOOP (MMA INSTRUCTION LOOP)
                # ============================================================================
                # Within each K-tile, we execute multiple MMA instructions.
                # mma_inst_tile_k (=4) MMA instructions are executed per K-tile.
                #
                # unroll_full=True: Fully unroll this loop (generate 4 copies of the body)
                # This is important for MMA instruction scheduling.
                for k_tile in cutlass.range(mma_inst_tile_k, unroll_full=True):
                    # Select the k_tile-th sub-slice for this MMA instruction.
                    # bufferA_sliced_stage has shape (MMA_atom, M_tile, K_tile)
                    # After slicing [None, None, k_tile]: shape (MMA_atom, M_tile)
                    bufferA_sliced = bufferA_sliced_stage[None, None, k_tile]
                    bufferB_sliced = bufferB_sliced_stage[None, None, k_tile]

                    # ========================================================================
                    # CUTE.DOT - MATRIX MULTIPLY-ACCUMULATE
                    # ========================================================================
                    # cute_ext.dot: Performs MMA operation C = A × B (or C += A × B)
                    #
                    # Arguments:
                    # - mma_atom: The MMA instruction configuration
                    # - a, b: Input tensors (auto-lifted to rank >= 3 internally;
                    #   CuTe's MMA fragment contract is (MMA, REST_M, REST_K))
                    # - c: Accumulator tensor C (in TMEM)
                    cute_ext.dot(
                        mma_atom,
                        bufferA_sliced,
                        bufferB_sliced,
                        accumulators_sliced,
                    )

                    # After the first MMA instruction, enable accumulation mode.
                    # Subsequent instructions add to the existing accumulator value.
                    mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)

                ## tma_consumer_body end ##

                # Release the mainloop pipeline stage for TMA to reuse.
                # consumer_release_and_advance():
                # - Signals that consumer has finished reading this stage
                # - Advances internal state to the next stage
                mainloop_pipe.consumer_release_and_advance()

            ## acc_producer_body end ##

            # Signal that MMA computation is complete for this tile.
            # The epilogue warps will consume this data.
            acc_pipe.producer_commit_and_advance()

        # ========================================================================================
        # STEP 20: EPILOGUE WARPS - CONSUME AND STORE PHASE
        # ========================================================================================
        # Warps 0-3 handle the epilogue: copying results from TMEM to GMEM.
        # This involves: TMEM → RMEM → apply epilogue op → SMEM → TMA store to GMEM
        #
        # The epilogue is both:
        # - CONSUMER of acc_pipe (waits for MMA to complete)
        # - PRODUCER/CONSUMER of tma_store_pipe (coordinates SMEM→GMEM stores)
        if is_epi_thr:
            # Wait for accumulator data to be ready.
            _, idx = acc_pipe.consumer_wait_and_get_stage()

            ## acc_consume_body begin ##

            # Select the accumulator stage and reshape for epilogue iteration.
            # accumulators_sliced: shape (M_epi, N_epi) after removing stage dimension
            accumulators_sliced = bufferAcc[(None, None), 0, 0, idx]

            # Divide the accumulator into epilogue-sized sub-tiles.
            # flat_divide creates a flat iteration space over sub-tiles.
            # acc_epi_div_tiled: allows iteration with index mn over sub-tiles
            acc_epi_div_tiled = cute.flat_divide(accumulators_sliced, epi_tile)

            # Get the number of sub-tiles to process.
            # mode=[3] accesses the sub-tile count dimension
            subtile_cnt = cute.size(acc_epi_div_tiled.shape, mode=[3])

            if cutlass.const_expr(self.use_tma_store):
                # Iterate over epilogue sub-tiles
                for mn in range(subtile_cnt):
                    # TMEM → RMEM
                    cute_ext.partition_and_copy(
                        tiled_copy_t2r.get_slice(tid_x),
                        acc_epi_div_tiled[None, None, 0, mn],
                        bufferRAcc,
                    )

                    # Apply epilogue op and type conversion
                    bufferRD.store(self.epilogue_op(bufferRAcc.load().to(d_dtype)))

                    # TMA store pipeline: acquire and get stage index
                    tma_store_pipe.acquire_sync()
                    idx = tma_store_pipe.get_index()

                    # RMEM → SMEM
                    tiled_copy_r2s = cute.make_tiled_copy_D(
                        cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), d_dtype),
                        tiled_copy_t2r,
                    )
                    cute_ext.partition_and_copy(
                        tiled_copy_r2s.get_slice(tid_x),
                        bufferRD,
                        bufferC[None, None, idx],
                    )

                    # Fence SMEM writes before TMA store
                    tma_store_pipe.commit_sync()

                    # SMEM → GMEM (only TMA store warp)
                    if warp_idx == tma_store_warp_id:
                        cute_ext.tma_store(
                            bufferC[None, None, idx],
                            gC_mnl_epi[None, None, 0, mn],
                        )

                    tma_store_pipe.release_advance()

                tma_store_pipe.tail()
            else:
                # Direct RMEM → GMEM epilogue (no TMA store)
                gd_epi_div = cute.flat_divide(gD_tile, epi_tile)
                for mn in range(subtile_cnt):
                    # TMEM → RMEM
                    cute_ext.partition_and_copy(
                        tiled_copy_t2r.get_slice(tid_x),
                        acc_epi_div_tiled[None, None, 0, mn],
                        bufferRAcc,
                    )

                    # Apply epilogue op and type conversion
                    bufferRD.store(self.epilogue_op(bufferRAcc.load().to(d_dtype)))

                    # RMEM → GMEM (direct store, reusing tiled_copy_t2r for partitioning)
                    cute_ext.partition_and_copy(
                        tiled_copy_t2r.get_slice(tid_x),
                        bufferRD,
                        gd_epi_div[None, None, 0, mn],
                    )

            # Release the accumulator pipeline stage
            acc_pipe.consumer_release_and_advance()


def create_tensors(
    l, m, n, k, a_major, b_major, c_major, ab_dtype, c_dtype, zero_init=False
):
    """
    Create input and output tensors for GEMM operation.

    This function creates:
    1. CPU tensors with proper layouts (for reference computation)
    2. GPU tensors wrapped as CuTe tensors (for kernel execution)

    Args:
        l: Batch size (L dimension)
        m: M dimension (rows of A, rows of D)
        n: N dimension (columns of B, columns of D)
        k: K dimension (columns of A, rows of B - the reduction dimension)
        a_major: "m" for M-major (column-major in M), "k" for K-major
        b_major: "n" for N-major, "k" for K-major
        d_major: "m" for M-major, "n" for N-major
        ab_dtype: Data type for A and B matrices
        d_dtype: Data type for output matrix

    Returns:
        Tuple of (a_tensor, b_tensor, d_tensor, a_cpu, b_cpu, d_cpu, d_gpu)
        - *_tensor: CuTe tensor wrappers for kernel input
        - *_cpu: PyTorch CPU tensors for reference
        - d_gpu: PyTorch GPU tensor for result extraction

    TENSOR LAYOUT CONVENTIONS:
    - cutlass_torch.matrix(l, m, k, m_major, dtype) creates a tensor of shape (m, k, l)
    - m_major=True: M is the fast (stride-1) dimension
    - m_major=False: K is the fast dimension

    CUTE TENSOR CREATION:
    - cute_tensor_like wraps a PyTorch tensor as a CuTe tensor
    - is_dynamic_layout=True: Allows variable problem sizes
    - assumed_align=16: Assumes 16-byte alignment for TMA
    """
    torch.manual_seed(1111)  # For reproducibility

    # zero_init=True fills operands with zeros instead of random data. All-zero
    # operands cause far less tensor-core switching activity -> much lower power,
    # which keeps the SM clock from throttling on power-capped boards during
    # throughput benchmarking. Use only with skip_ref_check (output is all-zero).
    init_kwargs = (
        dict(
            init_type=cutlass_torch.TensorInitType.SCALAR,
            init_config=cutlass_torch.ScalarInitConfig(value=0.0),
        )
        if zero_init
        else {}
    )

    # Create PyTorch CPU tensors with specified layouts.
    # cutlass_torch.matrix(l, m, k, m_major, dtype) creates (m, k, l) tensor
    a_torch_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype, **init_kwargs)
    b_torch_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype, **init_kwargs)
    c_torch_cpu = cutlass_torch.matrix(l, m, n, c_major == "m", c_dtype, **init_kwargs)

    # Wrap as CuTe tensors for kernel input.
    # cute_tensor_like returns (cute_tensor, pytorch_gpu_tensor)
    a_tensor, _ = cutlass_torch.cute_tensor_like(
        a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b_tensor, _ = cutlass_torch.cute_tensor_like(
        b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
        c_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
    )

    return (
        a_tensor,
        b_tensor,
        c_tensor,
        a_torch_cpu,
        b_torch_cpu,
        c_torch_cpu,
        c_torch_gpu,
    )


def compare(a_torch_cpu, b_torch_cpu, c_torch_gpu, c_dtype, tolerance):
    """
    Compare kernel output against PyTorch reference.

    The reference computation uses torch.einsum with the pattern "mkl,nkl->mnl":
    - A has shape (m, k, l): indices m, k, l
    - B has shape (n, k, l): indices n, k, l
    - Output has shape (m, n, l): indices m, n, l
    - The 'k' index is summed (contraction)

    This computes: D[m,n,l] = sum_k A[m,k,l] * B[n,k,l]

    Args:
        a_torch_cpu: Input A tensor on CPU
        b_torch_cpu: Input B tensor on CPU
        d_torch_gpu: Kernel output tensor on GPU
        d_dtype: Output data type (for reference tensor creation)
        tolerance: Absolute tolerance for comparison

    Raises:
        AssertionError: If kernel output doesn't match reference within tolerance
    """
    # Compute reference in float32 to avoid int8 overflow for sub-byte types.
    ref = torch.einsum(
        "mkl,nkl->mnl", a_torch_cpu.to(torch.float32), b_torch_cpu.to(torch.float32)
    )

    # Wrap reference as CuTe tensor (for consistent comparison)
    _, ref_torch_gpu = cutlass_torch.cute_tensor_like(
        ref, c_dtype, is_dynamic_layout=True, assumed_align=16
    )
    ref_result = ref_torch_gpu.cpu()

    if c_dtype in (cutlass.Float8E4M3FN, cutlass.Float8E5M2):
        # Torch fp8 only supports bitwise comparison
        # We test with small int values anyways so it shouldnt matter
        torch.testing.assert_close(c_torch_gpu.cpu(), ref_result, atol=0, rtol=0)
    else:
        # Compare with tolerance
        torch.testing.assert_close(
            c_torch_gpu.cpu(), ref_result, atol=tolerance, rtol=1e-05
        )


def run(
    mnkl: Tuple[int, int, int, int],
    mma_tiler_mn: Tuple[int, int],
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
    use_tma_store: bool = True,
    zero_init: bool = False,
    **kwargs,
):
    """Execute a batched dense GEMM operation on Blackwell architecture with performance benchmarking.

    This function:
    1. Creates input tensors
    2. Instantiates and compiles the kernel
    3. Executes the kernel
    4. Validates correctness against PyTorch reference
    5. Benchmarks performance

    COMPILATION PATTERN:
    -------------------
    CRITICAL: Always use explicit compilation to avoid JIT overhead!

    WRONG (recompiles every call, ~1000x slower):
        kernel = DenseGemmKernel(...)
        kernel(a, b, d)  # JIT compilation happens here every time!

    CORRECT (compile once, run many times):
        kernel = DenseGemmKernel(...)
        compiled = cute_ext.compile(kernel, a, b, d)   # Compile once
        compiled(a, b, d)                              # Fast execution

    Args:
        mnkl: Problem size tuple (M, N, K, L)
        mma_tiler_mn: MMA tile shape (M_tile, N_tile)
        cluster_shape_mn: Cluster shape (currently unused in 1-CTA mode)
        ab_dtype: Input data type
        d_dtype: Output data type
        acc_dtype: Accumulator data type
        a_major, b_major, d_major: Layout specifications ("m"/"k"/"n")
        warmup_iterations: Warmup iterations before timing
        iterations: Timed iterations
        use_cold_l2: Whether to use cold L2 cache (requires fresh tensors)
        tolerance: Tolerance for numerical comparison
        skip_ref_check: Skip reference validation
        kwargs: Extra perf-framework forwarded options

    Returns:
        exec_time: Execution time in microseconds per iteration
    """

    cli.print_problem_config(
        "Blackwell Dense GEMM",
        mnkl,
        dtypes={"AB": ab_dtype, "C": c_dtype, "Acc": acc_dtype},
        majors={"A": a_major, "B": b_major, "C": c_major},
        mma_tiler_mn=mma_tiler_mn,
        cluster_shape_mn=cluster_shape_mn,
    )
    print(f"Use 2-CTA instructions: {use_2cta_instrs}")
    print(f"Use TMA store: {use_tma_store}")
    cli.print_benchmark_config(
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
        use_cold_l2=use_cold_l2,
    )

    m, n, k, l = mnkl

    ab_dtype = ab_dtype
    c_dtype = c_dtype

    sm100_utils.check_gemm_tma_alignment(
        m,
        n,
        k,
        ab_dtype,
        ab_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        output_tensor_name="C",
    )

    a_tensor, b_tensor, c_tensor, a_torch_cpu, b_torch_cpu, c_torch_cpu, c_torch_gpu = (
        create_tensors(
            l,
            m,
            n,
            k,
            a_major,
            b_major,
            c_major,
            ab_dtype,
            c_dtype,
            zero_init=zero_init,
        )
    )
    dense_gemm = DenseGemmKernel(
        mn_tiler=mma_tiler_mn,
        mma_dtype=(ab_dtype, acc_dtype),
        tmem_output_dtype=c_dtype,
        use_2cta_instrs=use_2cta_instrs,
        cluster_shape_mn=cluster_shape_mn,
        use_tma_store=use_tma_store,
    )

    compiled_dense_gemm = cute_ext.compile(dense_gemm, a_tensor, b_tensor, c_tensor)
    compiled_dense_gemm.engine.initialize()

    compiled_dense_gemm(a_tensor, b_tensor, c_tensor)

    if not skip_ref_check:
        compare(a_torch_cpu, b_torch_cpu, c_torch_gpu, c_dtype, tolerance)
        print("check reference: PASS")

    def generate_tensors():
        a_tensor, _ = cutlass_torch.cute_tensor_like(
            a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b_tensor, _ = cutlass_torch.cute_tensor_like(
            b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        c_tensor, _ = cutlass_torch.cute_tensor_like(
            c_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
        )
        return testing.JitArguments(a_tensor, b_tensor, c_tensor)

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_torch_cpu.numel() * a_torch_cpu.element_size()
            + b_torch_cpu.numel() * b_torch_cpu.element_size()
            + c_torch_cpu.numel() * c_torch_cpu.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_dense_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Example of Dense GEMM on Blackwell.")

    cli.add_mnkl_arg(parser)
    cli.add_mma_tiler_arg(parser)
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
        "--use_tma_store",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Use TMA store for epilogue (default: True)",
    )
    parser.add_argument(
        "--zero_init",
        action="store_true",
        help="Initialize operands with zeros instead of random data. Lowers "
        "tensor-core switching power to keep the SM clock from throttling on "
        "power-capped boards (timing/benchmark path only; output is all-zero).",
    )

    args = parser.parse_args()

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values")

    exec_time = run(
        args.mnkl,
        args.mma_tiler_mn,
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
        args.use_tma_store,
        args.zero_init,
    )

    print(f"Execution time: {exec_time} microseconds per iteration")
