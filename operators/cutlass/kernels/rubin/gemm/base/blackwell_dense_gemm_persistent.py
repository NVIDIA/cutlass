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

import dataclasses
from typing import Optional, Tuple, Type, Union, Literal
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass import testing
import cutlass.utils as utils
from cutlass.utils import is_fp8_dtype
from cutlass.cutlass_dsl import Boolean, Int32
from cutlass.kernels.utils import tile_scheduler
from cutlass.cute.nvgpu import tcgen05


"""Blackwell SM100 persistent dense GEMM base for the Rubin SM107 kernels.

Not a runnable kernel: the standalone host/device paths were removed. Only the
pieces the SM107 subclasses inherit or import remain -- the constructor and
tile-scheduler template state, the pre-flight checks, the ``bmm`` traced
entry, and the tensor/stage helpers.
"""


def _compute_stages(
    tiled_mma: cute.TiledMma,
    mma_tiler_mnk: Tuple[int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    smem_capacity: int,
    occupancy: int,
    use_tma_store: bool,
    c_smem_layout: Union[cute.Layout, None],
    tile_scheduler_bytes: int = 0,
) -> Tuple[int, int, int]:
    """Computes the number of stages for A/B/C operands based on heuristics.

    :param tiled_mma: The tiled MMA object defining the core computation.
    :type tiled_mma: cute.TiledMma
    :param mma_tiler_mnk: The shape (M, N, K) of the MMA tiler.
    :type mma_tiler_mnk: tuple[int, int, int]
    :param a_dtype: Data type of operand A.
    :type a_dtype: type[cutlass.Numeric]
    :param b_dtype: Data type of operand B.
    :type b_dtype: type[cutlass.Numeric]
    :param c_dtype: Data type of operand C (output).
    :type c_dtype: type[cutlass.Numeric]
    :param smem_capacity: Total available shared memory capacity in bytes.
    :type smem_capacity: int
    :param occupancy: Target number of CTAs per SM (occupancy).
    :type occupancy: int
    :param use_tma_store: Whether TMA store is enabled.
    :type use_tma_store: bool
    :param c_smem_layout: Layout of C operand in shared memory, or None if not using TMA store.
    :type c_smem_layout: Union[cute.Layout, None]
    :param tile_scheduler_bytes: Shared memory the tile scheduler reserves, in bytes.
        Non-zero for the CLC work strategy (mbarriers + response slots) and for
        cluster split-K (the DSMEM mailbox).
    :type tile_scheduler_bytes: int

    :return: A tuple containing the computed number of stages for:
             (ACC stages, A/B operand stages, C stages)
    :rtype: tuple[int, int, int]
    """
    # Default ACC stages
    num_acc_stage = 2

    # Default C stages
    num_c_stage = 2 if use_tma_store else 0

    # Calculate smem layout and size for one stage of A, B, and C with 1-stage
    a_smem_layout_stage_one = utils.sm100.make_smem_layout_a(
        tiled_mma, mma_tiler_mnk, a_dtype, 1
    )
    b_smem_layout_staged_one = utils.sm100.make_smem_layout_b(
        tiled_mma, mma_tiler_mnk, b_dtype, 1
    )

    ab_bytes_per_stage = cute.size_in_bytes(
        a_dtype, a_smem_layout_stage_one
    ) + cute.size_in_bytes(b_dtype, b_smem_layout_staged_one)
    mbar_helpers_bytes = 1024

    c_bytes_per_stage = cute.size_in_bytes(c_dtype, c_smem_layout)
    c_bytes = c_bytes_per_stage * num_c_stage

    # Calculate A/B stages:
    # Start with total smem per CTA (capacity / occupancy)
    # Subtract reserved bytes and initial C stages bytes
    # Divide remaining by bytes needed per A/B stage
    num_ab_stage = (
        smem_capacity // occupancy
        - (mbar_helpers_bytes + c_bytes + tile_scheduler_bytes)
    ) // ab_bytes_per_stage

    # Refine epilogue stages:
    # Calculate remaining smem after allocating for A/B stages and reserved bytes
    # Add remaining unused smem to epilogue
    if use_tma_store:
        num_c_stage += (
            smem_capacity
            - occupancy * ab_bytes_per_stage * num_ab_stage
            - occupancy * (mbar_helpers_bytes + c_bytes + tile_scheduler_bytes)
        ) // (occupancy * c_bytes_per_stage)
    return num_acc_stage, num_ab_stage, num_c_stage


class PersistentDenseGemmKernel:
    """This class implements batched matrix multiplication (C = A x B) with support for various data types
    and architectural features specific to Blackwell GPUs with persistent tile scheduling and warp specialization.

    :param acc_dtype: Data type for accumulation during computation
    :type acc_dtype: type[cutlass.Numeric]
    :param use_2cta_instrs: Whether to use CTA group 2 for advanced thread cooperation
    :type use_2cta_instrs: bool
    :param mma_tiler_mn: Shape of the Matrix Multiply-Accumulate (MMA) tile (M,N)
    :type mma_tiler_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: Tuple[int, int]
    :param use_tma_store: Whether to use Tensor Memory Access (TMA) for storing results
    :type use_tma_store: bool

    :note: In current version, A and B tensor must have the same data type
        - i.e., Float8E4M3FN for A and Float8E5M2 for B is not supported

    :note: Supported A/B data types:
        - TFloat32
        - Float16/BFloat16
        - Int8/Uint8
        - Float8E4M3FN/Float8E5M2

    :note: Supported accumulator data types:
        - Float32 (for all floating point A/B data types)
        - Float16 (only for fp16 and fp8 A/B data types)
        - Int32 (only for uint8/int8 A/B data types)

    :note: Supported C data types:
        - Float32 (for float32 and int32 accumulator data types)
        - Int32 (for float32 and int32 accumulator data types)
        - Float16/BFloat16 (for fp32, fp16, and fp8 accumulator data types)
        - Int8/Uint8 (for uint8/int8 accumulator data types)
        - Float8E4M3FN/Float8E5M2 (for float32 accumulator data types)

    :note: Constraints:
        - MMA tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
        - MMA tiler N must be 32-256, step 32
        - Cluster shape M must be multiple of 2 if use_2cta_instrs=True
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 16

    This base is not runnable; see the SM107 subclasses for usage.
    """

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        use_tma_store: bool,
        split_k: int = 1,
        work_strategy: Literal["grid", "static", "clc"] = "static",
        rasterization_strategy: Literal["none", "affine"] = "affine",
        reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"] = "none",
        num_scheduler_stages: int = 1,
        use_pdl: bool = False,
        use_reduction_pdl: bool = False,
        fallback_cluster_shape_mn: Optional[Tuple[int, int]] = None,
    ):
        """Initializes the configuration for a Blackwell dense GEMM kernel.

        This configuration includes several key aspects:

        1.  MMA Instruction Settings (tcgen05):
            - acc_dtype: Data types for MMA accumulator.
            - mma_tiler_mn: The (M, N) shape of the MMA instruction tiler.
            - use_2cta_instrs: Boolean indicating if the tcgen05 MMA variant
              with cta_group=2 should be used.

        2.  Cluster Shape:
            - cluster_shape_mn: The (ClusterM, ClusterN) shape of the CTA cluster.

        3. Output C tensor store mode:
            - use_tma_store: Boolean indicating whether to use Tensor Memory Access (TMA) for storing results.

        :param acc_dtype: Data type of the accumulator.
        :type acc_dtype: type[cutlass.Numeric]
        :param mma_tiler_mn: Tuple (M, N) shape of the MMA instruction.
        :type mma_tiler_mn: Tuple[int, int]
        :param use_2cta_instrs: Boolean, True to use cta_group=2 MMA variant.
        :type use_2cta_instrs: bool
        :param cluster_shape_mn: Tuple (ClusterM, ClusterN) shape of the cluster.
        :type cluster_shape_mn: Tuple[int, int]
        :param use_tma_store: Use Tensor Memory Access (TMA) or normal store for output C tensor.
        :type use_tma_store: bool
        :param split_k: Number of K partitions; must be 1 iff ``reduction_strategy`` is "none".
        :type split_k: int
        :param work_strategy: How output tiles are handed to CTAs.
        :type work_strategy: Literal["grid", "static", "clc"]
        :param rasterization_strategy: How a work index is decoded into a tile coordinate.
        :type rasterization_strategy: Literal["none", "affine"]
        :param reduction_strategy: How the K partitions are reduced.
        :type reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"]
        :param num_scheduler_stages: Depth of the CLC work-fetch pipeline.
        :type num_scheduler_stages: int
        :param use_pdl: Launch this kernel with programmatic dependent launch.
        :type use_pdl: bool
        :param use_reduction_pdl: Launch the GMEM split-K reduction kernel with PDL.
        :type use_reduction_pdl: bool
        :param fallback_cluster_shape_mn: Tuple (ClusterM, ClusterN) shape of the
            fallback cluster; defaults to ``cluster_shape_mn``.
        :type fallback_cluster_shape_mn: Optional[Tuple[int, int]]
        """

        self.acc_dtype: Type[cutlass.Numeric] = acc_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.cluster_shape_mn = cluster_shape_mn
        self.fallback_cluster_shape_mn = fallback_cluster_shape_mn or cluster_shape_mn
        self.mma_tiler_mn = mma_tiler_mn
        self.mma_tiler = (*mma_tiler_mn, 1)
        self.use_tma_store = use_tma_store
        self.arch = "sm_100"

        self.split_k = split_k
        self.work_strategy = work_strategy
        self.rasterization_strategy = rasterization_strategy
        self.reduction_strategy = reduction_strategy
        self.num_sched_stages = num_scheduler_stages
        self.use_pdl = use_pdl
        self.use_reduction_pdl = use_reduction_pdl

        self.cta_group = (
            tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        self.occupancy = 1
        self.epilogue_warp_id = (0, 1, 2, 3)
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.epilog_sync_bar_id = 1
        self.tmem_alloc_sync_bar_id = 2
        self.tmem_dealloc_sync_bar_id = 3

        self.tile_scheduler_template_params = (
            tile_scheduler.TileSchedulerTemplateParams(
                acc_dtype=self.acc_dtype,
                work_strategy=self.work_strategy,
                rasterization_strategy=self.rasterization_strategy,
                reduction_strategy=self.reduction_strategy,
                num_scheduler_stages=self.num_sched_stages,
                cluster_shape_mn=self.cluster_shape_mn,
                split_k=self.split_k,
                cta_tile_shape_mnk=(
                    self.mma_tiler[0] // (2 if self.use_2cta_instrs else 1),
                    self.mma_tiler[1],
                    1,
                ),
                fallback_cluster_shape_mn=self.fallback_cluster_shape_mn,
            )
        )
        self.tile_scheduler_template = tile_scheduler.build_tile_scheduler_template(
            self.tile_scheduler_template_params
        )
        warp_ids = [self.mma_warp_id, self.tma_warp_id, *self.epilogue_warp_id]
        # ``sched_warp_id`` is only read behind a ``requires_scheduler_warp`` guard.
        if self.tile_scheduler_template.requires_scheduler_warp:
            self.sched_warp_id = 6
            warp_ids.append(self.sched_warp_id)
        self.threads_per_cta = 32 * len(warp_ids)

    def get_gmem_workspace_size(self, problem_shape_mnl) -> int:
        """Bytes of GMEM scratch the schedule needs for ``problem_shape_mnl``.

        :param problem_shape_mnl: problem extents (M, N, L) in elements
        :type problem_shape_mnl: Sequence[int]
        """
        return self.tile_scheduler_template.get_gmem_workspace_size(problem_shape_mnl)

    def initialize_workspace(self, workspace, problem_shape_mnl) -> None:
        """Populate the host-side staging buffer for the GMEM workspace.

        :param workspace: 1-D int8 buffer of ``get_gmem_workspace_size`` bytes
        :param problem_shape_mnl: problem extents (M, N, L) in elements
        """
        self.tile_scheduler_template.initialize_workspace(workspace, problem_shape_mnl)

    def lazily_set_cta_tile_shape_mnk(self, cta_tile_shape_mnk) -> None:
        """Rebuild the scheduler template with the real CTA tile shape.

        :param cta_tile_shape_mnk: the real CTA tile shape (M, N, K)
        """
        cta_tile_shape_mnk = tuple(cta_tile_shape_mnk)
        if self.tile_scheduler_template_params.cta_tile_shape_mnk == cta_tile_shape_mnk:
            return
        self.tile_scheduler_template_params = dataclasses.replace(
            self.tile_scheduler_template_params,
            cta_tile_shape_mnk=cta_tile_shape_mnk,
        )
        self.tile_scheduler_template = tile_scheduler.build_tile_scheduler_template(
            self.tile_scheduler_template_params
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
        - Setting up A/B/C stage counts in shared memory
        - Computing A/B/C shared memory layout
        - Computing tensor memory allocation columns
        """
        # Configure tiled mma
        tiled_mma = self._create_tiled_mma()

        # Compute mma/cluster/tile shapes
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        self.mma_tiler = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )

        self.lazily_set_cta_tile_shape_mnk(self.cta_tile_shape_mnk)

        # Compute cluster layout
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )

        self.clc_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(self.tile_scheduler_template_params.cluster_shape),
            (tiled_mma.thr_id.shape,),
        )

        # Compute number of multicast CTAs for A/B
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        # Compute epilogue subtile
        if cutlass.const_expr(self.use_tma_store):
            self.epi_tile = utils.sm100.compute_epilogue_tile_shape(
                self.cta_tile_shape_mnk,
                self.use_2cta_instrs,
                self.c_layout,
                self.c_dtype,
            )
        else:
            self.epi_tile = self.cta_tile_shape_mnk[:2]

        c_smem_layout = None
        if cutlass.const_expr(self.use_tma_store):
            c_smem_layout = utils.sm100.make_smem_layout_epi(
                self.c_dtype, self.c_layout, self.epi_tile, 1
            )

        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes()

        # Setup A/B/C stage count in shared memory and ACC stage count in tensor memory
        self.num_acc_stage, self.num_ab_stage, self.num_c_stage = _compute_stages(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.c_dtype,
            self.smem_capacity,
            self.occupancy,
            self.use_tma_store,
            c_smem_layout,
            self.tile_scheduler_template.get_smem_workspace_size(),
        )

        # Compute A/B/C shared memory layout
        self.a_smem_layout_staged = utils.sm100.make_smem_layout_a(
            tiled_mma, self.mma_tiler, self.a_dtype, self.num_ab_stage
        )
        self.b_smem_layout_staged = utils.sm100.make_smem_layout_b(
            tiled_mma, self.mma_tiler, self.b_dtype, self.num_ab_stage
        )

        self.c_smem_layout_staged = None
        if self.use_tma_store:
            self.c_smem_layout_staged = utils.sm100.make_smem_layout_epi(
                self.c_dtype, self.c_layout, self.epi_tile, self.num_c_stage
            )

        # Compute the number of tensor memory allocation columns
        self.num_tmem_alloc_cols = self._compute_num_tmem_alloc_cols(
            tiled_mma, self.mma_tiler, self.num_acc_stage, self.arch
        )

    # GPU device kernel

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

    @staticmethod
    def check_supported_dtypes(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
    ):
        """
        Check if the dtypes are valid

        :param ab_dtype: The data type of the A and B operands
        :type ab_dtype: Type[cutlass.Numeric]
        :param acc_dtype: The data type of the accumulator
        :type acc_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]

        :raises testing.CantImplementError: If the dtypes are invalid
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
        if a_dtype not in valid_ab_dtypes or b_dtype not in valid_ab_dtypes:
            raise testing.CantImplementError(
                f"Unsupported AB dtype: {a_dtype} and {b_dtype}"
            )

        if acc_dtype not in {cutlass.Float32, cutlass.Float16, cutlass.Int32}:
            raise testing.CantImplementError(
                f"Unsupported accumulator dtype: {acc_dtype}"
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
        if (
            a_dtype not in acc_ab_compatibility[acc_dtype]
            or b_dtype not in acc_ab_compatibility[acc_dtype]
        ):
            raise testing.CantImplementError(
                f"Unsupported AB dtype: {a_dtype} and {b_dtype} for accumulator dtype: {acc_dtype}"
            )

        # Define compatibility mapping between accumulator type and C type
        acc_c_compatibility = {
            cutlass.Float32: {
                cutlass.Float32,
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
                cutlass.Int32,
                cutlass.Int8,
                cutlass.Uint8,
            },
            cutlass.Float16: {
                cutlass.BFloat16,
                cutlass.Float16,
            },
            cutlass.Int32: {
                cutlass.BFloat16,
                cutlass.Float16,
                cutlass.Float32,
                cutlass.Int32,
                cutlass.Int8,
                cutlass.Uint8,
            },
        }
        # Check compatibility between accumulator type and C type
        if c_dtype not in acc_c_compatibility[acc_dtype]:
            raise testing.CantImplementError(
                f"Unsupported C dtype: {c_dtype} for accumulator dtype: {acc_dtype}"
            )

    def check_mma_tiler_and_cluster_shape(self):
        """Check if the mma tiler and cluster shape are valid.

        :raises testing.CantImplementError: If the mma tiler and cluster shape are invalid
        """
        self.is_valid_mma_tiler_and_cluster_shape(
            self.mma_tiler_mn,
            self.cluster_shape_mn,
            self.use_2cta_instrs,
            self.use_tma_store,
            self.tile_scheduler_template,
            self.tile_scheduler_template_params,
        )

    @staticmethod
    def is_valid_mma_tiler_and_cluster_shape(
        mma_tiler_mn: tuple[int, int],
        cluster_shape_mn: tuple[int, int],
        use_2cta_instrs: bool,
        use_tma_store: bool,
        tile_scheduler_template: tile_scheduler.TileSchedulerTemplate | None = None,
        tile_scheduler_template_params: tile_scheduler.TileSchedulerTemplateParams
        | None = None,
    ):
        """Check validity of tiler, cluster shape, and use_2cta_instrs.

        :raises testing.CantImplementError: If the mma tiler and cluster shape are invalid
        """

        # Skip invalid mma tile shape
        if not (
            (not use_2cta_instrs and mma_tiler_mn[0] in [64, 128])
            or (use_2cta_instrs and mma_tiler_mn[0] in [128, 256])
        ):
            raise testing.CantImplementError(
                f"Invalid mma tiler & use_2cta_instrs: {mma_tiler_mn}, {use_2cta_instrs}"
            )
        if mma_tiler_mn[1] not in range(32, 257, 32):
            raise testing.CantImplementError(f"Invalid mma tiler N: {mma_tiler_mn[1]}")
        # Skip illegal cluster shape
        if cluster_shape_mn[0] % (2 if use_2cta_instrs else 1) != 0:
            raise testing.CantImplementError(
                f"Invalid cluster shape M: {cluster_shape_mn[0]}"
            )
        # Skip invalid cluster shape
        is_power_of_2 = lambda x: x > 0 and (x & (x - 1)) == 0
        template_params = tile_scheduler_template_params
        total_cluster_size = (
            cluster_shape_mn[0]
            * cluster_shape_mn[1]
            * (template_params.cluster_shape[2] if template_params else 1)
        )
        if (
            total_cluster_size > 16
            or cluster_shape_mn[0] <= 0
            or cluster_shape_mn[1] <= 0
            or not is_power_of_2(cluster_shape_mn[0])
            or not is_power_of_2(cluster_shape_mn[1])
        ):
            raise testing.CantImplementError(
                f"Invalid cluster shape: {cluster_shape_mn} with "
                f"split_k={template_params.split_k if template_params else 'N/A'}"
            )
        if tile_scheduler_template:
            tile_scheduler_template.check_cluster_splitk_constraints(use_tma_store)

    def check_tensor_alignment(
        self,
        m: int,
        n: int,
        k: int,
        l: int,
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
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
        :param a_dtype: The data type of the A operand
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: The data type of the B operand
        :type b_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: The major axis of the A tensor
        :type a_major: str
        :param b_major: The major axis of the B tensor
        :type b_major: str
        :param c_major: The major axis of the C tensor
        :type c_major: str

        :raises testing.CantImplementError: If the tensor alignment is invalid
        """

        # TODO: move to utils
        def check_contiguous_16B_alignment(dtype, is_mode0_major, tensor_shape):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 16 * 8 // dtype.width
            return num_major_elements % num_contiguous_elements == 0

        if (
            not check_contiguous_16B_alignment(a_dtype, a_major == "m", (m, k, l))
            or not check_contiguous_16B_alignment(b_dtype, b_major == "n", (n, k, l))
            or not check_contiguous_16B_alignment(c_dtype, c_major == "m", (m, n, l))
        ):
            raise testing.CantImplementError(
                f"Invalid tensor alignment: {m}, {n}, {k}, {l}, {a_dtype}, {b_dtype}, {c_dtype}, {a_major}, {b_major}, {c_major}"
            )

    def can_implement(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        swizzle_size: int,
        raster_along: Literal["m", "n"],
    ) -> bool:
        """Determine if the compiled kernel can execute this launch.
        :param a: Input tensor A of shape (l, m, k).
        :type a: cute.Tensor
        :param b: Input tensor B of shape (l, k, n).
        :type b: cute.Tensor
        :param c: Output tensor C of shape (l, m, n).
        :type c: cute.Tensor
        :param swizzle_size: tiles per swizzle group for this launch
        :type swizzle_size: int
        :param raster_along: rasterization order for this launch, already
            resolved to a concrete axis by
            ``TileSchedulerTemplate.resolve_rasterization``.
        :type raster_along: Literal["m", "n"]
        :return: True if this launch can be executed.
        :rtype: bool

        :raises testing.CantImplementError: If the launch is invalid.
        """
        batch, m, k = a.shape
        n = b.shape[2]
        a_major = "k" if a.stride[2] == 1 else "m"
        b_major = "k" if b.stride[1] == 1 else "n"
        c_major = "n" if c.stride[2] == 1 else "m"
        self.check_tensor_alignment(
            m,
            n,
            k,
            batch,
            a.element_type,
            b.element_type,
            c.element_type,
            a_major,
            b_major,
            c_major,
        )
        self.check_epilog_store_option(m, n)
        if not self.use_tma_store and self.tile_scheduler_template.visits_oob_tiles(
            (m, n, 0, 1), swizzle_size, raster_along
        ):
            raise testing.CantImplementError(
                f"problem shape {m}, {n} with swizzle_size {swizzle_size} leaves "
                "partially-filled clusters or swizzle groups, which a non-TMA "
                "store cannot predicate away"
            )
        if not self.tile_scheduler_template.can_implement(
            (m, n, k, batch), swizzle_size, raster_along
        ):
            raise testing.CantImplementError(
                "Tile scheduler cannot implement this configuration for problem "
                f"{(m, n, k, batch)} with swizzle_size={swizzle_size}, "
                f"raster_along={raster_along!r}"
            )
        return True


@cute.jit
def bmm(
    gemm_op: cutlass.Constexpr,
    a: cute.Tensor,  # (l, m, k)
    b: cute.Tensor,  # (l, k, n)
    c: cute.Tensor,  # (l, m, n)
    stream: cuda.CUstream,
    workspace: cute.Pointer,
    swizzle_size: Int32,
    raster_along_m: Boolean,
    max_active_clusters_fallback: Int32,
    epilogue_op: cutlass.Constexpr = lambda x: x,
):
    """
    Wrapper API for persistent GEMM kernel to follow the convention of PyTorch's batch matrix-multiply (bmm).

    Internally, the tensors are permuted to match CuTe's convention:
      - a: (m, k, l)
      - b: (n, k, l)
      - c: (m, n, l)

    :param gemm_op: Kernel operation, expects (a, b, c, stream, workspace, swizzle_size, raster_along_m,
        max_active_clusters_fallback, epilogue_op)
    :type gemm_op: cutlass.Constexpr
    :param a: Input tensor of shape (l, m, k)
    :type a: cute.Tensor
    :param b: Input tensor of shape (l, k, n)
    :type b: cute.Tensor
    :param c: Output tensor of shape (l, m, n)
    :type c: cute.Tensor
    :param swizzle_size: Tiles per swizzle group for this launch
    :type swizzle_size: Int32
    :param raster_along_m: True rasterizes M-major, False N-major
    :type raster_along_m: Boolean
    :param max_active_clusters_fallback: occupancy cap on concurrently resident
        fallback clusters (launch-time value; see ``query_max_active_clusters``).
        Only the ``static`` work strategy uses it (its grid is one wave).
    :type max_active_clusters_fallback: Int32
    :param epilogue_op: Optional elementwise lambda function to apply per output element, defaults to identity
    :type epilogue_op: cutlass.Constexpr, optional
    """
    # (l,m,k) -> (m,k,l)
    a = cute.make_tensor(a.iterator, cute.select(a.layout, mode=[1, 2, 0]))
    # (l,k,n) -> (n,k,l)
    b = cute.make_tensor(b.iterator, cute.select(b.layout, mode=[2, 1, 0]))
    # (l,m,n) -> (m,n,l)
    c = cute.make_tensor(c.iterator, cute.select(c.layout, mode=[1, 2, 0]))

    gemm_op(
        a,
        b,
        c,
        stream,
        workspace,
        swizzle_size,
        raster_along_m,
        max_active_clusters_fallback,
        epilogue_op,
    )


def prepare_tensors(
    mnkl: Tuple[int, int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    init_random: bool = True,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
):
    """Prepare tensors for GEMM.

    Returns:
        Tuple of (a_f32, b_f32, c_f32, a_storage, b_storage, c_storage):
        - *_f32: Float32 tensors with the logical data (for reference and fp8 conversion)
        - *_storage: Storage tensors for DLPack (uint8 for fp8, otherwise the target dtype)
    """
    import torch
    from cutlass.torch import dtype as torch_dtype

    m, n, k, l = mnkl

    if a_major == "k":
        a_f32 = torch.empty((l, m, k), dtype=torch.float32, device="cuda")
    elif a_major == "m":
        a_f32 = torch.empty((l, k, m), dtype=torch.float32, device="cuda").permute(
            0, 2, 1
        )

    if b_major == "n":
        b_f32 = torch.empty((l, k, n), dtype=torch.float32, device="cuda")
    elif b_major == "k":
        b_f32 = torch.empty((l, n, k), dtype=torch.float32, device="cuda").permute(
            0, 2, 1
        )

    if c_major == "n":
        c_f32 = torch.empty((l, m, n), dtype=torch.float32, device="cuda")
    elif c_major == "m":
        c_f32 = torch.empty((l, n, m), dtype=torch.float32, device="cuda").permute(
            0, 2, 1
        )

    # Initialize tensors with either uniform random or normal distribution
    for tensor in [a_f32, b_f32, c_f32]:
        if init_random:
            tensor.random_(-2, 3)
        else:
            tensor.normal_(mean=normal_mean, std=normal_std)

    # For float8 types, use uint8 as storage type to avoid dlpack limitation
    # (dlpack doesn't support float8 types)
    # For other types, convert to the target dtype
    a_storage_dtype = torch.uint8 if is_fp8_dtype(a_dtype) else torch_dtype(a_dtype)
    b_storage_dtype = torch.uint8 if is_fp8_dtype(b_dtype) else torch_dtype(b_dtype)
    c_storage_dtype = torch.uint8 if is_fp8_dtype(c_dtype) else torch_dtype(c_dtype)

    a_storage = a_f32.to(dtype=a_storage_dtype)
    b_storage = b_f32.to(dtype=b_storage_dtype)
    c_storage = c_f32.to(dtype=c_storage_dtype)

    return (a_f32, b_f32, c_f32, a_storage, b_storage, c_storage)
