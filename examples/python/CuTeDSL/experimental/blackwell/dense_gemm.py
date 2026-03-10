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

import torch
from typing import Type, Tuple

import cutlass
from cutlass.cute import experimental as cute_ext
from cutlass.base_dsl.typing import Numeric, Constexpr
from cutlass import cute as cute
from cutlass import utils
from cutlass import torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils

import cutlass.cute.testing as testing

# ====================================================================================================
#
# This kernel implements a batched dense GEMM operation: D = A @ B
# where:
#   - A has shape (M, K, L) and is stored in global memory
#   - B has shape (N, K, L) and is stored in global memory
#   - D has shape (M, N, L) and is the output in global memory
#   - L is the batch dimension
#
# The kernel uses the LIR (Low-level Intermediate Representation) DSL which is a Python DSL
# for writing high-performance, Blackwell (SM100)-targeted kernels on top of CuTe abstractions.
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


# ====================================================================================================
# KERNEL CLASS DEFINITION
# ====================================================================================================
class DenseGemmKernel:
    """
    Dense GEMM kernel class for Blackwell (SM100) GPUs.

    This class encapsulates all the configuration and logic for a high-performance
    batched matrix multiplication: D = A @ B (with optional epilogue operation).

    The design follows LIR conventions:
    1. __init__: Store configuration parameters
    2. __call__: JIT-decorated host launcher that computes grid and calls kernel
    3. kernel: Device kernel that performs the actual computation

    Attributes:
        mn_tiler (tuple[int, int]): Tile sizes for M and N dimensions (e.g., (128, 256))
        ab_dtype (Type[Numeric]): Data type for input matrices A and B (e.g., Float16)
        acc_dtype (Type[Numeric]): Data type for accumulators (typically Float32)
        tmem_output_dtype (Type[Numeric]): Data type for TMEM->RMEM copy output
        use_2cta_instrs (bool): Whether to use 2-CTA MMA instructions (False = 1-CTA mode)
        TMA_STORE_STAGE (int): Number of pipeline stages for TMA store operations
        epilogue_op (callable): Optional epilogue function applied to output (default: identity)
    """

    def __init__(
        self,
        mn_tiler: tuple[int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric]],
        tmem_output_dtype: Type[Numeric],
        epilogue_op=lambda x: x,
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
        """
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.tmem_output_dtype = tmem_output_dtype
        self.use_2cta_instrs = False

        # Number of pipeline stages for TMA store operations.
        # More stages = better latency hiding, but more SMEM usage.
        self.TMA_STORE_STAGE = 4

        # Epilogue operation applied in registers before storing output.
        self.epilogue_op = epilogue_op

    # ================================================================================================
    # JIT-DECORATED HOST LAUNCHER
    # ================================================================================================
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
        # Create a packed tile shape for division. The _pack_shape helper handles
        # creating the proper CuTe shape representation.
        # (*self.mn_tiler, 1) = (M_tile, N_tile, 1) - the 1 handles the batch dimension
        tile_mn = cute.core._pack_shape((*self.mn_tiler, 1))

        # tiled_divide produces shape: ((tile_M, tile_N, 1), num_M_tiles, num_N_tiles, batch_L)
        # This is used to compute the grid dimensions.
        div = cute.tiled_divide(mD, tile_mn)

        # Grid dimensions: (num_tiles_M, num_tiles_N, batch_size)
        # Each CTA (Cooperative Thread Array / thread block) processes one tile.
        grid = (div.shape[1], div.shape[2], div.shape[3])

        # Launch the kernel with Blackwell-specific configuration:
        # - block=(192, 1, 1): 6 warps × 32 threads/warp = 192 threads
        #   Warp assignment: warps 0-3 (epilogue), warp 4 (MMA), warp 5 (TMA load)
        # - cluster=(1, 1, 1): Single-CTA mode (no cluster cooperation)
        # - smem: Request maximum shared memory capacity for SM100 (~232KB)
        self.kernel(mA, mB, mD).launch(
            grid=grid,
            block=(192, 1, 1),  # 6 warps for warp-specialized GEMM
            cluster=(1, 1, 1),  # Single CTA per cluster
            smem=cute.Int64(utils.get_smem_capacity_in_bytes("sm_100")),
        )

    # ================================================================================================
    # DEVICE KERNEL
    # ================================================================================================
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

        This kernel follows the standard LIR GEMM structure:
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
        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.ab_dtype,
            utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            self.acc_dtype,
            cute.nvgpu.tcgen05.CtaGroup.ONE,  # Single CTA mode
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
        mma_inst_tile_k = 4  # Number of MMA K-tile subdivisions per mainloop iteration

        # Full MNK tiler: (M_tile, N_tile, K_tile)
        # K_tile = mma_inst_shape_k * mma_inst_tile_k (e.g., 16 * 4 = 64)
        mnk_tiler = (
            self.mn_tiler[0],  # M dimension from constructor
            self.mn_tiler[1],  # N dimension from constructor
            mma_inst_shape_k * mma_inst_tile_k,  # K dimension
        )

        # Get output tensor layout and type for epilogue configuration
        d_layout = utils.LayoutEnum.from_tensor(mD)
        d_dtype = mD.element_type

        # Create sub-tilers for each operand:
        # - A has shape (M, K, L) → tiler_mk = (M_tile, K_tile)
        # - B has shape (N, K, L) → tiler_nk = (N_tile, K_tile)
        # - D has shape (M, N, L) → tiler_mn = (M_tile, N_tile)
        tiler_mk = (mnk_tiler[0], mnk_tiler[2])
        tiler_nk = (mnk_tiler[1], mnk_tiler[2])
        tiler_mn = (mnk_tiler[0], mnk_tiler[1])

        # ========================================================================================
        # STEP 3: DIVIDE GLOBAL TENSORS INTO TILES (zipped_divide)
        # ========================================================================================
        # cute.zipped_divide is the PRIMARY tiling operation in LIR kernels.
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
        gA = cute.zipped_divide(mA, tiler_mk)
        gB = cute.zipped_divide(mB, tiler_nk)
        gD = cute.zipped_divide(mD, tiler_mn)

        # ========================================================================================
        # STEP 4: PIPELINE CONFIGURATION
        # ========================================================================================
        # mainloop_stage: Number of pipeline stages for the TMA load → MMA pipeline.
        # More stages allow better overlap of TMA loads with MMA compute.
        # - 2 stages: Minimum for double-buffering
        # - 4 stages: Good for large GEMMs (better latency hiding)
        # Trade-off: More stages = more SMEM usage
        #
        # acc_stage: Number of accumulator stages in TMEM.
        # - For N=256 tiles: use 1 (single accumulator buffer)
        # - For N=128 tiles: use 2 (double-buffered)
        # Using the correct acc_stage provides measurable performance improvement.
        mainloop_stage = 2
        acc_stage = 2

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

        # ========================================================================================
        # STEP 6: SELECT THIS CTA'S TILES FROM GLOBAL TENSORS
        # ========================================================================================
        # After zipped_divide, we select the specific tiles for this CTA using slicing.
        #
        # CUTE SLICING NOTATION:
        # - None: Keep this dimension (preserve the mode)
        # - integer: Fix this dimension at that index
        #
        # gA has shape ((M_tile, K_tile), (num_M_tiles, num_K_tiles, batch))
        # gA_tile = gA[(None, None), (cta_m, None, cta_l)] means:
        # - (None, None): Keep the tile shape modes (M_tile, K_tile)
        # - (cta_m, None, cta_l): Select M-tile cta_m, keep K dimension, select batch cta_l
        #
        # Result: gA_tile has shape (M_tile, K_tile, num_K_tiles) - one CTA's work
        # The K dimension (None) is kept because we iterate over K in the mainloop.
        gA_tile = gA[(None, None), (cta_m, None, cta_l)]
        gB_tile = gB[(None, None), (cta_n, None, cta_l)]
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
            mainloop_stage,  # Number of pipeline stages
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
        cta_tile_shape_mnk = cute.shape_div(
            mnk_tiler, (cute.size(tiled_mma.thr_id.shape), 1, 1)
        )

        # compute_epilogue_tile_shape determines the sub-tile size for epilogue operations.
        # It considers:
        # - CTA tile shape
        # - Whether using 1-CTA or 2-CTA instructions
        # - Output layout (M-major or N-major)
        # - Output data type
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
            self.TMA_STORE_STAGE,  # Number of TMA store pipeline stages
        )

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
            cute.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )

        bufferB = cute_ext.allocate(
            self.ab_dtype,
            cute.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )

        # Allocate TMEM buffer for MMA accumulators.
        # This stores the running sum: C += A × B across K iterations.
        bufferAcc = cute_ext.allocate(
            self.acc_dtype,
            cute.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
        )

        # Allocate SMEM buffer for output (C) - used during epilogue before TMA store.
        bufferC = cute_ext.allocate(
            d_dtype,
            cute.AddressSpace.smem,
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
            self.acc_dtype,  # FP32 for accumulators
            cute.AddressSpace.rmem,
            acc_d_rmem_layout,
            alignment=32,
        )
        bufferRD = cute_ext.allocate(
            d_dtype,  # Output dtype (e.g., FP16)
            cute.AddressSpace.rmem,
            acc_d_rmem_layout,
            alignment=32,
        )

        # ========================================================================================
        # STEP 15: CREATE PIPELINES
        # ========================================================================================
        # Pipelines provide producer/consumer synchronization using hardware barriers.
        # They enable overlapping of memory operations with compute.
        #
        # PIPELINE 1: TMAToUMMAPipeline (mainloop_pipe)
        # ---------------------------------------------
        # Synchronizes TMA loads (producer) with UMMA/MMA operations (consumer).
        # - num_stages: Number of pipeline stages (matches mainloop_stage)
        # - mma_operation_type: The type of MMA operation being consumed
        #   SM100_MMA_1SM_SS = Single SM, Single-Stage MMA (1-CTA mode)
        mainloop_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=mainloop_stage,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
        )

        # PIPELINE 2: UMMAtoAsyncPipeline (acc_pipe)
        # ------------------------------------------
        # Synchronizes UMMA/MMA operations (producer) with TMEM→RMEM copies (consumer).
        # - num_stages: Accumulator stages (acc_stage)
        # - mma_operation_type: The MMA operation producing data
        # - consumer: The operation consuming data (SM100_COPY_T2R = TMEM→RMEM copy)
        # - consumer_arv_count: Number of threads participating as consumers (128 = 4 warps)
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=acc_stage,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=128,  # 4 epilogue warps × 32 threads
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

        # Assign warp roles
        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_warp_id = 5

        # Boolean flags for role-based execution
        is_tma_thr = warp_idx == tma_load_warp_id  # Only warp 5
        is_mma_thr = warp_idx == mma_warp_id  # Only warp 4
        is_epi_thr = warp_idx < 4  # Warps 0, 1, 2, 3

        # PIPELINE 3: TMAStorePipeline (tma_store_pipe)
        # ---------------------------------------------
        # Synchronizes RMEM→SMEM writes with TMA stores.
        # Uses named barriers (not mbarriers) for synchronization.
        #
        # - stages: Number of TMA store pipeline stages
        # - arv_count: Number of threads participating in barriers (128 = 4 warps)
        # - barrier_id: Named barrier ID (must be unique per pipeline)
        # - tma_warp_id: Which warp issues TMA stores (warp 0)
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
                # Select the K-tile from the CTA's tile view.
                # gA_tile has shape (M_tile, K_tile, num_K_tiles)
                # gA_tile[None, None, k] selects the k-th K-tile: shape (M_tile, K_tile)
                gA_k = gA_tile[None, None, k]
                gB_k = gB_tile[None, None, k]

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

                # ============================================================================
                # CTA-TO-VALUE MAPS FOR TMA
                # ============================================================================
                # cta_v_map (CTA-to-Value map) tells TMA which portion of the global tensor
                # this CTA should load. It encodes the mapping from CTA coordinates to
                # tensor indices.
                #
                # get_cta_v_map_ab: Computes the CTA-to-value map for operands A or B.
                # Arguments:
                # - mA/mB: The global tensor
                # - mnk_tiler: The MNK tiler dimensions
                # - tiled_mma: The MMA configuration
                # - "A"/"B": Which operand this is for
                a_cta_v_map = cute_ext.get_cta_v_map_ab(mA, mnk_tiler, tiled_mma, "A")
                b_cta_v_map = cute_ext.get_cta_v_map_ab(mB, mnk_tiler, tiled_mma, "B")

                # ============================================================================
                # TMA LOAD OPERATIONS
                # ============================================================================
                # tma_load: Asynchronous TMA load from GMEM to SMEM.
                #
                # Arguments:
                # - src: Source tensor in GMEM (the K-tile slice)
                # - dst: Destination buffer in SMEM (the stage-sliced buffer)
                # - mbar: Mbarrier for completion signaling
                # - cta_v_map: CTA-to-value mapping layout
                #
                # The TMA hardware:
                # 1. Reads from GMEM at the location specified by cta_v_map
                # 2. Writes to SMEM at dst
                # 3. Signals mbar when complete
                #
                # IMPORTANT: src and dst must have matching shapes!
                # This is a common source of "source/destination size mismatch" errors.
                cute_ext.tma_load(
                    gA_k,  # Source: K-tile from global A
                    bufferA_sliced,  # Destination: SMEM buffer stage
                    mbar,  # Mbarrier for synchronization
                    cta_v_map=a_cta_v_map,
                )
                cute_ext.tma_load(
                    gB_k,
                    bufferB_sliced,
                    mbar,
                    cta_v_map=b_cta_v_map,
                )

                ## producer_body end ##

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
        if is_mma_thr:
            # Acquire accumulator pipeline stage before starting MMA operations.
            # This reserves a TMEM accumulator buffer for this K-reduction.
            producer_stage_token, idx = acc_pipe.producer_acquire_and_get_stage()

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
            mma_atom.set(
                cute.nvgpu.tcgen05.Field.ACCUMULATE, False
            )  # First iteration: overwrite

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
                    _,  # Stage token not needed for consumer
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
                    # - a: Input tensor A (must be rank-3)
                    # - b: Input tensor B (must be rank-3)
                    # - c: Accumulator tensor C (in TMEM)
                    #
                    # CUTE ALGEBRA EXPLANATION - append_ones:
                    # ---------------------------------------
                    # cute.append_ones(tensor, up_to_rank=3):
                    # The MMA instruction expects rank-3 operands. If bufferA_sliced
                    # is rank-2 after slicing, append_ones pads it to rank-3 by
                    # appending singleton dimensions: shape (M, K) → (M, K, 1)
                    #
                    # This is necessary because the MMA instruction operates on
                    # 3D tiles even when the logical operation is 2D.
                    cute_ext.dot(
                        mma_atom,
                        cute.append_ones(bufferA_sliced, up_to_rank=3),
                        cute.append_ones(bufferB_sliced, up_to_rank=3),
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

            # Iterate over epilogue sub-tiles
            for mn in range(subtile_cnt):
                # ============================================================================
                # TMEM → RMEM COPY
                # ============================================================================
                # partition_and_copy: High-level function that combines partitioning and copying.
                # It handles:
                # 1. Partitioning source/destination according to the tiled copy layout
                # 2. Selecting the appropriate copy method based on memory spaces
                # 3. Executing the copy
                #
                # For TMEM→RMEM, this uses specialized tcgen05 load instructions.
                #
                # Arguments:
                # - tiled_copy.get_slice(tid_x): Per-thread copy configuration
                # - source: TMEM accumulator sub-tile
                # - destination: RMEM buffer (per-thread, not partitioned)
                cute_ext.partition_and_copy(
                    tiled_copy_t2r.get_slice(tid_x),
                    acc_epi_div_tiled[None, None, 0, mn],
                    bufferRAcc,
                )

                # ============================================================================
                # APPLY EPILOGUE OPERATION IN REGISTERS
                # ============================================================================
                # bufferRAcc.load(): Reads all values from the RMEM tensor into a register
                # .to(d_dtype): Converts from accumulator type (FP32) to output type (FP16)
                # self.epilogue_op: Applies user-specified transformation (default: identity)
                # bufferRD.store(): Writes the result back to RMEM
                #
                # Common epilogue operations:
                # - Identity: lambda x: x (default)
                # - ReLU: cute.where(x > 0, x, cute.full_like(x, 0))
                # - GELU: Uses cute.exp for tanh approximation
                # - Sigmoid: 1 / (1 + cute.exp(-x))
                bufferRD.store(self.epilogue_op(bufferRAcc.load().to(d_dtype)))

                # ============================================================================
                # TMA STORE PIPELINE PROTOCOL
                # ============================================================================
                # The TMA store pipeline coordinates multiple warps writing to SMEM
                # before a single warp (warp 0) issues the TMA store.
                #
                # acquire_sync():
                # - TMA warp waits for any in-flight TMA ops to complete
                # - All warps synchronize via a named barrier
                tma_store_pipe.acquire_sync()

                # Get the current pipeline stage index for buffer access
                idx = tma_store_pipe.get_index()

                # ============================================================================
                # RMEM → SMEM COPY
                # ============================================================================
                # Create a tiled copy for RMEM→SMEM using the same layout as TMEM→RMEM.
                # make_tiled_copy_D creates a copy with destination-oriented partitioning.
                #
                # CopyUniversalOp: A generic copy operation that works for any memory pair.
                # The partition_and_copy function will select appropriate vectorization.
                tiled_copy_r2s = cute.make_tiled_copy_D(
                    cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), d_dtype),
                    tiled_copy_t2r,
                )

                # Copy from RMEM to the current SMEM stage buffer
                cute_ext.partition_and_copy(
                    tiled_copy_r2s.get_slice(tid_x),
                    bufferRD,
                    bufferC[None, None, idx],
                )

                # commit_sync():
                # - Fences SMEM writes to ensure visibility for TMA
                # - All warps synchronize before TMA store
                # This is CRITICAL - TMA must see committed SMEM writes!
                tma_store_pipe.commit_sync()

                # ============================================================================
                # TMA STORE (SINGLE WARP)
                # ============================================================================
                # Only the designated TMA store warp (warp 0) issues the actual TMA store.
                # Other warps skip this but still participate in synchronization.
                if warp_idx == tma_store_warp_id:
                    # get_cta_v_map_c: CTA-to-value map for the output tensor.
                    # Arguments:
                    # - mD: Global output tensor
                    # - epi_tile: Epilogue tile shape
                    c_cta_v_map = cute_ext.get_cta_v_map_c(mD, epi_tile)

                    # tma_store: Asynchronous TMA store from SMEM to GMEM.
                    #
                    # Arguments:
                    # - src: Source buffer in SMEM (current stage)
                    # - dst: Destination in GMEM (sub-tile at position mn)
                    # - cta_v_map: CTA-to-value mapping
                    #
                    # The store is added to an async bulk group managed by the pipeline.
                    cute_ext.tma_store(
                        bufferC[None, None, idx],
                        gC_mnl_epi[None, None, 0, mn],
                        cta_v_map=c_cta_v_map,
                    )

                # release_advance():
                # - TMA warp commits TMA ops to bulk group
                # - All warps advance to the next pipeline stage
                tma_store_pipe.release_advance()

            # ============================================================================
            # PIPELINE CLEANUP
            # ============================================================================
            # tail(): Called at the end of the pipeline to ensure all TMA stores complete.
            # This waits for all in-flight TMA operations before the kernel exits.
            # Without this, the kernel might exit before stores are globally visible!
            tma_store_pipe.tail()

            # Release the accumulator pipeline stage
            acc_pipe.consumer_release_and_advance()


# ====================================================================================================
# HOST-SIDE UTILITY FUNCTIONS
# ====================================================================================================


def create_tensors(l, m, n, k, a_major, b_major, d_major, ab_dtype, d_dtype):
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

    # Create PyTorch CPU tensors with specified layouts.
    # cutlass_torch.matrix(l, m, k, m_major, dtype) creates (m, k, l) tensor
    a_torch_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype)
    b_torch_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype)
    d_torch_cpu = cutlass_torch.matrix(l, m, n, d_major == "m", d_dtype)

    # Wrap as CuTe tensors for kernel input.
    # cute_tensor_like returns (cute_tensor, pytorch_gpu_tensor)
    a_tensor, _ = cutlass_torch.cute_tensor_like(
        a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b_tensor, _ = cutlass_torch.cute_tensor_like(
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
        d_torch_gpu,
    )


def compare(a_torch_cpu, b_torch_cpu, d_torch_gpu, d_dtype, tolerance):
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
    # Compute reference using einsum
    ref = torch.einsum("mkl,nkl->mnl", a_torch_cpu, b_torch_cpu)

    # Wrap reference as CuTe tensor (for consistent comparison)
    _, ref_torch_gpu = cutlass_torch.cute_tensor_like(
        ref, d_dtype, is_dynamic_layout=True, assumed_align=16
    )
    ref_result = ref_torch_gpu.cpu()

    # Compare with tolerance
    torch.testing.assert_close(
        d_torch_gpu.cpu(), ref_result, atol=tolerance, rtol=1e-05
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

    Returns:
        exec_time: Execution time in microseconds per iteration
    """
    print("Running Blackwell Dense GEMM test with:")
    print(f"mnkl: {mnkl}")
    print(f"AB dtype: {ab_dtype}, D dtype: {c_dtype}, Acc dtype: {acc_dtype}")
    print(f"Matrix majors - A: {a_major}, B: {b_major}, D: {c_major}")
    print(f"Mma Tiler (M, N): {mma_tiler_mn}, Cluster Shape (M, N): {cluster_shape_mn}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")

    m, n, k, l = mnkl

    ab_dtype = ab_dtype
    d_dtype = c_dtype
    d_major = c_major

    # Create tensors
    a_tensor, b_tensor, d_tensor, a_torch_cpu, b_torch_cpu, d_torch_cpu, d_torch_gpu = (
        create_tensors(l, m, n, k, a_major, b_major, d_major, ab_dtype, d_dtype)
    )

    # Instantiate kernel with configuration
    dense_gemm = DenseGemmKernel(
        mn_tiler=mma_tiler_mn,
        mma_dtype=(ab_dtype, acc_dtype),
        tmem_output_dtype=d_dtype,
    )

    # compile() pre-compiles the kernel for the given tensor shapes/types
    compiled_dense_gemm = cute_ext.compile(dense_gemm, a_tensor, b_tensor, d_tensor)

    # Execute the kernel (now fast - no recompilation)
    compiled_dense_gemm(a_tensor, b_tensor, d_tensor)

    # Validate correctness
    if not skip_ref_check:
        compare(a_torch_cpu, b_torch_cpu, d_torch_gpu, d_dtype, tolerance)
        print("check reference: PASS")

    # Tensor generator for benchmarking
    def generate_tensors():
        a_tensor, _ = cutlass_torch.cute_tensor_like(
            a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b_tensor, _ = cutlass_torch.cute_tensor_like(
            b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        d_tensor, _ = cutlass_torch.cute_tensor_like(
            d_torch_cpu, d_dtype, is_dynamic_layout=True, assumed_align=16
        )
        return testing.JitArguments(a_tensor, b_tensor, d_tensor)

    # For cold L2 benchmarking, we need enough tensor copies to flush the cache
    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_torch_cpu.numel() * a_torch_cpu.element_size()
            + b_torch_cpu.numel() * b_torch_cpu.element_size()
            + d_torch_cpu.numel() * d_torch_cpu.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    # Run benchmark
    exec_time = testing.benchmark(
        compiled_dense_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time


# ====================================================================================================
# COMMAND-LINE INTERFACE
# ====================================================================================================

if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(description="Example of Dense GEMM on Blackwell.")

    parser.add_argument(
        "--mnkl",
        type=parse_comma_separated_ints,
        default=(256, 256, 512, 1),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--mma_tiler_mn",
        type=parse_comma_separated_ints,
        default=(128, 128),
        help="Mma tile shape (comma-separated)",
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(1, 1),
        help="Cluster shape (comma-separated)",
    )

    parser.add_argument("--ab_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--d_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)

    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--d_major", choices=["n", "m"], type=str, default="n")

    parser.add_argument(
        "--warmup_iterations", type=int, default=0, help="Warmup iterations"
    )
    parser.add_argument(
        "--iterations", type=int, default=1, help="Number of iterations"
    )
    parser.add_argument("--use_cold_l2", action="store_true", help="Use cold L2")
    parser.add_argument(
        "--tolerance", type=float, default=1e-02, help="Tolerance for validation"
    )
    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference checking"
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
        args.d_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.d_major,
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.tolerance,
        args.skip_ref_check,
    )

    print(f"Execution time: {exec_time} microseconds per iteration")
