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
import logging
import types
import typing
from typing import Tuple, Type, Union

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute as cute
import cutlass.pipeline as pipeline
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.nvgpu import cpasync, tcgen05

import common_efc
from common_efc import log

"""
Common base infrastructure for high-performance persistent batched dense GEMM with custom epilogue fusion
for the NVIDIA Blackwell SM100 architecture using CUTE DSL and Epilogue Fusion Configuration (EFC).

This module provides the DenseGemmEFC base class that implements the core GEMM functionality with
support for custom epilogue operations. Subclasses define specific epilogue configurations by
providing an epilogue function that operates on the accumulator and supplemental tensors.

Key Features:
    - Utilizes Tensor Memory Access (TMA) for efficient memory operations
    - Utilizes Blackwell's tcgen05.mma for matrix multiply-accumulate (MMA) operations (including 2cta mma instructions)
    - Implements TMA multicast with cluster to reduce L2 memory traffic
    - Supports persistent tile scheduling to better overlap memory load/store with mma between tiles
    - Supports warp specialization to avoid explicit pipelining between mainloop load and mma
    - Uses Epilogue Fusion Configuration (EFC) to define custom epilogue operations

GEMM Execution Flow:
1. DMA warp: Load A and B matrices from global memory (GMEM) to shared memory (SMEM) using TMA operations.
2. MMA warp: Perform matrix multiply-accumulate (MMA) operations using tcgen05.mma instruction.
3. EPILOGUE warp (customizable via EFC):
    - Load completed accumulator from tensor memory (TMEM) to registers (RMEM) using tcgen05.ld.
    - Load supplemental input tensors from GMEM to SMEM using TMA, then to RMEM.
    - Execute custom epilogue function (defined by subclass) that:
      * Accesses the accumulator via efc_config.accum()
      * Reads from supplemental input tensors via tensor.load()
      * Writes to supplemental output tensors via tensor.store()
      * Can apply arbitrary element-wise operations, scaling, and fusion
    - Store result tensors from RMEM to SMEM to GMEM with TMA operations.

SM100 tcgen05.mma instructions operate as follows:
- Read matrix A from SMEM
- Read matrix B from SMEM
- Write accumulator to TMEM
The accumulator in TMEM must then be loaded to registers before writing back to GMEM.

Base Tensor Dimensions:
- Matrix A is MxKxL, L is batch dimension, A can be row-major("K") or column-major("M")
- Matrix B is NxKxL, L is batch dimension, B can be row-major("N") or column-major("K")
- Supplemental tensors are MxNxL with layout matching the epilogue configuration

Common Constraints:
* Supported input data types: fp16, bf16, tf32, int8, uint8, fp8 (e4m3fn, e5m2)
* A/B tensors must have the same data type
* MMA tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
* MMA tiler N must be 32-256, step 32
* Cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Cluster shape M must be multiple of 2 if use_2cta_instrs=True
* The contiguous dimension of all tensors must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 4, 8, and 16 for TFloat32,
  Float16/BFloat16, and Int8/Uint8/Float8, respectively.
* OOB tiles are not allowed when TMA store is disabled

Subclass Examples:
- custom_epilogue_dense_gemm.py: Custom fused epilogue with multiple read/write tensors
- synthetic_custom_epilogue_dense_gemm.py: Synthetic epilogue for testing with configurable tensor counts
"""


class DenseGemmEFC:
    """Base class for batched GEMM with custom epilogue fusion using EFC.

    This class provides the core infrastructure for persistent batched GEMM operations
    with customizable epilogue fusion. Subclasses define specific epilogue behaviors
    by providing an epilogue configuration function that describes operations on the
    accumulator and supplemental tensors.

    The class handles:
    - GEMM mainloop (A * B computation)
    - TMA-based memory operations
    - Warp specialization
    - Persistent tile scheduling
    - EFC (Epilogue Fusion Configuration) integration
    - CLI argument parsing (extensible via CLIParser.more_parsing())
    - Tensor creation and validation

    :param acc_dtype: Data type for accumulation during computation
    :type acc_dtype: type[cutlass.Numeric]
    :param epi_dtype: Data type for epilogue operation
    :type epi_dtype: type[cutlass.Numeric]
    :param use_2cta_instrs: Whether to use CTA group 2 for advanced thread cooperation
    :type use_2cta_instrs: bool
    :param mma_tiler_mn: Shape of the Matrix Multiply-Accumulate (MMA) tile (M,N)
    :type mma_tiler_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: Tuple[int, int]
    :param epilogue_function_configuration: Function defining the epilogue behavior via EFC
    :type epilogue_function_configuration: Callable

    :note: Supported A/B data types:
        - TFloat32
        - Float16/BFloat16
        - Int8/Uint8
        - Float8E4M3FN/Float8E5M2
        (A and B must have the same data type)

    :note: Supported accumulator data types:
        - Float32 (for all floating point A/B data types)
        - Float16 (only for fp16 and fp8 A/B data types)
        - Int32 (only for uint8/int8 A/B data types)

    :note: Supported supplemental tensor data types (epilogue-dependent):
        - Float32 (for float32 and int32 accumulator data types)
        - Int32 (for float32 and int32 accumulator data types)
        - Float16/BFloat16 (for fp16 and fp8 accumulator data types)
        - Int8/Uint8 (for uint8/int8 accumulator data types)
        - Float8E4M3FN/Float8E5M2 (for float32 accumulator data types)

    :note: Constraints:
        - MMA tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
        - MMA tiler N must be 32-256, step 32
        - Cluster shape M must be multiple of 2 if use_2cta_instrs=True
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 16

    Example:
        >>> def my_epilogue(efc_config, alpha, beta, output_tensor, input_tensor):
        ...     result = efc_config.accum() * alpha + input_tensor.load() * beta
        ...     output_tensor.store(result)
        ...
        >>> gemm = DenseGemmEFC(
        ...     acc_dtype=cutlass.Float32,
        ...     epi_dtype=cutlass.Float32,
        ...     use_2cta_instrs=True,
        ...     mma_tiler_mn=(128, 128),
        ...     cluster_shape_mn=(2, 2),
        ...     epilogue_function_configuration=my_epilogue
        ... )
    """

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        epi_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        epilogue_function_configuration: typing.Callable,
    ):
        """Initializes the configuration for a Blackwell dense GEMM kernel with EFC.

        This configuration includes several key aspects:

        1.  MMA Instruction Settings (tcgen05):
            - acc_dtype: Data types for MMA accumulator.
            - mma_tiler_mn: The (M, N) shape of the MMA instruction tiler.
            - use_2cta_instrs: Boolean indicating if the tcgen05 MMA variant
              with cta_group=2 should be used.

        2.  Cluster Shape:
            - cluster_shape_mn: The (ClusterM, ClusterN) shape of the CTA cluster.

        3.  Epilogue Configuration:
            - epilogue_function_configuration: Defines custom epilogue behavior
              that operates on accumulator and supplemental tensors.

        :param acc_dtype: Data type of the accumulator.
        :type acc_dtype: type[cutlass.Numeric]
        :param epi_dtype: Data type of the epilogue.
        :type epi_dtype: type[cutlass.Numeric]
        :param use_2cta_instrs: Boolean, True to use cta_group=2 MMA variant.
        :type use_2cta_instrs: bool
        :param mma_tiler_mn: Tuple (M, N) shape of the MMA instruction.
        :type mma_tiler_mn: Tuple[int, int]
        :param cluster_shape_mn: Tuple (ClusterM, ClusterN) shape of the cluster.
        :type cluster_shape_mn: Tuple[int, int]
        :param epilogue_function_configuration: Function defining epilogue behavior via EFC.
        :type epilogue_function_configuration: Callable
        """

        self.acc_dtype: Type[cutlass.Numeric] = acc_dtype
        self.epi_dtype: Type[cutlass.Numeric] = epi_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.cluster_shape_mn = cluster_shape_mn
        # K dimension is deferred in _setup_attributes
        self.mma_tiler_mn = mma_tiler_mn
        self.mma_tiler = (*mma_tiler_mn, 1)
        self.arch = "sm_100"

        self.c_dtype = self.epi_dtype

        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        self.occupancy = 1
        # Set specialized warp ids:

        # The warps responsible for computing the epilogue function and storing
        # the results.
        self.epilogue_warp_id = (0, 1, 2, 3)
        # The warp responsible for computing the matrix multiplication.
        self.mma_warp_id = 4
        # The warp responsible for loading the tensors A & B to feed the MMA.
        self.tma_warp_id = 5
        # The warp responsible for loading the auxiliary tensors used in the epilogue.
        self.epilogue_load_warp_id = 6
        self.threads_per_cta = 32 * len(
            (
                self.mma_warp_id,
                self.tma_warp_id,
                *self.epilogue_warp_id,
                self.epilogue_load_warp_id,
            )
        )
        # Barrier ids for cta sync, epilogue sync and tmem ptr sync.
        self.cta_sync_bar_id = 1
        self.epilogue_sync_bar_id = 2
        self.tmem_alloc_sync_bar_id = 3
        # Amount of available shared memory.
        self.smem_capacity = utils.get_smem_capacity_in_bytes(self.arch)

        # Setup the EFC from the given function representing the epilogue
        # configuration.
        self.efc = common_efc.EFC(self, epilogue_function_configuration)

    def _create_tiled_mma(self):
        """Make a tiled MMA atom with given data type, leading dimension, CTA
        group and MMA tile shape. Use SMEM operand source for A."""
        return utils.sm100.make_trivial_tiled_mma(
            self.a_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
        )

    def _setup_attributes(self):
        """Set up configurations that are dependent on GEMM inputs

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Configuring tiled MMA
        - Computing MMA/cluster/tile shapes
        - Computing cluster layout
        - Computing multicast CTAs for A/B
        - Computing epilogue subtile
        - Setting up A/B/C/D stage counts in shared memory
        - Computing A/B/C/D shared memory layout
        - Computing tensor memory allocation columns
        """
        # Get the right tiled MMA.
        self._tiled_mma = self._create_tiled_mma()
        log(f"{self._tiled_mma = !s}")

        # Compute mma/cluster/tile shapes
        mma_inst_shape_k = cute.size(self._tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        # Extend mma_tiler with k-dimension (MMA_M, MMA_N, MMA_K)
        self.mma_tiler = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        log(f"{self.mma_tiler = !s}")
        # CTA tiler with the 2CTA instruction correction.
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(self._tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )
        log(f"{self.cta_tile_shape_mnk = !s}")
        # Compute cluster layout, V for the 2CTA instructions.
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (self._tiled_mma.thr_id.shape,),
        )
        log(f"{cute.make_layout((*self.cluster_shape_mn, 1)) = !s}")
        log(f"{self.cluster_layout_vmnk = !s}")
        # Compute number of multicast CTAs for A/B
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1
        log(f"{self.num_mcast_ctas_a = }, {self.num_mcast_ctas_b = }")
        log(f"{self.is_a_mcast = }, {self.is_b_mcast = }")

        # Compute epilogue (EPI_TILE_M, EPI_TILE_N) subtile of cta_tile_shape_mnk
        # according to some heuristics.
        self.epi_tile = sm100_utils.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            layout_d=self.d_layout,
            elem_ty_d=self.d_dtype,
            layout_c=self.c_layout,
            elem_ty_c=self.c_dtype,
        )
        log(f"{self.epi_tile = !s}")

        # Setup A/B/C/D pipeline stage count in shared memory and ACC stage
        # count in tensor memory.
        self.compute_stages()
        log(f"{self.num_acc_stage = }, {self.num_ab_stage = }, {self.num_c_stage = }")
        # Compute A/B shared memory layout
        self.a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            self._tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.num_ab_stage,
        )
        log(f"{self.a_smem_layout_staged = !s}")
        self.b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            self._tiled_mma,
            self.mma_tiler,
            self.b_dtype,
            self.num_ab_stage,
        )
        log(f"{self.b_smem_layout_staged = !s}")
        # Get the smem_layout for the tensors used in the EFC.
        self.efc.jit.smem_layout()

        # Compute the number of tensor memory allocation columns
        self.compute_num_tmem_alloc_cols()

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        supplemental_parameters: Tuple,
    ):
        """Execute the GEMM operation in steps:
        - Setup static attributes before smem/grid/tma computation
        - Setup TMA load/store atoms and tensors
        - Compute grid size with regard to hardware constraints
        - Define shared storage for kernel
        - Launch the kernel synchronously

        :param a: Input tensor A
        :type a: cute.Tensor
        :param b: Input tensor B
        :type b: cute.Tensor
        :param max_active_clusters: Maximum number of active clusters
        :type max_active_clusters: cutlass.Constexpr
        :param stream: CUDA stream for asynchronous execution
        :type stream: cuda.CUstream
        :param supplemental_parameters: Tuple or None used to pass variadic values
        :type supplemental_parameters: Tuple
        :raises TypeError: If input data types are incompatible with the MMA instruction.
        :raises AssertionError: If OOB (Out-Of-Bounds) tiles are present when TMA store is disabled.
        """
        # Process the variadic parameters.
        self.efc.jit.unpack_parameters(supplemental_parameters)

        # Setup static attributes before smem/grid/tma computation
        self.a_dtype: Type[cutlass.Numeric] = a.element_type
        self.b_dtype: Type[cutlass.Numeric] = b.element_type
        self.a_major_mode = utils.LayoutEnum.from_tensor(a).mma_major_mode()
        self.b_major_mode = utils.LayoutEnum.from_tensor(b).mma_major_mode()

        # Gather all the auxiliary tensor element data types.
        self.efc.jit.record_tensor_dtypes()

        # There is no D tensor to be used as a returned tensor. In the
        # following, D is used more like of a "store" concept. So use the
        # written tensor with the biggest element_type to set up all the tiling
        # heuristics and epilogue store pipeline.
        self.d_name_bigger = self.efc.jit.written_tensor_name_with_bigger_element_type()
        d = self.efc.jit.parameter[self.d_name_bigger]
        self.d_dtype: Type[cutlass.Numeric] = d.element_type
        self.d_layout = utils.LayoutEnum.from_tensor(d)
        log(f"d{self.d_name_bigger} = {d!s}")

        # C is the read tensor with the biggest element_type, if any, used by
        # some heuristics for tiling.
        self.c_dtype = None
        self.c_layout = None
        self.c_name_bigger = self.efc.jit.read_tensor_name_with_bigger_element_type()
        if cutlass.const_expr(self.c_name_bigger):
            c = self.efc.jit.parameter[self.c_name_bigger]
            log(f"{self.c_name_bigger = } -> {c = !s}")
            self.c_dtype = c.element_type
            self.c_layout = utils.LayoutEnum.from_tensor(c)

        # Check if input data types are compatible with MMA instruction
        if cutlass.const_expr(self.a_dtype != self.b_dtype):
            raise TypeError(f"Type must match: {self.a_dtype} != {self.b_dtype}")

        # Setup attributes that depend on gemm inputs
        self._setup_attributes()

        atom_thr_size = cute.size(self._tiled_mma.thr_id.shape)

        # Setup TMA load for A
        a_op = utils.sm100.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, self._tiled_mma.thr_id
        )
        log(f"{a_op = !s}")
        # Get read of the pipeline dimension.
        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        log(f"{a_smem_layout = !s}")
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            a,
            a_smem_layout,
            self.mma_tiler,
            self._tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if a.element_type is cutlass.Float32 else None
            ),
        )
        log(f"{tma_atom_a = !s}")
        log(f"{tma_tensor_a = !s}")
        # Setup TMA load for B
        b_op = utils.sm100.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, self._tiled_mma.thr_id
        )
        log(f"{b_op = !s}")
        # Get written of the pipeline dimension.
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, None, 0))
        log(f"{b_smem_layout = !s}")
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            b_op,
            b,
            b_smem_layout,
            self.mma_tiler,
            self._tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if b.element_type is cutlass.Float32 else None
            ),
        )
        log(f"{tma_atom_b = !s}")
        log(f"{tma_tensor_b = !s}")
        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        self.num_tma_load_bytes = (a_copy_size + b_copy_size) * atom_thr_size
        log(f"{self.num_tma_load_bytes = }")

        # Set the TMA related arguments for the tensors used in the EFC.
        self.efc.jit.create_tma_arguments()

        # Compute grid size
        self.tile_sched_params, grid = self._compute_grid(
            d, self.cta_tile_shape_mnk, self.cluster_shape_mn, max_active_clusters
        )

        self.efc.jit.create_supplemental_arguments_for_kernel()

        # Launch the kernel synchronously
        self.kernel(
            self._tiled_mma,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            self.cluster_layout_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            self.efc.kernel.pack_arguments(),
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
        )
        return

    # GPU device kernel
    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        supplemental_parameters: Tuple,
    ):
        """
        GPU device kernel performing the Persistent batched GEMM computation.
        """
        # Process the variadic parameters.
        self.efc.kernel.unpack_parameters(supplemental_parameters)

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        #
        # Prefetch tma desc
        #
        if warp_idx == self.tma_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            # Prefetch the TMA descriptors for all the supplemental tensors.
            self.efc.kernel.prefetch_tma_descriptors()

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
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        # Coord inside cta
        tidx, _, _ = cute.arch.thread_idx()

        #
        # Alloc and init: a+b full/empty, accumulator full/empty, tensor memory dealloc barrier
        #
        self.buffer_align_bytes = 1024

        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            ab_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            # Barriers used by the supplemental load tensor pipeline.
            c_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_c_stage]
            c_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_c_stage]
            tmem_dealloc_mbar_ptr: cutlass.Int64
            tmem_holding_buf: cutlass.Int32
            # (MMA, MMA_M, MMA_K, STAGE)
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    self.a_dtype, cute.cosize(a_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    self.b_dtype, cute.cosize(b_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        self.smem = utils.SmemAllocator()
        storage = self.smem.allocate(self.shared_storage)

        # Allocate the shared memory for all the supplemental tensors.
        self.efc.kernel.allocate_smem()

        # Initialize mainloop ab_pipeline (barrier) and states
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_tma_producer = self.num_mcast_ctas_a + self.num_mcast_ctas_b - 1
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_tma_producer
        )
        ab_pipeline = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
        )

        # Initialize acc_pipeline (barrier) and states
        acc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_acc_consumer_threads = len(self.epilogue_warp_id) * (
            2 if self.use_2cta_instrs else 1
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
        )

        # Load pipeline, used to load all the supplemental tensors of the
        # epilogue.
        c_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        c_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            len(self.epilogue_warp_id),
        )
        c_pipeline = pipeline.PipelineTmaAsync.create(
            barrier_storage=storage.c_full_mbar_ptr.data_ptr(),
            num_stages=self.num_c_stage,
            producer_group=c_producer_group,
            consumer_group=c_consumer_group,
            # Unlock the barrier when all the tensor bytes have been loaded.
            tx_count=self.efc.jit.total_tma_load_bytes,
        )

        tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=self.tmem_alloc_sync_bar_id,
            num_threads=32 * len((self.mma_warp_id, *self.epilogue_warp_id)),
        )
        # Tensor memory dealloc barrier init
        tmem = utils.TmemAllocator(
            storage.tmem_holding_buf,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=self.use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar_ptr,
        )

        # Cluster arrive after barrier init
        if cute.size(self.cluster_shape_mn) > 1:
            cute.arch.cluster_arrive_relaxed()

        #
        # Setup smem tensor A/B
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        # (MMA, MMA_N, MMA_K, STAGE)
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )

        #
        # Compute multicast mask for A/B buffer full
        #
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        if cutlass.const_expr(
            self.is_a_mcast or self.is_b_mcast or self.use_2cta_instrs
        ):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )

        #
        # Local_tile partition global tensors
        #
        # (bM, bK, loopM, loopK, loopL)
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )
        # (bN, bK, loopN, loopK, loopL)
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.mma_tiler, (0, None, None)), (None, None, None)
        )

        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        #
        # Partition global tensor for TiledMMA_A/B/D
        #
        self.thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_K, loopM, loopK, loopL)
        tCgA = self.thr_mma.partition_A(gA_mkl)
        log(f"{tCgA = !s}")
        # (MMA, MMA_N, MMA_K, loopN, loopK, loopL)
        tCgB = self.thr_mma.partition_B(gB_nkl)
        log(f"{tCgB = !s}")
        # Create the local_tile gX_mnl for all the EFC supplemental tensors.
        self.efc.kernel.partition_global_tensors_for_tiled_mma()

        #
        # Partition global/shared tensor for TMA load A/B
        #
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), tiles_m, tiles_k, tiles_l)
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
        # ((atom_v, rest_v), tiles_n, tiles_k, tiles_l)
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB, 0, 3),
            cute.group_modes(tCgB, 0, 3),
        )

        #
        # Partition shared/tensor memory tensor for TiledMMA_A/B/C/D
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        tCrA = tiled_mma.make_fragment_A(sA)
        log(f"{tCrA = !s}")
        # (MMA, MMA_N, MMA_K, STAGE)
        tCrB = tiled_mma.make_fragment_B(sB)
        log(f"{tCrB = !s}")
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        log(f"{acc_shape = !s}")
        # (MMA, MMA_M, MMA_N, STAGE)
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )
        log(f"{tCtAcc_fake = !s}")

        # Named barriers
        #
        cta_sync_barrier = pipeline.NamedBarrier(
            self.cta_sync_bar_id, self.threads_per_cta
        )
        epilogue_sync_barrier = pipeline.NamedBarrier(
            self.epilogue_sync_bar_id, 32 * len(self.epilogue_warp_id)
        )

        #
        # Cluster wait before tensor memory alloc
        #
        if cute.size(self.cluster_shape_mn) > 1:
            cute.arch.cluster_wait()
        else:
            cta_sync_barrier.arrive_and_wait()

        #
        # Specialized TMA load warp
        #

        if warp_idx == self.tma_warp_id:
            #
            # Persistent tile scheduling loop
            #
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
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
                # ((atom_v, rest_v), loopK)
                tAgA_slice = tAgA[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]
                # ((atom_v, rest_v), loopK)
                tBgB_slice = tBgB[
                    (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                ]

                # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt
                ab_producer_state.reset_count()
                peek_ab_empty_status = cutlass.Boolean(1)
                if ab_producer_state.count < k_tile_cnt:
                    peek_ab_empty_status = ab_pipeline.producer_try_acquire(
                        ab_producer_state
                    )

                #
                # Tma load loop
                #
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # Conditionally wait for AB buffer empty
                    ab_pipeline.producer_acquire(
                        ab_producer_state, peek_ab_empty_status
                    )

                    # TMA load A/B
                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, ab_producer_state.count)],
                        tAsA[(None, ab_producer_state.index)],
                        tma_bar_ptr=ab_pipeline.producer_get_barrier(ab_producer_state),
                        mcast_mask=a_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, ab_producer_state.count)],
                        tBsB[(None, ab_producer_state.index)],
                        tma_bar_ptr=ab_pipeline.producer_get_barrier(ab_producer_state),
                        mcast_mask=b_full_mcast_mask,
                    )

                    # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt + k_tile + 1
                    ab_producer_state.advance()
                    peek_ab_empty_status = cutlass.Boolean(1)
                    if ab_producer_state.count < k_tile_cnt:
                        peek_ab_empty_status = ab_pipeline.producer_try_acquire(
                            ab_producer_state
                        )

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Wait A/B buffer empty
            #
            ab_pipeline.producer_tail(ab_producer_state)

        #
        # Specialized MMA warp
        #
        if warp_idx == self.mma_warp_id:
            #
            # Bar sync for retrieve tensor memory ptr from shared mem
            #
            tmem.wait_for_alloc()

            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            #
            # Persistent tile scheduling loop
            #
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            ab_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_ab_stage
            )
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # Set tensor memory buffer for current tile
                # (MMA, MMA_M, MMA_N)
                tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]

                # Peek (try_wait) AB buffer full for k_tile = 0
                ab_consumer_state.reset_count()
                peek_ab_full_status = cutlass.Boolean(1)
                if ab_consumer_state.count < k_tile_cnt and is_leader_cta:
                    peek_ab_full_status = ab_pipeline.consumer_try_wait(
                        ab_consumer_state
                    )

                #
                # Wait for accumulator buffer empty
                #
                if is_leader_cta:
                    acc_pipeline.producer_acquire(acc_producer_state)

                #
                # Reset the ACCUMULATE field for each tile
                #
                tiled_mma.set(tcgen05.Field.ACCUMULATE, False)

                #
                # Mma mainloop
                #
                for k_tile in range(k_tile_cnt):
                    if is_leader_cta:
                        # Conditionally wait for AB buffer full
                        ab_pipeline.consumer_wait(
                            ab_consumer_state, peek_ab_full_status
                        )

                        # tCtAcc += tCrA * tCrB
                        num_k_blocks = cute.size(tCrA, mode=[2])
                        for k_block_idx in cutlass.range(
                            num_k_blocks, unroll_full=True
                        ):
                            k_block_coord = (
                                None,
                                None,
                                k_block_idx,
                                ab_consumer_state.index,
                            )

                            cute.gemm(
                                tiled_mma,
                                tCtAcc,
                                tCrA[k_block_coord],
                                tCrB[k_block_coord],
                                tCtAcc,
                            )
                            # Enable accumulate on tCtAcc after first k_block
                            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

                        # Async arrive AB buffer empty
                        ab_pipeline.consumer_release(ab_consumer_state)

                    # Peek (try_wait) AB buffer full for k_tile = k_tile + 1
                    ab_consumer_state.advance()
                    peek_ab_full_status = cutlass.Boolean(1)
                    if ab_consumer_state.count < k_tile_cnt:
                        if is_leader_cta:
                            peek_ab_full_status = ab_pipeline.consumer_try_wait(
                                ab_consumer_state
                            )

                #
                # Async arrive accumulator buffer full
                #
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
        if warp_idx < self.mma_warp_id:
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
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            log(f"tmem_ptr = {tmem_ptr!s}")
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)
            log(f"tCtAcc_base = {tCtAcc_base!s}")
            #
            # Partition for epilogue
            #
            epi_tidx = tidx
            tCgD = self.efc.kernel.tCgD_written[self.d_name_bigger]
            log(f"tCgD (aka tCgD_written[{self.d_name_bigger}])= {tCgD!s}")

            (
                tiled_copy_t2r,  # (EPI_TILE_M, EPI_TILE_N)
                tTR_tAcc_base,  # (T2R, T2R_M, T2R_N, EPI_M, EPI_M, STAGE)
                tTR_rAcc,  # (T2R, T2R_M, T2R_N)
            ) = self.epilogue_tmem_copy_and_partition(
                epi_tidx, tCtAcc_base, tCgD, epi_tile
            )
            log(f"{tiled_copy_t2r = !s}")
            log(f"{tTR_tAcc_base = !s}")
            log(f"{tTR_rAcc = !s}")
            # Copy and partition for the supplemental EFC tensors.
            self.efc.kernel.copy_and_partition_supplemental_rmem_tensors(
                tiled_copy_t2r, tTR_rAcc, epi_tidx, epi_tile
            )

            #
            # Persistent tile scheduling loop
            #
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )

            # Store D pipeline used for all the written tensors in the epilogue.
            d_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.epilogue_warp_id),
            )
            d_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.num_d_stage,
                producer_group=d_producer_group,
            )

            c_pipeline_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_c_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # Slice the supplemental written tensors per MMA tile index.
                self.efc.kernel.slice_written_tensors_per_mma_tile_index(
                    mma_tile_coord_mnl
                )

                # Set tensor memory buffer for current tile
                # (T2R, T2R_M, T2R_N, EPI_M, EPI_M)
                tTR_tAcc = tTR_tAcc_base[
                    (None, None, None, None, None, acc_consumer_state.index)
                ]
                log(f"tTR_tAcc = {tTR_tAcc!s}")
                #
                # Wait for accumulator buffer full
                #
                acc_pipeline.consumer_wait(acc_consumer_state)

                # Group together the EPI_M, EPI_M which are starting at group 3.
                # (T2R, T2R_M, T2R_N, (EPI_M, EPI_M))
                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                log(f"group_modes tTR_tAcc = {tTR_tAcc!s}")
                #
                # Store accumulator to global memory in subtiles
                #
                # Use EPI_M*EPI_M to iterate using the 1-D coordinate.
                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                num_prev_subtiles = tile_sched.num_tiles_executed * subtile_cnt
                for subtile_idx in cutlass.range(subtile_cnt):
                    #
                    # Load accumulator from tensor memory buffer to register
                    #
                    tTR_tAcc_mn = tTR_tAcc[(None, None, None, subtile_idx)]
                    cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)
                    log(f"cute.copy tiled_copy_t2r = {tiled_copy_t2r!s}")
                    log(f"cute.copy tTR_tAcc_mn = {tTR_tAcc_mn!s}")
                    log(f"cute.copy tTR_rAcc = {tTR_rAcc!s}")

                    # Wait for the EFC tensor loads to complete.
                    if cutlass.const_expr(self.efc.read_tensor_names):
                        # The wait is blocking even if the tx_count is 0 when
                        # there is no tensor to load. So need to skip it when
                        # there is no tensor to read.
                        c_pipeline.consumer_wait(c_pipeline_consumer_state)

                    # Load supplemental tensors from shared memory to register.
                    self.efc.kernel.load_tensors_from_smem_to_register(
                        c_pipeline_consumer_state.index
                    )

                    cute.arch.fence_proxy(
                        "async.shared",
                        space="cta",
                    )
                    c_pipeline.consumer_release(c_pipeline_consumer_state)

                    # Advance pipeline states
                    c_pipeline_consumer_state.advance()

                    #
                    # Perform epilogue op on accumulator.
                    #
                    tiled_copy_r2s = self.efc.kernel.tiled_copy_r2s[self.d_name_bigger]
                    log(f"tiled_copy_r2s = {tiled_copy_r2s!s}")
                    # Use a SimpleNamespace to pass easily some local content as
                    # an extensible class compatible with CuTe DSL
                    # implementation.
                    epilogue_context = types.SimpleNamespace()
                    # Load the accumulator cast to the epi_dtype used to do all
                    # the computations in the epilogue.
                    # Retile the accumulator subtile to fit the destination
                    # subtile vector TV layout.
                    epilogue_context.acc_vec = (
                        tiled_copy_r2s.retile(tTR_rAcc).load().to(self.epi_dtype)
                    )
                    log(f"before .retile tTR_rAcc = {tTR_rAcc!s}")
                    log(
                        f"tiled_copy_r2s.retile(tTR_rAcc) = {tiled_copy_r2s.retile(tTR_rAcc)!s}"
                    )
                    log(
                        f"tiled_copy_r2s.retile(tTR_rAcc).load() = {tiled_copy_r2s.retile(tTR_rAcc).load()!s}"
                    )
                    log(f"epilogue_context.acc_vec = {epilogue_context.acc_vec!s}")

                    # Execute the EFC epilogue.
                    self.efc.kernel.epilogue_computation(epilogue_context)
                    d_buffer = (num_prev_subtiles + subtile_idx) % self.num_d_stage

                    # Store the EFC written tensors to shared memory.
                    self.efc.kernel.store_written_tensors_to_smem(d_buffer)

                    # Fence and barrier to make sure shared memory store is visible to TMA store
                    cute.arch.fence_proxy(
                        "async.shared",
                        space="cta",
                    )
                    epilogue_sync_barrier.arrive_and_wait()

                    #
                    # TMA store D to global memory
                    #
                    if warp_idx == self.epilogue_warp_id[0]:
                        # Store with TMA the written EFC tensors to global memory.
                        self.efc.kernel.tma_store_written_tensors_to_gmem(
                            d_buffer, subtile_idx
                        )
                        # Fence and barrier to make sure shared memory store is visible to TMA store
                        d_pipeline.producer_commit()
                        d_pipeline.producer_acquire()

                    epilogue_sync_barrier.arrive_and_wait()

                #
                # Async arrive accumulator buffer empty
                #
                with cute.arch.elect_one():
                    acc_pipeline.consumer_release(acc_consumer_state)
                acc_consumer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            epilogue_sync_barrier.arrive_and_wait()
            tmem.free(tmem_ptr)
            #
            # Wait for D store complete
            #
            d_pipeline.producer_tail()

        #
        # Specialized epilog load warp
        #
        if warp_idx == self.epilogue_load_warp_id:
            # Create the tiled tensors to be loaded in the epilogue.
            self.efc.kernel.create_epilogue_subtile_tensors(tidx, epi_tile)

            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            c_pipeline_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_c_stage
            )

            # Setup the pipelines reading the EFC supplemental tensors.

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )
                # Prepare the EFC tensors to be loaded by the subtiles.
                subtile_cnt = self.efc.kernel.prepare_tensor_load_for_subtiles(
                    mma_tile_coord_mnl,
                )

                # Assume the pipeline can work even in the case there is no
                # tensor to load and so subtile_cnt is 0.
                for subtile_idx in cutlass.range(subtile_cnt):
                    # Load C from global memory to shared memory.
                    c_pipeline.producer_acquire(c_pipeline_producer_state)

                    # Load the subtiles of EFC tensors.
                    self.efc.kernel.load_tensor_subtiles(
                        subtile_idx, c_pipeline, c_pipeline_producer_state
                    )

                    c_pipeline_producer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Wait for the load buffer to be empty.
            #
            c_pipeline.producer_tail(c_pipeline_producer_state)

    def epilogue_tmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        tAcc: cute.Tensor,
        tCgC: cute.Tensor,
        epi_tile: cute.Tile,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Make tiledCopy for tensor memory load, then use it to partition tensor memory (source) and register array (destination).
        """
        # Make tiledCopy for tensor memory load
        copy_atom_t2r = sm100_utils.get_tmem_load_op(
            self.cta_tile_shape_mnk,
            self.d_layout,  # Take this as the reference layout for the epilogue tile.
            self.epi_dtype,  # But we get the accumulator as epi_dtype in the epilogue.
            self.acc_dtype,
            epi_tile,
            self.use_2cta_instrs,
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
        tCgC_epi = cute.flat_divide(
            tCgC[((None, None), 0, 0, None, None, None)], epi_tile
        )
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
        tTR_gC = thr_copy_t2r.partition_D(tCgC_epi)
        # (T2R, T2R_M, T2R_N)
        tTR_rAcc = cute.make_rmem_tensor(
            tTR_gC[(None, None, None, 0, 0, 0, 0, 0)].shape, self.acc_dtype
        )
        return tiled_copy_t2r, tTR_tAcc, tTR_rAcc

    def epilogue_smem_copy_and_partition_load(
        self,
        tiled_copy_t2r: cute.TiledCopy,
        tTR_rC: cute.Tensor,
        tidx: cutlass.Int32,
        sC: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Make tiledCopy for shared memory load, then use it to partition register array (destination) and shared memory (source).

        :param tiled_copy_t2r: The tiled copy operation for tmem to register copy(t2r)
        :type tiled_copy_t2r: cute.TiledCopy
        :param tTR_rC: The partitioned accumulator tensor
        :type tTR_rC: cute.Tensor
        :param tidx: The thread index in epilogue warp groups
        :type tidx: cutlass.Int32
        :param sC: The shared memory tensor to be copied and partitioned
        :type sC: cute.Tensor

        :return: A tuple containing (tiled_copy_s2r, tSR_rC, tSR_sC) where:
            - tiled_copy_s2r: The tiled copy operation for smem to register copy(s2r)
            - tSR_rC: The partitioned tensor C (register destination)
            - tSR_sC: The partitioned tensor C (smem source)
        :rtype: Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]
        """
        copy_atom_s2r = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), self.c_dtype)
        tiled_copy_s2r = cute.make_tiled_copy_D(copy_atom_s2r, tiled_copy_t2r)
        # (S2R, S2R_M, S2R_N, PIPE_C)
        thr_copy_s2r = tiled_copy_s2r.get_slice(tidx)
        tSR_sC = thr_copy_s2r.partition_D(sC)
        # (S2R, S2R_M, S2R_N)
        tSR_rC = tiled_copy_s2r.retile(tTR_rC)
        return tiled_copy_s2r, tSR_rC, tSR_sC

    def epilogue_gmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        atom: Union[cute.CopyAtom, cute.TiledCopy],
        gC_mnl: cute.Tensor,
        epi_tile: cute.Tile,
        sC: cute.Tensor,
        dtype: Type[cutlass.Numeric],
    ) -> Tuple[cute.CopyAtom, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for global memory store, then use it to:
        - partition register array (source) and global memory (destination) for none TMA store version;
        - partition shared memory (source) and global memory (destination) for TMA store version.

        :param tidx: The thread index in epilogue warp groups
        :type tidx: cutlass.Int32
        :param atom: The copy_atom_c to be used for TMA store version, or tiled_copy_t2r for none TMA store version
        :type atom: cute.CopyAtom or cute.TiledCopy
        :param gC_mnl: The global tensor C
        :type gC_mnl: cute.Tensor
        :param epi_tile: The epilogue tiler
        :type epi_tile: cute.Tile
        :param sC: The shared memory tensor to be copied and partitioned
        :type sC: cute.Tensor

        :return: A tuple containing either:
            - For TMA store: (tma_atom_c, bSG_sC, bSG_gC) where:
                - tma_atom_c: The TMA copy atom
                - bSG_sC: The partitioned shared memory tensor C
                - bSG_gC: The partitioned global tensor C
            - For non-TMA store: (simt_atom, tTR_rC, tTR_gC) where:
                - simt_atom: The SIMT copy atom
                - tTR_rC: The register tensor C
                - tTR_gC: The partitioned global tensor C
        :rtype: Tuple[cute.CopyAtom, cute.Tensor, cute.Tensor]
        """
        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, tiles_m, tiles_n, tiles_l)
        gC_epi = cute.flat_divide(
            gC_mnl[((None, None), 0, 0, None, None, None)], epi_tile
        )

        tma_atom_c = atom
        sC_for_tma_partition = cute.group_modes(sC, 0, 2)
        gC_for_tma_partition = cute.group_modes(gC_epi, 0, 2)
        # ((ATOM_V, REST_V), EPI_M, EPI_N)
        # ((ATOM_V, REST_V), EPI_M, EPI_N, tiles_m, tiles_n, tiles_l)
        bSG_sC, bSG_gC = cpasync.tma_partition(
            tma_atom_c,
            0,
            cute.make_layout(1),
            sC_for_tma_partition,
            gC_for_tma_partition,
        )
        return tma_atom_c, bSG_sC, bSG_gC

    def compute_stages(self) -> None:
        """Compute and set the number of stages for A/B/C/D operands.

        Uses instance attributes to compute and assign:
        `self.num_acc_stage`, `self.num_ab_stage`, `self.num_c_stage`,
        and `self.num_d_stage`.
        """
        # Defaults
        self.num_acc_stage = 2
        # To read the tensors needed for the epilogue:
        self.num_c_stage = 2
        # To write the tensors produced by the epilogue:
        self.num_d_stage = 2

        # Calculate smem layout and size for one stage of A, B, C, and D
        a_smem_layout_stage_one = sm100_utils.make_smem_layout_a(
            self._tiled_mma, self.mma_tiler, self.a_dtype, 1
        )
        b_smem_layout_staged_one = sm100_utils.make_smem_layout_b(
            self._tiled_mma, self.mma_tiler, self.b_dtype, 1
        )

        # Get the contribution from the tensors used in the EFC.
        self.efc.jit.compute_stage()

        ab_bytes_per_stage = cute.size_in_bytes(
            self.a_dtype, a_smem_layout_stage_one
        ) + cute.size_in_bytes(self.b_dtype, b_smem_layout_staged_one)
        mbar_helpers_bytes = 1024
        # Contribution from the tensors loaded in the EFC.
        c_bytes_per_stage = self.efc.jit.smem_size_in_bytes_of_read_tensors()
        c_bytes = c_bytes_per_stage * self.num_c_stage
        # Contribution from the tensors stored in the EFC. There is at least 1
        # written tensor, so the following is strictly positive.
        d_bytes_per_stage = self.efc.jit.smem_size_in_bytes_of_written_tensors()
        d_bytes = d_bytes_per_stage * self.num_d_stage

        # Calculate A/B stages
        self.num_ab_stage = (
            self.smem_capacity // self.occupancy
            - (mbar_helpers_bytes + c_bytes + d_bytes)
        ) // ab_bytes_per_stage
        log(f"\t{self.num_ab_stage = }")

        if self.num_ab_stage <= 0:
            raise MemoryError("Not enough smem capacity to allocate all the tensors.")

        # Refine epilogue stages:
        # Calculate remaining smem after allocating for A/B stages and reserved bytes.
        # Add remaining unused smem to epilogue.
        self.num_d_stage += (
            self.smem_capacity
            - self.occupancy * ab_bytes_per_stage * self.num_ab_stage
            - self.occupancy * (mbar_helpers_bytes + c_bytes + d_bytes)
        ) // (self.occupancy * d_bytes_per_stage)
        log(f"\tnew {self.num_d_stage = }")

    @staticmethod
    def _compute_grid(
        d: cute.Tensor,
        cta_tile_shape_mnk: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        max_active_clusters: cutlass.Constexpr,
    ) -> Tuple[utils.PersistentTileSchedulerParams, Tuple[int, int, int]]:
        """Use persistent tile scheduler to compute the grid size for the output tensor D.

        :param d: The output tensor D
        :type d: cute.Tensor
        :param cta_tile_shape_mnk: The shape (M, N, K) of the CTA tile.
        :type cta_tile_shape_mnk: tuple[int, int, int]
        :param cluster_shape_mn: Shape of each cluster in M, N dimensions.
        :type cluster_shape_mn: tuple[int, int]
        :param max_active_clusters: Maximum number of active clusters.
        :type max_active_clusters: cutlass.Constexpr

        :return: A tuple containing:
            - tile_sched_params: Parameters for the persistent tile scheduler.
            - grid: Grid shape for kernel launch.
        :rtype: Tuple[utils.PersistentTileSchedulerParams, tuple[int, int, int]]
        """
        log(f"compute_grid: {max_active_clusters = }")
        d_shape = cute.slice_(cta_tile_shape_mnk, (None, None, 0))
        gd = cute.zipped_divide(d, tiler=d_shape)
        num_ctas_mnl = gd[(0, (None, None, None))].shape
        common_efc.if_debug(
            lambda: cute.printf("compute_grid: num_ctas_mnl = {}", num_ctas_mnl)
        )
        cluster_shape_mnl = (*cluster_shape_mn, 1)

        tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl, cluster_shape_mnl
        )
        grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )
        common_efc.if_debug(lambda: cute.printf("compute_grid: grid = {}", grid))
        return tile_sched_params, grid

    def compute_num_tmem_alloc_cols(self) -> None:
        """Compute and set the number of tensor memory allocation columns.

        This method uses the instance attributes computed during setup to
        determine the number of tensor memory allocation columns and stores
        the result in `self.num_tmem_alloc_cols`.
        """
        acc_shape = self._tiled_mma.partition_shape_C(self.mma_tiler[:2])
        log(f"compute_num_tmem_alloc_cols: {acc_shape = !s}")
        tCtAcc_fake = self._tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )
        log(f"compute_num_tmem_alloc_cols: {tCtAcc_fake = !s}")
        self.num_tmem_alloc_cols = utils.get_num_tmem_alloc_cols(tCtAcc_fake)
        log(f"compute_num_tmem_alloc_cols: {self.num_tmem_alloc_cols = }")

    def check_valid_dtypes(
        self,
        ab_dtype: Type[cutlass.Numeric],
    ):
        """
        Check if the dtypes are valid

        :param ab_dtype: The data type of the A and B operands
        :type ab_dtype: Type[cutlass.Numeric]
        :param acc_dtype: The data type of the accumulator
        :type acc_dtype: Type[cutlass.Numeric]

        :raises ValueError: If the dtypes are invalid or incompatible
        """
        valid_ab_dtypes = {
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.TFloat32,
            cutlass.Uint8,
            cutlass.Int8,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        }
        if ab_dtype not in valid_ab_dtypes:
            raise ValueError(
                f"Invalid A/B dtype: {ab_dtype}. "
                f"Supported dtypes: {', '.join(str(dt) for dt in valid_ab_dtypes)}"
            )

        valid_acc_dtypes = {cutlass.Float32, cutlass.Float16, cutlass.Int32}
        if self.acc_dtype not in valid_acc_dtypes:
            raise ValueError(
                f"Invalid accumulator dtype: {self.acc_dtype}. "
                f"Supported dtypes: {', '.join(str(dt) for dt in valid_acc_dtypes)}"
            )

        # Define compatibility mapping between accumulator type and AB type
        acc_ab_compatibility = {
            cutlass.Float32: {
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.TFloat32,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },  # Float32 accumulator supports floating point AB types only
            cutlass.Float16: {
                cutlass.Float16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
            cutlass.Int32: {cutlass.Uint8, cutlass.Int8},
        }
        # Check compatibility between accumulator type and AB type
        if ab_dtype not in acc_ab_compatibility[self.acc_dtype]:
            compatible_types = acc_ab_compatibility[self.acc_dtype]
            raise ValueError(
                f"Incompatible dtype combination: A/B dtype {ab_dtype} is not compatible "
                f"with accumulator dtype {self.acc_dtype}. "
                f"Compatible A/B dtypes for {self.acc_dtype}: {', '.join(str(dt) for dt in compatible_types)}"
            )

    def check_valid_mma_tiler_and_cluster_shape(self):
        """Check if the mma tiler and cluster shape are valid.

        :raises ValueError: If the mma tiler or cluster shape is invalid
        """
        # Check invalid mma tile shape M dimension
        if not (
            (not self.use_2cta_instrs and self.mma_tiler_mn[0] in [64, 128])
            or (self.use_2cta_instrs and self.mma_tiler_mn[0] in [128, 256])
        ):
            expected = [128, 256] if self.use_2cta_instrs else [64, 128]
            raise ValueError(
                f"Invalid MMA tile M dimension: {self.mma_tiler_mn[0]}. "
                f"Expected one of {expected} (use_2cta_instrs={self.use_2cta_instrs})"
            )

        # Check invalid mma tile shape N dimension
        if self.mma_tiler_mn[1] not in range(32, 257, 32):
            raise ValueError(
                f"Invalid MMA tile N dimension: {self.mma_tiler_mn[1]}. "
                f"Expected a multiple of 32 in range [32, 256]"
            )
        # Check illegal cluster shape M dimension
        if self.cluster_shape_mn[0] % (2 if self.use_2cta_instrs else 1) != 0:
            divisor = 2 if self.use_2cta_instrs else 1
            raise ValueError(
                f"Invalid cluster shape M dimension: {self.cluster_shape_mn[0]}. "
                f"Must be divisible by {divisor} (use_2cta_instrs={self.use_2cta_instrs})"
            )

        def is_power_of_2(x):
            return x > 0 and (x & (x - 1)) == 0

        # Check invalid cluster shape constraints
        if self.cluster_shape_mn[0] * self.cluster_shape_mn[1] > 16:
            raise ValueError(
                f"Invalid cluster shape: {self.cluster_shape_mn}. "
                f"Product {self.cluster_shape_mn[0]} * {self.cluster_shape_mn[1]} = "
                f"{self.cluster_shape_mn[0] * self.cluster_shape_mn[1]} exceeds maximum of 16"
            )
        if self.cluster_shape_mn[0] <= 0 or self.cluster_shape_mn[1] <= 0:
            raise ValueError(
                f"Invalid cluster shape: {self.cluster_shape_mn}. "
                f"Both dimensions must be positive"
            )
        if not is_power_of_2(self.cluster_shape_mn[0]) or not is_power_of_2(
            self.cluster_shape_mn[1]
        ):
            raise ValueError(
                f"Invalid cluster shape: {self.cluster_shape_mn}. "
                f"Both dimensions must be powers of 2"
            )

    def check_valid_tensor_alignment(
        self,
        m: int,
        n: int,
        k: int,
        l: int,
        ab_dtype: Type[cutlass.Numeric],
        d_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        cd_major: str,
    ):
        """
        Check if the tensor alignment is valid

        :param m: The number of rows in the A tensor
        :type m: int
        :param n: The number of columns in the B tensor
        :type n: int
        :param k: The number of columns in the A tensor
        :type k: int
        :param l: The number of columns in the C tensor
        :type l: int
        :param ab_dtype: The data type of the A and B operands
        :type ab_dtype: Type[cutlass.Numeric]
        :param d_dtype: The data type of the D tensor
        :type d_dtype: Type[cutlass.Numeric]
        :param a_major: The major axis of the A tensor
        :type a_major: str
        :param b_major: The major axis of the B tensor
        :type b_major: str
        :param cd_major: The major axis of the C/D tensor
        :type cd_major: str

        :raises ValueError: If the tensor alignment is invalid
        """

        def check_contigous_16B_alignment(
            dtype, is_mode0_major, tensor_shape, tensor_name
        ):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 16 * 8 // dtype.width
            if num_major_elements % num_contiguous_elements != 0:
                raise ValueError(
                    f"Invalid alignment for tensor {tensor_name}. "
                    f"Major dimension has {num_major_elements} elements, "
                    f"but requires alignment to {num_contiguous_elements} elements (16 bytes). "
                    f"Dtype: {dtype}, width: {dtype.width} bits"
                )

        check_contigous_16B_alignment(ab_dtype, a_major == "m", (m, k, l), "A")
        check_contigous_16B_alignment(ab_dtype, b_major == "n", (n, k, l), "B")
        check_contigous_16B_alignment(d_dtype, cd_major == "m", (m, n, l), "D")

    def check_implementable(self, a: cute.Tensor, b: cute.Tensor, d: cute.Tensor):
        """Check if the given tensors can be implemented by this kernel.

        :param a: Input tensor A
        :type a: cute.Tensor
        :param b: Input tensor B
        :type b: cute.Tensor
        :param d: One of the tensor used as some output
        :type d: cute.Tensor

        :raises CantImplementError: If the configuration is not implementable
        """
        m, n, k, l = a.shape[0], b.shape[0], a.shape[1], a.shape[2]

        # infer a_major, b_major, cd_major
        is_m_major_a = utils.LayoutEnum.from_tensor(a).is_m_major_a()
        is_n_major_b = utils.LayoutEnum.from_tensor(b).is_n_major_b()
        is_m_major_d = utils.LayoutEnum.from_tensor(d).is_m_major_c()
        a_major = "m" if is_m_major_a else "k"
        b_major = "n" if is_n_major_b else "k"
        cd_major = "m" if is_m_major_d else "n"

        try:
            # Check dtypes (raises ValueError if invalid)
            self.check_valid_dtypes(a.element_type)

            # Check mma tile shape and cluster shape (raises ValueError if invalid)
            self.check_valid_mma_tiler_and_cluster_shape()

            # Check problem shape for load/store alignment (raises ValueError if invalid)
            self.check_valid_tensor_alignment(
                m,
                n,
                k,
                l,
                a.element_type,
                d.element_type,
                a_major,
                b_major,
                cd_major,
            )
        except ValueError as e:
            raise cute.testing.CantImplementError(f"Configuration error: {e}")

    class CLIParser:
        """Parse command-line arguments for the Blackwell Dense GEMM example."""

        def __init__(self):
            self.parser = argparse.ArgumentParser(
                description="Example of Dense Persistent GEMM on Blackwell."
            )
            self.parser.add_argument(
                "--mnkl",
                type=self.parse_comma_separated_ints,
                default=(256, 256, 512, 1),
                help="mnkl dimensions (comma-separated)",
            )
            self.parser.add_argument(
                "--mma_tiler_mn",
                type=self.parse_comma_separated_ints,
                default=(128, 128),
                help="Mma tile shape (comma-separated)",
            )
            self.parser.add_argument(
                "--cluster_shape_mn",
                type=self.parse_comma_separated_ints,
                default=(1, 1),
                help="Cluster shape (comma-separated)",
            )
            self.parser.add_argument(
                "--ab_dtype", type=cutlass.dtype, default=cutlass.TFloat32
            )
            self.parser.add_argument(
                "--acc_dtype", type=cutlass.dtype, default=cutlass.Float32
            )
            self.parser.add_argument(
                "--epi_dtype", type=cutlass.dtype, default=cutlass.Float32
            )
            self.parser.add_argument(
                "--use_2cta_instrs",
                action="store_true",
                help="Enable 2CTA MMA instructions feature",
            )
            self.parser.add_argument(
                "--a_major", choices=["k", "m"], type=str, default="k"
            )
            self.parser.add_argument(
                "--b_major", choices=["k", "n"], type=str, default="k"
            )
            self.parser.add_argument(
                "--cd_major", choices=["n", "m"], type=str, default="n"
            )
            self.parser.add_argument(
                "--tolerance",
                type=float,
                default=1e-01,
                help="Tolerance for validation",
            )
            self.parser.add_argument(
                "--warmup_iterations", type=int, default=0, help="Warmup iterations"
            )
            self.parser.add_argument(
                "--iterations",
                type=int,
                default=1,
                help="Number of iterations to run the kernel",
            )
            self.parser.add_argument(
                "--skip_ref_check", action="store_true", help="Skip reference checking"
            )

            # A children class may add more things to parse.
            self.more_parsing()

        def parse(self):
            """Parse the command-line arguments."""
            args = self.parser.parse_args()

            if len(args.mnkl) != 4:
                self.parser.error("--mnkl must contain exactly 4 values")

            if len(args.mma_tiler_mn) != 2:
                self.parser.error("--mma_tiler_mn must contain exactly 2 values")

            if len(args.cluster_shape_mn) != 2:
                self.parser.error("--cluster_shape_mn must contain exactly 2 values")

            return args

        @staticmethod
        def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
            try:
                return tuple(int(x.strip()) for x in s.split(","))
            except ValueError:
                raise argparse.ArgumentTypeError(
                    "Invalid format. Expected comma-separated integers."
                )

        def more_parsing(self):
            """To override to add more stuff to self.parser"""

    @staticmethod
    def dtype_name(dtype: Type[cutlass.Numeric]) -> str:
        """Convert a CUTLASS dtype object to its clean string name.

        This is needed to format dtype objects into CLI arguments without
        full module paths. CUTLASS dtype objects have different representations:
        some have a __name__ attribute while others need string parsing.

        We want "Float16" not "cutlass.Float16" or "<class 'cutlass.Float16'>".

        :param dtype: CUTLASS numeric data type
        :return: Clean type name string (e.g., "Float16", "BFloat16")

        Example:
            >>> DenseGemmEFC.dtype_name(cutlass.Float16)
            'Float16'
        """
        return (
            dtype.__name__ if hasattr(dtype, "__name__") else str(dtype).split(".")[-1]
        )

    @staticmethod
    def format_as_cli_args(
        script_name: str,
        mnkl: Tuple[int, int, int, int],
        ab_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        epi_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        cd_major: str,
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        use_2cta_instrs: bool,
        tolerance: float,
    ) -> str:
        """Format common test parameters as CLI arguments base.

        This method formats the common parameters shared across different GEMM examples.
        Subclass-specific parameters (like alpha, beta, etc.) should be added by overriding methods.

        :param script_name: Name of the Python script
        :param mnkl: Matrix dimensions (M, N, K, L)
        :param ab_dtype: Data type for A and B matrices
        :param acc_dtype: Data type for accumulation
        :param epi_dtype: Data type for epilogue
        :param a_major: Major order for matrix A
        :param b_major: Major order for matrix B
        :param cd_major: Major order for matrices C and D
        :param mma_tiler_mn: MMA tiler dimensions (M, N)
        :param cluster_shape_mn: Cluster shape (M, N)
        :param use_2cta_instrs: Whether to use 2CTA instructions
        :param tolerance: Tolerance for validation
        :return: Formatted CLI command string
        """
        # Format tuples as comma-separated values
        mnkl_str = ",".join(map(str, mnkl))
        mma_tiler_str = ",".join(map(str, mma_tiler_mn))
        cluster_shape_str = ",".join(map(str, cluster_shape_mn))

        cmd = (
            f"python {script_name} "
            f"--mnkl {mnkl_str} "
            f"--ab_dtype {DenseGemmEFC.dtype_name(ab_dtype)} "
            f"--acc_dtype {DenseGemmEFC.dtype_name(acc_dtype)} "
            f"--epi_dtype {DenseGemmEFC.dtype_name(epi_dtype)} "
            f"--a_major {a_major} "
            f"--b_major {b_major} "
            f"--cd_major {cd_major} "
            f"--mma_tiler_mn {mma_tiler_str} "
            f"--cluster_shape_mn {cluster_shape_str} "
            f"{'--use_2cta_instrs ' if use_2cta_instrs else ''}"
            f"--tolerance {tolerance}"
        )
        return cmd

    def create_arguments(self, l, m, n, k, a_major, b_major, cd_major, ab_dtype):
        """Create base GEMM input tensors A and B.

        This method creates the input matrices for GEMM computation. Subclasses
        typically override this method to create additional supplemental tensors
        for the epilogue.

        :param l: Batch dimension
        :param m: M dimension (rows of A and output)
        :param n: N dimension (columns of B and output)
        :param k: K dimension (inner dimension)
        :param a_major: Major order for A matrix ('m' or 'k')
        :param b_major: Major order for B matrix ('n' or 'k')
        :param cd_major: Major order for supplemental tensors ('m' or 'n')
        :param ab_dtype: Data type for A and B matrices
        :return: Tuple of (a_tensor, b_tensor, a_torch_cpu, b_torch_cpu)
        """
        torch.manual_seed(1111)

        a_torch_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype)
        b_torch_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype)

        a_tensor, _ = cutlass_torch.cute_tensor_like(
            a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b_tensor, _ = cutlass_torch.cute_tensor_like(
            b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )

        return (
            a_tensor,
            b_tensor,
            a_torch_cpu,
            b_torch_cpu,
        )

    def evaluate_on_cpu(
        self,
        a_torch_cpu,
        b_torch_cpu,
        epi_dtype,
        *epilogue_args,
    ):
        """Evaluate the GEMM and epilogue computation on CPU for validation.

        Computes the reference result by performing A*B using einsum, then
        evaluates the epilogue function with the accumulator and supplemental
        arguments. This updates any output tensors in epilogue_args.

        :param a_torch_cpu: Input matrix A on CPU
        :param b_torch_cpu: Input matrix B on CPU
        :param epi_dtype: Data type for epilogue computation
        :param epilogue_args: Supplemental arguments for the epilogue (tensors and scalars)
        """
        # Compute reference result
        ref = torch.einsum(
            "mkl,nkl->mnl",
            a_torch_cpu.to(dtype=torch.float32),
            b_torch_cpu.to(dtype=torch.float32),
        )

        self.efc.evaluate_on_cpu(ref, *epilogue_args)

    def compile(
        self,
        a_tensor,
        b_tensor,
        max_active_clusters,
        current_stream,
        *supplemental_arguments,
        **compiler_options,
    ):
        """Compile the GEMM kernel with epilogue fusion.

        Compiles the kernel using CUTE DSL compilation, incorporating the EFC
        (Epilogue Fusion Configuration) with all supplemental arguments. Returns
        a callable function that accepts the same arguments for execution.

        :param a_tensor: Input tensor A
        :param b_tensor: Input tensor B
        :param max_active_clusters: Maximum number of active clusters
        :param current_stream: CUDA stream for execution
        :param supplemental_arguments: Additional arguments for the epilogue (tensors and scalars)
        :param compiler_options: Keywords arguments passed to CuTe DSL compiler. "options = " for now
        :return: Compiled callable function that executes the GEMM with the same signature
        """
        self.efc.compile(supplemental_arguments)
        compiled = cutlass.cute.compile(
            self,
            a_tensor,
            b_tensor,
            max_active_clusters,
            current_stream,
            self.efc.jit.pack_arguments(*supplemental_arguments),
            **compiler_options,
        )

        def inject_supplemental_arguments(
            a_tensor,
            b_tensor,
            current_stream,
            *supplemental_arguments,
        ):
            # Run the compiled code, do not pass the constexpr parameters nor
            # the compiler options.
            return compiled(
                a_tensor,
                b_tensor,
                current_stream,
                self.efc.jit.pack_arguments(*supplemental_arguments),
            )

        return inject_supplemental_arguments
